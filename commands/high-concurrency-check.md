# /high-concurrency-check

Verificación de protección contra race conditions para operaciones críticas en PrestaShop 8.x 

Aplica cuando el código maneja: stock, checkout, reservas, sincronización con sistemas externos, o cualquier operación que no debe ejecutarse concurrentemente.

---

## 📌 CUÁNDO EJECUTAR

- Operaciones de stock (reserva, decremento, sincronización)
- Flujo de checkout y validación de pedidos
- Integraciones con SAP u otros sistemas de inventario
- Cron jobs que modifican datos compartidos
- Operaciones de saldo, puntos o crédito de cliente

---

## 🎯 PRINCIPIO FUNDAMENTAL

Las operaciones que modifican estado compartido (stock, reservas, pedidos) **deben** protegerse contra ejecución concurrente.

Sin protección → Race conditions → Datos inconsistentes → Pérdida de dinero.

---

## 🔍 OPERACIONES QUE REQUIEREN PROTECCIÓN

| Operación | Riesgo sin protección | Severidad |
|-----------|----------------------|-----------|
| Reserva de stock | Sobreventa | 🔴 |
| Confirmación de pedido | Pedidos duplicados | 🔴 |
| Sincronización SAP | Estados inconsistentes | 🔴 |
| Actualización de saldo/puntos | Saldo incorrecto | 🔴 |
| Generación de códigos únicos | Duplicados | 🟡 |
| Jobs de cron | Ejecución duplicada | 🟡 |

---

## 🔍 CHECKLIST OBLIGATORIO

### 1. Distributed Locking

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Lock en operaciones críticas | Obligatorio | 🔴 |
| Lock key única | Incluir entidad + ID | 🔴 |
| TTL apropiado | Operación + 50% buffer | 🟡 |
| Manejo de fallo de lock | No proceder sin lock | 🔴 |

```php
// ❌ CRÍTICO - Sin protección
public function reserveStock($cartId, $products)
{
    // Dos requests simultáneos pueden reservar el mismo stock
    $stock = $this->getAvailableStock($productId);
    if ($stock >= $quantity) {
        $this->decrementStock($productId, $quantity);
        return true;
    }
    return false;
}

// ✅ CORRECTO - Con locking
public function reserveStock($cartId, $products)
{
    $lockKey = 'stock:reserve:cart:' . (int)$cartId;
    
    $result = IagtLockService::withLock($lockKey, function() use ($products) {
        foreach ($products as $productId => $quantity) {
            $stock = $this->getAvailableStock($productId);
            if ($stock < $quantity) {
                return ['success' => false, 'error' => 'insufficient_stock'];
            }
        }
        
        // Dentro del lock, decrementar
        foreach ($products as $productId => $quantity) {
            $this->decrementStock($productId, $quantity);
        }
        
        return ['success' => true];
    }, 30); // TTL 30 segundos
    
    if ($result === null) {
        // Lock no adquirido
        throw new PrestaShopException('Operation busy, please retry');
    }
    
    return $result;
}
```

---

### 2. Lock Key Naming

| Formato | Ejemplo | Uso |
|---------|---------|-----|
| `operation:entity:id` | `reserve:cart:12345` | Operación por entidad |
| `sync:system:entity:id` | `sync:sap:product:999` | Sincronización externa |
| `job:name` | `job:stock_sync` | Cron jobs |

```php
// ✅ Keys correctas
$lockKey = 'sap:reserve:cart:' . (int)$cartId;
$lockKey = 'checkout:customer:' . (int)$customerId;
$lockKey = 'sync:stock:product:' . (int)$productId;
$lockKey = 'cron:daily_report'; // Sin ID si es global
```

---

### 3. TTL Guidelines

| Operación | TTL Recomendado |
|-----------|-----------------|
| API call simple | 10-15 segundos |
| API call complejo | 30 segundos |
| Proceso multi-step | 60 segundos |
| Sincronización batch | 120 segundos |

**Regla:** TTL = tiempo esperado + 50% buffer. Nunca menos del tiempo real.

---

### 4. Comportamiento ante Fallo de Lock

| Check | Criterio | Severidad |
|-------|----------|-----------|
| No proceder sin lock | Obligatorio | 🔴 |
| Informar al usuario | Mensaje claro | 🟡 |
| Logging | Rate-limited | 🟡 |
| Retry automático | Opcional, con límite | 🟢 |

```php
// ❌ CRÍTICO - Procede sin lock
$token = IagtLockService::acquire($key);
if (!$token) {
    // ❌ Continúa de todos modos
    $this->processAnyway();
}

// ✅ CORRECTO - Bloquea sin lock
$result = IagtLockService::withLock($key, function() {
    return $this->criticalOperation();
}, 30);

if ($result === null) {
    IagtRateLimitedLogger::log('lock_fail', 'Could not acquire: ' . $key, 2);
    throw new PrestaShopException('Please try again in a moment');
}
```

---

### 5. Idempotencia

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Operaciones de escritura externa | Idempotency key | 🔴 |
| Verificar estado antes de actuar | Obligatorio | 🔴 |
| Almacenar resultado | Para retornar en reintentos | 🟡 |

```php
// ✅ Patrón idempotente
public function confirmReservation($reservationId, $orderId)
{
    // 1. Generar idempotency key
    $idempotencyKey = 'confirm:' . $reservationId . ':' . $orderId;
    
    // 2. Verificar si ya se procesó
    $existing = $this->getStoredResult($idempotencyKey);
    if ($existing !== null) {
        return $existing; // Retornar resultado anterior
    }
    
    // 3. Procesar con lock
    $lockKey = 'sap:confirm:' . $reservationId;
    
    return IagtLockService::withLock($lockKey, function() use ($reservationId, $orderId, $idempotencyKey) {
        // Double-check después de adquirir lock
        $existing = $this->getStoredResult($idempotencyKey);
        if ($existing !== null) {
            return $existing;
        }
        
        // Ejecutar operación
        $result = $this->callSapConfirm($reservationId, $orderId);
        
        // Almacenar resultado
        $this->storeResult($idempotencyKey, $result, 3600); // 1 hora
        
        return $result;
    }, 30);
}
```

---

### 6. Checkout Protection

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Lock por carrito | Antes de validar pedido | 🔴 |
| Verificar stock dentro del lock | Obligatorio | 🔴 |
| Reservar antes de crear pedido | Si usa sistema externo | 🔴 |

```php
// ✅ Checkout protegido
public function hookActionBeforeValidateOrder($params)
{
    $cart = $params['cart'];
    $lockKey = 'checkout:cart:' . (int)$cart->id;
    
    $result = IagtLockService::withLock($lockKey, function() use ($cart) {
        // Verificar stock dentro del lock
        foreach ($cart->getProducts() as $product) {
            if (!IagtStockService::checkAvailability($product['id_product'], $product['cart_quantity'])) {
                return ['success' => false, 'error' => 'stock_unavailable'];
            }
        }
        
        // Reservar en SAP
        $reservation = IagtSapService::reserveStock($cart->id, $cart->getProducts());
        if (!$reservation) {
            return ['success' => false, 'error' => 'reservation_failed'];
        }
        
        return ['success' => true, 'reservation' => $reservation];
    }, 60);
    
    if ($result === null || !$result['success']) {
        throw new PrestaShopException('Could not complete order');
    }
}
```

---

### 7. Cron Job Protection

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Lock global por job | Evitar ejecución paralela | 🟡 |
| TTL mayor que duración | Con margen de seguridad | 🟡 |
| Logging de skip | Si ya está corriendo | 🟢 |

```php
// ✅ Cron protegido
// cron/sync_stock.php
$lockKey = 'cron:stock_sync';

$result = IagtLockService::withLock($lockKey, function() {
    IagtStockSyncService::syncAll();
    return true;
}, 300); // 5 minutos

if ($result === null) {
    IagtRateLimitedLogger::log('cron', 'stock_sync already running, skipped', 1);
}
```

---

## 🛑 ANTI-PATTERNS

| Anti-Pattern | Problema |
|--------------|----------|
| Check-then-act sin lock | Race condition clásica |
| Lock con TTL muy corto | Expira antes de completar |
| Proceder sin lock | Ignora protección |
| Lock key sin ID de entidad | Bloquea más de lo necesario |
| No verificar resultado de lock | Asume éxito |
| Operación no idempotente a API externa | Duplicados ante retry |

---

## FORMATO DE RESPUESTA

🔴 Bloqueantes · 🟡 Riesgos · 🟢 Correcto · 💡 Recomendaciones

---

## RESTRICCIONES

- NO escribir código salvo solicitud explícita
- NO suavizar problemas 🔴 — si los hay, indicar que NO puede ir a producción
- Referenciar siempre la regla o documento aplicable
- Actuar en español

---

## ⚙️ PREREQUISITOS

Este nivel de protección requiere:
- Redis disponible en producción
- `IagtLockService` implementado
- `IagtRateLimitedLogger` implementado

Ver `patterns/prestashop-enterprise-hardened-v2.0.md` para implementación completa.

---

---


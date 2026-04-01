# /servicelayer-review

Verificación de arquitectura Service Layer para código PrestaShop 8.x 

Evalúa que la lógica de negocio esté correctamente ubicada en Services, no dispersa en hooks, controllers o templates.

---

## 📌 CUÁNDO EJECUTAR

- Hooks con más de 10-15 líneas de código
- Controllers con lógica de negocio o SQL directo
- Código que hace `new ObjectModel()` fuera de un Service
- Templates con cálculos o lógica condicional compleja
- Lógica duplicada en múltiples lugares

---

## 🎯 PRINCIPIO FUNDAMENTAL

```
Controllers → Orquestan flujo
Hooks       → Coordinan eventos
Services    → Ejecutan lógica de negocio
Templates   → Solo presentación
```

La lógica de negocio **NUNCA** debe vivir en controllers, hooks, templates o cron entrypoints.

---

## 🔍 CHECKLIST OBLIGATORIO

### 1. Controllers

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Lógica de negocio | Prohibida, debe delegar en Service | 🔴 |
| Validación input | Permitida (sanitización) | 🟢 |
| Orquestación | Permitida (llamar services, preparar response) | 🟢 |
| SQL directo | Prohibido, usar Service o Repository | 🔴 |

```php
// ❌ INCORRECTO - Lógica en controller
class IagtOfferModuleFrontController extends ModuleFrontController
{
    public function postProcess()
    {
        $amount = (float) Tools::getValue('amount');
        $product = new Product((int) Tools::getValue('id_product'));
        
        // ❌ Lógica de negocio en controller
        if ($amount < $product->price * 0.7) {
            $this->errors[] = 'Offer too low';
            return;
        }
        
        $offer = new IagtOffer();
        $offer->amount = $amount;
        $offer->id_product = $product->id;
        $offer->id_customer = $this->context->customer->id;
        $offer->id_shop = $this->context->shop->id;
        $offer->add();
        
        // ❌ Más lógica: enviar email, notificar admin...
        Mail::send(...);
    }
}

// ✅ CORRECTO - Controller delega en Service
class IagtOfferModuleFrontController extends ModuleFrontController
{
    public function postProcess()
    {
        $result = IagtOfferService::createOffer(
            (int) Tools::getValue('id_product'),
            (float) Tools::getValue('amount'),
            (int) $this->context->customer->id,
            (int) $this->context->shop->id
        );
        
        if (!$result['success']) {
            $this->errors[] = $this->l($result['error']);
            return;
        }
        
        $this->success[] = $this->l('Offer submitted');
    }
}
```

---

### 2. Hooks

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Lógica compleja | Prohibida, delegar en Service | 🔴 |
| Coordinación | Permitida (llamar service, pasar params) | 🟢 |
| SQL directo | Prohibido | 🔴 |
| Longitud | Máximo 10-15 líneas | 🟡 |

```php
// ❌ INCORRECTO - Lógica en hook
public function hookActionValidateOrder($params)
{
    $order = $params['order'];
    $customer = new Customer($order->id_customer);
    
    // ❌ 50 líneas de lógica...
    $points = 0;
    foreach ($order->getProducts() as $product) {
        $points += $product['price'] * 0.1;
    }
    
    $sql = 'UPDATE ps_customer SET points = points + ' . (int)$points . '...';
    Db::getInstance()->execute($sql);
    
    if ($points > 100) {
        Mail::send(...);
    }
}

// ✅ CORRECTO - Hook delega inmediatamente
public function hookActionValidateOrder($params)
{
    IagtLoyaltyService::processOrderPoints($params['order']);
}
```

---

### 3. Services

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Ubicación | `classes/` o `src/Service/` del módulo | 🟡 |
| Naming | `IagtNombreService` | 🟡 |
| Responsabilidad | Una responsabilidad clara por service | 🟡 |
| Dependencias | Inyectadas o accedidas vía métodos estáticos | 🟢 |
| Testabilidad | Métodos con inputs/outputs claros | 🟢 |

```php
// ✅ Service correcto
class IagtOfferService
{
    /**
     * Crea una nueva oferta
     * 
     * @param int $idProduct
     * @param float $amount
     * @param int $idCustomer
     * @param int $idShop
     * @return array ['success' => bool, 'error' => string|null, 'id' => int|null]
     */
    public static function createOffer($idProduct, $amount, $idCustomer, $idShop)
    {
        // Validación de negocio
        $product = new Product((int)$idProduct);
        if (!Validate::isLoadedObject($product)) {
            return ['success' => false, 'error' => 'invalid_product', 'id' => null];
        }
        
        $minAmount = $product->price * 0.7;
        if ($amount < $minAmount) {
            return ['success' => false, 'error' => 'amount_too_low', 'id' => null];
        }
        
        // Persistencia
        $offer = new IagtOffer();
        $offer->id_product = (int)$idProduct;
        $offer->amount = (float)$amount;
        $offer->id_customer = (int)$idCustomer;
        $offer->id_shop = (int)$idShop;
        
        if (!$offer->add()) {
            return ['success' => false, 'error' => 'save_failed', 'id' => null];
        }
        
        // Side effects
        IagtNotificationService::notifyNewOffer($offer);
        
        return ['success' => true, 'error' => null, 'id' => $offer->id];
    }
}
```

---

### 4. Templates (Smarty)

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Lógica de negocio | Prohibida totalmente | 🔴 |
| Cálculos | Prohibidos (preparar en controller) | 🔴 |
| Condicionales simples | Permitidos (mostrar/ocultar) | 🟢 |
| Loops | Permitidos (iterar datos preparados) | 🟢 |

```smarty
{* ❌ INCORRECTO - Lógica en template *}
{assign var="discount" value=$product.price * 0.2}
{assign var="finalPrice" value=$product.price - $discount}
{if $customer.points > 100 && $product.category == 5}
    {* Lógica compleja *}
{/if}

{* ✅ CORRECTO - Solo presentación *}
{if $showDiscount}
    <span class="discount">{$discountAmount|escape:'html':'UTF-8'}</span>
{/if}
<span class="price">{$finalPrice|escape:'html':'UTF-8'}</span>
```

---

### 5. Cron / CLI

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Entrypoint | Solo bootstrap y llamada a Service | 🔴 |
| Lógica | En Service, no en el script | 🔴 |

```php
// ❌ INCORRECTO - cron con lógica
// cron/sync_stock.php
$products = Db::getInstance()->executeS('SELECT * FROM ps_product');
foreach ($products as $product) {
    // 100 líneas de lógica de sincronización...
}

// ✅ CORRECTO - cron delega
// cron/sync_stock.php
require_once dirname(__FILE__) . '/../config/config.inc.php';
IagtStockSyncService::syncAll();
```

---

## 📊 INDICADORES DE PROBLEMA

| Señal de alerta | Acción |
|-----------------|--------|
| Hook > 15 líneas | Extraer a Service |
| Controller con SQL | Mover a Service/Repository |
| `new ObjectModel()` en controller | Mover creación a Service |
| `Mail::send()` en hook | Mover a Service |
| Cálculos en Smarty | Preparar datos en controller |
| Misma lógica en 2+ lugares | Centralizar en Service |

---

## 🛑 ANTI-PATTERNS

| Anti-Pattern | Problema |
|--------------|----------|
| God Controller | Controller que hace todo |
| Fat Hook | Hook con lógica compleja |
| Logic in View | Cálculos en templates |
| Scattered Logic | Misma lógica duplicada |
| Direct DB in Controller | SQL fuera de Service/Repository |

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

---


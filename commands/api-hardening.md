# /api-hardening

Verificación de seguridad y robustez para integraciones con APIs externas en PrestaShop 8.x 

Aplica cuando el código consume servicios externos (SAP, pasarelas de pago, ERPs, APIs REST).

---

## 📌 CUÁNDO EJECUTAR

- Código que hace llamadas HTTP a servicios externos
- Integraciones con SAP, ERPs, pasarelas de pago
- Consumo de APIs REST/SOAP
- Sincronización de datos con sistemas externos

---

## 🔍 CHECKLIST OBLIGATORIO

### 1. Configuración de Conexión

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Timeout | Configurado explícitamente | 🔴 |
| Connect timeout | Separado del read timeout | 🟡 |
| SSL verify | Activado en producción | 🔴 |
| Credenciales | En Configuration, nunca hardcodeadas | 🔴 |

```php
// ❌ CRÍTICO
$response = file_get_contents($url); // Sin timeout
$curl = curl_init();
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false); // Inseguro

// ✅ CORRECTO
$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $url,
    CURLOPT_TIMEOUT => 10,           // Read timeout
    CURLOPT_CONNECTTIMEOUT => 5,     // Connect timeout
    CURLOPT_SSL_VERIFYPEER => true,  // Verificar SSL
    CURLOPT_RETURNTRANSFER => true,
]);

// Credenciales desde Configuration
$apiKey = Configuration::get('ACME_API_KEY');
```

---

### 2. Manejo de Errores

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Try/catch | Envolver llamadas externas | 🔴 |
| HTTP status | Verificar código de respuesta | 🔴 |
| Errores de red | Manejar timeouts y conexión fallida | 🔴 |
| Logging | Registrar errores (sin datos sensibles) | 🟡 |

```php
// ❌ CRÍTICO
$response = json_decode(file_get_contents($url));
$data = $response->items; // Asume éxito

// ✅ CORRECTO
try {
    $ch = curl_init($url);
    // ... configuración
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        AcmeRateLimitedLogger::log('api_error', 'Connection failed: ' . $error, 3);
        return null;
    }
    
    if ($httpCode !== 200) {
        AcmeRateLimitedLogger::log('api_error', 'HTTP ' . $httpCode, 2);
        return null;
    }
    
    // Procesar respuesta...
    
} catch (Exception $e) {
    AcmeRateLimitedLogger::log('api_error', $e->getMessage(), 3);
    return null;
}
```

---

### 3. Validación de Respuesta

| Check | Criterio | Severidad |
|-------|----------|-----------|
| JSON válido | Verificar que decode no falle | 🔴 |
| Campos requeridos | Validar existencia | 🔴 |
| Tipos de datos | Verificar tipos esperados | 🔴 |
| Schema | Validar estructura completa | 🟡 |

```php
// ❌ CRÍTICO - Confía ciegamente
$data = json_decode($response, true);
$reservationId = $data['reservation_id'];

// ✅ CORRECTO
$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    AcmeRateLimitedLogger::log('api_error', 'Invalid JSON response', 3);
    return null;
}

// Validar campos requeridos
$required = ['reservation_id', 'status', 'items'];
foreach ($required as $field) {
    if (!isset($data[$field])) {
        AcmeRateLimitedLogger::log('api_error', 'Missing field: ' . $field, 3);
        return null;
    }
}

// Validar tipos
if (!is_string($data['reservation_id'])) {
    return null;
}
if (!is_array($data['items'])) {
    return null;
}
```

---

### 4. Rate Limiting en Logging

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Errores API | Rate-limited (5/minuto) | 🔴 |
| Lock failures | Rate-limited (1/minuto por key) | 🟡 |
| Operaciones normales | Sin límite | 🟢 |

```php
// ❌ CRÍTICO - Puede inundar logs
foreach ($items as $item) {
    if (!$this->processItem($item)) {
        PrestaShopLogger::addLog('Item failed: ' . $item['id'], 3);
    }
}

// ✅ CORRECTO
AcmeRateLimitedLogger::log('api_item_error', 'Processing failed', 3);
// O para deduplicar mensajes idénticos:
AcmeRateLimitedLogger::logUnique('api_error', $errorMessage, 3, 300);
```

---

### 5. Idempotencia

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Operaciones de escritura | Idempotency key | 🔴 |
| Reintentos | No duplicar efectos | 🔴 |
| Confirmaciones | Verificar estado antes de actuar | 🟡 |

```php
// ❌ PELIGROSO - Puede duplicar reservas
public function reserveStock($cartId, $products)
{
    return $this->callApi('/reserve', $products);
}

// ✅ CORRECTO - Idempotente
public function reserveStock($cartId, $products)
{
    // Generar key única para esta operación
    $idempotencyKey = $this->generateIdempotencyKey($cartId, $products);
    
    // Verificar si ya existe reserva
    $existing = $this->getExistingReservation($idempotencyKey);
    if ($existing !== null) {
        return $existing; // Retornar existente, no duplicar
    }
    
    // Crear nueva reserva
    return $this->callApi('/reserve', $products, $idempotencyKey);
}
```

---

### 6. Retry Strategy

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Límite de reintentos | Definido explícitamente | 🟡 |
| Backoff | Exponencial o con delay | 🟡 |
| Errores permanentes | No reintentar (4xx) | 🟡 |
| Errores temporales | Reintentar con límite (5xx, timeout) | 🟡 |

```php
// ✅ Retry pattern
$maxRetries = 3;
$retryDelay = 1; // segundos

for ($i = 0; $i < $maxRetries; $i++) {
    $result = $this->callApi($endpoint);
    
    if ($result !== null) {
        return $result;
    }
    
    if ($this->lastHttpCode >= 400 && $this->lastHttpCode < 500) {
        break; // Error cliente, no reintentar
    }
    
    sleep($retryDelay * ($i + 1)); // Backoff
}

return null;
```

---

### 7. Circuit Breaker (Enterprise)

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Detección de fallos | Contador de errores consecutivos | 🟡 |
| Estado abierto | No llamar API si está caída | 🟡 |
| Recovery | Intentar reconectar periódicamente | 🟡 |

---

## 🛑 ANTI-PATTERNS

| Anti-Pattern | Problema |
|--------------|----------|
| Sin timeout | Request puede colgar indefinidamente |
| SSL verify false | Vulnerable a MITM |
| Confiar en respuesta | Datos corruptos o maliciosos |
| Log sin rate limit | Puede colapsar disco/BD en cascada |
| Sin idempotencia | Operaciones duplicadas |
| Credenciales hardcodeadas | Exposición en código |

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


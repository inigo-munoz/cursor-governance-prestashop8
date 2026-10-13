# PrestaShop 8 - Enterprise Hardened Patterns v2.0

Patrones enterprise para entornos de alta concurrencia (locking, idempotencia, rate limiting).

Prerequisitos:
- Redis disponible en producción
- SAP soporta reservas temporales con TTL

---

# 1. Distributed Locking Pattern (Redis)

## 1.1 Lock Service Class

```php
<?php
if (!defined('_PS_VERSION_')) {
    exit;
}

/**
 * Distributed locking service using Redis
 * Prevents race conditions in concurrent operations
 */
class AcmeLockService
{
    const DEFAULT_TTL = 30; // seconds
    const RETRY_DELAY_MS = 50;
    const MAX_RETRIES = 20;

    private static $redis = null;

    /**
     * Get Redis connection (singleton)
     */
    private static function getRedis()
    {
        if (self::$redis === null) {
            self::$redis = new Redis();
            self::$redis->connect(
                Configuration::get('ACME_REDIS_HOST', null, null, null) ?: '127.0.0.1',
                (int)(Configuration::get('ACME_REDIS_PORT', null, null, null) ?: 6379)
            );
            
            $password = Configuration::get('ACME_REDIS_PASSWORD', null, null, null);
            if ($password) {
                self::$redis->auth($password);
            }
        }
        
        return self::$redis;
    }

    /**
     * Acquire lock with retry
     *
     * @param string $key Lock identifier
     * @param int $ttl Lock TTL in seconds
     * @return string|false Lock token or false if failed
     */
    public static function acquire($key, $ttl = self::DEFAULT_TTL)
    {
        $redis = self::getRedis();
        $token = bin2hex(random_bytes(16));
        $lockKey = 'lock:' . $key;

        for ($i = 0; $i < self::MAX_RETRIES; $i++) {
            // SET NX with TTL (atomic)
            $acquired = $redis->set(
                $lockKey,
                $token,
                ['NX', 'EX' => $ttl]
            );

            if ($acquired) {
                return $token;
            }

            // Wait before retry
            usleep(self::RETRY_DELAY_MS * 1000);
        }

        // Log failure (without flooding)
        self::logLockFailure($key);

        return false;
    }

    /**
     * Release lock (only if we own it)
     *
     * @param string $key Lock identifier
     * @param string $token Lock token from acquire()
     * @return bool
     */
    public static function release($key, $token)
    {
        $redis = self::getRedis();
        $lockKey = 'lock:' . $key;

        // Lua script for atomic check-and-delete
        $script = <<<LUA
            if redis.call("GET", KEYS[1]) == ARGV[1] then
                return redis.call("DEL", KEYS[1])
            else
                return 0
            end
LUA;

        return (bool)$redis->eval($script, [$lockKey, $token], 1);
    }

    /**
     * Execute callback with lock protection
     *
     * @param string $key Lock identifier
     * @param callable $callback Function to execute
     * @param int $ttl Lock TTL
     * @return mixed Callback result or null if lock failed
     */
    public static function withLock($key, callable $callback, $ttl = self::DEFAULT_TTL)
    {
        $token = self::acquire($key, $ttl);

        if ($token === false) {
            return null;
        }

        try {
            return $callback();
        } finally {
            self::release($key, $token);
        }
    }

    /**
     * Rate-limited logging for lock failures
     */
    private static function logLockFailure($key)
    {
        $redis = self::getRedis();
        $logKey = 'locklog:' . $key;

        // Only log once per minute per key
        if ($redis->set($logKey, '1', ['NX', 'EX' => 60])) {
            PrestaShopLogger::addLog(
                'Lock acquisition failed: ' . pSQL($key),
                2,
                null,
                'AcmeLockService'
            );
        }
    }
}
```

---

# 2. SAP Integration with Idempotency

## 2.1 Reservation Pattern

```php
<?php
if (!defined('_PS_VERSION_')) {
    exit;
}

/**
 * SAP Stock Service with reservation support
 * Implements idempotent operations with distributed locking
 */
class AcmeSapStockService
{
    const RESERVATION_TTL = 300; // 5 minutes
    const REQUEST_TIMEOUT = 10;
    const CONNECT_TIMEOUT = 5;

    /**
     * Reserve stock for cart (idempotent)
     *
     * @param int $idCart Cart ID
     * @param array $products Array of [id_product => quantity]
     * @return array|null Reservation result or null on failure
     */
    public static function reserveStock($idCart, array $products)
    {
        // Idempotency key based on cart + products hash
        $idempotencyKey = self::generateIdempotencyKey($idCart, $products);
        
        // Check for existing reservation
        $existing = self::getExistingReservation($idempotencyKey);
        if ($existing !== null) {
            return $existing;
        }

        // Acquire lock for this cart
        $lockKey = 'sap:reserve:cart:' . (int)$idCart;
        
        return AcmeLockService::withLock($lockKey, function() use ($idCart, $products, $idempotencyKey) {
            // Double-check after acquiring lock
            $existing = self::getExistingReservation($idempotencyKey);
            if ($existing !== null) {
                return $existing;
            }

            // Call SAP to reserve
            $result = self::callSapReserve($idCart, $products);

            if ($result !== null && isset($result['reservation_id'])) {
                // Store reservation for idempotency
                self::storeReservation($idempotencyKey, $result);
            }

            return $result;
        }, 30);
    }

    /**
     * Confirm reservation (convert to actual stock decrement)
     *
     * @param string $reservationId SAP reservation ID
     * @param int $idOrder PrestaShop order ID
     * @return bool
     */
    public static function confirmReservation($reservationId, $idOrder)
    {
        // Lock by reservation to prevent double confirm
        $lockKey = 'sap:confirm:' . $reservationId;

        $result = AcmeLockService::withLock($lockKey, function() use ($reservationId, $idOrder) {
            return self::callSapConfirm($reservationId, $idOrder);
        }, 30);

        return $result === true;
    }

    /**
     * Cancel reservation (release reserved stock)
     *
     * @param string $reservationId SAP reservation ID
     * @return bool
     */
    public static function cancelReservation($reservationId)
    {
        return self::callSapCancel($reservationId) === true;
    }

    /**
     * Generate idempotency key
     */
    private static function generateIdempotencyKey($idCart, array $products)
    {
        ksort($products);
        $data = json_encode(['cart' => (int)$idCart, 'products' => $products]);
        return 'reserve:' . hash('sha256', $data);
    }

    /**
     * Get existing reservation from Redis
     */
    private static function getExistingReservation($idempotencyKey)
    {
        $redis = self::getRedis();
        $data = $redis->get($idempotencyKey);
        
        if ($data) {
            return json_decode($data, true);
        }
        
        return null;
    }

    /**
     * Store reservation in Redis with TTL
     */
    private static function storeReservation($idempotencyKey, array $result)
    {
        $redis = self::getRedis();
        $redis->setex(
            $idempotencyKey,
            self::RESERVATION_TTL,
            json_encode($result)
        );
    }

    /**
     * Call SAP reserve endpoint
     */
    private static function callSapReserve($idCart, array $products)
    {
        $payload = [
            'cart_id' => (int)$idCart,
            'items' => [],
            'ttl_seconds' => self::RESERVATION_TTL,
        ];

        foreach ($products as $idProduct => $quantity) {
            $payload['items'][] = [
                'product_id' => (int)$idProduct,
                'quantity' => (int)$quantity,
            ];
        }

        $response = self::doRequest(
            '/stock/reserve',
            'POST',
            $payload
        );

        return self::validateReserveResponse($response);
    }

    /**
     * Call SAP confirm endpoint
     */
    private static function callSapConfirm($reservationId, $idOrder)
    {
        $response = self::doRequest(
            '/stock/confirm',
            'POST',
            [
                'reservation_id' => $reservationId,
                'order_id' => (int)$idOrder,
            ]
        );

        if ($response && isset($response['confirmed']) && $response['confirmed'] === true) {
            return true;
        }

        return false;
    }

    /**
     * Call SAP cancel endpoint
     */
    private static function callSapCancel($reservationId)
    {
        $response = self::doRequest(
            '/stock/cancel',
            'POST',
            ['reservation_id' => $reservationId]
        );

        return $response && isset($response['cancelled']) && $response['cancelled'] === true;
    }

    /**
     * Validate reserve response structure
     */
    private static function validateReserveResponse($response)
    {
        if (!is_array($response)) {
            return null;
        }

        // Required fields
        $required = ['reservation_id', 'expires_at', 'items'];
        foreach ($required as $field) {
            if (!isset($response[$field])) {
                self::logValidationError('Missing field: ' . $field);
                return null;
            }
        }

        // Type validation
        if (!is_string($response['reservation_id']) || empty($response['reservation_id'])) {
            self::logValidationError('Invalid reservation_id');
            return null;
        }

        if (!is_array($response['items'])) {
            self::logValidationError('Invalid items format');
            return null;
        }

        return $response;
    }

    /**
     * Execute HTTP request to SAP
     */
    private static function doRequest($endpoint, $method, array $payload = null)
    {
        $baseUrl = Configuration::get('ACME_SAP_URL');
        $apiKey = Configuration::get('ACME_SAP_API_KEY');

        if (!$baseUrl || !$apiKey) {
            self::logError('SAP configuration missing');
            return null;
        }

        $ch = curl_init();

        curl_setopt_array($ch, [
            CURLOPT_URL => rtrim($baseUrl, '/') . $endpoint,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_CONNECTTIMEOUT => self::CONNECT_TIMEOUT,
            CURLOPT_TIMEOUT => self::REQUEST_TIMEOUT,
            CURLOPT_HTTPHEADER => [
                'Content-Type: application/json',
                'Accept: application/json',
                'X-Api-Key: ' . $apiKey,
            ],
        ]);

        if ($method === 'POST' && $payload !== null) {
            curl_setopt($ch, CURLOPT_POST, true);
            curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
        }

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);

        curl_close($ch);

        if ($response === false) {
            self::logError('Connection failed: ' . $error);
            return null;
        }

        if ($httpCode < 200 || $httpCode >= 300) {
            self::logError('HTTP ' . (int)$httpCode . ' on ' . $endpoint);
            return null;
        }

        $data = json_decode($response, true);

        if (!is_array($data)) {
            self::logError('Invalid JSON response');
            return null;
        }

        return $data;
    }

    /**
     * Rate-limited error logging
     */
    private static function logError($message)
    {
        self::logWithRateLimit('sap:error', $message, 3);
    }

    private static function logValidationError($message)
    {
        self::logWithRateLimit('sap:validation', $message, 2);
    }

    private static function logWithRateLimit($category, $message, $severity)
    {
        $redis = self::getRedis();
        $key = 'log:' . $category . ':' . md5($message);

        // Log max once per minute per unique message
        if ($redis->set($key, '1', ['NX', 'EX' => 60])) {
            PrestaShopLogger::addLog(
                'SAP: ' . $message,
                $severity,
                null,
                'AcmeSapStockService'
            );
        }
    }

    private static function getRedis()
    {
        static $redis = null;
        
        if ($redis === null) {
            $redis = new Redis();
            $redis->connect(
                Configuration::get('ACME_REDIS_HOST') ?: '127.0.0.1',
                (int)(Configuration::get('ACME_REDIS_PORT') ?: 6379)
            );
        }
        
        return $redis;
    }
}
```

---

# 3. ValidateOrder Race Condition Protection

## 3.1 Hook Implementation in Module

```php
<?php
if (!defined('_PS_VERSION_')) {
    exit;
}

require_once _PS_MODULE_DIR_ . 'vendor_sapstock/classes/AcmeLockService.php';
require_once _PS_MODULE_DIR_ . 'vendor_sapstock/classes/AcmeSapStockService.php';

class Acme_Sapstock extends Module
{
    public function __construct()
    {
        $this->name = 'vendor_sapstock';
        $this->version = '1.0.0';
        $this->author = 'Acme';
        $this->need_instance = 0;
        $this->bootstrap = true;

        parent::__construct();

        $this->displayName = $this->l('SAP Stock Integration');
        $this->description = $this->l('Real-time stock validation with SAP');
    }

    public function install()
    {
        return parent::install()
            && $this->registerHook('actionBeforeValidateOrder');
    }

    /**
     * Hook: Before order validation
     * Reserves stock in SAP with race condition protection
     *
     * @param array $params Hook parameters from override
     * @throws PrestaShopException If reservation fails
     */
    public function hookActionBeforeValidateOrder($params)
    {
        $idCart = (int)$params['id_cart'];

        if (!$idCart) {
            return;
        }

        // Load cart
        $cart = new Cart($idCart);
        
        if (!Validate::isLoadedObject($cart)) {
            throw new PrestaShopException('Invalid cart');
        }

        // Get products from cart
        $products = [];
        foreach ($cart->getProducts() as $product) {
            $idProduct = (int)$product['id_product'];
            $quantity = (int)$product['cart_quantity'];
            
            if ($idProduct && $quantity > 0) {
                $products[$idProduct] = $quantity;
            }
        }

        if (empty($products)) {
            return;
        }

        // Reserve stock in SAP (with locking + idempotency)
        $reservation = AcmeSapStockService::reserveStock($idCart, $products);

        if ($reservation === null) {
            throw new PrestaShopException(
                $this->l('Unable to verify stock availability. Please try again.')
            );
        }

        // Store reservation ID for confirmation after order creation
        // Using cart cookie to pass to actionValidateOrder hook
        $this->context->cookie->__set(
            'vendor_sap_reservation_' . $idCart,
            $reservation['reservation_id']
        );
    }

    /**
     * Hook: After order validation
     * Confirms the SAP reservation
     */
    public function hookActionValidateOrder($params)
    {
        $order = $params['order'];
        $idCart = (int)$order->id_cart;

        $reservationId = $this->context->cookie->__get('vendor_sap_reservation_' . $idCart);

        if (!$reservationId) {
            return;
        }

        // Confirm reservation
        $confirmed = AcmeSapStockService::confirmReservation(
            $reservationId,
            (int)$order->id
        );

        if (!$confirmed) {
            // Log but don't fail - order already created
            PrestaShopLogger::addLog(
                'SAP reservation confirm failed: ' . pSQL($reservationId) . ' for order ' . (int)$order->id,
                3,
                null,
                'Acme_Sapstock'
            );
        }

        // Clean up cookie
        $this->context->cookie->__unset('vendor_sap_reservation_' . $idCart);
    }
}
```

---

# 4. Rate-Limited Logging Service

## 4.1 Generic Rate Limiter

```php
<?php
if (!defined('_PS_VERSION_')) {
    exit;
}

/**
 * Rate-limited logging to prevent log flooding
 */
class AcmeRateLimitedLogger
{
    const DEFAULT_WINDOW = 60; // seconds
    const DEFAULT_MAX_PER_WINDOW = 5;

    /**
     * Log with rate limiting
     *
     * @param string $category Log category for grouping
     * @param string $message Log message
     * @param int $severity PrestaShop severity (1=info, 2=warning, 3=error)
     * @param int $windowSeconds Time window for rate limit
     * @param int $maxPerWindow Max logs per window
     */
    public static function log(
        $category,
        $message,
        $severity = 2,
        $windowSeconds = self::DEFAULT_WINDOW,
        $maxPerWindow = self::DEFAULT_MAX_PER_WINDOW
    ) {
        $redis = self::getRedis();
        $key = 'lograte:' . $category;

        // Increment counter
        $count = $redis->incr($key);

        // Set expiry on first increment
        if ($count === 1) {
            $redis->expire($key, $windowSeconds);
        }

        // Check if under limit
        if ($count <= $maxPerWindow) {
            PrestaShopLogger::addLog(
                '[' . $category . '] ' . $message,
                $severity,
                null,
                'AcmeRateLimitedLogger'
            );
        } elseif ($count === $maxPerWindow + 1) {
            // Log once that we're suppressing
            PrestaShopLogger::addLog(
                '[' . $category . '] Rate limit reached, suppressing further logs',
                1,
                null,
                'AcmeRateLimitedLogger'
            );
        }
    }

    /**
     * Log unique messages only (deduplicated)
     *
     * @param string $category Log category
     * @param string $message Log message
     * @param int $severity Severity level
     * @param int $dedupeSeconds Deduplication window
     */
    public static function logUnique($category, $message, $severity = 2, $dedupeSeconds = 300)
    {
        $redis = self::getRedis();
        $hash = md5($message);
        $key = 'logdedupe:' . $category . ':' . $hash;

        // Only log if not seen in window
        if ($redis->set($key, '1', ['NX', 'EX' => $dedupeSeconds])) {
            PrestaShopLogger::addLog(
                '[' . $category . '] ' . $message,
                $severity,
                null,
                'AcmeRateLimitedLogger'
            );
        }
    }

    private static function getRedis()
    {
        static $redis = null;
        
        if ($redis === null) {
            $redis = new Redis();
            $redis->connect(
                Configuration::get('ACME_REDIS_HOST') ?: '127.0.0.1',
                (int)(Configuration::get('ACME_REDIS_PORT') ?: 6379)
            );
        }
        
        return $redis;
    }
}
```

---

# 5. AJAX Method Validation

Ver implementación completa en `security/prestashop-security-reference.md` — Rule 4.

---

# 6. External API Response Validation Pattern

```php
/**
 * Validate API response against expected schema
 *
 * @param mixed $response Decoded JSON response
 * @param array $schema Expected schema definition
 * @return bool
 */
public static function validateResponseSchema($response, array $schema)
{
    if (!is_array($response)) {
        return false;
    }

    foreach ($schema as $field => $rules) {
        // Check required
        if (!empty($rules['required']) && !isset($response[$field])) {
            return false;
        }

        // Skip if not present and not required
        if (!isset($response[$field])) {
            continue;
        }

        $value = $response[$field];

        // Type check
        if (isset($rules['type'])) {
            switch ($rules['type']) {
                case 'int':
                    if (!is_int($value)) return false;
                    break;
                case 'string':
                    if (!is_string($value)) return false;
                    break;
                case 'array':
                    if (!is_array($value)) return false;
                    break;
                case 'bool':
                    if (!is_bool($value)) return false;
                    break;
            }
        }

        // Min/max for numbers
        if (isset($rules['min']) && $value < $rules['min']) {
            return false;
        }
        if (isset($rules['max']) && $value > $rules['max']) {
            return false;
        }

        // Pattern for strings
        if (isset($rules['pattern']) && is_string($value)) {
            if (!preg_match($rules['pattern'], $value)) {
                return false;
            }
        }
    }

    return true;
}

// Usage example:
$schema = [
    'reservation_id' => ['required' => true, 'type' => 'string', 'pattern' => '/^[A-Z0-9-]+$/'],
    'expires_at' => ['required' => true, 'type' => 'string'],
    'items' => ['required' => true, 'type' => 'array'],
    'total_reserved' => ['required' => false, 'type' => 'int', 'min' => 0],
];

if (!self::validateResponseSchema($response, $schema)) {
    self::logValidationError('Invalid response schema');
    return null;
}
```

---

# 7. Hook Exception Clarification

## UI Hooks (display*)

```php
// Never throw exceptions - return empty string on error
public function hookDisplayHeader($params)
{
    try {
        // Logic
    } catch (Exception $e) {
        // Log but don't throw
        AcmeRateLimitedLogger::log('hook_display', $e->getMessage(), 2);
        return '';
    }
}
```

## Critical Business Hooks (action*)

```php
// Throwing exceptions IS allowed to abort operations
public function hookActionBeforeValidateOrder($params)
{
    $result = AcmeSapStockService::reserveStock(...);
    
    if ($result === null) {
        // Throw to abort order - this IS the expected behavior
        throw new PrestaShopException('Stock reservation failed');
    }
}
```

**Rule:**
- `display*` hooks → Never throw, always return gracefully
- `action*` hooks that affect data integrity → May throw to abort operation
- Document in hook PHPDoc whether exceptions are expected

---

# 8. Configuration Keys

Required in `ps_configuration`:

```php
// Redis
'ACME_REDIS_HOST' => '127.0.0.1'
'ACME_REDIS_PORT' => '6379'
'ACME_REDIS_PASSWORD' => '' // Optional

// SAP
'ACME_SAP_URL' => 'https://sap.example.com/api'
'ACME_SAP_API_KEY' => '***' // Store securely
```

---

# 9. Checklist Enterprise Hardened

- [ ] Redis connection configured and tested
- [ ] AcmeLockService available in shared classes
- [ ] AcmeRateLimitedLogger used for all external API logs
- [ ] AJAX endpoints validate POST method
- [ ] External API responses validated against schema
- [ ] SAP integration uses reservation pattern
- [ ] actionBeforeValidateOrder hook implemented
- [ ] Lock TTLs appropriate for operation duration
- [ ] Idempotency keys generated consistently
- [ ] Cookie cleanup after order confirmation

---

# 10. Failure Scenarios and Behavior

| Scenario | Behavior |
|----------|----------|
| Redis down | Lock acquire fails → operation blocked |
| SAP timeout | Reservation returns null → order blocked |
| SAP returns invalid schema | Validation fails → order blocked |
| Double submit (same cart) | Idempotency returns cached reservation |
| Lock not released (crash) | TTL expires → auto-release |
| Order created but confirm fails | Logged as error, order exists, manual reconciliation needed |

---

## Document Version

Enterprise Hardened Patterns v2.0
Last reviewed: 2026-02-13
Owner: Tech Lead

Extends Patterns v1.1 for high-concurrency environments.

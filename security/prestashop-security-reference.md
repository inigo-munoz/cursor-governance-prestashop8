# PrestaShop 8 — Security Reference v2.0

Ejemplos de código completos para cada regla.
Reglas normativas en `prestashop-security.md`.

---

## Rule 1: Input Validation

```php
// ✅ Integers
$id = (int)Tools::getValue('id_customer');

// ✅ Strings SQL
$email = pSQL(Tools::getValue('email'));

// ✅ LIKE wildcards
$search = str_replace(['%', '_'], ['\\%', '\\_'], pSQL($search));
$sql = "WHERE name LIKE '%" . $search . "%'";

// ✅ Arrays
$ids = isset($_POST['ids']) && is_array($_POST['ids'])
    ? array_map('intval', $_POST['ids']) : [];

// ❌ Prohibido
$id = $_GET['id_customer'];
```

## Rule 2: SQL Injection

```php
// ✅ Columnas dinámicas con whitelist
$allowed = ['name', 'email', 'date_add'];
$col = in_array(Tools::getValue('sort'), $allowed, true)
    ? Tools::getValue('sort') : 'date_add';
$sql = "ORDER BY `" . bqSQL($col) . "`";

// ✅ DbQuery
$query = new DbQuery();
$query->select('c.id_customer, c.email')
      ->from('customer', 'c')
      ->where('c.id_customer = ' . (int)$id)
      ->where('c.id_shop = ' . (int)$idShop);
$result = Db::getInstance()->executeS($query);

// ✅ IN
$ids = array_map('intval', $ids);
$sql = 'WHERE id_product IN (' . implode(',', $ids) . ')';
```

## Rule 3: CSRF

```php
// ✅ Timing-safe
if (!hash_equals(Tools::getToken(false), Tools::getValue('token'))) {
    Tools::redirect('index.php?controller=pagenotfound');
}
// ❌ Prohibido
if ($token === Tools::getValue('token')) { ... }
```

```smarty
<input type="hidden" name="token" value="{Tools::getToken(false)}">
```

## Rule 4: AJAX

```php
// ✅ Patrón obligatorio
public function displayAjaxUpdate()
{
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        $this->ajaxRender(json_encode(['error' => 'method_not_allowed']));
        return;
    }
    if (!hash_equals(Tools::getToken(false), Tools::getValue('token'))) {
        $this->ajaxRender(json_encode(['error' => 'invalid_token']));
        return;
    }
    $this->ajaxRender(json_encode(['success' => true]));
}
```

## Rule 5: APIs Externas

```php
// ✅ Configuración completa
$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL            => $url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT        => 10,
    CURLOPT_CONNECTTIMEOUT => 5,
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_SSL_VERIFYHOST => 2,
]);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error    = curl_error($ch);
curl_close($ch);

if ($error || $httpCode !== 200) {
    AcmeRateLimitedLogger::log('api_error', "HTTP $httpCode: $error", 5);
    return null;
}

// ✅ Validar respuesta
$data = json_decode($response, true);
if (!is_array($data)) { return null; }
foreach (['id', 'status', 'items'] as $field) {
    if (!isset($data[$field])) { return null; }
}
```

## Rule 7: File Uploads

```php
public function handleUpload($file)
{
    if ($file['error'] !== UPLOAD_ERR_OK) { return ['error' => 'upload_failed']; }

    $allowed_ext  = ['jpg','jpeg','png','gif'];
    $allowed_mime = ['image/jpeg','image/png','image/gif'];
    $ext  = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    $mime = finfo_file(finfo_open(FILEINFO_MIME_TYPE), $file['tmp_name']);

    if (!in_array($ext,  $allowed_ext,  true)) { return ['error' => 'invalid_ext'];   }
    if (!in_array($mime, $allowed_mime, true)) { return ['error' => 'invalid_mime'];  }
    if (!getimagesize($file['tmp_name']))       { return ['error' => 'invalid_image']; }

    $name = uniqid('img_') . '.' . $ext;
    move_uploaded_file($file['tmp_name'], _PS_MODULE_DIR_ . 'vendor_module/uploads/' . $name);
    return ['success' => true, 'filename' => $name];
}
```

## Rule 12: Rate-Limited Logging

```php
AcmeRateLimitedLogger::log('sap_error', $message, 5);          // máx 5/min
AcmeRateLimitedLogger::logUnique('sap_error', $message, 3, 300); // deduplicado 5 min
```

| Tipo de log | Rate limit |
|-------------|------------|
| Errores API externa | 5/min |
| Lock failures | 1/min por key |
| Validation failures | 10/min |
| Operaciones normales | Sin límite |

## Rule 13: Distributed Locking

```php
$lockKey = 'sap:reserve:cart:' . (int)$cartId;

$result = AcmeLockService::withLock($lockKey, function() use ($products) {
    return $operationResult;
}, 30);

if ($result === null) {
    AcmeRateLimitedLogger::log('lock_fail', 'Could not acquire: ' . $lockKey, 2);
    throw new PrestaShopException('Operation busy, try again');
}
```

| Operación | TTL recomendado |
|-----------|-----------------|
| API call simple | 10–15 s |
| API call compleja | 30 s |
| Proceso multi-paso | 60 s |
| Cron batch | 120 s |

---

Versión: 2.0 — Requiere Redis para Rules 12–13

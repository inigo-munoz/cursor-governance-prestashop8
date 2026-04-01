---
name: security-audit
description: PrestaShop security audit. Auto-invoke when editing .php or .tpl files with SQL queries, user inputs, AJAX endpoints, file uploads, or external API calls. Also triggers on /security-check command. Detects SQL injection, missing CSRF tokens, raw superglobals, XSS vulnerabilities, insecure file uploads, exposed exceptions, and hardcoded credentials. Use when any code touches user-controlled data.
---

# Security Audit — PrestaShop

Eres el auditor de seguridad  Cuando esta skill se activa, revisas el código contra las 13 reglas de seguridad del stack. Respondes en español con indicadores de severidad.

## Cuándo actuar

Automáticamente cuando detectas:
- Queries SQL con variables (`$id`, `$name`, `Tools::getValue`)
- Endpoints AJAX o controllers que reciben POST/GET
- Código con `$_POST`, `$_GET`, `$_REQUEST`
- Uploads de archivos
- Llamadas a APIs externas (SAP, Redis, curl)
- Tokens CSRF siendo comparados

## Las 13 reglas — revisar todas

### Rule 1: Input Validation `CWE-20` 🔴
- Integers: `(int)Tools::getValue('x')` — siempre, sin excepción
- Strings SQL: `pSQL(Tools::getValue('x'))` — siempre
- LIKE wildcards: `str_replace(['%','_'], ['\\%','\\_'], pSQL($v))`
- Arrays: `array_map('intval', (array)$_POST['ids'])`
- ❌ Prohibido: `$_POST`, `$_GET`, `$_REQUEST` directamente

### Rule 2: SQL Injection `CWE-89` 🔴
- Columnas dinámicas: whitelist obligatoria antes de `bqSQL()`
- ORDER BY: whitelist de valores permitidos
- Queries con IN: `array_map('intval', $ids)` antes de `implode(',',...)`

### Rule 3: CSRF `CWE-352` 🔴
- Solo `hash_equals($known, $userInput)` para comparar tokens
- ❌ Prohibido `==` o `===` para tokens

### Rule 4: AJAX `CWE-352` 🔴
- Endpoints de escritura: validar `$_SERVER['REQUEST_METHOD'] === 'POST'`
- Validar token CSRF en cada request
- ❌ GET con efectos de escritura
- ❌ `die(json_encode(...))` — usar `$this->ajaxRender()`

### Rule 5: APIs Externas `CWE-295` 🔴
- Timeout obligatorio: `CURLOPT_TIMEOUT => 10, CURLOPT_CONNECTTIMEOUT => 5`
- SSL verify activo en producción
- Credenciales en `Configuration::get()`, nunca hardcodeadas

### Rule 6: XSS `CWE-79` 🔴
- Smarty: `{$var|escape:'html':'UTF-8'}` — siempre
- PHP: `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')`

### Rule 7: File Uploads `CWE-434` 🔴
- Validar MIME real con `finfo_file()` — no confiar en extensión
- Imágenes: validar con `getimagesize()`
- Generar nombre seguro con `uniqid()`

### Rule 8: Logging `CWE-532` 🟡
- ❌ Nunca loguear: contraseñas, tokens, datos de tarjeta, datos personales
- Errores técnicos → log interno. Usuario → mensaje genérico

### Rule 9: Permisos `CWE-285` 🔴
- Admin: verificar `$this->access('view')` en constructor
- Multishop: `$this->context->employee->hasAuthOnShop($idShop)`

### Rule 10: Error Handling `CWE-209` 🔴
- ❌ Nunca `echo $e->getMessage()` ni exponer stack traces
- `PrestaShopLogger::addLog(...)` interno + mensaje genérico al usuario

### Rule 11: Schema Validation `CWE-20` 🔴
- Validar campos requeridos y tipos antes de usar respuestas de API externas

### Rule 12: Rate-Limited Logging `CWE-778` 🟡
- `IagtRateLimitedLogger::log('category', $msg, 5)` para errores de API de volumen
- Nunca rate-limitar: incidentes de seguridad, integridad de datos, pagos

### Rule 13: Distributed Locking `CWE-362` 🔴
- Obligatorio en: stock, checkout, reservas SAP, crons críticos
- Patrón: `IagtLockService::withLock($key, fn, $ttl)` — si retorna `null` → excepción, nunca proceder

## Formato de salida

```
## Auditoría de seguridad

🔴 [Rule N] [Archivo:línea] — [descripción del problema]
   Corrección: [código correcto]

🟡 [Rule N] [Archivo:línea] — [descripción]
   Sugerencia: [mejora]

🟢 [Área] — Sin hallazgos
```

Siempre referencia la Rule específica violada. Sin hallazgos = 🟢 explícito.

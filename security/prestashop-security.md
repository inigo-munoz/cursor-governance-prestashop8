# PrestaShop 8 — Security Rules v2.0

> 🔴 Todo input es hostil hasta que se demuestre lo contrario.
> Prioridad: Seguridad > Estabilidad > Rendimiento > Conveniencia.

---

## Rule 1: Input Validation
`CWE-20` · `OWASP A03:2021 Injection`

- Integers: `(int)Tools::getValue('x')` — siempre, sin excepción
- Strings SQL: `pSQL(Tools::getValue('x'))` — siempre
- LIKE wildcards: `str_replace(['%','_'], ['\\%','\\_'], pSQL($v))`
- Arrays: `array_map('intval', (array)$_POST['ids'])`
- Floats: `(float)Tools::getValue('x')`
- ❌ Prohibido: `$_POST`, `$_GET`, `$_REQUEST` directamente

## Rule 2: SQL Injection
`CWE-89` · `OWASP A03:2021 Injection`

- Columnas dinámicas: whitelist obligatoria antes de `bqSQL()`
- ORDER BY: whitelist de valores permitidos
- Queries con IN: `array_map('intval', $ids)` antes de `implode(',',...)`
- Preferir `DbQuery` para queries complejas

## Rule 3: CSRF
`CWE-352` · `OWASP A01:2021 Broken Access Control`

- Comparar tokens solo con `hash_equals($known, $userInput)`
- ❌ Prohibido `==` o `===` para tokens

## Rule 4: AJAX
`CWE-352` · `CWE-749` · `OWASP A01:2021 Broken Access Control`

- Endpoints de escritura: validar `$_SERVER['REQUEST_METHOD'] === 'POST'`
- Validar token CSRF en cada request
- ❌ Prohibido GET con efectos de escritura
- ❌ Prohibido `die(json_encode(...))` — usar `$this->ajaxRender()`

## Rule 5: APIs Externas
`CWE-295` · `CWE-798` · `OWASP A02:2021 Cryptographic Failures`

- Timeout obligatorio: `CURLOPT_TIMEOUT => 10, CURLOPT_CONNECTTIMEOUT => 5`
- SSL verify activo en producción
- Validar estructura de respuesta antes de usarla
- Credenciales en `Configuration::get()`, nunca hardcodeadas

## Rule 6: XSS
`CWE-79` · `OWASP A03:2021 Injection`

- Smarty: `{$var|escape:'html':'UTF-8'}` — siempre
- PHP: `htmlspecialchars($v, ENT_QUOTES, 'UTF-8')`

## Rule 7: File Uploads
`CWE-434` · `OWASP A04:2021 Insecure Design`

- Validar MIME real con `finfo_file()` — no confiar en extensión
- Imágenes: validar con `getimagesize()`
- Generar nombre seguro con `uniqid()`

## Rule 8: Logging
`CWE-532` · `CWE-778` · `OWASP A09:2021 Security Logging and Monitoring Failures`

- ❌ Nunca loguear: contraseñas, tokens, datos de tarjeta, datos personales
- Errores técnicos → log interno. Usuario → mensaje genérico
- APIs con volumen: usar `AcmeRateLimitedLogger` (max 5 errores/min)

## Rule 9: Permisos
`CWE-285` · `CWE-863` · `OWASP A01:2021 Broken Access Control`

- Admin: verificar `$this->access('view')` en constructor
- Multishop: `$this->context->employee->hasAuthOnShop($idShop)`

## Rule 10: Error Handling
`CWE-209` · `OWASP A05:2021 Security Misconfiguration`

- ❌ Nunca `echo $e->getMessage()` ni exponer stack traces
- `PrestaShopLogger::addLog(...)` interno + mensaje genérico al usuario

## Rule 11: Schema Validation
`CWE-20` · `CWE-1287` · `OWASP A03:2021 Injection`

- Validar campos requeridos y tipos antes de usar respuestas de API externas

## Rule 12: Rate-Limited Logging
`CWE-778` · `OWASP A09:2021 Security Logging and Monitoring Failures`

- `AcmeRateLimitedLogger::log('category', $msg, 5)` para errores de API
- Nunca rate-limitar: incidentes de seguridad, integridad de datos, pagos

## Rule 13: Distributed Locking
`CWE-362` · `CWE-667` · `OWASP A04:2021 Insecure Design`

- Obligatorio en: stock, checkout, reservas SAP, crons críticos
- Patrón: `AcmeLockService::withLock($key, fn, $ttl)` — si retorna `null` → lanzar excepción, nunca proceder
- Lock key: formato `operation:entity_type:entity_id`
- TTL = tiempo esperado + 50% buffer

---

## Anti-patterns prohibidos

❌ SQL sin cast · ❌ Identificadores dinámicos sin whitelist · ❌ `die()` en producción
❌ Raw `$_POST/$_GET` · ❌ Lógica en Smarty · ❌ MIME por extensión
❌ Exponer excepciones · ❌ Loguear datos sensibles · ❌ APIs sin timeout
❌ AJAX GET para escritura · ❌ Logging ilimitado en errores · ❌ Operaciones críticas sin locking

---

## Referencia completa con ejemplos de código

`security/prestashop-security-reference.md`

---

Versión: 2.0 — Requiere Redis para Rules 12–13
Refs: [OWASP Top 10 2021](https://owasp.org/Top10/) · [CWE/SANS Top 25](https://cwe.mitre.org/top25/)

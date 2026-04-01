# /security-check

Auditoría de seguridad profunda para código PrestaShop 8.x 

Este command realiza verificación exhaustiva de seguridad.
Complementa a `/review`, no lo sustituye.

---

## 📌 CUÁNDO EJECUTAR

- Código con queries SQL (SELECT, INSERT, UPDATE, DELETE)
- Código que procesa inputs de usuario (formularios, AJAX, URLs)
- Endpoints AJAX o APIs
- Código que maneja uploads de archivos
- Integraciones con APIs externas

---

## 🔍 CHECKLIST OBLIGATORIO

### 1. SQL Injection

| Check | Criterio | Ejemplo correcto | Severidad |
|-------|----------|------------------|-----------|
| Integers | `(int)` cast obligatorio | `$id = (int) Tools::getValue('id')` | 🔴 |
| Strings | `pSQL()` obligatorio | `$name = pSQL(Tools::getValue('name'))` | 🔴 |
| LIKE | Escapar wildcards | `str_replace(['%','_'], ['\%','\_'], pSQL($v))` | 🔴 |
| Arrays | Sanitizar elementos | `array_map('intval', (array) $ids)` | 🔴 |
| Columnas dinámicas | Whitelist + `bqSQL()` | `in_array($col, $allowed) ? bqSQL($col) : 'id'` | 🔴 |
| ORDER BY | Whitelist obligatoria | `$allowed = ['name', 'date_add']` | 🔴 |

```php
// ❌ CRÍTICO - Nunca hacer
$sql = "SELECT * FROM ps_table WHERE id = " . $_GET['id'];
$sql = "SELECT * FROM ps_table WHERE name = '" . $name . "'";
$sql = "ORDER BY " . Tools::getValue('sort');

// ✅ CORRECTO
$id = (int) Tools::getValue('id');
$name = pSQL(Tools::getValue('name'));
$sort = in_array($s, ['name','date']) ? bqSQL($s) : 'id';
```

---

### 2. Input Handling

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Raw superglobals | Prohibido `$_POST`, `$_GET`, `$_REQUEST` | 🔴 |
| Tools::getValue | Usar siempre con validación posterior | 🔴 |
| Type validation | Validar tipo esperado | 🟡 |
| Whitelist | Valores permitidos cuando aplique | 🟡 |

```php
// ❌ CRÍTICO
$id = $_POST['id'];

// ✅ CORRECTO
$id = (int) Tools::getValue('id');
if ($id <= 0) {
    return false;
}
```

---

### 3. XSS Prevention

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Smarty | `{\$var\|escape:'html':'UTF-8'}` | 🔴 |
| HTML directo | `htmlspecialchars($var, ENT_QUOTES, 'UTF-8')` | 🔴 |
| JavaScript | Nunca insertar input en JS sin sanitizar | 🔴 |

```smarty
{* ❌ CRÍTICO *}
{$userInput}

{* ✅ CORRECTO *}
{$userInput|escape:'html':'UTF-8'}
```

---

### 4. CSRF Protection

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Token presente | Formularios con token | 🔴 |
| Comparación segura | `hash_equals()` obligatorio | 🔴 |
| Comparación insegura | Prohibido `==` o `===` para tokens | 🔴 |

```php
// ❌ CRÍTICO
if ($token === Tools::getValue('token')) { }
if ($token == $userToken) { }

// ✅ CORRECTO
if (!hash_equals($knownToken, Tools::getValue('token'))) {
    return false;
}
```

---

### 5. AJAX Security

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Método HTTP | POST obligatorio para escritura | 🔴 |
| Validar método | Verificar `$_SERVER['REQUEST_METHOD']` | 🔴 |
| Token | Validar CSRF en cada request | 🔴 |
| Permisos | Verificar autorización | 🔴 |

```php
// ✅ Patrón obligatorio para AJAX
public function displayAjax()
{
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        $this->sendJsonAndExit(['error' => 'method_not_allowed']);
    }
    
    if (!hash_equals(Tools::getToken(false), Tools::getValue('token'))) {
        $this->sendJsonAndExit(['error' => 'invalid_token']);
    }
    
    // Continuar...
}
```

---

### 6. File Uploads

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Extensión | No confiar, validar MIME real | 🔴 |
| MIME | Verificar con `finfo_file()` | 🔴 |
| Imágenes | Validar con `getimagesize()` | 🔴 |
| Nombre | No usar nombre original directamente | 🔴 |
| Ubicación | Fuera de webroot o sin ejecución | 🔴 |

---

### 7. Logging & Error Handling

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Datos sensibles | Nunca log de passwords, tokens, tarjetas | 🔴 |
| Errores usuario | Mensaje genérico, sin detalles técnicos | 🔴 |
| Errores técnicos | Solo en logs internos | 🟡 |
| Stack traces | Nunca exponer al usuario | 🔴 |

```php
// ❌ CRÍTICO
catch (Exception $e) {
    die($e->getMessage()); // Expone información
}
PrestaShopLogger::addLog('Login failed: ' . $password); // Log sensible

// ✅ CORRECTO
catch (Exception $e) {
    PrestaShopLogger::addLog('Error: ' . $e->getMessage(), 3);
    $this->errors[] = $this->l('An error occurred');
}
```

---

### 8. APIs Externas

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Timeout | Configurado explícitamente | 🔴 |
| SSL | Verificar certificados | 🔴 |
| Respuestas | No confiar, validar estructura | 🔴 |
| Credenciales | No hardcodear, usar Configuration | 🔴 |

---

### 9. Permisos y Contexto

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Shop access | `hasAuthOnShop()` cuando aplique | 🔴 |
| Employee perms | Verificar permisos de empleado | 🟡 |
| Customer context | Verificar ownership de recursos | 🔴 |

---

### 10. Rate-Limited Logging (si hay llamadas a APIs externas)

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Errores de API | Usar `IagtRateLimitedLogger`, no `PrestaShopLogger` directo | 🔴 |
| Datos sensibles | Nunca loguear tokens, passwords, datos de tarjeta | 🔴 |

---

### 11. Distributed Locking (si hay stock, checkout o sincronización SAP)

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Operaciones críticas | `IagtLockService::withLock($key, fn, $ttl)` obligatorio | 🔴 |
| Resultado null | Lanzar excepción — nunca proceder sin lock | 🔴 |
| Lock key | Formato `operation:entity_type:entity_id` | 🟡 |

---

## FORMATO DE RESPUESTA

🔴 Bloqueantes · 🟡 Riesgos · 🟢 Correcto · 💡 Recomendaciones

---

## RESTRICCIONES

- NO escribir código salvo solicitud explícita
- NO suavizar problemas 🔴 — si los hay, indicar que NO puede ir a producción
- Referenciar siempre la regla o documento aplicable
- Para ejemplos de código completos: `security/prestashop-security-reference.md`
- Actuar en español


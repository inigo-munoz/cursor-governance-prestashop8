# PrestaShop 8 — Project Context

Restricciones y convenciones específicas del entorno 
Para arquitectura completa: `architecture/prestashop-legacy-architecture.md`
Para naming detallado: `conventions/coding-conventions.md`
Para seguridad: `security/prestashop-security.md`

---

## Project Information

| Setting | Value |
|---------|-------|
| PrestaShop Version | 8.x |
| PHP Version | 8.1+ |
| Company Prefix | `vendor_` |
| Code Style | PSR-12 + PrestaShop specifics |
| Architecture | Legacy (no namespaces, no PSR-4, no Composer autoload) |
| Multishop | Obligatorio — siempre manejar `id_shop` |

---

## Module Structure

```
modules/vendor_modulename/
├── vendor_modulename.php
├── index.php                        # Obligatorio en CADA directorio
├── classes/
│   ├── index.php
│   └── IagtEntityName.php
├── controllers/
│   ├── index.php
│   ├── admin/
│   │   ├── index.php
│   │   └── AdminIagtEntityController.php
│   └── front/
│       ├── index.php
│       └── action.php
├── sql/
│   ├── index.php
│   ├── install.sql
│   └── uninstall.sql
├── views/
│   ├── index.php
│   ├── css/
│   ├── js/
│   └── templates/
│       ├── admin/
│       └── front/
└── translations/
```

Contenido mínimo de cada `index.php`:
```php
<?php
// Silence is golden.
```

---

## Code Loading

No hay autoload. Carga manual obligatoria:

```php
require_once _PS_MODULE_DIR_ . 'vendor_modulename/classes/IagtEntity.php';
```

Cargar en la parte superior del archivo, después del check `_PS_VERSION_`.

---

## Database Tables

Todas las tablas de datos de tienda deben incluir `id_shop`:

```sql
CREATE TABLE `PREFIX_vendor_entity` (
    `id_entity` INT UNSIGNED AUTO_INCREMENT,
    `id_shop`   INT UNSIGNED NOT NULL,
    ...
    PRIMARY KEY (`id_entity`),
    KEY `idx_shop` (`id_shop`)
);
```

Tablas globales (sin `id_shop`) deben documentarse explícitamente:

```sql
-- GLOBAL: Compartida entre todas las tiendas. Motivo: [razón]
CREATE TABLE `PREFIX_vendor_global_config` (...);
```

SQL files: solo CREATE/DROP simples. Sin stored procedures ni triggers.
Usar `PREFIX_` y `ENGINE_TYPE` como placeholders.

---

## Hooks Reference

### Frontend

| Hook | Propósito |
|------|-----------|
| `displayHeader` | CSS/JS en `<head>` |
| `displayFooter` | Contenido antes de `</body>` |
| `displayHome` | Contenido en homepage |
| `displayTop` | Área de cabecera |
| `displayNav` | Navegación |

### Backend

| Hook | Propósito |
|------|-----------|
| `displayBackOfficeHeader` | CSS/JS en admin |
| `displayAdminCustomers` | Página de clientes admin |
| `actionValidateOrder` | Tras validación de pedido |

### Buenas prácticas en hooks

```php
// 1. Verificar estado del módulo
if (!Module::isEnabled($this->name)) { return ''; }

// 2. Verificar contexto del controller
if (!($this->context->controller instanceof ProductController)) { return ''; }

// 3. Delegar inmediatamente en Service — no poner lógica en el hook
IagtService::processEvent($params);
```

- Evitar queries pesadas — cachear o lazy load
- Nunca lanzar excepciones desde hooks

---

## Email Sending

Preferir `vendor_mails` si está disponible:

```php
if (Module::isInstalled('vendor_mails') && class_exists('IagtMails')) {
    require_once _PS_MODULE_DIR_ . 'vendor_mails/classes/IagtMails.php';
    IagtMails::send(...);
} else {
    Mail::send(...);
}
```

---

## Configuration Values

Especificar contexto de tienda siempre de forma explícita:

```php
// Leer
$value = Configuration::get('VENDOR_KEY', null, null, $idShop);

// Escribir
Configuration::updateValue('VENDOR_KEY', $value, false, null, $idShop);
```

---

## Version

Context v1.2
Última revisión: 2026-03-20

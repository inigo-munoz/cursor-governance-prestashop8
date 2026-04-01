# Coding Conventions

> **Módulo:** PrestaShop 8 Technical Handbook v3.0  
> **Última actualización:** 13 de febrero de 2026

---

## 1. Nomenclatura de Módulos

Todos los módulos propios usan el prefijo `vendor_` seguido del nombre descriptivo en minúsculas.

| Formato | Ejemplo | Descripción |
|---------|---------|-------------|
| `vendor_nombremodulo` | `vendor_counteroffer` | Módulo de contraofertas |
| `vendor_nombremodulo` | `vendor_mails` | Sistema de emails |
| `vendor_nombremodulo` | `vendor_sapstock` | Integración SAP stock |

**Ventaja:** El prefijo identifica código propio y permite configurar SonarQube con un único patrón.

---

## 2. Estructura de Código Propio

Solo se analiza y mantiene código en estos directorios:

| Directorio | Contenido |
|------------|-----------|
| `modules/vendor_*` | Módulos propios de |
| `themes/vendor_[proyecto]` | Tema personalizado |
| `override/` | Overrides (solo con excepción documentada en `docs/overrides/`) |

---

## 3. Nomenclatura de Clases

> 🔴 **CRÍTICO:** TODAS las clases custom deben usar prefijo `Iagt` para evitar colisiones.

### Regla de naming

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| **Clase principal módulo** | `Iagt_nombremodulo` (snake_case) | `Iagt_counteroffer` |
| **Clases auxiliares** | `IagtNombreClase` (CamelCase) | `IagtCounterofferLogger` |
| **Clases helper** | `IagtNombreHelper` | `IagtMails`, `IagtValidator` |
| **ObjectModel** | `IagtNombreEntidad` | `IagtCustomerNote` |
| **Service Layer** | `IagtNombreService` | `IagtSapStockService` |
| **Controllers Admin** | `AdminIagtNombreController` | `AdminIagtLandingsController` |
| **Controllers Front** | `IagtNombreModuleFrontController` | `IagtCounterofferApiModuleFrontController` |

### ¿Por qué snake_case en la clase principal?

PrestaShop requiere que el nombre de la clase principal del módulo coincida exactamente con el nombre del directorio. Como los directorios usan `vendor_nombremodulo`, la clase debe ser `Iagt_nombremodulo`.

**Todas las demás clases** usan CamelCase sin underscore: `IagtNombreClase`.

```php
// Clase principal del módulo (snake_case obligatorio por PS)
class Iagt_counteroffer extends Module { }

// Todas las demás clases (CamelCase)
class IagtCounterofferLogger { }
class IagtCounterofferService { }
class IagtCustomerNote extends ObjectModel { }
```

---

## 4. Nomenclatura de Variables

Formato: `camelCase` siempre. Nombres descriptivos en inglés.

```php
// ✅ Correcto
$customerId = (int)Tools::getValue('id_customer');
$orderTotal = $cart->getOrderTotal();
$isValidCoupon = $this->validateCoupon($code);

// ❌ Evitar
$c = Tools::getValue('id_customer');
$x = $cart->getOrderTotal();
$temp = $this->validateCoupon($code);
```

### Convenciones específicas

| Tipo | Prefijo/Formato | Ejemplo |
|------|-----------------|---------|
| Booleanos | `is`, `has`, `can` | `$isActive`, `$hasDiscount` |
| Arrays | Plural | `$productIds`, `$orderItems` |
| Contadores | `count`, `total` | `$countProducts`, `$totalAmount` |

---

## 5. Nomenclatura de Métodos

Formato: `camelCase` comenzando con verbo.

| Acción | Prefijo | Ejemplo |
|--------|---------|---------|
| Obtener dato | `get` | `getCustomerById()` |
| Establecer dato | `set` | `setDiscountAmount()` |
| Verificar condición | `is`, `has`, `can` | `isValidCoupon()` |
| Procesar/Ejecutar | `process`, `handle` | `processOrder()` |
| Crear entidad | `create` | `createCoupon()` |
| Eliminar | `delete`, `remove` | `deleteExpiredOffers()` |
| Validar | `validate`, `check` | `validateCartRules()` |

### Longitud de métodos

> **Target recomendado:** 30-50 líneas.  
> **Excepciones justificadas:** Permitidas para métodos complejos como `getList()`, `postProcess()`, controllers con filtros.

No fragmentar artificialmente solo para cumplir un límite. La legibilidad y cohesión son más importantes.

---

## 6. Nomenclatura de Constantes

Formato: `UPPER_SNAKE_CASE` con prefijo del módulo.

```php
// Constantes de estado
const IAGT_MODULO_STATUS_PENDING = 1;
const IAGT_MODULO_STATUS_ACCEPTED = 2;
const IAGT_MODULO_STATUS_REJECTED = 3;

// Constantes de configuración
const IAGT_MODULO_CONFIG_KEY = 'IAGT_MOD_CONFIG';
const IAGT_MODULO_EMAIL_ENABLED = 'IAGT_MOD_EMAIL';
```

---

## 7. Nomenclatura de Tablas

Prefijo: `ps_vendor_` seguido del módulo y entidad.

| Formato | Ejemplo |
|---------|---------|
| `ps_vendor_modulo_entidad` | `ps_vendor_counteroffer` |
| `ps_vendor_modulo_entidad_lang` | `ps_vendor_counteroffer_lang` |
| `ps_vendor_modulo_entidad_shop` | `ps_vendor_counteroffer_shop` |

> 🔴 **OBLIGATORIO:** Todas las tablas shop-specific DEBEN incluir `id_shop` con índice.

```sql
CREATE TABLE IF NOT EXISTS `_DB_PREFIX_vendor_counteroffer` (
    `id_counteroffer` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `id_customer` INT UNSIGNED NOT NULL,
    `id_shop` INT UNSIGNED NOT NULL,  -- OBLIGATORIO
    `date_add` DATETIME NOT NULL,
    PRIMARY KEY (`id_counteroffer`),
    KEY `idx_shop` (`id_shop`)  -- ÍNDICE OBLIGATORIO
) ENGINE=ENGINE_TYPE DEFAULT CHARSET=utf8mb4;
```

Si la tabla es intencionalmente global (sin `id_shop`), documentar con comentario SQL:

```sql
-- GLOBAL: Configuración compartida entre todas las tiendas
CREATE TABLE IF NOT EXISTS `_DB_PREFIX_vendor_global_config` (
    ...
);
```

---

## 8. Arquitectura de Código

### 8.1 Legacy-Only Architecture

Ver definición completa en `architecture/prestashop-legacy-architecture.md`.
Resumen: sin namespaces, sin Composer autoload, sin Symfony services.
Service Layer obligatorio — lógica de negocio en Services, NO en controllers.

### 8.2 Controllers

```php
// BackOffice - extends ModuleAdminController
class AdminIagtLandingsController extends ModuleAdminController
{
    public function __construct()
    {
        $this->bootstrap = true;
        $this->table = 'vendor_landing';
        $this->className = 'IagtLanding';
        $this->identifier = 'id_landing';
        parent::__construct();
    }
}

// Frontend - extends ModuleFrontController
class Iagt_CounterofferApiModuleFrontController extends ModuleFrontController
{
    public function initContent()
    {
        parent::initContent();
        // Delegar en Service
    }
}
```

### 8.3 Service Layer Pattern

> 📘 La lógica de negocio va en clases Service, NO en controllers ni hooks.

```php
// classes/IagtCounterofferService.php
class IagtCounterofferService
{
    public static function create($idCustomer, $idProduct, $amount, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Shop::getContextShopID(true);
        }
        
        // Validaciones
        if ($amount <= 0) {
            return ['success' => false, 'error' => 'Invalid amount'];
        }
        
        // Lógica de negocio
        $offer = new IagtCounteroffer();
        $offer->id_customer = (int)$idCustomer;
        $offer->id_product = (int)$idProduct;
        $offer->amount = (float)$amount;
        $offer->id_shop = (int)$idShop;
        
        if (!$offer->add()) {
            return ['success' => false, 'error' => 'Could not save'];
        }
        
        return ['success' => true, 'id' => $offer->id];
    }
}
```

### 8.4 Hooks

> ❌ **Prohibido:** Lógica compleja en hooks.  
> ✅ **Correcto:** El hook debe delegar inmediatamente en un Service.

```php
// ❌ INCORRECTO - Lógica compleja en hook
public function hookActionValidateOrder($params)
{
    $order = $params['order'];
    $customer = new Customer($order->id_customer);
    
    // 50 líneas de lógica de negocio aquí...
    // Cálculos, validaciones, llamadas a API...
}

// ✅ CORRECTO - Hook delega en Service
public function hookActionValidateOrder($params)
{
    IagtOrderService::processNewOrder($params['order']);
}
```

---

## 9. Estilo de Código (PSR-12)

### Reglas básicas

- **Indentación:** 4 espacios (no tabs)
- **Longitud de línea:** Máximo 120 caracteres
- **Visibilidad:** Siempre explícita (`public`, `private`, `protected`)
- **Llaves:** En línea separada para clases y métodos

```php
// ✅ Correcto
class IagtCounterofferService
{
    private $logger;
    
    public function __construct()
    {
        $this->logger = new IagtLogger();
    }
    
    public function process($data)
    {
        if (empty($data)) {
            return false;
        }
        
        // Lógica
        return true;
    }
}
```

### Arrays

```php
// ✅ Correcto - Array corto en una línea
$ids = [1, 2, 3];

// ✅ Correcto - Array largo multilínea
$config = [
    'key1' => 'value1',
    'key2' => 'value2',
    'key3' => 'value3',
];
```

---

## 10. Traducciones (XLIFF)

PrestaShop 8 usa archivos XLIFF 1.2 (`.xlf`) — NO usar sistema legacy de archivos `.php`.

### Ubicación de archivos

```
# Tema
translations/es-ES/ShopThemeIagtHome.es-ES.xlf
translations/en-US/ShopThemeIagtHome.en-US.xlf

# Módulo
modules/vendor_modulename/translations/es-ES/ModulesIagtModulenameShop.es-ES.xlf
```

### Sintaxis en Smarty

```smarty
{l s='Texto original' d='ShopThemeIagtHome'}
{l s='Otro texto' d='Modules.IagtModulename.Shop'}
```

### Limpieza de caché (OBLIGATORIO)

```bash
# Docker (adaptar nombre del contenedor)
docker exec [CONTAINER_NAME] rm -rf var/cache/prod/translations
docker exec [CONTAINER_NAME] rm -rf var/cache/dev/translations

# Local
rm -rf var/cache/prod/translations
rm -rf var/cache/dev/translations
```

> ⚠️ Sin limpiar la caché, los cambios en traducciones NO se reflejarán.

---

## 11. Anti-Patterns de Código

| ❌ Prohibido | ✅ Correcto |
|-------------|-------------|
| Clases sin prefijo `Iagt` | `IagtNombreClase` |
| Lógica compleja en hooks | Hook delega en Service |
| Lógica en Smarty | Preparar datos en controller |
| `die()` en producción | `Tools::redirect()` o response JSON |
| Raw `$_POST` / `$_GET` | `Tools::getValue()` con validación |
| Métodos de 200+ líneas sin justificación | Extraer a métodos privados o Service |

---

## Referencias

- [prestashop-security.md](../security/prestashop-security.md) — Validación de inputs, SQL, CSRF
- [governance-workflow.md](./governance-workflow.md) — Git, PRs, SonarQube
- [multishop-data-model.md](./multishop-data-model.md) — Contextos, tablas

---

*Parte del PrestaShop 8 Technical Handbook v3.0*

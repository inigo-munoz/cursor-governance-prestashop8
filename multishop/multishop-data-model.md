# Multishop & Data Model

> **Módulo:** PrestaShop 8 Technical Handbook v3.0  
> **Última actualización:** 13 de febrero de 2026

---

## 1. Contextos de Tienda

### 1.1 Los tres contextos

| Contexto | Constante | Significado |
|----------|-----------|-------------|
| **Shop** | `Shop::CONTEXT_SHOP` | Una tienda específica seleccionada |
| **Group** | `Shop::CONTEXT_GROUP` | Un grupo de tiendas seleccionado |
| **All** | `Shop::CONTEXT_ALL` | Todas las tiendas (vista global) |

### 1.2 Cómo detectar el contexto

```php
// Obtener contexto actual
$context = Shop::getContext();

switch ($context) {
    case Shop::CONTEXT_SHOP:
        // Una tienda específica
        $idShop = (int)Shop::getContextShopID(true);
        break;
        
    case Shop::CONTEXT_GROUP:
        // Grupo de tiendas
        $idShopGroup = (int)Shop::getContextShopGroupID();
        $shopIds = Shop::getContextListShopID(); // ← Usar esto
        break;
        
    case Shop::CONTEXT_ALL:
        // Todas las tiendas
        // Decisión explícita requerida
        break;
}
```

---

## 2. Manejo de Cada Contexto

### 2.1 CONTEXT_SHOP — Una tienda

```php
if (Shop::getContext() === Shop::CONTEXT_SHOP) {
    $idShop = (int)Shop::getContextShopID(true);
    
    $sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'vendor_table
            WHERE id_shop = ' . $idShop;
}
```

### 2.2 CONTEXT_GROUP — Grupo de tiendas

> ⚠️ **Importante:** Usar `Shop::getContextListShopID()` para obtener las tiendas del grupo.

```php
if (Shop::getContext() === Shop::CONTEXT_GROUP) {
    // ✅ CORRECTO - Usar helper de PrestaShop
    $shopIds = Shop::getContextListShopID();
    
    if (!empty($shopIds)) {
        $shopIdsString = implode(',', array_map('intval', $shopIds));
        
        $sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'vendor_table
                WHERE id_shop IN (' . $shopIdsString . ')';
    }
}

// ❌ INCORRECTO - Subquery menos eficiente
$sql = 'WHERE id_shop IN (
    SELECT id_shop FROM ' . _DB_PREFIX_ . 'shop 
    WHERE id_shop_group = ' . (int)$idGroup . '
)';
```

### 2.3 CONTEXT_ALL — Todas las tiendas

> 🔴 **CRÍTICO:** CONTEXT_ALL requiere decisión explícita. Nunca ignorar.

```php
if (Shop::getContext() === Shop::CONTEXT_ALL) {
    // OPCIÓN A: Vista global (sin filtro de tienda)
    // Solo si el usuario tiene permisos globales
    $sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'vendor_table';
    
    // OPCIÓN B: Iterar por tiendas
    $shops = Shop::getShops();
    foreach ($shops as $shop) {
        $idShop = (int)$shop['id_shop'];
        // Procesar cada tienda...
    }
    
    // OPCIÓN C: Bloquear operación
    // Si la operación no tiene sentido en contexto global
    throw new PrestaShopException('Please select a specific shop');
}
```

### 2.4 Patrón completo recomendado

```php
/**
 * Obtiene datos respetando el contexto de tienda actual
 */
public static function getData()
{
    $context = Shop::getContext();
    
    $query = new DbQuery();
    $query->select('*')
          ->from('vendor_table');
    
    switch ($context) {
        case Shop::CONTEXT_SHOP:
            $query->where('id_shop = ' . (int)Shop::getContextShopID(true));
            break;
            
        case Shop::CONTEXT_GROUP:
            $shopIds = Shop::getContextListShopID();
            if (!empty($shopIds)) {
                $query->where('id_shop IN (' . implode(',', array_map('intval', $shopIds)) . ')');
            }
            break;
            
        case Shop::CONTEXT_ALL:
            // Sin filtro = todas las tiendas
            // O lanzar excepción si no aplica
            break;
    }
    
    return Db::getInstance()->executeS($query);
}
```

---

## 3. Errores Comunes

### 3.1 Asumir que getContextShopID() siempre devuelve la tienda correcta

```php
// ❌ PELIGROSO
$idShop = Shop::getContextShopID(true);
// En CONTEXT_ALL esto devuelve la tienda por defecto, NO todas

// ✅ CORRECTO - Verificar contexto primero
if (Shop::getContext() !== Shop::CONTEXT_SHOP) {
    // Manejar caso especial
}
$idShop = Shop::getContextShopID(true);
```

### 3.2 Ignorar CONTEXT_ALL

```php
// ❌ PELIGROSO - Ignora contexto
$idShop = Shop::getContextShopID();
$sql = 'WHERE id_shop = ' . $idShop; // ¡Puede ser incorrecto!

// ✅ CORRECTO - Decisión explícita
if (Shop::getContext() === Shop::CONTEXT_ALL) {
    // Decidir qué hacer
}
```

### 3.3 Queries sin filtro de tienda

```php
// ❌ INCORRECTO - Sin filtro de tienda
$sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'vendor_offers 
        WHERE id_customer = ' . (int)$idCustomer;

// ✅ CORRECTO - Con filtro de tienda
$sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'vendor_offers 
        WHERE id_customer = ' . (int)$idCustomer . '
        AND id_shop = ' . (int)Shop::getContextShopID(true);
```

---

## 4. Modelo de Datos

### 4.1 Tablas con id_shop (shop-specific)

Toda tabla que contenga datos específicos de tienda DEBE incluir:

```sql
CREATE TABLE `ps_vendor_example` (
    `id_example` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `id_customer` INT UNSIGNED NOT NULL,
    `id_shop` INT UNSIGNED NOT NULL,  -- OBLIGATORIO
    `data` TEXT,
    `date_add` DATETIME NOT NULL,
    PRIMARY KEY (`id_example`),
    KEY `idx_shop` (`id_shop`),        -- ÍNDICE OBLIGATORIO
    KEY `idx_customer_shop` (`id_customer`, `id_shop`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 4.2 Tablas globales (sin id_shop)

Si una tabla es intencionalmente global, documentar:

```sql
-- GLOBAL: Configuración compartida entre todas las tiendas
-- Motivo: Los valores son idénticos para todo el sistema
CREATE TABLE `ps_vendor_global_config` (
    `id_config` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `value` TEXT,
    PRIMARY KEY (`id_config`),
    UNIQUE KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 4.3 Patrón _shop (como PrestaShop core)

Para datos que varían por tienda con una base común:

```sql
-- Tabla base
CREATE TABLE `ps_vendor_landing` (
    `id_landing` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `date_add` DATETIME NOT NULL,
    PRIMARY KEY (`id_landing`)
);

-- Tabla por tienda
CREATE TABLE `ps_vendor_landing_shop` (
    `id_landing` INT UNSIGNED NOT NULL,
    `id_shop` INT UNSIGNED NOT NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id_landing`, `id_shop`)
);

-- Tabla de idiomas
CREATE TABLE `ps_vendor_landing_lang` (
    `id_landing` INT UNSIGNED NOT NULL,
    `id_lang` INT UNSIGNED NOT NULL,
    `id_shop` INT UNSIGNED NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT,
    PRIMARY KEY (`id_landing`, `id_lang`, `id_shop`)
);
```

---

## 5. Tablas Prohibidas

### 5.1 NUNCA hacer ALTER/DROP

> 🚨 **CRÍTICO:** No modificar estructura de estas tablas.

| Tabla | Motivo |
|-------|--------|
| `ps_configuration` | Configuración global. Solo `Configuration::updateValue()` |
| `ps_shop` | Definición de tiendas |
| `ps_shop_group` | Grupos de tiendas |
| `ps_shop_url` | URLs de tiendas |
| `ps_employee` | Usuarios de BO |
| `ps_access` | Permisos |
| `ps_authorization_role` | Roles |
| `ps_module` | Registro de módulos |
| `ps_module_shop` | Módulos por tienda |
| `ps_hook` | Sistema de hooks |
| `ps_hook_module` | Hooks por módulo |
| `ps_tab` | Menú del BO |

### 5.2 Tablas críticas de negocio

> ⚠️ **PRECAUCIÓN:** Solo lectura o modificación muy controlada.

| Tabla | Regla |
|-------|-------|
| `ps_orders` | Solo lectura excepto procesos de negocio documentados |
| `ps_order_detail` | Solo lectura |
| `ps_cart` | Solo lectura excepto módulos de checkout |
| `ps_customer` | Solo campos específicos, nunca password |
| `ps_product` | Solo via ObjectModel, nunca SQL directo |
| `ps_product_lang` | Solo via ObjectModel |
| `ps_cart_rule` | Solo cupones con prefijo propio (ej: `ACME-*`) |

---

## 6. ObjectModel y Multishop

### 6.1 Definición correcta

```php
class AcmeOffer extends ObjectModel
{
    public $id_offer;
    public $id_customer;
    public $id_product;
    public $amount;
    public $id_shop;
    public $date_add;
    
    public static $definition = [
        'table' => 'vendor_offer',
        'primary' => 'id_offer',
        'multilang' => false,
        'multishop' => true,  // ← Importante para multishop
        'fields' => [
            'id_customer' => ['type' => self::TYPE_INT, 'validate' => 'isUnsignedId', 'required' => true],
            'id_product' => ['type' => self::TYPE_INT, 'validate' => 'isUnsignedId', 'required' => true],
            'amount' => ['type' => self::TYPE_FLOAT, 'validate' => 'isPrice', 'required' => true],
            'id_shop' => ['type' => self::TYPE_INT, 'validate' => 'isUnsignedId'],
            'date_add' => ['type' => self::TYPE_DATE, 'validate' => 'isDate'],
        ],
    ];
    
    public function add($auto_date = true, $null_values = false)
    {
        // Asegurar id_shop si no está definido
        if (empty($this->id_shop)) {
            $this->id_shop = (int)Shop::getContextShopID(true);
        }
        
        return parent::add($auto_date, $null_values);
    }
}
```

### 6.2 Queries con ObjectModel

```php
// ✅ CORRECTO - Filtrar por tienda
$offers = AcmeOffer::getByCustomer($idCustomer, $idShop);

// Implementación
public static function getByCustomer($idCustomer, $idShop = null)
{
    if ($idShop === null) {
        $idShop = (int)Shop::getContextShopID(true);
    }
    
    $query = new DbQuery();
    $query->select('*')
          ->from('vendor_offer')
          ->where('id_customer = ' . (int)$idCustomer)
          ->where('id_shop = ' . (int)$idShop);
    
    return Db::getInstance()->executeS($query);
}
```

---

## 7. Frontend y Multishop

### 7.1 En Controllers Front

```php
class AcmeModuleDisplayModuleFrontController extends ModuleFrontController
{
    public function initContent()
    {
        parent::initContent();
        
        // En frontend, siempre hay una tienda específica
        $idShop = (int)$this->context->shop->id;
        
        // Usar en queries
        $data = AcmeService::getData($idShop);
        
        $this->context->smarty->assign([
            'data' => $data,
        ]);
    }
}
```

### 7.2 En Hooks

```php
public function hookDisplayHeader($params)
{
    // El contexto de tienda ya está establecido
    $idShop = (int)$this->context->shop->id;
    
    // Delegar en Service con id_shop
    $config = AcmeConfigService::getForShop($idShop);
    
    // ...
}
```

---

## 8. Admin y Multishop

### 8.1 En ModuleAdminController

```php
class AdminAcmeOffersController extends ModuleAdminController
{
    public function __construct()
    {
        $this->bootstrap = true;
        $this->table = 'vendor_offer';
        $this->className = 'AcmeOffer';
        $this->identifier = 'id_offer';
        
        // Filtrar automáticamente por tienda según contexto
        $this->_defaultOrderBy = 'date_add';
        $this->_defaultOrderWay = 'DESC';
        
        parent::__construct();
        
        // Añadir filtro de tienda al WHERE
        $this->_where = $this->getShopWhere();
    }
    
    protected function getShopWhere()
    {
        $context = Shop::getContext();
        
        switch ($context) {
            case Shop::CONTEXT_SHOP:
                return ' AND a.id_shop = ' . (int)Shop::getContextShopID(true);
                
            case Shop::CONTEXT_GROUP:
                $shopIds = Shop::getContextListShopID();
                if (!empty($shopIds)) {
                    return ' AND a.id_shop IN (' . implode(',', array_map('intval', $shopIds)) . ')';
                }
                return '';
                
            case Shop::CONTEXT_ALL:
            default:
                return ''; // Sin filtro = todas las tiendas
        }
    }
}
```

### 8.2 Verificar permisos de tienda

```php
// Verificar que el empleado tiene acceso a la tienda
$idShop = (int)Tools::getValue('id_shop');

if (!$this->context->employee->hasAuthOnShop($idShop)) {
    Tools::redirectAdmin($this->context->link->getAdminLink('AdminDashboard'));
}
```

---

## 9. Checklist Multishop

Ver checklist completo en `commands/multishop-check.md` — incluye todos los criterios con severidad.

---

## 10. Anti-Patterns Multishop

| ❌ Prohibido | ✅ Correcto |
|-------------|-------------|
| Queries sin `id_shop` | Filtrar siempre por tienda |
| Tablas sin `id_shop` + índice | Incluir ambos |
| `getContextShopID()` sin verificar contexto | Verificar contexto primero |
| Ignorar CONTEXT_ALL | Decisión explícita |
| Subquery para CONTEXT_GROUP | `getContextListShopID()` |
| Asumir siempre una tienda | Manejar los 3 contextos |

---

## Referencias

- [coding-conventions.md](./coding-conventions.md) — Naming de tablas
- [prestashop-security.md](../security/prestashop-security.md) — SQL injection prevention
- [governance-workflow.md](./governance-workflow.md) — Proceso de review

---

*Parte del PrestaShop 8 Technical Handbook v3.0*

# /multishop-check

Verificación de contexto multishop para código PrestaShop 8.x 

Evalúa que el código maneje correctamente los tres contextos de tienda y no asuma single-shop.

---

## 📌 CUÁNDO EJECUTAR

- Código con queries SELECT/UPDATE/DELETE/INSERT sobre datos de negocio
- Nuevas tablas o modificaciones de modelo de datos
- Controllers de admin que muestran listados
- Cualquier código que use `Shop::getContextShopID()`

---

## 🔍 CONTEXTOS DE TIENDA

| Contexto | Constante | Significado |
|----------|-----------|-------------|
| Shop | `Shop::CONTEXT_SHOP` | Una tienda específica |
| Group | `Shop::CONTEXT_GROUP` | Grupo de tiendas |
| All | `Shop::CONTEXT_ALL` | Todas las tiendas |

---

## 🔍 CHECKLIST OBLIGATORIO

### 1. Queries con Filtro de Tienda

| Check | Criterio | Severidad |
|-------|----------|-----------|
| SELECT | Filtrar `id_shop` en datos de tienda | 🔴 |
| UPDATE | Filtrar `id_shop` para no afectar otras tiendas | 🔴 |
| DELETE | Filtrar `id_shop` obligatorio | 🔴 |
| INSERT | Incluir `id_shop` en el registro | 🔴 |

```php
// ❌ CRÍTICO - Afecta todas las tiendas
$sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'vendor_offers 
        WHERE id_customer = ' . (int)$idCustomer;

// ✅ CORRECTO
$sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'vendor_offers 
        WHERE id_customer = ' . (int)$idCustomer . '
        AND id_shop = ' . (int)Shop::getContextShopID(true);
```

---

### 2. Verificación de Contexto

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Antes de getContextShopID | Verificar contexto actual | 🔴 |
| CONTEXT_ALL | Decisión explícita obligatoria | 🔴 |
| CONTEXT_GROUP | Usar `getContextListShopID()` | 🟡 |

```php
// ❌ PELIGROSO - No verifica contexto
$idShop = Shop::getContextShopID(true);
// En CONTEXT_ALL devuelve tienda por defecto, NO todas

// ✅ CORRECTO
$context = Shop::getContext();

switch ($context) {
    case Shop::CONTEXT_SHOP:
        $idShop = (int)Shop::getContextShopID(true);
        $where = 'id_shop = ' . $idShop;
        break;
        
    case Shop::CONTEXT_GROUP:
        $shopIds = Shop::getContextListShopID();
        $where = 'id_shop IN (' . implode(',', array_map('intval', $shopIds)) . ')';
        break;
        
    case Shop::CONTEXT_ALL:
        // Decisión explícita: ¿mostrar todo o bloquear?
        $where = '1'; // O lanzar excepción si no aplica
        break;
}
```

---

### 3. Tablas y Modelo de Datos

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Columna id_shop | Presente en tablas de datos de tienda | 🔴 |
| Índice id_shop | Creado para optimizar queries | 🟡 |
| ObjectModel | `'multishop' => true` en definition | 🟡 |
| Tablas _shop | Patrón correcto si aplica | 🟡 |

```sql
-- ❌ INCORRECTO - Sin id_shop
CREATE TABLE ps_vendor_offers (
    id_offer INT PRIMARY KEY,
    id_customer INT,
    amount DECIMAL(10,2)
);

-- ✅ CORRECTO
CREATE TABLE ps_vendor_offers (
    id_offer INT PRIMARY KEY,
    id_customer INT,
    id_shop INT NOT NULL,
    amount DECIMAL(10,2),
    KEY idx_shop (id_shop)
);
```

---

### 4. Frontend

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Context shop | Usar `$this->context->shop->id` | 🟡 |
| Queries | Filtrar por tienda actual | 🔴 |

```php
// ✅ En controllers front
$idShop = (int)$this->context->shop->id;
$data = IagtService::getByShop($idShop);
```

---

### 5. Admin / BackOffice

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Permisos | Verificar `hasAuthOnShop()` | 🔴 |
| Listados | Filtrar según contexto seleccionado | 🟡 |
| Formularios | Guardar con id_shop correcto | 🔴 |

```php
// ✅ Verificar permisos
$idShop = (int)Tools::getValue('id_shop');
if (!$this->context->employee->hasAuthOnShop($idShop)) {
    Tools::redirectAdmin($this->context->link->getAdminLink('AdminDashboard'));
}
```

---

### 6. ObjectModel

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Definition | `'multishop' => true` | 🟡 |
| add() | Asignar id_shop si no viene | 🔴 |
| Queries estáticas | Filtrar por tienda | 🔴 |

```php
// ✅ ObjectModel correcto
class IagtOffer extends ObjectModel
{
    public static $definition = [
        'table' => 'vendor_offer',
        'primary' => 'id_offer',
        'multishop' => true,
        'fields' => [
            'id_shop' => ['type' => self::TYPE_INT],
            // ...
        ],
    ];
    
    public function add($auto_date = true, $null_values = false)
    {
        if (empty($this->id_shop)) {
            $this->id_shop = (int)Shop::getContextShopID(true);
        }
        return parent::add($auto_date, $null_values);
    }
}
```

---

### 7. Tablas Globales (Excepción)

Si una tabla es intencionalmente global:

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Documentación | Comentario SQL explicando por qué | 🟡 |
| Justificación | Motivo técnico válido | 🟡 |

```sql
-- GLOBAL: Configuración compartida entre todas las tiendas
-- Motivo: Valores idénticos para todo el sistema
CREATE TABLE ps_vendor_global_config (...);
```

---

## 🛑 ANTI-PATTERNS

| Anti-Pattern | Problema |
|--------------|----------|
| Query sin id_shop | Mezcla datos de tiendas |
| getContextShopID() sin verificar contexto | Comportamiento impredecible en CONTEXT_ALL |
| Asumir single-shop | Rompe en entornos multishop |
| Subquery para CONTEXT_GROUP | Ineficiente, usar getContextListShopID() |
| Tabla sin id_shop ni documentación | Ambigüedad sobre alcance |

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


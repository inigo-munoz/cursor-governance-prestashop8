---
name: multishop-audit
description: PrestaShop multishop compliance audit. Auto-invoke when editing code with Db::getInstance(), SELECT/INSERT/UPDATE queries, or any code accessing persistent data tables. Detects missing id_shop filters, incorrect shop context usage, data leakage between shops, and non-multishop-ready configurations. No modo single-shop existe en tu equipo.
---

# Multishop Audit — PrestaShop

Eres el validador de multishop  Revisas que el código respeta el modelo de aislamiento de datos entre tiendas. En no existe modo single-shop — toda query que accede a datos persistentes debe filtrar por `id_shop`.

## Cuándo actuar

Automáticamente cuando detectas:
- Queries SQL con `SELECT`, `INSERT`, `UPDATE`, `DELETE` sobre tablas de datos
- Uso de `Db::getInstance()->getRow()`, `getRows()`, `execute()`
- Acceso a `$this->context->shop->id` o `Context::getContext()->shop`
- Configuraciones de módulo (`Configuration::get/set`)
- Instalación de tablas nuevas en `install()`

## Checklist obligatorio

### 1. Filtro id_shop en queries 🔴

Toda query sobre tablas de datos persistentes debe tener `id_shop`:

```php
// ✅ Correcto
SELECT * FROM `' . _DB_PREFIX_ . 'vendor_nombre`
WHERE `id_shop` = ' . (int)$idShop . '

// ❌ Incorrecto — sin filtro de tienda
SELECT * FROM `' . _DB_PREFIX_ . 'vendor_nombre`
WHERE `id_order` = ' . (int)$idOrder
```

Excepción permitida: tablas de configuración global sin variación por tienda (documentar explícitamente).

### 2. Contexto de tienda correcto 🔴

```php
// ✅ Obtener id_shop del contexto
$idShop = (int)$this->context->shop->id;

// ❌ No asumir tienda 1
$idShop = 1;

// ❌ No usar sin cast
$idShop = $this->context->shop->id;
```

- `CONTEXT_ALL`: solo para operaciones genuinamente globales
- `CONTEXT_GROUP`: solo para operaciones de grupo de tiendas
- `CONTEXT_SHOP`: el más común — verificar que se usa correctamente

### 3. Tablas nuevas con id_shop 🔴

```sql
-- ✅ Toda tabla nueva debe tener id_shop con índice
CREATE TABLE IF NOT EXISTS `{prefix}vendor_nombre` (
  `id_vendor_nombre` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_shop` INT(10) UNSIGNED NOT NULL,  -- OBLIGATORIO
  -- ...
  KEY `id_shop` (`id_shop`)             -- OBLIGATORIO
);
```

### 4. Configuración por tienda 🟡

```php
// ✅ Configuración con id_shop
Configuration::updateValue('IAGT_CONFIG', $value, false, null, (int)$idShop);
Configuration::get('IAGT_CONFIG', null, null, (int)$idShop);

// ❌ Configuración global cuando debería ser por tienda
Configuration::updateValue('IAGT_CONFIG', $value);
```

### 5. Aislamiento en migraciones 🔴

Si hay cambios de esquema (`ALTER TABLE`, nuevas tablas en actualizaciones), verificar:
- Las nuevas columnas tienen valor por defecto válido para todos los shops
- No se pierden asociaciones `id_shop` existentes
- Los datos de migración se insertan por cada shop activo

### 6. Permisos multishop 🔴

```php
// ✅ Verificar acceso a la tienda
if (!$this->context->employee->hasAuthOnShop($idShop)) {
    throw new PrestaShopException('Access denied to shop ' . $idShop);
}
```

## Formato de salida

```
## Auditoría multishop

🔴 [Archivo:línea] — Query sin filtro id_shop
   Tabla: vendor_nombre | Corrección: añadir WHERE id_shop = (int)$idShop

🟡 [Archivo:línea] — Configuración global debería ser por tienda
   Sugerencia: usar Configuration::get con id_shop

🟢 Filtros id_shop — todas las queries correctas
```

Responde en español. Sin hallazgos = 🟢 explícito para cada área revisada.

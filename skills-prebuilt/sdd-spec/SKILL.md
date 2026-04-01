---
name: sdd-spec
description: Escribe la especificación técnica completa del cambio basándose en la propuesta aprobada. Genera spec.md con contratos, esquemas de DB y criterios de aceptación verificables. Modelo recomendado: claude-sonnet-4-6 (contratos técnicos precisos).
---

# SDD — Spec

Eres el agente de especificación. Conviertes la propuesta en una spec técnica completa y verificable.

## Recibe del orquestador

- Nombre del cambio: `{change-name}`

## Pasos

### 1. Leer artefactos previos

Leer obligatoriamente:
- `.cursor/plans/{change-name}/proposal.md`
- `.cursor/plans/skill-registry.md`

Si no existe `proposal.md`: "Ejecuta `/sdd:propose {change-name}` primero."

### 2. Expandir la propuesta en spec técnica

Para cada elemento de la propuesta, desarrollar el detalle completo.

### 3. Crear artefacto

Guardar en `.cursor/plans/{change-name}/spec.md`:

```markdown
# Spec: {change-name}
Fecha: {fecha}
Basada en: proposal.md (aprobada)

## Contratos de Service Layer

### IagtNombreService

```php
/**
 * @param int $idShop   — obligatorio, multishop
 * @param int $idLang
 * @return array|false
 */
public function getNombre(int $idShop, int $idLang): array|false

/**
 * @param array $data   — validado antes de llegar aquí
 * @param int $idShop
 * @return int|false    — id creado o false
 */
public function createNombre(array $data, int $idShop): int|false
```

## Esquema de base de datos

```sql
CREATE TABLE IF NOT EXISTS `{prefix}vendor_{nombre}` (
  `id_vendor_{nombre}` INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_shop` INT(10) UNSIGNED NOT NULL,     -- OBLIGATORIO multishop
  `id_lang` INT(10) UNSIGNED NOT NULL,
  `nombre` VARCHAR(255) NOT NULL,
  `activo` TINYINT(1) NOT NULL DEFAULT 1,
  `date_add` DATETIME NOT NULL,
  `date_upd` DATETIME NOT NULL,
  PRIMARY KEY (`id_vendor_{nombre}`),
  KEY `id_shop` (`id_shop`),
  KEY `id_lang` (`id_lang`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Endpoints AJAX (si aplica)

**POST** `/module/vendor_{nombre}/endpointajax`
- Auth: token CSRF (`{vendor_nombre}_token`)
- Input: `{ campo1: string, campo2: int }`
- Output: `{ success: bool, data?: {...}, error?: string }`
- Validación: Rule 4 (POST, token, permisos)

## Reglas de governance aplicables

- Rule 1 (Input Validation): todos los inputs con `(int)` o `pSQL()`
- Rule 2 (SQL Injection): queries con `pSQL()` y `(int)id_shop`
- Rule 9 (Permisos): `$this->access('view')` en constructor del controller
- Multishop: filtro `id_shop` en toda query que acceda a datos persistentes

## Criterios de aceptación

- [ ] CA01: {criterio concreto y verificable}
- [ ] CA02: {criterio}
- [ ] CA03: La feature funciona en contexto multishop (tienda A no ve datos de tienda B)
- [ ] CA04: Sin warnings de governance en `/review`
- [ ] CA05: `/security-check` sin hallazgos 🔴
```

### 4. Output

```
## Spec creada: .cursor/plans/{change-name}/spec.md

Contratos definidos: {N} métodos de Service Layer
Tablas: {N} tablas con id_shop
Criterios de aceptación: {N}

¿Continúo con el plan de tareas? (`/sdd:tasks {change-name}`)
```

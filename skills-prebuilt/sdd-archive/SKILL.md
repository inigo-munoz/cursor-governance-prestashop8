---
name: sdd-archive
description: Cierra un cambio verificado. Marca el plan como completado y prepara el resumen para el PR. Usar después de verify exitoso.
---

# SDD — Archive

Eres el agente de cierre. Finalizas el cambio una vez verificado.

## Recibe del orquestador

- Nombre del cambio: `{change-name}`

## Pasos

### 1. Verificar que está listo

Comprobar que existe `.cursor/plans/{change-name}/tasks.md` con todas las tareas `[x]`.
Si hay tareas `[ ]` pendientes: "Hay tareas sin completar. ¿Seguro que quieres archivar?"

### 2. Generar resumen para PR

Crear `.cursor/plans/{change-name}/pr-summary.md`:

```markdown
# PR: {change-name}
Fecha: {fecha}

## Qué hace este cambio
{resumen de proposal.md en 2-3 líneas}

## Archivos principales
- `classes/AcmeNombreService.php` ← nuevo
- `modules/vendor_nombre/vendor_nombre.php` ← modificado

## Governance
- /review: ✅ sin bloqueantes
- /security-check: ✅
- /multishop-check: ✅ (si aplica)

## Cómo probar
1. {paso concreto}
2. {paso concreto}

## Notas para el reviewer
{si hay decisiones de arquitectura no obvias}
```

### 3. Marcar como archivado

Añadir al inicio de `.cursor/plans/{change-name}/proposal.md`:
```
Estado: ARCHIVADO — {fecha}
```

### 4. Output

```
## Cambio archivado: {change-name}

**Resumen PR**: `.cursor/plans/{change-name}/pr-summary.md`

### Para crear el PR
Copia el contenido de `pr-summary.md` como descripción del PR en Bitbucket.

### Siguiente cambio
`/sdd:init` para refrescar el contexto
`/sdd:new <nombre>` para empezar otro cambio
```

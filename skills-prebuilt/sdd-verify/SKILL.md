---
name: sdd-verify
description: Valida que la implementación cumple la spec aprobada y las reglas de governance  Ejecuta los commands de revisión relevantes y reporta CRITICAL / WARNING / OK. Modelo recomendado: claude-sonnet-4-6 (verificación crítica).
---

# SDD — Verify

Eres el agente verificador. Validas que lo implementado cumple lo acordado.

## Recibe del orquestador

- Nombre del cambio: `{change-name}`

## Pasos

### 1. Cargar artefactos

Leer:
- `.cursor/plans/{change-name}/spec.md` → criterios de aceptación
- `.cursor/plans/{change-name}/tasks.md` → tareas completadas
- `.cursor/plans/{change-name}/proposal.md` → arquitectura acordada

### 2. Verificar criterios de aceptación

Para cada `CA0X` en spec.md, verificar si está cumplido:
- Revisar el código implementado
- Marcar ✅ CUMPLIDO o ❌ PENDIENTE con explicación

### 3. Ejecutar revisión de governance

Determina qué commands ejecutar basándote en lo que se implementó:

| Si se implementó... | Ejecutar |
|---------------------|---------|
| Cualquier cosa | `/review` |
| SQL, inputs de usuario, AJAX | `/security-check` |
| Queries con datos de tienda | `/multishop-check` |
| Lógica de negocio nueva | `/servicelayer-review` |

Ejecuta los commands relevantes y recopila resultados.

### 4. Verificar consistencia con propuesta

Comparar la implementación con `proposal.md`:
- ¿Los archivos creados coinciden con lo propuesto?
- ¿La arquitectura sigue el Service Layer acordado?
- ¿Sin overrides donde se acordaron hooks?

### 5. Output

```
## Verificación: {change-name}

### Criterios de aceptación
- [x] CA01: ✅ {descripción cumplida}
- [x] CA02: ✅
- [ ] CA03: ❌ {qué falta y dónde}

### Governance
/review: ✅ Sin bloqueantes / 🔴 {hallazgos}
/security-check: ✅ / 🔴 {si aplica}
/multishop-check: ✅ / 🟡 {si aplica}

### Arquitectura
✅ Service Layer respetado
✅ Sin overrides
⚠️ {desviación si la hay}

---
**Estado: LISTO PARA PR ✅** / **REQUIERE CORRECCIONES 🔴**

{Si hay correcciones: lista concreta de qué arreglar}
{Cuando esté listo: `/sdd:archive {change-name}`}
```

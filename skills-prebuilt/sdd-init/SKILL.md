---
name: sdd-init
description: Inicializa el contexto SDD-IAGT en el proyecto. Detecta el stack, construye el skill registry y prepara la estructura de planes. Usar al empezar a trabajar en un proyecto o al inicio de una sesión nueva.
---

# SDD — Init

Eres el agente de inicialización SDD para proyectos 

## Pasos

### 1. Detectar stack y contexto del proyecto

Detecta:
- Stack: PrestaShop, Node.js, u otro
- Módulos `vendor_*` presentes en `modules/`
- Services `Iagt*Service.php` existentes en `classes/`
- Versión de governance: leer `.iagt-governance.yml` si existe
- Cambios en curso: listar `.cursor/plans/*/` si existe

### 2. Verificar governance activa

Comprobar que existe `.cursor/rules/governance-stack.mdc`.
Si no existe: avisar — "ejecuta `cursor-governance apply` antes de usar SDD".

### 3. Crear estructura de planes

```
.cursor/plans/
  README.md   ← instrucciones de uso (crear si no existe)
```

### 4. Construir skill registry

Listar las skills disponibles en `.cursor/skills/`:
- Governance: ai-review, security-audit, multishop-audit, service-layer-audit
- SDD: sdd-explore, sdd-propose, sdd-spec, sdd-tasks, sdd-apply, sdd-verify

Guardar en `.cursor/plans/skill-registry.md`:

```markdown
# Skill Registry

## Governance Skills
- ai-review: revisión general antes de PR
- security-audit: SQL, inputs, uploads, APIs externas
- multishop-audit: queries con datos persistentes
- service-layer-audit: lógica de negocio

## SDD Skills
- sdd-explore: analizar codebase antes de proponer
- sdd-propose: crear propuesta de cambio
- sdd-spec: especificación técnica IAGT
- sdd-tasks: plan de tareas
- sdd-apply: implementación
- sdd-verify: verificación contra spec

## Convenciones IAGT
- Prefijo clases: Iagt
- Service Layer: classes/Iagt*Service.php
- Hooks no overrides
- Toda query filtra id_shop
```

### 5. Output

```
## SDD-IAGT Inicializado

**Proyecto**: {nombre del directorio raíz}
**Stack**: PrestaShop 8.x IAGT
**Governance**: ✅ activa / ❌ ejecuta cursor-governance apply
**Módulos IAGT**: {N} módulos (lista)
**Services existentes**: {lista o "ninguno aún"}

**Cambios en curso**: {lista de .cursor/plans/*/proposal.md o "ninguno"}

**Skill registry**: .cursor/plans/skill-registry.md

### Próximos pasos
- Explorar una idea: `/sdd:explore <tema>`
- Iniciar un cambio: `/sdd:new <nombre-del-cambio>`
```

# `checklists/`

Este directorio agrupa las **checklists de gobernanza** del stack PrestaShop.

## Propósito

- Convertir las reglas y estándares del stack en **listas de verificación deterministas**.
- Dar soporte a comandos repetibles (por ejemplo, `/review`, `/security-check`, `/multishop-check`) que puedan validar cambios de forma consistente.
- Servir como **capa operativa** entre la documentación (reglas) y la ejecución (commands, CI, IA).

## Contrato de ejecución (para IA)

Las checklists son el nivel de **validación**: convierten la gobernanza en pasos
comprobables sin duplicar reglas.

- El contrato de campos recomendado está documentado en `docs/governance-schemas.md`.
- Para compatibilidad, las checklists pueden mantener estructuras ricas (por
  ejemplo, `steps` detallados), pero deben exponer un resumen estable:
  - `purpose`
  - `references_contract`
  - `steps_contract`
  - `expected_findings`

## Contenido esperado

- Ficheros de checklist en formato estructurado (por ejemplo, YAML), uno por área o flujo, tales como:
  - `module-generation.yml` – checklist para creación de nuevos módulos.
  - `service-layer-review.yml` – checklist de revisión de Service Layer.
  - `multishop-review.yml` – checklist de cumplimiento multitienda.
  - `security-review.yml` – checklist de revisión de seguridad.
- Cada checklist debería:
  - Tener un identificador estable y un dominio (seguridad, arquitectura, multishop, etc.).
  - Referenciar los documentos canónicos relevantes (`security/`, `rules/`, `architecture/`, `standards/`, `conventions/`).
  - Marcar qué pasos son obligatorios (🔴) o recomendados (🟡), alineados con `taxonomy.md`.

## Relación con el resto del stack

- **Con `rules/`, `security/`, `architecture/`, `standards/`, `conventions/`, `patterns/`, `multishop/`**:
  - Las checklists no redefinen reglas; las **referencian** y las convierten en pasos comprobables.
- **Con `commands/`**:
  - Cada command de gobernanza debería indicar explícitamente qué checklists ejecuta (por ejemplo, `/security-check` → `security-review.yml`).
- **Con `skills/`**:
  - Las habilidades IA usan estas checklists para guiar revisiones automáticas o asistidas.
- **Con `lessons/`**:
  - Las lecciones extraídas de errores reales pueden dar lugar a nuevos pasos dentro de las checklists o a la creación de nuevas checklists.
- **Con `tests/` y `scripts/`**:
  - Los stack tests pueden verificar que las checklists se comportan como se espera y que no se rompen al evolucionar el stack.

Este directorio debe mantenerse **libre de narrativas largas**; su foco es definir artefactos ejecutables y reutilizables para validación de gobernanza.

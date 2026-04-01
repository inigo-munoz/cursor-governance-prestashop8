# `skills/`

Este directorio define las **habilidades de gobernanza** que pueden usar agentes de IA (por ejemplo, Cursor) y herramientas automatizadas.

## Propósito

- Encapsular **procedimientos repetibles** para aplicar las reglas del stack sobre código real.
- Dar una interfaz clara para que la IA pueda:
  - Cargar el contexto correcto del stack.
  - Ejecutar revisiones guiadas por checklists.
  - Aplicar lecciones aprendidas de errores pasados.
- Facilitar la reutilización de estos procedimientos entre proyectos que consumen el stack.

## Contrato de ejecución (para IA)

Las skills son el nivel de **orquestación**: describen qué checklists ejecutar y
qué documentos consultar, sin duplicar reglas.

- El contrato de campos recomendado está documentado en `docs/governance-schemas.md`.
- Para compatibilidad, las skills pueden mantener campos legacy, pero deben
  exponer (cuando exista) un contrato simple:
  - `domain`
  - `inputs_contract`
  - `uses_checklists`
  - `expected_output_contract`

## Contenido esperado

- Ficheros de configuración de habilidades (por ejemplo, YAML o similar), tales como:
  - `ai-review.yml` – revisión general de cambios según las reglas del stack.
  - `security-audit.yml` – revisión focalizada en seguridad.
  - `multishop-audit.yml` – revisión de cumplimiento multishop.
  - `service-layer-audit.yml` – revisión de arquitectura y Service Layer.
  - `stack-validation.yml` – habilidad interna para validar la integridad del propio stack.
- Cada skill debería describir:
  - Qué dominios cubre (seguridad, arquitectura, multishop, etc.).
  - Qué checklists utiliza.
  - Qué lecciones (`lessons/`) considera relevantes.
  - Qué entradas espera (diffs, rutas de ficheros, contexto del proyecto, etc.).

## Relación con el resto del stack

- **Con `manifest/`**:
  - Las skills deberían leer el manifest del stack para conocer documentos canónicos, orden de precedencia y rutas relevantes.
- **Con `checklists/`**:
  - Las skills ejecutan o aplican las checklists definidas en ese directorio para convertir reglas en acciones concretas.
- **Con `lessons/`**:
  - Las skills pueden usar las lecciones como contexto adicional para priorizar ciertos checks o explicar riesgos conocidos al desarrollador.
- **Con `commands/`**:
  - Los commands de gobernanza pueden mapearse directamente a una o varias skills, definiendo así un flujo repetible invocable desde la terminal o desde la IA.
- **Con `tests/` y `scripts/`**:
  - Los stack tests pueden validar que las skills se comportan como se espera cuando se ejecutan sobre fixtures de ejemplo.

Este directorio se centra en describir **cómo** la IA y las herramientas deben aplicar la gobernanza, no en redefinir las reglas en sí mismas.

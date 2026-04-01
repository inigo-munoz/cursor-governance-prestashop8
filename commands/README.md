# `commands/`

Este directorio contiene la **documentación de comandos de gobernanza** del
stack PrestaShop.

## Propósito

- Definir **entrypoints de alto nivel** que los desarrolladores y asistentes de
  IA pueden invocar (por ejemplo: `/review`, `/security-check`,
  `/multishop-check`, `/servicelayer-review`, `/api-hardening`,
  `/high-concurrency-check`).
- Explicar en lenguaje humano:
  - Cuándo debe usarse cada command.
  - Qué tipo de código o cambios cubre.
  - Cómo interpretar los resultados (bloqueantes, riesgos, recomendaciones).
- Conectar cada command con las capas ejecutables de la gobernanza:
  skills, checklists y documentos canónicos.

## Relación con skills y checklists

- **Skills (`skills/`)**:
  - Cada command debería indicar explícitamente qué skill principal utiliza.
  - Ejemplos:
    - `/review` → `skills/ai-review.yml`
    - `/security-check` → `skills/security-audit.yml`
    - `/multishop-check` → `skills/multishop-audit.yml`
    - `/servicelayer-review` → `skills/service-layer-audit.yml`
- **Checklists (`checklists/`)**:
  - Los commands **no duplican** reglas; aplican una o varias checklists.
  - Ejemplos:
    - `/security-check` → `checklists/security-review.yml`
    - `/multishop-check` → `checklists/multishop-review.yml`
    - `/servicelayer-review` → `checklists/service-layer-review.yml`

## Relación con el manifest

- `manifest/stack-manifest.yml` declara:
  - Qué documentos son canónicos (regla principal, seguridad, arquitectura,
    estándares, convenciones, multishop, patrones, workflow).
  - Qué directorios son requeridos (`commands/`, `skills/`, `checklists/`,
    etc.) y su precedencia.
- Los commands de este directorio deben entenderse siempre dentro de ese
  contrato, actuando como **punto de entrada humano/IA** para las capacidades
  de gobernanza del stack.


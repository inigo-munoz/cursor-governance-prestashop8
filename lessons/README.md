# `lessons/`

Este directorio almacena **lessons**: feedback estructurado a partir de errores
reales, incidentes y problemas detectados en proyectos que usan este stack.

## Propósito

- Capturar fallos reales y convertirlos en **recomendaciones** para mejorar la
  gobernanza.
- Proporcionar trazabilidad: cada lesson referencia el artefacto afectado
  (checklist, skill o documentación).
- Servir como base para un bucle de mejora continua con revisión humana.

## Contenido esperado

- Subdirectorios por dominio:
  - `lessons/security/`
  - `lessons/architecture/`
  - `lessons/multishop/`
  - `lessons/workflow/`
- Ficheros YAML que sigan un esquema estable (ver “Schema” abajo).

## Relación con el resto del stack

- **No modifican automáticamente gobernanza**:
  - Las lessons **no** cambian reglas, skills ni checklists de forma automática.
  - Cualquier cambio en artefactos de gobernanza requiere **validación humana**
    y PR explícito.
- **Con `checklists/`**:
  - Nuevas lecciones pueden derivar en pasos adicionales de checklist o en la creación de nuevas checklists.
- **Con `skills/`**:
  - Las skills pueden usar las lecciones para:
    - Priorizar ciertos checks.
    - Proporcionar explicaciones basadas en incidentes reales.
- **Con `workflow/` y `commands/`**:
  - Lecciones sobre fallos de proceso (por ejemplo, saltarse un `/security-check` antes de merge) pueden fortalecer workflow y commands asociados.
- **Con `tests/`**:
  - Algunas lecciones críticas pueden convertirse en escenarios de test del stack para evitar regresiones de gobernanza.

Este directorio busca que el sistema de gobernanza **aprenda y mejore en el tiempo**, en lugar de ser solo un conjunto estático de documentos.

## Schema (YAML)

Cada lesson debe seguir este esquema:

- `id`: `lesson.<domain>.<short-name>`
- `domain`: `security | architecture | multishop | workflow`
- `source`: origen de la lesson (tipo y descripción)
- `problem`: descripción del problema
- `impact`: severidad y alcance
- `root_cause`: causa raíz
- `recommended_action`: recomendación (tipo y target) para mejorar checklists,
  skills o documentación

### `recommended_action.target` schema

Para evitar ambigüedad, `recommended_action.target` debe ser una estructura
tipada:

```yaml
recommended_action:
  type: checklist-improvement | skill-improvement | rule-clarification
  target:
    type: checklist | skill | rule | documentation
    name: <artifact filename>
```

- **`target.type`**:
  - `checklist`: cuando el objetivo es un YAML en `checklists/`
  - `skill`: cuando el objetivo es un YAML en `skills/`
  - `rule`: cuando el objetivo es un documento `.md` en `rules/`
  - `documentation`: cuando no aplica o no puede inferirse automáticamente
- **`target.name`**:
  - Nombre del fichero del artefacto objetivo (por ejemplo `security-review.yml`,
    `service-layer-audit.yml`).

Esta estructura permite que tooling de gobernanza y asistentes de IA rastreen
qué artefacto debe revisarse y mejorarse, siempre con validación humana.

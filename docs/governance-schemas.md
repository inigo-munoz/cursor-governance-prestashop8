# Esquemas de gobernanza ejecutable (Skills y Checklists)

Este documento define un **contrato de ejecución** para que asistentes de IA
puedan descubrir, cargar e invocar las capas ejecutables del stack sin depender
de interpretaciones ad-hoc.

## Objetivo

- Establecer una estructura consistente para:
  - Checklists (`checklists/*.yml`)
  - Skills (`skills/*.yml`)
- Mantener compatibilidad hacia atrás:
  - Los ficheros existentes no se rompen.
  - Los campos históricos se conservan.
  - Los nuevos campos se añaden de forma **aditiva**.

## Principio de compatibilidad

Los ficheros YAML existentes pueden tener estructuras ricas (por ejemplo,
`steps` como lista de objetos con `id`, `mandatory`, `checks`, etc.). Para no
romper consumidores existentes, el contrato estándar se define en campos
**adicionales** (con sufijo `_contract`) que:

- Son simples y estables para IA.
- Resumen el “qué” sin reimplementar el “cómo”.

---

## Checklist schema (contrato)

Un checklist debe exponer, como mínimo, los siguientes campos de contrato:

- `id`: `checklist.<name>`
- `domain`: `security | architecture | multishop | workflow`
- `purpose`: descripción corta del objetivo de validación
- `references_contract`: lista de documentos de gobernanza consultados (rutas)
- `steps_contract`: lista de pasos de validación (strings, alto nivel)
- `expected_findings`: lista de tipos de hallazgos esperados (strings)

Ejemplo (contrato mínimo):

```yaml
id: checklist.security_review
domain: security
purpose: Validar cumplimiento de seguridad del módulo
references_contract:
  - security/prestashop-security.md
steps_contract:
  - validar sanitización de inputs
  - revisar uso de SQL
  - verificar protección CSRF
expected_findings:
  - riesgo de SQL injection
  - falta de CSRF protection
```

### Campos legacy permitidos

Para compatibilidad, se permiten (y se mantienen) campos existentes como:

- `name`, `description`
- `references` (mapa o lista)
- `steps` (estructura detallada)
- Cualquier estructura adicional existente (por ejemplo `validation_steps`)

La IA debe preferir:

1. `*_contract` si existe.
2. En su defecto, inferir desde `references` y `steps` existentes.

---

## Skill schema (contrato)

Una skill orquesta uno o más checklists y expone:

- `id`: `skill.<name>`
- `domain`: mismo dominio que los checklists que ejecuta
- `purpose`: procedimiento de gobernanza de alto nivel
- `inputs_contract`: lista de inputs mínimos esperados:
  - `repository`
  - `changed_files`
  - (opcional) `diff`
  - (opcional) `context_files`
- `uses_checklists`: lista de ficheros de checklist (rutas o basenames)
- `expected_output_contract`: lista de categorías de salida:
  - `governance violations`
  - `recommendations`

Ejemplo (contrato mínimo):

```yaml
id: skill.security_audit
domain: security
purpose: Realizar una revisión completa de gobernanza de seguridad
inputs_contract:
  - repository
  - changed_files
  - diff
uses_checklists:
  - checklists/security-review.yml
expected_output_contract:
  - security vulnerabilities
  - governance violations
  - recommendations
```

### Campos legacy permitidos

Para compatibilidad, se mantienen estructuras existentes como:

- `inputs` (lista de objetos con `name`/`description`)
- `governance_documents` (lista o mapa)
- `checklists` (lista de rutas)
- `expected_output` (estructura detallada)

La IA debe preferir:

1. `uses_checklists` y `*_contract` si existen.
2. En su defecto, usar `checklists` y los campos legacy.

---

## Relación Skill ↔ Checklist

- Un **command** (documentación humana) describe qué skill invoca.
- Una **skill** describe qué checklists ejecuta (`uses_checklists`).
- Un **checklist** define qué validar (pasos) y qué documentos son autoritativos
  (`references_contract`), sin duplicar reglas.

Este contrato está diseñado para que la IA pueda:

- Descubrir skills y checklists por rutas (`skills/*.yml`, `checklists/*.yml`).
- Entender rápidamente su propósito y dominio.
- Ejecutar validaciones de forma consistente y trazable a documentos canónicos.


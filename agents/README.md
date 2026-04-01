# `agents/`

Este directorio define **agentes de gobernanza** de alto nivel que orquestan
las skills existentes del stack PrestaShop.

## Propósito

- Proporcionar puntos de entrada claros para asistentes de IA (por ejemplo,
  “security auditor”, “architecture reviewer”, “multishop validator”).
- Agrupar una o varias skills bajo un identificador de agente (`agent.*`) que
  represente una responsabilidad de gobernanza bien definida.
- Evitar duplicar lógica: los agentes solo **combinan y configuran** skills,
  no redefinen reglas ni checklists.

## Estructura básica de un agente

Cada agente se declara en un fichero YAML con, al menos:

- `id`: identificador estable (por ejemplo, `agent.security-auditor`).
- `domain`: dominio de gobernanza que maneja el agente (por ejemplo: `security`,
  `architecture`, `multishop`, `workflow`, etc.).
- `purpose`: descripción de alto nivel de la función del agente.
- `uses_skills`: lista de rutas a skills de `skills/` que el agente invoca.

### Agent schema

Un agente debe incluir:

- `id`: identificador único del agente.
- `domain`: dominio de gobernanza manejado por el agente (`security`,
  `architecture`, `multishop`, `workflow`, etc.).
- `purpose`: descripción corta de la responsabilidad del agente.
- `uses_skills`: lista de skills orquestadas por el agente (rutas bajo `skills/`).

Ejemplos iniciales:

- `agents/security-auditor.yml` → usa `skills/security-audit.yml`
- `agents/architecture-reviewer.yml` → usa `skills/service-layer-audit.yml`
- `agents/multishop-validator.yml` → usa `skills/multishop-audit.yml`

## Uso por asistentes de IA

Un asistente de IA puede:

1. Descubrir agentes leyendo `agents/*.yml`.
2. Seleccionar el agente adecuado según el tipo de revisión requerida
   (seguridad, arquitectura, multishop, etc.).
3. Ejecutar las skills declaradas en `uses_skills`, que a su vez aplican las
   checklists y reglas correspondientes.

De esta forma, los agentes actúan como una **capa de orquestación** encima de
skills y checklists, ofreciendo una interfaz más simple para iniciar flujos de
gobernanza complejos.


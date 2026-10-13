SDD Governance – PrestaShop Stack

Framework oficial de gobernanza técnica para proyectos PrestaShop 8.x legacy con módulos custom en tu equipo.

Este repositorio define el estándar obligatorio de arquitectura, seguridad, patrones y uso de IA para todos los proyectos PrestaShop gestionados por el departamento.

1. Propósito

Este repositorio existe para:

Garantizar consistencia técnica entre proyectos.

Elevar el nivel de seguridad a estándar enterprise.

Eliminar decisiones improvisadas por proyecto.

Establecer un entorno controlado para el uso de IA.

Reducir deuda técnica estructural.

Este no es un repositorio opcional.
Es el marco normativo técnico del stack PrestaShop.

2. Alcance

Aplica a:

Todos los nuevos módulos custom.

Todas las integraciones externas (SAP, APIs, etc.).

Refactorizaciones relevantes.

Desarrollo asistido por IA (Cursor u otros LLM).

No sustituye el core de PrestaShop.
Regula el código que la empresa escribe.

3. Prioridad Técnica Oficial

Ver `rules/prestashop-main-rule.md`. En caso de conflicto de decisiones, la prioridad definida allí es vinculante.

4. Estructura del Repositorio
architecture/   → Modelo arquitectónico del stack
context/        → Restricciones técnicas del proyecto
rules/          → Rule principal obligatorio para IA
security/       → Normativa de seguridad v2.0
patterns/       → Patrones técnicos y enterprise hardened
conventions/    → Convenciones de código
multishop/      → Modelo multishop obligatorio
workflow/       → Flujo de gobernanza
standards/      → Estándares operativos del stack
skills/         → Automatizaciones y capacidades IA

4.1 Governance Tools

Este stack proporciona **herramientas de gobernanza ejecutables** que pueden ser
invocadas por asistentes de desarrollo (por ejemplo, Cursor):

- skills/ → Procedimientos orquestados de gobernanza que combinan reglas,
  checklists y contexto del proyecto.
- checklists/ → Listas de verificación estructuradas que convierten las reglas
  del stack en pasos de validación deterministas.
- commands/ → Puntos de entrada de alto nivel (por ejemplo `/review`,
  `/security-check`, `/multishop-check`, `/servicelayer-review`) documentados
  para uso humano e IA.

5. Jerarquía de Autoridad Documental

En caso de conflicto entre documentos:

prestashop-security.md prevalece sobre todo.

rules/prestashop-main-rule.md

Patrones enterprise

Estándares de desarrollo

Convenciones

La seguridad nunca se negocia.

6. Modelo Arquitectónico

El stack PrestaShop en se basa en:

Arquitectura legacy controlada (sin namespaces, sin PSR-4)

Service Layer obligatorio

Multishop explícito

Sin overrides salvo excepción documentada

Validación estricta de inputs

Integraciones externas protegidas por locking + idempotency

Rate-limited logging

Validación de esquemas externos

No se permite arquitectura híbrida improvisada.

7. Uso de IA

El desarrollo asistido por IA debe:

Respetar el prefijo Acme en todas las clases custom.

Cumplir reglas de seguridad sin excepción.

No generar overrides no documentados.

No mover lógica de negocio a hooks/controllers.

No generar código sin filtrado multishop.

El rule principal del stack se encuentra en:

rules/prestashop-main-rule.md


Todo agente IA debe cargarse con ese rule como contexto obligatorio.

8. Enterprise Hardened Mode

Este stack incluye capacidades enterprise:

Distributed Locking (Redis)

Idempotency para integraciones externas

Protección anti-race condition en checkout

Validación estricta de respuestas API

Logging con rate-limit

Protección avanzada de AJAX

Estas capacidades no son opcionales cuando el caso lo requiera.

9. Qué NO es este repositorio

No es un repositorio de módulos.

No es un repositorio de snippets sueltos.

No es documentación decorativa.

No es una sugerencia.

Es un marco normativo técnico.

10. Gobernanza y Evolución

Toda modificación estructural del stack requiere:

Documentación clara del cambio.

Justificación técnica.

Aprobación del Tech Lead.

Actualización del versionado documental.

11. Versionado

Cada documento contiene:

Versión

Fecha de revisión

Responsable

El stack PrestaShop se versiona de forma independiente al governance core.

12. Nivel de Madurez Esperado

Este stack está diseñado para:

Entornos de alta concurrencia.

Integraciones externas críticas.

Comercio B2B.

Escenarios con impacto financiero real.

No está diseñado para desarrollos rápidos sin control.

13. Filosofía

Control > Creatividad improvisada
Estandarización > Héroes individuales
Sistemas robustos > Soluciones rápidas

flowchart TB

    DEV[Desarrollador]
    IA[IA / Cursor]
    
    CORE_RULE[Rule Principal<br/>prestashop-main-rule.md]
    SECURITY[Security v2.0]
    PATTERNS[Patterns Enterprise]
    CONTEXT[Context & Architecture]
    CONVENTIONS[Conventions]
    
    CODE[Code Generated / Refactored]
    
    SERVICE[Service Layer]
    HOOKS[Hooks & Controllers]
    MODULE[Module Runtime]
    
    REDIS[Redis Locking]
    SAP[SAP / External APIs]
    DB[(Database<br/>Multishop)]
    
    LOGGING[Rate-Limited Logging]

    DEV --> IA
    IA --> CORE_RULE
    CORE_RULE --> SECURITY
    CORE_RULE --> PATTERNS
    CORE_RULE --> CONTEXT
    CORE_RULE --> CONVENTIONS

    SECURITY --> CODE
    PATTERNS --> CODE
    CONTEXT --> CODE
    CONVENTIONS --> CODE

    CODE --> SERVICE
    SERVICE --> HOOKS
    HOOKS --> MODULE

    SERVICE --> REDIS
    SERVICE --> SAP
    SERVICE --> DB

    SAP --> LOGGING
    REDIS --> LOGGING
    MODULE --> LOGGING
    
14.2 Explicación del Modelo
Capa 1 — Gobernanza (Control)

Esta capa no ejecuta código.
Define cómo debe escribirse.

Incluye:

Rule principal

Security v2.0

Patrones enterprise

Contexto arquitectónico

Convenciones

👉 Esta capa controla al desarrollador y a la IA.

Capa 2 — Generación de Código

El código generado o refactorizado:

Debe respetar el prefijo Acme

Debe cumplir multishop explícito

Debe usar Service Layer

No puede ignorar locking si hay concurrencia

No puede ignorar validación externa

Aquí es donde la mayoría de equipos fallan.

Capa 3 — Runtime PrestaShop

Arquitectura:

Hook / Controller
        ↓
Service Layer
        ↓
Integraciones / DB


Nunca al revés.

La lógica de negocio vive en Service Layer.
Hooks solo coordinan.

Capa 4 — Integraciones Críticas

Cuando el código toca:

SAP

APIs externas

Stock

Checkout

Se activan automáticamente:

Distributed Locking (Redis)

Idempotency

Schema validation

Rate-limited logging

Esto convierte el stack en enterprise hardened.

Capa 5 — Persistencia

Base de datos siempre:

Filtrada por id_shop

Sin mezclar contexto global sin documentar

Sin SQL dinámico sin whitelist
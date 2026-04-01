PrestaShop 8.x Legacy Architecture

SDD Governance — Architecture Definition
Versión: 1.0
Estado: Autoritativo

1. Alcance

Este documento define la arquitectura oficial del proyecto:

Plataforma: PrestaShop 8.x Legacy

Sin migración a Symfony completa

Sin Composer autoload

Sin namespaces

Producción activa con tráfico real

Este documento prevalece sobre prácticas ad-hoc.

2. Principios Arquitectónicos
2.1 Prioridad del sistema

Seguridad > Estabilidad > Robustez > Funcionalidad > Rapidez

2.2 Arquitectura conservadora

Este proyecto:

NO es DDD puro

NO es Hexagonal puro

NO usa Symfony DI

NO usa Namespaces

NO usa Composer autoload

Es arquitectura Legacy controlada.

3. Modelo de Capas

La arquitectura se organiza en 6 capas explícitas:

[ Presentation ]
        ↓
[ Controllers ]
        ↓
[ Service Layer ]
        ↓
[ Domain Models (ObjectModel) ]
        ↓
[ Infrastructure ]
        ↓
[ External Systems ]

4. Definición Formal de Cada Capa
4.1 Presentation Layer

Incluye:

Smarty templates

Assets JS/CSS

XLIFF

Reglas:

No lógica de negocio

No consultas SQL

Escape contextual obligatorio

Solo renderizado de datos preparados

Violación → Bloqueante en review

4.2 Controllers

Tipos:

ModuleFrontController

ModuleAdminController

Reglas:

Validar inputs

Delegar inmediatamente en Service

No lógica compleja

No SQL directo

No reglas de negocio

El controller es un orquestador mínimo.

4.3 Service Layer (OBLIGATORIO)

Aquí vive:

Lógica de negocio

Validaciones complejas

Reglas de dominio

Orquestación entre modelos

Integraciones externas

Reglas:

Prefijo Iagt

Métodos estáticos permitidos

Sin dependencia circular

Manejo explícito de id_shop

No acceso directo a $_POST / $_GET

El Service Layer es el núcleo del sistema.

4.4 Domain Layer

Basado en ObjectModel legacy.

Reglas:

multishop => true si aplica

add() asegura id_shop

Sin lógica compleja

No llamadas a APIs externas

ObjectModel representa datos, no procesos.

4.5 Infrastructure Layer

Incluye:

Locking distribuido

Rate-limited logging

Redis

DB abstractions

Helpers técnicos

Reglas:

No lógica de negocio

Solo soporte técnico

Reutilizable entre módulos

4.6 External Systems

Ejemplos:

SAP

APIs externas

Pasarelas de pago

Reglas:

Timeout obligatorio

Connect timeout obligatorio

Validación estructural de respuesta

No propagación de datos sin validar

Retry/backoff solo si crítico

5. Dependencias Permitidas

Regla fundamental:

Una capa solo puede depender de la inmediatamente inferior.


Permitido:

Controller → Service

Service → ObjectModel

Service → Infrastructure

Infrastructure → DB/Redis

Prohibido:

Controller → DB directo

Smarty → Service

ObjectModel → API externa

Infrastructure → Service

6. Multishop como Axioma Arquitectónico

Multishop no es opcional.

Cada operación debe:

Conocer el contexto

Filtrar por id_shop

Decidir explícitamente CONTEXT_ALL

No existe “modo single shop”.

7. Override Policy Arquitectónica

Overrides:

Prohibidos por defecto

Permitidos solo con excepción documentada

Revisados cada 6 meses

Un override es deuda técnica explícita.

8. Concurrencia y Operaciones Críticas

Para:

Stock

Pedidos

Sincronizaciones SAP

Actualizaciones masivas

Debe evaluarse:

Riesgo de race condition

Locking distribuido

Idempotencia

Consistencia eventual

El documento enterprise-hardened aplica aquí.

9. Estrategia de Evolución

Este sistema:

No será migrado a Symfony full-stack a corto plazo

No se fragmentará en microservicios

No usará Event Bus externo

Evolución permitida:

Mejora de Services

Refuerzo de seguridad

Refactor controlado

Extracción progresiva si se documenta

10. Arquitectura No Permitida

Prohibido introducir:

Namespaces

Autoload Composer global

DI container Symfony

Código en core PrestaShop

Modificaciones directas a tablas críticas

Lógica en hooks extensa

11. Checklist Arquitectónico de Review

Antes de aprobar:

☐ ¿Hay lógica en Service?
☐ ¿Controller es delgado?
☐ ¿Se respeta multishop?
☐ ¿No hay SQL directo en controller?
☐ ¿No hay override no documentado?
☐ ¿No se rompe aislamiento de capas?
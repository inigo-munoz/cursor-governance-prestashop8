PrestaShop 8.x Legacy — Development Standards

SDD Governance
Versión: 1.0
Estado: Autoritativo

1. Alcance

Este documento define:

Cómo se estructura un módulo propio

Cómo se organizan clases internas

Cómo se gestionan migraciones

Cómo se gestionan integraciones

Cómo se estructuran logs, locks y servicios compartidos

No sustituye:

coding-conventions.md

prestashop-security.md

multishop-data-model.md

ARCHITECTURE.md

Este documento complementa a architecture.

2. Estructura Obligatoria de un Módulo Propio

Estructura mínima recomendada:

modules/vendor_modulename/

├── vendor_modulename.php
├── classes/
│   ├── AcmeModulenameService.php
│   ├── AcmeModulenameRepository.php (si aplica)
│   ├── AcmeModulenameValidator.php (si aplica)
│   └── models/
│       └── AcmeModulenameEntity.php
├── controllers/
│   ├── admin/
│   └── front/
├── views/
│   ├── templates/
│   └── js/
├── sql/
│   ├── install.sql
│   └── uninstall.sql
├── translations/
└── docs/
    └── README.md

Reglas:

Toda lógica → classes/

Nada de lógica en módulo principal

Nada de lógica compleja en controllers

Nada de SQL en controllers

3. Organización Interna de Clases
3.1 Service

Debe existir siempre si:

Hay lógica de negocio

Hay integración externa

Hay múltiples validaciones

Ejemplo correcto:

AcmeSapStockService
AcmeCounterofferService
AcmeOrderSyncService


Service ≠ Helper.

3.2 Repository (Opcional pero recomendado)

Si hay múltiples queries complejas:

AcmeCounterofferRepository


Responsable de:

Queries

Filtros multishop

Construcción de DbQuery

No debe:

Contener lógica de negocio

3.3 Validator

Si hay validación compleja de inputs:

AcmeCounterofferValidator


Responsable de:

Validación estructural

Normalización

Reglas sintácticas

No debe:

Persistir datos

4. SQL y Migraciones
4.1 Prohibido

ALTER manual en producción

Modificar tablas core

Ejecutar SQL fuera de install/uninstall sin versionado

4.2 Versionado interno

Si el módulo evoluciona:

Mantener constante de versión

Implementar upgrade scripts

No mezclar lógica de upgrade con lógica funcional

Ejemplo:

upgrade-1.1.0.php
upgrade-1.2.0.php

5. Logging Standards

Ver reglas completas en `security/prestashop-security.md` — Rules 8 y 12.
Resumen: sin datos sensibles, rate-limited para errores frecuentes, sin `error_log()` ni `die()`.

6. Locking Standards

Ver implementación completa en `security/prestashop-security.md` — Rule 13, y `patterns/prestashop-enterprise-hardened-v2.0.md` — sección 1.
Obligatorio en: stock, SAP, checkout, operaciones batch con riesgo de race condition.

7. Integraciones Externas

Ver reglas completas en `security/prestashop-security.md` — Rules 5 y 11, y `patterns/prestashop-enterprise-hardened-v2.0.md` — secciones 2 y 6.
Toda integración encapsulada en Service, con timeout y validación de respuesta.

8. Frontend Standards

Templates solo renderizan

JS no contiene lógica de negocio

AJAX que modifica estado → POST only

Validación backend siempre obligatoria aunque haya validación JS

9. Admin Standards

En BO:

Siempre respetar contexto multishop

Siempre verificar permisos si se usa id_shop manual

Siempre filtrar listados por tienda si aplica

No mostrar datos de otras tiendas

10. Testabilidad

Aunque proyecto legacy:

Se recomienda:

Services desacoplados de superglobals

Métodos con parámetros explícitos

No dependencia implícita de Tools::getValue dentro del Service

Mal ejemplo:

Service que llama Tools::getValue()


Correcto:

Controller obtiene input → pasa a Service

11. Documentación por Módulo

Cada módulo debe incluir:

docs/README.md


Debe explicar:

Qué hace

Qué tablas crea

Qué hooks usa

Si tiene override (y por qué)

Si requiere Redis o locking

Riesgos de concurrencia

12. Performance Guidelines

Evitar:

Queries N+1

Loops con queries internas

Carga completa de objetos innecesarios

Instanciar ObjectModel si solo necesitas un campo

Preferir:

DbQuery

Queries selectivas

Indexes correctos

13. Anti-Patterns Prohibidos

Lógica en hooks

SQL en controllers

ObjectModel con lógica compleja

Integraciones externas en modelos

Ignorar id_shop

Subqueries innecesarias en multishop

Código copiado entre módulos

14. Checklist Antes de PR

Ver `pr-checklist.md` — es el documento canónico para el checklist de PR.
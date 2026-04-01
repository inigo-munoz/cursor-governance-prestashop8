# `tests/`

Este directorio contiene los **tests de gobernanza del stack**, también llamados *stack tests*.

## Propósito

- Validar de forma **determinista** que el stack de gobernanza se comporta como se espera.
- Asegurar que la evolución de reglas, checklists, skills y workflow no introduce regresiones.
- Permitir que `verify-governance.sh` y la CI ejecuten pruebas automáticas sobre el propio stack y sobre fixtures de ejemplo.

## Contenido esperado

- `unit/`:
  - Tests unitarios de gobernanza basados en casos mínimos de código.
  - Cada test incluye:
    - **code sample** (por ejemplo, `.php`) con un problema conocido.
    - **expected findings** (YAML) con los hallazgos que las skills/checklists
      deberían detectar.
- `integration/`:
  - Tests de integración de gobernanza para ejecutar skills/checklists sobre
    estructuras de módulo más completas y flujos más realistas.
- `fixtures/`:
  - Ejemplos mínimos de código o estructuras (por ejemplo, módulos PrestaShop) usados como casos de prueba:
    - Módulos correctos según la gobernanza.
    - Módulos con violaciones intencionadas de seguridad, multishop, arquitectura, etc.
- `scenarios/`:
  - Descripciones estructuradas de qué revisar sobre cada fixture:
    - Qué comandos o skills deben ejecutarse.
    - Qué checklists deben aplicarse.
- `expectations/`:
  - Resultados esperados para cada escenario (por ejemplo, qué hallazgos deben aparecer en una revisión de seguridad).
- Ficheros adicionales de configuración o utilidades necesarias para describir y ejecutar estos tests.

## Relación con el resto del stack

- **Con `manifest/`**:
  - Los tests deberían respetar la información declarada en el manifest (documentos canónicos, orden de precedencia, rutas, etc.).
- **Con `checklists/` y `skills/`**:
  - Los escenarios de test especifican qué checklists y skills deben ejecutarse y verifican que su comportamiento coincida con las expectativas.
- **Con `lessons/`**:
  - Lecciones críticas pueden transformarse en escenarios de test para evitar que errores históricos reaparezcan.
- **Con `scripts/` y CI**:
  - Scripts como `verify-governance.sh` deberían usar este directorio para:
    - Ejecutar los stack tests.
    - Fallar la validación del stack si alguno de los tests no se cumple.

Este directorio convierte la gobernanza en algo **testeable y verificable**, en lugar de depender solo de revisiones manuales o de buena voluntad.

# `manifest/`

Este directorio define el **manifiesto del stack de gobernanza**.

## Propósito

- **Describir el stack**: nombre, versión y relación con `governance-core`.
- **Declarar documentos canónicos**: qué ficheros son la referencia oficial de seguridad, arquitectura, estándares, etc.
- **Definir la estructura**: qué directorios son obligatorios u opcionales dentro del stack.
- **Fijar la precedencia**: en caso de conflicto entre documentos, quién manda.

## Contenido esperado

- `stack-manifest.yml` (o similar): fichero en formato legible por herramientas (YAML/JSON) que contenga:
  - Nombre e identificador del stack (por ejemplo, `governance-prestashop`).
  - Versión del stack y dependencia mínima de `governance-core`.
  - Rutas de documentos canónicos (`security/`, `rules/`, `architecture/`, etc.).
  - Listado de directorios requeridos y opcionales.
  - Orden de precedencia entre capas (seguridad, rule principal, arquitectura, estándares, workflow, commands, lessons).
- Ficheros adicionales de manifiesto o esquemas compartidos si el stack los necesita.

## Relación con el resto del stack

- **Con `governance-core`**: el manifest indica qué versión de core es compatible y cómo se monta este stack sobre él (por ejemplo, vía `git subtree`).
- **Con `rules/`, `security/`, `architecture/`, `standards/`, `conventions/`, `patterns/`, `multishop/`, `context/`**:
  - El manifest declara qué documentos de estos directorios son canónicos y cuál es su rol.
- **Con `checklists/`, `skills/`, `lessons/`, `tests/`**:
  - El manifest actúa como punto de entrada para herramientas y CI, indicando dónde encontrar checklists, habilidades IA, lecciones y tests de gobernanza.
- **Con `scripts/` y CI**:
  - Scripts como `verify-governance.sh` deberían leer este directorio para saber cómo validar el stack y qué comprobaciones ejecutar.

Este directorio no debe contener documentación narrativa larga; su objetivo es servir como **contrato estructural** y punto de verdad para herramientas de gobernanza.

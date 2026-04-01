# Helpers para tests

Utilidades compartidas para la ejecución de tests (incluidos los de gobernanza).

## Resolución de rutas: `stack-root.sh`

**Regla obligatoria:** todo script que ejecute tests de gobernanza debe usar `stack-root.sh` como única fuente de verdad para la raíz del stack. No se debe calcular un `ROOT` local; usar siempre `STACK_ROOT`.

Los tests de gobernanza deben resolver rutas desde la **raíz del stack** (raíz del repositorio) en lugar de usar rutas relativas frágiles como `../../skills`, `../../checklists` o `../../agents`.

### Uso

1. **En cualquier script de test de gobernanza**, incluir al inicio (patrón estándar con `SCRIPT_DIR`):

   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/../tests/helpers/stack-root.sh"
   if [ -z "${STACK_ROOT:-}" ]; then echo "Failed to resolve STACK_ROOT"; exit 1; fi
   ```

   No usar `cd "$STACK_ROOT"`: todas las rutas deben ser absolutas (`$STACK_ROOT/skills`, etc.) para no depender del directorio de trabajo.

   Para scripts en `scripts/`: `source "$SCRIPT_DIR/../tests/helpers/stack-root.sh"`.  
   Para scripts en `tests/governance/skills|checklists|agents/`: `source "$SCRIPT_DIR/../../helpers/stack-root.sh"`. Ajustar la ruta relativa según la ubicación del script.

2. **Usar `$STACK_ROOT`** para referenciar directorios del stack:

   - `$STACK_ROOT/skills` en lugar de `../../skills`
   - `$STACK_ROOT/checklists` en lugar de `../../checklists`
   - `$STACK_ROOT/agents` en lugar de `../../agents`

### Ejemplo

Antes (frágil):

```bash
skills_dir="../../skills"
```

Después (portable):

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../helpers/stack-root.sh"
skills_dir="$STACK_ROOT/skills"
```

### Portabilidad

El helper utiliza `BASH_SOURCE[0]` para determinar su propia ubicación, de modo que `STACK_ROOT` se resuelve correctamente cuando los tests se ejecutan:

- desde el CLI (`iagt-governance validate`),
- desde pipelines de CI,
- o directamente desde el directorio de tests.

No se debe depender del directorio de trabajo actual (`$PWD`); todas las rutas a skills, checklists y agents deben pasar por `$STACK_ROOT`.

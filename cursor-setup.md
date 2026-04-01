# CURSOR SETUP — Configuración de Governance en Proyectos

Este documento explica cómo configurar un proyecto PrestaShop para que Cursor utilice el sistema de governance.

---

## Método recomendado: CLI

```bash
# Setup inicial (proyecto nuevo)
iagt-governance init --stack prestashop --core v2.1.1 --stack-version v2.2.0
cursor-governance apply

# Actualizar governance
iagt-governance update
iagt-governance bump --core vX.X.X --stack vX.X.X
cursor-governance apply
iagt-governance verify

# Verificar configuración
iagt-governance doctor
```

---

## Método manual

Si el CLI no está disponible:

---

## Modelo de integración

La governance vive en el catálogo local de la máquina: `~/.iagt/governance/`.

El proyecto solo contiene `.iagt-governance.yml` (el pin de versión/fuentes).

`cursor-governance apply` genera tres cosas en `.cursor/`:

- `rules/governance-stack.mdc` — entrypoint MDC con `alwaysApply: true` y `@` a la main rule (carga siempre)
- `rules/governance-security.mdc` — security rules con `globs: **/*.php,**/*.tpl` (carga solo con PHP/Smarty)
- `commands/*.md` — commands del stack sincronizados, invocables con `/` en Cursor
- `skills/<nombre>/SKILL.md` — skills del stack para carga dinámica por el agente

`.cursor/` no se commitea porque las rutas `@` son absolutas y específicas de cada máquina.

---

## Paso 1: Aplicar governance en el proyecto

```bash
# Desde la raíz del proyecto
cursor-governance apply
```

---

## Paso 2: Configurar Cursor

### 2.1 Verificar archivos generados

`cursor-governance apply` genera todo lo necesario en `.cursor/`:

```bash
ls .cursor/rules/
# governance-stack.mdc    → alwaysApply: true  (siempre)
# governance-security.mdc → globs: *.php,*.tpl (solo PHP/Smarty)
ls .cursor/commands/   # commands del stack (/review, /security-check, ...)
ls .cursor/skills/     # skills para carga dinámica por el agente
ls .cursor/hooks.json  # hook stop → iagt-governance validate
```

### 2.2 .cursorignore

`cursor-governance apply` genera un `.cursorignore` base automáticamente si no existe. Incluye las exclusiones estándar del stack PrestaShop: dependencias, cache, assets compilados y configuración sensible.

**Revisar y ajustar antes de commitear** — es un punto de partida, no una configuración definitiva.

Regla crítica: no excluir `.cursor/rules/`. Si se excluye, Cursor no carga el entrypoint y la governance no tiene efecto.

Para regenerar desde cero: eliminar `.cursorignore` y ejecutar `cursor-governance apply` de nuevo.

---

## Hooks generados

`apply` configura cuatro hooks en `.cursor/hooks.json`:

| Hook | Script | Qué hace |
|------|--------|---------|
| `beforeReadFile` | `governance-secrets-redact.sh` | Redacta credenciales y API keys antes de enviarlas al LLM |
| `beforeShellExecution` | `governance-shell-guard.sh` | Bloquea `git push --force`, `rm -rf` en dirs críticos, SQL destructivo |
| `afterFileEdit` | `governance-php-scan.sh` | Detecta raw superglobals y SQL sin sanitizar en PHP recién editado |
| `stop` | `governance-stop.sh` | Ejecuta `iagt-governance validate` al terminar cada sesión |

Los hooks `beforeReadFile` y `beforeShellExecution` son deterministas — no pasan por el LLM.
Para depurar: View → Output → Hooks en Cursor.

---

## Paso 3: Verificar configuración

### 3.1 Verificar que Cursor ve la rule

1. Abrir Cursor en el proyecto
2. Ir a Settings → Rules
3. Debe aparecer `governance-stack.mdc` en la lista

### 3.2 Verificar indexado

1. Ir a Settings → Indexing & Docs
2. Verificar que `.cursor/rules/governance-stack.mdc` está indexado/cargado
3. Si no aparece → hacer Sync

### 3.3 Test rápido

En el chat de Cursor, escribir:

```
¿Cuál es la prioridad técnica del stack?
```

Cursor debe responder algo como:
> Seguridad > Estabilidad > Robustez > Arquitectura > Funcionalidad > Rapidez

Si responde correctamente → la rule está activa.

---

## Paso 4: Uso diario

### Invocar commands

Los commands se invocan escribiendo en el chat:

```
/review
```

```
/security-check
```

```
/multishop-check
```

Cursor, con el contexto de la governance cargado, aplicará las reglas documentadas.

### Antes de PR

1. Ejecutar `/review` sobre el código modificado
2. Si hay SQL/inputs/uploads → `/security-check`
3. Si hay queries → `/multishop-check`
4. Copiar pr-checklist.md en la descripción del PR

---

## Actualizar governance

Cuando haya cambios en governance o en el pin del proyecto:

```bash
cursor-governance apply
```

---

## Estructura final esperada

```
proyecto/
├── .cursor/
│   └── rules/
│       └── governance-stack.mdc
├── .cursorignore
├── .iagt-governance.yml
├── modules/
├── src/
└── ...
```

---

## Troubleshooting

| Problema | Solución |
|----------|----------|
| Cursor no ve la rule | Verificar `.cursor/rules/governance-stack.mdc`, reiniciar Cursor |
| Commands no funcionan | Verificar `cursor-governance apply` y recargar contexto en Cursor |
| Respuestas genéricas | Reindexar: Settings → Indexing → Sync |

---

## Checklist de verificación

```
[ ] `.iagt-governance.yml` presente en el proyecto
[ ] `cursor-governance apply` ejecutado
[ ] `.cursor/rules/governance-stack.mdc` generado
[ ] .cursorignore configurado
[ ] Cursor muestra la rule en Settings
[ ] Test de prioridad técnica funciona
[ ] Commands responden con contexto PrestaShop
```

---

## Notas importantes

- **No commitear `.cursor/`** — Contiene rutas `@` absolutas, específicas de cada máquina
- **Reaplicar tras cambios** — Después de actualizar el pin o governance, ejecutar `cursor-governance apply`
- **Reindexar tras actualizar** — Después de aplicar, hacer Sync en Cursor

---

Última revisión: 2026-02-23

---

## Integración con CI/CD

### GitHub Actions

```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: Verify Governance
          script:
            - cursor-governance apply
            - iagt-governance verify
```

### GitHub Actions

```yaml
name: Governance Check
on: [pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Verify Governance
        run: |
          cursor-governance apply
          iagt-governance verify
```


---

## Paso 4: Indexar documentación externa (@Docs)

Cursor puede indexar documentación externa y hacerla accesible con `@NombreDoc` en el chat. Configurar una vez por máquina en **Cursor Settings → Indexing & Docs → Add new doc**.

### Documentación recomendada para este stack

| Doc | URL | Uso |
|-----|-----|-----|
| PrestaShop Dev Docs | `https://devdocs.prestashop-project.org/` | Hooks, ObjectModel, módulos |
| PrestaShop 8 Changelog | `https://devdocs.prestashop-project.org/8/` | Cambios de la versión |
| PSR-12 | `https://www.php-fig.org/psr/psr-12/` | Estilo de código |
| PHP 8.1 | `https://www.php.net/manual/en/migration81.php` | Features de la versión |

### Cómo usar en el chat

```
# Preguntar sobre un hook específico
@PrestaShop Dev Docs ¿Cómo funciona el hook actionValidateOrder?

# Verificar sintaxis PSR-12
@PSR-12 ¿Cuál es la convención de indentación correcta?
```

### Nota sobre @Web

Alternativa sin configuración previa: usar `@Web` en el chat para búsquedas en tiempo real. Menos preciso que `@Docs` para documentación técnica profunda.


---

## Paso 5: Learning loop — aprender de revisiones de PR

Cada vez que un PR se mergea con comentarios de revisión, ejecutar:

```bash
# Analizar comentarios del PR y extraer patrones
./scripts/learn-from-pr.sh <PR_NUMBER>

# Ver qué aprendería sin escribir nada
./scripts/learn-from-pr.sh --dry-run <PR_NUMBER>

# Analizar el último PR mergeado
./scripts/learn-from-pr.sh --last-merged
```

Los patrones detectados se añaden a `lessons/learned-patterns.md`.

**Flujo completo:**

```
PR mergeado → learn-from-pr.sh → learned-patterns.md
                                        ↓
                            Revisar manualmente
                                        ↓
                    ¿Requiere actualizar rules?
                    ├── Sí → editar rules/ o security/
                    ├── Sí → añadir detector en rulesets/
                    └── Sí → añadir test en tests/unit/
```

Para automatizar via CI, añadir a `.github/workflows/` o `.github/workflows/ci.yml`:

```yaml
# GitHub Actions — ejecutar automáticamente en cada PR mergeado
on:
  pull_request:
    types: [closed]
jobs:
  learn:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Extract governance patterns
        run: ./scripts/learn-from-pr.sh ${{ github.event.pull_request.number }}
      - name: Commit learned patterns
        run: |
          git config user.name "governance-bot"
          git config user.email "governance@iagt.com"
          git add lessons/learned-patterns.md
          git diff --staged --quiet || git commit -m "governance: learned patterns from PR #${{ github.event.pull_request.number }}"
          git push
```

---

## Notas sobre portabilidad

### Windows

Los scripts detectan Windows (Git Bash/WSL) y mantienen el mismo flujo con `cursor-governance apply`.

### Resultado esperado

`cursor-governance apply` regenera `.cursor/rules/governance-stack.mdc` de forma consistente en cualquier plataforma.

---

## Verificación de que Cursor indexa correctamente

Después del setup, verifica en Cursor:

1. Abre el chat
2. Pregunta: "Lista los commands disponibles del stack PrestaShop"
3. Debe responder con: review, security-check, multishop-check, etc.

Si no responde correctamente:
1. Ve a Settings → Indexing & Docs
2. Haz clic en "Sync"
3. Espera a que termine
4. Prueba de nuevo

---

Última revisión: 2026-02-23

# Governance & Workflow

> **Módulo:** PrestaShop 8 Technical Handbook v3.0  
> **Última actualización:** 13 de febrero de 2026

---

## 1. Flujo de Desarrollo

### 1.1 Flujo Obligatorio

```
[Cursor/Dev] → feature/branch → PR → Review humano → Pipeline → main
```

### 1.2 Nunca permitido

| ❌ Prohibido | Motivo |
|-------------|--------|
| Push directo a `main` | Sin review ni pipeline |
| Merge sin PR aprobado | Salta controles |
| Merge con pipeline fallido | Código no verificado |
| PR sin ejecutar `/review` | Sin validación Cursor |

---

## 2. Branches

### 2.1 Naming Convention

| Tipo | Formato | Ejemplo |
|------|---------|---------|
| Feature | `feature/TICKET-descripcion` | `feature/TICKET-123-sap-stock-sync` |
| Bugfix | `bugfix/TICKET-descripcion` | `bugfix/TICKET-456-csrf-validation` |
| Hotfix | `hotfix/TICKET-descripcion` | `hotfix/TICKET-789-critical-order-fix` |

### 2.2 Reglas de branches

- `main` — Producción. Solo merge via PR aprobado + pipeline verde.
- `develop` (si existe) — Integración. PRs desde feature branches.
- `feature/*` — Desarrollo de funcionalidades.
- `bugfix/*` — Corrección de bugs no críticos.
- `hotfix/*` — Correcciones urgentes de producción.

---

## 3. Pull Requests

Checklist completo y template de PR en [`pr-checklist.md`](../pr-checklist.md).

---

## 4. CI/CD Pipeline

### 4.1 Pipeline Mínimo Requerido

| Stage | Herramienta | Acción |
|-------|-------------|--------|
| Lint | PHP_CodeSniffer | Verificar PSR-12 |
| Analysis | SonarQube | Bugs, vulnerabilidades, code smells |
| Security | SonarQube + custom | Security scan básico |
| Test | PHPUnit (si existe) | Tests unitarios |

### 4.2 Configuración SonarQube

```properties
# sonar-project.properties
sonar.projectKey=cursor-governance-prestashop8
sonar.projectName=Cursor Governance PrestaShop 8

# Solo código propio
sonar.sources=modules/vendor_*,themes/vendor_*,override

# Exclusiones
sonar.exclusions=**/vendor/**,**/node_modules/**,**/*.min.js,**/*.min.css,**/mails/**
```

### 4.3 Reglas de bloqueo

| Condición | Acción |
|-----------|--------|
| Lint PHP falla | ❌ Bloquear merge |
| SonarQube: bugs nuevos | ❌ Bloquear merge |
| SonarQube: vulnerabilidades nuevas | ❌ Bloquear merge |
| SonarQube: code smells | ⚠️ Warning (no bloquea) |
| Tests fallan | ❌ Bloquear merge |

---

## 5. Cursor AI Governance

### 5.1 Documentación Autoritativa

La carga de contexto la gestiona el CLI via `cursor-governance apply`. El entrypoint `.cursor/rules/governance-stack.md` carga automáticamente:

| Documento | Cuándo |
|-----------|--------|
| `rules/prestashop-main-rule.md` | Siempre (via `@`) |
| `security/prestashop-security.md` | Siempre (via `@`) |
| Resto del catálogo | Bajo demanda según relevancia |

Jerarquía en caso de conflicto: `prestashop-security.md` prevalece sobre todo.

### 5.2 Comandos Obligatorios

```
/review           → Ejecutar SIEMPRE antes de crear PR
/security-check   → Si hay SQL, inputs, uploads o APIs externas
/multishop-check  → Si hay queries con datos persistentes
```

### 5.3 Restricciones de Cursor

| ❌ Cursor NO puede | ✅ Cursor SÍ puede |
|-------------------|-------------------|
| Push a `main` | Push a feature branches |
| Merge PRs | Crear PRs |
| Aprobar sin `/review` | Ejecutar comandos de review |
| Modificar core PS | Modificar `modules/vendor_*` |
| Crear overrides sin doc | Proponer override con documentación |


### 5.5 Plan Mode — obligatorio para features complejas

Para implementaciones que toquen múltiples capas (Service + Controller + DB + hook):

1. Activar Plan Mode (`Shift+Tab`)
2. El plan debe especificar explícitamente dónde va la lógica (Service Layer)
3. Revisar que el plan no incluye SQL en controllers ni lógica en hooks
4. Solo aprobar el plan si respeta la arquitectura del stack

Los planes se guardan en `.cursor/plans/` si se usa "Save to workspace".

### 5.4 Rules de Cursor

El contenido de las rules está en [`rules/prestashop-main-rule.md`](../rules/prestashop-main-rule.md).

El CLI genera el archivo activo en `.cursor/rules/` a partir de ese fuente. No editar la copia generada.

---

## Governance feedback loop

Este stack incorpora un bucle de feedback para transformar fallos reales en
mejoras de gobernanza **sin automatizar cambios**.

Flujo:

incident / audit / code review
↓
lesson creada (`lessons/<domain>/...`)
↓
lesson revisada por maintainers
↓
posible mejora de checklist o skill (vía PR y validación humana)

### Cuándo añadir una nueva rule — "Rule of Three"

No añadir una rule la primera vez que el agente comete un error. Añadirla
**solo si el agente falla el mismo patrón tres veces** en sesiones distintas.

Señales de que una rule es necesaria:
- El agente repite el mismo anti-patrón en PRs distintos
- `learn-from-pr.sh` detecta el mismo patrón en ≥3 PRs
- El equipo corrige lo mismo manualmente en code review de forma recurrente

Señales de que una rule NO es necesaria todavía:
- Ocurrió una sola vez
- Es un error puntual de contexto, no de patrón
- Ya está cubierto por una rule existente con distinta formulación

### Auditoría periódica de rules

Frecuencia recomendada: mensual o tras ≥10 PRs mergeados.

Revisar `governance-stack.mdc`, `governance-security.mdc` y `governance-modules.mdc`:

1. **Rules ignoradas** — Si el agente incumple una rule de forma consistente,
   la rule es demasiado vaga o entra en conflicto con otra. Reescribir o eliminar.
2. **Rules obsoletas** — Si una rule lleva 3 meses sin triggear ningún hallazgo
   en `/review`, evaluar si sigue siendo necesaria.
3. **Rules duplicadas** — Si dos rules cubren el mismo patrón con distinta
   formulación, consolidarlas. El token tax de rules redundantes es real.
4. **Regla de tamaño** — Mantener cada `.mdc` bajo 500 líneas. Si crece,
   dividir en rules más específicas con globs más precisos.

```bash
# Ver cuántas líneas tiene cada rule actualmente
wc -l .cursor/rules/*.mdc
```

---

## 6. Override Policy

### 6.1 Regla General

> 🔴 **Overrides PROHIBIDOS por defecto.**

### 6.2 Excepciones permitidas

Solo si se cumple TODO:

1. ✅ No existe hook alternativo
2. ✅ Bug de core requiere workaround
3. ✅ Documentado en `docs/overrides/[ClassName]-[Method].md`
4. ✅ Aprobado por Tech Lead (fecha + firma)
5. ✅ Review cada 6 meses

### 6.3 Template de excepción

```markdown
# Override: [ClassName]::[methodName]

## Fecha aprobación
YYYY-MM-DD

## Aprobado por
[Nombre Tech Lead]

## Motivo
[Por qué no hay alternativa]

## Riesgo
[Qué puede romperse en updates]

## Código mínimo
[Solo lo imprescindible]

## Próxima revisión
YYYY-MM-DD (6 meses)
```

### 6.4 Governance SonarQube + Override

> ⚠️ Si existe código en `override/` sin documentación en `docs/overrides/`, es **violación de governance**.

SonarQube analiza `override/`. El revisor debe verificar que cada override tiene su documentación.

---

## 7. Hotfix Process

### 7.1 Cuándo usar hotfix

- Producción caída
- Vulnerabilidad de seguridad activa
- Error crítico afectando ventas/pedidos

### 7.2 Proceso acelerado

| Paso | Acción | Tiempo máx |
|------|--------|------------|
| 1 | Crear branch `hotfix/TICKET-descripcion` | 5 min |
| 2 | Implementar cambio MÍNIMO | Variable |
| 3 | `/review` + `/security-check` | 10 min |
| 4 | PR con 1 aprobación (no 2) | 15 min |
| 5 | Pipeline verde | Variable |
| 6 | Merge + deploy | 5 min |
| 7 | Documentar en post-mortem | 24h |

### 7.3 Template post-mortem

```markdown
# Post-mortem: Hotfix TICKET-XXX

## Fecha incidente
YYYY-MM-DD HH:MM

## Duración
[Tiempo de afectación]

## Impacto
[Qué se vio afectado]

## Causa raíz
[Por qué ocurrió]

## Solución aplicada
[Qué se hizo]

## Acciones preventivas
[Cómo evitarlo en futuro]
```

---

## 8. Entorno de Desarrollo

### 8.1 Configuración

| Aspecto | Valor |
|---------|-------|
| Estructura | Monorepo |
| Plataforma | Bitbucket + Git |
| CI/CD | GitHub Actions |
| Orquestación | Docker Compose |
| IDE | Cursor (con rules configuradas) |

### 8.2 Contenedores Docker

| Contenedor | Propósito |
|------------|-----------|
| `[APP_CONTAINER]` | PrestaShop 8 application |
| `[MYSQL_CONTAINER]` | Base de datos MySQL |
| `[REDIS_CONTAINER]` | Cache/Sessions (si aplica) |

### 8.3 Comandos útiles

```bash
# Limpiar cache
docker exec [APP_CONTAINER] rm -rf var/cache/prod
docker exec [APP_CONTAINER] rm -rf var/cache/dev

# Limpiar cache traducciones
docker exec [APP_CONTAINER] rm -rf var/cache/prod/translations
docker exec [APP_CONTAINER] rm -rf var/cache/dev/translations

# Regenerar assets
docker exec [APP_CONTAINER] php bin/console prestashop:update:config-files

# Logs
docker logs [APP_CONTAINER] -f
```

---

## 9. Métricas de Calidad

### 9.1 SonarQube Gates

| Métrica | Umbral | Acción |
|---------|--------|--------|
| Bugs nuevos | 0 | Bloquear |
| Vulnerabilidades nuevas | 0 | Bloquear |
| Code smells nuevos | < 10 | Warning |
| Coverage (si hay tests) | > 60% | Warning |
| Duplicación | < 5% | Warning |

### 9.2 Revisión periódica

| Frecuencia | Acción |
|------------|--------|
| Semanal | Review dashboard SonarQube |
| Mensual | Review de overrides pendientes |
| Trimestral | Auditoría de seguridad completa |
| Semestral | Review de excepciones de override |

---

## Referencias

- [`pr-checklist.md`](../pr-checklist.md) — Checklist y template de PR
- [`rules/prestashop-main-rule.md`](../rules/prestashop-main-rule.md) — Rules activas de Cursor
- [`coding-conventions.md`](../conventions/coding-conventions.md) — Naming, estilo
- [`security/prestashop-security.md`](../security/prestashop-security.md) — Seguridad
- [`multishop/multishop-data-model.md`](../multishop/multishop-data-model.md) — Contextos de tienda

---

*Parte del PrestaShop 8 Technical Handbook v3.0*
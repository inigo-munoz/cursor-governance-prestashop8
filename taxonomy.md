# TAXONOMY — Clasificación de Reglas

Este documento define qué es **obligatorio**, qué es **recomendado** y qué es **patrón opcional** en el stack PrestaShop del equipo.

---

## Niveles de obligatoriedad

| Nivel | Significado | Consecuencia de violar |
|-------|-------------|------------------------|
| 🔴 **OBLIGATORIO** | No negociable. Sin excepciones salvo proceso formal. | Bloquea PR. No va a producción. |
| 🟡 **RECOMENDADO** | Debe seguirse salvo justificación técnica documentada. | Genera deuda técnica si se ignora. |
| 🟢 **PATRÓN** | Buena práctica. Seguir cuando aplique. | No bloquea, pero mejora calidad. |

---

## Seguridad — 🔴 OBLIGATORIO

Todo lo que está en `security/prestashop-security.md` es obligatorio sin excepción.

| Regla | Nivel |
|-------|-------|
| Cast `(int)` para enteros en SQL | 🔴 |
| `pSQL()` para strings en SQL | 🔴 |
| Escape de wildcards en LIKE | 🔴 |
| No raw `$_POST` / `$_GET` | 🔴 |
| `hash_equals()` para tokens | 🔴 |
| AJAX solo POST para escritura | 🔴 |
| Validación MIME real en uploads | 🔴 |
| No log de datos sensibles | 🔴 |

**Violación = 🔴 Bloqueante en revisión.**

---

## Arquitectura — 🔴 OBLIGATORIO (con matices)

| Regla | Nivel | Nota |
|-------|-------|------|
| Service Layer para lógica de negocio | 🔴 | Nunca lógica en hooks/controllers |
| Prefijo `Iagt` en clases custom | 🔴 | Sin excepciones |
| No overrides si existe hook | 🔴 | Excepción requiere documentación |
| Filtrar `id_shop` en queries | 🔴 | Excepto CONTEXT_ALL justificado |

---

## Multishop — 🔴 OBLIGATORIO

| Regla | Nivel |
|-------|-------|
| Toda query filtra `id_shop` | 🔴 |
| Verificar contexto antes de `getContextShopID()` | 🔴 |
| Tablas con columna `id_shop` + índice | 🔴 |
| No asumir single-shop | 🔴 |

---

## Patrones Enterprise — 🟡 RECOMENDADO

Aplican cuando el contexto lo requiere (concurrencia, integraciones, etc.):

| Patrón | Nivel | Cuándo aplica |
|--------|-------|---------------|
| Distributed Locking (Redis) | 🟡 | Stock, checkout, cron críticos |
| Idempotency en integraciones | 🟡 | APIs externas (SAP, ERPs) |
| Rate-limited logging | 🟡 | Integraciones con volumen |
| Schema validation en APIs | 🟡 | Respuestas externas |
| Circuit breaker | 🟢 | Integraciones inestables |

Si el proyecto tiene **concurrencia alta** o **integraciones críticas**, estos patrones pasan a ser 🔴.

---

## Convenciones — 🟡 RECOMENDADO

| Convención | Nivel |
|------------|-------|
| Naming en `coding-conventions.md` | 🟡 |
| Estructura de carpetas estándar | 🟡 |
| Comentarios en español | 🟡 |
| Formato de commits | 🟢 |

---

## Workflow — 🟡 RECOMENDADO

| Proceso | Nivel |
|---------|-------|
| Ejecutar `/review` antes de PR | 🟡 → 🔴 si hay CI |
| Ejecutar `/security-check` si hay SQL/inputs | 🔴 |
| Documentar excepciones | 🔴 |
| Code review humano | 🟡 |

---

## Cómo usar esta taxonomía

### En revisiones de código

```
🔴 Violación obligatoria → Bloquea PR
🟡 Violación recomendada → Comentario, no bloquea (salvo acumulación)
🟢 Violación de patrón → Sugerencia
```

### En discusiones técnicas

Si alguien dice "pero funciona", responde:
- Si es 🔴 → "No importa. Es obligatorio."
- Si es 🟡 → "Documenta por qué no aplica."
- Si es 🟢 → "Ok, pero considera aplicarlo."

### En onboarding

Nuevo desarrollador debe conocer:
1. Todo lo 🔴 (primera semana)
2. Lo 🟡 relevante a su proyecto (primer mes)
3. Lo 🟢 cuando surja

---

## Resumen ejecutivo

| Categoría | Nivel por defecto |
|-----------|-------------------|
| Seguridad | 🔴 Todo |
| Arquitectura core | 🔴 Todo |
| Multishop | 🔴 Todo |
| Patrones enterprise | 🟡 Según contexto |
| Convenciones | 🟡 |
| Workflow | 🟡 (algunos 🔴) |

---

## Actualización

Este documento debe actualizarse cuando:
- Se añade nueva regla al stack
- Se cambia nivel de obligatoriedad
- Se depreca alguna regla

Última revisión: 2026-02-23

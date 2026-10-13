# PR CHECKLIST — Verificación antes de Merge

Este checklist es **obligatorio** antes de crear un Pull Request.

---

## Instrucciones

1. Copia este checklist en la descripción del PR
2. Marca cada item que aplique
3. Si un item no aplica, márcalo con N/A
4. Si hay items 🔴 sin marcar → el PR no puede mergearse

---

## Checklist

### 🔴 Seguridad (obligatorio si hay código)

```
[ ] Enteros en SQL usan cast (int)
[ ] Strings en SQL usan pSQL()
[ ] Wildcards en LIKE están escapados
[ ] No hay $_POST/$_GET directos (uso Tools::getValue())
[ ] Tokens se comparan con hash_equals()
[ ] AJAX con escritura usa POST (no GET)
[ ] Uploads validan MIME real (si aplica)
[ ] No hay log de datos sensibles
```

### 🔴 Arquitectura (obligatorio)

```
[ ] Lógica de negocio está en Service Layer
[ ] No hay lógica en hooks/controllers (solo orquestación)
[ ] Clases custom usan prefijo Acme
[ ] No hay overrides (o tienen excepción documentada)
```

### 🔴 Multishop (obligatorio si hay queries)

```
[ ] Queries filtran id_shop correctamente
[ ] CONTEXT_ALL está justificado (si se usa)
[ ] Tablas nuevas tienen columna id_shop + índice
```

### 🟡 Commands ejecutados

```
[ ] Ejecuté /review
[ ] Ejecuté /security-check (si hay SQL/inputs/uploads/APIs)
[ ] Ejecuté /multishop-check (si hay queries con datos persistentes)
[ ] Ejecuté /servicelayer-review (si hay lógica de negocio nueva)
[ ] Ejecuté /api-hardening (si hay integraciones externas)
[ ] Ejecuté /high-concurrency-check (si hay stock/checkout/cron)
```

### 🟡 Calidad

```
[ ] El código compila/funciona en local
[ ] He probado el flujo completo manualmente
[ ] Los nombres siguen coding-conventions.md
[ ] Los comentarios están en español
```

### 🟡 Documentación

```
[ ] README actualizado (si hay cambios de uso)
[ ] Excepciones documentadas (si las hay)
[ ] CHANGELOG actualizado (si es release)
```

---

## Resultado de Commands

Pega aquí el resultado de los commands ejecutados:

```
/review:
[Pegar resultado]

/security-check (si aplica):
[Pegar resultado]

/multishop-check (si aplica):
[Pegar resultado]
```

---

## Excepciones

Si hay reglas que no se cumplen con excepción aprobada:

| Regla | ID Excepción | Aprobador |
|-------|--------------|-----------|
| [regla] | EXCEPTION-YYYY-MM-DD-xxx | [nombre] |

---

## Declaración

```
[ ] Confirmo que he revisado este checklist honestamente
[ ] Entiendo que violaciones no documentadas bloquean el merge
```

---

## Para el Reviewer

Antes de aprobar, verificar:

1. ¿El checklist está completo?
2. ¿Los commands no muestran 🔴?
3. ¿Las excepciones están documentadas?
4. ¿El código cumple lo que dice el checklist?

Si hay dudas → pedir aclaración antes de aprobar.

---

## Notas

- Este checklist no sustituye el code review humano
- Si un item no está claro → preguntar antes de marcar
- Si hay urgencia → documentar por qué y quién aprobó saltarse el proceso

Última revisión: 2026-02-23

# EXCEPTIONS — Proceso de Excepciones

Este documento define cómo solicitar, documentar y gestionar excepciones a las reglas del stack.

---

## Principio fundamental

> Las reglas existen por una razón.
> Las excepciones deben ser **excepcionales**, no la norma.

Si te encuentras pidiendo excepciones frecuentemente, el problema no son las reglas.

---

## ¿Qué requiere excepción formal?

| Tipo de violación | Requiere excepción formal |
|-------------------|---------------------------|
| Regla 🔴 OBLIGATORIA | ✅ Sí, siempre |
| Regla 🟡 RECOMENDADA | Solo si es recurrente o estructural |
| Patrón 🟢 OPCIONAL | No requiere excepción |

---

## Proceso de excepción

### Paso 1: Evaluar alternativas

Antes de pedir excepción:

1. ¿Realmente no hay forma de cumplir la regla?
2. ¿Has consultado con el Tech Lead?
3. ¿El coste de cumplir es mayor que el riesgo de no cumplir?

Si la respuesta a las 3 es SÍ → continúa.

### Paso 2: Documentar la solicitud

Crear archivo en el proyecto:

```
docs/exceptions/EXCEPTION-{YYYY-MM-DD}-{descripcion-corta}.md
```

Con este contenido:

```markdown
# Excepción: [Descripción corta]

## Regla afectada
[Nombre de la regla y documento donde está definida]

## Contexto
[Por qué surge la necesidad]

## Justificación técnica
[Por qué no se puede cumplir la regla]

## Alternativas evaluadas
[Qué otras opciones se consideraron y por qué se descartaron]

## Riesgo asumido
[Qué puede salir mal por no cumplir la regla]

## Mitigación
[Qué se hará para reducir el riesgo]

## Alcance
- Proyecto: [nombre]
- Módulo: [nombre]
- Fecha límite: [si es temporal]

## Aprobación
- Solicitante: [nombre]
- Fecha solicitud: [fecha]
- Aprobador: [Tech Lead]
- Fecha aprobación: [fecha]
- Estado: [Pendiente/Aprobada/Rechazada]
```

### Paso 3: Obtener aprobación

| Tipo de excepción | Aprobador |
|-------------------|-----------|
| Seguridad 🔴 | Tech Lead + Arquitecto |
| Arquitectura 🔴 | Tech Lead |
| Otras 🔴 | Tech Lead |

**Sin aprobación documentada = No hay excepción.**

### Paso 4: Marcar en el código

Donde aplique la excepción:

```php
/**
 * EXCEPCIÓN DOCUMENTADA: EXCEPTION-2026-02-23-endpoint-get-legacy
 * Razón: Compatibilidad con cliente legacy que no soporta POST
 * Aprobado por: [Tech Lead] el [fecha]
 * Válido hasta: [fecha o "indefinido"]
 */
public function handleLegacyGet()
{
    // código que viola la regla
}
```

### Paso 5: Revisar periódicamente

Las excepciones temporales deben revisarse en su fecha límite.
Las excepciones permanentes deben revisarse anualmente.

---

## Registro de excepciones

Cada proyecto debe mantener un índice en:

```
docs/exceptions/INDEX.md
```

Con formato:

```markdown
# Índice de Excepciones

| ID | Regla | Estado | Fecha | Válido hasta |
|----|-------|--------|-------|--------------|
| EXCEPTION-2026-02-23-xxx | AJAX GET | Aprobada | 2026-02-23 | 2026-06-01 |
| EXCEPTION-2026-02-20-yyy | Override | Aprobada | 2026-02-20 | Indefinido |
```

---

## Excepciones prohibidas

Algunas reglas **NO admiten excepción** bajo ninguna circunstancia:

| Regla | Por qué no admite excepción |
|-------|-----------------------------|
| SQL sin sanitizar | Riesgo de seguridad crítico |
| Log de contraseñas/tokens | Riesgo de seguridad crítico |
| Raw `$_POST`/`$_GET` | Riesgo de seguridad crítico |

Si alguien pide excepción a estas → la respuesta es **NO**.

---

## Qué NO es una excepción válida

❌ "El cliente lo quiere así"
❌ "No tenemos tiempo"
❌ "Funciona en local"
❌ "Siempre lo hemos hecho así"
❌ "Es solo temporal" (sin fecha límite)

---

## Qué SÍ es una excepción válida

✅ "El sistema legacy del cliente no soporta POST y no podemos cambiarlo"
✅ "PrestaShop no expone hook para este caso específico"
✅ "El volumen de datos hace inviable el patrón estándar"

---

## Consecuencias de no documentar

Si se detecta violación de regla 🔴 sin excepción documentada:

1. **Primera vez:** Se documenta retroactivamente + warning
2. **Segunda vez:** Bloqueo de PR hasta documentar
3. **Patrón recurrente:** Revisión con Tech Lead

---

## Revisión de este proceso

Este proceso puede mejorarse. Si encuentras fricciones:

1. Documenta el problema
2. Propón mejora
3. Discute con Tech Lead
4. Si se aprueba → actualiza este documento

Última revisión: 2026-02-23

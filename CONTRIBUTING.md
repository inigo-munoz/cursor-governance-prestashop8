# CONTRIBUTING — Cómo Contribuir al Stack

Este documento define cómo proponer cambios, mejoras o correcciones al repositorio de gobernanza PrestaShop.

---

## Principio

> Este repositorio es normativo, no experimental.
> Los cambios deben ser deliberados, no impulsivos.

---

## ¿Quién puede contribuir?

| Rol | Puede proponer | Puede aprobar |
|-----|----------------|---------------|
| Desarrollador | ✅ | ❌ |
| Senior Developer | ✅ | ❌ |
| Tech Lead | ✅ | ✅ (su área) |
| Arquitecto | ✅ | ✅ (todo) |

---

## Tipos de contribución

### 1. Corrección de errores

- Typos, links rotos, ejemplos incorrectos
- Proceso: PR directo con descripción clara
- Aprobación: Tech Lead

### 2. Clarificación

- Mejorar redacción sin cambiar significado
- Añadir ejemplos a reglas existentes
- Proceso: PR con justificación
- Aprobación: Tech Lead

### 3. Nueva regla o restricción

- Añadir regla a `prestashop-main-rule.md`
- Añadir criterio a un command
- Proceso: RFC (ver abajo)
- Aprobación: Tech Lead + Arquitecto

### 4. Nuevo command

- Crear command especializado
- Proceso: RFC + implementación según template
- Aprobación: Tech Lead + Arquitecto

### 5. Cambio estructural

- Modificar taxonomía
- Cambiar estructura de carpetas
- Modificar proceso de workflow
- Proceso: RFC formal + período de revisión
- Aprobación: Arquitecto

---

## Proceso RFC (Request for Comments)

Para cambios significativos (tipos 3, 4, 5):

### Paso 1: Crear RFC

Archivo: `rfcs/RFC-{YYYY-MM-DD}-{titulo}.md`

```markdown
# RFC: [Título]

## Resumen
[1-2 párrafos explicando el cambio]

## Motivación
[Por qué es necesario este cambio]

## Propuesta detallada
[Qué se cambia exactamente]

## Impacto
- Documentos afectados: [lista]
- Proyectos afectados: [estimación]
- Esfuerzo de migración: [bajo/medio/alto]

## Alternativas consideradas
[Qué otras opciones se evaluaron]

## Plan de implementación
[Cómo se haría el cambio]

## Autor
[Nombre y fecha]
```

### Paso 2: Revisión

- Mínimo 1 semana de revisión para cambios estructurales
- Comentarios en el PR del RFC
- Discusión en reunión técnica si es necesario

### Paso 3: Decisión

| Decisión | Siguiente paso |
|----------|----------------|
| Aprobado | Implementar según plan |
| Aprobado con cambios | Modificar RFC, luego implementar |
| Rechazado | Documentar razón, cerrar RFC |
| Diferido | Revisar en fecha acordada |

### Paso 4: Implementación

- PR separado con la implementación
- Referencia al RFC aprobado
- Actualizar CHANGELOG

---

## Formato de commits

```
tipo(área): descripción corta

[cuerpo opcional]

[referencias opcionales]
```

Tipos:
- `fix`: Corrección de error
- `docs`: Cambio de documentación
- `feat`: Nueva funcionalidad/regla
- `refactor`: Reestructuración sin cambio funcional
- `chore`: Mantenimiento

Ejemplos:
```
fix(security): corregir ejemplo de pSQL en rule principal
docs(commands): añadir ejemplo de uso en multishop-check
feat(commands): añadir command /performance-check
```

---

## Proceso de PR

### 1. Crear branch

```
git checkout -b tipo/descripcion-corta
```

Ejemplos:
- `fix/typo-security-doc`
- `feat/new-command-cache-check`
- `docs/clarify-service-layer`

### 2. Hacer cambios

- Seguir el formato de los documentos existentes
- Mantener consistencia de estilo
- Actualizar documentos relacionados

### 3. Crear PR

- Título descriptivo
- Descripción con contexto
- Referencias a issues/RFCs si aplica

### 4. Revisión

- Esperar aprobación según tipo de cambio
- Responder comentarios
- Hacer ajustes si se solicitan

### 5. Merge

- Solo después de aprobación
- Actualizar CHANGELOG si aplica
- Notificar a equipos si es cambio relevante

---

## Qué NO contribuir

❌ Reglas específicas de un proyecto (van en el proyecto)
❌ Código de módulos (esto es solo gobernanza)
❌ Cambios no consensuados
❌ "Mejoras" que reducen seguridad
❌ Cambios que contradicen el Core

---

## Comunicación

- **Dudas menores:** Slack del equipo
- **Propuestas:** RFC en este repo
- **Discusiones técnicas:** Reunión semanal
- **Urgencias:** Tech Lead directamente

---

## Ownership

| Área | Owner |
|------|-------|
| `rules/` | Tech Lead |
| `security/` | Tech Lead + Security |
| `commands/` | Tech Lead |
| `patterns/` | Arquitecto |
| `workflow/` | Tech Lead |
| Resto | Tech Lead |

---

## Historial de cambios

Todo cambio debe reflejarse en `CHANGELOG.md`.

Última revisión: 2026-02-23

---
name: sdd-tasks
description: Genera el plan de tareas ordenado para implementar el cambio  Crea tasks.md con bloques de trabajo concretos y dependencias claras.
---

# SDD — Tasks

Eres el agente de planificación. Conviertes la spec en tareas concretas e implementables.

## Recibe del orquestador

- Nombre del cambio: `{change-name}`

## Pasos

### 1. Leer artefactos

Leer:
- `.cursor/plans/{change-name}/proposal.md`
- `.cursor/plans/{change-name}/spec.md`

Si falta spec.md: "Ejecuta `/sdd:spec {change-name}` primero."

### 2. Descomponer en bloques

Organizar en bloques con dependencias explícitas.
Cada tarea debe ser implementable en menos de 1 hora.

### 3. Crear artefacto

Guardar en `.cursor/plans/{change-name}/tasks.md`:

```markdown
# Tareas: {change-name}
Generado: {fecha}

## Bloque 1 — Infraestructura DB
*Sin dependencias — empezar aquí*

- [ ] T01: Añadir tabla `vendor_{nombre}` en `install()` del módulo
- [ ] T02: Añadir `dropTable` en `uninstall()`
- [ ] T03: Crear índices en `install()`

## Bloque 2 — Service Layer
*Requiere: Bloque 1*

- [ ] T04: Crear `classes/AcmeNombreService.php` con constructor
- [ ] T05: Implementar `getNombre(int $idShop, int $idLang)`
- [ ] T06: Implementar `createNombre(array $data, int $idShop)`
- [ ] T07: Implementar `updateNombre(int $id, array $data, int $idShop)`

## Bloque 3 — Integración en módulo
*Requiere: Bloque 2*

- [ ] T08: Registrar hook `hookNombre` en `vendor_modulo.php`
- [ ] T09: Implementar `hookNombre()` — solo orquestación, llama al Service
- [ ] T10: Registrar hook en `install()`

## Bloque 4 — AJAX (si aplica)
*Requiere: Bloque 2*

- [ ] T11: Crear `controllers/front/endpointajax.php`
- [ ] T12: Validar token CSRF y permisos
- [ ] T13: Delegar lógica al Service

## Bloque 5 — Validación governance
*Requiere: todos los bloques anteriores*

- [ ] T14: `/review` — sin hallazgos 🔴
- [ ] T15: `/security-check` — sin hallazgos 🔴
- [ ] T16: `/multishop-check` — si aplica
- [ ] T17: `/servicelayer-review` — si aplica
```

### 4. Output

```
## Tareas creadas: .cursor/plans/{change-name}/tasks.md

{N} tareas en {M} bloques
Tiempo estimado: ~{estimación} horas

¿Empezamos la implementación? (`/sdd:apply {change-name}`)
O si quieres revisar las tareas primero, dime qué ajustar.
```

## SDD — Orquestador

Cuando el developer use comandos `/sdd:*`, actúas como coordinador SDD.

### Reglas del orquestador

1. **Nunca hagas trabajo de fase directamente** — lee la skill correspondiente y sigue sus instrucciones
2. **Contexto mínimo** — referencia rutas de archivo, no su contenido
3. **Una fase a la vez** — muestra el resultado, pide aprobación antes de continuar
4. **Si hay ambigüedad** — para y pregunta antes de asumir

### Comandos SDD disponibles

| Comando | Skill | Cuándo |
|---------|-------|--------|
| `/sdd:init` | sdd-init | Al empezar en un proyecto |
| `/sdd:explore <tema>` | sdd-explore | Antes de comprometerse |
| `/sdd:new <nombre>` | sdd-propose | Iniciar un cambio nuevo |
| `/sdd:continue [nombre]` | siguiente fase pendiente | Continuar donde lo dejé |
| `/sdd:apply [nombre]` | sdd-apply | Implementar |
| `/sdd:verify [nombre]` | sdd-verify | Validar antes del PR |
| `/sdd:archive [nombre]` | sdd-archive | Cerrar cambio verificado |

### Flujo normal

```
/sdd:init
  → /sdd:explore <tema>     (opcional — para ideas complejas)
  → /sdd:new <nombre>       (propuesta + aprobación)
  → /sdd:continue           (spec → tareas → apply → verify)
  → /sdd:archive
```

### Para `/sdd:continue`

Detecta automáticamente cuál es la siguiente fase:
- Si existe `proposal.md` pero no `spec.md` → ejecutar sdd-spec
- Si existe `spec.md` pero no `tasks.md` → ejecutar sdd-tasks
- Si existe `tasks.md` con tareas `[ ]` → ejecutar sdd-apply
- Si todas las tareas son `[x]` → sugerir sdd-verify

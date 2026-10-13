---
name: sdd-explore
description: Investiga el codebase antes de comprometerse con un cambio. Analiza el estado actual, detecta riesgos y superficia ambigüedades. NO crea archivos. Usar para pensar antes de actuar.
---

# SDD — Explore

Eres el agente explorador. Tu trabajo es **entender antes de proponer**.
No creas ningún archivo. Solo analizas y reportas.

## Recibe del orquestador

- Tema o idea a explorar (texto libre del developer)

## Pasos

### 1. Cargar skill registry

Leer `.cursor/plans/skill-registry.md` si existe.
Si no existe: sugerir ejecutar `/sdd:init`.

### 2. Preguntas de clarificación (si hay ambigüedad)

Si el tema es vago o tiene múltiples interpretaciones posibles, haz **máximo 3 preguntas** antes de explorar:

```
Para explorar bien esto necesito entender:

1. [pregunta sobre alcance o restricción concreta]
2. [pregunta sobre integración con sistemas existentes si aplica]
3. [pregunta sobre qué queda fuera si el scope no está claro]

Responde lo que puedas — más contexto = análisis más preciso.
Si ya tienes todo claro, simplemente di "adelante".
```

Si el tema es claro y concreto, salta directamente al análisis.

### 3. Analizar el codebase

Busca e inspecciona:

**Módulos relacionados:**
- `modules/vendor_*/` — buscar módulos relevantes al tema
- Leer `install()` y hooks registrados de los relevantes

**Services existentes:**
- `classes/Acme*Service.php` — qué servicios existen
- Qué métodos públicos tienen los relacionados

**Tablas de DB:**
- Buscar `Db::getInstance()` en módulos relacionados
- ¿Tienen `id_shop` en sus queries?

**Hooks activos:**
- ¿Qué hooks usa el área relacionada?
- ¿Hay overrides que deberían ser hooks?

**Riesgos detectados:**
- Código legacy sin Service Layer
- Queries sin `id_shop`
- Lógica en hooks que debería estar en services
- Dependencias con SAP, Redis, APIs externas

### 4. Output (sin crear archivos)

```
## Exploración: {tema}

### Estado actual del codebase

**Módulos relacionados:**
- `vendor_nombre` — [qué hace, relevante porque...]

**Services disponibles:**
- `AcmeNombreService` — métodos: [lista]
- *Necesario crear*: [si no existe el service relevante]

**Estado multishop:**
✅ Queries con id_shop / ⚠️ Queries sin id_shop en [archivos]

**Riesgos detectados:**
- [lista de riesgos concretos con localización]

### Enfoques posibles

**Opción A** — [descripción breve]
Pros: / Contras:

**Opción B** — [si hay alternativa real]
Pros: / Contras:

### Recomendación

[cuál opción y por qué, basado en las convenciones del proyecto]

---
*No se ha creado ningún archivo. Para empezar el cambio: `/sdd:new <nombre>`*
```

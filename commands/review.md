# /review

Revisión técnica completa para código PrestaShop 8.x 

Evalúa el código o diff aplicando la jerarquía: Seguridad > Arquitectura > Consistencia > Funcionalidad.

---

## 📌 CUÁNDO EJECUTAR

- Siempre antes de crear un PR
- Después de cambios significativos en un módulo
- Al revisar código de terceros o legacy
- Cuando se modifica lógica de negocio crítica

---

## 🔍 ESTRUCTURA DE ANÁLISIS

### 1. Seguridad (verificar siempre)

| Check | Criterio | Severidad | Acción |
|-------|----------|-----------|--------|
| SQL int | `(int)` cast en todos los enteros | 🔴 | → /security-check |
| SQL string | `pSQL()` en todos los strings | 🔴 | → /security-check |
| SQL LIKE | Wildcards escapados | 🔴 | → /security-check |
| SQL arrays | `array_map('intval', $arr)` | 🔴 | → /security-check |
| Inputs | `Tools::getValue()`, nunca raw `$_POST/$_GET` | 🔴 | → /security-check |
| CSRF | `hash_equals()` para tokens | 🔴 | → /security-check |
| AJAX | Solo POST para operaciones de escritura | 🔴 | → /security-check |
| Uploads | MIME real + `getimagesize()` si imagen | 🔴 | → /security-check |
| Logs | Sin datos sensibles (passwords, tokens) | 🔴 | → /security-check |

⚠️ Si detectas cualquier issue 🔴 en seguridad → ejecutar `/security-check`

---

### 2. Arquitectura

| Check | Criterio | Severidad | Acción |
|-------|----------|-----------|--------|
| Service Layer | Lógica de negocio en Services, NO en hooks/controllers | 🔴 | → /servicelayer-review |
| Prefijo | Clases custom con prefijo `Acme` | 🔴 | |
| Overrides | Prohibidos si existe hook viable | 🔴 | |
| Hooks | Solo orquestan, delegan en Services | 🟡 | → /servicelayer-review |
| Controllers | Solo coordinan flujo, sin lógica de negocio | 🟡 | → /servicelayer-review |

⚠️ Si detectas lógica en hooks/controllers → ejecutar `/servicelayer-review`

---

### 3. Multishop

| Check | Criterio | Severidad | Acción |
|-------|----------|-----------|--------|
| Queries | Filtrar `id_shop` en datos persistentes | 🔴 | → /multishop-check |
| Contexto | Verificar `Shop::getContext()` antes de `getContextShopID()` | 🟡 | → /multishop-check |
| CONTEXT_ALL | Decisión explícita documentada | 🟡 | → /multishop-check |
| Tablas | Incluir `id_shop` + índice | 🟡 | → /multishop-check |

⚠️ Si detectas queries sin filtro de tienda → ejecutar `/multishop-check`

---

### 4. Código y Mantenibilidad

| Check | Criterio | Severidad |
|-------|----------|-----------|
| `die()` | Prohibido en producción | 🔴 |
| Naming | Variables descriptivas en inglés, camelCase | 🟡 |
| Métodos | Longitud razonable, responsabilidad única | 🟡 |
| Duplicación | Evitar código duplicado | 🟡 |
| Comentarios | Documentar decisiones no obvias | 🟢 |

---

### 5. Integraciones Externas (si aplica)

| Check | Criterio | Severidad | Acción |
|-------|----------|-----------|--------|
| Timeout | Configurado explícitamente | 🔴 | → /api-hardening |
| Errores | Manejo de excepciones | 🔴 | → /api-hardening |
| Respuestas | Validar estructura/schema | 🟡 | → /api-hardening |
| Idempotencia | Operaciones repetibles sin efectos duplicados | 🟡 | → /api-hardening |

⚠️ Si detectas APIs externas → ejecutar `/api-hardening`

---

### 6. Concurrencia (si aplica)

| Check | Criterio | Severidad | Acción |
|-------|----------|-----------|--------|
| Stock | Locking en operaciones de stock | 🔴 | → /high-concurrency-check |
| Checkout | Protección race conditions | 🔴 | → /high-concurrency-check |
| Cron | Idempotencia en jobs | 🟡 | → /high-concurrency-check |

⚠️ Si detectas operaciones de stock/checkout → ejecutar `/high-concurrency-check`

---

## FORMATO DE RESPUESTA

🔴 Bloqueantes · 🟡 Riesgos · 🟢 Correcto · 💡 Recomendaciones

---

## RESTRICCIONES

- NO escribir código salvo solicitud explícita
- NO suavizar problemas 🔴 — si los hay, indicar que NO puede ir a producción
- Referenciar siempre la regla o documento aplicable
- Actuar en español

---

---


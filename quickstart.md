# QUICKSTART — Onboarding en 5 minutos

## ¿Qué es esto?

Este repositorio define **cómo debe escribirse código PrestaShop** en tu equipo.

No es opcional. No es sugerencia. Es el estándar técnico obligatorio.

---

## Lo mínimo que debes saber

### 0. Antes de escribir código — usa Plan Mode

Para cualquier feature nueva o refactor significativo, activa **Plan Mode** antes de escribir código:

1. Pulsa `Shift+Tab` en el input del agente para activar Plan Mode
2. Describe lo que quieres implementar
3. El agente investiga el codebase, hace preguntas y genera un plan con rutas de archivos
4. **Revisa el plan** — verifica que respeta Service Layer, multishop y las restricciones del stack
5. Aprueba el plan y deja que el agente ejecute

Esto es especialmente importante en PrestaShop porque el agente puede tender a poner lógica en hooks o controllers si no tiene un plan explícito que lo guíe.

---

### 1. Prioridad técnica (memorízala)

```
Seguridad > Estabilidad > Robustez > Arquitectura > Funcionalidad > Rapidez
```

Si tienes que elegir entre "funciona" y "es seguro", elige seguro.

---

### 2. Las 6 reglas que nunca puedes romper

| Regla | Qué significa |
|-------|---------------|
| **SQL seguro** | Enteros con `(int)`, strings con `pSQL()`, LIKE con wildcards escapados |
| **No raw superglobals** | Nunca `$_POST`, `$_GET`. Siempre `Tools::getValue()` |
| **CSRF con hash_equals** | Comparar tokens solo con `hash_equals()` |
| **AJAX solo POST** | Nunca GET con efectos de escritura |
| **Service Layer** | Lógica de negocio en Services, NO en hooks/controllers |
| **Multishop explícito** | Toda query debe filtrar `id_shop` |

---

### 3. Prefijo obligatorio

Todas las clases custom deben usar prefijo `Acme`:

```php
// ❌ Incorrecto
class OrderSyncService { }

// ✅ Correcto
class AcmeOrderSyncService { }
```

---

### 4. Antes de hacer PR

Ejecuta estos commands en orden:

```
1. /review          → Revisión general (siempre)
2. /security-check  → Si tocaste SQL, inputs, uploads o APIs
3. /multishop-check → Si tocaste queries con datos persistentes
```

Si `/review` indica 🔴 → **NO puede ir a producción**.

---

### 5. Dónde está todo

| Necesitas... | Ubicación |
|--------------|-----------|
| Reglas principales | `rules/prestashop-main-rule.md` |
| Seguridad detallada | `security/prestashop-security.md` |
| Cómo estructurar código | `patterns/prestashop-enterprise-hardened-v2.0.md` |
| Multishop | `multishop/multishop-data-model.md` |
| Commands disponibles | `commands/` |

---

### 6. Si tienes dudas

1. Lee `rules/prestashop-main-rule.md` (3 min)
2. Si no está claro → pregunta al Tech Lead
3. Si necesitas excepción → documéntala (ver `exceptions.md`)

---

## Checklist rápido antes de PR

```
[ ] ¿Usé (int) para enteros en SQL?
[ ] ¿Usé pSQL() para strings en SQL?
[ ] ¿Mi lógica está en un Service, no en hook/controller?
[ ] ¿Mis queries filtran id_shop?
[ ] ¿Mis clases tienen prefijo Acme?
[ ] ¿Ejecuté /review?
```

Si alguna respuesta es NO → corrige antes de PR.

---

## Tiempo estimado de lectura completa

| Documento | Tiempo | Prioridad |
|-----------|--------|-----------|
| Este quickstart | 5 min | 🔴 Obligatorio |
| `prestashop-main-rule.md` | 5 min | 🔴 Obligatorio |
| `prestashop-security.md` | 15 min | 🔴 Primera semana |
| `prestashop-enterprise-hardened-v2.0.md` | 20 min | 🟡 Primera semana |
| Resto de documentación | Variable | 🟢 Según necesidad |

---

## ¿Por qué existe esto?

Porque código inconsistente genera:
- Vulnerabilidades de seguridad
- Bugs en producción
- Deuda técnica acumulada
- Equipos que no pueden mantener código ajeno

Este sistema existe para que cualquier desarrollador pueda:
- Escribir código que otro pueda mantener
- Detectar problemas antes de producción
- No depender de "el que sabe"

---

**Bienvenido al stack PrestaShop del equipo.**

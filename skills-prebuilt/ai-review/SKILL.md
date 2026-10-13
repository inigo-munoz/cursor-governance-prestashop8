---
name: ai-review
description: PrestaShop comprehensive code review. Auto-invoke before PR creation, when user asks for /review or code review, or after significant changes to a module. Orchestrates security, multishop, and service layer checks. Applies hierarchy: Security > Architecture > Multishop compliance > Conventions > Functionality.
---

# AI Review — PrestaShop

Eres el revisor principal  Aplicas una revisión técnica completa siguiendo la jerarquía de prioridades del stack: Seguridad > Estabilidad > Robustez > Arquitectura > Funcionalidad.

## Cuándo actuar

- Cuando el developer pide `/review` o una revisión antes de PR
- Al finalizar una feature significativa (múltiples archivos modificados)
- Cuando detectas cambios que tocan lógica de negocio crítica

## Jerarquía de revisión

Aplica en este orden estricto. Un bloqueante 🔴 en cualquier área detiene la revisión de las siguientes hasta que se resuelva.

---

### 1. Seguridad — SIEMPRE primero

Revisa contra las 13 reglas de seguridad de la governance:

| Check | Criterio | Severidad |
|-------|----------|-----------|
| SQL integers | `(int)` cast en todos los enteros en SQL | 🔴 |
| SQL strings | `pSQL()` en todos los strings en SQL | 🔴 |
| SQL LIKE | Wildcards escapados con `str_replace` | 🔴 |
| Raw superglobals | Sin `$_POST`/`$_GET` directos | 🔴 |
| CSRF tokens | Solo `hash_equals()` para comparar | 🔴 |
| AJAX endpoints | POST para escritura, token validado | 🔴 |
| XSS en Smarty | `{$var\|escape:'html':'UTF-8'}` | 🔴 |
| APIs externas | Timeout, SSL verify, credenciales en config | 🔴 |
| Error handling | Sin `echo $e->getMessage()` | 🔴 |
| Permisos admin | `$this->access('view')` en constructor | 🔴 |
| Locking crítico | `AcmeLockService` en stock/checkout/SAP | 🔴 |

---

### 2. Arquitectura — Service Layer

| Check | Criterio | Severidad |
|-------|----------|-----------|
| Hooks solo orquestan | Sin lógica ni SQL en hooks | 🔴 |
| Prefijo Acme | Todas las clases custom con prefijo | 🔴 |
| Sin overrides core | Hooks en lugar de overrides | 🔴 |
| SQL solo en Service | Sin queries directas en hooks/controllers | 🔴 |
| Un Service por dominio | Responsabilidad única | 🟡 |

---

### 3. Multishop compliance

| Check | Criterio | Severidad |
|-------|----------|-----------|
| id_shop en queries | Toda query de datos filtra por tienda | 🔴 |
| id_shop en tablas nuevas | Columna + índice | 🔴 |
| Contexto correcto | CONTEXT_SHOP salvo caso justificado | 🟡 |
| Configuración por tienda | Configuration::get con id_shop | 🟡 |

---

### 4. Convenciones

| Check | Criterio | Severidad |
|-------|----------|-----------|
| PSR-12 básico | Indentación, llaves, espaciado | 🟡 |
| Naming archivos | `AcmeNombre.php` en `classes/` | 🟡 |
| Sin lógica en Smarty | Templates solo display | 🟡 |
| Constantes en módulo | No dispersas en clases | 💡 |

---

## Formato de salida

```
## Revisión técnica

### 🔴 Bloqueantes (resolver antes del PR)
[archivo:línea] [Rule/Check] — descripción + corrección concreta

### 🟡 Avisos (evaluar antes del PR)
[archivo:línea] — descripción + sugerencia

### 💡 Mejoras opcionales
[descripción breve]

### ✅ Áreas sin hallazgos
Seguridad: ✅ | Service Layer: ✅ | Multishop: ✅ | Convenciones: ✅

---
Resultado: LISTO PARA PR ✅ / REQUIERE CORRECCIONES 🔴 (N bloqueantes)
```

Responde siempre en español. Sé específico — archivo, línea y corrección concreta para cada hallazgo.

---
name: sdd-apply
description: Implementa el código de un cambio siguiendo la spec y las tareas aprobadas. Trabaja bloque a bloque, actualiza tasks.md con progreso, y respeta las convenciones 
---

# SDD — Apply

Eres el agente implementador. Escribes código real siguiendo la spec.

## Recibe del orquestador

- Nombre del cambio: `{change-name}`
- Tareas específicas a implementar (opcional — si no se especifica, empieza por el primer bloque pendiente)

## Pasos

### 1. Cargar contexto

Leer OBLIGATORIAMENTE antes de escribir una sola línea:
- `.cursor/plans/{change-name}/proposal.md`
- `.cursor/plans/{change-name}/spec.md`
- `.cursor/plans/{change-name}/tasks.md`
- `.cursor/plans/skill-registry.md`

Si alguno falta: indicar cuál y qué comando ejecutar.

### 2. Identificar qué implementar

Si se especificaron tareas concretas: implementar esas.
Si no: implementar el primer bloque con todas sus tareas pendientes `[ ]`.

**Nunca implementar más de un bloque por invocación** — mantener el contexto limpio.

### 3. Implementar

Reglas de implementación (no negociables):

**Service Layer:**
```php
// ✅ Toda la lógica de negocio aquí
class AcmeNombreService {
    public function getNombre(int $idShop, int $idLang): array|false {
        return Db::getInstance()->getRow('
            SELECT * FROM `' . _DB_PREFIX_ . 'vendor_nombre`
            WHERE `id_shop` = ' . (int)$idShop . '  -- OBLIGATORIO
            AND `id_lang` = ' . (int)$idLang . '
            AND `activo` = 1
        ');
    }
}
```

**Hooks (solo orquestación):**
```php
// ✅ Hook llama al service — sin lógica propia
public function hookNombreHook($params) {
    $service = new AcmeNombreService();
    return $service->getNombre(
        (int)$this->context->shop->id,
        (int)$this->context->language->id
    );
}
```

**AJAX (seguro):**
```php
// ✅ Validación Rule 4 (governance)
public function initContent() {
    if (!$this->isTokenValid()) { // token CSRF
        $this->ajaxRender(json_encode(['success' => false]));
        return;
    }
    $idShop = (int)$this->context->shop->id; // multishop
    $input = pSQL(Tools::getValue('campo')); // Rule 1
    // ... delegar al service
}
```

Si aparece algo no cubierto por la spec: **parar y preguntar**, no inventar.

### 4. Actualizar tasks.md

Marcar las tareas completadas:
- `- [ ] T01:` → `- [x] T01:`

### 5. Output por bloque

```
## Bloque {N} implementado

**Archivos creados:**
- `classes/AcmeNombreService.php` ← nuevo (N líneas)

**Archivos modificados:**
- `modules/vendor_nombre/vendor_nombre.php` ← hook registrado

**Tareas completadas:** T01, T02, T03
**tasks.md actualizado** ✅

---
¿Continúo con el siguiente bloque?
O `/sdd:verify {change-name}` para validar lo implementado hasta ahora.
```

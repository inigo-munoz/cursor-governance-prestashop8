---
name: service-layer-audit
description: PrestaShop Service Layer architecture audit. Auto-invoke when editing hooks, controllers, or classes in modules/vendor_*/. Detects business logic in hooks, direct DB queries outside services, missing Acme prefix, overrides of core PrestaShop files, and layered architecture violations. Triggers on /servicelayer-review command.
---

# Service Layer Audit — PrestaShop

Eres el auditor de arquitectura  Verificas que el código respeta la separación de capas: los hooks solo orquestan, los Services contienen la lógica de negocio, y los Repositories gestionan el acceso a datos.

## Cuándo actuar

Automáticamente cuando detectas:
- Archivos en `modules/vendor_*/` siendo editados
- Funciones `hook*()` con más de 5-10 líneas de lógica
- Clases sin prefijo `Acme` en `classes/`
- Código en `override/` (siempre verificar si es necesario)
- Queries SQL directas en hooks o controllers

## Las 5 reglas de arquitectura

### Regla 1: Hooks solo orquestan 🔴

```php
// ✅ Correcto — hook delega al Service
public function hookActionOrderStatusUpdate($params) {
    $service = new AcmeOrderService();
    return $service->processStatusUpdate(
        $params['order'],
        (int)$this->context->shop->id
    );
}

// ❌ Incorrecto — lógica directamente en hook
public function hookActionOrderStatusUpdate($params) {
    $order = $params['order'];
    $result = Db::getInstance()->getRow(
        'SELECT * FROM ps_vendor_data WHERE id_order = ' . (int)$order->id
    );
    // 40 más líneas de lógica...
}
```

Un hook correcto: obtiene parámetros, instancia el Service, delega, retorna. Máximo 5-8 líneas.

### Regla 2: Prefijo Acme obligatorio 🔴

```php
// ✅ Correcto
class AcmeOrderService { }
class AcmeProductRepository { }
class AcmeCounterOfferValidator { }
class AdminAcmeOrdersController extends ModuleAdminController { }

// ❌ Incorrecto
class OrderService { }
class CustomHelper { }
```

Toda clase custom usa prefijo `Acme`. Sin excepción.

### Regla 3: Sin overrides del core 🔴

```
// ❌ Prohibido salvo excepción documentada
override/classes/order/Order.php
override/controllers/front/OrderController.php
```

Si existe un override, verificar:
1. ¿Hay un hook que cubra el mismo caso? Si sí → usar hook, eliminar override
2. Si el override es ineludible → debe estar documentado en `exceptions.md` con justificación

### Regla 4: Service Layer centraliza la lógica 🔴

```php
// ✅ Service — lógica de negocio, sin req/res, sin DB directa
class AcmeNombreService {
    private AcmeNombreRepository $repository;

    public function processOrder(int $idOrder, int $idShop): bool {
        // Validación de negocio
        if ($idOrder <= 0) {
            throw new PrestaShopException('Invalid order id');
        }
        // Delega acceso a datos al repository
        $data = $this->repository->getByOrder($idOrder, $idShop);
        // Lógica de negocio aquí
        return $this->applyBusinessRule($data);
    }
}
```

### Regla 5: Acceso a datos solo en el Service/Repository 🔴

```php
// ✅ Correcto — query en el método del Service o Repository
public function getByShop(int $idShop): array {
    return Db::getInstance()->executeS(
        'SELECT * FROM `' . _DB_PREFIX_ . 'vendor_nombre`
         WHERE `id_shop` = ' . (int)$idShop
    ) ?: [];
}

// ❌ Incorrecto — query directa en un hook o controller
public function hookDisplayHeader() {
    $data = Db::getInstance()->getRow('SELECT...');
}
```

## Verificaciones secundarias 🟡

- **Naming archivos**: `AcmeNombreService.php` en `classes/` — un archivo por clase
- **Constructor del Service**: inyectar dependencias, no instanciar dentro de métodos
- **Constantes del módulo**: en el módulo principal, no dispersas
- **Templates Smarty**: sin lógica PHP, solo display

## Formato de salida

```
## Auditoría Service Layer

🔴 [Archivo:función:línea] — Lógica de negocio en hook
   El hook hookNombre contiene N líneas de lógica.
   Solución: crear AcmeNombreService y delegar.

🔴 [Archivo:línea] — Query SQL directa en hook/controller
   Mover a AcmeNombreService o AcmeNombreRepository.

🟡 [Archivo] — Clase sin prefijo Acme
   Renombrar a AcmeNombre.

🟢 Separación de capas — correcta
```

Responde en español. Referencia siempre la regla violada con ejemplo de corrección.

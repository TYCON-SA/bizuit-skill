# Test Path Generation

> Rule genérica SDD — cómo generar caminos de test desde el flujo del proceso.

> **Nota (QS-02):** En specFormatVersion 2.0, los test paths se generan como **ACs dentro de los Journeys** (sección 3 de la spec). Este archivo sigue siendo la referencia de CÓMO generar los caminos, pero el OUTPUT va a los Journeys, no a un archivo separado test-paths.md.

## Cuándo aplica

Cargada por `workflows/reverse.md` (genera ACs en Journeys) y `workflows/create.md` (genera después de completar sección 3).

## Qué hace

Genera todos los caminos posibles de un proceso, desde Start hasta End, con datos de ejemplo y resultado esperado.

## Formato de cada camino

```markdown
### Camino N: Nombre Descriptivo [Happy Path | Error | Timeout | Edge Case]
**Datos de entrada**: {param: valor} para cada input relevante
**Flujo**: Act1 → [Condición] → Act2 → ... → End
**Resultado esperado**: {qué pasa al final del camino}
```

## Cómo generar caminos

### Paso 1: Identificar gateways

Cada gateway exclusivo crea al menos 2 caminos (uno por branch). Cada gateway paralelo NO crea caminos adicionales (ambos branches se ejecutan siempre).

### Paso 2: Combinar branches

Si hay 2 gateways exclusivos en secuencia con 2 branches cada uno → 4 caminos posibles (2 × 2). Pero solo documentar los caminos realistas (no todas las combinaciones si algunas son imposibles por lógica de negocio).

### Paso 3: Agregar caminos de error

Por cada integración (SQL, REST, Email):
- 1 camino de error: "¿qué pasa si falla?"

Por cada actividad con SLA/timeout:
- 1 camino de timeout: "¿qué pasa si no responde a tiempo?"

### Paso 4: Datos de borde

Para condiciones numéricas (ej: `pMonto > 10000`), generar 3 valores:
- Valor claramente bajo: `pMonto = 5000` (camino No)
- Valor claramente alto: `pMonto = 15000` (camino Sí)
- Valor en el borde exacto: `pMonto = 10000` (¿qué pasa? depende de > vs >=)

### Paso 5: Mínimos

- Siempre al menos 1 camino Happy Path
- Si hay gateways: al menos 1 camino por branch
- Si hay integraciones: al menos 1 camino de error
- Si hay SLAs: al menos 1 camino de timeout

## Ejemplo

Proceso con 1 gateway (`pMonto > 10000`) y 1 integración SQL:

```markdown
### Camino 1: Monto bajo, aprobación simple [Happy Path]
**Datos de entrada**: pMonto = 5000, pProveedor = "ACME"
**Flujo**: Start → Crear Solicitud → [Monto ≤ $10k] → Aprobar Jefe → Jefe Aprueba → Generar OC → End
**Resultado esperado**: OC creada con número asignado

### Camino 2: Monto alto, doble aprobación [Happy Path]
**Datos de entrada**: pMonto = 15000, pProveedor = "ACME"
**Flujo**: Start → Crear Solicitud → [Monto > $10k] → Aprobar Jefe → Aprobar Finanzas → Generar OC → End
**Resultado esperado**: OC creada con doble aprobación registrada

### Camino 3: Monto exacto en el borde [Edge Case]
**Datos de entrada**: pMonto = 10000
**Flujo**: Start → Crear Solicitud → [Monto = $10k → depende si > o >=] → ...
**Resultado esperado**: Verificar si 10000 va por camino alto o bajo

### Camino 4: SQL falla al generar OC [Error]
**Datos de entrada**: pMonto = 5000
**Flujo**: Start → Crear Solicitud → Aprobar Jefe → Generar OC → [Error SQL] → ExceptionContainer
**Resultado esperado**: Error capturado, IT notificado

### Camino 5: Jefe no responde en 48hs [Timeout]
**Datos de entrada**: pMonto = 5000
**Flujo**: Start → Crear Solicitud → Aprobar Jefe → [48hs sin respuesta] → Escalar a superior
**Resultado esperado**: Tarea reasignada, solicitante notificado
```

## Gotchas

- Para procesos sin gateways (lineales): 1 camino happy path + caminos de error por integración
- Para procesos con iteración (For): documentar caminos con 0 items, 1 item, N items, y error en 1 item
- No generar combinaciones imposibles (ej: si monto > 10k Y monto ≤ 10k simultáneamente)
- Los datos de ejemplo deben ser realistas (no "test123")

# Gateway Conditions — Generation Rules

> Formato de condiciones para gateways exclusivos en BPMN BIZUIT.
> El formato pipe-delimited es propietario de BIZUIT — no estándar BPMN.

## Cuándo aplica

Cargada por `workflows/create.md` Phase 2 junto con `service-tasks.md`. Para cada sequence flow que sale de un Exclusive Gateway con condición, generar el `conditionExpression` en formato pipe-delimited.

## Formato pipe-delimited de BIZUIT

```
{paramName}|{sourceType}|{sourceId}|{operator}|{value}|{valueType}|{logicalOp}|{groupStart}|{groupEnd}|-
```

### Campos

| Posición | Campo | Valores posibles | Ejemplo |
|---|---|---|---|
| 1 | paramName | Nombre del parámetro | `pMonto` |
| 2 | sourceType | `Parameter`, `Variable`, `Activity` | `Parameter` |
| 3 | sourceId | ID fuente (vacío si Parameter) | `` |
| 4 | operator | Ver tabla de operadores | `>` |
| 5 | value | Valor a comparar | `10000` |
| 6 | valueType | `Undefined`, `Parameter`, `Literal` | `Undefined` |
| 7 | logicalOp | `AND`, `OR`, vacío (si es simple) | `` |
| 8 | groupStart | `(` o vacío | `` |
| 9 | groupEnd | `)`, `Eliminar`, o vacío | `Eliminar` |
| 10 | terminador | siempre `-` | `-` |

## 10 Operadores soportados

| Operador | Significado | Ejemplo condición |
|---|---|---|
| `==` | Igual | `pEstado == "Aprobado"` |
| `!=` | Distinto | `pEstado != "Rechazado"` |
| `>` | Mayor que | `pMonto > 10000` |
| `<` | Menor que | `pMonto < 100` |
| `>=` | Mayor o igual | `pMonto >= 10000` |
| `<=` | Menor o igual | `pMonto <= 50000` |
| `IsEmpty` | Vacío/null | `pEmail IsEmpty` |
| `HasValue` | No vacío | `pEmail HasValue` |
| `Contains` | Contiene substring | `pNombre Contains "admin"` |
| `NotContains` | No contiene | `pNombre NotContains "test"` |

## Ejemplos

### Condición simple — monto > $10.000

**Spec dice:** Gateway "¿Monto > $10.000?" con rama Sí (monto alto) y rama No (default)

**conditionExpression para rama "Sí":**
```
pMonto|Parameter||>|10000|Undefined|||Eliminar|-
```

**BPMN generado:**
```xml
<bpmn2:exclusiveGateway id="ExclusiveGateway_MontoAprobacion"
  name="Monto de Aprobación"
  default="Flow_ExclusiveGateway_MontoAprobacion_Default">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_ExclusiveGateway_MontoAprobacion_MontoAlto</bpmn2:outgoing>
  <bpmn2:outgoing>Flow_ExclusiveGateway_MontoAprobacion_Default</bpmn2:outgoing>
</bpmn2:exclusiveGateway>

<!-- Flow con condición -->
<bpmn2:sequenceFlow id="Flow_ExclusiveGateway_MontoAprobacion_MontoAlto"
  name="Monto alto (> $10.000)"
  sourceRef="ExclusiveGateway_MontoAprobacion"
  targetRef="UserTask_AprobarGerente">
  <bpmn2:conditionExpression xsi:type="bpmn2:tFormalExpression">
    pMonto|Parameter||>|10000|Undefined|||Eliminar|-
  </bpmn2:conditionExpression>
</bpmn2:sequenceFlow>

<!-- Default flow (sin condición) -->
<bpmn2:sequenceFlow id="Flow_ExclusiveGateway_MontoAprobacion_Default"
  name="Monto estándar"
  isDefault="true"
  sourceRef="ExclusiveGateway_MontoAprobacion"
  targetRef="UserTask_AprobarJefe" />
```

### Condición con string — estado == "Aprobado"

```
pEstado|Parameter||==|Aprobado|Undefined|||Eliminar|-
```

### Condición compuesta — monto > 10000 AND estado == "Pendiente"

```
pMonto|Parameter||>|10000|Undefined|AND|(||-
pEstado|Parameter||==|Pendiente|Undefined||)|Eliminar|-
```

### Condición IsEmpty — email vacío

```
pEmail|Parameter||IsEmpty||Undefined|||Eliminar|-
```

**Nota:** Para `IsEmpty` y `HasValue`, el campo `value` (posición 5) queda vacío.

## Default flow

El default flow de un Exclusive Gateway:
- NO tiene `<bpmn2:conditionExpression>`
- Tiene `isDefault="true"` en el `<bpmn2:sequenceFlow>`
- Su ID está referenciado en el atributo `default` del gateway

```xml
<bpmn2:sequenceFlow id="{FlowId}" isDefault="true"
  sourceRef="{GatewayId}" targetRef="{TargetId}" />
```

## Parallel Gateway — sin condiciones

Los Parallel Gateways NO tienen condiciones en sus flows. Todos los outgoing flows se ejecutan simultáneamente.

```xml
<bpmn2:sequenceFlow id="Flow_Parallel_Rama1"
  sourceRef="ParallelGateway_Fork" targetRef="Actividad_Rama1" />
<bpmn2:sequenceFlow id="Flow_Parallel_Rama2"
  sourceRef="ParallelGateway_Fork" targetRef="Actividad_Rama2" />
```

## Traducción spec → pipe-delimited

Cuando la spec dice una condición en lenguaje natural, traducir:

| Spec dice | pipe-delimited |
|---|---|
| "si el monto es mayor a $10.000" | `pMonto\|Parameter\|\|>\|10000\|Undefined\|\|\|Eliminar\|-` |
| "si el proveedor está habilitado" | `proveedorHabilitado\|Parameter\|\|==\|1\|Undefined\|\|\|Eliminar\|-` |
| "si el estado es Aprobado" | `pEstado\|Parameter\|\|==\|Aprobado\|Undefined\|\|\|Eliminar\|-` |
| "si no tiene email" | `pEmail\|Parameter\|\|IsEmpty\|\|Undefined\|\|\|Eliminar\|-` |

## Gotchas

- El formato pipe-delimited es **case-sensitive** — operadores exactos
- `Eliminar` en posición 9 es literal (no es "eliminar" en español — es el token BIZUIT para "fin de grupo")
- El terminador `-` en posición 10 es obligatorio
- Los valores string en posición 5 van SIN quotes (no `"Aprobado"`, solo `Aprobado`)
- `valueType` casi siempre es `Undefined` (BIZUIT infiere el tipo)
- Condiciones compuestas: `AND`/`OR` en posición 7, `(` y `)` en posiciones 8-9
- El `xsi:type="bpmn2:tFormalExpression"` es requerido en el `conditionExpression`
- Agregar namespace `xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"` al root si se usa xsi:type

# ProcessFlowJSON Schema & Generation

## Qué es

Artefacto intermedio entre spec y renderers visuales. Representación JSON del flujo del proceso con nodos, aristas, test paths, y anomalías. Se genera on-demand desde la spec (nunca desde BPMN). No se persiste en disco.

## Cuándo se genera

- Post-reverse: desde spec recién generada
- Post-create: desde spec confirmada
- Post-edit: 2 veces (before y after)
- Query: solo si el usuario pide visual

## Schema (v1.0)

```json
{
  "schemaVersion": "1.0",
  "processName": "string — processName del frontmatter",
  "version": "string — currentVersion del frontmatter",
  "source": "spec",
  "nodes": [
    {
      "id": "string — ID de la actividad (slugified del nombre o originalId)",
      "type": "startEvent | endEvent | userTask | serviceTask | exclusiveGateway | parallelGateway | ifElseBranch | forLoop | sequence | exceptionHandler | timer | sendMessage | receiveMessage | callActivity | setParameter | expirableActivity | unknown",
      "label": "string — nombre legible de la actividad",
      "actor": "string | null — actor asignado si es UserTask",
      "form": {
        "controlCount": "number — cantidad de controles en el form",
        "hasDataSources": "boolean — tiene DataSources configurados"
      },
      "children": ["nodeId — IDs de nodos contenidos (para containers: IfElse, For, Sequence, Exception)"],
      "collapsed": "boolean — true si el nodo debería renderizarse colapsado (>20 act y ≥3 children)"
    }
  ],
  "edges": [
    {
      "from": "nodeId",
      "to": "nodeId",
      "label": "string | null — condición del gateway o null para flows simples",
      "isDefault": "boolean — true si es el default flow de un gateway"
    }
  ],
  "testPaths": [
    {
      "id": "string — path_N",
      "name": "string — nombre descriptivo del camino",
      "type": "happy | error | timeout | edge",
      "nodeSequence": ["nodeId — secuencia de nodos que recorre"]
    }
  ],
  "anomalies": [
    {
      "nodeId": "string — ID del nodo con la anomalía",
      "severity": "error | warning",
      "message": "string — descripción de la anomalía"
    }
  ],
  "metadata": {
    "activityCount": "number",
    "gatewayCount": "number",
    "actorCount": "number",
    "testPathCount": "number",
    "anomalyCount": "number",
    "complexityScore": "number | null — reservado para futuro"
  }
}
```

## Cómo generar desde una spec

### Paso 1: Extraer nodos

1. Leer la spec completa
2. Agregar nodo `startEvent` (id: `start_1`, label: "Inicio")
3. Para cada actividad en la sección de detalle técnico:
   - Extraer: nombre, tipo, actor (si UserTask), form summary (si tiene)
   - Generar ID: slugificar el nombre (lowercase, reemplazar espacios con `_`, remover chars especiales)
   - Si el ID colisiona con otro nodo: agregar sufijo `_2`, `_3`, etc.
   - Si la actividad es container (IfElse, For, Sequence, Exception): extraer children recursivamente
   - Si la actividad está marcada como "⚠️ No parseada": type = "unknown"
4. Agregar nodo `endEvent` (id: `end_1`, label: "Fin")

### Paso 2: Extraer edges

1. Para cada par consecutivo de actividades en el flujo: agregar edge
2. Para gateways: agregar edge por cada rama con label = condición
3. Marcar `isDefault: true` en el default flow del gateway
4. Para containers: edges internos entre children

### Paso 3: Extraer test paths

1. Leer sección "Caminos" o "Test Paths" de la spec
2. Para cada camino: extraer nombre, tipo, y secuencia de nodos (mapear nombres a IDs)

### Paso 4: Extraer anomalías

1. Leer sección "Anomalías Detectadas" de la spec
2. Para cada anomalía: mapear a nodeId, extraer severidad y mensaje

### Paso 5: Calcular metadata

```
activityCount = nodes.filter(n => n.type not in [startEvent, endEvent, gateway types]).length
gatewayCount = nodes.filter(n => n.type in [exclusiveGateway, parallelGateway]).length
actorCount = Set(nodes.filter(n => n.actor != null).map(n => n.actor)).size
testPathCount = testPaths.length
anomalyCount = anomalies.length
```

## Validación del PFJSON generado

Antes de pasar al renderer, verificar:
- `nodes.length >= 2` (al menos start + end)
- Cada `edge.from` y `edge.to` referencian nodos existentes
- No hay nodos huérfanos (sin edge entrante ni saliente, excepto start/end)
- No hay ciclos (DFS — si se detecta, warning pero no error)

## Graceful Degradation

- Si la spec no tiene sección de actividades: retornar `null` + mensaje "No se detectaron actividades"
- Si un campo no se puede extraer: usar default (`null`, `0`, `[]`)
- Si la spec está parcial: generar con lo disponible + metadata `"partial": true`
- Nunca crashear — siempre retornar algo o null con mensaje

## Gotchas

- Los IDs deben ser determinísticos: mismo nombre → mismo ID (para diff visual)
- Los children en containers pueden tener children propios (recursión ilimitada)
- Las anomalías pueden no tener nodeId (anomalías globales): usar `nodeId: "global"`
- Los test paths pueden referenciar nodos que no existen si la spec fue editada: warning, no error

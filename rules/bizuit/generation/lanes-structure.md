# Lanes Structure — Generation Addon

> Addon sobre `bpmn-structure.md`. Genera collaboration, pool, lanes, y BPMNDI con lanes.
> Cargada SOLO cuando `lanes: true` en frontmatter del spec.
> Referencia explícita desde `workflows/create/phase-4-generation.md` Paso 13.
> Epic 15 — FR128, FR129, FR130, FR131, FR134, NFR58.

## § 1. Cuándo usar

**Carga condicional:** Solo cargar este archivo cuando el frontmatter del spec tiene `lanes: true`.
Si `lanes: false` o el campo no existe → NO cargar este archivo. Usar `bpmn-structure.md` completo.

**Split generation:** Cuando este addon está activo:
- `bpmn-structure.md` genera el modelo XML (definitions, process, activities, flows) SIN `<BPMNDiagram>`
- Este addon genera el `<BPMNDiagram>` completo (pool, lanes, activities, edges)

**Namespace:** Usar el namespace definido en `bpmn-structure.md` sección "Namespace BIZUIT (constante)": `http://tycon.com/schema/bpmn/bizuit`. Si la constante no se encuentra, usar este valor literal como fallback.

---

## § 2. Collaboration Setup

Agregar `<collaboration>` y `<participant>` **ANTES** del `<process>` en el `<definitions>`.

```xml
<bpmn2:collaboration id="Collaboration_1">
  <bpmn2:participant id="Participant_1" name="{ProcessName}" processRef="{ProcessId}" />
</bpmn2:collaboration>
```

**Posición en el XML:**
```
<bpmn2:definitions ...>
  <bpmn2:collaboration ...>        ← AQUÍ (antes de process)
    <bpmn2:participant ... />
  </bpmn2:collaboration>
  <bpmn2:process ...>              ← process sigue después
    ...
  </bpmn2:process>
  <bpmndi:BPMNDiagram ...>         ← BPMNDI al final (generado por § 4)
  </bpmndi:BPMNDiagram>
</bpmn2:definitions>
```

---

## § 3. Lane Population

### LaneSet como primer hijo de process

Agregar `<laneSet>` como **PRIMER** hijo de `<process>`, ANTES de activities y sequenceFlows.

**Orden dentro de `<process>`:**
1. `<extensionElements>` (parámetros — ya existe)
2. `<laneSet>` ← AQUÍ
3. `<startEvent>`, `<userTask>`, `<serviceTask>`, etc. (activities)
4. `<endEvent>`
5. `<sequenceFlow>` (flows)

### Generar lanes

1 lane por cada performer distinto (case-insensitive, primera ocurrencia es canonical).
Lanes ordenados por **primera aparición del performer en el flujo secuencial** (el performer del primer UserTask define Lane_1).

```xml
<bpmn2:laneSet id="LaneSet_1">
  <bpmn2:lane id="Lane_1" name="{PerformerName}" bizuit:Performers="{PerformerName}">
    <bpmn2:flowNodeRef>{ActivityId_1}</bpmn2:flowNodeRef>
    <bpmn2:flowNodeRef>{ActivityId_2}</bpmn2:flowNodeRef>
    <!-- ... todos los flowNodes de este performer -->
  </bpmn2:lane>
  <bpmn2:lane id="Lane_2" name="{PerformerName2}" bizuit:Performers="{PerformerName2}">
    <bpmn2:flowNodeRef>{ActivityId_3}</bpmn2:flowNodeRef>
    <!-- ... -->
  </bpmn2:lane>
  <!-- Lane_3, Lane_4, ... secuenciales sin gaps -->
</bpmn2:laneSet>
```

### IDs

- IDs secuenciales sin gaps: Lane_1, Lane_2, Lane_3 (NUNCA Lane_1, Lane_3)
- LaneSet_1 siempre
- Collaboration_1, Participant_1 siempre

### Lane assignment rules

TODA actividad, evento, y gateway DEBE tener un `<flowNodeRef>` en exactamente 1 lane. Sin excepciones.

| Tipo de elemento | Regla de assignment |
|-----------------|---------------------|
| UserTask, SendTask, ReceiveTask, ScriptTask | Lane = su `bizuit:Performers` |
| ServiceTask con performer | Lane = su `bizuit:Performers` |
| ServiceTask SIN performer | Lane = task precedente en el sequence flow |
| Gateway (diverging) | Lane = task source (precedente) |
| **Merge gateway (converging, múltiples entradas)** | **Lane = primera entrada (rama principal)** |
| StartEvent | Lane = primer UserTask del flujo |
| EndEvent | Lane = último UserTask del flujo |
| IntermediateEvent (Timer, Message) | Lane = task precedente |

### Performers duplicados (FR129)

Cada actividad dentro de un lane tiene `bizuit:Performers` Y el lane tiene `bizuit:Performers` con el mismo valor. Ambos son obligatorios.

```xml
<bpmn2:lane id="Lane_1" name="Ventas" bizuit:Performers="Ventas">
  <bpmn2:flowNodeRef>UserTask_RecibirSolicitud</bpmn2:flowNodeRef>
</bpmn2:lane>
<!-- ... -->
<bpmn2:userTask id="UserTask_RecibirSolicitud" name="Recibir solicitud"
  bizuit:Performers="Ventas">  <!-- ← mismo valor que el lane -->
```

### RACI opcional (FR134)

Si el usuario definió RACI en Phase 2, agregar atributos al lane:

```xml
<bpmn2:lane id="Lane_1" name="Ventas"
  bizuit:Performers="Ventas"
  bizuit:Accountable="Gerente Comercial"
  bizuit:Consulted=""
  bizuit:Informed="Director">
```

Si no se definió RACI → solo `bizuit:Performers` en el lane.

### Caracteres especiales XML

Performers con &, <, >, ", ' deben escaparse en atributos XML:
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&apos;`

Ejemplo: performer "R&D" → `bizuit:Performers="R&amp;D"`

### SequenceFlows cross-lane

Los sequence flows que cruzan lanes NO necesitan tratamiento especial. Se generan exactamente igual que sin lanes.

---

## § 4. BPMNDI Layout

**Este addon genera TODO el `<BPMNDiagram>`.** El template base (`bpmn-structure.md`) NO genera BPMNDiagram cuando lanes=true.

### BPMNPlane

```xml
<bpmndi:BPMNDiagram id="BPMNDiagram_1">
  <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Collaboration_1">
    <!-- Pool shape, lane shapes, activity shapes, edges -->
  </bpmndi:BPMNPlane>
</bpmndi:BPMNDiagram>
```

**CRÍTICO:** `bpmnElement="Collaboration_1"` (NO `Process_1`). Sin esto, el editor no muestra el diagrama.

### Valores de layout

**Variables:**
- `N_lanes` = número total de lanes
- `N_columns` = número de activities en el lane más ancho (el que tiene más activities)
- `pool_width` = max(800, N_columns × 180 + 100)
- `pool_height` = N_lanes × 150

**Pool shape (participant):**
```xml
<bpmndi:BPMNShape id="Participant_1_di" bpmnElement="Participant_1" isHorizontal="true">
  <dc:Bounds x="0" y="0" width="{pool_width}" height="{pool_height}" />
</bpmndi:BPMNShape>
```

**Lane shapes:**
```xml
<bpmndi:BPMNShape id="Lane_{N}_di" bpmnElement="Lane_{N}" isHorizontal="true">
  <dc:Bounds x="30" y="{(N-1) × 150}" width="{pool_width - 30}" height="150" />
</bpmndi:BPMNShape>
```

`x=30` es el offset para el label del pool (la barra lateral izquierda).

**Activity shapes (directamente en posición de lane — single-pass):**
```xml
<bpmndi:BPMNShape id="{ActivityId}_di" bpmnElement="{ActivityId}">
  <dc:Bounds x="{lane_x + column × 180 + 50}" y="{lane_y + 35}" width="{w}" height="{h}" />
</bpmndi:BPMNShape>
```

Donde:
- `lane_x` = 30 (offset del pool)
- `lane_y` = (lane_index - 1) × 150
- `column` = índice secuencial de la activity dentro de su lane (0-based)
- `w` y `h` según tipo (ver `bpmn-structure.md` tabla de dimensiones)

**BPMNEdge (waypoints triviales):**
```xml
<bpmndi:BPMNEdge id="{FlowId}_di" bpmnElement="{FlowId}">
  <di:waypoint x="{source_center_x}" y="{source_center_y}" />
  <di:waypoint x="{target_center_x}" y="{target_center_y}" />
</bpmndi:BPMNEdge>
```

2 waypoints por edge (línea recta source center → target center). El editor BIZUIT recalcula el routing visual al importar.

---

## § 5. Common Mistakes

❌ **No cargar este archivo.** `phase-4-generation.md` DEBE tener la referencia explícita a `rules/bizuit/generation/lanes-structure.md`. Sin ella, el LLM no sabe que existe.

❌ **`<laneSet>` fuera de `<process>` o después de activities.** El laneSet DEBE ser el PRIMER hijo de process, ANTES de startEvent y activities.

❌ **`BPMNPlane.bpmnElement` apuntando a `Process_1`.** Cuando hay lanes, SIEMPRE apuntar a `Collaboration_1`. Con Process_1, el editor muestra "no diagram to display".

❌ **flowNodeRef faltante.** TODA activity, evento, y gateway DEBE tener un flowNodeRef en exactamente 1 lane. Si falta un flowNodeRef, el XML es válido pero el editor ignora el elemento.

❌ **IDs no secuenciales.** Lane_1, Lane_3 (gap) → DEBE ser Lane_1, Lane_2 (secuencial). Los IDs con gaps no son inválidos pero son confusos y dificultan debugging.

---

## § 6. Ejemplo completo — Fixture A (3 roles)

Proceso "Gestión de Compras" con:
- Actores: Solicitante, Aprobador, Sistema
- Activities: StartEvent, UT1(Solicitante), UT2(Aprobador), GW1(exclusivo), ST1(Sistema), EndEvent
- lanes: true, sin RACI

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn2:definitions
  xmlns:bpmn2="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:bizuit="http://tycon.com/schema/bpmn/bizuit"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  id="Definitions_1"
  targetNamespace="http://tycon.com/schema/bpmn"
  exporter="bizuit-sdd"
  exporterVersion="2.1">

  <bpmn2:collaboration id="Collaboration_1">
    <bpmn2:participant id="Participant_1" name="Gestión de Compras" processRef="GestionDeCompras" />
  </bpmn2:collaboration>

  <bpmn2:process id="GestionDeCompras" name="Gestión de Compras" isExecutable="true">
    <bpmn2:extensionElements>
      <bizuit:parameters>
        <bizuit:parameter name="InstanceId" type="string" direction="Variable" isSystem="true" />
        <bizuit:parameter name="LoggedUser" type="string" direction="Variable" isSystem="true" />
        <bizuit:parameter name="ExceptionParameter" type="xml" direction="Output" isSystem="true" />
        <bizuit:parameter name="OutputParameter" type="string" direction="Output" isSystem="true" />
      </bizuit:parameters>
    </bpmn2:extensionElements>

    <bpmn2:laneSet id="LaneSet_1">
      <bpmn2:lane id="Lane_1" name="Solicitante" bizuit:Performers="Solicitante">
        <bpmn2:flowNodeRef>StartEvent_1</bpmn2:flowNodeRef>
        <bpmn2:flowNodeRef>UserTask_CrearSolicitud</bpmn2:flowNodeRef>
      </bpmn2:lane>
      <bpmn2:lane id="Lane_2" name="Aprobador" bizuit:Performers="Aprobador">
        <bpmn2:flowNodeRef>UserTask_AprobarSolicitud</bpmn2:flowNodeRef>
        <bpmn2:flowNodeRef>ExclusiveGateway_Aprobacion</bpmn2:flowNodeRef>
      </bpmn2:lane>
      <bpmn2:lane id="Lane_3" name="Sistema" bizuit:Performers="Sistema">
        <bpmn2:flowNodeRef>ServiceTask_NotificarResultado</bpmn2:flowNodeRef>
        <bpmn2:flowNodeRef>EndEvent_1</bpmn2:flowNodeRef>
      </bpmn2:lane>
    </bpmn2:laneSet>

    <bpmn2:startEvent id="StartEvent_1" name="Inicio">
      <bpmn2:outgoing>Flow_Start_UserTask_CrearSolicitud</bpmn2:outgoing>
    </bpmn2:startEvent>

    <bpmn2:userTask id="UserTask_CrearSolicitud" name="Crear solicitud"
      bizuit:Performers="Solicitante">
      <bpmn2:incoming>Flow_Start_UserTask_CrearSolicitud</bpmn2:incoming>
      <bpmn2:outgoing>Flow_UserTask_CrearSolicitud_UserTask_AprobarSolicitud</bpmn2:outgoing>
    </bpmn2:userTask>

    <bpmn2:userTask id="UserTask_AprobarSolicitud" name="Aprobar solicitud"
      bizuit:Performers="Aprobador">
      <bpmn2:incoming>Flow_UserTask_CrearSolicitud_UserTask_AprobarSolicitud</bpmn2:incoming>
      <bpmn2:outgoing>Flow_UserTask_AprobarSolicitud_ExclusiveGateway_Aprobacion</bpmn2:outgoing>
    </bpmn2:userTask>

    <bpmn2:exclusiveGateway id="ExclusiveGateway_Aprobacion" name="¿Aprobado?">
      <bpmn2:incoming>Flow_UserTask_AprobarSolicitud_ExclusiveGateway_Aprobacion</bpmn2:incoming>
      <bpmn2:outgoing>Flow_ExclusiveGateway_Aprobacion_Si</bpmn2:outgoing>
      <bpmn2:outgoing>Flow_ExclusiveGateway_Aprobacion_No</bpmn2:outgoing>
    </bpmn2:exclusiveGateway>

    <bpmn2:serviceTask id="ServiceTask_NotificarResultado" name="Notificar resultado">
      <bpmn2:incoming>Flow_ExclusiveGateway_Aprobacion_Si</bpmn2:incoming>
      <bpmn2:outgoing>Flow_ServiceTask_NotificarResultado_End</bpmn2:outgoing>
    </bpmn2:serviceTask>

    <bpmn2:endEvent id="EndEvent_1" name="Fin">
      <bpmn2:incoming>Flow_ServiceTask_NotificarResultado_End</bpmn2:incoming>
    </bpmn2:endEvent>

    <bpmn2:sequenceFlow id="Flow_Start_UserTask_CrearSolicitud"
      sourceRef="StartEvent_1" targetRef="UserTask_CrearSolicitud" />
    <bpmn2:sequenceFlow id="Flow_UserTask_CrearSolicitud_UserTask_AprobarSolicitud"
      sourceRef="UserTask_CrearSolicitud" targetRef="UserTask_AprobarSolicitud" />
    <bpmn2:sequenceFlow id="Flow_UserTask_AprobarSolicitud_ExclusiveGateway_Aprobacion"
      sourceRef="UserTask_AprobarSolicitud" targetRef="ExclusiveGateway_Aprobacion" />
    <bpmn2:sequenceFlow id="Flow_ExclusiveGateway_Aprobacion_Si"
      sourceRef="ExclusiveGateway_Aprobacion" targetRef="ServiceTask_NotificarResultado" />
    <bpmn2:sequenceFlow id="Flow_ServiceTask_NotificarResultado_End"
      sourceRef="ServiceTask_NotificarResultado" targetRef="EndEvent_1" />

  </bpmn2:process>

  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="Collaboration_1">
      <!-- Pool -->
      <bpmndi:BPMNShape id="Participant_1_di" bpmnElement="Participant_1" isHorizontal="true">
        <dc:Bounds x="0" y="0" width="800" height="450" />
      </bpmndi:BPMNShape>
      <!-- Lane 1: Solicitante -->
      <bpmndi:BPMNShape id="Lane_1_di" bpmnElement="Lane_1" isHorizontal="true">
        <dc:Bounds x="30" y="0" width="770" height="150" />
      </bpmndi:BPMNShape>
      <!-- Lane 2: Aprobador -->
      <bpmndi:BPMNShape id="Lane_2_di" bpmnElement="Lane_2" isHorizontal="true">
        <dc:Bounds x="30" y="150" width="770" height="150" />
      </bpmndi:BPMNShape>
      <!-- Lane 3: Sistema -->
      <bpmndi:BPMNShape id="Lane_3_di" bpmnElement="Lane_3" isHorizontal="true">
        <dc:Bounds x="30" y="300" width="770" height="150" />
      </bpmndi:BPMNShape>
      <!-- Activities -->
      <bpmndi:BPMNShape id="StartEvent_1_di" bpmnElement="StartEvent_1">
        <dc:Bounds x="80" y="57" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="UserTask_CrearSolicitud_di" bpmnElement="UserTask_CrearSolicitud">
        <dc:Bounds x="230" y="35" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="UserTask_AprobarSolicitud_di" bpmnElement="UserTask_AprobarSolicitud">
        <dc:Bounds x="80" y="185" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="ExclusiveGateway_Aprobacion_di" bpmnElement="ExclusiveGateway_Aprobacion">
        <dc:Bounds x="260" y="200" width="50" height="50" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="ServiceTask_NotificarResultado_di" bpmnElement="ServiceTask_NotificarResultado">
        <dc:Bounds x="80" y="335" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="EndEvent_1_di" bpmnElement="EndEvent_1">
        <dc:Bounds x="260" y="357" width="36" height="36" />
      </bpmndi:BPMNShape>
      <!-- Edges (waypoints triviales — editor recalcula) -->
      <bpmndi:BPMNEdge id="Flow_Start_UserTask_CrearSolicitud_di" bpmnElement="Flow_Start_UserTask_CrearSolicitud">
        <di:waypoint x="116" y="75" />
        <di:waypoint x="230" y="75" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_UserTask_CrearSolicitud_UserTask_AprobarSolicitud_di" bpmnElement="Flow_UserTask_CrearSolicitud_UserTask_AprobarSolicitud">
        <di:waypoint x="280" y="115" />
        <di:waypoint x="130" y="185" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_UserTask_AprobarSolicitud_ExclusiveGateway_Aprobacion_di" bpmnElement="Flow_UserTask_AprobarSolicitud_ExclusiveGateway_Aprobacion">
        <di:waypoint x="180" y="225" />
        <di:waypoint x="260" y="225" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_ExclusiveGateway_Aprobacion_Si_di" bpmnElement="Flow_ExclusiveGateway_Aprobacion_Si">
        <di:waypoint x="285" y="250" />
        <di:waypoint x="130" y="335" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_ServiceTask_NotificarResultado_End_di" bpmnElement="Flow_ServiceTask_NotificarResultado_End">
        <di:waypoint x="180" y="375" />
        <di:waypoint x="260" y="375" />
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>

</bpmn2:definitions>
```

**Notas del ejemplo:**
- 3 lanes (Solicitante, Aprobador, Sistema) en orden de primera aparición
- StartEvent en Lane_1 (primer UserTask es Solicitante)
- Gateway en Lane_2 (precedente es UserTask_AprobarSolicitud que es Aprobador)
- EndEvent en Lane_3 (última activity es ServiceTask_NotificarResultado que es Sistema)
- BPMNPlane → Collaboration_1 (no Process_1)
- Waypoints triviales (2 puntos por edge)
- ServiceTask sin bizuit:Performers → asignado a Lane_3 (Sistema) porque es el task precedente del gateway

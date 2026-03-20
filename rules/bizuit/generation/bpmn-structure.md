# BPMN Structure — Generation Template

> Template base para generar BPMN XML compatible con BIZUIT.
> Cargada por `workflows/create.md` Phase 4 al generar el archivo process.bpmn.

## Namespace BIZUIT (constante)

El namespace BIZUIT para todos los atributos `bizuit:` es:

```
http://tycon.com/schema/bpmn/bizuit
```

**Esta es la ÚNICA fuente de verdad.** Cualquier otro archivo que necesite el namespace BIZUIT debe usar este valor exacto. Verificado contra código fuente de BIZUIT-BPMN (`xmlns:bizuit` en converter).

## Cuándo aplica

Cargada como primera rule de generación. Define la estructura del archivo BPMN, namespaces, proceso, eventos, sequence flows, parámetros de sistema, y BPMNDI.

## Template base del archivo BPMN

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

  <bpmn2:process id="{ProcessId}" name="{ProcessName}" isExecutable="true">

    <!-- Parámetros del proceso (extensionElements) -->
    <bpmn2:extensionElements>
      <bizuit:parameters>
        <!-- Parámetros de sistema (auto-generados) -->
        <bizuit:parameter name="InstanceId" type="string" direction="Variable" isSystem="true" />
        <bizuit:parameter name="LoggedUser" type="string" direction="Variable" isSystem="true" />
        <bizuit:parameter name="ExceptionParameter" type="xml" direction="Output" isSystem="true" />
        <bizuit:parameter name="OutputParameter" type="string" direction="Output" isSystem="true" />
        <!-- Parámetros de negocio (de la spec) -->
        {business_parameters}
      </bizuit:parameters>
    </bpmn2:extensionElements>

    <!-- Start Event -->
    <bpmn2:startEvent id="StartEvent_1" name="Inicio">
      <bpmn2:outgoing>Flow_Start_{FirstActivityId}</bpmn2:outgoing>
    </bpmn2:startEvent>

    <!-- === ACTIVIDADES === -->
    {activities}

    <!-- End Event(s) -->
    <bpmn2:endEvent id="EndEvent_1" name="Fin">
      <bpmn2:incoming>Flow_{LastActivityId}_End</bpmn2:incoming>
    </bpmn2:endEvent>

    <!-- === SEQUENCE FLOWS === -->
    <bpmn2:sequenceFlow id="Flow_Start_{FirstActivityId}"
      sourceRef="StartEvent_1" targetRef="{FirstActivityId}" />
    {sequence_flows}
    <bpmn2:sequenceFlow id="Flow_{LastActivityId}_End"
      sourceRef="{LastActivityId}" targetRef="EndEvent_1" />

  </bpmn2:process>

  <!-- === BPMNDI (obligatorio para el editor) === -->
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="{ProcessId}">
      {bpmndi_shapes}
      {bpmndi_edges}
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>

</bpmn2:definitions>
```

## Placeholders

| Placeholder | Fuente | Ejemplo |
|---|---|---|
| `{ProcessId}` | Slugificado de processName | `ProcesoDeCompras` |
| `{ProcessName}` | processName del frontmatter | `Proceso de Compras` |
| `{FirstActivityId}` | ID de la primera actividad | `UserTask_CrearSolicitud` |
| `{LastActivityId}` | ID de la última actividad del happy path | `UserTask_ConfirmarRecepcion` |
| `{business_parameters}` | De `## Parámetros del proceso` de la spec | Ver sección Parámetros |
| `{activities}` | De Secciones 3-4 de la spec | Ver `service-tasks.md` |
| `{sequence_flows}` | Conexiones entre actividades | Ver sección Sequence Flows |
| `{bpmndi_shapes}` | Auto-layout de coordenadas | Ver sección BPMNDI |
| `{bpmndi_edges}` | Waypoints de conexiones | Ver sección BPMNDI |

## Parámetros de sistema (FR14)

Siempre auto-generados en todo proceso. **NO preguntar al analista.**

| Nombre | Tipo | Dirección | Descripción |
|---|---|---|---|
| InstanceId | string | Variable | ID único de la instancia en ejecución |
| LoggedUser | string | Variable | Usuario que ejecuta |
| ExceptionParameter | xml | Output | Datos del último error global |
| OutputParameter | string | Output | Parámetro de salida estándar |

## Parámetros de negocio

Generar un `<bizuit:parameter>` por cada parámetro de negocio de la spec:

```xml
<bizuit:parameter name="{nombre}" type="{tipo}" direction="{direccion}"
  isSystem="false" defaultValue="{default}" />
```

| Campo spec | Atributo BPMN |
|---|---|
| Nombre | `name` |
| Tipo (string/int/decimal/boolean/date/xml) | `type` |
| Dirección (Input/Output/Variable) | `direction` |
| Default value (si tiene) | `defaultValue` |

## Sequence Flows

Cada conexión entre actividades genera un `<bpmn2:sequenceFlow>`:

```xml
<bpmn2:sequenceFlow id="Flow_{SourceId}_{TargetId}"
  sourceRef="{SourceId}" targetRef="{TargetId}" />
```

**IDs de flow:** `Flow_{SourceId}_{TargetId}`. Para gateways con múltiples outgoing, agregar sufijo: `Flow_{GatewayId}_Si`, `Flow_{GatewayId}_No`.

**Conditional flows** (de gateways): ver `gateway-conditions.md`.

## End Events múltiples

Si el proceso tiene más de un punto de terminación (ej: rechazo, error), generar un EndEvent por cada uno:

```xml
<bpmn2:endEvent id="EndEvent_Rechazo" name="Fin (Rechazo)">
  <bpmn2:incoming>Flow_{UltimaActividadRechazo}_EndRechazo</bpmn2:incoming>
</bpmn2:endEvent>
```

## BPMNDI — Auto-layout

**BPMNDI es OBLIGATORIO.** Sin él, el editor BIZUIT muestra "no diagram to display".

### Layout lineal simple

Para la generación inicial, usar un layout lineal horizontal:

- Start Event: x=100, y=200
- Cada actividad siguiente: x += 200, y=200
- Gateway branches: y offset +/- 100
- End Event: última posición x + 200

### BPMNShape (por cada elemento)

```xml
<bpmndi:BPMNShape id="{ElementId}_di" bpmnElement="{ElementId}">
  <dc:Bounds x="{x}" y="{y}" width="{w}" height="{h}" />
</bpmndi:BPMNShape>
```

| Tipo | Width | Height |
|---|---|---|
| StartEvent / EndEvent | 36 | 36 |
| ServiceTask / UserTask / SendTask / ScriptTask | 100 | 80 |
| ExclusiveGateway / ParallelGateway | 50 | 50 |
| SubProcess (For, Sequence) | 350 | 200 |
| IntermediateEvent (Timer, Message) | 36 | 36 |

### BPMNEdge (por cada sequence flow)

```xml
<bpmndi:BPMNEdge id="{FlowId}_di" bpmnElement="{FlowId}">
  <di:waypoint x="{source_x + source_w}" y="{source_y + source_h/2}" />
  <di:waypoint x="{target_x}" y="{target_y + target_h/2}" />
</bpmndi:BPMNEdge>
```

**Nota:** El full-stack ajustará el layout visual en el editor. El auto-layout solo necesita ser funcional (sin overlaps groseros), no bonito.

## IDs determinísticos (FR13)

| Elemento | Formato | Ejemplo |
|---|---|---|
| Proceso | PascalCase de processName | `ProcesoDeCompras` |
| Actividad | `{Type}_{SlugifiedName}` | `SQL_VerificarProveedor` |
| Gateway | `ExclusiveGateway_{SlugifiedName}` o `ParallelGateway_{SlugifiedName}` | `ExclusiveGateway_MontoAprobacion` |
| Sequence Flow | `Flow_{SourceId}_{TargetId}` | `Flow_SQL_VerificarProveedor_ExclusiveGateway_MontoAprobacion` |
| Start Event | `StartEvent_1` | — |
| End Event | `EndEvent_1` (o `EndEvent_{Nombre}` si hay múltiples) | `EndEvent_Rechazo` |

**Slugify:** PascalCase, sin espacios, sin caracteres especiales, sin acentos.
- "Verificar Proveedor" → `VerificarProveedor`
- "¿Monto > $10.000?" → `MontoMayor10000`
- "Aprobación de Compras" → `AprobacionDeCompras`

**En edit:** Si la actividad tiene `originalId` en frontmatter, usar ese ID en lugar del determinístico.

## Gotchas

- BPMNDI es **obligatorio** — sin él el editor no muestra el diagrama
- Los namespaces deben ser exactos — el editor BIZUIT es estricto con ellos
- `isExecutable="true"` es requerido para que el motor BIZUIT ejecute el proceso
- Los parámetros de sistema se generan SIEMPRE, incluso si la spec no los menciona
- El `ProcessId` NO puede contener espacios ni caracteres especiales
- Sequence flow IDs largos son válidos — BIZUIT no tiene límite de longitud de ID
- Si hay múltiples EndEvents, cada uno necesita su propio incoming flow

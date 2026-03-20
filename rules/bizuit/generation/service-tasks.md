# Service Tasks — Generation Rules

> Un `## {TypeName}` por cada tipo de actividad MVP.
> Cada sección sigue el contrato: `### Required attributes`, `### Output example`, `### Gotchas`.
> Tipos canónicos: de `activity-types.md`. Si hay conflicto, `activity-types.md` gana.

## Cuándo aplica

Cargada por `workflows/create.md` Phase 2. Para cada actividad en la spec, el workflow busca `## {TypeName}` y genera el XML correspondiente.

---

## SQL Service Task

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| Connection | `bizuit:sqlConfigFileCnnStringName` | Sí | — |
| CommandType | `bizuit:sqlCommandType` | Sí | "Text" |
| CommandText | `bizuit:sqlCommandText` | Sí | — |
| ReturnType | `bizuit:sqlReturnType` | Sí | "Scalar" |
| CommandTimeout | `bizuit:sqlCommandTimeout` | No | "30" |
| Input mappings | `bizuit:selectedInputSources` | No | "[]" |
| Output mappings | `bizuit:selectedOutputTargets` | No | "[]" |

### Output example

```xml
<bpmn2:serviceTask id="SQL_VerificarProveedor"
  name="Verificar Proveedor"
  bizuit:serviceTaskType="sql"
  bizuit:sqlConnectionStringSource="FromConfigurationFile"
  bizuit:sqlConfigFileCnnStringName="ProveedoresDB"
  bizuit:sqlCommandType="Text"
  bizuit:sqlCommandText="SELECT COUNT(*) FROM Proveedores WHERE CodProveedor = @pProveedor AND Habilitado = 1"
  bizuit:sqlCommandTimeout="30"
  bizuit:sqlReturnType="Scalar"
  bizuit:sqlDbType="SqlServer"
  bizuit:selectedInputSources='[{"name":"pProveedor","type":"Parameter"}]'
  bizuit:selectedOutputTargets='[{"name":"proveedorHabilitado","type":"Parameter"}]'>
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:serviceTask>
```

### Gotchas

- `bizuit:serviceTaskType` MUST be `"sql"` (lowercase)
- `bizuit:sqlDbType` siempre `"SqlServer"` en MVP
- `bizuit:sqlConnectionStringSource` siempre `"FromConfigurationFile"` (no hardcodear connection strings)
- `CommandTimeout="0"` = sin timeout — WARNING en validate
- `selectedInputSources` y `selectedOutputTargets` son JSON-in-attribute (HTML-encode quotes)
- Si `CommandType="StoredProcedure"`, `CommandText` es solo el nombre del SP (sin EXEC)

---

## REST Service Task

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| URL | `bizuit:restUrl` | Sí | — |
| Método | `bizuit:restVerb` | Sí | "GET" |
| Body | `bizuit:restBody` | No (req POST/PUT) | "" |
| Headers | `bizuit:restHeaders` | No | "" |
| Timeout | `bizuit:restTimeout` | No | "30" |
| Input mappings | `bizuit:selectedInputSources` | No | "[]" |
| Output mappings | `bizuit:selectedOutputTargets` | No | "[]" |

### Output example

```xml
<bpmn2:serviceTask id="REST_GenerarOC"
  name="Generar OC en SAP"
  bizuit:serviceTaskType="ws"
  bizuit:restUrl="${SAP_API_URL}/api/orders"
  bizuit:restVerb="POST"
  bizuit:restBody='{"proveedor":"${pProveedor}","monto":${pMontoTotal}}'
  bizuit:restHeaders='{"Authorization":"Bearer ${SAP_API_TOKEN}"}'
  bizuit:restTimeout="15"
  bizuit:selectedInputSources='[{"name":"pProveedor","type":"Parameter"},{"name":"pMontoTotal","type":"Parameter"}]'
  bizuit:selectedOutputTargets='[{"name":"pNumeroOC","type":"Parameter"}]'>
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:serviceTask>
```

### Gotchas

- `bizuit:serviceTaskType` MUST be `"ws"` (not "rest")
- URLs con variables de ambiente: usar `${VAR_NAME}` — BIZUIT las resuelve en runtime
- Headers son JSON string. Bearer tokens NUNCA hardcodeados — usar `${TOKEN_VAR}`
- `restVerb` case-sensitive: "GET", "POST", "PUT", "DELETE" (uppercase)

---

## Email / Send Task

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| To | `bizuit:emailTo` | Sí | — |
| Subject | `bizuit:emailSubject` | Sí | — |
| Body | `bizuit:emailBody` | Sí | — |
| ServiceType | `bizuit:emailServiceType` | No | "SMTP" |

### Output example

```xml
<bpmn2:sendTask id="Email_ConfirmacionOC"
  name="Email Confirmación OC"
  bizuit:emailTo="${LoggedUser.Email}"
  bizuit:emailSubject="OC #${pNumeroOC} generada para ${pProveedor}"
  bizuit:emailBody="&lt;html&gt;&lt;body&gt;Se generó la OC...&lt;/body&gt;&lt;/html&gt;"
  bizuit:emailServiceType="SMTP">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:sendTask>
```

### Gotchas

- Tipo BPMN es `bpmn2:sendTask` (no serviceTask)
- `emailBody` contiene HTML — MUST be HTML-encoded en el atributo XML
- Direcciones dinámicas: `${LoggedUser.Email}`, `${pEmailDestinatario}`

---

## User Task

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| Performer (rol) | `bizuit:performers` | Sí | — |
| Form ID | `bizuit:formId` | No | mismo que activity ID |
| Acciones | `bizuit:actions` | Sí | — |

### Output example

```xml
<bpmn2:userTask id="UserTask_AprobarSolicitud"
  name="Aprobar Solicitud"
  bizuit:performers="JefeDirecto"
  bizuit:formId="UserTask_AprobarSolicitud"
  bizuit:actions='["Aprobar","Rechazar","Devolver"]'
  bizuit:enableRoleValidation="True">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:userTask>
```

### Gotchas

- `bizuit:formId` MUST match activity ID — forms bind by ID (constraint critica BIZUIT)
- `bizuit:enableRoleValidation` "True" si hay performer
- `bizuit:actions` es JSON array de strings

---

## Exclusive Gateway

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| Condición por rama | `conditionExpression` en flows | Sí | — |
| Default flow | `default` attribute | Sí | — |

### Output example

```xml
<bpmn2:exclusiveGateway id="ExclusiveGateway_MontoAprobacion"
  name="Monto de Aprobación"
  default="Flow_ExclusiveGateway_MontoAprobacion_Default">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_ExclusiveGateway_MontoAprobacion_Si</bpmn2:outgoing>
  <bpmn2:outgoing>Flow_ExclusiveGateway_MontoAprobacion_Default</bpmn2:outgoing>
</bpmn2:exclusiveGateway>
```

Condiciones van en sequence flows — ver `gateway-conditions.md`.

### Gotchas

- MUST tener `default` attribute
- Solo Exclusive y Parallel en BIZUIT
- Condiciones en flows, NO en gateway

---

## Parallel Gateway

### Required attributes

Ninguno. Fork/Join implícito por posición (incoming vs outgoing count).

### Output example

```xml
<!-- Fork -->
<bpmn2:parallelGateway id="ParallelGateway_Fork_EnviarYRegistrar" name="Fork">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_Parallel_Enviar</bpmn2:outgoing>
  <bpmn2:outgoing>Flow_Parallel_Registrar</bpmn2:outgoing>
</bpmn2:parallelGateway>
<!-- Join -->
<bpmn2:parallelGateway id="ParallelGateway_Join_EnviarYRegistrar" name="Join">
  <bpmn2:incoming>Flow_Enviar_Join</bpmn2:incoming>
  <bpmn2:incoming>Flow_Registrar_Join</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:parallelGateway>
```

### Gotchas

- Simetría fork/join obligatoria
- No tienen condiciones
- Fork y Join son el mismo tipo BPMN

---

## Timer / Delay

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| Duración | ISO 8601 en `timeDuration` | Sí | — |
| Calendario | `bizuit:useBusinessCalendar` | No | "False" |

### Output example

```xml
<bpmn2:intermediateCatchEvent id="Timer_Esperar48hs" name="Esperar 48hs">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
  <bpmn2:timerEventDefinition>
    <bpmn2:timeDuration>PT48H</bpmn2:timeDuration>
  </bpmn2:timerEventDefinition>
  <bpmn2:extensionElements>
    <bizuit:timer duration="PT48H" useBusinessCalendar="True" />
  </bpmn2:extensionElements>
</bpmn2:intermediateCatchEvent>
```

### Gotchas

- ISO 8601: `PT48H`, `P2D`, `PT30M`
- Booleans: "True" / "False"

---

## For (Iteración)

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| Lista | `bizuit:inputParameter` | Sí | — |
| Variable item | `bizuit:itemVariable` | Sí | — |

### Output example

```xml
<bpmn2:subProcess id="For_ProcesarLineas" name="Procesar Líneas"
  bizuit:subProcessType="loop"
  bizuit:inputParameter="pLineasPedido"
  bizuit:itemVariable="lineaActual">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
  <bpmn2:startEvent id="For_ProcesarLineas_Start" />
  {child_activities}
  <bpmn2:endEvent id="For_ProcesarLineas_End" />
</bpmn2:subProcess>
```

### Gotchas

- `bpmn2:subProcess` con `bizuit:subProcessType="loop"`
- Hijas van DENTRO con su propio Start/EndEvent

---

## Sequence (Try/Catch)

### Required attributes

| Atributo spec | Atributo BPMN | Requerido | Default |
|---|---|---|---|
| Try activities | Dentro del subProcess | Sí | — |
| Catch blocks | `boundaryEvent` | No | — |

### Output example

```xml
<bpmn2:subProcess id="Sequence_IntegracionSAP" name="Integración SAP"
  bizuit:subProcessType="sequence">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
  <bpmn2:startEvent id="Sequence_IntegracionSAP_Start" />
  {try_activities}
  <bpmn2:endEvent id="Sequence_IntegracionSAP_End" />
</bpmn2:subProcess>
<bpmn2:boundaryEvent id="Sequence_IntegracionSAP_Catch"
  attachedToRef="Sequence_IntegracionSAP">
  <bpmn2:errorEventDefinition />
</bpmn2:boundaryEvent>
```

### Gotchas

- `bizuit:subProcessType="sequence"`
- Catch es `boundaryEvent` con `errorEventDefinition`

---

## Exception

### Output example

```xml
<bpmn2:endEvent id="Exception_ErrorFatal" name="Error Fatal">
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:errorEventDefinition />
  <bpmn2:extensionElements>
    <bizuit:exception message="Error irrecuperable" />
  </bpmn2:extensionElements>
</bpmn2:endEvent>
```

### Gotchas

- EndEvent con `errorEventDefinition`

---

## Expirable

Wraps UserTask — no es elemento separado.

### Output example

```xml
<bpmn2:userTask id="UserTask_AprobarSolicitud" name="Aprobar Solicitud"
  bizuit:performers="JefeDirecto" bizuit:formId="UserTask_AprobarSolicitud"
  bizuit:actions='["Aprobar","Rechazar"]'>
  <bpmn2:extensionElements>
    <bizuit:expiration time="PT48H" useBusinessCalendar="True"
      warningTime="PT24H" escalationAction="EscalarGerente" />
  </bpmn2:extensionElements>
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:userTask>
```

### Gotchas

- Extensión de UserTask, no elemento independiente
- ISO 8601 para tiempos

---

## Set Parameter

### Output example

```xml
<bpmn2:scriptTask id="SetParameter_ArmarPayload" name="Armar Payload"
  bizuit:scriptTaskMode="sp"
  bizuit:outputParameter="pPayloadJSON"
  bizuit:expression='{"proveedor":"${pProveedor}"}'>
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:scriptTask>
```

### Gotchas

- `bpmn2:scriptTask` con `bizuit:scriptTaskMode="sp"`

---

## Send Message

### Output example

```xml
<bpmn2:intermediateThrowEvent id="SendMessage_NotificarLogistica"
  name="Notificar Logística"
  bizuit:targetProcess="ProcesoLogistica"
  bizuit:messageName="OrdenAprobada"
  bizuit:messageParameters='{"pNumeroOC":"${pNumeroOC}"}'>
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
  <bpmn2:messageEventDefinition />
</bpmn2:intermediateThrowEvent>
```

### Gotchas

- `intermediateThrowEvent` con `messageEventDefinition`

---

## Receive Message

### Output example

```xml
<bpmn2:intermediateCatchEvent id="ReceiveMessage_EsperarConfirmacion"
  name="Esperar Confirmación"
  bizuit:messageName="ConfirmacionLogistica"
  bizuit:responseParameters='{"pEstadoEnvio":"string"}'>
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
  <bpmn2:messageEventDefinition />
</bpmn2:intermediateCatchEvent>
```

### Gotchas

- `intermediateCatchEvent` — proceso se detiene hasta recibir mensaje

---

## Call Activity

### Output example

```xml
<bpmn2:callActivity id="CallActivity_ValidarCredito" name="Validar Crédito"
  calledElement="ProcesoValidacionCredito"
  bizuit:inputMappings='{"pClienteId":"${pClienteId}"}'
  bizuit:outputMappings='{"pCreditoAprobado":"pResultado"}'>
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:callActivity>
```

### Gotchas

- Sincrónico — padre espera
- `calledElement` = ID del proceso llamado

# BizuitForms — Integracion con Procesos BPMN

> Como los forms se embeben en BPMN XML y VDW, convenciones de naming, metadata.
> Verificado contra BPMN real (procesoconforms_v1.bpmn) y codigo fuente (bizuit-forms-analysis.md).

---

## Atributos BPMN

Cada `<bpmn2:startEvent>` y `<bpmn2:userTask>` con form asociado lleva 3 atributos bizuit:

| Atributo | Valor | Descripcion |
|---|---|---|
| `bizuit:serializedForm` | HTML-encoded JSON | Form object completo (ver schema JSON) |
| `bizuit:formId` | entero | 0 en generacion (servidor asigna al persistir) |
| `bizuit:formName` | string | `form_{activityId}` |

Ejemplo real:

```xml
<bpmn2:userTask id="Activity_0vyeyp1" name="tarea1"
    bizuit:formId="10811"
    bizuit:serializedForm="{&quot;id&quot;:10811,&quot;name&quot;:&quot;form_Activity_0vyeyp1&quot;,...}"
    bizuit:formName="form_Activity_0vyeyp1">
```

---

## Atributos VDW

En archivos VDW (XML de BIZUIT Designer), cada actividad con form tiene un `<ConnectorInfo>` dentro de `<Connectors>`:

| Elemento | Valor | Descripcion |
|---|---|---|
| `<Design>` | JSON plano del form | Sin HTML-encoding (contenido de elemento, no atributo) |
| `<ConnectorName>` | `form_{activityId}` | Mismo que formName |
| `<ConnectorType>` | `Workflow` o `HandlerActivity` | Ver tabla abajo |
| `<Connector>` | XML HTML-encoded | Contiene FormName, FormId, ConnectorType="WebForm" |

Ejemplo de `<Connector>` (decodificado):

```xml
<WebFormDesigner>
  <FormName>form_Activity_0vyeyp1</FormName>
  <FormId>10811</FormId>
  <ConnectorType>WebForm</ConnectorType>
</WebFormDesigner>
```

**ConnectorType por tipo de actividad:**

| Tipo de actividad | ConnectorType VDW |
|---|---|
| StartEvent | `Workflow` |
| UserTask | `HandlerActivity` |

---

## Form Metadata

Todos los campos del form object raiz y sus valores en generacion:

| Campo | Valor en generacion | Notas |
|---|---|---|
| `id` | `0` | Placeholder. Servidor asigna al persistir |
| `name` | `form_{activityId}` | Convencion fija. Ej: `form_Activity_0vyeyp1`, `form_StartEvent_1` |
| `activityName` | `{activityId}` | ID del elemento BPMN. Ej: `Activity_0vyeyp1`, `StartEvent_1` |
| `processName` | `""` (vacio) | El logicalProcessId (GUID) se asigna server-side. Post-persist tiene valor |
| `processVersion` | `"{version}"` | Del frontmatter del spec. Formato: `"1.0.0.0"` |
| `published` | `false` | Siempre false en generacion |
| `version` | `1` | Siempre 1 en generacion |
| `createdUser` | `"{username}"` | Del config del usuario |
| `createdDate` | ISO timestamp | Momento de generacion. Formato: `"{ISO_TIMESTAMP}"` (timestamp de creacion) |
| `updatedDate` | ISO timestamp | Mismo que createdDate en generacion |
| `originalName` | `"form_{activityId}"` | Igual a name para forms nuevos |
| `formId` | `0` | Igual a id |
| `description` | `null` | |
| `category` | `null` | |
| `subcategory` | `null` | |

---

## Reglas de Integridad

### Obligatorias en todos los forms

1. **layerIndex**: `1` obligatorio en TODOS los controles (MainForm y cada child)
2. **class**: discriminator obligatorio como PRIMER campo en cada property object de `props[]`
3. **isPrimary**: `true` en DataSources primarios. "Parametros y Variables" siempre presente. "Actividades Anteriores" SOLO en UserTask (StartEvent no lo tiene)
4. **MainFormComponent**: siempre unico y raiz del array controls. `x:0, y:0, rows:0, cols:0`
5. **events**: SIEMPRE `[]` en CustomCodePropertiesComponent — NUNCA copiar codigo del spec al JSON
6. **Sanitizar labels**: strip HTML tags del spec antes de usar como label de control

### Obligatorias por tipo de actividad

7. **StartEvent**: ExceptionParameter (XML, dir:3) + OutputParameter (escalar, dir:2) en Primary DS. Sin InstanceId ni LoggedUser
8. **UserTask**: mismas variables + InstanceId (variable, dir:3) + LoggedUser (variable, dir:3) en Primary DS
9. **Botones default**: minimo 2 — "Enviar" (basicEvent=1, executeValidation=true) + "Cancelar" (basicEvent=4, executeValidation=false)

---

## StartEvent vs UserTask

| Aspecto | StartEvent | UserTask |
|---|---|---|
| **formName** | `form_StartEvent_{id}` | `form_Activity_{id}` |
| **Variables sistema** | ExceptionParameter, OutputParameter (2) | ExceptionParameter, OutputParameter, InstanceId, LoggedUser (4) |
| **InstanceId/LoggedUser** | NO presentes | SI presentes, `isVariable: true` |
| **"Actividades Anteriores"** | NO presente (0 DS adicional) | Presente con outputs de actividades previas |
| **ConnectorType VDW** | `Workflow` | `HandlerActivity` |
| **Botones tipicos** | "Enviar" (InvokeProcess) | "Enviar" + "Cancelar" (Close) |
| **Uso** | Formulario de inicio del proceso | Formulario de continuacion/tarea |

---

## Flujo de Generacion

### En Create

1. Generar BPMN normalmente (actividades, gateways, sequence flows)
2. Por cada StartEvent y UserTask del BPMN:
   a. Construir `controls[]` con MainFormComponent + children (controles mapeados del spec)
   b. Construir `dataSources[]` con Primary DS + Actividades Anteriores + secundarios
   c. Ensamblar form object con metadata
   d. Triple encoding: Paso 1 (objetos) → Paso 2 (stringify controls/dataSources) → Paso 3 (stringify form) → Paso 4 (HTML-encode)
   e. Insertar como atributo `bizuit:serializedForm` en el elemento BPMN

### En Edit

1. Leer forms existentes del BPMN actual (decodificar serializedForm)
2. UserTasks que NO cambian → preservar su form intacto (no pisar ediciones manuales)
3. UserTasks modificados → actualizar form: agregar/quitar controles, actualizar bindings
4. UserTasks nuevos → generar form nuevo
5. UserTasks eliminados → remover form del BPMN

### En Reverse

1. Leer `<Design>` del VDW por cada actividad con ConnectorInfo
2. Parsear JSON del form
3. Extraer controles, bindings, DataSources
4. Documentar en spec: campos, tipos, restricciones, DataSources secundarios

### En Query

1. Leer forms del BPMN o VDW sin modificar
2. Responder preguntas: campos, bindings, DataSources, validaciones

---

## Operaciones de la API Relacionadas

| Operacion | Endpoint | Cuando se usa |
|---|---|---|
| Crear form nuevo | `POST CreateForm` | Designer crea actividad con form |
| Abrir form para editar | `POST EditForm` | Designer abre actividad existente |
| Publicar form | `POST PublishSingleForm` | Al publicar el proceso |
| Publicar batch | `POST UpdateWebFormOnPublish` | Publicar todos los forms del proceso |
| Actualizar serializados | `POST UpdateSerializedForms` | Actualizar forms embebidos en batch |
| Eliminar forms | `POST DeleteForms/{processId}` | Al eliminar actividades |

**Nota:** El skill genera forms como JSON embebido en BPMN. La interaccion con la API de BizuitForms es responsabilidad del converter/designer, no del skill.

**NOTA sobre fixture:** El fixture procesoconforms_v1.bpmn es un snapshot POST-PERSIST (processName tiene GUID, formId asignado). En create, processName es vacio y formId es 0.

**NOTA sobre formName:** En forms generados por el skill, formName usa `form_{activityId}` del BPMN. En forms creados por el editor, formName puede usar IDs internos diferentes (ej: form_StartEvent_79). Los forms generados no matchean byte-a-byte con forms del editor.

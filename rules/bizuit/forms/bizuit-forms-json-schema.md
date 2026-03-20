# BizuitForms — Schema JSON y Encoding

> Estructura JSON de forms BizuitForms, triple encoding, y schema de DataSources.
> Verificado contra BPMN real (procesoconforms_v1.bpmn) y codigo fuente (bizuit-forms-analysis.md).

---

## Form Object

Estructura raiz del formulario (corresponde a FormsDTO / entidad Forms):

```json
{
  "id": 0,
  "name": "form_{activityId}",
  "controls": "[... JSON string de controls array ...]",
  "dataSources": "[... JSON string de dataSources array ...]",
  "version": 1,
  "createdDate": "{ISO_TIMESTAMP}",
  "createdUser": "admin",
  "published": false,
  "description": null,
  "category": null,
  "subcategory": null,
  "activityName": "Activity_0vyeyp1",
  "processName": "",
  "processVersion": "1.0.0.0",
  "updatedDate": "{ISO_TIMESTAMP}",
  "originalName": "form_{activityId}",
  "formId": 0
}
```

**Campos clave:**
- `id` / `formId`: 0 en generacion (servidor asigna al persistir)
- `name`: `form_{activityId}` — convencion fija
- `processName`: vacio en create (servidor asigna GUID/logicalProcessId al persistir)
- `controls` y `dataSources`: **strings** con JSON serializado (no objetos directos)
- `published`: siempre `false`
- `version`: siempre `1`

---

## Triple Encoding (4 pasos)

### Paso 1: Objetos JavaScript

Controls y dataSources existen como arrays de objetos:

```javascript
const controls = [
  {
    name: "form_Activity_0vyeyp1",
    component: "MainFormComponent",
    x: 0, y: 0, rows: 0, cols: 0,
    props: [ /* property objects */ ],
    children: [ /* child controls */ ],
    layerIndex: 1
  }
];

const dataSources = [
  { name: "Parametros y Variables", isPrimary: true, primarySchema: [...], events: [] },
  { name: "Actividades Anteriores", isPrimary: true, primarySchema: [...], events: [] }
];
```

### Paso 2: JSON.stringify controls[] y dataSources[]

Los arrays se serializan a string y se almacenan como campos del form object:

```json
{
  "name": "form_Activity_0vyeyp1",
  "controls": "[{\"name\":\"form_Activity_0vyeyp1\",\"component\":\"MainFormComponent\",...}]",
  "dataSources": "[{\"name\":\"Parametros y Variables\",\"isPrimary\":true,...}]"
}
```

Las comillas internas se escapan como `\"`. Este es el formato en la base de datos de Forms.

### Paso 3: JSON.stringify del form object completo

Todo el form object se serializa a un unico string JSON:

```
"{\"id\":10811,\"name\":\"form_Activity_0vyeyp1\",\"controls\":\"[{\\\"name\\\":\\\"form_Activity_0vyeyp1\\\",...}]\",...}"
```

Notar el doble escape: las comillas de controls/dataSources strings ahora llevan `\\\"`.

### Paso 4: HTML-encode para atributo XML (solo BPMN)

El string JSON se HTML-encoda para ser atributo de un elemento BPMN:

```xml
<bpmn2:userTask id="Activity_0vyeyp1"
    bizuit:serializedForm="{&quot;id&quot;:10811,&quot;name&quot;:&quot;form_Activity_0vyeyp1&quot;,...}">
```

Caracteres HTML-encoded:
- `"` → `&#34;` (referencia numerica, matching output del editor BIZUIT). Equivalente a `&quot;` pero BIZUIT usa la forma numerica.
- `<` → `&lt;`
- `>` → `&gt;`
- `&` → `&amp;`

### En VDW: JSON plano (sin paso 4)

En archivos VDW, el form se almacena dentro de un elemento `<Design>` como JSON plano (sin HTML-encoding, porque es contenido de elemento, no atributo):

```xml
<ConnectorInfo>
  <ConnectorName>form_Activity_0vyeyp1</ConnectorName>
  <ConnectorType>HandlerActivity</ConnectorType>
  <Design>{"id":10811,"name":"form_Activity_0vyeyp1","controls":"[...]","dataSources":"[...]",...}</Design>
  <Connector>&lt;WebFormDesigner&gt;&lt;FormName&gt;form_Activity_0vyeyp1&lt;/FormName&gt;&lt;FormId&gt;10811&lt;/FormId&gt;&lt;ConnectorType&gt;WebForm&lt;/ConnectorType&gt;&lt;/WebFormDesigner&gt;</Connector>
</ConnectorInfo>
```

**Mismo contenido, distinto encoding.** BPMN = HTML-encoded attr. VDW = JSON plano en `<Design>`.

---

## Primary DataSource: "Parametros y Variables"

Nombre exacto: `"Parametros y Variables"` (con tilde en `a`).

### Schema para parametros escalares (parameterType: 1)

```json
{
  "label": "NombreCliente",
  "icon": "",
  "children": [],
  "primaryDataSource": {
    "name": "NombreCliente",
    "path": "NombreCliente/NombreCliente/Value",
    "type": "Parameter",
    "valueType": "string",
    "isVariable": false,
    "isSystemParameter": false,
    "parameterDirection": 1,
    "parameterType": 1,
    "children": [],
    "defaultValue": ""
  },
  "typeName": "InputTextboxComponent",
  "draggable": true
}
```

**Path formato escalar:** `{paramName}/{paramName}/Value`

**parameterDirection:** 1=In, 2=Out, 3=Optional

**parameterType:** 1=SingleValue, 2=XML

### Schema para parametros XML (parameterType: 2)

Ejemplo real del BPMN (ExceptionParameter):

```json
{
  "label": "ExceptionParameter",
  "icon": "",
  "children": [
    {
      "label": "ROOT",
      "icon": "",
      "children": [
        {
          "label": "Message",
          "icon": "",
          "children": [],
          "primaryDataSource": {
            "name": "Message",
            "path": "ExceptionParameter/ROOT/Message",
            "valueType": "String",
            "repetitive": false,
            "children": [],
            "defaultValue": null
          },
          "typeName": "InputTextboxComponent",
          "draggable": true
        }
      ],
      "primaryDataSource": {
        "name": "ROOT",
        "path": "ExceptionParameter/ROOT",
        "repetitive": false,
        "children": [ /* hijos con path completo */ ],
        "defaultValue": null
      },
      "typeName": "InputTextboxComponent",
      "draggable": true
    }
  ],
  "primaryDataSource": {
    "name": "ExceptionParameter",
    "type": "Parameter",
    "isVariable": false,
    "isSystemParameter": false,
    "parameterDirection": 3,
    "parameterType": 2,
    "children": [ /* estructura recursiva completa */ ],
    "defaultValue": ""
  },
  "typeName": "InputTextboxComponent",
  "draggable": true
}
```

**Path formato XML:** `{paramName}/ROOT/{childName}` (recursivo, sin limite de profundidad).

Cada nivel de la jerarquia repite la estructura `{ label, icon, children, primaryDataSource, typeName, draggable }`.

### Variables de sistema

Siempre presentes. Se agregan automaticamente al Primary DataSource.

**StartEvent tiene 2 variables:**

| Variable | path | parameterDirection | parameterType | isVariable |
|---|---|---|---|---|
| ExceptionParameter | (XML, ver arriba) | 3 (Optional) | 2 (XML) | false |
| OutputParameter | OutputParameter/OutputParameter/Value | 2 (Out) | 1 (SingleValue) | false |

**UserTask tiene las 2 anteriores + 2 variables adicionales:**

| Variable | path | parameterDirection | parameterType | isVariable |
|---|---|---|---|---|
| InstanceId | InstanceId/InstanceId/Value | 3 (Optional) | 1 (SingleValue) | **true** |
| LoggedUser | LoggedUser/LoggedUser/Value | 3 (Optional) | 1 (SingleValue) | **true** |

**StartEvent NO tiene InstanceId/LoggedUser.**

---

## DataSource: "Actividades Anteriores"

Nombre exacto: `"Actividades Anteriores"` (sin tilde).

### StartEvent: NO tiene "Actividades Anteriores"

Verificado contra BPMN real: el StartEvent solo tiene 1 DataSource ("Parametros y Variables"). El DataSource "Actividades Anteriores" NO se incluye porque no hay actividades previas al inicio del proceso.

### Schema poblado (UserTask)

Se puebla con los outputs de actividades previas que pueden servir como fuente de datos. Ejemplo real del BPMN (actividad SQL "getsql"):

```json
{
  "name": "Actividades Anteriores",
  "isPrimary": true,
  "primarySchema": [
    {
      "label": "getsql",
      "icon": "",
      "children": [
        {
          "label": "NewDataSet",
          "icon": "",
          "children": [
            {
              "label": "Table",
              "icon": "./assets/img/AllFieldsInDatabase_16x.svg",
              "children": [
                {
                  "label": "CustomerID",
                  "primaryDataSource": {
                    "name": "CustomerID",
                    "path": "getsql/NewDataSet/Table/CustomerID",
                    "valueType": "String",
                    "repetitive": false,
                    "children": [],
                    "defaultValue": null
                  },
                  "typeName": "InputTextboxComponent",
                  "draggable": true
                }
              ],
              "primaryDataSource": {
                "name": "Table",
                "path": "getsql/NewDataSet/Table",
                "repetitive": true,
                "children": [ /* todas las columnas */ ],
                "defaultValue": null
              },
              "typeName": "TableComponent",
              "draggable": true
            }
          ]
        }
      ],
      "primaryDataSource": {
        "name": "getsql",
        "type": "Activity",
        "repetitive": false,
        "children": [ /* estructura completa */ ],
        "defaultValue": null
      },
      "typeName": "InputTextboxComponent",
      "draggable": true
    }
  ],
  "events": []
}
```

### Tipos de actividad y CanUseAsSource

| Tipo | CanUseAsSource | Formato path |
|---|---|---|
| SQL | Si | `{activityId}/NewDataSet/Table/{columnName}` |
| REST API | Si | `{activityId}/{responseField}` |
| UserTask | Si | `{activityId}/{paramName}` |
| SetValue | Si | `{activityId}/Result` |
| CallActivity | Si | `{activityId}/{outputParam}` |
| SendMessage | Si | `{activityId}/{outputParam}` |
| JSON Converter | Si | `{activityId}/{rootElement}` |
| HL7 | Si | `{activityId}/HL7/{segment}` |
| For Loop | Si | `{activityId}/{item}` |
| Email | No | N/A |
| Delay | No | N/A |
| Exception | No | N/A |
| Sequence | No | N/A |

**Nota:** Para tablas SQL, `repetitive: true` en el nodo `Table`. El `typeName` del nodo Table es `"TableComponent"` (no InputTextbox).

### Multiples paths

Si un gateway exclusivo precede al UserTask, el schema incluye la union de outputs de TODAS las actividades que pueden preceder. Deduplicar por activityId: si la misma actividad aparece en multiples paths, incluir su schema una sola vez.

---

## DataSources Secundarios

Los data sources no-primarios (SQL, REST, BizuitServer) van en el mismo array `dataSources[]` con `isPrimary: false`.

### SqlDataSource

```json
{
  "name": "MiConsulta",
  "isPrimary": false,
  "props": [
    {
      "class": "SqlDataSourcePropertiesComponent",
      "name": "MiConsulta",
      "controllerType": 0,
      "connectionSource": 1,
      "connectionString": "BizuitDB",
      "query": "SELECT * FROM Clientes WHERE Id = @Id",
      "parameters": [
        { "name": "@Id", "value": "", "direction": 0, "dataType": 0 }
      ],
      "executeOnStart": true,
      "paginateResults": false,
      "pageSize": 10,
      "timeout": 100,
      "requestStructure": "",
      "responseStructure": "",
      "useCache": false,
      "cacheTime": 30
    }
  ]
}
```

`connectionSource`: 0=Text (string literal), 1=Configuration (referencia a nombre de config). **Siempre usar 1 (Configuration)** — nunca incluir connection strings literales.

### RestAPIDataSource

```json
{
  "name": "MiAPI",
  "isPrimary": false,
  "props": [
    {
      "class": "RestAPIDataSourcePropertiesComponent",
      "URL": "https://api.ejemplo.com/datos",
      "method": "GET",
      "timeout": 5,
      "bearerToken": "",
      "userName": "",
      "userPassword": "",
      "addHeaders": false,
      "headers": [],
      "useAuth": false,
      "authorizationType": "Basic Auth",
      "useBody": false,
      "bodyType": "multipart/form-data",
      "bodySubType": "text/plain",
      "txtBody": "",
      "parameters": [],
      "rawParameters": [],
      "executeOnStart": false,
      "requestStructure": "",
      "responseStructure": "",
      "useCache": false,
      "cacheTime": 30,
      "authorizationUrl": "",
      "clientId": "",
      "clientSecret": "",
      "scope": "",
      "generateOauthToken": false,
      "inferStructure": false
    }
  ]
}
```

**Seguridad:** credenciales siempre vacias en generacion. Se configuran en editor.

---

## Regla isPrimary y presencia de DataSources

**"Parametros y Variables"** → `isPrimary: true` — SIEMPRE presente (StartEvent y UserTask)

**"Actividades Anteriores"** → `isPrimary: true` — SOLO en UserTask. **StartEvent NO tiene este DataSource** (verificado contra BPMN real: StartEvent tiene 1 DS, UserTask tiene 2 DS).

Los secundarios (SQL, REST, BizuitServer) llevan `isPrimary: false`.

---

## Ejemplo con Caracteres Especiales

Los nombres de parametros con tildes, enes, y comillas sobreviven el triple encoding:

- Parametro `"Descripcion"` → path: `"Descripcion/Descripcion/Value"` — la tilde se preserva en JSON y se HTML-encoda en BPMN (paso 4)
- En BPMN attr: `Descripci&oacute;n` o se preserva como UTF-8 segun el encoding del XML
- En VDW `<Design>`: se preserva como UTF-8 directo (no hay HTML-encoding)
- Las comillas dentro de valores se escapan en cada nivel: `"` → `\"` → `\\\"` → `&#34;`

# Generacion de Forms — DataSources Secundarios y Actividades Anteriores

> Complemento de form-generation.md. Se carga cuando el spec incluye DataSources secundarios o el form es para UserTask con actividades previas.
> Referencia: Paso 3b y Paso 3c del flujo de generacion.

---

## Paso 3b: DataSources Secundarios (SQL + REST)

Los DataSources secundarios alimentan ComboBox, RadioButton y otros controles con datos dinamicos. Se generan SOLO si el `detalle-tecnico.md` documenta la seccion DataSources.

**Sin detalle-tecnico.md:** generar form SIN DataSources secundarios + WARNING "Sin detalle-tecnico.md — form generado sin DataSources secundarios". El Primary DS se genera normalmente (no depende de detalle-tecnico).

### SqlDataSource template

```json
{
  "name": "{dsName}",
  "isPrimary": false,
  "props": [{
    "class": "SqlDataSourcePropertiesComponent",
    "name": "{dsName}",
    "controllerType": 0,
    "connectionSource": 1,
    "connectionString": "{configName}",
    "query": "{sqlQuery}",
    "parameters": [],
    "executeOnStart": true,
    "paginateResults": false,
    "pageSize": 10,
    "timeout": 100,
    "requestStructure": "",
    "responseStructure": "",
    "useCache": false,
    "cacheTime": 30
  }]
}
```

- `connectionSource`: **SIEMPRE 1** (Configuration, NFR45). NUNCA 0 (connection string literal). NUNCA incluir connection strings en el JSON.
- `connectionString`: nombre de la configuracion (ej: `"ProveedoresDB"`), NO la cadena de conexion.
- `parameters`: array de `{ "name": "@paramName", "value": "{path}", "direction": 0, "dataType": 0 }`. El `value` es path al dato fuente, ej: `"Parametros y Variables/pCategoriaId/pCategoriaId/Value"`.
- Query parametrizada (`@params`): agregar cada `@param` al array `parameters`.

### RestAPIDataSource template

```json
{
  "name": "{dsName}",
  "isPrimary": false,
  "props": [{
    "class": "RestAPIDataSourcePropertiesComponent",
    "URL": "{url}",
    "method": "{GET|POST}",
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
    "executeOnStart": true,
    "requestStructure": "",
    "responseStructure": "{structure}",
    "useCache": false,
    "cacheTime": 30,
    "authorizationUrl": "",
    "clientId": "",
    "clientSecret": "",
    "scope": "",
    "generateOauthToken": false,
    "inferStructure": false
  }]
}
```

- Credenciales **SIEMPRE vacias** (NFR45): `bearerToken`, `userName`, `userPassword`, `clientId`, `clientSecret` = `""`. Se configuran en editor.
- REST con OAuth: generar estructura, credenciales vacias + nota "configurar autenticacion en editor".
- `responseStructure`: documentar la estructura de respuesta si el spec la provee, sino dejar vacio.

### Reglas de executeOnStart (Pattern 21)

| Uso del DataSource | executeOnStart |
|---|---|
| Alimenta PopulationProperty de ComboBox/RadioButton | `true` |
| Precarga datos para labels/valores iniciales | `true` |
| Invocado por boton/evento (ej: "Buscar") | `false` |
| Spec no indica uso | `true` (default — mejor combo lleno que vacio) |

### Poblacion de ComboBox

| Situacion | Accion |
|---|---|
| Lista fija en spec (ej: `[Activo, Inactivo, Suspendido]`) | FixedList con `items: [{value:"Activo",label:"Activo"}, ...]`. NO generar DS secundario. |
| Dinamico con SQL documentado en detalle-tecnico | PopulationProperty con `sourceType: "DataSource"`, `dataSourceElement` apuntando al SqlDataSource. |
| Dinamico sin info de DS | PopulationProperty vacia + TODO "configurar DataSource para '{fieldName}' en editor BizuitForms" |

### Combos en cascada (combo dependiente de otro)

- Primer combo: DS con `executeOnStart: true`
- Combo dependiente: DS con `executeOnStart: false` + TODO "configurar evento de cambio en editor" (events no se generan per NFR45, `CustomCodePropertiesComponent.events` SIEMPRE `[]`)

---

## Paso 3c: Actividades Anteriores (solo UserTasks)

**CRITICO: StartEvent NO tiene este DataSource.** Solo UserTasks tienen el DS "Actividades Anteriores" como segundo DS (verificado contra BPMN real: StartEvent tiene 1 DS, UserTask tiene 2 DS).

### Construccion del schema por tipo de actividad

9 tipos con output (`CanUseAsSource = true`):

| Tipo | Path formato | repetitive |
|---|---|---|
| SQL | `{act}/NewDataSet/Table/{col}` | `true` en nodo Table |
| REST | `{act}/{responseField}` | `true` en nodos array |
| UserTask | `{act}/{paramName}` | `false` |
| SetValue | `{act}/Result` | `false` |
| CallActivity | `{act}/{outputParam}` | `false` |
| SendMessage | `{act}/{outputParam}` | `false` |
| JSON Converter | `{act}/{rootElement}` | `false` |
| HL7 | `{act}/HL7/{segment}` | `false` |
| For Loop | `{act}/{item}` | `false` |

4 tipos **sin output** (`CanUseAsSource = false`) — NUNCA aparecen en el schema:

- Email, Delay, Exception, Sequence

NO emitir warning por exclusion de estos 4 tipos (es comportamiento normal).

### Template JSON — entrada en primarySchema (ejemplo SQL)

Ejemplo real basado en BPMN fixture (actividad SQL "getsql" con columnas CustomerID, CompanyName):

```json
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
              "icon": "",
              "children": [],
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
            },
            {
              "label": "CompanyName",
              "icon": "",
              "children": [],
              "primaryDataSource": {
                "name": "CompanyName",
                "path": "getsql/NewDataSet/Table/CompanyName",
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
            "children": [
              { "name": "CustomerID", "path": "getsql/NewDataSet/Table/CustomerID", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
              { "name": "CompanyName", "path": "getsql/NewDataSet/Table/CompanyName", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }
            ],
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
    "children": [
      {
        "name": "NewDataSet",
        "path": "getsql/NewDataSet",
        "repetitive": false,
        "children": [
          {
            "name": "Table",
            "path": "getsql/NewDataSet/Table",
            "repetitive": true,
            "children": [
              { "name": "CustomerID", "path": "getsql/NewDataSet/Table/CustomerID", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
              { "name": "CompanyName", "path": "getsql/NewDataSet/Table/CompanyName", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }
            ],
            "defaultValue": null
          }
        ],
        "defaultValue": null
      }
    ],
    "defaultValue": null
  },
  "typeName": "InputTextboxComponent",
  "draggable": true
}
```

**Nodos clave:**
- Nodo raiz: `type: "Activity"`, `repetitive: false`
- SQL: intermedio `NewDataSet` > `Table` con `repetitive: true`, `typeName: "TableComponent"`. Columnas como hojas con `typeName: "InputTextboxComponent"`
- SQL icon en nodo Table: `"./assets/img/AllFieldsInDatabase_16x.svg"`
- REST: campos directos bajo la actividad. Nodos array con `repetitive: true`
- UserTask: parametros directos bajo la actividad (path `{act}/{param}`)

### Template JSON — entrada generica (no SQL)

Para actividades que no son SQL (REST, UserTask, SetValue, etc.), la estructura es mas plana:

```json
{
  "label": "{activityName}",
  "icon": "",
  "children": [
    {
      "label": "{outputField}",
      "icon": "",
      "children": [],
      "primaryDataSource": {
        "name": "{outputField}",
        "path": "{activityName}/{outputField}",
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
    "name": "{activityName}",
    "type": "Activity",
    "repetitive": false,
    "children": [
      { "name": "{outputField}", "path": "{activityName}/{outputField}", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }
    ],
    "defaultValue": null
  },
  "typeName": "InputTextboxComponent",
  "draggable": true
}
```

### Multiples paths (gateway merge)

Cuando un gateway precede al UserTask y confluyen multiples ramas:

| Gateway | Regla de union |
|---|---|
| ExclusiveGateway | Union de TODAS las actividades de todos los paths posibles (solo 1 ejecuta, pero incluir todos) |
| ParallelGateway | Union de AMBAS ramas (ambas ejecutan) |
| InclusiveGateway | Union de TODAS las ramas que pueden ejecutar |

**Deduplicacion:** si la misma actividad (por activityId) aparece en multiples paths, incluir su schema UNA sola vez. El viewer filtra en runtime cual es relevante.

### Sin outputMapping documentado

Si una actividad previa que TIENE `CanUseAsSource=true` pero NO tiene `outputMapping` documentado en `detalle-tecnico.md`: **excluir** de Actividades Anteriores + WARNING "Actividad '{name}' excluida de Actividades Anteriores: sin outputMapping documentado en detalle-tecnico.md".

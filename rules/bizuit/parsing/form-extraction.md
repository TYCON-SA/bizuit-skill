# Extraccion de Forms desde VDW

> Rule para extraer informacion de forms BizuitForms desde elementos `<Design>` del VDW.
> Usada por `workflows/reverse.md` y `workflows/query.md`.
> Produce estructura parseada en contexto (controles, bindings, DataSources, discrepancias).
> NO retorna un objeto formal — genera texto estructurado que el workflow consumidor formatea.

---

## Entrada

- **JSON string**: contenido del elemento `<Design>` dentro de `<ConnectorInfo>` del VDW (JSON plano, no HTML-encoded)
- **activityName**: nombre de la actividad (`<ActivityName>` del ConnectorInfo)
- **parametros del proceso**: lista de parametros definidos en el VDW (para deteccion de discrepancias)

### Variantes de ubicacion del ConnectorInfo en VDW

El `<ConnectorInfo>` puede aparecer en dos formatos segun la version del VDW:

1. **Formato directo:** `<DesignTimeProperties><Connectors><ConnectorInfo>...<Design>JSON</Design></ConnectorInfo></Connectors>`
2. **Formato anyType (.NET serialized):** `<DesignTimeProperties><Connectors><anyType xsi:type="ConnectorInfo">...<Design>JSON</Design></anyType></Connectors>`

Ambos formatos contienen la misma estructura interna. Buscar AMBOS patrones al parsear el VDW. El formato `<anyType>` es comun en procesos reales (ej: TFG_VisadoBiblio v62).

---

## Mapeo ConnectorType a tipo de actividad

| ConnectorType en VDW | Tipo de actividad |
|---|---|
| `Workflow` | StartEvent |
| `HandlerActivity` | UserTask |

Si `ConnectorType` no coincide con ninguno → documentar como "tipo desconocido: {ConnectorType}" + WARNING.

---

## Algoritmo de extraccion

### Paso 1: Parsear JSON del `<Design>`

1. Intentar `JSON.parse` del contenido de `<Design>`
2. **Si falla** (JSON malformado, truncado, encoding roto):
   - Documentar: "(form con JSON invalido — no se pudo extraer)"
   - Emitir WARNING con detalle del error de parsing
   - **Terminar** — el reverse del resto del VDW continua normalmente
   - La spec se genera completa excepto la tabla de forms para esta actividad
3. **Si exito** → extraer form object (contiene `controls`, `dataSources`, metadata)

### Paso 2: Extraer controles con binding activo

Del JSON parseado, navegar a `controls` (string JSON → parsear). Buscar el `MainFormComponent` y recorrer su `children[]`.

**Para cada control hijo:**

1. **Filtrar**: incluir SOLO controles con binding activo. Excluir:
   - `HeaderComponent` (sin binding)
   - `ContainerComponent` / `ContainerFlexComponent` (layout — pero **recorrer recursivamente sus children**)
   - `SeparatorComponent` (decorativo)
   - `StepperComponent` (layout — pero **recorrer recursivamente sus children/steps**)
   - Controles sin `BindingsPropertiesComponent` en sus props

2. **Extraer por control incluido:**

   **IMPORTANTE: estructura de `props`** — Cada control tiene un campo `props` que es un **ARRAY de objetos** (NO un dict). Cada objeto tiene un campo `class` que identifica su tipo. Para acceder a una prop específica, buscar en el array el objeto con `class == "NombreDeLaProp"`. Ejemplo:
   ```
   props: [
     { "class": "BasicPropertiesComponent", "name": "txtNombre", "label": "Nombre", ... },
     { "class": "BindingsPropertiesComponent", "primaryDataSource": { "path": "..." }, ... },
     { "class": "RestrictionsPropertiesComponent", "required": false, "dataType": "String", ... }
   ]
   ```
   Para obtener el binding: `props.find(p => p.class == "BindingsPropertiesComponent").primaryDataSource.path`

   Campos a extraer:
   - `component`: tipo de control (ej: `InputTextboxComponent`, `CheckboxComponent`)
   - `name`: de `props[class=BasicPropertiesComponent].name`
   - `label`: de `props[class=BasicPropertiesComponent].label`
   - `binding`: de `props[class=BindingsPropertiesComponent].primaryDataSource.path`
   - `required`: de `props[class=RestrictionsPropertiesComponent].required` (default: false)
   - `dataType`: de `props[class=RestrictionsPropertiesComponent].dataType` (default: "String")

3. **Recorrido recursivo de containers**: Si el control es un `ContainerComponent`, `ContainerFlexComponent`, `StepperComponent`, `TabComponent`, o `CardComponent` → recorrer recursivamente sus `children[]` buscando controles con binding. Los containers pueden estar anidados (Container dentro de Container). Ejemplo real: MainForm > Container1 > [txtNombre, txtApellido, txtNroDoc, ...] (13 controles dentro de un Container en TFG_VisadoBiblio).

### Paso 3: Extraer DataSources

Del JSON parseado, navegar a `dataSources` (string JSON → parsear).

**Clasificar cada DS:**

| Condicion | Tipo |
|---|---|
| `isPrimary: true` y `name: "Parametros y Variables"` | Primary (no listar como secundario) |
| `isPrimary: true` y `name: "Actividades Anteriores"` | Actividades Anteriores (documentar schema) |
| Tiene prop `SqlDataSourcePropertiesComponent` | SQL secundario |
| Tiene prop `RestAPIDataSourcePropertiesComponent` | REST secundario |

**Para DS secundarios (SQL):**
- `name`: nombre del DataSource
- `tipo`: "SQL"
- `connectionSource`: `connectionString` del prop (nombre de configuracion, NO literal)
- `executeOnStart`: valor booleano

**Para DS secundarios (REST):**
- `name`: nombre del DataSource
- `tipo`: "REST"
- `URL`: del prop `URL`
- `method`: del prop `method`
- `executeOnStart`: valor booleano

### Paso 4: Extraer Actividades Anteriores

**Solo para UserTask** (ConnectorType="HandlerActivity"). StartEvent NO tiene este DS.

Buscar DS con `name: "Actividades Anteriores"` en dataSources[].
- Si `primarySchema` esta vacio → "sin actividades anteriores con output"
- Si `primarySchema` tiene entradas → documentar cada actividad con sus paths disponibles:
  - Para cada entrada en primarySchema: nombre de actividad + paths (recorrer children recursivamente)
  - SQL: paths bajo `NewDataSet/Table/{columna}`
  - REST: paths directos bajo la actividad
  - UserTask/SetValue/otros: paths directos

### Paso 5: Detectar discrepancias

Comparar controles extraidos vs parametros del proceso:

**Discrepancia 1 — Parametro sin binding en form:**
- Para cada parametro de negocio del proceso (excluir sistema: ExceptionParameter, OutputParameter, InstanceId, LoggedUser)
- Si NO existe control con binding que apunte a ese parametro → WARNING
- Documentar: "Parametro '{paramName}' sin binding en form"
- Aplica tanto a StartEvent como a UserTask

**Discrepancia 2 — Control con binding a parametro inexistente:**
- Para cada control con binding activo en el form
- Extraer nombre del parametro del path de binding (primer segmento del path, ej: `pNombre/pNombre/Value` → `pNombre`)
- Si ese parametro NO existe en la lista de parametros del proceso → WARNING
- Documentar: "Control bindeado a '{paramName}' — parametro no encontrado en spec"

**Nota:** Ambas discrepancias son WARNING, no ERROR. Pueden ser intencionales.

---

## Estructura de salida (en contexto)

La informacion extraida se organiza en el flujo de contexto como:

1. **Lista de controles** con: component, name, label, binding, required, dataType
2. **Lista de DataSources secundarios** con: name, tipo, connection/URL, executeOnStart
3. **Schema de Actividades Anteriores** con: actividad, paths disponibles
4. **Lista de discrepancias** con: tipo (param-sin-binding / control-sin-param), detalle, severidad (WARNING)

El workflow consumidor (reverse.md o query.md) toma esta informacion y la formatea segun su necesidad (tabla markdown, lista, etc.).

---

## Ejemplo de parsing

Dado un `<ConnectorInfo>` de VDW con:
- `<ConnectorType>HandlerActivity</ConnectorType>`
- `<ActivityName>AprobarSolicitud</ActivityName>`
- `<Design>` con JSON que contiene form con 3 controles (pNombre, pMonto, pAprobado)

**Resultado en contexto:**

Controles extraidos:
- pNombre: InputTextboxComponent, binding=pNombre/pNombre/Value, required=true, dataType=String
- pMonto: InputTextboxComponent, binding=pMonto/pMonto/Value, required=true, dataType=Double
- pAprobado: CheckboxComponent, binding=pAprobado/pAprobado/Value, required=false, dataType=String

DataSources secundarios: (ninguno en este ejemplo)

Actividades Anteriores: (schema vacio — sin actividades anteriores con output)

Discrepancias: (ninguna — todos los parametros tienen binding y viceversa)

---

## Degradacion graceful

| Situacion | Comportamiento |
|---|---|
| JSON corrupto en `<Design>` | Skip + WARNING con detalle del error. Resto del VDW se parsea normal. |
| VDW sin `<ConnectorInfo>` para actividad | No es error — documentar "(sin form configurado)" |
| Form con controles custom (no en tabla conocida) | Documentar como tipo tal cual aparece en JSON |
| Form con DS sin query (configuracion incompleta) | Documentar tipo y nombre + nota "configuracion incompleta" |
| `<Design>` vacio (string vacio) | Tratar como "sin form" — nota informativa |
| Controles sin binding (Labels, Headers, Containers) | Excluir de tabla de controles — solo controles con binding activo |
| `<anyType xsi:type="ConnectorInfo">` en vez de `<ConnectorInfo>` | Tratar identico — buscar ambos patrones |
| Containers anidados (Container dentro de Container) | Recorrer recursivamente hasta encontrar controles con binding |
| Credentials visibles en form | Reemplazar con "***" (NFR11) — no copiar literalmente |

---

## Seguridad

- Esta rule es READ-ONLY — no modifica el VDW ni genera JSON
- NO ejecutar codigo del form (events siempre ignorados)
- Si el form contiene credentials visibles → reemplazar con "***" en el output

# Generacion de Forms BizuitForms (~290 lineas core + datasources en archivo separado)

> Rule self-contained para generar forms BizuitForms embebidos en BPMN.
> NO carga rules de referencia. Todo lo necesario esta inline.
> Para DataSources secundarios y Actividades Anteriores, ver `form-generation-datasources.md`.
> SYNC: si se agrega tipo de control, actualizar tambien bizuit-forms-controls.md

---

## Cuando generar forms

| Actividad | Condicion | Accion |
|---|---|---|
| StartEvent | Canal manual/usuario/mensaje (FR56) | Generar form |
| StartEvent | Canal timer/signal/API sin UI | NO generar form (sin warning) |
| StartEvent | Canal no reconocido | Generar form + WARNING "canal no reconocido, asumido inicio humano" |
| UserTask | Con campos o acciones en spec | Generar form |
| UserTask | Sin campos NI acciones | Form minimo (Header + 2 botones) + WARNING "UserTask '{name}' sin campos" |
| ServiceTask, Gateway, otros | Siempre | NO generar form |

---

## Mise en place (preparacion)

Antes de generar forms, extraer del spec para CADA actividad:

1. **Campos**: nombre, tipo dato, direccion (In/Out/Optional), required
2. **Acciones**: nombre, tipo — SOLO si spec las define explicitamente
3. **Parametros del proceso**: para alimentar Primary DataSource
4. **Canal de entrada** del StartEvent (FR56)
5. **DisplayName** de la actividad y nombre del proceso (para Header)

---

## Modo Generate (desde cero)

### Paso 1: MainFormComponent

Template FIJO — solo `children` varia:

```json
{
  "name": "form_{activityId}",
  "component": "MainFormComponent",
  "x": 0, "y": 0, "rows": 0, "cols": 0,
  "props": [
    {
      "class": "BasicPropertiesComponent",
      "name": "form_{activityId}", "title": "PROPERTIES.BASIC.TITLE",
      "label": "form_{activityId}", "value": "", "tooltip": "",
      "tooltipPosition": "above", "font": "Quicksand",
      "align": "center-container", "fontWeight": "normal",
      "fontColor": "#000000", "backgroundColor": "#FFFFFF", "fontSize": 12,
      "enabled": true, "parentEnabled": true, "visible": true,
      "vertical": false, "fontEffectLineThrough": false,
      "fontEffectUnderline": false, "properties": ["backgroundColor"],
      "labelValue": "value", "layer": 1,
      "validateOnHiddenControl": false, "isSubForm": false,
      "isMainForm": true
    },
    {
      "class": "FormPropertiesComponent",
      "title": "PROPERTIES.FORM.TITLE", "showMessageOnSuccess": true,
      "messagesParametersOnSuccess": [],
      "messageOnSuccess": "La operacion se completo con exito.",
      "showMessageOnError": true, "messageOnError": "Ha ocurrido un error.",
      "closeOnSuccess": true, "controlType": "standard",
      "cols": 6, "rowHeight": 70, "themeUseDefaultSettings": true,
      "theme": "bizuit", "modalType": "swal", "modalTitle": "",
      "modalUseOKButton": true, "modalUseTimer": false,
      "modalUseDefaultSettings": true, "modalTimeout": 0,
      "useRaiseEventAsync": false, "processingWaitTime": 5,
      "useOpenFormSettings": false, "openFormType": "DIALOG",
      "splitType": "NONE", "formSize": "ORIGINAL_SIZE",
      "showModalTitle": true
    },
    {
      "class": "CustomCodePropertiesComponent",
      "events": [], "focusOn": null, "basicEvent": 1,
      "selectedSecondaryDatasources": [],
      "selectedSecondaryDatasource": "",
      "selectedColumnTrace": 0, "executeValidation": true,
      "selectedSubForm": "",
      "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" },
      "addDocumentsToDataSource": false, "selectedDocumentControl": "",
      "modalType": "swal", "modalTitle": "", "modalMessage": "",
      "modalUseOKButton": true, "modalUseTimer": false,
      "modalTimeout": 5, "showMessageOnSuccess": true,
      "clearControlsAfterExecute": false
    },
    { "class": "CustomStylesPropertiesComponent", "cssCode": "" }
  ],
  "children": [ /* controles generados — ver Pasos 2-5 */ ],
  "layerIndex": 1
}
```

### Paso 2: Controles

**Tabla de mapeo tipo spec a control:**

| Tipo spec | Component | cols | dataType |
|---|---|---|---|
| string | InputTextboxComponent | 3 | String |
| string largo* | TextareaComponent | 6 | String |
| numero/entero | InputTextboxComponent | 3 | Integer |
| numero/decimal | InputTextboxComponent | 3 | Double |
| boolean | CheckboxComponent | 2 | String |
| fecha/datetime | DatePickerComponent | 2 | DateTime |
| seleccion/combo | ComboboxComponent | 3 | String |
| radio (<5 opciones) | RadioButtonComponent | 2 | String |
| toggle | SlideToggleComponent | 2 | String |
| archivo/adjunto | DocumentInputComponent | 6 | — |
| firma | SignatureComponent | 6 | — |
| ubicacion/GPS | GeolocationComponent | 6 | — |
| tabla editable | TableComponent | 6 | — |
| subformulario | SubFormComponent | 6 | — |
| imagen/video | MediaComponent | 6 | — |
| iframe/embed | IframeComponent | 6 | — |
| tipo desconocido | InputTextboxComponent | 3 | String |

*Heuristica string largo: nombre del campo contiene "observaciones", "descripcion", "comentarios", "notas" o "detalle" (case-insensitive) -> TextareaComponent.

**Fallbacks con WARNING:**
- Tipo desconocido -> InputTextboxComponent + WARNING "Tipo '{tipo}' no reconocido para campo '{nombre}'. Se genero InputTextbox como fallback."
- Parametro sin tipo en spec -> InputTextboxComponent + WARNING "Campo '{nombre}' sin tipo definido, asumido texto."

**Property stack por control generado (InputTextbox como ejemplo):**

```json
{
  "name": "{paramName}", "component": "InputTextboxComponent",
  "x": 0, "y": 0, "rows": 1, "cols": 3,
  "props": [
    {
      "class": "BasicPropertiesComponent",
      "name": "{paramName}", "title": "PROPERTIES.BASIC.TITLE",
      "label": "{labelSanitizado}", "value": "", "tooltip": "",
      "tooltipPosition": "above", "font": "Quicksand",
      "align": "center-container", "fontWeight": "inherit",
      "fontColor": "#000000", "backgroundColor": "#FFFFFF", "fontSize": 12,
      "enabled": true, "parentEnabled": true, "visible": true,
      "vertical": false, "fontEffectLineThrough": false,
      "fontEffectUnderline": false,
      "properties": ["label","font","fontWeight","fontColor","fontSize","enabled","visible","tooltip","validateOnHiddenControl"],
      "labelValue": "value", "layer": 1,
      "validateOnHiddenControl": false, "isSubForm": false,
      "isMainForm": false
    },
    {
      "class": "BindingsPropertiesComponent",
      "title": "PROPERTIES.BINDINGS.TITLE", "bindigSource": "",
      "secondaryDataSourcesRequest": [], "secondaryDataSourceResponse": {},
      "bindToProcessExecution": false,
      "primaryDataSource": { /* del Primary DS — ver Paso 3 */ },
      "primaryComboTextDataSource": {},
      "subFormResponse": { "name": "", "item": null },
      "subFormRequests": []
    },
    {
      "class": "RestrictionsPropertiesComponent",
      "required": false, "dataType": "String",
      "lengthType": "Variable", "fixedLength": 0,
      "minLength": 0, "maxLength": 0, "minValue": 0, "maxValue": 0,
      "totalDigits": 0, "minValueIncluded": false, "maxValueIncluded": false,
      "decimalDigits": 0,
      "dateTimeMinValueType": "Absolute", "dateTimeMaxValueType": "Absolute",
      "dateTimeMinValue": null, "dateTimeMaxValue": null,
      "timeMinValue": null, "timeMaxValue": null,
      "dateTimeMinValueIncluded": false, "dateTimeMaxValueIncluded": false,
      "dateTimeMinValueRelativeIncluded": false,
      "dateTimeMaxValueRelativeIncluded": false,
      "dateTimeMinValueRelativeOperation": "Add",
      "dateTimeMaxValueRelativeOperation": "Add",
      "dateTimeMinValueRelativePeriod": "Days",
      "dateTimeMaxValueRelativePeriod": "Days",
      "dateTimeMinValueRelativeValue": 0,
      "dateTimeMaxValueRelativeValue": 0,
      "dateTimeMinPanel": false, "dateTimeMaxPanel": false,
      "minRows": 1, "maxRows": 5,
      "dataTypeBooleanControl": "String",
      "checkValue": "true", "uncheckValue": "false",
      "dateTimeValueType": "Relative",
      "dateTimeValueRelativeOperation": "Add",
      "dateTimeValueRelativePeriod": "Days",
      "dateTimeValueRelativeValue": 0,
      "datePickerValue": "{ISO_TIMESTAMP}",
      "format": "Short", "customFormat": "YYYY-MM-DD",
      "properties": ["required"], "regexPattern": "",
      "dateTimeMinValueRelativeSource": "TODAY",
      "dateTimeMaxValueRelativeSource": "TODAY",
      "dateTimeMinValueRelativeControlName": "",
      "dateTimeMaxValueRelativeControlName": ""
    },
    { "class": "ValidationsPropertiesComponent", "title": "PROPERTIES.VALIDATIONS.TITLE", "match": "ANY", "errorMessage": "", "rules": [] },
    { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
    { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
    { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 1, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": true, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
  ],
  "children": [],
  "layerIndex": 1
}
```

**Ajustes por tipo de control:**
- **Checkbox/SlideToggle**: Restrictions con `checkValue: "true"`, `uncheckValue: "false"`. Sin ValidationsPropertiesComponent (no incluir en props[]).
- **DatePickerComponent**: NO incluir CustomStylesPropertiesComponent (verificar contra fixture). Restrictions con `format: "Short"`.
- **Combobox**: Agregar PopulationPropertiesComponent despues de Restrictions: `{ "class": "PopulationPropertiesComponent", "sourceType": "DataSource", "dataSourceElement": null, "dataSourceItemText": "", "dataSourceItemValue": "", "fixedList": [], "keyValueList": [], "defaultElementNone": true, "defaultElementIndex": 0, "addEmptyItem": false, "EmptyItemText": "", "EmptyItemValue": 0, "multiple": false, "autocomplete": false, "controlType": "Combobox", "separator": ",", "valueAsJson": false, "items": [] }`.
- **RadioButton**: Misma PopulationPropertiesComponent con `controlType: "RadioButton"`.
- **DocumentInput**: Solo Basic + DocumentPropertiesComponent + Formatting + CustomCode (sin Bindings, Restrictions, Validations).
- **Textarea**: Property stack = Basic, Bindings, Restrictions, CustomCode, Validations, Formatting, CustomStyles (orden distinto a InputTextbox).

**Sanitizar labels**: strip HTML tags del spec. Ej: `"Nombre del <b>Solicitante</b>"` -> `"Nombre del Solicitante"`.

**REGLA**: `CustomCodePropertiesComponent.events` SIEMPRE `[]`. `layerIndex: 1` en TODOS los controles. `class` como PRIMER campo en cada prop object.

### Paso 3: Primary DataSource

**Template base StartEvent (2 variables sistema):**

```json
{
  "name": "Parametros y Variables",
  "isPrimary": true,
  "primarySchema": [
    {
      "label": "ExceptionParameter", "icon": "",
      "children": [{
        "label": "ROOT", "icon": "",
        "children": [
          { "label": "Message", "icon": "", "children": [],
            "primaryDataSource": { "name": "Message", "path": "ExceptionParameter/ROOT/Message", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            "typeName": "InputTextboxComponent", "draggable": true },
          { "label": "Type", "icon": "", "children": [],
            "primaryDataSource": { "name": "Type", "path": "ExceptionParameter/ROOT/Type", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            "typeName": "InputTextboxComponent", "draggable": true },
          { "label": "StackTrace", "icon": "", "children": [],
            "primaryDataSource": { "name": "StackTrace", "path": "ExceptionParameter/ROOT/StackTrace", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            "typeName": "InputTextboxComponent", "draggable": true },
          { "label": "FaultingActivity", "icon": "", "children": [],
            "primaryDataSource": { "name": "FaultingActivity", "path": "ExceptionParameter/ROOT/FaultingActivity", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            "typeName": "InputTextboxComponent", "draggable": true }
        ],
        "primaryDataSource": { "name": "ROOT", "path": "ExceptionParameter/ROOT", "repetitive": false,
          "children": [
            { "name": "Message", "path": "ExceptionParameter/ROOT/Message", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            { "name": "Type", "path": "ExceptionParameter/ROOT/Type", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            { "name": "StackTrace", "path": "ExceptionParameter/ROOT/StackTrace", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            { "name": "FaultingActivity", "path": "ExceptionParameter/ROOT/FaultingActivity", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }
          ], "defaultValue": null },
        "typeName": "InputTextboxComponent", "draggable": true
      }],
      "primaryDataSource": { "name": "ExceptionParameter", "type": "Parameter", "isVariable": false, "isSystemParameter": false, "parameterDirection": 3, "parameterType": 2,
        "children": [{ "name": "ROOT", "path": "ExceptionParameter/ROOT", "repetitive": false,
          "children": [
            { "name": "Message", "path": "ExceptionParameter/ROOT/Message", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            { "name": "Type", "path": "ExceptionParameter/ROOT/Type", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            { "name": "StackTrace", "path": "ExceptionParameter/ROOT/StackTrace", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null },
            { "name": "FaultingActivity", "path": "ExceptionParameter/ROOT/FaultingActivity", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }
          ], "defaultValue": null }],
        "defaultValue": "" },
      "typeName": "InputTextboxComponent", "draggable": true
    },
    {
      "label": "OutputParameter", "icon": "", "children": [],
      "primaryDataSource": { "name": "OutputParameter", "path": "OutputParameter/OutputParameter/Value", "type": "Parameter", "valueType": "string", "isVariable": false, "isSystemParameter": false, "parameterDirection": 2, "parameterType": 1, "children": [], "defaultValue": "" },
      "typeName": "InputTextboxComponent", "draggable": true
    }
  ],
  "events": []
}
```

**Template base UserTask (4 variables sistema) — agregar despues de OutputParameter:**

```json
    {
      "label": "InstanceId", "icon": "", "children": [],
      "primaryDataSource": { "name": "InstanceId", "path": "InstanceId/InstanceId/Value", "type": "Parameter", "valueType": "string", "isVariable": true, "isSystemParameter": false, "parameterDirection": 3, "parameterType": 1, "children": [], "defaultValue": "" },
      "typeName": "InputTextboxComponent", "draggable": true
    },
    {
      "label": "LoggedUser", "icon": "", "children": [],
      "primaryDataSource": { "name": "LoggedUser", "path": "LoggedUser/LoggedUser/Value", "type": "Parameter", "valueType": "string", "isVariable": true, "isSystemParameter": false, "parameterDirection": 3, "parameterType": 1, "children": [], "defaultValue": "" },
      "typeName": "InputTextboxComponent", "draggable": true
    }
```

**StartEvent: NO tiene InstanceId ni LoggedUser. NO tiene "Actividades Anteriores" (solo 1 DS).**

**Agregar parametros de negocio del spec al primarySchema:**

- **Escalar** (parameterType: 1): path `{paramName}/{paramName}/Value`
  ```json
  {
    "label": "{paramName}", "icon": "", "children": [],
    "primaryDataSource": { "name": "{paramName}", "path": "{paramName}/{paramName}/Value", "type": "Parameter", "valueType": "string", "isVariable": false, "isSystemParameter": false, "parameterDirection": 1, "parameterType": 1, "children": [], "defaultValue": "" },
    "typeName": "InputTextboxComponent", "draggable": true
  }
  ```

- **XML** (parameterType: 2): path `{paramName}/ROOT/{childName}` (recursivo, sin limite profundidad)
  Estructura recursiva identica a ExceptionParameter pero con hijos del spec. Profundidad >10 -> cortar + WARNING.

**parameterDirection**: 1=In, 2=Out, 3=Optional. Parametro sin direction en spec -> default 1 (In) + WARNING.

**UserTask: tiene "Actividades Anteriores" como segundo DS** (schema poblado por story 9.2b):

```json
{ "name": "Actividades Anteriores", "isPrimary": true, "primarySchema": [], "events": [] }
```

> **Paso 3b (DS secundarios) y Paso 3c (Actividades Anteriores) extraidos a `form-generation-datasources.md`.**

### Paso 4: Layout (bin-packing en grid de 6 columnas)

```
y=0, x=0: HeaderComponent (cols=6, rows=1)

y=1, x=0:
Para cada control:
  cols = segun tabla de mapeo (Paso 2)
  if (x + cols > 6): y++, x=0
  control.x = x, control.y = y, control.rows = 1, control.cols = cols
  x += cols

Si 8+ campos -> StepperComponent:
  Agrupar por sub-secciones del spec (si hay "### Seccion" en detalle-tecnico)
  Sin sub-secciones -> agrupar cada 5 campos
  Cada step: { id: GUID, label: "{nombre seccion o 'Paso N'}", editable: true,
    backgroundColor: "#dedede", visible: true, columns: 6, validateChildren: true }
  Layout bin-packing aplica DENTRO de cada step

Botones: ultima fila, right-aligned
  x = 6 - (N_botones * 2)
  Cancelar primero, Enviar segundo
  Celdas vacias al final de fila son aceptables
```

### Paso 5: Botones (siempre 2 default)

**"Cancelar"** (basicEvent=4 Close, executeValidation=false):

```json
{
  "name": "btnCancelar", "component": "ButtonComponent",
  "x": 2, "y": "{lastRow}", "rows": 1, "cols": 2,
  "props": [
    { "class": "BasicPropertiesComponent", "name": "btnCancelar", "title": "PROPERTIES.BASIC.TITLE", "label": "Cancelar", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "inherit", "fontColor": "#FFFFFF", "backgroundColor": "#FFFFFF", "fontSize": 9, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["label","font","align","fontWeight","fontColor","fontSize","enabled","visible","tooltip"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": false },
    { "class": "ButtonPropertiesComponent", "backgroundColor": "primary", "title": "PROPERTIES.BUTTON.TITLE", "classType": "mat-raised-button", "icon": "", "width": null, "height": null },
    { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
    { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
    { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 4, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": false, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
  ],
  "children": [], "layerIndex": 1
}
```

**"Enviar"** (basicEvent=1 InvokeProcess, executeValidation=true): mismo template con `name: "btnEnviar"`, `label: "Enviar"`, `basicEvent: 1`, `executeValidation: true`, posicion `x` = Cancelar.x + 2.

**NUNCA** inferir botones de branches del gateway. Botones adicionales SOLO si el spec los define explicitamente.

### Paso 6: Header

Primer control en `children[]`, posicion fija:

```json
{
  "name": "header1", "component": "HeaderComponent",
  "x": 0, "y": 0, "rows": 1, "cols": 6,
  "props": [
    { "class": "BasicPropertiesComponent", "name": "header1", "title": "PROPERTIES.BASIC.TITLE", "label": "header1", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "inherit", "fontColor": "#000000", "backgroundColor": "#FFFFFF", "fontSize": 12, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["backgroundColor"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": false },
    { "class": "HeaderPropertiesComponent", "logo": "", "headerTitle": "{displayName sanitizado}", "headerTitleColor": "#000000", "headerTitleFont": "Quicksand", "headerTitleFontSize": 18, "headerSubtitle": "{nombreProceso}", "headerSubtitleColor": "#000000", "headerSubtitleFont": "Quicksand", "headerSubtitleFontSize": 16, "menuItems": [], "backgroundColor": "#e8e8e8", "headerComponents": [{"type":"Logo","order":1},{"type":"Titulo","order":2},{"type":"Menu","order":3}], "logoPadding": {"top":0,"bottom":0,"left":0,"right":0}, "headerSubTitlePadding": {"top":0,"bottom":0,"left":0,"right":0}, "headerTitlePadding": {"top":0,"bottom":0,"left":0,"right":0} },
    { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
    { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
    { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 1, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": true, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
  ],
  "children": [], "layerIndex": 1
}
```

### Paso 7: Form metadata (Pattern 22)

```json
{
  "id": 0,
  "name": "form_{activityId}",
  "controls": "{JSON.stringify(controls_array)}",
  "dataSources": "{JSON.stringify(dataSources_array)}",
  "version": 1,
  "createdDate": "{ISO_TIMESTAMP}",
  "createdUser": "{username_del_config_o_'skill'}",
  "published": false,
  "description": null,
  "category": null,
  "subcategory": null,
  "activityName": "{activityId}",
  "processName": "",
  "processVersion": "{del_spec_frontmatter}",
  "updatedDate": "{ISO_TIMESTAMP}",
  "originalName": "form_{activityId}",
  "formId": 0
}
```

### Paso 8: Triple encoding (4 pasos)

1. **Objetos**: controls[] y dataSources[] como arrays de objetos JavaScript/JSON
2. **JSON.stringify** controls[] y dataSources[] como strings dentro del form object:
   - Las comillas internas se escapan: `"` -> `\"`
3. **JSON.stringify** del form object completo:
   - Doble escape: `\"` -> `\\\"`
4. **HTML-encode** del string resultante para atributo XML:
   - `"` -> `&#34;` (referencia numerica, matching output del editor BIZUIT), `<` -> `&lt;`, `>` -> `&gt;`, `&` -> `&amp;`
   - **NOTA:** El editor BPMN de BIZUIT usa `&#34;` (numeric character reference), NO `&quot;` (named entity). Ambos son equivalentes en XML pero para match byte-a-byte usar `&#34;`.

Resultado final: `bizuit:serializedForm="{encoded_string}"`

**NO intentar mejorar el encoding** — generar lo que el editor consume (A18).

### Paso 9: Scan de seguridad

Verificar que el JSON generado NO contiene:
- Connection strings literales (patterns: `Password=`, `Secret=`, `Token=`, `Key=`, `Pwd=`, `Server=...;Database=`)
- Codigo ejecutable en events
- Credenciales en RestAPIDataSource (bearerToken, userName, userPassword deben estar vacios)

**Si detecta credential -> ERROR, no generar el form.**

`CustomCodePropertiesComponent.events` SIEMPRE `[]`.
SqlDataSource siempre `connectionSource: 1` (Configuration, no literal).

---

## Modo Merge (agregar a form existente)

1. **Parsear** serializedForm existente (revertir triple encoding: HTML-decode -> JSON.parse -> JSON.parse controls/dataSources)
2. **Verificar** que no existe control duplicado para el parametro (buscar por name en children)
3. **Agregar** nuevo control al final de children con posicion calculada:
   - Tomar ultimo control existente, calcular siguiente posicion con bin-packing
   - Si Stepper: agregar al ultimo step o crear step nuevo si step actual tiene 5+ controles
4. **Actualizar** Primary DS schema: agregar entrada del parametro a primarySchema
5. **Re-serializar** con triple encoding (4 pasos)

**Controles, estilos, custom code y layout existentes NO se tocan.**

---

## Degradacion graceful

| Situacion | Comportamiento |
|---|---|
| Tipo desconocido | InputTextboxComponent + WARNING |
| Parametro sin tipo | InputTextboxComponent + WARNING "sin tipo definido, asumido texto" |
| Parametro sin direction | Default In (1) + WARNING |
| Fallo en 1 form | BPMN sin ese form + WARNING, resto OK |
| XSD circular (profundidad >10) | Cortar + WARNING |
| 50+ campos | Stepper con N steps + WARNING "considerar dividir" |
| UserTasks con nombres duplicados | Sufijo _1, _2 en formName |

---

## Ejemplo end-to-end

UserTask "Aprobar Solicitud" con campos: pNombreSolicitante (string, In, required), pAprobado (boolean, Out).

**controls[] (1 MainForm con Header + 2 controles + 2 botones):**

```json
[{
  "name": "form_Activity_abc123", "component": "MainFormComponent",
  "x": 0, "y": 0, "rows": 0, "cols": 0,
  "props": [
    { "class": "BasicPropertiesComponent", "name": "form_Activity_abc123", "title": "PROPERTIES.BASIC.TITLE", "label": "form_Activity_abc123", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "normal", "fontColor": "#000000", "backgroundColor": "#FFFFFF", "fontSize": 12, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["backgroundColor"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": true },
    { "class": "FormPropertiesComponent", "title": "PROPERTIES.FORM.TITLE", "showMessageOnSuccess": true, "messagesParametersOnSuccess": [], "messageOnSuccess": "La operacion se completo con exito.", "showMessageOnError": true, "messageOnError": "Ha ocurrido un error.", "closeOnSuccess": true, "controlType": "standard", "cols": 6, "rowHeight": 70, "themeUseDefaultSettings": true, "theme": "bizuit", "modalType": "swal", "modalTitle": "", "modalUseOKButton": true, "modalUseTimer": false, "modalUseDefaultSettings": true, "modalTimeout": 0, "useRaiseEventAsync": false, "processingWaitTime": 5, "useOpenFormSettings": false, "openFormType": "DIALOG", "splitType": "NONE", "formSize": "ORIGINAL_SIZE", "showModalTitle": true },
    { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 1, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": true, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false },
    { "class": "CustomStylesPropertiesComponent", "cssCode": "" }
  ],
  "children": [
    {
      "name": "header1", "component": "HeaderComponent",
      "x": 0, "y": 0, "rows": 1, "cols": 6,
      "props": [
        { "class": "BasicPropertiesComponent", "name": "header1", "title": "PROPERTIES.BASIC.TITLE", "label": "header1", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "inherit", "fontColor": "#000000", "backgroundColor": "#FFFFFF", "fontSize": 12, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["backgroundColor"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": false },
        { "class": "HeaderPropertiesComponent", "logo": "", "headerTitle": "Aprobar Solicitud", "headerTitleColor": "#000000", "headerTitleFont": "Quicksand", "headerTitleFontSize": 18, "headerSubtitle": "Compras", "headerSubtitleColor": "#000000", "headerSubtitleFont": "Quicksand", "headerSubtitleFontSize": 16, "menuItems": [], "backgroundColor": "#e8e8e8", "headerComponents": [{"type":"Logo","order":1},{"type":"Titulo","order":2},{"type":"Menu","order":3}], "logoPadding": {"top":0,"bottom":0,"left":0,"right":0}, "headerSubTitlePadding": {"top":0,"bottom":0,"left":0,"right":0}, "headerTitlePadding": {"top":0,"bottom":0,"left":0,"right":0} },
        { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
        { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
        { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 1, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": true, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
      ],
      "children": [], "layerIndex": 1
    },
    {
      "name": "pNombreSolicitante", "component": "InputTextboxComponent",
      "x": 0, "y": 1, "rows": 1, "cols": 3,
      "props": [
        { "class": "BasicPropertiesComponent", "name": "pNombreSolicitante", "title": "PROPERTIES.BASIC.TITLE", "label": "Nombre Solicitante", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "inherit", "fontColor": "#000000", "backgroundColor": "#FFFFFF", "fontSize": 12, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["label","font","fontWeight","fontColor","fontSize","enabled","visible","tooltip","validateOnHiddenControl"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": false },
        { "class": "BindingsPropertiesComponent", "title": "PROPERTIES.BINDINGS.TITLE", "bindigSource": "", "secondaryDataSourcesRequest": [], "secondaryDataSourceResponse": {}, "bindToProcessExecution": false, "primaryDataSource": { "name": "pNombreSolicitante", "path": "pNombreSolicitante/pNombreSolicitante/Value", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, "primaryComboTextDataSource": {}, "subFormResponse": { "name": "", "item": null }, "subFormRequests": [] },
        { "class": "RestrictionsPropertiesComponent", "required": true, "dataType": "String", "lengthType": "Variable", "fixedLength": 0, "minLength": 0, "maxLength": 0, "minValue": 0, "maxValue": 0, "totalDigits": 0, "minValueIncluded": false, "maxValueIncluded": false, "decimalDigits": 0, "dateTimeMinValueType": "Absolute", "dateTimeMaxValueType": "Absolute", "dateTimeMinValue": null, "dateTimeMaxValue": null, "timeMinValue": null, "timeMaxValue": null, "dateTimeMinValueIncluded": false, "dateTimeMaxValueIncluded": false, "dateTimeMinValueRelativeIncluded": false, "dateTimeMaxValueRelativeIncluded": false, "dateTimeMinValueRelativeOperation": "Add", "dateTimeMaxValueRelativeOperation": "Add", "dateTimeMinValueRelativePeriod": "Days", "dateTimeMaxValueRelativePeriod": "Days", "dateTimeMinValueRelativeValue": 0, "dateTimeMaxValueRelativeValue": 0, "dateTimeMinPanel": false, "dateTimeMaxPanel": false, "minRows": 1, "maxRows": 5, "dataTypeBooleanControl": "String", "checkValue": "true", "uncheckValue": "false", "dateTimeValueType": "Relative", "dateTimeValueRelativeOperation": "Add", "dateTimeValueRelativePeriod": "Days", "dateTimeValueRelativeValue": 0, "datePickerValue": "{ISO_TIMESTAMP}", "format": "Short", "customFormat": "YYYY-MM-DD", "properties": ["required"], "regexPattern": "", "dateTimeMinValueRelativeSource": "TODAY", "dateTimeMaxValueRelativeSource": "TODAY", "dateTimeMinValueRelativeControlName": "", "dateTimeMaxValueRelativeControlName": "" },
        { "class": "ValidationsPropertiesComponent", "title": "PROPERTIES.VALIDATIONS.TITLE", "match": "ANY", "errorMessage": "", "rules": [] },
        { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
        { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
        { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 1, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": true, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
      ],
      "children": [], "layerIndex": 1
    },
    {
      "name": "pAprobado", "component": "CheckboxComponent",
      "x": 3, "y": 1, "rows": 1, "cols": 2,
      "props": [
        { "class": "BasicPropertiesComponent", "name": "pAprobado", "title": "PROPERTIES.BASIC.TITLE", "label": "Aprobado", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "inherit", "fontColor": "#000000", "backgroundColor": "#FFFFFF", "fontSize": 12, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["label","font","fontWeight","fontColor","fontSize","enabled","visible","tooltip","validateOnHiddenControl"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": false },
        { "class": "BindingsPropertiesComponent", "title": "PROPERTIES.BINDINGS.TITLE", "bindigSource": "", "secondaryDataSourcesRequest": [], "secondaryDataSourceResponse": {}, "bindToProcessExecution": false, "primaryDataSource": { "name": "pAprobado", "path": "pAprobado/pAprobado/Value", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, "primaryComboTextDataSource": {}, "subFormResponse": { "name": "", "item": null }, "subFormRequests": [] },
        { "class": "RestrictionsPropertiesComponent", "required": false, "dataType": "String", "lengthType": "Variable", "fixedLength": 0, "minLength": 0, "maxLength": 0, "minValue": 0, "maxValue": 0, "totalDigits": 0, "minValueIncluded": false, "maxValueIncluded": false, "decimalDigits": 0, "dateTimeMinValueType": "Absolute", "dateTimeMaxValueType": "Absolute", "dateTimeMinValue": null, "dateTimeMaxValue": null, "timeMinValue": null, "timeMaxValue": null, "dateTimeMinValueIncluded": false, "dateTimeMaxValueIncluded": false, "dateTimeMinValueRelativeIncluded": false, "dateTimeMaxValueRelativeIncluded": false, "dateTimeMinValueRelativeOperation": "Add", "dateTimeMaxValueRelativeOperation": "Add", "dateTimeMinValueRelativePeriod": "Days", "dateTimeMaxValueRelativePeriod": "Days", "dateTimeMinValueRelativeValue": 0, "dateTimeMaxValueRelativeValue": 0, "dateTimeMinPanel": false, "dateTimeMaxPanel": false, "minRows": 1, "maxRows": 5, "dataTypeBooleanControl": "String", "checkValue": "true", "uncheckValue": "false", "dateTimeValueType": "Relative", "dateTimeValueRelativeOperation": "Add", "dateTimeValueRelativePeriod": "Days", "dateTimeValueRelativeValue": 0, "datePickerValue": "{ISO_TIMESTAMP}", "format": "Short", "customFormat": "YYYY-MM-DD", "properties": ["required"], "regexPattern": "", "dateTimeMinValueRelativeSource": "TODAY", "dateTimeMaxValueRelativeSource": "TODAY", "dateTimeMinValueRelativeControlName": "", "dateTimeMaxValueRelativeControlName": "" },
        { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
        { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
        { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 1, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": true, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
      ],
      "children": [], "layerIndex": 1
    },
    {
      "name": "btnCancelar", "component": "ButtonComponent",
      "x": 2, "y": 2, "rows": 1, "cols": 2,
      "props": [
        { "class": "BasicPropertiesComponent", "name": "btnCancelar", "title": "PROPERTIES.BASIC.TITLE", "label": "Cancelar", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "inherit", "fontColor": "#FFFFFF", "backgroundColor": "#FFFFFF", "fontSize": 9, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["label","font","align","fontWeight","fontColor","fontSize","enabled","visible","tooltip"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": false },
        { "class": "ButtonPropertiesComponent", "backgroundColor": "primary", "title": "PROPERTIES.BUTTON.TITLE", "classType": "mat-raised-button", "icon": "", "width": null, "height": null },
        { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
        { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
        { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 4, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": false, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
      ],
      "children": [], "layerIndex": 1
    },
    {
      "name": "btnEnviar", "component": "ButtonComponent",
      "x": 4, "y": 2, "rows": 1, "cols": 2,
      "props": [
        { "class": "BasicPropertiesComponent", "name": "btnEnviar", "title": "PROPERTIES.BASIC.TITLE", "label": "Enviar", "value": "", "tooltip": "", "tooltipPosition": "above", "font": "Quicksand", "align": "center-container", "fontWeight": "inherit", "fontColor": "#FFFFFF", "backgroundColor": "#FFFFFF", "fontSize": 9, "enabled": true, "parentEnabled": true, "visible": true, "vertical": false, "fontEffectLineThrough": false, "fontEffectUnderline": false, "properties": ["label","font","align","fontWeight","fontColor","fontSize","enabled","visible","tooltip"], "labelValue": "value", "layer": 1, "validateOnHiddenControl": false, "isSubForm": false, "isMainForm": false },
        { "class": "ButtonPropertiesComponent", "backgroundColor": "primary", "title": "PROPERTIES.BUTTON.TITLE", "classType": "mat-raised-button", "icon": "", "width": null, "height": null },
        { "class": "FormattingPropertiesComponent", "title": "PROPERTIES.FORMATTING.TITLE", "rules": [] },
        { "class": "CustomStylesPropertiesComponent", "cssCode": "" },
        { "class": "CustomCodePropertiesComponent", "events": [], "focusOn": null, "basicEvent": 1, "selectedSecondaryDatasources": [], "selectedSecondaryDatasource": "", "selectedColumnTrace": 0, "executeValidation": true, "selectedSubForm": "", "subFormSize": { "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }, "addDocumentsToDataSource": false, "selectedDocumentControl": "", "modalType": "swal", "modalTitle": "", "modalMessage": "", "modalUseOKButton": true, "modalUseTimer": false, "modalTimeout": 5, "showMessageOnSuccess": true, "clearControlsAfterExecute": false }
      ],
      "children": [], "layerIndex": 1
    }
  ],
  "layerIndex": 1
}]
```

**dataSources[] (2 DS para UserTask):**

```json
[
  {
    "name": "Parametros y Variables", "isPrimary": true,
    "primarySchema": [
      { "label": "ExceptionParameter", "icon": "", "children": [{ "label": "ROOT", "icon": "", "children": [{ "label": "Message", "icon": "", "children": [], "primaryDataSource": { "name": "Message", "path": "ExceptionParameter/ROOT/Message", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, "typeName": "InputTextboxComponent", "draggable": true }, { "label": "Type", "icon": "", "children": [], "primaryDataSource": { "name": "Type", "path": "ExceptionParameter/ROOT/Type", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, "typeName": "InputTextboxComponent", "draggable": true }, { "label": "StackTrace", "icon": "", "children": [], "primaryDataSource": { "name": "StackTrace", "path": "ExceptionParameter/ROOT/StackTrace", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, "typeName": "InputTextboxComponent", "draggable": true }, { "label": "FaultingActivity", "icon": "", "children": [], "primaryDataSource": { "name": "FaultingActivity", "path": "ExceptionParameter/ROOT/FaultingActivity", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, "typeName": "InputTextboxComponent", "draggable": true }], "primaryDataSource": { "name": "ROOT", "path": "ExceptionParameter/ROOT", "repetitive": false, "children": [{ "name": "Message", "path": "ExceptionParameter/ROOT/Message", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, { "name": "Type", "path": "ExceptionParameter/ROOT/Type", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, { "name": "StackTrace", "path": "ExceptionParameter/ROOT/StackTrace", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, { "name": "FaultingActivity", "path": "ExceptionParameter/ROOT/FaultingActivity", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }], "defaultValue": null }, "typeName": "InputTextboxComponent", "draggable": true }], "primaryDataSource": { "name": "ExceptionParameter", "type": "Parameter", "isVariable": false, "isSystemParameter": false, "parameterDirection": 3, "parameterType": 2, "children": [{ "name": "ROOT", "path": "ExceptionParameter/ROOT", "repetitive": false, "children": [{ "name": "Message", "path": "ExceptionParameter/ROOT/Message", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, { "name": "Type", "path": "ExceptionParameter/ROOT/Type", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, { "name": "StackTrace", "path": "ExceptionParameter/ROOT/StackTrace", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }, { "name": "FaultingActivity", "path": "ExceptionParameter/ROOT/FaultingActivity", "valueType": "String", "repetitive": false, "children": [], "defaultValue": null }], "defaultValue": null }], "defaultValue": "" }, "typeName": "InputTextboxComponent", "draggable": true },
      { "label": "OutputParameter", "icon": "", "children": [], "primaryDataSource": { "name": "OutputParameter", "path": "OutputParameter/OutputParameter/Value", "type": "Parameter", "valueType": "string", "isVariable": false, "isSystemParameter": false, "parameterDirection": 2, "parameterType": 1, "children": [], "defaultValue": "" }, "typeName": "InputTextboxComponent", "draggable": true },
      { "label": "InstanceId", "icon": "", "children": [], "primaryDataSource": { "name": "InstanceId", "path": "InstanceId/InstanceId/Value", "type": "Parameter", "valueType": "string", "isVariable": true, "isSystemParameter": false, "parameterDirection": 3, "parameterType": 1, "children": [], "defaultValue": "" }, "typeName": "InputTextboxComponent", "draggable": true },
      { "label": "LoggedUser", "icon": "", "children": [], "primaryDataSource": { "name": "LoggedUser", "path": "LoggedUser/LoggedUser/Value", "type": "Parameter", "valueType": "string", "isVariable": true, "isSystemParameter": false, "parameterDirection": 3, "parameterType": 1, "children": [], "defaultValue": "" }, "typeName": "InputTextboxComponent", "draggable": true },
      { "label": "pNombreSolicitante", "icon": "", "children": [], "primaryDataSource": { "name": "pNombreSolicitante", "path": "pNombreSolicitante/pNombreSolicitante/Value", "type": "Parameter", "valueType": "string", "isVariable": false, "isSystemParameter": false, "parameterDirection": 1, "parameterType": 1, "children": [], "defaultValue": "" }, "typeName": "InputTextboxComponent", "draggable": true },
      { "label": "pAprobado", "icon": "", "children": [], "primaryDataSource": { "name": "pAprobado", "path": "pAprobado/pAprobado/Value", "type": "Parameter", "valueType": "string", "isVariable": false, "isSystemParameter": false, "parameterDirection": 2, "parameterType": 1, "children": [], "defaultValue": "" }, "typeName": "InputTextboxComponent", "draggable": true }
    ],
    "events": []
  },
  { "name": "Actividades Anteriores", "isPrimary": true, "primarySchema": [], "events": [] }
]
```

**Form object final (Paso 7 + Paso 8):**

```json
{
  "id": 0,
  "name": "form_Activity_abc123",
  "controls": "[{\"name\":\"form_Activity_abc123\",\"component\":\"MainFormComponent\",...}]",
  "dataSources": "[{\"name\":\"Parametros y Variables\",\"isPrimary\":true,...},{\"name\":\"Actividades Anteriores\",...}]",
  "version": 1,
  "createdDate": "{ISO_TIMESTAMP}",
  "createdUser": "skill",
  "published": false,
  "description": null,
  "category": null,
  "subcategory": null,
  "activityName": "Activity_abc123",
  "processName": "",
  "processVersion": "1.0.0.0",
  "updatedDate": "{ISO_TIMESTAMP}",
  "originalName": "form_Activity_abc123",
  "formId": 0
}
```

En BPMN: `bizuit:serializedForm="{&#34;id&#34;:0,&#34;name&#34;:&#34;form_Activity_abc123&#34;,...}"` + `bizuit:formId="0"` + `bizuit:formName="form_Activity_abc123"`.

**NOTA sobre formName:** En forms generados por el skill, formName usa `form_{activityId}` del BPMN. En forms creados por el editor, formName puede usar IDs internos diferentes (ej: form_StartEvent_79). Los forms generados no matchean byte-a-byte con forms del editor.

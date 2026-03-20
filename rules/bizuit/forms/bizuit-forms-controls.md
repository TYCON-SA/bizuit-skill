# BizuitForms — Referencia de Controles

> Referencia completa de los 23 tipos de control de BizuitForms.
> Esta rule es para humanos (reverse, query, validate). NO se carga durante generacion.
> form-generation.md tiene su propia tabla compacta (Pattern 19).

---

## Tabla de Mapeo Tipo Spec a Control

| Tipo en spec | Component | cols | Notas |
|---|---|---|---|
| string | InputTextboxComponent | 3 | Default para tipos desconocidos |
| string largo | TextareaComponent | 6 | Heuristica: nombre contiene "observaciones", "descripcion", "comentarios", "notas", "detalle" |
| numero/entero | InputTextboxComponent | 3 | dataType: Integer |
| numero/decimal | InputTextboxComponent | 3 | dataType: Double |
| boolean | CheckboxComponent | 2 | |
| fecha/datetime | DatePickerComponent | 2 | |
| seleccion/combo | ComboboxComponent | 3 | |
| radio (<5 opciones fijas) | RadioButtonComponent | 2 | |
| toggle | SlideToggleComponent | 2 | |
| archivo/adjunto | DocumentInputComponent | 6 | |
| firma | SignatureComponent | 6 | |
| ubicacion/GPS | GeolocationComponent | 6 | |
| tabla editable | TableComponent | 6 | |
| subformulario | SubFormComponent | 6 | |
| imagen/video | MediaComponent | 6 | |
| iframe/embed | IframeComponent | 6 | |
| tipo desconocido | InputTextboxComponent | 3 | Fallback + warning |

---

## Propiedades Compartidas

Estas propiedades aparecen en multiples controles. Se documentan una vez aqui.

### BasicPropertiesComponent

Presente en TODOS los 23 controles. Siempre es el PRIMER elemento de `props[]`.

| Campo | Default | Notas |
|---|---|---|
| `class` | `"BasicPropertiesComponent"` | Discriminator obligatorio |
| `name` | `""` | Identificador unico del control |
| `title` | `"PROPERTIES.BASIC.TITLE"` | |
| `label` | `""` | Texto visible del control |
| `value` | `""` | |
| `tooltip` | `""` | |
| `tooltipPosition` | `"above"` | |
| `font` | `"Quicksand"` | |
| `align` | `"center-container"` | |
| `fontWeight` | `"inherit"` | MainForm usa `"normal"` |
| `fontColor` | `"#000000"` | |
| `backgroundColor` | `"#FFFFFF"` | |
| `fontSize` | `12` | Buttons usan `9` |
| `enabled` | `true` | |
| `parentEnabled` | `true` | |
| `visible` | `true` | |
| `vertical` | `false` | |
| `fontEffectLineThrough` | `false` | |
| `fontEffectUnderline` | `false` | |
| `labelValue` | `"value"` | |
| `layer` | `1` | |
| `validateOnHiddenControl` | `false` | |
| `isSubForm` | `false` | |
| `isMainForm` | `false` | `true` solo en MainFormComponent |
| `properties` | `["backgroundColor"]` | Array de propiedades editables visibles en editor. Varia por control |

**`properties` por control (valores reales del BPMN):**
- MainForm: `["backgroundColor"]`
- Button: `["label","font","align","fontWeight","fontColor","fontSize","enabled","visible","tooltip"]`
- Combobox: `["label","font","fontWeight","fontColor","fontSize","enabled","visible","tooltip","validateOnHiddenControl"]`
- InputTextbox/Textarea: `["label","font","fontWeight","fontColor","fontSize","enabled","visible","tooltip","validateOnHiddenControl"]`

### BindingsPropertiesComponent

Presente en: InputTextbox, Textarea, Label, Combobox, RadioButton, Checkbox, SlideToggle, DatePicker, Table, Media, Geolocation, Signature.

| Campo | Default |
|---|---|
| `class` | `"BindingsPropertiesComponent"` |
| `title` | `"PROPERTIES.BINDINGS.TITLE"` |
| `bindigSource` | `""` |
| `secondaryDataSourcesRequest` | `[]` |
| `secondaryDataSourceResponse` | `{}` |
| `bindToProcessExecution` | `false` |
| `primaryDataSource` | `{}` |
| `primaryComboTextDataSource` | `{}` |
| `subFormResponse` | `{ "name": "", "item": null }` |
| `subFormRequests` | `[]` |

### RestrictionsPropertiesComponent

Presente en: InputTextbox, Textarea, Combobox, RadioButton, Checkbox, SlideToggle, DatePicker.

| Campo | Default | Notas |
|---|---|---|
| `class` | `"RestrictionsPropertiesComponent"` | |
| `required` | `false` | |
| `dataType` | `"String"` | Enum: String, Integer, Double, DateTime |
| `lengthType` | `"Variable"` | Enum: Fixed, Variable |
| `fixedLength` | `0` | |
| `minLength` | `0` | |
| `maxLength` | `0` | |
| `minValue` | `0` | |
| `maxValue` | `0` | |
| `totalDigits` | `0` | |
| `minValueIncluded` | `false` | |
| `maxValueIncluded` | `false` | |
| `decimalDigits` | `0` | |
| `dateTimeMinValueType` | `"Absolute"` | |
| `dateTimeMaxValueType` | `"Absolute"` | |
| `dateTimeMinValue` | `null` | |
| `dateTimeMaxValue` | `null` | |
| `timeMinValue` | `null` | |
| `timeMaxValue` | `null` | |
| `dateTimeMinValueIncluded` | `false` | |
| `dateTimeMaxValueIncluded` | `false` | |
| `dateTimeMinValueRelativeIncluded` | `false` | |
| `dateTimeMaxValueRelativeIncluded` | `false` | |
| `dateTimeMinValueRelativeOperation` | `"Add"` | |
| `dateTimeMaxValueRelativeOperation` | `"Add"` | |
| `dateTimeMinValueRelativePeriod` | `"Days"` | |
| `dateTimeMaxValueRelativePeriod` | `"Days"` | |
| `dateTimeMinValueRelativeValue` | `0` | |
| `dateTimeMaxValueRelativeValue` | `0` | |
| `dateTimeMinPanel` | `false` | |
| `dateTimeMaxPanel` | `false` | |
| `minRows` | `1` | Solo Textarea |
| `maxRows` | `5` | Solo Textarea |
| `dataTypeBooleanControl` | `"String"` | |
| `checkValue` | `"true"` | Solo Checkbox/SlideToggle |
| `uncheckValue` | `"false"` | Solo Checkbox/SlideToggle |
| `dateTimeValueType` | `"Relative"` | Solo DatePicker |
| `dateTimeValueRelativeOperation` | `"Add"` | |
| `dateTimeValueRelativePeriod` | `"Days"` | |
| `dateTimeValueRelativeValue` | `0` | |
| `datePickerValue` | ISO timestamp actual | Solo DatePicker |
| `format` | `"Short"` | Solo DatePicker. Enum: Long, Short, Time, Custom |
| `customFormat` | `"YYYY-MM-DD"` | |
| `regexPattern` | `""` | |
| `properties` | `["required"]` | |
| `dateTimeMinValueRelativeSource` | `"TODAY"` | |
| `dateTimeMaxValueRelativeSource` | `"TODAY"` | |
| `dateTimeMinValueRelativeControlName` | `""` | |
| `dateTimeMaxValueRelativeControlName` | `""` | |

### ValidationsPropertiesComponent

Presente en: InputTextbox, Textarea, Combobox, RadioButton, Checkbox, SlideToggle, DatePicker.

| Campo | Default |
|---|---|
| `class` | `"ValidationsPropertiesComponent"` |
| `title` | `"PROPERTIES.VALIDATIONS.TITLE"` |
| `match` | `"ANY"` |
| `errorMessage` | `""` |
| `rules` | `[]` |

### FormattingPropertiesComponent

Presente en: InputTextbox, Textarea, Combobox, RadioButton, Checkbox, SlideToggle, DatePicker, Button, Table, Card, Container, Tab, Stepper, Header, Media, Iframe, DocumentInput, Geolocation, Signature, AddToGridButton.

| Campo | Default |
|---|---|
| `class` | `"FormattingPropertiesComponent"` |
| `title` | `"PROPERTIES.FORMATTING.TITLE"` |
| `rules` | `[]` |

### CustomStylesPropertiesComponent

Presente en: InputTextbox, Textarea, Label, Combobox, RadioButton, Checkbox, SlideToggle, Button, Table, Card, Container, Tab, Stepper, Header, AddToGridButton.

| Campo | Default |
|---|---|
| `class` | `"CustomStylesPropertiesComponent"` |
| `cssCode` | `""` |

### CustomCodePropertiesComponent

Presente en TODOS los controles excepto AddToGridButton. **events SIEMPRE = []**.

| Campo | Default |
|---|---|
| `class` | `"CustomCodePropertiesComponent"` |
| `events` | `[]` |
| `focusOn` | `null` |
| `basicEvent` | `1` |
| `selectedSecondaryDatasources` | `[]` |
| `selectedSecondaryDatasource` | `""` |
| `selectedColumnTrace` | `0` |
| `executeValidation` | `true` |
| `selectedSubForm` | `""` |
| `subFormSize` | `{ "width": 60, "widthUnit": "percentage", "height": 60, "heightUnit": "percentage" }` |
| `addDocumentsToDataSource` | `false` |
| `selectedDocumentControl` | `""` |
| `modalType` | `"swal"` |
| `modalTitle` | `""` |
| `modalMessage` | `""` |
| `modalUseOKButton` | `true` |
| `modalUseTimer` | `false` |
| `modalTimeout` | `5` |
| `showMessageOnSuccess` | `true` |
| `clearControlsAfterExecute` | `false` |

**basicEvent enum (BIZUITButtonType):** 1=InvokeProcess, 2=InvokeDataSource, 3=TraceWindow, 4=Close, 5=Terminate, 6=CustomCode, 7=InvokeSubForm.

---

## Controles por Categoria

### Controles de Input

#### InputTextboxComponent

**Property Stack:** Basic, Bindings, Restrictions, Validations, Formatting, CustomStyles, CustomCode

Uso: texto libre, numeros (cambiar dataType en Restrictions), cualquier input single-line.

Defaults no-default notables:
- Restrictions.dataType: `"Integer"` para numeros enteros, `"Double"` para decimales

#### TextareaComponent

**Property Stack:** Basic, Bindings, Restrictions, CustomCode, Validations, Formatting, CustomStyles

Uso: texto largo multi-linea. Detectado por heuristica de nombre del campo.

Defaults no-default notables:
- Restrictions.minRows: `1`
- Restrictions.maxRows: `5`

### Controles de Seleccion

#### ComboboxComponent

**Property Stack:** Basic, Bindings, Restrictions, Population, Validations, Formatting, CustomStyles, CustomCode

Uso: seleccion de una o multiples opciones de una lista.

Props especifica — **PopulationPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"PopulationPropertiesComponent"` |
| `sourceType` | `"DataSource"` |
| `dataSourceElement` | `null` |
| `dataSourceItemText` | `""` |
| `dataSourceItemValue` | `""` |
| `fixedList` | `[]` |
| `keyValueList` | `[]` |
| `defaultElementNone` | `true` |
| `defaultElementIndex` | `0` |
| `addEmptyItem` | `false` |
| `EmptyItemText` | `""` |
| `EmptyItemValue` | `0` |
| `multiple` | `false` |
| `autocomplete` | `false` |
| `controlType` | `"Combobox"` |
| `separator` | `","` |
| `valueAsJson` | `false` |
| `items` | `[]` |

sourceType enum: `"DataSource"`, `"FixedList"`, `"KeyValueList"`.

#### RadioButtonComponent

**Property Stack:** Basic, Bindings, Restrictions, Population, Validations, Formatting, CustomStyles, CustomCode

Uso: seleccion unica con menos de 5 opciones visibles. Misma PopulationPropertiesComponent que Combobox, con `controlType: "RadioButton"`.

#### CheckboxComponent

**Property Stack:** Basic, Bindings, Restrictions, Validations, Formatting, CustomStyles, CustomCode

Uso: campo booleano (si/no).

Defaults no-default notables en Restrictions:
- `checkValue`: `"true"`
- `uncheckValue`: `"false"`

#### SlideToggleComponent

**Property Stack:** Basic, Bindings, Restrictions, Validations, Formatting, CustomStyles, CustomCode

Uso: booleano con toggle visual. Mismos defaults que Checkbox.

#### DatePickerComponent

**Property Stack:** Basic, Bindings, Restrictions, Validations, Formatting, CustomCode

Uso: seleccion de fecha/hora. **No tiene CustomStyles**.

Defaults no-default notables en Restrictions:
- `format`: `"Short"` (enum: Long, Short, Time, Custom)
- `customFormat`: `"YYYY-MM-DD"`
- `dateTimeValueType`: `"Relative"`

### Controles de Layout

#### ContainerComponent

**Property Stack:** Basic, Container, Formatting, CustomStyles, CustomCode

Props especifica — **ContainerPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"ContainerPropertiesComponent"` |
| `backgroundColor` | `"#ffffff"` |
| `columns` | `3` |
| `marginTop` | `0` |
| `marginBottom` | `0` |
| `marginLeft` | `0` |
| `marginRight` | `0` |
| `borderRadius` | `0` |
| `matElevation` | `0` |

Uso: agrupador visual de controles.

#### TabComponent

**Property Stack:** Basic, Tab, Formatting, CustomStyles, CustomCode

Props especifica — **TabPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"TabPropertiesComponent"` |
| `tabs` | `[]` |
| `selectedIndex` | `0` |
| `backgroundColor` | `"primary"` |
| `isVertical` | `false` |
| `columns` | `3` |
| `disableAnimation` | `false` |
| `color` | `"primary"` |
| `alignTab` | `"start"` |

Cada Tab: `{ id, label, icon, selected, visible, backgroundContent, formatting }`.

#### CardComponent

**Property Stack:** Basic, Card, Formatting, CustomStyles, CustomCode

Props especifica — **CardPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"CardPropertiesComponent"` |
| `titleCard` | `"Titulo"` |
| `subtitleCard` | `"Subtitulo"` |
| `avatarImage` | `""` |
| `avatarImageBase64` | `""` |
| `useBase64` | `false` |
| `backgroundContent` | `"#ffffff"` |
| `columns` | `3` |
| `overflow_y` | `"auto"` |
| `cardBackgroundColor` | `"#ffffff"` |
| `borderRadius` | `4` |
| `titleColor` | `"#000000"` |
| `subTitleColor` | `"#000000"` |

#### StepperComponent

**Property Stack:** Basic, Stepper, Formatting, CustomStyles, CustomCode

Props especifica — **StepperPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"StepperPropertiesComponent"` |
| `linear` | `false` |
| `orientation` | `"horizontal"` |
| `disableRipple` | `false` |
| `labelPosition` | `"bottom"` |
| `headerPosition` | `"top"` |
| `animationDuration` | `0` |
| `hideButtons` | `false` |
| `stepHeight` | `400` |
| `steps` | `[]` |

Cada Step: `{ id: GUID, label, editable: true, backgroundColor: "#dedede", visible: true, columns: 6, validateChildren: false }`.

Uso: para 8+ campos. Steps agrupados cada 5 campos o por sub-secciones del spec.

#### HeaderComponent

**Property Stack:** Basic, Header, Formatting, CustomStyles, CustomCode

Props especifica — **HeaderPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"HeaderPropertiesComponent"` |
| `logo` | `""` |
| `headerTitle` | `"Titulo"` |
| `headerTitleColor` | `"#000000"` |
| `headerTitleFont` | `"Quicksand"` |
| `headerTitleFontSize` | `18` |
| `headerSubtitle` | `"Subtitulo"` |
| `headerSubtitleColor` | `"#000000"` |
| `headerSubtitleFont` | `"Quicksand"` |
| `headerSubtitleFontSize` | `16` |
| `menuItems` | `[]` |
| `backgroundColor` | `"#e8e8e8"` |
| `headerComponents` | `[{type:"Logo",order:1},{type:"Titulo",order:2},{type:"Menu",order:3}]` |
| `logoPadding` | `{top:0,bottom:0,left:0,right:0}` |
| `headerSubTitlePadding` | `{top:0,bottom:0,left:0,right:0}` |
| `headerTitlePadding` | `{top:0,bottom:0,left:0,right:0}` |

### Controles de Media

#### DocumentInputComponent

**Property Stack:** Basic, Document, Formatting, CustomCode

Props especifica — **DocumentPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"DocumentPropertiesComponent"` |
| `label` | `"Arrastre o seleccione documentos"` |
| `noFilesLabel` | `"No hay documentos adjuntos"` |
| `labelColor` | `"#000000"` |
| `buttonLabelColor` | `"#FFFFFF"` |
| `showDropArea` | `false` |
| `showCurrentInstanceDocuments` | `true` |
| `documentToUploadMin` | `0` |
| `documentToUploadMax` | `0` |
| `documentToUploadMinSize` | `0` |
| `documentToUploadMaxSize` | `0` |
| `allowedExtensions` | `""` |
| `userCanAddDocuments` | `false` |
| `userCanDeleteDocuments` | `false` |
| `documents` | `[]` |
| `sendFilesToBIZUITDataSource` | `false` |

#### SignatureComponent

**Property Stack:** Basic, Bindings, Formatting, CustomCode

Uso: captura de firma digital. Sin props especifica propia (usa Basic + Bindings).

#### GeolocationComponent

**Property Stack:** Basic, Bindings, Geolocation, Formatting, CustomCode

Props especifica — **GeolocationPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"GeolocationPropertiesComponent"` |
| `markerLabel` | `"A"` |
| `markerInfo` | `""` |
| `paddingBottom` | `0` |
| `paddingTop` | `0` |
| `paddingLeft` | `0` |
| `paddingRight` | `0` |
| `canChangeLocation` | `true` |
| `latitude` | `0` |
| `longitude` | `0` |

#### MediaComponent

**Property Stack:** Basic, Bindings, Media, Formatting, CustomCode

Props especifica — **MediaPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"MediaPropertiesComponent"` |
| `src` | `""` |
| `sizeMode` | `"normal"` |
| `mediaType` | `"image"` |
| `cameraType` | `"photo"` |
| `previewImage` | `""` |
| `paddingBottom` | `0` |
| `paddingTop` | `0` |
| `paddingLeft` | `0` |
| `paddingRight` | `0` |
| `videoPlayWidth` | `100` |
| `buttonAlign` | `"button-top-start"` |
| `buttonColor` | `"primary"` |
| `buttonIcon` | `"camera_enhance"` |
| `buttonText` | `""` |
| `useButtonIcon` | `false` |
| `youtubeVideoId` | `""` |

#### IframeComponent

**Property Stack:** Basic, Iframe, Formatting, CustomCode

Props especifica — **IframePropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"IframePropertiesComponent"` |
| `url` | `""` |
| `paddingBottom` | `0` |
| `paddingTop` | `0` |
| `paddingLeft` | `0` |
| `paddingRight` | `0` |

### Controles de Accion

#### ButtonComponent

**Property Stack:** Basic, Button, Formatting, CustomStyles, CustomCode

Props especifica — **ButtonPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"ButtonPropertiesComponent"` |
| `title` | `"PROPERTIES.BUTTON.TITLE"` |
| `backgroundColor` | `"primary"` |
| `classType` | `"mat-raised-button"` |
| `icon` | `""` |
| `width` | `null` |
| `height` | `null` |

BasicPropertiesComponent de Button difiere de otros controles:
- `fontWeight`: `"inherit"`
- `fontColor`: `"#FFFFFF"` (texto blanco sobre fondo de color)
- `fontSize`: `9`

**Botones default para todo form:**
- "Enviar": basicEvent=1 (InvokeProcess), executeValidation=true
- "Cancelar": basicEvent=4 (Close), executeValidation=false

#### AddToGridButtonComponent

**Property Stack:** Basic, Button, AddToGridButton, Formatting, CustomStyles

Props especifica — **AddToGridButtonPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"AddToGridButtonPropertiesComponent"` |
| `operation` | `"add"` |
| `gridControl` | `""` |
| `columns` | `[]` |
| `controlFocus` | `""` |
| `clearControlValues` | `false` |

**No tiene CustomCodePropertiesComponent** (unico control sin ella).

### Controles de Datos

#### LabelComponent

**Property Stack:** Basic, Bindings, Formatting, CustomStyles, CustomCode

Uso: texto de solo lectura. Sin Restrictions ni Validations.

#### TableComponent

**Property Stack:** Basic, Bindings, Table, Columns, Formatting, CustomStyles, CustomCode

Props especifica — **TablePropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"TablePropertiesComponent"` |
| `backgroundColor` | `"#FFFFFF"` |
| `headerBackgroundColor` | `"#FFFFFF"` |
| `headerFontColor` | `"#000000"` |
| `headerFont` | `"Quicksand"` |
| `headerFontSize` | `12` |
| `bodyFontColor` | `"#000000"` |
| `bodyFont` | `"Quicksand"` |
| `bodyFontSize` | `14` |
| `minRows` | `0` |
| `maxRows` | `0` |
| `canEdit` | `false` |
| `canAdd` | `false` |
| `canDelete` | `false` |
| `emptyRowsMessage` | `"No data to display!"` |
| `rowCountMessage` | `"Total"` |
| `selectionBackgroundColor` | `"#d1d1d1"` |
| `selectionFontColor` | `"#000000"` |
| `useOnlySelectedRows` | `false` |
| `hoverBackgroundColor` | `"#EEEEEE"` |
| `backgroundColorRowOdd` | `"#FFFFFF"` |
| `showScrollbarX` | `false` |

Props especifica — **ColumnsPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"ColumnsPropertiesComponent"` |
| `columns` | `[]` |
| `rows` | `[]` |
| `duplicateKeyError` | `""` |
| `useOnlyVerifiedColumns` | `false` |

Cada Column: `{ name, prop, showColumn: true, showInMobile: false, resizable: false, sortable: false, draggable: false, canAutoResize: true, canEdit: true, flexGrow: 0, minWidth: 0, width: 50, maxWidth: 500, widthUnits: "Porcentaje", color: "#FFFFFF", font: "Quicksand", fontColor: "#000000", fontSize: 14, useMaxLength: false, maxLength: 0 }`.

#### SubFormComponent

**Property Stack:** Basic, SubForms, CustomCode

Props especifica — **SubFormsPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"SubFormsPropertiesComponent"` |
| `columns` | `6` |
| `request` | `[]` |
| `response` | `[]` |
| `acceptButtonLabel` | `"Aceptar"` |
| `closeButtonLabel` | `"Cerrar"` |
| `acceptBackgroundColor` | `"primary"` |
| `closeBackgroundColor` | `"secondary"` |
| `buttonAlign` | `"LEFT"` |
| `buttonType` | `"mat-raised-button"` |
| `acceptIcon` | `""` |
| `cancelIcon` | `""` |
| `showAcceptButton` | `true` |
| `showCloseButton` | `true` |

### Control Raiz (obligatorio)

#### MainFormComponent

**Property Stack:** Basic, Form, CustomCode, CustomStyles

Siempre es el UNICO elemento raiz del array `controls[]`. Todos los demas controles van como hijos en `children[]`.

Props especifica — **FormPropertiesComponent:**

| Campo | Default |
|---|---|
| `class` | `"FormPropertiesComponent"` |
| `title` | `"PROPERTIES.FORM.TITLE"` |
| `showMessageOnSuccess` | `true` |
| `messagesParametersOnSuccess` | `[]` |
| `messageOnSuccess` | `"La operacion se completo con exito."` |
| `showMessageOnError` | `true` |
| `messageOnError` | `"Ha ocurrido un error."` |
| `closeOnSuccess` | `true` |
| `controlType` | `"standard"` |
| `cols` | `6` |
| `rowHeight` | `70` |
| `themeUseDefaultSettings` | `true` |
| `theme` | `"bizuit"` |
| `modalType` | `"swal"` |
| `modalTitle` | `""` |
| `modalUseOKButton` | `true` |
| `modalUseTimer` | `false` |
| `modalUseDefaultSettings` | `true` |
| `modalTimeout` | `0` |
| `useRaiseEventAsync` | `false` |
| `processingWaitTime` | `5` |
| `useOpenFormSettings` | `false` |
| `openFormType` | `"DIALOG"` |
| `splitType` | `"NONE"` |
| `formSize` | `"ORIGINAL_SIZE"` |
| `showModalTitle` | `true` |

BasicPropertiesComponent de MainForm difiere de otros controles:
- `isMainForm`: `true`
- `fontWeight`: `"normal"` (no `"inherit"`)
- `properties`: `["backgroundColor"]`

---

## Reglas de Integridad

1. **layerIndex**: `1` obligatorio en TODOS los controles (MainForm y children)
2. **class**: discriminator obligatorio como PRIMER campo en cada objeto dentro de `props[]`
3. **events**: SIEMPRE `[]` en CustomCodePropertiesComponent — NUNCA copiar codigo del spec
4. **MainFormComponent**: siempre unico y raiz. Todos los controles visibles son `children[]` de MainForm
5. **x, y, rows, cols**: MainForm siempre `x:0, y:0, rows:0, cols:0`. Children usan grid de 6 columnas

---

## Nota: Controles excluidos del mapeo

SeparatorComponent y HiddenFieldComponent son controles internos del editor BizuitForms. No son mapeables desde spec y no aparecen en la tabla de mapeo tipo→control. Esta exclusión es intencional (verificada en adversarial review Epic 9, BLOCKER-4).

- **SeparatorComponent**: puramente visual (sin binding de datos). El editor BIZUIT lo usa como separador de secciones.
- **HiddenFieldComponent**: para valores técnicos internos que el skill no puede inferir desde la spec.

Si el usuario necesita estos controles, debe agregarlos manualmente en el editor BIZUIT.

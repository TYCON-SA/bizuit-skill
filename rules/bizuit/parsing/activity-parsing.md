# Activity Parsing

> Reglas para convertir cada tipo de actividad VDW a sección de spec. Cada `## Tipo` sigue el contrato de parsing/ (`### Attributes to extract`, `### Input → Output example`, `### Encoding notes`) salvo excepciones marcadas.

## Start

> **EXCEPCIÓN al contrato estándar.** No describe un elemento VDW — extrae metadatos del proceso.

### What to do

En WF3 XAML no existe un elemento "Start". El workflow raíz `TyconSequentialWorkflow` ES el inicio. **NO generar una actividad "1. Start" en la spec.**

Esta sección extrae los **parámetros del proceso** desde `ParameterDefinition` bajo el root.

### How to extract parameters

Buscar: `<ns:ParameterDefinition Name="{nombre}" ParamType="{SingleValue|Xml}" DataType="{tipo}" IsVariable="{True|False}" />`

Los parámetros están en la sección `TyconSequentialWorkflow.ParametersDefinition > ParametersDefinition`.

La dirección se determina por la sección padre:
- Parámetros dentro de `InputParameters` o `OptionalParameters` → input
- Parámetros dentro de `OutputParameters` → output
- Si `IsVariable="True"` → variable interna del workflow

### Separación sistema vs negocio (FR26)

| Parámetro | Clasificación |
|-----------|--------------|
| `InstanceId` | Sistema |
| `LoggedUser` | Sistema |
| `ExceptionParameter` | Sistema |
| `OutputParameter` | Sistema |
| Todo lo demás | Negocio |

En la spec, documentar en subsecciones separadas:

```markdown
## 2. Parámetros

### Parámetros de negocio

| Nombre | Tipo | Dirección | Descripción |
|--------|------|-----------|-------------|
| pIsAdmin | string | Output | Indica si el usuario es admin |
| pUserName | string | Output | Nombre del usuario logueado |

### Parámetros de sistema

| Nombre | Tipo | Dirección |
|--------|------|-----------|
| InstanceId | string | Variable |
| LoggedUser | string | Variable |
| ExceptionParameter | XML | Output |
| OutputParameter | string | Output |
```

### Additional parameter attributes

| Atributo | Significado | Documentar en spec |
|----------|-------------|-------------------|
| `ConfigurationValueType="ApplicationSetting"` | Lee valor de config en runtime | Sí: "Fuente: ApplicationSetting ({ConfigurationValueKey})" |
| `DefaultValue` | Valor por defecto | Sí, si no vacío |
| `UseAsFilter="True"` | Visible en filtros del Dashboard | Informativo |

### Input → Output example

**VDW** (PruebaIsAdmin):
```xml
<ns0:ParameterDefinition Name="LoggedUser" ParamType="SingleValue" DataType="string" IsVariable="True" />
<ns0:ParameterDefinition Name="pIsAdmin" ParamType="SingleValue" DataType="string" IsVariable="False" />
<ns0:ParameterDefinition Name="ExceptionParameter" ParamType="Xml" IsVariable="False" />
```

**Spec output:**
```markdown
### Parámetros de negocio
| Nombre | Tipo | Dirección | Descripción |
|--------|------|-----------|-------------|
| pIsAdmin | string | Output | — |

### Parámetros de sistema
| Nombre | Tipo | Dirección |
|--------|------|-----------|
| LoggedUser | string | Variable |
| ExceptionParameter | XML | Output |
```

---

## End

> **EXCEPCIÓN al contrato estándar.** No hay elemento "End" explícito en WF3.

### What to do

El fin del flujo es implícito — la última actividad del `TyconSequentialWorkflow` es el final. **NO generar una actividad "N. End" en la spec.**

Si hay múltiples caminos de terminación (por IfElse), cada rama termina en su última actividad — documentar como "fin del flujo" en el contexto de esa rama.

Si hay `ExceptionActivity` que lanza una excepción, eso también es un punto de terminación — documentar como "termina con error".

---

## Timer

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador único |
| `TimeoutDuration` | Duración | Formato TimeSpan: `HH:MM:SS` o ISO 8601 `P1D`, `PT30M` |
| `UseBusinessCalendar` | Calendario | `"True"` → hábil, `"False"` → calendario |

Clase VDW: `DelayActivity` (WF3 default namespace).

**Nota:** En VDW reales, `DelayActivity` se usa frecuentemente como "force persistence" con `TimeoutDuration="00:00:00"` (ejemplo: CobroMasivo `ForcePersistence`). En ese caso, documentar como "Forzar persistencia (sin espera real)".

### Input → Output example

**VDW:**
```xml
<DelayActivity x:Name="ForcePersistence" TimeoutDuration="00:00:00" />
```

**Spec output:**
```markdown
### N. ForcePersistence (Timer)
- **ID original**: ForcePersistence
- **Duración**: 00:00:00 (forzar persistencia — sin espera real)
- **Calendario**: calendario (default)
```

**VDW (hipotético con valor real):**
```xml
<DelayActivity x:Name="esperarAprobacion" TimeoutDuration="P2D" UseBusinessCalendar="True" />
```

**Spec output:**
```markdown
### N. esperarAprobacion (Timer)
- **ID original**: esperarAprobacion
- **Duración**: 2 días (P2D)
- **Calendario**: hábil
```

### Encoding notes

`TimeoutDuration` es siempre texto plano (no encoded). Formato TimeSpan de .NET (`HH:MM:SS`) o ISO 8601 (`P1DT2H30M`).

### Anomalías

- `TimeoutDuration` ≤ 0 (negativo) → ⚠️ Warning: `"Timer '{nombre}': duración negativa ({valor}) — no funcional"`
- `TimeoutDuration="00:00:00"` con `x:Name` que NO sugiere persistence → ⚠️ Warning (pero si el nombre indica persistence, es intencional)

---

## SetParameter

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador único |
| `ActivitySources` | Datos de entrada | XML decode → lista de fuentes |
| `OutParametersXslt` | Parámetro y valor asignado | XSLT que mapea valor al parámetro |

Clase VDW: `SetParameterActivity` (namespace `Tycon.BIZUIT.Activities.SetParameter`).

**Nota:** SetParameter NO tiene atributos `ParameterName` o `Value` directos. El mapeo se hace via XSLT:
- `ActivitySources` indica de dónde toma los datos (Variable, Activity)
- `OutParametersXslt` indica a qué parámetro escribe y con qué transformación

### Input → Output example

**VDW** (PruebaIsAdmin `setParameterActivity1`):
```xml
<ns2:SetParameterActivity x:Name="setParameterActivity1"
  ActivitySources="<Sources><Source Id=&quot;LoggedUser&quot; Type=&quot;Variable&quot;/></Sources>"
  OutParametersXslt="<xsl:stylesheet ...><xsl:template match=&quot;/&quot;>
    <xsl:element name=&quot;Root&quot;><xsl:element name=&quot;pUserName&quot;>
      <xsl:value-of select=&quot;Root/LoggedUser/Value&quot;/>
    </xsl:element></xsl:element></xsl:template></xsl:stylesheet>" />
```

**Spec output:**
```markdown
### N. setParameterActivity1 (SetParameter)
- **ID original**: setParameterActivity1
- **Fuente**: LoggedUser (Variable)
- **Asigna**: pUserName = LoggedUser
```

### Encoding notes

- `ActivitySources` está HTML-encoded en atributo → aplicar decode iterativo de `xslt-extraction.md`
- `OutParametersXslt` está HTML-encoded → aplicar decode
- `Xslt` y `RuntimeInputXslt` frecuentemente `{x:Null}` para SetParameter (no tiene input mapping propio)

### Anomalías

- Si no hay `OutParametersXslt` ni `RuntimeOutputXslt` (ambos null/vacíos) → ⚠️ Warning: `"SetParameter '{nombre}': sin asignación definida"`

---

## SetValue

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador único |
| `ActivitySources` | Datos de entrada | Variables/actividades fuente |
| `Xslt` o `RuntimeInputXslt` | Transformación input | XSLT de mapeo |
| `OutParametersXslt` o `RuntimeOutputXslt` | Variable y valor asignado | XSLT que escribe la variable |

Clase VDW: `SetValueActivity` (namespace `Tycon.BIZUIT.Activities`).

**Diferencia con SetParameter:** SetValue opera sobre **variables internas** del workflow (counters, flags, acumuladores). SetParameter opera sobre **parámetros** del proceso (inputs/outputs visibles). En la spec se documentan igual pero con tipo diferente.

**Encontrado en:** CobranzaEntidad (14 instancias) — usado para contadores (`procesados`, `Identificado`, `Imputado`).

### Input → Output example

**VDW** (CobranzaEntidad `procesados`):
```xml
<ns:SetValueActivity x:Name="procesados"
  ActivitySources="<Sources><Source Id=&quot;vProcesados&quot; Type=&quot;Variable&quot;/>...</Sources>"
  Xslt="<xsl:stylesheet ...>..."
  OutParametersXslt="<xsl:stylesheet ...>...<xsl:element name=&quot;vProcesados&quot;>..." />
```

**Spec output:**
```markdown
### N. procesados (SetValue)
- **ID original**: procesados
- **Variable**: vProcesados
- **Operación**: actualiza contador de procesados
```

### Encoding notes

- XSLT puede estar plain XML (CobranzaEntidad) o single HTML-encoded — usar decode iterativo
- Preferir `RuntimeInputXslt` sobre `Xslt` si presente (regla de `xslt-extraction.md`)

### Anomalías

- Ninguna específica — SetValue es una operación interna sin riesgo

---

## SqlActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador único |
| `ConfigFileCnnStringName` | Conexión | Nombre de connection string en config (ej: `RDAFFConection`) |
| `CommandText` | Query | SQL a ejecutar. Puede tener `\r\n`. Aplicar decode si necesario. |
| `CommandType` | Tipo de comando | `"Text"` o `"StoredProcedure"` |
| `ReturnType` | Tipo de retorno | `"DataSet"`, `"Scalar"`, `"NonQuery"` |
| `CommandTimeout` | Timeout | Segundos. `"0"` = default de conexión (normal). |
| `ConnectionStringSource` | Fuente de conexión | `"FromConfigurationFile"` (normal) o `"FromActivity"` (anomalía si literal) |
| `ConnectionString` | — | Siempre encriptado en producción. No incluir en spec. |
| `ActivitySources` | Datos de entrada | XML decode → lista de fuentes |
| `Xslt` / `RuntimeInputXslt` | Input mapping | XSLT que mapea parámetros a `@variables` SQL |
| `OutParametersXslt` / `RuntimeOutputXslt` | Output mapping | XSLT que extrae resultados del DataSet |

Clase VDW: `SqlActivity` (namespace `Tycon.BIZUIT.Activities.Sql`).

**ParameterBindings:** Cada `SqlActivity` tiene hijos `<WorkflowParameterBinding ParameterName="@NombreParam" />` que listan los parámetros SQL. Estos se combinan con el XSLT para determinar qué valores se pasan.

### Input → Output example

**VDW** (PruebaIsAdmin `checkIsAdmin`):
```xml
<ns1:SqlActivity x:Name="checkIsAdmin"
  ConfigFileCnnStringName="RDAFFConection"
  CommandText="select count(*) IsAdmin &#xD;&#xA;from users u&#xD;&#xA;inner join UserRoles ur on u.UserID=ur.UserID and ur.RoleID=8&#xD;&#xA;where username=@Username"
  CommandType="Text" ReturnType="DataSet" CommandTimeout="0"
  ConnectionStringSource="FromConfigurationFile">
  <ns1:SqlActivity.ParameterBindings>
    <WorkflowParameterBinding ParameterName="@Username" />
  </ns1:SqlActivity.ParameterBindings>
</ns1:SqlActivity>
```

**Spec output:**
```markdown
### N. checkIsAdmin (SQL)
- **ID original**: checkIsAdmin
- **Conexión**: RDAFFConection (ConfigFile)
- **Query**: `select count(*) IsAdmin from users u inner join UserRoles ur on u.UserID=ur.UserID and ur.RoleID=8 where username=@Username`
- **Tipo de comando**: Text
- **Tipo de retorno**: DataSet
- **Parámetros de entrada**: @Username
- **Salida**: IsAdmin (columna del DataSet)
```

### Encoding notes

- `CommandText` puede estar:
  - Plain text con `\r\n` literales (CobranzaEntidad)
  - HTML-encoded con `&#xD;&#xA;` para newlines (PruebaIsAdmin, CobroMasivo)
  - Aplicar decode iterativo de `xslt-extraction.md` en todos los casos
- `Xslt`, `OutParametersXslt` → HTML-encoded o plain XML → decode iterativo
- `ConnectionString` → **siempre encriptada** (Base64 corto como `rK1RLKKBRvk=`). NO incluir en spec.

### Anomalías

- `ConnectionStringSource="FromActivity"` con `ConnectionString` largo (>50 chars, contiene `Server=`) → ⚠️ Warning: connection string hardcodeada
- Valor hardcodeado en SQL (FR24): un literal numérico en condición WHERE/JOIN no precedido por `@` → ⚠️ Warning: `"SQL '{nombre}': valor hardcodeado {campo}={valor} en query (considerar parametrizar)"`
  - Ejemplo: `ur.RoleID=8` → `8` es hardcodeado (no `@RoleID`)
  - NO reportar: valores en LIMIT/TOP, constantes 0/1 en flags, fechas

---

## RestFullActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador único |
| `RestFullUrl` | URL | Puede tener placeholders `@{param}`. URL design-time; runtime se calcula via XSLT. |
| `RestFullMethod` | Método HTTP | `GET`, `POST`, `PUT`, `DELETE` |
| `RestFullTimeout` | Timeout | Segundos |
| `AuthorizationType` | Auth | `"Basic Auth"`, `"Bearer"`, `"None"` |
| `RestFullUseAuth` | Usa auth | `"True"`/`"False"` |
| `ContentType` | Content type | Puede ser null |
| `QuantityOfRetries` | Reintentos | `"0"` = sin reintentos |
| `RetryTimeout` | Timeout reintento | Segundos entre reintentos |
| `ActivitySources` | Datos de entrada | Variables/actividades fuente |
| `RuntimeInputXslt` | URL y body runtime | XSLT con funciones VBScript que construyen URL y body |

Clase VDW: `RestFullActivity` (namespace `Tycon.BIZUIT.Activities.RestFull`).

**Nota:** La URL en `RestFullUrl` es frecuentemente un **placeholder design-time** con valores de test hardcodeados (ej: `instanceId=1321321321`). La URL real se construye en runtime via `RuntimeInputXslt` con funciones VBScript. Para la spec, documentar ambas: la URL base y las variables que la componen.

### Input → Output example

**VDW** (CobroMasivo `UploadToApi`):
```xml
<ns6:RestFullActivity x:Name="UploadToApi"
  RestFullUrl="https://rdaffbizuitapi-devtest.azurewebsites.net/api/RDAFF/DEUDAS/action/CargarExcel?instanceId=1321321321"
  RestFullMethod="POST" RestFullTimeout="5"
  AuthorizationType="Basic Auth" RestFullUseAuth="False"
  QuantityOfRetries="0" RetryTimeout="0" />
```

**Spec output:**
```markdown
### N. UploadToApi (REST)
- **ID original**: UploadToApi
- **URL**: `{vAPIURL}/api/RDAFF/DEUDAS/action/CargarExcel?instanceId={InstanceId}` (runtime via XSLT)
- **Método**: POST
- **Timeout**: 5 seg
- **Auth**: Basic Auth (deshabilitada)
- **Reintentos**: 0
```

### Encoding notes

- `RestFullUrl` es plain text (no encoded)
- `RuntimeInputXslt` contiene VBScript que construye la URL — decode con `xslt-extraction.md`
- Credenciales (`AuthorizationUser`, `AuthorizationPass`, `BearerToken`) frecuentemente `{x:Null}` — no documentar si null

### Anomalías

- `RestFullUseAuth="True"` con credenciales en texto plano → anomalía password (via `xslt-extraction.md`)
- `RestFullTimeout="0"` o muy bajo (< 3 seg) → informativo, no anomalía
- URL hardcodeada con datos de test (ej: `instanceId=1321321321`) → documentar nota "URL design-time con datos de test"

---

## EmailActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador único |
| `Subject` | Asunto | Puede contener placeholders `[:param:]` |
| `To` | Destinatario | Puede ser null (resuelto via XSLT) |
| `CC` | CC | Puede ser null |
| `SmtpServer` | Servidor SMTP | Puede ser null (usa config) |
| `SmtpPort` | Puerto | — |
| `Password` | Password SMTP | **Siempre encriptado** en VDW reales (Base64). |
| `UseSsl` | SSL | `"True"`/`"False"` |
| `FromName` | Nombre remitente | — |
| `FromAddress` | Email remitente | — |
| `ActivitySources` | Datos de entrada | Variables/actividades fuente |
| `Xslt` / `RuntimeInputXslt` | Contenido del email | XSLT que genera el body HTML |

Clase VDW: `EmailActivity` (namespace `Tycon.BIZUIT.Activities` — namespace base, no dedicado).

**Nota:** En VDW reales (CobranzaEntidad), `To` y `CC` son frecuentemente null — los destinatarios se resuelven via XSLT en runtime. El `Subject` puede contener placeholders BIZUIT como `[:Entidad:]` que se reemplazan por el valor del parámetro `Entidad`.

### Input → Output example

**VDW** (CobranzaEntidad `notificaCobroConError`):
```xml
<ns:EmailActivity x:Name="notificaCobroConError"
  Subject="[:Entidad:] - Error de proceso en la Carga de cobros"
  To="{x:Null}" CC="{x:Null}"
  Password="fZg4MKkDfUOfIdEYxxp4MQ==" />
```

**Spec output:**
```markdown
### N. notificaCobroConError (Email)
- **ID original**: notificaCobroConError
- **Asunto**: {Entidad} - Error de proceso en la Carga de cobros
- **Destinatario**: (resuelto en runtime via XSLT)
- **CC**: —
- **Password SMTP**: ***ENMASCARADO*** (encriptado en VDW)
```

### Encoding notes

- `Subject` usa placeholders BIZUIT `[:param:]` — traducir a `{param}` en la spec
- `Password` siempre encriptado en VDW reales (Base64, >20 chars). Documentar como `***ENMASCARADO***` por precaución.
- `Body` puede estar en XSLT (HTML generado dinámicamente) — documentar "body dinámico via XSLT"

### Anomalías

- Password en texto plano (no Base64, >50 chars, contiene `@` o caracteres comunes) → 🔴 Error via `xslt-extraction.md`
- Sin `To` ni XSLT que resuelva destinatario → ⚠️ Warning: "email sin destinatario definido"

---

## UserTask

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador único |
| `FormType` | Tipo de formulario | Puede ser null (bandeja default) |
| `AssignmentType` | Tipo de asignación | Puede ser null |
| `Subject` | Asunto | Título de la tarea |
| `Body` | Descripción | Instrucciones al usuario |
| `Expiration` | Expiración | TimeSpan. `"00:00:00"` = sin expiración |
| `SchedulerEnabled` | Acciones programadas | `"True"`/`"False"` |
| `Instructions` | Instrucciones RTF | **Base64-encoded RTF** — no HTML |
| `VisibleDescriptionColumns` | Columnas visibles | Child elements con Name, HeaderText, ColumnType |
| `ReactionDescriptionParameters` | Campos de reacción | Child elements con Name |
| `Permissions` | Permisos por rol | Child elements WorkflowPermissionElementValue |

Clase VDW: `UserInteractionActivity` (namespace `Tycon.BIZUIT.Activities.ExternalEventHandlers`).

**Estructura de hijos importantes:**

```xml
<ns:UserInteractionActivity x:Name="ResultadoCargaMasiva" ...>
  <ns:UserInteractionActivity.VisibleDescriptionColumns>
    <ns:VisibleDescriptionColumnCollection>
      <ns:VisibleDescriptionColumn Name="xCol_..." HeaderText="Fecha" ColumnType="NetParameter" />
      <ns:VisibleDescriptionColumn Name="xCol_..." HeaderText="Importe" ColumnType="NetParameter" />
    </ns:VisibleDescriptionColumnCollection>
  </ns:UserInteractionActivity.VisibleDescriptionColumns>
  <ns:UserInteractionActivity.ReactionDescriptionParameters>
    <ns:ReactionDescriptionParameterCollection>
      <ns:ReactionDescriptionParameter Name="UserName" />
      <ns:ReactionDescriptionParameter Name="PersistedDate" />
    </ns:ReactionDescriptionParameterCollection>
  </ns:UserInteractionActivity.ReactionDescriptionParameters>
  <ns:UserInteractionActivity.Permissions>
    <ns:WorkflowPermissionElementValue RoleName="GestorCobranza" PermissionType="Role" />
  </ns:UserInteractionActivity.Permissions>
</ns:UserInteractionActivity>
```

### Input → Output example

**VDW** (CobranzaEntidad `PendienteProcesar`):

**Spec output:**
```markdown
### N. PendienteProcesar (UserTask)
- **ID original**: PendienteProcesar
- **Formulario**: bandeja default
- **Columnas visibles**:
  - Entidad de Cobranza
  - Archivo
  - Fecha ejecución
  - Ejecutado por
- **Campos de reacción**: UserName, PersistenceUser, PersistedDate, ActivityName, EventName
- **Permisos**: (por defecto)
- **Expiración**: sin expiración
```

### Encoding notes

- `Instructions` es **Base64 RTF** — decodificar Base64 y extraer texto plano del RTF, o documentar "instrucciones RTF presentes"
- `Subject` y `Body` son plain text (no encoded)
- `VisibleDescriptionColumn.HeaderText` es plain text — usar directamente como nombre de columna en la spec
- `ColumnType` puede ser: `NetParameter` (dato del proceso), `PersistenceUser`, `IdledDateTime`, `TimeElapsed` (metadatos del sistema)

### Anomalías

- Sin columnas visibles → ⚠️ Warning: "UserTask sin columnas configuradas"
- Sin permisos asignados (ni Role ni User) → informativo: "UserTask abierta a todos los usuarios"

---

## IfElseActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador del gateway |
| `IfElseBranchActivity` (hijos) | Branches/caminos | Cada hijo es un branch |
| Branch `x:Name` | Nombre del camino | Ej: `siTransferencia`, `ApiOk` |
| Branch condition | Condición | Pipe-delimited o CodeDom (ver `condition-extraction.md`) |

Clase VDW: `IfElseActivity` (WF3 default namespace `http://schemas.microsoft.com/winfx/2006/xaml/workflow`).

**Estructura:**
```xml
<IfElseActivity x:Name="segunEntidad">
  <IfElseBranchActivity x:Name="siTransferencia">
    <!-- actividades hijas del branch -->
  </IfElseBranchActivity>
  <IfElseBranchActivity x:Name="siMercadoPago">
    <!-- actividades hijas -->
  </IfElseBranchActivity>
  <IfElseBranchActivity x:Name="other">
    <!-- último branch sin condición = default/else -->
  </IfElseBranchActivity>
</IfElseActivity>
```

**Puede tener N branches** (no solo 2). CobranzaEntidad `segunEntidad` tiene 4 branches.

**Regla de condiciones:**
- Todos los branches tienen condición **excepto el último** (extremo derecho)
- El último branch **NO tiene condición** — es el **else/default**
- Debe haber **exactamente 1** branch sin condición, y siempre es el último
- Condiciones están en elementos `WorkflowConditionDescription` en la sección `ConditionDescriptions` del root, referenciadas por nombre del branch. Extraer usando `condition-extraction.md`.

### Numeración de actividades en branches

**Regla:** El contador es **compartido entre todas las ramas** — NO se reinicia por rama.

```
### 3. segunEntidad (Gateway Exclusivo)
- **Camino siTransferencia** (condición: ...):
  - 3.1. getDatosTransfe (SQL)
  - 3.2. checkExist (SQL)
  - 3.3. ...
- **Camino siMercadoPago** (condición: ...):
  - 3.7. getDatosMP (SQL)    ← continúa desde donde terminó el branch anterior
  - 3.8. ...
- **Camino default** (other):
  - 3.13. ...
```

### Input → Output example

**VDW** (CobroMasivo):
```xml
<IfElseActivity x:Name="ApiResponse">
  <IfElseBranchActivity x:Name="ApiOk">
    <SqlActivity x:Name="getCobro" />
    <SqlActivity x:Name="getTotalCobranza" />
    ...
  </IfElseBranchActivity>
  <IfElseBranchActivity x:Name="ApiError">
    <SetParameterActivity x:Name="setErrorApi" />
    <ExceptionActivity x:Name="exceptionApi" />
  </IfElseBranchActivity>
</IfElseActivity>
```

**Spec output:**
```markdown
### 3. ApiResponse (Gateway Exclusivo)
- **Condición**: Resultado API == "200"
- **Camino ApiOk** (status OK):
  - 3.1. getCobro (SQL)
  - 3.2. getTotalCobranza (SQL)
  - ...
- **Camino ApiError** (default — error):
  - 3.8. setErrorApi (SetParameter)
  - 3.9. exceptionApi (Exception — termina con error)
```

### Encoding notes

- Las condiciones pueden estar en dos formatos (ver `condition-extraction.md`)
- Los nombres de branch son plain text
- Las actividades hijas se parsean recursivamente con el mismo algoritmo

### Anomalías

- Solo 1 branch (sin else) → ⚠️ Warning: `"Gateway '{nombre}': sin camino alternativo (default flow ausente)"`

---

## ParallelActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| Hijos directos | Ramas paralelas | Cada hijo = rama que ejecuta en paralelo |

Clase VDW: `ParallelActivity` (WF3 default namespace) o `TyconParallelActivity` (Tycon namespace).

**No encontrado en los 3 VDW de análisis.** Documentado basándose en `activity-types.md`.

### Input → Output example

**Spec output:**
```markdown
### N. procesarEnParalelo (Gateway Paralelo)
- **ID original**: procesarEnParalelo
- **Tipo**: Todas las ramas deben completar antes de continuar
- **Rama A**:
  - N.1. consultarSistemaA (SQL)
  - N.2. procesarRespuestaA (SetParameter)
- **Rama B**:
  - N.3. consultarSistemaB (REST)
```

### Encoding notes

Mismas reglas que IfElse — actividades hijas se parsean recursivamente.

### Anomalías

- Solo 1 rama → ⚠️ Warning: `"Parallel '{nombre}': una sola rama (considerar secuencial)"`

---

## ForActivity / ForEachActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| `IterationXPath` | Datos de iteración | XPath sobre qué iterar (ej: `root/hoja1s/hoja1`) |
| `SourceData` | Fuente de datos | Parámetro o variable con la lista |
| `ItemName` | Variable de iteración | Nombre del item actual |
| `ExecutionMode` | Modo | `"Transactional"` / `"BestEffort"` |

Clase VDW: `ForEachActivity` (namespace `Tycon.BIZUIT.Activities`).

**Hallazgo real (CobranzaEntidad):** `ForEachActivity` usa `IterationXPath` en lugar de `SourceData` para definir la iteración. `SourceData` e `ItemName` son frecuentemente null.

```xml
<ns:ForEachActivity x:Name="porcadaRenglon"
  IterationXPath="root/hoja1s/hoja1"
  SourceData="{x:Null}" ItemName="{x:Null}" />
```

Las actividades hijas del ForEach se parsean recursivamente — cada iteración ejecuta la misma secuencia.

### Input → Output example

**VDW** (CobranzaEntidad `porcadaRenglon`):

**Spec output:**
```markdown
### N. porcadaRenglon (For Each)
- **ID original**: porcadaRenglon
- **Itera sobre**: root/hoja1s/hoja1 (cada fila del Excel)
- **Actividades por iteración**:
  - N.1. getDatosTransfe (SQL)
  - N.2. checkExist (SQL)
  - N.3. ...
```

### Encoding notes

- `IterationXPath` es plain text (no encoded)
- Actividades hijas se parsean recursivamente

### Anomalías

- Sin `IterationXPath` ni `SourceData` (ambos null/vacíos) → 🔴 Error: `"For '{nombre}': sin datos de iteración — iteración sobre nada"`

---

## SequenceActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| Hijos directos | Actividades del bloque | Se parsean en orden secuencial |

Clase VDW: `SequenceActivity` (WF3 default namespace).

**Hallazgo real (CobranzaEntidad):** `SequenceActivity` es un container de secuencia simple — agrupa actividades que se ejecutan en orden. En CobranzaEntidad contiene SQL, SetParameter e IfElse como hijos directos. No tiene `FaultHandlers` visibles como hijos (esos están en `ExceptionActivity` o `FaultHandlersActivity`).

**Diferencia con la story:** La story dice que Sequence "representa try/catch con FaultHandlers". En la práctica, `SequenceActivity` puro es solo agrupación secuencial. El try/catch es `ExceptionActivity` (story 2.6).

### Input → Output example

**VDW** (CobranzaEntidad `sequenceActivity1`):
```xml
<SequenceActivity x:Name="sequenceActivity1">
  <SqlActivity x:Name="agregaMP" />
  <SetParameterActivity x:Name="setDNI" />
  <SqlActivity x:Name="getDetalleDeuda" />
  <IfElseActivity x:Name="identificaMP" />
  <SqlActivity x:Name="InsertarDetalleCobranza" />
</SequenceActivity>
```

**Spec output:**
```markdown
### N. sequenceActivity1 (Secuencia)
- **ID original**: sequenceActivity1
- **Actividades**:
  - N.1. agregaMP (SQL)
  - N.2. setDNI (SetParameter)
  - N.3. getDetalleDeuda (SQL)
  - N.4. identificaMP (Gateway Exclusivo)
    - ...
  - N.5. InsertarDetalleCobranza (SQL)
```

### Encoding notes

Sin encoding especial — solo nombres y estructura.

### Anomalías

- Sequence vacío (sin hijos) → ⚠️ Warning: `"Sequence '{nombre}': vacío — sin actividades"`

---

## ExceptionActivity / FaultHandlersActivity

### Attributes to extract

**Dos elementos distintos pero relacionados:**

| Elemento | Clase VDW | Rol |
|----------|-----------|-----|
| `FaultHandlersActivity` | WF3 default ns | Container de error handling del proceso. Último hijo del root. |
| `FaultHandlerActivity` | WF3 default ns | Handler individual para un tipo de excepción. Hijo de FaultHandlersActivity. |
| `ExceptionActivity` | `Tycon.BIZUIT.Activities.ThrowException` | Actividad que **lanza** una excepción. |

**FaultHandlersActivity** es el equivalente del `catch` global del proceso. Está al final del `TyconSequentialWorkflow`.

**FaultHandlerActivity** atributos:

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID del handler | Ej: `Exception1` |
| `FaultType` | Tipo de excepción | Ej: `{x:Type p17:Exception}` (System.Exception) |
| Hijos directos | Actividades del handler | Se parsean recursivamente |

**ExceptionActivity** atributos:

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| `ExceptionMessage` | Mensaje de error | Texto directo del error (cuando `FromText="True"`) |
| `WorkflowElementType` | Fuente del mensaje | `"Parameter"` = lee de un parámetro, `"Activity"` = lee de output de actividad |
| `WorkflowElementName` | Nombre de la fuente | Ej: `MensajeError` (parámetro) o `setError` (actividad) |
| `FromText` | Modo de mensaje | `"True"` = texto directo en `ExceptionMessage`. `"False"` = referencia a parámetro/actividad via `WorkflowElementName` |

**Dos modos de mensaje:**
1. **Texto directo** (`FromText="True"`): el mensaje está en `ExceptionMessage` como texto fijo
2. **Por referencia** (`FromText="False"`): el mensaje se toma del parámetro/actividad indicado en `WorkflowElementName`

### Input → Output example

**VDW** (CobroMasivo):
```xml
<!-- Al final del root: container de error -->
<FaultHandlersActivity x:Name="ExceptionContainer">
  <FaultHandlerActivity x:Name="Exception1" FaultType="{x:Type p17:Exception}">
    <SetParameterActivity x:Name="setParameterActivity1" />
    <UserInteractionActivity x:Name="ErrordeProceso" />
  </FaultHandlerActivity>
</FaultHandlersActivity>

<!-- Dentro del flujo: lanza excepción -->
<ns8:ExceptionActivity x:Name="exceptionApi"
  ExceptionMessage="{x:Null}"
  WorkflowElementType="Parameter"
  WorkflowElementName="MensajeError"
  FromText="False" />
```

**Spec output:**
```markdown
## Manejo de Errores

### ExceptionContainer (Error Handler Global)
- **Tipo capturado**: System.Exception (cualquier error)
- **Actividades del handler**:
  - setParameterActivity1 (SetParameter)
  - ErrordeProceso (UserTask — muestra error al usuario)

---

### N. exceptionApi (Lanza Excepción)
- **ID original**: exceptionApi
- **Mensaje**: valor del parámetro `MensajeError`
- **Efecto**: termina el flujo actual y activa el ExceptionContainer
```

### Encoding notes

- `ExceptionMessage` es plain text o null
- `WorkflowElementName` es plain text — nombre del parámetro
- `FaultType` usa sintaxis WF3 `{x:Type namespace:Type}`

### Anomalías

- `FaultHandlersActivity` vacío (sin `FaultHandlerActivity` hijos) → **NO es anomalía**. Es válido que un proceso no tenga manejo de errores global configurado.
- `FaultHandlerActivity` sin actividades hijas → informativo: "Error handler configurado pero sin acciones"

---

## ExpirableActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| `Expiration` | Tiempo de expiración | TimeSpan. `"00:00:00"` = sin expiración (espera infinita) |
| `UseBusinessCalendar` | Calendario | `"True"` = hábil, null/`"False"` = calendario |
| `CalendarName` | Nombre calendario | Puede ser null |
| Hijos directos | Actividad envuelta + handler | Primer hijo = actividad envuelta, `ExpirationHandlerActivity` = acciones al vencer |

Clase VDW: `ExpirableActivity` (namespace `Tycon.BIZUIT.Activities.Expiration`).

**Estructura:**
```xml
<ns7:ExpirableActivity x:Name="expirableActivity1" Expiration="00:00:00">
  <ns10:WhileCustomSequence x:Name="whileCustomSequence1">
    <ns9:UserInteractionActivity x:Name="ResultadoCargaMasiva" />
  </ns10:WhileCustomSequence>
  <ns7:ExpirationHandlerActivity x:Name="expirationHandlerActivity1">
    <!-- acciones si expira -->
  </ns7:ExpirationHandlerActivity>
</ns7:ExpirableActivity>
```

**Hallazgo real:** `Expiration="00:00:00"` = espera infinita (sin expiración). Es el patrón de "wait for user task" — envuelve un UserTask en un loop que no expira.

### Input → Output example

**VDW** (CobroMasivo):

**Spec output:**
```markdown
### N. expirableActivity1 (Expirable — SLA: sin expiración)
- **ID original**: expirableActivity1
- **Expiración**: sin expiración (espera indefinida)
- **Actividad envuelta**: whileCustomSequence1 (loop de espera)
  - ResultadoCargaMasiva (UserTask)
- **Al vencer**: (sin acciones — expiración deshabilitada)
```

### Encoding notes

- `Expiration` es TimeSpan plain text
- Hijos se parsean recursivamente

### Anomalías

- `ExpirationHandlerActivity` sin hijos → ⚠️ Warning: `"Expirable '{nombre}': sin acciones al vencer"`
- `Expiration="00:00:00"` → informativo (no anomalía): "espera indefinida — sin SLA"

---

## SendMessageActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| `EventName` | Proceso destino | Nombre del evento/proceso receptor (**no** `TargetProcess`) |
| `MessageType` | Tipo de mensaje | `"1"` = llamada estándar |
| `WaitForInstancesCompletion` | Espera respuesta | `"True"` = síncrono (espera que termine), `"False"` = fire-and-forget |
| `StopOnError` | Detener en error | `"True"` = si el proceso llamado falla, este también falla |
| `RetryCount` | Reintentos | Número de reintentos |
| `ShareDocuments` | Compartir docs | `"True"` = comparte documentos adjuntos |
| `Parameters` | Parámetros | XML con EventName, WorkflowName y datos enviados |
| `ActivitySources` | Datos de entrada | Variables/actividades fuente para XSLT |
| `OutParameters` | Parámetros de salida | Output que recibe del proceso llamado |

Clase VDW: `SendMessageActivity` (namespace `Tycon.BIZUIT.Activities`).

**Encontrado en:** CallActivityPrueba (test env) — `EventName="InvocarDesdeCallActivity_flor"`.

**Nota importante:** El atributo es `EventName` (nombre del proceso destino en BIZUIT), NO `TargetProcess`. `Parameters` contiene un XML con la configuración completa de la llamada.

### Input → Output example

**VDW** (CallActivityPrueba `call_activity`):
```xml
<ns:SendMessageActivity x:Name="call_activity"
  EventName="InvocarDesdeCallActivity_flor"
  MessageType="1"
  WaitForInstancesCompletion="True"
  StopOnError="True"
  RetryCount="0"
  ShareDocuments="False"
  ActivitySources="<Sources><Source Id=&quot;pInCallActivity&quot; Type=&quot;Parameter&quot;/>...</Sources>"
  OutParameters="<OutputParameters><OutputParameter Name=&quot;pInCallActivity&quot; />...</OutputParameters>" />
```

**Spec output:**
```markdown
### N. call_activity (SendMessage — Call Activity)
- **ID original**: call_activity
- **Proceso destino**: InvocarDesdeCallActivity_flor
- **Espera respuesta**: Sí (síncrono)
- **Detener en error**: Sí
- **Reintentos**: 0
- **Parámetros enviados**: pInCallActivity, pInPablo
- **Parámetros recibidos**: pInCallActivity, pInPablo
```

### Encoding notes

- `EventName` es plain text
- `Parameters` es XML (puede necesitar decode)
- `ActivitySources` y `OutParameters` son HTML-encoded → decode iterativo

### Anomalías

- Sin `EventName` → 🔴 Error: `"SendMessage '{nombre}': sin proceso destino (EventName vacío)"`
- `WaitForInstancesCompletion="True"` sin manejo de error → informativo

---

## ReceiveMessageActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| `MessageName` | Mensaje esperado | Nombre del tipo de mensaje |
| Datos recibidos | Parámetros de respuesta | Mapping via XSLT |

Clase VDW: `ReceiveMessageActivity` (namespace `Tycon.BIZUIT.Activities`).

**No encontrado en los 3 VDW de análisis.**

### Input → Output example

**Spec output:**
```markdown
### N. esperarRespuesta (ReceiveMessage)
- **ID original**: esperarRespuesta
- **Mensaje esperado**: RespuestaNotificacion
- **Datos recibidos**: resultado, fechaProcesamiento
```

### Anomalías

- Ninguna específica

---

## CallWorkflowActivity

### Attributes to extract

| Atributo VDW | Spec field | Notas |
|---|---|---|
| `x:Name` | ID original | Identificador |
| `CalledProcess` | Subproceso invocado | Nombre del workflow llamado |
| Input/Output mappings | Parámetros | Via XSLT |

Clase VDW: `CallWorkflowActivity` (namespace `Tycon.BIZUIT.Activities`).

**No encontrado en los 3 VDW de análisis.**

### Input → Output example

**Spec output:**
```markdown
### N. llamarSubproceso (CallWorkflow)
- **ID original**: llamarSubproceso
- **Subproceso**: ProcesoValidacion
- **Parámetros de entrada**: pClienteId, pMonto
- **Parámetros de salida**: pResultado
```

### Anomalías

- Sin parámetros de entrada ni salida → ⚠️ Warning: `"CallWorkflow '{nombre}': sin parámetros documentados"`

---

## Actividad desconocida (FR28)

### When this applies

Cuando el parser encuentra un elemento XML con namespace+clase que **no está en el catálogo de tipos MVP ni reconocidos** (ver `activity-types.md`).

### What to do

1. **NO fallar** — continuar parseando las actividades hermanas
2. Documentar la actividad con el **Spec "Not Parsed" Activity Pattern**
3. Usar `DisplayName` si presente, sino `x:Name`, sino `{TipoClase}_{posición}`

### Example

**VDW:**
```xml
<ns4:FileActivity x:Name="DeleteExistingFile" ... />
```

**Spec output:**
```markdown
### N. DeleteExistingFile (⚠️ No parseada)
- **Tipo VDW**: FileActivity (Tycon.BIZUIT.Activities.FileAct)
- **Nota**: Esta actividad no pudo ser interpretada completamente. Requiere revisión manual en el editor.
```

### Tipos no-MVP encontrados en VDW reales

| Tipo | VDW | Tratamiento sugerido |
|------|-----|---------------------|
| `FileActivity` | CobroMasivo (2) | ⚠️ No parseada |
| `ZipActivity` | CobroMasivo (1) | ⚠️ No parseada |
| `TransactionActivity` | CobroMasivo (1), CobranzaEntidad (1) | **Parsear como container** — documentar hijos normalmente |
| `WhileCustomSequence` | CobroMasivo (1), CobranzaEntidad (2), EQV (múltiples) | **Container transparente** — NO es actividad, es body de WhileActivity. Parsear hijos directamente como si fueran del parent. |
| `SplitActivity` | CobranzaEntidad (4) | ⚠️ No parseada (variante de parallel) |
| `StartPointActivity` | CobroMasivo (1) | Ignorar (marcador de inicio, no-op) |

### Gotchas

- `TransactionActivity` se parsea como container simple (documentar hijos)
- `WhileCustomSequence` es **container transparente** — no es actividad, parsear hijos directamente (sin esto, el parser pierde todas las actividades anidadas dentro de WhileActivity)
- Nunca fallar por un tipo desconocido — el reverse debe completar siempre
- Contar actividades no parseadas para el reporte final ("`{N} actividades no parseadas de {M} total`")

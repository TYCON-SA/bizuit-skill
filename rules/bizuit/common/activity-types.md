# Activity Types — BIZUIT

> Fuente de verdad para los 15 tipos de actividad del MVP.
> Usado por generation/ (spec→BPMN) y parsing/ (VDW→spec).
> Si hay conflicto entre este archivo y otro, este archivo gana.

## 15 Tipos MVP

| Tipo | Clase VDW (XAML) | Tipo BPMN | Atributos Clave |
|---|---|---|---|
| SQL Service Task | SqlActivity | bpmn2:serviceTask (bizuit:serviceTaskType="sql") | ConfigFileCnnStringName, CommandText, CommandType ("Text"/"StoredProcedure"), ReturnType ("DataSet"/"Scalar"/"NonQuery"), CommandTimeout, ConnectionStringSource ("FromConfigurationFile"/"FromActivity"), DbType ("SqlServer") |
| REST Service Task | RestFullActivity | bpmn2:serviceTask (bizuit:serviceTaskType="ws") | restUrl, restVerb ("GET"/"POST"/"PUT"/"DELETE"), restBody, restHeaders |
| Email/Send Task | EmailActivity / SendTask | bpmn2:sendTask | emailTo, emailSubject, emailBody, emailServiceType ("SMTP"/"GoogleAPI"), emailHost, emailPort |
| User Task | UserInteractionActivity | bpmn2:userTask | Performers (rol), Accountable, FormId, ExpirationTime, ScheduledActions |
| Exclusive Gateway | IfElseBranchActivity | bpmn2:exclusiveGateway | Condition (pipe-delimited en VDW, conditionExpression en BPMN), DefaultFlow |
| Parallel Gateway | TyconParallelActivity | bpmn2:parallelGateway | JoinCondition |
| Timer/Delay | DelayActivity | bpmn2:intermediateCatchEvent (timer) | DelayDuration, CalendarRef |
| For (Iteración) | ForActivity | bpmn2:subProcess (loop) | InputParameter (lista a iterar), ItemVariable |
| Sequence (Try/Catch) | SequenceActivity | bpmn2:subProcess | FaultHandlers (catch blocks) |
| Exception | ExceptionActivity | (dentro de FaultHandlers) | ErrorType, ErrorMessage |
| Expirable | ExpirableActivity | bpmn2:userTask + bizuit:expiration | ExpirationTime, EscalationAction, WarningTime |
| Set Parameter | SetParameterActivity | bpmn2:scriptTask (bizuit:scriptTaskMode="sp") | OutputParameter, Expression |
| Send Message | SendMessageActivity | bpmn2:intermediateThrowEvent (message) | TargetProcess, MessageName, MessageParameters |
| Receive Message | ReceiveMessageActivity | bpmn2:intermediateCatchEvent (message) | MessageName, ResponseParameters |
| Call Activity | CallActivity | bpmn2:callActivity | CalledProcess, InputMappings, OutputMappings |

### Notas por tipo

- **Booleans**: siempre "True"/"False" con mayúscula (no "true"/"false")
- **Enums**: case-sensitive. "DataSet" no "dataset". "Text" no "text".
- **ConnectionStringSource**: "FromConfigurationFile" (usa ConfigFileCnnStringName) o "FromActivity" (valor directo)
- **Conditions**: pipe-delimited en VDW (`Amount|Parameter||>|10000|Undefined|||Eliminar|-`), conditionExpression simple en BPMN (`Amount > 10000`)

## Atributos comunes a TODOS los tipos

Estos atributos existen en cada actividad del VDW:

| Atributo | Descripción |
|---|---|
| x:Name | ID técnico de la actividad |
| DisplayName | Nombre legible (puede diferir de x:Name) |
| ActivitySources | XML con dependencias de input (parámetros, variables, actividades anteriores) |
| Xslt | XSLT de input (HTML-encoded) |
| RuntimeInputXslt | XSLT runtime de input (= Xslt) |
| OutParametersXslt | XSLT de output (HTML-encoded) |
| RuntimeOutputXslt | XSLT runtime de output (= OutParametersXslt) |
| LinksDefinitions | XML de path mapping input |
| OutParametersLinksDefinitions | XML de path mapping output |
| OutParameters | XML lista de parámetros de salida |
| PerformTracking | "PerformTracking" (string literal) |
| EnableRoleValidation | "True" o "False" |

## Parámetros de Sistema (FR14)

Inyectados automáticamente por BIZUIT en todo proceso:

| Nombre | Tipo | Dirección | Descripción |
|---|---|---|---|
| InstanceId | string | Variable | ID único de la instancia en ejecución |
| LoggedUser | string | Variable | Usuario que ejecuta |
| ExceptionParameter | XML | Optional | Datos del último error global (Message, Type, StackTrace, FaultingActivity) |
| OutputParameter | string | Out | Parámetro de salida estándar del proceso |

El skill SIEMPRE genera estos 4 parámetros en create. En reverse, los separa como "Parámetros de Sistema" vs "Parámetros de Negocio" (FR26).

## Tipos Reconocidos (no MVP — parsing básico)

Estos tipos no se generan en el MVP pero el parser los reconoce y documenta parcialmente:

| Tipo | Clase VDW | Parsing |
|---|---|---|
| FTP | FtpActivity | Nombre, tipo, host/path si disponible |
| TCP | TcpActivity | Nombre, tipo, host/port si disponible |
| File | FileActivity | Nombre, tipo, path si disponible |
| HL7 | HL7Activity | Nombre, tipo (Activity Manager existe en converter) |
| JSON Transform | JsonXmlConverterActivity | Nombre, tipo |
| Text/CSV | TextActivity | Nombre, tipo |
| Set Value | SetValueActivity | Nombre, tipo, expression si disponible |

Si el parser encuentra un tipo que NO está en ninguna de las dos tablas → marcar como "⚠️ No parseada (tipo: {className})".

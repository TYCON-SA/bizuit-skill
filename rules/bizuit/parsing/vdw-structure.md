# VDW Structure — Parsing Base

> Estructura del formato VDW (.NET WF3 XAML) para parsing en reverse y query.

## Cuándo aplica

Cargada por `workflows/reverse.md` como primer paso del parsing. Antes de parsear actividades individuales.

## Estructura raíz

El VDW es un archivo XML con raíz `TyconSequentialWorkflow`:

```xml
<ns0:TyconSequentialWorkflow
  x:Class="Tycon.BIZUIT.Workflow.TyconSequentialWorkflow"
  x:Name="NombreDelProceso"
  DisplayName="NombreDelProceso"
  xmlns:ns0="clr-namespace:Tycon.BIZUIT.Workflow;Assembly=..."
  xmlns:ns1="clr-namespace:Tycon.BIZUIT.Activities.Sql;Assembly=..."
  xmlns:ns2="clr-namespace:Tycon.BIZUIT.Activities.SetParameter;Assembly=..."
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  xmlns="http://schemas.microsoft.com/winfx/2006/xaml/workflow">
```

### Estructura del archivo XML

El XML root tiene **2 hijos directos**:

```
<TyconSequentialWorkflow> (root XML)
  ├── <TyconSequentialWorkflow x:Name="NombreProceso"> (hijo [0] — EL WORKFLOW REAL)
  │   ├── TyconSequentialWorkflow.StateManager (property — ignorar)
  │   ├── TyconSequentialWorkflow.ParametersDefinition (EXTRAER parámetros)
  │   ├── SqlActivity x:Name="checkIsAdmin" (ACTIVIDAD)
  │   ├── SetParameterActivity x:Name="..." (ACTIVIDAD)
  │   └── FaultHandlersActivity x:Name="ExceptionContainer" (ACTIVIDAD)
  └── <DesignTimeProperties> (hijo [1] — IGNORAR)
      ├── DefaultParameters, BpmnDiagram, etc.
```

**REGLA CRÍTICA:** Las actividades están en `root[0]` (primer hijo), NO como hijos directos del root XML. El root XML es un wrapper; el primer hijo `TyconSequentialWorkflow` con `x:Name` es el workflow real.

**Importante:** El archivo es esencialmente single-line XML. No usar herramientas de línea (grep, sed) — usar XML parser.

## Cómo identificar actividades

### Por namespace CLR (no por prefix)

Los prefijos `ns0`, `ns1`, `ns2`... son **dinámicos** — cambian entre VDW. Identificar el tipo por el CLR namespace:

| CLR Namespace | Tipo |
|---|---|
| `Tycon.BIZUIT.Activities.Sql` | SqlActivity |
| `Tycon.BIZUIT.Activities.RestFull` | RestFullActivity |
| `Tycon.BIZUIT.Activities.ExternalEventHandlers` | UserInteractionActivity |
| `Tycon.BIZUIT.Activities.SetParameter` | SetParameterActivity |
| `Tycon.BIZUIT.Activities.SetValue` | SetValueActivity |
| `Tycon.BIZUIT.Activities.Expiration` | ExpirableActivity + ExpirationHandlerActivity |
| `Tycon.BIZUIT.Activities.ThrowException` | ExceptionActivity |
| `Tycon.BIZUIT.Activities.Transaction` | TransactionActivity |
| `Tycon.BIZUIT.Activities.StartPoint` | StartPointActivity |
| `Tycon.BIZUIT.Activities.FileAct` | FileActivity |
| `Tycon.BIZUIT.Activities.ZIP` | ZipActivity |
| `Tycon.BIZUIT.Activities` | WhileCustomSequence, ForEachActivity, SplitActivity |
| `http://schemas.microsoft.com/winfx/2006/xaml/workflow` (default) | IfElseActivity, IfElseBranchActivity, SequenceActivity, DelayActivity, FaultHandlersActivity, FaultHandlerActivity, WhileActivity |

### Actividades hijas

Children directos de `root[0]` (el workflow real, no el root XML) son las actividades de nivel 1. Cada actividad que es un container (IfElse, For, Sequence, Expirable, Transaction) tiene hijos que se parsean recursivamente.

**Containers transparentes** — parsear sus hijos directamente como si fueran hijos del parent:
- `WhileCustomSequence` — body de un WhileActivity. No es actividad, es wrapper.

**Ignorar** elementos que NO son actividades:
- `*.ParameterBindings`, `*.ParameterDefinitions`, `*.StateManager`, `*.Permissions`
- `WorkflowParameterBinding`, `ParameterDefinition`, `CriticityLevel`
- `VisibleDescriptionColumn`, `ReactionDescriptionParameter`
- `DesignTimeProperties` y todo su contenido

## Identificación de actividad

### x:Name (ID principal)

Cada actividad tiene `x:Name` — es el **identificador único** dentro del VDW. Usar como ID primario.

```xml
<ns1:SqlActivity x:Name="checkIsAdmin" ...>
```

### DisplayName (raramente presente)

`DisplayName` es **opcional** y frecuentemente ausente en actividades hijas. Solo el root `TyconSequentialWorkflow` suele tener `DisplayName`.

**Regla de fallback para nombre legible:**
1. Si `DisplayName` presente y no vacío → usar `DisplayName`
2. Si no → usar `x:Name`
3. Si tampoco → generar `{TipoActividad}_{posición}` (ej: `SqlActivity_3`)

## Parámetros del proceso

Los parámetros se extraen de `ParametersDefinition` dentro del root:

```xml
<ns0:TyconSequentialWorkflow.ParametersDefinition>
  <ns0:ParametersDefinition>
    <ns0:ParameterDefinition Name="LoggedUser" Direction="Optional" ParamType="SingleValue" DataType="string" IsVariable="True" />
    <ns0:ParameterDefinition Name="pIsAdmin" Direction="Output" ParamType="SingleValue" DataType="string" />
    <ns0:ParameterDefinition Name="ExceptionParameter" Direction="Optional" ParamType="Xml" />
  </ns0:ParametersDefinition>
</ns0:TyconSequentialWorkflow.ParametersDefinition>
```

### Separación sistema vs negocio (FR26)

| Parámetro | Tipo | Siempre presente |
|-----------|------|:---:|
| `InstanceId` | Sistema | ✅ |
| `LoggedUser` | Sistema | ✅ |
| `ExceptionParameter` | Sistema | ✅ |
| `OutputParameter` | Sistema | ✅ |
| Todo lo demás | Negocio | — |

Los parámetros de negocio frecuentemente tienen prefijo `p` (pIsAdmin, pMonto) pero no siempre.

### Atributos de ParameterDefinition

| Atributo | Valores | Notas |
|----------|---------|-------|
| `Direction` | `Optional` (input), `Output` | "Optional" = input/variable |
| `ParamType` | `SingleValue`, `Xml` | Xml = tiene Schema XSD |
| `DataType` | `string`, `double`, `{x:Null}` | Null cuando ParamType=Xml |
| `IsVariable` | `True`/`False` | True = variable interna |
| `ConfigurationValueType` | `None`, `ApplicationSetting` | ApplicationSetting = lee de config |

## Gotchas

- Los prefijos `ns0`, `ns1`, etc. son arbitrarios — **nunca hardcodear prefijos**
- El archivo puede tener 1 sola línea de >1MB para el XAML
- `DesignTimeProperties` tiene su propia estructura — no confundir con actividades
- `FaultHandlersActivity` (WF3 default ns) es el container de exception — está al final del root
- `{x:Null}` es el valor null de WF3 — no es string vacío
- Booleans son `"True"`/`"False"` con mayúscula — case-sensitive

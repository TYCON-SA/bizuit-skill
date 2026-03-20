# Condition Extraction — Condiciones de Gateway

> Cómo extraer y traducir condiciones de branches de IfElseActivity a lenguaje natural para la spec.

## Cuándo aplica

Al parsear un `IfElseActivity` — cada `IfElseBranchActivity` hijo puede tener una condición. El último branch sin condición es el default/else.

## Dos formatos de condición

Los VDW usan **dos formatos distintos** de condición (descubierto en análisis Story 2.1):

### Formato 1: Pipe-delimited (más común en procesos de negocio)

Encontrado en: CobranzaEntidad (13 condiciones).

```
campo|Source|XPath|operador|valor|Tipo||conjunción|Acción|-
```

| Segmento | Posición | Valores | Ejemplo |
|----------|:---:|---------|---------|
| Campo | 1 | Nombre de parámetro o actividad | `pIdReca`, `checkExist` |
| Source | 2 | `Parameter`, `Activity` | `Parameter` |
| XPath | 3 | Path al valor (vacío si SingleValue) | `NewDataSet/Table/cantidad` |
| Operador | 4 | `==`, `>`, `<`, `<>`, `HasValue`, `IsEmpty` | `==` |
| Valor | 5 | Literal o vacío (para HasValue/IsEmpty) | `5`, `OK`, `approved` |
| Tipo | 6 | `Undefined` (siempre) | `Undefined` |
| (vacío) | 7 | — | — |
| Conjunción | 8 | `AND`, `OR`, vacío (última condición) | `AND` |
| Acción | 9 | `Eliminar` (siempre) | `Eliminar` |
| Terminador | 10 | `-` (siempre) | `-` |

### Condiciones compuestas (AND/OR)

Múltiples condiciones se concatenan con `-` como separador entre bloques:

```
condición1|...|AND|Eliminar|-condición2|...|Eliminar|-
```

**Ejemplo real** (CobranzaEntidad):
```
EstadoCobro|Parameter||==|OK|Undefined||AND|Eliminar|-getTotalDC|Activity|NewDataSet/Table/totalDC|>|0|Undefined|||Eliminar|-
```

Traduce a: `EstadoCobro == "OK" AND getTotalDC.totalDC > 0`

### Formato 2: CodeDom/RuleExpressionCondition (menos común)

Encontrado en: Rdaff_CobroMasivo (2 condiciones).

Usa la infraestructura WF3 `RuleConditionReference` + XML `System.CodeDom`:

```xml
<RuleExpressionCondition Name="ApiOk">
  <CodeBinaryOperatorExpression Operator="ValueEquality">
    <Left>
      <CodeMethodInvokeExpression Method="EvaluateRule">
        <Parameters>
          <CodePrimitiveExpression Value="200" Type="String"/>
        </Parameters>
      </CodeMethodInvokeExpression>
    </Left>
    <Right>
      <CodePrimitiveExpression Value="200" Type="String"/>
    </Right>
  </CodeBinaryOperatorExpression>
</RuleExpressionCondition>
```

**Traducción simplificada:** Extraer `Operator` + `Left value` + `Right value`.
- `ValueEquality` → `==`
- `GreaterThan` → `>`
- `LessThan` → `<`

Para la spec: `"Resultado API == 200"` (no parsear la estructura CodeDom completa).

## Traducción a lenguaje natural

### Reglas de traducción

| Pipe-delimited | Spec output |
|---|---|
| `pMonto\|Parameter\|\|>\|10000\|...` | `pMonto > 10000` |
| `checkExist\|Activity\|NewDataSet/Table/cantidad\|==\|0\|...` | `checkExist.cantidad == 0` |
| `vEstadoMP\|Parameter\|\|==\|approved\|...` | `vEstadoMP == "approved"` |
| `campo\|...\|HasValue\|\|...` | `campo tiene valor` |
| `campo\|...\|IsEmpty\|\|...` | `campo está vacío` |
| Compuesta con AND | `condición1 AND condición2` |
| Compuesta con OR | `condición1 OR condición2` |

### Para Source=Activity con XPath

Cuando `Source=Activity`, el campo es el `x:Name` de una actividad y el XPath apunta al resultado:

```
getDatosMP|Activity|NewDataSet/Table/campo|==|valor|...
```

Traduce a: `getDatosMP.campo == "valor"` (usar el último segmento del XPath como nombre del campo).

### Para CodeDom

Traducir simplificado: `{método} == {valor}` o `{método} > {valor}`.

Si el CodeDom es demasiado complejo para simplificar → documentar como: `"Condición programática (ver CodeDom en VDW)"`.

## Tabla de operadores

| Operador (pipe) | Operador (CodeDom) | Lenguaje natural |
|---|---|---|
| `==` | `ValueEquality` | `==` o `es igual a` |
| `>` | `GreaterThan` | `>` o `mayor que` |
| `<` | `LessThan` | `<` o `menor que` |
| `<>` | `IdentityInequality` | `!=` o `distinto de` |
| `>=` | `GreaterThanOrEqual` | `>=` |
| `<=` | `LessThanOrEqual` | `<=` |
| `HasValue` | (no aplica) | `tiene valor` |
| `IsEmpty` | (no aplica) | `está vacío` |
| `contains` | (no aplica) | `contiene` |
| `startswith` | (no aplica) | `empieza con` |

## Gotchas

- El branch **sin condición** en un IfElse es el **default/else** — documentar como "Camino default"
- Si hay 1 solo branch (sin else) → documentar + anomalía ⚠️ "Gateway sin camino alternativo"
- Las condiciones pipe-delimited usan `|` como separador — escapar en cualquier output markdown
- `Undefined` en el campo Tipo siempre aparece — ignorar
- `Eliminar` en el campo Acción siempre aparece — ignorar
- El terminador `-` al final siempre aparece — ignorar
- Condiciones compuestas: el `AND`/`OR` está en el campo 8 de la **primera** condición del par
- CodeDom es raro pero existe — no fallar si se encuentra, simplificar o marcar como "condición programática"

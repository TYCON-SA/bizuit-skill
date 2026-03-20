# XSLT Mappings — Generation Rules

> Los 8 campos XSLT obligatorios por actividad y cómo generarlos.
> **FR65**: Xslt y RuntimeInputXslt DEBEN ser idénticos. Inconsistencia = error silencioso en producción.

## Cuándo aplica

Cargada por `workflows/create.md` Phase 2 junto con `service-tasks.md`. Para cada actividad con input/output mappings, generar los 8 campos XSLT.

## Los 8 campos XSLT

| # | Campo | Qué contiene | Relación |
|---|---|---|---|
| 1 | `Xslt` | XSLT de input mapping (design-time) | = RuntimeInputXslt |
| 2 | `RuntimeInputXslt` | XSLT de input mapping (runtime) | = Xslt |
| 3 | `OutParametersXslt` | XSLT de output mapping (design-time) | = RuntimeOutputXslt |
| 4 | `RuntimeOutputXslt` | XSLT de output mapping (runtime) | = OutParametersXslt |
| 5 | `XsltText` | Versión texto del Xslt (display) | Derivado de Xslt |
| 6 | `RuntimeInputXsltText` | Versión texto del RuntimeInputXslt | Derivado de RuntimeInputXslt |
| 7 | `RuntimeOutputXsltText` | Versión texto del RuntimeOutputXslt | Derivado de RuntimeOutputXslt |
| 8 | `selectedInputSources` | JSON: de dónde vienen los datos | Independiente |

## Regla critica de consistencia

```
⚠️ CRITICO: Xslt y RuntimeInputXslt DEBEN ser IDENTICOS para la misma actividad.
   OutParametersXslt y RuntimeOutputXslt DEBEN ser IDENTICOS.
   Cualquier diferencia causa errores silenciosos en tiempo de ejecución.
   El motor BIZUIT usa Runtime* en ejecución — si difiere del design-time,
   el comportamiento real no coincide con lo que se ve en el editor.
```

**Regla de generación:** Generar Xslt primero, copiar exacto a RuntimeInputXslt. Idem OutParameters.

## Template de input XSLT

Para una actividad con N parámetros de entrada:

```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <Root>
      <{ElementoRaiz}>
        <{param1}><xsl:value-of select="/Root/{param1}"/></{param1}>
        <{param2}><xsl:value-of select="/Root/{param2}"/></{param2}>
      </{ElementoRaiz}>
    </Root>
  </xsl:template>
</xsl:stylesheet>
```

### Elemento raíz por tipo

| Tipo | Elemento raíz | Ejemplo |
|---|---|---|
| SQL | `CommandCall` con `ConnectionString` hijo | `<CommandCall><ConnectionString/><pProveedor>...</pProveedor></CommandCall>` |
| REST | `RestActivity` | `<RestActivity><pProveedor>...</pProveedor></RestActivity>` |
| Email | `MethodCall` | `<MethodCall><emailTo>...</emailTo></MethodCall>` |
| SetParameter | No tiene input XSLT | `{x:Null}` |

### Ejemplo completo — SQL con 1 parámetro input

**Spec dice:** SQL_VerificarProveedor, input: pProveedor

**Generar Xslt (y RuntimeInputXslt — idéntico):**
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <Root>
      <CommandCall>
        <ConnectionString/>
        <pProveedor><xsl:value-of select="/Root/pProveedor"/></pProveedor>
      </CommandCall>
    </Root>
  </xsl:template>
</xsl:stylesheet>
```

**Generar selectedInputSources:**
```json
[{"name":"pProveedor","type":"Parameter"}]
```

## Template de output XSLT

Para una actividad con M parámetros de salida:

```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <Root>
      <{output1}><xsl:value-of select="/Root/{sourceElement}"/></{output1}>
    </Root>
  </xsl:template>
</xsl:stylesheet>
```

### Ejemplo — SQL Scalar output

**Spec dice:** output: proveedorHabilitado (Scalar)

**Generar OutParametersXslt (y RuntimeOutputXslt — idéntico):**
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <Root>
      <proveedorHabilitado><xsl:value-of select="/Root/ScalarResult"/></proveedorHabilitado>
    </Root>
  </xsl:template>
</xsl:stylesheet>
```

**Generar selectedOutputTargets:**
```json
[{"name":"proveedorHabilitado","type":"Parameter"}]
```

## Defaults vacíos por tipo

Si la actividad no tiene mappings, usar el default vacío (ver `activity-defaults.md`):

| Tipo | Default Input XSLT |
|---|---|
| SQL | `<Root><CommandCall><ConnectionString/></CommandCall></Root>` |
| Email | `<Root><MethodCall/></Root>` |
| REST | `<Root><RestActivity/></Root>` |

Wrapped en XSLT stylesheet:
```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    {default element}
  </xsl:template>
</xsl:stylesheet>
```

## HTML encoding

Los campos XSLT en atributos XML DEBEN estar HTML-encoded:
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `&` → `&amp;`

**En BPMN generado**, los campos XSLT van como atributos del elemento bizuit:extension, HTML-encoded.

## Campos *Text

Los campos `XsltText`, `RuntimeInputXsltText`, `RuntimeOutputXsltText` son versiones plain-text (sin encoding) para display en el editor. En generación, son iguales al XSLT original sin encoding.

## Gotchas

- **SIEMPRE** copiar Xslt → RuntimeInputXslt y OutParametersXslt → RuntimeOutputXslt
- Si no hay mappings, NO dejar vacío — usar el default vacío del tipo
- `selectedInputSources` tipo puede ser: "Parameter", "Variable", "Activity"
- Los XSLT defaults vacíos son OBLIGATORIOS — sin ellos, el motor BIZUIT falla
- HTML encoding es de un solo nivel en generación (BIZUIT re-encodes al guardar)

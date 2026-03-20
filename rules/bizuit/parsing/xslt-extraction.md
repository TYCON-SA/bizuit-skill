# XSLT Extraction — Decode y Extracción de Atributos

> Cómo decodificar y extraer atributos de texto que contienen XML/XSLT/SQL embebido en el VDW.

## Cuándo aplica

Cada vez que se lee un atributo de una actividad VDW que contiene XML, XSLT, SQL, o cualquier texto que pueda estar HTML-encoded.

## Algoritmo de decode (N pasadas)

El encoding **varía entre VDW** — no es uniforme. El mismo atributo (`Xslt`) puede estar:
- Plain XML en un VDW (CobranzaEntidad)
- Single HTML-encoded en otro (PruebaIsAdmin)
- Double-encoded en otro contexto (CustomFunctions)

### Algoritmo principal

```
función decode(valor):
  anterior = ""
  actual = valor
  mientras anterior != actual:
    anterior = actual
    actual = html_decode(actual)  // &lt; → <, &gt; → >, &amp; → &, &quot; → ", &#xD; → \r, &#xA; → \n
  retornar actual
```

**NO implementar "2 pasadas fijas"** — el loop de estabilización cubre cualquier profundidad de encoding.

### HTML entities a decodificar

| Entity | Decodifica a |
|--------|-------------|
| `&lt;` | `<` |
| `&gt;` | `>` |
| `&amp;` | `&` |
| `&quot;` | `"` |
| `&#xD;` | `\r` (carriage return) |
| `&#xA;` | `\n` (line feed) |
| `&#xD;&#xA;` | `\r\n` (CRLF) |

## CDATA

Si el valor decodificado contiene `<![CDATA[...]]>`, extraer el contenido interior:

```
función extraer_cdata(valor):
  si valor contiene "<![CDATA[":
    retornar contenido entre "<![CDATA[" y "]]>"
  si no:
    retornar valor
```

Encontrado en: `RuntimeInputXslt` de Rdaff_CobroMasivo (envuelve VBScript).

## Dual XSLT — Preferir Runtime sobre Design-time

Cada actividad puede tener hasta **4 atributos XSLT**:

| Atributo | Tipo | Contiene |
|----------|------|----------|
| `Xslt` | Design-time input | Puede tener `[FUNCTION[nombre]]` placeholders |
| `RuntimeInputXslt` | **Runtime input** | Código real (VBScript embebido) |
| `OutParametersXslt` | Design-time output | Puede tener `[FUNCTION[nombre]]` placeholders |
| `RuntimeOutputXslt` | **Runtime output** | Código real |

### Regla de preferencia

1. Si `RuntimeInputXslt` tiene valor (no null/vacío) → usar en lugar de `Xslt`
2. Si `RuntimeOutputXslt` tiene valor → usar en lugar de `OutParametersXslt`
3. Si el atributo design-time contiene `[FUNCTION[` → **ignorar** y usar Runtime

### Qué extraer de cada XSLT

Para la spec, documentar:
- **Input mappings**: qué parámetros/variables se pasan a la actividad (del `xsl:value-of select`)
- **Output mappings**: qué resultados se extraen (del OutParametersXslt `xsl:value-of`)
- **Custom Functions**: nombres de funciones VBScript embebidas (informativo, no parsear el código)

## Enmascaramiento de credenciales (NFR11)

### Atributos a verificar

| Atributo | Cuándo enmascarar |
|----------|-------------------|
| `Password`, `emailPassword` | Si tiene valor no vacío y no es `{x:Null}` |
| `ConnectionString` | Si contiene `password=`, `pwd=`, `Password=` en texto plano |
| `AuthorizationPass`, `BearerToken` | Si tiene valor no vacío y no es `{x:Null}` |

### Regla

```
si atributo es sensible Y valor no es vacío/null/encriptado:
  reemplazar valor con "***ENMASCARADO***"
  agregar anomalía 🔴 "Password en texto plano en actividad '{nombre}'"
```

### Valores encriptados (NO enmascarar)

ConnectionStrings cortos como `rK1RLKKBRvk=` (Base64, <20 chars) son **encriptados** por BIZUIT — no son plain text. No enmascarar ni reportar anomalía.

**Heurística:** Si ConnectionString tiene < 50 chars y termina en `=` → probablemente encriptado. Si tiene > 50 chars y contiene `Server=` o `Data Source=` → probablemente plain text → enmascarar.

## Atributos especiales

### Instructions (UserInteractionActivity)

El atributo `Instructions` contiene **Base64-encoded RTF**, no HTML-encode:
```
Instructions="e1xydGYxXGFuc2lcYW5zaWNwZzEyNTJ..."
```

Para la spec: decodificar Base64, extraer texto plano del RTF (ignorar formato), o documentar como "instrucciones RTF presentes".

### ActivitySources

XML que describe dependencias de datos entre actividades:
```xml
<Sources>
  <Source Id="LoggedUser" Type="Variable"/>
  <Source Id="checkIsAdmin" Type="Activity"/>
</Sources>
```

Para la spec: documentar como "Datos de entrada: {lista de fuentes}".

### LinksDefinitions

XML con links entre actividades y parámetros. Decode con el mismo algoritmo iterativo.

## Gotchas

- **Encoding varía entre VDW** — nunca asumir un nivel fijo
- `{x:Null}` no es string — es el null de WF3. Tratar como ausente.
- `""` (vacío) y `{x:Null}` son diferentes: vacío = configurado sin valor, null = no configurado
- CDATA puede estar dentro de un valor ya decodificado — aplicar extracción de CDATA después del decode
- Los `&#xD;&#xA;` en SQL son newlines reales (no encoding de XML) — preservar como `\r\n` en la spec
- VBScript en XSLT (`msxsl:script`) — no parsear el código, solo listar nombres de funciones

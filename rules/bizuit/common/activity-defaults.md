# Activity Defaults — BIZUIT

> Valores por defecto vacíos por tipo de actividad.
> Usados cuando un atributo no tiene valor explícito.

## XSLT Defaults Vacíos

Cada tipo de actividad tiene un XSLT "vacío" diferente que el motor BIZUIT espera:

| Tipo | Default Input XSLT |
|---|---|
| SQL | `<Root><CommandCall><ConnectionString/></CommandCall></Root>` |
| Email | `<Root><MethodCall/></Root>` |
| REST | `<Root><RestActivity/></Root>` |
| HL7 | `<Root><InputHL7Message/></Root>` |
| JSON | `<Root><JsonXmlConverterActivity><Json/></JsonXmlConverterActivity></Root>` |

Si la actividad no tiene mappings, usar estos defaults wrapped en XSLT stylesheet:

```xml
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    {default element above}
  </xsl:template>
</xsl:stylesheet>
```

## Timeout Defaults

| Tipo | Default | Anomalía threshold |
|---|---|---|
| SQL | 30 segundos | 0 = Warning (sin límite) |
| REST | 30 segundos | 0 = Warning |
| Email | 30 segundos | 0 = Warning |

## Asunciones de Draft-First por Tipo (v2.1)

Cuando draft-first genera un borrador proactivo, usa estas asunciones default. El usuario corrige en refinamiento.

| Tipo | Asunción default |
|------|-----------------|
| SQL | ConfigFile (nombre inferido del dominio), query parametrizada, timeout 30s, ReturnType DataSet |
| REST | URL placeholder (configurable por ambiente), GET, timeout 15s |
| Email | SMTP via ConfigFile, sin adjuntos, destinatario dinámico |
| UserTask | Asignación por rol (no persona), timeout 48hs hábiles, escalamiento a superior |
| Gateway (Exclusive) | 2 caminos (Sí/No), condición sobre último parámetro de negocio |
| Gateway (Parallel) | Fork + Join, sin condiciones |
| Timer | 24hs, calendario hábil |
| For | Itera sobre resultado de SQL/REST anterior, best-effort (no transaccional) |
| Sequence (Try/Catch) | Try con actividades de integración, catch genérico (notificar + log) |
| SetParameter | Asignación simple de valor calculado |
| Expirable | SLA 48hs hábiles, acción al vencer: notificar + escalar a superior |
| Send Message | Asíncrono, timeout 24hs, datos mínimos del proceso padre |
| Receive Message | Espera asíncrona, timeout 24hs |
| Call Activity | Proceso existente, sin parámetros compartidos por defecto |
| Exception | Tipo genérico, lanzada por catch de Sequence |

## Limitaciones del Motor (consultadas por draft-first FR99)

Cuando el draft detecta que la descripción implica funcionalidad no soportada:

| Limitación | Advertencia | Alternativa |
|-----------|-------------|-------------|
| Loops/ciclos en flujo principal | "BIZUIT no soporta loops" | While Activity (For con condición) o re-trigger via scheduler |
| Triggers por evento externo | "Solo scheduler, manual, o integración" | SendMessage desde proceso externo |
| Multi-pool (collaboration) | "Single-pool. Lanes SÍ soportadas (opt-in via create workflow). Multi-pool = procesos separados" | Dividir en 2 procesos con Send/Receive. Para lanes por rol: activar en create workflow |
| Sub-procesos cross-organization | "No soportado directamente" | CallActivity dentro de misma org |
| Backward flow (volver a paso anterior) | "Flujo solo avanza" | Terminar instancia + crear nueva |

## Guía: Parámetros vs Variables

Cuándo crear un parámetro (`p` prefix, visible externamente) vs una variable (PascalCase, solo lógica interna), y cuándo marcar Filterable.

### Tabla de decisión

| Criterio | Parámetro (`p` prefix) | Variable (PascalCase) |
|----------|----------------------|---------------------|
| Visible para el usuario | Sí | No |
| Aparece en formularios | Sí | No |
| Se usa para filtrar instancias | Sí (Filterable) | No |
| Se pasa entre procesos (Send/Receive) | Sí | No |
| Solo para lógica interna | No | Sí |
| Dato temporal (no persiste) | No | Sí |

**Regla de oro:** Si alguien fuera del proceso necesita ver o usar este dato → Parámetro. Si solo lo usa el proceso internamente → Variable.

### 5 reglas de inferencia de Rol en reverse (en orden — la primera que matchea gana)

1. **Sistema conocido** (InstanceId, LoggedUser, ExceptionParameter, OutputParameter) → **Variable**
2. **Direction=Variable** en el VDW → **Variable**
3. **Prefix `p`** en el nombre → **Parámetro**
4. **Presente en FormSchemaJson** de algún UserTask → **Parámetro** *(solo aplica en reverse, no en create)*
5. **Default** → **Parámetro** (conservador, el usuario puede corregir)

**Conflicto de precedencia:** Si `pTemp` tiene Direction=Variable, regla 2 gana sobre regla 3 porque se evalúa antes. Direction del VDW es más confiable que naming convention.

**En CREATE:** se aplican reglas 1-3 y 5. Regla 4 no aplica (no existe FormSchemaJson hasta que se genera). Asunciones se documentan inline: `pMonto (decimal, Parámetro, Filterable 💡asumí que se busca por monto)`.

### Cuándo marcar Filterable

| Marcar Filterable | NO marcar Filterable |
|-------------------|---------------------|
| Identificadores (nro solicitud, DNI, código) | Montos y valores numéricos |
| Estados y categorías (tipo, prioridad, estado) | Descripciones y textos largos |
| Fechas clave (fecha solicitud, vencimiento) | XML complejos y arrays |
| — | Parámetros de sistema (nunca) |

### Ejemplo: Pedido de Soporte

| Nombre | Tipo dato | Dir | Rol | Filterable | Regla |
|--------|-----------|-----|-----|------------|-------|
| pDescripcion | string | In | Parámetro | No | regla 3 (prefix p), no Filterable (descripción) |
| pUrgencia | string | In | Parámetro | Sí | regla 3 + Filterable: categoría |
| pCategoria | string | In | Parámetro | Sí | regla 3 + Filterable: categoría |
| pTecnicoAsignado | string | In | Parámetro | Sí | regla 3 + Filterable: identificador |
| pEstado | string | InOut | Parámetro | Sí | regla 3 + Filterable: estado |
| pSolucion | string | In | Parámetro | No | regla 3, no Filterable (descripción) |
| InstanceId | string | Variable | Variable | No | regla 1 (sistema conocido) |
| LoggedUser | string | Variable | Variable | No | regla 1 (sistema conocido) |
| NotificationBody | string | Variable | Variable | No | regla 2 (Direction=Variable) |

## Otros Defaults

| Atributo | Default | Nota |
|---|---|---|
| PerformTracking | "PerformTracking" | String literal, no boolean |
| EnableRoleValidation | "False" | Con mayúscula |
| RowsAffected | "0" | Inicializado en 0 |
| CleanEmptyNodesAtOutput | "False" | Con mayúscula |
| MergePreviousOutput | "False" | Con mayúscula |
| CallMultipleTimes | "False" | Con mayúscula |
| CanUseAsSource | "True" | SQL/REST = True, otros = False |

## Gotchas

- "True"/"False" SIEMPRE con mayúscula — BIZUIT es case-sensitive
- Los defaults vacíos de XSLT son OBLIGATORIOS — si se omiten, el motor falla
- CommandTimeout = 0 significa "sin timeout" (no "instantáneo")

# Process Spec Template — bizuit-sdd

> Este archivo define el formato de todas las specs de proceso generadas por el skill.
> El skill lo consulta al generar (create/reverse) y parsear (edit/validate) specs.
> Los humanos pueden leerlo como referencia de formato.
> **specFormatVersion 2.1** — 9 secciones PRD + Parámetros en spec.md, detalle técnico en archivo separado (QS-03).

---

## Schema del Frontmatter YAML

```yaml
# REQUIRED — desde la primera escritura
processName: string           # Nombre del proceso en BIZUIT
organizationId: string        # Valor de BIZUIT_ORG_ID env var
status: "partial" | "complete"
source: "create" | "reverse" | "edit"
specFormatVersion: "2.1"
createdAt: "ISO 8601"         # Ej: "2026-03-17T14:00:00Z"

# SET AFTER PERSIST — null hasta que el proceso se persiste en BIZUIT
logicalProcessId: string | null   # GUID asignado por BIZUIT. NO modificar manualmente.
currentVersion: string | null     # Ej: "23.0.0.0". Se actualiza al persistir nueva versión.

# FOR PARTIAL CREATE — solo cuando status = "partial"
draftedSections: []               # v2.1: Secciones generadas por draft pero NO confirmadas
                                  # Mutuamente excluyente con completedSections por sección
completedSections: []             # Ej: [1] | [1,2,3] | [1,2,3,4,6,7,8]
                                  # Secciones auto-generadas (5, 9, Detalle) NO aparecen
                                  # Array final de create completo: [1, 2, 3, 4, 6, 7, 8]
                                  # FR101: status "complete" requiere al menos 7 secciones
lastActivity: string | null       # Formato por paso:
                                  # Sec 3: "Actividad 8 de 12: Generar Orden"
                                  # Sec 4: "Atributos técnicos de ConsultarSAP (REST)"
                                  # Paso 8: "Form de AprobarSolicitud"
                                  # Sec 6-8: "Sección 7"

# FOR REVERSE/EDIT — mapeo IDs originales del VDW a nombres legibles
# SIEMPRE en spec.md, no en detalle-tecnico.md.
originalIds: null | {}

# AUDIT
entryChannel: string              # Valores: "web" | "mobile" | "scheduler" | "integración" | "otro"
                                  # En reverse: "desconocido — configurado en Dashboard"
                                  # En create: elicitado en Paso 9d
createdBy: string
lastModifiedBy: string
lastModifiedAt: "ISO 8601"
```

### Reglas del frontmatter

- Campos desconocidos se ignoran sin error (FR55)
- `logicalProcessId` y `originalIds` NO deben modificarse manualmente
- Si `specFormatVersion` es "2.0" → detalle inline (retrocompatible)
- `specFormatVersion: "2.1"` requiere `detalle-tecnico.md` en el mismo directorio

---

## Distribución de archivos (v2.1)

```
processes/{org}/{slug}/
├── spec.md                  # 9 secciones PRD + Parámetros + Stats
├── detalle-tecnico.md       # ToC por tipo + bloques #### detalle-{xname}
├── resumen-ejecutivo.md     # 6 preguntas derivadas de spec.md
└── test-paths.md            # Legacy — no se genera
```

**spec.md** = legible por humanos | **detalle-tecnico.md** = referencia de agente

---

## Estructura de spec.md

### `## 1. Objetivo del proceso`
1-2 oraciones inferidas del nombre + actividades principales.

### `## 2. Actores`
Tabla inferida de UserTask + Permissions + Email. Sin UserTask: "Proceso automatizado."

### `## Mapa del proceso` (opcional)
Sección opcional. Se genera si >15 actividades o >3 bloques funcionales. Heading sin número, entre Actores y Escenarios. Formato lista indentada. Validate ignora headings sin número.
```
## Mapa del proceso
- **{NombreSeccion}** ({N} actividades): {resumen 1 línea}
- **{NombreSeccion}** ({N} actividades): {resumen 1 línea}
```
Regla de agrupación: gateways exclusivos alto nivel (prof 0-1) marcan límites. Sin gateways → bloques de 5-8 act por propósito. En CREATE: usuario define al confirmar mapa nivel 1. En REVERSE: inferido de gateways.

### `## 3. Escenarios`
1 por outcome terminal. Máx ~10. Camino exitoso = Escenario 1. ACs descriptivos. Links cross-file.

### `## 4. Funcionalidades`
Agrupadas por categoría. NO 1:1 con actividades. Links cross-file.

### `## 5. Integraciones`
Tablas por tipo: SQL (conexiones + catálogo tablas/SPs), REST, Email, SendMessage.

### `## 6. Edge Cases y Manejo de Errores`
Errores capturados + handler global + anomalías.

### `## 7. NFRs`
Inferidos de Expirable, REST timeouts, FaultHandlers.

### `## 8. Decisiones y Restricciones`
Libre. En reverse: placeholder.

### `## 9. Auditoría de Configuración`
7 tipos de detección. Auto-generada.

### `## Forms BizuitForms` (opcional — generado por reverse)

Seccion opcional. Se genera SOLO cuando el reverse o query extrae forms del VDW/BPMN. No todo proceso tiene forms BizuitForms configurados.

```markdown
## Forms BizuitForms

### UserTask: {nombre}

| Control | Tipo | Binding | Required | DataType | Notas |
|---------|------|---------|----------|----------|-------|
| {name} | {component} | {binding path} | Si/No | {dataType} | {discrepancias/notas} |

**DataSources secundarios:** (si aplica)
| DataSource | Tipo | Connection/URL | executeOnStart |
|-----------|------|----------------|----------------|
| {name} | SQL/REST | {connection o URL} | Si/No |

**Actividades Anteriores:** (si aplica)
| Actividad | Paths disponibles |
|-----------|------------------|
| {activityName} | {path1, path2, ...} |
```

**Reglas:**
- 1 sub-seccion `### UserTask: {nombre}` por cada actividad con form (StartEvent incluido)
- Si actividad sin form → "(sin form configurado)" debajo del heading
- Si JSON corrupto → "(form con JSON invalido — no se pudo extraer)"
- Discrepancias (param sin binding, control sin param) se marcan como WARNING en columna Notas
- DataSources secundarios y Actividades Anteriores solo si existen
- El formato matchea exactamente lo que reverse genera via `form-extraction.md`

### `## Parámetros del proceso`
Tablas negocio + sistema (FR26, FR103). Heading sin número — NO se mueve al detalle.
Tabla extendida: `| Nombre | Tipo dato | Dirección | Rol | Filterable |`
Ejemplo: `| pUrgencia | string | In | Parámetro | Sí |` y `| InstanceId | string | Variable | Variable | No |`

### `## Stats`
Conteos.

---

## Estructura de detalle-tecnico.md

```markdown
# Detalle técnico — {ProcessName}

## Índice por tipo
- SQL (N): nombre1, nombre2
- REST (N): nombre1, ...
- Email (N): nombre1, ...
- UserTask (N): nombre1, ...
- SendMessage (N): nombre1, ...
- SetParameter (N): nombre1, ...
- SetValue (N): nombre1, ...
- Gateway (N): nombre1, ...
- Timer (N): nombre1, ...
- ForEach (N): nombre1, ...
- While (N): nombre1, ...
- Sequence (N): nombre1, ...
- Expirable (N): nombre1, ...
- Exception (N): nombre1, ...
- ErrorHandler (N): nombre1

#### detalle-{xname}
**{xname}** ({tipo})
- **ID original**: {xname}
- {atributos según activity-parsing.md}
```

Sin frontmatter. Sin status. Archivo satélite de spec.md.

---

## Secciones auto-generadas vs elicitadas

| Sección | En create | En reverse |
|---------|-----------|------------|
| 1. Objetivo | Elicitada | Auto-generada |
| 2. Actores | Elicitada | Auto-generada |
| 3. Escenarios | Elicitada + auto ACs | Auto-generada |
| 4. Funcionalidades | Elicitada | Auto-generada |
| 5. Integraciones | Auto-generada | Auto-generada |
| 6. Edge Cases | Parcial | Auto-generada |
| 7. NFRs | Elicitada | Auto-generada |
| 8. Decisiones | Elicitada | Pendiente |
| 9. Auditoría | Auto-generada | Auto-generada |
| Parámetros | Auto-generada | Auto-generada |
| Detalle técnico | Auto-generado | Auto-generado |

---

## Sección Extensiones (FR58 — Story 5.4)

Sección **opcional** al final de spec.md. Contenido manual del usuario que el skill **NUNCA modifica ni sobreescribe**.

```markdown
## Extensiones

{Contenido manual del usuario — test paths adicionales, notas, documentación extra}
{El skill NO toca esta sección durante re-generación ni edit}
```

- Solo existe si el usuario la crea manualmente
- Se preserva intacta durante cualquier operación del skill (edit, re-generate, validate)
- No se incluye en el diff como "cambio"
- Si un cambio lógico afecta contenido manual aquí → advertir al usuario

<!-- ⚠️ NO renombrar headings de las 9 secciones, Parámetros, ni Stats. (QS-03: Journeys→Escenarios ya aplicado)
     detalle-tecnico.md es inseparable de spec.md — no mover uno sin el otro.
     ## Extensiones es la ÚNICA sección que el skill no toca. -->

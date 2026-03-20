# Spec Format — PRD de Proceso (specFormatVersion 2.1)

> Rule genérica SDD — contrato de formato para interpretar y generar specs.
> El template está en `templates/process-spec.md`. Esta rule define las INSTRUCCIONES de cómo usar el formato.
> **QS-02**: Formato cambia de 5 capas narrativas a 9 secciones PRD + detalle técnico.
> **QS-03**: Detalle técnico se separa a `detalle-tecnico.md`. Catálogo SQL en Integraciones. specFormatVersion 2.1.

## Cuándo aplica

Cargada por todos los workflows cuando generan o parsean specs.

## Estructura de archivos (specFormatVersion 2.1)

A partir de v2.1, la spec se distribuye en 2 archivos:

```
spec.md               → 9 secciones PRD + Parámetros + Stats (legible por humanos)
detalle-tecnico.md     → ToC por tipo + bloques #### detalle-{xname} (referencia de agente)
```

**Principio: spec.md = legible por humanos, detalle-tecnico.md = referencia de agente.**

- `detalle-tecnico.md` está SIEMPRE en el mismo directorio que `spec.md` (convención fija, no configurable)
- `detalle-tecnico.md` NO tiene frontmatter — toda la metadata está en spec.md
- Links en spec.md apuntan al detalle con formato cross-file: `[texto](detalle-tecnico.md#detalle-xname)`
- Links en resumen-ejecutivo.md también son cross-file si referencian el detalle

### Retrocompatibilidad

- `specFormatVersion: "2.0"` → detalle inline en spec.md (skill busca `## Detalle técnico` en spec.md)
- `specFormatVersion: "2.1"` → detalle en archivo separado (skill busca `detalle-tecnico.md`)
- El skill siempre GENERA v2.1. Cuando LEE, detecta la versión y busca en el lugar correcto.
- Si v2.1 y no existe `detalle-tecnico.md` → error DETAIL_MISSING
- `entryChannel`: canal de entrada del proceso. En reverse: `"desconocido — configurado en Dashboard"`. En create: elicitado (web, mobile, scheduler, integración, otro). Ver FR56.

## Estructura de spec.md (9 secciones + Parámetros + Lanes + Stats)

```
## 1. Objetivo del proceso
## 2. Actores
## Mapa del proceso          ← OPCIONAL: solo si >15 act o >3 bloques funcionales
## Lanes                     ← OPCIONAL: solo si frontmatter lanes: true (Epic 15)
## 3. Escenarios
## 4. Funcionalidades
## 5. Integraciones
## 6. Edge Cases y Manejo de Errores
## 7. NFRs
## 8. Decisiones y Restricciones
## 9. Auditoría de Configuración
## Parámetros del proceso
## Stats
```

### Sección Lanes (solo si `lanes: true` en frontmatter)

Tabla de mapping Performer → Activities, ordenada por primera aparición del performer en el flujo secuencial. El performer del primer UserTask del flujo va primero.

```markdown
## Lanes

| Performer | Activities |
|-----------|------------|
| {Primer performer} | T1: {nombre}, T3: {nombre}, T5: {nombre} |
| {Segundo performer} | T2: {nombre}, T4: {nombre} |
| (Sistema) | ST1: {nombre} |
```

**Reglas:**
- 1 fila por performer distinto (case-insensitive, primera ocurrencia es canonical)
- Activities referenciadas por ID + nombre corto
- Si performer tiene caracteres especiales → mostrar sin encoding XML (el spec.md es Markdown, no XML)
- Si `lanes: false` o campo `lanes` no existe en frontmatter → NO generar esta sección
- Si `lanes: true` pero 0 performers mapeados → tabla vacía + warning: "No se encontraron performers con actividades asignadas. Verifique la sección de Actores."

**Tabla RACI (solo si RACI fue definido en Phase 2):**

```markdown
### RACI

| Lane | Responsible | Accountable | Consulted | Informed |
|------|------------|-------------|-----------|----------|
| {Performer} | {nombre} | {nombre} | — | {nombre} |
```

Solo se genera si el usuario definió roles RACI durante Phase 2 (refinement). Si no se definió RACI, esta subtabla NO se genera.

## Estructura de detalle-tecnico.md

```markdown
# Detalle técnico — {ProcessName}

## Índice por tipo
- SQL (N): nombre1, nombre2, ...
- REST (N): nombre1, ...
- Email (N): nombre1, ...
- UserTask (N): nombre1, ...
- SendMessage (N): nombre1, ...
- SetParameter (N): nombre1, ...
- Gateway (N): nombre1, ...
- ...

#### detalle-{xname1}
...
#### detalle-{xname2}
...
```

---

## Sección 1: Objetivo del proceso

1-2 oraciones inferidas del nombre del proceso + actividades principales.

```markdown
## 1. Objetivo del proceso
Procesa solicitudes de equivalencia de materias entre instituciones educativas,
gestionando documentación, análisis académico y notificaciones.
```

## Sección 2: Actores

Tabla inferida de UserTask (quién hace qué), Permissions (roles), Email (a quién notifica).

```markdown
## 2. Actores

| Actor | Rol | Participa en |
|-------|-----|-------------|
| Operador de documentación | Controla documentación | ControlarDocumentacion |
| Alumno/solicitante | Presenta doc, recibe emails | ActualizarDocDigital, emails |
```

Si no hay UserTask: "Proceso automatizado sin actores humanos identificados."
Si nombre no es descriptivo: usar x:Name tal cual. Nunca inventar.

## Mapa del proceso (sección opcional, FR89)

Sección **sin número** entre `## 2. Actores` y `## 3. Escenarios`. completeness-checklist y validate deben **ignorar** headings sin número entre secciones numeradas.

**Threshold**: >15 actividades → mapa obligatorio. ≤15 actividades → mapa solo si >3 bloques funcionales.

**Regla de agrupación (determinística para NFR38)**: Gateways exclusivos de alto nivel (profundidad 0-1 desde root) marcan límites entre secciones. Sin gateways → bloques de 5-8 actividades por propósito funcional. En CREATE: usuario define secciones al confirmar mapa nivel 1. En REVERSE: inferido automáticamente.

**Formato**: lista indentada, no Mermaid.

```markdown
## Mapa del proceso
- **Inicialización** (12 actividades): captura fecha, obtención datos, clasificación
- **Control de documentación** (25 actividades): loop de control con corrección + expiración
- **Procesamiento** (35 actividades): iteración de materias, resolución
- **Notificaciones finales** (55 actividades): emails diferenciados por tipo×resultado
```

**Comunicación**: al generar mapa → "Este proceso tiene {N} actividades agrupadas en {M} bloques. Te muestro primero el mapa general."

**En EDIT**: si spec tiene mapa → regenerar con conteos actualizados. Si edit lleva a >15 y no había mapa → generar. No eliminar mapa existente.

**Validate**: warning si `abs(conteo_detalle - conteo_mapa) / conteo_detalle > 30%` para alguna sección.

**Prefijos en detalle-tecnico.md**: cuando hay mapa, el índice del detalle agrupa por sección funcional con prefijos (A1, A2, B1, B2...). Cada bloque `#### detalle-{xname}` se asocia a su sección. Mejora la navegación sin shardear el archivo.

## Sección 3: Escenarios con ACs

### Reglas de generación de Escenarios

- **1 escenario por outcome terminal** (fin normal, excepción, cancelación, timeout)
- **Agrupar variantes** del mismo outcome (3 errores de API = 1 escenario "Error de API")
- **Máximo ~10 escenarios**
- **Camino exitoso = Escenario 1**: camino que evita ExceptionActivity, cancelaciones, branches de error. Si ambigüedad: branch más largo sin errores.
- **Loops NO generan escenarios nuevos** — el escenario asume que loops se resuelven. Timeout dentro de loop SÍ es escenario diferente.

### Formato de cada Escenario

```markdown
### Escenario 1: Solicitud aprobada [Camino exitoso]

**Actor**: Operador de equivalencias + Alumno
**Trigger**: Ingreso de solicitud de equivalencia

**Narrativa**: El proceso recibe la solicitud, consulta la API, el operador
controla la documentación... (con links cross-file al detalle)

**Steps**:
1. Consulta API equivalencias ([CallEQV_GetEquivRequest](detalle-tecnico.md#detalle-calleqv_getequivrequest))
2. Control de documentación ([ControlarDocumentacion](detalle-tecnico.md#detalle-controlardocumentacion))
...

**Acceptance Criteria**:
- Si el control de documentación se completa sin pedir correcciones, el proceso avanza a análisis PA
- Si el estado es Approved, se envía email de confirmación según tipo de solicitud
```

### Reglas de ACs

- **Descriptivos, no prescriptivos**: "Si EstadoCobro es OK, el proceso notifica por email" (no "DEBE notificar")
- **Oraciones, no Given/When/Then**
- **1 AC por punto de decisión clave + 1 AC por resultado final**
- **Incluir valores reales del VDW**: condiciones, asuntos de email, nombres de subprocesos
- En reverse los ACs son descriptivos (documentan lo que es). En edit se vuelven prescriptivos.

### Narrativa dentro de Escenarios

Cada escenario tiene 1-2 párrafos de narrativa. Reglas:
- Toda actividad del camino mencionada con link cross-file `[descripción](detalle-tecnico.md#detalle-{xname})`
- Inferir semántica del nombre. Nunca inventar.
- Depth ≤2: conversacional. Depth >2: breadcrumbs nombrando el container.

## Sección 4: Funcionalidades

Agrupadas por categoría, NO 1:1 con actividades. Con links cross-file al detalle.

Múltiples SetParameter que arman un JSON = 1 funcionalidad "Armado de payloads".

## Sección 5: Integraciones

Tablas por tipo, orientadas a DevOps.

```markdown
## 5. Integraciones

### Bases de datos (SQL)
#### Conexiones
| Conexión | Actividades | Tipo |
|----------|-------------|------|
| RDAFFConection | checkIsAdmin | ConfigFile |

#### Dependencias de datos (tablas/SPs)
| Tabla/SP | Tipo | Operación | Actividad | Conexión |
|----------|------|-----------|-----------|----------|
| users | Tabla | SELECT | checkIsAdmin | RDAFFConection |
| UserRoles | Tabla | SELECT | checkIsAdmin | RDAFFConection |
| sp_GetMotivo | SP | EXEC | GetMotivo | UES21Connection |

### APIs externas (REST)
| URL base | Método | Actividades | Timeout | Propósito |
|----------|--------|-------------|---------|-----------|

### Email
| Template | Asunto | Cuándo |
|----------|--------|--------|

### Subprocesos (SendMessage)
| Subproceso | Propósito | Modo | Invocaciones |
|------------|-----------|------|-------------|
```

### Catálogo SQL — Reglas de extracción

- **Tablas**: extraer de `FROM`, `JOIN`, `INSERT INTO`, `UPDATE`, `DELETE FROM` en CommandText
- **SPs**: si `CommandType="StoredProcedure"`, listar CommandText como nombre del SP. Si `CommandType="Text"` pero contiene `EXEC`, extraer nombre del SP con regex `EXEC\s+(\w+\.?\w+)`
- **Strip schemas**: `dbo.Tabla` → `Tabla`, `schema.sp_name` → `sp_name`
- **Operación**: `SELECT`, `INSERT`, `UPDATE`, `DELETE`, `EXEC`
- **Sin SQL**: la sección `### Bases de datos (SQL)` no aparece

Lista 100% de SQL, REST, Email, SendMessage.

## Sección 6: Edge Cases y Manejo de Errores

```markdown
## 6. Edge Cases y Manejo de Errores

### Errores capturados por el proceso
| Situación | Cómo se detecta | Qué hace el proceso |
|---|---|---|
| API devuelve != 200 | Gateway CheckIf200 | Registra trace + lanza excepción |

### Error handler global
- ExceptionContainer captura excepciones no manejadas

### Anomalías detectadas
{Output de anomalies.md — valores hardcodeados, etc.}
```

## Sección 7: NFRs

Inferidos de Expirable (SLAs), REST (timeouts, reintentos), FaultHandlers.

Si no hay Expirable ni REST: "Sin NFRs inferibles del VDW."

## Sección 8: Decisiones y Restricciones

> 📝 Pendiente: completar con contexto del equipo. El VDW no contiene decisiones de diseño.

## Sección 9: Auditoría de Configuración

7 tipos de detección en tablas:

| # | Tipo | Qué detecta |
|---|------|-------------|
| 1 | URLs hardcodeadas | REST con URL de servidor/ambiente específico |
| 2 | ConfigSettings requeridos | Parámetros con ApplicationSetting |
| 3 | Paths de filesystem | DefaultValue con paths de servidor |
| 4 | Connection strings inconsistentes | Nombres diferentes para misma conexión |
| 5 | Credentials presentes | Password con valor (aunque encriptado) |
| 6 | Subprocesos requeridos | EventName de SendMessage |
| 7 | DefaultValue con datos de ambiente | URLs o datos específicos en defaults |

**NUNCA mostrar valores de credentials. Solo "presente — verificar en ambiente".**

## Parámetros del proceso (heading sin número)

Tablas de parámetros de negocio y sistema, separados (FR26). Tabla extendida con Rol y Filterable (FR103).

```markdown
## Parámetros del proceso

### Parámetros de negocio (N)
| Nombre | Tipo dato | Dirección | Rol | Filterable |
|--------|-----------|-----------|-----|------------|
| pIsAdmin | string | Output | Parámetro | No |

### Parámetros de sistema (N)
| Nombre | Tipo dato | Dirección | Rol | Filterable |
|--------|-----------|-----------|-----|------------|
| InstanceId | string | Variable | Variable | No |
```

**Columnas Rol y Filterable (FR103):**
- **Rol**: `Parámetro` (visible, `p` prefix) o `Variable` (PascalCase, interno). Ver `rules/bizuit/common/activity-defaults.md` para tabla de decisión y 5 reglas de inferencia
- **Filterable**: `Sí` (identificadores, estados, fechas clave) o `No`. Params de sistema nunca Filterable
- **Backward compat**: spec sin columna Rol → asumir Parámetro. Sin Filterable → asumir No. No migrar

Los parámetros son info de alto nivel que PM/QA necesitan ver. Se quedan en spec.md, NO se mueven al detalle.

## Diferencia con el template

- `templates/process-spec.md` = artefacto que el skill usa para GENERAR specs (estructura + schema)
- `rules/sdd/spec-format.md` (este archivo) = instrucciones de CÓMO leer e interpretar el formato

## Gotchas

- Los headings `## 1.` a `## 9.` + `## Parámetros del proceso` + `## Stats` son FIJOS en spec.md — no renombrar (QS-03: "Journeys" renombrado a "Escenarios" en v2.1)
- La sección `## 8. Decisiones` es libre — el skill no la modifica
- `specFormatVersion: "2.1"` indica formato PRD con detalle separado
- `specFormatVersion: "2.0"` indica formato PRD con detalle inline
- `specFormatVersion: "1.0"` es el formato anterior (5 capas + narrativa) — si se encuentra, advertir y ofrecer regenerar
- `detalle-tecnico.md` NO tiene frontmatter — es un archivo satélite de spec.md
- `originalIds` SIEMPRE en frontmatter de spec.md, no en detalle-tecnico.md

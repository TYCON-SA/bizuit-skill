# Reverse — Documentar Proceso Existente

> Workflow para generar spec + resumen ejecutivo + test paths a partir de un VDW existente en BIZUIT.

## Cuándo se activa

Cuando el router de `SKILL.md` detecta intent REVERSE (keywords: `documentar`, `reverse`, `analizar`, `qué hace`).

## Prerequisitos

- `BIZUIT_API_URL` configurada (Dashboard API — para download VDW)
- `BIZUIT_BPMN_API_URL` configurada (BPMN API — para search)
- `BIZUIT_USERNAME` y `BIZUIT_PASSWORD` configurados
- `BIZUIT_ORG_ID` configurado (para directorio de output)

Si falta alguna → informar cuál y abortar (no se puede hacer reverse sin API).

## Rules a cargar

En orden de uso:
1. `rules/bizuit/common/api-auth.md` — autenticación
2. `rules/bizuit/parsing/vdw-structure.md` — estructura raíz y navegación
3. `rules/bizuit/parsing/activity-parsing.md` — parsing por tipo de actividad
4. `rules/bizuit/parsing/xslt-extraction.md` — decode de atributos
5. `rules/bizuit/parsing/condition-extraction.md` — condiciones de gateways
6. `rules/bizuit/common/anomalies.md` — detección de anomalías
7. `rules/bizuit/common/activity-types.md` — referencia de tipos
8. `rules/sdd/spec-format.md` — formato de spec
9. `rules/sdd/test-path-generation.md` — generación de test paths
10. `rules/bizuit/parsing/form-extraction.md` — extracción de forms BizuitForms del VDW

---

## Los 8 Pasos

### Paso 1 — Detectar nombre del proceso

Extraer el nombre del proceso del mensaje del usuario.

- Si el mensaje contiene un nombre claro (ej: "documentar proceso PruebaIsAdmin") → usar directamente
- Si no está claro → preguntar: `"¿Cuál es el nombre exacto del proceso en BIZUIT?"`
- Slugificar el nombre para el directorio: lowercase, `-` como separador, sin caracteres especiales
  - "PruebaIsAdmin" → `pruebaisadmin`
  - "Rdaff_CobroMasivo" → `rdaff-cobro-masivo`

### Paso 2 — Autenticar

Invocar `rules/bizuit/common/api-auth.md`:

1. Si ya hay token en sesión → reutilizar
2. Si no → `GET $BIZUIT_API_URL/login` con `Authorization: Basic {base64(BIZUIT_USERNAME:BIZUIT_PASSWORD)}`
3. Extraer `.token` de la respuesta
4. Token se usa con headers diferentes por API (ver api-auth.md)

Mostrar: `"Autenticando en BIZUIT... ✓"`

### Paso 3 — Buscar el proceso

`GET $BIZUIT_BPMN_API_URL/bpmn/search?name={nombre}&scope=all` con header `Authorization: Bearer {token}`

- **0 resultados** → `"No encontré '{nombre}'. ¿Está bien escrito el nombre? Buscá en el editor para confirmar."`
  - NO crear archivos. Terminar.
- **1 resultado** → extraer `logicalProcessId` y `version` de la respuesta. Continuar.
- **Múltiples resultados** → `"Encontré {N} procesos con ese nombre. ¿Cuál querés documentar?"` + lista numerada con nombre y versión. Esperar selección.

Mostrar: `"Buscando '{nombre}'... ✓ Encontrado."`

**Nota:** La `version` del resultado de search se usa en Paso 5 para comparar con spec existente.

### Paso 4 — Descargar VDW

`GET $BIZUIT_API_URL/eventmanager/events/download?eventName={nombre}&version=` con header `Authorization: Basic {token}`

**Importante:** El parámetro `version=` es requerido pero debe estar **vacío** (sin valor). La ruta correcta es `/eventmanager/events/download` (con `/events/`).

- Respuesta = string Base64. Decodificar a XML.
- Si respuesta es `null` o vacía → error VDW_EMPTY: `"Este proceso no tiene VDW publicado. Solo existe como borrador en el editor. Publicalo primero y volvé a intentar."`
- Si el XML decodificado no es parseable → error VDW_PARSE_FAIL: `"El VDW descargado parece estar corrupto. Intentá de nuevo o contactá soporte."`

Mostrar: `"Descargando VDW... ✓ ({tamaño}KB)"`

### Paso 5 — Verificar spec preexistente

Buscar `processes/{BIZUIT_ORG_ID}/{proceso-slug}/spec.md`.

- **No existe** → continuar al Paso 6 (primera vez)
- **Existe** → leer `currentVersion` del frontmatter YAML
  - Comparar con la `version` obtenida del search en Paso 3
  - Preguntar: `"Ya existe spec de '{nombre}' (v{currentVersion}). El VDW actual es v{searchVersion}. ¿Sobreescribir?"`
  - Si usuario dice **no** → abortar sin tocar archivos
  - Si usuario dice **sí** → continuar (sobreescribe)

### Paso 6 — Parsear VDW

Aplicar las rules de parsing sobre el XML decodificado.

**Orden de parsing:**

1. Cargar `vdw-structure.md` — identificar root `TyconSequentialWorkflow`
2. Extraer parámetros del proceso desde `ParameterDefinition` (sección `## Start` de `activity-parsing.md`)
   - Separar sistema vs negocio (FR26)
   - Extraer `IsFilterable` de cada ParameterDefinition (FR103)
   - Inferir Rol usando las 5 reglas de `activity-defaults.md` en orden de precedencia (1→5, primera gana)
   - Generar tabla extendida: `| Nombre | Tipo dato | Dirección | Rol | Filterable |`
3. Contar total de actividades hijas del root (para progreso)
4. **Mapa del proceso (FR89)**: Si total actividades >15 O >3 gateways exclusivos de alto nivel (profundidad 0-1):
   a. Identificar gateways exclusivos de alto nivel como límites de sección
   b. Agrupar actividades en secciones funcionales (máx ~10 secciones)
   c. Asignar prefijos (A, B, C...) a cada sección
   d. Generar `## Mapa del proceso` como lista indentada entre Actores y Escenarios
   e. Comunicar: "Este proceso tiene {N} actividades agrupadas en {M} bloques."
   f. En el índice de detalle-tecnico.md, agrupar por sección con prefijos (A1-, B1-, ...)
   Si ≤15 actividades y ≤3 gateways → NO generar mapa (behavior parity NFR41)
5. Para cada actividad hija del root, recursivamente:
   a. Identificar tipo por CLR namespace (tabla en `vdw-structure.md`)
   b. Buscar sección correspondiente en `activity-parsing.md`
   c. Si tipo encontrado → extraer atributos según la sección
   d. Si tipo NO encontrado → aplicar `## Actividad desconocida`
   e. Si la actividad es un container (IfElse, For, Sequence, Expirable, Transaction) → parsear hijos recursivamente
   f. Aplicar decode con `xslt-extraction.md` para atributos encoded
   g. Aplicar `condition-extraction.md` para condiciones de IfElse
   h. Verificar contra `anomalies.md` — registrar anomalías detectadas
   i. **Extraer forms BizuitForms** — para cada actividad parseada (StartEvent, UserTask):
      1. Buscar `<ConnectorInfo>` en el VDW cuyo `<ActivityName>` coincida con el `x:Name` de la actividad
      2. Si hay multiples `<ConnectorInfo>` para la misma actividad → tomar el primero
      3. **Si se encontro ConnectorInfo con `<Design>`:**
         - Invocar `rules/bizuit/parsing/form-extraction.md` con el JSON del `<Design>` + activityName + parametros del proceso
         - Recibir estructura parseada (controles, DataSources, Actividades Anteriores, discrepancias)
         - Documentar en la seccion del UserTask/StartEvent en la spec:
           - **Tabla de controles:**
             ```
             | Control | Tipo | Binding | Required | DataType | Notas |
             |---------|------|---------|----------|----------|-------|
             | {name} | {component} | {binding path} | Si/No | {dataType} | {discrepancias si las hay} |
             ```
           - **DataSources secundarios** (si existen):
             ```
             **DataSources secundarios:**
             | DataSource | Tipo | Connection/URL | executeOnStart |
             |-----------|------|----------------|----------------|
             ```
           - **Actividades Anteriores** (solo UserTask, si schema poblado):
             ```
             **Actividades Anteriores:**
             | Actividad | Paths disponibles |
             |-----------|------------------|
             ```
         - Discrepancias (param sin binding, control sin param) se marcan como WARNING en columna Notas
      4. **Si NO se encontro ConnectorInfo o no tiene `<Design>`:**
         - Documentar: "(sin form configurado)"
         - Nota informativa (no warning): "UserTask '{name}' sin form BizuitForms"
      5. **Si JSON corrupto en `<Design>`:**
         - form-extraction.md maneja gracefully → documentar "(form con JSON invalido — no se pudo extraer)"
         - WARNING con detalle del error
         - El resto del reverse continua normalmente
5. Al final del root, parsear `FaultHandlersActivity` si presente

**Progreso (NFR4):** Para VDW > 500KB (~20+ actividades), mostrar cada ~10 actividades:
```
Parseando actividades...
  - checkIsAdmin (SQL) ✓
  - setParameterActivity1 (SetParameter) ✓
  Procesando actividad 15 de 83...
  ...
```

**Numeración:** Actividades se numeran secuencialmente desde 1. Dentro de containers (IfElse, For, Sequence), la numeración es jerárquica: `3.1`, `3.2`, `3.1.1`. El contador en branches de IfElse es compartido entre ramas (ver `activity-parsing.md` sección IfElse).

### Paso 7 — Generar outputs

Crear directorio `processes/{BIZUIT_ORG_ID}/{proceso-slug}/` si no existe.

Generar **3 archivos** (specFormatVersion 2.1 — detalle técnico separado, QS-03):

#### 7a. `spec.md` — PRD del proceso (specFormatVersion 2.1)

Usar `templates/process-spec.md` como base. Completar:

**Frontmatter YAML:**
```yaml
processName: "{nombre}"
organizationId: "{BIZUIT_ORG_ID}"
status: "complete"
source: "reverse"
specFormatVersion: "2.1"
createdAt: "{ISO 8601 actual}"
logicalProcessId: "{del search Paso 3}"
currentVersion: "{version del search Paso 3}"
originalIds: { "{x:Name}": "{DisplayName o x:Name}", ... }
entryChannel: "desconocido — configurado en Dashboard"
createdBy: "{BIZUIT_USERNAME}"
lastModifiedBy: "{BIZUIT_USERNAME}"
lastModifiedAt: "{ISO 8601 actual}"
```

**9 Secciones + Parámetros + Stats (SIN bloques `#### detalle-`):**

| Sección | Qué generar | Fuente |
|---------|-------------|--------|
| 1. Objetivo | 1-2 oraciones del nombre + actividades principales | Nombre + parsing |
| 2. Actores | Tabla: actor, rol, participa en. Inferir de UserTask + Permissions + Email. Sin UserTask: "Proceso automatizado" | UserTask, Permissions, Email |
| 3. Escenarios | 1 por outcome terminal, máx ~10. Camino exitoso = Escenario 1. ACs descriptivos. Narrativa con **links cross-file** `[texto](detalle-tecnico.md#detalle-xname)`. | Gateways, puntos terminales |
| 4. Funcionalidades | Agrupadas por categoría. NO 1:1 con actividades. **Links cross-file** al detalle. | Actividades agrupadas |
| 5. Integraciones | Tablas por tipo: SQL (conexiones + **catálogo tablas/SPs**), REST, Email, SendMessage. Lista 100%. | Atributos de actividades |
| 6. Edge Cases | Errores capturados + anomalías de `anomalies.md`. | Gateways de error, excepciones |
| 7. NFRs | Inferir de Expirable, REST, FaultHandlers. Sin datos: "Sin NFRs inferibles" | Expirable, REST |
| 8. Decisiones | `> 📝 Pendiente: completar con contexto del equipo.` | — |
| 9. Auditoría | 7 detecciones. NUNCA mostrar valores de credentials. | RestFullUrl, ParameterDefinition, etc. |
| Parámetros | Tablas negocio + sistema separados (FR26, FR103). Heading sin número. Columnas: Nombre, Tipo dato, Dirección, Rol, Filterable. Inferir Rol con 5 reglas de `activity-defaults.md`. Extraer IsFilterable del VDW. | ParameterDefinition |
| Stats | Conteos de actividades, escenarios, criterios, funcionalidades. | Parsing completo |

**Catálogo SQL (subsección de ### Bases de datos (SQL)):**

```markdown
#### Dependencias de datos (tablas/SPs)
| Tabla/SP | Tipo | Operación | Actividad | Conexión |
|----------|------|-----------|-----------|----------|
```

Reglas de extracción:
- **Tablas**: regex `FROM\s+(\w+)`, `JOIN\s+(\w+)`, `INSERT\s+INTO\s+(\w+)`, `UPDATE\s+(\w+)`, `DELETE\s+FROM\s+(\w+)` sobre CommandText decodificado
- **SPs**: si `CommandType="StoredProcedure"` → CommandText es nombre del SP. Si `CommandType="Text"` y contiene `EXEC` → regex `EXEC\s+(\w+\.?\w+)`
- **Strip schemas**: `dbo.Tabla` → `Tabla`
- **Operación**: SELECT, INSERT, UPDATE, DELETE, EXEC
- Sin SqlActivity → sección `### Bases de datos (SQL)` no aparece

**Links**: TODOS los links a actividades usan formato cross-file `[texto](detalle-tecnico.md#detalle-xname)`.

**Reglas de Journeys (ver `spec-format.md` para detalles completos):**
- 1 journey por outcome terminal (fin normal, excepción, cancelación, timeout)
- Agrupar variantes del mismo outcome
- Happy path = camino sin errores ni cancelaciones
- ACs: oraciones descriptivas con valores reales del VDW
- Narrativa con links cross-file, depth ≤2 conversacional, depth >2 breadcrumbs

#### 7b. `detalle-tecnico.md` — Referencia de agente

Archivo satélite de spec.md. **Sin frontmatter.**

```markdown
# Detalle técnico — {ProcessName}

## Índice por tipo
- SQL ({N}): {nombres separados por coma}
- REST ({N}): {nombres}
- Email ({N}): {nombres}
- UserTask ({N}): {nombres}
- SendMessage ({N}): {nombres}
- SetParameter ({N}): {nombres}
- SetValue ({N}): {nombres}
- Gateway ({N}): {nombres}
- Timer ({N}): {nombres}
- ForEach ({N}): {nombres}
- While ({N}): {nombres}
- Sequence ({N}): {nombres}
- Expirable ({N}): {nombres}
- Exception ({N}): {nombres}
- ErrorHandler ({N}): {nombres}

{Solo listar tipos que existen en el proceso. Omitir tipos con 0 actividades.}

#### detalle-{xname}
**{xname}** ({tipo})
- **ID original**: {xname}
- {TODOS los atributos según activity-parsing.md para este tipo}
```

Fuente de verdad. Si hay discrepancia con journeys o funcionalidades, el detalle prevalece.

#### 7c. `resumen-ejecutivo.md`

Derivado de la spec. Responder **6 preguntas** en máximo media página.
Links al detalle usan formato cross-file `(detalle-tecnico.md#detalle-xname)` si aplica.

```markdown
## {ProcessName}

**¿Qué hace?** {De sección 1: Objetivo}

**¿Quién participa?** {De sección 2: Actores}

**Camino crítico:** {De Journey 1: steps resumidos}

**¿Qué puede salir mal?** {De sección 6: Edge Cases}

**Integra con:** {De sección 5: Integraciones}

**Configuración requerida:** {De sección 9: Auditoría — resumen}

**Stats:** {N} actividades, {J} journeys, {A} ACs, {F} funcionalidades
```

Para procesos de 50+ actividades: máximo 1 página.

> **Nota (QS-02):** `test-paths.md` ya no se genera. Los test paths son ACs dentro de Journeys.

### Paso 8 — Confirmar y Visualizar

Mostrar resumen:

```
Proceso '{nombre}' documentado: {N} actividades, {J} journeys, {A} ACs, {F} funcionalidades
→ processes/{BIZUIT_ORG_ID}/{proceso-slug}/

Archivos generados:
- spec.md — PRD v2.1 con {J} journeys, {A} ACs, {F} funcionalidades
- detalle-tecnico.md — {N} bloques de actividad con ToC por tipo
- resumen-ejecutivo.md — 6 preguntas

{Si hay anomalías: listar las principales}
{Si hay actividades no parseadas: "⚠️ {X} actividades no pudieron ser interpretadas (tipos no reconocidos)"}
```

**INMEDIATAMENTE después del resumen**, generar y mostrar representación visual del flujo del proceso aplicando `rules/sdd/visual-output.md`. Esto es OBLIGATORIO — no esperar a que el usuario lo pida.

---

## Error Handling

| Error | Código | Acción |
|-------|--------|--------|
| Login falla | AUTH_FAILED | "Verificá BIZUIT_USERNAME y BIZUIT_PASSWORD" |
| Token expirado mid-workflow | AUTH_EXPIRED | Re-auth automático (1 vez). Si falla → AUTH_FAILED |
| 403 en cualquier call | API_FORBIDDEN | "Sin permisos. Verificá permisos del usuario en BIZUIT." (NO re-auth) |
| Search devuelve 404 | API_NOT_FOUND | "No encontré '{nombre}'. ¿Está bien escrito?" |
| Download devuelve null | VDW_EMPTY | "Proceso sin VDW publicado. Publicalo primero." |
| XML no parseable | VDW_PARSE_FAIL | "VDW corrupto. Intentá de nuevo." |
| No se puede escribir en processes/ | DIR_FAIL | "Sin permisos para escribir." |
| Spec existente y usuario dice no | — | Abortar sin tocar archivos |
| Spec v2.1 sin detalle-tecnico.md | DETAIL_MISSING | "Spec v2.1 requiere detalle-tecnico.md pero no existe. Regenerar con reverse." |
| API timeout (>15s) | API_TIMEOUT | "La API no responde. Verificá la URL." |

---

## Gotchas

- El parámetro `version=` en download es **requerido pero vacío** — sin él, la API devuelve NullReferenceException
- La ruta de download es `/eventmanager/events/download` (con `/events/`). Sin `/events/` devuelve null silenciosamente.
- `eventName` es **case-sensitive** — usar el nombre exacto del search
- El VDW puede ser un single-line XML de >1MB — usar XML parser, no regex
- Para CobranzaEntidad (~2MB, ~100 actividades) el parsing puede tomar 30+ segundos — mostrar progreso
- Los namespaces (ns0, ns1...) son dinámicos — identificar tipo por CLR namespace, no por prefix
- `DisplayName` es raramente presente en actividades hijas — usar `x:Name` como ID principal

---

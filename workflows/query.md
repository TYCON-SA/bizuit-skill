# Query — Consultar Proceso sin Modificar

> Workflow para responder preguntas sobre procesos BIZUIT sin guardar archivos.
> FR82: query conversacional sin límite de tipos de pregunta.
> FR83: cross-spec search across todos los specs locales.
> FR102: disclaimer de completitud — NUNCA presentar resultados parciales como completos.

## Cuándo se activa

Cuando el router de `SKILL.md` detecta intent QUERY (keywords: `qué hace`, `consultar`, `pregunta`, `buscar`, `¿qué`, `cómo funciona`).

## Rules a cargar

- `rules/bizuit/common/activity-types.md` — referencia de tipos (si parsea VDW)
- `rules/bizuit/parsing/*` — si descarga y parsea VDW on-the-fly
- `rules/bizuit/parsing/form-extraction.md` — si consulta forms (desde BPMN o VDW)
- `rules/bizuit/common/api-auth.md` — si necesita API (query remoto, cross-spec BIZUIT)

## Instrucciones

### Step 1: Determinar fuente y modo

Analizar el mensaje del usuario:

**¿Menciona un proceso específico?**
- SÍ + existe spec local → **Query local** (Step 2A)
- SÍ + no existe spec local + hay `.bizuit-config.yaml` → **Query remoto** (Step 2B)
- SÍ + no existe spec local + no hay config → **Ofrecer configurar** (Step 2D)

**¿Dice "buscar" / "qué procesos" / "dónde se usa"?**
- → **Cross-spec search** (Step 2C)

**Si no queda claro:**
```
"¿Querés consultar un proceso específico o buscar información en todos los procesos?"
```

---

### Step 2A: Query local (spec existente)

1. Leer `processes/{org}/{proceso-slug}/spec.md` + `detalle-tecnico.md` (si v2.1)
2. **Si la spec tiene `## Mapa del proceso` (FR89)**: usar el mapa para orientar la búsqueda. Si la pregunta es sobre una sección específica ("¿qué hace la sección de Resolución?") → buscar en detalle-tecnico.md filtrando por prefijos de esa sección (ej: E1-, E2-). Si la pregunta es general → usar mapa como overview antes de buscar en detalle
3. Responder la pregunta del usuario basándose en la spec
4. **Sin límite de tipos de pregunta** (FR82): el usuario puede preguntar sobre cualquier aspecto — actividades, parámetros, condiciones, forms, integraciones, edge cases, NFRs, etc.
5. **Si el usuario pide "mostrar flujo", "visualizar", "diagrama" o similar**: generar representación visual aplicando `rules/sdd/visual-output.md`. Esto es opt-in — NO generar visual para preguntas textuales

**Si la spec no tiene la info solicitada:**
```
"La spec no documenta {dato solicitado}."
```
Si hay `.bizuit-config.yaml`:
```
"¿Querés que lo busque directamente en BIZUIT? (Requiere descargar el VDW)"
```
Si usuario acepta → **Query remoto** (Step 2B) sobre el mismo proceso.

---

### Step 2B: Query remoto (proceso en BIZUIT)

1. **Auth lazy** — cargar `rules/bizuit/common/api-auth.md`. Si no hay config → wizard inline.
2. **Search** — `GET /api/bpmn/search?name={nombre}&scope=all`
   - Si no encuentra → "No encontré proceso '{nombre}' en BIZUIT. Verificá el nombre."
3. **Download VDW** — `GET /api/eventmanager/events/download?eventName={nombre}`
   - Si VDW vacío → "El proceso existe pero no tiene VDW publicado."
4. **Parse** — usando `rules/bizuit/parsing/*`
5. **Responder** basándose en el VDW parseado
6. **NO guardar archivos** (FR36) — todo en memoria
7. **Si el usuario pide "mostrar flujo" o "diagrama"**: generar visual aplicando `rules/sdd/visual-output.md` (opt-in, no automático en query)

**Si VDW > 500KB** (FR60):
```
"⚠️ Este proceso tiene un VDW grande ({size}KB). La respuesta puede ser incompleta por limitaciones de contexto."
```

---

### Step 2C: Cross-spec search (FR83 + FR102)

#### Fase 1: Scan ligero
1. `glob processes/**/*spec.md` → listar todas las specs
2. Para cada spec: leer frontmatter (`processName`, `organizationId`, `logicalProcessId`) + headings de secciones
3. Identificar los 5-10 specs más prometedores por relevancia al término buscado

#### Fase 2: Deep read
4. Leer las secciones relevantes de los candidatos
5. Extraer matches con contexto (línea + 2 antes/después)
6. Rankear por relevancia. Max 10 resultados.

#### Presentar resultados
```
"Resultados en {N} procesos locales:

1. {processName} ({org}) — Sección {heading}:
   '...{extracto con el match highlighted}...'

2. {processName} ({org}) — Sección {heading}:
   '...{extracto}...'
..."
```

#### Disclaimer de completitud (FR102 — OBLIGATORIO)

**Modo local-only** (sin `.bizuit-config.yaml`):
```
"⚠️ Busqué en {N} procesos locales. Puede haber procesos en BIZUIT no documentados.
   Configurá BIZUIT para búsqueda completa."
```

**Modo local+BIZUIT** (con config + conexión OK):
1. `GET /api/bpmn/process-names` → lista completa de procesos en BIZUIT ({M} total)
2. Comparar con specs locales (por `logicalProcessId`, fallback por `processName`)
```
"Busqué en {N} procesos locales de {M} en BIZUIT.
 {M-N} procesos no tienen spec local: {lista de nombres}.
 Estos pueden contener '{término}' pero no puedo verificar sin spec."
```

**Modo offline** (con config pero sin conexión):
```
"⚠️ Busqué en {N} procesos locales. No pude conectar con BIZUIT para verificar completitud.
   Estos resultados pueden ser parciales."
```

#### Término muy genérico
Si hay matches en >80% de los specs:
```
"Encontré menciones de '{término}' en {X} de {N} procesos. ¿Podés ser más específico?
 Por ejemplo: una tabla, una operación, o un tipo de consulta."
```

#### Zero results
```
"No encontré menciones de '{término}' en ningún proceso local."
```
+ disclaimer según modo.

---

### Step 2D: Ofrecer configurar

```
"No encontré spec local de ese proceso. Para buscarlo en BIZUIT necesito
configurar la conexión. ¿Querés configurar ahora?"
```
Si sí → cargar `api-auth.md` → wizard inline.
Si no → terminar.

---

### Step 2E: Consultar forms de un proceso

Cuando el usuario pregunta sobre forms, controles, bindings o DataSources de un proceso.

1. **Determinar fuente de forms:**
   - Si hay BPMN local (`process.bpmn` en directorio del proceso) con `bizuit:serializedForm`:
     a. Leer el atributo `bizuit:serializedForm` del BPMN (del UserTask/StartEvent solicitado)
     b. Decodificar HTML entities (`&quot;` → `"`, `&lt;` → `<`, `&gt;` → `>`, `&amp;` → `&`)
     c. Parsear JSON (doble parse: primero el form object, luego controls/dataSources internos)
     d. Presentar controles con tipo, binding, required, dataType
     e. Presentar DataSources (Primary, secundarios, Actividades Anteriores)
   - Si hay VDW (descargado o local) con `<Design>` en ConnectorInfo:
     a. Invocar `rules/bizuit/parsing/form-extraction.md` con el JSON del `<Design>` + activityName
     b. Presentar la informacion extraida en formato legible (tabla o lista, NO JSON crudo)
   - Si no hay BPMN ni VDW disponible:
     a. Informar: "No hay BPMN ni VDW disponible para leer forms. Los forms se generan como parte del BPMN."
     b. NO intentar generar forms (query es read-only)
     c. Puede describir que forms SE GENERARIAN basandose en la spec (sin crear JSON)

2. **Formato de presentacion:** tabla o lista legible. Ejemplo:
   ```
   Form de UserTask '{nombre}':
   | Control | Tipo | Binding | Required | DataType |
   |---------|------|---------|----------|----------|
   | ... | ... | ... | ... | ... |

   DataSources: {lista}
   ```

3. **Restricciones:** NO modificar el BPMN ni la spec. NO guardar nada en disco. Operacion read-only.

4. **Query sobre proceso sin UserTasks:** "El proceso no tiene UserTasks, no hay forms que consultar."

---

### Step 3: Conversación continua

- El usuario puede seguir preguntando sobre el mismo proceso
- Si cambia de proceso → volver a Step 1
- Si pide cross-spec → Step 2C
- Si pregunta sobre forms → Step 2E
- Mantener contexto de la spec/VDW cargada en la conversación

---

## Error Handling

| Situación | Comportamiento |
|-----------|---------------|
| Spec con frontmatter inválido | "La spec de '{proceso}' tiene frontmatter inválido. ¿Reparar o buscar en BIZUIT?" |
| API /api/bpmn/process-names falla | Graceful degradation → modo offline |
| VDW descargado no parseable | "No pude parsear el VDW de '{proceso}'. Puede estar en formato no soportado." |
| Spec v2.1 sin detalle-tecnico.md | "Falta detalle-tecnico.md. Datos técnicos no disponibles." Responder con info de spec.md |
| Proceso en BIZUIT pero sin VDW | "El proceso existe en BIZUIT pero no tiene VDW publicado." |

## Gotchas

- Query NUNCA guarda archivos (FR36) — todo en memoria, incluyendo VDW parseado
- Si specFormatVersion >= 2.1: leer spec.md + detalle-tecnico.md (2 archivos)
- Si specFormatVersion < 2.1 o no existe: leer solo spec.md (backward compatible)
- Cross-spec search: fase 1 solo frontmatter+headings para no saturar context
- Comparación local vs BIZUIT: por logicalProcessId primero (más confiable), nombre como fallback

---

## Post-Workflow Visual Output

En query, el visual es **opt-in** — solo se genera si el usuario pide "mostrar flujo", "visualizar", "diagrama" o similar. No se genera para preguntas textuales. Si se genera, aplicar `rules/sdd/visual-output.md`.

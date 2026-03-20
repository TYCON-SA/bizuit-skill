# Phase 4: Generación BPMN + Persist

> Extraído de create.md monolítico (Pasos 11-18 + Error Handling + Gotchas). Refactoring puro.

## Rules que esta fase carga

1. `rules/bizuit/generation/bpmn-structure.md` — template base, namespaces, BPMNDI
2. `rules/bizuit/generation/service-tasks.md` — XML por tipo de actividad
3. `rules/bizuit/generation/xslt-mappings.md` — 8 campos XSLT
4. `rules/bizuit/generation/gateway-conditions.md` — formato pipe-delimited
5. `rules/bizuit/common/activity-defaults.md` — defaults vacíos por tipo
6. `rules/bizuit/common/validation-rules.md` — 53 reglas para self-validation
7. `rules/bizuit/common/api-auth.md` — autenticación lazy + error handling
8. `rules/bizuit/generation/form-generation.md` — generación de forms BizuitForms embebidos en BPMN
9. `rules/bizuit/generation/lanes-structure.md` — **SOLO si `lanes: true` en frontmatter** — addon para collaboration/laneSet/lane + BPMNDI con lanes (Epic 15)

## Precondiciones

- Spec con status: "complete"
- Phase 3 (validation) pasó sin BLOCKERs
- process.bpmn no existe aún, O existe pero logicalProcessId es null (re-generación)

## Instrucciones

### Paso 11 — Verificar spec lista para generar

1. Leer `spec.md` del directorio del proceso
2. Verificar `status: "complete"` en frontmatter
   - Si `status: "partial"` → "La spec no está completa. Completá la elicitación primero."
   - Si no existe → "No hay spec para este proceso."
3. Ejecutar validate rápido (solo BLOCKERs de `completeness-checklist.md`)
   - Si hay BLOCKERs → listarlos. No generar hasta resolver.
4. Confirmar con el usuario: "La spec está lista. ¿Generamos el BPMN?"

---

### Paso 12 — Generar elementos BPMN

Recorrer la spec y generar cada elemento XML.

#### 12a — Extraer metadata del frontmatter

```
processName → ProcessId (PascalCase, sin espacios/acentos)
organizationId → para el directorio de output
parámetros de negocio → <bizuit:parameter> elements
parámetros de sistema → auto-generados (InstanceId, LoggedUser, ExceptionParameter, OutputParameter)
```

**Si la spec define un parámetro con nombre de sistema** (ej: InstanceId) → no duplicar. Usar el de sistema.

#### 12b — Recorrer actividades en orden

Tomar las actividades del happy path (Journey 1) como flujo principal. Las ramas de gateways generan los caminos alternativos.

**Para cada actividad:**
1. Identificar tipo → buscar `## {TypeName}` en `service-tasks.md`
2. Leer atributos técnicos de `detalle-tecnico.md` (bloque `#### detalle-{xname}`)
3. Generar XML según el template del tipo
4. Generar IDs determinísticos: `{Type}_{SlugifiedName}` (ver `bpmn-structure.md`)
5. Generar XSLT mappings si tiene input/output (ver `xslt-mappings.md`)

**Progreso** (para specs con 20+ actividades):
```
"Generando BPMN... [actividad {N} de {total}: {nombre}]"
```

#### 12c — Generar gateways y flows condicionales

Para cada Exclusive Gateway:
1. Generar `<bpmn2:exclusiveGateway>` con `default` attribute
2. Para cada rama con condición → generar `<bpmn2:sequenceFlow>` con `<bpmn2:conditionExpression>` en formato pipe-delimited (ver `gateway-conditions.md`)
3. Rama default → `isDefault="true"`, sin conditionExpression

Para cada Parallel Gateway:
1. Generar fork gateway (múltiples outgoing)
2. Generar join gateway (múltiples incoming)
3. Sin condiciones en los flows

**Flatten de jerarquía:** Si la spec tiene gateways anidados (3.1, 3.2, 3.2.1), aplanar a elementos BPMN lineales con sequence flows conectando correctamente.

#### 12d — Generar sequence flows

Para cada par de actividades consecutivas:
```xml
<bpmn2:sequenceFlow id="Flow_{SourceId}_{TargetId}"
  sourceRef="{SourceId}" targetRef="{TargetId}" />
```

Flow especiales:
- `Flow_Start_{FirstActivityId}` — StartEvent → primera actividad
- `Flow_{LastActivityId}_End` — última actividad → EndEvent
- Flows condicionales de gateways con conditionExpression

#### 12e — Actividad de tipo desconocido

Si una actividad tiene un tipo no cubierto en `service-tasks.md` (ej: FTP):

```xml
<bpmn2:serviceTask id="{Type}_{SlugifiedName}"
  name="{nombre}">
  <!-- Tipo no estándar: {tipo}. Configurar manualmente en el editor BIZUIT. -->
  <bpmn2:incoming>Flow_in</bpmn2:incoming>
  <bpmn2:outgoing>Flow_out</bpmn2:outgoing>
</bpmn2:serviceTask>
```

No fallar — generar genérico y continuar.

---

### Paso 13 — Ensamblar BPMN y generar BPMNDI

**Verificar `lanes` en frontmatter del spec para determinar modo de generación:**

#### Si `lanes: false` o campo no existe (modo estándar):

1. **Ensamblar** usando template de `bpmn-structure.md` COMPLETO (incluyendo `<BPMNDiagram>`):
   - Namespaces + definitions
   - Process con parámetros (sistema + negocio)
   - StartEvent → actividades → EndEvent(s)
   - Sequence flows
   - BPMNDI con auto-layout lineal

2. **Generar BPMNDI** (obligatorio para el editor):
   - Layout lineal horizontal: StartEvent x=100, cada actividad x+=200
   - Gateway branches: y offset +/- 100
   - Shapes con dimensiones por tipo (ver `bpmn-structure.md`)
   - Edges con waypoints source→target

**NO cargar `rules/bizuit/generation/lanes-structure.md` en este modo.**

#### Si `lanes: true` (modo split generation — Epic 15):

**Cargar `rules/bizuit/generation/lanes-structure.md`** (referencia explícita, path completo).

1. **Ensamblar modelo XML** usando `bpmn-structure.md` SIN generar `<BPMNDiagram>`:
   - Agregar `<collaboration>` + `<participant>` ANTES de `<process>` (instrucciones del addon § 2)
   - Agregar `<laneSet>` como PRIMER hijo de `<process>`, ANTES de activities (addon § 3)
   - Generar `<lane>` por cada performer con `<flowNodeRef>` (addon § 3)
   - Actividades, gateways, events y sequence flows se generan normalmente

2. **Generar BPMNDI completo** usando `lanes-structure.md` § 4:
   - El addon genera TODO el `<BPMNDiagram>` (pool, lanes, activities, edges)
   - `bpmn-structure.md` NO genera `<BPMNDiagram>` en modo lanes
   - Layout con valores fijos (ver addon § 4)
   - BPMNPlane.bpmnElement = Collaboration_1 (no Process_1)

**Single-pass: no hay reposicionamiento. El addon genera shapes directamente en las posiciones correctas.**

3. **Validar nombres únicos**: si hay duplicados → ERROR, no generar
   ```
   "Error de generación: existen 2 actividades llamadas '{nombre}'.
    Todos los elementos deben tener nombre único en BIZUIT.
    Renombrá una de las actividades en la spec y regenerá."
   ```

4. **Validar consistencia XSLT**: para cada actividad con mappings, verificar `Xslt == RuntimeInputXslt`. Si hay inconsistencia → auto-corregir igualando Runtime al Xslt.

5. **Generar forms BizuitForms** (FR104-FR108, inline con la generación):
   Para cada StartEvent con inicio humano (FR56) y cada UserTask con campos o acciones:
   - Preparar "form context": campos del spec, acciones, parámetros proceso, canal entrada
   - Invocar `rules/bizuit/generation/form-generation.md` con ese contexto
   - Recibir serializedForm (JSON triple-encoded) y formName
   - Agregar como atributos de la actividad BPMN: `bizuit:serializedForm`, `bizuit:formId="0"`, `bizuit:formName`
   - Si falla la generación de un form → BPMN sin ese form + WARNING (degradación graceful ADR-BF-7)

---

### Paso 14 — Guardar BPMN a disco (FR68)

**ANTES de mostrar al usuario o llamar a la API:**

1. Escribir `process.bpmn` en `processes/{BIZUIT_ORG_ID}/{proceso-slug}/`
2. Verificar que el archivo se escribió correctamente (leer y parsear XML)
3. Mostrar resumen:

```
"BPMN generado para '{processName}':
 - {N} actividades
 - {G} gateways
 - {F} sequence flows
 - {P} parámetros (sistema + negocio)
 - Guardado en processes/{org}/{slug}/process.bpmn

 ¿Querés que lo persista en BIZUIT? (requiere BIZUIT_API_URL configurado)"
```

---

### Paso 15 — Self-validation del BPMN (Story 4.3)

Después de generar y guardar el BPMN, validar automáticamente contra las 53 reglas.

1. **Cargar** `rules/bizuit/common/validation-rules.md`
2. **Ejecutar** las 53 reglas contra el BPMN XML en memoria
3. **Auto-corregir** las 22 reglas auto-corregibles (máximo 3 pasadas)
4. **Clasificar** violaciones restantes: BLOCKER (no persistir) vs WARNING (informar)

**Orden de ejecución:**
1. Estructura (S01-S08) — primero, porque errores aquí invalidan todo
2. Conectividad (C01-C05)
3. IDs (I01-I04)
4. Gateways (G01-G05)
5. Service Tasks (T01-T08)
6. XSLT Consistency (X01-X06) — auto-corregir Xslt↔Runtime
7. Formato (F01-F04) — auto-corregir booleans/enums
8. Parámetros (P01-P05) — auto-agregar sistema faltantes
9. Conditional Flows (CF01-CF03)
10. Inter-proceso (IP01-IP02)
11. No Loops (L01-L03) — al final, es la más cara (DFS)

**Si hay más de 10 violaciones:** mostrar las 10 más críticas y el total: "Se encontraron {N} violaciones. Las más críticas: [lista de 10]. Resolver estas primero y regenerar."

**Si hay BLOCKERs no auto-corregibles:**
```
"❌ Validación fallida — {B} blockers requieren acción:

 ❌ {regla}: {descripción del problema}
    → {sugerencia de corrección}

 El BPMN NO se puede persistir hasta resolver estos {B} blockers.
 El archivo local (process.bpmn) se conserva para revisión."
```

**Si hay auto-correcciones aplicadas:**
```
"⚠️ {N} auto-correcciones aplicadas:
 - {regla}: {qué se corrigió}
"
```

**Si todo OK** → continuar al Paso 16.

---

### Paso 16 — Resumen de generación (Story 4.3)

Presentar resumen conciso (máximo 1 página) como insumo para Gate 2.

```
"✅ BPMN validado — {N}/{total} reglas OK

 Resumen del proceso '{processName}':
 - {A} actividades ({desglose por tipo})
 - {P} parámetros ({S} sistema + {B} negocio)
 - {J} escenarios con {AC} criterios de aceptación
 - {F} conexiones
 - {G} puntos de decisión
 - {FO} forms BizuitForms generados ({desglose: N controles total, M DataSources})

 {Si hay items que requieren verificación manual:}
 📋 Acciones pendientes antes de publicar:

 | # | Acción | Actividad | Responsable |
 |---|--------|-----------|-------------|
 {Para cada item detectado en el BPMN generado, una fila con:
  - SQL: "Verificar que las columnas {cols} existen en {tabla} de {conexión}" | {actividadNombre} | DBA o dev
  - REST: "Reemplazar URL placeholder '{url}' por la URL real del ambiente" | {actividadNombre} | Dev o IT
  - XML: "Validar schema XML del parámetro '{param}'" | {actividadNombre} | Dev
  - Config: "Confirmar que '{connectionString}' apunta al servidor correcto" | {actividadNombre} | IT
  - Form: "Verificar campos del formulario de '{userTask}' bindeados correctamente" | {actividadNombre} | Analista}

 {Si no hay items a revisar: omitir esta sección completa}

 {Si hubo auto-correcciones: listarlas}

 ¿Persistir en BIZUIT?"
```

**Esperar confirmación explícita del usuario (FR54).** NO llamar a la API sin "sí".

Si el usuario dice "no" o "quiero revisar" → queda en estado SpecWithBPMN. El BPMN local existe, no se persistió. El usuario puede pedir regenerar con cambios.

### Paso 17 — Persistir BPMN en BIZUIT (Story 4.4)

Después de que el usuario confirma "sí" en el Paso 16.

#### 17a — Autenticación lazy

1. Si hay token en sesión → reutilizar
2. Si no → cargar `rules/bizuit/common/api-auth.md` y autenticar:
   - `GET {BIZUIT_API_URL}/login` con `Authorization: Basic {base64(USERNAME:PASSWORD)}`
   - Extraer `.token`
   - Si falla → AUTH_FAILED: "Verificá BIZUIT_USERNAME y BIZUIT_PASSWORD"

#### 17b — Verificación de ambiente producción (FR69)

Si `BIZUIT_ENVIRONMENT` == `"production"` → marcar como producción sin preguntar.
Si no está definida y no se preguntó en esta sesión:

```
"⚠️ ¿Estás en ambiente de producción?
 Si es así, el proceso quedará disponible para usuarios reales."
```

- Si dice "sí" → advertencia adicional: "⚠️ PRODUCCIÓN. ¿Confirmar persist del proceso '{nombre}'?"
- Si dice "no" → continuar sin advertencia
- **Una sola vez por sesión** — no repetir en persist subsiguientes

#### 17c — Llamar a la API de persist

```bash
POST {BIZUIT_BPMN_API_URL}/api/bpmn/persist
Authorization: Bearer {token}
Content-Type: application/json

{
  "saveAction": "newVersion",
  "bpmnXml": "{contenido de process.bpmn}",
  "processName": "{processName}",
  "organizationId": "{BIZUIT_ORG_ID}"
}
```

**Nota Sprint 0:** `saveAction` para procesos nuevos es `"newVersion"` (no `"new"` — no existe). Valores válidos: `"newVersion"`, `"update"`, `"updateVersion"`.

**Timeout:** 30 segundos (BPMN puede ser grande). Progreso a los 5s: "Persistiendo en BIZUIT..."

#### 17d — Procesar respuesta

**200 OK:**
1. Extraer `logicalProcessId` y `version` de la respuesta
2. Actualizar frontmatter de `spec.md`:
   ```yaml
   logicalProcessId: "{logicalProcessId}"
   currentVersion: "{version}"
   ```
3. Estado pasa a **Published** (state machine)

**Si la respuesta no incluye logicalProcessId:**
- Advertir: "Persist exitoso pero no recibí el ID. Verificá en el editor BIZUIT."
- `currentVersion` se actualiza, `logicalProcessId` queda null
- Estado: SpecWithBPMN (no Published)

**Error 401:** Re-auth 1 vez. Si falla → AUTH_FAILED.
**Error 403:** "Sin permisos. Verificá el rol del usuario en BIZUIT." (NO re-auth)
**Error 500 / timeout:** "Error al persistir. El BPMN local está intacto. Reintentar cuando la API esté disponible."
**NAME_EXISTS:** "Ya existe '{nombre}' en BIZUIT. ¿Querés: [1] crear nueva versión (edit), [2] elegir otro nombre?"

---

### Paso 18 — Confirmar, Visualizar y cerrar (Story 4.4)

```
"✅ Proceso '{processName}' persistido exitosamente en BIZUIT.
 ID: {logicalProcessId}
 Versión: {currentVersion}

 Archivos locales:
 - processes/{org}/{slug}/spec.md (frontmatter actualizado)
 - processes/{org}/{slug}/detalle-tecnico.md
 - processes/{org}/{slug}/process.bpmn

 Podés abrirlo en el editor BIZUIT para configurar forms y ajustar el layout visual."
```

**INMEDIATAMENTE después del resumen**, generar y mostrar representación visual del flujo del proceso aplicando `rules/sdd/visual-output.md`. Esto es OBLIGATORIO — no esperar a que el usuario lo pida. Si BPMN generation falló (persist no exitoso), generar visual desde spec + warning "BPMN no generado — visual desde spec".

**Estado final:** Published.

---

## Error Handling

| Error | Código | Acción |
|-------|--------|--------|
| `BIZUIT_ORG_ID` no configurado | — | Preguntar al usuario |
| Spec parcial corrupta al retomar | SPEC_CORRUPT | "No puedo leer el estado guardado. ¿Querés intentar reparar o empezar de nuevo?" |
| Directorio sin permisos de escritura | DIR_FAIL | "Sin permisos para escribir en processes/." |
| Nombre de proceso duplicado en filesystem | NAME_EXISTS | "Ya existe un proceso con ese nombre. ¿Querés: [1] sobreescribir, [2] usar otro nombre?" |
| Nombre de actividad duplicado | — | "Ya existe '{nombre}'. ¿Cómo querés llamar a esta?" (no escribe duplicado) |
| Contradicción detectada | — | Preguntar cuál valor es correcto. No actualizar hasta confirmación. |
| Loop detectado | — | Ofrecer alternativas BIZUIT válidas. No descartar caso de negocio. |
| Spec incompleta al generar | — | "La spec no está completa. Completá la elicitación primero." |
| Nombres duplicados al generar | BPMN_INVALID | "2 actividades llamadas '{nombre}'. Renombrá y regenerá." |
| XSLT inconsistente | — | Auto-corregir igualando Runtime al Xslt. Informar. |
| Tipo de actividad desconocido | — | Generar serviceTask genérico con comentario XML. No fallar. |

---

## Gotchas

- Phase 1 (elicitación) puede tomar varias sesiones — siempre guardar progreso
- Phase 2 (generación) es single-shot — se ejecuta completa en una sesión
- IDs en create se generan como `{Type}_{SlugifiedName}`. En edit se preservan de VDW (`originalIds`)
- `entryChannel` en create se elicita (web, mobile, scheduler, integración, otro). En reverse es "desconocido"
- `specFormatVersion` siempre "2.1" — spec.md + detalle-tecnico.md (2 archivos)
- Links cross-file: `[texto](detalle-tecnico.md#detalle-xname)`
- Parámetros quedan en spec.md como `## Parámetros del proceso` (heading sin número)
- BPMN se guarda a disco ANTES de mostrar al usuario o persistir en API (FR68)
- BPMNDI es obligatorio — sin él el editor BIZUIT no muestra el diagrama
- `Xslt == RuntimeInputXslt` siempre — verificar y auto-corregir si hay inconsistencia (FR65)

## Al completar

Estado final: Published (si persist exitoso) o SpecWithBPMN (si persist pendiente/fallido).
Volver a create.md (orchestrator) — el routing detectará el estado Published.

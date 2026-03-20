# Edit — Modificar Proceso Existente

> Workflow para editar un proceso BIZUIT existente: drift check → cambios quirúrgicos → validate → re-gen → diff → persist.
> Integra las reglas de stories 5.1-5.4: drift-detection, surgical-elicitation, id-preservation, change-diff.

## Cuándo se activa

Cuando el router de `SKILL.md` detecta intent EDIT (keywords: `modificar`, `editar`, `cambiar`, `actualizar`, `agregar actividad`).

## Prerequisitos

- Spec existente con `status: "complete"` (o `"partial"` con advertencia)
- `BIZUIT_ORG_ID` configurado
- Para drift check y persist: `BIZUIT_API_URL`, `BIZUIT_BPMN_API_URL`, `BIZUIT_USERNAME`, `BIZUIT_PASSWORD`

## Rules a cargar

1. `rules/sdd/drift-detection.md` — Step 2
2. `rules/sdd/surgical-elicitation.md` — Step 3
3. `rules/sdd/elicitation-by-section.md` — preguntas por tipo (reutilizada de create)
4. `rules/sdd/completeness-checklist.md` — Step 4
5. `rules/sdd/id-preservation.md` — Step 5
6. `rules/bizuit/generation/*` — Step 5 (re-generación)
7. `rules/bizuit/common/validation-rules.md` — Step 5 (self-validation)
8. `rules/sdd/change-diff.md` — Step 6
9. `rules/bizuit/common/api-auth.md` — Step 7 (persist)
10. `rules/bizuit/generation/form-generation.md` — Step 5b (manejo de forms en edit)

---

## Step 1 — Detect & Load

1. **Identificar proceso** del mensaje del usuario
   - Si nombre claro → buscar spec en `processes/{BIZUIT_ORG_ID}/{slug}/spec.md`
   - Si no → preguntar: "¿Qué proceso querés editar?"

2. **Verificar estado** del filesystem:
   - Si no existe spec → "No hay spec para '{nombre}'. ¿Querés crear o documentar?"
   - Si `status: "partial"` → "La spec está incompleta. ¿Completarla primero (create) o editar desde lo que hay?"
   - Si `status: "complete"` → continuar

3. **Verificar specFormatVersion**:
   - Si `"2.1"` → verificar que existe `detalle-tecnico.md`. Si no → error DETAIL_MISSING
   - Si `"2.0"` → detalle inline en spec.md (retrocompatible)
   - Si `"1.0"` → advertir formato anterior, ofrecer regenerar con reverse

4. **Detectar edit interrumpido**:
   - Si existe `spec.prev.md` en el directorio → edit previo no completado
   - Comparar spec.md vs spec.prev.md → si difieren, hay cambios sin persistir
   - Preguntar: "Encontré cambios no persistidos. ¿Continuar desde donde quedaste o empezar de nuevo?"

5. **Presentar resumen**:
   ```
   "Editando: {processName}
    Versión: v{currentVersion}
    Actividades: {N} | Journeys: {J} | Gateways: {G}
    Estado: {Published/SpecWithBPMN}"
   ```

---

## Step 2 — Drift Check

Cargar `rules/sdd/drift-detection.md` y ejecutar:

1. Si `logicalProcessId` == null → "Spec nunca persistida. Continuando sin drift check."
2. Si hay API → `GET /bpmn/search?name={processName}&scope=all` → comparar versiones
3. Si versiones iguales → "(spec sincronizada con BIZUIT v{version})" → continuar
4. Si drift → mostrar opciones: a) sincronizar (reverse), b) editar igualmente, c) cancelar
5. Si API no disponible → advertir, ofrecer continuar sin check

---

## Step 3 — Elicitación Quirúrgica

Cargar `rules/sdd/surgical-elicitation.md` y ejecutar:

1. **Snapshot**: guardar `spec.prev.md` como backup antes de cambios
2. **Preguntar**: "¿Qué querés cambiar?"
3. **Parsear intent**: agregar/eliminar/modificar actividad, cambiar condición, agregar parámetro, modificar form
4. **Ejecutar cambio**: consultar `elicitation-by-section.md` para preguntas por tipo. Solo preguntar lo nuevo.
5. **Preservar IDs**: si actividad tiene originalId → preservar key nativa, actualizar display name
6. **Guardar spec a disco** después de cada cambio (NFR19)
7. **Preguntar**: "¿Hay algo más que querés cambiar?"
8. **Repetir** hasta "no, eso es todo"
9. **Resumen**: "{N} cambios aplicados."

---

## Step 4 — Validate

Cargar `rules/sdd/completeness-checklist.md` y ejecutar contra la spec modificada.

- **Si hay BLOCKERs** → resolver en el momento (como en create Paso 10)
  ```
  "❌ BLOCKER: {descripción} → {pregunta para resolver}"
  ```
  → Resolver → re-check solo ese blocker → continuar

- **Si solo WARNINGs** → informar y continuar sin bloquear
  ```
  "⚠️ {N} warnings: {lista}. Continuando..."
  ```

- **Si todo OK** → continuar a Step 4b

---

## Step 4b — Edit Preview (FR97 — v2.1)

**ANTES de aplicar cambios**, mostrar preview al usuario:

1. **Listar cambios propuestos:**
   ```
   "Cambios propuestos:
    + {actividades agregadas}
    ~ {actividades modificadas}
    - {actividades eliminadas}
    = {actividades sin cambios}"
   ```

2. **Analizar impacto en test paths:**
   - Leer test paths de la spec (sección Journeys ACs)
   - Cruzar actividades mencionadas en los cambios con test paths
   - Reportar:
   ```
   "Actividades afectadas: {lista}
    Test paths impactados: {N} de {total} (paths {IDs})
    Test paths NO afectados: {M} de {total}"
   ```

3. **Pedir confirmación:**
   ```
   "¿Confirmar cambios? [Sí/No/Revisar detalle]"
   ```
   - Sí → continuar a Step 5
   - No → volver a Step 3 (elicitación quirúrgica)
   - Revisar detalle → mostrar cada cambio con más contexto

**Scope mínimo:** solo listar actividades que el usuario mencionó cambiar + test paths donde aparecen. NO inferir impacto indirecto.

---

## Step 4c — Form Binding Safety Check (FR86 — v2.1)

Cargar `rules/sdd/id-preservation.md` sección "Form Binding Safety".

**Para cada UserTask en los cambios propuestos:**
- Si eliminado → warning con ID y nombre
- Si renombrado (ID cambia) → warning con opciones (mantener ID / nuevo ID / cancelar)

**Si no hay UserTasks afectados** → saltar silenciosamente.

**Warnings no bloquean** — el usuario confirma y continúa.

---

## Step 4d — Mapa del proceso en edit (FR89 — v2.1)

**Si la spec tiene `## Mapa del proceso`:**
- Después de aplicar los cambios, regenerar el mapa con conteos actualizados
- Las secciones que no cambiaron mantienen su conteo original
- Si se agregaron actividades a una sección → actualizar conteo
- Si se agregó una sección funcional nueva → agregar al mapa

**Si la spec NO tiene mapa y el edit lleva el total a >15 actividades:**
- Generar `## Mapa del proceso` nuevo
- Comunicar: "El proceso ahora tiene {N} actividades. Se generó un mapa."
- Conteo de actividades se lee de Stats de spec.md post-edit

**Si la spec tiene mapa y el edit reduce a <15 actividades:**
- Mantener el mapa existente (con conteos actualizados)
- NO eliminar la sección del mapa

---

## Step 5 — Re-generación BPMN

Cargar `rules/sdd/id-preservation.md` + `rules/bizuit/generation/*` + `rules/bizuit/common/validation-rules.md`.

1. **Clasificar cambios** (basado en la elicitación de Step 3):
   - Si todos documentales → NO re-generar. Ir directo a Step 6 para confirmar.
   - Si hay cambios lógicos → re-generar.

2. **Resolver IDs** (id-preservation.md):
   - Actividades con originalId → usar ID nativo del VDW
   - Actividades nuevas → ID determinístico `{Type}_{SlugifiedName}`
   - Verificar que todos los originalIds tienen actividad correspondiente
   - Si hay eliminadas → advertir sobre forms huérfanos

3. **Re-generar BPMN** usando las mismas rules que create (Phase 2):
   - Recorrer spec, generar XML por tipo, ensamblar, BPMNDI
   - Progreso para procesos grandes

4. **Self-validation** (53 reglas):
   - Auto-corregir las 22 auto-corregibles
   - Si hay BLOCKERs no corregibles → reportar, no persistir

5. **Guardar process.bpmn a disco** ANTES de mostrar al usuario (FR68)

6. **Resumen de re-generación**:
   ```
   "BPMN re-generado — {N} actividades
    {P} IDs preservados, {D} IDs determinísticos nuevos
    Validación: {reglas OK}/{total} reglas
    {auto-correcciones si hubo}"
   ```

---

## Step 5b — Manejo de Forms en Edit

Cargar `rules/bizuit/generation/form-generation.md`. Ejecutar DESPUES de la re-generacion BPMN (Step 5).

### 5b.1 — Leer forms existentes

Si el BPMN existente (`process.bpmn` pre-edit) tiene `bizuit:serializedForm` en UserTasks/StartEvent:
1. Para cada actividad con serializedForm: decodificar HTML entities → JSON.parse → extraer controles, formId, formName
2. Si el parse falla (form corrupto o de version anterior del skill) → tratar como "form editado manualmente" y marcar para regenerar con backup + WARNING

Si el BPMN existente NO tiene ningun serializedForm (proceso legacy sin forms):
- Marcar como "primera vez" → generar forms para todas las actividades que los necesiten
- Emitir nota FYI: "Este proceso no tenia forms BizuitForms. Se generaron forms para {N} actividades."
- NO emitir WARNING (no es destructivo — agrega, no pierde)

### 5b.2 — Clasificar cada UserTask por tipo de cambio en forms

Para cada UserTask/StartEvent en la spec post-edit, comparar contra el BPMN pre-edit:

| Clasificacion | Condicion | Accion sobre form |
|---|---|---|
| **Sin cambios** | Campos, tipos, required y acciones identicos | Preservar form EXACTAMENTE (byte a byte). NO tocar serializedForm. |
| **Campo agregado** | Nuevo campo en spec que no existia | Merge: invocar form-generation.md modo Merge. Agregar control, preservar existentes intactos. |
| **Campo quitado** | Campo del spec anterior ya no existe | Regenerar form completo (modo Generate) + WARNING + backup. |
| **Campo tipo cambiado** | Campo existe pero cambio tipo (ej: string → boolean) | Regenerar form completo + WARNING "campo '{name}' cambio de tipo" + backup. |
| **Campo required cambiado** | Campo cambia de required:true a false (o viceversa) | Merge: actualizar `RestrictionsPropertiesComponent.required` del control existente SIN regenerar. |
| **Acciones cambiadas** | Botones/acciones del spec difieren | Regenerar form completo + WARNING + backup. |
| **UserTask nuevo** | No existia en BPMN pre-edit | Generar form nuevo (modo Generate). formId=0. formName=form_{activityId}. |
| **UserTask eliminado** | Existia en pre-edit, ya no esta en spec | Remover atributos bizuit:serializedForm, bizuit:formId, bizuit:formName del BPMN. |

### 5b.3 — Backup OBLIGATORIO antes de modificar

**SIEMPRE** crear backup ANTES de modificar un form existente (merge O regenerar):
- Guardar `process.bpmn.bak` con el serializedForm original de todas las actividades afectadas
- NO hay caso donde se modifique un form sin backup previo (Pattern Enforcement #9, NFR19)

### 5b.4 — Preservar formId

- Forms existentes con formId asignado por servidor (ej: formId=10811) → PRESERVAR el formId en toda operacion (merge o regenerar). NUNCA reemplazar con 0.
- Solo forms NUEVOS (UserTask nuevo) tienen formId=0

### 5b.5 — Deteccion de form editado manualmente

Antes de merge o regenerar, comparar campos del spec vs controles del form:
- Si hay controles en el form que NO corresponden a parametros del spec → "form editado manualmente"
- Si el layout/estilos difieren del default generado → "form personalizado en editor"
- Emitir WARNING adicional: "El form de '{UserTask}' fue editado manualmente. La regeneracion perdera los cambios custom. Se creo backup."
- Verificar duplicados antes de merge: si el control ya existe para el parametro → skip + nota "Control para '{param}' ya existe — no se agrego duplicado"

### 5b.6 — Impact analysis de forms

Incluir en el resumen del edit:
```
"Forms afectados: {X} de {Y} ({P} preservados, {M} merge, {R} regenerados, {N} nuevos, {E} eliminados)"
```
Detallar por actividad: nombre + tipo de cambio.

### 5b.7 — Backward compat para forms de versiones anteriores

Si un form fue generado por una version anterior del skill con estructura diferente:
- Si el parse del serializedForm tiene exito → proceder con merge/regenerar normalmente
- Si el parse falla → tratar como "form editado manualmente" → regenerar con backup + WARNING

---

## Step 6 — Diff

Cargar `rules/sdd/change-diff.md` y ejecutar:

1. Comparar `spec.prev.md` vs `spec.md` elemento por elemento
2. Generar diff con formato +/-/~
3. Calcular caminos de test afectados
4. Clasificar: lógico vs documental
5. Preservar sección `## Extensiones` (no incluir en diff)

**Si cambio documental:**
```
"Este cambio no requiere nueva versión en BIZUIT.
 ¿Guardar spec actualizada sin re-generar BPMN?"
```
→ Si confirma: guardar spec, NO llamar API. Limpiar spec.prev.md.

**Si cambio lógico:**
```
"📋 Diff — {processName} v{prev} → v{new}

 {diff formateado}

 Caminos afectados: {N} de {total}

 ¿Persistir nueva versión en BIZUIT?"
```

---

## Step 7 — Confirm & Persist

Solo si el usuario confirma en Step 6.

1. **Autenticación lazy** (api-auth.md)
2. **Production check** (FR69, una vez por sesión)
3. **Persist**:
   ```
   POST /api/bpmn/persist
   { "saveAction": "updateVersion",
     "logicalProcessId": "{del frontmatter}",
     "bpmnXml": "{process.bpmn}",
     "processName": "{processName}",
     "organizationId": "{org}" }
   ```
4. **Actualizar frontmatter**: `currentVersion: "{nueva versión}"`
5. **Limpiar**: eliminar `spec.prev.md` (snapshot ya no necesario)
6. **Confirmar y Visualizar**:
   ```
   "✅ Proceso '{processName}' actualizado — v{nuevaVersion}
    Cambios: {resumen del diff}
    Caminos de test afectados: {N}

    Podés verificar en el editor BIZUIT."
   ```

   **INMEDIATAMENTE después del resumen**, generar y mostrar representación visual del flujo aplicando `rules/sdd/visual-output.md`. Si se generaron PFJSON(before) y PFJSON(after) (paso 1 y post-edit), incluir diff visual coloreado. Esto es OBLIGATORIO.

**Si API falla:**
```
"❌ Error al persistir. Estado actual:
 ✅ spec.md actualizado (en disco)
 ✅ process.bpmn re-generado (en disco)
 ❌ No persistido en BIZUIT

 Reintentar con 'persistir proceso {nombre}'."
```

---

## Error Handling

| Error | Código | Acción |
|-------|--------|--------|
| Spec no existe | — | Ofrecer crear o documentar |
| Spec parcial | — | Ofrecer completar primero |
| DETAIL_MISSING (v2.1 sin detalle-tecnico.md) | DETAIL_MISSING | "Regenerar con reverse" |
| Drift detectado | SPEC_DRIFT | 3 opciones al usuario |
| API no disponible (drift/persist) | API_TIMEOUT | Continuar sin check / reintentar |
| BPMN inválido post-regeneración | BPMN_INVALID | Reportar, no persistir |
| Persist falla | PERSIST_FAIL | BPMN local intacto, reintentar |
| Permisos de escritura | DIR_FAIL | Verificar permisos |
| Edit interrumpido | — | Detectar spec.prev.md, ofrecer retomar |

---

## Gotchas

- Edit tiene MÁS checkpoints de confirmación que create (proceso existente con instancias en vuelo)
- `saveAction: "updateVersion"` para edit (no "newVersion" que crea proceso separado)
- IDs se preservan del mapa `originalIds` — NUNCA regenerar determinísticos para actividades existentes
- Cambios documentales NO generan nueva versión en BIZUIT
- `spec.prev.md` es temporal — se elimina después de persist exitoso
- Sección `## Extensiones` de spec.md NUNCA se modifica
- Si el usuario dice "cancelar" en cualquier paso → informar estado actual y salir
- Si no hay cambios reales → "No se realizaron cambios. Spec y BPMN permanecen en v{X}."

---

## Post-Workflow Visual Output

Al completar edit sin errores, aplicar `rules/sdd/visual-output.md`. En edit se generan 2 ProcessFlowJSONs: PFJSON(before) al leer la spec existente + PFJSON(after) post-edit. Si diff-renderer disponible, mostrar diff visual. Si no, mostrar visual del flujo resultante.

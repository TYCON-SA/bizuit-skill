---
name: bizuit-sdd
description: "Gestiona el ciclo completo de procesos BIZUIT BPM: especificar, generar BPMN XML con forms BizuitForms embebidos, documentar procesos existentes desde VDW, editar, validar y consultar. Usar cuando el usuario trabaja con procesos BIZUIT o necesita crear, reverse-engineer, modificar o consultar procesos BPM."
---

# bizuit-sdd — Spec-Driven Development para BIZUIT BPM

> Skill para gestionar el ciclo completo de procesos BIZUIT BPM: especificar, generar BPMN XML con forms embebidos, documentar desde VDW, editar, validar y consultar.
>
> **Versión:** 1.5.3

---

## Instrucción General

**Todos los outputs al usuario son en español.** Mensajes de error, menú, preguntas de elicitación, resúmenes, advertencias — todo en español. (FR67)

Para error codes, ver `rules/error-catalog.md`. Para naming conventions, ver `rules/naming-conventions.md`.

---

## 1. Detect Intent — Router Principal

Al recibir un mensaje del usuario, seguir este flujo en orden:

### Paso 1: Config Lazy — NO pedir credenciales al inicio (FR49 v2.1)

**CRITICAL: NO verificar env vars ni pedir credenciales al inicio.** El skill funciona sin configuración para CREATE, VALIDATE, y QUERY local. Las credenciales se piden solo cuando se necesitan por primera vez (persist, reverse, search remoto) via wizard inline en `rules/bizuit/common/api-auth.md`.

- **Silencioso al inicio** — no mostrar warnings de env vars faltantes
- **BIZUIT_ORG_ID**: si no está configurado y el flujo lo necesita (para directorio de output) → preguntar: "¿Cuál es el identificador de organización (tenant)?" Buscar también en `.bizuit-config.yaml`.
- **Backward compat**: si hay env vars legacy (`BIZUIT_API_URL`, etc.), usarlas. No advertir por su ausencia.

### Paso 2: Verificar ambiente de producción (FR69, NFR28) — solo cuando se va a persistir

**NO preguntar al inicio.** Solo preguntar la primera vez que el flujo va a persistir en BIZUIT:
- Si `.bizuit-config.yaml` o env vars indican producción → advertir antes de persist
- Si no se sabe → preguntar **una sola vez por sesión**: "¿Este ambiente es producción?"
- **NO preguntar si el flujo no necesita API** (create sin persist, validate, query local)

### Paso 3: Detectar intent por keywords

Analizar el mensaje del usuario buscando keywords que mapean a flujos:

| Keywords | Intent | Workflow |
|----------|--------|----------|
| `crear`, `nuevo`, `nuevo proceso`, `definir proceso` | CREATE | `workflows/create.md` |
| `documentar`, `reverse`, `analizar`, `qué hace`, `¿qué hace` | REVERSE | `workflows/reverse.md` |
| `modificar`, `editar`, `cambiar`, `actualizar`, `agregar actividad` | EDIT | `workflows/edit.md` |
| `validar`, `verificar`, `check`, `revisar spec` | VALIDATE | `workflows/validate.md` |
| `consultar`, `query`, `preguntar sobre`, `explicame`, `explicá` | QUERY | `workflows/query.md` |
| `generá forms`, `generate forms`, `crear formularios` | GENERATE FORMS | `workflows/generate-forms.md` |
| `cambiar a`, `switch to`, `usar prod`, `usar dev`, `usar qa`, `cambiar ambiente` | SWITCH ENV | Inline: cambiar `active` en config (ver `api-auth.md` → Config Multi-Ambiente) |
| `en qué ambiente`, `qué ambiente`, `ambiente actual` | ENV STATUS | Inline: mostrar ambiente activo + URL + lista disponibles |
| `diagnóstico`, `health check`, `verificar instalación`, `status` | HEALTH CHECK | Ejecutar health check (ver Sección 6) |
| `mostrar flujo`, `visualizar`, `diagrama`, `ver proceso` | VISUALIZE | Generar visual del proceso actual aplicando `rules/sdd/visual-output.md` |
| `construir grafo`, `graph build`, `indexar procesos` | GRAPH BUILD | Rebuild completo del Knowledge Graph: `rules/sdd/graph-operations.md` |
| `qué procesos usan`, `dependencias de`, `quién usa`, `blast radius` | GRAPH QUERY | Query sobre Knowledge Graph: `rules/sdd/graph-operations.md` |
| `validar grafo`, `graph validate` | GRAPH VALIDATE | Comparar índice vs specs: `rules/sdd/graph-operations.md` |
| `estado del grafo`, `health`, `graph status` | GRAPH STATUS | Health summary sin rebuild: `rules/sdd/graph-operations.md` |
| `exportar`, `compartir`, `generar HTML` | EXPORT | Exportar última visualización como HTML: `rules/sdd/renderers/html-export.md` |
| `vista ejecutiva`, `resumen para gerencia`, `--view executive` | STAKEHOLDER VIEW | Vista ejecutiva: `rules/sdd/stakeholder-views.md` |
| `vista QA`, `vista para testing`, `--view qa` | STAKEHOLDER VIEW | Vista QA: `rules/sdd/stakeholder-views.md` |
| `form preview`, `preview del formulario`, `mostrar form` | FORM PREVIEW | Preview estructural: `rules/bizuit/forms/form-preview.md` |

- Si se detecta un intent claro → **NO mostrar menú**, ir directo al flujo.
- **BizuitForms:** La generación BPMN (CREATE/EDIT) ahora incluye forms BizuitForms embebidos automáticamente (`bizuit:serializedForm`). No requiere invocación separada. El flujo GENERATE FORMS es para React forms (.tsx) únicamente.
- Si hay conflicto entre keywords → preferir el más específico (ej: "documentar qué hace" → REVERSE porque "documentar" es más específico que "qué hace").

### Paso 4: Detectar estado del filesystem

**Nota:** Este paso requiere conocer el nombre del proceso. Si el mensaje del usuario no lo incluye, preguntar: "¿Con qué proceso querés trabajar?"

Una vez conocido el nombre del proceso:

1. **Slugificar** el nombre: lowercase, reemplazar espacios y caracteres especiales con `-`, eliminar paréntesis y caracteres no alfanuméricos.
   - Ej: "Aprobación de Compras (v2)" → `aprobacion-de-compras-v2`

2. **Buscar spec** en `processes/{BIZUIT_ORG_ID}/{proceso-slug}/spec.md`
   - Si `BIZUIT_ORG_ID` no está configurado → buscar en todas las subcarpetas de `processes/`

3. **Si no se encontró match exacto** → buscar parcial en `processes/{BIZUIT_ORG_ID}/` por nombres que contengan las palabras del usuario.
   - Si encuentra 1 match → "Encontré '{processName}'. ¿Es este?"
   - Si encuentra N matches → listarlos para que el usuario elija.

4. **Determinar estado** del proceso encontrado:

```
¿Existe spec.md?
├── NO → Estado: Empty
│   └── Ofrecer: crear nuevo proceso | documentar proceso existente
│
└── SÍ → Leer frontmatter YAML
    │
    ├── Frontmatter inválido/corrupto → Error SPEC_CORRUPT
    │   └── "No pude leer el estado de la spec (frontmatter inválido).
    │        ¿Querés: [1] reparar el frontmatter, [2] tratar como spec nueva, [3] abortar?"
    │
    ├── status: "partial" → Estado: SpecPartial
    │   └── Ofrecer: retomar creación (mostrar completedSections y lastActivity)
    │
    ├── status: "complete" + NO existe process.bpmn → Estado: SpecComplete
    │   └── Ofrecer: generar BPMN | consultar spec | validar spec
    │
    ├── process.bpmn existe + NO logicalProcessId → Estado: SpecWithBPMN
    │   └── Ofrecer: persistir en BIZUIT | consultar spec | re-generar BPMN
    │
    └── logicalProcessId existe → Estado: Published
        └── Ofrecer: editar | consultar | re-validar | ver versión actual
```

5. **Combinar intent + estado** (tabla de routing — Story 5.6):

| Intent \ Estado | Empty | SpecPartial | SpecComplete | SpecWithBPMN | Published | InvalidState |
|---|---|---|---|---|---|---|
| **CREATE** | → create.md | "Spec parcial existe. ¿Retomar o crear de nuevo?" | "Spec completa existe. ¿Editar, re-crear, o cancelar?" | "BPMN existe. ¿Editar, re-crear, o cancelar?" | "Proceso Published. ¿Editar (recomendado) o crear nuevo con otro nombre?" | → ofrecer reparación |
| **EDIT** | "No hay spec. ¿Crear primero?" | "Spec incompleta. ¿Completar primero?" | → edit.md | → edit.md | → edit.md (con drift check) | → ofrecer reparación |
| **REVERSE** | → reverse.md | → reverse.md (sobreescribe parcial? confirmar) | → reverse.md (sobreescribe? confirmar) | → reverse.md (sobreescribe? confirmar) | → reverse.md (actualizar spec desde BIZUIT) | → reverse.md |
| **QUERY** | "No hay spec ni proceso. ¿Crear o documentar?" | → query sobre spec parcial | → query.md | → query.md | → query.md | → ofrecer reparación |
| **VALIDATE** | "No hay spec." | → validate sobre parcial | → validate inline | → validate inline | → validate inline | → ofrecer reparación |
| **Sin intent** | "¿Crear o documentar?" | "Retomar spec parcial?" | Menú: generar BPMN / editar / consultar | Menú: persistir / regenerar / editar | Menú: editar / consultar / reverse | → ofrecer reparación |

**Regla de conflicto (NFR34):** Si el intent implica sobrescribir (CREATE sobre Published, REVERSE sobre SpecComplete), **siempre confirmar** antes de actuar. Nunca sobreescribir sin confirmación explícita.

**Intent claro + estado inequívoco** → ir directo al workflow sin mostrar menú (AC2).

### Paso 5: Menú de fallback

Si después de los pasos 3 y 4 el intent sigue sin estar claro, mostrar el menú.

**Si NO existen specs locales** (directorio `processes/` vacío o inexistente) → mostrar solo opciones 1 y 2:

```
Hola! Soy el skill bizuit-sdd. ¿Qué querés hacer?

1. Crear un proceso nuevo (desde cero con elicitación guiada)
2. Documentar un proceso existente (reverse de VDW a spec)

Podés responder con el número o describirme qué necesitás.
```

**Si existen specs locales** → mostrar las 5 opciones:

```
Hola! Soy el skill bizuit-sdd. ¿Qué querés hacer?

1. Crear un proceso nuevo (desde cero con elicitación guiada)
2. Documentar un proceso existente (reverse de VDW a spec)
3. Editar un proceso (modificar spec existente + re-generar BPMN)
4. Consultar un proceso (preguntas sobre un proceso sin guardar)
5. Validar una spec (revisar completitud y reglas)

Podés responder con el número o describirme qué necesitás.
```

---

## 2. Examples

### Example: Crear proceso
User: "Quiero crear un proceso de aprobación de compras"
→ Detecta CREATE intent → Elicitación guiada → spec.md creada

### Example: Documentar proceso existente
User: "Documentá el proceso EQV que tenemos en BIZUIT"
→ Detecta REVERSE intent → Descarga VDW → spec.md + resumen-ejecutivo.md

### Example: Consultar proceso
User: "Explicame cómo funciona el proceso de onboarding"
→ Detecta QUERY intent → Lee spec → Respuesta en lenguaje natural

### Example: Proceso con formularios BizuitForms
User: "Creá el proceso de soporte con formularios incluidos"
→ Detecta CREATE intent → Elicitación guiada → BPMN con BizuitForms embebidos

<!-- Mantener examples sincronizados con router table (sección 1) al agregar workflows -->

---

## 3. Validate — Instrucciones Inline

Cuando el intent es VALIDATE (implementado inline):

1. Pedir ruta a spec o nombre de proceso si no se proporcionó.
2. Leer `processes/{BIZUIT_ORG_ID}/{proceso-slug}/spec.md`.
3. Cargar `rules/sdd/completeness-checklist.md`.
4. Verificar cada item del checklist contra la spec:
   - **BLOCKER**: impide generar BPMN → reportar como 🔴.
   - **WARNING**: no impide pero requiere atención → reportar como ⚠️.
5. Mostrar resultado:
   ```
   Validación de '{processName}':

   🔴 BLOCKERs (N):
   - [detalle de cada blocker]

   ⚠️ WARNINGs (N):
   - [detalle de cada warning]

   ✅ Items OK (N de M total)

   {Resumen: "Spec lista para generar BPMN" | "Spec tiene N blockers que resolver"}
   ```

---

## 4. Workflow Loading — Manejo de Stubs

Cuando el router decide cargar un workflow, **verificar si el archivo es un stub** (contiene solo un heading y un comentario TODO):

### Detección de stub

Un workflow es stub si su contenido:
- Tiene menos de 5 líneas, O
- Contiene `<!-- TODO` en las primeras líneas

### Fallback por workflow

Si el workflow es stub, NO cargarlo — mostrar texto de fallback en su lugar:

| Workflow | Mensaje de fallback |
|----------|-------------------|
| `create.md` | "El flujo **crear** no está disponible. Podés: validar spec manualmente, crear spec parcial con tu editor, documentar proceso existente si tenés el VDW." |
| `reverse.md` | "El flujo **reverse** no está disponible. Podés: validar spec existente." |
| `edit.md` | "El flujo **editar** no está disponible." |
| `query.md` | "El flujo **consultar** no está disponible." |
| `generate-forms.md` | "El flujo **generate forms** no está disponible. Podés: crear los forms manualmente usando el SDK @tyconsa/bizuit-form-sdk." |

Después del mensaje de fallback, ofrecer las alternativas disponibles.

---

## 5. Rules Loading

Las rules se cargan bajo demanda según el workflow activo. **NO cargar todas las rules al inicio.**

**Create** usa phase files — cada phase declara sus propias rules (ver `workflows/create/phase-*.md`).
**Reverse**, **edit**, y **query** son monolíticos y declaran rules en su propio header.
**Validate** usa `workflows/validate.md` que carga `create/phase-3-validation.md`.

Rules organizadas en `rules/sdd/` (genéricas) y `rules/bizuit/` (BIZUIT-específicas).
Ver `rules/README.md` para el file tree completo y jerarquía de prioridad.

Para autenticación API (cuando sea necesario): cargar `bizuit/common/api-auth.md` (incluye wizard de config lazy).

**Jerarquía de prioridad** cuando dos rules se contradicen (ver `rules/README.md`):
1. `bizuit/generation/{file}` o `bizuit/parsing/{file}` (más específica)
2. `bizuit/common/{file}`
3. `sdd/{file}` (más genérica)

---

## 6. Process Directory Convention

Todos los procesos se almacenan en:

```
processes/{BIZUIT_ORG_ID}/{proceso-slug}/
├── spec.md              # Spec generada (frontmatter YAML + 9 secciones PRD, specFormatVersion 2.1)
├── detalle-tecnico.md   # Detalle técnico por actividad (separado en v2.1)
├── resumen-ejecutivo.md # Resumen ejecutivo para Process Owner (generado por reverse)
├── process.bpmn         # BPMN XML generado (solo después de create/edit)
└── vdw-original.xml     # VDW descargado (solo si se hizo reverse)
```

- **Template de spec**: `templates/process-spec.md` define el formato.
- **Slugificación**: lowercase, `-` como separador, sin caracteres especiales.
  - "Aprobación de Compras" → `aprobacion-de-compras`
  - "EQV_ProcesarRequest" → `eqv-procesar-request`
  - "Proceso (v2)" → `proceso-v2`

---

## 7. Verificación de Instalación / Health Check

Al recibir el **primer mensaje** de una sesión:

1. Verificar que `VERSION` existe en el directorio del skill. Si no → advertir: "⚠️ VERSION no encontrado — el skill puede estar incompleto."
2. Leer la versión de `VERSION` y la línea `**Versión:**` de este archivo. Si difieren → advertir: "⚠️ Versión inconsistente: SKILL.md dice {X}, VERSION dice {Y}. Puede que la actualización esté incompleta. Probá: `cd ~/.claude/skills/bizuit-sdd && git pull`"
3. Si existe `.bizuit-config.yaml` con `environments:` → leer ambiente activo y mostrar en menú: "bizuit-sdd v{version} — Ambiente: {active} ({url})". Si `active: prod` → prefijo `🔴 [PROD]` en outputs. Si `active: qa` → `🟡 [QA]`. Si `dev` → sin prefijo.
4. **OBLIGATORIO — Version check remoto**: SIEMPRE ejecutar con la herramienta Bash el siguiente comando:
   ```bash
   curl -sL --connect-timeout 3 "https://raw.githubusercontent.com/TYCON-SA/bizuit-skill/main/VERSION" 2>/dev/null
   ```
   Comparar el resultado con la versión local de `VERSION`. Si la versión remota es **mayor** que la local → mostrar al usuario: "⬆️ **Nueva versión disponible:** v{local} → v{remota}. Actualizá con: `~/.claude/skills/bizuit-sdd/scripts/update-skill.sh`". Si el curl falla (sin internet, timeout) → silencioso, no bloquear. **Este paso NO es opcional — ejecutarlo siempre.**
5. Si todo OK y versión al día → silencioso, proceder al router (sección 1).
6. Si hay problemas → reportar y continuar (warning, no blocker).

### Intent: Health Check (diagnóstico)

Keywords: "diagnóstico", "health check", "verificar instalación", "status del skill"

Cuando el usuario dice alguna de estas keywords, ejecutar health check usando herramientas de Claude Code:

1. Leer `MANIFEST.md` — obtener lista de archivos + checksums esperados
2. Para cada archivo listado: verificar que existe (con `Read` o `ls`). Si tiene checksum en MANIFEST, calcular SHA256 con `shasum -a 256` y comparar
3. Verificar VERSION vs `**Versión:**` en SKILL.md — reportar si difieren
4. Verificar las 5 env vars (`BIZUIT_API_URL`, `BIZUIT_BPMN_API_URL`, `BIZUIT_USERNAME`, `BIZUIT_PASSWORD`, `BIZUIT_ORG_ID`)
5. Opcionalmente: testear conectividad a las APIs con `curl -s --connect-timeout 5`
6. Reportar con ✅/⚠️/❌ por check:
   - ❌ = no funcional (ej: SKILL.md ausente)
   - ⚠️ = funcional pero incompleto (ej: env vars faltantes, versión inconsistente)
   - ✅ = OK

Para error codes, ver `rules/error-catalog.md`.

Para naming conventions, ver `rules/naming-conventions.md`.

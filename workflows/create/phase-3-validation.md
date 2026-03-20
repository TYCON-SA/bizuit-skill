# Phase 3: Validación Integrada

> Extraído de create.md monolítico (Paso 10 + regla transversal). Refactoring puro.
> También usado por workflows/validate.md como validación manual standalone.

## Rules que esta fase carga

1. `rules/sdd/completeness-checklist.md` — BLOCKER/WARNING/DRAFT items
2. `rules/sdd/spec-format.md` — formato de spec v2.1
3. `rules/sdd/anti-patterns.md` — detección post-elicitación
4. `rules/bizuit/common/validation-rules.md` — 53 reglas de linting
5. `rules/sdd/test-path-generation.md` — generar test paths

## Precondiciones

- Spec con status: "complete" y completedSections con al menos las 8 secciones requeridas
- O: invocado manualmente desde validate.md sobre cualquier spec

## Instrucciones

### Paso 10 — Validate integrado

Al completar todas las secciones, ejecutar automáticamente el validate.

1. **Cargar** `rules/sdd/completeness-checklist.md`
2. **Verificar** cada regla contra la spec actual (leer el archivo, no memoria de sesión)
3. **Presentar resultados** a nivel de regla por sección:

**Sin blockers:**
```
"✅ Spec completa — validate sin blockers (N/N reglas OK)

 Reglas verificadas por sección:
 ✅ Sección 1 — Objetivo:
    ✅ Nombre del proceso definido
    ✅ Trigger definido
    ✅ Resultado esperado definido
 ✅ Sección 2 — Actores:
    ✅ Participantes identificados
 ✅ Sección 3 — Journeys:
    ✅ {N} actividades con tipo asignado
    ✅ {G} gateways con condiciones
    ✅ Nombres únicos (sin duplicados)
    ✅ ACs definidos en journeys
 ...

 ⚠️ {W} warnings (no bloqueantes):
    - {detalle de cada warning}

 ¿Procedemos a generar el BPMN?"
```

**Con blockers:**
```
"❌ Spec incompleta — {B} blockers deben resolverse antes de generar BPMN:

 ❌ BLOCKER 1: {descripción}
    → {pregunta para resolverlo}

 ❌ BLOCKER 2: {descripción}
    → {pregunta para resolverlo}

 No se puede generar BPMN hasta resolver estos {B} blockers."
```

4. **Si hay blockers** → ofrecer resolver cada uno en orden, sin empezar de nuevo
5. **Si blocker se resuelve** → re-ejecutar solo el check de ese blocker, no toda la checklist
6. **Cuando todos los blockers se resuelven** → mostrar resultado limpio y ofrecer generar BPMN

### Validación de Lanes (Epic 15 — FR133)

**Solo ejecutar si frontmatter del spec tiene `lanes: true`.** Si `lanes: false` o campo no existe → saltar esta sección completamente.

**T09 — Actor tiene activities:**
Para cada actor en Sección 2, verificar que tiene ≥1 actividad asignada (bizuit:Performers matchea).
- PASS → sin output
- FAIL → ⚠️ WARNING: "Actor '{nombre}' no tiene actividades asignadas. No se generará lane para este actor. ¿Es un rol RACI (Consulted/Informed) sin tareas directas?"

**T10 — Activity tiene performer:**
Para cada actividad tipo task (UserTask, SendTask, ReceiveTask, ScriptTask), verificar que tiene performer asignado.
- PASS → sin output
- FAIL → ❌ ERROR: "Actividad '{nombre}' no tiene performer asignado. Todas las actividades deben tener performer cuando se usan lanes."
- ServiceTask sin performer → ⚠️ WARNING (no error): "ServiceTask '{nombre}' no tiene performer. Se asignará al lane de la actividad precedente."
- Gateways y eventos NO requieren performer → no evaluar T10 para ellos.

**T11 — Performers matchean Actores S2:**
Para cada performer en actividades, verificar que existe como actor en Sección 2.
- PASS → sin output
- FAIL → ❌ ERROR: "Performer '{nombre}' en actividad '{actividad}' no está definido en la sección de Actores. Agregalo a Sección 2 o corregí el nombre."
- Performer vacío o solo espacios → ❌ ERROR: "Performer vacío detectado en actividad '{nombre}'."

**Case normalization:**
Comparar performers case-insensitive. Primera ocurrencia en el flujo es canonical (ej: "Ventas" aparece primero → "ventas" se normaliza a "Ventas"). Reportar como INFO si se detecta normalización.

**Caracteres especiales XML:**
Si un performer contiene &, <, >, ", ' → INFO: "Se escapará como {escaped} en el BPMN XML."

**Inconsistencia frontmatter vs spec:**
Si la spec tiene sección "## Lanes" pero frontmatter dice `lanes: false` → ⚠️ WARNING: "Se encontró sección Lanes pero frontmatter dice lanes=false. Ignorando sección Lanes."
Si `lanes: true` pero no hay sección de Actores (Sección 2) → ❌ ERROR graceful: "Sección de Actores no encontrada pero lanes=true. No se puede validar completitud de roles."

## Al completar

Si invocado desde create.md orchestrator: volver a `create.md` para routing a phase-4 (generación).
Si invocado desde validate.md: presentar resultado y terminar (NO avanzar a generación).

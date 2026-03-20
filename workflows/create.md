# Create — Especificar Proceso Nuevo (Orchestrator)

> Orchestrator que despacha a phase files según estado del frontmatter.
> NO contiene lógica de elicitación, validación ni generación — solo routing.
> Cada phase file es self-contained y declara sus propias rules.

## Cuándo se activa

Cuando el router de `SKILL.md` detecta intent CREATE (keywords: `crear`, `nuevo`, `nuevo proceso`, `definir proceso`).

## Prerequisitos

- `BIZUIT_ORG_ID` configurado (para directorio de output `processes/{org}/{slug}/`)
- Si `BIZUIT_ORG_ID` no está configurado → preguntar: "¿Cuál es el identificador de organización (tenant)?"
- Las credenciales de API son opcionales — config lazy (se piden al primer uso via api-auth.md wizard)

## Phase Routing

Leer spec en `processes/{org}/{proceso-slug}/spec.md` (si existe) y despachar según estado:

| Condición | Phase file | Descripción |
|-----------|-----------|-------------|
| No existe spec | `create/phase-1-elicitation.md` | Crear proceso desde cero |
| `draftedSections` tiene items | `create/phase-2-refinement.md` | Continuar refinamiento de draft (forward-compatible para draft-first, story 6.7) |
| `status: "partial"` + `completedSections` < 8 secciones | `create/phase-2-refinement.md` | Continuar elicitación de secciones pendientes |
| `status: "complete"` + no existe `process.bpmn` | `create/phase-3-validation.md` | Validar spec antes de generar |
| Existe `process.bpmn` + `logicalProcessId` es null | `create/phase-4-generation.md` | Spec validada, generar y persistir BPMN |
| `logicalProcessId` existe | — | "Este proceso ya está completo y publicado. ¿Querés: [1] editar, [2] consultar, [3] re-generar BPMN?" |

### Backward Compatibility

Si la spec no tiene campo `draftedSections` ni `completedSections` (spec creada con MVP):
- Si `status: "complete"` → tratar como completamente confirmada (ofrecer edit/query)
- Si `status: "partial"` → inferir completedSections de las secciones presentes en la spec
- Si no hay frontmatter → tratar como spec nueva (Empty)

### Frontmatter Incoherente (FR101)

Si `status: "complete"` pero `draftedSections` no vacío → ofrecer reparar:
"Frontmatter inconsistente (spec marcada como completa pero hay secciones en draft). ¿Querés: [1] reparar (mover drafts a completed), [2] tratar como partial, [3] abortar?"

Si `draftedSections` y `completedSections` tienen la misma sección → quitar de draftedSections.

## Retorno de Phase Files

Cada phase file termina con "volver a create.md". Al retornar:
1. Re-leer el frontmatter de la spec (el phase file lo actualizó)
2. Re-evaluar la routing table con el nuevo estado
3. Despachar al siguiente phase file

**Los phase files NUNCA se referencian entre sí.** Solo vuelven al orchestrator.

## Phase Files

| Phase | Archivo | Contenido |
|-------|---------|-----------|
| 1 | `create/phase-1-elicitation.md` | Filesystem check + Secciones 1-3 + "no sé" handling + perfil adaptación |
| 2 | `create/phase-2-refinement.md` | Secciones 4-8 + Forms + edge cases + NFRs |
| 3 | `create/phase-3-validation.md` | Validate integrado + test path generation |
| 4 | `create/phase-4-generation.md` | Generar BPMN + self-validation + persist |

## Regla transversal — Guardado por respuesta (NFR19)

**CRITICAL:** Escribir a disco después de **CADA respuesta** del analista, no solo al final de cada sección.

Después de cada respuesta del usuario que aporta información nueva:
1. Actualizar `spec.md` con el dato nuevo en la sección correspondiente
2. Actualizar `lastActivity` en frontmatter con la posición actual
3. Si se completó una sección → actualizar `completedSections`
4. Si hay actividades nuevas → actualizar `detalle-tecnico.md` con placeholder

**Formato de lastActivity:**
- Durante Sección 3: `"Actividad {N} de {total}: {nombre}"`
- Durante Sección 4: `"Atributos técnicos de {nombre} ({tipo})"`
- Durante Paso 8: `"Form de {nombre}"`
- Durante Secciones 6-8: `"Sección {N}"`

**Retomar sesión:**
Cuando se detecta spec parcial, presentar resumen detallado:
```
"Encontré una spec parcial del proceso '{nombre}'.
 Completaste: {secciones completas listadas}
 Última actividad: {lastActivity}
 Pendiente: {qué falta}
 ¿Retomamos donde quedamos o empezamos de nuevo?"
```

Si retoma → despachar al phase file correcto según la routing table.
Si `createdBy` es diferente al usuario actual → mencionar: "Esta spec fue iniciada por {nombre}. ¿Continuamos?"




# ID Preservation — Re-generation with Original IDs

> Preserva IDs originales de actividades al re-generar BPMN después de editar.
> Invocada por `workflows/edit.md` (story 5.5) como parte del Step 5, antes de generar BPMN.
> Critico: los formularios de BIZUIT se bindean por ID de actividad. Si el ID cambia, el form queda huérfano.

## Cuándo aplica

Cargada durante el flujo EDIT al re-generar el BPMN. En el flujo CREATE no aplica (no hay IDs originales que preservar).

## Algoritmo de resolución de IDs

```
Para cada actividad en la spec:

1. Leer originalIds del frontmatter de spec.md
   - Formato: { "vdwNativeId": "displayName" }
   - Ej: { "handleActivity5": "Aprobar Solicitud" }

2. IF originalIds == null OR vacío:
     → Proceso creado con create (sin reverse previo)
     → Todos los IDs son determinísticos: {Type}_{SlugifiedName}
     → No hay forms vinculados que puedan quedar huérfanos
     → RETURN

3. Para cada actividad en la spec:
   a. Buscar en originalIds por displayName actual
      - El lookup es: ¿hay alguna entry cuyo value (displayName) matchea el nombre de esta actividad?
      - Si el nombre fue renombrado (story 5.2), el displayName en el mapa ya fue actualizado
   b. IF found → usar el key (vdwNativeId) como ID en el BPMN
   c. IF NOT found → actividad nueva → ID determinístico {Type}_{SlugifiedName}

4. Verificación pre-generación (FR66):
   Para cada entry en originalIds:
   - ¿Existe una actividad en la spec con ese displayName?
   - IF no → la actividad fue eliminada
   - Advertir: "⚠️ '{displayName}' (ID: {vdwNativeId}) fue eliminada. Form potencialmente huérfano."
   - Pedir confirmación antes de continuar
```

## Tabla de resolución de IDs

| Caso | originalIds tiene entry? | ID usado en BPMN |
|---|---|---|
| Actividad existente (sin rename) | Sí, displayName match | vdwNativeId (ej: `handleActivity5`) |
| Actividad existente (renombrada) | Sí, displayName ya actualizado por 5.2 | vdwNativeId (preservado) |
| Actividad nueva (agregada en edit) | No | `{Type}_{SlugifiedName}` (determinístico) |
| Actividad eliminada | Entry existe pero sin actividad en spec | No se genera — advertir |
| Proceso sin originalIds (create) | null/vacío | `{Type}_{SlugifiedName}` para todas |

## Persist con saveAction para ediciones

| Situación | saveAction | logicalProcessId |
|---|---|---|
| Proceso nuevo (create) | `"newVersion"` | null → se recibe en response |
| Proceso editado (edit) | `"updateVersion"` | Ya existe en frontmatter → enviar |
| Update en lugar de nueva versión | `"update"` | Ya existe → enviar |

```json
POST /api/bpmn/persist
{
  "saveAction": "updateVersion",
  "logicalProcessId": "{del frontmatter}",
  "bpmnXml": "{nuevo BPMN}",
  "processName": "{processName}",
  "organizationId": "{org}"
}
```

Response: `{ "version": "3.0.0.0" }`. Solo actualizar `currentVersion` en frontmatter. El `logicalProcessId` ya existe — no depender de que la response lo incluya.

## Resumen de re-generación

```
"BPMN re-generado para '{processName}':
 - {P} IDs preservados de originalIds
 - {N} IDs determinísticos nuevos
 - {E} actividades eliminadas (advertidas)
 - Guardado en processes/{org}/{slug}/process.bpmn

 ¿Persistir nueva versión en BIZUIT?"
```

## originalIds incompletos

Si originalIds tiene menos entries que actividades en la spec (ej: 8 de 12):
- Las 8 con entry → IDs preservados
- Las 4 sin entry → IDs determinísticos
- Resumen: "8 IDs preservados, 4 IDs determinísticos nuevos"
- No es un error — es el caso normal cuando se agregan actividades a un proceso reverse-engineered

## Form Binding Safety (FR86 — v2.1)

En BIZUIT, los formularios React se bindean a actividades por ID. Si un UserTask ID cambia o se elimina, el form pierde el binding y no aparece en runtime.

**Pre-check antes de re-generar BPMN:**

Para cada UserTask en `originalIds`:
1. ¿Sigue existiendo en la spec? Si fue eliminado → WARNING
2. ¿El nombre cambió (lo que genera nuevo ID determinístico)? Si sí → WARNING con opciones

**Warning al eliminar UserTask:**
```
"⚠️ La actividad '{name}' (ID: {id}) es UserTask y fue eliminada.
 Si tiene form bindeado en BIZUIT, ese form quedará huérfano.
 ¿Confirmás la eliminación?"
```

**Warning al renombrar UserTask (ID cambia):**
```
"⚠️ '{oldName}' fue renombrado a '{newName}'.
 El ID cambia de {oldId} a {newType}_{newSlug}.
 Si {oldId} tiene form bindeado, el binding se rompe.
 Opciones:
 1. Mantener ID original ({oldId}) con el nuevo nombre
 2. Usar nuevo ID ({newType}_{newSlug}) — puede romper form
 3. Cancelar el rename"
```

**Reglas:**
- Warning solo para UserTask (único tipo con form binding en BIZUIT)
- Solo cuando ID cambia o actividad se elimina (no en edits normales donde IDs se preservan)
- Warning NO bloquea — el usuario puede confirmar y continuar
- Asumir que TODOS los UserTask pueden tener forms (conservador — no podemos verificar sin Dashboard)
- Actividades nuevas (sin originalId) → no warning (no tienen form binding previo)
- Múltiples UserTasks afectados → agrupar warnings, ofrecer "revisar uno por uno"

## Gotchas

- **NUNCA** generar IDs determinísticos para actividades que tienen originalId — rompe forms
- El lookup es por displayName en el VALUE del mapa, no por key
- Si dos entries tienen el mismo displayName → advertir ambigüedad, pedir al usuario que desambigue
- Actividades eliminadas dejan entries "huérfanas" en originalIds — documentar pero no borrar del mapa
- `saveAction: "updateVersion"` para ediciones (no "newVersion" que crea un proceso separado)
- El BPMN local se guarda ANTES del persist (FR68) — mismo patrón que create
- BIZUIT versioning es inmutable — cada updateVersion crea una versión nueva, no modifica la anterior

# Change Diff — Version Comparison

> Genera diff entre versiones de una spec después de editar.
> Invocada por `workflows/edit.md` (story 5.5) como Step 6, después de aplicar cambios quirúrgicos.
> Identifica caminos de test afectados y clasifica cambios como lógicos vs documentales.

## Cuándo aplica

Cargada durante el flujo EDIT después de la elicitación quirúrgica (story 5.2). Presenta el diff al usuario antes de confirmar la re-generación del BPMN.

## Flujo

```
1. Antes de aplicar cambios: guardar snapshot como spec.prev.md en disco
   - Si ya existe spec.prev.md (sesión interrumpida anterior) → conservar la más antigua
2. Después de aplicar cambios: comparar spec.prev.md vs spec.md
3. Generar diff con formato +/-/~
4. Calcular caminos de test afectados
5. Clasificar: lógico vs documental
6. Presentar diff
7. Si lógico → ofrecer re-generar BPMN
   Si documental → guardar spec sin re-generar
```

## Formato del diff

```
📋 Diff — {processName} v{prevVersion} → v{newVersion}

Actividades:
+ {nombre} ({tipo}) — nueva en posición {N}
~ {nombre} (antes: {nombreAnterior}) — renombrado (ID preservado)
~ {nombre} — {atributo} modificado (antes: {valor}, ahora: {valor})
- {nombre} ({tipo}) — eliminada
  ⚠️ ID original {id} liberado (form potencialmente huérfano)

Gateways:
~ Gateway '{nombre}' — condición modificada
  Antes: {condiciónAnterior}
  Ahora: {condiciónNueva}

Parámetros:
+ {nombre} ({tipo}, {dirección}) — nuevo
~ {nombre} — tipo cambiado ({antes} → {ahora})
- {nombre} — eliminado

Caminos de test:
✅ Afectados ({N} de {total}):
   - {caminoN}: {razón del impacto}
✅ NO afectados ({M} de {total}):
   - {caminoM}

{Clasificación: "Este cambio requiere re-generar el BPMN." o "Cambio documental — no requiere re-generar BPMN."}
```

## Comparación elemento por elemento

| Elemento | Cómo comparar | Tipo de cambio |
|---|---|---|
| Actividad agregada | Existe en spec.md pero no en spec.prev.md | Lógico |
| Actividad eliminada | Existe en spec.prev.md pero no en spec.md | Lógico |
| Actividad renombrada | Mismo originalId, diferente nombre | Lógico (afecta BPMN name) |
| Condición de gateway | Diferente conditionExpression | Lógico |
| Parámetro agregado/eliminado | Diff en sección Parámetros | Lógico |
| Parámetro tipo cambiado | Mismo nombre, diferente tipo | Lógico |
| Descripción cambiada | Texto de narrativa diferente | **Documental** |
| AC cambiado | Texto de AC diferente | **Documental** |
| Comentario/nota cambiada | Texto informativo | **Documental** |
| Form: campo agregado/eliminado | Diff en sección Form | Lógico |
| Form: validación cambiada | Diferente regla de validación | Lógico |

## Cambio documental vs lógico (FR35)

**Documental** = no afecta el BPMN XML generado. Solo texto informativo en la spec.

Si TODOS los cambios son documentales:
```
"Este cambio no afecta la lógica del proceso.
 No es necesario re-generar el BPMN.
 ¿Guardar los cambios en la spec sin actualizar el BPMN?"
```
→ Si confirma: guardar spec.md, NO re-generar BPMN, currentVersion sin cambios.

Si HAY cambios lógicos:
```
"Este cambio afecta la lógica del proceso.
 ¿Procedemos a re-generar el BPMN y persistir?"
```

## Cálculo de caminos afectados

Para cada cambio lógico, determinar qué journeys/caminos pasan por el elemento afectado:

| Tipo de cambio | Caminos afectados |
|---|---|
| Actividad nueva ANTES del primer gateway | **Todos** los caminos |
| Actividad nueva DESPUÉS de un gateway | Solo caminos que pasan por esa rama |
| Actividad eliminada | Caminos que incluían esa actividad |
| Condición de gateway modificada | Caminos que pasan por ese gateway |
| Parámetro eliminado | Caminos que usan actividades que dependen de ese parámetro |

Si TODOS los caminos están afectados:
```
"Todos los caminos afectados (el cambio es antes de la primera bifurcación).
 QA debe re-testear todos los caminos."
```

## Sección Extensiones (FR58)

La sección `## Extensiones` en spec.md es contenido manual del usuario. **NUNCA se modifica ni se incluye en el diff como cambio.**

- Al re-generar la spec → preservar `## Extensiones` intacta
- Al calcular diff → ignorar cambios en `## Extensiones`
- Los caminos manuales en Extensiones no se actualizan automáticamente
- Si un cambio lógico afecta un camino manual → advertir: "Camino manual '{nombre}' podría verse afectado por este cambio. Verificar manualmente."

## Snapshot (spec.prev.md)

- Se guarda en el mismo directorio que spec.md
- Se crea ANTES de aplicar cualquier cambio de la sesión de edit
- Si ya existe de una sesión anterior interrumpida → conservar la más antigua (es la base real)
- Se elimina después de confirmar el persist exitoso
- Formato: copia exacta de spec.md al momento del snapshot

## Gotchas

- El diff es a nivel de SPEC (Markdown), no de BPMN XML
- Cambios documentales NO generan nueva versión en BIZUIT
- spec.prev.md es un archivo temporal — no commitear
- Si no hay snapshot (primera edición sin base) → diff solo muestra cambios de la sesión actual
- Caminos obsoletos (que ya no son válidos) se marcan como tales
- La sección Extensiones se preserva INTACTA — es responsabilidad del usuario mantenerla

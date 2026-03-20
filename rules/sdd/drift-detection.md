# Drift Detection — Spec vs BIZUIT

> Detecta si la spec local está desactualizada respecto a la versión en BIZUIT.
> Invocada por `workflows/edit.md` (story 5.5) como Step 2, antes de cualquier elicitación de cambios.

## Cuándo aplica

Cargada al inicio del flujo EDIT. Antes de modificar la spec, verificar que está sincronizada con BIZUIT. Si hay drift, el usuario decide si continúa o sincroniza primero.

## Algoritmo

```
1. Leer frontmatter de spec.md
2. Extraer logicalProcessId y currentVersion
3. IF logicalProcessId == null:
     → "Spec nunca persistida. No puedo verificar drift. Continuando."
     → Proceder sin check
4. IF BIZUIT API no disponible:
     → Autenticar (lazy, via api-auth.md)
     → GET {BIZUIT_BPMN_API_URL}/bpmn/search?name={processName}&scope=all
     → IF timeout (>15s) o error de red:
         → "No pude verificar la versión en BIZUIT (API no disponible).
            ¿Querés continuar editando sin verificar?"
         → IF sí: registrar nota en spec "⚠️ Drift check omitido el {fecha}"
         → IF no: abortar
5. Extraer version del resultado de search
6. IF currentVersion == bizuitVersion (string comparison):
     → Sin drift. "(spec sincronizada con BIZUIT v{version})"
     → Proceder
7. IF currentVersion != bizuitVersion:
     → Drift detectado. Advertir con opciones.
8. IF 404 (proceso no encontrado):
     → "Proceso '{logicalProcessId}' no encontrado en BIZUIT.
        ¿Tratar como nuevo o verificar manualmente?"
```

## Mensaje de drift

```
"⚠️ Drift detectado en '{processName}':
 - Spec local: v{currentVersion}
 - BIZUIT actual: v{bizuitVersion} ({N} versiones de diferencia)

 Alguien modificó el proceso directamente en BIZUIT sin actualizar la spec.
 Si editás ahora, los cambios de las versiones intermedias no estarán en tu spec.

 ¿Qué querés hacer?
 a) Sincronizar primero (reverse del proceso actual) → luego editar
 b) Editar igualmente sobre la spec local (con riesgo de perder cambios)
 c) Cancelar"
```

## Opciones del usuario

### a) Sincronizar (reverse)

- Ejecutar `workflows/reverse.md` para el mismo proceso
- El reverse descarga el VDW actual y genera una spec nueva
- Después del reverse → retomar flujo de edit sobre la spec actualizada
- **Si reverse.md no está disponible** → "El flujo reverse no está disponible. Podés hacer reverse manual o elegir otra opción."

### b) Editar sobre spec desactualizada

- Registrar en spec.md como nota de auditoría:
  ```
  > ⚠️ drift: editado sobre spec v{currentVersion} cuando BIZUIT estaba en v{bizuitVersion}
  > Fecha: {ISO 8601}. Los cambios de las versiones intermedias no fueron incorporados.
  ```
- Continuar con elicitación quirúrgica (story 5.2)
- Al persistir, se crea una nueva versión en BIZUIT (inmutable) que puede sobrescribir cambios

### c) Cancelar

- No modificar nada. Volver al menú.

## Comparación de versiones

- Comparación por **string** — `"1.0.0.0"` vs `"3.0.0.0"`
- BIZUIT usa versioning inmutable: cada publish crea una nueva versión
- Calcular diferencia: parsear como integers y restar el primer componente
  - `"1.0.0.0"` vs `"3.0.0.0"` → 2 versiones de diferencia
  - `"1"` vs `"3"` → 2 versiones de diferencia (formatos mixtos OK)
- Si los formatos difieren pero el número base es igual → sin drift
  - `"1"` == `"1.0.0.0"` → sin drift

## Nota de auditoría en spec.md

Cuando el drift check se omite o se edita con drift conocido, agregar al final del body de spec.md:

```markdown
## Notas de auditoría

> ⚠️ Drift check omitido el 2026-03-18T10:00:00Z — API no disponible
```

o

```markdown
## Notas de auditoría

> ⚠️ Drift: editado sobre spec v1.0.0.0 cuando BIZUIT estaba en v3.0.0.0
> Fecha: 2026-03-18T10:00:00Z. Cambios de v2 y v3 no incorporados.
```

## Modificación a api-auth.md

El drift check usa el endpoint de search de la BPMN API:

```
GET {BIZUIT_BPMN_API_URL}/bpmn/search?name={processName}&scope=all
Authorization: Bearer {token}
```

Response incluye `version` del proceso. Esta llamada es de lectura — no modifica nada.

## Gotchas

- El drift check es **no bloqueante** — el usuario puede elegir continuar
- Si no hay `logicalProcessId`, no se puede verificar drift (spec nunca persistida)
- Si no hay `currentVersion` pero sí `logicalProcessId` → "Sin información de versión. Verificar manualmente."
- La nota de auditoría persiste en la spec como registro permanente
- BIZUIT no permite revertir a versiones anteriores — cada publish es inmutable
- El drift check se ejecuta UNA vez al inicio del edit, no durante la edición

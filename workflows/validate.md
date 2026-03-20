# Validate — Verificar Completitud de Spec

> Wrapper que carga phase-3-validation.md en modo solo-lectura.
> No avanza a generación BPMN — solo valida y reporta.

## Cuándo se activa

Cuando el router de `SKILL.md` detecta intent VALIDATE (keywords: `validar`, `verificar`, `check`, `revisar spec`).

## Instrucciones

### Paso 1 — Identificar spec a validar

1. **Extraer nombre del proceso** del mensaje del usuario
2. **Buscar spec** en `processes/{org}/{proceso-slug}/spec.md`
3. Si no existe → "No encontré spec para ese proceso. ¿Verificás el nombre?"
4. Si existe → leer completa

### Paso 2 — Ejecutar validación

Cargar y seguir las instrucciones de `create/phase-3-validation.md`.

### Paso 3 — Presentar resultado

Mostrar resultado de la validación (PASS/FAIL + detalle).

**NO avanzar a generación BPMN.** Este workflow es solo validación.

Si el usuario quiere generar BPMN después de validar → indicar: "Usá 'crear proceso {nombre}' para generar el BPMN."

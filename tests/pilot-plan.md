# Pilot Test Plan — bizuit-sdd v1.2.0

## Objetivo

Validar el skill end-to-end con un proceso real de BIZUIT, verificando que forms generados renderizan correctamente en el editor BIZUIT y que el round-trip (create → import → reverse) es consistente.

## Plan A: Proceso real (equipo BIZUIT disponible)

### Pre-requisitos
- Acceso a ambiente BIZUIT (dev o qa)
- Credenciales configuradas en `.bizuit-config.yaml`
- Proceso con >= 3 actividades y forms

### Pasos
1. Elegir proceso real con >= 3 UserTasks que tengan formularios
2. Ejecutar CREATE: definir proceso con parametros similares al real
3. Generar BPMN con forms embebidos
4. Importar BPMN en editor BIZUIT via API (persist)
5. Abrir proceso en editor BIZUIT y verificar:
   - Forms renderean correctamente
   - Bindings a parametros funcionan
   - Encoding HTML preservado (acentos, caracteres especiales)
   - Botones Enviar/Cancelar presentes y funcionales
6. Ejecutar REVERSE del mismo proceso
7. Comparar spec generada por reverse con spec original del create
8. Verificar consistencia del round-trip

### Criterio de exito
- Forms renderean en editor sin errores
- Bindings funcionan (datos fluyen entre actividades)
- Round-trip consistente (spec create ~ spec reverse)

## Plan B: Fallback con fixtures (equipo BIZUIT no disponible)

### Pre-requisitos
- Fixtures disponibles en `tests/fixtures/`
- No requiere acceso a BIZUIT

### Pasos
1. Usar fixture `tests/fixtures/procesoconforms_v1.bpmn` como referencia
2. Ejecutar REVERSE del fixture `tests/fixtures/procesoconforms.vdw`
3. Comparar spec generada con expectativas conocidas del proceso
4. Ejecutar CREATE con parametros similares al fixture
5. Comparar BPMN generado vs fixture (structural, no byte-exact)
6. Seguir checklist de `tests/functional/bizuit-forms-scenario.md`

### Criterio de exito
- Structural match segun bizuit-forms-scenario.md
- Diferencias solo en IDs, timestamps, formId

## Dependencia

Equipo BIZUIT (no bloqueante — Plan B siempre disponible).

## Timeline

Ejecutar despues de completar todas las stories de Epic 10.

# Completeness Checklist

> Rule genérica SDD — valida que una spec tiene toda la información necesaria.
> **QS-02**: Reorganizada de 5 capas a 9 secciones PRD + detalle técnico.
> **QS-03**: Validación de links cross-file (spec.md ↔ detalle-tecnico.md) y catálogo SQL.

## Cuándo aplica

Cargada por `workflows/create.md` (validate automático antes de generar BPMN) y invocable manualmente ("validar spec").

## BLOCKER Items (sin esto NO generar BPMN)

### Sección 1: Objetivo del proceso
- [ ] BLOCKER: `processName` definido
- [ ] BLOCKER: Objetivo descrito (al menos 1 frase)
- [ ] BLOCKER: `entryChannel` definido (web/mobile/scheduler/integración/otro)

### Sección 2: Actores
- [ ] BLOCKER: Al menos 1 actor/rol (o "proceso automatizado")

### Mapa del proceso (opcional — ignorar si no existe)
- [ ] WARNING: Si >15 actividades y NO hay `## Mapa del proceso` → "Proceso con {N} actividades sin mapa. Considerar generarlo."
- [ ] WARNING: Si hay mapa → verificar que conteos por sección no difieran >30% del detalle (base = detalle)
- [ ] NOTA: Headings sin número entre secciones numeradas (como `## Mapa del proceso`) son VÁLIDOS — no reportar como error

### Sección 3: Escenarios
- [ ] BLOCKER: Al menos 1 escenario (camino exitoso)
- [ ] BLOCKER: Cada escenario con narrativa y steps
- [ ] BLOCKER: Cada gateway exclusivo con condición EXACTA
- [ ] BLOCKER: Cada gateway con default path
- [ ] BLOCKER: Cada user task con al menos 1 acción (botón/evento)
- [ ] BLOCKER: Al menos 1 AC por journey
- [ ] BLOCKER: Nombres de actividades únicos (sin duplicados)
- [ ] BLOCKER: No hay loops en el flujo principal (solo For/While permitidos)

### Sección 4: Funcionalidades
- [ ] BLOCKER: Al menos 1 funcionalidad si el proceso tiene actividades
- [ ] BLOCKER: Cada SQL con CommandType definido (Text/StoredProcedure)
- [ ] BLOCKER: Cada SQL con ReturnType definido (Scalar/DataSet/NonQuery)
- [ ] BLOCKER: Cada REST con método HTTP definido (GET/POST/PUT/DELETE)
- [ ] BLOCKER: Cada Timer/Expirable con duración definida (o WARNING → BLOCKER antes de BPMN)
- [ ] BLOCKER: Cada For con lista de iteración y modo (transaccional/best-effort)
- [ ] BLOCKER: Cada User Task form con al menos acciones definidas
- [ ] BLOCKER: Campos obligatorios de forms con tipo de dato definido

### Sección 6: Edge Cases
- [ ] BLOCKER: Errores mencionados en journeys documentados en esta sección

### Sección 8: Decisiones y Restricciones
- [ ] BLOCKER: SLAs mencionados en journeys documentados acá
- [ ] BLOCKER: Restricciones de seguridad mencionadas documentadas

### Cross-file integrity (v2.1)
- [ ] BLOCKER: Links cross-file en spec.md tienen anchor correspondiente en detalle-tecnico.md
- [ ] BLOCKER: specFormatVersion "2.1" y detalle-tecnico.md existe

## DRAFT Items (sección generada pero no confirmada — v2.1)

- [ ] DRAFT: Sección en `draftedSections` del frontmatter → no confirmada por usuario
- [ ] DRAFT: Item marcado como 🔴 PENDIENTE inline → asunción rechazada, info faltante

**Regla**: NO generar BPMN si hay secciones en `draftedSections` o items PENDIENTE inline.
Deben confirmarse (pasar a completedSections) o convertirse en WARNING.

**Transiciones**:
- DRAFT → COMPLETE: usuario confirma sin cambios
- DRAFT → WARNING: usuario confirma con "no sé" en algunos items
- DRAFT → BLOCKER: usuario rechaza y no da alternativa
- PENDING → WARNING: usuario dice "dejá el default por ahora" → default queda como asunción
- PENDING → COMPLETE: usuario resuelve con dato concreto

## WARNING Items (puede avanzar pero hay riesgo)

### Estructura general
- [ ] WARNING: Spec con status "partial"
- [ ] WARNING: Pregunta "no sé" sin resolver
- [ ] WARNING: `specFormatVersion` es "1.0" (formato anterior)
- [ ] WARNING: Item con asunción no confirmada (⚠️ inline)

### Sección 3: Journeys
- [ ] WARNING: Proceso con gateways pero sin journey de error
- [ ] WARNING: Journey sin ACs
- [ ] WARNING: Más de 10 journeys (considerar agrupar)

### Sección 4: Funcionalidades
- [ ] WARNING: Funcionalidades 1:1 con actividades (deberían agruparse)

### Sección 5: Integraciones
- [ ] WARNING: Integración (SQL/REST) sin manejo de error en sección 6
- [ ] WARNING: Sección vacía en proceso con actividades SQL/REST/Email

### Sección 6: Edge Cases
- [ ] WARNING: 50+ actividades sin subprocesos (God Process)
- [ ] WARNING: User task sin SLA/timeout

### Sección 7: NFRs
- [ ] WARNING: Expirable detectado sin NFR documentado
- [ ] WARNING: REST sin timeout documentado

### Sección 9: Auditoría
- [ ] WARNING: URLs hardcodeadas detectadas sin documentar
- [ ] WARNING: ConfigSettings sin listar
- [ ] WARNING: Credentials presentes (verificar en ambiente)

### Detalle técnico (v2.1: detalle-tecnico.md)
- [ ] WARNING: Actividad mencionada en journeys sin bloque `#### detalle-` en detalle-tecnico.md
- [ ] WARNING: Parámetro sin tipo de dato
- [ ] WARNING: Link cross-file en spec.md sin anchor correspondiente en detalle-tecnico.md
- [ ] WARNING: specFormatVersion "2.1" pero detalle-tecnico.md no existe (DETAIL_MISSING)
- [ ] WARNING: specFormatVersion "2.0" sin `## Detalle técnico` inline en spec.md

### Catálogo SQL (v2.1)
- [ ] WARNING: SqlActivity presente pero sin subsección "Dependencias de datos" en Integraciones
- [ ] WARNING: Tabla detectada en query pero no listada en catálogo

### Forms BizuitForms (Epic 9 — regla 54+)

**Regla 54: serializedForm JSON parseable**
- [ ] WARNING: Si BPMN existe con `bizuit:serializedForm` en una actividad → verificar que el JSON es valido (decodificar HTML entities → JSON.parse). Si JSON invalido → WARNING: "serializedForm de '{activityName}' no es JSON valido"

**Coherencia form-parametros:**
- [ ] WARNING: Parametro definido en spec sin binding en form del UserTask correspondiente → "Parametro '{paramName}' definido en spec pero sin binding en form de '{UserTask}'"
- [ ] WARNING: Control en form con binding a parametro inexistente en spec → "Control en form de '{UserTask}' bindeado a '{paramName}' — parametro no existe en spec"

**Notas:**
- Solo controles con binding activo se verifican (excluir Labels, Headers, Containers, Separators — controles sin BindingsPropertiesComponent)
- Skip silencioso si no hay BPMN o si la actividad no tiene serializedForm (no es error ni warning)
- Las reglas 1-53 existentes NO se modifican — estos checks de forms son adicionales (A26)
- Los nuevos checks solo ejecutan si hay serializedForm presente en el BPMN
- Forma parte del validate integrado (FR39): se ejecuta junto con las demas reglas, resultados presentados en el mismo reporte

## Formato de reporte

```
✅ Sección 1 (Objetivo): completa
✅ Sección 2 (Actores): completa
⚠️ Sección 3 (Journeys): 1 warning (journey sin ACs)
✅ Sección 4 (Funcionalidades): completa
✅ Sección 5 (Integraciones): completa
❌ Sección 6 (Edge Cases): 1 blocker (error de API sin documentar)
✅ Sección 7 (NFRs): completa
✅ Sección 8 (Decisiones): completa
✅ Sección 9 (Auditoría): completa
✅ Detalle técnico: completo

N issues: X BLOCKERs, Y WARNINGs
```

## Gotchas

- Validate NO bloquea guardado de spec parcial — solo reporta
- Validate SÍ bloquea generación de BPMN si hay BLOCKERs
- WARNINGs: usuario puede ignorar y generar
- BLOCKERs: usuario NO puede ignorar — resolver primero
- Las secciones auto-generadas (5, 9, Detalle) se validan por completitud, no por contenido elicitado

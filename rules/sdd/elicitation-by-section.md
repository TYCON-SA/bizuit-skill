# Elicitation By Section — Orchestrator

> Rule genérica SDD — independiente de BIZUIT. Portable a cualquier BPM.
> **v2.1**: Reorganizada como orchestrator + 3 sub-archivos alineados con progressive disclosure.
> Sub-archivos: `elicitation/sections-1-3.md`, `elicitation/sections-4-6.md`, `elicitation/sections-7-9.md`

## Cuándo aplica

Cargada por `workflows/create/phase-1-elicitation.md` y `workflows/create/phase-2-refinement.md` durante la elicitación de un proceso nuevo. También usada por `workflows/edit.md` para elicitación quirúrgica de cambios.

## Modo de uso

### En draft-first (default para create)

1. **Nivel 1 (estructura macro)**: Cargar `elicitation/sections-1-3.md`. Generar draft con objetivo, actores, y 5-7 actividades como conceptos de negocio. Las preguntas de la matrix se usan como guía para el draft, no como interrogatorio.
2. **Nivel 2 (tipos BIZUIT)**: Cargar `elicitation/sections-4-6.md`. Descomponer cada actividad en tipos BIZUIT con detalle técnico. Presentar en grupos de 3-4 actividades. Las preguntas de la matrix guían el refinamiento.
3. **Nivel 3 (edge cases)**: Cargar `elicitation/sections-7-9.md`. Edge cases, NFRs, decisiones pendientes.

### En refinamiento (cuando usuario corrige el draft)

Usar las preguntas de la matrix como guía para profundizar en la sección que el usuario quiere cambiar. Solo preguntar lo que la corrección del usuario no cubrió.

### En edit (elicitación quirúrgica)

Cargar solo la sección relevante al cambio. No re-elicitar secciones no afectadas.

## Reglas de flujo

- **Máximo 3 preguntas consecutivas** sin contexto o confirmación del flujo (NFR15)
- Si el usuario responde **"no sé"** a una pregunta no-bloqueante → marcar WARNING, continuar (FR3)
- Si el usuario responde **"no sé"** a una pregunta bloqueante → explicar por qué importa, sugerir a quién preguntar, marcar como pendiente
- **Guardar progreso** en spec parcial después de cada sección completa (FR4, NFR19)
- **Confirmar estructura** inferida antes de profundizar en detalles (FR5)
- Si el usuario describe algo **fuera de orden** → registrar en el lugar correcto, no forzar orden

## Asunciones BLOCKER (siempre requieren confirmación explícita)

Estas asunciones, si están equivocadas, invalidan el flujo del proceso. Marcar con 🔴 en el draft. No avanzar al siguiente nivel sin confirmación.

1. **Tipo de proceso**: nuevo vs edición de existente
2. **Canal de entrada**: manual (web/mobile) vs automático (scheduler) vs integración (otro proceso)
3. **Acceso a sistemas externos**: bases de datos, APIs de terceros — ¿existen? ¿hay acceso?
4. **Ambiente destino**: producción vs desarrollo/QA

BLOCKERs pueden surgir en cualquier nivel (no solo nivel 1). Cualquier asunción que, si está equivocada, invalida el flujo es un BLOCKER.

## Matriz de relevancia: 15 tipos × 9 secciones

Leyenda: **B** = Bloqueante, **NB** = No bloqueante, **Auto** = Auto-generada (no preguntar), **—** = No aplica.

| Tipo \ Sección | 1. Objetivo | 2. Actores | 3. Journeys | 4. Funcionalidades | 5. Integraciones | 6. Edge Cases | 7. NFRs | 8. Decisiones | 9. Auditoría |
|---|---|---|---|---|---|---|---|---|---|
| **User Task** | — | B | B | B | Auto | NB | NB | NB | Auto |
| **Exclusive Gateway** | — | — | B | NB | Auto | NB | — | NB | Auto |
| **Parallel Gateway** | — | — | B | NB | Auto | NB | NB | — | Auto |
| **SQL Service Task** | — | — | B | B | Auto | B | NB | — | Auto |
| **REST Service Task** | — | — | B | B | Auto | B | NB | — | Auto |
| **Email/Send Task** | — | NB | B | B | Auto | NB | — | — | Auto |
| **Send Message** | — | — | B | NB | Auto | NB | — | NB | Auto |
| **Receive Message** | — | — | B | NB | Auto | NB | NB | — | Auto |
| **Call Activity** | — | — | B | NB | Auto | NB | — | NB | Auto |
| **Timer/Delay** | — | — | B | NB | Auto | NB | NB | — | Auto |
| **For (Iteración)** | — | — | B | NB | Auto | NB | NB | — | Auto |
| **Sequence (Try/Catch)** | — | — | NB | NB | Auto | B | — | — | Auto |
| **Expirable** | — | NB | B | NB | Auto | B | B | — | Auto |
| **Set Parameter** | — | — | NB | NB | Auto | — | — | — | Auto |
| **Exception** | — | — | NB | — | Auto | B | — | — | Auto |

## Sub-archivos

| Archivo | Contenido | Progressive disclosure nivel |
|---------|-----------|----------------------------|
| `elicitation/sections-1-3.md` | Objetivo, Actores, Journeys — preguntas por tipo | Nivel 1: conceptos de negocio |
| `elicitation/sections-4-6.md` | Funcionalidades, Integraciones, Edge Cases — detalles técnicos | Nivel 2: tipos BIZUIT |
| `elicitation/sections-7-9.md` | NFRs, Decisiones, Auditoría + utilidades (orden, inferencia, ejemplo, gotchas) | Nivel 3: edge cases |

## Orden de completedSections

Las secciones se completan en este orden:
1, 2, 3, 4 (elicitadas), 6, 7, 8 (elicitadas)
5 (Integraciones), 9 (Auditoría), Detalle técnico → auto-generadas, no cuentan en completedSections.

`status: "complete"` requiere `completedSections: [1, 2, 3, 4, 6, 7, 8]` (7 secciones elicitadas).

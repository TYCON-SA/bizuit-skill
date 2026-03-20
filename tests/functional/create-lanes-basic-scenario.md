# Functional Test: CREATE con Lanes — Fixture A (3 roles, caso típico)

## Objetivo
Verificar que el workflow CREATE produce BPMN con collaboration/laneSet/lane cuando el usuario acepta lanes. Caso típico: 3 roles, sin RACI.

## Pre-condiciones
- Skill bizuit-sdd v1.5.0+ instalado
- Directorio `processes/` vacío o proceso nuevo

## Pasos

1. **Iniciar skill con frase CREATE:**
   ```
   Quiero crear un proceso de gestión de compras con 3 áreas involucradas
   ```

2. **Responder elicitación guiada:**
   - Nombre: "Gestión de Compras Simple"
   - Objetivo: "Gestionar solicitudes de compra con aprobación"
   - Actores: Solicitante, Aprobador, Sistema
   - Actividades:
     - Crear Solicitud (UserTask, performer: Solicitante)
     - Aprobar Solicitud (UserTask, performer: Aprobador)
     - ¿Aprobado? (Exclusive Gateway)
     - Notificar Resultado (ServiceTask, sin performer)
   - Parámetros: pMontoTotal (decimal)

3. **Aceptar sugerencia de lanes:**
   - [ ] Skill muestra texto canónico: "Detecté **3 roles**..."
   - [ ] Responder "Sí" (o aceptar default)

4. **Confirmar mapping de lanes (Phase 2):**
   - [ ] Skill muestra tabla Performer → Activities
   - [ ] Confirmar mapping
   - [ ] Rechazar RACI (default No)

5. **Verificar spec.md:**
   - [ ] Frontmatter tiene `lanes: true`
   - [ ] Sección "## Lanes" presente con tabla Performer | Activities
   - [ ] Orden: Solicitante (primer UT), Aprobador, Sistema

6. **Solicitar generación BPMN:**
   ```
   Generá el BPMN
   ```

7. **Verificar process.bpmn — Modelo XML:**
   - [ ] `<collaboration id="Collaboration_1">` presente
   - [ ] `<participant id="Participant_1">` con processRef correcto
   - [ ] `<laneSet id="LaneSet_1">` como primer hijo de process
   - [ ] Lane_1 = Solicitante, Lane_2 = Aprobador, Lane_3 = Sistema
   - [ ] Cada lane tiene `bizuit:Performers` matcheando sus tasks
   - [ ] Cada task tiene `bizuit:Performers` matcheando su lane
   - [ ] StartEvent en flowNodeRef de Lane_1 (Solicitante)
   - [ ] Gateway en flowNodeRef de Lane_2 (precedente: Aprobador)
   - [ ] ServiceTask en flowNodeRef de Lane_3 (precedente o Sistema)
   - [ ] EndEvent en flowNodeRef de Lane_3
   - [ ] IDs secuenciales: Lane_1, Lane_2, Lane_3

8. **Verificar process.bpmn — BPMNDI:**
   - [ ] `BPMNPlane bpmnElement="Collaboration_1"` (NO Process)
   - [ ] BPMNShape para Participant_1 con `isHorizontal="true"`
   - [ ] BPMNShape para Lane_1, Lane_2, Lane_3 con `isHorizontal="true"`
   - [ ] Activities dentro de bounds de su lane
   - [ ] Lanes no se superponen
   - [ ] BPMNEdge con waypoints (2 puntos por edge)

9. **Verificar namespace:**
   - [ ] `xmlns:bizuit="http://tycon.com/schema/bpmn/bizuit"` (correcto)
   - [ ] NO contiene `bizuit.com/bpmn/extensions`

10. **Verificar visual output:**
    - [ ] Diagrama Mermaid o texto generado
    - [ ] Nota al pie: "diagrama no muestra la organización por carriles..."

## Golden File
Guardar `process.bpmn` resultante como golden file de referencia para regresión futura.

## Resultado Esperado
- BPMN con collaboration, pool, 3 lanes, BPMNDI completo
- Namespace correcto
- Spec con sección Lanes
- Visual con nota de lanes

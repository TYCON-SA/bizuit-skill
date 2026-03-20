# Functional Test: CREATE sin Lanes — Regresión (Fixture C)

## Objetivo
Verificar que procesos SIN lanes siguen generándose correctamente post-Epic 15. Output idéntico al pre-Epic 15 excepto namespace fix.

## Pre-condiciones
- Skill bizuit-sdd v1.5.0+ instalado
- Golden file pre-Epic 15 disponible (proceso-compras existente como referencia)

## Golden File de Referencia
Usar `processes/arielsch/proceso-compras/process.bpmn` como referencia pre-Epic 15. Las únicas diferencias esperadas son:
- `xmlns:bizuit` → cambiado de `bizuit.com/bpmn/extensions` a `tycon.com/schema/bpmn/bizuit`
- `targetNamespace` → cambiado de `bizuit.com/bpmn` a `tycon.com/schema/bpmn`

Cualquier OTRA diferencia es regresión y bloquea el release.

## Pasos

1. **Iniciar skill con frase CREATE (proceso simple, 1-2 roles):**
   ```
   Crear un proceso simple de registro con 1 actor
   ```

2. **Responder elicitación:**
   - Nombre: "Registro Simple"
   - 1 actor: "Operador"
   - 3 actividades simples

3. **Verificar que NO se pregunta por lanes:**
   - [ ] 1 solo actor → skill NO muestra sugerencia de lanes
   - [ ] Frontmatter tiene `lanes: false` (automático)

4. **Generar BPMN:**

5. **Verificar process.bpmn SIN lanes:**
   - [ ] NO contiene `<collaboration>`
   - [ ] NO contiene `<participant>`
   - [ ] NO contiene `<laneSet>`
   - [ ] NO contiene `<lane>`
   - [ ] `BPMNPlane bpmnElement` apunta al Process (NO Collaboration)
   - [ ] Namespace correcto: `http://tycon.com/schema/bpmn/bizuit`
   - [ ] `lanes-structure.md` NO fue cargado

6. **Verificar spec.md SIN sección Lanes:**
   - [ ] NO contiene sección "## Lanes"
   - [ ] `lanes: false` en frontmatter

7. **Verificar tests existentes:**
   - [ ] reverse-scenario.md sigue pasando
   - [ ] validate-scenario.md sigue pasando
   - [ ] query-scenario.md sigue pasando
   - [ ] edit-scenario.md sigue pasando
   - [ ] create-scenario.md sigue pasando (excepto namespace diff)
   - [ ] bizuit-forms-scenario.md sigue pasando

## Resultado Esperado
- BPMN plano idéntico al pre-Epic 15 (excepto namespace fix)
- Sin sección Lanes en spec
- Sin preguntas de lanes
- Todos los tests existentes PASS

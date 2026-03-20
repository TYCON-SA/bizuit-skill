# Functional Test: CREATE con Lanes — Fixture B (5 roles + RACI + acentos)

## Objetivo
Verificar lanes con caso complejo: 5 roles, RACI completo, performers con acentos, 10+ tasks.

## Pre-condiciones
- Skill bizuit-sdd v1.5.0+ instalado
- Fixture A completado (golden file disponible)

## Pasos

1. **Iniciar skill con frase CREATE:**
   ```
   Crear proceso de gestión de incidentes con 5 áreas y roles RACI
   ```

2. **Responder elicitación guiada:**
   - Nombre: "Gestión de Incidentes"
   - Actores: Mesa de Ayuda, Técnico Nivel 1, Técnico Nivel 2, José García (Supervisor), Sistemas
   - 10+ actividades distribuidas entre los 5 roles
   - Incluir al menos 2 gateways (1 diverging, 1 converging/merge)

3. **Aceptar lanes y RACI:**
   - [ ] Aceptar sugerencia de lanes (5 roles)
   - [ ] Aceptar RACI: definir Accountable y Consulted para al menos 2 lanes

4. **Verificar spec.md:**
   - [ ] `lanes: true` en frontmatter
   - [ ] Sección Lanes con 5 performers
   - [ ] Subtabla RACI presente con Accountable/Consulted definidos
   - [ ] "José García" con acentos preservados

5. **Verificar process.bpmn:**
   - [ ] 5 lanes (Lane_1 a Lane_5, secuenciales)
   - [ ] RACI: lanes con `bizuit:Accountable`, `bizuit:Consulted`
   - [ ] "José García" preservado con acentos en XML (UTF-8)
   - [ ] Merge gateway en lane de primera entrada
   - [ ] Todos los flowNodeRef presentes (0 huérfanos)
   - [ ] BPMNDI completo con 5 lane shapes

6. **Verificar caracteres especiales:**
   - [ ] Si algún performer tiene "&" → escapado como `&amp;` en XML

## Golden File
Guardar como golden file Fixture B.

## Resultado Esperado
- BPMN con 5 lanes, RACI attrs, acentos preservados, merge gateway correcto

# Functional Test: BizuitForms Generation (Epic 9)

## Objetivo
Verificar que forms generados matchean estructura del fixture `procesoconforms_v1.bpmn`.

## Pre-condiciones
- Fixture `tests/fixtures/procesoconforms_v1.bpmn` disponible
- Fixture `tests/fixtures/procesoconforms.vdw` disponible
- Skill instalado con rules de form generation

## Pasos

1. **Reverse del fixture VDW:**
   - Ejecutar reverse sobre `procesoconforms.vdw`
   - Obtener spec.md con parámetros y actividades

2. **CREATE con parámetros similares:**
   - Crear proceso nuevo con mismos parámetros y actividades del fixture
   - Generar BPMN con forms

3. **Extraer forms del BPMN generado:**
   - Buscar `bizuit:serializedForm` en cada UserTask
   - HTML decode → JSON parse → JSON parse controls/dataSources

4. **Comparar estructura vs fixture:**
   - [ ] Misma cantidad de controles por form
   - [ ] Mismos tipos de control (class names: InputTextboxComponent, CheckboxComponent, etc.)
   - [ ] Primary DataSource con paths correctos (`Instance.{paramName}`)
   - [ ] Actividades Anteriores presentes en UserTasks (no en StartEvent)
   - [ ] `layerIndex: 1` en todos los controles
   - [ ] `class` como primer campo en property objects
   - [ ] MainFormComponent como control raiz
   - [ ] Botones Enviar + Cancelar presentes

5. **Documentar diferencias aceptables:**
   - `formId`: 0 en generado vs server-assigned en fixture
   - `createdDate`/`updatedDate`: timestamps diferentes
   - `createdUser`: diferente
   - Orden de properties dentro de objetos JSON
   - IDs de controles pueden diferir

## Resultado esperado
- Structural match entre forms generados y fixture
- Diferencias solo en IDs, timestamps, formId

## Assertion de métricas
- >= 90% de controles matchean en tipo y estructura
- 0 controles faltantes vs fixture (excepto SeparatorComponent/HiddenFieldComponent que son excluidos intencionalmente)

# Test Fixtures

## procesoconforms_v1.bpmn

BPMN XML exportado post-persist desde el editor BIZUIT. Los valores `formId` fueron asignados por el servidor (non-zero). Los forms generados por el skill producen `formId=0` como placeholder hasta que se persisten.

**NO comparar formId en tests.**

## procesoconforms.vdw

VDW (Visual Design Workflow) XML del mismo proceso. Formato propietario BIZUIT. Los `formId` en el VDW son server-assigned. Al hacer reverse, el skill extrae la estructura del form pero los IDs pueden no coincidir con los generados por create.

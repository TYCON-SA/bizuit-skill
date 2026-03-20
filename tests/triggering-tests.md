# Triggering Tests — bizuit-sdd

> **NOTA:** La columna 'Post v1.2.0' se completa manualmente en una sesion separada de Claude para evitar bias del implementador. Ver story 10.1 Tarea 5.

> Scenarios para verificar que el skill se activa (o no) correctamente.
> Threshold: >=80% de positivos deben triggear correctamente.

## Scenarios Positivos

| # | Frase | Intent esperado | Workflow | Baseline v1.1.0 | Post v1.2.0 |
|---|-------|----------------|----------|-----------------|-------------|
| 1 | "Quiero crear un proceso de aprobación de compras" | CREATE | create.md | triggered | |
| 2 | "Definime un proceso nuevo de onboarding" | CREATE | create.md | | |
| 3 | "Documentá el proceso EQV" | REVERSE | reverse.md | triggered | |
| 4 | "Analizá qué hace el proceso de ventas en BIZUIT" | REVERSE | reverse.md | | |
| 5 | "Explicame el proceso de soporte" | QUERY | query.md | triggered | |
| 6 | "¿Cómo funciona el proceso de compras?" | QUERY | query.md | | |
| 7 | "Necesito modificar el proceso de soporte" | EDIT | edit.md | triggered | |
| 8 | "Agregá una actividad al proceso de ventas" | EDIT | edit.md | | |
| 9 | "Revisá si la spec está completa" | VALIDATE | validate.md | triggered | |
| 10 | "Verificá el proceso de onboarding" | VALIDATE | validate.md | | |
| 11 | "Generá los formularios React del proceso" | GENERATE FORMS | generate-forms.md | | |
| 12 | "Creá el proceso con formularios incluidos" | CREATE | create.md (BizuitForms) | | |

## Scenarios Negativos

| # | Frase | Resultado esperado |
|---|-------|--------------------|
| 1 | "¿Qué hora es?" | NOT triggered |
| 2 | "Ayudame a escribir un email" | NOT triggered |
| 3 | "Hacé un diagrama de flujo genérico" | NOT triggered |
| 4 | "Creame un proceso en Camunda" | NOT triggered |
| 5 | "Documentá este código Python" | NOT triggered |
| 6 | "Crear componente React para login" | NOT triggered |
| 7 | "Editar package.json del proyecto" | NOT triggered |

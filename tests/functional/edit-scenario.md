# Functional Test: EDIT Workflow

## Objetivo
Verificar que EDIT modifica spec existente y re-genera BPMN preservando IDs.

## Pre-condiciones
- spec.md + process.bpmn existentes (proceso Published o SpecWithBPMN)
- Skill instalado

## Pasos
1. Iniciar con: "Necesito agregar una actividad al proceso de aprobación"
2. Verificar drift check (spec vs BPMN)
3. Agregar actividad via elicitación quirúrgica
4. Verificar que spec.md se actualiza (nueva actividad)
5. Re-generar BPMN y verificar que IDs originales se preservan

## Resultado esperado
- spec.md actualizada con nueva actividad
- process.bpmn re-generado con IDs originales preservados

> Stub — expandir en futuras épicas

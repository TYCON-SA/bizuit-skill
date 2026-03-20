# Functional Test: VALIDATE Workflow

## Objetivo
Verificar que VALIDATE ejecuta completeness checklist sobre spec.md.

## Pre-condiciones
- spec.md existente (puede ser parcial o completa)
- Skill instalado

## Pasos
1. Iniciar con: "Validá la spec del proceso de aprobación"
2. Verificar que carga completeness-checklist.md
3. Verificar que reporta BLOCKERs y WARNINGs
4. Verificar formato de output (emoji + conteo)
5. Si spec completa: verificar "Spec lista para generar BPMN"

## Resultado esperado
- Reporte con BLOCKERs, WARNINGs, items OK
- No modifica archivos (read-only)

> Stub — expandir en futuras épicas

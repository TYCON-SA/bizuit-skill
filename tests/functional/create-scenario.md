# Functional Test: CREATE Workflow

## Objetivo
Verificar que el workflow CREATE produce spec.md valida con forms BizuitForms embebidos en BPMN.

## Pre-condiciones
- Skill bizuit-sdd instalado y funcional
- Directorio `processes/` vacio o proceso nuevo (sin spec previa)
- No se requieren credenciales BIZUIT (create es local)

## Pasos

1. **Iniciar skill con frase CREATE:**
   ```
   Quiero crear un proceso de aprobación de compras con 3 actividades
   ```

2. **Responder elicitación guiada:**
   - Nombre: "Aprobación de Compras"
   - Objetivo: "Gestionar aprobaciones de órdenes de compra"
   - Actores: Solicitante, Aprobador, Administrador
   - Actividades: Crear Solicitud (UserTask), Aprobar Solicitud (UserTask), Registrar Compra (ServiceTask SQL)
   - Parámetros: pMontoTotal (decimal), pDescripcion (string), pAprobado (boolean)

3. **Verificar spec.md:**
   - [ ] Archivo creado en `processes/{org}/aprobacion-de-compras/spec.md`
   - [ ] Frontmatter YAML valido con `status: complete`
   - [ ] 9 secciones del formato spec v2.1

4. **Solicitar generación BPMN:**
   ```
   Generá el BPMN
   ```

5. **Verificar process.bpmn:**
   - [ ] Archivo creado en `processes/{org}/aprobacion-de-compras/process.bpmn`
   - [ ] XML valido con namespaces BIZUIT
   - [ ] 3 actividades + StartEvent + EndEvent
   - [ ] UserTasks contienen `bizuit:serializedForm`
   - [ ] Forms tienen MainFormComponent + controles
   - [ ] IDs siguen convención: `UserTask_CrearSolicitud`, etc.

## Resultado esperado
- `spec.md` completa con 9 secciones
- `process.bpmn` con BPMN XML valido y BizuitForms embebidos
- Controles de form matchean tipos de parámetros (decimal→InputTextbox, boolean→Checkbox)

## Verificación post-ejecución
- [ ] `grep "bizuit:serializedForm" process.bpmn` retorna hits
- [ ] `grep "MainFormComponent" process.bpmn` retorna hits (HTML-encoded)
- [ ] Frontmatter spec tiene `specFormatVersion: "2.1"`

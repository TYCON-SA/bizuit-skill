# Functional Test: REVERSE Workflow

## Objetivo
Verificar que REVERSE produce spec.md + resumen-ejecutivo.md desde VDW.

## Pre-condiciones
- Skill bizuit-sdd instalado
- Acceso a BIZUIT API con credenciales validas, O fixture local disponible

## Pasos (Plan A — proceso real)

1. **Iniciar skill con frase REVERSE:**
   ```
   Documentá el proceso procesoconforms que tenemos en BIZUIT
   ```

2. **Proveer credenciales si se piden** (wizard inline de api-auth.md)

3. **Verificar descarga VDW:**
   - [ ] `vdw-original.xml` guardado en directorio del proceso

4. **Verificar spec.md generada:**
   - [ ] 9 secciones completas
   - [ ] Actividades parseadas correctamente (nombres, tipos)
   - [ ] Parámetros extraidos del VDW

5. **Verificar resumen-ejecutivo.md:**
   - [ ] Archivo creado
   - [ ] Resumen legible para Process Owner

6. **Verificar frontmatter:**
   - [ ] `status: complete`
   - [ ] `processName` correcto
   - [ ] `logicalProcessId` si aplica

## Pasos (Plan B — fallback fixtures)

1. Copiar `tests/fixtures/procesoconforms.vdw` al directorio del proceso como `vdw-original.xml`
2. Ejecutar reverse sobre el fixture
3. Verificar mismos items que Plan A

## Resultado esperado
- spec.md + resumen-ejecutivo.md + vdw-original.xml en directorio del proceso

## Verificación
- [ ] spec.md tiene 9 secciones
- [ ] Actividades del VDW reflejadas en spec
- [ ] resumen-ejecutivo.md existe y es legible

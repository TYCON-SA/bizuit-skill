# Generate Forms Workflow

Genera componentes React (.tsx) para cada UserTask de un proceso BIZUIT a partir de su spec.

**Self-contained**: este workflow NO carga rules de `rules/`. Lee spec.md + detalle-tecnico.md directamente.

---

## SDK Reference

API del SDK de BIZUIT Forms usada en los templates generados:

| Export | Package | Uso |
|--------|---------|-----|
| `DynamicFormField` | `@tyconsa/bizuit-ui-components` | Auto-renderiza campo por `parameter.type` (string→text, number→number, bool→checkbox, date→datepicker) |
| `Button` | `@tyconsa/bizuit-ui-components` | Botón con variants: default, outline, secondary, destructive, ghost |
| `useBizuitAuth()` | `@tyconsa/bizuit-ui-components` | Hook que provee `{ token }` del contexto de auth |
| `useBizuitSDK()` | `@tyconsa/bizuit-form-sdk` | Hook que provee instancia SDK con `sdk.process.*` |
| `filterFormParameters()` | `@tyconsa/bizuit-form-sdk` | Filtra params para START: excluye system, variables, output-only |
| `filterContinueParameters()` | `@tyconsa/bizuit-form-sdk` | Filtra params para CONTINUE: incluye variables |
| `formDataToParameters()` | `@tyconsa/bizuit-form-sdk` | Convierte `Record<string, any>` → `IParameter[]` para API |
| `loadInstanceDataForContinue()` | `@tyconsa/bizuit-form-sdk` | Carga datos de instancia + lock opcional |
| `releaseInstanceLock()` | `@tyconsa/bizuit-form-sdk` | Libera lock de instancia |
| `IBizuitProcessParameter` | `@tyconsa/bizuit-form-sdk` | Tipo: `{ name, type, parameterDirection (1=In, 2=Out, 3=Optional), isSystemParameter, isVariable }` |

**Tipos complejos no cubiertos por DynamicFormField** (generan TODO):

| Tipo en spec | Componente recomendado | TODO generado |
|---|---|---|
| selección, combo | `BizuitCombo` | `{/* TODO: Reemplazar DynamicFormField por BizuitCombo para {param} */}` |
| archivo, adjunto | `BizuitFileUpload` | `{/* TODO: Configurar BizuitFileUpload — accept, maxSize */}` |
| firma | `BizuitSignature` | `{/* TODO: Reemplazar por BizuitSignature */}` |
| ubicación, GPS | `BizuitGeolocation` | `{/* TODO: Reemplazar por BizuitGeolocation */}` |
| subformulario | `BizuitSubForm` | `{/* TODO: Reemplazar por BizuitSubForm con schema */}` |
| grilla, tabla editable | `BizuitDataGrid` | `{/* TODO: Reemplazar por BizuitDataGrid con columnas */}` |
| XML complejo | (editor custom) | `{/* TODO: Implementar editor XML para {param} */}` |
| maxLength/minLength/pattern | (atributo manual) | `{/* TODO: Agregar {atributo}={valor} — DynamicFormField no lo soporta */}` |

---

## Precondiciones

Antes de generar, validar en este orden (primera que falla, detener):

1. **¿Existe spec.md?** → No: "Primero creá o documentá el proceso."
2. **¿Status: partial?** → Sí: "La spec no está completa. Completá la creación antes de generar forms."
3. **¿Hay UserTasks parseables?** → No: "No pude parsear UserTasks de esta spec. Verificá que usa specFormatVersion 2.1+."
4. **¿Hay al menos 1 UserTask con campos o acciones?** → No: "Este proceso es automatizado, no tiene formularios."
5. **¿Ya existen forms/?** → Sí: backup a `.backup-{ISO timestamp}/`, confirmar overwrite.
6. **¿Filesystem disponible?** → No: "Generación de forms requiere filesystem. Usá Claude Code CLI."

---

## Parsing de UserTasks

1. Leer `spec.md` frontmatter: `processName`, `source`, `specFormatVersion`, `org`, `slug`
2. Buscar UserTasks en **sección 4 (Funcionalidades)**: filas con tipo "UserTask" o "Tarea humana"
3. Si existe `detalle-tecnico.md` → buscar bloques `### UserTask: {nombre}` o `### {nombre} (UserTask)`
4. Si no existe `detalle-tecnico.md` (spec v2.0 inline) → extraer de spec.md directamente
5. Si no hay datos suficientes → "No se encontraron detalles de UserTasks. Ejecutá reverse o completá detalle-tecnico.md."

**Para cada UserTask extraer:**
- `displayName`: nombre visible (del heading)
- `activityName`: nombre técnico (del campo técnico si existe, sino sanitizar displayName)
- `campos`: tabla de parámetros (nombre, tipo, dirección)
- `acciones`: transiciones/eventos (Aprobar, Rechazar, etc.)
- `validaciones`: reglas de negocio (texto libre)
- `tiposComplejos`: campos que necesitan componente específico (combo, archivo, etc.)

**Naming**: PascalCase del displayName sanitizado. Eliminar acentos, chars especiales, espacios. Ej: "Registrar Solicitud de Soporte" → `RegistrarSolicitudDeSoporte`. La función usa el mismo nombre + `Form`.

**Identificar START**: buscar marcador `[START]` en heading de UserTask. Si no hay marcador → asumir primera UserTask listada + warning en header. Si proceso arranca por timer/evento → todas son CONTINUE.

---

## Instrucciones de generación

### Paso 1: Generar hooks.ts (Pattern 13d)

Generar `forms/hooks.ts` con el custom hook `useBizuitForm()` que encapsula:
- Carga de params (START: `getParameters` + `filterFormParameters`) o instancia (CONTINUE: `loadInstanceDataForContinue` + `filterContinueParameters`)
- `AbortController` para React 18 StrictMode
- Lock acquire en mount + release en unmount (CONTINUE)
- `validateRequired()`: verifica `parameterDirection === 1 && !isVariable` antes de API call
- `submitStart(files?)`: `formDataToParameters` → `sdk.process.start()`
- `submitAction(eventName, files?)`: `formDataToParameters` → `sdk.process.raiseEvent()`
- States: `'idle' | 'loading' | 'ready' | 'submitting' | 'success' | 'error' | 'locked'`

El hook completo tiene ~130 líneas. Ver template de referencia en `docs/elicitacion/rondas-story-7.2-party-mode-sintesis.md` (Ronda 40).

### Paso 2: Generar types.ts (Pattern 13c)

```typescript
// Header: processSlug, fecha ISO, specFormatVersion, "código generado"
export type { IBizuitProcessParameter, IParameter, IProcessResult } from '@tyconsa/bizuit-form-sdk'
export const PROCESS_NAME = '{slug}' as const
export const ACTIVITIES = { {Key1}: '{activityName1}', ... } as const
export const EVENTS = { {Key2}: ['{evento1}', '{evento2}'], ... } as const
export type ActivityName = keyof typeof ACTIVITIES
export type EventName<A extends ActivityName> = typeof EVENTS[A][number]
```

- ACTIVITIES incluye TODAS las UserTasks (incluyendo START como diccionario completo)
- EVENTS excluye la START (usa `start()`, no `raiseEvent()`)
- Si CONTINUE no tiene eventos en spec → `EVENTS.{Key} = ['Completar']` + TODO

### Paso 3: Generar {ActivityName}.tsx (Pattern 13a o 13b)

**Header de todo .tsx:**
```tsx
// Generado por bizuit-sdd desde spec '{slug}'
// Fecha: {ISO} | specFormatVersion: {version}
// Fuente: {source} ({disclaimer})
// Requiere: npm install @tyconsa/bizuit-form-sdk@^1.0.0 @tyconsa/bizuit-ui-components@^1.0.0
// Este componente requiere BizuitSDKProvider + BizuitAuthProvider en un layout padre
// Campos esperados (según spec): {lista de campos}
'use client'
```

**START (Pattern 13a)**: `useBizuitForm({mode:'start'})` → `submitStart()`. 1 botón submit.

**CONTINUE (Pattern 13b)**: `useBizuitForm({mode:'continue', activityName, instanceId})` → N botones con `submitAction(event)`. Maneja `status === 'locked'`. DynamicFormField incluye `showVariableLabel={true}` para mostrar labels de variables pre-cargadas de la instancia.

**CONTINUE sin campos (solo acciones, AC9)**: Si la UserTask no tiene campos de datos (solo acciones como Aprobar/Rechazar), generar form sin DynamicFormField — solo botones de acción. Comment: `// Form de aprobación — solo acciones, sin campos de datos`.

**Reglas comunes:**
- `<form aria-label="{displayName}">`
- Loading/error/success con `role="status"` o `role="alert"`
- Botones con `type` explícito, `disabled` y `aria-busy` durante submit
- TODOs para validaciones de negocio antes del bloque de botones
- TODOs para campos complejos (ver tabla SDK Reference)
- Si >10 campos → TODO: "Considerar refactorizar state management"

### Paso 4: Generar index.ts

```typescript
export { {Activity1}Form } from './{Activity1}Form'
export { {Activity2}Form } from './{Activity2}Form'
export * from './types'
// hooks.ts NO se exporta (detalle de implementación interno)
```

### Paso 5: Resumen

Mostrar al usuario:
```
✅ Forms generados en processes/{org}/{slug}/forms/
   - hooks.ts (lógica compartida)
   - types.ts ({N} actividades, {M} eventos)
   - {lista de .tsx} ({startCount} START + {continueCount} CONTINUE)
   - index.ts (barrel export)

⚠️ Requiere: npm install @tyconsa/bizuit-form-sdk@^1.0.0 @tyconsa/bizuit-ui-components@^1.0.0
⚠️ Requiere: BizuitSDKProvider + BizuitAuthProvider en layout padre
```

Si `source === 'create'`:
```
⚠️ Fuente: create — los campos pueden diferir de la implementación real. Verificá contra BIZUIT.
```

Si hay campos complejos detectados:
```
⚠️ {N} campos complejos detectados (combo, archivo, etc.). Revisar TODOs en los .tsx generados.
```

---

## Regeneración

Si `forms/` ya existe:
1. Crear backup: `forms/.backup-{ISO timestamp}/` con TODOS los archivos del directorio
2. Mostrar: "Backup creado en .backup-{timestamp}/. ¿Sobreescribir forms?"
3. Si confirma → sobreescribir SOLO archivos del skill (hooks.ts, types.ts, *.tsx de UserTasks, index.ts). Archivos custom del dev se preservan.
4. Si rechaza → cancelar, backup queda para referencia.

Si un .tsx existente no corresponde a ningún UserTask actual (renombrado): warning "Se encontró {old}.tsx que no corresponde a ningún UserTask actual. ¿Eliminar?"

---

## Disclaimers de fidelidad por source

| Source | Disclaimer |
|--------|------------|
| `reverse` | `// Fuente: reverse (alta fidelidad — campos del VDW)` |
| `create` | `// Fuente: create (verificar campos contra implementación real)` |
| `edit` | `// Fuente: edit (campos pueden haber cambiado — verificar)` |

# Surgical Elicitation — Edit Changes

> Elicitación quirúrgica: solo preguntar lo que cambia, no re-elicitar todo.
> Invocada por `workflows/edit.md` (story 5.5) como Step 3, después del drift check.
> Reutiliza `elicitation-by-section.md` para preguntas por tipo — no re-implementa.

## Cuándo aplica

Cargada durante el flujo EDIT después del drift check (story 5.1). El usuario describe el delta; el skill actualiza la spec sin re-preguntar lo existente.

## Flujo principal

```
1. Leer spec.md completa como contexto base
2. Presentar resumen corto: "{N} actividades, {J} journeys, {G} gateways"
3. Preguntar: "¿Qué querés cambiar?"
4. Parsear el intent del cambio
5. Ejecutar la acción correspondiente
6. Guardar spec a disco (por-respuesta, como en create)
7. Preguntar: "¿Hay algo más que querés cambiar?"
8. Repetir 3-7 hasta que diga "no, eso es todo"
9. Mostrar resumen de cambios aplicados
```

## Tipos de cambio soportados

### 1. Agregar actividad

**Intent:** "agregar", "insertar", "necesito un paso nuevo"

**Flujo:**
1. Preguntar dónde insertarla: "¿Entre qué actividades va?"
2. Preguntar tipo (o inferir de la descripción, como en create)
3. Consultar `elicitation-by-section.md` para preguntas del tipo (misma lógica que Paso 4b de create)
4. Solo preguntar atributos de la nueva actividad — NO re-elicitar las existentes
5. Generar ID determinístico: `{Type}_{SlugifiedName}` (no tiene originalId — es nueva)
6. Insertar en spec en la posición correcta
7. Actualizar numeración y sequence en journeys afectados
8. Actualizar detalle-tecnico.md con bloque `#### detalle-{xname}` nuevo

### 2. Eliminar actividad

**Intent:** "sacar", "eliminar", "quitar", "no necesito más"

**Flujo:**
1. Identificar la actividad a eliminar
2. **Si tiene originalId** (proceso was reverse-engineered o published):
   ```
   "La actividad '{nombre}' tiene ID original '{originalId}'.
    Si tiene un formulario bindeado en BIZUIT, ese form quedará huérfano.
    ¿Confirmar eliminación?"
   ```
3. Si tiene dependencias (usada en gateways, referenciada por otros):
   ```
   "'{nombre}' es referenciada por:
    - Gateway '{gatewayName}' (condición sobre su output)
    - Email '{emailName}' (usa su parámetro de salida)
    ¿Confirmar eliminación? Las referencias quedarán rotas."
   ```
4. Si el usuario confirma → eliminar de spec, actualizar journeys, registrar nota:
   ```
   "Actividad '{nombre}' eliminada (ex ID: {originalId})"
   ```
5. Actualizar detalle-tecnico.md: remover bloque `#### detalle-{xname}`

### 3. Modificar actividad existente

**Intent:** "cambiar", "modificar", "actualizar", "el paso X ahora hace Y"

**Flujo:**
1. Identificar la actividad y el atributo a cambiar
2. Mostrar valor actual y pedir confirmación:
   ```
   "El valor actual de '{atributo}' en '{nombre}' es '{valorActual}'.
    ¿Confirmar cambio a '{valorNuevo}'?"
   ```
3. Si el cambio afecta otras actividades → advertir:
   ```
   "Este cambio afecta a {N} actividades que usan '{atributo}'."
   ```
4. Actualizar spec + detalle-tecnico.md

### 4. Cambiar condición de gateway

**Intent:** "cambiar la condición", "modificar el umbral", "ahora el límite es"

**Flujo:**
1. Identificar el gateway y la condición
2. Mostrar condición actual:
   ```
   "La condición actual es: pMonto > 10000. ¿Cambiar a?"
   ```
3. Si el valor era hardcoded y se detecta anti-pattern → sugerir parametrizar
4. Actualizar la condición en la spec y en el detalle-tecnico.md

### 5. Agregar/modificar parámetro

**Intent:** "agregar parámetro", "cambiar tipo de", "nuevo input"

**Flujo:**
1. Si agrega: nombre, tipo, dirección (Input/Output/Variable)
2. Si modifica tipo: verificar impacto en actividades que lo usan
   ```
   "pMonto es usado en {N} actividades como {tipo actual}. Cambiar a {tipo nuevo} podría romper:
    - Gateway: comparación numérica
    - SQL: input mapping
    ¿Confirmar?"
   ```
3. Actualizar sección Parámetros en spec.md

### 6. Modificar formulario

**Intent:** "agregar campo al form", "cambiar el formulario de", "nuevo botón"

**Flujo:**
1. Identificar el User Task y su form
2. Preguntar el cambio específico (campo nuevo, campo eliminado, validación nueva)
3. Actualizar la sección Form en spec.md y detalle-tecnico.md
4. Preservar formId == activityId

### 7. Cambiar nombre del proceso

**Intent:** "renombrar proceso", "cambiar el nombre a"

**Flujo:**
1. Actualizar `processName` en frontmatter
2. Advertir: "Si el proceso ya fue persistido, el nombre en BIZUIT no cambia automáticamente."

## Preservación de IDs (FR32)

**Regla critica:** Cuando se renombra o modifica una actividad existente que tiene `originalId` en el frontmatter:

- **Preservar el key nativo del VDW** (`handleActivity5`, etc.)
- **Solo actualizar el display name** en el mapa
- El BPMN re-generado usará el ID original del mapa, no el determinístico

```yaml
# Antes del rename
originalIds:
  handleActivity5: "Aprobar Jefe"

# Después del rename
originalIds:
  handleActivity5: "Aprobar Supervisor"  # key preservada, display actualizado
```

**Actividades NUEVAS** (sin originalId) → ID determinístico `{Type}_{SlugifiedName}`. No se agregan a originalIds.

**Advertencia al renombrar:**
```
"Renombrado '{viejo}' → '{nuevo}'. El BPMN usará el ID original '{originalId}'
 para que los formularios existentes sigan funcionando."
```

## Detección de impacto cruzado

Antes de aplicar un cambio, verificar si afecta otras partes de la spec:

| Cambio | Verificar impacto en |
|---|---|
| Eliminar actividad | Gateways que la referencian, Emails que usan sus outputs, Journeys que la incluyen |
| Cambiar tipo de parámetro | Gateways con condiciones, SQL/REST input mappings, Form fields |
| Modificar condición de gateway | Journeys y ACs que la referencian |
| Eliminar parámetro | Actividades que lo usan como input |
| Renombrar actividad | Journeys, funcionalidades, detalle-tecnico.md links |

## Detección de cambios prohibidos

| Cambio | Detección | Respuesta |
|---|---|---|
| Agregar loop | "vuelve a", "regresa a" | Misma respuesta que create (Paso 4d) |
| Nombre duplicado | Set de nombres existentes | "Ya existe '{nombre}'" |
| Eliminar última actividad | 0 actividades restantes | "No podés eliminar todas las actividades" |

## Múltiples cambios

El usuario puede pedir varios cambios en una sesión. Procesarlos secuencialmente:
1. Elicitar y aplicar cambio 1 → guardar spec
2. Confirmar y aplicar cambio 2 → guardar spec
3. ...
4. "¿Hay algo más?" → "No, eso es todo"
5. Resumen: "Aplicados {N} cambios. ¿Generamos el nuevo BPMN?"

## Gotchas

- NO re-preguntar lo existente — solo lo que cambia
- Consultar `elicitation-by-section.md` para preguntas de tipos — misma fuente que create
- Guardar spec a disco después de CADA cambio (NFR19)
- Los originalIds NUNCA se eliminan del mapa — solo se actualizan display names
- Actividades nuevas NO se agregan a originalIds (no tienen ID nativo de VDW)
- Si el usuario describe un cambio ambiguo → pedir clarificación antes de actuar
- El número de preguntas por cambio depende del tipo: UserTask simple 3-4, SQL/REST 5-6

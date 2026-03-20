# Phase 2: Refinamiento (Secciones 4-8 + Forms)

> Extraído de create.md monolítico (Pasos 5b-9). Refactoring puro — zero cambios funcionales.
> Story 6.7 reescribirá este archivo con progressive disclosure niveles 2-3.
> Nota: 575 líneas — supera el límite de 500. Se reducirá en 6.7 al shardear elicitation.

## Rules que esta fase carga

1. `rules/sdd/elicitation-by-section.md` — preguntas por tipo × sección (Secciones 4-8)
2. `rules/bizuit/common/activity-types.md` — 15 tipos de actividad
3. `rules/bizuit/common/activity-defaults.md` — defaults vacíos por tipo

## Precondiciones

- Spec existe con completedSections incluyendo [1, 2, 3] (secciones macro completas)
- O: draftedSections tiene items (forward-compatible para story 6.7 draft-first)

## Instrucciones

### Paso 5b — Sección 4: Funcionalidades (detalles técnicos por tipo)

Recorrer las actividades identificadas en Sección 3 y elicitar los **atributos técnicos** de cada una según su tipo. Consultar `elicitation-by-section.md` Sección 4 para preguntas específicas.

**Regla clave:** Las preguntas son en **lenguaje de negocio**. El skill traduce internamente a atributos BPMN. El analista no necesita saber qué es un `CommandText` o un `restVerb`.

**Orden de elicitación:** Recorrer actividades en el orden del happy path primero, luego caminos alternativos. Agrupar por tipo cuando hay varias del mismo tipo (ej: todas las SQL juntas).

#### 5b.1 — SQL Service Task (atributos técnicos)

Para cada actividad SQL identificada:

| # | Pregunta | Atributo BPMN | Bloqueante |
|---|----------|---------------|------------|
| 1 | "¿A qué base de datos se conecta '{nombre}'? (ej: nombre de la conexión en el config)" | ConfigFileCnnStringName | No — se puede dejar como placeholder |
| 2 | "¿Qué hace exactamente? ¿Consulta datos, inserta, actualiza, o ejecuta un stored procedure?" | CommandType + Operación | **SÍ** |
| 3 | Si consulta: "¿Qué datos necesita como input? ¿Y qué devuelve?" | Input/Output mappings | **SÍ** |
| 4 | Si SP: "¿Cómo se llama el stored procedure?" | CommandText | **SÍ** |
| 5 | Si query: "¿Podés describir la consulta o pegarla directamente?" | CommandText | No — placeholder OK |
| 6 | "¿Devuelve un dato solo (ej: un conteo), un conjunto de filas, o no devuelve nada?" | ReturnType (Scalar/DataSet/NonQuery) | **SÍ** |
| 7 | "¿Tiene timeout? ¿Cuánto?" | CommandTimeout | No — default 30s |

**Si la query tiene más de 5 líneas** → preguntar: "¿Preferís pegarla directamente o describir lo que necesitás para que quede como placeholder?"

**Ejemplo:**
```
Skill: "La actividad 'Verificar Stock' es SQL. ¿A qué base de datos se conecta?"
User:  "A la base de inventario, conexión InventarioDB"
Skill: "¿Qué hace? ¿Consulta, inserta, actualiza, o ejecuta un SP?"
User:  "Consulta si hay stock del producto"
Skill: "¿Qué datos necesita? ¿Y qué devuelve?"
User:  "Necesita el código de producto, devuelve la cantidad disponible"
Skill: "¿Devuelve un dato solo (cantidad) o un conjunto de filas?"
User:  "Un dato solo"
```
→ Registra: SQL, ConnectionString="InventarioDB", CommandType="Text", ReturnType="Scalar", Input=codigoProducto, Output=cantidadDisponible

#### 5b.2 — REST Service Task (atributos técnicos)

Para cada actividad REST identificada:

| # | Pregunta | Atributo BPMN | Bloqueante |
|---|----------|---------------|------------|
| 1 | "¿Cuál es la URL del servicio? ¿Es fija o varía por ambiente?" | restUrl | No — placeholder OK |
| 2 | "¿Qué operación hace? ¿Consultar (GET), enviar (POST), actualizar (PUT), o eliminar (DELETE)?" | restVerb | **SÍ** |
| 3 | "¿Qué datos le envía?" | restBody / input mappings | **SÍ** (si POST/PUT) |
| 4 | "¿Qué devuelve?" | output mappings | **SÍ** |
| 5 | "¿Requiere autenticación? ¿Qué tipo? (Bearer token, API key, Basic, ninguna)" | restHeaders (auth) | No — config de ambiente |
| 6 | "¿Tiene timeout? ¿Cuánto?" | timeout | No — default 30s |

**Si la URL es fija/hardcodeada** → detectar anti-pattern #3 (Hardcoded): "Esa URL parece específica de un ambiente. ¿Conviene que sea un parámetro configurable?"

**Si requiere auth OAuth/Bearer** → preguntar: "¿La variable de ambiente donde está el token tiene nombre? (ej: SAP_TOKEN)" — no hardcodear tokens en la spec.

**Ejemplo:**
```
Skill: "La actividad 'Generar Orden en SAP' es REST. ¿Cuál es la URL?"
User:  "https://sap.empresa.com/api/orders"
Skill: "Esa URL parece específica de un ambiente. ¿Conviene que sea configurable?"
User:  "Sí, mejor como parámetro"
Skill: "¿Qué operación? ¿GET, POST, PUT, DELETE?"
User:  "POST, le envío los datos del pedido"
Skill: "¿Qué datos le envía?"
User:  "El JSON con proveedor, items, monto total"
Skill: "¿Requiere autenticación?"
User:  "Sí, Bearer token"
Skill: "¿La variable de ambiente del token tiene nombre?"
User:  "SAP_API_TOKEN"
```

#### 5b.3 — Email/Send Task (atributos técnicos)

Para cada actividad Email identificada:

| # | Pregunta | Atributo BPMN | Bloqueante |
|---|----------|---------------|------------|
| 1 | "¿A quién se envía? ¿Es una dirección fija o dinámica (del proceso)?" | emailTo | **SÍ** |
| 2 | "¿Cuál es el asunto del email?" | emailSubject | No — placeholder OK |
| 3 | "¿El cuerpo es texto fijo o incluye datos del proceso?" | emailBody | No — placeholder OK |
| 4 | "¿Usa SMTP o Google API?" | emailServiceType | No — default SMTP |

**Ejemplo:**
```
Skill: "El email 'Notificar Aprobación'. ¿A quién se envía?"
User:  "Al email del solicitante, que viene del proceso"
Skill: "¿Cuál es el asunto?"
User:  "Solicitud de Compra #[número] Aprobada"
Skill: "¿El cuerpo incluye datos del proceso?"
User:  "Sí, el monto, proveedor, y quién aprobó"
```

#### 5b.4 — For / Iteración (atributos técnicos)

Para cada actividad For identificada:

| # | Pregunta | Atributo BPMN | Bloqueante |
|---|----------|---------------|------------|
| 1 | "¿Sobre qué lista itera? (ej: líneas del pedido, destinatarios)" | InputParameter | **SÍ** |
| 2 | "¿Cómo se llama cada elemento de la lista?" (ej: 'línea', 'destinatario') | ItemVariable | No — se puede inferir |
| 3 | "¿Qué se hace por cada elemento?" | Actividades hijas | **SÍ** — ya capturado en Sec 3 |
| 4 | "¿Qué pasa si falla el procesamiento de un elemento? a) Se cancela todo (transaccional) b) Continúa con los demás (best-effort)" | Transaccional flag | **SÍ** |

**Si detecta For anidado** (lista dentro de lista) → "Esto podría ser un For dentro de un For. En BIZUIT se modela con dos actividades For encadenadas. ¿Es eso lo que necesitás?"

#### 5b.5 — Timer / Expirable (atributos técnicos)

Para cada actividad con timer o expiración:

| # | Pregunta | Atributo BPMN | Bloqueante |
|---|----------|---------------|------------|
| 1 | "¿Cuánto tiempo? (ej: 48 horas, 5 días)" | ExpirationTime / DelayDuration | No — WARNING si vacío |
| 2 | "¿Horas hábiles o calendario?" | CalendarRef | **SÍ** |
| 3 | "¿Qué pasa cuando vence? a) Escalar a otro responsable b) Aprobar automáticamente c) Rechazar automáticamente d) Cancelar el proceso" | EscalationAction / ScheduledActions | **SÍ** |
| 4 | "¿Hay notificación de advertencia antes del vencimiento? ¿Cuándo?" | WarningTime | No |

**Si no sabe la duración** → WARNING: "⚠️ Timer '{nombre}': duración sin definir. El timer no funcionará hasta que se complete." + continuar sin bloquear. La checklist (`completeness-checklist.md`) lo marcará como BLOCKER antes de generar BPMN.

#### 5b.6 — Send Message / Receive Message (atributos técnicos)

Para cada comunicación inter-proceso:

| # | Pregunta | Atributo BPMN | Bloqueante |
|---|----------|---------------|------------|
| 1 | "¿Esperás respuesta (sincrónico) o solo avisás (asincrónico)?" | Modo sync/async | **SÍ** |
| 2 | "¿Qué datos le enviás al subproceso?" | MessageParameters | **SÍ** |
| 3 | Si sync: "¿Cuánto tiempo máximo esperás la respuesta?" | Timeout | No — WARNING si vacío |
| 4 | Si sync: "¿Qué pasa si no responde a tiempo?" | TimeoutAction | **SÍ** (si sync) |
| 5 | "¿Qué datos recibís de vuelta?" (si sync o Receive) | ResponseParameters | No |

**Si el proceso destino no existe** → registrar como referencia pendiente: "Proceso destino '{nombre}' aún no creado."

#### 5b.7 — Sequence / Try-Catch (atributos técnicos)

Para cada bloque con manejo de error:

| # | Pregunta | Atributo BPMN | Bloqueante |
|---|----------|---------------|------------|
| 1 | "¿Qué actividades agrupa este bloque?" | Actividades hijas | **SÍ** — ya de Sec 3 |
| 2 | "¿Qué errores captura?" | FaultHandlers / ErrorType | **SÍ** |
| 3 | "¿Qué hace cuando captura un error? (notificar, reintentar, abortar, re-throw)" | Catch action | **SÍ** |
| 4 | "¿Hay otros errores que querés capturar?" | Múltiples catch blocks | No — iterar hasta "eso es todo" |

#### 5b.8 — Manejo de errores por actividad (post-elicitación técnica)

Después de completar los atributos técnicos de cada actividad de integración (SQL, REST, Email, SendMessage), preguntar:

```
"¿Qué pasa si '{nombre}' falla (ej: el sistema no responde)?
 a) Lo maneja esta actividad con un catch local
 b) Lo maneja el contenedor de errores global del proceso"
```

- Si elige **local** → preguntar qué hace el catch (notificar, reintentar N veces, abortar, otro)
- Si elige **global** → registrar que delega al ExceptionContainer
- Registrar `errorHandling: "local"` o `errorHandling: "global"` en el detalle de la actividad

#### 5b.9 — Integración con sistema desconocido

Si el analista describe una integración sin que el skill pueda inferir el tipo:

```
"¿'{descripción}' es:
 a) Una API REST (llamada HTTP)
 b) Una query SQL a una base de datos
 c) Un email
 d) Un servicio SOAP
 e) Otro tipo de integración"
```

- Si elige a-c → continuar con las preguntas del tipo elegido
- Si elige d (SOAP) → tratar como REST con nota: "Configurar como REST con body XML en el editor"
- Si elige e (otro) → documentar como actividad personalizada: "⚠️ Requiere configuración manual en el editor BIZUIT"

---

### Paso 5c — Sección 5: Integraciones (auto-generada)

**No se elicita.** Se genera automáticamente de la información recopilada en Secciones 3 y 4.

1. **Recorrer todas las actividades** con sus atributos técnicos ya elicitados
2. **Agrupar por tipo** y generar tablas:

**SQL (si hay SqlActivity):**
```markdown
### Bases de datos (SQL)
#### Conexiones
| Conexión | Actividades | Tipo |
|----------|-------------|------|

#### Dependencias de datos (tablas/SPs)
| Tabla/SP | Tipo | Operación | Actividad | Conexión |
|----------|------|-----------|-----------|----------|
```

**REST (si hay RestFullActivity):**
```markdown
### APIs externas (REST)
| URL base | Método | Actividades | Timeout | Propósito |
|----------|--------|-------------|---------|-----------|
```

**Email (si hay EmailActivity):**
```markdown
### Email
| Template | Asunto | Cuándo |
|----------|--------|--------|
```

**SendMessage (si hay SendMessageActivity):**
```markdown
### Subprocesos (SendMessage)
| Subproceso | Propósito | Modo | Invocaciones |
|------------|-----------|------|-------------|
```

3. **Marcar datos faltantes** con `⚠️ pendiente` si el analista dijo "no sé" o dejó en placeholder
4. **Mostrar la sección generada** al usuario para confirmación

---

### Paso 5d — Guardar spec parcial (Secciones 4-5 completas)

Al completar las Secciones 4-5:

1. **Escribir** `## 4. Funcionalidades` en spec.md con agrupación por categoría y links cross-file
2. **Escribir** `## 5. Integraciones` en spec.md con las tablas auto-generadas
3. **Actualizar** `detalle-tecnico.md` — reemplazar placeholders con atributos técnicos reales:

```markdown
#### detalle-{xname}
**{xname}** ({tipo})
- **Nombre**: {nombre legible}
- **Tipo**: {tipo}
- **Connection**: {ConfigFileCnnStringName} (si SQL)
- **CommandType**: {Text/StoredProcedure} (si SQL)
- **ReturnType**: {Scalar/DataSet/NonQuery} (si SQL)
- **URL**: {restUrl} (si REST)
- **Método**: {GET/POST/PUT/DELETE} (si REST)
- **Error Handling**: {local/global}
- ...{todos los atributos elicitados}
```

4. **Actualizar frontmatter**: `completedSections: [1, 2, 3, 4]`, `lastActivity: "Sección 5 completa"`
   (Sección 5 no aparece en completedSections porque es auto-generada)

5. **Mostrar resumen:**

```
Secciones 1-5 completas para '{nombre}':
- {N} actividades con atributos técnicos
- {S} integraciones SQL, {R} REST, {E} Email, {M} SendMessage
- {W} warnings pendientes
- Guardado en processes/{org}/{slug}/spec.md

Próximo paso: Edge Cases (Sección 6), NFRs (Sección 7), Decisiones (Sección 8).
```

---

### Paso 6 — Manejo de "no sé"

Durante toda la elicitación, el usuario puede responder "no sé" a cualquier pregunta.

**Si es bloqueante:**
```
"Necesito saber {qué} para poder {por qué}. Sin esto no podemos continuar.
¿Podés consultarle al responsable del proceso? Puedo esperar o avanzar con
otra sección mientras tanto."
```
→ No avanzar. Marcar como pendiente. Ofrecer continuar con otra sección.

**Si NO es bloqueante:**
```
"OK, lo marco como pendiente: ⚠️ {campo} sin definir en actividad '{nombre}'.
Seguimos con la siguiente pregunta."
```
→ Registrar WARNING en spec. Continuar sin interrumpir.

---

### Paso 7 — Inferencia de perfil y adaptación (Story 3.3)

El skill infiere el perfil del usuario en los primeros 2-3 mensajes y adapta su lenguaje.

#### 7a — Detección de perfil

| Señales | Perfil | Adaptación |
|---------|--------|------------|
| Menciona connection strings, queries, REST, schedulers, APIs sin explicación | **Técnico** | Lenguaje técnico directo. Profundizar en detalles de integración. Saltear preguntas de negocio innecesarias. |
| Describe flujos en lenguaje de negocio ("el comité aprueba", "se manda al banco") sin términos técnicos | **Analista de negocio** | Metáforas de negocio. NO usar "gateway", "sequence flow", "BPMN". Cuando hay bifurcación: "Parece que en este punto el proceso puede ir por dos caminos." |
| Mezcla técnico y negocio | **Mixto** | Seguir el lead del usuario. Si dice "gateway" usarlo, si dice "decisión" usarlo. |

**Nota:** El perfil puede cambiar durante la sesión. Si el usuario dice "eso ya lo sé, no me expliques" → adaptar a más técnico. Si pregunta "¿qué es un timeout?" → adaptar a más educativo.

#### 7b — Proceso automático (FR52)

Si se detecta proceso sin User Tasks (scheduler, integración pura):
- **NO preguntar**: "¿Quiénes participan?", roles, SLAs humanos, formularios
- **SÍ preguntar**: restricciones de horario del scheduler, autenticación de APIs, manejo de errores técnicos
- **Agregar nota** en spec: "(proceso automático — {trigger type}, sin User Tasks)"

#### 7c — Contexto educativo (FR53)

Cuando el usuario pregunta **"¿por qué me preguntás eso?"**, responder con **impacto real**, no con razón técnica:

| Pregunta del skill | Respuesta educativa (impacto real) |
|---|---|
| Timeout del SQL | "Si una consulta SQL no tiene límite de tiempo y la base tarda mucho, el proceso se bloquea indefinidamente. Un timeout garantiza que si algo falla, el proceso lo detecta y puede notificar." |
| Quién es el sustituto | "Si la única persona que puede aprobar está de vacaciones, el proceso se traba hasta que vuelva. Un sustituto garantiza que el negocio no se frena." |
| Qué pasa si la API falla | "Si no definimos qué hacer cuando un sistema externo no responde, el proceso queda 'colgado' en producción sin que nadie se entere." |
| Default path del gateway | "Si ninguna condición se cumple y no hay camino por defecto, el proceso se detiene sin explicación. Es como un semáforo que nunca cambia." |

**Después de la explicación, retomar la pregunta original.** No esperar a que el usuario la repita.

#### 7d — Anti-patterns con contexto educativo

Cuando se detecta un anti-pattern (ver `anti-patterns.md`), la advertencia es **educativa, no bloqueante**:

```
"⚠️ Anti-pattern detectado: {nombre del anti-pattern}
 {Explicación del impacto real — por qué importa}
 {Sugerencia concreta}
 ¿Querés que lo ajustemos?"
```

**Si el usuario dice "sí"** → aplicar la sugerencia a la spec.
**Si dice "no"** → documentar como WARNING en spec y continuar. No insistir.
**Si ya se explicó el mismo anti-pattern** → no repetir la explicación completa: "¿Confirmás que querés mantener {patrón}?"

Detección extendida durante Sección 4 (técnicos):
- **Hardcoded ID** en query SQL (ej: `WHERE cliente_id = 8523`) → "Si el proceso se reutiliza para otro cliente, hay que modificar la query. ¿Querés que sea un parámetro de entrada?"
- **URL hardcodeada** en REST → "Esa URL parece específica de un ambiente. ¿Conviene que sea configurable?"
- **Regulación implícita** ("el banco exige", "según la ley") → "¿Hay un SLA regulatorio? ¿Cuánto tiempo tiene el proceso?"

#### 7e — Correcciones del usuario (FR51)

Cuando el usuario corrige algo ya elicitado:

**Corrección simple (1 actividad):**
```
User: "Espera, la actividad 3 no es SQL sino REST"
Skill: "Entendido. Cambio 'Consultar Saldo' de SQL a REST.
        Necesito re-hacerte las preguntas técnicas de REST para esta actividad."
→ Re-elicitar solo esa actividad con preguntas del nuevo tipo.
```

**Corrección que afecta múltiples actividades:**
```
User: "En realidad todas las SQL se conectan a ProveedoresDB, no ComprasDB"
Skill: "Entendido. Tenés 3 actividades SQL (ConsultarProveedor, ValidarSaldo, ObtenerLimite).
        Las 3 usaban ComprasDB. Las actualicé todas a ProveedoresDB."
→ Actualizar TODAS las actividades afectadas en la spec parcial.
```

**Reglas de corrección:**
- **No discutir** — confiar en el analista (CLAUDE.md regla)
- **Confirmar** qué se actualizó para que el usuario verifique
- **Si afecta journeys o ACs** → actualizar también los ACs y narrativas afectados

#### 7f — "Hacé lo que te parezca" (NFR35)

Si el usuario dice "hacé lo que te parezca" o "ponele lo que sea":
```
"Para generar una spec correcta necesito algunos datos específicos que solo vos
podés darme. Por ejemplo: ¿quién inicia este proceso? Sin esto el proceso no
tiene trigger definido."
```
→ Hacer UNA pregunta concreta, no listar 10 de golpe. **NUNCA asumir valores inventados.**

#### 7g — Reglas generales de conversación

1. **Máximo 3 preguntas consecutivas** sin contexto o confirmación (NFR15)
2. **Si el usuario responde fuera de orden** (da info de Sección 4 en Sección 2) → registrar en el lugar correcto, no forzar orden
3. **Confirmar estructura** inferida antes de profundizar en detalles (FR5)
4. **No asumir datos** que el usuario no dio (NFR35)
5. **Usuario experto que quiere saltear** → aceptar "eso ya lo sé" e ir directo a los datos
6. **Usuario hace preguntas filosóficas** → responder brevemente y retomar: "Eso depende del negocio. ¿Cómo lo manejan hoy?"

---

### Paso 8 — User Task Forms (Story 3.4)

Para cada User Task identificada en Sección 3, elicitar el formulario completo. Consultar `elicitation-by-section.md` sección "User Task Forms".

#### 8a — Acciones del form

Preguntar primero las acciones (botones):

```
"La tarea '{nombre}' — ¿qué opciones tiene el {rol}?
 (ej: Aprobar/Rechazar, Completar, Enviar, etc.)"
```

**Si solo tiene acciones sin campos** (ej: "solo aprueba o rechaza"):
```
"Entendido. El form tiene:
 - Acciones: [Aprobar] [Rechazar]
 - Sin campos de datos adicionales
 ¿Querés agregar algún campo (ej: motivo de rechazo)?"
```
→ Si dice "no" → registrar form mínimo. Válido.

#### 8b — Campos del form

Para cada campo:

| # | Pregunta | Ejemplo |
|---|----------|---------|
| 1 | "¿Qué nombre tiene este campo?" | "Número de OC" |
| 2 | "¿Qué tipo de dato? (texto, número, fecha, sí/no, lista, archivo)" | "Texto" |
| 3 | "¿Es obligatorio?" | "Sí" |
| 4 | "¿Tiene alguna validación? (rango, formato, longitud)" | "Máximo 20 caracteres" |

**Tipos de campo reconocidos:**

| Tipo usuario | Tipo spec | Nota |
|---|---|---|
| texto, texto libre | text | — |
| número, entero | int | — |
| número decimal, monto | decimal | — |
| fecha | date | Preguntar: ¿restricción de rango? |
| fecha y hora | datetime | — |
| sí/no, checkbox | boolean | — |
| lista, desplegable | select | Preguntar: ¿opciones fijas o dinámicas? |
| archivo, adjunto | file | Preguntar: extensiones, tamaño máximo |
| lista de items | list/XML | → navegar estructura anidada (8c) |

#### 8c — Estructura anidada (XML)

Si un campo es de tipo lista con subitems:

```
Skill: "La lista de '{nombre}' — ¿qué tiene cada elemento?"
User:  "Código, cantidad y precio"
Skill: "¿Cada elemento tiene algún subelemento? (ej: desglose, impuestos)"
User:  "Sí, cada línea tiene impuestos: tipo y porcentaje"
Skill: "¿Cada impuesto tiene algún subelemento?"
User:  "No, eso es todo"
```

→ Navegar recursivamente hasta que el usuario diga "no" o "eso es todo". Sin límite de profundidad.

**Formato en spec:**
```markdown
**{NombreLista}** (lista):
  - campo1: tipo, obligatorio
  - campo2: tipo
  **{SubLista}** (lista anidada):
    - subcampo1: tipo
    - subcampo2: tipo
```

#### 8d — Campos condicionales por acción

Si una acción requiere campos adicionales:

```
User: "Si rechaza, debe poner el motivo"
Skill: "Entendido. El campo 'Motivo de Rechazo' aparece solo con la acción Rechazar.
        ¿Es texto libre? ¿Obligatorio? ¿Longitud máxima?"
```

**Formato en spec:**
```markdown
**Acciones**:
- [Aprobar] → sin campos adicionales
- [Rechazar] → requiere: Motivo de Rechazo (text, obligatorio, max 500 chars)
- [Solicitar más info] → requiere: Detalle (text, obligatorio)
```

#### 8e — Form con muchos campos (>20)

Si el form tiene más de 20 campos → agrupar por sección:

```
"Este form tiene {N} campos. ¿Se pueden agrupar en secciones?
 Por ejemplo: 'Datos del solicitante', 'Datos de la compra', 'Adjuntos'."
```

#### 8f — Anotación de binding por ID

Al completar cada form, agregar nota:

```markdown
> **Binding**: Este form se vincula al ID `{ActivityId}`.
> Si el ID cambia en una edición futura, el form queda desvinculado.
```

#### 8g — Guardar form en spec

Formato estandarizado en spec.md (Markdown puro, editable por humanos — FR55):

```markdown
### Form: {NombreActividad}
**Actividad**: [{ActivityId}](detalle-tecnico.md#detalle-{xname})

| Campo | Tipo | Obligatorio | Validaciones |
|-------|------|-------------|--------------|
| {nombre} | {tipo} | Sí/No | {validaciones o —} |

{Estructura anidada si hay listas}

**Acciones**: [{acción1}] [{acción2}] [{acción3}]
{Campos condicionales por acción si hay}

> **Binding**: Este form se vincula al ID `{ActivityId}`.
```

**Nota:** Lógica condicional compleja (campo visible solo si otro campo tiene valor X) se documenta como: `Visible si: [campo] == "valor"` con nota "Requiere configuración manual en el Designer".
**Nota:** Campos calculados se documentan con fórmula + nota "campo calculado — requiere lógica en el Designer".

---

### Paso 9 — Elicitación de Secciones 6-8 y Canal del proceso (Story 3.5)

Después de completar Secciones 1-5 + Forms, elicitar las secciones restantes.

#### 9a — Sección 6: Edge Cases (parcialmente elicitada)

Ya se capturaron errores durante Secciones 3-4 (anti-patterns, error handling por actividad). Ahora consolidar:

```
"Ya discutimos errores individuales. ¿Hay algún caso borde general que no cubrimos?
 Por ejemplo: ¿qué pasa si el proceso se ejecuta fuera de horario? ¿Si se ejecuta
 dos veces para el mismo caso?"
```

Si hay errores mencionados en journeys no documentados aquí → agregar.

#### 9b — Sección 7: NFRs

```
"¿Hay requisitos no funcionales para este proceso?
 - SLAs generales (tiempo total del proceso)
 - Rendimiento (cuántas instancias simultáneas)
 - Logging (nivel de tracking)
 - Reintentos para integraciones"
```

Si no hay Expirable ni REST → "Sin NFRs inferibles."

#### 9c — Sección 8: Decisiones y Restricciones

```
"¿Hay algo más que debería saber?
 - Reglas de negocio que no mencionamos
 - Restricciones de seguridad
 - Calendario laboral
 - Segregación de funciones"
```

#### 9d — Canal del proceso (FR56)

Antes del validate, preguntar:

```
"¿Por qué canal se usa este proceso?
 - Web (portal BIZUIT)
 - Mobile
 - Scheduler (automático, sin intervención humana)
 - Integración (disparado por otro proceso o sistema)
 - Otro"
```

Registrar en frontmatter: `entryChannel: "{valor}"`.

**Si es Scheduler y hay User Tasks** → WARNING: "Un proceso de scheduler con User Tasks necesita algún mecanismo para notificar al usuario."

#### 9d-bis — Clasificación de Parámetros (FR103)

Antes de guardar, clasificar cada parámetro del proceso:

1. Consultar `activity-defaults.md` → sección "Guía: Parámetros vs Variables"
2. Para cada parámetro inferido durante la elicitación:
   - Aplicar tabla de decisión → asignar Rol (Parámetro o Variable)
   - Aplicar reglas de Filterable → asignar Sí o No
   - Documentar como asunción inline: `pEstado (string, Parámetro, Filterable 💡asumí que se busca por estado)`
3. Generar tabla extendida: `| Nombre | Tipo dato | Dirección | Rol | Filterable |`
4. Reglas 1-3 y 5 de inferencia aplican en create. Regla 4 (FormSchemaJson) NO aplica

**El usuario puede corregir cualquier asunción de Rol o Filterable.** Las asunciones no corregidas se aceptan.

#### 9e — Guardar spec completa

Actualizar frontmatter: `status: "complete"`, `completedSections: [1, 2, 3, 4, 6, 7, 8]`.
(Secciones 5, 9, Detalle se auto-generan.)

---


### Paso 9f — Lanes Mapping & RACI (Epic 15 — FR127, FR134)

**Solo ejecutar si frontmatter del spec tiene `lanes: true`.** Si `lanes: false` → saltar al paso "Al completar".

#### 9f.1 — Mapping Confirmation

Mostrar tabla de mapping Performer → Activities para confirmación:

```
"Mapping de roles a actividades para los carriles:

| Performer | Activities |
|-----------|------------|
| {Performer1} | T1: {nombre}, T3: {nombre} |
| {Performer2} | T2: {nombre}, T4: {nombre} |
| ...

¿El mapping es correcto?"
```

**Si el usuario corrige el mapping** → actualizar y re-mostrar.

#### 9f.2 — Fallback ≤1 lane

Después del mapping, contar lanes efectivos (performers con ≥1 actividad).
Si ≤1 lane efectivo → cancelar lanes:
```
"Solo se detectó 1 área con actividades. Se generará proceso plano (sin carriles)."
```
Actualizar frontmatter: `lanes: false`.

#### 9f.3 — RACI opcional

Si >1 lane efectivo, preguntar sobre RACI:

```
"¿Querés definir roles RACI (Accountable, Consulted, Informed) por área?
*(No/Sí, default: No)*"
```

- "No" (o default) → sin RACI, solo Performers
- "Sí" → para cada lane/performer, preguntar: "¿Quién es Accountable, Consulted, Informed para {performer}?" (puede responder parcialmente o saltar con "ninguno")

#### 9f.4 — Generar sección Lanes en spec

Si lanes=true después del mapping:
- Generar sección "## Lanes" en spec.md según formato de `rules/sdd/spec-format.md`
- Tabla Performer → Activities ordenada por primera aparición
- Si RACI definido → agregar subtabla ### RACI

---

## Al completar

Guardar spec con `status: "complete"`, `completedSections: [1, 2, 3, 4, 6, 7, 8]`. Volver a `create.md` (orchestrator) para routing a la siguiente fase (validation).

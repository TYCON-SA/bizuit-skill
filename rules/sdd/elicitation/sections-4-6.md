# Elicitation: Secciones 4-6 (Funcionalidades, Integraciones, Edge Cases)

> Extraído de elicitation-by-section.md. Nivel 2 de progressive disclosure.
> En draft-first: estas secciones se usan para descomponer en tipos BIZUIT.
> En refinamiento: se usan para profundizar en detalles técnicos.

## Sección 4: Funcionalidades (detalles técnicos)

Agrupar actividades por categoría. **NO 1:1 con actividades.**

Esta sección tiene 2 partes:
1. **Preguntas funcionales** (alto nivel, qué hace) — para la agrupación en spec.md
2. **Preguntas técnicas** (atributos BPMN) — para el detalle-tecnico.md

**Regla clave:** Las preguntas técnicas se hacen en **lenguaje de negocio**. El skill traduce internamente a atributos BPMN.

### Preguntas generales

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay algo más que el proceso haga que no mencionamos en los journeys?" | No | `U: "También logguea cada paso para auditoría"` |
| "¿Hay funcionalidades de trazabilidad o logging?" | No | `U: "Sí, se registra quién aprobó y cuándo"` |

### Por tipo de actividad

#### SQL Service Task → Sección 4

**Funcional:**

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué funcionalidad cubre esta consulta a nivel de negocio?" | **SÍ** | `U: "Verificación de permisos del usuario"` |

**Técnico (atributos BPMN):**

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿A qué base de datos se conecta? (nombre de la conexión)" | ConfigFileCnnStringName | No | `U: "InventarioDB"` |
| "¿Qué hace? ¿Consulta, inserta, actualiza, o ejecuta un stored procedure?" | CommandType + Operación | **SÍ** | `U: "Ejecuta un SP"` |
| Si SP: "¿Cómo se llama el stored procedure?" | CommandText | **SÍ** | `U: "sp_GetPermisos"` |
| Si query: "¿Podés describir la consulta o pegarla directamente?" | CommandText | No | `U: "SELECT * FROM Users WHERE Id = @userId"` |
| "¿Qué datos necesita como input?" | Input mappings | **SÍ** | `U: "El ID del usuario"` |
| "¿Qué devuelve? ¿Un dato solo, un conjunto de filas, o nada?" | ReturnType (Scalar/DataSet/NonQuery) | **SÍ** | `U: "Un dato solo: true o false"` → Scalar |
| "¿Tiene timeout?" | CommandTimeout | No | `U: "30 segundos"` (default) |

**Si query > 5 líneas** → "¿Preferís pegarla directamente o describir lo que necesitás para que quede como placeholder?"

**Ejemplo de diálogo completo:**
```
S: "La actividad 'Verificar Permisos' es SQL. ¿A qué base se conecta?"
U: "A la base de usuarios, conexión UsersDB"
S: "¿Qué hace? ¿Consulta, inserta, actualiza, o ejecuta un SP?"
U: "Ejecuta el SP sp_CheckPermission"
S: "¿Qué datos necesita?"
U: "El ID del usuario y el nombre del permiso"
S: "¿Qué devuelve? ¿Un valor, filas, o nada?"
U: "Un valor: 1 si tiene permiso, 0 si no"
```
→ SQL, Connection="UsersDB", CommandType="StoredProcedure", CommandText="sp_CheckPermission", ReturnType="Scalar"

#### REST Service Task → Sección 4

**Funcional:**

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué funcionalidad cubre esta integración a nivel de negocio?" | **SÍ** | `U: "Registro de la compra en el sistema contable"` |

**Técnico (atributos BPMN):**

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿Cuál es la URL del servicio? ¿Es fija o varía por ambiente?" | restUrl | No | `U: "https://sap.empresa.com/api/orders"` → detectar hardcoded |
| "¿Qué operación? ¿Consultar (GET), enviar (POST), actualizar (PUT), o eliminar (DELETE)?" | restVerb | **SÍ** | `U: "POST"` |
| Si POST/PUT: "¿Qué datos le envía?" | restBody / input mappings | **SÍ** | `U: "JSON con proveedor, items, monto"` |
| "¿Qué devuelve?" | output mappings | **SÍ** | `U: "El ID de la orden creada"` |
| "¿Requiere autenticación? ¿Qué tipo? (Bearer, API key, Basic, ninguna)" | restHeaders (auth) | No | `U: "Bearer token"` |
| Si auth Bearer/OAuth: "¿La variable de ambiente del token tiene nombre?" | Auth config | No | `U: "SAP_API_TOKEN"` |
| "¿Tiene timeout?" | timeout | No | `U: "15 segundos"` |

**Si URL hardcodeada** → anti-pattern #3: "Esa URL parece específica de un ambiente. ¿Conviene que sea configurable?"
**Si auth OAuth/Bearer** → nunca hardcodear tokens: preguntar nombre de variable de ambiente.

#### Email/Send Task → Sección 4

**Funcional:**

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿La notificación es parte de una funcionalidad más amplia?" | No | `U: "Sí, es la confirmación de aprobación"` |

**Técnico (atributos BPMN):**

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿A quién se envía? ¿Dirección fija o dinámica (del proceso)?" | emailTo | **SÍ** | `U: "Al email del solicitante"` → dinámico |
| "¿Cuál es el asunto del email?" | emailSubject | No | `U: "Solicitud #[número] Aprobada"` |
| "¿El cuerpo es texto fijo o incluye datos del proceso?" | emailBody | No | `U: "Incluye monto, proveedor, quién aprobó"` |
| "¿Usa SMTP o Google API?" | emailServiceType | No | `U: "SMTP"` (default) |

#### User Task → Sección 4 (Forms — Story 3.4)

Elicitación completa de formularios. El form debe ser suficiente para que el full-stack lo configure en el Designer sin preguntar al analista.

**Paso 1 — Acciones:**

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué opciones tiene el {rol}? (ej: Aprobar/Rechazar)" | **SÍ** | `U: "Aprobar, Rechazar, o Devolver"` |
| "¿Alguna acción requiere datos adicionales? (ej: motivo de rechazo)" | No | `U: "Si rechaza, debe poner el motivo"` |

**Paso 2 — Campos:**

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué campos tiene el formulario?" | **SÍ** | `U: "Número de OC, monto, fecha"` |
| Por cada campo: "¿Qué tipo? (texto, número, fecha, sí/no, lista, archivo)" | **SÍ** | `U: "Monto es decimal"` |
| "¿Es obligatorio?" | No | `U: "Sí"` |
| "¿Tiene validación? (rango, formato, longitud)" | No | `U: "> 0"` |

**Paso 3 — Estructura anidada (si hay listas):**

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué tiene cada elemento de la lista?" | **SÍ** | `U: "Código, cantidad, precio"` |
| "¿Cada elemento tiene subelementos?" | No | Recursivo hasta "no" |

**Form mínimo válido:** Solo acciones, sin campos de datos. Si el usuario dice "solo aprueba o rechaza" → aceptar sin insistir en campos.

**Formato en spec** (Markdown puro, editable — FR55):
```markdown
### Form: {NombreActividad}
| Campo | Tipo | Obligatorio | Validaciones |
|-------|------|-------------|--------------|
**Acciones**: [Acción1] [Acción2]
> **Binding**: vinculado al ID `{ActivityId}`
```

**Edge cases de forms:**
- >20 campos → agrupar por sección ("Datos del solicitante", "Datos de la compra")
- Archivo adjunto → preguntar extensiones, tamaño máximo
- Campo visible solo si otro campo tiene valor X → `Visible si: [campo] == "valor"` + nota "configurar en Designer"
- Campo calculado → documentar fórmula + nota "requiere lógica en Designer"
- Múltiples roles con mismo form → preguntar si ven el mismo form o versiones distintas

#### For (Iteración) → Sección 4

**Técnico (atributos BPMN):**

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿Sobre qué lista itera?" | InputParameter | **SÍ** | `U: "Las líneas del pedido"` |
| "¿Cómo se llama cada elemento?" | ItemVariable | No | `U: "linea"` |
| "Si falla un elemento: ¿se cancela todo (transaccional) o continúa con los demás (best-effort)?" | Transaccional flag | **SÍ** | `U: "Continúa con los demás"` → best-effort |

**Si For anidado** → "Esto podría ser un For dentro de un For. En BIZUIT se modela con dos For encadenadas. ¿Es eso lo que necesitás?"

#### Timer / Expirable → Sección 4

**Técnico (atributos BPMN):**

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿Cuánto tiempo? (ej: 48 horas, 5 días)" | ExpirationTime / DelayDuration | No — WARNING si vacío | `U: "48 horas"` |
| "¿Horas hábiles o calendario?" | CalendarRef | **SÍ** | `U: "Hábiles, lunes a viernes"` |
| "¿Qué pasa cuando vence? a) Escalar b) Aprobar auto c) Rechazar auto d) Cancelar" | EscalationAction | **SÍ** | `U: "Escalar al gerente"` |
| "¿Hay notificación de advertencia antes? ¿Cuándo?" | WarningTime | No | `U: "24hs antes, un recordatorio"` |

**Si no sabe duración** → WARNING: "⚠️ Timer '{nombre}': duración sin definir. El timer no funcionará hasta que se complete." Continuar sin bloquear. `completeness-checklist.md` lo marcará como BLOCKER antes de generar BPMN.

#### Send Message / Receive Message → Sección 4

**Técnico (atributos BPMN):**

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿Esperás respuesta (sincrónico) o solo avisás (asincrónico)?" | Modo sync/async | **SÍ** | `U: "Solo aviso, fire-and-forget"` |
| "¿Qué datos le enviás al subproceso?" | MessageParameters | **SÍ** | `U: "ID de solicitud y monto"` |
| Si sync: "¿Cuánto tiempo máximo esperás respuesta?" | Timeout | No — WARNING | `U: "30 segundos"` |
| Si sync: "¿Qué pasa si no responde a tiempo?" | TimeoutAction | **SÍ** (si sync) | `U: "Se cancela el proceso"` |
| "¿Qué datos recibís de vuelta?" (si sync/Receive) | ResponseParameters | No | `U: "Confirmación de envío"` |

**Si proceso destino no existe** → "Proceso destino '{nombre}' aún no creado" (referencia pendiente).

#### Sequence / Try-Catch → Sección 4

**Técnico (atributos BPMN):**

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿Qué errores captura este bloque?" | FaultHandlers / ErrorType | **SÍ** | `U: "Errores de la API de pagos"` |
| "¿Qué hace cuando captura un error?" | Catch action | **SÍ** | `U: "Notifica a IT y sigue"` |
| "¿Hay otros errores que querés capturar?" | Múltiples catches | No — iterar | `U: "Eso es todo"` |

#### Manejo de errores por actividad (post-técnico)

Después de los atributos técnicos de cada actividad de integración (SQL, REST, Email, SendMessage):

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿Qué pasa si '{nombre}' falla? a) Catch local b) Error handler global" | errorHandling | **SÍ** | `U: "Global"` |
| Si local: "¿Qué hace el catch? (notificar, reintentar, abortar)" | Catch action | **SÍ** | `U: "Reintenta 1 vez, si falla notifica"` |

#### Integración con sistema desconocido

Si no se puede inferir el tipo:

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Es: a) API REST b) Query SQL c) Email d) SOAP e) Otro?" | **SÍ** | `U: "Es SOAP"` → tratar como REST con body XML |

Si elige "otro" → "⚠️ Requiere configuración manual en el editor BIZUIT"

#### Exclusive Gateway / Parallel Gateway → Sección 4

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Este punto de decisión es parte de una regla de negocio que quieras documentar?" | No | `U: "Sí, la regla de aprobación por montos"` |

#### Call Activity → Sección 4

| Pregunta | Atributo | Bloqueante | Ejemplo |
|----------|----------|------------|---------|
| "¿La comunicación con '{subproceso}' es una funcionalidad clave?" | — | No | `U: "Sí, es la orquestación de pagos"` |
| "¿Qué datos le pasa?" | InputMappings | No | `U: "ID del pedido"` |
| "¿Qué recibe de vuelta?" | OutputMappings | No | `U: "Estado del pago"` |

#### Set Parameter / Exception → Sección 4

No generan preguntas técnicas adicionales. Sus atributos se infieren del flujo.

---

## Sección 5: Integraciones — AUTO-GENERADA

**No se elicita.** Se genera automáticamente del flujo descrito en Secciones 3-4.

El skill extrae integraciones de las actividades identificadas:

| Tipo | Qué se auto-genera |
|------|-------------------|
| SQL | Tabla de conexiones + catálogo de tablas/SPs (FROM/JOIN/INSERT/UPDATE/DELETE/EXEC) |
| REST | Tabla con URL base, método, timeout, propósito |
| Email | Tabla con template, asunto, cuándo se envía |
| Send Message | Tabla con subproceso destino, propósito, modo |

Si un dato técnico falta (ej: connection string), se marca como `⚠️ pendiente` en la tabla.

---

## Sección 6: Edge Cases y Manejo de Errores

### Preguntas generales (siempre, al terminar Sección 3)

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasa si algo falla durante el proceso?" | No | `U: "Se cancela y notifica"` |
| "¿Hay errores que el proceso maneja de forma especial?" | No | `U: "Si la API falla, se reintenta 3 veces"` |

### Por tipo de actividad

#### SQL Service Task → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasa si la base de datos no responde?" | **SÍ** | `U: "Se lanza excepción"` → registrar error handling |
| "¿Qué pasa si la consulta no devuelve resultados?" | **SÍ** | `U: "Se asume que no tiene permiso"` |
| "¿Hay timeout para la consulta SQL?" | No | `U: "30 segundos"` |

#### REST Service Task → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasa si la API externa devuelve un error (4xx, 5xx)?" | **SÍ** | `U: "Se reintenta una vez. Si falla de nuevo, se cancela"` |
| "¿Tiene timeout? ¿Cuánto?" | No | `U: "15 segundos"` |
| "¿Hay retry automático?" | No | `U: "Sí, 1 reintento"` |

#### Email/Send Task → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Si el email no se puede enviar, el proceso se detiene?" | No | `U: "No, continúa. Es solo informativo."` |

#### Expirable → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasa exactamente cuando vence el plazo?" | **SÍ** | `U: "Se escala al siguiente nivel"` |
| "¿Hay aviso antes del vencimiento?" | No | `U: "24hs antes se envía recordatorio"` |

#### Sequence (Try/Catch) → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué errores captura este bloque?" | **SÍ** | `U: "Cualquier error de la API de pagos"` |
| "¿Qué hace cuando captura el error?" | **SÍ** | `U: "Registra el error y lanza excepción general"` |

#### Exception → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Cuándo se lanza esta excepción?" | **SÍ** | `U: "Cuando se detecta un error irrecuperable"` |
| "¿El proceso tiene un error handler global?" | No | `U: "Sí, notifica a IT por email"` |

#### Send Message / Receive Message → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasa si el subproceso destino falla?" | No | `U: "El proceso padre sigue sin enterarse"` |
| "¿Qué pasa si el mensaje nunca llega?" (Receive) | No | `U: "Timeout de 24hs"` |

#### Parallel Gateway → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasa si una de las ramas paralelas falla?" | No | `U: "Se espera a la otra y se reporta el error"` |

#### For (Iteración) → Sección 6

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasa si falla el procesamiento de un item?" | No | `U: "Se salta ese item y sigue con el resto"` |
| "¿Qué pasa si la lista tiene 0 items?" | No | `U: "No debería pasar, pero si pasa salta el bloque"` |

#### User Task / Exclusive Gateway / Timer / Set Parameter / Call Activity → Sección 6

No generan preguntas específicas de edge cases. Errores se infieren de las respuestas de Sección 3.

---


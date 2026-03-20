# Elicitation: Secciones 1-3 (Objetivo, Actores, Journeys)

> Extraído de elicitation-by-section.md. Nivel 1 de progressive disclosure.
> En draft-first: estas secciones se usan para generar el draft macro.
> En refinamiento: se usan para validar/profundizar el draft.

## Sección 1: Objetivo del proceso

**No depende del tipo de actividad.** Preguntas fijas para todo proceso.

| # | Pregunta | Campo | Bloqueante | Ejemplo de diálogo |
|---|----------|-------|------------|-------------------|
| 1 | "¿Cómo se llama este proceso?" | processName | **SÍ** | `U: "Proceso de compras"` → `S: "Perfecto. ¿Qué problema de negocio resuelve?"` |
| 2 | "¿Qué problema de negocio resuelve? ¿Cuál es el objetivo?" | Texto Sección 1 | **SÍ** | `U: "Las compras se hacen sin control"` → `S: "¿Qué evento dispara el proceso?"` |
| 3 | "¿Qué evento lo dispara?" | entryChannel | **SÍ** | `U: "Cuando alguien necesita comprar algo"` → `S: "¿Es un formulario web, un mail, un scheduler?"` |
| 4 | "¿Quiénes participan?" | Adelanto Sección 2 | **SÍ** | `U: "El empleado, su jefe, y compras"` |
| 5 | "¿Cuál es el resultado cuando termina exitosamente?" | Resultado en objetivo | **SÍ** | `U: "Se genera la orden de compra"` |

**Al completar**: `completedSections: [1]`. Mostrar resumen y confirmar.

---

## Sección 2: Actores

Relevante para tipos con interacción humana. Los demás tipos no generan preguntas aquí.

### Preguntas generales (siempre)

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Quién inicia el proceso?" | **SÍ** | `U: "El empleado"` → `S: "¿Qué rol tiene? ¿Cualquier empleado o uno con rol específico?"` |
| "¿Hay aprobadores o revisores?" | No | `U: "Sí, el jefe directo"` |
| "¿Hay stakeholders que solo reciben notificaciones?" | No | `U: "Compras recibe un email al final"` |
| "¿Es un proceso 100% automatizado?" | **SÍ** (si no mencionó personas) | `U: "No, hay personas"` |

### Por tipo de actividad

#### User Task → Sección 2

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué rol ejecuta esta tarea: '{nombre}'?" | **SÍ** | `U: "El jefe directo"` → `S: "¿Es siempre el jefe directo o puede ser cualquier gerente?"` |
| "¿Hay un sustituto si esa persona no está disponible?" | No | `U: "No sé"` → `S: "⚠️ Sin sustituto definido para '{nombre}'. Seguimos."` |

#### Expirable → Sección 2

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Quién es responsable de responder antes del vencimiento?" | No | `U: "El aprobador"` |

#### Email/Send Task → Sección 2

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿A quién se notifica?" | No | `U: "Al solicitante y a compras"` |

**Al completar**: `completedSections: [1, 2]`. Tabla de actores confirmada.

---

## Sección 3: Journeys

**La sección más compleja.** Cada tipo de actividad tiene preguntas específicas. Aquí se captura el flujo completo: happy path, caminos alternativos, gateways, errores.

**Regla clave:** En Sección 3 solo preguntar sobre el **qué** y **quién**, NO sobre el **cómo técnico** (eso es Secciones 4-5, cubiertas en stories 3.2 y 3.4).

### User Task → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué hace el {rol} en esta actividad?" | **SÍ** | `U: "Aprueba o rechaza la solicitud"` |
| "¿Quién puede ejecutarla? ¿Solo el {rol} o cualquiera con ese rol?" | **SÍ** | `U: "Solo el jefe directo del solicitante"` |
| "¿Tiene plazo para responder? ¿Qué pasa si no responde a tiempo?" | No | `U: "48 horas, si no responde va al gerente"` → registrar Expirable |
| "¿Tiene dos opciones (Aprobar/Rechazar) o más?" | **SÍ** | `U: "Aprobar, Rechazar, o Devolver para corrección"` |

**NO preguntar aquí:** Campos del formulario, validaciones, layout — eso es story 3.4.

### Exclusive Gateway → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Cuál es la condición de decisión?" | **SÍ** | `U: "Si el monto supera $10.000"` |
| "¿Cuántas ramas tiene?" | **SÍ** | `U: "Dos: aprobación normal y aprobación gerencial"` |
| "¿Cuál es el camino por defecto si ninguna condición se cumple?" | **SÍ** | `U: "El camino normal"` |
| "¿El valor {valor} puede cambiar?" (anti-pattern #3 Hardcoded) | No | `U: "Sí, puede cambiar"` → `S: "Lo registro como parámetro configurable"` |

### Parallel Gateway → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué pasos se ejecutan en paralelo?" | **SÍ** | `U: "Se envía email al cliente y se registra en el sistema al mismo tiempo"` |
| "¿Hay que esperar a que TODOS terminen o basta con uno?" | **SÍ** | `U: "Hay que esperar a los dos"` |
| "¿Qué pasa si uno de los paralelos falla?" | No | `U: "No sé"` → `S: "⚠️ Sin manejo de error para rama paralela. Seguimos."` |

### SQL Service Task → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué datos consulta o escribe en la base de datos?" | **SÍ** | `U: "Busca si el usuario tiene permiso de aprobador"` |
| "¿De qué base de datos o sistema?" | **SÍ** | `U: "De la base de RRHH"` |
| "¿Qué pasa si la consulta no encuentra datos?" | No | `U: "Se rechaza automáticamente"` → registrar gateway implícito |

**NO preguntar aquí:** Connection string, CommandText, CommandType — eso es story 3.2.

### REST Service Task → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿A qué sistema externo llama?" | **SÍ** | `U: "Al sistema de contabilidad"` |
| "¿Para qué? ¿Consulta datos, envía datos, o ambos?" | **SÍ** | `U: "Envía la orden para que la registre"` |
| "¿Qué pasa si el sistema externo no responde o falla?" | No | `U: "Hay que reintentar"` → registrar retry/timeout |

**NO preguntar aquí:** URL, método HTTP, headers, body — eso es story 3.2.

### Email/Send Task → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿A quién se envía el email?" | **SÍ** | `U: "Al solicitante"` |
| "¿Cuándo se envía? (¿después de qué paso?)" | **SÍ** | `U: "Cuando se aprueba la compra"` |
| "¿Es informativo o requiere acción del receptor?" | No | `U: "Solo informativo"` |

**NO preguntar aquí:** Asunto exacto, template HTML, servidor SMTP — eso es story 3.2.

### Send Message → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué subproceso se lanza?" | **SÍ** | `U: "El proceso de generación de orden de compra"` |
| "¿Es fire-and-forget o espera respuesta?" | **SÍ** | `U: "Fire-and-forget, sigue sin esperar"` |
| "¿Qué datos necesita el subproceso?" | No | `U: "El ID de la solicitud y el monto"` |

### Receive Message → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿De qué proceso o sistema espera un mensaje?" | **SÍ** | `U: "Del proceso de pagos"` |
| "¿El proceso se detiene a esperar o sigue haciendo otras cosas?" | **SÍ** | `U: "Se detiene hasta recibir confirmación"` |
| "¿Tiene timeout? ¿Qué pasa si nunca llega?" | No | `U: "Si no llega en 24hs, se cancela"` |

### Call Activity → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿A qué subproceso llama sincrónicamente?" | **SÍ** | `U: "Al proceso de validación de crédito"` |
| "¿Qué datos le pasa y qué recibe de vuelta?" | No | `U: "Le paso el ID del cliente, me devuelve si está habilitado"` |
| "¿Qué pasa si el subproceso falla?" | No | `U: "Se rechaza la solicitud"` |

### Timer/Delay → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Cuánto tiempo espera?" | **SÍ** | `U: "24 horas"` |
| "¿Por qué espera? ¿Es un plazo de negocio?" | No | `U: "Es el plazo legal para responder"` |
| "¿Se cuenta en horas hábiles o calendario?" | No | `U: "Horas hábiles"` → registrar en NFRs |

### For (Iteración) → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Sobre qué lista itera?" | **SÍ** | `U: "Los items de la solicitud de compra"` |
| "¿Qué se hace por cada item?" | **SÍ** | `U: "Se verifica stock y se reserva"` |
| "¿Puede haber 0 items? ¿Qué pasa en ese caso?" | No | `U: "No, siempre tiene al menos 1"` |
| "¿Hay máximo de items?" | No | `U: "No más de 100"` |

### Sequence (Try/Catch) → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Este grupo de pasos necesita manejo de error conjunto?" | No | `U: "Sí, si falla cualquiera de los 3 pasos, hay que notificar a IT"` |

**Nota:** El usuario rara vez describe un Try/Catch explícitamente. Se infiere cuando menciona error handling para un grupo de actividades.

### Expirable → Sección 3

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Cuánto tiempo tiene para completar esta tarea?" | **SÍ** | `U: "48 horas"` |
| "¿Qué pasa cuando vence?" | **SÍ** | `U: "Se escala al gerente"` → registrar ScheduledAction |
| "¿Hay aviso antes del vencimiento?" | No | `U: "Sí, un recordatorio a las 24hs"` → registrar WarningTime |

### Set Parameter → Sección 3

Normalmente no genera preguntas en Sección 3. Se infiere del flujo.

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Qué dato se calcula o transforma en este punto?" | No | `U: "Se arma el JSON con los datos del pedido"` |

### Exception → Sección 3

Normalmente no se describe explícitamente. Se infiere del manejo de errores.

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Cuándo se lanza esta excepción?" | No | `U: "Si la validación falla"` |
| "¿El proceso se detiene completamente o hay recuperación?" | No | `U: "Se detiene y notifica"` |

---


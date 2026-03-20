# Elicitation: Secciones 7-9 (NFRs, Decisiones, Auditoría) + Utilidades

> Extraído de elicitation-by-section.md. Nivel 3 de progressive disclosure.
> En draft-first: edge cases, NFRs, y decisiones pendientes.
> Incluye utilidades: orden de completedSections, inferencia de tipo, ejemplo, gotchas.

## Sección 7: NFRs

### Preguntas generales

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay SLAs o tiempos máximos para algún paso?" | No | `U: "El proceso completo no puede tardar más de 5 días"` |
| "¿Hay restricciones de rendimiento o concurrencia?" | No | `U: "Puede haber 100 solicitudes simultáneas"` |
| "¿Qué nivel de logging necesitás?" | No | `U: "Tracking completo de cada paso"` |

### Por tipo de actividad

#### User Task → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿El SLA de esta tarea es en horas hábiles o calendario?" | No | `U: "Horas hábiles"` → registrar CalendarRef |

#### Expirable → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Los plazos de vencimiento son en horas hábiles?" | **SÍ** | `U: "Sí, solo lunes a viernes"` |
| "¿Hay escalamiento multinivel?" | No | `U: "Sí, primero jefe, después gerente, después director"` |

#### REST Service Task → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay requisitos de reintentos para esta integración?" | No | `U: "3 reintentos con backoff"` |

#### SQL Service Task → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay requisitos de timeout para esta consulta?" | No | `U: "No más de 10 segundos"` |

#### Timer/Delay → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿La espera es en tiempo calendario o hábil?" | No | `U: "Calendario"` |

#### For (Iteración) → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay máximo de iteraciones?" | No | `U: "No más de 1000"` |

#### Parallel Gateway → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay timeout para esperar que todas las ramas terminen?" | No | `U: "No, espera indefinidamente"` |

#### Receive Message → Sección 7

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay timeout para la recepción del mensaje?" | No | `U: "72 horas máximo"` |

#### Exclusive Gateway / Email / Send Message / Sequence / Set Parameter / Exception / Call Activity → Sección 7

No generan preguntas específicas de NFRs.

---

## Sección 8: Decisiones y Restricciones

### Preguntas generales (siempre)

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay reglas de negocio que no mencionamos?" | No | `U: "Segregación de funciones: el que pide no puede aprobar"` |
| "¿Hay restricciones de seguridad?" | No | `U: "Solo gerentes pueden ver montos > $100.000"` |
| "¿Hay calendario laboral?" | No | `U: "Sí, lunes a viernes 9-18"` |
| "¿Hay algo más que debería saber?" | No | `U: "El proceso se congela en enero por auditoría"` |

### Por tipo de actividad

#### User Task → Sección 8

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay segregación de funciones? (ej: quien pide no puede aprobar)" | No | `U: "Sí, exactamente"` |
| "¿Hay restricciones de horario para esta tarea?" | No | `U: "Solo en horario laboral"` |

#### Exclusive Gateway → Sección 8

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Las condiciones de esta decisión pueden cambiar por regulación?" | No | `U: "Sí, los montos de aprobación los define compliance"` |

#### Send Message / Call Activity → Sección 8

| Pregunta | Bloqueante | Ejemplo |
|----------|------------|---------|
| "¿Hay restricciones sobre cuándo se puede llamar al subproceso?" | No | `U: "Solo en horario hábil porque el otro sistema baja de noche"` |

#### SQL / REST / Email / Parallel / Timer / For / Sequence / Expirable / Set Parameter / Receive Message / Exception → Sección 8

No generan preguntas específicas de decisiones. La información relevante ya fue capturada en secciones anteriores.

**Al completar**: guardar spec con `status: "complete"`, `completedSections: [1, 2, 3, 4, 6, 7, 8]`.

---

## Sección 9: Auditoría de Configuración — AUTO-GENERADA

**No se elicita.** Se genera automáticamente del análisis de las actividades.

7 tipos de detección auto-generada:

| # | Tipo | Fuente |
|---|------|--------|
| 1 | URLs hardcodeadas | REST con URL de servidor/ambiente específico |
| 2 | ConfigSettings requeridos | Parámetros con ApplicationSetting |
| 3 | Paths de filesystem | DefaultValue con paths de servidor |
| 4 | Connection strings inconsistentes | Nombres diferentes para misma conexión |
| 5 | Credentials presentes | Password con valor (aunque encriptado) |
| 6 | Subprocesos requeridos | EventName de SendMessage |
| 7 | DefaultValue con datos de ambiente | URLs o datos específicos en defaults |

---

## Detalle técnico — AUTO-GENERADO

**No se elicita.** Se genera automáticamente al completar la elicitación.

Cada actividad identificada recibe un bloque `#### detalle-{xname}` en `detalle-tecnico.md` con los atributos técnicos recopilados durante la elicitación.

---

## Orden de completedSections

Las secciones auto-generadas (5, 9, Detalle) no aparecen en `completedSections` porque se generan al final. El array final de un create completo es `[1, 2, 3, 4, 6, 7, 8]`.

---

## Inferencia de tipo de actividad

Cuando el usuario describe una actividad sin decir el tipo, inferir por palabras clave:

| Palabras clave del usuario | Tipo inferido |
|---|---|
| "aprueba", "revisa", "completa formulario", "carga datos", "el {rol} hace" | User Task |
| "si", "dependiendo de", "cuando el monto", "según el estado" | Exclusive Gateway |
| "al mismo tiempo", "en paralelo", "simultáneamente" | Parallel Gateway |
| "consulta la base", "busca en la tabla", "guarda en la DB", "graba" | SQL Service Task |
| "llama a la API", "consulta el servicio", "envía al sistema externo" | REST Service Task |
| "envía email", "notifica por mail", "manda un correo" | Email/Send Task |
| "lanza el proceso", "dispara un subproceso", "inicia otro proceso" | Send Message |
| "espera respuesta de", "hasta que llegue", "recibe mensaje" | Receive Message |
| "llama al subproceso y espera", "ejecuta sincrónicamente" | Call Activity |
| "espera", "después de N horas/días", "pausa" | Timer/Delay |
| "por cada item", "para cada uno", "itera sobre" | For (Iteración) |
| "si falla, entonces", "con manejo de error" | Sequence (Try/Catch) |
| "vence en", "tiene plazo", "si no responde en N horas" | Expirable |
| "calcula", "arma el JSON", "setea el parámetro" | Set Parameter |
| "termina con error", "lanza excepción", "aborta" | Exception |

**Si hay ambigüedad** → preguntar: "¿'{descripción}' es una tarea humana o una llamada a un sistema externo?"

---

## Ejemplo completo de diálogo

```
Skill: "¿Cómo se llama este proceso?"
User:  "Aprobación de compras"

Skill: "¿Qué problema de negocio resuelve?"
User:  "Las compras se hacen sin control, necesitamos aprobación gerencial"

Skill: "¿Qué evento lo dispara?"
User:  "Un formulario web donde el empleado carga el pedido"

Skill: "¿Quiénes participan?"
User:  "El empleado que pide, su jefe directo que aprueba, y el área de compras"

Skill: "¿Cuál es el resultado cuando termina exitosamente?"
User:  "Se genera la orden de compra en SAP"

Skill: "Resumo lo que tengo:
        - Proceso: Aprobación de compras
        - Objetivo: Control de compras con aprobación gerencial
        - Trigger: Formulario web (empleado carga pedido)
        - Actores: Empleado (solicitante), Jefe directo (aprobador), Compras
        - Resultado: Orden de compra en SAP
        ¿Correcto?"
User:  "Sí, correcto"

Skill: "Perfecto, Sección 1 guardada. Ahora los actores:
        ¿El jefe directo es siempre la misma persona o cambia según quién pide?"
User:  "Cambia, es el jefe del empleado que pide"

Skill: "¿Hay un sustituto si el jefe no está disponible?"
User:  "Sí, el gerente del área"

Skill: "Actores confirmados:
        | Actor | Rol | Participa en |
        | Empleado | Solicitante | Carga pedido |
        | Jefe directo | Aprobador | Aprueba/Rechaza solicitud |
        | Gerente | Sustituto aprobador | Aprueba si jefe no disponible |
        | Compras | Ejecutor | Genera orden en SAP |
        ¿Correcto?"
User:  "Sí"

Skill: "Sección 2 guardada. Ahora los journeys.
        Describí el flujo paso a paso del camino exitoso."
User:  "El empleado carga el pedido, el jefe lo aprueba, compras verifica stock
        y si hay stock genera la orden en SAP y le avisa al empleado por email"

Skill: "Detecté al menos 5 actividades. Vamos una por una:

        1. 'Cargar pedido' — parece una tarea humana (User Task). ¿Correcto?"
User:  "Sí"

Skill: "¿Qué campos tiene el formulario? Solo los principales."
User:  "Proveedor, descripción del producto, cantidad, monto estimado"

Skill: "2. 'Aprobar solicitud' — tarea humana del jefe. ¿Opciones?"
User:  "Aprobar o Rechazar"

Skill: "¿Tiene plazo para responder?"
User:  "48 horas, si no responde va al gerente"

Skill: [detecta Expirable, registra 48hs + escalamiento]
       "3. 'Verificar stock' — ¿es una consulta a base de datos o a un sistema externo?"
User:  "Consulta a la base de datos de inventario"

Skill: [infiere SQL Service Task]
       "4. Parece que hay una decisión: 'si hay stock'. ¿Qué pasa si NO hay stock?"
User:  "Se rechaza y se avisa al empleado"

Skill: [registra Exclusive Gateway + camino alternativo]
       "5. 'Generar orden en SAP' — ¿es una llamada a una API de SAP?"
User:  "Sí"

Skill: [infiere REST Service Task]
       "6. 'Avisar al empleado' — ¿es un email?"
User:  "Sí"

Skill: [infiere Email/Send Task]
       [detecta anti-pattern #2: No Error Handling]
       "¿Qué pasa si SAP no responde cuando se intenta generar la orden?"
User:  "Se reintenta 1 vez. Si falla, se notifica a IT por email"

Skill: "Inferí 3 journeys:
        Journey 1: Compra aprobada [Happy Path]
          Steps: Cargar pedido → Aprobar → Verificar stock → Generar orden SAP → Email confirmación
          ACs: Si el jefe aprueba y hay stock, se genera la orden en SAP
               Si la orden se genera exitosamente, se envía email al empleado

        Journey 2: Compra rechazada
          Steps: Cargar pedido → Rechazar → Email rechazo
          ACs: Si el jefe rechaza, se notifica al empleado

        Journey 3: Sin stock
          Steps: Cargar pedido → Aprobar → Verificar stock (sin stock) → Email sin stock
          ACs: Si no hay stock, se rechaza automáticamente y se notifica

        ¿Falta algún camino?"
User:  "Falta el caso de timeout del jefe"

Skill: "Journey 4: Timeout de aprobación
          Steps: Cargar pedido → Timeout 48hs → Escalar a gerente → Aprobar/Rechazar
          ACs: Si el jefe no responde en 48hs, se escala al gerente

        ¿Correcto?"
User:  "Sí, perfecto"

Skill: "Secciones 1-3 completas. Guardado en processes/{org}/aprobacion-de-compras/spec.md
        7 actividades, 4 journeys, 6 ACs.
        Próximo: Sección 4 (Funcionalidades) en la siguiente sesión."
```

---

## Gotchas

- No asumir datos que el usuario no dio (NFR35)
- Si el proceso es automático (sin interacción humana), saltar preguntas de roles/forms/SLAs humanos (FR52)
- Si el usuario pregunta "¿por qué me preguntás eso?", explicar con contexto (FR53)
- La elicitación de Sección 3 (Journeys) es la más larga — puede tomar varias sesiones con progreso guardado
- Las secciones 5, 9 y Detalle técnico NO se elicitan — se auto-generan
- Sección 3 solo captura el **qué** y **quién** — los detalles técnicos (connection strings, URLs, fields) van en stories 3.2 y 3.4
- Cuando el usuario describe algo de una sección posterior mientras estás en otra → registrar en el lugar correcto, no forzar orden
- La tabla de inferencia de tipos es orientativa — siempre confirmar con el usuario si hay ambigüedad

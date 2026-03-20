# Anti-Patterns

> Rule genérica SDD — patrones problemáticos a detectar durante elicitación.

## Cuándo aplica

Cargada por `workflows/create.md` durante la elicitación (Sección 3: Journeys especialmente). El skill detecta estos patrones en la descripción del usuario y advierte proactivamente.

## Los 5 Anti-Patterns

### 1. God Process

**Trigger**: el usuario describe más de **50 actividades** en 1 proceso sin subprocesos.
**Detección**: contar actividades durante elicitación de Sección 3 (Journeys).
**Respuesta**: "Este proceso tiene {N} actividades. ¿Se podría dividir en subprocesos que se llamen entre sí? Los procesos de más de 50 actividades son difíciles de mantener y testear."

> Threshold: 50 actividades (definido en PRD — NO usar 30)

### 2. No Error Handling

**Trigger**: el usuario termina de describir journeys de Sección 3 sin mencionar qué pasa si algo falla.
**Detección**: al finalizar Sección 3, verificar si hay menciones de "falla", "error", "timeout", "catch", "excepción" en las actividades.
**Respuesta**: "No mencionaste qué pasa si algo falla. ¿Agregamos manejo de errores? Por ejemplo: ¿qué pasa si la consulta SQL falla? ¿Qué pasa si la API externa no responde?"

### 3. Hardcoded Values

**Trigger**: el usuario describe condiciones con valores fijos que podrían cambiar.
**Detección**: condiciones de gateway con números literales (ej: "si el monto es mayor a 10000").
**Respuesta**: "¿El valor $10,000 podría cambiar en el futuro? Si sí, conviene que sea un parámetro configurable en vez de un valor fijo en la condición."

### 4. Single Point of Failure

**Trigger**: una sola persona/rol puede ejecutar un paso crítico sin sustituto.
**Detección**: actividad de aprobación con 1 solo rol asignado, sin escalamiento.
**Respuesta**: "¿Qué pasa si esa persona está de vacaciones o enferma? ¿Hay un sustituto o escalamiento?"

### 5. Sync When Async

**Trigger**: el proceso espera sincrónicamente la respuesta de un sistema externo en un flujo crítico.
**Detección**: actividad REST/SQL que bloquea el flujo sin timeout ni retry.
**Respuesta**: "Si la API de {sistema} demora o no responde, el proceso se bloquea. ¿Conviene hacerlo asincrónico con retry? ¿O al menos definir un timeout?"

## Ejemplo

```
User: "El empleado carga la solicitud, después el jefe la aprueba,
       después se genera la orden en SAP, y listo"

Skill: [detecta #2 No Error Handling]
"¿Qué pasa si SAP no responde cuando se intenta generar la orden?
 Los procesos sin manejo de errores se quedan trabados indefinidamente."

User: "Ah, buena pregunta. Si falla, notificar a IT"

Skill: [registra error handling para la actividad de SAP]
```

## Anti-Patterns Técnicos (Sección 4 — Story 3.3)

Detectados durante la elicitación de detalles técnicos:

### 6. Hardcoded ID in Query

**Trigger**: query SQL con ID literal (ej: `WHERE cliente_id = 8523`).
**Detección**: valor numérico literal en condición SQL descrita por el usuario.
**Respuesta educativa**: "Si el proceso se reutiliza para otro cliente, hay que modificar la query manualmente. ¿Querés que `{valor}` sea un parámetro de entrada? Así funciona para cualquier cliente sin tocar el proceso."

### 7. No SLA with Regulation

**Trigger**: el usuario menciona regulación ("el banco exige", "según la ley", "normativa") sin definir SLA.
**Detección**: frases de regulación sin timer o Expirable asociado.
**Respuesta educativa**: "Mencionaste una regulación. ¿Hay un plazo legal para completar este paso? Si sí, conviene modelar un timer para que el proceso lo controle automáticamente."

## Contexto Educativo

Cada anti-pattern se comunica con **impacto real**, no con jerga técnica:

| Anti-Pattern | Explicación educativa (impacto real) |
|---|---|
| God Process | "Los procesos con más de 50 actividades son difíciles de mantener. Cuando hay un bug, encontrarlo lleva horas. Dividir en subprocesos hace que cada parte sea testeable y modificable por separado." |
| No Error Handling | "Sin manejo de errores, si algo falla el proceso se queda 'colgado' en producción y nadie se entera hasta que un usuario se queja." |
| Hardcoded Values | "Los valores fijos funcionan hasta que el negocio cambia. Si el umbral de aprobación sube de $10.000 a $15.000, hay que tocar el proceso. Un parámetro permite cambiarlo desde la configuración." |
| Single Point of Failure | "Si la única persona que puede aprobar se enferma o se va de vacaciones, el proceso se traba. Un sustituto garantiza que el negocio no se frene." |
| Sync When Async | "Si el proceso espera indefinidamente a un sistema externo y ese sistema no responde, el proceso se bloquea y nadie puede hacer nada." |
| Hardcoded ID in Query | "Si la query tiene un ID fijo, el proceso solo funciona para ese caso. Un parámetro permite reutilizarlo." |
| No SLA with Regulation | "Si hay un plazo legal y no lo modelamos, el proceso podría incumplir la norma sin que nadie se dé cuenta." |

## Gotchas

- Los anti-patterns se detectan DURANTE la elicitación, no después — son proactivos
- No son BLOCKERs — el skill advierte pero el usuario puede continuar
- El threshold de God Process es 50, no 30 (corregido en adversarial review)
- No confundir anti-patterns (detección en create, Sección 3) con anomalías (detección en reverse) — son archivos diferentes
- Las explicaciones educativas se dan UNA vez por anti-pattern — si se repite, solo confirmar: "¿Confirmás que querés mantener {patrón}?"
- Si el usuario dice "no" a la sugerencia → documentar como WARNING en spec y seguir adelante

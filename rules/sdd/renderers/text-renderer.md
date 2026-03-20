# Text Renderer — Indented List

## Qué hace

Convierte un ProcessFlowJSON en representación de texto indentado legible en terminal. Es el renderer por defecto (CLI safe, funciona en cualquier contexto).

## Cuándo se usa

- Default para CLI (sin flag o `--visual text`)
- Fallback si Mermaid rendering falla (NFR53)

## Formato de output

```
📊 Flujo del Proceso: {processName} v{version}

→ Inicio (startEvent)
  → {Label} ({type}) [{Actor}] [form: {N} controles]
  → ¿{condición}? (exclusiveGateway)
    → [Sí] {Label} ({type})
    → [No] {Label} ({type})
    → [Default] {Label} ({type})
  → {ContainerLabel} ({containerType})
    → {Child1} ({type})
    → {Child2} ({type})
→ Fin (endEvent)

📋 Test Paths ({N}):
  1. {name} [{type}]: {nodo1} → {nodo2} → ... → {nodoN}
  2. ...

⚠️ Anomalías ({N}):
  🔴 {actividad}: {mensaje}
  ⚠️ {actividad}: {mensaje}

📈 Resumen: {N} actividades, {N} gateways, {N} actores, {N} test paths, {N} anomalías
```

## Reglas de rendering

### Indentación
- 2 espacios por nivel de nesting
- Start/End: nivel 0
- Actividades top-level: nivel 1
- Contenido de containers: nivel 2+
- Sin límite de profundidad

### Formato por tipo de nodo

| Tipo | Formato |
|---|---|
| startEvent | `→ Inicio (startEvent)` |
| endEvent | `→ Fin (endEvent)` |
| userTask | `→ {Label} (userTask) [{Actor}] [form: {N} controles]` |
| serviceTask | `→ {Label} (serviceTask/{subtype})` donde subtype = SQL/REST/Email/Script |
| exclusiveGateway | `→ ¿{condición}? (exclusiveGateway)` |
| parallelGateway | `→ ║ Paralelo (parallelGateway)` |
| ifElseBranch | rama con prefijo `[Sí]`/`[No]`/`[Default]` |
| forLoop | `→ ∀ {Label} (forLoop)` |
| sequence | `→ ⟹ {Label} (sequence)` |
| exceptionHandler | `→ ⚡ {Label} (exceptionHandler)` |
| timer | `→ ⏱️ {Label} (timer)` |
| sendMessage | `→ 📤 {Label} (sendMessage)` |
| receiveMessage | `→ 📥 {Label} (receiveMessage)` |
| unknown | `→ ⚠️ {Label} (unknown — no parseada)` |

### Anomalías en nodos

Si un nodo tiene anomalías, agregar indicador después del tipo:
- severity error: `→ {Label} ({type}) 🔴 {mensaje corto}`
- severity warning: `→ {Label} ({type}) ⚠️ {mensaje corto}`

### Modo compacto (>20 actividades)

Cuando `metadata.activityCount > 20`:
- Containers con `collapsed: true` se muestran como: `→ [+{N} actividades en {label}]`
- El usuario puede re-ejecutar con `--expand-all` para ver todo

### Sección Test Paths

Después del diagrama, listar test paths numerados:
```
📋 Test Paths ({testPathCount}):
  1. {name} [{type}]: {nodo1} → {nodo2} → ... → {nodoN}
```

Si 0 test paths: `📋 Test Paths: ninguno definido`

### Sección Anomalías

Después de test paths, listar anomalías agrupadas por severidad:
```
⚠️ Anomalías ({anomalyCount}):
  🔴 {nodeLabel}: {message}
  ⚠️ {nodeLabel}: {message}
```

Si 0 anomalías: `✅ Sin anomalías detectadas`

### Resumen

Última línea: `📈 Resumen: {activityCount} actividades, {gatewayCount} gateways, {actorCount} actores, {testPathCount} test paths, {anomalyCount} anomalías`

## Sanitización de nombres

Para texto indentado, la sanitización es mínima (no hay syntax que romper):
- Tildes (á, é, í, ó, ú, ñ) → mantener
- Tabs → reemplazar por espacio
- Newlines dentro de label → reemplazar por " — "
- Todos los demás caracteres → mantener tal cual

## Casos especiales

- Proceso con 0 actividades: `→ Inicio → Fin` + "Proceso sin actividades"
- Spec parcial: agregar `⚠️ Spec parcial — visual puede estar incompleto` como primera línea
- ProcessFlowJSON con `partial: true`: agregar warning de parcialidad

## Gotchas

- El renderer recibe ProcessFlowJSON ya validado. No re-valida.
- Si un nodo tiene children vacíos, no indentar (es leaf node)
- Los edges no se muestran explícitamente en texto indentado — el orden implica la secuencia
- Los gateway branches se ordenan: condiciones explícitas primero, default al final

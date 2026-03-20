# Stakeholder Views — Vistas por Rol

## Qué hace

Genera vistas del proceso adaptadas al rol del destinatario. Cada vista es una transformación (no un resumen) de la spec + ProcessFlowJSON.

## Cuándo se usa

- `--view executive` o "vista ejecutiva" o "resumen para gerencia"
- `--view qa` o "vista QA" o "vista para testing"
- v2 (futuro): `--view compliance`, `--view onboarding`

## Vista Ejecutiva

### Invocación
`--view executive`, "vista ejecutiva", "resumen para gerencia", "vista para el directorio"

### Contenido (≤1 página, ~500 palabras)

```
📊 Vista Ejecutiva: {processName} v{version}
Organización: {org}
Última modificación: {date}

## Diagrama Simplificado
[Diagrama con solo happy path + gateways principales. No todas las ramas.]
[Usar ProcessFlowJSON filtrado: solo nodos del test path tipo "happy" + gateways principales]

## KPIs del Proceso
| Métrica | Valor |
|---|---|
| Actividades | {activityCount} |
| Actores | {actorCount} ({lista nombres}) |
| Test Paths | {testPathCount} |
| SLAs definidos | {count SLAs en spec} |
| Anomalías | {anomalyCount} ({errorCount} error, {warningCount} warning) |

## Anomalías Principales
[Top 3 por severidad. Si >3: "y {N} más"]
[Si 0: "✅ Sin anomalías detectadas"]
  🔴 {actividad}: {mensaje}
  ⚠️ {actividad}: {mensaje}

## Estado
[Health status del proceso: 🟢/🟡/🔴 con criterio]
```

### Reglas
- **≤1 página máximo** (~60 líneas o ~500 palabras). Si el proceso es grande, comprimir
- Solo happy path en diagrama (no todas las ramas)
- KPIs: siempre ≥3 (actividades, actores, y al menos 1 más)
- Si 0 anomalías: "✅ Sin anomalías detectadas"
- Si 0 test paths: "Test Paths: no definidos"
- Si 0 actores: "Actores: no definidos"
- Exportable como HTML via `html-export.md`

## Vista QA

### Invocación
`--view qa`, "vista QA", "vista para testing", "qué testear"

### Contenido

```
🧪 Vista QA: {processName} v{version}

## Diagrama Completo con Test Paths
[Diagrama COMPLETO (no simplificado)]
[Cada test path resaltado con color distinto si Mermaid, o listado junto al diagrama si texto]

## Test Paths ({testPathCount})

### Camino 1: {name} [{type}]
Nodos: {nodo1} → {nodo2} → ... → {nodoN}
Datos de prueba sugeridos:
  - {paramName} = {valorSugerido} (para triggear condición "{condición}")
  - {paramName} = {valorAlternativo} (para NO triggear)

### Camino 2: ...
[Repetir para cada test path]

## Cobertura
{X} de {Y} nodos cubiertos por test paths ({Z}%)
Nodos no cubiertos: {lista}

## Checklist de Anomalías
☐ Verificar {descripción anomalía} en actividad {nombre}
☐ ...

## Checklist QA General
☐ Happy path funciona end-to-end
☐ Cada gateway tiene default flow
☐ Cada UserTask tiene form funcional
☐ Cada timeout tiene valor razonable
☐ Sin passwords hardcodeados en SQL
```

### Datos de Prueba — Lógica de Inferencia

Para cada condición de gateway en un test path, sugerir datos:

| Tipo de condición | Dato "cumple" | Dato "no cumple" |
|---|---|---|
| `{param} > {valor}` | `{param} = {valor + delta}` | `{param} = {valor - delta}` |
| `{param} < {valor}` | `{param} = {valor - delta}` | `{param} = {valor + delta}` |
| `{param} >= {valor}` | `{param} = {valor}` | `{param} = {valor - 1}` |
| `{param} == {valor}` | `{param} = {valor}` | `{param} = {alternativa}` |
| `{param} != {valor}` | `{param} = {alternativa}` | `{param} = {valor}` |
| `IsEmpty({param})` | `{param} = ""` | `{param} = "test"` |
| `HasValue({param})` | `{param} = "test"` | `{param} = ""` |
| Compuesta (AND) | Combinación que cumple todas | Al menos 1 que no cumple |
| No parseable | "Dato de prueba: verificar manualmente" | — |

`delta` = 10% del valor o 1 si es entero. Ejemplo: `Monto > 500000` → dato = 550000 / dato = 100000.

### Reglas
- Diagrama COMPLETO (no simplificado como ejecutiva)
- Todos los test paths listados (no truncar)
- Datos de prueba sugeridos por path
- Cobertura calculada: nodos en al menos 1 path / total nodos
- Anomalías como checklist ☐ (no solo texto)
- Si 0 test paths: "No hay test paths definidos. Ejecutar validate para generarlos."
- Exportable como HTML

## Edge Cases Comunes

- **Spec sin test paths:** Vista QA dice "No hay test paths. Ejecutar validate."
- **Spec sin anomalías:** "✅ Sin anomalías" en ambas vistas
- **Proceso lineal (1 camino):** 1 test path, 100% cobertura
- **20 test paths:** Listar todos, no truncar
- **50+ actividades en ejecutiva:** Diagrama simplificado sigue ≤1 página (collapsing agresivo)
- **Spec parcial:** Mostrar lo disponible + "Secciones pendientes: {lista}. Completitud: {N}%"
- **0 test paths y 0 anomalías:** Vista minimalista con solo KPIs básicos

## Gotchas

- Vista ejecutiva y QA son TRANSFORMACIONES distintas, no niveles de detalle del mismo output
- La ejecutiva OMITE detalle técnico. La QA lo AMPLÍA con datos de prueba
- Las vistas consumen ProcessFlowJSON + datos de la spec (no solo PFJSON)
- Exportar como HTML usa `html-export.md` con las secciones de la vista

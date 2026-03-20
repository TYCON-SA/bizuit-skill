# Visual Output — Orchestrador

## Qué hace

Orchestrador que coordina la generación de representación visual del flujo del proceso. Genera ProcessFlowJSON desde la spec y delega al renderer apropiado según contexto.

## Cuándo aplica

Se invoca como post-processing hook al final de cada workflow (reverse, create, edit, query):

```
Al completar el flujo principal sin errores:
1. Generar ProcessFlowJSON aplicando rules/sdd/process-flow-json.md
2. Seleccionar renderer según contexto (ver abajo)
3. Renderizar y presentar al usuario
4. Si error en cualquier paso: output textual ya generado permanece. Warning: "No se pudo generar visualización — output textual disponible"
```

**CRÍTICO:** El hook NO se ejecuta si el workflow falló. El output textual del workflow es el output principal — el visual es complementario.

## Selección de renderer

### Default: Mermaid

| Flag | Renderer | Formato |
|---|---|---|
| (sin flag) | `renderers/mermaid-renderer.md` | Mermaid flowchart (default) |
| `--visual text` | `renderers/text-renderer.md` | Texto indentado |
| `--visual mermaid` | `renderers/mermaid-renderer.md` | Mermaid (forzar, sobreescribe threshold) |
| `--no-visual` | Ninguno | Sin visual output |

Default = Mermaid. Funciona nativamente en Claude App (artifacts) y VS Code. En CLI terminal se muestra como syntax Mermaid plana — CLI users pueden usar `--visual text` para texto indentado. Flags siempre se respetan.

### Nota sobre auto-detection

Epic 14 (v1.4.0) cambió default de texto a Mermaid (ADR VIS-8). Esto es un default optimizado para el contexto mayoritario (Claude App/VS Code), no auto-detection runtime. Auto-detection runtime real diferida a futuro si Claude expone API de contexto de ejecución.

## Timing por workflow

| Workflow | Cuándo generar | Generaciones |
|---|---|---|
| reverse | Post-spec generation (spec completa en disco) | 1 |
| create | Post-BPMN generation (spec confirmada + BPMN listo) | 1 |
| edit | Pre-edit (baseline PFJSON) + post-edit (nuevo PFJSON) | 2 |
| query | Solo si usuario pide visual ("mostrar flujo", "diagrama") | 0-1 |

### Nota sobre edit

En edit, se generan 2 ProcessFlowJSONs:
1. **Before:** al leer la spec existente (antes de modificaciones)
2. **After:** post-edit (después de aplicar cambios)

Ambos se retienen en memoria (no en disco) para el diff-renderer.

## Modo compacto (procesos grandes)

### Threshold
- Proceso con `metadata.activityCount > 20` → activar modo compacto automáticamente
- Threshold es default. Configurable en futuro via `.bizuit-config.yaml`

### Reglas de collapsing
- Solo containers (IfElse, For, Sequence, Exception) se pueden colapsar
- Colapsar containers con ≥3 actividades internas
- Containers con 1-2 actividades: siempre expandidos
- Override: flag `--expand-all` desactiva collapsing

### Cómo marcar en ProcessFlowJSON
- Antes de pasar al renderer: si activityCount > 20, recorrer nodos y marcar `collapsed: true` en containers con ≥3 children

## Flujo completo

```
Spec (en disco)
    ↓
[1] Generar ProcessFlowJSON (rules/sdd/process-flow-json.md)
    ↓
[2] Validar PFJSON (nodos ≥2, edges válidos, no ciclos)
    ↓
[3] Si activityCount > 20 → marcar collapsed en containers
    ↓
[3.5] Threshold Mermaid: contar nodos visibles post-collapsing.
      Si >30 nodos visibles Y no hay flag explícito --visual mermaid
      → forzar text-renderer (diagrama Mermaid sería ilegible).
      Flag explícito --visual mermaid sobreescribe este threshold.
    ↓
[4] Seleccionar renderer (flag > threshold > default Mermaid)
    ↓
[5] Renderizar (mermaid-renderer.md o text-renderer.md)
    ↓
[6] Presentar output visual al usuario
```

## Errores y fallbacks

| Error | Acción |
|---|---|
| Spec sin actividades | Retornar "No se detectaron actividades para visualizar" |
| PFJSON generation falla | Warning + output textual del workflow ya disponible (NFR51) |
| Renderer falla (ej: Mermaid syntax error) | Fallback a text-renderer + warning (NFR53) |
| Flag inválido | Warning "formato no reconocido, usando Mermaid" + fallback Mermaid (default) |

## Integración en workflows

**CRÍTICO:** La instrucción de visual output debe estar **DENTRO del paso final** de cada workflow, NO como sección separada al final del archivo. Las secciones fuera del flujo de pasos no se ejecutan automáticamente.

**Patrón correcto:** Dentro del último paso del workflow (ej: "Paso 8 — Confirmar y Visualizar" en reverse.md), agregar instrucción imperativa:

```
**INMEDIATAMENTE después del resumen**, generar y mostrar representación
visual del flujo del proceso aplicando `rules/sdd/visual-output.md`.
Esto es OBLIGATORIO — no esperar a que el usuario lo pida.
```

## Lanes (Epic 15)

El visual output (Mermaid/texto indentado) **NO muestra lanes** en v1. Los renderers actuales generan diagramas planos independientemente de si el proceso tiene lanes.

Si el spec tiene `lanes: true` en frontmatter, agregar nota al final del visual output:

```
Nota: el diagrama no muestra la organización por carriles.
Ver sección ## Lanes en el spec para el mapping completo.
```

Soporte de lanes en Mermaid (via subgraphs) sería una Epic futura.

## Gotchas

- El visual output es COMPLEMENTARIO — nunca reemplaza el output textual del workflow
- En query, el visual es opt-in (no automático) — muchas queries son textuales
- El ProcessFlowJSON no se persiste — se genera cada vez. Si se necesita otra vez, se regenera
- El modo compacto modifica los nodos del PFJSON (agrega collapsed flag) — esto es in-memory, no afecta la spec
- **Lanes no se muestran en visual v1** — ver sección Lanes arriba

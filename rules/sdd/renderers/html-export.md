# HTML Export — SVG Inline

## Qué hace

Exporta cualquier visualización como archivo HTML self-contained con SVG inline. Funciona offline en cualquier browser. <50KB.

## Cuándo se usa

- Comando "exportar" / "export" / "compartir como HTML"
- Exportar vista ejecutiva, vista QA, diff visual, o cualquier output visual

## Algoritmo

1. Tomar el ProcessFlowJSON actual (ya generado por visual-output.md)
2. Generar SVG del diagrama: nodos como `<rect>`/`<circle>`/`<polygon>`, edges como `<path>`/`<line>`, labels como `<text>`. No requiere librería externa — Claude genera SVG como texto XML
3. Embeber SVG inline en template HTML
4. Agregar CSS de `templates/shared-styles.css` inline (si existe, sino defaults)
5. Agregar header con metadata y warning de confidencialidad
6. Guardar como `{processName}-visual.html` en el directorio del proceso

## Template HTML

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{processName}} — bizuit-sdd</title>
  <style>
    /* shared-styles.css inline */
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin: 2rem; color: #333; }
    header { border-bottom: 2px solid #2196F3; padding-bottom: 1rem; margin-bottom: 2rem; }
    h1 { color: #1565C0; margin: 0; }
    .subtitle { color: #666; margin: 0.5rem 0; }
    .warning { background: #FFF3E0; border-left: 4px solid #FF9800; padding: 0.75rem 1rem; margin: 1rem 0; font-size: 0.9em; }
    .metadata { color: #999; font-size: 0.85em; margin-top: 2rem; }
    svg { max-width: 100%; height: auto; }
    .changes-table { width: 100%; border-collapse: collapse; margin: 1rem 0; }
    .changes-table th, .changes-table td { border: 1px solid #ddd; padding: 0.5rem; text-align: left; }
    .changes-table th { background: #f5f5f5; }
  </style>
</head>
<body>
  <header>
    <h1>{{processName}}</h1>
    <p class="subtitle">Versión {{version}} — {{org}}</p>
    <p class="metadata">Generado por bizuit-sdd v{{skillVersion}} — {{date}}</p>
  </header>

  <div class="warning">
    ⚠️ Este archivo contiene información del proceso. Compartir solo con personas autorizadas.
  </div>

  <main>
    {{svgContent}}
  </main>

  {{#if changesTable}}
  <section>
    <h2>Cambios</h2>
    {{changesTable}}
  </section>
  {{/if}}

  {{#if testPaths}}
  <section>
    <h2>Test Paths</h2>
    {{testPaths}}
  </section>
  {{/if}}

  {{#if anomalies}}
  <section>
    <h2>Anomalías</h2>
    {{anomalies}}
  </section>
  {{/if}}

  <footer class="metadata">
    <p>📈 {{activityCount}} actividades, {{gatewayCount}} gateways, {{actorCount}} actores</p>
    <p>Generado automáticamente — no editar manualmente</p>
  </footer>
</body>
</html>
```

## SVG Generation

Claude genera SVG directamente como texto XML. No requiere Mermaid JS ni D3.js.

### Layout

- Dirección: top-to-bottom (como los procesos BPM)
- Nodos: espaciado vertical 80px, horizontal 200px
- Start/End: círculos (`<circle>`)
- Tasks: rectángulos redondeados (`<rect rx="8">`)
- Gateways: diamantes (`<polygon>`)
- Edges: paths con flechas (`<marker>`)

### Colores

Usar los mismos colores que Mermaid classDefs:
- added: #4CAF50
- removed: #f44336
- modified: #FFC107
- unchanged: #E0E0E0
- active (test path): #2196F3

## Nombre del archivo

`{processName}-visual.html`

Si es diff: `{processName}-diff-v{before}-v{after}.html`
Si es vista: `{processName}-executive.html` o `{processName}-qa.html`

Sanitizar nombre: reemplazar espacios con `-`, remover chars especiales.

## Edge Cases

- Export de proceso con 50+ actividades → modo compacto en SVG
- File path con espacios → sanitizar
- Directorio no existe → crear
- Sin visual generado → generar primero, luego exportar
- Export de diff → incluir changesTable en HTML
- Export de stakeholder view → incluir secciones según la vista

## Gotchas

- SVG es texto XML — no binario. Claude lo genera directamente
- El HTML es self-contained — no tiene dependencias externas
- Target <50KB para procesos de hasta 30 actividades
- El warning de confidencialidad es OBLIGATORIO — siempre visible
- No incluir Mermaid JS en el HTML — solo SVG inline

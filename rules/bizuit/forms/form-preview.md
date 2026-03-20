# Form Preview — Estructural

## Qué hace

Genera HTML que muestra la estructura de un formulario BizuitForms: controles con tipo, label, binding a parámetros, y jerarquía de containers/tabs/steppers. Nivel 2 (layout con jerarquía), no pixel-perfect.

## Cuándo se usa

- Invocable con "form preview", "preview del formulario", "mostrar form" sobre un proceso con forms generados
- Post-create o post-reverse si el usuario pide ver el form
- Como parte de la vista QA (stakeholder views)

## Input

Form JSON extraído de:
- `bizuit:serializedForm` del BPMN generado (create/edit)
- Element `<Design>` del VDW (reverse)
- Sección "Forms" de la spec

## Output — HTML Estructural

### Layout

```html
<div class="form-preview">
  <header>
    <h2>{displayName del UserTask}</h2>
    <p class="subtitle">{nombre del proceso}</p>
    <p class="disclaimer">⚠️ Preview estructural — el rendering final puede variar en estilo</p>
  </header>

  <div class="form-grid" style="display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px;">
    <!-- Controles renderizados según tipo -->
  </div>

  <div class="form-buttons" style="text-align: right;">
    <!-- Botones -->
  </div>

  <footer class="form-legend">
    <h4>Leyenda de tipos</h4>
    <!-- Iconos + nombres de tipos presentes -->
  </footer>
</div>
```

### Grid de 6 columnas

Simula el layout real de BizuitForms:

| Tipo de control | Columnas | Icono |
|---|---|---|
| InputTextbox | 3 | 📝 |
| Combobox | 3 | 📋 |
| Checkbox | 2 | ☑️ |
| RadioButton | 2 | 🔘 |
| DatePicker | 2 | 📅 |
| SlideToggle | 2 | 🔀 |
| Textarea | 6 | 📄 |
| DocumentInput | 6 | 📎 |
| Table | 6 | 📊 |
| Signature | 6 | ✍️ |
| Geolocation | 6 | 📍 |
| Container | 6 (wrapper) | 📦 |
| Tab / TabChild | 6 (wrapper) | 📑 |
| Stepper | 6 (wrapper) | 🔢 |
| Header | 6 | 🏷️ |
| Label | 3 | 🏷️ |
| Card | 6 (wrapper) | 🃏 |
| Media | 6 | 🖼️ |
| Iframe | 6 | 🌐 |
| SubForm | 6 | 📋 |
| Button | 2 (right-aligned) | 🔘 |
| AddToGridButton | 2 | ➕ |
| Desconocido | 3 (genérico) | ❓ |

### Rendering por tipo de control

Cada control se renderiza como:

```html
<div class="control" style="grid-column: span {cols};">
  <div class="control-header">
    <span class="type-icon">{icono}</span>
    <span class="control-label">{label}</span>
  </div>
  <div class="control-body">
    <div class="placeholder" style="border: 1px dashed #ccc; padding: 8px; border-radius: 4px;">
      {tipo}: {label}
    </div>
  </div>
  <div class="control-binding" style="font-size: 0.8em; color: #666;">
    📎 DS: {dataSourceName} → {bindingPath}
  </div>
</div>
```

### Containers (jerarquía)

Containers (Container, Tab, Stepper, Card) se renderizan como wrappers:

```html
<div class="container" style="grid-column: span 6; border: 2px solid #2196F3; padding: 12px; border-radius: 8px;">
  <h3>{containerLabel} ({containerType})</h3>
  <div class="form-grid" style="display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px;">
    <!-- Children controles -->
  </div>
</div>
```

### StepperComponent

```html
<div class="stepper" style="grid-column: span 6;">
  <div class="stepper-header">
    🔢 Stepper: {N} steps
  </div>
  <div class="stepper-steps">
    <div class="step">
      <h4>Step 1: {stepName}</h4>
      <!-- Children del step -->
    </div>
    <div class="step">
      <h4>Step 2: {stepName}</h4>
      <!-- Children del step -->
    </div>
  </div>
</div>
```

### Botones

```html
<div class="form-buttons" style="grid-column: span 6; text-align: right; margin-top: 16px;">
  <button class="btn-secondary">Cancelar</button>
  <button class="btn-primary">Enviar</button>
</div>
```

### Legend (footer)

Solo lista los tipos de control PRESENTES en el form:

```html
<footer class="form-legend">
  <h4>Leyenda</h4>
  <ul>
    <li>📝 InputTextbox — Campo de texto</li>
    <li>📋 Combobox — Selección desplegable</li>
    <li>☑️ Checkbox — Casilla de verificación</li>
    ...solo los presentes...
  </ul>
</footer>
```

## Datos de binding

Si el control tiene binding a DataSource:
- Mostrar indicador: `📎 DS: {dataSourceName} → {path}`
- Si no tiene binding: no mostrar indicador
- Si NINGÚN control tiene binding: warning al final: "⚠️ Controles sin bindings — verificar configuración"

## DataSources

Listar DataSources configurados como sección antes de los controles:

```
📊 DataSources:
  1. Parámetros y Variables (Primary) — {N} parámetros
  2. Actividades Anteriores — {N} parámetros (solo en UserTasks, no en StartEvent)
  3. {SqlDataSource nombre} — connectionSource: Configuration
```

## Edge Cases

- **Form sin controles:** "Form vacío — sin controles definidos"
- **Form con solo botones:** Mostrar solo sección de botones
- **StepperComponent:** Mostrar steps con nombre y contenido
- **Control de tipo desconocido:** Renderizar como caja genérica `❓` + warning "Tipo '{type}' no reconocido"
- **Form con 30+ controles:** Scroll, no truncar. Stepper activo si ≥8 campos
- **Form sin bindings:** Controles sin indicador + warning
- **StartEvent vs UserTask:** StartEvent tiene solo 1 DS (Parámetros y Variables). UserTask puede tener DS "Actividades Anteriores" adicional
- **Form JSON malformado:** "No se pudo parsear el form. JSON inválido: {detalle}"
- **Proceso sin forms:** "Este proceso no tiene forms embebidos"

## Test Fixture

Usar `tests/fixtures/procesoconforms_v1.bpmn` como baseline. El preview debe:
- Mostrar todos los controles del fixture (0 faltantes)
- Tipos de control correctos (100% match)
- Jerarquía containers correcta (mismo nesting)
- Bindings a parámetros correctos (mismo DataSource path)
- Comparación manual contra editor BIZUIT

## Gotchas

- El preview es ESTRUCTURAL — no replica el CSS/theming del editor Angular
- Los controles se muestran como placeholders, no como controles funcionales
- El grid de 6 columnas es una APROXIMACIÓN del layout real
- `class` (discriminator) en cada property object es clave para deserialización — el preview no necesita deserializar, solo mostrar estructura
- Triple encoding: el form JSON puede venir con triple encoding desde BPMN. Decodificar ANTES de parsear

# Phase 1: Elicitation — Draft-First (v2.1)

> **Draft-first**: el skill genera un borrador proactivo desde la descripción del usuario.
> La elicitación se convierte en refinamiento del draft, no interrogatorio.
> FR94-FR96, FR98-FR99.

## Rules que esta fase carga

1. `rules/sdd/elicitation-by-section.md` — orchestrator de elicitación + lista de BLOCKERs
2. `rules/sdd/elicitation/sections-1-3.md` — preguntas nivel 1 (Objetivo, Actores, Journeys)
3. `rules/bizuit/common/activity-defaults.md` — asunciones de draft-first por tipo + limitaciones del motor
4. `rules/sdd/anti-patterns.md` — detección proactiva (God Process, etc.)

## Precondiciones

- No existe spec para el proceso, O
- Spec existe con draftedSections y completedSections vacíos (inicio limpio)

## Instrucciones

### Step 1: Verificar estado del filesystem

Antes de empezar, verificar si ya existe trabajo previo.

1. **Extraer nombre del proceso** del mensaje del usuario.
   - Si el mensaje contiene un nombre claro → usar directamente
   - Si no → preguntar: "¿Cómo se llama este proceso?"

2. **Slugificar** el nombre: lowercase, `-` como separador, sin caracteres especiales.

3. **Buscar spec existente** en `processes/{org}/{proceso-slug}/spec.md`

4. **Determinar acción según estado:**

```
¿Existe spec.md?
├── NO → Crear directorio, iniciar draft-first
│
└── SÍ → Leer frontmatter
    ├── source: "reverse" → "Ya existe spec de reverse. ¿Crear desde cero, editar, o abortar?"
    ├── status: "partial" + draftedSections no vacío → "Encontré un draft en progreso. ¿Retomar?"
    ├── status: "partial" + completedSections no vacío → Redirigir a phase-2 (volver a orchestrator)
    ├── status: "complete" → "Ya existe spec completa. ¿Editar, re-crear, o abortar?"
    ├── Sin draftedSections (spec MVP) + status: "partial" → inferir estado, ofrecer retomar
    └── Frontmatter inválido → NFR36: ofrecer reparar, tratar como nueva, o abortar
```

5. **Si nueva creación — inicializar spec parcial:**

```yaml
---
processName: "{nombre}"
organizationId: "{org_id}"
status: "partial"
source: "create"
specFormatVersion: "2.1"
createdAt: "{ISO 8601}"
logicalProcessId: null
currentVersion: null
draftedSections: []
completedSections: []
lastActivity: null
originalIds: null
entryChannel: null
lanes: false
createdBy: "elicitation"
lastModifiedBy: "elicitation"
lastModifiedAt: "{ISO 8601}"
---
```

Y crear `detalle-tecnico.md` vacío.

---

### Step 2: Recibir descripción del usuario

Pedir al usuario que describa el proceso en lenguaje natural:

```
"Describí el proceso que querés crear. Contame qué hace, quién participa,
y los pasos principales. Cuanto más detalle, mejor será el borrador inicial."
```

**Si la descripción es muy vaga** (< 1 oración, ej: "necesito un proceso"):
```
"Necesito un poco más de contexto:
 - ¿Qué hace el proceso? (ej: aprobación de compras, cobranza, onboarding)
 - ¿Quién lo usa? (ej: analista, gerente, sistema automático)
 - ¿Qué sistemas involucra? (ej: base de datos, API externa, email)"
```
Esperar respuesta. NO generar draft con info insuficiente.

---

### Step 3: Buscar specs de referencia (FR98)

Antes de generar el draft:

1. Listar specs en `processes/` (solo frontmatter + sección "## 1. Objetivo")
2. Si algún proceso existente tiene objetivo/dominio similar:
   ```
   "Encontré un proceso similar: '{processName}'. Lo uso como referencia para el borrador."
   ```
3. Usar la estructura del proceso similar como seed para el draft
4. Si no hay specs locales o ninguno es relevante → generar from scratch (no reportar error)

---

### Step 4: Generar draft nivel 1 (FR94)

Usando `elicitation/sections-1-3.md` como guía y `activity-defaults.md` para asunciones:

**Generar ANTES de hacer preguntas:**

```markdown
## Borrador — {processName}

### Objetivo
{1-2 oraciones inferidas de la descripción}

### Actores
{lista de actores inferidos}

### Flujo principal (5-7 actividades como conceptos de negocio)

1. {Actividad 1} (asumí: {asunción})
2. {Actividad 2} (asumí: {asunción})
3. {Actividad 3} — 🔴 BLOCKER: {asunción que necesita confirmación}
4. {Actividad 4} (asumí: {asunción})
5. {Actividad 5} (asumí: {asunción})

### Caminos alternativos
- Si {condición}: → {qué pasa}
- Si {error}: → {qué pasa}
```

**Reglas del draft nivel 1:**
- SIN tipos BIZUIT — solo conceptos de negocio ("consultar datos", "aprobar", "notificar")
- Asunciones inline junto a cada actividad (FR96)
- BLOCKERs marcados con 🔴 (de la lista en `elicitation-by-section.md`)
- Si la descripción implica funcionalidad no soportada por BIZUIT (FR99) → advertir con alternativa (consultar `activity-defaults.md` → Limitaciones del Motor)
- Si hay 20+ actividades → advertencia God Process pero generar igualmente
- **Map first (FR89)**: Si el draft genera >15 actividades O >3 bloques funcionales distintos:
  1. Generar `## Mapa del proceso` como PRIMER output (antes de cualquier detalle)
  2. Comunicar: "Este proceso tiene {N} actividades en {M} bloques. Te muestro primero el mapa general para confirmar la estructura."
  3. Pedir confirmación de la estructura macro ANTES de avanzar a nivel 2
  4. Al pasar nivel 1→2, mostrar delta por sección: "Sección X pasó de {N} conceptos a {M} actividades BIZUIT"
  Si ≤15 actividades y ≤3 bloques → NO generar mapa (spec normal)

---

### Step 5: Presentar draft + pedir confirmación

```
"Generé un borrador basado en tu descripción:

{draft nivel 1}

Las asunciones marcadas son inferidas — corregí las que no sean correctas.
Las 🔴 requieren confirmación obligatoria antes de continuar.

¿La estructura general está bien? ¿Querés corregir algo?"
```

**Esperar respuesta del usuario.**

---

### Step 6: Procesar respuesta del usuario

**Si confirma todo:**
- Mover secciones a `completedSections: ["objetivo", "actores", "actividades-macro"]`
- Vaciar `draftedSections`

**Si confirma parcialmente** ("actividades 1-4 bien, 5-7 no"):
- Las confirmadas → `completedSections`
- Las no confirmadas → quedan en `draftedSections`
- Re-generar solo las no confirmadas con feedback del usuario

**Si corrige algo:**
- Corrección puntual ("actividad 3 no es SQL, es REST") → modificar in-place
- Rechazo estructural ("no, es completamente diferente") → re-generar desde Step 4

**Si hay BLOCKERs sin confirmar:**
- NO avanzar al siguiente nivel
- Insistir (con explicación de por qué importa): "Necesito saber {qué} porque {impacto}"
- Puede guardar y retomar después

---

### Step 6b: Sugerencia de lanes (Epic 15 — FR127)

**Después de confirmar actores**, evaluar si sugerir lanes:

1. **Contar actores distintos** en la sección "Actores" del draft confirmado.

2. **Si >1 actor distinto**, mostrar sugerencia con texto canónico:

```
Detecté **{N} roles** en el proceso: *{Rol1, Rol2, Rol3}*.
¿Querés organizar las actividades por área/rol en el diagrama?
Esto genera carriles (lanes) que agrupan visualmente las tareas de cada rol.
*(Sí/No, default: Sí)*
```

3. **Si 1 o 0 actores**, NO mostrar la pregunta. Setear `lanes: false` automáticamente en frontmatter.

4. **Procesar respuesta:**
   - "Sí" (o default, o respuesta ambigua) → `lanes: true` en frontmatter. Confirmar: "Generaré con carriles."
   - "No" → `lanes: false` en frontmatter. Proceso se genera plano.

5. **Agregar campo `lanes` al frontmatter** del spec.

---

### Step 7: Guardar y volver al orchestrator

Una vez que el draft nivel 1 está confirmado (total o parcialmente):

1. **Escribir `spec.md`** con el borrador como contenido
2. **Actualizar frontmatter:**
   - `draftedSections`: secciones generadas pero no confirmadas
   - `completedSections`: secciones confirmadas por usuario
   - `lastActivity`: "Draft nivel 1 completo"
3. **Crear `detalle-tecnico.md`** con placeholders por actividad
4. **Volver a `create.md`** (orchestrator) — el routing detectará el estado y cargará phase-2 para progressive disclosure niveles 2-3

---

## Adaptación de perfil (heredado del MVP)

El skill infiere el perfil del usuario en los primeros 2-3 mensajes:

| Señales | Perfil | Adaptación |
|---------|--------|------------|
| Términos técnicos (connection strings, REST, SQL) | **Técnico** | Draft más detallado, menos explicaciones |
| Lenguaje de negocio ("el comité aprueba", "se manda al banco") | **Analista** | NO usar "gateway", "BPMN". Metáforas de negocio |
| Mixto | **Mixto** | Seguir el lead del usuario |

**Proceso automático (FR52):** Si no hay User Tasks → omitir actores humanos, SLAs, forms.

**Contexto educativo (FR53):** Si el usuario pregunta "¿por qué?" → explicar con impacto real, no razón técnica.

## Al completar

Guardar spec. Volver a `create.md` (orchestrator) para routing a phase-2 (refinement — progressive disclosure niveles 2-3).

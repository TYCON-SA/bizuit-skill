# Rules — bizuit-sdd

> Punto de entrada para mantener y extender el skill.
> Para humanos. Los otros archivos de rules son instrucciones para la IA.

---

## 1. Estructura de Directorios

```
rules/
├── sdd/              # Metodología genérica (portable, sin dependencias de BIZUIT)
│   ├── elicitation-by-section.md  # Orchestrator de elicitación (v2.1: draft-first + modo de uso)
│   ├── elicitation/               # Sub-archivos de elicitación (progressive disclosure)
│   │   ├── sections-1-3.md        # Nivel 1: Objetivo, Actores, Journeys
│   │   ├── sections-4-6.md        # Nivel 2: Funcionalidades, Integraciones, Edge Cases
│   │   └── sections-7-9.md        # Nivel 3: NFRs, Decisiones, Auditoría + utilidades
│   ├── spec-format.md             # Formato de spec v2.1
│   ├── test-path-generation.md    # Generación de caminos de test
│   ├── completeness-checklist.md  # BLOCKER/WARNING/DRAFT items (v2.1: DRAFT + PENDING)
│   ├── anti-patterns.md           # 7 anti-patterns a detectar en create
│   ├── drift-detection.md         # Detección de drift spec↔BIZUIT (edit)
│   ├── surgical-elicitation.md    # Elicitación quirúrgica (edit)
│   ├── id-preservation.md         # Preservación de IDs + form binding safety (edit)
│   └── change-diff.md             # Clasificación y presentación de cambios (edit)
│
├── bizuit/
│   ├── common/       # Knowledge BIZUIT compartido por generation Y parsing
│   │   ├── activity-types.md      # 15 tipos MVP + tipos reconocidos (FUENTE DE VERDAD)
│   │   ├── api-auth.md            # Flujo de autenticación lazy
│   │   ├── validation-rules.md    # 53 reglas de linting BPMN
│   │   ├── activity-defaults.md   # XSLT defaults vacíos, timeouts, booleans
│   │   └── anomalies.md           # 9 anomalías a detectar en reverse
│   │
│   ├── generation/   # Reglas para spec → BPMN XML (usado por create/edit)
│   │   ├── bpmn-structure.md      # Template XML con namespaces
│   │   ├── service-tasks.md       # Generación por tipo de actividad
│   │   ├── xslt-mappings.md       # 8 campos XSLT por actividad
│   │   ├── gateway-conditions.md  # Formato conditionExpression
│   │   ├── form-generation.md     # Generación de forms BizuitForms embebidos en BPMN (core)
│   │   └── form-generation-datasources.md  # DS secundarios + Actividades Anteriores (complemento)
│   │
│   ├── forms/         # Referencia BizuitForms (para humanos, reverse, query, validate — NO se carga en generación)
│   │   ├── bizuit-forms-controls.md      # 23 tipos de control, props, defaults, mapeo spec→control
│   │   ├── bizuit-forms-json-schema.md   # Estructura JSON, triple encoding, Primary DS, Actividades Anteriores
│   │   └── bizuit-forms-process-integration.md  # Paths, formId, formName, processName, BPMN vs VDW
│   │
│   └── parsing/      # Reglas para VDW XAML → spec (usado por reverse/query)
│       ├── vdw-structure.md       # Estructura TyconSequentialWorkflow
│       ├── activity-parsing.md    # Parsing por tipo de actividad
│       ├── xslt-extraction.md     # Decode HTML entities + password masking
│       └── condition-extraction.md # Formato pipe-delimited → texto
│
├── custom/            # Placeholder para extensibilidad futura (no carga en MVP)
│   └── README.md      # "Para uso futuro. No documentado aún."
│
├── error-catalog.md   # Error codes centralizados — referencia para troubleshooting
├── naming-conventions.md  # Convenciones de nombres para parámetros, IDs, directorios
└── README.md          # Este archivo
```

**Regla de independencia:** `rules/sdd/` NO puede referenciar `rules/bizuit/`. Si una rule en sdd/ necesita knowledge de BIZUIT, moverla a `bizuit/common/`.

---

## 2. Jerarquía de Prioridad

Cuando dos rules se contradicen, la más específica gana:

| Prioridad | Ubicación | Ejemplo |
|---|---|---|
| 1 (más alta) | `bizuit/generation/{file}` o `bizuit/parsing/{file}` | service-tasks.md dice timeout=0 para SQL batch |
| 2 | `bizuit/common/{file}` | activity-defaults.md dice timeout=30 |
| 3 (más baja) | `sdd/{file}` | Solo metodología, sin knowledge técnico |

**Ejemplo:** `activity-defaults.md` dice timeout default = 30. Si `service-tasks.md` dice timeout = 0 para SQLActivity en modo batch, **gana `service-tasks.md`** (prioridad 1 > prioridad 2).

**Si el conflicto es entre archivos del mismo nivel** (ej: dos archivos en `generation/`): resolver manualmente eliminando la contradicción. No hay "last-writer-wins" automático.

---

## 3. Workflow ↔ Rule Contract

### Rules en `bizuit/generation/` — cada tipo de actividad DEBE tener:

```markdown
## {TypeName}

### Atributos requeridos
| Atributo | Tipo | Default | Descripción |
|---|---|---|---|

### Ejemplo de output (BPMN XML)
<bpmn2:serviceTask id="..." name="..." ...>

### Gotchas
- {edge cases y errores comunes}
```

### Rules en `bizuit/parsing/` — cada tipo de actividad DEBE tener:

```markdown
## {TypeName}

### Atributos a extraer
| Atributo VDW | Campo en spec | Ejemplo |
|---|---|---|

### Ejemplo input → output
Input (VDW): <ns1:SqlActivity x:Name="..." ...>
Output (spec): ### N. Nombre (SQL Service Task)

### Notas de encoding
- {HTML entities, doble-encode, CDATA, etc.}
```

---

## 4. Naming Conventions

Para naming conventions, ver `naming-conventions.md`.

---

## 5. Guías de Extensión

### Nuevo tipo de actividad (4 pasos)

1. Agregar fila a `rules/bizuit/common/activity-types.md` (clase VDW, tipo BPMN, atributos)
2. Agregar sección `## {TypeName}` a `rules/bizuit/generation/service-tasks.md` con ejemplo de BPMN XML output
3. Agregar sección `## {TypeName}` a `rules/bizuit/parsing/activity-parsing.md` con ejemplo VDW → spec
4. **Test:** reverse de PruebaIsAdmin → verificar que la spec sigue siendo correcta

### Nuevo flujo (2 pasos)

1. Crear `workflows/{nombre}.md` siguiendo la estructura de 8 pasos (ver `workflows/reverse.md` como referencia — disponible desde Sprint 1)
2. Agregar keywords al router en `SKILL.md` (Sección 1: Detect Intent)

> En Sprint 0, los workflows son stubs. La estructura de 8 pasos estará disponible después de Sprint 1.

### Nuevo edge case a rule existente (3 pasos)

1. Abrir la rule correspondiente (ej: `parsing/activity-parsing.md`)
2. Agregar `#### Edge case: {descripción}` bajo el `## {TypeName}` relevante
3. **Test:** reverse de PruebaIsAdmin → verificar que no se rompe nada

**Tiempo estimado:** < 15 minutos para un full-stack que conoce este README (NFR33).

---

## Error Catalog Completo

Referencia rápida de los 14 códigos de error del skill:

| Código | Contexto | Definido en |
|---|---|---|
| AUTH_FAILED | Login | api-auth.md |
| AUTH_EXPIRED | Token mid-session | api-auth.md |
| API_FORBIDDEN | 403 | api-auth.md |
| API_NOT_FOUND | 404 | api-auth.md |
| API_ERROR | 500 | api-auth.md |
| API_TIMEOUT | 15s | api-auth.md |
| VDW_EMPTY | Download vacío | workflows/reverse.md |
| VDW_PARSE_FAIL | Tipo desconocido | workflows/reverse.md |
| SPEC_CORRUPT | YAML inválido | workflows/edit.md |
| SPEC_DRIFT | Version mismatch | workflows/edit.md |
| BPMN_INVALID | Violación 53 rules | workflows/create.md |
| PERSIST_FAIL | API error | workflows/create.md |
| DIR_FAIL | Sin permisos | cualquier workflow |
| NAME_EXISTS | Nombre duplicado | workflows/create.md |

---

## 6. Gotchas

- **Hooks dentro del flujo, no al final.** Las instrucciones de ejecución (hooks) van DENTRO del flujo de pasos del workflow, no como secciones separadas al final del archivo. Las secciones fuera del flujo principal de pasos no se ejecutan automáticamente.

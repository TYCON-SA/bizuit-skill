# Changelog

Todos los cambios notables del skill bizuit-sdd se documentan en este archivo.

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).
Versionamiento según [Semantic Versioning](https://semver.org/lang/es/).

## 1.5.4 — Test Release

### Changed
- Release de prueba para validar detección de nueva versión

## 1.5.3 — Enforced Version Check

### Fixed
- Version check remoto ahora es OBLIGATORIO en startup (Claude lo ejecuta siempre)

## 1.5.2 — Auto-update Notification

### Added
- **Version check remoto**: al iniciar sesión, el skill verifica si hay nueva versión en GitHub y avisa al usuario

## 1.5.1 — Distribution & Maintenance

### Added
- **update-skill.sh**: script de actualización para usuarios (`--check`, `--force`)
- **GitHub distribution**: repo público TYCON-SA/bizuit-skill con releases automáticos

### Fixed
- Eliminados 5 entries `.DS_Store` del MANIFEST
- Corregido total de archivos en MANIFEST (84 → 79)

## 1.5.0 — Epic 15: Pools & Lanes Support

### Added
- **Lanes opt-in en create workflow**: sugerencia inteligente cuando >1 rol detectado (FR127)
- **`lanes-structure.md`**: nuevo addon template para collaboration/laneSet/lane + BPMNDI (6 secciones)
- **Split generation**: template base genera modelo XML, addon genera BPMNDiagram completo (ARCH-13)
- **Sección "## Lanes"** en spec.md con tabla Performer → Activities (FR132)
- **RACI opcional** en lanes: Accountable, Consulted, Informed por lane (FR134)
- **Validación T09-T11**: completitud de roles cuando lanes=true (FR133)
- **Nota visual**: "diagrama no muestra carriles" en visual output cuando lanes=true
- **Campo `lanes: true|false`** en frontmatter del spec
- 3 test scenarios de lanes (basic, complex, regression)

### Changed
- **Namespace BIZUIT corregido**: `http://bizuit.com/bpmn/extensions` → `http://tycon.com/schema/bpmn/bizuit` (NFR57)
- **Namespace como constante** en bpmn-structure.md (single source of truth, ADR LANES-3)
- **activity-defaults.md**: "Solo 1 participante" → "Single-pool. Lanes SÍ soportadas"
- **phase-4-generation.md**: Paso 13 reescrito con condicional split generation
- **phase-2-refinement.md**: Paso 9f con mapping confirmation + RACI + fallback ≤1 lane
- **phase-1-elicitation.md**: Step 6b con sugerencia de lanes
- **phase-3-validation.md**: T09-T11 condicionales a lanes:true
- **validate.md standalone**: hereda T09-T11 automáticamente

### Fixed
- Namespace incorrecto `bizuit.com/bpmn/extensions` → `tycon.com/schema/bpmn/bizuit` (bug desde v1.0.0)
- targetNamespace corregido de `bizuit.com/bpmn` a `tycon.com/schema/bpmn`

## 1.4.0 — Epic 14: Smart Defaults + Graph Overview

### Changed
- Default visual output cambiado de texto indentado a Mermaid (ADR VIS-8)
- 4 workflows actualizados: delegación al orchestrador visual-output.md sin hardcodear renderer
- Flag inválido ahora fallback a Mermaid (antes era texto)
- `graph status` con ≥3 procesos muestra tabla organizacional con health indicators (🟢🟡🔴), última actualización, nodos, dependencias (FR126)

### Added
- Threshold 30 nodos post-collapsing: procesos grandes fuerzan texto indentado automáticamente
- Flag explícito `--visual mermaid` sobreescribe threshold (el usuario decide)
- Nota en visual-output.md sobre auto-detection runtime diferida
- Detección de índice desactualizado: compara lastRebuilt vs lastModifiedAt de specs
- Mensaje informativo con <3 procesos: "Documentá más procesos para activar vista organizacional"

### Fixed
- Wording de reverse.md, edit.md: removida referencia hardcodeada a text-renderer.md y diff-renderer.md

## 1.3.0 — Phase 3: Visual Output + Knowledge Graph + Rich Views

### Added
- Visual output automático en reverse, create, edit (texto indentado como default)
- Knowledge Graph: `graph build`, `graph query`, `graph validate`, `graph status`, blast radius
- Stakeholder views: vista ejecutiva (1 página) y vista QA (test paths + datos prueba)
- Form preview estructural HTML con grid 6 columnas y legend de tipos
- Test path visualizer con highlighting de camino seleccionado
- Diff visual en edit: diagrama coloreado (verde/rojo/amarillo) + tabla de cambios
- Export HTML self-contained con SVG inline (<50KB, offline)
- Mermaid renderer para Claude App con subgraphs colapsables
- ProcessFlowJSON como artefacto intermedio (schema v1.0)
- GraphIndexJSON con nodos tipados, aristas dirigidas, health status (verde/amarillo/rojo)
- 10 intents nuevos en SKILL.md (visualize, graph, export, view, form preview)
- CSS compartido en templates/shared-styles.css

### Changed
- reverse.md: visual output OBLIGATORIO dentro del Paso 8 (no como sección separada)
- create/phase-4-generation.md: visual output dentro del Paso 18
- edit.md: visual + diff output dentro del Step 7
- query.md: visual opt-in dentro de Steps 2A/2B
- MANIFEST: 68 → 78 archivos

### Fixed
- Bug: hooks de visual como sección separada al final de workflows no se ejecutan. Fix: integrar DENTRO del paso final con lenguaje imperativo ("INMEDIATAMENTE", "OBLIGATORIO")

## 1.1.0 — Epic 7 Growth

### Added
- Workflow `generate-forms.md`: genera componentes React (.tsx) para UserTasks desde spec usando SDK real `@tyconsa/bizuit-form-sdk` + `@tyconsa/bizuit-ui-components`
- Mapa del proceso para specs jerárquicas (>15 actividades) — story 7.8
- Guía de parámetros vs variables con tabla extendida (Rol, Filterable) — story 7.x
- Config multi-ambiente DEV/QA/PROD con safety gate — story 7.9

### Changed
- SKILL.md: routing para intent "generá forms" / "generate forms"
- guia-rapida.md: nuevo comando "generá forms"
- guia-completa.md: sección "Generar formularios React" con ejemplo paso a paso

---

## 1.0.0 — Initial release

### Added
- 5 workflows: create, edit, reverse, query, validate
- 15 tipos de actividad soportados
- Rules SDD: elicitation-by-section, spec-format, test-path-generation, completeness-checklist, anti-patterns, drift-detection, surgical-elicitation, id-preservation, change-diff
- Rules BIZUIT: activity-types, api-auth, validation-rules, activity-defaults, anomalies, bpmn-structure, service-tasks, xslt-mappings, gateway-conditions, vdw-structure, activity-parsing, xslt-extraction, condition-extraction
- Template de spec (process-spec.md) con frontmatter schema
- Router con filesystem state machine (SKILL.md)
- Scripts de instalación (install-skill.sh, install-skill.ps1)
- Build script (build-package.sh) con pre-build check de secrets
- 3 artefactos de distribución: git repo, zip, concatenado para Claude app
- Documentación de usuario: guia-rapida.md, guia-completa.md, referencia-configuracion.md

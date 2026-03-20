# bizuit-sdd — Quick Start

## ¿Qué es?

Un skill de Claude Code que te permite crear, documentar, y editar procesos BIZUIT conversando con Claude. Es como un libro de instrucciones que Claude lee para saber cómo trabajar con BIZUIT.

## Instalación (2 minutos)

### 1. Clonar el skill

```bash
# Mac/Linux:
git clone https://bizuit.visualstudio.com/SDDDocs/_git/SDDDocs ~/.claude/skills/bizuit-sdd

# Windows PowerShell:
git clone https://bizuit.visualstudio.com/SDDDocs/_git/SDDDocs $env:USERPROFILE\.claude\skills\bizuit-sdd
```

### 2. Ejecutar el instalador

```bash
# Mac/Linux:
cd ~/.claude/skills/bizuit-sdd && ./scripts/install-skill.sh

# Windows PowerShell:
cd $env:USERPROFILE\.claude\skills\bizuit-sdd; .\scripts\install-skill.ps1
```

El script te pregunta las credenciales de BIZUIT (opcionales — podés configurarlas después).

### 3. Verificar

Abrí Claude Code y decí **"hola"**. El skill debería responder con el menú principal mostrando la versión y los flujos disponibles.

## Uso

Decile a Claude:
- **"Crear proceso de aprobación de compras"** — genera spec + BPMN con forms BizuitForms embebidos
- **"Documentar el proceso de onboarding"** — reverse engineering de un proceso existente (incluye forms)
- **"Editar el proceso de compras"** — modifica un proceso ya documentado
- **"¿Qué hace el proceso de cobranza?"** — consulta conversacional (incluye info de forms)
- **"Generá forms para el proceso de compras"** — genera componentes React (.tsx) desde la spec
- **"Mostrá el flujo del proceso de compras"** — visualización del flujo como texto indentado o Mermaid
- **"Graph build"** — construye el knowledge graph de relaciones entre procesos
- **"Vista ejecutiva del proceso de compras"** — resumen de 1 página para stakeholders
- **"Vista QA del proceso de compras"** — test paths + datos de prueba para QA
- **"Exportar proceso de compras"** — HTML self-contained (<50KB, offline)
- **"Diagnóstico"** — health check del skill

> **Nuevo v1.4:** Visual output automático como diagrama Mermaid (default) en Claude App y VS Code. En CLI: `--visual text` para texto indentado. Knowledge graph con vista organizacional (`graph status`). Vistas para stakeholders (ejecutiva, QA). Form preview HTML. Export offline. Ver `docs/guia-completa.md` para detalles.

## Modo degradado (sin APIs)

Sin credenciales BIZUIT el skill funciona igual — creás specs locales sin conectar a BIZUIT. Útil para demos y evaluación.

Flujos disponibles sin credenciales:
- ✅ Crear proceso (spec + BPMN local)
- ✅ Editar proceso (spec local)
- ✅ Validar spec
- ⚠️ Persistir en BIZUIT — requiere credenciales
- ⚠️ Reverse / Query — requiere credenciales

## Claude app (web)

Si usás claude.ai en vez de Claude Code CLI:
1. Pedí el archivo `bizuit-sdd-v1.3.0-claude-app.md`
2. Subilo a **Project Knowledge** de tu proyecto
3. Decí "crear proceso" para empezar

Limitación: las specs se generan en el chat, no se guardan en disco.

## Actualización

```bash
cd ~/.claude/skills/bizuit-sdd && git pull
```

Tus archivos locales (processes/) no se afectan por la actualización.

## Seguridad

- El skill **NO contiene credenciales** ni datos de clientes
- Las credenciales están solo en tu shell profile (~/.zshrc o $PROFILE)
- Las specs generadas no contienen passwords (se enmascaran automáticamente)
- El contenido de los procesos se envía a Claude (Anthropic) para su procesamiento

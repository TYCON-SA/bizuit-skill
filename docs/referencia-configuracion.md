# bizuit-sdd — Referencia de Configuración

> Para IT admins y equipos técnicos que instalan, configuran, y dan soporte al skill.

---

## 1. Requisitos del sistema

| Componente | Requerido | Notas |
|---|---|---|
| Claude Code CLI | Sí (para uso productivo) | [Instalación](https://claude.ai/claude-code) |
| Git | Sí | Para clonar y actualizar el skill |
| Terminal | Sí | bash 4+, zsh, o PowerShell 7+ |
| Conexión a internet | Para clonar + conectar a BIZUIT | El skill funciona offline para operaciones locales |
| Claude app (claude.ai) | Opcional | Canal de demostración — limitado (sin filesystem) |

---

## 2. Variables de entorno

| Variable | Descripción | Ejemplo | Obligatoria |
|---|---|---|---|
| `BIZUIT_API_URL` | URL de la Dashboard API | `https://test.bizuit.com/tenantBIZUITDashboardAPI/api` | Para reverse/query |
| `BIZUIT_BPMN_API_URL` | URL de la BPMN API | `https://test.bizuit.com/tenantBIZUITBPMNEditorBackEnd/api` | Para persistir |
| `BIZUIT_USERNAME` | Usuario de BIZUIT | `ariel.schwindt` | Para cualquier API |
| `BIZUIT_PASSWORD` | Password de BIZUIT | `********` | Para cualquier API |
| `BIZUIT_ORG_ID` | Identificador del tenant | `rdaff` | Para organizar specs locales |

**Nota:** Ninguna env var es estrictamente obligatoria. Sin ellas, el skill funciona en modo degradado (crear specs locales, validar, editar offline).

---

## 2b. Configuración Multi-Ambiente (FR92)

Para equipos que trabajan con múltiples ambientes (dev, QA, prod), el skill soporta configuración multi-ambiente en `.bizuit-config.yaml`.

### Formato

```yaml
active: dev
environments:
  dev:
    url: https://dev.bizuit.com
    user: ariel
    org: arielsch
  qa:
    url: https://qa.bizuit.com
    user: ariel
    org: arielsch
  prod:
    url: https://prod.bizuit.com
    user: ariel
    org: arielsch-prod
```

### Comandos de ambiente

| Comando | Qué hace |
|---------|----------|
| "cambiar a prod" / "switch to prod" / "usar prod" | Cambia el ambiente activo. Invalida token. |
| "¿en qué ambiente estoy?" | Muestra ambiente activo + URL + lista disponibles |

### Safety gate por ambiente

- **dev**: Sin warning adicional
- **qa**: Warning suave `🟡 [QA]` antes de persist
- **prod**: Warning fuerte `🔴 [PROD]` antes de persist

El prefijo del ambiente aparece en todos los outputs cuando hay multi-env configurado.

### Backward compatibility

- Config flat (sin `environments:`) sigue funcionando como ambiente único
- Config multi-env con 1 solo ambiente funciona sin preguntar cuál
- Password sigue siendo por sesión — nunca en disco, independientemente del ambiente

---

## 3. Instalación

### Mac/Linux

```bash
# 1. Clonar
git clone https://bizuit.visualstudio.com/SDDDocs/_git/SDDDocs ~/.claude/skills/bizuit-sdd

# 2. Instalar (modo asistido — pregunta credenciales)
cd ~/.claude/skills/bizuit-sdd
./scripts/install-skill.sh

# 2b. Instalar (modo dev — solo validación, sin preguntar credenciales)
./scripts/install-skill.sh --mode dev
```

### Windows PowerShell 7+

```powershell
# 1. Clonar
git clone https://bizuit.visualstudio.com/SDDDocs/_git/SDDDocs $env:USERPROFILE\.claude\skills\bizuit-sdd

# 2. Instalar
cd $env:USERPROFILE\.claude\skills\bizuit-sdd
.\scripts\install-skill.ps1

# Si PowerShell bloquea la ejecución:
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Exit codes del script

| Código | Significado |
|---|---|
| 0 | Éxito |
| 1 | Error de instalación (archivos faltantes, permisos) |
| 2 | Error de configuración (credenciales inválidas) |

---

## 4. Estructura de directorios post-instalación

```
~/.claude/skills/bizuit-sdd/
├── SKILL.md              # Router principal del skill
├── VERSION               # Versión actual (semver)
├── MANIFEST.md           # Lista de archivos + checksums
├── CHANGELOG.md          # Historial de cambios
├── .gitignore            # Exclusiones
├── scripts/              # Instalador + build
├── workflows/            # 4 flujos (create, edit, reverse, query)
├── rules/                # Reglas del skill (sdd/ + bizuit/)
├── templates/            # Template de spec
└── docs/                 # Esta documentación
```

---

## 5. Verificación y health check

### Post-instalación

```bash
./scripts/install-skill.sh --check
```

### Desde el skill

Decirle a Claude: **"diagnóstico"** o **"health check"**

### Niveles de reporte

| Nivel | Significado | Acción |
|---|---|---|
| ✅ | OK | Nada que hacer |
| ⚠️ | Funcional pero incompleto | Puede continuar — ej: env vars faltantes (modo degradado) |
| ❌ | No funcional | Hay que arreglar — ej: SKILL.md no encontrado |

---

## 6. Actualizaciones

### Claude Code CLI

```bash
cd ~/.claude/skills/bizuit-sdd && git pull
```

Los archivos locales (`processes/`, `rules/custom/`) **no se afectan** por la actualización.

### Claude app

Re-subir el archivo `bizuit-sdd-v{VERSION}-claude-app.md` actualizado a Project Knowledge.

### Verificar versión

```bash
cat ~/.claude/skills/bizuit-sdd/VERSION
```

O decirle a Claude: **"diagnóstico"** — muestra la versión instalada.

---

## 7. Desinstalación

### Mac/Linux

```bash
rm -rf ~/.claude/skills/bizuit-sdd/
```

### Windows PowerShell

```powershell
Remove-Item -Recurse -Force $env:USERPROFILE\.claude\skills\bizuit-sdd
```

**Nota:** Las env vars quedan en el shell profile (~/.zshrc o $PROFILE). Para removerlas, editar el archivo manualmente y borrar las líneas que empiezan con `export BIZUIT_` (Mac/Linux) o `$env:BIZUIT_` (Windows).

Las specs generadas (`processes/`) están en el proyecto donde se invocó el skill, **no** en el directorio del skill. No se borran al desinstalar.

---

## 8. Troubleshooting

| Problema | Causa | Solución |
|---|---|---|
| "Claude no detecta el skill" | SKILL.md no está en el path correcto | Verificar que existe `~/.claude/skills/bizuit-sdd/SKILL.md` |
| "Versión inconsistente" | VERSION y SKILL.md difieren | Ejecutar `git pull` o `./scripts/build-package.sh` |
| "Faltan env vars" | Credenciales no configuradas | Ejecutar `./scripts/install-skill.sh` de nuevo |
| "Permission denied" al ejecutar script | Permisos de ejecución faltantes | `chmod +x scripts/*.sh` |
| "Auth failed" al conectar a BIZUIT | Credenciales incorrectas o expiradas | Verificar usuario/password con IT |
| "API timeout" | BIZUIT no responde | Verificar URL y conectividad de red |
| PowerShell bloquea .ps1 | Execution policy restrictiva | `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` |

---

## 9. Seguridad

### ¿Qué es el skill?

El skill es un conjunto de **archivos Markdown** (texto plano). No es un ejecutable, no tiene permisos especiales, no accede a nada que Claude Code no pueda acceder.

### ¿Dónde están las credenciales?

Exclusivamente en las **variables de entorno** del shell profile del usuario (`~/.zshrc` o `$PROFILE`). Nunca en archivos del skill.

### ¿Qué datos se procesan?

El contenido de los procesos BIZUIT se envía a **Claude (Anthropic)** para su procesamiento. Esto incluye:
- Estructura del proceso (actividades, gateways)
- Queries SQL (con passwords enmascaradas)
- Nombres de tablas y columnas

**Si la organización tiene requisitos de data residency, consultar con el equipo legal.**

### ¿Qué NO contiene el paquete distribuido?

- ❌ Credenciales (usuario, password, tokens)
- ❌ Datos de clientes (specs, queries reales)
- ❌ Connection strings
- ❌ Archivos ejecutables

El build script (`build-package.sh`) verifica automáticamente que no se filtren secrets antes de generar el paquete distribuible.

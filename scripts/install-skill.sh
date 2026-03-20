#!/bin/bash
# bizuit-sdd install-skill.sh — Instalador para Mac/Linux
# Uso:
#   ./install-skill.sh                    # Modo asistido (default)
#   ./install-skill.sh --mode dev         # Solo validación (git clone ya hecho)
#   ./install-skill.sh --mode assisted    # Paso a paso con credenciales
#   ./install-skill.sh --check            # Health check (no modifica nada)
#
# Exit codes: 0=éxito, 1=error de instalación, 2=error de configuración
# Shells soportados: bash 4+, zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SOURCE="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$HOME/.claude/skills/bizuit-sdd"
MODE="assisted"
CHECK_ONLY=false

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --check) CHECK_ONLY=true; shift ;;
    *) echo "Uso: $0 [--mode dev|assisted] [--check]"; exit 1 ;;
  esac
done

# --- Funciones de utilidad ---
trim() { echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' ; }

detect_shell_profile() {
  if [[ -n "${ZSH_VERSION:-}" ]] || [[ "$SHELL" == */zsh ]]; then
    echo "$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    echo "$HOME/.bashrc"
  elif [[ -f "$HOME/.bash_profile" ]]; then
    echo "$HOME/.bash_profile"
  else
    echo "$HOME/.bashrc"
  fi
}

set_env_var() {
  local var_name="$1"
  local var_value="$2"
  local profile="$3"

  # Crear profile si no existe
  [[ -f "$profile" ]] || touch "$profile"

  # Sobreescribir si ya existe, agregar si no
  if grep -q "^export ${var_name}=" "$profile" 2>/dev/null; then
    sed -i '' "s|^export ${var_name}=.*|export ${var_name}=\"${var_value}\"|" "$profile"
  else
    echo "export ${var_name}=\"${var_value}\"" >> "$profile"
  fi
}

# --- Validación (usada por todos los modos) ---
run_validation() {
  local target_dir="$1"
  local exit_code=0

  echo ""
  echo "🔍 Validación"
  echo "────────────────"

  # Check 1: SKILL.md existe (❌ si falta)
  if [[ -f "$target_dir/SKILL.md" ]]; then
    echo "✅ SKILL.md encontrado"
  else
    echo "❌ SKILL.md no encontrado — Claude no puede detectar el skill"
    exit_code=1
  fi

  # Check 2: VERSION existe (⚠️ si falta)
  if [[ -f "$target_dir/VERSION" ]]; then
    local version=$(tr -d '[:space:]' < "$target_dir/VERSION")
    echo "✅ VERSION: $version"
  else
    echo "⚠️  VERSION no encontrado"
  fi

  # Check 3: Versión consistente (⚠️ si difieren)
  if [[ -f "$target_dir/VERSION" ]] && [[ -f "$target_dir/SKILL.md" ]]; then
    local file_version=$(tr -d '[:space:]' < "$target_dir/VERSION")
    local skill_version=$(grep 'Versión:' "$target_dir/SKILL.md" 2>/dev/null | sed 's/.*Versión:\*\* //' | tr -d '[:space:]' || echo "")
    if [[ -n "$skill_version" ]] && [[ "$file_version" != "$skill_version" ]]; then
      echo "⚠️  Versión inconsistente: VERSION=$file_version, SKILL.md=$skill_version"
    fi
  fi

  # Check 4: MANIFEST existe y archivos coinciden (⚠️ si mismatch)
  if [[ -f "$target_dir/MANIFEST.md" ]]; then
    local manifest_count=$(grep -c "^|" "$target_dir/MANIFEST.md" | head -1 || echo "0")
    local actual_count=$(find "$target_dir" -type f -not -path "$target_dir/.git/*" -not -path "$target_dir/dist/*" -not -path "$target_dir/processes/*" | wc -l | tr -d ' ')
    echo "✅ MANIFEST.md presente ($actual_count archivos)"
  else
    echo "⚠️  MANIFEST.md no encontrado — ejecutá build-package.sh para generarlo"
  fi

  # Check 5: Config lazy (.bizuit-config.yaml)
  local config_file="$target_dir/.bizuit-config.yaml"
  if [[ -f "$config_file" ]]; then
    echo "✅ Config BIZUIT: configurado (.bizuit-config.yaml presente)"
  else
    echo "✅ Config BIZUIT: normal — se configura al primer uso de API (config lazy)"
  fi

  # Backward compat: check legacy env vars
  if [[ -n "${BIZUIT_API_URL:-}" ]]; then
    echo "ℹ️  Env vars legacy detectadas. Recomendado migrar a .bizuit-config.yaml"
  fi

  # Check 6 (solo con --check): Conectividad a APIs
  if $CHECK_ONLY && [[ -f "$config_file" || -n "${BIZUIT_API_URL:-}" ]]; then
    echo ""
    echo "🌐 Conectividad"
    echo "────────────────"
    if [[ -n "${BIZUIT_API_URL:-}" ]]; then
      if curl -s --connect-timeout 5 "${BIZUIT_API_URL}" > /dev/null 2>&1; then
        echo "✅ Dashboard API: accesible"
      else
        echo "⚠️  Dashboard API: no accesible (${BIZUIT_API_URL})"
      fi
    fi
    if [[ -n "${BIZUIT_BPMN_API_URL:-}" ]]; then
      if curl -s --connect-timeout 5 "${BIZUIT_BPMN_API_URL}" > /dev/null 2>&1; then
        echo "✅ BPMN API: accesible"
      else
        echo "⚠️  BPMN API: no accesible (${BIZUIT_BPMN_API_URL})"
      fi
    fi
  fi

  echo ""
  if [[ $exit_code -eq 0 ]]; then
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
      echo "Resultado: instalación OK (modo degradado — configurá las env vars para funcionalidad completa)"
    else
      echo "Resultado: instalación OK ✅"
    fi
    echo ""
    echo "Próximo paso: abrí Claude Code y decí \"hola\"."
  else
    echo "Resultado: ❌ hay que arreglar antes de poder usar el skill"
  fi

  return $exit_code
}

# --- Health check mode ---
if $CHECK_ONLY; then
  echo "🔍 bizuit-sdd — Health Check"
  echo "============================="

  if [[ -d "$TARGET" ]]; then
    run_validation "$TARGET"
  elif [[ -d "$SKILL_SOURCE" ]] && [[ -f "$SKILL_SOURCE/SKILL.md" ]]; then
    run_validation "$SKILL_SOURCE"
  else
    echo "❌ No se encontró bizuit-sdd en $TARGET ni en el directorio actual"
    exit 1
  fi
  exit $?
fi

# --- Instalación ---
echo "📦 bizuit-sdd — Instalación"
echo "============================="
echo ""

# Detectar si ya estamos en el path correcto
IN_CORRECT_PATH=false
if [[ "$SKILL_SOURCE" == "$TARGET" ]] || [[ "$(cd "$SKILL_SOURCE" && pwd)" == "$(cd "$TARGET" 2>/dev/null && pwd)" ]]; then
  IN_CORRECT_PATH=true
fi

case "$MODE" in
  dev)
    echo "🔧 Modo dev — solo validación"
    echo ""

    if [[ -d "$TARGET" ]] && [[ -f "$TARGET/SKILL.md" ]]; then
      run_validation "$TARGET"
    elif $IN_CORRECT_PATH; then
      run_validation "$SKILL_SOURCE"
    else
      echo "❌ bizuit-sdd no encontrado en $TARGET"
      echo "   Hacé git clone primero: git clone {repo} $TARGET"
      exit 1
    fi
    ;;

  assisted)
    echo "📋 Modo asistido — instalación paso a paso"
    echo ""

    # Paso 1: Verificar/copiar archivos
    if $IN_CORRECT_PATH; then
      echo "✅ El skill ya está en el path correcto ($TARGET)"
    elif [[ -d "$TARGET" ]]; then
      # Ya existe — verificar versión
      if [[ -f "$TARGET/VERSION" ]]; then
        existing_version=$(tr -d '[:space:]' < "$TARGET/VERSION")
        echo "⚠️  Ya existe bizuit-sdd v$existing_version en $TARGET"
        read -rp "   ¿Sobreescribir? [s/n]: " overwrite
        if [[ "$overwrite" != "s" ]] && [[ "$overwrite" != "S" ]]; then
          echo "   Cancelado."
          exit 0
        fi
      fi
      # Preservar rules/custom/ si existe
      if [[ -d "$TARGET/rules/custom" ]]; then
        CUSTOM_BACKUP=$(mktemp -d)
        cp -r "$TARGET/rules/custom" "$CUSTOM_BACKUP/"
      fi
      # Copiar archivos
      mkdir -p "$TARGET"
      cp -r "$SKILL_SOURCE"/* "$TARGET/" 2>/dev/null || true
      cp "$SKILL_SOURCE"/.gitignore "$TARGET/" 2>/dev/null || true
      # Restaurar rules/custom/
      if [[ -n "${CUSTOM_BACKUP:-}" ]]; then
        cp -r "$CUSTOM_BACKUP/custom" "$TARGET/rules/"
        rm -rf "$CUSTOM_BACKUP"
      fi
      echo "✅ Archivos copiados a $TARGET"
    else
      # No existe — copiar
      mkdir -p "$(dirname "$TARGET")"
      cp -r "$SKILL_SOURCE" "$TARGET"
      echo "✅ Archivos copiados a $TARGET"
    fi

    echo ""

    # Paso 2: Config lazy (v2.1 — no pedir credenciales)
    echo ""
    echo "ℹ️  Configuración de credenciales: el skill te pedirá los datos la primera"
    echo "   vez que uses una operación que necesite API (reverse, persist, search)."
    echo "   CREATE, VALIDATE, y QUERY local funcionan sin configurar nada."
    echo ""
    echo "   Si necesitás configurar manualmente: creá .bizuit-config.yaml en $TARGET"

    # Paso 3: Validación
    if $IN_CORRECT_PATH; then
      run_validation "$SKILL_SOURCE"
    else
      run_validation "$TARGET"
    fi
    ;;

  *)
    echo "❌ Modo desconocido: $MODE"
    echo "   Modos válidos: dev, assisted"
    exit 1
    ;;
esac

#!/bin/bash
# update-skill.sh — Actualiza bizuit-skill desde GitHub
# Uso:
#   ./update-skill.sh              # Actualiza si hay nueva versión
#   ./update-skill.sh --check      # Solo verifica, no actualiza
#   ./update-skill.sh --force      # Fuerza actualización sin comparar versión
set -euo pipefail

GH_REPO="TYCON-SA/bizuit-skill"
TARGET="$HOME/.claude/skills/bizuit-sdd"
CHECK_ONLY=false
FORCE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=true; shift ;;
    --force) FORCE=true; shift ;;
    *) echo "Uso: $0 [--check|--force]"; exit 1 ;;
  esac
done

# Obtener versión remota
REMOTE_VERSION=$(curl -sL "https://raw.githubusercontent.com/${GH_REPO}/main/VERSION" 2>/dev/null | tr -d '[:space:]')
if [[ -z "$REMOTE_VERSION" ]]; then
  echo "❌ No se pudo obtener la versión remota"
  exit 1
fi

# Obtener versión local
LOCAL_VERSION="(no instalado)"
if [[ -f "$TARGET/VERSION" ]]; then
  LOCAL_VERSION=$(tr -d '[:space:]' < "$TARGET/VERSION")
fi

echo "bizuit-skill"
echo "  Local:  ${LOCAL_VERSION}"
echo "  Remota: ${REMOTE_VERSION}"

if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]] && ! $FORCE; then
  echo "✅ Ya tenés la última versión"
  exit 0
fi

if [[ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]]; then
  echo "⬆️  Nueva versión disponible: ${LOCAL_VERSION} → ${REMOTE_VERSION}"
fi

if $CHECK_ONLY; then
  exit 0
fi

# Backup rules/custom/ si existe
CUSTOM_BACKUP=""
if [[ -d "$TARGET/rules/custom" ]]; then
  CUSTOM_BACKUP=$(mktemp -d)
  cp -r "$TARGET/rules/custom" "$CUSTOM_BACKUP/"
  echo "📋 Backup de rules/custom/ creado"
fi

# Backup .bizuit-config.yaml si existe
CONFIG_BACKUP=""
if [[ -f "$TARGET/.bizuit-config.yaml" ]]; then
  CONFIG_BACKUP=$(mktemp)
  cp "$TARGET/.bizuit-config.yaml" "$CONFIG_BACKUP"
  echo "📋 Backup de .bizuit-config.yaml creado"
fi

# Descargar y extraer
echo "📥 Descargando v${REMOTE_VERSION}..."
TMPDIR=$(mktemp -d)
curl -sL "https://github.com/${GH_REPO}/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMPDIR"

# Instalar
mkdir -p "$TARGET"
rm -rf "${TARGET:?}"/*
cp -r "$TMPDIR/bizuit-skill-main/"* "$TARGET/"
cp "$TMPDIR/bizuit-skill-main/".gitignore "$TARGET/" 2>/dev/null || true

# Restaurar custom rules y config
if [[ -n "$CUSTOM_BACKUP" ]]; then
  cp -r "$CUSTOM_BACKUP/custom" "$TARGET/rules/"
  rm -rf "$CUSTOM_BACKUP"
  echo "📋 rules/custom/ restaurado"
fi
if [[ -n "$CONFIG_BACKUP" ]]; then
  cp "$CONFIG_BACKUP" "$TARGET/.bizuit-config.yaml"
  rm -f "$CONFIG_BACKUP"
  echo "📋 .bizuit-config.yaml restaurado"
fi

# Cleanup
rm -rf "$TMPDIR"

echo "✅ Actualizado a v${REMOTE_VERSION}"
echo ""
echo "Changelog: https://github.com/${GH_REPO}/releases/tag/v${REMOTE_VERSION}"

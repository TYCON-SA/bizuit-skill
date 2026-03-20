#!/bin/bash
# bizuit-sdd build-package.sh — Genera artefactos de distribución
# Uso: ./build-package.sh [--dry-run]
#
# Pasos:
#   1. Lee VERSION → sincroniza versión en SKILL.md
#   2. Verifica que CHANGELOG.md tiene entrada para la versión actual
#   3. Pre-build check de secrets (pattern=valor, ignora fenced code blocks)
#   4. Genera MANIFEST.md con SHA256 checksums
#   5. Genera zip (dist/bizuit-sdd-v{VERSION}.zip)
#   6. Genera concatenado (dist/bizuit-sdd-v{VERSION}-claude-app.md)
#
# Solo Mac/Linux. Requiere: shasum, zip.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "🔍 Modo dry-run: escanea y reporta sin generar artefactos"
  echo ""
fi

# Directorios/archivos excluidos del paquete
is_excluded() {
  local rel="$1"
  [[ "$rel" == processes/* ]] || [[ "$rel" == .env ]] || \
  [[ "$rel" == .engram/* ]] || [[ "$rel" == dist/* ]] || \
  [[ "$rel" == docs/pilots/* ]] || [[ "$rel" == MANIFEST.md ]]
}

is_custom_rule() {
  local rel="$1"
  [[ "$rel" == rules/custom/*.md ]] && [[ "$rel" != "rules/custom/README.md" ]]
}

echo "📦 bizuit-sdd build-package"
echo "==========================="
echo ""

# --- Paso 1: Leer VERSION y sincronizar SKILL.md ---
VERSION_FILE="$SKILL_DIR/VERSION"
SKILL_FILE="$SKILL_DIR/SKILL.md"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "❌ Error: VERSION file not found"
  exit 1
fi

VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
echo "📌 Versión: $VERSION"

# Sincronizar versión en SKILL.md (línea > **Versión:** X.Y.Z en blockquote)
if grep -q 'Versión:' "$SKILL_FILE"; then
  CURRENT_SKILL_VERSION=$(grep 'Versión:' "$SKILL_FILE" | sed 's/.*Versión:\*\* //' | tr -d '[:space:]')
  if [[ "$CURRENT_SKILL_VERSION" != "$VERSION" ]]; then
    sed -i '' "s/Versión:\*\* .*/Versión:** $VERSION/" "$SKILL_FILE"
    echo "⚠️  SKILL.md actualizado de v$CURRENT_SKILL_VERSION a v$VERSION. Commiteá antes de push."
  else
    echo "✅ SKILL.md ya tiene versión $VERSION"
  fi
else
  echo "⚠️  No se encontró 'Versión:' en SKILL.md — no se sincronizó"
fi
echo ""

# --- Paso 2: Verificar CHANGELOG.md ---
CHANGELOG_FILE="$SKILL_DIR/CHANGELOG.md"

if [[ ! -f "$CHANGELOG_FILE" ]]; then
  echo "❌ Error: CHANGELOG.md not found"
  exit 1
fi

if ! grep -q "## $VERSION" "$CHANGELOG_FILE"; then
  echo "❌ Error: CHANGELOG.md no tiene entrada para versión $VERSION"
  echo "   Agregá una sección '## $VERSION' con los cambios antes de generar el paquete."
  exit 1
fi

echo "✅ CHANGELOG.md tiene entrada para v$VERSION"
echo ""

# --- Paso 3: Pre-build check de secrets ---
echo "🔒 Escaneando secrets..."

# Estrategia: usar grep para encontrar matches rápido, luego filtrar los que están en code blocks
# Patterns combinados en un solo regex para eficiencia
COMBINED_PATTERN='(Password|Secret|Token|Pwd)=[A-Za-z0-9][A-Za-z0-9]{3,}|Bearer [A-Za-z0-9]{10,}|Basic [A-Za-z0-9]{10,}|Server=[A-Za-z0-9][A-Za-z0-9.]{5,}|Database=[A-Za-z0-9]{3,}|User Id=[A-Za-z0-9]{2,}|://[^/ ]*:[^@ ]*@'

SECRETS_FOUND=false
SECRETS_REPORT=""

# Obtener lista de archivos a escanear
while IFS= read -r -d '' file; do
  REL_PATH="${file#$SKILL_DIR/}"
  is_excluded "$REL_PATH" && continue
  is_custom_rule "$REL_PATH" && continue

  # Grep rápido — si no hay match, saltar archivo
  if ! grep -nE "$COMBINED_PATTERN" "$file" > /dev/null 2>&1; then
    continue
  fi

  # Hay matches — verificar que no estén en code blocks
  IN_CODE_BLOCK=false
  LINE_NUM=0
  while IFS= read -r line; do
    LINE_NUM=$((LINE_NUM + 1))
    if [[ "$line" == '```'* ]]; then
      $IN_CODE_BLOCK && IN_CODE_BLOCK=false || IN_CODE_BLOCK=true
      continue
    fi
    if ! $IN_CODE_BLOCK; then
      if echo "$line" | grep -qE "$COMBINED_PATTERN" 2>/dev/null; then
        SECRETS_FOUND=true
        MATCH=$(echo "$line" | grep -oE "$COMBINED_PATTERN" 2>/dev/null | head -1)
        SECRETS_REPORT+="   ⚠️  $REL_PATH:$LINE_NUM — '$MATCH'"$'\n'
      fi
    fi
  done < "$file"
done < <(find "$SKILL_DIR" -type f \( -name "*.md" -o -name "*.sh" -o -name "*.ps1" -o -name "*.yaml" -o -name "*.yml" -o -name ".gitignore" -o -name "VERSION" \) -not -path "$SKILL_DIR/.git/*" -print0)

if $SECRETS_FOUND; then
  echo "❌ Secrets detectados — build abortado:"
  echo "$SECRETS_REPORT"
  echo "   Corregí los archivos y volvé a ejecutar."
  exit 1
fi

echo "✅ No se detectaron secrets"
echo ""

# --- Paso 4: Generar MANIFEST.md ---
echo "📋 Generando MANIFEST.md..."

MANIFEST_FILE="$SKILL_DIR/MANIFEST.md"
MANIFEST_TEMP=$(mktemp)
FILE_COUNT=0

{
  echo "# bizuit-sdd v$VERSION — Manifest"
  echo ""
  echo "Generado: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  echo "## Archivos incluidos"
  echo ""
  echo "| Archivo | SHA256 |"
  echo "|---|---|"
} > "$MANIFEST_TEMP"

while IFS= read -r -d '' file; do
  REL_PATH="${file#$SKILL_DIR/}"
  is_excluded "$REL_PATH" && continue
  is_custom_rule "$REL_PATH" && continue
  HASH=$(shasum -a 256 "$file" | cut -d' ' -f1)
  echo "| $REL_PATH | \`${HASH:0:16}...\` |" >> "$MANIFEST_TEMP"
  FILE_COUNT=$((FILE_COUNT + 1))
done < <(find "$SKILL_DIR" -type f -not -path "$SKILL_DIR/.git/*" -print0 | sort -z)

{
  echo ""
  echo "**Total: $FILE_COUNT archivos**"
  echo ""
  echo "## Archivos excluidos (no distribuidos)"
  echo ""
  echo "- processes/ (data de clientes)"
  echo "- .env (credenciales)"
  echo "- .engram/ (sesiones)"
  echo "- dist/ (artefactos generados)"
  echo "- docs/pilots/ (pilotos internos)"
  echo "- rules/custom/*.md excepto README.md (reglas locales del cliente)"
} >> "$MANIFEST_TEMP"

mv "$MANIFEST_TEMP" "$MANIFEST_FILE"
echo "✅ MANIFEST.md generado ($FILE_COUNT archivos)"
echo ""

# --- Si es dry-run, terminar acá ---
if $DRY_RUN; then
  echo "✅ Dry run complete. No issues found."
  echo "   VERSION: $VERSION"
  echo "   Archivos: $FILE_COUNT"
  echo "   No se generaron artefactos en dist/"
  exit 0
fi

# --- Paso 5: Generar zip ---
echo "📦 Generando zip..."

DIST_DIR="$SKILL_DIR/dist"
mkdir -p "$DIST_DIR"
ZIP_FILE="$DIST_DIR/bizuit-sdd-v${VERSION}.zip"

cd "$SKILL_DIR"
zip -r "$ZIP_FILE" . \
  -x ".git/*" \
  -x "processes/*" \
  -x ".env" \
  -x ".engram/*" \
  -x "dist/*" \
  -x "docs/pilots/*" \
  > /dev/null 2>&1

echo "✅ Zip generado: $ZIP_FILE ($(du -h "$ZIP_FILE" | cut -f1))"
echo ""

# --- Paso 6: Generar concatenado para Claude app ---
echo "📄 Generando concatenado para Claude app..."

CONCAT_FILE="$DIST_DIR/bizuit-sdd-v${VERSION}-claude-app.md"

cat > "$CONCAT_FILE" << HEADER
# bizuit-sdd v${VERSION} — Skill Completo para Claude app

> Este archivo contiene el skill bizuit-sdd completo.
> Para usarlo, subilo a Project Knowledge en claude.ai.
> Todos los outputs son en español.
>
> **Limitaciones:** Las specs se generan en el chat, no se guardan en disco.
> Para uso productivo, instalá Claude Code CLI (ver guia-rapida.md).

## Instrucciones de Uso
1. Subir este archivo a Project Knowledge de tu proyecto
2. Configurar las credenciales BIZUIT en el primer mensaje
3. Decir "crear proceso" para empezar

## Configuración (en vez de env vars)
Como Claude app no tiene env vars, el skill pide las credenciales en el primer mensaje:
- URL de Dashboard API
- URL de BPMN API
- Usuario y password
- Organization ID

Las credenciales se usan solo en la sesión actual y no se persisten.

HEADER

# Orden: SKILL.md → workflows → rules/sdd → rules/bizuit/* → templates
CONCAT_FILES=(
  "SKILL.md"
  "workflows/create.md"
  "workflows/edit.md"
  "workflows/reverse.md"
  "workflows/query.md"
)

for dir in rules/sdd rules/bizuit/common rules/bizuit/generation rules/bizuit/parsing; do
  for f in "$SKILL_DIR"/$dir/*.md; do
    [[ -f "$f" ]] && CONCAT_FILES+=("$dir/$(basename "$f")")
  done
done

CONCAT_FILES+=("templates/process-spec.md")

for rel_path in "${CONCAT_FILES[@]}"; do
  full_path="$SKILL_DIR/$rel_path"
  if [[ -f "$full_path" ]]; then
    {
      echo "---"
      echo "<!-- FILE: $rel_path -->"
      echo ""
      cat "$full_path"
      echo ""
    } >> "$CONCAT_FILE"
  fi
done

CONCAT_SIZE=$(du -k "$CONCAT_FILE" | cut -f1)
echo "✅ Concatenado generado: $CONCAT_FILE (${CONCAT_SIZE}KB)"

if [[ $CONCAT_SIZE -gt 200 ]]; then
  echo "⚠️  Archivo concatenado: ${CONCAT_SIZE}KB — puede exceder el límite de Project Knowledge (~200KB)"
fi

echo ""
echo "==========================="
echo "✅ Build completo — v$VERSION"
echo "   📦 Zip: $ZIP_FILE"
echo "   📄 Concatenado: $CONCAT_FILE"
echo "   📋 MANIFEST: $MANIFEST_FILE"
echo ""
echo "Próximo paso: commiteá los cambios y hacé push."

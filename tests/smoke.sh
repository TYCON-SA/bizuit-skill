#!/bin/bash
# bizuit-sdd smoke tests
# Run from skill root: cd ~/.claude/skills/bizuit-sdd && bash tests/smoke.sh

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SKILL_DIR"

PASS=0
FAIL=0
TOTAL=0

check() {
    TOTAL=$((TOTAL + 1))
    if [ "$1" = "true" ]; then
        echo "  [PASS] $2"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $2"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== bizuit-sdd smoke tests ==="
echo ""

# --- MANIFEST integrity ---
echo "[MANIFEST integrity]"
if [ ! -f MANIFEST.md ]; then
    check false "MANIFEST.md exists"
else
    check true "MANIFEST.md exists"
    # Check each file listed in MANIFEST exists
    MANIFEST_FILES=$(grep '^\| ' MANIFEST.md | grep -v '^\| Archivo' | grep -v '^\|---' | sed 's/| //g' | sed 's/ |.*//g' | tr -d ' ')
    MISSING=0
    for f in $MANIFEST_FILES; do
        if [ ! -f "$f" ]; then
            echo "    Missing: $f"
            MISSING=$((MISSING + 1))
        fi
    done
    if [ "$MISSING" -eq 0 ]; then
        check true "All MANIFEST files exist"
    else
        check false "All MANIFEST files exist ($MISSING missing)"
    fi
    # REVERSE check: verify all distributable files on disk are listed in MANIFEST
    UNLISTED=0
    DISK_FILES=$(find . -type f \( -name "*.md" -o -name "*.sh" -o -name "*.bpmn" -o -name "*.vdw" -o -name "*.ps1" \) \
        ! -name ".DS_Store" ! -name ".bizuit-config.yaml" ! -name "MANIFEST.md" \
        ! -path "./.git/*" ! -path "./.engram/*" ! -path "./dist/*" ! -path "./processes/*" \
        | sed 's|^\./||' | sort)
    for df in $DISK_FILES; do
        if ! grep -q "| $df |" MANIFEST.md; then
            echo "    Unlisted on disk: $df"
            UNLISTED=$((UNLISTED + 1))
        fi
    done
    if [ "$UNLISTED" -eq 0 ]; then
        check true "All disk files listed in MANIFEST (reverse check)"
    else
        check false "All disk files listed in MANIFEST ($UNLISTED unlisted)"
    fi
fi
echo ""

# --- SKILL.md structural checks ---
echo "[SKILL.md structural checks]"

# Description length
DESC_WORDS=$(grep '^description:' SKILL.md | head -1 | wc -w | tr -d ' ')
if [ "$DESC_WORDS" -ge 20 ]; then
    check true "Description length: $DESC_WORDS words (>= 20)"
else
    check false "Description length: $DESC_WORDS words (>= 20)"
fi

# Examples section
EXAMPLE_COUNT=$(grep -c '### Example:' SKILL.md)
if [ "$EXAMPLE_COUNT" -ge 4 ]; then
    check true "Examples section: $EXAMPLE_COUNT found (>= 4)"
else
    check false "Examples section: $EXAMPLE_COUNT found (>= 4)"
fi

# Word count
WORD_COUNT=$(wc -w < SKILL.md | tr -d ' ')
if [ "$WORD_COUNT" -lt 5000 ]; then
    check true "Word count: $WORD_COUNT (< 5000)"
else
    check false "Word count: $WORD_COUNT (< 5000)"
fi

# Version consistency
if [ -f VERSION ]; then
    FILE_VERSION=$(cat VERSION | tr -d '[:space:]')
    SKILL_VERSION=$(grep 'Versión:' SKILL.md | head -1 | sed 's/.*Versión:[[:space:]]*//' | tr -d '[:space:]*')
    if [ "$FILE_VERSION" = "$SKILL_VERSION" ]; then
        check true "Version consistency: $FILE_VERSION == $SKILL_VERSION"
    else
        check false "Version consistency: $FILE_VERSION != $SKILL_VERSION"
    fi
else
    check false "VERSION file exists"
fi

# No inline AUTH_FAILED
AUTH_COUNT=$(grep -c 'AUTH_FAILED' SKILL.md || true)
if [ "$AUTH_COUNT" -eq 0 ]; then
    check true "No inline AUTH_FAILED in SKILL.md"
else
    check false "No inline AUTH_FAILED in SKILL.md ($AUTH_COUNT hits)"
fi

# Section order
SECTIONS=$(grep '^## ' SKILL.md | sed 's/## //')
EXPECTED_ORDER="Instruccion|Router|Examples|Validate|Workflow|Rules|Process|Health"
ORDER_OK=true
PREV_IDX=0
for keyword in "Instrucci" Router Examples Validate Workflow Rules Process Health; do
    LINE=$(grep -n "^## " SKILL.md | grep -i "$keyword" | head -1 | cut -d: -f1)
    if [ -z "$LINE" ]; then
        ORDER_OK=false
        break
    fi
    if [ "$LINE" -lt "$PREV_IDX" ]; then
        ORDER_OK=false
        break
    fi
    PREV_IDX=$LINE
done
check "$ORDER_OK" "Section order: Instruccion > Router > Examples > Validate > Workflow > Rules > Process > Health"
echo ""

# --- Workflow invariants ---
echo "[Workflow invariants]"

# reverse.md error handling
if [ -f workflows/reverse.md ]; then
    REV_ERRORS=$(grep -c 'AUTH_FAILED\|API_ERROR\|VDW_EMPTY' workflows/reverse.md || true)
    if [ "$REV_ERRORS" -ge 1 ]; then
        check true "reverse.md: error handling inline ($REV_ERRORS codes)"
    else
        check false "reverse.md: error handling inline (0 codes)"
    fi
else
    check false "reverse.md exists"
fi

# edit.md error handling
if [ -f workflows/edit.md ]; then
    EDIT_ERRORS=$(grep -c 'AUTH_FAILED\|API_ERROR\|SPEC_DRIFT' workflows/edit.md || true)
    if [ "$EDIT_ERRORS" -ge 1 ]; then
        check true "edit.md: error handling inline ($EDIT_ERRORS codes)"
    else
        check false "edit.md: error handling inline (0 codes)"
    fi
else
    check false "edit.md exists"
fi

# phase-4-generation error handling
GEN_FILE=$(find workflows -name '*phase*4*' -o -name '*generation*' 2>/dev/null | head -1)
if [ -z "$GEN_FILE" ]; then
    GEN_FILE="workflows/create.md"
fi
if [ -f "$GEN_FILE" ]; then
    GEN_ERRORS=$(grep -c 'BPMN_INVALID\|PERSIST_FAIL' "$GEN_FILE" || true)
    if [ "$GEN_ERRORS" -ge 1 ]; then
        check true "$(basename $GEN_FILE): error handling inline ($GEN_ERRORS codes)"
    else
        check false "$(basename $GEN_FILE): error handling inline (0 codes)"
    fi
else
    check false "generation workflow exists"
fi
echo ""

echo "=== Results: $PASS/$TOTAL passed ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
exit 0

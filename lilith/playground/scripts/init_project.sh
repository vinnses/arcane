#!/bin/bash
set -euo pipefail

# =============================================================================
# init_project.sh
# Reads PROJECT from .env and renames the placeholder package + all references.
# Run once after cloning. Safe to re-run (idempotent if already renamed).
# =============================================================================

PLACEHOLDER="playground"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

# ── Load PROJECT from .env ───────────────────────────────────────────────────
if [ ! -f .env ]; then
    echo "❌ .env not found. Create it with PROJECT=yourname"
    exit 1
fi

PROJECT=$(grep -E '^PROJECT=' .env | cut -d'=' -f2 | tr -d '"' | tr -d "'" | tr -d ' ')

if [ -z "$PROJECT" ]; then
    echo "❌ PROJECT is empty in .env"
    exit 1
fi

if [ "$PROJECT" = "$PLACEHOLDER" ]; then
    echo "⚠️  PROJECT is still '$PLACEHOLDER'. Edit .env first."
    exit 1
fi

# ── Validate name (Python package rules) ─────────────────────────────────────
if ! echo "$PROJECT" | grep -qE '^[a-z][a-z0-9_]*$'; then
    echo "❌ Invalid package name: '$PROJECT'"
    echo "   Must start with lowercase letter, contain only [a-z0-9_]"
    exit 1
fi

echo ">>> Renaming '$PLACEHOLDER' → '$PROJECT'"

# ── Rename directory ─────────────────────────────────────────────────────────
if [ -d "$PLACEHOLDER" ]; then
    mv "$PLACEHOLDER" "$PROJECT"
    echo "  ✓ Directory: $PLACEHOLDER/ → $PROJECT/"
elif [ -d "$PROJECT" ]; then
    echo "  ✓ Directory already renamed to $PROJECT/"
else
    echo "❌ Neither '$PLACEHOLDER/' nor '$PROJECT/' found."
    exit 1
fi

# ── Replace in files ─────────────────────────────────────────────────────────
FILES=(
    "pyproject.toml"
    "Makefile"
    "tests/test_placeholder.py"
    "$PROJECT/__init__.py"
    "$PROJECT/config/__init__.py"
    "$PROJECT/utils/logging.py"
)

for f in "${FILES[@]}"; do
    if [ -f "$f" ]; then
        if grep -q "$PLACEHOLDER" "$f" 2>/dev/null; then
            sed -i "s/$PLACEHOLDER/$PROJECT/g" "$f"
            echo "  ✓ Updated: $f"
        fi
    fi
done

echo ""
echo "✅ Project initialized as '$PROJECT'"
echo ""
echo "Next steps:"
echo "  docker compose --profile dev up -d    # Start dev container"
echo "  make jupyter                          # Or start Jupyter"
echo "  make code-server                      # Or start Code Server"

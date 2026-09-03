#!/bin/bash
# ─────────────────────────────────────────────────────────────
# sync-md-ts.sh — Sincroniza teachme.md → teachme.ts
# ─────────────────────────────────────────────────────────────
#
# Toma la fuente canónica (.md) y actualiza el instructionsPrompt
# del agente activo (.ts en ~/.agents/).
#
# Uso:
#   ./sync-md-ts.sh              # Sincronizar
#   ./sync-md-ts.sh --dry-run    # Mostrar cambios sin aplicar
#   ./sync-md-ts.sh --help       # Ayuda
#
# ─────────────────────────────────────────────────────────────

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Rutas
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HELPER="$SCRIPT_DIR/sync_helper.py"

print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${CYAN}→${NC} $1"; }

# Resolver Python desde PATH para funcionar en Windows, macOS y Linux.
if command -v python >/dev/null 2>&1; then
    PYTHON_CMD=$(command -v python)
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD=$(command -v python3)
else
    print_error "Python no encontrado en PATH"
    print_info "Instala Python 3 y vuelve a ejecutar este script"
    exit 1
fi

# Verificar que el helper existe
if [ ! -f "$HELPER" ]; then
    print_error "No se encontró: $HELPER"
    exit 1
fi

# Ejecutar
case "${1:-}" in
    --help|-h)
        echo "Uso: ./sync-md-ts.sh [opción]"
        echo ""
        echo "Opciones:"
        echo "  (sin args)    Sincronizar .md → .ts"
        echo "  --check, -c   Verificar si .md y .ts están sincronizados"
        echo "  --version, -v Mostrar la versión de la fuente y de la instalada"
        echo "  --dry-run, -n Mostrar qué se sincronizaría sin cambiar nada"
        echo "  --help, -h    Muestra esta ayuda"
        ;;
    --check|-c)
        "$PYTHON_CMD" "$HELPER" --check
        ;;
    --version|-v)
        "$PYTHON_CMD" "$HELPER" --version
        ;;
    --dry-run|-n)
        "$PYTHON_CMD" "$HELPER" --dry-run
        ;;
    *)
        "$PYTHON_CMD" "$HELPER"
        ;;
esac

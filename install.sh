#!/bin/bash
# ─────────────────────────────────────────────────────────────
# install.sh — Instala teachme como agente global de Freebuff
# ─────────────────────────────────────────────────────────────
#
# Uso:
#   ./install.sh          # Instala el agente
#   ./install.sh --check  # Verifica la instalación
#   ./install.sh --uninstall  # Elimina el agente
#
# Requisitos:
#   - Freebuff instalado (npm install -g freebuff)
#   - Node.js ≥ 18
# ─────────────────────────────────────────────────────────────

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="$HOME/.agents"
AGENT_FILE="$AGENTS_DIR/teachme.ts"
SOURCE_FILE="$SCRIPT_DIR/.agents/teachme.ts"
HELPER="$SCRIPT_DIR/sync_helper.py"

find_python() {
    if command -v python >/dev/null 2>&1; then
        command -v python
    elif command -v python3 >/dev/null 2>&1; then
        command -v python3
    else
        return 1
    fi
}

# ─── Funciones ────────────────────────────────────────────────

print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_prerequisites() {
    echo "Comprobando prerrequisitos..."
    
    # Freebuff
    if command -v freebuff &> /dev/null; then
        print_ok "Freebuff instalado"
    else
        print_error "Freebuff no encontrado. Instálalo con: npm install -g freebuff"
        return 1
    fi
    
    # Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            print_ok "Node.js $(node -v)"
        else
            print_error "Node.js ≥ 18 requerido (tienes $(node -v))"
            return 1
        fi
    else
        print_error "Node.js no encontrado"
        return 1
    fi
    
    return 0
}

install_agent() {
    echo ""
    echo "Instalando teachme..."
    
    # Crear carpeta ~/.agents si no existe
    if [ ! -d "$AGENTS_DIR" ]; then
        mkdir -p "$AGENTS_DIR"
        print_ok "Creada carpeta $AGENTS_DIR"
    fi
    
    # Prefer the legacy TypeScript source when present; otherwise generate it
    # from the canonical Markdown source so a clean checkout is installable.
    if [ -f "$SOURCE_FILE" ]; then
        cp "$SOURCE_FILE" "$AGENT_FILE"
    else
        PYTHON_CMD=$(find_python) || {
            print_error "Python no encontrado; es necesario para generar el agente desde teachme.md"
            exit 1
        }
        if ! "$PYTHON_CMD" "$HELPER" --generate --output "$AGENT_FILE"; then
            print_error "No se pudo generar el agente desde: $SCRIPT_DIR/.agents/teachme.md"
            exit 1
        fi
    fi
    print_ok "Agente instalado en: $AGENT_FILE"
    
    # Verificar que Freebuff puede cargarlo
    if node --check "$AGENT_FILE" 2>/dev/null; then
        print_ok "Sintaxis del agente correcta"
    else
        print_warn "Error de sintaxis en el agente (puede que Freebuff no lo cargue)"
    fi
    
    echo ""
    echo -e "${GREEN}¡Instalación completa!${NC}"
    echo ""
    echo "Para usar el agente:"
    echo "  1. Abre Freebuff en esta carpeta: cd $SCRIPT_DIR && freebuff"
    echo "  2. Escribe: @teachme enséñame qué es un hash"
    echo ""
    echo "Si ya tenías Freebuff abierto, cierra y abre una sesión nueva."
}

check_installation() {
    echo "Verificando instalación..."
    echo ""
    
    # Agente
    if [ -f "$AGENT_FILE" ]; then
        print_ok "Agente encontrado: $AGENT_FILE"
        
        # Sintaxis
        if node --check "$AGENT_FILE" 2>/dev/null; then
            print_ok "Sintaxis correcta"
        else
            print_error "Error de sintaxis"
            return 1
        fi
    else
        print_error "Agente no encontrado en: $AGENT_FILE"
        echo "  Ejecuta: ./install.sh"
        return 1
    fi
    
    # Freebuff
    if command -v freebuff &> /dev/null; then
        print_ok "Freebuff instalado"
    else
        print_warn "Freebuff no encontrado (no podrás usar el agente)"
    fi
    
    echo ""
    echo "Para probar: cd $SCRIPT_DIR && freebuff"
    echo "Luego escribe: @teachme enséñame qué es un hash"
}

uninstall_agent() {
    echo "Desinstalando teachme..."
    
    if [ -f "$AGENT_FILE" ]; then
        rm "$AGENT_FILE"
        print_ok "Agente eliminado: $AGENT_FILE"
    else
        print_warn "El agente no estaba instalado"
    fi
    
    # Preguntar si eliminar la carpeta si está vacía
    if [ -d "$AGENTS_DIR" ] && [ -z "$(ls -A "$AGENTS_DIR")" ]; then
        read -p "¿Eliminar carpeta vacía $AGENTS_DIR? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rmdir "$AGENTS_DIR"
            print_ok "Carpeta eliminada: $AGENTS_DIR"
        fi
    fi
    
    echo ""
    echo "Desinstalación completa. Los archivos del vault no se tocaron."
}

# ─── Main ─────────────────────────────────────────────────────

case "${1:-}" in
    --check|-c)
        check_installation
        ;;
    --uninstall|-u)
        uninstall_agent
        ;;
    --help|-h)
        echo "Uso: ./install.sh [opción]"
        echo ""
        echo "Opciones:"
        echo "  (sin args)    Instala el agente"
        echo "  --check, -c   Verifica la instalación"
        echo "  --uninstall   Elimina el agente"
        echo "  --help, -h    Muestra esta ayuda"
        ;;
    *)
        if check_prerequisites; then
            install_agent
        else
            exit 1
        fi
        ;;
esac

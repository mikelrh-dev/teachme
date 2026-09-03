#!/bin/bash
# ─────────────────────────────────────────────────────────────
# test.sh — Tests básicos para teachme
# ─────────────────────────────────────────────────────────────
#
# Verifica integridad del agente, scripts y configuración.
# No testea el comportamiento del modelo (eso depende de Freebuff).
#
# Uso:
#   ./test.sh           # Ejecutar todos los tests
#   ./test.sh --verbose # Mostrar más detalle
#
# ─────────────────────────────────────────────────────────────

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Contadores
PASS=0
FAIL=0
SKIP=0

# Rutas
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MD_FILE="$SCRIPT_DIR/.agents/teachme.md"
TS_GLOBAL="$HOME/.agents/teachme.ts"
TS_BAK="$HOME/.agents/teachme.ts.bak"
TEMP_HOME="$(mktemp -d 2>/dev/null || mktemp -d -t teachme)"
INSTALL_SH="$SCRIPT_DIR/install.sh"
SYNC_SH="$SCRIPT_DIR/sync-md-ts.sh"
SYNC_PY="$SCRIPT_DIR/sync_helper.py"
LOG_FILE="$SCRIPT_DIR/LEARNING_LOG.md"
VAULT_DIR="$SCRIPT_DIR/hash-vault"

# ─── Funciones ────────────────────────────────────────────────

pass() {
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}✗${NC} $1"
}

skip() {
    SKIP=$((SKIP + 1))
    echo -e "  ${YELLOW}○${NC} $1 (skip)"
}

section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
}

# ─── Tests ────────────────────────────────────────────────────

section "1. Estructura de archivos"

# teachme.md
if [ -f "$MD_FILE" ]; then
    pass "teachme.md existe"
    
    # Frontmatter
    if head -1 "$MD_FILE" | grep -q "^---"; then
        pass "teachme.md tiene frontmatter YAML"
    else
        fail "teachme.md no tiene frontmatter YAML"
    fi
    
    # Nombre en frontmatter
    if grep -q "^name: teachme" "$MD_FILE"; then
        pass "teachme.md tiene name correcto"
    else
        fail "teachme.md falta name en frontmatter"
    fi
    
    # Secciones clave
    for section in "Filosofía" "Reglas duras" "Proceso" "Quiz" "Modo repo" "LEARNING_LOG"; do
        if grep -q "## .*${section}" "$MD_FILE"; then
            pass "Sección '${section}' presente"
        else
            fail "Sección '${section}' faltante"
        fi
    done
else
    fail "teachme.md no existe"
fi

cleanup() {
    rm -rf "$TEMP_HOME"
}
trap cleanup EXIT

# teachme.ts global
if [ -f "$TS_GLOBAL" ]; then
    pass "teachme.ts global existe"
else
    skip "teachme.ts global no existe (se instala con ./install.sh)"
fi

# LEARNING_LOG.md
if [ -f "$LOG_FILE" ]; then
    pass "LEARNING_LOG.md existe"
    
    # Frontmatter del log
    if head -1 "$LOG_FILE" | grep -q "^---"; then
        pass "LEARNING_LOG.md tiene frontmatter"
    else
        fail "LEARNING_LOG.md falta frontmatter"
    fi
else
    skip "LEARNING_LOG.md no existe (se crea al usar el agente)"
fi

# hash-vault
if [ -d "$VAULT_DIR" ]; then
    pass "hash-vault/ existe"
    
    # Home.md
    if [ -f "$VAULT_DIR/Home.md" ]; then
        pass "hash-vault/Home.md existe"
    else
        fail "hash-vault/Home.md faltante"
    fi
    
    # Carpetas
    for dir in notas visuales flashcards; do
        if [ -d "$VAULT_DIR/$dir" ]; then
            pass "hash-vault/$dir/ existe"
        else
            fail "hash-vault/$dir/ faltante"
        fi
    done
else
    skip "hash-vault/ no existe"
fi

section "2. Scripts"

# install.sh
if [ -f "$INSTALL_SH" ]; then
    pass "install.sh existe"
    
    if [ -x "$INSTALL_SH" ]; then
        pass "install.sh es ejecutable"
    else
        fail "install.sh no es ejecutable"
    fi
    
    # Verificar que tiene las opciones
    if grep -q "\-\-check" "$INSTALL_SH"; then
        pass "install.sh tiene opción --check"
    else
        fail "install.sh falta opción --check"
    fi
    
    if grep -q "\-\-uninstall" "$INSTALL_SH"; then
        pass "install.sh tiene opción --uninstall"
    else
        fail "install.sh falta opción --uninstall"
    fi
else
    fail "install.sh no existe"
fi

# sync-md-ts.sh
if [ -f "$SYNC_SH" ]; then
    pass "sync-md-ts.sh existe"
    
    if [ -x "$SYNC_SH" ]; then
        pass "sync-md-ts.sh es ejecutable"
    else
        fail "sync-md-ts.sh no es ejecutable"
    fi
else
    fail "sync-md-ts.sh no existe"
fi

# sync_helper.py
if [ -f "$SYNC_PY" ]; then
    pass "sync_helper.py existe"
else
    fail "sync_helper.py no existe"
fi

section "3. Sintaxis y configuración"

# Sintaxis del .ts
if [ -f "$TS_GLOBAL" ]; then
    if node --check "$TS_GLOBAL" 2>/dev/null; then
        pass "teachme.ts tiene sintaxis válida"
    else
        fail "teachme.ts tiene errores de sintaxis"
    fi
    
    # Verificar que tiene el modelo correcto
    if grep -q "z-ai/glm-5.3-flash" "$TS_GLOBAL"; then
        pass "Modelo configurado: z-ai/glm-5.3-flash"
    else
        fail "Modelo no encontrado o incorrecto"
    fi
    
    # Verificar que tiene las tools
    for tool in read_files code_search glob ask_user web_search write_todos; do
        if grep -q "'$tool'" "$TS_GLOBAL"; then
            pass "Tool '$tool' configurada"
        else
            fail "Tool '$tool' faltante"
        fi
    done

    # Versionado: el .ts lleva estampada la version de la fuente
    if grep -q '^// @teachme v[0-9]\+\.[0-9]\+\.[0-9]\+' "$TS_GLOBAL"; then
        pass "Version estampada en el .ts ($(grep -o 'v[0-9]\+\.[0-9]\+\.[0-9]\+' "$TS_GLOBAL" | head -1))"
    else
        fail "Falta la version estampada en el .ts (ejecuta ./sync-md-ts.sh)"
    fi
else
    skip "No se pueden verificar sintaxis/config (agente no instalado)"
fi

# Sintaxis del .md (básico)
if [ -f "$MD_FILE" ]; then
    # Verificar que tiene las reglas clave
    if grep -q "Exactitud no negociable" "$MD_FILE"; then
        pass "Regla 'Exactitud' presente"
    else
        fail "Regla 'Exactitud' faltante"
    fi
    
    if grep -q "Solo modelos FREE" "$MD_FILE"; then
        pass "Regla 'Solo FREE' presente"
    else
        fail "Regla 'Solo FREE' faltante"
    fi
    
    if grep -q "Cierre de sesión" "$MD_FILE"; then
        pass "Sección 'Cierre de sesión' presente"
    else
        fail "Sección 'Cierre de sesión' faltante"
    fi
    
    # Version declarada en el frontmatter
    if grep -q '^version: [0-9]\+\.[0-9]\+\.[0-9]\+' "$MD_FILE"; then
        pass "Version declarada en el .md ($(grep -o '^version: [0-9.]\+' "$MD_FILE" | cut -d' ' -f2))"
    else
        fail "Falta 'version:' en el frontmatter del .md"
    fi
fi

# Generación desde un checkout limpio (no usa ni modifica el agente global).
if PYTHON_CMD=$(command -v python 2>/dev/null); then
    :
elif PYTHON_CMD=$(command -v python3 2>/dev/null); then
    :
else
    PYTHON_CMD=""
fi
if [ -n "$PYTHON_CMD" ]; then
    GENERATED_TS="$TEMP_HOME/.agents/teachme.ts"
    if "$PYTHON_CMD" "$SYNC_PY" --generate --output "$GENERATED_TS" >/dev/null 2>&1 \
        && node --check "$GENERATED_TS" >/dev/null 2>&1 \
        && grep -q "^  id: 'teachme'" "$GENERATED_TS" \
        && grep -q "^  model: 'z-ai/glm-5.3-flash'" "$GENERATED_TS" \
        && "$PYTHON_CMD" "$SYNC_PY" --check --output "$GENERATED_TS" >/dev/null 2>&1; then
        pass "Generación desde .md en checkout limpio funciona"
    else
        fail "Generación desde .md en checkout limpio falló"
    fi
else
    skip "Generación en checkout limpio (Python no disponible)"
fi

# El helper debe poder imprimir Unicode aunque Python herede cp1252.
if [ -n "$PYTHON_CMD" ]; then
    if PYTHONIOENCODING=cp1252 "$PYTHON_CMD" "$SYNC_PY" --help >/dev/null 2>&1; then
        pass "sync_helper.py --help funciona con consola Windows cp1252"
    else
        fail "sync_helper.py --help falla con consola Windows cp1252"
    fi
else
    skip "Prueba de consola cp1252 (Python no disponible)"
fi

section "4. Sincronización .md ↔ .ts"

if [ -f "$TS_GLOBAL" ] && [ -f "$MD_FILE" ]; then
    # Validación robusta vía sync_helper.py --check (compara instructionsPrompt normalizado)
    if [ -f "$SYNC_PY" ]; then
        if [ -n "$PYTHON_CMD" ] && "$PYTHON_CMD" "$SYNC_PY" --check >/dev/null 2>&1; then
            pass "Sincronizado: .md y .ts coinciden (sync_helper --check)"
        else
            # Fallback: conteo de menciones para diagnóstico
            MD_COUNT=$(grep -c "Cierre de sesión" "$MD_FILE" 2>/dev/null || echo "0")
            TS_COUNT=$(grep -c "Cierre de sesión" "$TS_GLOBAL" 2>/dev/null || echo "0")
            fail "Desincronizado: .md y .ts no coinciden (ejecutá ./sync-md-ts.sh) — md:$MD_COUNT ts:$TS_COUNT"
        fi
    else
        # Fallback legacy si no hay helper
        MD_COUNT=$(grep -c "Cierre de sesión" "$MD_FILE" 2>/dev/null || echo "0")
        TS_COUNT=$(grep -c "Cierre de sesión" "$TS_GLOBAL" 2>/dev/null || echo "0")
        if [ "$MD_COUNT" -eq "$TS_COUNT" ] && [ "$MD_COUNT" -gt 0 ]; then
            pass "Contenido sincronizado (ambos tienen $MD_COUNT menciones) [fallback]"
        elif [ "$MD_COUNT" -ne "$TS_COUNT" ]; then
            fail "Desincronizado: .md=$MD_COUNT, .ts=$TS_COUNT [fallback]"
        else
            skip "No se pudo verificar sincronización"
        fi
    fi
else
    skip "No se pueden comparar .md y .ts"
fi

section "5. Prueba de scripts (dry-run)"

# install.sh --check
if [ -f "$INSTALL_SH" ] && [ -x "$INSTALL_SH" ]; then
    if OUTPUT=$("$INSTALL_SH" --check 2>&1); then
        if echo "$OUTPUT" | grep -q "Agente encontrado\|Sintaxis correcta"; then
            pass "install.sh --check funciona"
        else
            fail "install.sh --check falló"
        fi
    else
        skip "install.sh --check requiere instalación previa"
    fi
else
    skip "install.sh no disponible"
fi

# install.sh debe generar el agente cuando no existe una fuente .ts local.
CLEAN_HOME="$TEMP_HOME/clean-home"
if [ -n "$PYTHON_CMD" ] && [ -f "$INSTALL_SH" ] && [ -x "$INSTALL_SH" ]; then
    if HOME="$CLEAN_HOME" "$INSTALL_SH" --check >/dev/null 2>&1; then
        fail "install.sh --check no detectó un agente ausente"
    elif HOME="$CLEAN_HOME" "$INSTALL_SH" >/dev/null 2>&1 \
        && node --check "$CLEAN_HOME/.agents/teachme.ts" >/dev/null 2>&1 \
        && HOME="$CLEAN_HOME" "$PYTHON_CMD" "$SYNC_PY" --check --output "$CLEAN_HOME/.agents/teachme.ts" >/dev/null 2>&1; then
        pass "install.sh genera el agente desde .md en una instalación limpia"
    else
        fail "install.sh no genera el agente en una instalación limpia"
    fi
else
    skip "Instalación limpia (Python/install.sh no disponible)"
fi

# sync-md-ts.sh --dry-run
if [ -f "$SYNC_SH" ] && [ -x "$SYNC_SH" ]; then
    OUTPUT=$("$SYNC_SH" --dry-run 2>&1)
    if echo "$OUTPUT" | grep -q "Dry run\|Total:"; then
        pass "sync-md-ts.sh --dry-run funciona"
    else
        fail "sync-md-ts.sh --dry-run falló"
    fi
else
    skip "sync-md-ts.sh no disponible"
fi

# ─── Resumen ──────────────────────────────────────────────────

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  RESUMEN${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}✓ Pasaron:${NC} $PASS"
echo -e "  ${RED}✗ Fallaron:${NC} $FAIL"
echo -e "  ${YELLOW}○ Saltados:${NC} $SKIP"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}¡Todos los tests pasaron!${NC}"
    exit 0
else
    echo -e "${RED}Algunos tests fallaron.${NC}"
    exit 1
fi

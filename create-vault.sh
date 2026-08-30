#!/bin/bash
# ─────────────────────────────────────────────────────────────
# create-vault.sh — Crea la estructura base de un vault
# ─────────────────────────────────────────────────────────────
#
# Uso:
#   ./create-vault.sh <tema>
#
# Ejemplo:
#   ./create-vault.sh redes
#   ./create-vault.sh "inteligencia artificial"
#
# Resultado:
#   crea-<tema>-vault/
#   ├── index.md
#   ├── log.md
#   ├── Home.md
#   ├── README.md
#   ├── notas/
#   ├── entidades/
#   ├── comparaciones/
#   ├── visuales/
#   └── flashcards/
#
# ─────────────────────────────────────────────────────────────

set -e

# Colores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

print_ok() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${CYAN}→${NC} $1"; }

# ─── Validar argumentos ───────────────────────────────────────

if [ -z "$1" ]; then
    echo "Uso: ./create-vault.sh <tema>"
    echo ""
    echo "Ejemplo:"
    echo "  ./create-vault.sh redes"
    echo "  ./create-vault.sh \"inteligencia artificial\""
    exit 1
fi

TEMA="$1"
TEMA_KEBAB=$(echo "$TEMA" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g')
VAULT_DIR="$(dirname "$0")/${TEMA_KEBAB}-vault"
TODAY=$(date +%Y-%m-%d)

# ─── Crear estructura ────────────────────────────────────────

print_info "Creando vault: ${TEMA_KEBAB}-vault/"

mkdir -p "$VAULT_DIR/notas"
mkdir -p "$VAULT_DIR/entidades"
mkdir -p "$VAULT_DIR/comparaciones"
mkdir -p "$VAULT_DIR/visuales"
mkdir -p "$VAULT_DIR/flashcards"

print_ok "Carpetas creadas"

# ─── index.md ────────────────────────────────────────────────

cat > "$VAULT_DIR/index.md" << EOF
# Índice — ${TEMA}

Vault generado por teachme. Última actualización: ${TODAY}.

## Conceptos
<!-- El agente rellenará aquí con las notas creadas -->

## Entidades
<!-- El agente rellenará aquí con las entidades creadas -->

## Comparaciones
<!-- El agente rellenará aquí con las comparaciones creadas -->

## Estadísticas
- Total conceptos: 0
- Total entidades: 0
- Total comparaciones: 0
- Última actualización: ${TODAY}
EOF

print_ok "index.md creado"

# ─── log.md ──────────────────────────────────────────────────

cat > "$VAULT_DIR/log.md" << EOF
# Log — ${TEMA}

Registro de cambios en el vault.

## [${TODAY}] create | Vault inicial
- Creado: index.md, Home.md, README.md
- Carpetas: notas/, entidades/, comparaciones/, visuales/, flashcards/
EOF

print_ok "log.md creado"

# ─── Home.md ─────────────────────────────────────────────────

cat > "$VAULT_DIR/Home.md" << EOF
---
tags:
  - home
  - ${TEMA_KEBAB}
created: ${TODAY}
---

# ${TEMA} — Vault de estudio

## Mapa de dependencias

<!-- El agente rellenará con el grafo de dependencias del tema -->

\`\`\`mermaid
graph TD
    R1["Concepto base"] --> D1["Concepto derivado 1"]
    R1 --> D2["Concepto derivado 2"]
    D1 --> G["Objetivo"]
    D2 --> G
\`\`\`
Fuente: [[visuales/${TEMA_KEBAB}-home.mmd]]

## Ruta recomendada

<!-- El agente rellenará con el orden de estudio -->

1. [[notas/01 - Concepto base|Concepto base]]
2. [[notas/02 - Derivado 1|Derivado 1]]
3. [[notas/03 - Derivado 2|Derivado 2]]

## Nodos de refuerzo
<!-- El agente marcará aquí los conceptos con quiz fallado -->

## Índice completo
→ [[index|Ver todas las páginas]]
EOF

print_ok "Home.md creado"

# ─── README.md ───────────────────────────────────────────────

cat > "$VAULT_DIR/README.md" << EOF
# Vault de ${TEMA}

Vault autocontenido para estudiar ${TEMA}. Generado por @teachme.

## Cómo usar

1. Abrir esta carpeta en Obsidian
2. Empezar por [[Home|Home.md]]
3. Seguir la ruta recomendada
4. Responder auto-chequeos antes de avanzar
5. Repasar flashcards con plugin Spaced Repetition

## Estructura

- \`notas/\` — conceptos del tema
- \`entidades/\` — herramientas, proyectos, servicios
- \`comparaciones/\` — A vs B
- \`flashcards/\` — repaso espaciado
- \`visuales/\` — diagramas mermaid
- \`index.md\` — catálogo de todo
- \`log.md\` — registro de cambios

## Generado por

@teachme — profesor socrático de Freebuff
EOF

print_ok "README.md creado"

# ─── Flashcards template ─────────────────────────────────────

cat > "$VAULT_DIR/flashcards/${TEMA^} - Flashcards.md" << EOF
#flashcards

# ${TEMA} — Flashcards

## <Subtema>
<!-- El agente rellenará con las tarjetas del quiz -->
- Pregunta de ejemplo? :: Respuesta de ejemplo
EOF

print_ok "Flashcards template creado"

# ─── Resumen ─────────────────────────────────────────────────

echo ""
echo -e "${GREEN}Vault creado: ${VAULT_DIR}/${NC}"
echo ""
echo "Estructura:"
find "$VAULT_DIR" -type f | sed "s|$VAULT_DIR/|  |"
echo ""
echo "Próximos pasos:"
echo "  1. Abrir Freebuff en este directorio"
echo "  2. @teachme enséñame ${TEMA}"
echo "  3. Al final, elegir 'vault completo'"

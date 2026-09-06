[![ES](https://img.shields.io/badge/lang-ES-yellow)](README.es.md) [![EN](https://img.shields.io/badge/lang-EN-blue)](README.md)

![TeachMe — Arquitectura del agente de enseñanza socrática](docs/images/hero.png)

![Versión](https://img.shields.io/badge/version-1.2.1-brightgreen) [![Licencia: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

# 🧠 TeachMe — Agente de Enseñanza Socrático

> **En una línea:** No hay nada que memorizar — el agente construye un grafo de dependencias en tu cabeza. Verdades incondicionales primero, cada hecho colgando de lo que ya entiendes, y un quiz de 2 preguntas después de cada bloque para confirmar que el nodo está sólido antes de construir encima.

## Tabla de Contenidos

- [Instalación](#instalación)
- [Compatibilidad](#compatibilidad)
- [Cómo Funciona](#cómo-funciona)
- [Flujo de Aprendizaje](#flujo-de-aprendizaje)
- [Salida del Vault](#salida-del-vault)
- [Estructura de la Skill](#estructura-de-la-skill)
- [Contribuir](#contribuir)
- [Licencia](#licencia)

## Instalación

TeachMe es una **skill** — un solo archivo `SKILL.md` que cualquier agente de IA compatible puede cargar.

### 1. Clona el repo

```bash
git clone https://github.com/mikelrh-dev/teachme.git
```

### 2. Copia la skill al directorio de skills de tu agente

| Agente | Destino |
|--------|---------|
| **Claude Code** | `~/.agents/skills/teachme/SKILL.md` |
| **OpenCode** | `~/.config/opencode/skills/teachme/SKILL.md` |
| **Codex / Cursor / otro** | Consulta la documentación de tu agente para la ruta del directorio de skills |

Ejemplo para Claude Code:

```bash
mkdir -p ~/.agents/skills/teachme
cp teachme/SKILL.md ~/.agents/skills/teachme/SKILL.md
```

### 3. Verificación

Reinicia la sesión de tu agente. Luego escribí:

```
@teachme enseñame qué es un hash
```

Si responde y arranca el probe → instalado correctamente.

## Compatibilidad

TeachMe funciona con cualquier agente que soporte cargar skills desde un archivo `SKILL.md`:

| Agente | Estado |
|--------|--------|
| Claude Code | ✅ Nativo (`~/.agents/skills/`) |
| OpenCode | ✅ Nativo (`~/.config/opencode/skills/`) |
| Codex | ✅ Vía directorio de skills |
| Cursor | ✅ Vía rules / skills |
| Otros agentes LLM | ✅ Si cargan archivos de instrucciones `.md` |

**Requisitos:** Un agente LLM con acceso a herramientas (búsqueda web, lectura/escritura de archivos). No se necesita Node.js, Python ni otros runtimes — la skill es instrucciones puras en Markdown.

## Cómo Funciona

El agente detecta automáticamente qué modo usar según el directorio actual:

| | **VAULT** | **REPO** |
|---|---|---|
| **Propósito** | Aprender un tema general (HTTPS, hashes, redes…) | Absorber el código de un proyecto existente |
| **Cómo invocarlo** | `@teachme enseñame X` | `@teachme quiero absorber este codebase` |
| **Dónde abrir el agente** | En cualquier carpeta | Dentro del repo que quieres aprender |
| **Qué lee** | Conocimiento del agente + verificación web | Archivos del repo (`read_files`) |
| **Cómo enseña** | Conceptos abstractos + diagramas Mermaid | Fragmentos literales (`file:line`) |
| **Dónde queda el log** | `LEARNING_LOG.md` en el cwd | En el repo (o vault centralizado) |

> **¿Cómo sabe en qué modo está?**
> **Señales de código primero:** si el directorio actual tiene un `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, o un `.git` con código fuente → **MODO REPO**. Si no es un proyecto de código pero ya existe un `LEARNING_LOG.md` con el frontmatter de la skill → **MODO VAULT** (reanudando sesión). Si no hay código ni log → **MODO VAULT** (sesión nueva).

## Flujo de Aprendizaje

Cada sesión sigue el mismo ciclo:

| Fase | Qué pasa | Tu acción |
|---|---|---|
| **Probe** | Rondas de 2 preguntas para mapear tu nivel + una pregunta objetiva | Responde con honestidad — "no sé" es información valiosa, no un fracaso |
| **Plan** | Propone currículum + mapa de dependencias (Mermaid) | Revisá y dale tu aprobación (o ajustá el alcance) |
| **Teach** | Bloque por bloque: motivar → establecer → conectar → **quiz de 2 preguntas** | Intentá el quiz en serio; si fallás, el nodo se repara antes de seguir |

El quiz usa exactamente **2 preguntas por bloque**, cada una con 3 opciones (incluyendo "No lo sé"). Los nodos que fallan se reparan antes de construir encima — sin cimientos débiles.

## Salida del Vault

Cuando la sesión termina, todo queda en `LEARNING_LOG.md`:

- Lección completa con diagramas Mermaid
- Resultados del quiz (pregunta + tu respuesta + veredicto ✓/✗)
- Flashcards para repaso espaciado (plugin Spaced Repetition de Obsidian)
- Grafo de dependencias mostrando qué nodos están sólidos y cuántos necesitan refuerzo

Abre la carpeta en Obsidian y el log se renderiza con Mermaid, LaTeX y callouts nativos.

**Generación opcional de vault:** al terminar un tema completo, el agente puede generar un vault de Obsidian con notas de teoría, esquemas de repaso y diagramas organizados por bloque.

## Estructura de la Skill

```
teachme/
├── SKILL.md              ← La skill (este es el único archivo que importa)
├── README.md             ← Este archivo (inglés)
├── README.es.md          ← Este archivo (español)
├── templates/            ← Plantillas de esquema del vault
├── docs/images/          ← Assets visuales del README
└── CHANGELOG.md          ← Historial de versiones
```

Toda la skill vive en `SKILL.md`. Todo lo demás es documentación y plantillas.

## Contribuir

Las contribuciones son bienvenidas. Haz fork del repo, creá una rama de funcionalidad y abrí una pull request.

Al editar la skill, mantené `SKILL.md` conciso (objetivo: 180–450 tokens para las instrucciones principales). Poné el material de apoyo en `templates/` o `references/`, no en el cuerpo principal de la skill.

---

> **Nota de sincronización bilingual:** Mantené ambas versiones en idioma al sincronizar contenido. Ver [README.md](README.md) para la versión en inglés.

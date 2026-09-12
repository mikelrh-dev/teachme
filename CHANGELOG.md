# Changelog — TeachMe

Formato: [Keep a Changelog](https://keepachangelog.com/) · Versionado: [semver](https://semver.org/).

La versión canónica del contenido vive en `SKILL.md` (edición genérica
multi-host). Cada cambio debe: (1) subir la versión aquí y en la cabecera del
`.ts` instalado (`~/.agents/teachme.ts`), (2) regenerar el agente desde la
fuente con `.atl/gen-teachme-ts.py` (verificación de round-trip incluida).

## [1.3.1] — 2026-09-09

### Changed

- **Fuente canónica**: `SKILL.md` queda como única fuente del contenido; el
  `.ts` instalado se genera desde ella (la referencia a `.agents/teachme.md`
  en el preamble era errónea desde `86ae5d2`).
- **Agente desincronizado**: `~/.agents/teachme.ts` seguía en v1.2.1 mientras
  el repo avanzó a la edición genérica. Regenerado (v1.3.1) desde `SKILL.md`
  con verificación de round-trip byte a byte; backup del agente anterior en
  `~/.agents/teachme.ts.bak`.

### Fixed

- **Reinstalador**: nuevo generador one-shot `.atl/gen-teachme-ts.py`
  sustituye al `sync-md-ts.sh` eliminado; escritura vía base64 para evitar
  errores de encoding en consolas Windows `cp1252` y verificación de que el
  contenido de `SKILL.md` es recuperable exacto desde el `.ts`.
- **Referencias rotas**: preamble del CHANGELOG actualizado; badges de
  versión de `README.md` y `README.es.md` pasan a 1.3.1.

### Added

- **Documentación bilingual** — `README.md` (inglés por defecto) y `README.es.md`
  (espejo en español) con estructura de 13 secciones idénticas, badges de
  idioma enlaces bidireccionales, tabla de contenidos con 12 anchors, y notas
  de sincronización bilingual al pie de cada archivo.
- **Assets visuales** — 5 imágenes generadas en `docs/images/` (hero,
  architecture, modes, flow, vault) referenciadas en ambos README.

## [1.3.0] — 2026-09-08

### Changed

- **Skill genérica (host-agnóstica)** — `SKILL.md` reescrita para funcionar en
  cualquier host (Claude Code, OpenCode, Codex, Cursor, etc.). Eliminadas todas
  las referencias a Freebuff; herramientas de host descritas genéricamente
  ("tu herramienta de lectura de archivos", "pregunta al usuario", etc.).
  Reglas pedagógicas y formato de vault preservados íntegramente.

### Removed

- Archivos legacy: `.agents/teachme.md`, `bootstrap.sh`, `install.sh`,
  `sync-md-ts.sh`, `sync_helper.py`, `__pycache__/`, `create-vault.sh`,
  `test.sh`, `test_output.txt`, `MEJORAS_SESION.md` (recuperables por git).

## [1.2.1] — 2026-09-03

### Fixed

- **Instalación portable** — el helper fuerza salida UTF-8 para no fallar en
  consolas Windows `cp1252`, resuelve Python desde `PATH` y genera el agente
  `.ts` desde el `.md` canónico cuando falta la fuente TypeScript local.
  Los checks cubren generación y una instalación limpia aislada.

## [1.2.0] — 2026-08-31

### Added

- **Esquema rápido de repaso** — cuarta opción en el cierre de sesión: un
  single-file schema (~60 líneas) que compila verdad nuclear, piezas, flujo,
  trampas frecuentes y flashcards. Recomendado para temas cortos (1–3 bloques).
  Template en `templates/esquema-schema.md`.

## [1.1.0] — 2026-08-30

### Added

- **`### Nivel del estudiante`** — puntuación 1–5 por tema en `## Estado actual`,
  derivada de evidencia contable (ventana de ~6 veredictos de quiz), con
  tendencia y recalculada tras cada bloque. Calibra el andamiaje de las
  explicaciones al nivel real.
- **Regla de escalada (2 bloques limpios)** — si los 2 últimos bloques cierran
  todo ✓ con nivel 4+, el agente propone con `ask_user` un nodo extra que
  extienda lo aprendido o contenido más denso en el siguiente tema.
- Línea `**Nivel:**` en el `Estado tras el bloque` de cada bloque del log.
- **Versionado del agente** — `version:` en el frontmatter, estampado
  `// @teachme vX.Y.Z` en la cabecera del `.ts` instalado, `--version` en
  `sync_helper.py` y `bootstrap.sh`, checks en `test.sh`.

## [1.0.0] — 2026-08-28

### Added

- Primera versión estable del agente (antes `learn-teacher`): filosofía
  teach (Principios i y ii), proceso probe → plan → teach, quiz de 2 preguntas
  por bloque con opción "No lo sé", modo VAULT y modo REPO, log
  `LEARNING_LOG.md` para Obsidian con mermaid + LaTeX + flashcards, visuals en
  `./visuals/`, cierre de sesión con vault de estudio.

### Fixed (auditoría 2026-08-28 — ver MEJORAS_SESION.md)

- Barajado de posiciones del quiz (la correcta ya no cae siempre primera).
- Opción literal "No lo sé" + graduación del texto libre.
- Secuencia obligatoria del log en vivo (quiz escrito antes de responder).
- Detección de modo (señales de código primero).
- Nombres únicos de visuals por bloque (`-b<n>.mmd`).
- Log append-only vía `str_replace` anclado (sin reescritura completa).

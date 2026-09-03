[![ES](https://img.shields.io/badge/lang-ES-yellow)](README.es.md) [![EN](https://img.shields.io/badge/lang-EN-blue)](README.md)

![TeachMe — Arquitectura del agente de enseñanza socrática](docs/images/hero.png)

![Versión](https://img.shields.io/badge/version-1.2.1-brightgreen) [![Freebuff](https://img.shields.io/badge/powered_by-Freebuff-orange)](https://github.com/nicholasgriffintn/Freebuff) [![Licencia: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

# 🧠 TeachMe — Agente de Enseñanza Socrático `v1.2.1`

> **En una línea:** No hay nada que memorizar — el agente construye un grafo de dependencias en tu cabeza. Verdades incondicionales primero, cada hecho colgando de lo que ya entiendes, y un quiz de 2 preguntas después de cada bloque para confirmar que el nodo está sólido antes de construir encima.

## Tabla de Contenidos

- [Prerrequisitos](#prerrequisitos)
- [Inicio Rápido](#inicio-rápido)
- [Arquitectura](#arquitectura)
- [Dos Modos](#dos-modos)
- [Flujo de Aprendizaje](#flujo-de-aprendizaje)
- [Salida del Vault](#salida-del-vault)
- [Personalización](#personalización)
- [Scripts y Herramientas](#scripts-y-herramientas)
- [Testing](#testing)
- [Versionado](#versionado)
- [Changelog](#changelog)
- [Contribuir](#contribuir)

## Prerrequisitos

- **Node.js** ≥ 18 (Freebuff lo necesita — el script de bootstrap lo instala si falta)
- **Freebuff** instalado ([repo](https://github.com/nicholasgriffintn/Freebuff))
- **Python** 3 (se usa para generar y sincronizar el agente)
- **Obsidian** (opcional): para renderizar Mermaid, LaTeX y callouts en el vault de aprendizaje

## Inicio Rápido

### Opción A — Un comando (recomendado)

```bash
cd teachme
./bootstrap.sh
```

Un solo comando, todo listo: instala Node.js y Freebuff si faltan, copia o genera el agente en `~/.agents/teachme.ts`, verifica la sintaxis y la sincronización `.md ↔ .ts`, y ejecuta los tests de integridad. Es idempotente — ejecútalo las veces que quieras.

Otros comandos:

```bash
./bootstrap.sh --check      # Verificar sin cambios
./bootstrap.sh --uninstall  # Desinstalar el agente
```

### Opción B — Instalación manual

```bash
# Instalar desde la fuente Markdown canónica
./install.sh

# El instalador genera ~/.agents/teachme.ts cuando no existe una fuente .ts local
node --check ~/.agents/teachme.ts
```

### Verificación

1. Abre Freebuff en esta carpeta:
   ```bash
   cd teachme
   freebuff
   ```
2. Escribe:
   ```
   @teachme enseñame qué es un hash
   ```
3. Si responde y arranca el probe → instalado correctamente

### Estructura del Repositorio

```
~/.agents/
└── teachme.ts          ← el agente activo (Freebuff lo carga)

teachme/
├── .agents/
│   └── teachme.md      ← fuente canónica del agente
├── bootstrap.sh              ← instalación con un comando
├── install.sh                ← instalación clásica (solo agente)
├── sync-md-ts.sh             ← sincroniza .md → .ts
├── test.sh                   ← tests de integridad
├── templates/                ← esquema del vault
├── LEARNING_LOG.md           ← tus datos (en .gitignore)
├── visuals/                  ← tus datos (en .gitignore)
├── docs/images/              ← assets visuales del README
└── hash-vault/               ← vault de ejemplo (en .gitignore)
```

> **Nota:** `LEARNING_LOG.md`, `visuals/` y `*-vault/` son **tus datos de aprendizaje** — están en .gitignore y nunca se suben a GitHub. Lo que se publica es el sistema: agente, scripts, templates y docs.

## Arquitectura

![TeachMe arquitectura: Freebuff carga el agente teachme, produce LEARNING_LOG.md](docs/images/architecture.png)

Freebuff es el runtime. TeachMe es el agente que carga. El flujo es:

1. Freebuff inicia una sesión en una carpeta
2. Descubre `~/.agents/teachme.ts` y carga el agente
3. El agente detecta el modo (VAULT o REPO) del directorio actual
4. Evalúa tu nivel, arma un plan, enseña bloque por bloque
5. Todo se escribe en `LEARNING_LOG.md` con diagramas Mermaid en `./visuals/`

## Dos Modos

![El modo VAULT aprende temas; el modo REPO aprende codebases](docs/images/modes.png)

El agente detecta el modo automáticamente según el directorio actual.

| | **VAULT** | **REPO** |
|---|---|---|
| **Propósito** | Aprender un tema general (HTTPS, hashes, redes…) | Absorber el código de un proyecto existente |
| **Cómo invocarlo** | `@teachme enseñame X` | `@teachme quiero absorber este codebase` |
| **Dónde abrir Freebuff** | En esta carpeta (`teachme`) | Dentro del repo que quieres aprender |
| **Qué lee** | Conocimiento del agente + verificación web | Archivos del repo (`read_files`) |
| **Cómo enseña** | Conceptos abstractos + Mermaid | Fragmentos literales (`file:line`) |
| **Dónde queda el log** | `teachme/LEARNING_LOG.md` | En el repo (o vault centralizado) |

> **¿Cómo sabe en qué modo está?**
> **Señales de código primero:** si el directorio actual tiene un `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, o un `.git` con código fuente → **MODO REPO**. Si no es un proyecto de código pero ya existe un `LEARNING_LOG.md` con nuestro frontmatter → **MODO VAULT** (reanudando sesión). Si no hay código ni log → **MODO VAULT** (sesión nueva).

## Flujo de Aprendizaje

![Ciclo de aprendizaje: probe, plan, teach, quiz](docs/images/flow.png)

Cada sesión sigue el mismo ciclo:

| Fase | Qué pasa | Tu acción |
|---|---|---|
| **Probe** | Rondas de 2 preguntas para mapear tu nivel + una pregunta objetiva | Responde con honestidad — "no sé" es información valiosa, no un fracaso |
| **Plan** | Propone currículum + mapa de dependencias (Mermaid) | Revisa y da tu aprobación (o ajusta el alcance) |
| **Teach** | Bloque por bloque: motivar → establecer → conectar → **quiz de 2 preguntas** | Intenta el quiz en serio; si fallas, el nodo se repara antes de seguir |

## Salida del Vault

![Salida del vault: LEARNING_LOG.md con diagramas](docs/images/vault.png)

Cuando la sesión termina, todo queda en `LEARNING_LOG.md`:

- Lección completa con diagramas Mermaid
- Resultados del quiz (pregunta + tu respuesta + veredicto ✓/✗)
- Grafo de dependencias mostrando qué nodos están sólidos y cuántos necesitan refuerzo

Abre la carpeta en Obsidian y el log se renderiza con Mermaid, LaTeX y callouts nativos.

> **Sesión nueva:** Los agentes se cargan al inicio de la sesión. Después de instalar o editar `teachme.ts`, abre una **nueva** sesión de Freebuff para que los cambios tomen efecto.

## Personalización

Edita la fuente canónica, luego sincroniza:

1. Edita `.agents/teachme.md` (la fuente canónica)
2. Ejecuta `./sync-md-ts.sh` (copia los cambios del `.md` al `.ts` global)
3. Abre una **nueva** sesión de Freebuff

> **No edites `~/.agents/teachme.ts` directamente** — se sobreescribe en la próxima sincronización.

## Scripts y Herramientas

| Script | Qué hace |
|--------|----------|
| `./bootstrap.sh` | Instalación con un comando (Node + Freebuff + agente + verificación) |
| `./bootstrap.sh --check` | Verificar instalación sin cambios |
| `./install.sh` | Instalar agente solo (clásico) |
| `./install.sh --check` | Verificar instalación |
| `./sync-md-ts.sh` | Sincronizar `.md` → `.ts` |
| `./sync-md-ts.sh --dry-run` | Mostrar qué se sincronizaría |
| `./test.sh` | Ejecutar tests de integridad |

## Testing

```bash
./test.sh    # Verificar archivos, sintaxis, configuración y scripts
```

Resultado esperado:

```
✓ Passed: 43
✗ Failed: 0
○ Skipped: 0
```

## Versionado

El agente usa versionado semántico. La versión canónica vive en el frontmatter de `.agents/teachme.md` (`version:`) y se estampa en el `.ts` instalado durante la sincronización.

```bash
./bootstrap.sh --version      # Mostrar versiones fuente e instalada
./sync-md-ts.sh               # Sincronizar y estampar la versión
```

Política (detalles en `CHANGELOG.md`):

- **PATCH** — correcciones de redacción sin cambio de comportamiento.
- **MINOR** — nueva regla o funcionalidad.
- **MAJOR** — cambio que rompe compatibilidad (formato del log, proceso).

Al editar el agente: sube `version:` en el frontmatter, agrega una entrada en `CHANGELOG.md`, sincroniza y abre una nueva sesión de Freebuff.

## Changelog

Ver [CHANGELOG.md](CHANGELOG.md) para el historial completo.

## Contribuir

Las contribuciones son bienvenidas. Haz fork del repo, crea una rama de funcionalidad y abre una pull request. Ejecuta `./test.sh` antes de enviar.

---

> **Nota de sincronización bilingual:** Mantén ambas versiones en idioma al sincronizar contenido. Ver [README.md](README.md) para la versión en inglés.

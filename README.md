---
tags:
  - learning
  - manual
---

# 🧠 Mi sistema de aprendizaje

Sistema de enseñanza socrática (adaptado a Freebuff) donde **el que aprende
eres tú** — el agente no aprende: enseña.

> [!tip] La idea en una frase
> Nada de resúmenes para memorizar: el agente construye un **grafo de
> dependencias** en tu cabeza — verdades incondicionales primero, cada hecho
> colgando de lo ya entendido, y un quiz de 2 preguntas tras cada bloque para
> confirmar que el nodo quedó firme antes de construir encima.

## 🎯 Dos modos — el agente detecta cuál automáticamente

| | **VAULT** | **REPO** |
|---|---|---|
| **Para qué** | Aprender un tema general (HTTPS, hashes, redes…) | Asimilar el código de un proyecto existente |
| **Cómo invocar** | `@teachme enséñame X` | `@teachme quiero asimilar este codebase` |
| **Dónde abres Freebuff** | En esta carpeta (`teachme`) | Dentro del repo que quieres aprender |
| **Qué lee** | Conocimiento del agente + verificación web | Archivos del repo (`read_files`) |
| **Cómo enseña** | Conceptos abstractos + mermaid | Snippets literales (`archivo:línea`) |
| **Dónde cae el log** | `teachme/LEARNING_LOG.md` | En el repo (o vault centralizado) |

> [!note] ¿Cómo sabe en qué modo está?
> **Señales de código primero:** si el directorio actual tiene un
> `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, o un `.git` con
> código fuente → **MODO REPO**. Si no es un proyecto de código pero ya existe
> un `LEARNING_LOG.md` con nuestro frontmatter → **MODO VAULT** (retoma sesión).
> Si no hay ni código ni log → **MODO VAULT** (nueva sesión).

## 🚀 Instalación

### Prerrequisitos

- **Node.js** ≥ 18 (Freebuff lo necesita — el bootstrap lo instala si falta)
- **Obsidian** (opcional): para renderizar mermaid, LaTeX y callouts

### Opción A — Un solo comando (recomendado)

```bash
cd teachme
./bootstrap.sh
```

Un comando, todo listo: instala Node.js y Freebuff si faltan, copia el agente
a `~/.agents/teachme.ts`, verifica la sintaxis y la sincronización
`.md ↔ .ts`, y corre los tests de integridad. Es idempotente — puedes
ejecutarlo las veces que quieras.

Otros comandos:
```bash
./bootstrap.sh --check      # Solo verificar (no cambia nada)
./bootstrap.sh --uninstall  # Eliminar el agente
```

### Opción B — Script clásico

```bash
# 1. Crear carpeta global si no existe
mkdir -p ~/.agents

# 2. Copiar el agente
cp .agents/teachme.ts ~/.agents/

# 3. Verificar sintaxis
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
   @teachme enséñame qué es un hash
   ```
3. Si responde y empieza el probe → ✅ instalado correctamente

### Estructura del repo

```
~/.agents/
└── teachme.ts          ← el agente activo (Freebuff lo carga)

teachme/
├── .agents/
│   └── teachme.md      ← fuente canónica del contenido
├── bootstrap.sh              ← instalación de un comando
├── install.sh                ← instalación clásica (agente solo)
├── sync-md-ts.sh             ← sincroniza .md → .ts
├── test.sh                   ← tests de integridad
├── templates/                ← schema del vault de estudio
├── LEARNING_LOG.md           ← tus datos (git-ignorado)
├── visuals/                  ← tus datos (git-ignorado)
└── hash-vault/               ← vault de ejemplo (git-ignorado)
```

> [!info] Datos personales vs. código
> `LEARNING_LOG.md`, `visuals/` y los `*-vault/` son **tus datos de
> aprendizaje** — están git-ignorados y no se suben a GitHub. Lo que se
> publica es el sistema: agente, scripts, templates y docs.

## ⚙️ Requisitos

- **Freebuff** instalado.
- **Obsidian** (opcional pero recomendado): abre esta carpeta como *vault* y el
  log se renderiza con mermaid, LaTeX y callouts nativos.

## 🚀 Modo vault — aprender un tema

1. Abre **esta carpeta** (`teachme`) en Freebuff, para que el log caiga
   en este vault. (El agente existe en cualquier sesión gracias a la
   instalación global, pero si abres Freebuff en otro sitio, el log se creará
   allí.)
2. Invoca al agente y pide tu tema:

   ```
   @teachme quiero entender cómo funciona HTTPS
   ```

   > [!tip] Nombre de la mención
   > Si el autocompletado no sugiere `@teachme`, prueba `@TeachMe`
   > (el nombre visible del agente es su `displayName`).

3. Sigue el flujo — el agente te va guiando:

   | Fase | Qué pasa | Qué haces tú |
   |---|---|---|
   | **Probe** | Rondas de 2 preguntas para mapear tu nivel + pregunta de objetivo | Responde con honestidad; "no lo sé" es info valiosa, no un fallo |
   | **Plan** | Te propone curriculum + mapa de dependencias (mermaid) | Revisa y da el OK (o cambia el alcance) |
   | **Teach** | Bloque a bloque: motivar → establecer → conectar → **quiz de 2 preguntas** | Intenta el quiz en serio; si fallas, se repara el nodo antes de avanzar |

4. Al terminar, cierra Obsidian y lee `LEARNING_LOG.md` renderizado: la lección
   entera quedó ahí con sus diagramas.

> [!warning] Sesión nueva
> Los agentes se cargan al arrancar la sesión. Tras instalar o editar
> `teachme.ts`, abre una sesión **nueva** de Freebuff para que surta
> efecto.

## 📦 Modo repo — asimilar el código de un proyecto

**Opción A (recomendada):** abre Freebuff **dentro del repo** y di:

```
@teachme quiero asimilar este codebase
```

El agente detecta el modo repo: cartografía primero (estructura, entry points,
módulos), luego sondea tu nivel en las tecnologías *de ese repo*, te propone un
curriculum ordenado por dependencia real del código, y enseña bloque a bloque
con snippets literales (`archivo:línea`). El log se crea en el propio repo — si
es git, te preguntará antes si añadir `LEARNING_LOG.md` y `visuals/` al
`.gitignore`. No hace falta nada especial en el repo: el agente ya está
disponible por la instalación global.

**Opción B (log centralizado):** si quieres que todo caiga en el log de este
vault, abre Freebuff en una **carpeta padre que contenga el repo y este vault**
(p. ej. tu home) y pídeselo así: *"@teachme enseña el código de
`mi-proyecto/` y guarda el log en `teachme/`"*.

## 💡 Consejos para que funcione mejor

- **No adivines en los quizzes.** Si no lo sabes, elige la opción "No lo sé"
  — el borde de tu conocimiento es exactamente lo que el agente busca para
  enseñar en tu zona correcta. (Escribir tu intento real en "Other" también
  vale: se gradúa como respuesta.)
- **Dile si va rápido o lento.** Si todo te sale, subirá la dificultad en seco;
  si te atascas, baja y repara.
- **Las sesiones se retoman solas:** el agente lee `LEARNING_LOG.md` al iniciar
  y sabe qué nodos quedaron firmes y cuáles piden refuerzo.
- **Verificación incluida:** si duda de un hecho, lo comprueba en la web antes
  de decírtelo. Si te corrige algo que te dijo antes, es que la verificación lo
  destapó — buena señal.
- **El log se lee en vivo:** los quizzes aparecen en `LEARNING_LOG.md` sin la
  respuesta correcta; el veredicto (✓/✗ + explicación) llega después en un
  callout.

## 🔧 Personalización y mantenimiento

### Editar el agente

Edita **`teachme/.agents/teachme.md`** (la fuente canónica) y
luego sincroniza:

```bash
./sync-md-ts.sh    # Copia los cambios del .md al .ts global
```

> [!warning] Flujo correcto
> 1. Edita `.agents/teachme.md`
> 2. Ejecuta `./sync-md-ts.sh`
> 3. Abre una sesión **nueva** de Freebuff
>
> **No edites directamente `~/.agents/teachme.ts`** — se sobrescribiría
> en la próxima sincronización.

### Herramientas

| Script | Qué hace |
|--------|----------|
| `./bootstrap.sh` | Instalación de un comando (Node + Freebuff + agente + verificación) |
| `./bootstrap.sh --check` | Verifica la instalación sin cambiar nada |
| `./install.sh` | Instala solo el agente (clásico) |
| `./install.sh --check` | Verifica la instalación |
| `./sync-md-ts.sh` | Sincroniza .md → .ts |
| `./sync-md-ts.sh --dry-run` | Muestra qué se sincronizaría |
| `./test.sh` | Ejecuta tests de integridad |

### Tests

```bash
./test.sh    # Verifica archivos, sintaxis, configuración y scripts
```

Resultado esperado:
```
✓ Pasaron: 38
✗ Fallaron: 0
○ Saltados: 0
```

### Modelo

El modelo es `z-ai/glm-5.3-flash` (free unlimited). Cámbialo en el `.ts`
solo por otro modelo de la familia FREE.

### Versiones del agente

El agente está versionado (semver). La versión canónica vive en el frontmatter
de `.agents/teachme.md` (`version:`) y se estampa en la cabecera del `.ts`
instalado al sincronizar.

```bash
./bootstrap.sh --version      # versión de la fuente y de la instalada
./sync-md-ts.sh               # sincroniza y estampa la versión
```

Política (detalle en `CHANGELOG.md`):

- **PATCH** — correcciones de redacción sin cambio de comportamiento.
- **MINOR** — regla o funcionalidad nueva.
- **MAJOR** — cambio que rompe compatibilidad (formato de log, proceso).

Al editar el agente: sube `version:` en el frontmatter, añade entrada en
`CHANGELOG.md`, sincroniza, y abre sesión nueva de Freebuff.

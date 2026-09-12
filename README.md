[![EN](https://img.shields.io/badge/lang-EN-blue)](README.md) [![ES](https://img.shields.io/badge/lang-ES-yellow)](README.es.md)

![TeachMe — Socratic teaching agent architecture](docs/images/hero.png)

![Version](https://img.shields.io/badge/version-1.3.1-brightgreen) [![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

# 🧠 TeachMe — Socratic Teaching Agent

> **The one-liner:** Nothing to memorize — the agent builds a dependency graph in your head. Unconditional truths first, each fact hanging from what you already understand, and a 2-question quiz after every block to confirm the node is solid before building on top.

## Table of Contents

- [Installation](#installation)
- [Compatibility](#compatibility)
- [How It Works](#how-it-works)
- [Learning Flow](#learning-flow)
- [Vault Output](#vault-output)
- [Skill Structure](#skill-structure)
- [Uninstallation](#uninstallation)
- [Contributing](#contributing)
- [License](#license)

## Installation

TeachMe is a **skill** — a single `SKILL.md` file that any compatible AI coding agent can load.

### 1. Clone the repo

```bash
git clone https://github.com/mikelrh-dev/teachme.git
```

### 2. Copy the skill to your agent's skills directory

| Agent | Destination |
|-------|-------------|
| **Claude Code** | `~/.agents/skills/teachme/SKILL.md` |
| **OpenCode** | `~/.config/opencode/skills/teachme/SKILL.md` |
| **Codex / Cursor / other** | See your agent's docs for the skills folder path |

Example for Claude Code:

```bash
mkdir -p ~/.agents/skills/teachme
cp teachme/SKILL.md ~/.agents/skills/teachme/SKILL.md
```

### 3. Restart your agent session

Skills load once at startup — there is no hot-reload. You MUST restart your agent session for the skill to be picked up.

### 4. Verify

Then type:

```
@teachme teach me what a hash is
```

If it responds and starts the probe → installed correctly.

## Compatibility

TeachMe works with any agent that supports loading skills from a `SKILL.md` file:

| Agent | Status |
|-------|--------|
| Claude Code | ✅ Native (`~/.agents/skills/`) |
| OpenCode | ✅ Native (`~/.config/opencode/skills/`) |
| Codex | ✅ Via skills directory |
| Cursor | ✅ Via rules / skills |
| Other LLM agents | ✅ If they load `.md` instruction files |

**Requirements:** An LLM agent with tool access (web search, file read/write). No Node.js, Python, or other runtimes needed — the skill is pure Markdown instructions.

## How It Works

The agent detects which mode to use automatically based on the current directory:

| | **VAULT** | **REPO** |
|---|---|---|
| **Purpose** | Learn a general topic (HTTPS, hashes, networking…) | Absorb the code of an existing project |
| **How to invoke** | `@teachme teach me X` | `@teachme teach me this repo` / `explain this codebase` / `I want to understand what happens in this folder` |
| **Where to open the agent** | Any folder | Inside the repo you want to learn |
| **What it reads** | Agent knowledge + web verification | Repo files (`read_files`) |
| **How it teaches** | Abstract concepts + Mermaid diagrams | Literal snippets (`file:line`) |
| **Where the log lands** | `LEARNING_LOG.md` in cwd | In the repo (or a centralized vault) |

> **How does it know which mode?**
> **Code-first signals:** if the current directory has a `package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`, or a `.git` with source code → **REPO MODE**. If it is not a code project but a `LEARNING_LOG.md` with the skill's frontmatter already exists → **VAULT MODE** (resuming a session). If neither code nor log exists → **VAULT MODE** (new session).

## Learning Flow

Every session follows the same cycle:

| Phase | What happens | What you do |
|---|---|---|
| **Probe** | 2-question rounds to map your level + an objective question | Answer honestly — "I don't know" is valuable info, not a failure |
| **Plan** | Proposes curriculum + dependency map (Mermaid) | Review and give the OK (or adjust scope) |
| **Teach** | Block by block: motivate → establish → connect → **2-question quiz** | Attempt the quiz seriously; if you fail, the node is repaired before moving on |

The quiz uses exactly **2 questions per block**, each with 3 options (including "I don't know"). Failed nodes are repaired before building on top — no weak foundations.

## Vault Output

When the session ends, everything is in `LEARNING_LOG.md`:

- Full lesson with Mermaid diagrams
- Quiz results (question + your answer + verdict ✓/✗)
- Flashcards for spaced repetition (Obsidian Spaced Repetition plugin)
- Dependency graph showing which nodes are solid and which need reinforcement

Open the folder in Obsidian and the log renders with native Mermaid, LaTeX, and callouts.

**Optional vault generation:** at the end of a complete topic, the agent can generate an Obsidian vault with theory notes, review schemas, and diagrams organized by block.

## Skill Structure

```
teachme/
├── SKILL.md              ← The skill (this is the only file that matters)
├── templates/            ← Schema extracts referenced by the skill
│   ├── vault-schema.md   ← Vault structure, page types, frontmatters, templates
│   └── esquema-schema.md ← Compact single-file review schema
├── README.md             ← This file (English)
├── README.es.md          ← This file (Spanish)
├── docs/images/          ← README visual assets
└── CHANGELOG.md          ← Version history
```

The entire skill lives in `SKILL.md`. The `templates/` directory contains schema extracts that the skill references. Other files in this repo (`hash-vault/`, `visuals/`, `LEARNING_LOG.md`, `.atl/`) are examples and tooling — not part of the installed skill.

## Uninstallation

Delete the skill folder from your agent's skills directory and restart the session:

```bash
rm -rf ~/.agents/skills/teachme   # Claude Code (adjust the path for your agent)
```

Your learning data (`LEARNING_LOG.md`, `visuals/`) is yours and stays untouched — only the skill is removed.

## Contributing

Contributions are welcome. Fork the repo, create a feature branch, and open a pull request.

When editing the skill, keep `SKILL.md` focused and actionable. Note: TeachMe's SKILL.md is ~652 lines (~3000 tokens) — it intentionally exceeds generic style-guide budgets because the pedagogical workflow, decision gates, and quality checklist require comprehensive in-context instructions. Put supporting material in `references/` when possible, but do not sacrifice completeness for brevity.

---

> **Bilingual sync note:** Keep both language versions in sync when editing content. See [README.es.md](README.es.md) for the Spanish version.

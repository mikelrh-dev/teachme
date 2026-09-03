#!/usr/bin/env python3
"""
sync_helper.py - Syncs teachme.md into the installed teachme.ts agent.

The Markdown file is canonical. The helper can update an existing agent or
build one from the Markdown frontmatter when no checked-in TypeScript source is
available.
"""

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path


# Windows commonly starts Python with the cp1252 console encoding. The source
# and generated agent are UTF-8, so command output must not depend on the shell.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


def extract_frontmatter(md_path: str) -> str:
    """Return the YAML frontmatter block from the canonical Markdown file."""
    with open(md_path, "r", encoding="utf-8") as file:
        content = file.read()
    match = re.match(r"\A---\s*\n(.*?)\n---\s*(?:\n|\Z)", content, re.DOTALL)
    return match.group(1) if match else ""


def extract_frontmatter_value(frontmatter: str, key: str) -> str:
    """Read a simple scalar frontmatter value."""
    match = re.search(rf"^{re.escape(key)}:\s*(.*?)\s*$", frontmatter, re.MULTILINE)
    return match.group(1).strip() if match else ""


def extract_md_description(md_path: str) -> str:
    """Read a folded or scalar description for the agent spawner prompt."""
    frontmatter = extract_frontmatter(md_path)
    lines = frontmatter.splitlines()
    description_lines = []
    reading_description = False

    for line in lines:
        if re.match(r"^description:\s*>-?\s*$", line):
            reading_description = True
            continue
        if reading_description:
            if line.startswith((" ", "\t")):
                description_lines.append(line.strip())
                continue
            break

    if description_lines:
        return " ".join(line for line in description_lines if line)
    return extract_frontmatter_value(frontmatter, "description")


def extract_md_tools(md_path: str) -> list[str]:
    """Read tool names from the frontmatter tools list."""
    frontmatter = extract_frontmatter(md_path)
    lines = frontmatter.splitlines()
    tools = []
    reading_tools = False

    for line in lines:
        if re.match(r"^tools:\s*$", line):
            reading_tools = True
            continue
        if reading_tools:
            match = re.match(r"^\s+-\s+([A-Za-z0-9_]+)\s*$", line)
            if match:
                tools.append(match.group(1))
                continue
            if line.strip():
                break

    return tools


def escape_ts_single_quote(value: str) -> str:
    """Escape a value for a single-quoted TypeScript string literal."""
    return value.replace("\\", "\\\\").replace("'", "\\'").replace("\n", "\\n")


def escape_ts_template(value: str) -> str:
    """Escape Markdown for a TypeScript template literal."""
    return value.replace("\\", "\\\\").replace("`", "\\`").replace("${", "\\${")


def generate_ts(md_path: str, ts_path: str) -> None:
    """Generate a Freebuff AgentDefinition from the canonical Markdown source."""
    frontmatter = extract_frontmatter(md_path)
    name = extract_frontmatter_value(frontmatter, "name")
    model = extract_frontmatter_value(frontmatter, "model")
    version = extract_frontmatter_value(frontmatter, "version")
    include_history_value = extract_frontmatter_value(frontmatter, "includeMessageHistory").lower()
    include_history = "true" if include_history_value == "true" else "false"
    description = extract_md_description(md_path)
    tools = extract_md_tools(md_path)
    body = extract_md_content(md_path)

    if not name or not model or not version or not description or not tools or not body:
        raise ValueError("El frontmatter o el contenido del .md están incompletos")

    tool_lines = ",\n".join(
        f"    '{escape_ts_single_quote(tool)}'" for tool in tools
    )
    generated = f"""// TeachMe - generated from .agents/teachme.md
// @teachme v{version}
//
// This file is generated. Edit .agents/teachme.md and run the installer or sync helper.

const definition = {{
  id: '{escape_ts_single_quote(name)}',
  displayName: 'TeachMe',
  model: '{escape_ts_single_quote(model)}',
  includeMessageHistory: {include_history},
  toolNames: [
{tool_lines},
  ],
  spawnerPrompt: '{escape_ts_single_quote(description)}',
  systemPrompt: 'Eres TeachMe, un profesor socrático personal. El que aprende es el USUARIO: tú enseñas; tú no aprendes. Tu único trabajo es construir un grafo de dependencias mental en su cabeza. No implementes código salvo los artefactos pedagógicos: LEARNING_LOG.md y ./visuals/*.mmd.',
  instructionsPrompt: `{escape_ts_template(body)}`,
}}

export default definition
"""

    target = Path(ts_path)
    target.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=target.parent, delete=False
    ) as temp:
        temp.write(generated)
        temp_path = Path(temp.name)
    os.replace(temp_path, target)


def extract_md_version(md_path: str) -> str:
    """Read version: from the Markdown frontmatter."""
    frontmatter = extract_frontmatter(md_path)
    return extract_frontmatter_value(frontmatter, "version")


def stamp_ts_version(ts_path: str, version: str) -> None:
    """Write or update the // @teachme vX.Y.Z header in an existing agent."""
    with open(ts_path, "r", encoding="utf-8") as file:
        ts_content = file.read()
    marker = f"// @teachme v{version}"
    stamped = re.sub(
        r"^// @teachme v[0-9]+\.[0-9]+\.[0-9]+$",
        marker,
        ts_content,
        count=1,
        flags=re.MULTILINE,
    )
    if stamped == ts_content and not re.search(
        r"^// @teachme v[0-9]+\.[0-9]+\.[0-9]+$", ts_content, re.MULTILINE
    ):
        lines = ts_content.split("\n")
        lines.insert(1, marker)
        stamped = "\n".join(lines)
    with open(ts_path, "w", encoding="utf-8") as file:
        file.write(stamped)


def extract_ts_version(ts_path: str) -> str:
    """Read the stamped version from an agent header."""
    with open(ts_path, "r", encoding="utf-8") as file:
        ts_content = file.read()
    match = re.search(
        r"^// @teachme v([0-9]+\.[0-9]+\.[0-9]+)$", ts_content, re.MULTILINE
    )
    return match.group(1) if match else ""


def extract_md_content(md_path: str) -> str:
    """Extract Markdown content after the YAML frontmatter."""
    with open(md_path, "r", encoding="utf-8") as file:
        content = file.read()

    lines = content.split("\n")
    frontmatter_end = None
    if lines and lines[0].strip() == "---":
        for index in range(1, len(lines)):
            if lines[index].strip() == "---":
                frontmatter_end = index
                break

    if frontmatter_end is None:
        return content.strip()
    return "\n".join(lines[frontmatter_end + 1 :]).strip()


def sync_ts(ts_path: str, md_content: str) -> bool:
    """Replace instructionsPrompt in an existing TypeScript agent."""
    with open(ts_path, "r", encoding="utf-8") as file:
        ts_content = file.read()

    md_escaped = escape_ts_template(md_content)
    start_match = re.search(r"instructionsPrompt:\s*`", ts_content)
    if not start_match:
        print("ERROR: No se encontró instructionsPrompt en el .ts")
        return False

    start_pos = start_match.end()
    end_matches = list(re.finditer(r"`,\s*$", ts_content[start_pos:], re.MULTILINE))
    if not end_matches:
        print("ERROR: No se encontró el cierre de instructionsPrompt")
        return False

    end_pos = start_pos + end_matches[-1].start()
    new_ts = ts_content[:start_pos] + md_escaped + ts_content[end_pos:]
    with open(ts_path, "w", encoding="utf-8") as file:
        file.write(new_ts)
    return True


def verify_ts_syntax(ts_path: str) -> bool:
    """Verify TypeScript/JavaScript syntax with Node."""
    result = subprocess.run(
        ["node", "--check", ts_path],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def extract_ts_content(ts_path: str) -> str:
    """Extract instructionsPrompt from an existing TypeScript agent."""
    with open(ts_path, "r", encoding="utf-8") as file:
        ts_content = file.read()
    start_match = re.search(r"instructionsPrompt:\s*`", ts_content)
    if not start_match:
        return ""

    start_pos = start_match.end()
    end_matches = list(re.finditer(r"`,\s*$", ts_content[start_pos:], re.MULTILINE))
    if not end_matches:
        return ""

    end_pos = start_pos + end_matches[-1].start()
    raw = ts_content[start_pos:end_pos]
    raw = raw.replace("\\${", "${")
    raw = raw.replace("\\`", "`")
    raw = raw.replace("\\\\", "\\")
    return raw.strip()


def check_sync(md_path: str, ts_path: str) -> bool:
    """Return whether the Markdown and TypeScript prompts are synchronized."""
    md_content = extract_md_content(md_path).strip()
    ts_content = extract_ts_content(ts_path).strip()
    md_norm = "\n".join(line.rstrip() for line in md_content.splitlines()).strip()
    ts_norm = "\n".join(line.rstrip() for line in ts_content.splitlines()).strip()
    return md_norm == ts_norm


def main() -> None:
    script_dir = Path(__file__).parent
    md_file = script_dir / ".agents" / "teachme.md"
    ts_file = Path.home() / ".agents" / "teachme.ts"

    if "--output" in sys.argv:
        output_index = sys.argv.index("--output") + 1
        if output_index >= len(sys.argv):
            print("ERROR: --output requiere una ruta")
            sys.exit(1)
        ts_file = Path(sys.argv[output_index]).expanduser()

    if "--help" in sys.argv or "-h" in sys.argv:
        print("Uso: sync_helper.py [opción]")
        print("")
        print("Opciones:")
        print("  (sin args)    Sincronizar .md → .ts")
        print("  --check       Verificar si .md y .ts están sincronizados (exit 0=ok, 1=desincronizado)")
        print("  --generate    Generar el .ts instalado desde el .md")
        print("  --output PATH Escribir el .ts generado en PATH (opcional)")
        print("  --version     Mostrar la versión de la fuente y la instalada")
        print("  --dry-run     Mostrar qué se sincronizaría sin cambiar nada")
        print("  --help, -h    Muestra esta ayuda")
        return

    if not md_file.exists():
        print(f"ERROR: No se encontró: {md_file}")
        sys.exit(1)

    if "--version" in sys.argv or "-v" in sys.argv:
        md_ver = extract_md_version(str(md_file))
        ts_ver = extract_ts_version(str(ts_file)) if ts_file.exists() else ""
        print(f"Fuente (.md):   v{md_ver or 'sin version'}")
        print(f"Instalado (.ts): v{ts_ver or 'sin version'}")
        if md_ver and ts_ver and md_ver != ts_ver:
            print("[FAIL] Versiones distintas — ejecuta ./sync-md-ts.sh")
            sys.exit(1)
        if not md_ver:
            print("[WARN] El .md no declara version: en el frontmatter")
            sys.exit(1)
        print("[OK] Versiones coinciden" if md_ver == ts_ver else "[OK] Version de fuente declarada")
        return

    if "--generate" in sys.argv:
        try:
            generate_ts(str(md_file), str(ts_file))
        except (OSError, ValueError) as error:
            print(f"ERROR: No se pudo generar el .ts: {error}")
            sys.exit(1)
        if not verify_ts_syntax(str(ts_file)):
            print("ERROR: El .ts generado tiene errores de sintaxis")
            sys.exit(1)
        print(f"Agente generado: {ts_file}")
        print("Sintaxis del .ts correcta")
        return

    if not ts_file.exists():
        print(f"ERROR: No se encontró: {ts_file}")
        print("Ejecuta ./install.sh para generar e instalar el agente")
        sys.exit(1)

    if "--check" in sys.argv:
        if check_sync(str(md_file), str(ts_file)):
            print("[OK] Sincronizado: .md y .ts coinciden")
            sys.exit(0)
        print("[FAIL] Desincronizado: .md y .ts NO coinciden")
        print("  Ejecuta: ./sync-md-ts.sh  para sincronizar")
        md_lines = extract_md_content(str(md_file)).splitlines()
        ts_lines = extract_ts_content(str(ts_file)).splitlines()
        print(f"  .md: {len(md_lines)} lineas | .ts instructionsPrompt: {len(ts_lines)} lineas")
        sys.exit(1)

    if "--dry-run" in sys.argv:
        print("Dry run - sin cambios\n")
        md_lines = extract_md_content(str(md_file)).split("\n")
        for line in md_lines[:30]:
            print(line)
        if len(md_lines) > 30:
            print("...")
        print(f"\nTotal: {len(md_lines)} líneas")
        return

    backup_file = ts_file.with_suffix(".ts.bak")
    import shutil

    shutil.copy2(ts_file, backup_file)
    print(f"Backup creado: {backup_file}")
    md_content = extract_md_content(str(md_file))
    if not md_content:
        print("ERROR: El contenido del .md está vacío")
        sys.exit(1)

    if not sync_ts(str(ts_file), md_content):
        print("Error durante la sincronizacion")
        shutil.copy2(backup_file, ts_file)
        sys.exit(1)

    print("instructionsPrompt actualizado")
    version = extract_md_version(str(md_file))
    if version:
        stamp_ts_version(str(ts_file), version)
        print(f"Version estampada: @teachme v{version}")

    if verify_ts_syntax(str(ts_file)):
        print("Sintaxis del .ts correcta")
    else:
        print("Error de sintaxis en el .ts")
        print("Restaurando backup...")
        shutil.copy2(backup_file, ts_file)
        sys.exit(1)

    print("\nSincronizacion completada")


if __name__ == "__main__":
    main()

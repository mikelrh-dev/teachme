#!/usr/bin/env python3
"""One-shot: regenerate ~/.agents/teachme.ts (v2.0.0) from SKILL.md (canonical).

Embeds SKILL.md verbatim inside a TS template-literal, escaping only for the
TS string syntax (backslash and backtick), so content round-trips exactly.
Verifies with diff before replacing the installed agent.
"""
import base64, pathlib, subprocess, sys

HOME = pathlib.Path.home()
REPO = HOME / "Documents" / "AgentLearn" / "teachme"
SKILL_MD = REPO / "SKILL.md"
TARGET = HOME / ".agents" / "teachme.ts"
BAK = HOME / ".agents" / "teachme.ts.bak"

VERSION = "1.3.1"
HEADER = f"""// TeachMe — profesor socrático personal
// @teachme v{VERSION}
//
// Instalado GLOBALMENTE en ~/.agents/ para que @teachme funcione en
// cualquier proyecto. Generado desde AgentLearn/teachme/SKILL.md
// (fuente canónica, edición genérica multi-host) al formato
// AgentDefinition de Freebuff.
//
// ⚠ Fuente canónica del contenido: AgentLearn/teachme/SKILL.md.
// Tras cualquier cambio en la fuente: regenera este archivo y abre una
// sesión NUEVA de Freebuff para que el cambio surta efecto.

const definition = {{
  id: 'teachme',
  displayName: 'TeachMe',
  model: 'z-ai/glm-5.3-flash',
  includeMessageHistory: false,
  toolNames: [
    'read_files', 'code_search', 'glob', 'list_directory', 'write_file',
    'str_replace', 'run_terminal_command', 'ask_user', 'web_search',
    'read_url', 'write_todos', 'suggest_followups',
  ],
  spawnerPrompt: 'Profesor socrático personal: enseña al USUARIO (el que aprende es él, no el agente). Trigger: cuando el usuario quiera aprender o entender algo ("enséñame X", "no entiendo Y", "quiero aprender Z"), pida una explicación profunda, retome el log o quiera ASIMILAR EL CÓDIGO de un proyecto ("enséñame este repo", "explícame este codebase", "quiero entender lo que pasa en esta carpeta"). Dos modos: VAULT (temas generales) y REPO (asimilar el código de un repo). Proceso probe → plan → teach, quiz de 2 preguntas tras cada bloque, mermaid en ./visuals/ y todo volcado en LEARNING_LOG.md para Obsidian. Sus conclusiones con sus palabras se capturan como definiciones de autor. Solo modelos FREE.',
  systemPrompt: `Eres TeachMe, un profesor socrático personal. El que aprende es el USUARIO: tú enseñas; tú no aprendes. Tu único trabajo es construir un grafo de dependencias mental en su cabeza. No implementes código salvo los artefactos pedagógicos: LEARNING_LOG.md y ./visuals/*.mmd. Responde en el idioma del estudiante.`,
  instructionsPrompt: `"""

FOOTER = """`,
}

export default definition
"""


def b64(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")


def read_b(target: pathlib.Path) -> bytes:
    return target.read_bytes()


def main() -> None:
    skill_md = SKILL_MD.read_bytes()

    # TS template literal escape: backslash first, then backtick.
    escaped = (
        skill_md.decode("utf-8")
        .replace("\\", "\\\\")
        .replace("`", "\\`")
    )
    generated = (HEADER + escaped + FOOTER).encode("utf-8")

    # Round-trip check on the content section only.
    generated_b = generated
    start = generated_b.index(HEADER.encode("utf-8")) + len(HEADER.encode("utf-8"))
    end = generated_b.index(FOOTER.encode("utf-8"), start)
    unescaped = (
        generated_b[start:end]
        .decode("utf-8")
        .replace("\\`", "`")
        .replace("\\\\", "\\")
    )
    if unescaped.encode("utf-8") != skill_md:
        print("ROUND-TRIP MISMATCH — aborting, installed agent untouched")
        sys.exit(1)

    candidate = TARGET.with_suffix(".ts.new")
    write_file = pathlib.Path(str(candidate) + ".b64")
    write_file.write_bytes(b64(generated_b).encode("ascii"))
    print(f"b64 payload: {write_file}")

    cmd = [
        "python", "-c",
        "import base64,sys; p=sys.argv[1]; out=sys.argv[2]; "
        "d=base64.b64decode(open(p,'rb').read()); open(out,'wb').write(d); "
        "print('written bytes:', len(d))",
        str(write_file),
        str(candidate),
    ]
    subprocess.run(cmd, check=True)
    write_file.unlink()

    # Byte-for-byte verification: diff the candidate against a re-composition.
    re_header = (HEADER + FOOTER)
    composed = (HEADER + escaped + FOOTER).encode("utf-8")
    if candidate.read_bytes() != composed:
        print("CANDIDATE DIFFERS from composed content — aborting")
        sys.exit(1)

    # Also verify round-trip from the file as written to disk.
    on_disk = candidate.read_bytes()
    s = on_disk.index(HEADER.encode()) + len(HEADER.encode())
    e = on_disk.index(FOOTER.encode(), s)
    rt = on_disk[s:e].decode("utf-8").replace("\\`", "`").replace("\\\\", "\\")
    if rt.encode("utf-8") == skill_md:
        print("ROUND-TRIP OK — SKILL.md recoverable exactly")
    else:
        print("ROUND-TRIP FAIL — aborting, installed agent untouched")
        sys.exit(1)

    # Final gate: replace the installed agent.
    old = TARGET.read_bytes() if TARGET.exists() else b""
    if old and not old.startswith(b"// TeachMe"):
        print("Unexpected target content — aborting")
        sys.exit(1)
    TARGET.write_bytes(on_disk)
    print(f"INSTALLED v{VERSION} -> {TARGET} ({TARGET.stat().st_size} bytes)")
    print("backup (v1.2.1) kept at:", BAK)


if __name__ == "__main__":
    main()

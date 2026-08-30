#!/usr/bin/env python3
"""
sync_helper.py — Sincroniza teachme.md → teachme.ts

Extrae el contenido del .md (sin frontmatter) y lo inserta
en el instructionsPrompt del .ts.
"""

import re
import sys
import os
from pathlib import Path

def extract_md_version(md_path: str) -> str:
    """Lee version: del frontmatter del .md. Devuelve '' si no existe."""
    with open(md_path, "r", encoding="utf-8") as f:
        content = f.read()
    m = re.search(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\s*$', content, re.MULTILINE)
    return m.group(1) if m else ""


def stamp_ts_version(ts_path: str, version: str) -> None:
    """Escribe/actualiza la línea '// @teachme vX.Y.Z' en la cabecera del .ts."""
    with open(ts_path, "r", encoding="utf-8") as f:
        ts_content = f.read()
    marker = f"// @teachme v{version}"
    stamped = re.sub(r'^// @teachme v[0-9]+\.[0-9]+\.[0-9]+$', marker, ts_content,
                     count=1, flags=re.MULTILINE)
    if stamped == ts_content and not re.search(r'^// @teachme v[0-9]+\.[0-9]+\.[0-9]+$', ts_content, re.MULTILINE):
        # No existía: insertar tras la primera línea (cabecera de comentario)
        lines = ts_content.split("\n")
        lines.insert(1, marker)
        stamped = "\n".join(lines)
    with open(ts_path, "w", encoding="utf-8") as f:
        f.write(stamped)


def extract_ts_version(ts_path: str) -> str:
    """Lee la versión estampada en la cabecera del .ts ('' si no hay)."""
    with open(ts_path, "r", encoding="utf-8") as f:
        ts_content = f.read()
    m = re.search(r'^// @teachme v([0-9]+\.[0-9]+\.[0-9]+)$', ts_content, re.MULTILINE)
    return m.group(1) if m else ""


def extract_md_content(md_path: str) -> str:
    """Extrae el contenido del .md quitando el frontmatter YAML."""
    with open(md_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    lines = content.split("\n")
    in_frontmatter = False
    fm_count = 0
    result_lines = []
    
    for line in lines:
        if line.strip() == "---":
            fm_count += 1
            if fm_count == 1:
                in_frontmatter = True
                continue
            if fm_count == 2:
                in_frontmatter = False
                continue
        if not in_frontmatter:
            result_lines.append(line)
    
    return "\n".join(result_lines).strip()

def sync_ts(ts_path: str, md_content: str) -> bool:
    """Reemplaza el instructionsPrompt en el .ts con el contenido del .md."""
    with open(ts_path, "r", encoding="utf-8") as f:
        ts_content = f.read()
    
    # Escapar para template literal de TS
    # Orden importante: backslashes primero, luego backticks, luego ${}
    md_escaped = md_content
    md_escaped = md_escaped.replace('\\', '\\\\')  # \ -> \\
    md_escaped = md_escaped.replace('`', '\\`')      # ` -> \`
    md_escaped = md_escaped.replace('${', '\\${')     # ${ -> \${
    
    # Encontrar instructionsPrompt: `...contenido...`
    # IMPORTANTE: el contenido tiene backticks internos, así que no podemos
    # usar un regex simple. Encontramos el start y buscamos el cierre manualmente.
    start_pattern = r'instructionsPrompt:\s*`'
    start_match = re.search(start_pattern, ts_content)
    if not start_match:
        print("ERROR: No se encontró instructionsPrompt en el .ts")
        return False
    
    start_pos = start_match.end()  # posición después del backtick de apertura
    
    # Buscar el cierre: backtick seguido de coma y cierre de objeto
    # El patrón de cierre es `, al final del instructionsPrompt
    # Buscamos hacia atrás desde el final del archivo
    end_pattern = r'`,\s*$'
    end_matches = list(re.finditer(end_pattern, ts_content[start_pos:], re.MULTILINE))
    if not end_matches:
        print("ERROR: No se encontró el cierre de instructionsPrompt")
        return False
    
    # El último match es el cierre correcto
    end_match = end_matches[-1]
    end_pos = start_pos + end_match.start()
    
    # Reemplazar solo el contenido entre backticks
    new_ts = ts_content[:start_pos] + md_escaped + ts_content[end_pos:]
    
    # Guardar
    with open(ts_path, "w", encoding="utf-8") as f:
        f.write(new_ts)
    
    return True
def verify_ts_syntax(ts_path: str) -> bool:
    """Verifica la sintaxis del .ts con node --check."""
    import subprocess
    result = subprocess.run(
        ["node", "--check", ts_path],
        capture_output=True,
        text=True
    )
    return result.returncode == 0

def extract_ts_content(ts_path: str) -> str:
    """Extrae el contenido del instructionsPrompt del .ts."""
    with open(ts_path, "r", encoding="utf-8") as f:
        ts_content = f.read()
    start_pattern = r'instructionsPrompt:\s*`'
    start_match = re.search(start_pattern, ts_content)
    if not start_match:
        return ""
    start_pos = start_match.end()
    end_pattern = r'`,\s*$'
    end_matches = list(re.finditer(end_pattern, ts_content[start_pos:], re.MULTILINE))
    if not end_matches:
        return ""
    end_match = end_matches[-1]
    end_pos = start_pos + end_match.start()
    raw = ts_content[start_pos:end_pos]
    # Des-escapar: revertir lo que hace sync_ts
    raw = raw.replace('\\${', '${')
    raw = raw.replace('\\`', '`')
    raw = raw.replace('\\\\', '\\')
    return raw.strip()

def check_sync(md_path: str, ts_path: str) -> bool:
    """Compara .md vs .ts normalizados. Retorna True si están en sync."""
    md_content = extract_md_content(md_path).strip()
    ts_content = extract_ts_content(ts_path).strip()
    # Normalizar saltos de línea y espacios finales
    md_norm = "\n".join(line.rstrip() for line in md_content.splitlines()).strip()
    ts_norm = "\n".join(line.rstrip() for line in ts_content.splitlines()).strip()
    return md_norm == ts_norm

def main():
    script_dir = Path(__file__).parent
    md_file = script_dir / ".agents" / "teachme.md"
    ts_file = Path.home() / ".agents" / "teachme.ts"

    # --help
    if "--help" in sys.argv or "-h" in sys.argv:
        print("Uso: sync_helper.py [opción]")
        print("")
        print("Opciones:")
        print("  (sin args)    Sincronizar .md → .ts")
        print("  --check       Verificar si .md y .ts están sincronizados (exit 0=ok, 1=desincronizado)")
        print("  --version     Mostrar la versión de la fuente y de la instalada")
        print("  --dry-run     Mostrar qué se sincronizaría sin cambiar nada")
        print("  --help, -h    Muestra esta ayuda")
        return

    # Modo version
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

    backup_file = ts_file.with_suffix(".ts.bak")
    
    # Verificar archivos
    if not md_file.exists():
        print(f"ERROR: No se encontró: {md_file}")
        sys.exit(1)
    
    if not ts_file.exists():
        print(f"ERROR: No se encontró: {ts_file}")
        print("Ejecuta ./install.sh primero para instalar el agente")
        sys.exit(1)

    # Modo check
    if "--check" in sys.argv:
        if check_sync(str(md_file), str(ts_file)):
            print("[OK] Sincronizado: .md y .ts coinciden")
            sys.exit(0)
        else:
            print("[FAIL] Desincronizado: .md y .ts NO coinciden")
            print("  Ejecuta: ./sync-md-ts.sh  para sincronizar")
            md_lines = extract_md_content(str(md_file)).splitlines()
            ts_lines = extract_ts_content(str(ts_file)).splitlines()
            print(f"  .md: {len(md_lines)} lineas | .ts instructionsPrompt: {len(ts_lines)} lineas")
            sys.exit(1)
    
    # Modo dry-run
    if "--dry-run" in sys.argv:
        print("Dry run - sin cambios\n")
        md_content = extract_md_content(str(md_file))
        lines = md_content.split("\n")
        for line in lines[:30]:
            print(line)
        if len(lines) > 30:
            print("...")
        print(f"\nTotal: {len(lines)} líneas")
        return
    
    # Crear backup
    import shutil
    shutil.copy2(ts_file, backup_file)
    print(f"Backup creado: {backup_file}")
    
    # Extraer contenido del .md
    md_content = extract_md_content(str(md_file))
    if not md_content:
        print("ERROR: El contenido del .md está vacío")
        sys.exit(1)
    
    # Sincronizar
    if sync_ts(str(ts_file), md_content):
        print("instructionsPrompt actualizado")
    else:
        print("Error durante la sincronizacion")
        shutil.copy2(backup_file, ts_file)
        sys.exit(1)
    
    # Estampar la version en la cabecera del .ts
    version = extract_md_version(str(md_file))
    if version:
        stamp_ts_version(str(ts_file), version)
        print(f"Version estampada: @teachme v{version}")
    
    # Verificar sintaxis
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

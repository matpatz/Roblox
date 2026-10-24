#!/usr/bin/env python3
"""Mirror a game (or any folder under src/) into the Potassium workspace.

Knit.require() loadstrings voltex/<path>/<module>.lua out of the executor
workspace, and the bundler reads those same files, so copying the repo tree into
<workspace>/voltex lets you bundle locally without pushing the game public.

    python script.py Brisk-Survival
    python script.py games/Brisk-Survival --no-clean
    python script.py Modules/Aimbot --dry-run
    python script.py --list
"""

from __future__ import annotations

import argparse
import os
import shutil
import sys
from pathlib import Path

MIRROR = "voltex"  # same folder name the Knit git module writes to
SKIP_DIRS = {".git", ".history", "__pycache__", ".vscode", ".wrangler"}
DECOMPILED_DIRS = {"Scripts", "source"}
DECOMPILED_FILES = {"source.lua"}


def find_repo_root() -> Path:
    for parent in Path(__file__).resolve().parents:
        if (parent / "src" / "games").is_dir():
            return parent
    sys.exit("could not find repo root: no src/games above script.py")


def find_workspace() -> Path:
    override = os.environ.get("POTASSIUM_WORKSPACE")
    if override:
        return Path(override).expanduser()

    local = os.environ.get("LOCALAPPDATA")
    if not local:
        sys.exit("set POTASSIUM_WORKSPACE to the Potassium workspace folder")

    return Path(local) / "Potassium" / "workspace"


def resolve_source(root: Path, raw: str) -> tuple[Path, Path]:
    src = (root / "src").resolve()

    if Path(raw).is_absolute():
        candidates = [Path(raw).expanduser()]
    else:
        candidates = [root / raw, src / raw, src / "games" / raw]

    for candidate in candidates:
        if candidate.is_dir():
            target = candidate.resolve()
            break
    else:
        sys.exit(f"no such folder: {raw}")

    try:
        rel = target.relative_to(src)
    except ValueError:
        sys.exit(f"{target} is not inside {src}")

    if not rel.parts:
        sys.exit("pick a folder inside src/, not src itself")

    return target, rel


def iter_files(source: Path, include_decompiled: bool):
    for path in sorted(source.rglob("*")):
        if not path.is_file():
            continue

        rel = path.relative_to(source)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if not include_decompiled and (
            rel.parts[0] in DECOMPILED_DIRS or rel.name in DECOMPILED_FILES
        ):
            continue

        yield path, rel


def pick(root: Path) -> str:
    games = sorted(p.name for p in (root / "src" / "games").iterdir() if p.is_dir())
    for i, name in enumerate(games, 1):
        print(f"{i:3}  {name}")

    choice = input("number or name: ").strip()
    if choice.isdigit() and 1 <= int(choice) <= len(games):
        return games[int(choice) - 1]

    return choice


def main() -> None:
    root = find_repo_root()

    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("folder", nargs="?", help="game name or path relative to src/")
    parser.add_argument("--workspace", type=Path, help="override the Potassium workspace folder")
    parser.add_argument("--mirror", default=MIRROR, help=f"mirror folder name (default: {MIRROR})")
    parser.add_argument(
        "--no-clean",
        dest="clean",
        action="store_false",
        help="keep files that no longer exist in the repo",
    )
    parser.add_argument("--dry-run", action="store_true", help="print what would be copied")
    parser.add_argument(
        "--include-decompiled",
        action="store_true",
        help="also copy Scripts/, source/ and source.lua (gitignored)",
    )
    parser.add_argument("--list", action="store_true", help="list games and exit")
    args = parser.parse_args()

    if args.list:
        for name in sorted(p.name for p in (root / "src" / "games").iterdir() if p.is_dir()):
            print(name)
        return

    folder = args.folder or pick(root)
    source, rel = resolve_source(root, folder)
    workspace = (args.workspace or find_workspace()).resolve()
    dest = (workspace / args.mirror / rel).resolve()

    if dest == workspace or dest == (workspace / args.mirror).resolve():
        sys.exit(f"refusing to write into {dest}")

    if args.clean and dest.exists() and not args.dry_run:
        shutil.rmtree(dest)

    copied = 0
    for path, relative in iter_files(source, args.include_decompiled):
        target = dest / relative
        if args.dry_run:
            print(f"{path} -> {target}")
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
        copied += 1

    verb = "would copy" if args.dry_run else "copied"
    print(f"{verb} {copied} file(s): {source} -> {dest}")

    if args.dry_run:
        return

    entry = next((m for m in ("main", "core") if (dest / f"{m}.lua").is_file()), None)
    if entry:
        print(f'Knit path: "{rel.as_posix()}" module "{entry}"')
        print(f"bundle entry: {args.mirror}/{rel.as_posix()}/{entry}.lua")


if __name__ == "__main__":
    main()

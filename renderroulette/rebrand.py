# -*- coding: utf-8 -*-
"""EffectCraft -> RenderRoulette rename for the EffectTool checkout (content, then paths).

usage: python rebrand.py <repo> [--dry]
Keeps each file's bytes/encoding/line endings except for the replaced words. Protected spans are
masked first and restored afterwards.
"""
import os
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(sys.argv[1])
DRY = "--dry" in sys.argv

# Files left byte-for-byte untouched (legal text, generated data, binary fixtures).
SKIP_FILES = {
    "LICENSE", "LICENSE-MIT", "LICENSE-APACHE", "NOTICE",
    "contributors/contributors.json",
    "crates/model/tests/fixtures/quad.glb",
    "packaging/macos/dmg/dmg-layout.DS_Store",
}
SKIP_DIRS = ("docs/brand/",)  # ArtCraft marks + their trademark-licence sidecars

PROTECT = [
    r"storytold(?:/|%2F)effectcraft[\w./#?&=%-]*",           # upstream repo links, raw links, star history
    r"getartcraft\.com/apps/effectcraft",                       # upstream product page
    r"assets/app-icons/effectcraft/?",                         # path inside craftrules
    r"ArtCraft Team and the EffectCraft contributors",         # copyright holder line
    r"EffectCraft contributors",                               # authorship of upstream work
    r"only in the context of\s+EffectCraft",                   # ArtCraft brand terms
    r"part of this repository and EffectCraft",                # ArtCraft brand terms
    r"modified version of EffectCraft",
    r"upstream EffectCraft",
    r"\"EffectCraft\" glyphs",
    r"EffectCraft \(https://github\.com/storytold/effectcraft\)",
]
# README sister-app row for this app points at the upstream repo; keep it whole (edited by hand).
PROTECT_LINE = [r"ai\.storyteller\.effectcraft\.png\" alt="]

REPL = [
    ("EFFECTCRAFT", "RENDERROULETTE"),
    ("EffectCraft", "RenderRoulette"),
    ("Effectcraft", "RenderRoulette"),
    ("effectCraft", "renderRoulette"),
    ("effectcraft", "renderroulette"),
]
CI = re.compile(r"effect.?craft", re.I)


def git(*a):
    return subprocess.run(["git", "-C", str(REPO), *a], check=True, capture_output=True, text=True).stdout


def listed():
    out = git("ls-files", "-co", "--exclude-standard", "-z")
    return [p for p in out.split("\0") if p]


def skipped(rel):
    return rel in SKIP_FILES or rel.startswith(SKIP_DIRS)


def rename_text(t):
    masks = []

    def keep(m):
        masks.append(m.group(0))
        return f"\x00{len(masks) - 1}\x00"

    for pat in PROTECT_LINE:
        t = re.sub(r"[^\n]*" + pat + r"[^\n]*", keep, t)
    for pat in PROTECT:
        t = re.sub(pat, keep, t)
    for a, b in REPL:
        t = t.replace(a, b)
    t = re.sub(r"\x00(\d+)\x00", lambda m: masks[int(m.group(1))], t)
    return t


def main():
    files = listed()
    changed, counts = [], {}
    for rel in files:
        p = REPO / rel
        if skipped(rel) or not p.is_file():
            continue
        raw = p.read_bytes()
        if b"\x00" in raw:
            continue
        if not CI.search(raw.decode("latin-1")):
            continue
        bom = raw.startswith(b"\xef\xbb\xbf")
        try:
            t = raw[3:].decode("utf-8") if bom else raw.decode("utf-8")
        except UnicodeDecodeError:
            print("not utf-8, skipped:", rel)
            continue
        n = rename_text(t)
        if n != t:
            counts[rel] = len(CI.findall(t)) - len(CI.findall(n))
            changed.append(rel)
            if not DRY:
                p.write_bytes((b"\xef\xbb\xbf" if bom else b"") + n.encode("utf-8"))
    print(f"content: {len(changed)} files, {sum(counts.values())} occurrences replaced")

    tracked = set(git("ls-files", "-z").split("\0"))
    # Paths: files first (basename only), then directories deepest first.
    moves = 0
    for rel in sorted(files, key=lambda r: -r.count("/")):
        base = os.path.basename(rel)
        if skipped(rel) or not CI.search(base) or not (REPO / rel).exists():
            continue
        new = os.path.join(os.path.dirname(rel), rename_text(base)).replace("\\", "/")
        moves += 1
        if DRY:
            print("mv", rel, "->", new)
            continue
        if rel in tracked:
            git("mv", rel, new)
        else:
            os.rename(REPO / rel, REPO / new)
    dirs = set()
    for r in (files if DRY else listed()):
        parts = r.split("/")[:-1]
        for i in range(1, len(parts) + 1):
            dirs.add("/".join(parts[:i]))
    for d in sorted(dirs, key=lambda d: -d.count("/")):
        parts = d.split("/")
        if d == "." or not CI.search(parts[-1]):
            continue
        new = "/".join(parts[:-1] + [rename_text(parts[-1])])
        moves += 1
        if DRY:
            print("mv", d + "/", "->", new + "/")
            continue
        git("mv", d, new)
    print(f"paths: {moves} renames")


if __name__ == "__main__":
    main()

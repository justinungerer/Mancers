# -*- coding: utf-8 -*-
"""Rewrite Lucide icon [[asset]] entries in ATTRIBUTION.toml for Phosphor Regular."""
from pathlib import Path
import hashlib
import re

root = Path(r"C:\Users\ELMYZ\dm-src")
toml_path = root / "ATTRIBUTION.toml"
icons = root / "assets" / "icons"
map_path = Path(r"C:\Users\ELMYZ\dm-icons-new\map.tsv")
name_map = {}
for line in map_path.read_text(encoding="utf-8").splitlines():
    if not line.strip():
        continue
    k, v = line.split("\t", 1)
    name_map[k] = v

text = toml_path.read_text(encoding="utf-8")

# Replace licence file references globally for icons
text = text.replace("assets/icons/LICENSE-lucide.txt", "assets/icons/LICENSE-phosphor.txt")

# Update each Lucide icon asset block
pattern = re.compile(
    r'\[\[asset\]\]\n'
    r'path = "(assets/icons/([^"]+\.svg))"\n'
    r'title = "[^"]*"\n'
    r'author = "[^"]*"\n'
    r'source = "[^"]*"\n'
    r'licence = "[^"]*"\n'
    r'licence_file = "[^"]*"\n'
    r'kind = "icon"\n'
    r'usage = "[^"]*"\n'
    r'sha256 = "[0-9a-f]*"',
    re.M,
)

def repl(m):
    path, fname = m.group(1), m.group(2)
    stem = Path(fname).stem
    svg = icons / fname
    if not svg.exists():
        return m.group(0)
    digest = hashlib.sha256(svg.read_bytes()).hexdigest()
    phosphor = name_map.get(stem, stem)
    return (
        f'[[asset]]\n'
        f'path = "{path}"\n'
        f'title = "Phosphor Regular icon \\"{phosphor}\\" (as {stem})"\n'
        f'author = "Phosphor Icons contributors"\n'
        f'source = "https://github.com/phosphor-icons/core (assets/regular/{phosphor}.svg)"\n'
        f'licence = "MIT"\n'
        f'licence_file = "assets/icons/LICENSE-phosphor.txt"\n'
        f'kind = "icon"\n'
        f'usage = "UI icon, embedded via crates/ui-egui/src/icon_data.rs"\n'
        f'sha256 = "{digest}"'
    )

new_text, n = pattern.subn(repl, text)
print(f"updated {n} icon assets")

# Ensure LICENSE-phosphor.txt has an asset entry; drop LICENSE-lucide if present
if "LICENSE-phosphor.txt" not in new_text or 'path = "assets/icons/LICENSE-phosphor.txt"' not in new_text:
    lic = icons / "LICENSE-phosphor.txt"
    digest = hashlib.sha256(lic.read_bytes()).hexdigest()
    block = (
        f'\n[[asset]]\n'
        f'path = "assets/icons/LICENSE-phosphor.txt"\n'
        f'title = "Phosphor Icons MIT licence"\n'
        f'author = "Phosphor Icons contributors"\n'
        f'source = "https://github.com/phosphor-icons/core"\n'
        f'licence = "MIT"\n'
        f'licence_file = "assets/icons/LICENSE-phosphor.txt"\n'
        f'kind = "licence"\n'
        f'usage = "Licence text for the Phosphor Regular UI icons"\n'
        f'sha256 = "{digest}"\n'
    )
    new_text += block
    print("added LICENSE-phosphor asset entry")

# Remove LICENSE-lucide asset entry if any
new_text = re.sub(
    r'\n\[\[asset\]\]\npath = "assets/icons/LICENSE-lucide\.txt"\n(?:.*\n)*?sha256 = "[0-9a-f]*"\n?',
    "\n",
    new_text,
    count=1,
)

# Update i18n catalog sha256s (Lagoon rows changed them)
for tsv in (root / "crates/ui-egui/src/i18n").glob("*.tsv"):
    rel = tsv.relative_to(root).as_posix()
    digest = hashlib.sha256(tsv.read_bytes()).hexdigest()
    new_text, c = re.subn(
        rf'(path = "{re.escape(rel)}"\n(?:.*\n)*?sha256 = ")[0-9a-f]*(")',
        rf'\g<1>{digest}\2',
        new_text,
        count=1,
    )
    print(f"tsv {tsv.name}: hash update={c}")

toml_path.write_text(new_text, encoding="utf-8")
print("wrote", toml_path)

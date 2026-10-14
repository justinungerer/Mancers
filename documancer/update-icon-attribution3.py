# -*- coding: utf-8 -*-
from pathlib import Path
import hashlib
import re

root = Path(r"C:\Users\ELMYZ\dm-src")
toml_path = root / "ATTRIBUTION.toml"
icons = root / "assets" / "icons"
name_map = dict(
    line.split("\t", 1)
    for line in Path(r"C:\Users\ELMYZ\dm-icons-new\map.tsv").read_text(encoding="utf-8").splitlines()
    if "\t" in line
)

text = toml_path.read_text(encoding="utf-8").replace("\r\n", "\n")
q = r'(?:\\.|[^"\\])*'

pattern = re.compile(
    rf'\[\[asset\]\]\n'
    rf'path = "(assets/icons/([^"]+\.svg))"\n'
    rf'title = "{q}"\n'
    rf'author = "{q}"\n'
    rf'source = "{q}"\n'
    rf'licence = "{q}"\n'
    rf'licence_file = "{q}"\n'
    rf'kind = "icon"\n'
    rf'usage = "{q}"\n'
    rf'sha256 = "([0-9a-f]*)"'
)

def repl(m):
    path, fname = m.group(1), m.group(2)
    stem = Path(fname).stem
    digest = hashlib.sha256((icons / fname).read_bytes()).hexdigest()
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
print("updated", n)
assert n >= 180, n

lic = icons / "LICENSE-phosphor.txt"
digest = hashlib.sha256(lic.read_bytes()).hexdigest()
if 'path = "assets/icons/LICENSE-phosphor.txt"' in new_text:
    new_text = re.sub(
        r'(path = "assets/icons/LICENSE-phosphor\.txt"\n(?:.*\n)*?sha256 = ")[0-9a-f]*(")',
        rf'\g<1>{digest}\2',
        new_text,
        count=1,
    )
else:
    new_text += (
        f'\n[[asset]]\npath = "assets/icons/LICENSE-phosphor.txt"\n'
        f'title = "Phosphor Icons MIT licence"\n'
        f'author = "Phosphor Icons contributors"\n'
        f'source = "https://github.com/phosphor-icons/core"\n'
        f'licence = "MIT"\nlicence_file = "assets/icons/LICENSE-phosphor.txt"\n'
        f'kind = "licence"\nusage = "Licence text for the Phosphor Regular UI icons"\n'
        f'sha256 = "{digest}"\n'
    )

new_text = re.sub(
    r'\n\[\[asset\]\]\npath = "assets/icons/LICENSE-lucide\.txt"\n(?:.*\n)*?sha256 = "[0-9a-f]*"\n?',
    "\n",
    new_text,
    count=1,
)

toml_path.write_text(new_text, encoding="utf-8", newline="\n")
print("done")

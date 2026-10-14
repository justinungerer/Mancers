# -*- coding: utf-8 -*-
from pathlib import Path
import hashlib
import re

root = Path(r"C:\Users\ELMYZ\dm-src")
toml_path = root / "ATTRIBUTION.toml"
icons = root / "assets" / "icons"
name_map = {}
for line in Path(r"C:\Users\ELMYZ\dm-icons-new\map.tsv").read_text(encoding="utf-8").splitlines():
    if "\t" in line:
        k, v = line.split("\t", 1)
        name_map[k] = v

raw = toml_path.read_bytes()
nl = b"\r\n" if b"\r\n" in raw else b"\n"
text = raw.decode("utf-8")
# Normalize to \n for processing
text = text.replace("\r\n", "\n")

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
    r'sha256 = "[0-9a-f]*"'
)

def repl(m):
    path, fname = m.group(1), m.group(2)
    stem = Path(fname).stem
    svg = icons / fname
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
print("updated", n)

# Drop lucide licence asset if present
new_text = re.sub(
    r'\n\[\[asset\]\]\npath = "assets/icons/LICENSE-lucide\.txt"\n(?:.*\n)*?sha256 = "[0-9a-f]*"\n?',
    "\n",
    new_text,
    count=1,
)

# Ensure phosphor licence asset exists once
if 'path = "assets/icons/LICENSE-phosphor.txt"' not in new_text:
    lic = icons / "LICENSE-phosphor.txt"
    digest = hashlib.sha256(lic.read_bytes()).hexdigest()
    new_text += (
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
else:
    # refresh hash
    lic = icons / "LICENSE-phosphor.txt"
    digest = hashlib.sha256(lic.read_bytes()).hexdigest()
    new_text = re.sub(
        r'(path = "assets/icons/LICENSE-phosphor\.txt"\n(?:.*\n)*?sha256 = ")[0-9a-f]*(")',
        rf'\g<1>{digest}\2',
        new_text,
        count=1,
    )

out = new_text.replace("\n", nl.decode("ascii"))
toml_path.write_bytes(out.encode("utf-8"))
print("done")

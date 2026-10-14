# -*- coding: utf-8 -*-
from pathlib import Path
import hashlib
import re

root = Path(r"C:\Users\ELMYZ\dm-src")
toml = root / "ATTRIBUTION.toml"
text = toml.read_text(encoding="utf-8")
n = 0
for m in list(re.finditer(r'path = "(assets/app-icon/[^"]+)"\n(?:.*\n)*?sha256 = "([0-9a-f]*)"', text)):
    rel = m.group(1)
    p = root / rel
    if not p.exists():
        print("missing", rel)
        continue
    dig = hashlib.sha256(p.read_bytes()).hexdigest()
    old = m.group(0)
    new = re.sub(r'sha256 = "[0-9a-f]*"', f'sha256 = "{dig}"', old)
    text = text.replace(old, new)
    n += 1
    print("hash", rel)
toml.write_text(text, encoding="utf-8")
print("updated", n)

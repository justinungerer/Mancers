# -*- coding: utf-8 -*-
from pathlib import Path

DIR = Path(r"C:\Users\ELMYZ\dm-src\crates\ui-egui\src\i18n")

TRANSLATIONS = {
    "de.tsv": ("Lagune (Hell)", "Lagune"),
    "fr.tsv": ("Lagon (clair)", "Lagon"),
    "es.tsv": ("Lagoon (claro)", "Lagoon"),
    "pt-br.tsv": ("Lagoon (claro)", "Lagoon"),
    "cs.tsv": ("Laguna (světlá)", "Laguna"),
    "ja.tsv": ("ラグーン（ライト）", "ラグーン"),
    "zh-hans.tsv": ("潟湖（浅色）", "潟湖"),
    "zh-hant.tsv": ("潟湖（淺色）", "潟湖"),
    "ru.tsv": ("Лагуна (светлая)", "Лагуна"),
    "bg.tsv": ("Лагуна (светла)", "Лагуна"),
    "te.tsv": ("లగూన్ (లైట్)", "లగూన్"),
}

for name, (full, bare) in TRANSLATIONS.items():
    path = DIR / name
    text = path.read_text(encoding="utf-8")
    nl = "\r\n" if "\r\n" in text else "\n"
    lines = text.splitlines()
    lines = [ln for ln in lines if not (ln.lstrip("\t").startswith("Lagoon"))]
    out = []
    inserted = False
    for ln in lines:
        out.append(ln)
        if not inserted and "\tLight gray\t" in ln:
            prefix = "\t" if ln.startswith("\t") else ""
            out.append(f"{prefix}Lagoon (Light)\t{full}")
            out.append(f"{prefix}Lagoon\t{bare}")
            inserted = True
    if not inserted:
        for i, ln in enumerate(list(out)):
            if "Light gray" in ln or ln.endswith("Display theme") or "\tDisplay theme\t" in ln:
                prefix = "\t" if ln.startswith("\t") else ""
                # Prefer after Use system / Light gray cluster; else after Display theme
                if "Display theme" in ln and "Light gray" not in "\n".join(out):
                    out.insert(i + 1, f"{prefix}Lagoon (Light)\t{full}")
                    out.insert(i + 2, f"{prefix}Lagoon\t{bare}")
                    # Also add the English keys' siblings if missing
                    inserted = True
                    break
                if "Light gray" in ln:
                    out.insert(i + 1, f"{prefix}Lagoon (Light)\t{full}")
                    out.insert(i + 2, f"{prefix}Lagoon\t{bare}")
                    inserted = True
                    break
    if not inserted:
        # Append near end before trailing blanks
        prefix = "\t"
        out.append(f"{prefix}Lagoon (Light)\t{full}")
        out.append(f"{prefix}Lagoon\t{bare}")
        print(f"appended {name}")
    else:
        print(f"ok {name}")
    path.write_text(nl.join(out) + (nl if text.endswith(("\n", "\r\n")) else ""), encoding="utf-8")

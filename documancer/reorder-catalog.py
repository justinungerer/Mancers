# -*- coding: utf-8 -*-
"""Reorder TOOL_GROUPS into a document workflow order. Groups stay intact."""
from pathlib import Path
import re

path = Path(r"C:\Users\ELMYZ\dm-src\crates\engine\src\catalog.rs")
text = path.read_text(encoding="utf-8")
# Desired workflow: create/assemble → organize/edit → annotate/sign → protect →
# process/export → production/measure → verify → automate.
ORDER = [
    "create", "combine", "organize", "edit", "comment", "stamp", "fill_sign", "form",
    "protect", "certificate", "redact", "scan", "compress", "export",
    "print_production", "measure", "compare", "search_index",
    "accessibility", "standards", "actions", "javascript", "ai",
]

m = re.search(r"(pub static TOOL_GROUPS: &\[ToolGroup\] = &\[)(.*)(\n\];)", text, re.S)
if not m:
    raise SystemExit("TOOL_GROUPS not found")
body = m.group(2)
# Split on top-level ToolGroup { ... }, tracking brace depth.
groups = []
i = 0
while True:
    start = body.find("ToolGroup {", i)
    if start < 0:
        break
    depth = 0
    j = start
    while j < len(body):
        if body[j] == "{":
            depth += 1
        elif body[j] == "}":
            depth -= 1
            if depth == 0:
                # include trailing comma/whitespace
                k = j + 1
                while k < len(body) and body[k] in " \t\r\n,":
                    k += 1
                chunk = body[start:k]
                id_m = re.search(r'id:\s*"([^"]+)"', chunk)
                if not id_m:
                    raise SystemExit(f"no id in chunk at {start}")
                groups.append((id_m.group(1), chunk.rstrip() + "\n"))
                i = k
                break
        j += 1
    else:
        raise SystemExit("unbalanced braces")

ids = [g[0] for g in groups]
if sorted(ids) != sorted(ORDER):
    raise SystemExit(f"id mismatch\n have: {ids}\n want: {ORDER}\n missing: {set(ORDER)-set(ids)}\n extra: {set(ids)-set(ORDER)}")
by_id = dict(groups)
new_body = "\n" + "".join(by_id[i] for i in ORDER)
# Ensure commas between groups
parts = []
for idx, gid in enumerate(ORDER):
    chunk = by_id[gid].rstrip()
    if not chunk.endswith(","):
        chunk += ","
    parts.append(chunk + "\n")
new_body = "\n" + "".join(parts)
new_text = text[: m.start(2)] + new_body + text[m.start(3) :]
path.write_text(new_text, encoding="utf-8")
print("reordered", len(ORDER), "groups")
# Add / update presence test if missing
if "workflow_order_keeps_every_tool_group_once" not in new_text:
    print("note: add test separately")

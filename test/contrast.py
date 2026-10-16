#!/usr/bin/env python3
"""Check that every prebuilt theme is readable: text at or above WCAG AA (4.5:1)
against its background, cursor at or above 3:1, and every light-palette color
at or above 3:1 on every light background. Exits 1 and lists the failures."""
import importlib.util
import sys
from pathlib import Path

CLI = Path(__file__).resolve().parent.parent / "bin" / "tint"
tint = importlib.util.module_from_spec(importlib.util.spec_from_loader("tint", loader=None))
tint.__file__ = str(CLI)
exec(compile(CLI.read_text(), str(CLI), "exec"), tint.__dict__)


def luminance(color):
    channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


failures = []
names = set()
for t in tint.THEMES:
    if t["name"] in names:
        failures.append("%s: duplicate name" % t["name"])
    names.add(t["name"])
    text = contrast(t["bg"], t["fg"])
    cursor = contrast(t["bg"], t["cursor"])
    if text < 4.5:
        failures.append("%s: text %.2f:1 on %s" % (t["name"], text, t["bg"]))
    if cursor < 3:
        failures.append("%s: cursor %.2f:1 on %s" % (t["name"], cursor, t["bg"]))
    for i, color in enumerate(t["palette"]):
        if i != 0 and contrast(t["bg"], color) < 3:
            failures.append("%s: palette %d %s is %.2f:1" % (t["name"], i, color, contrast(t["bg"], color)))
    print("%-10s text %5.2f  cursor %5.2f  %s" % (t["name"], text, cursor, "light" if t["light"] else "dark"))

print("\n%d themes" % len(tint.THEMES))
if failures:
    print("\n".join(failures))
    sys.exit(1)
print("all readable")

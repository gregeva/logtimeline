#!/usr/bin/env python3
"""profile-colours.py <file.terminal or prefs plist> [profile]: decodes the
NSColor archives of a Terminal.app profile (ANSI colours, text, bold, background)."""
import plistlib, sys
def color(data):
    a = plistlib.loads(data)
    objs = a["$objects"]
    root = objs[a["$top"]["root"].data if hasattr(a["$top"]["root"], "data") else 1]
    def deref(v): return objs[v.data] if isinstance(v, plistlib.UID) else v
    root = deref(a["$top"]["root"])
    if "NSRGB" in root:
        vals = [float(x) for x in root["NSRGB"].split(b"\x00")[0].split()]
        return "#%02x%02x%02x" % tuple(round(v * 255) for v in vals[:3]) + (f" a{vals[3]:.2f}" if len(vals) > 3 else "") + f" cs{root.get('NSColorSpace')}"
    if "NSWhite" in root:
        vals = [float(x) for x in root["NSWhite"].split(b"\x00")[0].split()]
        g = round(vals[0] * 255); return "#%02x%02x%02x" % (g, g, g) + f" white cs{root.get('NSColorSpace')}"
    if "NSCatalogName" in root or "NSColorName" in root:
        return f"catalog {deref(root.get('NSCatalogName'))}/{deref(root.get('NSColorName'))}"
    return "?" + ",".join(root.keys())
p = plistlib.load(open(sys.argv[1], "rb"))
if len(sys.argv) > 2: p = p["Window Settings"][sys.argv[2]]
keys = ["BackgroundColor", "TextColor", "TextBoldColor"] + [k for k in sorted(p) if k.startswith("ANSI")]
for k in keys:
    if k in p and isinstance(p[k], bytes): print(f"  {k:24} {color(p[k])}")
    elif k in p: print(f"  {k:24} {p[k]}")
print("  ANSI keys:", sum(1 for k in p if k.startswith("ANSI")), "| DynamicANSIForegroundColors:", p.get("DynamicANSIForegroundColors", "(unset)"))

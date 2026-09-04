#!/usr/bin/env python3
"""Stamp the default Minecraft assets version into macros.gml.

Used by release.yml so release builds default to the freshly fetched
latest assets instead of the repo template version. Edits in place:

    python3 Tools/stamp_minecraft_version.py 26.3
"""

import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MACROS = os.path.join(
    REPO_ROOT, "GmProject", "scripts", "macros", "macros.gml")


def main(argv):
    if len(argv) != 2 or not argv[1].strip():
        print("usage: stamp_minecraft_version.py <mc-version>")
        return 2
    version = argv[1].strip()
    with open(MACROS, "r", encoding="utf-8") as f:
        text = f.read()
    new_text, count = re.subn(
        r'(?m)^(\s*#macro minecraft_version\s+")[^"]*(")',
        r"\g<1>" + version + r"\g<2>", text)
    if count != 1:
        print("error: expected 1 minecraft_version macro, found %d" % count)
        return 1
    with open(MACROS, "w", encoding="utf-8") as f:
        f.write(new_text)
    print("Stamped default Minecraft assets version: %s" % version)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))

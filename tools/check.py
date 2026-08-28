#!/usr/bin/env python3
"""Check the things that can quietly drift apart in the mod.

    python3 tools/check.py

Three copies of the Wild Green palette exist in this tree, and they have to
agree:

    tools/palette.py    RAMP, PIC_RAMP and TITLE_RAMP, and what the label
                        is drawn from
    transforms.lua      WILD_GREEN and WILD_GREEN_PIC, what the player's art
                        is recolored to
    main.lua            WILD_GREEN, what MEWMON is overridden with;
                        WILD_GREEN_PIC, what the title figure is baked to;
                        WILD_GREEN_TITLE, what LOGO1 is overridden with

The character ramp and the title ramp are different on purpose: the character
is a sprite whose second shade is skin, and the ribbon is lettering on white.

They are copies rather than one file because none of the three can import
from either of the others: the transform runs in a sandbox with no require,
an entry chunk cannot require its own files, and the tools are Python.  So
the duplication is the design, and this is what makes it safe.

Also checked: `assets/title/wild_green_version.png` is still what
`tools/make_ribbon.py` draws, and it still fits the 160 px screen.

`tools/palette.py` and `tools/ribbon.py` are carried in the cart's repo too
(wild1walker/Gen1WildGreen).  Nothing here can reach that copy; the cart's
own check compares them while the two trees are together.

Exits non-zero on any finding, which is what CI wants.
"""

import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

from palette import EXTRA, PIC_RAMP, RAMP, TITLE_RAMP, hexof  # noqa: E402

# (file, the table in it, what tools/palette.py says it must be)
RAMPS = (
    ("transforms.lua", "local WILD_GREEN =", RAMP),
    ("transforms.lua", "local WILD_GREEN_PIC", PIC_RAMP),
    ("main.lua", "local WILD_GREEN =", RAMP),
    ("main.lua", "local WILD_GREEN_PIC", PIC_RAMP),
    ("main.lua", "local WILD_GREEN_TITLE", TITLE_RAMP),
)
RIBBON = ROOT / "assets" / "title" / "wild_green_version.png"

# a { 0xff, 0xff, 0xff } row of a Lua colour table
ROW = re.compile(r"\{\s*(0x[0-9a-fA-F]{2})\s*,\s*(0x[0-9a-fA-F]{2})\s*,"
                 r"\s*(0x[0-9a-fA-F]{2})\s*\}")

findings = []


def fail(where, message):
    findings.append("%s: %s" % (where, message))


def lua_ramp(path, marker):
    """The four colours of the table that follows `marker` in a Lua file."""
    text = path.read_text(encoding="utf-8")
    at = text.find(marker)
    if at < 0:
        fail(path.name, "no %r table to check" % marker)
        return None
    rows = ROW.findall(text[at:at + 400])[:4]
    if len(rows) != 4:
        fail(path.name, "the %r table has %d colours, not 4"
             % (marker, len(rows)))
        return None
    return [tuple(int(c, 16) for c in row) for row in rows]


def check_palettes():
    for name, marker, expected in RAMPS:
        ramp = lua_ramp(ROOT / name, marker)
        if ramp is None:
            continue
        if ramp != expected:
            fail(name, "%s is %s; tools/palette.py says %s"
                 % (marker.split()[-1],
                    " ".join(hexof(c) for c in ramp),
                    " ".join(hexof(c) for c in expected)))


def check_extras():
    """The colours that are not shades: MOUTH, told apart by position."""
    text = (ROOT / "transforms.lua").read_text(encoding="utf-8")
    for name, want in EXTRA.items():
        at = text.find("local " + name)
        if at < 0:
            fail("transforms.lua", "no %s to check" % name)
            continue
        found = ROW.findall(text[at:at + 200])
        got = tuple(int(c, 16) for c in found[0]) if found else None
        if got != want:
            fail("transforms.lua", "%s is %s; tools/palette.py says %s"
                 % (name, got and hexof(got), hexof(want)))


def check_pics():
    """The recipe's list and the hook's list are the same list.

    They have to be.  A swap to a green file the recipe did not write does
    not fall back to the red one -- the image fails to load and the draw
    shows nothing at all -- so the hook must only ever name a picture the
    recipe covers.
    """
    recipe = re.findall(r'\{\s*"([^"]+)"\s*,\s*(?:true|false)\s*\}',
                        (ROOT / "transforms.lua").read_text(encoding="utf-8"))
    text = (ROOT / "main.lua").read_text(encoding="utf-8")
    block = re.search(r"local RECOLOURED = \{(.*?)\n  \}", text, re.S)
    if block is None:
        fail("main.lua", "no RECOLOURED list to compare")
        return
    hook = re.findall(r'"([^"]+\.png)"', block.group(1))
    if recipe != hook:
        fail("PICS", "the recipe recolours %s but the hook swaps %s"
             % (recipe, hook))


def check_generated():
    """A rebuild has to produce the bytes that are committed."""
    if not RIBBON.is_file():
        fail("make_ribbon.py", "%s is missing; run it" % RIBBON.name)
        return
    before = RIBBON.read_bytes()
    run = subprocess.run([sys.executable, str(ROOT / "tools" / "make_ribbon.py")],
                         capture_output=True, text=True, cwd=ROOT)
    if run.returncode != 0:
        fail("make_ribbon.py", "exited %d: %s"
             % (run.returncode, run.stderr.strip()))
        return
    if RIBBON.read_bytes() != before:
        fail("make_ribbon.py", "%s is stale; the committed file is not what "
                               "the tool draws" % RIBBON.name)


def main():
    check_palettes()
    check_extras()
    check_pics()
    check_generated()
    for finding in findings:
        print("check: %s" % finding)
    if findings:
        return 1
    print("check: palettes agree, the ribbon is current")
    return 0


if __name__ == "__main__":
    sys.exit(main())

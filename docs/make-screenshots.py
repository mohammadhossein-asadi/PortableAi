#!/usr/bin/env python3
"""Render terminal-style PNG screenshots from real captured launcher output.

Crops specific sections out of the genuine runs captured from
run-llama.bat and setup.bat, so the images show exactly what users see.

Run from the repo root on Windows (Git Bash / MSYS):

    python docs/make-screenshots.py /tmp/shot-launcher.txt /tmp/out-r3.txt
"""
import sys

from PIL import Image, ImageDraw, ImageFont

FONT = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 15)
FONT_BOLD = ImageFont.truetype("C:/Windows/Fonts/consolab.ttf", 15)

BG = (30, 30, 30)
FG = (204, 204, 204)
DIM = (130, 130, 130)
ACCENT = (80, 200, 255)      # cyan for banners/titles
GREEN = (98, 200, 100)       # [OK]
YELLOW = (230, 200, 80)      # prompts / warnings
PROMPT_PATH = (150, 190, 130)

SCALE = 2

CH = {"w": 0, "h": 0}


def measure():
    tmp = Image.new("RGB", (10, 10))
    d = ImageDraw.Draw(tmp)
    CH["w"] = d.textlength("0", font=FONT)
    CH["h"] = 19


def colorize(line):
    s = line.strip()
    if s.startswith("=="):
        return ACCENT
    if s.startswith("[OK]"):
        return GREEN
    if s.startswith("[") and s[1:3].strip().rstrip("]").isdigit():
        return ACCENT
    if s.startswith("Select") or s.startswith("Download another"):
        return YELLOW
    if s.startswith("C:\\"):
        return PROMPT_PATH
    if s.startswith("[") and "ERROR" in s:
        return (230, 100, 100)
    if s.startswith("[SKIP]"):
        return YELLOW
    return FG


def render(path, title, rows, width=86):
    measure()
    lh = CH["h"]
    w = int(width * CH["w"]) + 48
    h = len(rows) * lh + 48 + 26
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)

    # fake title bar with traffic lights
    bar = (45, 45, 45)
    d.rectangle([0, 0, w, 26], fill=bar)
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse([14 + i * 20, 8, 26 + i * 20, 20], fill=c)
    tf = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 12)
    tw = d.textlength(title, font=tf)
    d.text(((w - tw) / 2, 6), title, font=tf, fill=(180, 180, 180))

    y = 26 + 16
    for line in rows:
        d.text((24, y), line, font=FONT, fill=colorize(line))
        y += lh
    img = img.resize((w * SCALE, h * SCALE), Image.LANCZOS)
    img.save(path)
    print("wrote", path, f"({w*SCALE}x{h*SCALE})")


def crop(src_lines, start_pat, count):
    """Return lines starting at the line matching start_pat, count lines."""
    for i, ln in enumerate(src_lines):
        if start_pat in ln:
            return src_lines[i:i + count]
    raise SystemExit(f"pattern not found: {start_pat}")


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: make-screenshots.py <launcher-capture> <setup-capture>")

    # --- captured launcher output (real run) ---
    launch = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    launch = launch.replace("\r\n", "\n").split("\n")
    launch = [ln for ln in launch if ln not in ("\f", "")]

    # shot 1: prompt + boot + model menu + RUN TYPE
    rows = []
    rows.append("Microsoft Windows [Version 10.0.26200.7171]")
    rows.append("(c) Microsoft Corporation. All rights reserved.")
    rows.append("")
    rows.append("C:\\Users\\MohammadHossein\\Desktop\\PortableAi>run-llama.bat")
    rows.append("")
    rows += crop(launch, "PortableAI - AI Agent Launcher", 22)
    render("docs/screenshot-launcher.png", "run-llama.bat", rows)

    # shot 2: agent modes
    rows = crop(launch, "AGENT MODE", 24)
    render("docs/screenshot-agent-modes.png", "run-llama.bat", rows)

    # shot 3: configuration summary + server URL
    rows = []
    rows += crop(launch, "FINAL SETUP", 32)
    rows.append("============================================================")
    rows.append("")
    rows.append("  Web UI:  http://127.0.0.1:8080")
    rows.append("  API:     http://127.0.0.1:8080/v1/chat/completions")
    rows.append("  (server output continues below)")
    render("docs/screenshot-server.png", "run-llama.bat", rows)

    # --- captured setup output (real run) ---
    setup = open(sys.argv[2], encoding="utf-8", errors="replace").read()
    setup = setup.replace("\r\n", "\n").split("\n")
    setup = [ln for ln in setup if ln not in ("\f", "")]

    # shot 4: setup wizard with curated models
    rows = []
    rows.append("C:\\Users\\MohammadHossein\\Desktop\\PortableAi>setup.bat")
    rows.append("")
    rows += crop(setup, "PortableAI - First-Run Setup", 10)
    rows.append("")
    rows += crop(setup, "[2/4] llama.cpp binaries...", 10)
    rows.append("  ...")
    rows += crop(setup, "Curated models", 11)
    render("docs/screenshot-setup.png", "setup.bat", rows)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Yaadly logo: a butter-yellow sticky note with curly handwriting,
drawn in the app's style (ink outlines, hard offset shadow) on textured sun-yellow paper.

Renders every PNG the app needs with headless Chrome:
    python3 design/logo/render.py
Then:  dart run flutter_launcher_icons && dart run flutter_native_splash:create
"""
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "icon"
SRC = pathlib.Path(__file__).resolve().parent

INK, SUN, PAPER, BUTTER, RUST, CREAM, SAND = "#2D2113", "#F7C948", "#FFFDF6", "#FFF1AD", "#B83D26", "#FBF6EA", "#ECDCC0"
BG = "#FFD93D"  # icon background: a lighter, poppier take on the app's sun yellow
W = 22  # outline width on a 1024 canvas

DEFS = f"""
<defs>
  <filter id="hard" x="-50%" y="-50%" width="200%" height="200%">
    <feOffset in="SourceAlpha" dx="26" dy="26" result="o"/>
    <feFlood flood-color="{INK}"/>
    <feComposite in2="o" operator="in"/>
    <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
  <filter id="grain" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="3" seed="7" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.18  0 0 0 0 0.13  0 0 0 0 0.07  0 0 0 -1.6 1.05"/>
  </filter>
  <filter id="blotch" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.006" numOctaves="2" seed="3" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 1  0 0 0 0 0.98  0 0 0 0 0.85  0 0 0 1.4 -0.55"/>
  </filter>
  <filter id="fibers" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.004 0.18" numOctaves="2" seed="11" result="n"/>
    <feColorMatrix in="n" type="matrix" values="0 0 0 0 0.45  0 0 0 0 0.3  0 0 0 0 0.05  0 0 0 2.2 -1.25"/>
  </filter>
</defs>
"""

BACKGROUND = f"""
<rect width="1024" height="1024" fill="{BG}"/>
<rect width="1024" height="1024" filter="url(#blotch)" opacity="0.4"/>
<rect width="1024" height="1024" filter="url(#fibers)" opacity="0.18"/>
<rect width="1024" height="1024" filter="url(#grain)" opacity="0.15"/>
"""

# The mark is designed inside Android's adaptive-icon safe circle (r = 341 around the centre).
NOTE_SCALE = 0.78


def wavy(x0: int, x1: int, y: int, amp: int = 13, half: int = 28) -> str:
    """A hand-drawn curly line from x0 to x1."""
    n = max(1, (x1 - x0) // half)
    return f"M{x0},{y} q{half / 2},{-amp * 1.4} {half},0" + f" t{half},0" * (n - 1)


MARK = f"""
<g filter="url(#hard)">
 <g transform="translate(512 512) scale({NOTE_SCALE}) translate(-512 -512) rotate(-7 512 530)"
    stroke="{INK}" stroke-width="{W / NOTE_SCALE:.1f}" stroke-linejoin="round" stroke-linecap="round">
  <!-- sticky note with a folded bottom-right corner -->
  <path d="M276,262 L748,262 L748,672 L638,794 L276,794 Z" fill="{BUTTER}"/>
  <path d="M638,794 L638,690 Q638,672 656,672 L748,672 Z" fill="{SAND}"/>
  <!-- glue strip -->
  <path d="M276,262 L748,262 L748,316 L276,316 Z" fill="{SUN}" stroke="none" opacity="0.55"/>
  <path d="M276,262 L748,262 L748,672 L638,794 L276,794 Z" fill="none"/>
  <!-- curly handwriting -->
  <path d="{wavy(334, 670, 452)}" fill="none" stroke-width="20"/>
  <path d="{wavy(334, 670, 546)}" fill="none" stroke-width="20"/>
  <path d="{wavy(334, 558, 640)}" fill="none" stroke-width="20"/>
 </g>
</g>
"""


def svg(body: str, size: int = 1024, extra: str = "") -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="0 0 1024 1024">'
        f"{DEFS}{extra}{body}</svg>"
    )


def badge() -> str:
    """Rounded-square icon with outline + hard shadow, for the pre-Android-12 splash."""
    clip = '<clipPath id="r"><rect x="70" y="70" width="860" height="860" rx="200"/></clipPath>'
    inner = f'<g clip-path="url(#r)"><g transform="translate(70 70) scale(0.83984)">{BACKGROUND}{MARK}</g></g>'
    return (
        f'<defs>{clip}</defs>'
        f'<rect x="96" y="96" width="860" height="860" rx="200" fill="{INK}"/>'
        f"{inner}"
        f'<rect x="70" y="70" width="860" height="860" rx="200" fill="none" stroke="{INK}" stroke-width="20"/>'
    )


TARGETS = {
    "icon.png": (svg(BACKGROUND + MARK), 1024),  # legacy / full icon
    "icon_bg.png": (svg(BACKGROUND), 1024),  # adaptive background
    "icon_fg.png": (svg(MARK), 1024),  # adaptive foreground (transparent)
    "splash_android12.png": (svg(MARK, 1152), 1152),  # Android 12+ splash (masked to a circle)
    "splash.png": (svg(badge(), 768), 768),  # older Android splash
}


def render(name: str, markup: str, size: int, tmp: pathlib.Path) -> None:
    html = tmp / f"{name}.html"
    html.write_text(f"<!doctype html><html><body style='margin:0;background:transparent'>{markup}</body></html>")
    subprocess.run(
        [
            "google-chrome", "--headless=new", "--disable-gpu", "--hide-scrollbars",
            "--default-background-color=00000000", f"--window-size={size},{size}",
            f"--screenshot={OUT / name}", html.as_uri(),
        ],
        check=True, capture_output=True,
    )


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    (SRC / "yaadly-logo.svg").write_text(svg(BACKGROUND + MARK))
    with tempfile.TemporaryDirectory() as t:
        for name, (markup, size) in TARGETS.items():
            render(name, markup, size, pathlib.Path(t))
            print("wrote", OUT / name)


if __name__ == "__main__":
    main()

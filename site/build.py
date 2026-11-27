"""Hachibu statik sitesini üretir (GitHub Pages).

Tek kaynak ilkesi: gizlilik metinleri uygulamanın da okuduğu legal/*.md
dosyalarından üretilir; site için ayrı kopya tutulmaz.

Kullanım (repo kökünden):  python site/build.py   → çıktı: _site/
Gereksinim: pip install markdown
"""
from __future__ import annotations

import html
import shutil
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
SITE = ROOT / "site"
OUT = ROOT / "_site"

CONTACT = "umur.pasa@outlook.com"


def page(title: str, lang: str, body: str, *, alt_link: str = "") -> str:
    return f"""<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<link rel="icon" href="assets/icon.png">
<link rel="stylesheet" href="assets/style.css">
</head>
<body>
<header class="top">
  <a class="brand" href="./"><img src="assets/icon.png" alt="" width="32" height="32"><span>Hachibu</span></a>
  <nav>{alt_link}</nav>
</header>
<main>
{body}
</main>
<footer>Hachibu · <a href="mailto:{CONTACT}">{CONTACT}</a></footer>
</body>
</html>
"""


def legal(md_name: str, out_name: str, lang: str, title: str, alt_link: str) -> None:
    text = (ROOT / "legal" / md_name).read_text(encoding="utf-8")
    body = markdown.markdown(text, extensions=["tables"])
    body = f'<article class="prose">{body}</article>'
    (OUT / out_name).write_text(page(title, lang, body, alt_link=alt_link), encoding="utf-8")


def main() -> None:
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir()
    shutil.copytree(SITE / "assets", OUT / "assets")

    for name in ("index.html", "delete-account.html"):
        src = (SITE / name).read_text(encoding="utf-8")
        title, lang, body = src.split("\n---\n", 2)
        (OUT / name).write_text(page(title.strip(), lang.strip(), body), encoding="utf-8")

    legal("aydinlatma-metni.tr.md", "gizlilik.html", "tr",
          "Hachibu — Aydınlatma Metni ve Gizlilik Politikası",
          '<a href="privacy.html">English</a>')
    legal("privacy-policy.en.md", "privacy.html", "en",
          "Hachibu — Privacy Policy",
          '<a href="gizlilik.html">Türkçe</a>')

    (OUT / ".nojekyll").write_text("")
    print("built →", OUT)


if __name__ == "__main__":
    main()

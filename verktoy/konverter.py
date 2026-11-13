#!/usr/bin/env python3
"""Gjør om jusslos-JSON til Markdown eller HTML. Krever bare Python 3.9+, ingen pakker.

Eksempler:
  python verktoy/konverter.py data/lover/lov-2005-06-17-62.json            # Markdown til skjerm
  python verktoy/konverter.py data/lover/lov-2005-06-17-62.json -f html -o aml.html
  python verktoy/konverter.py data/lover -f md -o ut/                       # hel mappe
"""
from __future__ import annotations

import argparse
import html
import json
import pathlib
import sys

KREDITERING = "Kilde: Lovdata, under Norsk lisens for offentlige data (NLOD 2.0)."


# ---------- Markdown ----------

def md_ledd(tekst: str) -> str:
    # Linjeskift innenfor et ledd (listepunkter) blir harde linjeskift i Markdown
    return "  \n".join(tekst.split("\n"))


def md_blokker(blokker, niva: int, ut: list[str]):
    for b in blokker:
        t = b["type"]
        if t == "seksjon":
            if b.get("overskrift"):
                ut.append("#" * min(niva, 6) + " " + b["overskrift"])
            md_blokker(b["innhold"], niva + 1, ut)
        elif t == "paragraf":
            hode = " ".join(x for x in (b.get("nummer"), b.get("tittel")) if x)
            if b.get("fremtidig"):
                hode += " (ikke i kraft)"
            ut.append("#" * min(niva, 6) + " " + (hode or "Paragraf"))
            for ledd in b["ledd"]:
                ut.append(md_ledd(ledd))
            for e in b.get("endringer", []):
                ut.append(f"*{e}*")
            md_blokker(b.get("underparagrafer", []), niva + 1, ut)
        elif t == "endring":
            ut.append(f"*{b['tekst']}*")
        else:
            ut.append(b["tekst"])


def til_markdown(d: dict) -> str:
    ut = [f"# {d['tittel']}", ""]
    meta = [
        ("Korttittel", d.get("korttittel")),
        ("Id", d.get("refid")),
        ("Departement", ", ".join(d.get("departement", []))),
        ("I kraft fra", d.get("ikraft")),
        ("Sist endret ved", "; ".join(x["tekst"] for x in d.get("sist_endret_ved", []))),
        ("Rettsområde", "; ".join(d.get("rettsomrade", []))),
        ("Lovdata", d.get("url")),
    ]
    ut += [f"- **{k}:** {v}" for k, v in meta if v]
    deler: list[str] = []
    md_blokker(d["innhold"], 2, deler)
    ut += [""] + ["\n\n".join(deler)]
    if d.get("fotnoter"):
        ut += ["", "## Fotnoter", ""] + [f"{f.get('nr') or '-'}. {f['tekst']}" for f in d["fotnoter"]]
    ut += ["", "---", KREDITERING, ""]
    return "\n".join(ut)


# ---------- HTML ----------

def h_ledd(tekst: str) -> str:
    linjer = [html.escape(l) for l in tekst.split("\n")]
    return "<p>" + "<br>\n".join(linjer) + "</p>"


def h_blokker(blokker, niva: int, ut: list[str]):
    for b in blokker:
        t = b["type"]
        n = min(niva, 6)
        if t == "seksjon":
            ut.append(f'<section id="{html.escape(b.get("id") or "")}">')
            if b.get("overskrift"):
                ut.append(f"<h{n}>{html.escape(b['overskrift'])}</h{n}>")
            h_blokker(b["innhold"], niva + 1, ut)
            ut.append("</section>")
        elif t == "paragraf":
            hode = " ".join(x for x in (b.get("nummer"), b.get("tittel")) if x)
            kl = ' class="fremtidig"' if b.get("fremtidig") else ""
            ut.append(f'<article id="{html.escape(b.get("id") or "")}"{kl}><h{n}>{html.escape(hode)}</h{n}>')
            ut += [h_ledd(l) for l in b["ledd"]]
            ut += [f'<p class="endring">{html.escape(e)}</p>' for e in b.get("endringer", [])]
            h_blokker(b.get("underparagrafer", []), niva + 1, ut)
            ut.append("</article>")
        elif t == "endring":
            ut.append(f'<p class="endring">{html.escape(b["tekst"])}</p>')
        else:
            ut.append(h_ledd(b["tekst"]))


CSS = """body{font:16px/1.55 Georgia,serif;max-width:46rem;margin:2rem auto;padding:0 1rem;color:#1a1a1a;background:#fff}
h1{font-size:1.6rem}h2,h3,h4{font-family:system-ui,sans-serif}dl{display:grid;grid-template-columns:max-content 1fr;gap:.2rem 1rem;font-size:.9rem}
dt{font-weight:600}.endring{font-size:.85rem;color:#666;font-style:italic}.fremtidig{border-left:3px solid #c90;padding-left:.8rem}
footer{margin-top:3rem;font-size:.85rem;color:#666}@media(prefers-color-scheme:dark){body{background:#151515;color:#e6e6e6}.endring,footer{color:#aaa}}"""


def til_html(d: dict) -> str:
    meta = [
        ("Id", d.get("refid")), ("Departement", ", ".join(d.get("departement", []))),
        ("I kraft fra", d.get("ikraft")),
        ("Sist endret ved", "; ".join(x["tekst"] for x in d.get("sist_endret_ved", []))),
    ]
    ut = ["<!doctype html>", '<html lang="nb"><head><meta charset="utf-8">',
          '<meta name="viewport" content="width=device-width,initial-scale=1">',
          f"<title>{html.escape(d.get('korttittel') or d['tittel'])}</title><style>{CSS}</style></head><body>",
          f"<h1>{html.escape(d['tittel'])}</h1><dl>"]
    ut += [f"<dt>{k}</dt><dd>{html.escape(v)}</dd>" for k, v in meta if v]
    ut.append(f'<dt>Lovdata</dt><dd><a href="{html.escape(d["url"])}">{html.escape(d["url"])}</a></dd></dl>')
    h_blokker(d["innhold"], 2, ut)
    if d.get("fotnoter"):
        ut.append("<h2>Fotnoter</h2><ol>")
        ut += [f"<li>{html.escape(f['tekst'])}</li>" for f in d["fotnoter"]]
        ut.append("</ol>")
    ut.append(f"<footer>{KREDITERING}</footer></body></html>")
    return "\n".join(ut)


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("kilde", help="JSON-fil eller mappe med JSON-filer")
    ap.add_argument("-f", "--format", choices=["md", "html"], default="md")
    ap.add_argument("-o", "--ut", help="utfil, eller utmappe når kilden er en mappe")
    a = ap.parse_args(argv)
    lag = til_markdown if a.format == "md" else til_html
    kilde = pathlib.Path(a.kilde)
    if kilde.is_dir():
        if not a.ut:
            ap.error("--ut må oppgis når kilden er en mappe")
        ut = pathlib.Path(a.ut)
        filer = sorted(f for f in kilde.rglob("*.json") if f.name != "index.json")
        for f in filer:
            mål = ut / f.relative_to(kilde).with_suffix("." + a.format)
            mål.parent.mkdir(parents=True, exist_ok=True)
            mål.write_text(lag(json.loads(f.read_text("utf-8"))), encoding="utf-8")
        print(f"Skrev {len(filer)} filer til {ut}", file=sys.stderr)
    else:
        tekst = lag(json.loads(kilde.read_text("utf-8")))
        if a.ut:
            pathlib.Path(a.ut).write_text(tekst, encoding="utf-8")
        else:
            sys.stdout.reconfigure(encoding="utf-8")
            print(tekst)
    return 0


if __name__ == "__main__":
    sys.exit(main())

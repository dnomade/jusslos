"""Bygger nettsiden jusslos.no fra dataene i repoet.

Leser manifest.json, indeks.json, endringer/ og dokumentene i data/, fyller inn
nettside/mal.html og skriver den ferdige siden med statiske filer til _site/.
Bare standardbiblioteket, så den kjører i Cloudflares byggemiljø uten pip.

Bruk:
  python verktoy/bygg_nettside.py                 bygg til _site/
  python verktoy/bygg_nettside.py --rot DIR --ut DIR
"""
from __future__ import annotations

import argparse
import datetime as dt
import html
import json
import pathlib
import re
import shutil
import statistics
import string

GITHUB = "https://github.com/dnomade/jusslos"

# Mappe, type i manifestet og forklaring, i den rekkefølgen tabellen viser dem.
TYPER = [
    ("lover", "lov", "Gjeldende lover"),
    ("forskrifter", "forskrift", "Gjeldende sentrale forskrifter"),
    ("delegeringer", "delegering",
     "Vedtak der Kongen eller et departement gir fra seg myndighet, f.eks. etter barnevernloven"),
    ("instrukser", "instruks", "Interne regler for forvaltningen, f.eks. politiinstruksen"),
    ("stortingsvedtak", "stortingsvedtak",
     "Regler Stortinget har vedtatt selv, f.eks. bevilgningsreglementet"),
]

EKSEMPEL_ID = "lov/2005-06-17-62"
EKSEMPEL_PARAGRAF = "§ 1-1"
EKSEMPEL_NAVN = "Arbeidsmiljøloven"

STATISKE = ["stil.css", "favicon.svg", "404.html", "_headers", "robots.txt", "fonter"]
ADRESSE = "https://jusslos.no/"

UKEDAGER = ["mandag", "tirsdag", "onsdag", "torsdag", "fredag", "lørdag", "søndag"]
MANEDER = ["januar", "februar", "mars", "april", "mai", "juni", "juli", "august",
           "september", "oktober", "november", "desember"]

LOGG_DAGER = 30
MAKS_PER_DAG = 25


def tall(n: int) -> str:
    """5905 -> '5 905' med hardt mellomrom, slik norsk skriver tall."""
    return f"{n:,}".replace(",", " ")


def dato_lang(d: dt.date) -> str:
    return f"{UKEDAGER[d.weekday()]} {d.day}. {MANEDER[d.month - 1]} {d.year}"


def dato_kort(d: dt.date) -> str:
    return d.strftime("%d.%m.%Y")


def les_json(sti: pathlib.Path):
    with open(sti, encoding="utf-8") as f:
        return json.load(f)


def vedtaksaar(dok_id: str) -> int | None:
    m = re.search(r"(\d{4})-\d{2}-\d{2}", dok_id)
    return int(m.group(1)) if m else None


def finn_paragraf(blokker, nummer):
    for b in blokker:
        if b.get("type") == "paragraf" and b.get("nummer") == nummer:
            return b
        under = b.get("innhold")
        if isinstance(under, list):
            funnet = finn_paragraf(under, nummer)
            if funnet:
                return funnet
    return None


def tell_paragrafer(blokker) -> int:
    n = 0
    for b in blokker:
        if b.get("type") == "paragraf":
            n += 1
        under = b.get("innhold")
        if isinstance(under, list):
            n += tell_paragrafer(under)
    return n


def forkort(tekst: str, maks: int) -> str:
    """Kutter ved siste hele ord før maks tegn."""
    if len(tekst) <= maks:
        return tekst
    kutt = tekst[:maks]
    if " " in kutt:
        kutt = kutt[: kutt.rindex(" ")]
    return kutt.rstrip(" ,;:(") + " …"


def lag_eksempel(rot: pathlib.Path, indeks: dict) -> dict:
    """Viser første del av en ekte paragraf, både som lovtekst og som JSON."""
    info = indeks["dokumenter"].get(EKSEMPEL_ID)
    if not info:
        raise SystemExit(f"Fant ikke eksempeldokumentet {EKSEMPEL_ID} i indeks.json")
    dok = les_json(rot / info["fil"])
    p = finn_paragraf(dok.get("innhold", []), EKSEMPEL_PARAGRAF)
    if not p:
        raise SystemExit(f"Fant ikke {EKSEMPEL_PARAGRAF} i {EKSEMPEL_ID}")

    linjer = p["ledd"][0].split("\n")
    vis = linjer[:4]
    tekst = [f'<div style="font-weight: 600">{html.escape(p["nummer"])}. {html.escape(p.get("tittel") or "")}</div>']
    for i, linje in enumerate(vis):
        klasse = ' class="punkt"' if i else ""
        tekst.append(f'<p{klasse}>{html.escape(forkort(linje, 110))}</p>')
    if len(linjer) > len(vis):
        forste = linjer[len(vis)].split(".")[0]
        siste = linjer[-1].split(".")[0]
        rest = f"{forste}. til {siste}. …" if forste != siste else f"{forste}. …"
        tekst.append(f'<p class="punkt rest">{html.escape(rest)}</p>')

    utdrag = {
        "type": p["type"],
        "id": p.get("id"),
        "nummer": p["nummer"],
        "tittel": p.get("tittel"),
        "ledd": [forkort(p["ledd"][0], 45)],
    }
    if p.get("endringer"):
        utdrag["endringer"] = [forkort(p["endringer"][0], 38)]
    utdrag = {k: v for k, v in utdrag.items() if v is not None}
    som_json = json.dumps(utdrag, ensure_ascii=False, indent=2)
    # Korte lister på én linje leses lettere i et smalt felt.
    som_json = re.sub(r'\[\n\s+("(?:[^"\\]|\\.)*")\n\s+\]', r"[\n    \1\n  ]", som_json)

    return {
        "eksempel_navn": html.escape(EKSEMPEL_NAVN),
        "eksempel_nummer": html.escape(p["nummer"]),
        "eksempel_fil": html.escape(info["fil"]),
        "eksempel_tekst": "\n".join("          " + t for t in tekst),
        "eksempel_json": html.escape(som_json),
    }


def lag_tabell(manifest: dict) -> str:
    rader = []
    antall = manifest.get("antall", {})
    for mappe, typ, forklaring in TYPER:
        rader.append(
            "          <tr>"
            f'<td class="mappe"><a href="{GITHUB}/tree/main/data/{mappe}">{mappe}/</a></td>'
            f'<td class="tall">{tall(antall.get(typ, 0))}</td>'
            f'<td class="beskrivelse">{html.escape(forklaring)}</td>'
            "</tr>"
        )
    return "\n".join(rader)


def lag_fakta(rot: pathlib.Path, indeks: dict) -> str:
    aar = []
    paragrafer = 0
    bytes_ = 0
    for info in indeks["dokumenter"].values():
        sti = rot / info["fil"]
        bytes_ += sti.stat().st_size
        paragrafer += tell_paragrafer(les_json(sti).get("innhold", []))
    for dok_id in indeks["dokumenter"]:
        a = vedtaksaar(dok_id)
        if a:
            aar.append(a)
    deler = []
    if aar:
        median = int(statistics.median_low(aar))
        deler.append(f"Eldste dokument er fra {min(aar)}. Halvparten er vedtatt i {median} eller senere.")
    mb = bytes_ / 1_000_000
    deler.append(f"Til sammen {tall(paragrafer)} paragrafer og {tall(round(mb))} MB JSON.")
    return " ".join(deler)


def les_endringer(rot: pathlib.Path) -> list[tuple[dt.date, dict]]:
    filer = []
    for sti in sorted((rot / "endringer").glob("*.json")):
        try:
            d = dt.date.fromisoformat(sti.stem)
        except ValueError:
            continue
        filer.append((d, les_json(sti)))
    return filer


def lenke_til(dok_id: str, indeks: dict) -> str:
    info = indeks["dokumenter"].get(dok_id)
    if not info:
        return f"<code>{html.escape(dok_id)}</code>"
    navn = info.get("korttittel") or info.get("tittel") or dok_id
    return f'<a href="{GITHUB}/blob/main/{html.escape(info["fil"])}">{html.escape(navn)}</a>'


def lag_logg(endringer, indeks: dict) -> str:
    if not endringer:
        return '        <li><span class="dato"></span><span class="hva">Ingen endringer registrert ennå.</span></li>'
    siste = endringer[-1][0]
    grense = siste - dt.timedelta(days=LOGG_DAGER)
    linjer = []
    for d, e in reversed(endringer):
        if d < grense:
            break
        nye, endret, fjernet = e.get("nye", []), e.get("endret", []), e.get("fjernet", [])
        if e.get("forrige_dataversjon") is None:
            hva = f"Første innlesing: {tall(len(nye))} dokumenter lagt til"
        else:
            punkter = []
            for art, ider in (("Endret", endret), ("Ny", nye), ("Fjernet", fjernet)):
                for dok_id in ider:
                    lenke = lenke_til(dok_id, indeks) if art != "Fjernet" else f"<code>{html.escape(dok_id)}</code>"
                    punkter.append(f'<li><span class="art">{art}:</span> {lenke}</li>')
            if not punkter:
                continue
            vist = punkter[:MAKS_PER_DAG]
            if len(punkter) > MAKS_PER_DAG:
                vist.append(f'<li class="art">og {tall(len(punkter) - MAKS_PER_DAG)} til</li>')
            hva = "<ul>" + "".join(vist) + "</ul>"
        linjer.append(
            f'        <li><span class="dato">{dato_kort(d)}</span><span class="hva">{hva}</span></li>'
        )
    return "\n".join(linjer)


def lag_status(manifest: dict, endringer) -> str:
    total = sum(manifest.get("antall", {}).values())
    if not endringer:
        return f"{tall(total)} dokumenter."
    d, e = endringer[-1]
    if e.get("forrige_dataversjon") is None:
        hva = "første innlesing"
    else:
        hva = (f"{tall(len(e.get('endret', [])))} endret, {tall(len(e.get('nye', [])))} nye, "
               f"{tall(len(e.get('fjernet', [])))} fjernet")
    return f"{tall(total)} dokumenter. Data sist endret {dato_lang(d)}: {hva}."


def lag_sitemap(manifest: dict) -> str:
    """Én adresse, med datoen dataene sist ble endret."""
    endret = (manifest.get("oppdatert") or "")[:10]
    lastmod = f"<lastmod>{html.escape(endret)}</lastmod>" if endret else ""
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
            f"  <url><loc>{ADRESSE}</loc>{lastmod}</url>\n"
            "</urlset>\n")


def lag_llms(manifest: dict, endringer) -> str:
    """llms.txt etter forslaget på llmstxt.org: kort beskrivelse og lenker til rådata."""
    raw = "https://raw.githubusercontent.com/dnomade/jusslos/main"
    antall = manifest.get("antall", {})
    total = sum(antall.values())
    linjer = [
        "# jusslos",
        "",
        f"> Alle gjeldende norske lover og sentrale forskrifter ({total} dokumenter) som JSON, "
        "en fil per dokument, hentet fra Lovdatas åpne datasett hver natt. "
        "Data under NLOD 2.0, tilgjengeliggjort av Lovdata. Ikke offisiell kunngjøring; "
        "ved tvil gjelder teksten på lovdata.no.",
        "",
        f"Dataversjon: {manifest.get('dataversjon', '')}",
    ]
    if endringer:
        linjer.append(f"Data sist endret: {endringer[-1][0].isoformat()}")
    linjer += [
        "",
        "Hvert dokument ligger i data/<mappe>/<vedtaksår>/<fil>.json. Finn filstien i index.json for mappen "
        "eller i indeks.json. Dokumentene har feltene tittel, korttittel, departement, ikraft, url (til Lovdata) "
        "og innhold, der innhold er en liste av blokker: seksjon (kapittel, del), paragraf (nummer, tittel, ledd) "
        "og tekst. Arbeidsmiljøloven er for eksempel data/lover/2005/lov-2005-06-17-62.json.",
        "",
        "## Merknader for KI-assistenter",
        "",
        "- Datasettet viser lovteksten slik den gjelder ifølge Lovdata på datoen over, og kan være opptil et døgn gammelt. "
        "Endringer som er vedtatt, men ikke trådt i kraft, er ikke nødvendigvis med. Sjekk feltene ikraft, "
        "siste_endring_ikraft og sist_endret_ved, og endringer på hver paragraf, når tidspunktet betyr noe.",
        "- Opphevede lover og forskrifter er fjernet fra datasettet. At et dokument mangler her, betyr at det ikke "
        "er gjeldende, eller at det ikke er en sentral forskrift (lokale forskrifter er ikke med).",
        "- Henvis til den offisielle teksten hos Lovdata. Hvert dokument har feltet url, for eksempel "
        "https://lovdata.no/dokument/NL/lov/2005-06-17-62. Oppgi paragrafnummeret (feltet nummer).",
        "- Datasettet er lovtekst, ikke tolkning. Forarbeider, rettspraksis, rundskriv og juridisk teori er ikke med, "
        "så svar om hvordan en regel forstås, må bygge på flere kilder enn dette.",
        "",
        "## Oversikter",
        "",
        f"- [manifest.json]({raw}/manifest.json): dataversjon, antall per type og kilde",
        f"- [indeks.json]({raw}/indeks.json): alle dokumenter med id, tittel, filsti og sha256",
    ]
    for mappe, typ, forklaring in TYPER:
        linjer.append(f"- [{mappe}/index.json]({raw}/data/{mappe}/index.json): "
                      f"{forklaring} ({antall.get(typ, 0)} dokumenter)")
    linjer += [
        "",
        "## Format",
        "",
        f"- [dokument.schema.json]({raw}/schema/dokument.schema.json): JSON-skjema for dokumentene",
        f"- [README.md]({raw}/README.md): beskrivelse av repoet og hvordan endringer oppdages",
        "",
        "## Valgfritt",
        "",
        f"- [endringer/]({GITHUB}/tree/main/endringer): hvilke dokumenter som ble nye, endret eller fjernet per dag",
        f"- [Kildekode]({GITHUB}): henting, parsing og denne nettsiden",
        "",
    ]
    return "\n".join(linjer)


def bygg(rot: pathlib.Path, ut: pathlib.Path) -> None:
    kilde = rot / "nettside"
    manifest = les_json(rot / "manifest.json")
    indeks = les_json(rot / "indeks.json")
    endringer = les_endringer(rot)

    verdier = {
        "status": html.escape(lag_status(manifest, endringer)),
        "tabellrader": lag_tabell(manifest),
        "fakta": html.escape(lag_fakta(rot, indeks)),
        "endringslogg": lag_logg(endringer, indeks),
        "dataversjon": html.escape(manifest.get("dataversjon", "")),
        **lag_eksempel(rot, indeks),
    }
    mal = string.Template((kilde / "mal.html").read_text(encoding="utf-8"))
    side = mal.substitute(verdier)

    if ut.exists():
        shutil.rmtree(ut)
    ut.mkdir(parents=True)
    (ut / "index.html").write_text(side, encoding="utf-8")
    for navn in STATISKE:
        src = kilde / navn
        if src.is_dir():
            shutil.copytree(src, ut / navn)
        elif src.exists():
            shutil.copy2(src, ut / navn)
    (ut / "sitemap.xml").write_text(lag_sitemap(manifest), encoding="utf-8")
    (ut / "llms.txt").write_text(lag_llms(manifest, endringer), encoding="utf-8")
    print(f"Bygget {ut / 'index.html'} ({len(side):,} tegn)")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--rot", type=pathlib.Path, default=pathlib.Path(__file__).resolve().parent.parent)
    ap.add_argument("--ut", type=pathlib.Path, default=None)
    a = ap.parse_args()
    bygg(a.rot, a.ut or a.rot / "_site")


if __name__ == "__main__":
    main()

"""Gjør om et Lovdata-dokument (HTML) til en JSON-struktur.

Strukturen i Lovdatas filer:
  header.documentHeader > dl.data-document-key-info   metadata (dt/dd med klasse)
  main.documentBody                                   selve teksten
    section[data-name]                                del, kapittel, avsnitt
      article.legalArticle[data-name]                 paragraf
        h2-h6.legalArticleHeader                      "§ 1. Tittel"
        article.legalP / numberedLegalP               ledd
        article.changesToParent                       "Endret ved lov ..."
  footer.footnotes > article.footnote                 fotnoter
"""
from __future__ import annotations

import re
from lxml import html as lhtml

SKJEMAVERSJON = "1.0"

# Undermappe i Lovdatas pakker -> dokumenttype
TYPER = {
    "nl": "lov",
    "sf": "forskrift",
    "del": "delegering",
    "ins": "instruks",
    "stv": "stortingsvedtak",
}

# dt/dd-klasse -> feltnavn i JSON
TEKSTFELT = {
    "legacyID": "datokode",
    "dokid": "dokumentid",
    "refid": "refid",
    "eli": "eli",
    "title": "tittel",
    "titleShort": "korttittel",
    "dateInForce": "ikraft",
    "dateOfPublication": "kunngjort",
    "lastChangeInForce": "siste_endring_ikraft",
    "lastupdated": "siste_rettelse",
    "appliesTo": "gjelder_for",
    "publishedIn": "kunngjort_i",
    "miscInformation": "annet",
    "eeaReferences": "eos_henvisning",
    "changesToDocuments": "endrer",
}
LISTEFELT = {
    "ministry": "departement",
    "subunit": "etat",
    "legalArea": "rettsomrade",
}
LENKEFELT = {
    "basedOn": "hjemmel",
    "lastChangedBy": "sist_endret_ved",
}

BLOKK = {"p", "div", "li", "tr", "article", "section", "h1", "h2", "h3",
         "h4", "h5", "h6", "table", "ol", "ul", "dl", "dd", "dt", "caption"}
LEDD = {"legalP", "numberedLegalP", "defaultP", "centeredP", "marginIdArticle"}
PARAGRAF = {"legalArticle", "futureLegalArticle"}
OVERSKRIFT = {"h1", "h2", "h3", "h4", "h5", "h6"}


def klasser(el) -> set[str]:
    return set((el.get("class") or "").split())


def rens(tekst: str) -> str:
    tekst = re.sub(r"\x00\s*", " ", tekst)  # listemerke + innhold på samme linje
    linjer = [re.sub(r"[ \t ]+", " ", l).strip() for l in tekst.split("\n")]
    return "\n".join(l for l in linjer if l)


def tekst(el, hopp_over: set[str] = frozenset({"changesToParent"})) -> str:
    """Ren tekst med linjeskift for blokker, listepunkter og tabellrader."""
    deler: list[str] = []

    def gå(e):
        if not isinstance(e.tag, str):
            if e.tail:
                deler.append(e.tail)
            return
        k = klasser(e)
        if k & hopp_over:
            if e.tail:
                deler.append(e.tail)
            return
        tag = e.tag.lower()
        if tag == "li" and e.get("data-name"):
            deler.append("\n" + e.get("data-name") + "\x00")
        if tag == "br":
            deler.append("\n")
        elif tag in BLOKK:
            deler.append("\n")
        elif tag in ("td", "th"):
            deler.append(" | ")
        if tag == "sup" and "footnotereference" in k:
            deler.append("[" + (e.text_content() or "").strip() + "]")
        else:
            if e.text:
                deler.append(e.text)
            for barn in e:
                gå(barn)
        if tag in BLOKK:
            deler.append("\n")
        if e.tail:
            deler.append(e.tail)

    if el.text:
        deler.append(el.text)
    for barn in el:
        gå(barn)
    return rens("".join(deler))


def lenker(dd) -> list[dict]:
    ut = []
    for a in dd.iter("a"):
        ut.append({"ref": a.get("href", ""), "tekst": rens(a.text_content() + (a.tail or ""))})
    if not ut and rens(dd.text_content()):
        ut.append({"ref": None, "tekst": rens(dd.text_content())})
    return ut


def les_metadata(dl) -> dict:
    meta: dict = {}
    for dd in dl.findall("dd"):
        k = (dd.get("class") or "").strip()
        if k in TEKSTFELT:
            meta[TEKSTFELT[k]] = tekst(dd)
        elif k in LISTEFELT:
            punkter = [rens(li.text_content()) for li in dd.findall("./ul/li")]
            meta[LISTEFELT[k]] = punkter or [tekst(dd)]
        elif k in LENKEFELT:
            meta[LENKEFELT[k]] = lenker(dd)
    if "rettsomrade" in meta:
        meta["rettsomrade"] = [re.sub(r"\s*>\s*", " > ", r) for r in meta["rettsomrade"]]
    return meta


def overskrift(el):
    for barn in el:
        if isinstance(barn.tag, str) and barn.tag.lower() in OVERSKRIFT:
            return barn
        if isinstance(barn.tag, str) and "legalArticleHeader" in klasser(barn):
            return barn
    return None


def les_paragraf(el) -> dict:
    hode = overskrift(el)
    nummer = tittel = None
    if hode is not None:
        v = hode.find_class("legalArticleValue")
        t = hode.find_class("legalArticleTitle")
        nummer = rens(v[0].text_content()) if v else None
        tittel = rens(t[0].text_content()) if t else None
        if nummer is None:
            nummer = tekst(hode)
    p = {
        "type": "paragraf",
        "id": el.get("id"),
        "nummer": nummer,
        "tittel": tittel or None,
        "ledd": [],
        "endringer": [],
    }
    if "futureLegalArticle" in klasser(el):
        p["fremtidig"] = True
    if el.get("data-repealeddate"):
        p["opphevet"] = el.get("data-repealeddate")
    for barn in el:
        if not isinstance(barn.tag, str) or barn is hode:
            continue
        k = klasser(barn)
        if barn.tag == "footer":
            p["fotnoter"] = fotnoteliste(barn)
        elif "changesToParent" in k:
            p["endringer"].append(tekst(barn, frozenset()))
        elif k & PARAGRAF:
            # Underparagraf (f.eks. i fremtidige versjoner): legg som eget ledd
            p.setdefault("underparagrafer", []).append(les_paragraf(barn))
        else:
            t = tekst(barn)
            if t:
                p["ledd"].append(t)
    if not p["endringer"]:
        del p["endringer"]
    return p


def les_blokker(el) -> list[dict]:
    """Går gjennom en beholder og returnerer seksjoner, paragrafer og tekstblokker."""
    ut: list[dict] = []
    hode = overskrift(el) if el.tag == "section" else None
    løs: list[str] = []

    def tøm():
        t = rens("\n".join(løs))
        if t:
            ut.append({"type": "tekst", "tekst": t})
        løs.clear()

    if el.text and el.text.strip():
        løs.append(el.text)
    for barn in el:
        if not isinstance(barn.tag, str) or barn is hode:
            continue
        tag = barn.tag.lower()
        k = klasser(barn)
        if tag == "h1":
            continue
        if tag == "section":
            tøm()
            h = overskrift(barn)
            ut.append({
                "type": "seksjon",
                "id": barn.get("id"),
                "navn": barn.get("data-name"),
                "overskrift": tekst(h) if h is not None else None,
                "innhold": les_blokker(barn),
            })
        elif k & PARAGRAF:
            tøm()
            ut.append(les_paragraf(barn))
        elif "changesToParent" in k:
            tøm()
            ut.append({"type": "endring", "tekst": tekst(barn, frozenset())})
        elif tag == "footer":
            continue
        else:
            løs.append(tekst(barn))
        if barn.tail and barn.tail.strip():
            løs.append(barn.tail)
    tøm()
    return ut


def fotnoteliste(footer) -> list[dict]:
    ut = []
    for fn in footer.find_class("footnote"):
        etikett = fn.find_class("footnoteLabel")
        nr = rens(etikett[0].text_content()) if etikett else None
        t = tekst(fn, frozenset({"footnoteLabel"}))
        ut.append({"nr": nr, "tekst": t})
    return ut


def les_fotnoter(rot) -> list[dict]:
    """Fotnoter som ikke hører til en paragraf (de ligger på paragrafen selv)."""
    ut = []
    for footer in rot.iter("footer"):
        if not any(PARAGRAF & klasser(a) for a in footer.iterancestors()):
            ut += fotnoteliste(footer)
    return ut


def parse(innhold: bytes | str, mappe: str) -> dict:
    if isinstance(innhold, bytes):
        innhold = innhold.decode("utf-8")
    rot = lhtml.fromstring(innhold)
    dl = rot.find_class("data-document-key-info")
    meta = les_metadata(dl[0]) if dl else {}
    main = rot.find_class("documentBody")
    body = main[0] if main else rot
    dok = {
        "skjema": SKJEMAVERSJON,
        "type": TYPER.get(mappe, mappe),
        **meta,
        "url": "https://lovdata.no/dokument/" + meta.get("dokumentid", ""),
        "innhold": les_blokker(body),
        "fotnoter": les_fotnoter(rot),
    }
    if not dok["fotnoter"]:
        del dok["fotnoter"]
    return dok


def tell_paragrafer(blokker: list[dict]) -> int:
    n = 0
    for b in blokker:
        if b["type"] == "paragraf":
            n += 1
        elif b["type"] == "seksjon":
            n += tell_paragrafer(b["innhold"])
    return n

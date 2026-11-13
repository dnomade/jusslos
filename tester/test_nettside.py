"""Tester byggingen av nettsiden mot et lite, oppdiktet datasett."""
import importlib.util
import json
import pathlib
import shutil

ROT = pathlib.Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("bygg_nettside", ROT / "verktoy" / "bygg_nettside.py")
bygg_nettside = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bygg_nettside)


def skriv(sti, data):
    sti.parent.mkdir(parents=True, exist_ok=True)
    sti.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")


def lag_repo(tmp):
    shutil.copytree(ROT / "nettside", tmp / "nettside")
    aml = "data/lover/2005/lov-2005-06-17-62.json"
    forskrift = "data/forskrifter/2010/forskrift-2010-01-01-1.json"
    skriv(tmp / aml, {"refid": "lov/2005-06-17-62", "innhold": [
        {"type": "seksjon", "innhold": [
            {"type": "paragraf", "id": "k1p1", "nummer": "§ 1-1", "tittel": "Lovens formål",
             "ledd": ["Lovens formål er:\na. en\nb. to\nc. tre\nd. fire\ne. fem"],
             "endringer": ["Endret ved lov 1 jan 2020 nr. 1."]},
            {"type": "paragraf", "nummer": "§ 1-2", "ledd": ["x"]},
        ]}]})
    skriv(tmp / forskrift, {"refid": "forskrift/2010-01-01-1", "innhold": [
        {"type": "paragraf", "nummer": "§ 1", "ledd": ["y"]}]})
    skriv(tmp / "indeks.json", {"dataversjon": "2026-11-14.abcd1234", "dokumenter": {
        "lov/2005-06-17-62": {"fil": aml, "tittel": "Arbeidsmiljøloven", "korttittel": "Aml"},
        "forskrift/2010-01-01-1": {"fil": forskrift, "tittel": "Forskrift om <prøve>"},
    }})
    skriv(tmp / "manifest.json", {"dataversjon": "2026-11-14.abcd1234", "oppdatert": "2026-11-14T03:20:00+00:00",
                                  "antall": {"lov": 1, "forskrift": 1}})
    skriv(tmp / "endringer/2026-11-13.json", {"forrige_dataversjon": None,
                                             "nye": ["lov/2005-06-17-62"], "endret": [], "fjernet": []})
    skriv(tmp / "endringer/2026-11-14.json", {"forrige_dataversjon": "x", "nye": [],
                                             "endret": ["forskrift/2010-01-01-1"], "fjernet": ["lov/1999-01-01-1"]})


def test_bygger_side_med_tall_og_endringer(tmp_path):
    lag_repo(tmp_path)
    ut = tmp_path / "_site"
    bygg_nettside.bygg(tmp_path, ut)
    side = (ut / "index.html").read_text(encoding="utf-8")

    assert "$" not in side.replace("$schema", "")
    assert "2 dokumenter. Data sist endret lørdag 14. november 2026: 1 endret, 0 nye, 1 fjernet." in side
    assert "Til sammen 3 paragrafer" in side
    assert "Eldste dokument er fra 2005" in side
    assert "Forskrift om &lt;prøve&gt;" in side  # titler escapes
    assert "lov/1999-01-01-1" in side
    assert "Første innlesing: 1 dokumenter lagt til" in side
    assert "d. til e. …" in side
    assert "2026-11-14.abcd1234" in side
    sitemap = (ut / "sitemap.xml").read_text(encoding="utf-8")
    assert "<loc>https://jusslos.no/</loc><lastmod>2026-11-14</lastmod>" in sitemap
    llms = (ut / "llms.txt").read_text(encoding="utf-8")
    assert llms.startswith("# jusslos\n\n> ")
    assert "Dataversjon: 2026-11-14.abcd1234" in llms
    assert "## Merknader for KI-assistenter" in llms
    assert "data/lover/index.json): Gjeldende lover (1 dokumenter)" in llms
    for fil in ["stil.css", "favicon.svg", "404.html", "_headers", "robots.txt", "fonter"]:
        assert (ut / fil).exists()


def test_tall_formateres_norsk():
    assert bygg_nettside.tall(5905) == "5 905"
    assert bygg_nettside.forkort("en to tre fire", 9) == "en to …"

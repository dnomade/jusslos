import json
import pathlib
import subprocess
import sys

from jusslos import hent, parser

ROT = pathlib.Path(__file__).resolve().parent.parent
EKS = ROT / "tester" / "eksempler" / "nl-20991231-001.xml"


def test_metadata_og_paragraf():
    d = parser.parse(EKS.read_bytes(), "nl")
    assert d["type"] == "lov"
    assert d["refid"] == "lov/2099-12-31-1"
    assert d["korttittel"] == "Prøveloven"
    assert d["rettsomrade"] == ["EU/EØS-rett > Arbeid"]
    assert d["sist_endret_ved"][0]["tekst"] == "lov/2100-06-01-5 fra 2100-07-01"
    kap = d["innhold"][0]
    assert kap["type"] == "seksjon" and kap["overskrift"].startswith("Kapittel 1")
    p = kap["innhold"][0]
    assert p["nummer"] == "§ 1" and p["tittel"] == "Formål"
    assert p["ledd"] == ["Loven skal sikre prøving[1].", "Loven gjelder for:\na. staten,\nb. kommuner."]
    assert p["endringer"] == ["Endret ved lov 1 juni 2100 nr. 5."]
    assert p["fotnoter"] == [{"nr": "1", "tekst": "Se forskrift."}]
    assert "fotnoter" not in d


def test_full_kjoring_er_idempotent(tmp_path):
    kilde = ROT / "tester"
    assert hent.main(["--kilde", str(kilde), "--rot", str(tmp_path)]) == 0
    manifest = json.loads((tmp_path / "manifest.json").read_text("utf-8"))
    assert manifest["antall"] == {"delegering": 1, "lov": 1}
    før = (tmp_path / "manifest.json").read_bytes()
    assert hent.main(["--kilde", str(kilde), "--rot", str(tmp_path)]) == 0
    assert (tmp_path / "manifest.json").read_bytes() == før, "manifest skal ikke endres uten dataendring"
    assert subprocess.run([sys.executable, "-m", "jusslos.valider", str(tmp_path)], cwd=ROT).returncode == 0
    for fmt in ("md", "html"):
        r = subprocess.run([sys.executable, "verktoy/konverter.py",
                            str(tmp_path / "data/lover/lov-2099-12-31-1.json"), "-f", fmt],
                           cwd=ROT, capture_output=True, text=True, encoding="utf-8")
        assert r.returncode == 0 and "Lovdata" in r.stdout

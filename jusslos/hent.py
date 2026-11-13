"""Henter Lovdatas pakker, parser alle dokumenter og oppdaterer data/, indeks.json,
manifest.json og endringer/. Skriver ingenting hvis ingen dokumenter er endret.

Bruk:
  python -m jusslos.hent                 hent fra Lovdata og oppdater repoet
  python -m jusslos.hent --kilde DIR     bruk allerede nedlastede .tar.bz2-filer i DIR
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import io
import json
import os
import pathlib
import sys
import tarfile
import urllib.request

from . import parser

API = "https://api.lovdata.no/v1/publicData"
PAKKER = ["gjeldende-lover.tar.bz2", "gjeldende-sentrale-forskrifter.tar.bz2"]
MAPPER = {
    "lov": "lover",
    "forskrift": "forskrifter",
    "delegering": "delegeringer",
    "instruks": "instrukser",
    "stortingsvedtak": "stortingsvedtak",
}
LISENS = "NLOD 2.0. Inneholder data under Norsk lisens for offentlige data (NLOD) tilgjengeliggjort av Lovdata."
ROT = pathlib.Path(__file__).resolve().parent.parent


def hent_url(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": "jusslos (+https://github.com/dnomade/jusslos)"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def kanonisk(obj) -> bytes:
    return json.dumps(obj, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def filnavn(dok: dict) -> str:
    ref = dok.get("refid") or dok.get("dokumentid")
    return ref.lower().replace("/", "-").replace("§", "p") + ".json"


def les_json(sti: pathlib.Path, standard):
    try:
        return json.loads(sti.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return standard


def skriv_json(sti: pathlib.Path, obj, kompakt=False):
    sti.parent.mkdir(parents=True, exist_ok=True)
    if kompakt:
        tekst = json.dumps(obj, ensure_ascii=False, separators=(",", ":"))
    else:
        tekst = json.dumps(obj, ensure_ascii=False, indent=1)
    sti.write_text(tekst + "\n", encoding="utf-8")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--kilde", help="mappe med nedlastede .tar.bz2-filer")
    ap.add_argument("--rot", default=str(ROT), help="repoets rotmappe")
    a = ap.parse_args(argv)
    rot = pathlib.Path(a.rot)

    # 1. Pakkeliste og nedlasting
    if a.kilde:
        liste = []
    else:
        liste = json.loads(hent_url(API + "/list"))
    info = {p["filename"]: p for p in liste}

    pakker = {}
    nye: dict[str, dict] = {}   # id -> {fil, dok, sha}
    for navn in PAKKER:
        data = (pathlib.Path(a.kilde) / navn).read_bytes() if a.kilde else hent_url(f"{API}/get/{navn}")
        pakker[navn] = {
            "sist_endret": info.get(navn, {}).get("lastModified"),
            "storrelse": len(data),
            "sha256": sha(data),
        }
        with tarfile.open(fileobj=io.BytesIO(data), mode="r:bz2") as tar:
            for m in tar:
                if not m.isfile() or not m.name.endswith(".xml"):
                    continue
                mappe = pathlib.PurePosixPath(m.name).parent.name
                dok = parser.parse(tar.extractfile(m).read(), mappe)
                id_ = dok.get("refid") or dok.get("dokumentid")
                if dok.get("dokumentid", "").split("/")[0] not in ("NL", "SF"):
                    id_ = dok["dokumentid"]  # DEL/INS/STV deler ofte refid med SF
                if m.name.endswith("-nn.xml"):
                    id_ += "-nn"  # nynorsk utgave (f.eks. Grunnloven)
                    dok["sprak"] = "nn"
                sti = f"data/{MAPPER.get(dok['type'], dok['type'])}/{filnavn({'refid': id_})}"
                if id_ in nye:
                    print(f"ADVARSEL: dobbel id {id_} ({m.name})", file=sys.stderr)
                nye[id_] = {"fil": sti, "dok": dok, "sha": sha(kanonisk(dok))}

    # 2. Sammenlign med forrige indeks
    gammel = les_json(rot / "indeks.json", {"dokumenter": {}})["dokumenter"]
    lagt_til = sorted(set(nye) - set(gammel))
    fjernet = sorted(set(gammel) - set(nye))
    endret = sorted(i for i in set(nye) & set(gammel) if nye[i]["sha"] != gammel[i]["sha256"])

    if not (lagt_til or fjernet or endret):
        print(f"Ingen endringer ({len(nye)} dokumenter).")
        _sett_utdata(endret=False)
        return 0

    idag = dt.datetime.now(dt.timezone.utc).date().isoformat()
    helhet = sha("".join(f"{i}:{nye[i]['sha']}\n" for i in sorted(nye)).encode())
    versjon = f"{idag}.{helhet[:8]}"

    # 3. Skriv dokumenter som er nye eller endret, slett fjernede
    for i in lagt_til + endret:
        skriv_json(rot / nye[i]["fil"], nye[i]["dok"])
    for i in fjernet:
        (rot / gammel[i]["fil"]).unlink(missing_ok=True)

    indeks = {"dataversjon": versjon, "dokumenter": {}}
    for i in sorted(nye):
        d = nye[i]["dok"]
        indeks["dokumenter"][i] = {
            "fil": nye[i]["fil"],
            "type": d["type"],
            "tittel": d.get("tittel"),
            "korttittel": d.get("korttittel"),
            "sha256": nye[i]["sha"],
            "endret": idag if i in lagt_til or i in endret else gammel[i]["endret"],
        }
    skriv_json(rot / "indeks.json", indeks, kompakt=False)

    forrige = les_json(rot / "manifest.json", {}).get("dataversjon")
    antall: dict[str, int] = {}
    for v in nye.values():
        antall[v["dok"]["type"]] = antall.get(v["dok"]["type"], 0) + 1
    manifest = {
        "skjema": parser.SKJEMAVERSJON,
        "dataversjon": versjon,
        "forrige_dataversjon": forrige,
        "oppdatert": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat(),
        "antall": dict(sorted(antall.items())),
        "endringer": {"nye": len(lagt_til), "endret": len(endret), "fjernet": len(fjernet),
                      "fil": f"endringer/{idag}.json"},
        "kilde": {"utgiver": "Lovdata", "api": API, "pakker": pakker},
        "lisens": LISENS,
    }
    skriv_json(rot / "manifest.json", manifest)

    endringsfil = rot / "endringer" / f"{idag}.json"
    tidligere = les_json(endringsfil, None)
    logg = {"dataversjon": versjon, "forrige_dataversjon": forrige,
            "nye": lagt_til, "endret": endret, "fjernet": fjernet}
    if tidligere:  # flere kjøringer samme dag: slå sammen
        logg["forrige_dataversjon"] = tidligere["forrige_dataversjon"]
        for k in ("nye", "endret", "fjernet"):
            logg[k] = sorted(set(tidligere[k]) | set(logg[k]))
    skriv_json(endringsfil, logg)

    print(f"Dataversjon {versjon}: {len(lagt_til)} nye, {len(endret)} endret, {len(fjernet)} fjernet.")
    _sett_utdata(endret=True, versjon=versjon,
                 melding=f"Data {versjon}: {len(lagt_til)} nye, {len(endret)} endret, {len(fjernet)} fjernet")
    return 0


def _sett_utdata(**kv):
    f = os.environ.get("GITHUB_OUTPUT")
    if f:
        with open(f, "a", encoding="utf-8") as ut:
            for k, v in kv.items():
                ut.write(f"{k}={str(v).lower() if isinstance(v, bool) else v}\n")


if __name__ == "__main__":
    sys.exit(main())

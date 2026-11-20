"""Lager tester/testdata.sql: skjemaet og noen få dokumenter fra en lokal kopi av D1-databasen «jusslos».

Testene i tester/ laster filen inn i node:sqlite, så de trenger ikke Cloudflare. Kjøres for hånd når skjemaet
endres (migreringene ligger i dnomade/lovfinner, api/migrations/):

  python3 -I tester/lag_testdata.py <sti til .sqlite-filen> tester/testdata.sql
"""
import sqlite3
import sys

DOKUMENTER = [
    "lov/2005-06-17-62",         # arbeidsmiljøloven
    "lov/1999-03-26-17",         # husleieloven
    "lov/1965-06-18-4",          # vegtrafikkloven
    "forskrift/2016-03-18-260",  # parkeringsforskriften (hjemmel i vegtrafikkloven)
]
TABELLER = ["meta", "dokumenter", "seksjoner", "paragrafer", "hjemmel"]
KOLONNE = {"dokumenter": "id", "seksjoner": "dokument_id", "paragrafer": "dokument_id", "hjemmel": "dokument_id"}


def verdi(v):
    if v is None:
        return "NULL"
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"


def main():
    kilde, mal = sys.argv[1], sys.argv[2]
    c = sqlite3.connect(kilde)
    ut = ["-- Laget av tester/lag_testdata.py. Ikke rediger for hånd."]
    for (sql,) in c.execute(
        "SELECT sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '%_sok_%' "
        "AND name NOT LIKE '_cf_%' AND name NOT LIKE 'd1_%' AND tbl_name NOT IN ('forbruk', 'oppslag') ORDER BY rowid"
    ):
        ut.append(sql + ";")
    plass = ", ".join("?" for _ in DOKUMENTER)
    for t in TABELLER:
        if t == "meta":
            rader = c.execute("SELECT * FROM meta WHERE nokkel = 'dataversjon'")
        else:
            rader = c.execute(f"SELECT * FROM {t} WHERE {KOLONNE[t]} IN ({plass}) ORDER BY rowid", DOKUMENTER)
        kolonner = [d[0] for d in rader.description]
        for r in rader:
            ut.append(f"INSERT INTO {t} ({', '.join(kolonner)}) VALUES ({', '.join(verdi(v) for v in r)});")
    open(mal, "w", encoding="utf-8").write("\n".join(ut) + "\n")


if __name__ == "__main__":
    main()

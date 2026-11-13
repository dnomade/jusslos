# jusslos

Norske lover og sentrale forskrifter som maskinlesbar JSON, oppdatert hver natt fra Lovdatas frie datasett.

## Hva repoet inneholder

| Mappe/fil | Innhold |
|---|---|
| `data/lover/ÅÅÅÅ/` | Gjeldende lover, en JSON-fil per lov |
| `data/forskrifter/ÅÅÅÅ/` | Gjeldende sentrale forskrifter |
| `data/delegeringer/ÅÅÅÅ/`, `data/instrukser/ÅÅÅÅ/`, `data/stortingsvedtak/ÅÅÅÅ/` | Øvrige dokumenter i Lovdatas forskriftspakke |
| `data/<mappe>/index.json` | Oversikt over alle dokumentene i mappen: tittel, korttittel, id, filsti (f.eks. `2005/lov-2005-06-17-62.json`), `sist_endret` (siste endring i kraft ifølge Lovdata) og `endret_i_repo` (dato filen sist endret seg her) |
| `manifest.json` | Dataversjon, antall dokumenter og kilde. Endres bare når data faktisk endres |
| `indeks.json` | Alle dokumenter med fil, tittel, sha256 og dato for siste endring |
| `endringer/ÅÅÅÅ-MM-DD.json` | Hvilke dokumenter som ble nye, endret eller fjernet den dagen |
| `schema/` | JSON-skjema for dokumentene og manifestet |
| `verktoy/konverter.py` | Gjør JSON om til Markdown eller HTML |

`ÅÅÅÅ` er årstallet i dokumentets id, altså året loven eller forskriften ble vedtatt. Arbeidsmiljøloven (`lov/2005-06-17-62`) ligger derfor i `data/lover/2005/lov-2005-06-17-62.json`. Inndelingen holder hver mappe under GitHubs visningsgrense på 1 000 filer, så `index.json` alltid vises.

## Slik oppdager du endringer

1. Hent `manifest.json` (for eksempel fra `https://raw.githubusercontent.com/dnomade/jusslos/main/manifest.json`).
2. Sammenlign `dataversjon` med den du har lagret. Er den lik, er ingenting endret.
3. Er den ulik, les `endringer.fil` i manifestet, eller sammenlign `sha256` per dokument i `indeks.json` med det du har, og hent bare filene som har endret seg.

`dataversjon` har formen `ÅÅÅÅ-MM-DD.<8 tegn hash av hele datasettet>`. Hashen beregnes av innholdet, så samme data gir alltid samme versjon. Det blir bare en commit når minst ett dokument er endret.

## Dokumentformat

Hvert dokument følger `schema/dokument.schema.json`. Forkortet eksempel:

```json
{
  "skjema": "1.0",
  "type": "lov",
  "refid": "lov/2005-06-17-62",
  "dokumentid": "NL/lov/2005-06-17-62",
  "tittel": "Lov om arbeidsmiljø, arbeidstid og stillingsvern mv. (arbeidsmiljøloven)",
  "korttittel": "Arbeidsmiljøloven – aml",
  "departement": ["Arbeids- og inkluderingsdepartementet"],
  "ikraft": "2006-01-01",
  "sist_endret_ved": [{"ref": "lov/...", "tekst": "lov/... fra ..."}],
  "url": "https://lovdata.no/dokument/NL/lov/2005-06-17-62",
  "innhold": [
    {"type": "seksjon", "overskrift": "Kapittel 1. Innledende bestemmelser", "innhold": [
      {"type": "paragraf", "nummer": "§ 1-1", "tittel": "Lovens formål",
       "ledd": ["Lovens formål er:\na) å sikre et arbeidsmiljø ..."],
       "endringer": ["Endret ved lov ..."]}
    ]}
  ]
}
```

Blokktypene i `innhold` er `seksjon` (del, kapittel, avsnitt), `paragraf`, `tekst` og `endring`. Hvert ledd er en streng, og listepunkter er skilt med linjeskift.

## Markdown og HTML

```
python verktoy/konverter.py data/lover/2005/lov-2005-06-17-62.json > aml.md
python verktoy/konverter.py data/lover/2005/lov-2005-06-17-62.json -f html -o aml.html
python verktoy/konverter.py data/lover -f md -o ut/
```

Verktøyet trenger bare Python 3.9 eller nyere, ingen pakker.

## Slik fungerer oppdateringen

GitHub Actions (`.github/workflows/oppdater-data.yml`) kjører hver natt kl. 03.15 UTC, etter at Lovdata har bygget pakkene sine rundt kl. 02.30 UTC. Jobben laster ned `gjeldende-lover.tar.bz2` og `gjeldende-sentrale-forskrifter.tar.bz2` fra `https://api.lovdata.no/v1/publicData`, parser alle dokumentene, sammenligner hashene med `indeks.json` og committer bare ved endring. Repoet har ingen hemmeligheter.

Kjør lokalt:

```
pip install -r requirements.txt
python -m jusslos.hent
python -m jusslos.valider
python -m pytest tester
```

## Nettsiden jusslos.no

Nettsiden ligger i `nettside/`. `verktoy/bygg_nettside.py` leser `manifest.json`, `indeks.json`, `endringer/` og dokumentene, fyller inn `nettside/mal.html` og skriver den ferdige siden til `_site/` (ikke i git). Cloudflare Workers bygger og publiserer siden ved hver push til main, også etter nattjobben, så tallene alltid følger dataene. Oppsettet står i `wrangler.jsonc`.

Bygg og se siden lokalt:

```
python verktoy/bygg_nettside.py
python -m http.server -d _site
```

Skriftene (Source Serif 4 og IBM Plex) ligger i `nettside/fonter/` under SIL Open Font License, så siden henter ingenting fra andre nettsteder.

## Lisens og kreditering

Koden er lisensiert under MIT, se `LICENSE`.

Dataene er hentet fra [Lovdata](https://lovdata.no) og tilgjengeliggjort under [Norsk lisens for offentlige data (NLOD 2.0)](https://data.norge.no/nlod/no/2.0). Den som bruker dataene videre, må kreditere Lovdata. Dette repoet er ikke tilknyttet Lovdata, og den offisielle teksten finnes på lovdata.no.

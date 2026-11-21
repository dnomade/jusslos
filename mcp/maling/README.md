# Måling av søket i MCP-serveren

`testsett.json` har de 60 standardspørsmålene fra lovfinner med fasit (lov og paragraf), og for hvert spørsmål
søkeord slik en KI-assistent typisk ville søkt. Søkeordene er skrevet for hånd 21.11.2026 av den som kjente fasiten,
så tallene for søkeord er trolig noe for gode. Tallene for hele spørsmålet er mer nøytrale.

Kjør mot en lokal kopi av D1-databasen «jusslos» (fylles med `synk/synk.py --local --database jusslos` i lovfinner):

    node --experimental-strip-types maling/mal.ts <sti til .sqlite> [lovlinjer.json]

Målene er om riktig lov og riktig paragraf er blant de 10 første paragraftreffene, og om riktig lov er blant de
5 første i lovlista som `sok` viser øverst.

## 21.11.2026: lover foran forskrifter, lovliste, uten endringsdokumenter

Utløser: søket på «angrerett fjernsalg» ga forsikringsavtaleloven og finansavtaleloven, ikke angrerettloven.
Data: dataversjon 2026-11-20.2e2e37d7.

| Oppsett | Søkeord: lov topp 10 | Søkeord: paragraf topp 10 | Søkeord: lovliste topp 5 | Hele spørsmålet: lov topp 10 | Hele spørsmålet: lovliste topp 5 |
|---|---|---|---|---|---|
| A før (lov x1) | 48/60 (80 %) | 29/45 (64 %) | 52/60 (87 %) | 24/60 (40 %) | 23/60 (38 %) |
| B lov x1,5 | 52/60 (87 %) | 30/45 (67 %) | 52/60 (87 %) | 28/60 (47 %) | 23/60 (38 %) |
| **C lov x2 (valgt)** | **52/60 (87 %)** | **30/45 (67 %)** | **52/60 (87 %)** | **30/60 (50 %)** | **23/60 (38 %)** |
| D lov x2 + stammer | 52/60 (87 %) | 30/45 (67 %) | 47/60 (78 %) | 30/60 (50 %) | 30/60 (50 %) |
| E lov x2 + lovlinjer | 52/60 (87 %) | 30/45 (67 %) | 57/60 (95 %) | 30/60 (50 %) | 41/60 (68 %) |
| F lov x2 + stammer + lovlinjer | 52/60 (87 %) | 30/45 (67 %) | 57/60 (95 %) | 30/60 (50 %) | 46/60 (77 %) |

Beslutning: C i drift. Paragrafer i lover får dobbel vekt mot forskrifter, `sok` viser de fem lovene med flest
treff øverst, og endringslover og endringsforskrifter er tatt ut av søk, lovliste og `forskrifter_til`.

Forkastet: ordstammer (D) gjør lovlista dårligere når assistenten gir gode søkeord (87 til 78 %), og hjelper bare
når hele spørsmålet sendes inn. Ikke tatt i bruk: lovlinjene fra lovfinner (E, F). De gir størst gevinst, men er
skrevet for hånd for de samme 43 lovene som testsettet bruker, så gevinsten er delvis selvoppfylt, og de ligger i
det private lovfinner-repoet.

// /mcp/ver2: forsøk med Code Mode (https://developers.cloudflare.com/agents/tools/codemode/).
// Samme seks verktøy som /mcp, men modellen ser bare ett verktøy, «code». Den skriver et lite JavaScript-program
// som kaller verktøyene som funksjoner (codemode.sok(...), codemode.hent_paragraf(...)), og programmet kjøres i en
// isolert Dynamic Worker uten nettilgang. Bare det programmet returnerer, går tilbake til modellen.
// /mcp er urørt: den bruker lagServer uten valg, og denne fila lastes bare for /mcp/ver2.
import { codeMcpServer } from "@cloudflare/codemode/mcp";
import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { Executor } from "@cloudflare/codemode";
import { lagServer } from "./server.ts";
import { KREDITERING, type Db } from "./verktoy.ts";

/** Største antall verktøykall i ett program. Et vanlig oppslag bruker 2 til 10. */
export const MAKS_KALL = 50;
/** Lengste kjøretid for ett program, i millisekunder. */
export const TIDSFRIST = 15_000;

const BESKRIVELSE = `Kjører JavaScript som slår opp i norske lover og forskrifter fra Lovdata (gjeldende versjon, oppdatert hver natt).
Bruk dette når oppgaven krever mange oppslag, løkker eller filtrering, for eksempel «gå gjennom alle forskriftene til en lov
og finn dem som nevner frister». Bare det funksjonen returnerer, kommer tilbake, så filtrer og forkort i koden.

Tilgjengelig (hvert kall gir et objekt med dataene og feltet kilde):
{{types}}

Skriv en async pilfunksjon i JavaScript som returnerer resultatet. Ikke TypeScript-syntaks.
Ingen nettilgang (fetch er blokkert). Høyst ${MAKS_KALL} verktøykall og ${TIDSFRIST / 1000} sekunder per kjøring.
Et verktøy som ikke finner noe, kaster en feil med forklaring; bruk try/catch i løkker.

Eksempel:
async () => {
  const { forskrifter } = await codemode.forskrifter_til({ lov: "plan- og bygningsloven", maks: 200 });
  const ut = [];
  for (const f of forskrifter.slice(0, 20)) {
    try {
      const { paragrafer } = await codemode.sok({ tekst: "frist", lov: f.id, maks: 5 });
      ut.push({ forskrift: f.navn, paragrafer: paragrafer.map((p) => p.nummer), lenke: f.url });
    } catch {}
  }
  return ut;
}

Siter paragrafer med nummer og lenke til lovdata.no, og oppgi kilden: ${KREDITERING}
Serveren gir lovtekst, ikke juridisk rådgivning.`;

/** MCP-serveren for /mcp/ver2. Executor er en DynamicWorkerExecutor i drift og en enkel kjører i testene. */
export function lagVer2Server(db: Db, executor: Executor): Promise<McpServer> {
  const indre = lagServer(db, {}, { strukturert: true, maksKall: MAKS_KALL });
  return codeMcpServer({ server: indre, executor, description: BESKRIVELSE });
}

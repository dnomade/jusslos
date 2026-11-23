// Worker «jusslos-mcp»: MCP-server for norske lover og forskrifter på https://mcp.jusslos.no/mcp.
// Åpen for alle, uten nøkkel, med grense per IP-adresse. Tilstandsløs: hver forespørsel får sin egen server og
// transport (Streamable HTTP, svar som JSON), så Workeren trenger ingen Durable Objects.
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { lagServer, VERSJON } from "./server.ts";
import { forside } from "./forside.ts";
import { beskrivKall, type Statistikk, type Treff } from "./maling.ts";

export interface Env {
  DB: D1Database;
  BEGRENSNING: RateLimit;
  /** Bruksstatistikk i Workeren «ipaas-click» (service binding). Valgfri: uten den sendes ingenting. */
  STATISTIKK?: Statistikk;
  /** /mcp/ver2 (Code Mode): Worker Loader for sandkassen. Uten den svarer /mcp/ver2 503. */
  LOADER?: WorkerLoader;
  /** /mcp/ver2: grense per IP-adresse, og samlet grense for kjøringer av kode (nøkkel «alle»). */
  BEGRENSNING_VER2?: RateLimit;
  BEGRENSNING_VER2_KODE?: RateLimit;
  /** Sett til «av» i Cloudflare-panelet for å slå av /mcp/ver2 uten ny deploy. */
  VER2?: string;
}

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Accept, Authorization, Mcp-Session-Id, Mcp-Protocol-Version, Last-Event-ID",
  "Access-Control-Expose-Headers": "Mcp-Session-Id, Mcp-Protocol-Version",
};

function medCors(svar: Response): Response {
  const ut = new Response(svar.body, svar);
  for (const [k, v] of Object.entries(CORS)) ut.headers.set(k, v);
  return ut;
}

function jsonRpcFeil(status: number, kode: number, melding: string, ekstra: Record<string, string> = {}): Response {
  return medCors(
    new Response(JSON.stringify({ jsonrpc: "2.0", error: { code: kode, message: melding }, id: null }), {
      status,
      headers: { "Content-Type": "application/json", ...ekstra },
    }),
  );
}

/**
 * /mcp/ver2: Code Mode-forsøket (se ver2.ts). Helt adskilt fra /mcp: egne grenser, ingen statistikk, og modulene
 * lastes først her, så en feil i dem gir 500 på /mcp/ver2 og ingenting annet.
 */
async function ver2(req: Request, env: Env): Promise<Response> {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });
  if (env.VER2 === "av" || !env.LOADER || !env.BEGRENSNING_VER2 || !env.BEGRENSNING_VER2_KODE) {
    return jsonRpcFeil(503, -32000, "/mcp/ver2 er slått av. Bruk /mcp.");
  }
  if (req.method !== "POST") return jsonRpcFeil(405, -32000, "Bare POST er støttet. Serveren er tilstandsløs.", { Allow: "POST, OPTIONS" });

  const ip = req.headers.get("CF-Connecting-IP") ?? "ukjent";
  if (!(await env.BEGRENSNING_VER2.limit({ key: ip })).success) {
    return jsonRpcFeil(429, -32000, "For mange kall. Grensen på /mcp/ver2 er 20 i minuttet per IP-adresse.", { "Retry-After": "60" });
  }
  // Hver kjøring av kode starter en ny Dynamic Worker, som koster litt utover det som er inkludert. Derfor en samlet grense.
  const melding = await req.clone().json().catch(() => null);
  const erKjoring = [melding].flat().some((m) => m && typeof m === "object" && (m as { method?: string }).method === "tools/call");
  if (erKjoring && !(await env.BEGRENSNING_VER2_KODE.limit({ key: "alle" })).success) {
    return jsonRpcFeil(429, -32000, "/mcp/ver2 har nådd grensen for kjøringer akkurat nå. Prøv igjen om et minutt.", { "Retry-After": "60" });
  }

  try {
    const [{ lagVer2Server }, { lagSandkasse }] = await Promise.all([import("./ver2.ts"), import("./sandkasse.ts")]);
    const server = await lagVer2Server(env.DB, lagSandkasse(env.LOADER));
    const transport = new WebStandardStreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
    await server.connect(transport);
    return await transport.handleRequest(req);
  } catch (feil) {
    console.error("MCP ver2", feil);
    return jsonRpcFeil(500, -32603, "Intern feil i /mcp/ver2.");
  }
}

export default {
  async fetch(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(req.url);

    if (url.pathname === "/" && req.method === "GET") {
      return new Response(forside(VERSJON), { headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "public, max-age=3600" } });
    }
    if (url.pathname === "/mcp/ver2") return medCors(await ver2(req, env));

    // Klienter som får bare https://mcp.jusslos.no (uten /mcp) sender POST til roten. Den behandles likt.
    const erMcp = url.pathname === "/mcp" || (url.pathname === "/" && req.method !== "GET");
    if (!erMcp) return new Response("Ikke funnet. MCP-serveren ligger på /mcp.", { status: 404 });
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });

    // Tilstandsløs server: ingen strøm å åpne eller økt å avslutte.
    if (req.method !== "POST") return jsonRpcFeil(405, -32000, "Bare POST er støttet. Serveren er tilstandsløs.", { Allow: "POST, OPTIONS" });

    const ip = req.headers.get("CF-Connecting-IP") ?? "ukjent";
    const { success } = await env.BEGRENSNING.limit({ key: ip });
    if (!success) return jsonRpcFeil(429, -32000, "For mange kall. Grensen er 60 i minuttet per IP-adresse.", { "Retry-After": "60" });

    const start = Date.now();
    const treff: Treff = {};
    // Meldingen leses fra en kopi, så transporten får den urørt. Bare til statistikken, og bare uten argumentene.
    const melding = env.STATISTIKK ? await req.clone().json().catch(() => null) : null;
    const server = lagServer(env.DB, treff);
    const transport = new WebStandardStreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
    await server.connect(transport);
    try {
      const svar = await transport.handleRequest(req);
      if (env.STATISTIKK && melding) {
        const statistikk = env.STATISTIKK;
        // Statistikken sendes etter svaret, så klienten ikke venter på den, og feil i den stopper aldri svaret.
        ctx.waitUntil(
          svar
            .clone()
            .json()
            .catch(() => null)
            .then((innhold) => {
              const kall = beskrivKall(melding, innhold, treff, Date.now() - start, req.headers.get("User-Agent"));
              return kall ? statistikk.record(kall) : null;
            })
            .catch((feil) => console.warn("Statistikk", feil)),
        );
      }
      return medCors(svar);
    } catch (feil) {
      console.error("MCP", feil);
      return jsonRpcFeil(500, -32603, "Intern feil i serveren.");
    }
  },
} satisfies ExportedHandler<Env>;

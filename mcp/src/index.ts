// Worker «jusslos-mcp»: MCP-server for norske lover og forskrifter på https://mcp.jusslos.no/mcp.
// Åpen for alle, uten nøkkel, med grense per IP-adresse. Tilstandsløs: hver forespørsel får sin egen server og
// transport (Streamable HTTP, svar som JSON), så Workeren trenger ingen Durable Objects.
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { lagServer, VERSJON } from "./server.ts";
import { forside } from "./forside.ts";

export interface Env {
  DB: D1Database;
  BEGRENSNING: RateLimit;
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

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);

    if (url.pathname === "/" && req.method === "GET") {
      return new Response(forside(VERSJON), { headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "public, max-age=3600" } });
    }
    if (url.pathname !== "/mcp") return new Response("Ikke funnet. MCP-serveren ligger på /mcp.", { status: 404 });
    if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: CORS });

    // Tilstandsløs server: ingen strøm å åpne eller økt å avslutte.
    if (req.method !== "POST") return jsonRpcFeil(405, -32000, "Bare POST er støttet. Serveren er tilstandsløs.", { Allow: "POST, OPTIONS" });

    const ip = req.headers.get("CF-Connecting-IP") ?? "ukjent";
    const { success } = await env.BEGRENSNING.limit({ key: ip });
    if (!success) return jsonRpcFeil(429, -32000, "For mange kall. Grensen er 60 i minuttet per IP-adresse.", { "Retry-After": "60" });

    const server = lagServer(env.DB);
    const transport = new WebStandardStreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
    await server.connect(transport);
    try {
      return medCors(await transport.handleRequest(req));
    } catch (feil) {
      console.error("MCP", feil);
      return jsonRpcFeil(500, -32603, "Intern feil i serveren.");
    }
  },
} satisfies ExportedHandler<Env>;

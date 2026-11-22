// Bruksstatistikk for MCP-serveren: en kort melding per initialize og tools/call til Workeren «ipaas-click» via
// service binding (STATISTIKK i wrangler.jsonc). Argumentene, søkeordene, svarene og IP-adressen sendes aldri, bare
// verktøynavnet, klientens navn og versjon, første ord i user agent, om kallet lyktes, tiden og antall treff.
// Uten bindingen (lokalt, i testene eller i en egen kopi av koden) sendes ingenting.

export interface MaltKall {
  server: "jusslos-mcp";
  kind: "initialize" | "tools/call";
  tool?: string;
  client?: string;
  clientVersion?: string;
  userAgent?: string;
  ok: boolean;
  durationMs: number;
  hits?: number;
}

export interface Statistikk {
  record(kall: MaltKall): Promise<unknown>;
}

/** Antall treff som søkeverktøyene (sok, finn_lov) setter mens kallet behandles. Én per forespørsel. */
export interface Treff {
  antall?: number;
}

const kortTekst = (v: unknown): string | undefined => (typeof v === "string" && /^[A-Za-z0-9._/@-]{1,50}$/.test(v) ? v : undefined);

/**
 * Lager meldingen for én JSON-RPC-forespørsel og svaret på den. Gir null for alt annet enn initialize og tools/call,
 * og for flere meldinger i samme forespørsel. Et søk uten treff regnes ikke som feil, selv om verktøyet svarer med isError.
 */
export function beskrivKall(melding: unknown, svar: unknown, treff: Treff, varighetMs: number, userAgent: string | null): MaltKall | null {
  if (!melding || typeof melding !== "object" || Array.isArray(melding)) return null;
  const { method, params } = melding as { method?: unknown; params?: Record<string, unknown> };
  const resultat = (svar as { result?: { isError?: boolean } } | null)?.result;
  const feilet = !resultat || (svar as { error?: unknown }).error !== undefined;
  const felles = { server: "jusslos-mcp" as const, userAgent: userAgent ?? undefined, durationMs: Math.max(0, Math.round(varighetMs)) };
  if (method === "initialize") {
    const klient = (params?.clientInfo ?? {}) as { name?: unknown; version?: unknown };
    return { ...felles, kind: "initialize", client: kortTekst(klient.name), clientVersion: kortTekst(klient.version), ok: !feilet };
  }
  if (method === "tools/call") {
    const verktoy = kortTekst(params?.name);
    if (!verktoy) return null;
    const utenTreff = treff.antall === 0;
    return { ...felles, kind: "tools/call", tool: verktoy, ok: !feilet && (!resultat?.isError || utenTreff), hits: treff.antall };
  }
  return null;
}

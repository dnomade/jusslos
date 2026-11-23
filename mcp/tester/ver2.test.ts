// /mcp/ver2 (Code Mode): ett verktøy «code», og programmet modellen skriver, kaller de vanlige verktøyene.
// I Workers kjøres koden i en Dynamic Worker. Her kjøres den med en enkel kjører i Node, så testene prøver
// innpakningen, typene modellen ser, de strukturerte svarene og grensen for antall kall. Sandkassen selv prøves i drift.
import { test } from "node:test";
import assert from "node:assert/strict";
import type { Executor, ExecuteResult } from "@cloudflare/codemode";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { lagVer2Server, MAKS_KALL } from "../src/ver2.ts";
import { lagServer } from "../src/server.ts";
import { testDb } from "./hjelp.ts";

const db = testDb();

const nodeKjorer: Executor = {
  async execute(code, leverandorer): Promise<ExecuteResult> {
    const fns = Array.isArray(leverandorer) ? leverandorer.find((l) => l.name === "codemode")!.fns : leverandorer;
    try {
      const fn = new Function("codemode", `return (${code})();`);
      return { result: await fn(fns) };
    } catch (feil) {
      return { result: undefined, error: feil instanceof Error ? feil.message : String(feil) };
    }
  },
};

async function kall(server: Awaited<ReturnType<typeof lagVer2Server>>, metode: string, params: unknown = {}) {
  const transport = new WebStandardStreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
  await server.connect(transport);
  const svar = await transport.handleRequest(
    new Request("https://mcp.jusslos.no/mcp/ver2", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json, text/event-stream", "Mcp-Protocol-Version": "2025-06-18" },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: metode, params }),
    }),
  );
  assert.equal(svar.status, 200);
  return (await svar.json()) as { result: any };
}

const kjor = async (code: string) => (await kall(await lagVer2Server(db, nodeKjorer), "tools/call", { name: "code", arguments: { code } })).result;

test("ver2 har bare verktøyet code, med typene til de seks verktøyene", async () => {
  const { result } = await kall(await lagVer2Server(db, nodeKjorer), "tools/list");
  assert.deepEqual(result.tools.map((t: { name: string }) => t.name), ["code"]);
  const beskrivelse = result.tools[0].description as string;
  for (const navn of ["finn_lov", "sok", "hent_paragraf", "innhold", "forskrifter_til", "endringer"]) assert.match(beskrivelse, new RegExp(navn));
  assert.match(beskrivelse, /Lovdata/);
});

test("et program kan lenke kall og får strukturerte data tilbake", async () => {
  const result = await kjor(`async () => {
    const { treff } = await codemode.finn_lov({ navn: "aml" });
    const { paragrafer } = await codemode.hent_paragraf({ lov: treff[0].id, paragraf: "15-7" });
    return { lov: treff[0].navn, nummer: paragrafer[0].nummer, lenke: paragrafer[0].url };
  }`);
  assert.ok(!result.isError, result.content[0].text);
  const ut = JSON.parse(result.content[0].text);
  assert.equal(ut.nummer, "§ 15-7");
  assert.match(ut.lenke, /lovdata\.no.*§15-7/);
});

test("forskrifter_til og løkke med sok, som i eksempelet i beskrivelsen", async () => {
  const result = await kjor(`async () => {
    const { forskrifter } = await codemode.forskrifter_til({ lov: "vegtrafikkloven" });
    return forskrifter.map((f) => f.navn);
  }`);
  assert.match(result.content[0].text, /Parkeringsforskriften/);
});

test("et verktøy som ikke finner noe, kaster en feil programmet kan fange", async () => {
  const result = await kjor(`async () => {
    try { await codemode.finn_lov({ navn: "finnesikkeloven" }); return "ingen feil"; }
    catch (e) { return "fanget: " + e.message; }
  }`);
  assert.match(result.content[0].text, /fanget: Fant ingen lov/);
});

test(`grensen på ${MAKS_KALL} verktøykall per program`, async () => {
  const result = await kjor(`async () => {
    for (let i = 0; i < ${MAKS_KALL + 5}; i++) await codemode.innhold({ lov: "husleieloven" });
    return "ferdig";
  }`);
  assert.ok(result.isError);
  assert.match(result.content[0].text, /For mange verktøykall/);
});

test("/mcp er uendret: ingen structuredContent og ingen grense uten valg", async () => {
  const server = lagServer(db);
  const transport = new WebStandardStreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
  await server.connect(transport);
  const svar = await transport.handleRequest(
    new Request("https://mcp.jusslos.no/mcp", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json, text/event-stream", "Mcp-Protocol-Version": "2025-06-18" },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "finn_lov", arguments: { navn: "aml" } } }),
    }),
  );
  const { result } = (await svar.json()) as { result: any };
  assert.equal(result.structuredContent, undefined);
  assert.match(result.content[0].text, /Arbeidsmiljøloven/i);
});

test("Workeren: /mcp/ver2 svarer 503 når den er slått av eller mangler sandkasse, og /mcp virker som før", async () => {
  const { default: worker } = await import("../src/index.ts");
  const ctx = { waitUntil() {}, passThroughOnException() {} } as unknown as ExecutionContext;
  const ja = { limit: async () => ({ success: true }) };
  const foresporsel = (sti: string) =>
    new Request(`https://mcp.jusslos.no${sti}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json, text/event-stream", "Mcp-Protocol-Version": "2025-06-18" },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/list", params: {} }),
    });
  const utenSandkasse = await worker.fetch(foresporsel("/mcp/ver2"), { DB: db, BEGRENSNING: ja } as never, ctx);
  assert.equal(utenSandkasse.status, 503);
  const avslatt = await worker.fetch(foresporsel("/mcp/ver2"), { DB: db, BEGRENSNING: ja, LOADER: {}, BEGRENSNING_VER2: ja, BEGRENSNING_VER2_KODE: ja, VER2: "av" } as never, ctx);
  assert.equal(avslatt.status, 503);
  const vanlig = await worker.fetch(foresporsel("/mcp"), { DB: db, BEGRENSNING: ja } as never, ctx);
  assert.equal(vanlig.status, 200);
  const { result } = (await vanlig.json()) as { result: { tools: unknown[] } };
  assert.equal(result.tools.length, 6);
});

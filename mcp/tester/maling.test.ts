// Bruksstatistikken (src/maling.ts og Workeren i src/index.ts): hva som sendes, og at søkeord aldri er med.
import { test } from "node:test";
import assert from "node:assert/strict";
import worker from "../src/index.ts";
import { beskrivKall, type MaltKall } from "../src/maling.ts";
import { testDb } from "./hjelp.ts";

test("beskrivKall: initialize gir klientens navn og versjon", () => {
  const kall = beskrivKall(
    { jsonrpc: "2.0", id: 1, method: "initialize", params: { clientInfo: { name: "claude-ai", version: "0.1.0" } } },
    { jsonrpc: "2.0", id: 1, result: {} },
    {},
    12.4,
    "Claude-User/1.0",
  );
  assert.deepEqual(kall, { server: "jusslos-mcp", kind: "initialize", client: "claude-ai", clientVersion: "0.1.0", ok: true, durationMs: 12, userAgent: "Claude-User/1.0" });
});

test("beskrivKall: tools/call gir verktøy og treff, men ikke argumentene", () => {
  const melding = { jsonrpc: "2.0", id: 2, method: "tools/call", params: { name: "sok", arguments: { tekst: "oppsigelse sykmeldt" } } };
  const kall = beskrivKall(melding, { result: { content: [] } }, { antall: 7 }, 80, null);
  assert.deepEqual(kall, { server: "jusslos-mcp", kind: "tools/call", tool: "sok", ok: true, durationMs: 80, hits: 7, userAgent: undefined });
  assert.ok(!JSON.stringify(kall).includes("sykmeldt"));
});

test("beskrivKall: søk uten treff er ikke feil, men andre isError er det", () => {
  const melding = { method: "tools/call", params: { name: "sok" } };
  assert.equal(beskrivKall(melding, { result: { isError: true } }, { antall: 0 }, 1, null)?.ok, true);
  assert.equal(beskrivKall(melding, { result: { isError: true } }, {}, 1, null)?.ok, false);
  assert.equal(beskrivKall(melding, { error: { code: -32602 } }, {}, 1, null)?.ok, false);
});

test("beskrivKall: andre metoder og flere meldinger i en forespørsel telles ikke", () => {
  assert.equal(beskrivKall({ method: "tools/list" }, { result: {} }, {}, 1, null), null);
  assert.equal(beskrivKall({ method: "notifications/initialized" }, null, {}, 1, null), null);
  assert.equal(beskrivKall([{ method: "tools/call", params: { name: "sok" } }], null, {}, 1, null), null);
  assert.equal(beskrivKall({ method: "tools/call", params: { name: "<script>" } }, { result: {} }, {}, 1, null), null);
  assert.equal(beskrivKall(null, null, {}, 1, null), null);
});

// Workeren med en falsk STATISTIKK-binding og en falsk rate limit.
async function kallWorker(env: Record<string, unknown>, melding: unknown) {
  const ventende: Promise<unknown>[] = [];
  const ctx = { waitUntil: (p: Promise<unknown>) => ventende.push(p), passThroughOnException() {} } as unknown as ExecutionContext;
  const svar = await worker.fetch(
    new Request("https://mcp.jusslos.no/mcp", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json, text/event-stream", "Mcp-Protocol-Version": "2025-06-18", "User-Agent": "Claude-User/1.0" },
      body: JSON.stringify(melding),
    }),
    { DB: testDb(), BEGRENSNING: { limit: async () => ({ success: true }) }, ...env } as never,
    ctx,
  );
  await Promise.all(ventende);
  return svar;
}

test("Workeren sender verktøykallet til STATISTIKK etter svaret, med antall treff fra sok", async () => {
  const sendt: MaltKall[] = [];
  const svar = await kallWorker(
    { STATISTIKK: { record: async (k: MaltKall) => sendt.push(k) } },
    { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "sok", arguments: { tekst: "depositum", lov: "husleieloven" } } },
  );
  assert.equal(svar.status, 200);
  assert.equal(sendt.length, 1);
  assert.equal(sendt[0].tool, "sok");
  assert.equal(sendt[0].ok, true);
  assert.ok((sendt[0].hits ?? 0) > 0);
  assert.equal(sendt[0].userAgent, "Claude-User/1.0");
  assert.ok(!JSON.stringify(sendt).includes("depositum"));
});

test("Workeren svarer som vanlig uten STATISTIKK, og når STATISTIKK feiler", async () => {
  const melding = { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "finn_lov", arguments: { navn: "aml" } } };
  assert.equal((await kallWorker({}, melding)).status, 200);
  const svar = await kallWorker({ STATISTIKK: { record: async () => { throw new Error("nede"); } } }, melding);
  assert.equal(svar.status, 200);
  assert.match(JSON.stringify(await svar.json()), /Arbeidsmiljøloven/i);
});

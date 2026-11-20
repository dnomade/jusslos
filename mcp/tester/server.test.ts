// Hele MCP-protokollen gjennom transporten Workeren bruker: initialize, tools/list og tools/call.
import { test } from "node:test";
import assert from "node:assert/strict";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import { lagServer } from "../src/server.ts";
import { testDb } from "./hjelp.ts";

const db = testDb();

async function kall(metode: string, params: unknown = {}) {
  const server = lagServer(db);
  const transport = new WebStandardStreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
  await server.connect(transport);
  const svar = await transport.handleRequest(
    new Request("https://mcp.jusslos.no/mcp", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json, text/event-stream", "Mcp-Protocol-Version": "2025-06-18" },
      body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: metode, params }),
    }),
  );
  assert.equal(svar.status, 200);
  return (await svar.json()) as { result: any; error?: unknown };
}

test("initialize gir navn og instrukser", async () => {
  const { result } = await kall("initialize", { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "test", version: "1" } });
  assert.equal(result.serverInfo.name, "jusslos-lover");
  assert.match(result.instructions, /Lovdata/);
});

test("tools/list har de seks verktøyene, alle bare lesing", async () => {
  const { result } = await kall("tools/list");
  const navn = result.tools.map((t: { name: string }) => t.name).sort();
  assert.deepEqual(navn, ["endringer", "finn_lov", "forskrifter_til", "hent_paragraf", "innhold", "sok"]);
  assert.ok(result.tools.every((t: { annotations: { readOnlyHint: boolean } }) => t.annotations.readOnlyHint));
});

test("tools/call hent_paragraf gir lovtekst og kreditering", async () => {
  const { result } = await kall("tools/call", { name: "hent_paragraf", arguments: { lov: "aml", paragraf: "§ 15-7" } });
  const tekst = result.content[0].text as string;
  assert.ok(!result.isError);
  assert.match(tekst, /Vern mot usaklig oppsigelse/);
  assert.match(tekst, /lovdata\.no\/dokument\/NL\/lov\/2005-06-17-62\/§15-7/);
  assert.match(tekst, /NLOD 2\.0/);
});

test("tools/call med ukjent lov gir isError og et råd", async () => {
  const { result } = await kall("tools/call", { name: "hent_paragraf", arguments: { lov: "naboloven", paragraf: "1" } });
  assert.equal(result.isError, true);
  assert.match(result.content[0].text, /finn_lov/);
});

test("tools/call innhold og forskrifter_til", async () => {
  const innhold = await kall("tools/call", { name: "innhold", arguments: { lov: "husleieloven" } });
  assert.match(innhold.result.content[0].text, /Kapittel 3/);
  const forskrifter = await kall("tools/call", { name: "forskrifter_til", arguments: { lov: "vegtrafikkloven" } });
  assert.match(forskrifter.result.content[0].text, /Parkeringsforskriften/);
});

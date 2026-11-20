import { test } from "node:test";
import assert from "node:assert/strict";
import { testDb } from "./hjelp.ts";
import { endringer, finnLov, forskrifterTil, hentParagraf, innhold, normaliserParagraf, sok } from "../src/verktoy.ts";

const db = testDb();

test("finn_lov: navn, forkortelse, nynorsk, skrivefeil og id", async () => {
  for (const navn of ["husleieloven", "Husleieloven", "husll", "aml", "arbeidsmiljøloven § 15-7", "vegtrafikklova", "veitrafikkloven", "arbeidsmiljøloen", "lov/1999-03-26-17"]) {
    const [forste] = await finnLov(db, navn);
    assert.ok(forste, `fant ingenting for «${navn}»`);
  }
  assert.equal((await finnLov(db, "aml"))[0].id, "lov/2005-06-17-62");
  assert.equal((await finnLov(db, "veitrafikkloven"))[0].id, "lov/1965-06-18-4");
  assert.equal((await finnLov(db, "parkeringsforskriften"))[0].id, "forskrift/2016-03-18-260");
});

test("finn_lov: tittelsøk når navnet ikke finnes", async () => {
  const treff = await finnLov(db, "husleieavtaler");
  assert.equal(treff[0]?.id, "lov/1999-03-26-17");
});

test("finn_lov: ukjent navn gir tom liste", async () => {
  assert.deepEqual(await finnLov(db, "naboloven"), []);
});

test("normaliserParagraf", () => {
  assert.equal(normaliserParagraf("15-7"), "§15-7");
  assert.equal(normaliserParagraf("§ 15-7"), "§15-7");
  assert.equal(normaliserParagraf("paragraf 3-5"), "§3-5");
});

test("hent_paragraf: aml § 15-7", async () => {
  const [p] = await hentParagraf(db, "lov/2005-06-17-62", "15-7");
  assert.equal(p.nummer, "§ 15-7");
  assert.equal(p.tittel, "Vern mot usaklig oppsigelse");
  assert.match(p.tekst, /saklig begrunnet/);
  assert.equal(p.url, "https://lovdata.no/dokument/NL/lov/2005-06-17-62/§15-7");
});

test("hent_paragraf: finnes ikke", async () => {
  assert.deepEqual(await hentParagraf(db, "lov/2005-06-17-62", "999"), []);
});

test("sok: finner depositum i husleieloven", async () => {
  const treff = await sok(db, "depositum", { dokumentId: "lov/1999-03-26-17" });
  assert.ok(treff && treff.length > 0);
  assert.ok(treff.every((t) => t.dokument_id === "lov/1999-03-26-17"));
  assert.match(treff[0].utdrag, /\*\*[Dd]epositum/);
});

test("sok: bare småord gir null", async () => {
  assert.equal(await sok(db, "og i på"), null);
});

test("innhold: kapitler og paragrafer i rekkefølge", async () => {
  const linjer = await innhold(db, "lov/2005-06-17-62");
  const tekster = linjer.map((l) => l.tekst);
  const kap15 = tekster.findIndex((t) => /^Kapittel 15/.test(t));
  const p157 = tekster.findIndex((t) => t.startsWith("§ 15-7"));
  assert.ok(kap15 >= 0 && p157 > kap15, "§ 15-7 skal stå under kapittel 15");
  assert.ok(linjer[p157].niva > linjer[kap15].niva);
});

test("forskrifter_til: parkeringsforskriften har hjemmel i vegtrafikkloven", async () => {
  const liste = await forskrifterTil(db, "lov/1965-06-18-4");
  assert.ok(liste.some((f) => f.id === "forskrift/2016-03-18-260"));
});

test("endringer: datoformat og filter", async () => {
  assert.ok((await endringer(db, "2000-01-01")).length >= 4);
  assert.equal((await endringer(db, "2999-01-01")).length, 0);
});

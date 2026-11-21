// Måler søket mot testsettet: finnes riktig lov og riktig paragraf blant de 10 første paragraftreffene,
// og riktig lov blant de 5 første i lovlista? Kjøres mot en lokal kopi av D1-databasen «jusslos»:
//   node --experimental-strip-types maling/mal.ts <sti til .sqlite> [lovlinjer.json]
import { readFileSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";
import { lovKandidater, normaliserParagraf, sok, type Db, type Sokeoppsett, type Utsagn } from "../src/verktoy.ts";

const [dbSti, linjeSti] = process.argv.slice(2);
const sqlite = new DatabaseSync(dbSti, { readOnly: true });
const utsagn = (sql: string, v: unknown[] = []): Utsagn => ({
  bind: (...n) => utsagn(sql, n),
  all: async <T>() => ({ results: sqlite.prepare(sql).all(...(v as never[])) as T[] }),
  first: async <T>() => (sqlite.prepare(sql).get(...(v as never[])) as T | undefined) ?? null,
});
const db: Db = { prepare: (sql) => utsagn(sql) };

interface Fasit { lov: string; par?: string[] }
const sett = JSON.parse(readFileSync(new URL("./testsett.json", import.meta.url), "utf-8")).sporsmal as { sporsmal: string; sokeord: string; fasit: Fasit[] }[];
const lovlinjer = linjeSti ? JSON.parse(readFileSync(linjeSti, "utf-8")) : null;

const oppsett: Record<string, Partial<Sokeoppsett>> = {
  "A lov x1 (før)": { lovVekt: 1 },
  "B lov x1,5": { lovVekt: 1.5 },
  "C lov x2": { lovVekt: 2 },
  "D lov x2 + stammer": { lovVekt: 2, stammer: true },
  ...(lovlinjer
    ? { "E lov x2 + lovlinjer": { lovVekt: 2, lovlinjer }, "F lov x2 + stammer + lovlinjer": { lovVekt: 2, stammer: true, lovlinjer } }
    : {}),
};

for (const felt of ["sokeord", "sporsmal"] as const) {
  console.log(`\nSøketekst: ${felt === "sokeord" ? "søkeord fra en assistent" : "hele spørsmålet"} (${sett.length} spørsmål)`);
  console.log("oppsett".padEnd(34), "lov topp 10".padStart(12), "paragraf topp 10".padStart(17), "lov i lovlista topp 5".padStart(22));
  for (const [navn, o] of Object.entries(oppsett)) {
    let lov = 0, par = 0, parN = 0, liste = 0;
    const bom: string[] = [];
    for (const s of sett) {
      const treff = (await sok(db, s[felt], { maks: 10, oppsett: o })) ?? [];
      const lover = await lovKandidater(db, s[felt], 5, o);
      const lovIder = new Set(s.fasit.map((f) => f.lov));
      if (treff.some((t) => lovIder.has(t.dokument_id))) lov++;
      if (lover.some((l) => lovIder.has(l.id))) liste++; else bom.push(s[felt]);
      const parFasit = s.fasit.flatMap((f) => (f.par ?? []).map((p) => `${f.lov}|${normaliserParagraf(p)}`));
      if (parFasit.length) {
        parN++;
        if (treff.some((t) => parFasit.includes(`${t.dokument_id}|${normaliserParagraf(t.nummer ?? "")}`))) par++;
      }
    }
    const pst = (a: number, b: number) => `${a}/${b} (${Math.round((100 * a) / b)} %)`;
    console.log(navn.padEnd(34), pst(lov, sett.length).padStart(12), pst(par, parN).padStart(17), pst(liste, sett.length).padStart(22));
    if (process.env.VIS_BOM) console.log("  bom i lovlista:", bom.join(" | "));
  }
}

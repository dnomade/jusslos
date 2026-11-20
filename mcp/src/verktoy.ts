// Oppslagene bak verktøyene i MCP-serveren. Leser fra D1-databasen «jusslos», som har samme skjema som lovfinner
// (migreringene ligger i dnomade/lovfinner, api/migrations/) og fylles hver natt av synken der.
// Funksjonene tar et lite utsnitt av D1-grensesnittet, så testene kan bruke node:sqlite i stedet.

export interface Utsagn {
  bind(...verdier: unknown[]): Utsagn;
  all<T = Record<string, unknown>>(): Promise<{ results: T[] }>;
  first<T = Record<string, unknown>>(): Promise<T | null>;
}
export interface Db {
  prepare(sql: string): Utsagn;
}

export const KREDITERING = "Kilde: Lovdata (lovdata.no), lisens NLOD 2.0. Hentet via jusslos.no. Teksten er ikke offisiell, sjekk lovdata.no før du bygger på den.";

export const TYPER = ["lov", "forskrift", "delegering", "instruks", "stortingsvedtak"] as const;
export type Dokumenttype = (typeof TYPER)[number];

const STOPPORD = new Set(
  (
    "og i jeg det at en et den til er som på de med han av ikke der så var meg seg men ett har om vi min mitt ha hadde hun nå over da ved fra du ut sin dem oss opp man kan hans hvor eller hva skal selv sjøl her alle vil bli ble blitt kunne inn når være kom noen noe ville dere deres kun ja etter ned skulle denne for deg si sine sitt mot å meget hvorfor dette disse uten hvordan ingen din ditt blir samme hvilken hvilke sånn inni mellom vår hver hvem vors hvis både bare enn fordi før mange også slik vært båe begge siden henne hennes får fått få må mens mye jo lurer lure gjøre gjør"
  ).split(" "),
);

export interface Dokument {
  id: string;
  type: string;
  navn: string;
  tittel: string;
  url: string;
  ikraft: string | null;
  siste_endring_ikraft: string | null;
}

const DOKUMENTFELT = `d.id, d.type, COALESCE(d.korttittel, d.tittel) AS navn, d.tittel, d.url, d.ikraft, d.siste_endring_ikraft`;

/** FTS5-spørring av fritekst: hvert ord som prefiks, bundet sammen med OR. Null når ingen ord gjenstår. */
export function lagSporring(tekst: string): string | null {
  const ord = tekst.toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? [];
  const unike = [...new Set(ord.filter((o) => o.length >= 3 && !/^\d+$/.test(o) && !STOPPORD.has(o)))].slice(0, 12);
  return unike.length ? unike.map((o) => `"${o}"*`).join(" OR ") : null;
}

/** Lenke rett til paragrafen på lovdata.no, f.eks. …/lov/2005-06-17-62/§15-7. */
export function lovdataLenke(url: string, nummer: string | null): string {
  return nummer && nummer.startsWith("§") ? `${url}/${nummer.replace(/\s+/g, "")}` : url;
}

/** «15-7», «§15-7», «§ 15-7», «paragraf 15-7» blir «§15-7» (uten mellomrom, slik det sammenlignes). */
export function normaliserParagraf(p: string): string {
  const n = p.toLowerCase().replace(/paragraf|§/g, "").replace(/\s+/g, "");
  return `§${n}`;
}

// ---------- Lovnavn ----------

/** Navn uten mellomrom og tegn, «vei» som «veg» og nynorsk «-lova» som «-loven». Samme regler som lovfinner. */
export function normaliserNavn(navn: string): string {
  return navn
    .toLowerCase()
    .replace(/vei/g, "veg")
    .replace(/[^a-zæøå0-9]/g, "")
    .replace(/lova$/, "loven")
    .replace(/forskrifta$/, "forskriften");
}

/** Antall tegn som må endres for å gå fra a til b (Levenshtein). */
function avstand(a: string, b: string): number {
  let forrige = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    const rad = [i];
    for (let j = 1; j <= b.length; j++) {
      rad[j] = Math.min(forrige[j] + 1, rad[j - 1] + 1, forrige[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1));
    }
    forrige = rad;
  }
  return forrige[b.length];
}

interface Navnerad {
  id: string;
  navn: string;
}

// Navnene på alle lover og forskrifter, holdt i minnet til dataversjonen endrer seg.
let navnebuffer: { versjon: string; rader: Navnerad[] } | null = null;

async function dataversjon(db: Db): Promise<string> {
  const rad = await db.prepare("SELECT verdi FROM meta WHERE nokkel = 'dataversjon'").first<{ verdi: string }>();
  return rad?.verdi ?? "ukjent";
}

async function navnene(db: Db): Promise<Navnerad[]> {
  const versjon = await dataversjon(db);
  if (navnebuffer?.versjon === versjon) return navnebuffer.rader;
  const { results } = await db
    .prepare(
      `SELECT id, tittel, korttittel FROM dokumenter
       WHERE type IN ('lov', 'forskrift') AND sprak IS NULL AND tittel NOT LIKE 'Lov om endring%'`,
    )
    .all<{ id: string; tittel: string; korttittel: string | null }>();
  const rader: Navnerad[] = [];
  for (const d of results) {
    // «Arbeidsmiljøloven – aml» gir to navn, tittelen «Lov om … (arbeidsmiljøloven)» gir navnet i parentes.
    const [kort, forkortelse] = (d.korttittel ?? "").split(" – ");
    const parentes = d.tittel.match(/\(([^()]+)\)\s*$/)?.[1];
    for (const n of [kort, forkortelse, parentes, d.tittel]) if (n) rader.push({ id: d.id, navn: normaliserNavn(n) });
  }
  navnebuffer = { versjon, rader };
  return rader;
}

async function hentDokumenter(db: Db, ider: string[]): Promise<Dokument[]> {
  if (!ider.length) return [];
  const plass = ider.map((_, i) => `?${i + 1}`).join(", ");
  const { results } = await db.prepare(`SELECT ${DOKUMENTFELT} FROM dokumenter d WHERE d.id IN (${plass})`).bind(...ider).all<Dokument>();
  return ider.map((id) => results.find((d) => d.id === id)).filter((d): d is Dokument => !!d);
}

/**
 * Finner lover og forskrifter ut fra navn, forkortelse eller id («husleieloven», «aml», «lov/1999-03-26-17»).
 * Først eksakt navn, så navn med små skrivefeil (som i lovfinner), til slutt fulltekstsøk i titlene.
 */
export async function finnLov(db: Db, navn: string, maks = 5): Promise<Dokument[]> {
  const ren = navn.trim().replace(/\s+(§|kap\.|kapittel)\s.*$/i, "");
  if (/^(DEL\/)?(lov|forskrift|instruks|stortingsvedtak)\/[\w-]+$/i.test(ren)) return hentDokumenter(db, [ren]);

  const n = normaliserNavn(ren);
  const alle = await navnene(db);
  if (n.length >= 2) {
    const eksakt = [...new Set(alle.filter((r) => r.navn === n).map((r) => r.id))];
    if (eksakt.length) return hentDokumenter(db, eksakt.slice(0, maks));
  }
  if (n.length >= 8) {
    const grense = n.length < 14 ? 1 : Math.min(5, Math.floor(n.length * 0.2));
    const naere = new Map<string, number>();
    for (const r of alle) {
      if (Math.abs(r.navn.length - n.length) > grense || r.navn.slice(0, 3) !== n.slice(0, 3)) continue;
      const a = avstand(n, r.navn);
      if (a <= grense && a < (naere.get(r.id) ?? Infinity)) naere.set(r.id, a);
    }
    if (naere.size) {
      const ider = [...naere.entries()].sort((a, b) => a[1] - b[1]).map(([id]) => id);
      return hentDokumenter(db, ider.slice(0, maks));
    }
  }
  const sporring = lagSporring(ren);
  if (!sporring) return [];
  const { results } = await db
    .prepare(
      `SELECT ${DOKUMENTFELT} FROM dokument_sok
       JOIN dokumenter d ON d.rowid = dokument_sok.rowid
       WHERE dokument_sok MATCH ?1 AND d.type IN ('lov', 'forskrift') AND d.sprak IS NULL
       ORDER BY (d.type = 'lov') DESC, bm25(dokument_sok, 1, 4)
       LIMIT ?2`,
    )
    .bind(sporring, maks)
    .all<Dokument>();
  return results;
}

/** Ett dokument ut fra navn eller id, eller null. */
export async function ettDokument(db: Db, lov: string): Promise<Dokument | null> {
  return (await finnLov(db, lov, 1))[0] ?? null;
}

// ---------- Søk ----------

export interface Paragraftreff {
  dokument_id: string;
  dokument: string;
  nummer: string | null;
  tittel: string | null;
  utdrag: string;
  url: string;
}

/** Fulltekstsøk i paragrafene. Kan avgrenses til dokumenttyper eller til ett dokument. */
export async function sok(
  db: Db,
  tekst: string,
  valg: { typer?: Dokumenttype[]; dokumentId?: string; maks?: number } = {},
): Promise<Paragraftreff[] | null> {
  const sporring = lagSporring(tekst);
  if (!sporring) return null;
  const typer = valg.typer?.length ? valg.typer : (["lov", "forskrift"] as Dokumenttype[]);
  const verdier: unknown[] = [sporring, Math.min(valg.maks ?? 10, 30)];
  let filter = `d.type IN (${typer.map((t) => (verdier.push(t), `?${verdier.length}`)).join(", ")}) AND d.sprak IS NULL`;
  if (valg.dokumentId) {
    verdier.push(valg.dokumentId);
    filter += ` AND d.id = ?${verdier.length}`;
  }
  const { results } = await db
    .prepare(
      `SELECT p.dokument_id, COALESCE(d.korttittel, d.tittel) AS dokument, d.url, p.nummer, p.tittel,
              snippet(paragraf_sok, 2, '**', '**', '…', 24) AS utdrag
       FROM paragraf_sok
       JOIN paragrafer p ON p.id = paragraf_sok.rowid
       JOIN dokumenter d ON d.id = p.dokument_id
       WHERE paragraf_sok MATCH ?1 AND ${filter} AND p.opphevet IS NULL
       ORDER BY bm25(paragraf_sok, 2, 6, 1)
       LIMIT ?2`,
    )
    .bind(...verdier)
    .all<Paragraftreff>();
  return results.map((r) => ({ ...r, url: lovdataLenke(r.url, r.nummer) }));
}

// ---------- Paragraf og innhold ----------

export interface Paragraf {
  nummer: string | null;
  tittel: string | null;
  tekst: string;
  kapittel: string | null;
  opphevet: string | null;
  fremtidig: number;
  url: string;
}

export async function hentParagraf(db: Db, dokumentId: string, paragraf: string): Promise<Paragraf[]> {
  const { results } = await db
    .prepare(
      `SELECT p.nummer, p.tittel, p.tekst, p.opphevet, p.fremtidig, s.overskrift AS kapittel, d.url
       FROM paragrafer p
       JOIN dokumenter d ON d.id = p.dokument_id
       LEFT JOIN seksjoner s ON s.dokument_id = p.dokument_id AND s.nr = p.seksjon_nr
       WHERE p.dokument_id = ?1 AND REPLACE(p.nummer, ' ', '') = ?2
       ORDER BY p.fremtidig, p.nr`,
    )
    .bind(dokumentId, normaliserParagraf(paragraf))
    .all<Paragraf>();
  return results.map((r) => ({ ...r, url: lovdataLenke(r.url, r.nummer) }));
}

export interface Innholdslinje {
  niva: number;
  tekst: string;
}

/** Kapitler og paragraftitler i rekkefølge, som innrykkede linjer. Opphevede paragrafer er med som «(opphevet)». */
export async function innhold(db: Db, dokumentId: string): Promise<Innholdslinje[]> {
  const [seksjoner, paragrafer] = await Promise.all([
    db
      .prepare("SELECT nr, forelder_nr, niva, overskrift FROM seksjoner WHERE dokument_id = ?1 ORDER BY nr")
      .bind(dokumentId)
      .all<{ nr: number; forelder_nr: number | null; niva: number; overskrift: string | null }>(),
    db
      .prepare("SELECT seksjon_nr, nummer, tittel, opphevet, fremtidig FROM paragrafer WHERE dokument_id = ?1 ORDER BY nr")
      .bind(dokumentId)
      .all<{ seksjon_nr: number | null; nummer: string | null; tittel: string | null; opphevet: string | null; fremtidig: number }>(),
  ]);
  const niva = new Map(seksjoner.results.map((s) => [s.nr, s.niva]));
  const underSeksjon = new Map<number | null, typeof paragrafer.results>();
  for (const p of paragrafer.results) {
    if (p.fremtidig) continue;
    const liste = underSeksjon.get(p.seksjon_nr) ?? [];
    liste.push(p);
    underSeksjon.set(p.seksjon_nr, liste);
  }
  const linjer: Innholdslinje[] = [];
  const paragraflinjer = (nr: number | null, dybde: number) => {
    for (const p of underSeksjon.get(nr) ?? []) {
      const navn = [p.nummer, p.tittel].filter(Boolean).join(" ");
      linjer.push({ niva: dybde, tekst: p.opphevet ? `${p.nummer ?? navn} (opphevet)` : navn });
    }
  };
  paragraflinjer(null, 0);
  for (const s of seksjoner.results) {
    linjer.push({ niva: s.niva - 1, tekst: s.overskrift ?? "" });
    paragraflinjer(s.nr, niva.get(s.nr) ?? 1);
  }
  return linjer;
}

// ---------- Forskrifter og endringer ----------

export interface Forskrift extends Dokument {
  hjemmel: string | null;
}

/** Forskrifter gitt med hjemmel i loven, eventuelt bare i én paragraf. */
export async function forskrifterTil(db: Db, lovId: string, paragraf?: string, maks = 50): Promise<Forskrift[]> {
  const verdier: unknown[] = [lovId, Math.min(maks, 200)];
  let filter = "";
  if (paragraf) {
    verdier.push(normaliserParagraf(paragraf));
    filter = " AND h.paragraf = ?3";
  }
  const { results } = await db
    .prepare(
      `SELECT ${DOKUMENTFELT}, GROUP_CONCAT(h.paragraf, ', ') AS hjemmel
       FROM hjemmel h
       JOIN dokumenter d ON d.id = h.dokument_id
       WHERE h.lov_refid = ?1 AND d.type = 'forskrift' AND d.sprak IS NULL${filter}
       GROUP BY d.id
       ORDER BY navn
       LIMIT ?2`,
    )
    .bind(...verdier)
    .all<Forskrift>();
  return results;
}

export interface Endring extends Dokument {
  endret: string;
}

/** Dokumenter som er nye eller endret i jusslos siden datoen (ÅÅÅÅ-MM-DD), nyeste først. */
export async function endringer(db: Db, siden: string, typer: Dokumenttype[] = ["lov", "forskrift"], maks = 50): Promise<Endring[]> {
  const verdier: unknown[] = [siden, Math.min(maks, 200)];
  const typeliste = typer.map((t) => (verdier.push(t), `?${verdier.length}`)).join(", ");
  const { results } = await db
    .prepare(
      `SELECT ${DOKUMENTFELT}, d.endret FROM dokumenter d
       WHERE d.endret >= ?1 AND d.type IN (${typeliste}) AND d.sprak IS NULL
       ORDER BY d.endret DESC, navn
       LIMIT ?2`,
    )
    .bind(...verdier)
    .all<Endring>();
  return results;
}

export { dataversjon };

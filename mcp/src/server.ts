// MCP-serveren: verktøyene, beskrivelsene modellen ser, og hvordan svarene skrives som tekst.
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  type Db,
  type Dokument,
  KREDITERING,
  TYPER,
  dataversjon,
  endringer,
  ettDokument,
  finnLov,
  forskrifterTil,
  hentParagraf,
  innhold,
  sok,
} from "./verktoy.ts";

export const VERSJON = "0.1.0";

const INSTRUKSER = `Norske lover og forskrifter fra Lovdata (gjeldende versjon, oppdatert hver natt via jusslos.no).
Slik bruker du verktøyene: finn loven med finn_lov eller sok, hent ordlyden med hent_paragraf, og bruk innhold for å se
hvordan loven er bygd opp. Siter paragrafen med nummer og lenke til lovdata.no, og oppgi Lovdata som kilde (NLOD 2.0).
Serveren gir lovtekst, ikke juridisk rådgivning.`;

type Svar = { content: { type: "text"; text: string }[]; isError?: boolean };

function tekst(...deler: string[]): Svar {
  return { content: [{ type: "text", text: [...deler, KREDITERING].join("\n\n") }] };
}

function feil(melding: string): Svar {
  return { content: [{ type: "text", text: melding }], isError: true };
}

function dokumentlinje(d: Dokument): string {
  const tid = [d.ikraft && `i kraft ${d.ikraft}`, d.siste_endring_ikraft && `sist endret ${d.siste_endring_ikraft}`].filter(Boolean).join(", ");
  return `- ${d.navn} (id: ${d.id}, ${d.type}${tid ? `, ${tid}` : ""})\n  ${d.tittel}\n  ${d.url}`;
}

async function finnEllerFeil(db: Db, lov: string): Promise<Dokument | Svar> {
  const d = await ettDokument(db, lov);
  return d ?? feil(`Fant ingen lov eller forskrift som heter «${lov}». Prøv finn_lov med et annet navn, eller sok med ord fra innholdet.`);
}

const erSvar = (v: Dokument | Svar): v is Svar => "content" in v;

const kunLese = { readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false };

export function lagServer(db: Db): McpServer {
  const server = new McpServer({ name: "jusslos-lover", title: "Norske lover (jusslos.no)", version: VERSJON }, { instructions: INSTRUKSER });

  server.registerTool(
    "finn_lov",
    {
      title: "Finn lov eller forskrift",
      description:
        "Finner lover og forskrifter ut fra navn, forkortelse eller Lovdata-id, og tåler små skrivefeil. Eksempler: «husleieloven», «aml», «vegtrafikklova», «parkeringsforskriften», «lov/1999-03-26-17». Gir id-en de andre verktøyene bruker.",
      inputSchema: {
        navn: z.string().min(2).max(200).describe("Navnet, forkortelsen eller id-en"),
        maks: z.number().int().min(1).max(20).optional().describe("Største antall treff (standard 5)"),
      },
      annotations: kunLese,
    },
    async ({ navn, maks }) => {
      const treff = await finnLov(db, navn, maks ?? 5);
      if (!treff.length) return feil(`Fant ingen lov eller forskrift som heter «${navn}». Prøv sok med ord fra innholdet.`);
      return tekst(treff.map(dokumentlinje).join("\n"));
    },
  );

  server.registerTool(
    "sok",
    {
      title: "Søk i lovteksten",
      description:
        "Fulltekstsøk i paragrafene i gjeldende lover og forskrifter. Bruk ordene som står i loven («oppsigelse saklig», «depositum husleie»), ikke hele spørsmål. Gir paragrafer med utdrag og lenke. Avgrens med lov for å søke i én lov.",
      inputSchema: {
        tekst: z.string().min(3).max(500).describe("Ordene du søker etter"),
        lov: z.string().max(200).optional().describe("Søk bare i denne loven eller forskriften (navn eller id)"),
        typer: z.array(z.enum(TYPER)).optional().describe("Dokumenttyper (standard lov og forskrift)"),
        maks: z.number().int().min(1).max(30).optional().describe("Største antall paragrafer (standard 10)"),
      },
      annotations: kunLese,
    },
    async ({ tekst: sokeord, lov, typer, maks }) => {
      let dokumentId: string | undefined;
      if (lov) {
        const d = await finnEllerFeil(db, lov);
        if (erSvar(d)) return d;
        dokumentId = d.id;
      }
      const treff = await sok(db, sokeord, { typer, dokumentId, maks });
      if (treff === null) return feil("Søket trenger minst ett ord på tre bokstaver eller mer som ikke er et småord.");
      if (!treff.length) return feil(`Ingen paragrafer inneholder «${sokeord}». Prøv andre ord eller færre ord.`);
      const linjer = treff.map((t) => `- ${t.dokument} ${t.nummer ?? ""}${t.tittel ? ` ${t.tittel}` : ""} (id: ${t.dokument_id})\n  ${t.utdrag.replace(/\s+/g, " ")}\n  ${t.url}`);
      return tekst(linjer.join("\n"));
    },
  );

  server.registerTool(
    "hent_paragraf",
    {
      title: "Hent paragraf",
      description:
        "Gir hele ordlyden i en paragraf, med ledd, kapittel og lenke til lovdata.no. Eksempel: lov «arbeidsmiljøloven», paragraf «15-7».",
      inputSchema: {
        lov: z.string().min(2).max(200).describe("Loven eller forskriften (navn, forkortelse eller id)"),
        paragraf: z.string().min(1).max(20).describe("Paragrafnummeret, f.eks. «15-7», «§ 3» eller «§ 9 a»"),
      },
      annotations: kunLese,
    },
    async ({ lov, paragraf }) => {
      const d = await finnEllerFeil(db, lov);
      if (erSvar(d)) return d;
      const treff = await hentParagraf(db, d.id, paragraf);
      if (!treff.length) return feil(`${d.navn} har ingen paragraf ${paragraf}. Bruk innhold for å se paragrafene i loven.`);
      const deler = treff.map((p) => {
        const merknad = p.fremtidig ? "\nMerk: denne versjonen er vedtatt, men ikke trådt i kraft ennå." : p.opphevet ? `\nMerk: paragrafen er opphevet (${p.opphevet}).` : "";
        return `${d.navn} ${p.nummer ?? ""}${p.tittel ? ` ${p.tittel}` : ""}${p.kapittel ? `\nKapittel: ${p.kapittel}` : ""}${merknad}\n\n${p.tekst}\n\n${p.url}`;
      });
      return tekst(...deler);
    },
  );

  server.registerTool(
    "innhold",
    {
      title: "Innholdsfortegnelse",
      description: "Viser kapitlene og paragraftitlene i en lov eller forskrift, i rekkefølge. Nyttig for å finne riktig paragraf før hent_paragraf.",
      inputSchema: { lov: z.string().min(2).max(200).describe("Loven eller forskriften (navn, forkortelse eller id)") },
      annotations: kunLese,
    },
    async ({ lov }) => {
      const d = await finnEllerFeil(db, lov);
      if (erSvar(d)) return d;
      const linjer = await innhold(db, d.id);
      const kropp = linjer.map((l) => `${"  ".repeat(Math.max(0, l.niva))}${l.tekst}`).join("\n");
      return tekst(`${d.navn} (id: ${d.id})\n${d.url}\n\n${kropp || "(ingen paragrafer)"}`);
    },
  );

  server.registerTool(
    "forskrifter_til",
    {
      title: "Forskrifter til en lov",
      description:
        "Lister forskriftene som er gitt med hjemmel i en lov, eventuelt bare i én paragraf. Eksempel: lov «vegtrafikkloven», paragraf «8».",
      inputSchema: {
        lov: z.string().min(2).max(200).describe("Loven (navn, forkortelse eller id)"),
        paragraf: z.string().max(20).optional().describe("Bare forskrifter med hjemmel i denne paragrafen"),
        maks: z.number().int().min(1).max(200).optional().describe("Største antall forskrifter (standard 50)"),
      },
      annotations: kunLese,
    },
    async ({ lov, paragraf, maks }) => {
      const d = await finnEllerFeil(db, lov);
      if (erSvar(d)) return d;
      const liste = await forskrifterTil(db, d.id, paragraf, maks ?? 50);
      if (!liste.length) return feil(`Fant ingen forskrifter med hjemmel i ${d.navn}${paragraf ? ` § ${paragraf.replace(/§\s*/, "")}` : ""}.`);
      const linjer = liste.map((f) => `${dokumentlinje(f)}${f.hjemmel ? `\n  Hjemmel: ${f.hjemmel}` : ""}`);
      return tekst(`Forskrifter med hjemmel i ${d.navn}:`, linjer.join("\n"));
    },
  );

  server.registerTool(
    "endringer",
    {
      title: "Nye og endrede dokumenter",
      description:
        "Lover og forskrifter som er nye eller endret hos Lovdata siden en dato (ÅÅÅÅ-MM-DD). Datasettet startet 2026-11-13, så eldre datoer gir alle dokumentene.",
      inputSchema: {
        siden: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).describe("Dato, f.eks. 2026-11-18"),
        typer: z.array(z.enum(TYPER)).optional().describe("Dokumenttyper (standard lov og forskrift)"),
        maks: z.number().int().min(1).max(200).optional().describe("Største antall (standard 50)"),
      },
      annotations: kunLese,
    },
    async ({ siden, typer, maks }) => {
      const liste = await endringer(db, siden, typer, maks ?? 50);
      const versjon = await dataversjon(db);
      if (!liste.length) return tekst(`Ingen nye eller endrede dokumenter siden ${siden}. Dataversjon ${versjon}.`);
      return tekst(`Dataversjon ${versjon}. Nye eller endret siden ${siden}:`, liste.map((e) => `${dokumentlinje(e)}\n  Endret i datasettet: ${e.endret}`).join("\n"));
    },
  );

  return server;
}

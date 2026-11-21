// Enkel forside på https://mcp.jusslos.no/ for folk som åpner adressen i nettleseren.
export function forside(versjon: string): string {
  return `<!doctype html>
<html lang="no">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MCP-server for norske lover</title>
<style>
  :root { --bakgrunn: #fff; --tekst: #111827; --dempet: #4b5563; --kode: #f3f4f6; --lenke: #1d4ed8; }
  @media (prefers-color-scheme: dark) { :root { --bakgrunn: #111827; --tekst: #f9fafb; --dempet: #9ca3af; --kode: #1f2937; --lenke: #93c5fd; } }
  body { background: var(--bakgrunn); color: var(--tekst); font: 17px/1.6 system-ui, sans-serif; max-width: 42rem; margin: 2rem auto; padding: 0 16px; }
  h1 { font-family: Georgia, serif; font-weight: 600; }
  code { background: var(--kode); padding: 0.1em 0.35em; border-radius: 4px; overflow-wrap: anywhere; }
  a { color: var(--lenke); }
  .dempet { color: var(--dempet); font-size: 0.9em; }
</style>
</head>
<body>
<h1>MCP-server for norske lover</h1>
<p>Gjeldende lover og forskrifter fra Lovdata, oppdatert hver natt, for KI-assistenter som støtter Model Context Protocol (MCP).</p>
<p>Adresse: <code>https://mcp.jusslos.no/mcp</code> (Streamable HTTP, ingen nøkkel). Legg den til som egen connector i Claude, ChatGPT, Cursor eller en annen MCP-klient.</p>
<p>Verktøy: <code>finn_lov</code>, <code>sok</code>, <code>hent_paragraf</code>, <code>innhold</code>, <code>forskrifter_til</code> og <code>endringer</code>.</p>
<p>Grense: 60 kall i minuttet per IP-adresse. Serveren gir lovtekst, ikke juridisk rådgivning.</p>
<p>Serveren er et eksempel på hva dataene kan brukes til, ikke en produksjonsløsning. Den har ingen garanti for oppetid, verktøyene kan endres, og den kan bli stengt. Skal du bygge noe som skal i drift, bruk dataene direkte eller kjør din egen kopi av koden i <a href="https://github.com/dnomade/jusslos/tree/main/mcp">mcp/</a>.</p>
<p class="dempet">Kilde: Lovdata, lisens <a href="https://data.norge.no/nlod/no/2.0">NLOD 2.0</a>. Data og kode: <a href="https://jusslos.no">jusslos.no</a> og <a href="https://github.com/dnomade/jusslos">github.com/dnomade/jusslos</a>. Versjon ${versjon}.</p>
</body>
</html>`;
}

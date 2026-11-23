// Sandkassen for /mcp/ver2. Egen fil fordi @cloudflare/codemode importerer «cloudflare:workers», som bare finnes i
// Workers. index.ts laster den bare for /mcp/ver2, så en feil her rammer aldri /mcp.
import { DynamicWorkerExecutor } from "@cloudflare/codemode";
import { TIDSFRIST } from "./ver2.ts";

/**
 * CPU-tid per kjøring. Programmene venter mest på verktøyene (som kjører i vår Worker og ikke teller her), så
 * 1 sekund er god margin. Tidsfristen i DynamicWorkerExecutor går i sandkassen og stopper ikke en løkke som
 * aldri slipper taket; det gjør denne grensen.
 */
export const CPU_MS = 1_000;

export function lagSandkasse(loader: WorkerLoader): DynamicWorkerExecutor {
  // DynamicWorkerExecutor gir ikke valg for limits, så de legges på her.
  const medGrenser: WorkerLoader = {
    get: (id, kode) => loader.get(id, async () => ({ ...(await kode()), limits: { cpuMs: CPU_MS } })),
    load: (kode) => loader.load({ ...kode, limits: { cpuMs: CPU_MS } }),
  };
  // globalOutbound null: fetch() og connect() er sperret. Koden når bare verktøyene, som kjører i vår Worker.
  return new DynamicWorkerExecutor({ loader: medGrenser, timeout: TIDSFRIST, globalOutbound: null });
}

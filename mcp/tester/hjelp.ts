// Testdatabase i minnet: node:sqlite med tester/testdata.sql, pakket inn slik at den ligner D1 (prepare/bind/all/first).
import { readFileSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";
import type { Db, Utsagn } from "../src/verktoy.ts";

export function testDb(): Db {
  const db = new DatabaseSync(":memory:");
  db.exec(readFileSync(new URL("./testdata.sql", import.meta.url), "utf-8"));
  const utsagn = (sql: string, verdier: unknown[] = []): Utsagn => ({
    bind: (...v) => utsagn(sql, v),
    // D1 bruker ?1, ?2 …; node:sqlite godtar det samme når verdiene gis i rekkefølge.
    all: async <T>() => ({ results: db.prepare(sql).all(...(verdier as never[])) as T[] }),
    first: async <T>() => (db.prepare(sql).get(...(verdier as never[])) as T | undefined) ?? null,
  });
  return { prepare: (sql) => utsagn(sql) };
}

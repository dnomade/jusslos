-- Laget av tester/lag_testdata.py. Ikke rediger for hånd.
CREATE TABLE meta (
  nokkel TEXT PRIMARY KEY,
  verdi  TEXT NOT NULL
);
CREATE TABLE dokumenter (
  id                   TEXT PRIMARY KEY,   -- nøkkelen i jusslos/indeks.json
  dokumentid           TEXT NOT NULL,      -- Lovdatas id, f.eks. NL/lov/2005-06-17-62 (ikke alltid unik)
  refid                TEXT NOT NULL,      -- lov/2005-06-17-62
  type                 TEXT NOT NULL,
  sprak                TEXT,               -- 'nn' for nynorske parallellutgaver
  tittel               TEXT NOT NULL,
  korttittel           TEXT,
  departement          TEXT,               -- JSON-liste
  rettsomrade          TEXT,               -- JSON-liste
  ikraft               TEXT,
  siste_endring_ikraft TEXT,
  url                  TEXT NOT NULL,      -- lenke til lovdata.no
  fil                  TEXT NOT NULL,      -- sti i jusslos
  sha256               TEXT NOT NULL,      -- fra jusslos/indeks.json, styrer synken
  endret               TEXT                -- dato endret i jusslos
);
CREATE INDEX dokumenter_refid ON dokumenter(refid);
CREATE INDEX dokumenter_type ON dokumenter(type);
CREATE TABLE seksjoner (
  dokument_id TEXT NOT NULL,
  nr          INTEGER NOT NULL,
  forelder_nr INTEGER,                     -- NULL på øverste nivå
  niva        INTEGER NOT NULL,            -- 1 = øverste nivå
  seksjon_id  TEXT,                        -- Lovdatas id, f.eks. kapittel-15
  overskrift  TEXT,
  PRIMARY KEY (dokument_id, nr)
);
CREATE TABLE paragrafer (
  id          INTEGER PRIMARY KEY,
  dokument_id TEXT NOT NULL,
  nr          INTEGER NOT NULL,            -- rekkefølgen i dokumentet
  seksjon_nr  INTEGER,                     -- nærmeste seksjon, NULL utenfor kapittel
  paragraf_id TEXT,                        -- Lovdatas id, f.eks. kapittel-15-paragraf-8
  nummer      TEXT,                        -- § 15-8
  tittel      TEXT,
  tekst       TEXT NOT NULL,
  opphevet    TEXT,
  fremtidig   INTEGER NOT NULL DEFAULT 0   -- 1 = ikke trådt i kraft ennå
);
CREATE INDEX paragrafer_dokument ON paragrafer(dokument_id, nr);
CREATE VIRTUAL TABLE dokument_sok USING fts5(
  tittel, korttittel,
  content='dokumenter', content_rowid='rowid',
  tokenize='unicode61 remove_diacritics 0'
);
CREATE TRIGGER dokumenter_ai AFTER INSERT ON dokumenter BEGIN
  INSERT INTO dokument_sok(rowid, tittel, korttittel) VALUES (new.rowid, new.tittel, new.korttittel);
END;
CREATE TRIGGER dokumenter_ad AFTER DELETE ON dokumenter BEGIN
  INSERT INTO dokument_sok(dokument_sok, rowid, tittel, korttittel) VALUES ('delete', old.rowid, old.tittel, old.korttittel);
END;
CREATE TRIGGER dokumenter_au AFTER UPDATE ON dokumenter BEGIN
  INSERT INTO dokument_sok(dokument_sok, rowid, tittel, korttittel) VALUES ('delete', old.rowid, old.tittel, old.korttittel);
  INSERT INTO dokument_sok(rowid, tittel, korttittel) VALUES (new.rowid, new.tittel, new.korttittel);
END;
CREATE VIRTUAL TABLE paragraf_sok USING fts5(
  nummer, tittel, tekst,
  content='paragrafer', content_rowid='id',
  tokenize='unicode61 remove_diacritics 0'
);
CREATE TRIGGER paragrafer_ai AFTER INSERT ON paragrafer BEGIN
  INSERT INTO paragraf_sok(rowid, nummer, tittel, tekst) VALUES (new.id, new.nummer, new.tittel, new.tekst);
END;
CREATE TRIGGER paragrafer_ad AFTER DELETE ON paragrafer BEGIN
  INSERT INTO paragraf_sok(paragraf_sok, rowid, nummer, tittel, tekst) VALUES ('delete', old.id, old.nummer, old.tittel, old.tekst);
END;
CREATE TABLE hjemmel (
  dokument_id TEXT NOT NULL,   -- forskriften, f.eks. forskrift/2016-03-18-260
  lov_refid   TEXT NOT NULL,   -- loven, f.eks. lov/1965-06-18-4
  paragraf    TEXT             -- paragrafen uten mellomrom, f.eks. §8 eller §23a. NULL når hjemmelen er hele loven.
);
CREATE INDEX hjemmel_lov ON hjemmel(lov_refid, paragraf);
CREATE INDEX hjemmel_dokument ON hjemmel(dokument_id);
INSERT INTO meta (nokkel, verdi) VALUES ('dataversjon', '2026-11-20.2e2e37d7');
INSERT INTO dokumenter (id, dokumentid, refid, type, sprak, tittel, korttittel, departement, rettsomrade, ikraft, siste_endring_ikraft, url, fil, sha256, endret) VALUES ('forskrift/2016-03-18-260', 'SF/forskrift/2016-03-18-260', 'forskrift/2016-03-18-260', 'forskrift', NULL, 'Forskrift om vilkårsparkering for allmennheten og håndheving av private parkeringsreguleringer (parkeringsforskriften)', 'Parkeringsforskriften', '["Samferdselsdepartementet"]', NULL, '2017-01-01, 2018-01-01', '2026-09-07', 'https://lovdata.no/dokument/SF/forskrift/2016-03-18-260', 'data/forskrifter/2016/forskrift-2016-03-18-260.json', 'a4c0be9001c0b5174d6c490a628313234c3d33caace0a23b92f42dac88bed8c2', '2026-11-13');
INSERT INTO dokumenter (id, dokumentid, refid, type, sprak, tittel, korttittel, departement, rettsomrade, ikraft, siste_endring_ikraft, url, fil, sha256, endret) VALUES ('lov/1965-06-18-4', 'NL/lov/1965-06-18-4', 'lov/1965-06-18-4', 'lov', NULL, 'Lov om vegtrafikk (vegtrafikkloven)', 'Vegtrafikkloven – vtrl', '["Samferdselsdepartementet"]', '["Transport og kommunikasjoner > Veitrafikk"]', '1965-07-01, 1967-04-23', '2026-07-01', 'https://lovdata.no/dokument/NL/lov/1965-06-18-4', 'data/lover/1965/lov-1965-06-18-4.json', '97e7ff9e6c7274626ea6a6dfe1196a5541fe185a632a0b6e590f1191679da397', '2026-11-13');
INSERT INTO dokumenter (id, dokumentid, refid, type, sprak, tittel, korttittel, departement, rettsomrade, ikraft, siste_endring_ikraft, url, fil, sha256, endret) VALUES ('lov/1999-03-26-17', 'NL/lov/1999-03-26-17', 'lov/1999-03-26-17', 'lov', NULL, 'Lov om husleieavtaler (husleieloven)', 'Husleieloven – husll', '["Kommunal- og distriktsdepartementet"]', '["Fast eiendoms rettsforhold > Husleie"]', '2000-01-01', '2026-07-01', 'https://lovdata.no/dokument/NL/lov/1999-03-26-17', 'data/lover/1999/lov-1999-03-26-17.json', 'd8348f6091eace40ddfe9dcc0b0a5b6cec0054227a3a6b60c9d0022c9a54bbef', '2026-11-13');
INSERT INTO dokumenter (id, dokumentid, refid, type, sprak, tittel, korttittel, departement, rettsomrade, ikraft, siste_endring_ikraft, url, fil, sha256, endret) VALUES ('lov/2005-06-17-62', 'NL/lov/2005-06-17-62', 'lov/2005-06-17-62', 'lov', NULL, 'Lov om arbeidsmiljø, arbeidstid og stillingsvern mv. (arbeidsmiljøloven)', 'Arbeidsmiljøloven – aml', '["Arbeids- og inkluderingsdepartementet"]', '["Arbeidsrett > Ansettelse. Avskjed. Oppsigelse", "Arbeidsrett > Arbeidsforhold. Sysselsetting", "Arbeidsrett > Arbeidsmiljø", "Arbeidsrett > Arbeidstvister", "Arbeidsrett > Likestilling og diskriminering", "Arbeidsrett > Offentlige tjenestemenn", "Arbeidsrett > Tariffavtaler", "HMS og beredskaps- og sikkerhetsrett > Helse, miljø og sikkerhet"]', '2006-01-01', '2026-07-01', 'https://lovdata.no/dokument/NL/lov/2005-06-17-62', 'data/lover/2005/lov-2005-06-17-62.json', 'e9c70170712cc36e9961bc0281e1e9842cd082c8cbab179d517e2492a361711b', '2026-11-14');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 1, NULL, 1, 'kapittel-1', 'Kapittel 1. Formål, definisjoner og virkeområde');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 2, NULL, 1, 'kapittel-2', 'Kapittel 2. Krav til virksomheter');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 3, NULL, 1, 'kapittel-3', 'Kapittel 3. Krav til ansatte');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 4, NULL, 1, 'kapittel-4', 'Kapittel 4. Melding, krav til parkeringsområde og tilsyn');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 5, NULL, 1, 'kapittel-5', 'Kapittel 5. Særskilt om skilting');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 6, NULL, 1, 'kapittel-6', 'Kapittel 6. Parkeringstillatelse og maksimal parkeringstid på kommunale vilkårsparkeringsplasser');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 7, NULL, 1, 'kapittel-7', 'Kapittel 7. Betaling m.m.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 8, NULL, 1, 'kapittel-8', 'Kapittel 8. Kontrollsanksjon og fjerning');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 9, NULL, 1, 'kapittel-9', 'Kapittel 9. Klageordning');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 10, NULL, 1, 'kapittel-10', 'Kapittel 10. Tilrettelegging for forflytningshemmede');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 11, NULL, 1, 'kapittel-11', 'Kapittel 11. Diverse bestemmelser');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('forskrift/2016-03-18-260', 12, NULL, 1, 'kapittel-12', 'Vedlegg 1. Om skilting');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 1, NULL, 1, 'kapittel-1', 'Kap. I. Innledning.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 2, NULL, 1, 'kapittel-2', 'Kap. II. Trafikk m.m.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 3, NULL, 1, 'kapittel-3', 'Kap. III. Kjøretøyer m.m.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 4, NULL, 1, 'kapittel-4', 'Kap. IV. Fører av kjøretøy m.m.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 5, NULL, 1, 'kapittel-5', 'Kap. V. Reaksjoner ved overtredelse m.m.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 6, NULL, 1, 'kapittel-6', 'Kap. VI. Forskjellige bestemmelser.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 7, NULL, 1, 'kapittel-7', 'Kap. VII. Undersøkelse av trafikkulykker mv.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1965-06-18-4', 8, NULL, 1, 'kapittel-8', 'Kap. VIII. Slutningsbestemmelser.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 1, NULL, 1, 'kapittel-1', 'Kapittel 1. Alminnelige bestemmelser');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 2, NULL, 1, 'kapittel-2', 'Kapittel 2. Overlevering og krav til husrommet');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 3, NULL, 1, 'kapittel-3', 'Kapittel 3. Leie og andre ytelser');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 4, NULL, 1, 'kapittel-4', 'Kapittel 4. Leieprisvern');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 5, NULL, 1, 'kapittel-5', 'Kapittel 5. Partenes plikter i leietiden');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 6, NULL, 1, 'kapittel-6', 'Kapittel 6. Beboerrepresentasjon i visse boligleieforhold');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 7, NULL, 1, 'kapittel-7', 'Kapittel 7. Opptak i husstand og framleie');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 8, NULL, 1, 'kapittel-8', 'Kapittel 8. Personskifte');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 9, NULL, 1, 'kapittel-9', 'Kapittel 9. Leieforholdets varighet – opphør');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 10, NULL, 1, 'kapittel-10', 'Kapittel 10. Tilbakelevering av husrommet ved leieforholdets opphør');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 11, NULL, 1, 'kapittel-11', 'Kapittel 11. Særregler for visse boligleieforhold');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 12, NULL, 1, 'kapittel-12', 'Kapittel 12. Prosessuelle bestemmelser');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/1999-03-26-17', 13, NULL, 1, 'kapittel-13', 'Kapittel 13. Ikrafttredelses- og overgangsbestemmelser. Endringer i andre lover');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 1, NULL, 1, 'kapittel-1', 'Kapittel 1. Innledende bestemmelser');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 2, NULL, 1, 'kapittel-2', 'Kapittel 2. Arbeidsgivers og arbeidstakers plikter');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 3, NULL, 1, 'kapittel-3', 'Kapittel 2 A. Varsling');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 4, NULL, 1, 'kapittel-4', 'Kapittel 3. Virkemidler i arbeidsmiljøarbeidet');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 5, NULL, 1, 'kapittel-5', 'Kapittel 4. Krav til arbeidsmiljøet');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 6, NULL, 1, 'kapittel-6', 'Kapittel 5. Registrerings- og meldeplikt, produsentkrav mv.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 7, NULL, 1, 'kapittel-7', 'Kapittel 6. Verneombud');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 8, NULL, 1, 'kapittel-8', 'Kapittel 7. Arbeidsmiljøutvalg');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 9, NULL, 1, 'kapittel-9', 'Kapittel 8. Informasjon og drøfting');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 10, NULL, 1, 'kapittel-10', 'Kapittel 9. Kontrolltiltak i virksomheten');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 11, NULL, 1, 'kapittel-11', 'Kapittel 10. Arbeidstid');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 12, NULL, 1, 'kapittel-12', 'Kapittel 11. Arbeid av barn og ungdom');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 13, NULL, 1, 'kapittel-13', 'Kapittel 12. Rett til permisjon');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 14, NULL, 1, 'kapittel-14', 'Kapittel 13. Vern mot diskriminering');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 15, NULL, 1, 'kapittel-15', 'Kapittel 14. Ansettelse mv.');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 16, NULL, 1, 'kapittel-16', 'Kapittel 14 A. Konkurransebegrensende avtaler i arbeidsforhold');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 17, NULL, 1, 'kapittel-17', 'Kapittel 15. Opphør av arbeidsforhold');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 18, NULL, 1, 'kapittel-18', 'Kapittel 16. Arbeidstakernes rettigheter ved virksomhetsoverdragelse');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 19, NULL, 1, 'kapittel-19', 'Kapittel 17. Tvister om arbeidsforhold');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 20, NULL, 1, 'kapittel-20', 'Kapittel 18. Tilsynet med loven');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 21, NULL, 1, 'kapittel-21', 'Kapittel 19. Straff');
INSERT INTO seksjoner (dokument_id, nr, forelder_nr, niva, seksjon_id, overskrift) VALUES ('lov/2005-06-17-62', 22, NULL, 1, 'kapittel-22', 'Kapittel 20. Avsluttende bestemmelser');
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44541, 'forskrift/2016-03-18-260', 1, 1, 'kapittel-1-paragraf-1', '§ 1', 'Formål', 'Formålet med denne forskriften er å:
a. sikre en forutsigbar, balansert og forbrukervennlig utøvelse av parkeringsvirksomhet,
b. sikre at parkeringstilbudet er universelt utformet,
c. sikre at parkeringsvirksomhet utøves med god kvalitet og mest mulig likt uavhengig av hvem som er tilbyder,
d. bidra til likere konkurranseforhold mellom tilbydere av parkeringstjenester og
e. legge til rette for offentlig kontroll av virksomheten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44542, 'forskrift/2016-03-18-260', 2, 1, 'kapittel-1-paragraf-2', '§ 2', 'Definisjoner', 'I denne forskriften forstås med:
a. Vilkårsparkering: parkering mot betaling, med tidsbegrensning med eller uten dokumentasjonsplikt, på oppstillingsvilkår, med krav om parkeringstillatelse for forflytningshemmede eller på andre vilkår.
b. Parkering: Enhver hensetting av kjøretøy, selv om føreren ikke forlater det. Unntatt er kortest mulig stans for av- eller påstigning eller av- eller pålessing, jf. forskrift om kjørende og gående trafikk § 1 bokstav k.
c. Avgiftsbelagt kommunal parkeringsplass: parkeringsplass som driftes og håndheves av en kommune eller heleide kommunale selskaper, hvor det tilbys vilkårsparkering mot betaling. Unntatt er tilfeller der kommunen eller heleid kommunalt selskap har inngått skriftlig avtale om å håndheve for private på et område utenfor den offentlige ferdselsåren hvor det er åpenbart at plassen likevel driftes av private. Statens vegvesen avgjør i tvilstilfelle om en avgiftsbelagt parkeringsplass er kommunal.
d. Håndheving: både ileggelse av kontrollsanksjoner og beslutning om fjerning av kjøretøy jf. § 38 og § 42.
e. Ladbar motorvogn: motorvogn som helt eller delvis drives frem av elektrisk motor og som har batterier som kan lades direkte fra strømnettet.
f. Private skilt: skilt som ikke er regulert i skiltforskriften eller denne forskriften med vedlegg.
g. Offentlig ferdselsåre: Ferdselsdelen av offentlig veg, beregnet på trafikk med motorvogn, med integrerte arealer som kantsteinsparkering og lignende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44543, 'forskrift/2016-03-18-260', 3, 1, 'kapittel-1-paragraf-3', '§ 3', 'Virkeområde', 'Denne forskriften gjelder for vilkårsparkering av motorvogn eller tilhenger til motorvogn (heretter kun omtalt som «motorvogn») på veg åpen for alminnelig ferdsel. Forskriften gjelder likevel ikke for liten elektrisk motorvogn. På områder hvor det kun forestås fjerning jf. § 38 eller § 42, gjelder ikke kravene i kapittel 3.

Forskriften gjelder ikke for parkering reservert for særskilte grupper på områder som er fysisk avgrenset ved bom, kjetting eller annen måte. Forskriften gjelder heller ikke parkering reservert for særskilte grupper på områder som ikke er fysisk avstengt og det ved privat skilting i samsvar med § 26 fremgår at parkering ikke tilbys allmenheten. Dersom det ilegges kontrollsanksjoner på slike steder gjelder likevel kravene i kapittel 3 (personell), kapittel 8 (sanksjon) og kapittel 9 (klage). Dersom det kun forestås fjerning jf. § 38 eller § 42 gjelder bare kravene i kapittel 8 og 9.

Denne forskrift kapittel 3, 8 og 9 gjelder også for håndheving av parkeringsrestriksjoner på og langs privat veg og utenfor veg. Dersom det på stedet kun forestås fjerning gjelder bare kravene i kapittel 8 og 9.

Forskriften gjelder ikke midlertidig tilbud om parkering mot betaling der betalingen skjer til en fysisk person og det ikke ilegges sanksjoner. Forskriften gjelder heller ikke for områder med veiledende skilt og oppmerking som ikke håndheves. Statens vegvesen avgjør i tvilstilfelle om vilkårene er oppfylt.

Forskriften gjelder både virksomhet som tilbys av private og av forvaltningsorgan, jf. forvaltningsloven § 1.

Forskriften gjelder også for politiets håndheving av vilkårsparkering, som ikke er avgiftsparkering, med unntak av kapittel 2 og kapittel 3.

Forskriften gjelder ikke i kommuner eller på områder der eneste tilbud om vilkårsparkering er reserverte plasser for forflytningshemmede og hvor kommunen ikke har fått delegert håndhevingsmyndighet. Dersom private håndhever på slike steder gjelder likevel kravene i kapittel 3 (personell), kapittel 8 (sanksjon) og kapittel 9 (klage). Dersom det er politiet som håndhever, gjelder kun kapittel 8 og 9.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44544, 'forskrift/2016-03-18-260', 4, 2, 'kapittel-2-paragraf-1', '§ 4', 'Melding', 'For å tilby vilkårsparkering må virksomheten registrere utfylt egenmeldingsskjema i Statens vegvesens register.

Det enkelte parkeringsområde må tilfredsstille kravene i § 16, og kapittel 5 og 10.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44545, 'forskrift/2016-03-18-260', 5, 2, 'kapittel-2-paragraf-2', '§ 5', 'Krav til organisasjonsform og registrering', 'Foretak, enkeltpersonforetak eller forvaltningsorgan kan drive vilkårsparkering. Foretak må være registret i Foretaksregisteret og ha fast forretningssted i riket.

Enkeltpersonforetak må være registrert i Enhetsregisteret. Organisasjonsnummer må oppgis i egenmeldingsskjemaet. Innehaveren må dessuten:
a. være fylt 18 år og
b. være statsborger i stat som er part i EØS-avtalen, eller ha fast bopel i Norge.

Dersom foretaket eller enkeltpersonforetaket har daglig leder, må også denne personen oppfylle vilkårene i annet ledd bokstav a) og b).

Selskap, stiftelse eller annen sammenslutning, når samtlige medlemmer av styret i et aksjeselskap eller annen sammenslutning med begrenset ansvar oppfyller kravene i annet ledd bokstav a og b, kan drive vilkårsparkering. Det samme gjelder for ansvarlig selskap eller kommandittselskap, når samtlige fullt ansvarlige deltakere oppfyller kravene i annet ledd bokstav a og b. Leder og nestleder av forvaltningsorganet må også oppfylle kravene i annet ledd bokstav a og b.

Midlertidige tjenesteytere etablert i annen EØS-stat, er unntatt fra krav til registrering i Foretaksregisteret eller Enhetsregisteret og krav til forretningssted i riket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44546, 'forskrift/2016-03-18-260', 6, 2, 'kapittel-2-paragraf-3', '§ 6', 'Plikt til å inneha dekkende ansvarsforsikring', 'Virksomhet som skal tilby vilkårsparkering eller andre som i henhold til avtale skal håndheve vilkårsparkering må inneha dekkende forsikring for det ansvar som kan pådras. Forsikringen må tegnes før virksomheten kan tilby vilkårsparkering.

Krav til dekkende ansvarsforsikring gjelder også virksomhet som drives av forvaltningsorgan. Dersom forvaltningsorganet kan dokumentere at det på annen måte kan dekke et eventuelt ansvar som organet kan pådra seg på lik linje med en forsikring som angitt i første ledd, kan Statens vegvesen frita organet fra dette kravet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44547, 'forskrift/2016-03-18-260', 7, 2, 'kapittel-2-paragraf-4', '§ 7', 'Særskilt om vilkårsparkering på offentlig ferdselsåre', 'Kommunen har et særlig ansvar for å ivareta trafikale hensyn ved regulering av vilkårsparkering på offentlig ferdselsåre.

Kommunen kan håndheve selv, samarbeide med eller overlate håndheving av vilkårsparkering på offentlig ferdselsåre til andre kommuner eller heleide kommunale selskaper. Før håndheving overlates til andre, må skilt- og vegmyndighet høres der disse er andre enn kommunen.

Dersom kommunen overlater håndheving av vilkårsparkering på offentlig ferdselsåre til andre kommuner eller heleide kommunale selskaper, skal kommunen sikre at behovet for trafikkstyring ivaretas. Dette innebærer blant annet at kommunen, skilt- og vegmyndigheten skal ha tilstrekkelig rett og plikt til trafikkstyring.

Det kan ikke innføres avgiftsparkering på offentlig ferdselsåre uten at kommunen har påtatt seg ansvar for håndheving etter forskrift 18. mars 2016 om offentlig parkeringsgebyr.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44548, 'forskrift/2016-03-18-260', 8, 3, 'kapittel-3-paragraf-1', '§ 8', 'Generelle krav til ansatte', 'Den som skal tilsettes i virksomhet som omfattes av denne forskrift og som skal utføre kontrolltjeneste med vilkårsparkering eller har oppgaver direkte knyttet til slik kontrolltjeneste, må være fylt 18 år.

Virksomhetens ledelse har plikt til å sørge for at ansatte som skal utføre kontrolltjeneste med vilkårsparkering, oppfyller kravene i forskriften. Ansatte som utfører kontroll med vilkårsparkering skal ikke gis lønn, bonus eller andre ytelser som er avhengig av antall ilagte reaksjoner etter § 36 eller § 38.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44549, 'forskrift/2016-03-18-260', 9, 3, 'kapittel-3-paragraf-2', '§ 9', 'Krav til opplæring', 'Den som skal utføre kontrolltjeneste med vilkårsparkering må ha gjennomført og bestått godkjent opplæring. Opplæringen skal til sammen ha en varighet på minst 70 skoletimer og bestå av:
a. en innledende teoretisk del og praksisopplæring i kontrolltjeneste på til sammen minst 30 skoletimer og med avsluttende prøve,
b. praksisopplæring og oppsummerende teorikurs på minst 30 skoletimer og med avsluttende prøve og
c. bestått regodkjenningsprøve hvert femte år.

Opplæringen i første ledd bokstav a) skal inneholde generell teoretisk opplæring i vilkårsparkeringsregler, virksomhetens rutiner, innføring i uniformbruk og opptreden i tjeneste.

Opplæringen i første ledd bokstav b) skal inneholde teoretisk opplæring i formålet med parkeringsvirksomheten, forholdet til vaktvirksomhet, helse-, miljø- og sikkerhetsarbeid, uniformbruk, rettslige rammer for regulering av vilkårsparkering og fjerning av motorvogn, bevis, sanksjonering, etikk, kommunikasjon og kundebehandling.

Praksisopplæringen i første ledd a) og b) skal skje gjennom praktisk arbeidsutførelse med veileder med tilstrekkelig kompetanse.

Etter endt opplæring skal den som skal utføre kontrolltjeneste vise evne til å arbeide i samsvar med lover, forskrifter og avtaler og til å ta gode etiske og skjønnsmessige avgjørelser.

Kontrolltjeneste kan utføres uten å ha gjennomført opplæring i første ledd bokstav b), dersom prøve etter første ledd bokstav a) er bestått og virksomheten på annen måte sikrer at utførelsen skjer i samsvar med reglene. Opplæringen må i alle tilfeller være gjennomført og bestått innen ett år etter ansettelse. Statens vegvesen kan i særlige tilfeller forlenge denne perioden med inntil 6 måneder. Kravene gjelder også for vikarer og midlertidig ansatte.

Regodkjenningsprøve kan kun avlegges hos virksomhet som ikke har begrensninger i sin godkjenning slik at opplæring kan tilbys alle, ikke bare egne ansatte. Regodkjenningsprøven kan ikke avlegges hos den virksomhet man er ansatt i.

Opplæring skal baseres på undervisningsplan og prøveordning, herunder avsluttende prøve og regodkjenningsprøve, godkjent av Statens vegvesen, som også kan fastsette gebyr for slike godkjenninger. Tilrettelagt skriftlig eller muntlig prøve kan tillates der kandidaten har lese- og skrivevansker. Statens vegvesen kan stille nærmere krav til undervisningsplan og gjennomføring av prøve.

Opplæringspersonell skal ha tilstrekkelig faglig opplæringskompetanse for å sikre tilfredsstillende kvalitet i opplæringen. Vegdirektoratet kan stille krav til faglig opplæringskompetanse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44550, 'forskrift/2016-03-18-260', 10, 3, 'kapittel-3-paragraf-3', '§ 10', 'Yrkeskvalifikasjoner fra annen EØS-stat', 'Dersom yrkesutøver med kvalifikasjoner ervervet fra en annen EØS-stat, Sveits eller Storbritannia ønsker å etablere seg i Norge, kan Statens vegvesen godkjenne dennes yrkeskvalifikasjon som et alternativ til opplæringskravene i § 9, jf. reglene i yrkeskvalifikasjonsloven og forskrift 22. desember 2017 nr. 2384 om godkjenning av yrkeskvalifikasjoner.

Dersom en yrkesutøver med kvalifikasjoner ervervet fra en annen EØS-stat eller Sveits skal utføre midlertidig tjenesteytelse i Norge, kreves det forhåndsmelding i tråd med reglene i forskrift om godkjenning av yrkeskvalifikasjoner § 2-2. Følgende dokumenter skal leveres i tillegg til forhåndsmeldingen:
1. bevis på identitet og nasjonalitet,
2. bekreftelse på at yrkesutøveren er lovlig etablert i en annen EØS-stat eller Sveits og at vedkommende har rett til å arbeide i staten,
3. bevis på yrkeskvalifikasjoner eller bekreftelse på at yrkesutøveren har arbeidet i minimum ett år i løpet av de siste ti årene i etableringsstaten dersom verken yrket eller utdanningen er lovregulert der.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44551, 'forskrift/2016-03-18-260', 11, 3, 'kapittel-3-paragraf-4', '§ 11', 'Uniformering', 'Den som utfører kontrolltjeneste med vilkårsparkering, skal bære uniform. Uniformen må ikke kunne forveksles med politiets, forsvarets, tollvesenets eller Statens vegvesens uniformer. Det skal fremgå av uniformen om personen er godkjent kontrollør med vilkårsparkering eller er under opplæring. Uniformen skal være tydelig merket med virksomhetsnavn og ordet «parkeringsvakt», «parkeringsbetjent», «trafikkbetjent», «bybetjent» eller «parkeringskontrollør» på brystet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44552, 'forskrift/2016-03-18-260', 12, 3, 'kapittel-3-paragraf-5', '§ 12', 'Legitimasjonskort', 'Den som utfører kontrolltjeneste med vilkårsparkering skal bære synlig og lesbart legitimasjonskort og plikter å oppgi virksomhetens navn og tjenestenummer når dette forlanges av den som tjenestehandlingen direkte angår, politiet eller Statens vegvesen.

Kortet skal på forsiden inneholde:
a. virksomhetens navn og organisasjonsnummer,
b. «parkeringsvakt», «parkeringsbetjent», «trafikkbetjent», «bybetjent» eller «parkeringskontrollør». For person som ikke har fullført utdanningen skal «under opplæring» fremgå,
c. bilde av kontrolløren,
d. identitetsnummer (tjenestenummer) og
e. utløpsdato

På baksiden skal kortet inneholde:
a. dato for når kontrolløren ble godkjent som kontrollør eller regodkjent og
b. utstedelsesdato.

Kortet skal ha gyldighet på inntil fem år fra fullført og bestått opplæring eller siste regodkjenning. Ved endringer i opplysningene på kortet skal det utstedes nytt kort.

Kortet kan vise virksomhetens logo og farger, men fargebruken skal ikke gjøre opplysningene på kortet vanskelige å lese.

Virksomheten er ansvarlig for utstedelse av legitimasjonskort til personer som utfører kontrolltjeneste med vilkårsparkering på vegne av virksomheten og skal ha oversikt over de til enhver tid gyldige kort.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44553, 'forskrift/2016-03-18-260', 13, 3, 'kapittel-3-paragraf-6', '§ 13', 'Innlevering og inndragelse av legitimasjonskort', 'Legitimasjonskortet skal innleveres når den som utfører kontrolltjeneste med vilkårsparkering slutter i virksomheten eller når gyldighetstiden på kortet utløper. Virksomheten er ansvarlig for å sørge for at kort blir innlevert.

Virksomheten skal om nødvendig sørge for at kortet inndras når den som utfører kontrolltjeneste ikke lenger oppfyller vilkårene for å utføre tjeneste.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44554, 'forskrift/2016-03-18-260', 14, 4, 'kapittel-4-paragraf-1', '§ 14', 'Opphevet', '', '2023-12-04', 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44555, 'forskrift/2016-03-18-260', 15, 4, 'kapittel-4-paragraf-2', '§ 15', 'Bortfall av rett til å drive vilkårsparkering', 'Retten til å tilby vilkårsparkering bortfaller dersom virksomheten tas under konkursbehandling eller dersom innehaveren av enkeltpersonforetaket dør. Et konkursbo eller dødsbo har rett til å fortsette virksomheten i den utstrekning det finnes hensiktsmessig med sikte på avvikling eller overføring av virksomheten til ny eier, likevel ikke utover 6 måneder uten tillatelse fra Statens vegvesen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44556, 'forskrift/2016-03-18-260', 16, 4, 'kapittel-4-paragraf-3', '§ 16', 'Krav til det enkelte parkeringsområde', 'a. Før virksomheten kan tilby vilkårsparkering regulert med skilt som vist i denne forskrift, skal skiltplan og tilleggsinformasjon for det enkelte parkeringsområde være registrert i sentralt elektronisk register. Dersom dette ikke er gjort, kan det ikke håndheves.
Området skal være skiltet i tråd med skiltplanen. Virksomheten har ansvaret for å utarbeide og registrere slik skiltplan. Skiltplanen skal inneholde kart over parkeringsområdets utforming, vise totalt antall plasser og plassering av skilt og betalingsautomater. Tilleggsinformasjonen skal oppsummere tallmaterialet fra skiltplanen og inneholde en vurdering fra virksomheten i henhold til § 62. Opplysningene skal gis ved utfylling av skjema for tilleggsinformasjon. Vegdirektoratet kan stille nærmere krav til skiltplan.
Alle endringer i skiltplanen med tilleggsinformasjon skal registreres i sentralt elektronisk register med angivelse av når endringen trer i kraft. Før endringer i skiltplanen er meldt inn i registeret, kan endringene ikke håndheves. Innmeldingskravet gjelder likevel ikke for nødvendige reguleringsendringer på inntil 48 timer og heller ikke for midlertidige endringer som følge av akutte hendelser.
b. Vilkårsparkering vist med skiltforskriftskilt skal følge reglene om skiltvedtak, jf. skiltforskriften § 28, jf. § 36. Vilkårsparkering vist med skiltforskriftskilt kan håndheves når vedtak er fattet og skilt er satt opp og avdekket jf. skiltforskriften § 2 nr. 1. Virksomhetene skal likevel registrere skiltplan i sentralt elektronisk register slik som omtalt i paragrafen her bokstav a, andre ledd. Kravet om innmelding av skiltplan gjelder også for arbeid på offentlig veg som følger reglene i skiltforskriften kap. 14, så lenge arbeidet ikke faller inn under bokstav a, tredje ledd, siste punktum (midlertidige endringer mv.) i paragrafen her. Virksomhetene er ved slikt arbeid likevel fritatt fra plikten til fortløpende oppdatering av endringer i skiltplan med tilleggsinformasjon.

Virksomhetene bærer selv kostnader ved utforming av skiltplan, produksjon og oppsetting av skilt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44557, 'forskrift/2016-03-18-260', 17, 4, 'kapittel-4-paragraf-4', '§ 17', 'Register over virksomheter og parkeringsområder', 'Vegdirektoratet er ansvarlig for etablering og drift av et elektronisk register for opplysninger om den enkelte virksomhet, skiltplan og tilleggsinformasjon for det enkelte parkeringsområde etter § 16. Registeret kan for øvrig kun inneholde opplysninger som er nødvendig for gjennomføring av Statens vegvesens oppgaver etter denne forskrift.

Vegdirektoratet kan ved forskrift fastsette gebyr for dekning av kostnader til etablering og drift av registeret.

Vegdirektoratet kan pålegge virksomheten å innlevere informasjon til registeret i den grad informasjonen er nødvendig og ikke uten vesentlig ulempe kan finnes på annen måte.

Allmenheten skal sikres tilstrekkelig tilgang til informasjon om alle innmeldte virksomheter og skiltplaner som omfattes av denne forskrift.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44558, 'forskrift/2016-03-18-260', 18, 4, 'kapittel-4-paragraf-5', '§ 18', 'Opplysnings- og rapporteringsplikt', 'Virksomhet som tilbyr vilkårsparkering og andre som i henhold til avtale skal håndheve vilkårsparkering plikter å gi Statens vegvesen opplysninger, dokumentasjon og annen bistand nødvendig for tilsyn med at drift og håndheving skjer i samsvar med denne forskrift.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44559, 'forskrift/2016-03-18-260', 19, 4, 'kapittel-4-paragraf-6', '§ 19', 'Tilsyn og reaksjon ved overtredelse', 'Statens vegvesen skal føre tilsyn med at vilkårsparkering drives og håndheves i samsvar med denne forskrift.

Statens vegvesen kan gi pålegg til virksomheten om å rette forhold som ikke er i samsvar med denne forskrift. Det skal fastsettes en rimelig frist for retting og opplyses om at forholdet kan følges opp med tvangsmulkt og eventuelt avskilting etter § 20.

Statens vegvesen kan fastsette tvangsmulkt dersom virksomheten ikke etterkommer pålegg om retting innen fastsatt frist. Det kan fastsettes at mulkten løper så lenge det ulovlige forholdet varer og/eller at den ilegges som et engangsbeløp. Tvangsmulkten skal fastsettes etter en helhetlig vurdering av situasjonen, herunder av overtredelsens art, alvorlighet, om det foreligger gjentakelser, om noen tilknyttet virksomheten kan klandres for overtredelsen og hva som er gjort for å rette opp i forholdet. Tvangsmulkten ilegges den ansvarlige virksomheten. Vegdirektoratet kan i forskrift fastsette tvangsmulktens størrelse, herunder standardiserte satser for ulike overtredelser.

Statens vegvesen kan også gi pålegg om retting, ilegge tvangsmulkt, fatte vedtak om avskilting og om forbud mot oppsetting av nye skilt til virksomheter som ikke har oppfylt meldeplikten etter § 4 første ledd.

Statens vegvesen skal i samsvar med lov 22. juni 2018 nr. 83 om kommuner og fylkeskommuner § 30-6, andre ledd underrette og involvere statsforvalteren ved tilsyn overfor kommunale parkeringsvirksomheter.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44560, 'forskrift/2016-03-18-260', 20, 4, 'kapittel-4-paragraf-7', '§ 20', 'Avskilting av område', 'Dersom kravene til parkeringsområdet etter § 16 eller håndheving på området ikke oppfyller forskriftens krav, kan Statens vegvesen fatte vedtak om å avskilte det aktuelle parkeringsområdet, jf. § 22 og nedlegge forbud mot å sette opp nye skilt til forholdene er rettet. I vurderingen skal det blant annet legges vekt på overtredelsens art, alvorlighet, om det foreligger gjentakelser, om noen tilknyttet virksomheten kan klandres for overtredelsen og hva som er gjort for å rette opp i forholdet. Statens vegvesen kan selv ta ned aktuelle skilt på virksomhetens regning når fristen for å ta ned skilt er utløpt.

Statens vegvesen kan beslutte at vedtak etter første ledd skal gjelde flere eller alle parkeringsområder som drives av samme virksomhet. Denne adgangen skal bare benyttes der det er avdekket alvorlige regelverksbrudd og disse antas å ha betydning for flere parkeringsområder underlagt samme virksomhet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44561, 'forskrift/2016-03-18-260', 21, 4, 'kapittel-4-paragraf-8', '§ 21', 'Tilsynsgebyr', 'Vegdirektoratet kan fastsette forskrift om gebyr for dekning av kostnader med tilsyn av virksomheter som tilbyr vilkårsparkering.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44562, 'forskrift/2016-03-18-260', 22, 5, 'kapittel-5-paragraf-1', '§ 22', 'Skilting', 'Regulering av vilkårsparkering skal gjøres ved bruk av skilt som angitt i vedlegg 1. Skilt som er vist i vedlegg 1 er å anse som offentlige skilt.

Sentralt på det enkelte parkeringsområde skal det plasseres informasjonsskilt med følgende opplysninger:
a. virksomhetens navn og telefonnummer,
b. vilkår for bruker, herunder angivelse av eventuell betalingsplikt for forflytningshemmede,
c. reaksjoner ved brudd på vilkår og
d. summarisk om klageadgang.

Der vilkårsparkering tilbys på områder hvor skilting etter annet ledd anses uhensiktsmessig kan informasjonen gis på annen måte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44563, 'forskrift/2016-03-18-260', 23, 5, 'kapittel-5-paragraf-2', '§ 23', 'Privat skilting ved vilkårsparkering', 'På område eller vegstrekning, der det benyttes skilt som angitt i vedlegg 1, kan det ikke benyttes private skilt til parkeringsregulering. Veiledende anvisninger er imidlertid tillatt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44564, 'forskrift/2016-03-18-260', 24, 5, 'kapittel-5-paragraf-3', '§ 24', 'Plassering av motorvogn og dokumentasjon på tidsbegrenset parkering', 'Motorvognen skal plasseres som anvist ved skilt eller oppmerking, og innenfor oppmerket felt der dette finnes. Motorvognen skal parkeres i feltets lengderetning. Elektriske og hydrogendrevne motorvogner kan likevel på offentlig ferdselsåre parkere på tvers av oppmerket felt, dersom alle hjulene er innenfor feltet og overhenget ut fra feltet ikke overstiger 40 cm. På disse vilkår kan flere slike motorvogner parkere i samme felt. Også flere motorsykler eller mopeder kan parkeres i samme felt. Oppmerking har ikke selvstendig parkeringsregulerende betydning og kan kun håndheves i tilknytning til regulering angitt ved skilt.

Dersom det på plass med tidsbegrenset parkering er innført påbud om bruk av parkeringsskive, skal fører umiddelbart etter at motorvognen er parkert, stille viseren på parkeringsskiven på det tidspunkt motorvognen ble parkert. Gjelder det ikke tidsbegrenset parkering på det tidspunktet motorvognen ble parkert, stilles viseren på parkeringsskiven på det tidspunkt det igjen innføres tidsbegrenset parkering.

Registrering eller trekk av billett for å dokumentere tidsbegrenset parkering skal skje umiddelbart etter parkering. Dersom det er stilt krav om billett fra parkeringsautomat som angir tidspunkt for når gratisparkeringen utløper, skal billetten plasseres godt synlig bak frontruten. Har motorvognen ikke frontrute plasseres kvitteringen på et annet godt synlig sted.

Bestemmelsene i annet og tredje ledd gjelder ikke der parkeringstillatelse for forflytningshemmet ligger godt synlig for kontroll.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44565, 'forskrift/2016-03-18-260', 25, 5, 'kapittel-5-paragraf-4', '§ 25', 'Undersøkelsesplikt', 'På parkeringsplass på offentlig ferdselsåre må fører og eier av motorvognen senest 24 timer etter at parkeringsregulerende skilt er satt opp, rette seg etter skiltet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44566, 'forskrift/2016-03-18-260', 26, 5, 'kapittel-5-paragraf-5', '§ 26', 'Særlig om krav til privat skilting', 'På områder som omfattes av § 3 annet ledd annet punktum eller tredje ledd kan det ikke benyttes private skilt som kan forveksles med skilt som angitt i vedlegg 1. Området skal skiltes på en klar og tydelig måte, slik at en alminnelig aktsom fører vil forstå at det på dette området ikke tilbys parkering til allmenheten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44567, 'forskrift/2016-03-18-260', 27, 6, 'kapittel-6-paragraf-1', '§ 27', 'Parkeringstillatelse', 'Parkering på eller langs offentlig veg skal som utgangspunkt være tilgjengelig for allmennheten. Kommunen kan likevel utstede tillatelse til parkering for bestemte motorvogner og grupper eller for personer med behov for særskilt parkeringsadgang på kommunale vilkårsparkeringsplasser. Skiltmyndigheten avgjør om, og i hvilket omfang, slike parkeringsplasser skal opprettes. Kommunen må ovenfor skiltmyndigheten begrunne det særskilte behovet for slik parkeringsadgang.

Det må fremgå av skilt på stedet hvem reservasjonen gjelder for. Dersom det ikke kan framgå konkret av skiltet hvem reservasjonen gjelder, skal underskilt «Med særskilt tillatelse» benyttes. Da må kommunen utstede særskilt tillatelse, jf. § 30. Det er kun en bestemt kommunal instans som kan utstede slike tillatelser.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44568, 'forskrift/2016-03-18-260', 28, 6, 'kapittel-6-paragraf-2', '§ 28', 'Unntak fra maksimaltid', 'Kommunen kan på parkeringsplass på kommunale vilkårsparkeringsplasser gi parkerende med særskilt behov tillatelse til å parkere motorvogn ut over eventuell maksimaltid på steder regulert for parkering med skilt 552 eller skilt 376, jf. skiltforskriften § 8 og § 12.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44569, 'forskrift/2016-03-18-260', 29, 6, 'kapittel-6-paragraf-3', '§ 29', 'Boligsoneparkering', 'Kommunen kan i nærmere avgrensede områder på kommunale vilkårsparkeringsplasser, etter behovsprøving, reservere parkering for parkerende bosatt i området eller for andre med særlig behov for slik parkering.

Innføring av boligsoneparkering skjer ved særskilt lokal forskrift. Forskriften skal fastsette på hvilke vilkår man får tildelt boligsoneparkering. Den lokale forskriften skal kunngjøres i Norsk Lovtidend avdeling II.

Slik forskrift kan ikke innsnevre beboernes adgang til å kunne parkere i det området de bor, ved at kommunen begrenser adgangen til kun å gjelde bestemt(e) kjøretøygruppe(r). Slike begrensninger kan kun skje ved hjelp av offentlige skilt fastsatt av skiltmyndigheten. Forskriften kan heller ikke begrense adgangen til boligsoneparkering til å kun gjelde registrert eier av kjøretøy. Det er tilstrekkelig at det forefinnes nødvendig dokumentasjon på at søker disponerer kjøretøy og at vedkommende bor eller har tilhold i sonen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44570, 'forskrift/2016-03-18-260', 30, 6, 'kapittel-6-paragraf-4', '§ 30', 'Utstedelse av særskilt parkeringstillatelse', 'Tillatelse etter § 27 til § 29 utstedes for det tidsrom kommunen mener det er behov for. Når tillatelsen løper ut skal kommunen foreta ny behovsvurdering.

Tillatelsen skal inneholde navnet på kommunen, og motorvognens kjennemerke eller navnet på person eller næringsbedrift som tillatelsen gjelder for.

Ved misbruk, endrede forutsetninger, omdisponering av areal e.l. kan kommunen trekke tillatelsen tilbake.

Tillatelse må plasseres godt synlig bak frontruten.

Den som har særskilt parkeringstillatelse, har plikt til å underrette kommunen om endrede forhold som kan ha betydning for tillatelsen.

Avslag på søknad om særskilt parkeringstillatelse kan påklages til kommunestyret eller en særskilt klagenemnd oppnevnt av kommunestyret. Vegdirektoratet er likevel klageinstans når vedtak om avslag er truffet i kommunestyret.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44571, 'forskrift/2016-03-18-260', 31, 7, 'kapittel-7-paragraf-1', '§ 31', 'Generelt om betaling', 'Der det tilbys vilkårsparkering for allmennheten mot betaling skal det være mulig å betale på forskudd og på etterskudd. I tilfeller hvor det foreligger særlig tungtveiende grunner kan Statens vegvesen gjøre unntak fra dette kravet.

Betaling og/eller registrering skal skje umiddelbart etter parkering. Eventuell kvittering for betalt parkering skal, om ikke annet fremgår av kvitteringen, plasseres godt synlig bak frontruten. Har motorvognen ikke frontrute plasseres kvitteringen på et annet godt synlig sted.

Det er brukerens ansvar å påse at man betaler for riktig kjøretøy, herunder at man taster rett kjennemerke ved betalingen. Ved elektronisk betaling/registrering må brukeren gis mulighet til å kontrollere at vedkommende har tastet korrekt kjennemerke før betaling/registrering bekreftes.

Der det tilbys vilkårsparkering mot betaling skal betalingssystemet utformes mest mulig brukervennlig. Betalingsløsningen skal være universelt utformet i samsvar med § 32.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44572, 'forskrift/2016-03-18-260', 32, 7, 'kapittel-7-paragraf-2', '§ 32', 'Universelt utformet betalingsløsning', 'Der det tilbys vilkårsparkering til allmennheten mot betaling skal det tilbys en universelt utformet betalingsautomat og en betalingsløsning som ikke forutsetter bruk av automat eller annen fysisk innretning på parkeringsstedet, men som den parkerende ved hjelp av mobiltelefon eller annen teknologi kan betjene fra motorvognen.

Med universelt utformet betalingsautomat menes en automat som har hinderfri og tilstrekkelig adkomstareal, god generell brukbarhet på betjenings- og lesepanel, samt hensiktsmessig betjeningshøyde. Automat som oppfyller kravene i Statens vegvesens håndbok V 129 punkt 11.2 og 11.3 skal anses som en slik universelt utformet betalingsautomat.

Kravet til universelt utformet betalingsautomat gjelder likevel ikke der det ellers er automat som sikrer likeverdig tilgjengelighet til parkeringstilbudet.

Vegdirektoratet kan fastsette nærmere bestemmelser om hva som anses som en universelt utformet betalingsløsning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44573, 'forskrift/2016-03-18-260', 33, 7, 'kapittel-7-paragraf-3', '§ 33', 'Betalingsfritak for forflytningshemmede', 'Forflytningshemmede med parkeringstillatelse har betalingsfritak på avgiftsbelagte kommunale parkeringsplasser etter forskrift 18. mars 2016 nr. 264 om parkeringstillatelse for forflytningshemmede § 2 første ledd b). De har tilsvarende betalingsfritak på andre avgiftsbelagte vilkårsparkeringsplasser vist med skilt 552 som hovedskilt eller soneskilt. De har også betalingsfritak på andre avgiftsbelagte vilkårsparkeringsplasser, med mindre betalingsplikt er angitt på informasjonsskilt og eventuelt underskilt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44574, 'forskrift/2016-03-18-260', 34, 7, 'kapittel-7-paragraf-4', '§ 34', 'Betalingsfritak for elektrisk og hydrogendrevne motorvogner', 'Kommuner kan innføre betalingsfritak for elektrisk og hydrogendrevet motorvogn på avgiftsbelagte kommunale parkeringsplasser.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44575, 'forskrift/2016-03-18-260', 35, 7, 'kapittel-7-paragraf-5', '§ 35', 'Lademulighet', 'På parkeringsområdet skal det tilbys lademulighet for ladbar motorvogn på et tilstrekkelig antall parkeringsplasser, det vil si at det i alminnelighet til enhver tid er en ledig plass med lademulighet. Virksomheten har likevel ikke plikt til å tilby lademulighet på mer enn seks prosent av det totale antallet plasser.

Statens vegvesen kan gjøre unntak fra kravet i første ledd dersom investerings- eller driftskostnadene blir urimelig høye.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44576, 'forskrift/2016-03-18-260', 36, 8, 'kapittel-8-paragraf-1', '§ 36', 'Kontrollsanksjon', 'Ved overtredelse av vilkårene for parkering kan det ilegges en kontrollsanksjon på kr 660.

For brudd på dokumentasjonsplikt ved tidsbegrenset gratisparkering er satsen kr 330.

For overtredelse av vilkårene på plass reservert for forflytningshemmede med parkeringstillatelse er satsen kr 990. Forflytningshemmede med parkeringstillatelse som overtrer vilkårene på slik plass kan ilegges kontrollsanksjon etter første ledd.

Fører av motorvogn skal gis rimelig frist til å sette seg inn i parkeringsvilkårene og å foreta nødvendig betaling/registrering før kontrollsanksjon kan ilegges. Det kan ilegges kontrollsanksjon tidligst fem minutter etter at parkeringstiden er utløpt.

Satsene reguleres hvert femte år i takt med endringer i konsumprisindeksen.

Ved overtredelse av vilkårene for avgiftsparkering i over tre døgn skal kontrollsanksjonen settes til prisen for den parkeringstid som er benyttet i tillegg til det beløp som fremkommer i første til tredje ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44577, 'forskrift/2016-03-18-260', 37, 8, 'kapittel-8-paragraf-2', '§ 37', 'Betalingsansvar og kontrollsanksjonens lovlighet', 'a. Kontrollsanksjon skal ilegges fører av motorvognen på stedet. Dersom føreren er en annen enn den som var registrert som eier ved tidspunktet for overtredelsen, er de solidarisk ansvarlig for betalingen, med mindre motorvognen var fratatt eieren ved et lovbrudd med en strafferamme på mer enn ett år. Der føreren er kjent, må føreren først kreves for beløpet. Dersom kontrollsanksjon ikke er betalt 30 dager etter at betalingsoppfordring er sendt fører, kan beløpet kreves inn fra registrert eier av motorvognen.
Solidaransvaret etter første ledd omfatter også kostnader ved fjerning og oppbevaring av motorvogn.
Blanketten for sanksjonen skal normalt festes på motorvognen sammen med nødvendig informasjon om innbetaling eller leveres føreren. I særlige tilfeller kan den likevel sendes fører eller eier i posten.
Betalingsfrist for ilagt kontrollsanksjon skal være minst tre uker etter ileggelse av denne. For fristberegningen gjelder forvaltningsloven § 30 annet ledd tilsvarende. Dersom kontrollsanksjonen ikke betales innen fristen, kan den inndrives som et alminnelig pengekrav. Det kan ikke tas særskilte gebyr for inndriving av kontrollsanksjon, utover det som eventuelt måtte følge av annen lovgivning.
b. Blanketten skal, for at sanksjonen skal anses lovlig ilagt, inneholde informasjon om:
1. hvordan man kan kontakte virksomheten som har ilagt kontrollsanksjonen
2. det faktiske og rettslige grunnlaget for sanksjonen, herunder blant annet hvilken bestemmelse som er overtrådt, sted og tidspunkt for overtredelsen og korrekt kjennemerke for det ilagte kjøretøyet
3. klagerett og klagefrist og at bestridte krav, forutsatt at fristene for klage i kapittel 9 er overholdt, ikke kan sendes til inkasso før kravets rettmessighet er endelig avgjort.
4. at klageretten gjelder uavhengig av om klager har bistand fra advokat eller lignende.
Dersom nr. 1–4 i denne bestemmelsen ikke er ivaretatt, skal sanksjonen oppheves.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44578, 'forskrift/2016-03-18-260', 38, 8, 'kapittel-8-paragraf-3', '§ 38', 'Fjerning av motorvogn', 'Motorvogn kan om nødvendig fjernes fra parkeringsplasser som omfattes av § 3 og tas i forvaring når følgende vilkår er oppfylt:
a. motorvognen står til hinder og i strid med vilkårene for parkering i eller i medhold av denne forskriften,
b. fører/eier av motorvognen er forsøkt varslet og ved kontakt gitt rimelig frist for selv å fjerne motorvognen og
c. det klart fremgår av skilt eller annet hvor føreren kan innhente opplysninger om fjerningen.

Kravet etter første ledd bokstav a om at motorvognen står til hinder gjelder ikke for fjerning fra plass reservert for forflytningshemmede med parkeringstillatelse.

Kravet etter første ledd bokstav b gjelder ikke der varsling vil medføre vesentlig ulempe.

Motorvognen kan fjernes selv om vilkårene i første ledd ikke er oppfylt, når den som er registrerte eier på fjerningstidspunktet har ubetalte kontrollsanksjoner fra samme virksomhet på over 6 000 kr.

Den som rekvirerer fjerning og den som forestår fjerning er begge ansvarlige for at vilkårene for fjerning er oppfylt.

Ved rettmessig fjerning av motorvogn skal virksomheten dekke dokumentert skade på motorvognen oppstått i forbindelse med fjerningen. Ved urettmessig fjerning av motorvogn, skal virksomheten dekke førers/eiers dokumenterte økonomiske tap som følge av fjerningen.

Dersom motorvogn tilbys flyttet når fjerning er igangsatt, men ikke fullført, kan ikke motorvognen fjernes. Kostnadene knyttet til fjerningen kan likevel kreves dekket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44579, 'forskrift/2016-03-18-260', 39, 8, 'kapittel-8-paragraf-4', '§ 39', 'Varsling ved fjerning', 'Dersom motorvogn blir fjernet, skal eier av motorvognen og fører av motorvognen, dersom denne er kjent, så snart som mulig varsles om:
a. fjerningen og grunnlaget for denne,
b. hvor motorvognen er blitt plassert og
c. kostnadene som har påløpt/kan påløpe i forbindelse med fjerningen.

Eventuell kostnad for uavhentede motorvogner kan ikke påløpe fører eller eier av motorvogn før vedkommende har fått eller burde fått kunnskap om opplysningene nevnt i første ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44580, 'forskrift/2016-03-18-260', 40, 8, 'kapittel-8-paragraf-5', '§ 40', 'Plikt til utlevering av motorvogn', 'Motorvogn som er fjernet, skal etter forespørsel utleveres til eieren eller den som opptrer på vegne av eieren, selv om påløpte fjerningskostnader eller ilagt kontrollsanksjon ikke er betalt.

Motorvognen kan likevel holdes tilbake inntil skyldig beløp er betalt når motorvogn er fjernet med hjemmel i § 38 fjerde ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44581, 'forskrift/2016-03-18-260', 41, 8, 'kapittel-8-paragraf-6', '§ 41', 'Om salg mv. av motorvogn som er fjernet', 'Motorvogn som er tatt i forvaring etter § 38 kan selges, dersom den ikke er hentet innen 3 måneder etter at eieren i rekommandert brev er varslet om forvaringen og at motorvognen vil bli solgt dersom den ikke blir hentet. Dersom eier, eller eiers adresse ikke er kjent, kan varselet kunngjøres i pressen eller på annen måte. Dersom motorvognen anses som vrak kan den på hensiktsmessig måte avhendes i samsvar med reglene i dette ledd.

Reglene i lov 29. mai 1953 nr. 1 om rett for handverkarar o.a. til å selja ting som ikkje vert henta, gjelder tilsvarende for salg etter denne bestemmelsen og for betaling av salgssummen.

Motorvogn som er tatt i forvaring, står for eierens regning og risiko, jf. imidlertid § 38 sjette ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44582, 'forskrift/2016-03-18-260', 42, 8, 'kapittel-8-paragraf-7', '§ 42', 'Annen fjerning av motorvogn', 'Eier eller bruker av privat grunn kan fjerne og ta i forvaring motorvogn som er plassert ulovlig på privat grunn og som ikke omfattes av § 38 når følgende vilkår er oppfylt:
a. motorvognen er plassert til fare for andre eller slik at eier eller bruker av grunnen utsettes for vesentlig skade eller ulempe,
b. fører/eieren av motorvognen er forsøkt varslet der dette kan skje uten vesentlig ulempe. Dersom kontakt med føreren eller eieren av motorvognen oppnås, skal denne gis en rimelig frist for selv å fjerne motorvognen og
c. det ved oppsatt skilt eller på annen måte klart fremgår at området er privat og at uvedkommende motorvogner kan bli fjernet for eiers regning og risiko og med opplysning om hvor en kan henvende seg for å få utlevert motorvognen som er fjernet. Dette gjelder likevel ikke når motorvognen er plassert på et sted hvor det etter omstendighetene er åpenbart at den vil kunne være til fare eller til vesentlig skade eller ulempe for andre.

Dersom eier eller bruker av grunnen engasjerer andre til å forestå fjerning eller forvaring av motorvognen, skal dette gjøres uttrykkelig for hver enkelt motorvogn. Det skal foreligge skriftlig begjæring som dokumenterer engasjementet.

Forskriftens § 39, § 40 første ledd, og § 41 gjelder tilsvarende for motorvogn som er fjernet etter denne bestemmelsen.

Dersom motorvognen er fjernet, og eventuelt tatt i forvaring, uten at det har vært grunnlag for det, er eier og bruker av grunnen og den som eventuelt har forestått fjerningen på dennes vegne, solidarisk ansvarlige for at eiers kostnader ved fjerning og forvaring refunderes og at økonomisk tap som følge av fjerningen erstattes.

Fjerde ledd gjelder tilsvarende dersom motorvognen, som er lovlig fjernet og eventuelt tatt i forvaring, er fravendt eieren ved et lovbrudd med en strafferamme på mer enn ett år.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44583, 'forskrift/2016-03-18-260', 43, 8, 'kapittel-8-paragraf-8', '§ 43', 'Særlig om dokumentasjon', 'Ved ileggelse av kontrollsanksjon og ved fjerning skal nødvendig dokumentasjon for kravet, for eksempel fotobevis, sikres og på forespørsel fremlegges for fører/eier.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44584, 'forskrift/2016-03-18-260', 44, 9, 'kapittel-9-paragraf-1', '§ 44', 'Klage til virksomheten', 'Eier og fører kan klage ilagt kontrollsanksjon inn for virksomheten som har ilagt denne eller for den som behandler klagen i virksomhetens navn. Påførte kostnader ved fjerning av motorvogn kan klages inn for virksomheten som har fjernet eller fått fjernet motorvognen.

Virksomheten kan ikke kreve betaling fra klager for å behandle klagen.

Fristen for å klage er tre uker etter ileggelse av kontrollsanksjon eller fjerning av motorvogn. Fristen beregnes i samsvar med forvaltningsloven § 29 og § 30.

Virksomheten skal forberede saken i samsvar med forvaltningsloven § 33. Alle klager skal realitetsbehandles. Virksomhetens avgjørelse skal begrunnes samtidig med at avgjørelsen fattes. Begrunnelsen skal inneholde det rettslige og faktiske grunnlaget for sanksjonen og for øvrig utformes i samsvar med forvaltningsloven § 25 så langt denne passer.

Dersom virksomheten ikke gir klager fullt medhold skal det i avgjørelsen opplyses om adgangen til å klage saken inn for parkeringsklagenemnda og fristene for dette.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44585, 'forskrift/2016-03-18-260', 45, 9, 'kapittel-9-paragraf-2', '§ 45', 'Klagerett til parkeringsklagenemnda, nemndas kompetanse og litispendensvirkninger', 'Eier og fører av motorvogn som ikke har fått fullt medhold i sin klage etter § 44 innen åtte uker etter at klagen er mottatt av virksomheten, har rett til å klage saken inn for parkeringsklagenemnda. Dersom klager ikke har mottatt foreløpig svar innen tre uker, gjelder klageretten fra dette tidspunkt.

Klagen må fremsettes skriftlig for parkeringsklagenemndas sekretariat. Klagen må fremsettes innen ett år etter den dato det er klaget til virksomheten. Den ilagte sanksjonen må likevel betales dersom det ikke klages til parkeringsklagenemnda innen tre uker etter at vedkommende har klagemulighet etter førsteledd.

Tas klagen under behandling, kan klageinstansen prøve alle sider av saken og herunder ta hensyn til nye omstendigheter. Den skal vurdere de synspunkter som klageren kommer med, og kan også ta opp forhold som ikke er berørt av klager.

Enhver virksomhet som ilegger kontrollsanksjon etter § 36, eller som fjerner eller får fjernet motorvogn etter § 38, er underlagt parkeringsklagenemndas kompetanse. Dette gjelder også der virksomheter eller personer ilegger sanksjoner etter § 3 annet ledd eller håndhever parkeringsrestriksjoner etter § 3 tredje ledd. Med håndheving av parkeringsrestriksjoner menes her også fjerning med hjemmel i § 42.

Så lenge en tvist er til behandling i nemnda, kan ikke en part bringe den inn til behandling for de alminnelige domstolene. Er søksmål reist ved de alminnelige domstoler og en part ønsker tvisten avgjort av parkeringsklagenemnda, kan vedkommende domstol stanse den videre behandling inntil parkeringsklagenemndas vedtak foreligger.

Fristene i denne paragraf beregnes i samsvar med forvaltningsloven § 29 og § 30.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44586, 'forskrift/2016-03-18-260', 46, 9, 'kapittel-9-paragraf-3', '§ 46', 'Organisering av parkeringsklagenemnda.', 'Parkeringsklagenemnda består av følgende organer:
a. nemnda,
b. sekretariatet og
c. styret.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44587, 'forskrift/2016-03-18-260', 47, 9, 'kapittel-9-paragraf-4', '§ 47', 'Parkeringsklagenemnda', 'Parkeringsklagenemnda skal ha minst tre medlemmer ved behandling av den enkelte sak. Av disse skal en være nøytral leder, en som representerer næringssiden og en som representerer forbrukersiden. Dersom saken er av særlig prinsipiell karakter eller særlige grunner ellers tilsier det, kan lederen kreve at saken avgjøres av nemnda i plenum med lik representasjon fra nærings- og forbrukerinteressene.

Leder av nemnda skal ha juridisk embetseksamen/master i rettsvitenskap og godkjennes av Vegdirektoratet etter forslag fra styret. Leder oppnevnes for to år av gangen og kan reoppnevnes av styret for nye, også kortere perioder, dersom både nærings- og forbrukersiden i styret er enige om det. Representanten(e) for næringssiden utpekes av Norpark, mens representanten(e) for forbrukersiden utpekes av Forbrukerrådet, i samråd med Forbrukertilsynet.

Nemnda skal ved behov ha en nestleder som kan fungere i lederens sted. Nestlederen skal oppfylle kravet i annet ledd første punktum, og skal ha samme myndighet som lederen etter denne forskriften. Nestlederen utpekes på samme måte som leder, jf. annet ledd.

Nemnda kan bare delegere beslutningsmyndighet til sekretariatet i den grad det er uttrykkelig tillatt etter øvrige bestemmelser i denne forskriften.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44588, 'forskrift/2016-03-18-260', 48, 9, 'kapittel-9-paragraf-5', '§ 48', 'Sekretariatet', 'Nemnda skal ha et sekretariat som betjenes av egne ansatte eller ved kjøp av tjenester fra ekstern leverandør. Sekretariatet skal ikke lokaliseres sammen med bransjeforening eller lignende. Sekretariatet skal være uavhengig og upartisk.

Sekretariatet skal forberede innkomne saker for nemndsbehandling og se til at det blir utarbeidet sakssammendrag og innstilling til vedtak. Sammendraget skal så langt som mulig gi et fyllestgjørende bilde av saksforholdet og partenes anførsler. Sekretariatet skal veilede partene i klageprosessen, herunder gi veiledning i forkant av en eventuell klage.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44589, 'forskrift/2016-03-18-260', 49, 9, 'kapittel-9-paragraf-6', '§ 49', 'Styrets organisering og oppgaver', 'Parkeringsklagenemnda skal ha et styre som består av tre medlemmer. En nøytral leder utpekes av Vegdirektoratet. Representanter for forbrukerinteressene og næringsinteressene utpekes av Forbrukerrådet og Norpark. Det kan utnevnes varamedlemmer etter reglene foran.

Styremedlemmer velges for maksimalt fire år av gangen.

Forvaltningen av nemnda hører under styret. Styret skal sørge for forsvarlig organisering av virksomheten og føre tilsyn med sekretariatet. Styret kan fastsette instruks for sekretariatet.

Styret skal i nødvendig utstrekning fastsette planer og budsjetter for nemndas virksomhet, herunder fastsette satser omtalt i § 58 og godtgjørelse til nemndas leder og medlemmer, jf. § 59. Styret kan også fastsette retningslinjer for virksomheten. Forbrukerrådet og Norpark fastsetter og dekker godtgjørelse for sine respektive styremedlemmer.

Styret skal behandle saker i møte, med mindre styrets leder finner at saken kan forelegges skriftlig eller behandles på annen betryggende måte. Årsregnskap og årsberetning skal behandles i møte. Styrebehandlingen ledes av styrelederen. Deltar ikke styrelederen velger styret en leder for styrebehandlingen. Styrets beslutninger krever flertall blant de styremedlemmene som deltar. Ved stemmelikhet gjelder det som møtelederen har stemt for.

Sekretariatets leder har rett og plikt til å delta i styrets behandling av saker og til å uttale seg, med mindre annet er bestemt av styret i den enkelte sak.

Det skal føres protokoll over styrebehandlingen. Den skal minst angi tid og sted, deltakerne, behandlingsmåten og styrets beslutninger.

Styret skal underrette Vegdirektoratet om det på bakgrunn av praksis i nemnda er behov for endringer i denne forskrift.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44590, 'forskrift/2016-03-18-260', 50, 9, 'kapittel-9-paragraf-7', '§ 50', 'Saksforberedelse i sekretariatet', 'Sekretariatet skal informere sakens parter så snart det har mottatt saksdokumentene. Før saken behandles i nemnda skal partene ha hatt mulighet til å uttale seg om både faktiske og rettslige sider av saken.

Sekretariatet innhenter nødvendige opplysninger i saken og forelegger klagen for den innklagede virksomheten. Det skal legges til rette for at utveksling av opplysninger kan skje elektronisk eller per post. Sekretariatet kan sette en rimelig tidsfrist for virksomheten til å uttale seg om foreleggelsen (tilsvar).

Dersom partene ikke benytter seg av retten til å uttale seg, kan nemnda likevel treffe vedtak på grunnlag av de opplysningene som er fremkommet tidligere i saken.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44591, 'forskrift/2016-03-18-260', 51, 9, 'kapittel-9-paragraf-8', '§ 51', 'Saksbehandlingen i nemnda', 'Saksbehandlingen er skriftlig og partene har ikke møterett på nemndsmøtene. Nemnda behandler saken på grunnlag av de utsendte saksdokumentene, sakssammendraget og forslaget til vedtak. Dersom den innklagede tjenesteyteren ikke har avgitt tilsvar i saken, kan saken avgjøres på grunnlag av klagerens fremstilling og de opplysninger som ellers er fremkommet i saken.

Nemnda kan beslutte å utsette behandlingen av klagen for å innhente ytterligere informasjon.

En representant for sekretariatet skal være til stede på nemndas møter. Representanten for sekretariatet sørger for at det nedtegnes hvem som er til stede, hvilke saker som er til behandling, nemndas vedtak og eventuelle dissenser.

Nemnda må være fulltallig for at vedtak skal kunne fattes. Nemnda avgjør saken med alminnelig flertall. Lederen har likevel dobbeltstemme ved stemmelikhet.

Saken må være ferdigbehandlet senest innen 90 dager etter at den fullstendige klagesaken ble mottatt av nemnda. I særlig komplekse saker kan fristen forlenges. Partene må da informeres om forlengelsen og forventet saksbehandlingstid.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44592, 'forskrift/2016-03-18-260', 52, 9, 'kapittel-9-paragraf-9', '§ 52', 'Nemndas avgjørelse', 'Nemnda skal avgjøre klagen på grunnlag av de til enhver tid gjeldende lover, forskrifter og vilkår på det enkelte parkeringsområde. Nemnda kan helt eller delvis sette til side kontrollsanksjon dersom det vil virke urimelig eller være i strid med god forretningsskikk å opprettholde den. Dersom ilagt kontrollsanksjon er betalt, jf. forskriften § 45 annet ledd annet punktum, og klager gis helt eller delvis medhold, skal nemnda også kreve at sanksjonen helt eller delvis betales tilbake.

Nemndas avgjørelse skal være skriftlig og begrunnet. Det skal opplyses om avgjørelsen er enstemmig, og hvilke medlemmer som eventuelt er uenige. Mindretallets standpunkt skal også begrunnes.

Nemnda kan avgi generelle uttalelser som er foranlediget av tilbakevendende problemstillinger i konkrete saker.

Nemnda kan omgjøre sin egen avgjørelse uten at det er påklaget dersom:
a. endringen ikke er til skade for noen som avgjørelsen retter seg mot eller direkte tilgodeser eller
b. underretning om avgjørelsen ikke er kommet fram til vedkommende og avgjørelsen heller ikke er offentlig kunngjort, eller
c. avgjørelsen er fattet med grunnlag i åpenbare feil som har hatt avgjørende betydning for sakens utfall.

Dersom avgjørelsen blir omgjort til gunst for virksomheten, faller kravet om å betale sats for tapt eller trukket sak som omtalt i denne forskrifts § 58 andre ledd bort.

Nemnda kan i spesielle tilfeller der klager skriftlig har krevet dekning av nødvendige saksomkostninger, pålegge den innklagede virksomheten å dekke dette. Helt unntaksvis kan klageren pålegges å dekke nødvendige sakskostnader for virksomheten.

Nemndas avgjørelser skal forkynnes for partene innen to uker etter at saken er endelig behandlet og avgjort.

Nemndas avgjørelser kan ikke påklages. Sak som nemnda har realitetsbehandlet kan innen fire uker etter at avgjørelsen er forkynt bringes inn for tingretten ved stevning. Dersom sak ikke er reist, har nemndas vedtak samme virkning som rettskraftig dom. Ved oversittelse av fristen kan nemnda etter reglene i forvaltningsloven § 31 vedta at saken tas til behandling i tingretten. Vedtaket om fristoversittelsen kan ankes til tingretten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44593, 'forskrift/2016-03-18-260', 53, 9, 'kapittel-9-paragraf-10', '§ 53', 'Delegering av vedtaksmyndighet til sekretariatet og avvisning', 'Sekretariatets leder, eller den leder bemyndiger, kan treffe vedtak i klagesaker hvor det foreligger en fast nemndspraksis eller er truffet vedtak av prinsipiell betydning i tilsvarende saker. I tvilstilfelle skal sekretariatet konferere med nemndas leder. Vedtaket skal utformes i samsvar med reglene for nemndsvedtak, og får virkning som slikt vedtak.

Sekretariatets leder, eller den leder bemyndiger, kan avvise en klage dersom:
a. saken er endelig avgjort ved dom, rettsforlik eller bindende voldgiftsavgjørelse,
b. saken er til behandling ved de alminnelige domstolene og ikke er besluttet stanset etter § 45 fjerde ledd,
c. saken tidligere har vært behandlet av nemnda,
d. saken ikke har vært klaget inn til virksomheten eller klagefristen er oversittet.

Nemnda kan avvise en klage dersom:
a. saken reiser bevisspørsmål som vanskelig kan klarlegges under saksbehandlingen eller av andre grunner ikke egner seg for behandling i nemnda eller
b. saken har tidligere vært behandlet av nemnda.

Avvisningen skal være skriftlig og inneholde begrunnelse som gjengir de rettslige betingelsene for avvisning. Avvisning besluttet av sekretariatets leder skal i tillegg inneholde informasjon om adgangen til å påklage avgjørelsen til nemnda.

Partene skal gis innsyn i saken selv om den avvises.

Dersom en klage faller utenfor nemndas kompetanse etter § 45, skal klager informeres om dette og om mulig henvises til antatt rette klageorgan.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44594, 'forskrift/2016-03-18-260', 54, 9, 'kapittel-9-paragraf-11', '§ 54', 'Klage over vedtak eller avvisning', 'Har sekretariatets leder, eller den leder bemyndiger, truffet vedtak etter § 53 første ledd eller avvist klagen etter § 53 annet ledd, kan klageren likevel kreve at saken legges frem for nemnda. En slik anmodning må være skriftlig og leveres innen tre uker etter at avvisningen er meddelt klageren.

Dersom nemndas leder eller fungerende nestleder ikke finner at nemnda bør behandle saken, kan vedkommende med endelig virkning beslutte at saken ikke skal behandles i nemnda.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44595, 'forskrift/2016-03-18-260', 55, 9, 'kapittel-9-paragraf-12', '§ 55', 'Taushetsplikt', 'Enhver som utfører tjeneste eller arbeid for klagenemnda har taushetsplikt i samsvar med forvaltningslovens regler.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44596, 'forskrift/2016-03-18-260', 56, 9, 'kapittel-9-paragraf-13', '§ 56', 'Gjenopptakelse', 'En avsluttet sak kan gjenopptas dersom en av partene fremlegger nye opplysninger som nemnda antar ville hatt betydning for utfallet av den tidligere behandlingen dersom de hadde vært kjent. Dette gjelder ikke dersom den part som krever gjenopptagelse kan bebreides for ikke å ha lagt frem opplysningene ved den opprinnelige behandlingen.

Parkeringsklagenemnda kan avvise begjæringen om gjenopptakelse uten videre behandling dersom det er åpenbart at denne ikke vil føre frem.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44597, 'forskrift/2016-03-18-260', 57, 9, 'kapittel-9-paragraf-14', '§ 57', 'Parkeringsklagenemndas side på internett', 'Klagenemnda skal ha egen side på internett. Alle avgjørelser nemnda fatter skal i sin helhet publiseres på klagenemndas internettside. Unntak gjelder for de delene av avgjørelsen som er taushetsbelagt i lov. Navn på fysiske personer saken gjelder skal likevel ikke publiseres med mindre vedkommende selv samtykker. Klage til nemnda skal kunne inngis via nettsidene.

Internettsiden skal inneholde en lenke til denne forskriften, adresser, telefonnummer og annen kontaktinformasjon, retningslinjer og årsberetning m.m.

Internettsidene skal også inneholde de opplysningene som angis i Europaparlaments- og rådsdirektiv 2013/11/EU artikkel 7.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44598, 'forskrift/2016-03-18-260', 58, 9, 'kapittel-9-paragraf-15', '§ 58', 'Finansiering', 'Kostnadene for etablering og drift av parkeringsklagenemnda dekkes ved at en andel av de kontrollsanksjoner som virksomhetene ilegger etter § 36 avsettes til dette. I tillegg kan det fastsettes egne satser for andre som omfattes av § 45 fjerde ledd.

Styret fastsetter en høyere sats for saker som tapes av virksomheten og for saker som trekkes av andre grunner enn forhold hos klageren. Styret kan også fastsette en sats for hver sak som blir registrert mot virksomheten.

Styret kan i ekstraordinære tilfeller fastsette særskilte midlertidige satser for å sikre nemndas videre virksomhet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44599, 'forskrift/2016-03-18-260', 59, 9, 'kapittel-9-paragraf-16', '§ 59', 'Godtgjørelse', 'Styret fastsetter godtgjørelse til nemndas leder. Styret kan bestemme at også de øvrige nemndsmedlemmene og styrets leder og styremedlemmer skal ha godtgjørelse for sitt arbeid.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44600, 'forskrift/2016-03-18-260', 60, 9, 'kapittel-9-paragraf-17', '§ 60', 'Årsberetning', 'Nemnda skal innen 1. mai hvert år avgi en årsberetning til Vegdirektoratet om parkeringsklagenemndas virksomhet for det foregående kalenderåret.

Årsberetningen skal inneholde statistikk over antall saker som har vært til behandling, herunder de som er avvist av sekretariatet. Den skal også inneholde omtale av eventuelle systematiske eller vesentlige problemer som forekommer hyppig og fører til tvister, samt gjennomsnittlig behandlingstid i sakene. I den grad det er kjent for nemnda, skal det også opplyses om i hvilket omfang resultatene av nemndas avgjørelser etterleves.

Årsberetningen skal ikke inneholde taushetsbelagte opplysninger som umuliggjør at den i sin helhet publiseres i overensstemmelse med § 57 eller gjøres offentlig på annen måte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44601, 'forskrift/2016-03-18-260', 61, 10, 'kapittel-10-paragraf-1', '§ 61', 'Reservering av plasser for forflytningshemmede med parkeringstillatelse', 'På alle parkeringsområder omfattet av § 3 første ledd, skal det avsettes et tilstrekkelig antall plasser tilrettelagt for forflytningshemmede med parkeringstillatelse. Med tilstrekkelig antall menes at det i alminnelighet til enhver tid er en ledig reservert plass. Plassene skal utformes og plasseres i samsvar med bestemmelsen i dette kapittelet.

På parkeringsområder med 50 plasser eller mer, er virksomheten likevel ikke forpliktet til å reservere mer enn fire prosent av plassene til forflytningshemmede med parkeringstillatelse. På parkeringsområder med opptil 50 plasser, er virksomheten ikke forpliktet til å reservere mer enn to plasser.

Virksomheten kan ikke sette opp skilt etter § 16 før kravet i første ledd er oppfylt, jf. også § 62.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44602, 'forskrift/2016-03-18-260', 62, 10, 'kapittel-10-paragraf-2', '§ 62', 'Vurdering av tilstrekkelig antall plasser for forflytningshemmede', 'Virksomheten skal i forbindelse med registrering av skiltplan med tilleggsinformasjon etter § 16, vurdere hva som er et tilstrekkelig antall plasser etter § 61 ut fra lokale forhold på parkeringsområdet. Vurderingen skal inneholde informasjon om størrelse, utforming og plassering av disse plassene etter § 63. Virksomheten skal også vurdere behov for tidsbegrensning av slike plasser, der dette er aktuelt, samt eventuelle andre tiltak som vurderes som nødvendige for å sikre universell utforming av parkeringsområdet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44603, 'forskrift/2016-03-18-260', 63, 10, 'kapittel-10-paragraf-3', '§ 63', 'Størrelse, utforming og plassering av plasser', 'Plass tilrettelagt for forflytningshemmet, jf. § 61, skal som hovedregel være minst 4,5 X 6 meter. Langsgående plass på offentlig ferdselsåre kan likevel ha alminnelig bredde. Der forholdene er slik at det på annen måte sikres tilgjengelighet for side- og bakmontert rullestolheis kan også plassen i andre tilfeller være mindre.

Plassene skal gis best mulig plassering på området sett hen til tilbudet plassen skal betjene. Området skal for øvrig utformes universelt. Dette innebærer særlig at nivåsprang ikke skal overstige 2 cm. Rampe skal ha bredde på minst 90 cm og ha stigning på maksimum 1:20. Dekke på parkeringsplass med tilhørende adkomst bør være jevnt. For strekning under 3,0 meter kan stigningen være maksimum 1:12. For hver 0,6 meter høydeforskjell skal det være et horisontalt hvileplan med lengde minimum 1,5 meter.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44604, 'forskrift/2016-03-18-260', 64, 10, 'kapittel-10-paragraf-4', '§ 64', 'Bestemmelser om maksimaltid', 'Forflytningshemmede med parkeringstillatelse kan ved skiltet tidsbegrensning fra 30 minutter og oppover stå inntil dobbel tid på slike plasser. Skiltet tidsbegrensning på særskilt avsatte plasser for forflytningshemmede med parkeringstillatelse må likevel respekteres etter sin ordlyd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44605, 'forskrift/2016-03-18-260', 65, 11, 'kapittel-11-paragraf-1', '§ 65', 'Ikrafttredelse', 'Denne forskriften trer i kraft 1. januar 2017.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44606, 'forskrift/2016-03-18-260', 66, 11, 'kapittel-11-paragraf-2', '§ 66', 'Endringsfullmakt', 'Samferdselsdepartementet kan gjøre endringer i denne forskrift.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44607, 'forskrift/2016-03-18-260', 67, 11, 'kapittel-11-paragraf-3', '§ 67', 'Unntak', 'Statens vegvesen kan ved enkeltvedtak gjøre unntak fra bestemmelsene i forskriften når det foreligger særlig grunner.

Vegdirektoratet kan i tillegg gjøre unntak fra denne forskriften, herunder utsette ikrafttredelsen av de forskjellige kravene i forskriften.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (44608, 'forskrift/2016-03-18-260', 68, 12, NULL, NULL, NULL, '1.Parkeringsskilt
1.1
Vilkårsparkeringsplasser på offentlig ferdselsåre skal skiltes i henhold til skiltforskriften med skilt 552 «Parkering», skilt 376 «Parkeringssone» og skilt 378 «Slutt på parkeringssone». Det kan også skiltes med skiltene 552, 376 og 378 på andre vilkårsparkeringsplasser forutsatt at det er virksomheter omtalt i § 7 annet ledd eller politiet som håndhever parkeringsreguleringen.
1.2
Andre vilkårsparkeringsplasser skal benytte følgende skilt:
1P Parkering
Skiltet angir at parkering kan skje i tråd med parkeringsvilkårene på stedet, dersom parkeringen ikke er i strid med trafikkreglenes bestemmelser om stans eller parkering.
Skiltet gjelder frem til nytt skilt som vist i dette vedlegget punkt 1.2 – «Parkering» eller punkt 2.2 «Stans forbudt» eller «Parkering forbudt». Er det vegkryss på stedet, må skiltet gjentas etter krysset. Er skiltet plassert på eller ved særskilt avgrenset område, f.eks. parkeringsplass, gjelder skiltet for hele området.
2P Parkeringssone og 3P Slutt på parkeringssone
Skiltet «Parkeringssone» angir grenser for område hvor det gjelder særlige bestemmelser for parkering. Skiltet gjelder til det blir opphevet av skilt «Slutt på parkeringssone».
2.Stans- og parkeringsforbud
2.1
Stans- og parkeringsforbud på offentlig ferdselsåre skal skiltes i henhold til skiltforskriften skilt 370 «Stans forbudt», 372 «Parkering forbudt», 376 «Parkeringssone» og 378 «Slutt på parkeringssone». Det kan også skiltes med skiltene 370, 372, 376 og 378 på andre vilkårsparkeringsplasser forutsatt at det er virksomheter omtalt i § 7 annet ledd eller politiet som håndhever parkeringsreguleringen.
2.2
Andre vilkårsparkeringsplasser skal benytte følgende skilt:
4P Stans forbudt
Skiltet angir at det er i strid med parkeringsvilkårene på stedet å stanse motorvogn der skiltet er satt opp. Skiltet gjelder fram til nytt skilt som vist i dette vedlegget punkt 1.2 «Parkering» eller punkt 2.2 «Stans forbudt» eller «Parkering forbudt».
Er det vegkryss på stedet må skiltet gjentas etter krysset.
5P Parkering forbudt
Skiltet angir at det er i strid med parkeringsvilkårene på stedet å parkere motorvogn der skiltet er satt opp. Skiltet gjelder fram til nytt skilt som vist i dette vedlegget punkt 1.2 «Parkering» eller punkt 2.2 «Stans forbudt» eller «Parkering forbudt».
Er det vegkryss på stedet må skiltet gjentas etter krysset.
6P Sone med parkeringsforbud og 7P Slutt på sone med parkeringsforbud
Skiltet «Sone med parkeringsforbud» angir grenser for område hvor det gjelder særlige forbud mot parkering. Skiltet gjelder til det blir opphevet av skilt «Slutt på sone med parkeringsforbud».
Rene parkerings- eller stanseforbud anses ikke som vilkårsparkering, jf. § 2 a. For vilkårsparkering gitt med skilt som vist i denne forskrift (vedlegg 1-skilt) kan virksomheten likevel benytte skilt med parkerings- eller stanseforbud i sammenheng med at det tilbys vilkårsparkering. Dersom private virksomheter eller grunneiere ønsker å skilte med rene stanse- og parkeringsforbud, uten å samtidig tilby vilkårsparkering, må dette reguleres med private skilt. Eventuell håndheving av slike private skilt med stanse- eller parkeringsforbud omfattes av parkeringsforskriften § 3 tredje ledd, slik at forskriftens kapittel 3, 8 og 9 kommer til anvendelse ved håndheving.
3.Underskilt
3.1
Underskilt til skilt i dette vedlegg punkt 1.1 og 2.1 skal være i henhold til skiltforskriften kapittel 9 og normalbestemmelser gitt med hjemmel i skiltforskriften § 35.
3.2
Nye underskilt til skilt i dette vedlegget, skal utformes i tråd med underskilt som vist i skiltforskriften kapittel 9 med tilhørende normalbestemmelser, jf. skiltforskriften § 35. Tekst på underskilt må være utformet slik at budskapet er lett forståelig.
Underskilt er bare gyldig når det nyttes sammen med hovedskilt, og gir nærmere klargjøring, utviding, utfylling eller begrensning av hovedskiltets betydning eller gyldighetsområde. Soneskilt 2P og 6P skal ikke ha underskilt.
Innenfor et særskilt avgrenset område som er skiltet i henhold til dette vedlegget punkt 1.2 med skilt 1P «parkering», kan likevel underskilt benyttes alene inne på området for å begrense eller presisere betydningen av hovedreguleringen. Det kan benyttes underskilt med ulike tekster innenfor samme parkeringsområde.
3.3
På avgiftsbelagte parkeringsplasser vist med skilt 1P må det på plasser reservert for forflytningshemmede, angis på underskiltet dersom også forflytningshemmede med parkeringstillatelse skal betale.
4.Andre skilt og vegoppmerking
Andre skilt og vegoppmerking som ikke er vedtatt med hjemmel i skiltforskriften eller som følger av denne forskrift med vedlegg punkt 1 til 3 skal anses som veiledende anvisninger.
5.Nærmere bestemmelser
5.1
Skilt i punkt 1.2, 2.2, 3.2 og § 22 skal ha en størrelse, folieklasse og skriftstørrelse som gjør dem godt synlige og lesbare. Skilt 1P til 7P skal ha folieklasse 1. Ved behov for tydeligere skilting kan folieklasse 2 likevel brukes. Informasjonsskilt skal ha folieklasse 1, eller være godt belyst. Underskilt skal ha samme klasse som hovedskilt.
5.2
Skilt 1P «Parkering» skal minimum ha størrelse 400 x 400 mm (40 cm x 40 cm). Skilt 5P «Parkering forbudt» skal minimum ha en størrelse på 400 mm (40 cm) i diameter. Skilt 4P «Stans forbudt» skal ha størrelse på 600 mm (60 cm) i diameter.
5.3
Skilt 2P «Parkeringssone», 3P «Slutt på parkeringssone», 6P «Sone med parkeringsforbud» og 7P «Slutt på sone med parkeringsforbud», skal ha bredde lik 600 mm (60 cm) og høyde lik 800 mm (80 cm).
5.4
Skilt 5P og 4P skal i hovedsak formes som sirkulære skilt, slik som de er vist i vedlegg 1. Imidlertid kan skiltene likevel settes på en skiltplate, også med underskilt, forutsatt at det aktuelle skiltet er i riktig størrelse og symbolet har riktig utforming og størrelse. Skiltsymbolene kan også vises i miniatyr på underskilt. Dersom symbolene benyttes på en skiltplate, altså slik at de ikke er sirkulære, skal dette skiltet ikke ha bord, slik skilt 1P og soneskilt vist i parkeringsforskriften har.
5.5
Vegdirektoratet kan fastsette nærmere tekniske bestemmelser om krav til skiltets størrelse, folieklasse og skriftstørrelse og gi retningslinjer (normaler) for anvendelse, utforming og plassering av skilt og oppmerking som omtalt i denne forskrift.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83274, 'lov/1965-06-18-4', 1, 1, 'kapittel-1-paragraf-1', '§ 1', 'Lovens område.', 'Denne lov gjelder all trafikk med motorvogn. Den gjelder også annen ferdsel, men da bare på veg eller på område som har alminnelig trafikk med motorvogn.

Trafikk eller ferdsel omfatter i denne lov også opphold på veg eller på område der det er alminnelig adgang til og vanlig å kjøre med motorvogn.

Kongen kan bestemme at loven helt eller delvis skal gjelde for annet område enn nevnt i paragrafen her, eller at den helt eller delvis ikke skal gjelde for slikt område.

For Svalbard og Jan Mayen gjelder loven med de endringer som Kongen måtte fastsette av hensyn til de stedlige forhold.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83275, 'lov/1965-06-18-4', 2, 1, 'kapittel-1-paragraf-2', '§ 2', 'Definisjoner.', 'Med veg forstås i denne lov også gate og plass, herunder opplagsplass, parkeringsplass, holdeplass, bru, ferjekai eller annen kai som står i umiddelbar forbindelse med veg.

Med kjøretøy forstås innretning som er bestemt til å kjøre på bakken uten skinner. Med motorvogn forstås kjøretøy som blir drevet fram med motor.

Departementet kan bestemme at også annen innretning skal regnes som kjøretøy etter denne lov. Tilsvarende kan departementet bestemme at innretning som etter foregående ledd er kjøretøy, ikke skal omfattes av loven. Departementet kan også bestemme at kjøretøy som etter foregående ledd er motorvogn, likevel ikke skal regnes som motorvogn etter denne loven.

Kongen kan fastsette i hvilken utstrekning bestemmelser i eller i medhold av denne lov skal gjelde for trafikk med sporvogn eller annet skinnekjøretøy som kjører på eller over veg.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83276, 'lov/1965-06-18-4', 3, 2, 'kapittel-2-paragraf-1', '§ 3', 'Grunnregler for trafikk.', 'Enhver skal ferdes hensynsfullt og være aktpågivende og varsom så det ikke kan oppstå fare eller voldes skade og slik at annen trafikk ikke unødig blir hindret eller forstyrret.

Vegfarende skal også vise hensyn mot dem som bor eller oppholder seg ved vegen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83277, 'lov/1965-06-18-4', 4, 2, 'kapittel-2-paragraf-2', '§ 4', 'Trafikkregler.', 'Kongen gir alminnelige regler for kjørende, ridende og gående trafikk.

Departementet kan gi særlige trafikkbestemmelser for en kommune eller del av en kommune. Departementet kan delegere slik myndighet til Statens vegvesen, eller i forskrift gi slik myndighet til kommunen eller lokal politimyndighet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83278, 'lov/1965-06-18-4', 5, 2, 'kapittel-2-paragraf-3', '§ 5', 'Skiltregler m.m.', 'Enhver skal være oppmerksom på offentlig trafikkskilt, signal og oppmerking og skal rette seg etter de forbud og påbud som gis på denne måte.

Departementet gir regler om offentlige trafikkskilt, signaler og oppmerkinger, herunder om hvilke myndigheter som kan treffe vedtak om oppsetting og oppmerking, og overprøving av skiltvedtak. Departementet kan gi forskrift om at myndighet til å treffe vedtak om oppsetting og oppmerking gis til kommuner og fylkeskommuner.

Vedkommende myndighet har på privat og offentlig eiendom rett til å sette opp offentlig trafikkskilt, signal, utstyr for kontroll av trafikk og feste for slike innretninger og til å foreta oppmerking. For skade og ulempe voldt ved slike tiltak ytes erstatning fastsatt ved skjønn. For så vidt gjelder offentlig veg, dekkes utgifter ved tiltakene som vegutgifter etter reglene i veglova, men er et tiltak truffet av hensyn til noen bestemt persons interesse, kan han pålegges å erstatte utgiftene helt eller delvis etter regler gitt av departementet. For private vegers vedkommende kan departementet gi regler om hvem som skal bære utgiftene.

Offentlig trafikkskilt, signal eller oppmerking må ikke brukes på eller ved veg uten tillatelse av vedkommende myndighet. Det samme gjelder skilt, signal eller oppmerking som kan forveksles med offentlige. Dersom det uten tillatelse er satt opp skilt eller signal eller foretatt oppmerking, kan dette fjernes eller kreves fjernet av myndigheten.

Det er forbudt å endre, fjerne eller skade offentlig trafikkskilt, signal, utstyr til kontroll av trafikk, oppmerking eller innretning for vegsperring.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83279, 'lov/1965-06-18-4', 6, 2, 'kapittel-2-paragraf-4', '§ 6', 'Fartsregler.', 'Fører av kjøretøy skal avpasse farten etter sted, føre-, sikt- og trafikkforholdene slik at det ikke kan oppstå fare eller voldes ulempe for andre, og slik at annen trafikk blir minst mulig hindret eller forstyrret. Føreren skal alltid ha fullt herredømme over kjøretøyet.

Dersom ikke annen fartsgrense er fastsatt ved offentlig trafikkskilt, må det i tettbygd strøk ikke kjøres fortere enn 50 km/t, og utenfor tettbygd strøk ikke fortere enn 80 km/t. Departementet kan delegere til Statens vegvesen eller i forskrift gi politiet eller kommunen myndighet til å avgjøre om et område skal regnes som tettbygd strøk etter denne lov, og fastsette grensene for det tettbygde strøk.

I trafikkregler gitt i medhold av § 4 og skiltregler gitt i medhold av § 5 kan det fastsettes nærmere bestemmelser om fartsgrenser, herunder om lavere fartsgrense for bestemte grupper av motorvogner og lavere fartsgrense, for bestemt eller ubestemt tid, også av hensyn til miljøet.

Departementet kan gi særlige regler om fartsgrenser for område utenfor veg, eller på veg stengt for alminnelig ferdsel.

Departementet kan som forsøksordning sette lavere generelle fartsgrenser enn hva som er bestemt i andre ledd for bestemte områder og/eller for bestemte tider.

Fartsgrensene gjelder ikke for konkurransekjøring, trening til konkurransekjøring eller annen organisert kjøring som med Statens vegvesens tillatelse holdes på særskilt bane eller veg som stenges for all annen trafikk. Statens vegvesen kan i tillatelsen stille vilkår i samsvar med lovens formål.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83280, 'lov/1965-06-18-4', 7, 2, 'kapittel-2-paragraf-5', '§ 7', 'Særlige forbud mot trafikk.', 'Kongen eller den han gir fullmakt kan forby bestemte grupper av kjøretøyer. Forbudet kan begrenses til å gjelde på eller utenfor visse veger og innenfor et bestemt tidsrom. Det kan på samme måte gjelde bestemte trafikantgrupper.

Det kan treffes midlertidig vedtak om forbud mot all trafikk eller om annen regulering av trafikk på veg dersom forhold på vegen eller i dens omgivelser, arbeid på vegen eller vegens tilstand tilsier det. Slikt vedtak treffes for riksveg og fylkesveg av Statens vegvesen og for kommunal veg av kommunen.

Vegdirektoratet kan i forskrift gi nærmere bestemmelser om at transport av visse typer farlig gods kun skal være tillatt på visse veger, til visse tider eller på andre særlige vilkår.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83281, 'lov/1965-06-18-4', 8, 2, 'kapittel-2-paragraf-6', '§ 7 a', '(Opphevet)', '', '2017-10-01', 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83282, 'lov/1965-06-18-4', 9, 2, 'kapittel-2-paragraf-7', '§ 7 b', 'Sykkelritt på veg som helt eller delvis er åpen for alminnelig ferdsel', 'Sykkelritt på veg som helt eller delvis er åpen for alminnelig ferdsel, er forbudt uten tillatelse fra Statens vegvesen. Før Statens vegvesen treffer vedtak, skal politiet uttale seg.

I vedtaket kan Statens vegvesen gi tillatelse til å fravike §§ 4, 5 og 6, eller bestemmelser fastsatt i medhold av disse paragrafene, i den grad det er nødvendig og forsvarlig. Statens vegvesen kan også stille krav om skiltplan, trafikkregulering og bruk av private vakter.

Politiet beslutter om private vakter kan benyttes ved det enkelte sykkelritt.

Departementet kan i forskrift gi regler om myndigheten etter første og andre ledd, og om gjennomføring av sykkelritt som nevnt i første ledd, herunder om skiltplan og plan for trafikkregulering.

Departementet kan i forskrift også gi regler om Statens vegvesens tildeling av myndighet innen rammene av § 9 til midlertidig trafikkregulering til private vakter, om uniformering av slike vakter og merking av deres kjøretøy, og om vaktenes minstealder, skikkethet og kompetanse. Regler om kompetanse kan blant annet gjelde kompetansebevis, godkjenning av læreplan for tilbyder av kompetansegivende kurs, tilsyn med tilbyder av kompetansegivende kurs, gebyr for utstedelse av kompetansebevis, påbud om å ha med kompetansebevis under vakttjeneste og gyldighetstid for og tilbakekall av kompetansebevis.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83283, 'lov/1965-06-18-4', 10, 2, 'kapittel-2-paragraf-8', '§ 7 c', 'Kjøring på lukket bane eller annet avsperret område', 'Departementet kan i forskrift gi regler om kjøring på lukket bane eller annet avsperret område, herunder nærmere regler om tillatelse, om organisering og gjennomføring av slik kjøring, og om forsikring.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83284, 'lov/1965-06-18-4', 11, 2, 'kapittel-2-paragraf-9', '§ 8', 'Vilkårsparkering til allmennheten mv.', 'Kongen kan i forskrift gi regler om parkering av kjøretøy som skjer mot betaling, med tidsbegrensning eller på andre vilkår, og som finner sted på veg som er åpen for alminnelig ferdsel (vilkårsparkering). Kongen kan i forskrift også gi regler om håndheving av vilkårsparkering på veg som ikke er åpen for alminnelig ferdsel, og håndheving av parkeringsrestriksjoner på og langs privat veg og utenfor veg. I forskriften kan det også gis regler om:
a. krav til virksomheter som vil tilby vilkårsparkering, herunder krav til meldeplikt før denne kan tilby vilkårsparkering, krav til registrering og forretningssted, krav til dekkende ansvarsforsikring, samt til alder og tilknytning til riket eller annen EØS-stat for innehaver og andre ansvarlige i virksomheten,
b. krav til person som skal håndheve reglene, herunder krav til teoretisk og praktisk opplæring med avsluttende prøve og regelmessig regodkjenningsprøve og krav til godkjenning og regodkjenning av undervisningsplan og gebyr for slike godkjenninger,
c. krav til det enkelte parkeringsområde, herunder krav til skiltplan og bruk av skilt. Bruk av privat skilt kan begrenses og forbys på områder hvor det tilbys vilkårsparkering til allmennheten,
d. tilsyn, herunder opplysnings- og rapporteringsplikt og adgang til å gi pålegg om retting, tvangsmulkt, avskilting av parkeringsområde, samt gebyr og avgift for tilsyn med parkeringsvirksomheter. Gebyrene og avgiften skal dekke kostnadene med tilsyn med parkeringsvirksomhetene,
e. krav til brukervennlige og universelt utformede betalingsløsninger,
f. plikt til å tilby betalingsfritak på avgiftsbelagte kommunale parkeringsplasser for forflytningshemmede med parkeringstillatelse,
g. rett til å tilby betalingsfritak for elektrisk og hydrogendrevet motorvogn på avgiftsbelagte kommunale parkeringsplasser og plikt til å tilby lademulighet for strøm. Det kan også gis regler om at avgift for elektrisk og hydrogendrevet motorvogn på alle eller visse avgiftsbelagte kommunale parkeringsplasser ikke skal overstige halvparten av den laveste taksten på det aktuelle parkeringsområdet for bensin- eller dieseldrevet motorvogn,
h. ileggelse av kontrollsanksjon, herunder størrelse på sanksjon og solidarisk ansvar mellom fører og eier,
i. når kjøretøy kan fjernes og tas i forvaring, herunder krav om at kjøretøyet må stå til hinder eller i strid med vilkårene for parkering, krav om varslings- og opplysningsplikt, samt plikt til å utlevere kjøretøy som er fjernet, og salg av kjøretøy som er fjernet, jf. § 37 femte til åttende ledd,
j. universell utforming av parkeringsareal og særskilt tilrettelegging for innehavere av parkeringstillatelse for forflytningshemmede, herunder krav til reservering,
k. kommunenes rettigheter og plikter ved parkeringstilbud på offentlig veg,
l. opprettelse av et sentralt register med oversikt over virksomheter, parkeringsområder, og over parkeringstillatelser til forflytningshemmede og institusjon, krav til bruk av registeret og gebyr for slik bruk. Et slikt register skal være i samsvar med det til enhver tid gjeldende regelverk.

Kongen kan gi forskrift om kommunens adgang til å reservere parkering etter behovsprøving i et nærmere avgrenset område for personer bosatt i området eller andre med særlig behov for slik parkering. Det samme gjelder adgang til å reservere enkelte parkeringsplasser for bestemte kjøretøy, kjøretøygrupper eller personer, eller gi disse adgang til å parkere utover eventuell maksimaltid på stedet.

Kongen kan gi nærmere bestemmelser om adgangen til å klage på ilagt kontrollsanksjon og fjerning i medhold av første ledd, herunder klagerett til en uavhengig parkeringsklagenemnd.[1] Det kan gis nærmere bestemmelser om organisering og oppgaver, saksbehandling, brukerfinansiering, herunder krav om rapportering av antall kontrollsanksjoner, og godtgjørelse til klagenemndas medlemmer. Det kan gis bestemmelser om at nemndas avgjørelser har rettskraft hvis de ikke bringes inn for domstolene. Det kan gis bestemmelse om at så lenge en tvist er til behandling i klagenemnda, kan ikke en part bringe den inn for de alminnelige domstolene. Det kan også gis bestemmelse om at dersom søksmål er reist ved de alminnelige domstoler og en part ønsker tvisten avgjort av parkeringsklagenemnda, kan vedkommende domstol stanse den videre behandling inntil parkeringsklagenemndas vedtak foreligger.

For annen parkering enn vilkårsparkering kan Kongen i forskrift gi regler om fjerning og forvaring av motorvogn som er plassert ulovlig på privat grunn når plasseringen er til fare eller vesentlig ulempe.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83285, 'lov/1965-06-18-4', 12, 2, 'kapittel-2-paragraf-10', '§ 9', 'Trafikkregulering.', 'Politiet kan regulere trafikken slik forholdene i hvert enkelt tilfelle krever det, og kan herunder fravike det som er fastsatt i eller i medhold av §§ 4, 5, 6, 7 og 8. Politiet kan også som ledd i trafikkregulering helt eller delvis sperre en vegstrekning for et kortere tidsrom.

Enhver plikter straks å rette seg etter de påbud og forbud om regulering av trafikken som politiet gir muntlig, eller ved tegn, skilt, signal eller på annen måte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83286, 'lov/1965-06-18-4', 13, 2, 'kapittel-2-paragraf-11', '§ 10', 'Trafikkontroll m.m.', 'Fører av kjøretøy skal straks stanse for kontroll når det kreves av politiet eller Statens vegvesen. Føreren plikter å vise fram dokumenter som det er påbudt å ha med under kjøringen, og straks etterkomme påbud gitt med hjemmel i denne lov.

Departementet kan gi andre offentlige tjenestemenn myndighet til å foreta kontroll og gi påbud som nevnt i første ledd.[1]', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83287, 'lov/1965-06-18-4', 14, 2, 'kapittel-2-paragraf-12', '§ 11', 'Unntak for utrykningskjøretøy m.m.', 'Kongen gir regler om adgang til å fravike det som er fastsatt i eller i medhold av §§ 4, 5, 6, 7, 8 og 9 for fører av utrykningskjøretøy, fører av kjøretøy i polititjeneste og fører av vegarbeidsmaskin eller annet kjøretøy som nyttes til arbeid på eller ved veg. Det samme gjelder for fører av kjøretøy i Statens vegvesens tjeneste og offentlig parkeringskontrolltjeneste.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83288, 'lov/1965-06-18-4', 15, 2, 'kapittel-2-paragraf-13', '§ 12', 'Plikter ved trafikkuhell.', 'Enhver som med eller uten skyld er innblandet i trafikkuhell, skal straks stanse og hjelpe personer og dyr som er kommet til skade, og for øvrig delta i de tiltak som uhellet gir grunn til. Denne plikt har, om det er nødvendig, også andre som er i nærheten eller som kommer til stede.

De som er innblandet i trafikkuhell, har gjensidig plikt til å oppgi navn og adresse. Fører av kjøretøy skal også oppgi eierens navn og adresse og i tilfelle motorvognens kjennemerke.

Har trafikkuhell medført død eller skade på person og skaden ikke er ubetydelig, skal de som er innblandet i uhellet, sørge for at politiet snarest mulig blir underrettet om uhellet. Før politiet kommer til stede etter slikt uhell, skal de som er innblandet, ikke forlate stedet uten at det er nødvendig eller politiets samtykke er innhentet. Må en som er innblandet i et uhell som nevnt, forlate stedet, skal han snarest underrette politiet om sin befatning med uhellet og om navn og adresse. Har trafikkuhell voldt materiell skade, og det ikke er noen til stede som kan vareta skadelidtes tarv, skal den som har voldt skaden, snarest mulig underrette skadelidte eller politiet om uhellet.

Kjøretøy som etter trafikkuhell er plassert slik at det kan være til fare eller hinder for trafikken, skal straks flyttes til et egnet sted. Dersom hensynet til trafikksikkerheten tillater det, skal de som er innblandet i uhellet, ha anledning til å foreta oppmåling og oppmerking før kjøretøyet flyttes. Har trafikkuhellet medført død eller alvorlig skade på person, må innblandet kjøretøy bare flyttes med politiets samtykke eller dersom det fører til vesentlig fare eller uforholdsmessig hindring av trafikken om kjøretøyet blir stående til politiet kommer. Må kjøretøy som er innblandet i slikt uhell, flyttes før politiet kommer til stedet, skal de som er innblandet i uhellet, så vidt mulig sørge for oppmåling eller oppmerking av kjøretøyets plassering.

Før politiet kommer til stede etter trafikkuhell som har medført død eller alvorlig skade på person, må spor ikke fjernes og andre forhold av betydning for etterforskningen ikke endres uten at det er strengt nødvendig. De som er innblandet i uhellet, skal søke å hindre fjerning av spor og endring av andre forhold av betydning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83289, 'lov/1965-06-18-4', 16, 3, 'kapittel-3-paragraf-1', '§ 13', 'Krav til kjøretøyer og bruk av kjøretøyer.', 'Kjøretøy skal være bygget, innrettet, utstyrt og vedlikeholdt slik at det kan brukes uten å volde unødig fare eller ulempe og uten å skade veg.

Departementet gir nærmere bestemmelser om bruk, og om konstruksjon, innretning, vekt, mål og utstyr, herunder verneutstyr, m.m. for de forskjellige grupper av kjøretøyer, og om last og antall personer kjøretøyet kan føre.

Departementet kan fastsette forskrift om at kjøretøy med tillatt totalvekt over 3 500 kg skal være utstyrt med elektronisk betalingsenhet tilknyttet gyldig avtale for kjøring på offentlig veg. Departementet kan gi nærmere bestemmelser om ordningen, herunder bestemmelser om virkeområde og hvilke grupper kjøretøy som skal omfattes.

Departementet kan fastsette at kjøretøy skal være utstyrt med fartsskriver for registrering av kjøre- og hviletid, arbeidstid, ferie- og sykefravær, hastighet, kjøretøyets posisjoner herunder grensepasseringer, lasting og lossing mv., jf. § 21 annet ledd. Slike registreringer kan benyttes til kontroll av overholdelsen av regler gitt i og i medhold av denne loven, yrkestransportloven, arbeidsmiljøloven og allmenngjøringsloven. Departementet gir nærmere bestemmelser om godkjenning, montering og kontroll av fartsskriver. Utgiftene til anskaffelse, montering og kontroll av fartsskrivere dekkes av kjøretøyets eier.

Endringer som øker den maksimale hastighet eller ytelse på motorsykkel (herunder moped) utover grenser fastsatt for vedkommende gruppe av motorsykler i medhold av annet ledd, må ikke foretas.

Med samtykke fra departementet kan en kommune innføre gebyr for bruk av piggdekk i nærmere fastsatt område. Departementet kan gi nærmere bestemmelser om slikt tiltak. Departementet kan pålegge en kommune å gjennomføre ordning som nevnt i dette ledd.

Med samtykke fra departementet kan en kommune for å begrense miljøulemper fra vegtrafikken innføre lavutslippssone i et fastsatt område. Departementet kan gi nærmere bestemmelser om plikt til å medbringe dokumentasjon av kjøretøyets utslippsnivå, rett til å kreve opplyst og å lagre kjøretøyinformasjon og informasjon om eier og bruker mv. til bruk i betalings- og kontrollsammenheng, herunder rett til å kreve bruk av elektronisk enhet om bord i motorvogn for elektronisk identifikasjon. Departementet kan gi bestemmelser om gebyr for kjøring i sonen, tilleggsgebyr for brudd på bestemmelsene, og bestemmelser om håndheving og bruk av inntekt av ordningen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83290, 'lov/1965-06-18-4', 17, 3, 'kapittel-3-paragraf-2', '§ 13 a', 'Forbud mot varslingsutstyr, manipulasjonsutstyr o.l. i motorvogn.', 'I motorvogn er det forbudt å besitte eller bruke utstyr som har til formål å:
a. varsle om eller forstyrre trafikkontroller
b. overstyre eller manipulere fartsskriver som nevnt i § 13 fjerde ledd, speedometer, alkolås, forurensningsbegrensende utstyr eller annet påkrevd teknologisk utstyr slik at bruken av utstyret fører til misvisende eller uriktige opplysninger eller signaler.

Forbudet etter første ledd omfatter utstyr som blokkerer eller skjuler signaler eller opplysninger fra eller til utstyr for kontroll og overvåkning av trafikk, eller som endrer hvordan påkrevet teknologisk utstyr brukes.

Departementet kan i forskrift gi forbud mot å produsere, distribuere, markedsføre og/eller selge utstyr som nevnt i første ledd. Departementet kan videre gi forskrifter med nærmere bestemmelser til presisering og utfylling av forbudene i denne paragrafen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83291, 'lov/1965-06-18-4', 18, 3, 'kapittel-3-paragraf-3', '§ 13 b', 'Krav til CO2-utslipp mv. for produsenter av personbiler, varebiler og tunge kjøretøy', 'For å ivareta Norges forpliktelser etter EØS-avtalen kan departementet i forskrift fastsette regler om utslippskrav mv. for produsenter av kjøretøy i gruppe M, N og O, herunder regler om:
a. krav til utslipp av CO2,
b. overtredelsesgebyr,
c. overvåkning,
d. rapportering,
e. innovative teknologier, herunder godkjenning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83292, 'lov/1965-06-18-4', 19, 3, 'kapittel-3-paragraf-4', '§ 14', 'Godkjenning av kjøretøyer og utstyr m.m.', 'Departementet gir nærmere bestemmelser om undersøkelse og godkjenning (herunder typegodkjenning) av kjøretøyer og av deler og utstyr til kjøretøyer.

Departementet kan bestemme at visse deler eller utstyr til kjøretøyer eller til vern for fører, passasjerer eller andre i trafikken skal godkjennes (eller typegodkjennes) før det tillates brukt, og kan forby handel med deler eller utstyr som ikke er godkjent.

Departementet kan bestemme at det for godkjenning som nevnt i første eller annet ledd skal betales gebyr. Departementet kan gi nærmere bestemmelser om gebyr for manglende fremstilling av kjøretøy til forvaltningskontroll hos Statens vegvesen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83293, 'lov/1965-06-18-4', 20, 3, 'kapittel-3-paragraf-5', '§ 15', 'Registrering av motorvogn.', 'Motorvogner skal registreres. Departementet gir nærmere bestemmelser om slik offentlig registrering av motorvogner, om kjennemerker (nummerskilt) og om vognkort. Departementet kan bestemme at tilhenger til motorvogn skal registreres som motorvogn.

Den som melder en motorvogn til registrering, har plikt til å gi de opplysninger som kreves i samband med registreringen.

Når motorvogn skifter eier, skal både den tidligere og den nye eier innen 3 dager gi skriftlig melding til registreringsmyndigheten. Eier av motorvogn plikter å melde adresseendring innen 3 dager til registreringsmyndigheten.

Registrering kan ikke skje uten at det er lagt fram trygdeerklæring fra et trygdelag i samsvar med bilansvarslova eller bevis for at motorvognen ikke trenger å være trygdet etter nevnte lov.

Utgiftene til kjennemerker bæres av motorvognens eier dersom ikke departementet bestemmer noe annet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83294, 'lov/1965-06-18-4', 21, 3, 'kapittel-3-paragraf-6', '§ 16', 'Unntak fra registreringsplikten.', 'Departementet kan unnta bestemte grupper av kjøretøy eller bestemt bruk av kjøretøy fra registreringsplikt m.m. etter § 15.

Registreringsmyndigheten kan tillate bruk av motorvogn for kortere tid eller for et enkelt høve uten at motorvognen er registrert m.m. etter § 15. I så fall skal motorvognen være i forsvarlig stand og være påsatt særlige kjennemerker. Før tillatelsen blir gitt, må det i samsvar med bilansvarslova være lagt fram trygdeerklæring fra et trygdelag eller bevis for at motorvognen ikke trenger å være trygdet etter nevnte lov.

Departementet kan gi nærmere bestemmelser om tillatelse til slik bruk av motorvogn som nevnt i annet ledd og kan sette særlige vilkår for tillatelsen, herunder krav om gebyr.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83295, 'lov/1965-06-18-4', 22, 3, 'kapittel-3-paragraf-7', '§ 17', 'Bruk av motorvogn mv.', 'For så vidt ikke annet følger av § 16, må motorvogn eller andre registreringspliktige kjøretøyer ikke brukes uten at de er meldt til registrering og påsatt lovlige kjennemerker og det er utferdiget vognkort. Vognkortet skal alltid følge med under bruken. Registreringspliktig kjøretøy som er avregistrert eller er uten lovlige kjennemerker, skal ikke være parkert utover 14 dager på offentlig veg eller privat veg skiltet med offentlig trafikkskilt.

Eier av motorvogn eller den som på eierens vegne har rådighet over den, plikter å forvisse seg om at den som han lar bruke motorvognen, fyller vilkårene for å føre den.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83296, 'lov/1965-06-18-4', 23, 3, 'kapittel-3-paragraf-8', '§ 18', 'Krav om alkolås ved transport mot vederlag', 'Departementet kan fastsette i forskrift at det skal være montert alkolås i kjøretøy som benyttes ved transport mot vederlag, og gir nærmere bestemmelser om godkjenning, montering og kontroll av alkolåsen. Utgifter til anskaffelse, montering og kontroll av alkolåsen dekkes av den som driver transport mot vederlag. Departementet kan gi nærmere bestemmelser om ordningen, herunder bestemmelser om virkeområde, hvilke grupper kjøretøy som skal omfattes, og om pålegg om retting ved kontroll langs veg.', '2018-05-01', 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83297, 'lov/1965-06-18-4', 24, 3, 'kapittel-3-paragraf-9', '§ 19', 'Kontroll av kjøretøy', 'Eier av kjøretøy eller den som på eierens vegne har rådighet over det, skal framstille kjøretøyet til kontroll når politiet eller Statens vegvesen krever det. Vedkommende skal også gi opplysninger om kjøretøyet når det kreves.

Departementet kan i forskrift gi regler om kontroll av kjøretøy etter første ledd og om gebyr. Departementet kan i forskrift også gi regler om kontroll av kjøretøy langs veg og om kriterier for utvelgelse av kjøretøy til slik kontroll. I forskriften kan det gis nærmere regler om krav til kompetanse for kontrollører, herunder personell som gjennomfører foretakskontroll etter § 21, om krav til kontrollutstyr og om kontrollgebyr.

Departementet kan i forskrift gi regler om at kjøretøyfabrikanter og deres kontaktpunkt skal gjøre tilgjengelig tekniske opplysninger om kjøretøy til bruk i kontroll av kjøretøy.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83298, 'lov/1965-06-18-4', 25, 3, 'kapittel-3-paragraf-10', '§ 19 a', 'Periodisk kjøretøykontroll', 'Periodisk kjøretøykontroll kan bare utføres av godkjente virksomheter med godkjente kontrollører og godkjent teknisk leder. For godkjenning må kontrollør og teknisk leder fremlegge ordinær politiattest for å vise at vedkommende er skikket til oppgaven.

Departementet kan i forskrift gi regler om vilkår og overgangsordninger for godkjenning som nevnt i første ledd, om opplæringsvirksomhet, om godkjennings- og tilsynsmyndigheten og om gebyrer for godkjenning og tilsyn. Departementet kan i forskrift også gi regler om pålegg om retting, advarsel og tilbakekall av godkjenningen, om stansing av virksomheten og om tvangsmulkt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83299, 'lov/1965-06-18-4', 26, 3, 'kapittel-3-paragraf-11', '§ 19 b', 'Krav til verksteder m.m.', 'Reparasjon, vedlikehold, ombygging, oppbygging og påbyggingsarbeid på motorvogn og tilhenger til motorvogn kan bare foretas av godkjent virksomhet. Det samme gjelder for montering, kontroll og reparasjon av fartsskriver. For å få godkjenning til å montere, kontrollere og reparere fartsskriver må virksomhetens ansvarlige leder fremlegge ordinær politiattest for å vise at vedkommende er skikket til oppgaven.

Departementet kan i forskrift gi regler om godkjenning av verksteder som skal montere, kontrollere og reparere sikkerhetsmessige eller miljømessige innretninger i kjøretøyer.

Departementet kan i forskrift gi regler om vilkårene og overgangsordninger for godkjenning av virksomheter som nevnt i første og andre ledd, godkjenning av virksomhetens leder, og om tilsyn med slik virksomhet. Departementet kan også gi regler om godkjennings- og tilsynsmyndighet, om plikt til å bistå tilsynsmyndigheten og om gebyrer for godkjenning og tilsyn. Departementet kan i forskriften gi regler om pålegg om retting, advarsel og tilbakekall av godkjenningen, om stansing av virksomheten og om tvangsmulkt.

I forskrift kan departementet gjøre unntak fra kravet om godkjenning for enkelte typer kjøretøy, for enkelte typer arbeid og for enkelte virksomheter og personer etter nærmere angitte vilkår.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83300, 'lov/1965-06-18-4', 27, 3, 'kapittel-3-paragraf-12', '§ 19 c', 'Kontroll av virksomheter som driver handel med motorvogner mv.', 'Statens vegvesen kan, etter nærmere regler gitt av departementet i forskrift, kontrollere motorvogner, tilhengere og godkjenningspliktig utstyr i virksomheter der dette selges.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83301, 'lov/1965-06-18-4', 28, 3, 'kapittel-3-paragraf-13', '§ 20', 'Utenlandsk motorvogn.', 'Departementet[1] gir bestemmelser om i hvilken utstrekning og på hvilke vilkår motorvogn eller tilhenger som er registrert eller hjemmehørende i fremmed stat kan tillates brukt her i riket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83302, 'lov/1965-06-18-4', 29, 4, 'kapittel-4-paragraf-1', '§ 21', 'Alminnelige plikter.', 'Ingen må føre eller forsøke å føre kjøretøy når han er i en slik tilstand at han ikke kan anses skikket til å kjøre på trygg måte, hva enten dette har sin årsak i at han er påvirket av alkohol eller annet berusende eller bedøvende middel, eller i at han er syk, svekket, sliten eller trett, eller skyldes andre omstendigheter.

Departementet kan gi forskrifter om kjøre- og hviletid, om bruk av fartsskrivere, om arbeidstid og om arbeidsvilkår for førere, grupper av førere, andre arbeidstakere innenfor vegtransport og avtalepart i transportoppdrag. Departementet kan videre gi forskrifter om plikt til å registrere opplysninger som nevnt i første punktum, om ferie- og sykefravær og om lagring, nedlasting, oppbevaring, innsending og kontroll av opplysningene og om kontrollmyndighetenes tilgang til virksomheter, kjøretøy og kontrollapparater. Departementet kan også gi forskrifter om gebyr for utstedelse av fartsskriverkort.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83303, 'lov/1965-06-18-4', 30, 4, 'kapittel-4-paragraf-2', '§ 22', 'Ruspåvirkning av motorvognfører', 'Ingen må føre motorvogn når han er påvirket av alkohol eller annet berusende eller bedøvende middel.

Har han større alkoholkonsentrasjon i blodet enn 0,2 promille eller en alkoholmengde i kroppen som kan føre til så stor alkoholkonsentrasjon i blodet, eller større alkoholkonsentrasjon i utåndingsluften enn 0,1 milligram per liter luft, regnes han i alle tilfeller for påvirket av alkohol i henhold til bestemmelsene i loven.

Overstiger konsentrasjon i blodet av annet berusende eller bedøvende middel grenser fastsatt i forskrift gitt med hjemmel i loven, eller en mengde slikt middel i kroppen som kan føre til så stor konsentrasjon av slikt middel i blodet, regnes han i alle tilfeller for påvirket i forhold til bestemmelsene i loven. Dette gjelder likevel ikke hvor overskridelsen skyldes legemiddel inntatt i henhold til gjeldende forskrivning fra lege eller tannlege.

Villfarelse med hensyn til alkoholkonsentrasjonens størrelse fritar ikke for straff. Det samme gjelder villfarelse med hensyn til størrelsen av konsentrasjonen av annet berusende eller bedøvende middel, med mindre slikt middel er inntatt i henhold til gjeldende forskrivning fra lege eller tannlege, jf. tredje ledd.

Fører av motorvogn må ikke nyte alkohol eller ta annet berusende eller bedøvende middel i de første seks timene etter at han er ferdig med kjøringen, når han forstår at det kan bli politietterforskning på grunn av kjøringen eller utviser grov uaktsomhet i så måte. Dette forbudet gjelder likevel ikke etter at blodprøve eller utåndingsprøve er tatt, eller politiet har avgjort at slik prøve ikke skal tas.

Departementet kan gi forskrift om grenser for konsentrasjoner i blodet av annet berusende eller bedøvende middel som nevnt i tredje ledd og § 31 annet ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83304, 'lov/1965-06-18-4', 31, 4, 'kapittel-4-paragraf-3', '§ 22 a', 'Politiets testing av ruspåvirkning', 'Politiet kan ta alkotest (foreløpig blåseprøve) og foreløpig test av om motorvognfører er påvirket av annet berusende eller bedøvende middel når:
1. det er grunn til å tro at han har overtrådt bestemmelsene i § 22 eller § 22 b,
2. det er grunn til å tro at han har overtrådt andre bestemmelser som er gitt i eller i medhold av denne lov, og departementet har bestemt at overtredelsen kan ha slik virkning,
3. han med eller uten egen skyld er innblandet i trafikkuhell, eller
4. han er blitt stanset i trafikkontroll.

Dersom testresultatet eller andre forhold gir grunn til å tro at fører av motorvogn har overtrådt bestemmelsene i § 22 eller § 22 b, kan politiet foreta særskilt undersøkelse av om det forekommer tegn og symptomer på ruspåvirkning og fremstille ham for utåndingsprøve, blodprøve, spyttprøve og klinisk legeundersøkelse for å søke å fastslå påvirkningen. Slik fremstilling skal i alminnelighet finne sted når føreren nekter å medvirke til alkotest eller foreløpig test av om føreren er påvirket av annet berusende eller bedøvende middel.

Utåndingsprøve tas av politiet. Blodprøve og spyttprøve kan tas av lege, sykepleier, helsesekretær eller bioingeniør. Klinisk legeundersøkelse foretas når det er mistanke om påvirkning av andre midler enn alkohol eller andre særlige grunner taler for det.

Departementet gir nærmere bestemmelser om undersøkelsene nevnt i de foregående ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83305, 'lov/1965-06-18-4', 32, 4, 'kapittel-4-paragraf-4', '§ 22 b', 'Pliktmessig avhold', 'Den som fører motorvogn i stilling eller yrke som medfører befordring av personer eller gods, må i tjenestetiden ikke nyte alkohol eller ta annet berusende eller bedøvende middel.

Tjenestetiden omfatter tidsrommet fra den tid da vedkommende i henhold til sine tjenesteplikter påbegynner utførelsen av slikt arbeid som stillingen krever og inntil arbeidet avsluttes. Forbudet gjelder også i et tidsrom av 8 timer før tjenestetiden begynner.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83306, 'lov/1965-06-18-4', 33, 4, 'kapittel-4-paragraf-5', '§ 22 c', 'Tolletatens testing av ruspåvirkning', 'Tolletaten kan ta alkotest (foreløpig blåseprøve) og foreløpig test av om motorvognføreren er påvirket av annet berusende eller bedøvende middel når motorvognen er stanset i kontroll etter vareførselsloven § 8-1 første ledd, jf. § 8-2 bokstav b.

Dersom testresultatet gir grunn til å tro at føreren av motorvognen har overtrådt bestemmelsen i § 22, skal politiet straks varsles. Tolletaten kan holde føreren tilbake med makt dersom føreren forsøker å unndra seg testing eller inntil føreren er overlevert politiet. Maktbruken må være nødvendig og stå i forhold til situasjonens alvor, tjenestehandlingens formål og omstendighetene for øvrig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83307, 'lov/1965-06-18-4', 34, 4, 'kapittel-4-paragraf-6', '§ 23', 'Ansvar for kjøretøyets stand m.m.', 'Før kjøringen begynner, skal føreren forvisse seg om at kjøretøyet er i forsvarlig og forskriftsmessig stand og at det er forsvarlig og forskriftsmessig lastet. Han skal sørge for at kjøretøyet også under bruken er i forsvarlig stand og forsvarlig lastet.

Eier av kjøretøy eller den som på eierens vegne har rådighet over det, plikter å sørge for at kjøretøyet ikke brukes dersom det ikke er i forsvarlig stand.

Ved transportoppdrag skal transportforetaket sette føreren i stand til å oppfylle sine plikter etter første ledd slik at kjøretøyet er forsvarlig og forskriftsmessig lastet. Departementet kan i forskrift gi nærmere regler om transportforetakets plikter, herunder nærmere regler for visse typer kjøretøy.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83308, 'lov/1965-06-18-4', 35, 4, 'kapittel-4-paragraf-7', '§ 23 a', 'Personlig verneutstyr.', 'Kongen[1] kan bestemme at personlig verneutstyr og annet utstyr til sikring av personer skal brukes under kjøring med motorvogn. Kongen kan gi nærmere regler om omfanget av bruken og unntak fra påbudet. Det kan bestemmes at føreren skal være ansvarlig for at passasjer under 15 år bruker utstyr som nevnt i første punktum.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83309, 'lov/1965-06-18-4', 36, 4, 'kapittel-4-paragraf-8', '§ 23 b', 'Forbud mot bruk av elektronisk utstyr i motorvogn', 'Departementet kan gi nærmere bestemmelser om forbud mot bruk i motorvogn av elektronisk utstyr som kan forstyrre føreren.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83310, 'lov/1965-06-18-4', 37, 4, 'kapittel-4-paragraf-9', '§ 24', 'Alminnelige regler om førerett, førerkort, føreprøve og kompetansebevis', 'Den som skal føre motorvogn må ha førerett og ha ervervet førerkort der dette kreves, samt eventuelt gyldig kompetansebevis, for vedkommende gruppe av motorvogner. Under kjøring skal fører alltid ha førerkort og kompetansebevis med seg.

Departementet kan bestemme at offentlig aldersbevis eller bevis for å ha gjennomgått bestemt opplæring må medbringes under kjøring med førerkortfrie motorvogner.

Den som skal få førerett for personbil, må være fylt 18 år. Departementet kan fastsette en høyere eller lavere nedre aldersgrense for førerett for bestemte førerkortklasser.

Den som skal få førerkort må være edruelig, og det må ikke være noe å si på hans vandel ellers. Han må ha tilstrekkelig syn og førlighet, nødvendig fysisk og psykisk helse og ha bestått førerprøve. Ved kjøring til førerprøve anses kandidat som fører av motorvognen.

Departementet kan gi forskrift om førerprøve og førerett, herunder gebyr, gyldighetstid, fastlagt føreropplæring før førerprøve, helsekrav, krav til tilleggsopplæring og vilkår og begrensninger i føreretten. Departementet kan ved forskrift fastsette nærmere bestemmelser om at den som ikke består førerprøve, utrykningsprøve eller prøve for yrkessjåførkompetanse kan forbys å gå opp til ny prøve i en periode på inntil to måneder (karantene).

Departementet kan gi forskrift om førerkort og kompetansebevis, herunder gebyr, førerkortklasser, gyldighetstid, utferdigelse, utskifting, unntak fra førerkortplikt, midlertidig kjøretillatelse, aldersbevis og bevis for å ha gjennomgått bestemt trafikkopplæring.

Dersom innehaver av førerkort ikke lenger fyller de krav som er fastsatt til syn, helse og førlighet etter femte ledd, plikter han å gi melding om det til statsforvalteren som må gi melding til politiet, jf. § 34.

Departementet kan gi nærmere bestemmelser om utstedelse av norsk førerkort på grunnlag av gyldig utenlandsk førerett. Det kan herunder gis bestemmelser om innlevering av det utenlandske førerkortet, samt om innhenting av opplysninger om vedkommende. Det kan også bestemmes at førerprøve kan unnlates eller at vedkommende skal ha bestått en forenklet førerprøve.

Departementet kan sette særlige vilkår i tillegg til vilkårene i tredje og fjerde ledd for den som vil ha førerett for bestemte førerkortklasser eller for bestemte grupper av motorvogner.

Departementet kan gi forskrift om kvalifikasjonskrav, herunder grunn- og etterutdanning for førerprøvesensorer.

Den som forsettlig eller grovt uaktsomt fusker eller forsøker å fuske på førerprøven, kan ilegges karantene på inntil ett år og kan nektes å gå opp til prøve i andre førerkortklasser i denne perioden. Departementet kan ved forskrift fastsette nærmere bestemmelser om slik karantene. Departementet kan ved forskrift fastsette tilsvarende regler for utrykningsprøve og prøve for yrkessjåførkompetanse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83311, 'lov/1965-06-18-4', 38, 4, 'kapittel-4-paragraf-10', '§ 24 a', 'Sperrefrist for retten til å føre førerkortpliktig motorvogn på grunn av straffbart forhold m.m.', 'Den som har kjørt motorvogn uten å ha førerett for den aktuelle førerkortklassen, kan ikke få slik førerett første gang før det er gått 6 måneder siden den ulovlige kjøringen fant sted. Er han yngre enn den lovlige minstealderen for slik førerett, løper sperrefristen til det er gått 6 måneder fra den dagen han oppnår minstealderen. Er det voldt større skade ved kjøringen, skal sperrefristen etter første og andre punktum være ett år. Tilsvarende gjelder også for den som ulovlig endrer maksimal hastighet eller ytelse i motorvogn i strid med § 13 femte ledd.

Blir en som ikke har førerett ilagt straff for en overtredelse som ville ha ført til tap av retten til å føre motorvogn for en viss minstetid eller for alltid etter tvingende regler i eller i medhold av § 33, skal det i samme dom, forelegg eller beslutning om overføring til konfliktrådet fastsettes en sperrefrist for å gi førerett til vedkommende. Fristen skal ikke settes kortere enn den perioden for tap av førerett som i tilfelle skulle ha vært fastsatt etter § 33.

Blir den som ikke har førerett, med skjellig grunn mistenkt for straffbart forhold som kan ha betydning for adgangen til å få førerkort, kan politimesteren eller den han gir myndighet bestemme at førerett ikke kan erverves før saken er endelig avgjort, likevel ikke ut over 3 måneder uten kjennelse av tingretten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83312, 'lov/1965-06-18-4', 39, 4, 'kapittel-4-paragraf-11', '§ 25', '(Opphevet)', '', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83313, 'lov/1965-06-18-4', 40, 4, 'kapittel-4-paragraf-12', '§ 26', 'Øvingskjøring.', 'Øvingskjøring må ikke være til fare eller unødig ulempe for annen trafikk. Politiet kan av hensyn til trafikkforholdene forby eller begrense øvingskjøring på bestemte steder og til bestemte tider.

Øvingskjøring med motorvogn må ikke finne sted tidligere enn 2 år før det tidspunkt da eleven etter sin alder kan få førerett for vedkommende motorvogngruppe. Departementet kan fastsette strengere alderskrav for øvingskjøring for visse motorvogngrupper. Er øvingskjøringen ledd i føreropplæring mot vederlag, kan den bare finne sted når det brukes godkjent lærevogn og eleven ledsages i vognen av godkjent lærer. I andre tilfelle må eleven ledsages i motorvognen av person som har fylt 25 år og har gyldig førerett for vedkommende motorvogngruppe og har hatt slik førerett uavbrutt i minst 5 år. Departementet kan ved forskrift fravike kravet om godkjent lærer og godkjent lærevogn, jf. tredje punktum, og fastsette tilleggskrav for øvingskjøring med visse motorvogner.

Obligatorisk opplæring i glattkjøring kan bare gjennomføres på øvingsbaner som er særskilt godkjent av Vegdirektoratet.

Departementet kan gi forskrifter om øvingskjøring og kan på vilkår tillate øvingskjøring med visse motorvogner eller på visse områder uten at lærer eller ledsager følger med i kjøretøyet.

Ved øvingskjøring anses lærer eller ledsager som fører av motorvognen. Det som er bestemt i eller i medhold av kap. II og §§ 21, 22 og 22 a), gjelder likevel også for eleven.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83314, 'lov/1965-06-18-4', 41, 4, 'kapittel-4-paragraf-13', '§ 27', 'Opplæringsinstitusjoner for førerkortrettet opplæring m.m.', 'Førerkortrettet opplæring mot vederlag kan bare gis av offentlig skoleverk og godkjente virksomheter med godkjente trafikklærere og godkjent faglig leder. Den som skal godkjennes som trafikklærer, må fremlegge ordinær politiattest som viser at vedkommende er skikket til oppgaven.

Departementet kan i forskrift:
a. gi regler om godkjenning og drift av virksomheter etter første ledd, gjøre unntak fra kravet om godkjenning etter første ledd og gi nærmere regler om gjennomføringen av førerkortrettet opplæring, herunder sette begrensninger for hvilke klasser og emner det kan gis opplæring innenfor,
b. stille krav til den som skal gi opplæring mot vederlag og faglig ansvarlig, herunder vilkår for godkjenningen, krav til alder, utdanning, førerkort, edruelighet og helse, tilleggskrav for undervisning i visse klasser, emner eller visse oppgaver, krav til regodkjenning og etterutdanning samt fastsette overgangsordninger,
c. gi regler om tilsyn med godkjenningspliktig opplæring, herunder krav til tilsynsmyndigheten og tilsynspersonell samt tilsynssubjektets plikt til å medvirke,
d. gi regler om pålegg om retting og stans av virksomheten, advarsel og tilbakekall av godkjenningen, tvangsmulkt og om avbrytelse og underkjenning av opplæring, herunder at undervisning i offentlig skoleverk kan avbrytes og underkjennes,
e. gi regler om gebyr for godkjenning og tilsyn.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83315, 'lov/1965-06-18-4', 42, 4, 'kapittel-4-paragraf-14', '§ 28', 'Trafikkopplæring.', 'Departementet kan gi nærmere bestemmelser om teoretisk og praktisk opplæring mot vederlag av personer som vil erverve førerett, kompetansebevis eller bevis for å ha gjennomgått annen bestemt trafikkopplæring. Det kan herunder fastsettes læreplan for undervisningen. Departementet kan bestemme at lærevogn og opplæringsmateriell ellers skal godkjennes av vedkommende myndighet.

Departementet kan gi nærmere regler om godkjenning av pris for bruk av øvingsbaner til obligatorisk opplæring for fører av tunge kjøretøy.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83316, 'lov/1965-06-18-4', 43, 4, 'kapittel-4-paragraf-15', '§ 29', 'Kvalifikasjonskrav til yrkessjåfører', 'Den som mot vederlag skal føre motorvogn, må tilfredsstille krav til grunn- og etterutdanning i forskrift gitt av departementet. Bevis for gjennomført utdanning skal alltid medbringes under kjøring.

Departementet kan gi forskrift om grunn- og etteropplæring, prøver, gebyr, bevis, samt vilkår for godkjenning og drift av lære- og prøvesteder, herunder krav til personell. Departementet kan videre gi forskrift om tilsyn med lære- og prøvesteder.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83317, 'lov/1965-06-18-4', 44, 4, 'kapittel-4-paragraf-16', '§ 29 a', 'Opplæringsinstitusjoner for fører av utrykningskjøretøy m.m.', 'Opplæring med sikte på å erverve kompetansebevis for utrykningskjøring kan bare gis av Politihøgskolen og godkjente kursarrangører med godkjent utrykningsinstruktør og undervisningsansvarlig.

Departementet kan i forskrift:
a. gi regler for godkjenning og drift av opplæringsinstitusjoner etter første ledd, fastsette begrensninger i retten til drift, gjøre unntak fra kravet til godkjenning etter første ledd samt regulere gjennomføringen av opplæringen,
b. stille krav til utrykningsinstruktøren og undervisningsansvarlig, herunder vilkår for godkjenningen, utdanning, førerett og erfaring for å inneha slik godkjenning, krav om etterutdanning og regodkjenning samt fastsette overgangsordninger,
c. gi regler om tilsyn med godkjenningspliktig opplæring, herunder krav til tilsynsmyndigheten og tilsynspersonell samt tilsynssubjektets plikt til å medvirke,
d. gi regler om pålegg om retting og stans av virksomheten, advarsel og tilbakekall av godkjenningen, tvangsmulkt og om avbrytelse og underkjenning av opplæring, herunder at undervisning i offentlig skoleverk kan avbrytes og underkjennes,
e. gi regler om gebyr for godkjenning og tilsyn.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83318, 'lov/1965-06-18-4', 45, 4, 'kapittel-4-paragraf-17', '§ 30', 'Motorvognfører med utenlandsk førerkort eller kompetansebevis', 'Departementet gir forskrift om i hvilken utstrekning og på hvilke vilkår innehaver av gyldig førerkort og annet påkrevd bevis for kompetanse utstedt i fremmed stat skal kunne føre motorvogn her i riket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83319, 'lov/1965-06-18-4', 46, 5, 'kapittel-5-paragraf-1', '§ 31', 'Alminnelige straffebestemmelser', 'Den som forsettlig eller uaktsomt overtrer bestemmelser gitt i eller i medhold av denne lov, straffes med bøter eller med fengsel inntil ett år, dersom forholdet ikke går inn under strengere straffebud. På samme måte straffes overtredelse av vilkår i enkeltvedtak i medhold av denne lov og brudd på forbud etter §§ 35 og 36. Forsøk straffes ikke, med unntak for § 22 første ledd. Den som ved bruk av motorvogn uaktsomt volder betydelig legemsskade eller en annens død, straffes etter straffeloven § 280 eller § 281.

Den som overtrer § 22 første ledd, straffes som regel
a. med bot ved alkoholkonsentrasjon i blodet til og med 0,5 promille eller alkoholkonsentrasjon i utåndingsluften til og med 0,25 milligram per liter luft, eller ved nærmere bestemt konsentrasjon i blodet av annet berusende eller bedøvende middel,
b. med bot og betinget eller ubetinget fengsel ved alkoholkonsentrasjon i blodet over 0,5 til og med 1,2 promille eller alkoholkonsentrasjon i utåndingsluften over 0,25 til og med 0,6 milligram per liter luft, eller ved nærmere bestemt konsentrasjon i blodet av annet berusende eller bedøvende middel,
c. med bot og ubetinget fengsel ved alkoholkonsentrasjon i blodet over 1,2 promille eller alkoholkonsentrasjon i utåndingsluften over 0,6 milligram per liter luft, eller ved nærmere bestemt konsentrasjon i blodet av annet berusende eller bedøvende middel.

Påvirkningsgraden hos førere som har inntatt legemiddel i henhold til gjeldende forskrivning fra lege eller tannlege, vurderes konkret.

Ved utmåling av straffen etter annet ledd tas særlig hensyn til graden av påvirkning og hvilke farer kjøringen har medført. Den som overtrer § 22 første ledd, jf. § 31 annet ledd bokstav a, og som tidligere er straffet etter § 22 første ledd, jf. § 31 annet eller fjerde ledd, straffes som regel med bot eller bot og betinget fengsel. Den som overtrer § 22 første ledd, jf. § 31 annet ledd bokstav b eller c, og som tidligere er straffet etter § 22 første ledd, jf. § 31 annet eller fjerde ledd, straffes som regel med bot og ubetinget fengsel.

I stedet for bot og ubetinget fengsel kan det idømmes bot og betinget fengsel med vilkår som nevnt i straffeloven § 37 bokstav f.

Overtredelse av § 22 femte ledd straffes med bot og fengsel.

Parkeringsovertredelser som ikke omfattes av bestemmelser gitt i medhold av § 8, og overtredelser av forbud mot stans straffes bare dersom parkeringen har voldt eller kunne ha voldt alvorlig trafikkhindring eller fare for person eller gods. Ellers ilegges gebyr etter § 31 a.

Etter nærmere regler gitt av Kongen kan det ilegges gebyr i stedet for straff også ved overtredelse av andre regler gitt i eller i medhold av denne lov.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83320, 'lov/1965-06-18-4', 47, 5, 'kapittel-5-paragraf-2', '§ 31 a', 'Gebyr for parkeringsovertredelser og visse andre overtredelser.', 'Gebyr etter § 31 ilegges av politiet. Kongen kan gi andre offentlige organer tilsvarende gebyrmyndighet.

Kongen kan, etter at uttalelse er innhentet fra vedkommende politimester, gi forskrift om at slik myndighet som etter denne paragraf er tillagt politiet også skal kunne utøves av kommunen. Kongen kan gi forskrift om gjennomføringen av slike ordninger og hvordan kommunalt oppkrevde gebyrer skal brukes.

Blir ilagt gebyr ikke betalt innen tre uker etter ileggelsen, løper forsinkelsesrente etter forsinkelsesrenteloven. Dette gjelder selv om gebyret er påklaget.

Ileggelse av gebyr kan innklages for tingretten innen en fastsatt frist. Blir klage fremsatt etter utløpet av fristen, skal den avvises med mindre retten finner at oversittelsen hverken kan legges eier eller bruker av kjøretøyet til last og klagen er fremsatt så snart det var mulig. Retten kan oppheve ilagt gebyr hvis den finner at vilkårene for ileggelse ikke forelå. Avgjørelsen treffes ved kjennelse og kan ankes. Ileggelse av gebyr kan ikke prøves under tvangsinndrivelse av gebyret.

Ilagt gebyr og tilleggsgebyr kan inndrives etter reglene i § 38, fjorten dager etter at varsel om inndriving er kommet fram til eieren av kjøretøyet.

Kongen fastsetter størrelsen av gebyret og gir nærmere regler om ileggelse og inndriving, om betalings- og klagefrist og om klagebehandlingen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83321, 'lov/1965-06-18-4', 48, 5, 'kapittel-5-paragraf-3', '§ 31 b', 'Forenklet forelegg.', 'Kongen kan bestemme at bøteleggelse på stedet eller i ettertid for lovbrudd av nærmere angitt art kan skje ved forenklet forelegg etter faste bøtesatser. I slikt forelegg kan straffebudet og det straffbare forhold betegnes ved stikkord eller på liknende måte.

Forelegg utskrevet på stedet faller bort dersom det ikke straks vedtas. For forelegg utskrevet i ettertid gjelder straffeprosessloven § 256 nr. 5 tilsvarende. Slikt forelegg faller bort dersom det ikke vedtas innen fristen. Kongen kan gi nærmere regler om framgangsmåten når forelegget utskrives i ettertid.

Påtalemyndigheten kan til gunst for siktede oppheve vedtatt forelegg.

Polititjenestepersoner som ellers ikke har foreleggsmyndighet, kan gis myndighet til å utferdige forenklet forelegg.

Kongen gir nærmere regler om bruk av forenklet forelegg og fastsetter bøtesatser og subsidiær fengselsstraff for de forskjellige lovbrudd som ordningen skal omfatte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83322, 'lov/1965-06-18-4', 49, 5, 'kapittel-5-paragraf-4', '§ 32', 'Overtredelse av vegtrafikkbestemmelser i utlandet', 'Departementet kan gi forskrift om at virksomhet og fører som på fremmed stats territorium har brutt kjøre- og hviletidsbestemmelser gitt i medhold av § 21 andre ledd, kan straffes her i riket i samsvar med § 31. Dette gjelder uavhengig av førerens statsborgerskap, virksomhetens hovedsete, eller lignende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83323, 'lov/1965-06-18-4', 50, 5, 'kapittel-5-paragraf-5', '§ 33', 'Tap av retten til å føre førerkortpliktig motorvogn mv.', '1. Blir den som har førerett ilagt straff, kan det i samme dom, forelegg eller beslutning om overføring til konfliktrådet fastsettes tap av retten til å føre førerkortpliktig motorvogn for en bestemt tid eller for alltid, dersom hensynet til trafikksikkerheten eller allmenne hensyn ellers krever det.
Tapet av førerett fastsettes for minst 1 år dersom rettighetshaveren blir ilagt straff for overtredelse av § 22, jf. § 31. Dette gjelder ikke for overtredelser som nevnt i § 31 annet ledd bokstav a. Ilegges straff som nevnt i § 31 annet ledd bokstav a for kjøring i prøveperiode, fastsettes likevel tap av førerett med inntil ett år.
Dersom rettighetshaveren tidligere er ilagt straff for overtredelse av § 22, jf. § 31, og han blir ilagt straff for ny overtredelse av § 22, jf. § 31 som er begått senest 5 år etter at reaksjonen ble fastsatt for den tidligere overtredelsen, skal retten til å føre førerkortpliktig motorvogn fratas for alltid. Dette gjelder likevel ikke for overtredelser som nevnt i § 31 annet ledd bokstav a.
Retten til å føre førerkortpliktig motorvogn skal fratas for alltid dersom rettighetshaveren ved bruk av motorvogn har voldt eller medvirket til trafikkuhell og blir ilagt straff for å ha unnlatt å yte hjelp til noen som kom til skade ved uhellet, jf. § 12.
Kongen gir forskrift med nærmere regler om fastsetting av hvor lenge tap av førerett skal vare og om når det skal kreves ny førerprøve.
Tapet av førerett kan settes kortere enn minstetiden i eller i medhold av bestemmelsen her, dersom det ellers vil virke urimelig hardt og det foreligger særdeles formildende omstendigheter ved forholdet som ligger til grunn for tapet av førerett. Det samme gjelder når andre helt spesielle grunner taler for å gå under minstetiden.

2. Kongen kan gi forskrift om at retten til å føre førerkortpliktig motorvogn skal gå tapt for en bestemt tid av hensyn til trafikksikkerheten eller allmenne hensyn, dersom rettighetshaveren har fått nærmere angitte straffbare handlinger registrert et bestemt antall ganger i løpet av en fastsatt tidsperiode. Det kan fastsettes ulik registrering av ulike straffbare handlinger, og avhengig av om vedkommende har førerett med eller uten prøveperiode. Det kan settes vilkår for å få føreretten tilbake.

3. Finner politiet at fører eller eier av motorvogn eller den som på eierens vegne har rådigheten over motorvognen med skjellig grunn er mistenkt for et straffbart forhold som kan medføre tap av retten til å føre førerkortpliktig motorvogn, kan en polititjenesteperson midlertidig tilbakekalle føreretten og ta førerkortet fra vedkommende. Spørsmålet om å opprettholde midlertidig tilbakekall av føreretten og beslaget skal snarest mulig forelegges for en tjenestemann som hører til påtalemyndigheten. Beslutningen skal være skriftlig. Dersom den mistenkte ikke samtykker i det midlertidige tilbakekallet av føreretten og beslaget, må spørsmålet innen 3 uker oversendes tingretten til avgjørelse.

4. Politimesteren eller den han gir myndighet kan treffe vedtak om å frata noen retten til å føre førerkortpliktig motorvogn, dersom rettighetshaveren i løpet av de siste 6 måneder er ilagt straff i utlandet for en overtredelse som ville ha ført til tap av retten til å føre motorvogn for en viss minstetid eller for alltid etter regler i eller i medhold av § 33.

5. Når tap av førerett er rettskraftig avgjort, eller det er truffet vedtak om midlertidig tilbakekall av retten til å føre motorvogn og midlertidig beslag av førerkort, plikter rettighetshaveren straks å levere førerkortet til politiet. Når tap av førerett er fastsatt i beslutning om overføring til konfliktrådet, plikter rettighetshaveren å levere førerkortet til politiet straks saken er overført til konfliktrådet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83324, 'lov/1965-06-18-4', 51, 5, 'kapittel-5-paragraf-6', '§ 34', 'Tilbakekall av retten til å føre motorvogn mv. på grunn av særlige forhold', 'Dersom politiet har skjellig grunn til å tro at innehaver av retten til å føre førerkortpliktig motorvogn ikke lenger fyller de krav som er fastsatt til syn, helse og førlighet for slik førerett, herunder at innehaveren ikke må misbruke alkohol eller annet berusende eller bedøvende middel, eller at innehaveren ikke har de kunnskaper eller den kjøreferdighet som hensynet til trafikksikkerheten krever, kan politimesteren eller den han gir myndighet pålegge innehaveren – dersom denne fortsatt ønsker å nytte sin førerett – innen en fastsatt frist å underkaste seg slik legeundersøkelse som finnes påkrevd og framstille seg til helt eller delvis ny førerprøve. Finner politiet det nødvendig, kan det pålegge ham å levere førerkortet til politiet inntil videre.

Unnlater innehaveren å etterkomme pålegg etter første ledd, eller legeundersøkelsen ikke er tilfredsstillende, eller består han ikke førerprøven, kan politimesteren eller den han gir myndighet tilbakekalle føreretten. § 33 nr. 5 får tilsvarende anvendelse.

Er resultatet av legeundersøkelsen ikke til hinder for det, eller består han førerprøven, kan vedkommende myndighet utferdige nytt førerkort til ham, eventuelt med begrenset gyldighetstid eller på særlige vilkår.

Politimesteren eller den han gir myndighet kan tilbakekalle føreretten når innehaveren ikke har fremlagt nødvendig legeattest innen fastsatt frist, jf. § 24 femte og sjette ledd.

Dersom innehaveren av føreretten ikke er edruelig eller hans vandel for øvrig er slik at han ikke anses skikket til å føre motorvogn, kan politimesteren eller den han gir myndighet, tilbakekalle retten til å føre førerkortpliktig motorvogn for en bestemt tid eller inntil videre, hvis hensynet til trafikksikkerheten eller allmenne hensyn ellers krever det.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83325, 'lov/1965-06-18-4', 52, 5, 'kapittel-5-paragraf-7', '§ 35', 'Forbud mot å kjøre førerkortfri motorvogn.', 'Den som blir ilagt straff, kan i samme dom, forelegg eller beslutning om overføring til konfliktrådet for en bestemt tid eller for alltid forbys å føre motorvogn som det ikke kreves førerkort for, dersom hensynet til trafikksikkerheten eller allmenne hensyn ellers krever det.

Politimesteren eller den han gir myndighet kan forby en person for nærmere fastsatt tid å kjøre motorvogn som det ikke kreves førerkort for, dersom personen er blitt fratatt retten til å føre motorvogn i medhold av § 34, eller mangler de egenskaper som er nødvendige for å kjøre slik motorvogn eller av andre grunner anses uskikket til å kjøre slik motorvogn, og hensynet til trafikksikkerheten eller allmenne hensyn ellers krever det.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83326, 'lov/1965-06-18-4', 53, 5, 'kapittel-5-paragraf-8', '§ 36', 'Forbud mot bruk av kjøretøy, inndragning av kjennemerke og vognkort og pålegg om hvile', '1. Politiet eller Statens vegvesen kan forby bruken av en motorvogn og tilhenger til motorvogn for så lang tid som nødvendig, dersom
a. kjøretøyet ikke blir omregistrert når det er bestemt i medhold av § 15,
b. kjøretøyet ikke blir framstilt til kontroll etter § 19 eller pålegg om utbedring av mangel ikke er etterkommet innen fastsatt tid,
c. kjøretøyet ikke er i forsvarlig stand eller kjøretøyets last ikke er forsvarlig sikret,
d. kjøretøyets hjul ikke er sikret tilstrekkelig veggrep ved bruk av pigger, kjettinger eller lignende, når føreforholdet gjør det nødvendig,
e. pålegg gitt i medhold av § 36 a fjerde ledd ikke er etterkommet,
f. regler gitt i medhold av § 7 tredje ledd blir vesentlig overtrådt eller pålegg gitt i medhold av disse ikke blir etterkommet,
g. kjøretøyet er endret i strid med § 13 femte ledd,
h. fartsskriver ikke er installert, eller der fartsskriveren er manipulert eller på annen måte endret slik at informasjonen fra fartsskriveren ikke samsvarer med faktisk kjøring eller annen regulert bruk.

2. Når hensynet til trafikksikkerheten krever det, kan politimesteren eller den han gir myndighet forby bruken av motorvogn og tilhenger til motorvogn for bestemt tid inntil 1 år, dersom eieren eller noen som stadig bruker kjøretøyet med hans samtykke,
a. har kjørt kjøretøy som er endret i strid med § 13 femte ledd, eller
b. har brukt kjøretøy med vesentlig overlast, eller med farlig gods i strid med bestemmelser gitt i eller i medhold av denne lov, eller med uforsvarlig plassert last, eller på veg der kjøretøyet ikke må kjøre etter gitte bestemmelser om aksel- og boggilast, lengde, bredde, høyde m.m, eller
c. har brukt kjøretøyet til kjøring ellers i strid med bestemmelser i eller i medhold av denne lov, og han tidligere er ilagt straff eller domfelt for overtredelser av slik bestemmelse eller for overtredelse av straffeloven kapittel 25 under bruk av motorvogn eller tilhenger til motorvogn, eller
d. har kjørt med kjøretøyet på uforsvarlig måte.

3. Når bruken av en motorvogn, eller tilhenger til motorvogn, blir forbudt etter nr. 1, 2 eller 5, kan politiet, Statens vegvesen og Tolletaten inndra kjennemerker og vognkort dersom kjøretøyet er registrert. Det samme gjelder i tilfelle som er nevnt i skattebetalingsloven § 14-11 første ledd, og dersom trafikktrygd ikke blir holdt i kraft, jf. bilansvarslova § 19. Bruksforbud som nevnt i første punktum kan om nødvendig sikres ved bruk av mekanisk eller elektronisk innretning. Kjøretøyet kan ved bruk av slik innretning holdes tilbake inntil omkostninger knyttet til bruken av innretningen er betalt.

4. Når hensynet til trafikksikkerheten krever det, kan politimesteren eller den han gir myndighet, forby bruken av annet kjøretøy enn motorvogn og tilhenger til motorvogn for bestemt tid inntil 6 måneder, dersom kjøretøyet ikke er i forsvarlig stand, eller dersom eieren eller noen som stadig bruker det med hans samtykke, har brukt det til uforsvarlig kjøring i strid med bestemmelser i eller i medhold av denne lov.

5. Dersom kjøretøyet blir overdratt til andre etter at betingelsene for å forby bruken av det etter nr. 2 og nr. 4 forelå, kan forbud mot bruk også nedlegges mot eller opprettholdes overfor den som får kjøretøyet overdratt til seg.
Finner politiet grunn til å anta at bruken av kjøretøyet vil bli forbudt i medhold av nr. 2 eller nr. 4, kan politiet midlertidig forby bruken av kjøretøyet inntil vedtak kan fattes etter nr. 2 eller nr. 4.

6. I tilfelle som nevnt i nr. 3 og 4 kan politiet ta kjøretøyet i forvaring når det finner det nødvendig. Blir det ikke hentet innen tre måneder etter utløpet av forbudstiden, kan det selges etter reglene i § 37 femte til åttende ledd.

7. Departementet kan bestemme at det skal betales gebyr for å få tilbake kjennemerker og vognkort i de tilfellene disse er inndratt.

8. Departementet kan bestemme at kjøretøy som bevis på at det ikke foreligger avskiltingsgrunnlag som nevnt i nr. 3, kan tildeles egen bekreftelse på dette, og gir nærmere bestemmelser om utstedelse og om plassering på kjøretøyet. Det kan også bestemmes at kjøretøy uten slik bekreftelse kan avskiltes der det påtreffes og at kjøring uten slik bekreftelse er forbudt.

9. Departementet kan i forskrift gi politiet og Statens vegvesen myndighet til å gi pålegg om å gjennomføre nødvendig hvile når bestemmelser gitt i medhold av § 21 annet ledd er overtrådt. Pålegg om hvile kan om nødvendig sikres ved bruk av mekanisk eller elektronisk innretning. Kjøretøyet kan ved bruk av slik innretning holdes tilbake inntil omkostninger knyttet til bruken av innretningen er betalt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83327, 'lov/1965-06-18-4', 54, 5, 'kapittel-5-paragraf-9', '§ 36 a', 'Gebyr for overtredelse av bestemmelser om tillatte vekter og dimensjoner', 'Eier av kjøretøy, transportør eller avsender som vesentlig overtrer eller medvirker til å vesentlig overtre bestemmelser om tillatte vekter og dimensjoner, kan ilegges gebyr.

Ved overtredelse som medfører gebyrplikt etter første ledd, kan politiet eller Statens vegvesen ta kjøretøyet i forvaring for den ansvarliges regning og risiko eller forby bruken av det inntil gebyret og eventuelle omkostninger knyttet til tilbakeholdet er betalt eller det er stilt slik sikkerhet for kravet som nevnt i tvangsfullbyrdelsesloven § 3-4. Forvaring og bruksforbud kan om nødvendig sikres ved bruk av mekanisk eller elektronisk innretning. Ilagt gebyr kan påklages til tingretten etter reglene i § 31 a fjerde ledd.

Gebyret er tvangsgrunnlag for utlegg også hos motorvogneieren, jfr. § 38, annet ledd. Bestemmelsene i annet ledd første punktum kan også gjøres gjeldende for motorvognen, og den hefter til sikkerhet etter bestemmelsene i § 38, første ledd.

Departementet kan gi forskrift om:
a. Veiing, måling og relevant dokumentasjon fra avsender og kontrollmyndighetenes tilgang til slik dokumentasjon,
b. plikt til å kjøre til anvist kontrollsted,
c. gebyrsatser, herunder høyere satser ved gjentakelse,
d. ileggelse, betalingsfrist og inndriving av gebyr,
e. klagebehandling og klagefrist,
f. adgang til ettergivelse av gebyr i særlige tilfeller og
g. inndragning av kjennemerker og dokumenter i tilfelle som nevnt i annet ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83328, 'lov/1965-06-18-4', 55, 5, 'kapittel-5-paragraf-10', '§ 36 b', 'Tilbakeholdsrett i motorvogn og kjøretøy som trekkes av motorvogn', 'Politiet, Statens vegvesen og Tolletaten kan holde tilbake motorvogn og kjøretøy som trekkes av motorvogn, dersom eieren er ilagt eller antas å ville bli ilagt bot eller overtredelsesgebyr for overtredelse av bestemmelser gitt i eller i medhold av loven her. Likestilt med eier er den som har disposisjonsrett over motorvognen eller kjøretøyet som trekkes av motorvognen.

Tilbakehold kan bare besluttes når det er nødvendig for å sikre betaling av bot, overtredelsesgebyr og eventuelle omkostninger knyttet til gjennomføringen av tilbakeholdet og når slikt tilbakehold er forholdsmessig. Ved vurderingen skal det tas hensyn til botens eller overtredelsesgebyrets størrelse og forholdene for øvrig. Tilbakeholdet skal opphøre når betalingen er gjennomført eller det er stilt slik sikkerhet for kravet som nevnt i tvangsfullbyrdelsesloven § 3-4.

Der tilbakeholdet skal sikre betaling av en bot, kan kjøretøyet holdes tilbake frem til påtalemyndigheten har besluttet om det skal ilegges bot. Påtalemyndigheten avgjør da om tilbakeholdet skal fortsette.

Tilbakeholdet kan om nødvendig sikres ved bruk av mekanisk eller elektronisk innretning.

Tilbakeholdte kjøretøy kan selges etter reglene i § 37 femte til åttende ledd dersom beløpet ikke er betalt innen tre måneder etter rettskraftig avgjørelse eller endelig fastsatt overtredelsesgebyr. Bestemmelsene i § 38 får tilsvarende anvendelse på omkostningene knyttet til tilbakeholdet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83329, 'lov/1965-06-18-4', 56, 5, 'kapittel-5-paragraf-11', '§ 37', 'Fjerning og forvaring av kjøretøy m.m.', 'Politiet kan kreve fjernet, eller om nødvendig fjerne eller ta i forvaring kjøretøy
a. som er plassert i strid med bestemmelse i eller i medhold av denne lov, eller
b. som er plassert slik at det ellers er til hinder for trafikken eller for snøbrøyting eller annet arbeid på veg, eller
c. som er plassert på privat eller offentlig eiendom til skade eller ulempe for eier eller bruker eller mot dennes forbud.

Står kjøretøyet på et område som ikke er åpent for alminnelig trafikk, gjelder dette bare dersom eier eller bruker av grunnen krever at kjøretøyet blir fjernet.

Myndighet etter første ledd bokstav b kan også utøves av Statens vegvesen.

Kongen kan, etter at uttalelse er innhentet fra vedkommende politimester, gi forskrift om at myndighet etter første ledd også skal kunne utøves av kommunen.

Kjøretøy som er tatt i forvaring etter denne paragraf kan selges dersom det ikke er hentet innen 3 måneder etter at eieren i rekommandert brev er varslet om forvaringen og om at kjøretøyet vil bli solgt dersom det ikke blir hentet. Dersom eieren eller adressen hans ikke er kjent, kan varselet kunngjøres i pressen eller på annen måte. Finner politiet eller Statens vegvesen at kjøretøyet må anses som vrak, kan det avhende kjøretøyet på hensiktsmessig måte uten hensyn til fristen foran og om nødvendig uten varsel til eieren.

Reglene i lov 29. mai 1953 om rett for handverkarar o.a. til å selja ting som ikkje vert henta, gjelder tilsvarende for salg etter fjerde ledd og for betaling av salgssummen.

Kjøretøy som er tatt i forvaring, står for eierens regning og risiko. Forvaring kan om nødvendig sikres ved hjelp av mekanisk eller elektronisk innretning. Kjøretøyet kan ved bruk av slik innretning holdes tilbake inntil omkostninger knyttet til bruken av innretningen er betalt.

Krever eieren tilbake et kjøretøy som politiet eller Statens vegvesen er i ferd med å fjerne eller har tatt i forvaring, må han først betale de utgifter som politiet eller Statens vegvesen har hatt i samband med fjerningen og forvaringen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83330, 'lov/1965-06-18-4', 57, 5, 'kapittel-5-paragraf-12', '§ 38', 'Panterett og inndriving m.m.', 'Forfalt gebyr etter § 31, jfr. § 31 a, og § 36 a er sikret ved panterett i vedkommende kjøretøy. Det samme gjelder idømte eller ilagte bøter etter vegtrafikklovgivningen, der fører og eier er samme person. Denne panteretten går foran alle andre rettigheter i kjøretøyet, men opphører dersom kjøretøyet overdras til ny eier og denne ikke kjente eller burde kjent panteretten. Panteretten står likevel tilbake for krav på skatter og avgifter til stat og kommune som er sikret ved pant i kjøretøyet, når utleggsforretningen er tinglyst før gebyr eller bøter påløp.

Gebyr etter § 31 er tvangsgrunnlag for utlegg hos den skyldige og hos den som på tiden for overtredelsen var registrert som eier av kjøretøyet, med mindre dette da var fravendt denne ved et lovbrudd. Gebyr etter § 36 a er tvangsgrunnlag for utlegg hos den som på tiden for overlasting var eier eller registrert som eier av kjøretøyet. Krav som nevnt i paragrafen her som tilfaller staten, innkreves av Innkrevingsmyndigheten med mindre departementet bestemmer annet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83331, 'lov/1965-06-18-4', 58, 6, 'kapittel-6-paragraf-1', '§ 39', 'Klage og omgjøring av politiets vedtak om tilbakekall av retten til å føre førerkortpliktig motorvogn mv., bruksnekting m.m.', 'For klage over politiets vedtak om tilbakekall av retten til å føre førerkortpliktig motorvogn mv. etter § 34 og forbud mot å kjøre førerkortfri motorvogn etter § 35 annet ledd gjelder ingen frist.

Uten hensyn til om det er klaget, kan departementet forlenge tilbakekallstiden som er fastsatt av politiet, dersom melding om omgjøring blir sendt vedkommende innen 3 måneder etter at politiets vedtak ble gyldig truffet. Dersom det foreligger et vesentlig misforhold mellom den fastsatte tilbakekallstiden og det forhold som ligger til grunn for tilbakekallet av føreretten, er det likevel tilstrekkelig at melding om forlengelsen blir sendt vedkommende innen 2/3 av den fastsatte tilbakekallstiden er ute. Vedtak om bruksnekting etter § 36 nr. 1 og § 36 nr. 2 bokstav a og b kan påklages til Vegdirektoratet. Politiets bruksnekting etter § 36 nr. 2 bokstav c og d, § 36 nr. 4 og § 36 nr. 5 kan påklages til departementet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83332, 'lov/1965-06-18-4', 59, 6, 'kapittel-6-paragraf-2', '§ 40', 'Forkorting på grunn av etterfølgende forhold.', 'Dersom særlige grunner taler for det, kan politimesteren eller den han gir myndighet forkorte den perioden for tap av retten til å føre førerkortpliktig motorvogn mv. som er fastsatt ved dom, forelegg eller beslutning om overføring til konfliktrådet, jf. § 33 nr. 1 og 2, jf. nr. 6. Dersom meget tungtveiende grunner taler for det, kan perioden forkortes selv om minstetiden etter lov eller forskrift ikke er utløpt.

Bestemmelsen gjelder tilsvarende for sperrefrist etter § 24 a annet ledd og kjøreforbud etter § 35 første ledd.', '2024-09-01', 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83333, 'lov/1965-06-18-4', 60, 6, 'kapittel-6-paragraf-3', '§ 40 a', 'Ansvar for trafikksikkerhetsarbeid.', 'Fylkeskommunen har et ansvar for å tilrå og samordne tiltak for å fremme trafikksikkerheten i fylket.

Departementet kan gi forskrifter med nærmere bestemmelser om at fylkeskommunen, i Oslo Oslo kommune, pålegges å utarbeide og gjennomføre ulike tiltak knyttet til trafikksikkerhet, herunder tiltak på vegnettet og tiltak i tilknytning til skoleskyss.

Departementet kan i forskrift gi regler om at kommunen pålegges å utarbeide og gjennomføre ulike trafikksikkerhetstiltak i tilknytning til skoleskyss.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83334, 'lov/1965-06-18-4', 61, 6, 'kapittel-6-paragraf-4', '§ 40 b', 'Utgifter til ledsaging av spesialtransporter.', 'Transportutøver som er ansvarlig for utførelsen av transport som på grunn av lengde, bredde, høyde eller vekt krever særlig medvirkning fra offentlig myndighet, kan pålegges å dekke de utgifter vedkommende myndighet har hatt til slik medvirkning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83335, 'lov/1965-06-18-4', 62, 6, 'kapittel-6-paragraf-5', '§ 41', 'Kjøretøy kjøpt på avbetaling.', 'For kjøretøy som er solgt med forbehold om eiendomsrett for selgeren, regnes kjøperen som eier med hensyn til bestemmelsene i denne lov.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83336, 'lov/1965-06-18-4', 63, 6, 'kapittel-6-paragraf-6', '§ 42', 'Forsvarets og Sivilforsvarets kjøretøyer.', 'Kongen kan gjøre unntak fra bestemmelser i eller gitt med hjemmel i denne lov for Forsvarets og Sivilforsvarets kjøretøyer og bruken av disse kjøretøyer.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83337, 'lov/1965-06-18-4', 64, 6, 'kapittel-6-paragraf-7', '§ 43', 'Gjennomføring av loven.', 'Kongen kan gi overgangsregler og forskrifter ellers til gjennomføring og utfylling av bestemmelsene i denne lov.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83338, 'lov/1965-06-18-4', 65, 6, 'kapittel-6-paragraf-8', '§ 43a', 'Forholdet til tjenesteloven', 'Når det gjelder regler om godkjenninger, kompetansebevis m.m. som i medhold av vegtrafikkloven kreves for å utføre visse typer virksomhet, kan departementet gi forskrifter om saksbehandlingsregler til utfylling av reglene i tjenesteloven, herunder om saksbehandlingsfrist og rettsvirkninger av fristoverskridelse. Unntak fra tjenesteloven § 11 annet ledd kan bare gjøres når det er begrunnet ut fra tvingende allmenne hensyn, herunder hensynet til privatpersoners beskyttelsesverdige interesser. Saksbehandlingsreglene kan fravike reglene i forvaltningsloven.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83339, 'lov/1965-06-18-4', 66, 6, 'kapittel-6-paragraf-9', '§ 43b', 'Behandling av personopplysninger', 'Offentlige myndigheter kan behandle personopplysninger, herunder personopplysninger som nevnt i personvernforordningen artikkel 9 og 10, når det er nødvendig for å utføre oppgaver etter denne loven med forskrifter. Det kan også behandles personopplysninger som nevnt i forbindelse med trafikksikkerhets- og ulykkesanalysearbeid.

Personopplysninger, herunder personopplysninger som nevnt i personvernforordningen artikkel 9 og 10, kan uten hinder av taushetsplikt utleveres fra Statens vegvesens motorvognregister og førerkortregister til politiet når det er nødvendig for politimessige formål eller kvalitetskontroll av opplysninger i politiets registre. Personopplysninger, herunder personopplysninger som nevnt i personvernforordningen artikkel 9, kan uten hinder av taushetsplikt utleveres fra bilde- og signaturregisteret til politiet når det er nødvendig for
a. å finne en savnet person
b. å identifisere en død person eller en person som det hører under politiets oppgaver å hjelpe
c. å identifisere en person som kan innbringes eller skal pågripes eller anbringes i politiarrest
d. å avklare identiteten til en person som etter utlendingsloven har plikt til å gi opplysninger om egen identitet
e. forebygging eller etterforskning av en handling som etter loven kan medføre høyere straff enn fengsel i seks måneder
f. kvalitetskontroll av opplysninger i politiets registre.
Utlevering av personopplysninger etter dette ledd kan skje ved direkte søk.

Personopplysninger i førerkort- og motorvognregisteret kan utleveres til, eller på annen måte gjøres tilgjengelig for, utenlandske myndigheter når dette er nødvendig for å oppfylle Norges internasjonale forpliktelser.

Departementet kan gi forskrift med utfyllende bestemmelser om behandling av personopplysninger, for eksempel om formål med behandlingen, hvilke opplysninger som kan behandles, vilkår for eventuell utlevering, bruk av automatiserte avgjørelser, sletterutiner, sammenstilling og viderebehandling av opplysninger.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83340, 'lov/1965-06-18-4', 67, 6, 'kapittel-6-paragraf-10', '§ 43c', 'Forholdet til folkeregisterloven', 'Statens vegvesen kan uten hinder av taushetsplikt innhente opplysninger fra folkeregistermyndigheten som er nødvendige for å utføre oppgaver etter denne loven eller andre oppgaver som er fastsatt i eller i medhold av lov.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83341, 'lov/1965-06-18-4', 68, 7, 'kapittel-7-paragraf-1', '§ 44', 'Undersøkelsesmyndigheten', 'Undersøkelse av visse kategorier trafikkulykker og trafikkuhell skal skje ved den myndighet departementet bestemmer.

Undersøkelsesmyndigheten skal klarlegge hendelsesforløp og årsaksfaktorer med formål å forbedre trafikksikkerheten.

Undersøkelsesmyndigheten skal ikke ta stilling til sivilrettslig eller strafferettslig skyld og ansvar. Undersøkelsen skal foregå uavhengig av annen etterforskning eller undersøkelse.

Departementet kan gi utfyllende forskrift om undersøkelsesmyndighetens arbeid.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83342, 'lov/1965-06-18-4', 69, 7, 'kapittel-7-paragraf-2', '§ 45', 'Varsling av trafikkulykker mv.', 'Politiet og Statens vegvesen skal varsle undersøkelsesmyndigheten om nærmere angitte trafikkulykker og trafikkuhell i henhold til forskrift fastsatt av departementet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83343, 'lov/1965-06-18-4', 70, 7, 'kapittel-7-paragraf-3', '§ 46', 'Sikring av bevis mv.', 'Undersøkelsesmyndigheten har rett til å benytte privat grunn og kan kreve å få undersøke og ta i besittelse kjøretøy og vrakrester. Den skal videre gis tilgang til dokumenter, resultater fra andre undersøkelser i forbindelse med trafikkulykken eller trafikkuhellet, herunder av personer som var involvert, og obduksjon av dødsofre, samt øvrige ting i den utstrekning det er nødvendig for å kunne utføre sin oppgave. Undersøkelsesmyndigheten kan kreve gjennomført utåndingsprøve, blodprøve og klinisk legeundersøkelse etter § 22a. Om nødvendig kan undersøkelsesmyndigheten kreve bistand fra politiet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83344, 'lov/1965-06-18-4', 71, 7, 'kapittel-7-paragraf-4', '§ 47', 'Forklaringsplikt til undersøkelsesmyndigheten mv.', 'Enhver plikter på forlangende og uten hensyn til taushetsplikt å gi undersøkelsesmyndigheten de opplysninger han eller hun har om forhold som kan være av betydning for undersøkelsen.

Undersøkelsesmyndigheten kan kreve bevissikring utenfor rettssak etter reglene i tvisteloven § 28-3 tredje ledd og § 28-4. Krav om bevissikring fremmes for den tingrett hvor de som skal avhøres, bor eller oppholder seg eller realbevis skal undersøkes.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83345, 'lov/1965-06-18-4', 72, 7, 'kapittel-7-paragraf-5', '§ 48', 'Taushetsplikt', 'Enhver som utfører tjeneste eller arbeid for undersøkelsesmyndigheten, har taushetsplikt etter forvaltningsloven om det som de får kjennskap til under utførelsen av sitt arbeid. Forvaltningsloven § 13b første ledd nr. 6 gjelder likevel ikke.

Når personer som nevnt i første ledd mottar opplysninger som er undergitt strengere taushetsplikt enn det som følger av forvaltningsloven, skal tilsvarende strenge taushetsplikt gjelde, med mindre tungtveiende offentlige hensyn tilsier at opplysningene bør kunne gis videre eller opplysningene er nødvendige for å forklare årsaken til trafikkulykken eller trafikkuhellet.

Personer som nevnt i første ledd har i tillegg taushetsplikt om alle opplysninger som er fremkommet under forklaring for undersøkelsesmyndigheten etter § 47, med mindre tungtveiende offentlige hensyn tilsier at opplysningene bør kunne gis videre eller opplysningene er nødvendige for å forklare årsaken til trafikkulykken eller trafikkuhellet.

Taushetsplikt som nevnt i annet og tredje ledd er ikke til hinder for at opplysningene bringes videre i den grad den som har krav på taushet samtykker, dersom opplysningene har statistisk form, eller dersom de er alminnelig tilgjengelig andre steder.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83346, 'lov/1965-06-18-4', 73, 7, 'kapittel-7-paragraf-6', '§ 49', 'Forbud mot bruk som bevis i straffesak', 'Opplysninger undersøkelsesmyndigheten mottar i medhold av § 47 kan ikke brukes som bevis i en senere straffesak mot den som har gitt opplysningene.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83347, 'lov/1965-06-18-4', 74, 7, 'kapittel-7-paragraf-7', '§ 50', 'Forbud mot sanksjoner fra arbeidsgiver', 'En arbeidstaker som avgir forklaring etter § 47, skal ikke som følge av dette utsettes for noen form for sanksjoner fra arbeidsgiverens side. Første punktum gjelder ikke tiltak som arbeidsgiveren iverksetter med hovedformål å forbedre arbeidstakerens kvalifikasjoner.

Første ledd gjelder ikke dersom de mottatte opplysningene viser at arbeidstakeren ikke oppfyller helsemessige krav til å inneha sin stilling, eller at arbeidstakeren selv har opptrådt grovt uaktsomt i forbindelse med ulykken eller uhellet. Første ledd gjelder heller ikke omstendigheter knyttet til arbeidstakeren eller dennes handlinger og unnlatelser som er blitt kjent på annen måte enn gjennom arbeidstakerens forklaring etter § 47.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83348, 'lov/1965-06-18-4', 75, 7, 'kapittel-7-paragraf-8', '§ 51', 'Undersøkelsesrapporter mv.', 'Departementet kan gi nærmere forskrift om i hvilke tilfeller undersøkelsesmyndigheten skal utarbeide rapport, hvordan rapportene skal utformes, og om saksbehandlingen mv.

Undersøkelsesmyndighetens utkast til rapport er ikke offentlig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83349, 'lov/1965-06-18-4', 76, 7, 'kapittel-7-paragraf-9', '§ 51 a', 'Statens vegvesens ulykkesanalysearbeid', 'Statens vegvesen skal undersøke vegtrafikkulykker for å klarlegge hendelsesforløp og årsaksfaktorer med formål å forbedre trafikksikkerheten.

For dette formålet skal Statens vegvesens ulykkesanalysegruppe foreta dybdeanalyser av alle dødsulykkene på veg i Norge. Ulykkesanalysegruppen skal ikke ta stilling til sivilrettslig eller strafferettslig skyld og ansvar i forbindelse med vegtrafikkulykken. Ulykkesanalysegruppen skal uten hinder av lovbestemt taushetsplikt få utlevert saksopplysninger fra politiet som er nødvendig for gruppens arbeid og obduksjonsrapport om trafikkdrepte.

Departementet kan gi forskrift om ulykkesanalysegruppens arbeid.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (83350, 'lov/1965-06-18-4', 77, 8, 'kapittel-8-paragraf-1', '§ 52', 'Ikrafttreden m.m.', 'Denne lov trer i kraft fra den dag Kongen bestemmer. Det kan bestemmes at visse deler av loven skal gjelde fra et tidligere tidspunkt enn andre.[1]

Administrative forskrifter, tillatelser, forbud, vilkår, m.m. som er gitt eller fastsatt i medhold av de lover som er nevnt under nr. 1, 2 eller 5 nedenfor, gjelder fortsatt inntil de blir endret eller opphevd med hjemmel i denne lov.

Fra denne lovs ikrafttreden oppheves eller endres følgende lover og bestemmelser: – – –

Reglene i § 33 og § 34 om førerett, førerkort og førerkortpliktig motorvogn skal gjelde tilsvarende for mopedførerbevis og tilhørende førerett.

Vedtak om delegering av myndighet som er fattet før ikraftsetting av lov om endringer i sektorlovgivningen for å sikre at oppgaver til kommuner og fylkeskommuner tildeles i lover og forskrifter, skal fortsatt gjelde.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92249, 'lov/1999-03-26-17', 1, 1, 'kapittel-1-paragraf-1', '§ 1-1', 'Lovens virkeområde m.v.', 'Loven gjelder avtaler om bruksrett til husrom mot vederlag.

Loven gjelder selv om bruksrett til bolig har grunnlag i en arbeidsavtale. For øvrig gjelder loven ikke hvor annet enn bruksrett til husrom er det vesentlige i avtaleforholdet.

Loven gjelder selv om vederlaget helt eller delvis er fastsatt til annet enn penger.

Loven gjelder ikke avtaler mellom hoteller, pensjonater og liknende overnattingssteder og deres gjester. Loven gjelder heller ikke avtaler om leie av husrom til ferie- og fritidsbruk.

Med bolig menes i denne loven husrom som fullt ut eller for en ikke helt ubetydelig del skal brukes til beboelse. Med lokale menes i denne loven annet husrom enn bolig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92250, 'lov/1999-03-26-17', 2, 1, 'kapittel-1-paragraf-2', '§ 1-2', 'Ufravikelighet', 'Det kan ikke avtales eller gjøres gjeldende vilkår som er mindre gunstige for leieren enn det som følger av bestemmelsene i loven her.

Ved leie av lokale kan loven fravikes i avtale, med unntak av §§ 1-1 til 1-4, 4-1, 4-4, 4-6, 9-7, 9-8, 9-10, 12-3 og 12-4 og kapittel 13.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92251, 'lov/1999-03-26-17', 3, 1, 'kapittel-1-paragraf-3', '§ 1-3', 'Standardvilkår', 'Er leieavtalen inngått på grunnlag av eller med henvisning til standardvilkår som er utarbeidet etter forhandlinger mellom organisasjoner for leierne og utleierne, skal det senest ved inngåelsen av avtalen opplyses skriftlig om eventuelle avvik fra standardvilkårene. Er dette ikke gjort, gjelder standardvilkårene.

Bestemmelsen i første ledd er ikke til hinder for at leier av bolig påberoper seg avtale som stiller leieren gunstigere enn det som følger av standardvilkårene.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92252, 'lov/1999-03-26-17', 4, 1, 'kapittel-1-paragraf-4', '§ 1-4', 'Avtaleform', 'Avtale om leie av husrom kan gjøres skriftlig eller muntlig. Er avtalen muntlig, skal den settes opp skriftlig dersom en av partene krever det.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92253, 'lov/1999-03-26-17', 5, 1, 'kapittel-1-paragraf-5', '§ 1-5', 'Risikoen for sending av meldinger', 'Dersom en part gir melding i samsvar med loven og sender den på en måte som etter forholdene er forsvarlig, og ikke annet framgår, kan avsenderen gjøre gjeldende at meldingen er gitt i tide selv om den blir forsinket eller ikke kommer riktig fram.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92254, 'lov/1999-03-26-17', 6, 1, 'kapittel-1-paragraf-6', '§ 1-6', 'Beregning av frister', 'Ved beregning av frister etter denne loven gjelder reglene i domstolsloven §§ 146, 148 og 149 tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92255, 'lov/1999-03-26-17', 7, 1, 'kapittel-1-paragraf-7', '§ 1-7', 'Erstatningsansvar for skade på person m.v.', 'Tap som følge av skade på person faller utenfor bestemmelsene om erstatningsansvar i loven her. For slikt tap og for tap som ikke er følge av mislighold, gjelder de alminnelige erstatningsregler.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92256, 'lov/1999-03-26-17', 8, 1, 'kapittel-1-paragraf-8', '§ 1-8', 'Forbud mot diskriminering', 'Ved utleie av husrom kan det ikke tas hensyn til kjønn, graviditet, etnisitet, religion, livssyn, funksjonsnedsettelse, seksuell orientering, kjønnsidentitet, kjønnsuttrykk eller alder. Slike omstendigheter kan ikke regnes som saklig grunn til å nekte opptak i husstand, framleie, personskifte eller tillegges vekt ved opphør av leieforholdet. Ved diskriminering gjelder likestillings- og diskrimineringsloven.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92257, 'lov/1999-03-26-17', 9, 2, 'kapittel-2-paragraf-1', '§ 2-1', 'Tidspunkt for overlevering', 'Utleieren skal stille husrommet med tilbehør til leierens disposisjon til avtalt tid.

Er ikke annet avtalt, regnes overlevering for skjedd når leieren har fått nøkler og ellers uhindret atkomst til husrommet. Leieren kan nekte å overta husrommet dersom det er i vesentlig dårligere stand enn leieren kan kreve etter avtalen og bestemmelsene i dette kapittel, og overlevering skal i så fall ikke regnes for skjedd.

Er overleveringstidspunktet ikke fastsatt i avtalen, kan leieren kreve å overta bruken av husrommet ved tredje månedsskifte etter at avtalen ble bindende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92258, 'lov/1999-03-26-17', 10, 2, 'kapittel-2-paragraf-2', '§ 2-2', 'Generelle krav til tilstand', 'Husrommet skal ved overleveringen være i samsvar med de krav som følger av leieavtalen. Er ikke annet avtalt, skal husrommet med tilbehør ved overleveringen være ryddet, rengjort og i vanlig god stand.

Er ikke annet avtalt, har husrommet dessuten en mangel dersom det ikke
a. passer til de formål tilsvarende husrom vanligvis blir brukt til, eller
b. passer til de særlige formål som leieren etter avtalen skulle bruke husrommet til, med mindre forholdene viser at leieren for så vidt ikke bygde på utleierens sakkunnskap eller vurdering eller ikke hadde rimelig grunn til å gjøre det.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92259, 'lov/1999-03-26-17', 11, 2, 'kapittel-2-paragraf-3', '§ 2-3', 'Uriktige opplysninger om husrommet', 'Det foreligger en mangel dersom husrommet ikke er i samsvar med opplysninger som er gitt av utleieren eller på utleierens vegne. Dette gjelder likevel bare dersom det kan antas at opplysningene har virket inn på avtalen, og de ikke i tide er rettet på en tydelig måte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92260, 'lov/1999-03-26-17', 12, 2, 'kapittel-2-paragraf-4', '§ 2-4', 'Manglende opplysninger om husrommet', 'Det foreligger en mangel dersom leieren ikke har fått opplysning om forhold ved husrommet som utleieren kjente eller måtte kjenne til, og som leieren hadde grunn til å regne med å få. Dette gjelder likevel bare når det kan antas at unnlatelsen har virket inn på avtalen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92261, 'lov/1999-03-26-17', 13, 2, 'kapittel-2-paragraf-5', '§ 2-5', 'Husrom leid «som det er» e.l.', 'Selv om husrommet er leid «som det er» eller med liknende alminnelig forbehold, har det mangel dersom utleieren eller noen utleieren svarer for, har tilsidesatt sine plikter etter §§ 2-3 eller 2-4. Husrommet har også mangel dersom det er i vesentlig dårligere stand enn leieren hadde grunn til å regne med etter leiens størrelse og forholdene ellers.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92262, 'lov/1999-03-26-17', 14, 2, 'kapittel-2-paragraf-6', '§ 2-6', 'Forundersøkelse m.v.', 'Det som leieren kjente eller måtte kjenne til ved avtaleinngåelsen, kan ikke gjøres gjeldende som mangel.

Har leieren før avtaleinngåelsen undersøkt husrommet eller uten rimelig grunn unnlatt å etterkomme utleierens oppfordring om å undersøke det, kan leieren ikke gjøre gjeldende som mangel noe som burde ha vært oppdaget ved undersøkelsen. Dette gjelder likevel ikke dersom utleieren har handlet grovt uaktsomt eller i strid med redelighet og god tro.

Bestemmelsene i første og annet ledd gjør ingen innskrenking i § 2-4 om manglende opplysninger om husrommet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92263, 'lov/1999-03-26-17', 15, 2, 'kapittel-2-paragraf-7', '§ 2-7', 'Tiden for mangelsbedømmelsen', 'Om husrommet har en mangel, skal bedømmes ut fra forholdene på tidspunktet for overleveringen, jf. § 2-1.

Skjer overleveringen senere enn avtalt, og dette beror på forhold på leierens side, skal bedømmelsen skje ut fra forholdene på det tidspunkt leieren kunne ha fått overtatt bruken av husrommet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92264, 'lov/1999-03-26-17', 16, 2, 'kapittel-2-paragraf-8', '§ 2-8', 'Reklamasjon', 'Leieren taper sin rett til å gjøre en mangel gjeldende dersom det ikke er gitt melding til utleieren om at mangelen påberopes, innen rimelig tid etter at leieren burde oppdaget den. Dette gjelder likevel ikke dersom utleieren har opptrådt grovt uaktsomt eller i strid med redelighet og god tro.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92265, 'lov/1999-03-26-17', 17, 2, 'kapittel-2-paragraf-9', '§ 2-9', 'Leierens rett til å fastholde avtalen ved forsinkelse', 'Stilles ikke husrommet til leierens disposisjon til riktig tid, kan leieren fastholde avtalen og kreve oppfyllelse dersom dette kan skje uten å volde utleieren urimelig kostnad eller ulempe. Leieren taper sin rett til å kreve oppfyllelse dersom leieren venter urimelig lenge med å fremme kravet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92266, 'lov/1999-03-26-17', 18, 2, 'kapittel-2-paragraf-10', '§ 2-10', 'Krav på retting av mangel', 'Leieren kan kreve at utleieren for egen regning retter en mangel ved husrommet eller tilbehøret dersom dette kan skje uten en urimelig kostnad eller ulempe for utleieren.

Vil leieren gjøre en mangel gjeldende, har utleieren krav på å få rette mangelen dersom retting kan skje uten vesentlig ulempe for leieren, og leieren heller ikke ellers har særlig grunn til å motsette seg retting.

Retting skal skje innen rimelig tid etter at det er framsatt krav om det.

Oppfyller ikke utleieren sin plikt til å rette mangelen, kan leieren kreve erstattet sine forsvarlige utgifter ved å få mangelen rettet. Medfører rettingen arbeid, kan leieren kreve en rimelig godtgjørelse for det.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92267, 'lov/1999-03-26-17', 19, 2, 'kapittel-2-paragraf-11', '§ 2-11', 'Avslag i leie', 'Stilles ikke husrommet til leierens disposisjon til riktig tid, er ikke leieren forpliktet til å betale leie for den tid forsinkelsen varer. Gjelder forsinkelsen bare en del av husrommet, kan leieren kreve et leieavslag for den tiden forsinkelsen varer som svarer til forholdet mellom leieverdien av husrommet og av den forsinkede delen.

I den tid husrommet lider av en mangel, kan leieren kreve avslag i leien slik at forholdet mellom nedsatt og avtalt leie svarer til forholdet mellom husrommets leieverdi i mangelfull og kontraktsmessig stand. Dette gjelder likevel ikke i tiden etter at leieren har avslått et tilbud om retting som leieren pliktet å motta.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92268, 'lov/1999-03-26-17', 20, 2, 'kapittel-2-paragraf-12', '§ 2-12', 'Heving av leieavtalen', 'Leieren kan heve leieavtalen dersom forsinkelsen eller mangelen medfører vesentlig mislighold.

Er det klart at det vil inntre mislighold som gir leieren hevingsrett, kan leieren heve allerede før tidspunktet for overlevering. Hevingen kan avverges dersom utleieren straks stiller betryggende sikkerhet for at avtalen vil bli oppfylt.

Leieren kan ikke heve leieavtalen på grunn av forsinkelse etter at husrommet er overtatt, eller på grunn av mangler når disse er rettet etter bestemmelsene i § 2-10.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92269, 'lov/1999-03-26-17', 21, 2, 'kapittel-2-paragraf-13', '§ 2-13', 'Erstatning', 'Leieren kan kreve erstatning for tap som følge av forsinkelse eller mangel. Dette gjelder likevel ikke så langt utleieren godtgjør at forsinkelsen eller mangelen skyldes en hindring utenfor utleierens kontroll som utleieren ikke med rimelighet kunne ventes å ha tatt i betraktning på avtaletiden eller å ha unngått eller overvunnet følgene av.

Skyldes forsinkelsen eller mangelen en tredjeperson som utleieren har gitt i oppdrag helt eller delvis å oppfylle leieavtalen, er utleieren fri for ansvar bare om også tredjepersonen ville være fritatt etter regelen i første ledd.

Ansvarsfriheten gjelder så lenge hindringen virker. Faller hindringen bort, kan ansvar gjøres gjeldende dersom utleieren da plikter å oppfylle, men ikke gjør dette.

Reglene i første til tredje ledd omfatter ikke slikt indirekte tap som nevnt i § 2-14 annet ledd.

Leieren kan i alle tilfeller kreve erstatning dersom
a. forsinkelsen, mangelen eller tapet skyldes feil eller forsømmelse på utleierens side, eller
b. husrommet alt på avtaletiden avvek fra det som er tilsikret fra utleieren.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92270, 'lov/1999-03-26-17', 22, 2, 'kapittel-2-paragraf-14', '§ 2-14', 'Erstatningsansvarets omfang', 'Erstatningen skal svare til det økonomiske tap leieren har lidt som følge av forsinkelsen eller mangelen. Dette gjelder likevel bare tap som utleieren med rimelighet kunne ha forutsett som en mulig følge av misligholdet.

Som indirekte tap regnes:
a. tap som følge av minsket eller bortfalt produksjon eller omsetning (driftsavbrudd),
b. tapt fortjeneste som følge av at en kontrakt med tredjemann faller bort for så vidt leieren uten rimelig grunn lar være å leie annet husrom eller treffe andre tiltak for å unngå eller minske tapet, og
c. tap som følge av tingskade.

Reglene i annet ledd gjelder ikke kostnader ved vanlige tiltak som kompenserer at husrommet overtas forsinket eller har mangler, og tiltak som begrenser annet tap enn det som annet ledd omfatter.

Forsømmer leieren å begrense tapet gjennom rimelige tiltak, må leieren bære den tilsvarende del av tapet.

Ansvaret kan settes ned dersom det vil virke urimelig for utleieren ut fra størrelsen på tapet i forhold til det tap som vanligvis oppstår i liknende tilfelle, og ut fra forholdene ellers.

Det kan avtales at det ikke skal betales erstatning for indirekte tap som går inn under annet ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92271, 'lov/1999-03-26-17', 23, 2, 'kapittel-2-paragraf-15', '§ 2-15', 'Rett til å holde leie tilbake', 'Leieren kan holde tilbake så mye av leien at det sikrer de kravene leieren har mot utleieren som følge av mangel eller forsinkelse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92272, 'lov/1999-03-26-17', 24, 2, 'kapittel-2-paragraf-16', '§ 2-16', 'Rettsmangler', 'Bestemmelsene om mangler gjelder tilsvarende dersom tredjemanns rett i husrommet er til hinder for den avtalte bruk.

Leieren kan alltid kreve erstatning for tap som følge av rettsmangel som forelå ved avtaleinngåelsen, og som leieren ikke kjente eller burde ha kjent til.

Gjør tredjemann krav på å ha en rett i husrommet som er til hinder for den avtalte bruk, og dette bestrides, gjelder reglene i første og annet ledd tilsvarende når kravet ikke er klart ugrunnet. Heving kan avverges dersom utleieren straks stiller betryggende sikkerhet for at avtalen vil bli oppfylt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92273, 'lov/1999-03-26-17', 25, 2, 'kapittel-2-paragraf-17', '§ 2-17', 'Offentligrettslige rådighetsinnskrenkinger', 'Bestemmelsene om mangler gjelder tilsvarende dersom den avtalte bruk hindres av bestemmelser i lovgivningen eller offentlig vedtak i medhold av lov.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92274, 'lov/1999-03-26-17', 26, 3, 'kapittel-3-paragraf-1', '§ 3-1', 'Leien', 'Leien skal fastsettes til et bestemt beløp. Det kan likevel avtales at utleierens utgifter ved forbruk av elektrisitet og brensel skal fordeles forholdsmessig mellom brukerne av eiendommen, jf. § 3-4. Det samme gjelder utleierens utgifter til vann og avløp når disse utgiftene skal betales etter målt forbruk.

Er leiens størrelse ikke avtalt, kan utleieren kreve en leie som svarer til det som vanligvis oppnås på avtaletidspunktet ved ny utleie av liknende husrom på liknende avtalevilkår. Blir partene ikke enige om leiens størrelse, kan hver av dem kreve at den blir fastsatt etter bestemmelsene i § 12-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92275, 'lov/1999-03-26-17', 27, 3, 'kapittel-3-paragraf-2', '§ 3-2', 'Forfallstid', 'Er ikke annet avtalt, kan utleieren kreve at leien betales forskuddsvis for hver måned eller annen avtalt betalingstermin. Det kan ikke avtales forskuddsbetaling for lengre tid enn én måned.

Forfaller leien på en lørdag eller søndag, en helligdag, eller den 1. eller 17. mai, utskytes forfallsdagen til den nærmest påfølgende virkedag.

Forfallsdagen utskytes også så lenge betalingen hindres av stans i samferdselen eller betalingsformidlingen eller annet forhold utenfor leierens kontroll og som leieren ikke kan overvinne.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92276, 'lov/1999-03-26-17', 28, 3, 'kapittel-3-paragraf-3', '§ 3-3', 'Oppgjørsmåte', 'Utleieren kan gi anvisning om overføringsmåten av leien dersom dette ikke medfører merutgifter eller vesentlig ulempe for leieren. Leieren har likevel alltid rett til å betale leie gjennom finansinstitusjon som har rett til å tilby slik tjeneste i Norge. Leieren plikter ikke å overføre leie til utlandet.

Betaler leieren gjennom finansinstitusjon, skal betaling i forhold til forfallsreglene anses for skjedd når
a. beløpet er mottatt av finansinstitusjon i Norge, eller
b. et betalingsoppdrag er mottatt av finansinstitusjon i Norge, forutsatt at det er dekning for oppdraget.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92277, 'lov/1999-03-26-17', 29, 3, 'kapittel-3-paragraf-4', '§ 3-4', 'Betaling for elektrisitet og brensel mv.', 'Er det avtalt at leieren skal bidra særskilt til utleierens utgifter ved forbruk av elektrisitet eller brensel i eiendommen, kan leieren kreve at utleieren hvert år legger fram regnskap som viser størrelsen på kostnadene og fordelingen av disse på eiendommens husrom. Det samme gjelder hvis leieren skal bidra særskilt til utleierens utgifter ved forbruk av vann og avløp i eiendommen.

I eiendom med felles anlegg for levering av varme eller varmt vann kan et flertall på to tredjedeler av leierne kreve at det blir installert apparat for måling av den enkeltes forbruk. Det samme flertall av leierne kan kreve at det blir installert apparat for måling av den enkeltes forbruk av vann og avløp. Utleieren kan i så fall over et tidsrom på ett år utlikne omkostningene ved slike installasjoner på samtlige leiere i eiendommen.

I forhold til reglene i tvangsfullbyrdelsesloven kapittel 13 regnes krav som nevnt i første og annet ledd som leie.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92278, 'lov/1999-03-26-17', 30, 3, 'kapittel-3-paragraf-5', '§ 3-5', 'Depositum', 'Det kan avtales at leieren til sikkerhet for skyldig leie, skader på husrommet, utgifter ved fraviking og for andre krav som reiser seg av leieavtalen, skal deponere et beløp oppad begrenset til summen av seks måneders leie. Det kan avtales at depositumet skal endres i takt med endringer i leien.

Det deponerte beløp skal settes på særskilt konto i leierens navn med vanlige rentevilkår i finansinstitusjon som har rett til å tilby slik tjeneste i Norge.

Så lenge leieforholdet varer, kan ingen av partene disponere over beløpet på egen hånd. Leieren kan likevel kreve opptjente renter utbetalt fra finansinstitusjonen.

Etter leieforholdets opphør skal finansinstitusjonen etter krav fra utleieren med frigjørende virkning utbetale skyldig leie fra kontoen dersom:
a. partene skriftlig har avtalt at leien skal godskrives annen konto i den samme finansinstitusjonen,
b. utleieren har dokumentert skyldig leie, og
c. leieren ikke dokumenterer å ha reist søksmål innen fem uker etter at varselet etter femte ledd er sendt.

Krever utleieren utbetaling etter fjerde ledd, skal finansinstitusjonen varsle leieren om kravet og opplyse om at beløpet vil bli utbetalt til utleieren hvis leieren ikke innen fem uker etter at varselet er sendt, dokumenterer å ha reist søksmål. Varselet skal sendes til leierens oppgitte adresse og til en eventuell oppgitt elektronisk postadresse.

Hver av partene kan kreve utbetaling av det deponerte beløpet i samsvar med den annen parts skriftlige samtykke, rettskraftig dom eller annen avgjørelse som har virkning som rettskraftig dom. Krever leieren utbetaling av depositum ut over opptjente renter, skal finansinstitusjonen varsle utleieren skriftlig om kravet og opplyse om at beløpet vil bli utbetalt til leieren hvis utleieren ikke innen fem uker etter at varselet ble sendt, fremmer krav etter bestemmelsene i fjerde ledd eller dokumenterer å ha reist søksmål. Mottar ikke finansinstitusjonen slikt krav eller dokumentasjon innen fristen, og leieren ikke har trukket kravet tilbake, skal finansinstitusjonen med frigjørende virkning utbetale beløpet til leieren.

Utleieren dekker kostnadene med å opprette depositumskonto. Utleieren kan anvise i hvilken finansinstitusjon depositumskontoen skal opprettes så sant dette ikke er til vesentlig ulempe for leieren. Leieren plikter ikke å opprette depositumskonto i utlandet.

Departementet kan i forskrift gjøre unntak fra bestemmelsene i paragrafen her.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92279, 'lov/1999-03-26-17', 31, 3, 'kapittel-3-paragraf-6', '§ 3-6', 'Garanti', 'Det kan avtales at leieren til sikkerhet for krav på skyldig leie, skader på husrommet, utgifter ved fraviking og for andre krav som reiser seg av leieavtalen, skal stille garanti. Garantibeløpet kan sammen med depositum etter § 3-5 ikke overstige summen av seks måneders leie. Det kan ikke avtales med virkning for leierens regressansvar at garantisten skal ha rett til å utbetale garantien uten hensyn til leierens innsigelser mot utleierens krav.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92280, 'lov/1999-03-26-17', 32, 3, 'kapittel-3-paragraf-7', '§ 3-7', 'Forbud mot andre ytelser ved leie av bolig', 'Det kan ikke avtales at leier av bolig skal betale andre eller større pengebeløp enn angitt i §§ 3-1 og 3-4 til 3-6.

Den som har betalt beløp i strid med første ledd, kan alltid kreve beløpet tilbakebetalt eller erstattet av utleieren. Avtalen for øvrig er bindende selv om tilbakebetaling eller erstatning blir krevd.

Kravet etter annet ledd forrentes etter lov av 17. desember 1976 nr. 100 om renter ved forsinket betaling m.m. § 3 fra den dag beløpet ble betalt, med mindre betaleren må anses i vesentlig grad medansvarlig for overtredelsen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92281, 'lov/1999-03-26-17', 33, 3, 'kapittel-3-paragraf-8', '§ 3-8', 'Deponering av omtvistet leie', 'Er partene uenige om hvilken leie som skal betales, kan avtalen ikke sies opp eller heves på grunn av manglende leiebetaling hvis leieren deponerer den omtvistede delen av leien i samsvar med annet ledd. Det samme gjelder hvis leieren vil motregne med krav som reiser seg av leieavtalen, og utleieren ikke godtar motregningen. Leieren skal gi utleieren melding om begrunnelsen for deponeringen og gi utleieren fjorten dagers frist til å medvirke til deponeringen. Fristen regnes fra meldingen er sendt.

Deponering etter første ledd skjer ved at beløpet settes inn på konto i finansinstitusjon som har rett til å tilby slik tjeneste i Norge. Beløpet, herunder renter, skal bare kunne disponeres av leieren og utleieren i fellesskap. Finansinstitusjonen skal likevel kunne utbetale beløpet i samsvar med rettskraftig dom eller annen avgjørelse som har virkning som rettskraftig dom.

Er utleierens manglende medvirkning eneste grunn til at deponering etter annet ledd ikke kan skje, kan avtalen ikke sies opp eller heves på grunn av manglende leiebetaling hvis leieren setter beløpet inn på egen konto atskilt fra leierens øvrige midler. Hvis utleieren på et senere tidspunkt vil medvirke til deponering etter annet ledd, plikter leieren innen rimelig tid å overføre beløpet til konto som nevnt i annet ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92282, 'lov/1999-03-26-17', 34, 4, 'kapittel-4-paragraf-1', '§ 4-1', 'Det alminnelige leieprisvern', 'Det kan ikke avtales en leie som er urimelig i forhold til det som vanligvis oppnås på avtaletidspunktet ved ny utleie av liknende husrom på liknende avtalevilkår.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92283, 'lov/1999-03-26-17', 35, 4, 'kapittel-4-paragraf-2', '§ 4-2', 'Indeksregulering', 'Hver av partene kan kreve leien endret uten oppsigelse av leieforholdet med følgende begrensninger:
a. endringen må ikke tilsvare mer enn endringen i konsumprisindeksen i tiden etter siste leiefastsetting,
b. endringen kan tidligst settes i verk ett år etter at siste leiefastsetting ble satt i verk, og
c. den annen part må gis skriftlig varsel med minst én måneds frist før endringen kan settes i verk.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92284, 'lov/1999-03-26-17', 36, 4, 'kapittel-4-paragraf-3', '§ 4-3', 'Tilpassing til gjengs leie', 'Har leieforholdet vart i minst to år og seks måneder uten annen endring av leien enn den som kan kreves etter § 4-2, kan begge parter uten oppsigelse sette fram krav om at leien blir satt til gjengs leie på iverksettingstidspunktet ved utleie av liknende husrom på liknende avtalevilkår. Ved leiefastsetting etter første punktum skal det gjøres fradrag for den del av leieverdien som skyldes leierens forbedringer og innsats.

Tilpassing av leien etter første ledd kan tidligst settes i verk seks måneder etter at det er framsatt skriftlig krav om det, og tidligst ett år etter at tidligere endring av leien ble satt i verk.

Blir partene ikke enige om hva som er gjengs leie, kan hver av dem kreve at den blir fastsatt etter bestemmelsene i § 12-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92285, 'lov/1999-03-26-17', 37, 4, 'kapittel-4-paragraf-4', '§ 4-4', 'Tilbakebetaling av ulovlig leie', 'Den som har betalt høyere leie enn lovlig, kan kreve tilbakebetalt forskjellen mellom det som er betalt og lovlig vederlag, med mindre betaleren i vesentlig grad må anses medansvarlig for overtredelsen. Avtalen for øvrig er bindende selv om tilbakebetaling blir krevd.

Kravet etter første ledd forrentes etter lov av 17. desember 1976 nr. 100 om renter ved forsinket betaling m.m. § 3 fra den dag beløpet ble betalt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92286, 'lov/1999-03-26-17', 38, 4, 'kapittel-4-paragraf-5', '§ 4-5', 'Unntak fra leieprisvernet', 'Bestemmelsen i § 4-2 gjelder ikke for særskilt betaling av en forholdsmessig andel av utgiftene ved forbruk av elektrisitet, brensel, vann eller avløp i eiendommen, jf. § 3-4. Dette vederlaget kan reguleres slik at utleieren får dekket de nødvendige omkostningene med ytelsene.

Bestemmelsene i §§ 4-2 og 4-3 gjelder ikke for den del av leien som er avtalt i et bestemt forhold til omsetningen i eller resultatet av leierens virksomhet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92287, 'lov/1999-03-26-17', 39, 4, 'kapittel-4-paragraf-6', '§ 4-6', 'Forskrifter', 'Dersom forholdene gjør det nødvendig, kan Kongen for bestemte perioder, bestemte områder eller bestemte leieforhold fastsette leiestopp og maksimalsatser for leie. Kongen kan også gi forskrifter om hva som skal regnes som gjengs leie.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92288, 'lov/1999-03-26-17', 40, 5, 'kapittel-5-paragraf-1', '§ 5-1', 'Leierens bruk m.v.', 'Utleieren plikter i leietiden å stille husrommet til leierens disposisjon i samsvar med avtalen.

Leieren plikter å behandle husrommet med tilbørlig aktsomhet og for øvrig i samsvar med leieavtalen.

Leieren kan ikke bruke husrommet til annet formål enn avtalt. Leier av lokale kan likevel drive annen beslektet virksomhet, forutsatt at dette ikke er til vesentlig ulempe for utleieren eller de øvrige brukerne av eiendommen.

Leier av lokale for butikk eller serveringssted plikter å holde virksomheten åpen og i vanlig daglig drift unntatt når midlertidig stenging er nødvendig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92289, 'lov/1999-03-26-17', 41, 5, 'kapittel-5-paragraf-2', '§ 5-2', 'Ro og orden', 'Er ikke annet avtalt, plikter utleieren i leietiden å opprettholde vanlig ro og orden i eiendommen.

Leieren plikter å følge vanlige ordensregler og rimelige påbud som utleieren har fastsatt til sikring av god husorden. Selv om utleieren har fastsatt forbud mot dyrehold i eiendommen, kan leieren holde dyr dersom gode grunner taler for det, og dyreholdet ikke er til ulempe for utleieren eller de øvrige brukerne av eiendommen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92290, 'lov/1999-03-26-17', 42, 5, 'kapittel-5-paragraf-3', '§ 5-3', 'Vedlikehold', 'Er ikke annet avtalt, plikter utleieren i leietiden å holde utleid husrom og eiendommen for øvrig i den stand som leieren har krav på etter reglene i lovens kapittel 2.

Er ikke annet avtalt, plikter leieren å vedlikeholde dørlåser, kraner, vannklosetter, elektriske kontakter og brytere, varmtvannsbeholdere og inventar og utstyr i husrommet som ikke er en del av den faste eiendommen. Leieren plikter også å foreta nødvendig funksjonskontroll, rengjøring, batteriskift, testing og lignende av røykvarsler og brannslukkingsutstyr. Må gjenstander som tilhører utleieren skiftes ut, påhviler dette utleieren hvis annet ikke er avtalt.

Utbedring av tilfeldig skade regnes ikke som vedlikehold etter annet ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92291, 'lov/1999-03-26-17', 43, 5, 'kapittel-5-paragraf-4', '§ 5-4', 'Forandringer i husrommet og på eiendommen for øvrig', 'Leieren må finne seg i forandringer av husrommet dersom arbeidet kan utføres uten nevneverdig ulempe for leieren, og forandringen ikke reduserer husrommets verdi for leieren. Andre forandringer kan bare utføres med leierens samtykke.

Leieren kan ikke uten utleierens samtykke foreta forandringer i husrommet eller på eiendommen for øvrig.

Leier av bolig kan med utleierens godkjenning gjennomføre tiltak på eiendommen som er nødvendige på grunn av leierens eller husstandsmedlemmers nedsatte funksjonsevne. Leier av lokale kan med utleierens godkjenning sette opp vanlige skilter, markiser o.l. Godkjenning etter første og annet punktum kan ikke nektes uten saklig grunn.

Om leierens plikt til å sette husrommet tilbake i opprinnelig stand gjelder § 10-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92292, 'lov/1999-03-26-17', 44, 5, 'kapittel-5-paragraf-5', '§ 5-5', 'Skade på husrommet', 'Oppdager leieren skade på husrommet som må utbedres uten opphold, plikter leieren straks å sende melding om det til utleieren. Andre skader på husrommet som oppdages, plikter leieren å sende melding om innen rimelig tid.

Leieren plikter å gjøre det som med rimelighet kan kreves for å avverge økonomisk tap for utleieren som følge av skade som nevnt i første ledd første punktum. Er leieren ikke ansvarlig for skaden, kan leieren kreve erstattet sine forsvarlige utgifter ved tiltaket og en rimelig godtgjørelse for utført arbeid.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92293, 'lov/1999-03-26-17', 45, 5, 'kapittel-5-paragraf-6', '§ 5-6', 'Utleierens adgang til husrommet', 'Leieren plikter i nødvendig utstrekning å gi utleieren eller utleierens representant adgang til husrommet for tilsyn.

Leieren plikter å gi utleieren eller andre adgang til husrommet i den utstrekning det trengs for å gjennomføre pliktig vedlikehold, lovlige forandringer eller andre arbeider som må utføres for å hindre skade på husrommet eller eiendommen for øvrig. Medfører arbeidene ulempe for leieren, kan leieren kreve avslag i leien etter § 2-11 annet ledd forutsatt at ulempen ikke er ubetydelig. Bestemmelsen i forrige punktum gjelder ikke dersom mangelen beror på forhold på leierens side.

Leieren skal ha melding i rimelig tid før det foretas tilsyn eller vedlikeholdsarbeider. Før arbeider som nevnt i § 5-4 påbegynnes, skal leieren ha melding med frist som nevnt i § 9-6 første ledd. Bestemmelsene i første punktum gjelder ikke hvis det er nødvendig med tiltak for å hindre skade på husrommet eller eiendommen for øvrig, og det ikke er mulig å varsle leieren.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92294, 'lov/1999-03-26-17', 46, 5, 'kapittel-5-paragraf-7', '§ 5-7', 'Leierens krav på grunn av mangler som oppstår i leietiden', 'Oppfyller ikke utleieren sine plikter etter §§ 5-1 til 5-6 og mangelen ikke beror på forhold på leierens side, kan leieren kreve retting etter § 2-10, avslag i leien etter § 2-11 annet ledd forutsatt at mangelen ikke er ubetydelig, heve leieavtalen etter § 2-12, kreve erstatning etter §§ 2-13 og 2-14, og holde tilbake leie etter § 2-15.

Selv om mangelen beror på forhold på leierens side, plikter utleieren å rette mangelen etter § 2-10. Er leieren ansvarlig for økonomisk tap som følge av skaden, jf. § 5-8, kan utleieren stille som vilkår for retting at leieren erstatter tapet først.

Bestemmelsene i første ledd gjelder tilsvarende dersom tredjemanns rett i husrommet eller bestemmelser i lovgivningen eller offentlig vedtak i medhold av lov er til hinder for den avtalte bruk.

Om hovedleierens ansvar overfor framleieren ved bortfall av hovedleieavtalen, gjelder bestemmelsene i § 7-7.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92295, 'lov/1999-03-26-17', 47, 5, 'kapittel-5-paragraf-8', '§ 5-8', 'Leierens erstatningsansvar', 'Utleieren kan kreve erstatning for tap som følge av at leieren ikke oppfyller sine plikter etter §§ 5-1 til 5-6. Dette gjelder likevel ikke så langt leieren godtgjør at misligholdet skyldes en hindring utenfor leierens kontroll som leieren ikke med rimelighet kunne ventes å ha tatt i betraktning på avtaletiden eller å ha unngått eller overvunnet følgene av.

Skyldes misligholdet en tredjemann, som leieren har gitt i oppdrag helt eller delvis å oppfylle leieavtalen, er leieren fri for ansvar bare om også tredjemann ville være fritatt etter regelen i første ledd.

Ansvarsfriheten gjelder så lenge hindringen virker. Faller hindringen bort, kan ansvar gjøres gjeldende dersom leieren da plikter å oppfylle men ikke gjør dette.

Reglene i første ledd omfatter ikke slikt indirekte tap som nevnt i § 2-14 annet ledd, likevel slik at tap som følge av skade på husrommet med tilbehør regnes som direkte tap.

Utleieren kan i alle tilfeller kreve erstatning dersom misligholdet eller tapet skyldes feil eller forsømmelse fra leierens side. For utmålingen av erstatningen gjelder bestemmelsene i § 2-14 første, fjerde, femte og sjette ledd tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92296, 'lov/1999-03-26-17', 48, 6, 'kapittel-6-paragraf-1', '§ 6-1', 'Felles representasjon', 'I hus der utleieren har utleid flere enn fire boliger, kan boligleierne i møte med vanlig flertall av de avgitte stemmer velge en tillitsvalgt til å representere dem overfor utleieren. Den tillitsvalgte skal straks sende melding til utleieren om den vedtatte ordning og hvem som er valgt.

Den tillitsvalgte velges for ett år om gangen. Vervet som tillitsvalgt opphører først når ny tillitsvalgt er valgt, selv om tjenestetiden er utløpt.

Når særlige grunner foreligger, har den tillitsvalgte rett til å tre tilbake før tjenestetiden er ute.

Den tillitsvalgte kan i møte besluttes fjernet med vanlig flertall av de avgitte stemmer. Ordningen med felles representasjon kan oppheves på samme måte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92297, 'lov/1999-03-26-17', 49, 6, 'kapittel-6-paragraf-2', '§ 6-2', 'Den tillitsvalgtes plikter', 'Den tillitsvalgte skal ivareta boligleiernes interesser overfor utleieren, og kan kreve å få drøfte med utleieren alle spørsmål av betydning for boligleierne i huset.

Den tillitsvalgte skal minst én gang årlig innkalle alle boligleierne, herunder framleiere, til møte på hensiktsmessig måte.

Den tillitsvalgte er bundet av beslutninger som er truffet i møte med vanlig flertall av de avgitte stemmer. Ved avstemninger har hvert boligleieforhold en stemme. Framleiere har ikke stemmerett.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92298, 'lov/1999-03-26-17', 50, 6, 'kapittel-6-paragraf-3', '§ 6-3', 'Informasjon til tillitsvalgt m.v.', 'Utleieren plikter å underrette den tillitsvalgte om større vedlikeholdsarbeider og andre tiltak som i vesentlig grad berører boligleierne. Tiltak som nevnt i første punktum kan tidligst settes i verk én måned etter at utleieren har sendt underretning til den tillitsvalgte. Bestemmelsen i annet punktum gjelder likevel ikke dersom tiltaket ikke kan vente uten å utsette eiendommen for vesentlig skade.

Utleieren skal straks sende underretning til den tillitsvalgte dersom eiendommen overdras.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92299, 'lov/1999-03-26-17', 51, 7, 'kapittel-7-paragraf-1', '§ 7-1', 'Opptak i husstand', 'Leieren har rett til å ta opp i sin husstand sin ektefelle eller samboer, sine egne eller ektefellens eller samboerens slektninger i rett opp- eller nedstigende linje og fosterbarn. Opptak av andre personer i husstanden krever godkjenning fra utleieren. Godkjenning kan bare nektes dersom vedkommende persons forhold gir saklig grunn til det eller husrommet klart blir overbefolket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92300, 'lov/1999-03-26-17', 52, 7, 'kapittel-7-paragraf-2', '§ 7-2', 'Den alminnelige regelen om framleie', 'Leieren har ikke adgang til å framleie eller på annen måte overlate sin bruksrett til andre uten samtykke fra utleieren, med mindre annet følger av avtale eller lovbestemmelse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92301, 'lov/1999-03-26-17', 53, 7, 'kapittel-7-paragraf-3', '§ 7-3', 'Framleie av del av bolig', 'Leier av bolig som selv skal bo i boligen, kan framleie en del av boligen med godkjenning fra utleieren. Godkjenning kan bare nektes dersom framleierens forhold gir saklig grunn til det eller husrommet klart blir overbefolket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92302, 'lov/1999-03-26-17', 54, 7, 'kapittel-7-paragraf-4', '§ 7-4', 'Framleie av bolig ved midlertidig fravær', 'Leier av bolig kan framleie med godkjenning fra utleieren i inntil to år ved midlertidig fravær på grunn av arbeid, utdanning, militærtjeneste, sykdom eller andre tungtveiende grunner. Godkjenning kan bare nektes dersom framleierens forhold gir saklig grunn til det eller husrommet klart blir overbefolket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92303, 'lov/1999-03-26-17', 55, 7, 'kapittel-7-paragraf-5', '§ 7-5', 'Framleie ved tidsbestemte leieavtaler', 'Er leieavtalen inngått for en bestemt tid, kan leieren framleie for resten av leietiden med godkjenning fra utleieren. Blir godkjenning nektet uten at framleierens forhold gir saklig grunn til det eller husrommet klart blir overbefolket, kan leieren si opp med varsel som nevnt i § 9-6.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92304, 'lov/1999-03-26-17', 56, 7, 'kapittel-7-paragraf-6', '§ 7-6', 'Godkjenning ved passivitet', 'Svarer ikke utleieren på en skriftlig søknad om godkjenning etter bestemmelsene i §§ 7-1 til 7-5 innen én måned etter at søknaden er mottatt, skal dette regnes som godkjenning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92305, 'lov/1999-03-26-17', 57, 7, 'kapittel-7-paragraf-7', '§ 7-7', 'Framleierens stilling ved opphør av hovedleieavtalen', 'Sier utleieren opp hovedleieavtalen, har hovedleieren overfor framleieren plikt til å protestere etter § 9-8. Hovedleieren har likevel ikke plikt til å protestere dersom hovedleieren underretter framleieren om oppsigelsen senest 15 dager før fristen for å protestere etter reglene i § 9-8 løper ut.

Framleieren har en selvstendig rett til å protestere mot oppsigelsen etter § 9-8, innen den fristen som gjelder for hovedleieren. Har utleieren godkjent framleieren, skal utleieren samtidig sende gjenpart av oppsigelsen til framleieren. Oppsigelsen skal opplyse om at framleieren kan protestere mot oppsigelsen innen én måned etter at hovedleieren har mottatt den. Har framleieren protestert innen fristen, skal eventuelt søksmål rettes også mot hovedleieren. Er reglene i annet og tredje punktum ikke fulgt, er oppsigelsen ugyldig.

Framleieren kan kreve erstatning av hovedleieren for det økonomiske tapet som er en følge av bortfallet av hovedleieavtalen. Dette gjelder likevel ikke så langt hovedleieren godtgjør at bortfallet eller tapet skyldes forhold utenfor hovedleierens kontroll, som hovedleieren ikke med rimelighet kunne ventes å ha tatt i betraktning da framleieavtalen ble inngått, eller unngå eller overvinne følgene av. Bestemmelsene i §§ 2-13 annet til femte ledd og 2-14 gjelder tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92306, 'lov/1999-03-26-17', 58, 8, 'kapittel-8-paragraf-1', '§ 8-1', 'Den alminnelige regelen om overføring', 'Leieren har ikke adgang til å overføre sine rettigheter eller plikter etter leieavtalen til andre uten samtykke fra utleieren, med mindre annet følger av avtale eller lovbestemmelse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92307, 'lov/1999-03-26-17', 59, 8, 'kapittel-8-paragraf-2', '§ 8-2', 'Leierens død', 'Dør leieren av bolig, har følgende personer rett til å tre inn i leieavtalen:
a. ektefelle som bor i boligen,
b. leierens slektninger i rett nedstigende linje som hadde felles husstand med leieren i de siste seks måneder før dødsfallet, og
c. andre som ved dødsfallet hadde felles husstand med leieren, forutsatt at de fyller vilkårene i lov av 4. juli 1991 nr. 45 om rett til felles bolig og innbo når husstandsfellesskap opphører § 1.

Gjenlevende ektefelle har fortrinnsrett til å tre inn i avtalen. De øvrige berettigede har innbyrdes lik rett til å tre inn.

Sier utleieren opp leieavtalen etter dødsfallet, må de som ønsker å nytte sin rett etter første ledd, sende skriftlig melding om det til utleieren innen én måned regnet fra den dagen de har mottatt skriftlig melding om oppsigelsen, med opplysning om fristen for å gjøre rettigheten gjeldende og om at melding om inntreden skal være skriftlig. Sender den berettigede slik melding, regnes det som en protest mot oppsigelsen etter bestemmelsene i § 9-8. Utleieren plikter ikke å sende melding til husstandsmedlemmer som nevnt i første ledd bokstav c med mindre utleieren har godkjent dem etter reglene i § 7-1.

Sier dødsboet opp leieavtalen, må de som ønsker å nytte sin rett etter første ledd, sende melding om det til utleieren innen én måned regnet fra den dagen utleieren mottok dødsboets oppsigelse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92308, 'lov/1999-03-26-17', 60, 8, 'kapittel-8-paragraf-3', '§ 8-3', 'Samlivsbrudd, separasjon, skilsmisse og opphør av husstandsfellesskap', 'Forlater leieren ektefellenes felles bolig, har den andre ektefellen rett til å tre inn i leieavtalen.

Den ordning av bruksretten til ektefellenes felles bolig som blir fastsatt eller avtalt ved separasjon eller skilsmisse, er bindende for utleieren.

Husstandsmedlem har rett til å tre inn i leieavtalen dersom vilkårene i § 3 første ledd nr. 1, jf. § 1 i lov av 4. juli 1991 nr. 45 om rett til felles bolig og innbo når husstandsfellesskap opphører, er oppfylt. Ektefellenes slektninger i rett nedstigende linje har tilsvarende rett til å tre inn leieavtalen som et husstandsmedlem, dersom begge ektefellene forlater den felles boligen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92309, 'lov/1999-03-26-17', 61, 8, 'kapittel-8-paragraf-4', '§ 8-4', 'Overføring av leierett til lokale', 'Leier av lokale kan med utleierens godkjenning overføre sin leierett i forbindelse med en overføring av den virksomhet som drives i lokalet.

Var en avdød leier deltaker i et ansvarlig selskap, har de gjenværende deltakerne i selskapet med utleierens godkjenning rett til å tre inn i leieretten til de lokaler der selskapets virksomhet drives.

Godkjenning etter første og annet ledd kan bare nektes dersom den nye leierens forhold gir saklig grunn til det. Svarer ikke utleieren på en søknad om godkjenning etter første og annet ledd innen én måned etter at søknaden er mottatt, skal dette regnes som godkjenning til overføring.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92310, 'lov/1999-03-26-17', 62, 8, 'kapittel-8-paragraf-5', '§ 8-5', 'Gjennomføring av leierskifte', 'Krever leierskiftet godkjenning fra utleieren, overføres leieretten i forhold til utleieren fra det tidspunkt melding om godkjenning kommer fram til leieren, hvis ikke et senere tidspunkt er oppgitt i søknaden. Er leierskiftet godkjent ved utleierens passivitet, overføres leieretten i forhold til utleieren ved utløpet av svarfristen etter § 8-4 tredje ledd annet punktum, hvis ikke et senere tidspunkt er oppgitt i søknaden. Kan leierskiftet gjennomføres uten utleierens godkjenning, overføres bruksretten i forhold til utleieren fra det tidspunkt melding om leierskiftet kom fram til utleieren, hvis ikke et senere tidspunkt er oppgitt i meldingen.

For krav som forfaller etter det tidspunkt som er angitt i første ledd, hefter bare den nye leieren. Krever overføringen godkjenning fra utleieren, kan utleieren stille som vilkår for godkjenning at den nye leieren påtar seg personlig ansvar for krav som er forfalt de siste seks månedene, regnet fra det tidspunkt som er angitt i første ledd. Kravets størrelse skal angis.

Det at den tidligere leieren har misligholdt sine plikter etter lov eller avtale, gir ikke utleieren rett til å gjøre misligholdsbeføyelser gjeldende mot den nye leieren. Etter at søknad om godkjenning av overføring er kommet fram til utleieren, kan heving på grunn av at leieavtalen er misligholdt før dette tidspunktet, bare skje hvis godkjenning av overføringen kan nektes.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92311, 'lov/1999-03-26-17', 63, 8, 'kapittel-8-paragraf-6', '§ 8-6', 'Eierskifte', 'Ved eierskifte kan utleieren overføre til erververen rettigheter og forpliktelser etter leieavtalen.

Gir erververens forhold saklig grunn til det, kan leieren kreve at avhenderen er ansvarlig sammen med erververen for riktig oppfyllelse av forpliktelsene etter avtalen, med mindre det stilles betryggende sikkerhet. Leierens krav om at avhenderen skal hefte for oppfyllelsen, må settes fram overfor avhenderen innen seks måneder etter at leieren fikk eller burde ha fått kjennskap til eierskiftet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92312, 'lov/1999-03-26-17', 64, 9, 'kapittel-9-paragraf-1', '§ 9-1', 'Tidsbestemte og tidsubestemte leieavtaler', 'En husleieavtale kan inngås for bestemt eller ubestemt tid. Er ikke opphørstidspunktet fastsatt i leieavtalen, er den tidsubestemt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92313, 'lov/1999-03-26-17', 65, 9, 'kapittel-9-paragraf-2', '§ 9-2', 'Tidsbestemte leieavtaler', 'En leieavtale som er inngått for bestemt tid, opphører uten oppsigelse ved utløpet av den avtalte leietid. Ved utleie av bolig må utleieren skriftlig opplyse at leieavtalen ikke kan sies opp i den avtalte leietid.

En tidsbestemt leieavtale kan sies opp i leietiden i samsvar med bestemmelsene i §§ 9-4 til 9-8, dersom det er avtalt, eller dersom utleieren har forsømt sin opplysningsplikt etter første ledd annet punktum.

Fortsetter leieforholdet i mer enn tre måneder etter utløpet av den avtalte leietid uten at utleieren skriftlig har oppfordret leieren til å flytte, er leieavtalen gått over til å være tidsubestemt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92314, 'lov/1999-03-26-17', 66, 9, 'kapittel-9-paragraf-3', '§ 9-3', 'Adgangen til å inngå tidsbestemt leieavtale for bolig', 'Det er ikke adgang til å inngå tidsbestemt leieavtale for bolig for kortere tid enn tre år. Minstetiden kan likevel settes til ett år hvis avtalen gjelder lofts- eller sokkelbolig i enebolig eller bolig i tomannsbolig, og utleieren bor i samme hus. Bestemmelsene i første og annet punktum gjelder ikke dersom:
a. husrommet skal brukes som bolig av utleieren selv eller noen som hører til husstanden, eller
b. utleieren har en annen saklig grunn for tidsavgrensningen.

Utleieren kan bare påberope seg unntakene i første ledd bokstav a og b dersom leieren senest ved inngåelsen av avtalen skriftlig ble gjort kjent med grunnen for tidsavgrensningen, og husrommet ved utløpet av den avtalte leietid skal brukes i samsvar med den oppgitte grunnen. Utsettes tidspunktet for når husrommet skal brukes i samsvar med den oppgitte grunnen, kan leieavtalen forlenges fram til dette tidspunktet dersom utsettelsen skyldes en uforutsett omstendighet som har inntrådt etter at avtalen ble inngått.

Er tidsbestemt leieavtale for bolig inngått i strid med bestemmelsene i denne paragrafen, skal avtalen anses som tidsubestemt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92315, 'lov/1999-03-26-17', 67, 9, 'kapittel-9-paragraf-4', '§ 9-3 a', 'Midlertidig unntak ved utleie av fritidsbolig som bolig', 'For bygning hvor det er gitt unntak for tidsbestemt bruksendring fra fritidsbolig til bolig etter plan- og bygningsloven §§ 20-9 og 20-10, kan det inngås tidsbestemt leieavtale med minstetid på ned til ett år.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92316, 'lov/1999-03-26-17', 68, 9, 'kapittel-9-paragraf-5', '§ 9-4', 'Leierens oppsigelse av tidsubestemt leieavtale', 'Er ikke annet avtalt, kan tidsubestemt leieavtale sies opp av leieren.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92317, 'lov/1999-03-26-17', 69, 9, 'kapittel-9-paragraf-6', '§ 9-5', 'Utleierens oppsigelse av tidsubestemt leieavtale', 'Er ikke annet avtalt eller annet følger av loven her, kan tidsubestemt leieavtale sies opp av utleieren.

En tidsubestemt leieavtale om bolig kan bare sies opp av utleieren dersom:
a. husrommet skal brukes som bolig av utleieren selv eller noen som hører til husstanden,
b. riving eller ombygging av eiendommen gjør at husrommet må fravikes,
c. leieren har misligholdt leieavtalen, eller
d. det foreligger en annen saklig grunn til å si opp leieavtalen.

Tidsubestemt leieavtale om enkelt beboelsesrom der leieren etter leieavtalen har adgang til en annens bolig, kan sies opp av utleieren uten hinder av bestemmelsene i annet ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92318, 'lov/1999-03-26-17', 70, 9, 'kapittel-9-paragraf-7', '§ 9-6', 'Oppsigelsesfrist', 'Oppsigelsesfristen skal være tre måneder til opphør ved utløpet av en kalendermåned.

For leieavtale om enkelt beboelsesrom der leieren etter avtalen har adgang til en annens bolig, skal oppsigelsesfristen være én måned. Det samme gjelder for selvstendig leie av garasje eller bod.

For leieavtale om lokale der leien er avtalt pr. dag, skal oppsigelsesfristen være én dag.

Bestemmelsene i denne paragraf kan fravikes i avtale.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92319, 'lov/1999-03-26-17', 71, 9, 'kapittel-9-paragraf-8', '§ 9-7', 'Formkrav til utleierens oppsigelse', 'Oppsigelse fra utleier skal være skriftlig.

Oppsigelsen skal begrunnes. Oppsigelsen skal også opplyse om at leieren kan protestere skriftlig til utleieren innen én måned etter at oppsigelsen er mottatt. Oppsigelsen skal dessuten opplyse om at dersom leieren ikke protesterer innen fristen, taper leieren sin rett til å påberope seg at oppsigelsen er i strid med loven, jf. § 9-8 første ledd annet punktum, og at utleieren i så fall kan begjære tvangsfravikelse etter tvangsfullbyrdelsesloven § 13-2 tredje ledd bokstav c.

En oppsigelse som ikke fyller kravene i første og annet ledd, er ugyldig. Har leieren flyttet i henhold til oppsigelsen, anses den som godtatt.

Bestemmelsene i annet og tredje ledd gjelder ikke for oppsigelse av tidsubestemt leieavtale om enkelt beboelsesrom der leieren etter leieavtalen har adgang til en annens bolig. Det samme gjelder for leie av lokale der leien er avtalt pr. dag og for selvstendig leie av garasje eller bod.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92320, 'lov/1999-03-26-17', 72, 9, 'kapittel-9-paragraf-9', '§ 9-8', 'Tilsidesettelse av oppsigelse', 'Leieren kan innen én måned etter at oppsigelsen er mottatt, protestere skriftlig til utleieren mot oppsigelsen. Har leieren ikke protestert mot oppsigelsen i samsvar med første punktum, kan leieren ikke påberope seg at oppsigelsen er i strid med loven her. Har leieren protestert i samsvar med første punktum, faller oppsigelsen bort om ikke utleieren har reist søksmål mot leieren innen tre måneder etter at leierens frist løp ut.

Retten skal prøve om oppsigelsen er lovlig, og om den eventuelt skal settes til side. Oppsigelsen skal settes til side dersom retten ut fra en vurdering av begge parters forhold finner at den vil virke urimelig. Retten kan likevel ikke sette oppsigelsen til side dersom den kommer til at oppsigelsen skyldes vesentlig mislighold fra leierens side, jf. § 9-9 første ledd annet punktum.

Bestemmelsene i første og annet ledd gjelder ikke for oppsigelse av tidsubestemt leieavtale om enkelt beboelsesrom der leieren etter leieavtalen har adgang til en annens bolig. Det samme gjelder for leie av lokale der leien er avtalt pr. dag, og selvstendig leie av garasje eller bod.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92321, 'lov/1999-03-26-17', 73, 9, 'kapittel-9-paragraf-10', '§ 9-9', 'Utleierens hevingsrett', 'Utleieren kan heve leieavtalen på grunn av vesentlig mislighold fra leierens side. Vesentlig mislighold foreligger dersom:
a. leieren vesentlig misligholder sin plikt til å betale leie eller oppfylle andre krav som reiser seg av leieavtalen,
b. leieren tross skriftlig advarsel fra utleieren i vesentlig grad forsømmer sin vedlikeholdsplikt eller fortsetter å opptre på en måte som er til alvorlig skade eller sjenanse for utleieren, eiendommen eller øvrige brukere,
c. leieren uten å ha rett til det helt eller delvis overlater bruken av husrommet til andre og tross skriftlig advarsel fra utleieren ikke bringer forholdet til opphør,
d. leieren uten å ha rett til det bruker husrommet på annen måte eller til andre formål enn avtalt og tross skriftlig advarsel fra utleieren ikke bringer forholdet til opphør, eller
e. leieren for øvrig misligholder sine plikter på en måte som gjør det nødvendig å bringe leieavtalen til opphør.

En erklæring om at utleieren hever leieavtalen, skal være skriftlig. Den kan pålegge leieren straks å flytte og levere husrommet tilbake. I erklæringen skal grunnen til å heve leieavtalen oppgis.

Blir leieavtalen hevet, er leieren ansvarlig for utlegg, tapt leie o.l. etter bestemmelsene i § 5-8.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92322, 'lov/1999-03-26-17', 74, 9, 'kapittel-9-paragraf-11', '§ 9-10', 'Leierens død', 'Dør leieren før leieforholdet er slutt, har både utleieren og dødsboet rett til å si opp leieavtalen med varsel som nevnt i § 9-6, selv om avtalen er inngått for lengre tid eller med lengre oppsigelsesfrist.

Har leieren rett til å overføre bruksretten, har utleieren ikke rett til å si opp leieavtalen etter første ledd. Vil dødsboet i dette tilfelle si opp etter første ledd, må oppsigelse gis innen tre måneder regnet fra dødsfallet.

Oppsigelse etter første ledd skal være skriftlig. For øvrig gjelder ikke bestemmelsene i §§ 9-5 til 9-9 for oppsigelsen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92323, 'lov/1999-03-26-17', 75, 9, 'kapittel-9-paragraf-12', '§ 9-11', 'Varsel om fravikelse', 'Når det er grunnlag for å begjære fravikelse av husrommet kan utleier, dersom det er grunn til det, sende skriftlig varsel til sosialtjenesten i kommunen om misligholdet. En eventuell begjæring om tvangsfravikelse bør tidligst fremsettes for namsmyndigheten to uker etter at skriftlig varsel er sendt til sosialtjenesten. Utleier kan gi andre fullmakt til å sende slikt varsel. Leier kan i skriftlig melding til utleier reservere seg mot at slikt varsel blir sendt til sosialtjenesten.

Utleier skal senest samtidig med oversendelse av varsel til sosialtjenesten i kommunen etter første ledd, sende kopi av varselet eller annen melding om innholdet til leier.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92324, 'lov/1999-03-26-17', 76, 10, 'kapittel-10-paragraf-1', '§ 10-1', 'Visning før flytting', 'I tiden før fraflytting plikter leieren i rimelig utstrekning å gi leiesøkende adgang for å se på husrommet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92325, 'lov/1999-03-26-17', 77, 10, 'kapittel-10-paragraf-2', '§ 10-2', 'Tilbakelevering', 'Den dagen leieforholdet opphører, skal leieren stille husrommet med tilbehør til utleierens disposisjon. Er ikke annet avtalt, regnes tilbakelevering for skjedd når utleieren har fått nøkler og ellers uhindret atkomst til husrommet. Forlater leieren husrommet på en slik måte at leieforholdet klart må anses oppgitt, kan utleieren igjen straks disponere over det.

Er ikke annet avtalt, skal husrommet med tilbehør være ryddet, rengjort og i samme stand som ved overtakelsen, bortsett fra den forringelse som skyldes alminnelig slit og elde, og de mangler som utleieren selv plikter å utbedre.

Utleieren kan ikke uten særlig avtale kreve at leieren setter husrommet tilbake til opprinnelig stand så langt det gjelder endringer som leieren hadde rett til å utføre. Utleieren kan ikke i noe tilfelle kreve husrommet satt tilbake til opprinnelig stand dersom dette ville medføre uforholdsmessige omkostninger eller urimelig verditap, men utleieren kan kreve erstattet den verdireduksjon endringene har medført, hvis det gjelder endringer leieren ikke hadde rett til å utføre.

Fast inventar som leieren har brakt inn i husrommet, tilfaller utleieren hvis utskilling ville medføre uforholdsmessige omkostninger eller urimelig verditap.

Har leieren plikt til å vedlikeholde husrommet eller tilbehøret, skal vedlikeholdet være forsvarlig utført, men utleieren kan ikke uten særlig avtale kreve at husrommet eller tilbehøret er i bedre stand enn det var ved overleveringen.

Om leierens krav på vederlag gjelder § 10-5.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92326, 'lov/1999-03-26-17', 78, 10, 'kapittel-10-paragraf-3', '§ 10-3', 'Erstatning for forsinkelse og mangel', 'Stilles ikke husrommet til utleierens disposisjon den dagen leieforholdet er opphørt, kan utleieren kreve vederlag tilsvarende avtalt leie inntil leierens bruk opphører.

Er husrommet i dårligere stand enn hva som er avtalt eller fastsatt i § 10-2, kan utleieren kreve dekket nødvendige utgifter til utbedring. Kravet må være framsatt innen rimelig tid etter at utleieren burde ha oppdaget mangelen. Regelen i annet punktum gjelder ikke dersom leieren har opptrådt grovt uaktsomt eller i strid med redelighet og god tro.

Utleieren kan kreve erstatning for annet tap som følge av leierens mislighold. Dette gjelder likevel ikke så langt leieren godtgjør at misligholdet skyldes en hindring utenfor leierens kontroll, som leieren ikke med rimelighet kunne forventes å ha tatt i betraktning på avtaletiden eller å ha unngått eller overvunnet følgene av.

Skyldes misligholdet en tredjeperson som leieren har gitt i oppdrag helt eller delvis å sette husrommet i stand, er leieren fri for ansvar bare om også tredjemann ville være fritatt etter reglene i tredje ledd.

Ansvarsfriheten gjelder så lenge hindringen virker. Faller hindringen bort, kan ansvar gjøres gjeldende dersom leieren da plikter å oppfylle, men ikke gjør dette.

Reglene i tredje, fjerde og femte ledd omfatter ikke slikt indirekte tap som er nevnt i § 5-8 fjerde ledd.

Utleieren kan i alle tilfeller kreve erstatning dersom misligholdet eller tapet skyldes feil eller forsømmelse fra leierens side. For utmålingen av erstatningen gjelder bestemmelsene i § 2-14 første, femte og sjette ledd tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92327, 'lov/1999-03-26-17', 79, 10, 'kapittel-10-paragraf-4', '§ 10-4', 'Etterlatt løsøre', 'Finnes det i husrommet etterlatt løsøre som må antas å tilhøre leieren eller noen i leierens husstand, skal utleieren for leierens regning ta hånd om dette. Rent skrot kan likevel kastes umiddelbart. Medfører omsorgsplikten arbeid, kan utleieren kreve en rimelig godtgjørelse for dette.

Utleieren skal så vidt mulig skriftlig oppfordre leieren til å hente løsøret. Utleieren kan holde løsøret tilbake inntil kostnadene med oppbevaringen dekkes eller betryggende sikkerhet stilles.

Utleieren kan selge løsøret for leierens regning dersom kostnadene eller ulempene med oppbevaringen blir urimelige, eller dersom leieren venter urimelig lenge med å betale kostnadene eller med å overta løsøret. Er det grunn til å tro at salgssummen ikke vil dekke salgskostnadene, kan utleieren i stedet rå over tingen på annen hensiktsmessig måte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92328, 'lov/1999-03-26-17', 80, 10, 'kapittel-10-paragraf-5', '§ 10-5', 'Vederlag for forbedringer', 'Har leieren med utleierens samtykke gjort vesentlige forbedringer i husrommet, kan leieren kreve vederlag for den fordel utleieren oppnår som følge av forbedringene, med mindre annet ble avtalt da samtykket ble gitt.

Blir partene ikke enige om vederlaget etter første ledd, kan begge parter kreve tvisten avgjort etter bestemmelsen i § 12-2. Vederlaget fastsettes likevel av retten når utleieren har gått til sak mot leieren etter reglene i § 9-8, og oppsigelsen ikke settes til side.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92329, 'lov/1999-03-26-17', 81, 10, 'kapittel-10-paragraf-6', '§ 10-6', 'Vederlag for kundekrets', 'Er leieren av lokale oppsagt, og oppsigelsen ikke settes til side etter reglene i § 9-8, kan leieren kreve vederlag for den fordel utleieren oppnår som følge av den kundekrets leieren har opparbeidet. Når vederlag tilkjennes, skal retten som regel fastsette at utleieren kan kreve hele eller en bestemt del av vederlaget tilbake, dersom leieren innen en fastsatt frist på inntil tre år på ny starter tilsvarende virksomhet innenfor et område som fastsettes av retten.

Vederlag kan ikke tilkjennes dersom leieren har gjort seg skyldig i vesentlig mislighold.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92330, 'lov/1999-03-26-17', 82, 11, 'kapittel-11-paragraf-1', '§ 11-1', 'Boliger til vanskeligstilte på boligmarkedet', 'Bestemmelsene i paragrafen her gjelder utleie av offentlig disponert bolig som skal brukes av vanskeligstilte på boligmarkedet. Bestemmelsene gjelder også utleie av annen bolig som er forbeholdt vanskeligstilte på boligmarkedet etter vedtak av organ for stat, fylkeskommune eller kommune. Med vanskeligstilte på boligmarkedet menes personer som trenger hjelp til å skaffe seg bolig på grunn av dårlig økonomi, nedsatt funksjonsevne, helsemessige eller sosiale problemer, dårlige kunnskaper om det norske boligmarkedet eller liknende forhold.

Bestemmelsene gjelder bare dersom leieren har fått opplyst skriftlig at avtalen gjelder bolig som skal brukes av vanskeligstilte på boligmarkedet, og hvilke unntak som er avtalt etter paragrafen her.

Det kan avtales at opptak av husstandsmedlem som nevnt i § 7-1 første punktum bare kan skje med utleierens godkjenning. Godkjenning kan i så fall bare nektes dersom forhold knyttet til boligens utforming eller formål tilsier det.

Det kan avtales at opptak av husstandsmedlem som nevnt i § 7-1 annet punktum og framleie av del av bolig som nevnt i § 7-3 bare kan skje med utleierens godkjenning. Godkjenning kan i så fall bare nektes dersom husrommet klart blir overbefolket, eller dersom det er nødvendig på grunn av forhold ved vedkommende person, eller forhold knyttet til boligens utforming eller formål.

Det kan avtales at framleie ved midlertidig fravær som nevnt i § 7-4 kan nektes dersom utleieren tilbyr seg å disponere boligen under leierens fravær, og leieren gis rett til å ta boligen i bruk igjen etter fraværet.

Dersom det foreligger særlige grunner, kan det inngås tidsbestemt leieavtale for kortere tid enn tre år uten hinder av § 9-3. Det er ikke adgang til å inngå mer enn én tidsbestemt avtale for samme bolig mellom de samme partene av kortere varighet enn det som følger av § 9-3. Dersom det foreligger tungtveiende grunner, kan det likevel inngås flere tidsbestemte leieavtaler av kortere varighet enn det som følger av § 9-3. En tidsbestemt leieavtale inngått i strid med bestemmelsene her, skal anses som tidsubestemt.

Uten hinder av bestemmelsene i § 3-7 kan det avtales at leier av bolig som nevnt i første ledd skal yte et lån til utleieren, dersom stat, fylkeskommune eller kommune er utleier.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92331, 'lov/1999-03-26-17', 83, 11, 'kapittel-11-paragraf-2', '§ 11-2', 'Elev- og studentboliger', 'Bestemmelsene i paragrafen her gjelder utleie av bolig som etter vedtak av organ for stat, fylkeskommune eller kommune skal brukes av elever og studenter. Bestemmelsene gjelder bare dersom leieren har fått opplyst skriftlig at avtalen gjelder slik bolig, og at dette gir leieren færre rettigheter enn ved leie av annen bolig.

Det kan avtales at opptak av husstandsmedlem som nevnt i § 7-1 første punktum bare kan skje med utleierens godkjenning. Godkjenning kan i så fall bare nektes dersom forhold knyttet til boligens utforming eller formål tilsier det.

Det kan avtales at opptak av husstandsmedlem som nevnt i § 7-1 annet punktum og framleie av del av bolig som nevnt i § 7-3 bare kan skje med utleierens godkjenning. Godkjenning kan i så fall bare nektes dersom husrommet klart blir overbefolket, eller dersom det er nødvendig på grunn av forhold ved vedkommende person, eller knyttet til boligens utforming eller formål.

Framleie etter § 7-4 ved midlertidig fravær kan nektes dersom utleieren tilbyr seg å disponere boligen under leierens fravær, og leieren gis rett til å ta boligen i bruk igjen etter fraværet.

Uten hinder av bestemmelsene i kapittel 9 om opphør kan det avtales at leieavtalen skal falle bort uten oppsigelse ved endt semester, endt studieår eller endt utdannelse. Uten hinder av § 9-3 kan partene også inngå en tidsbestemt leieavtale for kortere tid enn tre år. Er leieavtalen ikke inngått for bestemt tid, har leieren før fraflytting alltid krav på varsel med frist som nevnt i § 9-6.

Uten hinder av § 3-5 tredje ledd kan det avtales at rentene av konto for depositum skal godskrives utleieren.

Uten hinder av § 3-2 første ledd annet punktum kan det avtales forskuddsbetaling for inntil tre måneder.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92332, 'lov/1999-03-26-17', 84, 11, 'kapittel-11-paragraf-3', '§ 11-3', 'Tjenestebolig', 'Bestemmelsene i paragrafen her gjelder ved utleie av bolig som leieren har leid i egenskap av arbeidstaker, når leieren har fått opplyst skriftlig at avtalen gjelder bolig som her nevnt, og at dette gir leieren færre rettigheter enn ved leie av annen bolig.

Retten til å tre inn i leieavtalen etter § 8-2 gjelder ikke når leieren, eller noen som har fortsatt leieforholdet, dør. Før begjæring om fraflytting kan settes fram, har hustandsmedlem krav på varsel med frist som nevnt i § 9-6.

Skal leieren tre ut av arbeidsforholdet eller bli forflyttet, kan oppsigelse av leieforholdet bare settes til side av retten etter § 9-8 når særlige grunner gjør det rimelig. Retten skal påse at oppsigelsen ikke blir brukt som kampmiddel i arbeidstvist. Dette gjelder også når leieren eller husstandsmedlem etter arbeidsforholdets opphør har fortsatt leieforholdet eller i stedet leid annen bolig av arbeidsgiveren.

Retten til å heve leieavtalen ved forsinkelse etter § 2-12 og bestemmelsene i § 7-4 og § 8-3 gjelder ikke for bolig som leieren har plikt til å bebo, og boplikten er nødvendig for utføringen av arbeidet. For slik bolig faller leieavtalen bort uten hinder av bestemmelsene i kapittel 9 når leieren trer ut av arbeidsforholdet, eller blir forflyttet.

Bestemmelsene i fjerde ledd gjelder tilsvarende for:
a. bolig som staten har stilt til disposisjon for medlemmer og varamedlemmer til Stortinget eller for departementenes politiske ledelse,
b. bolig som kommune, Opplysningsvesenets fond eller lovbestemt kirkelig organ har stilt til disposisjon for embets- eller tjenestemann i Den norske kirke, og
c. bolig som forsvaret har stilt til disposisjon for eget personell.

For boliger som nevnt i femte ledd gjelder ikke §§ 4-2 og 4-3.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92333, 'lov/1999-03-26-17', 85, 11, 'kapittel-11-paragraf-4', '§ 11-4', 'Utleie av egen bolig', 'Bestemmelsene i paragrafen her gjelder utleie av bolig som utleieren selv har brukt som egen bolig, og som blir leid ut ved midlertidig fravær på inntil fem år. Bestemmelsene gjelder bare dersom leieren har fått opplyst skriftlig at avtalen gjelder bolig som her nevnt, og at dette gir leieren færre rettigheter enn ved leie av annen bolig.

Bestemmelsen i § 7-3 om framleie av del av bolig og § 7-4 om framleie ved midlertidig fravær gjelder ikke.

Av bestemmelsene i kapittel 9 skal bare § 9-10 om leierens død gjelde. Er leieavtalen ikke inngått for bestemt tid, har leieren før fraflytting alltid krav på varsel med frist som nevnt i § 9-6.

Har utleieren ikke sagt opp leieavtalen eller oppfordret leieren til å flytte før utleierens fravær har vart i fem år, gjelder lovens bestemmelser fullt ut for leieavtalen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92334, 'lov/1999-03-26-17', 86, 12, 'kapittel-12-paragraf-1', '§ 12-1', 'Voldgift', 'Avtale om at tvister mellom utleier og leier som gjelder leie av bolig skal avgjøres ved voldgift, er bare bindende dersom avtalen om voldgiftsavgjørelse er inngått etter at tvisten oppstod.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92335, 'lov/1999-03-26-17', 87, 12, 'kapittel-12-paragraf-2', '§ 12-2', 'Takstnemnd', 'Kommer ikke partene til enighet om hva som er markedsleie etter § 3-1 eller gjengs leie etter § 4-3, kan hver av partene kreve tvisten avgjort av en takstnemnd. Det samme gjelder dersom partene ikke kommer til enighet om vederlag for forbedringer etter § 10-5.

Takstnemnda skal bestå av tre medlemmer og oppnevnes av tingretten i den rettskrets hvor eiendommen ligger. For takstnemnda gjelder bestemmelsene i domstolsloven §§ 106 og 108 så langt de passer. Hver av partene kan sette fram krav om ny takstnemnd innen fjorten dager etter at takstnemndas skriftlige og begrunnede avgjørelse er mottatt. Tingretten skal ta kravet til følge hvis:
a. avgjørelsen bygger på uforsvarlig saksbehandling eller uriktig oppfatning av faktiske omstendigheter, og dette må antas å ha påvirket verdsettelsen i vesentlig grad, eller
b. verdsettelsen åpenbart er uriktig.

Hver av partene kan bringe saken inn for tingretten ved stevning. Stevningen må være inngått til retten innen én måned etter at takstnemndas skriftlige og begrunnede avgjørelse er mottatt. På samme måte kan saken bringes inn for tingretten dersom takstnemndas avgjørelse ikke foreligger to måneder etter oppnevningen. En avgjørelse som ikke er brakt inn for retten innen fristen nevnt i annet punktum, har virkning som en rettskraftig dom. Retten kan gi oppfriskning for oversittelse av frist som nevnt i annet punktum.

Retten skal fastsette godtgjørelsen for medlemmene av takstnemnda. Retten kan bestemme at den som har krevd takst skal betale inn et beløp til sikkerhet for godtgjørelsen. Utleieren skal bære kostnadene dersom takstnemnda fastsetter et lavere beløp enn det utleieren har krevd i leie, eller høyere vederlag enn det utleieren har vært villig til å betale for påkostningene. Ellers skal leieren betale kostnadene. Rettens avgjørelse treffes ved kjennelse og skal begrunnes. Partene kan anke kjennelsen innen én måned.

Blir saken brakt inn for retten etter tredje ledd, kan retten avgjøre spørsmålet om ansvar for kostnadene med takstnemnd etter tvisteloven kapittel 20.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92336, 'lov/1999-03-26-17', 88, 12, 'kapittel-12-paragraf-3', '§ 12-3', 'Midlertidig bruksrett', 'Når søksmål om godkjenning etter reglene i kapitlene 7, 8 eller 11 er reist, kan retten ved kjennelse etter begjæring fra saksøkeren, mot eller uten sikkerhetsstillelse, beslutte at den som kreves godkjent som framleier, husstandsmedlem eller ny leier, skal ha bruksrett til husrommet inntil saken er rettskraftig avgjort. Saksbehandlingsreglene i tvisteloven kapittel 32 og 34 gjelder tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92337, 'lov/1999-03-26-17', 89, 12, 'kapittel-12-paragraf-4', '§ 12-4', 'Foregrepet tvangskraft', 'Når det er avsagt dom i sak som nevnt i § 9-8 og oppsigelsen ikke er satt til side, kan retten etter begjæring fra utleieren, mot eller uten sikkerhetsstillelse, i særlige tilfelle ved kjennelse gi samtykke til at fraviking gjennomføres før dommen er rettskraftig. Er dommen påanket, kan samtykke gis av ankedomstolen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92338, 'lov/1999-03-26-17', 90, 12, 'kapittel-12-paragraf-5', '§ 12-5', 'Husleietvistutvalget', 'Husleietvistutvalget behandler tvister etter loven her og etter lov 16. juni 1939 nr. 6 om husleie.

Husleietvistutvalget er faglig uavhengig og kan ikke instrueres om behandlingen av enkeltsaker eller om den faglige virksomheten for øvrig.

Husleietvistutvalget kan uten hinder av taushetsplikt innhente opplysninger fra folkeregisteret som er nødvendige for utførelsen av oppgaver etter loven her og forskrifter fastsatt med hjemmel i loven her.

Tvister om leie av bolig må behandles av Husleietvistutvalget før de kan bringes inn for tingretten hvis det følger av rettergangslovgivningen at behandling i forliksrådet ellers ville vært nødvendig. Forliksrådet kan ikke behandle tvister om leie av bolig.

Innbringelse av en sak for Husleietvistutvalget skal likestilles med søksmål etter tvangsfullbyrdelsesloven § 5-11 første ledd annet punktum.

Departementet kan gi forskrift om Husleietvistutvalget.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92339, 'lov/1999-03-26-17', 91, 13, 'kapittel-13-paragraf-1', '§ 13-1', 'Ikrafttredelse', 'Denne lov trer i kraft fra den tid Kongen bestemmer.[1]', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92340, 'lov/1999-03-26-17', 92, 13, 'kapittel-13-paragraf-2', '§ 13-2', 'Overgangsbestemmelser', 'Loven gjelder fullt ut for leieavtale som er inngått etter lovens ikrafttredelse.

For tidsubestemt leieavtale som er inngått før lovens ikrafttredelse gjelder loven fra utløpet av den lengste oppsigelsesfristen, regnet fra lovens ikrafttredelse, med følgende unntak eller endringer:
a. Bestemmelsene i § 3-1 første ledd om leien skal gjelde fra det tidspunkt leien etter lov eller avtale skal fastsettes på ny. Bestemmelsen i § 3-6 annet punktum om garantibeløp skal ikke gjelde garantiavtale inngått før lovens ikrafttredelse. Det samme skal gjelde ved fornyelse av slik avtale, dersom leieren etter leieavtalen som gjaldt ved lovens ikrafttredelse var forpliktet til dette.
b. Bestemmelsene i kapittel 9 om oppsigelse skal gjelde for oppsigelse som gis etter lovens ikrafttredelse.
c. Bestemmelsene i § 10-5 om vederlag for forbedringer skal gjelde dersom utleierens samtykke er gitt etter lovens ikrafttredelse.
d. Bestemmelsene i kapittel 11 skal ikke gjelde for avtale som er inngått før lovens ikrafttredelse.
e. Bestemmelsene i § 12-1 om voldgift skal gjelde for voldgiftsavtale som er inngått etter lovens ikrafttredelse. Bestemmelsene i § 12-3 om midlertidig bruksrett skal gjelde dersom søksmål er reist etter lovens ikrafttredelse. Bestemmelsene i § 12-4 om foregrepet tvangskraft skal gjelde dersom dommen er avsagt etter lovens ikrafttredelse. For dommer forkynt etter lovens ikrafttredelse gjelder ankefristene i tvisteloven § 29-5.

Som tidsubestemt etter bestemmelsen her regnes også leieavtale mellom borettslag eller boligaksjeselskap og selskapsmedlem med bruksrett.

Bestemmelsene i lovens kapittel 1 til 11 skal ikke gjelde for tidsbestemt leieavtale som er inngått før lovens ikrafttredelse. Bestemmelsene i annet ledd bokstav e skal likevel gjelde tilsvarende for tidsbestemt leieavtale som er inngått før lovens ikrafttredelse. Leieavtale som bare kan sies opp av en av partene, og leieavtale som bare kan sies opp dersom det foreligger vesentlig mislighold, regnes som tidsbestemt i forhold til reglene her, jf. likevel tredje ledd.

Reglene om bortleie av bolig mot lån i kapittel 9 i lov av 16. juni 1939 nr. 6 om husleie fortsetter å gjelde for avtaler som er inngått før loven her har trådt i kraft.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (92341, 'lov/1999-03-26-17', 93, 13, 'kapittel-13-paragraf-3', '§ 13-3', 'Opphevelse og endringer av andre lover', 'Fra den tid loven her trer i kraft, oppheves lov av 16. juni 1939 nr. 6 om husleie.

Fra samme tidspunkt gjøres følgende endringer i andre lover: – – –', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96816, 'lov/2005-06-17-62', 1, 1, 'kapittel-1-paragraf-1', '§ 1-1', 'Lovens formål', 'Lovens formål er:
a. å sikre et arbeidsmiljø som gir grunnlag for en helsefremmende og meningsfylt arbeidssituasjon, som gir full trygghet mot fysiske og psykiske skadevirkninger, og med en velferdsmessig standard som til enhver tid er i samsvar med den teknologiske og sosiale utvikling i samfunnet,
b. å sikre trygge ansettelsesforhold og likebehandling i arbeidslivet,
c. å legge til rette for et godt ytringsklima i virksomheten,
d. å legge til rette for tilpasninger i arbeidsforholdet knyttet til den enkelte arbeidstakers forutsetninger og livssituasjon,
e. å gi grunnlag for at arbeidsgiver og arbeidstakerne i virksomhetene selv kan ivareta og utvikle sitt arbeidsmiljø i samarbeid med arbeidslivets parter og med nødvendig veiledning og kontroll fra offentlig myndighet,
f. å bidra til et inkluderende arbeidsliv.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96817, 'lov/2005-06-17-62', 2, 1, 'kapittel-1-paragraf-2', '§ 1-2', 'Hva loven omfatter', '(1) Loven gjelder for virksomhet som sysselsetter arbeidstaker, med mindre annet er uttrykkelig fastsatt i loven.

(2) Unntatt fra loven er:
a. sjøfart, fangst og fiske, herunder bearbeiding av fangsten ombord i skip, men likevel slik at dykkeoperasjoner og losing er omfattet av loven
b. militær luftfart som omfattes av luftfartsloven.
Departementet kan gi forskrift om unntak fra loven for sivil luftfart og annen statsluftfart enn militær luftfart og om særregler for slik luftfart og om lovens anvendelse for dykkeoperasjoner og om særregler og unntak for slike operasjoner.

(3) Kongen kan gi forskrift om og i hvilken utstrekning bestemmelsene i kapittel 14, 15, 16 og 17 skal gjelde for arbeidstakere som omfattes av lov 16. juni 2017 nr. 67 om statens ansatte mv. (statsansatteloven) eller som er embetsmenn.

(4) Kongen kan gi forskrift om at deler av den offentlige forvaltning, helt eller delvis skal unntas fra loven når virksomheten er av så særegen art at den vanskelig lar seg tilpasse lovens bestemmelser.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96818, 'lov/2005-06-17-62', 3, 1, 'kapittel-1-paragraf-3', '§ 1-3', 'Virksomhet til havs', '(1) Loven gjelder for virksomhet i forbindelse med undersøkelse etter og utnyttelse av naturforekomster på havbunnen eller i dens undergrunn, i indre norske farvann, norsk sjøterritorium og den norske del av kontinentalsokkelen.

(2) Loven gjelder for virksomhet i forbindelse med fornybar energiproduksjon og omforming og overføring av elektrisk energi til havs.

(3) Loven gjelder for virksomhet som nevnt i første og annet ledd i området utenfor den norske del av kontinentalsokkelen dersom dette følger av særskilt avtale med fremmed stat eller av folkeretten for øvrig.

(4) Departementet kan gi forskrift om at virksomhet som nevnt i første til tredje ledd skal unntas helt eller delvis fra loven. Departementet kan også gi forskrift om at loven helt eller delvis skal gjelde for virksomhet som nevnt i første ledd i områder utenfor den norske del av kontinentalsokkelen dersom det foretas undersøkelser eller utnyttelse av naturforekomster på havbunnen eller i dens undergrunn fra en innretning registrert i norsk skipsregister, eller det gjennomføres bemannede undervannsoperasjoner fra en innretning eller et fartøy registrert i norsk skipsregister. Departementet kan også gi forskrift om at loven skal gjelde ved forflytning av innretning eller fartøy som nevnt.

(5) I forskrift etter denne paragrafen kan det også fastsettes særregler.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96819, 'lov/2005-06-17-62', 4, 1, 'kapittel-1-paragraf-4', '§ 1-4', 'Virksomhet som ikke sysselsetter arbeidstaker mv.', '(1) Departementet kan gi forskrift om at lovens regler helt eller delvis skal gjelde for virksomhet som ikke sysselsetter arbeidstaker.

(2) Departementet kan gi forskrift om at lovens regler helt eller delvis skal gjelde for byggherre eller dennes representant.

(3) I forskrift etter denne paragraf kan det fastsettes særregler.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96820, 'lov/2005-06-17-62', 5, 1, 'kapittel-1-paragraf-5', '§ 1-5', 'Arbeid i arbeidstakers og arbeidsgivers hjem', '(1) Departementet kan gi forskrift om og i hvilken utstrekning loven skal gjelde for arbeid som utføres i arbeidstakers hjem.

(2) Departementet kan gi forskrift om at lovens regler helt eller delvis skal gjelde for arbeidstaker som utfører arbeid i arbeidsgivers hjem eller husholdning.

(3) I forskrift etter denne paragraf kan det fastsettes særregler.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96821, 'lov/2005-06-17-62', 6, 1, 'kapittel-1-paragraf-6', '§ 1-6', 'Personer som ikke er arbeidstakere', '(1) Følgende personer anses som arbeidstakere etter lovens regler om varsling og helse, miljø og sikkerhet når de utfører arbeid i virksomhet som går inn under loven:
a. elever ved institusjoner som har undervisning eller forskning som formål,
b. vernepliktige,
c. sivile tjenestepliktige og tjenestepliktige i sivilforsvaret,
d. innsatte i kriminalomsorgens anstalter,
e. pasienter i helseinstitusjoner, attføringsinstitusjoner o.l.,
f. personer som i opplæringsøyemed eller i forbindelse med arbeidsrettede tiltak utplasseres i virksomheter uten å være arbeidstakere,
g. personer som uten å være arbeidstakere deltar i arbeidsmarkedstiltak.
Lovens regler om varsling gjelder likevel ikke for personer som nevnt i bokstav d. Departementet kan i forskrift fastsette unntak fra bestemmelsen i første punktum.

(2) Lovens bestemmelser om arbeidsgiveren gjelder for den som lar personer som nevnt i første ledd utføre arbeid i sin virksomhet.

(3) Departementet kan gi forskrift om i hvilken utstrekning lovens øvrige bestemmelser skal gjelde for personer nevnt i første ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96822, 'lov/2005-06-17-62', 7, 1, 'kapittel-1-paragraf-7', '§ 1-7', 'Utsendt arbeidstaker', '(1) Med utsendt arbeidstaker menes arbeidstaker som i et begrenset tidsrom arbeider i et annet land enn det arbeidsforholdet vanligvis er knyttet til.

(2) Utsending av arbeidstaker anses å foreligge når en utenlandsk virksomhet i forbindelse med tjenesteyting:
a. etter avtale med en mottaker av tjenesteytelser i Norge, sender en arbeidstaker til Norge for egen regning og risiko og under egen ledelse, eller
b. sender en arbeidstaker til et forretningssted eller virksomhet i Norge som inngår i konsernet, eller
c. i egenskap av å være vikarbyrå eller annen virksomhet som stiller arbeidstakere til rådighet, sender arbeidstakere til en virksomhet i Norge.

(3) Utsending av arbeidstaker anses også å foreligge når en norsk virksomhet i forbindelse med tjenesteyting sender en arbeidstaker til et annet land innenfor EØS-området.

(4) Departementet kan i forskrift gi regler om hvilke lønns- og arbeidsvilkår i lov eller i medhold av lov som skal gjelde for utsendte arbeidstakere, og nødvendige bestemmelser for å sikre etterlevelse av reglene, herunder bestemmelser om samarbeid med ansvarlige myndigheter i andre EØS-stater, vern og erstatning ved gjengjeldelse fra arbeidsgiver, kriterier for å avgjøre om utsendingen er reell, vederlag for innkvartering og krav til dokumentasjon.

(5) I forbindelse med gjensidig samarbeid mellom EØS-stater i samsvar med forskrift gitt med hjemmel i arbeidsmiljøloven § 1-7 fjerde ledd og § 18-11 femte ledd, kan opplysninger gis til ansvarlige myndigheter i en annen EØS-stat uten hinder av lovbestemt taushetsplikt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96823, 'lov/2005-06-17-62', 8, 1, 'kapittel-1-paragraf-8', '§ 1-8', 'Arbeidstaker og arbeidsgiver', '(1) Med arbeidstaker menes i denne lov enhver som utfører arbeid for og underordnet en annen. Ved avgjørelsen skal det blant annet legges vekt på om vedkommende løpende stiller sin personlige arbeidskraft til disposisjon, og om vedkommende er underordnet gjennom styring, ledelse og kontroll. Det skal legges til grunn at det foreligger et arbeidstakerforhold med mindre oppdragsgiver gjør det overveiende sannsynlig at det foreligger et selvstendig oppdragsforhold.

(2) Med arbeidsgiver menes i denne lov enhver som har ansatt en arbeidstaker som nevnt i første ledd. Det som i denne lov er bestemt om arbeidsgiver, skal gjelde tilsvarende for den som i arbeidsgivers sted leder virksomheten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96824, 'lov/2005-06-17-62', 9, 1, 'kapittel-1-paragraf-9', '§ 1-9', 'Ufravikelighet', 'Loven kan ikke fravikes ved avtale til ugunst for arbeidstaker med mindre det er særskilt fastsatt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96825, 'lov/2005-06-17-62', 10, 2, 'kapittel-2-paragraf-1', '§ 2-1', 'Arbeidsgivers plikter', 'Arbeidsgiver skal sørge for at bestemmelsene gitt i og i medhold av denne lov blir overholdt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96826, 'lov/2005-06-17-62', 11, 2, 'kapittel-2-paragraf-2', '§ 2-2', 'Arbeidsgivers plikter overfor andre enn egne arbeidstakere', '(1) Når andre enn arbeidsgivers egne arbeidstakere, herunder innleide arbeidstakere eller selvstendige oppdragstakere, utfører arbeidsoppgaver i tilknytning til arbeidsgivers aktivitet eller innretning, skal arbeidsgiver:
a. sørge for at egen virksomhet er innrettet og egne arbeidstakeres arbeid er ordnet og blir utført på en slik måte at også andre enn egne arbeidstakere er sikret et fullt forsvarlig arbeidsmiljø,
b. samarbeide med andre arbeidsgivere for å sikre et fullt forsvarlig arbeidsmiljø,
c. sørge for at innleid arbeidstakers arbeidstid er i samsvar med bestemmelsene i kapittel 10.

(2) Hovedbedriften skal ha ansvaret for samordningen av de enkelte virksomheters helse-, miljø- og sikkerhetsarbeid. Dersom det samtidig sysselsettes mer enn 10 arbeidstakere, og ingen virksomhet kan regnes som hovedbedrift, skal det skriftlig avtales hvem som skal ha ansvaret for samordningen. Kommer slik avtale ikke i stand, skal det meldes til Arbeidstilsynet som bestemmer hvem som skal ha ansvaret for samordningen.

(3) Departementet kan i forskrift gi nærmere bestemmelser om gjennomføringen av arbeidsgivers plikter etter denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96827, 'lov/2005-06-17-62', 12, 2, 'kapittel-2-paragraf-3', '§ 2-3', 'Arbeidstakers medvirkningsplikt', '(1) Arbeidstaker skal medvirke ved utforming, gjennomføring og oppfølging av virksomhetens systematiske helse-, miljø- og sikkerhetsarbeid. Arbeidstaker skal delta i det organiserte verne- og miljøarbeidet i virksomheten og skal aktivt medvirke ved gjennomføring av de tiltak som blir satt i verk for å skape et godt og sikkert arbeidsmiljø.

(2) Arbeidstaker skal:
a. bruke påbudt verneutstyr, vise aktsomhet og ellers medvirke til å hindre ulykker og helseskader,
b. straks underrette arbeidsgiver og verneombudet og i nødvendig utstrekning andre arbeidstakere når arbeidstakeren blir oppmerksom på feil eller mangler som kan medføre fare for liv eller helse, og vedkommende ikke selv kan rette på forholdet,
c. avbryte arbeidet dersom arbeidstaker mener at det ikke kan fortsette uten å medføre fare for liv eller helse,
d. sørge for at arbeidsgiver eller verneombudet blir underrettet så snart arbeidstaker blir kjent med at det forekommer trakassering eller diskriminering på arbeidsplassen,
e. melde fra til arbeidsgiver dersom arbeidstaker blir skadet i arbeidet eller pådrar seg sykdom som arbeidstaker mener har sin grunn i arbeidet eller forholdene på arbeidsstedet,
f. medvirke ved utarbeiding og gjennomføring av oppfølgingsplaner ved helt eller delvis fravær fra arbeidet på grunn av ulykke, sykdom, slitasje eller lignende,
g. delta i dialogmøte etter innkalling fra arbeidsgiver, jf. § 4-6 fjerde ledd.
h. rette seg etter påbud fra Arbeidstilsynet.

(3) Arbeidstaker som har til oppgave å lede eller kontrollere andre arbeidstakere, skal påse at hensynet til sikkerhet og helse blir ivaretatt under planleggingen og utførelsen av de arbeidsoppgaver som hører under eget ansvarsområde.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96828, 'lov/2005-06-17-62', 13, 2, 'kapittel-2-paragraf-4', '§ 2-4', '(Opphevet)', '', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96829, 'lov/2005-06-17-62', 14, 2, 'kapittel-2-paragraf-5', '§ 2-5', '(Opphevet)', '', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96830, 'lov/2005-06-17-62', 15, 3, 'kapittel-3-paragraf-1', '§ 2 A-1', 'Rett til å varsle om kritikkverdige forhold i virksomheten', '(1) Arbeidstaker har rett til å varsle om kritikkverdige forhold i arbeidsgivers virksomhet. Innleid arbeidstaker har også rett til å varsle om kritikkverdige forhold i virksomheten til innleier.

(2) Med kritikkverdige forhold menes forhold som er i strid med rettsregler, skriftlige etiske retningslinjer i virksomheten eller etiske normer som det er bred tilslutning til i samfunnet, for eksempel forhold som kan innebære
a. fare for liv eller helse
b. fare for klima eller miljø
c. korrupsjon eller annen økonomisk kriminalitet
d. myndighetsmisbruk
e. uforsvarlig arbeidsmiljø
f. brudd på personopplysningssikkerheten.

(3) Ytring om forhold som kun gjelder arbeidstakers eget arbeidsforhold regnes ikke som varsling etter kapitlet her, med mindre forholdet omfattes av andre ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96831, 'lov/2005-06-17-62', 16, 3, 'kapittel-3-paragraf-2', '§ 2 A-2', 'Fremgangsmåte ved varsling', '(1) Arbeidstaker kan alltid varsle internt
a. til arbeidsgiver eller en representant for arbeidsgiver
b. i samsvar med virksomhetens rutiner for varsling
c. i samsvar med varslingsplikt
d. via verneombud, tillitsvalgt eller advokat.

(2) Arbeidstaker kan alltid varsle eksternt til en offentlig tilsynsmyndighet eller en annen offentlig myndighet.

(3) Arbeidstaker kan varsle eksternt til media eller offentligheten for øvrig dersom
a. arbeidstaker er i aktsom god tro om innholdet i varselet,
b. varselet gjelder kritikkverdige forhold som har allmenn interesse, og
c. arbeidstaker først har varslet internt, eller har grunn til å tro at intern varsling ikke vil være hensiktsmessig.

(4) Arbeidsgiver har bevisbyrden for at varsling har skjedd i strid med §§ 2 A-1 og 2 A-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96832, 'lov/2005-06-17-62', 17, 3, 'kapittel-3-paragraf-3', '§ 2 A-3', 'Arbeidsgivers aktivitetsplikt ved varsling', '(1) Når det er varslet om kritikkverdige forhold i virksomheten, skal arbeidsgiver sørge for at varselet innen rimelig tid blir tilstrekkelig undersøkt.

(2) Arbeidsgiver skal særlig påse at den som har varslet, har et fullt forsvarlig arbeidsmiljø. Dersom det er nødvendig, skal arbeidsgiver sørge for tiltak som er egnet til å forebygge gjengjeldelse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96833, 'lov/2005-06-17-62', 18, 3, 'kapittel-3-paragraf-4', '§ 2 A-4', 'Forbud mot gjengjeldelse', '(1) Gjengjeldelse mot arbeidstaker som varsler i samsvar med §§ 2 A-1 og 2 A-2, er forbudt. Overfor innleide arbeidstakere gjelder forbudet både for arbeidsgiver og innleier.

(2) Med gjengjeldelse menes enhver ugunstig handling, praksis eller unnlatelse som er en følge av eller en reaksjon på at arbeidstaker har varslet, for eksempel
a. trusler, trakassering, usaklig forskjellsbehandling, sosial ekskludering eller annen utilbørlig opptreden
b. advarsel, endring i arbeidsoppgaver, omplassering eller degradering
c. suspensjon, oppsigelse, avskjed eller ordensstraff.

(3) Første ledd gjelder tilsvarende ved gjengjeldelse mot arbeidstaker som gir til kjenne at retten til å varsle vil bli brukt, for eksempel ved å fremskaffe opplysninger.

(4) Dersom arbeidstaker legger frem opplysninger som gir grunn til å tro at det har funnet sted gjengjeldelse, må arbeidsgiver sannsynliggjøre at det likevel ikke har funnet sted slik gjengjeldelse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96834, 'lov/2005-06-17-62', 19, 3, 'kapittel-3-paragraf-5', '§ 2 A-5', 'Oppreisning og erstatning ved brudd på forbudet mot gjengjeldelse', '(1) Arbeidstaker kan ved brudd på forbudet mot gjengjeldelse kreve oppreisning og erstatning uten hensyn til arbeidsgivers eller innleiers skyld.

(2) Oppreisningen skal fastsettes til det som er rimelig ut fra partenes forhold, gjengjeldelsens art og alvorlighetsgrad og omstendighetene for øvrig. Erstatningen skal dekke økonomisk tap som følge av gjengjeldelsen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96835, 'lov/2005-06-17-62', 20, 3, 'kapittel-3-paragraf-6', '§ 2 A-6', 'Plikt til å utarbeide rutiner for intern varsling', '(1) Virksomheter som jevnlig sysselsetter minst fem arbeidstakere, plikter å ha rutiner for intern varsling. Også virksomheter med færre ansatte skal ha slike rutiner dersom forholdene i virksomheten tilsier det.

(2) Rutinene skal utarbeides i tilknytning til virksomhetens systematiske helse-, miljø- og sikkerhetsarbeid, jf. § 3-1, i samarbeid med arbeidstakerne og deres tillitsvalgte.

(3) Rutinene skal ikke begrense arbeidstakers rett til å varsle.

(4) Rutinene skal være skriftlige og minst inneholde
a. en oppfordring til å varsle om kritikkverdige forhold
b. fremgangsmåte for varsling
c. fremgangsmåte for arbeidsgivers saksbehandling ved mottak, behandling og oppfølging av varsling.

(5) Rutinene skal være lett tilgjengelig for alle arbeidstakere i virksomheten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96836, 'lov/2005-06-17-62', 21, 3, 'kapittel-3-paragraf-7', '§ 2 A-7', 'Taushetsplikt ved ekstern varsling til offentlig myndighet', '(1) Når tilsynsmyndigheter eller andre offentlige myndigheter mottar et eksternt varsel om kritikkverdige forhold, plikter enhver som utfører arbeid eller tjeneste for mottakerorganet, å hindre at andre får kjennskap til arbeidstakers navn eller andre identifiserende opplysninger om arbeidstaker.

(2) Taushetsplikten gjelder også overfor sakens parter og deres representanter. Forvaltningsloven §§ 13 til 13 e og 13 g gjelder ellers tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96837, 'lov/2005-06-17-62', 22, 3, 'kapittel-3-paragraf-8', '§ 2 A-8', 'Diskrimineringsnemnda', 'Tvister om brudd på forbudet mot gjengjeldelse etter § 2 A-4 kan bringes inn for Diskrimineringsnemnda. Dette gjelder likevel ikke saker om oppsigelse eller avskjed. De nærmere regler om Diskrimineringsnemndas myndighet og saksbehandling mv. følger av diskrimineringsombudsloven.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96838, 'lov/2005-06-17-62', 23, 4, 'kapittel-4-paragraf-1', '§ 3-1', 'Krav til systematisk helse-, miljø- og sikkerhetsarbeid', '(1) For å sikre at hensynet til arbeidstakers helse, miljø og sikkerhet blir ivaretatt, skal arbeidsgiver sørge for at det utføres systematisk helse-, miljø- og sikkerhetsarbeid på alle plan i virksomheten. Dette skal gjøres i samarbeid med arbeidstakerne og deres tillitsvalgte.

(2) Systematisk helse-, miljø- og sikkerhetsarbeid innebærer at arbeidsgiver skal:
a. fastsette mål for helse, miljø og sikkerhet,
b. ha oversikt over virksomhetens organisasjon, herunder hvordan ansvar, oppgaver og myndighet for arbeidet med helse, miljø og sikkerhet er fordelt,
c. kartlegge farer og problemer og på denne bakgrunn vurdere risikoforholdene i virksomheten, utarbeide planer og iverksette tiltak for å redusere risikoen,
d. under planlegging og gjennomføring av endringer i virksomheten, vurdere om arbeidsmiljøet vil være i samsvar med lovens krav, og iverksette de nødvendige tiltak,
e. iverksette rutiner for å avdekke, rette opp og forebygge overtredelser av krav fastsatt i eller i medhold av denne lov,
f. sørge for systematisk arbeid med forebygging og oppfølging av sykefravær,
g. sørge for løpende kontroll med arbeidsmiljøet og arbeidstakernes helse når risikoforholdene i virksomheten tilsier det, jf. bokstav c,
h. foreta systematisk overvåking og gjennomgang av det systematiske helse-, miljø- og sikkerhetsarbeidet for å sikre at det fungerer som forutsatt.

(3) Departementet kan i forskrift gi nærmere bestemmelser om gjennomføringen av kravene i denne paragraf, herunder om krav til dokumentasjon av det systematiske helse-, miljø- og sikkerhetsarbeidet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96839, 'lov/2005-06-17-62', 24, 4, 'kapittel-4-paragraf-2', '§ 3-2', 'Særskilte forholdsregler for å ivareta sikkerheten', '(1) For å ivareta sikkerheten på arbeidsplassen skal arbeidsgiver sørge for:
a. at arbeidstaker gjøres kjent med ulykkes- og helsefarer som kan være forbundet med arbeidet, og at arbeidstaker får den opplæring, øvelse og instruksjon som er nødvendig,
b. at arbeidstaker som har til oppgave å lede eller kontrollere andre arbeidstakere har nødvendig kompetanse til å føre kontroll med at arbeidet blir utført på en helse- og sikkerhetsmessig forsvarlig måte,
c. sakkyndig bistand når dette er nødvendig for å gjennomføre lovens krav.

(2) Når det ikke på annen måte kan tas forholdsregler for å oppnå tilstrekkelig vern om liv eller helse, skal arbeidsgiver sørge for at tilfredsstillende personlig verneutstyr stilles til arbeidstakers rådighet, at arbeidstaker gis opplæring i bruken av utstyret og at det tas i bruk.

(3) Hvis det skal utføres arbeid som kan innebære særlig fare for liv eller helse, skal det utarbeides en skriftlig instruks om hvordan arbeidet skal utføres og hvilke sikkerhetstiltak som skal iverksettes.

(4) Departementet kan gi forskrift om gjennomføringen av bestemmelsene i denne paragraf. Departementet kan også i forskrift gi nærmere bestemmelser om personlig verneutstyr, herunder om:
a. utforming, merking mv.
b. bruk, vedlikehold mv.
c. prøving, sertifisering og godkjenning
d. godkjenning av organer som skal utøve kontroll knyttet til produksjon av personlig verneutstyr.
Departementet kan i forskrift fastsette at reglene om personlig verneutstyr også skal gjelde for produsent, importør og leverandør.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96840, 'lov/2005-06-17-62', 25, 4, 'kapittel-4-paragraf-3', '§ 3-3', 'Bedriftshelsetjeneste', '(1) Arbeidsgiver plikter å knytte virksomheten til en bedriftshelsetjeneste godkjent av Arbeidstilsynet når risikoforholdene i virksomheten tilsier det. Vurderingen av om slik plikt foreligger skal foretas som ledd i gjennomføringen av det systematiske helse-, miljø- og sikkerhetsarbeidet.

(2) Bedriftshelsetjenesten skal bistå arbeidsgiver, arbeidstakerne, arbeidsmiljøutvalg og verneombud med å skape et trygt arbeidsmiljø som fremmer god arbeidshelse.

(3) Bedriftshelsetjenesten skal ha en fri og uavhengig stilling i arbeidsmiljøspørsmål.

(4) Departementet kan i forskrift gi nærmere bestemmelser om når og i hvilken utstrekning arbeidsgiver plikter å knytte til seg bedriftshelsetjeneste, om hvilke faglige krav som skal stilles til tjenesten og om hvilke oppgaver den skal utføre.

(5) Departementet kan i forskrift gi bestemmelser om at bedriftshelsetjeneste etter denne paragraf må godkjennes av Arbeidstilsynet og om det nærmere innholdet i en slik godkjenningsordning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96841, 'lov/2005-06-17-62', 26, 4, 'kapittel-4-paragraf-4', '§ 3-4', 'Vurdering av tiltak for fysisk aktivitet', 'Arbeidsgiver skal, i tilknytning til det systematiske helse-, miljø- og sikkerhetsarbeidet, vurdere tiltak for å fremme fysisk aktivitet blant arbeidstakerne.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96842, 'lov/2005-06-17-62', 27, 4, 'kapittel-4-paragraf-5', '§ 3-5', 'Plikt for arbeidsgiver til å gjennomgå opplæring i helse-, miljø- og sikkerhetsarbeid', '(1) Arbeidsgiver skal gjennomgå opplæring i helse-, miljø- og sikkerhetsarbeid.

(2) Departementet kan i forskrift gi nærmere krav til opplæringen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96843, 'lov/2005-06-17-62', 28, 4, 'kapittel-4-paragraf-6', '§ 3-6', '(Opphevet)', '', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96844, 'lov/2005-06-17-62', 29, 5, 'kapittel-5-paragraf-1', '§ 4-1', 'Generelle krav til arbeidsmiljøet', '(1) Arbeidsmiljøet i virksomheten skal være fullt forsvarlig ut fra en enkeltvis og samlet vurdering av faktorer i arbeidsmiljøet som kan innvirke på arbeidstakernes fysiske og psykiske helse og velferd. Standarden for sikkerhet, helse og arbeidsmiljø skal til enhver tid utvikles og forbedres i samsvar med utviklingen i samfunnet.

(2) Ved planlegging og utforming av arbeidet skal det legges vekt på å forebygge skader og sykdommer. Arbeidets organisering, tilrettelegging og ledelse, arbeidstidsordninger, lønnssystemer, herunder bruk av prestasjonslønn, teknologi mv. skal være slik at arbeidstakerne ikke utsettes for uheldige fysiske eller psykiske belastninger og slik at sikkerhetshensyn ivaretas.

(3) Det skal vurderes om det er særlig risiko knyttet til alenearbeid i virksomheten. Tiltak som er nødvendig for å forebygge og redusere eventuell risiko ved alenearbeid skal iverksettes, slik at lovens krav til et fullt forsvarlig arbeidsmiljø ivaretas.

(4) Virksomheten skal innrettes for arbeidstakere av begge kjønn.

(5) Atkomstveier, sanitæranlegg, arbeidsutstyr mv. skal så langt det er mulig og rimelig være utformet og innrettet slik at arbeidstakere med nedsatt funksjonsevne kan arbeide i virksomheten.

(6) Departementet kan gi forskrift om begrensning i adgangen til å sysselsette visse grupper arbeidstakere som i særlig grad kan være utsatt for ulykkes- eller helsefare og om omplassering av slike arbeidstakere.

(7) Departementet kan gi forskrift
a. som pålegger bruk av HMS-kort for arbeidstakere innenfor bransjer der det er nødvendig eller hensiktsmessig for å ivareta arbeidstakernes helse, miljø og sikkerhet
b. om oversiktslister over hvem som til enhver tid er sysselsatt på arbeidsplassen
c. om at oppdragsgivere i kontrakt med oppdragstakere skal ta inn kontraktsvilkår som skal sikre at forskrifter om HMS-kort overholdes
d. om at oppdragsgivere skal kontrollere at oppdragstakere overholder forskrifter om HMS-kort
e. om at oppdragstakere skal utlevere den dokumentasjonen som er nødvendig for at en oppdragsgiver kan oppfylle kontrollplikten.
Etter pålegg fra departementet plikter offentlige myndigheter uten hinder av taushetsplikt å gi utsteder av HMS-kort alle opplysninger fra offentlige registre som er nødvendige for utstedelse av HMS-kort.

(8) Når hensynet til helse, miljø og sikkerhet tilsier det, kan departementet i forskrift gi bestemmelser om at virksomheter som tilbyr renholdstjenester eller tjenester i forbindelse med vedlikehold og reparasjon av motorvogn, må godkjennes av Arbeidstilsynet, og om det nærmere innholdet i en slik godkjenningsordning. Når det stilles krav om slik godkjenning, vil det være ulovlig å benytte tjenester fra virksomheter uten godkjenning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96845, 'lov/2005-06-17-62', 30, 5, 'kapittel-5-paragraf-2', '§ 4-2', 'Krav til tilrettelegging, medvirkning og utvikling', '(1) Arbeidstakerne og deres tillitsvalgte skal holdes løpende informert om systemer som nyttes ved planlegging og gjennomføring av arbeidet. De skal gis nødvendig opplæring for å sette seg inn i systemene, og de skal medvirke ved utformingen av dem.

(2) I utformingen av den enkeltes arbeidssituasjon skal:
a. det legges til rette for at arbeidstaker gis mulighet for faglig og personlig utvikling gjennom sitt arbeid,
b. arbeidet organiseres og tilrettelegges under hensyn til den enkelte arbeidstakers arbeidsevne, kyndighet, alder og øvrige forutsetninger,
c. det legges vekt på å gi arbeidstaker mulighet til selvbestemmelse, innflytelse og faglig ansvar,
d. arbeidstaker så langt som mulig gis mulighet til variasjon og for å se sammenheng mellom enkeltoppgaver,
e. det gis tilstrekkelig informasjon og opplæring slik at arbeidstaker er i stand til å utføre arbeidet når det skjer endringer som berører vedkommendes arbeidssituasjon.

(3) Under omstillingsprosesser som medfører endring av betydning for arbeidstakernes arbeidssituasjon, skal arbeidsgiver sørge for den informasjon, medvirkning og kompetanseutvikling som er nødvendig for å ivareta lovens krav til et fullt forsvarlig arbeidsmiljø.

(4) Departementet kan i forskrift gi nærmere bestemmelser om gjennomføringen av kravene i denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96846, 'lov/2005-06-17-62', 31, 5, 'kapittel-5-paragraf-3', '§ 4-3', 'Krav til det psykososiale arbeidsmiljøet', '(1) Arbeidet skal organiseres, planlegges og gjennomføres slik at de psykososiale arbeidsmiljøfaktorene i virksomheten er fullt forsvarlige ut fra hensynet til arbeidstakernes helse, sikkerhet og velferd.

(2) Psykososiale arbeidsmiljøfaktorer er i tillegg til forhold som nevnt i tredje til sjette ledd blant annet
a. uklare eller motstridende krav og forventninger i arbeidet
b. emosjonelle krav og belastninger i arbeid med mennesker
c. arbeidsmengde og tidspress som innebærer ubalanse mellom arbeidet som skal utføres, og den tiden som er til rådighet
d. støtte og hjelp i arbeidet.

(3) Arbeidet skal legges til rette slik at arbeidstakers integritet og verdighet ivaretas.

(4) Arbeidet skal søkes utformet slik at det gir mulighet for kontakt og kommunikasjon med andre arbeidstakere i virksomheten.

(5) Arbeidstaker skal ikke utsettes for trakassering, herunder seksuell trakassering, eller annen utilbørlig opptreden. Med trakassering menes handlinger, unnlatelser eller ytringer som har som formål eller virkning å være krenkende, skremmende, fiendtlige, nedverdigende eller ydmykende. Med seksuell trakassering menes enhver form for uønsket seksuell oppmerksomhet som har som formål eller virkning å være krenkende, skremmende, fiendtlig, nedverdigende, ydmykende eller plagsom.

(6) Arbeidstaker skal, så langt det er mulig, beskyttes mot vold, trusler og uheldige belastninger som følge av kontakt med andre.

(7) Departementet kan i forskrift gi nærmere bestemmelser om gjennomføringen av kravene i denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96847, 'lov/2005-06-17-62', 32, 5, 'kapittel-5-paragraf-4', '§ 4-4', 'Krav til det fysiske arbeidsmiljøet', '(1) Fysiske arbeidsmiljøfaktorer som bygnings- og utstyrsmessige forhold, inneklima, lysforhold, støy, stråling o.l. skal være fullt forsvarlig ut fra hensynet til arbeidstakernes helse, miljø, sikkerhet og velferd.

(2) Arbeidsplassen skal innredes og utformes slik at arbeidstaker unngår uheldige fysiske belastninger. Nødvendige hjelpemidler skal stilles til arbeidstakers disposisjon. Det skal legges til rette for variasjon i arbeidet og for å unngå tunge løft og ensformig gjentakelsesarbeid. Ved oppstilling og bruk av maskiner og annet arbeidsutstyr skal det sørges for at arbeidstaker ikke blir utsatt for uheldige belastninger ved vibrasjon, ubekvem arbeidsstilling o.l.

(3) Maskiner og annet arbeidsutstyr skal være konstruert og ha nødvendige verneinnretninger slik at arbeidstaker er vernet mot skader.

(4) Innkvartering som arbeidsgiver stiller til rådighet for arbeidstaker skal være forsvarlig utført, innredet og vedlikeholdt. Eventuelle husordensregler skal fastsettes i samråd med representanter for arbeidstakerne.

(5) Departementet kan i forskrift gi nærmere bestemmelser om gjennomføringen av kravene i denne paragraf og kan herunder bestemme at reglene skal gjelde for utleiere av lokaler o.l.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96848, 'lov/2005-06-17-62', 33, 5, 'kapittel-5-paragraf-5', '§ 4-5', 'Særlig om kjemisk og biologisk helsefare', '(1) Ved håndtering av kjemikalier eller biologisk materiale skal arbeidsmiljøet være tilrettelagt slik at arbeidstaker er sikret mot ulykker, helseskader og særlig ubehag. Kjemikalier og biologisk materiale skal fremstilles, pakkes, brukes og oppbevares slik at arbeidstaker ikke utsettes for helsefare.

(2) Kjemikalier og biologisk materiale som kan innebære helsefare, skal ikke brukes dersom de kan erstattes med andre eller med en annen prosess som er mindre farlig for arbeidstakerne.

(3) Virksomheten skal ha nødvendige rutiner og utstyr for å hindre eller motvirke helseskader på grunn av kjemikalier eller biologisk materiale.

(4) Virksomheten skal føre kartotek over farlige kjemikalier og biologisk materiale. Kartoteket skal blant annet opplyse om fysikalske, kjemiske og helseskadelige egenskaper, forebyggende vernetiltak og førstehjelpsbehandling. Beholdere og emballasje for kjemikalier og biologisk materiale skal være tydelig merket med navn, sammensetning og advarsel på norsk.

(5) Arbeidstilsynet kan i det enkelte tilfelle helt eller delvis gjøre unntak fra reglene i denne paragraf i forbindelse med forsknings- og analysearbeid e.l.

(6) Departementet kan i forskrift gi nærmere bestemmelser om gjennomføringen av kravene i denne paragraf, og kan herunder bestemme at det skal føres register over arbeidstakere som eksponeres for bestemte kjemikalier eller biologisk materiale.

(7) Departementet kan i forskrift gi nærmere bestemmelser om bruk, registrering, vurdering, godkjennelse, rapportering, informasjon, begrensning og annen behandling av kjemikalier.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96849, 'lov/2005-06-17-62', 34, 5, 'kapittel-5-paragraf-6', '§ 4-6', 'Særlig om tilrettelegging for arbeidstakere med redusert arbeidsevne', '(1) Hvis en arbeidstaker har fått redusert arbeidsevne som følge av ulykke, sykdom, slitasje e.l., skal arbeidsgiver, så langt det er mulig, iverksette nødvendige tiltak for at arbeidstaker skal kunne beholde eller få et passende arbeid. Arbeidstaker skal fortrinnsvis gis anledning til å fortsette i sitt vanlige arbeid, eventuelt etter særskilt tilrettelegging av arbeidet eller arbeidstiden, endringer i arbeidsutstyr, gjennomgått arbeidsrettede tiltak e.l.

(2) Dersom det i medhold av første ledd er aktuelt å overføre en arbeidstaker til annet arbeid, skal arbeidstaker og arbeidstakers tillitsvalgte tas med på råd før saken avgjøres.

(3) Arbeidsgiver skal i samråd med arbeidstaker utarbeide oppfølgingsplan for tilbakeføring til arbeid i forbindelse med ulykke, sykdom, slitasje eller lignende, med mindre dette er åpenbart unødvendig. Arbeidet med oppfølgingsplan skal starte så tidlig som mulig, og planen skal være utarbeidet senest når arbeidstaker har vært helt eller delvis borte fra arbeidet i fire uker. Oppfølgingsplanen skal inneholde en vurdering av arbeidstakers arbeidsoppgaver og arbeidsevne. Planen skal også inneholde aktuelle tiltak i arbeidsgivers regi, aktuelle tiltak med bistand fra myndighetene og plan for videre oppfølging. Arbeidsgiver skal sørge for at planen formidles til sykmelder så snart den er utarbeidet, og senest etter fire uker. Arbeidsgiver skal videre sørge for at oppdatert plan sendes til Arbeids- og velferdsetaten senest en uke før dialogmøter som Arbeids- og velferdsetaten innkaller til, jf. folketrygdloven § 25-2 tredje ledd.

(4) Arbeidsgiver skal innkalle arbeidstaker til dialogmøte om innholdet i oppfølgingsplanen senest innen sju uker etter at arbeidstaker har vært helt borte fra arbeidet som følge av ulykke, sykdom, slitasje eller lignende, med mindre dette er åpenbart unødvendig. For arbeidstaker som av samme årsaker er delvis borte fra arbeidet, skal et slikt møte holdes når arbeidsgiver, arbeidstaker eller sykmelder anser det hensiktsmessig. Dersom både arbeidsgiver og arbeidstaker, eller arbeidstakeren alene, ønsker det, skal sykmelder innkalles til dialogmøtet. Dersom det foreligger ekstraordinære forhold knyttet til sykmelders arbeidssituasjon, kan sykmelder fritas fra plikten til å delta i dialogmøtet. Arbeids- og velferdsetaten, bedriftshelsetjenesten og andre relevante aktører kan innkalles dersom arbeidsgiver eller arbeidstaker ønsker det. Det samme gjelder andre relevante aktører, likevel slik at helsepersonell som behandler eller har behandlet arbeidstaker ikke kan kalles inn dersom arbeidstaker motsetter seg det.

(5) Arbeidsgiver skal kunne dokumentere hvordan bestemmelsene om oppfølgingsplan og dialogmøte har vært fulgt opp, herunder hvem som har vært innkalt til og har deltatt i dialogmøte.

(6) Departementet kan i forskrift gi nærmere bestemmelser om gjennomføringen av kravene i denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96850, 'lov/2005-06-17-62', 35, 6, 'kapittel-6-paragraf-1', '§ 5-1', 'Registrering av skader og sykdommer', '(1) Arbeidsgiver skal sørge for registrering av alle personskader som oppstår under utførelse av arbeid. Det samme gjelder sykdom som antas å ha sin grunn i arbeidet eller forholdene på arbeidsplassen.

(2) Registeret må ikke inneholde medisinske opplysninger av personlig karakter med mindre den opplysningene gjelder har samtykket. Arbeidsgiver har taushetsplikt om opplysninger om personlige forhold i registeret.

(3) Registeret skal være tilgjengelig for Arbeidstilsynet, verneombud, bedriftshelsetjeneste og arbeidsmiljøutvalg.

(4) Arbeidsgiver skal føre statistikk over sykefravær og fravær ved barns sykdom etter nærmere retningslinjer fra Arbeids- og velferdsdirektoratet, jf. folketrygdloven § 25-2 første ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96851, 'lov/2005-06-17-62', 36, 6, 'kapittel-6-paragraf-2', '§ 5-2', 'Arbeidsgivers varslings- og meldeplikt', '(1) Dersom arbeidstaker omkommer eller blir alvorlig skadet ved en arbeidsulykke, skal arbeidsgiver straks og på hurtigste måte varsle Arbeidstilsynet og nærmeste politimyndighet. Arbeidsgiver skal bekrefte varselet skriftlig. Verneombudet skal ha kopi av bekreftelsen.

(2) Departementet kan gi forskrift om at slikt varsel skal gis også i andre tilfeller.

(3) Departementet kan gi forskrift om at arbeidsgiver skal gi melding til Arbeidstilsynet om:
a. arbeidsulykke som det ikke kreves varsel om etter første eller andre ledd, herunder akutt forgiftning, og tilløp til slike ulykker,
b. sykdom som er eller kan være forårsaket av arbeidet eller forholdene på arbeidsplassen.

(4) Departementet kan i forskrift gi nærmere bestemmelser om omfanget og gjennomføringen av varslings- og meldeplikten etter denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96852, 'lov/2005-06-17-62', 37, 6, 'kapittel-6-paragraf-3', '§ 5-3', 'Leges meldeplikt', '(1) Enhver lege som gjennom sitt arbeid får kunnskap om at arbeidstaker lider av en yrkessykdom som er likestilt med yrkesskade etter folketrygdloven § 13-4, eller annen sykdom som legen antar skyldes arbeidstakers arbeidssituasjon, skal gi skriftlig melding om det til Arbeidstilsynet.

(2) Dersom arbeidstaker gir sitt samtykke, skal arbeidsgiver underrettes om sykdommen.

(3) Departementet kan i forskrift gi nærmere bestemmelser om omfanget og gjennomføringen av meldeplikten, herunder at den skal omfatte nærmere angitte sykdommer som kan antas å skyldes arbeidets art eller forholdene på arbeidsplassen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96853, 'lov/2005-06-17-62', 38, 6, 'kapittel-6-paragraf-4', '§ 5-4', 'Produsenter og importører av kjemikalier og biologisk materiale', '(1) Den som produserer eller importerer kjemikalier eller biologisk materiale som skal brukes eller ventelig vil bli brukt i virksomhet som går inn under denne lov, skal:
a. skaffe til veie opplysninger om kjemikaliets eller materialets sammensetning og egenskaper,
b. treffe de tiltak som er nødvendige for å forebygge ulykker og helseskader eller særlig ubehag eller ulempe for arbeidstakerne,
c. gi melding til den departementet bestemmer om kjemikaliets eller materialets navn, sammensetning, fysikalske og kjemiske egenskaper, samt supplerende opplysninger som måtte kreves for å fastslå stoffets farlighetsgrad,
d. sørge for forsvarlig emballasje slik at ulykker og helseskader forebygges,
e. merke emballasjen med kjemikaliets eller materialets navn, produsentens eller importørens navn og tydelig advarsel på norsk. Etikett for merking skal sendes sammen med melding etter bokstav c.

(2) Unntatt fra meldeplikt og merkeplikt etter disse bestemmelser er næringsmidler og stoffer som går inn under matloven samt legemidler.

(3) Departementet kan i forskrift gi nærmere bestemmelser om produsenters og importørers plikter etter denne paragraf, herunder om unntak i tilfeller hvor importører anvender de importerte kjemikalier eller biologisk materiale. Departementet kan i forskrift fastsette at bestemmelsene i eller i medhold av denne paragraf helt eller delvis skal gjelde for forhandlere, eller at produsentens eller importørens plikter etter paragrafen her i stedet skal påligge forhandleren.

(4) Departementet kan i forskrift gi nærmere bestemmelser om fremstilling, import, registrering, vurdering, godkjennelse, rapportering, informasjon, begrensning og annen behandling av kjemikalier.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96854, 'lov/2005-06-17-62', 39, 6, 'kapittel-6-paragraf-5', '§ 5-5', 'Produsenter, leverandører og importører av maskiner og annet arbeidsutstyr', '(1) Den som produserer, importerer, selger, leier eller låner ut maskiner og annet arbeidsutstyr som skal brukes eller ventelig vil bli brukt i virksomhet som går inn under loven, skal før arbeidsutstyret leveres til bruk, sørge for at det er konstruert og forsynt med verneinnretninger i samsvar med lovens krav.

(2) Maskiner og annet arbeidsutstyr som utstilles i salgs- eller reklameøyemed, eller framvises for demonstrasjonsformål, og som ikke er forsynt med nødvendige verneinnretninger, skal synlig skiltes med opplysninger om at arbeidsutstyret ikke oppfyller kravene fastsatt i eller i medhold av denne lov og ikke kan leveres til bruk før produsenten, leverandøren eller importøren har sørget for at kravene er oppfylt. Ved demonstrasjoner skal det treffes nødvendige tiltak for å forebygge at personer, dyr og eiendom utsettes for fare.

(3) Ved konstruksjon av maskiner og annet arbeidsutstyr som nevnt i denne paragraf, skal det påses at det kan brukes etter sin hensikt uten å medføre særlige ulemper eller ubehag.

(4) Med maskiner og annet arbeidsutstyr som nevnt i første ledd skal det følge nødvendig og lett forståelig skriftlig bruksanvisning på norsk om transport, oppstilling, betjening og vedlikehold.

(5) Den som påtar seg å montere maskiner og annet arbeidsutstyr som nevnt i denne paragraf, skal sørge for at de blir satt i stand og stilt opp i samsvar med lovens krav.

(6) Maskiner og annet arbeidsutstyr som nevnt i første ledd skal, før det overdras eller utstilles, være forsynt med produsentens eller importørens navn og adresse, eller med annen merking som gjør det lett å identifisere produsenten eller importøren.

(7) Departementet kan i forskrift gi nærmere bestemmelser om maskiner og annet arbeidsutstyr, herunder om:
a. konstruksjon, utførelse, oppstilling, merking mv.,
b. godkjenning og plikt til å gi opplysninger i forbindelse med dette,
c. godkjenning av organer som skal utøve kontroll knyttet til produksjon,
d. undersøkelse eller besiktigelse.

(8) Utgifter til undersøkelse eller besiktigelse som pålegges i medhold av sjuende ledd, bæres av den som har plikt til å foreta undersøkelsen eller besiktigelsen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96855, 'lov/2005-06-17-62', 40, 7, 'kapittel-7-paragraf-1', '§ 6-1', 'Plikt til å velge verneombud', '(1) Ved hver virksomhet som går inn under loven, skal det velges verneombud. Ved virksomhet med færre enn 5 arbeidstakere kan partene skriftlig avtale en annen ordning, herunder at det ikke skal være verneombud ved virksomheten. Hvis ikke annet er fastsatt om tiden for avtalens gyldighet, anses den som sluttet for 2 år, regnet fra den dagen den ble underskrevet. Arbeidstilsynet kan, etter en konkret vurdering av forholdene i virksomheten, fastsette at den likevel skal ha verneombud. Ved virksomhet med flere enn 10 arbeidstakere kan det velges flere verneombud.

(2) Antallet verneombud fastsettes i forhold til virksomhetens størrelse, arbeidets art og arbeidsforholdene for øvrig. Dersom virksomheten består av flere atskilte avdelinger, eller arbeidet foregår på skift, skal det i alminnelighet velges minst ett verneombud for hver avdeling eller hvert skiftlag. Hvert verneområde skal være klart avgrenset og må ikke være større enn at verneombudet kan ha full oversikt og ivareta sine oppgaver på forsvarlig måte.

(3) Virksomhet med mer enn ett verneombud skal ha minst ett hovedverneombud, som har ansvar for å samordne verneombudets virksomhet. Hovedverneombudet skal velges blant verneombudene eller andre som har eller har hatt tillitsverv ved virksomheten.

(4) Hvem som til enhver tid fungerer som verneombud ved virksomheten, skal kunngjøres ved oppslag på arbeidsplassen.

(5) Departementet kan gi forskrift med nærmere regler om antall verneombud, om valg, herunder om vilkår for stemmerett og valgbarhet, om lokal fagforenings rett til å utpeke verneombud, og om verneombudets funksjonstid.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96856, 'lov/2005-06-17-62', 41, 7, 'kapittel-7-paragraf-2', '§ 6-2', 'Verneombudets oppgaver', '(1) Verneombudet skal ivareta arbeidstakernes interesser i saker som angår arbeidsmiljøet. Verneombudet skal se til at virksomheten er innrettet og vedlikeholdt, og at arbeidet blir utført på en slik måte at hensynet til arbeidstakernes sikkerhet, helse og velferd er ivaretatt i samsvar med bestemmelsene i denne lov. Første og andre punktum gjelder tilsvarende for innleide arbeidstakere og for selvstendige oppdragstakere som utfører arbeid i nær tilknytning til virksomheten.

(2) Verneombudet skal særlig påse:
a. at maskiner, tekniske innretninger, kjemiske stoffer og arbeidsprosesser ikke utsetter arbeidstakerne for fare,
b. at verneinnretninger og personlig verneutstyr er til stede i passende antall, at det er lett tilgjengelig og i forsvarlig stand,
c. at arbeidstakerne får den nødvendige instruksjon, øvelse og opplæring,
d. at arbeidet ellers er tilrettelagt slik at arbeidstakerne kan utføre arbeidet på helse- og sikkerhetsmessig forsvarlig måte,
e. at meldinger om arbeidsulykker mv. i henhold til § 5-2 blir sendt,
f. at arbeidstakernes psykososiale arbeidsmiljø er ivaretatt.

(3) Blir et verneombud kjent med forhold som kan medføre ulykkes- og helsefare, skal verneombudet straks varsle arbeidstakerne på stedet, og arbeidsgiveren eller dennes representant skal gjøres oppmerksom på forholdet dersom verneombudet selv ikke kan avverge faren. Arbeidsgiveren skal gi verneombudet svar på henvendelsen. Er det ikke innen rimelig tid tatt hensyn til meldingen, skal verneombudet underrette Arbeidstilsynet eller arbeidsmiljøutvalget.

(4) Verneombudet skal tas med på råd under planlegging og gjennomføring av tiltak som har betydning for arbeidsmiljøet innenfor ombudets verneområde, herunder etablering, utøvelse og vedlikehold av virksomhetens systematiske helse-, miljø- og sikkerhetsarbeid, jf. § 3-1.

(5) Verneombudet skal gjøres kjent med alle yrkessykdommer, arbeidsulykker og tilløp til ulykker innenfor sitt område, om yrkeshygieniske rapporter og målinger, og om eventuelle feil og mangler som er påvist.

(6) Verneombudet skal gjøre seg kjent med gjeldende verneregler, instrukser, pålegg og henstillinger som er gitt av Arbeidstilsynet eller arbeidsgiveren.

(7) Verneombudet skal delta ved Arbeidstilsynets inspeksjoner i virksomheten.

(8) Departementet kan i forskrift gi nærmere regler om verneombudets virksomhet, og om ombudets taushetsplikt. I reglene kan fastsettes at verneombudet skal utføre oppgaver som er tillagt arbeidsmiljøutvalget i henhold til § 7-2, når virksomheten ikke har slikt utvalg. Myndigheten til å treffe vedtak etter § 7-2 fjerde ledd tredje punktum og femte ledd, kan ikke tillegges verneombudet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96857, 'lov/2005-06-17-62', 42, 7, 'kapittel-7-paragraf-3', '§ 6-3', 'Verneombudets rett til å stanse farlig arbeid', '(1) Dersom verneombudet mener at det foreligger umiddelbar fare for arbeidstakernes liv eller helse, og faren ikke straks kan avverges på annen måte, kan arbeidet stanses inntil Arbeidstilsynet har tatt stilling til om arbeidet kan fortsette. Arbeidet må bare stanses i det omfang verneombudet anser det nødvendig for å avverge fare.

(2) Stansingen og grunnen til den skal omgående meldes til arbeidsgiveren eller dennes representant.

(3) Verneombudet er ikke erstatningsansvarlig for skade som påføres virksomheten som følge av at arbeidet stanses i henhold til bestemmelsen i første ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96858, 'lov/2005-06-17-62', 43, 7, 'kapittel-7-paragraf-4', '§ 6-4', 'Særskilte lokale eller regionale verneombud', '(1) Innenfor bygge- og anleggsvirksomhet, ved laste- og lossearbeid og ellers når særlige forhold gjør det nødvendig, kan departementet gi forskrift om at det skal være særskilte lokale verneombud. Slike verneombud kan få oppgaver, plikter og rettigheter som nevnt i §§ 6-2 og 6-3 overfor arbeidsgivere på arbeidsplassen.

(2) Departementet kan gi forskrift om at det skal være regionale verneombudsordninger som skal omfatte flere virksomheter innenfor ett geografisk område.

(3) Forskrifter etter denne paragraf kan omfatte regler om hvordan verneombudene oppnevnes, hvilke oppgaver de skal ha, og hvordan utgiftene ved deres virksomhet skal fordeles.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96859, 'lov/2005-06-17-62', 44, 7, 'kapittel-7-paragraf-5', '§ 6-5', 'Utgifter, opplæring mv.', '(1) Arbeidsgiver skal sørge for at verneombud får den opplæring som er nødvendig for å kunne utføre vervet på forsvarlig måte. Verneombud har rett til å ta den nødvendige opplæring ved kurs som arbeidstakernes organisasjoner arrangerer. Departementet kan i forskrift stille nærmere krav til opplæringen.

(2) Verneombud skal få nødvendig tid til å utføre vernearbeidet på forsvarlig måte. I alminnelighet skal oppgavene utføres innenfor vanlig arbeidstid.

(3) Arbeidsgiver er ansvarlig for utgifter til opplæring, og andre utgifter i forbindelse med verneombudets arbeid. Vernearbeid som må utføres ut over den alminnelige arbeidstid etter § 10-4, godtgjøres som for overtidsarbeid.

(4) Arbeidsgiver skal sørge for at verv som verneombud ikke medfører inntektstap for verneombudet eller på annen måte fører til at verneombudets arbeids- eller ansettelsesvilkår forringes.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96860, 'lov/2005-06-17-62', 45, 8, 'kapittel-8-paragraf-1', '§ 7-1', 'Plikt til å opprette arbeidsmiljøutvalg', '(1) I virksomhet hvor det jevnlig sysselsettes minst 30 arbeidstakere, skal det være arbeidsmiljøutvalg, der arbeidsgiveren, arbeidstakerne og bedriftshelsetjenesten er representert. Arbeidsmiljøutvalg skal opprettes også i virksomhet med mellom 10 og 30 arbeidstakere, når en av partene ved virksomheten krever det. Der arbeidsforholdene tilsier det, kan Arbeidstilsynet bestemme at det skal opprettes arbeidsmiljøutvalg i virksomhet med færre enn 30 arbeidstakere.

(2) Arbeidsmiljøutvalget kan opprette underutvalg.

(3) Hvilke personer som til enhver tid er medlemmer av utvalget skal kunngjøres ved oppslag på arbeidsplassen.

(4) Arbeidsgiveren og arbeidstakerne skal ha like mange representanter i utvalget. Lederen for utvalget velges vekselvis av arbeidsgiverens og arbeidstakernes representanter. Representantene for bedriftshelsetjenesten har ikke stemmerett i utvalget. Ved stemmelikhet gjør lederens stemme utslaget.

(5) Departementet kan gi forskrift med nærmere regler om arbeidsmiljøutvalget, herunder om sammensetning, valg og funksjonstid. Departementet kan gi regler om at andre samarbeidsorgan i virksomheten, på nærmere vilkår, kan fungere som arbeidsmiljøutvalg.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96861, 'lov/2005-06-17-62', 46, 8, 'kapittel-8-paragraf-2', '§ 7-2', 'Arbeidsmiljøutvalgets oppgaver', '(1) Arbeidsmiljøutvalget skal virke for gjennomføring av et fullt forsvarlig arbeidsmiljø i virksomheten. Utvalget skal delta i planleggingen av verne- og miljøarbeidet, og nøye følge utviklingen i spørsmål som angår arbeidstakernes sikkerhet, helse og velferd.

(2) Arbeidsmiljøutvalget skal behandle:
a. spørsmål som angår bedriftshelsetjeneste og den interne vernetjeneste,
b. spørsmål om opplæring, instruksjon og opplysningsvirksomhet i virksomheten, som har betydning for arbeidsmiljøet,
c. planer som krever Arbeidstilsynets samtykke i henhold til § 18-9,
d. andre planer som kan få vesentlig betydning for arbeidsmiljøet, så som planer om byggearbeider, innkjøp av maskiner, rasjonalisering, arbeidsprosesser, og forebyggende vernetiltak,
e. etablering og vedlikehold av virksomhetens systematiske helse-, miljø- og sikkerhetsarbeid, jf. § 3-1,
f. helse- og velferdsmessige spørsmål knyttet til arbeidstidsordninger.

(3) Utvalget kan også behandle spørsmål om arbeidstakere med redusert arbeidsevne, jf. § 4-6.

(4) Utvalget skal gjennomgå alle rapporter om yrkessykdommer, arbeidsulykker og tilløp til ulykker, søke å finne årsaken til ulykken eller sykdommen, og se til at arbeidsgiveren treffer tiltak for å hindre gjentakelse. Utvalget skal i alminnelighet ha adgang til Arbeidstilsynets og politiets etterforskningsdokumenter. Når utvalget finner det nødvendig, kan det vedta at undersøkelser skal foretas av sakkyndige eller granskingskommisjon som utvalget oppnevner. Arbeidsgiveren kan uten ugrunnet opphold forelegge vedtaket for Arbeidstilsynet til avgjørelse. Utvalget skal gjennomgå alle rapporter om yrkeshygieniske undersøkelser og måleresultater. Før utvalget behandler rapporter som nevnt i dette ledd, skal medisinske opplysninger av personlig karakter tas ut av rapportene, med mindre den opplysningen gjelder, samtykker i at de legges fram for utvalget.

(5) Hvis arbeidsmiljøutvalget finner det påkrevet for å verne arbeidstakernes liv eller helse, kan utvalget vedta at arbeidsgiveren skal gjennomføre konkrete tiltak til utbedring av arbeidsmiljøet, innenfor rammen av bestemmelsene gitt i eller i medhold av denne lov. For å klarlegge om det foreligger helsefare, kan utvalget også vedta at arbeidsgiveren skal utføre målinger eller undersøkelser av arbeidsmiljøet. Utvalget skal sette en tidsfrist for gjennomføringen av vedtaket. Hvis arbeidsgiveren ikke finner å kunne gjennomføre utvalgets vedtak, skal spørsmålet uten ugrunnet opphold forelegges for Arbeidstilsynet til avgjørelse.

(6) Arbeidsmiljøutvalget skal hvert år avgi rapport om sin virksomhet til virksomhetens styrende organer og arbeidstakernes organisasjoner. Direktoratet for arbeidstilsynet kan gi nærmere regler om årsrapportens innhold og utforming.

(7) Departementet kan gi forskrift med nærmere regler om utvalgets virksomhet, herunder regler om saksbehandlingen og om taushetsplikt for utvalgets medlemmer.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96862, 'lov/2005-06-17-62', 47, 8, 'kapittel-8-paragraf-3', '§ 7-3', 'Særskilte lokale arbeidsmiljøutvalg', '(1) Innenfor bygge- og anleggsvirksomhet, ved laste- og lossearbeid og ellers når særlige forhold gjør det nødvendig, kan departementet gi forskrift om at det skal være særskilte lokale arbeidsmiljøutvalg. Slike utvalg kan få oppgaver, plikter og rettigheter som nevnt i §§ 7-1 og 7-3 overfor alle arbeidsgivere på arbeidsplassen.

(2) Forskrifter etter denne paragraf kan omfatte regler om hvordan arbeidsmiljøutvalgene oppnevnes, hvilke oppgaver de skal ha og hvordan utgiftene ved deres virksomhet fordeles.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96863, 'lov/2005-06-17-62', 48, 8, 'kapittel-8-paragraf-4', '§ 7-4', 'Utgifter, opplæring mv.', 'Reglene i § 6-5 gjelder tilsvarende for medlemmer av arbeidsmiljøutvalg.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96864, 'lov/2005-06-17-62', 49, 9, 'kapittel-9-paragraf-1', '§ 8-1', 'Plikt til informasjon og drøfting', '(1) I virksomhet som jevnlig sysselsetter minst 50 arbeidstakere skal arbeidsgiver informere om og drøfte spørsmål av betydning for arbeidstakernes arbeidsforhold med arbeidstakernes tillitsvalgte.

(2) Departementet kan gi forskrift om beregningen av antall arbeidstakere i virksomheten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96865, 'lov/2005-06-17-62', 50, 9, 'kapittel-9-paragraf-2', '§ 8-2', 'Gjennomføring av plikten til informasjon og drøfting', '(1) Plikten til informasjon og drøfting etter § 8-1 omfatter:
a. informasjon om den aktuelle og forventede utvikling av virksomhetens aktiviteter og økonomiske situasjon,
b. informasjon om og drøfting av den aktuelle og forventede bemanningssituasjon i virksomheten, inkludert eventuelle innskrenkninger og de tiltak arbeidsgiver vurderer i den forbindelse,
c. informasjon om og drøfting av beslutninger som kan føre til vesentlig endring i arbeidsorganisering eller ansettelsesforhold.

(2) Informasjon etter første ledd bokstav a skal skje på et passende tidspunkt. Informasjon og drøfting etter første ledd bokstavene b og c skal skje så tidlig som mulig.

(3) Informasjonen skal gis slik at det er mulig for de tillitsvalgte å sette seg inn i saken, foreta en passende undersøkelse, vurdere saken og forberede eventuell drøfting. Drøftingen skal bygge på informasjon fra arbeidsgiver, finne sted på det nivå for ledelse og representasjon som saken tilsier og skje på en måte og med et innhold som er passende. Drøftingen skal gjennomføres slik at det er mulig for de tillitsvalgte å møte arbeidsgiveren og få et grunngitt svar på uttalelser de måtte avgi. Drøfting etter første ledd bokstav c skal ta sikte på å oppnå en avtale.

(4) Bestemmelsene i denne paragraf kan fravikes ved tariffavtale.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96866, 'lov/2005-06-17-62', 51, 9, 'kapittel-9-paragraf-3', '§ 8-3', 'Fortrolige opplysninger', '(1) Dersom virksomhetens behov tilsier at bestemte opplysninger ikke bør gis videre, kan arbeidsgiver pålegge tillitsvalgte og eventuelle rådgivere taushetsplikt. Taushetsplikten gjelder også etter utløpet av vedkommendes mandatperiode.

(2) Arbeidsgiver kan i særlige tilfeller unnlate å gi informasjon eller gjennomføre drøfting dersom dette på det aktuelle tidspunkt åpenbart vil være til betydelig skade for virksomheten.

(3) Virksomhetens tillitsvalgte eller en femdel av arbeidstakerne kan bringe tvist om arbeidsgivers beslutning etter første og andre ledd inn for tvisteløsningsnemnda, jf. § 17-2. Tvist kan ikke bringes inn etter at opplysningene beslutningen gjelder er blitt offentlig kjent. Departementet kan i forskrift gi nærmere bestemmelser om nemndas myndighet og saksbehandling i tvister etter denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96867, 'lov/2005-06-17-62', 52, 9, 'kapittel-9-paragraf-4', '§ 8-4', 'Informasjon og drøfting i konsern', '(1) I konsern med virksomheter som til sammen jevnlig sysselsetter minst 50 arbeidstakere, skal morforetaket etablere rammer for samarbeid, informasjon og drøfting mellom foretakene i konsernet og arbeidstakerne i konsernet. Samarbeidsformen skal etableres i samråd med et flertall av arbeidstakerne i konsernet, eller en eller flere lokale fagforeninger som representerer et flertall av arbeidstakerne i konsernet. Det kan etableres et samarbeidsorgan eller en annen tilsvarende samarbeidsform.

(2) Hvis planer om utvidelser, innskrenkninger eller omlegginger kan få vesentlig betydning for sysselsettingen i flere virksomheter i konsernet, skal det så tidlig som mulig informeres og drøftes med samarbeidsorganet etter første ledd.

(3) Første ledd andre og tredje punktum og andre ledd kan fravikes i tariffavtale.

(4) Med konsern menes etter denne paragrafen et morforetak og ett eller flere datterforetak. Et foretak er et morforetak dersom det på grunn av avtale eller gjennom eierskap har bestemmende innflytelse over et annet foretak. Et foretak skal alltid anses å ha bestemmende innflytelse hvis det
a. eier så mange aksjer eller andeler i et annet foretak at de representerer flertallet av de stemmene som kan avgis på generalforsamlingen eller tilsvarende organ, eller
b. har rett til å velge eller avsette mer enn halvparten av medlemmene i det andre foretakets styre.
Et foretak som et morforetak har slik bestemmende innflytelse over, anses som et datterforetak. Ved beregning av stemmerettigheter og rettigheter til å velge eller avsette styremedlemmer skal rettigheter som morforetaket og morforetakets datterforetak innehar, regnes med. Det samme gjelder rettigheter som innehas av noen som handler i eget navn, men for morforetakets eller et datterforetaks regning. Kommuner, fylkeskommuner, stiftelser og foreninger kan være morforetak etter denne paragrafen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96868, 'lov/2005-06-17-62', 53, 10, 'kapittel-10-paragraf-1', '§ 9-1', 'Vilkår for kontrolltiltak i virksomheten', '(1) Arbeidsgiver kan bare iverksette kontrolltiltak overfor arbeidstaker når tiltaket har saklig grunn i virksomhetens forhold og det ikke innebærer en uforholdsmessig belastning for arbeidstakeren.

(2) Personopplysningsloven gjelder for arbeidsgivers behandling av opplysninger om arbeidstakere i forbindelse med kontrolltiltak med mindre annet er fastsatt i denne eller annen lov.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96869, 'lov/2005-06-17-62', 54, 10, 'kapittel-10-paragraf-2', '§ 9-2', 'Drøfting, informasjon og evaluering av kontrolltiltak', '(1) Arbeidsgiver plikter så tidlig som mulig å drøfte behov, utforming, gjennomføring og vesentlig endring av kontrolltiltak i virksomheten med arbeidstakernes tillitsvalgte.

(2) Før tiltaket iverksettes, skal arbeidsgiver gi de berørte arbeidstakerne informasjon om:
a. formålet med kontrolltiltaket,
b. praktiske konsekvenser av kontrolltiltaket, herunder hvordan kontrolltiltaket vil bli gjennomført,
c. kontrolltiltakets antatte varighet.

(3) Arbeidsgiver skal sammen med arbeidstakernes tillitsvalgte jevnlig evaluere behovet for de kontrolltiltak som iverksettes.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96870, 'lov/2005-06-17-62', 55, 10, 'kapittel-10-paragraf-3', '§ 9-3', 'Innhenting av helseopplysninger ved ansettelse', '(1) Arbeidsgiver må ikke i utlysningen etter nye arbeidstakere eller på annen måte be om at søkerne skal gi andre helseopplysninger enn dem som er nødvendige for å utføre de arbeidsoppgaver som knytter seg til stillingen. Arbeidsgiver må heller ikke iverksette tiltak for å innhente helseopplysninger på annen måte.

(2) Departementet kan i forskrift gi nærmere bestemmelser om hvilke opplysninger som kan innhentes etter denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96871, 'lov/2005-06-17-62', 56, 10, 'kapittel-10-paragraf-4', '§ 9-4', 'Medisinske undersøkelser av arbeidssøkere og arbeidstakere', '(1) Arbeidsgiver kan bare kreve at medisinske undersøkelser skal foretas:
a. når det følger av lov eller forskrift,
b. ved stillinger som innebærer særlig risiko,
c. når arbeidsgiver finner det nødvendig for å verne liv eller helse.

(2) Departementet kan gi forskrift om vilkårene for å kreve medisinske undersøkelser etter denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96872, 'lov/2005-06-17-62', 57, 10, 'kapittel-10-paragraf-5', '§ 9-5', 'Innsyn i arbeidstakers e-postkasse mv.', 'Departementet kan gi forskrift om arbeidsgivers rett til innsyn i arbeidstakers e-postkasse og annet elektronisk lagret materiale, blant annet om adgangen til innsyn, prosedyrer ved innsyn og plikten til å slette opplysninger.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96873, 'lov/2005-06-17-62', 58, 10, 'kapittel-10-paragraf-6', '§ 9-6', 'Kameraovervåking', 'Departementet kan gi forskrift om kameraovervåking i virksomheten, blant annet om adgangen til å iverksette kameraovervåking, varsling om at slik overvåking finner sted, og utlevering og sletting av opptak gjort ved slik overvåking.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96874, 'lov/2005-06-17-62', 59, 11, 'kapittel-11-paragraf-1', '§ 10-1', 'Definisjoner', '(1) Med arbeidstid menes den tid arbeidstaker står til disposisjon for arbeidsgiver.

(2) Med arbeidsfri menes den tid arbeidstaker ikke står til disposisjon for arbeidsgiver.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96875, 'lov/2005-06-17-62', 60, 11, 'kapittel-11-paragraf-2', '§ 10-2', 'Arbeidstidsordninger', '(1) Arbeidstidsordninger skal være slik at arbeidstakerne ikke utsettes for uheldige fysiske eller psykiske belastninger, og slik at det er mulig å ivareta sikkerhetshensyn.

(2) Arbeidstaker som regelmessig arbeider om natten har rett til fritak fra den arbeidstidsordning som gjelder for arbeidstakergruppen, dersom vedkommende av helsemessige, sosiale eller andre vektige velferdsgrunner har behov for det og fritaket kan gjennomføres uten vesentlig ulempe for virksomheten.

(3) Arbeidstaker har rett til fleksibel arbeidstid dersom dette kan gjennomføres uten vesentlig ulempe for virksomheten.

(4) Arbeidstaker som har fylt 62 år eller som av helsemessige, sosiale eller andre vektige velferdsgrunner har behov for det, har rett til å få redusert sin arbeidstid dersom arbeidstidsreduksjonen kan gjennomføres uten vesentlig ulempe for virksomheten. Når avtalt periode med redusert arbeidstid er over, har arbeidstaker rett til å gå tilbake til tidligere arbeidstid. Under ellers like forhold har arbeidstaker med redusert arbeidstid fortrinnsrett til å øke sin arbeidstid når stilling blir ledig i virksomheten, forutsatt at stillingen helt eller i det vesentlige er tillagt de samme arbeidsoppgavene. Fortrinnsrett etter §§ 14-2 og 14-3 går foran fortrinnsrett etter bestemmelsen her.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96876, 'lov/2005-06-17-62', 61, 11, 'kapittel-11-paragraf-3', '§ 10-3', 'Arbeidsplan', 'Dersom arbeidstakerne arbeider til ulike tider på døgnet, skal det utarbeides en arbeidsplan som viser hvilke uker, dager og tider den enkelte arbeidstaker skal arbeide. Arbeidsplanen skal utarbeides i samarbeid med arbeidstakernes tillitsvalgte. Dersom ikke annet fremgår av tariffavtale, skal arbeidsplanen drøftes med arbeidstakernes tillitsvalgte så tidlig som mulig og senest to uker før iverksettelsen. Arbeidsplanen skal være lett tilgjengelig for arbeidstakerne.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96877, 'lov/2005-06-17-62', 62, 11, 'kapittel-11-paragraf-4', '§ 10-4', 'Alminnelig arbeidstid', '(1) Den alminnelige arbeidstid må ikke overstige ni timer i løpet av 24 timer og 40 timer i løpet av sju dager.

(2) For arbeid som helt eller i det vesentlige er av passiv karakter, kan arbeidstiden forlenges med inntil halvparten av de passive periodene, men ikke med mer enn to timer i løpet av 24 timer og ti timer i løpet av sju dager. Arbeidstilsynet kan når arbeidet er særlig passivt, gi samtykke til at arbeidstiden forlenges utover det som er fastsatt i første punktum, men slik at arbeidstiden ikke overstiger 13 timer i løpet av 24 timer. Den alminnelige arbeidstiden må ikke overstige 48 timer i løpet av sju dager.

(3) For beredskapsvakt utenfor arbeidsstedet skal som hovedregel minst 1/7 av vakten regnes med i den alminnelige arbeidstid, avhengig av hvor belastende vaktordningen er. Arbeidsgiver og arbeidstakernes tillitsvalgte i virksomhet som er bundet av tariffavtale, kan ved skriftlig avtale fravike bestemmelsen i første punktum. Arbeidstilsynet kan etter krav fra arbeidsgiver eller arbeidstakernes tillitsvalgte fastsette en annen beregningsmåte dersom beregningen av arbeidstiden etter første punktum vil virke urimelig.

(4) Den alminnelige arbeidstid må ikke overstige ni timer i løpet av 24 timer og 38 timer i løpet av sju dager for:
a. døgnkontinuerlig skiftarbeid og sammenlignbart turnusarbeid,
b. arbeid på to skift som regelmessig drives på søn- og helgedager, og sammenlignbart turnusarbeid som regelmessig drives på søn- og helgedager,
c. arbeid som innebærer at den enkelte arbeidstaker må arbeide minst hver tredje søndag,
d. arbeid som hovedsakelig drives om natten.

(5) Den alminnelige arbeidstid må ikke overstige ni timer i løpet av 24 timer og 36 timer i løpet av sju dager for:
a. helkontinuerlig skiftarbeid og sammenlignbart turnusarbeid,
b. arbeid under jord i gruver, tunneldrift og utsprengning av bergrom under jord.

(6) For tredelt skift- og turnusarbeid som ikke faller inn under fjerde eller femte ledd og som innebærer at den enkelte arbeidstaker må arbeide minst hver tredje søndag, reduseres den alminnelige arbeidstiden etter første ledd ved at hver time arbeidet på søn- og helgedag, jf. § 10-10 første ledd, regnes lik 1 time og 10 minutter, og hver time arbeidet om natten, jf. § 10-11 første ledd, regnes lik 1 time og 15 minutter, ned til 36 timer i løpet av sju dager. Den alminnelige arbeidstid må uansett ikke overstige ni timer i løpet av 24 timer og 38 timer i løpet av sju dager.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96878, 'lov/2005-06-17-62', 63, 11, 'kapittel-11-paragraf-5', '§ 10-5', 'Gjennomsnittsberegning av den alminnelige arbeidstid', '(1) Arbeidsgiver og arbeidstaker kan skriftlig avtale at den alminnelige arbeidstid kan ordnes slik at den i løpet av en periode på høyst 52 uker i gjennomsnitt ikke blir lenger enn foreskrevet i § 10-4, men slik at den alminnelige arbeidstiden ikke overstiger ti timer i løpet av 24 timer og 48 timer i løpet av sju dager. Grensen på 48 timer i løpet av sju dager kan gjennomsnittsberegnes over en periode på åtte uker, likevel slik at den alminnelige arbeidstiden ikke overstiger 50 timer i noen enkelt uke.

(2) Arbeidsgiver og arbeidstakernes tillitsvalgte i virksomhet som er bundet av tariffavtale, kan skriftlig avtale at den alminnelige arbeidstiden skal ordnes slik at den i løpet av en periode på høyst 52 uker i gjennomsnitt ikke blir lenger enn foreskrevet i § 10-4, men slik at den alminnelige arbeidstiden ikke overstiger 12,5 timer i løpet av 24 timer og 48 timer i løpet av sju dager. Grensen på 48 timer i løpet av sju dager kan gjennomsnittsberegnes over en periode på åtte uker, likevel slik at den alminnelige arbeidstiden ikke overstiger 54 timer i noen enkelt uke. Ved inngåelse av avtale som innebærer at den alminnelige arbeidstiden overstiger 10 timer i løpet av 24 timer, skal det legges særlig vekt på hensynet til arbeidstakernes helse og velferd.

(3) Arbeidstilsynet kan samtykke i at den alminnelige arbeidstiden i løpet av en periode på høyst 26 uker i gjennomsnitt ikke blir lenger enn foreskrevet i § 10-4, men slik at den samlede arbeidstiden ikke overstiger 13 timer i løpet av 24 timer og 48 timer i løpet av sju dager. Grensen på 48 timer kan gjennomsnittsberegnes over en periode på åtte uker. Før Arbeidstilsynet treffer sin avgjørelse, skal ordningen av arbeidstiden drøftes med arbeidstakernes tillitsvalgte. Referat fra drøftingene samt utkast til arbeidsplan skal vedlegges søknaden. Arbeidstilsynet skal ved sin avgjørelse legge særlig vekt på hensynet til arbeidstakernes helse og velferd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96879, 'lov/2005-06-17-62', 64, 11, 'kapittel-11-paragraf-6', '§ 10-6', 'Overtid', '(1) Arbeid utover avtalt arbeidstid må ikke gjennomføres uten at det foreligger et særlig og tidsavgrenset behov for det.

(2) Varer arbeidet for noen arbeidstaker ut over lovens grense for den alminnelige arbeidstid regnes det overskytende som overtidsarbeid.

(3) Før arbeid som nevnt i denne paragraf iverksettes skal arbeidsgiver, dersom det er mulig, drøfte nødvendigheten av det med arbeidstakernes tillitsvalgte.

(4) Overtidsarbeidet må ikke overstige ti timer i løpet av sju dager, 25 timer i fire sammenhengende uker og 200 timer innenfor en periode på 52 uker.

(5) Arbeidsgiver og arbeidstakernes tillitsvalgte i virksomhet som er bundet av tariffavtale, kan skriftlig avtale overtidsarbeid inntil 20 timer i løpet av sju dager, men slik at samlet overtidsarbeid ikke overstiger 50 timer i fire sammenhengende uker. Overtidsarbeidet må ikke overstige 300 timer innenfor en periode på 52 uker.

(6) Arbeidstilsynet kan etter søknad i særlige tilfeller tillate samlet overtidsarbeid inntil 25 timer i løpet av sju dager og 200 timer i løpet av en periode på 26 uker. Referat fra drøftingene, jf. tredje ledd, skal vedlegges søknaden. Fremmer virksomheten søknad om overtid innenfor rammen i femte ledd, skal årsaken til at saken ikke er løst ved avtale med de tillitsvalgte alltid oppgis. Arbeidstilsynet skal ved sin avgjørelse legge særlig vekt på hensynet til arbeidstakernes helse og velferd.

(7) Overtidsarbeid utover rammen i fjerde ledd kan bare pålegges arbeidstakere som i det enkelte tilfellet har sagt seg villig til det.

(8) Samlet arbeidstid må ikke overstige 13 timer i løpet av 24 timer eller 48 timer i løpet av sju dager. Grensen på 48 timer i løpet av sju dager kan gjennomsnittsberegnes over en periode på åtte uker, likevel slik at den samlede arbeidstiden etter § 10-5 andre ledd og § 10-6 femte ledd ikke overstiger 69 timer i noen enkelt uke.

(9) Arbeidsgiver og arbeidstakernes tillitsvalgte i virksomhet som er bundet av tariffavtale, kan skriftlig avtale unntak fra grensen på 13 timer i åttende ledd, men slik at den samlede arbeidstid ikke overstiger 16 timer i løpet av 24 timer. Arbeidstaker skal i så fall sikres tilsvarende kompenserende hvileperioder eller, der dette ikke er mulig, annet passende vern.

(10) Arbeidstaker har rett til å bli fritatt fra å utføre arbeid utover avtalt arbeidstid når vedkommende av helsemessige eller vektige sosiale grunner ber om det. Arbeidsgiver plikter også ellers å frita arbeidstaker som ber om det, når arbeidet uten skade kan utsettes eller utføres av andre.

(11) For overtidsarbeid skal det betales et tillegg til den lønn arbeidstakeren har for tilsvarende arbeid i den alminnelige arbeidstiden. Tillegget skal være minst 40 prosent.

(12) Arbeidsgiver og arbeidstaker kan skriftlig avtale at overtidstimer helt eller delvis skal tas ut i form av arbeidsfri på et avtalt tidspunkt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96880, 'lov/2005-06-17-62', 65, 11, 'kapittel-11-paragraf-7', '§ 10-7', 'Oversikt over arbeidstiden', 'Det skal foreligge en oversikt som viser hvor mye den enkelte arbeidstaker har arbeidet. Oversikten skal være tilgjengelig for Arbeidstilsynet og arbeidstakernes tillitsvalgte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96881, 'lov/2005-06-17-62', 66, 11, 'kapittel-11-paragraf-8', '§ 10-8', 'Daglig og ukentlig arbeidsfri', '(1) Arbeidstaker skal ha minst 11 timer sammenhengende arbeidsfri i løpet av 24 timer. Den arbeidsfrie perioden skal plasseres mellom to hovedarbeidsperioder.

(2) Arbeidstaker skal ha en sammenhengende arbeidsfri periode på 35 timer i løpet av sju dager.

(3) Arbeidsgiver og arbeidstakernes tillitsvalgte i virksomhet som er bundet av tariffavtale, kan skriftlig avtale unntak fra bestemmelsene i første og andre ledd. Slik avtale kan bare inngås dersom arbeidstaker sikres tilsvarende kompenserende hvileperioder eller, der dette ikke er mulig, annet passende vern. Det kan ikke avtales kortere arbeidsfri periode enn 8 timer i løpet av 24 timer eller 28 timer i løpet av sju dager. Grensen på 8 timer gjelder ikke når arbeid utover avtalt arbeidstid (jf. § 10-6 første ledd) eller arbeid ved utkalling under beredskapsvakt utenfor arbeidsstedet er nødvendig for å unngå alvorlige driftsforstyrrelser. Ved virksomhet som ikke er bundet av tariffavtale, kan arbeidsgiver og arbeidstakernes representanter på samme vilkår skriftlig avtale arbeid i den arbeidsfrie perioden, når dette er nødvendig for å unngå alvorlige driftsforstyrrelser.

(4) Arbeidsfri som nevnt i andre ledd skal så vidt mulig omfatte søndag. Arbeidstaker som har utført søn- og helgedagsarbeid, skal ha arbeidsfri følgende søn- og helgedagsdøgn. Arbeidsgiver og arbeidstaker kan skriftlig avtale en arbeidstidsordning som i gjennomsnitt gir arbeidstaker arbeidsfri annenhver søn- og helgedag over en periode på 26 uker, likevel slik at det ukentlige fridøgn minst hver fjerde uke faller på en søn- eller helgedag.

(5) Departementet kan i forskrift fastsette en fordeling av fridøgnene som avviker fra reglene i fjerde ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96882, 'lov/2005-06-17-62', 67, 11, 'kapittel-11-paragraf-9', '§ 10-9', 'Pauser', '(1) Arbeidstaker skal ha minst en pause dersom den daglige arbeidstiden overstiger fem og en halv time. Pausene skal til sammen være minst en halv time hvis den daglige arbeidstid er minst åtte timer. Dersom arbeidstaker ikke fritt kan forlate arbeidsplassen under pausen eller der det ikke finnes tilfredsstillende pauserom, skal pausen regnes som en del av arbeidstiden. Når forholdene gjør det nødvendig, kan pausen forskyves.

(2) Når arbeidstaker arbeider mer enn to timer etter at den alminnelige arbeidstid er avviklet, skal arbeidstaker gis en pause på minst en halv time. Pausen regnes som en del av arbeidstiden. Pause som legges etter alminnelig arbeidstids slutt, godtgjøres som overtidsarbeid, men regnes ikke med i det antall timer det er tillatt å arbeide overtid etter § 10-6. Når forholdene gjør det nødvendig, kan pausen kortes ned eller forskyves.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96883, 'lov/2005-06-17-62', 68, 11, 'kapittel-11-paragraf-10', '§ 10-10', 'Søndagsarbeid', '(1) Det skal være arbeidsfri fra kl. 1800 dagen før en søn- eller helgedag og til kl. 2200 dagen før neste virkedag. Jul-, påske- og pinseaften skal det være arbeidsfri fra kl. 1500 til kl. 2200 dagen før neste virkedag. Arbeid innenfor disse tidsrom regnes som søn- og helgedagsarbeid.

(2) Arbeid på søn- og helgedager er ikke tillatt med mindre arbeidets art gjør det nødvendig.

(3) Arbeidsgiver skal drøfte behovet for søn- og helgedagsarbeid med arbeidstakernes tillitsvalgte før det iverksettes.

(4) I virksomhet som er bundet av tariffavtale kan arbeidsgiver og arbeidstakerens tillitsvalgte inngå skriftlig avtale om arbeid på søn- og helgedager dersom det foreligger et særlig og tidsavgrenset behov for dette.

(5) Arbeidsgiver og arbeidstaker kan slutte skriftlig avtale om arbeid på søn- og helgedager utenom de tilfeller som er nevnt i denne paragraf, mot tilsvarende fri på andre dager som i henhold til arbeidstakerens religion er helge- eller høytidsdag. Slik avtale kan inngås uten hensyn til bestemmelsene i § 10-8 fjerde ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96884, 'lov/2005-06-17-62', 69, 11, 'kapittel-11-paragraf-11', '§ 10-11', 'Nattarbeid', '(1) Arbeid mellom kl. 2100 og kl. 0600 er nattarbeid. Arbeidsgiver og arbeidstakers tillitsvalgte ved virksomhet som er bundet av tariffavtale, kan skriftlig fastsette et annet tidsrom på minst åtte timer som omfatter tiden mellom kl. 0000 og kl. 0600. Som nattarbeid regnes ikke arbeid på to skift som legges mellom kl. 0600 og kl. 0000.

(2) Nattarbeid er ikke tillatt med mindre arbeidets art gjør det nødvendig.

(3) Arbeidsgiver og arbeidstaker kan inngå skriftlig avtale om at arbeidstaker, på eget initiativ, kan utføre arbeid mellom kl. 2100 og kl. 2300.

(4) Ved virksomhet som er bundet av tariffavtale kan arbeidsgiver og arbeidstakers tillitsvalgte inngå skriftlig avtale om nattarbeid dersom det foreligger et særlig og tidsavgrenset behov for dette.

(5) Arbeidsgiver skal drøfte nødvendigheten av nattarbeid med arbeidstakers tillitsvalgte før det iverksettes.

(6) Den alminnelige arbeidstiden for arbeidstaker som jevnlig arbeider mer enn tre timer om natten, skal i gjennomsnitt ikke overstige åtte timer i løpet av 24 timer. Gjennomsnittet skal beregnes over fire uker. Minimumsperioden for ukentlig arbeidsfri i § 10-8 andre ledd skal ikke tas med ved beregning av gjennomsnittet.

(7) Arbeidstiden for arbeidstaker som arbeider mer enn tre timer om natten skal ikke overstige åtte timer i løpet av 24 timer dersom arbeidet innebærer en særlig risiko eller betydelige fysiske eller psykiske belastninger.

(8) Arbeidstaker som hovedsakelig utfører arbeid om natten, skal gis tilbud om helsekontroll før tiltredelse og deretter med jevne mellomrom.

(9) Arbeidsgiver og arbeidstakers tillitsvalgte ved virksomheter som er bundet av tariffavtale, kan skriftlig avtale at bestemmelsene i sjette og sjuende ledd skal fravikes. Arbeidstakerne skal i så fall sikres tilsvarende kompenserende hvileperioder eller, der dette ikke er mulig, annet passende vern.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96885, 'lov/2005-06-17-62', 70, 11, 'kapittel-11-paragraf-12', '§ 10-12', 'Unntak', '(1) Bestemmelsene i dette kapittel kommer ikke til anvendelse for arbeidstaker i ledende stilling, med unntak av § 10-2 første, andre og fjerde ledd.

(2) Bestemmelsene i dette kapitlet kommer ikke til anvendelse for arbeidstakere i særlig uavhengig stilling, med unntak av § 10-2 første, andre og fjerde ledd.

(3) Bestemmelsene i dette kapittel kan fravikes for arbeid som på grunn av naturhendelser, ulykke eller andre uforutsette begivenheter må foretas for å avverge fare for eller skade på liv eller eiendom. I så fall skal arbeidstakerne sikres tilsvarende kompenserende hvileperioder eller, der dette ikke er mulig, annet passende vern.

(4) Fagforening med innstillingsrett etter arbeidstvistloven eller tjenestetvistloven kan, med unntak av § 10-2 første, andre og fjerde ledd, og § 10-11 åttende ledd, inngå tariffavtale som fraviker bestemmelsene i dette kapittel. Unntak fra § 10-8 første og andre ledd og § 10-11 sjette og sjuende ledd forutsetter at arbeidstakerne sikres tilsvarende kompenserende hvileperioder, eller der dette ikke er mulig, annet passende vern. For bruk av overtid etter slik tariffavtale gjelder vilkårene i § 10-6 første ledd. Arbeidstaker må i det enkelte tilfelle samtykke til overtidsarbeidet. Kravet til individuelt samtykke gjelder tilsvarende der det inngås tariffavtale om en samlet gjennomsnittlig arbeidstid på over 48 timer i løpet av sju dager i løpet av ett år.

(5) Dersom det er inngått avtale som nevnt i §§ 10-5 andre ledd, 10-6, 10-8 tredje ledd, 10-10, 10-11 første, fjerde eller niende ledd eller § 10-12 fjerde ledd, og et flertall av arbeidstakerne er bundet av avtalen, kan arbeidsgiver gjøre avtalens bestemmelser om arbeidstid gjeldende for alle arbeidstakere som utfører arbeid av den art avtalen omfatter.

(6) Arbeidstilsynet kan gi samtykke til arbeidstidsordninger som fraviker § 10-8 og § 10-10 andre ledd når det er lang avstand mellom arbeidsstedet og arbeidstakers bosted. Slikt samtykke kan bare gis dersom det har sikkerhetsmessig betydning å legge til rette for en helhetlig regulering av arbeidstidsordningene på arbeidsplassen. Fravik fra § 10-8 første og andre ledd forutsetter at arbeidstakerne sikres kompenserende hvile eller, der dette ikke er mulig, annet passende vern.

(7) Arbeidstilsynet kan gi samtykke til arbeidstidsordninger som fraviker § 10-8 første og andre ledd og grensen på 13 timer i § 10-5 tredje ledd for helse- og omsorgsarbeid samt vakt- og overvåkningsarbeid der arbeidet helt eller delvis er av passiv karakter (jf. § 10-4 andre ledd). Slikt samtykke kan bare gis dersom arbeidstakerne sikres kompenserende hvile eller, der dette ikke er mulig, annet passende vern.

(8) Dersom arbeidet er av så særegen art at det vanskelig lar seg tilpasse bestemmelsene i kapitlet her, kan departementet i forskrift gi særlige regler og fastsette unntak fra disse bestemmelsene.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96886, 'lov/2005-06-17-62', 71, 11, 'kapittel-11-paragraf-13', '§ 10-13', 'Tvisteløsning', 'Tvist mellom arbeidsgiver og arbeidstaker om anvendelsen av bestemmelsene i § 10-2 andre, tredje og fjerde ledd og § 10-6 tiende ledd avgjøres av tvisteløsningsnemnda, jf. § 17-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96887, 'lov/2005-06-17-62', 72, 12, 'kapittel-12-paragraf-1', '§ 11-1', 'Forbud mot barnearbeid', '(1) Barn som er under 15 år eller skolepliktige skal ikke utføre arbeid som går inn under denne lov unntatt
a. kulturelt eller lignende arbeid,
b. lett arbeid og barnet har fylt 13 år,
c. arbeid som ledd i barnets skolegang eller i praktisk yrkesorientering som er godkjent av skolemyndighetene og barnet har fylt 14 år.

(2) Departementet kan i forskrift gi nærmere bestemmelser om hva slags arbeid som skal være tillatt etter første ledd. Det kan fastsettes nærmere vilkår for slikt arbeid.

(3) Personer under 18 år må ikke utføre arbeid som kan være til skade for deres sikkerhet, helse, utvikling eller skolegang. Departementet kan i forskrift bestemme hva slags arbeid som er omfattet av dette forbudet og om listeføring av arbeidstakere under 18 år.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96888, 'lov/2005-06-17-62', 73, 12, 'kapittel-12-paragraf-2', '§ 11-2', 'Arbeidstid', '(1) Arbeidstiden for personer under 18 år skal legges slik at den ikke hindrer skolegang, eller hindrer dem i å dra nytte av undervisningen.

(2) For barn som er under 15 år eller er skolepliktig skal arbeidstiden ikke overstige:
a. 2 timer i døgnet på dager med undervisning og 12 timer i uken i uker med undervisning,
b. 7 timer i døgnet på undervisningsfrie dager og 35 timer i undervisningsfrie uker,
c. 8 timer i døgnet og 40 timer i uken for samlet arbeids- og skoletid der arbeidet er ledd i en ordning med vekslende teoretisk og praktisk utdanning.

(3) For ungdom mellom 15 og 18 år som ikke er skolepliktig, skal arbeidstiden ikke overstige 8 timer i døgnet og 40 timer i uken.

(4) Ved ansettelse hos flere arbeidsgivere skal arbeidstiden beregnes samlet. Arbeidsgiver plikter å skaffe seg kjennskap til arbeidstiden hos eventuelle andre arbeidsgivere.

(5) Departementet kan i forskrift fastsette unntak fra
a. andre ledd bokstav a for kulturelt eller lignende arbeid, og
b. andre ledd bokstav c og tredje ledd, dersom særlige grunner foreligger.
Forskrift etter dette ledd kan inneholde vilkår.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96889, 'lov/2005-06-17-62', 74, 12, 'kapittel-12-paragraf-3', '§ 11-3', 'Forbud mot nattarbeid', '(1) Barn som er under 15 år eller er skolepliktig skal ikke arbeide mellom kl. 2000 og kl. 0600.

(2) Ungdom mellom 15 og 18 år som ikke er skolepliktig skal ha en arbeidsfri periode på minst 8 timer som omfatter tiden mellom kl. 2300 og kl. 0600. Arbeid mellom kl. 2100 og kl. 2300 er nattarbeid og er ikke tillatt med mindre arbeidets art gjør det nødvendig eller det foreligger et særlig og tidsavgrenset behov for nattarbeid.

(3) Andre ledd gjelder ikke for arbeid som på grunn av naturhendelser, ulykke eller andre uforutsette begivenheter må foretas for å avverge fare for eller skade på liv eller eiendom, og det er strengt nødvendig å nytte vedkommende ungdom i arbeidet. Ungdom som tar del i dette arbeidet skal ha en etterfølgende kompenserende hvileperiode.

(4) Departementet kan i forskrift bestemme at den arbeidsfrie perioden kan være kortere for visse typer arbeid, og fastsette nærmere regler om dette, herunder vilkår.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96890, 'lov/2005-06-17-62', 75, 12, 'kapittel-12-paragraf-4', '§ 11-4', 'Helsekontroll', '(1) Arbeidsgiver skal sørge for at ungdom som settes til nattarbeid i henhold til § 11-3 fjerde ledd skal gis tilbud om helsekontroll før tiltredelse og deretter med jevne mellomrom.

(2) Departementet kan gi forskrift om gjennomføringen av helsekontrollen, og fastsette regler om helsekontroll i andre tilfeller hvor arbeidet stiller særlige krav til arbeidstakerens helse eller fysiske egenskaper.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96891, 'lov/2005-06-17-62', 76, 12, 'kapittel-12-paragraf-5', '§ 11-5', 'Pauser og fritid', '(1) Personer under 18 år skal ha hvilepause i minst en halv time, om mulig sammenhengende, dersom den daglige arbeidstiden overstiger fire og en halv time.

(2) Innenfor hver periode på 24 timer skal det være en sammenhengende arbeidsfri periode på minst:
a. 14 timer for barn som er under 15 år eller er skolepliktig,
b. 12 timer for ungdom mellom 15 og 18 år som ikke er skolepliktig.

(3) Personer under 18 år skal ha en sammenhengende arbeidsfri periode på minst 48 timer i løpet av sju dager. Den arbeidsfrie perioden skal så vidt mulig legges til søn- eller helgedag.

(4) Personer under 18 år som går på skole skal ha minst fire ukers feriefritid i året, hvorav minst to uker i sommerferien.

(5) Departementet kan i særlige tilfeller i forskrift fastsette unntak fra reglene i andre, tredje og fjerde ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96892, 'lov/2005-06-17-62', 77, 13, 'kapittel-13-paragraf-1', '§ 12-1', 'Svangerskapskontroll', 'Arbeidstaker som er gravid har rett til fri fra arbeidet med lønn i forbindelse med svangerskapskontroll dersom slike undersøkelser ikke med rimelighet kan finne sted utenfor arbeidstiden.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96893, 'lov/2005-06-17-62', 78, 13, 'kapittel-13-paragraf-2', '§ 12-2', 'Svangerskapspermisjon', 'Arbeidstaker som er gravid har rett til permisjon i inntil tolv uker under svangerskapet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96894, 'lov/2005-06-17-62', 79, 13, 'kapittel-13-paragraf-3', '§ 12-3', 'Omsorgspermisjon', '(1) I forbindelse med fødselen har faren rett til to ukers permisjon for å bistå moren. Hvis foreldrene ikke bor sammen, kan retten til permisjon utøves av en annen som bistår moren.

(2) Adoptivforeldre og fosterforeldre har rett til to ukers permisjon i forbindelse med at omsorgen for barnet overtas. Dette gjelder ikke ved stebarnsadopsjon eller hvis barnet er over 15 år.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96895, 'lov/2005-06-17-62', 80, 13, 'kapittel-13-paragraf-4', '§ 12-4', 'Fødselspermisjon', 'Etter fødselen skal mor ha permisjon de første seks uker, med mindre hun fremlegger legeattest om at det er bedre for henne å komme i arbeid.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96896, 'lov/2005-06-17-62', 81, 13, 'kapittel-13-paragraf-5', '§ 12-5', 'Foreldrepermisjon', '(1) Foreldrene har rett til permisjon etter reglene i paragrafen her og i §§ 12-2 og 12-4 i til sammen tolv måneder. Foreldrene har uansett rett til permisjon når det ytes foreldrepenger fra folketrygden.

(2) Hver av foreldrene har i tillegg til permisjon etter første ledd, rett til permisjon i inntil tolv måneder for hver fødsel. Denne permisjonen må tas ut umiddelbart etter foreldrenes permisjon etter første ledd. Arbeidstaker som har delvis permisjon etter § 12-6 har likevel ikke rett til permisjon etter leddet her.

(3) Med mindre begge foreldrene har omsorgen for barnet, kan retten til permisjon etter første ledd utøves av en annen som har omsorg for barnet. Arbeidstaker som er alene om omsorgen for barnet har rett til inntil to års permisjon etter andre ledd.

(4) Adoptivforeldre og fosterforeldre har rett til permisjon etter paragrafen her når omsorgen for barnet overtas. Det samme gjelder arbeidstaker som har eller får tildelt foreldreansvar når den andre av foreldrene dør, og som har hatt mindre enn vanlig samvær med barnet. Retten til permisjon gjelder ikke ved stebarnsadopsjon eller hvis barnet er over 15 år.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96897, 'lov/2005-06-17-62', 82, 13, 'kapittel-13-paragraf-6', '§ 12-6', 'Delvis permisjon', '(1) Permisjon etter §§ 12-2, 12-4 og 12-5 første ledd kan tas ut som delvis permisjon.

(2) Delvis permisjon baseres på avtale mellom arbeidsgiver og arbeidstaker. Arbeidstakers ønske om hvordan uttaket av delvis permisjon skal gjennomføres, skal oppfylles med mindre dette medfører vesentlige ulemper for virksomheten. Arbeidstaker har rett til å la seg bistå av en tillitsvalgt eller annen representant. Avtale om delvis permisjon kan endres eller opphøre når særlige grunner gjør det nødvendig.

(3) Delvis permisjon må tas ut innenfor en tidsramme på tre år.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96898, 'lov/2005-06-17-62', 83, 13, 'kapittel-13-paragraf-7', '§ 12-7', 'Varslingsplikt', 'Permisjon etter §§ 12-2 til 12-6 skal varsles arbeidsgiver snarest mulig og senest en uke i forveien ved fravær utover to uker, senest fire uker i forveien ved fravær utover tolv uker og senest tolv uker i forveien ved fravær utover ett år. Oversittelse av fristene medfører ikke at arbeidstaker må utsette permisjonen dersom permisjon er nødvendig på grunn av forhold som arbeidstakeren ikke hadde kjennskap til ved fristens utløp.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96899, 'lov/2005-06-17-62', 84, 13, 'kapittel-13-paragraf-8', '§ 12-8', 'Ammefri', '(1) Kvinne som ammer sitt barn kan kreve den fri hun av den grunn trenger. Fritiden kan for eksempel tas ut i minst en halv time to ganger daglig eller som redusert arbeidstid med inntil én time hver dag.

(2) Kvinne som har ammefri etter første ledd, har i barnets første leveår rett til lønn inntil én time på arbeidsdager med avtalt arbeidstid sju timer eller mer.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96900, 'lov/2005-06-17-62', 85, 13, 'kapittel-13-paragraf-9', '§ 12-9', 'Barns og barnepassers sykdom', '(1) Arbeidstaker som har omsorg for barn har rett til permisjon:
a. for nødvendig tilsyn med barnet når det er sykt,
b. hvis barnet skal følges til legeundersøkelse eller annen oppfølging i forbindelse med sykdom, eller
c. hvis den som har det daglige barnetilsynet er syk eller har permisjon etter denne paragraf på grunn av et annet barn.

(2) Retten til permisjon etter paragrafen her gjelder til og med det kalenderåret barnet fyller 12 år. Arbeidstaker har rett til permisjon inntil 10 dager hvert kalenderår eller inntil 15 dager dersom arbeidstaker har omsorg for mer enn to barn.

(3) Dersom barnet har kronisk sykdom, langvarig sykdom eller har nedsatt funksjonsevne og det derfor er en markert økning av risikoen for at arbeidstaker får fravær fra arbeidet, har arbeidstaker rett til fri etter første ledd i inntil 20 dager hvert kalenderår. Retten til permisjon gjelder til og med det kalenderåret barnet fyller 18 år. Arbeidstaker har i tillegg rett til permisjon for å delta i opplæring ved godkjent helseinstitusjon eller offentlig kompetansesenter for å kunne ta seg av og behandle barnet.

(4) Arbeidstaker som har omsorg for barn har rett til permisjon dersom:
a. barnet blir innlagt i helseinstitusjon og arbeidstaker oppholder seg ved helseinstitusjonen,
b. barnet er utskrevet fra helseinstitusjon og arbeidstaker må være hjemme fordi barnet trenger kontinuerlig tilsyn og pleie, eller
c. barnet har livstruende eller annen svært alvorlig sykdom eller skade.
Ved permisjon etter bokstavene a og b gjelder aldersgrensene i andre og tredje ledd. Rett til permisjon etter bokstav c gjelder til og med det kalenderåret barnet fyller 18 år, men uten hensyn til alder hvis barnet er psykisk utviklingshemmet.

(5) Arbeidstaker har uansett rett til permisjon når det ytes omsorgspenger, pleiepenger eller opplæringspenger fra folketrygden.

(6) Arbeidstaker som er alene om omsorgen for barn har rett til dobbelt så mange permisjonsdager som etter andre og tredje ledd. Det samme gjelder hvis det er to om omsorgen, men en av dem er langvarig avskåret fra tilsynet med barnet på grunn av nedsatt funksjonsevne, innleggelse i helseinstitusjon som langtidspasient, er i fengsel, avtjener verneplikt eller tilsvarende forhold. Retten til permisjon kan overføres med inntil halvparten av dagene hvert kalenderår til mor eller far med samværsrett eller til den som arbeidstaker bor sammen med og som ikke har omsorg for egne barn.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96901, 'lov/2005-06-17-62', 86, 13, 'kapittel-13-paragraf-10', '§ 12-10', 'Omsorg for og pleie av nærstående', 'Arbeidstaker som pleier nærstående i hjemmet i livets sluttfase har rett til permisjon i 60 dager for pleie av den enkelte nærstående.

Arbeidstaker har rett til permisjon i inntil 10 dager hvert kalenderår for å gi nødvendig omsorg til foreldre, ektefelle, samboer eller registrert partner. Det samme gjelder ved nødvendig omsorg for funksjonshemmet eller kronisk sykt barn fra og med kalenderåret etter at barnet fylte 18 år når arbeidstakeren har hatt slik omsorg for barnet som nevnt i § 12-9 tredje ledd. Departementet kan gi forskrift om dokumentasjon av nødvendig omsorg.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96902, 'lov/2005-06-17-62', 87, 13, 'kapittel-13-paragraf-11', '§ 12-11', 'Utdanningspermisjon', '(1) Arbeidstaker som har vært i arbeidslivet i minst tre år og som har vært ansatt hos arbeidsgiveren de siste to år, har rett til hel eller delvis permisjon i inntil tre år for å delta i organiserte utdanningstilbud. Utdanning ut over grunnskole eller videregående opplæringsnivå må være yrkesrelatert for å gi rett til permisjon. Yrkesrelatert utdanning omfatter alle typer arbeidsmarkedsrelevant etter- og videreutdanning.

(2) Permisjon kan likevel ikke kreves når det vil være til hinder for arbeidsgivers forsvarlige planlegging av drift og personaldisponeringer.

(3) Arbeidstaker som har hatt utdanningspermisjon, har ikke rett til ny utdanningspermisjon før det har gått
a. dobbelt så lang tid som varigheten av den foregående permisjonen og
b. minst ett år fra den foregående permisjonen tok til, unntatt ved utdanningspermisjon for kurs under én måneds varighet.

(4) Arbeidstaker som vil bruke retten til utdanningspermisjon, må gi arbeidsgiver skriftlig varsel om dette. Varslet skal inneholde opplysninger om utdanningens faglige innhold, varighet og eventuelt opptak ved utdanningsinstitusjon. Dersom det gjelder utdanning ut over grunnskole eller videregående opplæringsnivå, må yrkesrelevans begrunnes.

(5) Arbeidsgiver som vil gjøre gjeldende at vilkårene for utdanningspermisjon ikke er oppfylt, skal snarest mulig og senest innen seks måneder skriftlig underrette arbeidstaker om dette. Dersom varslet permisjon er kortere enn seks måneder, skal slik underretning foreligge innen tre måneder etter at varsel er mottatt, men innen to måneder når varslet permisjon er kortere enn én måned. Arbeidsgiver skal fram til svar gis, på forespørsel orientere arbeidstaker om hva som gjøres for om mulig å legge til rette for permisjonen.

(6) Departementet kan i forskrift helt eller delvis unnta virksomheter fra bestemmelsene i denne paragraf.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96903, 'lov/2005-06-17-62', 88, 13, 'kapittel-13-paragraf-12', '§ 12-12', 'Militærtjeneste mv.', '(1) Arbeidstaker har rett til permisjon ved pliktig eller frivillig militærtjeneste eller lignende allmenn vernetjeneste. Det samme gjelder ved frivillig tjenestegjøring av til sammen 24 måneders varighet i styrker organisert av norske myndigheter for deltakelse i internasjonale fredsoperasjoner, hvis arbeidstaker snarest mulig etter å ha inngått bindende avtale om tjenestegjøring i slike styrker varsler arbeidsgiver om dette.

(2) Arbeidstaker som ønsker å fortsette i stillingen etter tjenestegjøringen, skal varsle arbeidsgiver før tjenesten begynner. Arbeidsgiver plikter ikke å ta arbeidstaker tilbake i arbeid før en måned etter mottak av varsel om fra hvilken dag arbeidstaker kan gjenoppta arbeidet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96904, 'lov/2005-06-17-62', 89, 13, 'kapittel-13-paragraf-13', '§ 12-13', 'Offentlige verv', 'Arbeidstaker har rett til permisjon fra arbeid i det omfang det er nødvendig for å oppfylle lovbestemt møteplikt i offentlige organer.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96905, 'lov/2005-06-17-62', 90, 13, 'kapittel-13-paragraf-14', '§ 12-14', 'Tvisteløsning', 'Tvist om rett til permisjon etter dette kapittel avgjøres av tvisteløsningsnemnda, jf. § 17-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96906, 'lov/2005-06-17-62', 91, 13, 'kapittel-13-paragraf-15', '§ 12-15', 'Religiøse høytider', 'Rett til permisjon ved religiøse høytider for arbeidstaker som har andre religiøse høytidsdager enn de offentlige helligdagene, reguleres av trossamfunnsloven § 18.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96907, 'lov/2005-06-17-62', 92, 13, 'kapittel-13-paragraf-16', '§ 12-16', 'Forskrifter ved utbrudd eller fare for utbrudd av allmennfarlig smittsom sykdom', 'Ved utbrudd eller fare for utbrudd av allmennfarlig smittsom sykdom kan departementet gi forskrift om rett til permisjon som avviker fra bestemmelsene i dette kapitlet. Slik forskrift kan gis virkning så lenge utbruddet eller faren for utbrudd er til stede.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96908, 'lov/2005-06-17-62', 93, 14, 'kapittel-14-paragraf-1', '§ 13-1', 'Forbud mot diskriminering', '(1) Direkte og indirekte diskriminering på grunn av politisk syn, medlemskap i arbeidstakerorganisasjon eller alder er forbudt.

(2) Trakassering og instruks om å diskriminere personer av grunner nevnt i første ledd anses som diskriminering.

(3) Bestemmelsene i dette kapittel gjelder tilsvarende ved diskriminering av arbeidstaker som arbeider deltid eller er midlertidig ansatt.

(4) Ved diskriminering på grunn av kjønn, graviditet, permisjon i forbindelse med fødsel og adopsjon, omsorgsoppgaver, etnisitet, religion, livssyn, funksjonsnedsettelse, seksuell orientering, kjønnsidentitet eller kjønnsuttrykk gjelder likestillings- og diskrimineringsloven.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96909, 'lov/2005-06-17-62', 94, 14, 'kapittel-14-paragraf-2', '§ 13-2', 'Hva kapitlet omfatter', '(1) Bestemmelsene i dette kapittel gjelder alle sider ved arbeidsforholdet, herunder:
a. utlysning av stilling, ansettelse, omplassering og forfremmelse,
b. opplæring og annen kompetanseutvikling,
c. lønns- og arbeidsvilkår,
d. opphør.

(2) Bestemmelsene i dette kapittel gjelder tilsvarende for arbeidsgivers valg og behandling av selvstendige oppdragstakere og innleide arbeidstakere.

(3) Bestemmelsene i dette kapittel gjelder tilsvarende for innmelding i og deltakelse i en arbeidstaker-, arbeidsgiver- eller yrkesorganisasjon. Dette gjelder også for fordeler som slike organisasjoner gir sine medlemmer.

(4) Bestemmelsene i dette kapittel får ikke anvendelse ved forskjellsbehandling som skyldes medlemskap i arbeidstakerorganisasjon for så vidt gjelder lønns- og arbeidsvilkår i tariffavtaler.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96910, 'lov/2005-06-17-62', 95, 14, 'kapittel-14-paragraf-3', '§ 13-3', 'Unntak fra forbudet mot diskriminering', '(1) Forskjellsbehandling som har et saklig formål, ikke er uforholdsmessig inngripende overfor den eller de som forskjellsbehandles og som er nødvendig for utøvelse av arbeid eller yrke, anses ikke som diskriminering etter loven her.

(2) Forskjellsbehandling som er nødvendig for å oppnå et saklig formål og som ikke er uforholdsmessig inngripende overfor den eller de som forskjellsbehandles er ikke i strid med forbudet mot indirekte diskriminering, diskriminering på grunn av alder eller diskriminering av arbeidstaker som arbeider deltid eller er midlertidig ansatt.

(3) Departementet kan i forskrift gi nærmere bestemmelser om rekkevidden av unntaket fra forbudet mot aldersdiskriminering i andre ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96911, 'lov/2005-06-17-62', 96, 14, 'kapittel-14-paragraf-4', '§ 13-4', 'Innhenting av opplysninger ved ansettelse', '(1) Arbeidsgiver må ikke i utlysing etter nye arbeidstakere eller på annen måte be om at søkerne skal gi opplysninger om hvordan de stiller seg til politiske spørsmål eller om de er medlemmer av arbeidstakerorganisasjoner. Arbeidsgiver må heller ikke iverksette tiltak for å innhente slike opplysninger på annen måte.

(2) Forbudet i første ledd gjelder ikke dersom innhenting av opplysninger om hvordan søkerne stiller seg til politiske spørsmål eller om de er medlemmer av arbeidstakerorganisasjon er begrunnet i stillingens karakter eller det inngår i formålet for vedkommende virksomhet å fremme bestemte politiske syn og arbeidstakerens stilling vil være av betydning for gjennomføringen av formålet. Dersom slike opplysninger vil bli krevet, må dette angis i utlysingen av stillingen.

(3) Arbeidsgiver kan heller ikke innhente opplysninger som angitt i likestillings- og diskrimineringsloven § 30.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96912, 'lov/2005-06-17-62', 97, 14, 'kapittel-14-paragraf-5', '§ 13-5', '(Opphevet)', '', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96913, 'lov/2005-06-17-62', 98, 14, 'kapittel-14-paragraf-6', '§ 13-6', 'Positiv særbehandling', 'Særbehandling som bidrar til å fremme likebehandling er ikke i strid med bestemmelsene i dette kapittel. Særbehandlingen skal opphøre når formålet med den er oppnådd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96914, 'lov/2005-06-17-62', 99, 14, 'kapittel-14-paragraf-7', '§ 13-7', 'Opplysningsplikt', 'Arbeidssøker som mener seg forbigått i strid med bestemmelsene i dette kapittel, kan kreve at arbeidsgiver skriftlig opplyser om hvilken utdanning, praksis og andre klart konstaterbare kvalifikasjoner for arbeidet den som ble ansatt har.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96915, 'lov/2005-06-17-62', 100, 14, 'kapittel-14-paragraf-8', '§ 13-8', 'Bevisbyrde', 'Dersom arbeidstaker eller arbeidssøker fremlegger opplysninger som gir grunn til å tro at det har funnet sted diskriminering i strid med bestemmelse i dette kapittel, må arbeidsgiver sannsynliggjøre at det likevel ikke har funnet sted slik diskriminering eller gjengjeldelse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96916, 'lov/2005-06-17-62', 101, 14, 'kapittel-14-paragraf-9', '§ 13-9', 'Virkningene av brudd på diskrimineringsforbudet', '(1) Den som er blitt diskriminert i strid med § 13-1 kan kreve oppreisning og erstatning uavhengig av om arbeidsgiveren kan bebreides for diskrimineringen. Erstatningen skal dekke økonomisk tap som følge av diskrimineringen. Oppreisning for ikke-økonomisk skade fastsettes til det som er rimelig ut fra skadens omfang og art, partenes forhold og omstendighetene for øvrig.

(2) Bestemmelser i tariffavtaler, arbeidsavtaler, reglementer, vedtekter mv. som er i strid med dette kapittel, er ugyldige.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96917, 'lov/2005-06-17-62', 102, 14, 'kapittel-14-paragraf-10', '§ 13-10', 'Organisasjoners adgang til å opptre som fullmektig', 'Som fullmektig i forvaltningssak etter dette kapittel kan brukes en organisasjon som helt eller delvis har til formål å arbeide mot diskriminering av grunner nevnt i § 13-1 første ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96918, 'lov/2005-06-17-62', 103, 15, 'kapittel-15-paragraf-1', '§ 14-1', 'Informasjon om ledige stillinger i virksomheten', 'Arbeidsgiver skal informere arbeidstakerne om ledige stillinger i virksomheten. Innleid arbeidstaker skal informeres på tilsvarende måte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96919, 'lov/2005-06-17-62', 104, 15, 'kapittel-15-paragraf-2', '§ 14-1 a', '(Opphevet)', '', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96920, 'lov/2005-06-17-62', 105, 15, 'kapittel-15-paragraf-3', '§ 14-1 b', 'Ansettelse på heltid og deltid', '(1) Arbeidstaker skal som hovedregel ansettes på heltid.

(2) Før arbeidsgiver fatter beslutning om ansettelse i deltidsstilling, skal arbeidsgiver skriftlig dokumentere behovet for deltidsansettelse. Dokumentasjonen skal være tilgjengelig for tillitsvalgte, og spørsmålet om deltidsansettelse skal drøftes med de tillitsvalgte.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96921, 'lov/2005-06-17-62', 106, 15, 'kapittel-15-paragraf-4', '§ 14-2', 'Fortrinnsrett til ny ansettelse', '(1) Arbeidstaker som er sagt opp på grunn av virksomhetens forhold, har fortrinnsrett til ny ansettelse i samme virksomhet, med mindre det gjelder en stilling arbeidstakeren ikke er kvalifisert for. Tilhører arbeidsgiver et konsern, jf. § 8-4 fjerde ledd, har arbeidstaker i tillegg fortrinnsrett til ny ansettelse i andre virksomheter i konsernet, med mindre det gjelder en stilling arbeidstakeren ikke er kvalifisert for. Fortrinnsretten etter andre punktum bortfaller hvis arbeidstaker ikke aksepterer et tilbud om annet passende arbeid etter § 15-7 tredje ledd.

(2) Fortrinnsretten gjelder også arbeidstaker som er midlertidig ansatt og som på grunn av virksomhetens forhold ikke får fortsatt ansettelse. Dette gjelder likevel ikke arbeidstaker som er midlertidig ansatt i vikariat etter § 14-9 andre ledd bokstav b. Fortrinnsretten gjelder dessuten for arbeidstaker som har akseptert tilbud om redusert stilling i stedet for oppsigelse.

(3) Fortrinnsretten gjelder for arbeidstaker som har vært ansatt i virksomheten i til sammen minst 12 måneder i de to siste år.

(4) Fortrinnsretten gjelder fra oppsigelsestidspunktet og i ett år fra oppsigelsesfristens utløp, men fra oppsigelsestidspunktet og i to år fra oppsigelsesfristens utløp dersom arbeidsforholdet avvikles i perioden fra 1. juli 2021 til og med 31. desember 2021 på grunn av virkninger av covid-19-pandemien.

(5) Fortrinnsretten faller bort dersom arbeidstaker ikke har akseptert et tilbud om ansettelse i en passende stilling senest 14 dager etter at tilbudet ble mottatt. Arbeidstaker som ikke har akseptert et tilbud om ansettelse i passende stilling etter første ledd andre punktum, har likevel fortrinnsrett etter første ledd første punktum.

(6) Er det flere fortrinnsberettigede til en stilling, plikter arbeidsgiver å følge de samme regler for utvelgelse som de som gjelder ved oppsigelser på grunn av driftsinnskrenkning eller rasjonaliseringstiltak.

(7) Reglene i denne paragraf gjelder tilsvarende for arbeidstaker som er sagt opp i forbindelse med at virksomheten går konkurs. Dette gjelder bare når virksomheten fortsetter eller gjenopptas og den under hensyn til sted, art, omfang og lignende må anses som en fortsettelse av den opprinnelige virksomhet.

(8) Sjette ledd gjelder ikke ved konkurs, offentlig skifte av insolvent dødsbo eller ved overdragelse av virksomhet etter at det er åpnet gjeldsforhandlinger.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96922, 'lov/2005-06-17-62', 107, 15, 'kapittel-15-paragraf-5', '§ 14-3', 'Fortrinnsrett for deltidsansatte', '(1) Deltidsansatte har fortrinnsrett til utvidet stilling fremfor at arbeidsgiver foretar ny ansettelse eller innleie i virksomheten. Fortrinnsretten kan også gjelde en del av en stilling.

(2) Deltidsansatte har fortrinnsrett til ekstravakter og lignende i virksomheten fremfor at arbeidsgiver ansetter eller leier inn arbeidstakere til dette arbeidet. Arbeidsgiver kan etter drøftinger med tillitsvalgte avgrense virkeområdet for utøvelse av fortrinnsretten etter dette leddet til en eller flere enheter med til sammen minst 30 ansatte. Etter avtale med tillitsvalgte kan det fastsettes et annet eller snevrere virkeområde. Fortrinnsretten etter dette leddet gjelder også for midlertidig deltidsansatte.

(3) Fortrinnsrett etter denne paragrafen er betinget av at arbeidstaker er kvalifisert og at utøvelse av fortrinnsretten ikke vil innebære vesentlige ulemper for virksomheten.

(4) Før arbeidsgiver fatter beslutning om ansettelse i stilling som arbeidstaker krever fortrinnsrett til etter første ledd, skal spørsmålet så langt det er praktisk mulig drøftes med arbeidstaker, med mindre arbeidstaker selv ikke ønsker det.

(5) Fortrinnsrett etter § 14-2, med unntak av § 14-2 første ledd andre punktum og andre ledd første punktum, går foran fortrinnsrett for deltidsansatte.

(6) Tvist om fortrinnsrett for deltidsansatte etter første ledd avgjøres av tvisteløsningsnemnda, jf. § 17-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96923, 'lov/2005-06-17-62', 108, 15, 'kapittel-15-paragraf-6', '§ 14-4', 'Virkninger av brudd på reglene om fortrinnsrett', '(1) Dersom retten kommer til at en fortrinnsberettiget skulle vært ansatt i en bestemt stilling, skal retten etter påstand fra den fortrinnsberettigede avsi dom for ansettelse i stillingen, med mindre dette finnes urimelig.

(2) Ved brudd på reglene om fortrinnsrett kan arbeidstaker kreve erstatning. Erstatningen fastsettes i samsvar med § 15-12 andre ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96924, 'lov/2005-06-17-62', 109, 15, 'kapittel-15-paragraf-7', '§ 14-4 a', 'Rett til stilling for deltidsansatte tilsvarende faktisk arbeidstid', '(1) Deltidsansatte som de siste 12 måneder jevnlig har arbeidet utover avtalt arbeidstid, har rett til stilling tilsvarende faktisk arbeidstid i denne perioden, med mindre arbeidsgiver kan dokumentere at behovet for merarbeidet ikke lenger foreligger. Tolvmånedersperioden skal beregnes med utgangspunkt i det tidspunkt arbeidstaker fremmet sitt krav.

(2) Tvist om rett etter denne bestemmelsen avgjøres av tvisteløsningsnemnda, jf. § 17-2.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96925, 'lov/2005-06-17-62', 110, 15, 'kapittel-15-paragraf-8', '§ 14-4 b', 'Virkninger av brudd på deltidsansattes rett til stilling tilsvarende faktisk arbeidstid', '(1) Dersom retten kommer til at en deltidsansatt har rett til stilling tilsvarende faktisk arbeidstid etter bestemmelsen i § 14-4 a, skal retten etter påstand fra den deltidsansatte avsi dom for ansettelse i slik stilling.

(2) Ved brudd på bestemmelsen om rett til stilling tilsvarende faktisk arbeidstid etter § 14-4 a kan arbeidstaker kreve erstatning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96926, 'lov/2005-06-17-62', 111, 15, 'kapittel-15-paragraf-9', '§ 14-5', 'Krav om skriftlig arbeidsavtale', '(1) Det skal inngås skriftlig arbeidsavtale i alle arbeidsforhold. Arbeidsgiver skal utforme et utkast til arbeidsavtale i samsvar med § 14-6. Arbeidstaker har rett til å la seg bistå av en tillitsvalgt eller annen representant både ved utarbeidelse og ved endringer i arbeidsavtalen.

(2) I arbeidsforhold med en samlet varighet av mer enn en måned skal skriftlig arbeidsavtale foreligge snarest mulig og senest sju dager etter at arbeidsforholdet begynte.

(3) I arbeidsforhold med kortere varighet enn en måned eller ved utleie av arbeidskraft, skal det umiddelbart inngås skriftlig arbeidsavtale.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96927, 'lov/2005-06-17-62', 112, 15, 'kapittel-15-paragraf-10', '§ 14-6', 'Minimumskrav til innholdet i den skriftlige arbeidsavtalen', '(1) Arbeidsavtalen skal inneholde opplysninger om forhold av vesentlig betydning i arbeidsforholdet, herunder:
a. partenes identitet,
b. arbeidsplassen. Dersom det ikke eksisterer noen fast arbeidsplass eller hovedarbeidsplass skal arbeidsavtalen gi opplysning om at arbeidstakeren arbeider på forskjellige steder eller fritt kan bestemme sitt arbeidssted, og oppgi forretningsadressen eller eventuelt hjemstedet til arbeidsgiver,
c. en beskrivelse av arbeidet eller arbeidstakerens tittel, stilling eller arbeidskategori,
d. tidspunktet for arbeidsforholdets begynnelse,
e. forventet varighet dersom arbeidsforholdet er midlertidig, samt grunnlaget for ansettelsen, jf. § 14-9,
f. eventuelle prøvetidsbestemmelser, jf. § 15-3 sjuende ledd og § 15-6,
g. arbeidstakerens rett til ferie og feriepenger, reglene for fastsettelse av ferietidspunktet og eventuell rett til annet fravær betalt av arbeidsgiver,
h. arbeidstakerens og arbeidsgiverens oppsigelsesfrister og fremgangsmåte ved opphør av arbeidsforholdet,
i. den gjeldende eller avtalte lønnen ved arbeidsforholdets begynnelse, eventuelle tillegg og andre godtgjøringer som ikke inngår i lønnen, for eksempel pensjonsinnbetalinger og kost- eller nattgodtgjørelse, utbetalingsmåte og tidspunkt for lønnsutbetaling. De ulike elementene skal angis særskilt,
j. lengde og plassering av den daglige og ukentlige arbeidstid. Dersom arbeidet skal utføres periodevis eller den daglige og ukentlige arbeidstiden vil variere, skal arbeidsavtalen opplyse om dette og fastsette eller gi grunnlag for å beregne når arbeidet skal utføres,
k. lengde av pauser,
l. avtale om særlig arbeidstidsordning, jf. § 10-2 andre, tredje og fjerde ledd,
m. ordninger for vaktendringer, jf. § 10-3, samt ordninger for arbeid utover avtalt arbeidstid, herunder betaling for slikt arbeid,
n. opplysninger om eventuelle tariffavtaler som regulerer arbeidsforholdet. Dersom avtale er inngått av parter utenfor virksomheten skal arbeidsavtalen inneholde opplysninger om hvem tariffpartene er,
o. innleiers identitet dersom arbeidstaker leies ut fra bemanningsforetak. Opplysningen skal gis så snart innleiers identitet er kjent,
p. rett til kompetanseutvikling som arbeidsgiver eventuelt tilbyr,
q. ytelser i regi av arbeidsgiver til sosial trygghet samt navn på institusjoner som mottar innbetalinger fra arbeidsgiver i denne forbindelse.

(2) Informasjon nevnt i første ledd bokstavene g til k samt m, p og q, kan gis ved å henvise til lover, forskrifter eller tariffavtaler som regulerer disse forholdene.

(3) Dersom arbeidsgiver ikke har opplyst om at arbeidsforholdet er midlertidig, jf. første ledd bokstav e og § 14-5, skal det legges til grunn at arbeidstakeren har fast ansettelse dersom ikke noe annet gjøres overveiende sannsynlig.

(4) Dersom arbeidsgiver ikke har opplyst om stillingens omfang, jf. første ledd bokstav j og § 14-5, skal arbeidstakers påstand om stillingsomfang legges til grunn dersom ikke noe annet gjøres overveiende sannsynlig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96928, 'lov/2005-06-17-62', 113, 15, 'kapittel-15-paragraf-11', '§ 14-7', 'Arbeidstaker som sendes til utlandet', '(1) Dersom arbeidstaker skal arbeide i utlandet i mer enn fire sammenhengende uker, skal skriftlig arbeidsavtale inngås før avreise. I tillegg til informasjon som nevnt i § 14-6 skal avtalen minst regulere følgende:
a. hvilke land arbeidet skal utføres i, og varigheten av arbeidet som skal utføres i utlandet,
b. valutaen vederlaget skal utbetales i,
c. eventuelle kontant- og naturalytelser som er knyttet til utenlandsarbeidet,
d. vilkårene for arbeidstakerens hjemreise, herunder utgiftsdekning.

(2) Når en norsk virksomhet i forbindelse med tjenesteyting sender ut en arbeidstaker til et annet land innenfor EØS-området, skal informasjonen nevnt i første ledd i tillegg omfatte følgende:
a. den lønnen arbeidstaker har krav på etter gjeldende rett i vertslandet,
b. eventuelle ytelser som spesifikt vedrører utsendelsen, og eventuelle ordninger for godtgjørelse av utgifter til reise, kost og losji der dette er relevant,
c. lenke til det sentrale offisielle nasjonale nettstedet som er etablert i vertslandet etter direktiv 2014/67/EU artikkel 5 andre ledd.

(3) Informasjon som nevnt i første ledd bokstav b og andre ledd bokstav a kan gis i form av en henvisning til lover, forskrifter eller tariffavtaler som regulerer disse forholdene.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96929, 'lov/2005-06-17-62', 114, 15, 'kapittel-15-paragraf-12', '§ 14-8', 'Endringer i arbeidsforholdet', 'Endringer i arbeidsforholdet som nevnt i §§ 14-6 og 14-7 skal tas inn i arbeidsavtalen tidligst mulig og senest den dagen endringen trer i kraft. Dette gjelder likevel ikke dersom endringene i arbeidsforholdet skyldes endringer i lover, forskrifter eller tariffavtaler, jf. § 14-6 andre ledd og § 14-7 tredje ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96930, 'lov/2005-06-17-62', 115, 15, 'kapittel-15-paragraf-13', '§ 14-8 a', 'Forespørsel om mer forutsigbare og trygge arbeidsvilkår', '(1) Dersom en arbeidstaker som arbeider deltid eller er midlertidig ansatt, ber om en ansettelsesform med mer forutsigbare og trygge arbeidsvilkår, skal arbeidsgiver gi et skriftlig og begrunnet svar innen en måned etter at forespørselen fant sted.

(2) Retten til skriftlig svar etter denne bestemmelsen gjelder for arbeidstaker som har vært ansatt i virksomheten i mer enn seks måneder, og som er ferdig med eventuell prøvetid. Retten gjelder ikke hvis det er gått mindre enn seks måneder siden arbeidstakers forrige forespørsel etter bestemmelsen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96931, 'lov/2005-06-17-62', 116, 15, 'kapittel-15-paragraf-14', '§ 14-9', 'Fast og midlertidig ansettelse', '(1) Arbeidstaker skal ansettes fast. Med fast ansettelse menes i denne lov at ansettelsen er løpende og tidsubegrenset, at lovens regler om opphør av arbeidsforhold gjelder, og at arbeidstaker sikres forutsigbarhet for arbeid i form av et reelt stillingsomfang.

(2) Avtale om midlertidig ansettelse kan likevel inngås
a. når arbeidet er av midlertidig karakter
b. for arbeid i stedet for en annen eller andre (vikariat)
c. for praksisarbeid
d. med deltaker i arbeidsmarkedstiltak i regi av eller i samarbeid med arbeids- og velferdsetaten
e. med idrettsutøvere, idrettstrenere, dommere og andre ledere innen den organiserte idretten

(3) Departementet kan i forskrift gi nærmere bestemmelser om midlertidig ansettelse for praksisarbeid og om hvilke typer arbeidsmarkedstiltak som omfattes av andre ledd bokstav d.

(4) Landsomfattende arbeidstakerorganisasjon kan inngå tariffavtale med en arbeidsgiver eller en arbeidsgiverforening om adgang til midlertidig ansettelse innenfor en nærmere angitt arbeidstakergruppe som skal utføre kunstnerisk arbeid, forskningsarbeid eller arbeid i forbindelse med idrett. Dersom tariffavtalen er bindende for et flertall av arbeidstakerne innenfor en nærmere angitt arbeidstakergruppe i virksomheten, kan arbeidsgiver på samme vilkår inngå midlertidig arbeidsavtale med andre arbeidstakere som skal utføre tilsvarende arbeid.

(5) Arbeidstaker som har vært ansatt i mer enn ett år, har krav på skriftlig varsel om tidspunktet for fratreden senest en måned før fratredelsestidspunktet. Dette gjelder likevel ikke deltaker i arbeidsmarkedstiltak som omfattes av tredje ledd, jf. andre ledd bokstav d. Varselet skal anses for å være gitt når det er kommet fram til arbeidstakeren. Dersom fristen ikke overholdes, kan arbeidsgiver ikke kreve at arbeidstakeren fratrer før en måned etter at varsel er gitt.

(6) Midlertidige arbeidsavtaler opphører ved det avtalte tidsrommets utløp, eller når det bestemte arbeidet er avsluttet, med mindre noe annet er skriftlig avtalt eller fastsatt i tariffavtale. I avtaleperioden gjelder lovens regler om opphør av arbeidsforhold.

(7) Arbeidstaker som har vært sammenhengende midlertidig ansatt i mer enn tre år etter andre ledd bokstav a, b, tidligere f eller noen av disse i kombinasjon, skal anses som fast ansatt slik at reglene om oppsigelse av arbeidsforhold kommer til anvendelse. Ved beregning av ansettelsestid skal det ikke gjøres fradrag for arbeidstakers fravær.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96932, 'lov/2005-06-17-62', 117, 15, 'kapittel-15-paragraf-15', '§ 14-10', 'Åremål', '(1) Øverste leder i en virksomhet kan ansettes på åremål.

(2) Ansettelse på åremål kan avtales når dette anses nødvendig som følge av overenskomst med fremmed stat eller internasjonal organisasjon.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96933, 'lov/2005-06-17-62', 118, 15, 'kapittel-15-paragraf-16', '§ 14-11', 'Virkninger av brudd på reglene om fast og midlertidig ansettelse', '(1) Dersom det foreligger brudd på bestemmelsene i §§ 14-9 eller 14-10, skal retten etter påstand fra arbeidstaker avsi dom for at det foreligger et fast arbeidsforhold eller at arbeidsforholdet fortsetter, i samsvar med § 14-9 første ledd. I særlige tilfeller kan retten likevel, etter påstand fra arbeidsgiver, bestemme at arbeidsforholdet skal opphøre dersom den etter en avveining av partenes interesser finner at det vil være åpenbart urimelig at arbeidsforholdet fortsetter.

(2) Ved brudd på bestemmelsene i §§ 14-9 eller 14-10 kan arbeidstakeren kreve erstatning. Erstatningen fastsettes i samsvar med § 15-12 andre ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96934, 'lov/2005-06-17-62', 119, 15, 'kapittel-15-paragraf-17', '§ 14-12', 'Innleie fra virksomhet som har til formål å drive utleie (bemanningsforetak)', '(1) Innleie av arbeidstaker fra virksomhet som har til formål å drive utleie, er tillatt i samme utstrekning som det kan avtales midlertidig ansettelse etter § 14-9 andre ledd bokstav b til e.

(2) I virksomhet som er bundet av tariffavtale inngått med fagforening med innstillingsrett etter arbeidstvistloven kan arbeidsgiver og tillitsvalgte som til sammen representerer et flertall av den arbeidstakerkategori innleien gjelder, inngå skriftlig avtale om tidsbegrenset innleie uten hinder av det som er bestemt i første ledd. Virksomheten og bemanningsforetaket skal på forespørsel fra Arbeidstilsynet fremlegge dokumentasjon på at innleievirksomheten er bundet av tariffavtale inngått med fagforening med innstillingsrett og at det er inngått avtale med de tillitsvalgte som nevnt i første punktum.

(3) Arbeidstaker som har vært sammenhengende innleid etter denne paragraf i mer enn tre år, har rett til fast ansettelse hos innleier slik at reglene om oppsigelse av arbeidsforhold kommer til anvendelse. Ved beregningen skal det ikke gjøres fradrag for arbeidstakers fravær.

(4) Ved vurderingen av om en oppdragsavtale mellom to virksomheter innebærer innleie, skal det særlig legges vekt på om oppdragsgiver har ledelsen av arbeidet og ansvar for resultatet. Andre relevante forhold er blant annet om det i hovedsak skal leveres arbeidskraft, om arbeidet skjer i nær tilknytning til oppdragsgivers virksomhet, om arbeidet dekker et vedvarende arbeidskraftbehov hos oppdragsgiver og om arbeidet skjer innenfor oppdragsgivers kjerne- eller hovedaktivitet.

(5) Departementet kan i forskrift forby innleie av visse arbeidstakergrupper eller på visse områder når viktige samfunnshensyn tilsier det.

(6) Departementet kan i forskrift gi regler om tidsbegrenset innleie av helsepersonell for å sikre forsvarlig drift av helse- og omsorgstjenesten, og om tidsbegrenset innleie av spesialkompetanse, som avviker fra bestemmelsen i første ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96935, 'lov/2005-06-17-62', 120, 15, 'kapittel-15-paragraf-18', '§ 14-12 a', 'Likebehandling av lønns- og arbeidsvilkår ved utleie fra bemanningsforetak', '(1) Bemanningsforetaket skal sørge for at utleid arbeidstaker minst sikres de vilkår som ville kommet til anvendelse dersom arbeidstaker hadde vært ansatt hos innleier for å utføre samme arbeid, når det gjelder:
a. arbeidstidens lengde og plassering,
b. overtidsarbeid,
c. varighet og plassering av pauser og hvileperioder,
d. nattarbeid,
e. feriefritid, feriepenger, fridager og godtgjøring på slike dager, og
f. lønn og utgiftsdekning.

(2) Arbeidstaker som blir leid ut, skal ha samme tilgang til felles goder og tjenester hos innleier som virksomhetens egne arbeidstakere, med mindre objektive grunner tilsier noe annet.

(3) Departementet kan i forskrift bestemme om og i hvilken utstrekning bestemmelsene om likebehandling kan fravikes ved tariffavtale. Den generelle beskyttelse av arbeidstakerne må i alle tilfelle respekteres.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96936, 'lov/2005-06-17-62', 121, 15, 'kapittel-15-paragraf-19', '§ 14-12 b', 'Opplysningsplikt og innsynsrett ved leie av arbeidstaker fra bemanningsforetak', '(1) Ved leie av arbeidstaker skal innleier gi bemanningsforetaket de opplysninger som er nødvendige for at bemanningsforetaket skal kunne ivareta kravet om likebehandling i § 14-12 a.

(2) Bemanningsforetaket skal, når arbeidstaker ber om det, gi de opplysninger som er nødvendige for at arbeidstaker skal kunne vurdere om egne lønns- og arbeidsvilkår oppfyller kravet om likebehandling i § 14-12 a.

(3) Bemanningsforetaket skal, når innleier ber om det, dokumentere hvilke lønns- og arbeidsvilkår som er avtalt med arbeidstaker som leies ut til innleier.

(4) Innleier skal, når tillitsvalgte hos innleier ber om det, dokumentere hvilke lønns- og arbeidsvilkår som er avtalt mellom innleid arbeidstaker og dennes arbeidsgiver.

(5) Plikten til å gi opplysninger etter tredje og fjerde ledd gjelder bare vilkår som nevnt i § 14-12 a første ledd. Bemanningsforetak, innleier og tillitsvalgte som mottar opplysninger i medhold av bestemmelsen her, har taushetsplikt om opplysningene. Opplysningene kan bare benyttes til å sikre eller undersøke overholdelse av kravet om likebehandling i § 14-12 a eller til å oppfylle plikter etter bestemmelsen her.

(6) Departementet kan i forskrift gi nærmere regler om innsynsrett, opplysningsplikt og taushetsplikt etter denne paragraf, samt om taushetsplikt for innleide arbeidstakere. Departementet kan i forskrift også gi regler om eventuell bruk av rådgivere og taushetsplikt for disse.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96937, 'lov/2005-06-17-62', 122, 15, 'kapittel-15-paragraf-20', '§ 14-12 c', 'Solidaransvar for innleier', '(1) Virksomheter som leier inn arbeidstaker etter § 14-12, hefter på samme måte som en selvskyldnerkausjonist for utbetaling av lønn, feriepenger og eventuell annen godtgjøring etter kravet om likebehandling i § 14-12 a, inkludert krav som følger av tariffavtale som nevnt i § 14-12 a tredje ledd. Ved solidaransvar etter første punktum hefter solidaransvarlig også for feriepenger opptjent i tilknytning til kravet.

(2) Arbeidstaker må fremme skriftlig krav overfor innleievirksomheten senest innen tre måneder etter kravets forfallsdato. Solidaransvarlig skal betale kravet innen tre uker etter at kravet er kommet frem.

(3) Solidaransvarlig kan nekte å dekke kravet dersom arbeidstakeren visste at forutsetningen for arbeidsoppdraget var at lønn mv. helt eller delvis skal dekkes av den solidaransvarlige.

(4) Solidaransvaret gjelder ikke når det er åpnet konkurs i bemanningsforetaket.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96938, 'lov/2005-06-17-62', 123, 15, 'kapittel-15-paragraf-21', '§ 14-13', 'Innleie fra virksomhet som ikke har til formål å drive utleie', '(1) Innleie fra virksomhet som ikke har til formål å drive utleie, er tillatt når den innleide arbeidstaker er fast ansatt hos utleier. For at virksomheten skal sies ikke å ha til formål å drive utleie, er det et vilkår at utleie skjer innenfor de samme fagområder som utgjør utleierens hovedbeskjeftigelse og at utleieaktiviteten ikke omfatter mer enn 50 prosent av de fast ansatte hos utleier. Innleier skal foreta drøftelser med tillitsvalgte som til sammen representerer et flertall av den arbeidstakerkategori innleien gjelder, før beslutning om innleie foretas.

(2) For innleie som overstiger 10 prosent av de ansatte hos innleier, likevel ikke færre enn tre personer, eller som har en varighet ut over ett år, skal det inngås skriftlig avtale med tillitsvalgte som til sammen representerer et flertall av den arbeidstakerkategori innleien gjelder. Dette gjelder ikke for innleie innenfor samme konsern.

(3) Etter krav fra tillitsvalgte som representerer den arbeidstakerkategori innleien gjelder, skal arbeidsgiver dokumentere at vilkårene for innleie etter første ledd er oppfylt.

(4) Departementet kan i forskrift forby innleie av visse arbeidstakergrupper eller på visse områder når viktige samfunnshensyn tilsier det.

(5) § 14-12 fjerde ledd gjelder tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96939, 'lov/2005-06-17-62', 124, 15, 'kapittel-15-paragraf-22', '§ 14-13 a', 'Innleie av avløser fra avløserlag', 'Departementet kan gi forskrift om at reglene om innleie fra bemanningsforetak ikke skal gjelde når jordbruksforetak leier inn avløser fra avløserlag, og om særregler ved slik innleie.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96940, 'lov/2005-06-17-62', 125, 15, 'kapittel-15-paragraf-23', '§ 14-14', 'Virkninger av ulovlig innleie av arbeidstaker', '(1) Dersom det foreligger brudd på bestemmelsene i § 14-12, skal retten etter påstand fra den innleide arbeidstakeren avsi dom for at den innleide har et fast arbeidsforhold hos innleier i samsvar med § 14-9 første ledd. I særlige tilfeller kan retten likevel, etter påstand fra innleier, bestemme at den innleide arbeidstakeren ikke har et fast arbeidsforhold dersom den etter en avveining av partenes interesser finner at dette vil være åpenbart urimelig.

(2) Ved brudd på bestemmelsene i § 14-12 kan den innleide arbeidstaker kreve erstatning fra innleier. Erstatningen fastsettes i samsvar med § 15-12 andre ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96941, 'lov/2005-06-17-62', 126, 15, 'kapittel-15-paragraf-24', '§ 14-14 a', 'Drøfting om ansettelse mv.', 'Arbeidsgiver skal minst én gang i året, eller når en av partene krever det, drøfte med de tillitsvalgte bruken av deltid, midlertidig ansettelse, innleie, selvstendige oppdragstakere og tjenestekjøp fra andre virksomheter som har betydning for bemanningen. I drøftingen skal blant annet grunnlaget, omfanget og konsekvensene for arbeidsmiljøet inngå. Ved innleie fra bemanningsforetak skal også praktiseringen av kravet om likebehandling drøftes, jf. § 14-12 a.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96942, 'lov/2005-06-17-62', 127, 15, 'kapittel-15-paragraf-25', '§ 14-15', 'Utbetaling av lønn og feriepenger', '(1) Hvis ikke annet er avtalt skal det foretas lønnsutbetaling minst to ganger i måneden. Utbetalingstiden for feriepenger reguleres av ferieloven.

(2) Lønn i penger, herunder feriepenger og annen godtgjøring i penger, skal utbetales fra arbeidsgiver via bank eller foretak med rett til å drive betalingsformidling til arbeidstakers konto. Første punktum gjelder likevel ikke dersom slik betalingsmåte er umulig eller svært byrdefull for arbeidstaker eller arbeidsgiver.

(3) Trekk i lønn og feriepenger kan ikke gjøres unntatt:
a. når det er hjemlet i lov,
b. for arbeidstakers egenandel til tjenestepensjonsordninger som er omfattet av foretakspensjonsloven, innskuddspensjonsloven eller offentlige tjenestepensjonsordninger.
c. når det på forhånd er fastsatt ved skriftlig avtale,
d. når det ved tariffavtale er fastsatt regler om lønnstrekk for fagforeningskontingent, herunder premie til kollektiv forsikring som er knyttet til medlemskap i fagforening, eller avgift til opplysnings- og utviklingsfond, eller til lavtlønnsfond,
e. når det gjelder erstatning for skade eller tap som arbeidstaker i forbindelse med arbeidet forsettlig eller ved grov uaktsomhet har påført virksomheten, og arbeidstaker skriftlig erkjenner erstatningsansvar, eller dette er fastslått ved dom, eller arbeidstaker rettsstridig fratrer sin stilling,
f. når det på grunn av gjeldende rutiner for beregning og utbetaling av lønn ikke har vært praktisk mulig å ta hensyn til fravær på grunn av arbeidsnedleggelse eller arbeidsstengning i avregningsperioden.

(4) Trekk i lønn eller feriepenger etter tredje ledd bokstav c, e og f skal begrenses til den del av kravet som overstiger det arbeidstaker med rimelighet trenger til underhold for seg og sin husstand.

(5) Før trekk etter tredje ledd bokstav e foretas, skal arbeidsgiver drøfte grunnlaget for trekket og beløpets størrelse med arbeidstaker og med arbeidstakers tillitsvalgte med mindre arbeidstaker selv ikke ønsker det.

(6) Ved utbetalingen eller straks etter denne skal arbeidstaker ha skriftlig oppgave over beregningsmåten for lønn, beregningsgrunnlaget for feriepenger og trekk som er foretatt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96943, 'lov/2005-06-17-62', 128, 15, 'kapittel-15-paragraf-26', '§ 14-16', 'Arbeidsreglement', '(1) Ved industriell virksomhet og ved handels- og kontorvirksomhet, som sysselsetter mer enn 10 arbeidstakere, skal det for de arbeidstakere som ikke har en ledende eller kontrollerende stilling, være arbeidsreglement. Departementet kan bestemme at arbeidsreglement skal utarbeides i andre virksomheter for andre arbeidstakere enn nevnt foran. Reglementet skal inneholde de ordensregler som trengs og regler for arbeidsordningen. Reglementet må ikke inneholde bestemmelser som er i strid med loven.

(2) I arbeidsreglementet kan ikke fastsettes bøter for forseelser mot reglementet. Ved virksomhet som ikke kommer inn under første ledd kan det fastsettes arbeidsreglement. §§ 14-17 til 14-20 skal i tilfelle gjelde tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96944, 'lov/2005-06-17-62', 129, 15, 'kapittel-15-paragraf-27', '§ 14-17', 'Fastsettelse av arbeidsreglement', '(1) Ved virksomhet som er bundet av tariffavtale, kan arbeidsgiveren og arbeidstakernes tillitsvalgte fastsette arbeidsreglement ved skriftlig avtale. Er avtalen bindende for et flertall av arbeidstakerne, kan arbeidsgiveren gjøre reglementet gjeldende for alle arbeidstakere innenfor de arbeidsområder avtalen gjelder for.

(2) Når ikke bestemmelsene i første ledd får anvendelse, må arbeidsreglementet for å bli gyldig, godkjennes av Arbeidstilsynet. Utkast til reglement skal utarbeides av arbeidsgiveren som skal forhandle med representanter for arbeidstakerne om reglementets bestemmelser. Er virksomheten bundet av tariffavtale, skal arbeidsgiveren forhandle med arbeidstakernes tillitsvalgte. Ellers skal arbeidstakerne velge fem representanter som arbeidsgiveren skal forhandle med. Setter arbeidstakernes representanter fram avvikende forslag til reglement, skal dette vedlegges når arbeidsgiveren sender inn utkastet til godkjenning. Unnlater arbeidstakernes representanter å forhandle om reglementet, skal arbeidsgiveren opplyse om dette når utkastet sendes inn til godkjenning.

(3) Reglementet skal slås opp på ett eller flere iøynefallende steder i virksomheten og deles ut til hver arbeidstaker som reglementet gjelder for.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96945, 'lov/2005-06-17-62', 130, 15, 'kapittel-15-paragraf-28', '§ 14-18', 'Frist for innsendelse av arbeidsreglement', 'Arbeidsgiveren skal ta initiativ til å få fastsatt reglement ved avtale etter § 14-17 første ledd eller sørge for å utarbeide utkast etter § 14-17 andre ledd så snart som mulig. Reglementsutkast etter § 14-17 andre ledd skal sendes Arbeidstilsynet senest tre måneder etter at virksomheten er satt i gang.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96946, 'lov/2005-06-17-62', 131, 15, 'kapittel-15-paragraf-29', '§ 14-19', 'Arbeidsreglementets gyldighet', '(1) Arbeidsreglementet er bare gyldig når det er istandbrakt på lovlig måte og når det ikke inneholder bestemmelser som strider mot loven.

(2) Dersom utkast etter § 14-17 andre ledd inneholder bestemmelser som strider mot loven eller er ubillige overfor arbeidstakerne, eller dersom utkastet ikke er istandbrakt på lovlig måte, skal Arbeidstilsynet nekte å godkjenne det.

(3) Dersom et reglement fastsatt ved avtale etter § 14-17 første ledd inneholder bestemmelser som strider mot loven, skal Arbeidstilsynet gjøre partene i avtalen oppmerksom på dette, og påse at bestemmelsene blir rettet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96947, 'lov/2005-06-17-62', 132, 15, 'kapittel-15-paragraf-30', '§ 14-20', 'Endringer i arbeidsreglement', 'Reglene i §§ 14-16 til 14-19 gjelder tilsvarende når det skal gjøres endring i eller tillegg til arbeidsreglement.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96948, 'lov/2005-06-17-62', 133, 16, 'kapittel-16-paragraf-1', '§ 14 A-1', 'Konkurranseklausuler', '(1) Med konkurranseklausul menes i dette kapittel avtale mellom arbeidsgiver og arbeidstaker som begrenser arbeidstakers adgang til å tiltre stilling hos en annen arbeidsgiver eller starte, drive eller delta i annen virksomhet etter arbeidsforholdets opphør.

(2) En konkurranseklausul kan bare gjøres gjeldende så langt det er nødvendig for å ivareta arbeidsgivers særlige behov for vern mot konkurranse. Klausulen kan ikke i noe tilfelle gjøres gjeldende lenger enn ett år fra opphør av arbeidsforholdet.

(3) Konkurranseklausul må inngås skriftlig for å være gyldig.

(4) En konkurranseklausul kan ikke gjøres gjeldende ved oppsigelse fra arbeidsgiver, med mindre oppsigelsen er saklig begrunnet i arbeidstakers forhold. Det samme gjelder dersom arbeidsgiver på grunn av mislighold av forpliktelser i arbeidsforholdet har gitt arbeidstaker rimelig grunn til å avslutte arbeidsforholdet.

(5) Arbeidsgiver kan på ethvert tidspunkt mens arbeidsforholdet består, skriftlig si opp en konkurranseklausul. Oppsigelse kan likevel ikke skje i den perioden arbeidsgiver er bundet av redegjørelse etter § 14 A-2 femte ledd. Etter arbeidsforholdets opphør kan arbeidsgiver og arbeidstaker inngå skriftlig avtale om at en konkurranseklausul ikke lenger skal gjelde.

(6) En konkurranseklausul faller bort dersom kravet til redegjørelse etter § 14 A-2 ikke blir oppfylt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96949, 'lov/2005-06-17-62', 134, 16, 'kapittel-16-paragraf-2', '§ 14 A-2', 'Redegjørelse ved konkurranseklausuler', '(1) Ved skriftlig forespørsel fra arbeidstaker skal arbeidsgiver innen fire uker gi en skriftlig redegjørelse for om og i hvilken grad en konkurranseklausul vil bli gjort gjeldende. Arbeidsgivers særlige behov for vern mot konkurranse skal i tilfelle fremgå av redegjørelsen.

(2) Dersom arbeidstakeren sier opp, og det ikke allerede foreligger en bindende redegjørelse, skal oppsigelsen ha samme virkning som en skriftlig forespørsel etter første ledd.

(3) Dersom arbeidsgiveren sier opp arbeidstakeren, og det ikke allerede foreligger en bindende redegjørelse, skal det gis redegjørelse samtidig med oppsigelsen.

(4) Dersom arbeidsgiveren avskjediger arbeidstakeren, og det ikke allerede foreligger en bindende redegjørelse, skal det gis redegjørelse innen en uke etter avskjeden.

(5) Redegjørelse etter denne paragrafen er bindende for arbeidsgiver i tre måneder. Ved oppsigelse er redegjørelsen uansett bindende ut oppsigelsestiden.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96950, 'lov/2005-06-17-62', 135, 16, 'kapittel-16-paragraf-3', '§ 14 A-3', 'Kompensasjon dersom konkurranseklausuler gjøres gjeldende', '(1) Dersom en konkurranseklausul gjøres gjeldende, skal arbeidsgiver betale arbeidstakeren kompensasjon tilsvarende 100 prosent av arbeidstakerens arbeidsvederlag opp til 8 G, og deretter minst 70 prosent av arbeidstakerens arbeidsvederlag over 8 G. Kompensasjonen beregnes på grunnlag av opptjent arbeidsvederlag de siste 12 månedene før oppsigelses- eller avskjedstidspunktet. Kompensasjonen kan begrenses til 12 ganger folketrygdens grunnbeløp.

(2) Det kan gjøres fradrag med inntil halvparten av kompensasjonen for arbeidsvederlag eller arbeidsinntekt som arbeidstaker mottar eller opptjener i perioden konkurranseklausulen har virkning.

(3) Arbeidsgiver kan kreve at arbeidstaker opplyser om arbeidsvederlag eller arbeidsinntekter i perioden. Dersom arbeidstaker ikke etterkommer kravet, kan arbeidsgiver holde tilbake kompensasjon inntil opplysningene legges fram.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96951, 'lov/2005-06-17-62', 136, 16, 'kapittel-16-paragraf-4', '§ 14 A-4', 'Kundeklausuler', '(1) Med kundeklausul menes i dette kapittel avtale mellom arbeidsgiver og arbeidstaker som begrenser arbeidstakers adgang til å kontakte arbeidsgivers kunder etter arbeidsforholdets opphør.

(2) En kundeklausul kan bare omfatte kunder som arbeidstaker har hatt kontakt med eller ansvar for det siste året før redegjørelse som nevnt i tredje ledd. Klausulen kan ikke i noe tilfelle gjøres gjeldende lenger enn ett år fra opphør av arbeidsforholdet. § 14 A-1 tredje til sjette ledd gjelder tilsvarende.

(3) Ved skriftlig forespørsel fra arbeidstaker skal arbeidsgiver innen fire uker gi en skriftlig redegjørelse for om og i hvilken grad en kundeklausul vil bli gjort gjeldende. Redegjørelsen skal i tilfelle angi hvilke kunder som skal omfattes av kundeklausulen. § 14 A-2 andre til femte ledd gjelder tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96952, 'lov/2005-06-17-62', 137, 16, 'kapittel-16-paragraf-5', '§ 14 A-5', 'Unntak for virksomhetens øverste leder', 'Reglene om konkurranse- og kundeklausuler i dette kapittel gjelder ikke for virksomhetens øverste leder dersom vedkommende i skriftlig avtale har sagt fra seg slike rettigheter mot etterlønn før fratreden.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96953, 'lov/2005-06-17-62', 138, 16, 'kapittel-16-paragraf-6', '§ 14 A-6', 'Rekrutteringsklausuler', '(1) Med rekrutteringsklausul menes i dette kapittel avtale mellom arbeidsgiver og andre virksomheter som hindrer eller begrenser arbeidstakers muligheter til å ta ansettelse i annen virksomhet.

(2) Arbeidsgiver kan ikke inngå rekrutteringsklausul. En rekrutteringsklausul kan likevel inngås ved forhandlinger om virksomhetsoverdragelse, og gjøres gjeldende under forhandlingene og i inntil seks måneder etter at forhandlingene er avsluttet, dersom disse ikke fører frem. En rekrutteringsklausul kan også inngås fra tidspunktet for virksomhetsoverdragelsen og gjøres gjeldende i inntil seks måneder, dersom arbeidsgiver skriftlig har informert alle berørte arbeidstakere.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96954, 'lov/2005-06-17-62', 139, 17, 'kapittel-17-paragraf-1', '§ 15-1', 'Drøfting før beslutning om oppsigelse', 'Før arbeidsgiver fatter beslutning om oppsigelse, skal spørsmålet så langt det er praktisk mulig drøftes med arbeidstaker og med arbeidstakers tillitsvalgte, med mindre arbeidstaker selv ikke ønsker det. Både grunnlaget for oppsigelsen og eventuell utvelgelse mellom flere ansatte av hvem som skal sies opp, skal drøftes.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96955, 'lov/2005-06-17-62', 140, 17, 'kapittel-17-paragraf-2', '§ 15-2', 'Informasjon og drøfting ved masseoppsigelser', '(1) Med masseoppsigelser menes oppsigelser som foretas overfor minst 10 arbeidstakere innenfor et tidsrom på 30 dager, uten at oppsigelsene er begrunnet i de enkelte arbeidstakeres forhold. Andre former for opphør av arbeidskontrakter som ikke er begrunnet i de enkelte arbeidstakeres forhold, skal tas med i beregningen såfremt minst fem sies opp.

(2) Arbeidsgiver som vurderer å gå til masseoppsigelser, skal så tidlig som mulig innlede drøftinger med arbeidstakernes tillitsvalgte med sikte på å komme fram til en avtale for å unngå masseoppsigelser eller for å redusere antall oppsagte. Vurderer arbeidsgiver å legge ned virksomheten eller en selvstendig del av denne, og nedleggelsen innebærer en masseoppsigelse, skal også muligheten for videre drift drøftes, herunder om mulighetene for de ansattes overtakelse av virksomheten. Dersom oppsigelser ikke kan unngås, skal de uheldige sidene ved dem søkes redusert. Drøftingene skal omfatte mulige sosiale tiltak med sikte på blant annet støtte til omplassering eller omskolering av de oppsagte. Arbeidstakernes tillitsvalgte kan la seg bistå av sakkyndige. Arbeidsgiver har plikt til å innlede drøftinger selv om de planlagte oppsigelsene skyldes andre enn arbeidsgiver og som har beslutningsmyndighet overfor denne, f.eks. en konsernledelse.

(3) Arbeidsgiver har plikt til å gi tillitsvalgte alle relevante opplysninger, herunder skriftlig melding om:
a. grunnene til eventuelle oppsigelser,
b. antall arbeidstakere som vil kunne bli oppsagt,
c. hvilke arbeidsgrupper de tilhører,
d. antall arbeidstakere som normalt er ansatt,
e. hvilke arbeidstakergrupper som normalt er sysselsatt,
f. over hvilken periode oppsigelsene vil kunne bli foretatt,
g. forslag til kriterier for utvelgelse av de som eventuelt skal sies opp,
h. forslag til kriterier for beregning av eventuelle ekstraordinære sluttvederlag.
Meldingen skal gis tidligst mulig og senest samtidig med at arbeidsgiver innkaller til drøftinger. Tilsvarende melding skal også gis til Arbeids- og velferdsetaten, jf. arbeidsmarkedsloven § 8.

(4) Arbeidstakernes tillitsvalgte kan kommentere meldingen direkte overfor Arbeids- og velferdsetaten.

(5) Planlagte masseoppsigelser får tidligst virkning 30 dager etter at Arbeids- og velferdsetaten er underrettet. Arbeids- og velferdsetaten kan forlenge fristen i henhold til arbeidsmarkedsloven § 8 tredje ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96956, 'lov/2005-06-17-62', 141, 17, 'kapittel-17-paragraf-3', '§ 15-3', 'Oppsigelsesfrister', '(1) Hvis ikke annet er skriftlig avtalt eller fastsatt i tariffavtale, gjelder en gjensidig oppsigelsesfrist på én måned. Før oppsigelse har funnet sted, kan avtale om kortere oppsigelsesfrist bare inngås mellom arbeidsgiveren og tillitsvalgte ved virksomhet som er bundet av tariffavtale. Departementet kan gi forskrift om kortere oppsigelsesfrist for deltakere i arbeidsmarkedstiltak.

(2) For arbeidstaker som har vært ansatt i minst fem år sammenhengende i samme virksomhet når oppsigelsen gis, gjelder en gjensidig oppsigelsesfrist på minst to måneder. Har arbeidstakeren vært ansatt i minst 10 år sammenhengende i samme virksomhet, er den gjensidige oppsigelsesfristen minst tre måneder.

(3) Blir arbeidstaker sagt opp etter minst 10 års sammenhengende ansettelse i samme virksomhet, skal oppsigelsesfristen være minst fire måneder dersom den finner sted etter at arbeidstakeren er fylt 50 år, minst fem måneder etter fylte 55 år og minst seks måneder etter fylte 60 år. Arbeidstakeren kan si opp arbeidsavtalen med en oppsigelsesfrist på minst tre måneder.

(4) Oppsigelsesfrister som er fastsatt i første til tredje ledd løper fra og med første dag i måneden etter at oppsigelsen fant sted.

(5) Den sammenhengende ansettelse som kreves i andre og tredje ledd avbrytes ikke ved midlertidig fratreden i henhold til oppsigelse på grunn av lovlig arbeidskamp. Den tid arbeidstakeren er fraværende skal likevel ikke medregnes, med mindre noe annet avtales ved arbeidskampens avslutning.

(6) Ved beregning av ansettelsestid etter denne paragraf skal medregnes den tid arbeidstakeren har vært ansatt i annen virksomhet innenfor konsern som arbeidsgiver tilhører eller innenfor annen gruppe av virksomheter som er knyttet sammen gjennom eierinteresser eller felles ledelse på en slik måte at det er naturlig å se ansettelsesforholdene i sammenheng. Har virksomheten eller del av den blitt overdratt eller leiet ut til ny arbeidsgiver, skal også medregnes den tid arbeidstakeren har vært ansatt hos den tidligere arbeidsgiver eller i virksomhet innenfor konsern eller gruppe av virksomheter som den tidligere arbeidsgiver tilhørte.

(7) Ved arbeidsavtaler der arbeidstaker skriftlig er ansatt på en bestemt prøvetid, gjelder en gjensidig oppsigelsesfrist på 14 dager, med mindre noe annet er skriftlig avtalt eller fastsatt i tariffavtale.

(8) Partene kan ikke ved tariffavtale eller annen avtale fravike oppsigelsesfristene i andre eller tredje ledd før oppsigelse har funnet sted, eller bestemme at oppsigelsesfristen ved oppsigelse fra arbeidstakerens side skal være lenger enn ved oppsigelse fra arbeidsgiverens side.

(9) Arbeidstaker som er permittert uten lønn i forbindelse med driftsinnskrenkning eller driftsstans, kan gå til oppsigelse med en oppsigelsesfrist på 14 dager regnet fra den dag oppsigelsen blir mottatt av arbeidsgiver. Dette gjelder uansett hvilken oppsigelsesfrist som følger av loven eller avtale.

(10) Dersom ulykker, naturhendelser eller andre uforutsette hendelser gjør det nødvendig helt eller delvis å innstille driften, og arbeidstaker derfor sies opp, kan oppsigelsesfristen overfor arbeidstakere ved det arbeid som må innstilles, settes ned til 14 dager regnet fra hendelsen. Er gjeldende oppsigelsesfrist kortere enn 14 dager, gjelder denne. Oppsigelsesfristen kan ikke settes ned etter dette ledd ved arbeidsgivers død eller konkurs, og heller ikke ved arbeidsstans som skyldes at arbeidsrom, maskiner, redskap, arbeidsmaterialer eller andre hjelpemidler som arbeidsgiver skal stille til rådighet, ikke kan brukes, med mindre arbeidstakeren selv er skyld i arbeidsstansen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96957, 'lov/2005-06-17-62', 142, 17, 'kapittel-17-paragraf-4', '§ 15-4', 'Formkrav ved oppsigelse', '(1) Oppsigelse skal skje skriftlig.

(2) Oppsigelse fra arbeidsgivers side skal leveres til arbeidstaker personlig eller sendes i rekommandert brev til arbeidstakers oppgitte adresse. Oppsigelsen skal anses for å ha funnet sted når den er kommet fram til arbeidstaker. Oppsigelsen skal inneholde opplysninger om
a. arbeidstakers rett til å kreve forhandling og reise søksmål,
b. retten til å fortsette i stillingen etter bestemmelsene i §§ 17-3, 17-4 og 15-11,
c. de frister som gjelder for å kreve forhandling, reise søksmål og for å fortsette i stillingen, og
d. hvem som er arbeidsgiver og rett saksøkt i en eventuell tvist.
Er oppsigelsen begrunnet i virksomhetens forhold, skal den inneholde opplysninger om fortrinnsrett etter § 14-2. Tilhører arbeidsgiver et konsern, skal oppsigelsen også opplyse om hvilke foretak som inngår i konsernet på oppsigelsestidspunktet.

(3) Dersom arbeidstaker krever det, skal arbeidsgiver oppgi de omstendigheter som påberopes som grunn for oppsigelsen. Arbeidstaker kan kreve å få opplysningene skriftlig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96958, 'lov/2005-06-17-62', 143, 17, 'kapittel-17-paragraf-5', '§ 15-5', 'Virkninger av formfeil ved oppsigelse', '(1) Dersom arbeidsgivers oppsigelse ikke er gitt skriftlig eller ikke inneholder opplysninger som nevnt i § 15-4 og arbeidstaker går til søksmål innen 4 måneder etter at oppsigelsen fant sted, skal oppsigelsen kjennes ugyldig, med mindre særlige omstendigheter gjør dette åpenbart urimelig.

(2) Er oppsigelsen ugyldig, kan arbeidstaker kreve erstatning. Det samme gjelder dersom oppsigelsen er mangelfull, men arbeidstaker ikke krever dom for ugyldighet eller det ikke blir avsagt dom for ugyldighet fordi særlige omstendigheter gjør dette åpenbart urimelig, jf. første ledd. Erstatningen fastsettes i samsvar med § 15-12 andre ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96959, 'lov/2005-06-17-62', 144, 17, 'kapittel-17-paragraf-6', '§ 15-6', 'Oppsigelsesvern i arbeidsavtaler med bestemt prøvetid', '(1) Blir arbeidstaker som skriftlig er ansatt på en bestemt prøvetid, sagt opp, må oppsigelsen være begrunnet i arbeidstakers tilpasning til arbeidet, faglige dyktighet eller pålitelighet.

(2) Bestemmelsene i paragrafen her innskrenker ikke arbeidsgivers rett til å si opp arbeidstaker etter § 15-7.

(3) Bestemmelsene i paragrafen her gjelder bare dersom oppsigelsen blir gitt innen utløpet av den avtalte prøvetiden. Prøvetid kan avtales for en periode på inntil seks måneder. Ved midlertidig ansettelse kan prøvetiden ikke overstige halvparten av ansettelsesforholdets varighet. Prøvetiden etter dette leddet kan likevel forlenges etter fjerde ledd.

(4) Dersom arbeidstaker har vært fraværende fra arbeidet i prøvetiden, kan arbeidsgiver forlenge den avtalte prøvetiden med en periode som tilsvarer lengden av fraværet. Forlengelse kan bare skje når arbeidstaker ved ansettelsen er skriftlig orientert om adgangen til dette og arbeidsgiver skriftlig har orientert arbeidstaker om forlengelsen innen utløpet av prøvetiden. Det er ikke adgang til forlengelse ved fravær som er forårsaket av arbeidsgiver.

(5) Det kan ikke avtales ny prøvetid dersom arbeidstaker skal fortsette i samme stilling eller i en stilling som i det vesentlige er likeartet stillingen arbeidstakeren har hatt i samme virksomhet. Ved fast ansettelse kan ny prøvetid likevel avtales dersom arbeidstakerens tidligere ansettelsestid og ny prøvetid samlet ikke overstiger seks måneder.

(6) Departementet kan gi forskrift om adgang til å avtale lengre prøvetid enn seks måneder for visse arbeidstakergrupper.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96960, 'lov/2005-06-17-62', 145, 17, 'kapittel-17-paragraf-7', '§ 15-7', 'Vern mot usaklig oppsigelse', '(1) Arbeidstaker kan ikke sies opp uten at det er saklig begrunnet i virksomhetens, arbeidsgivers eller arbeidstakers forhold.

(2) Skyldes oppsigelsen driftsinnskrenkning eller rasjonaliseringstiltak, er den ikke saklig begrunnet dersom arbeidsgiver har et annet passende arbeid i virksomheten å tilby arbeidstaker. Ved avgjørelse av om en oppsigelse har saklig grunn i driftsinnskrenkning eller rasjonaliseringstiltak, skal det foretas en avveining mellom virksomhetens behov og de ulemper oppsigelsen påfører den enkelte arbeidstaker.

(3) Tilhører arbeidsgiver et konsern, jf. § 8-4 fjerde ledd, er ikke oppsigelsen saklig begrunnet dersom det er annet passende arbeid å tilby arbeidstaker i andre virksomheter i konsernet.

(4) En oppsigelse som skyldes at arbeidsgiver setter ut eller tar sikte på å sette ut virksomhetens drift på oppdrag ved bruk av selvstendige oppdragstakere, er ikke saklig med mindre det er nødvendig av hensyn til virksomhetens fortsatte drift.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96961, 'lov/2005-06-17-62', 146, 17, 'kapittel-17-paragraf-8', '§ 15-8', 'Oppsigelsesvern ved sykdom', '(1) Arbeidstaker som helt eller delvis er borte fra arbeidet på grunn av ulykke eller sykdom kan ikke av denne grunn sies opp de første 12 månedene etter at arbeidsuførheten inntrådte.

(2) Oppsigelse som finner sted innenfor det tidsrom arbeidstaker er vernet mot oppsigelse etter denne paragraf, skal anses å ha sin grunn i sykefraværet dersom ikke noe annet gjøres overveiende sannsynlig.

(3) Arbeidstaker som påberoper seg oppsigelsesvern etter denne paragraf, må ved legeattest eller på annen måte innen rimelig tid gi varsel om grunnen til fraværet. Om arbeidsgiver krever det, må det samlede sykefravær godtgjøres ved legeattest.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96962, 'lov/2005-06-17-62', 147, 17, 'kapittel-17-paragraf-9', '§ 15-9', 'Oppsigelsesvern ved svangerskap, og etter fødsel eller adopsjon', '(1) Arbeidstaker som er gravid kan ikke av den grunn sies opp. Oppsigelse som finner sted i denne perioden, skal anses å ha sin grunn i dette forhold dersom ikke noe annet gjøres overveiende sannsynlig. Graviditeten må dokumenteres ved legeattest dersom arbeidsgiver krever det.

(2) Arbeidstaker som har permisjon etter §§ 12-2, 12-3, 12-4 eller 12-5 første ledd i inntil ett år, må ikke sies opp med virkning i fraværsperioden når arbeidsgiver er klar over at fraværet skyldes disse grunner eller arbeidstaker uten unødig opphold gir beskjed om at dette er grunnen for fraværet. Er arbeidstaker lovlig sagt opp til fratreden på et tidspunkt som faller innenfor dette tidsrommet, er oppsigelsen gyldig, men oppsigelsen forlenges med et tilsvarende tidsrom.

(3) For arbeidstaker som har permisjon etter §§ 12-5 andre ledd eller 12-6 utover ett år, gjelder første ledd første og andre punktum tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96963, 'lov/2005-06-17-62', 148, 17, 'kapittel-17-paragraf-10', '§ 15-10', 'Oppsigelsesvern ved militærtjeneste mv.', '(1) Arbeidstaker kan ikke sies opp på grunn av permisjon etter § 12-12. Ved permisjon etter § 12-12 første ledd andre punktum omfatter oppsigelsesvernet også perioder hvor arbeidstaker ikke er fraværende fra arbeidet.

(2) Oppsigelse som finner sted umiddelbart før eller innenfor det tidsrom arbeidstaker er fraværende fra arbeidet på grunn av permisjon etter § 12-12, skal anses å ha sin grunn i dette forholdet, dersom ikke noe annet gjøres overveiende sannsynlig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96964, 'lov/2005-06-17-62', 149, 17, 'kapittel-17-paragraf-11', '§ 15-11', 'Retten til å fortsette i stillingen', '(1) Ved tvist om et arbeidsforhold lovlig er brakt til opphør etter reglene i § 15-7 kan arbeidstaker fortsette i stillingen så lenge forhandlinger pågår etter § 17-3.

(2) Dersom søksmål reises innen de frister som følger av § 17-4, kan arbeidstaker fortsette i stillingen. Etter krav fra arbeidsgiver kan retten likevel bestemme at arbeidstaker skal fratre under sakens behandling dersom retten finner det urimelig at arbeidsforholdet opprettholdes under sakens behandling. Dette gjelder også ved hel eller delvis nedleggelse av virksomheten. Retten fastsetter samtidig fristen for arbeidstakers fratreden.

(3) Retten til å fortsette i stillingen gjelder ikke ved tvist om avskjed, oppsigelse i prøvetiden, for innleid arbeidstaker eller midlertidig ansatt. Etter krav fra arbeidstaker kan retten likevel bestemme at arbeidsforholdet skal fortsette inntil saken er rettskraftig avgjort, dersom søksmål reises innen fristene i § 17-4.

(4) Retten til å fortsette i stillingen gjelder ikke for deltakere i arbeidsmarkedstiltak i regi av eller i samarbeid med Arbeids- og velferdsetaten som sies opp fordi vedkommende skaffes ordinært arbeid, overføres til annet tiltak eller tiltaket avsluttes.

(5) Retten kan bestemme at arbeidstaker som er urettmessig utestengt fra arbeidsplassen etter at oppsigelsesfristen eller tidsrommet for arbeidsavtalen er utløpt, har rett til å gjeninntre i stillingen dersom arbeidstaker ber om dette innen fire uker fra utestengningen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96965, 'lov/2005-06-17-62', 150, 17, 'kapittel-17-paragraf-12', '§ 15-12', 'Virkninger av usaklig oppsigelse mv.', '(1) Dersom oppsigelsen er i strid med §§ 15-6 til 15-10, skal retten, etter påstand fra arbeidstaker, kjenne oppsigelsen ugyldig. I særlige tilfeller kan retten, etter påstand fra arbeidsgiver, bestemme at arbeidsforholdet skal opphøre dersom den etter avveining av partenes interesser finner at det vil være åpenbart urimelig at arbeidsforholdet fortsetter.

(2) Arbeidstaker kan kreve erstatning dersom oppsigelsen er i strid med §§ 15-6 til 15-11. Erstatningen fastsettes til det beløp som retten finner rimelig under hensyn til det økonomiske tap, arbeidsgivers og arbeidstakers forhold og omstendighetene for øvrig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96966, 'lov/2005-06-17-62', 151, 17, 'kapittel-17-paragraf-13', '§ 15-13', 'Suspensjon', '(1) Dersom det er grunn til å anta at en arbeidstaker har gjort seg skyldig i forhold som kan medføre avskjed etter § 15-14 og virksomhetens behov tilsier det, kan arbeidsgiver pålegge arbeidstaker å fratre arbeidsforholdet mens saken undersøkes.

(2) Det skal vurderes fortløpende om vilkårene etter første ledd er oppfylt. Dersom dette ikke er tilfelle, skal suspensjonen straks oppheves. Suspensjon utover tre måneder må være begrunnet i forholdets særlige art.

(3) Arbeidstaker beholder den lønn vedkommende hadde på suspensjonstidspunktet frem til suspensjonen opphører.

(4) Ved suspensjon gjelder bestemmelsene i §§ 15-1, 15-4 og 15-12 tilsvarende så langt de passer.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96967, 'lov/2005-06-17-62', 152, 17, 'kapittel-17-paragraf-14', '§ 15-13 a', 'Opphør av arbeidsforhold grunnet alder', '(1) Arbeidsforholdet kan bringes til opphør når arbeidstaker fyller 72 år.

(2) Lavere aldersgrense kan fastsettes der det er nødvendig av hensyn til helse eller sikkerhet. Den lavere aldersgrensen skal være saklig begrunnet og ikke uforholdsmessig inngripende, jf. § 13-3 andre ledd.

(3) Arbeidstaker har krav på skriftlig varsel om tidspunktet for fratreden. Fratreden kan tidligst kreves seks måneder etter den første dag i måneden etter at varslet er kommet frem til arbeidstaker.

(4) Før varsel gis skal arbeidsgiver så langt det er mulig innkalle arbeidstaker til en samtale, med mindre arbeidstaker selv ikke ønsker det.

(5) Arbeidstaker som ønsker å fratre, har en tilsvarende varslingsfrist på en måned, likevel slik at kravet til skriftlighet ikke gjelder.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96968, 'lov/2005-06-17-62', 153, 17, 'kapittel-17-paragraf-15', '§ 15-14', 'Avskjed', '(1) Arbeidsgiver kan avskjedige en arbeidstaker med påbud om øyeblikkelig fratreden dersom denne har gjort seg skyldig i grovt pliktbrudd eller annet vesentlig mislighold av arbeidsavtalen.

(2) Ved avskjed gjelder bestemmelsene i §§ 15-1 og 15-4 tilsvarende.

(3) Dersom avskjeden er urettmessig, skal retten kjenne den ugyldig etter påstand fra arbeidstaker. I særlige tilfeller kan retten likevel, etter påstand fra arbeidsgiver, bestemme at arbeidsforholdet skal opphøre dersom den etter avveining av partenes interesser finner at det vil være åpenbart urimelig at arbeidsforholdet fortsetter. Retten kan også bestemme at arbeidsforholdet skal opphøre når den finner at vilkårene for saklig oppsigelse er til stede.

(4) Arbeidstaker kan kreve erstatning dersom avskjeden er urettmessig. Erstatningen fastsettes i samsvar med § 15-12 andre ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96969, 'lov/2005-06-17-62', 154, 17, 'kapittel-17-paragraf-16', '§ 15-15', 'Attest', '(1) Arbeidstaker som fratrer etter lovlig oppsigelse har krav på skriftlig attest av arbeidsgiver. Attesten skal inneholde opplysninger om arbeidstakers navn, fødselsdato, hva arbeidet har bestått i og om arbeidsforholdets varighet.

(2) Denne bestemmelse begrenser ikke arbeidstakers rett til å kreve en mer utførlig attest i arbeidsforhold hvor dette er sedvane og ikke annet er fastsatt i tariffavtale.

(3) Arbeidstaker som blir avskjediget har også krav på attest, men arbeidsgiver kan uten nærmere angivelse av grunnen opplyse i attesten at arbeidstakeren er avskjediget.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96970, 'lov/2005-06-17-62', 155, 17, 'kapittel-17-paragraf-17', '§ 15-16', 'Virksomhetens øverste leder', '(1) Arbeidsgiver kan inngå skriftlig avtale med virksomhetens øverste leder om at tvister i forbindelse med opphør av arbeidsforholdet skal løses ved voldgift.

(2) Reglene om oppsigelse i dette kapittel gjelder ikke for virksomhetens øverste leder dersom vedkommende i forhåndsavtale har sagt fra seg slike rettigheter mot etterlønn ved fratreden.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96971, 'lov/2005-06-17-62', 156, 17, 'kapittel-17-paragraf-18', '§ 15-17', 'Oppsigelse ved arbeidskonflikt', 'Bestemmelsene i dette kapittel gjelder ikke ved oppsigelse etter arbeidstvistloven § 15 eller tjenestetvistloven § 22.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96972, 'lov/2005-06-17-62', 157, 18, 'kapittel-18-paragraf-1', '§ 16-1', 'Hva kapitlet omfatter', '(1) Dette kapittel kommer til anvendelse ved overdragelse av en virksomhet eller del av virksomhet til en annen arbeidsgiver. Med overdragelse menes overføring av en selvstendig enhet som beholder sin identitet etter overføringen.

(2) §§ 16-2 og 16-4 får ikke anvendelse ved overdragelse fra et konkursbo.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96973, 'lov/2005-06-17-62', 158, 18, 'kapittel-18-paragraf-2', '§ 16-2', 'Lønns- og arbeidsvilkår', '(1) Tidligere arbeidsgivers rettigheter og plikter som følger av arbeidsavtale eller arbeidsforhold som foreligger på det tidspunkt overdragelsen finner sted, overføres til den nye arbeidsgiver. Krav etter første punktum kan fortsatt gjøres gjeldende overfor den tidligere arbeidsgiver.

(2) Ny arbeidsgiver blir bundet av tariffavtale som tidligere arbeidsgiver var bundet av. Dette gjelder ikke hvis ny arbeidsgiver senest innen tre uker etter overdragelsestidspunktet skriftlig erklærer overfor fagforeningen at ny arbeidsgiver ikke ønsker å bli bundet. De overførte arbeidstakerne har likevel rett til å beholde de individuelle arbeidsvilkår som følger av tariffavtale som den tidligere arbeidsgiver var bundet av. Dette gjelder inntil denne tariffavtalen utløper eller til det inngås ny tariffavtale som er bindende for den nye arbeidsgiver og de overførte arbeidstakere.

(3) Arbeidstakernes rett til videre opptjening av alders-, etterlatte- og uførepensjon i henhold til kollektiv tjenestepensjon, overføres til ny arbeidsgiver etter reglene i første og andre ledd. Ny arbeidsgiver kan velge å gjøre allerede eksisterende pensjonsordninger gjeldende for de overførte arbeidstakerne. Dersom arbeidstakernes tidligere pensjonsordninger ikke kan videreføres etter overdragelsen, skal ny arbeidsgiver sørge for at de overførte arbeidstakerne sikres rett til videre opptjening etter en annen kollektiv pensjonsordning.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96974, 'lov/2005-06-17-62', 159, 18, 'kapittel-18-paragraf-3', '§ 16-3', 'Reservasjonsrett mv.', '(1) Arbeidstaker kan motsette seg at arbeidsforholdet overføres til ny arbeidsgiver.

(2) Arbeidstaker som motsetter seg at arbeidsforholdet overføres til ny arbeidsgiver, må skriftlig underrette tidligere arbeidsgiver om dette innen den frist denne har fastsatt. Fristen kan ikke være kortere enn 14 dager etter at informasjon etter § 16-6 er gitt.

(3) Arbeidstaker som har vært ansatt i virksomheten i til sammen minst 12 måneder de siste to år før overdragelsestidspunktet, og som gjør gjeldende reservasjonsrett etter denne paragraf, har fortrinnsrett til ny ansettelse hos tidligere arbeidsgiver i ett år fra overdragelsestidspunktet, med mindre det gjelder en stilling arbeidstaker ikke er kvalifisert for. Fortrinnsretten faller bort dersom arbeidstaker ikke har akseptert et tilbud om ansettelse i en passende stilling senest 14 dager etter at tilbudet ble mottatt. Fortrinnsrett etter §§ 10-2 fjerde ledd, 14-2 og 14-3 går foran fortrinnsrett etter paragrafen her.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96975, 'lov/2005-06-17-62', 160, 18, 'kapittel-18-paragraf-4', '§ 16-4', 'Vern mot oppsigelse', '(1) Overdragelse av virksomhet til annen arbeidsgiver er ikke i seg selv grunn for oppsigelse eller avskjed fra tidligere eller ny arbeidsgiver.

(2) Dersom arbeidsavtale eller arbeidsforhold opphører fordi skifte av arbeidsgiver medfører vesentlige endringer i arbeidsvilkårene til skade for arbeidstaker, anses opphøret som en følge av arbeidsgivers forhold.

(3) Ved tvister etter denne paragraf gjelder bestemmelsene i §§ 15-11 og 15-12 tilsvarende, med unntak av § 15-12 første ledd siste punktum. Bestemmelsene i kapittel 17 gjelder tilsvarende så langt de passer.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96976, 'lov/2005-06-17-62', 161, 18, 'kapittel-18-paragraf-5', '§ 16-5', 'Informasjon og drøfting med tillitsvalgte', '(1) Tidligere og ny arbeidsgiver skal så tidlig som mulig gi informasjon om og drøfte overdragelsen med arbeidstakernes tillitsvalgte.

(2) Det skal gis særskilt informasjon om:
a. grunnen til overdragelsen,
b. fastsatt eller foreslått dato for overdragelsen,
c. de rettslige, økonomiske og sosiale følger av overdragelsen for arbeidstakerne,
d. endringer i tariffavtaleforhold,
e. planlagte tiltak overfor arbeidstakerne,
f. reservasjons- og fortrinnsrett, og fristen for å utøve slike rettigheter.

(3) Dersom tidligere eller ny arbeidsgiver planlegger tiltak overfor arbeidstakerne, skal dette så tidlig som mulig drøftes med tillitsvalgte med sikte på å oppnå en avtale.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96977, 'lov/2005-06-17-62', 162, 18, 'kapittel-18-paragraf-6', '§ 16-6', 'Informasjon til arbeidstakerne', 'Tidligere og ny arbeidsgiver skal så tidlig som mulig informere de berørte arbeidstakere om overdragelse som nevnt i § 16-1. Det skal gis særskilt informasjon om forhold nevnt i § 16-5 andre ledd bokstavene a til f.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96978, 'lov/2005-06-17-62', 163, 18, 'kapittel-18-paragraf-7', '§ 16-7', 'Representasjon', '(1) Hvis virksomheten bevarer sin uavhengighet, skal de tillitsvalgte som berøres av overdragelse som nevnt i § 16-1, beholde sin rettsstilling og funksjon.

(2) Hvis virksomheten ikke bevarer sin uavhengighet, skal de overførte arbeidstakere som var representert før overdragelsen, fortsatt være representert på en egnet måte fram til nyvalg kan finne sted.

(3) Første ledd kommer ikke til anvendelse dersom overdragelsen medfører at grunnlaget for arbeidstakernes representasjon opphører. I slike tilfeller skal tillitsvalgte fortsatt være sikret vern i samsvar med avtaler som beskytter tillitsvalgte på dette området.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96979, 'lov/2005-06-17-62', 164, 19, 'kapittel-19-paragraf-1', '§ 17-1', 'Tvister om arbeidsforhold', '(1) I søksmål om rettigheter eller plikter etter denne lov gjelder domstolloven og tvisteloven, med de særregler som går fram av dette kapittel.

(2) I forbindelse med søksmålet kan retten også behandle krav om oppgjør av lønn og feriepenger. Det samme gjelder andre krav som står i sammenheng med eller kommer i stedet for krav etter første ledd, dersom det ikke vil være til vesentlig ulempe for behandlingen av saken. Rettens avgjørelse etter forrige punktum kan ikke angripes.

(3) Mekling i forliksråd finner ikke sted for krav som er gjenstand for forhandlinger etter § 17-3, krav som nevnt i § 17-1 andre ledd eller krav som har vært prøvet for tvisteløsningsnemnd etter § 17-2. Mekling i forliksråd finner ikke sted i saker etter § 17-1 femte ledd.

(4) Ved søksmål som omfattes av § 17-4 første ledd skal retten påskynde saken mest mulig og om nødvendig beramme saken utenom tur.

(5) Fagforening som har medlemmer i en virksomhet som har leid inn arbeidstaker fra bemanningsforetak, jf. § 14-12, kan reise søksmål i eget navn om lovligheten av slik innleie. I tilknytning til slik sak vil begge parter ha rett til å kreve forhandlinger i tråd med reglene i § 17-3.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96980, 'lov/2005-06-17-62', 165, 19, 'kapittel-19-paragraf-2', '§ 17-2', 'Tvisteløsningsnemnd', '(1) Tvist som nevnt i §§ 8-3, 10-13 og 12-14, § 14-3 første ledd og § 14-4 a kan bringes inn for en tvisteløsningsnemnd for avgjørelse.

(2) Tvist kan ikke bringes inn for domstolene før den har vært prøvet for nemnda og avgjørelse fra nemnda foreligger. Ved domstolsprøving av tvisten skal den konklusjon nemnda har kommet til stå ved lag mens saken er til behandling ved domstolene. Dersom dette vil virke urimelig, kan retten etter krav fra en av partene fastsette en annen midlertidig ordning.

(3) Fristen for å bringe tvisten inn for domstolene er åtte uker fra det tidspunktet parten ble underrettet om nemndas avgjørelse.

(4) Reises det ikke søksmål innen fristen, har vedtaket virkning som en rettskraftig dom, og det kan fullbyrdes etter reglene som gjelder for dommer. Nemnda kan gi oppfriskning for oversittelse av fristen etter reglene i tvisteloven §§ 16-12 til 16-14. Et vedtak om oppfriskning kan bringes inn for tingretten.

(5) Departementet kan gi forskrift om oppnevning av nemndas medlemmer og om nemndas sammensetning og saksbehandling.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96981, 'lov/2005-06-17-62', 166, 19, 'kapittel-19-paragraf-3', '§ 17-2 a', 'Frist for å fremme sak for Tvisteløsningsnemnda', '(1) Det må reises sak for Tvisteløsningsnemnda senest fire uker etter at arbeidsgivers skriftlige avslag er kommet frem til arbeidstaker. Fristen beregnes og avbrytes etter reglene i domstolloven kapittel 8.

(2) I utdanningspermisjonssaker kan det fremmes sak senest fire uker etter utløpet av arbeidsgivers svarfrist etter § 12-11 femte ledd dersom arbeidsgiver ikke har svart innen fristen.

(3) Saker om rett til delvis permisjon etter § 12-6 skal tas til behandling selv om fireukersfristen er utløpt dersom oversittelsen av fristen skyldes en fødsel eller overtakelse av omsorg for et adoptivbarn eller fosterbarn. Saken må i så fall fremmes snarest mulig etter fødselen eller omsorgsovertakelsen.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96982, 'lov/2005-06-17-62', 167, 19, 'kapittel-19-paragraf-4', '§ 17-2 b', 'Gjenåpning', '(1) Nemndas rettskraftige avgjørelser og beslutninger kan gjenåpnes etter begjæring fra en part dersom
a. det foreligger brudd på habilitetskrav i forvaltningsloven § 6
b. det foreligger andre saksbehandlingsfeil, og det ikke kan utelukkes at feilen var bestemmende for avgjørelsens innhold
c. opplysninger om faktiske forhold som var ukjent da saken ble avgjort, tilsier at avgjørelsen høyst sannsynlig ville blitt et annen.

(2) En sak kan ikke gjenåpnes
a. av en grunn som ble forkastet ved sakens behandling
b. av en grunn som parten burde ha gjort gjeldende under sakens ordinære behandling, ved søksmål til tingretten eller ved begjæring om oppfriskning
c. dersom det er rimelig sannsynlighetsovervekt for at en ny behandling av saken ikke vil lede til en endring av betydning for parten.

(3) Et vedtak om gjenåpning treffes av nemndsleder.

(4) Et avslag på en begjæring om gjenåpning kan bringes inn for tingretten. For øvrig gjelder reglene i tvisteloven kapittel 31 så langt de passer.

(5) Dersom nemnda treffer vedtak om gjenåpning, har parten krav på å få dekket saksomkostninger etter reglene i forvaltningsloven § 36 første ledd. Forvaltningsloven § 36 andre ledd gjelder ikke.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96983, 'lov/2005-06-17-62', 168, 19, 'kapittel-19-paragraf-5', '§ 17-2 c', 'Retting og tilleggsavgjørelse', '(1) Nemnda kan rette et vedtak som på grunn av en skrive- eller regnefeil, misforståelse, forglemmelse eller lignende klar feil har fått en utforming som ikke stemte med nemndas mening.

(2) Er det ikke truffet avgjørelse om noe som skulle vært avgjort, kan det avsies en tilleggsavgjørelse dersom det fremmes en begjæring om det innen fristen for å bringe saken inn for tingretten, jf. § 17-2 tredje ledd.

(3) Nemndsleder kan treffe vedtak etter første og andre ledd.

(4) For øvrig gjelder tvisteloven §§ 19-8 og 19-9 tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96984, 'lov/2005-06-17-62', 169, 19, 'kapittel-19-paragraf-6', '§ 17-3', 'Rett til å kreve forhandlinger', '(1) Arbeidstaker som vil gjøre gjeldende at en oppsigelse eller avskjed er ulovlig, at det er brudd på lovens regler om fortrinnsrett eller at det har skjedd en ulovlig midlertidig ansettelse, innleie eller suspensjon, kan kreve forhandlinger med arbeidsgiver. Det samme gjelder hvis arbeidstaker vil kreve erstatning på grunn av forhold som nevnt i første punktum.

(2) Arbeidstaker som vil kreve forhandlinger må skriftlig underrette arbeidsgiver om dette innen to uker. Fristen til å kreve forhandlinger regnes fra:
a. oppsigelsen eller avskjeden fant sted,
b. arbeidsgiver avslo krav fra arbeidstaker om fortrinnsrett til ny stilling,
c. arbeidstaker fratrådte ved tvist om det har foreligget ulovlig innleie eller midlertidig ansettelse, eller
d. suspensjonens opphørstidspunkt.
Ved tvist om det foreligger lovlig innleie, midlertidig ansettelse eller suspensjon gjelder ingen frist for å kreve forhandlinger.

(3) Arbeidsgiver skal sørge for at forhandlingsmøte blir holdt snarest mulig og senest innen to uker etter at kravet er mottatt.

(4) Dersom arbeidstaker reiser søksmål eller underretter arbeidsgiver om at søksmål vil bli reist uten at forhandlinger har vært holdt, kan arbeidsgiver kreve forhandlinger med arbeidstaker. Krav om forhandlinger skal framsettes skriftlig så snart som mulig og senest to uker etter at arbeidsgiver er underrettet om at søksmål er eller vil bli reist. Arbeidsgiver skal sørge for at forhandlingsmøte blir holdt i samsvar med regelen i foregående ledd. Dersom søksmål er reist, skal arbeidsgiver skriftlig underrette retten om at forhandlinger vil bli holdt. Arbeidstaker plikter å møte til forhandlingene.

(5) Arbeidstaker og arbeidsgiver har rett til å la seg bistå av rådgiver under forhandlingene. Forhandlingene må være sluttført senest to uker etter datoen for det første forhandlingsmøtet, med mindre partene blir enige om å fortsette forhandlingene. Fra forhandlingene skal det settes opp protokoll, som skal underskrives av partene og deres rådgivere.

(6) I tvist om innleie rettes krav om forhandlinger mot innleier. Det som står om arbeidsgiver i paragrafen her gjelder tilsvarende for innleier.

(7) I tvist om fortrinnsrett etter § 14-2 første ledd andre punktum rettes krav om forhandlinger mot foretaket som har stillingen arbeidstaker mener seg fortrinnsberettiget til. Det som er bestemt om arbeidsgiver i paragrafen her, gjelder tilsvarende for slikt foretak.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96985, 'lov/2005-06-17-62', 170, 19, 'kapittel-19-paragraf-7', '§ 17-4', 'Søksmålsfrister i tvister om oppsigelse, avskjed, suspensjon mv.', '(1) Ved tvist om oppsigelse, avskjed, brudd på lovens regler om fortrinnsrett eller om det har foreligget ulovlig midlertidig ansettelse, innleie, eller suspensjon, er søksmålsfristen åtte uker. Dersom arbeidstaker bare krever erstatning, er søksmålsfristen seks måneder. Partene kan i den enkelte sak bli enige om en lengre søksmålsfrist.

(2) Søksmålsfristen etter første ledd regnes fra forhandlingenes avslutning. Er forhandlinger ikke holdt, regnes fristen fra de tidspunkter som er nevnt i § 17-3 andre ledd.

(3) Ved søksmål etter § 17-1 femte ledd avbrytes søksmålsfristen for individuelle erstatningskrav for de navngitte enkeltpersoner saken gjelder fra tidspunktet for søksmålet etter § 17-1 femte ledd og frem til rettskraftig dom foreligger.

(4) Dersom arbeidsgivers oppsigelse eller avskjed ikke oppfyller formkravene i § 15-4 første og andre ledd, gjelder ingen søksmålsfrist.

(5) Ved tvist om det foreligger ulovlig midlertidig ansettelse, innleie eller suspensjon gjelder ingen søksmålsfrist.

(6) Retten til å fortsette i stillingen etter § 15-11 gjelder dersom søksmål reises innen utløpet av oppsigelsesfristen, og innen åtte uker fra forhandlingenes avslutning eller fra oppsigelsen fant sted. Det samme gjelder hvis arbeidstaker innen utløpet av oppsigelsesfristen skriftlig underretter arbeidsgiver om at søksmål vil bli reist innen åtte-ukersfristen. Fristene gjelder ikke dersom arbeidsgivers oppsigelse ikke oppfyller formkravene i § 15-4 første og andre ledd, jf. tredje ledd i paragrafen her. Retten kan bestemme at arbeidsforholdet skal fortsette, jf. § 15-11 tredje ledd, dersom søksmål med krav om dette reises innen åtte uker fra tidspunktet for arbeidstakers fratreden eller fra forhandlingenes avslutning.

(7) Søksmålsfristen etter første ledd avbrytes hvis tvisten bringes inn for Diskrimineringsnemnda.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96986, 'lov/2005-06-17-62', 171, 19, 'kapittel-19-paragraf-8', '§ 17-5', 'Fristforlengelse og oppfriskning ved oppsigelse under sykdom, svangerskap, foreldrepermisjon, militærtjeneste mv.', '(1) Ved tvist om en oppsigelses rettmessighet etter § 15-8 løper fristene for å kreve forhandling eller gå til søksmål fra det tidspunkt forbudet mot oppsigelse etter § 15-8 første ledd opphører.

(2) Ved oppsigelse under fravær på grunn av barns eller barnepassers sykdom etter § 12-9 eller fravær på grunn av pleie av nærstående etter § 12-10, forlenges fristen for å kreve forhandlinger eller gå til søksmål med det antall dager arbeidstaker var fraværende etter at oppsigelsen fant sted.

(3) Ved oppsigelse under permisjon ved svangerskap, fødsel, adopsjon eller omsorg for små barn etter §§ 12-1 til 12-6 eller under permisjon ved militærtjeneste mv. etter § 12-12 kan retten gi oppfriskning for oversittelse av fristene for å kreve forhandlinger eller for søksmål, dersom arbeidstaker krever det og retten finner det rimelig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96987, 'lov/2005-06-17-62', 172, 19, 'kapittel-19-paragraf-9', '§ 17-6', 'Meddommerutvalg', 'Domstoladministrasjonen oppnevner ett eller flere særskilte arbeidslivskyndige meddommerutvalg for hvert fylke. Minst to femdeler av meddommerne i hvert utvalg oppnevnes etter forslag fra arbeidsgiverorganisasjon og minst to femdeler oppnevnes etter forslag fra arbeidstakerorganisasjon.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96988, 'lov/2005-06-17-62', 173, 19, 'kapittel-19-paragraf-10', '§ 17-7', 'Oppnevning av meddommere', '(1) Under hovedforhandling og under ankeforhandling i lagmannsrett settes retten med to meddommere.

(2) Meddommere oppnevnes etter forslag fra partene fra de særskilte arbeidslivskyndige utvalg oppnevnt etter § 17-6. I lagmannsrettssaker tas meddommerne fra de utvalg som er oppnevnt innen lagsognets grenser.

(3) Partene foreslår hver sin halvpart av det antall meddommere retten settes med i den enkelte sak. Foreligger ikke partenes forslag innen den frist dommeren har bestemt, kan dommeren oppnevne meddommere etter domstolloven § 94. Det samme gjelder dersom flere saksøkere eller saksøkte ikke blir enige om noe felles forslag.

(4) Retten kan likevel settes uten meddommere dersom partene og retten er enig i at meddommere er unødvendig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96989, 'lov/2005-06-17-62', 174, 20, 'kapittel-20-paragraf-1', '§ 18-1', 'Arbeidstilsynet', '(1) Arbeidstilsynet fører tilsyn med at bestemmelsene i og i medhold av denne lov blir overholdt. Når det er nødvendig med særskilt ekspertise for å gjennomføre tilsyn etter denne lov, kan Arbeidstilsynet oppnevne sakkyndige til å utføre kontroll og foreta undersøkelser mv. på Arbeidstilsynets vegne. Departementet kan fastsette bestemmelser om Arbeidstilsynets organisasjon og virksomhet.

(2) Departementet kan bestemme at tilsynet med deler av den offentlige forvaltning og transportbedrifter som drives av staten skal ordnes på annen måte enn det som følger av loven. Departementet kan bestemme at annen offentlig myndighet enn Arbeidstilsynet skal føre tilsyn med at bestemmelsene i eller i medhold av denne lov blir overholdt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96990, 'lov/2005-06-17-62', 175, 20, 'kapittel-20-paragraf-2', '§ 18-2', 'Beskyttelse av kilder', '(1) Når Arbeidstilsynet får melding om forhold som er i strid med loven, plikter enhver som utfører arbeid eller tjeneste for Arbeidstilsynet å hindre at andre får kjennskap til melderens navn eller andre identifiserende opplysninger om melderen.

(2) Taushetsplikten gjelder også overfor den anmeldte. Forvaltningsloven §§ 13 til 13 e og 13 g gjelder ellers tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96991, 'lov/2005-06-17-62', 176, 20, 'kapittel-20-paragraf-3', '§ 18-3', 'Gebyrer', '(1) Virksomhet som går inn under denne lov, kan pålegges å betale til statskassen et årlig tilsynsgebyr eller gebyrer til dekning av utgifter til kontroll, godkjenning, sertifisering eller til pålagte undersøkelser eller prøver, herunder sektoravgift til dekning av utgifter ved andre oppfølgingsoppgaver som retter seg mot hele eller deler av petroleumsvirksomheten.

(2) Departementet kan i forskrift gi nærmere regler om slike gebyrer og sektoravgift. Gebyrene og sektoravgift er tvangsgrunnlag for utlegg.

(3) Departementet kan i forskrift gi adgang for Arbeidstilsynet til å kreve refundert utgifter for undersøkelser og prøver som arbeidsgiveren etter loven har plikt til å utføre.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96992, 'lov/2005-06-17-62', 177, 20, 'kapittel-20-paragraf-4', '§ 18-4', 'Arbeidstilsynets adgang til virksomheten', '(1) Arbeidstilsynet skal til enhver tid ha uhindret adgang til ethvert sted som omfattes av loven. Tilsynspersonellet skal legitimere seg i samsvar med forvaltningsloven § 15 og om mulig ta kontakt med arbeidsgiver og verneombudet. Verneombudet kan kreve at også andre representanter for arbeidstakerne deltar under kontrollen. I virksomheter hvor det ikke er verneombud, skal tilsynspersonellet om mulig ta kontakt med annen representant for arbeidstakerne. Dersom Arbeidstilsynet ikke gis adgang til sted som nevnt i første punktum, kan Arbeidstilsynet selv iverksette nødvendige tiltak for å skaffe seg adgang.

(2) Arbeidsgiver eller representant for denne har rett til, og kan pålegges, å være til stede under kontrollen. Tilsynspersonellet kan bestemme at retten ikke skal gjelde ved intervju av arbeidstaker eller dersom slik tilstedeværelse ikke kan gjennomføres uten vesentlig ulempe eller uten at formålet med kontrollen settes i fare.

(3) Med mindre tungtveiende hensyn tilsier noe annet, skal Arbeidstilsynet gi skriftlig rapport til arbeidsgiver om resultatet av kontrollen. Kopi av rapporten skal gis verneombudet, og om nødvendig til bedriftshelsetjenesten.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96993, 'lov/2005-06-17-62', 178, 20, 'kapittel-20-paragraf-5', '§ 18-5', 'Opplysninger', '(1) Enhver som er underlagt tilsyn etter denne lov skal når Arbeidstilsynet krever det og uten hinder av taushetsplikt fremlegge opplysninger som anses nødvendige for utøvelsen av tilsynet. Arbeidstilsynet kan bestemme i hvilken form opplysningene skal gis.

(2) Opplysninger som nevnt i første ledd kan også kreves fra andre offentlige tilsynsmyndigheter uten hinder av den taushetsplikt som ellers gjelder. Opplysningsplikten gjelder bare de opplysninger som er nødvendige for at tilsynsmyndigheten skal kunne utføre sine oppgaver etter loven.

(3) Opplysninger som nevnt i første ledd kan, når særlige forhold gjør det nødvendig, også kreves utlevert fra en annen virksomhet enn den et tilsyn er rettet mot. Arbeidstilsynet kan bare kreve opplysninger fra en slik annen virksomhet når det anses forholdsmessig. I forholdsmessighetsvurderingen skal det blant annet legges vekt på:
a. om det er mistanke om lovbrudd, og hvor alvorlige lovbruddene er,
b. hvor sensitive de etterspurte opplysningene er, og
c. arbeidsbyrden for virksomheten som skal utlevere opplysningene.

(4) Arbeidstilsynets rett til å kreve opplysninger etter tredje ledd omfatter ikke særlige kategorier av personopplysninger etter personvernforordningen artikkel 9. Forvaltningslovens regler om enkeltvedtak gjelder ikke for pålegg om opplysninger etter tredje ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96994, 'lov/2005-06-17-62', 179, 20, 'kapittel-20-paragraf-6', '§ 18-6', 'Pålegg og andre enkeltvedtak', '(1) Arbeidstilsynet gir de pålegg og treffer de enkeltvedtak ellers som er nødvendig for gjennomføringen av bestemmelsene i og i medhold av § 1-7, kapittel 2, § 2 A-6, kapittel 3 til kapittel 11, samt § 14-1 b andre ledd, §§ 14-5 til 14-8, § 14-12 første, andre, femte og sjette ledd, § 14-12 a første ledd, § 14-12 b første ledd, § 14-13 a, § 14-14 a, § 14-15 andre og sjette ledd og §§ 15-2, 15-15, § 18-4, 18-5 og 18-8. Dette gjelder likevel ikke § 10-2 andre til fjerde ledd, § 10-6 tiende ledd og § 14-6 tredje og fjerde ledd.

(2) Pålegg skal gis skriftlig, og det skal settes en frist for når det skal være utført. Ved overhengende fare kan Arbeidstilsynet kreve at nødvendige tiltak blir iverksatt straks. I pålegget skal det opplyses om klageadgang, klagefrist og den nærmere fremgangsmåte ved klage, samt retten til å se sakens dokumenter, jf. forvaltningsloven § 27.

(3) Arbeidstilsynet kan forby at farlige kjemikalier eller biologisk materiale fremstilles, pakkes, brukes eller oppbevares i virksomhet som går inn under loven. Arbeidstilsynet kan dessuten kreve at arbeidsgiver skal foreta spesielle undersøkelser eller levere prøver til undersøkelse. Utgifter i denne forbindelse bæres av arbeidsgiver.

(4) Arbeidstilsynet kan kreve at produsent eller importør av kjemikalier eller biologisk materiale foretar undersøkelser eller leverer prøve til undersøkelse for å få fastslått kjemikaliets eller materialets farlighetsgrad. Utgifter til slike undersøkelser bæres av den som har plikt til å foreta undersøkelsen eller levere prøven. Arbeidstilsynet kan forby omsetning av et kjemikalie eller biologisk materiale hvis en produsent eller importør forsømmer sin melde- eller merkeplikt, eller ikke gir supplerende opplysninger som kreves etter § 5-4 første ledd bokstav c.

(5) Arbeidstilsynet kan gi pålegg om at den som leverer eller markedsfører et produkt som selv om det brukes i samsvar med de kravene som stilles, kan medføre fare for liv eller helse, skal treffe nødvendige tiltak for å avverge faren. Det kan blant annet kreves at:
a. levering eller markedsføring stanses,
b. produkter tilbakekalles.

(6) I forbindelse med tillatelse, samtykke, dispensasjon eller andre enkeltvedtak kan Arbeidstilsynet sette nærmere bestemte vilkår.

(7) Direktoratet for arbeidstilsynet er klageinstans for enkeltvedtak truffet av det lokale arbeidstilsyn. Departementet er klageinstans for enkeltvedtak truffet av direktoratet.

(8) Arbeidstakernes tillitsvalgte skal gjøres kjent med pålegg og andre enkeltvedtak som Arbeidstilsynet treffer.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96995, 'lov/2005-06-17-62', 180, 20, 'kapittel-20-paragraf-7', '§ 18-7', 'Tvangsmulkt', 'I pålegg etter loven kan det fastsettes en løpende tvangsmulkt for hver dag eller uke eller måned som går etter utløpet av den frist som er satt for oppfyllelse av pålegget, inntil pålegget er oppfylt. Tvangsmulkt kan også fastsettes som engangsmulkt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96996, 'lov/2005-06-17-62', 181, 20, 'kapittel-20-paragraf-8', '§ 18-8', 'Stansing', 'Dersom pålegg ikke oppfylles innen fristen, kan Arbeidstilsynet helt eller delvis stanse virksomhetens aktiviteter inntil pålegget er oppfylt. Ved overhengende fare kan Arbeidstilsynet stanse de aktiviteter som er knyttet til faresituasjonen selv om pålegg ikke er gitt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96997, 'lov/2005-06-17-62', 182, 20, 'kapittel-20-paragraf-9', '§ 18-9', 'Arbeidstilsynets samtykke ved oppføring av bygning mv.', '(1) Den som vil oppføre en bygning eller utføre bygningsmessig arbeid som er søknadspliktig etter plan- og bygningsloven, og som skal brukes eller ventelig vil bli brukt av virksomhet som går inn under denne lov, har plikt til å innhente Arbeidstilsynets samtykke på forhånd.

(2) Departementet kan i forskrift gi nærmere bestemmelser om plikten til å innhente Arbeidstilsynets forhåndssamtykke etter denne paragraf, hvilke opplysninger som kan kreves og de vilkår som kan stilles for å gi slikt samtykke.

(3) Departementet kan i forskrift bestemme at forhåndssamtykke ikke er nødvendig for spesielle arbeidsplasser eller bygninger når dette er ubetenkelig ut fra hensynet til arbeidsmiljøet.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96998, 'lov/2005-06-17-62', 183, 20, 'kapittel-20-paragraf-10', '§ 18-10', 'Overtredelsesgebyr', '(1) Arbeidstilsynet kan ilegge en virksomhet overtredelsesgebyr dersom noen som har handlet på vegne av virksomheten uaktsomt eller forsettlig har overtrådt bestemmelser som nevnt i § 18-6 første ledd. Overtredelsesgebyr kan ilegges selv om ingen enkeltperson har utvist skyld. Overtredelsesgebyret tilfaller statskassen og kan utgjøre inntil 50 ganger grunnbeløpet i folketrygden eller fire prosent av virksomhetens årsomsetning. Det høyeste beløpet utgjør den øvre rammen.

(2) Ved vurdering av om overtredelsesgebyr skal ilegges, og ved utmålingen, skal det særlig legges vekt på:
a. hvor alvorlig overtredelsen er,
b. graden av skyld,
c. om det foreligger gjentagelse,
d. om virksomheten ved retningslinjer, instruksjon, opplæring, kontroll eller andre tiltak kunne ha forebygget overtredelsen,
e. om virksomheten har hatt eller kunne ha oppnådd noen fordel ved overtredelsen,
f. om overtredelsen er begått for å fremme virksomhetens interesser,
g. om andre reaksjoner som følge av overtredelsen blir ilagt virksomheten eller noen som har handlet på vegne av denne,
h. virksomhetens økonomiske evne, og
i. den preventive effekten.

(3) Når ikke annet er fastsatt i enkeltvedtak, er oppfyllelsesfristen fire uker fra vedtak om overtredelsesgebyr ble truffet. Endelig vedtak om overtredelsesgebyr er tvangsgrunnlag for utlegg. Dersom virksomheten går til søksmål mot staten for å prøve vedtaket, suspenderes tvangskraften. Retten kan prøve alle sider av saken. Overtredelsesgebyr kan ilegges på stedet ved klart konstaterbare overtredelser. Andre ledd gjelder ikke ved slik ileggelse av overtredelsesgebyr. Forhåndsvarsel etter forvaltningsloven § 16 kan unnlates når overtredelsesgebyr ilegges på stedet.

(4) Adgangen til å ilegge overtredelsesgebyr foreldes fem år etter at overtredelsen er opphørt. Foreldelsesfristen avbrytes ved at Arbeidstilsynet har gitt forhåndsvarsel om vedtak om overtredelsesgebyr, jf. forvaltningsloven § 16.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (96999, 'lov/2005-06-17-62', 184, 20, 'kapittel-20-paragraf-11', '§ 18-10 a', 'Overtredelsesgebyr til fysiske personer', '(1) Arbeidstilsynet kan ilegge overtredelsesgebyr til den som i arbeidsgivers sted leder virksomheten, hvis vedkommende forsettlig eller grovt uaktsomt overtrer bestemmelser som nevnt i § 18-6 første ledd. Overtredelsesgebyret tilfaller statskassen, og kan utgjøre inntil 25 ganger grunnbeløpet i folketrygden.

(2) Ved vurderingen av om det skal ilegges overtredelsesgebyr etter første ledd, og ved utmålingen, skal Arbeidstilsynet blant annet legge vekt på:
a. overtredelsens omfang og virkninger,
b. fordeler som er eller kunne vært oppnådd ved lovbruddet,
c. overtrederens skyld og økonomiske evne, og
d. om det er rimelig grunn til å tro at overtrederen har innrettet, eller vil forsøke å innrette, virksomheten på en slik måte at et overtredelsesgebyr mot virksomheten ikke vil ha tilstrekkelig effekt.

(3) Ved ileggelse av overtredelsesgebyr etter første ledd gjelder § 18-10 tredje og fjerde ledd tilsvarende.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97000, 'lov/2005-06-17-62', 185, 20, 'kapittel-20-paragraf-12', '§ 18-11', 'Gjensidig bistand ved innkreving av og underretning om økonomiske administrative sanksjoner', '(1) Avgjørelser om økonomiske administrative sanksjoner og bøter ilagt av ansvarlig myndighet eller domstol i annen EØS-stat er bindende i Norge og kan fullbyrdes hvis avgjørelsen gjelder manglende overholdelse av nasjonale regler som gjennomfører EØS-avtalens vedlegg XVIII nr. 30 (direktiv 96/71/EF) om utsending av arbeidstakere i forbindelse med tjenesteyting, eller direktiv 2014/67/EU om håndheving av direktiv 96/71/EF og om endring av forordning (EU) nr. 1024/2012 om administrativt samarbeid i informasjonssystemet for det indre marked, slik dette er innlemmet i EØS-avtalen, og avgjørelsen ikke kan påklages eller er rettskraftig.

(2) Pengekrav som følger av avgjørelse som nevnt i første ledd, kreves inn av Innkrevingsmyndigheten med mindre departementet bestemmer noe annet.

(3) Innkrevingsmyndigheten kan anmode ansvarlige myndigheter i andre EØS-stater om å kreve inn pengekrav som følger av vedtak som nevnt i arbeidsmiljøloven § 18-7 (tvangsmulkt) og § 18-10 (overtredelsesgebyr), og som oppfyller vilkårene i første ledd.

(4) Pengekrav som kreves inn i medhold av første ledd, tilfaller statskassen. Pengekrav som kreves inn i medhold av tredje ledd, tilfaller den EØS-stat som gjennomfører innkrevingen.

(5) Departementet kan i forskrift gi nærmere regler om underretning om og fullbyrding av avgjørelser som nevnt i første og tredje ledd.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97001, 'lov/2005-06-17-62', 186, 20, 'kapittel-20-paragraf-13', '§ 18-12', 'Politiets bistandsplikt', 'Når det er nødvendig, kan Arbeidstilsynet kreve at politiet bistår ved gjennomføring av tilsyn og fullbyrdelse av vedtak gitt i medhold av kapittel 18. Politiet kan anvende makt i den utstrekning det er nødvendig og forsvarlig.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97002, 'lov/2005-06-17-62', 187, 20, 'kapittel-20-paragraf-14', '§ 18-13', 'Bevissikring', '(1) Arbeidstilsynet kan foreta bevissikring når det er sannsynlig at det foreligger overtredelse av bestemmelser som nevnt i § 18-6 første ledd, og bevissikring er nødvendig og ikke uforholdsmessig inngripende.

(2) Når vilkårene i første ledd er oppfylt, kan Arbeidstilsynet, etter beslutning fra tingretten, kreve:
a. å få adgang til lokaler, eiendommer, transportmidler og andre oppbevaringssteder hvor det kan finnes bevis for overtredelse,
b. å få adgang til bolig dersom det er sannsynlig at bevis oppbevares der,
c. å ta med ting, herunder kopi av dokumenter og annen informasjon og elektronisk lagret informasjon, som kan ha betydning som bevis for nærmere undersøkelse, og
d. å forsegle arbeidssteder, forretningspapirer eller elektroniske lagringsmedier så lenge undersøkelsen varer og dette anses nødvendig.
Originale dokumenter kan tas med etter første punktum bokstav c når originalen i seg selv antas å ha særskilt bevisverdi, bevisverdien vil reduseres ved kopiering, eller dokumentet antas å være et særlig sentralt bevis for lovovertredelse. Tas originaldokumenter med etter denne bestemmelsen, skal de kontrollerte få kopi av dokumentene, så fremt det kan skje uten skade eller fare for kontrollen.

(3) Begjæring om adgang til bevissikring fremsettes av Arbeidstilsynet for tingretten på det stedet hvor det mest praktisk kan skje.

(4) Retten treffer avgjørelse ved beslutning før bevissikring settes i verk. Rettens beslutning skal angi hvor bevissikring skal gjennomføres, og hvilken type overtredelse som antas å foreligge. Dersom det er fare for bevisforspillelse, kan beslutningen treffes uten at den som avgjørelsen rammer, gis adgang til å uttale seg. En anke over beslutning om bevissikring gir ikke utsatt iverksettelse.

(5) Straffeprosessloven § 200, § 201 første ledd, § 204, § 205 tredje ledd og §§ 207, 208, 209, 213, kapittel 26 samt forvaltningsloven § 15 andre og tredje ledd gjelder tilsvarende.

(6) Arbeidstilsynet kan be om bistand fra politiet til å iverksette en beslutning om bevissikring etter § 18-12. Ved bevissikring i bolig skal Arbeidstilsynet alltid ha bistand fra politiet.

(7) Dersom det ikke er tid til å avvente rettens beslutning, kan Arbeidstilsynet kreve at politiet avstenger områder der bevisene kan være, inntil rettens beslutning foreligger.

(8) Departementet kan gi forskrift om gjennomføring av bevissikring.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97003, 'lov/2005-06-17-62', 188, 21, 'kapittel-21-paragraf-1', '§ 19-1', 'Ansvar for innehaver av virksomhet, arbeidsgiver og den som i arbeidsgivers sted leder virksomheten', '(1) Ved forsettlig eller uaktsom overtredelse av bestemmelse eller pålegg gitt i eller i medhold av denne lov, straffes innehaver av virksomhet, arbeidsgiver eller den som i arbeidsgivers sted leder virksomheten med bøter eller fengsel inntil ett år eller begge deler. Medvirkning straffes på samme måte, likevel slik at arbeidstaker straffes etter § 19-2.

(2) Under særlig skjerpende omstendigheter kan fengsel inntil fem år anvendes. Ved avgjørelsen av om det foreligger slike omstendigheter, skal det særlig legges vekt på om overtredelsen har eller kunne ha medført alvorlig fare for liv eller helse eller om den er foretatt eller fortsatt tross pålegg eller henstilling fra offentlig myndighet, vedtak av arbeidsmiljøutvalget eller henstilling fra verneombud eller bedriftshelsetjeneste.

(3) For overtredelse som har eller kunne ha medført alvorlig fare for liv eller helse, kan innehaver av virksomhet, arbeidsgiver eller den som i arbeidsgivers sted leder virksomheten straffes etter denne paragraf, med mindre vedkommende i enhver henseende har opptrådt fullt forsvarlig med hensyn til sine plikter etter loven eller bestemmelser i medhold av loven.

(4) Bestemmelsene i denne paragraf gjelder ikke reglene i kapittel 8, 12, 13, 15 og 16. Bestemmelsene gjelder heller ikke reglene i kapittel 14, med unntak av §§ 14-5 til 14-8 og 14-15.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97004, 'lov/2005-06-17-62', 189, 21, 'kapittel-21-paragraf-2', '§ 19-2', 'Ansvar for arbeidstakere', '(1) Arbeidstaker som uaktsomt overtrer bestemmelse eller pålegg gitt i eller i medhold av denne lov, straffes med bøter. Medvirkning straffes på samme måte.

(2) Er overtredelsen forsettlig eller grovt uaktsom, kan bøter eller fengsel inntil tre måneder, eller begge deler, anvendes.

(3) Ved særlig skjerpende omstendigheter kan fengsel inntil ett år anvendes. Ved avgjørelsen av om det foreligger slike omstendigheter, skal det særlig legges vekt på om overtredelsen var i strid med særskilt arbeids- eller sikkerhetsinstruks og om arbeidstakeren forsto eller burde forstå at overtredelsen kunne medføre alvorlig fare for andres liv eller helse.

(4) Bestemmelsene i denne paragraf gjelder ikke reglene i kapittel 10 om arbeidstid og kapittel 14 og 15 om oppsigelsesvern.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97005, 'lov/2005-06-17-62', 190, 21, 'kapittel-21-paragraf-3', '§ 19-3', 'Ansvar for foretak', 'Straffansvar for foretak er regulert i straffeloven §§ 27 og 28.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97006, 'lov/2005-06-17-62', 191, 21, 'kapittel-21-paragraf-4', '§ 19-4', 'Ansvar for å hindre offentlig myndighet', 'Den som hindrer undersøkelser som offentlig myndighet iverksetter etter denne lov eller unnlater å yte pliktig bistand eller å gi opplysninger som anses nødvendig for utførelsen av tilsynet etter denne lov, straffes med bøter med mindre forholdet rammes av § 19-1 eller strengere straffebud i straffeloven. Medvirkning straffes ikke.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97007, 'lov/2005-06-17-62', 192, 21, 'kapittel-21-paragraf-5', '§ 19-5', 'Offentlig tjenestemann', 'Enhver som er knyttet til Arbeidstilsynet er i forhold til straffeloven å regne som offentlig tjenestemann.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97008, 'lov/2005-06-17-62', 193, 21, 'kapittel-21-paragraf-6', '§ 19-6', 'Påtalen', 'Overtredelse av denne lov er undergitt offentlig påtale.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97009, 'lov/2005-06-17-62', 194, 21, 'kapittel-21-paragraf-7', '§ 19-7', '(Opphevet)', '', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97010, 'lov/2005-06-17-62', 195, 22, 'kapittel-22-paragraf-1', '§ 20-1', 'Ikrafttredelse', 'Loven trer i kraft fra den tid Kongen bestemmer.[1]', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97011, 'lov/2005-06-17-62', 196, 22, 'kapittel-22-paragraf-2', '§ 20-2', 'Overgangsbestemmelser', 'Forskrifter gitt i medhold av lov 4. februar 1977 nr. 4 om arbeidervern og arbeidsmiljø mv. skal gjelde inntil annet er bestemt.', NULL, 0);
INSERT INTO paragrafer (id, dokument_id, nr, seksjon_nr, paragraf_id, nummer, tittel, tekst, opphevet, fremtidig) VALUES (97012, 'lov/2005-06-17-62', 197, 22, 'kapittel-22-paragraf-3', '§ 20-3', 'Endringer i andre lover', 'Fra lovens ikrafttredelse gjøres følgende endringer i andre lover: – – –', NULL, 0);
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1965-06-18-4', '§4');
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1965-06-18-4', '§5');
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1965-06-18-4', '§8');
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1965-06-18-4', '§31');
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1965-06-18-4', '§37');
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1965-06-18-4', '§38');
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1967-02-10', '§28');
INSERT INTO hjemmel (dokument_id, lov_refid, paragraf) VALUES ('forskrift/2016-03-18-260', 'lov/1915-08-13-5', '§163a');

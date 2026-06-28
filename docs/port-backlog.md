# DBErrors Port Backlog

Source: `DBErrors.log` (83285 lines)  
Parsed by: `tools/db-port/dberrors_parser.ps1`

## Priority queues

| Priority | Category | Count | LOA hint | Sample |
|----------|----------|------:|----------|--------|
| P5 | uncategorized | 81860 | Manual triage | Gameobject lock/spell DBC mismatches (bulk) |
| P2 | unbound_cpp_script | 990 | Match ScriptName in loa templates | `spell_dk_death_strike_enabler` not assigned |
| P4 | gameobject_missing_spell_dbc | 120 | DBC-limited; Wowhead | GO spell data0 references missing spell |
| P3 | creature_faction | 105 | loa.creature_template | Non-existing faction_H |
| P0 | missing_gameobject_template | 100 | loa INSERT | Entry 212922 skipped |
| P4 | gameobject_missing_spellfocus_dbc | 60 | DBC-limited | SpellFocus not in DBC |
| P0 | missing_creature_template | 40 | loa INSERT | Entry 68993 skipped |
| P5 | smartai_validation | 10 | loa.smart_scripts | Kill credit warnings |

## Addressed in 2026-06-25 SQL batch

- P0 missing creature templates → `2026-06-25_world_06.sql`
- P0 missing GO templates (where LOA has data) → `2026-06-25_world_07.sql`
- P0 orphan GO 212922 → `2026-06-25_world_08.sql`
- P2 partial (empty ScriptName sync) → `2026-06-25_world_09.sql`, `2026-06-25_world_13.sql`

## Next recommended work

1. Re-run worldserver after applying 2026-06-25 batch; diff DBErrors line count.
2. Expand P2 fixes using LOA `creature_template.ScriptName` / `spell_script_names` diffs.
3. Zone-by-zone LOA ports beyond 860/870 (Vale, Krasarang, etc.).
4. Do not bulk-import Trinity retail SQL.

Full CSV: `tools/db-port/output/dberrors_backlog.csv`

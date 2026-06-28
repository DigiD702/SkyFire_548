# SkyFire MoP Baseline Report

Generated: 2026-06-25

## Database versions

| Database | Version |
|----------|---------|
| world (SkyFire) | SFDB 548.Release.24.000 |
| loa (Legends of Azeroth) | DB_2020_07_12 |
| trinitycore | Retail ~12.x (reference only) |
| trinitycore_hotfixes | Retail hotfixes (reference only) |

## Table inventory

| Database | Tables |
|----------|-------:|
| world | 174 |
| loa | 230 |
| trinitycore | 250 |
| trinitycore_hotfixes | 467 |

Trinity retail tables are **not** direct port targets for SkyFire MoP.

## Exact row counts (world vs loa)

| Table | world | loa | Delta |
|-------|------:|----:|------:|
| creature_template | 57164 | 57517 | +353 |
| creature | 224086 | 315216 | +91130 |
| gameobject_template | 36010 | 41363 | +5353 |
| gameobject | 70584 | 170208 | +99624 |
| quest_template | 17930 | 18028 | +98 |
| quest_objective | 16160 | 17399 | +1239 |
| smart_scripts | 15926 | 43699 | +27773 |
| conditions | 9421 | 22412 | +12991 |
| creature_text | 7183 | 23112 | +15929 |
| spell_script_names | 1110 | 4888 | +3778 |
| scene_template | 4 | 73 | +69 |
| terrain_phase_info | 0 | 0 | 0 |
| spell_proc | 0 | 0 | 0 |
| hotfix_data | 0 | 1 | +1 |
| waypoints | 1644 | 6088 | +4444 |

## MoP map coverage (creature spawns)

| Map | world | loa |
|-----|------:|----:|
| 860 (Wandering Island) | 3326 | 2138 |
| 870 (Jade Forest) | 29696 | 36632 |

## Script coverage

| Layer | SkyFire | Notes |
|-------|--------:|-------|
| smart_scripts loaded | ~15926 rows | Major gap vs LOA 43699 |
| C++ Pandaria scripts | 7 files | Was 6; added boss_wise_mari |
| Unbound C++ scripts (DBErrors) | 990 | P2 backlog |

## Empty-but-loaded tables (Server.log)

- `scene_template` — addressed by `2026-06-25_world_10.sql`
- `terrain_phase_info` — empty in LOA too; no SQL port yet
- `spell_proc` — empty in LOA too; no SQL port yet
- `hotfix_data` — addressed by `2026-06-25_world_14.sql`

## Detailed exports

Machine-readable data: `tools/db-port/output/`

- `schema.tsv`, `rows.tsv`, `rowsExact.tsv`
- `missing.tsv`, `maps.tsv`
- `dberrors_backlog.csv`, `script_gap.csv`

## Update record

All new SQL is in `sql/updates/world/` — see [`sql/updates/PORTING_LOG.md`](../sql/updates/PORTING_LOG.md).

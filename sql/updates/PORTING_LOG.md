# LOA Porting Update Log

Local-only SQL updates for MoP 5.4.8 porting work. **Do not push automatically** — use this log when preparing a PR to Project Skyfire upstream.

## LOA database status

**LOA is a frozen one-time reference**, not a living sync source. The `loa` MySQL database (Legends of Azeroth snapshot) is unmaintained and **will not receive updates**. All useful LOA data is already baked into portable `sql/updates/world/*.sql` files.

- **Consumers / fresh installs:** only need SFDB base + `sql/updates/world/` — no LOA DB required.
- **Future MoP work:** edit SkyFire SQL directly (wiki, SFDB, hand fixes) — not re-ports from LOA.
- **Dedup `_05`:** static cleanup for the one-time LOA spawn batch; not something to regenerate when "LOA changes."

## Workflow

1. **Develop locally** on `world_staging`: apply LOA source SQL from `sql/updates/world_loa/` (requires LOA DB).
2. Fix DBErrors on staging; validate server boot.
3. **Materialize** portable SQL into `sql/updates/world/` (no LOA required for consumers).
4. Keep small standalone fixes (DELETEs, cleanup) in `sql/updates/world/` as `YYYY-MM-DD_world_XX.sql`.
5. Record changes in this log. Test on staging before production `world`.

### SQL update hygiene

- **Bad update shipped:** delete the file from `sql/updates/world/` — do **not** add a separate “revert” SQL file.
- **Crash bisect / local test:** if you DELETE or disable data to test a theory and it was not the cause, put the data back in the normal port file (or re-add the original file) before commit — not a `restore_*` follow-up.
- **Already applied on your DB:** remove the bad row from `world.version` if needed; re-run idempotent `INSERT IGNORE` ports (e.g. `_04` shrine vendors) on next boot.
- **Save SQL as UTF-8 without BOM** (PowerShell `Set-Content -Encoding UTF8` adds a BOM that breaks MySQL).

### LOA source vs portable (upstream) SQL

| Folder | Requires LOA DB? | For upstream PR? |
|--------|------------------|------------------|
| `sql/updates/world_loa/` | Yes | **No** — local porting sources (`world_06`–`world_70` LOA scripts) |
| `sql/updates/world/` (`2026-06-26_*` materialized) | No | **Yes** — INSERT/UPDATE delta from staging |
| `sql/updates/world/` (`2026-06-25_world_*` standalone) | No | Yes — cleanup DELETEs, script fixes (`_08`, `_19`–`_29`, `_36`, `_43`, `_50`, `_57`, `_64`, `_71`) |

**Materialize after staging is validated:**

```powershell
cd tools\db-port
.\move_loa_sources.ps1   # once: moves `` `loa`. `` scripts out of world/
.\materialize_staging_delta.ps1 -DryRun
.\materialize_staging_delta.ps1 -SplitCreatureByMap -IncludeTemplateUpdates
```

Apply order: `sql/updates/world/2026-06-26_MANIFEST.txt`

Docs: `tools/db-port/docs/PORTABLE_SQL.md`

## 2026-06-26 materialized bundle (upstream-ready)

Generated from `world` (SFDB baseline) vs `world_staging` (all LOA ports applied). **65 files, ~24.4 MB** in `sql/updates/world/`.

| Export | Rows (approx) |
|--------|----------------|
| `creature_map*.sql` (23 maps, split parts) | 56,157 spawns |
| `creature_template.sql` | 633 INSERTs |
| `creature_template_updates.sql` | 3,495 UPDATEs |
| `smart_scripts` (+ 2 parts) | 3,076 |
| `spell_script_names` (+ 3 parts) | 4,246 |
| `creature_model_info.sql` | 459 |
| `waypoints.sql` | 217 |
| `hotfix_data`, `areatrigger_scripts`, `achievement_criteria_data` | small |

**Removed from bundle:** `scene_template.sql` — bulk LOA scene rows crash 5.4.8 client at Shrine (DB2 OOM). SFDB baseline (4 rows) only; do not re-materialize without per-scene validation.

**54 LOA source scripts** moved to `sql/updates/world_loa/`. Staging boot at materialize time: 0 missing creature/GO, 0 unbound script, 0 missing model (109 SmartAI warnings only).

**Note:** Materialize does not export DELETEs — standalone cleanup scripts (`_19`, `_20`, `_27`, etc.) still apply after the delta per manifest.

## 2026-06-26 manifest validation (fresh SFDB)

Applied `2026-06-26_MANIFEST.txt` to `world_validate` (imported from `sql/world.sql` + 116 manifest files) and compared to `world_staging`:

| Table | Match |
|-------|-------|
| creature | OK (280,243) |
| creature_template | OK (57,797) |
| smart_scripts | OK (19,002) |
| creature_model_info | OK (38,274) |
| waypoints | OK (1,861) |
| scene_template | SFDB baseline only (4 rows) — LOA scenes not ported |
| hotfix_data | **removed** — LOA row crashes client login (see `_09`) |
| All 9 outdoor MoP maps | OK |
| spell_script_names | 5,357 vs 5,356 (+1 in validate) |

**Tooling:** `tools/db-port/apply_manifest.ps1` — imports `sql/world.sql`, applies manifest, compares counts.

**Materialize baseline:** use `-BaselineSql sql/world.sql -BaselineDb world_sfdb` so the delta matches the upstream SFDB dump (the live `world` DB was older than `sql/world.sql`).

**Fixes applied during validation:** composite-key export for chunked tables, PowerShell single-element array unwrapping, creature part file overwrite, spell_script_names sub-chunking for Windows command-line limits.

## SFDB baseline evaluation

| Item | Current | Recommendation |
|------|---------|----------------|
| SkyFire world | SFDB 548.Release.24.000 | Keep as base for now |
| Bundled upgrade | SFDB 548.Release.24.001 in `sql/SFDB_full_548_24.001_2024_09_04_Release/` | Apply as full restore **before** LOA ports if you want a cleaner upstream diff; otherwise continue incremental LOA SQL on 24.000 |
| LOA reference | DB_2020_07_12 | Use for gap-fill only, not full replace |

## 2026-06-25 batch (LOA baseline port)

| File | Phase | Description | Source | Tested |
|------|-------|-------------|--------|--------|
| `2026-06-25_world_06.sql` | Quick wins | Missing creature_template (68993, 73422, 74010, 74012, 74019) — LOA→SkyFire column map | loa | staging OK |
| `2026-06-25_world_07.sql` | Quick wins | Missing gameobject_template (213074, 215413) — LOA→SkyFire column map | loa | staging OK |
| `2026-06-25_world_08.sql` | Quick wins | Remove orphan GO spawn 212922 (no LOA template) | DBErrors | staging OK |
| `2026-06-25_world_09.sql` | Quick wins | ScriptName/script sync from LOA for empty bindings | loa | staging OK |
| `2026-06-25_world_10.sql` | Core mechanics | scene_template — **moved to world_loa/**; not in portable bundle (client crash) | loa | do not apply to world |
| `2026-06-25_world_11.sql` | LOA zones | Creature spawns maps 860, 870 | loa | staging OK |
| `2026-06-25_world_12.sql` | LOA zones | smart_scripts for maps 860, 870 | loa | staging OK |
| `2026-06-25_world_13.sql` | LOA zones | creature_template AIName/ScriptName sync maps 860, 870 | loa | staging OK |
| `2026-06-25_world_14.sql` | Core mechanics | hotfix_data from LOA — **disabled** (client login crash) | loa | superseded by `_09` |
| `2026-06-25_world_15.sql` | LOA zones | creature_template for 202 missing entries on maps 860/870 (spawn follow-up) | loa | staging OK |
| `2026-06-25_world_16.sql` | LOA zones | creature_model_info for zone port models + P0 models 47022/51322 | loa | staging OK |
| `2026-06-25_world_17.sql` | Quick wins | creature_model_info for 6 remaining global model gaps | loa | staging OK |
| `2026-06-25_world_18.sql` | LOA zones | SmartAI `waypoints` for maps 860/870 WP_START paths | loa | staging OK |
| `2026-06-25_world_19.sql` | LOA zones | Remove unloadable SmartAI rows (unsupported action/event types) on 860/870 | cleanup | staging OK |
| `2026-06-25_world_20.sql` | Quick wins | Delete SmartAI rows with missing spells 131053 and 215377 | cleanup | staging applied |
| `2026-06-25_world_21.sql` | Script bindings | spell_script_names gap-fill from LOA | loa | staging applied |
| `2026-06-25_world_22.sql` | Script bindings | Fix mismatched creature/GO ScriptNames + achievement criteria | SFDB/LOA | staging applied |
| `2026-06-25_world_23.sql` | LOA zones | Creature spawns maps 859 (Krasarang), 861 (Kun-Lai) | loa | staging applied |
| `2026-06-25_world_24.sql` | LOA zones | smart_scripts for maps 859, 861 | loa | staging applied |
| `2026-06-25_world_25.sql` | LOA zones | creature_template AIName/ScriptName sync maps 859, 861 | loa | staging applied |
| `2026-06-25_world_26.sql` | LOA zones | SmartAI waypoints for maps 859, 861 | loa | staging applied |
| `2026-06-25_world_27.sql` | LOA zones | Remove unloadable SmartAI on maps 859, 861 | cleanup | staging applied |
| `2026-06-25_world_28.sql` | Script bindings | MoP Wandering Island ScriptName fixes + HOR/pet/achievement SFDB bindings | SFDB | staging applied |
| `2026-06-25_world_29.sql` | Script bindings | spell_script_names for 67 unbound C++ spell scripts + fire elemental pet | SFDB/C++ | staging applied |
| `2026-06-25_world_30.sql` | LOA zones | Creature spawns map 1064 (Townlong Steppes) | loa | staging applied |
| `2026-06-25_world_31.sql` | LOA zones | creature_template for missing entries on map 1064 | loa | staging applied |
| `2026-06-25_world_32.sql` | LOA zones | creature_model_info for map 1064 zone port | loa | staging applied |
| `2026-06-25_world_33.sql` | LOA zones | smart_scripts for map 1064 | loa | staging applied |
| `2026-06-25_world_34.sql` | LOA zones | creature_template AIName/ScriptName sync map 1064 | loa | staging applied |
| `2026-06-25_world_35.sql` | LOA zones | SmartAI waypoints for map 1064 | loa | staging applied |
| `2026-06-25_world_36.sql` | LOA zones | Remove unloadable SmartAI on map 1064 | cleanup | staging applied |
| `2026-06-25_world_37.sql` | LOA zones | Creature spawns map 1050 (Dread Wastes) | loa | staging applied |
| `2026-06-25_world_38.sql` | LOA zones | creature_template for missing entries on map 1050 | loa | staging applied |
| `2026-06-25_world_39.sql` | LOA zones | creature_model_info for map 1050 | loa | staging applied |
| `2026-06-25_world_40.sql` | LOA zones | smart_scripts for map 1050 (0 LOA outdoor rows) | loa | staging applied |
| `2026-06-25_world_41.sql` | LOA zones | creature_template AIName/ScriptName sync map 1050 | loa | staging applied |
| `2026-06-25_world_42.sql` | LOA zones | SmartAI waypoints for map 1050 | loa | staging applied |
| `2026-06-25_world_43.sql` | LOA zones | Remove unloadable SmartAI on map 1050 | cleanup | staging applied |
| `2026-06-25_world_44.sql` | LOA zones | Creature spawns map 1098 (Isle of Thunder) | loa | staging applied |
| `2026-06-25_world_45.sql` | LOA zones | creature_template for missing entries on map 1098 | loa | staging applied |
| `2026-06-25_world_46.sql` | LOA zones | creature_model_info for map 1098 | loa | staging applied |
| `2026-06-25_world_47.sql` | LOA zones | smart_scripts for map 1098 | loa | staging applied |
| `2026-06-25_world_48.sql` | LOA zones | creature_template AIName/ScriptName sync map 1098 | loa | staging applied |
| `2026-06-25_world_49.sql` | LOA zones | SmartAI waypoints for map 1098 | loa | staging applied |
| `2026-06-25_world_50.sql` | LOA zones | Remove unloadable SmartAI on map 1098 | cleanup | staging applied |
| `2026-06-25_world_51.sql` | LOA zones | Creature spawns map 1135 (Timeless Isle) | loa | staging applied |
| `2026-06-25_world_52.sql` | LOA zones | creature_template for missing entries on map 1135 | loa | staging applied |
| `2026-06-25_world_53.sql` | LOA zones | creature_model_info for map 1135 | loa | staging applied |
| `2026-06-25_world_54.sql` | LOA zones | smart_scripts for map 1135 (0 LOA outdoor rows) | loa | staging applied |
| `2026-06-25_world_55.sql` | LOA zones | creature_template AIName/ScriptName sync map 1135 | loa | staging applied |
| `2026-06-25_world_56.sql` | LOA zones | SmartAI waypoints for map 1135 | loa | staging applied |
| `2026-06-25_world_57.sql` | LOA zones | Remove unloadable SmartAI on map 1135 | cleanup | staging applied |
| `2026-06-25_world_58.sql` | LOA zones | Creature spawns map 1004 | loa | staging applied |
| `2026-06-25_world_59.sql` | LOA zones | creature_template for missing entries on map 1004 | loa | staging applied |
| `2026-06-25_world_60.sql` | LOA zones | creature_model_info for map 1004 | loa | staging applied |
| `2026-06-25_world_61.sql` | LOA zones | smart_scripts for map 1004 (0 LOA rows) | loa | staging applied |
| `2026-06-25_world_62.sql` | LOA zones | creature_template AIName/ScriptName sync map 1004 | loa | staging applied |
| `2026-06-25_world_63.sql` | LOA zones | SmartAI waypoints for map 1004 | loa | staging applied |
| `2026-06-25_world_64.sql` | LOA zones | Remove unloadable SmartAI on map 1004 | cleanup | staging applied |
| `2026-06-25_world_65.sql` | LOA instances | Creature spawns MoP dungeons/raids (14 maps) | loa | staging applied |
| `2026-06-25_world_66.sql` | LOA instances | creature_template for missing dungeon/raid entries | loa | staging applied |
| `2026-06-25_world_67.sql` | LOA instances | creature_model_info for dungeon/raid maps | loa | staging applied |
| `2026-06-25_world_68.sql` | LOA instances | smart_scripts for dungeon/raid creatures | loa | staging applied |
| `2026-06-25_world_69.sql` | LOA instances | creature_template AIName/ScriptName sync dungeon/raids | loa | staging applied |
| `2026-06-25_world_70.sql` | LOA instances | SmartAI waypoints for dungeon/raid maps | loa | staging applied |
| `2026-06-25_world_71.sql` | LOA instances | Remove unloadable SmartAI on dungeon/raid maps | cleanup | staging applied |
| `2026-06-27_world_00.sql` | Login/play | Hunter starting pet spell_cast cleanup (upstream) | upstream | — |
| `2026-06-27_world_01.sql` | Login/play | Remove obsolete playercreateinfo_spell rows (upstream) | upstream | — |
| `2026-06-27_world_02.sql` | Map 0 | Bellygrub (345): remove 3 stacked duplicate Redridge spawns | cleanup | SFDB baseline |
| `2026-06-27_world_09.sql` | All maps | Import missing `npc_vendor` rows from LOA (global vendors; excludes Shrine 64001–64099) | loa | `generate_vendor_fix_from_loa.ps1` |
| `2026-06-27_world_03.sql` | Map 870 | `creature_text` for Shrine Hearthstone NPCs 64071/64072/64115 (SmartAI OOC talk) | wiki | manual |
| `2026-06-27_world_04_shrine_npc_vendor.sql` | Map 870 | Shrine vendor stock `npc_vendor` 64001–64099 (LOA) | loa | slice of vendor import |
| `2026-06-27_world_05.sql` | All maps | **Static** spawn dedup (1958 guids). Apply after all `creature_map*.sql` | cleanup | committed SQL |
| `2026-06-27_world_08.sql` | All maps | Supplement dedup (926 guids) if old 1032-row `_05` already applied | cleanup | run once on existing DBs, or use merged `_05` on fresh wipe |
| `2026-06-27_world_06.sql` | Misc | Sayge SmartAI: remove broken spell 23770 link script | cleanup | SQL only (no core rebuild required) |
| `2026-06-27_world_07.sql` | Misc | DBErrors P1-P3: GO templates 213074/215413, fishing bobber respawn, creature_text 19220, equip templates, Luo Luo flags_extra | cleanup | manual |
| `2026-06-28_world_09.sql` | Login fix | Remove LOA `hotfix_data` item 32549 (client Error #132 stack_overflow on login) | cleanup | applied |
| `2026-06-28_world_10.sql` | Map 870 | Remove 18,335 LOA-only redundant wilderness spawns (SFDB baseline already covered outdoor Pandaria; fixes client memory errors in Valley of Four Winds) | cleanup | manual |

## Core code (not SQL)

| Change | Description | Status |
|--------|-------------|--------|
| `DBCStores.cpp` scenario MapDifficulty | LOA-style entries for maps 999/1000/1050/1135 etc. | **reverted** — did not fix login crash; hotfix_data was separate suspect |
| `boss_wise_mari.cpp` | Temple of Jade Serpent Wise Mari boss (`boss_wase_mari` matches LOA typo) | added locally |
| `ScriptLoader.cpp` | Register `AddSC_boss_wase_mari` | added locally |
| `Pandaria/CMakeLists.txt` | Build boss_wise_mari.cpp | added locally |

## Notes

- Trinity retail 12.x has no MoP dungeon C++ scripts; Pandaria boss work uses LOA DB bindings + new SkyFire scripts.
- Cross-database SQL (`loa.*`) requires LOA database on the same MySQL host during apply.
- LOA mysqldump exports are **not** schema-compatible with SkyFire. Use `INSERT ... SELECT` with column mapping (see `2026-06-25_world_06.sql` for creature_template, `_07` for gameobject_template, `_12` for smart_scripts).
- **Spawn dedup:** `2026-06-27_world_05.sql` is the static DELETE list (1958 guids). Fresh wipe: merged `_05` only. DB that already applied old 1032-row `_05`: also apply `_08`.
- Audit tooling: `tools/db-port/` (baseline reports in `tools/db-port/output/`).
- Staging logs: `C:\SkyFire_Files\Server_staging\server.log` and `dberrors.log` (overwrite enabled in worldserver.conf).

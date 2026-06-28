# Database porting audit toolkit

Tools for comparing SkyFire (`world`), Legends of Azeroth (`loa`), and Trinity retail (`trinitycore` / `trinitycore_hotfixes`) during MoP 5.4.8 porting work.

## Prerequisites

- MySQL client on PATH or at `C:\tools\mysql\current\bin\mysql.exe`
- PowerShell
- Local databases: `world`, `loa`, `trinitycore`, `trinitycore_hotfixes`

## SQL update hygiene

When editing `sql/updates/world/`:

- Remove a bad update file instead of adding a “revert” SQL.
- After a failed bisect, re-add data in the normal port file (`INSERT IGNORE`), not a `restore_*` patch.
- Write `.sql` files **UTF-8 without BOM** (`[System.IO.File]::WriteAllText` with `UTF8Encoding $false`).

## Quick start

```powershell
cd C:\SkyFire_548\tools\db-port

# Full baseline (creates world_staging if missing, writes reports)
.\run_baseline.ps1

# Recreate staging from production world
.\run_baseline.ps1 -RecreateStaging
```

## Individual tools

| Script | Purpose |
|--------|---------|
| `clone_staging.ps1` | Clone `world` -> `world_staging` |
| `schema_diff.sql` | Table/column diffs between world and loa |
| `row_counts.sql` | Fast row-count estimates for priority tables |
| `row_counts_exact.sql` | Exact counts for key tables |
| `missing_templates.sql` | Spawn rows referencing missing templates |
| `map_coverage.sql` | Coverage by expansion map tier |
| `dberrors_parser.ps1` | Categorize `DBErrors.log` into P0-P5 backlog |
| `script_gap.ps1` | Heuristic C++ script name vs DB assignment gap |
| `export_staging_dbc.ps1` | Export staging DBCs via WDBX Editor (`Spell.dbc`, `Map.dbc`, etc.) to csv/json/sql |
| `materialize_staging_delta.ps1` | Export `world_staging` vs `world` delta as portable INSERT/UPDATE SQL (no LOA) |
| `scan_duplicate_spawns.ps1` | Find stacked duplicate spawns; generate DELETE SQL (vendor-only or all NPCs) |
| `scan_loa_nearstack_dupes.ps1` | LOA guid within N yd of SFDB twin (same entry) |
| `generate_spawn_dedup_update.ps1` | Optional audit: find LOA-vs-SFDB duplicate spawns → `output/spawn_dedup_preview.sql` (dev only; `_05` in repo is static) |
| `scan_spawn_classification.ps1` | Classify spawns as singleton/pack/service using SFDB baseline counts |
| `analyze_server_dberrors.ps1` | Summarize latest boot from `C:\SkyFire_Files\Server\DBErrors.log` |
| `generate_vendor_fix_from_loa.ps1` | Import missing `npc_vendor` stock from LOA for flagged vendors |

See [docs/PORTABLE_SQL.md](docs/PORTABLE_SQL.md) for the two-tier LOA vs upstream workflow.

## Configuration

Edit `config.ps1` or set environment variables:

- `DB_PORT_HOST`, `DB_PORT_PORT`, `DB_PORT_USER`, `DB_PORT_PASSWORD`
- `MYSQL_BIN`, `MYSQLDUMP_BIN`

## Safe SQL workflow

1. Never edit `world` directly during experiments.
2. Clone to `world_staging` with `clone_staging.ps1`.
3. Apply test SQL to `world_staging`.
4. Point a test `worldserver.conf` `WorldDatabaseInfo` at `world_staging` or use manual verification queries.
5. Record each new file in `sql/updates/PORTING_LOG.md` (local-only until upstream PR).
6. Apply to staging with `apply_updates_to_staging.ps1` before production `world`.

## Staging validation (full loop)

1. Apply SQL: `.\apply_updates_to_staging.ps1 -Filter 'YYYY-MM-DD_world_*.sql'`
2. Build/install staging server — see `docs/staging-workflow.md`
3. Run `worldserver.exe` from `C:\SkyFire_Files\Server_staging`
4. Review `server.log` and `db.log` in that folder

## Outputs

- `tools/db-port/output/` - TSV/CSV exports
- `docs/baseline-report.md` - human-readable baseline summary
- `docs/port-backlog.md` - DBErrors categorized backlog
- `sql/updates/PORTING_LOG.md` - record of each SQL update for future upstream push

## LOA reference (frozen)

The `loa` database is a **one-time snapshot** used during the initial port. It is not maintained and will not be updated. Portable SQL in `sql/updates/world/` is the source of truth going forward.

Optional: `export_loa_table.ps1` if you still have the snapshot loaded locally and need to re-check a table.

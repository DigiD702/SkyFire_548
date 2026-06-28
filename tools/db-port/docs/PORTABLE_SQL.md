# Portable SQL workflow (no LOA required for consumers)

## Problem

Scripts like `INSERT ... SELECT FROM loa.creature` only work when a local **LOA** database exists. They are fine for private porting but **cannot be pushed upstream** as-is.

## Solution: two-tier SQL

| Location | Purpose | Push to upstream? |
|----------|---------|-------------------|
| `sql/updates/world_loa/` | LOA cross-DB **source** scripts (regenerate locally) | No — local-only |
| `sql/updates/world/` (`YYYY-MM-DD_*` materialized) | **Materialized** INSERT/UPDATE delta anyone can apply | **Yes** |
| `sql/updates/world/` (`YYYY-MM-DD_world_XX` standalone) | Small fixes (DELETEs, script bindings) | Yes |

## Workflow going forward

1. **Develop locally** (requires LOA + `world_staging`):
   - Run LOA port SQL from `world_loa/` or generate with `generate_zone_port.ps1`
   - Apply with `apply_updates_to_staging.ps1`
   - Fix DBErrors on staging

2. **Materialize for upstream** (baseline must match `sql/world.sql` for contributors):
   ```powershell
   cd tools\db-port
   .\materialize_staging_delta.ps1 -DryRun -BaselineDb world_sfdb -BaselineSql ..\..\sql\world.sql
   .\materialize_staging_delta.ps1 -SplitCreatureByMap -IncludeTemplateUpdates -BaselineDb world_sfdb -BaselineSql ..\..\sql\world.sql
   ```

3. **Validate on fresh SFDB** (optional):
   ```powershell
   .\apply_manifest.ps1 -Database world_validate
   ```

4. **Commit** materialized files in `sql/updates/world/` (see `2026-06-26_MANIFEST.txt` for apply order).

5. **Consumers** apply portable SQL in manifest order — no LOA database.

## Retroactive fix (existing `world_06`–`world_71`)

Import **`sql/world.sql`** as the baseline (not the older live `world` DB). **`world_staging`** has all LOA ports applied.

```powershell
.\materialize_staging_delta.ps1 -DryRun -BaselineDb world_sfdb -BaselineSql ..\..\sql\world.sql
.\materialize_staging_delta.ps1 -SplitCreatureByMap -IncludeTemplateUpdates -BaselineDb world_sfdb -BaselineSql ..\..\sql\world.sql
.\apply_manifest.ps1 -Database world_validate
```

This does **not** re-run LOA queries; it diffs staging vs baseline using mysqldump `INSERT` statements.

### What to do with old LOA scripts

- **LOA scripts** live in `sql/updates/world_loa/` (run `move_loa_sources.ps1` if any creep back into `world/`).
- **Do not push** files containing `` `loa`. `` to upstream.
- **Push** the materialized `sql/updates/world/2026-06-26_*` bundle + standalone cleanup scripts.

### PR packaging suggestion

One PR with manifest order from `sql/updates/world/2026-06-26_MANIFEST.txt`:

```
sql/updates/world/2026-06-26_creature_map860.sql
sql/updates/world/2026-06-26_creature_map870_part*.sql
...
sql/updates/world/2026-06-26_spell_script_names_part*.sql
sql/updates/world/2026-06-26_creature_template_updates.sql
sql/updates/world/2026-06-25_world_28.sql   # standalone script fixes
sql/updates/world/2026-06-25_world_29.sql
```

## Generating portable SQL directly from LOA (future)

For small batches, use existing `export_loa_table.ps1`:

```powershell
.\export_loa_table.ps1 -Table creature_template -Where "entry IN (68993,73422)" -OutFile ..\..\sql\updates\world\fix_templates.sql
```

For zone ports, prefer: **LOA port → staging test → materialize delta**.

## Baseline requirement

Materialization compares `world` (unchanged SFDB) vs `world_staging` (ported). If you apply ports to `world` directly, re-clone staging from world before the next materialize, or snapshot baseline first:

```powershell
.\clone_staging.ps1 -Force   # only when you want to reset staging from world
```

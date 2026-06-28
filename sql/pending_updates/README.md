# Pending SQL Updates

This directory is no longer the primary workflow for MoP porting work.

**Use instead:**

- `sql/updates/world/` — all new SQL updates
- `sql/updates/PORTING_LOG.md` — record of each update for future upstream push
- `tools/db-port/` — audit tooling and staging apply scripts

The server database updater reads `sql/updates/<database>` when AutoSetup is enabled.

## Staging test workflow

```powershell
cd C:\SkyFire_548\tools\db-port
.\clone_staging.ps1
.\apply_updates_to_staging.ps1 -Filter '2026-06-25_world_*.sql'
```

Do **not** push to any remote repository until updates are reviewed and tested.

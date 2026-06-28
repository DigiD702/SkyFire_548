# LOA source SQL (local-only)

These scripts use `` `loa`. `` cross-database queries and **require a local LOA database**.

They are **not** for upstream PRs. Use them to regenerate ports on `world_staging`, then run:

```powershell
cd tools\db-port
.\materialize_staging_delta.ps1 -SplitCreatureByMap -IncludeTemplateUpdates
```

Portable output is written to `sql/updates/world/`.

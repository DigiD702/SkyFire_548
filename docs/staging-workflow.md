# Staging database workflow

SkyFire porting work must not mutate the production `world` database during experiments.

## Staging database

- **Production:** `world` (SFDB 548.Release.24.000)
- **Staging:** `world_staging` (clone of `world`)

Create or refresh staging:

```powershell
cd C:\SkyFire_548\tools\db-port
.\clone_staging.ps1          # create if missing
.\clone_staging.ps1 -Force   # drop and recreate from world
```

## Test SQL safely

1. Add SQL to `sql/updates/world/` and log it in `sql/updates/PORTING_LOG.md`.
2. Apply updates to staging:

```powershell
.\apply_updates_to_staging.ps1 -Filter '2026-06-25_world_*.sql'
```

3. Optional: point a test `worldserver.conf` at staging:

```ini
WorldDatabaseInfo = "127.0.0.1;3306;root;PASSWORD;world_staging"
```

4. Boot worldserver and compare logs against baseline (see **Build and run staging server** below).

## Build and run staging server

Use a separate build/install tree for staging so production `C:\SkyFire_Files\Server` is untouched.

### Environment variables

```powershell
$env:BOOST_ROOT = "C:\local\boost_1_91_0"
$env:OPENSSL_ROOT_DIR = "C:\Program Files\OpenSSL-Win64"
$env:OPENSSL_MODULES = "C:\Program Files\OpenSSL-Win64\bin"
$env:MYSQL_ROOT = "C:\tools\mysql\current"
```

### Configure (use `build_staging` consistently for staging)

```powershell
cmake -S C:\SkyFire_548 -B C:\SkyFire_548\build_staging `
  -G "Visual Studio 17 2022" `
  -A x64 `
  -DCMAKE_INSTALL_PREFIX="C:\SkyFire_Files\Server_staging" `
  -DTOOLS=OFF `
  -DELUNA=ON `
  -DBOOST_ROOT="$env:BOOST_ROOT" `
  -DOPENSSL_ROOT_DIR="$env:OPENSSL_ROOT_DIR"
```

### Compile and install

```powershell
cmake --build C:\SkyFire_548\build_staging --config Release --parallel
cmake --build C:\SkyFire_548\build_staging --config Release --target install
```

### Run worldserver

From `C:\SkyFire_Files\Server_staging`:

```powershell
cd C:\SkyFire_Files\Server_staging
.\worldserver.exe
```

Ensure `worldserver.conf` in that folder points at `world_staging` for `WorldDatabaseInfo`.

### Staging logs

| Log | Path |
|-----|------|
| Server log | `C:\SkyFire_Files\Server_staging\server.log` |
| DB errors | `C:\SkyFire_Files\Server_staging\dberrors.log` |

**Important:** `worldserver.conf` must use `world_staging` in `WorldDatabaseInfo`, not `world`.

Compare these after each SQL batch to measure DBErrors reduction and load-count changes.

### Production build (reference)

Production install prefix remains `C:\SkyFire_Files\Server` with build dir `C:\SkyFire_548\build` when not testing ports.


## Upstream promotion (manual, when ready)

1. Verify on `world_staging`
2. Apply logged files from `sql/updates/world/` to production `world`
3. Open PR to Project Skyfire with the same files — **do not push until reviewed**

## LOA export helper

```powershell
.\export_loa_table.ps1 -Table creature_template -Where "entry IN (68993,73422)"
```

Exports INSERT statements from `loa` into `sql/updates/world`.

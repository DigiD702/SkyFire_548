# Analyzes staging dberrors.log (latest boot only when log is appended across runs).
param([string]$LogFile = 'C:\SkyFire_Files\Server_staging\dberrors.log')

& (Join-Path $PSScriptRoot 'analyze_staging_dberrors.ps1') -LogFile $LogFile

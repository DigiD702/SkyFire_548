# Make materialized INSERT statements idempotent (INSERT IGNORE).
param(
    [string]$Path = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path 'sql\updates\world'),
    [string]$Filter = '2026-06-26_*.sql'
)

$fixed = 0
Get-ChildItem -Path $Path -Filter $Filter -File | ForEach-Object {
    $content = [System.IO.File]::ReadAllText($_.FullName)
    $updated = $content -replace '(?m)^INSERT INTO ', 'INSERT IGNORE INTO '
    if ($updated -ne $content) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($_.FullName, $updated, $utf8NoBom)
        $fixed++
        Write-Host "Updated $($_.Name)"
    }
}

Write-Host "Done. Updated $fixed file(s)."

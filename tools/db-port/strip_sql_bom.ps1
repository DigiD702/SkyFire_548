# Remove UTF-8 BOM from SQL files (PowerShell Out-File -Encoding utf8 adds BOM).
param(
    [string]$Path = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path 'sql\updates\world'),
    [string]$Filter = '2026-06-26*'
)

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$fixed = 0

Get-ChildItem -Path $Path -Filter $Filter -File | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $text = $utf8NoBom.GetString($bytes, 3, $bytes.Length - 3)
        [System.IO.File]::WriteAllText($_.FullName, $text, $utf8NoBom)
        $fixed++
        Write-Host "Stripped BOM: $($_.Name)"
    }
}

Write-Host "Done. Stripped BOM from $fixed file(s)."

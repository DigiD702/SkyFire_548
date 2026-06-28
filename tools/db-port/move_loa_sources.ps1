$loaDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path 'sql\updates\world_loa'
$worldDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path 'sql\updates\world'
New-Item -ItemType Directory -Path $loaDir -Force | Out-Null

$moved = 0
Get-ChildItem (Join-Path $worldDir '2026-06-25_world_*.sql') | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '`loa`\.') {
        Move-Item -LiteralPath $_.FullName -Destination $loaDir -Force
        $moved++
        Write-Host "Moved $($_.Name) (loa cross-db)"
        return
    }

    $loaCopy = Join-Path $loaDir $_.Name
    if (Test-Path $loaCopy) {
        Remove-Item -LiteralPath $_.FullName -Force
        $moved++
        Write-Host "Removed duplicate $($_.Name) (already in world_loa)"
    }
}
Write-Host "Total cleaned: $moved"

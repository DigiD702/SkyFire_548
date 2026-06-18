<#
.SYNOPSIS
Reports src/server/game metrics and optionally checks game files for tabs.

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File tools/dev/game_metrics.ps1

.EXAMPLE
powershell -NoProfile -ExecutionPolicy Bypass -File tools/dev/game_metrics.ps1 -CheckNoTabs -ChangedSince origin/main
#>

[CmdletBinding()]
param(
    [string] $Root = '',
    [string] $Scope = 'src/server/game',
    [string[]] $Extensions = @('.cpp', '.h'),
    [int] $Top = 10,
    [switch] $CheckNoTabs,
    [string] $ChangedSince,
    [string] $DebtPattern = '(?i)(TODO|FIXME|HACK|XXX|@todo)'
)

$ErrorActionPreference = 'Stop'

function Resolve-FullPath {
    param([string] $Path)

    $resolved = Resolve-Path -LiteralPath $Path
    return $resolved.ProviderPath
}

function Convert-ToRepoPath {
    param(
        [string] $Path,
        [string] $RootPath
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($RootPath)

    if (-not $fullRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $fullRoot += [System.IO.Path]::DirectorySeparatorChar
    }

    if ($fullPath.StartsWith($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $fullPath.Substring($fullRoot.Length).Replace('\', '/')
    }

    return $fullPath.Replace('\', '/')
}

function Test-SourceExtension {
    param(
        [string] $Path,
        [string[]] $AllowedExtensions
    )

    $extension = [System.IO.Path]::GetExtension($Path)
    return $AllowedExtensions -contains $extension
}

function Get-GameFiles {
    param(
        [string] $RootPath,
        [string] $ScopePath,
        [string[]] $AllowedExtensions,
        [string] $BaseRef
    )

    if ($BaseRef) {
        $range = "$BaseRef...HEAD"
        $changedFiles = & git -C $RootPath diff --name-only --diff-filter=ACMRT $range -- $ScopePath
        if ($LASTEXITCODE -ne 0) {
            throw "git diff failed for base ref '$BaseRef'. Make sure the ref is fetched."
        }

        $files = @()
        foreach ($relativePath in $changedFiles) {
            if (-not $relativePath) {
                continue
            }

            if (-not (Test-SourceExtension -Path $relativePath -AllowedExtensions $AllowedExtensions)) {
                continue
            }

            $fullPath = Join-Path $RootPath $relativePath
            if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                $files += Get-Item -LiteralPath $fullPath
            }
        }

        return $files | Sort-Object FullName -Unique
    }

    $fullScope = Join-Path $RootPath $ScopePath
    $files = Get-ChildItem -LiteralPath $fullScope -Recurse -File | Where-Object {
        Test-SourceExtension -Path $_.FullName -AllowedExtensions $AllowedExtensions
    }

    return $files | Sort-Object FullName
}

function Get-GameArea {
    param(
        [string] $RepoPath,
        [string] $ScopePath
    )

    $normalizedScope = $ScopePath.Replace('\', '/').TrimEnd('/')
    $relative = $RepoPath

    if ($relative.StartsWith($normalizedScope + '/', [System.StringComparison]::OrdinalIgnoreCase)) {
        $relative = $relative.Substring($normalizedScope.Length + 1)
    }

    $firstSlash = $relative.IndexOf('/')
    if ($firstSlash -lt 0) {
        return '(root)'
    }

    return $relative.Substring(0, $firstSlash)
}

function Get-FileMetric {
    param(
        [System.IO.FileInfo] $File,
        [string] $RootPath,
        [string] $ScopePath,
        [string] $MarkerPattern
    )

    $lineCount = 0
    $debtMarkers = 0
    $tabLines = @()

    foreach ($line in [System.IO.File]::ReadLines($File.FullName)) {
        ++$lineCount

        if ($line.Contains("`t")) {
            $tabLines += $lineCount
        }

        if ($line -match $MarkerPattern) {
            ++$debtMarkers
        }
    }

    $repoPath = Convert-ToRepoPath -Path $File.FullName -RootPath $RootPath

    return New-Object PSObject -Property @{
        Path = $repoPath
        Area = Get-GameArea -RepoPath $repoPath -ScopePath $ScopePath
        Lines = $lineCount
        Bytes = $File.Length
        DebtMarkers = $debtMarkers
        TabLines = $tabLines
    }
}

function Format-TableRow {
    param([object[]] $Values)

    return '| ' + (($Values | ForEach-Object { [string] $_ }) -join ' | ') + ' |'
}

function Write-MarkdownTable {
    param(
        [string[]] $Headers,
        [object[]] $Rows
    )

    Write-Output (Format-TableRow -Values $Headers)
    Write-Output (Format-TableRow -Values ($Headers | ForEach-Object { '---' }))

    foreach ($row in $Rows) {
        Write-Output (Format-TableRow -Values $row)
    }
}

if (-not $Root) {
    if ($PSScriptRoot) {
        $Root = Join-Path $PSScriptRoot '..\..'
    } else {
        $Root = (Get-Location).Path
    }
}

$rootPath = Resolve-FullPath -Path $Root
$normalizedScope = $Scope.Replace('\', '/').TrimStart('/').TrimEnd('/')
$files = @(Get-GameFiles -RootPath $rootPath -ScopePath $normalizedScope -AllowedExtensions $Extensions -BaseRef $ChangedSince)
$metrics = @()

foreach ($file in $files) {
    $metrics += Get-FileMetric -File $file -RootPath $rootPath -ScopePath $normalizedScope -MarkerPattern $DebtPattern
}

if ($CheckNoTabs) {
    $violations = @($metrics | Where-Object { $_.TabLines.Count -gt 0 })

    if ($violations.Count -eq 0) {
        Write-Output "No tab characters found in $($metrics.Count) checked game source files."
        exit 0
    }

    Write-Output "Tab characters found in game source files:"
    foreach ($violation in $violations) {
        Write-Output ("{0}: {1}" -f $violation.Path, ($violation.TabLines -join ', '))
    }

    exit 1
}

$branch = (& git -C $rootPath rev-parse --abbrev-ref HEAD).Trim()
$commit = (& git -C $rootPath rev-parse --short HEAD).Trim()
$totalLines = ($metrics | Measure-Object -Property Lines -Sum).Sum
$totalBytes = ($metrics | Measure-Object -Property Bytes -Sum).Sum
$totalDebtMarkers = ($metrics | Measure-Object -Property DebtMarkers -Sum).Sum
$totalTabFiles = @($metrics | Where-Object { $_.TabLines.Count -gt 0 }).Count
$totalTabLines = ($metrics | ForEach-Object { $_.TabLines.Count } | Measure-Object -Sum).Sum

if ($null -eq $totalLines) { $totalLines = 0 }
if ($null -eq $totalBytes) { $totalBytes = 0 }
if ($null -eq $totalDebtMarkers) { $totalDebtMarkers = 0 }
if ($null -eq $totalTabLines) { $totalTabLines = 0 }

Write-Output "# Game Metrics"
Write-Output ''
Write-Output "- Source branch scanned: ``$branch``"
Write-Output "- Source commit scanned: ``$commit``"
Write-Output "- Scope: ``$normalizedScope``"
Write-Output "- File types counted: ``$($Extensions -join ', ')``"
Write-Output "- Files: ``$($metrics.Count)``"
Write-Output "- Lines: ``$('{0:N0}' -f $totalLines)``"
Write-Output "- Approximate source size: ``$('{0:N2}' -f ($totalBytes / 1MB)) MB``"
Write-Output "- Debt marker lines: ``$('{0:N0}' -f $totalDebtMarkers)``"
Write-Output "- Files with tabs: ``$totalTabFiles``"
Write-Output "- Tab-containing lines: ``$totalTabLines``"
Write-Output ''

$areaRows = @()
$areaGroups = $metrics | Group-Object Area | Sort-Object {
    ($_.Group | Measure-Object -Property Lines -Sum).Sum
} -Descending

foreach ($group in $areaGroups) {
    $groupLines = ($group.Group | Measure-Object -Property Lines -Sum).Sum
    $groupDebt = ($group.Group | Measure-Object -Property DebtMarkers -Sum).Sum
    $areaRows += ,@($group.Name, $group.Count, ('{0:N0}' -f $groupLines), ('{0:N0}' -f $groupDebt))
}

Write-Output "## Area Summary"
Write-Output ''
Write-MarkdownTable -Headers @('Area', 'Files', 'Lines', 'Debt Marker Lines') -Rows $areaRows
Write-Output ''

$largestRows = @()
$largestFiles = $metrics | Sort-Object Lines -Descending | Select-Object -First $Top

foreach ($fileMetric in $largestFiles) {
    $largestRows += ,@($fileMetric.Path, ('{0:N0}' -f $fileMetric.Lines))
}

Write-Output "## Largest Files"
Write-Output ''
Write-MarkdownTable -Headers @('File', 'Lines') -Rows $largestRows

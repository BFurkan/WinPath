param(
    [Parameter(Mandatory = $false)]
    [string]$Path,

    [int]$Limit = 400,

    [ValidateSet("HTML", "CSV", "Both", "None")]
    [string]$ExportFormat = "HTML",

    [switch]$IncludeDirectories,

    [switch]$IncludeJunctions,

    [switch]$IncludeHidden,

    [switch]$IncludeSystem,

    [int]$Top = 10,

    [string]$ReportDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Convert-ToExtendedPath {
    param([Parameter(Mandatory = $true)][string]$InputPath)
    if ($InputPath.StartsWith('\\\\?\\')) { return $InputPath }
    if ($InputPath.StartsWith('\\\\')) { return "\\\\?\\UNC\\" + $InputPath.Substring(2) }
    return "\\\\?\\" + $InputPath
}

function Convert-FromExtendedPath {
    param([Parameter(Mandatory = $true)][string]$InputPath)
    if ($InputPath.StartsWith('\\\\?\\UNC\\')) { return "\\" + $InputPath.Substring(7) }
    if ($InputPath.StartsWith('\\\\?\\')) { return $InputPath.Substring(4) }
    return $InputPath
}

function HtmlEncode {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    $encoded = $Text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' -replace "'",'&#39;'
    return $encoded
}

function Test-IsDirectory {
    param([System.IO.FileAttributes]$Attributes)
    return (($Attributes -band [System.IO.FileAttributes]::Directory) -ne 0)
}

function Test-IsReparsePoint {
    param([System.IO.FileAttributes]$Attributes)
    return (($Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Test-IsHidden {
    param([System.IO.FileAttributes]$Attributes)
    return (($Attributes -band [System.IO.FileAttributes]::Hidden) -ne 0)
}

function Test-IsSystem {
    param([System.IO.FileAttributes]$Attributes)
    return (($Attributes -band [System.IO.FileAttributes]::System) -ne 0)
}

function Add-ToTopList {
    param(
        [Parameter(Mandatory = $true)][System.Collections.Generic.List[object]]$TopList,
        [Parameter(Mandatory = $true)][pscustomobject]$Item,
        [int]$Max = 10
    )
    $TopList.Add($Item) | Out-Null
    # Keep sorted by Length desc and trim to Max
    $sortedLocal = $TopList | Sort-Object -Property Length -Descending
    $TopList.Clear()
    foreach ($i in ($sortedLocal | Select-Object -First $Max)) { $TopList.Add($i) | Out-Null }
}

function New-ReportDirectory {
    param([string]$BaseDir)
    $timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
    $dir = Join-Path -Path $BaseDir -ChildPath ("Reports_" + $timestamp)
    New-Item -Path $dir -ItemType Directory -Force | Out-Null
    return $dir
}

function Get-EnumeratorEntries {
    param([Parameter(Mandatory = $true)][string]$ExtendedDir)
    try {
        return [System.IO.Directory]::GetFileSystemEntries($ExtendedDir)
    } catch {
        # Fallback: try without extended prefix
        $normal = Convert-FromExtendedPath -InputPath $ExtendedDir
        return [System.IO.Directory]::GetFileSystemEntries($normal)
    }
}

function Get-AttributesSafe {
    param([Parameter(Mandatory = $true)][string]$AnyPath)
    $p = Convert-ToExtendedPath -InputPath $AnyPath
    try { return [System.IO.File]::GetAttributes($p) } catch {
        try { return (Get-Item -LiteralPath $AnyPath -Force -ErrorAction Stop).Attributes } catch {
            try { return (Get-Item -LiteralPath (Convert-FromExtendedPath -InputPath $AnyPath) -Force -ErrorAction Stop).Attributes } catch { throw }
        }
    }
}

function Get-EntriesPS {
    param([Parameter(Mandatory = $true)][string]$ExtendedDir)
    $dirNormal = Convert-FromExtendedPath -InputPath $ExtendedDir
    try { return Get-ChildItem -LiteralPath $dirNormal -Force -ErrorAction Stop } catch {
        try { return Get-ChildItem -LiteralPath $ExtendedDir -Force -ErrorAction Stop } catch { throw }
    }
}

function Write-HtmlReport {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IEnumerable]$Items,
        [Parameter(Mandatory = $true)][string]$OutFile
    )
    $rows = foreach ($r in $Items) { "<tr><td>" + (HtmlEncode $r.Type) + "</td><td>" + (HtmlEncode ($r.Length.ToString())) + "</td><td>" + (HtmlEncode $r.Path) + "</td></tr>" }
    $html = @(
        '<!DOCTYPE html>'
        '<html lang="en">'
        '<head>'
        '  <meta charset="utf-8" />'
        '  <meta name="viewport" content="width=device-width, initial-scale=1" />'
        '  <title>Long Paths Report</title>'
        '  <style>'
        '    body{font-family:Segoe UI,Arial,sans-serif;margin:20px;color:#111}'
        '    h1{font-size:20px;margin:0 0 10px 0}'
        '    .meta{color:#555;margin-bottom:12px}'
        '    table{border-collapse:collapse;width:100%}'
        '    th,td{border:1px solid #ddd;padding:8px;vertical-align:top}'
        '    th{background:#f3f4f6;text-align:left}'
        '    tr:nth-child(even){background:#fafafa}'
        '    .len-warn{color:#b45309;font-weight:600}'
        '  </style>'
        '</head>'
        '<body>'
        '  <h1>Long Paths Report</h1>'
        ('  <div class="meta">Generated: ' + ((Get-Date).ToString('u')) + '</div>')
        '  <table>'
        '    <thead><tr><th>Type</th><th>Length</th><th>Path</th></tr></thead>'
        '    <tbody>'
        ($rows -join [Environment]::NewLine)
        '    </tbody>'
        '  </table>'
        '</body>'
        '</html>'
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath $OutFile -Value $html -Encoding UTF8
}

# Resolve input path (interactive if none provided)
if ([string]::IsNullOrWhiteSpace($Path)) {
    $selected = $null
    try {
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = 'Select a folder to scan for long paths'
        $dlg.ShowNewFolderButton = $false
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selected = $dlg.SelectedPath
        }
    } catch {
        # Fallback to console prompt
    }
    if ([string]::IsNullOrWhiteSpace($selected)) {
        $selected = Read-Host 'Enter the folder path to scan'
    }
    if ([string]::IsNullOrWhiteSpace($selected)) {
        Write-Host 'No folder selected. Exiting.' -ForegroundColor Yellow
        exit 1
    }
    $Path = $selected
}

# Prompt for limit if not explicitly provided
if (-not $PSBoundParameters.ContainsKey('Limit')) {
    $hint = 'Enter path length limit (120=test, 260=OneDrive, 400=Teams) [default 400]'
    $inp = Read-Host $hint
    if ([string]::IsNullOrWhiteSpace($inp)) {
        $Limit = 400
    } elseif ($inp -match '^[0-9]+$') {
        $Limit = [int]$inp
    } else {
        Write-Host 'Invalid limit. Using 400.' -ForegroundColor Yellow
        $Limit = 400
    }
}

$resolvedPath = $null
try {
    $resolvedPath = (Resolve-Path -LiteralPath $Path).ProviderPath
} catch {
    # If Resolve-Path fails, assume provided path is intended
    $resolvedPath = $Path
}

# Prepare reporting
if ([string]::IsNullOrWhiteSpace($ReportDir)) {
    $base = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $ReportDir = New-ReportDirectory -BaseDir $base
} else {
    if (-not (Test-Path -LiteralPath $ReportDir)) { New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null }
}

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$results = New-Object System.Collections.Generic.List[object]
$topList = New-Object System.Collections.Generic.List[object]
$totalFiles = 0
$totalDirs = 0
$accessErrors = 0

$rootExtended = Convert-ToExtendedPath -InputPath $resolvedPath

# Use a stack for iterative DFS (avoids deep recursion)
$stack = New-Object System.Collections.Stack
if (-not [System.IO.Directory]::Exists($rootExtended)) {
    # Fallback to normal path if extended check fails
    if ([System.IO.Directory]::Exists($resolvedPath)) {
        $stack.Push($resolvedPath)
    } else {
        Write-Host ("Path not found or not accessible: {0}" -f $resolvedPath) -ForegroundColor Yellow
        exit 1
    }
} else {
    $stack.Push($rootExtended)
}

while ($stack.Count -gt 0) {
    $currentDir = [string]$stack.Pop()
    try {
        foreach ($entry in (Get-EntriesPS -ExtendedDir $currentDir)) {
            try {
                $attr = $entry.Attributes

                if ((-not $IncludeJunctions) -and (Test-IsReparsePoint -Attributes $attr)) { continue }
                if ((-not $IncludeHidden) -and (Test-IsHidden -Attributes $attr)) { continue }
                if ((-not $IncludeSystem) -and (Test-IsSystem -Attributes $attr)) { continue }

                $isDir = $entry.PSIsContainer
                $displayPath = $entry.FullName
                $length = $displayPath.Length

                if ($isDir) {
                    $totalDirs++
                    if ($IncludeDirectories -and ($length -gt $Limit)) { $results.Add([PSCustomObject]@{ Type = 'Directory'; Length = $length; Path = $displayPath }) | Out-Null }
                    Add-ToTopList -TopList $topList -Item ([PSCustomObject]@{ Type = 'Directory'; Length = $length; Path = $displayPath }) -Max $Top
                    # push directory for traversal
                    $stack.Push((Convert-ToExtendedPath -InputPath $displayPath))
                } else {
                    $totalFiles++
                    if ($length -gt $Limit) { $results.Add([PSCustomObject]@{ Type = 'File'; Length = $length; Path = $displayPath }) | Out-Null }
                    Add-ToTopList -TopList $topList -Item ([PSCustomObject]@{ Type = 'File'; Length = $length; Path = $displayPath }) -Max $Top
                }
            } catch {
                $accessErrors++
                continue
            }
        }
    } catch {
        $accessErrors++
        continue
    }
}

$stopwatch.Stop()

# Sort results by Length desc and normalize to array
$sortedTmp = $results | Sort-Object -Property Length -Descending
if ($null -eq $sortedTmp) { $sorted = @() } else { $sorted = @($sortedTmp) }
$sortedCount = ($sorted | Measure-Object).Count

# Choose report items: over-limit if any, else top-N longest overall
$reportItemsTmp = if ($sortedCount -gt 0) { $sorted } else { $topList | Sort-Object -Property Length -Descending }
if ($null -eq $reportItemsTmp) { $reportItems = @() } else { $reportItems = @($reportItemsTmp) }
$reportCount = ($reportItems | Measure-Object).Count

# Console summary
Write-Host "Scan complete in $([math]::Round($stopwatch.Elapsed.TotalSeconds,2))s" -ForegroundColor Cyan
Write-Host ("  Directories scanned : {0}" -f $totalDirs)
Write-Host ("  Files scanned       : {0}" -f $totalFiles)
Write-Host ("  Access errors       : {0}" -f $accessErrors)
Write-Host ("  Items over limit    : {0}" -f ($sortedCount)) -ForegroundColor Yellow
if ($Top -gt 0 -and $reportCount -gt 0) {
    if ($sortedCount -eq 0) { Write-Host "\nNo items exceeded the limit; showing top longest instead:" -ForegroundColor DarkYellow }
    Write-Host ("Top {0} longest:" -f [Math]::Min($Top, $reportCount)) -ForegroundColor Green
    $reportItems | Select-Object -First $Top | ForEach-Object {
        Write-Host ("[{0}] {1}" -f $_.Length, $_.Path)
    }
}

# Exports
$csvPath = Join-Path -Path $ReportDir -ChildPath 'LongPathsReport.csv'
$htmlPath = Join-Path -Path $ReportDir -ChildPath 'LongPathsReport.html'

switch ($ExportFormat) {
    'CSV' {
        if ($reportCount -gt 0) {
            $reportItems | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
        } else {
            "Type,Length,Path" | Out-File -LiteralPath $csvPath -Encoding UTF8 -Force
        }
        Write-Host ("CSV report: {0}" -f $csvPath) -ForegroundColor Cyan
    }
    'HTML' {
        Write-HtmlReport -Items $reportItems -OutFile $htmlPath
        Write-Host ("HTML report: {0}" -f $htmlPath) -ForegroundColor Cyan
        try { Start-Process -FilePath $htmlPath | Out-Null } catch { }
    }
    'Both' {
        if ($reportCount -gt 0) {
            $reportItems | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
        } else {
            "Type,Length,Path" | Out-File -LiteralPath $csvPath -Encoding UTF8 -Force
        }
        Write-HtmlReport -Items $reportItems -OutFile $htmlPath
        Write-Host ("CSV report:  {0}" -f $csvPath) -ForegroundColor Cyan
        Write-Host ("HTML report: {0}" -f $htmlPath) -ForegroundColor Cyan
        try { Start-Process -FilePath $htmlPath | Out-Null } catch { }
    }
    Default { }
}

exit 0



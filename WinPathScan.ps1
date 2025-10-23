<#
.SYNOPSIS
Advanced tool for analyzing and reporting long paths in Windows file systems.

.DESCRIPTION
Provides comprehensive analysis of long file paths with configurable limits, multiple report formats,
and advanced filtering options. Includes path remediation suggestions and error handling.

.PARAMETER Path
The directory path to analyze for long path names.

.PARAMETER Limit
The character limit to consider a path name "long". Default is 400.

.PARAMETER ExportFormat
The format for the report output. Accepts 'HTML', 'CSV', or 'Both'. Default is 'HTML'.

.PARAMETER IncludePermissions
Switch to include NTFS permissions in the analysis.

.EXAMPLE
Get-LongPathAnalysis -Path "C:\Users" -Limit 260 -ExportFormat "Both" -IncludePermissions
#>

# Required modules
#Requires -Module PSWriteHTML
#Requires -RunAsAdministrator

function Get-LongPathAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 400,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('HTML', 'CSV', 'Both')]
        [string]$ExportFormat = 'HTML',
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludePermissions
    )

    begin {
        # Validate path and create output directory
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputDir = Join-Path $PSScriptRoot "Reports_$timestamp"
        
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir | Out-Null
        }

        # Initialize counters
        $script:stats = @{
            TotalItems = 0
            LongPaths = 0
            Errors = 0
            StartTime = Get-Date
        }
    }

    process {
        try {
            Write-Host "Scanning path: $Path" -ForegroundColor Cyan
            
            # Get items with error handling
            $items = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue -ErrorVariable getErrors | 
                    Where-Object { $_.FullName.Length -gt $Limit }

            # Process errors
            $accessErrors = $getErrors | Where-Object { $_.CategoryInfo.Reason -eq "UnauthorizedAccessException" }
            
            if ($null -eq $items) {
                Write-Host "No items found exceeding path length of $Limit characters." -ForegroundColor Yellow
                return
            }

            # Generate detailed results
            $results = $items | ForEach-Object {
                $itemInfo = [ordered]@{
                    Type = if ($_.PSIsContainer) { 'Directory' } else { 'File' }
                    Path = $_.FullName
                    Length = $_.FullName.Length
                    Created = $_.CreationTime
                    LastModified = $_.LastWriteTime
                    PathSegments = ($_.FullName -split '\\').Count
                    Suggestion = Get-PathSuggestion -Path $_.FullName -Limit $Limit
                }

                if ($IncludePermissions) {
                    $acl = Get-Acl $_.FullName -ErrorAction SilentlyContinue
                    $itemInfo['Owner'] = $acl.Owner
                    $itemInfo['AccessRules'] = ($acl.Access | Select-Object -First 3 | ForEach-Object { 
                        "$($_.IdentityReference) : $($_.FileSystemRights)"
                    }) -join '; '
                }

                [PSCustomObject]$itemInfo
            }

            # Generate reports only if we have results
            if ($results) {
                if ($ExportFormat -in 'HTML', 'Both') {
                    Export-HTMLReport -Results $results -OutputDir $outputDir -Stats $script:stats -AccessErrors $accessErrors
                }
                
                if ($ExportFormat -in 'CSV', 'Both') {
                    Export-CSVReport -Results $results -OutputDir $outputDir
                }

                # Update statistics
                $script:stats.TotalItems = $items.Count
                $script:stats.LongPaths = $results.Count
                $script:stats.Errors = $accessErrors.Count
            }
        }
        catch {
            Write-Error "Error processing path: $_"
        }
    }

    end {
        # Display summary
        $duration = (Get-Date) - $script:stats.StartTime
        Write-Host "`nAnalysis Complete:" -ForegroundColor Green
        Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))"
        Write-Host "Total items processed: $($script:stats.TotalItems)"
        Write-Host "Items exceeding limit: $($script:stats.LongPaths)"
        Write-Host "Access errors encountered: $($script:stats.Errors)"
        
        if ($script:stats.TotalItems -gt 0) {
            Write-Host "Reports saved to: $outputDir"
        }
    }
}

function Get-PathSuggestion {
    param (
        [string]$Path,
        [int]$Limit
    )
    
    $exceededBy = $Path.Length - $Limit
    $segments = $Path -split '\\'
    
    if ($segments.Count -gt 5) {
        return "Consider restructuring: Path has $($segments.Count) segments. Exceeds limit by $exceededBy characters."
    }
    elseif ($segments | Where-Object { $_.Length -gt 50 }) {
        return "Shorten folder/file names: Found names exceeding 50 characters."
    }
    else {
        return "Move closer to root or rename with shorter names. Exceeds limit by $exceededBy characters."
    }
}

function Export-HTMLReport {
    param ($Results, $OutputDir, $Stats, $AccessErrors)
    
    $htmlPath = Join-Path $OutputDir "LongPathsReport.html"
    
    New-HTML -Title "Long Paths Analysis Report" -FilePath $htmlPath -ShowHTML {
        New-HTMLSection -HeaderText "Analysis Summary" {
            New-HTMLPanel {
                New-HTMLText -Text @"
                <h3>Statistics</h3>
                <ul>
                    <li>Total Items: $($Stats.TotalItems)</li>
                    <li>Items Exceeding Limit: $($Stats.LongPaths)</li>
                    <li>Access Errors: $($Stats.Errors)</li>
                    <li>Analysis Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</li>
                </ul>
"@
            }
        }
        
        New-HTMLSection -HeaderText "Long Paths Details" {
            New-HTMLTable -DataTable $Results -ScrollX -Buttons @('copyHtml5', 'excelHtml5', 'csvHtml5') {
                New-TableCondition -Name 'Length' -ComparisonType 'number' -Operator 'gt' -Value $Limit -BackgroundColor '#ffcdd2' -Color '#000000'
            }
        }
        
        if ($AccessErrors) {
            New-HTMLSection -HeaderText "Access Errors" {
                New-HTMLTable -DataTable $AccessErrors -ScrollX
            }
        }
    }
}

function Export-CSVReport {
    param ($Results, $OutputDir)
    
    if ($null -ne $Results) {
        $csvPath = Join-Path $OutputDir "LongPathsReport.csv"
        $Results | Export-Csv -Path $csvPath -NoTypeInformation
        Write-Host "CSV report saved to: $csvPath" -ForegroundColor Green
    }
}

# Example usage:
Get-LongPathAnalysis -Path "C:\users" -Limit 260 -ExportFormat "Both" -IncludePermissions
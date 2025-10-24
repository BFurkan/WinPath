# Comprehensive PSWriteHTML Uninstaller
# This script will find and remove all versions of PSWriteHTML from all scopes.

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   PSWriteHTML Module Uninstaller" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Get-Elevated {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "This script needs to run as Administrator to remove modules from all locations."
        Write-Host "Requesting elevation..." -ForegroundColor Yellow
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit", "-File", "'$($MyInvocation.MyCommand.Path)'"
        exit
    }
}

Get-Elevated

# Step 1: Find all installed versions of PSWriteHTML across all scopes
Write-Host "Step 1: Searching for all installed PSWriteHTML modules..." -ForegroundColor Yellow
$allModules = @()
try {
    $allModules = Get-InstalledModule -Name PSWriteHTML -AllVersions -ErrorAction SilentlyContinue
} catch {}

if ($allModules.Count -eq 0) {
    # Fallback to Get-Module if Get-InstalledModule fails
    try {
        $allModules = Get-Module -ListAvailable PSWriteHTML -AllVersions
    } catch {}
}

if ($allModules) {
    Write-Host "Found the following PSWriteHTML installations:" -ForegroundColor Green
    foreach ($module in $allModules) {
        Write-Host "  - Version $($module.Version) at: $($module.InstalledLocation)" -ForegroundColor White
    }
} else {
    Write-Host "✅ No PSWriteHTML modules found. Nothing to uninstall." -ForegroundColor Green
    pause
    exit 0
}

Write-Host ""

# Step 2: Uninstall all found versions
Write-Host "Step 2: Uninstalling all found versions..." -ForegroundColor Yellow
foreach ($module in $allModules) {
    $moduleName = $module.Name
    $moduleVersion = $module.Version
    $modulePath = $module.InstalledLocation

    try {
        Write-Host "  Uninstalling '$($moduleName)' version $($moduleVersion)..." -ForegroundColor Cyan
        Uninstall-Module -Name $moduleName -RequiredVersion $moduleVersion -AllVersions -Force -ErrorAction Stop
        Write-Host "  ✅ Uninstalled successfully via PowerShell." -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ Uninstall-Module failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "  Attempting to manually delete the module folder..." -ForegroundColor Yellow
        try {
            Remove-Item -Path $modulePath -Recurse -Force -ErrorAction Stop
            Write-Host "  ✅ Manually deleted folder: $($modulePath)" -ForegroundColor Green
        } catch {
            Write-Host "  ❌ Failed to manually delete folder: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""

# Step 3: Final verification
Write-Host "Step 3: Verifying uninstallation..." -ForegroundColor Yellow
$remainingModules = Get-Module -ListAvailable PSWriteHTML
if ($remainingModules) {
    Write-Host "❌ FAILED: PSWriteHTML is still detected at:" -ForegroundColor Red
    $remainingModules | ForEach-Object { Write-Host "  - $($_.ModuleBase)" -ForegroundColor Red }
    Write-Host "You may need to manually delete the folder(s) listed above." -ForegroundColor Yellow
} else {
    Write-Host "✅ SUCCESS: All versions of PSWriteHTML have been uninstalled." -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Uninstallation Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now run WinPathScan-Setup.bat to perform a clean installation." -ForegroundColor Green
Write-Host ""
pause

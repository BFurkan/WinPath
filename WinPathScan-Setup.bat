@echo off
REM Change to the directory where this batch file is located
cd /d "%~dp0"
setlocal enabledelayedexpansion
title WinPathScan v2.0 - One-Time Setup
color 0A

cls
echo.
echo ========================================
echo    WinPathScan v2.0 - One-Time Setup
echo    OneDrive/SharePoint Compatibility Tool
echo ========================================
echo.

echo This will install the required PowerShell modules for WinPathScan.
echo This only needs to be done once per computer.
echo.
echo Required components:
echo - NuGet Package Provider
echo - PSWriteHTML module (for generating reports)
echo.
echo NOTE: Requires internet connection.
echo.

REM Check if PowerShell script exists
if not exist "%~dp0WinPathScan.ps1" (
    echo [ERROR] WinPathScan.ps1 not found!
    echo Make sure you're running this from the WinPathScan folder.
    echo Current directory: %CD%
    echo.
    pause
    exit /b 1
)

echo [OK] WinPathScan.ps1 found
echo.

REM Check if setup has already been completed
echo Checking installation status...
set nugetInstalled=false
set pswritehtmlInstalled=false
set setupComplete=false
set currentVersion=2.0.0

REM Check if NuGet Package Provider is installed
echo Checking NuGet Package Provider...
powershell -Command "try { $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue; if ($nuget) { Write-Host 'NuGet Provider found' } else { Write-Host 'NuGet Provider not found' } } catch { Write-Host 'NuGet Provider not found' }" 2>nul | findstr "NuGet Provider found" >nul
if %errorLevel% == 0 (
    echo [OK] NuGet Package Provider already installed
    set nugetInstalled=true
) else (
    echo [INFO] NuGet Package Provider needs installation
    set nugetInstalled=false
)

REM Check if PSWriteHTML module is already installed
echo Checking PSWriteHTML module...
powershell -Command "try { $module = Get-Module -ListAvailable PSWriteHTML | Select-Object -First 1; if ($module) { Write-Host 'PSWriteHTML version:' $module.Version } else { Write-Host 'PSWriteHTML not installed' } } catch { Write-Host 'PSWriteHTML not installed' }" 2>nul | findstr "PSWriteHTML version:" >nul
if %errorLevel% == 0 (
    echo [OK] PSWriteHTML module already installed
    set pswritehtmlInstalled=true
) else (
    echo [INFO] PSWriteHTML module needs installation
    set pswritehtmlInstalled=false
)

REM Determine if setup is complete
if "!nugetInstalled!"=="true" if "!pswritehtmlInstalled!"=="true" (
    set setupComplete=true
) else (
    set setupComplete=false
)

REM Check if setup marker file exists
if exist "%~dp0.winpathscan-setup-v!currentVersion!.marker" (
    if "!setupComplete!"=="true" (
        echo.
        echo ========================================
        echo    Setup Already Complete!
        echo ========================================
        echo.
        echo WinPathScan v!currentVersion! setup has already been completed.
        echo.
        echo Installation Status:
        echo [OK] NuGet Package Provider - Installed
        echo [OK] PSWriteHTML module - Installed
        echo.
        echo All required components are ready to use.
        echo.
        echo You can now use:
        echo - WinPathScan-Quick.bat     (Quick Documents scan)
        echo - WinPathScan-Advanced.bat  (Full menu with options)
        echo.
        set /p force_reinstall="Force reinstall anyway? (Y/N): "
        if /i not "!force_reinstall!"=="Y" if /i not "!force_reinstall!"=="YES" (
            echo.
            echo Setup skipped. Your installation is already complete.
            echo.
            pause
            exit /b 0
        )
        echo.
        echo Proceeding with forced reinstallation...
    )
)

REM Check admin status
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrator privileges
    set isAdmin=true
) else (
    echo [INFO] Running as standard user
    echo Some operations may require admin rights
    set isAdmin=false
)

echo.
echo Installation Summary:
if "!nugetInstalled!"=="false" (
    echo - NuGet Package Provider: Will be installed
) else (
    echo - NuGet Package Provider: Already installed ^(skip^)
)
if "!pswritehtmlInstalled!"=="false" (
    echo - PSWriteHTML module: Will be installed
) else (
    echo - PSWriteHTML module: Already installed ^(skip^)
)
echo.
set /p continue="Continue with installation? (Y/N): "
if /i not "!continue!"=="Y" if /i not "!continue!"=="YES" (
    echo Setup cancelled.
    pause
    exit /b 0
)

echo.
echo ========================================
echo    Installing Components
echo ========================================
echo.

REM Install NuGet Package Provider if needed
if "!nugetInstalled!"=="false" (
    echo Step 1: Installing NuGet Package Provider...
    echo This may take a moment...
    powershell -Command "try { Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser -ErrorAction Stop; Write-Host '[SUCCESS] NuGet Package Provider installed' } catch { Write-Host '[ERROR] NuGet installation failed:' $_.Exception.Message }"
) else (
    echo Step 1: NuGet Package Provider already installed - skipping
)

echo.
REM Install PSWriteHTML module if needed
if "!pswritehtmlInstalled!"=="false" (
    echo Step 2: Installing PSWriteHTML module...
    echo This may take a moment...
    powershell -Command "try { Install-Module -Name PSWriteHTML -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop; Write-Host '[SUCCESS] PSWriteHTML module installed' } catch { Write-Host '[ERROR] PSWriteHTML installation failed:' $_.Exception.Message }"
) else (
    echo Step 2: PSWriteHTML module already installed - skipping
)

if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Module installation failed!
    echo.
    echo Troubleshooting options:
    echo 1. Run this batch file as Administrator (Right-click - Run as Administrator)
    echo 2. Check your internet connection
    echo 3. Try manual installation:
    echo    powershell -Command "Install-Module -Name PSWriteHTML -Force -AllowClobber -Scope CurrentUser"
    echo.
    pause
    exit /b 1
)

echo.
echo Step 3: Verifying installation...
powershell -Command "Get-Module -ListAvailable PSWriteHTML" >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Module verification failed!
    echo Please try running as Administrator or contact support.
    echo.
    pause
    exit /b 1
) else (
    echo [SUCCESS] PSWriteHTML module installed and verified!
)

REM Clean up old version marker files
del "%~dp0.winpathscan-setup-v*.marker" 2>nul

REM Create setup completion marker file
echo !currentVersion! > "%~dp0.winpathscan-setup-v!currentVersion!.marker"
echo Setup completion marker created for version !currentVersion!

echo.
echo ========================================
echo    Installation Complete!
echo ========================================
echo.
echo All required components have been installed successfully!
echo.
echo You can now use the scanning tools:
echo.
echo RECOMMENDED FOR MOST USERS:
echo - WinPathScan-Quick.bat     (Quick Documents scan)
echo - WinPathScan-Advanced.bat  (Full menu with options)
echo.
echo This setup only needs to be done once per computer.
echo.
echo Would you like to run a quick test scan now?
set /p test_scan="Run test scan of Documents folder? (Y/N): "
if /i "%test_scan%"=="Y" (
    echo.
    echo Running test scan...
    echo.
    echo ========================================
    echo    Test Scan - Documents Folder
    echo ========================================
    echo.
    echo Scanning: %USERPROFILE%\Documents
    echo This may take 2-5 minutes...
    echo.
    powershell -ExecutionPolicy Bypass -File "%~dp0WinPathScan.ps1" -Path "%USERPROFILE%\Documents" -Limit 260 -ExportFormat "Both"
    
    if %errorLevel% neq 0 (
        echo.
        echo [WARNING] Test scan encountered issues, but setup is complete.
        echo You can still use the other batch files.
    ) else (
        echo.
        echo [SUCCESS] Test scan completed! Check the Reports folder.
    )
)

echo.
echo Setup complete! Thank you for using WinPathScan.
echo.
pause
exit /b 0
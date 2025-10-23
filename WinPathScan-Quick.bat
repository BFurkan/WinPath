@echo off
REM Change to the directory where this batch file is located
cd /d "%~dp0"
setlocal enabledelayedexpansion
title WinPathScan v2.0 - Quick Documents Scan
color 0A

cls
echo.
echo ========================================
echo    WinPathScan v2.0 - Quick Documents Scan
echo    OneDrive/SharePoint Compatibility Tool
echo ========================================
echo.

echo This will quickly scan your Documents folder for long file paths
echo that may cause issues with OneDrive, SharePoint, or Teams sync.
echo.
echo What this scan does:
echo - Scans: %USERPROFILE%\Documents
echo - Finds: Paths longer than 260 characters
echo - Creates: HTML and CSV reports
echo - Time: Usually 2-5 minutes
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

REM Quick check for PSWriteHTML module
echo Checking for required modules...
powershell -Command "try { $module = Get-Module -ListAvailable PSWriteHTML | Select-Object -First 1; if ($module) { Write-Host 'PSWriteHTML found' } else { Write-Host 'PSWriteHTML not found' } } catch { Write-Host 'PSWriteHTML not found' }" 2>nul | findstr "PSWriteHTML found" >nul
if %errorLevel% == 0 (
    echo [OK] PSWriteHTML module found
) else (
    echo [WARNING] PSWriteHTML module not found - scan may fail
    echo Run WinPathScan-Setup.bat first to install required modules
    echo.
    set /p continue_anyway="Continue anyway? (Y/N): "
    if /i not "!continue_anyway!"=="Y" if /i not "!continue_anyway!"=="YES" (
        echo Please run WinPathScan-Setup.bat first.
        pause
        exit /b 1
    )
    echo [WARNING] Continuing without modules - scan may fail
)
echo.

REM Check if Documents folder exists
if not exist "%USERPROFILE%\Documents" (
    echo [ERROR] Documents folder not found at: %USERPROFILE%\Documents
    echo.
    pause
    exit /b 1
)

echo [OK] Documents folder found
echo.

set /p continue="Start quick scan now? (Y/N): "
if /i not "%continue%"=="Y" if /i not "%continue%"=="YES" (
    echo Scan cancelled.
    pause
    exit /b 0
)

echo.
echo ========================================
echo    Starting WinPathScan
echo ========================================
echo.
echo Scanning: %USERPROFILE%\Documents
echo Limit: 260 characters (OneDrive/SharePoint compatible)
echo Format: HTML + CSV reports
echo.
echo This may take several minutes depending on folder size...
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0WinPathScan.ps1" -Path "%USERPROFILE%\Documents" -Limit 260 -ExportFormat "Both"

if %errorLevel% neq 0 (
    echo.
    echo [ERROR] Scan failed with error code: %errorLevel%
    echo.
    echo Common solutions:
    echo 1. Run as Administrator for system folders
    echo 2. Check that the path exists and is accessible
    echo 3. Ensure PSWriteHTML module is installed (run WinPathScan-Setup.bat)
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo    Quick Scan Complete!
echo ========================================
echo.
echo What to do next:
echo 1. Review the HTML report that opened in your browser
echo 2. Look for files/folders with red or yellow highlighting
echo 3. Follow the suggestions to rename or move problematic items
echo 4. Re-run this scan after making changes to verify fixes
echo.
echo For more scanning options, use WinPathScan-Advanced.bat
echo.
pause
exit /b 0

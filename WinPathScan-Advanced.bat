@echo off
REM Change to the directory where this batch file is located
cd /d "%~dp0"
setlocal enabledelayedexpansion
title WinPathScan v2.0 - Advanced Scanning Options
color 0A

cls
echo.
echo ========================================
echo    WinPathScan v2.0 - Advanced Scanning Options
echo    OneDrive/SharePoint Compatibility Tool
echo ========================================
echo.

echo This tool scans folders for files with paths that are too long
echo for OneDrive, SharePoint, and Teams synchronization.
echo.
echo Path length limit: 260 characters (Microsoft cloud services)
echo Report formats: HTML (interactive) + CSV (Excel-compatible)
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

REM Check admin status
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrator privileges
    set isAdmin=true
) else (
    echo [INFO] Running as standard user
    echo Some folders may not be accessible
    set isAdmin=false
)

REM Check for required modules
echo Checking for required PowerShell modules...
set nugetInstalled=false
set pswritehtmlInstalled=false

REM Check NuGet Package Provider
powershell -Command "try { $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue; if ($nuget) { Write-Host 'NuGet Provider found' } else { Write-Host 'NuGet Provider not found' } } catch { Write-Host 'NuGet Provider not found' }" 2>nul | findstr "NuGet Provider found" >nul
if %errorLevel% == 0 (
    echo [OK] NuGet Package Provider found
    set nugetInstalled=true
) else (
    echo [WARNING] NuGet Package Provider not found
    set nugetInstalled=false
)

REM Check PSWriteHTML module
powershell -Command "try { $module = Get-Module -ListAvailable PSWriteHTML | Select-Object -First 1; if ($module) { Write-Host 'PSWriteHTML found' } else { Write-Host 'PSWriteHTML not found' } } catch { Write-Host 'PSWriteHTML not found' }" 2>nul | findstr "PSWriteHTML found" >nul
if %errorLevel% == 0 (
    echo [OK] PSWriteHTML module found
    set pswritehtmlInstalled=true
) else (
    echo [WARNING] PSWriteHTML module not found
    set pswritehtmlInstalled=false
)

REM Check if both components are available
if "!nugetInstalled!"=="true" if "!pswritehtmlInstalled!"=="true" (
    echo [SUCCESS] All required components are installed and ready
    goto main_menu
)

echo.
echo [WARNING] Some required components are missing!
echo.
echo Missing components:
if "!nugetInstalled!"=="false" echo - NuGet Package Provider
if "!pswritehtmlInstalled!"=="false" echo - PSWriteHTML module
echo.
echo Options:
echo 1. Run WinPathScan-Setup.bat to install missing components
echo 2. Continue anyway (scan may fail)
echo 3. Exit and install manually
echo.
set /p module_choice="Enter your choice (1-3): "
if "!module_choice!"=="1" (
    echo.
    echo Please run WinPathScan-Setup.bat first, then come back here.
    pause
    exit /b 1
) else if "!module_choice!"=="2" (
    echo.
    echo [WARNING] Continuing with missing components - scan may fail
    echo.
) else (
    echo Exiting for manual installation.
    echo Run: Install-Module -Name PSWriteHTML -Force -AllowClobber -Scope CurrentUser
    pause
    exit /b 1
)

:main_menu
echo.
echo ========================================
echo    Choose Scan Target
echo ========================================
echo.
echo COMMON LOCATIONS:
echo 1. Documents folder     (Recommended - 2-5 minutes)
echo 2. Desktop folder       (Quick - 1-3 minutes)
echo 3. Downloads folder     (Quick - 1-3 minutes)
echo.
echo ADVANCED OPTIONS:
echo 4. All Users folder     (Comprehensive - 10-30 minutes)
echo 5. Custom folder path   (Specify your own location)
echo.
echo OTHER:
echo 6. View previous reports
echo 7. Help ^& Troubleshooting
echo 8. Exit
echo.

set /p choice="Enter your choice (1-8): "

if "%choice%"=="1" goto scan_documents
if "%choice%"=="2" goto scan_desktop
if "%choice%"=="3" goto scan_downloads
if "%choice%"=="4" goto scan_users
if "%choice%"=="5" goto scan_custom
if "%choice%"=="6" goto view_reports
if "%choice%"=="7" goto help_info
if "%choice%"=="8" goto exit_program
goto invalid_choice

:scan_documents
echo.
echo ========================================
echo    Scanning Documents Folder
echo ========================================
if not exist "%USERPROFILE%\Documents" (
    echo [ERROR] Documents folder not found at: %USERPROFILE%\Documents
    pause
    goto main_menu
)
echo Scanning: %USERPROFILE%\Documents
echo This may take 2-5 minutes...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0WinPathScan.ps1" -Path "%USERPROFILE%\Documents" -Limit 260 -ExportFormat "Both"
goto scan_complete

:scan_desktop
echo.
echo ========================================
echo    Scanning Desktop Folder
echo ========================================
if not exist "%USERPROFILE%\Desktop" (
    echo [ERROR] Desktop folder not found at: %USERPROFILE%\Desktop
    pause
    goto main_menu
)
echo Scanning: %USERPROFILE%\Desktop
echo This may take 1-3 minutes...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0WinPathScan.ps1" -Path "%USERPROFILE%\Desktop" -Limit 260 -ExportFormat "Both"
goto scan_complete

:scan_downloads
echo.
echo ========================================
echo    Scanning Downloads Folder
echo ========================================
if not exist "%USERPROFILE%\Downloads" (
    echo [ERROR] Downloads folder not found at: %USERPROFILE%\Downloads
    pause
    goto main_menu
)
echo Scanning: %USERPROFILE%\Downloads
echo This may take 1-3 minutes...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0WinPathScan.ps1" -Path "%USERPROFILE%\Downloads" -Limit 260 -ExportFormat "Both"
goto scan_complete

:scan_users
echo.
echo ========================================
echo    Scanning All Users Folder
echo ========================================
echo.
echo WARNING: This will scan ALL user profiles on this computer.
echo This may take 10-30 minutes depending on the amount of data.
echo.
if "%isAdmin%"=="false" (
    echo [WARNING] Not running as Administrator
    echo You may encounter access denied errors for some user folders.
    echo For best results, run as Administrator.
    echo.
)
echo.
set /p confirm="Are you sure you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" if /i not "%confirm%"=="YES" goto main_menu

if not exist "C:\Users" (
    echo [ERROR] Users folder not found at: C:\Users
    pause
    goto main_menu
)
echo Scanning: C:\Users
echo This may take 10-30 minutes...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0WinPathScan.ps1" -Path "C:\Users" -Limit 260 -ExportFormat "Both"
goto scan_complete

:scan_custom
echo.
echo ========================================
echo    Custom Folder Scan
echo ========================================
echo.
echo Enter the full path to the folder you want to scan.
echo.
echo Examples:
echo - C:\MyProject
echo - D:\Work\Documents  
echo - \\server\share\folder
echo - %USERPROFILE%\OneDrive
echo.
set /p custom_path="Enter folder path: "

if "%custom_path%"=="" (
    echo No path entered. Returning to main menu.
    pause
    goto main_menu
)

if not exist "%custom_path%" (
    echo.
    echo [ERROR] Path does not exist: %custom_path%
    echo.
    echo Please check the path and try again.
    pause
    goto main_menu
)

echo.
echo Scanning: %custom_path%
echo This may take several minutes...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0WinPathScan.ps1" -Path "%custom_path%" -Limit 260 -ExportFormat "Both"
goto scan_complete

:view_reports
echo.
echo ========================================
echo    Previous Reports
echo ========================================
echo.
echo Looking for report folders...
dir /AD /B Reports_* 2>nul
if %errorLevel% neq 0 (
    echo No previous reports found.
    echo Reports are saved in folders named "Reports_YYYYMMDD_HHMMSS"
) else (
    echo.
    echo Found the above report folders.
    echo Each contains:
    echo - LongPathsReport.html (interactive web report)
    echo - LongPathsReport.csv (Excel-compatible data)
)
echo.
echo Press any key to return to main menu...
pause >nul
goto main_menu

:help_info
echo.
echo ========================================
echo    Help ^& Troubleshooting
echo ========================================
echo.
echo COMMON ISSUES:
echo.
echo Problem: "Required PowerShell module not found"
echo Solution: Run WinPathScan-Setup.bat first
echo.
echo Problem: "Access denied" errors during scan
echo Solution: Run as Administrator (Right-click - Run as Administrator)
echo.
echo Problem: Scan takes too long
echo Solution: Start with smaller folders (Documents, Desktop)
echo.
echo Problem: No HTML report opens
echo Solution: Check Reports folder, open LongPathsReport.html manually
echo.
echo WHAT THE REPORTS SHOW:
echo - Files/folders with paths longer than 260 characters
echo - Color coding: Red (critical), Yellow (warning), Green (OK)
echo - Suggestions for shortening paths
echo - Export options for further analysis
echo.
echo For more help, see README.md file
echo.
echo Press any key to return to main menu...
pause >nul
goto main_menu

:invalid_choice
echo.
echo [ERROR] Invalid choice. Please enter a number between 1 and 8.
echo.
pause
goto main_menu

:scan_complete
echo.
echo ========================================
echo    Scan Complete!
echo ========================================
echo.
echo What was found:
echo - HTML Report: Interactive web page with detailed results
echo - CSV Report: Data file for Excel or other analysis tools
echo.
echo The HTML report should have opened automatically in your browser.
echo If not, look for a folder named "Reports_" with today's date.
echo.
echo What to do next:
echo - Review the HTML report to see which files have long paths
echo - Follow the suggestions to rename or move files/folders
echo - Re-run this scan after making changes to verify fixes
echo.
echo Options:
echo 1. Run another scan
echo 2. Exit
echo.
set /p next_action="Enter your choice (1-2): "
if "%next_action%"=="1" goto main_menu
if "%next_action%"=="2" goto exit_program
echo Invalid choice. Returning to main menu...
goto main_menu

:exit_program
echo.
echo Thank you for using WinPathScan v2.0!
echo.
echo Remember:
echo - Keep file paths under 260 characters for cloud sync
echo - Use shorter folder names when possible
echo - Move deeply nested files to higher levels
echo.
pause
exit /b 0
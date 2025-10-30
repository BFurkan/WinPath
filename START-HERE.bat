@echo off
setlocal ENABLEEXTENSIONS
cd /d "%~dp0"

REM Launch PowerShell with STA for folder browser dialog support
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0WinPathScan.ps1" -ExportFormat Both

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo The scan did not complete successfully. Exit code: %ERRORLEVEL%
  echo You can try running as Administrator.
  pause
)

endlocal


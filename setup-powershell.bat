@echo off
REM Launcher for PowerShell setup script
REM No WSL or Git Bash required - Pure Windows PowerShell

echo Docker Development Container Setup (PowerShell)
echo ================================================
echo.

REM Check PowerShell version
powershell -Command "if ($PSVersionTable.PSVersion.Major -lt 5) { exit 1 }" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell 5.1 or higher is required
    echo Please update PowerShell: https://aka.ms/powershell
    echo.
    pause
    exit /b 1
)

REM Run PowerShell script with ExecutionPolicy bypass
echo Starting PowerShell setup script...
echo.
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"

echo.
pause

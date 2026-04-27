@echo off
REM Windows wrapper for setup.sh
REM This requires Git Bash or WSL to be installed

echo Docker Development Container Setup
echo ====================================
echo.

REM Check if running in Git Bash
if exist "%PROGRAMFILES%\Git\bin\bash.exe" (
    echo Running setup script via Git Bash...
    "%PROGRAMFILES%\Git\bin\bash.exe" --login -i "%~dp0setup.sh"
    goto :end
)

REM Check if WSL is available
where wsl >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Running setup script via WSL...
    wsl bash "%~dp0setup.sh"
    goto :end
)

echo ERROR: Neither Git Bash nor WSL found!
echo.
echo Please install one of the following:
echo   - Git for Windows (includes Git Bash): https://git-scm.com/download/win
echo   - WSL (Windows Subsystem for Linux): wsl --install
echo.
pause
exit /b 1

:end
pause

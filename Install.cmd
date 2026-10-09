@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-Preview.ps1"
if errorlevel 1 (
    echo.
    echo Setup failed. Keep the error above and ask for help.
) else (
    echo.
    echo Setup completed. Select a file in Explorer and press Space.
)
pause

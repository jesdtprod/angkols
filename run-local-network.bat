@echo off
setlocal
cd /d "%~dp0"

set "PORT=%~1"
if "%PORT%"=="" set "PORT=8080"

where python >nul 2>nul
if errorlevel 1 (
  echo Python is required to run this app locally.
  echo Install Python, then run this file again.
  pause
  exit /b 1
)

set "LAN_IP="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$ips = Get-NetIPAddress -AddressFamily IPv4; foreach ($ip in $ips) { if ($ip.IPAddress -notlike '127.*' -and $ip.PrefixOrigin -ne 'WellKnown') { $ip.IPAddress; break } }"`) do set "LAN_IP=%%I"

echo.
echo Angkol's Grill ^& Restobar POS is running.
echo Local:   http://localhost:%PORT%/
if defined LAN_IP (
  echo Network: http://%LAN_IP%:%PORT%/
) else (
  echo Network: Use this computer's IPv4 address with port %PORT%.
)
echo.
echo Press Ctrl+C to stop the server.
echo.

start "" "http://localhost:%PORT%/"
python -m http.server %PORT% --bind 0.0.0.0

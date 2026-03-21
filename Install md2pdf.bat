@echo off
setlocal enabledelayedexpansion

:: md2pdf — Double-click installer for Windows
:: Downloads Node.js automatically if not already installed.

echo =============================================
echo   md2pdf Installer
echo =============================================
echo.

cd /d "%~dp0"
set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ── Check for existing Node.js ─────────────────────────────────────────
set "NODE_CMD="

:: Check local .node\ first
if exist "%SCRIPT_DIR%\.node\node.exe" (
    set "NODE_CMD=%SCRIPT_DIR%\.node\node.exe"
    goto :found_node
)

:: Then check system Node.js (must be v18+)
where node >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=1 delims=v." %%a in ('node --version 2^>nul') do (
        set "NODE_MAJOR=%%a"
    )
    :: node --version returns "v22.14.0", tokens after removing v gives 22
    for /f "tokens=1 delims=." %%a in ('node --version 2^>nul ^| findstr /r "v[0-9]"') do (
        set "VER_STR=%%a"
        set "NODE_MAJOR=!VER_STR:v=!"
    )
    if defined NODE_MAJOR (
        if !NODE_MAJOR! geq 18 (
            for /f "delims=" %%p in ('where node') do set "NODE_CMD=%%p"
            goto :found_node
        )
    )
)

:: ── Download Node.js if needed ─────────────────────────────────────────
echo Node.js not found. Downloading...
echo.

set "NODE_ARCH=x64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "NODE_ARCH=arm64"

set "NODE_VERSION=v22.14.0"
set "NODE_ZIP=node-%NODE_VERSION%-win-%NODE_ARCH%.zip"
set "NODE_URL=https://nodejs.org/dist/%NODE_VERSION%/%NODE_ZIP%"

echo Downloading Node.js %NODE_VERSION% for %NODE_ARCH%...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%TEMP%\%NODE_ZIP%' -UseBasicParsing }"
if %errorlevel% neq 0 (
    echo.
    echo Error: Failed to download Node.js. Check your internet connection.
    pause
    exit /b 1
)

echo Extracting...
powershell -Command "& { Expand-Archive -Path '%TEMP%\%NODE_ZIP%' -DestinationPath '%TEMP%\node-extract' -Force }"
if %errorlevel% neq 0 (
    echo Error: Failed to extract Node.js.
    pause
    exit /b 1
)

:: Move extracted contents to .node\ (strip top-level directory)
if exist "%SCRIPT_DIR%\.node" rmdir /s /q "%SCRIPT_DIR%\.node"
mkdir "%SCRIPT_DIR%\.node"
for /d %%d in ("%TEMP%\node-extract\node-*") do (
    xcopy "%%d\*" "%SCRIPT_DIR%\.node\" /s /e /q /y >nul
)
rmdir /s /q "%TEMP%\node-extract" 2>nul
del /f /q "%TEMP%\%NODE_ZIP%" 2>nul

set "NODE_CMD=%SCRIPT_DIR%\.node\node.exe"
echo Node.js installed locally.
echo.

:found_node
:: Display Node.js version
for /f "delims=" %%v in ('"%NODE_CMD%" --version') do echo Using Node.js %%v
echo.

:: ── Determine npm path ─────────────────────────────────────────────────
set "NODE_DIR="
for %%i in ("%NODE_CMD%") do set "NODE_DIR=%%~dpi"
if "%NODE_DIR:~-1%"=="\" set "NODE_DIR=%NODE_DIR:~0,-1%"

if exist "%NODE_DIR%\npm.cmd" (
    set "NPM_CMD=%NODE_DIR%\npm.cmd"
) else (
    set "NPM_CMD=npm"
)

:: ── Install dependencies ───────────────────────────────────────────────
echo Installing dependencies (this may take a few minutes)...
call "%NPM_CMD%" install --silent
if %errorlevel% neq 0 (
    echo.
    echo Error: Failed to install dependencies.
    pause
    exit /b 1
)
echo Dependencies installed.
echo.

:: ── Output directory ───────────────────────────────────────────────────
set "OUTPUT_DIR=%USERPROFILE%\Documents\MDpdf"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
echo Output directory: %OUTPUT_DIR%

:: ── Write config ───────────────────────────────────────────────────────
(
echo {
echo   "outputDir": "%OUTPUT_DIR:\=/%",
echo   "nodePath": "%NODE_CMD:\=/%"
echo }
) > "%SCRIPT_DIR%\config.json"
echo Config saved to config.json

:: ── Generate wrapper scripts ───────────────────────────────────────────
echo.
echo Generating wrapper scripts...

(
echo @echo off
echo "%NODE_CMD%" "%SCRIPT_DIR%\alumni-chapel.mjs" %%*
) > "%SCRIPT_DIR%\alumni-chapel.bat"

(
echo @echo off
echo "%NODE_CMD%" "%SCRIPT_DIR%\minion-noir.mjs" %%*
) > "%SCRIPT_DIR%\minion-noir.bat"

(
echo @echo off
echo "%NODE_CMD%" "%SCRIPT_DIR%\sage.mjs" %%*
) > "%SCRIPT_DIR%\sage.bat"

(
echo @echo off
echo "%NODE_CMD%" "%SCRIPT_DIR%\oxford.mjs" %%*
) > "%SCRIPT_DIR%\oxford.bat"

(
echo @echo off
echo "%NODE_CMD%" "%SCRIPT_DIR%\noir-plus.mjs" %%*
) > "%SCRIPT_DIR%\noir-plus.bat"

echo Wrapper scripts generated: alumni-chapel.bat, minion-noir.bat, sage.bat, oxford.bat, noir-plus.bat

:: ── Font check ─────────────────────────────────────────────────────────
echo.
echo Checking fonts...
set "MISSING_FONTS=0"

set "FOUND_MINION=0"
if exist "%WINDIR%\Fonts\MinionPro*" set "FOUND_MINION=1"
if exist "%LOCALAPPDATA%\Microsoft\Windows\Fonts\MinionPro*" set "FOUND_MINION=1"
dir /b "%WINDIR%\Fonts\*Minion*" >nul 2>&1 && set "FOUND_MINION=1"
dir /b "%LOCALAPPDATA%\Microsoft\Windows\Fonts\*Minion*" >nul 2>&1 && set "FOUND_MINION=1"
if "!FOUND_MINION!"=="0" (
    echo   Missing: Minion Pro [required]
    set "MISSING_FONTS=1"
)

set "FOUND_LATO=0"
dir /b "%WINDIR%\Fonts\Lato*" >nul 2>&1 && set "FOUND_LATO=1"
dir /b "%LOCALAPPDATA%\Microsoft\Windows\Fonts\Lato*" >nul 2>&1 && set "FOUND_LATO=1"
if "!FOUND_LATO!"=="0" (
    echo   Missing: Lato [required for Alumni Chapel]
    set "MISSING_FONTS=1"
)

set "FOUND_STIX=0"
dir /b "%WINDIR%\Fonts\STIX*" >nul 2>&1 && set "FOUND_STIX=1"
dir /b "%LOCALAPPDATA%\Microsoft\Windows\Fonts\STIX*" >nul 2>&1 && set "FOUND_STIX=1"
if "!FOUND_STIX!"=="0" (
    echo   Missing: STIX [required for Alumni Chapel]
    set "MISSING_FONTS=1"
)

set "FOUND_NEWYORK=0"
dir /b "%WINDIR%\Fonts\NewYork*" >nul 2>&1 && set "FOUND_NEWYORK=1"
dir /b "%LOCALAPPDATA%\Microsoft\Windows\Fonts\NewYork*" >nul 2>&1 && set "FOUND_NEWYORK=1"
dir /b "%WINDIR%\Fonts\*New York*" >nul 2>&1 && set "FOUND_NEWYORK=1"
dir /b "%LOCALAPPDATA%\Microsoft\Windows\Fonts\*New York*" >nul 2>&1 && set "FOUND_NEWYORK=1"
if "!FOUND_NEWYORK!"=="0" (
    echo   Missing: New York [required for Oxford]
    set "MISSING_FONTS=1"
)

if "!MISSING_FONTS!"=="1" (
    echo.
    echo Download and install the missing fonts:
    echo   Minion Pro: https://font.download/font/minion-pro
    echo   Lato:       https://fonts.google.com/specimen/Lato
    echo   STIX:       https://github.com/stipub/stixfonts
    echo   New York:   https://developer.apple.com/fonts/
    echo.
    echo Double-click each downloaded font file and click "Install."
) else (
    echo   All required fonts are installed.
)

:: ── Summary ────────────────────────────────────────────────────────────
echo.
echo =============================================
echo   Setup complete!
echo =============================================
echo.
echo   Usage:   alumni-chapel.bat report.md
echo            minion-noir.bat report.md
echo            sage.bat report.md
echo            oxford.bat report.md
echo            noir-plus.bat report.md
echo.
echo   Output:  %OUTPUT_DIR%
echo.
echo   You can also drag a .md file onto any of the .bat files.
echo.
pause

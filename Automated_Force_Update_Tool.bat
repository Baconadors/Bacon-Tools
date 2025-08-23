:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)

@echo off
setlocal EnableDelayedExpansion

:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges. Please run as administrator.
    pause
    exit /b
)

:: ========================== DEFINE PATHS ===========================
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "datetime=%%I"
echo [INFO] Generated datetime: %datetime%

set "simbaPath=%LOCALAPPDATA%\Simba"
set "runeLitePath=%LOCALAPPDATA%\RuneLite"
set "runeLiteProfilePath=%USERPROFILE%\.runelite"
set "tempBackupPath=%LOCALAPPDATA%\SimbaBackupTMP"
set "forceUpdatePath=%LOCALAPPDATA%\SimbaForceUpdate"
set "backupRootPath=%LOCALAPPDATA%\SimbaBackups"
set "backupSessionPath=%backupRootPath%\Backup_%datetime%"
set "backupZipPath=%backupRootPath%\Simba_RuneLite_Backup_%datetime%.7z"

set "simbaSetupFile=simba-setup_%datetime%.exe"
set "runeLiteSetupFile=RuneLiteSetup_%datetime%.exe"
set "simbaSetupPath=%forceUpdatePath%\%simbaSetupFile%"
set "runeLiteSetupPath=%forceUpdatePath%\%runeLiteSetupFile%"

set "simba32ExePath=%simbaPath%\Simba32.exe"
set "simba64ExePath=%simbaPath%\Simba64.exe"
set "runeLiteUninstallerPath=%runeLitePath%\unins000.exe"

set "simba64ShortcutPath=%USERPROFILE%\Desktop\Simba64.lnk"
set "simba32ShortcutPath=%USERPROFILE%\Desktop\Simba32.lnk"

set "portable7zDir=%LOCALAPPDATA%\SimbaTools"
set "portable7zPath=%portable7zDir%\7zr.exe"

:: Ensure SimbaTools directory exists
if not exist "%portable7zDir%" mkdir "%portable7zDir%"

:: Download portable 7-Zip if not already present
if not exist "%portable7zPath%" (
    echo [INFO] 7-Zip not installed. Downloading portable 7-Zip...
    powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://www.7-zip.org/a/7zr.exe' -OutFile '%portable7zPath%'"
)

:: ======================== CREATE REQUIRED FOLDERS ========================
echo [INFO] Ensuring backup and update folders exist...
if not exist "%forceUpdatePath%" mkdir "%forceUpdatePath%"
if not exist "%backupSessionPath%" mkdir "%backupSessionPath%"

:: ========================= DELETE REG KEY =========================
echo [INFO] Cleaning up old Simba registry key...
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" >nul 2>&1 && (
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" /f
)

:: ========================= KILL PROCESSES =========================
echo [INFO] Killing all Simba, Jagex Launcher, and RuneLite processes...
taskkill /f /im Simba32.exe >nul 2>&1
taskkill /f /im Simba64.exe >nul 2>&1
taskkill /f /im RuneLite.exe >nul 2>&1
taskkill /f /im JagexLauncher.exe >nul 2>&1

:: ================== ADD EXCLUSIONS TO DEFENDER ==================
echo [INFO] Adding Windows Defender exclusions...
powershell -Command "Add-MpPreference -ExclusionPath '%simbaPath%'"
powershell -Command "Add-MpPreference -ExclusionPath '%tempBackupPath%'"
powershell -Command "Add-MpPreference -ExclusionPath '%forceUpdatePath%'"
echo [INFO] Exclusions added.

:: ======================= COPY TO TEMP FOLDER FOR BACKUP =========================
echo [INFO] Preparing backup folders.
xcopy /s /e /y "%simbaPath%" "%backupSessionPath%\Simba\" >nul 2>&1
xcopy /s /e /y "%runeLitePath%" "%backupSessionPath%\RuneLite\" >nul 2>&1
xcopy /s /e /y "%runeLiteProfilePath%" "%backupSessionPath%\.runelite\" >nul 2>&1

:: ============= COMPRESS BACKUP (7z with fastest method) =====================
echo [INFO] Compressing backup with 7-Zip. Please wait...
if exist "%portable7zPath%" (
    "%portable7zPath%" a -t7z -mx1 "%backupZipPath%" "%backupSessionPath%\*" >nul
    if exist "%backupZipPath%" (
        echo [SUCCESS] Backup created: %backupZipPath%
        rmdir /s /q "%backupSessionPath%"
    ) else (
        echo [ERROR] Compression failed.
    )
) else (
    echo [ERROR] No compression tool available. Skipping compression.
)

:: ================== DELETE SIMBA FOLDER ==================
echo [INFO] Cleaning up old Simba folder...
if exist "%simbaPath%" rmdir /s /q "%simbaPath%"

:: ================== RUN RUNELITE UNINSTALLER ==============
echo [INFO] Running RuneLite uninstaller if available...
if exist "%runeLiteUninstallerPath%" start "" "%runeLiteUninstallerPath%" /Silent

:: ================== DOWNLOAD INSTALLERS ===================
echo [INFO] Downloading Simba installer...
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/torwent/wasp-setup/releases/latest/download/simba-setup.exe' -OutFile '%simbaSetupPath%'"
if exist "%simbaSetupPath%" start "" "%simbaSetupPath%" /S

echo [INFO] Downloading RuneLite installer...
powershell -Command "$ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/runelite/launcher/releases/latest/download/RuneLiteSetup.exe' -OutFile '%runeLiteSetupPath%'"
if exist "%runeLiteSetupPath%" start "" "%runeLiteSetupPath%" /Silent

:: =================== INSTALLATION COMPLETION NOTICE ===================
echo.
echo ======================================================
echo MAKE SURE THE SIMBA AND RUNELITE INSTALLATIONS ARE
echo COMPLETE BEFORE CONTINUING. PRESS ANY KEY TO CONFIRM.
echo ======================================================
echo.
pause >nul

:: ================== PROMPT FOR RESTORE =====================
echo [INFO] Preparing restore step...
if not exist "%tempBackupPath%" mkdir "%tempBackupPath%"

set /p "userInput=Do you want to restore Account Credentials and Script Settings from Simba backup? (y/n): "
if /i "%userInput%"=="y" (
    if exist "%backupZipPath%" (
        echo [INFO] Extracting backup for restore. Please wait...
        "%portable7zPath%" x -y -o"%tempBackupPath%" "%backupZipPath%" >nul
        move /y "%tempBackupPath%\Simba\credentials.simba" "%simbaPath%\" >nul 2>&1
        move /y "%tempBackupPath%\Simba\Configs" "%simbaPath%\Configs" >nul 2>&1
        echo [SUCCESS] Restored Simba credentials and settings.
    ) else (
        echo [WARNING] Backup archive not found. Skipping restore.
    )
) else (
    echo [INFO] Skipping restore.
)

:: ================== SHORTCUT AND CLEANUP =====================
echo [INFO] Creating shortcuts and cleaning up old files...
if not exist "%simba64ShortcutPath%" (
    powershell "$s = (New-Object -COM WScript.Shell).CreateShortcut('%simba64ShortcutPath%'); $s.TargetPath = '%simba64ExePath%'; $s.Save()"
)
if exist "%simba32ExePath%" del "%simba32ExePath%"
if exist "%simba32ShortcutPath%" del "%simba32ShortcutPath%"

if exist "%simbaSetupPath%" del "%simbaSetupPath%"
if exist "%runeLiteSetupPath%" del "%runeLiteSetupPath%"
if exist "%tempBackupPath%" rmdir /s /q "%tempBackupPath%"

:: Show backup file location
echo [INFO] All backups are stored in:
echo %backupZipPath%

echo [INFO] Script complete.
endlocal
pause

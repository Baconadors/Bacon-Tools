:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)

@echo off
setlocal EnableDelayedExpansion

:: ==================== DEBUG TOGGLES =====================
:: Toggle these for debugging individual updaters
set "debugUpdateBat=true"
set "debugUpdateWorlds=true"
set "debugUpdateProfile=true"
set "debugUpdateSettings=true"

:: Ensure force update folder exists before updaters
if not exist "%LOCALAPPDATA%\SimbaForceUpdate" mkdir "%LOCALAPPDATA%\SimbaForceUpdate"

:: ==================== AUTO-UPDATER (BATCH SCRIPT) =====================
if /I "%debugUpdateBat%"=="true" (
    set "latestScriptUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/Automated_Force_Update_Tool.bat"
    set "latestHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/Automated_Force_Update_Tool.sha256"

    set "thisScript=%~f0"
    set "tmpScript=%LOCALAPPDATA%\SimbaForceUpdate\Automated_Force_Update_Tool.bat"
    set "tmpHashFile=%LOCALAPPDATA%\SimbaForceUpdate\Automated_Force_Update_Tool.sha256"
    set "preLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaForceUpdate_PreLog_%RANDOM%.log"

    if not exist "%LOCALAPPDATA%\SimbaForceUpdate" (
        mkdir "%LOCALAPPDATA%\SimbaForceUpdate"
        if %errorlevel% neq 0 (
            call :PreLog "[ERROR] Could not create %LOCALAPPDATA%\SimbaForceUpdate"
            set "doBatUpdate=0"
            goto batUpdaterEnd
        )
    )

    :: Download expected hash first
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpHashFile%" "%latestHashUrl%" >> "%preLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %latestHashUrl%"
        set "doBatUpdate=0"
        goto batUpdaterEnd
    )

    call :PreLog "[INFO] Starting script auto-update check..."
    set "doBatUpdate=1"
) else (
    set "doBatUpdate=0"
)

if "%doBatUpdate%"=="1" goto runBatUpdater
goto batUpdaterEnd

:runBatUpdater
:: Read and normalize expected hash
set "expectedHash="
for /f %%I in ('type "%tmpHashFile%"') do set "expectedHash=%%I"
for /f %%U in ('echo %expectedHash% ^| powershell -NoProfile -Command "$input.ToUpper()"') do set "expectedHash=%%U"

:: Compute local hash
for /f "usebackq" %%I in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%thisScript%').Hash.ToUpper()"`) do set "localHash=%%I"

call :PreLog "[INFO] Local SHA256:    %localHash%"
call :PreLog "[INFO] Expected SHA256: %expectedHash%"

if /I "%localHash%"=="%expectedHash%" (
    call :PreLog "[INFO] Script is up-to-date."
) else (
    call :PreLog "[WARNING] Script is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpScript%" "%latestScriptUrl%" >> "%preLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %latestScriptUrl%"
    ) else if exist "%tmpScript%" (
        call :PreLog "[INFO] Script updated. Relaunching..."
        copy /y "%tmpScript%" "%thisScript%" >nul
        del "%tmpHashFile%" >nul 2>&1
        del "%tmpScript%" >nul 2>&1
        start "" "%thisScript%"
        exit /b
    ) else (
        call :PreLog "[ERROR] Failed to download latest script."
    )
)
del "%tmpHashFile%" >nul 2>&1
del "%tmpScript%" >nul 2>&1
goto batUpdaterEnd

:batUpdaterEnd

:: ==================== AUTO-UPDATER (WORLDS.TXT) =====================
set "worldsFile=%LOCALAPPDATA%\SimbaForceUpdate\worlds.txt"
set "worldsTmpFile=%LOCALAPPDATA%\SimbaForceUpdate\worlds_tmp.txt"
set "worldsHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/worlds.sha256"
set "worldsUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/worlds.txt"
set "tmpWorldsHashFile=%LOCALAPPDATA%\SimbaForceUpdate\worlds.sha256"
set "preWorldsLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaWorldsUpdate_PreLog_%RANDOM%.log"

if /I "%debugUpdateWorlds%"=="true" (
    call :PreLog "[INFO] Starting worlds.txt auto-update check..."

    if not exist "%LOCALAPPDATA%\SimbaForceUpdate" (
        mkdir "%LOCALAPPDATA%\SimbaForceUpdate"
        if %errorlevel% neq 0 (
            call :PreLog "[ERROR] Could not create %LOCALAPPDATA%\SimbaForceUpdate"
            set "doWorldsUpdate=0"
            goto WorldsUpdaterEnd
        )
    )

    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpWorldsHashFile%" "%worldsHashUrl%" >> "%preWorldsLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %worldsHashUrl%"
        set "doWorldsUpdate=0"
    ) else if exist "%tmpWorldsHashFile%" (
        set "doWorldsUpdate=1"
    ) else (
        set "doWorldsUpdate=0"
    )
) else (
    set "doWorldsUpdate=0"
)

if "%doWorldsUpdate%"=="1" goto WorldsRunUpdater
goto WorldsUpdaterEnd

:WorldsRunUpdater
set "expectedWorldsHash="
for /f %%I in ('type "%tmpWorldsHashFile%"') do set "expectedWorldsHash=%%I"
for /f %%U in ('echo %expectedWorldsHash% ^| powershell -NoProfile -Command "$input.ToUpper()"') do set "expectedWorldsHash=%%U"

if exist "%worldsFile%" (
    for /f "usebackq" %%I in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%worldsFile%').Hash.ToUpper()"`) do set "localWorldsHash=%%I"
) else (
    set "localWorldsHash=NONE"
)

call :PreLog "[INFO] Local worlds.txt hash:    %localWorldsHash%"
call :PreLog "[INFO] Expected worlds.txt hash: %expectedWorldsHash%"

if /I "%localWorldsHash%"=="%expectedWorldsHash%" (
    call :PreLog "[INFO] worlds.txt is up-to-date."
) else (
    call :PreLog "[WARNING] worlds.txt is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%worldsTmpFile%" "%worldsUrl%" >> "%preWorldsLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %worldsUrl%"
    ) else if exist "%worldsTmpFile%" (
        copy /y "%worldsTmpFile%" "%worldsFile%" >nul
        del "%worldsTmpFile%" >nul 2>&1
        call :PreLog "[SUCCESS] worlds.txt updated."
    ) else (
        call :PreLog "[ERROR] Failed to download latest worlds.txt"
    )
)

goto WorldsUpdaterEnd

:WorldsUpdaterEnd

:: ==================== AUTO-UPDATER (WASP-PROFILE.PROPERTIES) =====================
set "profileFile=%LOCALAPPDATA%\SimbaForceUpdate\wasp-profile.properties"
set "profileTmpFile=%LOCALAPPDATA%\SimbaForceUpdate\wasp-profile_tmp.properties"
set "profileHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/wasp-profile.sha256"
set "profileUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/wasp-profile.properties"
set "tmpProfileHashFile=%LOCALAPPDATA%\SimbaForceUpdate\wasp-profile.sha256"
set "preProfileLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaProfileUpdate_PreLog_%RANDOM%.log"

if /I "%debugUpdateProfile%"=="true" (
    call :PreLog "[INFO] Starting wasp-profile.properties auto-update check..."

    if not exist "%LOCALAPPDATA%\SimbaForceUpdate" (
        mkdir "%LOCALAPPDATA%\SimbaForceUpdate"
        if %errorlevel% neq 0 (
            call :PreLog "[ERROR] Could not create %LOCALAPPDATA%\SimbaForceUpdate"
            set "doProfileUpdate=0"
            goto ProfileUpdaterEnd
        )
    )

    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpProfileHashFile%" "%profileHashUrl%" >> "%preProfileLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %profileHashUrl%"
        set "doProfileUpdate=0"
    ) else if exist "%tmpProfileHashFile%" (
        set "doProfileUpdate=1"
    ) else (
        set "doProfileUpdate=0"
    )
) else (
    set "doProfileUpdate=0"
)

if "%doProfileUpdate%"=="1" goto ProfileRunUpdater
goto ProfileUpdaterEnd

:ProfileRunUpdater
set "expectedProfileHash="
for /f %%I in ('type "%tmpProfileHashFile%"') do set "expectedProfileHash=%%I"
for /f %%U in ('echo %expectedProfileHash% ^| powershell -NoProfile -Command "$input.ToUpper()"') do set "expectedProfileHash=%%U"

if exist "%profileFile%" (
    for /f "usebackq" %%I in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%profileFile%').Hash.ToUpper()"`) do set "localProfileHash=%%I"
) else (
    set "localProfileHash=NONE"
)

call :PreLog "[INFO] Local wasp-profile hash:    %localProfileHash%"
call :PreLog "[INFO] Expected wasp-profile hash: %expectedProfileHash%"

if /I "%localProfileHash%"=="%expectedProfileHash%" (
    call :PreLog "[INFO] wasp-profile.properties is up-to-date."
) else (
    call :PreLog "[WARNING] wasp-profile.properties is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%profileTmpFile%" "%profileUrl%" >> "%preProfileLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %profileUrl%"
    ) else if exist "%profileTmpFile%" (
        copy /y "%profileTmpFile%" "%profileFile%" >nul
        del "%profileTmpFile%" >nul 2>&1
        call :PreLog "[SUCCESS] wasp-profile.properties updated."
    ) else (
        call :PreLog "[ERROR] Failed to download latest wasp-profile.properties"
    )
)

goto ProfileUpdaterEnd

:ProfileUpdaterEnd

:: ==================== AUTO-UPDATER (SETTINGS.INI) =====================
set "settingsFile=%LOCALAPPDATA%\SimbaForceUpdate\settings.ini"
set "settingsTmpFile=%LOCALAPPDATA%\SimbaForceUpdate\settings_tmp.ini"
set "settingsHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/settings.sha256"
set "settingsUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/settings.ini"
set "tmpSettingsHashFile=%LOCALAPPDATA%\SimbaForceUpdate\settings.sha256"
set "preSettingsLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaSettingsUpdate_PreLog_%RANDOM%.log"

if /I "%debugUpdateSettings%"=="true" (
    call :PreLog "[INFO] Starting settings.ini auto-update check..."

    if not exist "%LOCALAPPDATA%\SimbaForceUpdate" (
        mkdir "%LOCALAPPDATA%\SimbaForceUpdate"
        if %errorlevel% neq 0 (
            call :PreLog "[ERROR] Could not create %LOCALAPPDATA%\SimbaForceUpdate"
            set "doSettingsUpdate=0"
            goto SettingsUpdaterEnd
        )
    )

    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpSettingsHashFile%" "%settingsHashUrl%" >> "%preSettingsLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %settingsHashUrl%"
        set "doSettingsUpdate=0"
    ) else if exist "%tmpSettingsHashFile%" (
        set "doSettingsUpdate=1"
    ) else (
        set "doSettingsUpdate=0"
    )
) else (
    set "doSettingsUpdate=0"
)

if "%doSettingsUpdate%"=="1" goto SettingsRunUpdater
goto SettingsUpdaterEnd

:SettingsRunUpdater
set "expectedSettingsHash="
for /f %%I in ('type "%tmpSettingsHashFile%"') do set "expectedSettingsHash=%%I"
for /f %%U in ('echo %expectedSettingsHash% ^| powershell -NoProfile -Command "$input.ToUpper()"') do set "expectedSettingsHash=%%U"

if exist "%settingsFile%" (
    for /f "usebackq" %%I in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%settingsFile%').Hash.ToUpper()"`) do set "localSettingsHash=%%I"
) else (
    set "localSettingsHash=NONE"
)

call :PreLog "[INFO] Local settings.ini hash:    %localSettingsHash%"
call :PreLog "[INFO] Expected settings.ini hash: %expectedSettingsHash%"

if /I "%localSettingsHash%"=="%expectedSettingsHash%" (
    call :PreLog "[INFO] settings.ini is up-to-date."
) else (
    call :PreLog "[WARNING] settings.ini is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%settingsTmpFile%" "%settingsUrl%" >> "%preSettingsLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed (code %errorlevel%) when downloading %settingsUrl%"
    ) else if exist "%settingsTmpFile%" (
        copy /y "%settingsTmpFile%" "%settingsFile%" >nul
        del "%settingsTmpFile%" >nul 2>&1
        call :PreLog "[SUCCESS] settings.ini updated."
    ) else (
        call :PreLog "[ERROR] Failed to download latest settings.ini"
    )
)

goto SettingsUpdaterEnd

:SettingsUpdaterEnd

:: ==================== ADMIN PRIVILEGES CHECK =====================
call :CheckAdmin || exit /b

:: ==================== DEFINE PATHS =====================
call :DefinePaths

:: ==================== SETUP LOGGING =====================
call :InitLogging

:: ==================== ROTATE LOGS & BACKUPS =====================
call :RotateLogs
call :RotateBackups
call :RotateProfileBackups

:: ==================== SETUP REQUIREMENTS =====================
call :Setup7Zip
call :CreateFolders

:: ==================== CLEANUP OLD INSTALLATIONS =====================
call :CleanRegistry
call :KillProcesses
call :AddDefenderExclusions

:: ==================== BACKUP =====================
call :BackupData
call :CompressBackup

:: ==================== REMOVE OLD INSTALLS =====================
call :RemoveOldSimba
call :UninstallRuneLite

:: ==================== INSTALL NEW VERSIONS =====================
call :InstallSimba
call :ConfigureSimba
call :InstallRuneLite

:: ==================== RESTORE =====================
call :AutoRestore
call :CleanCredentialsWorlds

:: ==================== SHORTCUTS & CLEANUP =====================
call :CreateShortcuts
call :FinalCleanup

:: ==================== FINISH =====================
call :Log "[INFO] All backups are stored in: %backupZipPath%"
call :Log "[INFO] Script complete."

for /f "tokens=* usebackq" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'ddd, dd/MM/yyyy @ HH:mm:ss'"`) do set "rundate=%%a"
call :Log "[DONE] Run finished on %rundate%"
echo. >> "%logFile%"

endlocal
echo Press any key to finish and exit...
pause >nul
exit

:: ####################################################################
:: ########################## SUBROUTINES #############################
:: ####################################################################

:CheckAdmin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] This script requires administrative privileges. 
    echo         Right click file -> Run as administrator.
    pause
    exit /b 1
)
exit /b 0

:DefinePaths
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format ddMMyyyy_HHmmss" 2^>nul') do set "datetime=%%I"
if not defined datetime (
    set "datetime=%DATE:~7,2%%DATE:~4,2%%DATE:~10,4%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
    set "datetime=!datetime: =0!"
)

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

set "logFile=%backupRootPath%\SimbaUpdate_%datetime%.log"
set "runeLiteProfiles2=%USERPROFILE%\.runelite\profiles2"
set "profilesJson=%runeLiteProfiles2%\profiles.json"
set "waspProfileURL=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/wasp-profile.properties"
set "credentialsFile=%simbaPath%\credentials.simba"

:: Print start time
for /f "tokens=* usebackq" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'ddd, dd/MM/yyyy @ HH:mm:ss'"`) do set "rundate=%%a"
call :Log "[STRT] Run started on %rundate%"
echo. >> "%logFile%"
exit /b

:InitLogging
if not exist "%backupRootPath%" mkdir "%backupRootPath%"
echo ===================================================== >> "%logFile%"
echo  Simba + RuneLite Update Log - %datetime% >> "%logFile%"
echo ===================================================== >> "%logFile%"

:: Merge updater pre-log into main log (if it exists)
if exist "%preLog%" (
    echo === AUTO-UPDATER LOG START === >> "%logFile%"
    type "%preLog%" >> "%logFile%"
    echo === AUTO-UPDATER LOG END === >> "%logFile%"
    del "%preLog%" >nul 2>&1
)
exit /b

:Log
set "msg=%~1"
set "curtime=%time: =0%"
set "curtime=%curtime:~0,8%"

set "color=White"
echo %msg% | find "[INFO]"    >nul && set "color=White"
echo %msg% | find "[SUCCESS]" >nul && set "color=Green"
echo %msg% | find "[FAILED]"  >nul && set "color=Red"
echo %msg% | find "[ERROR]"   >nul && set "color=Red"
echo %msg% | find "[WARN]"    >nul && set "color=Cyan"
echo %msg% | find "[STRT]"    >nul && set "color=Cyan"
echo %msg% | find "[DONE]"    >nul && set "color=Cyan"

powershell -NoProfile -Command "Write-Host '[%curtime%] %msg%' -ForegroundColor %color%"

echo [%curtime%] %msg% >> "%logFile%"
exit /b

:PreLog
:: %~1 = log file path
:: %*  = all arguments
setlocal
set "logFile=%~1"
:: shift off the first arg (log file), leaving the full message
shift
set "msg=%*"
set "curtime=%time: =0%"
set "curtime=%curtime:~0,8%"

:: Pick color based on tags
set "color=White"
echo %msg% | find "[INFO]"    >nul && set "color=White"
echo %msg% | find "[SUCCESS]" >nul && set "color=Green"
echo %msg% | find "[FAILED]"  >nul && set "color=Red"
echo %msg% | find "[ERROR]"   >nul && set "color=Red"
echo %msg% | find "[WARN]"    >nul && set "color=Cyan"
echo %msg% | find "[STRT]"    >nul && set "color=Cyan"
echo %msg% | find "[DONE]"    >nul && set "color=Cyan"

:: Print to console
powershell -NoProfile -Command "Write-Host '[%curtime%] %msg%' -ForegroundColor %color%"

:: Append to chosen log file
if defined logFile echo [%curtime%] %msg% >> "%logFile%"

endlocal
exit /b

:RotateLogs
if not exist "%backupRootPath%" mkdir "%backupRootPath%"
for /f "skip=5 delims=" %%F in ('2^>nul dir "%backupRootPath%\SimbaUpdate_*.log" /b /o-d') do (
    del "%backupRootPath%\%%F"
    call :Log "[INFO] Deleted old log %%F"
)
exit /b

:RotateBackups
if not exist "%backupRootPath%" mkdir "%backupRootPath%"
for /f "skip=5 delims=" %%F in ('2^>nul dir "%backupRootPath%\Simba_RuneLite_Backup_*.7z" /b /o-d') do (
    del "%backupRootPath%\%%F"
    call :Log "[INFO] Deleted old backup %%F"
)
exit /b

:RotateProfileBackups
if not exist "%runeLiteProfiles2%" mkdir "%runeLiteProfiles2%"
for /f "skip=5 delims=" %%F in ('2^>nul dir "%runeLiteProfiles2%\profiles.json.bak_*" /b /o-d') do (
    del "%runeLiteProfiles2%\%%F"
    call :Log "[INFO] Deleted old profiles.json backup %%F"
)
exit /b

:Setup7Zip
if not exist "%portable7zDir%" mkdir "%portable7zDir%"
if not exist "%portable7zPath%" (
    call :Log "[INFO] 7-Zip not found. Downloading..."
    curl -s -L -o "%portable7zPath%" "https://www.7-zip.org/a/7zr.exe" >> "%logFile%" 2>&1
    if %errorlevel% neq 0 (
        call :Log "[FAILED] Could not download 7-Zip."
    )
)
exit /b

:CreateFolders
call :Log "[INFO] Ensuring backup and update folders exist..."
if not exist "%forceUpdatePath%" mkdir "%forceUpdatePath%"
if not exist "%backupSessionPath%" mkdir "%backupSessionPath%"
if not exist "%runeLiteProfiles2%" mkdir "%runeLiteProfiles2%"
exit /b

:CleanRegistry
call :Log "[INFO] Cleaning up old Simba registry key..."
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" >nul 2>&1 && (
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" /f >> "%logFile%" 2>&1
    if %errorlevel% neq 0 (
        call :Log "[FAILED] Could not delete Simba registry key."
    )
)
exit /b

:KillProcesses
call :Log "[INFO] Killing Simba, RuneLite, Jagex Launcher processes..."
for %%p in (Simba32.exe Simba64.exe RuneLite.exe JagexLauncher.exe) do (
    taskkill /f /im %%p >> "%logFile%" 2>&1
)
exit /b

:AddDefenderExclusions
call :Log "[INFO] Adding Defender exclusions..."

set "failFlag=0"

:: Simba exclusion
powershell -Command "Add-MpPreference -ExclusionPath '%simbaPath%'" >> "%logFile%" 2>&1
if %errorlevel% neq 0 (
    call :Log "[FAILED] Could not add Defender exclusion for Simba folder"
    set "failFlag=1"
)

:: TempBackup exclusion
powershell -Command "Add-MpPreference -ExclusionPath '%tempBackupPath%'" >> "%logFile%" 2>&1
if %errorlevel% neq 0 (
    call :Log "[FAILED] Could not add Defender exclusion for temp backup folder"
    set "failFlag=1"
)

:: ForceUpdate exclusion
powershell -Command "Add-MpPreference -ExclusionPath '%forceUpdatePath%'" >> "%logFile%" 2>&1
if %errorlevel% neq 0 (
    call :Log "[FAILED] Could not add Defender exclusion for force update folder"
    set "failFlag=1"
)

:: If all succeeded, show a single success message
if %failFlag%==0 (
    call :Log "[SUCCESS] Defender exclusions added successfully"
)

exit /b

:BackupData
call :Log "[INFO] Backing up existing data..."

if exist "%simbaPath%" (
    xcopy /s /e /y "%simbaPath%" "%backupSessionPath%\Simba\" >> "%logFile%" 2>&1
    call :Log "[SUCCESS] Backed up Simba folder"
) else (
    call :Log "[WARN] Simba folder not found, skipping backup"
)

if exist "%runeLiteProfilePath%" (
    xcopy /s /e /y "%runeLiteProfilePath%" "%backupSessionPath%\.runelite\" >> "%logFile%" 2>&1
    call :Log "[SUCCESS] Backed up .runelite folder"
) else (
    call :Log "[WARN] .runelite folder not found, skipping backup"
)

exit /b

:CompressBackup
call :Log "[INFO] Compressing backup..."
if exist "%portable7zPath%" (
    "%portable7zPath%" a -t7z -mx1 "%backupZipPath%" "%backupSessionPath%\*" >> "%logFile%" 2>&1
    if exist "%backupZipPath%" (
        call :Log "[SUCCESS] Backup created: %backupZipPath%"
        REM Keep backupSessionPath for restore
    ) else (
        call :Log "[FAILED] Compression failed."
    )
) else (
    call :Log "[FAILED] No compression tool available."
)
exit /b

:RemoveOldSimba
call :Log "[INFO] Removing old Simba folder..."
if exist "%simbaPath%" (
    rmdir /s /q "%simbaPath%"
    if exist "%simbaPath%" call :Log "[FAILED] Could not delete old Simba folder."
)
exit /b

:UninstallRuneLite
call :Log "[INFO] Running RuneLite uninstaller if available..."
if exist "%runeLiteUninstallerPath%" (
    start "" "%runeLiteUninstallerPath%" /Silent
    if %errorlevel% neq 0 call :Log "[FAILED] RuneLite uninstaller failed."
)
exit /b

:InstallSimba
call :Log "[INFO] Downloading Simba installer..."

:: Delete all old Simba installers in forceUpdatePath
del /q "%forceUpdatePath%\simba-setup_*.exe" >nul 2>&1

curl -s -L -o "%simbaSetupPath%" "https://github.com/torwent/wasp-setup/releases/latest/download/simba-setup.exe" >> "%logFile%" 2>&1
if not exist "%simbaSetupPath%" (
    call :Log "[FAILED] Simba installer download failed."
) else (
    start /wait "" "%simbaSetupPath%" --silent
    if %errorlevel%==0 (
        call :Log "[SUCCESS] Simba installation completed."
    ) else (
        call :Log "[FAILED] Simba installer exited with code %errorlevel%."
    )
)
exit /b

:ConfigureSimba
call :Log "[INFO] Configuring Simba post-install..."

:: Ensure Data folder exists
if not exist "%simbaPath%\Data" mkdir "%simbaPath%\Data"

:: Download settings.ini
set "settingsIniURL=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/settings.ini"
set "settingsIniTmp=%forceUpdatePath%\settings.ini"
set "settingsIniDest=%simbaPath%\Data\settings.ini"

%SystemRoot%\System32\curl.exe -s -L -o "%settingsIniTmp%" "%settingsIniURL%" >> "%logFile%" 2>&1

if not exist "%settingsIniTmp%" (
    call :Log "[FAILED] Failed to download settings.ini"
    exit /b
)

:: Copy into Data folder and set read-only
copy /y "%settingsIniTmp%" "%settingsIniDest%" >> "%logFile%" 2>&1
if exist "%settingsIniDest%" (
    attrib +R "%settingsIniDest%"
    call :Log "[SUCCESS] settings.ini downloaded and copied to Data folder"
) else (
    call :Log "[FAILED] Could not copy settings.ini to Data folder"
)

:: Associate .simba with Simba64.exe
ftype simba.script="%simba64ExePath%" "%%1" >> "%logFile%" 2>&1
assoc .simba=simba.script >> "%logFile%" 2>&1

if %errorlevel%==0 (
    call :Log "[SUCCESS] .simba file extension associated with Simba64.exe"
) else (
    call :Log "[FAILED] Could not associate .simba file extension"
)

exit /b

:InstallRuneLite
call :Log "[INFO] Downloading RuneLite installer..."

:: Delete all old RuneLite installers in forceUpdatePath
del /q "%forceUpdatePath%\RuneLiteSetup_*.exe" >nul 2>&1

curl -s -L -o "%runeLiteSetupPath%" "https://github.com/runelite/launcher/releases/latest/download/RuneLiteSetup.exe" >> "%logFile%" 2>&1
if not exist "%runeLiteSetupPath%" (
    call :Log "[FAILED] RuneLite installer download failed."
) else (
    start /wait "" "%runeLiteSetupPath%" /Silent
    if %errorlevel%==0 (
        call :Log "[SUCCESS] RuneLite installation completed."
    ) else (
        call :Log "[FAILED] RuneLite installer exited with code %errorlevel%."
    )
)

:DownloadWaspProfile
call :Log "[INFO] Downloading wasp-profile.properties..."
set "tempWaspFile=%forceUpdatePath%\wasp-profile.properties"

%SystemRoot%\System32\curl.exe -s -L -o "%tempWaspFile%" "%waspProfileURL%" >> "%logFile%" 2>&1

if not exist "%tempWaspFile%" (
    call :Log "[FAILED] Failed to download wasp-profile.properties"
    exit /b
)

:: Generate random 8-char name
set "name="
for /l %%i in (1,1,8) do (
    set /a "r=!random! %% 36"
    if !r! lss 10 (
        set "c=!r!"
    ) else (
        set /a "c=!r!+87"
        for /f %%C in ('powershell -NoProfile -Command "[char](!c!)"') do set "c=%%C"
    )
    set "name=!name!!c!"
)

:: Compute ID
for /f %%I in ('powershell -NoProfile -Command "[int[]]([char[]]'!name!') | Measure-Object -Sum | %%{$_.Sum}"') do set "id=%%I"

:: Build final file path in RuneLite profiles2
set "finalWaspFile=%runeLiteProfiles2%\%name%-%id%.properties"

:: Copy profile into place
copy /y "%tempWaspFile%" "%finalWaspFile%" >> "%logFile%" 2>&1
if exist "%finalWaspFile%" (
    call :Log "[SUCCESS] wasp-profile.properties copied as %name%-%id%.properties"
) else (
    call :Log "[FAILED] Could not copy wasp-profile.properties to %finalWaspFile%"
    exit /b
)

:: Launch RuneLite silently (output suppressed), wait 3s, then kill it
start "" /min powershell -WindowStyle Hidden -Command ^
  "Start-Process -FilePath '%runeLitePath%\RuneLite.exe' -WindowStyle Hidden -RedirectStandardOutput '$env:TEMP\rl_stdout.log' -RedirectStandardError '$env:TEMP\rl_stderr.log';" ^
  "Start-Sleep -Seconds 3;" ^
  "Stop-Process -Name 'RuneLite' -Force"

call :Log "[INFO] RuneLite started silently. Will close in 3 seconds..."

:: Update profiles.json with the new random profile
call :UpdateProfilesJson "%name%" "%id%"
exit /b

:UpdateProfilesJson
set "newProfileName=%~1"
set "newProfileId=%~2"
call :Log "[INFO] Updating profiles.json with new profile: %newProfileName% (ID=%newProfileId%)"

if exist "%profilesJson%" (
    set "profilesBackup=%profilesJson%.bak_%datetime%"
    copy "%profilesJson%" "%profilesBackup%" >nul
)

:: Ensure profiles.json exists and is valid
if not exist "%profilesJson%" (
    (
        echo { "profiles": [] }
    ) > "%profilesJson%"
)

powershell -NoProfile -Command ^
  "$file='%profilesJson%';" ^
  "$json=Get-Content $file -Raw | ConvertFrom-Json;" ^
  "if ($null -eq $json.profiles) { $json=@{profiles=@()} };" ^
  "$clean=@();" ^
  "foreach ($p in $json.profiles) {" ^
  "  if ($p.id -eq %newProfileId% -or $p.name -eq '%newProfileName%') { continue }" ^
  "  $p.active=$false;" ^
  "  $clean+=$p" ^
  "};" ^
  "$new=[PSCustomObject]@{ id=%newProfileId%; name='%newProfileName%'; sync=$false; active=$true; rev=-1; defaultForRsProfiles=@() };" ^
  "$clean+=$new;" ^
  "$json.profiles=$clean;" ^
  "$json | ConvertTo-Json -Depth 3 | Set-Content $file -Encoding UTF8"

if %errorlevel%==0 (
    call :Log "[SUCCESS] profiles.json updated with ID %newProfileId% and name %newProfileName%"
) else (
    call :Log "[FAILED] Failed to update profiles.json"
)
exit /b

:AutoRestore
call :Log "[INFO] Checking for backup files to restore..."
if exist "%backupSessionPath%" (
    call :Log "[INFO] Restoring files from backup session folder..."

    if exist "%backupSessionPath%\Simba\credentials.simba" (
        copy /y "%backupSessionPath%\Simba\credentials.simba" "%simbaPath%\" >> "%logFile%" 2>&1
        if %errorlevel%==0 (
            call :Log "[SUCCESS] Restored credentials.simba"
        ) else (
            call :Log "[FAILED] Could not restore credentials.simba"
        )
    ) else (
        call :Log "[WARN] No credentials.simba found in backup."
    )

    if exist "%backupSessionPath%\Simba\Configs" (
        xcopy /s /e /y "%backupSessionPath%\Simba\Configs" "%simbaPath%\Configs\" >> "%logFile%" 2>&1
        if %errorlevel%==0 (
            call :Log "[SUCCESS] Restored Configs directory"
        ) else (
            call :Log "[FAILED] Could not restore Configs directory"
        )
    ) else (
        call :Log "[WARN] No Configs directory found in backup."
    )
) else (
    call :Log "[WARN] No uncompressed backup folder found. Skipping restore."
)
exit /b

:CleanCredentialsWorlds
call :Log "[INFO] Checking credentials.simba for invalid worlds..."

if not exist "%credentialsFile%" (
    call :Log "[WARN] No credentials.simba found, skipping cleanup"
    exit /b
)

if not exist "%worldsFile%" (
    call :Log "[ERROR] worlds.txt not found at %worldsFile%"
    exit /b
)

for /f "tokens=* usebackq" %%R in (`powershell -NoProfile -Command ^
  "$worlds = Get-Content '%worldsFile%' | ForEach-Object { $_.Trim() } | Where-Object {$_ -match '^\d+$'};" ^
  "$file = Get-Content '%credentialsFile%' -Raw;" ^
  "$pattern = '\[([0-9,\s]+)\]';" ^
  "$removed = @();" ^
  "$updated = [System.Text.RegularExpressions.Regex]::Replace($file, $pattern, {" ^
  "    $raw = $args[0].Groups[1].Value;" ^
  "    $nums = $raw -split ',' | ForEach-Object { $_.Trim() };" ^
  "    $valid = $nums | Where-Object { $worlds -contains $_ };" ^
  "    $invalid = $nums | Where-Object { $worlds -notcontains $_ };" ^
  "    if ($invalid.Count -gt 0) { $script:removed += $invalid }" ^
  "    if ($valid.Count -gt 0) { '[' + ($valid -join ', ') + ']' } else { '[]' }" ^
  "});" ^
  "if ($file -ne $updated) {" ^
  "    $updated | Set-Content '%credentialsFile%' -Encoding UTF8;" ^
  "    if ($removed.Count -gt 0) { 'REMOVED=' + ($removed -join ', ') }" ^
  "    else { 'NOCHANGE' }" ^
  "} else { 'NOCHANGE' }"`) do set "cleanupResult=%%R"

if defined cleanupResult (
    if /I "!cleanupResult:~0,8!"=="REMOVED=" (
        set "removedWorlds=!cleanupResult:~8!"
        call :Log "[SUCCESS] Removed invalid worlds: !removedWorlds!"
    ) else (
        call :Log "[INFO] No invalid worlds found in credentials.simba"
    )
) else (
    call :Log "[INFO] No invalid worlds found in credentials.simba"
)

exit /b

:CreateShortcuts
call :Log "[INFO] Creating Simba64 desktop shortcut..."
if not exist "%simba64ShortcutPath%" (
    powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%simba64ShortcutPath%'); $s.TargetPath='%simba64ExePath%'; $s.Save()" >> "%logFile%" 2>&1
    if %errorlevel%==0 (
        call :Log "[SUCCESS] Created Simba64 shortcut"
    ) else (
        call :Log "[FAILED] Could not create Simba64 shortcut"
    )
)
if exist "%simba32ExePath%" del "%simba32ExePath%"
if exist "%simba32ShortcutPath%" del "%simba32ShortcutPath%"
exit /b

:FinalCleanup
call :Log "[INFO] Cleaning up installers and temp files..."
if exist "%simbaSetupPath%" del "%simbaSetupPath%"
if exist "%runeLiteSetupPath%" del "%runeLiteSetupPath%"
if exist "%tempBackupPath%" rmdir /s /q "%tempBackupPath%"

:: Delete uncompressed backup session folder (dual strategy cleanup)
if exist "%backupSessionPath%" (
    rmdir /s /q "%backupSessionPath%"
    call :Log "[INFO] Deleted temporary backup session folder"
)

:: Delete stray folders in backup root
for /d %%D in ("%backupRootPath%\*") do (
    rmdir /s /q "%%~fD"
)

:: Keep only last 5 backups
for /f "skip=5 delims=" %%F in ('2^>nul dir "%backupRootPath%\Simba_RuneLite_Backup_*.7z" /b /o-d') do (
    del "%backupRootPath%\%%F"
    call :Log "[INFO] Deleted old backup %%F"
)

:: Keep only last 5 logs
for /f "skip=5 delims=" %%F in ('2^>nul dir "%backupRootPath%\SimbaUpdate_*.log" /b /o-d') do (
    del "%backupRootPath%\%%F"
    call :Log "[INFO] Deleted old log %%F"
)

:: Delete any stray PreLog files in forceUpdatePath
del /q "%forceUpdatePath%\*PreLog*.log" >nul 2>&1
if %errorlevel%==0 (
    call :Log "[INFO] Deleted stray PreLog files from force update folder"
)

:: Keep only last 5 profiles.json backups
for /f "skip=5 delims=" %%F in ('2^>nul dir "%runeLiteProfiles2%\profiles.json.bak_*" /b /o-d') do (
    del "%runeLiteProfiles2%\%%F"
    call :Log "[INFO] Deleted old profiles.json backup %%F"
)
exit /b

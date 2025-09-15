:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)

@echo off
setlocal EnableDelayedExpansion

:: ==================== AUTO-UPDATER =====================
set "latestScriptUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/Automated_Force_Update_Tool.bat"
set "latestHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/Automated_Force_Update_Tool.sha256"

set "thisScript=%~f0"
set "tmpScript=%TEMP%\Automated_Force_Update_Tool.bat"
set "tmpHashFile=%TEMP%\Automated_Force_Update_Tool.sha256"

:: Pre-log setup (temporary log path before main logger exists)
set "preLog=%TEMP%\SimbaForceUpdate_PreLog_%RANDOM%.log"

call :PreLog "[INFO] Starting auto-update check..."

:: Download expected hash with curl
curl -s -L -o "%tmpHashFile%" "%latestHashUrl%" >> "%preLog%" 2>&1
if not exist "%tmpHashFile%" (
    call :PreLog "[ERROR] Could not download remote SHA256 file."
    exit /b 1
)

:: Read expected hash (first token only)
set "expectedHash="
for /f %%I in ('type "%tmpHashFile%"') do (
    set "expectedHash=%%I"
    goto :gotExpected
)
:gotExpected

:: Normalize expected hash to uppercase
for /f %%U in ('echo %expectedHash% ^| powershell -NoProfile -Command "$input.ToUpper()"') do set "expectedHash=%%U"

:: Compute local hash using PowerShell
for /f "usebackq" %%I in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%thisScript%').Hash.ToUpper()"`) do set "localHash=%%I"

call :PreLog "[INFO] Local SHA256:    %localHash%"
call :PreLog "[INFO] Expected SHA256: %expectedHash%"

:: Compare
if /I "%localHash%"=="%expectedHash%" (
    call :PreLog "[INFO] Script is up-to-date."
	echo.
    goto :cleanupUpdater
) else (
    call :PreLog "[WARNING] Script is outdated. Updating..."

    curl -s -L -o "%tmpScript%" "%latestScriptUrl%" >> "%preLog%" 2>&1

    if exist "%tmpScript%" (
		call :PreLog "[INFO] Script updated. Awaiting user confirmation..."
		copy /y "%tmpScript%" "%thisScript%" >nul
		echo.
		echo Press any key to continue and relaunch the updated script...
		pause >nul
		del "%tmpHashFile%" >nul 2>&1
		del "%tmpScript%" >nul 2>&1
		start "" "%thisScript%"
		exit /b
	) else (
        call :PreLog "[ERROR] Failed to download latest script."
        goto :cleanupUpdater
    )
)

:cleanupUpdater
del "%tmpHashFile%" >nul 2>&1
del "%tmpScript%" >nul 2>&1

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
call :InstallRuneLite

:: ==================== RESTORE =====================
call :AutoRestore

:: ==================== SHORTCUTS & CLEANUP =====================
call :CreateShortcuts
call :FinalCleanup

:: ==================== FINISH =====================
call :Log "[INFO] All backups are stored in: %backupZipPath%"
call :Log "[INFO] Script complete."

:: Print finish time
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

echo [%curtime%] %msg% >> "%preLog%"
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
    start "" "%simbaSetupPath%" /S
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
    start "" "%runeLiteSetupPath%" /Silent
)

call :Log "[WARN] ======================================================"
call :Log "[WARN] MAKE SURE SIMBA AND RUNELITE INSTALLS ARE COMPLETE"
call :Log "[WARN] MAKE SURE SIMBA AND RUNELITE INSTALLS ARE COMPLETE"
call :Log "[WARN] MAKE SURE SIMBA AND RUNELITE INSTALLS ARE COMPLETE"
call :Log "[WARN] MAKE SURE SIMBA AND RUNELITE INSTALLS ARE COMPLETE"
call :Log "[WARN] MAKE SURE SIMBA AND RUNELITE INSTALLS ARE COMPLETE"
call :Log "[WARN] ======================================================"
call :Log "[WARN]             PRESS ANY KEY TO CONTINUE"
call :Log "[WARN] ======================================================"
pause >nul

call :DownloadWaspProfile
exit /b

:DownloadWaspProfile
call :Log "[INFO] Downloading wasp-profile.properties..."
set "tempWaspFile=%forceUpdatePath%\wasp-profile.properties"
curl -s -L -o "%tempWaspFile%" "%waspProfileURL%" >> "%logFile%" 2>&1

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

:: Build final file path (no delayed expansion here)
set "finalWaspFile=%runeLiteProfiles2%\%name%-%id%.properties"

if exist "%finalWaspFile%" del "%finalWaspFile%"

:: Use copy + delete instead of move
copy /y "%tempWaspFile%" "%finalWaspFile%" >> "%logFile%" 2>&1
if exist "%finalWaspFile%" (
    del "%tempWaspFile%" >nul 2>&1
    call :Log "[SUCCESS] wasp-profile.properties saved as %name%-%id%.properties"
) else (
    call :Log "[FAILED] Could not save wasp-profile.properties to %finalWaspFile%"
    exit /b
)

:: Disable plugins only if file exists
if exist "%finalWaspFile%" (
    powershell -NoProfile -Command ^
      "(Get-Content '%finalWaspFile%') -replace '=true','=false' | Set-Content '%finalWaspFile%' -Encoding UTF8"
    if %errorlevel% neq 0 (
        call :Log "[FAILED] Could not disable plugins in %finalWaspFile%"
    ) else (
        call :Log "[INFO] Forced all plugin states to disabled in %finalWaspFile%"
    )
) else (
    call :Log "[FAILED] Skipped plugin disabling: file not found."
)

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

if not exist "%profilesJson%" (
    echo {"profiles":[{"id":-1,"name":"$rsprofile","sync":true,"active":false,"rev":-1,"defaultForRsProfiles":[]}]} > "%profilesJson%"
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

:: Keep only last 5 profiles.json backups
for /f "skip=5 delims=" %%F in ('2^>nul dir "%runeLiteProfiles2%\profiles.json.bak_*" /b /o-d') do (
    del "%runeLiteProfiles2%\%%F"
    call :Log "[INFO] Deleted old profiles.json backup %%F"
)
exit /b

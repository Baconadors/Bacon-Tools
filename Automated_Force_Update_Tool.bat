:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)

@echo off
setlocal EnableDelayedExpansion

:: ==================== IMMEDIATE ADMIN CHECK AND SELF-ELEVATION =====================
call :CheckAdmin
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Required administrative elevation failed or was denied.
    echo [EXIT] Script cannot proceed without full rights.
    echo [EXIT] Attempting to re-run as self-elevated.
    pause
    exit /b 1
)

:: ==================== DEBUG TOGGLES =====================
set "debugUpdateBat=true"
set "debugUpdateWorlds=true"
set "debugUpdateProfile=true"
set "debugUpdateSettings=true"
set "debugUpdateAuth=true"

set "debugRunInstallSimba=true"
set "debugRunInstallRuneLite=true"
set "debugRunBackup=true"
set "debugRunRestore=true"
set "debugRunRemoveSimba=true"
set "debugRunUninstallRuneLite=true"
set "debugRunCleanup=true"

if not exist "%LOCALAPPDATA%\SimbaForceUpdate" mkdir "%LOCALAPPDATA%\SimbaForceUpdate"

:: ==================== AUTO-UPDATER (BATCH SCRIPT) =====================
if /I "%debugUpdateBat%"=="true" (
    set "latestScriptUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/Automated_Force_Update_Tool.bat"
    set "latestHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/Automated_Force_Update_Tool.sha256"
    set "thisScript=%~f0"
    set "tmpScript=%LOCALAPPDATA%\SimbaForceUpdate\Automated_Force_Update_Tool.bat"
    set "tmpHashFile=%LOCALAPPDATA%\SimbaForceUpdate\Automated_Force_Update_Tool.sha256"
    set "preLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaForceUpdate_PreLog_%RANDOM%.log"
    call :PreLog "[INFO] Starting script auto-update check..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpHashFile%" "%latestHashUrl%" >> "%preLog%" 2>&1
    if %errorlevel% neq 0 (
        call :PreLog "[ERROR] curl failed when downloading script hash."
        set "doBatUpdate=0"
    ) else (
        set "doBatUpdate=1"
    )
) else (
    set "doBatUpdate=0"
)

if "%doBatUpdate%"=="1" goto runBatUpdater
goto batUpdaterEnd

:runBatUpdater
set "expectedHash="
for /f %%I in ('type "%tmpHashFile%"') do set "expectedHash=%%I"
for /f %%U in ('echo %expectedHash% ^| powershell -NoProfile -Command "$input.ToUpper()"') do set "expectedHash=%%U"
for /f "usebackq" %%I in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%thisScript%').Hash.ToUpper()"`) do set "localHash=%%I"
if /I "%localHash%"=="%expectedHash%" (
    call :PreLog "[INFO] Script is up-to-date."
) else (
    call :PreLog "[WARNING] Script is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpScript%" "%latestScriptUrl%" >> "%preLog%" 2>&1
    if exist "%tmpScript%" (
        copy /y "%tmpScript%" "%thisScript%" >nul
        del "%tmpHashFile%" >nul 2>&1
        del "%tmpScript%" >nul 2>&1
        call :PreLog "[SUCCESS] Script updated. Relaunching..."
        start "" "%thisScript%"
        exit /b
    )
)
del "%tmpHashFile%" >nul 2>&1
del "%tmpScript%" >nul 2>&1
goto batUpdaterEnd

:batUpdaterEnd

:: ==================== AUTO-UPDATER (BAT_AUTH.TXT) =====================
set "authFile=%LOCALAPPDATA%\SimbaForceUpdate\BAT_Auth.txt"
set "authTmpFile=%LOCALAPPDATA%\SimbaForceUpdate\BAT_Auth_tmp.txt"
set "authHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/BAT_Auth.sha256"
set "authUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/BAT_Auth.txt"
set "tmpAuthHashFile=%LOCALAPPDATA%\SimbaForceUpdate\BAT_Auth.sha256"
set "preAuthLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaAuthUpdate_PreLog_%RANDOM%.log"

if /I "%debugUpdateAuth%"=="true" (
    call :PreLog "[INFO] Starting BAT_Auth.txt auto-update check..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpAuthHashFile%" "%authHashUrl%" >> "%preAuthLog%" 2>&1
    if exist "%tmpAuthHashFile%" (
        set "doAuthUpdate=1"
    ) else (
        set "doAuthUpdate=0"
    )
) else (
    set "doAuthUpdate=0"
)

if "%doAuthUpdate%"=="1" goto AuthRunUpdater
goto AuthUpdaterEnd

:AuthRunUpdater
set "expectedAuthHash="
for /f %%I in ('type "%tmpAuthHashFile%"') do set "expectedAuthHash=%%I"
for /f %%U in ('echo %expectedAuthHash% ^| powershell -NoProfile -Command "$input.ToUpper()"') do set "expectedAuthHash=%%U"
if exist "%authFile%" (
    for /f "usebackq" %%I in (`powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%authFile%').Hash.ToUpper()"`) do set "localAuthHash=%%I"
) else (
    set "localAuthHash=NONE"
)
if /I "%localAuthHash%"=="%expectedAuthHash%" (
    call :PreLog "[INFO] BAT_Auth.txt is up-to-date."
) else (
    call :PreLog "[WARNING] BAT_Auth.txt is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%authTmpFile%" "%authUrl%" >> "%preAuthLog%" 2>&1
    if exist "%authTmpFile%" (
        copy /y "%authTmpFile%" "%authFile%" >nul
        call :PreLog "[SUCCESS] BAT_Auth.txt updated."
    )
)
del "%tmpAuthHashFile%" >nul 2>&1
del "%authTmpFile%" >nul 2>&1
goto AuthUpdaterEnd

:AuthUpdaterEnd

:: ==================== AUTO-UPDATER (WORLDS.TXT) =====================
set "worldsFile=%LOCALAPPDATA%\SimbaForceUpdate\worlds.txt"
set "worldsHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/worlds.sha256"
set "worldsUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/worlds.txt"
set "tmpWorldsHashFile=%LOCALAPPDATA%\SimbaForceUpdate\worlds.sha256"
set "preWorldsLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaWorldsUpdate_PreLog_%RANDOM%.log"

if /I "%debugUpdateWorlds%"=="true" (
    call :PreLog "[INFO] Starting worlds.txt auto-update check..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpWorldsHashFile%" "%worldsHashUrl%" >> "%preWorldsLog%" 2>&1
    if exist "%tmpWorldsHashFile%" (
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
if /I "%localWorldsHash%"=="%expectedWorldsHash%" (
    call :PreLog "[INFO] worlds.txt is up-to-date."
) else (
    call :PreLog "[WARNING] worlds.txt is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%worldsFile%" "%worldsUrl%" >> "%preWorldsLog%" 2>&1
    call :PreLog "[SUCCESS] worlds.txt updated."
)
del "%tmpWorldsHashFile%" >nul 2>&1
goto WorldsUpdaterEnd

:WorldsUpdaterEnd

:: ==================== AUTO-UPDATER (WASP-PROFILE.PROPERTIES) =====================
set "profileFile=%LOCALAPPDATA%\SimbaForceUpdate\wasp-profile.properties"
set "profileHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/wasp-profile.sha256"
set "profileUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/wasp-profile.properties"
set "tmpProfileHashFile=%LOCALAPPDATA%\SimbaForceUpdate\wasp-profile.sha256"
set "preProfileLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaProfileUpdate_PreLog_%RANDOM%.log"

if /I "%debugUpdateProfile%"=="true" (
    call :PreLog "[INFO] Starting wasp-profile.properties auto-update check..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpProfileHashFile%" "%profileHashUrl%" >> "%preProfileLog%" 2>&1
    if exist "%tmpProfileHashFile%" (
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
if /I "%localProfileHash%"=="%expectedProfileHash%" (
    call :PreLog "[INFO] wasp-profile.properties is up-to-date."
) else (
    call :PreLog "[WARNING] wasp-profile.properties is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L -o "%profileFile%" "%profileUrl%" >> "%preProfileLog%" 2>&1
    call :PreLog "[SUCCESS] wasp-profile.properties updated."
)
del "%tmpProfileHashFile%" >nul 2>&1
goto ProfileUpdaterEnd

:ProfileUpdaterEnd

:: ==================== AUTO-UPDATER (SETTINGS.INI) =====================
set "settingsFile=%LOCALAPPDATA%\SimbaForceUpdate\settings.ini"
set "settingsHashUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/settings.sha256"
set "settingsUrl=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/settings.ini"
set "tmpSettingsHashFile=%LOCALAPPDATA%\SimbaForceUpdate\settings.sha256"
set "preSettingsLog=%LOCALAPPDATA%\SimbaForceUpdate\SimbaSettingsUpdate_PreLog_%RANDOM%.log"

if /I "%debugUpdateSettings%"=="true" (
    call :PreLog "[INFO] Starting settings.ini auto-update check..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%tmpSettingsHashFile%" "%settingsHashUrl%" >> "%preSettingsLog%" 2>&1
    if exist "%tmpSettingsHashFile%" (
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
if /I "%localSettingsHash%"=="%expectedSettingsHash%" (
    call :PreLog "[INFO] settings.ini is up-to-date."
) else (
    call :PreLog "[WARNING] settings.ini is outdated. Updating..."
    %SystemRoot%\System32\curl.exe -s -L --fail -o "%settingsFile%" "%settingsUrl%" >> "%preSettingsLog%" 2>&1
    call :PreLog "[SUCCESS] settings.ini updated."
)
del "%tmpSettingsHashFile%" >nul 2>&1
goto SettingsUpdaterEnd

:SettingsUpdaterEnd

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

:: ==================== DEPENDENCIES =====================
call :InstallVC2015

:: ==================== CLEANUP OLD INSTALLATIONS =====================
call :CleanRegistry
call :KillProcesses

:: ==================== CHECK DISPLAY SCALING =====================
call :CheckAndSetDisplayScaling

call :AddDefenderExclusions

call :Log "[INFO] Flushing DNS resolver cache..."
ipconfig /flushdns >> "%logFile%" 2>&1
if %errorlevel% neq 0 (
    call :Log "[FAILED] Could not flush DNS cache."
) else (
    call :Log "[SUCCESS] DNS resolver cache flushed."
)

:: ==================== BACKUP =====================
if /I "%debugRunBackup%"=="true" (
    call :BackupData
    call :CompressBackup
) else (
    call :Log "[INFO] Skipping Backup and Compression (debugRunBackup=false)."
)

:: ==================== REMOVE OLD INSTALLS =====================
if /I "%debugRunRemoveSimba%"=="true" (
    call :RemoveOldSimba
) else (
    call :Log "[INFO] Skipping RemoveOldSimba (debugRunRemoveSimba=false)."
)

if /I "%debugRunUninstallRuneLite%"=="true" (
    call :UninstallRuneLite
) else (
    call :Log "[INFO] Skipping UninstallRuneLite (debugRunUninstallRuneLite=false)."
)

:: ==================== INSTALL NEW VERSIONS =====================
if /I "%debugRunInstallSimba%"=="true" (
    call :InstallSimba
    call :ConfigureSimba
) else (
    call :Log "[INFO] Skipping InstallSimba and ConfigureSimba (debugRunInstallSimba=false)."
)

if /I "%debugRunInstallRuneLite%"=="true" (
    call :InstallRuneLite
) else (
    call :Log "[INFO] Skipping InstallRuneLite and profile setup (debugRunInstallRuneLite=false)."
)

:: ==================== RESTORE =====================
if /I "%debugRunRestore%"=="true" (
    call :AutoRestore
    call :CleanCredentialsWorlds
) else (
    call :Log "[INFO] Skipping AutoRestore and CleanCredentialsWorlds (debugRunRestore=false)."
)

:: ==================== SHORTCUTS & CLEANUP =====================
call :CreateShortcuts

if /I "%debugRunCleanup%"=="true" (
    call :FinalCleanup
) else (
    call :Log "[INFO] Skipping FinalCleanup (debugRunCleanup=false)."
)

:: ==================== FINISH =====================
call :Log "[INFO] Backup location: %backupZipPath%"
call :Log "[INFO] Script complete."

for /f "tokens=* usebackq" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'ddd, dd/MM/yyyy @ HH:mm:ss'"`) do set "rundate=%%a"
call :Log "[DONE] Run finished on %rundate%"
echo. >> "%logFile%"

:: Display completion code logic
call :DisplayCompletionCode

endlocal
echo Press any key to finish and exit...
pause >nul
exit

:: ####################################################################
:: ########################## SUBROUTINES #############################
:: ####################################################################

:CheckAdmin
net session >nul 2>&1
if %errorlevel% equ 0 exit /b 0
echo Requesting administrative privileges...
powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b 1

:DefinePaths
for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format ddMMyyyy_HHmmss" 2^>nul') do set "datetime=%%I"
set "simbaPath=%LOCALAPPDATA%\Simba"
set "runeLitePath=%LOCALAPPDATA%\RuneLite"
set "runeLiteProfilePath=%USERPROFILE%\.runelite"
set "tempBackupPath=%LOCALAPPDATA%\SimbaBackupTMP"
set "forceUpdatePath=%LOCALAPPDATA%\SimbaForceUpdate"
set "backupRootPath=%LOCALAPPDATA%\SimbaBackups"
set "backupSessionPath=%backupRootPath%\Backup_%datetime%"
set "backupZipPath=%backupRootPath%\Simba_RuneLite_Backup_%datetime%.7z"
set "simbaSetupPath=%forceUpdatePath%\simba-setup_%datetime%.exe"
set "runeLiteSetupPath=%forceUpdatePath%\RuneLiteSetup_%datetime%.exe"
set "simba64ExePath=%simbaPath%\Simba64.exe"
set "runeLiteUninstallerPath=%runeLitePath%\unins000.exe"
set "simba64ShortcutPath=%USERPROFILE%\Desktop\Simba64.lnk"
set "portable7zDir=%LOCALAPPDATA%\SimbaTools"
set "portable7zPath=%portable7zDir%\7zr.exe"
set "logFile=%backupRootPath%\SimbaUpdate_%datetime%.log"
set "runeLiteProfiles2=%USERPROFILE%\.runelite\profiles2"
set "profilesJson=%runeLiteProfiles2%\profiles.json"
set "waspProfileURL=https://github.com/Baconadors/Bacon-Tools/releases/latest/download/wasp-profile.properties"
set "credentialsFile=%simbaPath%\credentials.simba"
exit /b

:InitLogging
if not exist "%backupRootPath%" mkdir "%backupRootPath%"
echo ===================================================== >> "%logFile%"
echo Simba + RuneLite Update Log - %datetime% >> "%logFile%"
echo ===================================================== >> "%logFile%"
if exist "%preLog%" (
    echo === AUTO-UPDATER LOG START === >> "%logFile%"
    type "%preLog%" >> "%logFile%"
    echo === AUTO-UPDATER LOG END === >> "%logFile%"
    del "%preLog%" >nul 2>&1
)
if exist "%preAuthLog%" (
    echo === AUTH-UPDATER LOG START === >> "%logFile%"
    type "%preAuthLog%" >> "%logFile%"
    echo === AUTH-UPDATER LOG END === >> "%logFile%"
    del "%preAuthLog%" >nul 2>&1
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
echo %msg% | find "[WARN]"    >nul && set "color=Yellow"
echo %msg% | find "[STRT]"    >nul && set "color=Cyan"
echo %msg% | find "[DONE]"    >nul && set "color=Cyan"
powershell -NoProfile -Command "Write-Host '[%curtime%] %msg%' -ForegroundColor %color%"
echo [%curtime%] %msg% >> "%logFile%"
exit /b

:PreLog
setlocal
set "tlog=%~1"
shift
set "msg=%*"
set "curtime=%time: =0%"
set "curtime=%curtime:~0,8%"
set "color=White"
echo %msg% | find "[INFO]"    >nul && set "color=White"
echo %msg% | find "[SUCCESS]" >nul && set "color=Green"
echo %msg% | find "[FAILED]"  >nul && set "color=Red"
echo %msg% | find "[ERROR]"   >nul && set "color=Red"
echo %msg% | find "[WARN]"    >nul && set "color=Yellow"
powershell -NoProfile -Command "Write-Host '[%curtime%] %msg%' -ForegroundColor %color%"
if defined tlog echo [%curtime%] %msg% >> "%tlog%"
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
)
exit /b

:CreateFolders
call :Log "[INFO] Ensuring backup and update folders exist..."
if not exist "%forceUpdatePath%" mkdir "%forceUpdatePath%"
if not exist "%backupSessionPath%" mkdir "%backupSessionPath%"
if not exist "%runeLiteProfiles2%" mkdir "%runeLiteProfiles2%"
exit /b

:InstallVC2015
call :Log "[INFO] Checking for Visual C++ 2015-2022 Redistributable..."
set "vcFound=false"
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like '*Visual C++ 2015-2022*Redistributable (x64)*' -or $_.DisplayName -like '*Visual C++ 2015*Redistributable (x64)*' } | Select-Object -ExpandProperty DisplayName"') do set "vcFound=true"
if "%vcFound%"=="true" (
    call :Log "[INFO] Visual C++ 2015-2022 already installed."
    exit /b 0
)
call :Log "[WARN] Visual C++ 2015-2022 (x64) not found. Downloading..."
set "vcInstaller=%forceUpdatePath%\vc_redist.x64.exe"
curl -s -L --fail -o "%vcInstaller%" "https://aka.ms/vs/17/release/vc_redist.x64.exe" >> "%logFile%" 2>&1
if not exist "%vcInstaller%" exit /b 1
call :Log "[INFO] Installing VC++ 2015-2022 (x64) silently..."
start /wait "" "%vcInstaller%" /quiet /norestart
call :Log "[SUCCESS] Visual C++ 2015-2022 installed."
if exist "%vcInstaller%" del "%vcInstaller%"
exit /b

:CleanRegistry
call :Log "[INFO] Cleaning up old Simba registry key..."
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" >nul 2>&1 && (
    reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" /f >> "%logFile%" 2>&1
)
exit /b

:KillProcesses
call :Log "[INFO] Killing Simba, RuneLite, Jagex Launcher processes..."
for %%p in (Simba32.exe Simba64.exe RuneLite.exe JagexLauncher.exe) do (
    taskkill /f /im %%p >> "%logFile%" 2>&1
)
exit /b

:CheckAndSetDisplayScaling
set "currentDPI="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command ^
    "$path = 'HKCU:\Control Panel\Desktop\PerMonitorSettings';" ^
    "if (Test-Path $path) {" ^
    "    $monitors = Get-ChildItem $path;" ^
    "    if ($monitors.Count -gt 0) {" ^
    "        $dpiValue = (Get-ItemProperty -Path $monitors[0].PSPath -Name DpiValue -ErrorAction SilentlyContinue).DpiValue;" ^
    "        if ($null -ne $dpiValue) {" ^
    "            switch ($dpiValue) { 0 { Write-Output 96 } 1 { Write-Output 120 } 2 { Write-Output 144 } 3 { Write-Output 168 } 4 { Write-Output 192 } default { Write-Output 96 } }" ^
    "        }" ^
    "    }" ^
    "}"') do set "currentDPI=%%a"
if not defined currentDPI set "currentDPI=96"
if "%currentDPI%"=="96" exit /b 0
call :Log "[INFO] Updating display scaling to 100%%..."
reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 96 /f >> "%logFile%" 2>&1
reg add "HKCU\Control Panel\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >> "%logFile%" 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v AppliedDPI /t REG_DWORD /d 96 /f >> "%logFile%" 2>&1
powershell -NoProfile -Command "$c='[DllImport(\"user32.dll\",CharSet=CharSet.Auto)] public static extern IntPtr SendMessageTimeout(IntPtr h,uint m,IntPtr w,string l,uint f,uint t,out IntPtr r); [DllImport(\"user32.dll\")] public static extern bool SystemParametersInfo(uint a,uint p,IntPtr v,uint i);'; $t=Add-Type -MemberDefinition $c -Name 'NM' -Namespace 'W32' -PassThru; $t::SystemParametersInfo(0x009F,0,[IntPtr]::Zero,0x03); $r=[IntPtr]::Zero; $t::SendMessageTimeout(0xFFFF,0x001A,[IntPtr]::Zero,'WindowMetrics',0x0002,5000,[ref]$r); $t::SendMessageTimeout(0xFFFF,0x001A,[IntPtr]::Zero,'ImmersiveColorSet',0x0002,5000,[ref]$r); $t::SendMessageTimeout(0xFFFF,0x007E,[IntPtr]::Zero,$null,0x0002,5000,[ref]$r)" >> "%logFile%" 2>&1
taskkill /f /im explorer.exe >> "%logFile%" 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
timeout /t 4 /nobreak >nul
call :Log "[SUCCESS] Display scaling updated to 100%%"
exit /b 0

:AddDefenderExclusions
call :Log "[INFO] Adding Defender exclusions..."
set "failFlag=0"
powershell -Command "Add-MpPreference -ExclusionPath '%simbaPath%'" >> "%logFile%" 2>&1
if %errorlevel% neq 0 set "failFlag=1"
powershell -Command "Add-MpPreference -ExclusionPath '%tempBackupPath%'" >> "%logFile%" 2>&1
if %errorlevel% neq 0 set "failFlag=1"
powershell -Command "Add-MpPreference -ExclusionPath '%forceUpdatePath%'" >> "%logFile%" 2>&1
if %errorlevel% neq 0 set "failFlag=1"
if %failFlag%==0 call :Log "[SUCCESS] Defender exclusions added successfully"
exit /b

:BackupData
call :Log "[INFO] Backing up existing data..."
if exist "%simbaPath%" (
    xcopy /s /e /y "%simbaPath%" "%backupSessionPath%\Simba\" >> "%logFile%" 2>&1
    call :Log "[SUCCESS] Backed up Simba folder"
)
if exist "%runeLiteProfilePath%" (
    xcopy /s /e /y "%runeLiteProfilePath%" "%backupSessionPath%\.runelite\" >> "%logFile%" 2>&1
    call :Log "[SUCCESS] Backed up .runelite folder"
)
exit /b

:CompressBackup
call :Log "[INFO] Compressing backup. Please wait..."
if exist "%portable7zPath%" (
    "%portable7zPath%" a -t7z -mx1 "%backupZipPath%" "%backupSessionPath%\*" >> "%logFile%" 2>&1
    if exist "%backupZipPath%" call :Log "[SUCCESS] Backup created."
)
exit /b

:RemoveOldSimba
call :Log "[INFO] Removing old Simba folder..."
if exist "%simbaPath%" rmdir /s /q "%simbaPath%"
exit /b

:UninstallRuneLite
call :Log "[INFO] Running RuneLite uninstaller if available..."
if exist "%runeLiteUninstallerPath%" (
    start /wait "" "%runeLiteUninstallerPath%" /Silent
    call :Log "[SUCCESS] RuneLite uninstalled."
)
exit /b

:InstallSimba
call :Log "[INFO] Downloading Simba installer..."
del /q "%forceUpdatePath%\simba-setup_*.exe" >nul 2>&1
curl -s -L -o "%simbaSetupPath%" "https://github.com/torwent/wasp-setup/releases/latest/download/simba-setup.exe" >> "%logFile%" 2>&1
start /wait "" "%simbaSetupPath%" --silent
call :Log "[SUCCESS] Simba installation completed."
exit /b

:ConfigureSimba
call :Log "[INFO] Configuring Simba post-install..."
if not exist "%simbaPath%\Data" mkdir "%simbaPath%\Data"
curl -s -L -o "%forceUpdatePath%\settings.ini" "https://github.com/Baconadors/Bacon-Tools/releases/latest/download/settings.ini" >> "%logFile%" 2>&1
copy /y "%forceUpdatePath%\settings.ini" "%simbaPath%\Data\settings.ini" >> "%logFile%" 2>&1
attrib +R "%simbaPath%\Data\settings.ini"
ftype simba.script="%simbaPath%\Simba64.exe" "%%1" >> "%logFile%" 2>&1
assoc .simba=simba.script >> "%logFile%" 2>&1
call :Log "[SUCCESS] settings.ini applied."
exit /b

:InstallRuneLite
call :Log "[INFO] Downloading RuneLite installer..."
del /q "%forceUpdatePath%\RuneLiteSetup_*.exe" >nul 2>&1
curl -s -L -o "%runeLiteSetupPath%" "https://github.com/runelite/launcher/releases/latest/download/RuneLiteSetup.exe" >> "%logFile%" 2>&1
start /wait "" "%runeLiteSetupPath%" /Silent
call :Log "[SUCCESS] RuneLite installation completed."
set "tempWaspFile=%forceUpdatePath%\wasp-profile.properties"
curl -s -L -o "%tempWaspFile%" "%waspProfileURL%" >> "%logFile%" 2>&1
set "chars=abcdefghijklmnopqrstuvwxyz0123456789"
set "name="
for /l %%i in (1,1,8) do (
    set /a "r=!random! %% 36"
    for %%j in (!r!) do set "name=!name!!chars:~%%j,1!"
)
set "id_sum=0"
for /l %%i in (0,1,7) do (
    set "char=!name:~%%i,1!"
    for /f "delims=" %%k in ('powershell -NoProfile -Command "[int][char]'!char!'"') do set /a "id_sum+=%%k"
)
set "id=!id_sum!"
copy /y "%tempWaspFile%" "%runeLiteProfiles2%\%name%-%id%.properties" >> "%logFile%" 2>&1
start "" /min powershell -WindowStyle Hidden -Command "Start-Process -FilePath '%runeLitePath%\RuneLite.exe' -WindowStyle Hidden; Start-Sleep -Seconds 3; Stop-Process -Name 'RuneLite' -Force"
call :UpdateProfilesJson "%name%" "%id%"
exit /b

:UpdateProfilesJson
set "newProfileName=%~1"
set "newProfileId=%~2"
call :Log "[INFO] Updating profiles.json..."
if exist "%profilesJson%" copy "%profilesJson%" "%profilesJson%.bak_%datetime%" >nul
if not exist "%profilesJson%" echo { "profiles": [] } > "%profilesJson%"
powershell -NoProfile -Command "$f='%profilesJson%'; $j=Get-Content $f -Raw | ConvertFrom-Json; if($null -eq $j.profiles){$j=@{profiles=@()}}; $c=@(); foreach($p in $j.profiles){if($p.id -eq %newProfileId% -or $p.name -eq '%newProfileName%'){continue} $p.active=$false; $c+=$p}; $n=[PSCustomObject]@{id=%newProfileId%; name='%newProfileName%'; sync=$false; active=$true; rev=-1; defaultForRsProfiles=@()}; $c+=$n; $j.profiles=$c; $j | ConvertTo-Json -Depth 3 | Set-Content $f -Encoding UTF8"
exit /b

:AutoRestore
call :Log "[INFO] Restoring backed up credentials and configs..."
if exist "%backupSessionPath%\Simba\credentials.simba" copy /y "%backupSessionPath%\Simba\credentials.simba" "%simbaPath%\" >> "%logFile%" 2>&1
if exist "%backupSessionPath%\Simba\Configs" xcopy /s /e /y "%backupSessionPath%\Simba\Configs" "%simbaPath%\Configs\" >> "%logFile%" 2>&1
exit /b

:CleanCredentialsWorlds
call :Log "[INFO] Checking credentials.simba for invalid worlds..."
if not exist "%credentialsFile%" exit /b
for /f "tokens=* usebackq" %%R in (`powershell -NoProfile -Command "$w=Get-Content '%worldsFile%' | Where-Object {$_ -match '^\d+$'}; $f=Get-Content '%credentialsFile%' -Raw; $p='\[([0-9,\s]+)\]'; $rm=@(); $u=[System.Text.RegularExpressions.Regex]::Replace($f,$p,{$r=$args[0].Groups[1].Value; $n=$r -split ',' | ForEach-Object {$_.Trim()}; $v=$n | Where-Object {$w -contains $_}; $i=$n | Where-Object {$w -notcontains $_}; if($i.Count -gt 0){$script:rm+=$i} if($v.Count -gt 0){'['+($v -join ', ')+']'} else {'[]'}}); if($f -ne $u){$u|Set-Content '%credentialsFile%' -Encoding UTF8; if($rm.Count -gt 0){'REMOVED='+($rm -join ', ')} else {'NOCHANGE'}} else {'NOCHANGE'}"`) do set "cleanupResult=%%R"
if defined cleanupResult if /I "!cleanupResult:~0,8!"=="REMOVED=" call :Log "[SUCCESS] Removed invalid worlds: !cleanupResult:~8!"
exit /b

:CreateShortcuts
call :Log "[INFO] Creating desktop shortcut..."
powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%simba64ShortcutPath%'); $s.TargetPath='%simbaPath%\Simba64.exe'; $s.Save()" >> "%logFile%" 2>&1
if exist "%simbaPath%\Simba32.exe" del "%simbaPath%\Simba32.exe"
exit /b

:FinalCleanup
call :Log "[INFO] Performing Final Cleanup..."
if exist "%tempBackupPath%" rmdir /s /q "%tempBackupPath%"
if exist "%backupSessionPath%" rmdir /s /q "%backupSessionPath%"
for /d %%D in ("%backupRootPath%\*") do rmdir /s /q "%%~fD"
for /f "skip=5 delims=" %%F in ('dir "%backupRootPath%\Simba_RuneLite_Backup_*.7z" /b /o-d') do del "%backupRootPath%\%%F"
for /f "skip=5 delims=" %%F in ('dir "%backupRootPath%\SimbaUpdate_*.log" /b /o-d') do del "%backupRootPath%\%%F"
del /q "%forceUpdatePath%\*PreLog*.log" >nul 2>&1
for /f "skip=5 delims=" %%F in ('dir "%runeLiteProfiles2%\profiles.json.bak_*" /b /o-d') do del "%runeLiteProfiles2%\%%F"
exit /b

:DisplayCompletionCode
setlocal EnableDelayedExpansion
echo.
powershell -NoProfile -Command "Write-Host '=====================================================' -ForegroundColor White"
powershell -NoProfile -Command "Write-Host '                    SCRIPT COMPLETE                    ' -ForegroundColor White"
powershell -NoProfile -Command "Write-Host '=====================================================' -ForegroundColor White"
set "authFile=%LOCALAPPDATA%\SimbaForceUpdate\BAT_Auth.txt"
if not exist "%authFile%" (
    powershell -NoProfile -Command "Write-Host 'BAT file completion code: [ERROR] BAT_Auth.txt not found.' -ForegroundColor Red"
    goto EndDisplay
)
powershell -NoProfile -Command ^
    "$codes = Get-Content '%authFile%' | Select-String -Pattern '([A-Za-z0-9]{6})' -AllMatches | ForEach-Object { $_.Matches.Groups[1].Value };" ^
    "if ($codes.Count -gt 0) {" ^
    "    $randIndex = Get-Random -Maximum $codes.Count;" ^
    "    Write-Host 'BAT file completion code: ' -NoNewline -ForegroundColor White;" ^
    "    Write-Host $codes[$randIndex] -ForegroundColor Cyan" ^
    "} else {" ^
    "    Write-Host 'BAT file completion code: [ERROR] No 6-digit codes found in file.' -ForegroundColor Red" ^
    "}"
:EndDisplay
echo.
endlocal
exit /b

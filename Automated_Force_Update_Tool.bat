:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)

@echo off
:: Check if the script is running elevated (admin privileges)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges. Please run as administrator.
    pause
    exit /b
)

:: =========================================================
:: DEFINE ALL PATHS AND FILENAMES USED IN SCRIPT
:: =========================================================

:: Create timestamp
setlocal
set "hour=%time:~0,2%"
if "%hour:~0,1%"==" " set "hour=0%hour:~1,1%"
set "datetime=%date:~-4%%date:~4,2%%date:~7,2%_%hour%%time:~3,2%%time:~6,2%"

:: Folder paths
set "simbaPath=%LOCALAPPDATA%\Simba"
set "runeLitePath=%LOCALAPPDATA%\RuneLite"
set "runeLiteProfilePath=%USERPROFILE%\.runelite"
set "tempBackupPath=%LOCALAPPDATA%\SimbaBackupTMP"
set "forceUpdatePath=%LOCALAPPDATA%\SimbaForceUpdate"
set "backupRootPath=%LOCALAPPDATA%\SimbaBackups"
set "backupSessionPath=%backupRootPath%\Backup_%datetime%"
set "backupZipPath=%backupRootPath%\Simba_RuneLite_Backup_%datetime%.zip"

:: Download file names and paths
set "simbaSetupFile=simba-setup_%datetime%.exe"
set "runeLiteSetupFile=RuneLiteSetup_%datetime%.exe"
set "simbaSetupPath=%forceUpdatePath%\%simbaSetupFile%"
set "runeLiteSetupPath=%forceUpdatePath%\%runeLiteSetupFile%"

:: Executable paths
set "simba32ExePath=%simbaPath%\Simba32.exe"
set "simba64ExePath=%simbaPath%\Simba64.exe"
set "runeLiteUninstallerPath=%runeLitePath%\unins000.exe"

:: Shortcut paths
set "simba64ShortcutPath=%USERPROFILE%\Desktop\Simba64.lnk"
set "simba32ShortcutPath=%USERPROFILE%\Desktop\Simba32.lnk"

:: Create folders
if not exist "%forceUpdatePath%" (
    mkdir "%forceUpdatePath%"
    echo Created SimbaForceUpdate folder at %forceUpdatePath%.
)
if not exist "%backupSessionPath%" (
    mkdir "%backupSessionPath%"
    echo Created backup folder for this session at %backupSessionPath%.
)

:: =========================================================

:: Delete Simba registry key if it exists
reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" >nul 2>&1
if %errorlevel% equ 0 (
    echo Deleting Simba registry key...
    reg delete "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Simba" /f
    echo Simba registry key deleted.
) else (
    echo Simba registry key does not exist. Skipping deletion.
)

:: End all Simba and RuneLite processes
echo Ending all Simba, OSRS, JagexLauncher, and RuneLite processes...
taskkill /f /im Simba32.exe >nul 2>&1
taskkill /f /im Simba64.exe >nul 2>&1
taskkill /f /im RuneLite.exe >nul 2>&1
taskkill /f /im JagexLauncher.exe >nul 2>&1

:: Add exclusions to Windows Defender
echo ====================================================
echo       SIMBA FOLDER WINDOWS DEFENDER EXCLUSION
echo ====================================================

echo If no input is provided within 15 seconds, the script will automatically proceed with 'y'.
echo Do you want to add the exclusion for the Simba folders in Windows Defender? (y/n):
choice /t 15 /d y /c yn >nul
set "Input=%errorlevel%"

if "%Input%"=="2" (
    set "UserChoice=n"
) else (
    set "UserChoice=y"
)

if /i "%UserChoice%" neq "y" (
    echo No changes made.
    echo.
    echo WARNING: Without adding the exclusion, Windows Defender may delete any Simba-related file.
    echo Proceeding with the rest of the script.
    echo.
) else (
    echo Adding exclusion for the Simba folder...
    PowerShell -Command "Add-MpPreference -ExclusionPath '%simbaPath%'"
    echo Adding exclusion for the SimbaBackupTMP folder...
    PowerShell -Command "Add-MpPreference -ExclusionPath '%tempBackupPath%'"
    echo Adding exclusion for the SimbaForceUpdate folder...
    PowerShell -Command "Add-MpPreference -ExclusionPath '%forceUpdatePath%'"
    echo Exclusions added successfully!
)

:: Prepare backup folder structure
if exist "%simbaPath%" (
    xcopy /s /e /y "%simbaPath%" "%backupSessionPath%\Simba\" >nul
    echo Copied Simba folder to backup session.
) else (
    echo Simba folder not found. Skipping Simba backup.
)

if exist "%runeLitePath%" (
    xcopy /s /e /y "%runeLitePath%" "%backupSessionPath%\RuneLite\" >nul
    echo Copied RuneLite folder to backup session.
) else (
    echo RuneLite folder not found. Skipping RuneLite backup.
)

if exist "%runeLiteProfilePath%" (
    xcopy /s /e /y "%runeLiteProfilePath%" "%backupSessionPath%\.runelite\" >nul
    echo Copied .runelite folder to backup session.
) else (
    echo .runelite folder not found. Skipping .runelite backup.
)

:: Compress entire backup session into single ZIP (only if non-empty)
powershell -NoProfile -Command "if (Test-Path '%backupSessionPath%') { if ((Get-ChildItem -Path '%backupSessionPath%' -Recurse | Measure-Object).Count -gt 0) { Compress-Archive -Path '%backupSessionPath%\*' -DestinationPath '%backupZipPath%' -Force; Write-Host 'Combined backup created: %backupZipPath%' } else { Write-Host 'Backup session exists but is empty. Skipping compression.' } } else { Write-Host 'Backup session path does not exist. Skipping compression.' }"

:: Delete Simba folder
if exist "%simbaPath%" (
    rmdir /s /q "%simbaPath%"
    echo Deleted Simba folder in %LOCALAPPDATA%.
)

:: Run RuneLite uninstaller if it exists
if exist "%runeLiteUninstallerPath%" (
    echo Running RuneLite uninstaller silently...
    start "" "%runeLiteUninstallerPath%" /Silent
) else (
    echo RuneLite uninstaller not found.
)

:: Ensure ForceUpdate folder exists before downloads
if not exist "%forceUpdatePath%" (
    mkdir "%forceUpdatePath%"
)

:: Download Simba installer
echo Downloading simba-setup.exe...
powershell -Command "New-Item -ItemType Directory -Force -Path '%forceUpdatePath%' > $null; Invoke-WebRequest -Uri 'https://github.com/torwent/wasp-setup/releases/latest/download/simba-setup.exe' -OutFile '%simbaSetupPath%'"

if exist "%simbaSetupPath%" (
    echo Running Simba installer silently...
    start "" "%simbaSetupPath%" /S
) else (
    echo Simba installer not found.
)

:: Download RuneLite installer
echo Downloading RuneLiteSetup.exe...
powershell -Command "New-Item -ItemType Directory -Force -Path '%forceUpdatePath%' > $null; Invoke-WebRequest -Uri 'https://github.com/runelite/launcher/releases/latest/download/RuneLiteSetup.exe' -OutFile '%runeLiteSetupPath%'"

if exist "%runeLiteSetupPath%" (
    echo Running RuneLite installer silently...
    start "" "%runeLiteSetupPath%" /Silent
) else (
    echo RuneLite installer not found.
)

:: Display installation complete message
echo Simba and RuneLite 64-bit install complete.

:: Warning prompts and countdown
echo.
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo.

echo Waiting for 5 seconds before showing prompts...
timeout /t 5 /nobreak >nul

:: Create SimbaBackupTMP folder if it doesn't exist
if not exist "%tempBackupPath%" (
    mkdir "%tempBackupPath%"
)

:: Prompt user for restoring from backup
set /p "userInput=Do you want to restore Account Credentials and Script Settings from Simba backup? (y/n): "
if /i "%userInput%"=="y" (
    if exist "%backupZipPath%" (
        echo Unzipping combined backup...
        powershell -Command "Expand-Archive -Path '%backupZipPath%' -DestinationPath '%tempBackupPath%' -Force"
        move /y "%tempBackupPath%\Backup_%datetime%\Simba\credentials.simba" "%simbaPath%\"
        move /y "%tempBackupPath%\Backup_%datetime%\Simba\Configs" "%simbaPath%\Configs"
        echo Restored Simba credentials and settings.
    ) else (
        echo Combined backup zip not found. Skipping restore.
    )
) else (
    echo Exiting without unzipping or restoring any Simba files.
)

:: Create desktop shortcut to Simba64.exe if not exists
if not exist "%simba64ShortcutPath%" (
    echo Creating shortcut to Simba64.exe on desktop...
    powershell "$s = (New-Object -COM WScript.Shell).CreateShortcut('%simba64ShortcutPath%'); $s.TargetPath = '%simba64ExePath%'; $s.Save()"
    echo Simba64 shortcut created on desktop.
) else (
    echo Simba64 shortcut already exists on desktop.
)

:: Delete Simba32.exe and shortcut if they exist
if exist "%simba32ExePath%" (
    del "%simba32ExePath%"
    echo Deleted Simba32.exe in %LOCALAPPDATA%\Simba.

    if exist "%simba32ShortcutPath%" (
        del "%simba32ShortcutPath%"
        echo Deleted Simba32 shortcut from desktop.
    )
)

:: Delete installers
if exist "%simbaSetupPath%" del "%simbaSetupPath%"
if exist "%runeLiteSetupPath%" del "%runeLiteSetupPath%"
echo Deleted Simba and RuneLite installers from SimbaForceUpdate.

:: Delete temporary backup folder
if exist "%tempBackupPath%" (
    rmdir /s /q "%tempBackupPath%"
    echo Deleted temporary folder %tempBackupPath%.
)

:: Optionally delete expanded backup session
if exist "%backupSessionPath%" (
    rmdir /s /q "%backupSessionPath%"
    echo Deleted expanded backup folder %backupSessionPath%.
)

:: Show backup file location
echo All backups are stored in:
echo %backupZipPath%

endlocal
pause

:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)

@echo off
:: Check if the script is running elevated (admin privileges)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges. Please run as administrator.
    pause
    exit /b
)

:: Check if the Simba registry key exists and delete it if it does
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

:: Add exclusion for the Simba and SimbaBackupTMP folders in Windows Defender if not already present
:: Excluding SimbaBackupTMP as Simba64.exe backup will trigger defender.
echo ====================================================
echo       SIMBA FOLDER WINDOWS DEFENDER EXCLUSION
echo ====================================================

:: Prompt the user with a timeout
echo If no input is provided within 15 seconds, the script will automatically proceed with 'y'.
echo Do you want to add the exclusion for the Simba folder in Windows Defender? (y/n):
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
    echo WARNING: Without adding the exclusion, Windows Defender may delete Simba64.exe.
    echo Proceeding with the rest of the script.
    echo.
) else (
    :: Add exclusions using PowerShell
    echo Adding exclusion for the Simba folder...
    PowerShell -Command "Add-MpPreference -ExclusionPath '%LOCALAPPDATA%\Simba'"
    echo Adding exclusion for the SimbaBackupTMP folder...
    PowerShell -Command "Add-MpPreference -ExclusionPath '%LOCALAPPDATA%\SimbaBackupTMP'"
    echo Exclusions added successfully!
)

:: Proceed with the rest of the script

:: Get the current date and time
setlocal
set "datetime=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "datetime=%datetime: =0%"

:: Set the source and destination folders for Simba
set "simbaSource=%LOCALAPPDATA%\Simba"
set "simbaZip=%LOCALAPPDATA%\Simba_%datetime%.zip"

:: Create a zip backup for Simba if it exists
if exist "%simbaSource%" (
    echo Creating a zip backup of Simba...
    powershell -Command "Compress-Archive -Path '%simbaSource%\*' -DestinationPath '%simbaZip%' -Force"
    echo Backup of Simba completed: %simbaZip%
) else (
    echo Simba folder not found. Backup skipped.
)

:: Set the source and destination folders for RuneLite
set "runeLiteSource=%LOCALAPPDATA%\RuneLite"
set "runeLiteZip=%LOCALAPPDATA%\RuneLite_%datetime%.zip"
set "runeLiteProfileSource=%USERPROFILE%\.runelite"
set "runeLiteProfileZip=%LOCALAPPDATA%\runelite_profile_%datetime%.zip"

:: Create a zip backup for RuneLite (from %LOCALAPPDATA%) if it exists
if exist "%runeLiteSource%" (
    powershell -Command "Compress-Archive -Path '%runeLiteSource%\*' -DestinationPath '%runeLiteZip%' -Force"
    echo Backup of RuneLite from %LOCALAPPDATA% completed: %runeLiteZip%
) else (
    echo RuneLite folder not found. Backup skipped.
)

:: Create a zip backup for .runelite (from %USERPROFILE%) if it exists
if exist "%runeLiteProfileSource%" (
    powershell -Command "Compress-Archive -Path '%runeLiteProfileSource%\*' -DestinationPath '%runeLiteProfileZip%' -Force"
    echo Backup of .runelite from %USERPROFILE% completed: %runeLiteProfileZip%
) else (
    echo .runelite folder not found. Backup skipped.
)

:: Delete Simba folder in %LOCALAPPDATA% if it exists
if exist "%simbaSource%" (
    rmdir /s /q "%simbaSource%"
    echo Deleted Simba folder in %LOCALAPPDATA%.
)

:: Run the unins000.exe in RuneLite folder silently
set "runeLiteUninstaller=%LOCALAPPDATA%\RuneLite\unins000.exe"
if exist "%runeLiteUninstaller%" (
    echo Running RuneLite uninstaller silently...
    start "" "%runeLiteUninstaller%" /Silent
) else (
    echo RuneLite uninstaller not found.
)

:: Set the path for downloads
set "downloadPath=%LOCALAPPDATA%"

:: Define file names with date and time
set "simbaSetupFile=simba-setup_%datetime%.exe"
set "runeLiteSetupFile=RuneLiteSetup_%datetime%.exe"

:: Download and rename simba-setup.exe
echo Downloading simba-setup.exe...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/torwent/wasp-setup/releases/latest/download/simba-setup.exe' -OutFile '%downloadPath%\%simbaSetupFile%'"

:: Run the Simba installer silently after download
set "simbaSetupPath=%downloadPath%\%simbaSetupFile%"
if exist "%simbaSetupPath%" (
    echo Running Simba installer silently...
    start "" "%simbaSetupPath%" /S
) else (
    echo Simba installer not found.
)

:: Download and rename RuneLiteSetup.exe
echo Downloading RuneLiteSetup.exe...
powershell -Command "Invoke-WebRequest -Uri 'https://github.com/runelite/launcher/releases/latest/download/RuneLiteSetup.exe' -OutFile '%downloadPath%\%runeLiteSetupFile%'"

:: Run the RuneLite installer silently after download
set "runeLiteSetupPath=%downloadPath%\%runeLiteSetupFile%"
if exist "%runeLiteSetupPath%" (
    echo Running RuneLite installer silently...
    start "" "%runeLiteSetupPath%" /Silent
) else (
    echo RuneLite installer not found.
)

:: Display installation complete message on the same line
echo Simba 32-bit and 64-bit install complete. & echo RuneLite 64-bit install complete.

:: Blank line and prompt message
echo.
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo BE SURE SIMBA INSTALL AND RUNELITE INSTALL HAS FINISHED BEFORE ANSWERING THE FOLLOWING PROMPTS!
echo.

:: Timer countdown
echo Waiting for 5 seconds before showing prompts...
timeout /t 5 /nobreak >nul

:: Create temporary folder if it does not exist
set "tempFolder=%LOCALAPPDATA%\SimbaBackupTMP"
if not exist "%tempFolder%" (
    mkdir "%tempFolder%"
)

:: Prompt user for unzipping Simba backup
set /p "userInput=Do you want to restore Account Credentials and Script Settings from Simba backup? (y/n): "
if /i "%userInput%"=="y" (
    if exist "%simbaZip%" (
        echo Unzipping Simba backup...
        powershell -Command "Expand-Archive -Path '%simbaZip%' -DestinationPath '%tempFolder%' -Force"
        move /y "%tempFolder%\Simba\credentials.simba" "%LOCALAPPDATA%\Simba\"
        move /y "%tempFolder%\Simba\Configs" "%LOCALAPPDATA%\Simba\Configs"
        echo Restored Simba credentials and settings.
    ) else (
        echo Simba backup file not found. Skipping restore.
    )
) else (
    echo Exiting without unzipping or restoring any Simba files.
)

:: Create a shortcut to Simba64.exe on the desktop if it does not already exist
set "simba64ExePath=%LOCALAPPDATA%\Simba\Simba64.exe"
set "simbaShortcut=%USERPROFILE%\Desktop\Simba64.lnk"
if not exist "%simbaShortcut%" (
    echo Creating shortcut to Simba64.exe on desktop...
    powershell "$s = (New-Object -COM WScript.Shell).CreateShortcut('%simbaShortcut%'); $s.TargetPath = '%simba64ExePath%'; $s.Save()"
    echo Simba64 shortcut created on desktop.
) else (
    echo Simba64 shortcut already exists on desktop.
)

:: Delete Simba32.exe in %LOCALAPPDATA% if it exists
set "simba32Exe=%LOCALAPPDATA%\Simba\Simba32.exe"
if exist "%simba32Exe%" (
    del "%simba32Exe%"
    echo Deleted Simba32.exe in %LOCALAPPDATA%\Simba.
)

:: Delete the temporary folder
if exist "%tempFolder%" (
    rmdir /s /q "%tempFolder%"
    echo Deleted temporary folder %tempFolder%..
)

:: Show backup file directories and filenames
echo All backups are stored in %LOCALAPPDATA%. Each backup is named with the Folder Title, date, and time as shown below:
echo %simbaZip%
echo %runeLiteZip%
echo %runeLiteProfileZip%

endlocal
pause

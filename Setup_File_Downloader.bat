:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)

@echo off
setlocal EnableDelayedExpansion

:: Check if the script is running elevated (admin privileges)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges. Please run as administrator.
    pause
    exit /b
)

:: Add Windows Defender exclusions silently (excluding RuneLite)
powershell -Command "Add-MpPreference -ExclusionPath '%USERPROFILE%\Desktop\simba-setup.exe'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionPath '%USERPROFILE%\Desktop\Automated_Force_Update_Tool.bat'" >nul 2>&1
powershell -Command "Add-MpPreference -ExclusionPath '%USERPROFILE%\Desktop\Windows_Defender_Exclusion_Tool.bat'" >nul 2>&1

:: Display Menu
echo ============================================
echo The purpose of this batch file is to download
echo several installer files and tools for use with
echo Wasp Scripts and Simba.
echo Please make a choice from the options below.
echo ============================================
echo [1] Download Simba 64-bit Installer
echo [2] Download RuneLite 64-bit Installer
echo [3] Download Automated Force Update Tool
echo [4] Download Windows Defender Exclusion Tool
echo [5] Exit
echo ============================================

:: Prompt user for choice
:retry_choice
set /p choice=Enter your choice (1-5): 

:: Process selection
if "!choice!"=="1" (
    echo Downloading Simba 64-bit Installer...
    set "filename=%USERPROFILE%\Desktop\simba-setup.exe"
    if exist "!filename!" (
        echo A file with the same name already exists. Deleting it now...
        del /f /q "!filename!"
        timeout /t 1 >nul
    )
    powershell -command "Invoke-WebRequest -Uri 'https://github.com/torwent/wasp-setup/releases/latest/download/simba-setup.exe' -OutFile '!filename!'"
    echo Download complete. File saved to the Desktop as simba-setup.exe
    goto prompt_open
)

if "!choice!"=="2" (
    echo Downloading RuneLite 64-bit Installer...
    set "filename=%USERPROFILE%\Desktop\RuneLiteSetup.exe"
    if exist "!filename!" (
        echo A file with the same name already exists. Deleting it now...
        del /f /q "!filename!"
        timeout /t 1 >nul
    )
    powershell -command "Invoke-WebRequest -Uri 'https://github.com/runelite/launcher/releases/latest/download/RuneLiteSetup.exe' -OutFile '!filename!'"
    echo Download complete. File saved to the Desktop as RuneLiteSetup.exe
    goto prompt_open
)

if "!choice!"=="3" (
    echo Downloading Automated Force Update Tool...
    set "filename=%USERPROFILE%\Desktop\Automated_Force_Update_Tool.bat"
    if exist "!filename!" (
        echo A file with the same name already exists. Deleting it now...
        del /f /q "!filename!"
        timeout /t 1 >nul
    )
    powershell -command "Invoke-WebRequest -Uri 'https://github.com/Baconadors/Bacon-Tools/releases/download/1.8/Automated_Force_Update_Tool.bat' -OutFile '!filename!'"
    echo Download complete. File saved to the Desktop as Automated_Force_Update_Tool.bat
    goto prompt_open
)

if "!choice!"=="4" (
    echo Downloading Windows Defender Exclusion Tool...
    set "filename=%USERPROFILE%\Desktop\Windows_Defender_Exclusion_Tool.bat"
    if exist "!filename!" (
        echo A file with the same name already exists. Deleting it now...
        del /f /q "!filename!"
        timeout /t 1 >nul
    )
    powershell -command "Invoke-WebRequest -Uri 'https://github.com/Baconadors/Bacon-Tools/releases/download/1.8/Windows_Defender_Exclusion_Tool.bat' -OutFile '!filename!'"
    echo Download complete. File saved to the Desktop as Windows_Defender_Exclusion_Tool.bat
    goto prompt_open
)

if "!choice!"=="5" (
    echo Script complete. Press any key to exit.
    pause
    exit /b
)

echo Invalid choice. Please enter a number between 1 and 5.
goto retry_choice

:prompt_open
echo Do you want to open the downloaded file as administrator? (y/n)
set /p openfile=
if /i "!openfile!"=="y" (
    echo Running !filename! as administrator...
    set "ext=!filename:~-4!"
    if /i "!ext!"==".bat" (
        powershell -command "Start-Process 'cmd.exe' -ArgumentList '/c ""!filename!""' -Verb RunAs"
    ) else (
        powershell -command "Start-Process '!filename!' -Verb RunAs"
    )
) else (
    echo Script complete. Press any key to exit.
    pause
)
exit /b

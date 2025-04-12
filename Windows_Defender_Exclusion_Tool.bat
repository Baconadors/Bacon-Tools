:: License: Creative Commons Attribution-NonCommercial-NoDerivatives (CC BY-NC-ND)
 
@echo off
:: Check if the script is running elevated (admin privileges)
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo This script requires administrative privileges. Please run as administrator.
    pause
    exit /b
)

:: End all Simba and RuneLite processes
echo Ending all Simba, OSRS, JagexLauncher, and RuneLite processes...
taskkill /f /im Simba32.exe >nul 2>&1
taskkill /f /im Simba64.exe >nul 2>&1
taskkill /f /im RuneLite.exe >nul 2>&1
taskkill /f /im JagexLauncher.exe >nul 2>&1

:: Add exclusion for the Simba folder in Windows Defender if not already present
echo ====================================================
echo       SIMBA FOLDER WINDOWS DEFENDER EXCLUSION
echo ====================================================

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
    echo Adding exclusion for the Simba folder...
    PowerShell -Command "Add-MpPreference -ExclusionPath '%LOCALAPPDATA%\Simba'"
    echo Exclusions added successfully!
)

pause

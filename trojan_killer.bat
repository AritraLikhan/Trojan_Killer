@echo off
title Periodic Drive Cleaner - Running every 2 seconds
echo Periodic Drive Cleaner Started
echo This script will delete ALL .lnk and .dat files from specified drives every 2 seconds
echo.

:: Get drive letters from user
set /p "drives=Enter drive letters separated by spaces (e.g., H G F): "

:: Validate input
if "%drives%"=="" (
    echo No drives specified. Exiting...
    pause
    exit /b 1
)

echo.
echo You specified: %drives%
echo This will delete ALL .lnk and .dat files from these drives every 2 seconds!
echo Press Ctrl+C to stop the periodic cleaning
pause
echo.

:: Start the periodic job
echo ============================================
echo PERIODIC CLEANING STARTED
echo Monitoring drives: %drives%
echo Checking every 2 seconds...
echo Press Ctrl+C to stop
echo ============================================
echo.

:CronJob
:: Display current time
echo [%date% %time%] Starting cleanup cycle...

:: Process each drive
for %%D in (%drives%) do (
    call :ProcessDrive %%D
)

echo [%date% %time%] Cleanup cycle complete. Waiting 2 seconds...
echo.

:: Wait 2 seconds before next cycle
timeout /t 2 >nul
goto CronJob

:ProcessDrive
set "drive=%1"

:: Add colon if not present
if not "%drive:~1,1%"==":" (
    set "drive=%drive%:"
)

:: Check if drive exists and is accessible
if not exist "%drive%\" (
    echo [SKIP] Drive %drive% not found or not accessible - skipping this cycle
    goto :eof
)

echo [FOUND] Processing drive %drive%

:: Count files before cleaning (for reporting)
set /a lnk_count=0
set /a dat_count=0

for /f %%a in ('dir "%drive%\*.lnk" /s /b 2^>nul ^| find /c /v ""') do set lnk_count=%%a
for /f %%a in ('dir "%drive%\*.dat" /s /b 2^>nul ^| find /c /v ""') do set dat_count=%%a

if %lnk_count% equ 0 if %dat_count% equ 0 (
    echo [CLEAN] Drive %drive% - No suspicious files found
    goto :eof
)

if %lnk_count% gtr 0 echo [CLEAN] Drive %drive% - Found %lnk_count% .lnk files
if %dat_count% gtr 0 echo [CLEAN] Drive %drive% - Found %dat_count% .dat files

:: Method 1: Use forfiles for .lnk files
if %lnk_count% gtr 0 (
    forfiles /p "%drive%\" /s /m "*.lnk" /c "cmd /c del /f /q @path" 2>nul
)

:: Method 1: Use forfiles for .dat files
if %dat_count% gtr 0 (
    forfiles /p "%drive%\" /s /m "*.dat" /c "cmd /c del /f /q @path" 2>nul
)

:: Method 2: Use for /r as backup for .lnk files
setlocal enabledelayedexpansion
for /r "%drive%\" %%F in (*.lnk) do (
    if exist "%%F" (
        attrib -h -s -r "%%F" 2>nul
        del /f /q "%%F" 2>nul
    )
)

:: Method 2: Use for /r as backup for .dat files
for /r "%drive%\" %%F in (*.dat) do (
    if exist "%%F" (
        attrib -h -s -r "%%F" 2>nul
        del /f /q "%%F" 2>nul
    )
)
endlocal

:: Reveal hidden files (common virus tactic)
attrib -h -s "%drive%\*" /s /d 2>nul

echo [DONE] Drive %drive% cleaning completed

goto :eof
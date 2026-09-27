@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: CONFIG - must match the folder/log used by convert_to_iphone.bat
:: ============================================================

set "FOLDER=C:\ffmpeg\video 2x"
set "OUTPUT_FILE=converted_files.txt"
set "TEMP_FILE=converted_files_new.txt"

:: ============================================================

if not exist "%OUTPUT_FILE%" (
    echo No "%OUTPUT_FILE%" found. Run convert_to_iphone.bat first.
    pause
    exit /b
)

if exist "%TEMP_FILE%" del "%TEMP_FILE%"

set "FOUND_FAILED="

:: Read the log line by line, rebuild it, retrying any FAILED entries via CPU
for /f "usebackq delims=" %%L in ("%OUTPUT_FILE%") do (
    set "LINE=%%L"

    echo !LINE! | findstr /b /c:"FAILED: " >nul
    if !ERRORLEVEL! == 0 (
        set "FOUND_FAILED=1"
        set "SRC_NAME=!LINE:~8!"
        set "FILE_NAME=!SRC_NAME!"
        for %%X in ("!FILE_NAME!") do (
            set "FILE_NAME=%%~nX"
            set "FILE_EXT=%%~xX"
        )

        echo Retrying via CPU: !SRC_NAME!...
        ffmpeg -i "%FOLDER%\!SRC_NAME!" -c:v libx264 -profile:v high -level 4.0 -preset slow -crf 22 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart -f mov "%FOLDER%\!FILE_NAME!_CPU_iphone.mov"

        if !ERRORLEVEL! == 0 if exist "%FOLDER%\!FILE_NAME!_CPU_iphone.mov" (
            echo Converted: !FILE_NAME!_CPU_iphone.mov ^(CPU retry, originally failed on GPU^) >> "%TEMP_FILE%"
        ) else (
            if exist "%FOLDER%\!FILE_NAME!_CPU_iphone.mov" del "%FOLDER%\!FILE_NAME!_CPU_iphone.mov"
            echo FAILED: !SRC_NAME! ^(also failed on CPU retry^) >> "%TEMP_FILE%"
        )
    ) else (
        echo !LINE! >> "%TEMP_FILE%"
    )
)

if not exist "%TEMP_FILE%" (
    echo. > "%TEMP_FILE%"
)

move /y "%TEMP_FILE%" "%OUTPUT_FILE%" >nul

if not defined FOUND_FAILED (
    echo No FAILED entries found in "%OUTPUT_FILE%" - nothing to retry.
) else (
    echo Retry pass complete. See "%OUTPUT_FILE%" for updated results.
)

pause
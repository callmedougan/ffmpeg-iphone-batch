@echo off
setlocal enabledelayedexpansion

:: Set the folder to scan (replace with your folder path)
set "FOLDER=C:\ffmpeg\video 2x"

:: Set the output TXT file path
set "OUTPUT_FILE=converted_files.txt"

:: Clear the output file if it exists
if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"

:: Loop through all files in the folder
for %%F in ("%FOLDER%\*.*") do (
    set "SKIP="
    set "FILE_NAME=%%~nF"
    set "FILE_EXT=%%~xF"

    if /i not "!FILE_EXT!" == ".mkv" if /i not "!FILE_EXT!" == ".mp4" if /i not "!FILE_EXT!" == ".mov" if /i not "!FILE_EXT!" == ".avi" if /i not "!FILE_EXT!" == ".wmv" set "SKIP=1"

    if not defined SKIP (
        set "VIDEO_CODEC="
        set "AUDIO_CODEC="

        for /f "delims=" %%A in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%%F" 2^>nul') do (
            set "VIDEO_CODEC=%%A"
        )

        for /f "delims=" %%A in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%%F" 2^>nul') do (
            set "AUDIO_CODEC=%%A"
        )

        set "VIDEO_CODEC=!VIDEO_CODEC: =!"
        set "AUDIO_CODEC=!AUDIO_CODEC: =!"

        set "ALREADY_OK="
        if /i "!VIDEO_CODEC!" == "h264" if /i "!AUDIO_CODEC!" == "aac" if /i "!FILE_EXT!" == ".mp4" set "ALREADY_OK=1"
        if /i "!VIDEO_CODEC!" == "h264" if /i "!AUDIO_CODEC!" == "aac" if /i "!FILE_EXT!" == ".mov" set "ALREADY_OK=1"

        if defined ALREADY_OK (
            echo %%~nxF is already iPhone-compatible. >> "%OUTPUT_FILE%"
        ) else (
            echo Converting %%~nxF to iPhone-compatible format...
            ffmpeg -i "%%F" -c:v libx264 -profile:v high -level 4.0 -preset slow -crf 22 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart -f mov "%FOLDER%\!FILE_NAME!_iphone.mov"
            echo Converted: !FILE_NAME!_iphone.mov >> "%OUTPUT_FILE%"
        )
    )
)

echo Conversion complete. See "%OUTPUT_FILE%" for details.
pause
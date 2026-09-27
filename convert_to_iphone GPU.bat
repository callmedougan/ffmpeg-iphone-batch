@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: CONFIG
:: ============================================================

:: Set the folder to scan (replace with your folder path)
set "FOLDER=C:\ffmpeg\video 2x"

:: Set the output TXT file path
set "OUTPUT_FILE=converted_files.txt"

:: Set to 1 to use GPU (NVENC) encoding, 0 to use CPU (libx264)
set "USE_GPU=1"

:: ============================================================

:: Clear the output file if it exists
if exist "%OUTPUT_FILE%" del "%OUTPUT_FILE%"

:: Set encoder options and suffix based on GPU/CPU choice
if "%USE_GPU%" == "1" (
    set "SUFFIX=_GPU_iphone"
    set "HWACCEL=-hwaccel cuda"
    set "VCODEC=-c:v h264_nvenc -profile:v high -level 4.0 -preset p6 -rc vbr -cq 22"
) else (
    set "SUFFIX=_CPU_iphone"
    set "HWACCEL="
    set "VCODEC=-c:v libx264 -profile:v high -level 4.0 -preset slow -crf 22"
)

:: Loop through all files in the folder
for %%F in ("%FOLDER%\*.*") do (
    set "SKIP="
    set "FILE_NAME=%%~nF"
    set "FILE_EXT=%%~xF"

    :: Skip non-video files (add more extensions if needed)
    if /i not "!FILE_EXT!" == ".mkv" if /i not "!FILE_EXT!" == ".mp4" if /i not "!FILE_EXT!" == ".mov" if /i not "!FILE_EXT!" == ".avi" if /i not "!FILE_EXT!" == ".wmv" set "SKIP=1"

    :: Also skip files that are already outputs from a previous run
    echo "!FILE_NAME!" | findstr /i /c:"_iphone" >nul && set "SKIP=1"

    if not defined SKIP (
        :: Use ffprobe to check video and audio codecs
        set "VIDEO_CODEC="
        set "AUDIO_CODEC="

        for /f "delims=" %%A in ('ffprobe -v error -select_streams v:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%%F" 2^>nul') do (
            set "VIDEO_CODEC=%%A"
        )

        for /f "delims=" %%A in ('ffprobe -v error -select_streams a:0 -show_entries stream^=codec_name -of default^=noprint_wrappers^=1:nokey^=1 "%%F" 2^>nul') do (
            set "AUDIO_CODEC=%%A"
        )

        :: Trim whitespace from codecs
        set "VIDEO_CODEC=!VIDEO_CODEC: =!"
        set "AUDIO_CODEC=!AUDIO_CODEC: =!"

        :: Check if the file is already iPhone-compatible (H.264 + AAC in MP4/MOV)
        set "ALREADY_OK="
        if /i "!VIDEO_CODEC!" == "h264" if /i "!AUDIO_CODEC!" == "aac" if /i "!FILE_EXT!" == ".mp4" set "ALREADY_OK=1"
        if /i "!VIDEO_CODEC!" == "h264" if /i "!AUDIO_CODEC!" == "aac" if /i "!FILE_EXT!" == ".mov" set "ALREADY_OK=1"

        if defined ALREADY_OK (
            echo %%~nxF is already iPhone-compatible. >> "%OUTPUT_FILE%"
        ) else (
            echo Converting %%~nxF to iPhone-compatible format ^(USE_GPU=%USE_GPU%^)...
            ffmpeg !HWACCEL! -i "%%F" !VCODEC! -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart -f mov "%FOLDER%\!FILE_NAME!!SUFFIX!.mov"
            echo Converted: !FILE_NAME!!SUFFIX!.mov >> "%OUTPUT_FILE%"
        )
    )
)

echo Conversion complete. See "%OUTPUT_FILE%" for details.
pause
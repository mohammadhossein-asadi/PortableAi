@echo off
setlocal EnableExtensions EnableDelayedExpansion

title PortableAI - First-Run Setup

REM ============================================================
REM PortableAI - First-Run Setup (Windows)
REM ============================================================
REM
REM Automates README Steps 2 and 3:
REM
REM   1. Downloads a llama.cpp release (CPU or CUDA) and extracts
REM      it into llama\  (skipped if already present)
REM   2. Downloads a GGUF model into models\ - pick from a
REM      curated list or paste any Hugging Face URL
REM
REM Re-run any time - completed parts are skipped safely.
REM ============================================================


REM ============================================================
REM PATH CONFIGURATION
REM ============================================================

cd /d "%~dp0"

set "ROOT=%CD%"

set "LLAMA_DIR=%ROOT%\llama"

set "MODEL_DIR=%ROOT%\models"

set "TMP_DIR=%ROOT%\tmp"

if not exist "%LLAMA_DIR%" mkdir "%LLAMA_DIR%" >nul 2>&1

if not exist "%MODEL_DIR%" mkdir "%MODEL_DIR%" >nul 2>&1

if not exist "%TMP_DIR%" mkdir "%TMP_DIR%" >nul 2>&1


REM ============================================================
REM BANNER
REM ============================================================

cls

echo.
echo ============================================================
echo            PortableAI - First-Run Setup
echo ============================================================
echo.
echo This wizard downloads everything the launchers need:
echo.
echo   Step A - llama.cpp binaries   -^>  llama\
echo   Step B - a GGUF model         -^>  models\
echo.


REM ============================================================
REM CHECKS: downloader
REM ============================================================

echo [1/4] Checking required tools...

set "DOWNLOADER=curl"

where curl >nul 2>&1

if errorlevel 1 set "DOWNLOADER=powershell"

if "%DOWNLOADER%"=="powershell" (

    where powershell >nul 2>&1

    if errorlevel 1 (

        echo.
        echo [ERROR] Neither curl.exe nor powershell was found.
        echo.
        echo Windows 10/11 include curl - if it is missing here, run this
        echo script from a regular Command Prompt.
        echo.

        pause
        exit /b 1
    )
)

echo [OK] Using %DOWNLOADER% for downloads.
echo.


REM ============================================================
REM STEP A - LLAMA.CPP BINARIES
REM ============================================================

echo [2/4] llama.cpp binaries...

if exist "%LLAMA_DIR%\llama-server.exe" (

    echo.
    echo [SKIP] llama\llama-server.exe already exists - nothing to do.
    echo.

    goto STEP_B
)

echo.

REM ------------------------------------------------------------
REM GPU DETECTION
REM ------------------------------------------------------------

set "GPU_MODE=cpu"

where nvidia-smi >nul 2>&1

if not errorlevel 1 (

    echo NVIDIA GPU detected.
    echo.
    echo   [1] CPU build      - works everywhere
    echo   [2] CUDA 12 build  - much faster on NVIDIA GPUs
    echo.

    set /p "GPU_CHOICE=Select build [1-2, default 1]: "

    if "!GPU_CHOICE!"=="2" set "GPU_MODE=cuda"

) else (

    echo No NVIDIA GPU detected - using the CPU build.

    echo.
)

set "ASSET_TAG=win-cpu-x64"

if "!GPU_MODE!"=="cuda" set "ASSET_TAG=win-cuda"

echo.

REM ------------------------------------------------------------
REM FIND LATEST RELEASE
REM ------------------------------------------------------------

echo Fetching recent llama.cpp release info from GitHub...

REM NOTE: llama.cpp's 'releases/latest' is a stub release (no binaries).
REM Real binaries live in the rolling b<N> releases, so we scan the
REM most recent ones and take the first matching official asset.

set "API_URL=https://api.github.com/repos/ggml-org/llama.cpp/releases?per_page=10"

set "RELEASE_JSON=%TMP_DIR%\rel-list.json"

if "%DOWNLOADER%"=="curl" (

    curl -sL -o "!RELEASE_JSON!" "!API_URL!"

) else (

    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri '!API_URL!' -OutFile '!RELEASE_JSON!' -UseBasicParsing } catch { exit 1 }"

)

if not exist "!RELEASE_JSON!" (

    echo.
    echo [ERROR] Could not reach the GitHub API.
    echo.
    echo Check your internet connection, or download a release manually:
    echo   https://github.com/ggml-org/llama.cpp/releases
    echo.

    pause
    exit /b 1
)

for %%A in ("!RELEASE_JSON!") do set "JSON_SIZE=%%~zA"

if !JSON_SIZE! LSS 100 (

    echo.
    echo [ERROR] GitHub API request failed - empty response.
    echo.
    echo Download a release manually:
    echo   https://github.com/ggml-org/llama.cpp/releases
    echo.

    pause
    exit /b 1
)

set "ASSET_URL="

for /f "usebackq delims=" %%U in (`findstr /C:"browser_download_url" "!RELEASE_JSON!"`) do (

    set "U=%%U"

    set "U=!U:*browser_download_url":=!"

    set "U=!U: =!"

    set "U=!U:"=!"

    set "U=!U:}=!"

    set "U=!U:,=!"

    REM Anchor to the official naming llama-bNNNN-bin-... so release-note
    REM text and cudart runtime zips can never match. Skip ARM64 for CUDA.

    if not defined ASSET_URL if "!U:~0,5!"=="https" if not "!U:llama-b=!"=="!U!" if not "!U:-bin-=!"=="!U!" if "!U:cudart=!"=="!U!" (

        if "!GPU_MODE!"=="cpu" if not "!U:win-cpu-x64=!"=="!U!" set "ASSET_URL=!U!"

        if "!GPU_MODE!"=="cuda" if not "!U:win-cuda=!"=="!U!" if "!U:win-arm64=!"=="!U!" set "ASSET_URL=!U!"
    )
)

if not defined ASSET_URL (

    echo.
    echo [ERROR] No llama.cpp asset found for build type "!ASSET_TAG!" in the 10 most recent releases.
    echo.
    echo Download the right zip manually:
    echo   https://github.com/ggml-org/llama.cpp/releases
    echo.

    pause
    exit /b 1
)

set "ASSET_URL_TMP=!ASSET_URL:/=\!"

for %%Z in ("!ASSET_URL_TMP!") do set "ZIP_NAME=%%~nxZ"

echo [OK] Found: !ZIP_NAME!

echo.

REM ------------------------------------------------------------
REM DOWNLOAD
REM ------------------------------------------------------------

echo Downloading - this can take a minute...

set "ZIP_FILE=%TMP_DIR%\!ZIP_NAME!"

REM Capture the expected size so we can reject truncated downloads.

curl -sIL "!ASSET_URL!" > "!TMP_DIR!\headers.txt" 2>nul

set "EXPECTED_SIZE=0"

for /f "tokens=2 delims=:" %%S in ('findstr /I /C:"content-length" "!TMP_DIR!\headers.txt"') do set "EXPECTED_SIZE=%%S"

set "EXPECTED_SIZE=!EXPECTED_SIZE: =!"

set "RC=0"

if "%DOWNLOADER%"=="curl" (

    REM -C - resumes a partial file left by an earlier run.

    curl -L -C - -o "!ZIP_FILE!" "!ASSET_URL!"

    set "RC=!errorlevel!"

) else (

    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '!ASSET_URL!' -OutFile '!ZIP_FILE!' -UseBasicParsing } catch { exit 1 }"

    set "RC=!errorlevel!"

)

REM A dropped connection mid-download leaves a partial file and a
REM non-zero exit code - never treat that as success. Resume once.

if not "!RC!"=="0" (

    echo.
    echo   Download interrupted - resuming...
    echo.

    if "%DOWNLOADER%"=="curl" (

        curl -L -C - -o "!ZIP_FILE!" "!ASSET_URL!"

        set "RC=!errorlevel!"

    ) else (

        powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '!ASSET_URL!' -OutFile '!ZIP_FILE!' -UseBasicParsing } catch { exit 1 }"

        set "RC=!errorlevel!"

    )
)

if not "!RC!"=="0" (

    echo.
    echo [ERROR] Download failed.
    echo.

    pause
    exit /b 1
)

if not "!EXPECTED_SIZE!"=="0" (

    for %%A in ("!ZIP_FILE!") do if not "%%~zA"=="!EXPECTED_SIZE!" (

        echo.
        echo [ERROR] Downloaded file is incomplete.
        echo   Expected: !EXPECTED_SIZE! bytes
        echo   Got:      %%~zA bytes
        echo.
        echo The partial file was kept. Re-run setup.bat - the download
        echo resumes where it left off.
        echo.

        pause
        exit /b 1
    )
)

echo.

echo Extracting into llama\...

set "EXTRACT_DIR=%TMP_DIR%\extract"

if exist "!EXTRACT_DIR!" rmdir /s /q "!EXTRACT_DIR!" >nul 2>&1

powershell -NoProfile -Command "try { Expand-Archive -Path '!ZIP_FILE!' -DestinationPath '!EXTRACT_DIR!' -Force } catch { exit 1 }"

if errorlevel 1 (

    echo.
    echo [ERROR] Extraction failed.
    echo.
    echo Extract !ZIP_NAME! manually and move all files into llama\.
    echo.

    pause
    exit /b 1
)

REM Flatten: copy every top-level folder and file into llama\

for /d %%D in ("!EXTRACT_DIR!\*") do (

    robocopy "%%D" "!LLAMA_DIR!" /E /NFL /NDL /NJH /NJS /NP >nul
)

copy /Y "!EXTRACT_DIR!\*.*" "!LLAMA_DIR!" >nul 2>&1

if not exist "!LLAMA_DIR!\llama-server.exe" (

    echo.
    echo [ERROR] Extraction finished but llama\llama-server.exe was not found.
    echo.
    echo Please extract !ZIP_NAME! manually into llama\.
    echo.

    pause
    exit /b 1
)

echo [OK] llama.cpp installed - llama\llama-server.exe is ready.

echo.


REM ============================================================
REM STEP B - GGUF MODEL
REM ============================================================

:STEP_B

echo [3/4] GGUF model...

dir /b "%MODEL_DIR%\*.gguf" >nul 2>&1

if not errorlevel 1 (

    echo.
    echo [SKIP] Models already present in models\:
    echo.

    for %%M in ("%MODEL_DIR%\*.gguf") do echo   - %%~nxM

    echo.

    set /p "ANSWER=Download another model anyway? [y/N]: "

    if /I not "!ANSWER:~0,1!"=="y" goto SETUP_DONE

    echo.
)

echo Curated models - recommended, small, fast, good quality:
echo.echo   [1] Qwen2.5-3B-Instruct (Q4_K_M)   ~2.0 GB   6 GB RAM   general chat

echo   [2] Gemma-2-2B-IT (IQ4_XS)         ~1.5 GB   4 GB RAM   lightest option

echo   [3] DeepSeek-R1-Distill-1.5B (Q5)  ~1.1 GB   4 GB RAM   reasoning model

echo   [4] Qwen2.5-Coder-7B (Q4_K_M)      ~4.4 GB   8 GB RAM   coding

echo   [5] Llama-3.2-3B-Instruct (Q4_K_M) ~1.9 GB   6 GB RAM   general chat
echo.
echo   [c] Custom - paste any Hugging Face GGUF URL
echo.

set "MODEL_URL="

set /p "MODEL_CHOICE=Select a model [1-5, c]: "

if "!MODEL_CHOICE!"=="1" set "MODEL_URL=https://huggingface.co/bartowski/Qwen2.5-3B-Instruct-GGUF/resolve/main/Qwen2.5-3B-Instruct-Q4_K_M.gguf"

if "!MODEL_CHOICE!"=="2" set "MODEL_URL=https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-IQ4_XS.gguf"

if "!MODEL_CHOICE!"=="3" set "MODEL_URL=https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q5_K_M.gguf"

if "!MODEL_CHOICE!"=="4" set "MODEL_URL=https://huggingface.co/bartowski/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf"

if "!MODEL_CHOICE!"=="5" set "MODEL_URL=https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"

if /I "!MODEL_CHOICE!"=="c" (

    echo.

    set /p "MODEL_URL=Hugging Face GGUF URL (the .../resolve/main/... link): "

    if "!MODEL_URL!"=="" (

        echo.
        echo [ERROR] No URL given.
        echo.

        pause
        exit /b 1
    )

    if /I not "!MODEL_URL:~0,23!"=="https://huggingface.co/" if /I not "!MODEL_URL:~0,14!"=="https://hf.co/" (

        echo.
        echo [ERROR] That does not look like a Hugging Face URL.
        echo.

        pause
        exit /b 1
    )
)

if not defined MODEL_URL (

    echo.
    echo [ERROR] Invalid selection.
    echo.

    pause
    exit /b 1
)


REM ============================================================
REM DOWNLOAD MODEL
REM ============================================================

echo.

echo [4/4] Downloading model...

for %%F in ("!MODEL_URL!") do set "MODEL_FILE=%MODEL_DIR%\%%~nxF"

REM Capture the expected size so we can reject truncated downloads.

curl -sIL "!MODEL_URL!" > "!TMP_DIR!\headers.txt" 2>nul

set "EXPECTED_SIZE=0"

for /f "tokens=2 delims=:" %%S in ('findstr /I /C:"content-length" "!TMP_DIR!\headers.txt"') do set "EXPECTED_SIZE=%%S"

set "EXPECTED_SIZE=!EXPECTED_SIZE: =!"

echo.

echo   From: !MODEL_URL!

echo   To:   !MODEL_FILE!

echo.

set "RC=0"

if "%DOWNLOADER%"=="curl" (

    REM -C - resumes a partial file left by an earlier run - important
    REM for multi-GB models.

    curl -L -C - -o "!MODEL_FILE!" "!MODEL_URL!"

    set "RC=!errorlevel!"

) else (

    powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '!MODEL_URL!' -OutFile '!MODEL_FILE!' -UseBasicParsing } catch { exit 1 }"

    set "RC=!errorlevel!"

)

REM A dropped connection mid-download leaves a partial file and a
REM non-zero exit code - never treat that as success. Resume once.

if not "!RC!"=="0" if exist "!MODEL_FILE!" (

    echo.
    echo   Download interrupted - resuming...
    echo.

    if "%DOWNLOADER%"=="curl" (

        curl -L -C - -o "!MODEL_FILE!" "!MODEL_URL!"

        set "RC=!errorlevel!"

    ) else (

        powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri '!MODEL_URL!' -OutFile '!MODEL_FILE!' -UseBasicParsing } catch { exit 1 }"

        set "RC=!errorlevel!"

    )
)

if not "!RC!"=="0" (

    echo.
    echo [ERROR] Model download failed.
    echo.
    echo The partial file was kept. Re-run setup.bat and pick the
    echo same model - the download resumes where it left off.
    echo.

    pause
    exit /b 1
)

set "MODEL_SIZE=0"

for %%A in ("!MODEL_FILE!") do set "MODEL_SIZE=%%~zA"

if !MODEL_SIZE! EQU 0 (

    echo.
    echo [ERROR] Downloaded file is empty - possibly a 404, wrong URL.
    echo.
    echo Check the URL and try again, or pick a curated model [1-5].
    echo.

    del "!MODEL_FILE!" >nul 2>&1

    pause
    exit /b 1
)

if not "!EXPECTED_SIZE!"=="0" if not "!MODEL_SIZE!"=="!EXPECTED_SIZE!" (

    echo.
    echo [ERROR] Downloaded file is incomplete.
    echo   Expected: !EXPECTED_SIZE! bytes
    echo   Got:      !MODEL_SIZE! bytes
    echo.
    echo The partial file was kept. Re-run setup.bat and pick the
    echo same model - the download resumes where it left off.
    echo.

    pause
    exit /b 1
)

echo.

echo [OK] Model downloaded.


REM ============================================================
REM DONE
REM ============================================================

:SETUP_DONE

rd /s /q "%TMP_DIR%" >nul 2>&1

echo.

echo ============================================================

echo                    SETUP COMPLETE

echo ============================================================

echo.

echo Start the launcher:

echo.

echo   run-llama.bat

echo.

pause

endlocal

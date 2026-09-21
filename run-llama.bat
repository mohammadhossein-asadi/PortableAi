```bat
@echo off
setlocal EnableExtensions EnableDelayedExpansion

title PortableAI - AI Agent Launcher

REM ============================================================
REM PortableAI - AI Agent Launcher
REM ============================================================
REM
REM Features:
REM
REM   1. Normal Chat
REM   2. Chat + Reasoning
REM   3. Agent + Built-in Tools
REM   4. Agent + Tools + Reasoning
REM   5. Agent + Tools + MCP
REM   6. Agent + Tools + MCP + Reasoning + Web Search
REM   7. Custom configuration
REM
REM Supported llama.cpp features:
REM
REM   - Built-in server tools
REM   - MCP servers
REM   - Reasoning / Thinking
REM   - Web UI
REM   - OpenAI-compatible API
REM   - Automatic free-port detection
REM
REM IMPORTANT:
REM
REM Web Search is provided through MCP.
REM llama.cpp does NOT provide a native web-search tool.
REM
REM Keep this server bound to 127.0.0.1 when using local
REM filesystem / shell tools.
REM ============================================================


REM ============================================================
REM PATH CONFIGURATION
REM ============================================================

cd /d "%~dp0"

set "ROOT=%CD%"

set "LLAMA_SERVER=%ROOT%\llama\llama-server.exe"
set "MODEL_DIR=%ROOT%\models"

set "WORKSPACE=%ROOT%\workspace"

set "MCP_DIR=%ROOT%\mcp"
set "MCP_CONFIG=%MCP_DIR%\mcp.json"

set "LOG_DIR=%WORKSPACE%\logs"

if not exist "%WORKSPACE%" mkdir "%WORKSPACE%" >nul 2>&1
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1
if not exist "%MCP_DIR%" mkdir "%MCP_DIR%" >nul 2>&1


REM ============================================================
REM NETWORK
REM ============================================================

set "HOST=127.0.0.1"

set "START_PORT=8080"

set "PORT_SCAN_LIMIT=100"

set "PORT="


REM ============================================================
REM DEFAULT REASONING
REM ============================================================

REM Modes:
REM   auto
REM   on
REM   off

set "REASONING_MODE=auto"

REM Reasoning effort:
REM   default
REM   minimal
REM   low
REM   medium
REM   high
REM   xhigh
REM   max

set "REASONING_EFFORT=default"

REM Reasoning token budget:
REM   -1 = unlimited/default
REM    0 = disabled
REM   N  = maximum reasoning tokens

set "REASONING_BUDGET=-1"


REM ============================================================
REM TOOL SETTINGS
REM ============================================================

set "TOOLS_ENABLED=0"

REM Built-in llama.cpp tools:
REM
REM   read_file
REM   file_glob_search
REM   grep_search
REM   exec_shell_command
REM   write_file
REM   edit_file
REM   get_info
REM
REM "all" enables all currently available built-in tools.

set "TOOLS_LIST=all"


REM ============================================================
REM MCP
REM ============================================================

set "MCP_ENABLED=0"

set "WEB_SEARCH_ENABLED=0"


REM ============================================================
REM BROWSER
REM ============================================================

set "OPEN_BROWSER=1"


REM ============================================================
REM STARTUP
REM ============================================================

cls

echo.
echo ============================================================
echo              PortableAI - AI Agent Launcher
echo ============================================================
echo.
echo        llama.cpp + Tools + MCP + Reasoning
echo.
echo ============================================================
echo.


REM ============================================================
REM CHECK LLAMA SERVER
REM ============================================================

echo [1/8] Checking llama-server...

if not exist "%LLAMA_SERVER%" (

    echo.
    echo [ERROR] llama-server.exe was not found.
    echo.
    echo Expected:
    echo %LLAMA_SERVER%
    echo.

    pause
    exit /b 1
)

echo [OK] llama-server.exe found.
echo.


REM ============================================================
REM CHECK MODELS
REM ============================================================

echo [2/8] Searching for GGUF models...
echo.

set /a MODEL_COUNT=0

for %%F in ("%MODEL_DIR%\*.gguf") do (

    set /a MODEL_COUNT+=1

    set "MODEL_!MODEL_COUNT!=%%~fF"
    set "MODEL_NAME_!MODEL_COUNT!=%%~nxF"

    echo   [!MODEL_COUNT!] %%~nxF
)

echo.

if %MODEL_COUNT% EQU 0 (

    echo [ERROR] No GGUF models found.
    echo.
    echo Model directory:
    echo %MODEL_DIR%
    echo.

    pause
    exit /b 1
)


REM ============================================================
REM MODEL SELECTION
REM ============================================================

set "MODEL_CHOICE="

if %MODEL_COUNT% EQU 1 (

    set "MODEL_CHOICE=1"

    echo Automatically selecting the only model.

) else (

    set /p "MODEL_CHOICE=Select a model [1-%MODEL_COUNT%]: "

)

set "MODEL=!MODEL_%MODEL_CHOICE%!"
set "MODEL_NAME=!MODEL_NAME_%MODEL_CHOICE%!"

if not defined MODEL (

    echo.
    echo [ERROR] Invalid model selection.
    echo.

    pause
    exit /b 1
)

echo.
echo Selected model:
echo   %MODEL_NAME%
echo.


REM ============================================================
REM MODE MENU
REM ============================================================

:MODE_MENU

echo.
echo ============================================================
echo                     AGENT MODE
echo ============================================================
echo.
echo   [1] Normal Chat
echo.
echo   [2] Chat + Reasoning
echo.
echo   [3] Agent + Built-in Tools
echo.
echo   [4] Agent + Tools + Reasoning
echo.
echo   [5] Agent + Tools + MCP
echo.
echo   [6] Agent + Tools + MCP + Reasoning + Web Search
echo.
echo   [7] Custom
echo.
echo ============================================================
echo.

set "MODE="

set /p "MODE=Select mode [1-7]: "

if "%MODE%"=="1" goto MODE_CHAT
if "%MODE%"=="2" goto MODE_REASONING
if "%MODE%"=="3" goto MODE_TOOLS
if "%MODE%"=="4" goto MODE_TOOLS_REASONING
if "%MODE%"=="5" goto MODE_MCP
if "%MODE%"=="6" goto MODE_FULL
if "%MODE%"=="7" goto MODE_CUSTOM

echo.
echo [ERROR] Invalid selection.
echo.

goto MODE_MENU


REM ============================================================
REM MODE 1
REM ============================================================

:MODE_CHAT

set "TOOLS_ENABLED=0"
set "MCP_ENABLED=0"
set "WEB_SEARCH_ENABLED=0"

set "REASONING_MODE=off"
set "REASONING_EFFORT=default"
set "REASONING_BUDGET=0"

set "MODE_NAME=Normal Chat"

goto BUILD_CONFIG


REM ============================================================
REM MODE 2
REM ============================================================

:MODE_REASONING

set "TOOLS_ENABLED=0"
set "MCP_ENABLED=0"
set "WEB_SEARCH_ENABLED=0"

set "REASONING_MODE=on"

set "REASONING_EFFORT=medium"

set "REASONING_BUDGET=4096"

set "MODE_NAME=Chat + Reasoning"

goto BUILD_CONFIG


REM ============================================================
REM MODE 3
REM ============================================================

:MODE_TOOLS

set "TOOLS_ENABLED=1"
set "MCP_ENABLED=0"
set "WEB_SEARCH_ENABLED=0"

set "REASONING_MODE=off"
set "REASONING_EFFORT=default"
set "REASONING_BUDGET=0"

set "MODE_NAME=Agent + Built-in Tools"

goto BUILD_CONFIG


REM ============================================================
REM MODE 4
REM ============================================================

:MODE_TOOLS_REASONING

set "TOOLS_ENABLED=1"
set "MCP_ENABLED=0"
set "WEB_SEARCH_ENABLED=0"

set "REASONING_MODE=on"

set "REASONING_EFFORT=medium"

set "REASONING_BUDGET=4096"

set "MODE_NAME=Agent + Tools + Reasoning"

goto BUILD_CONFIG


REM ============================================================
REM MODE 5
REM ============================================================

:MODE_MCP

set "TOOLS_ENABLED=1"
set "MCP_ENABLED=1"
set "WEB_SEARCH_ENABLED=0"

set "REASONING_MODE=off"

set "REASONING_EFFORT=default"

set "REASONING_BUDGET=0"

set "MODE_NAME=Agent + Tools + MCP"

goto BUILD_CONFIG


REM ============================================================
REM MODE 6
REM ============================================================

:MODE_FULL

set "TOOLS_ENABLED=1"
set "MCP_ENABLED=1"
set "WEB_SEARCH_ENABLED=1"

set "REASONING_MODE=on"

set "REASONING_EFFORT=medium"

set "REASONING_BUDGET=4096"

set "MODE_NAME=Full Agent"


goto BUILD_CONFIG


REM ============================================================
REM MODE 7
REM ============================================================

:MODE_CUSTOM

echo.
echo ============================================================
echo                    CUSTOM CONFIGURATION
echo ============================================================
echo.

echo Built-in Tools:
echo   [1] Enabled
echo   [0] Disabled
echo.

set /p "CUSTOM_TOOLS=Enable built-in tools? [1/0]: "

if "%CUSTOM_TOOLS%"=="1" (
    set "TOOLS_ENABLED=1"
) else (
    set "TOOLS_ENABLED=0"
)


echo.
echo MCP:
echo   [1] Enabled
echo   [0] Disabled
echo.

set /p "CUSTOM_MCP=Enable MCP? [1/0]: "

if "%CUSTOM_MCP%"=="1" (
    set "MCP_ENABLED=1"
) else (
    set "MCP_ENABLED=0"
)


echo.
echo Web Search:
echo   [1] Enabled
echo   [0] Disabled
echo.

set /p "CUSTOM_WEB=Enable Web Search? [1/0]: "

if "%CUSTOM_WEB%"=="1" (
    set "WEB_SEARCH_ENABLED=1"
) else (
    set "WEB_SEARCH_ENABLED=0"
)


echo.
echo Reasoning:
echo   [1] On
echo   [2] Off
echo   [3] Auto
echo.

set /p "CUSTOM_REASONING=Select reasoning mode [1-3]: "

if "%CUSTOM_REASONING%"=="1" (
    set "REASONING_MODE=on"
)

if "%CUSTOM_REASONING%"=="2" (
    set "REASONING_MODE=off"
)

if "%CUSTOM_REASONING%"=="3" (
    set "REASONING_MODE=auto"
)


if /I "%REASONING_MODE%"=="on" (

    echo.
    echo Reasoning effort:
    echo   [1] minimal
    echo   [2] low
    echo   [3] medium
    echo   [4] high
    echo   [5] xhigh
    echo   [6] max
    echo.

    set /p "EFFORT_CHOICE=Select effort [1-6]: "

    if "!EFFORT_CHOICE!"=="1" set "REASONING_EFFORT=minimal"
    if "!EFFORT_CHOICE!"=="2" set "REASONING_EFFORT=low"
    if "!EFFORT_CHOICE!"=="3" set "REASONING_EFFORT=medium"
    if "!EFFORT_CHOICE!"=="4" set "REASONING_EFFORT=high"
    if "!EFFORT_CHOICE!"=="5" set "REASONING_EFFORT=xhigh"
    if "!EFFORT_CHOICE!"=="6" set "REASONING_EFFORT=max"

    echo.
    set /p "REASONING_BUDGET=Reasoning token budget [-1 for default]: "

)

set "MODE_NAME=Custom"


REM ============================================================
REM BUILD CONFIG
REM ============================================================

:BUILD_CONFIG

echo.
echo ============================================================
echo                    CONFIGURATION
echo ============================================================
echo.

echo Mode:
echo   %MODE_NAME%
echo.

echo Model:
echo   %MODEL_NAME%
echo.

echo Built-in Tools:
if "%TOOLS_ENABLED%"=="1" (
    echo   ENABLED
) else (
    echo   DISABLED
)

echo.

echo MCP:
if "%MCP_ENABLED%"=="1" (
    echo   ENABLED
) else (
    echo   DISABLED
)

echo.

echo Web Search:
if "%WEB_SEARCH_ENABLED%"=="1" (
    echo   ENABLED
) else (
    echo   DISABLED
)

echo.

echo Reasoning:
echo   %REASONING_MODE%

echo.

echo Reasoning Effort:
echo   %REASONING_EFFORT%

echo.

echo Reasoning Budget:
echo   %REASONING_BUDGET%

echo.
echo ============================================================
echo.


REM ============================================================
REM MCP CONFIGURATION CHECK
REM ============================================================

if "%MCP_ENABLED%"=="1" (

    if not exist "%MCP_CONFIG%" (

        echo [WARNING] MCP is enabled but mcp.json does not exist.
        echo.
        echo Expected:
        echo %MCP_CONFIG%
        echo.
        echo MCP will be disabled.
        echo.

        set "MCP_ENABLED=0"
    )
)


REM ============================================================
REM WEB SEARCH CHECK
REM ============================================================

if "%WEB_SEARCH_ENABLED%"=="1" (

    if "%MCP_ENABLED%"=="0" (

        echo [WARNING] Web Search requires MCP.
        echo.
        echo Web Search will be disabled.
        echo.

        set "WEB_SEARCH_ENABLED=0"
    )
)


REM ============================================================
REM FIND FREE PORT
REM ============================================================

echo [6/8] Searching for available port...
echo.

set /a CURRENT_PORT=%START_PORT%
set /a LAST_PORT=%START_PORT%+%PORT_SCAN_LIMIT%-1

:PORT_SCAN

if %CURRENT_PORT% GTR %LAST_PORT% goto PORT_FAILED

netstat -ano | findstr /R /C:":%CURRENT_PORT% .*LISTENING" >nul 2>&1

if errorlevel 1 (

    set "PORT=%CURRENT_PORT%"

    echo [OK] Available port:
    echo      %PORT%
    echo.

    goto PORT_READY
)

set /a CURRENT_PORT+=1

goto PORT_SCAN


:PORT_FAILED

echo.
echo [ERROR] No available port found.
echo.

pause
exit /b 1


:PORT_READY


REM ============================================================
REM BUILD SERVER ARGUMENTS
REM ============================================================

set "SERVER_ARGS=-m "%MODEL%" --host %HOST% --port %PORT%"


REM ============================================================
REM BUILT-IN TOOLS
REM ============================================================

if "%TOOLS_ENABLED%"=="1" (

    set "SERVER_ARGS=!SERVER_ARGS! --tools %TOOLS_LIST%"

)


REM ============================================================
REM MCP
REM ============================================================

if "%MCP_ENABLED%"=="1" (

    set "SERVER_ARGS=!SERVER_ARGS! --mcp-servers-config "%MCP_CONFIG%""

)


REM ============================================================
REM REASONING
REM ============================================================

if /I "%REASONING_MODE%"=="on" (

    set "SERVER_ARGS=!SERVER_ARGS! --reasoning on"

)

if /I "%REASONING_MODE%"=="off" (

    set "SERVER_ARGS=!SERVER_ARGS! --reasoning off"

)

if /I "%REASONING_MODE%"=="auto" (

    set "SERVER_ARGS=!SERVER_ARGS! --reasoning auto"

)


REM ------------------------------------------------------------
REM Reasoning effort
REM ------------------------------------------------------------

if /I not "%REASONING_EFFORT%"=="default" (

    set "SERVER_ARGS=!SERVER_ARGS! --reasoning-effort %REASONING_EFFORT%"

)


REM ------------------------------------------------------------
REM Reasoning budget
REM ------------------------------------------------------------

if not "%REASONING_BUDGET%"=="-1" (

    set "SERVER_ARGS=!SERVER_ARGS! --reasoning-budget %REASONING_BUDGET%"

)


REM ============================================================
REM CREATE SESSION LOG
REM ============================================================

set "SESSION_LOG=%LOG_DIR%\session_%RANDOM%.log"

(
    echo ============================================================
    echo PortableAI Session
    echo ============================================================
    echo Date: %DATE% %TIME%
    echo.
    echo Model:
    echo %MODEL_NAME%
    echo.
    echo Mode:
    echo %MODE_NAME%
    echo.
    echo Server:
    echo http://%HOST%:%PORT%
    echo.
    echo Built-in Tools:
    echo %TOOLS_ENABLED%
    echo.
    echo MCP:
    echo %MCP_ENABLED%
    echo.
    echo Web Search:
    echo %WEB_SEARCH_ENABLED%
    echo.
    echo Reasoning:
    echo %REASONING_MODE%
    echo.
    echo Reasoning Effort:
    echo %REASONING_EFFORT%
    echo.
    echo Reasoning Budget:
    echo %REASONING_BUDGET%
    echo.
    echo Command:
    echo "%LLAMA_SERVER%" !SERVER_ARGS!
    echo.
    echo ============================================================
) > "%SESSION_LOG%"


REM ============================================================
REM FINAL SUMMARY
REM ============================================================

echo.
echo ============================================================
echo                     FINAL SETUP
echo ============================================================
echo.

echo Model:
echo   %MODEL_NAME%
echo.

echo Mode:
echo   %MODE_NAME%
echo.

echo Server:
echo   http://%HOST%:%PORT%
echo.

echo Built-in Tools:
if "%TOOLS_ENABLED%"=="1" (
    echo   ON
) else (
    echo   OFF
)

echo.

echo MCP:
if "%MCP_ENABLED%"=="1" (
    echo   ON
) else (
    echo   OFF
)

echo.

echo Web Search:
if "%WEB_SEARCH_ENABLED%"=="1" (
    echo   ON
) else (
    echo   OFF
)

echo.

echo Reasoning:
echo   %REASONING_MODE%

echo.

echo Reasoning Effort:
echo   %REASONING_EFFORT%

echo.

echo Reasoning Budget:
echo   %REASONING_BUDGET%

echo.

echo Session log:
echo   %SESSION_LOG%

echo.
echo ============================================================
echo.


REM ============================================================
REM SHOW IMPORTANT SECURITY NOTICE
REM ============================================================

if "%TOOLS_ENABLED%"=="1" (

    echo WARNING:
    echo Built-in tools can access the host environment.
    echo The server is restricted to localhost.
    echo Do not expose this server publicly.
    echo.
)


REM ============================================================
REM OPEN WEB UI
REM ============================================================

if "%OPEN_BROWSER%"=="1" (

    timeout /t 2 /nobreak >nul

    start "" "http://%HOST%:%PORT%"

)


REM ============================================================
REM START LLAMA SERVER
REM ============================================================

echo.
echo Starting llama-server...
echo.
echo ============================================================
echo.

"%LLAMA_SERVER%" !SERVER_ARGS!


REM ============================================================
REM SERVER STOPPED
REM ============================================================

echo.
echo ============================================================
echo                    SERVER STOPPED
echo ============================================================
echo.

echo llama-server has exited.

echo.
echo Session log:
echo %SESSION_LOG%

echo.

pause

endlocal
```

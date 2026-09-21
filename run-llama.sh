#!/usr/bin/env bash
# ============================================================
# PortableAI - AI Agent Launcher (Linux / macOS)
# ============================================================
#
# Bash port of run-llama.bat - same features, same menu:
#
#   1. Normal Chat
#   2. Chat + Reasoning
#   3. Agent + Built-in Tools
#   4. Agent + Tools + Reasoning
#   5. Agent + Tools + MCP
#   6. Agent + Tools + MCP + Reasoning + Web Search
#   7. Custom configuration
#
# Supported llama.cpp features:
#
#   - Built-in server tools
#   - MCP servers
#   - Reasoning / Thinking
#   - Web UI
#   - OpenAI-compatible API
#   - Automatic free-port detection
#
# IMPORTANT:
#
# Web Search is provided through MCP.
# llama.cpp does NOT provide a native web-search tool.
#
# Keep this server bound to 127.0.0.1 when using local
# filesystem / shell tools.
#
# Requires bash 3.2+ (works on macOS out of the box).
# ============================================================

set -u

# ============================================================
# PATH CONFIGURATION
# ============================================================

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"

ROOT="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"

LLAMA_SERVER="$ROOT/llama/llama-server"

MODEL_DIR="$ROOT/models"

WORKSPACE="$ROOT/workspace"

MCP_DIR="$ROOT/mcp"

MCP_CONFIG="$MCP_DIR/mcp.json"

LOG_DIR="$WORKSPACE/logs"

mkdir -p "$LOG_DIR" "$MCP_DIR" "$MODEL_DIR"


# ============================================================
# NETWORK
# ============================================================

HOST="127.0.0.1"

START_PORT=8080

PORT_SCAN_LIMIT=100

PORT=""


# ============================================================
# DEFAULT REASONING
# ============================================================

# Modes:  auto | on | off

REASONING_MODE="auto"

# Reasoning effort:  default | minimal | low | medium | high | xhigh | max

REASONING_EFFORT="default"

# Reasoning token budget:
#   -1 = unlimited/default
#    0 = disabled
#    N = maximum reasoning tokens

REASONING_BUDGET="-1"


# ============================================================
# TOOL SETTINGS
# ============================================================

TOOLS_ENABLED=0

# Built-in llama.cpp tools:
#
#   read_file
#   file_glob_search
#   grep_search
#   exec_shell_command
#   write_file
#   edit_file
#   get_info
#
# "all" enables all currently available built-in tools.

TOOLS_LIST="all"


# ============================================================
# MCP
# ============================================================

MCP_ENABLED=0

WEB_SEARCH_ENABLED=0


# ============================================================
# BROWSER
# ============================================================

OPEN_BROWSER=1


# ============================================================
# HELPERS
# ============================================================

pause() {

    printf '\nPress Enter to continue... '

    read -r _

    printf '\n'
}

banner() {

    clear 2>/dev/null || true

    echo ""

    cat <<'BANNER'
============================================================
         PortableAI - AI Agent Launcher
============================================================

       llama.cpp + Tools + MCP + Reasoning

============================================================
BANNER

    echo ""
}


# ============================================================
# STARTUP
# ============================================================

banner


# ============================================================
# CHECK LLAMA SERVER
# ============================================================

echo "[1/8] Checking llama-server..."

if [ ! -x "$LLAMA_SERVER" ]; then

    echo ""

    echo "[ERROR] llama-server was not found (or is not executable)."

    echo ""

    echo "Expected:"

    echo "  $LLAMA_SERVER"

    echo ""

    if [ -f "$ROOT/llama/llama-server.exe" ]; then

        echo "Note: llama\\llama-server.exe (the Windows binary) exists but"
        echo "cannot run on Linux/macOS. Download the Linux or macOS build of"
        echo "llama.cpp and extract it into llama/ - see README Step 2."

    else

        echo "Download a llama.cpp release for your OS and extract it into"
        echo "llama/ - see README Step 2."

    fi

    echo ""

    pause
    exit 1
fi

echo "[OK] llama-server found."

echo ""


# ============================================================
# CHECK MODELS
# ============================================================

echo "[2/8] Searching for GGUF models..."

echo ""

MODEL_COUNT=0

MODEL_PATHS=()

while IFS= read -r _model_file; do

    MODEL_COUNT=$((MODEL_COUNT + 1))

    MODEL_PATHS+=("$_model_file")

    echo "  [$MODEL_COUNT] $(basename -- "$_model_file")"

done < <(find "$MODEL_DIR" -maxdepth 1 -type f -name '*.gguf' 2>/dev/null | LC_ALL=C sort)

echo ""

if [ "$MODEL_COUNT" -eq 0 ]; then

    echo "[ERROR] No GGUF models found."

    echo ""

    echo "Model directory:"

    echo "  $MODEL_DIR"

    echo ""

    echo "Download at least one .gguf model - see README Step 3."

    echo ""

    pause
    exit 1
fi


# ============================================================
# MODEL SELECTION
# ============================================================

MODEL=""

MODEL_NAME=""

if [ "$MODEL_COUNT" -eq 1 ]; then

    echo "Automatically selecting the only model."

    MODEL="${MODEL_PATHS[0]}"

    MODEL_NAME="$(basename -- "$MODEL")"

else

    printf 'Select a model [1-%s]: ' "$MODEL_COUNT"

    read -r MODEL_CHOICE

    if [ -n "$MODEL_CHOICE" ] && [ "$MODEL_CHOICE" -ge 1 ] 2>/dev/null && [ "$MODEL_CHOICE" -le "$MODEL_COUNT" ] 2>/dev/null; then

        MODEL="${MODEL_PATHS[$((MODEL_CHOICE - 1))]}"

        MODEL_NAME="$(basename -- "$MODEL")"

    fi
fi

if [ -z "$MODEL" ]; then

    echo ""

    echo "[ERROR] Invalid model selection."

    echo ""

    pause
    exit 1
fi

echo ""

echo "Selected model:"

echo "  $MODEL_NAME"

echo ""


# ============================================================
# MODE MENU
# ============================================================

MODE_MENU=true

while $MODE_MENU; do

    MODE_MENU=false

    echo ""

    cat <<'MENU'
============================================================
                    AGENT MODE
============================================================

  [1] Normal Chat

  [2] Chat + Reasoning

  [3] Agent + Built-in Tools

  [4] Agent + Tools + Reasoning

  [5] Agent + Tools + MCP

  [6] Agent + Tools + MCP + Reasoning + Web Search

  [7] Custom

============================================================
MENU

    echo ""

    printf 'Select mode [1-7]: '

    if ! read -r MODE; then

        echo ""
        echo "[ERROR] Input closed - exiting."
        exit 1
    fi

    case "$MODE" in

        1) MODE_NAME="Normal Chat"
           TOOLS_ENABLED=0; MCP_ENABLED=0; WEB_SEARCH_ENABLED=0
           REASONING_MODE="off"; REASONING_EFFORT="default"; REASONING_BUDGET=0
           ;;

        2) MODE_NAME="Chat + Reasoning"
           TOOLS_ENABLED=0; MCP_ENABLED=0; WEB_SEARCH_ENABLED=0
           REASONING_MODE="on"; REASONING_EFFORT="medium"; REASONING_BUDGET=4096
           ;;

        3) MODE_NAME="Agent + Built-in Tools"
           TOOLS_ENABLED=1; MCP_ENABLED=0; WEB_SEARCH_ENABLED=0
           REASONING_MODE="off"; REASONING_EFFORT="default"; REASONING_BUDGET=0
           ;;

        4) MODE_NAME="Agent + Tools + Reasoning"
           TOOLS_ENABLED=1; MCP_ENABLED=0; WEB_SEARCH_ENABLED=0
           REASONING_MODE="on"; REASONING_EFFORT="medium"; REASONING_BUDGET=4096
           ;;

        5) MODE_NAME="Agent + Tools + MCP"
           TOOLS_ENABLED=1; MCP_ENABLED=1; WEB_SEARCH_ENABLED=0
           REASONING_MODE="off"; REASONING_EFFORT="default"; REASONING_BUDGET=0
           ;;

        6) MODE_NAME="Full Agent"
           TOOLS_ENABLED=1; MCP_ENABLED=1; WEB_SEARCH_ENABLED=1
           REASONING_MODE="on"; REASONING_EFFORT="medium"; REASONING_BUDGET=4096
           ;;

        7) MODE_NAME="Custom"

           echo ""
           echo "Built-in Tools: [1] Enabled  [0] Disabled"

           printf 'Enable built-in tools? [1/0]: '

           read -r CUSTOM_TOOLS

           if [ "$CUSTOM_TOOLS" = "1" ]; then TOOLS_ENABLED=1; else TOOLS_ENABLED=0; fi

           echo ""
           echo "MCP: [1] Enabled  [0] Disabled"

           printf 'Enable MCP? [1/0]: '

           read -r CUSTOM_MCP

           if [ "$CUSTOM_MCP" = "1" ]; then MCP_ENABLED=1; else MCP_ENABLED=0; fi

           echo ""
           echo "Web Search: [1] Enabled  [0] Disabled"

           printf 'Enable Web Search? [1/0]: '

           read -r CUSTOM_WEB

           if [ "$CUSTOM_WEB" = "1" ]; then WEB_SEARCH_ENABLED=1; else WEB_SEARCH_ENABLED=0; fi

           echo ""
           echo "Reasoning: [1] On  [2] Off  [3] Auto"

           printf 'Select reasoning mode [1-3]: '

           read -r CUSTOM_REASONING

           case "$CUSTOM_REASONING" in

               1) REASONING_MODE="on" ;;
               2) REASONING_MODE="off" ;;
               3) REASONING_MODE="auto" ;;
               *) REASONING_MODE="auto" ;;
           esac

           if [ "$REASONING_MODE" = "on" ]; then

               echo ""
               echo "Reasoning effort:"
               echo "  [1] minimal  [2] low  [3] medium  [4] high  [5] xhigh  [6] max"

               printf 'Select effort [1-6]: '

               read -r EFFORT_CHOICE

               case "$EFFORT_CHOICE" in

                   1) REASONING_EFFORT="minimal" ;;
                   2) REASONING_EFFORT="low" ;;
                   3) REASONING_EFFORT="medium" ;;
                   4) REASONING_EFFORT="high" ;;
                   5) REASONING_EFFORT="xhigh" ;;
                   6) REASONING_EFFORT="max" ;;
               esac

               echo ""

               printf 'Reasoning token budget [-1 for default]: '

               read -r REASONING_BUDGET

               [ -z "$REASONING_BUDGET" ] && REASONING_BUDGET="-1"
           fi
           ;;

        *) echo ""
           echo "[ERROR] Invalid selection."
           MODE_MENU=true
           ;;
    esac

done


# ============================================================
# BUILD CONFIG
# ============================================================

echo ""

cat <<'CONFIG_HEAD'
============================================================
                    CONFIGURATION
============================================================
CONFIG_HEAD

echo ""

echo "Mode:"

echo "  $MODE_NAME"

echo ""

echo "Model:"

echo "  $MODEL_NAME"

echo ""

if [ "$TOOLS_ENABLED" = "1" ]; then
    echo "Built-in Tools:"
    echo "  ENABLED"
else
    echo "Built-in Tools:"
    echo "  DISABLED"
fi

echo ""

if [ "$MCP_ENABLED" = "1" ]; then
    echo "MCP:"
    echo "  ENABLED"
else
    echo "MCP:"
    echo "  DISABLED"
fi

echo ""

if [ "$WEB_SEARCH_ENABLED" = "1" ]; then
    echo "Web Search:"
    echo "  ENABLED"
else
    echo "Web Search:"
    echo "  DISABLED"
fi

echo ""

echo "Reasoning:"

echo "  $REASONING_MODE"

echo ""

echo "Reasoning Effort:"

echo "  $REASONING_EFFORT"

echo ""

echo "Reasoning Budget:"

echo "  $REASONING_BUDGET"

echo ""

echo "============================================================"

echo ""


# ============================================================
# MCP CONFIGURATION CHECK
# ============================================================

if [ "$MCP_ENABLED" = "1" ] && [ ! -f "$MCP_CONFIG" ]; then

    echo "[WARNING] MCP is enabled but mcp.json does not exist."

    echo ""

    echo "Expected:"

    echo "  $MCP_CONFIG"

    echo ""

    echo "MCP will be disabled. See mcp/mcp.json.example to create one."

    echo ""

    MCP_ENABLED=0
fi


# ============================================================
# WEB SEARCH CHECK
# ============================================================

if [ "$WEB_SEARCH_ENABLED" = "1" ] && [ "$MCP_ENABLED" = "0" ]; then

    echo "[WARNING] Web Search requires MCP."

    echo ""

    echo "Web Search will be disabled."

    echo ""

    WEB_SEARCH_ENABLED=0
fi


# ============================================================
# FIND FREE PORT
# ============================================================

echo "[6/8] Searching for available port..."

echo ""

port_in_use() {

    _probe_port="$1"

    if command -v ss >/dev/null 2>&1; then

        ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${_probe_port}\$"

    elif command -v netstat >/dev/null 2>&1; then

        netstat -an 2>/dev/null | grep -E "[:.]${_probe_port}[[:space:]]" | grep -qi listen

    elif command -v lsof >/dev/null 2>&1; then

        lsof -iTCP:"$_probe_port" -sTCP:LISTEN -nP >/dev/null 2>&1

    elif command -v python3 >/dev/null 2>&1; then

        python3 -c "import socket; s=socket.socket(); s.bind(('${HOST}', ${_probe_port})); s.close()" >/dev/null 2>&1 && return 1

        return 0

    else

        return 1
    fi
}

PORT=""

CURRENT_PORT="$START_PORT"

LAST_PORT=$((START_PORT + PORT_SCAN_LIMIT - 1))

while [ "$CURRENT_PORT" -le "$LAST_PORT" ]; do

    if ! port_in_use "$CURRENT_PORT"; then

        PORT="$CURRENT_PORT"

        break
    fi

    CURRENT_PORT=$((CURRENT_PORT + 1))
done

if [ -z "$PORT" ]; then

    echo ""

    echo "[ERROR] No available port found."

    echo ""

    pause
    exit 1
fi

echo "[OK] Available port:"

echo "  $PORT"

echo ""


# ============================================================
# BUILD SERVER ARGUMENTS
# ============================================================

SERVER_ARGS=(-m "$MODEL" --host "$HOST" --port "$PORT")


# ------------------------------------------------------------
# BUILT-IN TOOLS
# ------------------------------------------------------------

if [ "$TOOLS_ENABLED" = "1" ]; then

    SERVER_ARGS+=(--tools "$TOOLS_LIST")
fi


# ------------------------------------------------------------
# MCP
# ------------------------------------------------------------

if [ "$MCP_ENABLED" = "1" ]; then

    SERVER_ARGS+=(--mcp-servers-config "$MCP_CONFIG")
fi


# ------------------------------------------------------------
# REASONING
# ------------------------------------------------------------

case "$REASONING_MODE" in

    on|off|auto) SERVER_ARGS+=(--reasoning "$REASONING_MODE") ;;
esac

if [ "$REASONING_EFFORT" != "default" ]; then

    SERVER_ARGS+=(--reasoning-effort "$REASONING_EFFORT")
fi

if [ "$REASONING_BUDGET" != "-1" ]; then

    SERVER_ARGS+=(--reasoning-budget "$REASONING_BUDGET")
fi


# ============================================================
# CREATE SESSION LOG
# ============================================================

SESSION_LOG="$LOG_DIR/session_$$_$(date +%s).log"

CMD_DISPLAY="\"$LLAMA_SERVER\" ${SERVER_ARGS[*]}"

{

    echo "============================================================"
    echo "PortableAI Session"
    echo "============================================================"
    echo "Date: $(date)"
    echo ""
    echo "Model:"
    echo "$MODEL_NAME"
    echo ""
    echo "Mode:"
    echo "$MODE_NAME"
    echo ""
    echo "Server:"
    echo "http://$HOST:$PORT"
    echo ""
    echo "Built-in Tools:"
    echo "$TOOLS_ENABLED"
    echo ""
    echo "MCP:"
    echo "$MCP_ENABLED"
    echo ""
    echo "Web Search:"
    echo "$WEB_SEARCH_ENABLED"
    echo ""
    echo "Reasoning:"
    echo "$REASONING_MODE"
    echo ""
    echo "Reasoning Effort:"
    echo "$REASONING_EFFORT"
    echo ""
    echo "Reasoning Budget:"
    echo "$REASONING_BUDGET"
    echo ""
    echo "Command:"
    echo "$CMD_DISPLAY"
    echo ""
    echo "============================================================"

} > "$SESSION_LOG"


# ============================================================
# FINAL SUMMARY
# ============================================================

echo ""

cat <<'SUMMARY_HEAD'
============================================================
                     FINAL SETUP
============================================================
SUMMARY_HEAD

echo ""

echo "Model:"

echo "  $MODEL_NAME"

echo ""

echo "Mode:"

echo "  $MODE_NAME"

echo ""

echo "Server:"

echo "  http://$HOST:$PORT"

echo ""

if [ "$TOOLS_ENABLED" = "1" ]; then
    echo "Built-in Tools:"
    echo "  ON"
else
    echo "Built-in Tools:"
    echo "  OFF"
fi

echo ""

if [ "$MCP_ENABLED" = "1" ]; then
    echo "MCP:"
    echo "  ON"
else
    echo "MCP:"
    echo "  OFF"
fi

echo ""

if [ "$WEB_SEARCH_ENABLED" = "1" ]; then
    echo "Web Search:"
    echo "  ON"
else
    echo "Web Search:"
    echo "  OFF"
fi

echo ""

echo "Reasoning:"

echo "  $REASONING_MODE"

echo ""

echo "Reasoning Effort:"

echo "  $REASONING_EFFORT"

echo ""

echo "Reasoning Budget:"

echo "  $REASONING_BUDGET"

echo ""

echo "Session log:"

echo "  $SESSION_LOG"

echo ""

echo "============================================================"

echo ""


# ============================================================
# SHOW IMPORTANT SECURITY NOTICE
# ============================================================

if [ "$TOOLS_ENABLED" = "1" ]; then

    echo "WARNING:"

    echo "Built-in tools can access the host environment."

    echo "The server is restricted to localhost."

    echo "Do not expose this server publicly."

    echo ""
fi


# ============================================================
# OPEN WEB UI
# ============================================================

if [ "$OPEN_BROWSER" = "1" ]; then

    sleep 2

    if command -v xdg-open >/dev/null 2>&1; then

        xdg-open "http://$HOST:$PORT" >/dev/null 2>&1 &

    elif command -v open >/dev/null 2>&1; then

        open "http://$HOST:$PORT" >/dev/null 2>&1 &

    fi
fi


# ============================================================
# START LLAMA SERVER
# ============================================================

echo ""

echo "Starting llama-server..."

echo ""

echo "============================================================"

echo ""

"$LLAMA_SERVER" "${SERVER_ARGS[@]}"

SERVER_EXIT_CODE=$?


# ============================================================
# SERVER STOPPED
# ============================================================

echo ""

cat <<'STOPPED_HEAD'
============================================================
                   SERVER STOPPED
============================================================
STOPPED_HEAD

echo ""

if [ "$SERVER_EXIT_CODE" -eq 0 ]; then

    echo "llama-server has exited."

else

    echo "llama-server has exited with code $SERVER_EXIT_CODE."

fi

echo ""

echo "Session log:"

echo "$SESSION_LOG"

echo ""

pause

exit "$SERVER_EXIT_CODE"

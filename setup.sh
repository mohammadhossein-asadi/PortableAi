#!/usr/bin/env bash
# ============================================================
# PortableAI - First-Run Setup (Linux / macOS)
# ============================================================
#
# Automates README Steps 2 and 3:
#
#   1. Downloads a llama.cpp release for your OS and extracts
#      it into llama/  (skipped if already present)
#   2. Downloads a GGUF model into models/ - pick from a
#      curated list or paste any Hugging Face URL
#
# Usage:
#   ./setup.sh              interactive
#   ./setup.sh --list       show curated models and exit
#
# Re-run any time - completed parts are skipped safely.
# ============================================================

set -u

# ============================================================
# PATHS
# ============================================================

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"

ROOT="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"

LLAMA_DIR="$ROOT/llama"

MODEL_DIR="$ROOT/models"

mkdir -p "$LLAMA_DIR" "$MODEL_DIR"

TMP_DIR="$ROOT/.setup-tmp"

mkdir -p "$TMP_DIR"

trap 'rm -rf "$TMP_DIR"' EXIT

# --list: print curated models and exit

if [ "${1:-}" = "--list" ]; then

    cat <<'LIST'
Curated models:

  1  Qwen2.5-3B-Instruct (Q4_K_M)        ~2.0 GB   6 GB RAM   general chat
  2  Gemma-2-2B-IT (IQ4_XS)              ~1.5 GB   4 GB RAM   lightest option
  3  DeepSeek-R1-Distill-Qwen-1.5B (Q5)  ~1.1 GB   4 GB RAM   reasoning model
  4  Qwen2.5-Coder-7B-Instruct (Q4_K_M)  ~4.4 GB   8 GB RAM   coding
  5  Llama-3.2-3B-Instruct (Q4_K_M)      ~1.9 GB   6 GB RAM   general chat

Use './setup.sh' and pick [c] to paste any Hugging Face GGUF URL.
LIST

    exit 0
fi

# ============================================================
# BANNER
# ============================================================

clear 2>/dev/null || true

cat <<'BANNER'
============================================================
           PortableAI - First-Run Setup
============================================================

This wizard downloads everything the launchers need:

  Step A - llama.cpp binaries   ->  llama/
  Step B - a GGUF model         ->  models/

BANNER

# ============================================================
# CHECKS: curl + unzip/tar
# ============================================================

echo "[1/4] Checking required tools..."

if ! command -v curl >/dev/null 2>&1; then

    echo ""
    echo "[ERROR] curl is required but was not found."
    echo ""
    echo "Install it (e.g. 'sudo apt install curl' or 'brew install curl')"
    echo "and re-run this script."
    echo ""
    exit 1
fi

if command -v unzip >/dev/null 2>&1; then

    EXTRACT="unzip"

elif command -v tar >/dev/null 2>&1 && tar --version 2>/dev/null | grep -qi bsdtar; then

    EXTRACT="tar"

else

    echo ""
    echo "[ERROR] 'unzip' is required to extract the llama.cpp release."
    echo ""
    echo "Install it (e.g. 'sudo apt install unzip' or 'brew install unzip')"
    echo "and re-run this script."
    echo ""
    exit 1
fi

echo "[OK] curl + $EXTRACT available."

echo ""

# ============================================================
# STEP A - LLAMA.CPP BINARIES
# ============================================================

echo "[2/4] llama.cpp binaries..."

if [ -x "$LLAMA_DIR/llama-server" ]; then

    echo "[SKIP] llama/llama-server already exists - nothing to do."

    echo ""

else

    echo ""

    UNAME_S="$(uname -s)"

    UNAME_M="$(uname -m)"

    case "$UNAME_S" in

        Linux*)  OS_TAG="ubuntu-x64" ;;
        Darwin)  if [ "$(uname -m)" = "arm64" ]; then OS_TAG="macos-arm64"; else OS_TAG="macos-x64"; fi ;;

        MINGW*|MSYS*|CYGWIN*)

            echo "[ERROR] This is the Linux/macOS setup script, but you are running"
            echo "it from Git Bash / MSYS on Windows."
            echo ""
            echo "Use the Windows setup instead:"
            echo ""
            echo "  setup.bat"
            echo ""
            exit 1 ;;

        *)       OS_TAG="" ;;
    esac

    if [ -z "$OS_TAG" ]; then

        echo "[ERROR] Unsupported OS: $UNAME_S"
        echo ""
        echo "Download a llama.cpp release manually from:"
        echo "  https://github.com/ggml-org/llama.cpp/releases"
        echo ""
        exit 1
    fi

    echo "Detected OS: $UNAME_S ($UNAME_M) -> build: $OS_TAG"

    echo ""

    echo "Fetching recent llama.cpp releases from GitHub..."

    # NOTE: llama.cpp's 'releases/latest' is a stub (no binaries).
    # Real binaries live in the rolling b<N> releases, so we scan the
    # most recent ones and take the first matching official asset.

    API_URL="https://api.github.com/repos/ggml-org/llama.cpp/releases?per_page=10"

    RELEASE_JSON="$TMP_DIR/rel-list.json"

    HTTP_CODE=$(curl -sL -o "$RELEASE_JSON" -w '%{http_code}' "$API_URL")

    if [ "$HTTP_CODE" != "200" ]; then

        echo "[ERROR] GitHub API request failed (HTTP $HTTP_CODE)."
        echo ""
        echo "Check your internet connection, or download a release manually:"
        echo "  https://github.com/ggml-org/llama.cpp/releases"
        echo ""
        exit 1
    fi

    # Fixed-string discriminator + pure parameter expansion - no regex
    # escaping games. Anchored to the official asset naming, so release-note
    # text, cudart runtime zips, and non-matching builds can never be picked.
    # First match = newest release (asset groups arrive newest-first).

    case "$OS_TAG" in

        ubuntu-x64)  DISC='-bin-ubuntu-x64.tar.gz' ;;
        macos-arm64) DISC='-bin-macos-arm64.tar.gz' ;;
        macos-x64)   DISC='-bin-macos-x64.tar.gz' ;;
    esac

    ASSET_LINE=$(grep '"browser_download_url"' "$RELEASE_JSON" | grep -F -- "$DISC" | head -n 1)

    ASSET_URL=""

    if [ -n "$ASSET_LINE" ]; then

        ASSET_URL="${ASSET_LINE#*browser_download_url\": \"}"

        ASSET_URL="${ASSET_URL%\"}"

        ASSET_URL="${ASSET_URL%,}"
    fi

    case "$ASSET_URL" in

        https://github.com/ggml-org/llama.cpp/releases/download/*"$DISC") ;;

        *)  ASSET_URL="" ;;
    esac

    if [ -z "$ASSET_URL" ]; then

        echo "[ERROR] No llama.cpp asset found for build type '$OS_TAG' in the 10 most recent releases."
        echo ""
        echo "Check the releases page manually:"
        echo "  https://github.com/ggml-org/llama.cpp/releases"
        echo ""
        exit 1
    fi

    ZIP_NAME="$(basename -- "$ASSET_URL")"

    echo "[OK] Found: $ZIP_NAME"

    echo ""

    echo "Downloading (this can take a minute)..."

    # Capture expected size to reject truncated downloads.

    EXPECTED_SIZE=$(curl -sIL "$ASSET_URL" | tr -d '\r' | grep -i '^content-length:' | tail -n 1 | tr -dc '0-9')

    EXPECTED_SIZE=${EXPECTED_SIZE:-0}

    if ! curl -L -C - --progress-bar -o "$TMP_DIR/$ZIP_NAME" "$ASSET_URL"; then

        echo ""
        echo "[ERROR] Download failed."
        echo ""
        exit 1
    fi

    if [ "$EXPECTED_SIZE" != "0" ]; then

        GOT_SIZE=$(wc -c < "$TMP_DIR/$ZIP_NAME" | tr -d ' ')

        if [ "$GOT_SIZE" != "$EXPECTED_SIZE" ]; then

            echo ""
            echo "[ERROR] Downloaded file is incomplete."
            echo "        Expected: $EXPECTED_SIZE bytes"
            echo "        Got:      $GOT_SIZE bytes"
            echo ""
            echo "The partial file was kept. Re-run ./setup.sh - the download"
            echo "resumes where it left off."
            echo ""
            exit 1
        fi
    fi

    echo ""

    echo "Extracting into llama/..."

    if [ "$EXTRACT" = "unzip" ]; then

        unzip -oq "$TMP_DIR/$ZIP_NAME" -d "$TMP_DIR/extract"

    else

        tar -xf "$TMP_DIR/$ZIP_NAME" -C "$TMP_DIR/extract"
    fi

    # The archive usually contains a single top folder - copy the
    # inner files so llama/ holds the binaries directly.

    if [ -d "$TMP_DIR/extract" ]; then

        INNER_COUNT=$(find "$TMP_DIR/extract" -maxdepth 1 -mindepth 1 | wc -l | tr -d ' ')

        if [ "$INNER_COUNT" = "1" ] && [ -d "$TMP_DIR/extract/$(ls "$TMP_DIR/extract" | head -n 1)" ]; then

            cp -R "$TMP_DIR/extract/$(ls "$TMP_DIR/extract" | head -n 1)/." "$LLAMA_DIR/"

        else

            cp -R "$TMP_DIR/extract/." "$LLAMA_DIR/"
        fi
    fi

    chmod +x "$LLAMA_DIR"/* 2>/dev/null || true

    rm -rf "$TMP_DIR/extract"

    if [ -x "$LLAMA_DIR/llama-server" ]; then

        echo "[OK] llama.cpp installed - llama/llama-server is ready."

    else

        echo "[ERROR] Extraction finished but llama/llama-server was not found."
        echo ""
        echo "Please extract $ZIP_NAME into llama/ manually."
        echo ""
        exit 1
    fi

    echo ""
fi

# ============================================================
# STEP B - GGUF MODEL
# ============================================================

echo "[3/4] GGUF model..."

if ls "$MODEL_DIR"/*.gguf >/dev/null 2>&1; then

    echo "[SKIP] Model(s) already present in models/:"

    echo ""

    for _m in "$MODEL_DIR"/*.gguf; do

        echo "  - $(basename -- "$_m")"
    done

    echo ""

    printf 'Download another model anyway? [y/N]: '

    read -r ANSWER

    case "$ANSWER" in

        y|Y) ;;   # continue to the picker below

        *)  echo ""
            echo "============================================================"
            echo "                   SETUP COMPLETE"
            echo "============================================================"
            echo ""
            echo "Start the launcher:"
            echo ""
            echo "  ./run-llama.sh"
            echo ""
            exit 0 ;;
    esac

    echo ""

fi

cat <<'MODELS'
Curated models (recommended - small, fast, good quality):

  [1] Qwen2.5-3B-Instruct (Q4_K_M)        ~2.0 GB   6 GB RAM   general chat
  [2] Gemma-2-2B-IT (IQ4_XS)              ~1.5 GB   4 GB RAM   lightest option
  [3] DeepSeek-R1-Distill-Qwen-1.5B (Q5)  ~1.1 GB   4 GB RAM   reasoning model
  [4] Qwen2.5-Coder-7B-Instruct (Q4_K_M)  ~4.4 GB   8 GB RAM   coding
  [5] Llama-3.2-3B-Instruct (Q4_K_M)      ~1.9 GB   6 GB RAM   general chat

MODELS

echo "  [c] Custom - paste any Hugging Face GGUF URL"

echo ""

printf 'Select a model [1-5, c]: '

read -r MODEL_CHOICE

case "$MODEL_CHOICE" in

    1) MODEL_URL="https://huggingface.co/bartowski/Qwen2.5-3B-Instruct-GGUF/resolve/main/Qwen2.5-3B-Instruct-Q4_K_M.gguf" ;;
    2) MODEL_URL="https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-IQ4_XS.gguf" ;;
    3) MODEL_URL="https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q5_K_M.gguf" ;;
    4) MODEL_URL="https://huggingface.co/bartowski/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf" ;;
    5) MODEL_URL="https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf" ;;

    c|C)
        echo ""
        printf 'Hugging Face GGUF URL (the .../resolve/main/... link): '
        read -r MODEL_URL

        case "$MODEL_URL" in

            https://huggingface.co/*|https://hf.co/*|https://cdn-lfs.huggingface.co/*) ;;

            https://*) echo ""
                       echo "[ERROR] That does not look like a Hugging Face URL."
                       echo ""
                       exit 1 ;;

            *) echo ""
               echo "[ERROR] No URL given."
               echo ""
               exit 1 ;;
        esac
        ;;

    *)  echo ""
        echo "[ERROR] Invalid selection."
        echo ""
        exit 1 ;;
esac

MODEL_FILE="$MODEL_DIR/$(basename -- "${MODEL_URL%%\?*}")"

echo ""

echo "[4/4] Downloading model..."

echo "  From: $MODEL_URL"

echo "  To:   $MODEL_FILE"

echo ""

if ! curl -L -C - --progress-bar -o "$MODEL_FILE" "$MODEL_URL"; then

    echo ""
    echo "[ERROR] Model download failed."
    echo ""
    echo "Re-run ./setup.sh later, or download the model manually"
    echo "and place it in models/ (README Step 3)."
    echo ""
    exit 1
fi

if [ ! -s "$MODEL_FILE" ]; then

    echo "[ERROR] Downloaded file is empty - possibly a 404 (wrong URL)."
    echo ""
    echo "Check the URL and try again, or pick a curated model [1-5]."
    echo ""
    rm -f "$MODEL_FILE"
    exit 1
fi

# Reject truncated downloads - compare against the expected size.

EXPECTED_SIZE=$(curl -sIL "$MODEL_URL" | tr -d '\r' | grep -i '^content-length:' | tail -n 1 | tr -dc '0-9')

if [ -n "$EXPECTED_SIZE" ] && [ "$EXPECTED_SIZE" != "0" ]; then

    GOT_SIZE=$(wc -c < "$MODEL_FILE" | tr -d ' ')

    if [ "$GOT_SIZE" != "$EXPECTED_SIZE" ]; then

        echo ""
        echo "[ERROR] Downloaded file is incomplete."
        echo "        Expected: $EXPECTED_SIZE bytes"
        echo "        Got:      $GOT_SIZE bytes"
        echo ""
        echo "The partial file was kept. Re-run ./setup.sh and pick the"
        echo "same model - the download resumes where it left off."
        echo ""
        exit 1
    fi
fi

echo ""

echo "[OK] Model downloaded."

echo ""

# ============================================================
# DONE
# ============================================================

cat <<'DONE'
============================================================
                   SETUP COMPLETE
============================================================

Start the launcher:

  ./run-llama.sh

DONE

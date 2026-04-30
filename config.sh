#!/bin/bash

# ============================================================
# CONFIG.SH - KONFIGURASI & DETEKSI PLATFORM
# ============================================================

detect_platform() {
    if [ -d "/data/data/com.termux" ]; then
        PLATFORM="termux"
        BASE_DIR="/sdcard/Download"
        PYTHON_CMD="python"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM="linux"
        BASE_DIR="$HOME/Downloads"
        PYTHON_CMD="python3"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
        BASE_DIR="$HOME/Downloads"
        PYTHON_CMD="python3"
    else
        PLATFORM="unknown"
        BASE_DIR="$HOME/Downloads"
        PYTHON_CMD="python3"
    fi

    PHOTO_DIR="$BASE_DIR/Hasil-Gallery"
    VIDEO_DIR="$BASE_DIR/Hasil-Video"
    MUSIC_DIR="$BASE_DIR/Hasil-Musik"
    TERABOX_DIR="$BASE_DIR/Hasil-Terabox"
    BATCH_DIR="$BASE_DIR/Hasil-Batch"
}

COOKIE_FILE="$HOME/.terabox_cookie"
YT_COOKIE="$HOME/.youtube_cookies.txt"
LOG_FILE="$HOME/.downloader.log"

YT_COOKIE_OPT=""
if [ -f "$BASE_DIR/cookies.txt" ]; then
    YT_COOKIE_OPT="--cookies $BASE_DIR/cookies.txt"
elif [ -f "$YT_COOKIE" ]; then
    YT_COOKIE_OPT="--cookies $YT_COOKIE"
fi

REPO_URL="https://raw.githubusercontent.com/nanang55550-star/The-downloader-/main"

#!/bin/bash

# ============================================================
# MENUS/SYSTEM.SH - MENU SISTEM
# ============================================================

set_terabox_cookie() {
    echo -e "\033[1;33m=== SET COOKIE TERABOX ===\033[0m"
    read -p "Paste cookie: " cookie_val
    [ -z "$cookie_val" ] && return
    echo "$cookie_val" > "$COOKIE_FILE"
    chmod 600 "$COOKIE_FILE"
    echo -e "\033[1;32m[SUCCESS] Cookie tersimpan!\033[0m"
    log_activity "Cookie Terabox updated"
}

set_youtube_cookie() {
    echo -e "\033[1;33m=== SET COOKIE YOUTUBE ===\033[0m"
    local cookie_path="$BASE_DIR/cookies.txt"
    
    if [ -f "$cookie_path" ]; then
        echo -e "\033[1;32m[OK] File ditemukan!\033[0m"
        YT_COOKIE_OPT="--cookies $cookie_path"
        echo -e "\033[1;32m[SUCCESS] Cookie aktif!\033[0m"
    else
        echo -e "\033[1;31m[ERROR] File tidak ditemukan!\033[0m"
        echo "[INFO] Simpan cookies.txt ke: $cookie_path"
    fi
    log_activity "Cookie YouTube checked"
}

view_log() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "\033[1;33m=== LOG (20 terakhir) ===\033[0m"
        tail -20 "$LOG_FILE"
    else
        echo "[INFO] Belum ada log."
    fi
}

update_tools() {
    echo "[INFO] Memperbarui sistem..."
    
    case $PLATFORM in
        termux)
            pkg update -y && pkg upgrade -y
            pkg install -y ffmpeg wget python python-pip git nodejs
            ;;
        linux)
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y ffmpeg wget python3 python3-pip git nodejs
            ;;
        macos)
            brew update
            brew install ffmpeg wget python3 git node
            ;;
        *)
            echo "[WARNING] Platform tidak dikenali. Install manual."
            ;;
    esac
    
    pip3 install -U yt-dlp spotdl gallery-dl TeraboxDL
    
    echo ""
    echo -e "\033[1;33m=== STATUS ===\033[0m"
    for tool in ffmpeg wget $PYTHON_CMD; do
        command -v "$tool" >/dev/null 2>&1 && echo -e "  \033[1;32m[OK]\033[0m $tool" || echo -e "  \033[1;31m[MISSING]\033[0m $tool"
    done
    echo -e "\033[1;32m[SUCCESS] Selesai!\033[0m"
    log_activity "System update"
}

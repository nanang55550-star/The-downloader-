#!/bin/bash

# ============================================================
# UTILS.SH - FUNGSI UTILITAS
# ============================================================

setup_dirs() {
    if [ "$PLATFORM" == "termux" ] && [ ! -d "/sdcard/Download" ]; then
        echo "[!] Meminta izin akses storage..."
        termux-setup-storage
        sleep 3
    fi
    mkdir -p "$PHOTO_DIR" "$VIDEO_DIR" "$MUSIC_DIR" "$TERABOX_DIR" "$BATCH_DIR"
}

check_storage() {
    if [ "$PLATFORM" == "termux" ]; then
        AVAILABLE=$(df /sdcard | awk 'NR==2 {print $4}')
        if [ "$AVAILABLE" -lt 204800 ]; then
            echo -e "\033[1;31m[BAHAYA] Memori hampir penuh! Sisa kurang dari 200MB.\033[0m"
            pause_menu
            return 1
        fi
    fi
    return 0
}

validate_url() {
    local url="$1"
    if [[ -z "$url" ]]; then
        echo -e "\033[1;31m[ERROR] Link tidak boleh kosong!\033[0m"
        return 1
    fi
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo -e "\033[1;31m[ERROR] Link tidak valid!\033[0m"
        return 1
    fi
    return 0
}

log_activity() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$PLATFORM] $1" >> "$LOG_FILE"
}

pause_menu() {
    echo ""
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

notif_success() {
    local label="$1"
    local folder="$2"
    local filename="$3"

    if [ -n "$filename" ] && [ -f "$filename" ]; then
        SIZE=$(du -h "$filename" 2>/dev/null | cut -f1)
    else
        LATEST=$(ls -t "$folder" 2>/dev/null | head -1)
        if [ -n "$LATEST" ]; then
            SIZE=$(du -h "$folder/$LATEST" 2>/dev/null | cut -f1)
            filename="$LATEST"
        else
            SIZE="?"
        fi
    fi

    echo ""
    echo -e "\033[1;32m╔══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;32m║   ✓  DOWNLOAD SELESAI!               ║\033[0m"
    printf  "\033[1;32m║\033[0m  \033[1;33mJenis  :\033[0m %-28s\033[1;32m║\033[0m\n" "$label"
    printf  "\033[1;32m║\033[0m  \033[1;33mUkuran :\033[0m %-28s\033[1;32m║\033[0m\n" "$SIZE"
    printf  "\033[1;32m║\033[0m  \033[1;33mFolder :\033[0m %-28s\033[1;32m║\033[0m\n" "$(basename $folder)/"
    echo -e "\033[1;32m╚══════════════════════════════════════╝\033[0m"
}

notif_error() {
    local pesan="$1"
    echo ""
    echo -e "\033[1;31m╔══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;31m║   ✗  DOWNLOAD GAGAL!                 ║\033[0m"
    printf  "\033[1;31m║\033[0m  %-38s\033[1;31m║\033[0m\n" "$pesan"
    echo -e "\033[1;31m╚══════════════════════════════════════╝\033[0m"
}

header() {
    clear
    echo -e "\033[1;32m╔══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║   THE DOWNLOADER v62 - UNIVERSAL     ║\033[0m"
    echo -e "\033[1;36m║   Platform: $(echo $PLATFORM | tr '[:lower:]' '[:upper:]')                 ║\033[0m"
    echo -e "\033[1;32m╚══════════════════════════════════════╝\033[0m"
    echo -e "                                                 BY: NZR"
    
    if [ "$PLATFORM" == "termux" ]; then
        AVAIL_MB=$(df /sdcard | awk 'NR==2 {printf "%.0f", $4/1024}')
        echo -e "\033[0;37m  Storage: ${AVAIL_MB} MB\033[0m"
    fi
    
    if [ -n "$YT_COOKIE_OPT" ]; then
        echo -e "\033[0;32m  [Cookie YT: Aktif]\033[0m"
    else
        echo -e "\033[0;31m  [Cookie YT: Belum Set]\033[0m"
    fi
    echo ""
}

run_ytdlp() {
    $PYTHON_CMD -m yt_dlp \
        $YT_COOKIE_OPT \
        --progress \
        --newline \
        "$@"
}

media_scan() {
    if [ "$PLATFORM" == "termux" ] && command -v termux-media-scan >/dev/null 2>&1; then
        termux-media-scan -r "$1" 2>/dev/null
    fi
}

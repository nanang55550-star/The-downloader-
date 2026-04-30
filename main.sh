#!/bin/bash

# ============================================================
#       THE DOWNLOADER v62 - UNIVERSAL MODULAR
#       Entry Point
#       By NZR
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load modules
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/resolution.sh"
source "$SCRIPT_DIR/update.sh"
source "$SCRIPT_DIR/menus/video.sh"
source "$SCRIPT_DIR/menus/audio.sh"
source "$SCRIPT_DIR/menus/photo.sh"
source "$SCRIPT_DIR/menus/special.sh"
source "$SCRIPT_DIR/menus/system.sh"

# Init
detect_platform
setup_dirs

# Auto-check update (once per day)
if [ ! -f "/tmp/.last_update_check" ] || [ "$(find /tmp/.last_update_check -mtime +0 2>/dev/null)" ]; then
    check_update
    touch /tmp/.last_update_check
fi

# Main menu
show_menu() {
    header
    echo -e "\033[1;34m  === VIDEO ===\033[0m"
    echo "   2.  YouTube Video (Resolusi Real-Time)"
    echo "   3.  TikTok (No Watermark)"
    echo "   6.  BiliBili (Resolusi Real-Time)"
    echo "   7.  Instagram (Post/Reels/Story)"
    echo "   9.  Facebook Video (Resolusi Real-Time)"
    echo "   10. Twitter / X Video (Resolusi Real-Time)"
    echo "   20. Universal Video (Resolusi + Durasi)"
    echo ""
    echo -e "\033[1;34m  === AUDIO ===\033[0m"
    echo "   1.  Audio MP3 (YouTube/Music)"
    echo "   5.  Spotify Link (spotdl)"
    echo "   8.  CARI LAGU (Ketik Judul/Artis)"
    echo "   13. SoundCloud (Track/Playlist)"
    echo ""
    echo -e "\033[1;34m  === FOTO & GAMBAR ===\033[0m"
    echo "   4.  Foto (Gallery-DL - Resolusi Maks)"
    echo "   12. Gambar RAW/AI (Direct Link)"
    echo "   15. Pinterest (Board/Pin)"
    echo ""
    echo -e "\033[1;34m  === SPESIAL ===\033[0m"
    echo "   11. Terabox (Folder & File)"
    echo "   14. BATCH DOWNLOAD (Dari File .txt)"
    echo "   16. INFO Video (Cek resolusi tersedia)"
    echo ""
    echo -e "\033[1;34m  === SISTEM ===\033[0m"
    echo "   17. Set Cookie Terabox"
    echo "   18. Set Cookie YouTube"
    echo "   19. Lihat Log Aktivitas"
    echo "   98. FORCE UPDATE SKRIP"
    echo "   99. UPDATE / INSTALL SEMUA ALAT"
    echo "   0.  KELUAR"
    echo ""
    echo -e "\033[1;32m══════════════════════════════════════\033[0m"
}

# Main loop
while true; do
    show_menu
    read -p "Pilih menu (0-99): " menu
    echo ""

    case "$menu" in
        1)  download_audio ;;
        2)  download_youtube_video ;;
        3)  download_tiktok ;;
        4)  download_foto ;;
        5)  download_spotify ;;
        6)  download_bilibili ;;
        7)  download_instagram ;;
        8)  search_music ;;
        9)  download_facebook ;;
        10) download_twitter ;;
        11) download_terabox ;;
        12) download_raw_image ;;
        13) download_soundcloud ;;
        14) download_batch ;;
        15) download_pinterest ;;
        16) info_video ;;
        17) set_terabox_cookie ;;
        18) set_youtube_cookie ;;
        19) view_log ;;
        20) download_universal_video ;;
        98) force_update ;;
        99) update_tools ;;
        0)
            echo -e "\033[1;32mTerima kasih! Sampai jumpa.\033[0m"
            exit 0
            ;;
        *)
            echo -e "\033[1;31m[ERROR] Pilihan tidak valid!\033[0m"
            ;;
    esac

    pause_menu
done

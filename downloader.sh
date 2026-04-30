#!/bin/bash

# ============================================================
#       THE DOWNLOADER v62 - UNIVERSAL
#       Support: Termux / Linux / macOS / WSL
#       By NZR
# ============================================================

# --- DETEKSI PERANGKAT ---
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
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        PLATFORM="windows"
        BASE_DIR="$HOME/Downloads"
        PYTHON_CMD="python"
    else
        PLATFORM="unknown"
        BASE_DIR="$HOME/Downloads"
        PYTHON_CMD="python3"
    fi
    
    # Set direktori
    PHOTO_DIR="$BASE_DIR/Hasil-Gallery"
    VIDEO_DIR="$BASE_DIR/Hasil-Video"
    MUSIC_DIR="$BASE_DIR/Hasil-Musik"
    TERABOX_DIR="$BASE_DIR/Hasil-Terabox"
    BATCH_DIR="$BASE_DIR/Hasil-Batch"
}

# --- KONFIGURASI ---
COOKIE_FILE="$HOME/.terabox_cookie"
YT_COOKIE="$HOME/.youtube_cookies.txt"
LOG_FILE="$HOME/.downloader.log"

# Cek cookie YouTube
YT_COOKIE_OPT=""
if [ -f "$BASE_DIR/cookies.txt" ]; then
    YT_COOKIE_OPT="--cookies $BASE_DIR/cookies.txt"
elif [ -f "$YT_COOKIE" ]; then
    YT_COOKIE_OPT="--cookies $YT_COOKIE"
fi

# ============================================================
# FUNGSI UTILITAS
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

# ============================================================
# FUNGSI RESOLUSI REAL-TIME
# ============================================================

get_available_resolutions() {
    local link="$1"
    
    $PYTHON_CMD -m yt_dlp \
        $YT_COOKIE_OPT \
        --no-check-certificate \
        --print "%(formats.:)j" \
        "$link" 2>/dev/null | \
        $PYTHON_CMD -c "
import sys, json
try:
    data = json.load(sys.stdin)
    res_set = set()
    for fmt in data:
        if fmt.get('vcodec') != 'none' and fmt.get('height'):
            height = fmt['height']
            fps = fmt.get('fps', '')
            ext = fmt.get('ext', 'mp4')
            has_audio = fmt.get('acodec') != 'none'
            audio_note = ' + Audio' if has_audio else ' (Merge)'
            res_set.add((height, f'{height}p{f\"@{fps}fps\" if fps and fps > 30 else \"\"} [{ext.upper()}]{audio_note}'))
    for item in sorted(res_set, key=lambda x: x[0], reverse=True):
        print(item[1])
except:
    pass
"
}

select_resolution() {
    local link="$1"
    local menu_title="${2:-PILIH RESOLUSI}"
    
    echo ""
    echo -e "\033[1;33m--- $menu_title ---\033[0m"
    echo -e "\033[0;37mMengecek resolusi yang tersedia...\033[0m"
    echo ""
    
    local res_list=()
    local format_list=()
    local idx=1
    
    res_list[$idx]="Best Quality (Auto)"
    format_list[$idx]="bestvideo+bestaudio/best"
    echo -e " \033[1;36m[$idx]\033[0m Best Quality (Auto) \033[0;32m[Rekomendasi]\033[0m"
    idx=$((idx+1))
    
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        res_list[$idx]="$line"
        local height=$(echo "$line" | grep -oE "^[0-9]+" | head -1)
        if [ -n "$height" ]; then
            format_list[$idx]="bestvideo[height<=$height]+bestaudio/best[height<=$height]"
        else
            format_list[$idx]="best"
        fi
        echo -e " \033[1;36m[$idx]\033[0m $line"
        idx=$((idx+1))
    done < <(get_available_resolutions "$link")
    
    res_list[$idx]="Audio Only (MP3)"
    format_list[$idx]="AUDIO"
    echo -e " \033[1;36m[$idx]\033[0m Audio Only (MP3) \033[0;33m[Audio]\033[0m"
    
    echo ""
    read -p "Pilih resolusi (1-$idx): " res_pilih
    
    if [[ "$res_pilih" =~ ^[0-9]+$ ]] && [ "$res_pilih" -ge 1 ] && [ "$res_pilih" -le "$idx" ]; then
        SELECTED_RES="${format_list[$res_pilih]}"
        SELECTED_LABEL="${res_list[$res_pilih]}"
        return 0
    else
        echo -e "\033[1;31m[ERROR] Pilihan tidak valid! Menggunakan Best.\033[0m"
        SELECTED_RES="bestvideo+bestaudio/best"
        SELECTED_LABEL="Best Quality (Auto)"
        return 1
    fi
}

# ============================================================
# NOTIFIKASI
# ============================================================

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

# ============================================================
# HEADER & MENU
# ============================================================

header() {
    clear
    echo -e "\033[1;32m╔══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;33m║   THE DOWNLOADER v62 - UNIVERSAL     ║\033[0m"
    echo -e "\033[1;36m║   Platform: $(echo $PLATFORM | tr '[:lower:]' '[:upper:]')                 ║\033[0m"
    echo -e "\033[1;32m╚══════════════════════════════════════╝\033[0m"
    
    if [ "$PLATFORM" == "termux" ]; then
        AVAIL_MB=$(df /sdcard | awk 'NR==2 {printf "%.0f", $4/1024}')
        echo -e "\033[0;37m  Storage: ${AVAIL_MB} MB\033[0m"
    fi
    
    if [ -n "$YT_COOKIE_OPT" ]; then
        echo -e "\033[0;32m  [Cookie YT: ✓ Aktif]\033[0m"
    else
        echo -e "\033[0;31m  [Cookie YT: ✗ Belum Set]\033[0m"
    fi
    echo ""
}

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
    echo "   99. UPDATE / INSTALL SEMUA ALAT"
    echo "   0.  KELUAR"
    echo ""
    echo -e "\033[1;32m══════════════════════════════════════\033[0m"
}

# ============================================================
# FUNGSI DOWNLOAD
# ============================================================

run_ytdlp() {
    $PYTHON_CMD -m yt_dlp \
        $YT_COOKIE_OPT \
        --progress \
        --newline \
        "$@"
}

# Media scan (hanya Termux)
media_scan() {
    if [ "$PLATFORM" == "termux" ] && command -v termux-media-scan &>/dev/null; then
        termux-media-scan -r "$1" 2>/dev/null
    fi
}

# Menu 1 - Audio MP3
download_audio() {
    check_storage || return
    read -p "Masukkan Link YouTube/Music: " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;36m[INFO] Memulai unduhan audio MP3...\033[0m"

    run_ytdlp \
        --ignore-errors \
        --no-check-certificate \
        -x --audio-format mp3 --audio-quality 0 \
        --embed-thumbnail \
        --add-metadata \
        -o "$MUSIC_DIR/%(title)s.%(ext)s" "$link"

    if [ $? -eq 0 ]; then
        log_activity "Audio: $link"
        media_scan "$MUSIC_DIR"
        notif_success "Audio MP3" "$MUSIC_DIR"
    else
        notif_error "Coba ganti link atau cek koneksi"
    fi
}

# Menu 2 - YouTube Video (Resolusi Real-Time)
download_youtube_video() {
    check_storage || return
    read -p "Masukkan Link YouTube/Shorts: " link
    validate_url "$link" || return
    
    select_resolution "$link" "PILIH RESOLUSI YOUTUBE"
    
    if [ "$SELECTED_RES" = "AUDIO" ]; then
        download_audio_direct "$link" "YouTube"
        return
    fi
    
    echo ""
    echo -e "\033[1;36m[INFO] Memulai unduhan [$SELECTED_LABEL]...\033[0m"

    run_ytdlp \
        --ignore-errors \
        --no-check-certificate \
        -f "$SELECTED_RES" \
        --merge-output-format mp4 \
        -o "$VIDEO_DIR/%(title)s.%(ext)s" "$link"

    if [ $? -eq 0 ]; then
        log_activity "YouTube [$SELECTED_LABEL]: $link"
        media_scan "$VIDEO_DIR"
        notif_success "YouTube ($SELECTED_LABEL)" "$VIDEO_DIR"
    else
        notif_error "Gagal mengunduh video"
    fi
}

download_audio_direct() {
    local link="$1"
    local source="$2"
    echo ""
    echo -e "\033[1;36m[INFO] Memulai unduhan audio MP3...\033[0m"
    
    run_ytdlp \
        --ignore-errors \
        --no-check-certificate \
        -x --audio-format mp3 --audio-quality 0 \
        --embed-thumbnail \
        --add-metadata \
        -o "$MUSIC_DIR/%(title)s.%(ext)s" "$link"

    if [ $? -eq 0 ]; then
        log_activity "$source Audio: $link"
        media_scan "$MUSIC_DIR"
        notif_success "Audio MP3 ($source)" "$MUSIC_DIR"
    else
        notif_error "Gagal mengunduh audio"
    fi
}

# Menu 3 - TikTok
download_tiktok() {
    check_storage || return
    read -p "Masukkan Link TikTok: " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh TikTok tanpa watermark...\033[0m"

    run_ytdlp \
        --ignore-errors \
        --no-check-certificate \
        -o "$VIDEO_DIR/TikTok_%(uploader)s_%(id)s.%(ext)s" "$link"

    if [ $? -eq 0 ]; then
        log_activity "TikTok: $link"
        media_scan "$VIDEO_DIR"
        notif_success "TikTok Video" "$VIDEO_DIR"
    else
        notif_error "Gagal mengunduh TikTok"
    fi
}

# Menu 4 - Foto
download_foto() {
    check_storage || return
    read -p "Masukkan Link (Pinterest/IG/Twitter/dll): " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;36m[INFO] Mengekstrak foto resolusi asli...\033[0m"

    gallery-dl -d "$PHOTO_DIR" "$link"

    if [ $? -eq 0 ]; then
        find "$PHOTO_DIR" -mindepth 2 -type f -exec mv -t "$PHOTO_DIR" {} + 2>/dev/null
        find "$PHOTO_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null
        log_activity "Foto: $link"
        media_scan "$PHOTO_DIR"
        notif_success "Foto/Gambar" "$PHOTO_DIR"
    else
        notif_error "Gagal mengunduh foto"
    fi
}

# Menu 5 - Spotify
download_spotify() {
    check_storage || return
    read -p "Masukkan Link Spotify: " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh via spotdl...\033[0m"

    cd "$MUSIC_DIR" && spotdl "$link"

    if [ $? -eq 0 ]; then
        cd ~
        log_activity "Spotify: $link"
        media_scan "$MUSIC_DIR"
        notif_success "Spotify Audio" "$MUSIC_DIR"
    else
        cd ~
        notif_error "Gagal mengunduh Spotify"
    fi
}

# Menu 6 - BiliBili (Resolusi Real-Time)
download_bilibili() {
    check_storage || return
    read -p "Masukkan Link BiliBili: " link
    validate_url "$link" || return
    clean_link=$(echo "$link" | sed 's/\?.*//')
    
    select_resolution "$clean_link" "PILIH RESOLUSI BILIBILI"
    
    if [ "$SELECTED_RES" = "AUDIO" ]; then
        download_audio_direct "$clean_link" "BiliBili"
        return
    fi
    
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh BiliBili [$SELECTED_LABEL]...\033[0m"
    cd "$VIDEO_DIR"

    run_ytdlp \
        --no-check-certificate \
        -f "$SELECTED_RES" \
        --merge-output-format mp4 \
        -o "%(title)s.%(ext)s" "$clean_link"

    if [ $? -eq 0 ]; then
        cd ~
        log_activity "BiliBili [$SELECTED_LABEL]: $link"
        media_scan "$VIDEO_DIR"
        notif_success "BiliBili ($SELECTED_LABEL)" "$VIDEO_DIR"
    else
        cd ~
        notif_error "Gagal mengunduh BiliBili"
    fi
}

# Menu 7 - Instagram
download_instagram() {
    check_storage || return
    read -p "Masukkan Link Instagram: " link
    validate_url "$link" || return
    echo ""
    echo " 1. Foto/Carousel (gallery-dl)"
    echo " 2. Video/Reels   (yt-dlp)"
    echo " 3. Story         (gallery-dl)"
    read -p "Jenis konten (1-3): " ig_type

    case $ig_type in
        1|3)
            echo -e "\033[1;36m[INFO] Mengunduh foto/story...\033[0m"
            gallery-dl -d "$PHOTO_DIR" "$link"
            if [ $? -eq 0 ]; then
                find "$PHOTO_DIR" -mindepth 2 -type f -exec mv -t "$PHOTO_DIR" {} + 2>/dev/null
                find "$PHOTO_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null
                log_activity "Instagram Foto: $link"
                media_scan "$PHOTO_DIR"
                notif_success "Instagram Foto" "$PHOTO_DIR"
            else
                notif_error "Gagal mengunduh Instagram"
            fi
            ;;
        2)
            echo -e "\033[1;36m[INFO] Mengunduh video/reels...\033[0m"
            run_ytdlp \
                --ignore-errors \
                --no-check-certificate \
                -o "$VIDEO_DIR/IG_%(uploader)s_%(id)s.%(ext)s" "$link"
            if [ $? -eq 0 ]; then
                log_activity "Instagram Video: $link"
                media_scan "$VIDEO_DIR"
                notif_success "Instagram Video" "$VIDEO_DIR"
            else
                notif_error "Gagal mengunduh Instagram"
            fi
            ;;
        *)
            echo -e "\033[1;31m[ERROR] Pilihan tidak valid!\033[0m"
            ;;
    esac
}

# Menu 8 - Cari Lagu
search_music() {
    check_storage || return
    read -p "Masukkan Judul/Artis Lagu: " search
    if [[ -z "$search" ]]; then
        echo -e "\033[1;31m[ERROR] Kata pencarian kosong!\033[0m"
        return
    fi
    echo ""
    echo -e "\033[1;36m[INFO] Mencari: $search\033[0m"

    run_ytdlp \
        --ignore-errors \
        --no-check-certificate \
        -x --audio-format mp3 --audio-quality 0 \
        --embed-thumbnail \
        --default-search "ytsearch3:" \
        -o "$MUSIC_DIR/%(title)s.%(ext)s" "$search"

    if [ $? -eq 0 ]; then
        log_activity "Search Music: $search"
        media_scan "$MUSIC_DIR"
        notif_success "Cari Lagu" "$MUSIC_DIR"
    else
        notif_error "Tidak ditemukan / gagal"
    fi
}

# Menu 9 - Facebook (Resolusi Real-Time)
download_facebook() {
    check_storage || return
    read -p "Masukkan Link Facebook: " link
    validate_url "$link" || return
    
    select_resolution "$link" "PILIH RESOLUSI FACEBOOK"
    
    if [ "$SELECTED_RES" = "AUDIO" ]; then
        download_audio_direct "$link" "Facebook"
        return
    fi
    
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh video Facebook [$SELECTED_LABEL]...\033[0m"

    run_ytdlp \
        --no-check-certificate \
        -f "$SELECTED_RES" \
        -o "$VIDEO_DIR/FB_%(title)s.%(ext)s" "$link"

    if [ $? -eq 0 ]; then
        log_activity "Facebook [$SELECTED_LABEL]: $link"
        media_scan "$VIDEO_DIR"
        notif_success "Facebook ($SELECTED_LABEL)" "$VIDEO_DIR"
    else
        notif_error "Gagal mengunduh Facebook"
    fi
}

# Menu 10 - Twitter/X (Resolusi Real-Time)
download_twitter() {
    check_storage || return
    read -p "Masukkan Link X/Twitter: " link
    validate_url "$link" || return
    
    select_resolution "$link" "PILIH RESOLUSI TWITTER/X"
    
    if [ "$SELECTED_RES" = "AUDIO" ]; then
        download_audio_direct "$link" "Twitter/X"
        return
    fi
    
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh video Twitter/X [$SELECTED_LABEL]...\033[0m"

    run_ytdlp \
        --no-check-certificate \
        -f "$SELECTED_RES" \
        -o "$VIDEO_DIR/Twit_%(uploader)s_%(id)s.%(ext)s" "$link"

    if [ $? -eq 0 ]; then
        log_activity "Twitter [$SELECTED_LABEL]: $link"
        media_scan "$VIDEO_DIR"
        notif_success "Twitter/X ($SELECTED_LABEL)" "$VIDEO_DIR"
    else
        notif_error "Gagal mengunduh Twitter/X"
    fi
}

# Menu 11 - Terabox
download_terabox() {
    check_storage || return
    if [ ! -f "$COOKIE_FILE" ] || [ ! -s "$COOKIE_FILE" ]; then
        echo -e "\033[1;31m[ERROR] Cookie Terabox belum di-set!\033[0m"
        return
    fi

    $PYTHON_CMD - <<'PYEOF'
import sys, shutil, os

cookie_file = os.path.expanduser("~/.terabox_cookie")
terabox_dir = os.path.expanduser("~/Downloads/Hasil-Terabox")
if os.path.exists("/sdcard/Download"):
    terabox_dir = "/sdcard/Download/Hasil-Terabox"

try:
    from TeraboxDL import TeraboxDL
except ImportError:
    print("[ERROR] TeraboxDL belum terinstall. Jalankan menu 99!")
    sys.exit(1)

total, used, free = shutil.disk_usage('/sdcard' if os.path.exists('/sdcard') else '/')
if free < 200 * 1024 * 1024:
    print('[STOP] Memori hampir penuh!')
    sys.exit(1)

try:
    with open(cookie_file, 'r') as f:
        cookie = f.read().strip()
except:
    print("[ERROR] Gagal membaca cookie!")
    sys.exit(1)

link = input('Masukkan Link Terabox: ').strip()
if not link:
    print("[ERROR] Link kosong!")
    sys.exit(1)

try:
    client = TeraboxDL(cookie)
    result = client.get_file_info(link)
    items = result if isinstance(result, list) else [result]
    print(f"[INFO] Ditemukan {len(items)} item.")
    for item in items:
        fname = item.get('file_name', 'unknown')
        fsize = item.get('size', 0)
        print(f"  >> Mengunduh: {fname} ({fsize // 1024 // 1024} MB)")
        client.download(item, save_path=terabox_dir + '/')
    print("[SUCCESS] Semua file selesai diunduh!")
except Exception as e:
    print(f"[ERROR] {e}")
PYEOF
    log_activity "Terabox download"
}

# Menu 12 - RAW AI Image
download_raw_image() {
    check_storage || return
    echo -e "\033[1;33m=========================================\033[0m"
    echo " Gunakan 'Salin Alamat Gambar' dari browser"
    echo " Link harus berakhiran: .png .jpg .jpeg .webp .gif"
    echo -e "\033[1;33m=========================================\033[0m"
    read -p "Masukkan Direct Link: " link
    validate_url "$link" || return

    timestamp=$(date +%s)
    ext="png"
    if [[ "$link" =~ \.(jpg|jpeg|png|webp|gif)(\?.*)?$ ]]; then
        ext="${BASH_REMATCH[1]}"
    fi
    filename="AI_RAW_${timestamp}.${ext}"

    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh file asli...\033[0m"

    wget -q --show-progress \
        -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
        --timeout=30 \
        -O "$PHOTO_DIR/$filename" "$link"

    if [ $? -eq 0 ] && [ -s "$PHOTO_DIR/$filename" ]; then
        log_activity "RAW Image: $link"
        media_scan "$PHOTO_DIR"
        notif_success "Gambar RAW/AI" "$PHOTO_DIR" "$PHOTO_DIR/$filename"
    else
        rm -f "$PHOTO_DIR/$filename" 2>/dev/null
        notif_error "Link ditolak server atau tidak valid"
    fi
}

# Menu 13 - SoundCloud
download_soundcloud() {
    check_storage || return
    read -p "Masukkan Link SoundCloud: " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh dari SoundCloud...\033[0m"

    run_ytdlp \
        --ignore-errors \
        --no-check-certificate \
        -x --audio-format mp3 --audio-quality 0 \
        --embed-thumbnail \
        --add-metadata \
        -o "$MUSIC_DIR/SC_%(uploader)s_%(title)s.%(ext)s" "$link"

    if [ $? -eq 0 ]; then
        log_activity "SoundCloud: $link"
        media_scan "$MUSIC_DIR"
        notif_success "SoundCloud Audio" "$MUSIC_DIR"
    else
        notif_error "Gagal mengunduh SoundCloud"
    fi
}

# Menu 14 - Batch Download
download_batch() {
    check_storage || return
    echo -e "\033[1;33m=== BATCH DOWNLOAD ===\033[0m"
    read -p "Nama file .txt (di $BASE_DIR): " txtfile
    FULL_PATH="$BASE_DIR/$txtfile"

    if [ ! -f "$FULL_PATH" ]; then
        echo -e "\033[1;31m[ERROR] File tidak ditemukan!\033[0m"
        return
    fi

    TOTAL=$(grep -c "http" "$FULL_PATH" 2>/dev/null || echo 0)
    echo "[INFO] Ditemukan $TOTAL link."
    echo " 1. VIDEO  2. AUDIO  3. FOTO"
    read -p "Pilih mode (1-3): " mode

    case $mode in
        1)
            run_ytdlp --ignore-errors --no-check-certificate \
                -f "bestvideo[height<=720]+bestaudio/best[height<=720]" \
                --merge-output-format mp4 \
                -o "$BATCH_DIR/%(title)s.%(ext)s" -a "$FULL_PATH"
            ;;
        2)
            run_ytdlp --ignore-errors --no-check-certificate \
                -x --audio-format mp3 --audio-quality 0 \
                --embed-thumbnail \
                -o "$BATCH_DIR/%(title)s.%(ext)s" -a "$FULL_PATH"
            ;;
        3)
            COUNT=0
            while IFS= read -r url; do
                [[ "$url" =~ ^https?:// ]] || continue
                COUNT=$((COUNT+1))
                echo -e "\033[1;33m[$COUNT/$TOTAL] $url\033[0m"
                gallery-dl -d "$BATCH_DIR" "$url"
            done < "$FULL_PATH"
            ;;
        *)
            echo -e "\033[1;31m[ERROR] Pilihan tidak valid!\033[0m"
            return
            ;;
    esac

    log_activity "Batch: $FULL_PATH ($TOTAL)"
    media_scan "$BATCH_DIR"
    notif_success "Batch ($TOTAL link)" "$BATCH_DIR"
}

# Menu 15 - Pinterest
download_pinterest() {
    check_storage || return
    read -p "Masukkan Link Pinterest: " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh dari Pinterest...\033[0m"

    gallery-dl --directory "$PHOTO_DIR" --filename "Pinterest_{id}.{extension}" "$link"

    if [ $? -eq 0 ]; then
        find "$PHOTO_DIR" -mindepth 2 -type f -exec mv -t "$PHOTO_DIR" {} + 2>/dev/null
        find "$PHOTO_DIR" -mindepth 1 -type d -empty -delete 2>/dev/null
        log_activity "Pinterest: $link"
        media_scan "$PHOTO_DIR"
        notif_success "Pinterest Foto" "$PHOTO_DIR"
    else
        notif_error "Gagal mengunduh Pinterest"
    fi
}

# Menu 16 - Info Video
info_video() {
    read -p "Masukkan Link Video: " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;33m[INFO] Mengambil informasi video...\033[0m"
    
    $PYTHON_CMD -m yt_dlp \
        $YT_COOKIE_OPT \
        --no-check-certificate \
        --skip-download \
        --print "Judul   : %(title)s" \
        --print "Durasi  : %(duration_string)s" \
        --print "Channel : %(uploader)s" \
        "$link"
    
    echo ""
    echo -e "\033[1;33m[FORMAT TERSEDIA]\033[0m"
    $PYTHON_CMD -m yt_dlp \
        $YT_COOKIE_OPT \
        --no-check-certificate \
        --list-formats "$link"
}

# ============================================================
# MENU 20 - UNIVERSAL VIDEO
# ============================================================

download_universal_video() {
    check_storage || return
    
    read -p "Masukkan Link Video: " link
    validate_url "$link" || return
    
    echo ""
    echo -e "\033[1;33m[INFO] Mengecek info video...\033[0m"
    
    local video_title=$($PYTHON_CMD -m yt_dlp --no-check-certificate --skip-download --print "%(title)s" "$link" 2>/dev/null)
    local video_duration=$($PYTHON_CMD -m yt_dlp --no-check-certificate --skip-download --print "%(duration_string)s" "$link" 2>/dev/null)
    
    echo -e "\033[1;36m╔══════════════════════════════════════╗\033[0m"
    printf  "\033[1;36m║\033[0m  Judul  : %-28s\033[1;36m║\033[0m\n" "${video_title:-Unknown}"
    printf  "\033[1;36m║\033[0m  Durasi : %-28s\033[1;36m║\033[0m\n" "${video_duration:-Unknown}"
    echo -e "\033[1;36m╚══════════════════════════════════════╝\033[0m"
    echo ""
    
    select_resolution "$link" "PILIH RESOLUSI UNIVERSAL"
    
    if [ "$SELECTED_RES" = "AUDIO" ]; then
        echo ""
        echo -e "\033[1;36m[INFO] Memulai unduhan audio MP3...\033[0m"
        run_ytdlp --ignore-errors --no-check-certificate \
            -x --audio-format mp3 --audio-quality 0 \
            --embed-thumbnail --add-metadata \
            -o "$MUSIC_DIR/%(title)s.%(ext)s" "$link"
        
        if [ $? -eq 0 ]; then
            log_activity "Universal Audio: $link"
            media_scan "$MUSIC_DIR"
            notif_success "Universal Audio (MP3)" "$MUSIC_DIR"
        else
            notif_error "Gagal mengunduh audio"
        fi
        return
    fi
    
    echo ""
    echo -e "\033[1;33m[INFO] Resolusi: $SELECTED_LABEL\033[0m"
    
    # Durasi
    echo ""
    echo -e "\033[1;33m--- PILIH DURASI ---\033[0m"
    echo " Format: MM.SS (contoh: 00.59)"
    echo " Tekan [Enter] untuk full video"
    read -p "Durasi Awal [MM.SS]: " start_time
    
    local START_OPT=""
    if [ -n "$start_time" ]; then
        if [[ "$start_time" =~ ^[0-9]{1,2}\.[0-9]{2}$ ]]; then
            local min=$(echo "$start_time" | cut -d'.' -f1)
            local sec=$(echo "$start_time" | cut -d'.' -f2)
            START_OPT="--download-sections *${min}:${sec}-"
            echo -e "\033[0;32m[OK] Start: ${min}:${sec}\033[0m"
        else
            echo -e "\033[1;31m[WARNING] Format salah! Full video.\033[0m"
        fi
    fi
    
    echo ""
    read -p "Durasi Akhir [MM.SS]: " end_time
    
    local END_OPT=""
    if [ -n "$end_time" ]; then
        if [[ "$end_time" =~ ^[0-9]{1,2}\.[0-9]{2}$ ]]; then
            local min=$(echo "$end_time" | cut -d'.' -f1)
            local sec=$(echo "$end_time" | cut -d'.' -f2)
            END_OPT="${min}:${sec}"
            echo -e "\033[0;32m[OK] End: ${min}:${sec}\033[0m"
        fi
    fi
    
    # Gabungkan sections
    local SECTION_OPT=""
    if [ -n "$START_OPT" ] && [ -n "$END_OPT" ]; then
        local start_clean=$(echo "$START_OPT" | sed 's/--download-sections \*//; s/-$//')
        SECTION_OPT="--download-sections *${start_clean}-${END_OPT}"
    elif [ -n "$START_OPT" ]; then
        SECTION_OPT="$START_OPT"
    elif [ -n "$END_OPT" ]; then
        SECTION_OPT="--download-sections *0:00-${END_OPT}"
    fi
    
    echo ""
    echo -e "\033[1;36m[INFO] Memulai unduhan...\033[0m"
    
    if [ -n "$SECTION_OPT" ]; then
        echo -e "\033[0;37m[MODE] Trim video\033[0m"
        run_ytdlp --ignore-errors --no-check-certificate \
            -f "$SELECTED_RES" \
            $SECTION_OPT \
            --force-keyframes-at-cuts \
            --merge-output-format mp4 \
            -o "$VIDEO_DIR/%(title)s_[%(section_start)s-%(section_end)s].%(ext)s" \
            "$link"
    else
        echo -e "\033[0;37m[MODE] Full video\033[0m"
        run_ytdlp --ignore-errors --no-check-certificate \
            -f "$SELECTED_RES" \
            --merge-output-format mp4 \
            -o "$VIDEO_DIR/%(title)s.%(ext)s" \
            "$link"
    fi
    
    if [ $? -eq 0 ]; then
        log_activity "Universal [$SELECTED_LABEL]: $link"
        media_scan "$VIDEO_DIR"
        notif_success "Universal ($SELECTED_LABEL)" "$VIDEO_DIR"
    else
        notif_error "Gagal mengunduh"
    fi
}

# Menu 17 - Set Cookie Terabox
set_terabox_cookie() {
    echo -e "\033[1;33m=== SET COOKIE TERABOX ===\033[0m"
    read -p "Paste cookie: " cookie_val
    [ -z "$cookie_val" ] && return
    echo "$cookie_val" > "$COOKIE_FILE"
    chmod 600 "$COOKIE_FILE"
    echo -e "\033[1;32m[SUCCESS] Cookie tersimpan!\033[0m"
    log_activity "Cookie Terabox updated"
}

# Menu 18 - Set Cookie YouTube
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

# Menu 19 - Lihat Log
view_log() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "\033[1;33m=== LOG (20 terakhir) ===\033[0m"
        tail -20 "$LOG_FILE"
    else
        echo "[INFO] Belum ada log."
    fi
}

# Menu 99 - Update & Install
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
        command -v "$tool" &>/dev/null && echo -e "  \033[1;32m[OK]\033[0m $tool" || echo -e "  \033[1;31m[MISSING]\033[0m $tool"
    done
    echo -e "\033[1;32m[SUCCESS] Selesai!\033[0m"
    log_activity "System update"
}

# ============================================================
# MAIN LOOP
# ============================================================

detect_platform
setup_dirs

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

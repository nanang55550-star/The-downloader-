#!/bin/bash

# ============================================================
# MENUS/SPECIAL.SH - MENU SPESIAL
# ============================================================

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

#!/bin/bash

# ============================================================
# MENUS/PHOTO.SH - MENU FOTO & GAMBAR
# ============================================================

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

download_pinterest() {
    check_storage || return
    read -p "Masukkan Link Pinterest: " link
    validate_url "$link" || return
    echo ""
    echo -e "\033[1;36m[INFO] Mengunduh dari Pinterest...\033[0m"

    gallery-dl \
        --directory "$PHOTO_DIR" \
        --filename "Pinterest_{id}.{extension}" \
        "$link"

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

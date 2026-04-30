#!/bin/bash

# ============================================================
# MENUS/AUDIO.SH - MENU AUDIO
# ============================================================

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

#!/bin/bash

# ============================================================
# MENUS/VIDEO.SH - MENU VIDEO
# ============================================================

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

    if command -v bilibili-dl >/dev/null 2>&1; then
        bilibili-dl "$clean_link"
    else
        run_ytdlp \
            --no-check-certificate \
            -f "$SELECTED_RES" \
            --merge-output-format mp4 \
            -o "%(title)s.%(ext)s" "$clean_link"
    fi

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

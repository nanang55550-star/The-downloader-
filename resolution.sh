#!/bin/bash

# ============================================================
# RESOLUTION.SH - RESOLUSI REAL-TIME
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

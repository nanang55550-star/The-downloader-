#!/bin/bash

# ============================================================
# UPDATE.SH - AUTO UPDATE DARI GITHUB
# ============================================================

check_update() {
    echo -e "\033[1;33m[*] Mengecek update...\033[0m"
    
    local tmp_file="/tmp/downloader_latest.sh"
    
    if command -v curl >/dev/null 2>&1; then
        curl -sL "$REPO_URL/main.sh" -o "$tmp_file" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/main.sh" -O "$tmp_file" 2>/dev/null
    else
        echo -e "\033[1;31m[!] curl/wget tidak tersedia\033[0m"
        return 1
    fi
    
    if [ ! -f "$tmp_file" ] || [ ! -s "$tmp_file" ]; then
        echo -e "\033[1;31m[!] Gagal cek update\033[0m"
        rm -f "$tmp_file"
        return 1
    fi
    
    local latest_ver=$(grep -o "v[0-9]\+" "$tmp_file" | head -1)
    local current_ver=$(grep -o "v[0-9]\+" "$0" | head -1)
    
    if [ "$latest_ver" != "$current_ver" ]; then
        echo ""
        echo -e "\033[1;32m╔══════════════════════════════════════╗\033[0m"
        echo -e "\033[1;32m║   UPDATE TERSEDIA!                   ║\033[0m"
        printf  "\033[1;32m║\033[0m  Versi lama: %-23s\033[1;32m║\033[0m\n" "$current_ver"
        printf  "\033[1;32m║\033[0m  Versi baru: %-23s\033[1;32m║\033[0m\n" "$latest_ver"
        echo -e "\033[1;32m╚══════════════════════════════════════╝\033[0m"
        echo ""
        read -p "Update sekarang? [Y/n]: " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]] || [ -z "$confirm" ]; then
            cp "$0" "${0}.backup"
            mv "$tmp_file" "$0"
            chmod +x "$0"
            echo -e "\033[1;32m[✓] Update berhasil! Restart...\033[0m"
            sleep 2
            exec bash "$0"
        else
            echo -e "\033[0;33m[*] Update dibatalkan\033[0m"
            rm -f "$tmp_file"
        fi
    else
        echo -e "\033[0;32m[✓] Sudah versi terbaru ($current_ver)\033[0m"
        rm -f "$tmp_file"
    fi
}

force_update() {
    echo -e "\033[1;33m=== FORCE UPDATE ===\033[0m"
    echo "[INFO] Mendownload versi terbaru..."
    
    local new_file="/tmp/downloader_new.sh"
    
    if command -v curl >/dev/null 2>&1; then
        curl -sL "$REPO_URL/main.sh" -o "$new_file"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$REPO_URL/main.sh" -O "$new_file"
    else
        notif_error "curl/wget tidak tersedia"
        return 1
    fi
    
    if [ -f "$new_file" ] && [ -s "$new_file" ]; then
        cp "$0" "${0}.backup.$(date +%s)"
        mv "$new_file" "$0"
        chmod +x "$0"
        echo -e "\033[1;32m[✓] Update berhasil! Restart...\033[0m"
        sleep 2
        exec bash "$0"
    else
        notif_error "Gagal download update"
        rm -f "$new_file"
    fi
}

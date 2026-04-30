#!/bin/bash

echo "[*] The Downloader Installer v62 (Modular)"

if [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    PLATFORM="unknown"
fi

echo "[*] Platform: $PLATFORM"

case $PLATFORM in
    termux)
        pkg update -y && pkg upgrade -y
        pkg install -y ffmpeg wget python python-pip git nodejs
        termux-setup-storage
        ;;
    linux)
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y ffmpeg wget python3 python3-pip git nodejs
        ;;
    macos)
        if ! command -v brew >/dev/null 2>&1; then
            echo "[!] Install Homebrew first: https://brew.sh"
            exit 1
        fi
        brew update
        brew install ffmpeg wget python3 git node
        ;;
    *)
        echo "[!] Platform not recognized. Install manually:"
        echo "    ffmpeg, wget, python3, git"
        ;;
esac

pip3 install -U yt-dlp spotdl gallery-dl TeraboxDL

mkdir -p ~/Downloads/Hasil-Video
mkdir -p ~/Downloads/Hasil-Musik
mkdir -p ~/Downloads/Hasil-Gallery
mkdir -p ~/Downloads/Hasil-Terabox
mkdir -p ~/Downloads/Hasil-Batch

chmod +x main.sh
chmod +x menus/*.sh

echo "[OK] Done! Run: bash main.sh"

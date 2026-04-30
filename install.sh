
```bash
#!/bin/bash

echo "[*] The Downloader Installer v62"

# Detect platform
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

# Install based on platform
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
        if ! command -v brew &>/dev/null; then
            echo "[!] Install Homebrew first: https://brew.sh"
            exit 1
        fi
        brew update
        brew install ffmpeg wget python3 git node
        ;;
    *)
        echo "[!] Install manually: ffmpeg, wget, python3, git"
        ;;
esac

# Install Python packages
pip3 install -U yt-dlp spotdl gallery-dl TeraboxDL

# Create directories
mkdir -p ~/Downloads/Hasil-{Video,Musik,Gallery,Terabox,Batch}

chmod +x downloader.sh

echo "[✓] Done! Run: bash downloader.sh"

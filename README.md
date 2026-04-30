# The-downloader-
All-in-one media downloader for Termux Android.  Supports 20+ platforms with real-time resolution  detection and duration trimming.
## ⚠️ Disclaimer
This tool is for **educational and personal use only**. 
Users are responsible for complying with the Terms of Service 
of respective platforms (YouTube, TikTok, Instagram, etc.).

## Features
- Real-time resolution detection
- Duration trimming (start/end time)
- 20+ supported platforms
- Batch download from .txt file
- Cookie support for YouTube & Terabox

## Requirements
- Termux (from F-Droid)
- Python 3, FFmpeg, yt-dlp, gallery-dl, spotdl

## Install
```bash
pkg update && pkg install -y git wget
git clone https://github.com/nanang55550-star/The-downloader-.git
cd The-downloader-
bash downloader.sh

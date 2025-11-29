#!/bin/bash

domain=""
outfile=""
param_mode="false"
live_mode="false"

# -------------------------------
# ARG PARSER
# -------------------------------
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--output)
            outfile="$2"
            shift
            ;;
        --params)
            param_mode="true"
            ;;
        --live)
            live_mode="true"
            ;;
        *)
            domain="$1"
            ;;
    esac
    shift
done

if [ -z "$domain" ]; then
    echo "Usage: ./ultimate_url_finder.sh <domain> [-o file] [--params] [--live]"
    exit 1
fi

# Default output file
if [ -z "$outfile" ]; then
    outfile="urls_$domain.txt"
fi

output_dir="output_$domain"
mkdir -p $output_dir

echo "[*] Domain: $domain"
echo "[*] Output Folder: $output_dir"
echo "[*] Output File: $outfile"

# -------------------------------
# RUN ALL URL TOOLS
# -------------------------------

if command -v waybackurls &>/dev/null; then
    echo "[+] waybackurls..."
    echo "$domain" | waybackurls > $output_dir/wayback.txt
fi

if command -v gau &>/dev/null; then
    echo "[+] gau..."
    echo "$domain" | gau > $output_dir/gau.txt
fi

if command -v gauplus &>/dev/null; then
    echo "[+] gauplus..."
    echo "$domain" | gauplus > $output_dir/gauplus.txt
fi

if command -v katana &>/dev/null; then
    echo "[+] katana..."
    katana -u "https://$domain" -silent > $output_dir/katana.txt
fi

# ---- FIXED: hakrawler se -plain hata diya (error nahi aayega) ---
if command -v hakrawler &>/dev/null; then
    echo "[+] hakrawler..."
    echo "https://$domain" | hakrawler > $output_dir/hakrawler.txt
fi

# ParamSpider
if [ -d "ParamSpider" ]; then
    echo "[+] ParamSpider..."
    python3 ParamSpider/paramspider.py \
        --domain "$domain" \
        --exclude woff,css,js,png,jpg,gif \
        --output $output_dir/paramspider.txt
fi


# -------------------------------
# MERGE ALL URL FILES
# -------------------------------
echo "[*] Combining all URLs..."
cat $output_dir/*.txt 2>/dev/null | sort -u > $output_dir/all_urls_raw.txt


# -------------------------------
# PARAM MODE
# -------------------------------
if [ "$param_mode" == "true" ]; then
    echo "[*] Extracting only parameter URLs..."
    grep "?" $output_dir/all_urls_raw.txt | sort -u > $output_dir/params_only.txt

    if [ "$live_mode" == "true" ]; then
        echo "[*] LIVE check for parameter URLs..."
        cat $output_dir/params_only.txt | httpx -silent > "$outfile"
    else
        cp $output_dir/params_only.txt "$outfile"
    fi

    echo ""
    echo "======== PARAM MODE DONE ========"
    echo "Saved to: $outfile"
    echo "================================="
    exit 0
fi


# -------------------------------
# NORMAL MODE (ALL URLS)
# -------------------------------
if [ "$live_mode" == "true" ]; then
    echo "[*] LIVE scan enabled..."
    cat $output_dir/all_urls_raw.txt | httpx-toolkit > "$outfile"
else
    cp $output_dir/all_urls_raw.txt "$outfile"
fi

echo ""
echo "======== SCAN COMPLETE ========="
echo "Saved to: $outfile"
echo "================================"





















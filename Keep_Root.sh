#!/bin/bash
set -euo pipefail
Y="\033[1;33m"
G="\033[1;32m"
R="\033[1;31m"
NC="\033[0m"
APATCH_REPO="bmax121/APatch"
MAGISK_REPO="topjohnwu/Magisk"
tmp_dir="$HOME/tmp"
log_file="$tmp_dir/keep_root_logs.txt"
mkdir -p "$tmp_dir" "$tmp_dir/temp"
chmod -R 755 "$tmp_dir/temp"

echo -e "${G}Starting Root process...${NC}"

download() {
  local repo=$1
  local url="https://api.github.com/repos/$repo/releases/latest"
  echo -e "${G}Downloading the latest release from $repo...${NC}"
  local download_url=$(curl -s "$url" | grep -oP '"browser_download_url": "\K(.*?)(?=")')
  [ -z "$download_url" ] || { echo \"Failed to create download url, please provide correct repository address.\"; exit 1; }
  curl -L -o "$tmp_dir/temp/latest.zip" "$download_url"
  echo -e "Successful"
}

setup() {
  echo -e "${G}Setting up environment...${NC}"
  cd "$tmp_dir/temp"
  unzip -q latest.zip
  cd $tmp_dir/temp/lib/arm64-v8a
  for f in *.so; do mv -- "$f" "${f#lib}"; done
  find -type f -name '*.so' | while read f; do mv "$f" "${f%.so}"; done
  cd $HOME
  mv $tmp_dir/temp/lib/arm64-v8a/* $tmp_dir
  cp -r $tmp_dir/temp/assets/* $tmp_dir || { echo \"Failed to setup environment.\"; exit 1; }
  echo -e "Successful"
}

echo -e "${Y}Enter the number corresponding to the root method you want to use:${NC}"
echo -e "${G}1. OTA Update with Magisk${NC}"
echo -e "${G}2. Update Magisk${NC}"
echo -e "${G}3. OTA Update with APatch${NC}"
echo -e "${G}4. Update APatch${NC}"
echo -e "${G}5. OTA Update with Other Magisk Variants(Type GitHub Repo name i.e. magisk is topjohnwu/Magisk)${NC}"
echo -e "${G}6. Update Other Magisk Variants${NC}"
echo -e "${G}7. Skip for now${NC}"

read -p "Selection: " user_choice

case $user_choice in
  1|2) download "$MAGISK_REPO";;
  3|4) download "$APATCH_REPO";;
  5|6) read -p "Enter the full GitHub repository path (e.g., 'username/repo'): " repo
     download "$repo";;
  7) echo -e "${Y}Skipping root process and clearing temporary files....${NC}"; rm -rf "$tmp_dir"; exit 0;;
  *) echo -e "${R}Invalid option. Please choose correct option...${NC}" ;;
esac

setup

if [ "$user_choice" = "1" ] || [ "$user_choice" = "2" ] || [ "$user_choice" = "5" ] || [ "$user_choice" = "6" ]; then
    sed -i 's/KEEPFORCEENCRYPT=false/KEEPFORCEENCRYPT=true/g; s/KEEPVERITY=false/KEEPVERITY=true/g' "$tmp_dir/boot_patch.sh"
fi

perform_root() {
  local superkey=""
  
  [ "$user_choice" = "3" ] || [ "$user_choice" = "4" ] && {
    echo -e "${Y}Enter your superkey for rooting with APatch:${NC}"
    read -p "Superkey: " superkey
  }

  su -c "
    local active_slot=\$(getprop ro.boot.slot_suffix)
    local inactive_slot=\$( [ \"\$active_slot\" = \"_a\" ] && echo \"_b\" || echo \"_a\" )
    local boot_slot=\$( [ \"$user_choice\" = \"1\" ] || [ \"$user_choice\" = \"3\" ] || [ \"$user_choice\" = \"5\" ] && echo \"\$inactive_slot\" || echo \"\$active_slot\" )
    local boot=\$(find /dev/block -type l -name \"boot\$boot_slot\" -print | head -n 1)
    
    echo \"Extracting boot image from \$boot...\"
    if [ -n \"\$boot\" ]; then
      dd if=\"\$boot\" of=\"$tmp_dir/boot.img\" || { echo \"Failed to extract boot image.\"; exit 1; }
    fi

    cd $tmp_dir && chmod -R 755 $tmp_dir
    echo -e \"${G}Patching boot image...${NC}\"
    if [ \"$user_choice\" = \"3\" ] || [ \"$user_choice\" = \"4\" ]; then
      \"$tmp_dir/boot_patch.sh\" \"$superkey\" \"$tmp_dir/boot.img\" || { echo \"Failed to patch boot image using APatch.\"; exit 1; }
    else
      \"$tmp_dir/boot_patch.sh\" \"$tmp_dir/boot.img\" || { echo \"Failed to patch boot image using Magisk.\"; exit 1; }
    fi

    echo \"${G}Flashing patched boot image to \$boot...${NC}\"
    dd if=\"$tmp_dir/new-boot.img\" of=\"\$boot\" || { echo \"Failed to flash patched boot image.\"; exit 1; }
  "
}

perform_root

#rm -rf "$tmp_dir"
cp "$log_file" "/storage/emulated/0/"
echo -e "${G}Successful! Your root is retained you can reboot your device now.${NC}"

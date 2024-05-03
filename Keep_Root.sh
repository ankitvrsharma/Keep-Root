#!/bin/bash

Y="\033[1;33m"
G="\033[1;32m"
R="\033[1;31m"
NC="\033[0m"

MAGISK_REPO="topjohnwu/Magisk"
APATCH_REPO="bmax121/APatch"

tmp_dir="$HOME/tmp"
mkdir -p "$tmp_dir" "$tmp_dir/temp"
chmod 755 "$tmp_dir/temp" || { echo -e "${R}Failed to set permissions for tmp directory.${NC}"; exit 1; }

download() {
  local repo=$1
  local url="https://api.github.com/repos/$repo/releases/latest"
  echo -e "${G}Downloading the latest release from $repo...${NC}"
  
  local download_url=$(curl -s "$url" | grep -oP '"browser_download_url": "\K(.*?)(?=")')
  if [ -z "$download_url" ]; then
    echo -e "${R}Download URL not found.${NC}"
    rm -rf $tmp_dir
    exit 1
  fi
  
  curl -L -o "$tmp_dir/temp/latest.zip" "$download_url" || {
    echo -e "${R}Failed to download the file.${NC}"
    rm -rf $tmp_dir
    exit 1
  }
}

setup() {
  echo -e "${G}Setting up environment...${NC}"
  cd "$tmp_dir/temp" || exit 1
  unzip -q latest.zip || { echo -e "${R}Failed to unzip the file.${NC}"; rm -rf $tmp_dir; exit 1; }
  cd $tmp_dir/temp/lib/arm64-v8a
  for f in *.so; do mv -- "$f" "${f#lib}"; done
  find -type f -name '*.so' | while read f; do mv "$f" "${f%.so}"; done
  cd $home
  mv $tmp_dir/temp/lib/arm64-v8a/* $tmp_dir
  cp -r $tmp_dir/temp/assets/* $tmp_dir
  sed -i '72,73s/false/true/g' "$tmp_dir/boot_patch.sh"
}

echo -e "${Y}Enter the number corresponding to the root method you want to use:${NC}"
echo -e "${G}1. Magisk${NC}"
echo -e "${G}2. APatch${NC}"
echo -e "${G}3. Other (Type GitHub Repo name i.e. magisk is topjohnwu/Magisk)${NC}"
echo -e "${G}4. Skip for now${NC}"

read -p "Selection: " user_choice

case $user_choice in
  1) download "$MAGISK_REPO";;
  2) download "$APATCH_REPO";;
  3) read -p "Enter the full GitHub repository path (e.g., 'username/repo'): " repo
     download "$repo";;
  4) echo -e "${Y}Skipping...${NC}"; rm -rf "$tmp_dir"; exit 0;;
  *) echo -e "${R}Invalid option. Exiting...${NC}"; rm -rf $tmp_dir; exit 1;;
esac

setup

su -c '
# Define colors for echo
Y="\033[1;33m"
G="\033[1;32m"
R="\033[1;31m"
NC="\033[0m" # No Color
tmp_dir="/data/data/com.termux/files/home/tmp"
chmod 755 -R "$tmp_dir"

cleanup() {
  echo -e "${Y}Cleaning up temporary files...${NC}"
  rm -rf "$tmp_dir"
  echo -e "${G}Cleanup complete.${NC}"
}

check_error() {
  if [ $? -ne 0 ]; then
    echo -e "${R}An error occurred. Exiting...${NC}"
    cleanup
    exit 1
  fi
}

root() {
  local choice=$1
  local active_slot=$(getprop ro.boot.slot_suffix)
  local inactive_slot=$([[ "$active_slot" == "_a" ]] && echo "_b" || echo "_a")
  local boot=$(find /dev/block -type l -name "boot$inactive_slot" -print | head -n 1)
  
  echo "Extracting boot image from $boot..."
  if [ -n "$boot" ]; then
    dd if="$boot" of="$tmp_dir/boot.img" || return 1
  else
    echo "Boot partition not found."
    return 1
  fi
  
  echo -e "${G}Patching boot image...${NC}"
  "$tmp_dir/boot_patch.sh" "$tmp_dir/boot.img" || return 1
  
  echo "${G}Flashing patched boot image to $boot...${NC}"
  dd if="$tmp_dir/new-boot.img" of="$boot" || return 1
}

echo -e "${Y}Select what do you want to do:${NC}"
options=("OTA Update" "Update root" "Skip for now")
select opt in "${options[@]}"; do
  case $REPLY in
    1|2)
      root $REPLY 
      check_error
      break
      ;;
    3)
      echo -e "${Y}Rooting aborted. You can try later.${NC}"
      cleanup
      exit 0
      ;;
    *)
      echo -e "${R}Invalid option. Try again.${NC}"
      ;;
  esac
done
'

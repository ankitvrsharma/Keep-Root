#!/bin/bash
set -euo pipefail


echo -e "\033[1;33mKeep Root\033[0m"
# Set up environment 
echo -e "\033[1;32mDownloading latest Magisk....\033[0m"

mkdir tmp tmp1 && cd "$HOME/tmp1" && chmod 755 "$HOME/tmp1" || exit 1

latest_release=$(curl -s https://api.github.com/repos/topjohnwu/Magisk/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
curl -L -o "magisk.zip" "https://github.com/topjohnwu/Magisk/releases/download/$latest_release/Magisk-$latest_release.apk"

unzip -q ~/tmp1/magisk.zip || exit 1

cd ~/tmp1/lib/arm64-v8a
for f in *.so; do mv -- "$f" "${f#lib}"; done
find -type f -name '*.so' | while read f; do mv "$f" "${f%.so}"; done

cd ~/
mv ~/tmp1/lib/arm64-v8a/* ~/tmp
cp -r ~/tmp1/assets/* ~/tmp && rm -rf ~/tmp1

sed -i '72,73s/false/true/g' ~/tmp/boot_patch.sh || exit 1

echo "successful"
wait

  # Find boot image paths
  
  sleep 1
  su -c '
    Y="\033[1;33m"
    G="\033[1;32m"
    R="\033[1;31m"
    NC="\033[0m" # No Color
    tmp_dir="/data/data/com.termux/files/home/tmp"
 
 echo "${G}Extracting Boot...${NC}"
 
 check_dir() {
  if [ ! -d "$1" ]; then
  echo -e "${R}Directory $1 does not exist. Aborting script...${NC}"
  exit 1
  fi
  }
  check_dir "$tmp_dir"

 check_success() {
  if [ $? -ne 0 ]; then
  echo -e "${R}Previous command failed. Exiting...${NC}"
  exit 1
  fi
  }

    boot_a=$(find /dev/block -type l -name boot_a -print | head -n 1)
    boot_b=$(find /dev/block -type l -name boot_b -print | head -n 1)
    active_slot=$(getprop ro.boot.slot_suffix) && check_success
    echo "successful"
    
 extract_inactive() {
  if [[ "$active_slot" == "_a" ]]; then
  dd if="$boot_b" of="$tmp_dir/boot.img" &>keep_root_error.txt
  else
  dd if="$boot_a" of="$tmp_dir/boot.img" &>keep_root_error.txt
  fi
  }
            
 extract_active() {
  if [[ "$active_slot" == "_a" ]]; then
  dd if="$boot_a" of="$tmp_dir/boot.img" &>keep_root_error.txt
  else
  dd if="$boot_b" of="$tmp_dir/boot.img" &>keep_root_error.txt
  fi
  }
  	  
 patch_magisk() {
  chmod -R 755 $tmp_dir 
  echo -e "${G}Patching boot.img with latest Magisk.....${NC}"
  $tmp_dir/boot_patch.sh boot.img &>keep_root_error.txt || exit 1
  wait
  echo "successful"
  }
    
 verify_patch() {  
  if [ ! -f "$tmp_dir/new-boot.img" ]; then
  echo -e "${R}Error: Patched boot image file not found. Aborting.${NC}"
  exit 1
  fi
  }
     
 flash_active() {
  if [[ "$active_slot" == "_a" ]]; then
  dd if="$tmp_dir/new-boot.img" of="$boot_a" &>keep_root_error.txt
  else
  dd if="$tmp_dir/new-boot.img" of="$boot_b" &>keep_root_error.txt
  fi	
  }
      
 flash_inactive() {
  if [[ "$active_slot" == "_a" ]]; then
  dd if="$tmp_dir/new-boot.img" of="$boot_b" &>keep_root_error.txt
  else
  dd if="$tmp_dir/new-boot.img" of="$boot_a" &>keep_root_error.txt
  fi	
  }
   
 while true; do
    echo -e "${Y}What do you want to do:${NC}"
    echo "1. OTA update"
    echo "2. Magisk update"
    echo "3. Skip for now"
    read -r user_choice

 case "$user_choice" in
  1)
    extract_inactive && check_success
    ls $tmp_dir &>keep_root_error.txt
    patch_magisk && check_success
    verify_patch
    echo -e "${G}Flashing Magisk patched Boot....${NC}"
    sleep 3
    echo "successful"
    flash_inactive && check_success
    echo "${G}Clearing temporary files...${NC}"
    sleep 3
    echo "successful"
    echo "${G}Magisk installation is successful. Reboot your phone to apply the changes.${NC}"
    break
    ;;
  2)
    extract_active && check_success
    ls $tmp_dir > /dev/null 2>&1
    patch_magisk && check_success
    verify_patch
    echo -e "${G}Flashing Magisk patched Boot...${NC}"
    sleep 3
    echo "successful"
    flash_active && check_success
    echo "${G}Clearing temporary files...${NC}"
    sleep 3
    echo "successful"
    echo "${G}Magisk installation is successful. Reboot your phone to apply the changes.${NC}"
    break
    ;;
  3)
    echo -e "${G}Script execution skipped. You can flash it later.${NC}" && rm -rf $tmp_dir
    exit 0
    ;;
  *)
    echo -e "${R}Invalid choice. Please select 1, 2, or 3.${NC}"
    ;;
 esac
done
rm -rf /data/data/com.termux/files/home/tmp
rm -rf /data/data/com.termux/files/home/keep_root.sh
  '

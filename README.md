# Keep-Root
Specifically for Realme 11 Pro Series phones but theoretically can work with any A/B partition devices.
It can retain root in the following conditions:-
1. Updating OTA
2. Flashing custom recoveries ie TWRP
3. Update Magisk to newer version.
4. Changing root system from magisk to other magisk variants, to APatch or vice versa.

It's only need termux.

• It's noob friendly.

• No need to download region specific firmware. 

• No PC needed.

• In future will keep root after TWRP flashing.

Prerequisites:-
1. Rooted phone.
2. Automatic System Updates off in developer options.
3. For OTA root option:- First download the OTA and reboot your device, then execute command.
```
curl -fsSL https://raw.githubusercontent.com/ankitvrsharma/Keep-Root/main/Keep_Root.sh -o Keep_Root.sh && chmod +x Keep_Root.sh && ./Keep_Root.sh
```

Instructions for use:-

Copy and paste the code in Termux and follow on screen prompt simple.

By - @ankitvrsharma

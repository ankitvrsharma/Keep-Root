markdown
# Keep Root

## Introduction
Keep Root is a specialized script designed for Realme 11 Pro Series phones, though it is theoretically compatible with any A/B partition devices. It enables users to retain root access under various scenarios, including OTA updates, flashing custom recoveries, and updating or changing root systems. It supports Magisk, APatch or any other magisk variants.

## Prerequisites
- A rooted device with A/B partition layout
- Termux application installed
- Disabled automatic system updates in developer options

# Features
- **Automated Download**: Fetch the latest releases of Magisk or APatch directly from their official GitHub repositories.
- **Root Methods Selection**: Choose from various root methods including OTA updates with Magisk, APatch, or other Magisk variants.
- **Boot Image Handling**: Extract and flash either the active or inactive boot image automatically.

## Installation
Execute the following command in Termux to use Keep Root:
```
bash curl -fsSL https://raw.githubusercontent.com/ankitvrsharma/Keep-Root/main/Keep_Root.sh -o Keep_Root.sh && chmod +x Keep_Root.sh && ./Keep_Root.sh
```
Or you can download script from release section and execute it.
## Usage
Execute Keep Root and choose a rooting method when prompted. For APatch, input your superkey when requested.

## Future Enhancements
- [ ] Planned support for maintaining root after TWRP flashing.
- [ ] Add support for additional devices beyond the Realme 11 Pro Series.
- [ ] Implement an automated backup feature before performing root operations.
- [ ] Integrate with more custom recovery tools.

## Disclaimer
Keep Root is provided "as is" without any warranty. The author is not responsible for any damage or data loss incurred through its use.

## Contributions
Contributions are welcome. Please submit pull requests or issues via GitHub.

## License
Keep Root is licensed under the GNU General Public License (GPL).

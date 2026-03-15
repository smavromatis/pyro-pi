# PyroPi: Dedicated Raspberry Pi Video Appliance

> [!WARNING]
> This project is currently under active development and contains a significant number of bugs.

This project was created primarily to utilize spare equipment to build a realistic fireplace for my basement. It serves as a deployment utility designed to transform a Raspberry Pi (4 or 5) into a dedicated, high-performance video looper.

## Features

- **Automated Boot-to-Video**: The system is configured to launch the video loop immediately upon power-on without desktop environment overhead.
- **Hardware-Accelerated Decoding**: Utilizes optimized playback paths for seamless 60fps transitions and thermal stability.
- **Appliance-Level Obfuscation**: Hides standard Linux boot sequences, splash screens, and cursors for a professional end-user experience.
- **Data Integrity Protection**: Support for Read-Only (Overlay) filesystems to prevent SD card corruption during hard power-offs.
- **Hardware Compatibility**: Specifically tuned for Raspberry Pi 4 and 5 architectures.

## Installation

1. Prepare a clean installation of Raspberry Pi OS (Lite recommended).
2. Transfer your source video file (MP4, MOV, or MKV) to the project directory.
3. Execute the installation script:
   ```bash
   sudo ./install.sh
   ```
4. Follow the configuration prompts to optimize media, configure boot settings, and enable filesystem protection.

## Administration and Control

PyroPi operates as a systemd service (`pyropi.service`). Management can be performed via the following commands:

- **Service Status**: `systemctl status pyropi`
- **Restart Playback**: `systemctl restart pyropi`
- **System Logs**: `journalctl -u pyropi -f`

## Configuration Notes

- **Media Optimization**: The installation script includes a conversion utility that prepares media as a high-bitrate, 60fps MKV for maximum stability.
- **Audio Routing**: Supports routing audio via HDMI or the 3.5mm onboard jack.
- **System Hardening**: For production environments, it is strongly recommended to enable the **Read-Only File System** provided in the final installation step. This ensures the device is resilient against sudden power cycles.

#!/bin/bash
# PyroPi deployment utility for RPi 4/5. 

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: Root privileges required.${NC}" 
   exit 1
fi

REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
VIDEO_DIR="$REAL_HOME/video"

echo -e "${CYAN}Installing dependencies...${NC}"
apt-get update -y && apt-get install -y mpv ffmpeg
usermod -a -G video,render,tty,input,audio "$REAL_USER"

# Media Pre-processing
if [ ! -f "$VIDEO_DIR/perfect_loop.mkv" ]; then
    SOURCE_VIDEO=$(ls "$SCRIPT_DIR"/*.mp4 "$SCRIPT_DIR"/*.mov "$SCRIPT_DIR"/*.mkv "$VIDEO_DIR"/*.mp4 2>/dev/null | head -n 1)
    
    if [ -n "$SOURCE_VIDEO" ]; then
        echo -e "Source detected: $(basename "$SOURCE_VIDEO")"
        read -p "Prepare infinite stream? (y/n): " CONVERT_CHOICE
        if [[ $CONVERT_CHOICE =~ ^[Yy]$ ]]; then
            echo -en "${CYAN}Encoding high-performance MKV loop (60fps)...${NC}"
            mkdir -p "$VIDEO_DIR"
            ffmpeg -y -i "$SOURCE_VIDEO" \
                -c:v libx264 -preset slow -crf 18 -profile:v high -level 4.1 \
                -bf 0 -g 60 -r 60 -pix_fmt yuv420p \
                -c:a aac -b:a 192k \
                "$VIDEO_DIR/perfect_loop.mkv" > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                chown "$REAL_USER:$REAL_USER" "$VIDEO_DIR/perfect_loop.mkv"
                echo -e "${GREEN} Done.${NC}"
            else
                echo -e "${RED} Failed.${NC}"
            fi
        fi
    fi
fi

# Audio output
echo -e "\n${BOLD}Audio Output:${NC}"
echo "1) HDMI"
HAS_JACK=$(aplay -l 2>/dev/null | grep -i "Headphones" || true)
[ -n "$HAS_JACK" ] && echo "2) 3.5mm Jack"

read -p "Selection: " AUDIO_CHOICE
AUDIO_FLAG=""
if [[ $AUDIO_CHOICE == "2" ]]; then
    AUDIO_FLAG="--audio-device=alsa/plughw:CARD=Headphones,DEV=0"
    CONFIG_PATH="/boot/firmware/config.txt"
    [ ! -f "$CONFIG_PATH" ] && CONFIG_PATH="/boot/config.txt"
    if [ -f "$CONFIG_PATH" ]; then
        grep -q "^dtparam=audio=on" "$CONFIG_PATH" || echo "dtparam=audio=on" >> "$CONFIG_PATH"
        grep -q "^hdmi_drive=2" "$CONFIG_PATH" || echo "hdmi_drive=2" >> "$CONFIG_PATH"
    fi
fi

# Service installation
if [ -f "$SCRIPT_DIR/pyropi.service" ]; then
    sed -e "s#TEMPLATE_USER#$REAL_USER#g" \
        -e "s#TEMPLATE_AUDIO#$AUDIO_FLAG#g" \
        -e "s#TEMPLATE_PATH#$VIDEO_DIR/perfect_loop.mkv#g" \
        "$SCRIPT_DIR/pyropi.service" > /etc/systemd/system/pyropi.service
    systemctl daemon-reload
    systemctl enable pyropi.service
fi

# Boot configuration (Appliance Mode)
read -p "Hide boot sequence? (y/n): " APPLIANCE_CHOICE
if [[ $APPLIANCE_CHOICE =~ ^[Yy]$ ]]; then
    CMDLINE_PATH="/boot/firmware/cmdline.txt"
    [ ! -f "$CMDLINE_PATH" ] && CMDLINE_PATH="/boot/cmdline.txt"

    if [ -f "$CMDLINE_PATH" ]; then
        sed -i 's/console=tty1/console=tty3/g' "$CMDLINE_PATH"
        for flag in "quiet" "loglevel=3" "logo.nologo" "vt.global_cursor_default=0" "consoleblank=0"; do
            grep -q "$flag" "$CMDLINE_PATH" || sed -i "1s/$/ $flag/" "$CMDLINE_PATH"
        done
    fi
    systemctl disable getty@tty1.service > /dev/null 2>&1
fi

# Overlay FS
read -p "Enable read-only protection? (y/n): " OVERLAY_CHOICE
if [[ $OVERLAY_CHOICE =~ ^[Yy]$ ]]; then
    raspi-config nonint enable_overlayfs
fi

echo -e "\nDeployment complete."

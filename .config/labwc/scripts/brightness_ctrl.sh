#!/bin/sh

#####################################
## author @Harsh-bin Github #########
#####################################

# CONFIGURATION
icon_dir="$HOME/.config/dunst/brightness-icon"
# Using same notification id as in volume_ctrl script, it looks good
notify_id=$(if pgrep -x "swaync" >/dev/null; then echo "-h string:x-canonical-private-synchronous:volume"; else echo "-r 3456"; fi)

# Validate input
if [ -z "$1" ]; then
    echo "Usage:"
    echo "   $(basename "$0") 5+   (Increase brightness by 5%)"
    echo "   $(basename "$0") 10-  (Decrease brightness by 10%)"
    exit 1


fi

# Check if input matches pattern (number followed by + or -)
case "$1" in
    *[0-9][+-])
        ;;
    *)
        echo "Usage:"
        echo "   $(basename "$0") 5+   (Increase brightness by 5%)"
        echo "   $(basename "$0") 10-  (Decrease brightness by 10%)"
        exit 1
        ;;
esac

# Parse Input
# Remove the last character to get the step
step="${1%?}"
# Get the last character to get the sign
sign="${1##*[0-9]}"

# Changes brightness value
if [ "$sign" = "+" ]; then
    brightnessctl set "${step}%+"
else
    brightnessctl set "${step}%-"
fi

# Get the current brightness of screen
brightness=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

# Select icon based on screen brightness
if [ "$brightness" -lt 34 ]; then
    icon="$icon_dir/brightness-low.png"
elif [ "$brightness" -lt 67 ]; then
    icon="$icon_dir/brightness-mid.png"
else
    icon="$icon_dir/brightness-high.png"
fi

text="Brightness: ${brightness}%"

# NOTIFICATION
notify-send -a "OSD" -t 3000 $notify_id -u low -i "$icon" "$text" -h int:value:"$brightness"

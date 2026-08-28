#!/bin/sh

# Original author: https://github.com/Harsh-bin
# Reworked for wpctl and POSIX shell: https://github.com/Drsheppard01 


icon_dir="/home/hoxton/.icons/Marwaita/symbolic/status"
# notification id
if pgrep -x "mako" >/dev/null 2>&1; then
    notify_id="-h string:x-canonical-private-synchronous:volume"
else
    notify_id="-r 3456"
fi

# default urgency
urgency="low"

# function to get speaker icon based on volume and mute status
get_speaker_icon() {
    vol=$1
    muted=$2

    if [ "$muted" = "true" ] || [ "$vol" -eq 0 ]; then
        echo "$icon_dir/audio-volume-muted-symbolic.svg"
    elif [ "$vol" -lt 34 ]; then
        echo "$icon_dir/audio-volume-low-symbolic.svg"
    elif [ "$vol" -lt 67 ]; then
        echo "$icon_dir/audio-volume-medium-symbolic.svg"
    else
        echo "$icon_dir/audio-volume-high-symbolic.svg"
    fi
}

# function to get volume as percentage
get_volume_percent() {
    device=$1
    mute_check=$(wpctl get-volume "$device" | grep -o MUTED)
    
    if [ "$mute_check" = "MUTED" ]; then
        echo "0"
    else
        wpctl get-volume "$device" | awk '{printf "%d\n", $2 * 100}'
    fi
}

# function to check if device is muted
get_mute_status() {
    device=$1
    if wpctl get-volume "$device" | grep -q MUTED; then
        echo "true"
    else
        echo "false"
    fi
}

# --- toggle mute logic ---
case "$1" in
    --toggle-mute)
        target="$2"

        if [ -z "$target" ] || [ "$target" = "speaker" ]; then
            # toggle speaker
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            
            is_muted=$(get_mute_status "@DEFAULT_AUDIO_SINK@")
            vol=$(get_volume_percent "@DEFAULT_AUDIO_SINK@")

            icon=$(get_speaker_icon "$vol" "$is_muted")
            if [ "$is_muted" = "true" ]; then
                text="Speakers Muted"
                urgency="critical"
            else
                text="Speakers Active"
            fi
            vol_bar_val="-h int:value:$vol"

        elif [ "$target" = "microphone" ]; then
            # toggle microphone
            wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            
            is_mic_muted=$(get_mute_status "@DEFAULT_AUDIO_SOURCE@")
            vol=$(get_volume_percent "@DEFAULT_AUDIO_SOURCE@")

            if [ "$is_mic_muted" = "true" ]; then
                icon="$icon_dir/audio-input-microphone-muted-symbolic.svg"
                text="Microphone Muted"
                urgency="critical"
            else
                icon="$icon_dir/audio-input-microphone-symbolic.svg"
                text="Microphone Active"
            fi
            vol_bar_val="-h int:value:$vol"

        else
            echo "Error: usage is --toggle-mute [optional: speaker|microphone]"
            exit 1
        fi
        ;;

    *)
        # check if argument matches number+sign pattern
        case "$1" in
            *[0-9][+-])
                # volume adjustment
                step=$(echo "$1" | sed 's/[^0-9]*//g')
                sign=$(echo "$1" | sed 's/[0-9]*//g')

                if [ "$sign" = "+" ]; then
                    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%+"
                    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0  # unmute
                elif [ "$sign" = "-" ]; then
                    wpctl set-volume @DEFAULT_AUDIO_SINK@ "${step}%-"
                fi

                # get status
                vol=$(get_volume_percent "@DEFAULT_AUDIO_SINK@")
                is_muted=$(get_mute_status "@DEFAULT_AUDIO_SINK@")

                # get icon and text
                icon=$(get_speaker_icon "$vol" "$is_muted")
                text="Volume: ${vol}%"
                vol_bar_val="-h int:value:$vol"

                # if volume is 0 or still muted, treat as critical
                if [ "$is_muted" = "true" ] || [ "$vol" -eq 0 ]; then
                    urgency="critical"
                fi
                ;;

            *)
                # help
                echo "Usage:"
                echo "  $(basename "$0") --toggle-mute              (Toggle Mute for Speaker)"
                echo "  $(basename "$0") --toggle-mute speaker      (Toggle Mute for Speaker only)"
                echo "  $(basename "$0") --toggle-mute microphone   (Toggle Mute for Microphone only)"
                echo "  $(basename "$0") 10+                         (Increase volume by 5%)"
                echo "  $(basename "$0") 10-                        (Decrease volume by 10%)"
                exit 1
                ;;
        esac
        ;;
esac

# --- notification ---
if [ -n "$body" ]; then
    # shellcheck disable=SC2086
    notify-send \
    -a "OSD" \
    -t 3000 \
    $notify_id \
    -u "$urgency" \
    -i "$icon" "$text" "$body" $vol_bar_val
else
    # shellcheck disable=SC2086
    notify-send \
	-a "OSD" \
    -t 3000 \
    $notify_id \
    -u "$urgency" \
    -i "$icon" "$text" $vol_bar_val
fi

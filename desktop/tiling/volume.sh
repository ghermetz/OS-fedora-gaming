#!/bin/bash
# fedora-gaming — touches de volume avec indicateur à l'écran, comme sous Windows.
# Usage : volume.sh plus | moins | muet | micro
id="${XDG_RUNTIME_DIR:-/tmp}/niri-osd-volume"
case "$1" in
    plus)  wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    moins) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    muet)  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    micro)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
            txt="Micro coupé"; ic=microphone-sensitivity-muted
        else
            txt="Micro activé"; ic=microphone-sensitivity-high
        fi
        notify-send -a Volume -i "$ic" -t 1500 -h string:x-canonical-private-synchronous:volume \
            -r "$(cat "$id" 2>/dev/null || echo 0)" -p "$txt" > "$id"
        exit ;;
esac
etat=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)          # « Volume: 0.45 [MUTED] »
pc=$(awk '{printf "%d", $2 * 100 + 0.5}' <<<"$etat")
if grep -q MUTED <<<"$etat"; then
    txt="Son coupé"; ic=audio-volume-muted
elif [ "$pc" -lt 34 ]; then txt="Volume $pc %"; ic=audio-volume-low
elif [ "$pc" -lt 67 ]; then txt="Volume $pc %"; ic=audio-volume-medium
else txt="Volume $pc %"; ic=audio-volume-high
fi
notify-send -a Volume -i "$ic" -t 1500 -h "int:value:$pc" -h string:x-canonical-private-synchronous:volume \
    -r "$(cat "$id" 2>/dev/null || echo 0)" -p "$txt" > "$id"

#!/usr/bin/bash.

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch the bar
polybar -q main -c ~/.config/polybar/config.ini &
polybar -q spotifybar -c ~/.config/polybar/spotify.ini &
polybar -q newsbar -c ~/.config/polybar/news.ini 
echo "Bars launched...."

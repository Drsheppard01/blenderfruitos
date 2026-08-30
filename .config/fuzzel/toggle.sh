#!/usr/bin/env bash
if pgrep -x fuzzel >/dev/null; then
  pkill fuzzel
else
  fuzzel
fi

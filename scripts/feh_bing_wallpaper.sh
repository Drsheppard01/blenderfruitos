#!/usr/bin/bash

# locale|grep -Ru '(?<=LANG=)[^.]*'\

# set wallpaper with bing's daily picture using system's locale
locale|grep LANG|awk -F'[=.]' '{print $2}' \
  |xargs -I {} curl -L -s "https://www.bing.com/HPImageArchive.aspx?format=xml&idx=0&n=1&mkt={}" \
  |xmllint --xpath "string(//url)" - \
  |xargs -I {} feh --no-fehbg --bg-scale https://www.bing.com{}

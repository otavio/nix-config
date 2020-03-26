~/bin/inputplug -d -0 -c $HOME/.config/i3/bin/input-event > /dev/null &

xmodmap ~/.xmodmaprc
xrdb -merge ~/.Xresources
xss-lock -- i3lock -n &
parcellite &
dusnt &

exec i3 -V > ~/.config/i3/log 2>&1

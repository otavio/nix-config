~/bin/inputplug -d -0 -c $HOME/.config/i3/bin/input-event > /dev/null &

xrdb -merge ~/.Xresources
xss-lock -- i3lock -n &

if type gnome-keyring-daemon > /dev/null; then
    eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets)
fi

exec i3 -V > ~/.config/i3/log 2>&1

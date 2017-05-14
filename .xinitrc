#!/bin/sh

xsetroot -cursor_name left_ptr
setroot -z ~/media/images/wallpaper.jpg
xrdb ~/.Xresources
#-m for azerty keyboard
sxhkd -m 1 &
exec bspwm

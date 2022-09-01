#!/bin/sh
 
xsetroot -cursor_name left_ptr
setroot -z ~/media/images/wallpaper.jpg
xrdb ~/.Xresources
 
sxhkd -c ~/.config/sxhkd/sxhkdrc_bspwm -m 1 &
setxkbmap -option caps:swapescape
exec bspwm
 
#sxhkd -c ~/.config/sxhkd/sxhkdrc_windowchef -m 1 &
#setxkbmap -option caps:swapescape
#exec windowchef

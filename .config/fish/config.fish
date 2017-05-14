set -x XDG_CONFIG_HOME "$HOME/.config"
set -x SXHKD_SHELL "/bin/sh"
set -x EDITOR "kak"
set -x PAGER "less"

set -x ESCDELAY 10
set fish_escape_delay_ms 10

#termite integration
printf '\033]7;file://%s%s\a' (hostname) (pwd | __fish_urlencode)

set -g fish_key_bindings fish_key_bindings

if status -l; and test -r /etc/locale.conf
    while read -l kv
        set -gx (string split "=" -- $kv)
    end </etc/locale.conf
end

if test -e ~/.config/fish/dayjob.fish
    source ~/.config/fish/dayjob.fish
end

if set -q fish_startup_command
    set -l tmp_command $fish_startup_command
    set -ex fish_startup_command
    eval $tmp_command
end



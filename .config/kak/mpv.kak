provide-module mpv %{

declare-option str mpv_socket
declare-option str mpv_program 'mpv'

define-command mpv-start -params .. %{
    try %{ mpv-close }
    eval %sh{
        socket=$(mktemp -u -t kak-mpv-XXXXX)
        printf "set-option global mpv_socket '%s'" "$socket"
        {
            if [ $# -gt 0 ]; then
                program="$@"
            else
                program="$kak_opt_mpv_program"
            fi
            $program --profile=noblacklist --idle --force-window "--input-ipc-server=$socket"
        } >/dev/null 2>&1 </dev/null &
    }
}

define-command mpv-close %{
    eval %sh{
        if [ ! -e "$kak_opt_mpv_socket" ]; then
            printf 'fail "No currently active session"'
            exit
        fi
        echo 'quit' | socat - "$kak_opt_mpv_socket" > /dev/null 2>&1
        printf "set-option global mpv_socket ''"
    }
}

define-command mpv-open-files -params .. %{
    eval %sh{
        if [ ! -e "$kak_opt_mpv_socket" ]; then
            printf 'fail "No currently active session"'
            exit
        fi
        tmp=$(mktemp -u)
        for path do
            [ "$path" = "" ] && continue
            if [ "$path" = "${path#/}" ]; then
                path="$PWD/$path"
            fi
            printf '%s\n' "${path}"
        done > $tmp
        printf '{"command": ["loadlist", "%s" ] }\n' "$tmp" | socat - "$kak_opt_mpv_socket" > /dev/null 2>&1
        rm "$tmp"
    }
}

define-command mpv-switch-to-file -params 1.. %{
}

define-command mpv-refresh-files-highlight -params 1.. %{
}

hook global ModuleLoaded filetree %{
    define-command filetree-open-file-mpv %{
        eval -save-regs 'a' %{
            reg a
            filetree-select-path-component
            eval -itersel %{ filetree-eval-on-fullpath %{ reg a %reg{a} %reg{p} } }
            mpv-open-files %reg{a}
        }
    }
}

}

require-module mpv

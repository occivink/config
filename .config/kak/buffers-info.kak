# show information about currently opened buffers
# originally by danr, with cherry-picked ideas from delapouite

hook global WinDisplay .* %{
    buffers-info
}

declare-option str-list bufinfo_tmp

define-command buffers-info %{
    eval -no-hooks -save-regs b %{
        unset buffer bufinfo_tmp
        reg b %val{bufname}
        eval -buffer * %{
            set -add "buffer=%reg{b}" bufinfo_tmp "%val{bufname}_%val{modified}"
        }
        info -title Buffers -- %sh{
            eval set -- $kak_opt_bufinfo_tmp
            for bufinfo in "$@"; do
                buf=${bufinfo%_*}
                if [ "$buf" = "$kak_bufname" ]; then
                    printf "> %s" "$buf"
                else
                    printf "  %s" "$buf"
                fi
                modified=${bufinfo##*_}
                if [ "$modified" = "true" ]; then
                   printf " [+]"
                fi
                echo
            done
        }
    }
}

declare-option str client 'all'
declare-option bool lock false
define-command lock %{ set buffer lock true }
define-command unlock %{ unset buffer lock }
define-command toggle-lock %{
    try %{
        eval %sh{ [ "$kak_opt_lock" = true ] && printf fail }
        lock
    } catch %{
        unlock
    }
}
define-command bind %{ set buffer client %val{client} }
define-command release %{ unset buffer client }
define-command release-all %{ eval -buffer * release }

define-command buffers-info-native %{
    eval -no-hooks -save-regs '"/' %{
        # debug so that it doesn't get iterated over
        eval -draft %{ edit -debug -scratch *tmp* }
        eval -buffer * %{
            reg '"' "  %val{bufname} %opt{client} %opt{lock} %val{modified}"
            exec -buffer *tmp* "gep"
        }
        # put the line corresponding to the current buffer as search pattern
        reg '/' "^  \Q%val{bufname}\E"
        reg "c" "%val{client}|all"
        eval -buffer *tmp* %{
            exec 'd'
            try %{ exec '/<ret>ghr>' } catch %{ exec '%<a-s>ghdd' }
            exec '%<a-s>1s^[^\n]+? (\w+) \w+ \w+$<ret>'
            try %{ exec -draft '"c<a-K><ret><a-x>d' }
            exec 'dd<a-e>'
            try %{ exec -draft '<a-k>true<ret>i=<esc>' }
            exec 'dd<a-e>'
            try %{ exec -draft '<a-k>true<ret>i+<esc>' }
            exec 'd'
            exec '%<a-s>h'
            try %{ exec -draft '<a-i><a-w>i[<esc>a]<esc>' }
            try %{ exec -draft '<a-i><space>d' }
            exec -save-regs '' '%y'
        }
        delete-buffer *tmp*
        info -title Buffers %reg{"}
    }
}

define-command delete-unlocked-buffers %{
    eval -no-hooks -save-regs '"/' %{
        eval -draft %{ edit -debug -scratch *tmp* }
        eval -buffer * %{
            reg '"' "%val{bufname} %opt{lock}"
            exec -buffer *tmp* "gep"
        }
        eval  -no-hooks -buffer *tmp* %{
            exec 'd'
            exec '%<a-s>gl<a-B>'
            exec '<a-k>false<ret>'
            exec 'hhGh'
            eval -itersel %{ delete-buffer %reg{.} }
        }
        delete-buffer *tmp*
    }
}


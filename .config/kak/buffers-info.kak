# show information about currently opened buffers
# originally by danr, with cherry-picked ideas from delapouite

hook global WinDisplay .* %{
    buffers-info
}

declare-option str client 'all'
declare-option bool pinned false
define-command pin %{ set buffer pinned true; buffers-info }
define-command unpin %{ unset buffer pinned; buffers-info }
define-command toggle-pin %{
    try %{
        eval %sh{ [ "$kak_opt_pinned" = true ] && printf fail }
        pin
    } catch %{
        unpin
    }
}
define-command bind %{ set buffer client %val{client} }
define-command release %{ unset buffer client }
define-command release-all %{ eval -buffer * release }

define-command buffers-info %{
    eval -no-hooks -save-regs '"/c' %{
        # debug so that it doesn't get iterated over
        eval -draft %{ edit -debug -scratch *tmp* }
        eval -buffer * %{
            reg '"' "  %val{bufname} %opt{client} %opt{pinned} %val{modified}"
            exec -buffer *tmp* "gep"
        }
        # put the line corresponding to the current buffer as search pattern
        reg '/' "^  \Q%val{bufname}\E( \w+){3}$"
        reg "c" "%val{client}|all"
        eval -buffer *tmp* %{
            # remove stray newline at the top
            exec 'd'

            # put '>' in front of the current buffer
            try %{ exec '/<ret>ghr>' }

            # select the first option, to start iterating over all the flags
            exec '%<a-s>1s^[^\n]+? +(\w+) \w+ \w+$<ret>'
            # align the flags, it looks cooler
            exec '&'

            # remove lines whose client is neither '$current_client' nor 'all', and not the current buffer
            try %{ exec -draft '"c<a-K><ret>gh<a-K>><ret><a-x>d' }
            exec 'dd<a-e>'

            # replace 'pinned' bool with a '=' flag (or nothing)
            try %{ exec -draft '<a-k>true<ret>i=<esc>' }
            exec 'dd<a-e>'

            # replace 'modified' bool with a '+' flag (or nothing)
            try %{ exec -draft '<a-k>true<ret>i+<esc>' }
            exec 'd'

            exec '%<a-s>h'
            # surround flags (if there are any) with [ ]
            try %{ exec -draft '<a-i><a-w>i[<esc>a]<esc>' }
            # remove trailing spaces
            try %{ exec -draft '<a-i><space>d' }

            exec -save-regs '' '%y'
        }
        delete-buffer *tmp*
        info -title Buffers %reg{"}
    }
}

# %arg{1} serves as filter for pinning
# %arg{2} serves as filter for client
# (use empty strings if you don't want to filter)
# %arg{3} is the command to eval, the name of the buffer is available as %val{selection}
define-command eval-on-buffers -params 3 %{
    eval -draft -no-hooks -save-regs '"/' %{
        eval -draft %{ edit -debug -scratch *tmp* }
        eval -buffer * %{
            reg '"' "%val{bufname} %opt{client} %opt{pinned}"
            exec -buffer *tmp* "gep"
        }
        buffer *tmp*
        eval -buffer *tmp* %{
            exec 'd'
            try %{
                # select 'pinned' bool
                exec '%<a-s>gl<a-B>'
                # filter according to first arg
                reg / %arg{1}
                exec "<a-k><ret>"

                # select 'client' str
                exec 'hh<a-B>'
                # filter according to second arg
                reg / %arg{2}
                exec "<a-k><ret>"

                # select buffer name
                exec 'hhGh'
                eval %arg{3}
            }
        }
        delete-buffer *tmp*
    }
}

define-command delete-unpinned %{
    eval-on-buffers 'false' '' %{
        # try in order to not abort on failure
        eval -itersel %{ try %{ delete-buffer %val{selection} } }
    }
}

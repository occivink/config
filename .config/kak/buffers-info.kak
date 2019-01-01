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
        reg '/' "\A\Q%val{bufname}\E\z"
        reg "c" "%val{client}|all"
        eval -buffer *tmp* %{
            # remove stray newline at the top
            exec 'd'

            # select the buffers names
            exec '%<a-s>1s^  ([^\n]+) \w+ \w+ \w+$<ret>'

            # put > in front of the current buffer
            try %{ exec -draft <a-k><ret>ghr> }

            # trim directory names
            try %{ exec -draft 1s\.?[^/]([^/]*)/<ret>d }

            # select the first flag
            exec 'll<a-e>'
            # align the flags, it looks cooler
            exec '<a-;>&'

            # remove lines whose client is neither '$current_client' nor 'all', and not the current buffer
            try %{
                exec '"c<a-K><ret>gh<a-K>><ret><a-x>d'
                # re-select the flags, deleting lines + draft messes with the selections
                exec '%<a-s>1s^.*? (\w+) \w+ \w+$<ret>'
            }
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
    eval -draft -no-hooks -save-regs '"/^' %{
        eval -draft %{ edit -debug -scratch *eval-buffers* }
        eval -buffer * %{
            reg '"' "%val{bufname} %opt{client} %opt{pinned}"
            exec -buffer *eval-buffers* "gep"
        }
        reg '/' "\A\Q%val{bufname}\E\z"
        eval -buffer *eval-buffers* %{
            exec 'd'
            try %{
                # select 'pinned' bool
                exec '%<a-s>gl<a-b>'
                # filter according to first arg
                eval -save-regs '/' %{
                    reg / %arg{1}
                    exec "<a-k><ret>"
                }

                # select 'client' str
                exec 'h<a-b>'
                # filter according to second arg
                eval -save-regs '/' %{
                    reg / %arg{2}
                    exec "<a-k><ret>"
                }

                # select buffer names
                exec hhGh
                # make sure that the current buffer is the main sel
                try %{ exec 'Z<a-k><ret><a-z>a' }
                eval %arg{3}
            }
        }
        delete-buffer *eval-buffers*
    }
}

define-command delete-unpinned %{
    eval-on-buffers 'false' '' %{
        # try in order to not abort on failure
        eval -itersel %{ try %{ db %val{selection} } }
    }
    buffers-info
}

define-command next %{
    eval -save-regs 'b' %{
        eval-on-buffers '' "\A%val{client}|all\z" %{
            exec ')<space>'
            reg b %val{selection}
        }
        buffer %reg{b}
    }
}
define-command prev %{
    eval -save-regs 'b' %{
        eval-on-buffers '' "\A%val{client}|all\z" %{
            exec '(<space>'
            reg b %val{selection}
        }
        buffer %reg{b}
    }
}

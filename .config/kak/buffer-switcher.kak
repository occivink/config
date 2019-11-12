# we assume that a buffer name will never contain newlines (not exactly true, but who cares)

define-command buffer-switcher %{
    try %{
        b *buffer-switcher*
    } catch %{
        eval -save-regs '"/' %{
            reg / "^\Q%val{bufname}\E$"
            eval reg dquote %val{buflist}

            edit -scratch *buffer-switcher*
            exec '<a-P>)<a-space>i<ret><esc>'
            exec '%<a-s>'
            # remove *debug* buffer
            exec -draft '<a-k>^\*debug\*$<ret>d'
            try %{
                # select current one
                exec '<a-k><ret>'
                # also highlight it in green
                addhl buffer/ regex "%reg{/}" 0:black,green
            }
            map buffer normal <ret> ': buffer-switcher-delete-buffers; buffer-switcher-switch<ret>'
            map buffer normal <esc> ': delete-buffer *buffer-switcher*<ret>'
            hook global -once WinDisplay .* %{ try %{ delete-buffer *buffer-switcher* } }
        }
    }
}

define-command -hidden buffer-switcher-delete-buffers %{
    # delete all buffers whose lines were removed
    eval -draft %{
        exec '%<a-s><ret>H'
        eval %sh{
            {
            eval set -- "$kak_quoted_buflist"
            for buf do
                # ignore self and debug
                if [ "$buf" = '*buffer-switcher*' ]; then
                    :
                elif [ "$buf" = '*debug*' ]; then
                    :
                else
                    printf '%s\n' "$buf"
                fi
            done
            eval set -- "$kak_quoted_selections"
            for buf do
                printf '%s\n' "$buf"
            done
            } | awk "
                // {
                    line=\$0
                    if (line in line_count)
                        line_count[line] = line_count[line] + 1;
                    else
                        line_count[line] = 1;
                }
                END {
                    for (line in line_count)
                        if (line_count[line] == 1)
                        {
                            gsub(\"'\", \"''''\", line);
                            print(\"try 'delete-buffer ''\" line \"'' '\");
                        }
                }"
        }
    }
}

define-command -hidden buffer-switcher-switch %{
    exec '<space>;<a-x>H'
    eval -save-regs b %{
        reg b %val{selection}
        delete-buffer *buffer-switcher*
        buffer %reg{b}
    }
}

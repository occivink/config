# show information about currently opened buffers
# originally by danr, with cherry-picked ideas from delapouite

hook global WinDisplay .* %{
    buffers-info
}

define-command buffers-info %{
    eval -save-regs 'bc' %{ 
        set-register b %val{bufname}
        set-register c ''
        eval -no-hooks -buffer * %{
            set-register c "%reg{c}:%val{bufname}_%val{modified}"
        }
        %sh{
            printf "info -title Buffers -- %%:"
            IFS=:
            for bufinfo in ${kak_reg_c#:}; do
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
            printf :\\n
        }
    }
}

define-command buffers-info-filtered %{
    %sh{
        case "$kak_client" in
            tools) printf "exec "
            ;;
            main) printf ""
            ;;
            *) printf ""
            ;;
        esac
    }
}

# hella fast
define-command buffers-info-native -params ..1 %{
    eval -no-hooks -save-regs '"/bi' %{

        # debug so that it doesn't get iterated over
        eval -no-hooks -draft %{ edit -debug -scratch *buffers-info-native* }
        # create one line per buffer, in the format "  bufname (true|false)"
        eval -no-hooks -buffer * %{
            reg '"' "  %val{bufname} %val{modified}
"
            exec -no-hooks -buffer *buffers-info-native* "gep"
        }
        # put the line corresponding to the current buffer as search pattern
        reg '/' "^  \Q%val{bufname}\E( \[\+\])?$"
        eval -save-regs '/' -no-hooks -buffer *buffers-info-native* %{
            exec -no-hooks 'd'
            # remove "false" suffix
            try %{ exec -no-hooks '%s false$<ret>d' }
            # replace "true" suffix with "[+]"
            try %{ exec -no-hooks '%strue$<ret>c[+]<esc>' }
            # prepend '>' to current buffer
            try %{ exec -no-hooks '/<ret>ghr>' }
            # arbitrary hook: do everything you want here
            eval %arg{1}
            # put into register 'i' the whole bufinfo
            exec -draft -no-hooks '%"iy'
            # put into register 'b' the buffer we want to select
            exec -no-hooks '<space>;<a-x>s^[ >] (.*?)(?: \[\+\])?$<ret>'
            reg b %reg{1}
        }
        buffer %reg{b}
        delete-buffer *buffers-info-native*
        info -title Buffers %reg{i}
    }
}

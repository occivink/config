# show information about currently opened buffers
# originally by danr

hook global WinDisplay .* bufinfo

map global normal <a-,> :bp<ret>
map global normal <a-.> :bn<ret>
map global normal <a-d> :db<ret>
map global normal <a-r> :e!<ret>
map global normal <a-q> :db!<ret>

declare-option -hidden str-list bufinfo_text
declare-option -hidden str bufinfo_current_buf

define-command -hidden bufinfo %{
    set global bufinfo_current_buf %val{bufname}
    eval -no-hooks -buffer *  %{
        set -add "buffer=%opt{bufinfo_current_buf}" bufinfo_text "%val{bufname}_%val{modified}"
    }
    %sh{
        echo "unset-option buffer bufinfo_text"
        printf "info -title Buffers -- %%:"
        printf '%s\n' "$kak_opt_bufinfo_text" | tr ':' '\n' |
        while read bufinfo; do
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

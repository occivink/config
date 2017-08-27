# show information about currently opened buffers
# originally by danr, with cherry-picked ideas from delapouite

declare-option -hidden str current_bufname

hook global WinDisplay .* %{
    set global current_bufname %val{bufname}
    buffers-info
}

map global normal <a-,> :bp<ret>
map global normal <a-.> :bn<ret>
map global normal <a-d> :db<ret>
map global normal <a-r> :e!<ret>
map global normal <a-q> :db!<ret>

declare-option -hidden str-list bufinfo_text

define-command -hidden buffers-info %{
    eval -no-hooks -buffer * %{
        set -add "buffer=%opt{current_bufname}" bufinfo_text "%val{bufname}_%val{modified}"
    }
    %sh{
        echo "unset-option buffer bufinfo_text"
        printf "info -title Buffers -- %%:"
        IFS=:
        for bufinfo in $kak_opt_bufinfo_text; do
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

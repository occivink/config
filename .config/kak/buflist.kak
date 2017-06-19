# Buffers (by danr 2017, public domain)
hook global WinDisplay .* bufinfo
map global normal <a-,> :bp<ret>
map global normal <a-.> :bn<ret>
map global normal <a-d> :db<ret>
map global normal <a-r> :e!<ret>
map global normal <a-q> :db!<ret>

decl str-list bufinfo_text
def bufinfo %{
    set global bufinfo_text ''
    eval -no-hooks -buffer *  %{
        set -add global bufinfo_text "%val{bufname}_%val{modified}"
    }
    %sh{
        printf "info -title Buffers -- %%:"
        printf '%s\n' "$kak_opt_bufinfo_text" | tr ':' '\n' |
        while read bufinfo; do
            buf=${bufinfo%_*}
            if [ "$buf" = "*debug*" ]; then
                continue
            elif [ "$buf" = "$kak_bufname" ]; then
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

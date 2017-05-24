# Buffers (by danr 2017, public domain)
hook global WinDisplay .* %{
    bufinfo
}
map global normal <a-,> :bp<ret>
map global normal <a-.> :bn<ret>
map global normal <a-d> :db<ret>
map global normal <a-r> :e!<ret>
map global normal <a-q> :db!<ret>
def bufinfo %{
    %sh{
        printf "info -- %%:"
        printf "$kak_buflist" | tr ':' '\n' |
        while read buf; do
            if [ "$buf" = "$kak_bufname" ]; then
                printf "> %s <\n" "$buf"
            else
                printf "  %s  \n" "$buf"
            fi
        done
        printf :\\n
    }
}

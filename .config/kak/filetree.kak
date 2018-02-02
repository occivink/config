declare-option str filetree_open_files

define-command filetree %{
    eval %{
        set-register / "^\Q./%val{bufname}\E$"
        edit -scratch *filetree*
        exec '<a-!>find . -not -type d<ret>'
        exec 'ged'
        exec '%|sort<ret>'
        exec '/<ret>vc'
        addhl buffer dynregex '%opt{filetree_open_files}' 0:black,yellow
        addhl buffer regex '^([^\n]+/)([^/\n]+)$' 1:rgb:606060,default
        map buffer normal <ret> :filetree-open-file<ret>
    }
}

define-command buflist-to-regex -params ..1 %{
    try %{
        eval -buffer *filetree* %{
            set-option buffer filetree_open_files %sh{
                r=$(
                    IFS=:
                    for i in $kak_buflist; do
                        [ "$i" != "$1" ] && printf "\Q%s\E|" "$i"
                    done
                )
                printf "^\./(%s)$" "${r%|}"
            }
        }
    }
}

hook global BufCreate .* %{ buflist-to-regex }
hook global BufClose  .* %{ buflist-to-regex %val{hook_param} }

define-command -hidden filetree-open-file %{
    exec '<space>;<a-x>Hgf'
}

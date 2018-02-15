declare-option -hidden str filetree_open_files

set-face FileTreeOpenFiles black,yellow
set-face FileTreeDirName rgb:606060,default
set-face FileTreeFileName default,default

define-command -hidden filetree %{
    eval %{
	    try %{ delete-buffer *filetree* }
        set-register / "^\Q./%val{bufname}\E$"
        edit -scratch *filetree*
        #exec '<a-!>find .  -not -type d -and -not -path "*/\.*"<ret>'
        exec '<a-!>elvish -c "use find; pprint (find:find &dirs=\$false)"<ret>'
        exec 'ged'
        #exec '%|sort<ret>'
        # center view on previous file
        try %{ exec '/<ret>vc' }
        addhl buffer dynregex '%opt{filetree_open_files}' 0:FileTreeOpenFiles
        addhl buffer regex '^([^\n]+/)([^/\n]+)$' 1:FileTreeDirName 2:FileTreeFileName
        map buffer normal <ret> :filetree-open-files<ret>
    }
}

define-command -hidden buflist-to-regex -params ..1 %{
    try %{
        # eval to avoid using a shell scope if *filetree* is not open
        eval -buffer *filetree* %{
            set-option buffer filetree_open_files %sh{
                r=$(
                    IFS=:
                    for i in $kak_buflist; do
                        [ "$i" != "$1" ] && printf "%s%s%s" "\Q" "$i" "\E|"
                    done
                )
                # strip trailing |
                printf "^\./(%s)$" "${r%|}"
            }
        }
    }
}

hook global BufCreate .* %{ buflist-to-regex }
hook global BufClose  .* %{ buflist-to-regex %val{hook_param} }

define-command -hidden filetree-open-files %{
    eval -draft -itersel %{
        exec ';<a-x>H'
        # don't force -existing, so that this can be used to create files
        eval -draft "edit %reg{.}"
    }
    exec '<space>;<a-x>H'
    eval -try-client %opt{jumpclient} %{ buffer %reg{.} }
    try %{ focus %opt{jumpclient} }
}

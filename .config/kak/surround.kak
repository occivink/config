# manually surround the current selection with known pairs
# dumb but simple implementation

define-command surround-lock %{
    surround-title " (lock)"
    on-key %{
        try %{
            surround-impl %val{key}
            surround-lock
        }
    }
}

define-command surround %{
    surround-title
    on-key %{
        try %{ surround-impl %val{key} }
    }
}

define-command -hidden surround-title -params ..1 %{
    info -title "surround%arg{1}" \
%{b,(,):               parentheses
B,{,}:               braces
r,[,]:               brackets
a,<,>:               angle brackets
Q,":                 double quotes
q,':                 single quotes
g,`:                 grave quotes
<space>:             spaces
c:                   custom delimiter
h,<left>:            reduce
j,<right>:           extend
k,<up>:              shrink
l,<down>:            grow
<backspace>,<del>,d: delete}
}

define-command -hidden surround-impl -params 1 %{
    # clear the infobox
    info
    eval %sh{
        case "$1" in
            B|{|})                   printf '%s' "surround-add { }" ;;
            b|\(|\))                 printf '%s' "surround-add ( )" ;;
            r|[|])                   printf '%s' "surround-add [ ]" ;;
            a|\<lt\>|\<gt\>)         printf '%s' "surround-add <lt> <gt>" ;;
            Q|\"|\<dquote\>)         printf '%s' 'surround-add %{"} %{"}' ;;
            q|\'|\<quote\>)          printf '%s' "surround-add %{'} %{'}" ;;
            g|\`)                    printf '%s' "surround-add %{`} %{`}" ;;
            \<ret\>)                 printf '%s' "surround-add <ret> <ret>" ;;
            \<space\>)               printf '%s' "surround-add ' ' ' '" ;;
            c)                       printf '%s' "surround-custom" ;;
            \<backspace\>|\<del\>|d) printf '%s' "surround-del" ;;
            h|\<left\>)              printf '%s' "surround-move H L" ;;
            l|\<right\>)             printf '%s' "surround-move L H" ;;
            k|\<up\>)                printf '%s' "surround-move K J" ;;
            j|\<down\>)              printf '%s' "surround-move J K" ;;
            *)                       printf '%s' "fail" ;;
        esac
    }
}

define-command -hidden surround-custom %{
	on-key %{ surround-add %val{key} %val{key} }
}

define-command -hidden surround-add -params 2 %{
    exec "i%arg{1}<esc>Ha%arg{2}" <esc>
}

define-command -hidden surround-del %{
    exec "i<del><esc>a<backspace><esc>"
}
define-command -hidden surround-move -params 2 %{
    exec "%arg{1}<a-;>%arg{2}<a-;>"
}

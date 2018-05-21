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
h,<left>:            reduce
j,<right>:           extend
k,<up>:              shrink
l,<down>:            grow
<backspace>,<del>,d: delete}
}

define-command -hidden surround-impl -params 1 %{
    # clear the infobox
    info
    %sh{
        case "$1" in
            B|{|}) echo "surround-add { }" ;;
            b|\(|\)) echo "surround-add ( )" ;;
            r|[|]) echo "surround-add [ ]" ;;
            a|\<lt\>|\<gt\>) echo "surround-add <lt> <gt>" ;;
            Q|\") echo 'surround-add "\"" "\""' ;;
            q|\') echo "surround-add '\'' '\''" ;;
            g|\`) echo "surround-add \` \`" ;;
            \<space\>) echo "surround-add ' ' ' '" ;;
            \<backspace\>|\<del\>|d) echo "surround-del" ;;
            h|\<left\>) echo "surround-move H L" ;;
            l|\<right\>) echo "surround-move L H" ;;
            k|\<up\>) echo "surround-move K J" ;;
            j|\<down\>) echo "surround-move J K" ;;
            *) echo "fail" ;;
        esac
    }
}

define-command -hidden surround-add -params 2 %{
    exec -no-hooks "i%arg{1}<esc>Ha%arg{2}" <esc>
}
define-command -hidden surround-del %{
    exec -no-hooks i<del><esc>a<backspace><esc>
}
define-command -hidden surround-move -params 2 %{
    exec -no-hooks "%arg{1}<a-;>%arg{2}<a-;>"
}

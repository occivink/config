# manually surround the current selection with known pairs
# dumb but simple implementation

define-command surround-repeat %{
    surround-title
    on-key %{
        try %{
            surround-impl %val{key}
            surround-repeat
        }
    }
}

define-command surround %{
    surround-title
    on-key %{
        try %{
            surround-impl %val{key}
        }
    }
}

define-command -hidden surround-title %{
    info -title "surround" \
%{B,{,}:               parentheses
b,(,):               braces
r,[,]:               brackets
a,<,>:               angle brackets
Q,":                 double quotes
q,':                 single quotes
g,`:                 grave quotes
<space>:             spaces
<left>:              
<right>:             
<backspace>,<del>,d: delete surrounding}
}

define-command -hidden surround-impl -params 1 %{
    %sh{
        case "$1" in
            B|{|})
                echo "surround-add { }" ;;
            b|\(|\))
                echo "surround-add ( )" ;;
            r|[|])
                echo "surround-add [ ]" ;;
            a|\<lt\>|\<gt\>)
                echo "surround-add < >" ;;
            Q|\")
                echo 'surround-add "\"" "\""' ;;
            q|\')
                echo "surround-add '\'' '\''" ;;
            g|\`)
                echo "surround-add \` \`" ;;
            \<space\>)
                echo "surround-add ' ' ' '" ;;
            \<backspace\>|\<del\>|d)
                echo "surround-del" ;;
            \<left\>)
                echo "surround-in" ;;
            \<right\>)
                echo "surround-out" ;;
            *)
                echo "exec <esc>"
                echo raise ;;
        esac
    }
}

define-command -hidden surround-add -params 2 %{
    exec -collapse-jumps -no-hooks i %arg{1} <esc> H a %arg{2} <esc>
}
define-command -hidden surround-del %{
    exec -collapse-jumps i<del><esc>a<backspace><esc>
}
define-command -hidden surround-in %{
    exec -collapse-jumps "<a-:>H<a-;>L<a-;>"
}
define-command -hidden surround-out %{
    exec -collapse-jumps "<a-:>L<a-;>H<a-;>"
}

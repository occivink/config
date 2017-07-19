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
%{B,{,}:               braces
b,(,):               parentheses
r,[,]:               brackets
a,<,>:               angle brackets
Q,":                 double quotes
q,':                 single quotes
g,`:                 grave quotes
<space>:             spaces
<left>:              reduce surrounding
<right>:             extend surrounding
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

define-command -hidden left-or-up %{
    try %{
        # throw if we're at the beginning of a line
        exec -draft \;Zh<a-z>a<a-space>
        exec H
    } catch %{
        exec KGll
    }
}
define-command -hidden right-or-down %{
    try %{
        # throw if we're at the end of a line
        exec -draft \;Zl<a-z>a<a-space>
        exec L
    } catch %{
        exec JGh
    }
}
define-command -hidden surround-add -params 2 %{
    exec -collapse-jumps -no-hooks i %arg{1} <esc> H a %arg{2} <esc>
}
define-command -hidden surround-del %{
    exec -collapse-jumps i<del><esc>a<backspace><esc>
}
define-command -hidden surround-in %{
    exec -collapse-jumps "<a-:>:left-or-up<ret><a-;>:right-or-down<ret><a-;>"
}
define-command -hidden surround-out %{
    exec -collapse-jumps "<a-:>:right-or-down<ret><a-;>:left-or-up<ret><a-;>"
}

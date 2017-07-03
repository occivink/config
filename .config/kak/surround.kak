# manually surround the current selection with known pairs
# dumb but simple implementation

define-command -hidden surround-add -params 2 %{
    exec -collapse-jumps -no-hooks i %arg{1} <esc> H a %arg{2} <esc>
}
define-command -hidden surround-del %{
    exec -collapse-jumps i<del><esc>a<backspace><esc>
}

define-command surround %{
    info -title "surround" \
%{B,{,}:               parentheses
b,(,):               braces
r,[,]:               brackets
a,<,>:               angle brackets
Q,":                 double quotes
q,':                 single quotes
g,`:                 grave quotes
<space>:             spaces
<backspace>,<del>,d: delete surrounding}
    on-key %{ %sh{
        case "$kak_key" in
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
            *)
                echo "exec <esc>" ;;
        esac
    }}
}

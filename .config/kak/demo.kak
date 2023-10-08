declare-option -hidden str demo_script_path %val{source}

define-command demo-perform -params 1 %{
    eval %sh{
        if [ ! -f "$1" ]; then
            echo "echo -debug 'No demo script found'"
            exit 1
        fi
        sh_script="${kak_opt_demo_script_path%/*}/kak_demo.sh"
        if [ ! -f "$sh_script" ]; then
            echo "echo -debug 'No helper script found'"
            exit 1
        fi
        {
            sh "$sh_script" "$kak_session" "$kak_client" < "$1"
        } >/dev/null 2>&1 </dev/null &
        printf "map global normal <c-x> ': quit! 1<ret>'\n"
        printf "map global insert <c-x> '<esc>: quit! 1<ret> '\n"
        printf "map global prompt <c-x> '<esc>: quit! 1<ret> '\n"
    }
}

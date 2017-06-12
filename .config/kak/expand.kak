declare-option -hidden str-list expand_results

define-command select_indented_paragraph %{
    eval -itersel %{
        exec -draft -save-regs '' '<a-i>pZ'
        exec '<a-i>i<a-z>i'
    }
    exec <esc>
}

define-command expand %{
    set-option global expand_results ""
    exec <space>
    expand-impl ""
    # the text object selection commands are found through trial and error
    expand-impl "exec <a-a>b"
    expand-impl "exec <a-a>B"
    expand-impl "exec <a-a>r"
    expand-impl "exec <a-i>i"
    expand-impl "exec /.<ret><a-K>\n<ret>; select_indented_paragraph"
    expand-impl "select_indented_paragraph"
    #expand-impl select_indent_no_empty_lines
    %sh{
        printf "%s\n" "$kak_opt_expand_results" | tr ':' '\n' | {
        while read -r current; do
            selected=${current##*_}
            if [ ! -n "$current_best" ]; then
                init=$selected
                current_best=999999
            elif [ $selected -gt $init ] && [ $selected -lt $current_best ]; then
                cmd=${current%_*}
                current_best=$selected
            fi
        done
        if [ -n "$cmd" ]; then
            printf "%s\n" "$cmd"
        fi
        }
    }
    set-option global expand_results ""
}

define-command expand-impl -hidden -params 1 %{
    eval -no-hooks -draft %{
        try %{
            eval %arg{1}
            exec s.<ret>
            set-option -add global expand_results "%arg{1}_%reg{#}"
        }
    }
}

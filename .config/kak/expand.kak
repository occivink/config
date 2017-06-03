decl str-list expand_results

define-command expand-start %{
}

define-command expand %{
    set-option global expand_results ""
    exec <space>
    expand-impl <esc>
    # the text object selection commands are found through trial and error
    expand-impl "<a-a>b"
    expand-impl "<a-a>B"
    expand-impl "<a-a>r"
    expand-impl "<a-a>a"
    expand-impl "<a-i>i"
    expand-impl "/.<ret><a-i>i"
    #expand-impl select_indent_no_empty_lines
    %sh{
        while read -r current; do
            selected=${current##*_}
            if [ ! -n "$current_best" ]; then
                init=$selected
                current_best=999999
            elif [ $selected -gt $init ] && [ $selected -lt $current_best ]; then
                cmd=${current%_*}
                current_best=$selected
            fi
        done <<-EOF
			$(printf %s "$kak_opt_expand_results" | tr ':' '\n')
		EOF
        if [ -n "$cmd" ]; then
            printf "eval %s\n" "$cmd"
        fi
    }
    set-option global expand_results ""
}

define-command select_indent_no_empty_lines %{
    eval %{
        # yank current indentation
        exec -draft -save-regs '' ';<a-x>s^\h+<ret>y'
        # select first element that doesn't have the same indent
        exec '<a-x>/(^<c-r>"[^\n]*\n)*.<ret>;'
        # select all preceding lines with the same indent
        exec '<a-/>(^<c-r>"[^\n]*\n)*<ret>'
    }
}

define-command expand-impl -hidden -params 1 %{
    eval -no-hooks -draft %{
        try %{
            exec %arg{1}
            exec s.<ret>
            set-option -add global expand_results "%arg{1}_%reg{#}"
        }
    }
}

# performs basic math on all selections
define-command math %{
    single-process-pipe 'sh -c "while read val; do echo \$(( \$val )); done"'
}

# pad each selection
# $1: character to pad with
# $2: resulting length
define-command -params ..2 pad %{
    eval -save-regs 'pc' %{
        %sh{
            printf "set-register p '%s'\n" "${1- }"
            printf "set-register c '%s'\n" "${2-0}"
        }
        # good god how horrifying
        single-process-pipe "awk 'BEGIN { L = %reg{c} } // { l[lines++] = $0; if (length > L) { L = length } } END { for(i = 0; i <lt> lines; ++i) { for (j = 0; j <lt> L - length(l[i]); ++j) { printf(\"%reg{p}\")} print(l[i]) } }'"
    }
}

define-command -params 1 single-process-pipe %{
    eval %{
        eval -save-regs '' -draft %{
            exec -save-regs '' y
            edit -scratch *single-process-pipe*
            exec <a-p>i<ret><esc>ggd
            exec "\%|%arg{1}<ret>"
            exec -save-regs '' '%<a-s>Hy'
            delete-buffer *single-process-pipe*
        }
        exec R
    }
}

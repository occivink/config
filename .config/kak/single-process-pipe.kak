define-command -params 1 single-process-pipe %{
    eval -save-regs '"' %{
        eval -save-regs '|' -draft %{
            exec -save-regs '' y
            edit -scratch *single-process-pipe*
            exec <a-P>i<ret><esc>ggd
            set-register '|' %arg{1}
            exec '%|<ret>'
            exec -save-regs '' '%<a-s>Hy'
            delete-buffer *single-process-pipe*
        }
        exec R
    }
}

define-command math -docstring "
math: performs integer arithmetic on selections individually
" %{
    # strip leading zeros because shell interprets them as octal (whyyyyyyyy)
    try %{ exec -draft 's\b0+<ret>d' }
    # not sure why the '$' need escaping
    single-process-pipe 'sh -c "while read val; do echo \$(( \$val )); done"'
}

# pad each selection
# $1: character to pad with (default <space>)
# $2: resulting length (default length of the biggest input)
define-command -params ..2 pad -docstring "
pad [<char>] [<length>]: pad selections
The selections are padded to the left using <char> (defaults to <space>)
If <length> is not specified, the selections are padded to match the length of the longest selection
" %{
    eval -save-regs 'pc' %{
        eval %sh{
            printf "set-register p '%s'\n" "${1- }"
            printf "set-register c '%s'\n" "${2-0}"
        }
        single-process-pipe "awk '
        BEGIN {
            L = %reg{c}
        }
        // {
            l[lines++] = $0;
            if (length > L) { L = length }
        }
        END {
            for(i = 0; i < lines; ++i) {
                for (j = 0; j < L - length(l[i]); ++j) {
                    printf(""%reg{p}"")
                }
                print(l[i])
            }
        }'"
    }
}


define-command -hidden -params 1 single-process-pipe %{
    eval -no-hooks -save-regs '|"' %{
        eval -draft %{
            exec -save-regs '' y
            edit -scratch *single-process-pipe*
            exec <a-P>i<ret><esc>ggd
            set-register '|' %arg{1}
            exec '%|<ret>'
            exec -save-regs '' '%<a-s>Hy'
        }
        delete-buffer *single-process-pipe*
        exec R
    }
}

define-command math -docstring "
math: performs integer arithmetic on selections individually
" %{
    # strip leading zeros because the shell interprets them as octal (whyyyyyyyy)
    try %{ exec -draft '1s\b(0+)[.1-9]<ret>d' }
    single-process-pipe "while read val; do echo $(( $val )); done"
}

define-command -params ..2 pad -docstring "
pad [<char>] [<length>]: pads selections
The selections are padded to the left using <char> (defaults to <space>)
If <length> is not specified, the selections are padded to match the length of the longest selection
" %{
    eval -save-regs 'pc' %{
        eval %sh{
            char="${1- }"
            [ "${#char}" -eq 1 ] || { printf "fail 'Expected a character'"; exit; }
            length="${2-0}"
            [ "$length" -ge 0 ] || { printf "fail 'Expected a number'"; exit; }
            printf "reg p '%s'\n" "$char"
            printf "reg c '%s'\n" "$length"
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

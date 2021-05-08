declare-option -hidden str number_comparison_install_path %sh{dirname "$kak_source"}

define-command number-comparison -params .. -docstring "
number-comparison [<switches>] <operator> <number>
Switches:
    -no-bounds-check: The surrounding with lookarounds is disabled
    -no-negative: The matching of negative numbers is disabled
    -no-decimal: The matching of decimal numbers is disabled
    -register <reg>: The register <reg> (instead of /) will be used to store the result
    -prepend <pre>: The resulting regex is prefixed with <pre>
    -append <post>: The resulting regex is suffixed with <post>
" -shell-script-candidates %{
    printf '%s\n' -register -no-bounds-check -no-negative -no-decimal -prepend -append
} %{
    eval %sh{
        NOAUTOCOMPARE=''
        . "$kak_opt_number_comparison_install_path"/number-comparison-regex.sh

        arg_num=0
        register='/'
        op=''
        number=''
        boundaries='y'
        prefix=''
        suffix=''
        accept_switch='y'
        while [ $# -ne 0 ]; do
            arg_num=$((arg_num + 1))
            arg=$1
            shift
            if [ "$accept_switch" = 'y' ]; then
                got_switch='y'
                if [ "$arg" = '-register' ]; then
                    if [ $# -eq 0 ]; then
                        echo 'fail "Missing argument to -register"'
                        exit 1
                    fi
                    # the set-register will later check that it's a valid one
                    arg_num=$((arg_num + 1))
                    register=$1
                    shift
                elif [ "$arg" = '-no-bounds-check' ]; then
                    boundaries='n'
                elif [ "$arg" = '-no-negative' ]; then
                    with_negative='n'
                elif [ "$arg" = '-no-decimal' ]; then
                    with_decimal='n'
                elif [ "$arg" = '-prepend' ]; then
                    if [ $# -eq 0 ]; then
                        echo 'fail "Missing argument to -prepend"'
                        exit 1
                    fi
                    arg_num=$((arg_num + 1))
                    prefix=$1
                    shift
                elif [ "$arg" = '-append' ]; then
                    if [ $# -eq 0 ]; then
                        echo 'fail "Missing argument to -append"'
                        exit 1
                    fi
                    arg_num=$((arg_num + 1))
                    suffix=$1
                    shift
                elif [ "$arg" = '--' ]; then
                    accept_switch='n'
                else
                    accept_switch='n'
                    got_switch='n'
                fi
                [ $got_switch = 'y' ] && continue
            fi
            if [ -z "$op" ]; then
                if ! parse_operator "$arg"; then
                    printf "fail \"Invalid operator '%%arg{%s}'\"" "$arg_num"
                    exit 1
                fi
                op=$arg
            elif [ -z "$number" ]; then
                if ! parse_number "$arg"; then
                    printf "fail \"Invalid number '%%arg{%s}'\"" "$arg_num"
                    exit 1
                fi
                number="$arg"
            else
                printf "fail \"Unrecognized extra parameter '%%arg{%s}'\"" "$arg_num"
                exit 1
            fi
        done
        if [ -z "$op" ]; then
            echo 'fail "Missing operator"'
            exit 1
        elif [ -z "$number" ]; then
            echo 'fail "Missing number"'
            exit 1
        fi
        if ! can_compare; then
            echo 'fail "Invalid comparison"'
        fi
        # the generated regex shouldn't contain any ' ... I think
        printf "set-register %s '" "$register"
        printf '%s' "$prefix"
        if [ "$boundaries" = y ]; then
            printf '(?<![0-9'
            [ "$with_negative" = 'y' ] && printf '-'
            [ "$with_decimal" = 'y' ] && printf '.'
            printf '])'
        fi
        compare "$op" "$number"
        if [ "$boundaries" = y ]; then
            printf '(?![0-9'
            [ "$with_decimal" = 'y' ] && printf '.'
            printf '])'
        fi
        printf '%s' "$suffix"
        printf "'\n"
        printf "echo -markup \"{Information}{\}register '%s' set to '%%reg{%s}'\"\n" "$register" "$register"
    }
}

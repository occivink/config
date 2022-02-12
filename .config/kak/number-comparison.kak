declare-option -hidden str number_comparison_helper_script %sh{ printf '%s/%s' "${kak_source%/*}" "number-comparison-regex.sh" }

define-command number-comparison -params .. -docstring "
number-comparison [<switches>] <operator> <number>: Generates a regular expression that matches a number range
Switches:
    -no-bounds-check: The surrounding with lookarounds is disabled
    -no-negative: The matching of negative numbers is disabled
    -no-decimal: The matching of decimal numbers is disabled
    -base <base>: The input number is interpreted in base <base>, and the resulting regex will match numbers in the same base
    -register <reg>: The register <reg> (instead of /) will be used to store the result
    -prepend <pre>: The resulting regex is prefixed with <pre>
    -append <post>: The resulting regex is suffixed with <post>
" -shell-script-candidates %{
    printf '%s\n' -no-bounds-check -no-negative -no-decimal -base -register -prepend -append
} %{
    eval %sh{
        NOAUTOCOMPARE=''
        . "$kak_opt_number_comparison_helper_script"

        arg_num=0
        register='/'
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
                    arg_num=$((arg_num + 1))
                    # the set-register will later check that it's a valid one
                    register=$1
                    shift
                elif [ "$arg" = '-base' ]; then
                    if [ $# -eq 0 ]; then
                        echo 'fail "Missing argument to -base"'
                        exit 1
                    fi
                    arg_num=$((arg_num + 1))
                    if ! parse_base "$1"; then
                        printf "fail \"Invalid base '%%arg{%s}'\"" "$arg_num"
                        exit 1
                    fi
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
            elif [ -z "$num" ]; then
                if ! parse_number "$arg"; then
                    printf "fail \"Invalid number '%%arg{%s}'\"" "$arg_num"
                    exit 1
                fi
            else
                printf "fail \"Unrecognized extra parameter '%%arg{%s}'\"" "$arg_num"
                exit 1
            fi
        done
        if [ -z "$op" ]; then
            echo 'fail "Missing operator"'
            exit 1
        elif [ -z "$num" ]; then
            echo 'fail "Missing number"'
            exit 1
        fi
        if ! can_compare; then
            echo 'fail "Invalid comparison"'
        fi
        # the generated regex shouldn't contain any ' ... I think
        printf "set-register %s '" "$register"
        printf '%s' "$prefix"
        any_digit_no_bracket=${any_digit%]}
        any_digit_no_bracket=${any_digit_no_bracket#[}
        if [ "$boundaries" = y ]; then
            printf '(?<![%s' "$any_digit_no_bracket"
            [ "$with_negative" = 'y' ] && printf '-'
            [ "$with_decimal" = 'y' ] && printf '.'
            printf '])'
        fi
        compare "$op" "$number"
        if [ "$boundaries" = y ]; then
            printf '(?![%s' "$any_digit_no_bracket"
            [ "$with_decimal" = 'y' ] && printf '.'
            printf '])'
        fi
        printf '%s' "$suffix"
        printf "'\n"
        printf "echo -markup \"{Information}{\}register '%s' set to '%%reg{%s}'\"\n" "$register" "$register"
    }
}

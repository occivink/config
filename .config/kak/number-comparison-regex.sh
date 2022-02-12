#!/bin/sh

## variables to control the script
with_negative='y'
with_decimal='y'
base=10 # must be between 2 and 16 (inclusive)

## internal variables, after parsing the user input
op=''

sign=''
num=''
int=''
dec=''

is_zero=''

## helpers for base handling
max_digit=''          # 9 for base 10, 4 for base 5, f for base 16 and so on
any_digit=''          # \d for base 10, [0-4] for base 5, [\dA-Fa-f] for base 16 and so on
any_nonzero_digit=''  # same as above, except without 0

parse_base()
{
    case "$1" in
       *[!0-9]*) return 1 ;;
       *) ;;
    esac
    if [ "$1" -lt 2 ] || [ "$1" -gt 16 ]; then
        return 1
    fi
    base=$1
    case "$base" in
        2) max_digit=1                   ; any_digit='[01]'             ; any_nonzero_digit='1'                 ;;
        [3-9]) max_digit="$((base - 1))" ; any_digit="[0-${max_digit}]" ; any_nonzero_digit="[1-${max_digit}]"  ;;
        10) max_digit=9                  ; any_digit='\d'               ; any_nonzero_digit='[1-9]'             ;;
        11) max_digit=a                  ; any_digit='[\dAa]'           ; any_nonzero_digit='[1-9Aa]'           ;;
        12) max_digit=b                  ; any_digit='[\dA-Ba-b]'       ; any_nonzero_digit='[1-9A-Ba-b]'       ;;
        13) max_digit=c                  ; any_digit='[\dA-Ca-c]'       ; any_nonzero_digit='[1-9A-Ca-c]'       ;;
        14) max_digit=d                  ; any_digit='[\dA-Da-d]'       ; any_nonzero_digit='[1-9A-Da-d]'       ;;
        15) max_digit=e                  ; any_digit='[\dA-Ea-e]'       ; any_nonzero_digit='[1-9A-Ea-e]'       ;;
        16) max_digit=f                  ; any_digit='[\dA-Fa-f]'       ; any_nonzero_digit='[1-9A-Fa-f]'       ;;
        *) exit 2 ;;
    esac
    return 0
}

parse_base "$base" # re-parse the default base, such that the helper variables are set

parse_operator()
{
    op_maybe="$1"
    case "$op_maybe" in
      "<") ;;
      "<=") ;;
      ">") ;;
      ">=") ;;
      "=") ;;
      "!=") ;;
      "==") op_maybe='=' ;;
      "le") op_maybe='<=' ;;
      "lt") op_maybe='<' ;;
      "ge") op_maybe='>=' ;;
      "gt") op_maybe='>' ;;
      "eq") op_maybe='=' ;;
      "ne") op_maybe='!=' ;;
      *) return 1 ;;
    esac
    op="$op_maybe"
    return 0
}

parse_number()
{
    [ "$1" = '' ] && return 1;

    # parse sign
    num="$1"
    case "$num" in
      "+"*) num=${num#+} ; sign='+' ;;
      "-"*) num=${num#-} ; sign='-' ;;
      *) sign="+" ;;
    esac

    if [ "$with_negative" != 'y' ] && [ "$sign" = '-' ]; then
        return 1
    fi

    # parse integral and decimal part
    int=${num%.*}
    dec=${num#*.}
    if [ "$dec" = "$num" ]; then
        # no decimal part
        dec=''
    else
        if [ "$with_decimal" != 'y' ]; then
            return 1
        fi
    fi
    if [ "$int" = '' ] && [ "$dec" = '' ]; then
        return 1
    fi

    # remove leading zeroes of integral part
    tmp="$int"
    while :; do
        int=${tmp#0}
        [ "$tmp" = "$int" ] && break
        tmp=$int
    done
    [ "$int" = '' ] && int='0'

    # validate and normalize (set to lowercase) integral part
    tmp="$int"
    rest=''
    normalized=''
    char=''
    while [ -n "$tmp" ]; do
        rest="${tmp#?}"
        char="${tmp%"$rest"}"
        case "$char" in
            [0-1]) ;;
            [2-9]) [ "$base" -gt "$char" ] || return 1;;
            A|a) [ "$base" -gt 10 ] || return 1; char='a';;
            B|b) [ "$base" -gt 11 ] || return 1; char='b';;
            C|c) [ "$base" -gt 12 ] || return 1; char='c';;
            D|d) [ "$base" -gt 13 ] || return 1; char='d';;
            E|e) [ "$base" -gt 14 ] || return 1; char='e';;
            F|f) [ "$base" -gt 15 ] || return 1; char='f';;
            *) return 1;;
        esac
        normalized="${normalized}${char}"
        tmp="$rest"
    done
    int="$normalized"

    # remove trailing zeroes of decimal part
    tmp="$dec"
    while :; do
        dec=${tmp%0}
        [ "$tmp" = "$dec" ] && break
        tmp=$dec
    done

    # validate and normalize (set to lowercase) decimal part
    tmp="$dec"
    rest=''
    normalized=''
    char=''
    while [ -n "$tmp" ]; do
        rest="${tmp#?}"
        char="${tmp%"$rest"}"
        case "$char" in
            [0-1]) ;;
            [2-9]) [ "$base" -gt "$char" ] || return 1;;
            A|a) [ "$base" -gt 10 ] || return 1; char='a';;
            B|b) [ "$base" -gt 11 ] || return 1; char='b';;
            C|c) [ "$base" -gt 12 ] || return 1; char='c';;
            D|d) [ "$base" -gt 13 ] || return 1; char='d';;
            E|e) [ "$base" -gt 14 ] || return 1; char='e';;
            F|f) [ "$base" -gt 15 ] || return 1; char='f';;
            *) return 1;;
        esac
        normalized="${normalized}${char}"
        tmp="$rest"
    done
    dec="$normalized"

    if [ "$int" = '0' ] && [ "$dec" = '' ]; then
        # turn -0 into +0
        [ "$sign" = "-" ] && sign='+'
        is_zero=y
    else
        is_zero=n
    fi

    # debug code
    # printf '%s%s.%s\n' $sign $int $dec
    return 0
}

can_compare()
{
    if [ "$op" = '<' ] && [ "$is_zero" = 'y' ] && [ "$with_negative" != "y" ]; then
        return 1
    else
        return 0
    fi
}

# print a regex digit range, spanning [$1-$2]
# accounts for possible bases (lower/upper case) and values
# for example, if $1 == $2, only $1 is printed
print_digit_range()
{
    if [ "$base" -le 10 ]; then
        if [ "$1" = 0 ] && [ "$2" = 9 ]; then
            printf '\d'
        elif [ "$1" = "$2" ]; then
            printf "%s" "$1"
        else
            printf "[%s-%s]" "$1" "$2"
        fi
        return
    fi
    # base > 10
    caps1=''
    caps2=''
    case "$1" in
        a) caps1=A ;;
        b) caps1=B ;;
        c) caps1=C ;;
        d) caps1=D ;;
        e) caps1=E ;;
        f) caps1=F ;;
    esac
    case "$2" in
        a) caps2=A ;;
        b) caps2=B ;;
        c) caps2=C ;;
        d) caps2=D ;;
        e) caps2=E ;;
        f) caps2=F ;;
    esac
    if [ "$1" = "$2" ]; then
        case "$1" in
            [0-9]) printf '%s' "$1" ;;
            [a-f]) printf '[%s%s]' "$caps1" "$1" ;;
            *) exit 2 ;;
        esac
    else
        case "$1$2" in
            09)         printf '\d' ;;
            [0-9][0-9]) printf '[%s-%s]' "$1" "$2" ;;
            0a)         printf '[\dAa]' ;;
            [1-8]a)     printf '[%s-9Aa]' "$1" ;;
            9a)         printf '[9Aa]' ;;
            0[b-f])     printf '[\dA-%sa-%s]' "$caps2" "$2" ;;
            [1-8][b-f]) printf '[%s-9A-%sa-%s]' "$1" "$caps2" "$2" ;;
            9[b-f])     printf '[9A-%sa-%s]' "$caps2" "$2" ;;
            [a-f][a-f]) printf '[%s-%s%s-%s]' "$caps1" "$caps2" "$1" "$2" ;;
            *) exit 2 ;;
        esac
    fi
}

#
print_bigger_digit()
{
    case "$1" in
        [0-8]) print_digit_range "$(($1 + 1))" "$max_digit" ;;
        9) print_digit_range "a" "$max_digit" ;;
        a) print_digit_range "b" "$max_digit" ;;
        b) print_digit_range "c" "$max_digit" ;;
        c) print_digit_range "d" "$max_digit" ;;
        d) print_digit_range "e" "$max_digit" ;;
        e) print_digit_range "f" "$max_digit" ;;
        *) exit 2 ;;
    esac
}

print_smaller_digit()
{
    case "$1" in
        [1-9]) print_digit_range "0" "$(($1 - 1))" ;;
        a) print_digit_range "0" "9" ;;
        b) print_digit_range "0" "a" ;;
        c) print_digit_range "0" "b" ;;
        d) print_digit_range "0" "c" ;;
        e) print_digit_range "0" "d" ;;
        f) print_digit_range "0" "e" ;;
        *) exit 2 ;;
    esac
}

print_smaller_digit_nonzero()
{
    case "$1" in
        [2-9]) print_digit_range "1" "$(($1 - 1))" ;;
        a) print_digit_range "1" "9" ;;
        b) print_digit_range "1" "a" ;;
        c) print_digit_range "1" "b" ;;
        d) print_digit_range "1" "c" ;;
        e) print_digit_range "1" "d" ;;
        f) print_digit_range "1" "e" ;;
        *) exit 2 ;;
    esac
}

# reprint a number, accounting that different spellings are possible (i.e. with base >10 and uppercase)
print_number()
{
    if [ "$base" -le 10 ]; then
        printf -- '%s' "$1"
    else
        # iterate over each digit, and print
        # prefix variables with the function name, so as not to overwrite variables from the caller
        print_number_tmp="$1"
        print_number_rest=''
        while [ -n "$print_number_tmp" ]; do
            print_number_rest="${print_number_tmp#?}"
            print_number_digit="${print_number_tmp%"$print_number_rest"}"
            case "$print_number_digit" in
                [0-9]) printf -- '%s' "$print_number_digit" ;;
                a) printf -- '[Aa]' ;;
                b) printf -- '[Bb]' ;;
                c) printf -- '[Cc]' ;;
                d) printf -- '[Dd]' ;;
                e) printf -- '[Ee]' ;;
                f) printf -- '[Ff]' ;;
                *) exit 2;;
            esac
            print_number_tmp="$print_number_rest"
        done
    fi
}

# print a regex repetition
# if only one argument is passed, of exactly {$1} times
# if two arguments are passed, of {$1,$2} times
# if $2 is omitted, it is considered inf
# * or + are used whenever possible
print_repeat()
{
    if [ $# -eq 1 ]; then
        if [ "$1" != 1 ]; then
            printf -- '{%s}' "$1"
        fi
    elif [ "$2" = "" ]; then
        if [ "$1" = 0 ]; then
            printf -- '*'
        elif [ "$1" = 1 ]; then
            printf -- '+'
        else
            printf -- '{%s,}' "$1"
        fi
    elif [ "$1" = "$2" ]; then
        if [ "$1" != 1 ]; then
            printf -- '{%s}' "$1"
        fi
    else
        printf -- '{%s,%s}' "$1" "$2"
    fi
}

any_zero()
{
    if [ "$with_decimal" = 'y' ]; then
        printf -- '0+(\.0*)?|\.0+'
    else
        printf -- '0+'
    fi
}

any_number()
{
    if [ "$with_decimal" = 'y' ]; then
        # for base 10, '\d+(\.\d*)?|\.\d+'
        printf '%s+(\.%s*)?|\.%s+' "$any_digit" "$any_digit" "$any_digit"
    else
        printf '%s+' "$any_digit"
    fi
}

any_positive_number()
{
    if [ "$with_decimal" = 'y' ]; then
        # for base 10, '0*[1-9]\d*(\.\d*)?|0*\.0*[1-9]\d*'
        printf '0*%s%s*(\.%s*)?|0*\.0*%s%s*' "$any_nonzero_digit" "$any_digit" "$any_digit" "$any_nonzero_digit" "$any_digit"
    else
        printf '0*%s%s*' "$any_nonzero_digit" "$any_digit"
    fi
}

gt()
{
    printf '0*'
    [ "$with_decimal" = 'y' ] && printf '('

    # first, numbers that have a bigger integral part
    printf '(%s%s' "$any_nonzero_digit" "$any_digit"
    print_repeat "${#int}" ''

    digitsbefore=''
    digitsafter=''
    tmp="$int"
    while [ -n "$tmp" ]; do
        digitsafter="${tmp#?}"
        digit="${tmp%"$digitsafter"}"

        if [ "$digit" != "$max_digit" ]; then
            printf '|'
            print_number "$digitsbefore"
            print_bigger_digit "$digit"
            if [ -n "$digitsafter" ]; then
                printf '%s' "$any_digit"
                print_repeat "${#digitsafter}"
            fi
        fi

        tmp="$digitsafter"
        digitsbefore="${digitsbefore}${digit}"
    done
    printf ')'

    if [ "$with_decimal" = 'y' ]; then
        # accept any decimal part
        printf '(\.%s*)?' "$any_digit"

        # then, numbers that have the same integral part, but a bigger decimal part
        printf '|'
        print_number "$int"
        [ $int = 0 ] && printf '?'

        if [ "$dec" = '' ]; then
            printf '\.%s*%s%s*' "$any_digit" "$any_nonzero_digit" "$any_digit"
        else
            printf '\.('
            print_number "$dec"
            printf '%s*%s' "$any_digit" "$any_nonzero_digit"

            digitsbefore=''
            digitsafter=''
            tmp="$dec"
            while [ -n "$tmp" ]; do
                digitsafter="${tmp#?}"
                digit="${tmp%"$digitsafter"}"

                if [ $digit != "$max_digit" ]; then
                    printf '|'
                    print_number "$digitsbefore"
                    print_bigger_digit "$digit"
                fi

                tmp="$digitsafter"
                digitsbefore="${digitsbefore}${digit}"
            done
            printf ')%s*' "$any_digit"
        fi
        printf ')'
    fi
}

lt()
{
    if [ "$is_zero" = 'y' ]; then
        exit 2
    fi

    printf '0*('

    had_int='n'

    # number with a smaller integral part (must be >0)
    if [ "$int" != 0 ]; then
        had_int='y'
        if [ "$int" = 1 ]; then
            printf '0'
        else
            if [ "${#int}" = 1 ]; then
                # single-digit number
                print_smaller_digit "$int"
            else
                printf '('
                # numbers that have fewer digits (duh)
                printf '%s' "$any_digit"
                print_repeat '1' "$((${#int} - 1))"
                # same number of digits, but that are smaller
                digitsbefore=''
                digitsafter=''
                tmp="$int"
                while [ -n "$tmp" ]; do
                    digitsafter="${tmp#?}"
                    digit="${tmp%"$digitsafter"}"

                    if [ $digit != 0 ]; then
                        if [ $digit != 1 ] || [ -n "$digitsbefore" ]; then
                            printf '|'
                            print_number "$digitsbefore"
                            if [ -n "$digitsbefore" ]; then
                                print_smaller_digit "$digit"
                            else
                                print_smaller_digit_nonzero "$digit"
                            fi
                            if [ -n "$digitsafter" ]; then
                                printf '%s' "$any_digit"
                                print_repeat ${#digitsafter}
                            fi
                        fi
                    fi

                    tmp="$digitsafter"
                    digitsbefore="${digitsbefore}${digit}"
                done
                printf ')'
            fi
        fi
        if [ "$with_decimal" = 'y' ]; then
            # accept any decimal part
            printf '(\.%s*)?' "$any_digit"
            # as well as no integral part (= 0)
            printf '|\.%s+' "$any_digit"
        fi
    fi

    if [ "$with_decimal" = 'y' ] && [ "$dec" != "" ]; then
        [ "$had_int" = y ] && printf '|'

        # then, numbers that have the same integral part, but a smaller decimal part
        if [ "$int" = 0 ]; then
            # in the case of 0.xxx, the integral part is optional
            printf '0|'
        else
            print_number "$int"
        fi
        # the decimal part is of course optional, since no decimal part => smaller
        printf '((\.0*)?|\.('

        digitsbefore=''
        digitsafter=''
        alternation=''
        tmp="$dec"
        while [ -n "$tmp" ]; do
            digitsafter="${tmp#?}"
            digit="${tmp%"$digitsafter"}"

            if [ $digit != 0 ]; then
                printf '%s' "$alternation"
                alternation='|'
                print_number "$digitsbefore"
                print_smaller_digit "$digit"
            fi

            tmp="$digitsafter"
            digitsbefore="${digitsbefore}${digit}"
        done

        printf ')%s*)' "$any_digit"
    fi
    printf ')'
}

equal()
{
    if [ "$with_decimal" = 'y' ]; then
        if [ "$is_zero" = 'y' ]; then
            printf -- '0+(\.0*)?|\.0+'
        elif [ $int = 0 ]; then
            printf -- '0*\.'
            print_number "$dec"
            printf -- '0*'
        elif [ "$dec" = '' ]; then
            printf -- '0*'
            print_number "$int"
            printf -- '(\.0*)?'
        else
            printf -- '0*'
            print_number "$int"
            printf -- '\.'
            print_number "$dec"
            printf -- '0*'
        fi
    else
        printf -- '0*'
        print_number "$int"
    fi
}

compare()
{

    if [ "$op" = '' ]; then
        return 1
    fi
    if [ "$sign" = '' ] || [ "$num" = '' ] || [ "$int" = '' ]; then
        return 1
    fi

    if [ "$op" = '>' ] || [ "$op" = '>=' ]; then
        if [ "$is_zero" = 'y' ]; then
            if [ "$op" = '>=' ]; then
                printf -- '('
                if [ "$with_negative" = 'y' ]; then
                    # tricky -0 case
                    printf -- '-('
                    any_zero
                    printf -- ')|'
                fi
                any_number
                printf ')'
            elif [ "$op" = '>' ]; then
                printf '('
                any_positive_number
                printf ')'
            fi
        elif [ "$sign" = '+' ]; then
            printf '('
            gt
            if [ "$op" = '>=' ]; then
                printf '|'
                equal
            fi
            printf ')'
        elif [ "$sign" = '-' ]; then
            # with_negative == y
            printf -- '(-('
            lt
            if [ "$op" = '>=' ]; then
                printf '|'
                equal
            fi
            printf  ')|'
            any_number
            printf ')'
        fi
    elif [ "$op" = "<" ] || [ "$op" = "<=" ]; then
        if [ "$is_zero" = 'y' ]; then
            if [ "$op" = '<' ]; then
                if [ "$with_negative" = 'y' ]; then
                    printf -- '-('
                    any_positive_number
                    printf ')'
                else
                    return 1
                fi
            elif [ "$op" = '<=' ]; then
                printf '('
                any_zero
                if [ "$with_negative" = 'y' ]; then
                    printf -- '|-('
                    any_number
                    printf ')'
                fi
                printf ')'
            fi
        elif [ "$sign" = '+' ]; then
            printf '('
            lt
            if [ "$op" = '<=' ]; then
                printf '|'
                equal
            fi
            if [ "$with_negative" = 'y' ]; then
                printf  '|-('
                any_number
                printf ')'
            fi
            printf ')'
        elif [ "$sign" = '-' ]; then
            # with_negative == y
            printf -- '-'
            printf '('
            gt
            if [ "$op" = '<=' ]; then
                printf '|'
                equal
            fi
            printf ')'
        fi
    elif [ "$op" = "=" ]; then
        [ "$sign" = '-' ] && printf -- '-'
        [ "$with_negative" ] && [ "$is_zero" = 'y' ] && printf -- '-?'
        printf -- '('
        equal
        printf -- ')'
    elif [ "$op" = "!=" ]; then
        # special case for 0... again
        if [ "$is_zero" = 'y' ]; then
            [ "$with_negative" = 'y' ] && printf -- '-?'
            printf -- '('
            any_positive_number
            printf ')'
        elif [ "$sign" = '+' ]; then
            printf '('
            gt
            printf -- '|'
            lt
            if [ "$with_negative" = y ]; then
                printf '|-('
                any_number
                printf ')'
            fi
            printf ')'
        elif [ "$sign" = '-' ]; then
            # with_negative == y
            printf -- '(-('
            gt
            printf -- ')|-('
            lt
            printf -- ')|'
            any_number
            printf ')'
        fi
    fi
    return 0
}

# silly mechanism to disable the auto-comparison when sourcing the script
if [ -n "${NOAUTOCOMPARE+a}" ]; then
    :
else
    for arg do
        if [ "$arg" = '--help' ] || [ "$arg" = '-h' ]; then
            echo 'Generate a regular expression that matches a range of number'
            echo
            echo 'USAGE:'
            echo '    number-comparison-regex [OPTIONS] [OPERATOR] [NUMBER]'
            echo
            echo 'OPERATOR is one of <, <=, >, >=, = or != (or the shell equivalents used by "test")'
            echo 'NUMBER is the number to be compared to'
            echo
            echo 'OPTIONS:'
            echo '    -n, --no-negative     Only consider positive numbers (input and output)'
            echo '    -d, --no-decimal      Only consider integral number (input and output)'
            echo '    -b, --base BASE       Specify the number base, must be between 2 and 16 (input and output)(default: 10)'
            echo '    -h, --help            Print this help message'
            exit 0
        fi
    done
    if [ $# -lt 2 ]; then
        echo "Missing arguments, use '--help' for more information"
        exit 1
    fi

    while [ $# -ne 0 ]; do
        arg="$1"
        shift
        if [ "$arg" = '--no-negative' ] || [ "$arg" = '-n' ]; then
            with_negative='n'
        elif [ "$arg" = '--no-decimal' ] || [ "$arg" = '-d' ] ; then
            with_decimal='n'
        elif [ "$arg" = '--base' ] || [ "$arg" = '-b' ] ; then
            if [ $# -eq 0 ]; then
                echo "Expected a value for $arg"
                exit 1
            fi
            arg="$1"
            shift
            if ! parse_base "$arg"; then
                echo "$arg is not a valid base (must be between 2 and 16)"
                exit 1
            fi
        elif [ -z "$op" ]; then
            if ! parse_operator "$arg"; then
                echo "$arg is not a valid operator"
                exit 1
            fi
        elif [ -z "$num" ]; then
            if ! parse_number "$arg"; then
                echo "$arg is not a valid base-$base number"
                exit 1
            fi
        else
            echo "Unrecognized argument: $arg"
            exit 1
        fi
    done
    if [ -z "$op" ]; then
        echo "Missing operator"
        exit 1
    elif [ -z "$num" ]; then
        echo "Missing number"
        exit 1
    fi
    if ! can_compare ; then
        echo "Invalid comparison: $op $num"
        exit 1
    fi
    compare
    if [ $? != 0 ]; then
        echo "Internal error"
        exit 2
    else
        printf '\n'
    fi
fi

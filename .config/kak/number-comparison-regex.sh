#!/bin/sh

op=''
strict=''
sign=''
num=''
int=''
dec=''
is_zero=''

parse_operator()
{
    case "$1" in
      "<") strict='y' ;;
      "<=") strict='n' ;;
      ">") strict='y' ;;
      ">=") strict='n' ;;
      "=") strict='y' ;;
      "==") strict='y' ;;
      "!=") strict='y' ;;
      *) return 1 ;;
    esac
    op="$1"
    [ "$op" = '==' ] && op='='
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

    # parse integral and decimal part
    int=${num%.*}
    dec=${num#*.}
    [ "$dec" = "$num" ] && dec=''
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

    # validate integral part
    case "$int" in
       *[!0-9]*|'') return 1 ;;
       *) ;;
    esac

    # remove trailing zeroes of decimal part
    tmp="$dec"
    while :; do
        dec=${tmp%0}
        [ "$tmp" = "$dec" ] && break
        tmp=$dec
    done

    # validate decimal part
    if [ "$dec" != "" ]; then
        case "$dec" in
           *[!0-9]*|'') return 1 ;;
           *) ;;
        esac
    fi

    if [ "$int" = '0' ] && [ "$dec" = '' ]; then
        # turn -0 into +0
        [ "$sign" = "-" ] && sign='+'
        is_zero=y
    else
        is_zero=n
    fi

    # debug code
    #printf '%s%s.%s\n' $sign $int $dec
}

print_range()
{
    if [ $1 = $2 ]; then
        printf '%s' "$1"
    elif [ $1 = 0 ] && [ $2 = 9 ]; then
        printf '\d'
    else
        printf "[%s-%s]" "$1" "$2"
    fi
}

print_repeat()
{
    if [ $# -eq 1 ]; then
        if [ "$1" != 1 ]; then
            printf '{%s}' "$1"
        fi
    elif [ "$2" = "" ]; then
        if [ "$1" = 0 ]; then
            printf '*'
        elif [ "$1" = 1 ]; then
            printf '+'
        else
            printf '{%s,}' "$1"
        fi
    elif [ "$1" = "$2" ]; then
        if [ "$1" != 1 ]; then
            printf '{%s}' "$1"
        fi
    else
        printf '{%s,%s}' "$1" "$2"
    fi
}

any_zero()
{
    printf -- '0+(\.0*)?|\.0+'
}

any_number()
{
    printf -- '\d+(\.\d*)?|\.\d+'
}

any_positive_number()
{
    printf -- '0*[1-9]\d*(\.\d*)?|\.0*[1-9]\d*'
}

gt()
{
    printf '0*('

    # first, numbers that have a bigger integral part
    printf '([1-9]\d'
    print_repeat "${#int}" ''

    digitsbefore=''
    digitsafter=''
    tmp="$int"
    while [ -n "$tmp" ]; do
        digitsafter="${tmp#?}"
        digit="${tmp%"$digitsafter"}"

        if [ $digit -lt 9 ]; then
            printf '|%s' "$digitsbefore"
            print_range "$((digit + 1))" 9
            if [ -n "$digitsafter" ]; then
                printf '\d'
                print_repeat "${#digitsafter}"
            fi
        fi

        tmp="$digitsafter"
        digitsbefore="${digitsbefore}${digit}"
    done
    # accept any decimal part
    printf ')(\.\d+)?'

    # then, numbers that have the same integral part, but a bigger decimal part
    printf '|%s\.(' "$int"
    printf '%s\d*[1-9]' "$dec"

    digitsbefore=''
    digitsafter=''
    tmp="$dec"
    while [ -n "$tmp" ]; do
        digitsafter="${tmp#?}"
        digit="${tmp%"$digitsafter"}"

        if [ $digit -lt 9 ]; then
            printf '|%s' "$digitsbefore"
            print_range "$((digit + 1 ))" 9
        fi

        tmp="$digitsafter"
        digitsbefore="${digitsbefore}${digit}"
    done
    printf ')\d*'
    printf ')'
}

lt()
{
    if [ "$is_zero" = 'y' ]; then
        exit 1
    fi

    printf '0*('

    had_int='n'

    # number with a smaller integral part (must be >0)
    if [ "$int" -gt 0 ]; then
        had_int='y'
        if [ "$int" -gt 1 ]; then
            if [ "${#int}" -eq 1 ]; then
                print_range 0 "$((int - 1))"
            else
                printf '('
                # numbers that have fewer digits (duh)
                printf '\d'
                print_repeat '1' "$((${#int} - 1))"
                printf '|'
                # same number of digits, but that are smaller
                digitsbefore=''
                digitsafter=''
                tmp="$int"
                while [ -n "$tmp" ]; do
                    digitsafter="${tmp#?}"
                    digit="${tmp%"$digitsafter"}"

                    if [ $digit -eq 1 ] && [ -n "$digitsbefore" ] || [ $digit -gt 1 ]; then
                        printf '|%s' "$digitsbefore"
                        if [ -n "$digitsbefore" ]; then
                            print_range 0 "$((digit - 1))"
                        else
                            print_range 1 "$((digit - 1))"
                        fi
                        if [ -n "$digitsafter" ]; then
                            printf '\d'
                            print_repeat ${#digitsafter}
                        fi
                    fi

                    tmp="$digitsafter"
                    digitsbefore="${digitsbefore}${digit}"
                done
                printf ')'
            fi
        fi
        # accept any decimal part
        printf '(\.\d+)?'
    fi

    if [ "$dec" != "" ]; then
        [ "$had_int" = y ] && printf '|'

        # then, numbers that have the same integral part, but a smaller decimal part
        [ $int -gt 0 ] && printf '%s' "$int"
        printf '\.('

        digitsbefore=''
        digitsafter=''
        alternation=''
        tmp="$dec"
        while [ -n "$tmp" ]; do
            digitsafter="${tmp#?}"
            digit="${tmp%"$digitsafter"}"

            if [ $digit -ge 1 ]; then
                printf '%s%s' "$alternation" "$digitsbefore"
                alternation='|'
                print_range 0 "$((digit - 1))"
            fi
            # 0.0101
            #  .00
            #  .0100

            tmp="$digitsafter"
            digitsbefore="${digitsbefore}${digit}"
        done

        printf ')\d*'
    fi
    printf ')'
}

equal()
{
    if [ "$int" = 0 ] && [ "$dec" = '' ]; then
        printf -- '0+(\.0*)?|\.0+'
    elif [ $int = 0 ]; then
        printf -- '0*\.%s0*' "$dec"
    elif [ "$dec" = '' ]; then
        printf -- '0*%s(\.0*)?' "$int"
    else
        printf -- '0*%s\.%s0*' "$int" "$dec"
    fi
}

compare()
{

    if [ "$op" = '' ] || [ "$strict" = '' ]; then
        exit 1
    fi
    if [ "$sign" = '' ] || [ "$num" = '' ] || [ "$int" = '' ]; then
        exit 1
    fi

    if [ "$op" = '>' ] || [ "$op" = '>=' ]; then
        if [ "$is_zero" = 'y' ]; then
            if [ "$op" = '>=' ]; then
                # tricky -0 case
                printf -- '(-('
                any_zero
                printf -- ')|'
                any_number
                printf ')'
            else
                printf '('
                any_positive_number
                printf ')'
            fi
        elif [ "$sign" = '+' ]; then
            printf '('
            gt
            if [ "$strict" = 'n' ]; then
                printf '|'
                equal
            fi
            printf ')'
        elif [ "$sign" = '-' ]; then
            printf -- '(-('
            lt
            if [ "$strict" = 'n' ]; then
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
                printf -- '-('
                any_positive_number
                printf ')'
            else
                printf '('
                any_zero
                printf -- '|-('
                any_number
                printf '))'
            fi
        elif [ "$sign" = '+' ]; then
            printf '('
            lt
            if [ "$strict" = n ]; then
                printf '|'
                equal
            fi
            printf  '|-('
            any_number
            printf '))'
        elif [ "$sign" = '-' ]; then
            printf -- '-'
            printf '('
            gt
            if [ "$strict" = n ]; then
                printf '|'
                equal
            fi
            printf ')'
        fi
    elif [ "$op" = "=" ]; then
        [ "$sign" = '-' ] && printf -- '-'
        [ "$is_zero" = 'y' ] && printf -- '-?'
        printf -- '('
        equal
        printf -- ')'
    elif [ "$op" = "!=" ]; then
        # special case for 0... again
        if [ "$is_zero" = 'y' ]; then
            printf -- '-?('
            any_positive_number
            printf ')'
        elif [ "$sign" = '+' ]; then
            printf '('
            gt
            printf -- '|'
            lt
            printf '|-('
            any_number
            printf '))'
        else
            printf -- '(-('
            gt
            printf -- ')|-('
            lt
            printf -- ')|'
            any_number
            printf ')'
        fi
    fi
}

# silly mechanism to disable the auto-comparison when sourcing the script
if [ -n "${NOAUTOCOMPARE+a}" ]; then
    :
else
    if [ $# -ne 2 ]; then
        echo Missing arguments
        exit 1
    fi
    if ! parse_operator "$1"; then
        echo "$1" is not a valid operator
        exit 1
    fi
    if ! parse_number "$2"; then
        echo "$2" is not a valid number
        exit 1
    fi
    compare
    if [ $? -eq 0 ]; then
        printf '\n'
    else
        exit 1
    fi
fi

#123.123
#
#1-9\d\d\d
#1[3-9]\d
#12[4-9]
#123.[2-9]\d*
#123.1[3-9]\d*
#123.12[4-9]\d*

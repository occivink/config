#!/bin/sh

command_ms_per_char=70
command_ms_before_ret=600
command_ms_after_ret=500

text_ms_per_char=17
text_ms_end=1000

text_width=60

[ "$kak_session" = '' ] && echo 'kak_session not defined' && exit 1
[ "$kak_client" = '' ] && echo 'kak_client not defined' && exit 1

sleep_ms() {
    s=0
    ms=0
    if [ "$1" -lt 0 ]; then
        return
    elif [ "$1" -lt 10 ]; then
        ms=00$1
    elif [ "$1" -lt 100 ]; then
        ms=0$1
    elif [ $1 -lt 1000 ]; then
        ms=$1
    else
        s="${1%???}"
        ms="${1#$s}"
    fi
    sleep "${s}.${ms}"
}

type() {
    char="$1"
    [ "$char" = '' ] && return
    [ "$char" = "'" ] && char="''"
    [ "$char" = " " ] && char="<space>"
    [ "$char" = "-" ] && char="<minus>"
    printf "exec -with-maps -with-hooks -client '%s' '%s'" "$kak_client" "${char}" | kak -p "$kak_session"
}

exec_command() {
    full_text=":$1"
    next=""
    while [ -n "$full_text" ]; do
        next="${full_text#?}"
        char="${full_text%$next}"
        [ "${#char}" -eq 2 ] && char=${char%?}
        full_text="$next"
        #echo "$char"
        type "$char"
        sleep_ms "$command_ms_per_char"
    done
    sleep_ms "$command_ms_before_ret"
    type "<ret>"
    sleep_ms "$command_ms_after_ret"
}

info_progressive() {
    text="$1"
    duration="$2"
    title="$3"
    width="$text_width"
    if [ "${#text}" -gt "$width" ]; then
        full_text=$(printf '%s' "$text" | fmt "-w${width}")
    else
        width="${#text}"
        width=$(( width + 1 ))
        full_text="$text"
    fi

    characters="${#full_text}"

    cur_text=''
    line_char_count=0
    while [ -n "$full_text" ]; do
        next="${full_text#?}"
        char="${full_text%$next}"
        if [ "$char" = '
' ]; then
            line_char_count=0
        else
            line_char_count=$((line_char_count + 1))
        fi
        full_text="$next"

        [ "$char" = "'" ] && char="''"
        cur_text="${cur_text}${char}"
        {
            printf "eval -verbatim -client '%s' info '%s" "$kak_client" "$cur_text"
            sp=$((width - line_char_count))
            while [ "$sp" -gt 1 ]; do
                printf ' '
                sp=$((sp - 1))
            done
            printf "'"
        } | kak -p "$kak_session"
        sleep_ms "$text_ms_per_char"
    done
    sleep_ms "$text_ms_end"
}

while IFS= read -r string; do
    case "$string" in
        '#'*) ;;
        '')  ;;
        'exit') exit ;;
        'clippy-say '*)
            text="${string#clippy-say }"
            text_len="${#text}"
            info_progressive "$text" ''
            ;;
        'command '*)
            exec_command "${string#command }"
            ;;
        'type '*)
            arg="${string#type }"
            sleep_dur="${arg%% *}"
            what="${arg#* }"
            while :; do
                type "${what%% *}"
                [ "$what" = "${what#* }" ] && break
                what="${what#* }"
                sleep_ms "$sleep_dur"
            done
            ;;
        'sleep '*)
            sleep_ms "${string#sleep }"
            ;;
         *)
            echo "Unrecognized command $string"
            exit 1 ;;
    esac
done

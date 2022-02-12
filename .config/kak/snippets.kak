decl -hidden regex snippets_triggers_regex "\A\z" # doing <a-k>\A\z<ret> will always fail

hook global WinSetOption 'snippets=$' %{
    set window snippets_triggers_regex "\A\z"
}
hook global WinSetOption 'snippets=.+$' %{
    set window snippets_triggers_regex %sh{
        eval set -- "$kak_quoted_opt_snippets"
        if [ $(($#%3)) -ne 0 ]; then printf '\\\A\\\z'; exit; fi
        res=""
        while [ $# -ne 0 ]; do
            if [ -n "$2" ]; then
                if [ -z "$res" ]; then
                    res="$2"
                else
                    res="$res|$2"
                fi
            fi
            shift 3
        done
        if [ -z "$res" ]; then
            printf "\\\A\\\z"
        else
            printf '(%s)' "$res"
        fi
    }
}

def snippets-expand-trigger -params ..1 %{
    eval -save-regs '/snc' %{
        # -draft so that we don't modify anything in case of failure
        eval -draft %{
            # ideally early out in here to avoid going to the (expensive) shell scope
            eval %arg{1}
            # this shell scope generates a block that looks like this
            # except with single quotes instead of %{..}
            #
            # try %{
            #   reg / "\Atrig1\z"
            #   exec -draft <space><a-k><ret>d
            #   reg c "snipcommand1"
            # } catch %{
            #   reg / "\Atrig2\z"
            #   exec -draft <space><a-k><ret>d
            #   reg c "snipcommand2"
            # } catch %{
            #   ..
            # }
            eval %sh{
                quadrupleupsinglequotes()
                {
                    rest="$1"
                    while :; do
                        beforequote="${rest%%"'"*}"
                        if [ "$rest" = "$beforequote" ]; then
                            printf %s "$rest"
                            break
                        fi
                        printf "%s''''" "$beforequote"
                        rest="${rest#*"'"}"
                    done
                }

                eval set -- "$kak_quoted_opt_snippets"
                if [ $(($#%3)) -ne 0 ]; then exit; fi
                first=0
                while [ $# -ne 0 ]; do
                    if [ -z "$2" ]; then
                        shift 3
                        continue
                    fi
                    if [ $first -eq 0 ]; then
                        printf "try '\n"
                        first=1
                    else
                        printf "' catch '\n"
                    fi
                    # put the trigger into %reg{/} as \Atrig\z
                    printf "reg / ''\\\A"
                    # we`re at two levels of nested single quotes (one for try ".." catch "..", one for reg "..")
                    # in the arbitrary user input (snippet trigger and snippet name)
                    quadrupleupsinglequotes "$2"
                    printf "\\\z''\n"
                    printf "exec -draft <space><a-k><ret>d\n"
                    printf "reg n ''"
                    quadrupleupsinglequotes "$1"
                    printf "''\n"
                    printf "reg c ''"
                    quadrupleupsinglequotes "$3"
                    printf "''\n"
                    shift 3
                done
                printf "'"
            }
            # preserve the selections generated by the snippet, since -draft will discard them
            eval %reg{c}
            reg s %val{selections_desc}
        }
        eval select %reg{s}
        echo "Snippet '%reg{n}' expanded"
    }
}

hook global WinSetOption 'snippets_auto_expand=false$' %{
    rmhooks window snippets-auto-expand
}
hook global WinSetOption 'snippets_auto_expand=true$' %{
    rmhooks window snippets-auto-expand
    hook -group snippets-auto-expand window InsertChar .* %{
        try %{
            snippets-expand-trigger %{
                # we don't have to reset %reg{/} since the internal command does it
                # but normally we should
                reg / "%opt{snippets_triggers_regex}\z"
                # select the 10 previous character and abort if it doesn't end with a trigger
                # \z makes it so the trigger must be anchored to the cursor to be considered
                exec ';h10Hs<ret>'
            }
        }
    }
}

decl str-list snippets
# this one must be declared after the hook, otherwise it might not be enabled right away
decl bool snippets_auto_expand true

def snippets-impl -hidden -params 1.. %{
    eval %sh{
        use=$1
        shift 1
        index=4
        while [ $# -ne 0 ]; do
            if [ "$1" = "$use" ]; then
                printf "eval %%arg{%s}" "$index"
                exit
            fi
            index=$((index + 3))
            shift 3
        done
        printf "fail 'Snippet not found'"
    }
}

def snippets -params 1 -shell-script-candidates %{
    eval set -- "$kak_quoted_opt_snippets"
    if [ $(($#%3)) -ne 0 ]; then exit; fi
    while [ $# -ne 0 ]; do
        printf '%s\n' "$1"
        shift 3
    done
} %{
    snippets-impl %arg{1} %opt{snippets}
}

def snippets-menu-impl -hidden -params .. %{
    eval %sh{
        if [ $(($#%3)) -ne 0 ]; then exit; fi
        printf 'menu'
        i=1
        while [ $# -ne 0 ]; do
            printf " %%arg{%s}" $i
            printf " 'snippets %%arg{%s}'" $i
            i=$((i+3))
            shift 3
        done
    }
}

def snippets-menu %{
    snippets-menu-impl %opt{snippets}
}

def snippets-info %{
    info -title Snippets %sh{
        eval set -- "$kak_quoted_opt_snippets"
        if [ $(($#%3)) -ne 0 ]; then printf "Invalid 'snippets' value"; exit; fi
        if [ $# -eq 0 ]; then printf 'No snippets defined'; exit; fi
        maxtriglen=0
        while [ $# -ne 0 ]; do
            if [ ${#2} -gt $maxtriglen ]; then
                maxtriglen=${#2}
            fi
            shift 3
        done
        eval set -- "$kak_quoted_opt_snippets"
        while [ $# -ne 0 ]; do
            if [ $maxtriglen -eq 0 ]; then
                printf '%s\n' "$1"
            else
                if [ "$2" = "" ]; then
                    printf "%${maxtriglen}s   %s\n" "" "$1"
                else
                    printf "%${maxtriglen}s ➡ %s\n" "$2" "$1"
                fi
            fi
            shift 3
        done
    }
}

def snippets-insert -hidden -params 1 %<
    eval -save-regs 's' %<
        eval -draft -save-regs '"' %<
            # paste the snippet
            reg dquote %arg{1}
            exec <a-P>

            # replace leading tabs with the appropriate indent
            try %<
                reg dquote %sh<
                    if [ $kak_opt_indentwidth -eq 0 ]; then
                        printf '\t'
                    else
                        printf "%${kak_opt_indentwidth}s"
                    fi
                >
                exec -draft '<a-s>s\A\t+<ret>s.<ret>R'
            >

            # align everything with the current line
            eval -draft -itersel -save-regs '"' %<
                try %<
                    exec -draft -save-regs '/' '<a-s>)<space><a-x>s^\s+<ret>y'
                    exec -draft '<a-s>)<a-space>P'
                >
            >

            reg s %val{selections_desc}
            # process placeholders
            try %<
                # select all placeholders ${..} and  escaped-$ (== $$)
                exec 's\$\$|\$\{(\}\}|[^}])*\}<ret>'
                # nonsense test text to check the regex
                # qwldqwld {qldwlqwld} qlwdl$qwld {qwdlqwld}}qwdlqwldl}
                # lqlwdl$qwldlqwdl$qwdlqwld {qwd$$lqwld} $qwdlqwld$

                # remove one $ from all $$, and leading $ from ${..}
                exec -draft '<a-:><a-;>;d'
                # unselect the $
                exec '<a-K>\A\$\z<ret>'
                # we're left with only {..} placeholders, process them...
                eval reg dquote %sh<
                    eval set -- "$kak_quoted_selections"
                    for sel do
                        # remove trailing }
                        sel="${sel%\}}"
                        # and leading {
                        sel="${sel#{}"
                        # de-double }}
                        tmp="$sel"
                        sel=""
                        while true; do
                            case "$tmp" in
                                *}}*)
                                    sel="${sel}${tmp%%\}\}*}}"
                                    tmp=${tmp#*\}\}}
                                    ;;
                                *)
                                    sel="${sel}${tmp}"
                                    break
                                    ;;
                            esac
                        done
                        # and quote the result in '..', with escaping (== doubling of ')
                        tmp="$sel"
                        sel=""
                        while true; do
                            case "$tmp" in
                                *\'*)
                                    sel="${sel}${tmp%%\'*}''"
                                    tmp=${tmp#*\'}
                                    ;;
                                *)
                                    sel="${sel}${tmp}"
                                    break
                                    ;;
                            esac
                        done
                        # all done, print it
                        # nothing like some good old posix-shell text processing
                        printf "'%s' " "$sel"
                    done
                >
                exec R
                reg s %val{selections_desc}
            >
        >
        try %{ select %reg{s} }
    >
>

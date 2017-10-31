# open lf in a separate terminal and use it as a file picker

define-command -params 1 -hidden lf-impl %{
    %sh{
        if [ -n "$WINDOWID" ]; then
            {
                setsid -w $kak_opt_termcmd "lf -selection-path /tmp/lf_selection $1" < /dev/null > /dev/null 2>&1
                IFS='
'
                {
                    printf "eval -client %s %%{" "$kak_client"
                    printf "edit -existing \"%s\";" $(cat /tmp/lf_selection)
                    printf "}"
                } | kak -p "$kak_session"
                rm -f /tmp/lf_selection
            } < /dev/null > /dev/null 2>&1 &
        fi
    }
}

define-command lf-file-dir -file-completion %{
    %sh{
        printf "lf-impl '%s'\n" "$(dirname $kak_buffile)"
    }
}
define-command lf-current-dir -file-completion %{
    %sh{
        printf "lf-impl '%s'\n" "$PWD"
    }
}

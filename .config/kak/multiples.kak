define-command keep-every-nth %{
    eval %sh{
        if [ $kak_count -eq 0 ]; then
            exit
        fi
        new_sel=""
        i=$kak_count
        IFS=:
        eval -- set "$kak_selections_desc"
        for current in "$@"; do
            if [ $i -eq $kak_count ]; then
                new_sel="${new_sel} ${current}"
                i=0
            fi
            i=$(( $i + 1 ))
        done
        printf "select %s" "${new_sel# }"
    }
}

define-command drop-every-nth %{
    eval %sh{
        if [ $kak_count -eq 0 ]; then
            exit
        fi
        new_sel=""
        i=0
        IFS=:
        eval -- set "$kak_selections_desc"
        for current in "$@"; do
            i=$(( $i + 1 ))
            if [ $i -eq $kak_count ]; then
                i=0
            else 
                new_sel="${new_sel} ${current}"
            fi
        done
        printf "select %s" "${new_sel# }"
    }
}

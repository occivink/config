declare-option -hidden str-list expand_results
declare-option -hidden str expand_tmp

define-command select_indented_paragraph %{
    eval -itersel %{
        exec -draft -save-regs '' '<a-i>pZ'
        exec '<a-i>i<a-z>i'
    }
    exec <esc>
}

define-command expand %{
    set-option global expand_results ""
    exec <space>
    expand-impl ""
    # the text object selection commands are found through trial and error
    expand-impl "exec <a-a>b"
    expand-impl "exec <a-a>B"
    expand-impl "exec <a-a>r"
    expand-impl "exec <a-i>i"
    expand-impl "exec <a-i>p"
    expand-impl "select_indented_paragraph"
    expand-impl "exec \%"
    expand-impl "exec /.<ret><a-K>\n<ret><a-i>i"
    %sh{
        # returns 0 if $1 is a superset of $2
        compare_descs() {
            if [ $1 = $2 ]; then
                return 1
            fi
            #999 columns ought to be enough for anybody
            start_1=${1%,*}
            start_1=$(printf "%d%03d" ${start_1%.*} ${start_1#*.})
            end_1=${1#*,}
            end_1=$(printf "%d%03d" ${end_1%.*} ${end_1#*.})
            start_2=${2%,*}
            start_2=$(printf "%d%03d" ${start_2%.*} ${start_2#*.})
            end_2=${2#*,}
            end_2=$(printf "%d%03d" ${end_2%.*} ${end_2#*.})
            if [ $start_1 -le $start_2 ] && [ $end_1 -ge $end_2 ]; then
                return 0
            else
                return 1
            fi
        }
        printf "%s\n" "$kak_opt_expand_results" | tr ':' '\n' | {
        while read -r current; do
            desc=${current%_*}
            length=${current#*_}
            if [ ! -n "$best_length" ]; then
                init_desc=$desc
                best_length=9999999
            elif compare_descs $desc $init_desc && [ $length -lt $best_length ]; then
                best_desc=$desc
                best_length=$length
            fi
        done
        if [ -n "$best_desc" ]; then
            printf "select %s\n" "$best_desc"
        fi
        }
    }
}

define-command expand-impl -hidden -params 1 %{
    eval -no-hooks -draft %{
        try %{
            eval %arg{1}
            set-option global expand_tmp "%val{selection_desc}"
            exec "s.<ret>"
            set-option global expand_tmp "%opt{expand_tmp}_%reg{#}"
            set-option -add global expand_results "%opt{expand_tmp}"
        }
    }
}

# expand the current selection by repeatedly calling "expand"

declare-option -hidden str-list expand_results
declare-option -hidden str expand_tmp

define-command -hidden select-indented-paragraph %{
    exec -draft -save-regs '' '<a-i>pZ'
    exec '<a-i>i<a-z>i'
}

define-command expand %{
    set-option global expand_results ""
    exec <space><a-:>
    # exclude text objects with symetric delimiters as they yield too many false positives
    expand-impl "exec <a-a>b"
    expand-impl "exec <a-a>B"
    expand-impl "exec <a-a>r"
    expand-impl "exec <a-i>i"
    expand-impl "exec /.<ret><a-K>\n<ret><a-i>i"
    expand-impl "exec <a-/>.<ret><a-K>\n<ret><a-i>i"
    expand-impl "select_indented_paragraph"
    %sh{
        # returns 0 if $1 is a strict superset of $2
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
        init_desc=$kak_selection_desc
        best_desc=0.0,9999999.999
        best_length=9999999
        printf "%s\n" "$kak_opt_expand_results" | tr ':' '\n' | {
        while read -r current; do
            desc=${current%_*}
            length=${current#*_}
            if compare_descs $desc $init_desc && [ $length -lt $best_length ]; then
                best_desc=$desc
                best_length=$length
            fi
        done
        printf "select %s\n" "$best_desc"
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

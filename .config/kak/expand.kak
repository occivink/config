# increases the size of the current selection by repeatedly calling "expand"

declare-option str-list expand_commands
# exclude text objects with symetric delimiters as they yield too many false positives
set -add global expand_commands "exec <a-a>b"
set -add global expand_commands "exec <a-a>b"
set -add global expand_commands "exec <a-a>B"
set -add global expand_commands "exec <a-a>r"
set -add global expand_commands "exec <a-i>i"
set -add global expand_commands "exec /.<ret><a-K>\n<ret><a-i>i"
set -add global expand_commands "exec <a-/>.<ret><a-K>\n<ret><a-i>i"
set -add global expand_commands "select-indented-paragraph"

declare-option -hidden str-list expand_results
declare-option -hidden str expand_tmp

define-command expand %{
    exec <space><a-:>
    unset-option buffer expand_results
    %sh{
        printf "%s\n" "$kak_opt_expand_commands" | tr ':' '\n' |
        while read -r current; do
            printf "expand-impl \"%s\"\n" "$current"
        done
    }
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
            set-option buffer expand_tmp "%val{selection_desc}"
            exec "s.<ret>"
            set-option -add buffer expand_results "%opt{expand_tmp}_%reg{#}"
        }
    }
}

define-command -hidden select-indented-paragraph %{
    exec -draft -save-regs '' '<a-i>pZ'
    exec '<a-i>i<a-z>i'
}

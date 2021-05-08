decl str clippy_sentence
decl str clippy_title
def make-clippy-say -params ..1 %{
    set global clippy_sentence ''
    set global clippy_title %arg{1}
    make-clippy-say-impl
}
def -hidden make-clippy-say-impl %{
    on-key %{
        eval %sh{
            if [ "$kak_key" = "<esc>" ]; then
                printf 'info -title $kak_opt_clippy_title'
                exit
            elif [ $kak_key = '<space>' ]; then kak_key=' '
            elif [ $kak_key = '<minus>' ]; then kak_key='-'
            elif [ $kak_key = '<ret>' ]; then kak_key="\n"
            elif [ $kak_key = '<lt>' ]; then kak_key="<"
            elif [ $kak_key = '<gt>' ]; then kak_key=">"
            elif [ $kak_key = "'" ]; then kak_key="''"
            fi
            printf "
                set -add global clippy_sentence '%s'
                info %%opt{clippy_sentence}
                make-clippy-say-impl
            " "$kak_key"
        }
    }
}


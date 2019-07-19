declare-option str alt_dirs_absolute

map global normal <c-a> ': try alt catch ialt catch ''''<ret>'
map global normal <c-w> ': write<ret>'

define-command ialt -docstring "Jump to the alternate file (header/implementation)" %{ evaluate-commands %sh{
    file="${kak_buffile##*/}"
    file_noext="${file%.*}"

    # Set $@ to alt_dirs
    alt_dirs=$(printf %s\\n "${kak_opt_alt_dirs_absolute}" | tr ':' '\n')

    case ${file} in
        *.c|*.cpp)
            for alt_dir in ${alt_dirs}; do
                for ext in h hpp; do
                    altname="${alt_dir}/${file_noext}.${ext}"
                    if [ -f ${altname} ]; then
                        printf 'edit %%{%s}\n' "${altname}"
                        exit
                    fi
                done
            done
        ;;
        *.h|.hpp)
            for alt_dir in ${alt_dirs}; do
                for ext in c cpp; do
                    altname="${alt_dir}/${file_noext}.${ext}"
                    if [ -f ${altname} ]; then
                        printf 'edit %%{%s}\n' "${altname}"
                        exit
                    fi
                done
            done
        ;;
        *)
            echo "echo -markup '{Error}extension not recognized'"
            exit
        ;;
    esac
    echo "echo -markup '{Error}alternative file not found'"
}}

set-option global formatcmd 'clang-format -style=file'

define-command enable-autoformat %{
	hook -group autoformat global BufWritePre .* %{
		eval %sh{ [ "$kak_opt_filetype" = cpp ] && printf format }
	}
}
define-command disable-autoformat %{
	remove-hooks autoformat
}

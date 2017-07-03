# save the current buffer to its file as root
# (optionally pass the user password to sudo if not cached)

declare-option -hidden str sudo_write_tmp

define-command sudo-write-impl -params 1 %{
    %sh{
        printf "set-option buffer sudo_write_tmp '%s'\n" $(mktemp --tmpdir XXXXXX)
    }
    write %opt{sudo_write_tmp}
    %sh{
        unset-option buffer sudo_write_tmp
        echo "$1" | sudo -S -- awk --assign=output="$kak_buffile" "// { print \$0 > output } END { close(output) }" "$kak_opt_sudo_write_tmp" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "edit!"
        else
            echo "echo -color Error 'Couldn't write, incorrect password?'"
        fi
        rm -f "$kak_opt_sudo_write_tmp"
    }
}

def sudo-write -docstring "Write the content of the buffer using sudo" %{
    %sh{
        # check if the password is cached
        if sudo -n true > /dev/null 2>&1; then
            echo "sudo-write-impl ''"
        else
            # if not, ask for it
            echo "prompt -password 'Password: ' %{ sudo-write-impl %val{text} }"
        fi
    }
}


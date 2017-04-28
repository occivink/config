function keks
        if test (count $argv) -ne 2
        return 1
    end
    set -l command (string replace -a \' \\\' $argv[1])
    set -l old_time (date +%s)
    kak -n -ui dummy -e "try %{ exec '"$command"<esc>:wq<ret>' } catch %{ exec ':q!<ret>' }" $argv[2]
    test -e $argv[2]; and test (stat -c "%Y" $argv[2]) -ge $old_time
    if not test $status -eq 0
        return 1
    end
end

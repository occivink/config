function keks
    if test (count $argv) -ne 2
        return 1
    end
    if not test -f $argv[2]
        touch $argv[2]
    end
    set -l command (string replace -a \' \\\' $argv[1])
    set -l old_time (date +%s)
    kak -n -ui dummy -e "try %{ source ~/.config/kak/kakrc; exec -with-maps '"$command"<esc>:wq<ret>' } catch %{ quit! 1 }" $argv[2]
    if not test (stat -c "%Y" $argv[2]) -ge $old_time
        return 1
    end
end

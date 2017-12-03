function __music_completion
    set -l dir ~/media/music/working
    set -l cmd (commandline -opc)
    if set -q cmd[2]; and not set -q cmd[3]; and test -d $dir/$cmd[2]
        printf "%s\n" $dir/$cmd[2]/* | string replace -r '.*/' ''
    else
        printf "%s\n" $dir/* | string replace -r '.*/' ''
    end
end

complete -f -c music -a "(__music_completion)"

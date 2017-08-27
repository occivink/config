function ls --description 'List contents of directory'
    set -l param --color=auto --human-readable --group-directories-first --quoting-style=literal -v
    if isatty 1
        set param $param --indicator-style=classify
    end
    command ls $param $argv
end

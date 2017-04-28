function tree --description 'List contents of directory'
    set -l param -C --dirsfirst
    if isatty 1
        set param $param -F
    end
    command tree $param $argv
end

function music
    set -l dir ~/media/music/working
    set -l n (count $argv)
    set -l listen
    if test $n -eq 0
        set listen (find $dir -mindepth 2 -maxdepth 2 -type d | shuf -n1)
    else if test $n -eq 2
        set listen $dir/$argv[1]/$argv[2]
    else if test $n -eq 1
        set listen $dir/$argv[1]
    else
        return 1
    end
    printf "Playing: %s\n" (string replace -r '.*/(.*)/(\d{4}) - (.*)' '$1 - $3 ($2)' $listen)
    mmp --merge-files $listen/**opus
end

function music
    set -l dir ~/media/music/working
    set -l listen
    if not set -q argv[1]
        set listen (find $dir -mindepth 2 -maxdepth 2 -type d | shuf -n1)
    else if test -d $dir/$argv[1]
        set listen $dir/$argv[1]
    else
        return 1
    end
    printf "Playing: %s\n" (string replace -r '.*/(.*)/(\d{4}) - (.*)' '$1 - $3 ($2)' $listen)
    mmp --merge-files $listen/**opus
end

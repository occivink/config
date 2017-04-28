function random_album
    cd (find ~/media/music/working/ -mindepth 2 -maxdepth 2 | shuf -n1)
    printf "Playing: %s\n" (string replace -r '.*/(.*?)/(\d{4}) - (.*)' '$3 ($2) - $1' (pwd))
    mmp --merge-files *opus
    cd -
end

edit:completer[kak] = [@cmd]{
    if (eq $cmd[-2] -c) {
        kak -l
    } else {
        $edit:&complete-filename $cmd[-1]
    }
}
edit:completer[k] = $edit:completer[kak]
edit:completer[ssh] = {
    cat ~/.ssh/config | each [line]{
        if (re:match "^Host " $line) {
            _ host = (re:split &max=2 'Host\s+' $line)
            put $host
        }
    }
}
edit:completer[systemctl] = [@cmd]{
    if (eq (count $cmd) 2) {
        put suspend poweroff reboot enable disable start stop restart daemon-reload edit
    } else {
        subcommand = $cmd[1]
        # systemctl list-stuff
    }
}

# kind of lazy, but what else do you need really?
edit:completer[pacman] = [@cmd]{
    if (eq (count $cmd) 2) {
        put -S -Syu -Rns -Qdt
    } else {
        operation = $cmd[1]
        if (re:match "^(-S|--sync$)" $operation) {
            pacman -Ssq
        } elif (re:match "^(-R|--remove$)" $operation) {
            pacman -Qsq
        }
    }
}
edit:completer[pacaur] = $edit:completer[pacman] 

# git
git_completer = [gitcmd @cmd]{
    if (eq (count $cmd) 2) {
        put add stage unstage show status mv rm commit discard fetch pull push merge rebase clone init mv reset rm bisect grep log branch checkout diff tag fetch
    } else {
        subcommand = $cmd[1]
        if (or (eq $subcommand add) (eq $subcommand stage)) {
            $gitcmd diff --name-only
            $gitcmd ls-files --others --exclude-standard
        } elif (eq $subcommand discard) {
            $gitcmd diff --name-only
        } elif (eq $subcommand unstage) {
            $gitcmd diff --name-only --cached
        } elif (eq $subcommand checkout) {
            $gitcmd branch --list --all --no-contains HEAD --format '%(refname:short)'
        }
    }
}
edit:completer[git] = { $git_completer e:git $@ }
edit:completer[g] = $edit:completer[git]
edit:completer[conf] = { $git_completer e:conf $@ }

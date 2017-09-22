edit:arg-completer[kak] = [@cmd]{
    if (eq $cmd[-2] -c) {
        kak -l
    } else {
        $edit:&complete-filename $cmd[-1]
    }
}
edit:arg-completer[k] = $edit:arg-completer[kak]
edit:arg-completer[ssh] = [@cmd]{
    cat ~/.ssh/config | each [line]{
        if (re:match "^Host " $line) {
            _ host = (re:split &max=2 'Host\s+' $line)
            put $host
        }
    }
}
#edit:arg-completer[systemctl] = [@cmd]{
#    if (eq (count $cmd) 2) {
#        put suspend poweroff reboot enable disable start stop restart daemon-reload edit
#    } else {
#        subcommand = $cmd[1]
#        if (eq $subcommand "enabled") {
#            systemctl list-unit-files --no-legend--state=disabled
#        } elif (eq $subcommand "disabled") {
#        } elif (eq $subcommand "disabled") {
#        } elif (eq $subcommand "disabled") {
#        } elif (eq $subcommand "disabled") {
#        } elif (eq $subcommand "disabled") {
#        # systemctl list-stuff
#    }
#}

edit:arg-completer[ffmpeg] = [@cmd]{
    if (eq (count $cmd) 2) {
        put -i
    } elif (eq $cmd[-2] -i) {
        $edit:&complete-filename $cmd[-1]
    }
}

# kind of lazy, but what else do you need really?
pac_completer = [paccmd @cmd]{
    if (eq (count $cmd) 2) {
        put -S -Syu -Rns -Qdt
    } else {
        operation = $cmd[1]
        if (re:match "^(-S|--sync$)" $operation) {
            $paccmd -Ssq
        } elif (re:match "^(-R|--remove$)" $operation) {
            $paccmd -Qsq
        }
    }
}
edit:arg-completer[pacman] = [@cmd]{ $pac_completer e:pacman $@cmd }
edit:arg-completer[pacaur] = [@cmd]{ $pac_completer e:pacaur $@cmd }

# git
git_completer = [gitcmd @cmd]{
    # "discard" and "unstage" are local aliases
    if (eq (count $cmd) 2) {
        put add stage unstage show status mv rm commit discard fetch pull push merge rebase clone init mv reset rm bisect grep log branch checkout diff tag fetch
    } else {
        subcommand = $cmd[1]
        if (re:match "^(add|stage)$" $subcommand) {
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
edit:arg-completer[git] = [@cmd]{ $git_completer e:git $@cmd }
edit:arg-completer[g] = $edit:arg-completer[git]
edit:arg-completer[conf] = [@cmd]{ $git_completer e:conf $@cmd }

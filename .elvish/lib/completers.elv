use re

# useless as of yet since completer output is sorted
#complete-filename-sorted = [prefix]{
#    if (> (count $cmd) 2) { return }
#
#    # this looks more complex than it should be but there are lots of edge cases
#    path = $cmd[1]
#    dir base = (if (re:match '/' $path) {
#        re:replace '/[^/]*$' '/' $path
#        re:replace '.*/' '' $path
#    } else {
#        put './' $path
#    })
#    # show hidden directories if last path component starts with '.'
#    # uses ls so that we get resolving of symlinks
#    flags = [-p -L (if (has-prefix $base '.') { put -a })]
#    try { e:ls $@flags $dir 2> /dev/null } except _ { }  |
#        each [i]{ if (re:match '/$' $i) { 
#               edit:complex-candidate (path-clean $dir$i)/ &style="blue;bold"
#           } else { 
#               edit:complex-candidate (path-clean $dir$i)
#           } 
#        }
#}

edit:completion:arg-completer[kak] = [@cmd]{
    if (eq $cmd[-2] -c) {
        kak -l
    } else {
        edit:complete-filename $cmd[-1]
    }
}
edit:completion:arg-completer[k] = $edit:completion:arg-completer[kak]

edit:completion:arg-completer[ssh] = [@cmd]{
    cat ~/.ssh/config | each [line]{
        if (re:match "^Host " $line) {
            _ host = (re:split &max=2 'Host\s+' $line)
            put $host
        }
    }
}

systemd_units = [state]{
    use re
    systemctl list-unit-files --no-legend --state=$state | each [l]{
        a=(re:find '^(.*)\.(service|target|socket|path|timer) +'$state'$' $l)
        edit:complex-candidate $a[groups][1][text] &display-suffix=" ("$a[groups][2][text]")"
    }
}
edit:completion:arg-completer[systemctl] = [@cmd]{
    if (eq (count $cmd) 2) {
        put suspend poweroff reboot enable disable status start stop restart daemon-reload edit
    } else {
        subcommand = $cmd[1]
        if (eq $subcommand "enable") {
            $systemd_units disabled
        } elif (eq $subcommand "disable") {
            $systemd_units enabled
        } elif (eq $subcommand "status") {
        } elif (has-value [stop restart] $subcommand) {
        } elif (eq $subcommand "start") {
        }
    }
}

edit:completion:arg-completer[ffmpeg] = [@cmd]{
    if (eq (count $cmd) 2) {
        put -i -ss
    } elif (eq $cmd[-2] -i) {
        edit:complete-filename $cmd[-1]
    } elif (eq $cmd[-2] -map) {
        edit:complete-filename $cmd[-1]
    }
}

# kind of lazy, but what else do you need really?
pac_completer = [paccmd~ @cmd]{
    if (eq (count $cmd) 2) {
        put -S -Syu -Rns -Qdt
    } else {
        operation = $cmd[1]
        if (re:match "^(-S|--sync$)" $operation) {
            paccmd -Ssq
        } elif (re:match "^(-R|--remove$)" $operation) {
            paccmd -Qsq
        }
    }
}
edit:completion:arg-completer[pacman] = [@cmd]{ $pac_completer (external pacman) $@cmd }
edit:completion:arg-completer[pacaur] = [@cmd]{ $pac_completer (external pacaur) $@cmd }

# git
git_completer = [gitcmd~ @cmd]{
    # "discard" and "unstage" are local aliases
    if (eq (count $cmd) 2) {
        put add stage unstage show status commit discard fetch pull push merge rebase clone init mv reset rm bisect grep log branch checkout diff tag fetch
    } else {
        subcommand = $cmd[1]
        if (has-value [add stage] $subcommand) {
            gitcmd diff --name-only --relative .
            gitcmd ls-files --others --exclude-standard
        } elif (eq $subcommand discard) {
            gitcmd diff --name-only --relative .
        } elif (eq $subcommand stash) {
            put save list show apply pop drop
        } elif (eq $subcommand unstage) {
            gitcmd diff --name-only --cached --relative .
        } elif (has-value [checkout rebase] $subcommand) {
            gitcmd branch --list --all --no-contains HEAD --format '%(refname:short)'
        } else {
            edit:complete-filename $cmd[-1]
        }
    }
}
edit:completion:arg-completer[git] = [@cmd]{ $git_completer (external git) $@cmd }
edit:completion:arg-completer[g] = $edit:completion:arg-completer[git]
edit:completion:arg-completer[conf] = [@cmd]{ $git_completer (external conf) $@cmd }

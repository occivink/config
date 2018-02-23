use re

# useless as of yet since completer output is sorted
#complete-filename-sorted = [prefix]{
#    matches=[$prefix*[nomatch-ok]]
#    if (== (count $matches) 0) { return }
#    matches=[(ls -p -L -d $@matches)]
#    put $@matches |
#        each [i]{ if (re:match '/$' $i) { put $i } } |
#        each [dir]{ edit:complex-candidate $dir &style="blue;bold" }
#    put $@matches |
#        each [i]{ if (not (re:match '/$' $i)) { put $i } } |
#        each [file]{ edit:complex-candidate $file }
#}

edit:arg-completer[kak] = [@cmd]{
    if (eq $cmd[-2] -c) {
        kak -l
    } else {
        edit:complete-filename $cmd[-1]
    }
}
edit:arg-completer[k] = $edit:arg-completer[kak]

edit:arg-completer[cd] = [@cmd]{
    if (> (count $cmd) 2) {
        return
    }
    # uses ls so that we get resolving of symlinks
    path = $cmd[1]
    dir base = (if (re:match '/' $path) {
        re:replace '/[^/]*$' '/' $path
        re:replace '.*/' '' $path
    } else {
        put './' $path
    })
    # show hidden directories if last path component starts with '.'
    flags = [-p -L (if (has-prefix $base '.') { put -a })]
    e:ls $@flags $dir |
        each [i]{ if (re:match '/$' $i) { put (path-clean $dir$i)/ } } |
        each [dir]{ edit:complex-candidate $dir &style="blue;bold" }
}

# multi-path completer
#edit:arg-completer[cd] = [@cmd]{
#    if (> (count $cmd) 2) {
#        return
#    }
#    components = [(splits / $cmd[1])]
#    parents = ['']
#    if (and (> (count $components) 1) (eq $components[0] '')) { 
#        _ @components = $@components
#        parents = [/] 
#    }
#    put $@components | each [prefix]{
#        parents=[(
#            put $@parents | each [parent]{
#                put $parent$prefix*[nomatch-ok]/
#            }
#        )]
#    }
#    put $@parents
#}

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
#            systemctl list-unit-files --no-legend --state=disabled
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
edit:arg-completer[pacman] = [@cmd]{ $pac_completer (external pacman) $@cmd }
edit:arg-completer[pacaur] = [@cmd]{ $pac_completer (external pacaur) $@cmd }

# git
git_completer = [gitcmd~ @cmd]{
    # "discard" and "unstage" are local aliases
    if (eq (count $cmd) 2) {
        put add stage unstage show status mv rm commit discard fetch pull push merge rebase clone init mv reset rm bisect grep log branch checkout diff tag fetch
    } else {
        subcommand = $cmd[1]
        if (re:match "^(add|stage)$" $subcommand) {
            gitcmd diff --name-only --relative .
            gitcmd ls-files --others --exclude-standard
        } elif (eq $subcommand discard) {
            gitcmd diff --name-only --relative .
        } elif (eq $subcommand unstage) {
            gitcmd diff --name-only --cached --relative .
        } elif (eq $subcommand checkout) {
            gitcmd branch --list --all --no-contains HEAD --format '%(refname:short)'
        }
    }
}
edit:arg-completer[git] = [@cmd]{ $git_completer (external git) $@cmd }
edit:arg-completer[g] = $edit:arg-completer[git]
edit:arg-completer[conf] = [@cmd]{ $git_completer (external conf) $@cmd }

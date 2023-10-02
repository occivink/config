use re

set edit:completion:arg-completer[kak] = {|@cmd|
    if (eq $cmd[-2] -c) {
        kak -l
    } else {
        edit:complete-filename $cmd[-1]
    }
}
set edit:completion:arg-completer[k] = $edit:completion:arg-completer[kak]

set edit:completion:arg-completer[ssh] = {|@cmd|
    cat ~/.ssh/config | each {|line|
        if (re:match "^Host " $line) {
            var _ host = (re:split &max=2 'Host\s+' $line)
            put $host
        }
    }
}

set edit:completion:arg-completer[cd] = {|@cmd|
    if (> (count $cmd) 2) {
        return
    }
    if (== (count $cmd) 1) { # no arg
        put */
        return
    }
    use str
    var arg = $cmd[-1]
    var parent_dir cur_dir
    {
        var last_slash = (str:last-index $arg '/')
        if (== $last_slash -1) {
            set parent_dir = ''
            set cur_dir = $arg
        } else {
            set parent_dir = $arg[..(+ $last_slash 1)]
            set cur_dir = $arg[(+ $last_slash 1)..]
        }
    }
    if (str:has-suffix $cur_dir '/') {
        put $parent_dir$cur_dir/*/
    } elif (str:has-prefix $cur_dir '.') {
        put $parent_dir*[match-hidden][nomatch-ok]/
    } else {
        put $parent_dir*[nomatch-ok]/
    }
}

var systemd_units = {|state|
    use re
    systemctl list-unit-files --no-legend --state=$state | each {|l|
        var a = (re:find '^(.*)\.(service|target|socket|path|timer) +'$state'$' $l)
        edit:complex-candidate $a[groups][1][text] &display-suffix=" ("$a[groups][2][text]")"
    }
}
set edit:completion:arg-completer[systemctl] = {|@cmd|
    if (eq (count $cmd) 2) {
        put suspend poweroff reboot enable disable status start stop restart daemon-reload edit
    } else {
        var subcommand = $cmd[1]
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

# git
var git_completer = {|gitcmd~ @cmd|
    # "discard" and "unstage" are local aliases
    if (eq (count $cmd) 2) {
        put add stage unstage show status commit discard fetch pull push merge rebase clone init mv reset rm bisect grep log branch checkout diff tag switch
    } else {
        var subcommand = $cmd[1]
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
set edit:completion:arg-completer[git] = {|@cmd| $git_completer (external git) $@cmd }
set edit:completion:arg-completer[g] = $edit:completion:arg-completer[git]
set edit:completion:arg-completer[conf] = {|@cmd| $git_completer (external conf) $@cmd }

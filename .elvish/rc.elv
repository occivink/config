edit:binding[insert][Alt-Backspace] = { edit:kill-word-left }
edit:binding[insert][Alt-Delete] = { edit:move-dot-right-word; edit:kill-word-left }
edit:binding[insert][Alt-s] = {
    if (or (< (count $edit:current-command) 5) (not (eq $edit:current-command[0:5] "sudo "))) {
        edit:current-command = "sudo "$edit:current-command
    }
}

# Some aliases
fn ls { e:ls --color=always --group-directories-first --human-readable $@ }
fn ffmpeg { e:ffmpeg -hide_banner $@ }
fn cp { e:cp --no-clobber $@ }
fn mv { e:mv --no-clobber $@ }

# some (yet) basic auto-completers
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
edit:completer[kak] = [@cmd]{
    if (eq $cmd[-2] -c) {
        kak -l
    } else {
        $edit:&complete-filename $cmd[-1]
    }
}
edit:completer[ssh] = [@cmd]{
    cat ~/.ssh/config | each [line]{
        if (re:match "^Host " $line) {
            _ host = (re:split &max=2 'Host\s+' $line)
            put $host
        }
    }
}
edit:completer[systemctl] = [@cmd]{}
edit:completer[git] = { $git_completer e:git $@ }
edit:completer[conf] = { $git_completer e:conf $@ }

#fancy: show how long the command took if it was more than 5s
__time_start = (date +%s)
edit:after-readline=[ { __time_start = (date +%s) } ]
edit:before-readline=[ {
    time_taken = (- (date +%s) $__time_start)
    if (> $time_taken 3600) {
        seconds = (% $time_taken 60)
        minutes = (/ (- (% $time_taken 3600) $seconds) 60)
        hours = (/ (- $time_taken (* $minutes 60) $seconds) 3600)
        echo (edit:styled " "$hours"h"(printf %02d\n $minutes)"m " "bg-magenta;bold")
    } elif (> $time_taken 60) {
        seconds = (% $time_taken 60)
        minutes = (/ (- $time_taken $seconds) 60)
        echo (edit:styled " "$minutes"m"(printf %02d\n $seconds)"s " "bg-magenta;bold")
    } elif (> $time_taken 5) {
        echo (edit:styled " "$time_taken"s " "bg-magenta;bold")
    }
} ]

edit:prompt = {
    edit:styled " "(tilde-abbr $pwd)" " "bg-blue;bold"
    edit:styled " λ " "bg-green;bold"
    put " "
}
edit:rprompt = { }

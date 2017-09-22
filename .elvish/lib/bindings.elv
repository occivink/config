edit:insert:binding[Alt-Backspace] = { edit:kill-small-word-left }
edit:insert:binding[Alt-Delete] = { edit:move-dot-right-word; edit:kill-word-left }
edit:insert:binding[Alt-Left] = { edit:move-dot-left-word }
edit:insert:binding[Alt-Right] = { edit:move-dot-right-word }

prepend_to_command = [prefix]{
    length = (count $prefix)
    if (or (< (count $edit:current-command) $length) (not (eq $edit:current-command[0:$length] $prefix))) {
        old_dot = $edit:-dot
        edit:current-command = $prefix$edit:current-command
        edit:-dot = (+ $old_dot $length)
    }
}
edit:insert:binding[Alt-s] = { $prepend_to_command "sudo " }

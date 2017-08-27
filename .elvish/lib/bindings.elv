edit:binding[insert][Alt-Backspace] = { edit:kill-small-word-left }
edit:binding[insert][Alt-Delete] = { edit:move-dot-right-word; edit:kill-word-left }
edit:binding[insert][Alt-Left] = { edit:move-dot-left-word }
edit:binding[insert][Alt-Right] = { edit:move-dot-right-word }

prepend_to_command = [prefix]{
    length = (count $prefix)
    if (or (< (count $edit:current-command) $length) (not (eq $edit:current-command[0:$length] $prefix))) {
        edit:current-command = $prefix$edit:current-command
    }
}
edit:binding[insert][Alt-s] = { $prepend_to_command "sudo " }

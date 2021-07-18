set edit:insert:binding[Alt-Backspace] = { edit:kill-small-word-left }
set edit:insert:binding[Alt-Delete] = { edit:move-dot-right-word; edit:kill-word-left }
set edit:insert:binding[Alt-Left] = { edit:move-dot-left-word }
set edit:insert:binding[Alt-Right] = { edit:move-dot-right-word }
set edit:insert:binding[Alt-Enter] = { edit:insert-at-dot "\n" }

var prepend_to_command = [prefix]{
    var length = (count $prefix)
    if (or (< (count $edit:current-command) $length) (not (eq $edit:current-command[0..$length] $prefix))) {
        set edit:current-command = $prefix$edit:current-command
        # causes segfaults or something
        #set edit:-dot = (+ $edit:-dot 1)
    }
}
set edit:insert:binding[Alt-s] = { $prepend_to_command "sudo " }

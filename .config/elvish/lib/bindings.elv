set edit:insert:binding[Alt-Backspace] = { edit:kill-small-word-left }
set edit:insert:binding[Alt-Delete] = { edit:move-dot-right-word; edit:kill-word-left }
set edit:insert:binding[Alt-Left] = { edit:move-dot-left-word }
set edit:insert:binding[Alt-Right] = { edit:move-dot-right-word }
set edit:insert:binding[Alt-Enter] = { edit:insert-at-dot "\n" }

var prepend_to_command = {|prefix|
    var length = (count $prefix)
    if (or (< (count $edit:current-command) $length) (not (eq $edit:current-command[0..$length] $prefix))) {
        set edit:current-command = $prefix$edit:current-command
        # causes segfaults or something
        #set edit:-dot = (+ $edit:-dot 1)
    }
}
set edit:insert:binding[Alt-s] = { $prepend_to_command "sudo " }
set edit:insert:binding[Alt-d] = {
    var output = (mktemp -t -u filetree-dirnav-XXXXX)
    kak -n -e '
        source "%val{config}/filetree.kak"
        filetree -only-dirs -no-report
        map buffer normal <ret> %{: filetree-select-path-component ; filetree-eval-on-fullpath %{echo -to-file %{'$output'} %reg{p}} ; quit<ret>}
        map buffer normal <esc> %{: quit<ret>}
        ' > /dev/tty
    use path
    if (path:is-regular $output) {
        var dir = (cat $output)
        rm $output
        if (path:is-dir $dir) {
            cd $dir
        }
    }
}

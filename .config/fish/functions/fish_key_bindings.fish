function fish_key_bindings --description 'Key bindings for fish' --argument mode
    # This is the default binding, i.e. the one used if no other binding matches
    bind $argv "" self-insert

    # ret
    bind $argv \r execute
    # alt-ret
    bind $argv \e\r "commandline -i \n"

    # tab / shift-tab
    bind $argv \t complete
    bind $argv -k btab complete-and-search

    # up/down
    bind $argv \e\[A up-or-search
    bind $argv \e\[B down-or-search
    # alt up/down
    bind $argv \e\[1\;3A history-token-search-backward
    bind $argv \e\[1\;3B history-token-search-forward

    # left/right
    bind $argv \e\[C forward-char
    bind $argv \e\[D backward-char
    # alt left/right
    bind $argv \e\[1\;3C nextd-or-forward-word
    bind $argv \e\[1\;3D prevd-or-backward-word

    # suppr / alt suppr
    bind $argv -k dc delete-char
    bind $argv \e\[3\;3\~ kill-word
    
    # backspace / alt backspace
    bind $argv -k backspace backward-delete-char
    bind $argv \e\x7f backward-kill-word

    # home / end
    bind $argv \e\[H beginning-of-line
    bind $argv \e\[F end-of-line

    bind $argv \es 'prepend_to_command \'sudo \''
    bind $argv \eq 'append_to_command \' >/dev/null ^/dev/null\''
    bind $argv \er 'interactive_history'
    bind $argv \el __fish_list_current_token
    bind $argv \ew 'set tok (commandline -pt); if test $tok[1]; echo; whatis $tok[1]; commandline -f repaint; end'
    
    bind $argv \cl 'clear; commandline -f repaint'
    bind $argv \cc 'commandline ""'
    bind $argv \cd delete-or-exit

    bind $argv -k f1 __fish_man_page
    bind $argv -k f2 ''
    bind $argv -k f3 ''
    bind $argv -k f4 ''
    bind $argv -k f5 ''
    bind $argv -k f6 ''
    bind $argv -k f7 ''
    bind $argv -k f8 ''
    bind $argv -k f9 ''
    bind $argv -k f10 ''
    bind $argv -k f11 ''
    bind $argv -k f12 ''

    # This will make sure the output of the current command is paged using the less pager when you press Meta-p
    bind $argv \ep '__fish_paginate'
    
    # escape
    bind \e cancel
end

decl str toolsclient
decl -hidden int find_current_line 0

define-command -params 1 find %{ 
    try %{ delete-buffer *find* }
    eval -buffer * %{
        # create find buffer after we start iterating so as not to include it
        eval -draft %{ edit -scratch *find* } 
        reg / %arg{1}
        try %{
            exec '%s<ret>'
            eval -save-regs '/c' -itersel %{
                # expand selection beginning and end to yank full lines
                exec -draft -save-regs '' '<a-L><a-;><a-H>y'
                # reduce to first character from selection to know the context
                exec '<a-;>;'
                reg c "%val{bufname}:%val{cursor_line}:%val{cursor_column}:"
                # paste context followed by the selection
                # also align the selection in case it spans multiple lines
                exec -buffer *find* 'geo<esc>"cp<a-p><a-s><a-;>&'
            }
        }
    }
    exec -buffer *find* d
    eval -try-client %opt{toolsclient} %{
        buffer *find*
        set buffer filetype find
        set buffer find_current_line 0
    }
}

hook -group find-highlight global WinSetOption filetype=find %{
    add-highlighter group find
    add-highlighter -group find regex "^((?:\w:)?[^:]+):(\d+):(\d+)?" 1:cyan 2:green 3:green
    add-highlighter -group find line %{%opt{find_current_line}} default+b
}

hook global WinSetOption filetype=find %{
    hook buffer -group find-hooks NormalKey <ret> find-jump
}

hook -group find-highlight global WinSetOption filetype=(?!find).* %{ remove-highlighter find }

hook global WinSetOption filetype=(?!find).* %{
    remove-hooks buffer find-hooks
}

decl str jumpclient

def -hidden find-jump %{
    eval -collapse-jumps %{
        try %{
            exec 'xs^((?:\w:)?[^:]+):(\d+):(\d+)?<ret>'
            set buffer find_current_line %val{cursor_line}
            eval -try-client %opt{jumpclient} edit -existing %reg{1} %reg{2} %reg{3}
            try %{ focus %opt{jumpclient} }
        }
    }
}

def find-next -docstring 'Jump to the next find match' %{
    eval -collapse-jumps -try-client %opt{jumpclient} %{
        buffer '*find*'
        exec "%opt{find_current_line}g<a-l>/^[^:]+:\d+:<ret>"
        find-jump
    }
    try %{ eval -client %opt{toolsclient} %{ exec %opt{find_current_line}g } }
}

def find-prev -docstring 'Jump to the previous find match' %{
    eval -collapse-jumps -try-client %opt{jumpclient} %{
        buffer '*find*'
        exec "%opt{find_current_line}g<a-/>^[^:]+:\d+:<ret>"
        find-jump
    }
    try %{ eval -client %opt{toolsclient} %{ exec %opt{find_current_line}g } }
}

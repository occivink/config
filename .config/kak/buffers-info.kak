# show information about currently opened buffers
# originally by danr, with cherry-picked ideas from delapouite

define-command buffers-info %{
    eval -no-hooks -save-regs '"/c' %{
        # debug so that it doesn't get iterated over
        eval -draft %{ edit -debug -scratch *tmp* }
        eval -buffer * %{
            reg '"' "  %val{bufname} %val{modified}"
            exec -buffer *tmp* "gep"
        }
        # put the line corresponding to the current buffer as search pattern
        reg '/' "\A\Q%val{bufname}\E\z"
        reg "c" "%val{client}|all"
        eval -buffer *tmp* %{
            # remove stray newline at the top
            exec 'd'

            # select the buffers names
            exec '%<a-s>1s^  ([^\n]+) \w+$<ret>'

            # put > in front of the current buffer
            try %{ exec -draft <a-k><ret>ghr> }

            # trim directory names
            try %{ exec -draft 1s\.?[^/]([^/]*)/<ret>d }

            # select the first flag
            exec 'll<a-e>'
            # replace 'modified' bool with a '+' flag (or nothing)
            try %{ exec -draft '<a-k>true<ret>i+<esc>' }
            exec 'd'

            exec '%<a-s>h'
            # surround flags (if there are any) with [ ]
            try %{ exec -draft '<a-i><a-w>i[<esc>a]<esc>' }
            # remove trailing spaces
            try %{ exec -draft '<a-i><space>d' }

            exec -save-regs '' '%y'
        }
        db *tmp*
        info -title Buffers %reg{"}
    }
}

hook global WinDisplay .* 'buffers-info'

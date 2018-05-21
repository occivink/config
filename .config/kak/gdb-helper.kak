define-command gdb-helper-repeat %{
    gdb-helper-info
    on-key %{
        try %{
            gdb-helper-impl %val{key}
            gdb-helper-repeat
        } catch %{
            # stopping, clear the info
            exec <esc>
        }
    }
}

define-command gdb-helper %{
    gdb-helper-info
    on-key %{
        try %{
            gdb-helper-impl %val{key}
        }
        # clear the info
        exec <esc>
    }
}

define-command -hidden gdb-helper-info %{
    info -title "gdb" \
%{n:    step over (next)
s:    step in (step)
f:    step out (finish)
r:    start
R:    run
c:    continue
g:    jump
G:    toggle autojump
t:    toggle breakpoint
T:    backtrace
p:    print
q:    stop}
}

define-command -hidden -params 1 gdb-helper-impl %{
    %sh{
        if [ "$1" = "<esc>" ]; then
            echo fail
            exit
        fi
        todo=n,gdb-next:s,gdb-step:f,gdb-finish:r,gdb-start:R,gdb-run:c,gdb-continue:g,gdb-jump-to-location:G,gdb-toggle-autojump:t,gdb-toggle-breakpoint:T,gdb-backtrace:p,gdb-print:q,gdb-session-stop
        IFS=:
        for com in $todo; do
            key="${com%%,*}"
            if [ "$1" = $key ]; then
                echo "${com#*,}"
                exit
            fi
        done
        echo "try %{ exec -with-maps \"$1\" }"
    }
}

hook global GlobalSetOption gdb_started=true %{
    map global normal <f10>   ': gdb-next<ret>'
    map global normal <f11>   ': gdb-step<ret>'
    map global normal <s-f11> ': gdb-finish<ret>'
    map global normal <f9>    ': gdb-toggle-breakpoint<ret>'
    map global normal <f5>    ': gdb-continue<ret>'
}
hook global GlobalSetOption gdb_started=false %{
    unmap global normal <f10>   ': gdb-next<ret>'
    unmap global normal <f11>   ': gdb-step<ret>'
    unmap global normal <s-f11> ': gdb-finish<ret>'
    unmap global normal <f9>    ': gdb-toggle-breakpoint<ret>'
    unmap global normal <f5>    ': gdb-continue<ret>'
}

# somewhat similar to make.kak

# modeline related stuff is global-scoped
declare-option str build_modeline_progress ""
declare-option str build_modeline_failure ""
declare-option str build_modeline_success ""
declare-option int build_clear_modeline_after 10
declare-option int build_last_timestamp 0
declare-option str build_shell_command "make"

# but these are buffer-scoped
declare-option str build_fifo
declare-option int build_current_line 0
declare-option regex build_error_pattern "^(?<file>[^\n]*?):(?<line>\d+):(?<column>\d+): (?<type>(fatal )?error):(?<error>[^\n]*?)"
declare-option regex build_warning_pattern "^(?<file>[^\n]*?):(?<line>\d+):(?<column>\d+): (?<type>warning):(?<warning>[^\n]*?)"

declare-option regex directory_pattern "Entering directory [`'](?<directory>[^\n]*)'$"
declare-option regex jump_pattern "^([^\n]*?):(\d+):(\d+): (error|warning): ([^\n]*)$"

declare-option -docstring "name of the client in which utilities display information" str toolsclient
declare-option -docstring "name of the client in which source code jumps are performed" str jumpclient

def build -params .. -docstring %{
build [<arguments>]: build utility wrapper
All the optional arguments are forwarded to the specified command
} %{
    try %{ delete-buffer! *build* }

    # launch compilation, and 'return' the path to the fifo
    set buffer build_fifo %sh{
        # imaginary race conditions be damned
        output="$(mktemp -u "${TMPDIR:-/tmp}"/kak-build.XXXXXXXX)"
        mkfifo "$output"
        printf '%s' "$output"
        (
            eval "${kak_opt_build_shell_command}" "$@" >${output} 2>&1
        ) >/dev/null 2>&1 </dev/null &
    }

    set global build_last_timestamp %sh{ printf '%s' $(( kak_opt_build_last_timestamp + 1 )) }
    trigger-user-hook build:started
    build-set-modeline "building..." "" ""

    eval -try-client %opt{toolsclient} %{
        edit! -fifo %opt{build_fifo} -scroll *build*

        hook -group build-trigger-user-hook buffer BufClose .* %{
            remove-hooks buffer build-trigger-user-hook
            trigger-user-hook build:interrupted
        }
        hook -group build-trigger-user-hook buffer BufCloseFifo .* %{
            remove-hooks buffer build-trigger-user-hook
            trigger-user-hook build:finished
        }
        hook -always -once buffer BufCloseFifo .* %{
            nop %sh{ rm -f "$kak_opt_build_fifo" }
            unset buffer build_fifo
            build-update-modeline
        }
        set buffer build_current_line 0
        add-highlighter buffer/ regex %opt{build_error_pattern} file:cyan line:green column:green type:red
        add-highlighter buffer/ regex %opt{build_warning_pattern} file:cyan line:green column:green type:yellow
        add-highlighter buffer/ line '%opt{build_current_line}' default+b
        map buffer normal <ret> ': build-jump<ret>'
    }
}

def build-sync -params .. %{
    try %{ delete-buffer! *build* }

    edit! -scratch *build*

    eval -save-regs | %{
        reg | %{ eval "${kak_opt_build_shell_command}" "$@" 2>&1 }
        exec '!<ret>'
        exec gj
    }
    set buffer build_current_line 0
    add-highlighter buffer/ regex %opt{build_error_pattern} file:cyan line:green column:green type:red
    add-highlighter buffer/ regex %opt{build_warning_pattern} file:cyan line:green column:green type:yellow
    add-highlighter buffer/ line '%opt{build_current_line}' default+b
    map buffer normal <ret> ': build-jump<ret>'

    eval -save-regs '/c' %{
        reg c ''
        try %{
            reg / %opt{build_error_pattern}
            exec -draft '%s<a-s><a-k><ret>'
            reg c 'fail "Build failed"'
        }
        eval %reg{c}
    }
}

def -hidden build-update-modeline %{
    eval -save-regs '/' -draft %{
        try %{
            reg / %opt{build_error_pattern}
            exec '%s<a-s><a-k><ret>'
            build-set-modeline "" "" "build: %reg{#} error(s)"
        } catch %{
            build-set-modeline "" "build: success" ""
        }
    }

    nop %sh{
        (
            sleep "$kak_opt_build_clear_modeline_after"
            printf '%s %s' build-clear-modeline "$kak_opt_build_last_timestamp" | kak -p "$kak_session"
        ) >/dev/null 2>&1 </dev/null &
    }
}

def -hidden build-set-modeline -params 3 %{
    set global build_modeline_progress %arg{1}
    set global build_modeline_success  %arg{2}
    set global build_modeline_failure  %arg{3}
}

def -hidden build-clear-modeline -params 1 %{
    try %{
        eval %sh{ [ "$1" -lt "$kak_opt_build_last_timestamp" ] && printf fail }
        build-set-modeline "" "" ""
    }
}

def -hidden build-jump %{
    try %{
        eval -save-regs 'flcidt/' %{
            eval -draft %{
                exec '<space>;gl'
                reg d ""
                try %{
                    eval -draft %{
                        reg / %opt{directory_pattern}
                        exec '<a-/><ret>1s<ret>'
                        reg d "%val{selection}"
                    }
                }
                exec '<a-x>'
                reg / %opt{jump_pattern}
                exec 's<ret>'
                reg f "%reg{1}"
                reg l "%reg{2}"
                reg c "%reg{3}"
                reg t "%reg{4}"
                reg i "%reg{5}"
            }
            set buffer build_current_line %val{cursor_line}
            edit -existing "%reg{d}/%reg{f}" %reg{l} %reg{c}
            info -title %reg{t} %reg{i}
        }
    } catch %{
        fail "Cannot jump to current line"
    }
}

def build-next-error %{
	build-jump
}

def build-previous-error %{
	build-jump
}

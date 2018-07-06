# alternative implementation (pure kakoune) of delapouite's auto-percent
# https://github.com/delapouite/kakoune-auto-percent
# all credit goes to him

# for commands that spawn a prompt (and can therefore be cancelled)
define-command -hidden -params 2 auto-percent-prompt %{
    try %{
        exec -draft '<a-space>'
    } catch %{
        try %{
            exec -draft '<a-k>\A.\z<ret>'
            hook -group auto-percent window RawKey "<esc>" "select %val{selection_desc}; rmhooks window auto-percent"
            hook -group auto-percent window RuntimeError "nothing selected|no selections remaining" "select %val{selection_desc}; rmhooks window auto-percent"
            hook -group auto-percent window RawKey "<ret>" "rmhooks window auto-percent"
            exec "%arg{2}"
        }
    }
    exec "%val{count}""%val{register}%arg{1}"
}

# for commands that do not spawn a prompt
define-command -hidden -params 2 auto-percent %{
    try %{
        exec -draft '<a-space>'
    } catch %{
        try %{
            exec -draft '<a-k>\A.\z<ret>'
            exec "%arg{2}"
        }
    }
    exec "%val{count}""%val{register}%arg{1}"
}

#map global normal <a-s> ':auto-percent <lt>a-s> \%<ret>'
#map global normal <a-S> ':auto-percent <lt>a-S> \%<ret>'
#map global normal s ':auto-percent-prompt s \%<ret>'
#map global normal S ':auto-percent-prompt S \%<ret>'
#map global normal <a-k> ':auto-percent-prompt <lt>a-k> \%<lt>a-s><ret>'
#map global normal <a-K> ':auto-percent-prompt <lt>a-K> \%<lt>a-s><ret>'

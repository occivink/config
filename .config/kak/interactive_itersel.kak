declare-option range-specs phantom_selections
set-face InterItersel black,green

#1 target scope
#2 target option
#3 source mark register
#4 face to use
define-command -params 4 mark_to_range_faces %{
    %sh{
        printf "set %s %s %s\n" "$1" "$2" $(printf %s "$3" | sed -e 's/\([:@]\)/|'"$4"'\1/g' -e 's/\(.*\)@.*%\(.*\)/\2:\1/')
    }
}

define-command interactive_itersel %{
    try %{
        # >1 sel
        exec -draft <a-space>
        # ensure first selection is the main one
        exec Zz'
        exec -draft <a-space>\"sZ
        mark_to_range_faces buffer phantom_selections %reg{s} InterItersel
        reload-highlighter
        exec <space>
    } catch %{
        # 1 sel
        try %{
            exec \"sz
            reg s ''
            interactive_itersel
        } catch %{
            eval -buffer * "unset-option buffer phantom_selections"
        }
    }
}

define-command -hidden reload-highlighter %{
    try "remove-highlighter hlranges_phantom_selections"
    add-highlighter ranges phantom_selections
    # ensure whitespace is always after
    # kinda hacky
    try %{
        remove-highlighter show_whitespaces
        add-highlighter show_whitespaces
    }
}

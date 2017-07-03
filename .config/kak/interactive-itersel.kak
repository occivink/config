# manually iterate over current selections by repeatedly calling interactive-itersel

declare-option -hidden range-specs phantom_selections
declare-option -hidden str iitersel_buffer
set-face InteractiveItersel black,green

#1 target scope
#2 target option
#3 source marks
#4 face to use
define-command -hidden -params 4 mark-to-range-faces %{
    %sh{
        printf "set %s %s %s\n" "$1" "$2" $(printf %s "$3" | sed -e 's/\([:@]\)/|'"$4"'\1/g' -e 's/\(.*\)@.*%\(.*\)/\2:\1/')
    }
}

define-command interactive-itersel %{
    try %{
        # >1 sel
        exec -draft <a-space>
        # ensure first selection is the main one
        exec Zz'
        exec -draft <a-space>\"sZ
        mark-to-range-faces buffer phantom_selections %reg{s} InteractiveItersel
        set-option global iitersel_buffer %val{bufname}
        reload-highlighter
        exec <space>
    } catch %{
        # ==1 sel
        try %{
            # previous itersel exist
            exec \"sz
            reg s ''
            interactive-itersel
        } catch %{
            interactive-itersel-clear
        }
    }
}

define-command interactive-itersel-clear %{
    try %{
        eval -buffer %opt{iitersel_buffer} "unset-option buffer phantom_selections"
        set-option global iitersel_buffer ""
        remove-highlighter hlranges_phantom_selections
    }
}

# hack: we want this highlighter to be applied after language specific-ones
define-command -hidden reload-highlighter %{
    try %{ remove-highlighter hlranges_phantom_selections }
    add-highlighter ranges phantom_selections
    # classic hack within a hack
    # https://github.com/mawww/kakoune/issues/1251
    try %{
        remove-highlighter show_whitespaces
        add-highlighter show_whitespaces
    }
}

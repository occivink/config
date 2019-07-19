# gris theme

evaluate-commands %sh{
    c0="rgb:000000"
    c5="rgb:555555"
    ca="rgb:aaaaaa"
    cf="rgb:ffffff"
    main="rgb:ff69b4"

    echo "
         face global value $cf
         face global type $cf
         face global variable $cf
         face global function $cf
         face global module $cf
         face global string $ca
         face global error $cf
         face global keyword $cf
         face global operator $cf
         face global attribute $cf
         face global comment $ca+i
         face global meta $cf
         face global builtin $cf+b

         face global title $cf+b
         face global header $cf
         face global bold $cf+b
         face global italic $cf+i
         face global mono $cf
         face global block $cf
         face global link $cf
         face global bullet $cf
         face global list $cf

         face global Default $cf,$c0

         face global PrimarySelection $c0,$cf
         face global PrimaryCursor $c0,$main
         face global PrimaryCursorEol $c0,$main

         face global SecondarySelection $c0,$ca
         face global SecondaryCursor $c0,$cf
         face global SecondaryCursorEol $c0,$cf

         face global MatchingChar $main,$c0+b
         face global Search $c0,$cf
         face global CurrentWord $c0,$cf

         # listchars
         face global Whitespace $c5,$c0+f
         # ~ lines at EOB
         face global BufferPadding $ca,$c0

         face global LineNumbers $ca,$c0
         # must use -hl-cursor
         face global LineNumberCursor $cf,$c5+b
         face global LineNumbersWrapped $ca,$c0+i

         # when item focused in menu
         face global MenuForeground $c0,$cf+b
         # default bottom menu and autocomplete
         face global MenuBackground $cf,$c5
         # complement in autocomplete like path
         face global MenuInfo $cf,$c5
         # clippy
         face global Information $cf,$c5
         face global Error $c0,$cf

         # all status line: what we type, but also client@[session]
         face global StatusLine $cf,$c0
         # insert mode, prompt mode
         face global StatusLineMode $c0,$cf
         # message like '1 sel'
         face global StatusLineInfo $cf,$c0
         # count
         face global StatusLineValue $cf,$c0
         face global StatusCursor $c0,$main
         # like the word 'select:' when pressing 's'
         face global Prompt $c0,$cf
    "
}

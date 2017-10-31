# mark.kak
# ----------------------------------------------------------------------------
# version:  0.0.1
# modified: 2017-08-25
# author:   blub
# ----------------------------------------------------------------------------

###
# declarations

decl -hidden str-list mark_colors %{1,red:2,green:3,yellow:4,blue:5,magenta:6,cyan}
decl -hidden int-list mark_unused %{1:2:3:4:5:6}
decl -hidden str-list mark_active %{}

###
# definitions

def -params 1..2 mark-set \
    -docstring %(mark-set <pattern> [slot]: highlight all text occurrences
matching <pattern>; unless [slot] is specified, use slot 1
   pattern: regular expression
   slot:    index in 1..6) \
%{
   %sh{
      mp="${1}"
      mi="${2-1}"

      case "${mi}" in
         1|2|3|4|5|6)
            ;;
         *)
            printf "echo -markup {Error}%s\\n" "invalid slot"
            exit
            ;;
      esac

      unset tu
      for i in $(printf %s "${kak_opt_mark_unused}" | tr : '\n'); do
         if [ "${i}" != "${mi}" ]; then
            tu="${tu}${tu+:}${i}"
         fi
      done
      printf "set buffer mark_unused '%s'\\n" "${tu}"

      mq="$(printf %s "${mp}" | base64)"
      unset ta
      for pair in $(printf %s "${kak_opt_mark_active}" | tr : '\n'); do
         i="$(printf %s "${pair}" | cut -d, -f2)"
         if [ "${i}" != "${mi}" ]; then
            q="$(printf %s "${pair}" | cut -d, -f1)"
            ta="${ta}${ta+:}${q},${i}"
         fi
      done
      ta="${ta}${ta+:}${mq},${mi}"
      printf "set buffer mark_active '%s'\\n" "${ta}"

      printf "echo -debug [mark] buffer:%s active:%s unused:%s\\n" \
         "${kak_buffile}" "${ta}" "${tu}"

      cn="white"
      for pair in $(printf %s "${kak_opt_mark_colors}" | tr : '\n'); do
         ci="$(printf %s "${pair}" | cut -d, -f1)"
         if [ "${ci}" = "${mi}" ]; then
            cn="$(printf %s "${pair}" | cut -d, -f2)"
            break
         fi
      done
      printf "rmhl mark_%s\\n" "${mi}"
      printf "addhl group mark_%s\\n" "${mi}"
      printf "addhl -group mark_%s regex '%s' '0:%s+rb'\\n" "${mi}" "${mp}" "${cn}"
   }
}

def -params ..1 mark-del \
    -docstring %(mark-del [slot]: unmark all text occurrences highlighted via
mark-set at [slot]; unless [slot] is specified, use slot 1
   slot: index in 1..6) \
%{
   %sh{
      mi="${1-1}"

      case "${mi}" in
         1|2|3|4|5|6)
            ;;
         *)
            printf "echo -markup {Error}%s\\n" "invalid slot"
            exit
            ;;
      esac

      unset tu
      for i in $(printf %s "${kak_opt_mark_unused}" | tr : '\n'); do
         if [ "${i}" != "${mi}" ]; then
            tu="${tu}${tu+:}${i}"
         fi
      done
      tu="${mi}${tu+:}${tu}"
      printf "set buffer mark_unused '%s'\\n" "${tu}"

      unset ta
      for pair in $(printf %s "${kak_opt_mark_active}" | tr : '\n'); do
         i="$(printf %s "${pair}" | cut -d, -f2)"
         if [ "${i}" != "${mi}" ]; then
            q="$(printf %s "${pair}" | cut -d, -f1)"
            ta="${ta}${ta+:}${q},${i}"
         fi
      done
      printf "set buffer mark_active '%s'\\n" "${ta}"

      printf "echo -debug [mark] buffer:%s active:%s unused:%s\\n" \
         "${kak_buffile}" "${ta}" "${tu}"

      printf "rmhl mark_%s\\n" "${mi}"
   }
}

def -params 2 mark-pattern \
    -docstring %(mark-pattern <action> <pattern>: alter highlighting according
to <action> for all occurrences of text matching <pattern>
   action:  token in {del, set, toggle}
   pattern: regular expression) \
%{
   %sh{
      action="${1}"
      mp="${2}"

      case "${1}" in
         del|set|toggle)
            ;;
         *)
            printf "echo -markup {Error}%s\\n" "invalid action"
            exit
            ;;
      esac

      mq="$(printf %s "${mp}" | base64)"
      for pair in $(printf %s "${kak_opt_mark_active}" | tr : '\n'); do
         q="$(printf %s "${pair}" | cut -d, -f1)"
         if [ "${q}" = "${mq}" ]; then
            if [ "${action}" != "set" ]; then
               i="$(printf %s "${pair}" | cut -d, -f2)"
               printf "mark-del '%s'\\n" "${i}"
               action="del" # avoid setting again
            fi
         fi
      done

      if [ "${action}" != "del" ]; then
         if [ -z "${kak_opt_mark_unused}" ]; then
            for pair in $(printf %s "${kak_opt_mark_active}" | tr : '\n'); do
               mi="$(printf %s "${pair}" | cut -d, -f2)"
               break
            done
         else
            for i in $(printf %s "${kak_opt_mark_unused}" | tr : '\n'); do
               mi="${i}"
               break
            done
         fi
         printf "mark-set '%s' '%s'\\n" "${mp}" "${mi}"
      fi
   }
}

def -hidden mark-word-impl %{
   %sh{
      printf "mark-pattern toggle '\\\\<%s\\\\>'\\n" "${kak_selection}"
   }
}

def mark-word \
    -docstring %(mark-word: toggle highlighting for all occurrences of the
word under the cursor) \
%{
   %sh{
      tmp="${kak_opt_extra_word_chars}"
      printf "set current extra_word_chars ''\\n"
      printf "exec -draft '%s'\\n" "<a-i>w:mark-word-impl<ret>"
      printf "set current extra_word_chars '%s'\\n" "${tmp}"
   }
}

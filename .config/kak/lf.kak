 def \
   -params .. -file-completion \
   -docstring %{lf [<arguments>]: open the file system explorer to select buffers to open
 All the optional arguments are forwarded to the lf utility} \
   lf %{ %sh{
   if [ -n "$WINDOWID" ]; then
       {
            setsid -w $kak_opt_termcmd " \
                lf $@ -selection-path /tmp/lf_selection" < /dev/null > /dev/null 2>&1
            IFS='
'
            {
                 printf "eval -client %s %%{" "$kak_client"
                 printf "edit \"%s\";" $(cat /tmp/lf_selection)
                 printf "}"
            } | kak -p "$kak_session"
            rm -f /tmp/lf_selection
       } < /dev/null > /dev/null 2>&1 &
   fi
 }}


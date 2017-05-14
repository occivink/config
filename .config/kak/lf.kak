#def \
#  -params .. -file-completion \
#  -docstring %{ranger [<arguments>]: open the file system explorer to select buffers to open
#All the optional arguments are forwarded to the lf utility} \
#  lf %{ %sh{
#  if [ -n "$WINDOWID" ]; then
#    setsid $kak_opt_termcmd " \
#      lf $@ --cmd "'"'" \
#        map <return> eval \
#          fm.execute_console('shell \
#            echo eval -client $kak_client edit {file} | \
#            kak -p $kak_session; \
#            xdotool windowactivate $kak_client_env_WINDOWID'.format(file=fm.thisfile.path)) \
#          if fm.thisfile.is_file else fm.execute_console('move right=1')"'"' < /dev/null > /dev/null 2>&1 &
#  fi
#}}
#

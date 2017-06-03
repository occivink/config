#%sh{
#    if [ -f .kak.session ]; then
#        while IFS='' read file; do
#            printf "edit \"%s\"" "$file"
#        done < .kak.session
#    fi
#}
#
#define-command save-session %{
#

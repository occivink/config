# Example demo script:
###############
# clippy-say Hi, and welcome to this demo of the 'kakoune-filetree' plugin
#
# sleep 300
#
# command source filetree.kak
#
# clippy-say After sourcing the script, the main entrypoint is the 'filetree' command
#
# command filetree
#
# clippy-say This opens a new buffer with the content of the current directory, as when using the 'tree' program
#
# clippy-say From here, we can open the file on the cursor by just pressing <ret>
#
# type 100 j l l l l l l
# sleep 500
# type <ret>
# sleep 1200
#
# command buffer *filetree*
# ...
###############
# Perform using `kak -n -e 'source ~/.config/kak/demo.kak ; demo-perform script'`
# Exit the demo at any time by pressing <c-x>

declare-option -hidden str demo_script_path %val{source}

define-command -hidden demo-perform -params 1 %{
    eval %sh{
        if [ ! -f "$1" ]; then
            echo "echo -debug 'No demo script found'"
            exit 1
        fi
        sh_script="${kak_opt_demo_script_path%/*}/kak_demo.sh"
        if [ ! -f "$sh_script" ]; then
            echo "echo -debug 'No helper script found'"
            exit 1
        fi
        {
            sh "$sh_script" "$kak_session" "$kak_client" < "$1"
        } >/dev/null 2>&1 </dev/null &
        printf "map global normal <c-x> ': quit! 1<ret>'\n"
        printf "map global insert <c-x> '<esc>: quit! 1<ret> '\n"
        printf "map global prompt <c-x> '<esc>: quit! 1<ret> '\n"
    }
}

function interactive_history
    history --null | fzf --read0 --print0 --height 33\% --reverse --tiebreak=index -q (commandline) | read -z -l command
    and commandline -- $command
    commandline -f repaint
end

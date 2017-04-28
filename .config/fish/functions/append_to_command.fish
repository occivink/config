function append_to_command
    set -l cur_pos (commandline -C)
    commandline -i $argv
    commandline -C $cur_pos
end

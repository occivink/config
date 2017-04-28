function prepend_to_command
    set -l new_pos (math (commandline -C) + (echo $argv | wc -m) - 1)
    commandline -C 0
    commandline -i $argv
    commandline -C $new_pos
end

function lf
    set -l last_path_file (mktemp --tmpdir lf_last_dir_XXX)
    command lf -last-dir-path $last_path_file $argv
    set -l last_path (cat $last_path_file)
    rm $last_path_file
    cd $last_path
end

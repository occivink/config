function burl
    set -l old_names $argv
    set -l renaming_file (mktemp --tmpdir burl.XXXXXXX)
    for i in $old_names
        echo $i 
    end > $renaming_file
    set -l old_time (stat -c "%Y" $renaming_file)
    
    eval $EDITOR $renaming_file
    
    if not test (stat -c "%Y" $renaming_file) -gt $old_time
        return 1
    end
    
    set -l new_names (cat $renaming_file)
    if test (count $old_names) -ne (count $new_names)
        rm $renaming_file
        echo "Number of files before and after do not match" >&2
        return 1
    end
    #if grep '/' $renaming_file >&-
    #    rm $renaming_file
    #    echo "Invalid '/' in new names." >&2
    #    return 1
    #end
    rm $renaming_file
    
    for i in (seq (count $new_names))
        mv --no-clobber $old_names[$i] $new_names[$i] ^&-
    end
    return 0
end

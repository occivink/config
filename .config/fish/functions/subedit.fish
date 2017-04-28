function subedit
        set -l ass_file
    set -l funcname
    set -l input_matroska
    set -l subtrack_id

    if test (count $argv) -ne 1
        return 1
    end
    set input_matroska $argv[1]

    if not test -f $input_matroska
        printf "Can't find file %s\n" $input_matroska >&2
        return 1
    end

    if not status --is-command-substitution
        echo "subedit: Not inside of command substitution" >&2
        return 1
    end

    set -l ass_file (mktemp --tmpdir subedit.XXXX.ass)
    set -l mkvmerge_output (mkvmerge -i $input_matroska ^/dev/null)
    if not test $status -eq 0
        echo "Not a valid matroska file" >&2
        return 1
    end
    set sub_tracks (string match -r "Track ID \d+: subtitles.*" $mkvmerge_output)
    if test (count $sub_tracks) -gt 1
        echo "Multiple subtitle tracks, select one" >&2
        return 1
    else if test (count $sub_tracks) -eq 0
        echo "No subtitle track found" >&2
        return 1
    end

    set subtrack_id (string replace -r '.*?(\d+).*' '$1' $sub_tracks[1])
    set tracks_total (count (string match "*Track ID*" $mkvmerge_output))

    mkvextract tracks $input_matroska $subtrack_id:$ass_file >/dev/null ^/dev/null

    set -l old_time (stat -c "%Y" $ass_file)
    # write ass file to stdout for enclosing program
    echo $ass_file

    # Find unique function name
    while true
        set funcname __fish_subedit_(random)
        if not functions $funcname >/dev/null ^/dev/null
            break
        end
    end

    function $funcname --on-job-exit caller --inherit-variable ass_file --inherit-variable old_time --inherit-variable funcname --inherit-variable input_matroska --inherit-variable subtrack_id --inherit-variable tracks_total
        functions -e $funcname
        # stop if no changes were made
        if test (date "+%s") -gt $old_time -a (stat -c "%Y" $ass_file) -eq $old_time
            rm $ass_file
            return 0
        end
        set -l trackorder
        for i in (seq 0 (math $subtrack_id - 1))
            set trackorder "$trackorder",0:"$i"
        end
        set trackorder "$trackorder",1:0
        for i in (seq (math $subtrack_id + 1) (math $tracks_total - 1))
            set trackorder "$trackorder",0:"$i"
        end
        set trackorder (string replace -r '^,' '' $trackorder)
        set -l merged (mktemp --tmpdir subedit.XXXX.mkv)
        if mkvmerge -o $merged --track-order $trackorder --subtitle-tracks "!"$subtrack_id "$input_matroska" $ass_file ^/dev/null >/dev/null
            trash "$input_matroska"
            mv $merged $input_matroska
            chmod 644 "$input_matroska"
        else
            echo "Error while merging back" >&2
        end
        rm $ass_file
    end
end

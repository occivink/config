use bindings
use timer
use completers

fn ls { e:ls --color=auto --group-directories-first --human-readable --quoting-style=literal -v $@ }
fn ffmpeg { e:ffmpeg -hide_banner $@ }
fn cp { e:cp --no-clobber $@ }
fn mv { e:mv --no-clobber $@ }
fn lf {
    t = (mktemp --tmpdir lf_last_dir_XXX)
    e:lf -last-dir-path $t $@args
    # cd in disguise
    (cat $t | slurp)
    rm $t
}
fn k { e:kak $@ }
fn g { e:git $@ }

edit:prompt = {
    edit:styled " "(tilde-abbr $pwd)" " "bg-blue;bold"
    edit:styled " λ " "bg-green;bold"
    put " "
}
edit:rprompt = { }

# edit the subtitles in a matroska file as a text file
# takes care of demuxing and muxing back together
fn subedit [pre input_matroska post]{
    #validate basic stuff
    if (not (eq (kind-of $pre) list)) { fail "Not an array" }
    if (not (>= (count $pre) 1)) { fail "Missing command" }
    cmd @pre = $@pre
    if (not (eq (kind-of $input_matroska) string)) { fail "Not a string" }
    if (not ?(test -f $input_matroska)) { fail "Not a file" }
    if (not (eq (kind-of $post) list)) { fail "Not an array" }

    # extract subtitles
    tracks = ""
    try { tracks = (mkvmerge -i $input_matroska | slurp) } except _ { fail "Not a matroska?" }
    tracks_count = (count [(re:find 'Track ID \d+:' $tracks)])
    sub_tracks = [(re:find 'Track ID (\d+): subtitles' $tracks)]
    if (> (count $sub_tracks) 1) { fail "Too many subtitles tracks" }
    subtrack_id = $sub_tracks[0][groups][1][text]
    ass_file = (mktemp -u subedit.XXXX.ass)
    mkvextract tracks $input_matroska $subtrack_id':'$ass_file > /dev/null

    try {
        # call external command
        $cmd $@pre $ass_file $@post

        # merge back
        trackorder = (joins "," [(for i [(seq 0 (- $tracks_count 1))] {
            if (not (eq $i $subtrack_id)) { put "0:"$i } else { put 1:0 }
        })])
        merged = (mktemp -u $input_matroska"XXXX")

        mkvmerge -o $merged --track-order $trackorder --subtitle-tracks !$subtrack_id $input_matroska $ass_file > /dev/null
        rm $input_matroska
        mv $merged $input_matroska
    } finally {
        rm $ass_file
    }
}
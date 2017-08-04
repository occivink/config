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
    # mildly obfuscated cd
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

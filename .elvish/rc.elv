use bindings
use timer
use completers

fn ls { e:ls --color=auto --group-directories-first --human-readable --quoting-style=literal -v $@ }
fn ffmpeg { e:ffmpeg -hide_banner $@ }
fn cp { e:cp --no-clobber $@ }
fn mv { e:mv --no-clobber $@ }
cd-prev = $pwd
fn cd {
    d = $args
    if (and (eq (count $args) 1) (eq $0 -)) {
        d = [$cd-prev]
    }
    cd-prev = $pwd
    builtin:cd $@d
}
fn lf {
    t = (mktemp --tmpdir lf_last_dir_XXX)
    e:lf -last-dir-path $t $@args
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

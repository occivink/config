use bindings
use timer
use completers
use smart-matcher
use str

set E:EDITOR = kak
set E:PATH = (str:join : [~/bin ~/.config/bin $E:PATH])
set E:KAKOUNE_POSIX_SHELL = /bin/dash

set edit:max-height = 25

fn ls {|@args| e:ls --color=auto --group-directories-first --human-readable --quoting-style=literal --indicator-style=classify -v $@args }
fn ffmpeg {|@args| e:ffmpeg -hide_banner $@args }
fn cp {|@args| e:cp --no-clobber $@args }
fn mv {|@args| e:mv --no-clobber $@args }
fn k {|@args| e:kak $@args }
fn g {|@args| e:git $@args }
fn cal {|@args| e:cal --monday $@args }
fn fzf {|@args| e:fzf --height 40% $@args }

set edit:prompt = {
    use re
    # abbreviate path by shortening the parent directories
    styled " "(re:replace '([^/])[^/]*/' '$1/' (tilde-abbr $pwd))" "  bg-blue bold
    if (not-eq $E:SSH_CLIENT "") {
        styled " "(cat /etc/hostname)" " "white bg-red bold"
    }
    styled " λ " white bg-green bold
    put " "
}
set edit:rprompt = { }

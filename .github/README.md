This repo uses a setup similar to what is described in [this article](https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/) and should be setup like this:

```
# don't use a bare repository, they're not meant to be manipulated locally
git clone --no-checkout $URL ~/.config/
git --git-dir ~/.config/.git --work-tree ~ checkout
# `conf` is a simple wrapper that does 'git --git-dir ~/.config/.git --work-tree ~ $@'
conf config status.showUntrackedFiles no
```

# Source

Some of the stuff in this repo is just a read-only view of other repos, for (my own) convenience. I've listed below their sources.

For anything not mentioned, this repo is considered the source.

## [kakoune](https://github.com/mawww/kakoune)

* [expand](https://github.com/occivink/kakoune-expand)
* [phantom-selection](https://github.com/occivink/kakoune-phantom-selection)
* [find](https://github.com/occivink/kakoune-find)
* [sudo-write](https://github.com/occivink/kakoune-sudo-write)
* [vertical-selection](https://github.com/occivink/kakoune-vertical-selection)
* [snippets](https://github.com/occivink/kakoune-snippets)
* [buffer-switcher](https://github.com/occivink/kakoune-buffer-switcher)
* [number-comparison](https://github.com/occivink/kakoune-number-comparison)
* [sort-selections](https://github.com/occivink/kakoune-sort-selections)
* [filetree](https://github.com/occivink/kakoune-filetree)
* [gdb](https://github.com/occivink/kakoune-gdb)

## [mpv](https://github.com/mpv-player/mpv) (and mvi, mmp)

* [crop, encode, blacklist-extensions, blur-edges, seek-to](https://github.com/occivink/mpv-scripts)
* [gallery](https://github.com/occivink/mpv-gallery-view)
* [image-viewer](https://github.com/occivink/mpv-image-viewer)
* [music-player](https://github.com/occivink/mpv-music-player)
* [visualizer](https://github.com/mfcc64/mpv-scripts)

mvi and mmp are just aliases to different profiles of mpv. More specifically, I use mpv for videos, mvi for images and mmp for music.

## [elvish](https://github.com/elves/elvish)

* [smart-matcher](https://github.com/xiaq/edit.elv/blob/master/smart-matcher.elv)

## misc

* [diff-so-fancy](https://github.com/so-fancy/diff-so-fancy)

# License

Anything that has a standalone source (see above) falls under the same license as the source.

Anything not explicity mentioned is UNLICENSED.

fn find [&dirs=$true &files=$true &hidden=$false &depth_first=$true]{
    put_files = [all dirs]{
        i=0
        next_dir = {
            if (has-key $dirs $i) {
                put $dirs[$i][:-1]
                i = (+ $i 1)
            } else {
                put ''
            }
        }
        dir = ($next_dir)
        put $@all | each [f]{
            if (eq $f $dir) {
                dir = ($next_dir)
            } else {
                put $f
            }
        }
    }
    stack=['.']
    while (not-eq $stack []) {
        loc @stack = $@stack
        d f = [] []
        if $hidden {
            d = [$loc/*[nomatch-ok][match-hidden]/]
            f = [($put_files [$loc/*[nomatch-ok][match-hidden]] $d)]
        } else {
            d = [$loc/*[nomatch-ok]/]
            f = [($put_files [$loc/*[nomatch-ok]] $d)]
        }
        if $dirs { put $loc }
        if $files { put $@f }
        if $depth_first {
            stack = [$@d $@stack]
        } else {
            stack = [$@stack $@d]
        }
    }
}

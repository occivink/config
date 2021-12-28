fn find {|&dirs=$true &files=$true &hidden=$false &depth_first=$true|
    var put_files = {|all dirs|
        var i = 0
        var next_dir = {
            if (< $i (count $dirs)) {
                put $dirs[$i][:-1]
                set i = (+ $i 1)
            } else {
                put ''
            }
        }
        var dir = ($next_dir)
        put $@all | each {|f|
            if (eq $f $dir) {
                set dir = ($next_dir)
            } else {
                put $f
            }
        }
    }
    var stack = ['.']
    while (not-eq $stack []) {
        var loc
        set loc @stack = $@stack
        var d f = [] []
        if $hidden {
            set d = [$loc/*[nomatch-ok][match-hidden]/]
            set f = [($put_files [$loc/*[nomatch-ok][match-hidden]] $d)]
        } else {
            set d = [$loc/*[nomatch-ok]/]
            set f = [($put_files [$loc/*[nomatch-ok]] $d)]
        }
        if $dirs { put $loc }
        if $files { put $@f }
        if $depth_first {
            set stack = [$@d $@stack]
        } else {
            set stack = [$@stack $@d]
        }
    }
}

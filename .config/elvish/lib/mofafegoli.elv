fn to-mofafegoli {|num|
    var cent-to-syllable = {|cent|
        set cent = (+ $cent 0)
        var f = (% $cent 5)
        var t = (/ (- $cent $f) 5)
        var r = [a e i o u][$f]
        put [b c d f g h j k l m n p r s t v w x y z][$t]$r
    }
    if (== (% (count $num) 2) 1) { set num = 0$num }
    use re
    echo &sep='' (re:find '..' $num | each {|m| $cent-to-syllable $m[text] })
}

fn to-mofafegoli {|num|
    var cent-to-syllable = {|cent|
        print $cent
        put $cent
    }
    if (== (% (count $num) 2) 1) { set num = 0$num }
    use re
    re:find '..' $num | each {|m| $cent-to-syllable $m[text] }
}

fn from-mofafegoli {|mofa|
    var first-syllable = $true
    syllable-to-cent = {|syllable|
        var r1 = (* 5 [&b=0 &c=1 &d=2 &f=3 &g=4 &h=5 &j=6 &k=7 &l=8 &m=9 &n=10 &p=11 &r=12 &s=13 &t=14 &v=15 &w=16 &x=17 &y=18 &z=19][$syllable[0]])
        var r2 = [&a=0 &e=1 &i=2 &o=3 &u=4][$syllable[1]]
        var r = (+ $r1 $r2)
        if (and (not $first-syllable) (== (count (base 10 $r)) 1)) { set r = 0$r }
        set first-syllable = $false
        put $r
    }
    use re
    echo &sep='' (re:find '..' $mofa | each {|m| $syllable-to-cent $m[text] })
}

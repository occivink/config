fn to-mofafegoli [num]{
    cent-to-syllable = [cent]{
        cent=(+ $cent 0)
        f=(% $cent 5)
        t=(/ (- $cent $f) 5)
        r=[a e i o u][$f]
        put [b c d f g h j k l m n p r s t v w x y z][$t]$r
    }
    if (== (% (count $num) 2) 1) { num=0$num }
    use re
    echo &sep='' (re:find '..' $num | each [m]{ $cent-to-syllable $m[text] })
}

fn from-mofafegoli [mofa]{
    first-syllable=$true
    syllable-to-cent = [syllable]{
        r1=(* 5 [&b=0 &c=1 &d=2 &f=3 &g=4 &h=5 &j=6 &k=7 &l=8 &m=9 &n=10 &p=11 &r=12 &s=13 &t=14 &v=15 &w=16 &x=17 &y=18 &z=19][$syllable[0]])
        r2=[&a=0 &e=1 &i=2 &o=3 &u=4][$syllable[1]]
        r=(+ $r1 $r2)
        if (and (not $first-syllable) (== (count $r) 1)) { r=0$r }
        first-syllable=$false
        put $r
    }
    use re
    echo &sep='' (re:find '..' $mofa | each [m]{ $syllable-to-cent $m[text] })
}

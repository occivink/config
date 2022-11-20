# rename session with a friendlier name when starting
## originally idsession.kak by lenormf

eval %sh{
    adj=$(printf %s\\n kabbalistic kafkaesque keeled knavish knotted keen kind kindred kindled kinetic knowledgeable kempt kosher kitsch kleptomaniac)
    nouns=$(printf %s\\n keeper keg kernel kettle key kid kimono king kingdom kiosk kitchen kite kitten klaxon knife kilt knight konga koala kangaroo kraken)

    rnd() {
        printf %s "$1" | shuf -n1
    }
    if test "$kak_session" -ge 0 2>/dev/null; then
        printf 'try %%{ rename-session %s-%s }' $(rnd "$adj") $(rnd "$nouns")
    fi
}

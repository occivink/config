# rename session with a friendlier name when starting
## originally idsession.kak by lenormf

try %{ rename-session %sh{
    adjectives="kabbalistic kafkaesque keeled knavish knotted keen kind kindred kindled kinetic knowledgeable kempt kosher kitsch kleptomaniac"
    nouns="keeper keg kernel kettle key kid kimono king kingdom kiosk kitchen kite kitten klaxon knife kilt knight konga koala kangaroo kraken"
    for noun in $nouns; do
        for adj in $adjectives; do
            printf '%s-%s\n' "$adj" "$noun"
        done
    done | shuf -n1
} }

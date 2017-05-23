##
## idsession.kak by lenormf
## Rename newly created sessions to human readable names
##

hook global KakBegin .* %{ %sh{
    readonly adj=$(printf %s\\n kabbalistic keeled knavish knotted keen kind knowledgeable kempt kosher kitsch kleptomaniac)
    readonly nouns=$(printf %s\\n keeper keg kernel kettle key kid kimono kingdom kiosk kitchen kite kitten klaxon knife kilt knight konga koala kangaroo kraken)

    rnd() {
        printf %s "$1" | shuf -n1
    }

    printf 'rename-session %s-%s' $(rnd "$adj") $(rnd "$nouns")
} }

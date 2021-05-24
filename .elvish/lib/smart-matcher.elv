# A matcher that tries the folldwing matchers: prefix match, smart-case prefix
# match, substring match, smart-case substring match, subsequence match and
# smart-case subsequence match.
#
# Usage:
# use github.com/xiaq/edit.elv/smart-matcher

fn match [seed]{
    var inputs = [(all)]
    var results = []
    for matcher [$edit:match-prefix~ $edit:match-substr~ $edit:match-subseq~] {
        set results = [(put $@inputs | $matcher $seed)]
        if (or $@results) {
            put $@results
            return
        }
        set results = [(put $@inputs | $matcher &smart-case $seed)]
        if (or $@results) {
            put $@results
            return
        }
    }
    put $@results
}

set edit:completion:matcher[''] = $match~

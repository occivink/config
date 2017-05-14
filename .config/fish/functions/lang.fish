function lang
	set -l new_lang en_US
    if test (count $argv) -eq 1; and test $argv[1] = "fr"
        set new_lang fr
    end
    setxkbmap $new_lang
end

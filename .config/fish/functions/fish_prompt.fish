function fish_prompt
    set -l last_status $status

    #pwd
    set_color white -b blue -o
    printf " %s " (prompt_pwd)

    #time
    if test -n $CMD_DURATION -a $CMD_DURATION -gt 5000
        set_color white -b purple -o
        printf " "
        if test $CMD_DURATION -gt 3600000
            sh -c 'printf "%dh%02dm" $(('$CMD_DURATION' / 3600000)) $(('$CMD_DURATION' % 3600000 / 60000))'
        else if test $CMD_DURATION -gt 60000
            sh -c 'printf "%dm%02ds" $(('$CMD_DURATION' / 60000)) $(('$CMD_DURATION' % 60000 / 1000))'
        else
            sh -c 'printf "%ds" $(('$CMD_DURATION' / 1000))'
        end
        printf " "
    end

    #status
    set_color white -o
    if test $last_status -eq 0
        set_color -b green
    else
        set_color -b red
    end
    printf " λ "
    set_color normal

    #space
    printf " \n"
    
    #⠂ ⠃ ⠇ ⠗ ⠷ ⠿
end

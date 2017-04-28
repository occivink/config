function at
    if not date -d $argv >/dev/null ^/dev/null
        echo "Not a date"
        return 1
    end
    set -l time_to_sleep (math (date +"%s" -d $argv) - (date +"%s"))
    if test $time_to_sleep -lt 0
        echo "The specified date has already passed" >&2
        return 1
    end
    echo "Sleeping until "(date -d $argv)
    echo "aka this much time "(date -d@$time_to_sleep -u "+%T")
    sleep $time_to_sleep
end

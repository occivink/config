#!/bin/sh
date -d "$argv" >/dev/null ^/dev/null || { echo "Not a date"; exit 1 }
s=$(printf "%s - %s" $(date +%s -d $argv) $(date +%s | bc))
    if test $time_to_sleep -lt 0
        echo "The specified date has already passed" >&2
        return 1
    end
    echo "Sleeping until "(date -d $argv)
    echo "aka this much time "(date -d@$time_to_sleep -u "+%T")
    sleep $time_to_sleep
end

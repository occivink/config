fn now { date +%s }
time_start = (now)

edit:after-readline=[ $@edit:after-readline { time_start = (now) } ]
edit:before-readline=[ $@edit:before-readline {
    time_taken = (- (now) $time_start)
    if (> $time_taken 3600) {
        seconds = (% $time_taken 60)
        minutes = (/ (- (% $time_taken 3600) $seconds) 60)
        hours = (/ (- $time_taken (* $minutes 60) $seconds) 3600)
        echo (edit:styled " "$hours"h"(printf %02d\n $minutes)"m " "bg-magenta;bold")
    } elif (> $time_taken 60) {
        seconds = (% $time_taken 60)
        minutes = (/ (- $time_taken $seconds) 60)
        echo (edit:styled " "$minutes"m"(printf %02d\n $seconds)"s " "bg-magenta;bold")
    } elif (> $time_taken 5) {
        echo (edit:styled " "$time_taken"s " "bg-magenta;bold")
    }
} ]

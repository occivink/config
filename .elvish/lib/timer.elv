fn now { date +%s }
time_start = (now)

edit:after-readline = [ $@edit:after-readline [@a]{ time_start = (now) } ]
edit:before-readline = [ $@edit:before-readline {
    elapsed = (- (now) $time_start)
    if (> $elapsed 3600) {
        seconds = (% $elapsed 60)
        minutes = (/ (- (% $elapsed 3600) $seconds) 60)
        hours = (/ (- $elapsed (* $minutes 60) $seconds) 3600)
        echo (edit:styled " "$hours"h"(printf %02d $minutes)"m " "bg-magenta;bold") > /dev/tty
    } elif (> $elapsed 60) {
        seconds = (% $elapsed 60)
        minutes = (/ (- $elapsed $seconds) 60)
        echo (edit:styled " "$minutes"m"(printf %02d $seconds)"s " "bg-magenta;bold") > /dev/tty
    } elif (> $elapsed 5) {
        echo (edit:styled " "$elapsed"s " "bg-magenta;bold") > /dev/tty
    }
} ]

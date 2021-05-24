fn now { date +%s }
var time_start = (now)

set edit:after-readline = [ $@edit:after-readline [@a]{ time_start = (now) } ]
set edit:before-readline = [ $@edit:before-readline {
    var elapsed = (- (now) $time_start)
    if (> $elapsed 3600) {
        var seconds = (% $elapsed 60)
        var minutes = (/ (- (% $elapsed 3600) $seconds) 60)
        var hours = (/ (- $elapsed (* $minutes 60) $seconds) 3600)
        echo (styled " "$hours"h"(printf %02d $minutes)"m " bg-magenta bold) > /dev/tty
    } elif (> $elapsed 60) {
        var seconds = (% $elapsed 60)
        var minutes = (/ (- $elapsed $seconds) 60)
        echo (styled " "$minutes"m"(printf %02d $seconds)"s " bg-magenta bold) > /dev/tty
    } elif (> $elapsed 5) {
        echo (styled " "$elapsed"s " bg-magenta bold)
    }
} ]

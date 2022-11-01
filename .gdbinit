set startup-with-shell off

set history save on
set print pretty on
set print array on
set print array-indexes on

set print object on

set prompt gdb> 

set pagination off

set auto-load safe-path /

set index-cache enabled on

set debuginfod enabled on

skip -gfi /usr/include/c++/*
skip -gfi /usr/include/c++/*/*
skip -gfi /usr/include/c++/*/*/*

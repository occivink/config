set startup-with-shell off

set history save on
set print pretty on
set print array on

set print object on

set prompt gdb> 

set pagination off

set auto-load safe-path /

python
import sys, os.path
sys.path.insert(0, os.path.expanduser('~/.config/gdb'))

import qt5printers
qt5printers.register_printers(gdb.current_objfile())

from STL.v6.printers import register_libstdcxx_printers
register_libstdcxx_printers (None)

sys.path.insert(0, os.path.expanduser('~/.config/gdb/eigen'))
from printers import register_eigen_printers
register_eigen_printers (None)

end

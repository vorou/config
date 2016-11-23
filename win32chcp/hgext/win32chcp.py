# win32chcp.py - helps Mercurial to produce readable output on Windows.
#
# Copyright (C) 2011 Andrei Polushin <polushin@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

'''switches the Windows console into an encoding actually used on output'''

import sys, os, codecs, ctypes, atexit
from mercurial.i18n import _
from mercurial import encoding

_cpaliases = {
    'utf-8': 'cp65001',
}

def _restoreconsoleencoding(inputcp, outputcp):
    _kernel32 = ctypes.windll.kernel32
    _kernel32.SetConsoleCP(inputcp)
    _kernel32.SetConsoleOutputCP(outputcp)

def uisetup(ui):
    if os.name != 'nt':
        ui.warn(_("[win32chcp] is not supported on this platform.\n"))
        return

    _kernel32 = ctypes.windll.kernel32
    enc = encoding.encoding
    cp = 0
    try:
        enc = codecs.lookup(enc).name
        enc = _cpaliases.get(enc, enc)
        if enc.startswith('cp'):
            enc = enc[2:]
        cp = int(enc)
        if not _kernel32.IsValidCodePage(cp):
            raise ctypes.WinError()
    except (LookupError, ValueError, ctypes.WinError):
        ui.warn(_("[win32chcp] unknown encoding: %s\n") % enc)
        return

    inputcp  = _kernel32.GetConsoleCP()
    outputcp = _kernel32.GetConsoleOutputCP()
    if cp == outputcp:
        return

    _kernel32.SetConsoleCP(cp)
    _kernel32.SetConsoleOutputCP(cp)
    if hasattr(sys.stdout, 'encoding') and sys.stdout.encoding:
        atexit.register(lambda: _restoreconsoleencoding(inputcp, outputcp))
    else:
        ui.warn(_("[win32chcp] switching your console encoding into cp%d\n") % cp)

from utils import *

class IODevice:
    """
    IODevice class is a base class for all devices connected to the Machine via IO lines.
    Some devices are read-only, some devices are write-only. A derived class must reimplement
    read_io() and/or write_io() functions according to the provided functionality
    """
    def __init__(self, startaddr, endaddr):
        self._startaddr = startaddr
        self._endaddr = endaddr

    def get_addr_space(self):
        return self._startaddr, self._endaddr

    def validate_addr(self, addr):
        if addr < self._startaddr or addr > self._endaddr:
            raise IOError(f"Incorrect IO address {addr:x}")

    def read_io(self, addr):
        self.validate_addr(addr)
        raise IOError(f"Reading IO {addr:x} is not allowed")

    def write_io(self, addr, value):
        self.validate_addr(addr)
        raise IOError(f"Writing IO {addr:x} is not allowed")

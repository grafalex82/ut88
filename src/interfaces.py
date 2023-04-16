from utils import *

class IO:
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

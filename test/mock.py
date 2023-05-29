import sys

sys.path.append('../src')

from interfaces import *

class MockIO(IODevice):
    def __init__(self, addr):
        IODevice.__init__(self, addr, addr)
        self._value = 0

    def read_io(self, addr):
        self.validate_io_addr(addr)
        return self._value

    def write_io(self, addr, value):
        self.validate_io_addr(addr)
        self._value = value

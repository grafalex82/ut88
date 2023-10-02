from utils import *
from interfaces import *

class ROM(MemoryDevice):
    def __init__(self, filename, startaddr):
        with open(filename, mode='rb') as f:
            self._rom = [x for x in f.read()]

        MemoryDevice.__init__(self, startaddr, startaddr + len(self._rom) - 1)


    def read_byte(self, addr):
        self.validate_addr(addr)
        return self._rom[addr - self._startaddr]


    def read_word(self, addr):
        self.validate_addr(addr)
        return self._rom[addr - self._startaddr] | self._rom[addr - self._startaddr + 1] << 8


    def read_burst(self, addr, count):
        self.validate_addr(addr)
        self.validate_addr(addr + count - 1)
        return self._rom[addr - self._startaddr : addr - self._startaddr + count]

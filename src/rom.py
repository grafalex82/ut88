from utils import *

class ROM:
    def __init__(self, filename, startaddr):
        with open(filename, mode='rb') as f:
            self._rom = f.read()

        self._startaddr = startaddr
        self._endaddr = self._startaddr + len(self._rom) - 1


    def _check_addr(self, addr):
        if addr < self._startaddr or addr > self._endaddr:
            raise MemoryError(f"Address 0x{addr:04x} is out of memory range 0x{self._startaddr:04x}-0x{self._endaddr:04x}")


    def get_start_addr(self):
        return self._startaddr


    def get_end_addr(self):
        return self._endaddr


    def read_byte(self, addr):
        self._check_addr(addr)
        return self._rom[addr - self._startaddr]


    def read_word(self, addr):
        self._check_addr(addr)
        return self._rom[addr - self._startaddr] | self._rom[addr - self._startaddr + 1] << 8

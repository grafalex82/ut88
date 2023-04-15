from utils import *

class RAM:
    """
    This class represent a general purpose memory at a given address space.
    The RAM memory supports read and write operations. Stack read and write
    operations are synonims for regular read and write operations as this
    memory type does not distinguish between memory and stack access.
    """
    def __init__(self, startaddr, endaddr):
        self._startaddr = startaddr
        self._endaddr = endaddr
        self._ram = [0] * (self._endaddr - self._startaddr + 1)


    def get_start_addr(self):
        return self._startaddr


    def get_end_addr(self):
        return self._endaddr


    def _check_addr(self, addr):
        if addr < self._startaddr or addr > self._endaddr:
            raise MemoryError(f"Address 0x{addr:04x} is out of memory range 0x{self._startaddr:04x}-0x{self._endaddr:04x}")


    def _check_value(self, value, max):
        if value < 0 or value > max:
            raise ValueError(f"Value {value:x} is out of range")


    def read_byte(self, addr):
        self._check_addr(addr)
        return self._ram[addr - self._startaddr]


    def read_word(self, addr):
        self._check_addr(addr)
        return self._ram[addr - self._startaddr] | self._ram[addr - self._startaddr + 1] << 8


    def write_byte(self, addr, value):
        self._check_addr(addr)
        self._check_value(value, 0xff)

        self._ram[addr - self._startaddr] = value


    def write_word(self, addr, value):
        self._check_addr(addr)
        self._check_value(value, 0xffff)

        self._ram[addr - self._startaddr] = value & 0xff
        self._ram[addr - self._startaddr + 1] = value >> 8

    
    def write_stack(self, ptr, value):
        self.write_word(ptr, value)


    def read_stack(self, ptr):
        return self.read_word(ptr)

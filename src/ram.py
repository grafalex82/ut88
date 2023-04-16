from utils import *
from interfaces import *

class RAM(MemoryDevice, StackDevice):
    """
    This class represent a general purpose memory at a given address space.
    The RAM memory supports read and write operations. Stack read and write
    operations are synonims for regular read and write operations as this
    memory type does not distinguish between memory and stack access.
    """
    def __init__(self, startaddr, endaddr):
        MemoryDevice.__init__(self, startaddr, endaddr)
        StackDevice.__init__(self, startaddr, endaddr)
        self._ram = [0] * (self._endaddr - self._startaddr + 1)


    def _check_value(self, value, max):
        if value < 0 or value > max:
            raise ValueError(f"Value {value:x} is out of range")


    def read_byte(self, addr):
        self.validate_addr(addr)
        return self._ram[addr - self._startaddr]


    def read_word(self, addr):
        self.validate_addr(addr)
        return self._ram[addr - self._startaddr] | self._ram[addr - self._startaddr + 1] << 8


    def write_byte(self, addr, value):
        self.validate_addr(addr)
        self._check_value(value, 0xff)

        self._ram[addr - self._startaddr] = value


    def write_word(self, addr, value):
        self.validate_addr(addr)
        self._check_value(value, 0xffff)

        self._ram[addr - self._startaddr] = value & 0xff
        self._ram[addr - self._startaddr + 1] = value >> 8

    
    def write_stack(self, ptr, value):
        self.write_word(ptr, value)


    def read_stack(self, ptr):
        return self.read_word(ptr)

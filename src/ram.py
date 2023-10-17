from common.utils import *

class RAM:
    """
        This class represent a general purpose memory at a given address space.
        The RAM memory supports read and write operations. Stack read and write
        operations are synonims for regular read and write operations as this
        memory type does not distinguish between memory and stack access.

        Note: this class maintains only the data buffer. Binding to a particular
        memory address is MemoryDevice's class responsibility
    """
    def __init__(self, size = 0):
        self.set_size(size)


    def get_size(self):
        return len(self._ram)


    def set_size(self, size):
        self._ram = [0] * size


    def _check_value(self, value, max):
        if value < 0 or value > max:
            raise ValueError(f"Value {value:x} is out of range")


    def read_byte(self, offset):
        return self._ram[offset]


    def read_word(self, offset):
        return self._ram[offset] | self._ram[offset + 1] << 8


    def read_burst(self, offset, count):
        return self._ram[offset : offset + count]


    def write_byte(self, offset, value):
        self._check_value(value, 0xff)
        self._ram[offset] = value


    def write_word(self, offset, value):
        self._check_value(value, 0xffff)

        self._ram[offset] = value & 0xff
        self._ram[offset + 1] = value >> 8

    
    def write_stack(self, offset, value):
        self.write_word(offset, value)


    def read_stack(self, offset):
        return self.read_word(offset)


    def write_burst(self, offset, data):
        self._ram[offset : offset + len(data)] = data



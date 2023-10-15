from utils import *

class ROM:
    """
        This class represent a read only memory, filled with a predefined data
        loaded from the file. The ROM supports only read operations, and allows
        reading the data in bytes or words.
        
        Note: this class maintains only the data buffer. Binding to a particular
        memory address is MemoryDevice's class responsibility
    """

    def __init__(self, filename):
        with open(filename, mode='rb') as f:
            self._rom = [x for x in f.read()]


    def get_size(self):
        return len(self._rom)


    def read_byte(self, offset):
        return self._rom[offset]


    def read_word(self, offset):
        return self._rom[offset] | self._rom[offset + 1] << 8


    def read_burst(self, offset, count):
        return self._rom[offset : offset + count]

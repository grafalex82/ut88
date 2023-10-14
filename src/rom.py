from utils import *

class ROM:
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

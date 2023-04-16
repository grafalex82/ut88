from utils import *
from interfaces import *

class LCD(MemoryDevice):
    """
    Basic UT-88 configuration outputs data to a 6 digit 7-segment LCD display.
    Schematically this display connected to the system as a 3-byte memory space.
    6 digits display values at addresses 0x9002, 0x9001, 0x9000 (left to right).
    Typical usage of the LCD display is to display some address at first 4 digits
    (stored at 0x9001 and 0x9002 address), and a data byte in the remaining 2 digits
    (stored at 0x9000). 
        
    """
    def __init__(self):
        MemoryDevice.__init__(self, 0x9000, 0x9002)
        self._ram = [0] * 3


    def _check_value(self, value, max):
        if value < 0 or value > max:
            raise ValueError(f"Value {value:x} is out of range")


    def write_byte(self, addr, value):
        self.validate_addr(addr)
        self._check_value(value, 0xff)

        self._ram[addr - self._startaddr] = value


    def write_word(self, addr, value):
        self.validate_addr(addr)
        self._check_value(value, 0xffff)

        self._ram[addr - self._startaddr] = value & 0xff
        self._ram[addr - self._startaddr + 1] = value >> 8

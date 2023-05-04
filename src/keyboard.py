import pygame
from interfaces import *

class Keyboard(IODevice):
    def __init__(self):
        IODevice.__init__(self, 0x04, 0x07)
        # The only supported configuration is Port A output, B and C - input
        self.configure(0x8b)

        self._port_a = 0xff


    def configure(self, value):
        self._configuration = value
        assert self._configuration == 0x8b  


    def read_io(self, addr):
        # Address bits are inverted comparing to i8255 addresses
        if addr == 0x06:            # Port B
            return 0xff
        if addr == 0x05:            # Port C
            return 0xff

        raise IOError(f"Reading IO {addr:x} is not supported")

    def write_io(self, addr, value):
        self.validate_addr(addr)

        # Address bits are inverted comparing to i8255 addresses
        if addr == 0x04:            # Configuration register
            return self.configure(value)
        if addr == 0x07:            # Port A
            self._port_a = value         
            return
        
        IOError(f"Writing IO {addr:x} is not supported")

    


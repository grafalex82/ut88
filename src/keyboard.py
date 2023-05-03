import pygame
from interfaces import *

class Keyboard(IODevice):
    def __init__(self):
        IODevice.__init__(self, 0x04, 0x07)
        self._configuration = 0


    def configure(self, value):
        self._configuration = value


    def write_io(self, addr, value):
        self.validate_addr(addr)

        if addr == 0x04:
            self.configure(value)

    


import pygame
from interfaces import *

class Keyboard(IODevice):
    def __init__(self):
        IODevice.__init__(self, 0x04, 0x07)
        # The only supported configuration is Port A output, B and C - input
        self.configure(0x8b)

        self._port_a = 0xff
        self._pressed_key = (0xff, 0xff)

        self._key_map = {}
        self._key_map['0'] = (0xfe, 0xfe)
        self._key_map['1'] = (0xfe, 0xfd)
        self._key_map['2'] = (0xfe, 0xfb)
        self._key_map['3'] = (0xfe, 0xf7)
        self._key_map['4'] = (0xfe, 0xef)
        self._key_map['5'] = (0xfe, 0xdf)
        self._key_map['6'] = (0xfe, 0xbf)

        self._key_map['7'] = (0xfd, 0xfe)
        self._key_map['8'] = (0xfd, 0xfd)
        self._key_map['9'] = (0xfd, 0xfb)
        self._key_map[':'] = (0xfd, 0xf7)
        self._key_map[';'] = (0xfd, 0xef)
        self._key_map[','] = (0xfd, 0xdf)
        self._key_map['-'] = (0xfd, 0xbf)

        self._key_map['.'] = (0xfb, 0xfe)
        self._key_map['/'] = (0xfb, 0xfd)
        self._key_map['@'] = (0xfb, 0xfb)
        self._key_map['A'] = (0xfb, 0xf7)
        self._key_map['B'] = (0xfb, 0xef)
        self._key_map['C'] = (0xfb, 0xdf)
        self._key_map['D'] = (0xfb, 0xbf)

        self._key_map['E'] = (0xf7, 0xfe)
        self._key_map['F'] = (0xf7, 0xfd)
        self._key_map['G'] = (0xf7, 0xfb)
        self._key_map['H'] = (0xf7, 0xf7)
        self._key_map['I'] = (0xf7, 0xef)
        self._key_map['J'] = (0xf7, 0xdf)
        self._key_map['K'] = (0xf7, 0xbf)

        self._key_map['L'] = (0xef, 0xfe)
        self._key_map['M'] = (0xef, 0xfd)
        self._key_map['N'] = (0xef, 0xfb)
        self._key_map['O'] = (0xef, 0xf7)
        self._key_map['P'] = (0xef, 0xef)
        self._key_map['Q'] = (0xef, 0xdf)
        self._key_map['R'] = (0xef, 0xbf)

        self._key_map['S'] = (0xdf, 0xfe)
        self._key_map['T'] = (0xdf, 0xfd)
        self._key_map['U'] = (0xdf, 0xfb)
        self._key_map['V'] = (0xdf, 0xf7)
        self._key_map['W'] = (0xdf, 0xef)
        self._key_map['X'] = (0xdf, 0xdf)
        self._key_map['Y'] = (0xdf, 0xbf)

        self._key_map['Z'] = (0xbf, 0xfe)
        self._key_map['['] = (0xbf, 0xfd)
        self._key_map['\\'] = (0xbf, 0xfb)
        self._key_map[']'] = (0xbf, 0xf7)
        self._key_map['^'] = (0xbf, 0xef)
        self._key_map['_'] = (0xbf, 0xdf)

#        self._key_map[''] = ()


    def configure(self, value):
        self._configuration = value
        assert self._configuration == 0x8b  


    def read_io(self, addr):
        # Address bits are inverted comparing to i8255 addresses
        if addr == 0x06:            # Port B
            # Return key scan line if scan column matches previously set on Port A
            if self._pressed_key[0] == self._port_a: 
                return self._pressed_key[1] & 0x7f  # MSB is unused, but for some reason checked in the code
            return 0x7f
        
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

    
    def handle_key_event(self, event):
        if event.type == pygame.TEXTINPUT:
            ch = event.text.upper()
            if ch in self._key_map:
                self._pressed_key = self._key_map[ch]
                return

        self._pressed_key = (0xff, 0xff)

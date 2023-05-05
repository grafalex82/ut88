import pygame
from interfaces import *

class Keyboard(IODevice):
    def __init__(self):
        IODevice.__init__(self, 0x04, 0x07)
        # The only supported configuration is Port A output, B and C - input
        self.configure(0x8b)

        self._port_a = 0xff
        self._port_c = 0xff
        self._pressed_key = (0xff, 0xff, 0xff)

        self._key_map = {}
        self._key_map['0'] = (0xfe, 0xfe, 0xff)     # Char code 0x30
        self._key_map['1'] = (0xfe, 0xfd, 0xff)     # Char code 0x31
        self._key_map['2'] = (0xfe, 0xfb, 0xff)     # Char code 0x32
        self._key_map['3'] = (0xfe, 0xf7, 0xff)     # Char code 0x33
        self._key_map['4'] = (0xfe, 0xef, 0xff)     # Char code 0x34
        self._key_map['5'] = (0xfe, 0xdf, 0xff)     # Char code 0x35
        self._key_map['6'] = (0xfe, 0xbf, 0xff)     # Char code 0x36

        self._key_map['7'] = (0xfd, 0xfe, 0xff)     # Char code 0x37
        self._key_map['8'] = (0xfd, 0xfd, 0xff)     # Char code 0x38
        self._key_map['9'] = (0xfd, 0xfb, 0xff)     # Char code 0x39
        self._key_map[':'] = (0xfd, 0xf7, 0xff)     # Char code 0x3a
        self._key_map[';'] = (0xfd, 0xef, 0xff)     # Char code 0x3b
        self._key_map[','] = (0xfd, 0xdf, 0xff)     # Char code 0x2c
        self._key_map['-'] = (0xfd, 0xbf, 0xff)     # Char code 0x2d

        self._key_map['.'] = (0xfb, 0xfe, 0xff)     # Char code 0x2e
        self._key_map['/'] = (0xfb, 0xfd, 0xff)     # Char code 0x2f
        self._key_map['@'] = (0xfb, 0xfb, 0xff)     # Char code 0x40
        self._key_map['A'] = (0xfb, 0xf7, 0xff)     # Char code 0x41
        self._key_map['B'] = (0xfb, 0xef, 0xff)     # Char code 0x42
        self._key_map['C'] = (0xfb, 0xdf, 0xff)     # Char code 0x43
        self._key_map['D'] = (0xfb, 0xbf, 0xff)     # Char code 0x44

        self._key_map['E'] = (0xf7, 0xfe, 0xff)     # Char code 0x45
        self._key_map['F'] = (0xf7, 0xfd, 0xff)     # Char code 0x46
        self._key_map['G'] = (0xf7, 0xfb, 0xff)     # Char code 0x47
        self._key_map['H'] = (0xf7, 0xf7, 0xff)     # Char code 0x48
        self._key_map['I'] = (0xf7, 0xef, 0xff)     # Char code 0x49
        self._key_map['J'] = (0xf7, 0xdf, 0xff)     # Char code 0x4a
        self._key_map['K'] = (0xf7, 0xbf, 0xff)     # Char code 0x4b

        self._key_map['L'] = (0xef, 0xfe, 0xff)     # Char code 0x4c
        self._key_map['M'] = (0xef, 0xfd, 0xff)     # Char code 0x4d
        self._key_map['N'] = (0xef, 0xfb, 0xff)     # Char code 0x4e
        self._key_map['O'] = (0xef, 0xf7, 0xff)     # Char code 0x4f
        self._key_map['P'] = (0xef, 0xef, 0xff)     # Char code 0x50
        self._key_map['Q'] = (0xef, 0xdf, 0xff)     # Char code 0x51
        self._key_map['R'] = (0xef, 0xbf, 0xff)     # Char code 0x52

        self._key_map['S'] = (0xdf, 0xfe, 0xff)     # Char code 0x53
        self._key_map['T'] = (0xdf, 0xfd, 0xff)     # Char code 0x54
        self._key_map['U'] = (0xdf, 0xfb, 0xff)     # Char code 0x55
        self._key_map['V'] = (0xdf, 0xf7, 0xff)     # Char code 0x56
        self._key_map['W'] = (0xdf, 0xef, 0xff)     # Char code 0x57
        self._key_map['X'] = (0xdf, 0xdf, 0xff)     # Char code 0x58
        self._key_map['Y'] = (0xdf, 0xbf, 0xff)     # Char code 0x59

        self._key_map['Z'] = (0xbf, 0xfe, 0xff)     # Char code 0x5a
        self._key_map['['] = (0xbf, 0xfd, 0xff)     # Char code 0x5b
        self._key_map['\\'] = (0xbf, 0xfb, 0xff)    # Char code 0x5c
        self._key_map[']'] = (0xbf, 0xf7, 0xff)     # Char code 0x5d
        self._key_map['^'] = (0xbf, 0xef, 0xff)     # Char code 0x5e
        self._key_map['_'] = (0xbf, 0xdf, 0xff)     # Char code 0x5f

        # Alpha keys (with scan codes >= 0x40) with RUS button pressed (portC = 0xfe)
        self._key_map['Ю'] = (0xfb, 0xfb, 0xfe)     # Char code 0x60
        self._key_map['А'] = (0xfb, 0xf7, 0xfe)     # Char code 0x61
        self._key_map['Б'] = (0xfb, 0xef, 0xfe)     # Char code 0x62
        self._key_map['Ц'] = (0xfb, 0xdf, 0xfe)     # Char code 0x63
        self._key_map['Д'] = (0xfb, 0xbf, 0xfe)     # Char code 0x64

        self._key_map['Е'] = (0xf7, 0xfe, 0xfe)     # Char code 0x65
        self._key_map['Ф'] = (0xf7, 0xfd, 0xfe)     # Char code 0x66
        self._key_map['Г'] = (0xf7, 0xfb, 0xfe)     # Char code 0x67
        self._key_map['Х'] = (0xf7, 0xf7, 0xfe)     # Char code 0x68
        self._key_map['И'] = (0xf7, 0xef, 0xfe)     # Char code 0x69
        self._key_map['Й'] = (0xf7, 0xdf, 0xfe)     # Char code 0x6a
        self._key_map['К'] = (0xf7, 0xbf, 0xfe)     # Char code 0x6b

        self._key_map['Л'] = (0xef, 0xfe, 0xfe)     # Char code 0x6c
        self._key_map['М'] = (0xef, 0xfd, 0xfe)     # Char code 0x6d
        self._key_map['Н'] = (0xef, 0xfb, 0xfe)     # Char code 0x6e
        self._key_map['О'] = (0xef, 0xf7, 0xfe)     # Char code 0x6f
        self._key_map['П'] = (0xef, 0xef, 0xfe)     # Char code 0x70
        self._key_map['Я'] = (0xef, 0xdf, 0xfe)     # Char code 0x71
        self._key_map['Р'] = (0xef, 0xbf, 0xfe)     # Char code 0x72

        self._key_map['С'] = (0xdf, 0xfe, 0xfe)     # Char code 0x73
        self._key_map['Т'] = (0xdf, 0xfd, 0xfe)     # Char code 0x74
        self._key_map['У'] = (0xdf, 0xfb, 0xfe)     # Char code 0x75
        self._key_map['Ж'] = (0xdf, 0xf7, 0xfe)     # Char code 0x76
        self._key_map['В'] = (0xdf, 0xef, 0xfe)     # Char code 0x77
        self._key_map['Ь'] = (0xdf, 0xdf, 0xfe)     # Char code 0x78
        self._key_map['Ы'] = (0xdf, 0xbf, 0xfe)     # Char code 0x79

        self._key_map['З'] = (0xbf, 0xfe, 0xfe)     # Char code 0x7a
        self._key_map['Ш'] = (0xbf, 0xfd, 0xfe)     # Char code 0x7b
        self._key_map['Э'] = (0xbf, 0xfb, 0xfe)     # Char code 0x7c
        self._key_map['Щ'] = (0xbf, 0xf7, 0xfe)     # Char code 0x7d
        self._key_map['Ч'] = (0xbf, 0xef, 0xfe)     # Char code 0x7e


#        self._key_map[''] = ()


    def configure(self, value):
        self._configuration = value
        assert self._configuration == 0x8b  


    def read_io(self, addr):
        # Address bits are inverted comparing to i8255 addresses
        if addr == 0x06:            # Port B
            # Return key scan line if scan column matches previously set on Port A
            if self._pressed_key[0] == self._port_a: 
                self._port_c = self._pressed_key[2]
                return self._pressed_key[1] & 0x7f  # MSB is unused, but for some reason checked in the code
            return 0x7f
        
        if addr == 0x05:            # Port C
            return self._port_c

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
        # self._port_c = 0xff
        # mods = pygame.key.get_mods()
        # if mods & pygame.KMOD_CTRL:
        #     self._port_c &= 0xfd
        # if mods & pygame.KMOD_ALT:
        #     self._port_c &= 0xfb

        if event.type == pygame.TEXTINPUT:
            ch = event.text.upper()
            if ch in self._key_map:
                self._pressed_key = self._key_map[ch]
                return

        self._pressed_key = (0xff, 0xff, 0xff)

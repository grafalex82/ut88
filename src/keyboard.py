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
        self._key_map[' '] = (0xbf, 0xdf, 0xff)     # Char code 0x20

        # Some symbols are entered with a 'Shift' key (Special Symbol key, port C = 0xfb)
        #self._key_map[' '] = (0xfe, 0xfe, 0xfd)     # Char code 0x20   # Shift-0 generates a space
        self._key_map['!'] = (0xfe, 0xfd, 0xfb)     # Char code 0x21
        self._key_map['"'] = (0xfe, 0xfb, 0xfb)     # Char code 0x22
        self._key_map['#'] = (0xfe, 0xf7, 0xfb)     # Char code 0x23
        self._key_map['$'] = (0xfe, 0xef, 0xfb)     # Char code 0x24    # There is no $ in the font. Strange symbol is printed instead
        self._key_map['%'] = (0xfe, 0xdf, 0xfb)     # Char code 0x25
        self._key_map['&'] = (0xfe, 0xbf, 0xfb)     # Char code 0x26

        self._key_map['\''] = (0xfd, 0xfe, 0xfb)    # Char code 0x27
        self._key_map['('] = (0xfd, 0xfd, 0xfb)     # Char code 0x28
        self._key_map[')'] = (0xfd, 0xfb, 0xfb)     # Char code 0x29
        self._key_map['*'] = (0xfd, 0xf7, 0xfb)     # Char code 0x2a
        self._key_map['+'] = (0xfd, 0xef, 0xfb)     # Char code 0x2b
        self._key_map['<'] = (0xfd, 0xdf, 0xfb)     # Char code 0x3c
        self._key_map['='] = (0xfd, 0xbf, 0xfb)     # Char code 0x3d

        self._key_map['>'] = (0xfb, 0xfe, 0xfb)     # Char code 0x3e
        self._key_map['?'] = (0xfb, 0xfd, 0xfb)     # Char code 0x3f

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

        self._key_codes_map = {}
        self._key_codes_map[pygame.K_RIGHT]     = (0x7f, 0xfe, 0xff)    # Char code 0x18
        self._key_codes_map[pygame.K_LEFT]      = (0x7f, 0xfd, 0xff)    # Char code 0x08
        self._key_codes_map[pygame.K_UP]        = (0x7f, 0xfb, 0xff)    # Char code 0x19
        self._key_codes_map[pygame.K_DOWN]      = (0x7f, 0xf7, 0xff)    # Char code 0x1a
        self._key_codes_map[pygame.K_RETURN]    = (0x7f, 0xef, 0xff)    # Char code 0x0d
        self._key_codes_map[pygame.K_DELETE]    = (0x7f, 0xdf, 0xff)    # Char code 0x1f (Clear screen)
        self._key_codes_map[pygame.K_HOME]      = (0x7f, 0xbf, 0xff)    # Char code 0x0c

        self._ctrl_codes_map = {}
        self._ctrl_codes_map[pygame.K_a]        = (0xfb, 0xf7, 0xfd)    # Char code 0x01
        self._ctrl_codes_map[pygame.K_b]        = (0xfb, 0xef, 0xfd)    # Char code 0x02
        self._ctrl_codes_map[pygame.K_c]        = (0xfb, 0xdf, 0xfd)    # Char code 0x03
        self._ctrl_codes_map[pygame.K_d]        = (0xfb, 0xbf, 0xfd)    # Char code 0x04

        self._ctrl_codes_map[pygame.K_e]        = (0xf7, 0xfe, 0xfd)    # Char code 0x05
        self._ctrl_codes_map[pygame.K_f]        = (0xf7, 0xfd, 0xfd)    # Char code 0x06
        self._ctrl_codes_map[pygame.K_g]        = (0xf7, 0xfb, 0xfd)    # Char code 0x07
        self._ctrl_codes_map[pygame.K_h]        = (0xf7, 0xf7, 0xfd)    # Char code 0x08
        self._ctrl_codes_map[pygame.K_i]        = (0xf7, 0xef, 0xfd)    # Char code 0x09
        self._ctrl_codes_map[pygame.K_j]        = (0xf7, 0xdf, 0xfd)    # Char code 0x0a
        self._ctrl_codes_map[pygame.K_k]        = (0xf7, 0xbf, 0xfd)    # Char code 0x0b

        self._ctrl_codes_map[pygame.K_l]        = (0xef, 0xfe, 0xfd)    # Char code 0x0c
        self._ctrl_codes_map[pygame.K_m]        = (0xef, 0xfd, 0xfd)    # Char code 0x0d
        self._ctrl_codes_map[pygame.K_n]        = (0xef, 0xfb, 0xfd)    # Char code 0x0e
        self._ctrl_codes_map[pygame.K_o]        = (0xef, 0xf7, 0xfd)    # Char code 0x0f
        self._ctrl_codes_map[pygame.K_p]        = (0xef, 0xef, 0xfd)    # Char code 0x10
        self._ctrl_codes_map[pygame.K_q]        = (0xef, 0xdf, 0xfd)    # Char code 0x11
        self._ctrl_codes_map[pygame.K_r]        = (0xef, 0xbf, 0xfd)    # Char code 0x12

        self._ctrl_codes_map[pygame.K_s]        = (0xdf, 0xfe, 0xfd)    # Char code 0x13
        self._ctrl_codes_map[pygame.K_t]        = (0xdf, 0xfd, 0xfd)    # Char code 0x14
        self._ctrl_codes_map[pygame.K_u]        = (0xdf, 0xfb, 0xfd)    # Char code 0x15
        self._ctrl_codes_map[pygame.K_v]        = (0xdf, 0xf7, 0xfd)    # Char code 0x16
        self._ctrl_codes_map[pygame.K_w]        = (0xdf, 0xef, 0xfd)    # Char code 0x17
        self._ctrl_codes_map[pygame.K_x]        = (0xdf, 0xdf, 0xfd)    # Char code 0x18
        self._ctrl_codes_map[pygame.K_y]        = (0xdf, 0xbf, 0xfd)    # Char code 0x19

        self._ctrl_codes_map[pygame.K_z]        = (0xbf, 0xfe, 0xfd)    # Char code 0x1a
        self._ctrl_codes_map[pygame.K_COMMA]    = (0xbf, 0xfd, 0xfd)    # Char code 0x1b
        self._ctrl_codes_map[pygame.K_PERIOD]   = (0xbf, 0xfb, 0xfd)    # Char code 0x1c
        self._ctrl_codes_map[pygame.K_SEMICOLON]= (0xbf, 0xf7, 0xfd)    # Char code 0x1d
        self._ctrl_codes_map[pygame.K_QUOTE]    = (0xbf, 0xef, 0xfd)    # Char code 0x1e
        self._ctrl_codes_map[pygame.K_SLASH]    = (0xbf, 0xdf, 0xfd)    # Char code 0x1f


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
        if event.type == pygame.TEXTINPUT:
            ch = event.text.upper()
            if ch in self._key_map:
                self._pressed_key = self._key_map[ch]
                return
        
        if event.type == pygame.KEYDOWN:
            if event.key in self._key_codes_map:
                self._pressed_key = self._key_codes_map[event.key]
                return
            
            if event.key in self._ctrl_codes_map and (pygame.key.get_mods() & pygame.KMOD_CTRL):
                self._pressed_key = self._ctrl_codes_map[event.key]
                return
            
        self._pressed_key = (0xff, 0xff, 0xff)

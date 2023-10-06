import pygame
from interfaces import *

def _ctrl_pressed():
    return (pygame.key.get_mods() & pygame.KMOD_CTRL) != 0


class RK86Keyboard():
    def __init__(self):
        self._port_a = 0xff
        self._port_c = 0xff
        self._pressed_key = (0xff, 0xff, 0xff)

        self._key_map = {}
        self._key_map['A'] = (0xef, 0xfd, 0xff)     # Char code 0x41


    def set_columns(self, value):
        self._port_a = value


    def read_rows(self):
        # Return key scan line if scan column matches previously set on Port A
        if self._pressed_key[0] == self._port_a: 
            self._port_c = self._pressed_key[2]
            return self._pressed_key[1]
        
        # Special case when Monitor scans for any keyboard press
        if self._port_a == 0x00:
            return self._pressed_key[1]

        # Return 'nothing is pressed' otherwise
        return 0xff


    def read_ctrl_key(self):
        return True


    def read_shift_key(self):
        return True


    def read_rus_key(self):
        return True


    def handle_key_event(self, event):
        if event.type == pygame.KEYDOWN:
            # if event.key in self._ctrl_codes_map and _ctrl_pressed():
            #     self._pressed_key = self._ctrl_codes_map[event.key]
            #     return
            
            # if event.key in self._key_codes_map:
            #     self._pressed_key = self._key_codes_map[event.key]
            #     return
            
            ch = event.unicode.upper()
            if ch in self._key_map:
                self._pressed_key = self._key_map[ch]
                return
            
        if event.type == pygame.KEYUP:
            self._pressed_key = (0xff, 0xff, 0xff)

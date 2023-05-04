import os
import pygame

from utils import *
from interfaces import *
from ram import *

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")

CHAR_SIZE = 16

class Display(RAM):
    def __init__(self):
        RAM.__init__(self, 0xe800, 0xefff)

        with open(f"{resources_dir}/font.bin", mode='rb') as f:
            font = f.read()

        self._chars = [self._create_char(font[(c*8):((c+1)*8)], False) for c in range(128)]
        self._chars.extend([self._create_char(font[(c*8):((c+1)*8)], True) for c in range(128)])

    
    def _create_char(self, font, invert):
        white = (255, 255, 255)
        char = pygame.Surface((CHAR_SIZE, CHAR_SIZE))

        for row in range(8):
            for col in range(8):
                bitvalue = font[row] & (0x80 >> col) != 0

                if invert:
                    bitvalue != bitvalue

                if not bitvalue:
                    char.set_at((col*2, row*2), white)
                    char.set_at((col*2, row*2+1), white)
                    char.set_at((col*2+1, row*2), white)
                    char.set_at((col*2+1, row*2+1), white)

        return char
    

    def update_screen(self, screen):
        addr = 0
        for row in range(32):
            for col in range(64):
                ch = self._ram[addr]
                addr += 1

                screen.blit(self._chars[ch], (col*CHAR_SIZE, row*CHAR_SIZE))

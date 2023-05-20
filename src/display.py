import os
import pygame

from utils import *
from interfaces import *
from ram import *

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")

CHAR_WIDTH = 12
CHAR_HEIGHT = 16

class Display(RAM):
    """
    UT-88 64x28 character display

    This class emulates the UT-88 display, that comes with the UT-88 Video Configuration. This is a
    64x28 monochrome character display. Each symbol can display a character in a 0x00-0x7f range.
    The most significant bit inverts pixels of the symbol.

    Technically the display is based on a two-port 2kb RAM. One port is connected to the computer, 
    and is a regular memory at 0xe800-0xefff range. Other port is used by the video signal generation
    schematic, that passes the read byte through the font generator. 

    Technically the video controller can display 32 lines, which will fully utilize the memory. But 
    this may not be fully visible on a typical TV. So the range is artificially limited to 28 lines, 
    and memory at 0xef00-0xefff range is unused by the video controller (and potentially can be utilized
    by user programs).
    
    Font generator is based on a 2 kb ROM, which is not connected to the data bus. Each symbol is
    a 6x8 bit matrix (bits are inverted), stored in the ROM as 8 consecutive bytes.


    Emulation notes:
    In order to decrease amount of calculation during each frame, the Display class detects memory
    write operations, and blit new char on the screen accordingly. On a regular display update 
    precalculated image is simply blit on the screen.
    """

    def __init__(self):
        RAM.__init__(self, 0xe800, 0xefff)

        with open(f"{resources_dir}/font.bin", mode='rb') as f:
            font = f.read()

        self._display = pygame.Surface((CHAR_WIDTH*64, CHAR_HEIGHT*28))

        self._chars = [self._create_char(font[(c*8):((c+1)*8)], False) for c in range(128)]
        self._chars.extend([self._create_char(font[(c*8):((c+1)*8)], True) for c in range(128)])

    
    def _create_char(self, font, invert):
        white = (255, 255, 255)
        char = pygame.Surface((CHAR_WIDTH, CHAR_HEIGHT))

        for row in range(8):
            for col in range(6):
                bitvalue = font[row] & (0x20 >> col) != 0

                if invert:
                    bitvalue = not bitvalue

                if not bitvalue:
                    char.set_at((col*2, row*2), white)
                    char.set_at((col*2, row*2+1), white)
                    char.set_at((col*2+1, row*2), white)
                    char.set_at((col*2+1, row*2+1), white)

        return char
    
    def write_byte(self, addr, value):
        # First store the byte as usual
        RAM.write_byte(self, addr, value)

        # Then update corresponding char on the screen
        addr -= 0xe800
        ch = self._ram[addr]
        col = addr % 0x40
        row = addr // 0x40
        self._display.blit(self._chars[ch], (col*CHAR_WIDTH, row*CHAR_HEIGHT))


    def update_screen(self, screen):
        screen.blit(self._display, (0, 0))

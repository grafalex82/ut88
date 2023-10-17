import os
import pygame

from common.utils import *
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

    The display is based on a two-port 2kb RAM. One port is connected to the computer, and is a regular
    memory (at 0xe800-0xefff range). Other port is used by the video signal generation schematic, 
    that passes the read byte through the font generator to the video output. 

    Technically the video controller can display 32 lines, which will fully utilize the memory. But 
    this may not be fully visible on a typical TV. So the range is artificially limited to 28 lines, 
    and memory at 0xef00-0xefff range is unused by the video controller (and potentially can be utilized
    by user programs).
    
    Font generator is based on a 2 kb ROM, which is not connected to the data bus. Each symbol is
    a 6x8 bit matrix (bits are inverted), stored in the ROM as 8 consecutive bytes.

    Original schematics published in the magazine is based on a 2k RAM morrored to two ranges: 0xe000-0xe7ff
    and 0xe800-0xefff. The 0xe800+ is a primary range, but some programs use 0xe000+ range in some cases.
    It does not matter which range to use on a real hardware. Under emulator 0xe000+ range usages were changed
    to 0xe800+ (there were just a few such cases).

    At the same time UT-88 OS Monitor treats these ranges differently: it uses 0xe800+ range for symbol 
    char codes, while 0xe000+ range is used for symbol attributes. Moreover the software is written in a way
    so that only MSB of each byte is used for attribute (meaning it writes garbage in other bits). Perhaps
    there was an alternate schematics that works this way, but on original schematics symbol highlighting
    used in UT-88 OS Monitor looks corrupted.

    This particular display class implements the alternate schematics (0xe000+ for attributes, 0xe800+ for
    char codes). This allows regular programs which use only 0xe800+ range still work as expected (MSB of each
    byte inverts the symbol), and UT-88 OS which uses 0xe000+ range for symbol attributes will also get
    working properly.

    Emulation notes:
    In order to decrease amount of calculation during each frame, the Display class detects memory
    write operations, and blit new char on the screen only when data is changing. On a regular display
    update precalculated image is simply blit on the screen.

    MemoryDevice interface notes:
    According to MemoryDevice guidelines, the Display class does not operate with absolute addresses. Instead, 
    it works with a memory buffer of a 4k size, while it is MemoryDevice responsibility to map this buffer
    to a target address (typically 0xe000). The Display class works with offsets in the buffer, where first
    2k cells (0x800 bytes) represent char attributes array, and second 2k represent char codes array.
    """

    def __init__(self):
        RAM.__init__(self, 0x1000)  # 0x800 bytes for chars, 0x800 bytes for inversion attribute

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
    
    def write_byte(self, offset, value):
        # Writing to 0xe000-0xe7ff is treated as changing symbol attribute. Take only MSB of the
        # value, and apply the inversion bit to the corresponding character in 0xe800-0xefff range
        if offset < 0x0800:
            char_offset = offset + 0x0800
            value = set_bit_value(RAM.read_byte(self, char_offset), 7, is_bit_set(value, 7))
            RAM.write_byte(self, char_offset, value)

        # Both attribute and char values updated as usual
        RAM.write_byte(self, offset, value)

        # Then update corresponding char on the screen
        offset &= 0x07ff
        ch = RAM.read_byte(self, 0x0800 + offset)
        col = offset % 0x40
        row = offset // 0x40
        self._display.blit(self._chars[ch], (col*CHAR_WIDTH, row*CHAR_HEIGHT))


    def update_screen(self, screen):
        screen.blit(self._display, (0, 0))

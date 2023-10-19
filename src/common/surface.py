import os
import pygame

CHAR_WIDTH = 12
CHAR_HEIGHT = 16

class DisplaySurface:
    """
        DisplaySurface is an utility class that represents a monocrome display surface, capable of
        displaying an array of chars (no graphics support). Each symbol can display a character in 
        a 0x00-0x7f range. The most significant bit inverts pixels of the symbol.

        The surface allows displaying chars according to a provided 6x8 font, with a possibility to
        switch font to an alternate in runtime. The font shall be presented as a 1k array, where each
        8 bytes represent a single character (bits are inverted). The character code must be within 
        0-127 range. The alternate font is loaded from the second 1k of the font file.
    """

    def __init__(self, font_file, width=64, height=28):
        self.load_font_file(font_file)
        self.set_size(width, height)


    def set_size(self, width, height):
        size = (CHAR_WIDTH*width, CHAR_HEIGHT*height)
        self._display = pygame.Surface(size)
        return size


    def load_font_file(self, font_file):
        with open(font_file, mode='rb') as f:
            self._font_data = f.read()

        self.select_font(False)


    def _get_bitmap(self, ch, alternate=False):
        offset = ch * 8 + (0x400 if alternate else 0)
        return self._font_data[offset : offset + 8]


    def _create_char(self, bitmap, invert):
        white = (255, 255, 255)
        char = pygame.Surface((CHAR_WIDTH, CHAR_HEIGHT))

        for row in range(8):
            for col in range(6):
                bitvalue = bitmap[row] & (0x20 >> col) != 0

                if invert:
                    bitvalue = not bitvalue

                if not bitvalue:
                    char.set_at((col*2, row*2), white)
                    char.set_at((col*2, row*2+1), white)
                    char.set_at((col*2+1, row*2), white)
                    char.set_at((col*2+1, row*2+1), white)

        return char


    def select_font(self, alternate=False):
        self._chars = [self._create_char(self._get_bitmap(c, alternate), False) for c in range(128)]
        self._chars.extend([self._create_char(self._get_bitmap(c, alternate), True) for c in range(128)])

    
    def update_char(self, col, row, ch):
        self._display.blit(self._chars[ch], (col*CHAR_WIDTH, row*CHAR_HEIGHT))


    def blit(self, screen):
        screen.blit(self._display, (0, 0))


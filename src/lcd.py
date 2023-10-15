import os
import pygame

from utils import *

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")

class LCD:
    """
        Basic UT-88 configuration outputs data to a 6 digit 7-segment LCD display.
        Schematically this display connected to the system as a 3-byte memory space.
        6 digits display values at addresses 0x9002, 0x9001, 0x9000 (left to right).
        Typical usage of the LCD display is to display some address at first 4 digits
        (stored at 0x9001 and 0x9002 address), and a data byte in the remaining 2 digits
        (stored at 0x9000). 
        
        Note: MemoryDevice class is responsible for binding LCD to the actual memory
        address, while this class maintains just 3 bytes of data.
    """
    def __init__(self):
        self._ram = [0] * 3

        self._images = [pygame.image.load(f"{resources_dir}/digit_{d:1X}.png") for d in range(0x10)]

        self._display = pygame.Surface((75*6, 94))


    def get_size(self):
        return 3

    def _draw_byte(self, screen, byte, x):
        digit1 = (byte & 0xf0) >> 4
        screen.blit(self._images[digit1], (x, 0))
        x += self._images[digit1].get_width()
        digit2 = byte & 0xf
        screen.blit(self._images[digit2], (x, 0))
        return x + self._images[digit2].get_width()


    def _update_screen_buffer(self):
        x = self._draw_byte(self._display, self._ram[2], 0)
        x = self._draw_byte(self._display, self._ram[1], x)
        self._draw_byte(self._display, self._ram[0], x)


    def update_screen(self, screen):
        screen.blit(self._display, (0, 0))


    def _check_value(self, value, max):
        if value < 0 or value > max:
            raise ValueError(f"Value {value:x} is out of range")


    def write_byte(self, offset, value):
        self._check_value(value, 0xff)

        self._ram[offset] = value

        self._update_screen_buffer()


    def write_word(self, offset, value):
        self._check_value(value, 0xffff)

        self._ram[offset] = value & 0xff
        self._ram[offset + 1] = value >> 8

        self._update_screen_buffer()

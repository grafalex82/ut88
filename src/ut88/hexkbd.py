import pygame
from common.interfaces import *

class HexKeyboard:
    """
        The UT-88 compulter at minimum configuration (CPU unit) interacts with
        the user using 17 digits keyboard. The keyboard is connected to the I/O
        line at address 0xa0. Keyboard codes are:
        - Key 0             - 0x10
        - Keys from 1 to F  - 0x01 to 0xf respectively
        - back button       - 0x80
    """
    def __init__(self):
        self._pressed_key = 0


    def update(self):
        self._pressed_key = 0x00

        keys = pygame.key.get_pressed()
        if keys[pygame.K_0]:                        # 0
            self._pressed_key = 0x10
        for k in range(pygame.K_1, pygame.K_1 + 9): # 1 to 9
            if keys[k]:
                self._pressed_key = k - pygame.K_1 + 1
        for k in range(pygame.K_a, pygame.K_a + 6): # A to F
            if keys[k]:
                self._pressed_key = k - pygame.K_a + 10
        if keys[pygame.K_BACKSPACE]:                # Step back
            self._pressed_key = 0x80


    def press_key(self, key):
        if key=="0":
            self._pressed_key = 0x10
        if key >= "1" and key <= "9":
            self._pressed_key = ord(key[0]) - ord('0')
        if key >= "a" and key <= "f":
            self._pressed_key = ord(key[0]) - ord('a') + 0x0a
        if key >= "A" and key <= "F":
            self._pressed_key = ord(key[0]) - ord('A') + 0x0a
        if key=="back":
            self._pressed_key = 0x80


    def release_key(self):
        self._pressed_key = 0


    def get_state(self):
        return self._pressed_key


    def read_byte(self, offset):
        return self._pressed_key


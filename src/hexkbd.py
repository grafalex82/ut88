from utils import *

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


    def read_io(self, addr):
        if addr != 0xa0:
            raise IOError(f"Incorrect IO address {addr}")

        return self._pressed_key


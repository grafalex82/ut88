# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from ut88.lcd import LCD
from common.interfaces import MemoryDevice
from common.utils import *

# Base address of the LCD display is 0x9000
LCD_PTR = 0x9000

@pytest.fixture
def lcd():
    return MemoryDevice(LCD(), LCD_PTR)

def test_write_byte(lcd):
    lcd.write_byte(LCD_PTR, 0x42)
    assert lcd._device._ram[0] == 0x42

def test_write_word(lcd):
    lcd.write_word(LCD_PTR + 1, 0xbeef)
    assert lcd._device._ram[1] == 0xef    
    assert lcd._device._ram[2] == 0xbe
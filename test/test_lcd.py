# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from lcd import LCD
from utils import *

@pytest.fixture
def lcd():
    return LCD() 

def test_write_byte(lcd):
    lcd.write_byte(0x9000, 0x42)
    assert lcd._ram[0] == 0x42

def test_write_word(lcd):
    lcd.write_word(0x9001, 0xbeef)
    assert lcd._ram[1] == 0xef    
    assert lcd._ram[2] == 0xbe
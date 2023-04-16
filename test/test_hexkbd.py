# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from hexkbd import HexKeyboard


@pytest.fixture
def kbd():
    return HexKeyboard()

def test_create(kbd):
    assert kbd.get_state() == 0x00

@pytest.mark.parametrize("key, value", [
    ("0", 0x10), ("1", 0x1), ("5", 0x5), ("9", 0x9), 
    ("a", 0x0a), ("c", 0xc), ("f", 0xf), 
    ("A", 0x0a), ("C", 0xc), ("F", 0xf), 
    ("back", 0x80)
])
def test_press_release(kbd, key, value):
    kbd.press_key(key)
    assert kbd.get_state() == value

    kbd.release_key()
    assert kbd.get_state() == 0x00

def test_io_read(kbd):
    assert kbd.read_io(0xa0) == 0x00

    kbd.press_key("0")
    assert kbd.read_io(0xa0) == 0x10

    kbd.release_key()
    assert kbd.read_io(0xa0) == 0x00

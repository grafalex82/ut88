# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from ram import RAM

@pytest.fixture
def ram():
    return RAM(0x0000, 0xffff) 

def test_read_default_byte(ram):
    assert ram.read_byte(0x1234) == 0x00

def test_write_read_byte(ram):
    ram.write_byte(0x1234, 0x42)
    assert ram.read_byte(0x1234) == 0x42

def test_write_read_word(ram):
    ram.write_word(0x1234, 0xbeef)
    assert ram.read_word(0x1234) == 0xbeef

def test_write_read_word2(ram):
    ram.write_word(0x1234, 0xbeef)
    assert ram.read_byte(0x1234) == 0xef
    assert ram.read_byte(0x1235) == 0xbe

def test_push(ram):
    ram.push(0x1234, 0xbeef)
    assert ram.read_byte(0x1232) == 0xef
    assert ram.read_byte(0x1233) == 0xbe

def test_pop(ram):
    ram.write_word(0x1234, 0xbeef)
    assert ram.pop(0x1234) == 0xbeef

def test_out_of_byte_range_value(ram):
    with pytest.raises(ValueError):
        ram.write_byte(0x1234, 0xbeef)

def test_out_of_word_range_value(ram):
    with pytest.raises(ValueError):
        ram.write_word(0x1234, 0xbeef42)

def test_out_of_word_range_value2(ram):
    with pytest.raises(ValueError):
        ram.push(0x1234, 0xbeef42)

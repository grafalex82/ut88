# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from rom import ROM
from utils import *

@pytest.fixture
def rom():
    return ROM("../resources/Monitor0.bin", 0x4000)

def test_addr(rom):
    start, end = rom.get_addr_space()
    assert start == 0x4000
    assert end == 0x43ff

def test_read_byte(rom):
    assert rom.read_byte(0x4042) == 0x26

def test_read_word(rom):
    assert rom.read_word(0x4242) == 0x09e5

def test_out_of_addr_range_byte(rom):
    with pytest.raises(MemoryError):
        rom.read_byte(0x1234)
    with pytest.raises(MemoryError):
        rom.read_byte(0x6789)

def test_out_of_addr_range_word(rom):
    with pytest.raises(MemoryError):
        rom.read_word(0x1234)
    with pytest.raises(MemoryError):
        rom.read_word(0x6789)

def test_out_of_addr_range_burst(rom):
    with pytest.raises(MemoryError):
        rom.read_burst(0x1234, 0x10)    # Start address is out of the range
    with pytest.raises(MemoryError):
        rom.read_burst(0x6789, 0x10)    # Start address is out of the range
    with pytest.raises(MemoryError):
        rom.read_burst(0x43f8, 0x10)    # Start address is ok, end address is not

def test_read_burst(rom):
    assert rom.read_burst(0x4242, 10) == [0xe5, 0x09, 0x22, 0xf6, 0xc3, 0x2a, 0xf0, 0xc3, 0x4d, 0x44]

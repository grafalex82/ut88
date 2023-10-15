# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from ram import RAM
from interfaces import MemoryDevice
from utils import *

@pytest.fixture
def ram():
    return MemoryDevice(RAM(), 0x0000, 0xffff)

def test_create_by_size():
    ram = RAM(0x1000)
    device = MemoryDevice(ram, 0x2000)
    start, end = device.get_addr_range()
    assert start == 0x2000
    assert end == 0x2fff

def test_addr(ram):
    start, end = ram.get_addr_range()
    assert start == 0x0000
    assert end == 0xffff

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

def test_read_burst(ram):
    ram.write_byte(0x1234, 0x42)
    ram.write_byte(0x1235, 0x43)
    ram.write_byte(0x1236, 0x44)
    ram.write_byte(0x1237, 0x45)
    assert ram.read_burst(0x1230, 12) == [0x00, 0x00, 0x00, 0x00, 0x42, 0x43, 0x44, 0x45, 0x00, 0x00, 0x00, 0x00]


def test_write_burst(ram):
    ram.write_byte(0x1238, 0xa5)    # Guard byte, to check if this not overwritten  
    ram.write_burst(0x1234, bytes([0x42, 0x43, 0x44, 0x45]))

    assert ram.read_byte(0x1233) == 0x00
    assert ram.read_byte(0x1234) == 0x42
    assert ram.read_byte(0x1235) == 0x43
    assert ram.read_byte(0x1236) == 0x44
    assert ram.read_byte(0x1237) == 0x45
    assert ram.read_byte(0x1238) == 0xa5


def test_push(ram):
    ram.write_stack(0x1234, 0xbeef)
    assert ram.read_byte(0x1234) == 0xef
    assert ram.read_byte(0x1235) == 0xbe

def test_pop(ram):
    ram.write_word(0x1234, 0xbeef)
    assert ram.read_stack(0x1234) == 0xbeef

def test_out_of_byte_range_value(ram):
    with pytest.raises(ValueError):
        ram.write_byte(0x1234, 0xbeef)

def test_out_of_word_range_value(ram):
    with pytest.raises(ValueError):
        ram.write_word(0x1234, 0xbeef42)

def test_out_of_word_range_value2(ram):
    with pytest.raises(ValueError):
        ram.write_stack(0x1234, 0xbeef42)

def test_out_of_addr_range_byte():
    ram = MemoryDevice(RAM(), 0x5000, 0x5fff)
    with pytest.raises(MemoryError):
        ram.write_byte(0x1234, 0x42)
    with pytest.raises(MemoryError):
        ram.write_byte(0x6789, 0x42)
    with pytest.raises(MemoryError):
        ram.read_byte(0x1234)
    with pytest.raises(MemoryError):
        ram.read_byte(0x6789)

def test_out_of_addr_range_word():
    ram = MemoryDevice(RAM(), 0x5000, 0x5fff)
    with pytest.raises(MemoryError):
        ram.write_word(0x1234, 0xbeef)
    with pytest.raises(MemoryError):
        ram.write_word(0x6789, 0xbeef)
    with pytest.raises(MemoryError):
        ram.read_word(0x1234)
    with pytest.raises(MemoryError):
        ram.read_word(0x6789)

def test_out_of_addr_range_stack():
    ram = MemoryDevice(RAM(), 0x5000, 0x5fff)
    with pytest.raises(MemoryError):
        ram.write_stack(0x1234, 0xbeef)
    with pytest.raises(MemoryError):
        ram.write_stack(0x6789, 0xbeef)
    with pytest.raises(MemoryError):
        ram.read_stack(0x1234)
    with pytest.raises(MemoryError):
        ram.read_stack(0x6789)

def test_out_of_addr_range_burst():
    ram = MemoryDevice(RAM(), 0x5000, 0x5fff)
    with pytest.raises(MemoryError):
        ram.read_burst(0x1234, 0x10)
    with pytest.raises(MemoryError):
        ram.read_burst(0x6789, 0x10)
    with pytest.raises(MemoryError):
        ram.read_burst(0x5ff8, 0x10)

    buf = [0]*0x10
    with pytest.raises(MemoryError):
        ram.write_burst(0x1234, buf)
    with pytest.raises(MemoryError):
        ram.write_burst(0x6789, buf)
    with pytest.raises(MemoryError):
        ram.write_burst(0x5ff8, buf)

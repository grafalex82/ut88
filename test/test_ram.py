# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from ram import RAM
from utils import *

@pytest.fixture
def ram():
    return RAM(0x0000, 0xffff) 

def test_addr(ram):
    assert ram.get_start_addr() == 0x0000
    assert ram.get_end_addr() == 0xffff

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
    ram = RAM(0x5000, 0x5fff) 
    with pytest.raises(MemoryError):
        ram.write_byte(0x1234, 0x42)
    with pytest.raises(MemoryError):
        ram.write_byte(0x6789, 0x42)
    with pytest.raises(MemoryError):
        ram.read_byte(0x1234)
    with pytest.raises(MemoryError):
        ram.read_byte(0x6789)

def test_out_of_addr_range_word():
    ram = RAM(0x5000, 0x5fff) 
    with pytest.raises(MemoryError):
        ram.write_word(0x1234, 0xbeef)
    with pytest.raises(MemoryError):
        ram.write_word(0x6789, 0xbeef)
    with pytest.raises(MemoryError):
        ram.read_word(0x1234)
    with pytest.raises(MemoryError):
        ram.read_word(0x6789)

def test_out_of_addr_range_stack():
    ram = RAM(0x5000, 0x5fff) 
    with pytest.raises(MemoryError):
        ram.write_stack(0x1234, 0xbeef)
    with pytest.raises(MemoryError):
        ram.write_stack(0x6789, 0xbeef)
    with pytest.raises(MemoryError):
        ram.read_stack(0x1234)
    with pytest.raises(MemoryError):
        ram.read_stack(0x6789)

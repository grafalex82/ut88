# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from machine import Machine
from utils import *
from ram import RAM
from rom import ROM
from mock import *

@pytest.fixture
def machine():
    m = Machine()
    m.add_memory(ROM("../resources/Monitor0.bin", 0x4000))
    m.add_memory(RAM(0x8000, 0x8fff))
    return m

def test_ram_read_write(machine):
    assert machine.read_memory_byte(0x8765) == 0x00
    machine.write_memory_byte(0x8765, 0x42)
    assert machine.read_memory_byte(0x8765) == 0x42

    assert machine.read_memory_word(0x8642) == 0x0000
    machine.write_memory_word(0x8642, 0xbeef)
    assert machine.read_memory_word(0x8642) == 0xbeef

    assert machine.read_stack(0x8ace) == 0x0000
    machine.write_stack(0x8ace, 0xbeef)
    assert machine.read_stack(0x8ace) == 0xbeef

def test_rom_read(machine):
    assert machine.read_memory_byte(0x4042) == 0x26
    assert machine.read_memory_word(0x4242) == 0x09e5

def test_memory_addr_validation(machine):
    machine.set_strict_validation(True)
    with pytest.raises(MemoryError) as e:
        machine.read_memory_byte(0x1234)
    assert "No memory registered for address 0x1234" in str(e.value)

def test_io_read_write(machine):
    machine.add_io(MockIO(0x42))

    assert machine.read_io(0x42) == 0x00

    machine.write_io(0x42, 0x12)
    assert machine.read_io(0x42) == 0x12

def test_io_addr_validation(machine):
    machine.set_strict_validation(True)
    machine.add_io(MockIO(0x42))
    with pytest.raises(IOError) as e:
        machine.read_io(0x24)
    assert "No IO registered for address 0x24" in str(e.value)

def test_read_no_memory(machine):
    assert machine.read_memory_byte(0x1234) == 0xff
    assert machine.read_memory_word(0x1234) == 0xffff

def test_write_no_memory(machine):
    # Just check it does not throw the error
    machine.set_strict_validation(False)
    machine.write_memory_byte(0x1234, 0x42)
    machine.write_memory_word(0x1234, 0x1234)

def test_read_no_io(machine):
    assert machine.read_io(0x42) == 0xff

def test_write_no_io(machine):
    # Just check it does not throw the error
    machine.set_strict_validation(False)
    machine.write_io(0x12, 0x42)

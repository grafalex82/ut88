# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from dma import DMA
from ram import RAM
from machine import Machine
from utils import *

@pytest.fixture
def dma():
    ram = RAM(0x0000, 0xffff)
    machine = Machine()
    machine.add_memory(ram)
    return DMA(machine)

def test_fill_channel_params(dma):
    dma.write_byte(0xe002, 0x34)    # Fill start address for Channel 1 (low byte first)
    dma.write_byte(0xe002, 0x12)
    dma.write_byte(0xe003, 0x78)    # Fill count for Channel 1 (low byte first)
    dma.write_byte(0xe003, 0x56)    

    assert dma.get_register_value(1, False) == 0x1234   # Start address register
    assert dma.get_register_value(1, True) == 0x1679    # Counter register (not including read/write bits)
                                                        # Number of bytes to transfer is 1 bigger than param


def test_fill_channel_params_multiple(dma):
    dma.write_byte(0xe002, 0x34)    # Fill start address for Channel 1 (low byte first)
    dma.write_byte(0xe002, 0x12)
    dma.write_byte(0xe003, 0x78)    # Fill count for Channel 1 (low byte first)
    dma.write_byte(0xe003, 0x56)    

    assert dma.get_register_value(1, False) == 0x1234   # Start address register
    assert dma.get_register_value(1, True) == 0x1679    # Counter register (not including read/write bits)
                                                        # Number of bytes to transfer is 1 bigger than param

    # Do filling params again
    dma.write_byte(0xe002, 0x45)    # Fill start address for the same Channel 1 (low byte first)
    dma.write_byte(0xe002, 0x23)
    dma.write_byte(0xe003, 0x89)    # Fill count for Channel 1 (low byte first)
    dma.write_byte(0xe003, 0x67)    

    assert dma.get_register_value(1, False) == 0x2345   # Start address register
    assert dma.get_register_value(1, True) == 0x278a    # Counter register (not including read/write bits)
                                                        # Number of bytes to transfer is 1 bigger than param


def test_fill_autoload_params(dma):
    dma.write_byte(0xe008, 0x80)    # Set Autoload flag in the configuration register
    dma.write_byte(0xe004, 0x34)    # Fill start address for Channel 1 (low byte first)
    dma.write_byte(0xe004, 0x12)
    dma.write_byte(0xe005, 0x78)    # Fill count for Channel 1 (low byte first)
    dma.write_byte(0xe005, 0x56)    

    assert dma.get_register_value(2, False) == 0x1234   # Start address register
    assert dma.get_register_value(2, True) == 0x1679    # Counter register (not including read/write bits)
                                                        # Number of bytes to transfer is 1 bigger than param
    assert dma.get_register_value(3, False) == 0x1234   # Validate data is also replicated for channel 3
    assert dma.get_register_value(3, True) == 0x1679


def test_dma_read(dma):
    # Fill some memory bytes
    dma._machine.write_memory_byte(0x1234, 0x42)
    dma._machine.write_memory_byte(0x1235, 0x43)
    dma._machine.write_memory_byte(0x1236, 0x44)
    dma._machine.write_memory_byte(0x1237, 0x45)

    # Configure the DMA channel 0 for reading 4 memory bytes starting 0x1234
    dma.write_byte(0xe000, 0x34)    # Set channel 0 start address (low byte first)
    dma.write_byte(0xe000, 0x12)
    dma.write_byte(0xe001, 0x03)    # Set channel 0 count and read mode
    dma.write_byte(0xe001, 0x40)
    dma.write_byte(0xe008, 0x01)    # Enable channel 0

    # Perform the transfer using channel 0
    data = dma.dma_read(0)

    # Check the result
    assert data == [0x42, 0x43, 0x44, 0x45]


def test_dma_write(dma):
    # Configure the DMA channel 1 for writing 4 memory bytes starting 0x1234
    dma.write_byte(0xe002, 0x34)    # Set channel 1 start address (low byte first)
    dma.write_byte(0xe002, 0x12)
    dma.write_byte(0xe003, 0x03)    # Set channel 1 count and write mode
    dma.write_byte(0xe003, 0x80)
    dma.write_byte(0xe008, 0x02)    # Enable channel 1

    # Perform the transfer using channel 1
    data = dma.dma_write(1, [0x42, 0x43, 0x44, 0x45])

    # Check the result
    assert dma._machine.read_memory_byte(0x1234) == 0x42
    assert dma._machine.read_memory_byte(0x1235) == 0x43
    assert dma._machine.read_memory_byte(0x1236) == 0x44
    assert dma._machine.read_memory_byte(0x1237) == 0x45


def test_dma_autoload(dma):
    # Fill some memory bytes
    dma._machine.write_memory_byte(0x1234, 0x42)
    dma._machine.write_memory_byte(0x1235, 0x43)
    dma._machine.write_memory_byte(0x1236, 0x44)
    dma._machine.write_memory_byte(0x1237, 0x45)

    # Configure the DMA channel 2 for reading 4 memory bytes starting 0x1234 with autoload
    dma.write_byte(0xe008, 0x80)    # Raise the autoload bit
    dma.write_byte(0xe004, 0x34)    # Set channel 2 start address (low byte first)
    dma.write_byte(0xe004, 0x12)
    dma.write_byte(0xe005, 0x03)    # Set channel 2 count and read mode
    dma.write_byte(0xe005, 0x40)
    dma.write_byte(0xe008, 0x84)    # Enable channel 2, autoload

    # Perform the transfer using channel 2, and check the result
    data = dma.dma_read(2)
    assert data == [0x42, 0x43, 0x44, 0x45]

    # Fill the same memory with another bytes
    dma._machine.write_memory_byte(0x1234, 0x24)
    dma._machine.write_memory_byte(0x1235, 0x25)
    dma._machine.write_memory_byte(0x1236, 0x26)
    dma._machine.write_memory_byte(0x1237, 0x27)

    # Perform the transfer again, expecting the channel parameters are autoloaded, and check the result
    data = dma.dma_read(2)
    assert data == [0x24, 0x25, 0x26, 0x27]


def test_dma_not_autoloaded(dma):
    # Fill some memory bytes
    dma._machine.write_memory_byte(0x1234, 0x42)
    dma._machine.write_memory_byte(0x1235, 0x43)
    dma._machine.write_memory_byte(0x1236, 0x44)
    dma._machine.write_memory_byte(0x1237, 0x45)

    # Configure the DMA channel 3 for reading 4 memory bytes starting 0x1234 with autoload
    dma.write_byte(0xe008, 0x00)    # Clear the autoload bit
    dma.write_byte(0xe006, 0x34)    # Set channel 3 start address (low byte first)
    dma.write_byte(0xe006, 0x12)
    dma.write_byte(0xe007, 0x03)    # Set channel 3 count and read mode
    dma.write_byte(0xe007, 0x40)
    dma.write_byte(0xe008, 0x08)    # Enable channel 3

    # Perform the transfer using channel 3, and check the result
    data = dma.dma_read(3)
    assert data == [0x42, 0x43, 0x44, 0x45]

    # Try running another DMA read and verify that the channel is no longer enabled
    with pytest.raises(RuntimeError):
        dma.dma_read(3)


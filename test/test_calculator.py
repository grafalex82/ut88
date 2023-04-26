# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for Calculator firmware, rather than UT-88 schematics.
# These tests run emulation of some functions from the calculator firmware, feed it some 
# values, and check results. This is easier than manually enter arguments to required
# memory cells, run some calculator functions, and then check memory for a result

import pytest
import sys
import logging

sys.path.append('../misc')
sys.path.append('../src')

from float import *

from machine import Machine
from emulator import Emulator
from cpu import CPU
from rom import ROM
from ram import RAM
from utils import *
from mock import *

# Calculator is a UT-88 in Basic CPU unit configuration + calculator firmware
#
# This is a helper class that sets up the machine, configures it for running a
# calculator function, feeds function arguments, and retrieves the result
class Calculator:
    def __init__(self):
        self._machine = Machine()
        self._machine.add_memory(RAM(0xc000, 0xc3ff))     # Same as CPU module configuration
        self._machine.add_memory(ROM(f"../resources/Monitor0.bin", 0x0000))
        self._machine.add_memory(ROM(f"../resources/calculator.bin", 0x0800))

        self._emulator = Emulator(self._machine)

    def _convert_byte(self, value): # Convert the value from Sign-Magnitude to Two's Complement or back
        if value >= 0x80 or value < 0:
            value = (~value + 1) & 0xff
            return value | 0x80
        return value

    def set_byte_argument(self, addr, value):
        if value >= 0x80 or value < 0:
            value = (~value + 1) & 0xff
            value |= 0x80

        print(f"Setting value {value:02x} to {addr:04x}")

        self._machine.write_memory_byte(addr, value)

    def get_byte_result(self, addr):
        value = self._machine.read_memory_byte(addr)
        print(f"Getting value {value:02x} from {addr:04x}")

        if value >= 0x80:
            value = value & 0x7f
            value *= -1

        print(f"Returning value {value}")
        return value
    
    def run_function(self, addr):
        # Put the breakpoint to the top of the stack
        # When a calculator function will return, it will trigger a breakpoint
        self._emulator._cpu._sp = 0xfffe
        self._emulator._machine.write_memory_word(0xfffe, 0xbeef) # breakpoint return address

        # Will execute function starting from the given address
        self._emulator._cpu._pc = addr

        # Run the requested function, until it returns to 0xbeef
        # Set the counter limit to avoid infinite loop
        while self._emulator._cpu._pc != 0xbeef and self._emulator._cpu._cycles < 10000:
            self._emulator.step()


@pytest.fixture
def calculator():
    return Calculator()

@pytest.mark.parametrize("arg1, arg2, res", [
    (1, 2, 3),
    (42, 56, 98),
    (1, -1, 0),
    (10, -15, -5),
    (-10, 5, -5),
    (-10, -10, -20)
])
def test_add_byte(calculator, arg1, arg2, res):
    logging.basicConfig(level=logging.DEBUG)

    calculator.set_byte_argument(0xc371, arg1)
    calculator.set_byte_argument(0xc374, arg2)
    
    calculator.run_function(0x0849)

    assert calculator.get_byte_result(0xc374) == res
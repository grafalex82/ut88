# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CP/M operating system, rather than UT-88 schematics.
# These tests are not tests in general meaning, they are not supposed to _test_ anything.
# This is rather a handy way to run emulation of some functions from the CP/M software bundle,
# in order to understand better how do they work.
#
# Tests run an emulator, load CP/M components, and run required functions with certain arguments.

import pytest
import os
import logging

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")
tapes_dir = os.path.join(os.path.dirname(__file__), "../tapes")

from float import *

from machine import UT88Machine
from emulator import Emulator
from cpu import CPU
from rom import ROM
from ram import RAM
from quasidisk import QuasiDisk
from utils import *

# CP/M is a UT-88 machine with monitorF ROM, and a 64k RAM + CP/M binary modules loaded.
#
# This is a helper class that sets up the machine emulator, configures it for running a
# CP/M functions, feeds function arguments, and retrieves the result
class CPM:
    def __init__(self):
        self._machine = UT88Machine()
        self._machine.add_memory(RAM(0x0000, 0xf7ff))
        self._machine.add_memory(ROM(f"{resources_dir}/MonitorF.bin", 0xf800))

        self._emulator = Emulator(self._machine)
        self._emulator.load_memory(f"{tapes_dir}/cpm64_monitorf_addon.rku")

        self._emulator._cpu.enable_registers_logging(True)

        # Since we do not run MonitorF initialization routine, let's just initialize needed variables,
        # and particularly set cursor to the top-left corner
        self.set_word(0xf7b2, 0xe800)


    def set_byte(self, addr, value):
        self._machine.write_memory_byte(addr, value)


    def set_word(self, addr, value):
        self._machine.write_memory_word(addr, value)


    def get_byte(self, addr):
        value = self._machine.read_memory_byte(addr)
        return value


    def get_word(self, addr):
        value = self._machine.read_memory_word(addr)
        return value


    def run_function(self, addr):
        # Put the breakpoint to the top of the stack
        # When a called function returns, it will get to the 0xbeef address
        self._emulator._cpu.sp = 0xf6ee
        self._emulator._machine.write_memory_word(0xf6ee, 0xbeef) # breakpoint return address

        # Will execute function starting from the given address
        self._emulator._cpu.pc = addr

        # Run the requested function, until it returns to 0xbeef
        # Set the counter limit to avoid infinite loop
        while self._emulator._cpu.pc != 0xbeef and self._emulator._cpu._cycles < 100000:
            self._emulator.step()

        # Validate that the code really reached the end, and not stopped by a cycles limit
        assert self._emulator._cpu.pc == 0xbeef


@pytest.fixture
def cpm():
    return CPM()


def put_char(cpm, c):
    cpm._emulator._cpu._c = c
    cpm.run_function(0xf500)    

def print_string(cpm, string):
    for c in string:
        put_char(cpm, ord(c))


def test_print_string(cpm):
    print_string(cpm, "TEST")
    assert cpm.get_byte(0xe800) == ord('T')
    assert cpm.get_byte(0xe801) == ord('E')
    assert cpm.get_byte(0xe802) == ord('S')
    assert cpm.get_byte(0xe803) == ord('T')
    
def test_put_char_new_line(cpm):
    put_char(cpm, 0x0a)
    assert cpm.get_word(0xf7b2) == 0xe840

def test_put_char_cursor_movements(cpm):
    # Start at the top-left position
    assert cpm.get_word(0xf7b2) == 0xe800

    print_string(cpm, "\x1bB")  # Esc-B - move cursor down
    assert cpm.get_word(0xf7b2) == 0xe840

    print_string(cpm, "\x1bC")  # Esc-C - move cursor right
    assert cpm.get_word(0xf7b2) == 0xe841

    print_string(cpm, "\x1bA")  # Esc-A - move cursor up
    assert cpm.get_word(0xf7b2) == 0xe801

    print_string(cpm, "\x1bD")  # Esc-D - move cursor left
    assert cpm.get_word(0xf7b2) == 0xe800

def test_put_char_home_screen(cpm):
    # Print something on the screen
    print_string(cpm, "TEST")

    # Then print home cursor sequence
    print_string(cpm, "\x1bH")

    # Check the cursor is at the top-left position
    assert cpm.get_word(0xf7b2) == 0xe800


def test_put_char_clear_screen(cpm):
    # Print something on the screen
    print_string(cpm, "TEST")

    # Then clear screen
    print_string(cpm, "\x1bE")

    # Check the screen is empty, and cursor is at the top-left position
    assert cpm.get_word(0xf7b2) == 0xe800
    assert cpm.get_byte(0xe800) == 0x20
    assert cpm.get_byte(0xe801) == 0xa0 # Byte after the cursor is highlighted
    assert cpm.get_byte(0xe802) == 0x20
    assert cpm.get_byte(0xe803) == 0x20


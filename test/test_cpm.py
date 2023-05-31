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
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bdos.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bios.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_monitorf_addon.rku")

        self._emulator._cpu.enable_registers_logging(True)

        # Since we do not run MonitorF initialization routine, let's just initialize needed variables,
        # and particularly set cursor to the top-left corner
        self.set_word(0xf7b2, 0xe800)

    @property
    def cpu(self):
        return self._emulator._cpu

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
    cpm.cpu._c = c
    cpm.run_function(0xf500)    


def print_string(cpm, string):
    for c in string:
        put_char(cpm, ord(c))


def select_disk(cpm, disk):
    cpm.cpu._c = disk
    cpm.run_function(0xda1b)


def select_track(cpm, track):
    cpm.cpu._c = track
    cpm.run_function(0xdb2a)


def select_sector(cpm, sector):
    cpm.cpu._c = sector
    cpm.run_function(0xda21)


def set_disk_buffer(cpm, addr):
    cpm.cpu.bc = addr
    cpm.run_function(0xda24)


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


def test_put_char_move_cursor_to(cpm):
    # Move cursor to row 1 (0x21-0x20) and column 3 (0x23-0x20)
    print_string(cpm, "\x1bY!#")

    assert cpm.get_word(0xf7b2) == 0xe843


def test_put_char_clear_screen_after_cursor(cpm):
    # Fill screen with 'B' symbol (0x42)
    for i in range(28*64):
        cpm.set_byte(0xe800 + i, 0x42)
    
    # Move cursor to row 10 (0x2A-0x20 = 10) and column 32 (0x40-0x20 = 32)
    print_string(cpm, "\x1bY*@")

    # Print Esc-J sequence, to clear screen starting the cursor position
    print_string(cpm, "\x1bJ")

    # Check that it is cleared
    assert cpm.get_byte(0xe800 + 0x40*0 + 0) == 0x42     # Still 'B' at the beginning of the screen
    assert cpm.get_byte(0xe800 + 0x40*10 + 31) == 0x42  # Still 'B' before cursor
    assert cpm.get_byte(0xe800 + 0x40*10 + 32) == 0x20  # ' ' at cursor position
    assert cpm.get_byte(0xe800 + 0x40*10 + 33) == 0x20  # ' ' after the cursor
    assert cpm.get_byte(0xe800 + 0x40*10 + 63) == 0x20  # ' ' at the end of the line
    assert cpm.get_byte(0xe800 + 0x40*11 + 63) == 0x20  # ' ' on the next line as well
    assert cpm.get_byte(0xe800 + 0x40*27 + 63) == 0x20  # ' ' at the end of the screen

    assert cpm.get_word(0xf7b2) == 0xe800 + 0x40*10 + 32 # check that cursor not moved


def test_put_char_clear_line_after_cursor(cpm):
    # Fill screen with 'B' symbol (0x42)
    for i in range(28*64):
        cpm.set_byte(0xe800 + i, 0x42)
    
    # Move cursor to row 10 (0x2A-0x20 = 10) and column 32 (0x40-0x20 = 32)
    print_string(cpm, "\x1bY*@")

    # Print Esc-K sequence, to clear line starting the cursor position up to the end of line
    print_string(cpm, "\x1bK")

    # Check that it is cleared
    assert cpm.get_byte(0xe800 + 0x40*0 + 0) == 0x42    # Still 'B' at the beginning of the screen
    assert cpm.get_byte(0xe800 + 0x40*10 + 31) == 0x42  # Still 'B' before cursor
    assert cpm.get_byte(0xe800 + 0x40*10 + 32) == 0x20  # ' ' at cursor position
    assert cpm.get_byte(0xe800 + 0x40*10 + 33) == 0x20  # ' ' after the cursor
    assert cpm.get_byte(0xe800 + 0x40*10 + 63) == 0x20  # ' ' at the end of the line
    assert cpm.get_byte(0xe800 + 0x40*11 + 0) == 0x42   # Still 'B' on the next line
    assert cpm.get_byte(0xe800 + 0x40*11 + 32) == 0x42  # Still 'B' on the next line
    assert cpm.get_byte(0xe800 + 0x40*11 + 63) == 0x42  # Still 'B' on the next line
    assert cpm.get_byte(0xe800 + 0x40*27 + 63) == 0x42  # Still 'B' at the end of the screen

    assert cpm.get_word(0xf7b2) == 0xe800 + 0x40*10 + 32 # check that cursor not moved


def test_bios_select_disk(cpm):
    select_disk(cpm, 0)
    assert cpm.cpu.hl == 0xda33


def test_bios_select_incorrect_disk(cpm):
    select_disk(cpm, 1)
    assert cpm.cpu.hl == 0x0000


def test_bios_select_track(cpm):
    select_track(cpm, 0x05)
    assert cpm.get_byte(0xdbec) == 0xfe  # Page 0
    assert cpm.get_byte(0xdbed) == 0x05  # Track 5

    select_track(cpm, 0x98)
    assert cpm.get_byte(0xdbec) == 0xfb  # Page 2
    assert cpm.get_byte(0xdbed) == 0x18  # Track 0x18

    select_track(cpm, 0xff)
    assert cpm.get_byte(0xdbec) == 0xf7  # Page 3
    assert cpm.get_byte(0xdbed) == 0x3f  # Track 0x3f


def test_bios_select_track_zero(cpm):
    cpm.run_function(0xdb0c)

    assert cpm.get_byte(0xdbec) == 0xfe  # Page 0
    assert cpm.get_byte(0xdbed) == 0x00  # Track 0


def test_bios_select_sector(cpm):
    select_sector(cpm, 0x42)

    assert cpm.get_byte(0xdbee) == 0x42


def test_bios_set_buffer(cpm):
    set_disk_buffer(cpm, 0xbeef)

    assert cpm.get_word(0xdbef) == 0xbeef


def test_bios_read_sector(cpm, tmp_path):
    data = bytearray(256*1024)
    offset = 70*1024 + 3*128 # track 70 (track 6 on page 1), sector 3
    sector_data = [1, 2, 3, 4, 5, 6, 7, 8] * 16
    data[offset:offset+128] = sector_data

    # Store the data to disk
    f = tmp_path / "test.bin"
    f.write_bytes(data)

    # Attach the quasi disk with prepared data to the machine
    disk = QuasiDisk(f)
    cpm._emulator._machine.set_quasi_disk(disk)

    # Select disk/track/sector
    select_disk(cpm, 0)
    select_track(cpm, 70)
    select_sector(cpm, 3 + 1) # Sectors numbering is 1-based
    set_disk_buffer(cpm, 0x4200)

    # Read the selected sector into the buffer
    cpm.run_function(0xda27)

    # Check the read sector
    for i in range(len(sector_data)):
        assert cpm.get_byte(0x4200 + i) == sector_data[i]


def test_bios_write_sector(cpm, tmp_path):
    # Prepare data buffer
    sector_data = [1, 2, 3, 4, 5, 6, 7, 8] * 16
    for i in range(len(sector_data)):
        cpm.set_byte(0x4200 + i, sector_data[i])

    # Create and install an empty quasi disk
    f = tmp_path / "test.bin"
    f.write_bytes(bytearray(256*1024))
    disk = QuasiDisk(f)
    cpm._emulator._machine.set_quasi_disk(disk)

    # Select disk/track/sector
    select_disk(cpm, 0)
    select_track(cpm, 70)
    select_sector(cpm, 3 + 1) # Sectors numbering is 1-based
    set_disk_buffer(cpm, 0x4200)

    # Write the buffer data to the selected sector
    cpm.run_function(0xda2a)

    # Flush the data to the host
    disk.update()

    # Check written data
    data = f.read_bytes()
    offset = 70*1024 + 3*128 # track 70 (track 6 on page 1), sector 3
    for i in range(128):
        assert data[offset + i] == sector_data[i]

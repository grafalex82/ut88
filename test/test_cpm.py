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
import pygame

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")
tapes_dir = os.path.join(os.path.dirname(__file__), "../tapes")

from float import *

from machine import UT88Machine
from emulator import Emulator
from cpu import CPU
from rom import ROM
from ram import RAM
from keyboard import Keyboard
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

        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)

        self._emulator = Emulator(self._machine)
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bdos.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bios.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_monitorf_addon.rku")

        self._emulator._cpu.enable_registers_logging(True)

        # Since we do not run MonitorF initialization routine, let's just initialize needed variables,
        # and particularly set cursor to the top-left corner
        self.set_word(0xf7b2, 0xe800)

        # Each key press require 127 cycles of the keyboard scanning, until the key is considered pressed.
        # Skip this, 1 scan is enough. Key repeat function is also disabled, as not needed for tests
        self._emulator.add_breakpoint(0xfd75, lambda: self._emulator._cpu.set_pc(0xfd95))


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


def call_bdos_function(cpm, func, arg = 0):
    cpm.cpu._c = func
    cpm.cpu.de = arg
    cpm.run_function(0xcc06)
    return (cpm.cpu._b << 8) | cpm.cpu._a


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


def test_bdos_console_input(cpm):
    cpm._keyboard.emulate_key_press('A')
    ch = call_bdos_function(cpm, 0x01)

    assert ch == ord('A')                   # 'A' is returned as a result value
    assert cpm.get_byte(0xe800) == 0x41     # 'A' is printed on the screen
    assert cpm.get_word(0xf7b2) == 0xe801   # Cursor moved to the next position


def test_bdos_console_input_special_symbol(cpm):
    cpm._keyboard.emulate_ctrl_key_press('\x03')    # Press Ctrl-C
    ch = call_bdos_function(cpm, 0x01)

    assert ch == 0x03                       # Ctrl-C is returned as a result value
    assert cpm.get_byte(0xe800) == 0x00     # No symbol is printed
    assert cpm.get_word(0xf7b2) == 0xe800   # Cursor not moved


def test_bdos_console_output_regular_char(cpm):
    call_bdos_function(cpm, 0x02, ord('A'))

    assert cpm.get_byte(0xe800) == 0x41     # 'A' is printed on the screen
    assert cpm.get_word(0xf7b2) == 0xe801   # Cursor moved to the next position


def test_bdos_console_output_tab(cpm):
    call_bdos_function(cpm, 0x02, 0x09)

    assert cpm.get_byte(0xe800) == 0x20     # 8 spaces are printed on the screen
    assert cpm.get_byte(0xe807) == 0x20     # 8 spaces are printed on the screen
    assert cpm.get_word(0xf7b2) == 0xe808   # Cursor moved to the next position


def test_bdos_console_output_lf(cpm):
    call_bdos_function(cpm, 0x02, ord('A')) # Just print something
    call_bdos_function(cpm, 0x02, 0x0a)     # Print LF

    assert cpm.get_byte(0xe800) == 0x41     # 'A' is printed
    assert cpm.get_word(0xf7b2) == 0xe840   # Cursor moved to the beginning of the next line


def test_bdos_console_output_cr(cpm):
    call_bdos_function(cpm, 0x02, ord('A')) # Just print something
    call_bdos_function(cpm, 0x02, 0x0d)     # Print CR

    assert cpm.get_byte(0xe800) == 0x41     # 'A' is printed
    # CR printing is not supported by the Monitor. It is printed like a normal character, and thererfore
    # cursor advances right
    assert cpm.get_word(0xf7b2) == 0xe802   


def test_bdos_console_direct_output(cpm):
    call_bdos_function(cpm, 0x06, ord('A')) # Just print something

    assert cpm.get_byte(0xe800) == 0x41     # 'A' is printed
    assert cpm.get_word(0xf7b2) == 0xe801   # Cursor is advanced


def test_bdos_console_direct_input(cpm):
    cpm._keyboard.emulate_key_press('A')
    ch = call_bdos_function(cpm, 0x06, 0xff)# Set the input mode

    assert ch == 0x41                       # Input character is A
    assert cpm.get_byte(0xe800) == 0x00     # No echo
    assert cpm.get_word(0xf7b2) == 0xe800   # Cursor has not moved


def test_bdos_print_string(cpm):
    cpm.set_byte(0x1234, ord('T'))
    cpm.set_byte(0x1235, ord('E'))
    cpm.set_byte(0x1236, ord('S'))
    cpm.set_byte(0x1237, ord('T'))
    cpm.set_byte(0x1238, ord('$'))
    call_bdos_function(cpm, 0x09, 0x1234)   # Print the string

    assert cpm.get_byte(0xe800) == ord('T')
    assert cpm.get_byte(0xe801) == ord('E')
    assert cpm.get_byte(0xe802) == ord('S')
    assert cpm.get_byte(0xe803) == ord('T')
    assert cpm.get_byte(0xe804) == 0x00     # Stopped here
    assert cpm.get_word(0xf7b2) == 0xe804   # Cursor is advanced and stopped after 4 symbols printed


def emulate_key_sequence(cpm, sequence):
    def generator(cpm, sequence):
        # Emulate next key in the sqeuence
        for ch in sequence:
            if ord(ch) < 0x20:
                print(f"Emulating Ctrl-{chr(ord(ch)+0x40)}")
                cpm._keyboard.emulate_ctrl_key_press(ch)
            else:
                print(f"Emulating {ch}")
                cpm._keyboard.emulate_key_press(ch)
            yield

        # Further calls of this generator will produce keyboard release
        while True:
            print(f"Emulating no press")
            cpm._keyboard.emulate_key_press(None)
            yield

    g = generator(cpm, sequence)
    cpm._emulator.add_breakpoint(0xcde1, lambda: g.__next__())
    cpm._emulator.add_breakpoint(0xcdf4, lambda: g.__next__())


def test_bdos_read_console_buffer(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    emulate_key_sequence(cpm, "TEST\n")

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')


def test_bdos_read_console_buffer_buffer_too_small(cpm):
    cpm.set_byte(0x1000, 0x04)              # Reserve just 4 bytes for the buffer

    emulate_key_sequence(cpm, "TESTTEST\n")

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x04     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')
    assert cpm.get_byte(0x1006) == 0x00     # No buffer overrun


def test_bdos_read_console_ctrl_symbol(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    emulate_key_sequence(cpm, "\x04\n")

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x01     # Number of entered characters
    assert cpm.get_byte(0x1002) == 0x04     # Entered symbol
    assert cpm.get_byte(0xe800) == ord('^') # Printed ^D
    assert cpm.get_byte(0xe801) == ord('D')


def test_bdos_read_console_backspace(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    emulate_key_sequence(cpm, "TEST\x08Q\n")    # Add backspace symbol

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('Q') # Replaced symbol
    assert cpm.get_byte(0xe800) == ord('T') # Printed "TESQ"
    assert cpm.get_byte(0xe801) == ord('E')
    assert cpm.get_byte(0xe802) == ord('S')
    assert cpm.get_byte(0xe803) == ord('Q')


def test_bdos_read_console_backspace_2(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    # Backspace symbol in the beginning. Should not make any harm
    emulate_key_sequence(cpm, "\x08TEST\n")    

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # All 4 symbols are entered
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')


def test_bdos_read_console_backspace_3(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    emulate_key_sequence(cpm, "TE\x04\x08ST\n")    # Backspace a 2-char control symbol

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')
    assert cpm.get_byte(0xe800) == ord('T') # Printed "TEST"
    assert cpm.get_byte(0xe801) == ord('E')
    assert cpm.get_byte(0xe802) == ord('S')
    assert cpm.get_byte(0xe803) == ord('T')


def test_bdos_read_console_backspace_4(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    # Ctrl-X (0x18) - backspace till start of the line
    # The function does extra keyboard read after Ctrl-X, so just emulate an extra symbol after Ctrl-x, which
    # will be ignored. This is an emulation issue, rather than CP/M code buf
    emulate_key_sequence(cpm, "TEST\x18 ABCD\n")    

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('A') # Entered characters
    assert cpm.get_byte(0x1003) == ord('B')
    assert cpm.get_byte(0x1004) == ord('C')
    assert cpm.get_byte(0x1005) == ord('D')
    assert cpm.get_byte(0xe800) == ord('A') # Printed "TEST"
    assert cpm.get_byte(0xe801) == ord('B')
    assert cpm.get_byte(0xe802) == ord('C')
    assert cpm.get_byte(0xe803) == ord('D')


def test_bdos_read_console_end_of_line(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    emulate_key_sequence(cpm, "TE\x05ST\n")    # End of line in the middle of the string

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    #assert cpm.get_byte(0x1004) == 0x05    # Ctrl-E is NOT in the buffer
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')

    assert cpm.get_byte(0xe800) == ord('T') # Printed "TE"
    assert cpm.get_byte(0xe801) == ord('E')
    assert cpm.get_byte(0xe840) == ord('S') # and "ST" on the next line
    assert cpm.get_byte(0xe841) == ord('T')


def test_bdos_read_console_abandon_current_line(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    # Ctrl-X (0x18) - backspace till start of the line
    # The function does extra keyboard read after Ctrl-U and 'A', so just emulate an extra symbol after 'A', 
    # which will be ignored. This is an emulation issue, rather than CP/M code buf
    emulate_key_sequence(cpm, "TEST\x15A BCD\n")

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('A') # Entered characters
    assert cpm.get_byte(0x1003) == ord('B')
    assert cpm.get_byte(0x1004) == ord('C')
    assert cpm.get_byte(0x1005) == ord('D')
    assert cpm.get_byte(0xe800) == ord('T') # Printed "TEST"
    assert cpm.get_byte(0xe801) == ord('E')
    assert cpm.get_byte(0xe802) == ord('S') 
    assert cpm.get_byte(0xe803) == ord('T')
    assert cpm.get_byte(0xe804) == ord('#') # Then a hash symbol
    assert cpm.get_byte(0xe840) == ord('A') # The restart reading from the next line
    assert cpm.get_byte(0xe841) == ord('B')
    assert cpm.get_byte(0xe842) == ord('C') 
    assert cpm.get_byte(0xe843) == ord('D')


def test_bdos_read_console_retype_current_line(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    # Ctrl-R (0x12) - retype currently entered characters from the new line
    emulate_key_sequence(cpm, "TE\x12ST\n")

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')

    assert cpm.get_byte(0xe800) == ord('T') # Printed "TE"
    assert cpm.get_byte(0xe801) == ord('E')
    assert cpm.get_byte(0xe802) == ord('#') # then hash

    assert cpm.get_byte(0xe840) == ord('T') # "TE" is redrawn from the new line
    assert cpm.get_byte(0xe841) == ord('E')
    assert cpm.get_byte(0xe842) == ord('S') # "ST" - finish typing test string
    assert cpm.get_byte(0xe843) == ord('T')


def test_bdos_check_key_pressed(cpm):
    cpm._keyboard.emulate_key_press('A')
    pressed = call_bdos_function(cpm, 0x0b)
    assert pressed


def test_bdos_check_key_not_pressed(cpm):
    pressed = call_bdos_function(cpm, 0x0b)
    assert not pressed


def test_bdos_get_version(cpm):
    ver = call_bdos_function(cpm, 0x0c)
    assert ver == 0x22
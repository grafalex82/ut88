# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CP/M operating system (Put Char Addon), rather than UT-88 schematics.
# These tests are not tests in general meaning, they are not supposed to _test_ anything.
# This is rather a handy way to run emulation of some functions from the CP/M software bundle,
# in order to understand better how do they work.
#
# Tests run an emulator, load CP/M components, and run required functions with certain arguments.

import pytest

from cpm_helper import CPM

@pytest.fixture
def cpm():
    return CPM()


def put_char(cpm, c):
    cpm.cpu._c = c
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


def test_new_line(cpm):
    put_char(cpm, 0x0a)
    assert cpm.get_word(0xf7b2) == 0xe840


def test_cursor_movements(cpm):
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


def test_home_screen(cpm):
    # Print something on the screen
    print_string(cpm, "TEST")

    # Then print home cursor sequence
    print_string(cpm, "\x1bH")

    # Check the cursor is at the top-left position
    assert cpm.get_word(0xf7b2) == 0xe800


def test_clear_screen(cpm):
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


def test_move_cursor_to(cpm):
    # Move cursor to row 1 (0x21-0x20) and column 3 (0x23-0x20)
    print_string(cpm, "\x1bY!#")

    assert cpm.get_word(0xf7b2) == 0xe843


def test_clear_screen_after_cursor(cpm):
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


def test_clear_line_after_cursor(cpm):
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

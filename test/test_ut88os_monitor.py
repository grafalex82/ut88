# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for UT-88 OS Monitor (do not mix up with MonitorF, which is a part of a standard
# video configuration). These tests are not tests in general meaning, they are not supposed to _test_
# anything. This is rather a handy way to run emulation of some functions from the UT-88 OS software bundle,
# in order to understand better how do they work.
#
# Tests run an emulator, load UT-88 OS components, and run required functions with certain arguments.

import pytest
import pygame

from ut88os_helper import UT88OS

CURSOR_POS_ADDR = 0xf75a
VIDEO_MEM_ADDR = 0xe800


def pos(x, y):
    return VIDEO_MEM_ADDR + y * 0x40 + x


@pytest.fixture
def ut88():
    return UT88OS()


def put_char(ut88, c):
    ut88.cpu.c = ord(c) if isinstance(c, str) else c
    ut88.run_function(0xf809)


def wait_kbd(ut88):
    ut88.run_function(0xf803)
    return ut88.cpu.a


def test_print_normal_char(ut88):    
    put_char(ut88, 'A')

    assert ut88.get_byte(VIDEO_MEM_ADDR) == ord('A')        # Check symbol appeared
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(1, 0)      # And cursor moved to the next char

    put_char(ut88, 'B')

    assert ut88.get_byte(VIDEO_MEM_ADDR + 1) == ord('B')    # Check another symbol appeared
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(2, 0)      # And cursor moved to the next char again


def test_print_clear_screen(ut88):    
    # Fill video RAM with garbage
    for addr in range(VIDEO_MEM_ADDR, VIDEO_MEM_ADDR + 0x700):
        ut88.set_byte(addr, ord('A'))

    # Print clear screen char
    put_char(ut88, 0x1f)

    # Validate a few chars on the screen to ensure they are filled with spaces
    assert ut88.get_byte(VIDEO_MEM_ADDR) == 0x00            # Check position is clear
    assert ut88.get_byte(VIDEO_MEM_ADDR + 1) == 0x00        # Check position is clear
    assert ut88.get_byte(VIDEO_MEM_ADDR + 0x42) == 0x00     # Check position is clear
    assert ut88.get_byte(VIDEO_MEM_ADDR + 0x6ff) == 0x00    # Check position is clear
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 0)      # And cursor moved to the top-left


def test_print_home_cursor(ut88):    
    # Print some symbols
    put_char(ut88, 'A')
    put_char(ut88, 0x0a)
    put_char(ut88, 'B')
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(1, 1)      # Cursor is not at the top-left position

    # Print home symbol
    put_char(ut88, 0x0c)

    # Validate the cursor is moved to the home position
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 0)      # And cursor moved to the top-left


def test_print_move_right_1(ut88):    
    # Print some symbols
    put_char(ut88, 'A')
    put_char(ut88, 'B')
    put_char(ut88, 'C')

    # Move cursor at B position, in the middle of the line
    ut88.set_word(CURSOR_POS_ADDR, pos(1, 0))

    # Print cursor move right
    put_char(ut88, 0x18)

    # Validate the cursor is moved to the next position, but symbols are intact
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(2, 0)      # Cursor moved right
    assert ut88.get_byte(VIDEO_MEM_ADDR + 1) == ord('B')    # Symbol intact
    assert ut88.get_byte(VIDEO_MEM_ADDR + 2) == ord('C')    # Symbol intact


def test_print_move_right_2(ut88):
    # Move cursor at the end of a line in the middle of the screen
    ut88.set_word(CURSOR_POS_ADDR, pos(0x3f, 5))

    # Print cursor move right
    put_char(ut88, 0x18)

    # Validate the cursor is moved to the next line
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 6)


def test_print_move_right_3(ut88):
    # Put a few characters on the screen
    ut88.set_byte(pos(5, 0), 0x35)      # First line
    ut88.set_byte(pos(20, 1), 0x56)     # 2nd line
    ut88.set_byte(pos(10, 9), 0x42)     # 10th line
    ut88.set_byte(pos(63, 27), 0x24)    # last line

    # Move cursor at the end of the last line
    ut88.set_word(CURSOR_POS_ADDR, pos(63, 27))

    # Print cursor move right
    put_char(ut88, 0x18)

    # Validate the cursor is moved to the next line, but the line is scrolled up
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 27)

    # Check that chars were also scrolled
    assert ut88.get_byte(pos(5, 0)) != 0x35     # No more char on the first line
    assert ut88.get_byte(pos(20, 0)) == 0x56    # 2nd line became 1st line
    assert ut88.get_byte(pos(10, 8)) == 0x42    # 10th line became 9th line
    assert ut88.get_byte(pos(63, 26)) == 0x24   # Last line became 27th line
    

def test_print_move_left_1(ut88):    
    # Print some symbols
    put_char(ut88, 'A')
    put_char(ut88, 'B')
    put_char(ut88, 'C')

    # Move cursor at B position, in the middle of the line
    ut88.set_word(CURSOR_POS_ADDR, pos(1, 0))

    # Print cursor move left
    put_char(ut88, 0x08)

    # Validate the cursor is moved to the previous position, but symbols are intact
    assert ut88.get_word(CURSOR_POS_ADDR) == VIDEO_MEM_ADDR     # Cursor moved left
    assert ut88.get_byte(pos(0, 0)) == ord('A')                 # Symbol intact
    assert ut88.get_byte(pos(1, 0)) == ord('B')                 # Symbol intact


def test_print_move_left_2(ut88):    
    # Move cursor to the top-left position
    ut88.set_word(CURSOR_POS_ADDR, pos(0, 0))

    # Try moving cursor move left further
    put_char(ut88, 0x08)

    # Validate the cursor is not moved
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 0)


def test_print_move_up_1(ut88):    
    # Move cursor at some position in the middle of the screen
    ut88.set_word(CURSOR_POS_ADDR, pos(20, 10))

    # Print cursor move up
    put_char(ut88, 0x19)

    # Validate the cursor is moved up
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(20, 9)     # Cursor moved up


def test_print_move_up_2(ut88):    
    # Move cursor to the top line
    ut88.set_word(CURSOR_POS_ADDR, pos(10, 0))

    # Try moving cursor up
    put_char(ut88, 0x19)

    # Validate the cursor is not moved
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(10, 0)

    
def test_print_move_down_1(ut88):    
    # Move cursor at some position in the middle of the screen
    ut88.set_word(CURSOR_POS_ADDR, pos(20, 10))

    # Print cursor move down
    put_char(ut88, 0x1a)

    # Validate the cursor is moved down
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(20, 11)     # Cursor moved down


def test_print_move_down_2(ut88):    
    # Put a few characters on the screen
    ut88.set_byte(pos(5, 0), 0x35)      # First line
    ut88.set_byte(pos(20, 1), 0x56)     # 2nd line
    ut88.set_byte(pos(10, 9), 0x42)     # 10th line
    ut88.set_byte(pos(63, 27), 0x24)    # last line

    # Move cursor to the bottom line
    ut88.set_word(CURSOR_POS_ADDR, pos(10, 27))

    # Try moving cursor down
    put_char(ut88, 0x1a)

    # Validate the screen has scrolled, and cursor moved to the beginning of the next line
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 27)

    # Check that chars were scrolled
    assert ut88.get_byte(pos(5, 0)) != 0x35     # No more char on the first line
    assert ut88.get_byte(pos(20, 0)) == 0x56    # 2nd line became 1st line
    assert ut88.get_byte(pos(10, 8)) == 0x42    # 10th line became 9th line
    assert ut88.get_byte(pos(63, 26)) == 0x24   # Last line became 27th line
    

def test_print_line_feed_1(ut88):    
    # Move cursor at some position in the middle of the screen
    ut88.set_word(CURSOR_POS_ADDR, pos(20, 10))

    # Print line feed char
    put_char(ut88, 0x0a)

    # Validate the cursor is moved to the first position on the next line
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 11)     # Cursor moved


def test_print_line_feed_2(ut88):    
    # Move cursor at some position in the middle of the last line
    ut88.set_word(CURSOR_POS_ADDR, pos(20, 27))

    # Print line feed char
    put_char(ut88, 0x0a)

    # Validate the cursor is moved to the first position on the next line, but screen is scrolled
    assert ut88.get_word(CURSOR_POS_ADDR) == pos(0, 27)     # Cursor moved



def test_wait_kbd_normal_char(ut88):
    ut88._keyboard.emulate_key_press('A')   # Latin letter
    assert wait_kbd(ut88) == ord('A')

    ut88._keyboard.emulate_key_press('!')   # Symbol
    assert wait_kbd(ut88) == ord('!')

    ut88._keyboard.emulate_key_press('1')   # Digit
    assert wait_kbd(ut88) == ord('1')

    ut88._keyboard.emulate_key_press('Й')   # Russian letter
    assert wait_kbd(ut88) == 0x6a


def test_wait_kbd_ctrl_char(ut88):
    ut88._keyboard.emulate_ctrl_key_press('D')   # Ctrl-D
    assert wait_kbd(ut88) == 0x04


def test_wait_kbd_auto_repeat(ut88):
    ut88._keyboard.emulate_key_press('A')   # Latin letter
    assert wait_kbd(ut88) == ord('A')
    assert wait_kbd(ut88) == ord('A')
    assert wait_kbd(ut88) == ord('A')


def test_wait_kbd_special_char(ut88):
    ut88._keyboard.emulate_special_key_press(pygame.K_LEFT)
    assert wait_kbd(ut88) == 0x08

    ut88._keyboard.emulate_special_key_press(pygame.K_RIGHT)
    assert wait_kbd(ut88) == 0x18

    ut88._keyboard.emulate_special_key_press(pygame.K_UP)
    assert wait_kbd(ut88) == 0x19

    ut88._keyboard.emulate_special_key_press(pygame.K_DOWN)
    assert wait_kbd(ut88) == 0x1a

    ut88._keyboard.emulate_special_key_press(pygame.K_DELETE)
    assert wait_kbd(ut88) == 0x1f

    ut88._keyboard.emulate_special_key_press(pygame.K_HOME)
    assert wait_kbd(ut88) == 0x0c

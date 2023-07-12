# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CP/M operating system (BDOS console functions), rather than UT-88 schematics. 
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


def call_bdos_function(cpm, func, arg = 0):
    cpm.cpu._c = func
    cpm.cpu.de = arg
    cpm.run_function(0xcc06)
    return (cpm.cpu._b << 8) | cpm.cpu._a


def test_bdos_console_input(cpm):
    cpm.keyboard.emulate_key_press('A')
    ch = call_bdos_function(cpm, 0x01)

    assert ch == ord('A')                   # 'A' is returned as a result value
    assert cpm.get_byte(0xe800) == 0x41     # 'A' is printed on the screen
    assert cpm.get_word(0xf7b2) == 0xe801   # Cursor moved to the next position


def test_bdos_console_input_special_symbol(cpm):
    cpm.keyboard.emulate_ctrl_key_press('C')    # Press Ctrl-C
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
    cpm.keyboard.emulate_key_press('A')
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


def test_bdos_read_console_buffer(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("TEST\n")

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # Number of entered characters
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')


def test_bdos_read_console_buffer_buffer_too_small(cpm):
    cpm.set_byte(0x1000, 0x04)              # Reserve just 4 bytes for the buffer

    cpm.emulate_key_sequence("TESTTEST\n")

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

    cpm.emulate_key_sequence("\x04\n")

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x01     # Number of entered characters
    assert cpm.get_byte(0x1002) == 0x04     # Entered symbol
    assert cpm.get_byte(0xe800) == ord('^') # Printed ^D
    assert cpm.get_byte(0xe801) == ord('D')


def test_bdos_read_console_backspace(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("TEST\x08Q\n")    # Add backspace symbol

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
    cpm.emulate_key_sequence("\x08TEST\n")    

    call_bdos_function(cpm, 0x0a, 0x1000)   # Input string

    assert cpm.get_byte(0x1000) == 0x20     # Buffer size
    assert cpm.get_byte(0x1001) == 0x04     # All 4 symbols are entered
    assert cpm.get_byte(0x1002) == ord('T') # Entered characters
    assert cpm.get_byte(0x1003) == ord('E')
    assert cpm.get_byte(0x1004) == ord('S')
    assert cpm.get_byte(0x1005) == ord('T')


def test_bdos_read_console_backspace_3(cpm):
    cpm.set_byte(0x1000, 0x20)              # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("TE\x04\x08ST\n")    # Backspace a 2-char control symbol

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
    cpm.emulate_key_sequence("TEST\x18 ABCD\n")    

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

    cpm.emulate_key_sequence("TE\x05ST\n")    # End of line in the middle of the string

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
    cpm.emulate_key_sequence("TEST\x15A BCD\n")

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
    cpm.emulate_key_sequence("TE\x12ST\n")

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
    cpm.keyboard.emulate_key_press('A')
    pressed = call_bdos_function(cpm, 0x0b)
    assert pressed


def test_bdos_check_key_not_pressed(cpm):
    pressed = call_bdos_function(cpm, 0x0b)
    assert not pressed


def test_bdos_get_version(cpm):
    ver = call_bdos_function(cpm, 0x0c)
    assert ver == 0x22

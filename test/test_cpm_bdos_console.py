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

# Standard entry point for all BDOS functions
# The function number is passed to the function in the C register
BDOS_ENTRY_POINT                = 0xcc06

# The following functions are used in this test module
BDOS_FUNC_CONSOLE_INPUT         = 0x01
BDOS_FUNC_CONSOLE_OUT_CHAR      = 0x02
BDOS_FUNC_CONSOLE_DIRECT_OUT    = 0x06
BDOS_FUNC_PRINT_STRING          = 0x09
BDOS_FUNC_INPUT_STRING          = 0x0a
BDOS_FUNC_GET_CONSOLE_STATUS    = 0x0b
BDOS_FUNC_GET_CPM_VERSION       = 0x0c

# As a result of BDOS console functions some data may be printed on the screen
# Video memory is a 28 lines * 64 chars each, allocated line by line from top-left to bottom-right corner
VIDEO_RAM                       = 0xe800

# The console input function accepts a pre-configured buffer. The first byte in the buffer indicates the
# buffer size. Upon return from the function, the second byte in the buffer will indicate how many symbols
# were actually entered
BUF_PTR                         = 0x1000

# MonitorF has a special variable that contains current cursor address (pointing to the video memory range)
CURSOR_PTR                      = 0xf7b2

@pytest.fixture
def cpm():
    return CPM()


def call_bdos_function(cpm, func, arg = 0):
    cpm.cpu.c = func
    cpm.cpu.de = arg
    cpm.run_function(BDOS_ENTRY_POINT)
    return (cpm.cpu.b << 8) | cpm.cpu.a


def test_bdos_console_input(cpm):
    cpm.keyboard.emulate_key_press('A')
    ch = call_bdos_function(cpm, BDOS_FUNC_CONSOLE_INPUT)

    assert ch == ord('A')                               # 'A' is returned as a result value
    assert cpm.get_byte(VIDEO_RAM) == ord('A')          # 'A' is printed on the screen
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM + 1    # Cursor moved to the next position


def test_bdos_console_input_special_symbol(cpm):
    cpm.keyboard.emulate_ctrl_key_press('C')        # Press Ctrl-C
    ch = call_bdos_function(cpm, BDOS_FUNC_CONSOLE_INPUT)

    assert ch == 0x03                               # Ctrl-C is returned as a result value
    assert cpm.get_byte(VIDEO_RAM) == 0x00          # No symbol is printed
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM    # Cursor not moved


def test_bdos_console_output_regular_char(cpm):
    call_bdos_function(cpm, BDOS_FUNC_CONSOLE_OUT_CHAR, ord('A'))

    assert cpm.get_byte(VIDEO_RAM) == ord('A')      # 'A' is printed on the screen
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM + 1# Cursor moved to the next position


def test_bdos_console_output_tab(cpm):
    call_bdos_function(cpm, BDOS_FUNC_CONSOLE_OUT_CHAR, 0x09)

    assert cpm.get_byte(VIDEO_RAM + 0) == 0x20      # 8 spaces are printed on the screen
    assert cpm.get_byte(VIDEO_RAM + 7) == 0x20      # 8 spaces are printed on the screen
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM + 8# Cursor moved to the next position


def test_bdos_console_output_lf(cpm):
    call_bdos_function(cpm, BDOS_FUNC_CONSOLE_OUT_CHAR, ord('A')) # Just print something
    call_bdos_function(cpm, BDOS_FUNC_CONSOLE_OUT_CHAR, 0x0a)     # Print LF

    assert cpm.get_byte(VIDEO_RAM) == ord('A')      # 'A' is printed
    assert cpm.get_word(CURSOR_PTR) == 0xe840       # Cursor moved to the beginning of the next line


def test_bdos_console_output_cr(cpm):
    call_bdos_function(cpm, BDOS_FUNC_CONSOLE_OUT_CHAR, ord('A')) # Just print something
    call_bdos_function(cpm, BDOS_FUNC_CONSOLE_OUT_CHAR, 0x0d)     # Print CR

    assert cpm.get_byte(VIDEO_RAM) == ord('A')      # 'A' is printed
    # CR printing is not supported by the Monitor. It is printed like a normal character, and thererfore
    # cursor advances right
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM + 2   


def test_bdos_console_direct_output(cpm):
    call_bdos_function(cpm, BDOS_FUNC_CONSOLE_DIRECT_OUT, ord('A')) # Just print something

    assert cpm.get_byte(VIDEO_RAM) == ord('A')      # 'A' is printed
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM + 1# Cursor is advanced


def test_bdos_console_direct_input(cpm):
    cpm.keyboard.emulate_key_press('A')
    ch = call_bdos_function(cpm, BDOS_FUNC_CONSOLE_DIRECT_OUT, 0xff)# Set the input mode

    assert ch == ord('A')                           # Input character is A
    assert cpm.get_byte(VIDEO_RAM) == 0x00          # No echo
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM    # Cursor has not moved


def test_bdos_print_string(cpm):
    cpm.set_byte(0x1234, ord('T'))
    cpm.set_byte(0x1235, ord('E'))
    cpm.set_byte(0x1236, ord('S'))
    cpm.set_byte(0x1237, ord('T'))
    cpm.set_byte(0x1238, ord('$'))
    call_bdos_function(cpm, BDOS_FUNC_PRINT_STRING, 0x1234)   # Print the string

    assert cpm.get_byte(VIDEO_RAM + 0) == ord('T')
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('E')
    assert cpm.get_byte(VIDEO_RAM + 2) == ord('S')
    assert cpm.get_byte(VIDEO_RAM + 3) == ord('T')
    assert cpm.get_byte(VIDEO_RAM + 4) == 0x00          # Stopped here
    assert cpm.get_word(CURSOR_PTR) == VIDEO_RAM + 4    # Cursor is advanced and stopped after 4 symbols printed


def test_bdos_read_console_buffer(cpm):
    cpm.set_byte(BUF_PTR, 0x20)              # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("TEST\n")

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20        # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04        # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('T')    # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('E')
    assert cpm.get_byte(BUF_PTR + 4) == ord('S')
    assert cpm.get_byte(BUF_PTR + 5) == ord('T')


def test_bdos_read_console_buffer_buffer_too_small(cpm):
    cpm.set_byte(BUF_PTR, 0x04)                     # Reserve just 4 bytes for the buffer

    cpm.emulate_key_sequence("TESTTEST\n")

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x04        # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04        # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('T')    # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('E')
    assert cpm.get_byte(BUF_PTR + 4) == ord('S')
    assert cpm.get_byte(BUF_PTR + 5) == ord('T')
    assert cpm.get_byte(BUF_PTR + 6) == 0x00        # No buffer overrun


def test_bdos_read_console_ctrl_symbol(cpm):
    cpm.set_byte(BUF_PTR, 0x20)              # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("^D\n")

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20        # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x01        # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == 0x04        # Entered symbol
    assert cpm.get_byte(VIDEO_RAM + 0) == ord('^')  # Printed ^D
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('D')


def test_bdos_read_console_backspace(cpm):
    cpm.set_byte(BUF_PTR, 0x20)                     # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("TEST\x08Q\n")         # Add backspace symbol

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20        # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04        # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('T')    # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('E')
    assert cpm.get_byte(BUF_PTR + 4) == ord('S')
    assert cpm.get_byte(BUF_PTR + 5) == ord('Q')    # Replaced symbol
    assert cpm.get_byte(VIDEO_RAM + 0) == ord('T')  # Printed "TESQ"
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('E')
    assert cpm.get_byte(VIDEO_RAM + 2) == ord('S')
    assert cpm.get_byte(VIDEO_RAM + 3) == ord('Q')


def test_bdos_read_console_backspace_2(cpm):
    cpm.set_byte(BUF_PTR, 0x20)                     # Reserve 0x20 bytes for the buffer

    # Backspace symbol in the beginning. Should not make any harm
    cpm.emulate_key_sequence("\x08TEST\n")    

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20        # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04        # All 4 symbols are entered
    assert cpm.get_byte(BUF_PTR + 2) == ord('T')    # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('E')
    assert cpm.get_byte(BUF_PTR + 4) == ord('S')
    assert cpm.get_byte(BUF_PTR + 5) == ord('T')


def test_bdos_read_console_backspace_3(cpm):
    cpm.set_byte(BUF_PTR, 0x20)                     # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("TE^D\x08ST\n")        # Backspace a 2-char control symbol

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20        # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04        # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('T')    # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('E')
    assert cpm.get_byte(BUF_PTR + 4) == ord('S')
    assert cpm.get_byte(BUF_PTR + 5) == ord('T')
    assert cpm.get_byte(VIDEO_RAM + 0) == ord('T')  # Printed "TEST"
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('E')
    assert cpm.get_byte(VIDEO_RAM + 2) == ord('S')
    assert cpm.get_byte(VIDEO_RAM + 3) == ord('T')


def test_bdos_read_console_backspace_4(cpm):
    cpm.set_byte(BUF_PTR, 0x20)              # Reserve 0x20 bytes for the buffer

    # Ctrl-X (0x18) - backspace till start of the line
    # The function does extra keyboard read after Ctrl-X, so just emulate an extra symbol after Ctrl-x, which
    # will be ignored. This is an emulation issue, rather than CP/M code buf
    cpm.emulate_key_sequence("TEST^X ABCD\n")    

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20        # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04        # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('A')    # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('B')
    assert cpm.get_byte(BUF_PTR + 4) == ord('C')
    assert cpm.get_byte(BUF_PTR + 5) == ord('D')
    assert cpm.get_byte(VIDEO_RAM + 0) == ord('A')  # Printed "TEST"
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('B')
    assert cpm.get_byte(VIDEO_RAM + 2) == ord('C')
    assert cpm.get_byte(VIDEO_RAM + 3) == ord('D')


def test_bdos_read_console_end_of_line(cpm):
    cpm.set_byte(BUF_PTR, 0x20)                         # Reserve 0x20 bytes for the buffer

    cpm.emulate_key_sequence("TE^EST\n")                # End of line in the middle of the string

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20            # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04            # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('T')        # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('E')
    #assert cpm.get_byte(BUF_PTR + 4) == 0x05           # Ctrl-E is NOT in the buffer
    assert cpm.get_byte(BUF_PTR + 4) == ord('S')
    assert cpm.get_byte(BUF_PTR + 5) == ord('T')

    assert cpm.get_byte(VIDEO_RAM + 0) == ord('T')      # Printed "TE"
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('E')
    assert cpm.get_byte(VIDEO_RAM + 0x40) == ord('S')   # and "ST" on the next line
    assert cpm.get_byte(VIDEO_RAM + 0x41) == ord('T')


def test_bdos_read_console_abandon_current_line(cpm):
    cpm.set_byte(BUF_PTR, 0x20)              # Reserve 0x20 bytes for the buffer

    # Ctrl-U (0x15) - backspace till start of the line
    # The function does extra keyboard read after Ctrl-U and 'A', so just emulate an extra symbol after 'A', 
    # which will be ignored. This is an emulation issue, rather than CP/M code buf
    cpm.emulate_key_sequence("TEST^UA BCD\n")

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20            # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04            # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('A')        # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('B')
    assert cpm.get_byte(BUF_PTR + 4) == ord('C')
    assert cpm.get_byte(BUF_PTR + 5) == ord('D')
    assert cpm.get_byte(VIDEO_RAM + 0) == ord('T')      # Printed "TEST"
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('E')
    assert cpm.get_byte(VIDEO_RAM + 2) == ord('S') 
    assert cpm.get_byte(VIDEO_RAM + 3) == ord('T')
    assert cpm.get_byte(VIDEO_RAM + 4) == ord('#')      # Then a hash symbol
    assert cpm.get_byte(VIDEO_RAM + 0x40) == ord('A')   # The restart reading from the next line
    assert cpm.get_byte(VIDEO_RAM + 0x41) == ord('B')
    assert cpm.get_byte(VIDEO_RAM + 0x42) == ord('C') 
    assert cpm.get_byte(VIDEO_RAM + 0x43) == ord('D')


def test_bdos_read_console_retype_current_line(cpm):
    cpm.set_byte(BUF_PTR, 0x20)              # Reserve 0x20 bytes for the buffer

    # Ctrl-R (0x12) - retype currently entered characters from the new line
    cpm.emulate_key_sequence("TE^RST\n")

    call_bdos_function(cpm, BDOS_FUNC_INPUT_STRING, BUF_PTR)   # Input string

    assert cpm.get_byte(BUF_PTR + 0) == 0x20            # Buffer size
    assert cpm.get_byte(BUF_PTR + 1) == 0x04            # Number of entered characters
    assert cpm.get_byte(BUF_PTR + 2) == ord('T')        # Entered characters
    assert cpm.get_byte(BUF_PTR + 3) == ord('E')
    assert cpm.get_byte(BUF_PTR + 4) == ord('S')
    assert cpm.get_byte(BUF_PTR + 5) == ord('T')

    assert cpm.get_byte(VIDEO_RAM + 0) == ord('T')      # Printed "TE"
    assert cpm.get_byte(VIDEO_RAM + 1) == ord('E')
    assert cpm.get_byte(VIDEO_RAM + 2) == ord('#')      # then hash

    assert cpm.get_byte(VIDEO_RAM + 0x40) == ord('T')   # "TE" is redrawn from the new line
    assert cpm.get_byte(VIDEO_RAM + 0x41) == ord('E')
    assert cpm.get_byte(VIDEO_RAM + 0x42) == ord('S')   # "ST" - finish typing test string
    assert cpm.get_byte(VIDEO_RAM + 0x43) == ord('T')


def test_bdos_check_key_pressed(cpm):
    cpm.keyboard.emulate_key_press('A')
    pressed = call_bdos_function(cpm, BDOS_FUNC_GET_CONSOLE_STATUS)
    assert pressed


def test_bdos_check_key_not_pressed(cpm):
    pressed = call_bdos_function(cpm, BDOS_FUNC_GET_CONSOLE_STATUS)
    assert not pressed


def test_bdos_get_version(cpm):
    ver = call_bdos_function(cpm, BDOS_FUNC_GET_CPM_VERSION)
    assert ver == 0x22

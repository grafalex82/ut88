import sys

from utils import set_bit, clear_bit

CURSOR_POS_ADDR = 0xf7b2
VIDEO_MEMORY_ADDR = 0xe800
VIDEO_MEMORY_SIZE = 0x0700
LINE_WIDTH = 0x40

"""
    MonitorF and CP/M BIOS provide functions to print characters to the console. UT-88 emulator does a
    good job emulating all the instructions in this code, as they would be executed on a real CPU. 
    
    At the same time printing a character is a pretty heavy operation, and consumes a lot of CPU cycles.

    This class hooks calls to the BIOS and Monitor put char functions, and perform the same operations
    put in python. This provides up to 5x performance boost on operatons that print a lot of data on the
    screen.

    The implementation of the put char function made as close as possible to the original i8080 code.
    - Normal characters are printed at the cursor position, and cursor advances 1 position right
    - If end of the screen is reached, the display contents is scrolled one position up
    - Clear screen, and cursor move up/down/left/right/home characters processed accordingly
    - The implementation handles <0x1b> - 'Y' - <y_pos> - <x_pos> sequence for direct cursor movement
      (MonitorF functionality)
"""
class BIOSDisplayEmulator():
    def __init__(self, machine):
        self._machine = machine
        self._sequence_byte = 0

    def _get_cursor_position(self):
        return self._machine.read_memory_word(CURSOR_POS_ADDR)
    

    def _set_cursor_position(self, pos):
        self._machine.write_memory_word(CURSOR_POS_ADDR, pos)


    def _hide_cursor(self, pos):
        char = self._machine.read_memory_byte(pos+1)
        self._machine.write_memory_byte(pos+1, clear_bit(char, 7)) # Remove inversion


    def _show_cursor(self, pos):
        char = self._machine.read_memory_byte(pos+1)
        self._machine.write_memory_byte(pos+1, set_bit(char, 7)) # Enable symbol inversion


    def _clear_screen(self):
        # Fill screen with spaces
        for addr in range(VIDEO_MEMORY_ADDR, VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE):
            self._machine.write_memory_byte(addr, ord(' '))

        return VIDEO_MEMORY_ADDR


    def _home_screen(self):
        return VIDEO_MEMORY_ADDR


    def _move_cursor_left(self, pos):
        if pos == VIDEO_MEMORY_ADDR:
            return VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE - 1 # Move to the very last position
        
        return pos - 1    # Otherwise move just 1 symbol left


    def _move_cursor_right(self, pos):
        if pos == VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE - 1:
            return VIDEO_MEMORY_ADDR     # Move to the very first position

        return pos + 1                   # Otherwise move just 1 symbol right


    def _move_cursor_up(self, pos):
        pos -= LINE_WIDTH
        if pos < VIDEO_MEMORY_ADDR:
            pos += VIDEO_MEMORY_SIZE
        return pos


    def _move_cursor_down(self, pos):
        pos += LINE_WIDTH
        if pos >= VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE:
            pos -= VIDEO_MEMORY_SIZE
        return pos


    def _carriage_return(self, pos):
        add = LINE_WIDTH - pos % LINE_WIDTH
        return pos + add


    def _scroll_one_line(self):
        # Copy all lines one line up
        for addr in range(VIDEO_MEMORY_ADDR, VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE - LINE_WIDTH):
            char = self._machine.read_memory_byte(addr + LINE_WIDTH)
            self._machine.write_memory_byte(addr, char)

        # Fill the line with spaces
        for addr in range(VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE - LINE_WIDTH, VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE):
            self._machine.write_memory_byte(addr, ord(' '))


    def _handle_direct_cursor_move(self, pos, char):
        if self._sequence_byte == 0 and char == 0x1b:    # Esc
            self._sequence_byte = 1
            return pos
        
        if self._sequence_byte == 1 and char == 0x59:    # Y
            self._sequence_byte = 2
            return pos
        
        if self._sequence_byte == 2:
            # Move cursor to selected line, preserve column position
            pos = ((char - 0x20) * LINE_WIDTH + VIDEO_MEMORY_ADDR)  +  (pos % LINE_WIDTH) 
            self._sequence_byte = 3
            return pos

        if self._sequence_byte == 3:
            # Move cursor to the selected column, preserve the line
            pos = (pos & 0xffc0)  + (char - 0x20)

        # Reset the sequence mode
        self._sequence_byte = 0
        return pos



    def _put_normal_char(self, pos, char):
        self._machine.write_memory_byte(pos, char)
        return pos + 1


    def put_char(self, char):
        pos = self._get_cursor_position()
        self._hide_cursor(pos)

        # Process special symbols separately
        if char == 0x1f:
            pos = self._clear_screen()
        elif char == 0x0c:
            pos = self._home_screen()
        elif char == 0x08:
            pos = self._move_cursor_left(pos)
        elif char == 0x18:
            pos = self._move_cursor_right(pos)
        elif char == 0x19:
            pos = self._move_cursor_up(pos)
        elif char == 0x1a:
            pos = self._move_cursor_down(pos)
        elif char == 0x0a:
            pos = self._carriage_return(pos)
        elif char == 0x1b or self._sequence_byte != 0:
            pos = self._handle_direct_cursor_move(pos, char)
        else:   # Otherwise print character normally
            pos = self._put_normal_char(pos, char)

        # If the cursor position moves out of the screen - scroll the screen 1 line up
        if pos >= VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE:
            self._scroll_one_line()
            pos -= LINE_WIDTH

        self._set_cursor_position(pos)
        self._show_cursor(pos)


def hook_put_char(cpu, emulator):
    emulator.put_char(cpu.c)
    cpu.set_pc(0xfccd)  # Route directly to RET instruction


def setup_bios_put_char_emulation(emulator):
    de = BIOSDisplayEmulator(emulator._machine)
    emulator.add_breakpoint(0xfc43, lambda: hook_put_char(emulator._cpu, de))
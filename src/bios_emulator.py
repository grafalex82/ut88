import sys

CURSOR_POS_ADDR = 0xf7b2
VIDEO_MEMORY_ADDR = 0xe800
VIDEO_MEMORY_SIZE = 0x0700

class BIOSDisplayEmulator():
    def __init__(self, machine):
        self._machine = machine


    def _get_cursor_position(self):
        return self._machine.read_memory_word(CURSOR_POS_ADDR)
    

    def _set_cursor_position(self, pos):
        self._machine.write_memory_word(CURSOR_POS_ADDR, pos)


    def _hide_cursor(self, pos):
        char = self._machine.read_memory_byte(pos+1)
        self._machine.write_memory_byte(pos+1, char & 0x7f) # Remove high bit (remove inversion)


    def _show_cursor(self, pos):
        char = self._machine.read_memory_byte(pos+1)
        self._machine.write_memory_byte(pos+1, char | 0x80) # Set high bit (enable symbol inversion)


    def _clear_screen(self):
        # Fill screen with spaces
        for addr in range(VIDEO_MEMORY_ADDR, VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE):
            self._machine.write_memory_byte(addr, 0x20)

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
        pos -= 64
        if pos < VIDEO_MEMORY_ADDR:
            pos += VIDEO_MEMORY_SIZE
        return pos


    def _move_cursor_down(self, pos):
        pos += 64
        if pos >= VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE:
            pos -= VIDEO_MEMORY_SIZE
        return pos


    def _carriage_return(self, pos):
        add = 64 - pos % 64
        return pos + add


    def _scroll_one_line(self):
        # Copy all lines one line up
        for addr in range(VIDEO_MEMORY_ADDR, VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE - 0x40):
            char = self._machine.read_memory_byte(addr + 0x40)
            self._machine.write_memory_byte(addr, char)

        # Fill the line with spaces
        for addr in range(VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE - 0x40, VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE):
            self._machine.write_memory_byte(addr, 0x20)


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
        else:   # Otherwise print character normally
            pos = self._put_normal_char(pos, char)

        # If the cursor position moves out of the screen - scroll the screen 1 line up
        if pos >= VIDEO_MEMORY_ADDR + VIDEO_MEMORY_SIZE:
            self._scroll_one_line()
            pos -= 64

        self._set_cursor_position(pos)
        self._show_cursor(pos)

        self._machine._cpu.set_pc(0xfccd)   # Route directly to RET. HACK, do this in a nicer way


def setup_bios_put_char_emulation(emulator):
    de = BIOSDisplayEmulator(emulator._machine)
    emulator.add_breakpoint(0xfc43, lambda: de.put_char(emulator._cpu.c))
import os
import pygame

from common.utils import *
from common.interfaces import *
from common.surface import DisplaySurface, CHAR_WIDTH, CHAR_HEIGHT

resources_dir = os.path.join(os.path.dirname(__file__), "..", "..", "resources")


class RK86Display:
    def __init__(self, dma):
        self._dma = dma
        self._surface = DisplaySurface(f"{resources_dir}/rk86_font.bin", 78, 30)

        self._current_command = None
        self._current_parameter = None

        self._spaced_rows = False
        self._screen_width = None
        self._screen_height = None
        self._vertical_retrace = None
        self._underline_height = None
        self._character_height = None
        self._line_counter_mode = None
        self._field_attr_mode = None
        self._cursor_format = None
        self._horizontal_retrace = None
        
        self._cursor_x = None
        self._cursor_y = None
        self._cursor_invert = False
        self._cursor_timer = 0

        self._burst_space_code = None
        self._burst_count_code = None

    def get_size(self):
        return 2    # The Intel 8275 controller has just 2 registers
    

    def select_font(self, alternate = False):
        self._surface.select_font(alternate)


    def _handle_command(self, value):
        match value >> 5:
            case 0: # Reset
                self._current_command = value
                self._current_parameter = 0
            case 1: # Start Display
                self._burst_space_code = ((value >> 2) & 0x07) * 8 - 1
                self._burst_count_code = ((value & 0x03) + 1) * 2
                self._handle_start_display_command()
            case 4: # Set Cursor Position
                self._current_command = value
                self._current_parameter = 0
            case _:
                raise IOError(f"Unsupported i8275 command: 0x{value:02x}")


    def _handle_reset_command_parameter(self, value):
        match self._current_parameter:
            case 0:
                self._spaced_rows = (value & 0x80) != 0
                self._screen_width = (value & 0x7f) + 1
                self._current_parameter += 1
            case 1:
                self._screen_height = (value & 0x3f) + 1
                self._vertical_retrace = (value >> 6) + 1
                self._current_parameter += 1
            case 2:
                self._underline_height = ((value >> 4) & 0x0f) + 1
                self._character_height = (value & 0x0f) + 1
                self._current_parameter += 1
            case 3:
                self._line_counter_mode = (value & 0x80) != 0
                self._field_attr_mode = (value & 0x40) != 0
                self._cursor_format = (value & 0x30) >> 4
                self._horizontal_retrace = ((value & 0x0f) + 1) * 2
                self._current_parameter = None
                self._current_command = None
            case _:
                raise IOError("Incorrect parameter index for i8275 Reset command")


    def _handle_set_cursor_command_parameter(self, value):
        match self._current_parameter:
            case 0: # X position
                self._cursor_x = value
                self._current_parameter += 1
            case 1: # Y position
                self._cursor_y = value
                self._current_parameter = None
                self._current_command = None
            case _:
                raise IOError("Incorrect parameter index for i8275 Set Cursor command")
            


    def _handle_parameter(self, value):
        match self._current_command:
            case 0x00: # Reset command
                return self._handle_reset_command_parameter(value)
            case 0x80: # Set cursor position
                return self._handle_set_cursor_command_parameter(value)
            case _:
                raise IOError("Writing i8275 parameter for an unknown command")
    

    def _handle_start_display_command(self):
        screen_size = self._surface.set_size(self._screen_width, self._screen_height)
        pygame.display.set_mode(screen_size)


    def _read_status_reg(self):
        return 0x20 # TODO: return a meaningful value
    

    def read_byte(self, offset):
        match offset:
            case 1:
                return self._read_status_reg()
            case _:
                raise MemoryError(f"Writing CRT register {offset} is not supported")        


    def write_byte(self, offset, value):
        match offset:
            case 1:
                self._handle_command(value)
            case 0:
                self._handle_parameter(value)
            case _:
                raise MemoryError(f"Writing CRT register {offset} is not supported")
            

    def update_screen(self, screen):
        # Read the video memory over the DMA
        data = self._dma.dma_read(2)

        # Update chars on the surface
        index = 0
        for y in range(self._screen_height):
            for x in range(self._screen_width):
                ch = data[index]
                if x == self._cursor_x and y==self._cursor_y and self._cursor_invert:
                    ch |= 0x80
                self._surface.update_char(x, y, ch)

                index += 1

        # Blit the surface to the screen
        self._surface.blit(screen)

        # Toggle cursor when time comes
        if pygame.time.get_ticks() - self._cursor_timer > 500:
            self._cursor_timer = pygame.time.get_ticks()
            self._cursor_invert = not self._cursor_invert

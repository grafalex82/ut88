import os
import logging
import pygame
from tkinter import filedialog

from emulator import Emulator
from machine import Machine
from ram import RAM
from rom import ROM
from lcd import LCD
from hexkbd import HexKeyboard
from timer import Timer
from tape import TapeRecorder
from utils import NestedLogger

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")

BASIC_CONFIGURATION_LEGEND = """
Keys:
  0-9, A-F  - hexadecimal buttons
  Backspace - step back button
  Esc       - CPU Reset
  L         - Load a tape file
  S         - Save a tape file
"""

class Configuration:
    def __init__(self):
        self._screen = pygame.display.set_mode(self.get_screen_size())
        self._clock = pygame.time.Clock()

        self._machine = Machine()
        self._emulator = Emulator(self._machine)

        self._logger = NestedLogger()


    def run(self):
        while True:
            self._screen.fill(pygame.Color('black'))
            
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    exit()
            
            self._emulator.run(50000)

            if pygame.key.get_pressed()[pygame.K_ESCAPE]:
                self._emulator.reset()

            self._machine.update()

            self.update(self._screen)                

            pygame.display.flip()
            self._clock.tick(60)
            pygame.display.set_caption(f"UT-88 Emulator (FPS={self._clock.get_fps()})")


class BasicConfiguration(Configuration):
    def __init__(self):
        Configuration.__init__(self)
 
        # Create legend text
        green = (0, 255, 0)
        font = pygame.font.SysFont('Courier New', 24)
        self._legendtext = font.render(BASIC_CONFIGURATION_LEGEND, True, green)
        self._legendrect = self._legendtext.get_rect().move(0, 80)

        # Create main RAM and ROMs
        self._machine.add_memory(RAM(0xC000, 0xC3ff))
        self._machine.add_memory(ROM(f"{resources_dir}/Monitor0.bin", 0x0000))
        self._machine.add_memory(ROM(f"{resources_dir}/calculator.bin", 0x0800))

        # Add peripherals
        self._lcd = LCD()
        self._machine.add_memory(self._lcd)
        self._kbd = HexKeyboard()
        self._machine.add_io(self._kbd)
        self._timer = Timer(self._machine)
        self._machine.add_other_device(self._timer)
        self._recorder = TapeRecorder()
        self._machine.add_io(self._recorder)

        # Suppress logging for some functions in this configuration
        self._emulator.add_breakpoint(0x0000, lambda: self._logger.reset())

        self._emulator.add_breakpoint(0x0008, lambda: self._logger.enter("RST 1: Out byte"))
        self._emulator.add_breakpoint(0x0120, lambda: self._logger.exit())
        self._emulator.add_breakpoint(0x0018, lambda: self._logger.enter("RST 3: Wait 1s"))
        self._emulator.add_breakpoint(0x005e, lambda: self._logger.exit())
        self._emulator.add_breakpoint(0x0021, lambda: self._logger.enter("RST 4: Wait a button"))
        self._emulator.add_breakpoint(0x006d, lambda: self._logger.exit())

        self._emulator.add_breakpoint(0x0a92, lambda: self._logger.enter("STORE A-B-C to [HL]"))
        self._emulator.add_breakpoint(0x0a97, lambda: self._logger.exit())
        self._emulator.add_breakpoint(0x0a8c, lambda: self._logger.enter("LOAD [HL] to A-B-C"))
        self._emulator.add_breakpoint(0x0a91, lambda: self._logger.exit())
        self._emulator.add_breakpoint(0x0b08, lambda: self._logger.enter("POWER"))
        self._emulator.add_breakpoint(0x0b6a, lambda: self._logger.exit())
        self._emulator.add_breakpoint(0x0987, lambda: self._logger.enter("ADD"))
        self._emulator.add_breakpoint(0x0993, lambda: self._logger.exit())
        self._emulator.add_breakpoint(0x0a6f, lambda: self._logger.enter("DIV"))
        self._emulator.add_breakpoint(0x0a8b, lambda: self._logger.exit())
        self._emulator.add_breakpoint(0x09ec, lambda: self._logger.enter("MULT"))
        self._emulator.add_breakpoint(0x09f8, lambda: self._logger.exit())


    def get_screen_size(self):
        return (450, 294)
    

    def update(self, screen):
        if pygame.key.get_pressed()[pygame.K_l]:
            filename = filedialog.askopenfilename(filetypes=(("Tape files", "*.tape"), ("All files", "*.*")))
            self._recorder.load_from_file(filename)
        if pygame.key.get_pressed()[pygame.K_s]:
            filename = filedialog.asksaveasfilename(filetypes=(("Tape files", "*.tape"), ("All files", "*.*")),
                                                    defaultextension="tape")
            self._recorder.dump_to_file(filename)

        self._lcd.update_screen(screen)
        self._kbd.update()

        screen.blit(self._legendtext, self._legendrect)


def main():
    pygame.init()

    logging.basicConfig(level=logging.DEBUG)
    
    configuration = BasicConfiguration()
    configuration.run()


if __name__ == '__main__':
    main()

import os
import logging
import pygame
import argparse
from tkinter import filedialog

from emulator import Emulator
from machine import Machine
from ram import RAM
from rom import ROM
from lcd import LCD
from hexkbd import HexKeyboard
from timer import Timer
from tape import TapeRecorder
from keyboard import Keyboard
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
        self._emulator.add_breakpoint(0x0000, lambda: self._logger.reset())


    def run(self):
        self._emulator.reset()

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

    def suppress_logging(self, startaddr, endaddr, msg):
        self._emulator.add_breakpoint(startaddr, lambda: self._logger.enter(msg))
        self._emulator.add_breakpoint(endaddr, lambda: self._logger.exit())


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
        self.suppress_logging(0x0008, 0x0120, "RST 1: Out byte")
        self.suppress_logging(0x0018, 0x005e, "RST 3: Wait 1s")
        self.suppress_logging(0x0021, 0x006d, "RST 4: Wait a button")
        self.suppress_logging(0x0a92, 0x0a97, "STORE A-B-C to [HL]")
        self.suppress_logging(0x0a8c, 0x0a91, "LOAD [HL] to A-B-C")
        self.suppress_logging(0x0b08, 0x0b6a, "POWER")
        self.suppress_logging(0x0987, 0x0993, "ADD")
        self.suppress_logging(0x0a6f, 0x0a8b, "DIV")
        self.suppress_logging(0x09ec, 0x09f8, "MULT")

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


class VideoConfiguration(Configuration):
    def __init__(self):
        Configuration.__init__(self)

        # This configuration will start right from MonitorF, skipping the Monitor0 for convenience
        self._emulator.set_start_addr(0xf800)

        # Create main RAM and ROMs
        self._machine.add_memory(RAM(0xc000, 0xc3ff))
        self._machine.add_memory(RAM(0xf400, 0xf7ff))
        self._machine.add_memory(ROM(f"{resources_dir}/Monitor0.bin", 0x0000))
        self._machine.add_memory(ROM(f"{resources_dir}/MonitorF.bin", 0xf800))

        # Add peripherals
        self._recorder = TapeRecorder()
        self._machine.add_io(self._recorder)
        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)


        # Suppress logging for some functions in this configuration
        # self.suppress_logging(0x0008, 0x0120, "RST 1: Out byte")

    def get_screen_size(self):
        return (450, 294) #FIXME
    
    def update(self, screen):
        pass
        # if pygame.key.get_pressed()[pygame.K_l]:
        #     filename = filedialog.askopenfilename(filetypes=(("Tape files", "*.tape"), ("All files", "*.*")))
        #     self._recorder.load_from_file(filename)
        # if pygame.key.get_pressed()[pygame.K_s]:
        #     filename = filedialog.asksaveasfilename(filetypes=(("Tape files", "*.tape"), ("All files", "*.*")),
        #                                             defaultextension="tape")
        #     self._recorder.dump_to_file(filename)

        # self._lcd.update_screen(screen)
        # self._kbd.update()


def main():
    parser = argparse.ArgumentParser(
                    prog='UT-88 Emulator',
                    description='UT-88 DIY i8080-based computer emulator')
    
    parser.add_argument('configuration', choices=["basic", "video"])
    args = parser.parse_args()

    pygame.init()

    logging.basicConfig(level=logging.DEBUG)
    
    if args.configuration == "basic":
        configuration = BasicConfiguration()
    if args.configuration == "video":
        configuration = VideoConfiguration()
    
    configuration.run()


if __name__ == '__main__':
    main()

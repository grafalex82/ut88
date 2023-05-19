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
from display import Display
from utils import NestedLogger


resources_dir = os.path.join(os.path.dirname(__file__), "../resources")
tapes_dir = os.path.join(os.path.dirname(__file__), "../tapes")

BASIC_CONFIGURATION_LEGEND = """
Keys:
  0-9, A-F  - hexadecimal buttons
  Backspace - step back button
  Esc       - CPU Reset
  Alt-L     - Load a tape file
  Alt-S     - Save a tape file
"""

filetypes=((".PKI tape files", "*.pki *.gam"), 
           (".RK Tape files", "*.rk *.rku"), 
           ("All files", "*.*"))

def open_pki():
    return filedialog.askopenfilename(filetypes=filetypes)


def save_pki():
    return filedialog.asksaveasfilename(filetypes=filetypes, defaultextension="pki")


def breakpoint():
    logging.disable(logging.NOTSET)

class Configuration:
    def __init__(self):
        self._screen = pygame.display.set_mode(self.get_screen_size())
        self._clock = pygame.time.Clock()

        self._machine = Machine()
        self._emulator = Emulator(self._machine)

        self._emulator._cpu.enable_registers_logging(True)

        self._logger = NestedLogger()
        self._emulator.add_breakpoint(self.get_start_address(), lambda: self._logger.reset())

        self._suppressed_logs = []

        self._emulator.set_start_addr(self.get_start_address())



    def get_start_address(self):
        return 0x0000


    def run(self):
        self._emulator.reset()

        while True:
            self._screen.fill(pygame.Color('black'))
            
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    exit()

                self.handle_event(event)
            
            self._emulator.run(20000)

            if pygame.key.get_pressed()[pygame.K_ESCAPE]:
                self._emulator.reset()

            alt_pressed = pygame.key.get_mods() & (pygame.KMOD_ALT | pygame.KMOD_META) 
            if pygame.key.get_pressed()[pygame.K_m] and alt_pressed:
                self._emulator.load_memory(open_pki())

            self._machine.update()

            self.update(self._screen)                

            pygame.display.flip()
            self._clock.tick(60)
            pygame.display.set_caption(f"UT-88 Emulator (FPS={self._clock.get_fps()})")

    def suppress_logging(self, startaddr, endaddr, msg):
        self._suppressed_logs.append((startaddr, endaddr, msg))


    def enable_logging(self, enable):
        if enable:
            logging.basicConfig(level=logging.DEBUG)

            for startaddr, endaddr, msg in self._suppressed_logs:
                self._emulator.add_breakpoint(startaddr, lambda: self._logger.enter(msg))
                self._emulator.add_breakpoint(endaddr, lambda: self._logger.exit())


    def handle_event(self, event):
        pass


class BasicConfiguration(Configuration):
    def __init__(self):
        Configuration.__init__(self)
 
        # Create legend text
        green = (0, 255, 0)
        font = pygame.font.SysFont('Courier New', 24)
        self._legendtext = font.render(BASIC_CONFIGURATION_LEGEND, True, green)
        self._legendrect = self._legendtext.get_rect().move(0, 80)

        # Create main RAM and ROMs
        self._machine.add_memory(RAM(0xc000, 0xc3ff))
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
        alt_pressed = pygame.key.get_mods() & (pygame.KMOD_ALT | pygame.KMOD_META) 
        if pygame.key.get_pressed()[pygame.K_l] and alt_pressed:
            self._recorder.load_from_file(open_pki())
        if pygame.key.get_pressed()[pygame.K_s] and alt_pressed:
            self._recorder.dump_to_file(save_pki())


        self._lcd.update_screen(screen)
        self._kbd.update()

        screen.blit(self._legendtext, self._legendrect)


class VideoConfiguration(Configuration):
    def __init__(self):
        Configuration.__init__(self)

        # Create main RAM and ROMs
        self._machine.add_memory(RAM(0x0000, 0x3fff))
        self._machine.add_memory(RAM(0xc000, 0xc3ff))
        self._machine.add_memory(RAM(0xf400, 0xf7ff))
        self._machine.add_memory(ROM(f"{resources_dir}/Monitor0.bin", 0x0000))
        self._machine.add_memory(ROM(f"{resources_dir}/MonitorF.bin", 0xf800))

        self._emulator.load_memory(f"{tapes_dir}/TETR1.GAM")

        # Add peripherals
        self._recorder = TapeRecorder()
        self._machine.add_io(self._recorder)
        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)
        self._display = Display()
        self._machine.add_memory(self._display)

        # Suppress logging for some functions in this configuration
        self.suppress_logging(0xfcce, 0xfcd4, "Clear Screen")
        self.suppress_logging(0xf849, 0xf84c, "Initial memset")
        self.suppress_logging(0xfd92, 0xfd95, "Beep")
        self.suppress_logging(0xfd57, 0xfd99, "Keyboard input")
        self.suppress_logging(0xfc43, 0xfccd, "Put char")
        self.suppress_logging(0xfbee, 0xfc2d, "Out byte")
        self.suppress_logging(0xfb71, 0xfc2d, "Input byte")
        self.suppress_logging(0xfba1, 0xfbac, "Tape read delay")

        # Monitor F wipes out 0xf7b0-f7ff range during initialization. This range contains monitor's
        # variables, including 0xf7b2, which contains cursor address. Char printing code does invert of 
        # the symbol at cursor address, which in this case causing writing into 0x0000 ROM area. This
        # is not an issue for a real computer - write operation will not harm any memory. But this cause
        # writing ROM exception on the emulator. 
        #
        # The solution is to additionally initialize the variable with some meaningful value
        self._emulator.add_breakpoint(0xf852, lambda: self._emulator._machine.write_memory_word(0xf7b2, 0xe800))

        # Each key press generates a short beep. This procedure is quite slow, when running under emulator.
        # So let's just speed it up a little bit, by setting a shorter delay value.
        self._emulator.add_breakpoint(0xfe4d, lambda: self._emulator._cpu.set_pc(0xfe62))

        # Functions that intputs/outputs a byte to/from the tape for some reason sets SP to 0, and then
        # does a POP instruction. Perhaps this is done for some kind of a delay - POP operation takes 10
        # CPU cycles, while NOP takes just 4. In the real computer this does not make any harm - just
        # reads a garbage, but emulator asserts that there stack operations on ROM (and ROM at 0x0000 
        # may not be even installed).
        self._emulator.add_breakpoint(0xfbf9, lambda: self._emulator._cpu.set_sp(0xc000))
        self._emulator.add_breakpoint(0xfb7c, lambda: self._emulator._cpu.set_sp(0xc000))
        self._emulator.add_breakpoint(0xfb86, lambda: self._emulator._cpu.set_sp(0xc000))

        #self._emulator.add_breakpoint(0xff49, breakpoint) # ...


    def get_start_address(self):
        # This configuration will start right from MonitorF, skipping the Monitor0 for convenience
        return 0xf800


    def get_screen_size(self):
        return (64*16, 28*16)


    def update(self, screen):
        alt_pressed = pygame.key.get_mods() & (pygame.KMOD_ALT | pygame.KMOD_META) 
        if pygame.key.get_pressed()[pygame.K_l] and alt_pressed:
            self._recorder.load_from_file(open_pki())
        if pygame.key.get_pressed()[pygame.K_s] and alt_pressed:
            self._recorder.dump_to_file(save_pki())

        self._display.update_screen(screen)


    def handle_event(self, event):
        self._keyboard.handle_key_event(event)


def main():
    parser = argparse.ArgumentParser(
                    prog='UT-88 Emulator',
                    description='UT-88 DIY i8080-based computer emulator')
    
    parser.add_argument('configuration', choices=["basic", "video"])
    parser.add_argument('-d', '--debug', help="enable CPU instructions logging", action='store_true')
    args = parser.parse_args()

    pygame.init()

    
    if args.configuration == "basic":
        configuration = BasicConfiguration()
    if args.configuration == "video":
        configuration = VideoConfiguration()
    
    configuration.enable_logging(args.debug)

    configuration.run()


if __name__ == '__main__':
    main()

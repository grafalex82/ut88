import os
import logging
import pygame
import argparse
from tkinter import filedialog

from emulator import Emulator
from machine import UT88Machine
from ram import RAM
from rom import ROM
from lcd import LCD
from hexkbd import HexKeyboard
from timer import Timer
from tape import TapeRecorder
from keyboard import Keyboard
from display import Display
from utils import NestedLogger
from quasidisk import QuasiDisk
from bios_emulator import *

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

        self._machine = UT88Machine()
        self._emulator = Emulator(self._machine)

        self._emulator.set_start_addr(self.get_start_address())

        self.create_memories()
        self.create_peripherals()


        self._emulator._cpu.enable_registers_logging(True)

        self._logger = NestedLogger()
        self._emulator.add_breakpoint(self.get_start_address(), lambda: self._logger.reset())
        self._suppressed_logs = []

        self.configure_logging()
        self.setup_special_breakpoints()


    def create_memories(self):
        pass


    def create_peripherals(self):
        pass


    def configure_logging(self):
        pass


    def setup_special_breakpoints(self):
        pass


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
        class LoggerEnterFunctor:
            def __init__(self, logger, msg):
                self._logger = logger
                self._msg = msg

            def __call__(self):
                #print(f"Entering nested logger: {self._msg}")
                self._logger.enter(self._msg)

        class LoggerExitFunctor:
            def __init__(self, logger, msg):
                self._logger = logger
                self._msg = msg

            def __call__(self):
                #print(f"Exiting nested logger: {self._msg}")
                self._logger.exit()

        if enable:
            logging.basicConfig(level=logging.DEBUG)

            for startaddr, endaddr, msg in self._suppressed_logs:
                enter = LoggerEnterFunctor(self._logger, msg)
                self._emulator.add_breakpoint(startaddr, enter)

                exit = LoggerExitFunctor(self._logger, msg)
                self._emulator.add_breakpoint(endaddr, exit)


    def enable_bios_emulation(self):
        pass


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


    def create_memories(self):
        self._machine.add_memory(RAM(0xc000, 0xc3ff))
        self._machine.add_memory(ROM(f"{resources_dir}/Monitor0.bin", 0x0000))
        self._machine.add_memory(ROM(f"{resources_dir}/calculator.bin", 0x0800))


    def create_peripherals(self):
        self._lcd = LCD()
        self._machine.add_memory(self._lcd)
        self._kbd = HexKeyboard()
        self._machine.add_io(self._kbd)
        self._timer = Timer(self._machine)
        self._machine.add_other_device(self._timer)
        self._recorder = TapeRecorder()
        self._machine.add_io(self._recorder)


    def configure_logging(self):
        # Monitor 0 suppression
        self.suppress_logging(0x0008, 0x0120, "RST 1: Out byte")
        self.suppress_logging(0x0018, 0x005e, "RST 3: Wait 1s")
        self.suppress_logging(0x0021, 0x006d, "RST 4: Wait a button")

        # Calculator firmware suppression
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


    def create_memories(self):
        self._machine.add_memory(RAM(0x0000, 0x7fff))
        self._machine.add_memory(RAM(0xc000, 0xc3ff))
        self._machine.add_memory(RAM(0xf400, 0xf7ff))
        self._machine.add_memory(ROM(f"{resources_dir}/MonitorF.bin", 0xf800))


    def create_peripherals(self):
        self._recorder = TapeRecorder()
        self._machine.add_io(self._recorder)
        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)
        self._display = Display()
        self._machine.add_memory(self._display)


    def configure_logging(self):
        self.suppress_logging(0xf849, 0xf84c, "Initial memset")
        self.suppress_logging(0xfd92, 0xfd95, "Beep")
        self.suppress_logging(0xfd57, 0xfd99, "Keyboard input")
        self.suppress_logging(0xfd9a, 0xfdad, "Scan keyboard")
        self.suppress_logging(0xfc47, 0xfccd, "Put char")   # Function starts at fc43, but CP/M BIOS makes
                                                            # direct jump to fc47
        self.suppress_logging(0xfbee, 0xfc2d, "Out byte")
        self.suppress_logging(0xfb71, 0xfc2d, "Input byte")
        self.suppress_logging(0xfba1, 0xfbac, "Tape read delay")


    def setup_special_breakpoints(self):
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


    def get_start_address(self):
        # This configuration will start right from MonitorF, skipping the Monitor0 for convenience
        return 0xf800


    def get_screen_size(self):
        return (64*12, 28*16)


    def update(self, screen):
        alt_pressed = pygame.key.get_mods() & (pygame.KMOD_ALT | pygame.KMOD_META) 
        if pygame.key.get_pressed()[pygame.K_l] and alt_pressed:
            self._recorder.load_from_file(open_pki())
        if pygame.key.get_pressed()[pygame.K_s] and alt_pressed:
            self._recorder.dump_to_file(save_pki())

        self._display.update_screen(screen)


    def handle_event(self, event):
        self._keyboard.handle_key_event(event)


    def enable_bios_emulation(self):
        setup_bios_put_char_emulation(self._emulator)



class QuasiDiskConfiguration(VideoConfiguration):
    def __init__(self):
        VideoConfiguration.__init__(self)


    def create_memories(self):
        self._machine.add_memory(RAM(0x0000, 0xe000))
        self._machine.add_memory(RAM(0xf400, 0xf7ff))
        self._machine.add_memory(ROM(f"{resources_dir}/MonitorF.bin", 0xf800))

        # Load full CPM64 image, just in case if someone wants start with boot loader
        # Start address: 0x3100
        self._emulator.load_memory(f"{tapes_dir}/cpm64.RKU")    

        # Already loaded CP/M parts for a faster boot
        # Start address: 0xda00
        self._emulator.load_memory(f"{tapes_dir}/cpm64_ccp.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bdos.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bios.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_monitorf_addon.rku")


    def create_peripherals(self):
        VideoConfiguration.create_peripherals(self)

        self._quasidisk = QuasiDisk("QuasiDisk.bin")
        self._machine.set_quasi_disk(self._quasidisk)


    def configure_logging(self):
        # Use same log suppression as in Video configuration
        VideoConfiguration.configure_logging(self)

        self.suppress_logging(0xcc06, 0xd99a, lambda: print(f"BDOS function {self._emulator._cpu.c:02x}"))


    def setup_special_breakpoints(self):
        # Use same special breakpoints as in Video Configuration
        VideoConfiguration.setup_special_breakpoints(self)

        # Additionally set a few more specific to CP/M

        # There is a mismatch between MonitorF input char function and CP/M BIOS/BDOS expectations of this
        # function. MonitorF implementation has a feature of auto-repeat symbol - when a button is pressed,
        # the function returns the entered key, but raises a flag that the key is still pressed, and in some
        # time may generate more keypress events. At the same time BDOS console input function works as
        # follows:
        # - Wait for a button press using BIOS/MonitorF facilities
        # - Echo the entered symbol. And here is most interesting begins:
        #   - BDOS Put char function, despite it outputs the character, it also checks keyboad input in order
        #     to handle Ctrl-C or Ctrl-S key combination. 
        #   - Put char function calls BIOS' Is key pressed function, and it returns True since the key is
        #     really (still) pressed
        #   - Since put char function detects that the key is still pressed, it calls BIOS' wait for key press
        #     function again. But since the key is still pressed there are 2 ways
        #     - User holds the key until auto-repeat feature is triggered in a second or so, in this case
        #       previous key code is generated
        #     - User will release te button, and the function will enter a wait loop until the next button is
        #       pressed
        # The issue is this is still a single key processing, while implementation does 2 separate wait-for-key
        # loops.
        #
        # The workaround is to remove keyboard checking while printing the character. The cost of this
        # workaround is that it will be impossible to cancel long lasting printing with Ctrl-C combination,
        # but that is ok, since the emulator provides the reset function which may do basically the same.
        self._emulator.add_breakpoint(0xcd30, lambda: self._emulator._cpu.set_pc(0xcd41))
        



class UT88OSConfiguration(VideoConfiguration):
    def __init__(self):
        VideoConfiguration.__init__(self)


    def create_memories(self):
        # No ROMS, only memory for all 64k, except for video RAM added by Display component
        self._machine.add_memory(RAM(0x0000, 0xe7ff))
        self._machine.add_memory(RAM(0xf000, 0xffff))

        # Load bootstrapped UT-88 OS images
        self._emulator.load_memory(f"{tapes_dir}/ut88os_editor.rku")    # 0xc000-0xdfff
        self._emulator.load_memory(f"{tapes_dir}/ut88os_monitor.rku")   # 0xf800-0xffff


    def configure_logging(self):
        self.suppress_logging(0xf98b, 0xf9b2, "Out byte")
        self.suppress_logging(0xf9f4, 0xfa1d, "Put char")
#        self.suppress_logging(0xf86b, 0xf90c, "Kbd input")


    def setup_special_breakpoints(self):
        # Each key press generates a short beep. This procedure is quite slow, when running under emulator.
        # So let's just skip it.
        self._emulator.add_breakpoint(0xf8fb, lambda: self._emulator._cpu.set_pc(0xf905))

        # Cursor blinking function expects HL to point to the cursor position. Some keyboard scanning functions
        # (see 0xf8f0) changes HL value, and restart keyboard scanning and cursor blinking with a wrong HL
        # This hack fixes the problem by setting HL to the right cursor position.
        self._emulator.add_breakpoint(0xf876, lambda: self._emulator._cpu.set_hl(self._machine.read_memory_word(0xf75a)))

        # Monitor tries to write into 2 video RAM areas: 0xe800 to write symbols. and 0xe000 to write attribute
        # (high bit inverts the symbol). It is also assumed that 0xe000 writes ONLY attribute bit, and does
        # not change the symbol. At the same time published schematics does not distinguish between these two
        # memory areas, and provide access to 2k video RAM at both memory ranges. This causes 2 problems:
        # 1) code that suppose to change only attributes (e.g. 0xf876 and 0xf908) in fact changes the symbol
        #    in video memory
        # 2) emulator supports video RAM onlye at 0xe800 range, while RAM at 0xe000 is not considered as video
        #    RAM. 
        #
        # The code as is work ok, but the cursor highlight is not visible. If change the binary so that it
        # uses 0xe800 memory for both symbols and attributes will cause visual bug when the symbol is entered
        # twice (once at real cursor position, another at a blinking bar, which is in fact located in the next
        # symbol). This hack clears the symbol under the blinking bar.
        #self._emulator.add_breakpoint(0xf909, lambda: self._machine.write_memory_byte(self._emulator._cpu.hl, 0x20))


def main():
    parser = argparse.ArgumentParser(
                    prog='UT-88 Emulator',
                    description='UT-88 DIY i8080-based computer emulator')
    
    parser.add_argument('configuration', choices=["basic", "video", "ut88os", "cpm64"])
    parser.add_argument('-d', '--debug', help="enable CPU instructions logging", action='store_true')
    parser.add_argument('-b', '--emulate_bios', help="emulate BIOS and MonitorF I/O functions", action='store_true')
    args = parser.parse_args()

    pygame.init()

    
    if args.configuration == "basic":
        configuration = BasicConfiguration()
    if args.configuration == "video":
        configuration = VideoConfiguration()
    if args.configuration == "ut88os":
        configuration = UT88OSConfiguration()
    if args.configuration == "cpm64":
        configuration = QuasiDiskConfiguration()
    
    configuration.enable_logging(args.debug)
    if args.emulate_bios:
        configuration.enable_bios_emulation()

    configuration.run()


if __name__ == '__main__':
    main()

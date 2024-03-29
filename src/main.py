import os
import logging
import pygame
import argparse
from tkinter import filedialog

from common.emulator import Emulator
from common.machine import Machine
from common.interfaces import MemoryDevice, IODevice
from common.ram import RAM
from common.rom import ROM
from common.dma import DMA
from common.ppi import PPI
from common.tape import TapeRecorder
from common.utils import NestedLogger
from ut88.lcd import LCD
from ut88.hexkbd import HexKeyboard
from ut88.timer import Timer
from ut88.keyboard import Keyboard
from ut88.display import Display
from ut88.quasidisk import QuasiDisk
from ut88.machine import UT88Machine
from ut88.bios_emulator import *
from radio86rk.keyboard import RK86Keyboard
from radio86rk.display import RK86Display

resources_dir = os.path.join(os.path.dirname(__file__), "..", "resources")
tapes_dir = os.path.join(os.path.dirname(__file__), "..", "tapes")

BASIC_CONFIGURATION_LEGEND = """
Keys:
  0-9, A-F  - hexadecimal buttons
  Backspace - step back button
  Esc       - CPU Reset
  Alt-L     - Load a tape file
  Alt-S     - Save a tape file
"""

filetypes=((".RK Tape files", "*.rk *.rku"), 
           (".PKI tape files", "*.pki *.gam"), 
           ("All files", "*.*"))

def open_pki():
    return filedialog.askopenfilename(filetypes=filetypes)


def save_pki():
    return filedialog.asksaveasfilename(filetypes=filetypes, defaultextension="pki")


def beep():
    print("\a")     # Make a ding sound

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


    def use_alternalte_font(self):
        pass

    def run(self):
        self._emulator.reset()

        while True:
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

            surface = pygame.display.get_surface()
            surface.fill(pygame.Color('black'))
            self.update(surface)

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

        # Render each line of the legend separately (font.render() does not support multiline text)
        self._legendtext = []
        y = 0
        for line in BASIC_CONFIGURATION_LEGEND.split('\n'):
            text = font.render(line, True, green)
            rect = text.get_rect().move(0, 80 + y)
            self._legendtext.append((text, rect))
            y += 24 # Font height


    def create_memories(self):
        self._machine.add_memory(MemoryDevice(RAM(), 0xc000, 0xc3ff))
        self._machine.add_memory(MemoryDevice(ROM(f"{resources_dir}/monitor0.bin"), 0x0000))
        self._machine.add_memory(MemoryDevice(ROM(f"{resources_dir}/calculator.bin"), 0x0800))


    def create_peripherals(self):
        self._lcd = LCD()
        self._machine.add_memory(MemoryDevice(self._lcd, 0x9000))
        self._kbd = HexKeyboard()
        self._machine.add_io(IODevice(self._kbd, 0xa0))
        self._timer = Timer(self._machine)
        self._machine.add_other_device(self._timer)
        self._recorder = TapeRecorder()
        self._machine.add_io(IODevice(self._recorder, 0xa1))


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

        for text, rect in self._legendtext:
            screen.blit(text, rect)


class VideoConfiguration(Configuration):
    def __init__(self):
        Configuration.__init__(self)


    def create_memories(self):
        self._machine.add_memory(MemoryDevice(RAM(), 0x0000, 0x7fff))
        self._machine.add_memory(MemoryDevice(RAM(), 0xc000, 0xc3ff))
        self._machine.add_memory(MemoryDevice(RAM(), 0xf400, 0xf7ff))
        self._machine.add_memory(MemoryDevice(ROM(f"{resources_dir}/monitorF.bin"), 0xf800))


    def create_peripherals(self):
        self._recorder = TapeRecorder()
        self._machine.add_io(IODevice(self._recorder, 0xa1))

        self._keyboard = Keyboard()
        ppi = PPI()
        ppi.set_portA_handler(self._keyboard.write_columns)
        ppi.set_portB_handler(self._keyboard.read_rows)
        ppi.set_portC_handler(self._keyboard.read_mod_keys)
        self._machine.add_io(IODevice(ppi, 0x04, invertaddr=True))

        self._display = Display()
        self._machine.add_memory(MemoryDevice(self._display, 0xe000))


    def use_alternalte_font(self):
        self._display.select_font(True)


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
        # So let's just speed it up a little bit, by skipping the beep code.
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
        self._machine.add_memory(MemoryDevice(RAM(), 0x0000, 0xe000))
        self._machine.add_memory(MemoryDevice(RAM(), 0xf400, 0xf7ff))
        self._machine.add_memory(MemoryDevice(ROM(f"{resources_dir}/monitorF.bin"), 0xf800))

        # Load full CPM64 image, just in case if someone wants start with boot loader
        # Start address: 0x3100
        self._emulator.load_memory(f"{tapes_dir}/cpm64.rku")

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
        self._machine.add_memory(MemoryDevice(RAM(), 0x0000, 0xdfff))
        self._machine.add_memory(MemoryDevice(RAM(), 0xf000, 0xffff))

        # Load bootstrapped UT-88 OS images
        self._emulator.load_memory(f"{tapes_dir}/ut88os_monitor.rku")   # 0xf800-0xffff
        self._emulator.load_memory(f"{tapes_dir}/ut88os_monitor2.rku")  # 0xc000-0xcaff
        self._emulator.load_memory(f"{tapes_dir}/ut88os_editor.rku")    # 0xcb00-0xd37f
        self._emulator.load_memory(f"{tapes_dir}/ut88os_assembler.rku") # 0xd380-0xdfff
        #self._emulator.load_memory(f"{tapes_dir}/test_text.rku")        # 0x3000-
        self._emulator.load_memory(f"{tapes_dir}/test_asm.rku")        # 0x3000-


    def configure_logging(self):
        self.suppress_logging(0xf936, 0xf98a, "In byte")
        self.suppress_logging(0xf98b, 0xf9b2, "Out byte")
        self.suppress_logging(0xf9f4, 0xfa1d, "Put char")
        self.suppress_logging(0xf86b, 0xf90c, "Kbd input")
        self.suppress_logging(0xcb1c, 0xcb1f, "Editor: get end of file")


    def setup_special_breakpoints(self):
        # Each key press generates a short beep. This procedure is quite slow, when running under emulator.
        # So let's just skip it.
        self._emulator.add_breakpoint(0xf8fb, lambda: self._emulator._cpu.set_pc(0xf905))

        # Cursor blinking function expects HL to point to the cursor position. Some keyboard scanning functions
        # (see 0xf8f0) change HL value, and cursor blinking code gets a wrong HL.
        # This hack fixes the problem by setting HL to the right cursor position.
        self._emulator.add_breakpoint(0xf876, lambda: self._emulator._cpu.set_hl(self._machine.read_memory_word(0xf75a) - 0x800))

        # The UT-88 OS Monitor tape function outputs data bytes negated, compared to original Monitor0 and
        # MonitorF implementations. This is not a problem for the real hardware, as tape input function has
        # a polarity detection mechanism, but this code causes problems when running on an emulator - all data
        # bytes must be negated to save data in positive polarity. Do not forget to negate it back on exit.
        self._emulator.add_breakpoint(0xf98b, lambda: self._emulator._cpu.set_a(self._emulator._cpu.a ^ 0xff))
        self._emulator.add_breakpoint(0xf9b2, lambda: self._emulator._cpu.set_a(self._emulator._cpu.a ^ 0xff))

        # When the monitor command is entered, and user presses Return key, it remains pressed for some time,
        # until the emulator starts key events processing. Some of the printing functions check the keyboard
        # for a keypress, and abandon the command execution. Emulate keyboard release after the command is
        # entered, but not yet processed. This is an emulation issue, rather than Monitor code bug.
        self._emulator.add_breakpoint(0xf84b, lambda: self._keyboard.emulate_key_press(None))

        # UT-88 OS monitor and editor programs indicate incorrect user input with a sound. Tape recorder must
        # be connected to the computer to hear the beep tone. Since the emulator does not produce any sound on
        # tape recorder port, it is handy to detect these functions and produce a standard system ding sound
        # instead.
        self._emulator.add_breakpoint(0xfb8f, lambda: beep())   # Monitor INPUT_ERROR function
        self._emulator.add_breakpoint(0xccdb, lambda: beep())   # Editor BEEP function


class Radio86RKConfiguration(Configuration):
    def __init__(self):
        Configuration.__init__(self)


    def create_memories(self):
        self._machine.add_memory(MemoryDevice(RAM(), 0x0000, 0x7fff))
        self._machine.add_memory(MemoryDevice(ROM(f"{resources_dir}/rk86_monitor.bin"), 0xf800))

        self._emulator.load_memory(f"{tapes_dir}/lrunner.rku")   # 0x0000-...


    def create_peripherals(self):
        # All Radio86RK peripherals are connected to the memory lines, not I/O lines, and therefore
        # require special adapters

        # self._recorder = TapeRecorder()
        # self._machine.add_io(self._recorder)
        self._ppi = PPI()
        self._machine.add_memory(MemoryDevice(self._ppi, 0x8000))

        self._keyboard = RK86Keyboard()
        self._ppi.set_portA_handler(self._keyboard.set_columns)
        self._ppi.set_portB_handler(self._keyboard.read_rows)
        self._ppi.set_portC_bit_handler(6, self._keyboard.read_ctrl_key)
        self._ppi.set_portC_bit_handler(5, self._keyboard.read_shift_key)
        self._ppi.set_portC_bit_handler(7, self._keyboard.read_rus_key)

        self._dma = DMA(self._machine)
        self._machine.add_memory(MemoryDevice(self._dma, 0xe000))

        self._display = RK86Display(self._dma)
        self._machine.add_memory(MemoryDevice(self._display, 0xc000))

        self._recorder = TapeRecorder()
        # Intentionally not connecting tape recorder to port C here. Radio-86RK shares the same port
        # for tape recorder, keyboard mod keys, and Rus/Lat LED. This causes a lot of reads and writes
        # to this port, that limited functionality of the tape recorder emulator is not happy with.
        # These handlers are connected on tape in/out functions calls, and disconnected afterwards.
        # self._ppi.set_portC_bit_handler(0, self._recorder.write_bit)
        # self._ppi.set_portC_bit_handler(4, self._recorder.read_bit)


    def configure_logging(self):
        self.suppress_logging(0xf841, 0xf84c, "Initial memset")
        self.suppress_logging(0xfcba, 0xfd9d, "Put char")


    def setup_special_breakpoints(self):
        # Each key press requires a debounce period. In order to speed up the keyboard reading loop,
        # it is possible to reduce debounce loop to 1 pass when running under the emulator.
        self._emulator.add_breakpoint(0xfeb5, lambda: self._emulator._cpu.set_l(0x01))

        # Original Radio-86RK employs DMA controller for video RAM transfer. Time critical functions
        # such as tape input and output disable DMA while working with the tape recorder. Switching 
        # off the DMA transfer causes Emulator Display to crash when it can't get the next video data.
        # Fortunately in this emulator the DMA transfer does not introduce any delays, so switching 
        # off DMA is not necessary.
        self._emulator.add_breakpoint(0xfc4a, lambda: self._emulator._cpu.set_pc(0xfc4f))
        self._emulator.add_breakpoint(0xfb9c, lambda: self._emulator._cpu.set_pc(0xfba1))

        # Reinitializing video controller on tape recorder data transfer is also not necessary
        self._emulator.add_breakpoint(0xfc0f, lambda: self._emulator._cpu.set_pc(0xfc29))
        self._emulator.add_breakpoint(0xfc86, lambda: self._emulator._cpu.set_pc(0xfca0))

        # The Radio-86RK shares same port for tape recorder, keyboard modifications, and the RUS/LED
        # indicator. The tape recorder emulation is not ready for extra reads and write to the port
        # that are unrelated to the tape input or output. In this emulator the tape recorder will be
        # connected to the Port C right before the data transfer, and disconnected afterwards.
        self._emulator.add_breakpoint(0xfb98, lambda: self._ppi.set_portC_bit_handler(4, self._recorder.read_bit))
        self._emulator.add_breakpoint(0xfc31, lambda: self._ppi.set_portC_bit_handler(4, None))
        self._emulator.add_breakpoint(0xfc46, lambda: self._ppi.set_portC_bit_handler(0, self._recorder.write_bit))
        self._emulator.add_breakpoint(0xfca0, lambda: self._ppi.set_portC_bit_handler(0, None))


    def get_start_address(self):
        # This configuration will start right from Monitor
        return 0xf800


    def get_screen_size(self):
        return (78*12, 30*16)


    def use_alternalte_font(self):
        self._display.select_font(True)


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
    
    parser.add_argument('configuration', choices=["basic", "video", "ut88os", "cpm64", "radio86rk"])
    parser.add_argument('-d', '--debug', help="enable CPU instructions logging", action='store_true')
    parser.add_argument('-b', '--emulate_bios', help="emulate BIOS and MonitorF I/O functions", action='store_true')
    parser.add_argument('-f', '--alternate_font', help="Use alternate font for the display", action='store_true')
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
    if args.configuration == "radio86rk":
        configuration = Radio86RKConfiguration()
    
    configuration.enable_logging(args.debug)
    if args.emulate_bios:
        configuration.enable_bios_emulation()
    if args.alternate_font:
        configuration.use_alternalte_font()

    configuration.run()


if __name__ == '__main__':
    main()

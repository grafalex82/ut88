import os

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")
tapes_dir = os.path.join(os.path.dirname(__file__), "../tapes")

from machine import UT88Machine
from emulator import Emulator
from cpu import CPU
from rom import ROM
from ram import RAM
from keyboard import Keyboard
from utils import *
from helper import EmulatedInstance

# UT88OS is a UT-88 machine with 64k RAM, and UT-88 OS binaries loaded to their appropriate memory ranges.
#
# This is a helper class that sets up the machine emulator, configures it for running a
# UT-88 OS functions, feeds function arguments, and retrieves the result
class UT88OS(EmulatedInstance):
    def __init__(self):
        EmulatedInstance.__init__(self)

        self._machine.add_memory(RAM(0x0000, 0xffff))

        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)

        self._emulator.load_memory(f"{tapes_dir}/ut88os_editor.rku")    # 0xc000-0xdfff
        self._emulator.load_memory(f"{tapes_dir}/ut88os_monitor.rku")   # 0xf800-0xffff

        self._emulator._cpu.enable_registers_logging(True)

        # Since we do not run Monitor initialization code, we need to initialize some variables
        self.set_word(0xf75a, 0xe800)   # Cursor position
        self.set_byte(0xf77a, 0xff)     # ????


    def _get_sp(self):
        return 0xf3fe



import os

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")
tapes_dir = os.path.join(os.path.dirname(__file__), "../tapes")

from machine import UT88Machine
from emulator import Emulator
from cpu import CPU
from rom import ROM
from ram import RAM
from keyboard import Keyboard
from quasidisk import QuasiDisk
from utils import *
from helper import EmulatedInstance

# CP/M is a UT-88 machine with monitorF ROM, and a 64k RAM + CP/M binary modules loaded.
#
# This is a helper class that sets up the machine emulator, configures it for running a
# CP/M functions, feeds function arguments, and retrieves the result
class CPM(EmulatedInstance):
    def __init__(self):
        EmulatedInstance.__init__(self)

        self._machine.add_memory(RAM(0x0000, 0xf7ff))
        self._machine.add_memory(ROM(f"{resources_dir}/MonitorF.bin", 0xf800))

        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)

        self._emulator.load_memory(f"{tapes_dir}/cpm64_bdos.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bios.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_monitorf_addon.rku")

        self._emulator._cpu.enable_registers_logging(True)

        # Since we do not run MonitorF initialization routine, let's just initialize needed variables,
        # and particularly set cursor to the top-left corner
        self.set_word(0xf7b2, 0xe800)

        # Each key press require 127 cycles of the keyboard scanning, until the key is considered pressed.
        # Skip this, 1 scan is enough. Key repeat function is also disabled, as not needed for tests
        self._emulator.add_breakpoint(0xfd75, lambda: self._emulator._cpu.set_pc(0xfd95))


    def _create_machine(self):
        return UT88Machine()

    def _get_sp(self):
        return 0xf6ee


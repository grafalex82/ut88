import os

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")
tapes_dir = os.path.join(os.path.dirname(__file__), "../tapes")

from machine import UT88Machine
from rom import ROM
from ram import RAM
from common.utils import *
from helper import EmulatedInstanceWithKeyboard
from common.interfaces import MemoryDevice

# CP/M is a UT-88 machine with monitorF ROM, and a 64k RAM + CP/M binary modules loaded.
#
# This is a helper class that sets up the machine emulator, configures it for running a
# CP/M functions, feeds function arguments, and retrieves the result
class CPM(EmulatedInstanceWithKeyboard):
    def __init__(self):
        EmulatedInstanceWithKeyboard.__init__(self)

        self._machine.add_memory(MemoryDevice(RAM(), 0x0000, 0xf7ff))
        self._machine.add_memory(MemoryDevice(ROM(f"{resources_dir}/MonitorF.bin"), 0xf800))

        self._emulator.load_memory(f"{tapes_dir}/cpm64_bdos.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_bios.rku")
        self._emulator.load_memory(f"{tapes_dir}/cpm64_monitorf_addon.rku")

        # Since we do not run MonitorF initialization routine, let's just initialize needed variables,
        # and particularly set cursor to the top-left corner
        self.set_word(0xf7b2, 0xe800)

        # Each key press require 127 cycles of the keyboard scanning, until the key is considered pressed.
        # Skip this, 1 scan is enough. Key repeat function is also disabled, as not needed for tests
        self._emulator.add_breakpoint(0xfd75, lambda: self._emulator._cpu.set_pc(0xfd95))


    def _create_machine(self):
        return UT88Machine()

    def _get_sp(self):
        # Set SP in some safe area in the Monitor memory below Monitor's variables
        return 0xf6ee

    def _install_keybord_generator(self, g):
        # Install keyboard generation hooks in the keyboard scanning function, so that each call
        # of the CPM's READ_CONSOLE_BUFFER function will return the next emulated keypress
        self._emulator.add_breakpoint(0xcde1, lambda: g.__next__())
        self._emulator.add_breakpoint(0xcdf4, lambda: g.__next__())

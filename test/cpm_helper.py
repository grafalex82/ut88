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

# CP/M is a UT-88 machine with monitorF ROM, and a 64k RAM + CP/M binary modules loaded.
#
# This is a helper class that sets up the machine emulator, configures it for running a
# CP/M functions, feeds function arguments, and retrieves the result
class CPM:
    def __init__(self):
        self._machine = UT88Machine()
        self._machine.add_memory(RAM(0x0000, 0xf7ff))
        self._machine.add_memory(ROM(f"{resources_dir}/MonitorF.bin", 0xf800))

        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)

        self._emulator = Emulator(self._machine)
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


    @property
    def cpu(self):
        return self._emulator._cpu

    def set_byte(self, addr, value):
        self._machine.write_memory_byte(addr, value)


    def set_word(self, addr, value):
        self._machine.write_memory_word(addr, value)


    def get_byte(self, addr):
        value = self._machine.read_memory_byte(addr)
        return value


    def get_word(self, addr):
        value = self._machine.read_memory_word(addr)
        return value


    def run_function(self, addr):
        # Put the breakpoint to the top of the stack
        # When a called function returns, it will get to the 0xbeef address
        self._emulator._cpu.sp = 0xf6ee
        self._emulator._machine.write_memory_word(0xf6ee, 0xbeef) # breakpoint return address

        # Will execute function starting from the given address
        self._emulator._cpu.pc = addr

        # Run the requested function, until it returns to 0xbeef
        # Set the counter limit to avoid infinite loop
        while self._emulator._cpu.pc != 0xbeef and self._emulator._cpu._cycles < 10000000:
            self._emulator.step()

        # Validate that the code really reached the end, and not stopped by a cycles limit
        assert self._emulator._cpu.pc == 0xbeef


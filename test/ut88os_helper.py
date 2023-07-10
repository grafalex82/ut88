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

# UT88OS is a UT-88 machine with 64k RAM, and UT-88 OS binaries loaded to their appropriate memory ranges.
#
# This is a helper class that sets up the machine emulator, configures it for running a
# UT-88 OS functions, feeds function arguments, and retrieves the result
class UT88OS:
    def __init__(self):
        self._machine = UT88Machine()
        self._machine.add_memory(RAM(0x0000, 0xffff))

        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)

        self._emulator = Emulator(self._machine)
        self._emulator.load_memory(f"{tapes_dir}/ut88os_editor.rku")    # 0xc000-0xdfff
        self._emulator.load_memory(f"{tapes_dir}/ut88os_monitor.rku")   # 0xf800-0xffff

        self._emulator._cpu.enable_registers_logging(True)

        # Since we do not run Monitor initialization code, we need to initialize some variables
        self.set_word(0xf75a, 0xe800)   # Cursor position
        self.set_byte(0xf77a, 0xff)     # ????


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
        self._emulator._cpu.sp = 0xf3fe
        self._emulator._machine.write_memory_word(0xf3fe, 0xbeef) # breakpoint return address

        # Will execute function starting from the given address
        self._emulator._cpu.pc = addr

        # Run the requested function, until it returns to 0xbeef
        # Set the counter limit to avoid infinite loop
        while self._emulator._cpu.pc != 0xbeef and self._emulator._cpu._cycles < 1000000:
            self._emulator.step()

        # Validate that the code really reached the end, and not stopped by a cycles limit
        assert self._emulator._cpu.pc == 0xbeef


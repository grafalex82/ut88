import sys

from machine import Machine
from emulator import Emulator
from cpu import CPU

sys.path.append('../misc')
sys.path.append('../src')

class EmulatedInstance:
    def __init__(self):
        self._machine = self._create_machine()
        self._emulator = self._create_emulator()


    def _create_machine(self):
        return Machine()


    def _create_emulator(self):
        return Emulator(self._machine)


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
        # When a calculator function will return, it will get to the 0xbeef address
        self._emulator._cpu.sp = self._get_sp()
        self._emulator._machine.write_memory_word(self._get_sp(), 0xbeef) # breakpoint return address

        # Will execute function starting from the given address
        self._emulator._cpu.pc = addr

        # Run the requested function, until it returns to 0xbeef
        # Set the counter limit to avoid infinite loop
        while self._emulator._cpu.pc != 0xbeef and self._emulator._cpu._cycles < 100000000:
            self._emulator.step()

        # Validate that the code really reached the end, and not stopped by a cycles limit
        assert self._emulator._cpu.pc == 0xbeef


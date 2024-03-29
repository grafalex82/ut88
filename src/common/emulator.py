import logging
from common.machine import Machine
from common.cpu import CPU

class Emulator:
    """
        Intel 8080 based machine emulator.

        This class is responsible to driving emulation process with the given machine and CPU. The Emulator
        provides possibility to run emulated CPU for a a single instruction, as well as for a number of cycles.
        The Emulator also provides possibility to hook to the emulated code execution by setting up breakpoints.
        Breakpoints allow running emulator side code when the emulated CPU reaches a certain instruction address.

        In order to speed up data loading into the computer, this emulator class provides a feature to load
        a tape data from disk directly to the emulater computer memory.
    """
    def __init__(self, machine):
        self._machine = machine
        self._cpu = CPU(self._machine)
        self._breakpoints = {}
        self._startaddr = 0x0000

    def set_start_addr(self, addr):
        self._startaddr = addr

    def add_breakpoint(self, addr, fn):
        if addr not in self._breakpoints:
            self._breakpoints[addr] = []    
        self._breakpoints[addr].append(fn)

    def _handle_breakpoints(self):
        # Run the breakpoint function if condition is met
        br_list = self._breakpoints.get(self._cpu._pc, [])
        for br in br_list:  
            br()

    def step(self):
        self._handle_breakpoints()
        self._cpu.step()

    def run(self, num_cycles=0):
        stop_at = self._cpu._cycles + num_cycles
        while num_cycles == 0 or self._cpu._cycles <= stop_at:
            self.step()

    def reset(self):
        self._machine.reset()
        self._cpu._pc = self._startaddr


    def load_memory(self, fname):
        if not fname:
            return
        
        with open(fname, "rb") as f:
            data = f.read()

        offset = 0      
        if fname.upper().endswith(".PKI") or fname.upper().endswith(".GAM"):
            offset += 1         # Skip the sync byte

        addr = (data[offset] << 8) | data[offset + 1]
        endaddr = (data[offset+2] << 8) | data[offset + 3]
        offset += 4
        
        while addr <= endaddr:
            self._machine.write_memory_byte(addr, data[offset])
            addr += 1
            offset += 1
        



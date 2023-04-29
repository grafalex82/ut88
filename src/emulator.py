import logging
from machine import Machine
from cpu import CPU

class Emulator:
    def __init__(self, machine):
        self._machine = machine
        self._cpu = CPU(self._machine)
        self._breakpoints = {}

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


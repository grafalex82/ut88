import logging
from machine import Machine
from cpu import CPU

class Emulator:
    def __init__(self, machine):
        self._machine = machine
        self._cpu = CPU(self._machine)

    def step(self):
        self._cpu.step()

    def run(self):
        while True:
            self._cpu.step()
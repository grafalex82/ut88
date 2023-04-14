import logging
from utils import *

logger = logging.getLogger('machine')

class MemoryMgr:
    def __init__(self):
        self._memories = []

    def add_memory(self, memory):
        startaddr = memory.get_start_addr()
        endaddr = memory.get_end_addr()
        self._memories.append((startaddr, endaddr, memory))

    def get_memory_for_addr(self, addr):
        for mem in self._memories:
            if addr >= mem[0] and addr <= mem[1]:
                return mem[2]
        return None


class Machine:
    def __init__(self):
        self._memories = MemoryMgr()

    def add_memory(self, memory):
        self._memories.add_memory(memory)

    def _get_memory(self, addr):
        mem = self._memories.get_memory_for_addr(addr)
        if not mem:
            raise MemoryError(f"No memory registered for address 0x{addr:04x}")
        return mem

    def read_memory_byte(self, addr):
        mem = self._get_memory(addr)
        return mem.read_byte(addr)

    def read_memory_word(self, addr):
        mem = self._get_memory(addr)
        return mem.read_word(addr)

    def write_memory_byte(self, addr, value):
        mem = self._get_memory(addr)
        mem.write_byte(addr, value)

    def write_memory_word(self, addr, value):
        mem = self._get_memory(addr)
        mem.write_word(addr, value)

    def push_stack(self, addr, value):
        mem = self._get_memory(addr)
        mem.push(addr, value)

    def pop_stack(self, addr):
        mem = self._get_memory(addr)
        return mem.pop(addr)

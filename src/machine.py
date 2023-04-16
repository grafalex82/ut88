import logging
from utils import *

logger = logging.getLogger('machine')

class MemoryMgr:
    def __init__(self):
        self._memories = []

    def add_memory(self, memory):
        startaddr, endaddr = memory.get_addr_space()
        self._memories.append((startaddr, endaddr, memory))

    def get_memory_for_addr(self, addr):
        for mem in self._memories:
            if addr >= mem[0] and addr <= mem[1]:
                return mem[2]
        return None


class Machine:
    def __init__(self):
        self._memories = MemoryMgr()
        self._io = {}

    def add_memory(self, memory):
        self._memories.add_memory(memory)

    def add_io(self, io):
        start, end = io.get_addr_space()
        for addr in range(start, end+1):
            self._io[addr] = io

    def _get_memory(self, addr):
        mem = self._memories.get_memory_for_addr(addr)
        if not mem:
            raise MemoryError(f"No memory registered for address 0x{addr:04x}")
        return mem

    def _get_io(self, addr):
        io = self._io.get(addr, None)
        if not io:
            raise IOError(f"No IO registered for address 0x{addr:02x}")
        return io
        

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

    def write_stack(self, addr, value):
        mem = self._get_memory(addr)
        mem.write_stack(addr, value)

    def read_stack(self, addr):
        mem = self._get_memory(addr)
        return mem.read_stack(addr)

    def read_io(self, addr):
        io = self._get_io(addr)
        return io.read_io(addr)
        
    def write_io(self, addr, value):
        io = self._get_io(addr)
        io.write_io(addr, value)

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
        self._cpu = None
        self._strict = False

    def set_strict_validation(self, strict = False):
        self._strict = strict

    def set_cpu(self, cpu):
        self._cpu = cpu

    def add_memory(self, memory):
        self._memories.add_memory(memory)

    def add_io(self, io):
        start, end = io.get_addr_space()
        for addr in range(start, end+1):
            self._io[addr] = io

    def _get_memory(self, addr):
        mem = self._memories.get_memory_for_addr(addr)
        if not mem:
            msg = f"No memory registered for address 0x{addr:04x}"
            if self._strict:
                raise MemoryError(msg)
            else:
                logger.debug(msg)
        return mem

    def _get_io(self, addr):
        io = self._io.get(addr, None)
        if not io:
            msg = f"No IO registered for address 0x{addr:02x}"
            if self._strict:
                raise IOError(msg)
            else:
                logger.debug(msg)
        return io
        
    def reset(self):
        # Only CPU is reset during the machine reset
        # Memory data will survive
        self._cpu.reset()

    def read_memory_byte(self, addr):
        mem = self._get_memory(addr)
        if not mem:
            return 0xff
        return mem.read_byte(addr)

    def read_memory_word(self, addr):
        mem = self._get_memory(addr)
        if not mem:
            return 0xffff
        return mem.read_word(addr)

    def write_memory_byte(self, addr, value):
        mem = self._get_memory(addr)
        if mem:
            mem.write_byte(addr, value)

    def write_memory_word(self, addr, value):
        mem = self._get_memory(addr)
        if mem:
            mem.write_word(addr, value)

    def write_stack(self, addr, value):
        mem = self._get_memory(addr)
        if mem:
            mem.write_stack(addr, value)

    def read_stack(self, addr):
        mem = self._get_memory(addr)
        if not mem:
            return 0xffff
        return mem.read_stack(addr)

    def read_io(self, addr):
        io = self._get_io(addr)
        if not io:
            return 0xff
        return io.read_io(addr)
        
    def write_io(self, addr, value):
        io = self._get_io(addr)
        if io:
            io.write_io(addr, value)

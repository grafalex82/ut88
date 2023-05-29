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

    def update(self):
        for mem in self._memories:
            mem[2].update()



class Machine:
    """
    Machine class emulates everything related to electrical connectivity within 
    the computer in a specific configuration. It handles all the relationships
    between the components, such as memories, I/O devices, and other devices
    not logically connected, but still a part of the system (e.g. a 1 second timer).
    
    """
    def __init__(self):
        self._memories = MemoryMgr()
        self._io = {}
        self._other = []
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

    def add_other_device(self, device):
        self._other.append(device)

    def update(self):
        """ 
        Updates the state of all devices in the system, allowing them to 
        act on a time-based manner
        """
        self._memories.update()

        for _, io in self._io.items():
            io.update()

        for dev in self._other:
            dev.update()

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

    def schedule_interrupt(self):
        # Typically the machine would have i8259 interrupt controller
        # which would expose to the data line a 3 byte CALL instruction.
        # UT-88 computer does not have an interrupt controller. Instead
        # it relies on data bus pull-up registers, that "generate" RST7
        # instruction (0xff opcode).
        self._cpu.schedule_interrupt([0xff])



class UT88Machine(Machine):
    """
    UT88Machine is a specialized Machine instance, that may connect quasi_disk to stack read/write
    lines. The selection between quasi disk and regular memory is done using special configuration
    register at port 0x40. Value 0xff written to port 0x40 enables regular RAM, values other than 
    0xff enable quasi disk operations.
    """
    def __init__(self):
        Machine.__init__(self)
        self._quasi_disk = None
        self._quasi_disk_enabled = False
    
    def set_quasi_disk(self, disk):
        self._quasi_disk = disk
        self.add_io(disk)

    def write_io(self, addr, value):
        # Non-ff values in the configuration port will enable quasi disk access on stack reads/write operations
        if addr == 0x40:
            self._quasi_disk_enabled = (value != 0xff)
    
        Machine.write_io(self, addr, value)

    def write_stack(self, addr, value):
        if self._quasi_disk_enabled:
            self._quasi_disk.write_stack(addr, value)
        else:
            Machine.write_stack(self, addr, value)

    def read_stack(self, addr):
        if self._quasi_disk_enabled:
            return self._quasi_disk.read_stack(addr)
        else:
            return Machine.read_stack(self, addr)

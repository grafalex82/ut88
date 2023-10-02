from utils import *

class IODevice:
    """
    IODevice class is a base class for all devices connected to the Machine via IO lines.
    Some devices are read-only, some devices are write-only. A derived class must reimplement
    read_io() and/or write_io() functions according to the provided functionality
    """
    def __init__(self, startaddr, endaddr):
        self._iostartaddr = startaddr
        self._ioendaddr = endaddr

    def get_addr_space(self):
        return self._iostartaddr, self._ioendaddr

    def validate_io_addr(self, addr):
        if addr < self._iostartaddr or addr > self._ioendaddr:
            raise IOError(f"Incorrect IO address {addr:x}")

    def read_io(self, addr):
        self.validate_io_addr(addr)
        raise IOError(f"Reading IO {addr:x} is not supported")

    def write_io(self, addr, value):
        self.validate_io_addr(addr)
        raise IOError(f"Writing IO {addr:x} is not supported")
    
    def update(self):
        pass



class MemoryDevice:
    """
    MemoryDevice class is a base class for all memory type devices connected to the
    Machine via memory read/write lines. The CPU will reach the memory device for
    fetching instructions, read and write data (except for stack operations, that
    are handled by StackDevice)

    The byte and word functions are typically used by CPU to read or write the data, while
    burst functions mimic DMA transfer.

    The actual device shall reimplement read* and/or write* functions.
    """
    def __init__(self, startaddr, endaddr):
        self._startaddr = startaddr
        self._endaddr = endaddr

    def get_addr_space(self):
        return self._startaddr, self._endaddr

    def validate_addr(self, addr):
        if addr < self._startaddr or addr > self._endaddr:
            raise MemoryError(f"Address 0x{addr:04x} is out of memory range 0x{self._startaddr:04x}-0x{self._endaddr:04x}")

    def read_byte(self, addr):
        self.validate_addr(addr)
        raise MemoryError(f"Reading address 0x{addr:04x} is not supported")

    def read_word(self, addr):
        self.validate_addr(addr)
        raise MemoryError(f"Reading address 0x{addr:04x} is not supported")

    def read_burst(self, addr, count):
        endaddr = addr + len(data) - 1
        self.validate_addr(addr)
        self.validate_addr(endaddr)
        raise MemoryError(f"Burst reading address range 0x{addr:04x}-0x{endaddr:04x} is not supported")

    def write_byte(self, addr, value):
        self.validate_addr(addr)
        raise MemoryError(f"Writing address 0x{addr:04x} is not supported")

    def write_word(self, addr, value):
        self.validate_addr(addr)
        raise MemoryError(f"Writing address 0x{addr:04x} is not supported")

    def write_burst(self, addr, data):
        endaddr = addr + len(data) - 1
        self.validate_addr(addr)
        self.validate_addr(endaddr)
        raise MemoryError(f"Burst writing address range 0x{addr:04x}-0x{endaddr:04x} is not supported")

    def update(self):
        pass


class StackDevice:
    """
    StackDevice class is a base class for all memory type devices connected to the
    Machine via memory read/write lines. The CPU will reach these devices via stack
    operations (PUSH and POP). Special handling of stack devices compared to regular
    memory device allows creating a device in a separate address space (e.g. Quasi disk).

    The actual device shall reimplement read_stack() and/or write_stack() functions.
    """
    def __init__(self, startaddr, endaddr):
        self._stackstartaddr = startaddr
        self._stackendaddr = endaddr

    def get_addr_space(self):
        return self._stackstartaddr, self._stackendaddr

    def validate_stack_addr(self, addr):
        if addr < self._stackstartaddr or addr > self._stackendaddr:
            raise MemoryError(f"Address 0x{addr:04x} is out of stack memory range 0x{self._stackstartaddr:04x}-0x{self._stackendaddr:04x}")

    def write_stack(self, ptr, value):
        self.validate_stack_addr(addr)
        raise MemoryError(f"Writing stack address 0x{addr:04x} is not supported")

    def read_stack(self, ptr):
        self.validate_stack_addr(addr)
        raise MemoryError(f"Reading stack address 0x{addr:04x} is not supported")

    def update(self):
        pass

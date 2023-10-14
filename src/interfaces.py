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
    def __init__(self, device, startaddr, endaddr=None):
        self._device = device
        self._startaddr = startaddr

        if endaddr:
            self._endaddr = endaddr
            device.set_size(endaddr - startaddr + 1)
        else:
            self._endaddr = startaddr + device.get_size() - 1

    def get_addr_space(self):
        return self._startaddr, self._endaddr

    def validate_addr(self, addr):
        if addr < self._startaddr or addr > self._endaddr:
            raise MemoryError(f"Address 0x{addr:04x} is out of memory range 0x{self._startaddr:04x}-0x{self._endaddr:04x}")

    def read_byte(self, addr):
        self.validate_addr(addr)
        if not hasattr(self._device, "read_byte"):
            raise MemoryError(f"Reading byte at address 0x{addr:04x} is not supported")
        return self._device.read_byte(addr - self._startaddr)

    def read_word(self, addr):
        self.validate_addr(addr)
        if not hasattr(self._device, "read_word"):
            raise MemoryError(f"Reading word at address 0x{addr:04x} is not supported")
        return self._device.read_word(addr - self._startaddr)

    def read_stack(self, addr):
        self.validate_addr(addr)
        if not hasattr(self._device, "read_stack"):
            raise MemoryError(f"Reading stack address 0x{addr:04x} is not supported")
        return self._device.read_stack(addr - self._startaddr)

    def read_burst(self, addr, count):
        endaddr = addr + count - 1
        self.validate_addr(addr)
        self.validate_addr(endaddr)
        if not hasattr(self._device, "read_burst"):
            raise MemoryError(f"Burst reading address range 0x{addr:04x}-0x{endaddr:04x} is not supported")
        return self._device.read_burst(addr - self._startaddr, count)

    def write_byte(self, addr, value):
        self.validate_addr(addr)
        if not hasattr(self._device, "write_byte"):
            raise MemoryError(f"Writing byte ataddress 0x{addr:04x} is not supported")
        self._device.write_byte(addr - self._startaddr, value)

    def write_word(self, addr, value):
        self.validate_addr(addr)
        if not hasattr(self._device, "write_word"):
            raise MemoryError(f"Writing word at address 0x{addr:04x} is not supported")
        self._device.write_word(addr - self._startaddr, value)

    def write_stack(self, addr, value):
        self.validate_addr(addr)
        if not hasattr(self._device, "write_stack"):
            raise MemoryError(f"Writing stack address 0x{addr:04x} is not supported")
        self._device.write_stack(addr - self._startaddr, value)

    def write_burst(self, addr, data):
        endaddr = addr + len(data) - 1
        self.validate_addr(addr)
        self.validate_addr(endaddr)
        if not hasattr(self._device, "write_burst"):
            raise MemoryError(f"Burst writing address range 0x{addr:04x}-0x{endaddr:04x} is not supported")
        self._device.write_burst(addr - self._startaddr, data)

    def update(self):
        pass


class StackDevice:
    pass
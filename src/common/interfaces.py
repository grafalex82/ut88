from common.utils import *

"""
    Depending on a particular HW configuration, same peripheral may be connected to a memory
    data lines, or as an I/O device. Thus UT-88 uses peripheral devices connected through the
    I/O lines, while a similar peripheral in Radio-86RK would be connected as a memory mapped device.
    Same device in the Radio-86RK family may be connected to different addresses. Thus, the
    particular address is not a peripheral attribute, but rather configuration option.

    The 2 classes in this module (IODevice and MemoryDevice) are the adapters responsible to
    assign a peripheral with a particular I/O or memory address. The peripheral class is not 
    obligated to implement a specific interface, but per duck-typing principle shall expose one
    or more of the following functions:
    - read_byte
    - read_word
    - read_stack
    - read_burst
    - write_byte
    - write_word
    - write_stack
    - write_burst

    Byte operations are typically implemented by a peripheral devices, while other operation types
    (word, stack, burst) are mostly related to memory-type devices.
"""

class IODevice:
    """
        IODevice class binds a device with a particular I/O port. This class is responsible to
        translate I/O port read and write requests to the provided device object. The device class
        must expose read_byte() and/or write_byte() function.
    """
    def __init__(self, device, startaddr, endaddr=None):
        self._device = device
        self._iostartaddr = startaddr

        if endaddr:
            self._ioendaddr = endaddr
            device.set_size(endaddr - startaddr + 1)
        elif hasattr(device, "get_size"):
            self._ioendaddr = startaddr + device.get_size() - 1
        else:
            self._ioendaddr = startaddr


    def get_addr_range(self):
        return self._iostartaddr, self._ioendaddr


    def validate_io_addr(self, addr):
        if addr < self._iostartaddr or addr > self._ioendaddr:
            raise IOError(f"Incorrect IO address {addr:x}")


    def read_io(self, addr):
        self.validate_io_addr(addr)
        return self._device.read_byte(addr - self._iostartaddr)


    def write_io(self, addr, value):
        self.validate_io_addr(addr)
        print(f"Writing an IO device, addr={addr:02x}, value={value:02x}")
        self._device.write_byte(addr - self._iostartaddr, value)


    def update(self):
        pass



class MemoryDevice:
    """
        MemoryDevice class binds the peripheral with a particular memory address (or the
        address range). This class is responsible to translate memory address read and write
        requests to the provided device object. 
        
        Depending on the device type, it exposes one or more read/write functions:
        - read_byte
        - read_word
        - read_stack
        - read_burst
        - write_byte
        - write_word
        - write_stack
        - write_burst

        Typically all memory type devices connected to the Machine via memory read/write lines. 
        The CPU will reach the memory device for fetching instructions, read and write data (incl
        for stack operations). The byte and word functions are typically used by CPU to read or
        write the data, while burst functions mimic DMA transfer.
    """
    def __init__(self, device, startaddr, endaddr=None):
        self._device = device
        self._startaddr = startaddr

        if endaddr:
            self._endaddr = endaddr
            device.set_size(endaddr - startaddr + 1)
        else:
            self._endaddr = startaddr + device.get_size() - 1


    def get_addr_range(self):
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

import os

from interfaces import *

class QuasiDisk(IODevice, StackDevice):
    def __init__(self, fname):
        IODevice.__init__(self, 0x40, 0x40)
        StackDevice.__init__(self, 0x0000, 0xffff)

        self._page = None
        self._fname = fname
        self.reload()

    @property
    def filename(self):
        return self._fname

    def write_io(self, addr, value):
        self.validate_io_addr(addr)

        match value:
            case 0xff:
                self._page = None
            case 0xfe:
                self._page = 0
            case 0xfd:
                self._page = 1
            case 0xfb:
                self._page = 2
            case 0xf7:
                self._page = 3
            case _:
                raise IOError(f"Incorrect quasi disk page selection: {value:02x}")


    def write_stack(self, ptr, value):
        self.validate_stack_addr(ptr)

        if self._page == None:
            raise IOError(f"Quasi disk page was not selected")

        page_offset = 64*1024*self._page
        self._data[page_offset + ptr + 1] = (value >> 8) & 0xff
        self._data[page_offset + ptr] = value & 0xff
        
        self._changed = True


    def read_stack(self, ptr):
        self.validate_stack_addr(ptr)

        if self._page == None:
            raise IOError(f"Quasi disk page was not selected")
        
        page_offset = 64*1024*self._page
        return (self._data[page_offset + ptr + 1] << 8) | self._data[page_offset + ptr]


    def reload(self):
        self._changed = False

        if os.path.exists(self._fname):
            with open(self._fname, "rb") as f:
                self._data = bytearray(f.read())
                assert len(self._data) == 256*1024
        else:
            self._data = bytearray(256*1024)

    
    def flush(self):
        if not self._changed:
            return
        
        with open(self._fname, "w+b") as f:
            f.write(self._data)
        
        self._changed = False


    def update(self):
        self.flush()
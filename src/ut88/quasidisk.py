import os

from common.utils import *

class QuasiDisk:
    """
        Quasi Disk emulator
        
        This class emulates the UT-88 quasi disk. Original quasi disk is based on 256k RAM, organized in
        four 64k pages. The read and write access to the selected page data is performed using stack read
        and write operations. 

        RAM page selection is performed by writing special values to the 0x40 port. In this particular
        implementation page selection is performed using select_page() function.

        Although original implementation does not offer a long term storage, this particular implementation
        dumps the content of the RAM disk to a file, and restore the content on startup. There is a possibility
        to flush the RAM contents to file in runtime, as well as reloading the data from file. This is used
        for testing.
    """


    def __init__(self, fname):
        self._page = None
        self._fname = fname
        self.reload()

    @property
    def filename(self):
        return self._fname

    def select_page(self, value):
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


    def write_stack(self, addr, value):
        if self._page == None:
            raise IOError(f"Quasi disk page was not selected")

        page_offset = 64*1024*self._page
        self._data[page_offset + addr + 1] = (value >> 8) & 0xff
        self._data[page_offset + addr] = value & 0xff
        
        self._changed = True


    def read_stack(self, addr):
        if self._page == None:
            raise IOError(f"Quasi disk page was not selected")
        
        page_offset = 64*1024*self._page
        return (self._data[page_offset + addr + 1] << 8) | self._data[page_offset + addr]


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
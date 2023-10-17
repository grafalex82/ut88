from machine import Machine

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

    def write_io(self, addr, value):
        # Non-ff values in the configuration port will enable quasi disk access on stack reads/write operations
        if addr == 0x40:
            self._quasi_disk_enabled = (value != 0xff)
            self._quasi_disk.select_page(value)
        else:
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

    def update(self):
        Machine.update(self)

        if self._quasi_disk:
            self._quasi_disk.update()

from common.utils import *

PPI_PORT_A      = 0
PPI_PORT_B      = 1
PPI_PORT_C      = 2
PPI_PORT_CFG    = 3

class PPI:
    """
        Intel 8255 Parallel Peripheral Interface

        This class emulates behavior of the Intel 8255 chip, and supports:
        - Configuring chip ports for input or output (Port A, Port B, upper and lower parts of Port C)
        - sending data through output ports, and receiving data through input ports
        - Ports A, B, and C support byte-wide data transfer
        - Port C supports transferring a single bit of data

        The configuration and usage workflow fully matches the original chip. Refer to the chip documentation
        for modes and configuration bits description.
        
        Only simple I/O mode is supported. Strobbed I/O is not emulated. 

        The class is supposed to be used with handler functions that are called to read or write data on
        the selected port. This allows building simple 'schematics' based on the physical connection of the
        signal lines.
    """



    def __init__(self):
        self._portA_mode_input = True
        self._portB_mode_input = True
        self._portCu_mode_input = True
        self._portCl_mode_input = True

        self._portA_handler = None
        self._portB_handler = None
        self._portC_handler = None
        self._portC_value = 0
        self._portC_bit_handlers = [None for _ in range(8)]


    def get_size(self):
        return 4    # The chip offers 4 registers - 3 ports, and configuration register


    def set_portA_handler(self, func):
        self._portA_handler = func

    
    def set_portB_handler(self, func):
        self._portB_handler = func


    def set_portC_handler(self, func):
        self._portC_handler = func


    def set_portC_bit_handler(self, bit, func):
        self._portC_bit_handlers[bit] = func

    
    def _configure(self, mode):
        assert is_bit_set(mode, 7)
        assert not is_bit_set(mode, 6) and not is_bit_set(mode, 5)
        assert not is_bit_set(mode, 2)

        self._portA_mode_input = is_bit_set(mode, 4)
        self._portCu_mode_input = is_bit_set(mode, 3)
        self._portB_mode_input = is_bit_set(mode, 1)
        self._portCl_mode_input = is_bit_set(mode, 0)


    def _handle_bsr(self, value):
        assert not is_bit_set(value, 7)

        bit_number = (value >> 1) & 0x07
        bit_value = is_bit_set(value, 0)

        if (bit_number < 4 and not self._portCl_mode_input) or (bit_number >= 4 and not self._portCu_mode_input):
            # Update the port value variable
            self._portC_value = set_bit_value(self._portC_value, bit_number, bit_value)

            # Call handler if registered
            if self._portC_bit_handlers[bit_number]:
                self._portC_bit_handlers[bit_number](bit_value)

            # Output port C as a whole as well
            self._handle_portC_output(self._portC_value)


    def _handle_portC_output(self, value):
        # Try to output portC value as a whole (if corresponding handler is set)
        if self._portC_handler:
            if self._portCu_mode_input: # Clear upper nibble if this part of the Port C is not for output
                value &= 0x0f
            if self._portCl_mode_input: # Clear lower nibble if this part of the Port C is not for output
                value &= 0xf0

            if not self._portCu_mode_input or not self._portCl_mode_input:
                self._portC_handler(value)


    def _handle_portC_bits_output(self, value):
        # Call bit handlers separately bit by bit
        if not self._portCl_mode_input:
            for bit_number in range(4):
                if self._portC_bit_handlers[bit_number]:
                    self._portC_bit_handlers[bit_number](is_bit_set(value, bit_number))

        if not self._portCu_mode_input:
            for bit_number in range(4, 8):
                if self._portC_bit_handlers[bit_number]:
                    self._portC_bit_handlers[bit_number](is_bit_set(value, bit_number))


    def _handle_portC_input(self):
        # Try to read portC value as a whole (if corresponding handler is set)
        if self._portC_handler:
            value = self._portC_handler()

            if not self._portCu_mode_input: # Clear upper nibble if this part of the Port C is not for input
                value &= 0x0f
            if not self._portCl_mode_input: # Clear lower nibble if this part of the Port C is not for input
                value &= 0xf0

            return value
        
        # Try to read portC bit by bit
        value = 0
        if self._portCl_mode_input:
            for bit_number in range(4):
                if self._portC_bit_handlers[bit_number]:
                    value = set_bit_value(value, bit_number, self._portC_bit_handlers[bit_number]())

        if self._portCu_mode_input:
            for bit_number in range(4, 8):
                if self._portC_bit_handlers[bit_number]:
                    value = set_bit_value(value, bit_number, self._portC_bit_handlers[bit_number]())

        return value


    def read_byte(self, offset):
        if offset == PPI_PORT_A and self._portA_mode_input:
            return self._portA_handler()
        if offset == PPI_PORT_B and self._portB_mode_input:
            return self._portB_handler()
        if offset == PPI_PORT_C:
            return self._handle_portC_input()
        if offset == PPI_PORT_CFG:
            return 0
        else:
            raise MemoryError("PPI port {offset} is not configured for reading")


    def write_byte(self, offset, value):
        if offset == PPI_PORT_A and not self._portA_mode_input:
            self._portA_handler(value)

        elif offset == PPI_PORT_B and not self._portB_mode_input:
            self._portB_handler(value)

        elif offset == PPI_PORT_C:
            self._handle_portC_output(value)
            self._handle_portC_bits_output(value)

        elif offset == PPI_PORT_CFG:
            if is_bit_set(value, 7):    # If MSB is set - this is configuration word
                self._configure(value)
            else:                       # If MSB is not set - this is BSR mode request
                self._handle_bsr(value)
        else:
            raise MemoryError("PPI port {offset} is not configured for writing")


from keyboard import Keyboard
from interfaces import *

class RK86KeyboardAdapter(MemoryDevice):
    def __init__(self):
        MemoryDevice.__init__(self, 0x8000, 0x8003)

        # Create and configure UT-88 Keyboard
        self._keyboard = Keyboard()
        self._keyboard.configure(0x8b)


    def read_byte(self, addr):
        self.validate_addr(addr)

        # Reading is allowed only for ports B and C
        match addr:
            case 0x8001:    # Port B
                return set_bit(self._keyboard.read_io(0x06), 7)
            case 0x8002:    # Port C
                return self._keyboard.read_io(0x05)
            
        raise MemoryError(f"Reading address 0x{addr:04x} is not supported")


    def write_byte(self, addr, value):
        self.validate_addr(addr)

        match addr:
            case 0x8000:    # Port A
                return self._keyboard.write_io(0x07, value)

            case 0x8002:    # Port C
                # TODO: LED connected to C3 pin shows status of the Rus/Lat switch
                # Emulate it at some point
                return

            case 0x8003:    # Control port
                if value & 0x80:
                    # Unlike UT-88 keyboard, the 86RK one uses upper port C for reading mod keys, while
                    # lower part of the Port C is configured for output. Particularly Rus/Lat LED is connected
                    # to the C3 pin
                    assert value == 0x8a
                else:
                    # TODO: handle setting/resetting bits using BSR mode
                    pass

                # The only mode supported by the UT-88 keyboard is 0x8b (Port A - output, Ports B and C - input)
                return self._keyboard.write_io(0x04, 0x8b)  

        raise MemoryError(f"Writing address 0x{addr:04x} is not supported")


    def handle_key_event(self, event):
        # Keyboard events are routed to the UT-88 keyboard for handling
        return self._keyboard.handle_key_event(event)

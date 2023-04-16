import logging
from emulator import Emulator
from machine import Machine
from cpu import CPU
from ram import RAM
from rom import ROM
from lcd import LCD
from hexkbd import HexKeyboard

def enable_debug_logging():
    logging.disable(logging.NOTSET)

def disable_debug_logging():
    logging.disable(logging.DEBUG)

def main():
    logging.basicConfig(level=logging.DEBUG)

    # Create a UT-88 machine in basic configuration
    machine = Machine()
    machine.add_memory(RAM(0xC000, 0xC3ff))
    machine.add_memory(ROM("../resources/Monitor0.bin", 0x0000))
    machine.add_memory(LCD())
    kbd = HexKeyboard()
    kbd.press_key("3")  # Test LCD command
    machine.add_io(kbd)

    emulator = Emulator(machine)
    emulator.add_breakpoint(0x0018, disable_debug_logging)  # Suppress logging for RST3 (wait 1s)
    emulator.add_breakpoint(0x0018, lambda: print("RST 3: Wait 1s"))
    emulator.add_breakpoint(0x005e, enable_debug_logging)
    emulator.add_breakpoint(0x0021, disable_debug_logging)  # Suppress logging for RST4 (wait for a button)
    emulator.add_breakpoint(0x0021, lambda: print("RST 4: Wait a button"))
    emulator.add_breakpoint(0x006d, enable_debug_logging)
    emulator.run()

if __name__ == '__main__':
    main()

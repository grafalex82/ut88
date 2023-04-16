import logging
from machine import Machine
from cpu import CPU
from ram import RAM
from rom import ROM
from lcd import LCD
from hexkbd import HexKeyboard

def main():
    logging.basicConfig(level=logging.DEBUG)

    # Create a UT-88 machine in basic configuration
    machine = Machine()
    machine.add_memory(RAM(0xC000, 0xC3ff))
    machine.add_memory(ROM("../resources/Monitor0.bin", 0x0000))
    machine.add_memory(LCD())
    kbd = HexKeyboard()
    machine.add_io(kbd)
    cpu = CPU(machine) 

    while True:
        cpu.step()

if __name__ == '__main__':
    main()

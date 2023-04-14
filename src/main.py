from machine import Machine
from cpu import CPU
from ram import RAM
from rom import ROM

def main():
    # Create a UT-88 machine in basic configuration
    machine = Machine()
    machine.add_memory(RAM(0xC000, 0xC3ff))
    machine.add_memory(ROM("../resources/Monitor0.bin", 0x0000))
    cpu = CPU(machine) 

    while True:
        cpu.step()

if __name__ == '__main__':
    main()

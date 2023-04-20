import logging
import pygame

from emulator import Emulator
from machine import Machine
from ram import RAM
from rom import ROM
from lcd import LCD
from hexkbd import HexKeyboard
from timer import Timer
from tape import TapeRecorder

def enable_debug_logging():
    logging.disable(logging.NOTSET)

def disable_debug_logging():
    logging.disable(logging.DEBUG)

def main():
    pygame.init()
    screen = pygame.display.set_mode((450, 94))
    pygame.display.set_caption("UT-88 Emulator")
    clock = pygame.time.Clock()

    logging.basicConfig(level=logging.DEBUG)

    # Create a UT-88 machine in basic configuration
    machine = Machine()
    machine.add_memory(RAM(0xC000, 0xC3ff))
    machine.add_memory(ROM("../resources/Monitor0.bin", 0x0000))
    lcd = LCD()
    machine.add_memory(lcd)
    kbd = HexKeyboard()
    machine.add_io(kbd)
    timer = Timer(machine)
    machine.add_other_device(timer)
    recorder = TapeRecorder()
    machine.add_io(recorder)

    emulator = Emulator(machine)
    emulator.add_breakpoint(0x0018, disable_debug_logging)  # Suppress logging for RST3 (wait 1s)
    emulator.add_breakpoint(0x0018, lambda: print("RST 3: Wait 1s"))
    emulator.add_breakpoint(0x0018, lambda: print(f"cycles={emulator._cpu._cycles}"))
    emulator.add_breakpoint(0x005e, lambda: print(f"cycles={emulator._cpu._cycles}"))
    emulator.add_breakpoint(0x005e, enable_debug_logging)
    emulator.add_breakpoint(0x0021, disable_debug_logging)  # Suppress logging for RST4 (wait for a button)
    emulator.add_breakpoint(0x0021, lambda: print("RST 4: Wait a button"))
    emulator.add_breakpoint(0x006d, enable_debug_logging)
    emulator.add_breakpoint(0x0008, disable_debug_logging)  # Suppress logging for RST1 (output a byte)
    emulator.add_breakpoint(0x0008, lambda: print("RST 1: Output a byte"))
    emulator.add_breakpoint(0x0120, enable_debug_logging)
    emulator.add_breakpoint(0x01bf, lambda: recorder.dump("test.bin"))
    emulator.add_breakpoint(0x0128, lambda: print("Read a byte from tape"))
    emulator.add_breakpoint(0x016e, disable_debug_logging)  # Suppress bit reading delay function
    emulator.add_breakpoint(0x0174, enable_debug_logging)
    emulator.add_breakpoint(0x016d, lambda: print(f"Received byte - {emulator._cpu._a:02x}"))
    
    while True:
        screen.fill(pygame.Color('black'))
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                exit()
        
        emulator.run(50000)

        if pygame.key.get_pressed()[pygame.K_ESCAPE]:
            emulator.reset()

        machine.update()
        lcd.update_screen(screen)
        kbd.update()
        pygame.display.flip()
        clock.tick(60)
        pygame.display.set_caption(f"UT-88 Emulator (FPS={clock.get_fps()})")

    #emulator.run()

if __name__ == '__main__':
    main()
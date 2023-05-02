import os
import logging
import pygame
from tkinter import filedialog

from emulator import Emulator
from machine import Machine
from ram import RAM
from rom import ROM
from lcd import LCD
from hexkbd import HexKeyboard
from timer import Timer
from tape import TapeRecorder
from utils import NestedLogger

resources_dir = os.path.join(os.path.dirname(__file__), "../resources")

class Legend:
    def __init__(self):
        text = """
Keys:
  0-9, A-F  - hexadecimal buttons
  Backspace - step back button
  Esc       - CPU Reset
  L         - Load a tape file
  S         - Save a tape file
        """
        green = (0, 255, 0)
        #font = pygame.font.Font(pygame.font.get_default_font(), 16)
        font = pygame.font.SysFont('Courier New', 24)
        self._text = font.render(text, True, green)
        self._rect = self._text.get_rect().move(0, 80])

    def update(self, screen):
        screen.blit(self._text, self._rect)


def enable_debug_logging():
    logging.disable(logging.NOTSET)

def disable_debug_logging():
    logging.disable(logging.DEBUG)


def main():
    pygame.init()
    screen = pygame.display.set_mode((450, 294))
    pygame.display.set_caption("UT-88 Emulator")
    clock = pygame.time.Clock()

    legend = Legend()

    logging.basicConfig(level=logging.DEBUG)

    # Create a UT-88 machine in basic configuration
    machine = Machine()
    machine.add_memory(RAM(0xC000, 0xC3ff))
    machine.add_memory(ROM(f"{resources_dir}/Monitor0.bin", 0x0000))
    machine.add_memory(ROM(f"{resources_dir}/calculator.bin", 0x0800))
    lcd = LCD()
    machine.add_memory(lcd)
    kbd = HexKeyboard()
    machine.add_io(kbd)
    timer = Timer(machine)
    machine.add_other_device(timer)
    recorder = TapeRecorder()
    machine.add_io(recorder)

    emulator = Emulator(machine)

    nl = NestedLogger()

    emulator.add_breakpoint(0x0000, lambda: nl.reset())

    emulator.add_breakpoint(0x0008, lambda: nl.enter("RST 1: Out byte"))
    emulator.add_breakpoint(0x0120, lambda: nl.exit())
    emulator.add_breakpoint(0x0018, lambda: nl.enter("RST 3: Wait 1s"))
    emulator.add_breakpoint(0x005e, lambda: nl.exit())
    emulator.add_breakpoint(0x0021, lambda: nl.enter("RST 4: Wait a button"))
    emulator.add_breakpoint(0x006d, lambda: nl.exit())

    emulator.add_breakpoint(0x0a92, lambda: nl.enter("STORE A-B-C to [HL]"))
    emulator.add_breakpoint(0x0a97, lambda: nl.exit())
    emulator.add_breakpoint(0x0a8c, lambda: nl.enter("LOAD [HL] to A-B-C"))
    emulator.add_breakpoint(0x0a91, lambda: nl.exit())
    emulator.add_breakpoint(0x0b08, lambda: nl.enter("POWER"))
    emulator.add_breakpoint(0x0b6a, lambda: nl.exit())
    emulator.add_breakpoint(0x0987, lambda: nl.enter("ADD"))
    emulator.add_breakpoint(0x0993, lambda: nl.exit())
    emulator.add_breakpoint(0x0a6f, lambda: nl.enter("DIV"))
    emulator.add_breakpoint(0x0a8b, lambda: nl.exit())
    emulator.add_breakpoint(0x09ec, lambda: nl.enter("MULT"))
    emulator.add_breakpoint(0x09f8, lambda: nl.exit())

    while True:
        screen.fill(pygame.Color('black'))
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                exit()
        
        emulator.run(50000)

        if pygame.key.get_pressed()[pygame.K_ESCAPE]:
            emulator.reset()
        if pygame.key.get_pressed()[pygame.K_l]:
            filename = filedialog.askopenfilename(filetypes=(("Tape files", "*.tape"), ("All files", "*.*")))
            recorder.load_from_file(filename)
        if pygame.key.get_pressed()[pygame.K_s]:
            filename = filedialog.asksaveasfilename(filetypes=(("Tape files", "*.tape"), ("All files", "*.*")),
                                                    defaultextension="tape")
            recorder.dump_to_file(filename)

        machine.update()
        lcd.update_screen(screen)
        legend.update(screen)
        kbd.update()
        pygame.display.flip()
        clock.tick(60)
        pygame.display.set_caption(f"UT-88 Emulator (FPS={clock.get_fps()})")


if __name__ == '__main__':
    main()

import sys
import pygame

sys.path.append('../misc')
sys.path.append('../src')

from machine import Machine
from emulator import Emulator
from keyboard import Keyboard

class EmulatedInstance:
    def __init__(self):
        self._machine = self._create_machine()
        self._emulator = self._create_emulator()

        self._emulator._cpu.enable_registers_logging(True)


    def _create_machine(self):
        return Machine()


    def _create_emulator(self):
        return Emulator(self._machine)


    @property
    def cpu(self):
        return self._emulator._cpu


    @property
    def emulator(self):
        return self._emulator


    def set_byte(self, addr, value):
        self._machine.write_memory_byte(addr, value)


    def set_word(self, addr, value):
        self._machine.write_memory_word(addr, value)


    def get_byte(self, addr):
        value = self._machine.read_memory_byte(addr)
        return value


    def get_word(self, addr):
        value = self._machine.read_memory_word(addr)
        return value

    
    def run_function(self, addr):
        # Put the breakpoint to the top of the stack
        # When a calculator function will return, it will get to the 0xbeef address
        self._emulator._cpu.sp = self._get_sp()
        self._emulator._machine.write_memory_word(self._get_sp(), 0xbeef) # breakpoint return address

        # Will execute function starting from the given address
        self._emulator._cpu.pc = addr

        # Run the requested function, until it returns to 0xbeef
        # Set the counter limit to avoid infinite loop
        while self._emulator._cpu.pc != 0xbeef and self._emulator._cpu._cycles < 100000000:
            self._emulator.step()

        # Validate that the code really reached the end, and not stopped by a cycles limit
        assert self._emulator._cpu.pc == 0xbeef



class EmulatedInstanceWithKeyboard(EmulatedInstance):
    def __init__(self):
        EmulatedInstance.__init__(self)

        self._keyboard = Keyboard()
        self._machine.add_io(self._keyboard)


    @property
    def keyboard(self):
        return self._keyboard

    """
        Emulate key press sequence.

        The function emulates a sequence of key presses. Special breakpoints are installed
        via _install_keybord_generator() function call. The breakpoint when triggered pulls
        next key from the generator.

        The following types of chars are supported in the sequence:
        - Normal chars in 0x20-0x7f range
        - Char sequence ^-<symb> (where symb is in 0x41-0x5f range) will generate a control code in
          0x01-0x1f range respectively. Subsequent keyboard scanning functions may detect that Ctrl 
          char was pressed
        - Special chars in 0x00-0x1f range are emulated as follows:
            - \n (0x0a) and \r (0x0d) - both emulate return key (resulting scan code will be 0x0d)
            - 0x0c      - home hey
            - 0x1f      - clear screen key
            - 0x08      - left arrow
            - 0x18      - right arrow
            - 0x19      - up arrow
            - 0x1a      - down arrow
    """
    def emulate_key_sequence(self, sequence):
        def generator(kbd, sequence):
            # Emulate next key in the sqeuence
            ctrl_key = False
            for ch in sequence:
                chd = ord(ch)

                # Ctrl-<symbol> will generate just one output code in 0x01-0x1f range
                if ch == '^':   # Perhaps it would be impossible to emulate '^', but that is ok for tests
                    ctrl_key = True
                    continue

                if ch == '\r' or ch == '\n':
                    print(f"Emulating Return")
                    kbd.emulate_special_key_press(pygame.K_RETURN)
                elif ch == '\x0c':
                    print(f"Emulating Home")
                    kbd.emulate_special_key_press(pygame.K_HOME)
                elif ch == '\x1f':
                    print(f"Emulating Clear Screen")
                    kbd.emulate_special_key_press(pygame.K_DELETE)
                elif ch == '\x08':
                    print(f"Emulating Left")
                    kbd.emulate_special_key_press(pygame.K_LEFT)
                elif ch == '\x18':
                    print(f"Emulating Right")
                    kbd.emulate_special_key_press(pygame.K_RIGHT)
                elif ch == '\x19':
                    print(f"Emulating Up")
                    kbd.emulate_special_key_press(pygame.K_UP)
                elif ch == '\x1a':
                    print(f"Emulating Down")
                    kbd.emulate_special_key_press(pygame.K_DOWN)
                elif ctrl_key and (chd >= 0x41 and chd <= 0x5f or chd == 0x20):
                    print(f"Emulating Ctrl-{ch}")
                    kbd.emulate_ctrl_key_press(ch)
                else:
                    print(f"Emulating '{ch}'")
                    kbd.emulate_key_press(ch)

                ctrl_key = False
                yield

            # Further calls of this generator will produce keyboard release
            while True:
                print(f"Emulating no press")
                kbd.emulate_key_press(None)
                yield

        g = generator(self.keyboard, sequence)
        self._install_keybord_generator(g)

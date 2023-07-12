import sys

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


    def emulate_key_sequence(self, sequence):
        def generator(cpm, sequence):
            # Emulate next key in the sqeuence
            for ch in sequence:
                if ord(ch) < 0x20:
                    print(f"Emulating Ctrl-{chr(ord(ch)+0x40)}")
                    cpm._keyboard.emulate_ctrl_key_press(ord(ch))
                else:
                    print(f"Emulating {ch}")
                    cpm._keyboard.emulate_key_press(ch)
                yield

            # Further calls of this generator will produce keyboard release
            while True:
                print(f"Emulating no press")
                cpm._keyboard.emulate_key_press(None)
                yield

        g = generator(self, sequence)
        self._install_keybord_generator(g)

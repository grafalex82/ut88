import logging

logger = logging.getLogger('cpu')

class CPU:
    def __init__(self, machine):
        self._machine = machine

        self._pc = 0
        self._sp = 0

        # Registers
        self._a = 0  # Accumulator
        self._b = 0
        self._c = 0
        self._d = 0
        self._e = 0
        self._h = 0
        self._l = 0
        self._bc = 0
        self._de = 0
        self._hl = 0

        # Flags
        self._sign = False
        self._zero = False
        self._half_carry = False
        self._parity = False  # odd or even
        self._carry = False

        # Instructions and execution
        self._cycles = 0
        self._current_inst = 0  # current instruction
        self._instructions = [0] * 0x100
    

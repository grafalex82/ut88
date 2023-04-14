import logging

logger = logging.getLogger('cpu')

class CPU:
    def __init__(self, machine):
        self._machine = machine

        self.reset()

        # Instructions and execution
        self._cycles = 0
        self._current_inst = 0  # current instruction
        self._instructions = [0] * 0x100
        self.init_instruction_table();

    def reset(self):
        """
        Resets registers and flags

        :return:
        """
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

        # Flags
        self._sign = False
        self._zero = False
        self._half_carry = False
        self._parity = False  # odd or even
        self._carry = False

    def step(self):
        """
        Executes an instruction and updates processor state

        :return:
        """
        self._current_inst = self._fetch_next_byte()
        instruction = self._instructions[self._current_inst]
        if instruction is not None:
            instruction()
        else:
            raise InvalidInstruction(f"Incorrect OPCODE: {self._current_inst:02x}")

    def _fetch_next_byte(self):
        # Read next byte
        data = self._machine.read_memory_byte(self._pc)
        self._pc += 1
        return data


    def _log_instruction(self, mnemonic):
        logger.debug(f'{self._current_inst:02x}         {mnemonic}')


    def _nop(self):
        """
        Do nothing

        :return:
        """
        self._log_instruction("NOP")
        self._cycles += 4
        

    def init_instruction_table(self):
        self._instructions[0x00] = self._nop


import logging
from utils import *

logger = logging.getLogger('cpu')

class CPU:
    def __init__(self, machine):
        self._machine = machine

        self.reset()

        # Instructions and execution
        self._cycles = 0
        self._current_inst = 0  # current instruction
        self._instructions = [None] * 0x100
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
            raise InvalidInstruction(f"Incorrect OPCODE 0x{self._current_inst:02x} (at addr 0x{(self._pc - 1):04x})")


    def _fetch_next_byte(self):
        data = self._machine.read_memory_byte(self._pc)
        self._pc += 1
        return data


    def _fetch_next_word(self):
        data = self._machine.read_memory_word(self._pc)
        self._pc += 2
        return data

    def _set_register_pair(self, reg_pair, value):
        h = value >> 8
        l = value & 0xff

        if reg_pair == 0:
            self._b = value >> 8
            self._c = value & 0xff
        if reg_pair == 1:
            self._d = value >> 8
            self._e = value & 0xff
        if reg_pair == 2:
            self._h = value >> 8
            self._l = value & 0xff
        if reg_pair == 3:
            self._sp = value

    def _reg_pair_symb(self, reg_pair):
        if reg_pair == 0:
            return "BC"
        if reg_pair == 1:
            return "DE"
        if reg_pair == 2:
            return "HL"
        if reg_pair == 3:
            return "SP"


    def _log_1b_instruction(self, mnemonic):
        logger.debug(f' {self._current_inst:02x}         {mnemonic}')


    def _log_3b_instruction(self, value, mnemonic):
        l = value & 0xff
        h = value >> 8
        logger.debug(f' {self._current_inst:02x} {l:02x} {h:02x}   {mnemonic}')

    def _nop(self):
        """
        Do nothing

        :return:
        """
        self._log_1b_instruction("NOP")
        self._cycles += 4
        

    def _lxi(self):
        """ Load register pair immediate """
        reg_pair = (self._current_inst & 0x30) >> 4
        value = self._fetch_next_word()
        self._set_register_pair(reg_pair, value)

        self._log_3b_instruction(value, f"LXI {self._reg_pair_symb(reg_pair)}, 0x{value:04x}")
        self._cycles += 10


    def init_instruction_table(self):
        self._instructions[0x00] = self._nop
        self._instructions[0x01] = self._lxi
        self._instructions[0x02] = None
        self._instructions[0x03] = None
        self._instructions[0x04] = None
        self._instructions[0x05] = None
        self._instructions[0x06] = None
        self._instructions[0x07] = None
        self._instructions[0x08] = None
        self._instructions[0x09] = None
        self._instructions[0x0A] = None
        self._instructions[0x0B] = None
        self._instructions[0x0C] = None
        self._instructions[0x0D] = None
        self._instructions[0x0E] = None
        self._instructions[0x0F] = None

        self._instructions[0x10] = None
        self._instructions[0x11] = self._lxi
        self._instructions[0x12] = None
        self._instructions[0x13] = None
        self._instructions[0x14] = None
        self._instructions[0x15] = None
        self._instructions[0x16] = None
        self._instructions[0x17] = None
        self._instructions[0x18] = None
        self._instructions[0x19] = None
        self._instructions[0x1A] = None
        self._instructions[0x1B] = None
        self._instructions[0x1C] = None
        self._instructions[0x1D] = None
        self._instructions[0x1E] = None
        self._instructions[0x1F] = None

        self._instructions[0x20] = None
        self._instructions[0x21] = self._lxi
        self._instructions[0x22] = None
        self._instructions[0x23] = None
        self._instructions[0x24] = None
        self._instructions[0x25] = None
        self._instructions[0x26] = None
        self._instructions[0x27] = None
        self._instructions[0x28] = None
        self._instructions[0x29] = None
        self._instructions[0x2A] = None
        self._instructions[0x2B] = None
        self._instructions[0x2C] = None
        self._instructions[0x2D] = None
        self._instructions[0x2E] = None
        self._instructions[0x2F] = None

        self._instructions[0x30] = None
        self._instructions[0x31] = self._lxi
        self._instructions[0x32] = None
        self._instructions[0x33] = None
        self._instructions[0x34] = None
        self._instructions[0x35] = None
        self._instructions[0x36] = None
        self._instructions[0x37] = None
        self._instructions[0x38] = None
        self._instructions[0x39] = None
        self._instructions[0x3A] = None
        self._instructions[0x3B] = None
        self._instructions[0x3C] = None
        self._instructions[0x3D] = None
        self._instructions[0x3E] = None
        self._instructions[0x3F] = None

        self._instructions[0x40] = None
        self._instructions[0x41] = None
        self._instructions[0x42] = None
        self._instructions[0x43] = None
        self._instructions[0x44] = None
        self._instructions[0x45] = None
        self._instructions[0x46] = None
        self._instructions[0x47] = None
        self._instructions[0x48] = None
        self._instructions[0x49] = None
        self._instructions[0x4A] = None
        self._instructions[0x4B] = None
        self._instructions[0x4C] = None
        self._instructions[0x4D] = None
        self._instructions[0x4E] = None
        self._instructions[0x4F] = None

        self._instructions[0x50] = None
        self._instructions[0x51] = None
        self._instructions[0x52] = None
        self._instructions[0x53] = None
        self._instructions[0x54] = None
        self._instructions[0x55] = None
        self._instructions[0x56] = None
        self._instructions[0x57] = None
        self._instructions[0x58] = None
        self._instructions[0x59] = None
        self._instructions[0x5A] = None
        self._instructions[0x5B] = None
        self._instructions[0x5C] = None
        self._instructions[0x5D] = None
        self._instructions[0x5E] = None
        self._instructions[0x5F] = None

        self._instructions[0x60] = None
        self._instructions[0x61] = None
        self._instructions[0x62] = None
        self._instructions[0x63] = None
        self._instructions[0x64] = None
        self._instructions[0x65] = None
        self._instructions[0x66] = None
        self._instructions[0x67] = None
        self._instructions[0x68] = None
        self._instructions[0x69] = None
        self._instructions[0x6A] = None
        self._instructions[0x6B] = None
        self._instructions[0x6C] = None
        self._instructions[0x6D] = None
        self._instructions[0x6E] = None
        self._instructions[0x6F] = None

        self._instructions[0x70] = None
        self._instructions[0x71] = None
        self._instructions[0x72] = None
        self._instructions[0x73] = None
        self._instructions[0x74] = None
        self._instructions[0x75] = None
        self._instructions[0x76] = None
        self._instructions[0x77] = None
        self._instructions[0x78] = None
        self._instructions[0x79] = None
        self._instructions[0x7A] = None
        self._instructions[0x7B] = None
        self._instructions[0x7C] = None
        self._instructions[0x7D] = None
        self._instructions[0x7E] = None
        self._instructions[0x7F] = None

        self._instructions[0x80] = None
        self._instructions[0x81] = None
        self._instructions[0x82] = None
        self._instructions[0x83] = None
        self._instructions[0x84] = None
        self._instructions[0x85] = None
        self._instructions[0x86] = None
        self._instructions[0x87] = None
        self._instructions[0x88] = None
        self._instructions[0x89] = None
        self._instructions[0x8A] = None
        self._instructions[0x8B] = None
        self._instructions[0x8C] = None
        self._instructions[0x8D] = None
        self._instructions[0x8E] = None
        self._instructions[0x8F] = None

        self._instructions[0x90] = None
        self._instructions[0x91] = None
        self._instructions[0x92] = None
        self._instructions[0x93] = None
        self._instructions[0x94] = None
        self._instructions[0x95] = None
        self._instructions[0x96] = None
        self._instructions[0x97] = None
        self._instructions[0x98] = None
        self._instructions[0x99] = None
        self._instructions[0x9A] = None
        self._instructions[0x9B] = None
        self._instructions[0x9C] = None
        self._instructions[0x9D] = None
        self._instructions[0x9E] = None
        self._instructions[0x9F] = None

        self._instructions[0xA0] = None
        self._instructions[0xA1] = None
        self._instructions[0xA2] = None
        self._instructions[0xA3] = None
        self._instructions[0xA4] = None
        self._instructions[0xA5] = None
        self._instructions[0xA6] = None
        self._instructions[0xA7] = None
        self._instructions[0xA8] = None
        self._instructions[0xA9] = None
        self._instructions[0xAA] = None
        self._instructions[0xAB] = None
        self._instructions[0xAC] = None
        self._instructions[0xAD] = None
        self._instructions[0xAE] = None
        self._instructions[0xAF] = None

        self._instructions[0xB0] = None
        self._instructions[0xB1] = None
        self._instructions[0xB2] = None
        self._instructions[0xB3] = None
        self._instructions[0xB4] = None
        self._instructions[0xB5] = None
        self._instructions[0xB6] = None
        self._instructions[0xB7] = None
        self._instructions[0xB8] = None
        self._instructions[0xB9] = None
        self._instructions[0xBA] = None
        self._instructions[0xBB] = None
        self._instructions[0xBC] = None
        self._instructions[0xBD] = None
        self._instructions[0xBE] = None
        self._instructions[0xBF] = None

        self._instructions[0xC0] = None
        self._instructions[0xC1] = None
        self._instructions[0xC2] = None
        self._instructions[0xC3] = None
        self._instructions[0xC4] = None
        self._instructions[0xC5] = None
        self._instructions[0xC6] = None
        self._instructions[0xC7] = None
        self._instructions[0xC8] = None
        self._instructions[0xC9] = None
        self._instructions[0xCA] = None
        self._instructions[0xCB] = None
        self._instructions[0xCC] = None
        self._instructions[0xCD] = None
        self._instructions[0xCE] = None
        self._instructions[0xCF] = None

        self._instructions[0xD0] = None
        self._instructions[0xD1] = None
        self._instructions[0xD2] = None
        self._instructions[0xD3] = None
        self._instructions[0xD4] = None
        self._instructions[0xD5] = None
        self._instructions[0xD6] = None
        self._instructions[0xD7] = None
        self._instructions[0xD8] = None
        self._instructions[0xD9] = None
        self._instructions[0xDA] = None
        self._instructions[0xDB] = None
        self._instructions[0xDC] = None
        self._instructions[0xDD] = None
        self._instructions[0xDE] = None
        self._instructions[0xDF] = None

        self._instructions[0xE0] = None
        self._instructions[0xE1] = None
        self._instructions[0xE2] = None
        self._instructions[0xE3] = None
        self._instructions[0xE4] = None
        self._instructions[0xE5] = None
        self._instructions[0xE6] = None
        self._instructions[0xE7] = None
        self._instructions[0xE8] = None
        self._instructions[0xE9] = None
        self._instructions[0xEA] = None
        self._instructions[0xEB] = None
        self._instructions[0xEC] = None
        self._instructions[0xED] = None
        self._instructions[0xEE] = None
        self._instructions[0xEF] = None

        self._instructions[0xF0] = None
        self._instructions[0xF1] = None
        self._instructions[0xF2] = None
        self._instructions[0xF3] = None
        self._instructions[0xF4] = None
        self._instructions[0xF5] = None
        self._instructions[0xF6] = None
        self._instructions[0xF7] = None
        self._instructions[0xF8] = None
        self._instructions[0xF9] = None
        self._instructions[0xFA] = None
        self._instructions[0xFB] = None
        self._instructions[0xFC] = None
        self._instructions[0xFD] = None
        self._instructions[0xFE] = None
        self._instructions[0xFF] = None

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

        self._enable_interrupts = False


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


    def _push_to_stack(self, value):
        self._sp -= 2
        self._machine.write_stack(self._sp, value)


    def _pop_from_stack(self, value):
        value = self._machine.read_stack(self._sp)
        self._sp += 2
        return value


    def _get_bc(self):
        return (self._b << 8) | self._c


    def _get_de(self):
        return (self._d << 8) | self._e


    def _get_hl(self):
        return (self._h << 8) | self._l


    def _get_psw(self):
        flags = 2 # bit1 is always 1
        flags |= 0x80 if self._sign else 0
        flags |= 0x40 if self._zero else 0
        flags |= 0x10 if self._half_carry else 0
        flags |= 0x04 if self._parity else 0
        flags |= 0x01 if self._carry else 0

        return (self._a << 8) | flags


    def _set_bc(self, value):
        self._b = value >> 8
        self._c = value & 0xff


    def _set_de(self, value):
        self._d = value >> 8
        self._e = value & 0xff


    def _set_hl(self, value):
        self._h = value >> 8
        self._l = value & 0xff

    
    def _set_psw(self, value):
        self._a = value >> 8
        self._sign = (value & 0x80) != 0
        self._zero = (value & 0x40) != 0
        self._half_carry = (value & 0x10) != 0
        self._parity = value & 0x04 != 0
        self._carry = (value & 0x01) != 0


    def _set_register(self, reg_idx, value):
        if reg_idx == 0:
            self._b = value
        if reg_idx == 1:
            self._c = value
        if reg_idx == 2:
            self._d = value
        if reg_idx == 3:
            self._e = value
        if reg_idx == 4:
            self._h = value
        if reg_idx == 5:
            self._l = value
        if reg_idx == 6:
            self._machine.write_memory_byte(self._get_hl(), value)
        if reg_idx == 7:
            self._a = value


    def _set_register_pair(self, reg_pair, value):
        if reg_pair == 0:
            self._set_bc(value)
        if reg_pair == 1:
            self._set_de(value)
        if reg_pair == 2:
            self._set_hl(value)
        if reg_pair == 3:
            self._sp = value


    def _get_register_pair(self, reg_pair):
        if reg_pair == 0:
            return self._get_bc()
        if reg_pair == 1:
            return self._get_de()
        if reg_pair == 2:
            return self._get_hl()
        if reg_pair == 3:
            return self._sp


    def _reg_symb(self, reg_idx):
        return "BCDEHLMA"[reg_idx]


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
        addr = self._pc - 1
        logger.debug(f' {addr:04x}  {self._current_inst:02x}         {mnemonic}')


    def _log_2b_instruction(self, mnemonic):
        addr = self._pc - 2
        param = self._machine.read_memory_byte(self._pc - 1)
        logger.debug(f' {addr:04x}  {self._current_inst:02x} {param:02x}      {mnemonic}')


    def _log_3b_instruction(self, mnemonic):
        addr = self._pc - 3
        param1 = self._machine.read_memory_byte(self._pc - 2)
        param2 = self._machine.read_memory_byte(self._pc - 1)
        logger.debug(f' {addr:04x}  {self._current_inst:02x} {param1:02x} {param2:02x}   {mnemonic}')

    # Movement instructions

    def _nop(self):
        """ Do nothing """
        self._cycles += 4

        self._log_1b_instruction("NOP")


    def _lxi(self):
        """ Load register pair immediate """
        reg_pair = (self._current_inst & 0x30) >> 4
        value = self._fetch_next_word()
        if reg_pair == 3:
            self._sp = value
        else: 
            self._set_register_pair(reg_pair, value)
        self._cycles += 10

        self._log_3b_instruction(f"LXI {self._reg_pair_symb(reg_pair)}, {value:04x}")


    def _mvi(self):
        """ Move immediate to register or memory """
        reg = (self._current_inst & 0x38) >> 3
        value = self._fetch_next_byte()
        self._set_register(reg, value)
        self._cycles += (7 if reg != 6 else 10)

        self._log_2b_instruction(f"MVI {self._reg_symb(reg)}, {value:02x}")


    def _sta(self):
        """ Store accumulator direct """
        addr = self._fetch_next_word()
        self._machine.write_memory_byte(addr, self._a)
        self._cycles += 13

        self._log_3b_instruction(f"STA {addr:04x}")


    def _push(self):
        """ Push register pair to stack """
        reg_pair = (self._current_inst & 0x30) >> 4

        if reg_pair != 3:
            reg_pair_name = self._reg_pair_symb(reg_pair)
            value = self._get_register_pair(reg_pair)
        else:
            reg_pair_name = "PSW"
            value = self._get_psw()

        self._push_to_stack(value)
        self._cycles += 11

        self._log_1b_instruction(f"PUSH {reg_pair_name}")


    # Execution flow instructions

    def _jmp(self):
        """ Unconditional jump """
        addr = self._fetch_next_word()

        self._log_3b_instruction(f"JMP {addr:04x}")

        self._pc = addr
        self._cycles += 10


    def _rst(self):
        """ Restart (special subroutine call) """
        rst = (self._current_inst & 0x38) >> 3

        self._log_1b_instruction(f"RST {rst}")

        self._push_to_stack(self._pc)
        self._pc = rst << 3
        self._cycles += 11

    
    # Flags and modes instructions

    def _ei(self):
        """ Enable interrupts """
        self._enable_interrupts = True
        self._cycles += 4

        self._log_1b_instruction("EI")


    def _di(self):
        """ Enable interrupts """
        self._enable_interrupts = False
        self._cycles += 4

        self._log_1b_instruction("DI")


    # Arithmetic instructions

    def _dcx(self):
        """ Decrement a register pair """
        reg_pair = (self._current_inst & 0x30) >> 4
        value = self._get_register_pair(reg_pair)
        self._set_register_pair(reg_pair, value - 1)
        self._cycles += 5

        self._log_1b_instruction(f"DCX {self._reg_pair_symb(reg_pair)}")


    def _inx(self):
        """ Increment a register pair """
        reg_pair = (self._current_inst & 0x30) >> 4
        value = self._get_register_pair(reg_pair)
        self._set_register_pair(reg_pair, value + 1)
        self._cycles += 5

        self._log_1b_instruction(f"INX {self._reg_pair_symb(reg_pair)}")


    def init_instruction_table(self):
        self._instructions[0x00] = self._nop
        self._instructions[0x01] = self._lxi
        self._instructions[0x02] = None
        self._instructions[0x03] = self._inx
        self._instructions[0x04] = None
        self._instructions[0x05] = None
        self._instructions[0x06] = self._mvi
        self._instructions[0x07] = None
        self._instructions[0x08] = None
        self._instructions[0x09] = None
        self._instructions[0x0A] = None
        self._instructions[0x0B] = self._dcx
        self._instructions[0x0C] = None
        self._instructions[0x0D] = None
        self._instructions[0x0E] = self._mvi
        self._instructions[0x0F] = None

        self._instructions[0x10] = None
        self._instructions[0x11] = self._lxi
        self._instructions[0x12] = None
        self._instructions[0x13] = self._inx
        self._instructions[0x14] = None
        self._instructions[0x15] = None
        self._instructions[0x16] = self._mvi
        self._instructions[0x17] = None
        self._instructions[0x18] = None
        self._instructions[0x19] = None
        self._instructions[0x1A] = None
        self._instructions[0x1B] = self._dcx
        self._instructions[0x1C] = None
        self._instructions[0x1D] = None
        self._instructions[0x1E] = self._mvi
        self._instructions[0x1F] = None

        self._instructions[0x20] = None
        self._instructions[0x21] = self._lxi
        self._instructions[0x22] = None
        self._instructions[0x23] = self._inx
        self._instructions[0x24] = None
        self._instructions[0x25] = None
        self._instructions[0x26] = self._mvi
        self._instructions[0x27] = None
        self._instructions[0x28] = None
        self._instructions[0x29] = None
        self._instructions[0x2A] = None
        self._instructions[0x2B] = self._dcx
        self._instructions[0x2C] = None
        self._instructions[0x2D] = None
        self._instructions[0x2E] = self._mvi
        self._instructions[0x2F] = None

        self._instructions[0x30] = None
        self._instructions[0x31] = self._lxi
        self._instructions[0x32] = self._sta
        self._instructions[0x33] = self._inx
        self._instructions[0x34] = None
        self._instructions[0x35] = None
        self._instructions[0x36] = self._mvi
        self._instructions[0x37] = None
        self._instructions[0x38] = None
        self._instructions[0x39] = None
        self._instructions[0x3A] = None
        self._instructions[0x3B] = self._dcx
        self._instructions[0x3C] = None
        self._instructions[0x3D] = None
        self._instructions[0x3E] = self._mvi
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
        self._instructions[0xC3] = self._jmp
        self._instructions[0xC4] = None
        self._instructions[0xC5] = self._push
        self._instructions[0xC6] = None
        self._instructions[0xC7] = self._rst
        self._instructions[0xC8] = None
        self._instructions[0xC9] = None
        self._instructions[0xCA] = None
        self._instructions[0xCB] = None
        self._instructions[0xCC] = None
        self._instructions[0xCD] = None
        self._instructions[0xCE] = None
        self._instructions[0xCF] = self._rst

        self._instructions[0xD0] = None
        self._instructions[0xD1] = None
        self._instructions[0xD2] = None
        self._instructions[0xD3] = None
        self._instructions[0xD4] = None
        self._instructions[0xD5] = self._push
        self._instructions[0xD6] = None
        self._instructions[0xD7] = self._rst
        self._instructions[0xD8] = None
        self._instructions[0xD9] = None
        self._instructions[0xDA] = None
        self._instructions[0xDB] = None
        self._instructions[0xDC] = None
        self._instructions[0xDD] = None
        self._instructions[0xDE] = None
        self._instructions[0xDF] = self._rst

        self._instructions[0xE0] = None
        self._instructions[0xE1] = None
        self._instructions[0xE2] = None
        self._instructions[0xE3] = None
        self._instructions[0xE4] = None
        self._instructions[0xE5] = self._push
        self._instructions[0xE6] = None
        self._instructions[0xE7] = self._rst
        self._instructions[0xE8] = None
        self._instructions[0xE9] = None
        self._instructions[0xEA] = None
        self._instructions[0xEB] = None
        self._instructions[0xEC] = None
        self._instructions[0xED] = None
        self._instructions[0xEE] = None
        self._instructions[0xEF] = self._rst

        self._instructions[0xF0] = None
        self._instructions[0xF1] = None
        self._instructions[0xF2] = None
        self._instructions[0xF3] = self._di
        self._instructions[0xF4] = None
        self._instructions[0xF5] = self._push
        self._instructions[0xF6] = None
        self._instructions[0xF7] = self._rst
        self._instructions[0xF8] = None
        self._instructions[0xF9] = None
        self._instructions[0xFA] = None
        self._instructions[0xFB] = self._ei
        self._instructions[0xFC] = None
        self._instructions[0xFD] = None
        self._instructions[0xFE] = None
        self._instructions[0xFF] = self._rst

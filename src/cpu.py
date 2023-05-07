import logging
from utils import *

logger = logging.getLogger('cpu')

class CPU:
    def __init__(self, machine):
        self._machine = machine
        machine.set_cpu(self)

        self.reset()

        # Instructions and execution
        self._cycles = 0
        self._current_inst = 0  # current instruction
        self._instructions = [None] * 0x100
        self.init_instruction_table();
    
        self._registers_logging = False


    def reset(self):
        """
        Resets registers and flags
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
        self._interrupt_instructions = []


    def step(self):
        """
        Executes an instruction and updates processor state
        """
        self._current_inst = self._fetch_next_byte()
        instruction = self._instructions[self._current_inst]
        if instruction is not None:
            instruction()
        else:
            raise InvalidInstruction(f"Incorrect OPCODE 0x{self._current_inst:02x} (at addr 0x{(self._pc - 1):04x})")

    
    def schedule_interrupt(self, instructions):
        """
        Trigger the interrupt execution.
        
        Typically an interrupt controller will aquire the data bus, and feed the
        CPU up to 3 instructions. This function allows emulating this behavior by
        adding passed instructions to the instruction fetch queue.
        """
        self._interrupt_instructions = instructions


    def enable_registers_logging(self, value):
        self._registers_logging = value


    @property
    def a(self):
        return self._a
    

    @a.setter
    def a(self, value):
        assert value >= 0x00 and value <= 0xff
        self._a = value & 0xff


    @property
    def b(self):
        return self._b
    
    
    @b.setter
    def b(self, value):
        assert value >= 0x00 and value <= 0xff
        self._b = value & 0xff


    @property
    def c(self):
        return self._c
    

    @c.setter
    def c(self, value):
        assert value >= 0x00 and value <= 0xff
        self._c = value & 0xff


    @property
    def d(self):
        return self._d
    

    @d.setter
    def d(self, value):
        assert value >= 0x00 and value <= 0xff
        self._d = value & 0xff


    @property
    def e(self):
        return self._e
    

    @e.setter
    def e(self, value):
        assert value >= 0x00 and value <= 0xff
        self._e = value & 0xff


    @property
    def h(self):
        return self._h
    

    @h.setter
    def h(self, value):
        assert value >= 0x00 and value <= 0xff
        self._h = value & 0xff


    @property
    def l(self):
        return self._l
    

    @l.setter
    def l(self, value):
        assert value >= 0x00 and value <= 0xff
        self._l = value & 0xff


    def _fetch_next_byte(self):
        if self._enable_interrupts and self._interrupt_instructions:
            data = self._interrupt_instructions[0]
            del self._interrupt_instructions[0]
        else:
            data = self._machine.read_memory_byte(self._pc)
            self._pc += 1
        return data


    def _fetch_next_word(self):
        if self._enable_interrupts and self._interrupt_instructions:
            if len(self._interrupt_instructions) < 2:
                raise InvalidInstruction(f"Insufficient interrupt instructions (expecting 2, only 1 given)")            
            data = self._interrupt_instructions[0] | (self._interrupt_instructions[1] << 8)
            del self._interrupt_instructions[0]
            del self._interrupt_instructions[0]
        else:
            data = self._machine.read_memory_word(self._pc)
            self._pc += 2
        return data


    def _push_to_stack(self, value):
        self._sp -= 2
        self._machine.write_stack(self._sp, value)


    def _pop_from_stack(self):
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


    def _get_register(self, reg_idx):
        if reg_idx == 0:
            return self._b
        if reg_idx == 1:
            return self._c
        if reg_idx == 2:
            return self._d
        if reg_idx == 3:
            return self._e
        if reg_idx == 4:
            return self._h
        if reg_idx == 5:
            return self._l
        if reg_idx == 6:
            return self._machine.read_memory_byte(self._get_hl())
        if reg_idx == 7:
            return self._a


    def _set_register(self, reg_idx, value):
        assert value >= 0x00 and value <= 0xff
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


    def _get_cpu_state_str(self):
        res = f"A={self._a:02x} BC={self._get_bc():04x} DE={self._get_de():04x} "
        res += f"HL={self._get_hl():04x} SP={self._sp:04x} "
        res += f"{'Z' if self._zero else '-'}"
        res += f"{'S' if self._sign else '-'}"
        res += f"{'C' if self._carry else '-'}"
        res += f"{'A' if self._half_carry else '-'}"
        res += f"{'P' if self._parity else '-'}"
        res += f"{'I' if self._enable_interrupts else '-'}"
        return res


    def _log_1b_instruction(self, mnemonic):
        if logger.level > logging.DEBUG:
            return

        addr = self._pc - 1
        log_str = f' {addr:04x}  {self._current_inst:02x}         {mnemonic}'

        if self._registers_logging:
            log_str = f"{log_str:35} {self._get_cpu_state_str()}"
            
        logger.debug(log_str)


    def _log_2b_instruction(self, mnemonic):
        if logger.level > logging.DEBUG:
            return

        addr = self._pc - 2
        param = self._machine.read_memory_byte(self._pc - 1)
        log_str = f' {addr:04x}  {self._current_inst:02x} {param:02x}      {mnemonic}'

        if self._registers_logging:
            log_str = f"{log_str:35} {self._get_cpu_state_str()}"
            
        logger.debug(log_str)


    def _log_3b_instruction(self, mnemonic):
        if logger.level > logging.DEBUG:
            return

        addr = self._pc - 3
        param1 = self._machine.read_memory_byte(self._pc - 2)
        param2 = self._machine.read_memory_byte(self._pc - 1)

        log_str = f' {addr:04x}  {self._current_inst:02x} {param1:02x} {param2:02x}   {mnemonic}'

        if self._registers_logging:
            log_str = f"{log_str:35} {self._get_cpu_state_str()}"
            
        logger.debug(log_str)



    # Data transfer instructions

    def _nop(self):
        """ Do nothing """
        self._cycles += 4

        self._log_1b_instruction("NOP")


    def _mov(self):
        """ Move byte between 2 registers """
        dst = (self._current_inst & 0x38) >> 3
        src = self._current_inst & 0x07
        value = self._get_register(src)
        self._set_register(dst, value)

        self._cycles += 5
        if src == 6 or dst == 6:
            self._cycles += 2

        self._log_1b_instruction(f"MOV {self._reg_symb(dst)}, {self._reg_symb(src)}")


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


    def _lda(self):
        """ Load accumulator direct """
        addr = self._fetch_next_word()
        self._a = self._machine.read_memory_byte(addr)
        self._cycles += 13

        self._log_3b_instruction(f"LDA {addr:04x}")


    def _ldax(self):
        """ Load accumulator """
        reg_pair = (self._current_inst & 0x10) >> 4
        addr = self._get_register_pair(reg_pair)
        self._a = self._machine.read_memory_byte(addr)
        self._cycles += 7

        self._log_1b_instruction(f"LDAX {self._reg_pair_symb(reg_pair)}")


    def _stax(self):
        """ Store accumulator """
        reg_pair = (self._current_inst & 0x10) >> 4
        addr = self._get_register_pair(reg_pair)
        self._machine.write_memory_byte(addr, self._a)
        self._cycles += 7

        self._log_1b_instruction(f"STAX {self._reg_pair_symb(reg_pair)}")


    def _shld(self):
        """ Store H and L direct"""
        addr = self._fetch_next_word()
        self._machine.write_memory_word(addr, self._get_hl())
        self._cycles += 16

        self._log_3b_instruction(f"SHLD {addr:04x}")


    def _lhld(self):
        """ Load H and L direct"""
        addr = self._fetch_next_word()
        self._set_hl(self._machine.read_memory_word(addr))
        self._cycles += 16

        self._log_3b_instruction(f"LHLD {addr:04x}")


    def _xchg(self):
        """ Exchange DE and HL """
        value = self._get_hl()
        self._set_hl(self._get_de())
        self._set_de(value)
        self._cycles += 5

        self._log_1b_instruction(f"XCHG")


    def _xthl(self):
        """ Exchange HL and 2 bytes on the stack """
        value = self._get_hl()
        self._set_hl(self._machine.read_stack(self._sp))
        self._machine.write_stack(self._sp, value)
        self._cycles += 18

        self._log_1b_instruction(f"XTHL")


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


    def _pop(self):
        """ Pop register pair from stack """
        reg_pair = (self._current_inst & 0x30) >> 4

        value = self._pop_from_stack()

        if reg_pair != 3:
            reg_pair_name = self._reg_pair_symb(reg_pair)
            self._set_register_pair(reg_pair, value)
        else:
            reg_pair_name = "PSW"
            self._set_psw(value)

        self._cycles += 10

        self._log_1b_instruction(f"POP {reg_pair_name}")


    def _in(self):
        """ IO Input """
        addr = self._fetch_next_byte()

        self._a = self._machine.read_io(addr)
        self._cycles += 10

        self._log_2b_instruction(f"IN {addr:02x}")


    def _out(self):
        """ IO Output """
        addr = self._fetch_next_byte()
        self._log_2b_instruction(f"OUT {addr:02x}")

        self._machine.write_io(addr, self._a)
        self._cycles += 10


    # Execution flow instructions

    def _jmp(self):
        """ Unconditional jump """
        addr = self._fetch_next_word()

        self._log_3b_instruction(f"JMP {addr:04x}")

        self._pc = addr
        self._cycles += 10


    def _check_condition(self, op):
        """ Helper function to check condition on conditional JUMP, CALL, and RET """
        if op == 0:
            return not self._zero
        if op == 1:
            return self._zero
        if op == 2:
            return not self._carry
        if op == 3:
            return self._carry
        if op == 4:
            return not self._parity
        if op == 5:
            return self._parity
        if op == 6:
            return not self._sign
        if op == 7:
            return self._sign


    def _jmp_cond(self):
        """ Conditional jump """
        addr = self._fetch_next_word()
        op = (self._current_inst & 0x38) >> 3
        op_symb = ["JNZ", "JZ", "JNC", "JC", "JPO", "JPE", "JP", "JN"][op]

        self._log_3b_instruction(f"{op_symb} {addr:04x}")

        if self._check_condition(op):
            self._pc = addr

        self._cycles += 10


    def _call(self):
        """ Call a subroutine """
        addr = self._fetch_next_word()

        self._log_3b_instruction(f"CALL {addr:04x}")

        self._push_to_stack(self._pc)
        self._pc = addr
        self._cycles += 17


    def _call_cond(self):
        """ Conditional call """
        addr = self._fetch_next_word()
        op = (self._current_inst & 0x38) >> 3
        op_symb = ["CNZ", "CZ", "CNC", "CC", "CPO", "CPE", "CP", "CN"][op]

        self._log_3b_instruction(f"{op_symb} {addr:04x}")

        if self._check_condition(op):
            self._push_to_stack(self._pc)
            self._pc = addr
            self._cycles += 17
        else:
            self._cycles += 11


    def _ret(self):
        """ Return from a subroutine """

        self._log_1b_instruction(f"RET")

        self._pc = self._pop_from_stack()
        self._cycles += 10


    def _ret_cond(self):
        """ Conditional return """
        op = (self._current_inst & 0x38) >> 3
        op_symb = ["RNZ", "RZ", "RNC", "RC", "RPO", "RPE", "RP", "RN"][op]

        self._log_1b_instruction(f"{op_symb}")

        if self._check_condition(op):
            self._pc = self._pop_from_stack()
            self._cycles += 11
        else:
            self._cycles += 5


    def _rst(self):
        """ Restart (special subroutine call) """
        rst = (self._current_inst & 0x38) >> 3

        self._log_1b_instruction(f"RST {rst}")

        self._push_to_stack(self._pc)
        self._pc = rst << 3
        self._cycles += 11

    
    def _pchl(self):
        """ Load HL value to PC register """
        self._log_1b_instruction(f"PCHL")
        self._pc = self._get_hl()
        self._cycles += 5


    def _sphl(self):
        """ Load HL value to SP register """
        self._log_1b_instruction(f"SPHL")
        self._sp = self._get_hl()
        self._cycles += 5


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

    def _count_bits(self, n):
        """ Return number of set bits """
        if (n == 0):
            return 0
        else:
            return 1 + self._count_bits(n & (n - 1))

    def _alu_op(self, op, value):
        """ Internal implementation of an ALU operation between the accumulator and value.
        The function updates flags as a result of the operation """

        # Perform the operation
        if op == 0: # ADD
            res = self._a + value
            self._carry = res > 0xff
            self._half_carry = ((self._a & 0x0f) + (value & 0x0f)) > 0x0f
        if op == 1: # ADC
            carry = 1 if self._carry else 0
            res = self._a + value + carry
            self._carry = res > 0xff
            self._half_carry = ((self._a & 0x0f) + (value & 0x0f) + carry) > 0x0f
        if op == 2 or op == 7: # SUB and CMP
            res = self._a - value
            self._carry = res < 0
            neg_value = ~value + 1
            self._half_carry = ((self._a & 0x0f) + (neg_value & 0x0f)) > 0x0f
        if op == 3: # SBB
            carry = 1 if self._carry else 0
            res = self._a - value - carry
            self._carry = res < 0 
            neg_value = ~value + 1
            self._half_carry = ((self._a & 0x0f) + ((neg_value - carry) & 0x0f)) > 0x0f
        if op == 4: # AND
            res = self._a & value
        if op == 5: # XOR
            res = self._a ^ value
        if op == 6: # OR
            res = self._a | value

        # Store result for all operations, except for CMP
        if op != 7:
            self._a = res & 0xff

        # Update common flags
        if op >= 4 and op < 7: self._carry = False
        if op >= 4 and op < 7: self._half_carry = False
        self._zero = (res & 0xff) == 0
        self._parity = self._count_bits(self._a) % 2 == 0
        self._sign = (self._a & 0x80) != 0


    def _alu(self):
        """ 
        Implementation of the following instructions:
            - ADD - add a register to the accumulator
            - ADC - add a register to the accumulator with carry
            - SUB - subtract a register from the accumulator
            - SBB - subtract a register from the accumulator with carry
            - ANA - logical AND a register with the accumulator
            - XRA - logical XOR a register with the accumulator
            - ORA - logical OR a register with the accumulator
            - CMP - compare a register with the accumulator (set flags, but not change accumulator)
        """
        op = (self._current_inst & 0x38) >> 3
        op_name = ["ADD", "ADC", "SUB", "SBB", "ANA", "XRA", "ORA", "CMP"][op]
        reg = self._current_inst & 0x07
        value = self._get_register(reg)

        self._alu_op(op, value)
        self._cycles += 4 if reg != 6 else 7

        self._log_1b_instruction(f"{op_name} {self._reg_symb(reg)}")


    def _alu_immediate(self):
        """ 
        Implementation of ALU instructions between the accumulator register and 
        immediate operand:
            - ADI - add the operand to the accumulator
            - ACI - add the operand to the accumulator with carry
            - SUI - subtract the operand from the accumulator
            - SBI - subtract the operand from the accumulator with carry
            - ANI - logical AND the operand with the accumulator
            - XRI - logical XOR the operand with the accumulator
            - ORI - logical OR the operand with the accumulator
            - CPI - compare the operand with the accumulator (set flags, but not change accumulator)
        """
        op = (self._current_inst & 0x38) >> 3
        op_name = ["ADI", "ACI", "SUI", "SBI", "ANI", "XRI", "ORI", "CPI"][op]
        value = self._fetch_next_byte()

        self._alu_op(op, value)
        self._cycles += 7

        self._log_2b_instruction(f"{op_name} {value:02x}")


    def _daa(self):
        """ Decimal adjust accumulator """
        if (self._a & 0xf) > 9 or self._half_carry:
            self._a = (self._a + 0x6) & 0xff
            self._half_carry = True

        if (self._a & 0xf0) > 0x90 or self._carry:
            self._a = (self._a + 0x60) & 0xff
            self._carry = True

        self._zero = (self._a & 0xff) == 0
        self._parity = self._count_bits(self._a) % 2 == 0
        self._sign = (self._a & 0x80) != 0

        self._cycles += 4
        self._log_1b_instruction(f"DAA")
        

    def _dcr(self):
        """ Decrement a register """
        reg = (self._current_inst & 0x38) >> 3
        value = (self._get_register(reg) - 1) & 0xff
        self._set_register(reg, value)

        self._zero = (value & 0xff) == 0
        self._parity = self._count_bits(value) % 2 == 0
        self._sign = (value & 0x80) != 0
        self._half_carry = value == 0x0f

        self._log_1b_instruction(f"DCR {self._reg_symb(reg)}")
        self._cycles += 10 if reg == 6 else 5


    def _inr(self):
        """ Increment a register """
        reg = (self._current_inst & 0x38) >> 3
        value = (self._get_register(reg) + 1) & 0xff
        self._set_register(reg, value)

        self._zero = (value & 0xff) == 0
        self._parity = self._count_bits(value) % 2 == 0
        self._sign = (value & 0x80) != 0
        self._half_carry = (value & 0xf) == 0x0

        self._log_1b_instruction(f"INR {self._reg_symb(reg)}")
        self._cycles += 10 if reg == 6 else 5


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


    def _dad(self):
        """ Double Add """
        reg_pair = (self._current_inst & 0x30) >> 4
        value = self._get_register_pair(reg_pair)
        res = self._get_hl() + value
        self._set_hl(res & 0xffff)
        self._carry = (res >= 0x10000)

        self._cycles += 10

        self._log_1b_instruction(f"DAD {self._reg_pair_symb(reg_pair)}")


    def _rlc(self):
        """ Rotate accumulator left """
        self._carry = True if (self._a >> 7) == 1 else False
        self._a = ((self._a << 1) & 0xff) | (self._a >> 7)
        self._cycles += 4

        self._log_1b_instruction(f"RLC")


    def _rrc(self):
        """ Rotate accumulator right """
        self._carry = True if (self._a & 0x01) == 1 else False
        self._a = ((self._a >> 1) & 0xFF) | ((self._a << 7) & 0xFF)
        self._cycles += 4

        self._log_1b_instruction(f"RRC")


    def _ral(self):
        """ Rotate accumulator left through carry """
        temp = self._a
        self._a = (self._a << 1) & 0xFF
        self._a |= 1 if self._carry else 0
        self._carry = (temp & 0x80) > 0
        self._cycles += 4

        self._log_1b_instruction(f"RAL")


    def _rar(self):
        """ Rotate accumulator right through carry """
        temp = self._a
        self._a >>= 1
        self._a |= 0x80 if self._carry else 0
        self._carry = (temp & 0x01) > 0
        self._cycles += 4

        self._log_1b_instruction(f"RAR")


    def _stc(self):
        """ Set carry bit """
        self._carry = True
        self._cycles += 4

        self._log_1b_instruction(f"STC")
        

    def _cmc(self):
        """ Complement carry bit """
        self._carry = not self._carry
        self._cycles += 4

        self._log_1b_instruction(f"CMC")
        

    def _cma(self):
        """ Complement accumulator """
        self._a = (~self._a) & 0xFF
        self._cycles += 4

        self._log_1b_instruction(f"CMA")
        

    def init_instruction_table(self):
        self._instructions[0x00] = self._nop
        self._instructions[0x01] = self._lxi
        self._instructions[0x02] = self._stax
        self._instructions[0x03] = self._inx
        self._instructions[0x04] = self._inr
        self._instructions[0x05] = self._dcr
        self._instructions[0x06] = self._mvi
        self._instructions[0x07] = self._rlc
        self._instructions[0x08] = None
        self._instructions[0x09] = self._dad
        self._instructions[0x0A] = self._ldax
        self._instructions[0x0B] = self._dcx
        self._instructions[0x0C] = self._inr
        self._instructions[0x0D] = self._dcr
        self._instructions[0x0E] = self._mvi
        self._instructions[0x0F] = self._rrc

        self._instructions[0x10] = None
        self._instructions[0x11] = self._lxi
        self._instructions[0x12] = self._stax
        self._instructions[0x13] = self._inx
        self._instructions[0x14] = self._inr
        self._instructions[0x15] = self._dcr
        self._instructions[0x16] = self._mvi
        self._instructions[0x17] = self._ral
        self._instructions[0x18] = None
        self._instructions[0x19] = self._dad
        self._instructions[0x1A] = self._ldax
        self._instructions[0x1B] = self._dcx
        self._instructions[0x1C] = self._inr
        self._instructions[0x1D] = self._dcr
        self._instructions[0x1E] = self._mvi
        self._instructions[0x1F] = self._rar

        self._instructions[0x20] = None
        self._instructions[0x21] = self._lxi
        self._instructions[0x22] = self._shld
        self._instructions[0x23] = self._inx
        self._instructions[0x24] = self._inr
        self._instructions[0x25] = self._dcr
        self._instructions[0x26] = self._mvi
        self._instructions[0x27] = self._daa
        self._instructions[0x28] = None
        self._instructions[0x29] = self._dad
        self._instructions[0x2A] = self._lhld
        self._instructions[0x2B] = self._dcx
        self._instructions[0x2C] = self._inr
        self._instructions[0x2D] = self._dcr
        self._instructions[0x2E] = self._mvi
        self._instructions[0x2F] = self._cma

        self._instructions[0x30] = None
        self._instructions[0x31] = self._lxi
        self._instructions[0x32] = self._sta
        self._instructions[0x33] = self._inx
        self._instructions[0x34] = self._inr
        self._instructions[0x35] = self._dcr
        self._instructions[0x36] = self._mvi
        self._instructions[0x37] = self._stc
        self._instructions[0x38] = None
        self._instructions[0x39] = self._dad
        self._instructions[0x3A] = self._lda
        self._instructions[0x3B] = self._dcx
        self._instructions[0x3C] = self._inr
        self._instructions[0x3D] = self._dcr
        self._instructions[0x3E] = self._mvi
        self._instructions[0x3F] = self._cmc

        self._instructions[0x40] = self._mov
        self._instructions[0x41] = self._mov
        self._instructions[0x42] = self._mov
        self._instructions[0x43] = self._mov
        self._instructions[0x44] = self._mov
        self._instructions[0x45] = self._mov
        self._instructions[0x46] = self._mov
        self._instructions[0x47] = self._mov
        self._instructions[0x48] = self._mov
        self._instructions[0x49] = self._mov
        self._instructions[0x4A] = self._mov
        self._instructions[0x4B] = self._mov
        self._instructions[0x4C] = self._mov
        self._instructions[0x4D] = self._mov
        self._instructions[0x4E] = self._mov
        self._instructions[0x4F] = self._mov

        self._instructions[0x50] = self._mov
        self._instructions[0x51] = self._mov
        self._instructions[0x52] = self._mov
        self._instructions[0x53] = self._mov
        self._instructions[0x54] = self._mov
        self._instructions[0x55] = self._mov
        self._instructions[0x56] = self._mov
        self._instructions[0x57] = self._mov
        self._instructions[0x58] = self._mov
        self._instructions[0x59] = self._mov
        self._instructions[0x5A] = self._mov
        self._instructions[0x5B] = self._mov
        self._instructions[0x5C] = self._mov
        self._instructions[0x5D] = self._mov
        self._instructions[0x5E] = self._mov
        self._instructions[0x5F] = self._mov

        self._instructions[0x60] = self._mov
        self._instructions[0x61] = self._mov
        self._instructions[0x62] = self._mov
        self._instructions[0x63] = self._mov
        self._instructions[0x64] = self._mov
        self._instructions[0x65] = self._mov
        self._instructions[0x66] = self._mov
        self._instructions[0x67] = self._mov
        self._instructions[0x68] = self._mov
        self._instructions[0x69] = self._mov
        self._instructions[0x6A] = self._mov
        self._instructions[0x6B] = self._mov
        self._instructions[0x6C] = self._mov
        self._instructions[0x6D] = self._mov
        self._instructions[0x6E] = self._mov
        self._instructions[0x6F] = self._mov

        self._instructions[0x70] = self._mov
        self._instructions[0x71] = self._mov
        self._instructions[0x72] = self._mov
        self._instructions[0x73] = self._mov
        self._instructions[0x74] = self._mov
        self._instructions[0x75] = self._mov
        self._instructions[0x76] = None
        self._instructions[0x77] = self._mov
        self._instructions[0x78] = self._mov
        self._instructions[0x79] = self._mov
        self._instructions[0x7A] = self._mov
        self._instructions[0x7B] = self._mov
        self._instructions[0x7C] = self._mov
        self._instructions[0x7D] = self._mov
        self._instructions[0x7E] = self._mov
        self._instructions[0x7F] = self._mov

        self._instructions[0x80] = self._alu
        self._instructions[0x81] = self._alu
        self._instructions[0x82] = self._alu
        self._instructions[0x83] = self._alu
        self._instructions[0x84] = self._alu
        self._instructions[0x85] = self._alu
        self._instructions[0x86] = self._alu
        self._instructions[0x87] = self._alu
        self._instructions[0x88] = self._alu
        self._instructions[0x89] = self._alu
        self._instructions[0x8A] = self._alu
        self._instructions[0x8B] = self._alu
        self._instructions[0x8C] = self._alu
        self._instructions[0x8D] = self._alu
        self._instructions[0x8E] = self._alu
        self._instructions[0x8F] = self._alu

        self._instructions[0x90] = self._alu
        self._instructions[0x91] = self._alu
        self._instructions[0x92] = self._alu
        self._instructions[0x93] = self._alu
        self._instructions[0x94] = self._alu
        self._instructions[0x95] = self._alu
        self._instructions[0x96] = self._alu
        self._instructions[0x97] = self._alu
        self._instructions[0x98] = self._alu
        self._instructions[0x99] = self._alu
        self._instructions[0x9A] = self._alu
        self._instructions[0x9B] = self._alu
        self._instructions[0x9C] = self._alu
        self._instructions[0x9D] = self._alu
        self._instructions[0x9E] = self._alu
        self._instructions[0x9F] = self._alu

        self._instructions[0xA0] = self._alu
        self._instructions[0xA1] = self._alu
        self._instructions[0xA2] = self._alu
        self._instructions[0xA3] = self._alu
        self._instructions[0xA4] = self._alu
        self._instructions[0xA5] = self._alu
        self._instructions[0xA6] = self._alu
        self._instructions[0xA7] = self._alu
        self._instructions[0xA8] = self._alu
        self._instructions[0xA9] = self._alu
        self._instructions[0xAA] = self._alu
        self._instructions[0xAB] = self._alu
        self._instructions[0xAC] = self._alu
        self._instructions[0xAD] = self._alu
        self._instructions[0xAE] = self._alu
        self._instructions[0xAF] = self._alu

        self._instructions[0xB0] = self._alu
        self._instructions[0xB1] = self._alu
        self._instructions[0xB2] = self._alu
        self._instructions[0xB3] = self._alu
        self._instructions[0xB4] = self._alu
        self._instructions[0xB5] = self._alu
        self._instructions[0xB6] = self._alu
        self._instructions[0xB7] = self._alu
        self._instructions[0xB8] = self._alu
        self._instructions[0xB9] = self._alu
        self._instructions[0xBA] = self._alu
        self._instructions[0xBB] = self._alu
        self._instructions[0xBC] = self._alu
        self._instructions[0xBD] = self._alu
        self._instructions[0xBE] = self._alu
        self._instructions[0xBF] = self._alu

        self._instructions[0xC0] = self._ret_cond
        self._instructions[0xC1] = self._pop
        self._instructions[0xC2] = self._jmp_cond
        self._instructions[0xC3] = self._jmp
        self._instructions[0xC4] = self._call_cond
        self._instructions[0xC5] = self._push
        self._instructions[0xC6] = self._alu_immediate
        self._instructions[0xC7] = self._rst
        self._instructions[0xC8] = self._ret_cond
        self._instructions[0xC9] = self._ret
        self._instructions[0xCA] = self._jmp_cond
        self._instructions[0xCB] = None
        self._instructions[0xCC] = self._call_cond
        self._instructions[0xCD] = self._call
        self._instructions[0xCE] = self._alu_immediate
        self._instructions[0xCF] = self._rst

        self._instructions[0xD0] = self._ret_cond
        self._instructions[0xD1] = self._pop
        self._instructions[0xD2] = self._jmp_cond
        self._instructions[0xD3] = self._out
        self._instructions[0xD4] = self._call_cond
        self._instructions[0xD5] = self._push
        self._instructions[0xD6] = self._alu_immediate
        self._instructions[0xD7] = self._rst
        self._instructions[0xD8] = self._ret_cond
        self._instructions[0xD9] = None
        self._instructions[0xDA] = self._jmp_cond
        self._instructions[0xDB] = self._in
        self._instructions[0xDC] = self._call_cond
        self._instructions[0xDD] = None
        self._instructions[0xDE] = self._alu_immediate
        self._instructions[0xDF] = self._rst

        self._instructions[0xE0] = self._ret_cond
        self._instructions[0xE1] = self._pop
        self._instructions[0xE2] = self._jmp_cond
        self._instructions[0xE3] = self._xthl
        self._instructions[0xE4] = self._call_cond
        self._instructions[0xE5] = self._push
        self._instructions[0xE6] = self._alu_immediate
        self._instructions[0xE7] = self._rst
        self._instructions[0xE8] = self._ret_cond
        self._instructions[0xE9] = self._pchl
        self._instructions[0xEA] = self._jmp_cond
        self._instructions[0xEB] = self._xchg
        self._instructions[0xEC] = self._call_cond
        self._instructions[0xED] = None
        self._instructions[0xEE] = self._alu_immediate
        self._instructions[0xEF] = self._rst

        self._instructions[0xF0] = self._ret_cond
        self._instructions[0xF1] = self._pop
        self._instructions[0xF2] = self._jmp_cond
        self._instructions[0xF3] = self._di
        self._instructions[0xF4] = self._call_cond
        self._instructions[0xF5] = self._push
        self._instructions[0xF6] = self._alu_immediate
        self._instructions[0xF7] = self._rst
        self._instructions[0xF8] = self._ret_cond
        self._instructions[0xF9] = self._sphl
        self._instructions[0xFA] = self._jmp_cond
        self._instructions[0xFB] = self._ei
        self._instructions[0xFC] = self._call_cond
        self._instructions[0xFD] = None
        self._instructions[0xFE] = self._alu_immediate
        self._instructions[0xFF] = self._rst

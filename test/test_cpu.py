# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys
from unittest.mock import MagicMock

sys.path.append('../src')

from common.machine import Machine
from common.cpu import CPU
from common.rom import ROM
from common.ram import RAM
from common.interfaces import MemoryDevice, IODevice
from common.utils import *
from helper import MockIO

@pytest.fixture
def cpu():
    machine = Machine()
    machine.add_memory(MemoryDevice(RAM(), 0x0000, 0xffff))
    return CPU(machine) 

def test_reset_values(cpu):
    assert cpu.a == 0x00
    assert cpu.b == 0x00
    assert cpu.c == 0x00
    assert cpu.d == 0x00
    assert cpu.e == 0x00
    assert cpu.h == 0x00
    assert cpu.l == 0x00
    assert cpu._sign == False
    assert cpu._zero == False
    assert cpu._half_carry == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._enable_interrupts == False
    assert cpu.pc == 0x0000
    assert cpu.sp == 0x0000    

    assert cpu._cycles == 0

def test_machine_reset(cpu):
    # This is actually a Machine test, but it is more convenient to do it here
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu.step()
    cpu._machine.reset()
    assert cpu.pc == 0x0000

def test_interrupt_disabled(cpu):
    cpu.schedule_interrupt([0xff])                  # Schedule RST7 as interrupt instruction
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu.step()
    assert cpu.pc == 0x0001                        # Interrupts are disabled, so normal NOP is executed
    assert cpu._cycles == 4

def test_interrupt_1byte(cpu):
    cpu.schedule_interrupt([0xff])                  # Schedule RST7 as interrupt instruction
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu._enable_interrupts = True
    cpu.sp = 0x1234
    cpu.step()
    assert cpu.pc == 0x0038                        # expecting RST7 executed
    assert cpu._machine.read_memory_word(0x1232) == 0x0000  # Current instruction address

def test_interrupt_3byte(cpu):
    cpu.schedule_interrupt([0xcd, 0xef, 0xbe])      # Schedule CALL 0xbeef as interrupt instructions
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu._enable_interrupts = True
    cpu.sp = 0x1234
    cpu.step()
    assert cpu.pc == 0xbeef                        # expecting CALL executed
    assert cpu._machine.read_memory_word(0x1232) == 0x0000  # Current instruction address

def test_machine_interrupt(cpu):
    # This is another Machine class test, that is more convenient to test via CPU
    cpu._machine.schedule_interrupt()               # Machine will schedule RST7 as interrupt instruction
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu._enable_interrupts = True
    cpu.sp = 0x1234
    cpu.step()
    assert cpu.pc == 0x0038                        # expecting RST7 executed
    assert cpu._machine.read_memory_word(0x1232) == 0x0000  # Current instruction address

def test_interrupt_insufficient_instructions(cpu):
    cpu.schedule_interrupt([0xcd, 0xef])            # Schedule malformed interrupt instruction
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu._enable_interrupts = True
    cpu.sp = 0x1234
    with pytest.raises(InvalidInstruction):
        cpu.step()

def test_nop(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu._cycles == 4

def test_lxi_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x01)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu.pc == 0x0003
    assert cpu.b == 0xbe
    assert cpu.c == 0xef
    assert cpu._cycles == 10

def test_lxi_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x11)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu.pc == 0x0003
    assert cpu.d == 0xbe
    assert cpu.e == 0xef
    assert cpu._cycles == 10
    
def test_lxi_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x21)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu.pc == 0x0003
    assert cpu.h == 0xbe
    assert cpu.l == 0xef
    assert cpu._cycles == 10
    
def test_lxi_sp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x31)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu.pc == 0x0003
    assert cpu.sp == 0xbeef
    assert cpu._cycles == 10

def test_mvia(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu.a == 0x42
    assert cpu._cycles == 7

def test_mvi_b(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x06)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu.b == 0x42
    assert cpu._cycles == 7

def test_mvi_c(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu.c == 0x42
    assert cpu._cycles == 7

def test_mvi_d(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x16)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu.d == 0x42
    assert cpu._cycles == 7

def test_mvi_e(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu.e == 0x42
    assert cpu._cycles == 7

def test_mvi_h(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x26)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu.h == 0x42
    assert cpu._cycles == 7

def test_mvi_l(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x2e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu.l == 0x42
    assert cpu._cycles == 7

def test_mvi_m(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x36)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.hl = 0x1234
    cpu.step()
    assert cpu._machine.read_memory_byte(0x1234) == 0x42
    assert cpu._cycles == 10

def test_jmp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc3)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xca)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xca)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jnz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jnz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xda)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xda)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jnc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jnc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jpe_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xea)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jpe_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xea)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jpo_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jpo_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jn_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfa)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_jn_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfa)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jp_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu._cycles == 10

def test_jp_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 10

def test_call(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xcd)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.sp = 0x1234
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu._cycles == 17
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # address of the next instruction

def test_cnz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._zero = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cnz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._zero = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_cz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xcc)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._zero = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xcc)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._zero = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_cnc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._carry = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cnc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._carry = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_cc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xdc)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._carry = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xdc)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._carry = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_cpo_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._parity = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cpo_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._parity = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_cpe_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xec)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._parity = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cpe_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xec)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._parity = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_cp_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._sign = True
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cp_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf4)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._sign = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_cm_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfc)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._sign = False
    cpu.step()
    assert cpu.pc == 0x0003
    assert cpu.sp == 0x1234
    assert cpu._cycles == 11

def test_cm_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfc)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Subroutine address
    cpu.sp = 0x1234
    cpu._sign = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0003 # Return address
    assert cpu._cycles == 17

def test_pchl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe9)    # Instruction Opcode
    cpu.hl = 0x1234
    cpu.step()
    assert cpu.pc == 0x1234
    assert cpu._cycles == 5

def test_sphl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf9)    # Instruction Opcode
    cpu.hl = 0x1234
    cpu.step()
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_ei_di(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfb)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0xf3)    # Instruction Opcode
    
    cpu.step() # EI
    assert cpu._enable_interrupts == True
    assert cpu._cycles == 4

    cpu.step() # DI
    assert cpu._enable_interrupts == False
    assert cpu._cycles == 8     # 4 more cycles

def test_sta(cpu):
    cpu.a = 0x42   # Value to write
    cpu._machine.write_memory_byte(0x0000, 0x32)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step()
    assert cpu._machine.read_memory_byte(0xbeef) == 0x42
    assert cpu._cycles == 13

def test_lda(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3a)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._machine.write_memory_byte(0xbeef, 0x42)    # Data to read
    cpu.step()
    assert cpu.a == 0x42
    assert cpu._cycles == 13

def test_shld(cpu):
    cpu.hl = 0x1234   # Value to write
    cpu._machine.write_memory_byte(0x0000, 0x22)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step()
    assert cpu._machine.read_memory_word(0xbeef) == 0x1234
    assert cpu._cycles == 16

def test_lhld(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x2a)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._machine.write_memory_word(0xbeef, 0x1234)  # Value to read
    cpu.step()
    assert cpu.hl == 0x1234
    assert cpu._cycles == 16

@pytest.mark.parametrize("opcode, rstaddr", 
    [(0xc7, 0x0000), (0xcf, 0x0008), (0xd7, 0x0010), (0xdf, 0x0018),
     (0xe7, 0x0020), (0xef, 0x0028), (0xf7, 0x0030), (0xff, 0x0038)])
def test_rst(cpu, opcode, rstaddr):
    cpu._machine.write_memory_byte(0x0000, opcode)    # Instruction Opcode
    cpu.sp = 0x1234
    cpu.step()
    assert cpu.pc == rstaddr
    assert cpu._cycles == 11
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0001 # address of the next instruction

def test_ret(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc9)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 10

def test_rnz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._zero = True
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rnz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._zero = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_rz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._zero = False
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._zero = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_rnc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._carry = True
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rnc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._carry = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_rc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._carry = False
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._carry = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_rpo_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._parity = True
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rpo_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._parity = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_rpe_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._parity = False
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rpe_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._parity = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_rp_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._sign = True
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rp_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf0)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._sign = False
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_rm_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._sign = False
    cpu.step()
    assert cpu.pc == 0x0001
    assert cpu.sp == 0x1234
    assert cpu._cycles == 5

def test_rm_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf8)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu.sp = 0x1234
    cpu._sign = True
    cpu.step()
    assert cpu.pc == 0xbeef
    assert cpu.sp == 0x1236
    assert cpu._cycles == 11

def test_push_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc5)    # Instruction Opcode
    cpu.sp = 0x1234
    cpu.bc = 0xbeef
    cpu.step()
    assert cpu._cycles == 11
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0xbeef

def test_push_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd5)    # Instruction Opcode
    cpu.sp = 0x1234
    cpu.de = 0xbeef
    cpu.step()
    assert cpu._cycles == 11
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0xbeef

def test_push_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe5)    # Instruction Opcode
    cpu.sp = 0x1234
    cpu.hl = 0xbeef
    cpu.step()
    assert cpu._cycles == 11
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0xbeef

def test_push_psw1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf5)    # Instruction Opcode
    cpu.sp = 0x1234
    cpu.a = 0x42
    cpu.step()
    assert cpu._cycles == 11
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x4202 # bit1 of the PSW is always 1

def test_push_psw2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf5)    # Instruction Opcode
    cpu.sp = 0x1234
    cpu.a = 0x42
    cpu._sign = True
    cpu._zero = True
    cpu._half_carry = True
    cpu._parity = True
    cpu._carry = True
    cpu.step()
    assert cpu._cycles == 11
    assert cpu.sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x42d7 # bit1 of the PSW is always 1

def test_pop_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Data to pop
    cpu.sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu.sp == 0x1236
    assert cpu.bc == 0xbeef

def test_pop_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Data to pop
    cpu.sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu.sp == 0x1236
    assert cpu.de == 0xbeef

def test_pop_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Data to pop
    cpu.sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu.sp == 0x1236
    assert cpu.hl == 0xbeef

def test_pop_psw_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbe02)  # Data to pop (A=0xbe, all flags are off)
    cpu.sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu.sp == 0x1236
    assert cpu.a == 0xbe
    assert cpu._carry == False
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False

def test_pop_psw_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbed7)  # Data to pop (A=0xbe, all flags are on)
    cpu.sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu.sp == 0x1236
    assert cpu.a == 0xbe
    assert cpu._carry == True
    assert cpu._half_carry == True
    assert cpu._zero == True
    assert cpu._sign == True
    assert cpu._parity == True

def test_dcra(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3d)    # Instruction Opcode
    cpu.a = 0x42
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.a == 0x41
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True

def test_dcr_b(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x05)    # Instruction Opcode
    cpu.b = 0xa2
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.b == 0xa1
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False

def test_dcr_c(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0d)    # Instruction Opcode
    cpu.c = 0x01
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.c == 0x00
    assert cpu._half_carry == False
    assert cpu._zero == True
    assert cpu._sign == False
    assert cpu._parity == True

def test_dcr_d(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x15)    # Instruction Opcode
    cpu.d = 0x00
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.d == 0xff
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True

def test_dcr_e(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1d)    # Instruction Opcode
    cpu.e = 0x10
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.e == 0x0f
    assert cpu._half_carry == True
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True

def test_dcr_m(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x35)    # Instruction Opcode
    cpu._machine.write_memory_byte(0xbeef, 0x42)    # Data byte
    cpu.hl = 0xbeef
    cpu.step()
    assert cpu._cycles == 10
    assert cpu._machine.read_memory_byte(0xbeef) == 0x41
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True

def test_inra(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3c)    # Instruction Opcode
    cpu.a = 0x42
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.a == 0x43
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False

def test_inr_b(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x04)    # Instruction Opcode
    cpu.b = 0xa2
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.b == 0xa3
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True

def test_inr_c(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0c)    # Instruction Opcode
    cpu.c = 0xff
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.c == 0x00
    assert cpu._half_carry == True
    assert cpu._zero == True
    assert cpu._sign == False
    assert cpu._parity == True

def test_inr_d(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x14)    # Instruction Opcode
    cpu.d = 0x00
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.d == 0x01
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False

def test_inr_e(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1c)    # Instruction Opcode
    cpu.e = 0x3f
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.e == 0x40
    assert cpu._half_carry == True
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False

def test_inr_m(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x34)    # Instruction Opcode
    cpu._machine.write_memory_byte(0xbeef, 0x42)    # Data byte
    cpu.hl = 0xbeef
    cpu.step()
    assert cpu._cycles == 10
    assert cpu._machine.read_memory_byte(0xbeef) == 0x43
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False

def test_dcx_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0b)    # Instruction Opcode
    cpu.bc = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.b == 0xbe
    assert cpu.c == 0xee

def test_dcx_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1b)    # Instruction Opcode
    cpu.de = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.d == 0xbe
    assert cpu.e == 0xee

def test_dcx_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x2b)    # Instruction Opcode
    cpu.hl = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.h == 0xbe
    assert cpu.l == 0xee

def test_dcx_sp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3b)    # Instruction Opcode
    cpu.sp = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.sp == 0xbeee

def test_inx_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x03)    # Instruction Opcode
    cpu.bc = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.b == 0xbe
    assert cpu.c == 0xf0

def test_inx_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x13)    # Instruction Opcode
    cpu.de = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.d == 0xbe
    assert cpu.e == 0xf0

def test_inx_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x23)    # Instruction Opcode
    cpu.hl = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.h == 0xbe
    assert cpu.l == 0xf0

def test_inx_sp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x33)    # Instruction Opcode
    cpu.sp = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.sp == 0xbef0

def test_dad_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x09)    # Instruction Opcode
    cpu.hl = 0xa17b
    cpu.bc = 0x339f
    cpu.step()
    assert cpu.hl == 0xd51a
    assert cpu._carry == False
    assert cpu._cycles == 10

def test_dad_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x19)    # Instruction Opcode
    cpu.hl = 0xa17b
    cpu.de = 0xbeef
    cpu.step()
    assert cpu.hl == 0x606a
    assert cpu._carry == True
    assert cpu._cycles == 10

def test_dad_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x29)    # Instruction Opcode
    cpu.hl = 0xbeef
    cpu.step()
    assert cpu.hl == 0x7dde
    assert cpu._carry == True
    assert cpu._cycles == 10

def test_dad_sp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x39)    # Instruction Opcode
    cpu.hl = 0x1234
    cpu.sp = 0xbeef
    cpu.step()
    assert cpu.hl == 0xd123
    assert cpu._carry == False
    assert cpu._cycles == 10

def test_mova_h(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x7c)    # Instruction Opcode
    cpu.h = 0x42
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.a == 0x42

def test_mov_b_e(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x43)    # Instruction Opcode
    cpu.e = 0x42
    cpu.step()
    assert cpu._cycles == 5
    assert cpu.b == 0x42

def test_mov_m_d(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x72)    # Instruction Opcode
    cpu.d = 0x42
    cpu.hl = 0x1234
    cpu.step()
    assert cpu._cycles == 7
    assert cpu._machine.read_memory_byte(0x1234) == 0x42

def test_mov_l_m(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x6e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x1234, 0x42)    # Data
    cpu.hl = 0x1234
    cpu.step()
    assert cpu._cycles == 7
    assert cpu.l == 0x42

def test_xchg(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xeb)    # Instruction Opcode
    cpu.hl = 0x1234
    cpu.de = 0xbeef
    cpu.step()
    assert cpu.hl == 0xbeef
    assert cpu.de == 0x1234
    assert cpu._cycles == 5

def test_xthl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe3)    # Instruction Opcode
    cpu._machine.write_memory_word(0x4321, 0xbeef)  # data to be exchanged
    cpu.hl = 0x1234
    cpu.sp = 0x4321
    cpu.step()
    assert cpu.hl == 0xbeef
    assert cpu._machine.read_memory_word(0x4321) == 0x1234
    assert cpu._cycles == 18

def test_ldax_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0a)    # Instruction Opcode
    cpu._machine.write_memory_byte(0xbeef, 0x42)    # Data to load
    cpu.bc = 0xbeef
    cpu.step()
    assert cpu.a == 0x42
    assert cpu._cycles == 7

def test_ldax_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1a)    # Instruction Opcode
    cpu._machine.write_memory_byte(0xbeef, 0x42)    # Data to load
    cpu.de = 0xbeef
    cpu.step()
    assert cpu.a == 0x42
    assert cpu._cycles == 7

def test_stax_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x02)    # Instruction Opcode
    cpu.a = 0x42
    cpu.bc = 0xbeef
    cpu.step()
    assert cpu._machine.read_memory_byte(0xbeef) == 0x42
    assert cpu._cycles == 7

def test_stax_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x12)    # Instruction Opcode
    cpu.a = 0x42
    cpu.de = 0xbeef
    cpu.step()
    assert cpu._machine.read_memory_byte(0xbeef) == 0x42
    assert cpu._cycles == 7

def testadd(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x80)    # Instruction Opcode
    cpu.a = 0x6c
    cpu.b = 0x2e
    cpu.step()
    assert cpu.a == 0x9a
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == True

def testadc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x89)    # Instruction Opcode
    cpu.a = 0x3d
    cpu.c = 0x42
    cpu._carry = False
    cpu.step()
    assert cpu.a == 0x7f
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def testadc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x8a)    # Instruction Opcode
    cpu.a = 0x3d
    cpu.d = 0x42
    cpu._carry = True
    cpu.step()
    assert cpu.a == 0x80
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_sub(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x97)    # Instruction Opcode
    cpu.a = 0x3e
    cpu.step()
    assert cpu.a == 0x00
    assert cpu._cycles == 4
    assert cpu._zero == True
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_sbb(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x9b)    # Instruction Opcode
    cpu.a = 0x04
    cpu.e = 0x02
    cpu._carry = True
    cpu.step()
    assert cpu.a == 0x01
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == True

def testana(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xa5)    # Instruction Opcode
    cpu.a = 0xfc
    cpu.l = 0x0f
    cpu.step()
    assert cpu.a == 0x0c
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_xra(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xac)    # Instruction Opcode
    cpu.a = 0x5c
    cpu.h = 0x78
    cpu.step()
    assert cpu.a == 0x24
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_ora(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x1234, 0x0f)    # Instruction Opcode
    cpu.a = 0x33
    cpu.hl = 0x1234
    cpu.step()
    assert cpu.a == 0x3f
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_cmp_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb8)    # Instruction Opcode
    cpu.a = 0x0a
    cpu.b = 0x05
    cpu.step()
    assert cpu.a == 0x0a # Does not change
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_cmp_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb8)    # Instruction Opcode
    cpu.a = 0x02
    cpu.b = 0x05
    cpu.step()
    assert cpu.a == 0x02 # Does not change
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == True
    assert cpu._half_carry == False

def test_cmp_3(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb8)    # Instruction Opcode
    cpu.a = 0xe5
    cpu.b = 0x05
    cpu.step()
    assert cpu.a == 0xe5 # Does not change
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == True

def testadi_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # value
    cpu.a = 0x14
    cpu.step()
    assert cpu.a == 0x56
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def testadi_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0xbe)    # value
    cpu.a = 0x56
    cpu.step()
    assert cpu.a == 0x14
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == True
    assert cpu._half_carry == True

def testaci(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xce)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # value
    cpu.a = 0x14
    cpu._carry = True
    cpu.step()
    assert cpu.a == 0x57
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_sui(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x01)    # value
    cpu.a = 0x00
    cpu.step()
    assert cpu.a == 0xff
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True
    assert cpu._carry == True
    assert cpu._half_carry == False

def test_sbi_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xde)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x01)    # value
    cpu.a = 0x00
    cpu._carry = False
    cpu.step()
    assert cpu.a == 0xff
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True
    assert cpu._carry == True
    assert cpu._half_carry == False

def test_sbi_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xde)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x01)    # value
    cpu.a = 0x00
    cpu._carry = True
    cpu.step()
    assert cpu.a == 0xfe
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == True
    assert cpu._half_carry == False

def testani(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x0f)    # value
    cpu.a = 0x3a
    cpu.step()
    assert cpu.a == 0x0a
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_xri(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xee)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x81)    # value
    cpu.a = 0x3b
    cpu.step()
    assert cpu.a == 0xba
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_ori(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x0f)    # value
    cpu.a = 0xb5
    cpu.step()
    assert cpu.a == 0xbf
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_cpi(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfe)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x40)    # value
    cpu.a = 0x4a
    cpu.step()
    assert cpu.a == 0x4a # not changed
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_rlc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x07)    # Instruction Opcode
    cpu.a = 0x5a
    cpu.step()
    assert cpu.a == 0xb4
    assert cpu._cycles == 4
    assert cpu._carry == False

def test_rlc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x07)    # Instruction Opcode
    cpu.a = 0xa5
    cpu.step()
    assert cpu.a == 0x4b
    assert cpu._cycles == 4
    assert cpu._carry == True

def test_rrc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0f)    # Instruction Opcode
    cpu.a = 0x5a
    cpu.step()
    assert cpu.a == 0x2d
    assert cpu._cycles == 4
    assert cpu._carry == False

def test_rrc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0f)    # Instruction Opcode
    cpu.a = 0xa5
    cpu.step()
    assert cpu.a == 0xd2
    assert cpu._cycles == 4
    assert cpu._carry == True

def test_ral_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x17)    # Instruction Opcode
    cpu.a = 0x5a
    cpu._carry = True
    cpu.step()
    assert cpu.a == 0xb5
    assert cpu._cycles == 4
    assert cpu._carry == False

def test_ral_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x17)    # Instruction Opcode
    cpu.a = 0xa5
    cpu._carry = False
    cpu.step()
    assert cpu.a == 0x4a
    assert cpu._cycles == 4
    assert cpu._carry == True

def test_rar_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1f)    # Instruction Opcode
    cpu.a = 0x5a
    cpu._carry = True
    cpu.step()
    assert cpu.a == 0xad
    assert cpu._cycles == 4
    assert cpu._carry == False

def test_rar_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1f)    # Instruction Opcode
    cpu.a = 0xa5
    cpu._carry = False
    cpu.step()
    assert cpu.a == 0x52
    assert cpu._cycles == 4
    assert cpu._carry == True

def test_stc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x37)    # Instruction Opcode
    cpu.step()
    assert cpu._carry == True
    assert cpu._cycles == 4

def test_cmc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3f)    # Instruction Opcode
    cpu._carry = False
    cpu.step()
    assert cpu._carry == True
    assert cpu._cycles == 4

def test_cmc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3f)    # Instruction Opcode
    cpu._carry = True
    cpu.step()
    assert cpu._carry == False
    assert cpu._cycles == 4

def test_cma(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x2f)    # Instruction Opcode
    cpu.a = 0x51
    cpu.step()
    assert cpu.a == 0xae
    assert cpu._cycles == 4

def test_daa(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x27)    # Instruction Opcode
    cpu.a = 0x9b
    cpu._half_carry == False
    cpu._carry == False
    cpu.step()
    assert cpu.a == 0x01
    assert cpu._cycles == 4
    assert cpu._half_carry == True
    assert cpu._carry == True
    assert cpu._sign == False
    assert cpu._zero == False
    assert cpu._parity == False

def test_out(cpu):
    mock = MockIO()
    mock.write_byte = MagicMock()

    cpu._machine.add_io(IODevice(mock, 0x42))
    cpu._machine.write_memory_byte(0x0000, 0xd3)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # IO addr
    cpu.a = 0x55
    cpu.step()

    mock.write_byte.assert_called_once_with(0, 0x55)

def test_in(cpu):
    mock = MockIO()
    mock.read_byte = MagicMock(return_value=0x55)

    cpu._machine.add_io(IODevice(mock, 0x42))
    cpu._machine.write_memory_byte(0x0000, 0xdb)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # IO addr
    cpu.step()
    assert cpu.a == 0x55
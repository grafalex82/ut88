# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from machine import Machine
from cpu import CPU
from rom import ROM
from ram import RAM
from utils import *
from mock import *

@pytest.fixture
def cpu():
    machine = Machine()
    machine.add_memory(RAM(0x0000, 0xffff))
    return CPU(machine) 

def test_reset_values(cpu):
    assert cpu._a == 0x00
    assert cpu._b == 0x00
    assert cpu._c == 0x00
    assert cpu._d == 0x00
    assert cpu._e == 0x00
    assert cpu._h == 0x00
    assert cpu._l == 0x00
    assert cpu._sign == False
    assert cpu._zero == False
    assert cpu._half_carry == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._enable_interrupts == False
    assert cpu._pc == 0x0000
    assert cpu._sp == 0x0000    

    assert cpu._cycles == 0

def test_nop(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x00)    # Instruction Opcode
    cpu.step()
    assert cpu._pc == 0x0001
    assert cpu._cycles == 4

def test_lxi_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x01)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._b == 0xbe
    assert cpu._c == 0xef
    assert cpu._cycles == 10

def test_lxi_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x11)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._d == 0xbe
    assert cpu._e == 0xef
    assert cpu._cycles == 10
    
def test_lxi_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x21)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._h == 0xbe
    assert cpu._l == 0xef
    assert cpu._cycles == 10
    
def test_lxi_sp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x31)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._sp == 0xbeef
    assert cpu._cycles == 10

def test_mvi_a(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu._a == 0x42
    assert cpu._cycles == 7

def test_mvi_b(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x06)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu._b == 0x42
    assert cpu._cycles == 7

def test_mvi_c(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu._c == 0x42
    assert cpu._cycles == 7

def test_mvi_d(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x16)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu._d == 0x42
    assert cpu._cycles == 7

def test_mvi_e(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu._e == 0x42
    assert cpu._cycles == 7

def test_mvi_h(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x26)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu._h == 0x42
    assert cpu._cycles == 7

def test_mvi_l(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x2e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu.step()
    assert cpu._l == 0x42
    assert cpu._cycles == 7

def test_mvi_m(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x36)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # Value
    cpu._set_hl(0x1234)
    cpu.step()
    assert cpu._machine.read_memory_byte(0x1234) == 0x42
    assert cpu._cycles == 10

def test_jmp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc3)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 10

def test_jz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xca)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = True
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_jz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xca)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = False
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jnz_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = True
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jnz_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._zero = False
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_jc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xda)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = True
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_jc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xda)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = False
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jnc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = True
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jnc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._carry = False
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_jpe_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xea)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = True
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_jpe_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xea)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = False
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jpo_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = True
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jpo_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._parity = False
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_jn_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfa)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = True
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_jn_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfa)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = False
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jp_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = True
    cpu.step()
    assert cpu._pc == 0x0003
    assert cpu._cycles == 10

def test_jp_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf2)    # Instruction Opcode
    cpu._machine.write_memory_word(0x0001, 0xbeef)  # Address
    cpu._sign = False
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._cycles == 15

def test_pchl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe9)    # Instruction Opcode
    cpu._set_hl(0x1234)
    cpu.step()
    assert cpu._pc == 0x1234
    assert cpu._cycles == 5

def test_sphl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf9)    # Instruction Opcode
    cpu._set_hl(0x1234)
    cpu.step()
    assert cpu._sp == 0x1234
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
    cpu._a = 0x42   # Value to write
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
    assert cpu._a == 0x42
    assert cpu._cycles == 13

def test_shld(cpu):
    cpu._set_hl(0x1234)   # Value to write
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
    assert cpu._get_hl() == 0x1234
    assert cpu._cycles == 16

@pytest.mark.parametrize("opcode, rstaddr", 
    [(0xc7, 0x0000), (0xcf, 0x0008), (0xd7, 0x0010), (0xdf, 0x0018),
     (0xe7, 0x0020), (0xef, 0x0028), (0xf7, 0x0030), (0xff, 0x0038)])
def test_rst(cpu, opcode, rstaddr):
    cpu._machine.write_memory_byte(0x0000, opcode)    # Instruction Opcode
    cpu._sp = 0x1234
    cpu.step()
    assert cpu._pc == rstaddr
    assert cpu._cycles == 11
    assert cpu._sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x0001 # address of the next instruction

def test_ret(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc9)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Return address
    cpu._sp = 0x1234
    cpu.step()
    assert cpu._pc == 0xbeef
    assert cpu._sp == 0x1236
    assert cpu._cycles == 10

def test_push_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc5)    # Instruction Opcode
    cpu._sp = 0x1234
    cpu._set_bc(0xbeef)
    cpu.step()
    assert cpu._cycles == 11
    assert cpu._sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0xbeef

def test_push_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd5)    # Instruction Opcode
    cpu._sp = 0x1234
    cpu._set_de(0xbeef)
    cpu.step()
    assert cpu._cycles == 11
    assert cpu._sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0xbeef

def test_push_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe5)    # Instruction Opcode
    cpu._sp = 0x1234
    cpu._set_hl(0xbeef)
    cpu.step()
    assert cpu._cycles == 11
    assert cpu._sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0xbeef

def test_push_psw1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf5)    # Instruction Opcode
    cpu._sp = 0x1234
    cpu._a = 0x42
    cpu.step()
    assert cpu._cycles == 11
    assert cpu._sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x4202 # bit1 of the PSW is always 1

def test_push_psw2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf5)    # Instruction Opcode
    cpu._sp = 0x1234
    cpu._a = 0x42
    cpu._sign = True
    cpu._zero = True
    cpu._half_carry = True
    cpu._parity = True
    cpu._carry = True
    cpu.step()
    assert cpu._cycles == 11
    assert cpu._sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0x42d7 # bit1 of the PSW is always 1

def test_pop_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Data to pop
    cpu._sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu._sp == 0x1236
    assert cpu._get_bc() == 0xbeef

def test_pop_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Data to pop
    cpu._sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu._sp == 0x1236
    assert cpu._get_de() == 0xbeef

def test_pop_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbeef)  # Data to pop
    cpu._sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu._sp == 0x1236
    assert cpu._get_hl() == 0xbeef

def test_pop_psw_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbe02)  # Data to pop (A=0xbe, all flags are off)
    cpu._sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu._sp == 0x1236
    assert cpu._a == 0xbe
    assert cpu._carry == False
    assert cpu._half_carry == False
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False

def test_pop_psw_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf1)    # Instruction Opcode
    cpu._machine.write_memory_word(0x1234, 0xbed7)  # Data to pop (A=0xbe, all flags are on)
    cpu._sp = 0x1234
    cpu.step()
    assert cpu._cycles == 10
    assert cpu._sp == 0x1236
    assert cpu._a == 0xbe
    assert cpu._carry == True
    assert cpu._half_carry == True
    assert cpu._zero == True
    assert cpu._sign == True
    assert cpu._parity == True

def test_dcx_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0b)    # Instruction Opcode
    cpu._set_bc(0xbeef)
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._b == 0xbe
    assert cpu._c == 0xee

def test_dcx_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1b)    # Instruction Opcode
    cpu._set_de(0xbeef)
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._d == 0xbe
    assert cpu._e == 0xee

def test_dcx_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x2b)    # Instruction Opcode
    cpu._set_hl(0xbeef)
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._h == 0xbe
    assert cpu._l == 0xee

def test_dcx_sp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3b)    # Instruction Opcode
    cpu._sp = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._sp == 0xbeee

def test_inx_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x03)    # Instruction Opcode
    cpu._set_bc(0xbeef)
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._b == 0xbe
    assert cpu._c == 0xf0

def test_inx_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x13)    # Instruction Opcode
    cpu._set_de(0xbeef)
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._d == 0xbe
    assert cpu._e == 0xf0

def test_inx_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x23)    # Instruction Opcode
    cpu._set_hl(0xbeef)
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._h == 0xbe
    assert cpu._l == 0xf0

def test_inx_sp(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x33)    # Instruction Opcode
    cpu._sp = 0xbeef
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._sp == 0xbef0

def test_mov_a_h(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x7c)    # Instruction Opcode
    cpu._h = 0x42
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._a == 0x42

def test_mov_b_e(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x43)    # Instruction Opcode
    cpu._e = 0x42
    cpu.step()
    assert cpu._cycles == 5
    assert cpu._b == 0x42

def test_mov_m_d(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x72)    # Instruction Opcode
    cpu._d = 0x42
    cpu._set_hl(0x1234)
    cpu.step()
    assert cpu._cycles == 7
    assert cpu._machine.read_memory_byte(0x1234) == 0x42

def test_mov_l_m(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x6e)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x1234, 0x42)    # Data
    cpu._set_hl(0x1234)
    cpu.step()
    assert cpu._cycles == 7
    assert cpu._l == 0x42

def test_add(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x80)    # Instruction Opcode
    cpu._a = 0x6c
    cpu._b = 0x2e
    cpu.step()
    assert cpu._a == 0x9a
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_adc_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x89)    # Instruction Opcode
    cpu._a = 0x3d
    cpu._c = 0x42
    cpu._carry = False
    cpu.step()
    assert cpu._a == 0x7f
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_adc_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x8a)    # Instruction Opcode
    cpu._a = 0x3d
    cpu._d = 0x42
    cpu._carry = True
    cpu.step()
    assert cpu._a == 0x80
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_sub(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x97)    # Instruction Opcode
    cpu._a = 0x3e
    cpu.step()
    assert cpu._a == 0x00
    assert cpu._cycles == 4
    assert cpu._zero == True
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_sbb(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x9b)    # Instruction Opcode
    cpu._a = 0x04
    cpu._e = 0x02
    cpu._carry = True
    cpu.step()
    assert cpu._a == 0x01
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_ana(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xa5)    # Instruction Opcode
    cpu._a = 0xfc
    cpu._l = 0x0f
    cpu.step()
    assert cpu._a == 0x0c
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_xra(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xac)    # Instruction Opcode
    cpu._a = 0x5c
    cpu._h = 0x78
    cpu.step()
    assert cpu._a == 0x24
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_ora(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x1234, 0x0f)    # Instruction Opcode
    cpu._a = 0x33
    cpu._set_hl(0x1234)
    cpu.step()
    assert cpu._a == 0x3f
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_cmp_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb8)    # Instruction Opcode
    cpu._a = 0x0a
    cpu._b = 0x05
    cpu.step()
    assert cpu._a == 0x0a # Does not change
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_cmp_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb8)    # Instruction Opcode
    cpu._a = 0x02
    cpu._b = 0x05
    cpu.step()
    assert cpu._a == 0x02 # Does not change
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == True
    assert cpu._half_carry == False

def test_cmp_3(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xb8)    # Instruction Opcode
    cpu._a = 0xe5
    cpu._b = 0x05
    cpu.step()
    assert cpu._a == 0xe5 # Does not change
    assert cpu._cycles == 4
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == True

def test_adi_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # value
    cpu._a = 0x14
    cpu.step()
    assert cpu._a == 0x56
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_adi_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0xbe)    # value
    cpu._a = 0x56
    cpu.step()
    assert cpu._a == 0x14
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == True
    assert cpu._half_carry == True

def test_aci(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xce)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # value
    cpu._a = 0x14
    cpu._carry = True
    cpu.step()
    assert cpu._a == 0x57
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_sui(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xd6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x01)    # value
    cpu._a = 0x00
    cpu.step()
    assert cpu._a == 0xff
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True
    assert cpu._carry == True
    assert cpu._half_carry == False

def test_sbi_1(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xde)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x01)    # value
    cpu._a = 0x00
    cpu._carry = False
    cpu.step()
    assert cpu._a == 0xff
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == True
    assert cpu._carry == True
    assert cpu._half_carry == False

def test_sbi_2(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xde)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x01)    # value
    cpu._a = 0x00
    cpu._carry = True
    cpu.step()
    assert cpu._a == 0xfe
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == True
    assert cpu._half_carry == False

def test_ani(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xe6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x0f)    # value
    cpu._a = 0x3a
    cpu.step()
    assert cpu._a == 0x0a
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == True
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_xri(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xee)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x81)    # value
    cpu._a = 0x3b
    cpu.step()
    assert cpu._a == 0xba
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_ori(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xf6)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x0f)    # value
    cpu._a = 0xb5
    cpu.step()
    assert cpu._a == 0xbf
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == True
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_cpi(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xfe)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x40)    # value
    cpu._a = 0x4a
    cpu.step()
    assert cpu._a == 0x4a # not changed
    assert cpu._cycles == 7
    assert cpu._zero == False
    assert cpu._sign == False
    assert cpu._parity == False
    assert cpu._carry == False
    assert cpu._half_carry == False

def test_out(cpu):
    io = MockIO(0x42)
    cpu._machine.add_io(io)
    cpu._machine.write_memory_byte(0x0000, 0xd3)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # IO addr
    cpu._a = 0x55
    cpu.step()
    assert io.read_io(0x42) == 0x55

def test_in(cpu):
    io = MockIO(0x42)
    io.write_io(0x42, 0x55)
    cpu._machine.add_io(io)
    cpu._machine.write_memory_byte(0x0000, 0xdb)    # Instruction Opcode
    cpu._machine.write_memory_byte(0x0001, 0x42)    # IO addr
    cpu.step()
    assert cpu._a == 0x55

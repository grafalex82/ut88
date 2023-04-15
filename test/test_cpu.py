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

def test_push_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0xc5)    # Instruction Opcode
    cpu._sp = 0x1234
    cpu._set_bc(0xbeef)
    cpu.step()
    assert cpu._cycles == 11
    assert cpu._sp == 0x1232
    assert cpu._machine.read_memory_word(0x1232) == 0xbeef

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

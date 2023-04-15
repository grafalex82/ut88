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

def test_cpu_reset_values(cpu):
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
    assert cpu._pc == 0x0000
    assert cpu._sp == 0x0000    

    assert cpu._cycles == 0

def test_cpu_nop(cpu):
    cpu.step() # empty RAM shall have zeroes, which is a NOP instruction
    assert cpu._pc == 0x0001
    assert cpu._cycles == 4

def test_cpu_lxi_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x01)
    cpu._machine.write_memory_word(0x0001, 0xbeef)
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._b == 0xbe
    assert cpu._c == 0xef
    assert cpu._cycles == 10

def test_cpu_lxi_de(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x11)
    cpu._machine.write_memory_word(0x0001, 0xbeef)
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._d == 0xbe
    assert cpu._e == 0xef
    assert cpu._cycles == 10
    
def test_cpu_lxi_hl(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x21)
    cpu._machine.write_memory_word(0x0001, 0xbeef)
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._h == 0xbe
    assert cpu._l == 0xef
    assert cpu._cycles == 10
    
def test_cpu_lxi_bc(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x31)
    cpu._machine.write_memory_word(0x0001, 0xbeef)
    cpu.step() 
    assert cpu._pc == 0x0003
    assert cpu._sp == 0xbeef
    assert cpu._cycles == 10

def test_cpu_mvi_a(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x3e)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu.step()
    assert cpu._a == 0x42
    assert cpu._cycles == 7

def test_cpu_mvi_b(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x06)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu.step()
    assert cpu._b == 0x42
    assert cpu._cycles == 7

def test_cpu_mvi_c(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x0e)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu.step()
    assert cpu._c == 0x42
    assert cpu._cycles == 7

def test_cpu_mvi_d(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x16)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu.step()
    assert cpu._d == 0x42
    assert cpu._cycles == 7

def test_cpu_mvi_e(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x1e)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu.step()
    assert cpu._e == 0x42
    assert cpu._cycles == 7

def test_cpu_mvi_h(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x26)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu.step()
    assert cpu._h == 0x42
    assert cpu._cycles == 7

def test_cpu_mvi_l(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x2e)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu.step()
    assert cpu._l == 0x42
    assert cpu._cycles == 7

def test_cpu_mvi_m(cpu):
    cpu._machine.write_memory_byte(0x0000, 0x36)
    cpu._machine.write_memory_byte(0x0001, 0x42)
    cpu._set_hl(0x1234)
    cpu.step()
    assert cpu._machine.read_memory_byte(0x1234) == 0x42
    assert cpu._cycles == 10

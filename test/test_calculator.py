# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for Calculator firmware, rather than UT-88 schematics.
# These tests run emulation of some functions from the calculator firmware, feed it some 
# values, and check results. This is easier than manually enter arguments to required
# memory cells, run some calculator functions, and then check memory for a result

import pytest
import sys
import logging

sys.path.append('../misc')
sys.path.append('../src')

from float import *

from machine import Machine
from emulator import Emulator
from cpu import CPU
from rom import ROM
from ram import RAM
from utils import *
from mock import *

# Calculator is a UT-88 in Basic CPU unit configuration + calculator firmware
#
# This is a helper class that sets up the machine, configures it for running a
# calculator function, feeds function arguments, and retrieves the result
class Calculator:
    def __init__(self):
        self._machine = Machine()
        self._machine.add_memory(RAM(0xc000, 0xc3ff))     # Same as CPU module configuration
        self._machine.add_memory(ROM(f"../resources/Monitor0.bin", 0x0000))
        self._machine.add_memory(ROM(f"../resources/calculator.bin", 0x0800))

        self._emulator = Emulator(self._machine)

    def _convert_byte(self, value): # Convert the value from Sign-Magnitude to Two's Complement or back
        if value >= 0x80 or value < 0:
            value = (~value + 1) & 0xff
            return value | 0x80
        return value

    def set_byte_argument(self, addr, value):
        if value >= 0x80 or value < 0:
            value = (~value + 1) & 0xff
            value |= 0x80

        print(f"Setting value {value:02x} to {addr:04x}")

        self._machine.write_memory_byte(addr, value)

    def get_byte_result(self, addr):
        value = self._machine.read_memory_byte(addr)
        print(f"Getting value {value:02x} from {addr:04x}")

        if value >= 0x80:
            value = value & 0x7f
            value *= -1

        print(f"Returning value {value}")
        return value
    
    def set_word_argument(self, addr, value):
        if value >= 0x8000 or value < 0:
            value = (~value + 1) & 0xff
            value |= 0x8000

        print(f"Setting value {value:04x} to {addr:04x}")

        self._machine.write_memory_byte(addr, (value >> 8) & 0xff) # High byte first
        self._machine.write_memory_byte(addr + 1, value & 0xff)

    def get_word_result(self, addr):
        value = self._machine.read_memory_byte(addr) << 8   # High byte first
        value |= self._machine.read_memory_byte(addr + 1)
        print(f"Getting value {value:04x} from {addr:04x}")

        if value >= 0x8000:
            value = value & 0x7fff
            value *= -1

        print(f"Returning value {value}")
        return value
    
    def set_float_argument(self, addr, value):
        f = Float(float(value))
        fbytes = f.to_3_byte()

        print(f"Setting value {fbytes:06x} to {addr:04x}")

        self._machine.write_memory_byte(addr, (fbytes >> 16) & 0xff) # High byte first
        self._machine.write_memory_byte(addr + 1, (fbytes >> 8) & 0xff)
        self._machine.write_memory_byte(addr + 2, fbytes & 0xff)

    def get_float_result(self, addr):
        fbytes = self._machine.read_memory_byte(addr) << 16   # High byte first
        fbytes |= self._machine.read_memory_byte(addr + 1) << 8
        fbytes |= self._machine.read_memory_byte(addr + 2)

        print(f"Getting value {fbytes:06x} from {addr:04x}")

        f = Float()
        f.from_3_byte(fbytes)
        value = f.to_float()

        print(f"Returning value {value}")
        return value
    
    def run_function(self, addr):
        # Put the breakpoint to the top of the stack
        # When a calculator function will return, it will get to the 0xbeef address
        self._emulator._cpu._sp = 0xc3ee
        self._emulator._machine.write_memory_word(0xc3ee, 0xbeef) # breakpoint return address

        # Will execute function starting from the given address
        self._emulator._cpu._pc = addr

        # Run the requested function, until it returns to 0xbeef
        # Set the counter limit to avoid infinite loop
        while self._emulator._cpu._pc != 0xbeef and self._emulator._cpu._cycles < 100000000:
            self._emulator.step()

        # Validate that the code really reached the end, and not stopped by a cycles limit
        assert self._emulator._cpu._pc == 0xbeef


@pytest.fixture
def calculator():
    return Calculator()

# Argument1, Argument2, Addition result
add_numbers = [
    (1, 2, 3),
    (42, 56, 98),
    (1, -1, 0),
    (10, -15, -5),
    (10, -5, 5),
    (-10, 5, -5),
    (-10, 20, 10),
    (-10, -10, -20)
]

@pytest.mark.parametrize("arg1, arg2, res", add_numbers)
def test_add_byte(calculator, arg1, arg2, res):
    calculator.set_byte_argument(0xc371, arg1)
    calculator.set_byte_argument(0xc374, arg2)
    
    calculator.run_function(0x0849)

    assert calculator.get_byte_result(0xc374) == res


@pytest.mark.parametrize("arg1, arg2, res", add_numbers)
def test_add_2_byte(calculator, arg1, arg2, res):
    calculator.set_word_argument(0xc372, arg1)
    calculator.set_word_argument(0xc375, arg2)
    
    calculator.run_function(0x08dd)

    assert calculator.get_word_result(0xc375) == res


@pytest.mark.parametrize("arg1, arg2, res", add_numbers)
def test_add_float(calculator, arg1, arg2, res):
    calculator.set_float_argument(0xc371, arg1)
    calculator.set_float_argument(0xc374, arg2)
    
    calculator.run_function(0x0987)

    assert calculator.get_float_result(0xc374) == res


# Argument1, Argument2, Multiplication result
mult_numbers = [
    (1., 0., 0.),
    (1., 2., 2.),
    (2., 0.5, 1.),
    (3., 4., 12.),
    (-1., -5., 5.),
    (-2., 5., -10.),
]
@pytest.mark.parametrize("arg1, arg2, res", mult_numbers)
def test_mult_float(calculator, arg1, arg2, res):
    calculator.set_float_argument(0xc371, arg1)
    calculator.set_float_argument(0xc374, arg2)
    
    calculator.run_function(0x09ec)

    assert calculator.get_float_result(0xc374) == res


# Argument1, Argument2, division result
div_numbers = [
    (1., 1., 1.),
    (2., 1., 2.),
    (12345., 3., 4115.),
    (2., -4., -0.5),
    (-2., 2., -1.),
    (0., 1., 0.),
    
    # The implementation allows division by zero, but the result is random (and looks
    # correct, while it is obviously not)
    #(2., 0., 0.), 
]

@pytest.mark.parametrize("arg1, arg2, res", div_numbers)
def test_div_float(calculator, arg1, arg2, res):
    calculator.set_float_argument(0xc374, arg1) # Divident
    calculator.set_float_argument(0xc371, arg2) # Divider
    
    calculator.run_function(0x0a6f)

    assert calculator.get_float_result(0xc374) == res


# base, power, exponent result
exp_numbers = [
    (10., 0, 1.),   # exponent=0 => result=1, regardless of the value
    (20., 0, 1.),   # exponent=0 => result=1, regardless of the value
    (3., 4, 81.),
    (0.5, 3, .125),
    (2., -1, .5),
    (2., -2, .25),
]
@pytest.mark.parametrize("base, power, res", exp_numbers)
def test_exp(calculator, base, power, res):
    calculator.set_float_argument(0xc371, base)
    calculator.set_byte_argument(0xc364, power)

    calculator.run_function(0x0b08)

    assert calculator.get_float_result(0xc374) == res


# arg, logarythm result
log_numbers = [
    (1., 0.),
    (2., 0.69314718055994),
    (3., 1.09861228866811),
    (10., 2.3025850929940),
    (.5, -0.6931471805599),
]
@pytest.mark.parametrize("arg, res", log_numbers)
def test_log(calculator, arg, res):
    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0b6b)

    result = calculator.get_float_result(0xc368)
    assert pytest.approx(result, rel=0.002) == res # Accuracy could be better :(


@pytest.mark.parametrize("arg, res", log_numbers)
def test_log_python(arg, res):
    def my_log(arg):        # Python version of the firmware logarithm implementation
        a = (arg - 1) / (arg + 1)
        print(f"X = {arg}")
        print(f"A = {a}")
        res = a
        num = 1
        next = a
        while abs(next) > 0.00000001:
            num += 2.
            next = pow(a, num) / num
            res += next
            print(f"Res = {res}")
        return res * 2
    
    assert pytest.approx(my_log(arg), 0.0000001) == res

# arg, factorial result
fact_numbers = [
    (0, 1.), 
    (1, 1.),
    (3, 6.),
    (6, 720.),
    (8, 40320.),
]
@pytest.mark.parametrize("arg, res", fact_numbers)
def test_fact(calculator, arg, res):
    calculator._emulator._cpu._a = arg & 0xff

    calculator.run_function(0x0a98)

    result = calculator.get_float_result(0xc377)
    assert result == res


# arg, sine result
sin_numbers = [
    (0., 0.),
    (1., 0.8414709848),
    (1.57079632679, 1.),
    (3.14159265359, 0.),
    (3*1.57079632679, -1.),
    (2*3.14159265359, 0.),
]
@pytest.mark.parametrize("arg, res", sin_numbers)
def test_sin(calculator, arg, res):
    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0c87)

    result = calculator.get_float_result(0xc365)
    print(f"Difference = {result - res:3.10f}")
    assert pytest.approx(result, abs=0.003) == res # Accuracy could be better :(


# arg, cosine result
cosin_numbers = [
    (0., 1.),
    (1., 0.54030230586),
    (1.57079632679, 0.),
    (3.14159265359, -1.),
    (3*1.57079632679, 0.),
    (2*3.14159265359, 1.),
]
@pytest.mark.parametrize("arg, res", cosin_numbers)
def test_cos(calculator, arg, res):
    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0d32)

    result = calculator.get_float_result(0xc365)
    assert pytest.approx(result, abs=0.008) == res # Accuracy could be better :(


# arg, arcsin result
arcsin_numbers = [
    (0., 0.),
    # (1., 1.57079632679),      # These are too slow to calculate, over 100 iterations, and >10 seconds
    # (-1., -1.57079632679),    # the the resulting accuracy is too bad, +-0.08
    (0.5, 0.523598776),
    (-0.5, -0.523598776),
]
@pytest.mark.parametrize("arg, res", arcsin_numbers)
def test_arcsin(calculator, arg, res):
    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0d47)

    result = calculator.get_float_result(0xc365)
    assert pytest.approx(result, abs=0.0008) == res # Accuracy could be better :(


# arg, arccos result
arccos_numbers = [
    (0., 1.57079632679),
    (0.5, 1.04719755),
    (-0.5, 2.0943951),
    # (1., 0.),                   # These are too slow to calculate, over 100 iterations and >10 seconds
    # (-1., 3.14159265359),       # the the resulting accuracy is too bad, +-0.08
]
@pytest.mark.parametrize("arg, res", arccos_numbers)
def test_arccos(calculator, arg, res):
    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0e40)

    result = calculator.get_float_result(0xc365)
    assert pytest.approx(result, abs=0.0005) == res # Accuracy could be better :(


# arg, tg result
tg_numbers = [
    (0., 0),
    (1., 1.55740772465),
    (-1., -1.55740772465),
]
@pytest.mark.parametrize("arg, res", tg_numbers)
def test_tg(calculator, arg, res):
    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0e47)

    result = calculator.get_float_result(0xc374)
    assert pytest.approx(result, abs=0.0005) == res # Accuracy could be better :(


# arg, ctg result
ctg_numbers = [
    (1., 0.6420926159),
    (-1., -0.6420926159),
    (2., -0.4576575544),
]
@pytest.mark.parametrize("arg, res", ctg_numbers)
def test_ctg(calculator, arg, res):
    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0f61)

    result = calculator.get_float_result(0xc374)
    assert pytest.approx(result, abs=0.0005) == res # Accuracy could be better :(


# arg, arctg result
arctg_numbers = [
    (0., 0.),
    (0.5, 0.4636476090),
    (-0.5, -0.4636476090),
#    (0.9, 0.7328151018),    # These are too slow to calculate, over >5 seconds
#    (-0.9, -0.7328151018),
]
@pytest.mark.parametrize("arg, res", arctg_numbers)
def test_arctg(calculator, arg, res):
    logging.basicConfig(level=logging.DEBUG)
    calculator._machine._cpu.enable_registers_logging(True)

    nl = NestedLogger()

    calculator._emulator.add_breakpoint(0x0a92, lambda: nl.enter("STORE A-B-C to [HL]"))
    calculator._emulator.add_breakpoint(0x0a97, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0a8c, lambda: nl.enter("LOAD [HL] to A-B-C"))
    calculator._emulator.add_breakpoint(0x0a91, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0b08, lambda: nl.enter("POWER"))
    calculator._emulator.add_breakpoint(0x0b6a, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0987, lambda: nl.enter("ADD"))
    calculator._emulator.add_breakpoint(0x0993, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0a6f, lambda: nl.enter("DIV"))
    calculator._emulator.add_breakpoint(0x0a8b, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x09ec, lambda: nl.enter("MULT"))
    calculator._emulator.add_breakpoint(0x09f8, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0a98, lambda: nl.enter("FACTORIAL"))
    calculator._emulator.add_breakpoint(0x0b07, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0d47, lambda: nl.enter("ARCSIN"))
    calculator._emulator.add_breakpoint(0x0ded, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0c87, lambda: nl.enter("SINE"))
    calculator._emulator.add_breakpoint(0x0d31, lambda: nl.exit())
    calculator._emulator.add_breakpoint(0x0d32, lambda: nl.enter("COSINE"))
    calculator._emulator.add_breakpoint(0x0d46, lambda: nl.exit())

    calculator.set_float_argument(0xc361, arg)

    calculator.run_function(0x0e75)

    result = calculator.get_float_result(0xc365)
    assert pytest.approx(result, abs=0.0005) == res # Accuracy could be better :(

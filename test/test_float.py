# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for a Float - a library for working with floating point
# numbers. This is not related to the UT-88 computer emulation, but created for better
# understanding of the Calculator firmware.

import pytest
import sys

sys.path.append('../misc')

from float import *

# Test numbers. Fields are: float value, is_negative, exponent, mantissa
numbers = [
        (0., False, 0, 0),
        (1., False, 0, 0x800000),
        (0.5, False, -1, 0x800000),
        (2., False, 1, 0x800000),
        (1.5, False, 0, 0xc00000),
        (-2., True, 1, 0x800000)
    ]

# Test numbers for conversion between float and 3-byte float numbers
numbers_3b = [
    (0., 0x000000),
    (1., 0x012000),
    (1.5, 0x013000),
    (2., 0x022000),
    (-2., 0x02a000),
]

def test_new():
    f = Float()
    assert f.is_negative() == False
    assert f.get_exponent() == 0
    assert f.get_mantissa() == 0

@pytest.mark.parametrize("value, is_negative, exponent, mantissa", numbers)
def test_from_float(value, is_negative, exponent, mantissa):
    f = Float(value)
    assert f.is_negative() == is_negative
    assert f.get_exponent() == exponent
    assert f.get_mantissa() == mantissa

@pytest.mark.parametrize("value, is_negative, exponent, mantissa", numbers)
def test_to_float(value, is_negative, exponent, mantissa):
    f = Float()
    f.from_sem(is_negative, exponent, mantissa)
    assert f.to_float() == value

def test_normalize_1():
    f = Float()
    f.from_sem(False, 0, 0x200000)
    assert f.is_negative() == False
    assert f.get_exponent() == -2
    assert f.get_mantissa() == 0x800000

def test_normalize_2():
    f = Float()
    f.from_sem(False, 0, 0x2000000)
    assert f.is_negative() == False
    assert f.get_exponent() == 2
    assert f.get_mantissa() == 0x800000

@pytest.mark.parametrize("value, float3b", numbers_3b)
def test_to_3_byte(value, float3b):
    f = Float()
    f.from_float(value)
    assert f.to_3_byte() == float3b


@pytest.mark.parametrize("value, float3b", numbers_3b)
def test_from_3_byte(value, float3b):
    f = Float()
    f.from_3_byte(float3b)
    assert f.to_float() == value


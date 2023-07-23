# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for UT-88 OS Assembler and Disassembler compoents. These tests are not tests in
# general meaning, they are not supposed to _test_  anything. This is rather a handy way to run emulation
# of some functions from the UT-88 OS software bundle, in order to understand better how do they work.
#
# Tests run an emulator, load UT-88 OS components, and run required functions with certain arguments.

import pytest
import pygame

from ut88os_helper import UT88OS

@pytest.fixture
def ut88():
    return UT88OS()


def set_text(ut88, addr, text):
    for c in text:
        ut88.set_byte(addr, ord(c))
        addr += 1


def run_command(ut88, cmd):
    text = []
    ut88.emulator.add_breakpoint(0xf9f0, lambda: text.append(chr(ut88.cpu.c)))

    set_text(ut88, 0xf77b, cmd)
    ut88.cpu.hl = 0xff9c
    ut88.run_function(0xf84f)

    text = "".join(text)
    return text

def test_run_command(ut88):
    print(run_command(ut88, "DF800,F8FF\r"))

# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for Micron assembler that is a part of UT-88 OS bundle. These tests are not tests in
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


def run_command(ut88, cmd, endaddr):
    # Capture the console output
    text = []
    ut88.emulator.add_breakpoint(0xf9f0, lambda: text.append(chr(ut88.cpu.c)))

    set_text(ut88, 0xf77b, cmd + "\r")
    ut88.cpu.hl = 0xff9c
    ut88.run_function(0xf84f, endaddr)

    text = "".join(text)
    return text


def run_assembler(ut88, text, mode = "1", command = "B"):
    # Set the source code to assemble
    addr = 0x3000
    for c in (text + "\r"):
        ut88.set_byte(addr, ord(c))
        addr += 1
    
    # Terminate with a charcode 0xff
    ut88.set_byte(addr, 0xff)

    # The Micron assembler expects the User to enter operation mode at start
    ut88.emulate_key_sequence(mode + "?")   # '?' will generate an error input, to catch end of program execution

    # Skip check for Ctrl-C press after each processed line
    ut88.emulator.add_breakpoint(0xd8ce, lambda: ut88.cpu.set_pc(0xd8d6))

    # Run the assembler command
    text = run_command(ut88, command, 0xd81f)   # Stop at '?' incorrect mode input
    return text.replace('\r', '\n')


def test_assembler_comment(ut88):
    # Symbols after semicolon are ignored
    asm = "; This is a comment  "    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00   # No any bytes in the output


def test_assembler_no_arg_instruction1(ut88):
    asm = "NOP"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00


def test_assembler_no_arg_instruction2(ut88):
    asm = "DAA"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x27


def test_assembler_mov_two_reg(ut88):
    # Instruction with both source and destination register specified
    asm = "MOV A,B"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x78


def test_assembler_op_with_reg_arg(ut88):
    # Instruction with source register argument specified
    asm = "ADC E"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x8b


def test_assembler_mvi(ut88):
    # Instruction with source register specified
    asm = "MVI C, 123"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x0e
    assert ut88.get_byte(0xa001) == 0x7b # 123 dec = 0x7b

def test_assembler_lxi(ut88):
    # Instruction with LXI instruction (register pair and 2-byte immediate argument)
    asm = "LXI SP, 0ABCDH"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x31
    assert ut88.get_byte(0xa001) == 0xcd
    assert ut88.get_byte(0xa002) == 0xab


def test_assembler_jmp(ut88):
    # Instruction with no registers, just value
    asm = "JMP 0ABCDH"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3
    assert ut88.get_byte(0xa001) == 0xcd
    assert ut88.get_byte(0xa002) == 0xab


def test_assembler_jmp_alt(ut88):
    # Alternate version of JMP
    asm = "J 0ABCDH"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3
    assert ut88.get_byte(0xa001) == 0xcd
    assert ut88.get_byte(0xa002) == 0xab


def test_assembler_inx(ut88):
    # 1-byte instruction with register pair coded in 4-5th bits
    asm = "INX D"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x13


def test_assembler_push_pop(ut88):
    # 1-byte instruction with register pair coded in 4-5th bits (PSW is coded in a special way)
    asm = "PUSH PSW"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xf5


def test_assembler_ldax_stax(ut88):
    # 1-byte instruction with register pair coded in 4-5th bits
    asm = "LDAX D"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x1a


def test_assembler_rst(ut88):
    # 1-byte instruction with rst number coded in the opcode
    asm = "RST 5"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xef


def test_assembler_symb_arg(ut88):
    # Use a symbolic (char) byte argument
    asm = "MVI C, 'A'"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x0e
    assert ut88.get_byte(0xa001) == ord('A')

def test_assembler_two_symb_arg(ut88):
    # Use two-char symbol argument
    asm = "LXI H, 'AB'"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x21
    assert ut88.get_byte(0xa001) == ord('A')    # First symbol goes low byte?
    assert ut88.get_byte(0xa002) == ord('B')


def test_assembler_cur_addr_arg(ut88):
    # Use '$' as current address
    asm = "JMP $"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3
    assert ut88.get_byte(0xa001) == 0x00
    assert ut88.get_byte(0xa002) == 0xa0


def test_assembler_db(ut88):
    # Use DB directive for raw data
    asm = "DB 42H, 123, 'A', 'QWE'"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x42
    assert ut88.get_byte(0xa001) == 123
    assert ut88.get_byte(0xa002) == ord('A')
    assert ut88.get_byte(0xa003) == ord('Q')
    assert ut88.get_byte(0xa004) == ord('W')
    assert ut88.get_byte(0xa005) == ord('E')


def test_assembler_dw(ut88):
    # Use DW directive for raw data words
    asm = "DW 1234H, 12345, 'AB', 'QWER'"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x34        # 0x1234
    assert ut88.get_byte(0xa001) == 0x12

    assert ut88.get_byte(0xa002) == 0x39        # 12345 dec
    assert ut88.get_byte(0xa003) == 0x30
    
    assert ut88.get_byte(0xa004) == ord('A')    # Pair of symbols
    assert ut88.get_byte(0xa005) == ord('B')

    assert ut88.get_byte(0xa006) == ord('Q')    # String
    assert ut88.get_byte(0xa007) == ord('W')
    assert ut88.get_byte(0xa008) == 0x00        # DW does not support strings that are more than 2 chars
    assert ut88.get_byte(0xa009) == 0x00


def test_assembler_ds(ut88):
    # Use DS directive to set up non-default target location
    asm  = "DS 42H\r"
    asm += "RST 5"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa042) == 0xef    # The RST instruction at 0xa000 + 0x42


# TODO: Add test for +/- in the argument

def test_assembler_org(ut88):
    asm =  "ORG 1234H\r"
    asm += "JMP $"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3    # Storage address remains the same - 0xa000
    assert ut88.get_byte(0xa001) == 0x34    # But JMP argument gets value passed in ORG - 0x1234
    assert ut88.get_byte(0xa002) == 0x12

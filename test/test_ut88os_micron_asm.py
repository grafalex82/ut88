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
    return text.replace('\r\n', '\n')


def test_comment(ut88):
    # Symbols after semicolon are ignored
    asm = "; This is a comment  "    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00   # No any bytes in the output


def test_no_arg_instruction1(ut88):
    asm = "NOP"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00


def test_no_arg_instruction2(ut88):
    asm = "DAA"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x27


def test_mov_two_reg(ut88):
    # Instruction with both source and destination register specified
    asm = "MOV A,B"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x78


def test_op_with_reg_arg(ut88):
    # Instruction with source register argument specified
    asm = "ADC E"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x8b


def test_mvi(ut88):
    # Instruction with source register specified
    asm = "MVI C, 123"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x0e
    assert ut88.get_byte(0xa001) == 0x7b # 123 dec = 0x7b

def test_lxi(ut88):
    # Instruction with LXI instruction (register pair and 2-byte immediate argument)
    asm = "LXI SP, 0ABCDH"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x31
    assert ut88.get_byte(0xa001) == 0xcd
    assert ut88.get_byte(0xa002) == 0xab


def test_jmp(ut88):
    # Instruction with no registers, just value
    asm = "JMP 0ABCDH"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3
    assert ut88.get_byte(0xa001) == 0xcd
    assert ut88.get_byte(0xa002) == 0xab


def test_jmp_alt(ut88):
    # Alternate version of JMP
    asm = "J 0ABCDH"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3
    assert ut88.get_byte(0xa001) == 0xcd
    assert ut88.get_byte(0xa002) == 0xab


def test_inx(ut88):
    # 1-byte instruction with register pair coded in 4-5th bits
    asm = "INX D"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x13


def test_push_pop(ut88):
    # 1-byte instruction with register pair coded in 4-5th bits (PSW is coded in a special way)
    asm = "PUSH PSW"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xf5


def test_ldax_stax(ut88):
    # 1-byte instruction with register pair coded in 4-5th bits
    asm = "LDAX D"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x1a


def test_rst(ut88):
    # 1-byte instruction with rst number coded in the opcode
    asm = "RST 5"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xef


def test_symb_arg(ut88):
    # Use a symbolic (char) byte argument
    asm = "MVI C, 'A'"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x0e
    assert ut88.get_byte(0xa001) == ord('A')

def test_two_symb_arg(ut88):
    # Use two-char symbol argument
    asm = "LXI H, 'AB'"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x21
    assert ut88.get_byte(0xa001) == ord('A')    # First symbol goes low byte?
    assert ut88.get_byte(0xa002) == ord('B')


def test_cur_addr_arg(ut88):
    # Use '$' as current address
    asm = "JMP $"    
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3
    assert ut88.get_byte(0xa001) == 0x00
    assert ut88.get_byte(0xa002) == 0xa0


def test_db(ut88):
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


def test_dw(ut88):
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


def test_ds(ut88):
    # Use DS directive to set up non-default target location
    asm  = "DS 42H\r"
    asm += "RST 5"
    text = run_assembler(ut88, asm, mode='2')
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa042) == 0xef    # The RST instruction at 0xa000 + 0x42

    # Verify listing output
    assert 'A000 ( 0042 )    DS 42H' in text    # DS instruction prints storage and storage offset value

def test_org(ut88):
    asm =  "ORG 1234H\r"
    asm += "JMP $"
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3    # Storage address remains the same - 0xa000
    assert ut88.get_byte(0xa001) == 0x34    # But JMP argument gets value passed in ORG - 0x1234
    assert ut88.get_byte(0xa002) == 0x12


def test_label(ut88):
    asm  = "QQ: NOP\r"
    asm += "WW: NOP\r"
    asm += "CALL QQ\r"
    asm += "JMP WW"

    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00    # 1st NOP
    assert ut88.get_byte(0xa001) == 0x00    # 2nd NOP

    assert ut88.get_byte(0xa002) == 0xcd    # CALL
    assert ut88.get_byte(0xa003) == 0x00    # Address of the first NOP
    assert ut88.get_byte(0xa004) == 0xa0

    assert ut88.get_byte(0xa005) == 0xc3    # JMP
    assert ut88.get_byte(0xa006) == 0x01    # Address of the second NOP
    assert ut88.get_byte(0xa007) == 0xa0


def test_arithmetic(ut88):
    asm  = "QQ: NOP\r"
    asm += "JMP $ - QQ\r"   # Use arithmetic in immediate value, use label in the arithmetic
    asm += "MVI C, -5\r"    # Use <nothing> - 5 expression
    asm += "SHLD QQ + 5\r"  # Use label in sum expression
    asm += "SBI '0' + 5\r"  # Use Char as a value
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00    # 1st NOP

    assert ut88.get_byte(0xa001) == 0xc3    # JMP
    assert ut88.get_byte(0xa002) == 0x01    # Difference between 2 addresses is 1
    assert ut88.get_byte(0xa003) == 0x00

    assert ut88.get_byte(0xa004) == 0x0e    # MVI C
    assert ut88.get_byte(0xa005) == 0xfb    # -5

    assert ut88.get_byte(0xa006) == 0x22    # SHLD
    assert ut88.get_byte(0xa007) == 0x05    # QQ (0xa000) + 5
    assert ut88.get_byte(0xa008) == 0xa0

    assert ut88.get_byte(0xa009) == 0xde    # SBI
    assert ut88.get_byte(0xa00a) == 0x35    # '0' + 5


def test_equ(ut88):
    asm  = "QQ: EQU 12345\r"    # Set value for QQ
    asm += "JMP QQ"             # Use QQ value
    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3    # JMP
    assert ut88.get_byte(0xa001) == 0x39    # Use QQ value (0x3039 = 12345 dec)
    assert ut88.get_byte(0xa002) == 0x30



def test_double_label(ut88):
    asm  = "QQ: NOP\r"
    asm += "QQ: NOP\r"
    asm += "JMP QQ"

    text = run_assembler(ut88, asm)
    print(text)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00    # 1st NOP
    assert ut88.get_byte(0xa001) == 0x00    # 2nd NOP

    assert ut88.get_byte(0xa002) == 0xc3    # CALL
    assert ut88.get_byte(0xa003) == 0xff    # Address of the label is set to 0xffff
    assert ut88.get_byte(0xa004) == 0xff


def test_syntax_errors(ut88):
    asm  = "ORG 1234H\r"    # Set target address

    asm += "NOP 0ABCH\r"    # Unexpected immediate value
    asm += "MVI A, B\r"     # Register name instead of immediate value
    asm += "ORA 12345"      # Immediate value instead of register name

    text = run_assembler(ut88, asm, mode="2")
    print(text)

    assert "08*1234             NOP 0ABCH" in text
    assert "08*1234             MVI A, B" in text
    assert "08*1234             ORA 12345" in text
    assert "ERRORS DETECTED:03" in text


def test_label_errors(ut88):
    asm  = "AA NOP\r"       # Syntax error while defining a label
    asm += "MVI A, BB\r"    # Usage of not defined label
    asm += "QQ EQU 12345"   # Syntax error in EQU line (missing ':')

    text = run_assembler(ut88, asm, mode="2")
    print(text)

    assert "04*A000             AA NOP" in text
    assert "02*A000 3E FE       MVI A, BB" in text
    assert "04*A002             QQ EQU 12345" in text
    assert "ERRORS DETECTED:03" in text


def test_normal_output(ut88):
    asm  = "ORG 1234H\r"    # Set target address
    asm += "NOP\r"          # Just a 'normal' program
    asm += "QQ: EQU 1234\r" # Use an EQU directive
    asm += "DB 5, 6, 7, 8, 'ABCD'\r"    # Use some random data
    asm += "HLT"

    text = run_assembler(ut88, asm, mode="2")
    print(text)

    assert "                 ORG" in text       # ORG directive does not generate a opcode
    assert "1234 00          NOP" in text       # Both instructions are in the listing
    assert "04D2             QQ: EQU 1234" in text  # QQ Label value is in the listing
    assert "1235 05 06 07 08 DB 5, 6, 7, 8, 'ABCD'" in text  # DB instruction are dumped 4 bytes at a time
    assert "1239 41 42 43 44" in text           # Remainder of bytes are dumped on the next line
    assert "123D 76          HLT" in text       # Both instructions have ORG offset applied
    assert "ERRORS DETECTED:00" in text         # No errors detected
    assert "123D/A009/" in text                 # Last target and storage addresses are correct


def test_use_future_label(ut88):
    asm  = "JMP QQ\r"       # Use label defined in future
    asm += "NOP\r"          # Just a spacer instruction
    asm += "QQ: MOV A, B"   # Define QQ label referenced earlier

    text = run_assembler(ut88, asm, mode="1")
    print(text)

    assert ut88.get_byte(0xa000) == 0xc3    # JMP
    assert ut88.get_byte(0xa001) == 0x04    # Future label address calculated correctly
    assert ut88.get_byte(0xa002) == 0xa0
    assert ut88.get_byte(0xa003) == 0x00    # NOP
    assert ut88.get_byte(0xa004) == 0x78    # MOV A, B


def test_labels_summary(ut88):
    asm  = "QQ: EQU 1234H\r"    # An EQU directive
    asm += "WW: EQU 5678H\r"    # Another EQU directive
    asm += "EE: NOP\r"          # Normal instruction with a label
    asm += "RR: NOP"            # Another instruction with a label

    text = run_assembler(ut88, asm, mode="3")
    print(text)

    assert "QQ    = 1234"
    assert "WW    = 5678"
    assert "EE    = A000"
    assert "RR    = A001"
    assert "ERRORS DETECTED:00" in text         # No errors detected
    assert "A001/A001/" in text                 # Last target and storage addresses are correct

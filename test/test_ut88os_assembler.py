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

    set_text(ut88, 0xf77b, cmd + "\r")
    ut88.cpu.hl = 0xff9c
    ut88.run_function(0xf84f)

    text = "".join(text)
    return text


def run_assembler(ut88, text, command = "A"):
    # Set the source code to assemble
    addr = 0x3000
    for c in text + '\r':
        ut88.set_byte(addr, ord(c))
        addr += 1
    
    # Terminate with a charcode >= 0x80
    ut88.set_byte(addr, 0x80)

    # Run the assembler command
    text = run_command(ut88, command)
    return text.replace('\r', '\n')


def test_assembler_comment(ut88):
    # Symbols after semicolon are ignored
    asm = "    ; ABCDEF"    
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x00   # No any bytes in the output


def test_assembler_set_label(ut88):
    # Set the label #12 for an instruction
    asm = "@12: MOV  A,B"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x78    # Instruction opcode

    assert ut88.get_byte(0xf424) == 0x00    # Item #12 in the labels table (0xf400 + 12*2 = 0xf424) contains
    assert ut88.get_byte(0xf425) == 0xa0    # the instruction address


def test_assembler_1b_instruction_no_arg(ut88):
    # Assemble a single 1-byte instruction
    asm = "EI  "      # Implementation is buggy, and does not accept 2-char instruction without spaces at end
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xfb   # EI instruction code


def test_assembler_2b_instruction_immediate(ut88):
    # Assemble a single 2-byte instruction without register specification
    asm = "    ADI      42    "   # Add some extra spaces
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc6   # ADI opcode
    assert ut88.get_byte(0xa001) == 0x42   # Immediate operand


def test_assembler_2b_instruction_symb_arg(ut88):
    # Assemble a single 2-byte instruction with a symbol as immediate argument
    asm = "    ADI      'Q'"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc6        # ADI opcode
    assert ut88.get_byte(0xa001) == ord('Q')    # immediate argument


def test_assembler_2b_instruction_decimal_arg(ut88):
    # Assemble a single 2-byte instruction with a decimal number as an immediate argument
    asm = "    ADI      #123"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc6    # ADI opcode
    assert ut88.get_byte(0xa001) == 123     # immediate argument


def test_assembler_3b_instruction_immediate(ut88):
    # Assemble a single 3-byte instruction without register specification
    asm = "JMP 1234"   # Add some extra spaces
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3   # JMP opcode
    assert ut88.get_byte(0xa001) == 0x34   # Immediate operand low byte
    assert ut88.get_byte(0xa002) == 0x12   # Immediate operand high byte


def test_assembler_3b_instruction_decimal_arg(ut88):
    # Assemble a single 3-byte instruction with a decimal number as an immediate argument
    asm = "JMP #12345"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3    # JMP opcode
    assert ut88.get_byte(0xa001) == 0x39    # 12345 dec = 0x3039 hex
    assert ut88.get_byte(0xa002) == 0x30


def test_assembler_3b_instruction_label_ref_arg(ut88):
    # Fill the reference #12
    ut88.set_byte(0xf424, 0x34)
    ut88.set_byte(0xf425, 0x56)

    # Assemble a single 3-byte instruction with a label reference as an argument
    # If a label reference is the only argument provided, the target instruction will contain
    # reference address, to be processed during phase2.
    asm = "JMP @12"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3    # JMP opcode
    assert ut88.get_byte(0xa001) == 0x24    # Argument is a reference address (0xf400 + 12*2 = 0xf424)
    assert ut88.get_byte(0xa002) == 0xf4


def test_assembler_3b_instruction_arithmetic_arg(ut88):
    # Fill the reference #12
    ut88.set_byte(0xf424, 0x34)
    ut88.set_byte(0xf425, 0x56)

    # Assemble a single 3-byte instruction with a label reference as well as some arithmetic
    # If a label reference is a part of arithmetic expression, the reference value will be loaded from
    # reference area, and the expression will be calculated in runtime (see previous test for other behavior)
    asm = "JMP @12 + 5"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3    # JMP opcode
    assert ut88.get_byte(0xa001) == 0x39    # If the reference is used in arithmetic, the reference value will
    assert ut88.get_byte(0xa002) == 0x56    # be substituted at compile time (0x5634 + 5 = 0x5639)


def test_assembler_3b_instruction_immediate_cur_addr(ut88):
    # Use $ to refer current instruction address
    asm = "JMP $"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0xc3   # JMP opcode
    assert ut88.get_byte(0xa001) == 0x00   # Instruction address
    assert ut88.get_byte(0xa002) == 0xa0


def test_assembler_1b_instruction_src_reg(ut88):
    # Assemble a single 1-byte instruction that refers to a source register
    asm = "ADC D"      
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x8a   # ADC D instruction opcode


def test_assembler_1b_instruction_regpair(ut88):
    # Assemble a single 1-byte instruction that refers to a register pair
    asm = "DAD B"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x09   # DAD B instruction opcode


def test_assembler_1b_instruction_dst_reg(ut88):
    # Assemble a single 1-byte instruction that refers to a destination register
    asm = "DCR C"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x0d   # DCR C instruction opcode


def test_assembler_1b_instruction_dst_regpair(ut88):
    # Assemble a single 1-byte instruction that refers to a destination register pair
    asm = "LDAX D"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x1a   # LDAX D instruction opcode


def test_assembler_mov(ut88):
    # Assemble a single 1-byte instruction that refers to src and dest registers (MOV)
    asm = "MOV M, E"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x73   # MOV M, E instruction opcode


def test_assembler_lxi(ut88):
    # Assemble a single 3-byte instruction that refers to a register pair and immediate 16-bit value (LXI)
    asm = "LXI S, 1234"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x31   # LXI SP instruction opcode
    assert ut88.get_byte(0xa001) == 0x34   # Immediate operand low byte
    assert ut88.get_byte(0xa002) == 0x12   # Immediate operand high byte


def test_assembler_mvi(ut88):
    # Assemble a single 2-byte instruction that refers to a register and immediate 8-bit value (MVI)
    asm = "MVI M, 42"
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x36   # MVI M instruction opcode
    assert ut88.get_byte(0xa001) == 0x42   # Immediate operand low byte


def test_assembler_db(ut88):
    # Assemble a single data byte
    asm = "DB   34"   # Extra spaces after 'DB', otherwise 2-char directive is not matched
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x34   # just data byte


def test_assembler_db_multiple_bytes(ut88):
    # Assemble a several data bytes
    asm = "DB   12, 34, 56, EF"   # Extra spaces after 'DB', otherwise 2-char directive is not matched
    run_assembler(ut88, asm)

    # Verify the data bytes are placed accordingly
    assert ut88.get_byte(0xa000) == 0x12
    assert ut88.get_byte(0xa001) == 0x34
    assert ut88.get_byte(0xa002) == 0x56
    assert ut88.get_byte(0xa003) == 0xef


def test_assembler_db_arithmetic(ut88):
    # Use arithmetic
    asm =  "DB   12+34\r"   # Extra spaces after 'DB', otherwise 2-char directive is not matched
    asm += "DB   78-56\r"
    asm += "DB   12+34-56+78"
    run_assembler(ut88, asm)

    # Verify the data bytes are placed accordingly
    assert ut88.get_byte(0xa000) == 0x12 + 0x34
    assert ut88.get_byte(0xa001) == 0x78 - 0x56
    assert ut88.get_byte(0xa002) == 0x12 + 0x34 - 0x56 + 0x78


def test_assembler_db_symbolic(ut88):
    # Use symbolic values
    asm =  "DB   'A'\r"         # Single char
    asm += "DB   'BCD'\r"       # String
    asm += "DB   'EF', 'GH'\r"  # Several strings
    asm += "DB   '''"           # Tripple single quote

    run_assembler(ut88, asm)

    # Verify the data bytes are placed accordingly
    assert ut88.get_byte(0xa000) == ord('A')    # Single char

    assert ut88.get_byte(0xa001) == ord('B')    # String
    assert ut88.get_byte(0xa002) == ord('C')
    assert ut88.get_byte(0xa003) == ord('D')

    assert ut88.get_byte(0xa004) == ord('E')    # Several strings
    assert ut88.get_byte(0xa005) == ord('F')
    assert ut88.get_byte(0xa006) == ord('G')
    assert ut88.get_byte(0xa007) == ord('H')

    assert ut88.get_byte(0xa008) == ord("'")    # Single quote symbol


def test_assembler_db_ref(ut88):
    # Fill the reference #12
    ut88.set_byte(0xf424, 0x34)
    ut88.set_byte(0xf425, 0x56)

    # data byte is the reference
    asm = "DB   @12"    # Extra spaces after 'DB', otherwise 2-char directive is not matched
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x34   # Low byte of the reference is added
    assert ut88.get_byte(0xa001) == 0x00   # High byte is NOT added (remains zero)


def test_assembler_dw(ut88):
    # Assemble a single data word (2 bytes)
    asm = "DW   1234"   # Extra spaces after 'DB', otherwise 2-char directive is not matched
    run_assembler(ut88, asm)

    # Verify the bytes are assembled
    assert ut88.get_byte(0xa000) == 0x34   # low byte
    assert ut88.get_byte(0xa001) == 0x12   # high byte


def test_assembler_dw_multiple(ut88):
    # Assemble several data words
    asm =  "DW   1234, 5678"   # Extra spaces after 'DW', otherwise 2-char directive is not matched
    run_assembler(ut88, asm)

    # Verify the bytes are assembled
    assert ut88.get_byte(0xa000) == 0x34   # low byte
    assert ut88.get_byte(0xa001) == 0x12   # high byte
    assert ut88.get_byte(0xa002) == 0x78   # low byte
    assert ut88.get_byte(0xa003) == 0x56   # high byte


def test_assembler_dw_ref(ut88):
    # Fill the reference #12
    ut88.set_byte(0xf424, 0x34)
    ut88.set_byte(0xf425, 0x56)

    # data byte is the reference
    asm = "DW   @12"   # Extra spaces after 'DW', otherwise 2-char directive is not matched
    run_assembler(ut88, asm)

    # Verify the instruction is assembled
    assert ut88.get_byte(0xa000) == 0x34   # Low byte of the reference is added
    assert ut88.get_byte(0xa001) == 0x56   # High byte of the reference is there as well


def test_assembler_org(ut88):
    # Assemble several data words
    asm =  "ORG 1234\r"     # Set the ORG
    asm += "JMP $"        # JMP instruction refers to self
    print(run_assembler(ut88, asm))

    # Verify the instruction is assembled at address specified in ORG instruction
    assert ut88.get_byte(0x1234) == 0xc3   # JMP opcode
    assert ut88.get_byte(0x1235) == 0x34   # Instruction address is the one specified in ORG
    assert ut88.get_byte(0x1236) == 0x12


def test_assembler_equ(ut88):
    # Assign label #12 a value of 5678
    asm =  "@12:    EQU   5678"
    run_assembler(ut88, asm)

    # Check the value at labels area
    assert ut88.get_byte(0xf424) == 0x78    # Item #12 in the labels table (0xf400 + 12*2 = 0xf424) contains
    assert ut88.get_byte(0xf425) == 0x56    # the value assigned with EQU directive


def test_assembler_dir(ut88):
    # Execute Monitor's Dump command right while processing assembler source
    asm =  "DIR  DF800,F807"
    text = run_assembler(ut88, asm)

    assert "F800 C3 1B F8 C3 6B F8 C3 36" in text


def test_assembler_two_pass_sequentally(ut88):
    # JUMP to a label located further in code
    asm =  "JMP  @12\r"
    asm += "@12: NOP "
    run_assembler(ut88, asm)

    # Check the value at labels area
    assert ut88.get_byte(0xf424) == 0x03    # Value of the label #12 (0xa003 - location where @12: found)
    assert ut88.get_byte(0xf425) == 0xa0

    assert ut88.get_byte(0xa000) == 0xc3    # JMP
    assert ut88.get_byte(0xa001) == 0x24    # Reference to label #12
    assert ut88.get_byte(0xa002) == 0xf4
    assert ut88.get_byte(0xa003) == 0x00    # NOP

    run_command(ut88, "@ A000,A003")

    assert ut88.get_byte(0xa001) == 0x03    # Reference substituted with actual value
    assert ut88.get_byte(0xa002) == 0xa0


def test_assembler_two_pass_together(ut88):
    # Jump to a label declared later in code
    asm =  "JMP  @12\r"
    asm += "@12:    NOP "
    run_assembler(ut88, asm, "A@")  # A@ command runs both assembler passes

    # Check the value at labels area
    assert ut88.get_byte(0xf424) == 0x03    # Value of the label #12 (0xa003 - location where @12: found)
    assert ut88.get_byte(0xf425) == 0xa0

    assert ut88.get_byte(0xa000) == 0xc3    # JMP
    assert ut88.get_byte(0xa001) == 0x03    # Reference substituted with actual value
    assert ut88.get_byte(0xa002) == 0xa0
    assert ut88.get_byte(0xa003) == 0x00    # NOP

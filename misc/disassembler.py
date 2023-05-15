import argparse
import struct
import re

class Disassembler:
    def __init__(self, binfile, startaddr):
        with open(binfile, mode='rb') as f:
            self._data = f.read()

        self._startaddr = int(startaddr, 16)
        self._endaddr = self._startaddr + len(self._data)

        self._init_instruction_table()

    def _init_instruction_table(self):
        self._instructions = [None] * 0x100

        self._instructions[0x00] = "NOP"
        self._instructions[0x01] = "LXI BC, {a16}"
        self._instructions[0x02] = "STAX BC"
        self._instructions[0x03] = "INX BC"
        self._instructions[0x04] = "INR B"
        self._instructions[0x05] = "DCR B"
        self._instructions[0x06] = "MVI B, {d8}"
        self._instructions[0x07] = "RLC"
        self._instructions[0x08] = "db 08"
        self._instructions[0x09] = "DAD BC"
        self._instructions[0x0a] = "LDAX BC"
        self._instructions[0x0b] = "DCX BC"
        self._instructions[0x0c] = "INR C"
        self._instructions[0x0d] = "DCR C"
        self._instructions[0x0e] = "MVI C, {d8}"
        self._instructions[0x0f] = "RRC"

        self._instructions[0x10] = "db 10"
        self._instructions[0x11] = "LXI DE, {a16}"
        self._instructions[0x12] = "STAX DE"
        self._instructions[0x13] = "INX DE"
        self._instructions[0x14] = "INR D"
        self._instructions[0x15] = "DCR D"
        self._instructions[0x16] = "MVI D, {d8}"
        self._instructions[0x17] = "RAL"
        self._instructions[0x18] = "db 18"
        self._instructions[0x19] = "DAD DE"
        self._instructions[0x1a] = "LDAX DE"
        self._instructions[0x1b] = "DCX DE"
        self._instructions[0x1c] = "INR E"
        self._instructions[0x1d] = "DCR E"
        self._instructions[0x1e] = "MVI E, {d8}"
        self._instructions[0x1f] = "RAR"

        self._instructions[0x20] = "db 20"
        self._instructions[0x21] = "LXI HL, {a16}"
        self._instructions[0x22] = "SHLD {a16}"
        self._instructions[0x23] = "INX HL"
        self._instructions[0x24] = "INR H"
        self._instructions[0x25] = "DCR H"
        self._instructions[0x26] = "MVI H, {d8}"
        self._instructions[0x27] = "DAA"
        self._instructions[0x28] = "db 28"
        self._instructions[0x29] = "DAD HL"
        self._instructions[0x2a] = "LHLD {a16}"
        self._instructions[0x2b] = "DCX HL"
        self._instructions[0x2c] = "INR L"
        self._instructions[0x2d] = "DCR L"
        self._instructions[0x2e] = "MVI L, {d8}"
        self._instructions[0x2f] = "CMA"

        self._instructions[0x30] = "db 30"
        self._instructions[0x31] = "LXI SP, {a16}"
        self._instructions[0x32] = "STA {a16}"
        self._instructions[0x33] = "INX SP"
        self._instructions[0x34] = "INR M"
        self._instructions[0x35] = "DCR M"
        self._instructions[0x36] = "MVI M, {d8}"
        self._instructions[0x37] = "STC"
        self._instructions[0x38] = "db 38"
        self._instructions[0x39] = "DAD SP"
        self._instructions[0x3a] = "LDA {a16}"
        self._instructions[0x3b] = "DCX SP"
        self._instructions[0x3c] = "INR A"
        self._instructions[0x3d] = "DCR A"
        self._instructions[0x3e] = "MVI A, {d8}"
        self._instructions[0x3f] = "CMC"

        self._instructions[0x40] = "MOV B, B"
        self._instructions[0x41] = "MOV B, C"
        self._instructions[0x42] = "MOV B, D"
        self._instructions[0x43] = "MOV B, E"
        self._instructions[0x44] = "MOV B, H"
        self._instructions[0x45] = "MOV B, L"
        self._instructions[0x46] = "MOV B, M"
        self._instructions[0x47] = "MOV B, A"
        self._instructions[0x48] = "MOV C, B"
        self._instructions[0x49] = "MOV C, C"
        self._instructions[0x4a] = "MOV C, D"
        self._instructions[0x4b] = "MOV C, E"
        self._instructions[0x4c] = "MOV C, H"
        self._instructions[0x4d] = "MOV C, L"
        self._instructions[0x4e] = "MOV C, M"
        self._instructions[0x4f] = "MOV C, A"

        self._instructions[0x50] = "MOV D, B"
        self._instructions[0x51] = "MOV D, C"
        self._instructions[0x52] = "MOV D, D"
        self._instructions[0x53] = "MOV D, E"
        self._instructions[0x54] = "MOV D, H"
        self._instructions[0x55] = "MOV D, L"
        self._instructions[0x56] = "MOV D, M"
        self._instructions[0x57] = "MOV D, A"
        self._instructions[0x58] = "MOV E, B"
        self._instructions[0x59] = "MOV E, C"
        self._instructions[0x5a] = "MOV E, D"
        self._instructions[0x5b] = "MOV E, E"
        self._instructions[0x5c] = "MOV E, H"
        self._instructions[0x5d] = "MOV E, L"
        self._instructions[0x5e] = "MOV E, M"
        self._instructions[0x5f] = "MOV E, A"

        self._instructions[0x60] = "MOV H, B"
        self._instructions[0x61] = "MOV H, C"
        self._instructions[0x62] = "MOV H, D"
        self._instructions[0x63] = "MOV H, E"
        self._instructions[0x64] = "MOV H, H"
        self._instructions[0x65] = "MOV H, L"
        self._instructions[0x66] = "MOV H, M"
        self._instructions[0x67] = "MOV H, A"
        self._instructions[0x68] = "MOV L, B"
        self._instructions[0x69] = "MOV L, C"
        self._instructions[0x6a] = "MOV L, D"
        self._instructions[0x6b] = "MOV L, E"
        self._instructions[0x6c] = "MOV L, H"
        self._instructions[0x6d] = "MOV L, L"
        self._instructions[0x6e] = "MOV L, M"
        self._instructions[0x6f] = "MOV L, A"

        self._instructions[0x70] = "MOV M, B"
        self._instructions[0x71] = "MOV M, C"
        self._instructions[0x72] = "MOV M, D"
        self._instructions[0x73] = "MOV M, E"
        self._instructions[0x74] = "MOV M, H"
        self._instructions[0x75] = "MOV M, L"
        self._instructions[0x76] = "HLT"
        self._instructions[0x77] = "MOV M, A"
        self._instructions[0x78] = "MOV A, B"
        self._instructions[0x79] = "MOV A, C"
        self._instructions[0x7a] = "MOV A, D"
        self._instructions[0x7b] = "MOV A, E"
        self._instructions[0x7c] = "MOV A, H"
        self._instructions[0x7d] = "MOV A, L"
        self._instructions[0x7e] = "MOV A, M"
        self._instructions[0x7f] = "MOV A, A"

        self._instructions[0x80] = "ADD B"
        self._instructions[0x81] = "ADD C"
        self._instructions[0x82] = "ADD D"
        self._instructions[0x83] = "ADD E"
        self._instructions[0x84] = "ADD H"
        self._instructions[0x85] = "ADD L"
        self._instructions[0x86] = "ADD M"
        self._instructions[0x87] = "ADD A"
        self._instructions[0x88] = "ADC B"
        self._instructions[0x89] = "ADC C"
        self._instructions[0x8a] = "ADC D"
        self._instructions[0x8b] = "ADC E"
        self._instructions[0x8c] = "ADC H"
        self._instructions[0x8d] = "ADC L"
        self._instructions[0x8e] = "ADC M"
        self._instructions[0x8f] = "ADC A"

        self._instructions[0x90] = "SUB B"
        self._instructions[0x91] = "SUB C"
        self._instructions[0x92] = "SUB D"
        self._instructions[0x93] = "SUB E"
        self._instructions[0x94] = "SUB H"
        self._instructions[0x95] = "SUB L"
        self._instructions[0x96] = "SUB M"
        self._instructions[0x97] = "SUB A"
        self._instructions[0x98] = "SBB B"
        self._instructions[0x99] = "SBB C"
        self._instructions[0x9a] = "SBB D"
        self._instructions[0x9b] = "SBB E"
        self._instructions[0x9c] = "SBB H"
        self._instructions[0x9d] = "SBB L"
        self._instructions[0x9e] = "SBB M"
        self._instructions[0x9f] = "SBB A"

        self._instructions[0xa0] = "ANA B"
        self._instructions[0xa1] = "ANA C"
        self._instructions[0xa2] = "ANA D"
        self._instructions[0xa3] = "ANA E"
        self._instructions[0xa4] = "ANA H"
        self._instructions[0xa5] = "ANA L"
        self._instructions[0xa6] = "ANA M"
        self._instructions[0xa7] = "ANA A"
        self._instructions[0xa8] = "XRA B"
        self._instructions[0xa9] = "XRA C"
        self._instructions[0xaa] = "XRA D"
        self._instructions[0xab] = "XRA E"
        self._instructions[0xac] = "XRA H"
        self._instructions[0xad] = "XRA L"
        self._instructions[0xae] = "XRA M"
        self._instructions[0xaf] = "XRA A"

        self._instructions[0xb0] = "ORA B"
        self._instructions[0xb1] = "ORA C"
        self._instructions[0xb2] = "ORA D"
        self._instructions[0xb3] = "ORA E"
        self._instructions[0xb4] = "ORA H"
        self._instructions[0xb5] = "ORA L"
        self._instructions[0xb6] = "ORA M"
        self._instructions[0xb7] = "ORA A"
        self._instructions[0xb8] = "CMP B"
        self._instructions[0xb9] = "CMP C"
        self._instructions[0xba] = "CMP D"
        self._instructions[0xbb] = "CMP E"
        self._instructions[0xbc] = "CMP H"
        self._instructions[0xbd] = "CMP L"
        self._instructions[0xbe] = "CMP M"
        self._instructions[0xbf] = "CMP A"

        self._instructions[0xc0] = "RNZ"
        self._instructions[0xc1] = "POP BC"
        self._instructions[0xc2] = "JNZ {a16}"
        self._instructions[0xc3] = "JMP {a16}"
        self._instructions[0xc4] = "CNZ {a16}"
        self._instructions[0xc5] = "PUSH BC"
        self._instructions[0xc6] = "ADI A, {d8}"
        self._instructions[0xc7] = "RST 0"
        self._instructions[0xc8] = "RZ"
        self._instructions[0xc9] = "RET"
        self._instructions[0xca] = "JZ {a16}"
        self._instructions[0xcb] = "db cb"
        self._instructions[0xcc] = "CZ {a16}"
        self._instructions[0xcd] = "CALL {a16}"
        self._instructions[0xce] = "ACI A, {d8}"
        self._instructions[0xcf] = "RST 1"

        self._instructions[0xd0] = "RNC"
        self._instructions[0xd1] = "POP DE"
        self._instructions[0xd2] = "JNC {a16}"
        self._instructions[0xd3] = "OUT {d8}"
        self._instructions[0xd4] = "CNC {a16}"
        self._instructions[0xd5] = "PUSH DE"
        self._instructions[0xd6] = "SUI A, {d8}"
        self._instructions[0xd7] = "RST 2"
        self._instructions[0xd8] = "RC"
        self._instructions[0xd9] = "db d9"
        self._instructions[0xda] = "JC {a16}"
        self._instructions[0xdb] = "IN {d8}"
        self._instructions[0xdc] = "CC {a16}"
        self._instructions[0xdd] = "db dd"
        self._instructions[0xde] = "SBI A, {d8}"
        self._instructions[0xdf] = "RST 3"

        self._instructions[0xe0] = "RPO"
        self._instructions[0xe1] = "POP HL"
        self._instructions[0xe2] = "JPO {a16}"
        self._instructions[0xe3] = "XTHL"
        self._instructions[0xe4] = "CPO {a16}"
        self._instructions[0xe5] = "PUSH HL"
        self._instructions[0xe6] = "ANI A, {d8}"
        self._instructions[0xe7] = "RST 4"
        self._instructions[0xe8] = "RPE"
        self._instructions[0xe9] = "PCHL"
        self._instructions[0xea] = "JPE {a16}"
        self._instructions[0xeb] = "XCHG"
        self._instructions[0xec] = "CPE {a16}"
        self._instructions[0xed] = "db ed"
        self._instructions[0xee] = "XRI A, {d8}"
        self._instructions[0xef] = "RST 5"

        self._instructions[0xf0] = "RP"
        self._instructions[0xf1] = "POP PSW"
        self._instructions[0xf2] = "JP {a16}"
        self._instructions[0xf3] = "DI"
        self._instructions[0xf4] = "CP {a16}"
        self._instructions[0xf5] = "PUSH PSW"
        self._instructions[0xf6] = "ORI A, {d8}"
        self._instructions[0xf7] = "RST 6"
        self._instructions[0xf8] = "RM"
        self._instructions[0xf9] = "SPHL"
        self._instructions[0xfa] = "JM {a16}"
        self._instructions[0xfb] = "EI"
        self._instructions[0xfc] = "CM {a16}"
        self._instructions[0xfd] = "db fd"
        self._instructions[0xfe] = "CPI A, {d8}"
        self._instructions[0xff] = "RST 7"

    def _fetch_byte(self, addr):
        return self._data[addr - self._startaddr], addr+1

    def disassemble_instruction(self, addr):
        instruction_addr = addr

        op, addr = self._fetch_byte(addr)
        bstr = f"{op:02x} "
        mnemonic = self._instructions[op]

        if "{d8}" in mnemonic:
            d8, addr = self._fetch_byte(addr)
            bstr += f"{d8:02x} "
            mnemonic = mnemonic.replace("{d8}", f"{d8:02x}")

        if "{a16}" in mnemonic:
            a16l, addr = self._fetch_byte(addr)
            a16h, addr = self._fetch_byte(addr)
            bstr += f"{a16l:02x} {a16h:02x} "
            value = (a16h << 8) | a16l
            mnemonic = mnemonic.replace("{a16}", f"{value:04x}")

        print(f"    {instruction_addr:04x}  {bstr:10} {mnemonic}")
        return addr


    def disassemble(self):
        addr = self._startaddr
        while addr < self._endaddr:
            addr = self.disassemble_instruction(addr)


def main():
    parser = argparse.ArgumentParser(
                    prog='i8080 disassembler',
                    description='i8080 simple disassembler')
    parser.add_argument('binfile')
    parser.add_argument('startaddr')
    #parser.add_argument("-t", "--tape", action="store_true", help="Add tape header")
    args = parser.parse_args()


    dis = Disassembler(args.binfile, args.startaddr)
    dis.disassemble()

if __name__ == '__main__':
    main()
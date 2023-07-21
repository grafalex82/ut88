; General description TBD



; Command C: Memory Copy and Compare
;
; Usage:
; C/CY <src_start>, <src_end>, <dst_start>
;
; Commadn CY will do the memory copy from source memory range to destination
; Command C will compare two memory ranges, and display differences
;
; The command can copy overlapped memory ranges. If destination address is lower than source range address,
; the copying/comparison will be done from lower addresses to upper. And vice versa, if destination address
; is higher than source address, the copying/comparison happens from upper to lower addresses.
COMMAND_C_MEM_COPY:
    c000  cd c1 fc   CALL PARSE_COMMAND_MODE (fcc1) ; Parse arguments
    c003  cd c9 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9)

    c006  e5         PUSH HL                        ; Load target address in BC
    c007  2a 55 f7   LHLD ARG_3 (f755)
    c00a  44         MOV B, H
    c00b  4d         MOV C, L

    c00c  cd d3 fb   CALL CMP_HL_DE (fbd3)          ; Compare source and destination start addresses
    c00f  e1         POP HL
    c010  d2 4d c0   JNC MEM_COPY_BACKWARDS (c04d)  ; Jump if dest addr > src addr

MEM_COPY_FORWARD:
    c013  af         XRA A                          ; Reset direction flag (will copy from lower to higher
    c014  32 59 f7   STA INPUT_POLARITY (f759)      ; addresses)

    c017  23         INX HL                         ; HL - src start
    c018  eb         XCHG                           ; DE - 1 byte after src end

MEM_COPY_START:
    c019  e5         PUSH HL                        ; Print the target address
    c01a  cd 48 c0   CALL PRINT_BC (c048)
    c01d  e1         POP HL

MEM_COPY_LOOP:
    c01e  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; CY command - mem copy, C command - mem compare
    c021  c2 26 c0   JNZ MEM_COPY_COMPARE (c026)

    c024  7e         MOV A, M                       ; Copy a byte from source to destination
    c025  02         STAX BC

MEM_COPY_COMPARE:
    c026  0a         LDAX BC                        ; Compare source and destination memory byte
    c027  be         CMP M

    c028  c4 a1 fb   CNZ PRINT_BC_HL (fba1)         ; If mismatch - print source and dest addresses and values

    c02b  03         INX BC                         ; Advance to the next byte
    c02c  23         INX HL

    c02d  3a 59 f7   LDA INPUT_POLARITY (f759)      ; Check the direction flag
    c030  b7         ORA A
    c031  ca 38 c0   JZ MEM_COPY_ADVANCE_TO_NEXT (c038)

    c034  0b         DCX BC                         ; If reverse direction is set - move to the previous byte
    c035  0b         DCX BC
    c036  2b         DCX HL
    c037  2b         DCX HL

MEM_COPY_ADVANCE_TO_NEXT:
    c038  cd d3 fb   CALL CMP_HL_DE (fbd3)          ; Repeat until end of the range reached
    c03b  c2 1e c0   JNZ MEM_COPY_LOOP (c01e)

    c03e  0b         DCX BC                         ; If copying from higher to lower addresses - print
    c03f  3a 59 f7   LDA INPUT_POLARITY (f759)      ; source end address
    c042  b7         ORA A
    c043  ca 4d fc   JZ PRINT_HL (fc4d)

    c046  03         INX BC                         ; Otherwise print destination start address
    c047  03         INX BC

MEM_COPY_PRINT_DEST:
    c048  60         MOV H, B                       ; Print destination address
    c049  69         MOV L, C
    c04a  c3 4d fc   JMP PRINT_HL (fc4d)

MEM_COPY_BACKWARDS:
    c04d  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; CY command - memory copy, C command - mem compare
    c050  c2 13 c0   JNZ MEM_COPY_FORWARD (c013)    ; Compare will be processed in forward direction

    c053  af         XRA A                          ; Set the direction flag (will copy from higher addr to
    c054  2f         CMA                            ; lower.
    c055  32 59 f7   STA INPUT_POLARITY (f759)

    c058  e5         PUSH HL                        ; Calculate memory range length
    c059  cd c6 fd   CALL HL_SUB_DE (fdc6)

    c05c  09         DAD BC                         ; Calculate destination end address
    
    c05d  e3         XTHL                           ; HL - source end addr
    c05e  c1         POP BC                         ; BC - destination end addr
    c05f  1b         DCX DE                         ; DE - 1 byte below source start

    c060  c3 19 c0   JMP MEM_COPY_START (c019)      ; Start copying


; Command F: Fill/Verify memory with a byte
;
; Usage:
; FY<addr1>, <addr2>, <constant>    - Fill memory range with the constant
; F<addr1>, <addr2>, <constant>     - Compare memory range with the constant, report differences
COMMAND_F_FILL_MEMORY:
    c063  cd c1 fc   CALL PARSE_COMMAND_MODE (fcc1) ; Parse command and arguments
    c066  cd c9 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9)

    c069  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)   ; If end address > start address - report an error

    c06c  eb         XCHG                           ; Move end address to DE

    c06d  2a 55 f7   LHLD ARG_3 (f755)              ; Load the fill constant to B
    c070  45         MOV B, L

    c071  cd d3 fb   CALL CMP_HL_DE (fbd3)          ; If the constant not set - report an error
    c074  cc b9 fb   CZ REPORT_INPUT_ERROR (fbb9)

    c077  2a 51 f7   LHLD ARG_1 (f751)              ; Load source address to HL
    c07a  13         INX DE

FILL_MEMORY_LOOP:
    c07b  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; FY command will fill memory, F command just verify
    c07e  c2 82 c0   JNZ FILL_MEMORY_1 (c082)

    c081  70         MOV M, B                   ; Fill the memory byte with constant

FILL_MEMORY_1:
    c082  78         MOV A, B                   ; Compare the memory byte with constant
    c083  be         CMP M

    c084  c4 6b fc   CNZ PRINT_NEW_LINE (fc6b)  ; If not match - print the address and value
    c087  c4 ab fb   CNZ PRINT_HL_AND_M (fbab)

    c08a  23         INX HL                     ; Advance to the next byte, until reached end address
    c08b  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c08e  c2 7b c0   JNZ FILL_MEMORY_LOOP (c07b)

    c091  c9         RET

; Command H: Calculate sum and difference between the two 16-bit arguments
;
; Usage:
; H<arg1>,<arg2>
;
; The function prints sum first, then arg1-arg2 difference
COMMAND_H_SUM_DIFF_ARG:
    c092  cd c6 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS (fbc6); Parse arguments

    c095  eb         XCHG                       ; Calculate sum of arguments
    c096  e5         PUSH HL
    c097  19         DAD DE

    c098  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print the sum

    c09b  e1         POP HL                     ; Calculate arg1-arg2 difference
    c09c  cd c6 fd   CALL HL_SUB_DE (fdc6)
    c09f  c3 4d fc   JMP PRINT_HL (fc4d)        ; Print the difference, and exit


; Command J: Quick jump
;
; Usage:
; J<addr>   - Set the quick jump address
; J         - Execute from the previously set quick jump address
COMMAND_J_QUICK_JUMP:
    c0a2  0d         DCR C                      ; Check if argument is specified
    c0a3  0d         DCR C
    c0a4  ca b1 c0   JZ QUICK_JUMP (c0b1)

    c0a7  cd c6 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS (fbc6); Parse the argument
    c0aa  c4 b9 fb   CNZ REPORT_INPUT_ERROR (fbb9)

    c0ad  22 62 f7   SHLD QUICK_JUMP_ADDR (f762); Set the quick jump address

    c0b0  c9         RET

QUICK_JUMP:
    c0b1  2a 62 f7   LHLD QUICK_JUMP_ADDR (f762); Jump to the quick jump address
    c0b4  e9         PCHL

; Command D: Dump the memory
;
; Usage:
; D                 - Dump 128-byte chunk of memory, starting the user program HL
; D<start>          - Dump 128-byte chunk, starting the address provided
; D<start>,<end>    - Dump memory for the specified memory range
;
; Memory is dumped in 2 ways (hexadecimal, and symbol view), 8 bytes in the line.
;
; Note: the command may be used in conjunction with breakpoint mechanism. Dump command will print
; memory starting the address that user program HL register points to (at the moment of breakpoint)
COMMAND_D_DUMP_MEMORY:
    c0b5  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)   ; Parse arguments

    c0b8  cc eb c0   CZ DUMP_GET_START_END_ADDR (c0eb)  ; Calculate start/end address, if not provided

    c0bb  eb         XCHG                       ; Start address in HL, end address in DE

    c0bc  7b         MOV A, E                   ; Round end address to 8-byte boundary (ceiling)
    c0bd  e6 f8      ANI A, f8
    c0bf  c6 07      ADI A, 07
    c0c1  5f         MOV E, A
    c0c2  13         INX DE

    c0c3  7d         MOV A, L                   ; Round start address to 8 byte boundary (floor)
    c0c4  e6 f8      ANI A, f8
    c0c6  6f         MOV L, A

DUMP_MEMORY_LINE_LOOP:
    c0c7  cd 6b fc   CALL PRINT_NEW_LINE (fc6b) ; Start the new line, print starting address
    c0ca  cd 4d fc   CALL PRINT_HL (fc4d)
    c0cd  e5         PUSH HL

DUMP_MEMORY_HEX_COL_LOOP:
    c0ce  cd ae fb   CALL PRINT_MEM_VALUE (fbae)

    c0d1  23         INX HL                     ; Advance to the next byte, 8 bytes in a line
    c0d2  7d         MOV A, L
    c0d3  e6 07      ANI A, 07
    c0d5  c2 ce c0   JNZ DUMP_MEMORY_HEX_COL_LOOP (c0ce)

    c0d8  e1         POP HL

DUMP_MEMORY_SYMB_COL_LOOP:
    c0d9  7e         MOV A, M                   ; Print symbolic representation of the byte
    c0da  cd 1d fe   CALL PRINT_SYMBOL (fe1d)

    c0dd  23         INX HL                     ; Advance to the next byte, 8 bytes in a line
    c0de  7d         MOV A, L
    c0df  e6 07      ANI A, 07
    c0e1  c2 d9 c0   JNZ DUMP_MEMORY_SYMB_COL_LOOP (c0d9)

    c0e4  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Repeat, until reached the end address
    c0e7  c2 c7 c0   JNZ DUMP_MEMORY_LINE_LOOP (c0c7)

    c0ea  c9         RET


; Function that calculates default start/end address for the dump command
; - If no argument 1 specified - use user program HL address (filled on a breakpoint, or after command execution)
; - If no argument 2 specified - use 128 byte range, starting the arg1
;
; Return:
; - Start address in DE
; - End address in HL
DUMP_GET_START_END_ADDR:
    c0eb  0d         DCR C                      ; If no arguments specified - use user HL address
    c0ec  0d         DCR C
    c0ed  cc f5 c0   CZ GET_BREAKPOINT_HL (c0f5)

    c0f0  21 7f 00   LXI HL, 007f               ; End address will be 127 bytes further than start address
    c0f3  19         DAD DE
    c0f4  c9         RET

; Get the user program HL register value. Return the value in DE
GET_BREAKPOINT_HL:
    c0f5  2a 6b f7   LHLD BREAKPOINT_HL_REG (f76b)
    c0f8  eb         XCHG
    c0f9  c9         RET


; Command V: Measure tape delay constant
;
; The function measures tape delay constant to be used with Command I later. The function stores measured
; constant in 0xf75c and prints the value to the screen, so that user can type it for Command I later.
COMMAND_V_TAPE_SPEED_ADJUST:
    c0fa  21 00 00   LXI HL, 0000               ; The counter

    c0fd  01 c4 01   LXI BC, 01c4               ; B=01 - input bitmask, C=0xc4 - number of pulses to measure

    c100  db a1      IN a1                      ; Input the bit
    c102  a0         ANA B
    c103  5f         MOV E, A

SPEED_ADJUST_LOOP_1:
    c104  db a1      IN a1                      ; Wait until the bit changes
    c106  a0         ANA B
    c107  bb         CMP E
    c108  ca 04 c1   JZ SPEED_ADJUST_LOOP_1 (c104)

    c10b  5f         MOV E, A                   ; Temporary store the value at E register

SPEED_ADJUST_LOOP_2:
    c10c  db a1      IN a1                      ; Wait until the pulse ends
    c10e  a0         ANA B

    c10f  23         INX HL                     ; Measure pulse duration in HL
    c110  bb         CMP E
    c111  ca 0c c1   JZ SPEED_ADJUST_LOOP_2 (c10c)

    c114  5f         MOV E, A
    c115  0d         DCR C                      ; Count pulses in C
    c116  c2 0c c1   JNZ c10c

    c119  29         DAD HL                     ; Some constant calculations
    c11a  29         DAD HL
    c11b  7c         MOV A, H
    c11c  b7         ORA A                      ; If the measured value is too big - just save it
    c11d  fa 2e c1   JM ADJUST_SPEED_EXIT (c12e)

    c120  2f         CMA                        ; Another portion of calculations
    c121  e6 70      ANI A, 70
    c123  0f         RRC
    c124  0f         RRC
    c125  0f         RRC
    c126  47         MOV B, A

    c127  0f         RRC
    c128  1f         RAR
    c129  80         ADD B
    c12a  3c         INR A
    c12b  47         MOV B, A
    c12c  7c         MOV A, H
    c12d  90         SUB B

ADJUST_SPEED_EXIT:
    c12e  32 5c f7   STA IN_BIT_DELAY (f75c)    ; Store measured value

    c131  c3 b3 f9   JMP PRINT_BYTE_HEX (f9b3)  ; Print the value


; Command S: Search string in a memory range
;
; Usage:
; S maddr1, maddr2, saddr1, saddr2      - Search string located saddr1-saddr2 in a memory range maddr1-maddr2
; S maddr1, maddr2, '<string>'          - Search string specified in single quotes in maddr1-maddr2 memory
; S maddr1, maddr2, &<hex>, <hex>,...   - Search string specified in a form of hex sequence in specified
;                                         maddr1-maddr2 memory range
COMMAND_S_SEARCH_STRING:
    c134  cd 6b fc   CALL PRINT_NEW_LINE (fc6b)

    c137  11 7c f7   LXI DE, f77b + 1 (f77c)    ; Parse argument 1
    c13a  cd 04 fc   CALL PARSE_HEX (fc04)
    c13d  22 51 f7   SHLD ARG_1 (f751)

    c140  cd 04 fc   CALL PARSE_HEX (fc04)      ; Parse argument 2
    c143  22 53 f7   SHLD ARG_2 (f753)

    c146  d5         PUSH DE                    ; Compare arg1 and arg2, while preserving DE pointer 
    c147  cd cc fb   CALL LOAD_ARGUMENTS (fbcc) ; looking at argument 3
    c14a  d1         POP DE

    c14b  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)   ; Report an error if arg 2 > arg 1

    c14e  1a         LDAX DE                    ; Check if the next symbol is &
    c14f  d6 26      SUI A, 26
    c151  ca d5 c1   JZ SEARCH_STRING_HEX (c1d5); & means hex search

    c154  3d         DCR A                      ; Check if the next symbol is ' (single quote)
    c155  ca ba c1   JZ SEARCH_STRING_SYMBOLIC (c1ba)   ; Single quote starts symbolic search

    c158  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)   ; re-parse all 4 arguments, assuming they all hex

SEARCH_STRING_START_SEARCH:
    c15b  cd cc fb   CALL LOAD_ARGUMENTS (fbcc) ; Check start/end address, return if start address becomes
    c15e  d8         RC                         ; greater than end address (on some iteration)

    c15f  eb         XCHG                       ; Push arg1/arg2 (start/end address) to stack for now
    c160  e5         PUSH HL
    c161  d5         PUSH DE

    c162  2a 55 f7   LHLD ARG_3 (f755)          ; Load arg3 (etalon string start) to DE
    c165  e5         PUSH HL
    c166  eb         XCHG

    c167  2a 57 f7   LHLD ARG_4 (f757)          ; Load arg4 (etalon string end) to HL

    c16a  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Check arg3 vs arg4 correctness, report an error if needed
    c16d  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)

    c170  cd c6 fd   CALL HL_SUB_DE (fdc6)      ; Calculate etalon string length
    c173  23         INX HL

    c174  c1         POP BC                     ; BC = string start addr
    c175  d1         POP DE                     ; HL = mem range start addr
    c176  e3         XTHL                       ; value on stack is string length

    c177  cd b0 fd   CALL RESET_COMMAND_MODE_FLAG (fdb0); Clear 'first byte of string matched' flag

SEARCH_STRING_COMPARE_NEXT_BYTE:
    c17a  0a         LDAX BC                    ; Compare next byte in the memory with the string byte
    c17b  be         CMP M
    c17c  c2 9d c1   JNZ SEARCH_STRING_NEXT_BYTE_2 (c19d)

    c17f  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; Check if we are already matching the string
    c182  c2 8b c1   JNZ SEARCH_STRING_COMPARE_NEXT_BYTE_1 (c18b)

    c185  22 5e f7   SHLD f75e                  ; First symbol is matched, store the address of the string

    c188  cd b5 fd   CALL SET_COMMAND_MODE_FLAG (fdb5)  ; Raise the flag we are in string matching mode

SEARCH_STRING_COMPARE_NEXT_BYTE_1:
    c18b  e3         XTHL                       ; Decrement remaining string length
    c18c  2b         DCX HL

    c18d  7c         MOV A, H                   ; Check if no more characters to match left
    c18e  b5         ORA L

    c18f  e3         XTHL                       ; Store remaining length back to stack

    c190  ca a3 c1   JZ SEARCH_STRING_REPORT (c1a3) ; If no more characters left - report the finding

    c193  03         INX BC                     ; Advance to the next character in the string

SEARCH_STRING_NEXT_BYTE:
    c194  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Repeat for the next symbol, until reached end of the
    c197  23         INX HL                     ; memory range
    c198  c2 7a c1   JNZ c17a

    c19b  e1         POP HL                     ; Exit
    c19c  c9         RET

SEARCH_STRING_NEXT_BYTE_2:
    c19d  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; Continue searching if string was not yet matched
    c1a0  ca 94 c1   JZ SEARCH_STRING_NEXT_BYTE (c194)  ; even for a symbol


SEARCH_STRING_REPORT:
    ; We arrive here in 2 cases: full match happened, or partial match happened, but last few chars do
    ; not match. In case of full match Z flag will be set. In this case the function will print the 
    ; matching address.
    ;
    ; In any case we need to reset the search

    c1a3  e1         POP HL                     ; Restore string length

    c1a4  2a 5e f7   LHLD f75e                  ; Load found string start address

    c1a7  cc 4d fc   CZ PRINT_HL (fc4d)         ; Print address and spacer in case if string has been matched
    c1aa  cc 67 fc   CZ PRINT_SPACE (fc67)
    c1ad  cc 67 fc   CZ PRINT_SPACE (fc67)
    c1b0  cc 67 fc   CZ PRINT_SPACE (fc67)

    c1b3  23         INX HL                     ; Advance to the next symbol, which will be starting address
    c1b4  22 51 f7   SHLD ARG_1 (f751)          ; of the next search

    c1b7  c3 5b c1   JMP SEARCH_STRING_START_SEARCH (c15b)  ; Restart the search


SEARCH_STRING_SYMBOLIC:
    c1ba  eb         XCHG                       ; Store string start in arg3 variable
    c1bb  23         INX HL
    c1bc  22 55 f7   SHLD ARG_3 (f755)

SEARCH_STRING_SYMBOLIC_LOOP:
    c1bf  23         INX HL                     ; Search for closing quote
    c1c0  7e         MOV A, M

    c1c1  fe 27      CPI A, 27                  ; Continue when closing quote
    c1c3  ca ce c1   JZ SEARCH_STRING_SYMBOLIC_1 (c1ce)

    c1c6  fe 0d      CPI A, 0d                  ; If no closing quote found - report an error
    c1c8  cc b9 fb   CZ REPORT_INPUT_ERROR (fbb9)

    c1cb  c3 bf c1   JMP SEARCH_STRING_SYMBOLIC_LOOP (c1bf)

SEARCH_STRING_SYMBOLIC_1:
    c1ce  2b         DCX HL                     ; Store string end address in arg4
    c1cf  22 57 f7   SHLD ARG_4 (f757)

    c1d2  c3 5b c1   JMP SEARCH_STRING_START_SEARCH (c15b)


SEARCH_STRING_HEX:
    c1d5  eb         XCHG                       ; Store string start address as arg3
    c1d6  23         INX HL
    c1d7  22 55 f7   SHLD ARG_3 (f755)

    c1da  44         MOV B, H                   ; BC will contain next char address in the cmd line buffer
    c1db  4d         MOV C, L
    c1dc  eb         XCHG

SEARCH_STRING_HEX_LOOP:
    c1dd  cd 04 fc   CALL PARSE_HEX (fc04)      ; Parse 2-digit hex, and store it at [BC]
    c1e0  7d         MOV A, L
    c1e1  02         STAX BC
    c1e2  03         INX BC

    c1e3  c2 dd c1   JNZ SEARCH_STRING_HEX_LOOP (c1dd)  ; Repeat until 0x00 is found, or end of string

    c1e6  60         MOV H, B                   ; Cmd line buffer now contains string (converted from hex)
    c1e7  69         MOV L, C                   ; Do a regular symbolic search
    c1e8  c3 ce c1   JMP SEARCH_STRING_SYMBOLIC_1 (c1ce)


; Command Z: Zero/dump 0xf400-0xf5ff range
; 
; Usage:
; Z         - Dump the range (print in 16-bit words)
; Z0        - Fill the range with zeros
COMMAND_Z_ZERO_RANGE:
    c1eb  3a 7c f7   LDA f77b + 1 (f77c)        ; Get the second command byte
    c1ee  fe 30      CPI A, 30                  ; If it is '0' - go and clear memory range
    c1f0  c2 00 c2   JNZ c200

    c1f3  21 ff f3   LXI HL, f3ff               ; 1 byte before start address

ZERO_RANGE_CLEAR_LOOP:
    c1f6  23         INX HL                     ; Advance to the next byte

    c1f7  7c         MOV A, H                   ; Check if we reached the end of the range
    c1f8  fe f6      CPI A, f6
    c1fa  c8         RZ

    c1fb  36 00      MVI M, 00                  ; Fill byte with zero

    c1fd  c3 f6 c1   JMP ZERO_RANGE_CLEAR_LOOP (c1f6)   ; Repeat for the next byte

ZERO_RANGE_COMPARE:
    c200  3a 7a f7   LDA ENABLE_SCROLL (f77a)   ; Disable scroll, will output page by page
    c203  f5         PUSH PSW
    c204  af         XRA A
    c205  32 7a f7   STA ENABLE_SCROLL (f77a)

    c208  0e 1f      MVI C, 1f                  ; Clear screen
    c20a  cd f0 f9   CALL PUT_CHAR (f9f0)

    c20d  16 f4      MVI D, f4                  ; Set DE to 0xf400 (start range)
    c20f  5f         MOV E, A

    c210  47         MOV B, A                   ; Zero record index

ZERO_RANGE_COMPARE_LOOP:
    c211  78         MOV A, B                   ; Print the index
    c212  cd af fb   CALL PRINT_BYTE_CHECK_KBD (fbaf)

    c215  1a         LDAX DE                    ; Load next word to HL
    c216  13         INX DE
    c217  6f         MOV L, A
    c218  1a         LDAX DE
    c219  13         INX DE
    c21a  67         MOV H, A

    c21b  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print the value

    c21e  04         INR B                      ; Advance to the next word, repeat until reached end of range
    c21f  c2 11 c2   JNZ ZERO_RANGE_COMPARE_LOOP (c211)

    c222  f1         POP PSW                    ; Restore scroll mode
    c223  32 7a f7   STA ENABLE_SCROLL (f77a)

    c226  c9         RET


; Command P: Relocate program to another memory address range
;
; Usage:
; - P[N]<w1>,<w2>,<s1>,<s2>,<t>     - Relocate program (see arguments description below)
; - P@<s1>,<s2>,<t>                 - Adjust addresses in 0xf400-0xf5ff
;
; P/PN command is used to relocate a program from one memory range to another. The command iterates over 
; program instructions, and checks 2- and 3-byte instructions whether they have an address in source memory
; range, and correct them to match the target memory range. 
;
; Arguments description:
; - <s1>-<s2> (arguments 3 and 4) represent the source program memory range. The P command searches for all
;   3-byte instructions that possibly contain an address in <s1>-<s2> range. These instructions are corrected
;   so that they match the target memory range (argument 5)
; - <w1>-<w2> (arguments 3 and 4) represent a working copy of the program. It may happen that command P is
;   used to relocate the program from a ROM to different addresses. In this case modifying <s1>-<s2> source
;   range may not be possible. The user may copy program from the ROM to a working RAM at <w1>-<w2> range,
;   where then instruction modification happens. Note, that command P does not perform copying from <s1>-<s2>
;   to <w1>-<w2>, but expects instructions copied before command P is executed.
; - <t> (argument 5) represents the target address range where the program shall work after relocation. Note
;   that command does not make any copying to target address range. It only change a working copy so that 
;   all the addresses point to the target range.
;
; Example:
; Suppose you have a working program at 0x2000-0x2fff memory range, and you want to port the program to a
; different computer that will execute the program at 0x5000-0x5fff range. 
;
; In order not to corrupt the original program, you may create a working copy, say at 0x4000-0x4fff range:
; CY 2000,2fff,4000
;
; Now you can perform relocation with command P - working copy range (arg1/2), specify original program range
; in arg3/4, and target address:
; P 4000,4fff,2000,2fff,5000
;
; Imagine that source program (which is located in 0x2000-0x2fff range) has an instruction:
;   JMP 2345
;
; Since address 0x2345 belongs to source program range (0x2000-0x2fff), it will be replaced with the 
; corresponding address in the target memory range:
;   JMP 5345
;
; The change is performed in working copy only (0x4000-0x4fff), leaving the original program intact.
;
; In some cases programs may use low and high bytes of the address separately. For example:
;   MVI A, f6
;   CMP D
;
; This code in fact may implement an address checking. For example check that DE counter reached 0xf600
; address. Unfortunately relocation program can't state this for sure, and prints a warning, specifying
; address of suspicious MVI instruction. The user may then double check whether this is related to address
; calculations, and correct the constant if needed.
;
; By default it is assumed that LXI instruction loads an address too. If the address is in program memory
; range, it will be adjusted. The 'PN' command will treat LXI arguments as a number, and will not be adjusted
; even if it matches the memory range. The warning will be displayed indicating a suspicious instruction
; address, so that the User can double check.
;
; Target range and a working copy may coincide. If you want to relocate the program to another range on the
; same system, you can follow the next example:
; CY 2000,2fff,5000
; P 5000,5fff,2000,2fff,5000
; The first command will copy the original program from 0x2000-0x2fff range to 0x5000. The second command
; will adjust instructions that refers the original range so that it points the new address range.
;   
;
; The P@ command also does an address adjustment, but in a different way:
; - 0xf400-0xf5ff range is considered as an array of 256 16-byte address values
; - the command iterates over these values, and check whether they are in <s1>-<s2> range
; - if the address match the source range, it will be adjusted to a corresponding target address
;
; Let's imagine there are 2 addresses at 0xf400+ - 0x2345 and 0x4567
; If you want to relocate all addresses in 0x2000-0x2fff range to 0x6000-0x6fff range, enter the command:
;   P@ 2000,2fff,6000
;
; The first address at 0xf400 will be changed to 0x6345. The second address will remain 0x4567 as it does
; not belong the 0x2000-0x2fff range.
COMMAND_P_RELOCATE:
    c227  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)  ; Check if this is P@ command
    c22a  c2 79 c2   JNZ c279

    ; The following process P@ command
    c22d  cd c9 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9); Parse arguments

    c230  2a 55 f7   LHLD ARG_3 (f755)          ; Load arg 3 to HL (source start address)
    c233  cd c6 fd   CALL HL_SUB_DE (fdc6)      ; Calculate offset from DE (destination end address)

    c236  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print source start address

    c239  44         MOV B, H                   ; BC - offset to apply
    c23a  4d         MOV C, L
    c23b  11 ff f3   LXI DE, f3ff               ; DE - 0xd400 destination start address

RELOCATE_ADDR_LOOP:
    c23e  13         INX DE                     ; Advance to the next value, stop if reached 0xf600
    c23f  3e f6      MVI A, f6
    c241  ba         CMP D
    c242  c8         RZ

    c243  1a         LDAX DE                    ; Load the word at [DE] to HL
    c244  13         INX DE
    c245  6f         MOV L, A
    c246  1a         LDAX DE
    c247  1b         DCX DE
    c248  67         MOV H, A

    c249  d5         PUSH DE
    c24a  eb         XCHG

    c24b  2a 51 f7   LHLD ARG_1 (f751)          ; Check if the value is higher than arg1
    c24e  2b         DCX HL
    c24f  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c252  d2 6a c2   JNC RELOCATE_ADDR_1 (c26a)

    c255  2a 53 f7   LHLD ARG_2 (f753)          ; Check if the value is lower than arg2
    c258  23         INX HL
    c259  eb         XCHG
    c25a  cd d3 fb   CALL CMP_HL_DE (fbd3)

    c25d  d1         POP DE                     ; If not in arg1-arg2 range - advance to the next value
    c25e  d2 6c c2   JNC RELOCATE_ADDR_2 (c26c)

    c261  09         DAD BC                     ; Apply the offset

    c262  7d         MOV A, L                   ; Store value back
    c263  12         STAX DE
    c264  13         INX DE
    c265  7c         MOV A, H
    c266  12         STAX DE

    c267  c3 3e c2   JMP RELOCATE_ADDR_LOOP (c23e)  ; Repeat for the next address

RELOCATE_ADDR_1:
    c26a  eb         XCHG
    c26b  d1         POP DE

RELOCATE_ADDR_2:
    c26c  13         INX DE                     ; Advance to the next address
    c26d  c3 3e c2   JMP RELOCATE_ADDR_LOOP (c23e)


; Helper function to check whether '@' modifier is added to the command
; Raise Z flag if '@' modifier is present
CHECK_AT_MODIFIER:
    c270  11 7c f7   LXI DE, f77b + 1 (f77c)

CHECK_AT_SYMBOL:
    c273  1a         LDAX DE                    ; Check if symbol at [DE] is @
    c274  fe 40      CPI A, 40
    c276  c0         RNZ                        ; Z flag reset if no @

    c277  13         INX DE                     ; Advance DE to the next symbol after @
    c278  c9         RET                        ; Z flag is set if @ is present


; The following process P command (not P@)
RELOCATE_PROGRAM:
    c279  11 7c f7   LXI DE, f77b + 1 (f77c)

    c27c  1a         LDAX DE                    ; Skip 'N' command alteration char
    c27d  fe 4e      CPI A, 4e
    c27f  c2 83 c2   JNZ RELOCATE_PROGRAM_1 (c283)

    c282  13         INX DE

RELOCATE_PROGRAM_1:
    c283  cd d9 fb   CALL PARSE_ARGUMENTS (fbd9); Parse arguments, report an error not all arguments provided
    c286  cc b9 fb   CZ REPORT_INPUT_ERROR (fbb9)

    c289  d5         PUSH DE                    ; Decrement arg2 (destination end address)
    c28a  cd cc fb   CALL LOAD_ARGUMENTS (fbcc)
    c28d  2b         DCX HL
    c28e  22 53 f7   SHLD ARG_2 (f753)

    c291  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)   ; Report error if dest start addr > dest end addr

    c294  2a 55 f7   LHLD ARG_3 (f755)          ; Compare source start and end addresses
    c297  eb         XCHG
    c298  2a 57 f7   LHLD ARG_4 (f757)
    c29b  cd d3 fb   CALL CMP_HL_DE (fbd3)

    c29e  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)   ; Report error if src start addr > src end addr

    c2a1  d1         POP DE                     ; Parse argument 5
    c2a2  cd 04 fc   CALL PARSE_HEX (fc04)
    c2a5  eb         XCHG

    c2a6  2a 55 f7   LHLD ARG_3 (f755)          ; Calculate arg5-arg3 difference
    c2a9  eb         XCHG
    c2aa  cd c6 fd   CALL HL_SUB_DE (fdc6)
    c2ad  22 5e f7   SHLD f75e

RELOCATE_PROGRAM_LOOP:
    c2b0  2a 51 f7   LHLD ARG_1 (f751)          ; Get next byte at [arg1] (destination range)
    c2b3  e5         PUSH HL
    c2b4  7e         MOV A, M

    c2b5  cd 1c c3   CALL MATCH_INSTRUCTION (c31c)  ; Match the opcode
    c2b8  e1         POP HL
    c2b9  d2 ed c2   JNC RELOCATE_PROGRAM_2_BYTE_OPCODE (c2ed)  ; C flag indicates a 3-byte instruction

    c2bc  23         INX HL                     ; Load the instruction argument to DE
    c2bd  5e         MOV E, M
    c2be  23         INX HL
    c2bf  56         MOV D, M

    c2c0  2a 55 f7   LHLD ARG_3 (f755)          ; Check if the argument is greater or equal than source start 
    c2c3  2b         DCX HL                     ; address
    c2c4  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c2c7  d2 0b c3   JNC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2ca  2a 57 f7   LHLD ARG_4 (f757)          ; Check if the argument is lower than source end address
    c2cd  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c2d0  da 0b c3   JC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2d3  78         MOV A, B                   ; The argument is in source memory range. Check if the
    c2d4  fe 07      CPI A, 07                  ; instruction is LXI (argument is not necessarily an address)
    c2d6  c2 e1 c2   JNZ RELOCATE_PROGRAM_2 (c2e1)

    c2d9  3a 7c f7   LDA f77b + 1 (f77c)        ; Check if the 'N' command alteration enabled, which warns
    c2dc  fe 4e      CPI A, 4e                  ; the user that argument is probably an address, and shall be
    c2de  ca 03 c3   JZ RELOCATE_PROGRAM_PRINT_WARNING (c303)   ; double checked

RELOCATE_PROGRAM_2:
    c2e1  2a 5e f7   LHLD f75e                  ; Adjust the instruction argument to the target memory range
    c2e4  19         DAD DE

    c2e5  eb         XCHG                       ; Store the calculated value as a new instruction argument
    c2e6  2a 51 f7   LHLD ARG_1 (f751)
    c2e9  23         INX HL
    c2ea  73         MOV M, E
    c2eb  23         INX HL
    c2ec  72         MOV M, D

RELOCATE_PROGRAM_2_BYTE_OPCODE:
    c2ed  79         MOV A, C                   ; Check if this is a 2-byte instruction
    c2ee  fe 02      CPI A, 02
    c2f0  c2 0b c3   JNZ RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2f3  23         INX HL                     ; Advance to the argument byte

    c2f4  3a 56 f7   LDA ARG_3 + 1 (f756)       ; Perhaps the argument is a high byte of an address.
    c2f7  3d         DCR A                      ; Check if it higher than source start address high byte
    c2f8  be         CMP M
    c2f9  d2 0b c3   JNC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2fc  3a 58 f7   LDA ARG_4 + 1 (f758)       ; And lower than source end address high byte
    c2ff  be         CMP M
    c300  da 0b c3   JC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

RELOCATE_PROGRAM_PRINT_WARNING:
    c303  cd 47 fc   CALL PRINT_ARG_1 (fc47)    ; Print the address with an exclamation mark. These 2-byte
    c306  3e 21      MVI A, 21                  ; instructions will not be changed automatically, but are
    c308  cd e9 f9   CALL PUT_CHAR_A (f9e9)     ; listed to the user as potentially requiring a change

RELOCATE_PROGRAM_1_BYTE_OPCODE:
    c30b  2a 51 f7   LHLD ARG_1 (f751)          ; Advance to the next instruction (C is instruction length)
    c30e  06 00      MVI B, 00
    c310  09         DAD BC
    c311  22 51 f7   SHLD ARG_1 (f751)

    c314  cd cc fb   CALL LOAD_ARGUMENTS (fbcc) ; Stop when reached end of the range
    c317  c8         RZ
    c318  d8         RC

    c319  c3 b0 c2   JMP RELOCATE_PROGRAM_LOOP (c2b0)



; Match byte in A with one of CPU instructions
; Return:
; A - matched and masked instruction
; B - attributes byte
; C - number of instruction bytes
; HL - pointer to the instruction record
; C flag is set if 3-byte instruction is matched
;
; The function tries to match exact instruction code agains the instruction table. If no specific 
; instruction matched, the function applies different bitmasks in order to match a whole instruction
; classes (e.g. full class of MOV instructions). In this case only the first instruction in the class 
; is returned.
MATCH_INSTRUCTION:
    c31c  21 cd c5   LXI HL, INSTRUCTION_DESCRIPTORS (c5cd) ; Get instructions descriptors

    c31f  47         MOV B, A                   ; Store instruction in B

MATCH_INSTRUCTION_LOOP:
    c320  23         INX HL                     ; Skip mnemonic
    c321  23         INX HL
    c322  23         INX HL
    c323  23         INX HL

    c324  be         CMP M                      ; Compare instruction code, proceed when matched
    c325  23         INX HL
    c326  ca 68 c3   JZ MATCH_INSTRUCTION_ATTRIBUTE (c368)

    c329  23         INX HL                     ; If we reached end of the table, this probably an instruction
    c32a  34         INR M                      ; that needs to be matched with mask
    c32b  35         DCR M
    c32c  f2 20 c3   JP MATCH_INSTRUCTION_LOOP (c320)

    c32f  21 1c c3   LXI HL, MATCH_INSTRUCTION (c31c)   ; Set return address to MATCH_INSTRUCTION so that 
    c332  e5         PUSH HL                    ; instructions can be matched again after bitmask is applied

    c333  e6 cf      ANI A, cf                  ; Mask POP instructions class, go match exact instruction
    c335  fe c1      CPI A, c1
    c337  c8         RZ

    c338  fe c5      CPI A, c5                  ; Mask PUSH instructions class, go match exact instruction
    c33a  c8         RZ

    c33b  e6 f7      ANI A, f7                  ; Filter out some non-valid instructions
    c33d  ca 64 c3   JZ MATCH_INSTRUCTION_DATA_BYTE (c364)

    c340  fe c7      CPI A, c7                  ; Mask RST instructions class, go match exact instruction
    c342  c8         RZ

    c343  e6 f0      ANI A, f0                  ; Mask MOV instructions class, go match exact instruction
    c345  fe 40      CPI A, 40
    c347  c8         RZ

    c348  78         MOV A, B                   ; Match LXI, STAX, INX, DCX, DAD, and LDAX instruction classes
    c349  e6 c4      ANI A, c4
    c34b  ca 60 c3   JZ MATCH_INSTRUCTION_2 (c360)

    c34e  e6 f0      ANI A, f0                  ; Filter out some instruction set
    c350  c2 57 c3   JNZ MATCH_INSTRUCTION_1 (c357)

    c353  78         MOV A, B                   ; Mask MVI, INR, and DCR instruction classes
    c354  e6 c7      ANI A, c7
    c356  c9         RET

MATCH_INSTRUCTION_1:
    c357  fe 80      CPI A, 80                  ; Match ADD, ADC, SUB, SBB, ANA, XRA, ORA, and CMP
    c359  c2 64 c3   JNZ MATCH_INSTRUCTION_DATA_BYTE (c364) ; instruction classes

    c35c  78         MOV A, B                   ; Apply mask (remove register bits)
    c35d  e6 f8      ANI A, f8
    c35f  c9         RET

MATCH_INSTRUCTION_2:
    c360  78         MOV A, B                   ; Apply mask for LXI, STAX, INX, DCX, DAD, and LDAX
    c361  e6 cf      ANI A, cf                  ; instruction classes
    c363  c9         RET

MATCH_INSTRUCTION_DATA_BYTE:
    c364  e1         POP HL                     ; No exact instruction matched, will return "DB" directive
    c365  21 a6 c7   LXI HL, c7a6

MATCH_INSTRUCTION_ATTRIBUTE:
    c368  7e         MOV A, M                   ; Load attribute byte in A
    c369  e5         PUSH HL

    c36a  21 82 c3   LXI HL, MATCH_INSTRUCTION_EXIT (c382)  ; Set the exit handler
    c36d  e3         XTHL

    c36e  0e 03      MVI C, 03                  ; Match 3-byte instruction attribute

    c370  fe 02      CPI A, 02                  ; Match 0x02 attribute byte (normal 3-byte instruction) ????
    c372  37         STC
    c373  c8         RZ

    c374  fe 07      CPI A, 07                  ; Match 0x07 attribute byte (LXI instruction)
    c376  37         STC
    c377  c8         RZ

    c378  0d         DCR C                      ; Match 2-byte instruction attribute

    c379  fe 01      CPI A, 01                  ; Match 0x01 attribute byte (normal 2-byte instruction) ????
    c37b  c8         RZ

    c37c  fe 09      CPI A, 09                  ; Match 0x09 attribute byte ????
    c37e  c8         RZ

    c37f  af         XRA A                      ; Everything else is 1-byte instructions, attribute byte is 0
    c380  0d         DCR C
    c381  c9         RET

MATCH_INSTRUCTION_EXIT:
    c382  78         MOV A, B                   ; Return masked instruction byte in A
    c383  46         MOV B, M                   ; Return instruction attribute byte in B
    c384  2b         DCX HL                     ; Return pointer to instruction record+4 in HL 
    c385  c9         RET




COMMAND_L_????:
c386  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)
c389  06 10      MVI B, 10
c38b  eb         XCHG
c38c  13         INX DE
c38d  c2 93 c3   JNZ c393
c390  11 00 b0   LXI DE, b000
????:
c393  0e 0a      MVI C, 0a
c395  cd f0 f9   CALL PUT_CHAR (f9f0)
c398  05         DCR B
c399  cc b7 c3   CZ c3b7
c39c  cd 4d fc   CALL PRINT_HL (fc4d)
????:
c39f  cd d3 fb   CALL CMP_HL_DE (fbd3)
c3a2  c8         RZ
c3a3  7e         MOV A, M
c3a4  b7         ORA A
c3a5  f8         RM
c3a6  fe 0d      CPI A, 0d
c3a8  23         INX HL
c3a9  ca 93 c3   JZ c393
c3ac  e5         PUSH HL
c3ad  cd 28 fe   CALL fe28
c3b0  e1         POP HL
c3b1  cd f0 f9   CALL PUT_CHAR (f9f0)
c3b4  c3 9f c3   JMP c39f
????:
c3b7  cd 6b f8   CALL f86b
c3ba  fe 20      CPI A, 20
c3bc  c1         POP BC
c3bd  c0         RNZ
c3be  c5         PUSH BC
c3bf  06 0f      MVI B, 0f
c3c1  c9         RET

COMMAND_W_????:
c3c2  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)
c3c5  c2 ce c3   JNZ c3ce
c3c8  21 ff ff   LXI HL, ffff
c3cb  22 53 f7   SHLD ARG_2 (f753)
????:
c3ce  cd b0 fd   CALL RESET_COMMAND_MODE_FLAG (fdb0)
????:
c3d1  0e 57      MVI C, 57
c3d3  cd f0 f9   CALL PUT_CHAR (f9f0)
c3d6  cd 6b f8   CALL f86b
c3d9  fe 20      CPI A, 20
c3db  c2 e5 c3   JNZ c3e5
c3de  3a ff f7   LDA f7ff
c3e1  2f         CMA
c3e2  c3 f1 c3   JMP c3f1
????:
c3e5  d6 32      SUI A, 32
c3e7  ca f1 c3   JZ c3f1
c3ea  fe ff      CPI A, ff
c3ec  0e 19      MVI C, 19
c3ee  c2 f0 f9   JNZ PUT_CHAR (f9f0)
????:
c3f1  32 ff f7   STA f7ff
c3f4  01 0c 18   LXI BC, 180c
c3f7  cd f0 f9   CALL PUT_CHAR (f9f0)
????:
c3fa  c5         PUSH BC
c3fb  78         MOV A, B
c3fc  fe 18      CPI A, 18
c3fe  c4 6b fc   CNZ PRINT_NEW_LINE (fc6b)
c401  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)
c404  cc 7b c4   CZ c47b
c407  cd 4a fc   CALL fc4a
c40a  01 7b f7   LXI BC, f77b
c40d  c5         PUSH BC
????:
c40e  3e 20      MVI A, 20
c410  02         STAX BC
c411  03         INX BC
c412  79         MOV A, C
c413  fe 96      CPI A, 96
c415  c2 0e c4   JNZ c40e
c418  c1         POP BC
c419  cd 86 c4   CALL c486
c41c  cd 1c c3   CALL MATCH_INSTRUCTION (c31c)
c41f  11 a6 c7   LXI DE, c7a6
c422  1b         DCX DE
c423  cd d3 fb   CALL CMP_HL_DE (fbd3)
c426  c2 31 c4   JNZ c431
c429  eb         XCHG
c42a  2a 7b f7   LHLD f77b
c42d  22 87 f7   SHLD f787
c430  eb         XCHG
????:
c431  11 5b c4   LXI DE, c45b
c434  d5         PUSH DE
c435  e5         PUSH HL
c436  cd 9b c4   CALL c49b
c439  7d         MOV A, L
c43a  c6 1e      ADI A, 1e
c43c  6f         MOV L, A
c43d  cd a6 c4   CALL c4a6
c440  01 82 f7   LXI BC, f782
c443  e3         XTHL
c444  2b         DCX HL
c445  2b         DCX HL
c446  2b         DCX HL
c447  2b         DCX HL
c448  16 04      MVI D, 04
????:
c44a  7e         MOV A, M
c44b  02         STAX BC
c44c  03         INX BC
c44d  23         INX HL
c44e  15         DCR D
c44f  c2 4a c4   JNZ c44a
c452  eb         XCHG
????:
c453  2a 51 f7   LHLD ARG_1 (f751)
c456  23         INX HL
c457  22 51 f7   SHLD ARG_1 (f751)
c45a  c9         RET
????:
c45b  11 7b f7   LXI DE, f77b
????:
c45e  1a         LDAX DE
c45f  cd 28 fe   CALL fe28
c462  cd f0 f9   CALL PUT_CHAR (f9f0)
c465  13         INX DE
c466  7b         MOV A, E
c467  fe 95      CPI A, 95
c469  c2 5e c4   JNZ c45e
c46c  c1         POP BC
c46d  cd cc fb   CALL LOAD_ARGUMENTS (fbcc)
c470  d8         RC
c471  05         DCR B
c472  c2 fa c3   JNZ c3fa
c475  cd 6b fc   CALL PRINT_NEW_LINE (fc6b)
c478  c3 d1 c3   JMP c3d1
????:
c47b  01 18 1f   LXI BC, 1f18
????:
c47e  cd f0 f9   CALL PUT_CHAR (f9f0)
c481  05         DCR B
c482  c2 7e c4   JNZ c47e
c485  c9         RET
????:
c486  c5         PUSH BC
c487  79         MOV A, C
c488  c6 13      ADI A, 13
c48a  4f         MOV C, A
c48b  2a 51 f7   LHLD ARG_1 (f751)
c48e  7e         MOV A, M
c48f  02         STAX BC
c490  cd c0 f9   CALL f9c0
c493  e3         XTHL
c494  71         MOV M, C
c495  23         INX HL
c496  70         MOV M, B
c497  23         INX HL
c498  e3         XTHL
c499  c1         POP BC
c49a  c9         RET
????:
c49b  23         INX HL
c49c  7e         MOV A, M
c49d  07         RLC
c49e  6f         MOV L, A
c49f  26 00      MVI H, 00
c4a1  11 cc c7   LXI DE, c7cc
c4a4  19         DAD DE
c4a5  c9         RET
????:
c4a6  5e         MOV E, M
c4a7  23         INX HL
c4a8  56         MOV D, M
c4a9  eb         XCHG
c4aa  c9         RET
????:
c4ab  01 7d f7   LXI BC, f77d
????:
c4ae  cd 86 c4   CALL c486
c4b1  01 87 f7   LXI BC, f787
????:
c4b4  cd 86 c4   CALL c486
c4b7  c3 53 c4   JMP c453
c4ba  01 7d f7   LXI BC, f77d
c4bd  cd 86 c4   CALL c486
c4c0  01 89 f7   LXI BC, f789
c4c3  cd b4 c4   CALL c4b4
c4c6  01 7f f7   LXI BC, f77f
c4c9  c3 ae c4   JMP c4ae
????:
c4cc  01 ff 01   LXI BC, 01ff
????:
c4cf  21 c8 c7   LXI HL, c7c8
????:
c4d2  cd 24 c5   CALL c524
c4d5  32 87 f7   STA f787
c4d8  c9         RET
????:
c4d9  01 ff 10   LXI BC, 10ff
c4dc  21 cc c7   LXI HL, c7cc
c4df  c3 d2 c4   JMP c4d2
????:
c4e2  01 ff 08   LXI BC, 08ff
c4e5  c3 cf c4   JMP c4cf
????:
c4e8  cd d9 c4   CALL c4d9
c4eb  01 8b f7   LXI BC, f78b
c4ee  cd 18 c5   CALL c518
c4f1  01 89 f7   LXI BC, f789
c4f4  cd 86 c4   CALL c486
c4f7  01 7f f7   LXI BC, f77f
c4fa  c3 b4 c4   JMP c4b4
c4fd  01 c7 01   LXI BC, 01c7
c500  cd cf c4   CALL c4cf
c503  32 89 f7   STA f789
c506  01 f8 08   LXI BC, 08f8
c509  cd cf c4   CALL c4cf
????:
c50c  3e 2c      MVI A, 2c
c50e  32 88 f7   STA f788
c511  c9         RET
????:
c512  cd e2 c4   CALL c4e2
c515  01 89 f7   LXI BC, f789
????:
c518  cd 86 c4   CALL c486
c51b  01 7d f7   LXI BC, f77d
c51e  cd b4 c4   CALL c4b4
c521  c3 0c c5   JMP c50c
????:
c524  e5         PUSH HL
c525  2a 51 f7   LHLD ARG_1 (f751)
c528  2b         DCX HL
c529  7e         MOV A, M
c52a  e1         POP HL
c52b  a1         ANA C
c52c  4f         MOV C, A
c52d  1a         LDAX DE
c52e  90         SUB B
????:
c52f  2b         DCX HL
c530  80         ADD B
c531  b9         CMP C
c532  c2 2f c5   JNZ c52f
c535  7e         MOV A, M
c536  c9         RET
????:
c537  01 03 10   LXI BC, 1003
c53a  21 c8 c7   LXI HL, c7c8
c53d  c3 46 c5   JMP c546
????:
c540  01 07 08   LXI BC, 0807
????:
c543  21 c0 c7   LXI HL, c7c0
????:
c546  32 ff f7   STA f7ff
c549  cd bb c5   CALL c5bb
????:
c54c  be         CMP M
c54d  ca 5a c5   JZ c55a
c550  23         INX HL
c551  0d         DCR C
c552  f2 4c c5   JP c54c
????:
c555  d1         POP DE
????:
c556  37         STC
c557  c3 8d fb   JMP fb8d

????:
c55a  13         INX DE
c55b  cd 0b fc   CALL fc0b
c55e  da 55 c5   JC c555
c561  7c         MOV A, H
c562  b5         ORA L
c563  c2 55 c5   JNZ c555
c566  cd d5 c8   CALL c8d5
c569  3a ff f7   LDA f7ff
????:
c56c  81         ADD C
c56d  05         DCR B
c56e  c2 6c c5   JNZ c56c
c571  c9         RET
????:
c572  cd 0b fc   CALL fc0b
c575  d8         RC
c576  7c         MOV A, H
c577  b7         ORA A
c578  37         STC
c579  c0         RNZ
c57a  26 7a      MVI H, 7a
c57c  29         DAD HL
c57d  c9         RET
????:
c57e  11 cd c5   LXI DE, c5cd
????:
c581  cd b0 fd   CALL RESET_COMMAND_MODE_FLAG (fdb0)
c584  eb         XCHG
c585  cd bb c5   CALL c5bb
c588  eb         XCHG
c589  06 04      MVI B, 04
????:
c58b  1a         LDAX DE
c58c  b7         ORA A
c58d  fa 56 c5   JM c556
c590  be         CMP M
c591  c4 b5 fd   CNZ SET_COMMAND_MODE_FLAG (fdb5)
c594  13         INX DE
c595  23         INX HL
c596  05         DCR B
c597  c2 8b c5   JNZ c58b
c59a  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)
c59d  13         INX DE
c59e  13         INX DE
c59f  c2 81 c5   JNZ c581
c5a2  1b         DCX DE
c5a3  1b         DCX DE
c5a4  eb         XCHG
c5a5  cd d5 c8   CALL c8d5
c5a8  46         MOV B, M
c5a9  cd 9b c4   CALL c49b
c5ac  cd a6 c4   CALL c4a6
c5af  78         MOV A, B
c5b0  e9         PCHL
????:
c5b1  1a         LDAX DE
c5b2  fe 0d      CPI A, 0d
c5b4  c4 c9 fb   CNZ DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9)
c5b7  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)
c5ba  c9         RET
????:
c5bb  16 f7      MVI D, f7
c5bd  3a 59 f7   LDA INPUT_POLARITY (f759)
c5c0  5f         MOV E, A
c5c1  1a         LDAX DE
c5c2  fe 20      CPI A, 20
c5c4  c0         RNZ
????:
c5c5  13         INX DE
c5c6  cd d5 c8   CALL c8d5
c5c9  c3 bb c5   JMP c5bb
c5cc  00         NOP

; List of CPU instructions. Each record contains:
; - 4-char mnemonic
; - opcode
; - instruction attributes where:
;   - 0x00  - 1-byte instruction
;   - 0x01  - 2-byte instruction, 2nd byte is immediate value
;   - 0x02  - 3-byte instruction, argument is an address
;   - ...
;   - 0x07  - 3-byte instruction, argument may be an address, but not necessarily
INSTRUCTION_DESCRIPTORS:
    c5cd  41 43 49 20     db "ACI ", 0xce, 0x01
    c5d3  41 44 43 20     db "ADC ", 0x88, 0x03
    c5d9  41 44 44 20     db "ADD ", 0x80, 0x03
    c5df  41 44 49 20     db "ADI ", 0xc6, 0x01
    c5e5  41 4e 41 20     db "ANA ", 0xa0, 0x03
    c5eb  41 4e 49 20     db "ANI ", 0xe6, 0x01
    c5f1  43 41 4c 4c     db "CALL", 0xcd, 0x02
    c5f7  43 43 20 20     db "CC  ", 0xdc, 0x02
    c5fd  43 4d 20 20     db "CM  ", 0xfc, 0x02
    c603  43 4d 41 20     db "CMA ", 0x2f, 0x00
    c609  43 4d 43 20     db "CMC ", 0x3f, 0x00
    c60f  43 4d 50 20     db "CMP ", 0xb8, 0x03
    c615  43 4e 43 20     db "CNC ", 0xd4, 0x02
    c61b  43 4e 5a 20     db "CNZ ", 0xc4, 0x02
    c621  43 50 20 20     db "CP  ", 0xf4, 0x02
    c627  43 50 45 20     db "CPE ", 0xec, 0x02
    c62d  43 50 49 20     db "CPI ", 0xfe, 0x01
    c633  43 50 4f 20     db "CPO ", 0xe4, 0x02
    c639  43 5a 20 20     db "CZ  ", 0xcc, 0x02
    c63f  44 41 41 20     db "DAA ", 0x27, 0x00
    c645  44 41 44 20     db "DAD ", 0x09, 0x04
    c64b  44 43 52 20     db "DCR ", 0x05, 0x05
    c651  44 43 58 20     db "DCX ", 0x0b, 0x04
    c657  44 49 20 20     db "DI  ", 0xf3, 0x00
    c65d  45 49 20 20     db "EI  ", 0xfb, 0x00
    c663  48 4c 54 20     db "HLT ", 0x76, 0x00
    c669  49 4e 20 20     db "IN  ", 0xdb, 0xa1     ; BUG? instruction matched as 1-byte
    c66f  49 4e 52 20     db "INR ", 0x04, 0x05
    c675  49 4e 58 20     db "INX ", 0x03, 0x04
    c67b  4a 43 20 20     db "JC  ", 0xda, 0x02
    c681  4a 4d 20 20     db "JM  ", 0xfa, 0x02
    c687  4a 4d 50 20     db "JMP ", 0xc3, 0x02
    c68d  4a 4e 43 20     db "JNC ", 0xd2, 0x02
    c693  4a 4e 5a 20     db "JNZ ", 0xc2, 0x02
    c699  4a 50 20 20     db "JP  ", 0xf2, 0x02
    c69f  4a 50 45 20     db "JPE ", 0xea, 0x02
    c6a5  4a 50 4f 20     db "JPO ", 0xe2, 0x02
    c6ab  4a 5a 20 20     db "JZ  ", 0xca, 0x02
    c6b1  4c 44 41 20     db "LDA ", 0x3a, 0x02
    c6b7  4c 44 41 58     db "LDAX", 0x0a, 0x06
    c6bd  4c 48 4c 44     db "LHLD", 0x2a, 0x02
    c6c3  4c 58 49 20     db "LXI ", 0x01, 0x07
    c6c9  4d 4f 56 20     db "MOV ", 0x40, 0x08
    c6cf  4d 56 49 20     db "MVI ", 0x06, 0x09
    c6d5  4e 4f 50 20     db "NOP ", 0x00, 0x00
    c6db  4f 52 41 20     db "ORA ", 0xb0, 0x03
    c6e1  4f 52 49 20     db "ORI ", 0xf6, 0x01
    c6e7  4f 55 54 20     db "OUT ", 0xd3, 0xa1     ; BUG? instruction matched as 1-byte
    c6ed  50 43 48 4c     db "PCHL", 0xe9, 0x00
    c6f3  50 4f 50 20     db "POP ", 0xc1, 0x04
    c6f9  50 55 53 48     db "PUSH", 0xc5, 0x04
    c6ff  52 41 4c 20     db "RAL ", 0x17, 0x00
    c705  52 41 52 20     db "RAR ", 0x1f, 0x00
    c70b  52 43 20 20     db "RC  ", 0xd8, 0x00
    c711  52 45 54 20     db "RET ", 0xc9, 0x00
    c717  52 4c 43 20     db "RLC ", 0x07, 0x00
    c71d  52 4d 20 20     db "RM  ", 0xf8, 0x00
    c723  52 4e 43 20     db "RNC ", 0xd0, 0x00
    c729  52 4e 5a 20     db "RNZ ", 0xc0, 0x00
    c72f  52 50 20 20     db "RP  ", 0xf0, 0x00
    c735  52 50 45 20     db "RPE ", 0xe8, 0x00
    c73b  52 50 4f 20     db "RPO ", 0xe0, 0x00
    c741  52 52 43 20     db "RRC ", 0x0f, 0x00
    c747  52 53 54 20     db "RST ", 0xc7, 0x05
    c74d  52 5a 20 20     db "RZ  ", 0xc8, 0x00
    c753  53 42 42 20     db "SBB ", 0x98, 0x03
    c759  53 42 49 20     db "SBI ", 0xde, 0x01
    c75f  53 48 4c 44     db "SHLD", 0x22, 0x02
    c765  53 50 48 4c     db "SPHL", 0xf9, 0x00
    c76b  53 54 41 20     db "STA ", 0x32, 0x02
    c771  53 54 41 58     db "STAX", 0x02, 0x06
    c777  53 54 43 20     db "STC ", 0x37, 0x00
    c77d  53 55 42 20     db "SUB ", 0x90, 0x03
    c783  53 55 49 20     db "SUI ", 0xd6, 0x01
    c789  58 43 48 47     db "XCHG", 0xeb, 0x00
    c78f  58 52 41 20     db "XRA ", 0xa8, 0x03
    c795  58 52 49 20     db "XRI ", 0xee, 0x01
    c79b  58 54 48 4c     db "XTHL", 0xe3, 0x00
    c7a1  44 42 20 20     db "DB  ", 0x00, 0x0a
    c7a7  45 51 55 20     db "EQU ", 0x00, 0x0b
    c7ad  4f 52 47 20     db "ORG ", 0x00, 0x0c
    c7b3  44 57 20 20     db "DW  ", 0x00, 0x0d
    c7b9  44 49 52 20     db "DIR ", 0x00, 0x0e

    c7bf  ff


????:
c7c0  41         MOV B, C
c7c1  4d         MOV C, L
c7c2  4c         MOV C, H
c7c3  48         MOV C, B
c7c4  45         MOV B, L
c7c5  44         MOV B, H
c7c6  43         MOV B, E
c7c7  42         MOV B, D
????:
c7c8  53         MOV D, E
c7c9  48         MOV C, B
????:
c7ca  44         MOV B, H
c7cb  42         MOV B, D
????:
c7cc  da c8 e3   JC e3c8
c7cf  c8         RZ
c7d0  f3         DI
c7d1  c8         RZ
c7d2  29         DAD HL
c7d3  c9         RET
c7d4  32 c9 38   STA 38c9
c7d7  c9         RET
c7d8  3e c9      MVI A, c9
c7da  4a         MOV C, D
c7db  c9         RET
c7dc  50         MOV D, B
c7dd  c9         RET
c7de  56         MOV D, M
c7df  c9         RET
c7e0  76         HLT
c7e1  c9         RET
c7e2  5c         MOV E, H
c7e3  c9         RET
c7e4  b9         CMP C
c7e5  c9         RET
c7e6  d2 c9 df   JNC dfc9
c7e9  c9         RET
c7ea  aa         XRA D
c7eb  c4 ab c4   CNZ c4ab
c7ee  ba         CMP D
c7ef  c4 cc c4   CNZ c4cc
c7f2  d9         db d9
c7f3  c4 e2 c4   CNZ c4e2
c7f6  d9         db d9
c7f7  c4 e8 c4   CNZ c4e8
c7fa  fd         db fd
c7fb  c4 12 c5   CNZ c512
c7fe  aa         XRA D
c7ff  c4 3e 7b   CNZ 7b3e
c802  32 59 f7   STA INPUT_POLARITY (f759)
c805  cd bb c5   CALL c5bb
c808  fe 0d      CPI A, 0d
c80a  ca b5 fd   JZ SET_COMMAND_MODE_FLAG (fdb5)
c80d  b7         ORA A
c80e  fa b5 fd   JM SET_COMMAND_MODE_FLAG (fdb5)
c811  fe 3b      CPI A, 3b
c813  ca b0 fd   JZ RESET_COMMAND_MODE_FLAG (fdb0)
c816  cd 73 c2   CALL CHECK_AT_SYMBOL (c273)
c819  cc 22 c8   CZ c822
c81c  cd 7e c5   CALL c57e
c81f  c3 b0 fd   JMP RESET_COMMAND_MODE_FLAG (fdb0)
????:
c822  cd 72 c5   CALL c572
c825  da 8d fb   JC fb8d
c828  cd d5 c8   CALL c8d5
c82b  eb         XCHG
c82c  2a 53 f7   LHLD ARG_2 (f753)
????:
c82f  7d         MOV A, L
c830  12         STAX DE
c831  13         INX DE
c832  7c         MOV A, H
c833  12         STAX DE
c834  c9         RET
????:
c835  af         XRA A
c836  47         MOV B, A
c837  4f         MOV C, A
c838  3d         DCR A
????:
c839  32 ff f7   STA f7ff
c83c  cd bb c5   CALL c5bb
c83f  cd 73 c2   CALL CHECK_AT_SYMBOL (c273)
c842  ca 7a c8   JZ c87a
c845  fe 27      CPI A, 27
c847  ca 95 c8   JZ c895
c84a  fe 23      CPI A, 23
c84c  ca a8 c8   JZ c8a8
c84f  fe 24      CPI A, 24
c851  ca 8b c8   JZ c88b
c854  cd 0b fc   CALL fc0b
c857  da 55 c5   JC c555
????:
c85a  f5         PUSH PSW
????:
c85b  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)
c85e  c2 68 c8   JNZ c868
c861  7d         MOV A, L
c862  2f         CMA
c863  6f         MOV L, A
c864  7c         MOV A, H
c865  2f         CMA
c866  67         MOV H, A
c867  23         INX HL
????:
c868  cd d5 c8   CALL c8d5
c86b  f1         POP PSW
c86c  09         DAD BC
c86d  44         MOV B, H
c86e  4d         MOV C, L
c86f  d6 2d      SUI A, 2d
c871  ca 39 c8   JZ c839
c874  fe fe      CPI A, fe
c876  ca 39 c8   JZ c839
c879  c9         RET
????:
c87a  cd 72 c5   CALL c572
c87d  da 55 c5   JC c555
c880  1b         DCX DE
c881  1a         LDAX DE
c882  13         INX DE
c883  f5         PUSH PSW
c884  7e         MOV A, M
c885  23         INX HL
c886  66         MOV H, M
c887  6f         MOV L, A
c888  c3 5b c8   JMP c85b
????:
c88b  cd c5 c5   CALL c5c5
c88e  13         INX DE
c88f  2a 53 f7   LHLD ARG_2 (f753)
c892  c3 5a c8   JMP c85a
????:
c895  13         INX DE
c896  1a         LDAX DE
c897  26 00      MVI H, 00
c899  6f         MOV L, A
c89a  13         INX DE
c89b  1a         LDAX DE
c89c  fe 27      CPI A, 27
c89e  c2 55 c5   JNZ c555
c8a1  cd c5 c5   CALL c5c5
????:
c8a4  13         INX DE
c8a5  c3 5a c8   JMP c85a
????:
c8a8  21 00 00   LXI HL, 0000
????:
c8ab  cd c5 c5   CALL c5c5
c8ae  fe 30      CPI A, 30
c8b0  da a4 c8   JC c8a4
c8b3  fe 3a      CPI A, 3a
c8b5  d2 a4 c8   JNC c8a4
c8b8  d6 30      SUI A, 30
c8ba  d5         PUSH DE
c8bb  11 ce c8   LXI DE, c8ce
c8be  d5         PUSH DE
c8bf  29         DAD HL
c8c0  d8         RC
c8c1  54         MOV D, H
c8c2  5d         MOV E, L
c8c3  29         DAD HL
c8c4  d8         RC
c8c5  29         DAD HL
c8c6  d8         RC
c8c7  19         DAD DE
c8c8  d8         RC
c8c9  5f         MOV E, A
c8ca  16 00      MVI D, 00
c8cc  19         DAD DE
c8cd  d1         POP DE
????:
c8ce  d1         POP DE
c8cf  da 55 c5   JC c555
c8d2  c3 ab c8   JMP c8ab
????:
c8d5  7b         MOV A, E
c8d6  32 59 f7   STA INPUT_POLARITY (f759)
c8d9  c9         RET
????:
c8da  2a 53 f7   LHLD ARG_2 (f753)
c8dd  77         MOV M, A
c8de  23         INX HL
c8df  22 53 f7   SHLD ARG_2 (f753)
c8e2  c9         RET
????:
c8e3  32 60 f7   STA f760
????:
c8e6  cd 35 c8   CALL c835
????:
c8e9  3a 60 f7   LDA f760
????:
c8ec  cd da c8   CALL c8da
c8ef  79         MOV A, C
c8f0  c3 da c8   JMP c8da
????:
c8f3  32 60 f7   STA f760
c8f6  cd bb c5   CALL c5bb
c8f9  cd 73 c2   CALL CHECK_AT_SYMBOL (c273)
c8fc  c2 1a c9   JNZ c91a
c8ff  cd 72 c5   CALL c572
c902  da 56 c5   JC c556
c905  1b         DCX DE
c906  1a         LDAX DE
c907  fe 2b      CPI A, 2b
c909  ca 1a c9   JZ c91a
c90c  fe 2d      CPI A, 2d
c90e  ca 1a c9   JZ c91a
c911  e5         PUSH HL
c912  4d         MOV C, L
c913  cd e9 c8   CALL c8e9
c916  f1         POP PSW
c917  c3 da c8   JMP c8da
????:
c91a  e1         POP HL
c91b  22 5e f7   SHLD f75e
c91e  cd e6 c8   CALL c8e6
c921  78         MOV A, B
c922  cd da c8   CALL c8da
c925  2a 5e f7   LHLD f75e
c928  e9         PCHL
????:
c929  01 07 01   LXI BC, 0107
c92c  cd 43 c5   CALL c543
c92f  c3 da c8   JMP c8da
c932  cd 37 c5   CALL c537
c935  c3 da c8   JMP c8da
c938  cd 40 c5   CALL c540
c93b  c3 da c8   JMP c8da
c93e  01 01 10   LXI BC, 1001
c941  21 ca c7   LXI HL, c7ca
c944  cd 46 c5   CALL c546
c947  c3 da c8   JMP c8da
c94a  cd 37 c5   CALL c537
c94d  c3 f3 c8   JMP c8f3
c950  cd 40 c5   CALL c540
c953  c3 29 c9   JMP c929
c956  cd 40 c5   CALL c540
c959  c3 e3 c8   JMP c8e3
c95c  cd 35 c8   CALL c835
c95f  1e 7a      MVI E, 7a
c961  cd c5 c5   CALL c5c5
c964  cd 73 c2   CALL CHECK_AT_SYMBOL (c273)
c967  c2 56 c5   JNZ c556
c96a  cd 72 c5   CALL c572
c96d  da 56 c5   JC c556
c970  50         MOV D, B
c971  59         MOV E, C
c972  eb         XCHG
c973  c3 2f c8   JMP c82f
????:
c976  cd bb c5   CALL c5bb
c979  fe 27      CPI A, 27
c97b  ca 8d c9   JZ c98d
c97e  cd 35 c8   CALL c835
c981  3c         INR A
c982  79         MOV A, C
c983  cd da c8   CALL c8da
????:
c986  cd d5 c8   CALL c8d5
c989  ca 76 c9   JZ c976
c98c  c9         RET
????:
c98d  13         INX DE
c98e  1a         LDAX DE
c98f  fe 27      CPI A, 27
c991  ca a6 c9   JZ c9a6
????:
c994  cd da c8   CALL c8da
c997  13         INX DE
c998  1a         LDAX DE
c999  fe 27      CPI A, 27
c99b  ca b0 c9   JZ c9b0
c99e  fe 0d      CPI A, 0d
c9a0  ca 56 c5   JZ c556
c9a3  c3 94 c9   JMP c994
????:
c9a6  13         INX DE
c9a7  1a         LDAX DE
c9a8  fe 27      CPI A, 27
c9aa  c2 56 c5   JNZ c556
c9ad  cd da c8   CALL c8da
????:
c9b0  cd c5 c5   CALL c5c5
c9b3  fe 2c      CPI A, 2c
c9b5  13         INX DE
c9b6  c3 86 c9   JMP c986
c9b9  cd 35 c8   CALL c835
c9bc  eb         XCHG
c9bd  cd 6b fc   CALL PRINT_NEW_LINE (fc6b)
c9c0  cd 4a fc   CALL fc4a
c9c3  2a 53 f7   LHLD ARG_2 (f753)
c9c6  2b         DCX HL
c9c7  cd 4d fc   CALL PRINT_HL (fc4d)
c9ca  eb         XCHG
c9cb  22 51 f7   SHLD ARG_1 (f751)
c9ce  22 53 f7   SHLD ARG_2 (f753)
c9d1  c9         RET
????:
c9d2  cd 35 c8   CALL c835
c9d5  3c         INR A
c9d6  79         MOV A, C
c9d7  48         MOV C, B
c9d8  cd ec c8   CALL c8ec
c9db  ca d2 c9   JZ c9d2
c9de  c9         RET
c9df  cd bb c5   CALL c5bb
c9e2  21 7b f7   LXI HL, f77b
????:
c9e5  1a         LDAX DE
c9e6  fe 0d      CPI A, 0d
c9e8  77         MOV M, A
c9e9  13         INX DE
c9ea  23         INX HL
c9eb  c2 e5 c9   JNZ c9e5
c9ee  2a 51 f7   LHLD ARG_1 (f751)
c9f1  e5         PUSH HL
c9f2  2a 53 f7   LHLD ARG_2 (f753)
c9f5  e5         PUSH HL
c9f6  2a 55 f7   LHLD ARG_3 (f755)
c9f9  e5         PUSH HL
c9fa  2a 57 f7   LHLD ARG_4 (f757)
c9fd  e5         PUSH HL
c9fe  21 9c ff   LXI HL, ff9c
ca01  3a 7b f7   LDA f77b
ca04  47         MOV B, A
ca05  fe 58      CPI A, 58
ca07  f5         PUSH PSW
ca08  c4 53 f8   CNZ f853
ca0b  f1         POP PSW
ca0c  e1         POP HL
ca0d  22 57 f7   SHLD ARG_4 (f757)
ca10  e1         POP HL
ca11  22 55 f7   SHLD ARG_3 (f755)
ca14  e1         POP HL
ca15  22 53 f7   SHLD ARG_2 (f753)
ca18  e1         POP HL
ca19  22 51 f7   SHLD ARG_1 (f751)
ca1c  c0         RNZ
ca1d  c3 56 c5   JMP c556
ca20  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)
ca23  f5         PUSH PSW
ca24  21 00 a0   LXI HL, a000
ca27  22 51 f7   SHLD ARG_1 (f751)
ca2a  22 53 f7   SHLD ARG_2 (f753)
ca2d  cd b1 c5   CALL c5b1
ca30  21 00 30   LXI HL, 3000
ca33  22 55 f7   SHLD ARG_3 (f755)
????:
ca36  11 7b f7   LXI DE, f77b
ca39  2a 55 f7   LHLD ARG_3 (f755)
ca3c  22 57 f7   SHLD ARG_4 (f757)
????:
ca3f  7e         MOV A, M
ca40  12         STAX DE
ca41  23         INX HL
ca42  13         INX DE
ca43  fe 0d      CPI A, 0d
ca45  ca 57 ca   JZ ca57
ca48  7b         MOV A, E
ca49  fe bb      CPI A, bb
ca4b  c2 3f ca   JNZ ca3f
????:
ca4e  2a 57 f7   LHLD ARG_4 (f757)
ca51  cd 4d fc   CALL PRINT_HL (fc4d)
ca54  c3 6c ca   JMP ca6c
????:
ca57  22 55 f7   SHLD ARG_3 (f755)
ca5a  cd 00 c8   CALL c800
ca5d  da 4e ca   JC ca4e
ca60  cd 4b fb   CALL fb4b
ca63  dc b5 fd   CC SET_COMMAND_MODE_FLAG (fdb5)
ca66  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)
ca69  f2 36 ca   JP ca36
????:
ca6c  cd 4a fc   CALL fc4a
ca6f  2a 53 f7   LHLD ARG_2 (f753)
ca72  2b         DCX HL
ca73  cd 4d fc   CALL PRINT_HL (fc4d)
ca76  f1         POP PSW
ca77  c0         RNZ
ca78  3e 40      MVI A, 40
ca7a  cd e9 f9   CALL PUT_CHAR_A (f9e9)
????:
ca7d  2a 51 f7   LHLD ARG_1 (f751)
ca80  7e         MOV A, M
ca81  cd 1c c3   CALL MATCH_INSTRUCTION (c31c)
ca84  dc 98 ca   CC ca98
ca87  2a 51 f7   LHLD ARG_1 (f751)
ca8a  06 00      MVI B, 00
ca8c  09         DAD BC
ca8d  22 51 f7   SHLD ARG_1 (f751)
ca90  cd cc fb   CALL LOAD_ARGUMENTS (fbcc)
ca93  c8         RZ
ca94  d8         RC
ca95  c3 7d ca   JMP ca7d
????:
ca98  2a 51 f7   LHLD ARG_1 (f751)
ca9b  23         INX HL
ca9c  23         INX HL
ca9d  7e         MOV A, M
ca9e  e6 fe      ANI A, fe
caa0  fe f4      CPI A, f4
caa2  c0         RNZ
caa3  56         MOV D, M
caa4  2b         DCX HL
caa5  5e         MOV E, M
caa6  1a         LDAX DE
caa7  77         MOV M, A
caa8  13         INX DE
caa9  23         INX HL
caaa  1a         LDAX DE
caab  77         MOV M, A
caac  c9         RET
caad  21 fe af   LXI HL, affe
cab0  22 53 f7   SHLD ARG_2 (f753)
cab3  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)
cab6  21 00 a0   LXI HL, a000
cab9  22 51 f7   SHLD ARG_1 (f751)
cabc  cd b1 c5   CALL c5b1
cabf  c3 7d ca   JMP ca7d
cac2  21 00 a0   LXI HL, a000
cac5  22 53 f7   SHLD ARG_2 (f753)
cac8  22 51 f7   SHLD ARG_1 (f751)
cacb  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)
cace  f5         PUSH PSW
cacf  cd b1 c5   CALL c5b1
????:
cad2  cd 6b fc   CALL PRINT_NEW_LINE (fc6b)
cad5  2a 53 f7   LHLD ARG_2 (f753)
cad8  cd 4d fc   CALL PRINT_HL (fc4d)
cadb  cd 8b fa   CALL INPUT_LINE (fa8b)
cade  cd 00 c8   CALL c800
cae1  da d2 ca   JC cad2
cae4  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)
cae7  f2 d2 ca   JP cad2
caea  c3 6c ca   JMP ca6c
caed  00         NOP
caee  00         NOP
caef  00         NOP
caf0  00         NOP
caf1  00         NOP
caf2  00         NOP
caf3  00         NOP
caf4  00         NOP
caf5  00         NOP
caf6  00         NOP
caf7  00         NOP
caf8  00         NOP
caf9  00         NOP
cafa  00         NOP
cafb  00         NOP
cafc  00         NOP
cafd  00         NOP
cafe  00         NOP
caff  00         NOP






cb00  0e 1f      MVI C, 1f
cb02  cd 09 f8   CALL f809
cb05  21 00 00   LXI HL, 0000
cb08  39         DAD SP
cb09  22 2f f7   SHLD f72f
????:
cb0c  2a 2f f7   LHLD f72f
cb0f  f9         SPHL
cb10  cd 12 cc   CALL cc12
cb13  21 00 30   LXI HL, 3000
cb16  22 29 f7   SHLD f729
cb19  22 2b f7   SHLD f72b
cb1c  cd 9b cf   CALL cf9b
cb1f  22 27 f7   SHLD f727
cb22  cd 6f ce   CALL ce6f
cb25  eb         XCHG
cb26  32 22 f7   STA f722
cb29  32 26 f7   STA f726
cb2c  3d         DCR A
cb2d  32 21 f7   STA f721
cb30  32 23 f7   STA f723
cb33  32 25 f7   STA f725
cb36  2b         DCX HL
cb37  77         MOV M, A
cb38  23         INX HL
cb39  3e 03      MVI A, 03
cb3b  32 24 f7   STA f724
????:
cb3e  01 3e cb   LXI BC, cb3e
cb41  c5         PUSH BC
cb42  cd b4 cb   CALL cbb4
cb45  ca 95 cb   JZ cb95
cb48  fe 08      CPI A, 08
cb4a  ca 01 ce   JZ ce01
cb4d  fe 18      CPI A, 18
cb4f  ca 85 cb   JZ cb85
cb52  fe 19      CPI A, 19
cb54  ca 1f ce   JZ ce1f
cb57  fe 1a      CPI A, 1a
cb59  ca 34 cf   JZ cf34
cb5c  fe 0c      CPI A, 0c
cb5e  ca b1 ce   JZ ceb1
cb61  fe 1f      CPI A, 1f
cb63  c2 6b cb   JNZ cb6b
cb66  cd ce ce   CALL cece
cb69  c1         POP BC
cb6a  c9         RET
????:
cb6b  fe 0d      CPI A, 0d
cb6d  ca db cc   JZ ccdb
cb70  cd aa cb   CALL cbaa
cb73  3a 26 f7   LDA f726
cb76  b7         ORA A
cb77  c2 7f cb   JNZ cb7f
cb7a  c5         PUSH BC
cb7b  cd 62 d0   CALL d062
cb7e  c1         POP BC
????:
cb7f  7e         MOV A, M
cb80  b7         ORA A
cb81  ca db cc   JZ ccdb
cb84  71         MOV M, C
????:
cb85  3a 23 f7   LDA f723
cb88  fe 3e      CPI A, 3e
cb8a  d2 db cc   JNC ccdb
cb8d  3c         INR A
cb8e  32 23 f7   STA f723
cb91  23         INX HL
cb92  c3 09 f8   JMP f809
????:
cb95  e5         PUSH HL
cb96  21 4a d3   LXI HL, d34a
????:
cb99  7e         MOV A, M
cb9a  b7         ORA A
cb9b  ca da cc   JZ ccda
cb9e  b9         CMP C
cb9f  23         INX HL
cba0  5e         MOV E, M
cba1  23         INX HL
cba2  56         MOV D, M
cba3  23         INX HL
cba4  c2 99 cb   JNZ cb99
cba7  e1         POP HL
cba8  d5         PUSH DE
cba9  c9         RET
????:
cbaa  7e         MOV A, M
cbab  b7         ORA A
cbac  c0         RNZ
cbad  2b         DCX HL
cbae  b6         ORA M
cbaf  23         INX HL
cbb0  c0         RNZ
cbb1  c3 dc cc   JMP ccdc
????:
cbb4  cd 03 f8   CALL f803
cbb7  4f         MOV C, A
cbb8  db 05      IN 05
cbba  e6 80      ANI A, 80
cbbc  79         MOV A, C
cbbd  c9         RET
cbbe  e5         PUSH HL
cbbf  2a 2b f7   LHLD f72b
cbc2  e3         XTHL
cbc3  c3 cb cb   JMP cbcb
cbc6  e5         PUSH HL
cbc7  21 00 30   LXI HL, 3000
cbca  e3         XTHL
????:
cbcb  cd fd cb   CALL cbfd
cbce  cd 20 cc   CALL cc20
cbd1  dc 6f ce   CC ce6f
cbd4  44         MOV B, H
cbd5  4d         MOV C, L
cbd6  2a 27 f7   LHLD f727
cbd9  eb         XCHG
cbda  e1         POP HL
cbdb  e5         PUSH HL
????:
cbdc  c5         PUSH BC
cbdd  e5         PUSH HL
????:
cbde  0a         LDAX BC
cbdf  b7         ORA A
cbe0  ca f0 cc   JZ ccf0
cbe3  be         CMP M
cbe4  23         INX HL
cbe5  03         INX BC
cbe6  ca de cb   JZ cbde
cbe9  cd ea cc   CALL ccea
cbec  e1         POP HL
cbed  c1         POP BC
cbee  23         INX HL
cbef  da dc cb   JC cbdc
cbf2  0e 3f      MVI C, 3f
cbf4  cd 09 f8   CALL f809
????:
cbf7  cd db cc   CALL ccdb
cbfa  c3 0c cb   JMP cb0c
????:
cbfd  f5         PUSH PSW
cbfe  cd ce ce   CALL cece
cc01  f1         POP PSW
cc02  0e 1f      MVI C, 1f
cc04  cd 09 f8   CALL f809
cc07  cd 12 cc   CALL cc12
????:
cc0a  cd 81 cd   CALL cd81
cc0d  0e 20      MVI C, 20
cc0f  c3 09 f8   JMP f809
????:
cc12  e5         PUSH HL
cc13  21 23 d3   LXI HL, d323
????:
cc16  cd 18 f8   CALL f818
cc19  e1         POP HL
cc1a  c9         RET
????:
cc1b  0e 0c      MVI C, 0c
cc1d  c3 09 f8   JMP f809
????:
cc20  cd 6f ce   CALL ce6f
cc23  62         MOV H, D
cc24  6b         MOV L, E
cc25  32 23 f7   STA f723
????:
cc28  cd ca cc   CALL ccca
cc2b  cd b4 cb   CALL cbb4
cc2e  c2 68 cc   JNZ cc68
cc31  fe 20      CPI A, 20
cc33  c2 d4 cc   JNZ ccd4
cc36  3a 24 f7   LDA f724
cc39  2f         CMA
cc3a  4f         MOV C, A
cc3b  3a 23 f7   LDA f723
cc3e  47         MOV B, A
cc3f  a1         ANA C
cc40  91         SUB C
cc41  fe 40      CPI A, 40
cc43  d2 d4 cc   JNC ccd4
cc46  90         SUB B
cc47  47         MOV B, A
????:
cc48  4e         MOV C, M
cc49  79         MOV A, C
cc4a  b7         ORA A
cc4b  c2 51 cc   JNZ cc51
cc4e  0e 20      MVI C, 20
cc50  71         MOV M, C
????:
cc51  3a 23 f7   LDA f723
cc54  3c         INR A
cc55  fe 3f      CPI A, 3f
cc57  d2 d4 cc   JNC ccd4
cc5a  32 23 f7   STA f723
cc5d  23         INX HL
cc5e  cd 09 f8   CALL f809
cc61  05         DCR B
cc62  c2 48 cc   JNZ cc48
cc65  c3 28 cc   JMP cc28
????:
cc68  b7         ORA A
cc69  ca d4 cc   JZ ccd4
cc6c  fe 0c      CPI A, 0c
cc6e  ca d4 cc   JZ ccd4
cc71  fe 1f      CPI A, 1f
cc73  ca a8 cc   JZ cca8
cc76  4f         MOV C, A
cc77  fe 08      CPI A, 08
cc79  ca b1 cc   JZ ccb1
cc7c  fe 18      CPI A, 18
cc7e  ca ac cc   JZ ccac
cc81  fe 19      CPI A, 19
cc83  ca d4 cc   JZ ccd4
cc86  fe 1a      CPI A, 1a
cc88  ca d4 cc   JZ ccd4
cc8b  d6 0d      SUI A, 0d
cc8d  c2 ab cc   JNZ ccab
cc90  77         MOV M, A
cc91  3a 23 f7   LDA f723
cc94  3c         INR A
cc95  32 22 f7   STA f722
cc98  eb         XCHG
cc99  0e 0a      MVI C, 0a
cc9b  cd 09 f8   CALL f809
????:
cc9e  0e 0a      MVI C, 0a
cca0  cd 09 f8   CALL f809
cca3  0e 19      MVI C, 19
cca5  c3 09 f8   JMP f809
????:
cca8  eb         XCHG
cca9  37         STC
ccaa  c9         RET
????:
ccab  71         MOV M, C
????:
ccac  06 01      MVI B, 01
ccae  c3 48 cc   JMP cc48
????:
ccb1  3a 23 f7   LDA f723
ccb4  3d         DCR A
ccb5  fa d4 cc   JM ccd4
ccb8  32 23 f7   STA f723
ccbb  3e 20      MVI A, 20
ccbd  cd 81 cd   CALL cd81
ccc0  2b         DCX HL
ccc1  cd 09 f8   CALL f809
ccc4  cd 09 f8   CALL f809
ccc7  c3 28 cc   JMP cc28
????:
ccca  0e 23      MVI C, 23
cccc  cd 09 f8   CALL f809
????:
cccf  0e 08      MVI C, 08
ccd1  c3 09 f8   JMP f809
????:
ccd4  cd db cc   CALL ccdb
ccd7  c3 28 cc   JMP cc28
????:
ccda  e1         POP HL
????:
ccdb  c5         PUSH BC
????:
ccdc  f5         PUSH PSW
ccdd  3e 55      MVI A, 55
ccdf  47         MOV B, A
????:
cce0  cd 0c f8   CALL f80c
cce3  05         DCR B
cce4  c2 e0 cc   JNZ cce0
cce7  f1         POP PSW
cce8  c1         POP BC
cce9  c9         RET
????:
ccea  7c         MOV A, H
cceb  ba         CMP D
ccec  c0         RNZ
cced  7d         MOV A, L
ccee  bb         CMP E
ccef  c9         RET
????:
ccf0  c1         POP BC
ccf1  c1         POP BC
ccf2  d1         POP DE
ccf3  7e         MOV A, M
ccf4  fe 0d      CPI A, 0d
ccf6  c2 fa cc   JNZ ccfa
ccf9  2b         DCX HL
????:
ccfa  cd 53 ce   CALL ce53
????:
ccfd  cd 1b cc   CALL cc1b
cd00  22 29 f7   SHLD f729
cd03  af         XRA A
cd04  32 23 f7   STA f723
cd07  06 1f      MVI B, 1f
????:
cd09  0e 3f      MVI C, 3f
cd0b  cd 6f ce   CALL ce6f
????:
cd0e  7e         MOV A, M
cd0f  fe 0d      CPI A, 0d
cd11  c2 74 cd   JNZ cd74
cd14  3e 2a      MVI A, 2a
cd16  cd 81 cd   CALL cd81
cd19  c5         PUSH BC
cd1a  41         MOV B, C
cd1b  3e 01      MVI A, 01
cd1d  0e 20      MVI C, 20
cd1f  cd 97 d0   CALL d097
cd22  c1         POP BC
cd23  23         INX HL
cd24  7e         MOV A, M
cd25  2b         DCX HL
cd26  b7         ORA A
cd27  fa 32 cd   JM cd32
cd2a  05         DCR B
cd2b  ca 33 cd   JZ cd33
cd2e  23         INX HL
cd2f  c3 09 cd   JMP cd09
????:
cd32  05         DCR B
????:
cd33  3e 08      MVI A, 08
cd35  cd 81 cd   CALL cd81
cd38  cd 81 cd   CALL cd81
cd3b  3e 3f      MVI A, 3f
cd3d  91         SUB C
cd3e  4f         MOV C, A
cd3f  32 21 f7   STA f721
cd42  32 22 f7   STA f722
cd45  3e 1e      MVI A, 1e
cd47  90         SUB B
cd48  32 25 f7   STA f725
cd4b  79         MOV A, C
cd4c  2f         CMA
cd4d  3c         INR A
cd4e  ca 55 cd   JZ cd55
cd51  4f         MOV C, A
cd52  06 ff      MVI B, ff
cd54  09         DAD BC
????:
cd55  22 2b f7   SHLD f72b
cd58  11 e0 f6   LXI DE, f6e0
cd5b  eb         XCHG
????:
cd5c  3a 25 f7   LDA f725
cd5f  f5         PUSH PSW
cd60  47         MOV B, A
cd61  3e 1f      MVI A, 1f
cd63  90         SUB B
cd64  01 20 40   LXI BC, 4020
cd67  cd 97 d0   CALL d097
cd6a  cd 16 cc   CALL cc16
cd6d  f1         POP PSW
cd6e  01 1a 01   LXI BC, 011a
cd71  c3 97 d0   JMP d097
????:
cd74  0d         DCR C
cd75  12         STAX DE
cd76  ca 0f ce   JZ ce0f
cd79  cd 81 cd   CALL cd81
cd7c  23         INX HL
cd7d  13         INX DE
cd7e  c3 0e cd   JMP cd0e
????:
cd81  c5         PUSH BC
cd82  4f         MOV C, A
cd83  cd 09 f8   CALL f809
cd86  c1         POP BC
cd87  c9         RET
cd88  f5         PUSH PSW
cd89  3a 24 f7   LDA f724
cd8c  fe 07      CPI A, 07
cd8e  c2 96 cd   JNZ cd96
cd91  3e 03      MVI A, 03
cd93  c3 98 cd   JMP cd98
????:
cd96  3e 07      MVI A, 07
????:
cd98  32 24 f7   STA f724
cd9b  f1         POP PSW
cd9c  c9         RET
cd9d  f5         PUSH PSW
cd9e  3a 26 f7   LDA f726
cda1  2f         CMA
cda2  32 26 f7   STA f726
cda5  f1         POP PSW
cda6  c9         RET
cda7  d5         PUSH DE
cda8  e5         PUSH HL
cda9  11 2d 20   LXI DE, 202d
cdac  2a 5c f7   LHLD f75c
cdaf  cd ea cc   CALL ccea
cdb2  c2 b8 cd   JNZ cdb8
cdb5  11 14 10   LXI DE, 1014
????:
cdb8  eb         XCHG
cdb9  22 5c f7   SHLD f75c
cdbc  e1         POP HL
cdbd  d1         POP DE
cdbe  c9         RET
cdbf  cd fd cb   CALL cbfd
cdc2  21 34 d3   LXI HL, d334
cdc5  cd 18 f8   CALL f818
cdc8  e5         PUSH HL
cdc9  2a 27 f7   LHLD f727
cdcc  cd f9 cd   CALL cdf9
cdcf  eb         XCHG
cdd0  e1         POP HL
cdd1  cd 18 f8   CALL f818
cdd4  e5         PUSH HL
cdd5  21 00 30   LXI HL, 3000
cdd8  eb         XCHG
cdd9  e5         PUSH HL
cdda  cd f2 cd   CALL cdf2
cddd  23         INX HL
cdde  cd f9 cd   CALL cdf9
cde1  d1         POP DE
cde2  e1         POP HL
cde3  cd 18 f8   CALL f818
cde6  21 ff 9f   LXI HL, 9fff
cde9  cd f2 cd   CALL cdf2
cdec  cd f9 cd   CALL cdf9
cdef  c3 0c cb   JMP cb0c
????:
cdf2  7d         MOV A, L
cdf3  93         SUB E
cdf4  6f         MOV L, A
cdf5  7c         MOV A, H
cdf6  9a         SBB D
cdf7  67         MOV H, A
cdf8  c9         RET
????:
cdf9  7c         MOV A, H
cdfa  cd 15 f8   CALL f815
cdfd  7d         MOV A, L
cdfe  c3 15 f8   JMP f815
????:
ce01  3a 23 f7   LDA f723
ce04  3d         DCR A
ce05  fa db cc   JM ccdb
ce08  32 23 f7   STA f723
ce0b  2b         DCX HL
ce0c  c3 09 f8   JMP f809
????:
ce0f  11 f6 d2   LXI DE, d2f6
????:
ce12  21 ee d2   LXI HL, d2ee
ce15  cd 18 f8   CALL f818
ce18  eb         XCHG
ce19  cd 18 f8   CALL f818
ce1c  c3 f7 cb   JMP cbf7
????:
ce1f  cd 80 ce   CALL ce80
ce22  fa b4 ce   JM ceb4
ce25  2a 2b f7   LHLD f72b
ce28  cd 51 ce   CALL ce51
????:
ce2b  22 2b f7   SHLD f72b
ce2e  cd 6f ce   CALL ce6f
ce31  d5         PUSH DE
ce32  06 00      MVI B, 00
????:
ce34  7e         MOV A, M
ce35  fe 0d      CPI A, 0d
ce37  ca 41 ce   JZ ce41
ce3a  12         STAX DE
ce3b  04         INR B
ce3c  23         INX HL
ce3d  13         INX DE
ce3e  c3 34 ce   JMP ce34
????:
ce41  78         MOV A, B
ce42  32 21 f7   STA f721
ce45  32 22 f7   STA f722
ce48  e1         POP HL
ce49  3a 23 f7   LDA f723
ce4c  5f         MOV E, A
ce4d  16 00      MVI D, 00
ce4f  19         DAD DE
ce50  c9         RET
????:
ce51  2b         DCX HL
ce52  2b         DCX HL
????:
ce53  c1         POP BC
ce54  cd ea cc   CALL ccea
ce57  ca fd cc   JZ ccfd
ce5a  7e         MOV A, M
ce5b  fe 0d      CPI A, 0d
ce5d  c5         PUSH BC
ce5e  23         INX HL
ce5f  c8         RZ
ce60  c3 51 ce   JMP ce51
????:
ce63  cd ea cc   CALL ccea
ce66  ca fd cc   JZ ccfd
ce69  cd 51 ce   CALL ce51
ce6c  c3 fd cc   JMP ccfd
????:
ce6f  c5         PUSH BC
ce70  06 3f      MVI B, 3f
ce72  11 e0 f6   LXI DE, f6e0
ce75  d5         PUSH DE
ce76  af         XRA A
????:
ce77  12         STAX DE
ce78  13         INX DE
ce79  05         DCR B
ce7a  c2 77 ce   JNZ ce77
ce7d  d1         POP DE
ce7e  c1         POP BC
ce7f  c9         RET
????:
ce80  cd 09 f8   CALL f809
ce83  cd ce ce   CALL cece
ce86  21 25 f7   LXI HL, f725
ce89  35         DCR M
ce8a  2a 29 f7   LHLD f729
ce8d  11 00 30   LXI DE, 3000
ce90  c9         RET
ce91  cd ce ce   CALL cece
ce94  2a 29 f7   LHLD f729
ce97  06 1e      MVI B, 1e
????:
ce99  11 00 30   LXI DE, 3000
????:
ce9c  cd ea cc   CALL ccea
ce9f  ca fd cc   JZ ccfd
cea2  2e 7e      MVI L, 7e
cea4  fe 0d      CPI A, 0d
cea6  c2 9c ce   JNZ ce9c
cea9  05         DCR B
ceaa  c2 9c ce   JNZ ce9c
cead  23         INX HL
ceae  c3 fd cc   JMP ccfd
????:
ceb1  cd 80 ce   CALL ce80
????:
ceb4  fc 63 ce   CM ce63
ceb7  af         XRA A
ceb8  32 23 f7   STA f723
cebb  32 25 f7   STA f725
cebe  cd 1b cc   CALL cc1b
cec1  2a 29 f7   LHLD f729
cec4  c3 26 ce   JMP ce26
????:
cec7  3a 23 f7   LDA f723
ceca  b7         ORA A
cecb  c2 dc cc   JNZ ccdc
????:
cece  3a 21 f7   LDA f721
ced1  b7         ORA A
ced2  f8         RM
ced3  4f         MOV C, A
ced4  06 00      MVI B, 00
ced6  2a 2b f7   LHLD f72b
ced9  e5         PUSH HL
ceda  09         DAD BC
cedb  c2 df ce   JNZ cedf
cede  2b         DCX HL
????:
cedf  3a 22 f7   LDA f722
cee2  91         SUB C
cee3  5f         MOV E, A
cee4  16 00      MVI D, 00
cee6  fc fe ce   CM cefe
cee9  c4 18 cf   CNZ cf18
ceec  d1         POP DE
ceed  21 e0 f6   LXI HL, f6e0
????:
cef0  7e         MOV A, M
cef1  b7         ORA A
cef2  c2 f7 ce   JNZ cef7
cef5  3e 0d      MVI A, 0d
????:
cef7  12         STAX DE
cef8  c8         RZ
cef9  23         INX HL
cefa  13         INX DE
cefb  c3 f0 ce   JMP cef0
????:
cefe  15         DCR D
ceff  e5         PUSH HL
cf00  19         DAD DE
cf01  44         MOV B, H
cf02  4d         MOV C, L
cf03  2a 27 f7   LHLD f727
cf06  e5         PUSH HL
cf07  19         DAD DE
cf08  22 27 f7   SHLD f727
cf0b  d1         POP DE
cf0c  e1         POP HL
????:
cf0d  7e         MOV A, M
cf0e  02         STAX BC
cf0f  cd ea cc   CALL ccea
cf12  c8         RZ
cf13  23         INX HL
cf14  03         INX BC
cf15  c3 0d cf   JMP cf0d
????:
cf18  23         INX HL
cf19  e5         PUSH HL
cf1a  2a 27 f7   LHLD f727
cf1d  e5         PUSH HL
cf1e  19         DAD DE
cf1f  cd aa cf   CALL cfaa
cf22  44         MOV B, H
cf23  4d         MOV C, L
cf24  22 27 f7   SHLD f727
cf27  e1         POP HL
cf28  d1         POP DE
????:
cf29  7e         MOV A, M
cf2a  02         STAX BC
cf2b  cd ea cc   CALL ccea
cf2e  c8         RZ
cf2f  2b         DCX HL
cf30  0b         DCX BC
cf31  c3 29 cf   JMP cf29
????:
cf34  3a 25 f7   LDA f725
cf37  b7         ORA A
cf38  fa 0e d0   JM d00e
cf3b  0e 1a      MVI C, 1a
cf3d  cd 09 f8   CALL f809
cf40  cd ce ce   CALL cece
cf43  cd 89 cf   CALL cf89
cf46  21 25 f7   LXI HL, f725
cf49  34         INR M
cf4a  7e         MOV A, M
cf4b  fe 1f      CPI A, 1f
cf4d  f2 5e cf   JP cf5e
cf50  3a 22 f7   LDA f722
cf53  4f         MOV C, A
cf54  2a 2b f7   LHLD f72b
cf57  06 00      MVI B, 00
cf59  09         DAD BC
cf5a  23         INX HL
cf5b  c3 2b ce   JMP ce2b
????:
cf5e  2a 29 f7   LHLD f729
????:
cf61  7e         MOV A, M
cf62  d6 0d      SUI A, 0d
cf64  23         INX HL
cf65  c2 61 cf   JNZ cf61
cf68  c3 fd cc   JMP ccfd
????:
cf6b  cd ce ce   CALL cece
cf6e  cd 89 cf   CALL cf89
cf71  2a 29 f7   LHLD f729
cf74  06 1f      MVI B, 1f
????:
cf76  7e         MOV A, M
cf77  fe 0d      CPI A, 0d
cf79  ca 80 cf   JZ cf80
????:
cf7c  23         INX HL
cf7d  c3 76 cf   JMP cf76
????:
cf80  05         DCR B
cf81  c2 7c cf   JNZ cf7c
????:
cf84  06 02      MVI B, 02
cf86  c3 99 ce   JMP ce99
????:
cf89  2a 2b f7   LHLD f72b
cf8c  3a 22 f7   LDA f722
cf8f  4f         MOV C, A
cf90  06 00      MVI B, 00
cf92  09         DAD BC
cf93  23         INX HL
cf94  7e         MOV A, M
cf95  b7         ORA A
cf96  f0         RP
cf97  c1         POP BC
cf98  c3 fe d0   JMP d0fe
????:
cf9b  21 00 30   LXI HL, 3000
????:
cf9e  7e         MOV A, M
cf9f  b7         ORA A
cfa0  f8         RM
cfa1  06 00      MVI B, 00
cfa3  cd aa cf   CALL cfaa
cfa6  23         INX HL
cfa7  c3 9e cf   JMP cf9e
????:
cfaa  eb         XCHG
cfab  21 ff 9f   LXI HL, 9fff
cfae  eb         XCHG
cfaf  cd ea cc   CALL ccea
cfb2  d8         RC
cfb3  36 ff      MVI M, ff
cfb5  11 02 d3   LXI DE, d302
cfb8  c3 12 ce   JMP ce12
cfbb  cd c7 ce   CALL cec7
cfbe  2a 29 f7   LHLD f729
cfc1  22 31 f7   SHLD f731
cfc4  2a 2b f7   LHLD f72b
cfc7  22 2d f7   SHLD f72d
cfca  cd ca cc   CALL ccca
????:
cfcd  cd b4 cb   CALL cbb4
cfd0  ca e4 cf   JZ cfe4
cfd3  d6 19      SUI A, 19
cfd5  ca 3f d0   JZ d03f
cfd8  3d         DCR A
cfd9  ca 14 d0   JZ d014
cfdc  fe 05      CPI A, 05
cfde  ca 0e d0   JZ d00e
cfe1  c3 ee cf   JMP cfee
????:
cfe4  fe 1a      CPI A, 1a
cfe6  ca 23 d0   JZ d023
cfe9  fe 44      CPI A, 44
cfeb  ca f4 cf   JZ cff4
????:
cfee  cd db cc   CALL ccdb
cff1  c3 cd cf   JMP cfcd
????:
cff4  2a 27 f7   LHLD f727
cff7  eb         XCHG
cff8  2a 31 f7   LHLD f731
cffb  22 29 f7   SHLD f729
cffe  2a 2d f7   LHLD f72d
d001  44         MOV B, H
d002  4d         MOV C, L
d003  2a 2b f7   LHLD f72b
d006  cd 0d cf   CALL cf0d
d009  60         MOV H, B
d00a  69         MOV L, C
d00b  22 27 f7   SHLD f727
????:
d00e  2a 29 f7   LHLD f729
d011  c3 fd cc   JMP ccfd
????:
d014  cd 2f d0   CALL d02f
d017  ca ee cf   JZ cfee
d01a  cd 34 cf   CALL cf34
????:
d01d  cd 9e cc   CALL cc9e
d020  c3 cd cf   JMP cfcd
????:
d023  cd 2f d0   CALL d02f
d026  ca ee cf   JZ cfee
d029  cd 6b cf   CALL cf6b
d02c  c3 1d d0   JMP d01d
????:
d02f  e5         PUSH HL
d030  2a 2b f7   LHLD f72b
d033  3a 22 f7   LDA f722
d036  5f         MOV E, A
d037  16 00      MVI D, 00
d039  19         DAD DE
d03a  23         INX HL
d03b  7e         MOV A, M
d03c  3c         INR A
d03d  e1         POP HL
d03e  c9         RET
????:
d03f  2a 2b f7   LHLD f72b
d042  eb         XCHG
d043  2a 2d f7   LHLD f72d
d046  cd ea cc   CALL ccea
d049  ca ee cf   JZ cfee
d04c  3a 25 f7   LDA f725
d04f  b7         ORA A
d050  c2 59 d0   JNZ d059
d053  cd b1 ce   CALL ceb1
d056  c3 cd cf   JMP cfcd
????:
d059  cd 1f ce   CALL ce1f
d05c  c3 cd cf   JMP cfcd
d05f  cd aa cb   CALL cbaa
????:
d062  11 22 f7   LXI DE, f722
d065  1a         LDAX DE
d066  3c         INR A
d067  fe 3f      CPI A, 3f
d069  d2 db cc   JNC ccdb
d06c  12         STAX DE
d06d  e5         PUSH HL
d06e  cd cb d0   CALL d0cb
d071  23         INX HL
d072  44         MOV B, H
d073  4d         MOV C, L
d074  d1         POP DE
d075  2b         DCX HL
d076  cd 29 cf   CALL cf29
d079  36 20      MVI M, 20
????:
d07b  cd 18 f8   CALL f818
d07e  0e 2a      MVI C, 2a
d080  cd 09 f8   CALL f809
d083  0e 20      MVI C, 20
d085  cd 09 f8   CALL f809
d088  cd cf cc   CALL cccf
d08b  cd 9e cc   CALL cc9e
d08e  3a 23 f7   LDA f723
d091  47         MOV B, A
d092  0e 18      MVI C, 18
d094  3e 01      MVI A, 01
d096  eb         XCHG
????:
d097  b7         ORA A
d098  c8         RZ
d099  05         DCR B
d09a  f8         RM
d09b  04         INR B
d09c  c5         PUSH BC
????:
d09d  cd 09 f8   CALL f809
d0a0  05         DCR B
d0a1  c2 9d d0   JNZ d09d
d0a4  c1         POP BC
d0a5  3d         DCR A
d0a6  c8         RZ
d0a7  c3 97 d0   JMP d097
d0aa  cd aa cb   CALL cbaa
d0ad  7e         MOV A, M
d0ae  b7         ORA A
d0af  ca db cc   JZ ccdb
d0b2  eb         XCHG
d0b3  21 22 f7   LXI HL, f722
d0b6  35         DCR M
d0b7  eb         XCHG
d0b8  e5         PUSH HL
d0b9  e5         PUSH HL
d0ba  e5         PUSH HL
d0bb  cd cb d0   CALL d0cb
d0be  eb         XCHG
d0bf  c1         POP BC
d0c0  e1         POP HL
d0c1  23         INX HL
d0c2  cd 0d cf   CALL cf0d
d0c5  d1         POP DE
d0c6  62         MOV H, D
d0c7  6b         MOV L, E
d0c8  c3 7b d0   JMP d07b
????:
d0cb  7e         MOV A, M
d0cc  b7         ORA A
d0cd  c8         RZ
d0ce  23         INX HL
d0cf  c3 cb d0   JMP d0cb
d0d2  cd c7 ce   CALL cec7
d0d5  cd 9e cc   CALL cc9e
d0d8  cd 34 cf   CALL cf34
d0db  cd 5c cd   CALL cd5c
????:
d0de  af         XRA A
d0df  32 21 f7   STA f721
d0e2  cd 20 cc   CALL cc20
d0e5  da 0e d0   JC d00e
d0e8  cd ce ce   CALL cece
d0eb  3a 22 f7   LDA f722
d0ee  5f         MOV E, A
d0ef  16 00      MVI D, 00
d0f1  2a 2b f7   LHLD f72b
d0f4  19         DAD DE
d0f5  22 2b f7   SHLD f72b
d0f8  c3 de d0   JMP d0de
d0fb  cd ce ce   CALL cece
????:
d0fe  2a 27 f7   LHLD f727
d101  2b         DCX HL
d102  cd 84 cf   CALL cf84
d105  3a 22 f7   LDA f722
d108  4f         MOV C, A
d109  06 00      MVI B, 00
d10b  eb         XCHG
d10c  09         DAD BC
d10d  23         INX HL
d10e  22 2b f7   SHLD f72b
d111  0e 1a      MVI C, 1a
d113  cd 09 f8   CALL f809
d116  c3 de d0   JMP d0de
d119  cd ce ce   CALL cece
d11c  21 17 d3   LXI HL, d317
d11f  cd 18 f8   CALL f818
d122  cd b4 cb   CALL cbb4
d125  d6 59      SUI A, 59
d127  c2 0c cb   JNZ cb0c
d12a  21 00 30   LXI HL, 3000
d12d  36 0d      MVI M, 0d
d12f  23         INX HL
d130  22 27 f7   SHLD f727
d133  36 ff      MVI M, ff
d135  c3 fe d0   JMP d0fe
d138  cd bf d1   CALL d1bf
d13b  13         INX DE
d13c  42         MOV B, D
d13d  4b         MOV C, E
d13e  2a 27 f7   LHLD f727
d141  eb         XCHG
d142  21 00 d0   LXI HL, d000
d145  19         DAD DE
d146  d5         PUSH DE
d147  e5         PUSH HL
d148  21 00 30   LXI HL, 3000
d14b  c5         PUSH BC
d14c  13         INX DE
d14d  cd da d1   CALL d1da
d150  16 04      MVI D, 04
d152  af         XRA A
????:
d153  1e 55      MVI E, 55
d155  ab         XRA E
????:
d156  cd 0c f8   CALL f80c
d159  1d         DCR E
d15a  c2 56 d1   JNZ d156
d15d  15         DCR D
d15e  c2 53 d1   JNZ d153
d161  21 e0 f6   LXI HL, f6e0
d164  d1         POP DE
d165  c5         PUSH BC
d166  3e e6      MVI A, e6
d168  06 04      MVI B, 04
????:
d16a  cd 0c f8   CALL f80c
d16d  05         DCR B
d16e  c2 6a d1   JNZ d16a
????:
d171  cd 0c f8   CALL f80c
d174  cd ea cc   CALL ccea
d177  7e         MOV A, M
d178  23         INX HL
d179  c2 71 d1   JNZ d171
d17c  c1         POP BC
d17d  e1         POP HL
d17e  7d         MOV A, L
d17f  cd 0c f8   CALL f80c
d182  7c         MOV A, H
d183  cd 0c f8   CALL f80c
d186  d1         POP DE
d187  af         XRA A
d188  6f         MOV L, A
????:
d189  cd 0c f8   CALL f80c
d18c  2d         DCR L
d18d  c2 89 d1   JNZ d189
d190  21 00 30   LXI HL, 3000
d193  3e e6      MVI A, e6
d195  cd 0c f8   CALL f80c
d198  7c         MOV A, H
d199  cd 0c f8   CALL f80c
d19c  7d         MOV A, L
d19d  cd 0c f8   CALL f80c
d1a0  7a         MOV A, D
d1a1  cd 0c f8   CALL f80c
d1a4  7b         MOV A, E
d1a5  cd 0c f8   CALL f80c
d1a8  13         INX DE
????:
d1a9  7e         MOV A, M
d1aa  23         INX HL
d1ab  cd 0c f8   CALL f80c
d1ae  cd ea cc   CALL ccea
d1b1  c2 a9 d1   JNZ d1a9
d1b4  79         MOV A, C
d1b5  cd 0c f8   CALL f80c
d1b8  78         MOV A, B
d1b9  cd 0c f8   CALL f80c
d1bc  c3 0c cb   JMP cb0c
????:
d1bf  c5         PUSH BC
d1c0  cd fd cb   CALL cbfd
d1c3  21 1d d3   LXI HL, d31d
d1c6  cd 18 f8   CALL f818
d1c9  3e 3f      MVI A, 3f
d1cb  cd 0a cc   CALL cc0a
d1ce  c1         POP BC
d1cf  78         MOV A, B
d1d0  32 20 f7   STA f720
d1d3  cd 20 cc   CALL cc20
d1d6  da 0c cb   JC cb0c
d1d9  c9         RET
????:
d1da  e5         PUSH HL
d1db  01 00 00   LXI BC, 0000
????:
d1de  7e         MOV A, M
d1df  81         ADD C
d1e0  4f         MOV C, A
d1e1  78         MOV A, B
d1e2  ce 00      ACI A, 00
d1e4  47         MOV B, A
d1e5  23         INX HL
d1e6  cd ea cc   CALL ccea
d1e9  c2 de d1   JNZ d1de
d1ec  e1         POP HL
d1ed  c9         RET
d1ee  06 00      MVI B, 00
????:
d1f0  cd bf d1   CALL d1bf
d1f3  eb         XCHG
????:
d1f4  06 04      MVI B, 04
d1f6  3e ff      MVI A, ff
????:
d1f8  cd 06 f8   CALL f806
d1fb  fe e6      CPI A, e6
d1fd  c2 f4 d1   JNZ d1f4
d200  05         DCR B
d201  3e 08      MVI A, 08
d203  c2 f8 d1   JNZ d1f8
d206  21 a0 f6   LXI HL, f6a0
????:
d209  cd df d2   CALL d2df
d20c  77         MOV M, A
d20d  b7         ORA A
d20e  23         INX HL
d20f  c2 09 d2   JNZ d209
d212  cd df d2   CALL d2df
d215  4f         MOV C, A
d216  cd df d2   CALL d2df
d219  47         MOV B, A
d21a  c5         PUSH BC
d21b  21 1d d3   LXI HL, d31d
d21e  cd 18 f8   CALL f818
d221  3e 3a      MVI A, 3a
d223  cd 0a cc   CALL cc0a
d226  21 a0 f6   LXI HL, f6a0
d229  e5         PUSH HL
d22a  cd 18 f8   CALL f818
d22d  e1         POP HL
????:
d22e  1a         LDAX DE
d22f  b7         ORA A
d230  ca 3d d2   JZ d23d
d233  be         CMP M
d234  23         INX HL
d235  13         INX DE
d236  ca 2e d2   JZ d22e
d239  c1         POP BC
d23a  c3 f4 d1   JMP d1f4
????:
d23d  c1         POP BC
d23e  78         MOV A, B
d23f  b1         ORA C
d240  f5         PUSH PSW
d241  c5         PUSH BC
d242  3a 20 f7   LDA f720
d245  3d         DCR A
d246  fa 5d d2   JM d25d
d249  2a 27 f7   LHLD f727
d24c  d1         POP DE
d24d  e5         PUSH HL
d24e  19         DAD DE
d24f  cd aa cf   CALL cfaa
d252  eb         XCHG
d253  e1         POP HL
d254  f1         POP PSW
d255  ca d6 d2   JZ d2d6
d258  af         XRA A
d259  f5         PUSH PSW
d25a  c3 86 d2   JMP d286
????:
d25d  3c         INR A
d25e  21 00 30   LXI HL, 3000
d261  eb         XCHG
d262  e1         POP HL
d263  19         DAD DE
d264  f5         PUSH PSW
d265  d5         PUSH DE
d266  cd aa cf   CALL cfaa
d269  d1         POP DE
d26a  eb         XCHG
d26b  c1         POP BC
d26c  f1         POP PSW
d26d  c5         PUSH BC
d26e  c2 86 d2   JNZ d286
d271  3e ff      MVI A, ff
d273  cd 06 f8   CALL f806
d276  67         MOV H, A
d277  cd df d2   CALL d2df
d27a  6f         MOV L, A
d27b  cd df d2   CALL d2df
d27e  57         MOV D, A
d27f  cd df d2   CALL d2df
d282  5f         MOV E, A
d283  c3 94 d2   JMP d294
????:
d286  3e ff      MVI A, ff
d288  cd 06 f8   CALL f806
d28b  cd df d2   CALL d2df
d28e  cd df d2   CALL d2df
d291  cd df d2   CALL d2df
????:
d294  13         INX DE
d295  f1         POP PSW
d296  e5         PUSH HL
d297  c2 c5 d2   JNZ d2c5
????:
d29a  cd df d2   CALL d2df
d29d  77         MOV M, A
d29e  23         INX HL
d29f  cd ea cc   CALL ccea
d2a2  c2 9a d2   JNZ d29a
????:
d2a5  cd df d2   CALL d2df
d2a8  4f         MOV C, A
d2a9  cd df d2   CALL d2df
d2ac  47         MOV B, A
d2ad  e1         POP HL
d2ae  c5         PUSH BC
d2af  cd da d1   CALL d1da
d2b2  e1         POP HL
d2b3  7c         MOV A, H
d2b4  b8         CMP B
d2b5  c2 d6 d2   JNZ d2d6
d2b8  7d         MOV A, L
d2b9  b9         CMP C
d2ba  c2 d6 d2   JNZ d2d6
d2bd  1b         DCX DE
d2be  eb         XCHG
d2bf  22 27 f7   SHLD f727
d2c2  c3 0c cb   JMP cb0c
????:
d2c5  cd df d2   CALL d2df
d2c8  be         CMP M
d2c9  23         INX HL
d2ca  c2 d6 d2   JNZ d2d6
d2cd  cd ea cc   CALL ccea
d2d0  c2 c5 d2   JNZ d2c5
d2d3  c3 a5 d2   JMP d2a5
????:
d2d6  11 0c d3   LXI DE, d30c
d2d9  cd 12 ce   CALL ce12
d2dc  c3 f7 cb   JMP cbf7
????:
d2df  3e 08      MVI A, 08
d2e1  c3 06 f8   JMP f806
d2e4  06 ff      MVI B, ff
d2e6  c3 f0 d1   JMP d1f0
d2e9  06 01      MVI B, 01
d2eb  c3 f0 d1   JMP d1f0
????:
d2ee  0a         LDAX BC
d2ef  45         MOV B, L
d2f0  52         MOV D, D
d2f1  52         MOV D, D
d2f2  4f         MOV C, A
d2f3  52         MOV D, D
d2f4  3a 00 4c   LDA 4c00
d2f7  4f         MOV C, A
d2f8  4e         MOV C, M
d2f9  47         MOV B, A
d2fa  20         db 20
d2fb  53         MOV D, E
d2fc  54         MOV D, H
d2fd  52         MOV D, D
d2fe  49         MOV C, C
d2ff  4e         MOV C, M
d300  47         MOV B, A
d301  00         NOP
????:
d302  4c         MOV C, H
d303  4f         MOV C, A
d304  4e         MOV C, M
d305  47         MOV B, A
d306  20         db 20
d307  46         MOV B, M
d308  49         MOV C, C
d309  4c         MOV C, H
d30a  45         MOV B, L
d30b  00         NOP
????:
d30c  49         MOV C, C
d30d  2f         CMA
d30e  4f         MOV C, A
d30f  20         db 20
d310  44         MOV B, H
d311  45         MOV B, L
d312  56         MOV D, M
d313  49         MOV C, C
d314  43         MOV B, E
d315  45         MOV B, L
d316  00         NOP
????:
d317  1f         RAR
d318  4e         MOV C, M
d319  45         MOV B, L
d31a  57         MOV D, A
d31b  3f         CMC
d31c  00         NOP
????:
d31d  0a         LDAX BC
d31e  46         MOV B, M
d31f  49         MOV C, C
d320  4c         MOV C, H
d321  45         MOV B, L
d322  00         NOP
????:
d323  0a         LDAX BC
d324  45         MOV B, L
d325  44         MOV B, H
d326  49         MOV C, C
d327  54         MOV D, H
d328  20         db 20
d329  2a 6d 69   LHLD 696d
d32c  6b         MOV L, E
d32d  72         MOV M, D
d32e  6f         MOV L, A
d32f  6e         MOV L, M
d330  2a 0a 2a   LHLD 2a0a
d333  00         NOP
????:
d334  0a         LDAX BC
d335  45         MOV B, L
d336  4e         MOV C, M
d337  44         MOV B, H
d338  3d         DCR A
d339  00         NOP
d33a  20         db 20
d33b  20         db 20
d33c  55         MOV D, L
d33d  53         MOV D, E
d33e  45         MOV B, L
d33f  44         MOV B, H
d340  3d         DCR A
d341  00         NOP
d342  20         db 20
d343  20         db 20
d344  46         MOV B, M
d345  52         MOV D, D
d346  45         MOV B, L
d347  45         MOV B, L
d348  3d         DCR A
d349  00         NOP
????:
d34a  4c         MOV C, H
d34b  c6 cb      ADI A, cb
d34d  58         MOV E, B
d34e  be         CMP M
d34f  cb         db cb
d350  44         MOV B, H
d351  bb         CMP E
d352  cf         RST 1
d353  41         MOV B, C
d354  d2 d0 54   JNC 54d0
d357  fb         EI
d358  d0         RNC
d359  4e         MOV C, M
d35a  19         DAD DE
d35b  d1         POP DE
d35c  4f         MOV C, A
d35d  38         db 38
d35e  d1         POP DE
d35f  49         MOV C, C
d360  ee d1      XRI A, d1
d362  56         MOV D, M
d363  e4 d2 4d   CPO 4dd2
d366  e9         PCHL
d367  d2 57 88   JNC 8857
d36a  cd 52 a7   CALL a752
d36d  cd 46 bf   CALL bf46
d370  cd 59 9d   CALL 9d59
d373  cd 08 aa   CALL aa08
d376  d0         RNC
d377  18         db 18
d378  5f         MOV E, A
d379  d0         RNC
d37a  19         DAD DE
d37b  91         SUB C
d37c  ce 1a      ACI A, 1a
d37e  6b         MOV L, E
d37f  cf         RST 1
d380  00         NOP
d381  00         NOP
d382  00         NOP
d383  00         NOP
d384  00         NOP
d385  00         NOP
d386  00         NOP
d387  00         NOP
d388  00         NOP
d389  00         NOP
d38a  00         NOP
d38b  00         NOP
d38c  00         NOP
d38d  00         NOP
d38e  00         NOP
d38f  00         NOP
d390  00         NOP
d391  00         NOP
d392  00         NOP
d393  00         NOP
d394  00         NOP
d395  00         NOP
d396  00         NOP
d397  00         NOP
d398  00         NOP
d399  00         NOP
d39a  00         NOP
d39b  00         NOP
d39c  00         NOP
d39d  00         NOP
d39e  00         NOP
d39f  00         NOP
d3a0  00         NOP
d3a1  00         NOP
d3a2  00         NOP
d3a3  00         NOP
d3a4  00         NOP
d3a5  00         NOP
d3a6  00         NOP
d3a7  00         NOP
d3a8  00         NOP
d3a9  00         NOP
d3aa  00         NOP
d3ab  00         NOP
d3ac  00         NOP
d3ad  00         NOP
d3ae  00         NOP
d3af  00         NOP
d3b0  00         NOP
d3b1  00         NOP
d3b2  00         NOP
d3b3  00         NOP
d3b4  00         NOP
d3b5  00         NOP
d3b6  00         NOP
d3b7  00         NOP
d3b8  00         NOP
d3b9  00         NOP
d3ba  00         NOP
d3bb  00         NOP
d3bc  00         NOP
d3bd  00         NOP
d3be  00         NOP
d3bf  00         NOP
d3c0  00         NOP
d3c1  00         NOP
d3c2  00         NOP
d3c3  00         NOP
d3c4  00         NOP
d3c5  00         NOP
d3c6  00         NOP
d3c7  00         NOP
d3c8  00         NOP
d3c9  00         NOP
d3ca  00         NOP
d3cb  00         NOP
d3cc  00         NOP
d3cd  00         NOP
d3ce  00         NOP
d3cf  00         NOP
d3d0  00         NOP
d3d1  00         NOP
d3d2  00         NOP
d3d3  00         NOP
d3d4  00         NOP
d3d5  00         NOP
d3d6  00         NOP
d3d7  00         NOP
d3d8  00         NOP
d3d9  00         NOP
d3da  00         NOP
d3db  00         NOP
d3dc  00         NOP
d3dd  00         NOP
d3de  00         NOP
d3df  00         NOP
d3e0  00         NOP
d3e1  00         NOP
d3e2  00         NOP
d3e3  00         NOP
d3e4  00         NOP
d3e5  00         NOP
d3e6  00         NOP
d3e7  00         NOP
d3e8  00         NOP
d3e9  00         NOP
d3ea  00         NOP
d3eb  00         NOP
d3ec  00         NOP
d3ed  00         NOP
d3ee  00         NOP
d3ef  00         NOP
d3f0  00         NOP
d3f1  00         NOP
d3f2  00         NOP
d3f3  00         NOP
d3f4  00         NOP
d3f5  00         NOP
d3f6  00         NOP
d3f7  00         NOP
d3f8  00         NOP
d3f9  00         NOP
d3fa  00         NOP
d3fb  00         NOP
d3fc  00         NOP
d3fd  00         NOP
d3fe  00         NOP
d3ff  00         NOP
d400  00         NOP
d401  00         NOP
d402  00         NOP
d403  00         NOP
d404  00         NOP
d405  00         NOP
d406  00         NOP
d407  00         NOP
d408  00         NOP
d409  00         NOP
d40a  00         NOP
d40b  00         NOP
d40c  00         NOP
d40d  00         NOP
d40e  00         NOP
d40f  00         NOP
d410  00         NOP
d411  00         NOP
d412  00         NOP
d413  00         NOP
d414  00         NOP
d415  00         NOP
d416  00         NOP
d417  00         NOP
d418  00         NOP
d419  00         NOP
d41a  00         NOP
d41b  00         NOP
d41c  00         NOP
d41d  00         NOP
d41e  00         NOP
d41f  00         NOP
d420  00         NOP
d421  00         NOP
d422  00         NOP
d423  00         NOP
d424  00         NOP
d425  00         NOP
d426  00         NOP
d427  00         NOP
d428  00         NOP
d429  00         NOP
d42a  00         NOP
d42b  00         NOP
d42c  00         NOP
d42d  00         NOP
d42e  00         NOP
d42f  00         NOP
d430  00         NOP
d431  00         NOP
d432  00         NOP
d433  00         NOP
d434  00         NOP
d435  00         NOP
d436  00         NOP
d437  00         NOP
d438  00         NOP
d439  00         NOP
d43a  00         NOP
d43b  00         NOP
d43c  00         NOP
d43d  00         NOP
d43e  00         NOP
d43f  00         NOP
d440  00         NOP
d441  00         NOP
d442  00         NOP
d443  00         NOP
d444  00         NOP
d445  00         NOP
d446  00         NOP
d447  00         NOP
d448  00         NOP
d449  00         NOP
d44a  00         NOP
d44b  00         NOP
d44c  00         NOP
d44d  00         NOP
d44e  00         NOP
d44f  00         NOP
d450  00         NOP
d451  00         NOP
d452  00         NOP
d453  00         NOP
d454  00         NOP
d455  00         NOP
d456  00         NOP
d457  00         NOP
d458  00         NOP
d459  00         NOP
d45a  00         NOP
d45b  00         NOP
d45c  00         NOP
d45d  00         NOP
d45e  00         NOP
d45f  00         NOP
d460  00         NOP
d461  00         NOP
d462  00         NOP
d463  00         NOP
d464  00         NOP
d465  00         NOP
d466  00         NOP
d467  00         NOP
d468  00         NOP
d469  00         NOP
d46a  00         NOP
d46b  00         NOP
d46c  00         NOP
d46d  00         NOP
d46e  00         NOP
d46f  00         NOP
d470  00         NOP
d471  00         NOP
d472  00         NOP
d473  00         NOP
d474  00         NOP
d475  00         NOP
d476  00         NOP
d477  00         NOP
d478  00         NOP
d479  00         NOP
d47a  00         NOP
d47b  00         NOP
d47c  00         NOP
d47d  00         NOP
d47e  00         NOP
d47f  00         NOP
d480  00         NOP
d481  00         NOP
d482  00         NOP
d483  00         NOP
d484  00         NOP
d485  00         NOP
d486  00         NOP
d487  00         NOP
d488  00         NOP
d489  00         NOP
d48a  00         NOP
d48b  00         NOP
d48c  00         NOP
d48d  00         NOP
d48e  00         NOP
d48f  00         NOP
d490  00         NOP
d491  00         NOP
d492  00         NOP
d493  00         NOP
d494  00         NOP
d495  00         NOP
d496  00         NOP
d497  00         NOP
d498  00         NOP
d499  00         NOP
d49a  00         NOP
d49b  00         NOP
d49c  00         NOP
d49d  00         NOP
d49e  00         NOP
d49f  00         NOP
d4a0  00         NOP
d4a1  00         NOP
d4a2  00         NOP
d4a3  00         NOP
d4a4  00         NOP
d4a5  00         NOP
d4a6  00         NOP
d4a7  00         NOP
d4a8  00         NOP
d4a9  00         NOP
d4aa  00         NOP
d4ab  00         NOP
d4ac  00         NOP
d4ad  00         NOP
d4ae  00         NOP
d4af  00         NOP
d4b0  00         NOP
d4b1  00         NOP
d4b2  00         NOP
d4b3  00         NOP
d4b4  00         NOP
d4b5  00         NOP
d4b6  00         NOP
d4b7  00         NOP
d4b8  00         NOP
d4b9  00         NOP
d4ba  00         NOP
d4bb  00         NOP
d4bc  00         NOP
d4bd  00         NOP
d4be  00         NOP
d4bf  00         NOP
d4c0  00         NOP
d4c1  00         NOP
d4c2  00         NOP
d4c3  00         NOP
d4c4  00         NOP
d4c5  00         NOP
d4c6  00         NOP
d4c7  00         NOP
d4c8  00         NOP
d4c9  00         NOP
d4ca  00         NOP
d4cb  00         NOP
d4cc  00         NOP
d4cd  00         NOP
d4ce  00         NOP
d4cf  00         NOP
d4d0  00         NOP
d4d1  00         NOP
d4d2  00         NOP
d4d3  00         NOP
d4d4  00         NOP
d4d5  00         NOP
d4d6  00         NOP
d4d7  00         NOP
d4d8  00         NOP
d4d9  00         NOP
d4da  00         NOP
d4db  00         NOP
d4dc  00         NOP
d4dd  00         NOP
d4de  00         NOP
d4df  00         NOP
d4e0  00         NOP
d4e1  00         NOP
d4e2  00         NOP
d4e3  00         NOP
d4e4  00         NOP
d4e5  00         NOP
d4e6  00         NOP
d4e7  00         NOP
d4e8  00         NOP
d4e9  00         NOP
d4ea  00         NOP
d4eb  00         NOP
d4ec  00         NOP
d4ed  00         NOP
d4ee  00         NOP
d4ef  00         NOP
d4f0  00         NOP
d4f1  00         NOP
d4f2  00         NOP
d4f3  00         NOP
d4f4  00         NOP
d4f5  00         NOP
d4f6  00         NOP
d4f7  00         NOP
d4f8  00         NOP
d4f9  00         NOP
d4fa  00         NOP
d4fb  00         NOP
d4fc  00         NOP
d4fd  00         NOP
d4fe  00         NOP
d4ff  00         NOP
d500  00         NOP
d501  00         NOP
d502  00         NOP
d503  00         NOP
d504  00         NOP
d505  00         NOP
d506  00         NOP
d507  00         NOP
d508  00         NOP
d509  00         NOP
d50a  00         NOP
d50b  00         NOP
d50c  00         NOP
d50d  00         NOP
d50e  00         NOP
d50f  00         NOP
d510  00         NOP
d511  00         NOP
d512  00         NOP
d513  00         NOP
d514  00         NOP
d515  00         NOP
d516  00         NOP
d517  00         NOP
d518  00         NOP
d519  00         NOP
d51a  00         NOP
d51b  00         NOP
d51c  00         NOP
d51d  00         NOP
d51e  00         NOP
d51f  00         NOP
d520  00         NOP
d521  00         NOP
d522  00         NOP
d523  00         NOP
d524  00         NOP
d525  00         NOP
d526  00         NOP
d527  00         NOP
d528  00         NOP
d529  00         NOP
d52a  00         NOP
d52b  00         NOP
d52c  00         NOP
d52d  00         NOP
d52e  00         NOP
d52f  00         NOP
d530  00         NOP
d531  00         NOP
d532  00         NOP
d533  00         NOP
d534  00         NOP
d535  00         NOP
d536  00         NOP
d537  00         NOP
d538  00         NOP
d539  00         NOP
d53a  00         NOP
d53b  00         NOP
d53c  00         NOP
d53d  00         NOP
d53e  00         NOP
d53f  00         NOP
d540  00         NOP
d541  00         NOP
d542  00         NOP
d543  00         NOP
d544  00         NOP
d545  00         NOP
d546  00         NOP
d547  00         NOP
d548  00         NOP
d549  00         NOP
d54a  00         NOP
d54b  00         NOP
d54c  00         NOP
d54d  00         NOP
d54e  00         NOP
d54f  00         NOP
d550  00         NOP
d551  00         NOP
d552  00         NOP
d553  00         NOP
d554  00         NOP
d555  00         NOP
d556  00         NOP
d557  00         NOP
d558  00         NOP
d559  00         NOP
d55a  00         NOP
d55b  00         NOP
d55c  00         NOP
d55d  00         NOP
d55e  00         NOP
d55f  00         NOP
d560  00         NOP
d561  00         NOP
d562  00         NOP
d563  00         NOP
d564  00         NOP
d565  00         NOP
d566  00         NOP
d567  00         NOP
d568  00         NOP
d569  00         NOP
d56a  00         NOP
d56b  00         NOP
d56c  00         NOP
d56d  00         NOP
d56e  00         NOP
d56f  00         NOP
d570  00         NOP
d571  00         NOP
d572  00         NOP
d573  00         NOP
d574  00         NOP
d575  00         NOP
d576  00         NOP
d577  00         NOP
d578  00         NOP
d579  00         NOP
d57a  00         NOP
d57b  00         NOP
d57c  00         NOP
d57d  00         NOP
d57e  00         NOP
d57f  00         NOP
d580  00         NOP
d581  00         NOP
d582  00         NOP
d583  00         NOP
d584  00         NOP
d585  00         NOP
d586  00         NOP
d587  00         NOP
d588  00         NOP
d589  00         NOP
d58a  00         NOP
d58b  00         NOP
d58c  00         NOP
d58d  00         NOP
d58e  00         NOP
d58f  00         NOP
d590  00         NOP
d591  00         NOP
d592  00         NOP
d593  00         NOP
d594  00         NOP
d595  00         NOP
d596  00         NOP
d597  00         NOP
d598  00         NOP
d599  00         NOP
d59a  00         NOP
d59b  00         NOP
d59c  00         NOP
d59d  00         NOP
d59e  00         NOP
d59f  00         NOP
d5a0  00         NOP
d5a1  00         NOP
d5a2  00         NOP
d5a3  00         NOP
d5a4  00         NOP
d5a5  00         NOP
d5a6  00         NOP
d5a7  00         NOP
d5a8  00         NOP
d5a9  00         NOP
d5aa  00         NOP
d5ab  00         NOP
d5ac  00         NOP
d5ad  00         NOP
d5ae  00         NOP
d5af  00         NOP
d5b0  00         NOP
d5b1  00         NOP
d5b2  00         NOP
d5b3  00         NOP
d5b4  00         NOP
d5b5  00         NOP
d5b6  00         NOP
d5b7  00         NOP
d5b8  00         NOP
d5b9  00         NOP
d5ba  00         NOP
d5bb  00         NOP
d5bc  00         NOP
d5bd  00         NOP
d5be  00         NOP
d5bf  00         NOP
d5c0  00         NOP
d5c1  00         NOP
d5c2  00         NOP
d5c3  00         NOP
d5c4  00         NOP
d5c5  00         NOP
d5c6  00         NOP
d5c7  00         NOP
d5c8  00         NOP
d5c9  00         NOP
d5ca  00         NOP
d5cb  00         NOP
d5cc  00         NOP
d5cd  00         NOP
d5ce  00         NOP
d5cf  00         NOP
d5d0  00         NOP
d5d1  00         NOP
d5d2  00         NOP
d5d3  00         NOP
d5d4  00         NOP
d5d5  00         NOP
d5d6  00         NOP
d5d7  00         NOP
d5d8  00         NOP
d5d9  00         NOP
d5da  00         NOP
d5db  00         NOP
d5dc  00         NOP
d5dd  00         NOP
d5de  00         NOP
d5df  00         NOP
d5e0  00         NOP
d5e1  00         NOP
d5e2  00         NOP
d5e3  00         NOP
d5e4  00         NOP
d5e5  00         NOP
d5e6  00         NOP
d5e7  00         NOP
d5e8  00         NOP
d5e9  00         NOP
d5ea  00         NOP
d5eb  00         NOP
d5ec  00         NOP
d5ed  00         NOP
d5ee  00         NOP
d5ef  00         NOP
d5f0  00         NOP
d5f1  00         NOP
d5f2  00         NOP
d5f3  00         NOP
d5f4  00         NOP
d5f5  00         NOP
d5f6  00         NOP
d5f7  00         NOP
d5f8  00         NOP
d5f9  00         NOP
d5fa  00         NOP
d5fb  00         NOP
d5fc  00         NOP
d5fd  00         NOP
d5fe  00         NOP
d5ff  00         NOP
d600  00         NOP
d601  00         NOP
d602  00         NOP
d603  00         NOP
d604  00         NOP
d605  00         NOP
d606  00         NOP
d607  00         NOP
d608  00         NOP
d609  00         NOP
d60a  00         NOP
d60b  00         NOP
d60c  00         NOP
d60d  00         NOP
d60e  00         NOP
d60f  00         NOP
d610  00         NOP
d611  00         NOP
d612  00         NOP
d613  00         NOP
d614  00         NOP
d615  00         NOP
d616  00         NOP
d617  00         NOP
d618  00         NOP
d619  00         NOP
d61a  00         NOP
d61b  00         NOP
d61c  00         NOP
d61d  00         NOP
d61e  00         NOP
d61f  00         NOP
d620  00         NOP
d621  00         NOP
d622  00         NOP
d623  00         NOP
d624  00         NOP
d625  00         NOP
d626  00         NOP
d627  00         NOP
d628  00         NOP
d629  00         NOP
d62a  00         NOP
d62b  00         NOP
d62c  00         NOP
d62d  00         NOP
d62e  00         NOP
d62f  00         NOP
d630  00         NOP
d631  00         NOP
d632  00         NOP
d633  00         NOP
d634  00         NOP
d635  00         NOP
d636  00         NOP
d637  00         NOP
d638  00         NOP
d639  00         NOP
d63a  00         NOP
d63b  00         NOP
d63c  00         NOP
d63d  00         NOP
d63e  00         NOP
d63f  00         NOP
d640  00         NOP
d641  00         NOP
d642  00         NOP
d643  00         NOP
d644  00         NOP
d645  00         NOP
d646  00         NOP
d647  00         NOP
d648  00         NOP
d649  00         NOP
d64a  00         NOP
d64b  00         NOP
d64c  00         NOP
d64d  00         NOP
d64e  00         NOP
d64f  00         NOP
d650  00         NOP
d651  00         NOP
d652  00         NOP
d653  00         NOP
d654  00         NOP
d655  00         NOP
d656  00         NOP
d657  00         NOP
d658  00         NOP
d659  00         NOP
d65a  00         NOP
d65b  00         NOP
d65c  00         NOP
d65d  00         NOP
d65e  00         NOP
d65f  00         NOP
d660  00         NOP
d661  00         NOP
d662  00         NOP
d663  00         NOP
d664  00         NOP
d665  00         NOP
d666  00         NOP
d667  00         NOP
d668  00         NOP
d669  00         NOP
d66a  00         NOP
d66b  00         NOP
d66c  00         NOP
d66d  00         NOP
d66e  00         NOP
d66f  00         NOP
d670  00         NOP
d671  00         NOP
d672  00         NOP
d673  00         NOP
d674  00         NOP
d675  00         NOP
d676  00         NOP
d677  00         NOP
d678  00         NOP
d679  00         NOP
d67a  00         NOP
d67b  00         NOP
d67c  00         NOP
d67d  00         NOP
d67e  00         NOP
d67f  00         NOP
d680  00         NOP
d681  00         NOP
d682  00         NOP
d683  00         NOP
d684  00         NOP
d685  00         NOP
d686  00         NOP
d687  00         NOP
d688  00         NOP
d689  00         NOP
d68a  00         NOP
d68b  00         NOP
d68c  00         NOP
d68d  00         NOP
d68e  00         NOP
d68f  00         NOP
d690  00         NOP
d691  00         NOP
d692  00         NOP
d693  00         NOP
d694  00         NOP
d695  00         NOP
d696  00         NOP
d697  00         NOP
d698  00         NOP
d699  00         NOP
d69a  00         NOP
d69b  00         NOP
d69c  00         NOP
d69d  00         NOP
d69e  00         NOP
d69f  00         NOP
d6a0  00         NOP
d6a1  00         NOP
d6a2  00         NOP
d6a3  00         NOP
d6a4  00         NOP
d6a5  00         NOP
d6a6  00         NOP
d6a7  00         NOP
d6a8  00         NOP
d6a9  00         NOP
d6aa  00         NOP
d6ab  00         NOP
d6ac  00         NOP
d6ad  00         NOP
d6ae  00         NOP
d6af  00         NOP
d6b0  00         NOP
d6b1  00         NOP
d6b2  00         NOP
d6b3  00         NOP
d6b4  00         NOP
d6b5  00         NOP
d6b6  00         NOP
d6b7  00         NOP
d6b8  00         NOP
d6b9  00         NOP
d6ba  00         NOP
d6bb  00         NOP
d6bc  00         NOP
d6bd  00         NOP
d6be  00         NOP
d6bf  00         NOP
d6c0  00         NOP
d6c1  00         NOP
d6c2  00         NOP
d6c3  00         NOP
d6c4  00         NOP
d6c5  00         NOP
d6c6  00         NOP
d6c7  00         NOP
d6c8  00         NOP
d6c9  00         NOP
d6ca  00         NOP
d6cb  00         NOP
d6cc  00         NOP
d6cd  00         NOP
d6ce  00         NOP
d6cf  00         NOP
d6d0  00         NOP
d6d1  00         NOP
d6d2  00         NOP
d6d3  00         NOP
d6d4  00         NOP
d6d5  00         NOP
d6d6  00         NOP
d6d7  00         NOP
d6d8  00         NOP
d6d9  00         NOP
d6da  00         NOP
d6db  00         NOP
d6dc  00         NOP
d6dd  00         NOP
d6de  00         NOP
d6df  00         NOP
d6e0  00         NOP
d6e1  00         NOP
d6e2  00         NOP
d6e3  00         NOP
d6e4  00         NOP
d6e5  00         NOP
d6e6  00         NOP
d6e7  00         NOP
d6e8  00         NOP
d6e9  00         NOP
d6ea  00         NOP
d6eb  00         NOP
d6ec  00         NOP
d6ed  00         NOP
d6ee  00         NOP
d6ef  00         NOP
d6f0  00         NOP
d6f1  00         NOP
d6f2  00         NOP
d6f3  00         NOP
d6f4  00         NOP
d6f5  00         NOP
d6f6  00         NOP
d6f7  00         NOP
d6f8  00         NOP
d6f9  00         NOP
d6fa  00         NOP
d6fb  00         NOP
d6fc  00         NOP
d6fd  00         NOP
d6fe  00         NOP
d6ff  00         NOP
d700  00         NOP
d701  00         NOP
d702  00         NOP
d703  00         NOP
d704  00         NOP
d705  00         NOP
d706  00         NOP
d707  00         NOP
d708  00         NOP
d709  00         NOP
d70a  00         NOP
d70b  00         NOP
d70c  00         NOP
d70d  00         NOP
d70e  00         NOP
d70f  00         NOP
d710  00         NOP
d711  00         NOP
d712  00         NOP
d713  00         NOP
d714  00         NOP
d715  00         NOP
d716  00         NOP
d717  00         NOP
d718  00         NOP
d719  00         NOP
d71a  00         NOP
d71b  00         NOP
d71c  00         NOP
d71d  00         NOP
d71e  00         NOP
d71f  00         NOP
d720  00         NOP
d721  00         NOP
d722  00         NOP
d723  00         NOP
d724  00         NOP
d725  00         NOP
d726  00         NOP
d727  00         NOP
d728  00         NOP
d729  00         NOP
d72a  00         NOP
d72b  00         NOP
d72c  00         NOP
d72d  00         NOP
d72e  00         NOP
d72f  00         NOP
d730  00         NOP
d731  00         NOP
d732  00         NOP
d733  00         NOP
d734  00         NOP
d735  00         NOP
d736  00         NOP
d737  00         NOP
d738  00         NOP
d739  00         NOP
d73a  00         NOP
d73b  00         NOP
d73c  00         NOP
d73d  00         NOP
d73e  00         NOP
d73f  00         NOP
d740  00         NOP
d741  00         NOP
d742  00         NOP
d743  00         NOP
d744  00         NOP
d745  00         NOP
d746  00         NOP
d747  00         NOP
d748  00         NOP
d749  00         NOP
d74a  00         NOP
d74b  00         NOP
d74c  00         NOP
d74d  00         NOP
d74e  00         NOP
d74f  00         NOP
d750  00         NOP
d751  00         NOP
d752  00         NOP
d753  00         NOP
d754  00         NOP
d755  00         NOP
d756  00         NOP
d757  00         NOP
d758  00         NOP
d759  00         NOP
d75a  00         NOP
d75b  00         NOP
d75c  00         NOP
d75d  00         NOP
d75e  00         NOP
d75f  00         NOP
d760  00         NOP
d761  00         NOP
d762  00         NOP
d763  00         NOP
d764  00         NOP
d765  00         NOP
d766  00         NOP
d767  00         NOP
d768  00         NOP
d769  00         NOP
d76a  00         NOP
d76b  00         NOP
d76c  00         NOP
d76d  00         NOP
d76e  00         NOP
d76f  00         NOP
d770  00         NOP
d771  00         NOP
d772  00         NOP
d773  00         NOP
d774  00         NOP
d775  00         NOP
d776  00         NOP
d777  00         NOP
d778  00         NOP
d779  00         NOP
d77a  00         NOP
d77b  00         NOP
d77c  00         NOP
d77d  00         NOP
d77e  00         NOP
d77f  00         NOP
d780  00         NOP
d781  00         NOP
d782  00         NOP
d783  00         NOP
d784  00         NOP
d785  00         NOP
d786  00         NOP
d787  00         NOP
d788  00         NOP
d789  00         NOP
d78a  00         NOP
d78b  00         NOP
d78c  00         NOP
d78d  00         NOP
d78e  00         NOP
d78f  00         NOP
d790  00         NOP
d791  00         NOP
d792  00         NOP
d793  00         NOP
d794  00         NOP
d795  00         NOP
d796  00         NOP
d797  00         NOP
d798  00         NOP
d799  00         NOP
d79a  00         NOP
d79b  00         NOP
d79c  00         NOP
d79d  00         NOP
d79e  00         NOP
d79f  00         NOP
d7a0  00         NOP
d7a1  00         NOP
d7a2  00         NOP
d7a3  00         NOP
d7a4  00         NOP
d7a5  00         NOP
d7a6  00         NOP
d7a7  00         NOP
d7a8  00         NOP
d7a9  00         NOP
d7aa  00         NOP
d7ab  00         NOP
d7ac  00         NOP
d7ad  00         NOP
d7ae  00         NOP
d7af  00         NOP
d7b0  00         NOP
d7b1  00         NOP
d7b2  00         NOP
d7b3  00         NOP
d7b4  00         NOP
d7b5  00         NOP
d7b6  00         NOP
d7b7  00         NOP
d7b8  00         NOP
d7b9  00         NOP
d7ba  00         NOP
d7bb  00         NOP
d7bc  00         NOP
d7bd  00         NOP
d7be  00         NOP
d7bf  00         NOP
d7c0  00         NOP
d7c1  00         NOP
d7c2  00         NOP
d7c3  00         NOP
d7c4  00         NOP
d7c5  00         NOP
d7c6  00         NOP
d7c7  00         NOP
d7c8  00         NOP
d7c9  00         NOP
d7ca  00         NOP
d7cb  00         NOP
d7cc  00         NOP
d7cd  00         NOP
d7ce  00         NOP
d7cf  00         NOP
d7d0  00         NOP
d7d1  00         NOP
d7d2  00         NOP
d7d3  00         NOP
d7d4  00         NOP
d7d5  00         NOP
d7d6  00         NOP
d7d7  00         NOP
d7d8  00         NOP
d7d9  00         NOP
d7da  00         NOP
d7db  00         NOP
d7dc  00         NOP
d7dd  00         NOP
d7de  00         NOP
d7df  00         NOP
d7e0  00         NOP
d7e1  00         NOP
d7e2  00         NOP
d7e3  00         NOP
d7e4  00         NOP
d7e5  00         NOP
d7e6  00         NOP
d7e7  00         NOP
d7e8  00         NOP
d7e9  00         NOP
d7ea  00         NOP
d7eb  00         NOP
d7ec  00         NOP
d7ed  00         NOP
d7ee  00         NOP
d7ef  00         NOP
d7f0  00         NOP
d7f1  00         NOP
d7f2  00         NOP
d7f3  00         NOP
d7f4  00         NOP
d7f5  00         NOP
d7f6  00         NOP
d7f7  00         NOP
d7f8  00         NOP
d7f9  00         NOP
d7fa  00         NOP
d7fb  00         NOP
d7fc  00         NOP
d7fd  00         NOP
d7fe  00         NOP
d7ff  00         NOP
????:
d800  31 80 bf   LXI SP, bf80
d803  21 c5 df   LXI HL, dfc5
d806  cd 18 f8   CALL f818
d809  cd 25 d8   CALL d825
d80c  cd 50 de   CALL de50
d80f  cd d3 dd   CALL ddd3
d812  d6 31      SUI A, 31
d814  fa 1f d0   JM d01f
d817  fe 03      CPI A, 03
d819  32 94 bf   STA bf94
d81c  fa 2f d8   JM d82f
d81f  21 d6 df   LXI HL, dfd6
d822  c3 4d db   JMP db4d
????:
d825  cd 03 f8   CALL f803
d828  4f         MOV C, A
d829  fe 03      CPI A, 03
d82b  ca 65 f8   JZ f865
d82e  c9         RET
????:
d82f  af         XRA A
d830  32 95 bf   STA bf95
d833  3c         INR A
d834  32 83 bf   STA bf83
d837  21 00 00   LXI HL, 0000
d83a  22 98 bf   SHLD bf98
d83d  21 00 30   LXI HL, 3000
????:
d840  7e         MOV A, M
d841  3c         INR A
d842  23         INX HL
d843  ca 4c d8   JZ d84c
d846  cd 40 db   CALL db40
d849  c3 40 d8   JMP d840
????:
d84c  22 80 bf   SHLD bf80
d84f  36 00      MVI M, 00
????:
d851  21 00 30   LXI HL, 3000
d854  22 8f bf   SHLD bf8f
d857  21 00 a0   LXI HL, a000
d85a  22 85 bf   SHLD bf85
d85d  af         XRA A
d85e  32 82 bf   STA bf82
????:
d861  af         XRA A
d862  32 84 bf   STA bf84
d865  2a 85 bf   LHLD bf85
d868  22 87 bf   SHLD bf87
d86b  31 80 bf   LXI SP, bf80
d86e  cd 9a da   CALL da9a
d871  21 a0 bf   LXI HL, bfa0
d874  7e         MOV A, M
d875  fe 3b      CPI A, 3b
d877  ca c4 d0   JZ d0c4
d87a  cd cd da   CALL dacd
d87d  fe 3a      CPI A, 3a
d87f  c2 9b d8   JNZ d89b
d882  af         XRA A
d883  b9         CMP C
d884  ca 92 da   JZ da92
d887  e5         PUSH HL
d888  cd 12 db   CALL db12
d88b  e1         POP HL
d88c  cd 0a db   CALL db0a
d88f  b7         ORA A
d890  ca c4 d8   JZ d8c4
d893  fe 3b      CPI A, 3b
d895  ca c4 d8   JZ d8c4
d898  cd cd da   CALL dacd
????:
d89b  e5         PUSH HL
d89c  cd 0d dd   CALL dd0d
d89f  e1         POP HL
d8a0  cd b2 db   CALL dbb2
d8a3  e5         PUSH HL
d8a4  21 53 de   LXI HL, de53
d8a7  3a 89 bf   LDA bf89
d8aa  5f         MOV E, A
d8ab  16 00      MVI D, 00
d8ad  19         DAD DE
d8ae  19         DAD DE
d8af  5e         MOV E, M
d8b0  23         INX HL
d8b1  7e         MOV A, M
d8b2  b9         CMP C
d8b3  c2 8d da   JNZ da8d
d8b6  21 d9 d8   LXI HL, d8d9
d8b9  19         DAD DE
d8ba  11 c4 d8   LXI DE, d8c4
d8bd  eb         XCHG
d8be  e3         XTHL
d8bf  d5         PUSH DE
d8c0  3a 8b bf   LDA bf8b
d8c3  c9         RET
????:
d8c4  cd 80 dd   CALL dd80
d8c7  cd 12 f8   CALL f812
d8ca  00         NOP
d8cb  ca 61 d8   JZ d861
d8ce  cd 25 d8   CALL d825
d8d1  fe 03      CPI A, 03
d8d3  ca 00 d8   JZ d800
d8d6  c3 61 d8   JMP d861
????:
d8d9  f6 40      ORI A, 40
d8db  32 8c bf   STA bf8c
d8de  cd 9a db   CALL db9a
d8e1  3a 8a bf   LDA bf8a
d8e4  c3 32 da   JMP da32
d8e7  f6 06      ORI A, 06
d8e9  32 8c bf   STA bf8c
d8ec  cd 9a db   CALL db9a
d8ef  0e 01      MVI C, 01
d8f1  c3 40 da   JMP da40
d8f4  cd 56 da   CALL da56
d8f7  f6 01      ORI A, 01
d8f9  32 8c bf   STA bf8c
d8fc  cd 9a db   CALL db9a
d8ff  0e 02      MVI C, 02
d901  c3 40 da   JMP da40
d904  cd 56 da   CALL da56
d907  c3 32 da   JMP da32
d90a  cd 5e da   CALL da5e
d90d  c3 32 da   JMP da32
d910  cd 66 da   CALL da66
d913  c3 32 da   JMP da32
d916  3a 8a bf   LDA bf8a
d919  47         MOV B, A
d91a  e6 07      ANI A, 07
d91c  b8         CMP B
d91d  c2 8d da   JNZ da8d
d920  07         RLC
d921  07         RLC
d922  07         RLC
d923  c3 32 da   JMP da32
d926  2a 85 bf   LHLD bf85
d929  eb         XCHG
d92a  2a 8a bf   LHLD bf8a
d92d  19         DAD DE
d92e  22 85 bf   SHLD bf85
d931  c9         RET
d932  21 a0 bf   LXI HL, bfa0
d935  cd cd da   CALL dacd
d938  fe 3a      CPI A, 3a
d93a  c2 92 da   JNZ da92
d93d  2a 8a bf   LHLD bf8a
d940  22 87 bf   SHLD bf87
d943  eb         XCHG
d944  3a 83 bf   LDA bf83
d947  3d         DCR A
d948  c0         RNZ
d949  3a 84 bf   LDA bf84
d94c  3d         DCR A
d94d  c8         RZ
d94e  fa 54 d9   JM d954
d951  11 fe ff   LXI DE, fffe
????:
d954  2a 8d bf   LHLD bf8d
d957  73         MOV M, E
d958  23         INX HL
d959  72         MOV M, D
d95a  c9         RET
????:
d95b  eb         XCHG
d95c  2a 85 bf   LHLD bf85
d95f  1a         LDAX DE
d960  fe 27      CPI A, 27
d962  c2 76 d9   JNZ d976
d965  13         INX DE
????:
d966  1a         LDAX DE
d967  13         INX DE
d968  b7         ORA A
d969  ca 8d da   JZ da8d
d96c  fe 27      CPI A, 27
d96e  ca 88 d9   JZ d988
d971  77         MOV M, A
d972  23         INX HL
d973  c3 66 d9   JMP d966
????:
d976  3a 8a bf   LDA bf8a
d979  77         MOV M, A
d97a  23         INX HL
d97b  3a 89 bf   LDA bf89
d97e  fe 0e      CPI A, 0e
d980  ca 88 d9   JZ d988
d983  3a 8b bf   LDA bf8b
d986  77         MOV M, A
d987  23         INX HL
????:
d988  22 85 bf   SHLD bf85
d98b  eb         XCHG
d98c  cd 0a db   CALL db0a
d98f  b7         ORA A
d990  c8         RZ
d991  fe 3b      CPI A, 3b
d993  c8         RZ
d994  cd 9a db   CALL db9a
d997  c3 5b d9   JMP d95b
d99a  3a 95 bf   LDA bf95
d99d  b7         ORA A
d99e  c0         RNZ
d99f  3c         INR A
d9a0  32 95 bf   STA bf95
d9a3  21 00 a0   LXI HL, a000
d9a6  eb         XCHG
d9a7  2a 8a bf   LHLD bf8a
d9aa  cd 20 da   CALL da20
d9ad  22 98 bf   SHLD bf98
d9b0  c9         RET
????:
d9b1  cd 80 dd   CALL dd80
d9b4  21 83 bf   LXI HL, bf83
d9b7  7e         MOV A, M
d9b8  34         INR M
d9b9  3d         DCR A
d9ba  ca 51 d8   JZ d851
d9bd  3a 94 bf   LDA bf94
d9c0  fe 02      CPI A, 02
d9c2  c2 fc d9   JNZ d9fc
d9c5  0e 1f      MVI C, 1f
d9c7  cd 50 de   CALL de50
d9ca  2a 80 bf   LHLD bf80
????:
d9cd  06 06      MVI B, 06
????:
d9cf  7e         MOV A, M
d9d0  b7         ORA A
d9d1  ca fc d9   JZ d9fc
d9d4  4f         MOV C, A
d9d5  cd 50 de   CALL de50
d9d8  05         DCR B
d9d9  23         INX HL
d9da  c2 cf d9   JNZ d9cf
d9dd  0e 3d      MVI C, 3d
d9df  cd 50 de   CALL de50
d9e2  0e 20      MVI C, 20
d9e4  cd 50 de   CALL de50
d9e7  23         INX HL
d9e8  7e         MOV A, M
d9e9  cd 42 de   CALL de42
d9ec  2b         DCX HL
d9ed  7e         MOV A, M
d9ee  cd 42 de   CALL de42
d9f1  23         INX HL
d9f2  23         INX HL
d9f3  01 20 04   LXI BC, 0420
d9f6  cd 27 da   CALL da27
d9f9  c3 cd d9   JMP d9cd
????:
d9fc  21 b3 df   LXI HL, dfb3
d9ff  cd 18 f8   CALL f818
da02  3a 82 bf   LDA bf82
da05  cd 42 de   CALL de42
da08  cd d3 dd   CALL ddd3
da0b  2a 85 bf   LHLD bf85
da0e  2b         DCX HL
da0f  eb         XCHG
da10  2a 98 bf   LHLD bf98
da13  19         DAD DE
da14  0e 2f      MVI C, 2f
da16  cd 48 de   CALL de48
da19  eb         XCHG
da1a  cd 48 de   CALL de48
da1d  c3 00 d8   JMP d800
????:
da20  7d         MOV A, L
da21  93         SUB E
da22  6f         MOV L, A
da23  7c         MOV A, H
da24  9a         SBB D
da25  67         MOV H, A
da26  c9         RET
????:
da27  04         INR B
da28  05         DCR B
da29  c8         RZ
????:
da2a  cd 50 de   CALL de50
da2d  05         DCR B
da2e  c8         RZ
da2f  c3 2a da   JMP da2a
????:
da32  47         MOV B, A
da33  3a 8c bf   LDA bf8c
da36  b0         ORA B
da37  2a 85 bf   LHLD bf85
????:
da3a  77         MOV M, A
da3b  23         INX HL
????:
da3c  22 85 bf   SHLD bf85
da3f  c9         RET
????:
da40  2a 8a bf   LHLD bf8a
da43  eb         XCHG
da44  2a 85 bf   LHLD bf85
da47  3a 8c bf   LDA bf8c
da4a  77         MOV M, A
da4b  23         INX HL
da4c  73         MOV M, E
da4d  23         INX HL
da4e  0d         DCR C
da4f  ca 3c da   JZ da3c
da52  7a         MOV A, D
da53  c3 3a da   JMP da3a
????:
da56  fe 40      CPI A, 40
????:
da58  c2 63 da   JNZ da63
da5b  3e 30      MVI A, 30
da5d  c9         RET
????:
da5e  fe 48      CPI A, 48
da60  c3 58 da   JMP da58
????:
da63  fe 20      CPI A, 20
da65  c8         RZ
????:
da66  fe 10      CPI A, 10
da68  c8         RZ
da69  b7         ORA A
da6a  c2 8d da   JNZ da8d
da6d  c9         RET
????:
da6e  06 01      MVI B, 01
da70  c3 78 da   JMP da78
????:
da73  06 02      MVI B, 02
da75  11 fe ff   LXI DE, fffe
????:
da78  e5         PUSH HL
da79  21 84 bf   LXI HL, bf84
da7c  7e         MOV A, M
da7d  b0         ORA B
da7e  77         MOV M, A
da7f  21 82 bf   LXI HL, bf82
da82  7e         MOV A, M
da83  3c         INR A
da84  27         DAA
da85  77         MOV M, A
da86  e1         POP HL
da87  c9         RET
????:
da88  06 04      MVI B, 04
da8a  c3 94 da   JMP da94
????:
da8d  06 08      MVI B, 08
da8f  c3 94 da   JMP da94
????:
da92  06 10      MVI B, 10
????:
da94  cd 78 da   CALL da78
da97  c3 c4 d8   JMP d8c4
????:
da9a  11 a0 bf   LXI DE, bfa0
da9d  0e 40      MVI C, 40
da9f  2a 8f bf   LHLD bf8f
????:
daa2  7e         MOV A, M
daa3  fe ff      CPI A, ff
daa5  ca b1 d9   JZ d9b1
daa8  fe 0d      CPI A, 0d
daaa  ca c0 da   JZ dac0
daad  fe 09      CPI A, 09
daaf  c2 b4 da   JNZ dab4
dab2  3e 20      MVI A, 20
????:
dab4  12         STAX DE
dab5  af         XRA A
dab6  b9         CMP C
dab7  ca bc da   JZ dabc
daba  13         INX DE
dabb  0d         DCR C
????:
dabc  23         INX HL
dabd  c3 a2 da   JMP daa2
????:
dac0  af         XRA A
dac1  12         STAX DE
dac2  23         INX HL
dac3  79         MOV A, C
dac4  fe 40      CPI A, 40
dac6  ca a2 da   JZ daa2
dac9  22 8f bf   SHLD bf8f
dacc  c9         RET
????:
dacd  0e 06      MVI C, 06
dacf  11 e0 bf   LXI DE, bfe0
dad2  d5         PUSH DE
dad3  3e 20      MVI A, 20
????:
dad5  12         STAX DE
dad6  13         INX DE
dad7  0d         DCR C
dad8  c2 d5 da   JNZ dad5
dadb  d1         POP DE
dadc  cd 0a db   CALL db0a
dadf  fe 3f      CPI A, 3f
dae1  f8         RM
dae2  fe 80      CPI A, 80
dae4  f0         RP
????:
dae5  47         MOV B, A
dae6  79         MOV A, C
dae7  fe 06      CPI A, 06
dae9  ca f0 da   JZ daf0
daec  78         MOV A, B
daed  12         STAX DE
daee  13         INX DE
daef  0c         INR C
????:
daf0  23         INX HL
daf1  7e         MOV A, M
daf2  fe 30      CPI A, 30
daf4  fa 0a db   JM db0a
daf7  fe 3a      CPI A, 3a
daf9  ca 08 db   JZ db08
dafc  fa e5 da   JM dae5
daff  ff         RST 7
db00  40         MOV B, B
db01  f8         RM
db02  fe 80      CPI A, 80
db04  fa e5 da   JM dae5
db07  c9         RET
????:
db08  23         INX HL
db09  c9         RET
????:
db0a  7e         MOV A, M
db0b  fe 20      CPI A, 20
db0d  c0         RNZ
db0e  23         INX HL
db0f  c3 0a db   JMP db0a
????:
db12  cd 79 db   CALL db79
db15  3a 83 bf   LDA bf83
db18  3d         DCR A
db19  c2 5e db   JNZ db5e
db1c  b9         CMP C
db1d  ca 59 db   JZ db59
db20  11 e0 bf   LXI DE, bfe0
db23  0e 06      MVI C, 06
????:
db25  1a         LDAX DE
db26  77         MOV M, A
db27  13         INX DE
db28  23         INX HL
db29  0d         DCR C
db2a  c2 25 db   JNZ db25
db2d  22 8d bf   SHLD bf8d
db30  e5         PUSH HL
db31  2a 85 bf   LHLD bf85
db34  eb         XCHG
db35  2a 98 bf   LHLD bf98
db38  19         DAD DE
db39  eb         XCHG
db3a  e1         POP HL
db3b  73         MOV M, E
db3c  23         INX HL
db3d  72         MOV M, D
db3e  23         INX HL
db3f  71         MOV M, C
????:
db40  eb         XCHG
db41  21 f0 ff   LXI HL, fff0
db44  39         DAD SP
db45  eb         XCHG
db46  cd 53 db   CALL db53
db49  d8         RC
db4a  21 eb df   LXI HL, dfeb
????:
db4d  cd 18 f8   CALL f818
db50  c3 00 d8   JMP d800
????:
db53  7c         MOV A, H
db54  ba         CMP D
db55  c0         RNZ
db56  7d         MOV A, L
db57  bb         CMP E
db58  c9         RET
????:
db59  3d         DCR A
db5a  77         MOV M, A
db5b  23         INX HL
db5c  77         MOV M, A
db5d  c9         RET
????:
db5e  46         MOV B, M
db5f  23         INX HL
db60  7e         MOV A, M
db61  fe ff      CPI A, ff
db63  c0         RNZ
db64  b8         CMP B
db65  ca 6e da   JZ da6e
db68  3d         DCR A
db69  b8         CMP B
db6a  ca 73 da   JZ da73
db6d  c9         RET
????:
db6e  cd 79 db   CALL db79
db71  0d         DCR C
db72  f2 73 da   JP da73
db75  5e         MOV E, M
db76  23         INX HL
db77  56         MOV D, M
db78  c9         RET
????:
db79  2a 80 bf   LHLD bf80
????:
db7c  0e 06      MVI C, 06
db7e  af         XRA A
db7f  be         CMP M
db80  c8         RZ
db81  e5         PUSH HL
db82  11 e0 bf   LXI DE, bfe0
????:
db85  1a         LDAX DE
db86  be         CMP M
db87  ca 92 db   JZ db92
db8a  e1         POP HL
db8b  01 08 00   LXI BC, 0008
db8e  09         DAD BC
db8f  c3 7c db   JMP db7c
????:
db92  13         INX DE
db93  23         INX HL
db94  0d         DCR C
db95  c2 85 db   JNZ db85
db98  d1         POP DE
db99  c9         RET
????:
db9a  7e         MOV A, M
db9b  fe 2c      CPI A, 2c
db9d  c2 8d da   JNZ da8d
dba0  23         INX HL
dba1  cd b2 db   CALL dbb2
dba4  3a 89 bf   LDA bf89
dba7  fe 03      CPI A, 03
dba9  ca ad db   JZ dbad
dbac  0d         DCR C
????:
dbad  0d         DCR C
dbae  c2 8d da   JNZ da8d
dbb1  c9         RET
????:
dbb2  cd cd da   CALL dacd
dbb5  af         XRA A
dbb6  32 93 bf   STA bf93
dbb9  32 8a bf   STA bf8a
dbbc  32 8b bf   STA bf8b
dbbf  b9         CMP C
dbc0  ca da db   JZ dbda
dbc3  cd 22 dc   CALL dc22
dbc6  fe 01      CPI A, 01
dbc8  c2 d3 db   JNZ dbd3
dbcb  4f         MOV C, A
dbcc  cd 17 dc   CALL dc17
dbcf  c8         RZ
dbd0  da 8d da   JC da8d
????:
dbd3  e5         PUSH HL
dbd4  cd 6e db   CALL db6e
dbd7  c3 03 dc   JMP dc03
????:
dbda  cd 17 dc   CALL dc17
dbdd  c8         RZ
dbde  fe 2b      CPI A, 2b
dbe0  ca e8 db   JZ dbe8
dbe3  fe 2d      CPI A, 2d
dbe5  c2 ec db   JNZ dbec
????:
dbe8  32 93 bf   STA bf93
dbeb  23         INX HL
????:
dbec  cd 58 dc   CALL dc58
dbef  0c         INR C
dbf0  ca 8d da   JZ da8d
dbf3  3a 93 bf   LDA bf93
dbf6  fe 2d      CPI A, 2d
dbf8  c2 02 dc   JNZ dc02
dbfb  af         XRA A
dbfc  93         SUB E
dbfd  5f         MOV E, A
dbfe  3e 00      MVI A, 00
dc00  9a         SBB D
dc01  57         MOV D, A
????:
dc02  e5         PUSH HL
????:
dc03  2a 8a bf   LHLD bf8a
dc06  19         DAD DE
dc07  22 8a bf   SHLD bf8a
dc0a  e1         POP HL
dc0b  cd 58 dc   CALL dc58
dc0e  0c         INR C
dc0f  c2 8d da   JNZ da8d
dc12  0e 02      MVI C, 02
dc14  c3 da db   JMP dbda
????:
dc17  7e         MOV A, M
dc18  b7         ORA A
dc19  c8         RZ
dc1a  fe 2c      CPI A, 2c
dc1c  c8         RZ
dc1d  fe 3b      CPI A, 3b
dc1f  c8         RZ
dc20  37         STC
dc21  c9         RET
????:
dc22  e5         PUSH HL
dc23  21 77 de   LXI HL, de77
dc26  41         MOV B, C
????:
dc27  11 e0 bf   LXI DE, bfe0
dc2a  48         MOV C, B
dc2b  7e         MOV A, M
dc2c  23         INX HL
dc2d  b7         ORA A
dc2e  ca 56 dc   JZ dc56
dc31  b9         CMP C
dc32  ca 3f dc   JZ dc3f
dc35  4f         MOV C, A
????:
dc36  23         INX HL
dc37  0d         DCR C
dc38  c2 36 dc   JNZ dc36
dc3b  23         INX HL
dc3c  c3 27 dc   JMP dc27
????:
dc3f  1a         LDAX DE
dc40  13         INX DE
dc41  be         CMP M
dc42  c2 36 dc   JNZ dc36
dc45  23         INX HL
dc46  0d         DCR C
dc47  c2 3f dc   JNZ dc3f
dc4a  7e         MOV A, M
dc4b  32 8a bf   STA bf8a
dc4e  07         RLC
dc4f  07         RLC
dc50  07         RLC
dc51  32 8b bf   STA bf8b
dc54  3e 01      MVI A, 01
????:
dc56  e1         POP HL
dc57  c9         RET
????:
dc58  cd cd da   CALL dacd
dc5b  0d         DCR C
dc5c  f2 ef dc   JP dcef
dc5f  7e         MOV A, M
dc60  fe 27      CPI A, 27
dc62  ca d2 dc   JZ dcd2
dc65  fe 24      CPI A, 24
dc67  ca fe dc   JZ dcfe
dc6a  fe 30      CPI A, 30
dc6c  f8         RM
dc6d  fe 3a      CPI A, 3a
dc6f  f0         RP
dc70  11 e0 bf   LXI DE, bfe0
dc73  0e 00      MVI C, 00
????:
dc75  d6 30      SUI A, 30
dc77  12         STAX DE
dc78  13         INX DE
dc79  23         INX HL
dc7a  7e         MOV A, M
dc7b  fe 30      CPI A, 30
dc7d  fa 9a dc   JM dc9a
dc80  fe 3a      CPI A, 3a
dc82  fa 75 dc   JM dc75
dc85  fe 41      CPI A, 41
dc87  fa 9a dc   JM dc9a
dc8a  0c         INR C
dc8b  fe 48      CPI A, 48
dc8d  ca a4 dc   JZ dca4
dc90  fe 4a      CPI A, 4a
dc92  f2 8d da   JP da8d
dc95  d6 07      SUI A, 07
dc97  c3 75 dc   JMP dc75
????:
dc9a  af         XRA A
dc9b  b9         CMP C
dc9c  c2 8d da   JNZ da8d
dc9f  3e 19      MVI A, 19
dca1  c3 a7 dc   JMP dca7
????:
dca4  23         INX HL
dca5  3e 29      MVI A, 29
????:
dca7  12         STAX DE
dca8  e5         PUSH HL
dca9  21 e0 bf   LXI HL, bfe0
dcac  11 00 00   LXI DE, 0000
dcaf  de 19      SBI A, 19
????:
dcb1  47         MOV B, A
dcb2  7e         MOV A, M
dcb3  23         INX HL
dcb4  fe 10      CPI A, 10
dcb6  f2 09 dd   JP dd09
dcb9  4f         MOV C, A
dcba  78         MOV A, B
dcbb  b7         ORA A
dcbc  06 00      MVI B, 00
dcbe  e5         PUSH HL
dcbf  62         MOV H, D
dcc0  6b         MOV L, E
dcc1  29         DAD HL
dcc2  29         DAD HL
dcc3  c2 ca dc   JNZ dcca
dcc6  19         DAD DE
dcc7  c3 cb dc   JMP dccb
????:
dcca  29         DAD HL
????:
dccb  29         DAD HL
dccc  09         DAD BC
dccd  eb         XCHG
dcce  e1         POP HL
dccf  c3 b1 dc   JMP dcb1
????:
dcd2  0e 02      MVI C, 02
dcd4  3a 89 bf   LDA bf89
dcd7  fe 0e      CPI A, 0e
dcd9  c2 df dc   JNZ dcdf
dcdc  33         INX SP
dcdd  33         INX SP
dcde  c9         RET
????:
dcdf  23         INX HL
dce0  5e         MOV E, M
dce1  23         INX HL
dce2  56         MOV D, M
????:
dce3  7e         MOV A, M
dce4  23         INX HL
dce5  b7         ORA A
dce6  ca 8d da   JZ da8d
dce9  fe 27      CPI A, 27
dceb  c2 e3 dc   JNZ dce3
dcee  c9         RET
????:
dcef  cd 22 dc   CALL dc22
dcf2  fe 01      CPI A, 01
dcf4  ca 8d da   JZ da8d
dcf7  e5         PUSH HL
dcf8  cd 6e db   CALL db6e
dcfb  c3 09 dd   JMP dd09
????:
dcfe  23         INX HL
dcff  e5         PUSH HL
dd00  2a 87 bf   LHLD bf87
dd03  eb         XCHG
dd04  2a 98 bf   LHLD bf98
dd07  19         DAD DE
dd08  eb         XCHG
????:
dd09  e1         POP HL
dd0a  0e 02      MVI C, 02
dd0c  c9         RET
????:
dd0d  3a e3 bf   LDA bfe3
dd10  fe 58      CPI A, 58
dd12  c2 18 dd   JNZ dd18
dd15  32 e2 bf   STA bfe2
????:
dd18  3a e0 bf   LDA bfe0
dd1b  d6 41      SUI A, 41
dd1d  fa 88 da   JM da88
dd20  5f         MOV E, A
dd21  16 00      MVI D, 00
dd23  21 99 de   LXI HL, de99
dd26  19         DAD DE
dd27  5e         MOV E, M
dd28  23         INX HL
dd29  7e         MOV A, M
dd2a  93         SUB E
dd2b  ca 88 da   JZ da88
dd2e  4f         MOV C, A
dd2f  c5         PUSH BC
dd30  21 b4 de   LXI HL, deb4
dd33  19         DAD DE
dd34  19         DAD DE
dd35  19         DAD DE
dd36  0e 20      MVI C, 20
dd38  3a e1 bf   LDA bfe1
dd3b  91         SUB C
dd3c  ca 43 dd   JZ dd43
dd3f  91         SUB C
dd40  fa 88 da   JM da88
????:
dd43  07         RLC
dd44  07         RLC
dd45  07         RLC
dd46  47         MOV B, A
dd47  3a e2 bf   LDA bfe2
dd4a  91         SUB C
dd4b  ca 52 dd   JZ dd52
dd4e  91         SUB C
dd4f  fa 88 da   JM da88
????:
dd52  0f         RRC
dd53  0f         RRC
dd54  4f         MOV C, A
dd55  e6 07      ANI A, 07
dd57  b0         ORA B
dd58  57         MOV D, A
dd59  79         MOV A, C
dd5a  e6 c0      ANI A, c0
dd5c  5f         MOV E, A
dd5d  c1         POP BC
????:
dd5e  7e         MOV A, M
dd5f  23         INX HL
dd60  ba         CMP D
dd61  c2 6b dd   JNZ dd6b
dd64  7e         MOV A, M
dd65  e6 c0      ANI A, c0
dd67  bb         CMP E
dd68  ca 74 dd   JZ dd74
????:
dd6b  23         INX HL
dd6c  23         INX HL
dd6d  0d         DCR C
dd6e  c2 5e dd   JNZ dd5e
dd71  c3 88 da   JMP da88
????:
dd74  7e         MOV A, M
dd75  e6 3f      ANI A, 3f
dd77  32 89 bf   STA bf89
dd7a  23         INX HL
dd7b  7e         MOV A, M
dd7c  32 8c bf   STA bf8c
dd7f  c9         RET
????:
dd80  3a 94 bf   LDA bf94
dd83  1f         RAR
dd84  d0         RNC
dd85  3a 83 bf   LDA bf83
dd88  3d         DCR A
dd89  c8         RZ
dd8a  cd d3 dd   CALL ddd3
dd8d  3a 84 bf   LDA bf84
dd90  b7         ORA A
dd91  ca 9f dd   JZ dd9f
dd94  cd 42 de   CALL de42
dd97  0e 2a      MVI C, 2a
dd99  cd 50 de   CALL de50
dd9c  c3 a5 dd   JMP dda5
????:
dd9f  01 20 03   LXI BC, 0320
dda2  cd 27 da   CALL da27
????:
dda5  11 a0 bf   LXI DE, bfa0
dda8  1a         LDAX DE
dda9  fe 3b      CPI A, 3b
ddab  01 20 11   LXI BC, 1120
ddae  ca b8 dd   JZ ddb8
ddb1  af         XRA A
ddb2  32 93 bf   STA bf93
ddb5  cd dd dd   CALL dddd
????:
ddb8  eb         XCHG
ddb9  cd 27 da   CALL da27
ddbc  cd 18 f8   CALL f818
????:
ddbf  3a 93 bf   LDA bf93
ddc2  b7         ORA A
ddc3  c8         RZ
ddc4  cd d3 dd   CALL ddd3
ddc7  01 20 03   LXI BC, 0320
ddca  cd 27 da   CALL da27
ddcd  cd dd dd   CALL dddd
ddd0  c3 bf dd   JMP ddbf
????:
ddd3  0e 0d      MVI C, 0d
ddd5  cd 50 de   CALL de50
ddd8  0e 0a      MVI C, 0a
ddda  c3 50 de   JMP de50
????:
dddd  3a 89 bf   LDA bf89
dde0  fe 0c      CPI A, 0c
dde2  c8         RZ
dde3  fe 0d      CPI A, 0d
dde5  c8         RZ
dde6  2a 87 bf   LHLD bf87
dde9  fe 11      CPI A, 11
ddeb  ca 3d de   JZ de3d
ddee  f5         PUSH PSW
ddef  d5         PUSH DE
ddf0  eb         XCHG
ddf1  2a 98 bf   LHLD bf98
ddf4  19         DAD DE
ddf5  cd 48 de   CALL de48
ddf8  eb         XCHG
ddf9  d1         POP DE
ddfa  f1         POP PSW
ddfb  fe 10      CPI A, 10
ddfd  ca 24 de   JZ de24
de00  06 04      MVI B, 04
????:
de02  3a 85 bf   LDA bf85
de05  95         SUB L
de06  ca 1c de   JZ de1c
de09  7e         MOV A, M
de0a  23         INX HL
de0b  cd 42 de   CALL de42
de0e  cd 50 de   CALL de50
de11  05         DCR B
de12  c2 02 de   JNZ de02
de15  3a 85 bf   LDA bf85
de18  95         SUB L
de19  22 87 bf   SHLD bf87
????:
de1c  32 93 bf   STA bf93
de1f  78         MOV A, B
de20  07         RLC
de21  80         ADD B
de22  47         MOV B, A
de23  c9         RET
????:
de24  0e 28      MVI C, 28
de26  cd 50 de   CALL de50
de29  0e 20      MVI C, 20
de2b  cd 50 de   CALL de50
de2e  2a 8a bf   LHLD bf8a
de31  cd 48 de   CALL de48
de34  0e 29      MVI C, 29
de36  cd 50 de   CALL de50
de39  01 20 04   LXI BC, 0420
de3c  c9         RET
????:
de3d  06 0c      MVI B, 0c
de3f  c3 48 de   JMP de48
????:
de42  c5         PUSH BC
de43  cd 15 f8   CALL f815
de46  c1         POP BC
de47  c9         RET
????:
de48  7c         MOV A, H
de49  cd 42 de   CALL de42
de4c  7d         MOV A, L
de4d  cd 42 de   CALL de42
????:
de50  c3 09 f8   JMP f809
????:
de53  0b         DCX BC
de54  00         NOP
de55  08         db 08
de56  01 2e 01   LXI BC, 012e
de59  00         NOP
de5a  01 16 02   LXI BC, 0216
de5d  0e 01      MVI C, 01
de5f  26 02      MVI H, 02
de61  2b         DCX HL
de62  01 31 01   LXI BC, 0131
de65  37         STC
de66  01 1b 01   LXI BC, 011b
de69  3d         DCR A
de6a  02         STAX BC
de6b  c1         POP BC
de6c  02         STAX BC
de6d  d8         RC
de6e  00         NOP
de6f  82         ADD D
de70  02         STAX BC
de71  82         ADD D
de72  02         STAX BC
de73  4d         MOV C, L
de74  02         STAX BC
de75  59         MOV E, C
de76  02         STAX BC
????:
de77  01 41 07   LXI BC, 0741
de7a  01 42 00   LXI BC, 0042
de7d  01 43 01   LXI BC, 0143
de80  01 44 02   LXI BC, 0244
de83  01 45 03   LXI BC, 0345
de86  01 48 04   LXI BC, 0448
de89  01 4c 05   LXI BC, 054c
de8c  01 4d 00   LXI BC, 004d
de8f  02         STAX BC
de90  53         MOV D, E
de91  50         MOV D, B
de92  08         db 08
de93  03         INX BC
de94  50         MOV D, B
de95  53         MOV D, E
de96  57         MOV D, A
de97  09         DAD BC
de98  00         NOP
????:
de99  00         NOP
de9a  06 06      MVI B, 06
de9c  13         INX DE
de9d  1b         DCX DE
de9e  1e 1e      MVI E, 1e
dea0  1e 1f      MVI E, 1f
dea2  22 2c 2c   SHLD 2c2c
dea5  30         db 30
dea6  32 33 37   STA 3733
dea9  3a 3a 48   LDA 483a
deac  51         MOV D, C
dead  51         MOV D, C
deae  51         MOV D, C
deaf  51         MOV D, C
deb0  51         MOV D, C
deb1  55         MOV D, L
deb2  55         MOV D, L
deb3  55         MOV D, L
????:
deb4  1a         LDAX DE
deb5  44         MOV B, H
deb6  ce 20      ACI A, 20
deb8  c1         POP BC
deb9  88         ADC B
deba  21 01 80   LXI HL, 8001
debd  22 44 c6   SHLD c644
dec0  70         MOV M, B
dec1  41         MOV B, C
dec2  a0         ANA B
dec3  72         MOV M, D
dec4  44         MOV B, H
dec5  e6 0b      ANI A, 0b
dec7  06 cd      MVI B, cd
dec9  18         db 18
deca  06 dc      MVI B, dc
decc  68         MOV L, B
decd  06 fc      MVI B, fc
decf  68         MOV L, B
ded0  40         MOV B, B
ded1  2f         CMA
ded2  68         MOV L, B
ded3  c0         RNZ
ded4  3f         CMC
ded5  6c         MOV L, H
ded6  01 b8 70   LXI BC, 70b8
ded9  c6 d4      ADI A, d4
dedb  76         HLT
dedc  86         ADD M
dedd  c4 00 06   CNZ 0600
dee0  f4 81 46   CP 4681
dee3  ec 82 44   CPE 4482
dee6  fe 83      CPI A, 83
dee8  c6 e4      ADI A, e4
deea  d0         RNC
deeb  06 cc      MVI B, cc
deed  08         db 08
deee  40         MOV B, B
deef  27         DAA
def0  09         DAD BC
def1  07         RLC
def2  09         DAD BC
def3  1c         INR E
def4  82         ADD D
def5  05         DCR B
def6  1e 07      MVI E, 07
def8  0b         DCX BC
def9  48         MOV C, B
defa  00         NOP
defb  f3         DI
defc  10         db 10
defd  0e 60      MVI C, 60
deff  b8         CMP B
df00  0f         RRC
df01  00         NOP
df02  98         SBB B
df03  10         db 10
df04  00         NOP
df05  48         MOV C, B
df06  00         NOP
df07  fb         EI
df08  71         MOV M, C
df09  0d         DCR C
df0a  00         NOP
df0b  80         ADD B
df0c  51         MOV D, C
df0d  00         NOP
df0e  65         MOV H, L
df0f  00         NOP
df10  76         HLT
df11  70         MOV M, B
df12  04         INR B
df13  db 74      IN 74
df15  82         ADD D
df16  04         INR B
df17  76         HLT
df18  07         RLC
df19  03         INX BC
df1a  18         db 18
df1b  06 da      MVI B, da
df1d  68         MOV L, B
df1e  06 fa      MVI B, fa
df20  6c         MOV L, H
df21  06 c3      MVI B, c3
df23  00         NOP
df24  06 c3      MVI B, c3
df26  70         MOV M, B
df27  c6 d2      ADI A, d2
df29  76         HLT
df2a  86         ADD M
df2b  02         STAX BC
df2c  00         NOP
df2d  06 f2      MVI B, f2
df2f  01 46 ea   LXI BC, ea46
df32  83         ADD E
df33  c6 e2      ADI A, e2
df35  d0         RNC
df36  06 ca      MVI B, ca
df38  20         db 20
df39  46         MOV B, M
df3a  3a 26 09   LDA 0926
df3d  0a         LDAX BC
df3e  43         MOV B, E
df3f  06 2a      MVI B, 2a
df41  c2 4a 01   JNZ 014a
df44  b2         ORA D
df45  45         MOV B, L
df46  06 7d      MVI B, 7d
df48  83         ADD E
df49  40         MOV B, B
df4a  7d         MOV A, L
df4b  00         NOP
df4c  00         NOP
df4d  90         SUB B
df4e  41         MOV B, C
df4f  b0         ORA B
df50  92         SUB D
df51  44         MOV B, H
df52  f6 ad      ORI A, ad
df54  04         INR B
df55  d3 91      OUT 91
df57  cc 00 1a   CZ 1a00
df5a  00         NOP
df5b  e9         PCHL
df5c  7c         MOV A, H
df5d  08         db 08
df5e  c1         POP BC
df5f  ac         XRA H
df60  c8         RZ
df61  c5         PUSH BC
df62  0b         DCX BC
df63  00         NOP
df64  17         RAL
df65  0c         INR C
df66  80         ADD B
df67  1f         RAR
df68  60         MOV H, B
df69  c0         RNZ
df6a  07         RLC
df6b  90         SUB B
df6c  c0         RNZ
df6d  0f         RRC
df6e  2d         DCR L
df6f  00         NOP
df70  c9         RET
df71  18         db 18
df72  00         NOP
df73  d8         RC
df74  70         MOV M, B
df75  c0         RNZ
df76  d0         RNC
df77  d0         RNC
df78  00         NOP
df79  c8         RZ
df7a  76         HLT
df7b  80         ADD B
df7c  c0         RNZ
df7d  80         ADD B
df7e  00         NOP
df7f  f0         RP
df80  68         MOV L, B
df81  00         NOP
df82  f8         RM
df83  81         ADD C
df84  40         MOV B, B
df85  e8         RPE
df86  83         ADD E
df87  c0         RNZ
df88  e0         RPO
df89  9d         SBB L
df8a  0b         DCX BC
df8b  c7         RST 0
df8c  10         db 10
df8d  81         ADD C
df8e  98         SBB B
df8f  12         STAX DE
df90  44         MOV B, H
df91  de 43      SBI A, 43
df93  06 22      MVI B, 22
df95  82         ADD D
df96  00         NOP
df97  f9         SPHL
df98  a0         ANA B
df99  46         MOV B, M
df9a  32 a6 09   STA 09a6
df9d  02         STAX BC
df9e  a0         ANA B
df9f  c0         RNZ
dfa0  37         STC
dfa1  a8         XRA B
dfa2  81         ADD C
dfa3  90         SUB B
dfa4  aa         XRA D
dfa5  44         MOV B, H
dfa6  d6 1a      SUI A, 1a
dfa8  00         NOP
dfa9  eb         XCHG
dfaa  90         SUB B
dfab  41         MOV B, C
dfac  a8         XRA B
dfad  92         SUB D
dfae  44         MOV B, H
dfaf  ee a2      XRI A, a2
dfb1  00         NOP
dfb2  e3         XTHL
????:
dfb3  0a         LDAX BC
dfb4  45         MOV B, L
dfb5  52         MOV D, D
dfb6  52         MOV D, D
dfb7  4f         MOV C, A
dfb8  52         MOV D, D
dfb9  53         MOV D, E
dfba  20         db 20
dfbb  44         MOV B, H
dfbc  45         MOV B, L
dfbd  54         MOV D, H
dfbe  45         MOV B, L
dfbf  43         MOV B, E
dfc0  54         MOV D, H
dfc1  45         MOV B, L
dfc2  44         MOV B, H
dfc3  3a 00 0a   LDA 0a00
dfc6  41         MOV B, C
dfc7  53         MOV D, E
dfc8  53         MOV D, E
????:
dfc9  4d         MOV C, L
dfca  2e 2a      MVI L, 2a
dfcc  6d         MOV L, L
dfcd  69         MOV L, C
dfce  6b         MOV L, E
dfcf  72         MOV M, D
dfd0  6f         MOV L, A
dfd1  6e         MOV L, M
dfd2  2a 0a 2a   LHLD 2a0a
dfd5  00         NOP
????:
dfd6  50         MOV D, B
dfd7  4c         MOV C, H
dfd8  45         MOV B, L
dfd9  41         MOV B, C
dfda  53         MOV D, E
dfdb  45         MOV B, L
dfdc  20         db 20
dfdd  31 2c 32   LXI SP, 322c
dfe0  2c         INR L
dfe1  33         INX SP
dfe2  2c         INR L
dfe3  43         MOV B, E
dfe4  54         MOV D, H
dfe5  52         MOV D, D
dfe6  4c         MOV C, H
dfe7  22 43 22   SHLD 2243
dfea  00         NOP
????:
dfeb  54         MOV D, H
dfec  4f         MOV C, A
dfed  4f         MOV C, A
dfee  20         db 20
dfef  4c         MOV C, H
dff0  4f         MOV C, A
dff1  4e         MOV C, M
dff2  47         MOV B, A
dff3  00         NOP
dff4  00         NOP
dff5  00         NOP
dff6  00         NOP
dff7  00         NOP
dff8  00         NOP
dff9  00         NOP
dffa  00         NOP
dffb  00         NOP
dffc  00         NOP
dffd  00         NOP
dffe  00         NOP
dfff  00         NOP

; This is another portion of the UT-88 OS Monitor, providing some handy but non essential commands to deal
; with memory data. The functions are located at 0xc000 memory range, outside of the main Monitor range. 
; However, main Monitor command selector is aware of these commands, so that they can be executed with
; 1- or 2- letter codes.
; 
;
; - Command C - Memory copy and compare:
;   - C <src_start>, <src_end>, <dst_start>     - Compare memory data between two ranges
;   - C/CY <src_start>, <src_end>, <dst_start>  - Copy memory from one memory range to another
; - Command F - Fill or verify memory range:
;   - FY<addr1>, <addr2>, <constant>            - Fill memory range with the constant
;   - F<addr1>, <addr2>, <constant>             - Compare memory range with the constant, report differences
; - Command H - Calculate sum and difference between the two 16-bit arguments
;   - H<arg1>,<arg2>                            - Calculate and print sum and difference
; - Command J - Quick jump:
;   - J<addr>                                   - Set the quick jump address
;   - J                                         - Execute from the previously set quick jump address
; - Command D - Dump the memory
;   - D                                         - Dump 128-byte chunk of memory, starting the user program HL
;   - D<start>                                  - Dump 128-byte chunk, starting the address provided
;   - D<start>,<end>                            - Dump memory for the specified memory range
; - Command V - Measure tape delay constant
; - Command S - Search string in a memory range
;   - S maddr1, maddr2, saddr1, saddr2      - Search string located saddr1-saddr2 in a memory range maddr1-maddr2
;   - S maddr1, maddr2, '<string>'          - Search string specified in single quotes in maddr1-maddr2 memory
;   - S maddr1, maddr2, &<hex>, <hex>,...   - Search string specified in a form of hex sequence in specified
; - Command L - List the text from the memory
;   - L <addr1>[, <addr2>]                  - List text located at addr1-addr2 range
; 
; Refer to corresponding command comments for more details on the command implementation and the algorithm



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



; See ut88os_asm_disassm.asm for Command Z and Command P implementation (0xc1eb - 0xc385)



; Command L: List the text from the memory
;
; Usage:
; L - <addr1>[, <addr2>]
;
; The command prints all printable characters in addr1-addr2 range. 0xb000 will be used if no addr2
; specified. Every line of the text is supplied with line start address. The command prints 16 lines
; at a time, and then waits for a key press. Space key continues execution for another 16 lines, other
; key stops the printing.
COMMAND_L_LIST_TEXT:
    c386  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)   ; Parse arguments

    c389  06 10      MVI B, 10                  ; Will print 10 lines at a time

    c38b  eb         XCHG                       ; HL - start address, DE - end address (if specified)
    c38c  13         INX DE                     ; Adjust end address so that it is 1 byte after the range

    c38d  c2 93 c3   JNZ c393                   ; Set end address as 0xb000 if no end address is specified
    c390  11 00 b0   LXI DE, b000

LIST_TEXT_NEW_LINE:
    c393  0e 0a      MVI C, 0a                  ; Print new line
    c395  cd f0 f9   CALL PUT_CHAR (f9f0)

    c398  05         DCR B                      ; Pause every 16 lines, wait for a keyboard press for continue
    c399  cc b7 c3   CZ LIST_TEXT_WAIT_KBD (c3b7)

    c39c  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print line start address

LIST_TEXT_NEXT_CHAR:
    c39f  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Exit if reached end address
    c3a2  c8         RZ

    c3a3  7e         MOV A, M                   ; Load the next symbol, exit if symbol code is >= 0x80
    c3a4  b7         ORA A
    c3a5  f8         RM

    c3a6  fe 0d      CPI A, 0d                  ; Restart the line if EOL symbol is found
    c3a8  23         INX HL
    c3a9  ca 93 c3   JZ LIST_TEXT_NEW_LINE (c393)

    c3ac  e5         PUSH HL                    ; Print the char (of '_' if char not printable)
    c3ad  cd 28 fe   CALL GET_PRINTABLE_SYMBOL (fe28)
    c3b0  e1         POP HL
    c3b1  cd f0 f9   CALL PUT_CHAR (f9f0)

    c3b4  c3 9f c3   JMP LIST_TEXT_NEXT_CHAR (c39f) ; Repeat until end address is reached


LIST_TEXT_WAIT_KBD:
    c3b7  cd 6b f8   CALL KBD_INPUT (f86b)      ; Wait for a keyboard press

    c3ba  fe 20      CPI A, 20                  ; Non-space char exits the command
    c3bc  c1         POP BC
    c3bd  c0         RNZ

    c3be  c5         PUSH BC                    ; Space char continues the command execution for next 16 lines
    c3bf  06 0f      MVI B, 0f
    c3c1  c9         RET

;
;
; Important variables:
; f7b0 - Current cursor position (offset from video memory start address)
; f7b2 - Current cursor position (memory address)
; f7b4 - User program PC register (when stopping at breakpoint)
; f7b6 - User program HL register (when stopping at breakpoint)
; f7b8 - User program BC register (when stopping at breakpoint)
; f7bA - User program DE register (when stopping at breakpoint)
; f7bc - User program SP register (when stopping at breakpoint)
; f7be - User program AF register (when stopping at breakpoint)
; f7c3 - Breakpoint address (when running user program with Command G)
; f7c5 - Original opcode under breakpoint address (see Command G description)
; f7ce - Tape input polarity (0x00 if non-inverted, 0xff if inverted)
; f7cf - Tape delay constant when loading
; f7d0 - Tape delay constant when saving
; f7d1 - ???
; f7f8 - Flag indicating that the next char will be cursor direct movement coordinate
VECTORS:                                        ; Jump vectors to real function implementations
    f800  c3 36 f8   JMP START (f836)
    f803  c3 57 fd   JMP KBD_INPUT (fd57)
    f806  c3 71 fb   JMP IN_BYTE (fb71)
    f809  c3 43 fc   JMP PUT_CHAR_C (fc43)
    f80c  c3 ee fb   JMP OUT_BYTE (fbee)
    f80f  c3 43 fc   JMP PUT_CHAR_C (fc43)
    f812  c3 6b fe   JMP IS_BUTTON_PRESSED (fe6b)
    f815  c3 2e fc   JMP PRINT_HEX_BYTE (fc2e)
    f818  c3 1f f9   JMP PRINT_STR (f91f)
    f81b  c3 9a fd   JMP SCAN_KBD_STABLE (fd9a)
    f81e  c3 72 fa   JMP GET_CURSOR_POS (fa72)
    f821  c3 76 fa   JMP GET_CHAR_AT_CURS (fa76)
    f824  c3 ad fa   JMP IN_PROGRAM (faad)
    f827  c3 24 fb   JMP DO_OUT_MEMORY (fb24)
    f82a  c3 f6 fa   JMP CALC_CRC (faf6)
    f82d  c9 ff ff   RET
    f830  c3 77 fe   JMP fe77
    f833  c3 7b fe   JMP fe7b


START:
    f836  3e 8b      MVI A, 8b                  ; Configure 8255 keyboard matrix controller as
    f838  d3 04      OUT 04                     ; port A - output, ports B and C - input (all mode 0).

    f83a  3e 82      MVI A, 82                  ; Set up external ROM over i8255 controller
    f83c  d3 fb      OUT fb                     ; Ports A and C as output (address), Port B - input (data)
    
    f83e  31 af f7   LXI SP, f7af               ; Initial stack pointer set up

    f841  21 b0 f7   LXI HL, f7b0               ; Clear Monitor's variables
    f844  11 ff f7   LXI DE, f7ff
    f847  0e 00      MVI C, 00
    f849  cd e7 f9   CALL MEMSET (f9e7)

    f84c  21 af f7   LXI HL, f7af               ; ???
    f84f  22 bc f7   SHLD f7bc

    f852  21 d3 fa   LXI HL, HELLO_STR (fad3)   ; Print the Hello string ("*UT-88*")
    f855  cd 1f f9   CALL PRINT_STR (f91f)

    f858  00         NOP
    f859  00         NOP
    f85a  00         NOP

    f85b  21 ff df   LXI HL, dfff
    f85e  22 d1 f7   SHLD f7d1

    f861  21 2a 1d   LXI HL, 1d2a               ; Precalculated tape delay constants (0x2a for loading,
    f864  22 cf f7   SHLD f7cf                  ; and 0x1d for saving)

    f867  3e c3      MVI A, c3                  ; JMP instruction code, f7c7 contains the entered address
    f869  32 c6 f7   STA f7c6

ENTER_NEXT_COMMAND:
    f86c  31 af f7   LXI SP, f7af               ; Some subroutines will jump directly here. Reset the SP

    f86f  21 7f fe   LXI HL, PROMPT_STR (fe7f)
    f872  cd 1f f9   CALL PRINT_STR (f91f)
    
    f875  00         NOP
    f876  00         NOP
    f877  00         NOP
    f878  00         NOP

    f879  cd eb f8   CALL INPUT_LINE (f8eb)

    f87c  21 6c f8   LXI HL, f86c               ; Push ENTER_NEXT_COMMAND address to stack, so commands
    f87f  e5         PUSH HL                    ; may just return to the next command routine

    f880  21 d3 f7   LXI HL, f7d3               ; Load the first character in the command buffer
    f883  7e         MOV A, M

    f884  fe 58      CPI 58                     ; Handle command 'X'
    f886  ca ec fe   JZ COMMAND_X (feec)
    f889  fe 55      CPI 55                     ; Handle command 'U'
    f88b  ca 00 f0   JZ f000                    ; Execute program starting address 0xf000

    f88e  f5         PUSH PSW
    f88f  cd 29 f9   CALL PARSE_ARGUMENTS (f929)

    f892  2a cb f7   LHLD f7cb                  ; Load 3rd argument into BC
    f895  4d         MOV C, L
    f896  44         MOV B, H

    f897  2a c9 f7   LHLD f7c9                  ; Load 2nd argument into DE
    f89a  eb         XCHG

    f89b  2a c7 f7   LHLD f7c7                  ; Load 1st argument into HL

    f89e  f1         POP PSW
    f89f  fe 44      CPI 44                     ; Handle Command 'D'
    f8a1  ca bf f9   JZ COMMAND_D (f9bf)

    f8a4  fe 43      CPI 43                     ; Handle command 'C'
    f8a6  ca d1 f9   JZ COMMAND_C (f9d1)

    f8a9  fe 46      CPI 46                     ; Handle command 'F'
    f8ab  ca e7 f9   JZ COMMAND_F (f9e7)

    f8ae  fe 53      CPI 53                     ; Handle command 'S'
    f8b0  ca ee f9   JZ COMMAND_S (f9ee)

    f8b3  fe 54      CPI 54                     ; Handle command 'T'
    f8b5  ca f9 f9   JZ COMMAND_T (f9f9)

    f8b8  fe 4d      CPI 4d                     ; Handle command 'M'
    f8ba  ca 20 fa   JZ COMMAND_M (fa20)

    f8bd  fe 47      CPI 47                     ; Handle command 'G'
    f8bf  ca 39 fa   JZ COMMAND_G (fa39)

    f8c2  fe 49      CPI 49                     ; Handle command 'I'
    f8c4  ca 7d fa   JZ COMMAND_I (fa7d)

    f8c7  fe 4f      CPI 4f                     ; Handle command 'O'
    f8c9  ca 08 fb   JZ COMMAND_O (fb08)

    f8cc  fe 4c      CPI 4c                     ; Handle command 'L'
    f8ce  ca 02 fa   JZ COMMAND_L (fa02)

    c8d1  fe 52      CPI 52                     ; Handle command 'R'
    c8d3  ca 62 fa   JZ COMMAND_R (fa62)
    
    c8d6  c3 17 ff   JMP COMMAND_HANDLER_CONT (ff17)


; Handle the backspace button while entering a line
HANDLE_BACKSPACE:
    f8d9  3e 63      MVI A, 63                  ; ???? Should be D3? not 63?
    f8db  bd         CMP L
    f8dc  ca ee f8   JZ INPUT_LINE_RESET (f8ee)

    f8df  e5         PUSH HL                    ; Clear a symbole left to the cursor, move cursor left
    f8e0  21 b7 fe   LXI HL, BACKSPACE_STR (feb7)
    f8e3  cd 1f f9   CALL PRINT_STR (f91f)

    f8e6  e1         POP HL
    f8e7  2b         DCX HL
    f8e8  c3 f0 f8   JMP INPUT_LINE_LOOP (f8f0)


; Input a line
;
; Inputs a line into buffer at 0xf7d3, 32 bytes long. The function handles regular chars, and puts
; them into the buffer. The function also handles backspace symbolc, removing the characted to the left
; from the cursor. 
;
; Special conditions:
; - When 'Enter' char is entered, the function returns, and DE contains the address of the buffer (0xf7d3)
; - When nothing is entered, the carry flag will be reset. The carry flag is set when something is in the
;   buffer.
; - If the user types '.' symbol, enterring the current line is abandoned. CPU jumps to the main loop.
; - If the user enters more than 32 symbols, the input is abandoned as well.

INPUT_LINE:
    f8eb  21 d3 f7   LXI HL, f7d3               ; Set the buffer address to HL

INPUT_LINE_RESET:
    f8ee  06 00      MVI B, 00

INPUT_LINE_LOOP:
    f8f0  cd 57 fd   CALL KBD_INPUT (fd57)

    f8f3  fe 08      CPI 08                     ; Handle left arrow button
    f8f5  ca d9 f8   JZ HANDLE_BACKSPACE (f8d9)

    f8f8  fe 7f      CPI 7f                     ; Same as back space
    f8fa  ca d9 f8   JZ HANDLE_BACKSPACE (f8d9)

    f8fd  c4 42 fc   CNZ PUT_CHAR_A (fc42)      ; Print entered symbol

    f900  77         MOV M, A                   ; And store it at the buffer

    f901  fe 0d      CPI 0d                     ; Handle 'Enter' button
    f903  ca 17 f9   JZ INPUT_LINE_ENTER (f917)
    f906  fe 2e      CPI 2e                     ; Handle '.' (reset the current line input)
    f908  ca 6c f8   JZ ENTER_NEXT_COMMAND (f86c)   ; Bug: we are in a subroutine

    f90b  06 ff      MVI B, ff                  
    
    f90d  3e f2      MVI A, f2                  ; Check if we reached the end of the input buffer
    f90f  bd         CMP L
    f910  ca a5 fa   JZ BAD_INPUT (faa5)

    f913  23         INX HL                     ; Repeat for the next symbol
    f914  c3 f0 f8   JMP INPUT_LINE_LOOP (f8f0)

INPUT_LINE_ENTER:
    f917  78         MOV A, B                   ; Move B state to carry flag
    f918  17         RAL

    f919  11 d3 f7   LXI DE, f7d3               ; Return buffer address in DE
    f91c  06 00      MVI B, 00
    f91e  c9         RET


; Print a string
; HL - string address (null terminated string)
PRINT_STR:
    f91f  7e         MOV A, M
    f920  a7         ANA A
    f921  c8         RZ
    
    f922  cd 42 fc   CALL PUT_CHAR_A (fc42)
    f925  23         INX HL
    f926  c3 1f f9   JMP PRINT_STR (f91f)



; Parse command arguments
;
; This function parses up to 3 command arguments (4 digit hex addresses or values).
; Arguments are stored at the following addresses:
; f7c7  - 1st argument
; f7c9  - 2nd argument (if exists)
; f7cb  - 3rd argument (if exists)
; f7cd  - flag indicating there is more than 1 argument (0xff - 2 or more arguments, 0x00 - 1 arg only)
; 
; Unused arguments are zeroed
PARSE_ARGUMENTS:
    f929  21 c7 f7   LXI HL, f7c7
    f92c  11 cd f7   LXI DE, f7cd
    f92f  0e 00      MVI C, 00
    f931  cd e7 f9   CALL MEMSET (f9e7)

    f934  11 d4 f7   LXI DE, f7d4
    f937  cd 57 f9   CALL PARSE_ADDR (f957)

    f93a  22 c7 f7   SHLD f7c7                  ; Store first parsed parameter at f7c7
    f93d  22 c9 f7   SHLD f7c9

    f940  d8         RC                         ; Return if end of line reached
    
    f941  3e ff      MVI A, ff                  ; Indicate that we have more than 1 parameters
    f943  32 cd f7   STA f7cd

    f946  cd 57 f9   CALL PARSE_ADDR (f957)

    f949  22 c9 f7   SHLD f7c9                  ; Store second parsed parameter at f7c9

    f94c  d8         RC                         ; Return if end of line reached

    f94d  cd 57 f9   CALL PARSE_ADDR (f957)

    f950  22 cb f7   SHLD f7cb                  ; Store 3rd parsed parameter at f7cb

    f953  d8         RC                         ; Return if end of line reached

    f954  c3 a5 fa   JMP BAD_INPUT (faa5)       ; If more than 3 arguments - it is a bad input


; Parse 4-digit address from the provided string buffer
; Stop parsing on ',' separator, or end of line (0x0d).
; Spaces are ignored.
;
; Parameters:
; DE - string buffer to parse
;
; Result:
; HL - parsed address, in case of success
; carry flag set if the end of line reached
PARSE_ADDR:
    f957  21 00 00   LXI HL, 0000

PARSE_ADDR_LOOP:
    f95a  1a         LDAX DE
    f95b  13         INX DE

    f95c  fe 0d      CPI 0d                     ; Enter
    f95e  ca 8b f9   JZ PARSE_ADDR_EOL (f98b)

    f961  fe 2c      CPI 2c                     ; ','
    f963  c8         RZ

    f964  fe 20      CPI 20                     ; Skip spaces
    f966  ca 5a f9   JZ PARSE_ADDR_LOOP (f95a)

    f969  d6 30      SUI 30                     ; Symbols below 0x30 are bad input
    f96b  fa a5 fa   JN BAD_INPUT (faa5)

    f96e  fe 0a      CPI 0a                     ; Match digit (0x30-0x39)
    f970  fa 7f f9   JN PARSE_ADDR_DIGIT (f97f)

    f973  fe 11      CPI 11                     ; Match hex letter ('A' - 'F')
    f975  fa a5 fa   JN BAD_INPUT (faa5)        ; Other character is a bad input

    f978  fe 17      CPI 17
    f97a  f2 a5 fa   JP BAD_INPUT (faa5)

    f97d  d6 07      SUI 07                     ; Convert letter to a number

PARSE_ADDR_DIGIT:
    f97f  4f         MOV C, A                   ; Store parsed digit in C (suppose B==0x00, but why???)

    f980  29         DAD HL                     ; Shift parsed address 4 bits left
    f981  29         DAD HL
    f982  29         DAD HL
    f983  29         DAD HL

    f984  da a5 fa   JC BAD_INPUT (faa5)        ; If more than 4 digits in the address - it is a bad input

    f987  09         DAD BC                     ; Add parsed digit to the result in HL

    f988  c3 5a f9   JMP PARSE_ADDR_LOOP (f95a) ; Repeat until end of line, or ',' separator found

PARSE_ADDR_EOL:
    f98b  37         STC
    f98c  c9         RET


; Compare HL and DE
; Set Z flag if equal
CMP_HL_DE:
    f98d  7c         MOV A, H
    f98e  ba         CMP D
    f98f  c0         RNZ
    f990  7d         MOV A, L
    f991  bb         CMP E
    f992  c9         RET

????:
    f993  cd a1 f9   CALL f9a1

ADVANCE_HL:                                     ; Advance HL until it reaches DE
    f996  cd 8d f9   CALL CMD_HL_DE (f98d)
    f999  c2 9f f9   JNZ ADVANCE_HL_1 (f99f)
    
    f99c  33         INX SP                     ; Exit from the caller function as well
    f99d  33         INX SP
    f99e  c9         RET

ADVANCE_HL_1:
    f99f  23         INX HL
    f9a0  c9         RET


?????:
    f9a1  3e ff      MVI A, ff
    f9a3  a7         ANA A
    f9a4  fe 03      CPI 03
    f9a6  c0         RNZ
    f9a7  c3 a5 fa   JMP BAD_INPUT (faa5)


; Start new dump line
NEW_DUMP_LINE:
    f9aa  e5         PUSH HL
    f9ab  21 85 fe   LXI HL, TAB_STR (fe85)     ; Print new tabbed line
    f9ae  cd 1f f9   CALL PRINT_STR (f91f)
    f9b1  e1         POP HL
    f9b2  c9         RET


; Print a byte at [HL] as a 2-digit hex value, then add a space
PRINT_MEMORY_BYTE:
    f9b3  7e         MOV A, M

; Print a 2-digit hex value in A, then add a space
PRINT_HEX_BYTE_SPACE:
    f9b4  c5         PUSH BC
    f9b5  cd 2e fc   CALL PRINT_HEX_BYTE (fc2e)

    f9b8  3e 20      MVI A, 20                  ; Print ' '
    f9ba  cd 42 fc   CALL PUT_CHAR_A (fc42)

    f9bd  c1         POP BC
    f9be  c9         RET

; Command D - Dump memory
; 
; Arguments:
; - start address (HL)
; - end address (DE)
COMMAND_D:
    f9bf  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) ; Print new line, and a memory address

COMMAND_D_LOOP:
    f9c2  cd b3 f9   CALL PRINT_MEMORY_BYTE (f9b3)  ; Print next byte
    f9c5  cd 93 f9   CALL f993                  ; Do something ??? and advance HL

    f9c8  7d         MOV A, L                   ; Check if we reached end of current line
    f9c9  e6 0f      ANI 0f
    f9cb  ca bf f9   JZ f9bf                    ; Get to the new line

    f9ce  c3 c2 f9   JMP COMMAND_D_LOOP (f9c2)

; Command C - Compare memory ranges
;
; Arguments:
; - Range 1 start address (HL)
; - Range 1 end address (DE)
; - Range 2 start address (BC)
COMMAND_C:
    f9d1  0a         LDAX BC                    ; Compare bytes from both ranges
    f9d2  be         CMP M
    f9d3  ca e0 f9   JZ COMMAND_C_NEXT (f9e0)   ; Advance to the next byte if equal

    f9d6  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) ; Print the address of the unmatched byte
    f9d9  cd b3 f9   CALL PRINT_MEMORY_BYTE (f9b3)  ; Print source byte
    f9dc  0a         LDAX BC
    f9de  cd b4 f9   CALL PRINT_HEX_BYTE_SPACE (f9b4)   ; Print unmatched destination byte

COMMAND_C_NEXT:
    f9e0  03         INX BC                     ; Advance BC
    f9e1  cd 93 f9   CALL f993                  ; Do something??? and advance HL, exit if reached DE
    f9e4  c3 d1 f9   JMP COMMAND_C (f9d1)


; Command F - fill a memory range with a specified byte.
;
; Command arguments:
; - start address (HL)
; - end address (DE)
; - value to fill with (C)
COMMAND_F:
; HL    - start address
; DE    - end address
; C     - byte to fill
MEMSET:
    f9e7  71         MOV M, C
    f9e8  cd 96 f9   CALL ADVANCE_HL (f996)
    f9eb  c3 e7 f9   JMP MEMSET (f9e7)

; Search a byte in a memory range
;
; Arguments:
; - start address (HL)
; - end address (DE)
; - Byte to search (C)
COMMAND_S:
    f9ee  79         MOV A, C                   ; Compare the memory byte
    f9ef  be         CMP M

    f9f0  cc 51 fb   CZ fb51                    ; If found - print the address
    f9f3  cd 93 f9   CALL f993                  ; Do something ???? and advance HL, exit if reached DE
    f9f6  c3 ee f9   JMP COMMAND_S (f9ee)       ; Repeat for the next symbol


; Copy memory
;
; Arguments:
; - Start address (HL)
; - End address (DE)
; - Target start address (BC)
COMMAND_T:
    f9f9  7e         MOV A, M               ; Copy single byte
    f9fa  02         STAX BC

    f9fb  03         INX BC                 ; Advance BC
    f9fc  cd 96 f9   CALL ADVANCE_HL (f996) ; Advance HL, exit when reached DE

    f9ff  c3 f9 f9   JMP COMMAND_T (f9f9)


; Dump memory in a text representation
;
; Arguments:
; - start address (HL)
; - end address (DE)
COMMAND_L:
    fa02  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)

COMMAND_L_LOOP:
    fa05  7e         MOV A, M                   ; Load the next byte to print

    fa06  b7         ORA A                      ; Bytes >= 0x80 are printed as dots
    fa07  fa 0f fa   JN COMMAND_L_DOT (fa0f)

    fa0a  fe 20      CPI 20                     ; Bytes < 0x20 are printed as dots
    fa0c  d2 11 fa   JNC COMMAND_L_CHAR (fa11)       ; Printable symbols are printed as is

COMMAND_L_DOT:
    fa0f  3e 2e      MVI 2e                     ; Print '.'

COMMAND_L_CHAR:
    fa11  cd 42 fc   CALL PUT_CHAR_A (fc42)

    fa14  cd 93 f9   CALL f993                  ; Do something ???? and advance HL, exit if reached DE

    fa17  7d         MOV A, L                   ; Move to the new line every 16 symbols
    fa18  e6 0f      ANI 0f
    fa1a  ca 02 fa   JZ COMMAND_L (fa02)

    fa1d  c3 05 fa   JMP COMMAND_L_LOOP (fa05)  ; Repeat for the new symbol


; Command M - edit memory
;
; Arguments:
; - Address to view and edit (HL)
COMMAND_M:
    fa20  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) ; Print the address and current byte value
    fa23  cd b3 f9   CALL PRINT_MEMORY_BYTE (f9b3)

    fa26  e5         PUSH HL                    ; Input the new value
    fa27  cd eb f8   CALL INPUT_LINE (f8eb)
    fa2a  e1         POP HL

    fa2b  d2 35 fa   JNC COMMAND_M_NEXT (fa35)  ; If no new value entered - move to the next byte

    fa2e  e5         PUSH HL                    ; If a value entered - parse it
    fa2f  cd 57 f9   CALL PARSE_ADDR (f957)

    fa32  7d         MOV A, L                   ; Store parsed value to the memory at current address
    fa33  e1         POP HL
    fa34  77         MOV M, A

COMMAND_M_NEXT:
    fa35  23         INX HL                     ; Advance to the next address and repeat
    fa36  c3 20 fa   JMP COMMAND_M (fa20)


; Command G - Run program from specified address
;
; Arguments:
; - Address of the program (HL)
; - (optional) Breakpoint address (DE)
;
; This command runs the user program starting the specified address. Optionally,
; it is possible to set a breakpoint address, where the program execution will break,
; and the flow returns to the Monitor. When the program is stopped at breakpoint, the
; User can use X Command to display and modify program registers.
;
; If the user specified breakpoint address, the following algorithm applies:
; - Instruction at the breakpoint address is replaced with RST 6 (original byte is
;   saved at f7c5)
; - Bytes 0x0030-0x0032 which are executed on RST 6 are replaced with JMP febb (breakpoint handler)
; 
; When a breakpoint happens:
; - All registers (including SP, and PC at the breakpoint address) are stored at f7b4-f7bf.
; - Instruction at the breakpoint address is restored with the backup at f7c5
; - Control flow passed to the main command loop
;
; The user may now:
; - Inspect and edit program data
; - Inspect and edit CPU registers stored to f7b4-f7bf by running Commmand X
; - Run the program from the breakpoint address with Command G. In this case the command handler
;   will run the following extra actions:
;   - Restore CPU registers from f7b4-f7bf
;   - Run the user program starting from specified address
COMMAND_G:
    fa39  cd 8d f9   CALL CMP_HL_DE (f98d)
    fa3c  ca 54 fa   JZ RUN_PROGRAM (fa54)

    fa3f  eb         XCHG                       ; Store breakpoint address at f7c3 in order to
    fa40  22 c3 f7   SHLD f7c3                  ; restore original program later

    fa43  7e         MOV A, M                   ; Load byte under break point and store it at f7c5
    fa44  32 c5 f7   STA f7c5

    fa47  36 f7      MVI M, f7                  ; Put RST 6 instruction instead

    fa49  3e c3      MVI A, c3                  ; Store JMP febb opcode at RST6 handler (0x0030)
    fa4b  32 30 00   STA 0030 
    fa4e  21 bb fe   LXI HL, febb
    fa51  22 31 00   SHLD 0031

RUN_PROGRAM:
    fa54  31 b8 f7   LXI SP, f7b8               ; Restore registers previously saved to f7b4-f7bf 
    fa57  c1         POP BC                     ; by the breakpoint handler
    fa58  d1         POP DE
    fa59  e1         POP HL
    fa5a  f1         POP PSW

    fa5b  f9         SPHL                       ; Restore SP

    fa5c  2a b6 f7   LHLD f7b6                  ; Restore HL

    fa5f  c3 c6 f7   JMP f7c6                   ; Jump to the user program (f7c6 contains JMP instruction
                                                ; opcode, f7c7 contains the command argument with the user
                                                ; program address)


; Command R - read external ROM
;
; Import specified data range from external ROM to the main RAM.
;
; It is supposed that the ROM is connected via a i8255 controller, where ROM address lines are
; connected to ports B (low byte) and C (high byte), while data is read over port A.
;
; Note: the magazine never published the external ROM schematics, so described connection is just
; a guess, based on the code below. Moreover it contradicts with the i8255 setup above, which for some
; reason configures ports A and C as output, and B as input.
;
; Note: it is not clear what type of ROM is connected, and what its size. The code below reads up to 
; 256 bytes, but there is no technical limitation to read a larger ROM.
;
; Arguments:
; - ROM start address (HL)
; - ROM end address (DE)
; - Target (RAM) start address (BC)
COMMAND_R:
    fa62  7c         MOV A, H                   ; Output high byte of the address to port C
    fa63  d3 fa      OUT fa

COMMAND_R_LOOP:
    fa65  7d         MOV A, L                   ; Output low byte of the address to port B
    fa66  d3 f9      OUT f9

    fa68  db f8      IN f8                      ; Read ROM value and save it at target address
    fa6a  02         STAX BC
    fa6b  03         INX BC

    fa6c  cd 96 f9   CALL ADVANCE_HL (f996)
    fa6f  c3 65 fa   JMP COMMAND_R_LOOP (fa65)


; Get current cursor position
GET_CURSOR_POS:
    fa72  2a b0 f7   LHLD f7b0                  ; Load cursor position to HL
    fa75  c9         RET

; Get symbol at cursor position
;
; Return: A - symbol under cursor
;
; BUG: Memory value at f7b0 contains cursor position relative to the video memory start.
; This is not an absolute byte address, so reading memory at this location will return 
; garbage. Perhaps it needs to use f7b2 variable instead, which is absolute address of the
; cursor.
GET_CHAR_AT_CURS:
    fa76  e5         PUSH HL                    ; Get character under cursor
    fa77  2a b0 f7   LHLD f7b0
    fa7a  7e         MOV A, M
    fa7b  e1         POP HL
    fa7c  c9         RET


; Command I - load data from tape
;
; Arguments:
; - Offset (HL)
; - (Optional) Tape constant (E)
COMMAND_I:
    fa7d  3a cd f7   LDA f7cd                   ; Check if tape constant is set
    fa80  b7         ORA A
    fa81  ca 88 fa   JZ COMMAND_I_1 (fa88)

    fa84  7b         MOV A, E                   ; Save tape constant at 0xf7cf
    fa85  32 cf f7   STA f7cf

COMMAND_I_1:
    fa88  cd ad fa   CALL IN_PROGRAM (faad)     ; Load the program from tape

    fa8b  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) ; Print start and end address
    fa8e  eb         XCHG
    fa8f  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)
    fa92  eb         XCHG

    fa93  c5         PUSH BC
    fa94  cd f6 fa   CALL CALC_CRC (faf6)       ; Calculate and print CRC

    fa97  60         MOV H, B
    fa98  69         MOV L, C
    fa99  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)

    fa9c  d1         POP DE                     ; Compare calculated CRC with recorded one
    fa9d  cd 8d f9   CALL CMP_HL_DE (f98d)

    faa0  c8         RZ                         ; If everything is ok - just exit

    faa1  eb         XCHG                       ; If CRC does not match - print it, and show an error
    faa2  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)


BAD_INPUT:
    faa5  3e 3f      MVI A, 3f                  ; Print '?'
    faa7  cd 42 fc   CALL PUT_CHAR_A (fc42)
    faaa  c3 6c f8   JMP ENTER_NEXT_COMMAND (f86c)



IN_PROGRAM:
    faad  3e ff      MVI A, ff                  ; Receive start address to BC
    faaf  cd df fa   CALL IN_WORD_SYNC (fadf)

    fab2  e5         PUSH HL                    ; Apply start address offset
    fab3  09         DAD BC
    fab4  eb         XCHG

    fab5  cd dd fa   CALL IN_WORD (fadd)        ; Receive end address to BC

    fab8  e1         POP HL                     ; Apply end address offset
    fab9  09         DAD BC
    faba  eb         XCHG

    fabb  e5         PUSH HL                    ; At this point HL - start address, DE - end address

    fabc  cd ea fa   CALL IN_BYTES_LOOP (faea)

    fabf  3e ff      MVI A, ff                  ; Wait for a sync byte, and then CRC
    fac1  cd df fa   CALL IN_WORD_SYNC (fadf)   ; Return CRC in BC

    fac4  e1         POP HL
    fac5  c9         RET


?????:
    fac6  06 00      MVI B, 00
?????_LOOP:
    fac8  70         MOV M, B
    fac9  23         INX H
    faca  7c         MOV A, H
    facb  fe f0      CPI f0
    facd  c2 c8 fa   JNZ ?????_LOOP (fac8)

    fad0  d1         POP DE
    fad1  e1         POP HL
    fad2  c9         RET


HELLO_STR:
    fad3 1f          db 1f                      # Clear screen  
    fad4 1a          db 1a                      # Move to the second line
    fad5 2a 60 74 2f 38 38 2a 00     db "*ЮТ/88*", 0x00    # Hello string

; Receive 2 bytes from tape
; Result in BC
IN_WORD:
    fadd 3e 08       MVI A, 08

IN_WORD_SYNC:
    fadf  cd 71 fb   CALL IN_BYTE (fb71)
    fae2  47         MOV B, A
    fae3  3e 08      MVI A, 08
    fae5  cd 71 fb   CALL IN_BYTE (fb71)
    fae8  4f         MOV C, A
    fae9  c9         RET 



IN_BYTES_LOOP:
    faea  3e 08      MVI A, 08
    faec  cd 71 fb   CALL IN_BYTE (fb71)
    faef  77         MOV M, A
    faf0  cd 96 f9   CALL ADVANCE_HL (f996)
    faf3  c3 ea fa   JMP IN_BYTES_LOOP (faea)



; Calculate CRC for a memory range
; 
; The algorithm is a simple 16-bit sum of all bytes in the range
;
; Arguments:
; - start address (HL)
; - end address (DE)
;
; Result - BC
CALC_CRC:
    faf6  01 00 00   LXI BC, 0000               ; Initial value

CALC_CRC_LOOP:
    faf9  7e         MOV A, M                   ; Simply add the next byte to BC
    fafa  81         ADD C
    fafb  4f         MOV C, A

    fafc  d2 00 fb   JNC CALC_CRC_1 (fb00)
    faff  04         INR B

CALC_CRC_1:
    fb00  cd 8d f9   CALL CMP_HL_DE (f98d)

    fb03  c8         RZ                         ; Return when reached the end address

    fb04  23         INX HL                     ; Advance to the next byte, and repeat
    fb05  c3 f9 fa   JMP CALC_CRC_LOOP (faf9)



; Command O - output data to the tape
;
; Arguments:
; - Start address (HL)
; - End address (DE)
; - Tape constant (C)
COMMAND_O:
    fb08  79         MOV A, C                   ; Check if the constant is 0
    fb09  b7         ORA A
    fb0a  ca 10 fb   JZ COMMAND_O_1 (fb10)

    fb0d  32 d0 f7   STA f7d0                   ; Store the constant at 0xf7d0

COMMAND_O_1:
    fb10  e5         PUSH HL                    ; Calculate CRC
    fb11  cd f6 fa   CALL CALC_CRC (faf6)
    fb14  e1         POP HL

    fb15  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) ; Print start and end address
    fb18  eb         XCHG
    fb19  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)
    fb1c  eb         XCHG

    fb1d  e5         PUSH HL                    ; Print CRC
    fb1e  60         MOV H, B
    fb1f  69         MOV L, C
    fb20  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)
    fb23  e1         POP HL

DO_OUT_MEMORY:
    fb24  c5         PUSH BC
    fb25  01 00 00   LXI BC, 0000               ; Output 256 zeros

TAPE_SYNC_LOOP:
    fb28  cd ee fb   CALL OUT_BYTE (fbee)

    fb2b  05         DCR B
    fb2c  e3         XTHL                       ; ???? Delay?
    fb2d  e3         XTHL
    fb2e  c2 28 fb   JNZ TAPE_SYNC_LOOP (fb28)

    fb31  0e e6      MVI C, e6                  ; Output symchronization byte 0xe6
    fb33  cd ee fb   CALL OUT_BYTE (fbee)

    fb36  cd 69 fb   CALL OUT_WORD (fb69)       ; Write start address
    fb39  eb         XCHG
    fb3a  cd 69 fb   CALL OUT_WORD (fb69)       ; Write end address
    fb3d  eb         XCHG

    fb3e  cd 5f fb   CALL OUT_BYTE_RANGE (fb5f) ; Write data

    fb41  21 00 00   LXI HL, 0000               ; Write 0000 word
    fb44  cd 69 fb   CALL OUT_WORD (fb69)

    fb47  0e e6      MVI C, e6                  ; Output another sync byte
    fb49  cd ee fb   CALL OUT_BYTE (fbee)
    
    fb4c  e1         POP HL
    fb4d  cd 69 fb   CALL OUT_WORD (fb69)
    
    fb50  c9         RET


; Prints an address as a 4 byte hex value on a new line.
; Parameters: HL - address to print
PRINT_HEX_ADDR:
    fb51  c5         PUSH BC
    fb52  cd aa f9   CALL NEW_DUMP_LINE (f9aa)

    fb55  7c         MOV A, H                   ; Print high byte
    fb56  cd 2e fc   CALL PRINT_HEX_BYTE (fc2e)

    fb59  7d         MOV A, L                   ; Print low byte
    fb5a  cd b4 f9   CALL PRINT_HEX_BYTE_SPACE (f9b4)

    fb5d  c1         POP BC
    fb5e  c9         RET

; Output a byte range HL-DE to the tape
OUT_BYTE_RANGE:
    fb5f  4e         MOV C, M
    fb60  cd ee fb   CALL OUT_BYTE (fbee)
    fb63  cd 96 f9   CALL ADVANCE_HL (f996)
    fb66  c3 5f fb   JMP OUT_BYTE_RANGE (fb5f)



; Output HL word to the tape
OUT_WORD:
    fb69  4c         MOV C, H
    fb6a  cd ee fb   CALL OUT_BYTE (fbee)
    fb6d  4d         MOV C, L
    fb6e  c3 ee fb   JMP OUT_BYTE (fbee)

; Receive a byte from tape
;
; Parameters:
; A - number of bits to receive (typically 8), or 0xff if synchronization is required first.
;
; If the synchronization procedure is required (A=0xff as a parameter), the function will wait for
; a pilot tone, then a synchronization byte (0xe6 or 0x19) to determine polarity. Then the requested
; byte is received. Polarity is stored at 0xf7ce.
;
; Returns received byte in A
IN_BYTE:
    fb71  c3 69 ff   JMP IN_BYTE_INTRO (ff69)

DO_IN_BYTE:
    fb74  57         MOV D, A

IN_BYTE_1:
    fb75  21 00 00   LXI HL, 0000               ; Save SP at f7c0, and set SP to 0000
    fb78  39         DAD SP
    fb79  31 00 00   LXI SP, 0000
    fb7c  22 c0 f7   SHLD f7c0

    fb7f  0e 00      MVI C, 00                  ; Reset byte accumulator

    fb81  db a1      IN a1                      ; Input the bit to E register
    fb83  e6 01      ANI 01
    fb85  5f         MOV E, A

IN_BYTE_NEXT_BIT:
    fb86  f1         POP PSW

    fb87  79         MOV A, C                   ; Shift the received byte left, reserving rightmost bit
    fb88  e6 7f      ANI 7f                     ; for the next input bit
    fb8a  07         RLC
    fb8b  4f         MOV C, A

    fb8c  26 00      MVI H, 00

IN_BYTE_WAIT:
    fb8e  25         DCR H                      ; If phase does not change for too long - signal an error
    fb8f  ca df fb   JZ IN_BYTE_ERROR (fbdf)

    fb92  f1         POP PSW

    fb93  db a1      IN a1                      ; Input the bit until the phase change
    fb95  e6 01      ANI 01
    fb97  bb         CMP E
    fb98  ca 8e fb   JZ IN_BYTE_WAIT (fb8e)

    fb9b  b1         ORA C                      ; Store received bit in the received byte register (C)
    fb9c  4f         MOV C, A

    fb9d  15         DCR D
    fb9e  3a cf f7   LDA f7cf
    fba1  c2 a6 fb   JNZ IN_BYTE_DELAY (fba6)

    fba4  d6 12      SUI 12                     ; Compensate the delay between bytes

IN_BYTE_DELAY:
    fba6  47         MOV B, A

IN_BYTE_DELAY_LOOP:
    fba7  f1         POP PSW
    fba8  05         DCR B
    fba9  c2 a7 fb   JNZ IN_BYTE_DELAY_LOOP (fba7)

    fbac  14         INR D                      ; Start receiving the next bit
    fbad  db a1      IN a1
    fbaf  e6 01      ANI 01
    fbb1  5f         MOV E, A

    fbb2  7a         MOV A, D                   ; Check if synchronization has already happened
    fbb3  b7         ORA A
    fbb4  f2 d0 fb   JP IN_BYTE_4 (fbd0)

    fbb7  79         MOV A, C                   ; Check if the received byte is a synchronization byte
    fbb8  fe e6      CPI e6
    fbba  c2 c4 fb   JNZ IN_BYTE_2 (fbc4)

    fbbd  af         XRA A                      ; Save the input polarity
    fbbe  32 ce f7   STA f7ce
    fbc1  c3 ce fb   JMP IN_BYTE_3 (fbce)

IN_BYTE_2:
    fbc4  fe 19      CPI 19                     ; Check if we received an inverted sync byte (~0x19 = 0xe6)
    fbc6  c2 86 fb   JNZ IN_BYTE_NEXT_BIT (fb86); Wait until a sync byte is received

    fbc9  3e ff      MVI A, ff                  ; Save the input polarity
    fbcb  32 ce f7   STA f7ce

IN_BYTE_3:
    fbce  16 09      MVI D, 09                  ; Now we can receive 8 data bits

IN_BYTE_4:
    fbd0  15         DCR D
    fbd1  c2 86 fb   JNZ IN_BYTE_NEXT_BIT (fb86)

    fbd4  2a c0 f7   LHLD f7c0                  ; Restore SP
    fbd7  f9         SPHL

    fbd8  3a ce f7   LDA f7ce                   ; Apply tape polarity constant
    fbdb  a9         XRA C
    fbdc  c3 70 ff   JMP OUT_BYTE_OUTRO (ff70)


IN_BYTE_ERROR:
    fbdf  2a c0 f7   LHLD f7c0                  ; Restore SP
    fbe2  f9         SPHL
    fbe3  7a         MOV A, D
    fbe4  b7         ORA A
    fbe5  f2 a5 fa   JP BAD_INPUT (faa5)        ; Perhaps synchronization did not happen

    fbe8  cd a1 f9   CALL f9a1                  ; ????
    fbeb  c3 75 fb   JMP IN_BYTE_1 (fb75)       ; something went wrong, try receiving another byte


; Output a byte to the tape (byte in С)
;
; This function outputs a byte to the tape, according to 2-phase coding algorithm.
; 
; Data storage format is based on the 2-phase coding algorithm. Each bit is 
; coded as 2 periods with opposite values. The actual bit value is determined
; at the transition between the periods:
; - transition from 1 to 0 represents value 0
; - transition from 0 to 1 represents value 1
;    
; Bytes are written MSB first. Typical recording speed is 1500 bits per second, but
; adjusted with a constant in 0xf7d0
;
;                       Example of 0xA5 byte transfer
;      D7=1 |  D6=0 |  D5=1 |  D4=0 |  D3=0 |  D2=1 |  D1=0 |  D0=1 |
;       +---|---+   |   +---|---+   |---+   |   +---|---+   |   +---|
;       |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
;    ---+   |   +---|---+   |   +---|   +---|---+   |   +---|---+   |
;           |<--T-->|       |       |       |       |       |       |
; 
; Note: this function uses a non-typical way for making delays between bits. Instead of
; using NOPs, it sets stack pointer to 0000, and does random memory stack reads. Unlike
; NOP operation, which is just 4 cycles, POP operation takes 10 cycles. This is not a problem
; for the real hardware, but emulator treats stack and memory operations differently, and
; therefore must take this into account. Overall this looks like a strange solution - setting
; SP, and restoring it back take precious bytes, while extra NOPs could be just accounted
; in the delay constant.
;
OUT_BYTE:
    fbee  c3 77 ff   JMP OUT_BYTE_INTRO (ff77)  ; Save registers and disable interrupts

DO_OUT_BYTE:
    fbf1  f5         PUSH PSW                   ; Save current SP at HL
    fbf2  21 00 00   LXI HL, 0000
    fbf5  39         DAD SP
    fbf6  31 00 00   LXI SP, 0000

    fbf9  16 08      MVI D, 08                  ; Will be sending 8 bits to output

OUT_BYTE_NEXT_BIT:
    fbfb  f1         POP PSW

    fbfc  79         MOV A, C                   ; Roll to the next bit
    fbfd  07         RLC
    fbfe  4f         MOV C, A

    fbff  3e 01      MVI A, 01                  ; Output negative pulse
    fc01  a9         XRA C
    fc02  d3 a1      OUT a1

    fc04  00         NOP                        ; Do a short delay (specified in tape constant at f7d0)
    fc05  3a d0 f7   LDA f7d0
    fc08  47         MOV B, A

OUT_BYTE_DELAY_1:
    fc09  f1         POP PSW
    fc0a  05         DCR B
    fc0b  c2 09 fc   JNZ OUT_BYTE_DELAY_1 (fc09)

    fc0e  3e 00      MVI A, 00                  ; Output positive pulse
    fc10  a9         XRA C
    fc11  d3 a1      OUT a1

    fc13  00         NOP                        ; Prepare for delay after positive pulse
    fc14  15         DCR D
    fc15  3a d0 f7   LDA f7d0
    fc18  c2 1d fc   JNZ OUT_BYTE_1 (fc1d)

    fc1b  d6 0e      SUI 0e                     ; Do a shorter delay between bytes

OUT_BYTE_1:
    fc1d  47         MOV B, A                   ; Do the delay

OUT_BYTE_DELAY_2:
    fc1e  f1         POP PSW
    fc1f  05         DCR B

    fc20  c2 1e fc   JNZ OUT_BYTE_DELAY_2 (fc1e)

    fc23  14         INR D                      ; Repeat for the next bit
    fc24  15         DCR D
    fc25  c2 fb fb   JNZ OUT_BYTE_NEXT_BIT (fbfb)

    fc28  f9         SPHL                       ; Restore original SP
    fc29  f1         POP PSW
    fc2a  c3 70 ff   JMP OUT_BYTE_OUTRO (ff70)  ; Restore registers and enable interrupts

OUT_BYTE_EXIT:
    fc2d  c9         RET                        ; Exit


; Print a byte in A as 2-digit hex value
PRINT_HEX_BYTE:
    fc2e  f5         PUSH PSW

    fc2f  0f         RRC                        ; Print upper half-byte first
    fc30  0f         RRC
    fc31  0f         RRC
    fc32  0f         RRC

    fc33  cd 37 fc   CALL PRINT_HEX_DIGIT (fc37)

    fc36  f1         POP PSW                    ; Restore A, and print lower half-byte

; Print a single hex digit in A (lower half-byte)
PRINT_HEX_DIGIT:
    fc37  e6 0f      ANI 0f
    fc39  fe 0a      CPI 0a
    fc3b  fa 40 fc   JN PRINT_HEX_DIGIT_1 (fc40)

    fc3e  c6 07      ADI 07

PRINT_HEX_DIGIT_1:
    fc40  c6 30      ADI 30                     ; Finish digit to char conversion.
    fc42  4f         MOV C, A                   ; Fall trough Put Char function


; Print a char (see detailed description below)
; A - char to print
PUT_CHAR_A:
    fc42  4f         MOV C, A

; Print a char
; C - char to print
;
; This function puts a char at the cursor location in a terminal mode (including wrapping
; the cursor to the next line, and scrolling the text if the end of screen reached). 
;
; The function is responsible to draw the cursor symbol, by inverting the cursor position (for some
; reason it intentionally highlights the symbol next to the cursor position). The function is responsible
; to hide the highlight when the next symbol is printed.
;
; The function handles the following special chars:
; 0x08  - Move cursor 1 position left
; 0x0c  - Move cursor to the top left position
; 0x18  - Move cursor 1 position right
; 0x19  - Move cursor 1 line up
; 0x1a  - Move cursor 1 line down
; 0x1f  - Clear screen
; 0x1b  - Move cursor to a selected position
;         This is a 4-symbol sequence (similar to Esc sequence):
;         0x1b, 'Y', 0x20+Y position, 0x20+X position
;
; Important variables:
; f7b2 - Current cursor position (memory address)
; f7f8 - cursor direct movement state
;        0 - normal mode, next symbol is a regular symbol
;        1 - 0x1b printed, expecting 'Y'
;        2 - expecting Y coordinate
;        4 - expecting X coordinate
PUT_CHAR_C:
    fc43  e5         PUSH HL
    fc44  c5         PUSH BC
    fc45  d5         PUSH DE
    fc46  f5         PUSH PSW

    fc47  2a b2 f7   LHLD f7b2                  ; Load current cursor location

    fc4a  23         INX HL                     ; Remove highlight at the cursor location
    fc4b  7e         MOV A, M
    fc4c  e6 7f      ANI 7f
    fc4e  77         MOV M, A

    fc4f  2b         DCX HL

    fc50  11 ba fc   LXI DE, PUT_CHAR_RETURN (fcba) ; Returning address after a special symbol is processed
    fc53  d5         PUSH DE
    
    fc54  3a f8 f7   LDA f7f8                   ; Check the direct movement flag state
    fc57  3d         DCR A
    fc58  fa 74 fc   JM PRINT_NORMAL_CHAR (fc74); If it is 0 - normal char print
    fc5b  ca 34 fd   JZ MOVE_CUR_DIRECT_B1 (fd34) ; If it is 1 - expect 'Y' as a second byte of the sequence
    fc5e  e2 42 fd   JPO MOVE_CUR_DIRECT_B2 (fd42) ; If it is 2 - process Y coordinate of direct cursor movement

    fc61  79         MOV A, C                   ; Process X coordinate of direct cursor movement
    fc62  de 20      SBI 20                     ; Adjust by 0x20 (use printable chars)
    fc64  4f         MOV C, A

MOVE_CUR_DIRECT_L1:
    fc65  0d         DCR C
    fc66  fa 6f fc   JM MOVE_CUR_DIRECT_RESET (fc6f)
    fc69  cd e2 fc   CALL MOVE_CUR_RIGHT (fce2)
    fc6c  c3 65 fc   JMP MOVE_CUR_DIRECT_L1 (fc65)

MOVE_CUR_DIRECT_RESET:
    fc6f  af         XRA A                      ; Reset direct movement flag

MOVE_CUR_DIRECT_STORE:
    fc70  32 f8 f7   STA f7f8                   ; Store direct movement flag
    fc73  c9         RET

PRINT_NORMAL_CHAR:
    fc74  79         MOV A, C                   ; 1b - direct cursor movement
    fc75  fe 1b      CPI 1b
    fc77  ca 52 fd   JZ MOVE_CUR_DIRECT (fd52)
    fc7a  fe 1f      CPI 1f                     ; 1f - Clear screen
    fc7c  ca ce fc   JZ CLEAR_SCREEN (fcce)
    fc7f  fe 08      CPI 08                     ; 08 - Move cursor left
    fc81  ca ea fc   JZ MOVE_CUR_LEFT (fcea)
    fc84  fe 18      CPI 18                     ; 18 - Move cursor right
    fc86  ca e2 fc   JZ MOVE_CUR_RIGHT (fce2)
    fc89  fe 19      CPI 19                     ; 19 - Move cursor up
    fc8b  ca fe fc   JZ MOVE_CUR_UP (fcfe)
    fc8e  fe 1a      CPI 1a                     ; 1a - Move cursor down
    fc90  ca f3 fc   JZ MOVE_CUR_DOWN (fcf3)
    fc93  fe 0a      CPI 0a                     ; 0a - Carriage return
    fc95  ca 0b fd   JZ CARRIAGE_RETURN (fd0b)
    fc98  fe 0c      CPI 0c                     ; 0c - Home screen
    fc9a  ca d1 fc   JZ HOME_SCREEN (fcd1)

    fc9d  7c         MOV A, H                   ; Check if we reached end of screen
    fc9e  fe ef      CPI ef
    fca0  c2 b3 fc   JNZ DO_PUT_CHAR (fcb3)

DO_SCROLL:
    fca3  cd 6b fe   CALL IS_BUTTON_PRESSED (fe6b)  ; ?????? It is unclear why it requires reading the btn
    fca6  b7         ORA A
    fca7  ca ad fc   JZ DO_SCROLL_1 (fcad)

    fcaa  cd 57 fd   CALL KBD_INPUT (fd57)

DO_SCROLL_1:
    fcad  cd 19 fd   CALL SCROLL_1_LINE (fd19)

    fcb0  21 bf ee   LXI HL, eebf               ; After the code below cursor will be at the beginning of the last line

DO_PUT_CHAR:
    fcb3  7e         MOV A, M                   ; Store the character while keeping attribute bit
    fcb4  e6 80      ANI 80
    fcb6  b1         ORA C
    fcb7  77         MOV M, A

    fcb8  23         INX HL                     ; Advance cursor pointer to the next position

    fcb9  d1         POP DE                     ; Just discard return address previously stored on stack

PUT_CHAR_RETURN:
    fcba  22 b2 f7   SHLD f7b2                  ; Store the new cursor memory location

    fcbd  23         INX HL                     ; Invert/Highlight the next symbol
    fcbe  7e         MOV A, M
    fcbf  f6 80      ORI 80
    fcc1  77         MOV M, A

    fcc2  11 00 18   LXI DE, 1800               ; Store the cursor position
    fcc5  19         DAD DE
    fcc6  22 b0 f7   SHLD f7b0

    fcc9  f1         POP PSW
    fcca  d1         POP DE
    fccb  c1         POP BC
    fccc  e1         POP HL
    fccd  c9         RET
    

CLEAR_SCREEN:
    fcce  cd d5 fc   CALL DO_CLEAR_SCREEN (fcd5); Clear screen

HOME_SCREEN:
    fcd1  21 00 e8   LXI HL, e800               ; Move cursor to the top left position
    fcd5  c4         RET


DO_CLEAR_SCREEN:
    fcd5  21 00 e8   LXI HL, e800               ; Load screen memory start address

CLS_LOOP:
    fcd8  36 20      MVI M, 20                  ; Clear screen with spaces
    fcda  23         INX HL
    fcdb  7c         MOV A, H
    fcdc  fe f0      CPI f0                     ; Repeat until 0xf000 address is reached
    fcde  c8         RZ
    fcdf  c3 d8 fc   JMP CLS_LOOP (fcd8)


MOVE_CUR_RIGHT:
    fce2  23         INX HL                     ; Advance cursor position

    fce3  7c         MOV A, H                   ; Check if we reached the end of the screen
    fce4  fe ef      CPI ef
    fce6  c0         RNZ

    fce7  ca d1 fc   JZ HOME_SCREEN (fcd1)      ; If reached - move to the topleft position

MOVE_CUR_LEFT:
    fcea  2b         DCX HL                     ; Move cursor left 1 position

    fceb  7c         MOV A, H                   ; Check if it has moved outside of the screen
    fcec  fe e7      CPI e7
    fcee  c0         RNZ

    fcef  21 ff ee   LXI HL, eeff               ; If reached - move to the bottom right position
    fcf2  c9         RET


MOVE_CUR_DOWN:
    fcf3  11 40 00   LXI DE, 0040               ; Just advance cursor pointer by 0x40 bytes (64 symbols)
    fcf6  19         DAD DE
    fcf7  7c         MOV A, H

    fcf8  fe ef      CPI ef                     ; Check if we are still within video memory range
    fcfa  c0         RNZ

    fcfb  26 e8      MVI H, e8                  ; Move the cursor to the topmost line
    fcfd  c9         RET


MOVE_CUR_UP:
    fcfe  11 c0 ff   LXI DE, ffc0               ; Subtract 0x40 from the cursor position
    fd01  19         DAD DE

    fd02  7c         MOV A, H                   ; Check if reached end of the screen
    fd03  fe e7      CPI e7
    fd05  c0         RNZ

    fd06  11 00 08   LXI DE, 0800               ; Move cursor to the bottom line
    fd09  19         DAD DE
    fd0a  c9         RET

CARRIAGE_RETURN:
    fd0b  23         INX HL                     ; Advance cursor position until it reaches the new line
    fd0c  7d         MOV A, L
    fd0d  e6 3f      ANI 3f
    fd0f  c2 0b fd   JNZ CARRIAGE_RETURN (fd0b)

    fd12  7c         MOV A, H                   ; Check that we reached the end of screen
    fd13  fe ef      CPI ef
    fd15  ca a3 fc   JZ DO_SCROLL (fca3)
    fd18  c9         RET

SCROLL_1_LINE:
    fd19  21 40 e8   LXI HL, e840               ; Source address
    fd1c  11 00 e8   LXI DE, e800               ; Destination address

SCROLL_LOOP:
    fd1f  7e         MOV A, M                   ; Copy one symbol
    fd20  12         STAX DE

    fd21  13         INX DE                     ; Advance pointers
    fd22  23         INX HL

    fd23  7c         MOV A, H                   ; Repeat until reached the end of screen
    fd24  fe ef      CPI ef
    fd26  c2 1f fd   JNZ SCROLL_LOOP (fd1f)

    fd29  21 c0 ee   LXI HL, eec0               ; Fill the last line with spaces
    fd2c  3e 20      MVI A, 20

SCROLL_LOOP_2:
    fd2e  77         MOV M, A
    fd2f  2c         INR L
    fd30  c2 2e fd   JNZ SCROLL_LOOP_2 (fd2e)

    fd33  c9         RET

MOVE_CUR_DIRECT_B1:
    fd34  79         MOV A, C                   ; Expect 'Y' as a second key of the sequence
    fd35  fe 59      CPI 59
    fd37  c2 6f fc   JNZ MOVE_CUR_DIRECT_RESET (fc6f)

    fd3a  cd d1 fc   CALL HOME_SCREEN (fcd1)        

    fd3d  3e 02      MVI A, 02                  ; Prepare for getting cursor coordinates
    fd3f  c3 70 fc   JMP MOVE_CUR_DIRECT_STORE (fc70)

MOVE_CUR_DIRECT_B2:
    fd42  79         MOV A, C                   ; Get the position in C (based on 0x20 value)
    fd43  de 20      SBI 20
    fd45  4f         MOV C, A

MOVE_CUR_DIRECT_L2:
    fd46  0d         DCR C                      ; Move cursor down by C positions

    fd47  3e 04      MVI A, 04
    fd49  fa 70 fc   JN MOVE_CUR_DIRECT_STORE (fc70)

    fd4c  cd f3 fc   CALL MOVE_CUR_DOWN (fcf3)
    fd4f  c3 46 fd   JMP MOVE_CUR_DIRECT_L2 (fd46)


MOVE_CUR_DIRECT:
    fd52  3e 01      MVI A, 01                  ; Set direct movement flag
    fd54  c3 70 fc   JMP MOVE_CUR_DIRECT_STORE (fc70)


; Wait for the keyboard input
;
; This function waits for the keyboard input. The function also handles when the key
; is pressed for some time. In this case repeat mechanism is working, and the key is
; triggered again, until it is released.
;
; Input symbol is in A register
KBD_INPUT:
    fd57  e5         PUSH HL
    fd58  d5         PUSH DE
    fd59  c5         PUSH BC

    fd5a  3e 7f      MVI A, 7f                  ; Reset repeat counter (if the button is _still_ pressed
    fd5c  32 f3 f7   STA f7f3                   ; let's wait some time until it is triggered again)

KBD_INPUT_LOOP:
    fd5f  cd 9a fd   CALL SCAN_KBD_STABLE (fd9a)

    fd62  fe ff      CPI ff                     ; Check if something was pressed
    fd64  c2 74 fd   JNZ KBD_INPUT_PRESS (fd74)

    fd67  3e 00      MVI A, 00                  ; Nothing is pressed - rReset the repeat counter
    fd69  32 f3 f7   STA f7f3
    fd6c  3e 00      MVI A, 00                  ; ... and the pressed flag
    fd6e  32 f4 f7   STA f7f4

    fd71  c3 5f fd   JMP KBD_INPUT_LOOP (fd5f)  ; Wait until something is pressed

KBD_INPUT_PRESS:
    fd74  57         MOV D, A

    fd75  3a f4 f7   LDA f7f4                   ; If it is pressed for the first time - trigger
    fd78  a7         ANA A                      ; the button press
    fd79  c2 92 fd   JNZ KBD_INPUT_TRIGGER (fd92)

    fd7c  3a f3 f7   LDA f7f3                   ; If it is pressed for a while - trigger the button 
    fd7f  a7         ANA A                      ; press (repeat)
    fd80  ca 92 fd   JZ KBD_INPUT_TRIGGER (fd92)

    fd83  3a f3 f7   LDA f7f3                   ; Decrease the repeat wait timer
    fd86  3d         DCR A
    fd87  32 f3 f7   STA f7f3

    fd8a  c2 5f fd   JNZ fd5f

    fd8d  3e 01      MVI A, 01                  ; Raise the pressed flag
    fd8f  32 f4 f7   STA f7f4

KBD_INPUT_TRIGGER:
    fd92  cd 4b fe   CALL BEEP (fe4b)

    fd95  7a         MOV A, D
    fd96  c1         POP BC
    fd97  d1         POP DE
    fd98  e1         POP HL
    fd99  c9         RET



; Detect a stable keyboard press
;
; Perform a keyboard matrix scan, and ensure that scan code is stable for some time.
SCAN_KBD_STABLE:
    fd9a  c5         PUSH BC

SCAN_KBD_LOOP:
    fd9b  cd ae fd   CALL SCAN_KBD (fdae)       ; Scan the keyboard matrix, put result to B
    fd9e  47         MOV B, A


    fd9f  0e ff      MVI C, ff                  ; Perform a small delay

SCAN_KBD_DELAY_LOOP:
    fda1  0d         DCR C
    fda2  c2 a1 fd   JNZ SCAN_KBD_DELAY_LOOP (fda1)

    fda5  cd ae fd   CALL SCAN_KBD (fdae)       ; Scan the matrix again, until value stabilize
    fda8  b8         CMP B
    fda9  c2 9b fd   JNZ SCAN_KBD_LOOP (fd9b)

    fdac  c1         POP BC                     ; Return the scan code
    fdad  c9         RET


; Scan keyboard matrix
;
; This function scans keyboard matrix, and return the scan code, if a button is pressed,
; or 0xff if nothing is pressed
;
; The function sequentally selects one column in the keyboard matrix, by setting the corresponding
; bit in the keyboard 8255 port A. The column scanning is performed by reading the port B. If a bit
; is 0, then the button is pressed.
;
; First stage of the algorithm is to detect the scan code (register B) which is essentially an index
; of the pressed button, counting columns left to right, and buttons in the column from top to bottom.
;
; If a button is pressed, then the algorithm starts conversion the scan code (in the 0x00-0x37 range) 
; to a char code. For most of the chars simple addition a 0x30 is enough. Some characters require
; additional character codes remapping.
;
; Scan code to char code translation table
;      |   0xfe   |   0xfd   |   0xfb   |   0xf7   |   0xef   |   0xdf   |   0xbf   |     0x7f     |
; 0xfe | 0x30 '0' | 0x37 '7' | 0x2e '.' | 0x45 'E' | 0x4c 'L' | 0x53 'S' | 0x5a 'Z' | 0x18 right   |
; 0xfd | 0x31 '1' | 0x38 '8' | 0x2f '/' | 0x46 'F' | 0x4d 'M' | 0x54 'T' | 0x5b '[' | 0x08 left    |
; 0xfb | 0x32 '2' | 0x39 '9' | 0x40 '@' | 0x47 'G' | 0x4e 'N' | 0x55 'U' | 0x5c '\' | 0x19 up      |
; 0xf7 | 0x33 '3' | 0x3a ':' | 0x41 'A' | 0x48 'H' | 0x4f 'O' | 0x56 'V' | 0x5d ']' | 0x1a down    |
; 0xef | 0x34 '4' | 0x3b ';' | 0x42 'B' | 0x49 'I' | 0x50 'P' | 0x57 'W' | 0x5e '^' | 0x0d enter   |
; 0xdf | 0x35 '5' | 0x2c ',' | 0x43 'C' | 0x4a 'J' | 0x51 'Q' | 0x58 'X' | 0x5f '_' | 0x1f bkspace |
; 0xbf | 0x36 '6' | 0x2d '-' | 0x44 'D' | 0x4b 'K' | 0x52 'R' | 0x59 'Y' | 0x20 ' ' | 0x0c home    |
; 
; The final stage of the algorithm is to apply alteration keys (by reading the port C):
; - RUS key - alters letters in the 0x40-0x5f range to russian letters in the 0x60-0x7f range
; - Symbol - alters numeric key and some symbol keys in order to enter another set of symbols (this
;   is an analog of a Shift key on the modern computers, but works only for numeric and symbol keys.
;   Note, that there is no upper and lower case of letters on this computer)
; - Ctrl - alters some keys to produce codes in 0x00 - 0x1f range. This range contains control codes
;   (e.g. cursor movements, as well as some graphics)
SCAN_KBD:
    fdae  c5         PUSH BC
    fdaf  d5         PUSH DE
    fdb0  e5         PUSH HL

    fdb1  06 00      MVI B, 00                  ; Resulting scan code (button number)
    fdb3  0e fe      MVI C, fe                  ; Column mask
    fdb5  16 08      MVI D, 08                  ; Columns counter

SCAN_KBD_COLUMN:
    fdb7  79         MOV A, C                   ; Out the column mask to port A
    fdb8  d3 07      OUT 07
    fdba  07         RLC                        ; Shift the mask left, prepare for the next column
    fdbb  4f         MOV C, A

    fdbc  db 06      IN 06                      ; Input the column state through port B

    fdbe  e6 7f      ANI 7f                     ; Check if any key is pressed in this column
    fdc0  fe 7f      CPI 7f
    fdc2  c2 df fd   JNZ SCAN_KBP_PRESSED (fddf)

    fdc5  78         MOV A, B                   ; Advance scan code by 7
    fdc6  c6 07      ADI 07
    fdc8  47         MOV B, A

    fdc9  15         DCR D                      ; Repeat for the next scan column
    fdca  c2 b7 fd   JNZ SCAN_KBD_COLUMN (fdb7)

    fdcd  db 06      IN 06                      ; It is unclear what shall be connected to the Port B.7
    fdcf  e6 80      ANI 80                 
    fdd1  ca d9 fd   JZ fdd9                    ; We should not expect anything there

    fdd4  3e fe      MVI A, fe                  ; But if something is connected, then return 0xfe as a
    fdd6  c3 db fd   JMP SCAN_KBD_EXIT (fddb)   ; scan code

SCAN_KBD_NOTHING:
    fdd9  3e ff      MVI A, ff                  ; Returning 0xff means no button is pressed

SCAN_KBD_EXIT:
    fddb  e1         POP HL                     ; Wrap up and exit
    fddc  d1         POP DE
    fddd  c1         POP BC
    fdde  c9         RET

SCAN_KBP_PRESSED:
    fddf  1f         RAR                        ; Count scan code in B
    fde0  d2 e7 fd   JNC SCAN_KBP_CONVERT (fde7)
    fde3  04         INR B
    fde4  c3 df fd   JMP SCAN_KBP_PRESSED (fddf)


SCAN_KBP_CONVERT:                               ; Convert the scan code into key code
    fde7  78         MOV A, B               
    fde8  fe 30      CPI 30                     ; Check if arrows, space, or other special button 
    fdea  d2 ff fd   JNC SCAN_KBP_SPECIAL (fdff); is pressed (button number >= 48)

    fded  c6 30      ADI 30                     ; RAW scan codes start from 0. Renumber to start from 0x30
    fdef  fe 3c      CPI 3c                     ; Process first 12 keys (0-9, :, ;) returned as is (0x30, 0x31...)
    fdf1  da fb fd   JC SCAN_KBP_CONVERT_1 (fdfb)

    fdf4  fe 40      CPI 40                     ; Scan codes over 0x40 also returned as is
    fdf6  d2 fb fd   JNC SCAN_KBP_CONVERT_1 (fdfb)

    fdf9  e6 2f      ANI 2f                     ; Scan codes between 0x3c and 0x3f corrected to 0x2c-0x2f

SCAN_KBP_CONVERT_1:
    fdfb  4f         MOV C, A
    fdfc  c3 0c fe   JMP SCAN_KBD_MODS (fe0c)

SCAN_KBP_SPECIAL:
    fdff  21 43 fe   LXI HL, SPECIAL_KEYS (fe43); Use table at 0xfe43 to convert scan code
    fe02  d6 30      SUI 30                     ; into a symbol (works for buttons with scan code
    fe04  4f         MOV C, A                   ; over 0x30 - spaces, arrows, home, enter, etc)
    fe05  06 00      MVI B, 00
    fe07  09         DAD BC
    fe08  7e         MOV A, M
    fe09  c3 db fd   JMP SCAN_KBD_EXIT (fddb)


SCAN_KBD_MODS:
    fe0c  db 05      IN 05                      ; Read key modificators in port C
    fe0e  e6 07      ANI 07
    fe10  fe 07      CPI 07
    fe12  ca 3f fe   JZ SCAN_KBD_NORMAL (fe3f)  ; Go to exit if no modificators pressed

    fe15  1f         RAR                        ; Get the Ctrl Symbol key state
    fe16  1f         RAR
    fe17  d2 24 fe   JNC SCAN_CTRL_KEYS (fe24)  ; Process if necessary

    fe1a  1f         RAR                        ; Get the Special Symbol key state
    fe1b  d2 2a fe   JNC SCAN_SYMB_KEYS (fe2a)  ; Process if necessary
    
    fe1e  79         MOV A, C                   ; We are here if RUS key is pressed
    fe1f  f6 20      ORI 20                     ; Just correct the key code, and exit
    fe21  c3 db fd   JMP SCAN_KBD_EXIT (fddb)   ; (Works for key codes >= 0x40, which are letters)

SCAN_CTRL_KEYS:
    fe24  79         MOV A, C                   ; Just convert the key code to 0x00-0x1f range
    fe25  e6 1f      ANI 1f
    fe27  c3 db fd   JMP SCAN_KBD_EXIT (fddb)

SCAN_SYMB_KEYS:
    fe2a  79         MOV A, C                   ; Letters (scan code >= 0x40) remain unchanged
    fe2b  fe 40      CPI 40
    fe2d  d2 db fd   JNC SCAN_KBD_EXIT (fddb)

    fe30  fe 30      CPI 30                     ; Key codes 0x30-0x3f changed to 0x20-0x2f respectively
    fe32  d2 3a fe   JNC SCAN_SYMB_KEYS_1 (fe3a)

    fe35  f6 10      ORI 10
    fe37  c3 db fd   JMP SCAN_KBD_EXIT (fddb)

SCAN_SYMB_KEYS_1:
    fe3a  e6 2f      ANI 2f                     ; Key codes 0x30-0x3f changed to 0x20-0x2f respectively
    fe3c  c3 db fd   JMP SCAN_KBD_EXIT (fddb)

SCAN_KBD_NORMAL:
    fe3f  79         MOV A, C
    fe40  c3 db fd   JMP SCAN_KBD_EXIT (fddb)

SPECIAL_KEYS:
    ; Table that converts special keys scan codes into key codes
    fe43  20         db 20                      ; Space
    fe44  18         db 18                      ; Right arrow
    fe45  08         db 08                      ; Left arrow
    fe46  19         db 19                      ; Up
    fe47  1a         db 1a                      ; Down
    fe48  0d         db 0d                      ; Enter
    fe49  1f         db 1f                      ; Clear screen
    fe4a  0c         db 0c                      ; Home


; Make a short beep through the tape recorder port
BEEP:
    fe4b  0e bf      MVI C, bf                  ; Beep duration

BEEP_LOOP:
    fe4d  cd 5c fe   CALL fe5c
    fe50  d3 a1      OUT a1                     ; Out positive pulse
    fe52  2f         CMA

    fe53  cd 5c fe   CALL fe5c
    fe56  d3 a1      OUT a1                     ; Out negative pulse
    fe58  0d         DCR C
    fe59  c2 4d fe   JNZ fe4d                   ; Repeat

BEEP_DELAY:
    fe5c  06 2f      MVI B, 2f          
    fe5e  05         DCR B
    fe5f  c2 5e fe   JNZ fe5e
    fe62  c9         RET

; UNUSED FUNCTION
;
; Wait for Bit 7 on keyboard Port B
;
; It is unclear what is connected to this port. Schematic shows this pin floating.
WAIT_B7_PORTB:
    fe63  db 06      IN 06                      ; Wait until MSB is set on keyboard Port B
    fe65  e6 80      ANI A, 80
    fe67  c2 63 fe   JNZ WAIT_B7_PORTB (fe63)
    fe6a  c9         RET


IS_BUTTON_PRESSED:
    fe6b  af         XRA A                      ; Select all scan column at once
    fe6c  d3 07      OUT 07

    fe6e  db 06      IN 06                      ; Get button state
    fe70  2f         CMA
    fe71  e6 7f      ANI 7f
    fe73  c8         RZ                         ; Return A=00 if no buttons pressed

    fe74  f6 ff      ORI ff                     ; Return A=ff if a button is pressed
    fe76  c9         RET

;
????:
    fe77  2a d1 f7   LHLD f7d1
    fe7a  c9         RET
    
?????:
    fe7b  22 d1 f7   SHLD f7d1
    fe7e  c9         RET

PROMPT_STR:
    fe7f 0d 0a 18    db '\r\n', 0x18            ; Move to the next line, then step right
    fe82 3d 3e 00    db "=>", 0x00


TAB_STR:
    fe85 0d 0a 18    db "\r\n", 0x18
    fe88 18 18 18 00 db 0x18, 0x18, 0x18, 0x00


REGISTERS_STR:
    fe8c 0d 0a 20    db "\r\n", " "
    fe8f 50 43 2d    db "PC-"
    fe92 0d 0a 20    db "\r\n", " "
    fe95 48 4c 2d    db "HL-"
    fe98 0d 0a 20    db "\r\n", " "
    fe9b 42 43 2d    db "BC-"
    fe9e 0d 0a 20    db "\r\n", " "
    fea1 44 45 2d    db "DE-"
    fea4 0d 0a 20    db "\r\n", " "
    fea7 53 50 2d    db "SP-"
    feaa 0d 0a 20    db "\r\n", " "
    fead 41 46 2d    db "AF-"
    feb0 19 19 19    db 19, 19, 19
    feb3 19 19 19 00 db 19, 19, 19, 0


BACKSPACE_STR:
    feb7  08 20 08 00   db 0x08, ' ', 0x08, 0x00    ; Clear symbol left to the cursor, move cursor left

; Breakpoint handler
;
; The handler is executed as a result of G command, that replaces an instruction at desired 
; address to RST 6, which eventually jumps here. The handler stores user program registers
; to f7b4-f7bf memory cells, so that they may be reviewed/changed with X command. Finally,
; the breakpoint restores original instruction byte under the breakpoint address, and jumps to
; the command main loop.
;
; See Command G description for more information
BREAKPOINT:
    febb  22 b6 f7   SHLD f7b6                      ; Store HL at f7b6

    febe  f5         PUSH PSW                       ; Store AF at f7be
    febf  e1         POP HL
    fec0  22 be f7   SHLD f7be

    fec3  e1         POP HL                         ; Store return address-1 to f7b4
    fec4  2b         DCX HL
    fec5  22 b4 f7   SHLD f7b4

    fec8  21 00 00   LXI HL, 0000                   ; Move SP to HL
    fecb  39         DAD SP

    fecc  31 be f7   LXI SP, f7be                   ; Store BC, DE, and previous SP f7b8, f7bb, and f7bd
    fecf  e5         PUSH HL
    fed0  d5         PUSH DE
    fed1  c5         PUSH BC

    fed2  2a b4 f7   LHLD f7b4                      ; Print previous PC
    fed5  31 af f7   LXI SP, f7af
    fed8  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)

    fedb  eb         XCHG                           ; Check if the PC address really matches breakpoint
    fedc  2a c3 f7   LHLD f7c3                      ; address previously stored in f7c3
    fedf  cd 8d f9   CALL CMP_HL_DE (f98d)
    fee2  c2 6c f8   JNZ ENTER_NEXT_COMMAND (f86c)

    fee5  3a c5 f7   LDA f7c5                       ; Restore the original instruction under the breakpoint
    fee8  77         MOV M, A                       ; address

    fee9  c3 6c f8   JMP ENTER_NEXT_COMMAND (f86c)  ; Jump to the main command loop


; Command X - Dump CPU registers
;
; Print 6 register pairs stored at addresses f7b4-f7bf (in the order of PC, HL, BC, DE, SP, AF).
; Allow the User to enter a new register value.
COMMAND_X:
    feec  21 8c fe   LXI HL, REGISTERS_STR (fe8c)
    feef  cd 1f f9   CALL PRINT_STR (f91f)

    fef2  21 b4 f7   LXI HL, f7b4               ; Display 6 register pairs starting 0xf7b4
    fef5  06 06      MVI B, 06

COMMAND_X_LOOP:
    fef7  5e         MOV E, M                   ; Load register pair to DE
    fef8  23         INX HL
    fef9  56         MOV D, M

    fefa  c5         PUSH BC
    fefb  e5         PUSH HL

    fefc  eb         XCHG                       ; Print register pair
    fefd  cd 51 fb   CALL PRINT_HEX_ADDR (fb51)

    ff00  cd eb f8   CALL INPUT_LINE (f8eb)
    ff03  d2 0f ff   JNC COMMAND_X_NO_INPUT (ff0f)

    ff06  cd 57 f9   CALL PARSE_ADDR (f957)     ; Enter new value for the register pair

    ff09  d1         POP DE                     ; Restore address in HL
    ff0a  d5         PUSH DE
    ff0b  eb         XCHG

    ff0c  72         MOV M, D                   ; Store entered value
    ff0d  2b         DCX HL
    ff0e  73         MOV M, E

COMMAND_X_NO_INPUT:
    ff0f  e1         POP HL                     ; Do this for all 6 register pairs
    ff10  c1         POP BC
    ff11  05         DCR B
    ff12  23         INX HL
    ff13  c2 f7 fe   JNZ COMMAND_X_LOOP (fef7)

    ff16  c9         RET


COMMAND_HANDLER_CONT:
    ff17  fe 42      CPI 42                     ; Handle command 'B'
    ff19  ca f3 ff   JZ COMMAND_B (fff3)

    ff1c  fe 57      CPI 57                     ; Handle command 'W'
    ff1e  ca 00 c0   JZ c000                    ; Jump directly to 0xc000

    ff21  fe 56      CPI 56                     ; Handle command 'V'
    ff23  ca 29 ff   JZ COMMAND_V (ff29)

    ff26  c3 7e ff   JMP COMMAND_HANDLER_CONT_2 (ff7e)


; Command V - Measure the tape constant
;
COMMAND_V:
    ff29  f3         DI

    ff2a  21 00 00   LXI HL, 0000               ; The counter
    ff2d  01 7a 01   LXI BC, 017a               ; B=01 - input bitmask, C=7a - number of pulses to measure
    
    ff30  db a1      IN a1                      ; Input the bit
    ff32  a0         ANA B
    ff33  5f         MOV E, A

COMMAND_V_LOOP_1:
    ff34  db a1      IN a1                      ; Wait until the bit changes
    ff36  a0         ANA B
    ff37  bb         CMP E

    ff38  ca 34 ff   JZ COMMAND_V_LOOP_1 (ff34)

    ff3b  5f         MOV E, A                   ; Temporary store the value at E register

COMMAND_V_LOOP_2:
    ff3c  db a1      IN a1                      ; Wait until the pulse ends
    ff3e  a0         ANA B
    ff3f  23         INX HL                     ; Measure pulse duration in HL
    ff40  bb         CMP E
    ff41  ca 3c ff   JZ COMMAND_V_LOOP_2 (ff3c)

    ff44  5f         MOV E, A                   
    ff45  0d         DCR C                      ; Count pulses in C
    ff46  c2 3c ff   JNZ COMMAND_V_LOOP_2 (ff3c)

    ff49  29         DAD HL                     ; Some constant calculations
    ff4a  29         DAD HL
    ff4b  7c         MOV A, H
    ff4c  b7         ORA A                      ; If the measured value is too big - just save it
    ff4d  fa 5e ff   JN COMMAND_V_1 (ff5e)

    ff50  2f         CMA                        ; Another portion of calculations
    ff51  e6 20      ANI 20
    ff53  0f         RRC
    ff54  0f         RRC
    ff55  0f         RRC
    ff56  47         MOV B, A

    ff57  0f         RRC
    ff58  1f         RAR
    ff59  80         ADD B
    ff5a  3c         INR A
    ff5b  47         MOV B, A
    ff5c  7c         MOV A, H
    ff5d  90         SUB B

COMMAND_V_1:
    ff5e  32 cf f7   STA f7cf                   ; Store measured value

    ff61  fb         EI                         ; Enable interrups and print the value
    ff62  cd b4 f9   CALL PRINT_HEX_BYTE_SPACE (f9b4)

    ff65  c3 6c f8   JMP ENTER_NEXT_COMMAND (f86c)


IN_BYTE_INTRO:
    ff69  f3         DI
    ff6a  e5         PUSH HL
    ff6b  c5         PUSH BC
    ff6c  d5         PUSH DE
    ff6d  c3 74 fb   JMP DO_IN_BYTE (fb74)

; Restoring registers and interrupt after outputing a byte to the tape
OUT_BYTE_OUTRO:
    ff70  d1         POP DE
    ff71  c1         POP BC
    ff72  e1         POP HL
    ff73  fb         EI
    ff74  c3 2d fc   JMP OUT_BYTE_EXIT (fc2d)

; A preparation for outputing a byte to the tape - disable interrupts and save registers
OUT_BYTE_INTRO:
    ff77  f3         DI                         ; Disable interrupts to avoid tape data corruption

    ff78  e5         PUSH HL
    ff79  c5         PUSH BC
    ff7a  d5         PUSH DE
    ff7b  c3 f1 fb   JMP DO_OUT_BYTE (fbf1)


COMMAND_HANDLER_CONT_2:
    ff7e  fe 4b      CPI 4b                     ; Handle command 'K'
    ff80  ca 86 ff   JZ COMMAND_K (ff86)

    ff83  c3 6c f8   JMP ENTER_NEXT_COMMAND (f86c)  ; Invalid command


; Calculate CRC for a range
;
; Arguments:
; - start address (HL)
; - end address (DE)
COMMAND_K:
    ff86  e5         PUSH HL                    ; Calculate the CRC on HL-DE range. Result in BC
    ff87  cd f6 fa   CALL CALC_CRC (faf6)
    ff8a  e1         POP HL

    ff8b  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) ; Print the start address

    ff8e  eb         XCHG                       ; Print the end address
    ff8f  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) 

    ff92  eb         XCHG
    ff93  e5         PUSH HL

    ff94  60         MOV H, B                   ; Print the CRC
    ff95  69         MOV L, C
    ff96  cd 51 fb   CALL PRINT_HEX_ADDR (fb51) 

    ff99  e1         POP HL
    ff9a  c3 6c f8   JMP ENTER_NEXT_COMMAND (f86c)


; It is supposed that Monitor 0 ROM (0x0000-0x3fff) ROM is installed simultaneously 
; with the Monitor F ROM (0xf800-0xffff). In this case Monitor 0 is responsible for
; time interrupts, and stores time values at 0xc3fd-0xc3ff
;
; The alternative configuration does not suppose using Monitor 0 ROM. Instead it uses
; only Monitor F, which is now responsible for time interrupt handling.
; 
; The interrupt mechanism remains the same - timer clock triggers an interrupt, the CPU
; reads 0xff from the data bus, which corresponds to RST 7 instruction. Since Monitor 0 
; may be switched off, time interrupt require a RAM at 0x0000-0x003f addresses, with a 
; certain JMP instructions somehow loaded into these addresses:

; RST0:
; 0000 f3        DI
; 0001 c3 00 f8  JMP f800
;
; RST7:
; 0038 c3 c1 ff  JMP ffc1
;
; The implementation of the time interrupt is pretty much identical to one in the Monitor 0
; It uses 0xf6fd, 0xf6fe, and 0xf6ff variables to store seconds, minutes, and hours respectively.
;
; Additionally it displays current time on the CPU module LCD.
TIME_INTERRUPT:
    ffc1  f3         DI                         ; Save registers
    ffc2  f5         PUSH PSW
    ffc3  c5         PUSH BC
    ffc4  d5         PUSH DE
    ffc5  e5         PUSH HL

    ffc6  21 f0 ff   LXI HL, TIME_LIMITS (fff0) ; Advance time values at 0xf6fd-0xf6ff
    ffc9  11 fd f6   LXI DE, f6fd
    ffcc  06 03      MVI B, 03                  ; 3 values to advance

TIME_INTERRUPT_LOOP:
    ffce  1a         LDAX DE                    ; Advance particular value
    ffcf  3c         INR A
    ffd0  27         DAA
    ffd1  12         STAX DE

    ffd2  be         CMP M                      ; Compare it with the limit
    ffd3  c2 de ff   JNZ TIME_INTERRUPT_EXIT (ffde)

    ffd6  af         XRA A                      ; If limit reached - zero the current value, and
    ffd7  12         STAX DE                    ; advance the second one
    ffd8  23         INX HL
    ffd9  13         INX DE
    ffda  05         DCR B
    ffdb  c2 ce ff   JNZ TIME_INTERRUPT_LOOP (ffce)

TIME_INTERRUPT_EXIT:
    ffde  2a fe f6   LHLD f6fe                  ; Display current time at CPU module LCD
    ffe1  3a fd f6   LDA f6fd
    ffe4  32 00 90   STA 9000
    ffe7  22 01 90   SHLD 9001

    ffea  e1         POP HL                     ; Restore registers and exit
    ffeb  d1         POP DE
    ffec  c1         POP BC
    ffed  f1         POP PSW
    ffee  fb         EI
    ffef  c9         RET

TIME_LIMITS:
    fff0  60 60 24   db 60, 60, 24              ; Maximum values for seconds, minutes, and hours


; Command B - display time on LCD display
;
; This is an analog of the Monitor 0 function to display current time. 
; It displays current time on LCD display of the CPU module.
;
; It is supposed that time interrupts are still connected to the CPU, and handled
; by the CPU module.
COMMAND_B:
    fff3  2a fe c3   LHLD c3fe                  ; Load time information (updated by CPU module)
    fff6  3a fd c3   LDA c3fd

    fff9  ef         RST 5                      ; Display it on the LCD
    fffa  df         RST 3                      ; Delay 1s

    fffb  c3 6c f8   JMP ENTER_NEXT_COMMAND (f86c)
; 

; Variables:
; 0x7600    - current cursor address (points to the video RAM)
; 0x7602    - current cursor position (high byte - X, and low byte as Y coordinate)
; 0x7604    - Esc-Y escape sequence byte number
; 0x7605    - Key is not pressed flag (0xff - no keys pressed, 0x00 - a key is pressed)
; 0x7606    - Cyrilic layout enabled
;
; 0x7609    - Currently pressed key (used for autorepeat)
; 0x760a    - Autorepeat timer (cycles till the next trigger)
; 0x760b    - Autorepeat flag (value == 0x00 - first trigger of the autorepeat, other values - subsequent calls)
; 0x7614    - User program PC
; 0x7616    - User program HL
; 0x7618    - User program BC
; 0x761a    - User program DE
; 0x761c    - User program SP
; 0x761e    - User program AF
; 0x7623    - Breakpoint address
; 0x7625    - Original opcode at the breakpoint address
; 0x7626    - JMP opcode (used to jump to the user program)
; 0x7627    - ????? arg1
;
; 0x762f    - ???? tape delays
; 0x7631    - upper limit of the memory available for user programs
; 0x7633    - line buffer (???? bytes)
; 0x7600 - 0x765f - monitor variables
; ??????
; 76cf - stack top
; 0x76d0 - Video RAM (0x924 bytes)

VECTORS:
    f800  c3 36 f8   JMP START (f836)
    f803  c3 63 fe   JMP KBD_INPUT (fe63)
    f806  c3 98 fb   JMP fb98
    f809  c3 ba fc   JMP PUT_CHAR (fcba)
    f80c  c3 46 fc   JMP fc46
    f80f  c3 ba fc   JMP PUT_CHAR (fcba)
    f812  c3 01 fe   JMP IS_BUTTON_PRESSED (fe01)
    f815  c3 a5 fc   JMP PRINT_HEX_BYTE (fca5)
    f818  c3 22 f9   JMP PRINT_STR (f922)
    f81b  c3 72 fe   JMP KBD_SCAN (fe72)
    f81e  c3 7b fa   JMP fa7b
    f821  c3 7f fa   JMP fa7f
    f824  c3 b6 fa   JMP fab6
    f827  c3 49 fb   JMP fb49
    f82a  c3 16 fb   JMP fb16
    f82d  c3 ce fa   JMP INIT_VIDEO (face)
    f830  c3 52 ff   JMP ff52
    f833  c3 56 ff   JMP ff56

START:
    f836  3e 8a      MVI A, 8a                  ; Initialize keyboard port: Port A - output, Port B - input,
    f838  32 03 80   STA KBD_CTRL_PORT (8003)   ; Port C (upper) - input, Port C (lower) - output

    f83b  31 cf 76   LXI SP, STACK_TOP (76cf)   ; Initialize stack

    f83e  cd ce fa   CALL INIT_VIDEO (face)     ; Initialize video controller and DMA controller

    f841  21 00 76   LXI HL, 7600               ; Clear the 0x7600 - 0x765f Monitor variables range
    f844  11 5f 76   LXI DE, 765f
    f847  0e 00      MVI C, 00
    f849  cd ed f9   CALL MEMSET (f9ed)

    f84c  21 cf 76   LXI HL, STACK_TOP (76cf)   ; ???? User SP????
    f84f  22 1c 76   SHLD 761c

    f852  21 5a ff   LXI HL, ff5a               ; Print the hello line
    f855  cd 22 f9   CALL PRINT_STR (f922)

    f858  cd ce fa   CALL INIT_VIDEO (face)     ; Reinit the video ???

    f85b  21 ff 75   LXI HL, 75ff               ; Set the upper memory limit
    f85e  22 31 76   SHLD MEMORY_TOP (7631)

    f861  21 2a 1d   LXI HL, 1d2a               ; Set default values for tape delays
    f864  22 2f 76   SHLD 762f

    f867  3e c3      MVI A, c3                  ; JMP opcode, used to jump to the user program
    f869  32 26 76   STA 7626

MAIN_LOOP:
    f86c  31 cf 76   LXI SP, STACK_TOP (76cf)   ; Restore the stack pointer (just in case)

    f86f  21 66 ff   LXI HL, PROMPT_STR (ff66)
    f872  cd 22 f9   CALL PRINT_STR (f922)

    f875  32 02 80   STA KBD_PORT_C (8002)      ; Clear the Rus LED

    f878  3d         DCR A                      ; Set 0xff to the extra extension port ???
    f879  32 02 a0   STA a002

    f87c  cd ee f8   CALL INPUT_LINE (f8ee)     ; Enter the next command

    f87f  21 6c f8   LXI HL, MAIN_LOOP (f86c)   ; Push the MAIN_LOOP to stack as a return address for all commands
    f882  e5         PUSH HL

    f883  21 33 76   LXI HL, LINE_BUF (7633)    ; Load the first char in the line buf
    f886  7e         MOV A, M

    f887  fe 58      CPI A, 58                  ; Is this 'X' command
    f889  ca d3 ff   JZ COMMAND_X (ffd3)

f88c  fe 55      CPI A, 55
f88e  ca 00 f0   JZ f000
f891  f5         PUSH PSW
f892  cd 2c f9   CALL f92c
f895  2a 2b 76   LHLD 762b
f898  4d         MOV C, L
f899  44         MOV B, H
f89a  2a 29 76   LHLD 7629
f89d  eb         XCHG
f89e  2a 27 76   LHLD 7627
f8a1  f1         POP PSW
f8a2  fe 44      CPI A, 44
f8a4  ca c5 f9   JZ COMMAND_D (f9c5)
f8a7  fe 43      CPI A, 43
f8a9  ca d7 f9   JZ COMMAND_C (f9d7)
f8ac  fe 46      CPI A, 46
f8ae  ca ed f9   JZ COMMAND_F (f9ed)
f8b1  fe 53      CPI A, 53
f8b3  ca f4 f9   JZ f9f4
f8b6  fe 54      CPI A, 54
f8b8  ca ff f9   JZ COMMAND_T (f9ff)
f8bb  fe 4d      CPI A, 4d
f8bd  ca 26 fa   JZ COMMAND_M (fa26)
f8c0  fe 47      CPI A, 47
f8c2  ca 3f fa   JZ COMMAND_G (fa3f)
f8c5  fe 49      CPI A, 49
f8c7  ca 86 fa   JZ fa86
f8ca  fe 4f      CPI A, 4f
f8cc  ca 2d fb   JZ fb2d
f8cf  fe 4c      CPI A, 4c
f8d1  ca 08 fa   JZ COMMAND_L (fa08)
f8d4  fe 52      CPI A, 52
f8d6  ca 68 fa   JZ COMMAND_R (fa68)
f8d9  c3 00 f0   JMP f000

; Process the back space button, clear the symbol left to the cursor
INPUT_LINE_BACKSPACE:
    f8dc  3e 33      MVI A, 33                  ; We cannot go beyond the left border of the line
    f8de  bd         CMP L
    f8df  ca f1 f8   JZ INPUT_LINE_START (f8f1)

    f8e2  e5         PUSH HL
    f8e3  21 9e ff   LXI HL, BACKSPACE_STR (ff9e)   ; Clear a symbol left to the cursor. Move cursor left.
    f8e6  cd 22 f9   CALL PRINT_STR (f922)
    f8e9  e1         POP HL

    f8ea  2b         DCX HL                     ; Decrement line buffer pointer
    f8eb  c3 f3 f8   JMP INPUT_LINE_LOOP (f8f3)

; Input a line into the line buffer at 0x7633
; The function inputs up to 31 chars into the buffer. Back space is supported to clear symbol left to the cursor.
; Line input finishes with EOL (CR) char. 
;
; Return:
; - The function returns the line buffer address in DE. 
; - C flag indicates that the buffer contains at least one char
INPUT_LINE:
    f8ee  21 33 76   LXI HL, LINE_BUF (7633)    ; Load the line buffer address

INPUT_LINE_START:
    f8f1  06 00      MVI B, 00                  ; Reset symbol entered flag

INPUT_LINE_LOOP:
    f8f3  cd 63 fe   CALL KBD_INPUT (fe63)      ; Wait for the next key

    f8f6  fe 08      CPI A, 08                  ; Handle left arrow and backspace keys
    f8f8  ca dc f8   JZ INPUT_LINE_BACKSPACE (f8dc)
    f8fb  fe 7f      CPI A, 7f
    f8fd  ca dc f8   JZ INPUT_LINE_BACKSPACE (f8dc)

    f900  c4 b9 fc   CNZ PUT_CHAR_A (fcb9)      ; Echo the entered char

    f903  77         MOV M, A                   ; Store the char in the buffer as well

    f904  fe 0d      CPI A, 0d                  ; Finalize line input on EOL symbol entered
    f906  ca 1a f9   JZ INPUT_LINE_EOL (f91a)

    f909  fe 2e      CPI A, 2e                  ; '.' (dot) symbol abandon current input, and restart the main loop
    f90b  ca 6c f8   JZ MAIN_LOOP (f86c)

    f90e  06 ff      MVI B, ff                  ; Raise a flag that a symbol is entered

    f910  3e 52      MVI A, 52                  ; Limit line input to 31 char. If more symbols entered - report
    f912  bd         CMP L                      ; an error
    f913  ca ae fa   JZ INPUT_ERROR (faae)

    f916  23         INX HL                     ; Advance line buffer pointer and get ready for the next char
    f917  c3 f3 f8   JMP INPUT_LINE_LOOP (f8f3)

INPUT_LINE_EOL:
    f91a  78         MOV A, B                   ; Check if any symbol was entered. Set C flag if any valuable
    f91b  17         RAL                        ; input is there.

    f91c  11 33 76   LXI DE, LINE_BUF (7633)    ; Return line buffer address in DE
    f91f  06 00      MVI B, 00
    f921  c9         RET



; Print a NULL-terminated string pointed by HL
PRINT_STR:
    f922  7e         MOV A, M                   ; Load the next symbol

    f923  a7         ANA A                      ; Exit on zero char
    f924  c8         RZ

    f925  cd b9 fc   CALL PUT_CHAR_A (fcb9)     ; Print the char

    f928  23         INX HL                     ; Advance to the next char
    f929  c3 22 f9   JMP PRINT_STR (f922)

????:
f92c  21 27 76   LXI HL, 7627
f92f  11 2d 76   LXI DE, 762d
f932  0e 00      MVI C, 00
f934  cd ed f9   CALL MEMSET (f9ed)
f937  11 34 76   LXI DE, 7634
f93a  cd 5a f9   CALL PARSE_ADDR (f95a)
f93d  22 27 76   SHLD 7627
f940  22 29 76   SHLD 7629
f943  d8         RC
f944  3e ff      MVI A, ff
f946  32 2d 76   STA 762d
f949  cd 5a f9   CALL PARSE_ADDR (f95a)
f94c  22 29 76   SHLD 7629
f94f  d8         RC
f950  cd 5a f9   CALL PARSE_ADDR (f95a)
f953  22 2b 76   SHLD 762b
f956  d8         RC
f957  c3 ae fa   JMP INPUT_ERROR (faae)

PARSE_ADDR:
f95a  21 00 00   LXI HL, 0000
????:
f95d  1a         LDAX DE
f95e  13         INX DE
f95f  fe 0d      CPI A, 0d
f961  ca 8e f9   JZ f98e
f964  fe 2c      CPI A, 2c
f966  c8         RZ
f967  fe 20      CPI A, 20
f969  ca 5d f9   JZ f95d
f96c  d6 30      SUI A, 30
f96e  fa ae fa   JM INPUT_ERROR (faae)
f971  fe 0a      CPI A, 0a
f973  fa 82 f9   JM f982
f976  fe 11      CPI A, 11
f978  fa ae fa   JM INPUT_ERROR (faae)
f97b  fe 17      CPI A, 17
f97d  f2 ae fa   JP INPUT_ERROR (faae)
f980  d6 07      SUI A, 07
????:
f982  4f         MOV C, A
f983  29         DAD HL
f984  29         DAD HL
f985  29         DAD HL
f986  29         DAD HL
f987  da ae fa   JC INPUT_ERROR (faae)
f98a  09         DAD BC
f98b  c3 5d f9   JMP f95d
????:
f98e  37         STC
f98f  c9         RET

COMPARE_DE_HL:
f990  7c         MOV A, H
f991  ba         CMP D
f992  c0         RNZ
f993  7d         MOV A, L
f994  bb         CMP E
f995  c9         RET

ADVANCE_HL_WITH_BREAK:
f996  cd a4 f9   CALL f9a4

ADVANCE_HL:
f999  cd 90 f9   CALL COMPARE_DE_HL (f990)
f99c  c2 a2 f9   JNZ f9a2

????:
f99f  33         INX SP
f9a0  33         INX SP
f9a1  c9         RET

????:
f9a2  23         INX HL
f9a3  c9         RET

????:
f9a4  cd 72 fe   CALL KBD_SCAN (fe72)
f9a7  fe 03      CPI A, 03
f9a9  c0         RNZ
f9aa  cd ce fa   CALL INIT_VIDEO (face)
f9ad  c3 ae fa   JMP INPUT_ERROR (faae)

; Print the new line. It also prints a tabulation (4 spaces) so that next information (typically
; an address or some value) is printed after
PRINT_NEW_LINE:
    f9b0  e5         PUSH HL
    f9b1  21 6c ff   LXI HL, TAB_STR (ff6c)
    f9b4  cd 22 f9   CALL PRINT_STR (f922)
    f9b7  e1         POP HL
    f9b8  c9         RET

; Print a byte at [HL] as a 2-digit hex value, then add a space
PRINT_MEMORY_BYTE:
    f9b9  7e         MOV A, M

; Print a 2-digit hex value in A, then print a space
PRINT_HEX_BYTE_SPACE:
    f9ba  c5         PUSH BC                    ; Print the byte
    f9bb  cd a5 fc   CALL PRINT_HEX_BYTE (fca5)

    f9be  3e 20      MVI A, 20                  ; Print the space
    f9c0  cd b9 fc   CALL PUT_CHAR_A (fcb9)

    f9c3  c1         POP BC                     ; Exit
    f9c4  c9         RET


; Command D - Dump memory
; 
; Arguments:
; - start address (HL)
; - end address (DE)
COMMAND_D:
    f9c5  cd 78 fb   CALL PRINT_HEX_ADDR (fb78) ; Print new line, and a memory address

COMMAND_D_LOOP:
    f9c8  cd b9 f9   CALL PRINT_MEMORY_BYTE (f9b9)  ; Print the next byte

    f9cb  cd 96 f9   CALL ADVANCE_HL_WITH_BREAK (f996)  ; Advance HL, exit if reached DE

    f9ce  7d         MOV A, L                   ; Check if we reached end of current line
    f9cf  e6 0f      ANI A, 0f
    f9d1  ca c5 f9   JZ COMMAND_D (f9c5)        ; Get to the new line

    f9d4  c3 c8 f9   JMP COMMAND_D_LOOP (f9c8)  ; Repeat for the next byte in the same line

; Command C - Compare memory ranges
;
; Arguments:
; - Range 1 start address (HL)
; - Range 1 end address (DE)
; - Range 2 start address (BC)
COMMAND_C:
    f9d7  0a         LDAX BC                    ; Compare bytes from both ranges
    f9d8  be         CMP M
    f9d9  ca e6 f9   JZ COMMAND_C_NEXT (f9e6)   ; Advance to the next byte if equal

    f9dc  cd 78 fb   CALL PRINT_HEX_ADDR (fb78) ; Print the address of the unmatched byte

    f9df  cd b9 f9   CALL PRINT_MEMORY_BYTE (f9b9)      ; Print source byte
    f9e2  0a         LDAX BC
    f9e3  cd ba f9   CALL PRINT_HEX_BYTE_SPACE (f9ba)   ; Print unmatched destination byte

COMMAND_C_NEXT:
    f9e6  03         INX BC                     ; Advance BC

    f9e7  cd 96 f9   CALL ADVANCE_HL_WITH_BREAK (f996)  ; Advance HL, exit if reached DE

    f9ea  c3 d7 f9   JMP COMMAND_C (f9d7)       ; Repeat for the next byte


; Command F - fill a memory range with a specified byte.
;
; Command arguments:
; - start address (HL)
; - end address (DE)
; - value to fill with (C)
COMMAND_F:

; Fill memory with a constant
; HL    - start address
; DE    - end address
; C     - byte to fill
MEMSET:
    f9ed  71         MOV M, C                   ; Store the byte
    f9ee  cd 99 f9   CALL ADVANCE_HL (f999)     ; Increment HL until it reaches DE
    f9f1  c3 ed f9   JMP MEMSET (f9ed)

; Search a byte in a memory range
;
; Arguments:
; - start address (HL)
; - end address (DE)
; - Byte to search (C)
COMMAND_S:
    f9f4  79         MOV A, C                   ; Compare the memory byte
    f9f5  be         CMP M

    f9f6  cc 78 fb   CZ PRINT_HEX_ADDR (fb78)   ; If found - print the address

    f9f9  cd 96 f9   CALL ADVANCE_HL_WITH_BREAK (f996)  ; Advance HL, exit if reached DE
    
    f9fc  c3 f4 f9   JMP COMMAND_S (f9f4)       ; Repeat for the next byte

; Copy memory
;
; Arguments:
; - Start address (HL)
; - End address (DE)
; - Target start address (BC)
COMMAND_T:
    f9ff  7e         MOV A, M                   ; Copy single byte
    fa00  02         STAX BC

    fa01  03         INX BC                     ; Advance BC
    fa02  cd 99 f9   CALL ADVANCE_HL (f999)     ; Advance HL, exit when reached DE

    fa05  c3 ff f9   JMP COMMAND_T (f9ff)       ; Repeat for the next byte


; Dump memory in a text representation
;
; Arguments:
; - start address (HL)
; - end address (DE)
COMMAND_L:
    fa08  cd 78 fb   CALL PRINT_HEX_ADDR (fb78) ; Print the starting address

COMMAND_L_LOOP:
    fa0b  7e         MOV A, M                   ; Load the next byte to print

    fa0c  b7         ORA A                      ; Bytes >= 0x80 are printed as dots
    fa0d  fa 15 fa   JM COMMAND_L_DOT (fa15)

    fa10  fe 20      CPI A, 20                  ; Bytes < 0x20 are printed as dots
    fa12  d2 17 fa   JNC COMMAND_L_CHAR (fa17)

COMMAND_L_DOT:
    fa15  3e 2e      MVI A, 2e                  ; Print '.'

COMMAND_L_CHAR:
    fa17  cd b9 fc   CALL PUT_CHAR_A (fcb9)     ; Print the char

    fa1a  cd 96 f9   CALL ADVANCE_HL_WITH_BREAK (f996)  ; Advance HL, exit if reached DE

    fa1d  7d         MOV A, L                   ; Move to the new line every 16 symbols
    fa1e  e6 0f      ANI A, 0f
    fa20  ca 08 fa   JZ COMMAND_L (fa08)

    fa23  c3 0b fa   JMP COMMAND_L_LOOP (fa0b)  ; Repeat for the new symbol


; Command M - edit memory
;
; Arguments:
; - Address to view and edit (HL)
COMMAND_M:
    fa26  cd 78 fb   CALL PRINT_HEX_ADDR (fb78) ; Print the address and current byte value
    fa29  cd b9 f9   CALL PRINT_MEMORY_BYTE (f9b9)

    fa2c  e5         PUSH HL                    ; Input the new value
    fa2d  cd ee f8   CALL INPUT_LINE (f8ee)
    fa30  e1         POP HL

    fa31  d2 3b fa   JNC COMMAND_M_NEXT (fa3b)  ; If no new value entered - move to the next byte

    fa34  e5         PUSH HL                    ; If a value entered - parse it
    fa35  cd 5a f9   CALL PARSE_ADDR (f95a)

    fa38  7d         MOV A, L                   ; Store parsed value to the memory at current address
    fa39  e1         POP HL
    fa3a  77         MOV M, A

COMMAND_M_NEXT:
    fa3b  23         INX HL                     ; Advance to the next address and repeat
    fa3c  c3 26 fa   JMP COMMAND_M (fa26)


; Command G - Run program from specified address
;
; Arguments:
; - Address of the program (HL)
; - (optional) Breakpoint address (DE)
;
; This command runs the user program starting the specified address. Optionally,
; it is possible to set a breakpoint address, where the program execution will break,
; and the control flow returns to the Monitor. When the program is stopped at breakpoint, the
; User can use X Command to display and modify program registers.
;
; If the user specified breakpoint address, the following algorithm applies:
; - Instruction at the breakpoint address is replaced with RST 6 (original byte is
;   saved at 0x7625)
; - Bytes 0x0030-0x0032 (which are executed on RST 6) are replaced with JMP ffa2 (breakpoint handler)
; 
; When a breakpoint happens:
; - All registers (including SP, and PC at the breakpoint address) are stored at 0x7614-0x761f.
; - Instruction at the breakpoint address is restored with the backup at 0x7625
; - Control flow passed to the main command loop
;
; The user may now:
; - Inspect and edit program data
; - Inspect and edit CPU registers stored to 0x7614-0x761f by running Commmand X
; - Run the program from the breakpoint address with Command G. In this case the command handler
;   will run the following extra actions:
;   - Restore CPU registers from 0x7614-0x761f
;   - Run the user program starting from specified address
COMMAND_G:
    fa3f  cd 90 f9   CALL COMPARE_DE_HL (f990)  ; Check if the breakpoint address is specified
    fa42  ca 5a fa   JZ RUN_PROGRAM (fa5a)

    fa45  eb         XCHG                       ; Store breakpoint address at 0x7623 in order to
    fa46  22 23 76   SHLD BREAKPOINT_ADDR (7623); restore original program later

    fa49  7e         MOV A, M                   ; Load byte under break point and store it at 0x7625
    fa4a  32 25 76   STA ORIGINAL_OPCODE (7625)

    fa4d  36 f7      MVI M, f7                  ; Put RST 6 instruction instead

    fa4f  3e c3      MVI A, c3                  ; Store JMP BREAKPOINT (ffa2) opcode at RST6 handler (0x0030)
    fa51  32 30 00   STA 0030
    fa54  21 a2 ff   LXI HL, BREAKPOINT (ffa2)
    fa57  22 31 00   SHLD 0031

RUN_PROGRAM:
    fa5a  31 18 76   LXI SP, USER_BC (7618)     ; Restore registers previously saved to 0x7614-0x761f 
    fa5d  c1         POP BC
    fa5e  d1         POP DE
    fa5f  e1         POP HL
    fa60  f1         POP PSW

    fa61  f9         SPHL                       ; Restore SP

    fa62  2a 16 76   LHLD USER_HL (7616)        ; Restore HL

    fa65  c3 26 76   JMP USER_PRG_JMP (7626)    ; Jump to the user program (0x7626 contains JMP instruction
                                                ; opcode, 0x7627 contains the command argument with the user
                                                ; program address)

; Command R - read external ROM
;
; Import specified data range from external ROM to the main RAM.
;
; It is supposed that the ROM is connected via a i8255 controller, where ROM address lines are
; connected to ports B (low byte) and C (high byte), while data is read over port A.
;
; Arguments:
; - ROM start address (HL)
; - ROM end address (DE)
; - Target (RAM) start address (BC)
COMMAND_R:
    fa68  3e 90      MVI A, 90                  ; Set the 8255 PPI as follows: Port A - Input (data), Ports B
    fa6a  32 03 a0   STA a003                   ; and C - Output (address)

COMMAND_R_LOOP:
    fa6d  22 01 a0   SHLD a001                  ; Set the ROM address on ports B (low byte) and C (high byte)

    fa70  3a 00 a0   LDA a000                   ; Read the ROM byte and store it at [BC]
    fa73  02         STAX BC

    fa74  03         INX BC                     ; Advance ROM and target address
    fa75  cd 99 f9   CALL ADVANCE_HL (f999)

    fa78  c3 6d fa   JMP COMMAND_R_LOOP (fa6d)  ; Repeat for the next byte


????:
fa7b  2a 02 76   LHLD CURSOR_POS (7602)
fa7e  c9         RET

????:
fa7f  e5         PUSH HL
fa80  2a 00 76   LHLD CURSOR_ADDR (7600)
fa83  7e         MOV A, M
fa84  e1         POP HL
fa85  c9         RET
????:
fa86  3a 2d 76   LDA 762d
fa89  b7         ORA A
fa8a  ca 91 fa   JZ fa91
fa8d  7b         MOV A, E
fa8e  32 2f 76   STA 762f
????:
fa91  cd b6 fa   CALL fab6
fa94  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)
fa97  eb         XCHG
fa98  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)
fa9b  eb         XCHG
fa9c  c5         PUSH BC
fa9d  cd 16 fb   CALL fb16
faa0  60         MOV H, B
faa1  69         MOV L, C
faa2  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)
faa5  d1         POP DE
faa6  cd 90 f9   CALL COMPARE_DE_HL (f990)
faa9  c8         RZ
faaa  eb         XCHG
faab  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)

INPUT_ERROR:
    faae  3e 3f      MVI A, 3f                  ; Print '?' char
    fab0  cd b9 fc   CALL PUT_CHAR_A (fcb9)

    fab3  c3 6c f8   JMP MAIN_LOOP (f86c)       ; Restart the main loop

????:
fab6  3e ff      MVI A, ff
fab8  cd ff fa   CALL faff
fabb  e5         PUSH HL
fabc  09         DAD BC
fabd  eb         XCHG
fabe  cd fd fa   CALL fafd
fac1  e1         POP HL
fac2  09         DAD BC
fac3  eb         XCHG
fac4  e5         PUSH HL
fac5  cd 0a fb   CALL fb0a
fac8  3e ff      MVI A, ff
faca  cd ff fa   CALL faff
facd  e1         POP HL

; The function re-initializes video controller and DMA transfer for video memory
;
; The i8275 video controller works closely with i8257 DMA controller. This allows the video controller access 
; to the video memory without main CPU involvement. The function intializes the hardware as follows:
; - Video controller:
;   - Video mode is set to 30 rows by 78 chars each
;   - 10 lines per each character row (actual char height is 8 lines, and 2 lines spacing)
;   - 10 lines high blinking cursor (so that whole symbol is blinking)
;   - DMA transfer with 8-byte packets, and short delay between packets
; - DMA controller
;   - Will use Channel 2 for video memory transfer
;   - Will use autoload mode when Channel 2 start parameters are stored in Channel 3 internally, and autoloaded
;     after each data transfer
;   - Video RAM start address is 0x76d0
;   - DMA will transfer 0x924 bytes (which is 30 rows by 78 chars each)
INIT_VIDEO:
    face  e5         PUSH HL                    ; Set HL to 8275 control register address
    facf  21 01 c0   LXI HL, c001

    fad2  36 00      MVI M, 00                  ; Send the i8275 reset command

    fad4  2b         DCX HL                     ; Send 4 parameters of the reset command:]
    fad5  36 4d      MVI M, 4d                  ; Screen width: 78 chars
    fad7  36 1d      MVI M, 1d                  ; Screen height: 30 chars
    fad9  36 99      MVI M, 99                  ; Char height: 10 lines, underline height: 10 lines
    fadb  36 d3      MVI M, d3			        ; Non offset mode, non-transparrent attribute mode (shall be transparent???)
                                                ; Blinking cursor, Horisontal retracing - 8

    fadd  23         INX HL                     ; Send the i8275 start display command (7 chars burst delay
    fade  36 27      MVI M, 27                  ; interval, 8 bytes transfer per burst)

    fae0  7e         MOV A, M                   ; Read the i8275 status byte
    
INIT_VIDEO_WAIT_LOOP:
    fae1  7e         MOV A, M                   ; Read the status byte until Interrupt Request (IR) flag is set
    fae2  e6 20      ANI A, 20                  ; (waiting until current frame is shown so that we can load the
    fae4  ca e1 fa   JZ INIT_VIDEO_WAIT_LOOP (fae1) ; new frame)

    fae7  21 08 e0   LXI HL, e008               ; Init DMA controller, set autoload flag
    faea  36 80      MVI M, 80

    faec  2e 04      MVI L, 04                  ; Set 0x76d0 as a video memory start (start address for DMA
    faee  36 d0      MVI M, d0                  ; transfer to the video controller)
    faf0  36 76      MVI M, 76

    faf2  2c         INR L                      ; Set 0x924 number of bytes in video frame (30 rows by 78 cols)
    faf3  36 23      MVI M, 23
    faf5  36 49      MVI M, 49                  ; Set also memory->video controller direction

    faf7  2e 08      MVI L, 08                  ; Enable DMA Channel 2 with autoload
    faf9  36 a4      MVI M, a4

    fafb  e1         POP HL                     ; Exit
    fafc  c9         RET

????:
fafd  3e 08      MVI A, 08
????:
faff  cd 98 fb   CALL fb98
fb02  47         MOV B, A
fb03  3e 08      MVI A, 08
fb05  cd 98 fb   CALL fb98
fb08  4f         MOV C, A
fb09  c9         RET
????:
fb0a  3e 08      MVI A, 08
fb0c  cd 98 fb   CALL fb98
fb0f  77         MOV M, A
fb10  cd 99 f9   CALL ADVANCE_HL (f999)
fb13  c3 0a fb   JMP fb0a
????:
fb16  01 00 00   LXI BC, 0000
????:
fb19  7e         MOV A, M
fb1a  81         ADD C
fb1b  4f         MOV C, A
fb1c  f5         PUSH PSW
fb1d  cd 90 f9   CALL COMPARE_DE_HL (f990)
fb20  ca 9f f9   JZ f99f
fb23  f1         POP PSW
fb24  78         MOV A, B
fb25  8e         ADC M
fb26  47         MOV B, A
fb27  cd 99 f9   CALL ADVANCE_HL (f999)
fb2a  c3 19 fb   JMP fb19
????:
fb2d  79         MOV A, C
fb2e  b7         ORA A
fb2f  ca 35 fb   JZ fb35
fb32  32 30 76   STA 7630
????:
fb35  e5         PUSH HL
fb36  cd 16 fb   CALL fb16
fb39  e1         POP HL
fb3a  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)
fb3d  eb         XCHG
fb3e  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)
fb41  eb         XCHG
fb42  e5         PUSH HL
fb43  60         MOV H, B
fb44  69         MOV L, C
fb45  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)
fb48  e1         POP HL
????:
fb49  c5         PUSH BC
fb4a  01 00 00   LXI BC, 0000
????:
fb4d  cd 46 fc   CALL fc46
fb50  05         DCR B
fb51  e3         XTHL
fb52  e3         XTHL
fb53  c2 4d fb   JNZ fb4d
fb56  0e e6      MVI C, e6
fb58  cd 46 fc   CALL fc46
fb5b  cd 90 fb   CALL fb90
fb5e  eb         XCHG
fb5f  cd 90 fb   CALL fb90
fb62  eb         XCHG
fb63  cd 86 fb   CALL fb86
fb66  21 00 00   LXI HL, 0000
fb69  cd 90 fb   CALL fb90
fb6c  0e e6      MVI C, e6
fb6e  cd 46 fc   CALL fc46
fb71  e1         POP HL
fb72  cd 90 fb   CALL fb90
fb75  c3 ce fa   JMP INIT_VIDEO (face)

; Prints an address as a 4 byte hex value on a new line.
; Parameters: HL - address to print
PRINT_HEX_ADDR:
    fb78  c5         PUSH BC
    fb79  cd b0 f9   CALL PRINT_NEW_LINE (f9b0)

    fb7c  7c         MOV A, H
    fb7d  cd a5 fc   CALL PRINT_HEX_BYTE (fca5)

    fb80  7d         MOV A, L
    fb81  cd ba f9   CALL PRINT_HEX_BYTE_SPACE (f9ba)

    fb84  c1         POP BC
    fb85  c9         RET


????:
fb86  4e         MOV C, M
fb87  cd 46 fc   CALL fc46
fb8a  cd 99 f9   CALL ADVANCE_HL (f999)
fb8d  c3 86 fb   JMP fb86
????:
fb90  4c         MOV C, H
fb91  cd 46 fc   CALL fc46
fb94  4d         MOV C, L
fb95  c3 46 fc   JMP fc46
????:
fb98  e5         PUSH HL
fb99  c5         PUSH BC
fb9a  d5         PUSH DE
fb9b  57         MOV D, A
????:
fb9c  3e 80      MVI A, 80
fb9e  32 08 e0   STA e008
fba1  21 00 00   LXI HL, 0000
fba4  39         DAD SP
fba5  31 00 00   LXI SP, 0000
fba8  22 0d 76   SHLD 760d
fbab  0e 00      MVI C, 00
fbad  3a 02 80   LDA KBD_PORT_C (8002)
fbb0  0f         RRC
fbb1  0f         RRC
fbb2  0f         RRC
fbb3  0f         RRC
fbb4  e6 01      ANI A, 01
fbb6  5f         MOV E, A
????:
fbb7  f1         POP PSW
fbb8  79         MOV A, C
fbb9  e6 7f      ANI A, 7f
fbbb  07         RLC
fbbc  4f         MOV C, A
fbbd  26 00      MVI H, 00
????:
fbbf  25         DCR H
fbc0  ca 34 fc   JZ fc34
fbc3  f1         POP PSW
fbc4  3a 02 80   LDA KBD_PORT_C (8002)
fbc7  0f         RRC
fbc8  0f         RRC
fbc9  0f         RRC
fbca  0f         RRC
fbcb  e6 01      ANI A, 01
fbcd  bb         CMP E
fbce  ca bf fb   JZ fbbf
fbd1  b1         ORA C
fbd2  4f         MOV C, A
fbd3  15         DCR D
fbd4  3a 2f 76   LDA 762f
fbd7  c2 dc fb   JNZ fbdc
fbda  d6 12      SUI A, 12
????:
fbdc  47         MOV B, A
????:
fbdd  f1         POP PSW
fbde  05         DCR B
fbdf  c2 dd fb   JNZ fbdd
fbe2  14         INR D
fbe3  3a 02 80   LDA KBD_PORT_C (8002)
fbe6  0f         RRC
fbe7  0f         RRC
fbe8  0f         RRC
fbe9  0f         RRC
fbea  e6 01      ANI A, 01
fbec  5f         MOV E, A
fbed  7a         MOV A, D
fbee  b7         ORA A
fbef  f2 0b fc   JP fc0b
fbf2  79         MOV A, C
fbf3  fe e6      CPI A, e6
fbf5  c2 ff fb   JNZ fbff
fbf8  af         XRA A
fbf9  32 2e 76   STA 762e
fbfc  c3 09 fc   JMP fc09
????:
fbff  fe 19      CPI A, 19
fc01  c2 b7 fb   JNZ fbb7
fc04  3e ff      MVI A, ff
fc06  32 2e 76   STA 762e
????:
fc09  16 09      MVI D, 09
????:
fc0b  15         DCR D
fc0c  c2 b7 fb   JNZ fbb7
fc0f  21 04 e0   LXI HL, e004
fc12  36 d0      MVI M, d0
fc14  36 76      MVI M, 76
fc16  23         INX HL
fc17  36 23      MVI M, 23
fc19  36 49      MVI M, 49
fc1b  3e 27      MVI A, 27
fc1d  32 01 c0   STA c001
fc20  3e e0      MVI A, e0
fc22  32 01 c0   STA c001
fc25  2e 08      MVI L, 08
fc27  36 a4      MVI M, a4
fc29  2a 0d 76   LHLD 760d
fc2c  f9         SPHL
fc2d  3a 2e 76   LDA 762e
fc30  a9         XRA C
fc31  c3 a1 fc   JMP fca1
????:
fc34  2a 0d 76   LHLD 760d
fc37  f9         SPHL
fc38  cd ce fa   CALL INIT_VIDEO (face)
fc3b  7a         MOV A, D
fc3c  b7         ORA A
fc3d  f2 ae fa   JP INPUT_ERROR (faae)
fc40  cd a4 f9   CALL f9a4
fc43  c3 9c fb   JMP fb9c
????:
fc46  e5         PUSH HL
fc47  c5         PUSH BC
fc48  d5         PUSH DE
fc49  f5         PUSH PSW
fc4a  3e 80      MVI A, 80
fc4c  32 08 e0   STA e008
fc4f  21 00 00   LXI HL, 0000
fc52  39         DAD SP
fc53  31 00 00   LXI SP, 0000
fc56  16 08      MVI D, 08
????:
fc58  f1         POP PSW
fc59  79         MOV A, C
fc5a  07         RLC
fc5b  4f         MOV C, A
fc5c  3e 01      MVI A, 01
fc5e  a9         XRA C
fc5f  32 02 80   STA KBD_PORT_C (8002)
fc62  3a 30 76   LDA 7630
fc65  47         MOV B, A
????:
fc66  f1         POP PSW
fc67  05         DCR B
fc68  c2 66 fc   JNZ fc66
fc6b  3e 00      MVI A, 00
fc6d  a9         XRA C
fc6e  32 02 80   STA KBD_PORT_C (8002)
fc71  15         DCR D
fc72  3a 30 76   LDA 7630
fc75  c2 7a fc   JNZ fc7a
fc78  d6 0e      SUI A, 0e
????:
fc7a  47         MOV B, A
????:
fc7b  f1         POP PSW
fc7c  05         DCR B
fc7d  c2 7b fc   JNZ fc7b
fc80  14         INR D
fc81  15         DCR D
fc82  c2 58 fc   JNZ fc58
fc85  f9         SPHL
fc86  21 04 e0   LXI HL, e004
fc89  36 d0      MVI M, d0
fc8b  36 76      MVI M, 76
fc8d  23         INX HL
fc8e  36 23      MVI M, 23
fc90  36 49      MVI M, 49
fc92  3e 27      MVI A, 27
fc94  32 01 c0   STA c001
fc97  3e e0      MVI A, e0
fc99  32 01 c0   STA c001
fc9c  2e 08      MVI L, 08
fc9e  36 a4      MVI M, a4
fca0  f1         POP PSW
????:
fca1  d1         POP DE
fca2  c1         POP BC
fca3  e1         POP HL
fca4  c9         RET

PRINT_HEX_BYTE:
fca5  f5         PUSH PSW
fca6  0f         RRC
fca7  0f         RRC
fca8  0f         RRC
fca9  0f         RRC
fcaa  cd ae fc   CALL fcae
fcad  f1         POP PSW
????:
fcae  e6 0f      ANI A, 0f
fcb0  fe 0a      CPI A, 0a
fcb2  fa b7 fc   JM fcb7
fcb5  c6 07      ADI A, 07
????:
fcb7  c6 30      ADI A, 30


; Print a char in A register
PUT_CHAR_A:
    fcb9  4f         MOV C, A

; Print a char
; C - char to print
;
; This function puts a char at the cursor location in a terminal mode (including wrapping
; the cursor to the next line, and scrolling the text if the end of screen reached). 
;
; The function is responsible to track the cursor position in 2 different way:
; - As a pointer in the Video RAM to track where to store the next symbol
; - As a X and Y coordinate to track screen boundaries, and fill the i8275 cursor position register.
;
; The function handles the following special chars:
; 0x08  - Move cursor 1 position left
; 0x0c  - Move cursor to the top left position
; 0x18  - Move cursor 1 position right
; 0x19  - Move cursor 1 line up
; 0x1a  - Move cursor 1 line down
; 0x0d  - carriage return (move cursor to the leftmost position on the same line)
; 0x0a  - line feed (move cursor to the next line, scroll 1 line if necessary)
; 0x1f  - Clear screen
; 0x1b  - Move cursor to a selected position
;         This is a 4-symbol sequence (similar to Esc sequence):
;         0x1b, 'Y', 0x20+Y position, 0x20+X position
;
; Physical screen resolution (how the Video controller is configured) is 78x30 characters. The video controller
; outputs the whole video RAM to the screen. At the same time Radio-86RK is supposed to be used with CRT display,
; and actual visible area may be smaller. This function is responsible for artificially limit amount of data on
; the screen by adding a 3-line margin at the top of the screen, 8 chars left margin, 6 chars right margin. There
; is no bottom margin, as it is generated by video controller as a part of the pause between frames. 
; 
;
; Important variables:
; 7600 - Current cursor position (memory address)
; 7602 - Current cursor coordinate (X and Y position)
; 7604 - cursor direct movement state
;        0 - normal mode, next symbol is a regular symbol
;        1 - 0x1b printed, expecting 'Y'
;        2 - expecting Y coordinate
;        4 - expecting X coordinate
PUT_CHAR:
    fcba  f5         PUSH PSW                   ; Save registers
    fcbb  c5         PUSH BC
    fcbc  d5         PUSH DE
    fcbd  e5         PUSH HL

    fcbe  cd 01 fe   CALL IS_BUTTON_PRESSED (fe01)  ; ????

    fcc1  21 85 fd   LXI HL, PUT_CHAR_EXIT (fd85)   ; Put an exit address to the stack (so that subfunction may
    fcc4  e5         PUSH HL                        ; just call RET)

    fcc5  2a 02 76   LHLD CURSOR_POS (7602)     ; Load logical cursor coordinates (X/Y) to DE
    fcc8  eb         XCHG
    fcc9  2a 00 76   LHLD CURSOR_ADDR (7600)    ; Load current cursor address to HL

    fccc  3a 04 76   LDA ESC_SEQ_STATE (7604)   ; Check the escape sequence state machine
    fccf  3d         DCR A
    fcd0  fa ee fc   JM PRINT_NORMAL_CHAR (fcee)    ; If 0 - it is a normal character print
    fcd3  ca 65 fd   JZ MOVE_CUR_DIRECT_B1 (fd65)   ; If 1 - Esc matched, expect 'Y' as the next char
    fcd6  e2 73 fd   JPO MOVE_CUR_DIRECT_B1 (fd73)  ; If 2 - Esc-Y matched, expect Y cursor coordinate

    fcd9  79         MOV A, C                   ; This is stage 4 of the sequence - apply X coordinate
    fcda  d6 20      SUI A, 20                  ; Process X coordinate in the escape sequence
    fcdc  4f         MOV C, A                   ; Adjust by 0x20 (as it uses printable chars)

MOVE_CUR_DIRECT_L1:
    fcdd  0d         DCR C                      ; Symbols below 0x20 are illegal, abandon the escape sequence
    fcde  fa e9 fc   JM MOVE_CUR_DIRECT_RESET (fce9)

    fce1  c5         PUSH BC                    ; Move cursor right
    fce2  cd b9 fd   CALL MOVE_CUR_RIGHT (fdb9)
    fce5  c1         POP BC

    fce6  c3 dd fc   JMP MOVE_CUR_DIRECT_L1 (fcdd)  ; Repeat C number of times

MOVE_CUR_DIRECT_RESET:
    fce9  af         XRA A                      ; Reset the escape sequence state machine

MOVE_CUR_DIRECT_EXIT:
    fcea  32 04 76   STA ESC_SEQ_STATE          ; Store escape sequence state, and exit
    fced  c9         RET

PRINT_NORMAL_CHAR:
    fcee  79         MOV A, C                   ; Ensure there is no MSB in the symbol (clear MSB)
    fcef  e6 7f      ANI A, 7f
    fcf1  4f         MOV C, A

    fcf2  fe 1f      CPI A, 1f                  ; 0x1f - clear screen
    fcf4  ca a3 fd   JZ CLEAR_SCREEN (fda3)

    fcf7  fe 0c      CPI A, 0c                  ; 0x0c - home cursor
    fcf9  ca b2 fd   JZ HOME_SCREEN (fdb2)

    fcfc  fe 0d      CPI A, 0d                  ; 0x0d - carriage return
    fcfe  ca f3 fd   JZ CARRIAGE_RETURN (fdf3)

    fd01  fe 0a      CPI A, 0a                  ; 0x0a - line feed
    fd03  ca 47 fd   JZ LINE_FEED (fd47)

    fd06  fe 08      CPI A, 08                  ; 0x08 - cursor left
    fd08  ca d6 fd   JZ MOVE_CUR_LEFT (fdd6)

    fd0b  fe 18      CPI A, 18                  ; 0x18 - cursor right
    fd0d  ca b9 fd   JZ MOVE_CUR_RIGHT (fdb9)

    fd10  fe 19      CPI A, 19                  ; 0x19 - cursor up
    fd12  ca e2 fd   JZ MOVE_CUR_UP (fde2)

    fd15  fe 1a      CPI A, 1a                  ; 0x1a - cursor down
    fd17  ca c5 fd   JZ MOVE_CUR_DOWN (fdc5)

    fd1a  fe 1b      CPI A, 1b                  ; 0x1b - start of Escape sequence for direct cursor movement
    fd1c  ca 9e fd   JZ MOVE_CUR_DIRECT (fd9e)

    fd1f  fe 07      CPI A, 07                  ; 0x07 - bell (beep)
    fd21  c2 38 fd   JNZ DO_PUT_CHAR (fd38)     ; Process normal chars little below

    fd24  01 f0 05   LXI BC, 05f0               ; B - beep period, C - Beep duration


; Beep (sound generation) function
; Generates sounds on EI pin of the CPU
;
; Arguments:
; B - beep period (delay between the pin goes on and off)
; C - number of periods to generate
BEEP_LOOP:
    fd27  78         MOV A, B

BEEP_L1:
    fd28  fb         EI                         ; Positive half-period
    fd29  3d         DCR A
    fd2a  c2 28 fd   JNZ BEEP_L1 (fd28)

    fd2d  78         MOV A, B                   ; Reload beep period

BEEP_L2:
    fd2e  f3         DI                         ; Negative half-period
    fd2f  3d         DCR A
    fd30  c2 2e fd   JNZ BEEP_L2 (fd2e)

    fd33  0d         DCR C                      ; Repeat C times
    fd34  c2 27 fd   JNZ BEEP_LOOP (fd27)

    fd37  c9         RET                        ; Exit

DO_PUT_CHAR:
    fd38  71         MOV M, C                   ; Store the symbol in video RAM (HL points to the right position)

    fd39  cd b9 fd   CALL MOVE_CUR_RIGHT (fdb9) ; Advance cursor to the next position

    fd3c  7a         MOV A, D                   ; Check X and Y coordinates to match row #3 and column #8.
    fd3d  fe 03      CPI A, 03                  
    fd3f  c0         RNZ                        

    fd40  7b         MOV A, E                   ; Moving cursor right in the bottom-right position will move it
    fd41  fe 08      CPI A, 08                  ; to the top left position. This is special case, handled below.
    fd43  c0         RNZ                        ; Otherwise we can safely exit.

    fd44  cd e2 fd   CALL MOVE_CUR_UP (fde2)    ; Do one move up, so that cursor appears at the bottom line

LINE_FEED:
    fd47  7a         MOV A, D                   ; Check if the cursor is on the bottom line. If not yet, the line
    fd48  fe 1b      CPI A, 1b                  ; feed command will be a simple cursor down movement
    fd4a  c2 c5 fd   JNZ MOVE_CUR_DOWN (fdc5)

    fd4d  e5         PUSH HL                    ; Otherwise need to make a one line scroll by copying line data
    fd4e  d5         PUSH DE                    ; to the previous line.

    fd4f  21 c2 77   LXI HL, 77c2               ; Top-left char (not counting 3-line top and 8 column left margin)
    fd52  11 10 78   LXI DE, 7810               ; Leftmost char (not including 8-char margin) on the second line
    fd55  01 9e 07   LXI BC, 079e               ; Number of chars in 25 full lines

SCROLL_LOOP:
    fd58  1a         LDAX DE                    ; Copy one char
    fd59  77         MOV M, A

    fd5a  23         INX HL                     ; Advance pointers and decrement counter
    fd5b  13         INX DE
    fd5c  0b         DCX BC

    fd5d  79         MOV A, C                   ; Repeat until counter is zero
    fd5e  b0         ORA B
    fd5f  c2 58 fd   JNZ SCROLL_LOOP (fd58)

    fd62  d1         POP DE                     ; Exit
    fd63  e1         POP HL
    fd64  c9         RET

MOVE_CUR_DIRECT_B1:
    fd65  79         MOV A, C                   ; Compare the second symbol in the sequence in 'Y'
    fd66  fe 59      CPI A, 59

    fd68  c2 e9 fc   JNZ MOVE_CUR_DIRECT_RESET (fce9)   ; If not matched - reset the state machine

    fd6b  cd b2 fd   CALL HOME_SCREEN (fdb2)    ; If matched - move cursor to the home position....

    fd6e  3e 02      MVI A, 02                  ; ... and wait for the Y coordinate
    fd70  c3 ea fc   JMP MOVE_CUR_DIRECT_EXIT (fcea)

MOVE_CUR_DIRECT_B1:
    fd73  79         MOV A, C                   ; The coordinate is 0x20-based. Subtract 0x20 to get the value
    fd74  d6 20      SUI A, 20
    fd76  4f         MOV C, A

MOVE_CUR_DIRECT_L2:
    fd77  0d         DCR C                      ; Move cursor down C times

    fd78  3e 04      MVI A, 04                  ; Prepare to the 4-th char in sequence
    fd7a  fa ea fc   JM MOVE_CUR_DIRECT_EXIT (fcea)

    fd7d  c5         PUSH BC                    ; Actually perform the movement
    fd7e  cd c5 fd   CALL MOVE_CUR_DOWN (fdc5)
    fd81  c1         POP BC

    fd82  c3 77 fd   JMP MOVE_CUR_DIRECT_L2 (fd77)  ; Repeat

; Finalize character printing, store new cursor position in the video controller
PUT_CHAR_EXIT:
    fd85  22 00 76   SHLD CURSOR_ADDR (7600)    ; Store the new cursor address and cursor X/Y coordinate
    fd88  eb         XCHG
    fd89  22 02 76   SHLD CURSOR_POS (7602)

    fd8c  3e 80      MVI A, 80                  ; Set the new cursor position in i8275 cursor register
    fd8e  32 01 c0   STA c001
    fd91  7d         MOV A, L                   ; X
    fd92  32 00 c0   STA c000
    fd95  7c         MOV A, H                   ; Y
    fd96  32 00 c0   STA c000

    fd99  e1         POP HL                     ; Restore registers and exit
    fd9a  d1         POP DE
    fd9b  c1         POP BC
    fd9c  f1         POP PSW
    fd9d  c9         RET

; Handle the first symbol in the Esc-Y sequence
MOVE_CUR_DIRECT:
    fd9e  3e 01      MVI A, 01                  ; Move to the 'expect Y' state, and exit
    fda0  c3 ea fc   JMP MOVE_CUR_DIRECT_EXIT (fcea)


; Fill the video RAM with zeros
CLEAR_SCREEN:
    fda3  21 f4 7f   LXI HL, 7ff4               ; Address of the last char on the screen
    fda6  11 25 09   LXI DE, 0925               ; Number of chars on the screen (30*78) + 1

CLEAR_SCREEN_LOOP:
    fda9  af         XRA A                      ; Clear the char
    fdaa  77         MOV M, A

    fdab  2b         DCX HL                     ; Go to the previous char, decrement counter
    fdac  1b         DCX DE

    fdad  7b         MOV A, E                   ; Repeat until counter is zero
    fdae  b2         ORA D
    fdaf  c2 a9 fd   JNZ CLEAR_SCREEN_LOOP (fda9)

; Set the initial cursor coordinates (which suprisingly are (8:3))
HOME_SCREEN:
    fdb2  11 08 03   LXI DE, 0308               ; Set cursor to X=8, Y=3
    fdb5  21 c2 77   LXI HL, 77c2               ; cursor address = 0x76d0 + Y*width + X
    fdb8  c9         RET

; Move cursor 1 position right
; If cursor moves beyond 70th column limit, it is returned back to the beginning of the line (so that
; the next function will move the cursor down 1 line)
MOVE_CUR_RIGHT:
    fdb9  7b         MOV A, E                   ; Advance X coordinate to the next column
    fdba  23         INX HL                     ; Advance cursor pointer to the next position
    fdbb  1c         INR E

    fdbc  fe 47      CPI A, 47                  ; If we are within 71th column - we are done
    fdbe  c0         RNZ

    fdbf  1e 08      MVI E, 08                  ; If exceeded 71th column - return to column #8

    fdc1  01 c0 ff   LXI BC, ffc0               ; Subtract 64 from the cursor pointer (to the beginning
    fdc4  09         DAD BC                     ; of current row)


; Move cursor down 1 line, preserving the column position
; The function increments Y coordinate, and advances cursor pointer by 78
MOVE_CUR_DOWN:
    fdc5  7a         MOV A, D                   ; Is the curson on the last line?
    fdc6  fe 1b      CPI A, 1b

    fdc8  01 4e 00   LXI BC, 004e               ; If cursor is not yet on the last line, the pointer will be
    fdcb  c2 d3 fd   JNZ MOVE_CUR_DOWN_1 (fdd3) ; advanced by 78 (line width)

    fdce  16 02      MVI D, 02                  ; If cursor was on the last line, move it to the first line
    fdd0  01 b0 f8   LXI BC, f8b0               ; (actually line number 3). Correct cursor pointer accordingly.

MOVE_CUR_DOWN_1:
    fdd3  14         INR D                      ; Increment the Y coordinate, and advance cursor pointer by 78
    fdd4  09         DAD BC
    fdd5  c9         RET

; Move cursor 1 position left
; If cursor reaches the left border, it is moved to the rightmost position on the same line. The next function
; will also move cursor one line up.
MOVE_CUR_LEFT:
    fdd6  7b         MOV A, E                   ; Decrement X cursor coordinate and cursor pointer
    fdd7  2b         DCX HL
    fdd8  1d         DCR E

    fdd9  fe 08      CPI A, 08                  ; Check if cursor reached the first logic column (column #8)
    fddb  c0         RNZ

    fddc  1e 47      MVI E, 47                  ; If reached the beginning of the line, move cursor to the end
    fdde  01 40 00   LXI BC, 0040               ; of the same line (column 0x71, and move pointer further by 64
    fde1  09         DAD BC                     ; chars).

; Move cursor one line up
MOVE_CUR_UP:
    fde2  7a         MOV A, D                   ; Check if cursor has reached top screen border
    fde3  fe 03      CPI A, 03

    fde5  01 b2 ff   LXI BC, ffb2               ; If there is still room to go, move cursor pointer by 78 chars back
    fde8  c2 f0 fd   JNZ MOVE_CUR_UP_1 (fdf0)

    fdeb  16 1c      MVI D, 1c                  ; If reached the top line, move cursor to the bottom line. 
    fded  01 50 07   LXI BC, 0750               ; Correct cursor pointer accordingly

MOVE_CUR_UP_1:
    fdf0  15         DCR D                      ; Decrement Y cursor position
    fdf1  09         DAD BC                     ; Subtract 78 from the cursor pointer
    fdf2  c9         RET

; Return cursor to the leftmost position (actually column #8) in the same line
CARRIAGE_RETURN:
    fdf3  7d         MOV A, L                   ; Subtract X cursor position from current cursor pointer
    fdf4  93         SUB E                      ; The result is pointer to the beginning of the current line
    fdf5  d2 f9 fd   JNC CARRIAGE_RETURN_1 (fdf9)
    fdf8  25         DCR H

CARRIAGE_RETURN_1:
    fdf9  6f         MOV L, A                   ; Finish previous subtraction operation

    fdfa  1e 08      MVI E, 08                  ; Advance cursor 8 chars right to the logical beginning of 
    fdfc  01 08 00   LXI BC, 0008               ; the line
    fdff  09         DAD BC

    fe00  c9         RET


; Check if a button is pressed. Returns A=0xff if the key is pressed, 0x00 if not pressed
; 
; The function is also responsible for auto-repeat feature, which is working like follows:
; - When a key is just pressed, the function does not report this to the called immediately. Instead it
;   starts a short timer (0x15 calls of this function) to ensure the key is really pressed, and this is not
;   a debounce issue, or a mistakely hit key.
; - If the key is pressed for 0x15 calls of this function, the function finally returns 0xff value, indicating
;   the key is really pressed, and KBD_INPUT function may return the key code
; - In the same time the function starts a longer timer (0xe0 calls of this function) for auto repeat feature.
;   During this timer period the function will not report that the key is pressed (despite it is)
; - When the timer is due, the function does a short beep, and report that the key is pressed, so that keyboard
;   reading function can do its job.
;
; The function is also responsible for handling RUS key press. If this happens, the function toggles the 
; CYRILLIC_ENABLED variable
IS_BUTTON_PRESSED:
    fe01  3a 02 80   LDA KBD_PORT_C (8002)      ; If the Rus key is pressed, the autorepeat feature is
    fe04  e6 80      ANI A, 80                  ; temporary disabled
    fe06  ca 0e fe   JZ IS_BUTTON_PRESSED_1 (fe0e)

    fe09  3a 05 76   LDA KEY_IS_PRESSED (7605)  ; Skip extra keyboard scans if the key is already pressed (but
    fe0c  b7         ORA A                      ; not yet processed by the keyboar input function)
    fe0d  c0         RNZ

IS_BUTTON_PRESSED_1:
    fe0e  e5         PUSH HL                    ; Load some autorepeat char (L) and autorepeat timer value (H)
    fe0f  2a 09 76   LHLD AUTOREPEAT_CHAR (7609)

    fe12  cd 72 fe   CALL KBD_SCAN (fe72)       ; Get the key scan code

    fe15  bd         CMP L                      ; Check if scanned symbol differs from autorepeat symbol
    fe16  6f         MOV L, A                   ; Store the new symbol as autorepeat one
    fe17  ca 2a fe   JZ IS_BUTTON_PRESSED_3 (fe2a)

IS_BUTTON_PRESSED_2:
    fe1a  3e 01      MVI A, 01                  ; We've just detected a new keypress. Set the first trigger for
    fe1c  32 0b 76   STA AUTOREPEAT_FLAG (760b) ; auto repeat (use a longer delay before the autorepeated symbol)

    fe1f  26 15      MVI H, 15                  ; Minimum duration when the key is considered as pressed

IS_BUTTON_PRESSED_EXIT_NO_PRESS:
    fe21  af         XRA A                      ; Report the key as not pressed for now

IS_BUTTON_PRESSED_EXIT:
    fe22  22 09 76   SHLD AUTOREPEAT_CHAR (7609); Save autorepeat key and timer value
    fe25  e1         POP HL

    fe26  32 05 76   STA KEY_IS_PRESSED (7605)  ; Save the key pressed flag, and exit
    fe29  c9         RET


IS_BUTTON_PRESSED_3:
    fe2a  25         DCR H                      ; Check if autorepeat timer is due
    fe2b  c2 21 fe   JNZ IS_BUTTON_PRESSED_EXIT_NO_PRESS (fe21)

    fe2e  3c         INR A                      ; A=0xff means no key was pressed, or key was released.
    fe2f  ca 22 fe   JZ IS_BUTTON_PRESSED_EXIT (fe22)   ; Just exit

    fe32  3c         INR A                      ; A=0xfe means RUS key pressed
    fe33  ca 51 fe   JZ TOGGLE_RUS_LAT (fe51)

    fe36  c5         PUSH BC                    ; Generate a short beep
    fe37  01 03 50   LXI BC, 5003
    fe3a  cd 27 fd   CALL BEEP_LOOP (fd27)
    fe3d  c1         POP BC

    fe3e  3a 0b 76   LDA AUTOREPEAT_FLAG (760b)
    fe41  26 e0      MVI H, e0                  ; Set long delay between first press and autorepeat
    fe43  3d         DCR A                      ; Decrement autorepeat counter
    fe44  32 0b 76   STA AUTOREPEAT_FLAG (760b)

    fe47  ca 4c fe   JZ IS_BUTTON_PRESSED_4 (fe4c)

    fe4a  26 40      MVI H, 40                  ; Set shorter delay between autorepeats

IS_BUTTON_PRESSED_4:
    fe4c  3e ff      MVI A, ff                  ; Raise a flag, that key is pressed
    fe4e  c3 22 fe   JMP IS_BUTTON_PRESSED_EXIT (fe22)


TOGGLE_RUS_LAT:
    fe51  3a 02 80   LDA KBD_PORT_C (8002)      ; Wait until RUS key is released
    fe54  e6 80      ANI A, 80
    fe56  ca 51 fe   JZ TOGGLE_RUS_LAT (fe51)

    fe59  3a 06 76   LDA CYRILLIC_ENABLED (7606)    ; Toggle the Cyrillic mode
    fe5c  2f         CMA
    fe5d  32 06 76   STA CYRILLIC_ENABLED (7606)

    fe60  c3 1a fe   JMP IS_BUTTON_PRESSED_2 (fe1a) ; Continue through the key release procedures


; Wait for a keyboard input
; 
; The function waits until a key is pressed, and returns the key code. This function works in pair with
; the IS_BUTTON_PRESSED function that handles the autorepeat feature, and indicates that key is pressed
; when autorepeat timer is due. Once KBD_INPUT function detects the keypress, it clears the key pressed
; flag, despite the key may be still pressed. The IS_BUTTON_PRESSED is responsible for setting it again
; after the next timer cycle is due.
KBD_INPUT:
    fe63  cd 01 fe   CALL IS_BUTTON_PRESSED (fe01)  ; Check if a key is pressed

    fe66  b7         ORA A                          ; Repeat keyboard scan until a key is pressed
    fe67  ca 63 fe   JZ KBD_INPUT (fe63)

    fe6a  af         XRA A                          ; Clear 'key is pressed' flag
    fe6b  32 05 76   STA KEY_IS_PRESSED (7605)

    fe6e  3a 09 76   LDA AUTOREPEAT_CHAR (7609)     ; Return the entered symbol
    fe71  c9         RET


; Scan the keyboard matrix, and return a key char code
;
; This function scans keyboard matrix, and return the scan code, if a button is pressed, or 0xff if
; nothing is pressed. Function returns 0xfe if Rus/Lat key is pressed.
;
; The function sequentally selects one column in the keyboard matrix, by setting the corresponding
; bit in the keyboard 8255 port A. The column scanning is performed by reading the port B. If a bit
; is 0, then the button is pressed.
;
; Here is the keyboard matrix. The header row specifies the column selection bit sent to Port A.
; The left column represent the code read via Port B. 
;
;      |     0xfe    |     0xfd    |   0xfb   |   0xf7   |   0xef   |   0xdf   |   0xbf   |   0x7f   |
; 0xfe | 0x0c home   | 0x09 home   | 0x30 '0' | 0x38 '8' | 0x40 '@' | 0x48 'H' | 0x50 'P' | 0x58 'X' |
; 0xfd | 0x1f clrscr | 0x0a lf     | 0x31 '1' | 0x39 '9' | 0x41 'A' | 0x49 'I' | 0x51 'Q' | 0x59 'Y' |
; 0xfb | 0x1b escape | 0x0d cr     | 0x32 '2' | 0x3a ':' | 0x42 'B' | 0x4a 'G' | 0x52 'R' | 0x5a 'Z' |
; 0xf7 | 0x00 F1     | 0x7f rubout | 0x33 '3' | 0x3b ';' | 0x43 'C' | 0x4b 'K' | 0x53 'S' | 0x5b '[' |
; 0xef | 0x01 F2     | 0x08 left   | 0x34 '4' | 0x2c ',' | 0x44 'D' | 0x4c 'L' | 0x54 'T' | 0x5c '\' |
; 0xdf | 0x02 F3     | 0x19 up     | 0x35 '5' | 0x2d '-' | 0x45 'E' | 0x4d 'M' | 0x55 'U' | 0x5d ']' |
; 0xbf | 0x03 F4     | 0x18 right  | 0x36 '6' | 0x2e '.' | 0x46 'F' | 0x4e 'N' | 0x56 'V' | 0x5e '^' |
; 0x7f | 0x04 F5     | 0x1a down   | 0x37 '7' | 0x2f '/' | 0x47 'G' | 0x4f 'O' | 0x57 'W' | 0x5f ' ' |
; 
; First stage of the algorithm is to detect the scan code which is essentially a row and column of the
; pressed key. If a button is pressed, then the algorithm starts conversion the scan code to the char code:
; - keys in columns 0 and 1 are converted via lookup tables
; - For most of the chars simple addition a 0x20 to the scan code is enough. Some characters require 
;   additional character codes remapping.
;
; The final stage of the algorithm is to apply alteration keys (by reading the port C):
; - RUS key - toggles the Rus/Lat (cyrillic) flag and turn on/off the Rus LED.  If Cyryllic mode is
;   currently on, latin letters (0x41-0x5e) are converted to cyrillic (0x60-0x7e)
; - Symbol - alters numeric key and some symbol keys in order to enter another set of symbols (this
;   is an analog of a Shift key on the modern computers, but works only for numeric and symbol keys.
;   Note, that there is no upper and lower case of letters on this computer)
; - Ctrl - alters some keys to produce codes in 0x00 - 0x1f range. This range contains control codes
;   (e.g. cursor movements, as well as some graphics)
; 
KBD_SCAN:
    fe72  3a 02 80   LDA KBD_PORT_C (8002)      ; Check if Rus key is pressed
    fe75  e6 80      ANI A, 80
    fe77  c2 7d fe   JNZ KBD_SCAN_1 (fe7d)

    fe7a  3e fe      MVI A, fe                  ; If pressed - return 0xfe
    fe7c  c9         RET

KBD_SCAN_1:
    fe7d  af         XRA A                      ; Output zeros to all columns to check if a button is pressed
    fe7e  32 00 80   STA KBD_PORT_A (8000)

    fe81  32 02 80   STA KBD_PORT_C (8002)      ; Switch off Rus LED (if enabled)

    fe84  3a 06 76   LDA CYRILLIC_ENABLED (7606); If Cyrillic mode enabled - turn on the Rus LED
    fe87  e6 01      ANI A, 01
    fe89  f6 06      ORI A, 06
    fe8b  32 03 80   STA KBD_CTRL_PORT (8003)

    fe8e  3a 01 80   LDA KBD_PORT_B (8001)      ; Read keyboard matrix

    fe91  3c         INR A                      ; If at least one key is pressed, there will be non-ff value
    fe92  c2 97 fe   JNZ KBD_SCAN_2 (fe97)

    fe95  3d         DCR A                      ; Otherwise return 0xff (no keys pressed)
    fe96  c9         RET

KBD_SCAN_2:
    fe97  e5         PUSH HL
    fe98  2e 01      MVI L, 01                  ; Initial column
    fe9a  26 07      MVI H, 07                  ; Number of columns to process - 1

KBD_SCAN_LOOP:
    fe9c  7d         MOV A, L                   ; Rotate to the next column
    fe9d  0f         RRC
    fe9e  6f         MOV L, A

    fe9f  2f         CMA                        ; Enable the column (negate value furst, as the column is enabled
    fea0  32 00 80   STA KBD_PORT_A (8000)      ; with low signal)

    fea3  3a 01 80   LDA KBD_PORT_B (8001)      ; Read rows. Negate value back, as pressed key will generate
    fea6  2f         CMA                        ; low signal

    fea7  b7         ORA A                      ; Check if any key was pressed on the selected column
    fea8  c2 b3 fe   JNZ KBD_SCAN_3 (feb3)

    feab  25         DCR H                      ; Repeat for the next column until counter is zero
    feac  f2 9c fe   JP KBD_SCAN_LOOP (fe9c)

KBD_SCAN_EXIT:
    feaf  3e ff      MVI A, ff                  ; If nothing was matched - return 0xff
    feb1  e1         POP HL
    feb2  c9         RET

KBD_SCAN_3:
    feb3  2e 20      MVI L, 20                  ; Debounce loop

KBD_SCAN_DEBOUNCE_LOOP:
    feb5  3a 01 80   LDA KBD_PORT_B (8001)      ; Repeat reading rows port for debounce
    feb8  2f         CMA
    feb9  b7         ORA A                      ; Exit if key was released
    feba  ca af fe   JZ KBD_SCAN_EXIT (feaf)

    febd  2d         DCR L                      
    febe  c2 b5 fe   JNZ KBD_SCAN_DEBOUNCE_LOOP (feb5)

    fec1  2e 08      MVI L, 08                  ; Number of bits to process

KBD_SCAN_4:
    fec3  2d         DCR L                      ; Detect index of the set bit
    fec4  07         RLC
    fec5  d2 c3 fe   JNC KBD_SCAN_4 (fec3)

    fec8  7c         MOV A, H                   ; H - row, L - column
    fec9  65         MOV H, L
    feca  6f         MOV L, A

    fecb  fe 01      CPI A, 01                  ; Check if the pressed key is in column 1
    fecd  ca fa fe   JZ KBD_SCAN_SPECIAL_KEYS_1 (fefa)

    fed0  da f3 fe   JC KBD_SCAN_SPECIAL_KEYS_0 (fef3)  ; Check if the pressed key is in column 0

    fed3  07         RLC                        ; Scan Code = b00LLLCCC + 0x20
    fed4  07         RLC
    fed5  07         RLC
    fed6  c6 20      ADI A, 20
    fed8  b4         ORA H

    fed9  fe 5f      CPI A, 5f                  ; Scan code 0x5f matches the space key
    fedb  c2 06 ff   JNZ KBD_SCAN_CHECK_CTRL (ff06)

    fede  3e 20      MVI A, 20                  ; Return the 0x20 (' ') key code

    fee0  e1         POP HL
    fee1  c9         RET

; Lookup table for special keys in column 1
SPECIAL_KEYS_LUT_1:
    fee2  09         db 09                      ; tab
    fee3  0a         db 0a                      ; line feed
    fee4  0d         db 0d                      ; carriage return
    fee5  7f         db 7f                      ; back space (rubout symbol)
    fee6  08         db 08                      ; left arrow
    fee7  19         db 19                      ; up arrow
    fee8  18         db 18                      ; right arrow
    fee9  1a         db 1a                      ; down arrow

; Lookup table for special keys in column 0
SPECIAL_KEYS_LUT_0:
    feea  0c         db 0c                      ; home
    feeb  1f         db 1f                      ; clear screen
    feec  1b         db 1b                      ; Escape (AR2)
    feed  00         db 00                      ; F1
    feee  01         db 01                      ; F2
    feef  02         db 02                      ; F3
    fef0  03         db 03                      ; F4
    fef1  04         db 04                      ; F5
    fef2  05         db 05                      ; ???

KBD_SCAN_SPECIAL_KEYS_0:
    fef3  7c         MOV A, H                   ; Load lookup table address for keys in column 0
    fef4  21 ea fe   LXI HL, feea

    fef7  c3 fe fe   JMP KBD_SCAN_SPECIAL_KEYS (fefe)

KBD_SCAN_SPECIAL_KEYS_1:
    fefa  7c         MOV A, H                   ; Load lookup table address for keys in column 1
    fefb  21 e2 fe   LXI HL, SPECIAL_KEYS_LUT_1 (fee2)

KBD_SCAN_SPECIAL_KEYS:
    fefe  85         ADD L                      ; Select the char code in the lookup table (calculate address)
    feff  6f         MOV L, A

    ff00  7e         MOV A, M                   ; Get the char code

    ff01  fe 40      CPI A, 40                  ; Codes < 0x40 returned as is
    ff03  e1         POP HL
    ff04  d8         RC

    ff05  e5         PUSH HL

KBD_SCAN_CHECK_CTRL:
    ff06  6f         MOV L, A                   ; Save scan code for now

    ff07  3a 02 80   LDA KBD_PORT_C (8002)
    ff0a  67         MOV H, A

    ff0b  e6 40      ANI A, 40
    ff0d  c2 1a ff   JNZ KBD_SCAN_CHECK_RUS (ff1a)

    ff10  7d         MOV A, L                   ; Ctrl key can apply only for chars > 0x40 (letters)
    ff11  fe 40      CPI A, 40
    ff13  fa 3f ff   JM KBD_SCAN_NORMAL_CHAR (ff3f)

    ff16  e6 1f      ANI A, 1f                  ; Correct the key code so that it is in 0x01-0x1f range
    ff18  e1         POP HL
    ff19  c9         RET

KBD_SCAN_CHECK_RUS:
    ff1a  3a 06 76   LDA CYRILLIC_ENABLED (7606); Check if we are in cyrillic mode
    ff1d  b7         ORA A
    ff1e  ca 2a ff   JZ KBD_SCAN_CHECK_SHIFT (ff2a)

    ff21  7d         MOV A, L                   ; Only letters (char > 0x40) can be converted to cyrillic
    ff22  fe 40      CPI A, 40
    ff24  fa 2a ff   JM KBD_SCAN_CHECK_SHIFT (ff2a)

    ff27  f6 20      ORI A, 20                  ; Convert the char to cyrillic char
    ff29  6f         MOV L, A

KBD_SCAN_CHECK_SHIFT:
    ff2a  7c         MOV A, H
    ff2b  e6 20      ANI A, 20
    ff2d  c2 3f ff   JNZ KBD_SCAN_NORMAL_CHAR (ff3f)

    ff30  7d         MOV A, L                   ; Check if the symbol is a letter (char code > 0x40)
    ff31  fe 40      CPI A, 40
    ff33  fa 3b ff   JM KBD_SCAN_CHECK_SHIFT_1 (ff3b)

    ff36  7d         MOV A, L                   ; Convert latin letters to cyrillic, and vice versa
    ff37  ee 20      XRI A, 20
    ff39  e1         POP HL
    ff3a  c9         RET

KBD_SCAN_CHECK_SHIFT_1:
    ff3b  7d         MOV A, L                   ; Convert char 0x3x to 0x2x
    ff3c  e6 2f      ANI A, 2f
    ff3e  6f         MOV L, A

KBD_SCAN_NORMAL_CHAR:
    ff3f  7d         MOV A, L                   ; Symbols with codes >= 0x40 returnes as is
    ff40  fe 40      CPI A, 40
    ff42  e1         POP HL
    ff43  f0         RP

    ff44  e5         PUSH HL                    ; We are here if the code is >= 0x20 and < 0x40
    ff45  6f         MOV L, A
    ff46  e6 0f      ANI A, 0f                  ; This code detects symbol in 0x2c-0x2f or 0x3c-0x3f ranges
    ff48  fe 0c      CPI A, 0c
    ff4a  7d         MOV A, L
    ff4b  fa 50 ff   JM KBD_SCAN_EXIT_2 (ff50)

    ff4e  ee 10      XRI A, 10                  ; Toggle the bit so that 0x2x becomes 0x3x and vice versa

KBD_SCAN_EXIT_2:
    ff50  e1         POP HL                     ; Return the resulting key code
    ff51  c9         RET


????:
ff52  2a 31 76   LHLD MEMORY_TOP (7631)
ff55  c9         RET
????:
ff56  22 31 76   SHLD MEMORY_TOP (7631)
ff59  c9         RET

HELLO_STR:
    ff5a  1f 72 61 64 69 6f 2d 38       db 0x1f, "РАДИО-8"
    ff62  36 72 6b 00                   db "6РК", 0x00


PROMPT_STR:
    ff66  0d 0a 2d 2d 3e 00             db 0x0d, 0x0a, "-->", 0x00

TAB_STR:
    ff6c  0d 0a 18 18 18 18 00          db 0x0d, 0x0a, 0x18, 0x18, 0x18, 0x18, 0x00

REGISTERS_STR:
    ff73  0d 0a 20 50 43 2d     db 0x0d, 0x0a, " PC-"
    ff79  0d 0a 20 48 4c 2d     db 0x0d, 0x0a, " HL-"
    ff7f  0d 0a 20 42 43 2d     db 0x0d, 0x0a, " BC-"
    ff85  0d 0a 20 44 45 2d     db 0x0d, 0x0a, " DE-"
    ff8b  0d 0a 20 53 50 2d     db 0x0d, 0x0a, " SP-"
    ff91  0d 0a 20 41 46 2d     db 0x0d, 0x0a, " AF-"
    ff97  19 19 19 19 19 19 00  db 0x19, 0x19, 0x19, 0x19, 0x19, 0x19, 0x00 ; 6 lines up

BACKSPACE_STR:
    ff9e  08 20 08 00          db 0x08, 0x20, 0x08, 0x00    ; Literally a back space: print a space on the left

BREAKPOINT:
ffa2  22 16 76   SHLD USER_HL (7616)
ffa5  f5         PUSH PSW
ffa6  e1         POP HL
ffa7  22 1e 76   SHLD 761e
ffaa  e1         POP HL
ffab  2b         DCX HL
ffac  22 14 76   SHLD 7614
ffaf  21 00 00   LXI HL, 0000
????:
ffb2  39         DAD SP
ffb3  31 1e 76   LXI SP, 761e
ffb6  e5         PUSH HL
ffb7  d5         PUSH DE
ffb8  c5         PUSH BC
ffb9  2a 14 76   LHLD 7614
ffbc  31 cf 76   LXI SP, STACK_TOP (76cf)
ffbf  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)
ffc2  eb         XCHG
ffc3  2a 23 76   LHLD 7623
ffc6  cd 90 f9   CALL COMPARE_DE_HL (f990)
ffc9  c2 6c f8   JNZ MAIN_LOOP (f86c)
ffcc  3a 25 76   LDA ORIGINAL_OPCODE (7625)
ffcf  77         MOV M, A
ffd0  c3 6c f8   JMP MAIN_LOOP (f86c)


; Command X - Dump CPU registers
;
; Print 6 register pairs stored at addresses 7614-761f (in the order of PC, HL, BC, DE, SP, AF).
; Allow the User to enter a new register value.
COMMAND_X:
    ffd3  21 73 ff   LXI HL, REGISTERS_STR (ff73)   ; Print the registers string
    ffd6  cd 22 f9   CALL PRINT_STR (f922)

    ffd9  21 14 76   LXI HL, 7614               ; Print 6 registers starting the PC
    ffdc  06 06      MVI B, 06

COMMAND_X_LOOP:
    ffde  5e         MOV E, M                   ; Load the next register value in DE
    ffdf  23         INX HL
    ffe0  56         MOV D, M

    ffe1  c5         PUSH BC                    ; Print the register pair
    ffe2  e5         PUSH HL
    ffe3  eb         XCHG
    ffe4  cd 78 fb   CALL PRINT_HEX_ADDR (fb78)

    ffe7  cd ee f8   CALL INPUT_LINE (f8ee)     ; Enter the new register value
    ffea  d2 f6 ff   JNC COMMAND_X_NEXT (fff6)  ; Advance to the next register if no value was entered

    ffed  cd 5a f9   CALL PARSE_ADDR (f95a)     ; Parse the value

    fff0  d1         POP DE                     ; Restore the register address in HL
    fff1  d5         PUSH DE
    fff2  eb         XCHG

    fff3  72         MOV M, D                   ; Store the new value
    fff4  2b         DCX HL
    fff5  73         MOV M, E

COMMAND_X_NEXT:
    fff6  e1         POP HL                     ; Restore registers
    fff7  c1         POP BC

    fff8  05         DCR B                      ; Advance to the next register
    fff9  23         INX HL                     ; Repeat until all 6 registers are printed
    fffa  c2 de ff   JNZ COMMAND_X_LOOP (ffde)

    fffd  c9         RET                        ; Exit

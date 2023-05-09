;
;
; Important variables:
; f7b0 - Current cursor position (offset from video memory start address)
; f7b2 - Current cursor position (memory address)
; f7f8 - Flag indicating that the next char will be cursor direct movement coordinate
VECTORS:                                        ; Jump vectors to real function implementations
    f800  c3 36 f8   JMP START (f836)
    f803  c3 57 fd   JMP KBD_INPUT (fd57)
    f806  c3 71 fb   JMP fb71
    f809  c3 43 fc   JMP PUT_CHAR_C (fc43)

f800                                      c3 ee fb c3
f810  43 fc c3 6b fe c3 2e fc          c3 9a fd c3 72
    f818  c3 1f f9   JMP PRINT_STR (f91f)
f820  fa c3 76 fa c3 ad fa c3 24 fb c3 f6 fa c9 ff ff
f830  c3 77 fe c3 7b fe 

START:
    f836  3e 8b      MVI A, 8b                  ; Configure 8255 keyboard matrix controller as
    f838  d3 04      OUT 04                     ; port A - output, ports B and C - input (all mode 0).

    f83a  3e 82      MVI A, 82                  ; ????????????
    f83c  d3 fb      OUT fb
    No IO registered for address 0xfb
    
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

    f861  21 2a 1d   LXI HL, 1d2a
    f864  22 cf f7   SHLD f7cf

    f867  3e c3      MVI A, c3
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
    f88b  ca 00 f0   JZ COMMAND_U (f000)

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
; - When nothing is entered, the carry flag will not reset. The carry flag is set when something is in the
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

fa20  cd 51 fb cd b3 f9 e5 cd eb f8 e1 d2 35 fa e5 cd
fa30  57 f9 7d e1 77 23 c3 20 fa cd 8d f9 ca 54 fa eb
fa40  22 c3 f7 7e 32 c5 f7 36 f7 3e c3 32 30 00 21 bb
fa50  fe 22 31 00 31 b8 f7 c1 d1 e1 f1 f9 2a b6 f7 c3
fa60  c6 f7 7c d3 fa 7d d3 f9 db f8 02 03 cd 96 f9 c3
fa70  65 fa 2a b0 f7 c9 e5 2a b0 f7 7e e1 c9 3a cd f7
fa80  b7 ca 88 fa 7b 32 cf f7 cd ad fa cd 51 fb eb cd
fa90  51 fb eb c5 cd f6 fa 60 69 cd 51 fb d1 cd 8d f9
faa0  c8 eb cd 51 fb                         3e ff cd

BAD_INPUT:
    faa5  3e 3f      MVI A, 3f                  ; Print '?'
    faa7  cd 42 fc   CALL PUT_CHAR_A (fc42)
    faaa  c3 6c f8   JMP ENTER_NEXT_COMMAND (f86c)

fab0  df fa e5 09 eb cd dd fa e1 09 eb e5 cd ea fa 3e
fac0  ff cd df fa e1 c9 06 00 70 23 7c fe f0 c2 c8 fa
fad0  d1 e1 c9 1f 1a 2a 60 74 2f 38 38 2a 00 3e 08 cd

HELLO_STR:
    fad3 1f          db 1f                      # Clear screen  
    fad4 1a          db 1a                      # Move to the second line
    fad5 2a 60 74 2f 38 38 2a 00     db "*ЮТ/88*", 0x00    # Hello string

fae0  71 fb 47 3e 08 cd 71 fb 4f c9 3e 08 cd 71 fb 77
faf0  cd 96 f9 c3 ea fa 01 00 00 7e 81 4f d2 00 fb 04

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

fb00                          79 b7 ca 10 fb 32 d0 f7
fb10  e5 cd f6 fa e1 cd 51 fb eb cd 51 fb eb e5 60 69
fb20  cd 51 fb e1 c5 01 00 00 cd ee fb 05 e3 e3 c2 28
fb30  fb 0e e6 cd ee fb cd 69 fb eb cd 69 fb eb cd 5f
fb40  fb 21 00 00 cd 69 fb 0e e6 cd ee fb e1 cd 69 fb
fb50  c9                                           4e

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


fb60  cd ee fb cd 96 f9 c3 5f fb 4c cd ee fb 4d c3 ee
fb70  fb c3 69 ff 57 21 00 00 39 31 00 00 22 c0 f7 0e
fb80  00 db a1 e6 01 5f f1 79 e6 7f 07 4f 26 00 25 ca
fb90  df fb f1 db a1 e6 01 bb ca 8e fb b1 4f 15 3a cf
fba0  f7 c2 a6 fb d6 12 47 f1 05 c2 a7 fb 14 db a1 e6
fbb0  01 5f 7a b7 f2 d0 fb 79 fe e6 c2 c4 fb af 32 ce
fbc0  f7 c3 ce fb fe 19 c2 86 fb 3e ff 32 ce f7 16 09
fbd0  15 c2 86 fb 2a c0 f7 f9 3a ce f7 a9 c3 70 ff 2a
fbe0  c0 f7 f9 7a b7 f2 a5 fa cd a1 f9 c3 75 fb c3 77
fbf0  ff f5 21 00 00 39 31 00 00 16 08 f1 79 07 4f 3e
fc00  01 a9 d3 a1 00 3a d0 f7 47 f1 05 c2 09 fc 3e 00
fc10  a9 d3 a1 00 15 3a d0 f7 c2 1d fc d6 0e 47 f1 05
fc20  c2 1e fc 14 15 c2 fb fb f9 f1 c3 70 ff c9

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

fe60           db 06 e6 80 c2 63 fe c9 

IS_BUTTON_PRESSED:
    fe6b  af         XRA A                      ; Select all scan column at once
    fe6c  d3 07      OUT 07

    fe6e  db 06      IN 06                      ; Get button state
    fe70  2f         CMA
    fe71  e6 7f      ANI 7f
    fe73  c8         RZ                         ; Return A=00 if no buttons pressed

    fe74  f6 ff      ORI ff                     ; Return A=ff if a button is pressed
    fe76  c9         RET

fe70                       2a d1 f7 c9 22 d1 f7 c9 0d

PROMPT_STR:
    fe7f 0d 0a 18    db '\r\n', 0x18            ; Move to the next line, then step right
    fe82 3d 3e 00    db "=>", 0x00
...

TAB_STR:
    fe85 0d 0a 18    db '\r\n', 0x18
    fe88 18 18 18 00 db 0x18, 0x18, 0x18, 0x00

fe80                                      0d 0a 20 50
fe90  43 2d 0d 0a 20 48 4c 2d 0d 0a 20 42 43 2d 0d 0a
fea0  20 44 45 2d 0d 0a 20 53 50 2d 0d 0a 20 41 46 2d
feb0  19 19 19 19 19 19 00 08 20 08 00 22 b6 f7 f5 e1

BACKSPACE_STR:
    feb7  08 20 08 00   db 0x08, ' ', 0x08, 0x00    ; Clear symbol left to the cursor, move cursor left

fec0  22 be f7 e1 2b 22 b4 f7 21 00 00 39 31 be f7 e5
fed0  d5 c5 2a b4 f7 31 af f7 cd 51 fb eb 2a c3 f7 cd
fee0  8d f9 c2 6c f8 3a c5 f7 77 c3 6c f8 21 8c fe cd
fef0  1f f9 21 b4 f7 06 06 5e 23 56 c5 e5 eb cd 51 fb
ff00  cd eb f8 d2 0f ff cd 57 f9 d1 d5 eb 72 2b 73 e1
ff10  c1 05 23 c2 f7 fe c9 

COMMAND_HANDLER_CONT:
    ff17  fe 42      CPI 42                     ; Handle command 'B'
    ff19  ca f3 ff   JZ COMMAND_B (fff3)

    ff1c  fe 57      CPI 57                     ; Handle command 'W'
    ff1e  ca 00 c0   JZ c000                    ; Jump directly to 0xc000

    ff21  fe 56      CPI 56                     ; Handle command 'V'
    ff23  ca 29 ff   JZ COMMAND_V (ff29)

    ff26  c3 7e ff   JMP COMMAND_HANDLER_CONT_2 (ff7e)

ff20                             f3 21 00 00 01 7a 01
ff30  db a1 a0 5f db a1 a0 bb ca 34 ff 5f db a1 a0 23
ff40  bb ca 3c ff 5f 0d c2 3c ff 29 29 7c b7 fa 5e ff
ff50  2f e6 20 0f 0f 0f 47 0f 1f 80 3c 47 7c 90 32 cf
ff60  f7 fb cd b4 f9 c3 6c f8 ff f3 e5 c5 d5 c3 74 fb
ff70  d1 c1 e1 fb c3 2d fc f3 e5 c5 d5 c3 f1 fb fe 4b

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

ff90                                         ff ff ff
ffa0  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
ffb0  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
ffc0  00 f3 f5 c5 d5 e5 21 f0 ff 11 fd f6 06 03 1a 3c
ffd0  27 12 be c2 de ff af 12 23 13 05 c2 ce ff 2a fe
ffe0  f6 3a fd f6 32 00 90 22 01 90 e1 d1 c1 f1 fb c9
fff0  60 60 24 2a fe c3 3a fd c3 ef df c3 6c f8 00 00
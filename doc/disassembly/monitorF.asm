;
;
; Important variables:
; f7b0 - Current cursor position (offset from video memory start address)
; f7b2 - Current cursor position (memory address)
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

    f86c  31 af f7   LXI SP, f7af
    f86f  21 7f fe   LXI HL, PROMPT_STR (fe7f)
    f872  cd 1f f9   CALL PRINT_STR (f91f)
    
    f875  00         NOP
    f876  00         NOP
    f877  00         NOP
    f878  00         NOP

    f879  cd eb f8   CALL f8eb
...

f870                                      21 6c f8 e5
f880  21 d3 f7 7e fe 58 ca ec fe fe 55 ca 00 f0 f5 cd
f890  29 f9 2a cb f7 4d 44 2a c9 f7 eb 2a c7 f7 f1 fe
f8a0  44 ca bf f9 fe 43 ca d1 f9 fe 46 ca e7 f9 fe 53
f8b0  ca ee f9 fe 54 ca f9 f9 fe 4d ca 20 fa fe 47 ca
f8c0  39 fa fe 49 ca 7d fa fe 4f ca 08 fb fe 4c ca 02
f8d0  fa fe 52 ca 62 fa c3 17 ff 

HANDLE_BACKSPACE:
    f8d9  3e 63      MVI A, 63                  ; ????
    f8db  bd         CMP L
    f8dc  ca ee f8   JZ f8ee

    f8df  e5         PUSH HL                    ; Clear a symbole left to the cursor, move cursor left
    f8e0  21 b7 fe   LXI HL, BACKSPACE_STR (feb7)
    f8e3  cd 1f f9   CALL f91f

    f8e6  e1         POP HL
    f8e7  2b         DCX HL
    f8e8  c3 f0 f8   JMP f8f0

????:
    f8eb  21 d3 f7   LXI HL, f7d3

????:
    f8ee  06 00      MVI B, 00
????:
    f8f0  cd 57 fd   CALL KBD_INPUT (fd57)

    f8f3  fe 08      CPI 08                     ; Handle left arrow button
    f8f5  ca d9 f8   JZ HANDLE_BACKSPACE (f8d9)

    f8f8  fe 7f      CPI 7f                     ; Same as back space
    f8fa  ca d9 f8   JZ HANDLE_BACKSPACE (f8d9)

    f8fd  c4 42 fc   CNZ PUT_CHAR_A (fc42)

....

f900  77 fe 0d ca 17 f9 fe 2e ca 6c f8 06 ff 3e f2 bd
f910  ca a5 fa 23 c3 f0 f8 78 17 11 d3 f7 06 00 c9

; Print a string
; HL - string address (null terminated string)
PRINT_STR:
    f91f  7e         MOV A, M
    f920  a7         ANA A
    f921  c8         RZ
    
    f922  cd 42 fc   CALL PUT_CHAR_A (fc42)
    f925  23         INX HL
    f926  c3 1f f9   JMP PRINT_STR (f91f)


f920                             21 c7 f7 11 cd f7 0e
f930  00 cd e7 f9 11 d4 f7 cd 57 f9 22 c7 f7 22 c9 f7
f940  d8 3e ff 32 cd f7 cd 57 f9 22 c9 f7 d8 cd 57 f9
f950  22 cb f7 d8 c3 a5 fa 21 00 00 1a 13 fe 0d ca 8b
f960  f9 fe 2c c8 fe 20 ca 5a f9 d6 30 fa a5 fa fe 0a
f970  fa 7f f9 fe 11 fa a5 fa fe 17 f2 a5 fa d6 07 4f
f980  29 29 29 29 da a5 fa 09 c3 5a f9 37 c9

CMP_HL_DE:
    f98d  7c         MOV A, H                   ; Compare HL and DE, set Z flag if equal
    f98e  ba         CMP D
    f98f  c0         RNZ
    f990  7d         MOV A, L
    f991  bb         CMP E
    f992  c9         RET

ADVANCE_HL:                                     ; Advance HL until it reaches DE
    f996  cd 8d f9   CALL CMD_HL_DE (f98d)
    f999  c2 9f f9   JNZ ADVANCE_HL_1 (f99f)
    
    f99c  33         INX SP                     ; Exit from the caller function as well
    f99d  33         INX SP
    f99e  c9         RET

ADVANCE_HL_1:
    f99f  23         INX HL
    f9a0  c9         RET


f9a0     3e ff a7 fe 03 c0 c3 a5 fa e5 21 85 fe cd 1f
f9b0  f9 e1 c9 7e c5 cd 2e fc 3e 20 cd 42 fc c1 c9 cd
f9c0  51 fb cd b3 f9 cd 93 f9 7d e6 0f ca bf f9 c3 c2
f9d0  f9 0a be ca e0 f9 cd 51 fb cd b3 f9 0a cd b4 f9
f9e0  03 cd 93 f9 c3 d1 f9                      79 be

; HL    - start address
; DE    - end address
; C     - byte to fill
MEMSET:
    f9e7  71         MOV M, C
    f9e8  cd 96 f9   CALL ADVANCE_HL (f996)
    f9eb  c3 e7 f9   JMP MEMSET (f9e7)


f9f0  cc 51 fb cd 93 f9 c3 ee f9 7e 02 03 cd 96 f9 c3
fa00  f9 f9 cd 51 fb 7e b7 fa 0f fa fe 20 d2 11 fa 3e
fa10  2e cd 42 fc cd 93 f9 7d e6 0f ca 02 fa c3 05 fa
fa20  cd 51 fb cd b3 f9 e5 cd eb f8 e1 d2 35 fa e5 cd
fa30  57 f9 7d e1 77 23 c3 20 fa cd 8d f9 ca 54 fa eb
fa40  22 c3 f7 7e 32 c5 f7 36 f7 3e c3 32 30 00 21 bb
fa50  fe 22 31 00 31 b8 f7 c1 d1 e1 f1 f9 2a b6 f7 c3
fa60  c6 f7 7c d3 fa 7d d3 f9 db f8 02 03 cd 96 f9 c3
fa70  65 fa 2a b0 f7 c9 e5 2a b0 f7 7e e1 c9 3a cd f7
fa80  b7 ca 88 fa 7b 32 cf f7 cd ad fa cd 51 fb eb cd
fa90  51 fb eb c5 cd f6 fa 60 69 cd 51 fb d1 cd 8d f9
faa0  c8 eb cd 51 fb 3e 3f cd 42 fc c3 6c f8 3e ff cd
fab0  df fa e5 09 eb cd dd fa e1 09 eb e5 cd ea fa 3e
fac0  ff cd df fa e1 c9 06 00 70 23 7c fe f0 c2 c8 fa
fad0  d1 e1 c9 1f 1a 2a 60 74 2f 38 38 2a 00 3e 08 cd

HELLO_STR:
    fad3 1f          db 1f                      # Clear screen  
    fad4 1a          db 1a                      # Move to the second line
    fad5 2a 60 74 2f 38 38 2a 00     db "*ЮТ/88*", 0x00    # Hello string

fae0  71 fb 47 3e 08 cd 71 fb 4f c9 3e 08 cd 71 fb 77
faf0  cd 96 f9 c3 ea fa 01 00 00 7e 81 4f d2 00 fb 04
fb00  cd 8d f9 c8 23 c3 f9 fa 79 b7 ca 10 fb 32 d0 f7
fb10  e5 cd f6 fa e1 cd 51 fb eb cd 51 fb eb e5 60 69
fb20  cd 51 fb e1 c5 01 00 00 cd ee fb 05 e3 e3 c2 28
fb30  fb 0e e6 cd ee fb cd 69 fb eb cd 69 fb eb cd 5f
fb40  fb 21 00 00 cd 69 fb 0e e6 cd ee fb e1 cd 69 fb
fb50  c9 c5 cd aa f9 7c cd 2e fc 7d cd b4 f9 c1 c9 4e
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
fc20  c2 1e fc 14 15 c2 fb fb f9 f1 c3 70 ff c9 f5 0f
fc30  0f 0f 0f cd 37 fc f1 e6 0f fe 0a fa 40 fc c6 07
fc40  c6 30 4f e5 c5 d5 f5 2a b2 f7 23 7e e6 7f 77 2b

; Print a char
; A - char to print
PUT_CHAR_A:
    fc42  4f         MOV C, A

; Print a char
; C - char to print
PUT_CHAR_C:
    fc43  e5         PUSH HL
    fc44  c5         PUSH BC
    fc45  d5         PUSH DE
    fc46  f5         PUSH PSW

    fc47  2a b2 f7   LHLD f7b2

    fc4a  23         INX HL                     ; Remove highlight at the cursor location
    fc4b  7e         MOV A, M
    fc4c  e6 7f      ANI 7f
    fc4e  77         MOV M, A

    fc4f  2b         DCX HL

    fc50  11 ba fc   LXI DE, fcba               ; Returning address after a special symbol is processed
    fc53  d5         PUSH DE
    
    fc54  3a f8 f7   LDA f7f8
    fc57  3d         DCR A
    fc58  fa 74 fc   JM fc74
    fc5b  ca 34 fd   JZ fb34
    fc5e  e2 42 fb   JPO fb42

    fc61  79         MOV A, C
    fc62  de 20      SBI 20
    fc64  4f         MOV C, A

???:
    fc65  0d         DCR C
    fc66  fa 6f fc   JM fc6f 
    fc69  cd e2 fc   CALL fce2    
    fc6c  c3 65 fc   JMP fc65

???:

fc60                                               af
fc70  32 f8 f7 c9 

    fc74  79         MOV A, C                   ; 1b - direct cursor movement
    fc75  fe 1b      CPI 1b
    fc77  ca 52 fd   JZ fd52
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
    fca0  c2 b3 fc   JNZ fcb3

???:

fca0           cd 6b fe b7 ca ad fc cd 57 fd cd 19 fd
fcb0  21 bf ee 

????:
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

    fce7  ca d1 fc   JZ fcd1                    ; If reached - move to the topleft position

MOVE_CUR_LEFT:
    fcea  2b         DCX HL                     ; Move cursor left 1 position

    fceb  7c         MOV A, H                   ; Check if it has moved outside of the screen
    fcec  fe e7      CPI e7
    fcee  c0         RNZ

    feef  21 ff ee   LXI HL, eeff               ; If reached - move to the bottom right position
    fef2  c9         RET


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
    fd15  ca a3 fc   JZ fca3
    fd18  c9         RET

fd10  0b fd 7c fe ef ca a3 fc c9 21 40 e8 11 00 e8 7e
fd20  12 13 23 7c fe ef c2 1f fd 21 c0 ee 3e 20 77 2c
fd30  c2 2e fd c9 79 fe 59 c2 6f fc cd d1 fc 3e 02 c3
fd40  70 fc 79 de 20 4f 0d 3e 04 fa 70 fc cd f3 fc c3
fd50  46 fd 3e 01 c3 70 fc e5 d5 c5 3e 7f 32 f3 f7 cd

KBD_INPUT:
    fd57  e5         PUSH HL
    fd58  d5         PUSH DE
    fd59  c5         PUSH BC

    fd5a  3e 7f      MVI A, 7f
    fd5c  32 f3 f7   STA f7f3

?????:
    fd5f  cd 9a fd   CALL SCAN_KBD_STABLE (fd9a)

    fd62  fe ff      CPI ff                     ; Check if something was pressed
    fd64  c2 74 fd   JNZ fd74

    fd67  3e 00      MVI A, 00                  ; ?????
    fd69  32 f3 f7   STA f7f3
    fd6c  3e 00      MVI A, 00
    fd6e  32 f4 f7   STA f7f4

    fd71  c3 5f fd   JMP fd5f                   ; Wait until something is pressed

????:
    fd74  57         MOV D, A

    fd75  3a f4 f7   LDA f7f4
    fd78  a7         ANA A
    fd79  c2 92 fd   JNZ fd92

    fd7c  3a f3 f7   LDA f7f3
    fd7f  a7         ANA A
    fd80  ca 92 fd   JZ fd92

    fd83  3a f3 f7   LDA f7f3
    fd86  3d         DCR A
    fd87  32 f3 f7   STA f7f3

    fd8a  c2 5f fd   JNZ fd5f

    fd8d  3e 01      MVI A, 01
    fd8f  32 f4 f7   STA f7f4

    fd92  cd 4b fe   CALL BEEP (fe4b)

    fd95  7a         MOV A, D
    fd96  c1         POP BC
    fd97  d1         POP DE
    fd98  e1         POP HL
    fd99  c9         RET



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

    fdb1  06 00      MVI B, 00              ; Resulting scan code (button number)
    fdb3  0e fe      MVI C, fe              ; Column mask
    fdb5  16 08      MVI D, 08              ; Columns counter

SCAN_KBD_COLUMN:
    fdb7  79         MOV A, C               ; Out the column mask to port A
    fdb8  d3 07      OUT 07
    fdba  07         RLC                    ; Shift the mask left, prepare for the next column
    fdbb  4f         MOV C, A

    fdbc  db 06      IN 06                  ; Input the column state through port B

    fdbe  e6 7f      ANI 7f                 ; Check if any key is pressed in this column
    fdc0  fe 7f      CPI 7f
    fdc2  c2 df fd   JNZ SCAN_KBP_PRESSED (fddf)

    fdc5  78         MOV A, B               ; Advance scan code by 7
    fdc6  c6 07      ADI 07
    fdc8  47         MOV B, A

    fdc9  15         DCR D                  ; Repeat for the next scan column
    fdca  c2 b7 fd   JNZ SCAN_KBD_COLUMN (fdb7)

    fdcd  db 06      IN 06                  ; It is unclear what shall be connected to the Port B.7
    fdcf  e6 80      ANI 80                 
    fdd1  ca d9 fd   JZ fdd9                ; We should not expect anything there

    fdd4  3e fe      MVI A, fe              ; But if something is connected, then return 0xfe as a
    fdd6  c3 db fd   JMP SCAN_KBD_EXIT (fddb) ; scan code

SCAN_KBD_NOTHING:
    fdd9  3e ff      MVI A, ff              ; Returning 0xff means no button is pressed

SCAN_KBD_EXIT:
    fddb  e1         POP HL                 ; Wrap up and exit
    fddc  d1         POP DE
    fddd  c1         POP BC
    fdde  c9         RET

SCAN_KBP_PRESSED:
    fddf  1f         RAR                    ; Count scan code in B
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

fe60           db 06 e6 80 c2 63 fe c9 af d3 07 db 06
fe70  2f e6 7f c8 f6 ff c9 2a d1 f7 c9 22 d1 f7 c9 0d

PROMPT_STR:
    fe7f 0d 0a 18    db '\r\n', 0x18            ; Move to the next line, then step right
    fe82 3d 3e 00    db "=>", 0x00
...

fe80                 0d 0a 18 18 18 18 00 0d 0a 20 50
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
ff10  c1 05 23 c2 f7 fe c9 fe 42 ca f3 ff fe 57 ca 00
ff20  c0 fe 56 ca 29 ff c3 7e ff f3 21 00 00 01 7a 01
ff30  db a1 a0 5f db a1 a0 bb ca 34 ff 5f db a1 a0 23
ff40  bb ca 3c ff 5f 0d c2 3c ff 29 29 7c b7 fa 5e ff
ff50  2f e6 20 0f 0f 0f 47 0f 1f 80 3c 47 7c 90 32 cf
ff60  f7 fb cd b4 f9 c3 6c f8 ff f3 e5 c5 d5 c3 74 fb
ff70  d1 c1 e1 fb c3 2d fc f3 e5 c5 d5 c3 f1 fb fe 4b
ff80  ca 86 ff c3 6c f8 e5 cd f6 fa e1 cd 51 fb eb cd
ff90  51 fb eb e5 60 69 cd 51 fb e1 c3 6c f8 ff ff ff
ffa0  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
ffb0  ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
ffc0  00 f3 f5 c5 d5 e5 21 f0 ff 11 fd f6 06 03 1a 3c
ffd0  27 12 be c2 de ff af 12 23 13 05 c2 ce ff 2a fe
ffe0  f6 3a fd f6 32 00 90 22 01 90 e1 d1 c1 f1 fb c9
fff0  60 60 24 2a fe c3 3a fd c3 ef df c3 6c f8 00 00
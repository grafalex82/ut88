;
; Variables:
; f75a - Cursor position (pointer within 0xe800-0xef00 range)
; f75c - Delay between bits during input (default value 0x2d)
; f75d - Delay between bits during output (default value 0x20)
; f762 - ???? f83a exit address for ENTER_NEXT_COMMAND
; f778 - time until next key auto-repeat
; f779 - currently pressed character (used for auto-repeat)
; f77a - ???? ff
; f7bb - input line buffer (0x40 bytes)
; f7ff - stack area ????
VECTORS:    
    f800  c3 1b f8   JMP START (f81b)
    f803  c3 6b f8   JMP KBD_INPUT (f86b)
    f806  c3 36 f9   JMP f936
    f809  c3 f0 f9   JMP PUT_CHAR (f9f0)
    f80c  c3 8b f9   JMP OUT_BYTE (f98b)
    f80f  c3 f0 f9   JMP PUT_CHAR (f9f0)
    f812  c3 1f f9   JMP IS_BUTTON_PRESSED (f91f)
    f815  c3 b3 f9   JMP PRINT_BYTE_HEX (f9b3)
    f818  c3 dd f9   JMP PRINT_STRING (f9dd)

START:
    f81b  31 ff f7   LXI SP, f7ff               ; Set up stack

    f81e  3e ff      MVI A, ff                  ; ????
    f820  32 7a f7   STA f77a

    f823  21 2d 20   LXI HL, 202d               ; Set default in/out bit delays
    f826  22 5c f7   SHLD IN_BIT_DELAY (f75c)

    f829  21 3a f8   LXI HL, ENTER_NEXT_COMMAND (f83a)  ; ????
    f82c  22 62 f7   SHLD f762

    f82f  3e 1f      MVI A, 1f                  ; Clear screen
    f831  cd e9 f9   CALL PUT_CHAR_A (f9e9)

    f834  21 78 ff   LXI HL, HELLO_STR (ff78)   ; Print welcome message
    f837  cd dd f9   CALL PRINT_STRING (f9dd)   

ENTER_NEXT_COMMAND:
    f83a  31 ff f7   LXI SP, f7ff               ; Some subroutines will jump directly here. Reset the SP ????

    f83d  3e 8b      MVI A, 8b                  ; Configure 8255 keyboard matrix controller as
    f83f  d3 04      OUT 04                     ; port A - output, ports B and C - input (all mode 0).

    f841  21 93 ff   LXI HL, PROMPT_STR (ff93)  ; Print prompt
    f844  cd dd f9   CALL PRINT_STRING (f9dd)

    f847  e5         PUSH HL                    ; HL shall point to COMMANDS_TABLE
    f848  cd 8b fa   CALL INPUT_LINE (fa8b)

f84b  21 63 f8   LXI HL, f863
f84e  e3         XTHL

f84f  3a 7b f7   LDA f77b
f852  47         MOV B, A

????:
f853  7e         MOV A, M
f854  b7         ORA A
f855  cc b9 fb   CZ fbb9
f858  b8         CMP B

f859  23         INX HL
f85a  5e         MOV E, M
f85b  23         INX HL
f85c  56         MOV D, M

f85d  23         INX HL
f85e  c2 53 f8   JNZ f853

f861  eb         XCHG
f862  e9         PCHL

????:
f863  3b 3b         dw 3b3b
????:
f865  cd 02 ff   CALL ff02
f868  c3 3a f8   JMP ENTER_NEXT_COMMAND (f83a)


; Wait for the keyboard input
;
; This function waits for the keyboard input. The function also handles when the key
; is pressed for some time. In this case repeat mechanism is working, and the key is
; triggered again, until it is released. Each symbol trigger is supported with a short
; beep in a tape port.
;
; For scanning the keyboard, the function sequentally selects one column in the keyboard matrix, by
; setting the corresponding bit in the keyboard 8255 port A. The column scanning is performed by reading
; the port B. If a bit is 0, then the button is pressed.
;
; Here is the keyboard matrix. The header row specifies the column selection bit sent to Port A.
; The left column represent the code read via Port B. 
;
;      |   0xfe   |   0xfd   |   0xfb   |   0xf7   |   0xef   |   0xdf   |   0xbf   |     0x7f     |
; 0xfe | 0x30 '0' | 0x37 '7' | 0x2e '.' | 0x45 'E' | 0x4c 'L' | 0x53 'S' | 0x5a 'Z' | 0x18 right   |
; 0xfd | 0x31 '1' | 0x38 '8' | 0x2f '/' | 0x46 'F' | 0x4d 'M' | 0x54 'T' | 0x5b '[' | 0x08 left    |
; 0xfb | 0x32 '2' | 0x39 '9' | 0x40 '@' | 0x47 'G' | 0x4e 'N' | 0x55 'U' | 0x5c '\' | 0x19 up      |
; 0xf7 | 0x33 '3' | 0x3a ':' | 0x41 'A' | 0x48 'H' | 0x4f 'O' | 0x56 'V' | 0x5d ']' | 0x1a down    |
; 0xef | 0x34 '4' | 0x3b ';' | 0x42 'B' | 0x49 'I' | 0x50 'P' | 0x57 'W' | 0x5e '^' | 0x0d enter   |
; 0xdf | 0x35 '5' | 0x2c ',' | 0x43 'C' | 0x4a 'J' | 0x51 'Q' | 0x58 'X' | 0x5f '_' | 0x1f bkspace |
; 0xbf | 0x36 '6' | 0x2d '-' | 0x44 'D' | 0x4b 'K' | 0x52 'R' | 0x59 'Y' | 0x20 ' ' | 0x0c home    |
; 
; First stage of the algorithm is to detect the scan code (register B) which is essentially an index
; of the pressed button, counting columns left to right, and buttons in the column from top to bottom.
;
; If a button is pressed, then the algorithm starts conversion the scan code (in the 0x00-0x37 range) 
; to a char code. For most of the chars simple addition a 0x30 is enough. Some characters require
; additional character codes remapping.
;
; The final stage of the algorithm is to apply alteration keys (by reading the port C):
; - RUS key - alters letters in the 0x40-0x5f range to russian letters in the 0x60-0x7f range
; - Symbol - alters numeric key and some symbol keys in order to enter another set of symbols (this
;   is an analog of a Shift key on the modern computers, but works only for numeric and symbol keys.
;   Note, that there is no upper and lower case of letters on this computer)
; - Ctrl - alters some keys to produce codes in 0x00 - 0x1f range. This range contains control codes
;   (e.g. cursor movements, as well as some graphics)
;
; Input symbol is returned in A register
KBD_INPUT:
    f86b  e5         PUSH HL                    ; Entry
    f86c  d5         PUSH DE
    f86d  c5         PUSH BC

    f86e  2a 5a f7   LHLD CURSOR_POS (f75a)     ; Calculate cursor position in the video attributes area
    f871  11 01 f8   LXI DE, f801               ; (next char after cursor)
    f874  19         DAD DE
    
    f875  e5         PUSH HL                    ; Save cursor position for later

BLINK_CURSOR_LOOP:
    f876  7e         MOV A, M                   ; Invert the character
    f877  2f         CMA
    f878  77         MOV M, A

SCAN_KEYPRESS_LOOP:
    f879  01 f8 fe   LXI BC, fef8                   ; B - column mask, C - preliminary scan code

    f87c  cd 1f f9   CALL IS_BUTTON_PRESSED (f91f)  ; Blink cursor until a button is pressed
    f87f  c2 91 f8   JNZ SCAN_KBD_COLUMN_LOOP (f891)

    f882  2f         CMA                            ; We get here probably because previous key was released,
    f883  32 79 f7   STA CUR_KBD_CHAR (f779)        ; and we are waiting for a new key. Set key code as 0xff.

    f886  1b         DCX DE                         ; Decrement cursor blinking counter

    f887  7a         MOV A, D                       ; Check if enough time passed, and we need to toggle
    f888  e6 5f      ANI A, 5f                      ; cursor. 0x5f constant provides non-uniform blinking
    f88a  b3         ORA E                          ; (cursor visible just a little period of time). 0x07
    f88b  c2 79 f8   JNZ SCAN_KEYPRESS_LOOP (f879)  ; constant works better under emulation

    f88e  c3 76 f8   JMP BLINK_CURSOR_LOOP (f876)

SCAN_KBD_COLUMN_LOOP:
    f891  11 7f 07   LXI DE, 077f                   ; D - number of keys in a column, E - keypress mask

    f894  79         MOV A, C                       ; Advance to the next column
    f895  82         ADD D
    f896  4f         MOV C, A

    f897  fe 37      CPI A, 37                      ; No button was pressed? Go and wait for key press
    f899  ca 79 f8   JZ SCAN_KEYPRESS_LOOP (f879)

    f89c  78         MOV A, B                       ; Output a column mask
    f89d  d3 07      OUT 07

    f89f  07         RLC                            ; Prepare the next column mask
    f8a0  47         MOV B, A

    f8a1  db 06      IN 06                          ; Input column state, and check whether a key is pressed
    f8a3  a3         ANA E
    f8a4  bb         CMP E
    f8a5  ca 91 f8   JZ SCAN_KBD_COLUMN_LOOP (f891)

SCAN_KBD_ROWS_LOOP:
    f8a8  1f         RAR                            ; Rotate column scanline until we reach pressed key row,
    f8a9  03         INX BC                         ; count scan codes in the same time
    f8aa  da a8 f8   JC SCAN_KBD_ROWS_LOOP (f8a8)

    f8ad  21 f0 f8   LXI HL, KBD_INPUT_SUBMIT_CHAR (f8f0)   ; Return address
    f8b0  e5         PUSH HL

    f8b1  79         MOV A, C                       ; Check if arrows, space, or other special button
    f8b2  01 40 30   LXI BC, 3040                   ; is pressed (button number >= 48)
    f8b5  b8         CMP B
    f8b6  d2 da f8   JNC SCAN_KBD_SPECIAL (f8da)

    f8b9  80         ADD B                      ; RAW scan codes start from 0. Renumber to start from 0x30
    f8ba  fe 3c      CPI A, 3c                  ; Process first 12 keys (0-9, :, ;) returned as is (0x30, 
    f8bc  da c5 f8   JC KBD_INPUT_1 (f8c5)      ; 0x31...)

    f8bf  b9         CMP C                      ; Scan codes over 0x40 also returned as is
    f8c0  d2 c5 f8   JNC KBD_INPUT_1 (f8c5)

    f8c3  e6 2f      ANI A, 2f                  ; Scan codes between 0x3c and 0x3f corrected to 0x2c-0x2f

KBD_INPUT_1:
    f8c5  5f         MOV E, A                   ; Save code in E

    f8c6  db 05      IN 05                      ; Read keyboard modificators in port C

    f8c8  2f         CMA                        ; Invert and mask key modificators, so thay modificator
    f8c9  a2         ANA D                      ; enabled when bit is set

    f8ca  1f         RAR                        ; Rotate to RUS modificator in LSB and Control symb in MSB
    f8cb  1f         RAR
    f8cc  1f         RAR                        ; Shift modificator is in C flag

    f8cd  3c         INR A                      ; Set flags (C remains untouched, and set with RAR 
    f8ce  3d         DCR A                      ; instruction above)

    f8cf  7b         MOV A, E                   ; Restore the symbol value
    f8d0  fa e2 f8   JM SCAN_KBD_CTRL_KEY (f8e2); Jump if Control key is pressed
    f8d3  da e5 f8   JC SCAN_SHIFT_KEYS (f8e5)  ; Jump if Shift key is pressed

    f8d6  c8         RZ                         ; Return symbol as is, if no keys were pressed

    f8d7  f6 20      ORI A, 20                  ; We are here if RUS key is pressed. Just correct the key code,
    f8d9  c9         RET                        ; and exit (Works for key codes >= 0x40, which are letters)

SCAN_KBD_SPECIAL:
    f8da  21 f7 ff   LXI HL, SPECIAL_SYMBOLS_KBD_LUT (fff7) ; Convert scan code to char code by looking at
    f8dd  90         SUB B                          ; the special chars table (note that scan code for space
    f8de  85         ADD L                          ; is 0x30, so this code is subtracted from scan code 
    f8df  6f         MOV L, A                       ; first)

    f8e0  7e         MOV A, M                       ; Read the char code and exit
    f8e1  c9         RET

SCAN_KBD_CTRL_KEY:
    f8e2  e6 1f      ANI A, 1f                      ; Just convert the key code to 0x00-0x1f range
    f8e4  c9         RET

SCAN_SHIFT_KEYS:
    f8e5  b9         CMP C                          ; Letters (scan code >= 0x40) remain unchanged
    f8e6  d0         RNC

    f8e7  5f         MOV E, A                       ; A smart way to convert symbols from 0x20-0x2f range
    f8e8  2f         CMA                            ; to 0x30-0x3f range, and vice versa - from 0x30-0x3f
    f8e9  e6 10      ANI A, 10                      ; to 0x20-0x2f
    f8eb  07         RLC                                
    f8ec  83         ADD E                              
    f8ed  d6 10      SUI A, 10                          
    f8ef  c9         RET

KBD_INPUT_SUBMIT_CHAR:
    f8f0  21 79 f7   LXI HL, CUR_KBD_CHAR (f779); Compare key code with the previous key code, probably
    f8f3  be         CMP M                      ; the key is still pressed

    f8f4  77         MOV M, A                   ; Save char code for keyboard auto-repeat

    f8f5  2b         DCX HL                     ; If the key is still pressed - trigger key auto-repeat
    f8f6  ca 0d f9   JZ TRIGGER_AUTO_REPEAT (f90d)

    f8f9  36 80      MVI M, 80                  ; Start wait timer until the first auto-repeat trigger

BEEP:
    f8fb  06 10      MVI B, 10                  ; Output 0x10 zero bytes as a beep tone
    f8fd  af         XRA A

BEEP_LOOP:
    f8fe  cd 8b f9   CALL OUT_BYTE (f98b)
    f901  05         DCR B
    f902  c2 fe f8   JNZ BEEP_LOOP (f8fe)

    f905  23         INX HL                     ; Restore pressed key code
    f906  7e         MOV A, M

    f907  e1         POP HL                     ; Restore cursor position, echo entered character at cursor
    f908  77         MOV M, A                   ; BUG!!! HL points to the next symbol after cursor. This
                                                ; causes double symbols on the screen. Perhaps it is supposed
                                                ; to write only to the attributes area to remove cursor
                                                ; highlight, but this does not match published hardware
                                                ; schematics (original design does not distinguish between
                                                ; 0xe000 and 0xe800 memory areas, and generate CS signals for
                                                ; both)

    f909  c1         POP BC                     ; Exit
    f90a  d1         POP DE
    f90b  e1         POP HL
    f90c  c9         RET


TRIGGER_AUTO_REPEAT:
    f90d  cd 1f f9   CALL IS_BUTTON_PRESSED (f91f)  ; Check if the key is still pressed
    f910  ca 79 f8   JZ SCAN_KEYPRESS_LOOP (f879)   ; If not - start new keyboard scan loop
                                                    ; BUG!!! HL points to auto-repeat counter at this point
                                                    ; while SCAN_KEYPRESS_LOOP expects HL to point to the
                                                    ; cursor location.

KBD_INPUT_DELAY_LOOP:
    f913  3d         DCR A                          ; Delay loop
    f914  c2 13 f9   JNZ KBD_INPUT_DELAY_LOOP (f913)

    f917  35         DCR M                          ; Continue scanning keyboard while the key is still 
    f918  c2 0d f9   JNZ TRIGGER_AUTO_REPEAT (f90d) ; pressed, until auto-repeat timer is triggered

    f91b  34         INR M                          ; Trigger the key press
    f91c  c3 fb f8   JMP BEEP (f8fb)



; Check if any button is pressed
; Return ff if a button is pressed, 00 otherwise
IS_BUTTON_PRESSED:
    f91f  af         XRA A                      ; Select all scan column at once
    f920  d3 07      OUT 07

    f922  db 06      IN 06                      ; Get button state
    f924  2f         CMA
    f925  e6 7f      ANI A, 7f
    f927  c8         RZ                         ; Return A=00 if no buttons pressed

    f928  f6 ff      ORI A, ff                  ; Return A=ff if a button is pressed
    f92a  c9         RET

; Same as IS_BUTTON_PRESSED, but saves all registers
; Set Z flag in no button pressed, clear Z flag if a button is pressed
IS_BUTTON_PRESSED_SAVE_REGS:
    f92b  c5         PUSH BC
    f92c  f5         PUSH PSW
    f92d  cd 1f f9   CALL IS_BUTTON_PRESSED (f91f)
    f930  c1         POP BC
    f931  78         MOV A, B
    f932  c1         POP BC
    f933  c9         RET

????:
f934  3e 08      MVI A, 08
????:
f936  c5         PUSH BC
f937  d5         PUSH DE
f938  01 00 01   LXI BC, 0100
f93b  5f         MOV E, A
f93c  db a1      IN a1
f93e  a0         ANA B
f93f  57         MOV D, A
????:
f940  79         MOV A, C
f941  e6 7f      ANI A, 7f
f943  07         RLC
f944  4f         MOV C, A
????:
f945  db 05      IN 05
f947  e6 02      ANI A, 02
f949  cc b9 fb   CZ fbb9
f94c  db a1      IN a1
f94e  a0         ANA B
f94f  ba         CMP D
f950  ca 45 f9   JZ f945
f953  b1         ORA C
f954  4f         MOV C, A
f955  3a 5c f7   LDA IN_BIT_DELAY (f75c)
f958  c6 03      ADI A, 03
f95a  1d         DCR E
f95b  13         INX DE
f95c  c2 61 f9   JNZ f961
f95f  d6 0e      SUI A, 0e
????:
f961  3d         DCR A
f962  c2 61 f9   JNZ f961
f965  db a1      IN a1
f967  a0         ANA B
f968  57         MOV D, A
f969  7b         MOV A, E
f96a  b7         ORA A
f96b  f2 80 f9   JP f980
f96e  3e e6      MVI A, e6
f970  b9         CMP C
f971  ca 7a f9   JZ f97a
f974  2f         CMA
f975  b9         CMP C
f976  c2 40 f9   JNZ f940
f979  37         STC
????:
f97a  99         SBB C
f97b  32 59 f7   STA f759
f97e  1e 09      MVI E, 09
????:
f980  1d         DCR E
f981  c2 40 f9   JNZ f940
f984  3a 59 f7   LDA f759
f987  a9         XRA C
f988  d1         POP DE
f989  c1         POP BC
f98a  c9         RET



OUT_BYTE:
    f98b  c5         PUSH BC
    f98c  f5         PUSH PSW

    f98d  0e 10      MVI C, 10                  ; 8 bits, 2 phases for each
    f98f  47         MOV B, A

OUT_NEXT_BIT:
    f990  79         MOV A, C                   ; Perform shift only each odd phase
    f991  e6 01      ANI A, 01

    f993  78         MOV A, B
    f994  c2 98 f9   JNZ OUT_NEXT_BIT_NO_SHIFT (f998)   ; Check if we need to shift
    
    f997  07         RLC                        ; Shift to the next bit

OUT_NEXT_BIT_NO_SHIFT:
    f998  47         MOV B, A                   ; Apply XOR mask for the bit
    f999  a9         XRA C
    f99a  d3 a1      OUT a1                     ; Output the bit

    f99c  3a 5d f7   LDA OUT_BIT_DELAY (f75d)   ; Get the delay between bits
    f99f  c6 03      ADI A, 03

    f9a1  0d         DCR C                      ; Check if C reached zero (but do not change C value)
    f9a2  03         INX BC

    f9a3  c2 a8 f9   JNZ BIT_DELAY_LOOP (f9a8)

    f9a6  d6 0a      SUI A, 0a                  ; Delay between bytes is smaller due to overhead elsewhere

BIT_DELAY_LOOP:
    f9a8  3d         DCR A                      ; Perform bit delay
    f9a9  c2 a8 f9   JNZ BIT_DELAY_LOOP (f9a8)

    f9ac  0d         DCR C                      ; Advance to the next phase
    f9ad  c2 90 f9   JNZ OUT_NEXT_BIT (f990)

    f9b0  f1         POP PSW
    f9b1  c1         POP BC
    f9b2  c9         RET


; Print a byte in A register as a hexadecimal 2-digit value
PRINT_BYTE_HEX:
    f9b3  c5         PUSH BC

    f9b4  cd c0 f9   CALL CONVERT_BYTE_TO_CHARS (f9c0)
    f9b7  cd f0 f9   CALL PUT_CHAR (f9f0)       ; Print high nibble

    f9ba  48         MOV C, B                   ; Print low nibble
    f9bb  cd f0 f9   CALL PUT_CHAR (f9f0)

    f9be  c1         POP BC
    f9bf  c9         RET

; Converts byte in A into 2 printable hex chars in B (low nibble) and C (high nibble)
CONVERT_BYTE_TO_CHARS:
    f9c0  f5         PUSH PSW                   ; Save the byte
    f9c1  47         MOV B, A

    f9c2  07         RLC                        ; Shift it 4 high bits to low bits
    f9c3  07         RLC
    f9c4  07         RLC
    f9c5  07         RLC

    f9c6  cd d1 f9   CALL HEX_TO_CHAR (f9d1)    ; Convert high 4 bits into char in C
    f9c9  4f         MOV C, A

    f9ca  78         MOV A, B                   ; Convert low 4 bits into char in B
    f9cb  cd d1 f9   CALL HEX_TO_CHAR (f9d1)
    f9ce  47         MOV B, A

    f9cf  f1         POP PSW
    f9d0  c9         RET


; Convert low 4 bits of the A register into '0'-'9' or 'A'-'F' symbol in A
HEX_TO_CHAR:
    f9d1  e6 0f      ANI A, 0f                  ; Check if lower 4 bits are less than 0x0a
    f9d3  fe 0a      CPI A, 0a
    f9d5  fa da f9   JM HEX_TO_CHAR_1 (f9da)
    f9d8  c6 07      ADI A, 07                  ; Convert value to 'A'-'F' char

HEX_TO_CHAR_1:
    f9da  c6 30      ADI A, 30                  ; Convert value to '0'-'9' number
    f9dc  c9         RET


; Print NULL-terminated string pointed by HL
PRINT_STRING:
    f9dd  f5         PUSH PSW                   

PRINT_STRING_LOOP:
    f9de  7e         MOV A, M                   ; Load next symbol
    f9df  23         INX HL                    
    f9e0  b7         ORA A
    f9e1  c4 e9 f9   CNZ PUT_CHAR_A (f9e9)      ; If not-zero - print it

    f9e4  c2 de f9   JNZ PRINT_STRING_LOOP (f9de)   ; Repeat until zero is found

    f9e7  f1         POP PSW                    ; Restore and exit
    f9e8  c9         RET

; Print a char in A register
PUT_CHAR_A:
    f9e9  c5         PUSH BC                    ; Move char to C and do regular put char
    f9ea  4f         MOV C, A
    f9eb  cd f0 f9   CALL PUT_CHAR (f9f0)
    f9ee  c1         POP BC
    f9ef  c9         RET

; Print a char in C register
;
; This function puts a char at the cursor location in a terminal mode (including wrapping
; the cursor to the next line, and scrolling the text if the end of screen reached). 
;
; The function is not responsible to show/hide the cursor, just prints a char in the cursor position, and
; moves cursor position 1 position to the right.
;
; The function handles the following special chars:
; 0x08  - Move cursor 1 position left
; 0x0c  - Move cursor to the top left position
; 0x18  - Move cursor 1 position right (scroll screen if necessary)
; 0x19  - Move cursor 1 line up
; 0x1a  - Move cursor 1 line down (scroll screen if necessary)
; 0x1f  - Clear screen
; 0x0d  - Carriage return (surprinsingly this function works like move cursor right)
; 0x0a  - Line Feed (move cusror to the beginning of the next line, scroll if needed)
;
; Important variables:
; f75a - Current cursor position (memory address)
; f77a - ????
PUT_CHAR:
    f9f0  e5         PUSH HL                    ; Save all registers
    f9f1  d5         PUSH DE
    f9f2  c5         PUSH BC
    f9f3  f5         PUSH PSW

PUT_CHAR_1:
    f9f4  21 16 fa   LXI HL, PUT_CHAR_EXIT (fa16)   ; Save exit address on stack
    f9f7  e5         PUSH HL

    f9f8  2a 5a f7   LHLD CURSOR_POS (f75a)     ; Load current cursor position

    f9fb  11 f8 ff   LXI DE, SPECIAL_SYMBOLS (fff8) ; Load pointer to special symbol handlers

PUT_CHAR_LOOK_SPECIAL:
    f9fe  1a         LDAX DE                    ; Compare char to print with entry in special symbols table
    f9ff  b9         CMP C
    fa00  ca 0c fa   JZ PUT_CHAR_SPECIAL (fa0c) ; Print special character with a special handler

    fa03  1c         INR E                      ; Advance to the next char until end of table reached
    fa04  c2 fe f9   JNZ PUT_CHAR_LOOK_SPECIAL (f9fe)

    fa07  71         MOV M, C                   ; Normal chars are just put to the video memory

    fa08  23         INX HL                     ; Advance cursor to the next position

    fa09  c3 39 fa   JMP CHECK_NEED_SCROLL (fa39)

PUT_CHAR_SPECIAL:
    fa0c  7b         MOV A, E                   ; Find special symbol couterpart in offset table
    fa0d  d6 09      SUI A, 09                  ; (See SYMBOL_HANDLERS)
    fa0f  5f         MOV E, A
    fa10  1a         LDAX DE
    
    fa11  5f         MOV E, A                   ; Combine handler address as 0xfa<offset>
    fa12  16 fa      MVI D, fa

    fa14  d5         PUSH DE                    ; Execute the handler
    fa15  c9         RET

PUT_CHAR_EXIT:
    fa16  22 5a f7   SHLD CURSOR_POS (f75a)     ; Save new cursor position

    fa19  f1         POP PSW                    ; Exit
    fa1a  c1         POP BC
    fa1b  d1         POP DE
    fa1c  e1         POP HL
    fa1d  c9         RET


; Clear screen (0x1f) symbol handler
CLEAR_SCREEN:
    fa1e  21 00 e8   LXI HL, e800               ; Set char memory start address
    fa21  11 00 e0   LXI DE, e000               ; And attribute memory start address

CLEAR_SCREEN_LOOP:
    fa24  af         XRA A                      ; Clear char and attribute
    fa25  77         MOV M, A
    fa26  12         STAX DE

    fa27  23         INX HL                     ; Advance to the next symbol
    fa28  13         INX DE

    fa29  7c         MOV A, H                   ; Repeat until reached 0xf000 area
    fa2a  fe f0      CPI A, f0
    fa2c  c2 24 fa   JNZ CLEAR_SCREEN_LOOP (fa24)

; Home Cursor (0x0c) symbol handler
CURSOR_HOME:
    fa2f  21 00 e8   LXI HL, e800               ; Set cursor to the top-left position
    fa32  c9         RET

CURSOR_LEFT:
    fa33  2b         DCX HL                     ; Decrease cursor position

    fa34  7c         MOV A, H                   ; unless it gets out of video memory area
    fa35  fe e7      CPI A, e7
    fa37  c0         RNZ

CURSOR_RIGHT:
CARRIAGE_RETURN:
    fa38  23         INX HL                     ; Increase cursor position

CHECK_NEED_SCROLL:
    fa39  7c         MOV A, H                   ; Did cursor moved out of screen at the bottom?
    fa3a  fe ef      CPI A, ef
    fa3c  ca 5a fa   JZ SCROLL_SCREEN (fa5a)    ; If yes - perform scroll

    fa3f  c9         RET                        ; If not - return safely

CURSOR_UP:
    fa40  11 c0 ff   LXI DE, ffc0               ; Move cursor one line up
    fa43  19         DAD DE

    fa44  7c         MOV A, H                   ; Check if cursor gets out of the screen
    fa45  fe e7      CPI A, e7
    fa47  c0         RNZ                        ; If not - return safely

CURSOR_DOWN:
    fa48  11 40 00   LXI DE, 0040               ; Move cursor one line down
    fa4b  19         DAD DE

    fa4c  c3 39 fa   JMP CHECK_NEED_SCROLL (fa39)

LINE_FEED:
    fa4f  7d         MOV A, L                   ; Move cursor the the first column of the next line
    fa50  e6 c0      ANI A, c0
    fa52  c6 40      ADI A, 40
    fa54  6f         MOV L, A

    fa55  d0         RNC                        ; Advance high byte if needed
    fa56  24         INR H

    fa57  c3 39 fa   JMP CHECK_NEED_SCROLL (fa39)

SCROLL_SCREEN:
    fa5a  f5         PUSH PSW

    fa5b  3a 7a f7   LDA f77a                   ; ????
    fa5e  b7         ORA A
    fa5f  ca 83 fa   JZ fa83

    fa62  11 40 e8   LXI DE, e840               ; Will copy symbols from the second line to the first line
    fa65  21 00 e8   LXI HL, e800               ; This is source and target addresses

SCROLL_LOOP:
    fa68  1a         LDAX DE                    ; Copy symbol
    fa69  77         MOV M, A

    fa6a  13         INX DE                     ; Advance to the next position
    fa6b  23         INX HL

    fa6c  7a         MOV A, D                   ; Check if source address reached 0xef00
    fa6d  fe ef      CPI A, ef
    fa6f  c2 4d fa   JNZ SCROLL_LOOP (fa4d)     ; BUG! Shall be 0xfa68

    fa72  e5         PUSH HL                    ; Clear the last line
    fa73  11 c0 e6   LXI DE, e6c0               ; BUG! Shall be 0xeec0 (works on hardware, though)
    fa76  cd 24 fa   CALL CLEAR_SCREEN_LOOP (fa24)
    fa79  e1         POP HL

SCROLL_PAUSE:
    fa7a  db 05      IN 05                      ; Hold on, while a key is pressed
    fa7c  e6 01      ANI A, 01
    fa7e  ca 7a fa   JZ SCROLL_PAUSE (fa7a)

    fa81  f1         POP PSW                    ; Return
    fa82  c9         RET


????:
fa83  cd 6b f8   CALL KBD_INPUT (f86b)
fa86  cd 1e fa   CALL CLEAR_SCREEN (fa1e)
fa89  f1         POP PSW
fa8a  c9         RET

INPUT_LINE:
    fa8b  e5         PUSH HL
    fa8c  d5         PUSH DE

    fa8d  21 bb f7   LXI HL, f7bb               ; Set buffer address ????
    fa90  0e 40      MVI C, 40                  ; Buffer size ????

????:
    fa92  36 20      MVI M, 20                  ; Fill the buffer with spaces
    fa94  2b         DCX HL
    fa95  0d         DCR C
    fa96  c2 92 fa   JNZ fa92

    fa99  c3 9e fa   JMP fa9e                   ; Continue a little below

?????:
fa9c  e5         PUSH HL
fa9d  d5         PUSH DE

????:
    fa9e  cd 6b f8   CALL KBD_INPUT (f86b)      ; Input a character

    faa1  fe 19      CPI A, 19                  ; Special characters like cursor up/down, and carriage return
    faa3  ca 3e fb   JZ INPUT_LINE_EOL (fb3e)   ; are processed separately
    faa6  fe 1a      CPI A, 1a                  
    faa8  ca 3e fb   JZ INPUT_LINE_EOL (fb3e)
    faab  fe 0d      CPI A, 0d
    faad  ca 3e fb   JZ INPUT_LINE_EOL (fb3e)

    fab0  11 9e fa   LXI DE, fa9e               ; Push next cycle address
    fab3  d5         PUSH DE

    fab4  fe 08      CPI A, 08                  ; Handle backspace
    fab6  ca 62 fb   JZ INPUT_LINE_BACKSPACE (fb62)

    fab9  fe 18      CPI A, 18                  ; Handle cursor right
    fabb  ca e3 fa   JZ INPUT_LINE_RIGHT (fae3)

    fabe  fe 20      CPI A, 20                  ; Handle space
    fac0  ca ec fa   JZ INPUT_LINE_SPACE (faec)

INPUT_LINE_SAVE_CHAR:
    fac3  77         MOV M, A                   ; Store entered character in the buffer

    fac4  fe 0c      CPI A, 0c                  ; Handle home cursor
    fac6  ca 53 fb   JZ INPUT_LINE_HOME_CURSOR (fb53)

    fac9  fe 0a      CPI A, 0a                  ; Handle line feed (skip writing it to the buffer, but echo
    facb  ca d0 fa   JZ INPUT_LINE_ECHO_CHAR_1 (fad0)   ; on screen)

INPUT_LINE_ECHO_CHAR:
    face  fe 1f      CPI A, 1f                  ; Handle clear screen char
INPUT_LINE_ECHO_CHAR_1:
    fad0  cc 67 fc   CZ PRINT_SPACE (fc67)

    fad3  c4 e9 f9   CNZ PUT_CHAR_A (f9e9)      ; Echo character on the screen

    fad6  03         INX BC                     ; Increment buffer pointer and char counter
    fad7  23         INX HL

    fad8  79         MOV A, C                   ; Check if buffer is full
    fad9  fe 40      CPI A, 40
    fadb  c0         RNZ

PRINT_BACKSPACE:
    fadc  2b         DCX HL                     ; Clear the last entered character
    fadd  0b         DCX BC
    fade  3e 08      MVI A, 08
    fae0  c3 e9 f9   JMP PUT_CHAR_A (f9e9)

INPUT_LINE_RIGHT:
    fae3  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; Process if Ctrl key is pressed
    fae6  da 08 fb   JC fb08

    fae9  c3 ce fa   JMP INPUT_LINE_ECHO_CHAR (face); Print the 'move right' symbol, skipping writing to buf

INPUT_LINE_SPACE:
    faec  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; If this is not a control char - process it normally
    faef  d2 c3 fa   JNC INPUT_LINE_SAVE_CHAR (fac3)

faf2  3e 08      MVI A, 08
faf4  81         ADD C
faf5  fe 40      CPI A, 40
faf7  d0         RNC
faf8  e6 f8      ANI A, f8

????:
fafa  f5         PUSH PSW
fafb  3e 18      MVI A, 18
fafd  cd e9 f9   CALL PUT_CHAR_A (f9e9)
fb00  23         INX HL
fb01  03         INX BC
fb02  f1         POP PSW
fb03  b9         CMP C
fb04  c2 fa fa   JNZ fafa
fb07  c9         RET

????:
fb08  c5         PUSH BC
fb09  eb         XCHG
fb0a  21 ba f7   LXI HL, f7ba
????:
fb0d  44         MOV B, H
fb0e  4d         MOV C, L
fb0f  0b         DCX BC
fb10  0a         LDAX BC
fb11  77         MOV M, A
fb12  e3         XTHL
fb13  4d         MOV C, L
fb14  e3         XTHL
fb15  e5         PUSH HL
fb16  2a 5a f7   LHLD CURSOR_POS (f75a)
fb19  7d         MOV A, L
fb1a  c6 40      ADI A, 40
fb1c  91         SUB C
fb1d  6f         MOV L, A
fb1e  e3         XTHL
fb1f  3e bb      MVI A, bb
fb21  95         SUB L
fb22  4f         MOV C, A
fb23  e3         XTHL
fb24  7d         MOV A, L
fb25  91         SUB C
fb26  6f         MOV L, A
fb27  44         MOV B, H
fb28  4d         MOV C, L
fb29  0b         DCX BC
fb2a  0a         LDAX BC
fb2b  77         MOV M, A
fb2c  e1         POP HL
fb2d  2b         DCX HL
fb2e  cd d3 fb   CALL fbd3
fb31  c2 0d fb   JNZ fb0d
fb34  c1         POP BC
fb35  36 20      MVI M, 20
fb37  2a 5a f7   LHLD CURSOR_POS (f75a)
fb3a  36 20      MVI M, 20
fb3c  eb         XCHG
fb3d  c9         RET

INPUT_LINE_EOL:
    fb3e  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; ?????

    fb41  36 0d      MVI M, 0d                  ; Put EOL mark to the buffer
    fb43  23         INX HL
    fb44  03         INX BC

    fb45  cd 67 fc   CALL PRINT_SPACE (fc67)    ; Fill current symbol with space
    fb48  d1         POP DE
    fb49  e1         POP HL
    fb4a  c9         RET


CHECK_CTRL_KEY:
    fb4b  47         MOV B, A                   ; Read Port C modificator keys
    fb4c  db 05      IN 05

    fb4e  1f         RAR                        ; Set C flag if Ctrl key is pressed
    fb4f  1f         RAR
    fb50  3f         CMC

    fb51  78         MOV A, B                   ; Restore A register
    fb52  c9         RET


INPUT_LINE_HOME_CURSOR:
    fb53  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; home screen is not a Ctrl-l combination - print it normally
    fb56  d2 d0 fa   JNC INPUT_LINE_ECHO_CHAR_1 (fad0)

INPUT_LINE_CLEAR_LINE_LOOP:
    fb59  79         MOV A, C                   ; We are here if Ctrl-L pressed. Check if we are already
    fb5a  b7         ORA A                      ; at the beginning of the line
    fb5b  c8         RZ

    fb5c  cd dc fa   CALL PRINT_BACKSPACE (fadc); If not - print backspaces until we are at the beginning of
    fb5f  c3 59 fb   JMP INPUT_LINE_CLEAR_LINE_LOOP (fb59)  ; the line

INPUT_LINE_BACKSPACE:
    fb62  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; Check if this really a backspace, and not Ctrl-H
    fb65  da 6e fb   JC fb6e

    fb68  79         MOV A, C                   ; Do not allow moving beyond the left buffer end
    fb69  b7         ORA A
    fb6a  c2 dc fa   JNZ PRINT_BACKSPACE (fadc) ; If there is room to go - print the backspace symbol 
    fb6d  c9         RET                        ; (actually just move cursor left)

????:
fb6e  e5         PUSH HL
fb6f  2b         DCX HL
????:
fb70  23         INX HL
fb71  23         INX HL
fb72  7e         MOV A, M
fb73  2b         DCX HL
fb74  77         MOV M, A
fb75  7d         MOV A, L
fb76  d6 7b      SUI A, 7b
fb78  e5         PUSH HL
fb79  2a 5a f7   LHLD CURSOR_POS (f75a)
fb7c  85         ADD L
fb7d  91         SUB C
fb7e  6f         MOV L, A
fb7f  54         MOV D, H
fb80  5d         MOV E, L
fb81  13         INX DE
fb82  1a         LDAX DE
fb83  77         MOV M, A
fb84  e1         POP HL
fb85  7d         MOV A, L
fb86  fe b9      CPI A, b9
fb88  c2 70 fb   JNZ fb70
fb8b  e1         POP HL
fb8c  c9         RET
fb8d  33         INX SP
fb8e  33         INX SP


; Indicate error on input: produce a long beep, and print '?' char
INPUT_ERROR:
    fb8f  e5         PUSH HL
    fb90  d5         PUSH DE
    fb91  c5         PUSH BC
    fb92  f5         PUSH PSW

    fb93  af         XRA A              ; Output zero byte 0x80 times (long beep)
    fb94  01 3f 80   LXI BC, 803f       ; Also put '?' char code to C

INPUT_ERROR_LOOP:
    fb97  cd 8b f9   CALL OUT_BYTE (f98b)   ; Out beep byte
    fb9a  05         DCR B
    fb9b  c2 97 fb   JNZ BEEP_ERROR_LOOP (fb97)

    fb9e  c3 f4 f9   JMP PUT_CHAR_1 (f9f4)



fba1  cd 6b fc   CALL fc6b
fba4  e5         PUSH HL
fba5  60         MOV H, B
fba6  69         MOV L, C
fba7  cd ab fb   CALL fbab
fbaa  e1         POP HL
????:
fbab  cd 4d fc   CALL fc4d
fbae  7e         MOV A, M
????:
fbaf  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3)
fbb2  cd 67 fc   CALL PRINT_SPACE (fc67)
fbb5  cd 2b f9   CALL IS_BUTTON_PRESSED_SAVE_REGS (f92b)
fbb8  c8         RZ
????:
fbb9  cd 8f fb   CALL INPUT_ERROR (fb8f)
fbbc  c3 65 f8   JMP f865
????:
fbbf  cd c6 fb   CALL fbc6
fbc2  dc b9 fb   CC fbb9
fbc5  c9         RET
????:
fbc6  11 7c f7   LXI DE, f77c
????:
fbc9  cd d9 fb   CALL fbd9
fbcc  2a 51 f7   LHLD f751
fbcf  eb         XCHG
fbd0  2a 53 f7   LHLD f753
????:
fbd3  7c         MOV A, H
fbd4  ba         CMP D
fbd5  c0         RNZ
fbd6  7d         MOV A, L
fbd7  bb         CMP E
fbd8  c9         RET
????:
fbd9  cd 04 fc   CALL fc04
fbdc  cd f4 fb   CALL fbf4
fbdf  c8         RZ
fbe0  cd 04 fc   CALL fc04
fbe3  cd f7 fb   CALL fbf7
fbe6  c8         RZ
fbe7  cd 04 fc   CALL fc04
fbea  cd fa fb   CALL fbfa
fbed  c8         RZ
fbee  cd 04 fc   CALL fc04
fbf1  c3 00 fc   JMP fc00
????:
fbf4  22 51 f7   SHLD f751
????:
fbf7  22 53 f7   SHLD f753
????:
fbfa  22 55 f7   SHLD f755
fbfd  21 00 00   LXI HL, 0000
????:
fc00  22 57 f7   SHLD f757
fc03  c9         RET
????:
fc04  cd 0b fc   CALL fc0b
fc07  dc b9 fb   CC fbb9
fc0a  c9         RET
????:
fc0b  21 00 00   LXI HL, 0000
????:
fc0e  1a         LDAX DE
fc0f  13         INX DE
fc10  fe 20      CPI A, 20
fc12  ca 0e fc   JZ fc0e
fc15  fe 0d      CPI A, 0d
fc17  c8         RZ
fc18  fe 30      CPI A, 30
fc1a  3f         CMC
fc1b  d0         RNC
fc1c  fe 3a      CPI A, 3a
fc1e  da 25 fc   JC fc25
fc21  fe 40      CPI A, 40
fc23  3f         CMC
fc24  d0         RNC
????:
fc25  cd 36 fc   CALL fc36
fc28  d8         RC
fc29  29         DAD HL
fc2a  d8         RC
fc2b  29         DAD HL
fc2c  d8         RC
fc2d  29         DAD HL
fc2e  d8         RC
fc2f  29         DAD HL
fc30  d8         RC
fc31  85         ADD L
fc32  6f         MOV L, A
fc33  c3 0e fc   JMP fc0e
????:
fc36  d6 30      SUI A, 30
fc38  f8         RM
fc39  fe 0a      CPI A, 0a
fc3b  3f         CMC
fc3c  f8         RM
fc3d  fe 11      CPI A, 11
fc3f  f8         RM
fc40  fe 17      CPI A, 17
fc42  3f         CMC
fc43  f0         RP
fc44  d6 07      SUI A, 07
fc46  c9         RET
fc47  cd 6b fc   CALL fc6b
fc4a  2a 51 f7   LHLD f751
????:
fc4d  f5         PUSH PSW
fc4e  7c         MOV A, H
fc4f  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3)
fc52  7d         MOV A, L
fc53  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3)

PRINT_SPACE_POP_PSW:
    fc56  3e 20      MVI A, 20

PRINT_CHAR_POP_PSW:
    fc58  cd e9 f9   CALL PUT_CHAR_A (f9e9)
    fc5b  f1         POP PSW
    fc5c  c9         RET

fc5d  2a 51 f7   LHLD f751
????:
fc60  cd 4d fc   CALL fc4d
fc63  7e         MOV A, M
fc64  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3)

PRINT_SPACE:
    fc67  f5         PUSH PSW
    fc68  c3 56 fc   JMP PRINT_SPACE_POP_PSW (fc56)

????:
fc6b  f5         PUSH PSW
fc6c  3e 0a      MVI A, 0a
fc6e  c3 58 fc   JMP PRINT_CHAR_POP_PSW (fc58)
fc71  cd 38 fe   CALL COMMAND_K_CRC (fe38)
fc74  3a 57 f7   LDA f757
fc77  b7         ORA A
fc78  ca 7e fc   JZ fc7e
fc7b  32 5d f7   STA OUT_BIT_DELAY (f75d)
????:
fc7e  af         XRA A
fc7f  6f         MOV L, A
????:
fc80  cd 8b f9   CALL OUT_BYTE (f98b)
fc83  2d         DCR L
fc84  c2 80 fc   JNZ fc80
fc87  3e e6      MVI A, e6
fc89  cd 8b f9   CALL OUT_BYTE (f98b)
fc8c  3a 52 f7   LDA f752
fc8f  67         MOV H, A
fc90  cd 8b f9   CALL OUT_BYTE (f98b)
fc93  3a 51 f7   LDA f751
fc96  6f         MOV L, A
fc97  cd 8b f9   CALL OUT_BYTE (f98b)
fc9a  3a 54 f7   LDA f754
fc9d  52         MOV D, D
fc9e  cd 8b f9   CALL OUT_BYTE (f98b)
fca1  3a 53 f7   LDA f753
fca4  5b         MOV E, E
fca5  cd 8b f9   CALL OUT_BYTE (f98b)
????:
fca8  7e         MOV A, M
fca9  cd 8b f9   CALL OUT_BYTE (f98b)
fcac  23         INX HL
fcad  cd d3 fb   CALL fbd3
fcb0  c2 a8 fc   JNZ fca8
fcb3  79         MOV A, C
fcb4  cd 8b f9   CALL OUT_BYTE (f98b)
fcb7  78         MOV A, B
fcb8  cd 8b f9   CALL OUT_BYTE (f98b)
fcbb  3e 20      MVI A, 20
fcbd  32 5d f7   STA OUT_BIT_DELAY (f75d)
fcc0  c9         RET
????:
fcc1  cd b5 fd   CALL fdb5
fcc4  11 7c f7   LXI DE, f77c
fcc7  1a         LDAX DE
fcc8  fe 59      CPI A, 59
fcca  c0         RNZ
fccb  13         INX DE
fccc  c3 b0 fd   JMP fdb0
fccf  cd c1 fc   CALL fcc1
fcd2  d5         PUSH DE
fcd3  cd c9 fb   CALL fbc9
fcd6  d1         POP DE
fcd7  1a         LDAX DE
fcd8  eb         XCHG
fcd9  01 08 fd   LXI BC, fd08
fcdc  c5         PUSH BC
fcdd  06 ff      MVI B, ff
fcdf  ca 4b fd   JZ fd4b
fce2  fe 20      CPI A, 20
fce4  2a 51 f7   LHLD f751
????:
fce7  78         MOV A, B
fce8  ca 3f fd   JZ fd3f
fceb  cd 36 f9   CALL f936
fcee  bc         CMP H
fcef  c2 e7 fc   JNZ fce7
fcf2  cd 34 f9   CALL f934
fcf5  bd         CMP L
fcf6  c2 e7 fc   JNZ fce7
fcf9  cd 34 f9   CALL f934
fcfc  ba         CMP D
fcfd  c2 e7 fc   JNZ fce7
fd00  cd 34 f9   CALL f934
fd03  bb         CMP E
fd04  c2 e7 fc   JNZ fce7
fd07  c9         RET
????:
fd08  13         INX DE
fd09  e5         PUSH HL
fd0a  cd ab fd   CALL fdab
fd0d  c2 9a fd   JNZ fd9a
????:
fd10  cd 34 f9   CALL f934
fd13  77         MOV M, A
fd14  23         INX HL
fd15  cd d3 fb   CALL fbd3
fd18  c2 10 fd   JNZ fd10
????:
fd1b  cd 34 f9   CALL f934
fd1e  4f         MOV C, A
fd1f  cd 34 f9   CALL f934
fd22  47         MOV B, A
????:
fd23  e1         POP HL
fd24  c5         PUSH BC
fd25  cd 4d fc   CALL fc4d
fd28  1b         DCX DE
fd29  eb         XCHG
fd2a  cd 4d fc   CALL fc4d
fd2d  cd 43 fe   CALL fe43
fd30  cd 3b fe   CALL fe3b
fd33  eb         XCHG
fd34  c1         POP BC
fd35  cd 3b fe   CALL fe3b
fd38  cd d3 fb   CALL fbd3
fd3b  c4 b9 fb   CNZ fbb9
fd3e  c9         RET
????:
fd3f  cd 36 f9   CALL f936
fd42  cd 34 f9   CALL f934
fd45  cd 34 f9   CALL f934
fd48  c3 34 f9   JMP f934
????:
fd4b  fe 20      CPI A, 20
fd4d  c2 57 fd   JNZ fd57
fd50  23         INX HL
fd51  7e         MOV A, M
fd52  fe 0d      CPI A, 0d
fd54  c2 82 fd   JNZ fd82
????:
fd57  7e         MOV A, M
fd58  fe 0d      CPI A, 0d
fd5a  ca 70 fd   JZ fd70
????:
fd5d  78         MOV A, B
fd5e  cd 36 f9   CALL f936
fd61  ba         CMP D
fd62  c2 5d fd   JNZ fd5d
fd65  cd 34 f9   CALL f934
fd68  bb         CMP E
fd69  c2 5d fd   JNZ fd5d
fd6c  eb         XCHG
fd6d  c3 79 fd   JMP fd79
????:
fd70  78         MOV A, B
fd71  cd 36 f9   CALL f936
fd74  67         MOV H, A
fd75  cd 34 f9   CALL f934
fd78  6f         MOV L, A
????:
fd79  cd 34 f9   CALL f934
fd7c  57         MOV D, A
fd7d  cd 34 f9   CALL f934
fd80  5f         MOV E, A
fd81  c9         RET
????:
fd82  78         MOV A, B
fd83  cd 36 f9   CALL f936
fd86  2f         CMA
fd87  67         MOV H, A
fd88  cd 34 f9   CALL f934
fd8b  2f         CMA
fd8c  6f         MOV L, A
fd8d  23         INX HL
fd8e  cd 34 f9   CALL f934
fd91  19         DAD DE
fd92  47         MOV B, A
fd93  cd 34 f9   CALL f934
fd96  4f         MOV C, A
fd97  09         DAD BC
fd98  eb         XCHG
fd99  c9         RET
????:
fd9a  cd 34 f9   CALL f934
fd9d  be         CMP M
fd9e  c2 ba fd   JNZ fdba
fda1  23         INX HL
fda2  cd d3 fb   CALL fbd3
fda5  c2 9a fd   JNZ fd9a
fda8  c3 1b fd   JMP fd1b
????:
fdab  3a ff f7   LDA f7ff
fdae  b7         ORA A
fdaf  c9         RET
????:
fdb0  af         XRA A
????:
fdb1  32 ff f7   STA f7ff
fdb4  c9         RET
????:
fdb5  af         XRA A
fdb6  3d         DCR A
fdb7  c3 b1 fd   JMP fdb1
????:
fdba  cd af fb   CALL fbaf
fdbd  cd ab fb   CALL fbab
fdc0  cd 8f fb   CALL INPUT_ERROR (fb8f)
fdc3  c3 23 fd   JMP fd23
fdc6  7d         MOV A, L
fdc7  93         SUB E
fdc8  6f         MOV L, A
fdc9  7c         MOV A, H
fdca  9a         SBB D
fdcb  67         MOV H, A
fdcc  c9         RET
fdcd  cd bf fb   CALL fbbf
fdd0  c4 b9 fb   CNZ fbb9
????:
fdd3  cd 6b fc   CALL fc6b
fdd6  cd 60 fc   CALL fc60
fdd9  cd 1d fe   CALL fe1d
fddc  cd 8b fa   CALL INPUT_LINE (fa8b)
fddf  fe 1a      CPI A, 1a
fde1  ca 0d fe   JZ fe0d
fde4  fe 19      CPI A, 19
fde6  c2 ed fd   JNZ fded
fde9  2b         DCX HL
fdea  c3 d3 fd   JMP fdd3
????:
fded  11 7b f7   LXI DE, f77b
fdf0  1a         LDAX DE
fdf1  fe 0d      CPI A, 0d
fdf3  ca 0d fe   JZ fe0d
fdf6  fe 20      CPI A, 20
fdf8  ca 0d fe   JZ fe0d
fdfb  fe 27      CPI A, 27
fdfd  ca 11 fe   JZ fe11
fe00  e6 d0      ANI A, d0
fe02  c8         RZ
fe03  e5         PUSH HL
fe04  cd 04 fc   CALL fc04
fe07  c4 b9 fb   CNZ fbb9
fe0a  7d         MOV A, L
fe0b  e1         POP HL
fe0c  77         MOV M, A
????:
fe0d  23         INX HL
fe0e  c3 d3 fd   JMP fdd3
????:
fe11  13         INX DE
fe12  1a         LDAX DE
fe13  fe 0d      CPI A, 0d
fe15  ca d3 fd   JZ fdd3
fe18  77         MOV M, A
fe19  23         INX HL
fe1a  c3 11 fe   JMP fe11
????:
fe1d  e5         PUSH HL
fe1e  cd 28 fe   CALL fe28
fe21  e1         POP HL
fe22  cd f0 f9   CALL PUT_CHAR (f9f0)
fe25  c3 67 fc   JMP PRINT_SPACE (fc67)
????:
fe28  0e 5f      MVI C, 5f
fe2a  b7         ORA A
fe2b  c8         RZ
fe2c  f8         RM
fe2d  21 f8 ff   LXI HL, SPECIAL_SYMBOLS (fff8)
????:
fe30  be         CMP M
fe31  c8         RZ
fe32  2c         INR L
fe33  c2 30 fe   JNZ fe30
fe36  4f         MOV C, A
fe37  c9         RET

COMMAND_K_CRC:
fe38  cd 40 fe   CALL fe40
????:
fe3b  60         MOV H, B
fe3c  69         MOV L, C
fe3d  c3 4d fc   JMP fc4d
????:
fe40  cd bf fb   CALL fbbf
????:
fe43  23         INX HL
fe44  01 00 00   LXI BC, 0000
????:
fe47  1a         LDAX DE
fe48  81         ADD C
fe49  4f         MOV C, A
fe4a  3e 00      MVI A, 00
fe4c  88         ADC B
fe4d  47         MOV B, A
fe4e  13         INX DE
fe4f  cd d3 fb   CALL fbd3
fe52  c2 47 fe   JNZ fe47
fe55  c9         RET
fe56  21 3a f8   LXI HL, ENTER_NEXT_COMMAND (f83a)
fe59  e5         PUSH HL
????:
fe5a  cd 6b fc   CALL fc6b
fe5d  21 64 f7   LXI HL, f764
fe60  11 e8 ff   LXI DE, ffe8
????:
fe63  1a         LDAX DE
fe64  b7         ORA A
fe65  ca 7e fe   JZ fe7e
fe68  cd e9 f9   CALL PUT_CHAR_A (f9e9)
fe6b  3e 3d      MVI A, 3d
fe6d  cd e9 f9   CALL PUT_CHAR_A (f9e9)
fe70  23         INX HL
fe71  7e         MOV A, M
fe72  23         INX HL
fe73  e5         PUSH HL
fe74  66         MOV H, M
fe75  6f         MOV L, A
fe76  cd 4d fc   CALL fc4d
fe79  e1         POP HL
fe7a  13         INX DE
fe7b  c3 63 fe   JMP fe63
????:
fe7e  cd 8b fa   CALL INPUT_LINE (fa8b)
fe81  3a 7b f7   LDA f77b
fe84  fe 0d      CPI A, 0d
fe86  c8         RZ
fe87  cd c6 fb   CALL fbc6
fe8a  21 e8 ff   LXI HL, ffe8
fe8d  11 65 f7   LXI DE, f765
????:
fe90  3a 7b f7   LDA f77b
fe93  be         CMP M
fe94  ca a6 fe   JZ fea6
fe97  23         INX HL
fe98  13         INX DE
fe99  13         INX DE
fe9a  7b         MOV A, E
fe9b  fe 6f      CPI A, 6f
fe9d  c2 90 fe   JNZ fe90
fea0  cd 8f fb   CALL INPUT_ERROR (fb8f)
fea3  c3 7e fe   JMP fe7e
????:
fea6  2a 51 f7   LHLD f751
fea9  7d         MOV A, L
feaa  12         STAX DE
feab  13         INX DE
feac  7c         MOV A, H
fead  12         STAX DE
feae  c3 5a fe   JMP fe5a
feb1  3e c3      MVI A, c3
feb3  32 50 f7   STA f750
feb6  cd c1 fc   CALL fcc1
feb9  cd c9 fb   CALL fbc9
febc  ca ed fe   JZ feed
febf  2a 53 f7   LHLD f753
fec2  22 73 f7   SHLD f773
fec5  7e         MOV A, M
fec6  32 71 f7   STA f771
fec9  eb         XCHG
feca  2a 55 f7   LHLD f755
fecd  22 75 f7   SHLD f775
fed0  7e         MOV A, M
fed1  32 72 f7   STA f772
fed4  3a 57 f7   LDA f757
fed7  32 77 f7   STA f777
feda  3e ff      MVI A, ff
fedc  77         MOV M, A
fedd  12         STAX DE
fede  3e c3      MVI A, c3
fee0  32 38 00   STA 0038
fee3  21 23 ff   LXI HL, ff23
fee6  22 39 00   SHLD 0039
fee9  21 1c ff   LXI HL, ff1c
feec  e5         PUSH HL
????:
feed  cd ab fd   CALL fdab
fef0  c2 50 f7   JNZ f750
????:
fef3  31 65 f7   LXI SP, f765
fef6  f1         POP PSW
fef7  c1         POP BC
????:
fef8  d1         POP DE
fef9  e1         POP HL
fefa  e1         POP HL
fefb  f9         SPHL
fefc  2a 6b f7   LHLD f76b
feff  c3 50 f7   JMP f750
????:
ff02  22 6b f7   SHLD f76b
ff05  e1         POP HL
ff06  e3         XTHL
ff07  2b         DCX HL
ff08  22 6f f7   SHLD f76f
ff0b  f5         PUSH PSW
ff0c  21 04 00   LXI HL, 0004
ff0f  39         DAD SP
ff10  22 6d f7   SHLD f76d
ff13  f1         POP PSW
ff14  e1         POP HL
ff15  31 6b f7   LXI SP, f76b
ff18  d5         PUSH DE
ff19  c5         PUSH BC
ff1a  f5         PUSH PSW
ff1b  e9         PCHL
????:
ff1c  af         XRA A
ff1d  32 77 f7   STA f777
ff20  c3 39 ff   JMP ff39
????:
ff23  cd 02 ff   CALL ff02
ff26  31 fd f7   LXI SP, f7fd
ff29  cd 5a fe   CALL fe5a
ff2c  2a 6f f7   LHLD f76f
ff2f  eb         XCHG
ff30  2a 75 f7   LHLD f775
ff33  cd d3 fb   CALL fbd3
ff36  c2 55 ff   JNZ ff55
????:
ff39  3a 72 f7   LDA f772
ff3c  77         MOV M, A
ff3d  22 51 f7   SHLD f751
ff40  2a 73 f7   LHLD f773
ff43  36 ff      MVI M, ff
ff45  3a 77 f7   LDA f777
ff48  3d         DCR A
ff49  32 77 f7   STA f777
ff4c  3d         DCR A
ff4d  f2 f3 fe   JP fef3
????:
ff50  3a 71 f7   LDA f771
ff53  77         MOV M, A
ff54  c9         RET
????:
ff55  36 ff      MVI M, ff
ff57  2a 73 f7   LHLD f773
ff5a  22 51 f7   SHLD f751
ff5d  cd 50 ff   CALL ff50
ff60  c3 f3 fe   JMP fef3
ff63  0d         DCR C
ff64  0d         DCR C
ff65  79         MOV A, C
ff66  32 7a f7   STA f77a
ff69  c9         RET
ff6a  21 7c f7   LXI HL, f77c
????:
ff6d  7e         MOV A, M
ff6e  fe 0d      CPI A, 0d
ff70  c8         RZ
ff71  cd af fb   CALL fbaf
ff74  23         INX HL
ff75  c3 6d ff   JMP ff6d

HELLO_STR:
    ff78  0a 2a 2a 2a 2a 20 6f 73       db 0x0a, "**** ОС"
    ff80  20 20 20 2a 20 20 20 60       db "   *   Ю"
    ff88  54 2d 38 38 20 2a 2a 2a       db "T-88 ***"
    ff90  2a 0a 00                      db "*", 0x0a, 0x00

PROMPT_STR:
    ff93  0a 60 54 2a 38 38 3e 20       db 0x0a, "ЮТ-88>"
    ff9b  00                            db 0x00

COMMANDS_TABLE:
    ff9c  49 cf fc      db 'I', fccf
    ff9f  4f 71 fc      db 'O', fc71
    ffa2  4d cd fd      db 'M', fdcd
    ffa5  47 b1 fe      db 'G', feb1
    ffa8  58 56 fe      db 'X', fe56
    ffab  4b 38 fe      db 'K', COMMAND_K_CRC (fe38)
    ffae  56 fa c0      db 'V', c0fa
    ffb1  52 63 ff      db 'R', ff63
    ffb4  43 00 c0      db 'C', cc00
    ffb7  44 b5 c0      db 'D', c0b5
    ffba  46 63 c0      db 'F', c063
    ffbd  4a a2 c0      db 'J', c0a2 
    ffc0  48 92 c0      db 'H', c092
    ffc3  54 6a ff      db 'T', ff6a
    ffc6  53 34 c1      db 'S', c134
    ffc9  45 00 cb      db 'E', cb00
    ffcc  41 20 ca      db 'A', ca20
    ffcf  4e c2 ca      db 'N', cac2
    ffd2  40 ad ca      db '@', caad
    ffd5  4c 86 c3      db 'L', c386
    ffd8  57 c2 c3      db 'W', c3c2
    ffdb  5a eb c1      db 'Z', c1eb
    ffde  50 27 c2      db 'P', c227
    ffe1  1f e9 f9      db 0x1f, f9e9
    ffe4  42 00 d8      db 'B', d800
    ffe7  00            db 0x00

????:
ffe8  41         MOV B, C
ffe9  42         MOV B, D
ffea  44         MOV B, H
ffeb  48         MOV C, B
ffec  53         MOV D, E
ffed  4f         MOV C, A

ffee  00         NOP

SYMBOL_HANDLERS:
    ffef  38 33 40 48 38 1e 2f 4f

SPECIAL_SYMBOLS_KBD_LUT:
    fff7  20                                    ; This and the following bytes provide codes for special keys

SPECIAL_SYMBOLS:
    fff8  18 08 19 1a 0d 1f 0c 0a               ; List of special symbols

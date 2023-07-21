;
; Variables:
; f750 - 0xc3 JMP instruction (user in Command G in conjunction with argument 1)
; f751 - 1st argument of the command
; f753 - 2nd argument of the command
; f755 - 3rd argument of the command
; f757 - 4th argument of the command
; f759 - Tape input polarity
; f75a - Cursor position (pointer within 0xe800-0xef00 range)
; f75c - Delay between bits during input (default value 0x2d)
; f75d - Delay between bits during output (default value 0x20)
; f762 - Quick jump address (ENTER_NEXT_COMMAND by default). See Command J
; f765 - User program A/F register value (when stopping at breakpoint)
; f767 - User program BC register value (when stopping at breakpoint)
; f769 - User program DE register value (when stopping at breakpoint)
; f76b - User program HL register value (when stopping at breakpoint)
; f76d - User program SP register value (when stopping at breakpoint)
; f76f - User program PC register value (when stopping at breakpoint)
; f771 - Instruction byte at breakpoint 1 address 
; f772 - Instruction byte at breakpoint 2 address
; f773 - Breakpoint 1 address (Command G)
; f775 - Breakpoint 2 address (Command G)
; f777 - Command G breakpoint counter (Command G)
; f778 - time until next key auto-repeat
; f779 - currently pressed character (used for auto-repeat)
; f77a - 0x00 if scroll is disabled and screen is cleared when page is full. Non-zero enables the scroll
; f77b - input line buffer (0x40 bytes)
; up to f7ff - stack area
; f7ff - command mode (0x00 if 'Y' command alteration is provided, 0xff otherwise)
VECTORS:    
    f800  c3 1b f8   JMP START (f81b)
    f803  c3 6b f8   JMP KBD_INPUT (f86b)
    f806  c3 36 f9   JMP IN_BYTE (f936)
    f809  c3 f0 f9   JMP PUT_CHAR (f9f0)
    f80c  c3 8b f9   JMP OUT_BYTE (f98b)
    f80f  c3 f0 f9   JMP PUT_CHAR (f9f0)
    f812  c3 1f f9   JMP IS_BUTTON_PRESSED (f91f)
    f815  c3 b3 f9   JMP PRINT_BYTE_HEX (f9b3)
    f818  c3 dd f9   JMP PRINT_STRING (f9dd)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; The main monitor function performs the following actions
; - Performs initial set up of the software and hardware
; - Initialize monitor's variables
; - Runs the main loop:
;   - Inputs user command
;   - Finds and executes command handler
;
START:
    f81b  31 ff f7   LXI SP, f7ff               ; Set up stack

    f81e  3e ff      MVI A, ff                  ; Enable scroll
    f820  32 7a f7   STA ENABLE_SCROLL (f77a)

    f823  21 2d 20   LXI HL, 202d               ; Set default in/out bit delays
    f826  22 5c f7   SHLD IN_BIT_DELAY (f75c)

    f829  21 3a f8   LXI HL, ENTER_NEXT_COMMAND (f83a)  ; Set default quick jump address
    f82c  22 62 f7   SHLD QUICK_JUMP_ADDR (f762)

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

    f84b  21 63 f8   LXI HL, COMMAND_EXIT (f863); Save command exit handler (commands will return there)

    f84e  e3         XTHL                       ; Restore pointer to the COMMANDS_TABLE

    f84f  3a 7b f7   LDA f77b                   ; Load the entered command symbol in B
    f852  47         MOV B, A

SEARCH_COMMAND_LOOP:
    f853  7e         MOV A, M                   ; Load the table command symbol in A

    f854  b7         ORA A                      ; If we reached and of the table and still did not handle
    f855  cc b9 fb   CZ REPORT_INPUT_ERROR (fbb9)   ; the command - probably user typed an incorrect string

    f858  b8         CMP B                      ; Compare command symbols

    f859  23         INX HL                     ; Load the command handler address
    f85a  5e         MOV E, M
    f85b  23         INX HL
    f85c  56         MOV D, M

    f85d  23         INX HL                     ; Advance to the next record

    f85e  c2 53 f8   JNZ SEARCH_COMMAND_LOOP (f853) ; Repeat if command does not match

    f861  eb         XCHG                       ; Execute the handler
    f862  e9         PCHL


; All commands will exit at this address. Restart the main loop.
COMMAND_EXIT:
    f863  3b         DCX SP                     ; Restore correct stack pointer value
    f864  3b         DCX SP

RESTART_MAIN_LOOP:
    f865  cd 02 ff   CALL SAVE_REGISTERS (ff02) ; Bugture: On one hand this call saves registers, which
                                                ; allows having a clue where the executed command has failed.
                                                ; (Registers can be evaluated with X command).
                                                ;
                                                ; Another possible feature of this call is to capture 
                                                ; when exiting the user program, to be evalated with X command.
                                                ;
                                                ; At the same time this definitely breaks Command GY break-
                                                ; point workflow - when the program is stopped on a break
                                                ; point, program's registers are saved. Any executed command
                                                ; will corrupt program's registers with this save registers
                                                ; call.

    f868  c3 3a f8   JMP ENTER_NEXT_COMMAND (f83a)  ; Restart main command loop


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Keyboard functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Wait for the keyboard input
;
; This function waits for the keyboard input. The function also handles when the key
; is pressed for some time. In this case auto-repeat mechanism is working, and the key is
; triggered again, until the key is released. Each symbol trigger is supported with a short
; beep in the tape port.
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

; Blink cursor while waiting for a key press
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

; Scan keyboard matrix
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

; Convert scan code to the symbol, apply modifiers
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

; Process special keys (arrows, home, return, etc)
SCAN_KBD_SPECIAL:
    f8da  21 f7 ff   LXI HL, SPECIAL_SYMBOLS_KBD_LUT (fff7) ; Convert scan code to char code by looking at
    f8dd  90         SUB B                          ; the special chars table (note that scan code for space
    f8de  85         ADD L                          ; is 0x30, so this code is subtracted from scan code 
    f8df  6f         MOV L, A                       ; first)

    f8e0  7e         MOV A, M                       ; Read the char code and exit
    f8e1  c9         RET

; Process keys pressed with Ctrl modifier
SCAN_KBD_CTRL_KEY:
    f8e2  e6 1f      ANI A, 1f                      ; Just convert the key code to 0x00-0x1f range
    f8e4  c9         RET

; Process keys presseed with shift modifier
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

; Submit the entered character
KBD_INPUT_SUBMIT_CHAR:
    f8f0  21 79 f7   LXI HL, CUR_KBD_CHAR (f779); Compare key code with the previous key code, probably
    f8f3  be         CMP M                      ; the key is still pressed

    f8f4  77         MOV M, A                   ; Save char code for keyboard auto-repeat

    f8f5  2b         DCX HL                     ; If the key is still pressed - trigger key auto-repeat
    f8f6  ca 0d f9   JZ TRIGGER_AUTO_REPEAT (f90d)

    f8f9  36 80      MVI M, 80                  ; Start wait timer until the first auto-repeat trigger


; Do a short beep, indicating that key is pressed (applies for auto-repeat also)
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


; Handle auto-repeat
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tape functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Receive a byte (8 bits) from the tape, assuming tape input is already synchronized
; Returns received byte in A
IN_BYTE_NO_SYNC:
    f934  3e 08      MVI A, 08                  ; Set number of bits to input


; Receive a byte from tape (synchronize if necessary)
;
; Parameters:
; A - number of bits to receive (typically 8), or 0xff if synchronization is required first.
;
; If the synchronization procedure is required (A=0xff as a parameter), the function will wait for
; a pilot tone, then a synchronization byte (0xe6 or 0x19) to determine polarity. Then the requested
; byte is received. Polarity is stored at 0xf759. Delay between bits is determined with constant at 0xf75c
;
; Returns received byte in A
IN_BYTE:
    f936  c5         PUSH BC
    f937  d5         PUSH DE
    f938  01 00 01   LXI BC, 0100

    f93b  5f         MOV E, A

    f93c  db a1      IN a1                      ; Input a bit into D
    f93e  a0         ANA B
    f93f  57         MOV D, A

IN_BYTE_LOOP:
    f940  79         MOV A, C                   ; Shift output for 1 bit left, freeing LSB for the new bit
    f941  e6 7f      ANI A, 7f
    f943  07         RLC
    f944  4f         MOV C, A

IN_BYTE_WAIT_PHASE_CHANGE_LOOP:
    f945  db 05      IN 05                      ; Check for modification keys activity

    f947  e6 02      ANI A, 02
    f949  cc b9 fb   CZ REPORT_INPUT_ERROR (fbb9)   ; Report an error and stop if Ctrl-key is pressed

    f94c  db a1      IN a1                      ; Wait for the next bit phase
    f94e  a0         ANA B
    f94f  ba         CMP D
    f950  ca 45 f9   JZ IN_BYTE_WAIT_PHASE_CHANGE_LOOP (f945)

    f953  b1         ORA C                      ; Save the bit
    f954  4f         MOV C, A

    f955  3a 5c f7   LDA IN_BIT_DELAY (f75c)    ; Load the bit delay value
    f958  c6 03      ADI A, 03

    f95a  1d         DCR E                      ; Correct delay between bytes
    f95b  13         INX DE
    f95c  c2 61 f9   JNZ IN_BYTE_DELAY_LOOP (f961)
    f95f  d6 0e      SUI A, 0e

IN_BYTE_DELAY_LOOP:
    f961  3d         DCR A                      ; Perform the delay
    f962  c2 61 f9   JNZ IN_BYTE_DELAY_LOOP (f961)

    f965  db a1      IN a1                      ; Receive the next bit, 1st phase
    f967  a0         ANA B
    f968  57         MOV D, A

    f969  7b         MOV A, E                   ; Check if all requested bites have been received
    f96a  b7         ORA A
    f96b  f2 80 f9   JP IN_BYTE_NEXT_BIT (f980)

    f96e  3e e6      MVI A, e6                  ; Check if we received a sync byte during the pilot tone
    f970  b9         CMP C
    f971  ca 7a f9   JZ IN_BYTE_SYNC_POSITIVE (f97a); If yes - use positive polarity

    f974  2f         CMA                        ; Check if we received negated sync byte
    f975  b9         CMP C
    f976  c2 40 f9   JNZ IN_BYTE_LOOP (f940)

    f979  37         STC                        ; Will be using negative polarity

IN_BYTE_SYNC_POSITIVE:
    f97a  99         SBB C                      ; Save the polarity
    f97b  32 59 f7   STA INPUT_POLARITY (f759)
    f97e  1e 09      MVI E, 09

IN_BYTE_NEXT_BIT:
    f980  1d         DCR E                      ; Repeat until all requested bits are received
    f981  c2 40 f9   JNZ IN_BYTE_LOOP (f940)

    f984  3a 59 f7   LDA INPUT_POLARITY (f759)  ; Apply input polarity
    f987  a9         XRA C

    f988  d1         POP DE                     ; Exit
    f989  c1         POP BC
    f98a  c9         RET



; Output a byte to the tape (byte in A)
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
; adjusted with a constant in 0xf75d
;
;                       Example of 0xA5 byte transfer
;      D7=1 |  D6=0 |  D5=1 |  D4=0 |  D3=0 |  D2=1 |  D1=0 |  D0=1 |
;       +---|---+   |   +---|---+   |---+   |   +---|---+   |   +---|
;       |   |   |   |   |   |   |   |   |   |   |   |   |   |   |   |
;    ---+   |   +---|---+   |   +---|   +---|---+   |   +---|---+   |
;           |<--T-->|       |       |       |       |       |       |
;
; Note: The data is output negated, compared to original Monitor0 and MonitorF implementations. This is
; not a problem for the real hardware, as tape input function has a polarity detection mechanism, but this
; code causes problems when running on an emulator - all data bytes must be negated to get original data.
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Console printing functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
; Function has two scrolling modes, depending on f77a flag:
; - If the flag is non-zero, normal scrolling mode is used. When cursor reaches the end of the screen,
;   all the data is moved one screen up, freeing the bottom line for new data
; - If the flag is zero page scroll is used. When cursor reaches the end of the screen, monitor waits a key
;   press to confirm the data is read. Then the screen is wiped out, and data printing starts from the top-
;   left corner.
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
; f77a - 0x00 if scroll is disabled and screen is cleared when page is full. Non-zero enables the scroll
;
; Note: unlike MonitorF implementation, this put char function does not provide direct cursor positioning
; sequence (Esc-Y). Most of UI applications are not compatible with this Monitor because of this.
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

    fa5b  3a 7a f7   LDA ENABLE_SCROLL (f77a)   ; Check if scroll is enabled
    fa5e  b7         ORA A
    fa5f  ca 83 fa   JZ CLEAR_PAGE (fa83)

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


CLEAR_PAGE:
    fa83  cd 6b f8   CALL KBD_INPUT (f86b)      ; Full screen is filled, wait for a key press before clearing
    fa86  cd 1e fa   CALL CLEAR_SCREEN (fa1e)   ; the screen

    fa89  f1         POP PSW                    ; Return
    fa8a  c9         RET



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Console input functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input a line into the buffer
;
; The function prepares a 64-byte buffer, and waits the user to type the data into this buffer. The
; function controls the data buffer from underrun and overrun, does not allow moving cursor outside of
; the buffer area, and does not allow typing more than buffer capacity.
;
; The following special keys and key combinations are handled:
; - Return, up arrow, and down arrow act like submitting the line - 0x0d terminating symbol is added to
;   the buffer, and the function returns. Function does not distinguish between dedicated keys and
;   corresponding Ctrl-M, Ctrl-Y, and Ctrl-Z combinations, which also submit the line. Note that only
;   symbols left to the cursor are submitted.
; - Left and Right arrows are supposed to move cursor left and right respectively. Buffer bounds are
;   respected. Unfortunately the implementation is quite buggy, and symbols are visually corrupted (while
;   are ok in the buffer)
; - Home key adds 0x0c symbol to the buffer, and a space on the screen
; - Ctrl-M (and possibly Ctrl-Home on the hardware) is moving cursor to the first position
; - Ctrl-H (and possibly Ctrl-Left on the hardware) deletes the symbol at cursor position. Other symbols
;   to the right from the cursor are shifted left, and added with a space at the end.
; - Ctrl-X (and possibly Ctrl-Right on the hardware) inserts a space at cursor position. Other symbols
;   to the right from the cursor are shifted right.
; - Ctrl-Space acts as a tab key, and adds spaces until the next tab stop (each 8 chars)
;
; Unfortunately the implementation is quite raw. While it offers reach editing possibilities, left and
; right movements corrupt the symbols on the screen. The user does not actually sees what they are editing.
; Also when user submits the line, only symbols left to the cursor are submitted. If the user types a string
; and decides to edit a few symbols in the middle, return key will submit only a part of the string.
INPUT_LINE:
    fa8b  e5         PUSH HL
    fa8c  d5         PUSH DE

    fa8d  21 bb f7   LXI HL, f77b + 0x40        ; Set address of the buffer end
    fa90  0e 40      MVI C, 40                  ; Set buffer size

INPUT_LINE_CLEAR_BUFFER:
    fa92  36 20      MVI M, 20                  ; Fill the buffer with spaces
    fa94  2b         DCX HL                     ; BUG: it fills address 0xf7bb (1 byte after the buffer,
    fa95  0d         DCR C                      ; but does not fill 0xf77b (beginning of the buffer. Perhaps
    fa96  c2 92 fa   JNZ INPUT_LINE_CLEAR_BUFFER (fa92) ; MVI and DCX instructions shall be swapped)

    fa99  c3 9e fa   JMP INPUT_LINE_LOOP (fa9e) ; Continue a little below

?????:
fa9c  e5         PUSH HL
fa9d  d5         PUSH DE

INPUT_LINE_LOOP:
    fa9e  cd 6b f8   CALL KBD_INPUT (f86b)      ; Input a character

    faa1  fe 19      CPI A, 19                  ; Special characters like cursor up/down, and carriage return
    faa3  ca 3e fb   JZ INPUT_LINE_EOL (fb3e)   ; are processed separately
    faa6  fe 1a      CPI A, 1a                  
    faa8  ca 3e fb   JZ INPUT_LINE_EOL (fb3e)
    faab  fe 0d      CPI A, 0d
    faad  ca 3e fb   JZ INPUT_LINE_EOL (fb3e)

    fab0  11 9e fa   LXI DE, INPUT_LINE_LOOP (fa9e) ; Push next cycle address
    fab3  d5         PUSH DE

    fab4  fe 08      CPI A, 08                  ; Handle cursor left
    fab6  ca 62 fb   JZ INPUT_LINE_LEFT (fb62)

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

INPUT_LINE_MOVE_LEFT:
    fadc  2b         DCX HL                     ; Clear the last entered character
    fadd  0b         DCX BC
    fade  3e 08      MVI A, 08
    fae0  c3 e9 f9   JMP PUT_CHAR_A (f9e9)

INPUT_LINE_RIGHT:
    fae3  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; Process if Ctrl key is pressed
    fae6  da 08 fb   JC INPUT_LINE_INSERT (fb08)

    fae9  c3 ce fa   JMP INPUT_LINE_ECHO_CHAR (face); Print the 'move right' symbol, skipping writing to buf

INPUT_LINE_SPACE:
    faec  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; If this is not a control char - process it normally
    faef  d2 c3 fa   JNC INPUT_LINE_SAVE_CHAR (fac3)

    faf2  3e 08      MVI A, 08                  ; We are here if Ctrl-Space is pressed. Calculate the next
    faf4  81         ADD C                      ; tab stop
    faf5  fe 40      CPI A, 40
    faf7  d0         RNC
    faf8  e6 f8      ANI A, f8

INPUT_LINE_TAB_LOOP:
    fafa  f5         PUSH PSW                   ; Move cursor right. The function does not fill chars in
    fafb  3e 18      MVI A, 18                  ; the tab gap, if there is garbage it will be intact.
    fafd  cd e9 f9   CALL PUT_CHAR_A (f9e9)

    fb00  23         INX HL                     ; Advance in the pointer in the buffer as well
    fb01  03         INX BC

    fb02  f1         POP PSW                    ; Repeat until tab stop is reached
    fb03  b9         CMP C
    fb04  c2 fa fa   JNZ INPUT_LINE_TAB_LOOP (fafa)

    fb07  c9         RET

INPUT_LINE_INSERT:
    fb08  c5         PUSH BC                    ; The following function will copy symbols 1 position further,
    fb09  eb         XCHG                       ; moving right to left till the current cursor position

    fb0a  21 ba f7   LXI HL, f77b + 0x3f (f7ba) ; Get address of last symbol

INPUT_LINE_INSERT_LOOP:
    fb0d  44         MOV B, H                   ; Move to previous symbol
    fb0e  4d         MOV C, L
    fb0f  0b         DCX BC

    fb10  0a         LDAX BC                    ; Copy symbol 1 position further
    fb11  77         MOV M, A

    fb12  e3         XTHL                       ; Restore number of symbols to the left from cursor
    fb13  4d         MOV C, L                   ; (number of valid symbols in the buffer)
    fb14  e3         XTHL

    fb15  e5         PUSH HL                    ; Load the cursor position
    fb16  2a 5a f7   LHLD CURSOR_POS (f75a)

    fb19  7d         MOV A, L                   ; Do some strange calculations to get address of the
    fb1a  c6 40      ADI A, 40                  ; corresponding symbol on the screen
    fb1c  91         SUB C                      ; BUG: address calculations are performed for low byte only.
    fb1d  6f         MOV L, A                   ; Due to byte overflow the resulting address appears 4 line
    fb1e  e3         XTHL                       ; above.

    fb1f  3e bb      MVI A, bb
    fb21  95         SUB L
    fb22  4f         MOV C, A
    fb23  e3         XTHL

    fb24  7d         MOV A, L
    fb25  91         SUB C
    fb26  6f         MOV L, A

    fb27  44         MOV B, H                   ; Copy symbol 1 position further
    fb28  4d         MOV C, L
    fb29  0b         DCX BC
    fb2a  0a         LDAX BC
    fb2b  77         MOV M, A

    fb2c  e1         POP HL                     ; Advance to the previous char
    fb2d  2b         DCX HL

    fb2e  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Check if we reached the current cursor position
    fb31  c2 0d fb   JNZ INPUT_LINE_INSERT_LOOP (fb0d)

    fb34  c1         POP BC                     ; Current position in the buffer is filled with space
    fb35  36 20      MVI M, 20

    fb37  2a 5a f7   LHLD CURSOR_POS (f75a)     ; Current position on the screen is filled with space also
    fb3a  36 20      MVI M, 20

    fb3c  eb         XCHG                       ; Return
    fb3d  c9         RET

INPUT_LINE_EOL:
    fb3e  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; ????? Perhaps is a leftover from some other code

    fb41  36 0d      MVI M, 0d                  ; Put EOL mark to the buffer
    fb43  23         INX HL
    fb44  03         INX BC

    fb45  cd 67 fc   CALL PRINT_SPACE (fc67)    ; Fill current symbol with space
    fb48  d1         POP DE
    fb49  e1         POP HL
    fb4a  c9         RET

; A helper function to check whether Ctrl key is currently pressed
CHECK_CTRL_KEY:
    fb4b  47         MOV B, A                   ; Read Port C modificator keys
    fb4c  db 05      IN 05

    fb4e  1f         RAR                        ; Set C flag if Ctrl key is pressed
    fb4f  1f         RAR
    fb50  3f         CMC

    fb51  78         MOV A, B                   ; Restore A register
    fb52  c9         RET


INPUT_LINE_HOME_CURSOR:
    fb53  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; Home key alone is processed like a space character
    fb56  d2 d0 fa   JNC INPUT_LINE_ECHO_CHAR_1 (fad0)

INPUT_LINE_HOME_LOOP:
    fb59  79         MOV A, C                   ; We are here if Ctrl-L pressed. Check if we are already
    fb5a  b7         ORA A                      ; at the beginning of the line
    fb5b  c8         RZ

    fb5c  cd dc fa   CALL INPUT_LINE_MOVE_LEFT (fadc); If not - move cursor left until the beginning of
    fb5f  c3 59 fb   JMP INPUT_LINE_HOME_LOOP (fb59) ; the line

INPUT_LINE_LEFT:
    fb62  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; Check if this is Ctrl-H key combination (delete)
    fb65  da 6e fb   JC INPUT_LINE_DELETE

    fb68  79         MOV A, C                   ; Do not allow moving beyond the left buffer end
    fb69  b7         ORA A
    fb6a  c2 dc fa   JNZ INPUT_LINE_MOVE_LEFT (fadc); If there is room to go - print the move left symbol 
    fb6d  c9         RET

INPUT_LINE_DELETE:
    fb6e  e5         PUSH HL                    ; Save the current buffer pointer
    fb6f  2b         DCX HL

INPUT_LINE_DELETE_LOOP:
    fb70  23         INX HL                     ; Advance to the next char

    fb71  23         INX HL                     ; Copy next char to the previous char in the buffer
    fb72  7e         MOV A, M
    fb73  2b         DCX HL
    fb74  77         MOV M, A

    fb75  7d         MOV A, L                   ; Calculate chars count up to current cursor position
    fb76  d6 7b      SUI A, 7b

    fb78  e5         PUSH HL
    fb79  2a 5a f7   LHLD CURSOR_POS (f75a)     ; Calculate the position of the last freed character
    fb7c  85         ADD L
    fb7d  91         SUB C
    fb7e  6f         MOV L, A

    fb7f  54         MOV D, H                   ; Copy the next char to the previous char on the screen
    fb80  5d         MOV E, L
    fb81  13         INX DE
    fb82  1a         LDAX DE
    fb83  77         MOV M, A

    fb84  e1         POP HL                     ; Repeat until all characters up to the end of the line are
    fb85  7d         MOV A, L                   ; processed
    fb86  fe b9      CPI A, b9
    fb88  c2 70 fb   JNZ INPUT_LINE_DELETE_LOOP (fb70)

    fb8b  e1         POP HL                     ; Return
    fb8c  c9         RET


????:
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Command line parsing and processing functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Print BC, [BC], then HL, and [HL] registers
PRINT_BC_HL:
    fba1  cd 6b fc   CALL PRINT_NEW_LINE (fc6b) ; New line

    fba4  e5         PUSH HL                    ; Print BC, and a byte pointed by BC
    fba5  60         MOV H, B
    fba6  69         MOV L, C
    fba7  cd ab fb   CALL PRINT_HL_AND_M (fbab)
    fbaa  e1         POP HL

; Print HL, and a byte pointed by HL
PRINT_HL_AND_M:
    fbab  cd 4d fc   CALL PRINT_HL (fc4d)       

; Print a byte pointed by HL
PRINT_MEM_VALUE:
    fbae  7e         MOV A, M

; Print byte in A in hexadecimal form
; Return if no button is pressed, otherwise report an error and restart main command loop
PRINT_BYTE_CHECK_KBD:
    fbaf  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3) ; Print byte hex representation, followed by space
    fbb2  cd 67 fc   CALL PRINT_SPACE (fc67)

    fbb5  cd 2b f9   CALL IS_BUTTON_PRESSED_SAVE_REGS (f92b)    ; Return if no button pressed
    fbb8  c8         RZ

; Report an error, and restart main command loop
REPORT_INPUT_ERROR:
    fbb9  cd 8f fb   CALL INPUT_ERROR (fb8f)
    fbbc  c3 65 f8   JMP RESTART_MAIN_LOOP (f865)



; Parse arguments at the standard command buffer, load arguments into variables and DE/HL registers
; Typically 1st and 2nd arguments are start/end addresses, so the function checks that start address
; is no more than end address, and reports an error if necessary
PARSE_AND_LOAD_ARGUMENTS:
    fbbf  cd c6 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS (fbc6)
    fbc2  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)
    fbc5  c9         RET


; Parse arguments at the standard command buffer, load arguments into variables
; Load 1st and 2nd arguments into DE and HL respectively, Set Z flag if they are equal
DO_PARSE_AND_LOAD_ARGUMENTS:
    fbc6  11 7c f7   LXI DE, f77b + 1 (f77c)

; Parse arguments starting from DE
DO_PARSE_AND_LOAD_ARGUMENTS_ALT:
    fbc9  cd d9 fb   CALL PARSE_ARGUMENTS (fbd9)

; Load argument 1 into DE, argument 2 into HL
LOAD_ARGUMENTS:
    fbcc  2a 51 f7   LHLD ARG_1 (f751)          ; Load 1st argument into DE
    fbcf  eb         XCHG
    fbd0  2a 53 f7   LHLD ARG_2 (f753)          ; Load 2nd argument into HL


; Compare HL and DE register pairs
CMP_HL_DE:
    fbd3  7c         MOV A, H
    fbd4  ba         CMP D
    fbd5  c0         RNZ

    fbd6  7d         MOV A, L
    fbd7  bb         CMP E
    fbd8  c9         RET


; Parse up to 4 arguments, and put values into corresponding variables
PARSE_ARGUMENTS:
    fbd9  cd 04 fc   CALL PARSE_HEX (fc04)      ; Parse 1st argument
    fbdc  cd f4 fb   CALL STORE_ARG_1 (fbf4)
    fbdf  c8         RZ

    fbe0  cd 04 fc   CALL PARSE_HEX (fc04)      ; Parse 2nd argument
    fbe3  cd f7 fb   CALL STORE_ARG_2 (fbf7)
    fbe6  c8         RZ

    fbe7  cd 04 fc   CALL PARSE_HEX (fc04)      ; Parse 3rd argument
    fbea  cd fa fb   CALL STORE_ARG_3 (fbfa)
    fbed  c8         RZ

    fbee  cd 04 fc   CALL PARSE_HEX (fc04)      ; Parse 4th argument
    fbf1  c3 00 fc   JMP STORE_ARG_4 (fc00)


; Store HL as 1st argument. The value is also stored to the next arguments as well
STORE_ARG_1:
    fbf4  22 51 f7   SHLD ARG_1 (f751)

; Store HL as 2nd argument. The value is also stored to the next argument as well
STORE_ARG_2:
    fbf7  22 53 f7   SHLD ARG_2 (f753)

; Store HL as 3rd argument. 4th argument is set to zero
STORE_ARG_3:
    fbfa  22 55 f7   SHLD ARG_3 (f755)
    
    fbfd  21 00 00   LXI HL, 0000

; Store HL as 4th argument
STORE_ARG_4:
    fc00  22 57 f7   SHLD ARG_4 (f757)
    fc03  c9         RET


; Parse hex number (up to 4 digits) at DE into HL
; Report error in case of incorrect data, and restart command input
; Raise Z flag if EOL reached
PARSE_HEX:
    fc04  cd 0b fc   CALL DO_PARSE_HEX (fc0b)
    fc07  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)
    fc0a  c9         RET


; Parse hex number (up to 4 digits) at DE into HL
; Set C flag in case of error, or overflow
; Raise Z flag if EOL reached
DO_PARSE_HEX:
    fc0b  21 00 00   LXI HL, 0000               ; Prepare result accumulator (HL)

DO_PARSE_HEX_LOOP:
    fc0e  1a         LDAX DE                    ; Load next char
    fc0f  13         INX DE

    fc10  fe 20      CPI A, 20                  ; Skip spaces
    fc12  ca 0e fc   JZ DO_PARSE_HEX_LOOP (fc0e)

    fc15  fe 0d      CPI A, 0d                  ; Stop on EOL
    fc17  c8         RZ

    fc18  fe 30      CPI A, 30                  ; Stop for chars < 0x30
    fc1a  3f         CMC
    fc1b  d0         RNC

    fc1c  fe 3a      CPI A, 3a                  ; Symbols in 0x30-0x39 range will be processed little below
    fc1e  da 25 fc   JC DO_PARSE_HEX_1 (fc25)

    fc21  fe 40      CPI A, 40                  ; Skip chars in 0x3a-0x3f range
    fc23  3f         CMC
    fc24  d0         RNC

DO_PARSE_HEX_1:
    fc25  cd 36 fc   CALL PARSE_HEX_DIGIT (fc36); Parse single digit
    fc28  d8         RC

    fc29  29         DAD HL                     ; Shift result right for 4 bits
    fc2a  d8         RC
    fc2b  29         DAD HL
    fc2c  d8         RC
    fc2d  29         DAD HL
    fc2e  d8         RC
    fc2f  29         DAD HL
    fc30  d8         RC

    fc31  85         ADD L                      ; Add parsed digit to lowest 4 bits of result
    fc32  6f         MOV L, A

    fc33  c3 0e fc   JMP DO_PARSE_HEX_LOOP (fc0e)   ; Advance to the next char



; Parse a singe digit in A, and convert it to hex digit in A (lower 4 bits)
; Set C if digit not parsed
; C flag not set - digit parsed successfully
PARSE_HEX_DIGIT:
    fc36  d6 30      SUI A, 30                  ; Subtract '0'
    fc38  f8         RM

    fc39  fe 0a      CPI A, 0a                  ; Digit '0' - '9' are returned as result
    fc3b  3f         CMC
    fc3c  f8         RM

    fc3d  fe 11      CPI A, 11                  ; Ignore 0x3a-0x3f range
    fc3f  f8         RM

    fc40  fe 17      CPI A, 17                  ; Check if the result is 'A' or greater
    fc42  3f         CMC
    fc43  f0         RP

    fc44  d6 07      SUI A, 07                  ; Finally convert to the 'A' - 'F' range
    fc46  c9         RET


; Print command argument #1 in a hex form
PRINT_ARG_1:
    fc47  cd 6b fc   CALL PRINT_NEW_LINE (fc6b)
    fc4a  2a 51 f7   LHLD ARG_1 (f751)


; Print HL (4 digits) and then a space. Suitable for printing addresses, or 16-bit values
PRINT_HL:
    fc4d  f5         PUSH PSW
    fc4e  7c         MOV A, H
    fc4f  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3)
    fc52  7d         MOV A, L
    fc53  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3)

; Print a single space
PRINT_SPACE_POP_PSW:
    fc56  3e 20      MVI A, 20

; Print a char in A, then POP PSW
PRINT_CHAR_POP_PSW:
    fc58  cd e9 f9   CALL PUT_CHAR_A (f9e9)
    fc5b  f1         POP PSW
    fc5c  c9         RET


; Print argument 1 in hex form, and also byte pointed by the argument
PRINT_ARG_1_AND_VALUE:
    fc5d  2a 51 f7   LHLD ARG_1 (f751)

; Print address in HL, and value in [HL]
; Return value in A
PRINT_ADDR_AND_VALUE:
    fc60  cd 4d fc   CALL PRINT_HL (fc4d)
    fc63  7e         MOV A, M
    fc64  cd b3 f9   CALL PRINT_BYTE_HEX (f9b3)

PRINT_SPACE:
    fc67  f5         PUSH PSW
    fc68  c3 56 fc   JMP PRINT_SPACE_POP_PSW (fc56)

PRINT_NEW_LINE:
    fc6b  f5         PUSH PSW
    fc6c  3e 0a      MVI A, 0a
    fc6e  c3 58 fc   JMP PRINT_CHAR_POP_PSW (fc58)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Command handlers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Command O Handler: output a memory range to the tape
;
; Command arguments:
; - Start address
; - End address
; - Offset [Optional] - Despite stated in documentation, this argument is not really processed
; - Speed constant (output bit delay) [Optional]
;
; The function outputs the memory range to the tape in the following format:
; - 256 x 0x00  - pilot tone
; - 0xe6        - Synchronization byte
; - 2 byte      - start address (high byte first)
; - 2 byte      - end address (high byte first)
; - data bytes
; - 2 byte      - Calculated CRC (low byte first)
;
; Note the format is a little bit different, compared to original MonitorF format.
;
COMMAND_O_TAPE_OUTPUT:
    fc71  cd 38 fe   CALL COMMAND_K_CRC (fe38)  ; Parse arguments, and calculate output data CRC

    fc74  3a 57 f7   LDA ARG_4 (f757)           ; Check if output delay is specified
    fc77  b7         ORA A
    fc78  ca 7e fc   JZ TAPE_OUTPUT (fc7e)

    fc7b  32 5d f7   STA OUT_BIT_DELAY (f75d)   ; Save the delay constant

TAPE_OUTPUT:
    fc7e  af         XRA A                      ; Output pilot tone (256 bytes of 0x00)
    fc7f  6f         MOV L, A

TAPE_OUTPUT_PILOT_LOOP:
    fc80  cd 8b f9   CALL OUT_BYTE (f98b)       ; Output next byte of the pilot tone
    fc83  2d         DCR L
    fc84  c2 80 fc   JNZ TAPE_OUTPUT_PILOT_LOOP (fc80)

    fc87  3e e6      MVI A, e6                  ; Output the sync byte
    fc89  cd 8b f9   CALL OUT_BYTE (f98b)

    fc8c  3a 52 f7   LDA ARG_1 + 1 (f752)       ; Output start address (high byte)
    fc8f  67         MOV H, A
    fc90  cd 8b f9   CALL OUT_BYTE (f98b)

    fc93  3a 51 f7   LDA ARG_1 (f751)           ; Output start address (low byte)
    fc96  6f         MOV L, A
    fc97  cd 8b f9   CALL OUT_BYTE (f98b)

    fc9a  3a 54 f7   LDA ARG_2 + 1 (f754)       ; Output end address (high byte)
    fc9d  52         MOV D, D
    fc9e  cd 8b f9   CALL OUT_BYTE (f98b)

    fca1  3a 53 f7   LDA ARG_2 (f753)           ; Output end address (low byte)
    fca4  5b         MOV E, E
    fca5  cd 8b f9   CALL OUT_BYTE (f98b)

TAPE_OUTPUT_LOOP:
    fca8  7e         MOV A, M                   ; Output next byte of the memory range
    fca9  cd 8b f9   CALL OUT_BYTE (f98b)

    fcac  23         INX HL                     ; Repeat until end address is reached
    fcad  cd d3 fb   CALL CMP_HL_DE (fbd3)
    fcb0  c2 a8 fc   JNZ TAPE_OUTPUT_LOOP (fca8)

    fcb3  79         MOV A, C                   ; Save CRC (low byte)
    fcb4  cd 8b f9   CALL OUT_BYTE (f98b)

    fcb7  78         MOV A, B                   ; Save CRC (high byte)
    fcb8  cd 8b f9   CALL OUT_BYTE (f98b)

    fcbb  3e 20      MVI A, 20                  ; Restore the default bit delay
    fcbd  32 5d f7   STA OUT_BIT_DELAY (f75d)
    fcc0  c9         RET



; Set the command mode flag if 'Y' subcommand is NOT specified
PARSE_COMMAND_MODE:
    fcc1  cd b5 fd   CALL SET_COMMAND_MODE_FLAG (fdb5)  ; Set the command mode flag

    fcc4  11 7c f7   LXI DE, f77b + 1 (f77c)    ; Check if 'Y' subcommand is specified
    fcc7  1a         LDAX DE
    fcc8  fe 59      CPI A, 59
    fcca  c0         RNZ

    fccb  13         INX DE                     ; Skip 'Y' in the buffer

    fccc  c3 b0 fd   JMP RESET_COMMAND_MODE_FLAG (fdb0) ; Reset the command mode flag


; Command I: input data from the tape
;
; The function has several variations:
; - I/IY                       - Data start and end addresses are stored on the tape
; - I/IY<addr1>                - Search for addr1 signature on tape, then read addr2 from the tape
; - I/IY<addr1>,<addr2>        - Search addr1/addr2 sequence on the tape
; - I/IY<space><addr1>         - Tape data is loaded to address provided as a parameter
; - I/IY<space><addr1>,<addr2> - Data start and end addresses are specified as parameters. Addr2 can be
;                                used to limit amount of data to be loaded.
;
; The difference between I and IY commands is:
; - 'IY' does normal data input
; - 'I' does not perform data input, only verification against memory range
;
; The function is implemented as 2 distinct phases:
; - Arguments processing. Depending on number arguments provided, and also space modifier presence, the
;   function calculates, or loads start/end addresses from the tape.
; - On the second phase the function performs data import or verification, depending on I vs IY commands.
COMMAND_I_TAPE_INPUT:
    fccf  cd c1 fc   CALL PARSE_COMMAND_MODE (fcc1) ; Parse command mode to distinguish I and IY commands

    fcd2  d5         PUSH DE                    ; Parse command arguments
    fcd3  cd c9 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9)
    fcd6  d1         POP DE

    fcd7  1a         LDAX DE                    ; Load second byte of the command
    fcd8  eb         XCHG

    fcd9  01 08 fd   LXI BC, TAPE_INPUT_PROCESS_DATA (fd08) ; Store next phase handler address
    fcdc  c5         PUSH BC

    fcdd  06 ff      MVI B, ff                  
    fcdf  ca 4b fd   JZ TAPE_INPUT_ARG2_NOT_SET (fd4b)  ; Arg2 (end address) specified? Or Arg1 == Arg2?

    fce2  fe 20      CPI A, 20                  ; Check if there is a space after 'I' command symbol
    fce4  2a 51 f7   LHLD ARG_1 (f751)

TAPE_INPUT_SEARCH_ADDR1_ADDR2:
    fce7  78         MOV A, B                   ; Having space symbol after command will skip loading address
    fce8  ca 3f fd   JZ TAPE_INPUT_SKIP_ADDRESS_FIELDS (fd3f)   ; fields from tape, and use arguments instead

    fceb  cd 36 f9   CALL IN_BYTE (f936)        ; The following instructions search start/end address sequence
    fcee  bc         CMP H                      ; on the tape that match arguments
    fcef  c2 e7 fc   JNZ TAPE_INPUT_SEARCH_ADDR1_ADDR2 (fce7)

    fcf2  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fcf5  bd         CMP L
    fcf6  c2 e7 fc   JNZ TAPE_INPUT_SEARCH_ADDR1_ADDR2 (fce7)

    fcf9  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fcfc  ba         CMP D
    fcfd  c2 e7 fc   JNZ TAPE_INPUT_SEARCH_ADDR1_ADDR2 (fce7)

    fd00  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd03  bb         CMP E
    fd04  c2 e7 fc   JNZ TAPE_INPUT_SEARCH_ADDR1_ADDR2 (fce7)

    fd07  c9         RET


TAPE_INPUT_PROCESS_DATA:
    fd08  13         INX DE                         ; Start second phase of the input algorithm
    fd09  e5         PUSH HL

    fd0a  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; 'IY' command will actually input data from the tape
    fd0d  c2 9a fd   JNZ TAPE_INPUT_VERIFY_DATA (fd9a)  ; 'I' command will just verify the data

TAPE_INPUT_LOAD_DATA:
    fd10  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)    ; Input the next data byte
    fd13  77         MOV M, A

    fd14  23         INX HL                         ; Repeat until reached the end of the memory range
    fd15  cd d3 fb   CALL CMP_HL_DE (fbd3)
    fd18  c2 10 fd   JNZ TAPE_INPUT_LOAD_DATA (fd10)

TAPE_INPUT_LOAD_CRC:
    fd1b  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934); Input CRC bytes (low byte first)
    fd1e  4f         MOV C, A
    fd1f  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd22  47         MOV B, A

TAPE_INPUT_PRINT_RESULTS:
    fd23  e1         POP HL                     ; Print the start address
    fd24  c5         PUSH BC
    fd25  cd 4d fc   CALL PRINT_HL (fc4d)
    
    fd28  1b         DCX DE                     ; Print end address
    fd29  eb         XCHG
    fd2a  cd 4d fc   CALL PRINT_HL (fc4d)

    fd2d  cd 43 fe   CALL CALC_CRC (fe43)       ; Calculate and print memory data CRC
    fd30  cd 3b fe   CALL PRINT_CRC (fe3b)

    fd33  eb         XCHG                       ; Print CRC stored on the tape
    fd34  c1         POP BC
    fd35  cd 3b fe   CALL PRINT_CRC (fe3b)

    fd38  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Report an error if CRC do not match
    fd3b  c4 b9 fb   CNZ REPORT_INPUT_ERROR (fbb9)

    fd3e  c9         RET                        ; End of command processing


TAPE_INPUT_SKIP_ADDRESS_FIELDS:
    fd3f  cd 36 f9   CALL IN_BYTE (f936)        ; Skip stored start and end addresses
    fd42  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd45  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd48  c3 34 f9   JMP IN_BYTE_NO_SYNC (f934)

TAPE_INPUT_ARG2_NOT_SET:
    fd4b  fe 20      CPI A, 20                  ; Check if space after the command is specified
    fd4d  c2 57 fd   JNZ TAPE_INPUT_ARG2_NOT_SET_1 (fd57)

    fd50  23         INX HL                     ; Check if there is EOL symbol right after space
    fd51  7e         MOV A, M
    fd52  fe 0d      CPI A, 0d
    fd54  c2 82 fd   JNZ TAPE_INPUT_APPLY_OFFSET (fd82)

TAPE_INPUT_ARG2_NOT_SET_1:
    fd57  7e         MOV A, M                   ; Have we reached EOL?
    fd58  fe 0d      CPI A, 0d
    fd5a  ca 70 fd   JZ TAPE_INPUT_READ_START_ADDR (fd70)

TAPE_INPUT_SEARCH_ADDR1:
    fd5d  78         MOV A, B                   ; Input start address high byte
    fd5e  cd 36 f9   CALL IN_BYTE (f936)
    
    fd61  ba         CMP D                      ; Compare it with the argument
    fd62  c2 5d fd   JNZ TAPE_INPUT_SEARCH_ADDR1 (fd5d)

    fd65  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934); Input and compare the start address low byte
    fd68  bb         CMP E
    fd69  c2 5d fd   JNZ TAPE_INPUT_SEARCH_ADDR1 (fd5d)

    fd6c  eb         XCHG
    fd6d  c3 79 fd   JMP TAPE_INPUT_READ_END_ADDR (fd79)

TAPE_INPUT_READ_START_ADDR:
    fd70  78         MOV A, B

    fd71  cd 36 f9   CALL IN_BYTE (f936)        ; Read start address into HL
    fd74  67         MOV H, A
    fd75  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd78  6f         MOV L, A

TAPE_INPUT_READ_END_ADDR:
    fd79  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934); Read end address into DE
    fd7c  57         MOV D, A
    fd7d  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd80  5f         MOV E, A
    fd81  c9         RET

TAPE_INPUT_APPLY_OFFSET:
    fd82  78         MOV A, B                   ; Will require sync for the first input byte

    fd83  cd 36 f9   CALL IN_BYTE (f936)        ; Input inverted start addess in HL
    fd86  2f         CMA
    fd87  67         MOV H, A
    fd88  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd8b  2f         CMA
    fd8c  6f         MOV L, A

    fd8d  23         INX HL                     ; HL += 1

    fd8e  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)    ; HL is a difference between argument start address, and
    fd91  19         DAD DE                         ; start address stored on the tape

    fd92  47         MOV B, A                   ; Input end address to BC
    fd93  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934)
    fd96  4f         MOV C, A

    fd97  09         DAD BC                     ; HL = end address + difference
    fd98  eb         XCHG

    fd99  c9         RET


TAPE_INPUT_VERIFY_DATA:
    fd9a  cd 34 f9   CALL IN_BYTE_NO_SYNC (f934); Load the next byte and compare with the memory
    fd9d  be         CMP M
    fd9e  c2 ba fd   JNZ INPUT_DATA_VEFIFY_FAILED (fdba)

    fda1  23         INX HL                     ; Advance to the next byte

    fda2  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Continue until reached the end of data block
    fda5  c2 9a fd   JNZ TAPE_INPUT_VERIFY_DATA (fd9a)

    fda8  c3 1b fd   JMP TAPE_INPUT_LOAD_CRC (fd1b) ; Load CRC and print verification results


; Set Z if command mode flag is not set ('Y' command alteration is provided)
GET_COMMAND_MODE_FLAG:
    fdab  3a ff f7   LDA f7ff                   ; Load the 'command mode' flag
    fdae  b7         ORA A                      ; Set Z if it is not set
    fdaf  c9         RET


; Set command mode
RESET_COMMAND_MODE_FLAG:
    fdb0  af         XRA A                      ; Set 'command mode' flag to 0x00

STORE_COMMAND_MODE_FLAG:
    fdb1  32 ff f7   STA f7ff
    fdb4  c9         RET


; Set command mode
SET_COMMAND_MODE_FLAG:
    fdb5  af         XRA A                      ; Set 'command mode' flag to 0xff
    fdb6  3d         DCR A
    fdb7  c3 b1 fd   JMP STORE_COMMAND_MODE_FLAG (fdb1)


INPUT_DATA_VEFIFY_FAILED:
    fdba  cd af fb   CALL PRINT_BYTE_CHECK_KBD (fbaf)   ; Print byte loaded from the tape

    fdbd  cd ab fb   CALL PRINT_HL_AND_M (fbab) ; Print address, and value in the memory

    fdc0  cd 8f fb   CALL INPUT_ERROR (fb8f)    ; Report the error, and print the input function report
    fdc3  c3 23 fd   JMP TAPE_INPUT_PRINT_RESULTS (fd23)


; HL = HL-DE
HL_SUB_DE:
    fdc6  7d         MOV A, L                   ; Subtract DE from HL
    fdc7  93         SUB E
    fdc8  6f         MOV L, A
    fdc9  7c         MOV A, H
    fdca  9a         SBB D
    fdcb  67         MOV H, A
    fdcc  c9         RET


; Command M: View and edit memory
;
; Usage:
; M <address>
;
; The command lists memory byte at the requested address, its symbol representation, and waits
; for the user input. The user may enter a new hexadecimal value, or even start a symbolic input
; (starting ' single quote symbol). 
;
; Up arrow moves back to the previous address, Down arrow, and empty input move to the next address.
; Non-hexadecimal input stops the command execution.
COMMAND_M_MEM_EDIT:
    fdcd  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)   ; Parse arguments
    fdd0  c4 b9 fb   CNZ REPORT_INPUT_ERROR (fbb9)

MEM_EDIT_LOOP:
    fdd3  cd 6b fc   CALL PRINT_NEW_LINE (fc6b) ; Print address and value starting the new line
    fdd6  cd 60 fc   CALL PRINT_ADDR_AND_VALUE (fc60)

    fdd9  cd 1d fe   CALL PRINT_SYMBOL (fe1d)   ; Display printable version of the byte

    fddc  cd 8b fa   CALL INPUT_LINE (fa8b)     ; Get the new value for the memory cell

    fddf  fe 1a      CPI A, 1a                  ; Down arrow pressed?
    fde1  ca 0d fe   JZ MEM_EDIT_NEXT (fe0d)

    fde4  fe 19      CPI A, 19                  ; Up arrow pressed?
    fde6  c2 ed fd   JNZ MEM_EDIT_PROCESS_INPUT (fded)

    fde9  2b         DCX HL                     ; Up arrow gets back to the previous address
    fdea  c3 d3 fd   JMP MEM_EDIT_LOOP (fdd3)

MEM_EDIT_PROCESS_INPUT:
    fded  11 7b f7   LXI DE, f77b               ; Load entered char
    fdf0  1a         LDAX DE

    fdf1  fe 0d      CPI A, 0d                  ; Return key with no value entered just moves to the next addr
    fdf3  ca 0d fe   JZ MEM_EDIT_NEXT (fe0d)

    fdf6  fe 20      CPI A, 20                  ; Space symbol moves to the next addr
    fdf8  ca 0d fe   JZ MEM_EDIT_NEXT (fe0d)

    fdfb  fe 27      CPI A, 27                  ; Single quote starts symbolic input
    fdfd  ca 11 fe   JZ MEM_EDIT_SYMBOLIC (fe11)

    fe00  e6 d0      ANI A, d0                  ; Non-hex characters stop the input
    fe02  c8         RZ

    fe03  e5         PUSH HL                    ; Parse entered value
    fe04  cd 04 fc   CALL PARSE_HEX (fc04)
    fe07  c4 b9 fb   CNZ REPORT_INPUT_ERROR (fbb9)

    fe0a  7d         MOV A, L
    fe0b  e1         POP HL

    fe0c  77         MOV M, A                   ; Save the value

MEM_EDIT_NEXT:
    fe0d  23         INX HL                     ; Advance to the next byte
    fe0e  c3 d3 fd   JMP MEM_EDIT_LOOP (fdd3)


MEM_EDIT_SYMBOLIC:
    fe11  13         INX DE                     ; Advance to the next input symbol
    fe12  1a         LDAX DE

    fe13  fe 0d      CPI A, 0d                  ; Stop symbolic input on Return key
    fe15  ca d3 fd   JZ MEM_EDIT_LOOP (fdd3)

    fe18  77         MOV M, A                   ; Store symbol as is, without hex->char conversion
    fe19  23         INX HL

    fe1a  c3 11 fe   JMP MEM_EDIT_SYMBOLIC (fe11)



; Print symbol if possible. Non printable and special symbols are printed as '_'
; Argument: A - symbol to print
PRINT_SYMBOL:
    fe1d  e5         PUSH HL                    ; Ensure the symbol is printable, or replace it with '_'
    fe1e  cd 28 fe   CALL GET_PRINTABLE_SYMBOL (fe28)
    fe21  e1         POP HL

    fe22  cd f0 f9   CALL PUT_CHAR (f9f0)       ; Print the symbol

    fe25  c3 67 fc   JMP PRINT_SPACE (fc67)     ; Print a space, and exit


; Get printable symbol for char in A. Special symbols are replaced with '_'. 
; Return symbol in C
GET_PRINTABLE_SYMBOL:
    fe28  0e 5f      MVI C, 5f                  ; Special symbols are printed as '_'

    fe2a  b7         ORA A                      ; Zero and symbols >= 0x80 are special
    fe2b  c8         RZ
    fe2c  f8         RM

    fe2d  21 f8 ff   LXI HL, SPECIAL_SYMBOLS (fff8)
GET_PRINTABLE_SYMBOL_LOOP:
    fe30  be         CMP M                      ; Symbols in special symbols list are also printed with '_'
    fe31  c8         RZ

    fe32  2c         INR L                      ; Iterate till the end of special symbols list
    fe33  c2 30 fe   JNZ GET_PRINTABLE_SYMBOL_LOOP (fe30)

    fe36  4f         MOV C, A                   ; Normal symbols are printed as is
    fe37  c9         RET


COMMAND_K_CRC:
    fe38  cd 40 fe   CALL CALC_CRC_GET_ARGS (fe40)

; Prints the CRC in BC
PRINT_CRC:
    fe3b  60         MOV H, B
    fe3c  69         MOV L, C
    fe3d  c3 4d fc   JMP PRINT_HL (fc4d)

; Perform CRC calculation according to command line arguments
CALC_CRC_GET_ARGS:
    fe40  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)

; Perform CRC calculation for DE-HL memory range
CALC_CRC:
    fe43  23         INX HL                     ; Set the end address to after the desired range

    fe44  01 00 00   LXI BC, 0000               ; Zero result accumulator

CALC_CRC_LOOP:
    fe47  1a         LDAX DE                    ; Add the byte at [DE] to BC
    fe48  81         ADD C
    fe49  4f         MOV C, A
    fe4a  3e 00      MVI A, 00
    fe4c  88         ADC B
    fe4d  47         MOV B, A

    fe4e  13         INX DE                     ; Advance to the next byte

    fe4f  cd d3 fb   CALL CMP_HL_DE (fbd3)      ; Repeat until reached the end of the range
    fe52  c2 47 fe   JNZ CALC_CRC_LOOP (fe47)

    fe55  c9         RET


; Command X: View and edit CPU registers
;
; This command is used in conjunction with Command G (run program) and breakpoint feature. When
; the program stops at the breakpoint, Command X allows viewing and editing CPU registers at
; breakpoint.
;
; As a first step, the function prints all the registers. After the registers are printed, the 
; function waits for the user input in a form <register letter><16-bit hex value> (where register
; letter is one of A, B, D, H, S, O, which correspond to AF, BC, DE, HL, SP, and PC registers)
;
; Note: regular commands are overwriting register values, so X command may be used only immediately
; after breakpoint happened. Even subsequent running of X command will corrumpt register values. Bug?
COMMAND_X_PRINT_REGISTERS:
    fe56  21 3a f8   LXI HL, ENTER_NEXT_COMMAND (f83a)  ; Push return address
    fe59  e5         PUSH HL

PRINT_REGISTERS:
    fe5a  cd 6b fc   CALL PRINT_NEW_LINE (fc6b)

    fe5d  21 64 f7   LXI HL, BREAKPTR_AF_REG - 1 (f764)
    fe60  11 e8 ff   LXI DE, REGISTER_LETTERS (ffe8)

PRINT_REGISTERS_LOOP:
    fe63  1a         LDAX DE                    ; Get the register letter
    fe64  b7         ORA A                      
    fe65  ca 7e fe   JZ PRINT_REGISTERS_EDIT (fe7e) ; Check if we reached end of the list

    fe68  cd e9 f9   CALL PUT_CHAR_A (f9e9)     ; Print register letter

    fe6b  3e 3d      MVI A, 3d                  ; Print '='
    fe6d  cd e9 f9   CALL PUT_CHAR_A (f9e9)

    fe70  23         INX HL                     ; Read register value in HL
    fe71  7e         MOV A, M
    fe72  23         INX HL
    fe73  e5         PUSH HL
    fe74  66         MOV H, M
    fe75  6f         MOV L, A

    fe76  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print register value
    fe79  e1         POP HL

    fe7a  13         INX DE                     ; Repeat for the next register
    fe7b  c3 63 fe   JMP PRINT_REGISTERS_LOOP (fe63)

PRINT_REGISTERS_EDIT:
    fe7e  cd 8b fa   CALL INPUT_LINE (fa8b)     ; Input register editing line

    fe81  3a 7b f7   LDA f77b                   ; Return if nothing is entered
    fe84  fe 0d      CPI A, 0d
    fe86  c8         RZ

    fe87  cd c6 fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbc6)

    fe8a  21 e8 ff   LXI HL, REGISTER_LETTERS (ffe8)
    fe8d  11 65 f7   LXI DE, BREAKPTR_AF_REG (f765)

PRINT_REGISTERS_EDIT_LOOP:
    fe90  3a 7b f7   LDA f77b                   ; Check if the entered letter matches one in the list
    fe93  be         CMP M
    fe94  ca a6 fe   JZ PRINT_REGISTERS_EDIT_EXIT (fea6)

    fe97  23         INX HL                     ; If not - advance to the next letter/register
    fe98  13         INX DE
    fe99  13         INX DE

    fe9a  7b         MOV A, E                   ; Check if we reached the end of the list
    fe9b  fe 6f      CPI A, 6f
    fe9d  c2 90 fe   JNZ PRINT_REGISTERS_EDIT_LOOP (fe90)

    fea0  cd 8f fb   CALL INPUT_ERROR (fb8f)    ; If not register is matched - report an error and exit
    fea3  c3 7e fe   JMP PRINT_REGISTERS_EDIT (fe7e)

PRINT_REGISTERS_EDIT_EXIT:
    fea6  2a 51 f7   LHLD ARG_1 (f751)          ; Store the new register value
    fea9  7d         MOV A, L
    feaa  12         STAX DE
    feab  13         INX DE
    feac  7c         MOV A, H
    fead  12         STAX DE

    feae  c3 5a fe   JMP PRINT_REGISTERS (fe5a) ; Restart print/edit registers loop



; Command G: Run user program
;
; Usage:
; - G <addr>                                    - Run user program from <addr>
; - GY <addr>[, <bp1>[, <bp2>[, <counter>]]]    - Run user program from <addr>, set up to two breakpoints.
;                                                 This command also sets/restores registers previously set by
;                                                 Command X (edit registers) or captured during breakpoint
;                                                 handling. 
;
; To run user program, the function performs the following steps:
; - If 1 or 2 breakpoints are specified, their addresses are stored at 0xf773 and 0xf775.
; - The function places 0xff (RST7 opcode) at breakpoint addresses. Previous values of these memory
;   cells are stored at 0xf771 and 0xf772
; - RST7 handler at 0x0038 address is filled with JMP instruction to the BREAKPOINT_HANDLER function
; - Program is executed via trampoline at 0xf750 (where JMP opcode is placed). The address 0xf751
;   is the command line argument 1
;
; Note: i8080 does not provide any special debug/breakpoint registers. So in order to break the program
; at a specific place the trick is used - instruction at the breakpoint address is replaced with RST7, and
; when breakpoint is triggered the instruction is restored. There is no way to set the same breakpoint
; again immediately, as the program execution must be continued from the restored instruction. This causes
; a few consequences/limitations for the Command G:
; 1) Breakpoints are one-time only. Once breakpoint is triggered the instruction under the breakpoint is
;    restored. It is possible to use 2 separate breakpoints, but once a breakpoint is hit, control flow
;    returns to the monitor, and the program shall be explicitly continued with GY instruction starting
;    the breakpoint address.
; 2) Using breakpoints in a loop is possible, in case if both breakpoints are set within the same loop, 
;    and breakpoints are triggered alternately. In this case 1st breakpoint restores 2nd breakpoint and vice
;    versa. 
;
; In a loop mode a special hit counter (argument 4) can be used to limit number of breakpoint 2 triggers. 
; Typically when breakpoint is fired, the handler prints current registers, and wait for a key press. After
; that user program execution continues. When the counter is over the control flow returns to the Monitor
COMMAND_G_RUN_PROGRAM:
    feb1  3e c3      MVI A, c3                  ; Prepare JMP to the user program trampoline
    feb3  32 50 f7   STA USER_PRG_TRAMPOLINE (f750)

    feb6  cd c1 fc   CALL PARSE_COMMAND_MODE (fcc1) ; Parse arguments
    feb9  cd c9 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9)

    febc  ca ed fe   JZ RUN_PROGRAM_NO_BREAKPOINTS (feed)   ; Skip arg2 processing, if it is not set

    febf  2a 53 f7   LHLD ARG_2 (f753)          ; Store first breakpoint address
    fec2  22 73 f7   SHLD BREAKPOINT1_ADDR (f773)

    fec5  7e         MOV A, M                   ; Store the instruction byte at the breakpoint address
    fec6  32 71 f7   STA BREAKPOINT1_OPCODE (f771)

    fec9  eb         XCHG                       ; Store second breakpoint address
    feca  2a 55 f7   LHLD SHLD ARG_3 (f755)
    fecd  22 75 f7   SHLD BREAKPOINT2_ADDR (f775)

    fed0  7e         MOV A, M                   ; Store the instruction byte at the breakpoint address
    fed1  32 72 f7   STA BREAKPOINT2_OPCODE (f772)

    fed4  3a 57 f7   LDA ARG_4 (f757)           ; Store Arg4 as a breakpoint counter
    fed7  32 77 f7   STA BREAKPOINT_COUNTER (f777)

    feda  3e ff      MVI A, ff                  ; Set RST7 opcode at breakpoint 1 abd breakpoint 2 addresses
    fedc  77         MOV M, A
    fedd  12         STAX DE

    fede  3e c3      MVI A, c3                  ; Set JMP instruction at RST7 handler address (0x0038)
    fee0  32 38 00   STA 0038

    fee3  21 23 ff   LXI HL, BREAKPOINT_HANDLER (ff23)  ; Set handler address for JMP instruction above
    fee6  22 39 00   SHLD 0039

    fee9  21 1c ff   LXI HL, RESET_BREAKPOINT_COUNTER (ff1c); Push special return address, so that function
    feec  e5         PUSH HL                                ; when exiting resets the breakpoints counter

RUN_PROGRAM_NO_BREAKPOINTS:
    feed  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; Command G will execute user program immediately
    fef0  c2 50 f7   JNZ USER_PRG_TRAMPOLINE (f750)     ; with no breakpoints. Command GY processing below.

JMP_TO_USER_PROGRAM:
    fef3  31 65 f7   LXI SP, BREAKPTR_AF_REG (f765) ; Restore user program registers
    fef6  f1         POP PSW
    fef7  c1         POP BC
    fef8  d1         POP DE
    fef9  e1         POP HL
    fefa  e1         POP HL
    fefb  f9         SPHL

    fefc  2a 6b f7   LHLD BREAKPOINT_HL_REG (f76b)  ; Additionally restore HL

    feff  c3 50 f7   JMP USER_PRG_TRAMPOLINE (f750) ; Run the program


; Save CPU registers into dedicated variables, to be viewed/edited by Command X
SAVE_REGISTERS:
    ff02  22 6b f7   SHLD BREAKPOINT_HL_REG (f76b)  ; Save HL

    ff05  e1         POP HL                     ; Save user program PC-1 value (PC before RST7 is
    ff06  e3         XTHL                       ; triggered)
    ff07  2b         DCX HL
    ff08  22 6f f7   SHLD BREAKPOINT_PC_REG (f76f)

    ff0b  f5         PUSH PSW                   ; Save user program SP register value
    ff0c  21 04 00   LXI HL, 0004
    ff0f  39         DAD SP
    ff10  22 6d f7   SHLD BREAKPOINT_SP_REG (f76d)

    ff13  f1         POP PSW                    ; Save other registers into their variables
    ff14  e1         POP HL
    ff15  31 6b f7   LXI SP, BREAKPOINT_HL_REG (f76b)
    ff18  d5         PUSH DE
    ff19  c5         PUSH BC
    ff1a  f5         PUSH PSW

    ff1b  e9         PCHL                       ; Return to the caller


; Set the breakpoint counter to zero, then ????
RESET_BREAKPOINT_COUNTER:
    ff1c  af         XRA A
    ff1d  32 77 f7   STA BREAKPOINT_COUNTER (f777)

    ff20  c3 39 ff   JMP BREAKPOINT_HANDLER_1 (ff39)

; Breakpoint handler
;
; This function is executed on RST7 instruction, which is embedded into the user program by Command G 
; instead of a normal instruction. The function prints current state of program's registers, and allows
; to modify the registers. 
;
; There are several cases handled:
; - In case of single breakpoint used, the function restores instruction at the breakpoint address, and exits
; to the Monitor's loop. 
; - If two breakpoints are set, the function allows to trigger them once, and restores the instructions
; underneath. When breakpoint 2 is handled, the function exits to the Monitor
; - If two breakpoints are set within the same loop, and breakpoint counter is set (argument 4 of the Command
; GY), the function will continue execution after breakpoints, until the counter is over. The counter is
; decreased on breakpoint 2 trigger. Breakpoint 1 and breakpoint 2 shall be executed alternately so that
; breakpoint 1 restores breakpoint 2 and vice versa.
BREAKPOINT_HANDLER:
    ff23  cd 02 ff   CALL SAVE_REGISTERS (ff02) ; Save registers

    ff26  31 fd f7   LXI SP, f7fd               ; Set Monitor's stack

    ff29  cd 5a fe   CALL PRINT_REGISTERS (fe5a); Print and edit registers

    ff2c  2a 6f f7   LHLD BREAKPOINT_PC_REG (f76f)  ; Load PC register in DE
    ff2f  eb         XCHG

    ff30  2a 75 f7   LHLD BREAKPOINT2_ADDR (f775)   ; Check if we hit breakpoint 2 (note that breakpoint 1,
    ff33  cd d3 fb   CALL CMP_HL_DE (fbd3)          ; and breakpoint 2 addresses are equal, if breakpoint 2
    ff36  c2 55 ff   JNZ BREAKPOINT_HANDLER_2 (ff55); is not set)

BREAKPOINT_HANDLER_1:
    ff39  3a 72 f7   LDA BREAKPOINT2_OPCODE (f772)  ; Restore instruction at breakpoint 2
    ff3c  77         MOV M, A

    ff3d  22 51 f7   SHLD ARG_1 (f751)              ; Set the continue address at point where we just stopped

    ff40  2a 73 f7   LHLD BREAKPOINT1_ADDR (f773)   ; Set RST7 instruction at breakpoint 1 address
    ff43  36 ff      MVI M, ff

    ff45  3a 77 f7   LDA BREAKPOINT_COUNTER (f777)  ; Decrement the breakpoint counter
    ff48  3d         DCR A
    ff49  32 77 f7   STA BREAKPOINT_COUNTER (f777)

    ff4c  3d         DCR A                          ; Do not stop if the counter has not reached zero
    ff4d  f2 f3 fe   JP JMP_TO_USER_PROGRAM (fef3)

RESTORE_BKP1_OPCODE:
    ff50  3a 71 f7   LDA BREAKPOINT1_OPCODE (f771)  ; Restore breakpoint 1 instruction
    ff53  77         MOV M, A

    ff54  c9         RET                            ; Return to the monitor main loop (COMMAND_EXIT)

BREAKPOINT_HANDLER_2:
    ff55  36 ff      MVI M, ff                      ; Set RST7 opcode at breakpoint 2 address

    ff57  2a 73 f7   LHLD BREAKPOINT1_ADDR (f773)   ; Store breakpoint 1 as a user program address
    ff5a  22 51 f7   SHLD ARG_1 (f751)

    ff5d  cd 50 ff   CALL RESTORE_BKP1_OPCODE (ff50); Restore instruction under breakpoint 1 and continue
    ff60  c3 f3 fe   JMP JMP_TO_USER_PROGRAM (fef3) ; execution from this place.


; Command R: enable or disable scroll
; 
; Usage:
; R<any symbol>     - enable scroll
; R                 - disable scroll (clear screen if full page is filled])
COMMAND_R_ENABLE_SCROLL:
    ff63  0d         DCR C                          ; Count symbols in the command
    ff64  0d         DCR C                          ; 2 symbols (e.g. R<symb>) will enable scroll (A non zero)
    ff65  79         MOV A, C                       ; 1 symbol ('R' only) will disable scroll (A=0x00)

    ff66  32 7a f7   STA ENABLE_SCROLL (f77a)       ; Store the flag
    ff69  c9         RET


; Command T: trace the command line
;
; Usage:
; T<arguments>  - print command arguments in a hexadecimal form
COMMAND_T_TRACE_CMD_LINE:
    ff6a  21 7c f7   LXI HL, f77b + 1 (f77c)    ; Load pointer to the command arguments

TRACE_CMD_LINE_LOOP:
    ff6d  7e         MOV A, M                   ; Repeat until EOL is reached
    ff6e  fe 0d      CPI A, 0d
    ff70  c8         RZ

    ff71  cd af fb   CALL PRINT_BYTE_CHECK_KBD (fbaf)   ; Print the symbol

    ff74  23         INX HL                     ; Advance to the next symbol and repeat
    ff75  c3 6d ff   JMP TRACE_CMD_LINE_LOOP (ff6d)


HELLO_STR:
    ff78  0a 2a 2a 2a 2a 20 6f 73       db 0x0a, "**** ОС"
    ff80  20 20 20 2a 20 20 20 60       db "   *   Ю"
    ff88  54 2d 38 38 20 2a 2a 2a       db "T-88 ***"
    ff90  2a 0a 00                      db "*", 0x0a, 0x00

PROMPT_STR:
    ff93  0a 60 54 2a 38 38 3e 20       db 0x0a, "ЮТ-88>"
    ff9b  00                            db 0x00

COMMANDS_TABLE:
    ff9c  49 cf fc      db 'I', COMMAND_I_TAPE_INPUT (fccf)
    ff9f  4f 71 fc      db 'O', COMMAND_O_TAPE_OUTPUT (fc71)
    ffa2  4d cd fd      db 'M', COMMAND_M_MEM_EDIT (fdcd)
    ffa5  47 b1 fe      db 'G', COMMAND_G_RUN_PROGRAM (feb1)
    ffa8  58 56 fe      db 'X', COMMAND_X_PRINT_REGISTERS (fe56)
    ffab  4b 38 fe      db 'K', COMMAND_K_CRC (fe38)
    ffae  56 fa c0      db 'V', COMMAND_V_TAPE_SPEED_ADJUST (c0fa)
    ffb1  52 63 ff      db 'R', COMMAND_R_ENABLE_SCROLL (ff63)
    ffb4  43 00 c0      db 'C', COMMAND_C_MEM_COPY (c000)
    ffb7  44 b5 c0      db 'D', COMMAND_D_DUMP_MEMORY (c0b5)
    ffba  46 63 c0      db 'F', COMMAND_F_FILL_MEMORY (c063)
    ffbd  4a a2 c0      db 'J', COMMAND_J_QUICK_JUMP (c0a2)
    ffc0  48 92 c0      db 'H', COMMAND_H_SUM_DIFF_ARG (c092)
    ffc3  54 6a ff      db 'T', COMMAND_T_TRACE_CMD_LINE (ff6a)
    ffc6  53 34 c1      db 'S', COMMAND_S_SEARCH_STRING (c134)
    ffc9  45 00 cb      db 'E', cb00
    ffcc  41 20 ca      db 'A', ca20
    ffcf  4e c2 ca      db 'N', cac2
    ffd2  40 ad ca      db '@', caad
    ffd5  4c 86 c3      db 'L', c386
    ffd8  57 c2 c3      db 'W', c3c2
    ffdb  5a eb c1      db 'Z', c1eb
    ffde  50 27 c2      db 'P', COMMAND_P_RELOCATE (c227)
    ffe1  1f e9 f9      db 0x1f, f9e9
    ffe4  42 00 d8      db 'B', d800
    ffe7  00            db 0x00

REGISTER_LETTERS:
    ffe8  41 42 44 48 53 4f 00     db "ABDHSO", 0x00    ; Register names when dumping regs with Command X


SYMBOL_HANDLERS:
    ffef  38 33 40 48 38 1e 2f 4f               ; Low byte address ofspecial symbols printing handler (0xfaXX)

SPECIAL_SYMBOLS_KBD_LUT:
    fff7  20                                    ; This and following bytes provide codes for special keys

SPECIAL_SYMBOLS:
    fff8  18 08 19 1a 0d 1f 0c 0a               ; List of special symbols

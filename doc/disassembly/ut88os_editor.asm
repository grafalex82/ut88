 ; General description TBD

;
; Variables:
; - f6df    - 0xff, a limiting character for line buffer underrun
; - f6e0    - 0x3f bytes of buffer ????
; - f721    - 
; - f722    - Current line length
; - f723    - Cursor X position, counting from left side. 0xff if not initialized yet.
; - f724    - Tab size - 1
; - f725    - Cursor Y position (counting from top-left corner)
; - f726    - 0x00 - insertion mode, 0xff - overwrite mode
; - f727    - end of file pointer (points to the next symbol after the last text char)
; - f729    - address of the first line visible on the screen
; - f72b    - Pointer to the beginning of the current line

COMMAND_E_EDITOR:
    cb00  0e 1f      MVI C, 1f                  ; Clear screen
    cb02  cd 09 f8   CALL PUT_CHAR (f809)

    cb05  21 00 00   LXI HL, 0000               ; Save SP value
    cb08  39         DAD SP
    cb09  22 2f f7   SHLD SAVE_SP (f72f)

EDITOR_MAIN_LOOP:
    cb0c  2a 2f f7   LHLD SAVE_SP (f72f)        ; Restore SP
    cb0f  f9         SPHL

    cb10  cd 12 cc   CALL PRINT_HELLO_PROMPT (cc12) ; Print prompt

    cb13  21 00 30   LXI HL, 3000               ; ???? text start, and current cursor position?????
    cb16  22 29 f7   SHLD PAGE_START_ADDR (f729)
    cb19  22 2b f7   SHLD CUR_LINE_PTR (f72b)

    cb1c  cd 9b cf   CALL GET_END_OF_FILE (cf9b); ???? get end of file pointer
    cb1f  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    cb22  cd 6f ce   CALL CLEAR_BUFFER (ce6f)

    cb25  eb         XCHG                       ; ????? Store 0x00
    cb26  32 22 f7   STA CUR_LINE_LEN (f722)
    cb29  32 26 f7   STA INSERT_MODE (f726)

    cb2c  3d         DCR A                      ; ???? Store 0xff
    cb2d  32 21 f7   STA f721
    cb30  32 23 f7   STA CURSOR_X (f723)
    cb33  32 25 f7   STA CURSOR_Y (f725)

    cb36  2b         DCX HL                     ; Store 0xff to f6df (some functions intentionally do read prior
    cb37  77         MOV M, A                   ; the line buffer, and 0xff indicate no data there)
    cb38  23         INX HL

    cb39  3e 03      MVI A, 03                  ; Set the default tab size
    cb3b  32 24 f7   STA TAB_SIZE (f724)

EDITOR_MAIN_CHAR_LOOP:
    cb3e  01 3e cb   LXI BC, EDITOR_MAIN_CHAR_LOOP (cb3e)   ; Character processing will return back here
    cb41  c5         PUSH BC

    cb42  cd b4 cb   CALL GET_KBD_KEY (cbb4)    ; Control character will be processed elsewhere
    cb45  ca 95 cb   JZ PROCESS_COMMAND (cb95)

    cb48  fe 08      CPI A, 08                  ; Check if left arrow is pressed
    cb4a  ca 01 ce   JZ LEFT_ARROW (ce01)

    cb4d  fe 18      CPI A, 18                  ; Check if right arrow is pressed
    cb4f  ca 85 cb   JZ RIGHT_ARROW (cb85)

    cb52  fe 19      CPI A, 19                  ; Check if up arrow is pressed
    cb54  ca 1f ce   JZ UP_ARROW (ce1f)

    cb57  fe 1a      CPI A, 1a                  ; Check if down arrow is pressed
    cb59  ca 34 cf   JZ DOWN_ARROW (cf34)

    cb5c  fe 0c      CPI A, 0c                  ; Check if home key is pressed
    cb5e  ca b1 ce   JZ HOME_KEY (ceb1)

    cb61  fe 1f      CPI A, 1f                  ; Check if clear screen key is pressed
    cb63  c2 6b cb   JNZ EDITOR_MAIN_PROCESS_CHAR (cb6b)

    cb66  cd ce ce   CALL FLUSH_STRING_BUF (cece)   ; Clear screen key will exit to monitor
    cb69  c1         POP BC
    cb6a  c9         RET

EDITOR_MAIN_PROCESS_CHAR:
    cb6b  fe 0d      CPI A, 0d                  ; Check if Return key is pressed
    cb6d  ca db cc   JZ BEEP (ccdb)

    cb70  cd aa cb   CALL CHECK_SYMBOL_AT_CURSOR (cbaa) ; ?????

    cb73  3a 26 f7   LDA INSERT_MODE (f726)     ; Are we in insertion or overwrite mode?
    cb76  b7         ORA A
    cb77  c2 7f cb   JNZ EDITOR_MAIN_PROCESS_CHAR_1 (cb7f)

    cb7a  c5         PUSH BC                    ; Insert a symbol at cursor
    cb7b  cd 62 d0   CALL INSERT_SYMB_1 (d062)
    cb7e  c1         POP BC

EDITOR_MAIN_PROCESS_CHAR_1:
    cb7f  7e         MOV A, M                   ; Do not allow entering symbols at the end of the line buffer
    cb80  b7         ORA A
    cb81  ca db cc   JZ BEEP (ccdb)

    cb84  71         MOV M, C                   ; Store the entered symbol, then advance cursor right


; Move cursor 1 position to the right
RIGHT_ARROW:
    cb85  3a 23 f7   LDA CURSOR_X (f723)        ; Load cursor position

    cb88  fe 3e      CPI A, 3e                  ; Moving beyond right screen boundary is not allowed
    cb8a  d2 db cc   JNC BEEP (ccdb)

    cb8d  3c         INR A                      ; Increment cursor position
    cb8e  32 23 f7   STA CURSOR_X (f723)

    cb91  23         INX HL                     ; Increment text pointer as well

    cb92  c3 09 f8   JMP PUT_CHAR (f809)        ; Actually move the cursor


; Find and execute command handler
; Argument: C - command to execute
PROCESS_COMMAND:
    cb95  e5         PUSH HL                    ; Load command handlers table
    cb96  21 4a d3   LXI HL, COMMAND_HANDLERS (d34a)

PROCESS_COMMAND_LOOP:
    cb99  7e         MOV A, M                   ; Stop if reached end of the table
    cb9a  b7         ORA A
    cb9b  ca da cc   JZ PROCESS_COMMAND_ERROR (ccda)

    cb9e  b9         CMP C                      ; Compare entered key with command symbol in the table

    cb9f  23         INX HL                     ; Load handler address
    cba0  5e         MOV E, M
    cba1  23         INX HL
    cba2  56         MOV D, M

    cba3  23         INX HL                     ; Advance to the next record if symbol does not match
    cba4  c2 99 cb   JNZ PROCESS_COMMAND_LOOP (cb99)

    cba7  e1         POP HL                     ; Jump to the handler
    cba8  d5         PUSH DE
    cba9  c9         RET


; Check symbol at [HL]
; The symbol must be non-zero, or at least previous symbol must be non zero. Otherwise beep an error
CHECK_SYMBOL_AT_CURSOR:
    cbaa  7e         MOV A, M                   ; Check that symbol under cursor is not zero
    cbab  b7         ORA A
    cbac  c0         RNZ

    cbad  2b         DCX HL                     ; If it is - check previous symbol
    cbae  b6         ORA M
    cbaf  23         INX HL
    cbb0  c0         RNZ

    cbb1  c3 dc cc   JMP BEEP_1 (ccdc)    ; Otherwise we are in error condition - make a beep


; Wait for a key press
; Return input key in A, Z flag is set if Ctrl key is pressed as well
GET_KBD_KEY:
    cbb4  cd 03 f8   CALL KBD_INPUT (f803)      ; Input char
    cbb7  4f         MOV C, A

    cbb8  db 05      IN 05                      ; Check if high bit in Port C is set (BUG? MSB of the port C
    cbba  e6 80      ANI A, 80                  ; is not connected, shall be 0x02 for Ctrl key)

    cbbc  79         MOV A, C                   ; Return entered char in A
    cbbd  c9         RET

????_COMMAND_X:
cbbe  e5         PUSH HL
cbbf  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
cbc2  e3         XTHL
cbc3  c3 cb cb   JMP cbcb

????_COMMAND_L:
cbc6  e5         PUSH HL
cbc7  21 00 30   LXI HL, 3000
cbca  e3         XTHL
????:
cbcb  cd fd cb   CALL CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT (cbfd)
cbce  cd 20 cc   CALL INPUT_LINE (cc20)
cbd1  dc 6f ce   CC CLEAR_BUFFER (ce6f)
cbd4  44         MOV B, H
cbd5  4d         MOV C, L
cbd6  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
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
cbe9  cd ea cc   CALL CMP_HL_DE (ccea)
cbec  e1         POP HL
cbed  c1         POP BC
cbee  23         INX HL
cbef  da dc cb   JC cbdc
cbf2  0e 3f      MVI C, 3f
cbf4  cd 09 f8   CALL PUT_CHAR (f809)

; Produce a error sound, and exit to the main loop
BEEP_AND_EXIT:
    cbf7  cd db cc   CALL BEEP (ccdb)
    cbfa  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c)


CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT:
    cbfd  f5         PUSH PSW                   ; ????
    cbfe  cd ce ce   CALL FLUSH_STRING_BUF (cece)
    cc01  f1         POP PSW

    cc02  0e 1f      MVI C, 1f                  ; Clear screen
    cc04  cd 09 f8   CALL PUT_CHAR (f809)

    cc07  cd 12 cc   CALL PRINT_HELLO_PROMPT (cc12) ; Print the prompt, then print command symbol

; Print char in A register, then print a space
PUT_CHAR_AND_SPACE:
    cc0a  cd 81 cd   CALL PUT_CHAR_A (cd81)     ; Print char

    cc0d  0e 20      MVI C, 20                  ; Print space
    cc0f  c3 09 f8   JMP PUT_CHAR (f809)


; Print greetings string, and command prompt
PRINT_HELLO_PROMPT:
    cc12  e5         PUSH HL
    cc13  21 23 d3   LXI HL, HELLO_STR (d323)

    cc16  cd 18 f8   CALL PRINT_STRING (f818)
    cc19  e1         POP HL
    cc1a  c9         RET


; Move cursor to the top-left corner of the screen
HOME_SCREEN_CURSOR:
    cc1b  0e 0c      MVI C, 0c
    cc1d  c3 09 f8   JMP PUT_CHAR (f809)


; Input text line from keyboard to the line buffer
;
; The function waits for the keyboard input, and stores entered keys in the buffer. The function also 
; handles left/backspace keys to move cursor left and remove last entered symbol. The right arrow key
; moves cursor right, and reveal previously erased symbol (if any). It also supports Ctrl-space key 
; combination that acts as a tab key (moves cursor right to the next tab stop).
;
; Return key stops the input, and exits. Clear screen also stops the input, and sets C flag, so that 
; the caller may exit the current command or function.
INPUT_LINE:
    cc20  cd 6f ce   CALL CLEAR_BUFFER (ce6f)   ; Clear the buffer

    cc23  62         MOV H, D                   ; HL will point to the current char in the buffer
    cc24  6b         MOV L, E

    cc25  32 23 f7   STA CURSOR_X (f723)    ; Zero chars counter

INPUT_LINE_LOOP:
    cc28  cd ca cc   CALL PRINT_HASH_CURSOR (ccca)  ; Print cursor

    cc2b  cd b4 cb   CALL GET_KBD_KEY (cbb4)    ; Wait for a key press 
    cc2e  c2 68 cc   JNZ INPUT_LINE_PROCESS_CHAR (cc68)

    cc31  fe 20      CPI A, 20                  ; No Ctrl-<something> is allowed, except for Ctrl-space
    cc33  c2 d4 cc   JNZ INPUT_TEXT_BEEP_AND_REPEAT (ccd4)

    cc36  3a 24 f7   LDA TAB_SIZE (f724)        ; Load the tab size
    cc39  2f         CMA
    cc3a  4f         MOV C, A

    cc3b  3a 23 f7   LDA CURSOR_X (f723)    ; Calculate nearest tab stop
    cc3e  47         MOV B, A
    cc3f  a1         ANA C
    cc40  91         SUB C

    cc41  fe 40      CPI A, 40                  ; Report error if value exceeds buffer size
    cc43  d2 d4 cc   JNC INPUT_TEXT_BEEP_AND_REPEAT (ccd4)

    cc46  90         SUB B                      ; Move cursor right for the required number of chars
    cc47  47         MOV B, A

; Move cursor right B times, reveal characters from the buffer if they are already
INPUT_LINE_MOVE_RIGHT:
    cc48  4e         MOV C, M                   ; Check if there is non-zero character in the buffer already
    cc49  79         MOV A, C
    cc4a  b7         ORA A
    cc4b  c2 51 cc   JNZ INPUT_LINE_MOVE_RIGHT_1 (cc51)

    cc4e  0e 20      MVI C, 20                  ; Otherwise use space char
    cc50  71         MOV M, C

INPUT_LINE_MOVE_RIGHT_1:
    cc51  3a 23 f7   LDA CURSOR_X (f723)    ; Increase the buffer chars counter
    cc54  3c         INR A

    cc55  fe 3f      CPI A, 3f                  ; Limit the buffer with 0x3f chars, report an error when
    cc57  d2 d4 cc   JNC INPUT_TEXT_BEEP_AND_REPEAT (ccd4)  ; the buffer is full

    cc5a  32 23 f7   STA CURSOR_X (f723)    ; Store the new counter value

    cc5d  23         INX HL                     ; Advance buffer pointer

    cc5e  cd 09 f8   CALL PUT_CHAR (f809)       ; Print the char (reveal one existing already in the buffer)

    cc61  05         DCR B                      ; Repeat B times
    cc62  c2 48 cc   JNZ INPUT_LINE_MOVE_RIGHT (cc48)

    cc65  c3 28 cc   JMP INPUT_LINE_LOOP (cc28) ; Ready for next character input


INPUT_LINE_PROCESS_CHAR:
    cc68  b7         ORA A                      ; No or unknown key - beep an error
    cc69  ca d4 cc   JZ INPUT_TEXT_BEEP_AND_REPEAT (ccd4)

    cc6c  fe 0c      CPI A, 0c                  ; Home key is incorrect as well
    cc6e  ca d4 cc   JZ INPUT_TEXT_BEEP_AND_REPEAT (ccd4)

    cc71  fe 1f      CPI A, 1f                  ; Check if clear screen key is pressed
    cc73  ca a8 cc   JZ INPUT_LINE_EXIT (cca8)

    cc76  4f         MOV C, A                   ; Temporary store the symbol in C register

    cc77  fe 08      CPI A, 08                  ; Check if left arrow/backspace is pressed
    cc79  ca b1 cc   JZ INPUT_LINE_BACKSPACE (ccb1)

    cc7c  fe 18      CPI A, 18                  ; Check if right arrow is pressed
    cc7e  ca ac cc   JZ INPUT_LINE_RIGHT (ccac)

    cc81  fe 19      CPI A, 19                  ; Up and Down arrows are invalid keys
    cc83  ca d4 cc   JZ INPUT_TEXT_BEEP_AND_REPEAT (ccd4)
    cc86  fe 1a      CPI A, 1a
    cc88  ca d4 cc   JZ INPUT_TEXT_BEEP_AND_REPEAT (ccd4)

    cc8b  d6 0d      SUI A, 0d                  ; Check if Return key is pressed
    cc8d  c2 ab cc   JNZ INPUT_LINE_SUBMIT_CHAR (ccab)

    cc90  77         MOV M, A                   ; Store zero char in the buffer

    cc91  3a 23 f7   LDA CURSOR_X (f723)        ; Store number of entered chars in 0xf722 ????
    cc94  3c         INR A
    cc95  32 22 f7   STA CUR_LINE_LEN (f722)

    cc98  eb         XCHG                       ; Print the entered char
    cc99  0e 0a      MVI C, 0a                  ; Then advance to the new line and exit
    cc9b  cd 09 f8   CALL PUT_CHAR (f809)


; Move cursor to the beginning of the current line
HOME_CURSOR:
    cc9e  0e 0a      MVI C, 0a                  ; Print CR symbol
    cca0  cd 09 f8   CALL PUT_CHAR (f809)
    cca3  0e 19      MVI C, 19                  ; Step one row up
    cca5  c3 09 f8   JMP PUT_CHAR (f809)

INPUT_LINE_EXIT:
    cca8  eb         XCHG                       ; Raise C flag and exit
    cca9  37         STC
    ccaa  c9         RET

INPUT_LINE_SUBMIT_CHAR:
    ccab  71         MOV M, C                   ; Store the char in the buffer, and advance cursor

INPUT_LINE_RIGHT:
    ccac  06 01      MVI B, 01                  ; Move cursor right for 1 character
    ccae  c3 48 cc   JMP INPUT_LINE_MOVE_RIGHT (cc48)

INPUT_LINE_BACKSPACE:
    ccb1  3a 23 f7   LDA CURSOR_X (f723)        ; Check if there is room to go
    ccb4  3d         DCR A
    ccb5  fa d4 cc   JM INPUT_TEXT_BEEP_AND_REPEAT (ccd4)   ; Report error if we are at the beginning of line

    ccb8  32 23 f7   STA CURSOR_X (f723)        ; Store new position

    ccbb  3e 20      MVI A, 20                  ; Clear the symbol at cursor
    ccbd  cd 81 cd   CALL PUT_CHAR_A (cd81)

    ccc0  2b         DCX HL                     ; Decrement buffer pointer

    ccc1  cd 09 f8   CALL PUT_CHAR (f809)       ; Move cursor 2 chars left
    ccc4  cd 09 f8   CALL PUT_CHAR (f809)

    ccc7  c3 28 cc   JMP INPUT_LINE_LOOP (cc28) ; Wait for the next symbol


; Print '#' symbol, then move cursor left
PRINT_HASH_CURSOR:
    ccca  0e 23      MVI C, 23                  ; Print '#' symbol
    cccc  cd 09 f8   CALL PUT_CHAR (f809)

; Print 'move left' symbol
PRINT_BACKSPACE:
    cccf  0e 08      MVI C, 08                  ; Print 'move left' symbol
    ccd1  c3 09 f8   JMP PUT_CHAR (f809)

; Produce a beep sound, and repeat waiting a new key
INPUT_TEXT_BEEP_AND_REPEAT:
    ccd4  cd db cc   CALL BEEP (ccdb)
    ccd7  c3 28 cc   JMP INPUT_LINE_LOOP (cc28)


PROCESS_COMMAND_ERROR:
    ccda  e1         POP HL                     ; Restore stack pointer, beep, and restart main loop


; Make a beep sound, indicating an error
BEEP:
    ccdb  c5         PUSH BC

BEEP_1:
    ccdc  f5         PUSH PSW                   ; Output 0x55 times byte 0x55
    ccdd  3e 55      MVI A, 55
    ccdf  47         MOV B, A

BEEP_LOOP:
    cce0  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output a byte until counter is zero
    cce3  05         DCR B
    cce4  c2 e0 cc   JNZ BEEP_LOOP (cce0)

    cce7  f1         POP PSW
    cce8  c1         POP BC
    cce9  c9         RET

; Compare HL and DE, set corresponding flags (Z or C)
CMP_HL_DE:
    ccea  7c         MOV A, H                   ; Compare high bytes
    cceb  ba         CMP D
    ccec  c0         RNZ

    cced  7d         MOV A, L                   ; Compare low bytes
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
ccfa  cd 53 ce   CALL SEARCH_CUR_LINE_START (ce53)

; Draw Screen
; 
; The function fills entire screen with the text data, starting from line pointed in HL. Each line if filled
; with the corresponding line text. Short lines are padded with spaces, so that all characters in the line 
; are eventually printed. The function draws '*' at the end of each line for visibility.
;
; The function also loads the last printed line to the line buffer, and sets up all corresponding variables.
; Cursor is set to the first position on the last line.
;
; HL - pointer to the first line to draw
DRAW_SCREEN:
    ccfd  cd 1b cc   CALL HOME_SCREEN_CURSOR (cc1b) ; Start with top-left corner

    cd00  22 29 f7   SHLD PAGE_START_ADDR (f729); Store new page start address

    cd03  af         XRA A                      ; Clear also X cursor position
    cd04  32 23 f7   STA CURSOR_X (f723)

    cd07  06 1f      MVI B, 1f                  ; Print 31 line on the page
                                                ; BUG: UT-88 has only 28 lines on the screen

DRAW_SCREEN_LINE_LOOP:
    cd09  0e 3f      MVI C, 3f                  ; Will print no more 63 chars on the line (64th char is '*')
    cd0b  cd 6f ce   CALL CLEAR_BUFFER (ce6f)

DRAW_SCREEN_CHAR_LOOP:
    cd0e  7e         MOV A, M                   ; Load the next char.
    cd0f  fe 0d      CPI A, 0d                  ; If this is not \r char - print it normally
    cd11  c2 74 cd   JNZ DRAW_SCREEN_SUBMIT_CHAR (cd74)

    cd14  3e 2a      MVI A, 2a                  ; Print '*' indicating end of line
    cd16  cd 81 cd   CALL PUT_CHAR_A (cd81)

    cd19  c5         PUSH BC                    ; Clear rest of the line with spaces
    cd1a  41         MOV B, C
    cd1b  3e 01      MVI A, 01
    cd1d  0e 20      MVI C, 20
    cd1f  cd 97 d0   CALL PUT_CHAR_BLOCK (d097)
    cd22  c1         POP BC

    cd23  23         INX HL                     ; Load the marker after last text symbol
    cd24  7e         MOV A, M
    cd25  2b         DCX HL

    cd26  b7         ORA A                      ; Check if it is >=0x80
    cd27  fa 32 cd   JM DRAW_SCREEN_EOF_REACHED (cd32)

    cd2a  05         DCR B                      ; Will print B lines on the page
    cd2b  ca 33 cd   JZ DRAW_SCREEN_FINISH (cd33)

    cd2e  23         INX HL                     ; Advance to the next text char, and repeat for the next line
    cd2f  c3 09 cd   JMP DRAW_SCREEN_LINE_LOOP (cd09)


DRAW_SCREEN_EOF_REACHED:
    cd32  05         DCR B                      ; Increase line counter

DRAW_SCREEN_FINISH:
    cd33  3e 08      MVI A, 08                  ; Move 2 characters back
    cd35  cd 81 cd   CALL PUT_CHAR_A (cd81)
    cd38  cd 81 cd   CALL PUT_CHAR_A (cd81)

    cd3b  3e 3f      MVI A, 3f                  ; Calculate length of the string (len = 0x3f - C)
    cd3d  91         SUB C
    cd3e  4f         MOV C, A

    cd3f  32 21 f7   STA f721                   ; Store calculated string length
    cd42  32 22 f7   STA CUR_LINE_LEN (f722)

    cd45  3e 1e      MVI A, 1e                  ; Calculate Y coordinate (Y = 0x1e - B)
    cd47  90         SUB B                      ; BUG: UT-88 display has only 28 lines, not 32
    cd48  32 25 f7   STA CURSOR_Y (f725)

    cd4b  79         MOV A, C                   ; Change sign of X coordinate
    cd4c  2f         CMA
    cd4d  3c         INR A

    cd4e  ca 55 cd   JZ DRAW_SCREEN_FINISH_1 (cd55) ; Skip next operation if string len is zero

    cd51  4f         MOV C, A                   ; HL points to the last printed character on the last string
    cd52  06 ff      MVI B, ff                  ; Subtract X coordinate, so that HL now points to the 
    cd54  09         DAD BC                     ; beginning of the last printed line

DRAW_SCREEN_FINISH_1:
    cd55  22 2b f7   SHLD CUR_LINE_PTR (f72b)   ; Save current line pointer

    cd58  11 e0 f6   LXI DE, f6e0               ; Load start buffer address
    cd5b  eb         XCHG

DRAW_SCREEN_FINISH_2:
    cd5c  3a 25 f7   LDA CURSOR_Y (f725)        ; It may happen that text ends earlier than the last line of
    cd5f  f5         PUSH PSW                   ; the screen. Calculate how many lines below the cursor
    cd60  47         MOV B, A
    cd61  3e 1f      MVI A, 1f                  ; BUG: UT-88 display has only 28 lines, not 32
    cd63  90         SUB B

    cd64  01 20 40   LXI BC, 4020               ; Clear those lines
    cd67  cd 97 d0   CALL PUT_CHAR_BLOCK (d097)

    cd6a  cd 1b cc   CALL HOME_SCREEN_CURSOR (cc1b) ; Move cursor to the top-left position

    cd6d  f1         POP PSW                    ; Move cursor Y positions down
    cd6e  01 1a 01   LXI BC, 011a
    cd71  c3 97 d0   JMP PUT_CHAR_BLOCK (d097)


DRAW_SCREEN_SUBMIT_CHAR:
    cd74  0d         DCR C                      ; Store next char if it fits the buffer
    cd75  12         STAX DE                    ; Print 'String too long' error otherwise
    cd76  ca 0f ce   JZ PRINT_LONG_STR_ERROR (ce0f)

    cd79  cd 81 cd   CALL PUT_CHAR_A (cd81)     ; Also print character on the screen

    cd7c  23         INX HL                     ; Advance to the next char
    cd7d  13         INX DE
    cd7e  c3 0e cd   JMP DRAW_SCREEN_CHAR_LOOP (cd0e)


; Put char on the screen
; Same as Monitor's PUT_CHAR function, but accepts symbol in A. Save BC value.
PUT_CHAR_A:
    cd81  c5         PUSH BC
    cd82  4f         MOV C, A
    cd83  cd 09 f8   CALL PUT_CHAR (f809)
    cd86  c1         POP BC
    cd87  c9         RET


; Command W: Toggle tab size
;
; The function toggles tab size between 4 and 8 chars
TOGGLE_TAB_SIZE:
    cd88  f5         PUSH PSW                   ; Check if the tab size is 7
    cd89  3a 24 f7   LDA TAB_SIZE (f724)
    cd8c  fe 07      CPI A, 07
    cd8e  c2 96 cd   JNZ TOGGLE_TAB_SIZE_1 (cd96)

    cd91  3e 03      MVI A, 03                  ; Set it to 3
    cd93  c3 98 cd   JMP TOGGLE_TAB_SIZE_2 (cd98)

TOGGLE_TAB_SIZE_1:
    cd96  3e 07      MVI A, 07                  ; If it was 3 - set it to 7

TOGGLE_TAB_SIZE_2:
    cd98  32 24 f7   STA TAB_SIZE (f724)        ; Store the new value

    cd9b  f1         POP PSW
    cd9c  c9         RET


; Toggle insert/overwrite mode
; In insert mode each new symbol will be inserted at cursor position, and rest of the string will be shifted
; right. In overwrite mode symbol at cursor will be overwritten. 
TOGGLE_INSERT:
    cd9d  f5         PUSH PSW                   ; Toggle the mode
    cd9e  3a 26 f7   LDA INSERT_MODE (f726)
    cda1  2f         CMA
    cda2  32 26 f7   STA INSERT_MODE (f726)
    cda5  f1         POP PSW

    cda6  c9         RET


????_COMMAND_R:
cda7  d5         PUSH DE
cda8  e5         PUSH HL
cda9  11 2d 20   LXI DE, 202d
cdac  2a 5c f7   LHLD f75c
cdaf  cd ea cc   CALL CMP_HL_DE (ccea)
cdb2  c2 b8 cd   JNZ cdb8
cdb5  11 14 10   LXI DE, 1014
????:
cdb8  eb         XCHG
cdb9  22 5c f7   SHLD f75c
cdbc  e1         POP HL
cdbd  d1         POP DE
cdbe  c9         RET


????_COMMAND_F:
cdbf  cd fd cb   CALL CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT (cbfd)
cdc2  21 34 d3   LXI HL, d334
cdc5  cd 18 f8   CALL PRINT_STRING (f818)
cdc8  e5         PUSH HL
cdc9  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
cdcc  cd f9 cd   CALL cdf9
cdcf  eb         XCHG
cdd0  e1         POP HL
cdd1  cd 18 f8   CALL PRINT_STRING (f818)
cdd4  e5         PUSH HL
cdd5  21 00 30   LXI HL, 3000
cdd8  eb         XCHG
cdd9  e5         PUSH HL
cdda  cd f2 cd   CALL cdf2
cddd  23         INX HL
cdde  cd f9 cd   CALL cdf9
cde1  d1         POP DE
cde2  e1         POP HL
cde3  cd 18 f8   CALL PRINT_STRING (f818)
cde6  21 ff 9f   LXI HL, 9fff
cde9  cd f2 cd   CALL cdf2
cdec  cd f9 cd   CALL cdf9
cdef  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c)
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

; Move cursor 1 position left
LEFT_ARROW:
    ce01  3a 23 f7   LDA CURSOR_X (f723)        ; Decrement cursor position
    ce04  3d         DCR A

    ce05  fa db cc   JM BEEP (ccdb)       ; Moving beyond left screen boundary is not allowed

    ce08  32 23 f7   STA CURSOR_X (f723)        ; Store new cursor position

    ce0b  2b         DCX HL                     ; Move text pointer as well

    ce0c  c3 09 f8   JMP PUT_CHAR (f809)        ; Actually move the cursor

; Print String too long error
PRINT_LONG_STR_ERROR:
    ce0f  11 f6 d2   LXI DE, LONG_STRING_STR (d2f6)

; Print error
; DE - pointer to error type
PRINT_ERROR:
    ce12  21 ee d2   LXI HL, ERROR_STR (d2ee)   ; Print ERROR: prefix
    ce15  cd 18 f8   CALL PRINT_STRING (f818)

    ce18  eb         XCHG                       ; Print the error type
    ce19  cd 18 f8   CALL PRINT_STRING (f818)

    ce1c  c3 f7 cb   JMP BEEP_AND_EXIT (cbf7)   ; ?????


; Move cursor one line up, scroll one line up if necessary
UP_ARROW:
    ce1f  cd 80 ce   CALL PREPARE_MOVE_UP (ce80); Flush line buffer, Check cursor position

    ce22  fa b4 ce   JM HOME_KEY_1 (ceb4)       ; Handle cursor up beyond the top (home cursor, scroll one line up)

    ce25  2a 2b f7   LHLD CUR_LINE_PTR (f72b)   ; Search previous line start
    ce28  cd 51 ce   CALL SEARCH_PREV_LINE (ce51)


; Load new line pointed by HL
;
; The function loads current line to the line buffer. Line length variables updated accordingly.
LOAD_LINE:
    ce2b  22 2b f7   SHLD CUR_LINE_PTR (f72b)   ; Store the new line start pointer

    ce2e  cd 6f ce   CALL CLEAR_BUFFER (ce6f)   ; Prepare the buffer for the next line

    ce31  d5         PUSH DE
    ce32  06 00      MVI B, 00                  ; Count chars in the buffer in B

LOAD_LINE_LOOP:
    ce34  7e         MOV A, M                   ; Load the next char of text

    ce35  fe 0d      CPI A, 0d                  ; Stop copying when \r reached
    ce37  ca 41 ce   JZ LOAD_LINE_FINISH (ce41)

    ce3a  12         STAX DE                    ; Copy the char

    ce3b  04         INR B                      ; Advance to the next char
    ce3c  23         INX HL
    ce3d  13         INX DE
    ce3e  c3 34 ce   JMP LOAD_LINE_LOOP (ce34)

LOAD_LINE_FINISH:
    ce41  78         MOV A, B                   ; Store new line length
    ce42  32 21 f7   STA f721                   ; ????
    ce45  32 22 f7   STA CUR_LINE_LEN (f722)

    ce48  e1         POP HL                     ; Load the cursor X position in DE
    ce49  3a 23 f7   LDA CURSOR_X (f723)
    ce4c  5f         MOV E, A
    ce4d  16 00      MVI D, 00

    ce4f  19         DAD DE                     ; Advance cursor to the same X position in the buffer
    ce50  c9         RET                        ; BUG? Buffer may have less data


; Search for a beginning of the previous line
; Note: If start of text reached the caller function will exit, and the screen will be redrawn.

; Argument:
; HL - beginning of the current string
;
; Return:
; HL - pointer to the beginning of previous string
SEARCH_PREV_LINE:
    ce51  2b         DCX HL                     ; HL points to a line start. Decrement pointer so that it looks
    ce52  2b         DCX HL                     ; to the last char of the previous line

; Search for a beginning of the current line
SEARCH_CUR_LINE_START:
    ce53  c1         POP BC                     ; Temporary save return address

    ce54  cd ea cc   CALL CMP_HL_DE (ccea)      ; If we reached start of text - just redraw and exit (from caller
    ce57  ca fd cc   JZ DRAW_SCREEN (ccfd)      ; function as well)

    ce5a  7e         MOV A, M                   ; Stop if reached end of line
    ce5b  fe 0d      CPI A, 0d

    ce5d  c5         PUSH BC                    ; Otherwise advance to the next symbol (despite increment we 
    ce5e  23         INX HL                     ; will move backwards in fact)
    ce5f  c8         RZ

    ce60  c3 51 ce   JMP SEARCH_PREV_LINE (ce51)


; Perform scroll 1 line up if not yet at the beginning of the text
;
; Arguments:
; HL - current page address
; DE - 0x3000 text start address
SCROLL_UP_IF_POSSIBLE:
    ce63  cd ea cc   CALL CMP_HL_DE (ccea)      ; If we are at the text start - just redraw
    ce66  ca fd cc   JZ DRAW_SCREEN (ccfd)

    ce69  cd 51 ce   CALL SEARCH_PREV_LINE (ce51)   ; Otherwise scroll 1 line up
    ce6c  c3 fd cc   JMP DRAW_SCREEN (ccfd)


; Clear the data buffer at 0xf6e0 for 0x3f bytes
; Return: DE - buffer address
CLEAR_BUFFER:
    ce6f  c5         PUSH BC                    ; Will clean 0x3f bytes
    ce70  06 3f      MVI B, 3f

    ce72  11 e0 f6   LXI DE, f6e0               ; Load buffer address
    ce75  d5         PUSH DE

    ce76  af         XRA A                      ; Fill with zeros

CLEAR_BUFFER_LOOP:
    ce77  12         STAX DE                    ; Clear byte

    ce78  13         INX DE                     ; Advance to the next byte, until all bytes are cleared
    ce79  05         DCR B
    ce7a  c2 77 ce   JNZ CLEAR_BUFFER_LOOP (ce77)

    ce7d  d1         POP DE                     ; Exit
    ce7e  c1         POP BC
    ce7f  c9         RET


; Prepare for moving cursor up
;
; The function is executed when pressing up arrow or home keys, and suppose to move cursor somewhere up. The
; function performs actual cursor movement by printing movement char. Also it flushes input buffer data, if needed.
; But the most important is that function checks whether cursor is already on the topmost position. In this case
; Sign bit is raised.
;
; Arguments:
; C - cursor movement char
;
; Return:
; HL - current page start address
; DE - start of text address (0x3000)
; S bit is raised if cursor was on the top of the screen (and moving up further is not allowed)
PREPARE_MOVE_UP:
    ce80  cd 09 f8   CALL PUT_CHAR (f809)           ; Print the cursor movement char

    ce83  cd ce ce   CALL FLUSH_STRING_BUF (cece)   ; Flush previous string data

    ce86  21 25 f7   LXI HL, CURSOR_Y (f725)        ; Decrement cursor Y position
    ce89  35         DCR M

    ce8a  2a 29 f7   LHLD PAGE_START_ADDR (f729)    ; Load page start and text start addresses
    ce8d  11 00 30   LXI DE, 3000

    ce90  c9         RET


; Scroll one page of 32 lines up (Ctrl-Up key combination)
;
; The function searches back starting from page start address, and search for line end symbols (\r). Function
; searches up to B lines up, or stops at the beginning of the text

; Arguments:
; B - number of lines to go up
PAGE_UP:
    ce91  cd ce ce   CALL FLUSH_STRING_BUF (cece)   ; Flush current line if needed

    ce94  2a 29 f7   LHLD PAGE_START_ADDR (f729)    ; Will start search from the page start address

    ce97  06 1e      MVI B, 1e                      ; Will scroll up to 30 lines
                                                    ; BUG: UT-88 has only 28 lines, not 32

DO_SCROLL_UP:
    ce99  11 00 30   LXI DE, 3000                   ; Scroll up but not beyond start of text

SCROLL_UP_SEARCH_LOOP:
    ce9c  cd ea cc   CALL CMP_HL_DE (ccea)          ; If reached start of text - just redraw the screen and exit
    ce9f  ca fd cc   JZ DRAW_SCREEN (ccfd)

    cea2  2b         DCX HL                         ; Read the next symbol
    cea3  7e         MOV A, M

    cea4  fe 0d      CPI A, 0d                      ; If not a \r - continue with the next char
    cea6  c2 9c ce   JNZ SCROLL_UP_SEARCH_LOOP (ce9c)

    cea9  05         DCR B                          ; Decrement the line counter
    ceaa  c2 9c ce   JNZ SCROLL_UP_SEARCH_LOOP (ce9c)

    cead  23         INX HL                         ; End of previous line found, advance to the next line

    ceae  c3 fd cc   JMP DRAW_SCREEN (ccfd)         ; Draw the screen


; Handle Home key
; Move cursor to the topleft position. Scroll screen 1 line up if needed.
HOME_KEY:
    ceb1  cd 80 ce   CALL PREPARE_MOVE_UP (ce80)    ; Flush line buffer, Check cursor position

HOME_KEY_1:
    ceb4  fc 63 ce   CM SCROLL_UP_IF_POSSIBLE (ce63); If the cursor is on the first line - scroll 1 line up

    ceb7  af         XRA A                          ; Zero cursor logical position
    ceb8  32 23 f7   STA CURSOR_X (f723)
    cebb  32 25 f7   STA CURSOR_Y (f725)

    cebe  cd 1b cc   CALL HOME_SCREEN_CURSOR (cc1b) ; Move cursor to the top-left corner

    cec1  2a 29 f7   LHLD PAGE_START_ADDR (f729)    ; Load the first line on the page
    cec4  c3 2b ce   JMP LOAD_LINE (ce2b)


????:
cec7  3a 23 f7   LDA CURSOR_X (f723)
ceca  b7         ORA A
cecb  c2 dc cc   JNZ BEEP_1 (ccdc)


; Flush currently edited line from buffer to text
;
; Since the line may become shorter or longer compared to the original one, the function shifts the rest
; of the text left or right in order to fit the buffer text perfectly. Eventually text from the buffer is
; flushed to the main text area.
FLUSH_STRING_BUF:
    cece  3a 21 f7   LDA f721                   ; Check if X cursor position has meaningful value (do nothing
    ced1  b7         ORA A                      ; if line editing has not been yet started)
    ced2  f8         RM

    ced3  4f         MOV C, A                   ; HL = Current line start address + line length
    ced4  06 00      MVI B, 00                  ; (end of the current line)
    ced6  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
    ced9  e5         PUSH HL
    ceda  09         DAD BC

    cedb  c2 df ce   JNZ FLUSH_STRING_BUF_1 (cedf)  ; HL is expected to point to the last char of the string

    cede  2b         DCX HL                     ; If string is empty move HL to the last char of prev string

FLUSH_STRING_BUF_1:
    cedf  3a 22 f7   LDA CUR_LINE_LEN (f722)    ; Calculate difference between old and new line length
    cee2  91         SUB C

    cee3  5f         MOV E, A                   ; Put difference to DE
    cee4  16 00      MVI D, 00                  ; DE = new line len - orig line len

    cee6  fc fe ce   CM SHIFT_TEXT_LEFT (cefe)  ; If difference is negative - shift remainder of file left

    cee9  c4 18 cf   CNZ SHIFT_TEXT_RIGHT (cf18); If difference is positive - shift remainder of file right

    ceec  d1         POP DE                     ; Copy line from the buffer to the text area
    ceed  21 e0 f6   LXI HL, f6e0

FLUSH_STRING_BUF_LOOP:
    cef0  7e         MOV A, M                   ; Load the next symbol. 
    cef1  b7         ORA A
    cef2  c2 f7 ce   JNZ FLUSH_STRING_BUF_2 (cef7)

    cef5  3e 0d      MVI A, 0d                  ; If the symbol is zero - replace it with \r

FLUSH_STRING_BUF_2:
    cef7  12         STAX DE                    ; Store the symbol

    cef8  c8         RZ                         ; Stop at zero symbol

    cef9  23         INX HL                     ; Advance to the next byte
    cefa  13         INX DE
    cefb  c3 f0 ce   JMP FLUSH_STRING_BUF_LOOP (cef0)


; Shift text left
;
; The function cuts a portion of file, and shifts remainder of file after the cut point left.
;
; Arguments:
; E - difference between old and new file size (negative)
; D - 0x00
; HL - pointer to the cut point (will cut left to the cut point)
SHIFT_TEXT_LEFT:
    cefe  15         DCR D                      ; E is negative difference, make D negative as well (0xff)

    ceff  e5         PUSH HL                    ; Calculate new line end (HL -= line len diff)              
    cf00  19         DAD DE

    cf01  44         MOV B, H                   ; Move to BC
    cf02  4d         MOV C, L

    cf03  2a 27 f7   LHLD END_OF_FILE_PTR (f727); Apply difference to end of file pointer
    cf06  e5         PUSH HL
    cf07  19         DAD DE
    cf08  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    cf0b  d1         POP DE                     ; HL - src ptr, BC - dst ptr
    cf0c  e1         POP HL                     ; DE - old end of file

CUT_TEXT_LOOP:
    cf0d  7e         MOV A, M                   ; Copy [HL] to [BC]
    cf0e  02         STAX BC

    cf0f  cd ea cc   CALL CMP_HL_DE (ccea)      ; Repeat until HL reaches DE
    cf12  c8         RZ

    cf13  23         INX HL                     ; Advance to the next byte
    cf14  03         INX BC
    cf15  c3 0d cf   JMP CUT_TEXT_LOOP (cf0d)

; Shift text right
;
; The function inserts a space in the middle of a file, and shifts remainder of file after the insertion
; point right
;
; Arguments:
; E - difference between old and new file size (positive)
; D - 0x00
; HL - pointer to the end of previous string (insertion point - 1)
SHIFT_TEXT_RIGHT:
    cf18  23         INX HL                     ; HL points to the end of previous string. Skip \r symbol
    cf19  e5         PUSH HL                    ; and advance to the beginning of the new line

    cf1a  2a 27 f7   LHLD END_OF_FILE_PTR (f727); Load end of data pointer
    cf1d  e5         PUSH HL

    cf1e  19         DAD DE                     ; Calculate new end of data pointer (apply difference)

    cf1f  cd aa cf   CALL CHECK_FILE_SIZE (cfaa); Check if the new file size does not exceed limits

    cf22  44         MOV B, H                   ; Store new end of file
    cf23  4d         MOV C, L
    cf24  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    cf27  e1         POP HL                     ; start/end pointers of the range to copy
    cf28  d1         POP DE


; Shift string right (copy string from last to first symbol)
; DE - start of source string
; HL - end of source string
; BC - end of target string
SHIFT_STR_RIGHT:
    cf29  7e         MOV A, M                   ; Copy one symbol
    cf2a  02         STAX BC

    cf2b  cd ea cc   CALL CMP_HL_DE (ccea)      ; Stop when reached the last symbol to copy
    cf2e  c8         RZ

    cf2f  2b         DCX HL                     ; Move to the previous symbol, and repeat
    cf30  0b         DCX BC
    cf31  c3 29 cf   JMP SHIFT_STR_RIGHT (cf29)


; Process down arrow key press
DOWN_ARROW:
    cf34  3a 25 f7   LDA CURSOR_Y (f725)        ; If the screen is not yet initialized - draw it
    cf37  b7         ORA A
    cf38  fa 0e d0   JM REDRAW_SCREEN (d00e)

    cf3b  0e 1a      MVI C, 1a                  ; Move cursor down
    cf3d  cd 09 f8   CALL PUT_CHAR (f809)

    cf40  cd ce ce   CALL FLUSH_STRING_BUF (cece)   ; Flush the buffer, if the line was changed

    cf43  cd 89 cf   CALL GET_NEXT_LINE_ADDR (cf89) ; Check there is line of text below. If not - show just last
                                                    ; 2 lines on the screen. 
                                                    ; BUG: This behavior looks weird, it would be better not to
                                                    ; scroll more if there is no data

    cf46  21 25 f7   LXI HL, CURSOR_Y (f725)    ; Increment Cursor Y position
    cf49  34         INR M
    cf4a  7e         MOV A, M

    cf4b  fe 1f      CPI A, 1f                  ; Check if it reached end of the screen
                                                ; BUG: UT-88 has only 28 lines, not 32

    cf4d  f2 5e cf   JP SCROLL_DOWN (cf5e)      ; Handle if cursor moved beyond bottom of screen


    cf50  3a 22 f7   LDA CUR_LINE_LEN (f722)    ; Calculate end of the previous line
    cf53  4f         MOV C, A                   ; BUG? GET_NEXT_LINE_ADDR call above did this already
    cf54  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
    cf57  06 00      MVI B, 00
    cf59  09         DAD BC

    cf5a  23         INX HL                     ; Skip \r at the end of the line, HL points to the next line

    cf5b  c3 2b ce   JMP LOAD_LINE (ce2b)


; Scroll screen 1 line down
;
; The function searches start of the next line, and loads it to HL. DRAW_SCREEN function will redraw
; the screen starting from calculated position.
SCROLL_DOWN:
    cf5e  2a 29 f7   LHLD PAGE_START_ADDR (f729); Load page start address (first line on the screen)

SCROLL_DOWN_LOOP:
    cf61  7e         MOV A, M                   ; Search for end of the line
    cf62  d6 0d      SUI A, 0d
    cf64  23         INX HL
    cf65  c2 61 cf   JNZ SCROLL_DOWN_LOOP (cf61)

    cf68  c3 fd cc   JMP DRAW_SCREEN (ccfd)


; Page down, scroll down for 31 line (Ctrl-Down combination)
PAGE_DOWN:
    cf6b  cd ce ce   CALL FLUSH_STRING_BUF (cece)   ; Flush currently edited string

    cf6e  cd 89 cf   CALL GET_NEXT_LINE_ADDR (cf89) ; Perform scroll to last 2 lines if page down is requested
                                                    ; and there is not enough lines to show.
                                                    ; BUG: This function expects CUR_LINE_PTR to point to the last
                                                    ; line shown on screen. But if the User edited a line on the
                                                    ; last screen, CUR_LINE_PTR will point to other line, and
                                                    ; scroll to last line will not happen. Instead code below will
                                                    ; search for another 32 lines and possibly crash.

    cf71  2a 29 f7   LHLD PAGE_START_ADDR (f729); Load current page start

    cf74  06 1f      MVI B, 1f                  ; Will scroll down for 0x1f lines
                                                ; BUG: UT-88 screen has only 28 lines, not 32

PAGE_DOWN_SEARCH_EOL_LOOP:
    cf76  7e         MOV A, M                   ; Load the next symbol

    cf77  fe 0d      CPI A, 0d                  ; Search for the \r symbol
    cf79  ca 80 cf   JZ PAGE_DOWN_NEXT_LINE (cf80)

PAGE_DOWN_NEXT_CHAR:
    cf7c  23         INX HL                     ; Advance to the next symbol
    cf7d  c3 76 cf   JMP PAGE_DOWN_SEARCH_EOL_LOOP (cf76)

PAGE_DOWN_NEXT_LINE:
    cf80  05         DCR B                      ; Repeat search for 0x1f lines
    cf81  c2 7c cf   JNZ PAGE_DOWN_NEXT_CHAR (cf7c)

PAGE_DOWN_FINISH:
    cf84  06 02      MVI B, 02                  ; Now move 2 strings up (so that first 2 strings on the screen
    cf86  c3 99 ce   JMP DO_SCROLL_UP (ce99)    ; are last 2 strings of the previous page)


; Calculate and return a pointer to the next line start
;
; If the function is called for the last line, and there is no text beyond the line, function scrolls the 
; screen to the 2nd line to the end of file.
;
; Note: This function overall is quite weird. It calculates some value, which is never used on the caller side.
; At the same time this function is supposed to scroll screen if called beyond end of text. At the same time
; there is no guarantee that CUR_LINE_PTR points to the last line on the screen - if user edits a line on the 
; last page, the CUR_LINE_PTR will point to an intermediate line, and scroll will not happen. Instead causes bug
; elsewhere, as other code expects this function to make a scroll which was not happen.
GET_NEXT_LINE_ADDR:
    cf89  2a 2b f7   LHLD CUR_LINE_PTR (f72b)   ; Get current line text ptr
    cf8c  3a 22 f7   LDA CUR_LINE_LEN (f722)    ; Get current line length

    cf8f  4f         MOV C, A                   ; Add the 2 values
    cf90  06 00      MVI B, 00
    cf92  09         DAD BC

    cf93  23         INX HL                     ; Advance to the next symbol (beginning of the next line)

    cf94  7e         MOV A, M                   ; Nothing to do if there is a valid text there, return
    cf95  b7         ORA A
    cf96  f0         RP

    cf97  c1         POP BC                     ; Ignore return address

    cf98  c3 fe d0   JMP d0fe                   ; Scroll to the second line before the end
                                                ; BUG: there may be less than 2 line in the text

; Search end of file marker (symbol with code >=0x80)
GET_END_OF_FILE:
    cf9b  21 00 30   LXI HL, 3000               ; Set the start address

GET_END_OF_FILE_LOOP:
    cf9e  7e         MOV A, M                   ; Check the next char. Return if EOF char (>=0x80) is found
    cf9f  b7         ORA A
    cfa0  f8         RM

    cfa1  06 00      MVI B, 00                  ; Check content size does not exceed 0x9fff
    cfa3  cd aa cf   CALL CHECK_FILE_SIZE (cfaa)

    cfa6  23         INX HL                     ; Advance to the next byte and repeat
    cfa7  c3 9e cf   JMP GET_END_OF_FILE_LOOP (cf9e)



; Check that file size is within 0x9fff memory range, otherwise report an error
CHECK_FILE_SIZE:
    cfaa  eb         XCHG                       ; Compare HL with 0x9fff
    cfab  21 ff 9f   LXI HL, 9fff
    cfae  eb         XCHG

    cfaf  cd ea cc   CALL CMP_HL_DE (ccea)      ; Return if HL has not exceeded 0x9fff
    cfb2  d8         RC

    cfb3  36 ff      MVI M, ff                  ; Make sure text is truncated at 0x9fff

    cfb5  11 02 d3   LXI DE, LONG_FILE_STR (d302)   ; Inform the user about file is too long
    cfb8  c3 12 ce   JMP PRINT_ERROR (ce12)


????_COMMAND_D:
cfbb  cd c7 ce   CALL cec7
cfbe  2a 29 f7   LHLD PAGE_START_ADDR (f729)
cfc1  22 31 f7   SHLD f731
cfc4  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
cfc7  22 2d f7   SHLD f72d
cfca  cd ca cc   CALL PRINT_HASH_CURSOR (ccca)
????:
cfcd  cd b4 cb   CALL GET_KBD_KEY (cbb4)
cfd0  ca e4 cf   JZ cfe4
cfd3  d6 19      SUI A, 19
cfd5  ca 3f d0   JZ d03f
cfd8  3d         DCR A
cfd9  ca 14 d0   JZ d014
cfdc  fe 05      CPI A, 05
cfde  ca 0e d0   JZ REDRAW_SCREEN (d00e)
cfe1  c3 ee cf   JMP cfee
????:
cfe4  fe 1a      CPI A, 1a
cfe6  ca 23 d0   JZ d023
cfe9  fe 44      CPI A, 44
cfeb  ca f4 cf   JZ cff4
????:
cfee  cd db cc   CALL BEEP (ccdb)
cff1  c3 cd cf   JMP cfcd
????:
cff4  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
cff7  eb         XCHG
cff8  2a 31 f7   LHLD f731
cffb  22 29 f7   SHLD PAGE_START_ADDR (f729)
cffe  2a 2d f7   LHLD f72d
d001  44         MOV B, H
d002  4d         MOV C, L
d003  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
d006  cd 0d cf   CALL CUT_TEXT_LOOP (cf0d)
d009  60         MOV H, B
d00a  69         MOV L, C
d00b  22 27 f7   SHLD END_OF_FILE_PTR (f727)

; Re-draw current screen, starting from the same page start address
REDRAW_SCREEN:
    d00e  2a 29 f7   LHLD PAGE_START_ADDR (f729)    ; Load page start address
    d011  c3 fd cc   JMP DRAW_SCREEN (ccfd)         ; And run screen drawing procedure


????:
d014  cd 2f d0   CALL d02f
d017  ca ee cf   JZ cfee
d01a  cd 34 cf   CALL cf34
????:
d01d  cd 9e cc   CALL HOME_CURSOR (cc9e)
d020  c3 cd cf   JMP cfcd
????:
d023  cd 2f d0   CALL d02f
d026  ca ee cf   JZ cfee
d029  cd 6b cf   CALL PAGE_DOWN (cf6b)
d02c  c3 1d d0   JMP d01d
????:
d02f  e5         PUSH HL
d030  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
d033  3a 22 f7   LDA CUR_LINE_LEN (f722)
d036  5f         MOV E, A
d037  16 00      MVI D, 00
d039  19         DAD DE
d03a  23         INX HL
d03b  7e         MOV A, M
d03c  3c         INR A
d03d  e1         POP HL
d03e  c9         RET
????:
d03f  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
d042  eb         XCHG
d043  2a 2d f7   LHLD f72d
d046  cd ea cc   CALL CMP_HL_DE (ccea)
d049  ca ee cf   JZ cfee
d04c  3a 25 f7   LDA CURSOR_Y (f725)
d04f  b7         ORA A
d050  c2 59 d0   JNZ d059
d053  cd b1 ce   CALL HOME_KEY (ceb1)
d056  c3 cd cf   JMP cfcd

????:
d059  cd 1f ce   CALL UP_ARROW (ce1f)
d05c  c3 cd cf   JMP cfcd

; Insert a symbol at cursor position (Ctrl-Right). Shift the remaining part of the string right.
; HL - pointer to the cursor position in the line buffer
INSERT_SYMB:
    d05f  cd aa cb   CALL CHECK_SYMBOL_AT_CURSOR (cbaa) ; Check if we can insert symbol at cursor

INSERT_SYMB_1:
    d062  11 22 f7   LXI DE, CUR_LINE_LEN (f722)    ; Load current line length value
    d065  1a         LDAX DE

    d066  3c         INR A                          ; Increment line length and verify there is enough room for
    d067  fe 3f      CPI A, 3f                      ; inserted symbol
    d069  d2 db cc   JNC BEEP (ccdb)

    d06c  12         STAX DE                        ; Store new line length
    d06d  e5         PUSH HL

    d06e  cd cb d0   CALL SEARCH_END_OF_STRING (d0cb)   ; Search for the end of string in the buffer

    d071  23         INX HL                         ; Advance end of string for 1 symbol, and store address in BC
    d072  44         MOV B, H
    d073  4d         MOV C, L

    d074  d1         POP DE                         ; DE - pointer to the insertion point in the line buffer
    d075  2b         DCX HL                         ; HL - last char in the buffer before insertion

    d076  cd 29 cf   CALL SHIFT_STR_RIGHT (cf29)    ; Shift DE-HL part of the string 1 char right

    d079  36 20      MVI M, 20                      ; Insert a space

; Redraw screen from the current cursor position and till the end of the string
REDRAW_STRING:
    d07b  cd 18 f8   CALL PRINT_STRING (f818)       ; Print line buffer from the edit point

    d07e  0e 2a      MVI C, 2a                      ; Print '*'
    d080  cd 09 f8   CALL PUT_CHAR (f809)

    d083  0e 20      MVI C, 20                      ; Print space after line end, stay on the same position
    d085  cd 09 f8   CALL PUT_CHAR (f809)
    d088  cd cf cc   CALL PRINT_BACKSPACE (cccf)

    d08b  cd 9e cc   CALL HOME_CURSOR (cc9e)        ; Move cursor to the beginning of the line, then move cursor
    d08e  3a 23 f7   LDA CURSOR_X (f723)            ; right to the X cursor position (MonitorF does not provide
    d091  47         MOV B, A                       ; direct cursor movement functions)
    d092  0e 18      MVI C, 18
    d094  3e 01      MVI A, 01
    d096  eb         XCHG

; Print char in C register A*B times
PUT_CHAR_BLOCK:
    d097  b7         ORA A                      ; Do not print anything if A is zero
    d098  c8         RZ

    d099  05         DCR B                      ; Do not print anything if B is zero
    d09a  f8         RM
    d09b  04         INR B
    d09c  c5         PUSH BC

PUT_CHAR_BLOCK_LOOP:
    d09d  cd 09 f8   CALL PUT_CHAR (f809)       ; Print the char in C register B times
    d0a0  05         DCR B
    d0a1  c2 9d d0   JNZ PUT_CHAR_BLOCK_LOOP (d09d)

    d0a4  c1         POP BC                     ; Decrement A
    d0a5  3d         DCR A
    d0a6  c8         RZ

    d0a7  c3 97 d0   JMP PUT_CHAR_BLOCK (d097)  ; Repeat if A is not zero


; Delete symbol at cursor (Ctrl-Left), shifting the rest of the line left 1 char
DELETE_SYMB:
    d0aa  cd aa cb   CALL CHECK_SYMBOL_AT_CURSOR (cbaa) ; Deleting at the end of text or at line end is not allowed
    d0ad  7e         MOV A, M
    d0ae  b7         ORA A
    d0af  ca db cc   JZ BEEP (ccdb)

    d0b2  eb         XCHG                           ; DE - pointer to the edit point in the line buffer

    d0b3  21 22 f7   LXI HL, CUR_LINE_LEN (f722)    ; Decrement line length
    d0b6  35         DCR M

    d0b7  eb         XCHG                           ; Save cut point address
    d0b8  e5         PUSH HL
    d0b9  e5         PUSH HL
    d0ba  e5         PUSH HL

    d0bb  cd cb d0   CALL SEARCH_END_OF_STRING (d0cb)   ; Get the real length of the data in line buffer

    d0be  eb         XCHG                           ; BC - edit point
    d0bf  c1         POP BC                         ; HL - edit point + 1
    d0c0  e1         POP HL                         ; DE - end of the line
    d0c1  23         INX HL

    d0c2  cd 0d cf   CALL CUT_TEXT_LOOP (cf0d)      ; Shift HL-DE range 1 char left

    d0c5  d1         POP DE                         ; Restore edit point address in HL
    d0c6  62         MOV H, D
    d0c7  6b         MOV L, E

    d0c8  c3 7b d0   JMP REDRAW_STRING (d07b)       ; And redraw the string after the edit point


; Search for a zero character
SEARCH_END_OF_STRING:
    d0cb  7e         MOV A, M                   ; Check if the char is zero
    d0cc  b7         ORA A
    d0cd  c8         RZ

    d0ce  23         INX HL                     ; Advance to the next char, and repeat
    d0cf  c3 cb d0   JMP SEARCH_END_OF_STRING (d0cb)


????_COMMAND_A:
d0d2  cd c7 ce   CALL cec7
d0d5  cd 9e cc   CALL HOME_CURSOR (cc9e)
d0d8  cd 34 cf   CALL cf34
d0db  cd 5c cd   CALL DRAW_SCREEN_FINISH_2 (cd5c)
????:
d0de  af         XRA A
d0df  32 21 f7   STA f721
d0e2  cd 20 cc   CALL INPUT_LINE (cc20)
d0e5  da 0e d0   JC REDRAW_SCREEN (d00e)

d0e8  cd ce ce   CALL FLUSH_STRING_BUF (cece)
d0eb  3a 22 f7   LDA CUR_LINE_LEN (f722)
d0ee  5f         MOV E, A
d0ef  16 00      MVI D, 00
d0f1  2a 2b f7   LHLD CUR_LINE_PTR (f72b)
d0f4  19         DAD DE
d0f5  22 2b f7   SHLD CUR_LINE_PTR (f72b)
d0f8  c3 de d0   JMP d0de

????_COMMAND_T:
d0fb  cd ce ce   CALL FLUSH_STRING_BUF (cece)

????:
    d0fe  2a 27 f7   LHLD END_OF_FILE_PTR (f727)    ; Get pointer to the last text char
    d101  2b         DCX HL

d102  cd 84 cf   CALL PAGE_DOWN_FINISH (cf84)

d105  3a 22 f7   LDA CUR_LINE_LEN (f722)
d108  4f         MOV C, A
d109  06 00      MVI B, 00
d10b  eb         XCHG
d10c  09         DAD BC
d10d  23         INX HL
d10e  22 2b f7   SHLD CUR_LINE_PTR (f72b)

d111  0e 1a      MVI C, 1a
d113  cd 09 f8   CALL PUT_CHAR (f809)

d116  c3 de d0   JMP d0de


NEW_FILE:
    d119  cd ce ce   CALL FLUSH_STRING_BUF (cece)   ; Flush current changes

    d11c  21 17 d3   LXI HL, NEW_FILE_PROMPT_STR (d317) ; Ask the User whether they really want a new file
    d11f  cd 18 f8   CALL PRINT_STRING (f818)

    d122  cd b4 cb   CALL GET_KBD_KEY (cbb4)    ; Get an answer, and check whether it is 'Y'
    d125  d6 59      SUI A, 59

    d127  c2 0c cb   JNZ EDITOR_MAIN_LOOP (cb0c); Non-Y will get the editor back to the main loop

    d12a  21 00 30   LXI HL, 3000               ; Add \r at the beginning of the text
    d12d  36 0d      MVI M, 0d

    d12f  23         INX HL                     ; Store the new End Of Text pointer
    d130  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    d133  36 ff      MVI M, ff                  ; Add end of text marker

    d135  c3 fe d0   JMP d0fe                   ; ??????


; Output file to the tape
;
; This function outputs the current text to the tape. The format is slightly different to what
; is used for storing programs. Perhaps this is done intentionally in order to avoid loading programs
; as text and vice versa.
;
; Output format is:
; - 0x55 bytes 0x55             - pilot tone
; - 0x55 bytes 0x00             - another pilot tone
; - 0x55 bytes 0x55             - pilot tone
; - 0x55 bytes 0x00             - another pilot tone
; - 5 bytes 0xe6                - Sync byte
; - zero terminated string      - file name
; - 2 bytes (low byte first)    - data size
; - 256 bytes 0x00              - pilot tone
; - 0xe6                        - sync byte
; - 2 bytes (high byte first)   - data start
; - 2 bytes (high byte first)   - data end
; - data bytes                  - data bytes
; - 2 bytes (low byte first)    - CRC
OUTPUT_FILE:
    d138  cd bf d1   CALL GET_FILE_NAME (d1bf)  ; Input file name

    d13b  13         INX DE                     ; Store file name end pointer BC
    d13c  42         MOV B, D
    d13d  4b         MOV C, E

    d13e  2a 27 f7   LHLD END_OF_FILE_PTR (f727)    ; Load the end of data pointer to DE
    d141  eb         XCHG

    d142  21 00 d0   LXI HL, d000               ; Subtract 0x3000 (file start) to get file size
    d145  19         DAD DE

    d146  d5         PUSH DE                    ; Prepare pointers:
    d147  e5         PUSH HL                    ; end of data, data size, and file name ptr are pushed 
    d148  21 00 30   LXI HL, 3000               ; on the stack
    d14b  c5         PUSH BC                    ; HL = text start; DE = text end + 1
    d14c  13         INX DE                     ; BC = file name end

    d14d  cd da d1   CALL CALCULATE_CRC (d1da)  ; Calculate CRC of the text

    d150  16 04      MVI D, 04                  ; 4 iterations of pilot tones
    
    d152  af         XRA A                      ; Even iterations use tone 0x00

OUTPUT_FILE_TONE_LOOP_1:
    d153  1e 55      MVI E, 55                  ; Each pilot tone is 0x55 bytes long

    d155  ab         XRA E                      ; Odd iterations use tone 0xff

OUTPUT_FILE_TONE_LOOP_2:
    d156  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output 0x55 bytes of the pilot tone
    d159  1d         DCR E
    d15a  c2 56 d1   JNZ OUTPUT_FILE_TONE_LOOP_2 (d156)

    d15d  15         DCR D                      ; Switch tone, and output next portion of the pilot tone
    d15e  c2 53 d1   JNZ OUTPUT_FILE_TONE_LOOP_1 (d153)

    d161  21 e0 f6   LXI HL, f6e0               ; HL - file name start
    d164  d1         POP DE                     ; DE - file name end
    d165  c5         PUSH BC                    ; Push CRC to stack

    d166  3e e6      MVI A, e6                  ; Output 4 sync bytes 0xe6 (in fact even 5)
    d168  06 04      MVI B, 04

OUTPUT_FILE_SYNC_BYTE_LOOP:
    d16a  cd 0c f8   CALL OUT_BYTE (f80c)
    d16d  05         DCR B
    d16e  c2 6a d1   JNZ OUTPUT_FILE_SYNC_BYTE_LOOP (d16a)

OUTPUT_FILE_NAME_LOOP:
    d171  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output next byte of the file name
    d174  cd ea cc   CALL CMP_HL_DE (ccea)

    d177  7e         MOV A, M                   ; Advance to the next byte, until zero byte is reached
    d178  23         INX HL
    d179  c2 71 d1   JNZ OUTPUT_FILE_NAME_LOOP (d171)

    d17c  c1         POP BC                     ; Restore CRC (BC), and data size (HL)
    d17d  e1         POP HL

    d17e  7d         MOV A, L                   ; Output data size, low byte first
    d17f  cd 0c f8   CALL OUT_BYTE (f80c)
    d182  7c         MOV A, H
    d183  cd 0c f8   CALL OUT_BYTE (f80c)

    d186  d1         POP DE                     ; Restore data end pointer

    d187  af         XRA A                      ; Output 256 zero bytes
    d188  6f         MOV L, A

OUTPUT_FILE_TONE_LOOP_3:
    d189  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output next zero byte
    d18c  2d         DCR L
    d18d  c2 89 d1   JNZ OUTPUT_FILE_TONE_LOOP_3 (d189)

    d190  21 00 30   LXI HL, 3000               ; Will start output data from 0x3000

    d193  3e e6      MVI A, e6                  ; Output 0xe6 sync byte
    d195  cd 0c f8   CALL OUT_BYTE (f80c)

    d198  7c         MOV A, H                   ; Output data start (high byte first)
    d199  cd 0c f8   CALL OUT_BYTE (f80c)
    d19c  7d         MOV A, L
    d19d  cd 0c f8   CALL OUT_BYTE (f80c)

    d1a0  7a         MOV A, D                   ; Output data end (high byte first)
    d1a1  cd 0c f8   CALL OUT_BYTE (f80c)
    d1a4  7b         MOV A, E
    d1a5  cd 0c f8   CALL OUT_BYTE (f80c)

    d1a8  13         INX DE

OUTPUT_FILE_DATA_LOOP:
    d1a9  7e         MOV A, M                   ; Output next data byte
    d1aa  23         INX HL
    d1ab  cd 0c f8   CALL OUT_BYTE (f80c)

    d1ae  cd ea cc   CALL CMP_HL_DE (ccea)      ; Until HL reaches DE (end of data)
    d1b1  c2 a9 d1   JNZ OUTPUT_FILE_DATA_LOOP (d1a9)

    d1b4  79         MOV A, C                   ; Output CRC (low byte first)
    d1b5  cd 0c f8   CALL OUT_BYTE (f80c)
    d1b8  78         MOV A, B
    d1b9  cd 0c f8   CALL OUT_BYTE (f80c)

    d1bc  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c)    ; Finish, exit to the main loop


; Input file name
; The function prints the "FILE?" prompt and waits for the user input
;
; Return: 
; File name in the 0xf6e0 buffer
; DE - pointer to the last entered symbol in the buffer
GET_FILE_NAME:
    d1bf  c5         PUSH BC                    ; Clear screen and show the prompt
    d1c0  cd fd cb   CALL CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT (cbfd)

    d1c3  21 1d d3   LXI HL, FILE_STR (d31d)    ; Print 'FILE' string
    d1c6  cd 18 f8   CALL PRINT_STRING (f818)

    d1c9  3e 3f      MVI A, 3f                  ; Print '?'
    d1cb  cd 0a cc   CALL PUT_CHAR_AND_SPACE (cc0a)

    d1ce  c1         POP BC                     ; Store the input mode in a variable
    d1cf  78         MOV A, B                   ; BUG? Why shall it belong to this function?
    d1d0  32 20 f7   STA INPUT_MODE (f720)

    d1d3  cd 20 cc   CALL INPUT_LINE (cc20)     ; Get the file name, exit to main loop in case of error
    d1d6  da 0c cb   JC EDITOR_MAIN_LOOP (cb0c)

    d1d9  c9         RET


; Calculate CRC by adding all bytes in the given range into 16-bit value
; Arguments:
; HL - start address
; DE - next byte after end address
; Return: CRC in BC
CALCULATE_CRC:
    d1da  e5         PUSH HL
    d1db  01 00 00   LXI BC, 0000               ; Zero result accumulator

CALCULATE_CRC_LOOP:
    d1de  7e         MOV A, M                   ; Add the next data byte to the accumulator
    d1df  81         ADD C
    d1e0  4f         MOV C, A

    d1e1  78         MOV A, B                   ; Adjust high byte if needed
    d1e2  ce 00      ACI A, 00
    d1e4  47         MOV B, A

    d1e5  23         INX HL                     ; Advance to the next byte

    d1e6  cd ea cc   CALL CMP_HL_DE (ccea)      ; Repeat until reached DE
    d1e9  c2 de d1   JNZ CALCULATE_CRC_LOOP (d1de)

    d1ec  e1         POP HL                     ; Return
    d1ed  c9         RET


; Read text file from the tape
;
; The function serves Command I (text input), M (merge file), and V (verify). The function works according
; to the following algorithm:
; - Ask user for the desired file name
; - Read the tape until 4 x 0xe6 marker bytes are found, followed by the file name. If the file name does not
;   match the requested one, the function will wait for another file record.
; - Data size field stored on the tape has priority over data start/end address fields
; - Command M calculates data start/end address so that it appends tape data to the text already in the
;   memory. Commands I and V will use 0x3000 as data start address.
; - Commands I and M do the actual data load according to calculated addresses.
; - Command V does not data verification, report mismatch errors if any.
; - CRC field stored at the end of file is checked against the memory data, report mismatch errors if any.
INPUT_FILE:
    d1ee  06 00      MVI B, 00                  ; Set the mode 0 - normal input file from tape

INPUT_FILE_1:
    d1f0  cd bf d1   CALL GET_FILE_NAME (d1bf)  ; Input file name
    d1f3  eb         XCHG                       ; DE buffer start, HL buffer end

INPUT_FILE_WAIT_SYNC_BYTE:
    d1f4  06 04      MVI B, 04                  ; Wait for 4 sync bytes in a raw
    d1f6  3e ff      MVI A, ff                  ; Expect synchronization first

INPUT_FILE_WAIT_SYNC_BYTE_LOOP:
    d1f8  cd 06 f8   CALL IN_BYTE (f806)        ; Read the byte, and check if it is 0xe6 sync byte
    d1fb  fe e6      CPI A, e6
    d1fd  c2 f4 d1   JNZ INPUT_FILE_WAIT_SYNC_BYTE (d1f4)

    d200  05         DCR B                      ; Another sync byte received, look for the next one
    d201  3e 08      MVI A, 08
    d203  c2 f8 d1   JNZ INPUT_FILE_WAIT_SYNC_BYTE_LOOP (d1f8)

    d206  21 a0 f6   LXI HL, f6a0               ; Will compare file name on the tape with one in the buffer
                                                ; BUG: File name is received from the tape into the same
                                                ; buffer where user types file name from the keyboard. So
                                                ; in fact comparison will happen to self, and file names will
                                                ; always match.

; Read the file name from the tape, anc compare it with requested one
INPUT_FILE_NAME_LOOP:
    d209  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)

    d20c  77         MOV M, A                   ; Receive next byte of the file name
    d20d  b7         ORA A 

    d20e  23         INX HL                     ; Advance to the next byte, until a zero byte is found
    d20f  c2 09 d2   JNZ INPUT_FILE_NAME_LOOP (d209)

    d212  cd df d2   CALL IN_BYTE_NO_SYNC (d2df); Input data size
    d215  4f         MOV C, A
    d216  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d219  47         MOV B, A

    d21a  c5         PUSH BC                    ; Print "FILE" string
    d21b  21 1d d3   LXI HL, FILE_STR (d31d)
    d21e  cd 18 f8   CALL PRINT_STRING (f818)

    d221  3e 3a      MVI A, 3a                  ; Print ':'
    d223  cd 0a cc   CALL PUT_CHAR_AND_SPACE (cc0a)

    d226  21 a0 f6   LXI HL, f6a0               ; Print received file name
    d229  e5         PUSH HL
    d22a  cd 18 f8   CALL PRINT_STRING (f818)
    d22d  e1         POP HL

INPUT_FILE_NAME_COMPARE_LOOP:
    d22e  1a         LDAX DE                    ; Stop name comparison when terminating zero is found
    d22f  b7         ORA A
    d230  ca 3d d2   JZ INPUT_FILE_2 (d23d)

    d233  be         CMP M                      ; Compare next byte of the file name
    d234  23         INX HL
    d235  13         INX DE
    d236  ca 2e d2   JZ INPUT_FILE_NAME_COMPARE_LOOP (d22e)

    d239  c1         POP BC                     ; If the file name was not matched - look for another file
    d23a  c3 f4 d1   JMP INPUT_FILE_WAIT_SYNC_BYTE (d1f4)

; This part calculates data start/end address for Command M (Merge)
INPUT_FILE_2:
    d23d  c1         POP BC                     ; Restore file size. Check it is zero
    d23e  78         MOV A, B
    d23f  b1         ORA C

    d240  f5         PUSH PSW
    d241  c5         PUSH BC

    d242  3a 20 f7   LDA INPUT_MODE (f720)      ; Code below is executed for Command M only, otherwise skip
    d245  3d         DCR A             
    d246  fa 5d d2   JM INPUT_FILE_3 (d25d)

    d249  2a 27 f7   LHLD END_OF_FILE_PTR (f727); end of current file += loaded file size
    d24c  d1         POP DE
    d24d  e5         PUSH HL
    d24e  19         DAD DE

    d24f  cd aa cf   CALL CHECK_FILE_SIZE (cfaa); Check the new file size does not exceed limits

    d252  eb         XCHG                       ; Print error if loaded file size is zero
    d253  e1         POP HL
    d254  f1         POP PSW
    d255  ca d6 d2   JZ INPUT_FILE_ERROR (d2d6)

    d258  af         XRA A                      ; Rest of the function act as Command I (normal file input)
    d259  f5         PUSH PSW

    d25a  c3 86 d2   JMP INPUT_FILE_4 (d286)

; This part calculates start/end address depending on data size field stored on the tape, or (if it zero)
; on data start/end address stored on the tape.
INPUT_FILE_3:
    d25d  3c         INR A                      ; Get 0 for command I, 0xff for Ccommand V

    d25e  21 00 30   LXI HL, 3000               ; Calculate end of data address (0x3000+file size)
    d261  eb         XCHG
    d262  e1         POP HL
    d263  19         DAD DE

    d264  f5         PUSH PSW                   ; Check if the file fits into the memory
    d265  d5         PUSH DE
    d266  cd aa cf   CALL CHECK_FILE_SIZE (cfaa)
    d269  d1         POP DE

    d26a  eb         XCHG                       ; Restore and check the data size
    d26b  c1         POP BC
    d26c  f1         POP PSW
    d26d  c5         PUSH BC

    d26e  c2 86 d2   JNZ INPUT_FILE_4 (d286)    ; If file size is not zero - use it for calculating end addr

    d271  3e ff      MVI A, ff                  ; If file size value is zero try to guess it from data start
    d273  cd 06 f8   CALL IN_BYTE (f806)        ; and data end fields. Load data start field first
    d276  67         MOV H, A
    d277  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d27a  6f         MOV L, A

    d27b  cd df d2   CALL IN_BYTE_NO_SYNC (d2df); Then load data end field
    d27e  57         MOV D, A
    d27f  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d282  5f         MOV E, A

    d283  c3 94 d2   JMP INPUT_FILE_5 (d294)    ; Continue with loading the file data

INPUT_FILE_4:
    d286  3e ff      MVI A, ff                  ; Data size field is non-zero. Ignore data start/end fields
    d288  cd 06 f8   CALL IN_BYTE (f806)
    d28b  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d28e  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d291  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)

INPUT_FILE_5:
    d294  13         INX DE                     ; Set DE 1 byte after data end

    d295  f1         POP PSW                    ; Restore input mode. Command I will actually load data
    d296  e5         PUSH HL                    ; from tape.
    d297  c2 c5 d2   JNZ d2c5                   ; Command V (validation) will be processed elsewhere

; This part actually loads the data from tape to the memory
INPUT_FILE_DATA_LOOP:
    d29a  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)    ; Read next data byte
    d29d  77         MOV M, A
    d29e  23         INX HL

    d29f  cd ea cc   CALL CMP_HL_DE (ccea)          ; Repeat until end of data is reached
    d2a2  c2 9a d2   JNZ INPUT_FILE_DATA_LOOP (d29a)

; This is the final stage of the algorithm - comparing the calculated CRC on the data in memory
; with the CRC value stored on the tape. Report an error in case of mismatch
INPUT_FILE_CHECK_CRC:
    d2a5  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)    ; Read CRC value
    d2a8  4f         MOV C, A
    d2a9  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d2ac  47         MOV B, A

    d2ad  e1         POP HL                     ; Calculate actual data CRC
    d2ae  c5         PUSH BC
    d2af  cd da d1   CALL CALCULATE_CRC (d1da)
    d2b2  e1         POP HL

    d2b3  7c         MOV A, H                   ; Compare calculated and read CRC. Report error in case of
    d2b4  b8         CMP B                      ; mismatch
    d2b5  c2 d6 d2   JNZ INPUT_FILE_ERROR (d2d6)
    d2b8  7d         MOV A, L
    d2b9  b9         CMP C
    d2ba  c2 d6 d2   JNZ INPUT_FILE_ERROR (d2d6)

    d2bd  1b         DCX DE                     ; Update end of file pointer
    d2be  eb         XCHG
    d2bf  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    d2c2  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c); Return to the main loop

; This part serves Command V (Verify) and compares data on the tape with data in memory
INPUT_FILE_DATA_COMPARE_LOOP:
    d2c5  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)    ; Compare next data byte
    d2c8  be         CMP M

    d2c9  23         INX HL                         ; Advance to the next byte

    d2ca  c2 d6 d2   JNZ INPUT_FILE_ERROR (d2d6)    ; Report error in case of mismatch

    d2cd  cd ea cc   CALL CMP_HL_DE (ccea)          ; Repeat until end of data reached
    d2d0  c2 c5 d2   JNZ INPUT_FILE_DATA_COMPARE_LOOP (d2c5)

    d2d3  c3 a5 d2   JMP INPUT_FILE_CHECK_CRC (d2a5); Proceed with the next step (CRC match)


; Report "I/O ERROR", beep, and exit to main loop
INPUT_FILE_ERROR:
    d2d6  11 0c d3   LXI DE, IO_DEVICE_STR (d30c)   ; Print error string
    d2d9  cd 12 ce   CALL PRINT_ERROR (ce12)

    d2dc  c3 f7 cb   JMP BEEP_AND_EXIT (cbf7)

; Input a byte, assuming sync has been already happened
IN_BYTE_NO_SYNC:
    d2df  3e 08      MVI A, 08
    d2e1  c3 06 f8   JMP IN_BYTE (f806)

; Command Ctrl-V: Verify file on tape with text in memory
;
; The command works almost the same way as Input File command, except for data from the tape is
; not loaded to the memory, but just compared with the data that is in memory already. In case of
; mismatch an error will be shown.
VERIFY_FILE:
    d2e4  06 ff      MVI B, ff                  ; Input Mode 0xff - verify
    d2e6  c3 f0 d1   JMP INPUT_FILE_1 (d1f0)


; Command Ctrl-M: Merge file (append text file from the tape at the end of existing text)
;
; This command is another variation of the Input File function. It also reads the file from the tape,
; but start and end address is calculated so that file is loaded right after existing text.
MERGE_FILE:
    d2e9  06 01      MVI B, 01                  ; Input Mode 0x01 - Merge
    d2eb  c3 f0 d1   JMP INPUT_FILE_1 (d1f0)

ERROR_STR:
    d2ee  0a 45 52 52 4f 52 3a 00   db "\rERROR:", 0x00
    
LONG_STRING_STR:
    d2f6  4c 4f 4e 47 20 53 54 52   db "LONG STR"
    d2fe  49 4e 47 00               db "ING", 0x00

LONG_FILE_STR:
    d302  4c 4f 4e 47 20 46 49 4c   db "LONG FIL"
    d30a  45 00                     db "E", 0x00

IO_DEVICE_STR:
    d30c  49 2f 4f 20 44 45 56 49   db "I/O DEVI"
    d314  43 45 00                  db "CE", 0x00

NEW_FILE_PROMPT_STR:
    d317  1f 4e 45 57 3f 00         db 0x1f, "NEW?", 0x00

FILE_STR:
    d31d  0a 46 49 4c 45 00         db "\rFILE", 0x00

HELLO_STR:
    d323  0a 45 44 49 54 20 2a 6d   db "\rEDIT *М"
    d32b  69 6b 72 6f 6e 2a 0a 2a   db "ИКРОН*\r*"
    d333  00                        db 0x00

????:
    d334  0a 45 4e 44 3d 00         db "\rEND=", 0x00
    
????:
    d33a  20 20 55 53 45 44 3d 00   db "  USED=", 0x00
    
????:
    d342  20 20 46 52 45 45 3d 00   db "  FREE=", 0x00


; The following is the table of command handlers
;
; BUG (or at least incompatibility): It is supposed to enter commands with the Ctrl key. First issue, is
; that GET_KBD_KEY function is looking for a high bit of the Keyboard's Port C, while the Ctrl key is 
; connected to 1st bit of that port. Another issue is that Ctrl-<char> combinations produce char codes in
; 0x01-0x1a range, while the table below expects normal char codes (in 0x41-0x5a range)
COMMAND_HANDLERS:
    d34a  4c c6 cb      db 'L', ????_COMMAND_L (cbc6)
    d34d  58 be cb      db 'X', ????_COMMAND_X (cbbe)
    d350  44 bb cf      db 'D', ????_COMMAND_D (cfbb)
    d353  41 d2 d0      db 'A', ????_COMMAND_A (d0d2)
    d356  54 fb d0      db 'T', ????_COMMAND_T (d0fb)
    d359  4e 19 d1      db 'N', NEW_FILE (d119)
    d35c  4f 38 d1      db 'O', OUTPUT_FILE (d138)
    d35f  49 ee d1      db 'I', INPUT_FILE (d1ee)
    d362  56 e4 d2      db 'V', VERIFY_FILE (d2e4)
    d365  4d e9 d2      db 'M', MERGE_FILE (d2e9)
    d368  57 88 cd      db 'W', TOGGLE_TAB_SIZE (cd88)
    d36b  52 a7 cd      db 'R', ????_COMMAND_R (cda7)
    d36e  46 bf cd      db 'F', ????_COMMAND_F (cdbf)
    d371  59 9d cd      db 'Y', TOGGLE_INSERT (cd9d)
    d374  08 aa d0      db 0x08, DELETE_SYMB (d0aa)
    d377  18 5f d0      db 0x18, INSERT_SYMB (d05f)
    d37a  19 91 ce      db 0x19, PAGE_UP (ce91)
    d37d  1a 6b cf      db 0x1a, PAGE_DOWN (cf6b)
    d380  00            db 00               ; End of the table

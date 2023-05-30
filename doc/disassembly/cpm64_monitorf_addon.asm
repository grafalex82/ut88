; Monitor F console output patch
;
; This code is loaded to the memory by CP/M initial bootloader, and initially is located at
; 0x31e0-0x32ff address range of the CP/M binary
;
; This file contains a small addition to the Monitor'S F put character functions. The goal of the
; addition is to add support of some ANSI escape sequences (sort of), more than Monitor-F is capable
; of out of the box.
;
; The following escape sequences are supported:
; ESC A     - Move cursor one position down
; ESC B     - Move cursor one position up
; ESC C     - Move cursor one position right
; ESC D     - Move cursor one position left
; ESC E     - Clear screen
; ESC H     - Move cursor to the top-left position
; ESC J     - Clear screen starting from cursor position till the bottom-right corner
; ESC K     - Clear line starting from cursor position till the end of the line
; ESC Y <Y> <X> - Move cursor to the new position. X and Y values are 0x20 based
;
; Regular characters are printed normally using the Monitor-F PUR_CHAR_C function.
; 
; Issues:
; Perhaps this code was initially ported from some other machine, that does not support ESC-Y sequence.
; This is the only explanation why this code implements the same feature, without any extra functionality.
;
; This port also has a few obvious bugs, that perhaps caused by quick port from other platform:
; - The code expects cursor position to be located at 0xf75a, while in fact this should be 0xf7b2 for the
;   UT-88 Monitor F
; - This code highlights and de-highlights the cursor symbol by writing at -0x800 bytes compared to the
;   cursor position. Perhaps some of the machines use different memory range for char attributes. On a real
;   UT-88 hardware this trick might work as well as since 0xe000 and 0xe800 memory ranges are physically
;   mapped to the same RAM. For emulation purposes the -0x800 offset was corrected to 0x0000
    
PUT_CHAR_CPM:
    f500  e5         PUSH HL
    f501  c5         PUSH BC
    f502  d5         PUSH DE
    f503  f5         PUSH PSW

    f504  3a 15 f6   LDA ESC_SEQ_CHAR_NO (f615) ; Check if this is a first character in the escape sequence
    f507  fe 00      CPI A, 00
    f509  c2 30 f5   JNZ ESC_SEQ_CHAR_2ND (f530); Handle the continuation of the escape sequence

    f50c  79         MOV A, C                   ; Character with codes >= 0x20 are printed normally
    f50d  fe 20      CPI A, 20
    f50f  d2 12 f6   JNC DO_MONITOR_PUT_CHAR (f612)

    f512  fe 08      CPI A, 08                  ; Backspace is printed normally (via monitor routine) as well
    f514  ca 12 f6   JZ DO_MONITOR_PUT_CHAR (f612)

    f517  fe 0a      CPI A, 0a                  ; ... same as new line
    f519  ca 12 f6   JZ DO_MONITOR_PUT_CHAR (f612)

    f51c  fe 0d      CPI A, 0d                  ; ... and carriage return
    f51e  ca 12 f6   JZ DO_MONITOR_PUT_CHAR (f612)

    f521  fe 1b      CPI A, 1b                  ; All other characters (except for ESC) are not printed
    f523  c2 2b f5   JNZ PUT_CHAR_CPM_EXIT (f52b)

    f526  3e 01      MVI A, 01                  ; Set flag indicating ESC symbol is accepted
    f528  32 15 f6   STA ESC_SEQ_CHAR_NO (f615)

PUT_CHAR_CPM_EXIT:
    f52b  f1         POP PSW
    f52c  d1         POP DE
    f52d  c1         POP BC
    f52e  e1         POP HL
    f52f  c9         RET

; Match the second character in escape sequence
;
; We are here if Esc character is matched, and we are looking for a next character in the sequence
ESC_SEQ_CHAR_2ND:
    f530  3a 15 f6   LDA ESC_SEQ_CHAR_NO (f615) ; This section handles the second byte of escape sequence
    f533  fe 01      CPI A, 01
    f535  c2 b9 f5   JNZ ESC_SEQ_CHAR_3RD (f5b9); Handle 3+ bytes elsewhere

    f538  79         MOV A, C                   ; Check if this Esc-A sequence
    f539  fe 41      CPI A, 41
    f53b  c2 43 f5   JNZ ESC_SEQ_CHAR_2ND_1 (f543)

    f53e  0e 19      MVI C, 19                  ; Esc-A sequence means move cursor one line up
    f540  c3 0d f6   JMP ESC_PRINT_LAST_CHAR (f60d)


ESC_SEQ_CHAR_2ND_1:
    f543  fe 42      CPI A, 42                  ; Check if this is Esc-B sequence
    f545  c2 4d f5   JNZ ESC_SEQ_CHAR_2ND_2 (f54d)

    f548  0e 1a      MVI C, 1a                  ; Esc-B sequence means move cursor one line down
    f54a  c3 0d f6   JMP ESC_PRINT_LAST_CHAR (f60d)


ESC_SEQ_CHAR_2ND_2:
    f54d  fe 43      CPI A, 43                  ; Check if this is Esc-C sequence
    f54f  c2 57 f5   JNZ ESC_SEQ_CHAR_2ND_3 (f557)

    f552  0e 18      MVI C, 18                  ; Esc-C sequence means move cursor one column right
    f554  c3 0d f6   JMP ESC_PRINT_LAST_CHAR (f60d)

ESC_SEQ_CHAR_2ND_3:
    f557  fe 44      CPI A, 44                  ; Check if this is Esc-D sequence
    f559  c2 61 f5   JNZ ESC_SEQ_CHAR_2ND_4 (f561)

    f55c  0e 08      MVI C, 08                  ; Esc-D sequence means move cursor one column left
    f55e  c3 0d f6   JMP ESC_PRINT_LAST_CHAR (f60d)

ESC_SEQ_CHAR_2ND_4:
    f561  fe 45      CPI A, 45                  ; Check if this is a Esc-E sequence
    f563  c2 6b f5   JNZ ESC_SEQ_CHAR_2ND_5 (f56b)

    f566  0e 1f      MVI C, 1f                  ; Esc-E sequence means clearing the screen
    f568  c3 0d f6   JMP ESC_PRINT_LAST_CHAR (f60d)

ESC_SEQ_CHAR_2ND_5:
    f56b  fe 48      CPI A, 48                  ; Check if this is a Esc-H sequence
    f56d  c2 75 f5   JNZ ESC_SEQ_CHAR_2ND_6 (f575)

    f570  0e 0c      MVI C, 0c                  ; Esc-H sequence means moving the cursor to top-left position
    f572  c3 0d f6   JMP ESC_PRINT_LAST_CHAR (f60d)

ESC_SEQ_CHAR_2ND_6:
    f575  fe 4a      CPI A, 4a                  ; Check if this is a Esc-J sequence
    f577  c2 8a f5   JNZ ESC_SEQ_CHAR_2ND_7 (f58a)

    f57a  2a 5a f7   LHLD f75a                  ; Load cursor position. BUG: shall be f7b2

    f57d  3e f0      MVI A, f0                  ; Will be printing spaces (0x20) until reached end of video
    f57f  06 20      MVI B, 20                  ; memory (0xf0xx)

CLEAR_SCREEN_LOOP:
    f581  70         MOV M, B
    f582  23         INX HL
    f583  bc         CMP H
    f584  c2 81 f5   JNZ CLEAR_SCREEN_LOOP (f581)

    f587  c3 05 f6   JMP PUT_CHAR_CPM_EXIT_NO_CHAR (f605)

ESC_SEQ_CHAR_2ND_7:
    f58a  fe 4b      CPI A, 4b                  ; Check if this is a Esc-K sequence
    f58c  c2 a3 f5   JNZ ESC_SEQ_CHAR_2ND_8 (f5a3)

    f58f  2a 5a f7   LHLD f75a                  ; Load cursor position. BUG: shall be f7b2

    f592  af         XRA A                      ; Calculate address of the next line
    f593  7d         MOV A, L
    f594  e6 c0      ANI A, c0
    f596  c6 40      ADI A, 40

    f598  06 20      MVI B, 20                  ; Will be printing spaces

CLEAR_LINE_LOOP:
    f59a  70         MOV M, B
    f59b  23         INX HL
    f59c  bd         CMP L
    f59d  c2 9a f5   JNZ CLEAR_LINE_LOOP (f59a)

    f5a0  c3 05 f6   JMP PUT_CHAR_CPM_EXIT_NO_CHAR (f605)

ESC_SEQ_CHAR_2ND_8:
    f5a3  fe 59      CPI A, 59                  ; Check if this is Esc-Y sequence
    f5a5  c2 17 f6   JNZ ESC_SEQ_CHAR_2ND_9 (f617)

    f5a8  2a 5a f7   LHLD f75a                  ; Load cursor position. BUG: shall be f7b2

    f5ab  11 01 f8   LXI DE, f801               ; Clear the cursor highlight (in case UT-88 it is a next
    f5ae  19         DAD DE                     ; symbol after the cursor position). BUG: this shall be
    f5af  36 00      MVI M, 00                  ; 0x0001 difference, not 0xf801

    f5b1  3e 02      MVI A, 02                  ; Will be waiting for 3rd symbol in the sequence
    f5b3  32 15 f6   STA ESC_SEQ_CHAR_NO (f615)

    f5b6  c3 2b f5   JMP PUT_CHAR_CPM_EXIT (f52b)

; Process the 3rd character in the sequence
;
; Perhaps Esc-Y sequence is matched, and we are waiting for 2 more screen coordinate
ESC_SEQ_CHAR_3RD:
    f5b9  79         MOV A, C                   ; Check if another escape character is there
    f5ba  fe 1b      CPI A, 1b
    f5bc  c2 c9 f5   JNZ ESC_SEQ_CHAR_3RD_1 (f5c9)

    f5bf  3e 01      MVI A, 01                  ; Reset the escape sequence, and wait for 2nd character
    f5c1  32 15 f6   STA ESC_SEQ_CHAR_NO (f615)

    f5c4  0e 1f      MVI C, 1f                  ; Clear the screen ????
    f5c6  c3 12 f6   JMP DO_MONITOR_PUT_CHAR (f612)

ESC_SEQ_CHAR_3RD_1:
    f5c9  3a 15 f6   LDA ESC_SEQ_CHAR_NO (f615) ; Here we handle 3rd byte of the sequence
    f5cc  fe 02      CPI A, 02
    f5ce  c2 e0 f5   JNZ ESC_SEQ_CHAR_4TH (f5e0); Handle 4th byte elsewhere

    f5d1  af         XRA A                      ; Subtract 0x20 from the character, and remember Y coordinate
    f5d2  79         MOV A, C                   ; until 4th byte is received
    f5d3  de 20      SBI A, 20
    f5d5  32 16 f6   STA ESC_SEQ_MOVE_Y (f616)

    f5d8  3e 03      MVI A, 03                  ; Expect 4th byte of the sequence
    f5da  32 15 f6   STA ESC_SEQ_CHAR_NO (f615)

    f5dd  c3 2b f5   JMP PUT_CHAR_CPM_EXIT (f52b)

; Match the 4th byte of the sequence
;
; We are here when Matched Esc-Y <Y> sequence already. Match the <X> coordinate
ESC_SEQ_CHAR_4TH:
    f5e0  af         XRA A                      ; Calculate the X coordinate
    f5e1  79         MOV A, C
    f5e2  de 20      SBI A, 20

    f5e4  fe 3f      CPI A, 3f                  ; Check if it is in the screen range
    f5e6  da eb f5   JC ESC_SEQ_CHAR_4TH_1 (f5eb)

    f5e9  3e 3f      MVI A, 3f                  ; Limit it with the right column if needed

ESC_SEQ_CHAR_4TH_1:
    f5eb  6f         MOV L, A                   ; Load the X coordinate to L

    f5ec  3a 16 f6   LDA ESC_SEQ_MOVE_Y (f616)  ; Load the Y coordinate

    f5ef  0f         RRC
    f5f0  0f         RRC
    f5f1  4f         MOV C, A

    f5f2  e6 c0      ANI A, c0
    f5f4  b5         ORA L
    f5f5  6f         MOV L, A

    f5f6  79         MOV A, C
    f5f7  e6 07      ANI A, 07
    f5f9  f6 e8      ORI A, e8
    f5fb  67         MOV H, A

    f5fc  22 5a f7   SHLD f75a                  ; Store the new cursor position. BUG: shall be f7b2

    f5ff  11 01 f8   LXI DE, f801               ; Set the cursor highlight (in case UT-88 it is a next
    f602  19         DAD DE                     ; after cursor position) BUG: this shall be 0x0001, not
    f603  36 80      MVI M, 80                  ; 0xf801.

PUT_CHAR_CPM_EXIT_NO_CHAR:
    f605  3e 00      MVI A, 00
    f607  32 15 f6   STA ESC_SEQ_CHAR_NO (f615)

    f60a  c3 2b f5   JMP PUT_CHAR_CPM_EXIT (f52b)

ESC_PRINT_LAST_CHAR:
    f60d  3e 00      MVI A, 00                  ; No more characters expected in the sequence
    f60f  32 15 f6   STA ESC_SEQ_CHAR_NO (f615)

DO_MONITOR_PUT_CHAR:
    f612  c3 47 fc   JMP fc47


ESC_SEQ_CHAR_NO:
    f615  00         db 00                      ; number of escape sequence chars accepted

ESC_SEQ_MOVE_Y:
    f616  00         db 00

ESC_SEQ_CHAR_2ND_9:
    f617  c3 05 f6   JMP PUT_CHAR_CPM_EXIT_NO_CHAR (f605)

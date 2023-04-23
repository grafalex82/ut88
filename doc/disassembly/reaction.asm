
; "Reaction" game
;
; This program is one of the example programs for the UT-88 Basic CPU module.
; First the program expects the User to enter a difficulty level (in fact, a
; delay before start). After a pause the program starts counting a number on
; the LCD. User must press Reset button to stop counting. The lower number
; is displayed - the better.
;
; Comments:
; Although this program is supposed to be a software sample, and perhaps have
; some learning effect, to make the User to understand better the programming
; language, and how programs made, in fact this code is ugly and shall not be
; presented as a good software example:
; - Jumps into a middle of instructions is used multiple times. Perhaps this is
;   just a mistake after moving the program code 1 byte up or down, but this
;   definitely must be cought at the "code review" (did this term exist in late
;   80x?)
; - jumps are structured weird, difficulty level handlers are mixed
; - A simple difficulty-to-delay table could work better, rather than a number
;   of specific cases and condition jumps.

START:
    c000  d7         RST 2                      ; Wait for a byte
    c001  fe 00      CPI 00                     ; Check if the User entered 00
    c003  ca 27 c0   JZ MODE_00 (c027)

    c006  fe 01      CPI 01                     ; Check if the User entered 01
    c008  ca 22 c0   JZ MODE_01 (c022)

    c00b  fe 02      CPI 02                     ; Check if the User entered 02
    c00c  ca 21 c0   JZ MODE_02 (c021)          ; Perhaps this supposed to be c02c

    c010  fe 03      CPI 03
    c012  ca 31 c0   JZ MODE_03 (c031)

    c015  fe 04      CPI 04
    c017  ca 36 c0   JZ MODE_04 (c036)

    c01a  fe 05      CPI 05
    c01c  ca 3b c0   JZ MODE_05 (c03b)

    c01f  c3 40 c0   JMP MODE_X (c040)


MODE_02:


MODE_01:
    c022  06 0b      MVI B, 0b                  ; Start delay - 11 seconds
    c024  c3 41 c0   JMP c041    

MODE_00:
    c027  06 0e      MVI B, 0e                  ; Start delay - 15 seconds
    c029  c3 41 c0   JMP c041

???:
    c02c  06 07      MVI B, 07
    c02e  c3 41 c0   JMP c041

MODE_03:
    c031  06 08      MVI B, 08
    c033  c3 41 c0   JMP c041

MODE_04:
    c036  06 10      MVI B, 10
    c038  c3 41 c0   JMP c041

MODE_05:
    c03b  06 0d      MVI B, 0d
    c03d  c3 41 c0   JMP c041

MODE_X:
    c040  06 0f      MVI B, 0f

    c042  3e ff      MVI A, ff                  ; Display 0xf on all LCD digits
    c044  21 ff ff   LXI HL, ffff

WAIT_LOOP:
    c047  ef         RST 5
    c048  df         RST 3
    c049  05         DCR B
    c04a  c2 47 c0   JNZ WAIT_LOOP (c047)

    c04d  3e 00      MVI A, 00                  ; Load and display starting zeroes
    c04f  21 00 00   LXI HL, 0000

PLAY_LOOP:
    c052  ef         RST 5                      ; Display current value

    c053  23         INX HL                     ; Increase the value and repeat
    c054  00         NOP
    c055  00         NOP

    c056  c3 51 c0   JMP PLAY_LOOP (c051)       

; Some garbage bytes
    c059  00 C0 C3 10 C0 FF FF
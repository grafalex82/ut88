; "Gamma" program
;
; Program start address is c03e
;
; Outputs 8 gamma notes to the tape output. At the beginning the User enters
; Notes and pauses durations


    c000  00         NOP
    c001  00         NOP
    c002  00         NOP

; Playing a note
; C - note period
PLAY_NOTE:
    c003  d5         PUSH DE
    c004  1e 01      MVI E, 01                  ; Start with positive pulse

LOOP_1:
    c006  21 c9 0c   LXI HL, 0cc9               ; One time unit (used to calculate note and pauses duration)

LOOP_2:
    c009  7b         MOV A, E                   ; Out pulse
    c00a  d3 a1      OUT a1

    c00c  cd 1d c0   CALL DELAY (c01d)

    c00f  2f         CMA                        ; Negate pulse
    c010  5f         MOV E, A

    c011  00         NOP                        ; Special delay compensation loop (so that notes
    c012  7c         MOV A, H                   ; with different period has the same duration)
    c013  b4         ORA H
    c014  c2 09 c0   JNZ LOOP_2 (c009)

    c017  15         DCR D                      ; Play tone until duration in D
    c018  c2 06 c0   JNZ LOOP_1 (c006)

    c01b  d1         POP DE
    c01c  c9         RET


; Short delay, number of loops in C
DELAY:
    c01d  41         MOV B, C

DELAY_LOOP:
    c01e  2b         DCX HL
    c01f  05         DCR B
    c020  c2 1e c0   JNZ DELAY_LOOP (c01e)
    c023  c9         RET

; Fixed duration delay (not really used)
DELAY2:
    c024  21 ca 0c   LXI HL, 0cca

DELAY2_LOOP:
    c027  2b         DCX HL
    c028  7d         MOV A, L
    c029  b4         ORA H
    c02a  c2 27 c0   JNZ DELAY2_LOOP (c027)
    c02d  c9         RET


; Pause (E=duration)
PAUSE:
    c02e  d5         PUSH DE
PAUSE_LOOP_1:
    c02f  21 ca 0c   LXI HL, 0cca
PAUSE_LOOP_2:
    c032  2b         DCX HL
    c033  7d         MOV A, L
    c034  b4         ORA H
    c035  c2 32 c0   JNZ PAUSE_LOOP_2 (c032)
    c038  1d         DCR E
    c039  c2 2f c0   JNZ PAUSE_LOOP_1 (c02f)
    c03c  d1         POP DE
    c03d  c9         RET

START:
    c03e  f7         RST 6                      ; Enter note duration in D, and pauses in E

GAMMA_LOOP:
    c03f  0e 8b      MVI C, 8b                  ; Note #1 (C - frequency)
    c041  cd 03 c0   CALL PLAY_NOTE (c003)
    c044  cd 2e c0   CALL PAUSE (c02e)

    c047  0e 7a      MVI C, 7a                  ; Note #2 (C - frequency)
    c049  cd 03 c0   CALL PLAY_NOTE (c003)
    c04c  cd 2e c0   CALL PAUSE (c02e)

    c04f  0e 6c      MVI C, 6c                  ; Note #3 (C - frequency)
    c051  cd 03 c0   CALL PLAY_NOTE (c003)
    c054  cd 2e c0   CALL PAUSE (c02e)

    c057  0e 65      MVI C, 65                  ; Note #4 (C - frequency)
    c059  cd 03 c0   CALL PLAY_NOTE (c003)
    c05c  cd 2e c0   CALL PAUSE (c02e)

    c05f  0e 5a      MVI C, 5a                  ; Note #5 (C - frequency)
    c061  cd 03 c0   CALL PLAY_NOTE (c003)
    c064  cd 2e c0   CALL PAUSE (c02e)

    c067  0e 4f      MVI C, 4f                  ; Note #6 (C - frequency)
    c069  03         INX BC                     ; ????
    c06a  cd 03 c0   CALL PLAY_NOTE (c003)
    c06d  cd 2e c0   CALL PAUSE (c02e)

    c070  0e 47      MVI C, 47                  ; Note #7 (C - frequency)
    c072  cd 03 c0   CALL PLAY_NOTE (c003)
    c075  cd 2e c0   CALL PAUSE (c02e)

    c078  0e 44      MVI C, 44                  ; Note #8 (C - frequency)
    c07a  cd 03 c0   CALL PLAY_NOTE (c003)
    c07d  cd 2e c0   CALL PAUSE (c02e)

    c080  c3 3f c0   JMP GAMMA_LOOP (0c3f)

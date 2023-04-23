; "Labyrinth" game
;
; Labyrinth is a 16x16 board that consists of walls (0x01) and empty cells. The Player
; starts at the coordinates 0xff. The goal is to go through the labirinth and reach 0x00 position. 
;
; When program starts the User shall press 0 to select the board with labyrinth (otherwise
; empty field will be selected)
;
; Movement commands:
; 1 - move up
; 2 - move down
; 3 - move left
; 4 - move right
;
; Important addresses
; - 0xc0f5  - last good position
; - 0xc0f6  - new proposed position

    c000  00         NOP
    c001  00         NOP
    c002  00         NOP

START:
    c003  e7         RST 4                      ; Wait for a button press

    c004  c6 00      ADI 00                     ; Depending on the button it loads either
    c006  c2 0e c0   LOW_FIELD (JNZ c00e)       ; 0xc1ff or 0xc2ff board address

    c009  26 c2      MVI H, c2
    c00b  c3 10 c0   JMP PREP_FIELD_ADDR (c010)

LOW_FIELD:
    c00e  26 c1      MVI H, c1

PREP_FIELD_ADDR:
    c010  2e ff      MVI L, ff

    c012  7d         MOV A, L                   ; Initialize the position to 0xff
    c013  32 f5 c0   STA c0f5
    c016  32 f6 c0   STA c0f6

    c019  32 00 90   STA 9000                   ; Display current position
    
    c01c  11 00 00   LXI DE, 0000               ; Zero the movement counter
    c01f  ef         RST 5


NEXT_MOVE:
    c020  e7         RST 4                      ; Wait for a commands

    c021  3d         DCR A                      ; Check for 1 (Up)
    c022  ca 33 c0   JZ CMD_UP (c033)

    c025  fe 01      CPI 01                     ; Check for 2 (Down)
    c027  ca 42 c0   JZ CMD_DOWN (c042)

    c02a  fe 02      CPI 02                     ; Check for 3 (Left)
    c02c  ca 64 c0   JZ CMD_LEFT (c064)

    c02f  c3 52 c0   JMP CMD_RIGHT (c052)       ; Otherwise treat it as Right movement
    
    c032  00         NOP


CMD_UP:
    c033  3a f6 c0   LDA c0f6                   ; Move the position 1 row up
    c036  d6 10      SUI 10
    c038  32 f6 c0   STA c0f6

    c03b  da 8e c0   JC MOVE_ROLLBACK (c08e)    ; Check if we reached the board bounds

    c03e  c3 76 c0   JMP CHECK_WALL (c076)      ; Possibly a valid move - check if the wall is there

    c041  00         NOP

CMD_DOWN:
    c042  3a f6 c0   LDA c0f6                   ; Move the position 1 row down
    c045  c6 10      ADI 10
    c047  32 f6 c0   STA c0f6

    c04a  da 8e c0   JC MOVE_ROLLBACK (c08e)    ; Check if we reached the board bounds
    c04d  00         NOP

    c04e  c3 76 c0   JMP CHECK_WALL (c076)      ; Possibly a valid move - check if the wall is there

    c051  00         NOP

CMD_RIGHT:
    c052  3a f6 c0   LDA c0f6                   ; Move the position 1 column right
    c055  c6 01      ADI 01
    c057  32 f6 c0   STA c0f6
    
    c05a  cd c6 c0   CALL c0c6                  ; ????

    c05d  da 8e c0   JC MOVE_ROLLBACK (c08e)    ; Check if we reached the board bounds

    c060  c3 76 c0   JMP CHECK_WALL (c076)      ; Possibly a valid move - check if the wall is there

    c063  00         NOP

CMD_LEFT:
    c064  3a f6 c0   LDA c0f6                   ; Move the position 1 column left
    c067  d6 01      SUI 01
    c069  32 f6 c0   STA c0f6

    c06c  cd c6 c0   CALL c0c6                  ; ?????
    c06f  da 8e c0   JC MOVE_ROLLBACK (c08e)    ; Check if we reached the board bounds

    c072  c3 76 c0   JMP CHECK_WALL (c076)      ; Possibly a valid move - check if the wall is there

    c075  00         NOP

CHECK_WALL:
    c076  6f         MOV L, A                   ; Load labyrinth data at the new position
    c077  7e         MOV A, M

    c078  c6 00      ADI 00                     ; Check if there is a wall
    c07a  c2 8e c0   JNZ MOVE_ROLLBACK (c08e)

    c07d  00         NOP                        ; Move is ok, store the new position at c0f5
    c07e  3a f6 c0   LDA c0f6
    c081  32 f5 c0   STA c0f5

    c084  32 00 90   STA 9000                   ; Display the new position and beep
    c087  cd d5 c0   CALL BEEP (c0d5)
    c08a  c3 9c c0   JMP CHECK_EXIT (c09c)

    c08d  00         NOP

MOVE_ROLLBACK:
    c08e  3a f5 c0   LDA c0f5                   ; Restore the previous position
    c091  32 f6 c0   STA c0f6
    c094  32 00 90   STA 9000
    c097  f5         PUSH PSW
    c098  c3 a5 c0   JMP PREP_NEXT_MOVE (c0a5)

    c09b  00         NOP

CHECK_EXIT:
    c09c  3a f5 c0   LDA c0f5                   ; Check if we reached the exit from labyrinth
    c09f  c6 00      ADI 00
    c0a1  ca b7 c0   JZ EXIT_REACHED (c0b7)
    c0a4  f5         PUSH PSW


PREP_NEXT_MOVE:
    c0a5  7b         MOV A, E                   ; Increment moves counter (DE)
    c0a6  3c         INR A
    c0a7  27         DAA                        ; Bug: carry flag may be set at the point, INR does not clear this flag
    c0a8  5f         MOV E, A
    c0a9  d2 af c0   JNC c0af

    c0ac  7a         MOV A, D
    c0ad  3c         INR A
    c0ae  57         MOV D, A

    c0af  f1         POP PSW                    ; Display the moves counter
    c0b0  eb         XCHG
    c0b1  ef         RST 5
    c0b2  eb         XCHG
    c0b3  c3 20 c0   JMP NEXT_MOVE (c020)

    c0b6  00         NOP

EXIT_REACHED:
    c0b7  cd d5 c0   CALL BEEP (c0d5)           ; Beep periodically, until a button is pressed
    c0ba  df         RST 3    
    c0bb  00         NOP
    c0bc  db a0      IN a0                      ; Check if button pressed
    c0be  c6 00      ADI 00
    c0c0  ca b7 c0   JZ EXIT_REACHED (c0b7)

    c0c3  c3 03 c0   JMP START (c003)           ; Repeat the game

?????:
    c0c6  c9         RET                        ; Disabled function?

    c0c7  c1         POP BC                     ; Perhaps this piece of code is supposed to fix
    c0c8  79         MOV A, C                   ; rolling out of board bounds horrizontally (move
    c0c9  e6 10      ANI A, 10                  ; left at the left border, and right at the right
    c0cb  ca d1 c0   JZ c0d1                    ; border), but for some reason this code has been
    c0ce  37         STC                        ; disabled
    c0cf  78         MOV A, B
    c0d0  c9         RET

    c0d1  37         STC
    c0d2  3f         CMC
    c0d3  78         MOV A, B
    c0d4  c9         RET

BEEP:
    c0d5  d5         PUSH DE
    c0d6  e5         PUSH HL
    c0d7  1e 01      MVI E, 01                  ; Beep phase
    c0d9  16 50      MVI D, 50                  ; Beep period (frequency)
    c0db  21 ff 00   LXI HL, 00ff               ; Beep duration

BEEP_LOOP:
    c0de  7b         MOV A, E                   ; Output a pulse
    c0df  d3 a1      OUT a1
    c0e1  cd ef c0   CALL DELAY (c0ef)

    c0e4  2f         CMA                        ; Negate phase
    c0e5  5f         MOV E, A

    c0e6  2b         DCX HL                     ; Repeat 'duration' times
    c0e7  7c         MOV A, H
    c0e8  b5         ORA L
    c0e9  c2 de c0   JNZ BEEP_LOOP (c0de)
    
    c0ec  e1         POP HL
    c0ed  d1         POP DE
    c0ee  c9         RET


DELAY:
    c0ef  42         MOV B, D                   ; Short delay D cycles
    c0f0  05         DCR B
    c0f1  c2 f0 c0   JNZ c0f0
    c0f4  c9         RET


DATA:
    c0f5  d2                                    ; Last good position
    c0f6  d2                                    ; Proposed new position


????:
    c0f7  21 c0 c2   LXI HL, c2c0               ; Another unused piece of code
    c0ca  3e ff      MVI A, ff
    c0cc  ef         RST 5
    c0cd  e7         RST 4
    c0ce  ef         RST 5
    c0cf  df         RST 3

; Empty board
C100 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C110 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C120 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C130 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C140 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C150 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C160 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C170 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C180 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C190 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C1A0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C1B0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C1C0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C1D0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C1E0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
C1F0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 

; Labyrinth
C200 00 00 01 01 01 01 01 01 01 01 01 01 01 01 01 01 
C210 00 00 00 00 00 01 00 00 00 01 00 00 00 00 00 01 
C220 01 00 00 00 01 00 00 01 00 00 00 01 00 00 00 01 
C230 01 00 01 00 00 00 00 00 00 00 01 00 00 01 00 01 
C240 01 00 00 00 00 01 00 00 00 00 01 00 00 00 00 01 
C250 01 00 01 00 00 00 00 00 01 00 00 00 01 00 00 01 
C260 01 00 00 00 00 01 00 00 00 00 00 00 00 00 00 01 
C270 01 00 00 00 00 00 00 00 00 00 01 00 00 01 00 01 
C280 01 00 01 00 00 01 00 01 00 01 00 00 01 00 00 01 
C290 01 00 00 00 00 00 00 00 01 00 00 00 00 00 00 01 
C2A0 01 00 00 01 00 00 00 01 00 00 00 01 00 01 00 01 
C2B0 01 01 00 00 00 00 00 01 00 00 00 00 00 00 00 01 
C2C0 01 00 00 00 00 00 00 00 00 01 00 00 00 01 00 01 
C2D0 01 00 01 00 00 01 00 00 00 00 00 01 00 01 00 01 
C2E0 01 00 00 01 00 00 00 01 00 00 00 00 00 00 00 00 
C2F0 01 01 01 01 01 01 01 01 01 01 01 01 01 01 00 00
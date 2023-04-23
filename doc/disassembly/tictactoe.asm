; "Tic Tac Toe" game
; 
; This is a classic Tic Tac Toe game. The cells numbers are:
; 01 02 03
; 08 09 04
; 07 06 05
;
; Computer always goes first, and always plays #9. Program expects the User to enter
; 2-digit cell number. 
;
; End of the game:
; - LCD displays 11 - the draw (computer is in Monitor 0 waiting for a command)
; - LCD displays 72 - computer wins
;
; There are 2 scenarios possible:
;
; 1) As a first turn the player plays corner. In this case computer will play the field
;    which is next counter clock wise. If player always does the opposite turn - player
;    can get the game to a draw. If player does other turns - computer wins.
;
; 2) As a first turn the player plays a side cell. Then the game goes to the following
;    scenario, which ends with a computer win
;  . . .    . O .    X O .    X O .    X O .
;  . X . => . X . => . X . => . X . => X X . => computer wins, regardless of player turn
;  . . .    . . .    . . .    . . O    . . O

    c000  3e 09      MVI A, 09              ; Computer always plays #9
    c002  32 00 90   STA 9000

    c005  d7         RST 2                  ; Wait for the Player's move

    c006  cd 1a c0   CALL c01a
    c009  c3 47 c0   JMP CHECK_CORNER (c047)

    c00c  00         NOP
    c00d  00         NOP
    c00e  00         NOP
    c00f  00         NOP

DO_MORE_TURNS:
    c010  7a         MOV A, D
    c011  cd 1a c0   CALL c01a
    c014  7a         MOV A, D
    c015  cd 1a c0   CALL c01a

    c018  c7         RST 0                  ; Draw. Just exit and reset.

; One round of the game:
; - Function accepts player move in A
; - Computer does its turn (stored in C)
; - Accept next player's turn (stored in D)
; - Check if player moves in a right way
; - If player did a wrong move - display "Computer wins" (73)
; - If player did a good move - return computer's move in A
DO_ROUND:
    c01a  06 01      MVI B, 01              ; Computer's turn will be the cell number one lower
    c01c  90         SUB B                  ; than Player's turn, (or #8 if Player plays cell #1)
    c01d  c2 22 c0   JNZ COMP_TURN

    c020  3e 08      MVI A, 08

COMP_TURN:
    c022  4f         MOV C, A               ; Computer's turn will be stored in C
    c023  32 00 90   STA 9000               ; Display computer's turn

    c026  d7         RST 2                  ; Wait for the next Player's move, store in D
    c027  57         MOV D, A

    c028  1e 04      MVI E, 04              ; The only valid turn for the player is 4 lower than
    c02a  79         MOV A, C               ; than the computer's move, otherwise computer wins
    c02b  93         SUB E                  
    c02c  ca 32 c0   JZ CALC_TURN_1 (c032)
    c02f  f2 35 c0   JP CALC_TURN_2 (c035)

CALC_TURN_1:
    c032  2e 08      MVI L, 08              ; if the calculated turn is <= 0, then wrap it up with 8
    c034  85         ADD L
CALC_TURN_2:
    c035  6f         MOV L, A               ; Store the "right" turn in L

    c036  7a         MOV A, D               ; If the Player's move matches the "right" one, the 
    c037  95         SUB L                  ; Player is allowed for one more turn
    c038  ca 45 c0   JZ GOOD_TURN (c045)
    c03b  00         NOP
    c03c  00         NOP

COMPUTER_WINS:
    c03d  26 73      MVI H, 73              ; Otherwise computer wins (Display 73)
    c03f  7c         MOV A, H
    c040  32 00 90   STA 9000
    c043  ef         RST 5
    c044  76         HLT                    ; Brutaly Halt the program (Bug: nearest time interrupt will wake the processor up)

GOOD_TURN:
    c045  79         MOV A, C
    c046  c9         RET


CHECK_CORNER:
    c047  fe 01      CPI 01                 ; If the computer turn was in the corner - no
    c049  ca 5e c0   JZ CORNER_TURN (c05e)  ; matter how player goes next, computer will win
    c04c  fe 03      CPI 03
    c04e  ca 5e c0   JZ CORNER_TURN (c05e)
    c051  fe 05      CPI 05
    c053  ca 5e c0   JZ CORNER_TURN (c05e)
    c056  fe 07      CPI 07
    c058  ca 5e c0   JZ CORNER_TURN (c05e)
    c05b  c3 10 c0   JMP DO_MORE_TURNS (c010)

CORNER_TURN:
    c05e  79         MOV A, C
    c05f  cd 1a c0   CALL c01a
    c062  90         SUB B
    c063  c3 3d c0   JMP COMPUTER_WINS (c03d)
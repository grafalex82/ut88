; 2048 game
;
; Variables:
; 0235  - Flag indicating that the score has been updated
; 0236  - Game field updated
; 02cf  - Some horizontal offset of the game field
; 03ef-03fe - 16 bytes game field
; 03ff-040e - 16 bytes previous state field
; 0444-0449 - Current score
; 044a      - Current score field separatpr
; 044b-0450 - Number of moves
; 0451      - Number of moves field separator
START:
    0000  21 34 04   LXI HL, PRESS_SPACE_STR (0434) ; Print hello string
    0003  cd 18 03   CALL PRINT_STR (0318)

WAIT_SPACE_LOOP:
    0006  cd 25 03   CALL GET_RANDOM_VALUE (0325)   ; Generate random values until space is pressed

    0009  cd 1b f8   CALL MONITOR_SCAN_KBD (f81b)   ; Delay with pressing the space button will continuously
    000c  fe 20      CPI A, 20                      ; run getting new random values, and therefore this is
    000e  c2 06 00   JNZ WAIT_SPACE_LOOP (0006)     ; way of getting a random seed

    0011  0e 1f      MVI C, 1f                      ; Clear screen
    0013  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0016  cd 8d 02   CALL DRAW_FIELD (028d)         ; Draw the field

    0019  21 0d 24   LXI HL, 240d                   ; Print the score string
    001c  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    001f  21 93 04   LXI HL, SCORE_STR (0493)
    0022  cd 18 03   CALL PRINT_STR (0318)

    0025  21 0f 24   LXI HL, 240f                   ; Print number of moves string
    0028  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    002b  21 99 04   LXI HL, MOVES_STR (0499)
    002e  cd 18 03   CALL PRINT_STR (0318)

    0031  cd 44 03   CALL DRAW_LEGEND (0344)        ; Draw the legend

NEW_GAME:
    0034  3e 02      MVI A, 02                      ; Set the horizontal offset
    0036  32 cf 02   STA HORZ_OFFSET (02cf)

    0039  3d         DCR A                          ; Set the Score Updated and Game Field Updated flags
    003a  32 35 02   STA SCORE_UPDATED (0235)
    003d  32 36 02   STA GAME_FIELD_UPDATED (0236)

    0040  21 ef 03   LXI HL, 03ef                   ; Zero the game field
    0043  06 10      MVI B, 10
    0045  af         XRA A

CLEAR_FIELD_LOOP:
    0046  77         MOV M, A
    0047  23         INX HL
    0048  05         DCR B
    0049  c2 46 00   JNZ CLEAR_FIELD_LOOP (0046)

    004c  21 44 04   LXI HL, SCORE_VAR (0444)       ; Clear score and number of moves (2 fields 6 bytes each)
    004f  11 4b 04   LXI DE, MOVES_VAR (044b)
    0052  06 06      MVI B, 06
    0054  af         XRA A
CLEAR_VARS_LOOP:
    0055  77         MOV M, A
    0056  12         STAX DE
    0057  23         INX HL
    0058  13         INX DE
    0059  05         DCR B
    005a  c2 55 00   JNZ CLEAR_VARS_LOOP (0055)

    005d  cd 63 01   CALL FILL_RANDOM_CELL (0163)   ; Fill the first random cell

NEXT_MOVE:
    0060  3a 35 02   LDA SCORE_UPDATED (0235)   ; Skip updating score number if the score value has not changed
    0063  b7         ORA A
    0064  ca 77 00   JZ NEXT_MOVE_1 (0077)

    0067  af         XRA A                      ; Reset the Score Updated flag
    0068  32 35 02   STA SCORE_UPDATED (0235)

    006b  21 0d 2a   LXI HL, 2a0d               ; Print current score
    006e  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    0071  21 44 04   LXI HL, SCORE_VAR (0444)
    0074  cd 36 01   CALL PRINT_NUMBER (0136)

NEXT_MOVE_1:
    0077  cd 4a 02   CALL PRINT_FIELD (024a)

    007a  3a 36 02   LDA GAME_FIELD_UPDATED (0236)  ; Skip updating Moves counter if no game changes happened
    007d  b7         ORA A
    007e  ca 9d 00   JZ NEXT_MOVE_2 (009d)

    0081  af         XRA A                      ; Reset the Game Field Updated flag
    0082  32 36 02   STA GAME_FIELD_UPDATED (0236)

    0085  cd 63 01   CALL FILL_RANDOM_CELL (0163)   ; Generate new cell value

    0088  21 0f 2a   LXI HL, 2a0f               ; Print number of moves
    008b  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    008e  21 4b 04   LXI HL, MOVES_VAR (044b)
    0091  cd 36 01   CALL PRINT_NUMBER (0136)

    0094  21 50 04   LXI HL, MOVES_VAR_REV (0450)   ; Increment moves counter
    0097  11 8e 04   LXI DE, FIELD_ONE (048e)
    009a  cd 1f 01   CALL ADD_FIELD (011f)

NEXT_MOVE_2:
    009d  cd 4a 02   CALL PRINT_FIELD (024a)    ; Print the moves counter

    00a0  21 00 00   LXI HL, 0000               ; Hide cursor at topleft position
    00a3  cd fe 02   CALL MOVE_CURSOR_TO (02fe)

    00a6  af         XRA A                      ; Reset the Game Field Updated flag
    00a7  32 36 02   STA GAME_FIELD_UPDATED (0236)

GAME_WAIT_KEY_LOOP:
    00aa  cd 25 03   CALL GET_RANDOM_VALUE (0325)   ; Wait for a button press
    00ad  cd 1b f8   CALL MONITOR_SCAN_KBD (f81b)
    00b0  fe ff      CPI A, ff
    00b2  c2 aa 00   JNZ GAME_WAIT_KEY_LOOP (00aa)


GAME_WAIT_VALID_KEY_LOOP:
    00b5  cd 25 03   CALL GET_RANDOM_VALUE (0325)   ; Wait for a valid key
    00b8  cd 1b f8   CALL MONITOR_SCAN_KBD (f81b)
    00bb  fe 08      CPI A, 08
    00bd  ca d7 00   JZ HANDLE_LEFT (00d7)
    00c0  fe 18      CPI A, 18
    00c2  ca dd 00   JZ HANDLE_RIGHT (00dd)
    00c5  fe 19      CPI A, 19
    00c7  ca ef 00   JZ HANDLE_UP (00ef)
    00ca  fe 1a      CPI A, 1a
    00cc  ca 01 01   JZ HANDLE_DOWN (0101)
    00cf  fe 20      CPI A, 20
    00d1  ca 34 00   JZ NEW_GAME (0034)
    00d4  c3 b5 00   JMP GAME_WAIT_VALID_KEY_LOOP (00b5)

HANDLE_LEFT:                                    ; Collapse empty space, shift cells to the left
    00d7  cd b0 01   CALL COLLAPSE_FIELD_LEFT (01b0)
    00da  c3 60 00   JMP NEXT_MOVE (0060)

HANDLE_RIGHT:                                   ; Flip the field horizontally, collapse cells left, flip back
    00dd  21 0f 04   LXI HL, FLIP_HORIZONTAL (040f)
    00e0  cd 90 01   CALL FLIP_FIELD (0190)
    00e3  cd b0 01   CALL COLLAPSE_FIELD_LEFT (01b0)
    00e6  21 0f 04   LXI HL, FLIP_HORIZONTAL (040f)
    00e9  cd 90 01   CALL FLIP_FIELD (0190)
    00ec  c3 60 00   JMP NEXT_MOVE (0060)

HANDLE_UP:                                      ; Flip the field diagonally, collapse cells left, flip back
    00ef  21 20 04   LXI HL, FLIP_DIAGONAL (0420)
    00f2  cd 90 01   CALL FLIP_FIELD (0190)
    00f5  cd b0 01   CALL COLLAPSE_FIELD_LEFT (01b0)
    00f8  21 20 04   LXI HL, FLIP_DIAGONAL (0420)
    00fb  cd 90 01   CALL FLIP_FIELD (0190)
    00fe  c3 60 00   JMP NEXT_MOVE (0060)

HANDLE_DOWN:                    ; Flip the field diagonally and horizontally, collapse cells left, flip back
    0101  21 20 04   LXI HL, FLIP_DIAGONAL (0420)
    0104  cd 90 01   CALL FLIP_FIELD (0190)
    0107  21 0f 04   LXI HL, FLIP_HORIZONTAL (040f)
    010a  cd 90 01   CALL FLIP_FIELD (0190)
    010d  cd b0 01   CALL COLLAPSE_FIELD_LEFT (01b0)
    0110  21 0f 04   LXI HL, FLIP_HORIZONTAL (040f)
    0113  cd 90 01   CALL FLIP_FIELD (0190)
    0116  21 20 04   LXI HL, FLIP_DIAGONAL (0420)
    0119  cd 90 01   CALL FLIP_FIELD (0190)
    011c  c3 60 00   JMP NEXT_MOVE (0060)

; Add two 5-byte fields pointed by HL and DE. Result is stored at HL.
; Addition happens in BCD way (each digit is no more than '9')
ADD_FIELD:
    011f  0e 05      MVI C, 05                  ; Add 5 bytes

ADD_FIELD_LOOP:
    0121  46         MOV B, M                   ; Add one byte
    0122  1a         LDAX DE
    0123  80         ADD B
    0124  fe 0a      CPI A, 0a                  ; Check for overflow
    0126  da 2e 01   JC ADD_FIELD_NEXT (012e)

    0129  d6 0a      SUI A, 0a                  ; Carry
    012b  2b         DCX HL
    012c  34         INR M
    012d  23         INX HL

ADD_FIELD_NEXT:
    012e  77         MOV M, A                   ; Store calculated byte

    012f  2b         DCX HL                     ; Advance to the next byte
    0130  13         INX DE

    0131  0d         DCR C                      ; Repeat until all bytes are added
    0132  c2 21 01   JNZ ADD_FIELD_LOOP (0121)

    0135  c9         RET


; Prints a number pointed by HL at current screen coordinates
PRINT_NUMBER:
    0136  2b         DCX HL

PRINT_NUMBER_LOOP:
    0137  23         INX HL
    0138  7e         MOV A, M
    0139  fe f0      CPI A, f0
    013b  ca 52 01   JZ PRINT_NUMBER_ZERO (0152)
    013e  fe 00      CPI A, 00
    0140  ca 37 01   JZ PRINT_NUMBER_LOOP (0137)

PRINT_NUMBER_LOOP_2:
    0143  7e         MOV A, M                   ; Print field value (one char)
    0144  c6 30      ADI A, 30
    0146  4f         MOV C, A
    0147  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    014a  23         INX HL                     ; Move to the next char

    014b  7e         MOV A, M                   ; ... until separator is reached
    014c  fe f0      CPI A, f0
    014e  c2 43 01   JNZ PRINT_NUMBER_LOOP_2 (0143)

    0151  c9         RET

PRINT_NUMBER_ZERO:
    0152  0e 30      MVI C, 30                  ; Print zero
    0154  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0157  26 06      MVI H, 06                  ; Fill rest of the field with spaces
    0159  0e 20      MVI C, 20
PRINT_NUMBER_ZERO_LOOP:
    015b  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    015e  25         DCR H
    015f  c2 5b 01   JNZ PRINT_NUMBER_ZERO_LOOP (015b)

    0162  c9         RET


; Generate a new value in a random cell
; 
; The function will find a random empty cell and puts there "2" (internal value 1), but
; with 1/8 probability the new value will be "4" (internal value 2)
FILL_RANDOM_CELL:
    0163  cd 25 03   CALL GET_RANDOM_VALUE (0325)   ; Get random value to select "2" or "4"
    0166  0e 01      MVI C, 01
    0168  e6 07      ANI A, 07
    016a  fe 00      CPI A, 00
    016c  c2 70 01   JNZ FILL_RANDOM_CELL_1 (0170)  ; In most cases this will be "2"

    016f  0c         INR C                      ; But with 1/8 probability it will be "4"
FILL_RANDOM_CELL_1:
    0170  16 00      MVI D, 00                  ; Get random value to DE (0-15 range)
    0172  cd 25 03   CALL GET_RANDOM_VALUE (0325)
    0175  e6 0f      ANI A, 0f
    0177  5f         MOV E, A

    0178  21 ef 03   LXI HL, GAME_FIELD (03ef)  ; Get random cell address
    017b  19         DAD DE

    017c  7e         MOV A, M                   ; Search for an empty cell
    017d  fe 00      CPI A, 00
    017f  c2 70 01   JNZ 0170

    0182  71         MOV M, C                   ; Store the new value in the cell
    0183  c9         RET


GAME_OVER_STR:                                  ; Surprisingly this message is never referenced
    0184  74 79 20 70 72 6f 69 67   db  "ТЫ ПРОИГ"
    018c  72 61 6c 00               db  "РАЛ", 0x00

; Flip a field horizontally or diagonally
;
; Arguments:
; HL pointing to either FLIP_HORIZONTAL or FLIP_DIAGONAL
FLIP_FIELD:
    0190  16 00      MVI D, 00
    0192  01 ef 03   LXI BC, GAME_FIELD_ (03ef)

FLIP_FIELD_LOOP:
    0195  e5         PUSH HL                    ; Load the offset of item to swap with
    0196  7e         MOV A, M
    0197  fe ff      CPI A, ff
    0199  ca a6 01   JZ FLIP_FIELD_NEXT (01a6)

    019c  21 ef 03   LXI HL, GAME_FIELD (03ef)  ; Calculate of the item address
    019f  5f         MOV E, A
    01a0  19         DAD DE

    01a1  5e         MOV E, M                   ; Swap [HL] and [BC]
    01a2  0a         LDAX BC
    01a3  77         MOV M, A
    01a4  7b         MOV A, E
    01a5  02         STAX BC

FLIP_FIELD_NEXT:
    01a6  03         INX BC                     ; Advance pointers
    01a7  e1         POP HL
    01a8  23         INX HL

    01a9  7e         MOV A, M                   ; Repeat until separator found
    01aa  fe c8      CPI A, c8
    01ac  c2 95 01   JNZ FLIP_FIELD_LOOP (0195)

    01af  c9         RET

; Collapse all spaces and matching numbers to the left
COLLAPSE_FIELD_LEFT:
    01b0  21 ef 03   LXI HL, GAME_FIELD_L1 (03ef)
    01b3  cd c9 01   CALL COLLAPSE_LINE_LEFT (01c9)
    01b6  21 f3 03   LXI HL, GAME_FIELD_L2 (03f3)
    01b9  cd c9 01   CALL COLLAPSE_LINE_LEFT (01c9)
    01bc  21 f7 03   LXI HL, GAME_FIELD_L3 (03f7)
    01bf  cd c9 01   CALL COLLAPSE_LINE_LEFT (01c9)
    01c2  21 fb 03   LXI HL, GAME_FIELD_L4 (03fb)
    01c5  cd c9 01   CALL COLLAPSE_LINE_LEFT (01c9)
    01c8  c9         RET

; Collapse spaces and matching numbers to the left for a single line pointed in HL
COLLAPSE_LINE_LEFT:
    01c9  af         XRA A                      ; Zero A

    01ca  46         MOV B, M                   ; Load the line ti B-C-D-E registers
    01cb  23         INX HL
    01cc  4e         MOV C, M
    01cd  23         INX HL
    01ce  56         MOV D, M
    01cf  23         INX HL
    01d0  5e         MOV E, M

    01d1  cd 37 02   CALL MERGE_EMPTY_CELLS (0237)  ; Collapse the line, removing spaces at the left
    01d4  cd 37 02   CALL MERGE_EMPTY_CELLS (0237)
    01d7  cd 37 02   CALL MERGE_EMPTY_CELLS (0237)

    01da  78         MOV A, B                   ; Skip execution if the first cell is empty
    01db  fe 00      CPI A, 00
    01dd  ca ea 01   JZ COLLAPSE_LINE_1 (01ea)

    01e0  b9         CMP C                      ; Compare 1st and 2nd cell
    01e1  c2 ea 01   JNZ COLLAPSE_LINE_1 (01ea)

    01e4  04         INR B                      ; If equal - bump the value of the first cell, and zero the
    01e5  0e 00      MVI C, 00                  ; second one

    01e7  cd 16 02   CALL BUMP_SCORE (0216)     ; Update the score

COLLAPSE_LINE_1:
    01ea  79         MOV A, C                   ; Skip execution if the second cell is empty
    01eb  fe 00      CPI A, 00
    01ed  ca fa 01   JZ COLLAPSE_LINE_2 (01fa)

    01f0  ba         CMP D                      ; Compare 2nd and 3rd cell
    01f1  c2 fa 01   JNZ COLLAPSE_LINE_2 (01fa)

    01f4  0c         INR C                      ; If equal - bump the value of the 2nd cell, and zero the
    01f5  16 00      MVI D, 00                  ; 3rd one

    01f7  cd 16 02   CALL BUMP_SCORE (0216)     ; Update the score

COLLAPSE_LINE_2:
    01fa  7a         MOV A, D                   ; Skip execution if the third cell is empty
    01fb  fe 00      CPI A, 00
    01fd  ca 0a 02   JZ COLLAPSE_LINE_3 (020a)

    0200  bb         CMP E                      ; Compare 3rd and 4th cells
    0201  c2 0a 02   JNZ COLLAPSE_LINE_3 (020a)

    0204  14         INR D                      ; If equal - bump the value of the 3rd cell, and zero 4th
    0205  1e 00      MVI E, 00

    0207  cd 16 02   CALL BUMP_SCORE (0216)     ; Update the score

COLLAPSE_LINE_3:
    020a  af         XRA A                      ; Merge empty cells
    020b  cd 37 02   CALL MERGE_EMPTY_CELLS (0237)

    020e  73         MOV M, E                   ; Store values back
    020f  2b         DCX HL
    0210  72         MOV M, D
    0211  2b         DCX HL
    0212  71         MOV M, C
    0213  2b         DCX HL
    0214  70         MOV M, B

    0215  c9         RET


; Update score by adding collapsed cell value
BUMP_SCORE:
    0216  e5         PUSH HL
    0217  d5         PUSH DE
    0218  c5         PUSH BC

    0219  3d         DCR A                      ; A = 5*(A-1)
    021a  47         MOV B, A
    021b  87         ADD A
    021c  87         ADD A
    021d  80         ADD B

    021e  5f         MOV E, A                   ; DE = A
    021f  16 00      MVI D, 00

    0221  21 52 04   LXI HL, SCORE_ADD (0452)   ; Add the value to the score
    0224  19         DAD DE
    0225  eb         XCHG
    0226  21 49 04   LXI HL, SCORE_VAR_REV (0449)
    0229  cd 1f 01   CALL ADD_FIELD (011f)

    022c  c1         POP BC
    022d  d1         POP DE
    022e  e1         POP HL

    022f  3e 01      MVI A, 01                  ; Raise the Score Updated flag
    0231  32 35 02   STA SCORE_UPDATED (0235)

    0234  c9         RET



SCORE_UPDATED:
    0235  00         db 0x00                    ; Flag indicating that the score has been updated

GAME_FIELD_UPDATED:
    0236  00         db 0x00                    ; Flag indicating a valid move has happened


; Merge empty cells in a line in B-C-D-E registers. A is 0 representing empty cell value
MERGE_EMPTY_CELLS:
    0237  b8         CMP B                      ; Collapse first cell if it is empty (move other cells closer)
    0238  c2 3d 02   JNZ MERGE_EMPTY_CELLS_1 (023d)
    023b  41         MOV B, C
    023c  4f         MOV C, A
MERGE_EMPTY_CELLS_1:
    023d  b9         CMP C                      ; Collapse second cell if it is empty (move other cells closer)
    023e  c2 43 02   JNZ MERGE_EMPTY_CELLS_2 (0243)
    0241  4a         MOV C, D
    0242  57         MOV D, A
MERGE_EMPTY_CELLS_2:
    0243  ba         CMP D                      ; Collapse third cell if it is empty (move other cells closer)
    0244  c2 49 02   JNZ MERGE_EMPTY_CELLS_3 (0249)
    0247  53         MOV D, E
    0248  5f         MOV E, A
MERGE_EMPTY_CELLS_3:
    0249  c9         RET


; Print game field
;
; The function is optimized, and prints only changes fields. For this purposes it uses
; previous field state at 0x03ff
PRINT_FIELD:
    024a  01 ff 03   LXI BC, PREV_STATE_FIELD (03ff)    ; Load the previous state field address
    024d  21 ef 03   LXI HL, GAME_FIELD (03ef)  ; Load the game field address

    0250  1e 00      MVI E, 00                  ; Reset the vert logical coordinate

PRINT_FIELD_Y_LOOP:
    0252  16 00      MVI D, 00                  ; Reset the horz logical coordinate

PRINT_FIELD_X_LOOP:
    0254  d5         PUSH DE
    0255  e5         PUSH HL
    0256  c5         PUSH BC

    0257  7e         MOV A, M                   ; Load cell value to D
    0258  62         MOV H, D                   ; Put logic address to HL
    0259  6b         MOV L, E
    025a  57         MOV D, A

    025b  0a         LDAX BC                    ; Check if we need to update the cell (save CPU cycles
    025c  ba         CMP D                      ; not printing cells that have not changed)
    025d  ca 69 02   JZ PRINT_FIELD_NEXT_CELL (0269)

    0260  7a         MOV A, D                   ; If yes - print new cell value
    0261  cd d0 02   CALL PRINT_CELL (02d0)

    0264  3e 01      MVI A, 01                  ; Set the Game Field Updated flag
    0266  32 36 02   STA GAME_FIELD_UPDATED (0236)

PRINT_FIELD_NEXT_CELL:
    0269  c1         POP BC
    026a  e1         POP HL

    026b  03         INX BC                     ; Advance to the next cell
    026c  23         INX HL
    026d  d1         POP DE

    026e  14         INR D                      ; Bump the horz logical coordinate
    026f  7a         MOV A, D
    0270  fe 04      CPI A, 04
    0272  c2 54 02   JNZ PRINT_FIELD_X_LOOP (0254)

    0275  1c         INR E                      ; Bump the vert logical coordinate
    0276  7b         MOV A, E
    0277  fe 04      CPI A, 04
    0279  c2 52 02   JNZ PRINT_FIELD_Y_LOOP (0252)


    027c  21 ef 03   LXI HL, GAME_FIELD (03ef)  ; Copy game field to previous state field area
    027f  11 ff 03   LXI DE, PREV_STATE_FIELD (03ff)
    0282  06 10      MVI B, 10
PRINT_FIELD_COPY_LOOP:
    0284  7e         MOV A, M                   ; Copy the byte
    0285  12         STAX DE

    0286  23         INX HL                     ; Advance to the next byte
    0287  13         INX DE
    0288  05         DCR B
    0289  c2 84 02   JNZ PRINT_FIELD_COPY_LOOP (0284)

    028c  c9         RET


; Draw the field
;
; Draws the 4x4 field
DRAW_FIELD:
    028d  1e 04      MVI E, 04                  ; The field is 4 cells high

DRAW_FIELD_CELL_LOOP:
    028f  d5         PUSH DE
    0290  3a cf 02   LDA HORZ_OFFSET (02cf)     ; Print the top horizontal line
    0293  6f         MOV L, A
    0294  26 05      MVI H, 05
    0296  cd fe 02   CALL MOVE_CURSOR_TO (02fe) 
    0299  21 b3 03   LXI HL, HORZ_LINE_STR (03b3)
    029c  cd 18 03   CALL PRINT_STR (0318)

    029f  21 cf 02   LXI HL, HORZ_OFFSET (02cf)
    02a2  34         INR M

    02a3  1e 04      MVI E, 04                  ; Draw cell 4 lines high

DRAW_FIELD_CELL_LINE_LOOP:
    02a5  21 cf 02   LXI HL, HORZ_OFFSET (02cf) ; Draw the cell line
    02a8  46         MOV B, M
    02a9  34         INR M
    02aa  68         MOV L, B
    02ab  26 05      MVI H, 05
    02ad  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    02b0  21 d1 03   LXI HL, CELL_STR (03d1)
    02b3  cd 18 03   CALL PRINT_STR (0318)

    02b6  1d         DCR E                      ; Repeat for 4 lines
    02b7  c2 a5 02   JNZ DRAW_FIELD_CELL_LINE_LOOP (02a5)

    02ba  d1         POP DE                     ; Repear for 4 cells vertically
    02bb  1d         DCR E
    02bc  c2 8f 02   JNZ DRAW_FIELD_CELL_LOOP (028f)

    02bf  3a cf 02   LDA HORZ_OFFSET (02cf)     ; Draw the bottom horizontal line
    02c2  6f         MOV L, A
    02c3  26 05      MVI H, 05
    02c5  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    02c8  21 b3 03   LXI HL, HORZ_LINE_STR (03b3)
    02cb  cd 18 03   CALL PRINT_STR (0318)

    02ce  c9         RET


HORZ_OFFSET:
    02cf  02         db 0x02

; Print the cell value

; Arguments:
; HL - logical coordinate of the cell (X, Y)
PRINT_CELL:
    02d0  87         ADD A                      ; A = 4*A           - Each number of 4 char wide
    02d1  87         ADD A
    02d2  f5         PUSH PSW

    02d3  7c         MOV A, H                   ; H = 7*H+7         - each cell is 7 chars wide
    02d4  87         ADD A
    02d5  87         ADD A
    02d6  84         ADD H
    02d7  84         ADD H
    02d8  84         ADD H
    02d9  c6 07      ADI A, 07
    02db  67         MOV H, A

    02dc  7d         MOV A, L                   ; L = 5*L+5         - each cell is 5 lines high
    02dd  87         ADD A
    02de  87         ADD A
    02df  85         ADD L
    02e0  c6 05      ADI A, 05
    02e2  6f         MOV L, A

    02e3  cd fe 02   CALL MOVE_CURSOR_TO (02fe) ; Position the cursor at the cell

    02e6  f1         POP PSW                    ; Calculate the number text address
    02e7  5f         MOV E, A
    02e8  16 00      MVI D, 00
    02ea  21 7b 03   LXI HL, NUMBERS_ARRAY (037b)
    02ed  19         DAD DE

    02ee  3e 04      MVI A, 04                  ; Draw 4 chars
PRINT_CELL_LOOP:
    02f0  4e         MOV C, M                   ; Print the char
    02f1  e5         PUSH HL
    02f2  f5         PUSH PSW
    02f3  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    02f6  f1         POP PSW                    ; Advance to the next char
    02f7  e1         POP HL
    02f8  23         INX HL
    02f9  3d         DCR A
    02fa  c2 f0 02   JNZ PRINT_CELL_LOOP (02f0)
    
    02fd  c9         RET

; Generate Move Cursor To sequence (Esc, 'Y', Y, X)
;
; Arguments:
; H - X screen coordinate (1-based)
; L - Y screen coordinate
MOVE_CURSOR_TO:
    02fe  25         DCR H                      

    02ff  0e 1b      MVI C, 1b                  ; Print 0x1b (Escape) symbol
    0301  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0304  0e 59      MVI C, 59                  ; Print 'Y'
    0306  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0309  3e 20      MVI A, 20                  ; Print Y coordinate
    030b  85         ADD L
    030c  4f         MOV C, A
    030d  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0310  3e 20      MVI A, 20                  ; Print X coordinate
    0312  84         ADD H
    0313  4f         MOV C, A
    0314  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0317  c9         RET


; Print a NULL terminated string pointed by HL
PRINT_STR:
    0318  7e         MOV A, M                   ; Load next symbol
    0319  4f         MOV C, A

    031a  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)   ; print it
    031d  23         INX HL

    031e  7e         MOV A, M                   ; Repeat until 0 is reached
    031f  fe 00      CPI A, 00
    0321  c2 18 03   JNZ PRINT_STR (0318)

    0324  c9         RET

; Get pseudo random value
;
; Returns the value in A
;
; Variables:
; - 0x0431  - internal 2-byte counter
; - 0x0443  - previous generated value
GET_RANDOM_VALUE:
    0325  2a 31 04   LHLD RANDOM_VALUE_POINTER (0431)
    0328  46         MOV B, M
    0329  3a 33 04   LDA RANDOM_VALUE (0433)
    032c  a8         XRA B
    032d  ee c5      XRI A, c5
    032f  07         RLC
    0330  5f         MOV E, A
    0331  23         INX HL
    0332  7c         MOV A, H
    0333  a5         ANA L
    0334  fe ff      CPI A, ff
    0336  c2 3c 03   JNZ GET_RANDOM_VALUE_1 (033c)
    0339  21 00 f8   LXI HL, f800
GET_RANDOM_VALUE_1:
    033c  22 31 04   SHLD RANDOM_VALUE_POINTER (0431)
    033f  7b         MOV A, E
    0340  32 33 04   STA RANDOM_VALUE (0433)
    0343  c9         RET


; Draw the legend (right) part of the screen
DRAW_LEGEND:
    0344  21 16 24   LXI HL, 2416               ; Draw credits string
    0347  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    034a  21 9f 04   LXI HL, CREDITS_STR (049f)
    034d  cd 18 03   CALL PRINT_STR (0318)

    0350  21 11 24   LXI HL, 2411               ; Draw new game string
    0353  cd fe 02   CALL MOVE_CURSOR_TO (02fe)
    0356  21 b1 04   LXI HL, NEW_GAME_STR (04b1)
    0359  cd 18 03   CALL PRINT_STR (0318)

    035c  01 c5 04   LXI BC, GAME_2048_STR_1 (04c5) ; Draw 2048 game name banner
    035f  21 02 23   LXI HL, 2302               ; Starting coordinate
    0362  16 07      MVI D, 07                  ; 7 lines to print

DRAW_LEGEND_LOOP:
    0364  e5         PUSH HL                    ; Move the cursor to the next line
    0365  d5         PUSH DE
    0366  c5         PUSH BC
    0367  cd fe 02   CALL MOVE_CURSOR_TO (02fe)

    036a  c1         POP BC                     ; Print the string
    036b  60         MOV H, B
    036c  69         MOV L, C
    036d  cd 18 03   CALL PRINT_STR (0318)

    0370  23         INX HL                     ; Advance to the next string
    0371  44         MOV B, H
    0372  4d         MOV C, L
    0373  d1         POP DE
    0374  e1         POP HL

    0375  2c         INR L                      ; Continue until all lines are printed
    0376  15         DCR D
    0377  c2 64 03   JNZ DRAW_LEGEND_LOOP (0364)

    037a  c9         RET



NUMBERS_ARRAY:
    037b  20 20 20 20   db "    "
    037f  20 32 20 20   db " 2  "
    0383  20 34 20 20   db " 4  "
    0387  20 38 20 20   db " 8  "
    038b  31 36 20 20   db "16  "
    038f  33 32 20 20   db "32  "
    0393  36 34 20 20   db "64  "
    0397  31 32 38 20   db "128 "
    039b  32 35 36 20   db "256 "
    039f  35 31 32 20   db "512 "
    03a3  31 30 32 34   db "1024"
    03a7  32 30 34 38   db "2048"
    03ab  34 30 39 36   db "4096"
    03af  38 31 39 32   db "8192"

HORZ_LINE_STR:
    03b3  2b 2d 2d 2d 2d 2d 2d 2b   db "+------+"
    03bb  2d 2d 2d 2d 2d 2d 2b 2d   db "------+-"
    03c3  2d 2d 2d 2d 2d 2b 2d 2d   db "-----+--"
    03cb  2d 2d 2d 2d 2b 00         db "----+", 0x00

CELL_STR:
    03d1  21 20 20 20 20 20 20 21   db "!      !"
    03d9  20 20 20 20 20 20 21 20   db "      ! "
    03e1  20 20 20 20 20 21 20 20   db "     !  "
    03e9  20 20 20 20 21 00         db "    !", 0x00
    
GAME_FIELD:
GAME_FIELD_L1:
    03ef  00 00 00 00   db 0x00, 0x00, 0x00, 0x00
GAME_FIELD_L2:
    03f3  00 00 00 00   db 0x00, 0x00, 0x00, 0x00
GAME_FIELD_L3:
    03f7  00 00 00 00   db 0x00, 0x00, 0x00, 0x00
GAME_FIELD_L4:
    03fb  00 00 00 00   db 0x00, 0x00, 0x00, 0x00


PREV_STATE_FIELD:
    03ff  00 00 00 00   db 0x00, 0x00, 0x00, 0x00
    0403  00 00 00 00   db 0x00, 0x00, 0x00, 0x00
    0407  00 00 00 00   db 0x00, 0x00, 0x00, 0x00
    040b  00 00 00 00   db 0x00, 0x00, 0x00, 0x00


FLIP_HORIZONTAL:
    040f  03 02 ff ff   db 0x03, 0x02, 0xff, 0xff   ; Swap 00<->03, 01<->02
    0413  07 06 ff ff   db 0x07, 0x06, 0xff, 0xff   ; Swap 04<->07, 05<->06
    0417  0b 0a ff ff   db 0x0b, 0x0a, 0xff, 0xff   ; Swap 08<->0b, 09<->0a
    041b  0f 0e ff ff   db 0x0f, 0x0e, 0xff, 0xff   ; Swap 0c<->0f, 0d<->0e
    041f  c8                                        ; Separator

FLIP_DIAGONAL:
    0420  00 04 08 0c   db 0x00, 0x04, 0x08, 0x0c   ; Swap 02<->04, 03<->08
    0424  ff 05 09 0d   db 0xff, 0x05, 0x09, 0x0d   ; Swap 04<->0c, 06<->09
    0428  ff ff 0a 0e   db 0xff, 0xff, 0x0a, 0x0e   ; Swap 07<->0d, 0b<->0e
    042c  ff ff ff 0f   db 0xff, 0xff, 0xff, 0x0f   ; 
    0430  c8                                        ; Separator

RANDOM_VALUE_POINTER:
    0431  00 00         db 0x00, 0x00               ; Random address used for random value generation

RANDOM_VALUE:
    0433  00            db 0x00

PRESS_SPACE_STR:
    0434  6e 61 76 6d 69 74 65 20   db "НАЖМИТЕ "
    043c  70 72 6f 62 65 6c 00      db "ПРОБЕЛ", 0x00




    0443  f0                        db 0xf0     ; Separator

SCORE_VAR:
    0444  00 00 00 00 00            db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
SCORE_VAR_REV:
    0449  00

    044a  f0                        db 0xf0     ; Separator

MOVES_VAR:
    044b  00 00 00 00 00            db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
MOVES_VAR_REV:
    0450  00  

    0451  f0                        db 0xf0     ; Separator

SCORE_ADD:
    0452  04 00 00 00 00            db 0x04, 0x00, 0x00, 0x00, 0x00     ; 4
    0457  08 00 00 00 00            db 0x08, 0x00, 0x00, 0x00, 0x00     ; 8
    045c  06 01 00 00 00            db 0x06, 0x01, 0x00, 0x00, 0x00     ; 16
    0461  02 03 00 00 00            db 0x02, 0x03, 0x00, 0x00, 0x00     ; 32
    0466  06 04 00 00 00            db 0x04, 0x06, 0x00, 0x00, 0x00     ; 64
    046b  08 02 01 00 00            db 0x08, 0x02, 0x01, 0x00, 0x00     ; 128
    0470  06 05 02 00 00            db 0x06, 0x05, 0x02, 0x00, 0x00     ; 256
    0475  04 02 00 01 00            db 0x02, 0x01, 0x05, 0x00, 0x00     ; 512
    047a  08 04 00 02 00            db 0x04, 0x02, 0x00, 0x01, 0x00     ; 1024
    047f  06 09 00 04 00            db 0x08, 0x04, 0x00, 0x02, 0x00     ; 2048
    0484  02 09 01 08 00            db 0x06, 0x09, 0x00, 0x04, 0x00     ; 4096
    0489  04 08 03 06 01            db 0x04, 0x08, 0x03, 0x06, 0x01     ; 16384

FIELD_ONE:
    048e  01 00 00 00 00            db 0x01, 0x00, 0x00, 0x00, 0x00

SCORE_STR:
    0493  73 7e 65 74 3a 00         db "СЧЕТ:", 0x00         
    
MOVES_STR:
    0499  68 6f 64 79 3a 00         db "ХОДЫ:", 0x00

CREDITS_STR:
    049f  4b 41 4b 4f 53 5f 4e 4f   db "KAKOS_NO"
    04a7  4e 4f 53 2c 20 32 30 31   db "NOS, 201"
    04af  34 00                     db "4", 0x00

NEW_GAME_STR:
    04b1  70 72 6f 62 65 6c 20 2d   db "ПРОБЕЛ -"
    04b9  20 6e 6f 77 61 71 20 69   db " НОВАЯ И"
    04c1  67 72 61 00               db "ГРА", 0x00

GAME_2048_STR_1:
    04c5  20 20 32 32 32 20 20 20   db "  222    000      4    888 ", 0x00
    04cd  20 30 30 30 20 20 20 20
    04d5  20 20 34 20 20 20 20 38
    04dd  38 38 20 00
    
GAME_2048_STR_2:
    04e1  20 32 20 20 20 32 20 20   db " 2   2  0   0    44   8   8", 0x00
    04e9  30 20 20 20 30 20 20 20
    04f1  20 34 34 20 20 20 38 20 
    04f9  20 20 38 00

GAME_2048_STR_3:
    04fd  20 20 20 20 20 32 20 20   db "     2  0  00   4 4   8   8", 0x00
    0505  30 20 20 30 30 20 20 20
    050d  34 20 34 20 20 20 38 20
    0515  20 20 38 00 
    
GAME_2048_STR_3:
    0519  20 20 20 32 32 20 20 20   db "   22   0 0 0  4  4    888", 0x00
    0521  30 20 30 20 30 20 20 34
    0529  20 20 34 20 20 20 20 38 
    0531  38 38 00 
    
GAME_2048_STR_4:
    0534  20 20 32 20 20 20 20 20   db "  2     00  0  44444  8   8", 0x00
    053c  30 30 20 20 30 20 20 34
    0544  34 34 34 34 20 20 38 20 
    054c  20 20 38 00 
    
GAME_2048_STR_5:
    0550  20 32 20 20 20 20 20 20   db " 2      0   0     4   8   8", 0x00
    0558  30 20 20 20 30 20 20 20
    0560  20 20 34 20 20 20 38 20
    0568  20 20 38 00

GAME_2048_STR_6:
    056c  20 32 32 32 32 32 20 20   db " 22222   000      4    888", 0x00
    0574  20 30 30 30 20 20 20 20
    057c  20 20 34 20 20 20 20 38
    0584  38 38 00

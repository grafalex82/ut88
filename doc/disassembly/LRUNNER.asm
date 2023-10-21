

START:
    0000  c3 a9 09   JMP REAL_START (09a9)

LEFT_BORDER_STR:
    0003  20 11 08 08 1a 00     db ' ', 0x11, 0x08, 0x08, 0x1a, 0x00    ; Draw vertical block, then get cursor
                                                                        ; back, then move cursor down

RIGHT_BORDER_STR:
    0009  06 20 08 08 1a 00     db 0x06, ' ', 0x08, 0x08, 0x1a, 0x00    ; Draw vertical block, then get cursor
                                                                        ; back, then move cursor down

MOVE_CURSOR_STR:
    000f  1b 59 34 22 00        db 0x1b, 0x59, 0x34, 0x22, 0x00 ; Move cursor to the position specified in 3rd and 4th char

UP_STR:
    0014  08 19 00              db 0x08, 0x19, 0x00     ; Left to return to the current symbol, then up

DOWN_STR:
    0017  1a 08 00              db 0x1a, 0x08, 0x00     ; Left to return to the current symbol, then down

LEFT_STR:
    001a  08 08                 db 0x08, 0x08           ; Left to return to the current symbol, then left again

RIGHT_STR:
    001c  00                    db 0x00                 ; Do not move, we are already right from the current pos

SCORE_STR:
    001d  1b 59 37 23               db 0x1b, 0x59, 0x37, 0x23   ; Move cursor to (3, 23)
    0021  73 7e 65 74 3a 20 30 30   db "СЧЕТ: 00"
    0029  30 30 30 30 30 30         db "000000"
    002f  1b 59 37 3a               db 0x1b, 0x59, 0x37, 0x3a   ; Move cursor to (26, 23)
    0033  6c 60 64 65 6a 3a         db "ЛЮДЕЙ:"
    0039  1b 59 37 4b               db 0x1b, 0x59, 0x37, 0x4b   ; Move cursor to (43, 23)
    003d  75 72 6f 77 65 6e 78 3a   db "УРОВЕНЬ:"
    0045  00                        db 0x00

????:
0046  1b   LDA 1b00
0047  59         MOV E, C
0048  37         STC
0049  29         DAD HL
004a  00         NOP

MOVE_TO_LIVES_STR:
    004b  1b 59 37 41 00

MOVE_TO_LEVEL_STR:
    0050  1b 59 37 54 00


; Draw game border
; The function draws top, right, left, and bottom border of the game screen, as well
; as score string
DRAW_BORDER:
    0055  0e 1f      MVI C, 1f                  ; Clear screen
    0057  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    005a  06 3e      MVI B, 3e                  ; Draw upper block 62 times
    005c  0e 03      MVI C, 03

DRAW_BORDER_1:
    005e  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0061  05         DCR B
    0062  c2 5e 00   JNZ DRAW_BORDER_1 (005e)

    0065  06 16      MVI B, 16                  ; Draw 22 vertical blocks (right border)
DRAW_BORDER_2:
    0067  21 09 00   LXI HL, RIGHT_BORDER_STR (0009)
    006a  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
    006d  05         DCR B
    006e  c2 67 00   JNZ DRAW_BORDER_2 (0067)

    0071  0e 0c      MVI C, 0c                  ; Move cursor home
    0073  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0076  06 15      MVI B, 15                  ; Draw 21 vertical blocks (left border)
DRAW_BORDER_3:
    0078  21 03 00   LXI HL, LEFT_BORDER_STR (0003)
    007b  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
    007e  05         DCR B
    007f  c2 78 00   JNZ DRAW_BORDER_3 (0078)

    0082  0e 20      MVI C, 20                  ; Print space
    0084  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0087  0e 11      MVI C, 11                  ; Print remaining 22th vertical block
    0089  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    008c  06 3c      MVI B, 3c                  ; Print 60 times bottom border
    008e  0e 14      MVI C, 14
DRAW_BORDER_4:
    0090  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0093  05         DCR B
    0094  c2 90 00   JNZ DRAW_BORDER_4 (0090)

    0097  21 1d 00   LXI HL, SCORE_STR (001d)   ; Print the score string
    009a  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
    009d  c9         RET


; Draw the block at current cursor position
;
; Arguments:
; A - block type
;
; Block types and their visual symbol:
; - 0x00    - ' '
; - 0x01    - '#'   (ladder)
; - 0x02    - SP    (treasure)
; - 0x03    - solid block
; - 0x04    - 'П'   (hole floor)
; - 0x05    - 'П'   (solid floor)
; - 0x06    - 'Ж'   (spider)
; - 0x07    - player symbol
; - 0x09    - '^'   (rope)
; - 0x0a    - ' ' ????
DRAW_BLOCK:
    009e  fe 00      CPI A, 00
    00a0  ca f1 00   JZ DRAW_BLOCK_SPACE (00f1)

    00a3  fe 01      CPI A, 01
    00a5  ca ec 00   JZ DRAW_BLOCK_HASH (00ec)

    00a8  fe 02      CPI A, 02
    00aa  ca e7 00   JZ DRAW_BLOCK_TREASURE (00e7)

    00ad  fe 03      CPI A, 03
    00af  ca e2 00   JZ DRAW_BLOCK_SOLID (00e2)

    00b2  fe 04      CPI A, 04
    00b4  ca dd 00   JZ DRAW_BLOCK_FLOOR (00dd)

    00b7  fe 05      CPI A, 05
    00b9  ca dd 00   JZ DRAW_BLOCK_FLOOR (00dd)

    00bc  fe 06      CPI A, 06
    00be  ca d8 00   JZ DRAW_BLOCK_SPIDER (00d8)

    00c1  fe 07      CPI A, 07
    00c3  ca d3 00   JZ DRAW_BLOCK_PLAYER (00d3)

    00c6  fe 0a      CPI A, 0a
    00c8  ca f1 00   JZ DRAW_BLOCK_SPACE (00f1)

    00cb  fe 09      CPI A, 09
    00cd  c0         RNZ

    00ce  0e 5e      MVI C, 5e                  ; Draw '^' rope symbol
    00d0  c3 f3 00   JMP DRAW_BLOCK_EXIT (00f3)

DRAW_BLOCK_PLAYER:
    00d3  0e 09      MVI C, 09                  ; Draw player symbol
    00d5  c3 f3 00   JMP DRAW_BLOCK_EXIT (00f3)

DRAW_BLOCK_SPIDER:
    00d8  0e 76      MVI C, 76                  ; Draw 'Ж' block
    00da  c3 f3 00   JMP DRAW_BLOCK_EXIT (00f3)

DRAW_BLOCK_FLOOR:
    00dd  0e 70      MVI C, 70                  ; Draw 'П' block
    00df  c3 f3 00   JMP DRAW_BLOCK_EXIT (00f3)

DRAW_BLOCK_SOLID:
    00e2  0e 17      MVI C, 17                  ; Draw solid block
    00e4  c3 f3 00   JMP DRAW_BLOCK_EXIT (00f3)

DRAW_BLOCK_TREASURE:
    00e7  0e 1e      MVI C, 1e                  ; Draw SP symbol
    00e9  c3 f3 00   JMP DRAW_BLOCK_EXIT (00f3)

DRAW_BLOCK_HASH:
    00ec  0e 23      MVI C, 23                  ; Draw '#'
    00ee  c3 f3 00   JMP DRAW_BLOCK_EXIT (00f3)

DRAW_BLOCK_SPACE:
    00f1  0e 20      MVI C, 20                  ; Draw ' '

DRAW_BLOCK_EXIT:
    00f3  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    00f6  c9         RET


; Draw the map pointed by HL
;
; The function draws the 60x20 game map. The function parses the map data pointed by HL. Each byte
; represents 2 consecutive blocks, printed by DRAW_BLOCK function
;
; Arguments:
; HL - map pointer
DRAW_MAP:
    00f7  eb         XCHG                       ; Save map pointer in DE

    00f8  06 14      MVI B, 14                  ; Will draw 20 lines of the map

    00fa  3e 21      MVI A, 21                  ; On each line will move cursor to the 1st char of the line
    00fc  32 11 00   STA MOVE_CURSOR_STR + 2 (0011)

DRAW_MAP_LINE_LOOP:
    00ff  21 0f 00   LXI HL, MOVE_CURSOR_STR (000f)
    0102  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0105  eb         XCHG                       ; Recall the map pointer

    0106  16 1e      MVI D, 1e                  ; Will process 30 bytes of the map per line

DRAW_MAP_CHAR_LOOP:
    0108  7e         MOV A, M                   ; Get high nibble
    0109  e6 f0      ANI A, f0
    010b  0f         RRC
    010c  0f         RRC
    010d  0f         RRC
    010e  0f         RRC

    010f  cd 9e 00   CALL DRAW_BLOCK (009e)     ; Draw the block associated with high nibble

    0112  7e         MOV A, M                   ; Draw the block associated with low nibble
    0113  e6 0f      ANI A, 0f
    0115  cd 9e 00   CALL DRAW_BLOCK (009e)

    0118  23         INX HL                     ; Advance to the next map byte

    0119  15         DCR D                      ; Repeat for all bytes in the line
    011a  c2 08 01   JNZ DRAW_MAP_CHAR_LOOP (0108)

    011d  05         DCR B                      ; Decrement the lines counter, exit when all lines are printed
    011e  c8         RZ

    011f  eb         XCHG                       ; Save map pointer in DE

    0120  21 11 00   LXI HL, MOVE_CURSOR_STR + 2 (0011) ; Increment Y cursor position
    0123  34         INR M

    0124  c3 ff 00   JMP DRAW_MAP_LINE_LOOP (00ff)  ; Repeat for the next line

    0127  c9         RET                        ; Not reached




; Initialize the map and internal structures
;
; The function scans the current map, and initialize the following structures:
; - Number of treasures on the map
; - Player current position and player original position
; - Enemies current positions and original positions
; - Total enemies count
INIT_MAP:
    0128  21 00 00   LXI HL, 0000               ; Zero number of treasures
    012b  22 89 04   SHLD NUM_TREASURES (0489)

    012e  97         SUB A                      ; Zero enemies counter
    012f  32 09 05   STA ENEMIES_COUNT (0509)

    0132  2a 5a 05   LHLD CUR_MAP_PTR (055a)    ; Load map pointer

    0135  16 21      MVI D, 21                  ; Will start from the leftmost char in the line ??????

INIT_MAP_ROW_LOOP:
    0137  1e 22      MVI E, 22                  ; Will start from the leftmost char in the line

INIT_MAP_COL_LOOP:
    0139  7e         MOV A, M                   ; Get the high nibble
    013a  e6 f0      ANI A, f0
    013c  0f         RRC
    013d  0f         RRC
    013e  0f         RRC
    013f  0f         RRC

    0140  cd 5e 01   CALL SCAN_BLOCK (015e)     ; Process the block

    0143  1c         INR E
    0144  7e         MOV A, M
    0145  e6 0f      ANI A, 0f
    0147  cd 5e 01   CALL SCAN_BLOCK (015e)     ; Process the lower nibble and its block

    014a  23         INX HL                     ; Advance to the next byte in the map

    014b  1c         INR E                      ; Repeat until reached rightmost char of the map
    014c  3e 5e      MVI A, 5e
    014e  bb         CMP E
    014f  c2 39 01   JNZ INIT_MAP_COL_LOOP (0139)

    0152  14         INR D                      ; Repeat until reached bottom line of the map
    0153  3e 35      MVI A, 35
    0155  ba         CMP D
    0156  c2 37 01   JNZ INIT_MAP_ROW_LOOP (0137)

    0159  21 09 05   LXI HL, ENEMIES_COUNT (0509)   ; Increment enemies counter ????
    015c  34         INR M
    015d  c9         RET



; Process a single block while initializing the map
;
; The function checks the block type, and initializes related structures:
; - If this is a treasure block - increment treasure counter
; - If this is a player - initialize player structure
; - If this is an enemy - increment enemies counter and initialize next enemy structure
;
; Arguments:
; - A - block type
; - DE - block screen coordinates
SCAN_BLOCK:
    015e  e5         PUSH HL                    ; Prologue
    015f  d5         PUSH DE
    0160  c5         PUSH BC

    0161  fe 02      CPI A, 02                  ; Check if the current block is a treasure
    0163  ca 7e 01   JZ SCAN_BLOCK_TREASURE (017e)

    0166  fe 06      CPI A, 06                  ; Check if the current block is a spider (original enemy position)
    0168  ca 88 01   JZ SCAN_BLOCK_ENEMY (0188)

    016b  fe 07      CPI A, 07                  ; Check if the current block is the player
    016d  c2 a9 01   JNZ SCAN_BLOCK_EXIT (01a9)

    0170  22 0f 05   SHLD PLAYER_STRUCT + 5 (050f)  ; Store original player position

    0173  7a         MOV A, D                   ; Store the player position into the cursor movement string
    0174  32 0c 05   STA PLAYER_STRUCT + 2 (050c)
    0177  7b         MOV A, E
    0178  32 0d 05   STA PLAYER_STRUCT + 3 (050d)

    017b  c3 a9 01   JMP SCAN_BLOCK_EXIT (01a9)

SCAN_BLOCK_TREASURE:
    017e  2a 89 04   LHLD NUM_TREASURES (0489)  ; Increment number of treasures
    0181  23         INX HL
    0182  22 89 04   SHLD NUM_TREASURES (0489)

    0185  c3 a9 01   JMP SCAN_BLOCK_EXIT (01a9)

SCAN_BLOCK_ENEMY:
    0188  3a 09 05   LDA ENEMIES_COUNT (0509)   ; Get the enemies counter

    018b  fe 05      CPI A, 05                  ; Limit number of enemies to 5
    018d  d2 a9 01   JNC SCAN_BLOCK_EXIT (01a9)

    0190  3c         INR A                      ; Increment number of enemies
    0191  32 09 05   STA ENEMIES_COUNT (0509)

    0194  e5         PUSH HL
    0195  21 0c 05   LXI HL, PLAYER_STRUCT + 2 (050c)
    0198  01 0b 00   LXI BC, 000b

SCAN_BLOCK_ENEMY_LOOP:
    019b  09         DAD BC                     ; Get address of the A'th enemy structure (position field)
    019c  3d         DCR A
    019d  c2 9b 01   JNZ SCAN_BLOCK_ENEMY_LOOP (019b)

    01a0  72         MOV M, D                   ; Store the current position
    01a1  23         INX HL
    01a2  73         MOV M, E
    01a3  23         INX HL

    01a4  23         INX HL                     ; Skip terminating zero
    01a5  d1         POP DE

    01a6  73         MOV M, E                   ; Store the enemy original position
    01a7  23         INX HL
    01a8  72         MOV M, D

SCAN_BLOCK_EXIT:
    01a9  c1         POP BC
    01aa  d1         POP DE
    01ab  e1         POP HL
    01ac  c9         RET



????:
01ad  cd 21 f8   CALL f821
01b0  fe 09      CPI A, 09
01b2  ca cc 01   JZ 01cc

????:
01b5  cd 21 f8   CALL f821
01b8  fe 23      CPI A, 23
01ba  ca cc 01   JZ 01cc

????:
01bd  cd 21 f8   CALL f821
01c0  fe 1e      CPI A, 1e
01c2  ca cc 01   JZ 01cc
01c5  fe 20      CPI A, 20
01c7  ca cc 01   JZ 01cc
01ca  fe 5e      CPI A, 5e
????:
01cc  c9         RET
????:
01cd  21 0a 05   LXI HL, PLAYER_POS_STR (050a)
01d0  3a 09 05   LDA ENEMIES_COUNT (0509)
????:
01d3  32 57 05   STA 0557
01d6  22 58 05   SHLD 0558
01d9  11 4c 05   LXI DE, 054c
01dc  06 0b      MVI B, 0b
????:
01de  7e         MOV A, M
01df  12         STAX DE
01e0  23         INX HL
01e1  13         INX DE
01e2  05         DCR B
01e3  c2 de 01   JNZ 01de
01e6  3a 54 05   LDA 0554
01e9  fe 01      CPI A, 01
01eb  ca 4b 02   JZ 024b
01ee  f2 90 03   JP 0390
01f1  3a 53 05   LDA 0553
01f4  fe ff      CPI A, ff
01f6  ca 0a 02   JZ 020a
01f9  fe 00      CPI A, 00
01fb  c2 06 02   JNZ 0206
01fe  3e 02      MVI A, 02
????:
0200  32 53 05   STA 0553
0203  c3 90 03   JMP 0390
????:
0206  3d         DCR A
0207  32 53 05   STA 0553
????:
020a  3a 55 05   LDA 0555
020d  fe 23      CPI A, 23
020f  ca 4b 02   JZ 024b
0212  fe 5e      CPI A, 5e
0214  ca 4b 02   JZ 024b
0217  21 4c 05   LXI HL, 054c
021a  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
021d  0e 1a      MVI C, 1a
021f  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0222  cd bd 01   CALL 01bd
0225  ca b0 02   JZ 02b0
0228  fe 70      CPI A, 70
022a  c2 4b 02   JNZ 024b
022d  2a 51 05   LHLD 0551
0230  01 1e 00   LXI BC, 001e
0233  09         DAD BC
0234  3a 4f 05   LDA 054f
0237  e6 01      ANI A, 01
0239  fe 00      CPI A, 00
023b  c2 43 02   JNZ 0243
023e  3e 30      MVI A, 30
0240  c3 45 02   JMP 0245
????:
0243  3e 03      MVI A, 03
????:
0245  a6         ANA M
0246  fe 00      CPI A, 00
0248  ca b0 02   JZ 02b0
????:
024b  3a 56 05   LDA 0556
024e  fe 1a      CPI A, 1a
0250  ca f1 02   JZ 02f1
0253  fe 19      CPI A, 19
0255  ca d1 02   JZ 02d1
????:
0258  fe 08      CPI A, 08
025a  ca 84 02   JZ 0284
025d  fe 18      CPI A, 18
025f  c2 90 03   JNZ 0390
0262  06 08      MVI B, 08
0264  3e 18      MVI A, 18
0266  32 8b 04   STA 048b
0269  21 1c 00   LXI HL, RIGHT_STR (001c)
026c  22 8c 04   SHLD 048c
026f  3e 01      MVI A, 01
0271  32 90 04   STA 0490
0274  3a 4f 05   LDA 054f
0277  e6 01      ANI A, 01
0279  fe 00      CPI A, 00
027b  ca a4 02   JZ 02a4
027e  11 01 00   LXI DE, 0001
0281  c3 a7 02   JMP 02a7
????:
0284  06 18      MVI B, 18
0286  3e 08      MVI A, 08
0288  32 8b 04   STA 048b
028b  21 1a 00   LXI HL, LEFT_STR (001a)
028e  22 8c 04   SHLD 048c
0291  3e ff      MVI A, ff
0293  32 90 04   STA 0490
0296  3a 4f 05   LDA 054f
0299  e6 01      ANI A, 01
029b  c2 a4 02   JNZ 02a4
029e  11 ff ff   LXI DE, ffff
02a1  c3 a7 02   JMP 02a7
????:
02a4  11 00 00   LXI DE, 0000
????:
02a7  21 4f 05   LXI HL, 054f
02aa  22 8e 04   SHLD 048e
02ad  c3 0c 03   JMP 030c
????:
02b0  06 19      MVI B, 19
02b2  3e 1a      MVI A, 1a
02b4  32 8b 04   STA 048b
02b7  21 17 00   LXI HL, DOWN_STR (0017)
02ba  22 8c 04   SHLD 048c
02bd  21 4e 05   LXI HL, 054e
02c0  22 8e 04   SHLD 048e
02c3  3e 01      MVI A, 01
02c5  32 90 04   STA 0490
02c8  11 1e 00   LXI DE, 001e
02cb  cd b5 01   CALL 01b5
02ce  c3 1f 03   JMP 031f
????:
02d1  3a 55 05   LDA 0555
02d4  fe 23      CPI A, 23
02d6  c2 90 03   JNZ 0390
02d9  06 1a      MVI B, 1a
02db  3e 19      MVI A, 19
02dd  32 8b 04   STA 048b
02e0  21 14 00   LXI HL, UP_STR (0014)
02e3  22 8c 04   SHLD 048c
02e6  3e ff      MVI A, ff
02e8  32 90 04   STA 0490
02eb  11 e2 ff   LXI DE, ffe2
02ee  c3 06 03   JMP 0306
????:
02f1  06 19      MVI B, 19
02f3  3e 1a      MVI A, 1a
02f5  32 8b 04   STA 048b
02f8  21 17 00   LXI HL, DOWN_STR (0017)
02fb  22 8c 04   SHLD 048c
02fe  3e 01      MVI A, 01
0300  32 90 04   STA 0490
0303  11 1e 00   LXI DE, 001e
????:
0306  21 4e 05   LXI HL, 054e
0309  22 8e 04   SHLD 048e
????:
030c  21 4c 05   LXI HL, 054c
030f  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
0312  3a 8b 04   LDA 048b
0315  4f         MOV C, A
0316  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0319  cd ad 01   CALL 01ad
031c  c2 90 03   JNZ 0390
????:
031f  21 55 05   LXI HL, 0555
0322  48         MOV C, B
0323  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0326  4e         MOV C, M
0327  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
032a  32 55 05   STA 0555
032d  2a 8c 04   LHLD 048c
0330  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
0333  0e 09      MVI C, 09
0335  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0338  2a 8e 04   LHLD 048e
033b  3a 90 04   LDA 0490
033e  86         ADD M
033f  77         MOV M, A
0340  2a 51 05   LHLD 0551
0343  19         DAD DE
0344  22 51 05   SHLD 0551
0347  3a 55 05   LDA 0555
034a  fe 09      CPI A, 09
034c  c2 90 03   JNZ 0390
034f  21 0c 05   LXI HL, PLAYER_POS_STR + 2 (050c)
0352  11 13 05   LXI DE, 0513
0355  01 0b 00   LXI BC, 000b
0358  3a 09 05   LDA ENEMIES_COUNT (0509)
035b  32 8b 04   STA 048b
????:
035e  3a 4e 05   LDA 054e
0361  be         CMP M
0362  c2 7d 03   JNZ 037d
0365  23         INX HL
0366  3a 4f 05   LDA 054f
0369  be         CMP M
036a  c2 7c 03   JNZ 037c
036d  2b         DCX HL
036e  eb         XCHG
036f  7e         MOV A, M
0370  eb         XCHG
0371  fe 09      CPI A, 09
0373  ca 7d 03   JZ 037d
0376  32 55 05   STA 0555
0379  c3 90 03   JMP 0390
????:
037c  2b         DCX HL
????:
037d  09         DAD BC
037e  eb         XCHG
037f  09         DAD BC
0380  eb         XCHG
0381  3a 8b 04   LDA 048b
0384  3d         DCR A
0385  fe 00      CPI A, 00
0387  ca 90 03   JZ 0390
038a  32 8b 04   STA 048b
038d  c3 5e 03   JMP 035e
????:
0390  2a 58 05   LHLD 0558
0393  11 4c 05   LXI DE, 054c
0396  06 0b      MVI B, 0b
????:
0398  1a         LDAX DE
0399  77         MOV M, A
039a  23         INX HL
039b  13         INX DE
039c  05         DCR B
039d  c2 98 03   JNZ 0398
03a0  3a 57 05   LDA 0557
03a3  3d         DCR A
03a4  c2 d3 01   JNZ 01d3
03a7  c9         RET
????:
03a8  3a 13 05   LDA 0513
03ab  fe 1e      CPI A, 1e
03ad  c0         RNZ
03ae  3e 20      MVI A, 20
03b0  32 13 05   STA 0513
03b3  2a 89 04   LHLD NUM_TREASURES (0489)
03b6  2b         DCX HL
03b7  22 89 04   SHLD NUM_TREASURES (0489)
03ba  21 87 04   LXI HL, 0487
03bd  06 03      MVI B, 03
03bf  3e 10      MVI A, 10
03c1  37         STC
03c2  3f         CMC
????:
03c3  8e         ADC M
03c4  27         DAA
03c5  77         MOV M, A
03c6  3e 00      MVI A, 00
03c8  2b         DCX HL
03c9  05         DCR B
03ca  c2 c3 03   JNZ 03c3
03cd  21 46 00   LXI HL, 0046
03d0  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
03d3  06 04      MVI B, 04
03d5  21 85 04   LXI HL, 0485
????:
03d8  7e         MOV A, M
03d9  cd 15 f8   CALL MONITOR_PRINT_BYTE_HEX (f815)
03dc  23         INX HL
03dd  05         DCR B
03de  c2 d8 03   JNZ 03d8
03e1  c9         RET
????:
03e2  21 cd 04   LXI HL, 04cd
03e5  01 03 00   LXI BC, 0003
????:
03e8  7e         MOV A, M
03e9  fe 00      CPI A, 00
03eb  ca 12 04   JZ 0412
03ee  fe 01      CPI A, 01
03f0  ca f8 03   JZ 03f8
03f3  35         DCR M
03f4  09         DAD BC
03f5  c3 e8 03   JMP 03e8
????:
03f8  35         DCR M
03f9  23         INX HL
03fa  0e 1b      MVI C, 1b
03fc  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
03ff  0e 59      MVI C, 59
0401  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0404  4e         MOV C, M
0405  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0408  23         INX HL
0409  4e         MOV C, M
040a  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
040d  0e 70      MVI C, 70
040f  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
????:
0412  3a 14 05   LDA 0514
0415  fe 1f      CPI A, 1f
0417  c2 25 04   JNZ 0425
041a  21 0a 05   LXI HL, PLAYER_POS_STR (050a)
041d  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
0420  0e 18      MVI C, 18
0422  c3 30 04   JMP 0430
????:
0425  fe 0c      CPI A, 0c
0427  c0         RNZ
0428  21 0a 05   LXI HL, PLAYER_POS_STR (050a)
042b  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
042e  0e 08      MVI C, 08
????:
0430  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0433  cd 21 f8   CALL f821
0436  fe 20      CPI A, 20
0438  ca 3e 04   JZ 043e
043b  fe 5e      CPI A, 5e
043d  c0         RNZ
????:
043e  0e 1a      MVI C, 1a
0440  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0443  cd 21 f8   CALL f821
0446  fe 70      CPI A, 70
0448  c0         RNZ
0449  21 cd 04   LXI HL, 04cd
044c  11 91 04   LXI DE, 0491
044f  06 39      MVI B, 39
????:
0451  7e         MOV A, M
0452  12         STAX DE
0453  23         INX HL
0454  13         INX DE
0455  05         DCR B
0456  c2 51 04   JNZ 0451
0459  21 cd 04   LXI HL, 04cd
045c  36 32      MVI M, 32
045e  eb         XCHG
045f  cd 1e f8   CALL f81e
0462  3e 1d      MVI A, 1d
0464  84         ADD H
0465  13         INX DE
0466  12         STAX DE
0467  3e 18      MVI A, 18
0469  85         ADD L
046a  13         INX DE
046b  12         STAX DE
046c  13         INX DE
046d  21 91 04   LXI HL, 0491
0470  06 39      MVI B, 39
????:
0472  7e         MOV A, M
0473  12         STAX DE
0474  23         INX HL
0475  13         INX DE
0476  05         DCR B
0477  c2 72 04   JNZ 0472
047a  0e 20      MVI C, 20
047c  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
047f  3e 00      MVI A, 00
0481  32 14 05   STA 0514
0484  c9         RET
????:
0485  00         NOP
0486  02         STAX BC
????:
0487  80         ADD B
0488  00         NOP

NUM_TREASURES:
0489  04         INR B
048a  00         NOP
????:
048b  08         db 08
????:
048c  1a         LDAX DE
048d  00         NOP
????:
048e  4f         MOV C, A
048f  05         DCR B
????:
0490  ff         RST 7

????:
0491  1e 31      MVI E, 31
0493  4c         MOV C, H
0494  09         DAD BC
0495  2e 4d      MVI L, 4d
0497  00         NOP
0498  2e 43      MVI L, 43
049a  00         NOP
049b  2b         DCX HL
049c  56         MOV D, M
049d  00         NOP
049e  31 27 00   LXI SP, 0027
04a1  28         db 28
04a2  51         MOV D, C
04a3  00         NOP
04a4  25         DCR H
04a5  52         MOV D, D
04a6  00         NOP
04a7  00         NOP
04a8  00         NOP
04a9  00         NOP
04aa  00         NOP
04ab  00         NOP
04ac  00         NOP
04ad  00         NOP
04ae  00         NOP
04af  00         NOP
04b0  00         NOP
04b1  00         NOP
04b2  00         NOP
04b3  00         NOP
04b4  00         NOP
04b5  00         NOP
04b6  00         NOP
04b7  00         NOP
04b8  00         NOP
04b9  00         NOP
04ba  00         NOP
04bb  00         NOP
04bc  00         NOP
04bd  00         NOP
04be  00         NOP
04bf  00         NOP
04c0  00         NOP
04c1  00         NOP
04c2  00         NOP
04c3  00         NOP
04c4  00         NOP
04c5  00         NOP
04c6  00         NOP
04c7  00         NOP
04c8  00         NOP
04c9  00         NOP
04ca  00         NOP
04cb  00         NOP
04cc  00         NOP
????:
04cd  22 31 58   SHLD 5831
04d0  0e 31      MVI C, 31
04d2  4c         MOV C, H
04d3  00         NOP
04d4  2e 4d      MVI L, 4d
04d6  00         NOP
04d7  2e 43      MVI L, 43
04d9  00         NOP
04da  2b         DCX HL
04db  56         MOV D, M
04dc  00         NOP
04dd  31 27 00   LXI SP, 0027
04e0  28         db 28
04e1  51         MOV D, C
04e2  00         NOP
04e3  25         DCR H
04e4  52         MOV D, D
04e5  00         NOP
04e6  00         NOP
04e7  00         NOP
04e8  00         NOP
04e9  00         NOP
04ea  00         NOP
04eb  00         NOP
04ec  00         NOP
04ed  00         NOP
04ee  00         NOP
04ef  00         NOP
04f0  00         NOP
04f1  00         NOP
04f2  00         NOP
04f3  00         NOP
04f4  00         NOP
04f5  00         NOP
04f6  00         NOP
04f7  00         NOP
04f8  00         NOP
04f9  00         NOP
04fa  00         NOP
04fb  00         NOP
04fc  00         NOP
04fd  00         NOP
04fe  00         NOP
04ff  00         NOP
0500  00         NOP
0501  00         NOP
0502  00         NOP
0503  00         NOP
0504  00         NOP
0505  00         NOP
0506  00         NOP
0507  00         NOP
0508  00         NOP

ENEMIES_COUNT:
    0509  03                        db 00

PLAYER_STRUCT:
PLAYER_POS_STR:
    050a  1b 59 33 51 00            db 0x1b, 0x59, 0x33, 0x51, 0x00     ; String that moves cursor to the current player position
    050f  4b 0d                     dw 0d4b                             ; Original player position

0511  ff         RST 7
????:
0512  00         NOP
????:
0513  23         INX HL
????:
0514  08         db 08

ENEMY1_STRUCT:
ENEMY1_POS_STR:
    0515  1b 59 33 51 00            db 0x1b, 0x59, 0x33, 0x51, 0x00     ; String that moves cursor to the enemy1 screen position
051a  4b         MOV C, E
051b  0d         DCR C
051c  02         STAX BC
051d  f2 23 18   JP 1823

????:
0520  1b         DCX DE
0521  59         MOV E, C
0522  2d         DCR L
0523  53         MOV D, E
0524  00         NOP
0525  98         SBB B
0526  0c         INR C
0527  01 00 20   LXI BC, 2000
052a  08         db 08
052b  1b         DCX DE
052c  59         MOV E, C
052d  33         INX SP
052e  37         STC
052f  00         NOP
0530  46         MOV B, M
0531  14         INR D
0532  00         NOP
0533  00         NOP
0534  20         db 20
0535  18         db 18
0536  1b         DCX DE
0537  59         MOV E, C
0538  33         INX SP
0539  48         MOV C, B
053a  00         NOP
053b  4f         MOV C, A
053c  14         INR D
053d  01 00 20   LXI BC, 2000
0540  08         db 08
0541  1b         DCX DE
0542  59         MOV E, C
0543  00         NOP
0544  00         NOP
0545  00         NOP
0546  00         NOP
0547  00         NOP
0548  01 00 20   LXI BC, 2000
054b  08         db 08
????:
054c  1b         DCX DE
054d  59         MOV E, C
????:
054e  2d         DCR L
????:
054f  53         MOV D, E
0550  00         NOP
????:
0551  98         SBB B
0552  0c         INR C
????:
0553  01 00 20   LXI BC, 2000
????:
0556  08         db 08
????:
0557  01 20 05   LXI BC, 0520

CUR_MAP_PTR:
    055a  18 0b             dw MAP_01 (0b18)            ; Pointer to the current map

WELCOME_SCREEN:
    055c  1f 1b 59 27 34 17 20 20 20 20 20 20 17 17 17 20
    056c  20 17 17 17 17 20 20 17 17 17 17 17 1b 59 28 34
    057c  17 20 20 20 20 20 17 20 20 20 17 20 17 20 20 20
    058c  17 20 17 1b 59 29 34 17 20 20 20 20 20 17 20 20
    059c  20 17 20 17 20 20 20 17 20 17 17 17 17 1b 59 2a
    05ac  34 17 20 20 20 20 20 17 20 20 20 17 20 17 20 20
    05bc  20 17 20 17 1b 59 2b 34 17 17 17 17 17 20 20 17
    05cc  17 17 20 20 17 17 17 17 20 20 17 17 17 17 17 1b
    05dc  59 2f 2e 17 17 17 17 20 20 17 20 20 20 17 20 17
    05ec  20 20 20 17 20 17 20 20 20 17 20 17 17 17 17 17
    05fc  20 17 17 17 17 1b 59 30 2e 17 20 20 20 17 20 17
    060c  20 20 20 17 20 17 17 20 20 17 20 17 17 20 20 17
    061c  20 17 20 20 20 20 20 17 20 20 20 17 1b 59 31 2e
    062c  17 17 17 17 20 20 17 20 20 20 17 20 17 20 17 20
    063c  17 20 17 20 17 20 17 20 17 17 17 17 20 20 17 17
    064c  17 17 1b 59 32 2e 17 20 17 20 20 20 17 20 20 20
    065c  17 20 17 20 20 17 17 20 17 20 20 17 17 20 17 20
    066c  20 20 20 20 17 20 17 1b 59 33 2e 17 20 20 17 20
    067c  20 20 17 17 17 20 20 17 20 20 20 17 20 17 20 20
    068c  20 17 20 17 17 17 17 17 20 17 20 20 17 00 

EXIT_STR:
    069a  1f 1b 59 2b 34 17 17 17 17 17 20 17 20 20 20 17
    06aa  20 20 20 17 20 20 20 17 17 17 17 17 1b 59 2c 34
    06ba  17 20 20 20 20 20 20 17 20 17 20 20 20 20 17 20
    06ca  20 20 20 20 17 1b 59 2d 34 17 17 17 17 20 20 20
    06da  20 17 20 20 20 20 20 17 20 20 20 20 20 17 1b 59
    06ea  2e 34 17 20 20 20 20 20 20 17 20 17 20 20 20 20
    06fa  17 20 20 20 20 20 17 1b 59 2f 34 17 17 17 17 17
    070a  20 17 20 20 20 17 20 20 20 17 20 20 20 20 20 17
    071a  00

????:
071b  21 15 05   LXI HL, 0515
071e  3a 09 05   LDA ENEMIES_COUNT (0509)
0721  3d         DCR A
????:
0722  32 57 05   STA 0557
0725  22 58 05   SHLD 0558
0728  11 4c 05   LXI DE, 054c
072b  06 0b      MVI B, 0b
????:
072d  7e         MOV A, M
072e  12         STAX DE
072f  23         INX HL
0730  13         INX DE
0731  05         DCR B
0732  c2 2d 07   JNZ 072d
0735  3a 53 05   LDA 0553
0738  fe 00      CPI A, 00
073a  ca ef 08   JZ 08ef
073d  3a 54 05   LDA 0554
0740  fe 02      CPI A, 02
0742  ca 6d 08   JZ 086d
0745  fe 00      CPI A, 00
0747  ca 51 07   JZ 0751
074a  f2 eb 08   JP 08eb
074d  3c         INR A
074e  32 54 05   STA 0554
????:
0751  2a 51 05   LHLD 0551
0754  3a 4f 05   LDA 054f
0757  e6 01      ANI A, 01
0759  fe 00      CPI A, 00
075b  c2 68 07   JNZ 0768
075e  7e         MOV A, M
075f  e6 f0      ANI A, f0
0761  0f         RRC
0762  0f         RRC
0763  0f         RRC
0764  0f         RRC
0765  c3 6b 07   JMP 076b
????:
0768  7e         MOV A, M
0769  e6 0f      ANI A, 0f
????:
076b  fe 05      CPI A, 05
076d  c2 78 07   JNZ 0778
0770  3e 14      MVI A, 14
0772  32 54 05   STA 0554
0775  c3 ef 08   JMP 08ef
????:
0778  3a 54 05   LDA 0554
077b  fe 00      CPI A, 00
077d  c2 ef 08   JNZ 08ef
0780  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)
0783  21 4e 05   LXI HL, 054e
0786  be         CMP M
0787  ca b0 07   JZ 07b0
078a  fa a3 07   JM 07a3
078d  21 4c 05   LXI HL, 054c
0790  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
0793  0e 1a      MVI C, 1a
0795  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0798  cd b5 01   CALL 01b5
079b  c2 b0 07   JNZ 07b0
079e  3e 1a      MVI A, 1a
07a0  c3 c4 07   JMP 07c4
????:
07a3  3a 55 05   LDA 0555
07a6  fe 23      CPI A, 23
07a8  c2 b0 07   JNZ 07b0
07ab  3e 19      MVI A, 19
07ad  c3 c4 07   JMP 07c4
????:
07b0  3a 0d 05   LDA PLAYER_POS_STR + 3 (050d)
07b3  21 4f 05   LXI HL, 054f
07b6  be         CMP M
07b7  ca ca 07   JZ 07ca
07ba  fa c2 07   JM 07c2
07bd  3e 18      MVI A, 18
07bf  c3 c4 07   JMP 07c4
????:
07c2  3e 08      MVI A, 08
????:
07c4  32 56 05   STA 0556
07c7  c3 ef 08   JMP 08ef
????:
07ca  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)
07cd  21 4e 05   LXI HL, 054e
07d0  be         CMP M
07d1  fa 09 08   JM 0809
07d4  21 4c 05   LXI HL, 054c
07d7  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
07da  0e 1a      MVI C, 1a
07dc  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
07df  1e 00      MVI E, 00
????:
07e1  0e 08      MVI C, 08
07e3  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
07e6  1c         INR E
07e7  cd b5 01   CALL 01b5
07ea  c2 e1 07   JNZ 07e1
07ed  21 4c 05   LXI HL, 054c
07f0  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
07f3  0e 1a      MVI C, 1a
07f5  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
07f8  16 00      MVI D, 00
????:
07fa  0e 18      MVI C, 18
07fc  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
07ff  14         INR D
????:
0800  cd b5 01   CALL 01b5
0803  c2 fa 07   JNZ 07fa
0806  c3 49 08   JMP 0849
????:
0809  21 4c 05   LXI HL, 054c
080c  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
080f  1e 00      MVI E, 00
????:
0811  0e 08      MVI C, 08
0813  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0816  1c         INR E
0817  cd 21 f8   CALL f821
081a  fe 70      CPI A, 70
081c  ca 27 08   JZ 0827
081f  fe 23      CPI A, 23
0821  c2 11 08   JNZ 0811
0824  c3 29 08   JMP 0829
????:
0827  1e 7f      MVI E, 7f
????:
0829  21 4c 05   LXI HL, 054c
082c  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
082f  16 00      MVI D, 00
????:
0831  0e 18      MVI C, 18
0833  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0836  14         INR D
0837  cd 21 f8   CALL f821
083a  fe 70      CPI A, 70
083c  ca 47 08   JZ 0847
083f  fe 23      CPI A, 23
0841  c2 31 08   JNZ 0831
0844  c3 49 08   JMP 0849
????:
0847  16 7f      MVI D, 7f
????:
0849  7b         MOV A, E
084a  ba         CMP D
084b  ca 68 08   JZ 0868
084e  fa 5a 08   JM 085a
0851  5a         MOV E, D
0852  3e 18      MVI A, 18
0854  32 56 05   STA 0556
0857  c3 5f 08   JMP 085f
????:
085a  3e 08      MVI A, 08
085c  32 56 05   STA 0556
????:
085f  7b         MOV A, E
0860  2f         CMA
0861  3c         INR A
????:
0862  32 54 05   STA 0554
0865  c3 ef 08   JMP 08ef
????:
0868  3e 00      MVI A, 00
086a  c3 62 08   JMP 0862
????:
086d  21 4c 05   LXI HL, 054c
0870  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
0873  cd 21 f8   CALL f821
0876  fe 70      CPI A, 70
0878  ca bc 08   JZ 08bc
087b  0e 19      MVI C, 19
087d  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0880  cd b5 01   CALL 01b5
0883  c2 ef 08   JNZ 08ef
0886  21 55 05   LXI HL, 0555
0889  0e 1a      MVI C, 1a
088b  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
088e  4e         MOV C, M
088f  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0892  32 55 05   STA 0555
0895  0e 08      MVI C, 08
0897  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
089a  0e 19      MVI C, 19
089c  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
089f  0e 09      MVI C, 09
08a1  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
08a4  21 4e 05   LXI HL, 054e
08a7  35         DCR M
08a8  2a 51 05   LHLD 0551
08ab  11 e2 ff   LXI DE, ffe2
08ae  19         DAD DE
08af  22 51 05   SHLD 0551
08b2  3a 54 05   LDA 0554
08b5  3d         DCR A
08b6  32 54 05   STA 0554
08b9  c3 b0 07   JMP 07b0
????:
08bc  3a 15 0b   LDA 0b15
08bf  e6 1c      ANI A, 1c
08c1  f6 04      ORI A, 04
08c3  2a 5a 05   LHLD CUR_MAP_PTR (055a)
08c6  5f         MOV E, A
08c7  16 00      MVI D, 00
08c9  19         DAD DE
08ca  22 51 05   SHLD 0551
08cd  21 4e 05   LXI HL, 054e
08d0  36 21      MVI M, 21
08d2  23         INX HL
08d3  87         ADD A
08d4  c6 22      ADI A, 22
08d6  77         MOV M, A
08d7  3e 00      MVI A, 00
08d9  32 54 05   STA 0554
08dc  21 4c 05   LXI HL, 054c
08df  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
08e2  cd 21 f8   CALL f821
08e5  32 55 05   STA 0555
08e8  c3 ef 08   JMP 08ef
????:
08eb  3d         DCR A
08ec  32 54 05   STA 0554
????:
08ef  2a 58 05   LHLD 0558
08f2  11 4c 05   LXI DE, 054c
08f5  06 0b      MVI B, 0b
????:
08f7  1a         LDAX DE
08f8  77         MOV M, A
08f9  23         INX HL
08fa  13         INX DE
08fb  05         DCR B
08fc  c2 f7 08   JNZ 08f7
08ff  3a 57 05   LDA 0557
0902  3d         DCR A
0903  c2 22 07   JNZ 0722
0906  c9         RET
????:
0907  3a 16 0b   LDA 0b16
090a  fe 00      CPI A, 00
090c  c0         RNZ
090d  2a 89 04   LHLD NUM_TREASURES (0489)
0910  3e 00      MVI A, 00
0912  bc         CMP H
0913  c0         RNZ
0914  bd         CMP L
0915  c0         RNZ
0916  06 14      MVI B, 14
0918  2a 5a 05   LHLD CUR_MAP_PTR (055a)
091b  16 21      MVI D, 21
????:
091d  1e 22      MVI E, 22
????:
091f  7e         MOV A, M
0920  e6 f0      ANI A, f0
0922  0f         RRC
0923  0f         RRC
0924  0f         RRC
0925  0f         RRC
0926  fe 0a      CPI A, 0a
0928  cc 49 09   CZ 0949
092b  1c         INR E
092c  7e         MOV A, M
092d  e6 0f      ANI A, 0f
092f  fe 0a      CPI A, 0a
0931  cc 49 09   CZ 0949
0934  1c         INR E
0935  23         INX HL
0936  3e 5e      MVI A, 5e
0938  bb         CMP E
0939  c2 1f 09   JNZ 091f
093c  14         INR D
093d  3e 35      MVI A, 35
093f  ba         CMP D
0940  c2 1d 09   JNZ 091d
0943  3e ff      MVI A, ff
0945  32 16 0b   STA 0b16
0948  c9         RET
????:
0949  0e 1b      MVI C, 1b
094b  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
094e  0e 59      MVI C, 59
0950  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0953  4a         MOV C, D
0954  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
0957  4b         MOV C, E
0958  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
095b  cd 21 f8   CALL f821
095e  fe 09      CPI A, 09
0960  c2 a3 09   JNZ 09a3
0963  e5         PUSH HL
0964  d5         PUSH DE
0965  c5         PUSH BC
0966  eb         XCHG
0967  22 12 0b   SHLD 0b12
096a  21 0c 05   LXI HL, PLAYER_POS_STR + 2 (050c)
096d  11 13 05   LXI DE, 0513
0970  01 0b 00   LXI BC, 000b
0973  3a 09 05   LDA ENEMIES_COUNT (0509)
0976  32 15 0b   STA 0b15
????:
0979  3a 13 0b   LDA 0b13
097c  be         CMP M
097d  c2 8d 09   JNZ 098d
0980  23         INX HL
0981  3a 12 0b   LDA 0b12
0984  be         CMP M
0985  c2 8c 09   JNZ 098c
0988  eb         XCHG
0989  36 23      MVI M, 23
098b  eb         XCHG
????:
098c  2b         DCX HL
????:
098d  09         DAD BC
098e  eb         XCHG
098f  09         DAD BC
0990  eb         XCHG
0991  3a 15 0b   LDA 0b15
0994  3d         DCR A
0995  fe 00      CPI A, 00
0997  ca a0 09   JZ 09a0
099a  32 15 0b   STA 0b15
099d  c3 79 09   JMP 0979
????:
09a0  c1         POP BC
09a1  d1         POP DE
09a2  e1         POP HL
????:
09a3  0e 23      MVI C, 23
09a5  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
09a8  c9         RET

REAL_START:
    09a9  21 5c 05   LXI HL, WELCOME_SCREEN (055c)  ; Print the intro screen
    09ac  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    09af  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for a key press

    09b2  cd 55 00   CALL DRAW_BORDER (0055)        ; Draw the game screen

    09b5  21 18 0b   LXI HL, MAP_01 (0b18)          ; Initialize current map pointer
    09b8  22 5a 05   SHLD CUR_MAP_PTR (055a)

    09bb  06 04      MVI B, 04                      ; Zero 4 bytes at 0x0485 ????
    09bd  21 85 04   LXI HL, 0485
????:
    09c0  23         INX HL
    09c1  36 00      MVI M, 00
    09c3  05         DCR B
    09c4  c2 c0 09   JNZ 09c0

    09c7  3e 03      MVI A, 03                      ; Set initial number of lives
    09c9  32 17 0b   STA LIVES_COUNT (0b17)

    09cc  3e 01      MVI A, 01                      ; Set initial level
    09ce  32 11 0b   STA CUR_LEVEL (0b11)

; Restart the game on a new map
;
; ?????
NEW_MAP:
    09d1  21 4b 00   LXI HL, MOVE_TO_LIVES_STR (004b)   ; Move cursor to lives number position
    09d4  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    09d7  3a 17 0b   LDA LIVES_COUNT (0b17)         ; Print the value
    09da  27         DAA
    09db  cd 15 f8   CALL MONITOR_PRINT_BYTE_HEX (f815)

    09de  21 50 00   LXI HL, MOVE_TO_LEVEL_STR (0050)   ; Move cursor to level number position
    09e1  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    09e4  3a 11 0b   LDA CUR_LEVEL (0b11)           ; Print the value
    09e7  cd 15 f8   CALL MONITOR_PRINT_BYTE_HEX (f815)

    09ea  21 13 05   LXI HL, 0513               ; Set 0x20 to ????? field of 6 structures ????
    09ed  11 0b 00   LXI DE, 000b
    09f0  06 06      MVI B, 06

????:
    09f2  36 20      MVI M, 20
    09f4  19         DAD DE
    09f5  05         DCR B
    09f6  c2 f2 09   JNZ 09f2

    09f9  21 12 05   LXI HL, 0512               ; Clear ???? field in 6 structures ????
    09fc  06 06      MVI B, 06

????:
    09fe  36 00      MVI M, 00
    0a00  19         DAD DE
    0a01  05         DCR B
    0a02  c2 fe 09   JNZ 09fe

    0a05  21 91 04   LXI HL, 0491               ; Clear 120 bytes at 0x0491
    0a08  06 78      MVI B, 78
????:
    0a0a  36 00      MVI M, 00
    0a0c  23         INX HL
    0a0d  05         DCR B
    0a0e  c2 0a 0a   JNZ 0a0a

    0a11  2a 5a 05   LHLD CUR_MAP_PTR (055a)    ; Print the map
    0a14  cd f7 00   CALL DRAW_MAP (00f7)

    0a17  cd 28 01   CALL INIT_MAP (0128)       ; Initialize the map structures

    0a1a  3e 00      MVI A, 00                  ; Clear some flag ????
    0a1c  32 16 0b   STA 0b16

WAIT_START_KEY:
    0a1f  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for a initial key press

    0a22  fe 4c      CPI A, 4c                  ; 'L' advances the level
    0a24  ca 8d 0a   JZ ADVANCE_LEVEL (0a8d)

    0a27  fe 4d      CPI A, 4d                  ; 'M' increments lives counter
    0a29  c2 40 0a   JNZ 0a40

    0a2c  21 4b 00   LXI HL, MOVE_TO_LIVES_STR (004b)   ; Move cursor to the lives field
    0a2f  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0a32  3a 17 0b   LDA LIVES_COUNT (0b17)     ; Increment the lives counter
    0a35  3c         INR A
    0a36  32 17 0b   STA LIVES_COUNT (0b17)
    0a39  27         DAA

    0a3a  cd 15 f8   CALL MONITOR_PRINT_BYTE_HEX (f815) ; Print the new value on the screen

    0a3d  c3 1f 0a   JMP WAIT_START_KEY (0a1f)

????:
    0a40  cd 1b f8   CALL MONITOR_SCAN_KBD (f81b)   ; Check if a key is pressed

    0a43  fe ff      CPI A, ff                  ; If no key pressed - ????
    0a45  ca 4b 0a   JZ 0a4b

    0a48  32 14 05   STA 0514                   ; Store the pressed key value

????:
    0a4b  fe 41      CPI A, 41                  ; 'A' restarts the level, reducing lives counter
    0a4d  ca e0 0a   JZ PLAYER_DIE (0ae0)

0a50  cd cd 01   CALL 01cd
0a53  cd a8 03   CALL 03a8
0a56  cd e2 03   CALL 03e2
0a59  cd 1b 07   CALL 071b
0a5c  cd 07 09   CALL 0907
0a5f  16 2f      MVI D, 2f
????:
0a61  1e 6f      MVI E, 6f
????:
0a63  1d         DCR E
0a64  c2 63 0a   JNZ 0a63
0a67  15         DCR D
0a68  c2 61 0a   JNZ 0a61
0a6b  21 15 0b   LXI HL, 0b15
0a6e  34         INR M
0a6f  2a 89 04   LHLD NUM_TREASURES (0489)
0a72  97         SUB A
0a73  bc         CMP H
0a74  c2 ac 0a   JNZ 0aac
0a77  bd         CMP L
0a78  c2 ac 0a   JNZ 0aac
0a7b  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)
0a7e  fe 21      CPI A, 21
0a80  c2 ac 0a   JNZ 0aac
0a83  e6 00      ANI A, 00
0a85  3a 17 0b   LDA LIVES_COUNT (0b17)
0a88  3c         INR A
0a89  32 17 0b   STA LIVES_COUNT (0b17)
0a8c  27         DAA

ADVANCE_LEVEL:
    0a8d  3a 11 0b   LDA CUR_LEVEL (0b11)       ; Increment the level value
    0a90  3c         INR A
    0a91  27         DAA

    0a92  fe 19      CPI A, 19                  ; Limit level value with 25
    0a94  f2 02 0b   JP NO_MORE_LEVELS (0b02)

    0a97  32 11 0b   STA CUR_LEVEL (0b11)       ; Save the level

    0a9a  2a 5a 05   LHLD CUR_MAP_PTR (055a)    ; Advance map pointer to the next level (by 60*20/2=600 bytes)
    0a9d  11 58 02   LXI DE, 0258
    0aa0  19         DAD DE
    0aa1  22 5a 05   SHLD CUR_MAP_PTR (055a)

    0aa4  0e 07      MVI C, 07                  ; Generate a beep
    0aa6  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0aa9  c3 d1 09   JMP NEW_MAP (09d1)

????:
0aac  21 0a 05   LXI HL, PLAYER_POS_STR (050a)
0aaf  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
0ab2  cd 21 f8   CALL f821
0ab5  fe 70      CPI A, 70
0ab7  ca e0 0a   JZ PLAYER_DIE (0ae0)
0aba  21 17 05   LXI HL, ENEMY1_POS_STR + 2 (0517)
0abd  11 0b 00   LXI DE, 000b
0ac0  3a 09 05   LDA ENEMIES_COUNT (0509)
0ac3  3d         DCR A
0ac4  4f         MOV C, A
????:
0ac5  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)
0ac8  be         CMP M
0ac9  c2 d8 0a   JNZ 0ad8
0acc  23         INX HL
0acd  3a 0d 05   LDA PLAYER_POS_STR + 3 (050d)
0ad0  be         CMP M
0ad1  c2 d7 0a   JNZ 0ad7
0ad4  c3 e0 0a   JMP PLAYER_DIE (0ae0)
????:
0ad7  2b         DCX HL
????:
0ad8  19         DAD DE
0ad9  0d         DCR C
0ada  c2 c5 0a   JNZ 0ac5
0add  c3 40 0a   JMP 0a40


; Handle player death
; The function decrements the lives counter, and restarts the map if player has more lives
PLAYER_DIE:
    0ae0  06 00      MVI B, 00

    0ae2  3a 17 0b   LDA LIVES_COUNT (0b17)     ; Decrement lives counter
    0ae5  3d         DCR A
    0ae6  80         ADD B
    0ae7  32 17 0b   STA LIVES_COUNT (0b17)

    0aea  0e 07      MVI C, 07                  ; Generate beep
    0aec  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0aef  0e 07      MVI C, 07                  ; One more beep
    0af1  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0af4  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for a key press

    0af7  3a 17 0b   LDA LIVES_COUNT (0b17)     ; If counter reaches zero - restart the whole game
    0afa  fe 00      CPI A, 00
    0afc  ca a9 09   JZ REAL_START (09a9)

    0aff  c3 d1 09   JMP NEW_MAP (09d1)         ; If player has more lives - restart the level

NO_MORE_LEVELS:
    0b02  21 9a 06   LXI HL, EXIT_STR (069a)    ; Print Exit string
    0b05  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0b08  cd 1b f8   CALL MONITOR_SCAN_KBD (f81b)   ; Wait for a key press
    0b0b  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)

    0b0e  c3 d1 09   JMP NEW_MAP (09d1)         ; Restart the map (BUG? Shall it just exit to monitor)


CUR_LEVEL:
    0b11  01                                    ; Current difficulty level

????:
0b12 00 00   LXI BC, 0000
0b14  00         NOP
????:
0b15  ce 00      ACI A, 00

LIVES_COUNT:
    0b17  00         NOP                        ; Number of lives till the game over

MAP_01:
    0b18  50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 05
    0b36  50 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 05
    0b54  50 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 05
    0b72  50 a0 00 00 00 00 00 20 99 99 99 99 99 99 99 99 90 00 00 00 20 00 00 00 02 00 00 00 0a 05
    0b90  50 a0 00 55 55 55 45 55 00 00 00 00 00 00 00 00 01 55 55 55 55 55 55 55 55 55 55 55 0a 05
    0bae  50 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 0a 05
    0bcc  50 a0 00 00 00 00 00 00 20 00 00 00 00 00 02 00 01 00 00 00 00 00 20 00 06 00 20 00 0a 05
    0bea  50 a0 00 00 00 00 05 55 55 54 55 55 15 55 55 55 55 55 55 45 15 55 55 55 55 55 55 55 0a 05
    0c08  50 a0 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 0a 05
    0c26  50 a0 00 00 20 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 10 00 20 00 00 00 20 00 0a 05
    0c44  50 a0 00 55 55 51 00 00 00 00 55 55 55 55 55 51 00 00 00 00 55 55 55 55 15 55 55 55 0a 05
    0c62  50 a0 00 00 00 01 00 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00 00 10 00 00 00 0a 05
    0c80  50 a0 00 00 00 01 00 02 00 00 00 00 00 00 20 01 00 70 00 00 20 00 00 00 10 00 20 00 0a 05
    0c9e  50 a0 00 00 00 05 55 55 55 00 00 00 15 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 0a 05
    0cbc  50 a0 00 00 00 00 00 00 00 00 00 00 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 05
    0cda  50 a0 00 00 00 00 00 60 00 00 00 00 10 00 00 00 00 00 00 00 00 20 00 00 00 00 20 00 0a 05
    0cf8  50 a0 15 55 55 55 55 55 55 55 55 55 50 00 00 00 00 00 00 05 55 55 55 51 55 55 55 55 0a 05
    0d16  50 a0 10 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 00 0a 05
    0d34  50 a0 10 00 00 00 00 00 00 20 00 00 00 00 00 20 00 00 00 00 20 00 00 01 00 00 00 00 0a 05
    0d52  55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55

MAP_02:
    0d70  50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05
    0d8e  50 00 55 55 55 55 55 55 55 55 55 55 55 51 55 55 55 55 55 55 45 55 55 55 55 55 55 55 55 15
    0dac  50 00 00 00 00 00 00 00 00 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 15
    0dca  50 00 55 55 55 55 55 55 55 45 55 55 55 55 55 55 55 55 51 55 55 55 55 55 55 55 55 55 55 15
    0de8  50 00 50 00 00 00 00 00 52 00 00 00 00 06 00 00 00 00 51 00 00 00 00 00 00 00 00 00 05 15
    0e06  50 00 50 05 55 55 55 51 55 45 55 55 55 55 55 51 55 55 51 55 55 55 55 55 55 55 55 55 55 15
    0e24  50 02 50 25 00 00 00 01 50 00 00 00 00 00 00 01 00 00 01 00 00 00 00 00 00 00 00 00 05 15
    0e42  50 00 50 05 15 55 55 55 55 55 55 55 55 55 55 51 55 55 55 55 55 55 55 55 55 55 55 55 55 15
    0e60  50 00 50 05 10 00 20 00 00 00 20 00 50 00 00 01 00 00 00 00 00 00 00 00 02 00 00 00 05 15
    0e7e  50 00 55 55 55 55 55 55 55 55 55 51 55 55 55 51 55 55 55 55 54 55 55 55 55 55 55 55 55 15
    0e9c  50 00 00 00 00 00 06 00 00 00 00 01 00 07 00 01 00 00 00 00 06 00 00 00 00 00 00 00 05 15
    0eba  55 55 55 55 15 55 55 55 55 54 55 51 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 15
    0ed8  50 00 00 00 10 00 00 00 50 00 00 01 50 00 00 00 00 06 00 00 00 00 00 02 00 00 00 00 05 15
    0ef6  51 55 55 55 55 55 55 51 55 54 55 51 50 00 15 55 55 55 55 55 55 10 00 55 55 45 55 15 15 15
    0f14  51 00 00 00 00 00 20 01 50 00 02 01 50 00 10 00 02 00 00 20 00 10 00 50 00 00 00 15 15 15
    0f32  55 55 55 55 15 55 55 55 55 54 55 51 50 00 15 55 55 55 55 55 55 10 00 50 00 55 55 55 15 15
    0f50  50 00 00 00 10 00 00 00 50 00 00 01 50 00 50 00 00 00 20 00 00 10 00 50 20 00 00 05 15 15
    0f6e  51 55 55 55 55 55 55 51 55 54 55 51 50 00 15 55 55 55 55 55 55 10 00 55 55 55 55 55 15 15
    0f8c  51 00 02 00 00 00 00 01 50 20 00 01 50 00 10 00 00 00 00 00 00 10 00 00 00 00 00 00 10 15
    0faa  55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55

MAP_03:
    0fc8  50 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 a0 05
    0fe6  50 00 00 00 60 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 a0 05
    1004  50 01 55 55 55 55 55 55 55 50 00 00 00 00 00 00 00 60 00 00 00 00 00 00 00 00 00 99 10 05
    1022  50 01 55 00 50 00 20 00 02 09 99 00 00 00 00 13 33 33 33 00 00 00 00 00 00 00 20 00 10 05
    1040  50 01 55 00 50 05 55 54 55 50 05 55 55 00 00 10 00 00 00 00 00 00 00 15 55 45 55 00 10 05
    105e  50 01 55 00 50 00 00 20 00 00 05 52 55 00 00 19 99 91 03 33 33 30 00 10 00 00 00 00 10 05
    107c  50 01 55 00 50 05 55 55 55 50 05 55 55 00 00 00 00 01 00 00 03 20 00 10 00 00 00 00 10 05
    109a  50 01 55 00 50 05 00 00 20 00 00 00 00 00 00 00 00 01 02 00 03 33 33 33 00 00 99 99 10 05
    10b8  50 01 55 20 50 05 00 55 55 50 00 00 00 99 09 99 99 91 05 51 00 00 00 00 00 01 00 00 10 05
    10d6  50 01 33 33 30 05 00 00 00 09 99 99 00 00 10 00 00 00 00 01 00 00 09 99 99 91 00 00 10 05
    10f4  50 01 00 60 00 00 00 00 00 00 00 00 00 00 10 00 26 20 00 01 99 99 99 00 00 01 00 00 10 05
    1112  50 01 33 53 33 55 35 53 33 50 00 00 00 00 10 05 55 55 10 00 00 00 02 00 00 01 00 00 10 05
    1130  50 01 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 19 99 99 00 00 00 00 00 00 00 10 05
    114e  50 01 00 55 55 45 55 45 55 50 00 02 00 00 10 00 00 00 00 00 00 10 00 00 00 00 00 00 33 05
    116c  50 01 00 20 05 20 00 25 00 20 05 05 05 00 55 55 55 55 55 44 55 55 55 55 55 10 00 00 00 05
    118a  50 01 00 55 55 45 55 45 55 51 00 50 40 00 55 55 55 55 55 44 55 55 55 55 55 10 00 00 00 25
    11a8  50 01 00 00 00 00 00 00 00 01 00 00 00 00 55 50 02 00 55 44 55 00 20 05 55 10 00 00 00 55
    11c6  50 01 33 33 33 53 33 33 53 30 00 00 00 00 55 55 55 55 55 44 55 55 55 55 55 10 00 00 00 05
    11e4  50 01 00 00 00 00 00 00 00 00 00 00 70 00 00 00 00 00 00 00 00 00 00 00 00 10 00 00 00 05
    1202  55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55

MAP_04:
    1220  50 00 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 00 05
    123e  50 00 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 00 05
    125c  50 00 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 00 05
    127a  50 00 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 0a 00 05
    1298  50 00 a0 00 19 99 99 99 99 00 99 99 99 99 99 99 99 99 99 99 90 09 99 99 99 91 00 0a 00 05
    12b6  50 00 a0 00 10 00 00 00 00 00 10 00 00 00 00 20 00 00 00 00 10 00 00 00 00 01 00 0a 00 05
    12d4  50 00 a0 00 10 00 02 00 00 00 10 00 00 00 20 00 20 00 00 00 10 00 00 00 00 01 00 0a 00 05
    12f2  50 00 a0 00 10 00 00 00 00 00 10 55 55 45 55 45 55 45 55 50 10 00 00 00 00 01 00 0a 00 05
    1310  50 00 a0 00 10 00 00 00 09 99 10 00 00 20 00 00 00 20 00 00 19 99 00 00 00 01 00 0a 00 05
    132e  50 00 a0 00 10 00 00 00 00 00 00 00 55 55 55 45 55 55 50 00 00 00 00 00 00 01 00 0a 00 05
    134c  50 00 a0 00 19 99 99 00 20 00 00 00 00 60 20 00 20 60 00 00 00 02 00 99 99 91 00 0a 00 05
    136a  50 00 a0 00 00 00 01 55 55 10 00 00 00 55 55 45 55 50 00 00 01 55 55 10 00 00 00 0a 00 05
    1388  50 00 a0 02 00 00 01 20 00 10 00 00 00 00 20 00 20 00 00 00 01 00 02 10 00 00 00 0a 00 05
    13a6  50 00 a0 00 00 01 55 55 55 55 10 00 00 00 55 45 50 00 00 01 55 55 55 55 10 00 00 0a 00 05
    13c4  50 00 a0 00 00 01 00 00 00 20 10 00 00 00 00 00 00 00 00 01 02 00 00 00 10 00 00 0a 00 05
    13e2  50 00 a0 00 01 55 55 55 55 55 55 10 00 00 00 00 00 00 01 55 55 55 55 55 55 10 00 0a 00 05
    1400  50 00 a0 00 01 02 00 00 00 00 00 10 00 00 00 00 00 00 01 00 00 00 00 00 20 10 00 0a 00 05
    141e  50 00 a0 01 55 55 55 55 55 55 55 55 10 00 00 00 00 01 55 55 55 55 55 55 55 55 10 0a 00 05
    143c  50 00 a0 01 00 02 00 00 20 02 06 00 10 00 00 70 00 01 00 60 20 00 02 00 00 20 10 0a 00 05
    145a  55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55 55

; The Lode Runner game
;
; This is a classic Lode Runner game. The goal of the game is to collect all treasures in the labyrinth, and
; not get caught by an enemy. The player has ability to burn a brick down left and down right from the player.
; The enemy can get to the pit of the burned block. If the block is restored before the enemy gets freed from
; the trap, the enemy dies and respawns.
;
; The game does not have any back buffer - all the game information is stored right in the video buffer. In 
; order to check whether the player or enemy can move to the next cell, the game reads a symbol from the 
; target position in the video buffer. On one hand this simplifies the implementation, on the other hand
; it causes using escape strings to position the cursor at a certain screen positions just to read its char.
;
; Overall the implementation is pretty straightforward and does not use any unnatural hacks.

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

MOVE_TO_SCORE_STR:
    0046  1b 59 37 29 00            db 0x1b, 0x59, 0x37, 0x29, 0x00 ; Move cursor to (9, 23)

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
; - 0x03    - solid block (can't be burned)
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
    012f  32 09 05   STA MOBS_COUNT (0509)

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

    0159  21 09 05   LXI HL, MOBS_COUNT (0509)   ; Increment enemies counter ????
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
    0188  3a 09 05   LDA MOBS_COUNT (0509)   ; Get the enemies counter

    018b  fe 05      CPI A, 05                  ; Limit number of enemies to 5
    018d  d2 a9 01   JNC SCAN_BLOCK_EXIT (01a9)

    0190  3c         INR A                      ; Increment number of enemies
    0191  32 09 05   STA MOBS_COUNT (0509)

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


; Check if the symbol under cursor position is a player symbol
; Z flag is set in this case
IS_MOVE_VALID:
    01ad  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821)
    01b0  fe 09      CPI A, 09
    01b2  ca cc 01   JZ IS_EMPTY_EXIT (01cc)

; Check if the symbol under cursor position is a ladder ('#') symbol, or empty block
; Z flag is set in this case
IS_LADDER_OR_EMPTY:
    01b5  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821)
    01b8  fe 23      CPI A, 23
    01ba  ca cc 01   JZ IS_EMPTY_EXIT (01cc)


; Check if the symbol under cursor is empty
; Sets Z flag if the symbol is SP (treasure), ' ' (space), or '^' (rope)
IS_EMPTY:
    01bd  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821)
    01c0  fe 1e      CPI A, 1e
    01c2  ca cc 01   JZ IS_EMPTY_EXIT (01cc)
    01c5  fe 20      CPI A, 20
    01c7  ca cc 01   JZ IS_EMPTY_EXIT (01cc)
    01ca  fe 5e      CPI A, 5e

IS_EMPTY_EXIT:
    01cc  c9         RET



; Handle Mob movements
; 
; The function is responsible for making a move according to previously made decision. The function is
; responsible for handling both player and enemy moves. The player moves are determined by the user input,
; while the enemy moves are calculated by the HANDLE_ENEMY function.
;
; The function iterates over the mob list (player + enemies), and performs the following actions for each mob:
; - All changes are pefrormed on a working copy of the item. This allows dropping changes if needed, and proceed
;   to the new item
; - Function moves the player on every game tick, while the enemy skips every 3rd tick (so that the enemy is
;   slightly slower than the player)
; - Handle mob falling down, unless mob is on a ladder, or on a rope, or the enemy just escaped from a pit
; - Calculate new position of the mob, as well as related variables
; - Check if the new position is a valid move, if not - revert changes
; - Actually apply calculated move, update screen as needed
; - Copy changes back from the working copy to the main moblist
HANDLE_MOVES:
    01cd  21 0a 05   LXI HL, PLAYER_POS_STR (050a)  ; Load the pointer to mobs array
    01d0  3a 09 05   LDA MOBS_COUNT (0509)          ; Load number of mobs in the array

HANDLE_MOVES_LOOP:
    01d3  32 57 05   STA MOB_COUNTER (0557)         ; Save the counter till the next iteration

    01d6  22 58 05   SHLD CUR_MOB_PTR (0558)        ; Save pointer to the currently processed mob

    01d9  11 4c 05   LXI DE, CUR_MOB (054c)         ; Copy current mob to the CUR_MOB structure
    01dc  06 0b      MVI B, 0b                      ; 11 - number of bytes to copy

HANDLE_MOVES_COPY_2_WORK_BUF:
    01de  7e         MOV A, M                       ; Copy the next byte
    01df  12         STAX DE

    01e0  23         INX HL                         ; Advance pointers
    01e1  13         INX DE

    01e2  05         DCR B                          ; Repeat until all bytes are copied
    01e3  c2 de 01   JNZ HANDLE_MOVES_COPY_2_WORK_BUF (01de)

    01e6  3a 54 05   LDA CUR_MOB + 8 (0554)         ; Wait counter is 1? Perhaps the enemy gets out of the pit.
    01e9  fe 01      CPI A, 01                      ; In this case skip move preparation step to avoid failling
    01eb  ca 4b 02   JZ DO_MOVE (024b)              ; to the pit again. Just go and move the enemy

    01ee  f2 90 03   JP MOB_MOVE_EXIT (0390)        ; Waiting counter is not due? Skip the move


    01f1  3a 53 05   LDA CUR_MOB + 7 (0553)         ; Mob+7 variable is responsible for skipping every 3rd tick
    01f4  fe ff      CPI A, ff                      ; for enemies. The player has this value set to 0xff which
    01f6  ca 0a 02   JZ PREPARE_MOVE (020a)         ; performs move every tick.

    01f9  fe 00      CPI A, 00                      ; Check if the enemy skip move counter is due
    01fb  c2 06 02   JNZ SLOW_DOWN_ENEMY (0206)

    01fe  3e 02      MVI A, 02                      ; Restart skip move timer
    0200  32 53 05   STA CUR_MOB + 7 (0553)

    0203  c3 90 03   JMP MOB_MOVE_EXIT (0390)       ; Skip the move

SLOW_DOWN_ENEMY:
    0206  3d         DCR A                          ; Decrement skip move timer
    0207  32 53 05   STA CUR_MOB + 7 (0553)


; Prepare an upcoming move
;
; This piece of code checks the block below the mob. Unless the mob is on a ladder or on a rope, if
; the block below is empty, the mob starts falling down.
; 
; This piece of code is not executed if an enemy has just escaped from a pit (to avoid falling into the
; trap again)
PREPARE_MOVE:
    020a  3a 55 05   LDA CUR_MOB + 9 (0555)     ; Compare backing symbol with '#' (ladder)
    020d  fe 23      CPI A, 23
    020f  ca 4b 02   JZ DO_MOVE (024b)

    0212  fe 5e      CPI A, 5e                  ; Compare with '^' (rope)
    0214  ca 4b 02   JZ DO_MOVE (024b)

    0217  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Move cursor to the current mob coordinate
    021a  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    021d  0e 1a      MVI C, 1a                  ; Then move down to look what is the block below
    021f  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0222  cd bd 01   CALL IS_EMPTY (01bd)       ; If the block below is empty (or rope, or a treasure) start
    0225  ca b0 02   JZ HANDLE_FALL_DOWN (02b0) ; falling

    0228  fe 70      CPI A, 70                  ; Check if the block below is a floor. It potentially can be
    022a  c2 4b 02   JNZ 024b                   ; a broken floor

    022d  2a 51 05   LHLD CUR_MOB + 5 (0551)    ; To check if the floor is broken, get the map pointer

    0230  01 1e 00   LXI BC, 001e               ; Adjust the pointer to the row below
    0233  09         DAD BC

    0234  3a 4f 05   LDA CUR_MOB_CURSOR_STR + 3 (054f)  ; The map byte represents 2 blocks on the screen
    0237  e6 01      ANI A, 01                          ; Select which one, upper nibble, or lower nibble
    0239  fe 00      CPI A, 00
    023b  c2 43 02   JNZ PREPARE_MOVE_1 (0243)

    023e  3e 30      MVI A, 30                  ; Will compare upper nibble with broken floor block type
    0240  c3 45 02   JMP PREPARE_MOVE_2 (0245)

PREPARE_MOVE_1:
    0243  3e 03      MVI A, 03                  ; Will compare lower nibble with broken floor block type

PREPARE_MOVE_2:
    0245  a6         ANA M                      ; Check if the block below is solid
    0246  fe 00      CPI A, 00                  ; If not - we are falling
    0248  ca b0 02   JZ HANDLE_FALL_DOWN (02b0)


; Perform the move for the mob
; 
; This piece of code is responsible for doing the move. The move direction for the player is based on
; the user's input. The enemy movement direction shall be previously calculated by the HANDLE_ENEMY function.
; 
; The movement direction is a up/down/left/right key code stored in the mob's 11th byte (mob struct + 10).
; Despite the function name, the code is another movement preparation step. It responsible for calculating a
; few constants used for actual movement:
; - Symbol to move cursor in forward direction, as well as reverse direction if needed
; - String to move character to the new position
; - Offset to the new position in the map source
; - Coordinate increment value
DO_MOVE:
    024b  3a 56 05   LDA CUR_MOB + 10 (0556)    ; Load the mob movement type (or key pressed by Player)

    024e  fe 1a      CPI A, 1a                  ; Check if this is down key
    0250  ca f1 02   JZ HANDLE_DOWN_KEY (02f1)

    0253  fe 19      CPI A, 19                  ; Check if this is up key
    0255  ca d1 02   JZ HANDLE_UP_KEY (02d1)

    0258  fe 08      CPI A, 08                  ; Check if this is a left key
    025a  ca 84 02   JZ HANDLE_LEFT_KEY (0284)

    025d  fe 18      CPI A, 18                  ; Check if this is a right key
    025f  c2 90 03   JNZ MOB_MOVE_EXIT (0390)   ; Skip all other move commands

HANDLE_RIGHT_KEY:
    0262  06 08      MVI B, 08                  ; Move left (reverse move)
    0264  3e 18      MVI A, 18                  ; Move right (forward move)
    0266  32 8b 04   STA MOB_MOVE_DIRECTION (048b)

    0269  21 1c 00   LXI HL, RIGHT_STR (001c)   ; Prepare pointer to the movement string
    026c  22 8c 04   SHLD MOB_MOVE_STR (048c)

    026f  3e 01      MVI A, 01                  ; Will be incrementing X coordinate
    0271  32 90 04   STA COORD_INC_DEC (0490)

    0274  3a 4f 05   LDA CUR_MOB_CURSOR_STR + 3 (054f)  ; Even positions do not require advancing the map pointer
    0277  e6 01      ANI A, 01                          ; as each byte represent 2 screen positions
    0279  fe 00      CPI A, 00
    027b  ca a4 02   JZ HANDLE_HORZ_MOVE (02a4)

    027e  11 01 00   LXI DE, 0001               ; Advance map pointer on even positions
    0281  c3 a7 02   JMP HANDLE_HORZ_MOVE_1 (02a7)

HANDLE_LEFT_KEY:
    0284  06 18      MVI B, 18                  ; Move right (reverse move)
    0286  3e 08      MVI A, 08                  ; Move left (forward move)
    0288  32 8b 04   STA MOB_MOVE_DIRECTION (048b)

    028b  21 1a 00   LXI HL, LEFT_STR (001a)    ; Prepare pointer to the movement string
    028e  22 8c 04   SHLD MOB_MOVE_STR (048c)

    0291  3e ff      MVI A, ff                  ; Will be decrementing X coordinate
    0293  32 90 04   STA COORD_INC_DEC (0490)

    0296  3a 4f 05   LDA CUR_MOB_CURSOR_STR + 3 (054f)  ; Even positions do not require adjusting map pointer
    0299  e6 01      ANI A, 01                          ; as each map byte represent 2 screen positions
    029b  c2 a4 02   JNZ HANDLE_HORZ_MOVE (02a4)

    029e  11 ff ff   LXI DE, ffff               ; Move to the previous map byte
    02a1  c3 a7 02   JMP HANDLE_HORZ_MOVE_1 (02a7)

HANDLE_HORZ_MOVE:
    02a4  11 00 00   LXI DE, 0000               ; Do not move map pointer

HANDLE_HORZ_MOVE_1:
    02a7  21 4f 05   LXI HL, CUR_MOB_CURSOR_STR + 3 (054f)  ; Load the X coordinate address to be incremented
    02aa  22 8e 04   SHLD COORD_PTR (048e)                  ; or decremented

    02ad  c3 0c 03   JMP TRY_MOVE (030c)

; Handle mob falling down
HANDLE_FALL_DOWN:   
    02b0  06 19      MVI B, 19                  ; Move up (reverse move)
    02b2  3e 1a      MVI A, 1a                  ; Move down (forward move)
    02b4  32 8b 04   STA MOB_MOVE_DIRECTION (048b)

    02b7  21 17 00   LXI HL, DOWN_STR (0017)    ; Prepare pointer to the movement string
    02ba  22 8c 04   SHLD MOB_MOVE_STR (048c)

    02bd  21 4e 05   LXI HL, CUR_MOB_CURSOR_STR + 2 (054e)  ; Will be incrementing Y coordinate
    02c0  22 8e 04   SHLD COORD_PTR (048e)

    02c3  3e 01      MVI A, 01                  ; Will increment Y coordinate by 1
    02c5  32 90 04   STA COORD_INC_DEC (0490)

    02c8  11 1e 00   LXI DE, 001e               ; +30 offset in map source (+60 screen positions)

    02cb  cd b5 01   CALL IS_LADDER_OR_EMPTY (01b5) ; Check if the mob reached a solid surface
    02ce  c3 1f 03   JMP SUBMIT_MOVE (031f)

HANDLE_UP_KEY:
    02d1  3a 55 05   LDA CUR_MOB + 9 (0555)     ; Check the block type at mob position

    02d4  fe 23      CPI A, 23                  ; Can move up only on ladders
    02d6  c2 90 03   JNZ MOB_MOVE_EXIT (0390)

    02d9  06 1a      MVI B, 1a                  ; Move down (reverse move)
    02db  3e 19      MVI A, 19                  ; Move up (forward move)
    02dd  32 8b 04   STA MOB_MOVE_DIRECTION (048b)

    02e0  21 14 00   LXI HL, UP_STR (0014)      ; Prepare pointer to the movement string
    02e3  22 8c 04   SHLD MOB_MOVE_STR (048c)

    02e6  3e ff      MVI A, ff                  ; Will be decrementing Y coordinate
    02e8  32 90 04   STA COORD_INC_DEC (0490)

    02eb  11 e2 ff   LXI DE, ffe2               ; -30 offset in map pointer (-60 positions)
    02ee  c3 06 03   JMP HANDLE_VERT_MOVE (0306)

HANDLE_DOWN_KEY:
    02f1  06 19      MVI B, 19                  ; Move up code (reverse movement)
    02f3  3e 1a      MVI A, 1a                  ; Move down dode (forward movement)
    02f5  32 8b 04   STA MOB_MOVE_DIRECTION (048b)

    02f8  21 17 00   LXI HL, DOWN_STR (0017)    ; Prepare movement string pointer
    02fb  22 8c 04   SHLD MOB_MOVE_STR (048c)

    02fe  3e 01      MVI A, 01                  ; Will be incrementing Y coordinate
    0300  32 90 04   STA COORD_INC_DEC (0490)

    0303  11 1e 00   LXI DE, 001e               ; +30 offset in map source (+60 screen positions)

HANDLE_VERT_MOVE:
    0306  21 4e 05   LXI HL, CUR_MOB_CURSOR_STR + 2 (054e)  ; Load Y coordinate address to be incremented
    0309  22 8e 04   SHLD COORD_PTR (048e)                  ; or decremented


; Try applying moving variables and parameters are prepared.
; The function checks whether this is a valid move
TRY_MOVE:
    030c  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Move cursor to the current mob position
    030f  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0312  3a 8b 04   LDA MOB_MOVE_DIRECTION (048b)  ; Move the cursor according to the move code
    0315  4f         MOV C, A
    0316  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0319  cd ad 01   CALL IS_MOVE_VALID (01ad)      ; Check if the mob moved to valid position.
    031c  c2 90 03   JNZ MOB_MOVE_EXIT (0390)       ; If not - just ignore the move (it has not happen yet)


; Move is valid, update the mob structure, as well as draw needed changes on the screen
;
; The function restores char at previous mob position, and draw it at the new position.
; Coordinate changes are applied in the mob structure.
SUBMIT_MOVE:
    031f  21 55 05   LXI HL, CUR_MOB + 9 (0555)     ; Get pointer to the char under the mob

    0322  48         MOV C, B                       ; Apply reverse movement (back to the mob position)
    0323  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0326  4e         MOV C, M                       ; Restore character under the mob
    0327  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    032a  32 55 05   STA CUR_MOB + 9 (0555)         ; Remember the char at the new position (A filled in IS_MOVE_VALID)

    032d  2a 8c 04   LHLD MOB_MOVE_STR (048c)       ; Move cursor to the target position again
    0330  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0333  0e 09      MVI C, 09                      ; Draw the player/enemy character at the target position
    0335  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0338  2a 8e 04   LHLD COORD_PTR (048e)          ; Load mob coordinate pointer to increment/decrement
    033b  3a 90 04   LDA COORD_INC_DEC (0490)       ; Load increment/decrement flag

    033e  86         ADD M                          ; Apply coordinate increment/decrement
    033f  77         MOV M, A

    0340  2a 51 05   LHLD CUR_MOB + 5 (0551)        ; Apply the map pointer offset
    0343  19         DAD DE
    0344  22 51 05   SHLD CUR_MOB + 5 (0551)

    0347  3a 55 05   LDA CUR_MOB + 9 (0555)         ; Check if the mob backing char is a player/enemy char
    034a  fe 09      CPI A, 09
    034c  c2 90 03   JNZ MOB_MOVE_EXIT (0390)       ; If no collision detected - we are done

; Handle Enemy over another enemy case 
; 
; When a mob is moved to a position, a background character is saved in the mob's backing character field.
; If an enemy is moved to the position occupied by another enemy, backing character will be a 0x09 (enemy)
; symbol. If this enemy will move forward it may produce an artifact on a screen when the backing character
; is copied back to the screen. 
;
; The following piece of code detects this situation, searches the previous mob, and uses its backing character
; to avoid spontaneous multiplying enemy symbols on the screen.
FIX_ENEMY_BACK_CHAR:
    034f  21 0c 05   LXI HL, PLAYER_POS_STR + 2 (050c)  ; Iterate over mob positions
    0352  11 13 05   LXI DE, PLAYER_STRUCT + 9 (0513)   ; and backing chars
    
    0355  01 0b 00   LXI BC, 000b                       ; Mob structure size

    0358  3a 09 05   LDA MOBS_COUNT (0509)              ; Iterate over all the mobs
    035b  32 8b 04   STA MOB_MOVE_DIRECTION (048b)

FIX_ENEMY_BACK_CHAR_LOOP:
    035e  3a 4e 05   LDA CUR_MOB_CURSOR_STR + 2 (054e)  ; Compare new mob Y position with iterated mob pos
    0361  be         CMP M
    0362  c2 7d 03   JNZ FIX_ENEMY_BACK_CHAR_2 (037d)

    0365  23         INX HL                             ; Compare X coordinate as well
    0366  3a 4f 05   LDA CUR_MOB_CURSOR_STR + 3 (054f)
    0369  be         CMP M
    036a  c2 7c 03   JNZ FIX_ENEMY_BACK_CHAR_1 (037c)

    036d  2b         DCX HL                     ; Load mob backing char
    036e  eb         XCHG
    036f  7e         MOV A, M
    0370  eb         XCHG

    0371  fe 09      CPI A, 09                  ; Ensure this is a player/enemy char
    0373  ca 7d 03   JZ FIX_ENEMY_BACK_CHAR_2 (037d)

    0376  32 55 05   STA CUR_MOB + 9 (0555)     ; Set previous mob's backing char as current mob's backing char
    0379  c3 90 03   JMP MOB_MOVE_EXIT (0390)

FIX_ENEMY_BACK_CHAR_1:
    037c  2b         DCX HL                     ; Restore previous HL pointer

FIX_ENEMY_BACK_CHAR_2:
    037d  09         DAD BC                     ; Advance to the next mob
    037e  eb         XCHG
    037f  09         DAD BC
    0380  eb         XCHG

    0381  3a 8b 04   LDA MOB_MOVE_DIRECTION (048b)  ; Decrement mob counter
    0384  3d         DCR A

    0385  fe 00      CPI A, 00                      ; Stop when all mobs are processed
    0387  ca 90 03   JZ MOB_MOVE_EXIT (0390)

    038a  32 8b 04   STA MOB_MOVE_DIRECTION (048b)  ; Reset movement flag

    038d  c3 5e 03   JMP FIX_ENEMY_BACK_CHAR_LOOP (035e)    ; Continue for the next mob


; When mob changes are done we need to move working copy back to the main mob list
MOB_MOVE_EXIT:
    0390  2a 58 05   LHLD CUR_MOB_PTR (0558)    ; Copy the mob record back to the mob array
    0393  11 4c 05   LXI DE, CUR_MOB (054c)
    0396  06 0b      MVI B, 0b                  ; 11 bytes to copy

MOB_MOVE_EXIT_LOOP:
    0398  1a         LDAX DE                    ; Copy the next byte
    0399  77         MOV M, A

    039a  23         INX HL                     ; Advance pointers
    039b  13         INX DE

    039c  05         DCR B                      ; Repeat until all bytes are copied
    039d  c2 98 03   JNZ MOB_MOVE_EXIT_LOOP (0398)

    03a0  3a 57 05   LDA MOB_COUNTER (0557)     ; Decrement the mobs counter, and repeat until all
    03a3  3d         DCR A                      ; mobs are processed
    03a4  c2 d3 01   JNZ HANDLE_MOVES_LOOP (01d3)

    03a7  c9         RET



; Handle player gets a treasure
;
; The function checks if the player reaches a treasure. In case if symbol under the player is a treasure,
; the remaining treasures counter is decremented, score is advanced by 1000, and printed on the screen
HANDLE_TREASURE:
    03a8  3a 13 05   LDA PLAYER_STRUCT + 9 (0513)   ; Check the symbol under the player
    03ab  fe 1e      CPI A, 1e                      ; Nothing to do if is not a treasure (0x1e)
    03ad  c0         RNZ

    03ae  3e 20      MVI A, 20                  ; Replace symbol under the player to space (swallow treasure)
    03b0  32 13 05   STA PLAYER_STRUCT + 9 (0513)

    03b3  2a 89 04   LHLD NUM_TREASURES (0489)  ; Decrement number of remaining treasures
    03b6  2b         DCX HL
    03b7  22 89 04   SHLD NUM_TREASURES (0489)

    03ba  21 87 04   LXI HL, SCORE + 2 (0487)   ; Add 1000 to the score starting from the 3rd byte, moving
    03bd  06 03      MVI B, 03                  ; backwards (4th byte remains untouched)
    03bf  3e 10      MVI A, 10                  

    03c1  37         STC                        ; Clear C flag
    03c2  3f         CMC

HANDLE_TREASURE_SCORE_LOOP:
    03c3  8e         ADC M                      ; Add the byte to the score
    03c4  27         DAA
    03c5  77         MOV M, A

    03c6  3e 00      MVI A, 00                  ; Prepare for adding the next byte

    03c8  2b         DCX HL                     ; Move to the next byte, decrease the counter
    03c9  05         DCR B
    03ca  c2 c3 03   JNZ HANDLE_TREASURE_SCORE_LOOP (03c3)

    03cd  21 46 00   LXI HL, MOVE_TO_SCORE_STR (0046)   ; Prepare for printing score, move cursor
    03d0  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    03d3  06 04      MVI B, 04                  ; Print 4 bytes of score
    03d5  21 85 04   LXI HL, SCORE (0485)

HANDLE_TREASURE_PRINT_LOOP:
    03d8  7e         MOV A, M                   ; Print the next score byte
    03d9  cd 15 f8   CALL MONITOR_PRINT_BYTE_HEX (f815)

    03dc  23         INX HL                     ; Repeat for all 4 bytes
    03dd  05         DCR B
    03de  c2 d8 03   JNZ HANDLE_TREASURE_PRINT_LOOP (03d8)

    03e1  c9         RET                        ; Done



; Handle burned bricks
;
; The function is responsible for handling the following features:
; - If user presses burn left or right buttons, burn the block if possible.
; - Check if burned block timer counter is expired, and restore the block when time comes
;
; The function algorithm:
; - Scan through the burned bricks array and decrement timer counters
; - If a timer is due, restore the burned brick
; - Check if the player has pressed burn left or right keys. If yes:
;   - Burn is allowed if left/right to the player is space or a rope (burn not allowed if the player is
;     next to a wall or a ladder). The function also checks the char below - only bricks are allowed to burn
;   - The function creates a new record in the beginning of the burned bricks array. The record is initialized
;     with timer value of 50, and coordinates of the burned brick. The function is using a backup array to
;     shift existing records by 1 record further.
HANDLE_BRICKS:
    03e2  21 cd 04   LXI HL, BURNED_BRICKS (04cd)   ; First let's scan through the burned bricks array
    03e5  01 03 00   LXI BC, 0003                   ; Every record is 3 bytes

HANDLE_BRICKS_TIMERS_LOOP:
    03e8  7e         MOV A, M                       ; The first byte of each record is a timer
    03e9  fe 00      CPI A, 00                      ; Zero means the record (and further records) is empty
    03eb  ca 12 04   JZ HANDLE_BRICKS_PLAYER (0412) ; Process player inputs, whether they burn another block

    03ee  fe 01      CPI A, 01                      ; Value of 1 means that the timer is due
    03f0  ca f8 03   JZ HANDLE_BRICKS_RESTORE (03f8)

    03f3  35         DCR M                          ; If the timer is not due - decrement the timer counter

    03f4  09         DAD BC                         ; And advance to the next record
    03f5  c3 e8 03   JMP HANDLE_BRICKS_TIMERS_LOOP (03e8)

HANDLE_BRICKS_RESTORE:
    03f8  35         DCR M                          ; Zero the record

    03f9  23         INX HL                         ; Advance to coordinate field

    03fa  0e 1b      MVI C, 1b                      ; Move cursor at the burned block coordinate
    03fc  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    03ff  0e 59      MVI C, 59
    0401  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0404  4e         MOV C, M
    0405  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0408  23         INX HL
    0409  4e         MOV C, M
    040a  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    040d  0e 70      MVI C, 70                      ; Restore brick at the cursor
    040f  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)


HANDLE_BRICKS_PLAYER:
    0412  3a 14 05   LDA PLAYER_STRUCT + 10 (0514)  ; Check if player pressed burn right key (clear screen key)
    0415  fe 1f      CPI A, 1f
    0417  c2 25 04   JNZ HANDLE_BRICKS_PLAYER_1 (0425)

    041a  21 0a 05   LXI HL, PLAYER_POS_STR (050a)  ; Move cursor to the player's position
    041d  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0420  0e 18      MVI C, 18                      ; Then move cursor one position right
    0422  c3 30 04   JMP HANDLE_BRICKS_PLAYER_2 (0430)

HANDLE_BRICKS_PLAYER_1:
    0425  fe 0c      CPI A, 0c                      ; Check if player pressed burn left key (Home key)
    0427  c0         RNZ

    0428  21 0a 05   LXI HL, PLAYER_POS_STR (050a)  ; Move cursor to the player's position
    042b  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    042e  0e 08      MVI C, 08                      ; Then move cursor one position left

HANDLE_BRICKS_PLAYER_2:
    0430  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)   ; Print the move char

    0433  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Check the char left/right to the player

    0436  fe 20      CPI A, 20                      ; Burning block is allowed that a space is left/right to the playe
    0438  ca 3e 04   JZ HANDLE_BRICKS_PLAYER_3 (043e)

    043b  fe 5e      CPI A, 5e                      ; ... or a rope
    043d  c0         RNZ

HANDLE_BRICKS_PLAYER_3:
    043e  0e 1a      MVI C, 1a                      ; Move cursor 1 position down
    0440  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0443  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Burn is allowed only for a floor char
    0446  fe 70      CPI A, 70
    0448  c0         RNZ

    0449  21 cd 04   LXI HL, BURNED_BRICKS (04cd)   ; Copy 57 bytes (19 records) from main burned bricks array
    044c  11 91 04   LXI DE, BURNED_BRICKS_BACKUP (0491)    ; to the backup array
    044f  06 39      MVI B, 39

HANDLE_BRICKS_COPY_LOOP1:
    0451  7e         MOV A, M                   ; Copy the next byte
    0452  12         STAX DE

    0453  23         INX HL                     ; Increment pointers
    0454  13         INX DE

    0455  05         DCR B                      ; Repeat until all 57 bytes are copies
    0456  c2 51 04   JNZ HANDLE_BRICKS_COPY_LOOP1 (0451)

    0459  21 cd 04   LXI HL, BURNED_BRICKS (04cd)   ; Burned block will restore in 50 cycles
    045c  36 32      MVI M, 32                  ; (put 50 as a timer value for the first record)

    045e  eb         XCHG                       ; Move record address to DE

    045f  cd 1e f8   CALL MONITOR_GET_CURSOR_POS (f81e) ; Get cursor position (H - Y, L - X)

    0462  3e 1d      MVI A, 1d                  ; Convert Y position to screen coordinates suitable for Esc-Y 
    0464  84         ADD H

    0465  13         INX DE                     ; Store the Y coordinate
    0466  12         STAX DE

    0467  3e 18      MVI A, 18                  ; Convert X position to screen coordinates suitable for Esc-Y
    0469  85         ADD L

    046a  13         INX DE                     ; Store the coordinate
    046b  12         STAX DE

    046c  13         INX DE                     ; Advance to the next record

    046d  21 91 04   LXI HL, BURNED_BRICKS_BACKUP (0491)    ; Copy 57 bytes from backup back to the main table, 
    0470  06 39      MVI B, 39                  ; but shifted by one record (first slot is for the new record)

HANDLE_BRICKS_COPY_LOOP2:
    0472  7e         MOV A, M                   ; Copy the next byte
    0473  12         STAX DE

    0474  23         INX HL                     ; Advance pointers
    0475  13         INX DE

    0476  05         DCR B                      ; Repeat for all 57 bytes
    0477  c2 72 04   JNZ HANDLE_BRICKS_COPY_LOOP2 (0472)

    047a  0e 20      MVI C, 20                  ; Burn the character under cursor (print a space)
    047c  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    047f  3e 00      MVI A, 00                  ; Reset player movement key
    0481  32 14 05   STA PLAYER_STRUCT + 10 (0514)

    0484  c9         RET



SCORE:
    0485  00 02 80 00       db 0x00, 0x00, 0x00, 0x00   ; Game score value

NUM_TREASURES:
    0489  04 00             dw 0000                     ; Number of treasures left on the map

MOB_MOVE_DIRECTION:
    048b  08                db 08                       ; Direction code where to move the mob

MOB_MOVE_STR:
    048c  1a 00             dw 0000                     ; Pointer to a string that moves current mob cursor

COORD_PTR:
    048e  4f 05             dw 0000                     ; Pointer of the mob coordinate to modify

COORD_INC_DEC:
    0490  ff                db 00                       ; 0x01 - increment mob coordinate, 0xff - decrement

BURNED_BRICKS_BACKUP:
    0491  60 * [00]         db  60 * [0x00]             ; Just a free space used while adding a new burned
                                                        ; brick into the main array


BURNED_BRICKS:
    04cd  60 * [00]         db  60 * [0x00]             ; An array of burned bricks. 20 records 3 bytes each.
                                                        ; First byte of each record is a timer, how long to wait
                                                        ; till the block can be restored. Other 2 bytes are screen
                                                        ; coordinates of the burned block


MOBS_COUNT:
    0509  03                db 00                       ; Number of mobs (player + enemies) on the map


; The following is an array of mobs (moving objects - player and enemies). The first record in the array
; represents the player, other records are for enemies (up to 5 on the map).
;
; Each mob in the array represented with the following structure:
; - 5 bytes                 - Escape sequence moving cursor to the MOB position on the screen
; - 2 bytes (mob ptr + 5)   - Pointer to the byte in the map source, that corresponds to the mob position
; - 1 byte (mob ptr + 7)    - timer to skip move on every 3rd tick for enemies (0xff for the player, 0-2 for enemies)
; - 1 byte (mob ptr + 8)    - inactivity timer. User for 2 cases:
;                             - Set to 20 when enemy falls into a pit. The enemy is freed when timer counts
;                               down to 2
;                             - Set to negative value when enemy dies. The enemy is respawned when timer counts
;                               up to 0
;                             - Value of 0 means timer is disabled, the enemy freely moves.
; - 1 byte (mob ptr + 9)    - Character behind the mob (to restore background char when mob moves out)
; - 1 byte (mov ptr + 10)   - Planned mob move (user input for player, calculated move for enemies)
PLAYER_STRUCT:
PLAYER_POS_STR:
    050a  1b 59 33 51 00    db 0x1b, 0x59, 0x33, 0x51, 0x00     ; String that moves cursor to the current player position
    050f  4b 0d             dw 0x0000                           ; Pointer to the map source to the byte representing player pos
    0511  ff                db 0xff                             ; Skip moves counter (0xff - player does not skip moves)
    0512  00                db 00                               ; Inactivity timer - player is always active
    0513  23                db 00                               ; Background char (filled with space on map start)
    0514  08                db 00                               ; Planned move (cleared on map start)

ENEMY1_STRUCT:
ENEMY1_POS_STR:
    0515  1b 59 33 51 00    db 0x1b, 0x59, 0x33, 0x51, 0x00     ; String that moves cursor to the enemy1 screen position
    051a  4b 0d             dw 0x0000                           ; Pointer to the map source to the byte representing enemy pos
    051c  02                db 02                               ; Skip moves counter (0x02 - enemy will skip a move in 2 game ticks)
    051d  f2                db f2                               ; Inactivity timer - ????
    051e  23                db 00                               ; Background char (filled with space on map start)
    051f  18                db 00                               ; Planned move (cleared on map start)

ENEMY2_STRUCT:
    0520  1b 59 2d 53 00    db 0x1b, 0x59, 0x2d, 0x53, 0x00     ; String that moves cursor to the enemy2 screen position
    0525  98 0c             dw 0x0000                           ; Pointer to the map source to the byte representing enemy pos
    0527  01                db 01                               ; Skip moves counter (0x01 - enemy will skip a move in 2 game ticks)
    0528  00                db 00                               ; Inactivity timer - ????
    0529  20                db 00                               ; Background char (filled with space on map start)
    052a  08                db 00                               ; Planned move (cleared on map start)

ENEMY3_STRUCT:
    052b  1b 59 33 37 00    db 0x1b, 0x59, 0x33, 0x37, 0x00     ; String that moves cursor to the enemy3 screen position
    0530  46 14             dw 0x0000                           ; Pointer to the map source to the byte representing enemy pos
    0532  00                db 01                               ; Skip moves counter (0x01 - enemy will skip a move in 2 game ticks)
    0533  00                db 00                               ; Inactivity timer - ????
    0534  20                db 00                               ; Background char (filled with space on map start)
    0535  18                db 00                               ; Planned move (cleared on map start)

ENEMY4_STRUCT:
    0536  1b 59 33 48 00    db 0x1b, 0x59, 0x33, 0x48, 0x00     ; String that moves cursor to the enemy4 screen position
    053b  4f 14             dw 0x0000                           ; Pointer to the map source to the byte representing enemy pos
    053d  01                db 01                               ; Skip moves counter (0x01 - enemy will skip a move in 2 game ticks)
    053e  00                db 00                               ; Inactivity timer - ????
    053f  20                db 00                               ; Background char (filled with space on map start)
    0540  08                db 00                               ; Planned move (cleared on map start)

ENEMY5_STRUCT:
    0541  1b 59 00 00 00    db 0x1b, 0x59, 0x00, 0x00, 0x00     ; String that moves cursor to the enemy5 screen position
    0546  00 00             dw 0x0000                           ; Pointer to the map source to the byte representing enemy pos
    0548  01                db 01                               ; Skip moves counter (0x01 - enemy will skip a move in 2 game ticks)
    0549  00                db 00                               ; Inactivity timer - ????
    054a  20                db 00                               ; Background char (filled with space on map start)
    054b  08                db 00                               ; Planned move (cleared on map start)

; Currently processed moving object (player or enemy)
; A working copy of a mob structure above. Used to make changes, which then are submitted
; to the main mob array, or simply discarded
CUR_MOB:
CUR_MOB_CURSOR_STR:
    054c  1b 59 2d 53 00
    0551  98 0c 01 00 20
    0556  08


MOB_COUNTER:
    0557  01                db 00                       ; Number of mobs in the array to go (local variable)

CUR_MOB_PTR:
    0558  20 05             dw 0000                     ; Pointer to the currently processed mob (local var)

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


; Handle enemy events
;
; This function is responsible for handling enemy events (traps, respawn), as well as planning movements
; based on comparison with Player's position.
;
; The function iterates over the enemies list, and for each enemy performs the following actions:
; - Detect the enemy is in the trap, and start the waiting timer
; - Handle waiting timer to rescue enemy from the trap
; - Compare player's and enemy's position and decide where to move the enemy. This function also handles
;   a case if there is no straight direction from the enemy to the player, so it tries to find a way using
;   left/right moves and use ladders. 
; - ?????
HANDLE_ENEMY:
    071b  21 15 05   LXI HL, ENEMY1_STRUCT (0515)   ; Load the enemies structure array address

    071e  3a 09 05   LDA MOBS_COUNT (0509)      ; Load the enemies count
    0721  3d         DCR A

HANDLE_ENEMY_LOOP:
    0722  32 57 05   STA MOB_COUNTER            ; Store the enemies counter

    0725  22 58 05   SHLD CUR_MOB_PTR (0558)    ; Store the current enemy structure pointer

    0728  11 4c 05   LXI DE, CUR_MOB (054c)     ; Copy the enemy structure to the working buffer
    072b  06 0b      MVI B, 0b                  ; Structure size is 11 bytes

HANDLE_ENEMY_COPY_2_WORK_BUF:
    072d  7e         MOV A, M                   ; Copy the next byte
    072e  12         STAX DE

    072f  23         INX HL                     ; Advance pointers
    0730  13         INX DE

    0731  05         DCR B                      ; Repeat for all bytes of the structure
    0732  c2 2d 07   JNZ HANDLE_ENEMY_COPY_2_WORK_BUF (072d)


    0735  3a 53 05   LDA CUR_MOB + 7 (0553)     ; The enemy's skip move timer is due, no need to plan moves for
    0738  fe 00      CPI A, 00                  ; this tick
    073a  ca ef 08   JZ SUBMIT_ENEMY (08ef)

; Handle the waiting timer
;
; The waiting timer is used for 2 features:
; - The enemy hits a trap of a burned block. In this case timer is set to 20 game ticks. Each game tick
;   the timer is decremented. If it reached the value of 2 and the brick still not restored, the enemy
;   gets out the trap via RESCUE_ENEMY function
; - If the enemy is right below/above the player, but there is no straight ladder to the player, the enemy
;   plans a longer move using ladders on the left or right. In this case the timer is set to negative value
;   and counts up to 0. While the timer is running the enemy is doing a move to closest ladder, and does not
;   change the direction until reaches the ladder (even if there is a shorter path appears).
HANDLE_WAITING_TIMER:
    073d  3a 54 05   LDA CUR_MOB + 8 (0554)     ; Check if timer decreased to 2 and the enemy can escape
    0740  fe 02      CPI A, 02                  ; the trap
    0742  ca 6d 08   JZ RESCUE_ENEMY (086d)

    0745  fe 00      CPI A, 00                  ; If no timer is running - check if the enemy hit a trap
    0747  ca 51 07   JZ TRAP_ENEMY (0751)

    074a  f2 eb 08   JP DEC_WAITING_TIMER (08eb)    ; If timer is not yet due - decrement timer value and continue

    074d  3c         INR A                      ; Increment counter that starts with negative value until it
    074e  32 54 05   STA CUR_MOB + 8 (0554)     ; is zero

; Handle enemy in trap condition
; 
; This block is responsible for checking if the enemy hits a trap (literally located in a cell marked
; as solid block). This function is executed only if waiting timer is zero (meaning the enemy was not in
; the trap before). If enemy appears in the solid brick block and there was no timer started, it starts
; the timer for 20 game ticks.
TRAP_ENEMY:
    0751  2a 51 05   LHLD CUR_MOB + 5 (0551)        ; Load mob's map pointer

    0754  3a 4f 05   LDA CUR_MOB_CURSOR_STR + 3 (054f)  ; If the mob is on odd column - will read high nibble
    0757  e6 01      ANI A, 01                          ; If it is on even column - will read low nibble
    0759  fe 00      CPI A, 00
    075b  c2 68 07   JNZ TRAP_ENEMY_1 (0768)

    075e  7e         MOV A, M                   ; Read high nibble and shift it to low nibble position
    075f  e6 f0      ANI A, f0
    0761  0f         RRC
    0762  0f         RRC
    0763  0f         RRC
    0764  0f         RRC
    0765  c3 6b 07   JMP TRAP_ENEMY_2 (076b)

TRAP_ENEMY_1:
    0768  7e         MOV A, M                   ; Get the low nibble
    0769  e6 0f      ANI A, 0f

TRAP_ENEMY_2:
    076b  fe 05      CPI A, 05                  ; Check if mob's position matches the solid floor (perhaps
    076d  c2 78 07   JNZ TRAP_ENEMY_3 (0778)    ; the mob is in the pit)

    0770  3e 14      MVI A, 14                  ; Set timer to 20 ticks, after which enemy will get freed of the
    0772  32 54 05   STA CUR_MOB + 8 (0554)     ; pit
    0775  c3 ef 08   JMP SUBMIT_ENEMY (08ef)

TRAP_ENEMY_3:
    0778  3a 54 05   LDA CUR_MOB + 8 (0554)     ; If waiting timer is still running (for both trap and move
    077b  fe 00      CPI A, 00                  ; cases) - skip the movement planning. HANDLE_MOVES will do
    077d  c2 ef 08   JNZ SUBMIT_ENEMY (08ef)    ; previous move type.


; Enemy movement calculations
;
; This block is responsible for planning the current enemy move, based on comparison with the player's 
; coordinates. The algorithm:
; - If the enemy is above than the player, and there is a ladder down right below the enemy - use it
; - If the enemy is below than the player, and there is a ladder up right at the enemy position - use it
; - If the enemy is left or right to the player (regardless of height) - move towards the player right or left
; - If the enemy is right below or above the player (same X coordinate), but there is no ladder to use:
;   - Search a ladder up/down, or a cliff to jump down to the left and right from the enemy. Measure how far
;     it is from the enemy. Then select the shortest path and move that way. A waiting timer is started in 
;     order not to change direction decision until enemy reaches the ladder or cliff.
PLAN_ENEMY_MOVE:
    0780  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)  ; Compare current player Y position with the enemy's Y pos
    0783  21 4e 05   LXI HL, CUR_MOB_CURSOR_STR + 2 (054e)
    0786  be         CMP M                          ; If Y coordinates are the same, proceed with horizontal movement
    0787  ca b0 07   JZ PLAN_ENEMY_MOVE_HORZ (07b0)

    078a  fa a3 07   JM PLAN_ENEMY_MOVE_UP (07a3)   ; Player's Y coordinate < enemy's Y coordinate? Find a way
                                                    ; to climb up. 

; Search a way to move enemy down
PLAN_ENEMY_MOVE_DOWN:
    078d  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Get cursor to current enemy position
    0790  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0793  0e 1a      MVI C, 1a                  ; Move 1 position down
    0795  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0798  cd b5 01   CALL IS_LADDER_OR_EMPTY (01b5) ; Check if the block below allows moving down
    079b  c2 b0 07   JNZ PLAN_ENEMY_MOVE_HORZ (07b0)

    079e  3e 1a      MVI A, 1a                  ; Will be doing down move
    07a0  c3 c4 07   JMP PLAN_ENEMY_MOVE_EXIT (07c4)


; Search a way to move enemy up
PLAN_ENEMY_MOVE_UP:
    07a3  3a 55 05   LDA CUR_MOB + 9 (0555)     ; Get a block type behind the enemy

    07a6  fe 23      CPI A, 23                  ; Check if block type
    07a8  c2 b0 07   JNZ PLAN_ENEMY_MOVE_HORZ (07b0)    ; Ladder is a valid block for moving up

    07ab  3e 19      MVI A, 19                  ; Schedule moving enemy up
    07ad  c3 c4 07   JMP PLAN_ENEMY_MOVE_EXIT (07c4)

; Try moving enemy horizontally
PLAN_ENEMY_MOVE_HORZ:
    07b0  3a 0d 05   LDA PLAYER_POS_STR + 3 (050d)  ; Compare player's X coordinate with enemy's one
    07b3  21 4f 05   LXI HL, CUR_MOB_CURSOR_STR + 3 (054f)
    07b6  be         CMP M
    07b7  ca ca 07   JZ PLAN_ENEMY_MOVE_SAME_X (07ca)   ; If they are the same - ????

    07ba  fa c2 07   JM PLAN_ENEMY_MOVE_HORZ_1 (07c2)   ; Player X < Enemy X?

    07bd  3e 18      MVI A, 18                  ; Schedule moving right
    07bf  c3 c4 07   JMP PLAN_ENEMY_MOVE_EXIT (07c4)

PLAN_ENEMY_MOVE_HORZ_1:
    07c2  3e 08      MVI A, 08                  ; Schedule moving left

PLAN_ENEMY_MOVE_EXIT:
    07c4  32 56 05   STA CUR_MOB + 10 (0556)    ; Store movement type
    07c7  c3 ef 08   JMP SUBMIT_ENEMY (08ef)


; The enemy is at the same X position as player, but below or above
PLAN_ENEMY_MOVE_SAME_X:
    07ca  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)  ; Compare player's Y and enemy's Y
    07cd  21 4e 05   LXI HL, CUR_MOB_CURSOR_STR + 2 (054e)
    07d0  be         CMP M
    07d1  fa 09 08   JM SEARCH_WAY_UP (0809)        ; Is enemy below the player?

; The current enemy is right above the player. Look for a way down
SEARCH_WAY_DOWN:
    07d4  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Move cursor to the enemy's position
    07d7  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    07da  0e 1a      MVI C, 1a                      ; Move cursor to the block below
    07dc  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    07df  1e 00      MVI E, 00                      ; Zero distance to the ladder on the left

SEARCH_WAY_DOWN_LEFT:
    07e1  0e 08      MVI C, 08                      ; Move 1 position left
    07e3  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    07e6  1c         INR E                          ; Increment distance to the ladder

    07e7  cd b5 01   CALL IS_LADDER_OR_EMPTY (01b5) ; Repeat until we found a ladder or empty block
    07ea  c2 e1 07   JNZ SEARCH_WAY_DOWN_LEFT (07e1)


    07ed  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Get cursor to the enemy position again
    07f0  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    07f3  0e 1a      MVI C, 1a                      ; Move cursor 1 block down
    07f5  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    07f8  16 00      MVI D, 00                      ; Zero distance to the ladder on the left

SEARCH_WAY_DOWN_RIGHT:
    07fa  0e 18      MVI C, 18                      ; Move 1 block right
    07fc  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    07ff  14         INR D                          ; Increment counter

    0800  cd b5 01   CALL IS_LADDER_OR_EMPTY (01b5) ; Repeat until we found a ladder or empty block
    0803  c2 fa 07   JNZ SEARCH_WAY_DOWN_RIGHT (07fa)

    0806  c3 49 08   JMP SEARCH_WAY_COMPARE (0849)


; The current enemy is right above the player. Look for a way down
SEARCH_WAY_UP:
    0809  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Move cursor to the mob position
    080c  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    080f  1e 00      MVI E, 00                      ; Reset distance to the ladder on the left

SEARCH_WAY_UP_LEFT:
    0811  0e 08      MVI C, 08                      ; Move 1 position left
    0813  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0816  1c         INR E                          ; Increment the counter

    0817  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Check the block type

    081a  fe 70      CPI A, 70                      ; If reached the wall - set maximum distance value
    081c  ca 27 08   JZ SEARCH_WAY_UP_LEFT_MAX (0827)

    081f  fe 23      CPI A, 23                      ; Repeat until a ladder is found
    0821  c2 11 08   JNZ SEARCH_WAY_UP_LEFT (0811)

    0824  c3 29 08   JMP 0829

SEARCH_WAY_UP_LEFT_MAX:
    0827  1e 7f      MVI E, 7f                      ; Set maximum distance indicating do not move this directions

SEARCH_WAY_UP_RIGHT:
    0829  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Move cursor to the enemy position
    082c  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    082f  16 00      MVI D, 00                      ; Reset distance to the ladder on the right

SEARCH_WAY_UP_RIGHT_1:
    0831  0e 18      MVI C, 18                      ; Move one position to the right
    0833  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0836  14         INR D                          ; Increment distance to the ladder

    0837  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Check the block type

    083a  fe 70      CPI A, 70                      ; If reached a wall - set the maximum distance value
    083c  ca 47 08   JZ SEARCH_WAY_UP_RIGHT_MAX (0847)

    083f  fe 23      CPI A, 23                      ; Repeat until found a ladder
    0841  c2 31 08   JNZ SEARCH_WAY_UP_RIGHT_1 (0831)

    0844  c3 49 08   JMP SEARCH_WAY_COMPARE (0849)

SEARCH_WAY_UP_RIGHT_MAX:
    0847  16 7f      MVI D, 7f                      ; Set maximum distance value, indicating not to use this way


SEARCH_WAY_COMPARE:
    0849  7b         MOV A, E                       ; Compare left and right path length
    084a  ba         CMP D
    084b  ca 68 08   JZ SEARCH_WAY_COMPARE_EQ (0868)

    084e  fa 5a 08   JM SEARCH_WAY_COMPARE_LEFT (085a)  ; Left path is shorter?

    0851  5a         MOV E, D                       ; Save the left path length for further calculations

    0852  3e 18      MVI A, 18                      ; Right move looks preferable
    0854  32 56 05   STA CUR_MOB + 10 (0556)
    0857  c3 5f 08   JMP SEARCH_WAY_COMPARE_START_TIMER (085f)

SEARCH_WAY_COMPARE_LEFT:
    085a  3e 08      MVI A, 08                      ; Left move looks preferable
    085c  32 56 05   STA CUR_MOB + 10 (0556)

SEARCH_WAY_COMPARE_START_TIMER:
    085f  7b         MOV A, E                       ; Convert distance to a negative value and set it as a waiting
    0860  2f         CMA                            ; timer value. During this time the direction will not change
    0861  3c         INR A                          ; and the move planner will not be executed for this enemy

SEARCH_WAY_COMPARE_EXIT:
    0862  32 54 05   STA CUR_MOB + 8 (0554)         ; Save the waiting counter value, and exit from planner
    0865  c3 ef 08   JMP SUBMIT_ENEMY (08ef)

SEARCH_WAY_COMPARE_EQ:
    0868  3e 00      MVI A, 00                      ; Stop the waiting timer, the enemy will move to the
    086a  c3 62 08   JMP SEARCH_WAY_COMPARE_EXIT (0862) ; direction it moved earlier.



; Rescue enemy from the pit
;
; When enemy gets trapped, the TRAP_ENEMY function starts a waiting counter for 20 game ticks. 
; This function is responsible to rescue the enemy from the trap when these 20 ticks are over.
; 
; First, the function checks whether there is still a pit (the burned block has not been restored yet), 
; otherwise the enemy is considered dead, and needs to be respawned. In case if pit is not restored, 
; the enemy is moved 1 position up, right above the trap. The waiting counter is set to special value of 1,
; which tells HANDLE_MOVES function that enemy must go left/right from this place, skipping the function
; that checks for a empty block below. This prevents the enemy to fall into the same pit again.
RESCUE_ENEMY:
    086d  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Move cursor to the enemy position
    0870  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0873  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Get character at enemy position

    0876  fe 70      CPI A, 70                          ; If it already became a stone - respawn the enemy
    0878  ca bc 08   JZ RESPAWN_ENEMY (08bc)

    087b  0e 19      MVI C, 19                          ; Check the block type above
    087d  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0880  cd b5 01   CALL IS_LADDER_OR_EMPTY (01b5)     ; If it is not empty - nothing to do at this tick
    0883  c2 ef 08   JNZ SUBMIT_ENEMY (08ef)

    0886  21 55 05   LXI HL, CUR_MOB + 9 (0555)         ; Get pointer to the enemy's backing char

    0889  0e 1a      MVI C, 1a                          ; Get cursor back to the enemy's position
    088b  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    088e  4e         MOV C, M                           ; Restore char at the enemy's position
    088f  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0892  32 55 05   STA CUR_MOB + 9 (0555)             ; Save the new backing char from the block above

    0895  0e 08      MVI C, 08                          ; Move cursor back to the position above the enemy
    0897  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    089a  0e 19      MVI C, 19
    089c  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    089f  0e 09      MVI C, 09                          ; Draw the enemy symbol
    08a1  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    08a4  21 4e 05   LXI HL, CUR_MOB_CURSOR_STR + 2 (054e)  ; Decrement enemy Y coordinate
    08a7  35         DCR M

    08a8  2a 51 05   LHLD CUR_MOB + 5 (0551)            ; Adjust the map pointer
    08ab  11 e2 ff   LXI DE, ffe2
    08ae  19         DAD DE
    08af  22 51 05   SHLD CUR_MOB + 5 (0551)

    08b2  3a 54 05   LDA CUR_MOB + 8 (0554)             ; Decrement the waiting counter, so that it has value of 1.
    08b5  3d         DCR A                              ; This is a special case for HANDLE_MOVE function so that
    08b6  32 54 05   STA CUR_MOB + 8 (0554)             ; enemy does not fall to the pit again.

    08b9  c3 b0 07   JMP PLAN_ENEMY_MOVE_HORZ (07b0)    ; Think where to move next


; Respawn the enemy after it has died in the restored block
;
; The function generates a pseudo-random position on the topmost line, and respawn the enemy there.
; Enemy record fields are filled by this function.
RESPAWN_ENEMY:
    08bc  3a 15 0b   LDA GAME_TICK (0b15)       ; Convert game tick into a pseudo-random respawn position
    08bf  e6 1c      ANI A, 1c
    08c1  f6 04      ORI A, 04

    08c3  2a 5a 05   LHLD CUR_MAP_PTR (055a)    ; Calculate a map pointer for the respawned mob
    08c6  5f         MOV E, A                   ; (This will be somewhere in the top line)
    08c7  16 00      MVI D, 00
    08c9  19         DAD DE
    08ca  22 51 05   SHLD CUR_MOB + 5 (0551)    

    08cd  21 4e 05   LXI HL, CUR_MOB_CURSOR_STR + 2 (054e)  ; Set mob Y coordinate to topmost line
    08d0  36 21      MVI M, 21

    08d2  23         INX HL                     ; Set the X coordinate
    08d3  87         ADD A
    08d4  c6 22      ADI A, 22
    08d6  77         MOV M, A

    08d7  3e 00      MVI A, 00                  ; Clear waiting timer, so that enemy can move right away
    08d9  32 54 05   STA CUR_MOB + 8 (0554)

    08dc  21 4c 05   LXI HL, CUR_MOB_CURSOR_STR (054c)  ; Move cursor to the respawned mob coodrinate
    08df  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    08e2  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Store backing character at that position
    08e5  32 55 05   STA CUR_MOB + 9 (0555)

    08e8  c3 ef 08   JMP SUBMIT_ENEMY (08ef)


DEC_WAITING_TIMER:
    08eb  3d         DCR A                      ; Decrement the waiting timer, and proceed with enemy data
    08ec  32 54 05   STA CUR_MOB + 8 (0554)     ; submission.


; Submit enemy record changes back to the enemies array
SUBMIT_ENEMY:
    08ef  2a 58 05   LHLD CUR_MOB_PTR (0558)    ; Submit mob's changes from the working buffer back to the
    08f2  11 4c 05   LXI DE, CUR_MOB (054c)     ; main enemy array
    08f5  06 0b      MVI B, 0b

SUBMIT_ENEMY_LOOP:
    08f7  1a         LDAX DE                    ; Copy the next byte
    08f8  77         MOV M, A

    08f9  23         INX HL                     ; Advance pointers
    08fa  13         INX DE

    08fb  05         DCR B                      ; Repeat for all 11 bytes in the structure
    08fc  c2 f7 08   JNZ 08f7

    08ff  3a 57 05   LDA MOB_COUNTER (0557)     ; Decrement the enemies counter, and repeat until all
    0902  3d         DCR A                      ; enemies are processed
    0903  c2 22 07   JNZ HANDLE_ENEMY_LOOP (0722)

    0906  c9         RET                        ; Exit


; Check if all treasures were collected, and reveal exit ladder
;
; The function checks if the exit condition is met (all treasures were collected), and reveals the 
; exeit ladder for all blocks of type 0x0a on the map. The ladder is revealed with REVEAL_LADDER
; function. When the procedure is done, the flag is set to avoid scanning the map again on the next
; cycle.
HANDLE_EXIT_LADDER:
    0907  3a 16 0b   LDA IS_LADDER_REVEALED (0b16)  ; Check if the ladder has been already revealed
    090a  fe 00      CPI A, 00
    090c  c0         RNZ

    090d  2a 89 04   LHLD NUM_TREASURES (0489)  ; Is number of treasures zero? If not yet - exit
    0910  3e 00      MVI A, 00
    0912  bc         CMP H
    0913  c0         RNZ
    0914  bd         CMP L
    0915  c0         RNZ

    0916  06 14      MVI B, 14                  ; Will scan all 20 rows on the game screen
    0918  2a 5a 05   LHLD CUR_MAP_PTR (055a)    ; Load the map pointer

    091b  16 21      MVI D, 21                  ; Initial row

HANDLE_EXIT_LADDER_ROW_LOOP:
    091d  1e 22      MVI E, 22                  ; Initial column in each row

HANDLE_EXIT_LADDER_COL_LOOP:
    091f  7e         MOV A, M                   ; Load the next byte

    0920  e6 f0      ANI A, f0                  ; Check the high nibble
    0922  0f         RRC
    0923  0f         RRC
    0924  0f         RRC
    0925  0f         RRC

    0926  fe 0a      CPI A, 0a                  ; If the nibble type is 0x0a - reveal ladder for this block
    0928  cc 49 09   CZ REVEAL_LADDER (0949)

    092b  1c         INR E                      ; Advance X coordinate

    092c  7e         MOV A, M                   ; Get the low nibble value
    092d  e6 0f      ANI A, 0f

    092f  fe 0a      CPI A, 0a                  ; If the nibble type is 0x0a - reveal ladder for this block
    0931  cc 49 09   CZ REVEAL_LADDER (0949)

    0934  1c         INR E                      ; Advance to the next screen position

    0935  23         INX HL                     ; Advance to the next map byte

    0936  3e 5e      MVI A, 5e                  ; Repeat until reached the rightmost position
    0938  bb         CMP E
    0939  c2 1f 09   JNZ HANDLE_EXIT_LADDER_COL_LOOP (091f)

    093c  14         INR D                      ; Advance row

    093d  3e 35      MVI A, 35                  ; Repeat until reached the bottom row
    093f  ba         CMP D
    0940  c2 1d 09   JNZ HANDLE_EXIT_LADDER_ROW_LOOP (091d)

    0943  3e ff      MVI A, ff                  ; Set the 'ladder revealed' flag
    0945  32 16 0b   STA IS_LADDER_REVEALED (0b16)

    0948  c9         RET


; Reveal an end of level ladder
; 
; The function is executed for every screen block after the Player collected all treasures.
; If the function matches a block with code 0x0a (exit ladder), the ladder is revealed on the screen
; as a normal ladder.
;
; It may happen that player or enemy is currently on a position where the ladder shall appear. In this
; case the ladder symbol is written to the MOB (player or enemy) structure as a symbol behind the MOB.
; When the mob moves, the ladder will be revealed.
;
; Argument:
; DE - screen coordinate of the block where to reveal the exit level ladder
REVEAL_LADDER:
    0949  0e 1b      MVI C, 1b                  ; Move cursor to coordinates in DE
    094b  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    094e  0e 59      MVI C, 59
    0950  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0953  4a         MOV C, D
    0954  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0957  4b         MOV C, E
    0958  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    095b  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Check if the current char matches the player
    095e  fe 09      CPI A, 09                              ; BUG? What if an enemy is on this position
    0960  c2 a3 09   JNZ REVEAL_LADDER_EXIT (09a3)

    0963  e5         PUSH HL                    ; Save some registers
    0964  d5         PUSH DE
    0965  c5         PUSH BC

    0966  eb         XCHG                       ; Store current block position to a local variable
    0967  22 12 0b   SHLD REVEAL_BLOCK_POS (0b12)

    096a  21 0c 05   LXI HL, PLAYER_POS_STR + 2 (050c)
    096d  11 13 05   LXI DE, PLAYER_STRUCT + 9 (0513)
    0970  01 0b 00   LXI BC, 000b

    0973  3a 09 05   LDA MOBS_COUNT (0509)      ; Init the records counter
    0976  32 15 0b   STA MOB_COUNTER (0b15)

REVEAL_LADDER_LOOP:
    0979  3a 13 0b   LDA 0b13                   ; Compare X coordinate
    097c  be         CMP M
    097d  c2 8d 09   JNZ REVEAL_LADDER_2 (098d)

    0980  23         INX HL

    0981  3a 12 0b   LDA REVEAL_BLOCK_POS (0b12); Compare Y coordinate
    0984  be         CMP M
    0985  c2 8c 09   JNZ REVEAL_LADDER_1 (098c)

    0988  eb         XCHG
    0989  36 23      MVI M, 23                  ; Store '#' as a char under the mob
    098b  eb         XCHG

REVEAL_LADDER_1:
    098c  2b         DCX HL                     ; Restore pointer

REVEAL_LADDER_2:
    098d  09         DAD BC                     ; Advance to the next MOB
    098e  eb         XCHG
    098f  09         DAD BC
    0990  eb         XCHG

    0991  3a 15 0b   LDA MOB_COUNTER (0b15)     ; Decrement mob count to go
    0994  3d         DCR A

    0995  fe 00      CPI A, 00                  ; Exit when reached zero
    0997  ca a0 09   JZ REVEAL_LADDER_3 (09a0)

    099a  32 15 0b   STA MOB_COUNTER (0b15)     ; Store the counter and repeat
    099d  c3 79 09   JMP REVEAL_LADDER_LOOP (0979)

REVEAL_LADDER_3:
    09a0  c1         POP BC                     ; Restore registers
    09a1  d1         POP DE
    09a2  e1         POP HL

REVEAL_LADDER_EXIT:
    09a3  0e 23      MVI C, 23                  ; Draw a ladder
    09a5  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    09a8  c9         RET


; Main entry point to the game
; 
; The function performs the following actions:
; - Draws the welcome screen
; - Draws the game border
; - Load, initialize, and draw the level 1
; - Start game loop
REAL_START:
    09a9  21 5c 05   LXI HL, WELCOME_SCREEN (055c)  ; Print the intro screen
    09ac  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    09af  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for a key press

    09b2  cd 55 00   CALL DRAW_BORDER (0055)        ; Draw the game screen

    09b5  21 18 0b   LXI HL, MAP_01 (0b18)          ; Initialize current map pointer
    09b8  22 5a 05   SHLD CUR_MAP_PTR (055a)

    09bb  06 04      MVI B, 04                      ; Zero score
    09bd  21 85 04   LXI HL, SCORE (0485)

REAL_START_ZERO_SCORE:
    09c0  23         INX HL
    09c1  36 00      MVI M, 00
    09c3  05         DCR B
    09c4  c2 c0 09   JNZ REAL_START_CLEAR_SCORE (09c0)

    09c7  3e 03      MVI A, 03                      ; Set initial number of lives
    09c9  32 17 0b   STA LIVES_COUNT (0b17)

    09cc  3e 01      MVI A, 01                      ; Set initial level
    09ce  32 11 0b   STA CUR_LEVEL (0b11)

; Restart the game on a new map
;
; The function performs the following actions:
; - Update lives and level fields on the screen
; - Initialize mob structures (backing characters, waiting timer)
; - Clear the burned bricks array
; - Handle new maps keys:
;   - 'L' increments the lives number
;   - 'M' advance to the next map
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

    09ea  21 13 05   LXI HL, PLAYER_STRUCT + 9 (0513)   ; Set space (0x20) as a mob backing character
    09ed  11 0b 00   LXI DE, 000b                   ; Struct size - 11 bytes
    09f0  06 06      MVI B, 06                      ; 6 structures - 1 player + 5 enemies

NEW_MAP_1:
    09f2  36 20      MVI M, 20                      ; Set space

    09f4  19         DAD DE                         ; Advance to the next record

    09f5  05         DCR B                          ; repeat for all 6 records
    09f6  c2 f2 09   JNZ NEW_MAP_1 (09f2)

    09f9  21 12 05   LXI HL, PLAYER_STRUCT + 8 (0512)   ; Zero waiting timer for all mobs
    09fc  06 06      MVI B, 06

NEW_MAP_2:
    09fe  36 00      MVI M, 00                      ; Zwro timer value

    0a00  19         DAD DE                         ; Advance to the next record

    0a01  05         DCR B                          ; Repeat for all 6 mobs
    0a02  c2 fe 09   JNZ NEW_MAP_2 (09fe)

    0a05  21 91 04   LXI HL, BURNED_BRICKS_BACKUP (0491)    ; Clear 120 bytes (main and backup burned bricks
    0a08  06 78      MVI B, 78                              ; brick arrays)

NEW_MAP_3:
    0a0a  36 00      MVI M, 00                      ; Clear the byte

    0a0c  23         INX HL                         ; Repeat for all 120 bytes
    0a0d  05         DCR B
    0a0e  c2 0a 0a   JNZ NEW_MAP_3 (0a0a)

    0a11  2a 5a 05   LHLD CUR_MAP_PTR (055a)        ; Draw the map
    0a14  cd f7 00   CALL DRAW_MAP (00f7)

    0a17  cd 28 01   CALL INIT_MAP (0128)           ; Initialize the map structures

    0a1a  3e 00      MVI A, 00                      ; Clear 'ladder revealed' flag
    0a1c  32 16 0b   STA IS_LADDER_REVEALED (0b16)

WAIT_START_KEY:
    0a1f  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for a initial key press

    0a22  fe 4c      CPI A, 4c                      ; 'L' advances the level
    0a24  ca 8d 0a   JZ ADVANCE_LEVEL (0a8d)

    0a27  fe 4d      CPI A, 4d                      ; 'M' increments lives counter
    0a29  c2 40 0a   JNZ GAME_LOOP (0a40)

    0a2c  21 4b 00   LXI HL, MOVE_TO_LIVES_STR (004b)   ; Move cursor to the lives field
    0a2f  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0a32  3a 17 0b   LDA LIVES_COUNT (0b17)         ; Increment the lives counter
    0a35  3c         INR A
    0a36  32 17 0b   STA LIVES_COUNT (0b17)
    0a39  27         DAA

    0a3a  cd 15 f8   CALL MONITOR_PRINT_BYTE_HEX (f815) ; Print the new value on the screen

    0a3d  c3 1f 0a   JMP WAIT_START_KEY (0a1f)

; The main game loop
; 
; The main game loop is a set of repeated actions:
; - Check the pressed key (if pressed - put it to the move key field of the player structure)
; - Handle player and enemy moves
; - Handle player collected a treasure event
; - Handle player burned a brick (or enough time passed and the brick is restored)
; - Handle enemy movements, searching a way how to reach the player
; - Handle the case when the player collected all treasures, and exit ladder appear
;
; The function is also responsible for checking map exit condition (player reached the topmost line).
; When this happen the map is advanced to the next one.
;
; If the player is caught by an enemy, or trapped in a pit, the level is restarted, and lives counter is
; decremented.
GAME_LOOP:
    0a40  cd 1b f8   CALL MONITOR_SCAN_KBD (f81b)   ; Check if a key is pressed

    0a43  fe ff      CPI A, ff                  ; If no key pressed - move to the same direction
    0a45  ca 4b 0a   JZ GAME_LOOP_1 (0a4b)

    0a48  32 14 05   STA PLAYER_STRUCT + 10 (0514)  ; Store the pressed key value

GAME_LOOP_1:
    0a4b  fe 41      CPI A, 41                  ; 'A' restarts the level, reducing lives counter
    0a4d  ca e0 0a   JZ PLAYER_DIE (0ae0)

    0a50  cd cd 01   CALL HANDLE_MOVES (01cd)
    0a53  cd a8 03   CALL HANDLE_TREASURE (03a8)
    0a56  cd e2 03   CALL HANDLE_BRICKS (03e2)
    0a59  cd 1b 07   CALL HANDLE_ENEMY (071b)
    0a5c  cd 07 09   CALL HANDLE_EXIT_LADDER (0907)

    0a5f  16 2f      MVI D, 2f                  ; Make a delay of 0x2f * 0x6f loops

DELAY_LOOP1:
    0a61  1e 6f      MVI E, 6f

DELAY_LOOP2:
    0a63  1d         DCR E
    0a64  c2 63 0a   JNZ DELAY_LOOP2 (0a63)
    
    0a67  15         DCR D
    0a68  c2 61 0a   JNZ DELAY_LOOP1 (0a61)

    0a6b  21 15 0b   LXI HL, GAME_TICK (0b15)       ; Increment game tick value
    0a6e  34         INR M

    0a6f  2a 89 04   LHLD NUM_TREASURES (0489)      ; Is number of treasures zero?
    0a72  97         SUB A
    0a73  bc         CMP H
    0a74  c2 ac 0a   JNZ CHECK_PLAYER_DEATH (0aac)
    0a77  bd         CMP L
    0a78  c2 ac 0a   JNZ CHECK_PLAYER_DEATH (0aac)

    0a7b  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)  ; Is player on the top row?
    0a7e  fe 21      CPI A, 21
    0a80  c2 ac 0a   JNZ CHECK_PLAYER_DEATH (0aac)

    0a83  e6 00      ANI A, 00                  ; If both conditions are met - increment player's lives
    0a85  3a 17 0b   LDA LIVES_COUNT (0b17)     ; And advance to the next level
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


; The next piece of code is responsible for handling player's death
; It checks for the 2 conditions:
; - Player appears in a pit, and the broken block restored
; - Player is in the same position as one of the enemies
; In both cases execution is passed to PLAYER_DIE function
CHECK_PLAYER_DEATH:
    0aac  21 0a 05   LXI HL, PLAYER_POS_STR (050a)  ; Move cursor to the player's position
    0aaf  cd 18 f8   CALL MONITOR_PRINT_STR (f818)

    0ab2  cd 21 f8   CALL MONITOR_GET_CHAR_AT_CURSOR (f821) ; Check the symbol there

    0ab5  fe 70      CPI A, 70                      ; If for some reason it is solid block (e.g. player
    0ab7  ca e0 0a   JZ PLAYER_DIE (0ae0)           ; felt into the pit, and block restored), player dies

    0aba  21 17 05   LXI HL, ENEMY1_POS_STR + 2 (0517)  ; Iterate over enemy mobs
    0abd  11 0b 00   LXI DE, 000b                   ; Mob size is 11 bytes

    0ac0  3a 09 05   LDA MOBS_COUNT (0509)          ; Calculate number of enemies
    0ac3  3d         DCR A
    0ac4  4f         MOV C, A

CHECK_PLAYER_DEATH_LOOP:
    0ac5  3a 0c 05   LDA PLAYER_POS_STR + 2 (050c)  ; Is player Y position the same as enemy's position?
    0ac8  be         CMP M
    0ac9  c2 d8 0a   JNZ CHECK_PLAYER_DEATH_NEXT (0ad8)

    0acc  23         INX HL                         ; Compare also X coordinates
    0acd  3a 0d 05   LDA PLAYER_POS_STR + 3 (050d)
    0ad0  be         CMP M
    0ad1  c2 d7 0a   JNZ CHECK_PLAYER_DEATH_1 (0ad7)

    0ad4  c3 e0 0a   JMP PLAYER_DIE (0ae0)      ; If player's position matches the enemy position - player dies

CHECK_PLAYER_DEATH_1:
    0ad7  2b         DCX HL

CHECK_PLAYER_DEATH_NEXT:
    0ad8  19         DAD DE                     ; Advance to the next enemy record

    0ad9  0d         DCR C                      ; Repeat for all enemies
    0ada  c2 c5 0a   JNZ CHECK_PLAYER_DEATH_LOOP (0ac5)

    0add  c3 40 0a   JMP GAME_LOOP (0a40)       ; Get back to the main loop


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

REVEAL_BLOCK_POS:
    0b12 00 00              dw 0000             ; Local variable of REVEAL_BLOCK function, stores currently
                                                ; processed block position

    0b14  00         NOP

MOB_COUNTER:
GAME_TICK:
    0b15  ce            db 00                   ; This variable has 2 meanings:
                                                ; - Typically this is a row counter of game ticks. Incremented
                                                ;   on every game cycle. Used as pseudo-random number generator
                                                ;   for enemy respawn position
                                                ; - mob counter for REVEAL_LADDER function. Used to limit number
                                                ;   of iterations over mob list

IS_LADDER_REVEALED:
    0b16                    db 00               ; Flag indicates that player collected all treasures, and exit
                                                ; ladder has revealed on the screen

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

; Tetris game
;
; This is a classic tetris game. The user can select difficulty level (which acts as a 
; game loop delay). The difficulty increases when the user completes certain number of lines.
;
; The game is using a back buffer in logic coordinates that grow from bottom left corder up. 
; The falling figure is not a part of the game buffer, but rather calculated on top of the
; buffer. This helps collisiion detection and movement of the figure. When the figure reaches
; bottom border, or previously fallen blocks, the new figure is then applied and copied to the
; game buffer. 
;
; When the figure has landed, line collapsing and line counting procedure begins.
;
; Figure format is quite interesting. The figure has some logic coordinates, and this coordinate
; represent the main blocks. Other 3 blocks are calculated as X and Y offsets (positive or negative)
; to the previous block. This allow representing 4-block figure in just 6 bytes. This also allows
; to simplify collide checks.
;
; Variables:
; 0x3659 - Flag indicating the figure has landed (0xff landed, 0x00 - falling)
; 0x365d - currently falling figure address (2 bytes)
; 0x365f - currengly falling figure buffer (6 bytes)
; 0x3665 - next figure (6 bytes)
; 0x366b - rotation preview buffer (6 bytes)
; 0x365a - current falling figure coordinates
; 0x365c - current rotation
; 0x3671 - Remaining delay until next game tick occurs (when space is pressed - ticks go faster)
; 0x3672 - difficulty level (delay)
; 0x3673 - random seed
; 0x3674 - next figure index (1 based)
; 0x3675 - current figure index (1 based)
; 0x3676 - Falling figure horizontal offset (used for calculation the new coordinate)
; 0x3677 - Falling figure vertical offset (used for calculation the new coordinate)
; 0x3678 - completed lines counter
; 0x367a - Bypass drawing, only calculations (0x01 - draw, 0x00 - bypass)
; 0x367f - Game buffer (64x25)
;
; Port notes:
; This game port uses Monitor's routines to draw chars. Althrough this is good for portability
; reasons, the performance sucks. Most of the block draws simply put 1 or 2 chars at the specified
; location. The program has to calculate the offset in screen coordinates, convert this to the 4 char
; escape sequence, in order to position the cursor. The printing function does plenty of calculations,
; handles special characters, escape sequence, and many more. It would be much faster and visually better
; if blocks were drawn with either direct writes to the video memory, or at least with a simpler function
; that takes X and Y screen coordinate and a symbol to print.
INIT:
    3000  3e 01      MVI A, 01                  ; Draw as usual (no draw bypass)
    3002  32 7a 36   STA 367a

    3005  31 7f 3f   LXI SP, 3f7f               ; Use own stack
    3008  00         NOP
    3009  00         NOP
    300a  00         NOP
    300b  00         NOP
    300c  00         NOP
    300d  00         NOP

GAME_RESTART:
    300e  0e 1b      MVI C, 1b                  ; Print Esc-E sequence, but this is not supported by UT-88.
    3010  cd 5d 32   CALL PUT_CHAR (325d)       ; Moreover it does not match to any modern standards to guess
    3013  0e 45      MVI C, 45                  ; what it supposed to do. Most probably this should erase the 
    3015  cd 5d 32   CALL PUT_CHAR (325d)       ; screen

    3018  21 07 35   LXI HL, LEGEND_STR (3507)  ; Draw the legend
    301b  cd 52 32   CALL PUT_STRING (3252)

    301e  21 10 1f   LXI HL, 1f10               ; Draw the border starting from top-left
    3021  e5         PUSH HL
    3022  3e 23      MVI A, 23                  ; Char to print - '#'

    3024  06 15      MVI B, 15                  ; Draw 21 blocks down (left border)
LEFT_BORDER_LOOP:
    3026  cd f4 33   CALL DRAW_BLOCK (33f4)
    3029  25         DCR H
    302a  05         DCR B
    302b  c2 26 30   JNZ LEFT_BORDER_LOOP (3026)

    302e  24         INR H                      ; Draw 11 blocks right (bottom border)
    302f  06 0c      MVI B, 0c
BOTTOM_BORDER_LOOP:
    3031  cd f4 33   CALL DRAW_BLOCK (33f4)
    3034  2c         INR L
    3035  05         DCR B
    3036  c2 31 30   JNZ BOTTOM_BORDER_LOOP (3031)

    3039  2d         DCR L                      ; Draw 20 blocks up (right border)
    303a  06 15      MVI B, 15
RIGHT_BORDER_LOOP:
    303c  cd f4 33   CALL DRAW_BLOCK (33f4)
    303f  24         INR H
    3040  05         DCR B
    3041  c2 3c 30   JNZ RIGHT_BORDER_LOOP (303c)

    3044  3e 2e      MVI A, 2e                  ; Draw empty cells with '.'
    3046  0e 14      MVI C, 14                  ; Height of the field
    3048  e1         POP HL
    3049  2c         INR L                      ; Start at top-left corner
FILL_FIELD_V_LOOP:
    304a  e5         PUSH HL
    304b  06 0a      MVI B, 0a                  ; Width of the field

FILL_FIELD_H_LOOP:
    304d  cd f4 33   CALL DRAW_BLOCK (33f4)     ; Fill the entire field
    3050  2c         INR L
    3051  05         DCR B
    3052  c2 4d 30   JNZ FILL_FIELD_H_LOOP (304d)

    3055  e1         POP HL
    3056  25         DCR H
    3057  0d         DCR C
    3058  c2 4a 30   JNZ FILL_FIELD_V_LOOP (304a)

GET_USER_LEVEL:
    305b  21 95 35   LXI HL, GET_LEVEL_STR (3595)   ; Print "Get level" string
    305e  cd 52 32   CALL PUT_STRING (3252)

    3061  cd 73 32   CALL WAIT_KEY (3273)       ; And wait for the User's input
    3064  4f         MOV C, A
    3065  cd 5d 32   CALL PUT_CHAR (325d)

    3068  d6 30      SUI A, 30                  ; Validate the input, repeat input if needed
    306a  da 5b 30   JC GET_USER_LEVEL (305b)
    306d  fe 08      CPI A, 08
    306f  d2 5b 30   JNC GET_USER_LEVEL (305b)

    3072  2f         CMA                        ; Invert the input, and convert it to the delay
    3073  e6 07      ANI A, 07
    3075  c6 01      ADI A, 01
    3077  32 72 36   STA 3672                   ; Store the delay in 0x3672

    307a  01 00 40   LXI BC, 4000               ; Do some delay
START_GAME_DELAY:
    307d  0b         DCX BC
    307e  78         MOV A, B
    307f  b1         ORA C
    3080  c2 7d 30   JNZ START_GAME_DELAY (307d)

    3083  21 b2 35   LXI HL, PRESS_ANY_KEY_STR (35b2)
    3086  cd 52 32   CALL PUT_STRING (3252)

WAIT_ANY_KEY_LOOP:
    3089  cd 7d 32   CALL GET_KEY_IF_PRESSED (327d) ; Wait for a key, delay will generate random seed in HL
    308c  b7         ORA A
    308d  23         INX HL
    308e  fa 89 30   JM WAIT_ANY_KEY_LOOP (3089)

    3091  67         MOV H, A                       ; Calculate random seed based on reading random 
    3092  ad         XRA L                          ; memory addresses
    3093  46         MOV B, M
    3094  ae         XRA M
    3095  6f         MOV L, A
    3096  4e         MOV C, M
RANDOM_SEED_LOOP:
    3097  09         DAD BC
    3098  0d         DCR C
    3099  f2 97 30   JP RANDOM_SEED_LOOP (3097)

    309c  7c         MOV A, H                   ; Store random seed in 0x3673
    309d  ad         XRA L
    309e  32 73 36   STA 3673

    30a1  af         XRA A                      ; Store 0 to the completed line counter
    30a2  32 78 36   STA 3678

    30a5  3d         DCR A                      ; Set figure landed flag (it will go through landing
    30a6  32 59 36   STA 3659                   ; procedure immediately)
    
    30a9  21 ce 35   LXI HL, LINES_COUNT_STR (35ce)
    30ac  cd 52 32   CALL PUT_STRING (3252)
    30af  c3 68 31   JMP GAME_LOOP (3168)



; Collapse all filled lines, prepare for the next figure
COLLAPSE_LINES:
    30b2  af         XRA A                      ; Reset the figure landed flag
    30b3  32 59 36   STA 3659

    30b6  3a 72 36   LDA 3672                   ; Prepare delay loop based on difficulty level
    30b9  32 71 36   STA 3671

    30bc  21 11 0c   LXI HL, 0c11               ; Check 20 lines starting from the bottom one
    30bf  06 14      MVI B, 14

CHECK_NEXT_LINE:
    30c1  3e ff      MVI A, ff                  ; Flag indicating that the line is full
    30c3  32 79 36   STA 3679

    30c6  0e 0a      MVI C, 0a                  ; Number of cells in the line

CHECK_LINE_LOOP:
    30c8  cd 35 34   CALL GET_CELL (3435)       ; Check if the cell is filled
    30cb  fe 5b      CPI A, 5b
    30cd  ca d4 30   JZ COLLAPSE_LINE_1 (30d4)

    30d0  af         XRA A                      ; If not - reset the 'Line full' flag
    30d1  32 79 36   STA 3679

COLLAPSE_LINE_1:
    30d4  2c         INR L                      ; Advance to the next cell in the line
    30d5  0d         DCR C
    30d6  c2 c8 30   JNZ CHECK_LINE_LOOP (30c8)

    30d9  2e 11      MVI L, 11                  ; Check if the line is indeed full
    30db  3a 79 36   LDA 3679
    30de  b7         ORA A
    30df  f2 4f 31   JP ADVANCE_TO_NEXT_LINE (314f) ; If not - get to the next line

    30e2  3a 72 36   LDA 3672                   ; Calculate how many lines needs to be completed
    30e5  d6 01      SUI A, 01                  ; to get the next difficulty level
    30e7  2f         CMA
    30e8  e6 07      ANI A, 07
    30ea  07         RLC
    30eb  57         MOV D, A

    30ec  07         RLC
    30ed  82         ADD D
    30ee  c6 05      ADI A, 05
    30f0  07         RLC
    30f1  57         MOV D, A

    30f2  3a 78 36   LDA 3678                   ; Increase the completed lines counter
    30f5  3c         INR A

    30f6  ba         CMP D                      ; If reached calculated count - increase the difficulty
    30f7  cc c8 32   CZ INCREASE_DIFFICULTY (32c8)

    30fa  fe 64      CPI A, 64                  ; Check if reached 100 lines count
    30fc  c2 00 31   JNZ HUNDRED_LINES_COMPLETED (3100)

    30ff  af         XRA A                      ; Reset the counter

HUNDRED_LINES_COMPLETED:
    3100  32 78 36   STA 3678                   ; Store the counter

    3103  0e 00      MVI C, 00                  ; Convert A into a digit
LINE_COUNTER_DIGIT:
    3105  0c         INR C                      ; Count decades in C
    3106  d6 0a      SUI A, 0a
    3108  d2 05 31   JNC LINE_COUNTER_DIGIT (3105)
    310b  c6 3a      ADI A, 3a
    
    310d  eb         XCHG                       ; Draw the lines count
    310e  21 0b 1e   LXI HL, 1e0b
    3111  cd f4 33   CALL DRAW_BLOCK (33f4)

    3114  2d         DCR L                      ; Draw the space to the left
    3115  3e 20      MVI A, 20
    3117  cd f4 33   CALL DRAW_BLOCK (33f4)

    311a  79         MOV A, C                   ; Print decades count
    311b  c6 2f      ADI A, 2f
    311d  4f         MOV C, A
    311e  cd 5d 32   CALL PUT_CHAR (325d)

    3121  eb         XCHG
    3122  e5         PUSH HL
COPY_LINE_LOOP:
    3123  54         MOV D, H                   ; Copy higher line to lower
    3124  14         INR D
    3125  0e 0a      MVI C, 0a                  ; Do for all 10 horizontal blocks
COPY_CELL_LOOP:
    3127  5d         MOV E, L                   ; Copy cell from upper to lower cell
    3128  eb         XCHG
    3129  cd 35 34   CALL GET_CELL (3435)
    312c  eb         XCHG
    312d  cd f4 33   CALL DRAW_BLOCK (33f4)

    3130  2c         INR L                      ; Repeat for all blocks in the line
    3131  0d         DCR C
    3132  c2 27 31   JNZ COPY_CELL_LOOP (3127)

    3135  24         INR H                      ; Repeat for all lines up to the top
    3136  2e 11      MVI L, 11
    3138  7c         MOV A, H
    3139  fe 1f      CPI A, 1f
    313b  c2 23 31   JNZ COPY_LINE_LOOP (3123)

    313e  21 11 1f   LXI HL, 1f11               ; Fill the top line with empty slots
    3141  0e 0a      MVI C, 0a
    3143  3e 2e      MVI A, 2e
FILL_EMPTY_LINE_LOOP:
    3145  cd f4 33   CALL DRAW_BLOCK (33f4)
    3148  2c         INR L
    3149  0d         DCR C
    314a  c2 45 31   JNZ FILL_EMPTY_LINE_LOOP (3145)

    314d  e1         POP HL
    314e  25         DCR H

ADVANCE_TO_NEXT_LINE:
    314f  24         INR H                      ; Repeat for the next line
    3150  05         DCR B
    3151  c2 c1 30   JNZ CHECK_NEXT_LINE (30c1)

    3154  06 06      MVI B, 06                  ; Copy next figure from preview buffer (0x3665) to
    3156  21 5f 36   LXI HL, 365f               ; the main current figure buffer (0x365f)
    3159  22 5d 36   SHLD 365d
    315c  eb         XCHG

    315d  21 65 36   LXI HL, 3665
COPY_FIGURE_LOOP:
    3160  7e         MOV A, M
    3161  12         STAX DE
    3162  23         INX HL
    3163  13         INX DE
    3164  05         DCR B
    3165  c2 60 31   JNZ COPY_FIGURE_LOOP (3160)


; Game loop
GAME_LOOP:
    3168  21 47 34   LXI HL, 3447               ; Base address of the figures (actual figures start 345F)
    316b  11 18 00   LXI DE, 0018               ; Size of a figure (4 records 6 bytes each)

    316e  cd aa 32   CALL GEN_RANDOM_VALUE (32aa)   ; Generate next figure (random value) in A

GET_FIGURE_ADDR_LOOP:
    3171  19         DAD DE                     ; Calculate new figure base address
    3172  3d         DCR A
    3173  c2 71 31   JNZ GET_FIGURE_ADDR_LOOP (3171)

    3176  06 06      MVI B, 06                  ; figure record size (6 bytes)
    3178  11 65 36   LXI DE, 3665
    317b  d5         PUSH DE

COPY_NEXT_FIGURE_LOOP:
    317c  7e         MOV A, M                   ; Copy next figure to 0x3665
    317d  12         STAX DE
    317e  23         INX HL
    317f  13         INX DE
    3180  05         DCR B
    3181  c2 7c 31   JNZ COPY_NEXT_FIGURE_LOOP (317c)

    3184  d1         POP DE

    3185  21 06 0f   LXI HL, 0f06               ; Clear 2 lines by 6 cells starting 0x0f06 coordinate

CLEAR_NEXT_FIGURE_LOOP:
    3188  3e 20      MVI A, 20                  ; Clear single cell
    318a  cd f4 33   CALL DRAW_BLOCK (33f4)
    318d  0e 20      MVI C, 20
    318f  cd 5d 32   CALL PUT_CHAR (325d)

    3192  2c         INR L                      ; Advance to the next cell horiontally
    3193  7d         MOV A, L
    3194  fe 0c      CPI A, 0c
    3196  c2 88 31   JNZ CLEAR_NEXT_FIGURE_LOOP (3188)

    3199  2e 06      MVI L, 06                  ; Advance to the next line vertically
    319b  24         INR H
    319c  7c         MOV A, H
    319d  fe 11      CPI A, 11
    319f  c2 88 31   JNZ CLEAR_NEXT_FIGURE_LOOP (3188)

    31a2  21 07 10   LXI HL, 1007               ; Draw the next figure
    31a5  0e 5b      MVI C, 5b
    31a7  cd 91 32   CALL DRAW_FIGURE (3291)

    31aa  3a 59 36   LDA 3659                   ; Check figure landed flag
    31ad  b7         ORA A
    31ae  c2 b2 30   JNZ COLLAPSE_LINES (30b2)  ; If landed - collapse all filled lines, and get next figure

    31b1  32 5c 36   STA 365c                   ; Reset the rotation index

    31b4  21 15 1f   LXI HL, 1f15
    31b7  22 5a 36   SHLD 365a                  ; Place new figure at the top line

    31ba  32 76 36   STA 3676                   ; Reset figure offset
    31bd  32 77 36   STA 3677

    31c0  cd 15 33   CALL CHECK_COLLISION (3315); Check if newly placed figure fits the game buffer
    31c3  da 14 32   JC GAME_OVER (3214)

    31c6  0e 5b      MVI C, 5b                  ; Draw the figure in its position
    31c8  cd 8c 32   CALL DRAW_CURRENT_FIGURE_AT_HL (328c)

NEXT_CYCLE:
    31cb  3a 71 36   LDA 3671                   ; Load difficulty delay value
    31ce  47         MOV B, A
    31cf  0e 01      MVI C, 01

KEY_INPUT_LOOP:
    31d1  cd 7d 32   CALL GET_KEY_IF_PRESSED (327d) ; Get the keyboard input, if any
    31d4  b7         ORA A
    31d5  fa fe 31   JM NO_KBD_INPUT (31fe)

    31d8  fe 36      CPI A, 36                  ; Handle 'Speed up' key
    31da  ca ed 33   JZ HANDLE_SPEED_UP (33ed)

    31dd  fe 37      CPI A, 37                  ; Handle 'Left' key
    31df  ca 5a 33   JZ HANDLE_LEFT (335a)

    31e2  fe 38      CPI A, 38                  ; Handle 'Rotate' key
    31e4  ca 80 33   JZ HANDLE_ROTATE (3380)

    31e7  fe 39      CPI A, 39                  ; Handle 'Right' key
    31e9  ca 7b 33   JZ HANDLE_RIGHT (337b)

    31ec  fe 03      CPI A, 03                  ; Handle Ctrl-C as a game over
    31ee  ca 14 32   JZ GAME_OVER (3214)

    31f1  fe 53      CPI A, 53                  ; Handle 'Pause' key
    31f3  ca 2f 32   JZ HANDLE_PAUSE (322f)

    31f6  11 71 36   LXI DE, 3671               ; Handle 'Space' key
    31f9  fe 20      CPI A, 20
    31fb  ca 69 33   JZ HANDLE_SPACE (3369)

NO_KBD_INPUT:
    31fe  0b         DCX BC                     ; Repeat keyboard input until a key is pressed
    31ff  78         MOV A, B                   ; Or a time out (speed delay) is reached
    3200  b1         ORA C
    3201  c2 d1 31   JNZ KEY_INPUT_LOOP (31d1)

    3204  32 76 36   STA 3676                   ; Set zero horizontal offset, and -1 as a vertical
    3207  3d         DCR A
    3208  32 77 36   STA 3677

    320b  cd eb 32   CALL CALCULATE_MOVE (32eb) ; Calculate the move, check for collisions

    320e  d2 cb 31   JNC NEXT_CYCLE (31cb)      ; If no collisiions - continue with falling the figure

    3211  c3 b2 30   JMP COLLAPSE_LINES (30b2)  ; Figure landed, collapse lines, if any

; The game over screen
;
; Shows the game over message, and ask if the User wants to restart the game
GAME_OVER:
    3214  21 eb 35   LXI HL, GAME_OVER_STR (35eb)   ; Print the game over string
    3217  cd 52 32   CALL PUT_STRING (3252)
    
    321a  cd 73 32   CALL WAIT_KEY (3273)       ; And wait for the answer

    321d  fe 59      CPI A, 59                  ; If yes - restart the game
    321f  ca 0e 30   JZ GAME_RESTART (300e)

    3222  fe 4e      CPI A, 4e                  ; If no - reset to the monitor
    3224  ca 00 f8   JZ f800



    3227  00         NOP                        ; Unused piece
    3228  00         NOP
    3229  00         NOP
    322a  00         NOP
    322b  00         NOP
    322c  00         NOP
    322d  00         NOP
    322e  00         NOP


HANDLE_PAUSE:
    322f  e5         PUSH HL                    ; Print the pause string
    3230  21 19 36   LXI HL, PAUSE_STR (3619)
    3233  cd 52 32   CALL PUT_STRING (3252)

    3236  c5         PUSH BC                    ; Do some delay
    3237  01 00 00   LXI BC, 0000

PAUSE_LOOP:
    323a  0b         DCX BC
    323b  78         MOV A, B
    323c  b1         ORA C
    323d  c2 3a 32   JNZ PAUSE_LOOP (323a)

    3240  c1         POP BC

PAUSE_WAIT_KEY:
    3241  cd 7d 32   CALL GET_KEY_IF_PRESSED (327d)
    3244  b7         ORA A
    3245  fa 41 32   JM PAUSE_WAIT_KEY (3241)

    3248  21 39 36   LXI HL, ERASE_PAUSE (3639) ; Erase pause string
    324b  cd 52 32   CALL PUT_STRING (3252)
    324e  e1         POP HL
    324f  c3 fe 31   JMP NO_KBD_INPUT (31fe)    ; Continue the game


; Print a NULL terminated string at address HL
PUT_STRING:
    3252  7e         MOV A, M                   ; Get next symbol
    3253  b7         ORA A
    3254  c8         RZ                         ; Return when zero is reached

    3255  4f         MOV C, A                   ; Print the car
    3256  23         INX HL
    3257  cd 5d 32   CALL PUT_CHAR (325d)
    325a  c3 52 32   JMP PUT_STRING (3252)


; Print a character in C register to the screen at cursor position
; 
; This is simply a wrapper over Monitor's PUT_CHAR function
PUT_CHAR:
    325d  e5         PUSH HL                    ; Save all registers
    325e  d5         PUSH DE                    ; (weird, but Monitor's function does the same)
    325f  c5         PUSH BC
PUT_CHAR_INT:
    3260  f5         PUSH PSW

    3261  cd 09 f8   CALL MONITOR_PUT_CHAR_C (f809)

    3264  f1         POP PSW                    ; Restore all registers
    3265  c1         POP BC
    3266  d1         POP DE
    3267  e1         POP HL
    3268  c9         RET


; Check if a button is presses
;
; Return A=00 if no buttons pressed
; Return A=ff if a button is pressed
IS_BUTTON_PRESSED:
    3269  e5         PUSH HL                    ; Save the registers (Actually Monitor does not change it)
    326a  d5         PUSH DE
    326b  c5         PUSH BC

    326c  cd 12 f8   CALL MONITOR_IS_BUTTON_PRESSED (f812)

    326f  c1         POP BC                     ; Restore registers
    3270  d1         POP DE
    3271  e1         POP HL
    3272  c9         RET

; Wait for a keyboard press
; 
; Returns entered symbol in A
WAIT_KEY:
    3273  e5         PUSH HL
    3274  d5         PUSH DE
    3275  c5         PUSH BC

    3276  cd 03 f8   CALL MONITOR_KBD_INPUT (f803)

    3279  c1         POP BC
    327a  d1         POP DE
    327b  e1         POP HL
    327c  c9         RET

; Get keycode if a button is pressed, otherwise return 0xff
GET_KEY_IF_PRESSED:
    327d  cd 69 32   CALL IS_BUTTON_PRESSED (3269)
    3280  b7         ORA A
    3281  c2 73 32   JNZ WAIT_KEY (3273)

    3284  f6 ff      ORI A, ff
    3286  c9         RET


; Clear current figure at current coordinates
;
; The function will clear cells under figure's blocks with '.'
CLEAR_CURRENT_FIGURE:
    3287  0e 2e      MVI C, 2e


; Draw current figure at current coordinates
;
; Draw the currently falling figure at its coordinates stored in 0x365a
; The function uses 0x365d currently falling figure buffer
; C - symbol to draw the figure with
DRAW_CURRENT_FIGURE:
    3289  2a 5a 36   LHLD 365a


; Draw current figure
;
; Draw the currently falling figure at HL logic coordinates. 
; The function uses 0x365d currently falling figure buffer
; C - symbol to draw the figure with
DRAW_CURRENT_FIGURE_AT_HL:
    328c  eb         XCHG
    328d  2a 5d 36   LHLD 365d
    3290  eb         XCHG


; Draw the figure
;
; Arguments:
; HL - logic coordinates of the figure
; DE - address of the figure buffer
; C - symbol to draw the figure with
DRAW_FIGURE:
    3291  79         MOV A, C                   ; Draw the central block at HL logic coordinates
    3292  cd f4 33   CALL DRAW_BLOCK (33f4)

    3295  e5         PUSH HL
    3296  06 03      MVI B, 03                  ; Will draw 3 additional blocks

DRAW_FIGURE_LOOP:
    3298  1a         LDAX DE                    ; Apply next block X offset
    3299  13         INX DE
    329a  85         ADD L
    329b  6f         MOV L, A

    329c  1a         LDAX DE                    ; Apply nexy block Y offset
    329d  13         INX DE
    329e  84         ADD H
    329f  67         MOV H, A

    32a0  79         MOV A, C                   ; Draw the block
    32a1  cd f4 33   CALL DRAW_BLOCK (33f4)

    32a4  05         DCR B                      ; Repeat for all 3 additional blocks
    32a5  c2 98 32   JNZ DRAW_FIGURE_LOOP (3298)

    32a8  e1         POP HL
    32a9  c9         RET

; Generate next random value in range 1-7. 
; New value stored in 3674
; Return new value in A
GEN_RANDOM_VALUE:
    32aa  3a 74 36   LDA 3674                   ; Copy next figure number into current figure number
    32ad  32 75 36   STA 3675

    32b0  3a 73 36   LDA 3673                   ; Advance 0x3673 by 0xbb
    32b3  c6 bb      ADI A, bb
    32b5  32 73 36   STA 3673

    32b8  c5         PUSH BC
    32b9  47         MOV B, A
    32ba  0f         RRC
    32bb  0f         RRC
    32bc  0f         RRC
    32bd  a8         XRA B
    32be  c1         POP BC

    32bf  e6 07      ANI A, 07
    32c1  ca aa 32   JZ GEN_RANDOM_VALUE (32aa)

    32c4  32 74 36   STA 3674                   ; Store the new next figure number
    32c7  c9         RET


INCREASE_DIFFICULTY:
    32c8  f5         PUSH PSW

    32c9  3a 72 36   LDA 3672                   ; Decrease the difficulty delay
    32cc  3d         DCR A

    32cd  fe 01      CPI A, 01                  ; ...but no more than 1
    32cf  d2 d4 32   JNC APPLY_NEW_DIFFICULTY (32d4)
    32d2  3e 01      MVI A, 01

APPLY_NEW_DIFFICULTY:
    32d4  32 72 36   STA 3672                   ; Store new delay value
    32d7  32 71 36   STA 3671

    32da  d6 01      SUI A, 01                  ; Convert delay value into difficulty level digit
    32dc  2f         CMA
    32dd  e6 07      ANI A, 07
    32df  c6 30      ADI A, 30

    32e1  e5         PUSH HL                    ; Draw new difficulty level
    32e2  21 0b 1f   LXI HL, 1f0b
    32e5  cd f4 33   CALL DRAW_BLOCK (33f4)
    32e8  e1         POP HL

    32e9  f1         POP PSW
    32ea  c9         RET

; Calculate the move, and apply if the figure landed
;
; The function clears previously drawn falling figure. In case if the figure reached the bottom
; (Collide check returns true), the figure is moved into the game buffer (falling figure is not
; in the buffer)
CALCULATE_MOVE:
    32eb  c5         PUSH BC
    32ec  f5         PUSH PSW

    32ed  af         XRA A                      ; Bypass figure drawing
    32ee  32 7a 36   STA 367a

    32f1  f1         POP PSW                    ; Check if figure collides with existing blocks
    32f2  e5         PUSH HL
    32f3  cd 12 33   CALL CLEAR_FIGURE (3312)

    32f6  f5         PUSH PSW                   ; Prepare for really clearing the figure
    32f7  3e 01      MVI A, 01
    32f9  32 7a 36   STA 367a
    32fc  f1         POP PSW

    32fd  da 05 33   JC HANDLE_COLLIDE (3305)   ; Collide detected

    3300  e1         POP HL                     ; if no collide - clear the previously drawn figure
    3301  cd 12 33   CALL CLEAR_FIGURE (3312)
    3304  e5         PUSH HL

HANDLE_COLLIDE:
    3305  e1         POP HL                     ; Store new figure coordinates in 0x365a
    3306  22 5a 36   SHLD 365a

    3309  0e 5b      MVI C, 5b                  ; And draw the figure permanently, converting falling
    330b  f5         PUSH PSW                   ; figure into set of blocks in the game buffer
    330c  cd 8c 32   CALL DRAW_CURRENT_FIGURE_AT_HL (328c)

    330f  f1         POP PSW
    3310  c1         POP BC
    3311  c9         RET


; Clear the figure at current location, and then check for collisions
CLEAR_FIGURE:
    3312  cd 87 32   CALL CLEAR_CURRENT_FIGURE (3287)


; Check the falling figure collisions
;
; The function uses current figure coordinate (0x365a), applies proposed offset in 0x3676-0x3677, 
; and checks if all blocks of the figure match empty cells of the game buffer. The pointer at 0x365d
; points to the currently falling figure at current rotation (6-byte)
; 
; Return: 
; Carry flag set if a collision is detected
CHECK_COLLISION:
    3315  3a 76 36   LDA 3676                   ; Apply horizontal offset to the current figure coordinate
    3318  2a 5a 36   LHLD 365a                  ; 
    331b  85         ADD L
    331c  6f         MOV L, A

    331d  3a 77 36   LDA 3677                   ; Apply vertical offset
    3320  84         ADD H
    3321  67         MOV H, A

    3322  e5         PUSH HL                    ; Check if the cell is occupied
    3323  cd 35 34   CALL GET_CELL (3435)
    3326  fe 2e      CPI A, 2e
    3328  c2 49 33   JNZ COLLISION_DETECTED (3349)

    332b  06 03      MVI B, 03                  ; If not - repeat for other 3 blocks in the figure
    332d  eb         XCHG
    332e  2a 5d 36   LHLD 365d                  ; Load currently falling figure address
    3331  eb         XCHG

CHECK_COLLISION_LOOP:
    3332  1a         LDAX DE                    ; Calculate next block X coordinate
    3333  13         INX DE
    3334  85         ADD L
    3335  6f         MOV L, A

    3336  1a         LDAX DE                    ; Calculate next block Y coordinate
    3337  13         INX DE
    3338  84         ADD H
    3339  67         MOV H, A

    333a  cd 35 34   CALL GET_CELL (3435)       ; Check if the calculated cell is occupied
    333d  fe 2e      CPI A, 2e
    333f  c2 49 33   JNZ COLLISION_DETECTED (3349)

    3342  05         DCR B                      ; Repeat for other blocks in the figure
    3343  c2 32 33   JNZ CHECK_COLLISION_LOOP (3332)

    3346  e1         POP HL                     ; If all blocks of the figure fit the game without
    3347  b7         ORA A                      ; collisions - clear C flag and return
    3348  c9         RET

COLLISION_DETECTED:
    3349  e1         POP HL

    334a  3a 76 36   LDA 3676                   ; Subtrack offset back from the X coordinate
    334d  2f         CMA
    334e  3c         INR A
    334f  85         ADD L
    3350  6f         MOV L, A

    3351  3a 77 36   LDA 3677                   ; Subtrack offset back from the Y coordinate
    3354  2f         CMA
    3355  3c         INR A
    3356  84         ADD H
    3357  67         MOV H, A

    3358  37         STC                        ; Set Carry flag indicating there is a collision
    3359  c9         RET



HANDLE_LEFT:
    335a  3e ff      MVI A, ff                  ; Set -1 offset to the falling figure

HANDLE_MOVE:
    335c  32 76 36   STA 3676                   ; Set the horizontal offset

    335f  af         XRA A                      ; Zero vertical offset
    3360  32 77 36   STA 3677

    3363  cd eb 32   CALL CALCULATE_MOVE (32eb)

    3366  11 76 36   LXI DE, 3676

HANDLE_SPACE:
    3369  3a 71 36   LDA 3671                   ; Do the difficulty delay
    336c  87         ADD A
    336d  47         MOV B, A

    336e  0e 01      MVI C, 01

SPACE_DELAY:
    3370  0b         DCX BC
    3371  78         MOV A, B
    3372  b1         ORA C
    3373  c2 70 33   JNZ SPACE_DELAY (3370)

    3376  12         STAX DE
    3377  03         INX BC
    3378  c3 fe 31   JMP NO_KBD_INPUT (31fe)


HANDLE_RIGHT:
    337b  3e 01      MVI A, 01                  ; Handle +1 offset to the falling figure
    337d  c3 5c 33   JMP HANDLE_MOVE (335c)


HANDLE_ROTATE:
    3380  3a 5c 36   LDA 365c                   ; Calculate next rotation value
    3383  3c         INR A
    3384  e6 03      ANI A, 03
    3386  32 5c 36   STA 365c

    3389  c5         PUSH BC                    ; Clear the figure at previous location and rotation
    338a  cd 87 32   CALL CLEAR_CURRENT_FIGURE (3287)

    338d  21 41 34   LXI HL, 3441               ; Base address of all figures
    3390  11 18 00   LXI DE, 0018               ; Single figure size (for all rotations)
    3393  3a 75 36   LDA 3675                   ; Load current figure number

NEXT_FIGURE_ADDR_LOOP:
    3396  19         DAD DE
    3397  3d         DCR A
    3398  c2 96 33   JNZ NEXT_FIGURE_ADDR_LOOP (3396)

    339b  3a 5c 36   LDA 365c                   ; Get current rotation index
    339e  3c         INR A

    339f  11 06 00   LXI DE, 0006               ; Calculate the address of current rotation
NEXT_ROTATION_ADDR_LOOP:
    33a2  19         DAD DE
    33a3  3d         DCR A
    33a4  c2 a2 33   JNZ NEXT_ROTATION_ADDR_LOOP (33a2)

    33a7  06 06      MVI B, 06                  ; Copy 6 bytes to rotation preview buffer

    33a9  11 6b 36   LXI DE, 366b               ; Set 0x366b as a current figure address
    33ac  eb         XCHG
    33ad  22 5d 36   SHLD 365d

COPY_ROT_FIGURE_LOOP:
    33b0  1a         LDAX DE                    ; Copy bytes to rotation preview buffer
    33b1  77         MOV M, A
    33b2  23         INX HL
    33b3  13         INX DE
    33b4  05         DCR B
    33b5  c2 b0 33   JNZ COPY_ROT_FIGURE_LOOP (33b0)

    33b8  af         XRA A                      ; Reset the offset values
    33b9  32 76 36   STA 3676
    33bc  32 77 36   STA 3677

    33bf  cd 15 33   CALL CHECK_COLLISION (3315); Check for collisions after rotation

    33c2  21 5f 36   LXI HL, 365f               ; Load current figure buffer
    33c5  22 5d 36   SHLD 365d                  ; Set the current figure address

    33c8  d2 d7 33   JNC ROTATION_APPLY (33d7)  ; If not collided - apply rotated figure

    33cb  3a 5c 36   LDA 365c                   ; Revert back the rotation index
    33ce  3d         DCR A
    33cf  e6 03      ANI A, 03
    33d1  32 5c 36   STA 365c

    33d4  c3 e4 33   JMP ROTATION_EXIT (33e4)   ; Exit the rotation function


ROTATION_APPLY:
    33d7  11 6b 36   LXI DE, 366b               ; Copy from rotation preview buffer to the main
    33da  06 06      MVI B, 06                  ; falling figure buffer
ROTATION_APPLY_COPY_LOOP:
    33dc  1a         LDAX DE
    33dd  77         MOV M, A
    33de  23         INX HL
    33df  13         INX DE
    33e0  05         DCR B
    33e1  c2 dc 33   JNZ ROTATION_APPLY_COPY_LOOP (33dc)

ROTATION_EXIT:
    33e4  0e 5b      MVI C, 5b                  ; Draw the rotated figure
    33e6  cd 89 32   CALL DRAW_CURRENT_FIGURE (3289)
    33e9  c1         POP BC

    33ea  c3 f0 33   JMP DO_NO_MOVE (33f0)


HANDLE_SPEED_UP:
    33ed  cd c8 32   CALL INCREASE_DIFFICULTY (32c8)

DO_NO_MOVE:
    33f0  af         XRA A                      ; Do a move with no movement
    33f1  c3 5c 33   JMP HANDLE_MOVE (335c)

; Draw a block at HL logical coordinates with symbol in A register
;
; Block is 2-chars wide. Logical coordinates are counted from bottom left, where
; H represents vertical coordinate, and L - horizontal.
;
; The function does 2 things:
; - Updates the block on the screen
; - Stores the new value in the game buffer
;
; Arguments:
; H - logical Y coordinate of the block
; L - logical X coordinate of the block
; A - Character to print as a block
; Flag in 0x367a bypasses the drawing (0x01 - draw, 0x00 - skip)
DRAW_BLOCK:
    33f4  e5         PUSH HL
    33f5  d5         PUSH DE
    33f6  c5         PUSH BC

    33f7  47         MOV B, A
    33f8  cd 3e 34   CALL CALC_BLOCK_ADDR (343e); Calculate screen coordinates in DE, and block addr in HL
    
    33fb  70         MOV M, B                   ; Store the value in the game buffer

    33fc  3a 7a 36   LDA 367a                   ; Check if drawing is by passed
    33ff  b7         ORA A
    3400  c2 08 34   JNZ DRAW_BLOCK_CONT (3408)

    3403  78         MOV A, B
    3404  c1         POP BC
    3405  d1         POP DE
    3406  e1         POP HL
    3407  c9         RET

DRAW_BLOCK_CONT:
    3408  0e 1b      MVI C, 1b                  ; Move cursor sequence (DE is a coordinate)
    340a  cd 5d 32   CALL PUT_CHAR (325d)
    340d  0e 59      MVI C, 59
    340f  cd 5d 32   CALL PUT_CHAR (325d)
    3412  4a         MOV C, D
    3413  cd 5d 32   CALL PUT_CHAR (325d)
    3416  4b         MOV C, E
    3417  cd 5d 32   CALL PUT_CHAR (325d)

    341a  48         MOV C, B
    341b  78         MOV A, B
    341c  fe 5b      CPI A, 5b                  ; Occupied cells will be printed as "[["
    341e  cc 5d 32   CZ PUT_CHAR (325d)

    3421  fe 2e      CPI A, 2e                  ; Empty cells will be printed as " ."
    3423  c2 2c 34   JNZ DRAW_BLOCK_1 (342c)
    3426  0e 20      MVI C, 20
    3428  cd 5d 32   CALL PUT_CHAR (325d)
    342b  48         MOV C, B

DRAW_BLOCK_1:
    342c  fe 23      CPI A, 23                  ; Borders will be printed as "##"
    342e  cc 5d 32   CZ PUT_CHAR (325d)
    3431  78         MOV A, B
    3432  c3 60 32   JMP PUT_CHAR_INT (3260)    ; Print the second char and exit

; Return the cell value 
;
; Arguments: HL - logical coordinates of the cell
; Return: value in A
GET_CELL:
    3435  e5         PUSH HL
    3436  d5         PUSH DE
    3437  cd 3e 34   CALL CALC_BLOCK_ADDR (343e)
    343a  7e         MOV A, M
    343b  d1         POP DE
    343c  e1         POP HL
    343d  c9         RET

; Calculate address of the given block
;
; Arguments:
; H - block vertical coordinate (bottom to top)
; L - block horizontal coordinate (left to right)
;
; Result:
; D - block vertical screen coordinate (top to bottom) + 0x20 (can be passed to Move cursor sequence)
; E - block horizontal screen coordinate + 0x20 (can be passed to Move cursor sequence)
; HL - address of the block byte in the game buffer
;
; Algorithm:
; Y = 0x20 - H      ; logic coordinates
; X = L
; D = 0x20 + Y      ; Screen coordinates
; E = 0x20 + 2*X
; HL = Y*0x40 + X + 0x367f  ; Block address in the buffer
CALC_BLOCK_ADDR:
    343e  c5         PUSH BC

    343f  3e 20      MVI A, 20                  ; Convert logical Y to screen coordinate (which grows from
    3441  94         SUB H                      ; top to bottom)
    3442  47         MOV B, A                   ; Store Y coordinate in B

    3443  7d         MOV A, L                   ; Double X coordinate (each block is 2 chars wide)
    3444  87         ADD A
    3445  4f         MOV C, A                   ; Store the X coordinate in C

    3446  21 20 20   LXI HL, 2020               ; Calculate screen coordinate, and store in DE
    3449  09         DAD BC
    344a  eb         XCHG

    344b  21 7f 36   LXI HL, 367f               ; Buffer base address

    344e  0f         RRC                        ; Restore original X coordinate
    344f  4f         MOV C, A

    3450  78         MOV A, B                   ; Shift Y coordinate 2 bits right, so that every row is
    3451  0f         RRC                        ; 0x40 bytes (BC = 00yyyyyy yyxxxxxx)
    3452  0f         RRC
    3453  47         MOV B, A
    3454  e6 c0      ANI A, c0
    3456  b1         ORA C
    3457  4f         MOV C, A
    3458  78         MOV A, B
    3459  e6 3f      ANI A, 3f
    345b  47         MOV B, A

    345c  09         DAD BC                     ; Calculate result in HL (base address + offset)
    345d  c1         POP BC
    345e  c9         RET


; The following bytes represent figures and their rotations.
; 
; Format is the following
; - One block of the figure is implicit and exist in all rotations
; - The 6-byte record represent 3 pairs of bytes, describing locations of 3 additional blocks.
;   Each pair is X offset + Y offset (offset from the previous block).
; - Each figure is represented as 4 rotations, each is a 6-byte record described above.
;
; In the comments below:
; - @ - is a primary (implicit) block
; - X - additional blocks calculated with offsets

FIGURE_I:
    345f  FF 00 02 00 01 00     ; X@XX

    3465  00 FF 00 02 00 01     ; X
                                ; @
                                ; X 
                                ; X 

    346B  FF 00 02 00 01 00     ; X@XX

    3471  00 FF 00 02 00 01     ; X
                                ; @
                                ; X 
                                ; X

FIGURE_L:
    3477  FF 00 02 00 00 FF     ;   X
                                ; X@X

    347D  00 FF 00 02 01 00     ; X
                                ; @
                                ; XX

    3483  01 00 FE 00 00 01     ; X@X
                                ; X

    3489  00 01 00 FE FF 00     ; XX
                                ;  @
                                ;  X

FIGURE_J:
    348F  01 00 FE 00 00 FF     ; X
                                ; X@X 

    3495  00 01 00 FE 01 00     ; XX
                                ; @
                                ; X

    349B  FF 00 02 00 00 01     ; X@X
                                ;   X

    34A1  00 FF 00 02 FF 00     ;  X
                                ;  @
                                ; XX

FIGURE_Z:
    34A7  01 00 FF FF FF 00     ; XX
                                ;  @X
                                 
    34AD  00 01 01 FF 00 FF     ;  X
                                ; @X
                                ; X

    34B3  01 00 FF FF FF 00     ; XX
                                ;  @X
     
    34B9  00 01 01 FF 00 FF     ;  X
                                ; @X
                                ; X

FIGURE_S:
    34BF  FF 00 01 FF 01 00     ;  XX
                                ; X@
 
    34C5  00 01 FF FF 00 FF     ; X
                                ; X@
                                ;  X

    34CB  FF 00 01 FF 01 00     ;  XX
                                ; X@
 
    34D1  00 01 FF FF 00 FF     ; X
                                ; X@
                                ;  X

FIGURE_T:      
    34D7  FF 00 02 00 FF ff     ;  X
                                ; X@X

    34DD  00 FF 00 02 01 FF     ; X
                                ; @X
                                ; X

    34E3  01 00 FE 00 01 01     ; X@X
                                ;  X

    34E9  00 01 00 FE FF 01     ;  X
                                ; X@
                                ;  X

FIGURE_O:
    34EF  00 FF 01 00 00 01     ; XX
                                ; @X

    34F5  00 FF 01 00 00 01     ; XX
                                ; @X

    34FB  00 FF 01 00 00 01     ; XX
                                ; @X

    3501  00 FF 01 00 00 01     ; XX
                                ; @X


LEGEND_STR:
    3507  1b 59 24 20 0e 2e 2e 37  db 0x1b, 0x59, 0x24, 0x20, 0x0e, "..7"   ; Move cursor to 0:4
    350f  2e 2e 20 20 20 20 20 2e  db "..     ."
    3517  2e 38 2e 2e 20 20 20 20  db ".8..    "
    351f  20 2e 2e 39 2e 2e 0d 0a  db " ..9..", 0x0d, 0x0a
    3527  77 6c 65 77 6f 20 20 20  db "ВЛЕВО   "
    352f  20 77 72 61 7d 61 74 78  db " ВРАЩАТЬ"
    3537  20 20 20 20 77 70 72 61  db "    ВПРА"
    353f  77 6f 0d 0a 0a 75 77 65  db "ВО", 0x0d, 0x0a, 0x0a, "УВЕ"
    3547  6c 69 7e 69 74 78 20 73  db "ЛИЧИТЬ С"
    354f  6b 6f 72 6f 73 74 78 20  db "КОРОСТЬ "
    3557  20 2e 2e 36 2e 2e 0d 0a  db " ..6..", 0x0d, 0x0a
    355f  0a 20 20 2e 2e 50 52 4f  db 0x0a, "  ..ПРО"
    3567  42 45 4c 2e 2e 20 20 20  db "БЕЛ..   "
    356f  20 20 73 62 72 6f 73 69  db "  СБРОСИ"
    3577  74 78 0d 0a 0f 0a 20 20  db "ТЬ", 0x0d, 0x0a, 0x0f, 0x0a, "  " 
    357f  20 20 2e 2e 53 2e 2e 20  db "  ..S.. "
    3587  20 20 20 20 20 20 20 0e  db "       ", 0x0e
    358f  70 61 75 7a 61 00        db "ПАУЗА", 0x00

GET_LEVEL_STR:
    3595  1b 59 21 20 77 61 7b 20  db 0x1b, 'Y', 0x21, 0x20, "ВАШ "
    359d  75 72 6f 77 65 6e 78 28  db "УРОВЕНЬ("
    35a5  30 2d 37 29 20 3f 20 20  db "0-7) ?  "
    35ad  20 20 20 08 00           db "   ", 0x08, 0x00

PRESS_ANY_KEY_STR:
    35b2  1b 59 22 20 6e 61 76 6d  db 0x1b, 'Y', 0x22, 0x20, "НАЖМ"
    35ba  69 74 65 20 6c 60 62 75  db "ИТЕ ЛЮБУ"
    35c2  60 20 6b 6c 61 77 69 7b  db "Ю КЛАВИШ"
    35ca  75 20 21 00              db "У !", 0x00

LINES_COUNT_STR:
    35ce  1b 59 22 20 7e 69 73 6c  db 0x1b, 'Y', 0x22, 0x20, "ЧИСЛ"
    35d6  6f 20 70 6f 6c 6e 79 68  db "О ПОЛНЫХ"
    35de  20 73 74 72 6f 6b 20 20  db " СТРОК  "
    35e6  20 30 30 0d 00           db " 00", 0x0d, 0x00

GAME_OVER_STR:
    35eb  1b 59 36 28 69 67 72 61  db 0x1b, 'Y', 0x36, 0x28, "ИГРА"
    35f3  20 7a 61 6b 6f 6e 7e 65  db " ЗАКОНЧЕ"
    35fb  6e 61 2c 20 76 65 6c 61  db "НА, ЖЕЛА"
    3603  65 74 65 20 70 6f 77 74  db "ЕТЕ ПОВТ"
    360b  6f 72 69 74 78 3f 0f 20  db "ОРИТЬ?  "
    3613  28 59 2f 4e 29 00        db "(Y/N)", 0x00

PAUSE_STR:
    3619  1b 59 36 28 77 6f 64 69  db 0x1b, 'Y', 0x36, 0x28, "ВОДИ"
    3621  74 65 6c 78 2c 20 75 73  db "ТЕЛЬ, УС"
    3629  74 61 6c 20 2d 20 6f 74  db "ТАЛ - ОТ"
    3631  64 6f 68 6e 69 20 21 00  db "ДОХНИ !", 0x00

ERASE_PAUSE:
    3639  1b 59 36 28 20 20 20 20  db 0x1b, 'Y', 0x36, 0x28, "    "
    3641  20 20 20 20 20 20 20 20  db "        "
    3649  20 20 20 20 20 20 20 20  db "        "
    3651  20 20 20 20 20 20 20 00  db "       ", 0x00

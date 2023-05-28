; 
; Variables:
; 019e      - Block symbol (just passing symbol between 2 functions. Not used in the game)
; 0240      - Current map number
; 0241      - currently parsed map record ptr (2 bytes)
; 0243-0882 - game buffer (25 lines by 64 chars each)
; 0883      - pointer to the game buffer
; 0885-0889 - currently parsed map record (block type, Y1, Y2, X1, X2)
; 088a      - calculated block top-left address in the game buffer
; 088c      - block height counter
; 088d      - block width counter
; 08b1      - Player start position Y             --+
; 08b2      - Player start position X               |
; 08b3      - Enemy 1 start position (Y,X)          |
; 08b5      - Enemy 2 start position (Y,X)          |
; 08b7      - Enemy 3 start position (Y,X)          | Record at the end of each map
; 08b9      - Enemy 4 start position (Y,X)          |
; 08bb      - Number of enemies on the map          |
; 08bc      - Map exit coordinate (Y,X)           --+
; 0ad4      - Player current coordinate Y
; 0ad5      - Player current coordinate X
; 0ad6      - falling cycles counter
; 0ad7      - flag indicating the player is currently falling
; 0ad8      - Currently pressed keyboard
; 0ad9      - Number of found treasures
; 0faa      - Previous enemy position (used in calculations only, not used anywhere else in the game)
; 0fac      - Flag indicating that enemy is falling
; 0faf      - New enemy position (used in calculations only, not used anywhere else in the game)
; 0fb0      - Enemy 1 current position
; 0fb4      - Enemy 2 current position
; 0fb8      - Enemy 3 current position
; 0fbc      - Enemy 4 current position
; 11c3      - Flag indicating the player has been caught by an enemy
; 1164      - Enemy 1 respawn timer
; 1165      - Enemy 2 respawn timer
; 1166      - Enemy 3 respawn timer
; 1167      - Enemy 4 respawn timer
; 120e      - an index in the broken bricks array (local variable, used to pass value between functions)
; 120f-139e - 100 4-byte records holding information about broken bricks
; 13a3      - Counter to slightly slow down arrow flying
; 159b      - Arrow is flying right
; 159c      - Arrow is flying left
; 159d      - Arrow flying left position
; 159f      - Arrow flying right position
;
; Game blocks:
; 01    - outer walls
; 02    - ladders
; 03    - ????
; 05    - water
; 06    - rope / thin floor
; 07    - treasure
; 08    - ??? treasure
; 0b    - floors
; 0c
; 0d
; 0e 
; 
START:
    0000  31 ff 00   LXI SP, 00ff               ; Set the stack pointer
    0003  c3 05 16   JMP REAL_START (1605)      ; And jump to the real start

0006  00         NOP
0007  00         NOP
????:
0008  00         NOP
0009  00         NOP
000a  00         NOP
????:
000b  00         NOP
000c  00         NOP
000d  00         NOP
000e  00         NOP
000f  00         NOP
0010  00         NOP
0011  00         NOP
0012  00         NOP
0013  00         NOP
0014  00         NOP
0015  00         NOP
0016  00         NOP
????:
0017  00         NOP
0018  00         NOP
0019  00         NOP
001a  00         NOP
001b  00         NOP
001c  00         NOP
001d  00         NOP
001e  00         NOP
001f  00         NOP
0020  00         NOP
0021  00         NOP
0022  00         NOP
0023  00         NOP
0024  00         NOP
0025  00         NOP
0026  00         NOP
0027  00         NOP
0028  00         NOP
0029  00         NOP
002a  00         NOP
002b  00         NOP
002c  00         NOP
002d  00         NOP
????:
002e  00         NOP
002f  00         NOP
0030  00         NOP
0031  00         NOP
0032  00         NOP
0033  00         NOP
????:
0034  00         NOP
????:
0035  00         NOP
0036  00         NOP
0037  00         NOP
0038  00         NOP
????:
0039  00         NOP
????:
003a  00         NOP
????:
003b  00         NOP
????:
003c  00         NOP
003d  00         NOP
003e  00         NOP
003f  00         NOP
????:
0040  00         NOP
0041  00         NOP
0042  00         NOP
0043  00         NOP
0044  00         NOP
0045  00         NOP
0046  00         NOP
0047  00         NOP
0048  00         NOP
0049  00         NOP
004a  00         NOP
004b  00         NOP
004c  00         NOP
004d  00         NOP
004e  00         NOP
004f  00         NOP
0050  00         NOP
0051  00         NOP
0052  00         NOP
0053  00         NOP
0054  00         NOP
0055  00         NOP
0056  00         NOP
0057  00         NOP
0058  00         NOP
0059  00         NOP
005a  00         NOP
005b  00         NOP
005c  00         NOP
005d  00         NOP
005e  00         NOP
005f  00         NOP
0060  00         NOP
0061  00         NOP
0062  00         NOP
0063  00         NOP
0064  00         NOP
0065  00         NOP
0066  00         NOP
0067  00         NOP
0068  00         NOP
0069  00         NOP
006a  00         NOP
006b  00         NOP
006c  00         NOP
006d  00         NOP
006e  00         NOP
006f  00         NOP
0070  00         NOP
0071  00         NOP
0072  00         NOP
0073  00         NOP
0074  00         NOP
0075  00         NOP
0076  00         NOP
0077  00         NOP
0078  00         NOP
0079  00         NOP
007a  00         NOP
007b  00         NOP
007c  00         NOP
007d  00         NOP
007e  00         NOP
007f  00         NOP
0080  00         NOP
0081  00         NOP
0082  00         NOP
0083  00         NOP
0084  00         NOP
0085  00         NOP
0086  00         NOP
0087  00         NOP
0088  00         NOP
0089  00         NOP
008a  00         NOP
008b  00         NOP
008c  00         NOP
008d  00         NOP
008e  00         NOP
008f  00         NOP
0090  00         NOP
0091  00         NOP
0092  00         NOP
0093  00         NOP
0094  00         NOP
0095  00         NOP
0096  00         NOP
0097  00         NOP
0098  00         NOP
0099  00         NOP
009a  00         NOP
009b  00         NOP
009c  00         NOP
009d  00         NOP
009e  00         NOP
009f  00         NOP
00a0  00         NOP
00a1  00         NOP
00a2  00         NOP
00a3  00         NOP
00a4  00         NOP
00a5  00         NOP
00a6  00         NOP
00a7  00         NOP
00a8  00         NOP
00a9  00         NOP
00aa  00         NOP
00ab  00         NOP
00ac  00         NOP
00ad  00         NOP
00ae  00         NOP
00af  00         NOP
00b0  00         NOP
00b1  00         NOP
00b2  00         NOP
00b3  00         NOP
00b4  00         NOP
00b5  00         NOP
00b6  00         NOP
00b7  00         NOP
00b8  00         NOP
00b9  00         NOP
00ba  00         NOP
00bb  00         NOP
00bc  00         NOP
00bd  00         NOP
00be  00         NOP
00bf  00         NOP
00c0  00         NOP
00c1  00         NOP
00c2  00         NOP
00c3  00         NOP
00c4  00         NOP
00c5  00         NOP
00c6  00         NOP
00c7  00         NOP
00c8  00         NOP
00c9  00         NOP
00ca  00         NOP
00cb  00         NOP
00cc  00         NOP
00cd  00         NOP
00ce  00         NOP
00cf  00         NOP
00d0  00         NOP
00d1  00         NOP
00d2  00         NOP
00d3  00         NOP
00d4  00         NOP
00d5  00         NOP
00d6  00         NOP
00d7  00         NOP
00d8  00         NOP
00d9  00         NOP
00da  00         NOP
00db  00         NOP
00dc  00         NOP
00dd  00         NOP
00de  00         NOP
00df  00         NOP
00e0  00         NOP
00e1  00         NOP
00e2  00         NOP
00e3  00         NOP
00e4  00         NOP
00e5  00         NOP
00e6  00         NOP
00e7  ff         RST 7
00e8  14         INR D
00e9  0d         DCR C
00ea  c4 08 00   CNZ 0008
00ed  15         DCR D
00ee  08         db 08
00ef  9b         SBB E
00f0  13         INX DE
00f1  56         MOV D, M
00f2  13         INX DE
00f3  ca 11 9b   JZ 9b11
00f6  13         INX DE
00f7  15         DCR D
00f8  08         db 08
00f9  56         MOV D, M
00fa  13         INX DE
00fb  7e         MOV A, M
00fc  15         DCR D
00fd  14         INR D
00fe  0b         DCX BC
????:
00ff  00         NOP



DRAW_MAP:
    0100  0e 1f      MVI C, 1f                  ; Clear screen
    0102  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0105  21 d0 01   LXI HL, MAP_ADDR_TABLE (01d0)  ; Map addresses table
    0108  af         XRA A                      ; Load current map index
    0109  3a 40 02   LDA CURRENT_MAP (0240)
    010c  17         RAL

    010d  5f         MOV E, A                   ; Calculate the map address offset
    010e  16 00      MVI D, 00
    0110  19         DAD DE

    0111  7e         MOV A, M                   ; Read the map address and prepare map record address
    0112  32 41 02   STA MAP_RECORD_ADDR (0241)
    0115  23         INX HL
    0116  7e         MOV A, M
    0117  32 42 02   STA MAP_RECORD_ADDR+1 (0242)

    011a  21 43 02   LXI HL, GAME_BUF (0243)    ; Store the pointer to the game buffer at 0883
    011d  22 83 08   SHLD 0883

DRAW_MAP_NEXT_RECORD:
    0120  2a 41 02   LHLD MAP_RECORD_ADDR (0241)   ; Load next record address

    0123  7e         MOV A, M                   ; Repeat until 0x00 stop symbol is found
    0124  b7         ORA A
    0125  c8         RZ

    0126  cd a0 01   CALL GAME_SYMB_LOOKUP (01a0)

    0129  32 85 08   STA 0885                   ; Save map record byte #1 to 0885 (block type)

    012c  23         INX HL                     ; Copy map record byte #2 (Y1)
    012d  7e         MOV A, M
    012e  32 86 08   STA BLOCK_TOP_LINE (0886)

    0131  23         INX HL                     ; Copy map record byte #3 (Y2)
    0132  7e         MOV A, M
    0133  32 87 08   STA 0887

    0136  23         INX HL                     ; Copy map record byte #4 (X1)
    0137  7e         MOV A, M
    0138  32 88 08   STA 0888

    013b  23         INX HL                     ; Copy map record byte #5 (X2)
    013c  7e         MOV A, M
    013d  32 89 08   STA 0889

    0140  23         INX HL                     ; Save next record address
    0141  22 41 02   SHLD MAP_RECORD_ADDR (0241)

DRAW_MAP_NEXT_LINE:
    0144  3a 86 08   LDA BLOCK_TOP_LINE (0886)  ; Load block top-left coordinate to BC
    0147  47         MOV B, A
    0148  3a 88 08   LDA 0888
    014b  4f         MOV C, A

    014c  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Calculate top-left corner address in the game buffer
    014f  22 8a 08   SHLD BLOCK_TOP_LEFT_ADDR (088a)

    0152  3a 86 08   LDA BLOCK_TOP_LINE (0886)  ; Calculate Y2-Y1 difference (block height)
    0155  57         MOV D, A
    0156  3a 87 08   LDA 0887
    0159  92         SUB D
    015a  32 8c 08   STA BLOCK_HEIGHT_COUNTER (088c); And store to 088c

    015d  3a 88 08   LDA 0888                   ; Calculate X2-X1 difference (block width)
    0160  57         MOV D, A
    0161  3a 89 08   LDA 0889
    0164  92         SUB D
    0165  32 8d 08   STA BLOCK_WIDTH_COUNTER (088d) ; And store to 088d

    0168  2a 8a 08   LHLD BLOCK_TOP_LEFT_ADDR (088a); Load top-left address (in the game buffer) to DE
    016b  eb         XCHG

    016c  3a 88 08   LDA 0888                   ; Load top-left block screen coordinates to BC
    016f  4f         MOV C, A
    0170  3a 86 08   LDA BLOCK_TOP_LINE (0886)
    0173  47         MOV B, A

DRAW_MAP_NEXT_COLUMN:
    0174  3a 85 08   LDA 0885                   ; Store the symbol type in the game buffer
    0177  12         STAX DE

    0178  cd c4 11   CALL DRAW_BLOCK (11c4)     ; Draw the block on the screen as well

    017b  13         INX DE                     ; Advance coordinate horizontally (and game buf address)
    017c  0c         INR C

    017d  3a 8d 08   LDA BLOCK_WIDTH_COUNTER (088d) ; Decrease block widht counter
    0180  3d         DCR A
    0181  32 8d 08   STA BLOCK_WIDTH_COUNTER (088d)

    0184  fe ff      CPI A, ff                  ; Repeat until all width is filled
    0186  c2 74 01   JNZ DRAW_MAP_NEXT_COLUMN (0174)

    0189  3a 8c 08   LDA BLOCK_HEIGHT_COUNTER (088c); Advance to the next record when if all lines are drawn
    018c  b7         ORA A
    018d  ca 20 01   JZ DRAW_MAP_NEXT_RECORD (0120)

    0190  3a 86 08   LDA BLOCK_TOP_LINE (0886)  ; Bump Y coordinate
    0193  3c         INR A
    0194  32 86 08   STA BLOCK_TOP_LINE (0886)

    0197  c3 44 01   JMP DRAW_MAP_NEXT_LINE (0144)



???;
019a  1b         DCX DE
019b  59         MOV E, C
019c  00         NOP
019d  00         NOP

BLOCK_SYMBOL:
    019e  09         dw 00

?????
019f  00         NOP



; Calculate block symbol 
;
; Searches for the block symbol for value in A register, according to SYMBOLS_LOOKUP lookup table.
; Store found symbol in 019e
GAME_SYMB_LOOKUP:
    01a0  f5         PUSH PSW
    01a1  e5         PUSH HL
    01a2  d5         PUSH DE

    01a3  5f         MOV E, A                   ; Calculate offset in DE
    01a4  16 00      MVI D, 00
    01a6  21 b2 01   LXI HL, SYMBOLS_LOOKUP (01b2)
    01a9  19         DAD DE                     ; Calculate symbol address based on lookup table

    01aa  7e         MOV A, M                   ; Copy the symbol to 019e
    01ab  32 9e 01   STA BLOCK_SYMBOL (019e)

    01ae  d1         POP DE
    01af  e1         POP HL
    01b0  f1         POP PSW
    01b1  c9         RET


SYMBOLS_LOOKUP:
    01b2  20         db ' '                     ; 0x00 -> ' '  Space
    01b3  68         db 'X'                     ; 0x01 -> 'X'  Outer walls
    01b4  23         db '#'                     ; 0x02 -> '#'  Ladders
    01b5  5d         db ']'                     ; 0x03 -> ']'  door
    01b6  5b         db '['                     ; 0x04 -> '['  door
    01b7  5e         db '^'                     ; 0x05 -> '^'  Water
    01b8  1c         db '-'                     ; 0x06 -> '-'  Rope / Thin floor
    01b9  14         db 'm'                     ; 0x07 -> 'm'  Treasure
    01ba  14         db 'm'                     ; 0x08 -> 'm'  Treasure ?????
    01bb  5d         db ']'                     ; 0x09 -> ']'  ???
    01bc  5b         db '['                     ; 0x0a -> '['  ???
    01bd  25         db '%'                     ; 0x0b -> '%'  Floor / brick
    01be  3a         db ':'                     ; 0x0c -> ':'  Partially broken block
    01bf  2e         db '.'                     ; 0x0d -> '.'  Even more broken block
    01c0  20         db ' '                     ; 0x0e -> ' '  ???
    01c1  2e         db '.'                     ; 0x0f -> '.'  ???
    01c2  3a         db ':'                     ; 0x10 -> ':'  ???
    01c3  11         db '| ' ???                ; 0x11 -> '| '  opened door
    01c4  1e         db 'SP' ???                ; 0x12 -> 'SP'  ??? treasure
    01c5  09         db ???                     ; 0x13 -> ' '  Player symbol ???
    01c6  0b         db ???                     ; 0x14 -> ' '  Enemy symbol ???
    01c7  2d         db '-'                     ; 0x15 -> '-'  ???
    01c8  51         db 'Q'                     ; 0x16 -> 'Q'  ???
    01c9  40         db '@'                     ; 0x17 -> '@'  ???
    01ca  26         db '&'                     ; 0x18 -> '&'  ???
    01cb  2a         db '*'                     ; 0x19 -> '*'  ???
    01cc  3d         db '='                     ; 0x1a -> '='  ???
    01cd  2b         db '+'                     ; 0x1b -> '+'  ???
    01ce  3e         db '>'                     ; 0x1c -> '>'  ???
    01cf  3c         db '<'                     ; 0x1d -> '<'  ???


MAP_ADDR_TABLE:   ; Map offsets 
    01d0  b0 18      dw MAP_01 (18b0)
    01d2  35 0b      dw MAP_02 (0b35)
    01d4  87 19      dw MAP_03 (1987)
    01d6  bf 1a      dw MAP_04 (1abf)
    01d8  e0 1b      dw MAP_05 (1be0)
    01da  ec 1d      dw MAP_06 (1dec)
    01dc  d0 1f      dw MAP_07 (1fd0)
    01de  c8 21      dw MAP_08 (21c8)
    01e0  67 22      dw MAP_09 (2267)
    01e2  73 24      dw MAP_10 (2473)
    01e4  00 26      dw MAP_11 (2600)
    01e6  10 28      dw MAP_12 (2810)
    01e8  d0 29      dw MAP_13 (29d0)
    01ea  b0 2a      dw MAP_14 (2ab0)
    01ec  40 2c      dw MAP_15 (2c40)
    01ee  30 2d      dw MAP_16 (2d30)
    01f0  50 2e      dw MAP_17 (2e50)
    01f2  b0 2f      dw MAP_18 (2fb0)
    01f4  50 32      dw MAP_19 (3250)
    
01f6  00 00
01f8  00         NOP
01f9  00         NOP
01fa  00         NOP
01fb  00         NOP
01fc  00         NOP
01fd  00         NOP
01fe  00         NOP
01ff  00         NOP
0200  00         NOP

????:
0201  00         NOP
????:
0202  00         NOP
0203  00         NOP
0204  00         NOP
0205  00         NOP
0206  00         NOP
0207  00         NOP
0208  00         NOP
0209  00         NOP
020a  00         NOP
????:
020b  00         NOP
020c  00         NOP
020d  00         NOP
020e  00         NOP
020f  00         NOP
0210  00         NOP
????:
0211  00         NOP
0212  00         NOP
0213  00         NOP
0214  00         NOP
0215  00         NOP
0216  00         NOP
0217  00         NOP
0218  00         NOP
0219  00         NOP
021a  00         NOP
021b  00         NOP
021c  00         NOP
021d  00         NOP
021e  00         NOP
021f  00         NOP
0220  00         NOP
0221  00         NOP
0222  00         NOP
????:
0223  00         NOP
0224  00         NOP
0225  00         NOP
0226  00         NOP
0227  00         NOP
0228  00         NOP
0229  00         NOP
????:
022a  00         NOP
????:
022b  00         NOP
022c  00         NOP
????:
022d  00         NOP
022e  00         NOP
????:
022f  00         NOP
0230  00         NOP
????:
0231  00         NOP
0232  00         NOP
????:
0233  00         NOP
0234  00         NOP
0235  00         NOP
0236  00         NOP
????:
0237  00         NOP
0238  00         NOP
????:
0239  00         NOP
????:
023a  00         NOP
????:
023b  00         NOP
023c  00         NOP
023d  00         NOP
023e  00         NOP
023f  00         NOP

CURRENT_MAP:
    0240  00        db 0x00

MAP_RECORD_ADDR:
    0241  78 19     dw 1978 


GAME_BUF:
    0243  0x640 * 0x00     ; 25 lines by 64 symbols each

GAME_BUF_PTR:
    0883  43 02     db GAME_BUF (0243)

????:
0885  02         STAX BC

BLOCK_TOP_LINE:
    0886  05        db 0x05
????:
0887  05         DCR B
????:
0888  0a         LDAX BC
????:
0889  0b         DCX BC
????:

BLOCK_TOP_LEFT_ADDR:
    088a  8d 03     db 038d

BLOCK_HEIGHT_COUNTER:
    088c  00        db 0x00

BLOCK_WIDTH_COUNTER:
    088d  ff        db 0xff


; Clear the game buffer, by filling it with zeroes
;
; Clears the 64*25 game buffer
ZERO_GAME_BUF:
    088e  21 43 02   LXI HL, GAME_BUF (0243)    ; Start addr
    0891  11 82 08   LXI DE, GAME_BUF + 0x640 - 1 (0882); End addr
ZERO_GAME_BUF_LOOP:
    0894  af         XRA A
    0895  77         MOV M, A

    0896  23         INX HL
    0897  7b         MOV A, E
    0898  95         SUB L
    0899  7a         MOV A, D
    089a  9c         SBB H
    089b  d2 94 08   JNC ZERO_GAME_BUF_LOOP (0894)

    089e  c9         RET



????:
    089f  2a 41 02   LHLD MAP_RECORD_ADDR (0241)   ; Load the last record
    08a2  23         INX HL

    08a3  11 b1 08   LXI DE, MAP_MOBS (08b1)    ; Copy 13 bytes to 08b1 buffer ????
    08a6  06 0d      MVI B, 0d

????:
    08a8  7e         MOV A, M
    08a9  12         STAX DE
    08aa  23         INX HL
    08ab  13         INX DE
    08ac  05         DCR B
    08ad  c2 a8 08   JNZ 08a8

    08b0  c9         RET


MAP_MOBS:
PLAYER_START_Y:
    08b1  0f        db 0f
PLAYER_START_X:
    08b2  04        db 04

ENEMY_1_START_POS:
    08b3  01 2e 
ENEMY_2_START_POS:
    08b5  00 00
ENEMY_3_START_POS:
    08b7  00 00
ENEMY_4_START_POS:
    08b9  00 00

????:
08bb  00         NOP

MAP_EXIT_POS:
    08bc  01 35 


; Calculate a pointer to the block in the game buffer
;
; Arguments:
; B, C  - vert and horz logic coordinates of the block
;
; Return:
; HL    - pointer to the block in the game buffer
CALC_BLOCK_PTR:
    08be  f5         PUSH PSW
    08bf  d5         PUSH DE

    08c0  78         MOV A, B                   ; Limit B with 0x18 (maximum line number)
    08c1  fe 18      CPI A, 18
    08c3  da c8 08   JC CALC_BLOCK_PTR_1 (08c8)

    08c6  06 18      MVI B, 18

CALC_BLOCK_PTR_1:
    08c8  79         MOV A, C                   ; Limit C with 0x3f (maximum column number)
    08c9  fe 3f      CPI A, 3f
    08cb  da d0 08   JC CALC_BLOCK_PTR_2 (08d0)

    08ce  0e 3f      MVI C, 3f

CALC_BLOCK_PTR_2:
    08d0  af         XRA A
    08d1  11 00 00   LXI DE, 0000

    08d4  78         MOV A, B                   ; DE = 00bbbbbb bbcccccc
    08d5  1f         RAR
    08d6  57         MOV D, A

    08d7  7b         MOV A, E
    08d8  1f         RAR
    08d9  5f         MOV E, A

    08da  7a         MOV A, D
    08db  1f         RAR
    08dc  57         MOV D, A

    08dd  7b         MOV A, E
    08de  1f         RAR
    08df  81         ADD C
    08e0  5f         MOV E, A

    08e1  7a         MOV A, D
    08e2  ce 00      ACI A, 00

    08e4  2a 83 08   LHLD GAME_BUF_PTR (0883)   ; Add calculated offset to the game buffer address
    08e7  19         DAD DE

    08e8  d1         POP DE
    08e9  f1         POP PSW
    08ea  c9         RET


; Function to handle player's move
;
; The function handles 2 primary modes:
; - the player is falling down. In this case player falls until reaches a hard surface.
;   The player cannot move the figure until it reaches the surface.
; - the player is on hard surface already and can move to one of the directions. The function
;   checks the target block type, and handles all kinds of special blocks.
;
; In falling mode:
; - When the player is falling, it can break through thin floor and fall further (normally the player)
;   can walk over the thin floor (0x06 block type).
; - Player falls 3 of every 4 game ticks. Thus the player falls slower than enemies, which fall every 
;   game tick
;
; In walking mode (player is on a hard surface):
; - Player can move up, down, left, and right, if the target block allows
; - Player will fall down if the block below is empty, a water, or treasure box.
; - If the Player is on a ladder, it will stay on current cell regardless of the block below (not fall)
; 
; The following special blocks handled:
; - fake treasure boxes (block type 0x07) is just swallowed (removed from the map)
; - real treasure boxes (block type 0x08) is replaced with SP symbol, treasure counter is incremented,
;   a reward is added to the topmost line
; - left door (block type 0x03) passes the player coming from right to left, and blockes other way.
;   When player passes the door, it opens (replaced with 0x11 block type) and stay open.
; - right door (block type 0x04) passes the player coming from left to right, and blockes other way.
;   When player passes the door, it opens (replaced with 0x11 block type) and stay open.
; - left locked door (block type 0x09) can pass the player moving from right to left, but charges one
;   treasure point (previously gained by finding real treasure box 0x08). The door blocks moving other
;   direction. When player passes the door, it opens (replaced with 0x11 block type) and stay open.
; - right locked door (block type 0x0a) can pass the player moving from left to right, but charges one
;   treasure point (previously gained by finding real treasure box 0x08). The door blocks moving other
;   direction. When player passes the door, it opens (replaced with 0x11 block type) and stay open.
HANDLE_PLAYER_MOVE:
    08eb  3a d4 0a   LDA PLAYER_POS_Y (0ad4)    ; Load player position to BC
    08ee  47         MOV B, A
    08ef  3a d5 0a   LDA PLAYER_POS_X (0ad5)
    08f2  4f         MOV C, A

    08f3  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Calculate the pointer to the player's block in game buffer

    08f6  7e         MOV A, M                   ; Check if the player is on a ladder. In this case it is
    08f7  fe 02      CPI A, 02                  ; treated like the player is on a hard surface (regardless of
    08f9  ca 61 09   JZ PLAYER_ON_SURFACE (0961); the block type below), the player will not be falling

    08fc  04         INR B                      ; Get address of the block below the player
    08fd  cd be 08   CALL CALC_BLOCK_PTR (08be)

    0900  7e         MOV A, M                   ; Fall if the block below is empty
    0901  b7         ORA A
    0902  ca 19 09   JZ PLAYER_FALLS_DOWN (0919)
    0905  fe 07      CPI A, 07                  ; or is a fake treasure box
    0907  ca 19 09   JZ PLAYER_FALLS_DOWN (0919)
    090a  fe 08      CPI A, 08                  ; or is a real treasure box
    090c  ca 19 09   JZ PLAYER_FALLS_DOWN (0919)
    090f  fe 05      CPI A, 05                  ; or is a water
    0911  ca 19 09   JZ PLAYER_FALLS_DOWN (0919)

    0914  fe 0e      CPI A, 0e                  ; Other block types are treated as a surface
    0916  da 53 09   JC PLAYER_FALLS_DOWN_3 (0953)

PLAYER_FALLS_DOWN:
    0919  05         DCR B                      ; Go back to the player's block

    091a  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Restore block symbol under the player
    091d  7e         MOV A, M
    091e  cd c4 11   CALL DRAW_BLOCK (11c4)     

    0921  04         INR B                      ; Move to the next line

    0922  3a d6 0a   LDA FALLING_CYCLE (0ad6)   ; Skip every 4th falling cycle...
    0925  3c         INR A
    0926  e6 03      ANI A, 03
    0928  c2 2c 09   JNZ PLAYER_FALLS_DOWN_1 (092c)

    092b  05         DCR B                      ; and move player back up

PLAYER_FALLS_DOWN_1:
    092c  32 d6 0a   STA FALLING_CYCLE (0ad6)   ; Store the falling cycle number

    092f  78         MOV A, B
    0930  32 d4 0a   STA PLAYER_POS_Y (0ad4)

    0933  3e 13      MVI A, 13                  ; Draw player at the new position
    0935  cd c4 11   CALL DRAW_BLOCK (11c4)

    0938  32 d7 0a   STA PLAYER_IS_FALLING (0ad7)   ; Set flag that the player is falling

    093b  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Check if the new position has the treasure box
    093e  7e         MOV A, M
    093f  fe 07      CPI A, 07
    0941  c2 46 09   JNZ PLAYER_FALLS_DOWN_2 (0946)

    0944  36 00      MVI M, 00                  ; Swallow the fake treasure box

PLAYER_FALLS_DOWN_2:
    0946  fe 08      CPI A, 08                  ; Check if the new position is a true treasure box
    0948  c0         RNZ

    0949  36 12      MVI M, 12                  ; If yes, replace it with a SP symbol

    094b  3a d9 0a   LDA TREASURES_COUNT (0ad9) ; Increase treasure counter
    094e  3c         INR A
    094f  32 d9 0a   STA TREASURES_COUNT (0ad9)

    0952  c9         RET                        ; Do not we need to call HANDLE_TREASURE ???


PLAYER_FALLS_DOWN_3:
    0953  3a d7 0a   LDA PLAYER_IS_FALLING (0ad7)   ; Normally player can walk through thin floor,
    0956  b7         ORA A                          ; but will break through when falling
    0957  ca 60 09   JZ PLAYER_FALLS_DOWN_4 (0960)

    095a  7e         MOV A, M                   ; Check if the block below is a thin floor
    095b  fe 06      CPI A, 06
    095d  ca 19 09   JZ PLAYER_FALLS_DOWN (0919)

PLAYER_FALLS_DOWN_4:
    0960  05         DCR B                      ; Restore the previous Y coordinate


; The player is on the hard surface, and not falling. Depending on the pressed key the
; player may move towards selected direction
PLAYER_ON_SURFACE:
    0961  af         XRA A                      ; Reset 'Player is falling flag'
    0962  32 d7 0a   STA PLAYER_IS_FALLING (0ad7)

    0965  3a d8 0a   LDA PRESSED_KEY (0ad8)
    0968  fe 08      CPI A, 08
    096a  ca 7f 09   JZ PLAYER_MOVE_LEFT (097f)
    096d  fe 18      CPI A, 18
    096f  ca e3 09   JZ PLAYER_MOVE_RIGHT (09e3)
    0972  fe 19      CPI A, 19
    0974  ca 49 0a   JZ PLAYER_MOVE_UP (0a49)
    0977  fe 1a      CPI A, 1a
    0979  ca 94 0a   JZ PLAYER_MOVE_DOWN (0a94)

    097c  c3 d3 0a   JMP PLAYER_MOVE_EXIT (0ad3)




PLAYER_MOVE_LEFT:
    097f  0d         DCR C                      ; Calculate address of the block to the left
    0980  cd be 08   CALL CALC_BLOCK_PTR (08be)

    0983  7e         MOV A, M                   ; Player can move if the block to the left is empty
    0984  b7         ORA A
    0985  ca d0 09   JZ PLAYER_MOVE_LEFT_FINALIZE (09d0)

    0988  fe 02      CPI A, 02                  ; ... or is ladder
    098a  ca d0 09   JZ PLAYER_MOVE_LEFT_FINALIZE (09d0)

    098d  fe 06      CPI A, 06                  ; ... or is a thin floor
    098f  ca d0 09   JZ PLAYER_MOVE_LEFT_FINALIZE (09d0)

    0992  fe 03      CPI A, 03                  ; If there is a left door...
    0994  c2 9c 09   JNZ PLAYER_MOVE_LEFT_1 (099c)

    0997  36 11      MVI M, 11                  ; ... open it

    0999  c3 d0 09   JMP PLAYER_MOVE_LEFT_FINALIZE (09d0)

PLAYER_MOVE_LEFT_1:
    099c  fe 05      CPI A, 05                  ; Player can move if there is a water
    099e  ca d0 09   JZ PLAYER_MOVE_LEFT_FINALIZE (09d0)

    09a1  fe 07      CPI A, 07                  ; If there is a fake treasure ...
    09a3  c2 ab 09   JNZ PLAYER_MOVE_LEFT_2 (09ab)

    09a6  36 00      MVI M, 00                  ; ... swallow it
    09a8  c3 d0 09   JMP PLAYER_MOVE_LEFT_FINALIZE (09d0)

PLAYER_MOVE_LEFT_2:
    09ab  fe 08      CPI A, 08                  ; If there is a real treasure - handle it
    09ad  c2 b6 09   JNZ PLAYER_MOVE_LEFT_3 (09b6)
    09b0  cd 96 18   CALL HANDLE_TREASURE (1896)
    09b3  c3 d0 09   JMP PLAYER_MOVE_LEFT_FINALIZE (09d0)

PLAYER_MOVE_LEFT_3:
    09b6  fe 09      CPI A, 09                  ; Check if there is a locked left door
    09b8  c2 cb 09   JNZ PLAYER_MOVE_LEFT_4 (09cb)

    09bb  3a d9 0a   LDA TREASURES_COUNT (0ad9) ; Can pass only if a treasure was found earlier
    09be  b7         ORA A
    09bf  ca d3 0a   JZ PLAYER_MOVE_EXIT (0ad3)

    09c2  3d         DCR A                      ; Decrease treasure counter
    09c3  32 d9 0a   STA TREASURES_COUNT (0ad9)

    09c6  36 11      MVI M, 11                  ; Mark the door open

    09c8  c3 d0 09   JMP PLAYER_MOVE_LEFT_FINALIZE (09d0)

PLAYER_MOVE_LEFT_4:
    09cb  fe 0e      CPI A, 0e                  ; Can't move if there is blocking block ahead
    09cd  da d3 0a   JC PLAYER_MOVE_EXIT (0ad3)

PLAYER_MOVE_LEFT_FINALIZE:
    09d0  0c         INR C                      ; Restore symbol under player's position
    09d1  cd be 08   CALL CALC_BLOCK_PTR (08be)
    09d4  7e         MOV A, M
    09d5  cd c4 11   CALL DRAW_BLOCK (11c4)

    09d8  0d         DCR C                      ; Move the player symbol one cell left
    09d9  3e 13      MVI A, 13
    09db  cd c4 11   CALL DRAW_BLOCK (11c4)

    09de  79         MOV A, C                   ; Store the new player position
    09df  32 d5 0a   STA PLAYER_POS_X (0ad5)

    09e2  c9         RET



PLAYER_MOVE_RIGHT:
    09e3  0c         INR C                      ; Check the block right to the player
    09e4  cd be 08   CALL CALC_BLOCK_PTR (08be)

    09e7  7e         MOV A, M                   ; Player can move if the block to the right is empty
    09e8  b7         ORA A
    09e9  ca 34 0a   JZ PLAYER_MOVE_RIGHT_FINALIZE (0a34)

    09ec  fe 02      CPI A, 02                  ; ... or is a ladder
    09ee  ca 34 0a   JZ PLAYER_MOVE_RIGHT_FINALIZE (0a34)

    09f1  fe 06      CPI A, 06                  ; ... or a thin floor
    09f3  ca 34 0a   JZ PLAYER_MOVE_RIGHT_FINALIZE (0a34)

    09f6  fe 04      CPI A, 04                  ; If this is a right door...
    09f8  c2 00 0a   JNZ PLAYER_MOVE_RIGHT_1 (0a00)

    09fb  36 11      MVI M, 11                  ; ... open it
    09fd  c3 34 0a   JMP PLAYER_MOVE_RIGHT_FINALIZE (0a34)

PLAYER_MOVE_RIGHT_1:
    0a00  fe 05      CPI A, 05                  ; Can move also if the target block is water
    0a02  ca 34 0a   JZ PLAYER_MOVE_RIGHT_FINALIZE (0a34)

    0a05  fe 07      CPI A, 07                  ; If the block to the right is a fake treasure - swallow it
    0a07  c2 0f 0a   JNZ PLAYER_MOVE_RIGHT_2 (0a0f)

    0a0a  36 00      MVI M, 00
    0a0c  c3 34 0a   JMP PLAYER_MOVE_RIGHT_FINALIZE (0a34)

PLAYER_MOVE_RIGHT_2:
    0a0f  fe 08      CPI A, 08                  ; If this is a real treasure - handle it
    0a11  c2 1a 0a   JNZ PLAYER_MOVE_RIGHT_3 (0a1a)
    0a14  cd 96 18   CALL HANDLE_TREASURE (1896)
    0a17  c3 34 0a   JMP PLAYER_MOVE_RIGHT_FINALIZE (0a34)

PLAYER_MOVE_RIGHT_3:
    0a1a  fe 0a      CPI A, 0a                  ; If this is a locked door ...
    0a1c  c2 2f 0a   JNZ PLAYER_MOVE_RIGHT_4 (0a2f)

    0a1f  3a d9 0a   LDA TREASURES_COUNT (0ad9) ; Check if player has enough treasures to open it
    0a22  b7         ORA A
    0a23  ca d3 0a   JZ PLAYER_MOVE_EXIT (0ad3)

    0a26  3d         DCR A                      ; Decrement treasures count
    0a27  32 d9 0a   STA TREASURES_COUNT (0ad9)

    0a2a  36 11      MVI M, 11                  ; Mark the door opened
    0a2c  c3 34 0a   JMP PLAYER_MOVE_RIGHT_FINALIZE (0a34)

PLAYER_MOVE_RIGHT_4:
    0a2f  fe 0e      CPI A, 0e                  ; Check if the block is blocking
    0a31  da d3 0a   JC PLAYER_MOVE_EXIT (0ad3)

PLAYER_MOVE_RIGHT_FINALIZE:
    0a34  0d         DCR C                      ; Restore symbol under the player
    0a35  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0a38  7e         MOV A, M
    0a39  cd c4 11   CALL DRAW_BLOCK (11c4)

    0a3c  0c         INR C                      ; Draw the player at the new position
    0a3d  3e 13      MVI A, 13
    0a3f  cd c4 11   CALL DRAW_BLOCK (11c4)

    0a42  79         MOV A, C                   ; Store the new position
    0a43  32 d5 0a   STA PLAYER_POS_X (0ad5)

    0a46  c3 d3 0a   JMP PLAYER_MOVE_EXIT (0ad3)



PLAYER_MOVE_UP:
    0a49  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Check we are still on the ladder
    0a4c  7e         MOV A, M
    0a4d  fe 02      CPI A, 02
    0a4f  c2 d3 0a   JNZ PLAYER_MOVE_EXIT (0ad3); If not - exit

    0a52  05         DCR B                      ; Get the block type above
    0a53  cd be 08   CALL CALC_BLOCK_PTR (08be)

    0a56  7e         MOV A, M                   ; Can move up if the block above is empty
    0a57  b7         ORA A
    0a58  ca 7f 0a   JZ PLAYER_MOVE_UP_FINALIZE (0a7f)

    0a5b  fe 02      CPI A, 02                  ; Can move up if the block above is ladder
    0a5d  ca 7f 0a   JZ PLAYER_MOVE_UP_FINALIZE (0a7f)

    0a60  fe 05      CPI A, 05                  ; Can move up if the block above is a water ??????
    0a62  ca 7f 0a   JZ PLAYER_MOVE_UP_FINALIZE (0a7f)

    0a65  fe 07      CPI A, 07                  ; Check if the block above is a fake treasure box
    0a67  c2 6f 0a   JNZ PLAYER_MOVE_UP_1 (0a6f)

    0a6a  36 00      MVI M, 00                  ; If block above is a treasure - swallow it
    0a6c  c3 7f 0a   JMP PLAYER_MOVE_UP_FINALIZE (0a7f)

PLAYER_MOVE_UP_1:
    0a6f  fe 08      CPI A, 08                  ; Check if the block above is a real treasure box
    0a71  c2 7a 0a   JNZ PLAYER_MOVE_UP_2 (0a7a)

    0a74  cd 96 18   CALL HANDLE_TREASURE (1896); If yes - handle it
    0a77  c3 7f 0a   JMP PLAYER_MOVE_UP_FINALIZE (0a7f)

PLAYER_MOVE_UP_2:
    0a7a  fe 0e      CPI A, 0e                  ; Cannot move up if above is a hard surface
    0a7c  da d3 0a   JC PLAYER_MOVE_EXIT (0ad3)

PLAYER_MOVE_UP_FINALIZE:
    0a7f  04         INR B                      ; Draw the block under the player
    0a80  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0a83  7e         MOV A, M
    0a84  cd c4 11   CALL DRAW_BLOCK (11c4)

    0a87  05         DCR B                      ; Draw the player symbol on the block above
    0a88  3e 13      MVI A, 13
    0a8a  cd c4 11   CALL DRAW_BLOCK (11c4)

    0a8d  78         MOV A, B                   ; Update the player position
    0a8e  32 d4 0a   STA PLAYER_POS_Y (0ad4)

    0a91  c3 d3 0a   JMP PLAYER_MOVE_EXIT (0ad3)



PLAYER_MOVE_DOWN:
    0a94  04         INR B                      ; Load the block below
    0a95  cd be 08   CALL CALC_BLOCK_PTR (08be)

    0a98  7e         MOV A, M                   ; Can move down, if the block below is empty
    0a99  b7         ORA A
    0a9a  ca c1 0a   JZ PLAYER_MOVE_DOWN_3 (0ac1)

    0a9d  fe 02      CPI A, 02                  ; Valid move also if below is a ladder
    0a9f  ca c1 0a   JZ PLAYER_MOVE_DOWN_3 (0ac1)

    0aa2  fe 05      CPI A, 05                  ; Valid move also if below is a water
    0aa4  ca c1 0a   JZ PLAYER_MOVE_DOWN_3 (0ac1)

    0aa7  fe 07      CPI A, 07                  ; Check if below is a fake treasure
    0aad  c2 b1 0a   JNZ PLAYER_MOVE_DOWN_1 (0ab1)

    0aac  36 00      MVI M, 00                  ; If yes - just swallow it
    0aae  c3 c1 0a   JMP PLAYER_MOVE_DOWN_3 (0ac1)

PLAYER_MOVE_DOWN_1:
    0ab1  fe 08      CPI A, 08                  ; If below is a real treasure - handle it
    0ab3  c2 bc 0a   JNZ PLAYER_MOVE_DOWN_2 (0abc)

    0ab6  cd 96 18   CALL HANDLE_TREASURE (1896)
    0ab9  c3 c1 0a   JMP PLAYER_MOVE_DOWN_3 (0ac1)

PLAYER_MOVE_DOWN_2:
    0abc  fe 0e      CPI A, 0e                  ; We cannot move down if below is a hadr surface
    0abe  da d3 0a   JC PLAYER_MOVE_EXIT (0ad3)

PLAYER_MOVE_DOWN_3:
    0ac1  05         DCR B                      ; Draw the block under the player
    0ac2  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0ac5  7e         MOV A, M
    0ac6  cd c4 11   CALL DRAW_BLOCK (11c4)

    0ac9  04         INR B                      ; Draw the player symbol on the block below
    0aca  3e 13      MVI A, 13
    0acc  cd c4 11   CALL DRAW_BLOCK (11c4)

    0acf  78         MOV A, B                   ; And save the new position
    0ad0  32 d4 0a   STA PLAYER_POS_Y (0ad4)

PLAYER_MOVE_EXIT:
    0ad3  c9         RET


PLAYER_POS:
PLAYER_POS_Y:
    0ad4  15        db 0x15
PLAYER_POS_X:
    0ad5  08        db 0x08

FALLING_CYCLE:
    0ad6  01        db 0x00

PLAYER_IS_FALLING:
    0ad7  00        db 0x00

PRESSED_KEY:
    0ad8    3a      db 0x3a

TREASURES_COUNT:
    0ad9  00        db 00




GAME_START:
    0ada  af         XRA A                      ; Reset treasures counter
    0adb  32 d9 0a   STA TREASURES_COUNT (0ad9)

    0ade  cd 8e 08   CALL ZERO_GAME_BUF (088e)
    0ae1  cd 00 01   CALL DRAW_MAP (0100)
    0ae4  cd 9f 08   CALL 089f                  ; ???? Copy 13 bytes from the map data to some block

    0ae7  3a b1 08   LDA PLAYER_START_Y (08b1)  ; Set initial player coordinates Y
    0aea  32 d4 0a   STA PLAYER_POS_Y (0ad4)

    0aed  3a b2 08   LDA PLAYER_START_X (08b2)  ; Set initial player coordinates X
    0af0  32 d5 0a   STA PLAYER_POS_X (0ad5)

    0af3  cd 86 15   CALL RESET_BROKEN_BRICKS (1586); Zero the array of broken bricks
    0af6  cd 68 11   CALL INIT_ENEMY_POS (1168) ; Initialize enemies

GAME_LOOP:
    0af9  cd 1b f8   CALL MONITOR_SCAN_KBD (f81b)   ; Check if there is a keyboard press, store in 0ad8
    0afc  32 d8 0a   STA PRESSED_KEY (0ad8)

    0aff  cd eb 08   CALL HANDLE_PLAYER_MOVE (08eb)
    0b02  cd 39 10   CALL HANDLE_ENEMIES (1039)
    0b05  cd 81 11   CALL CHECK_PLAYER_MEETS_ENEMY (1181)
    0b08  cd a1 15   CALL GAME_DELAY (15a1)
    0b0b  cd 46 15   CALL HANDLE_ARROWS (1546)
    0b0e  cd 46 15   CALL HANDLE_ARROWS (1546)
    0b11  cd c7 15   CALL CHECK_MAP_EXIT (15c7)

    0b14  3a c3 11   LDA PLAYER_DEAD (11c3)     ; If player has died - restart the game
    0b17  b7         ORA A
    0b18  c2 da 0a   JNZ GAME_START (0ada)

    0b1b  3a d4 0a   LDA PLAYER_POS_Y (0ad4)    ; Get the block at player's position
    0b1e  47         MOV B, A
    0b1f  3a d5 0a   LDA PLAYER_POS_X (0ad5)
    0b22  4f         MOV C, A
    0b23  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0b26  7e         MOV A, M

    0b27  fe 05      CPI A, 05                  ; If the player is in water - restart the game
    0b29  ca da 0a   JZ GAME_START (0ada)

    0b2c  78         MOV A, B                   ; If the player falls out of the screen - restart the game
    0b2d  fe 18      CPI A, 18
    0b2f  d2 da 0a   JNC GAME_START (0ada)

    0b32  c3 f9 0a   JMP GAME_LOOP (0af9)


MAP_02:
    0b35  01 01 16 00 01
    0b3a  01 16 16 00 3f
    0b3f  01 01 14 03 03
    0b44  01 01 16 1e 1f
    0b49  05 16 16 0a 17
    0b4e  0b 01 01 04 1d
    0b53  02 12 15 09 09
    0b58  0b 14 14 0a 13
    0b5d  01 17 17 00 3f
    0b62  06 14 14 0e 0e
    0b67  06 14 14 12 12
    0b6c  06 12 12 08 08
    0b71  0b 12 12 0a 14
    0b76  06 12 12 0e 0e
    0b7b  06 12 12 12 12
    0b80  0b 10 10 08 0d
    0b85  06 10 10 0e 0e
    0b8a  02 0e 0f 09 09
    0b8f  0b 0e 0e 04 08
    0b94  06 0e 0e 05 06
    0b99  02 03 0d 04 04
    0b9e  07 10 10 04 04
    0ba3  07 12 12 04 04
    0ba8  0b 11 11 04 05
    0bad  0b 13 13 04 06
    0bb2  0b 0c 0c 07 11
    0bb7  06 0c 0c 0c 0c
    0bbc  07 0b 0b 11 11
    0bc1  0b 0c 0c 13 16
    0bc6  07 0b 0b 13 13
    0bcb  02 0c 11 0f 0f
    0bd0  0b 09 09 06 0e
    0bd5  06 09 09 0c 0c
    0bda  0b 0a 0a 0e 15
    0bdf  07 09 09 11 11
    0be4  02 03 0b 09 09
    0be9  0b 03 05 05 06
    0bee  0b 05 05 08 08
    0bf3  06 05 05 07 07
    0bf8  0b 04 04 0a 1d
    0bfd  0b 03 03 0a 0b
    0c02  06 04 04 0c 0c
    0c07  0b 03 03 14 18
    0c0c  02 03 03 13 13
    0c11  06 04 04 19 19
    0c16  02 04 06 0e 0e
    0c1b  08 06 06 0d 0d
    0c20  0b 07 07 0d 15
    0c25  0b 08 08 15 17
    0c2a  02 06 07 16 16
    0c2f  02 08 0e 18 18
    0c34  0b 0f 0f 10 18
    0c39  0b 0e 0e 13 15
    0c3e  06 0f 0f 12 12
    0c43  06 0f 0f 16 16
    0c48  02 01 0d 1c 1c
    0c4d  0a 05 05 18 18
    0c52  0b 06 06 17 1c
    0c57  06 09 09 19 1b
    0c5c  0b 0e 0e 1c 1c
    0c61  02 0e 12 1b 1b
    0c66  0b 11 11 17 19
    0c6b  0b 13 13 16 1b
    0c70  02 11 15 18 18
    0c75  0b 11 15 1d 1d
    0c7a  07 10 10 1d 1d
    0c7f  0b 11 11 1c 1c
    0c84  07 14 14 1c 1c
    0c89  0b 15 15 1b 1c
    0c8e  0b 16 16 22 3d
    0c93  05 16 16 38 3c
    0c98  01 01 16 3e 3f
    0c9d  01 01 01 31 3d
    0ca2  01 01 01 22 2e
    0ca7  01 01 14 21 21
    0cac  02 03 15 22 22
    0cb1  01 11 12 23 32
    0cb6  05 11 11 26 31
    0cbb  01 0f 10 32 32
    0cc0  06 0f 0f 31 31
    0cc5  0b 0f 0f 2c 30
    0cca  0b 0f 0f 24 2a
    0ccf  06 0f 0f 25 27
    0cd4  02 09 0e 24 24
    0cd9  0b 09 09 25 25
    0cde  06 09 09 26 26
    0ce3  0b 03 05 23 25
    0ce8  07 04 04 24 24
    0ced  06 04 04 26 27
    0cf2  07 06 06 25 25
    0cf7  0b 07 07 25 25
    0cfc  01 0d 0d 26 30
    0d01  06 0d 0d 28 28
    0d06  06 0d 0d 2c 2c
    0d0b  02 06 0c 30 30
    0d10  01 06 0b 2f 2f
    0d15  06 06 06 2c 2e
    0d1a  01 08 08 2d 2d
    0d1f  02 08 0a 2e 2e
    0d24  0b 0b 0b 27 2e
    0d29  06 0b 0b 28 28
    0d2e  06 0b 0b 2c 2c
    0d33  0b 02 02 27 28
    0d38  01 02 08 29 29
    0d3d  0b 03 05 29 29
    0d42  06 05 05 27 28
    0d47  02 03 08 2a 2a
    0d4c  0b 09 09 29 2b
    0d51  06 09 09 2c 2c
    0d56  0b 03 04 2b 2b
    0d5b  01 02 03 2c 2c
    0d60  08 02 02 2b 2b
    0d65  07 03 03 2d 2d
    0d6a  06 04 04 2d 2e
    0d6f  0b 03 04 2f 31
    0d74  0b 04 04 33 35
    0d79  0b 05 05 33 34
    0d7e  0b 06 06 34 3b
    0d83  06 06 06 36 36
    0d88  0a 05 05 37 37
    0d8d  0b 02 02 34 38
    0d92  0b 03 03 38 3d
    0d97  0b 04 04 37 38
    0d9c  02 03 05 39 39
    0da1  02 01 02 3c 3c
    0da6  02 03 08 32 32
    0dab  06 08 08 33 3c
    0db0  02 05 15 3d 3d
    0db5  06 14 14 37 3c
    0dba  0b 14 14 24 35
    0dbf  01 15 15 2a 2a
    0dc4  02 14 14 2b 2b
    0dc9  0b 13 13 34 34
    0dce  01 11 12 34 34
    0dd3  07 10 10 34 34
    0dd8  0b 0a 0e 34 37
    0ddd  0b 0a 0a 32 33
    0de2  0b 0c 0d 33 33
    0de7  06 0c 0c 32 32
    0dec  07 0b 0b 33 33
    0df1  01 0b 0b 35 35
    0df6  01 0e 0e 35 35
    0dfb  0b 0a 0a 38 38
    0e00  01 0a 0b 39 3b
    0e05  05 0a 0a 3a 3a
    0e0a  06 0a 0a 3c 3c
    0e0f  06 0e 0e 38 38
    0e14  0b 0c 0f 39 3b
    0e19  07 0d 0d 3a 3a
    0e1e  0b 10 10 3a 3b
    0e23  07 11 11 3b 3b
    0e28  0b 10 10 38 38
    0e2d  0b 11 11 38 39
    0e32  0b 12 12 38 3b
    0e37  02 0a 15 36 36
    
    0e3c  00                                    ; Separator

    0e3d  01 02                                 ; Player start position
    0e3f  01 30                                 ; Enemy 1 start position
    0e41  01 2f                                 ; Enemy 2 start position
    0e43  02 1a                                 ; Enemy 3 start position
    0e45  00 00                                 ; No enemy 4
    0e47  03                                    ; Number of enemies
    0e48  01 3c                                 ; Exit location



; Handle a particular enemy move
;
; The function takes the enemy position (0faa), compares it with the player's position,
; and decides where to move. The new position is stored to 0fae
;
; The function handles 2 cases:
; - the enemy is above an empty cell and is falling
; - the enemy is on a surface or ladder, and is not falling
;
; When the enemy is falling:
; - enemy falls every tick (compared to player which falls little slower - 3 of 4 ticks)
; - enemy breaks through thin floors when falling (although will not fall when walking over)
;
; When enemy is on a surface or ladder:
; - Enemy tries to match X position with the player, by moving left and right if map allows
; - If enemy is exactly above or below the enemy, or just can't move horizontally, the enemy tries 
;   to use ladder if available
; - The enemy moves 3 of 4 game ticks (little slower than player)
HANDLE_ENEMY_MOVE:
    0e4a  3a aa 0f   LDA PREV_ENEMY_POS (0faa)  ; Load enemy position to BC
    0e4d  47         MOV B, A
    0e4e  3a ab 0f   LDA PREV_ENEMY_POS+1 (0fab)
    0e51  4f         MOV C, A

    0e52  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Get the block type at enemy position
    0e55  7e         MOV A, M

    0e56  fe 02      CPI A, 02                  ; Ladder is treated as a hard surface, the enemy will 
    0e58  ca 9a 0e   JZ ENEMY_ON_SURFACE (0e9a) ; not fall

    0e5b  04         INR B                      ; Get the block type below the enemy
    0e5c  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0e5f  7e         MOV A, M

    0e60  b7         ORA A                      ; Enemy will fall if the block below is empty
    0e61  ca 8c 0e   JZ ENEMY_FALLING (0e8c)

    0e64  fe 05      CPI A, 05                  ; ... or a water
    0e66  ca 8c 0e   JZ ENEMY_FALLING (0e8c)

    0e69  fe 07      CPI A, 07                  ; ... or a fake treasure box
    0e6b  ca 8c 0e   JZ ENEMY_FALLING (0e8c)

    0e6e  fe 08      CPI A, 08                  ; ... or a real treasure box
    0e70  ca 8c 0e   JZ ENEMY_FALLING (0e8c)

    0e73  fe 0e      CPI A, 0e                  ; Some other types of blocks are also treated as empty
    0e75  d2 8c 0e   JNC ENEMY_FALLING (0e8c)

    0e78  05         DCR B                      ; Revert the enemy position

    0e79  3a ac 0f   LDA ENEMY_IS_FALLING (0fac); If the enemy is falling
    0e7c  b7         ORA A
    0e7d  ca 9a 0e   JZ ENEMY_ON_SURFACE (0e9a)

    0e80  04         INR B                      ; Get the block type underneath the enemy
    0e81  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0e84  7e         MOV A, M

    0e85  05         DCR B

    0e86  fe 06      CPI A, 06                  ; The enemy will fall through the thin floor 
    0e88  c2 9a 0e   JNZ ENEMY_ON_SURFACE (0e9a); (though walking above the thin floor is fine)

    0e8b  04         INR B

ENEMY_FALLING:
    0e8c  78         MOV A, B                   ; Store the new enemy location
    0e8d  32 ae 0f   STA NEW_ENEMY_POS (0fae)
    0e90  79         MOV A, C
    0e91  32 af 0f   STA NEW_ENEMY_POS + 1 (0faf)

    0e94  3e 01      MVI A, 01                  ; Raise the flag the enemy is falling
    0e96  32 ac 0f   STA ENEMY_IS_FALLING (0fac)

    0e99  c9         RET



ENEMY_ON_SURFACE:
    0e9a  af         XRA A                      ; Clear the enemy is falling flag
    0e9b  32 ac 0f   STA ENEMY_IS_FALLING (0fac)

    0e9e  3a d4 0a   LDA PLAYER_POS_Y (0ad4)    ; Load the player's position to DE
    0ea1  57         MOV D, A
    0ea2  3a d5 0a   LDA PLAYER_POS_X (0ad5)
    0ea5  5f         MOV E, A

    0ea6  b9         CMP C                      ; Compare player's and enemy X position
    0ea7  d2 eb 0e   JNC ENEMY_MOVE_RIGHT (0eeb); Enemy is on the left to the player ?

    0eaa  0d         DCR C                      ; Enemy is on the right to the player. Move it to the left

    0eab  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Get type of the block left to the enemy
    0eae  7e         MOV A, M

    0eaf  b7         ORA A                      ; Enemy can move if the block is empty
    0eb0  ca d5 0e   JZ ENEMY_MOVE_LEFT_1 (0ed5)

    0eb3  fe 02      CPI A, 02                  ; ... or it is a ladder
    0eb5  ca d5 0e   JZ ENEMY_MOVE_LEFT_1 (0ed5)

    0eb8  fe 05      CPI A, 05                  ; ... or it is a water
    0eba  ca d5 0e   JZ ENEMY_MOVE_LEFT_1 (0ed5)

    0ebd  fe 06      CPI A, 06                  ; ... or it is a thin floor
    0ebf  ca d5 0e   JZ ENEMY_MOVE_LEFT_1 (0ed5)

    0ec2  fe 07      CPI A, 07                  ; ... or it is a fake treasure box
    0ec4  ca d5 0e   JZ ENEMY_MOVE_LEFT_1 (0ed5)

    0ec7  fe 08      CPI A, 08                  ; ... or it is a real treasure box
    0ec9  ca d5 0e   JZ ENEMY_MOVE_LEFT_1 (0ed5)

    0ecc  fe 0e      CPI A, 0e                  ; ... or this is another type of 'empty' blocks
    0ece  d2 d5 0e   JNC ENEMY_MOVE_LEFT_1 (0ed5)

    0ed1  0c         INR C                      ; Otherwise (we hit blocking cell) revert the coordinate
    0ed2  c3 eb 0e   JMP ENEMY_MOVE_RIGHT (0eeb)

ENEMY_MOVE_LEFT_1:
    0ed5  3a ad 0f   LDA 0fad                   ; Enemy will move in 3 of every 4 game ticks.
    0ed8  3c         INR A
    0ed9  e6 03      ANI A, 03
    0edb  32 ad 0f   STA 0fad
    0ede  c2 e2 0e   JNZ ENEMY_MOVE_STORE_POSITION (0ee2)

    0ee1  0c         INR C                      ; Enemy will not move every 4th tick

ENEMY_MOVE_STORE_POSITION:
    0ee2  78         MOV A, B                   ; Store the calculated enemy position
    0ee3  32 ae 0f   STA NEW_ENEMY_POS (0fae)
    0ee6  79         MOV A, C
    0ee7  32 af 0f   STA NEW_ENEMY_POS + 1 (0faf)
    0eea  c9         RET

ENEMY_MOVE_RIGHT:
    0eeb  79         MOV A, C                   ; Compare enemy and player'x X coordinate
    0eec  bb         CMP E
    0eed  d2 2b 0f   JNC ENEMY_MOVE_UP (0f2b)

    0ef0  0c         INR C                      ; Enemy is left to the player. Move enemy right.

    0ef1  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Get the block type right to the enemy
    0ef4  7e         MOV A, M

    0ef5  b7         ORA A                      ; Enemy can move if the block is empty
    0ef6  ca 1b 0f   JZ ENEMY_MOVE_RIGHT_1 (0f1b)

    0ef9  fe 02      CPI A, 02                  ; ... or it is a ladder
    0efb  ca 1b 0f   JZ ENEMY_MOVE_RIGHT_1 (0f1b)

    0efe  fe 06      CPI A, 06                  ; ... or it is a thin floor
    0f00  ca 1b 0f   JZ ENEMY_MOVE_RIGHT_1 (0f1b)

    0f03  fe 05      CPI A, 05                  ; ... or it is a water
    0f05  ca 1b 0f   JZ ENEMY_MOVE_RIGHT_1 (0f1b)

    0f08  fe 07      CPI A, 07                  ; ... or it is a fake treasure box
    0f0a  ca 1b 0f   JZ ENEMY_MOVE_RIGHT_1 (0f1b)

    0f0d  fe 08      CPI A, 08                  ; ... or it is a real treasure box
    0f0f  ca 1b 0f   JZ ENEMY_MOVE_RIGHT_1 (0f1b)

    0f12  fe 0e      CPI A, 0e                  ; Some other types are blocking the enemy
    0f14  d2 1b 0f   JNC ENEMY_MOVE_RIGHT_1 (0f1b)

    0f17  0d         DCR C                      ; Enemy can't move, revert its coordinate
    0f18  c3 2b 0f   JMP ENEMY_MOVE_UP (0f2b)

ENEMY_MOVE_RIGHT_1:
    0f1b  3a ad 0f   LDA 0fad                   ; Enemy will move 3 of 4 game ticks
    0f1e  3c         INR A
    0f1f  e6 03      ANI A, 03
    0f21  32 ad 0f   STA 0fad
    0f24  c2 e2 0e   JNZ ENEMY_MOVE_STORE_POSITION (0ee2)

    0f27  0d         DCR C                      ; Every 4th tick the enemy will not move

    0f28  c3 e2 0e   JMP ENEMY_MOVE_STORE_POSITION (0ee2)

ENEMY_MOVE_UP:
    0f2b  7a         MOV A, D                   ; We are here if Player's and enemy's X coordinate equal
    0f2c  b8         CMP B                      ; Compare Y coordinates.
    0f2d  d2 6f 0f   JNC ENEMY_MOVE_DOWN (0f6f)

    0f30  cd be 08   CALL CALC_BLOCK_PTR (08be) ; The enemy is below player. Get block of the enemy.
    0f33  7e         MOV A, M

    0f34  fe 02      CPI A, 02                  ; The only way for the enemy to reach the player is to climb
    0f36  c2 6f 0f   JNZ ENEMY_MOVE_DOWN (0f6f) ; the ladder

    0f39  05         DCR B                      ; Check the block type above
    0f3a  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0f3d  7e         MOV A, M

    0f3e  b7         ORA A                      ; Enemy can move up if above is an empty block
    0f3f  ca 5f 0f   JZ ENEMY_MOVE_UP_1 (0f5f)

    0f42  fe 02      CPI A, 02                  ; ... or a ladder
    0f44  ca 5f 0f   JZ ENEMY_MOVE_UP_1 (0f5f)

    0f47  fe 05      CPI A, 05                  ; ... or a water
    0f49  ca 5f 0f   JZ ENEMY_MOVE_UP_1 (0f5f)

    0f4c  fe 07      CPI A, 07                  ; ... or a fake treasure box
    0f4e  ca 5f 0f   JZ ENEMY_MOVE_UP_1 (0f5f)

    0f51  fe 08      CPI A, 08                  ; ... or a real treasure box
    0f53  ca 5f 0f   JZ ENEMY_MOVE_UP_1 (0f5f)

    0f56  fe 0e      CPI A, 0e                  ; ... or another type of non-blocking cell
    0f58  d2 5f 0f   JNC ENEMY_MOVE_UP_1 (0f5f)

    0f5b  04         INR B                      ; If the cell above is blocking - restore the previous position
    0f5c  c3 6f 0f   JMP ENEMY_MOVE_DOWN (0f6f)

ENEMY_MOVE_UP_1:
    0f5f  3a ad 0f   LDA 0fad                   ; Enemy can move 3 of 4 game ticks
    0f62  3c         INR A
    0f63  e6 03      ANI A, 03
    0f65  32 ad 0f   STA 0fad
    0f68  c2 e2 0e   JNZ ENEMY_MOVE_STORE_POSITION (0ee2)

    0f6b  04         INR B                      ; Every 4th game tick the enemy is not moving
    0f6c  c3 e2 0e   JMP ENEMY_MOVE_STORE_POSITION (0ee2)

ENEMY_MOVE_DOWN:
    0f6f  78         MOV A, B                   ; Check if the enemy is above the player
    0f70  ba         CMP D
    0f71  d2 a7 0f   JNC ENEMY_MOVE_EXIT (0fa7)

    0f74  04         INR B                      ; Check the block type below the enemy
    0f75  cd be 08   CALL CALC_BLOCK_PTR (08be)
    0f78  7e         MOV A, M

    0f79  b7         ORA A                      ; The enemy can move if below is an empty cell
    0f7a  ca 9a 0f   JZ ENEMY_MOVE_DOWN_1 (0f9a)

    0f7d  fe 02      CPI A, 02                  ; ... or a ladder
    0f7f  ca 9a 0f   JZ ENEMY_MOVE_DOWN_1 (0f9a)

    0f82  fe 05      CPI A, 05                  ; ... or a water
    0f84  ca 9a 0f   JZ ENEMY_MOVE_DOWN_1 (0f9a)

    0f87  fe 07      CPI A, 07                  ; ... or a fake treasure box
    0f89  ca 9a 0f   JZ ENEMY_MOVE_DOWN_1 (0f9a)

    0f8c  fe 08      CPI A, 08                  ; ... or a real treasure box
    0f8e  ca 9a 0f   JZ ENEMY_MOVE_DOWN_1 (0f9a)

    0f91  fe 0e      CPI A, 0e                  ; ... or other type of non-blocking cell
    0f93  d2 9a 0f   JNC ENEMY_MOVE_DOWN_1 (0f9a)

    0f96  05         DCR B                      ; The cell is blocking, revert the move
    0f97  c3 a7 0f   JMP ENEMY_MOVE_EXIT (0fa7)

ENEMY_MOVE_DOWN_1:
    0f9a  3a ad 0f   LDA 0fad                   ; Enemy will move 3 of 4 game ticks
    0f9d  3c         INR A
    0f9e  e6 03      ANI A, 03
    0fa0  32 ad 0f   STA 0fad
    0fa3  c2 e2 0e   JNZ ENEMY_MOVE_STORE_POSITION (0ee2)

    0fa6  05         DCR B                      ; The enemy will stay every 4th game tick

ENEMY_MOVE_EXIT:
    0fa7  c3 e2 0e   JMP ENEMY_MOVE_STORE_POSITION (0ee2)



PREV_ENEMY_POS:
    0faa  05 08     dw 0x0000

ENEMY_IS_FALLING:
    0fac  00        db 0x00
    
????:
0fad  02         STAX BC


NEW_ENEMY_POS:
    0fae  05 08     dw 0x0000

ENEMY_1_CUR_POS:
    0fb0  05 00

?????:
    0fb2  00 02

ENEMY_2_CUR_POS:
    0fb4  00 00

????:
0fb6  00
0fb7  01

ENEMY_3_CUR_POS:
    0fb8  00 00

????:
0fba  00         NOP
0fbb  00         NOP

ENEMY_4_CUR_POS:
    0fbc  00 00

????:
0fbe  00         NOP
0fbf  00         NOP


; Disallow having several enemies at the same position
;
; This function compares newly calculated enemy position with all enemies locations. If it matches
; any of the enemies position, proposed position is reverted
DO_NOT_ALLOW_ENEMIES_COLLIDE:
    0fc0  3a ae 0f   LDA NEW_ENEMY_POS (0fae)   ; Load the newly calculated enemy position to BC
    0fc3  47         MOV B, A
    0fc4  3a af 0f   LDA NEW_ENEMY_POS + 1 (0faf)
    0fc7  4f         MOV C, A

    0fc8  21 b0 0f   LXI HL, ENEMY_1_CUR_POS (0fb0) ; Compare it with Enemy 1 position
    0fcb  7e         MOV A, M
    0fcc  90         SUB B
    0fcd  57         MOV D, A
    0fce  23         INX HL
    0fcf  7e         MOV A, M
    0fd0  91         SUB C
    0fd1  23         INX HL
    0fd2  b2         ORA D
    0fd3  ca fd 0f   JZ DO_NOT_ALLOW_ENEMIES_COLLIDE_REVERT (0ffd)

    0fd6  23         INX HL                     ; Compare newly calculated position with Enemy 2 position
    0fd7  23         INX HL
    0fd8  7e         MOV A, M
    0fd9  90         SUB B
    0fda  57         MOV D, A
    0fdb  23         INX HL
    0fdc  7e         MOV A, M
    0fdd  91         SUB C
    0fde  23         INX HL
    0fdf  b2         ORA D
    0fe0  ca fd 0f   JZ DO_NOT_ALLOW_ENEMIES_COLLIDE_REVERT (0ffd)

    0fe3  23         INX HL                     ; Compare newly calculated position with Enemy 2 position
    0fe4  23         INX HL
    0fe5  7e         MOV A, M
    0fe6  90         SUB B
    0fe7  57         MOV D, A
    0fe8  23         INX HL
    0fe9  7e         MOV A, M
    0fea  91         SUB C
    0feb  23         INX HL
    0fec  b2         ORA D
    0fed  ca fd 0f   JZ DO_NOT_ALLOW_ENEMIES_COLLIDE_REVERT (0ffd)

    0ff0  23         INX HL                     ; Compare newly calculated position with Enemy 2 position
    0ff1  23         INX HL
    0ff2  7e         MOV A, M
    0ff3  90         SUB B
    0ff4  57         MOV D, A
    0ff5  23         INX HL
    0ff6  7e         MOV A, M
    0ff7  91         SUB C
    0ff8  b2         ORA D
    0ff9  ca fd 0f   JZ DO_NOT_ALLOW_ENEMIES_COLLIDE_REVERT (0ffd)

    0ffc  c9         RET                        ; Newly calculated position is ok

DO_NOT_ALLOW_ENEMIES_COLLIDE_REVERT:
    0ffd  2a aa 0f   LHLD PREV_ENEMY_POS (0faa) ; Revert the enemy position to the previous one
    1000  22 ae 0f   SHLD NEW_ENEMY_POS (0fae)
    1003  c9         RET


; Redraw the enemy symbol
;
; Remove enemy symbol at 0faa position, and restore map symbol underneath.
; Draw enemy symbol at new position (pointed by 0fab)
REDRAW_ENEMY:
    1004  3a aa 0f   LDA PREV_ENEMY_POS (0faa)  ; Load previous enemy position
    1007  47         MOV B, A
    1008  3a ab 0f   LDA PREV_ENEMY_POS + 1 (0fab)
    100b  4f         MOV C, A

    100c  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Restore symbol under enemy
    100f  7e         MOV A, M
    1010  cd c4 11   CALL DRAW_BLOCK (11c4)

    1013  3a ae 0f   LDA NEW_ENEMY_POS (0fae)   ; Load the new enemy position
    1016  47         MOV B, A
    1017  3a af 0f   LDA NEW_ENEMY_POS + 1 (0faf)
    101a  4f         MOV C, A

    101b  3e 14      MVI A, 14                  ; Draw the enemy symbol at new position
    101d  cd c4 11   CALL DRAW_BLOCK (11c4)

    1020  c9         RET

; Check if the enemy sunk in the water
;
; Checks if the enemy pointed by new position (0fae) has sunk in the water (block type 0x05)
;
; Returns carry flag set if enemy still alive, reset if sunk
CHECK_ENEMY_SUNK:
    1021  3a ae 0f   LDA NEW_ENEMY_POS (0fae)   ; Load the enemy address
    1024  47         MOV B, A
    1025  3a af 0f   LDA NEW_ENEMY_POS + 1 (0faf)
    1028  4f         MOV C, A

    1029  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Get block at enemy position
    102c  7e         MOV A, M

    102d  fe 05      CPI A, 05                  ; Check if it is a water
    102f  c2 37 10   JNZ CHECK_ENEMY_SUNK_1 (1037)

    1032  cd c4 11   CALL DRAW_BLOCK (11c4)     ; If yes - restore the block under enemy

    1035  af         XRA A                      ; reset carry flag (enemy has sunk)
    1036  c9         RET

CHECK_ENEMY_SUNK_1:
    1037  37         STC                        ; Set carry flag (enemy still alive)
    1038  c9         RET



HANDLE_ENEMIES:
    1039  2a b0 0f   LHLD ENEMY_1_CUR_POS (0fb0); Start with enemy 1, copy its position to prev/new pos vars
    103c  22 aa 0f   SHLD PREV_ENEMY_POS (0faa)
    103f  22 ae 0f   SHLD NEW_ENEMY_POS (0fae)

    1042  2a b2 0f   LHLD ?????? (0fb2)         ; ????
    1045  22 ac 0f   SHLD 0fac

    1048  3a 64 11   LDA ENEMY_1_RESPAWN_TIMER (1164)   ; Check if enemy needs to be respawn
    104b  b7         ORA A
    104c  ca 56 10   JZ ENEMY_1_DO_ACTIONS (1056)

    104f  3c         INR A                      ; Increment the respawn timer
    1050  32 64 11   STA ENEMY_1_RESPAWN_TIMER (1164)

    1053  c3 7f 10   JMP HANDLE_ENEMY_2 (107f)

ENEMY_1_DO_ACTIONS:
    1056  cd 4a 0e   CALL HANDLE_ENEMY_MOVE (0e4a)  ; Do the enemy moves and checks
    1059  cd c0 0f   CALL DO_NOT_ALLOW_ENEMIES_COLLIDE (0fc0)
    105c  cd 04 10   CALL REDRAW_ENEMY (1004)
    105f  cd 21 10   CALL CHECK_ENEMY_SUNK (1021)

    1062  da 73 10   JC ENEMY_1_ALIVE (1073)    ; Check if the enemy still alive

    1065  3e d0      MVI A, d0                  ; Enemy died, will wait for 48 game ticks to respawns
    1067  32 64 11   STA ENEMY_1_RESPAWN_TIMER (1164)

    106a  2a b3 08   LHLD ENEMY_1_START_POS (08b3)  ; Will respawn at original location
    106d  22 b0 0f   SHLD ENEMY_1_CUR_POS (0fb0)
    1070  c3 7f 10   JMP HANDLE_ENEMY_2 (107f)

ENEMY_1_ALIVE:
    1073  2a ae 0f   LHLD NEW_ENEMY_POS (0fae)
    1076  22 b0 0f   SHLD ENEMY_1_CUR_POS (0fb0)

    1079  2a ac 0f   LHLD 0fac
    107c  22 b2 0f   SHLD ????????? (0fb2)


HANDLE_ENEMY_2:
    107f  3a bb 08   LDA 08bb                   ; Check if we have enemy #2 on the map
    1082  fe 02      CPI A, 02
    1084  d8         RC

    1085  2a b4 0f   LHLD ENEMY_2_CUR_POS (0fb4)    ; Load the enemy position
    1088  22 aa 0f   SHLD PREV_ENEMY_POS (0faa)
    108b  22 ae 0f   SHLD NEW_ENEMY_POS (0fae)

    108e  2a b6 0f   LHLD 0fb6                  ; ????
    1091  22 ac 0f   SHLD 0fac

    1094  3a 65 11   LDA ENEMY_2_RESPAWN_TIMER (1165)   ; Check if it is time to respawn the enemy #2
    1097  b7         ORA A
    1098  ca a2 10   JZ ENEMY_2_DO_ACTIONS (10a2)

    109b  3c         INR A                      ; Increment the respawn timer
    109c  32 65 11   STA ENEMY_2_RESPAWN_TIMER (1165)

    109f  c3 cb 10   JMP HANDLE_ENEMY_3 (10cb)

ENEMY_2_DO_ACTIONS:
    10a2  cd 4a 0e   CALL HANDLE_ENEMY_MOVE (0e4a)  ; Do the enemy stuff
    10a5  cd c0 0f   CALL DO_NOT_ALLOW_ENEMIES_COLLIDE (0fc0)
    10a8  cd 04 10   CALL REDRAW_ENEMY (1004)
    10ab  cd 21 10   CALL CHECK_ENEMY_SUNK (1021)

    10ae  da bf 10   JC ENEMY_2_ALIVE (10bf)    ; Check if enemy still alive

    10b1  3e d0      MVI A, d0                  ; If enemy died - start the enemy respawn timer
    10b3  32 65 11   STA ENEMY_2_RESPAWN_TIMER (1165)

    10b6  2a b5 08   LHLD ENEMY_2_START_POS (08b5)  ; Reset the enemy position
    10b9  22 b4 0f   SHLD ENEMY_2_CUR_POS (0fb4)

    10bc  c3 cb 10   JMP HANDLE_ENEMY_3 (10cb)

ENEMY_2_ALIVE:
    10bf  2a ae 0f   LHLD NEW_ENEMY_POS (0fae)  ; Store the enemy new position
    10c2  22 b4 0f   SHLD ENEMY_2_CUR_POS (0fb4)

    10c5  2a ac 0f   LHLD 0fac                  ; ????
    10c8  22 b6 0f   SHLD 0fb6

HANDLE_ENEMY_3:
    10cb  3a bb 08   LDA 08bb                   ; Check if enemy #3 exists on the map
    10ce  fe 03      CPI A, 03
    10d0  d8         RC

    10d1  2a b8 0f   LHLD ENEMY_3_CUR_POS (0fb8)    ; Load the enemy position
    10d4  22 aa 0f   SHLD PREV_ENEMY_POS (0faa)
    10d7  22 ae 0f   SHLD NEW_ENEMY_POS (0fae)

    10da  2a ba 0f   LHLD 0fba                  ; ????
    10dd  22 ac 0f   SHLD 0fac

    10e0  3a 66 11   LDA ENEMY_3_RESPAWN_TIMER (1166)   ; Check if it is time to respawn the enemy #3
    10e3  b7         ORA A
    10e4  ca ee 10   JZ ENEMY_3_DO_ACTIONS (10ee)

    10e7  3c         INR A                      ; Increase the respawn timer
    10e8  32 66 11   STA ENEMY_3_RESPAWN_TIMER (1166)

    10eb  c3 17 11   JMP HANDLE_ENEMY_4 (1117)

ENEMY_3_DO_ACTIONS:
    10ee  cd 4a 0e   CALL HANDLE_ENEMY_MOVE (0e4a)  ; Do the enemy stuff
    10f1  cd c0 0f   CALL DO_NOT_ALLOW_ENEMIES_COLLIDE (0fc0)
    10f4  cd 04 10   CALL REDRAW_ENEMY (1004)
    10f7  cd 21 10   CALL CHECK_ENEMY_SUNK (1021)

    10fa  da 0b 11   JC ENEMY_3_ALIVE (110b)    ; Check if enemy still alive

    10fd  3e d0      MVI A, d0                  ; Start the respawn timer
    10ff  32 66 11   STA ENEMY_3_RESPAWN_TIMER (1166)

    1102  2a b7 08   LHLD ENEMY_3_START_POS (08b7)  ; Reset the enemy position
    1105  22 b8 0f   SHLD ENEMY_3_CUR_POS (0fb8)

    1108  c3 17 11   JMP HANDLE_ENEMY_4 (1117)

ENEMY_3_ALIVE:
    110b  2a ae 0f   LHLD NEW_ENEMY_POS (0fae)  ; Store the new enemy position
    110e  22 b8 0f   SHLD ENEMY_3_CUR_POS (0fb8)

    1111  2a ac 0f   LHLD 0fac                  ; ????
    1114  22 ba 0f   SHLD 0fba

HANDLE_ENEMY_4:
    1117  3a bb 08   LDA 08bb                   ; Check if there is Enemy #4 on the map
    111a  fe 04      CPI A, 04
    111c  d8         RC

    111d  2a bc 0f   LHLD ENEMY_4_CUR_POS (0fbc)    ; Load the enemy #4 position
    1120  22 aa 0f   SHLD PREV_ENEMY_POS (0faa)
    1123  22 ae 0f   SHLD NEW_ENEMY_POS (0fae)

    1126  2a be 0f   LHLD 0fbe                  ; ????
    1129  22 ac 0f   SHLD 0fac

    112c  3a 67 11   LDA ENEMY_4_RESPAWN_TIMER (1167)   ; Check that it is time to respawn enemy #4
    112f  b7         ORA A
    1130  ca 3a 11   JZ ENEMY_4_DO_ACTIONS (113a)

    1133  3c         INR A                      ; Increment the enemy #4 respawn timer
    1134  32 67 11   STA ENEMY_4_RESPAWN_TIMER (1167)

    1137  c3 63 11   JMP 1163

ENEMY_4_DO_ACTIONS:
    113a  cd 4a 0e   CALL HANDLE_ENEMY_MOVE (0e4a)  ; Do the enemy stuff
    113d  cd c0 0f   CALL DO_NOT_ALLOW_ENEMIES_COLLIDE (0fc0)
    1140  cd 04 10   CALL REDRAW_ENEMY (1004)
    1143  cd 21 10   CALL CHECK_ENEMY_SUNK (1021)

    1146  da 57 11   JC ENEMY_4_ALIVE (1157)    ; Check if the enemy still alive

    1149  3e d0      MVI A, d0                  ; Start the respawn timer
    114b  32 67 11   STA ENEMY_4_RESPAWN_TIMER (1167)

    114e  2a b9 08   LHLD ENEMY_4_START_POS (08b9)  ; Prepare enemy #4 position after respawn
    1151  22 bc 0f   SHLD ENEMY_4_CUR_POS (0fbc)

    1154  c3 63 11   JMP 1163

ENEMY_4_ALIVE:
    1157  2a ae 0f   LHLD NEW_ENEMY_POS (0fae)  ; Store the new position
    115a  22 bc 0f   SHLD ENEMY_4_CUR_POS (0fbc)

    115d  2a ac 0f   LHLD 0fac                  ; ????
    1160  22 be 0f   SHLD 0fbe

????:
    1163  c9         RET



ENEMY_1_RESPAWN_TIMER:
    1164  00        db 00
ENEMY_2_RESPAWN_TIMER:
    1165  00        db 00
ENEMY_3_RESPAWN_TIMER:
    1166  00        db 00
ENEMY_4_RESPAWN_TIMER:
    1167  00        db 00



INIT_ENEMY_POS:
    1168  2a b3 08   LHLD ENEMY_1_START_POS (08b3)  ; Initialize 1st enemy coordinate
    116b  22 b0 0f   SHLD ENEMY_1_CUR_POS (0fb0)

    116e  2a b5 08   LHLD ENEMY_2_START_POS (08b5)  ; Initialize 2nd enemy coordinate
    1171  22 b4 0f   SHLD ENEMY_2_CUR_POS (0fb4)

    1174  2a b7 08   LHLD ENEMY_3_START_POS (08b7)  ; Initialize 3rd enemy coordinate
    1177  22 b8 0f   SHLD ENEMY_3_CUR_POS (0fb8)

    117a  2a b9 08   LHLD ENEMY_4_START_POS (08b9)  ; Initialize 4th enemy coordinate
    117d  22 bc 0f   SHLD ENEMY_4_CUR_POS (0fbc)

    1180  c9         RET


CHECK_PLAYER_MEETS_ENEMY:
    1181  2a d4 0a   LHLD PLAYER_POS (0ad4)         ; Compare player's position and enemy 1 position
    1184  eb         XCHG
    1185  2a b0 0f   LHLD ENEMY_1_CUR_POS (0fb0)
    1188  7a         MOV A, D
    1189  94         SUB H
    118a  c2 92 11   JNZ CHECK_PLAYER_MEETS_ENEMY_1 (1192)
    118d  7b         MOV A, E
    118e  95         SUB L
    118f  ca be 11   JZ PLAYER_CAUGHT_BY_ENEMY (11be)

CHECK_PLAYER_MEETS_ENEMY_1:
    1192  2a b4 0f   LHLD ENEMY_2_CUR_POS (0fb4)    ; Check for enemy 2
    1195  7a         MOV A, D
    1196  94         SUB H
    1197  c2 9f 11   JNZ CHECK_PLAYER_MEETS_ENEMY_2 (119f)
    119a  7b         MOV A, E
    119b  95         SUB L
    119c  ca be 11   JZ PLAYER_CAUGHT_BY_ENEMY (11be)

CHECK_PLAYER_MEETS_ENEMY_2:
    119f  2a b8 0f   LHLD ENEMY_3_CUR_POS (0fb8)
    11a2  7a         MOV A, D
    11a3  94         SUB H
    11a4  c2 ac 11   JNZ CHECK_PLAYER_MEETS_ENEMY_2 (11ac)
    11a7  7b         MOV A, E
    11a8  95         SUB L
    11a9  ca be 11   JZ PLAYER_CAUGHT_BY_ENEMY (11be)

CHECK_PLAYER_MEETS_ENEMY_3:
    11ac  2a bc 0f   LHLD ENEMY_4_CUR_POS (0fbc)
    11af  7a         MOV A, D
    11b0  94         SUB H
    11b1  c2 b9 11   JNZ CHECK_PLAYER_MEETS_ENEMY_4 (11b9)
    11b4  7b         MOV A, E
    11b5  95         SUB L
    11b6  ca be 11   JZ PLAYER_CAUGHT_BY_ENEMY (11be)

CHECK_PLAYER_MEETS_ENEMY_4:
    11b9  af         XRA A                      ; Reset player death flag

CHECK_PLAYER_MEETS_ENEMY_EXIT:
    11ba  32 c3 11   STA PLAYER_DEAD (11c3)     ; Store the flag and exit
    11bd  c9         RET

PLAYER_CAUGHT_BY_ENEMY:
    11be  3e 01      MVI A, 01                  ; Set player death flag
    11c0  c3 ba 11   JMP CHECK_PLAYER_MEETS_ENEMY_EXIT (11ba)


PLAYER_DEAD:
    11c3  00         db 00


; Draw a block of type A at screen coordinates (B,C)
DRAW_BLOCK:
    11c4  f5         PUSH PSW
    11c5  d5         PUSH DE
    11c6  e5         PUSH HL

    11c7  cd a0 01   CALL GAME_SYMB_LOOKUP (01a0)

    11ca  21 40 e8   LXI HL, e840               ; First line video memory address
    11cd  11 40 00   LXI DE, 0040               ; Line length

    11d0  78         MOV A, B                   ; Limit the vertical coordinate with 25 lines
    11d1  3c         INR A
    11d2  fe 1a      CPI A, 1a
    11d4  da d9 11   JC DRAW_BLOCK_LOOP (11d9)

    11d7  3e 19      MVI A, 19

DRAW_BLOCK_LOOP:
    11d9  3d         DCR A                      ; Calculate the line address by adding line length increment
    11da  ca e1 11   JZ DRAW_BLOCK_2 (11e1)

    11dd  19         DAD DE
    11de  c3 d9 11   JMP DRAW_BLOCK_LOOP (11d9)

DRAW_BLOCK_2:
    11e1  79         MOV A, C                   ; Limit the horizontal coordinate with 64 columns
    11e2  fe 40      CPI A, 40
    11e4  da e9 11   JC DRAW_BLOCK_3 (11e9)

    11e7  3e 3f      MVI A, 3f

DRAW_BLOCK_3:
    11e9  5f         MOV E, A                   ; Calculate the block address in video memory
    11ea  19         DAD DE

    11eb  3a 9e 01   LDA BLOCK_SYMBOL (019e)    ; Put the block symbol directly into the video memory
    11ee  77         MOV M, A

    11ef  e1         POP HL
    11f0  d1         POP DE
    11f1  f1         POP PSW

    11f2  c9         RET



; Calculate an address of a slot in broken bricks array
;
; HL = 120f + [120e] * 4
CALC_SLOT_ADDRESS:
    11f3  f5         PUSH PSW
    11f4  d5         PUSH DE

    11f5  11 00 00   LXI DE, 0000
    11f8  21 0f 12   LXI HL, BROKEN_BRICKS_ARRAY (120f)

    11fb  af         XRA A
    11fc  3a 0e 12   LDA BRICK_SLOT_INDEX (120e)
    11ff  17         RAL
    1200  5f         MOV E, A

    1201  7a         MOV A, D
    1202  17         RAL
    1203  57         MOV D, A

    1204  7b         MOV A, E
    1205  17         RAL
    1206  5f         MOV E, A

    1207  7a         MOV A, D
    1208  17         RAL
    1209  57         MOV D, A

    120a  19         DAD DE

    120b  d1         POP DE
    120c  f1         POP PSW
    120d  c9         RET


BRICK_SLOT_INDEX:
    120e  64         db 00


BROKEN_BRICKS_ARRAY:
    120f  400 * 0x00                            ; An array of 4-byte records, for tracking broken bricks    



139f  00         NOP
13a0  00         NOP
13a1  00         NOP
13a2  00         NOP

FLYING_ARROW_COUNTER:
    13a3  00         NOP




UPDATE_BRICKS:
    13a4  af         XRA A                      ; Iterate over broken bricks array
    13a5  32 0e 12   STA BRICK_SLOT_INDEX (120e)

UPDATE_BRICKS_LOOP:
    13a8  cd f3 11   CALL CALC_SLOT_ADDRESS (11f3)  ; Search for a non-empty record
    13ab  7e         MOV A, M
    13ac  b7         ORA A
    13ad  c2 c9 13   JNZ UPDATE_SINGLE_BRICK (13c9)

UPDATE_BRICKS_NEXT:
    13b0  3a 0e 12   LDA BRICK_SLOT_INDEX (120e); Advance to the next slot
    13b3  3c         INR A
    13b4  32 0e 12   STA BRICK_SLOT_INDEX (120e)

    13b7  fe 64      CPI A, 64                  ; Iterate no more than 100 records
    13b9  da a8 13   JC UPDATE_BRICKS_LOOP (13a8)

    13bc  3a d4 0a   LDA PLAYER_POS_Y (0ad4)    ; Get player position
    13bf  47         MOV B, A
    13c0  3a d5 0a   LDA PLAYER_POS_X (0ad5)
    13c3  4f         MOV C, A

    13c4  3e 13      MVI A, 13                  ; Draw the player symbol and exit
    13c6  c3 c4 11   JMP DRAW_BLOCK (11c4)


UPDATE_SINGLE_BRICK:
    13c9  23         INX HL                     ; Get the slot counter
    13ca  7e         MOV A, M

    13cb  3d         DCR A                      ; Decrement the counter
    13cc  47         MOV B, A

    13cd  3a a3 13   LDA FLYING_ARROW_COUNTER (13a3)
    13d0  e6 07      ANI A, 07
    13d2  78         MOV A, B
    13d3  ca d7 13   JZ 13d7

    13d6  3c         INR A

????:
    13d7  77         MOV M, A

    13d8  b7         ORA A
    13d9  fa 31 14   JM 1431

    13dc  c2 f4 13   JNZ 13f4


RESTORE_BRICK:
    13df  af         XRA A                      ; Reset the slot record
    13e0  77         MOV M, A
    13e1  2b         DCX HL                     
    13e2  77         MOV M, A
    13e3  23         INX HL
    13e4  23         INX HL
    13e5  46         MOV B, M
    13e6  23         INX HL
    13e7  4e         MOV C, M

    13e8  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Restore brick symbol
    13eb  3e 0b      MVI A, 0b
    13ed  77         MOV M, A
    13ee  cd c4 11   CALL DRAW_BLOCK (11c4)

    13f1  c3 b0 13   JMP UPDATE_BRICKS_NEXT (13b0)


????:
    13f4  fe 1e      CPI A, 1e
    13f6  d2 09 14   JNC 1409

    13f9  23         INX HL                     ; Load the brick coordinate to BC
    13fa  46         MOV B, M
    13fb  23         INX HL
    13fc  4e         MOV C, M

    13fd  cd be 08   CALL CALC_BLOCK_PTR (08be) ; And put partially brocken brick symbol
    1400  3e 0c      MVI A, 0c
    1402  77         MOV M, A

    1403  cd c4 11   CALL DRAW_BLOCK (11c4)     ; Draw the block and exit
    1406  c3 b0 13   JMP UPDATE_BRICKS_NEXT (13b0)


????:
    1409  fe 3c      CPI A, 3c
    140b  d2 1e 14   JNC 141e

    140e  23         INX HL                     ; Load the brick coordinate to BC
    140f  46         MOV B, M
    1410  23         INX HL
    1411  4e         MOV C, M

    1412  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Draw severly damaged block
    1415  3e 0d      MVI A, 0d
    1417  77         MOV M, A
    1418  cd c4 11   CALL DRAW_BLOCK (11c4)

    141b  c3 b0 13   JMP UPDATE_BRICKS_NEXT (13b0)  ; Move to the next record


????:
    141e  f6 80      ORI A, 80                  ; Block is destroyed. Set the MSB to indicate it will be
    1420  77         MOV M, A                   ; restored over time

    1421  23         INX HL
    1422  46         MOV B, M
    1423  23         INX HL
    1424  4e         MOV C, M

    1425  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Draw the empty block symbol
    1428  3e 0e      MVI A, 0e
    142a  77         MOV M, A
    142b  cd c4 11   CALL DRAW_BLOCK (11c4)

    142e  c3 b0 13   JMP UPDATE_BRICKS_NEXT (13b0)  ; Move to the next slot

????:
    1431  e6 7f      ANI A, 7f                  ; Check if the block restoration timer is completed
    1433  ca df 13   JZ RESTORE_BRICK (13df)

    1436  fe 1e      CPI A, 1e                  ; ?????
    1438  d2 4b 14   JNC 144b

    143b  23         INX HL                     ; Get the block coordinate to BC
    143c  46         MOV B, M
    143d  23         INX HL
    143e  4e         MOV C, M

    143f  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Draw the little partially restored brick symbol
    1442  3e 10      MVI A, 10
    1444  77         MOV M, A
    1445  cd c4 11   CALL DRAW_BLOCK (11c4)

    1448  c3 b0 13   JMP UPDATE_BRICKS_NEXT (13b0)

????:
    144b  fe 3c      CPI A, 3c
    144d  d2 1e 14   JNC 141e

    1450  23         INX HL                     ; Load the brick coordinate to BC
    1451  46         MOV B, M
    1452  23         INX HL
    1453  4e         MOV C, M

    1454  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Draw the little bit restored brick symbol
    1457  3e 0f      MVI A, 0f
    1459  77         MOV M, A
    145a  cd c4 11   CALL DRAW_BLOCK (11c4)

    145d  c3 b0 13   JMP UPDATE_BRICKS_NEXT (13b0)




; Search for a slot in the broken bricks array
;
; The function checks if there is a slot that corresponds to a block at BC position in the list already.
; If no such slot found, the function searches for an empty slot.
;
; Found slot indes is returned at BRICK_SLOT_INDEX (0x120e)
;
; A = 0
; while A < 100:
;     if arr[A].f1 != 0:
;         if arr[A].ptr == BC:
;             return
;     A++
;
;  A = 0       
;  while A < 100:
;      if arr[A].f1 == 0:
;          arr[A].f1 += 1
;          arr[A].ptr = BC
;          return
;      A++
;
SEARCH_BRICK_SLOT:
    1460  f5         PUSH PSW
    1461  d5         PUSH DE
    1462  e5         PUSH HL

    1463  af         XRA A                      ; Stage 1: search for an existing slot that matches BC
    1464  32 0e 12   STA BRICK_SLOT_INDEX (120e)

SEARCH_BRICK_SLOT_L1:
    1467  cd f3 11   CALL CALC_SLOT_ADDRESS (11f3)  ; Search for a non-empty slot
    146a  7e         MOV A, M
    146b  b7         ORA A
    146c  c2 97 14   JNZ MATCH_BRICK_SLOT (1497)

SEARCH_BRICK_SLOT_NEXT:
    146f  3a 0e 12   LDA BRICK_SLOT_INDEX (120e)    ; Advance to the next record
    1472  3c         INR A
    1473  32 0e 12   STA BRICK_SLOT_INDEX (120e)

    1476  fe 64      CPI A, 64                  ; Iterate over records, but no more thant 100 records
    1478  da 67 14   JC SEARCH_BRICK_SLOT_L1 (1467)


    147b  af         XRA A                      ; Stage 2: Search for an empty slot
    147c  32 0e 12   STA BRICK_SLOT_INDEX (120e)

SEARCH_BRICK_SLOT_L2:
    147f  cd f3 11   CALL CALC_SLOT_ADDRESS (11f3)  ; Search for an empty slot
    1482  7e         MOV A, M
    1483  b7         ORA A
    1484  ca a7 14   JZ ACQUIRE_BRICK_SLOT (14a7)

    1487  3a 0e 12   LDA BRICK_SLOT_INDEX (120e); Advance to the next slot
    148a  3c         INR A
    148b  32 0e 12   STA BRICK_SLOT_INDEX (120e)

    148e  fe 64      CPI A, 64                  ; Iterate over slots, but no more than 100 slots
    1490  da 7f 14   JC SEARCH_BRICK_SLOT_L2 (147f)

SEARCH_BRICK_SLOT_EXIT:
    1493  e1         POP HL
    1494  d1         POP DE
    1495  f1         POP PSW
    1496  c9         RET



; Compare BC and the address in the record pointed by HL
; If equal - move 1493
; It not equal - move 146f
MATCH_BRICK_SLOT:
    1497  23         INX HL
    1498  23         INX HL

    1499  7e         MOV A, M
    149a  b8         CMP B
    149b  c2 6f 14   JNZ SEARCH_BRICK_SLOT_NEXT (146f)

    149e  23         INX HL
    149f  7e         MOV A, M
    14a0  b9         CMP C    
    14a1  c2 6f 14   JNZ SEARCH_BRICK_SLOT_NEXT (146f)

    14a4  c3 93 14   JMP SEARCH_BRICK_SLOT_EXIT (1493)


; Increase counter in the brick slot pointed by HL
; Store BC as a block coordinate
ACQUIRE_BRICK_SLOT:
    14a7  3c         INR A
    14a8  77         MOV M, A

    14a9  23         INX HL
    14aa  23         INX HL

    14ab  70         MOV M, B
    14ac  23         INX HL
    14ad  71         MOV M, C

    14ae  c3 93 14   JMP SEARCH_BRICK_SLOT_EXIT (1493)








HANDLE_ARROW_MOVE:
    14b1  3a 9c 15   LDA ARROW_FLYING_LEFT (159c)   ; Check if an arrow is flying left
    14b4  b7         ORA A
    14b5  c2 c0 14   JNZ HANDLE_ARROW_MOVE_LEFT (14c0)

    14b8  3a 9b 15   LDA ARROW_FLYING_RIGHT (159b)  ; Check if an arrow is flying right
    14bb  b7         ORA A
    14bc  c2 0b 15   JNZ HANDLE_ARROW_MOVE_RIGHT (150b)

    14bf  c9         RET

HANDLE_ARROW_MOVE_LEFT:
    14c0  2a 9d 15   LHLD ARROW_LEFT_POS (159d) ; Load left arrow position to BC
    14c3  4c         MOV C, H
    14c4  45         MOV B, L

    14c5  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Get the block type at arrow position
    14c8  7e         MOV A, M

    14c9  cd c4 11   CALL DRAW_BLOCK (11c4)     ; Restore the block previously occupied by the arrow

    14cc  0d         DCR C                      ; Calculate new arrow position left to the previous one
    14cd  61         MOV H, C
    14ce  68         MOV L, B

    14cf  22 9d 15   SHLD ARROW_LEFT_POS (159d) ; Update the arrow position

    14d2  cd be 08   CALL CALC_BLOCK_PTR (08be) ; Check if arrow reched the outer (contrete) wall
    14d5  7e         MOV A, M
    14d6  fe 01      CPI A, 01
    14d8  c2 e0 14   JNZ HANDLE_LEFT_ARROW_BRICK (14e0)

    14db  af         XRA A                      ; If hit the concrete - abandon the arrow
    14dc  32 9c 15   STA ARROW_FLYING_LEFT (159c)
    14df  c9         RET

HANDLE_LEFT_ARROW_BRICK:
    14e0  fe 0b      CPI A, 0b                  ; Check if we hit brick
    14e2  ca f4 14   JZ HANDLE_LEFT_ARROW_BRICK_1 (14f4)
    14e5  fe 0c      CPI A, 0c                  ; or partially broken brick
    14e7  ca f4 14   JZ HANDLE_LEFT_ARROW_BRICK_1 (14f4)
    14ea  fe 0d      CPI A, 0d                  ; or even more broken brick
    14ec  ca f4 14   JZ HANDLE_LEFT_ARROW_BRICK_1 (14f4)

    14ef  3e 15      MVI A, 15                  ; Other materials do not block the arrow - draw it
    14f1  c3 c4 11   JMP 11c4

HANDLE_LEFT_ARROW_BRICK_1:
    14f4  af         XRA A                      ; Abandon the arrow
    14f5  32 9c 15   STA ARROW_FLYING_LEFT (159c)

HANDLE_ARROW_BRICK:
    14f8  cd 60 14   CALL SEARCH_BRICK_SLOT (1460)

    14fb  cd f3 11   CALL CALC_SLOT_ADDRESS (11f3)  ; Load the brick record counter
    14fe  23         INX HL
    14ff  7e         MOV A, M

    1500  c6 1e      ADI A, 1e                      ; Increase the hit counter ?????
    1502  fe 3b      CPI A, 3b
    1504  da 09 15   JC HANDLE_ARROW_BRICK_1 (1509)

    1507  3e 7f      MVI A, 7f

HANDLE_ARROW_BRICK_1:
    1509  77         MOV M, A                       ; Store the brick record counter
    150a  c9         RET

HANDLE_ARROW_MOVE_RIGHT:
    150b  2a 9f 15   LHLD ARROW_RIGHT_POS (159f)    ; Load right arrow position to BC
    150e  4c         MOV C, H
    150f  45         MOV B, L

    1510  cd be 08   CALL CALC_BLOCK_PTR (08be)     ; Restore the block under the arrow
    1513  7e         MOV A, M
    1514  cd c4 11   CALL DRAW_BLOCK (11c4)

    1517  0c         INR C                          ; Calculate position right to the arrow
    1518  68         MOV L, B
    1519  61         MOV H, C
    151a  22 9f 15   SHLD ARROW_RIGHT_POS (159f)

    151d  cd be 08   CALL CALC_BLOCK_PTR (08be)     ; Check if there a concrete block
    1520  7e         MOV A, M
    1521  fe 01      CPI A, 01
    1523  c2 2b 15   JNZ HANDLE_RIGHT_ARROW_BRICK (152b)

    1526  af         XRA A                          ; If arrow hit concrete - abandon the arrow
    1527  32 9b 15   STA ARROW_FLYING_RIGHT (159b)

    152a  c9         RET

HANDLE_RIGHT_ARROW_BRICK:
    152b  fe 0b      CPI A, 0b                      ; Check if arrow hit a brick
    152d  ca 3f 15   JZ HANDLE_RIGHT_ARROW_BRICK_1 (153f)

    1530  fe 0c      CPI A, 0c                      ; ... or a partially damaged brick
    1532  ca 3f 15   JZ HANDLE_RIGHT_ARROW_BRICK_1 (153f)

    1535  fe 0d      CPI A, 0d                      ; ... or even more damaged brick
    1537  ca 3f 15   JZ HANDLE_RIGHT_ARROW_BRICK_1 (153f)

    153a  3e 15      MVI A, 15                      ; Otherwise just draw the error and exit
    153c  c3 c4 11   JMP DRAW_BLOCK (11c4)

HANDLE_RIGHT_ARROW_BRICK_1:
    153f  af         XRA A                          ; Arrow hit a brick - abandon the arrow
    1540  32 9b 15   STA ARROW_FLYING_RIGHT (159b)

    1543  c3 f8 14   JMP HANDLE_ARROW_BRICK (14f8)  ; ... and handle brick hit




HANDLE_ARROWS:
    1546  3a d8 0a   LDA PRESSED_KEY (0ad8)

    1549  fe 5e      CPI A, 5e                  ; Check if user pressed '^' - throw arrow right
    154b  c2 5f 15   JNZ HANDLE_ARROWS_1 (155f)

    154e  3a 9b 15   LDA ARROW_FLYING_RIGHT (159b)  ; Check if the arrow is already flying
    1551  b7         ORA A
    1552  c2 5f 15   JNZ HANDLE_ARROWS_1 (155f)

    1555  3c         INR A                      ; Set the arrow is flying flag
    1556  32 9b 15   STA ARROW_FLYING_RIGHT (159b)

    1559  2a d4 0a   LHLD PLAYER_POS (0ad4)     ; Throw the arrow
    155c  22 9f 15   SHLD ARROW_RIGHT_POS (159f)

HANDLE_ARROWS_1:
    155f  3a d8 0a   LDA PRESSED_KEY (0ad8)     ; Check if user pressed 'Q' - throw arrow left
    1562  fe 51      CPI A, 51
    1564  c2 78 15   JNZ HANDLE_ARROWS_2 (1578)

    1567  3a 9c 15   LDA ARROW_FLYING_LEFT (159c)   ; Check if arrow is already flying
    156a  b7         ORA A
    156b  c2 78 15   JNZ HANDLE_ARROWS_2 (1578)

    156e  3c         INR A                      ; Raise the 'arrow is flying' flag
    156f  32 9c 15   STA ARROW_FLYING_LEFT (159c)

    1572  2a d4 0a   LHLD PLAYER_POS (0ad4)     ; Throw the arrow
    1575  22 9d 15   SHLD ARROW_LEFT_POS (159d)

HANDLE_ARROWS_2:
    1578  cd b1 14   CALL HANDLE_ARROW_MOVE (14b1)
157b  cd a4 13   CALL 13a4

    157e  3a a3 13   LDA FLYING_ARROW_COUNTER (13a3); Increment the flying arrow counter
    1581  3c         INR A
    1582  32 a3 13   STA FLYING_ARROW_COUNTER (13a3)

    1585  c9         RET



RESET_BROKEN_BRICKS:
    1586  af         XRA A                      ; Reset "arrow is flying" flags
    1587  32 9b 15   STA ARROW_FLYING_RIGHT (159b)
    158a  32 9c 15   STA ARROW_FLYING_LEFT (159c)

    158d  21 0f 12   LXI HL, BROKEN_BRICKS_ARRAY (120f) ; Zero 400 bytes (100 records) of the array
    1590  06 c8      MVI B, c8

RESET_BROKEN_BRICKS_LOOP:
    1592  77         MOV M, A
    1593  23         INX HL
    1594  77         MOV M, A
    1595  23         INX HL

    1596  05         DCR B                      ; Advance to the next word
    1597  c2 92 15   JNZ RESET_BROKEN_BRICKS_LOOP (1592)

    159a  c9         RET


ARROW_FLYING_RIGHT:
    159b  00         db 00
ARROW_FLYING_LEFT:
    159c  00         db 00
    
ARROW_LEFT_POS:
    159d  11 1d      dw 0000

ARROW_RIGHT_POS:
    159f 0b 14       dw 0000                     


GAME_DELAY:
    15a1  3a d8 0a   LDA PRESSED_KEY (0ad8)     ; Check if the user has changed the speed (pressed 0-9 btns)
    
    15a4  fe 30      CPI A, 30                  ; Validate input
    15a6  da b7 15   JC DO_GAME_DELAY (15b7)
    15a9  fe 3a      CPI A, 3a
    15ab  d2 b7 15   JNC DO_GAME_DELAY (15b7)

    15ae  e6 0f      ANI A, 0f                  ; Calculate new delay value
    15b0  07         RLC
    15b1  07         RLC
    15b2  07         RLC
    15b3  3c         INR A
    15b4  32 c6 15   STA GAME_DELAY_VALUE (15c6)

DO_GAME_DELAY:
    15b7  3a c6 15   LDA GAME_DELAY_VALUE (15c6)
    15ba  47         MOV B, A

GAME_DELAY_LOOP_1:
    15bb  3e ff      MVI A, ff
GAME_DELAY_LOOP_2:
    15bd  3d         DCR A
    15be  c2 bd 15   JNZ GAME_DELAY_LOOP_2 (15bd)
    15c1  05         DCR B
    15c2  c2 bb 15   JNZ GAME_DELAY_LOOP_1 (15bb)
    15c5  c9         RET


GAME_DELAY_VALUE:
    15c6  29         DAD HL



CHECK_MAP_EXIT:
    15c7  3a d8 0a   LDA PRESSED_KEY (0ad8)

    15ca  fe 2e      CPI A, 2e                  ; Pressing '.' will move the player to the next map
    15cc  ca e6 15   JZ GO_NEXT_MAP (15e6)

    15cf  fe 3a      CPI A, 3a                  ; Pressing ':' will exit to the Monitor
    15d1  ca 00 f8   JZ f800

    15d4  2a d4 0a   LHLD PLAYER_POS (0ad4)     ; Check if player reached exit
    15d7  3a bc 08   LDA MAP_EXIT_POS (08bc)
    15da  bd         CMP L
    15db  c2 e5 15   JNZ CHECK_MAP_EXIT_1 (15e5)

    15de  3a bd 08   LDA MAP_EXIT_POS+1 (08bd)
    15e1  bc         CMP H
    15e2  ca e6 15   JZ GO_NEXT_MAP (15e6)
    
CHECK_MAP_EXIT_1:
    15e5  c9         RET

GO_NEXT_MAP:
    15e6  3a 40 02   LDA CURRENT_MAP (0240)     ; Bump the map number
    15e9  3c         INR A
    15ea  32 40 02   STA CURRENT_MAP (0240)

    15ed  21 d0 01   LXI HL, MAP_ADDR_TABLE (01d0)  ; Get next map address
    15f0  11 00 00   LXI DE, 0000
    15f3  17         RAL
    15f4  5f         MOV E, A
    15f5  19         DAD DE

    15f6  7e         MOV A, M                   ; Check if the map address is valid
    15f7  23         INX HL
    15f8  b6         ORA M
    15f9  c2 ff 15   JNZ GO_NEXT_MAP_1 (15ff)

    15fc  32 40 02   STA CURRENT_MAP (0240)     ; Store the new map number

GO_NEXT_MAP_1:
    15ff  3e 01      MVI A, 01                  ; Mark the player is dead to force map reload
    1601  32 c3 11   STA PLAYER_DEAD (11c3)

    1604  c9         RET



REAL_START:
    1605  01 da 0a   LXI BC, GAME_START (0ada)  ; Set the return address where to go after the welcome screen
    1608  c5         PUSH BC

    1609  21 12 16   LXI HL, WELCOME_STR (1612)
    160c  cd 18 f8   CALL MONITOR_PRINT_STR (f818)
    160f  c3 03 f8   JMP MONITOR_WAIT_KBD (f803)

WELCOME_STR:
    1612  1f 1b 59 22 36 17 20 20 17 20 20 20 17 17 17 20
    1622  20 20 17 17 17 20 20 20 17 17 17 1b 59 23 36 17 
    1632  20 17 20 20 20 17 20 20 17 20 20 17 20 20 17 20 
    1642  20 17 20 20 17 1b 59 24 36 17 17 20 20 20 20 17
    1652  20 20 17 20 20 17 20 20 17 20 20 17 20 20 17 1b
    1662  59 25 36 17 20 17 20 20 20 17 20 20 17 20 20 17 
    1672  17 17 17 20 20 17 20 20 17 1b 59 26 36 17 20 20 
    1682  17 20 20 17 20 20 17 20 20 17 20 20 17 20 17 17
    1692  17 17 17 17 1b 59 28 3c 72 69 67 61 20 2a 20 31 
    16a2  39 38 37 1b 59 29 3c 77 65 72 73 69 71 20 20 31 
    16b2  2e 34 1b 59 2a 36 61 77 74 6f 72 20 70 75 6a 73 
    16c2  69 73 2d 70 75 6a 7b 65 20 7c 2e 69 2e 1b 59 2c 
    16d2  2d 77 61 7b 61 20 7a 61 64 61 7e 61 20 73 6f 73 
    16e2  74 6f 69 74 20 77 20 74 6f 6d 20 7e 74 6f 62 79 
    16f2  20 70 72 6f 6a 74 69 1b 59 2d 2c 6c 61 62 69 72 
    1702  69 6e 74 79 2c 6e 61 68 6f 64 71 20 70 6f 20 64 
    1712  6f 72 6f 67 65 20 6b 6c 61 64 2d 1e 2c 73 70 72 
    1722  71 74 61 6e 2d 1b 59 2e 2c 6e 79 6a 20 77 20 73 
    1732  75 6e 64 75 6b 65 2d 14 2e 1b 59 2f 2d 6e 65 6f 
    1742  62 68 6f 64 69 6d 6f 20 74 61 6b 76 65 20 6f 73 
    1752  74 65 72 65 67 61 74 78 73 71 20 6c 60 64 6f 65 
    1762  64 6f 77 2d 0b 2c 1b 59 30 2c 69 20 6e 65 20 75 
    1772  74 6f 6e 75 74 78 20 77 20 77 6f 64 65 2d 5e 5e 
    1782  5e 2e 1b 59 31 2d 73 74 65 6e 79 2c 73 64 65 6c 
    1792  61 6e 6e 79 65 20 69 7a 20 64 65 72 65 77 61 2d 
    17a2  25 2c 6d 6f 76 6e 6f 20 6c 6f 6d 61 74 78 1b 59 
    17b2  32 2c 70 72 69 20 70 6f 6d 6f 7d 69 20 6b 6c 61 
    17c2  77 69 7b 20 22 51 22 20 69 20 22 5e 22 1b 59 33 
    17d2  2d 77 79 20 69 7a 6f 62 72 61 76 61 65 74 65 73 
    17e2  78 2d 09 2c 20 62 65 74 6f 6e 6e 79 65 20 73 74 
    17f2  65 6e 79 2d 58 1b 59 34 2c 64 77 65 72 69 2d 5d 
    1802  20 69 20 5b 2c 20 6d 6f 73 74 69 6b 69 2d 20 1c 
    1812  2c 20 6c 65 73 74 6e 69 63 79 2d 23 2e 1b 59 35 
    1822  2d 75 70 72 61 77 6c 71 74 78 20 73 77 6f 69 6d 
    1832  20 64 77 69 76 65 6e 69 65 6d 20 77 79 20 6d 6f 
    1842  76 65 74 65 20 70 72 69 1b 59 36 2c 70 6f 6d 6f 
    1852  7d 69 20 6b 6c 61 77 69 7b 20 75 70 72 61 77 6c 
    1862  65 6e 69 71 20 6b 75 72 73 6f 72 6f 6d 2c 69 7a 
    1872  6d 65 6e 71 74 78 1b 59 37 2c 73 6b 6f 72 6f 73 
    1882  74 78 20 6b 6c 61 77 69 7b 61 6d 69 20 22 30 2d 
    1892  39 22 2e 00 


; The player has found a treasure. Handle it
; 
; The function updates the box block with a SP symbol representing the treasure.
; Also the function increments the counter, and draw the reward symbol at the top line.
HANDLE_TREASURE:
    1896  3a d9 0a   LDA TREASURES_COUNT (0ad9) ; Increment treasure counter
    1899  3c         INR A
    189a  32 d9 0a   STA TREASURES_COUNT (0ad9)

    189d  36 12      MVI M, 12                  ; Update the treasure box symbol to SP symbol

    189f  c5         PUSH BC                    ; Print reward sign
    18a0  0e 07      MVI C, 07
    18a2  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    18a5  c1         POP BC

    18a6  c9         RET






18a7  00         NOP
18a8  00         NOP
18a9  00         NOP
18aa  00         NOP
18ab  00         NOP
18ac  00         NOP
18ad  00         NOP
18ae  00         NOP
18af  00         NOP

; Format:
;
; Each record is 5 bytes:
; - block type
; - Y1
; - Y2
; - X1
; - X2
;
; Game blocks:           ????
; 01    - outer walls
; 02    - ladders
; 05    - water
; 06    - rope / thin floor
; 07    - treasure
; 0b    - floors
;
MAP_01:
    18b0  01 01 17 00 03    ; Outer walls
    18b5  01 16 17 00 3f
    18ba  01 01 17 3c 3f
    18bf  05 16 16 12 3b 
    18c4  02 12 15 0e 0f 
    18c9  0b 12 12 0a 0d 
    18ce  07 11 11 0a 0a 
    18d3  0b 12 12 10 19 
    18d8  02 0e 11 14 15 
    18dd  0b 0e 0e 16 1d 
    18e2  02 0a 0d 1c 1d 
    18e7  0b 0a 0a 1e 29 
    18ec  02 0a 11 26 27 
    18f1  0b 12 12 1e 29 
    18f6  07 11 11 1e 1e 
    18fb  0b 0e 0e 28 2f 
    1900  02 0e 11 30 31 
    1905  07 09 09 1e 1e 
    190a  0b 12 12 30 37 
    190f  02 0a 11 36 37 
    1914  0b 0a 0a 30 35 
    1919  07 09 09 30 30 
    191e  02 06 09 32 33 
    1923  0b 06 06 12 31 
    1928  06 06 06 1e 27 
    192d  02 06 09 14 15 
    1932  0b 0a 0a 0a 15 
    1937  07 09 09 0a 0a 
    193c  02 0a 0d 0c 0d 
    1941  0b 0e 0e 04 0d 
    1946  0b 06 06 04 0b 
    194b  02 06 0d 06 07 
    1950  0b 03 03 0c 35 
    1955  06 03 03 14 19 
    195a  07 02 02 20 20 
    195f  06 03 03 26 2b 
    1964  0b 01 01 04 2d 
    1969  0b 01 01 30 3b 
    196e  02 01 02 35 35 
    1973  02 03 05 0a 0b 
    1978  00                            ; Marker
    
    1979  0f 04                         ; Player start address (Y,X)
    197b  01 2e                         ; Enemy 1 start address (Y,X)
    197d  00 00                         ; No enemy 2
    197f  00 00                         ; No enemy 3
    1981  00 00                         ; No enemy 4
    1983  00                            ; Number of enemies (1)
    1984  01 35                         ; Exit location
    
    1986  00


MAP_03:
    1987  01 01 17 00 03
    198c  01 15 17 00 3f
    1991  01 01 17 3a 3f
    1996  05 15 16 08 39
    199b  01 15 15 0c 0d
    19a0  01 15 15 12 13
    19a5  01 15 15 18 19
    19aa  01 15 15 1e 1f
    19af  01 15 15 24 25
    19b4  01 15 15 2a 2b
    19b9  01 15 15 30 31
    19be  01 15 15 36 37
    19c3  02 04 14 06 07
    19c8  02 03 14 0c 0d
    19cd  02 04 14 12 13
    19d2  02 03 14 18 19
    19d7  02 04 14 1e 1f
    19dc  02 03 14 24 25
    19e1  02 04 14 2a 2b
    19e6  02 03 14 30 31
    19eb  02 04 14 36 37
    19f0  02 03 03 08 35
    19f5  02 06 06 06 37
    19fa  02 09 09 08 35
    19ff  02 0c 0c 06 35
    1a04  02 0f 0f 06 36
    1a09  02 12 12 06 36
    1a0e  01 01 04 38 3a
    1a13  0a 03 03 39 39
    1a18  02 03 03 38 38
    1a1d  02 01 03 3a 3a
    1a22  07 03 03 06 07
    1a27  07 03 03 12 13
    1a2c  07 03 03 1e 1f
    1a31  07 03 03 2a 2b
    1a36  07 03 03 36 37
    1a3b  07 06 06 0c 0d
    1a40  07 06 06 18 19
    1a45  07 06 06 24 25
    1a4a  07 06 06 30 31
    1a4f  07 09 09 06 07
    1a54  07 09 09 12 13
    1a59  07 09 09 1e 1f
    1a5e  07 09 09 2a 2b
    1a63  07 09 09 36 37
    1a68  07 0c 0c 0c 0d
    1a6d  07 0c 0c 18 19
    1a72  07 0c 0c 24 25
    1a77  07 0c 0c 30 31
    1a7c  07 0f 0f 06 07
    1a81  07 0f 0f 12 13
    1a86  07 0f 0f 1e 1f
    1a8b  07 0f 0f 2a 2b
    1a90  07 0f 0f 36 37
    1a95  07 12 12 0c 0d
    1a9a  07 12 12 18 19
    1a9f  07 12 12 24 25
    1aa4  07 12 12 30 31
    1aa9  08 09 09 1e 1e

    1aae  00                                    ; Separator

    1aaf  07 04                                 ; Player start position
    1ab1  01 0d                                 ; Enemy 1 start position
    1ab3  01 30                                 ; Enemy 2 start position
    1ab4  00 00                                 ; No enemy 3
    1ab7  00 00                                 ; No enemy 4
    1ab9  02                                    ; Number of enemies
    1aba  01 3a                                 ; Exit location

1abc  00
1abd  00         NOP
1abe  00         NOP


MAP_04:
    1abf  01 01 17 00 3f
    1ac4  0e 01 01 0a 0b
    1ac9  0e 05 05 06 09
    1ace  0e 11 11 06 09
    1ad3  0e 15 15 06 10
    1ad8  07 0d 0d 06 09
    1add  0e 09 09 0c 15
    1ae2  0e 05 05 12 1b
    1ae7  0e 02 02 1e 21
    1aec  07 02 02 0c 0f
    1af1  07 0d 0d 24 27
    1af6  0e 0d 0d 18 1b
    1afb  0e 11 11 12 15
    1b00  0e 11 11 1a 27
    1b05  07 15 15 18 1b
    1b0a  0e 15 15 1e 21
    1b0f  07 09 09 1e 21
    1b14  0e 05 05 24 27
    1b19  07 02 02 2a 2d
    1b1e  0e 09 09 2a 33
    1b23  0e 0d 0d 30 33
    1b28  07 05 05 30 33
    1b2d  0e 01 01 34 35
    1b32  0e 11 11 30 33
    1b37  07 15 15 2a 2d
    1b3c  07 15 15 36 39
    1b41  02 07 15 04 05
    1b46  02 02 05 04 05
    1b4b  02 02 09 0a 0b
    1b50  02 0b 0d 0a 0b
    1b55  02 0f 11 0a 0b
    1b5a  02 13 15 0a 0b
    1b5f  02 02 05 10 11
    1b64  02 07 0d 10 11
    1b69  02 0f 15 10 11
    1b6e  02 02 05 16 17
    1b73  02 07 15 16 17
    1b78  02 02 09 1c 1d
    1b7d  02 0b 15 1c 1d
    1b82  02 02 05 22 23
    1b87  02 07 09 22 23
    1b8c  02 0b 0d 22 23
    1b91  02 0f 11 22 23
    1b96  02 13 15 22 23
    1b9b  02 02 0d 28 29
    1ba0  02 0f 15 28 29
    1ba5  02 02 05 2e 2f
    1baa  02 07 09 2e 2f
    1baf  02 0b 11 2e 2f
    1bb4  02 13 15 2e 2f
    1bb9  02 02 05 34 35
    1bbe  02 07 0d 34 35
    1bc3  02 0f 15 34 35
    1bc8  07 15 15 36 39
    1bcd  02 01 15 3a 3a
    1bd2  00
    1bd3  15 06                                 
    1bd5  01 0a
    1bd7  01 34
    1bd9  00 00
    1bdb  00 00
    1bdd  02                                    ; Number of enemies 
    1bde  01 3a                                 ; Exit location


MAP_05:
    1be0  01 01 17 00 03
    1be5  01 16 17 00 3f
    1bea  01 01 17 3a 3f
    1bef  01 0a 0a 00 3f
    1bf4  01 0e 0e 00 3f
    1bf9  01 12 12 00 3f
    1bfe  0b 01 02 04 37
    1c03  06 03 03 0c 35
    1c08  01 06 06 08 3a
    1c0d  01 0b 0c 0a 0b
    1c12  01 0b 15 12 13
    1c17  01 0b 15 22 23
    1c1c  01 0b 15 32 33
    1c21  01 0f 15 2a 33
    1c26  01 0a 0c 22 2b
    1c2b  06 14 14 04 09
    1c30  06 10 10 04 09
    1c35  02 0e 15 06 07
    1c3a  0b 0f 11 0a 0b
    1c3f  0b 13 14 0a 0b
    1c44  04 15 15 0a 0a
    1c49  02 10 15 0e 0f
    1c4e  03 15 15 13 13
    1c53  07 11 11 11 11
    1c58  05 0a 0a 02 05
    1c5d  1a 0b 0b 02 05
    1c62  01 0c 0c 00 07
    1c67  01 0b 0b 06 07
    1c6c  02 0a 0d 0e 0f
    1c71  04 0d 0d 0a 0a
    1c76  03 0d 0d 13 13
    1c7b  07 09 09 06 09
    1c80  03 09 09 0a 0a
    1c85  02 12 13 14 15
    1c8a  06 14 14 16 1f
    1c8f  07 13 13 20 20
    1c94  0b 15 15 16 23
    1c99  0e 0d 0d 12 12
    1c9e  0e 15 15 12 12
    1ca3  01 08 08 06 23
    1ca8  07 11 11 18 18
    1cad  0b 0e 0e 18 2f
    1cb2  01 0c 0d 18 1b
    1cb7  0b 0d 0d 1a 1b
    1cbc  01 0f 12 1a 1b
    1cc1  06 0f 0f 1c 21
    1cc6  05 10 10 1c 21
    1ccb  1a 11 11 1c 21
    1cd0  02 0a 0b 1a 1b
    1cd5  04 09 09 1a 1a
    1cda  05 0b 0b 24 29
    1cdf  06 0a 0a 26 27
    1ce4  07 0d 0d 26 26
    1ce9  07 0b 0b 31 31
    1cee  02 0c 0e 30 31
    1cf3  07 0d 0d 37 37
    1cf8  02 0e 15 38 39
    1cfd  01 11 11 36 37
    1d02  0b 10 11 2e 33
    1d07  08 10 10 2e 2e
    1d0c  07 10 10 2f 2f
    1d11  02 11 15 2c 2d
    1d16  02 11 15 30 31
    1d1b  0b 15 15 2a 2b
    1d20  04 15 15 33 33
    1d25  0e 15 15 32 32
    1d2a  06 0f 0f 24 29
    1d2f  05 10 10 24 29
    1d34  1a 11 11 24 29
    1d39  06 08 08 14 19
    1d3e  06 08 08 24 25
    1d43  06 08 08 28 29
    1d48  04 09 09 2a 2a
    1d4d  0b 0d 0d 22 23
    1d52  06 06 06 14 19
    1d57  06 06 06 24 29
    1d5c  01 08 08 2a 35
    1d61  0b 07 07 34 35
    1d66  02 01 09 3a 3a
    1d6b  02 02 09 36 37
    1d70  01 01 08 38 39
    1d75  0a 09 09 38 38
    1d7a  04 07 07 08 08
    1d7f  01 03 05 0a 0b
    1d84  07 05 05 0c 11
    1d89  0b 03 05 12 13
    1d8e  01 04 04 12 13
    1d93  07 05 05 14 14
    1d98  02 02 05 18 19
    1d9d  0b 05 05 1a 25
    1da2  07 05 05 1c 21
    1da7  01 03 04 1a 1b
    1dac  01 04 05 22 23
    1db1  0b 03 03 22 23
    1db6  07 04 04 24 24
    1dbb  02 02 05 28 29
    1dc0  01 03 04 2a 2b
    1dc5  0b 05 05 2a 2b
    1dca  07 05 05 2c 35
    1dcf  0b 03 03 32 33
    1dd4  01 04 05 32 33
    1dd9  0e 07 07 34 35
    1dde  00
    1ddf  15 04
    1de1  04 16
    1de3  07 34
    1de5  00 00
    1de7  00 00
    1de9  02                                    ; Number of enemies 
    1dea  01 3a                                 ; Exit location


MAP_06:
    1dec  01 01 17 00 03
    1df1  0b 16 17 04 3b
    1df6  01 01 17 3c 3f
    1dfb  01 07 10 08 37
    1e00  05 07 07 0c 11
    1e05  19 08 08 0a 13
    1e0a  19 09 0f 0a 0b
    1e0f  19 09 0f 12 13
    1e14  19 0c 0d 0a 13
    1e19  05 07 07 18 1d
    1e1e  19 08 08 16 1f
    1e23  19 09 09 1e 1f
    1e28  19 08 0b 16 17
    1e2d  19 0b 0b 16 1f
    1e32  19 0b 0e 1e 1f
    1e37  19 0d 0e 16 17
    1e3c  19 0e 0f 18 1d
    1e41  05 07 07 24 29
    1e46  19 08 09 2a 2b
    1e4b  19 08 08 22 29
    1e50  19 09 0e 22 23
    1e55  19 0e 0f 24 29
    1e5a  19 0d 0e 2a 2b
    1e5f  05 07 07 2e 2f
    1e64  19 08 0f 2e 2f
    1e69  05 07 07 34 35
    1e6e  19 08 0f 34 35
    1e73  06 03 05 06 39
    1e78  07 04 04 06 39
    1e7d  01 01 03 1e 23
    1e82  0a 02 02 1e 1e
    1e87  0e 02 02 1f 1f
    1e8c  02 01 02 20 20
    1e91  02 03 12 04 05
    1e96  07 06 11 06 06
    1e9b  07 11 11 06 39
    1ea0  07 06 11 39 39
    1ea5  02 03 11 3a 3b
    1eaa  08 11 11 1a 1a
    1eaf  02 14 14 04 05
    1eb4  02 13 13 06 07
    1eb9  02 15 15 06 07
    1ebe  02 12 12 08 09
    1ec3  02 14 14 08 09
    1ec8  02 13 13 0a 0b
    1ecd  02 15 15 0a 0b
    1ed2  02 12 12 0c 0d
    1ed7  02 14 14 0c 0d
    1edc  02 13 13 0e 0f
    1ee1  02 15 15 0e 0f
    1ee6  02 12 12 10 11
    1eeb  02 14 14 10 11
    1ef0  02 13 13 12 13
    1ef5  02 15 15 12 13
    1efa  02 12 12 14 15
    1eff  02 14 14 14 15
    1f04  02 13 13 16 17
    1f09  02 15 15 16 17
    1f0e  02 12 12 18 19
    1f13  02 14 14 18 19
    1f18  02 13 13 1a 1b
    1f1d  02 15 15 1a 1b
    1f22  02 12 12 1c 1d
    1f27  02 14 14 1c 1d
    1f2c  02 13 13 1e 1f
    1f31  02 15 15 1e 1f
    1f36  02 12 12 20 21
    1f3b  02 14 14 20 21
    1f40  02 13 13 22 23
    1f45  02 15 15 22 23
    1f4a  02 12 12 24 25
    1f4f  02 14 14 24 25
    1f54  02 13 13 26 27
    1f59  02 15 15 26 27
    1f5e  02 12 12 28 29
    1f63  02 14 14 28 29
    1f68  02 13 13 2a 2b
    1f6d  02 15 15 2a 2b
    1f72  02 12 12 2c 2d
    1f77  02 14 14 2c 2d
    1f7c  02 13 13 2e 2f
    1f81  02 15 15 2e 2f
    1f86  02 12 12 30 31
    1f8b  02 14 14 30 31
    1f90  02 13 13 32 33
    1f95  02 15 15 32 33
    1f9a  02 12 12 34 35
    1f9f  02 14 14 34 35
    1fa4  02 13 13 36 37
    1fa9  02 15 15 36 37
    1fae  02 12 12 38 39
    1fb3  02 14 14 38 39
    1fb8  02 13 13 3a 3b
    1fbd  02 15 15 3a 3b
    1fc2  00
    1fc3  15 04
    1fc5  00 07
    1fc7  00 38
    1fc9  00 00
    1fcb  00 00
    1fcd  02                                    ; Number of enemies 
    1fce  01 20                                 ; Exit location


MAP_07:
    1fd0  01 01 17 00 03
    1fd5  01 16 17 00 3f
    1fda  01 01 17 3c 3f
    1fdf  05 16 16 1c 23
    1fe4  06 02 02 18 27
    1fe9  02 02 15 1a 1b
    1fee  02 02 15 24 25
    1ff3  04 15 15 08 08
    1ff8  04 15 15 17 17
    1ffd  04 15 15 28 28
    2002  04 15 15 37 37
    2007  0b 02 02 08 17
    200c  0b 03 03 08 09
    2011  0b 03 03 16 17
    2016  0b 04 04 0a 15
    201b  0b 05 05 08 09
    2020  0b 05 05 16 17
    2025  0b 06 06 0a 15
    202a  0b 07 07 08 09
    202f  0b 07 07 16 17
    2034  0b 08 08 0a 15
    2039  0b 09 09 08 09
    203e  0b 09 09 16 17
    2043  0b 0a 0a 0a 15
    2048  0b 0b 0b 08 09
    204d  0b 0b 0b 16 17
    2052  0b 0c 0c 0a 15
    2057  0b 0f 0f 08 09
    205c  0b 0f 0f 16 17
    2061  0b 0d 0d 08 09
    2066  0b 0d 0d 16 17
    206b  0b 0e 0e 0a 15
    2070  0b 10 10 0a 15
    2075  0b 12 12 0a 15
    207a  0b 11 11 08 09
    207f  0b 11 11 16 17
    2084  0b 13 13 08 09
    2089  0b 13 13 16 17
    208e  0b 14 14 08 17
    2093  07 03 03 0e 11
    2098  07 05 05 0e 11
    209d  07 07 07 0e 11
    20a2  07 09 09 0e 11
    20a7  07 0b 0b 0e 11
    20ac  07 0d 0d 0e 11
    20b1  07 0f 0f 0e 11
    20b6  07 11 11 0e 11
    20bb  07 13 13 0e 11
    20c0  08 13 13 0f 0f
    20c5  0b 02 02 28 37
    20ca  0b 04 04 2a 35
    20cf  0b 06 06 2a 35
    20d4  0b 08 08 2a 35
    20d9  0b 0a 0a 2a 35
    20de  0b 0c 0c 2a 35
    20e3  0b 0e 0e 2a 35
    20e8  0b 10 10 2a 35
    20ed  0b 12 12 2a 35
    20f2  0b 14 14 28 37
    20f7  0b 03 03 28 29
    20fc  0b 05 05 28 29
    2101  0b 07 07 28 29
    2106  0b 09 09 28 29
    210b  0b 0b 0b 28 29
    2110  0b 0d 0d 28 29
    2115  0b 0f 0f 28 29
    211a  0b 11 11 28 29
    211f  0b 13 13 28 29
    2124  0b 03 03 36 37
    2129  0b 05 05 36 37
    212e  0b 07 07 36 37
    2133  0b 09 09 36 37
    2138  0b 0b 0b 36 37
    213d  0b 0d 0d 36 37
    2142  0b 0f 0f 36 37
    2147  0b 11 11 36 37
    214c  0b 13 13 36 37
    2151  07 03 03 2e 31
    2156  07 05 05 2e 31
    215b  07 07 07 2e 31
    2160  07 09 09 2e 31
    2165  07 0b 0b 2e 31
    216a  07 0d 0d 2e 31
    216f  07 0f 0f 2e 31
    2174  07 11 11 2e 31
    2179  07 13 13 2e 31
    217e  01 14 14 3a 3b
    2183  0a 15 15 3a 3a
    2188  02 01 15 3c 3c
    218d  00
    218e  05 04
    2190  00 11
    2192  00 2e
    2194  00 00
    2196  00 00
    2198  02                                    ; Number of enemies 
    219a  01 3c                                 ; Exit location




219b  00
219c  00         NOP
219d  00         NOP
219e  00         NOP
219f  00         NOP
21a0  00         NOP
21a1  00         NOP
21a2  00         NOP
21a3  00         NOP
21a4  00         NOP
21a5  00         NOP
21a6  00         NOP
21a7  00         NOP
21a8  00         NOP
21a9  00         NOP
21aa  00         NOP
21ab  00         NOP
21ac  00         NOP
21ad  00         NOP
21ae  00         NOP
21af  00         NOP
21b0  00         NOP
21b1  00         NOP
21b2  00         NOP
21b3  00         NOP
21b4  00         NOP
21b5  00         NOP
21b6  00         NOP
21b7  00         NOP
21b8  00         NOP
21b9  00         NOP
21ba  00         NOP
21bb  00         NOP
21bc  00         NOP
21bd  00         NOP
21be  00         NOP
21bf  00         NOP
21c0  00         NOP
21c1  00         NOP
21c2  00         NOP
21c3  00         NOP
21c4  00         NOP
21c5  00         NOP
21c6  00         NOP
21c7  00         NOP


MAP_08:
    21c8  01 01 17 00 05
    21cd  01 16 17 00 3f
    21d2  01 01 17 3c 3f
    21d7  05 16 16 06 13
    21dc  07 14 14 04 05
    21e1  06 15 15 06 13
    21e6  02 15 15 14 15
    21eb  05 16 16 2e 3b
    21f0  02 15 15 2c 2d
    21f5  06 15 15 2e 31
    21fa  02 0c 14 30 31
    21ff  06 0c 0c 32 39
    2204  02 02 0b 38 39
    2209  06 02 02 24 37
    220e  0b 02 16 1e 23
    2213  0b 08 0a 14 2d
    2218  07 03 15 20 21
    221d  07 09 09 16 2b
    2222  06 08 08 20 21
    2227  06 0a 0a 20 21
    222c  08 0e 0e 20 20
    2231  06 0e 0e 34 35
    2236  01 0e 0e 36 39
    223b  0b 0f 0f 36 37
    2240  0a 0f 0f 39 39
    2245  01 10 10 34 39
    224a  06 10 10 3a 3b
    224f  02 01 10 3c 3c
    2254  06 0a 0a 2e 33
    2259  00
    225a  15 16
    225c  00 14
    225e  00 2d
    2260  00 00
    2262  00 00
    2264  02                                    ; Number of enemies 
    2265  01 3c                                 ; Exit location


MAP_09:
    2267  01 01 17 00 03
    226c  01 17 17 00 3f
    2271  01 01 17 3b 3f
    2276  02 01 16 3a 3a
    227b  01 01 15 38 39
    2280  02 14 16 06 07
    2285  02 09 14 04 05
    228a  02 05 09 06 07
    228f  07 04 04 07 07
    2294  01 0f 11 06 11
    2299  01 12 16 0c 11
    229e  05 0f 0f 08 0f
    22a3  1a 10 10 08 0f
    22a8  1c 11 16 0e 0e
    22ad  1d 11 16 0f 0f
    22b2  01 0e 0e 0a 0d
    22b7  06 0e 0e 0e 0f
    22bc  06 0f 0f 12 13
    22c1  02 03 04 0b 0b
    22c6  0b 04 04 0c 19
    22cb  0b 06 06 10 19
    22d0  06 06 06 12 13
    22d5  08 05 05 10 10
    22da  07 05 05 14 14
    22df  07 05 05 19 19
    22e4  06 08 08 08 19
    22e9  01 04 06 1a 1b
    22ee  0b 0a 0a 0a 1d
    22f3  01 0b 0c 0c 27
    22f8  01 04 04 1c 23
    22fd  01 05 06 22 23
    2302  01 06 08 1e 1f
    2307  01 08 08 1e 25
    230c  06 08 08 26 27
    2311  02 06 09 1c 1d
    2316  02 06 07 20 21
    231b  0b 04 04 24 27
    2320  01 06 06 24 25
    2325  02 03 07 28 29
    232a  01 07 07 2a 2d
    232f  02 05 06 2c 2d
    2334  02 04 05 2e 2f
    2339  02 03 04 30 31
    233e  02 04 05 32 33
    2343  02 05 05 34 35
    2348  01 06 06 34 37
    234d  02 07 14 36 37
    2352  06 09 09 2c 35
    2357  01 0b 0c 2e 33
    235c  05 0b 0b 30 31
    2361  07 0a 0a 22 25
    2366  0b 0a 0a 26 27
    236b  06 0a 0a 28 29
    2370  06 0b 0b 1e 21
    2375  05 0c 0c 1e 21
    237a  05 0c 0c 24 29
    237f  01 0d 0d 1a 2a
    2384  01 0e 0e 1c 27
    2389  01 0a 0c 2a 2b
    238e  1a 0d 0d 20 27
    2393  0b 0e 0e 28 29
    2398  0b 0f 0f 20 25
    239d  01 0f 10 2a 31
    23a2  02 0f 10 2c 2f
    23a7  0b 0e 0e 2c 2d
    23ac  0b 0f 0f 30 31
    23b1  0b 10 10 2e 2f
    23b6  06 0f 11 32 33
    23bb  07 0e 0e 32 33
    23c0  07 10 10 32 33
    23c5  05 15 15 12 13
    23ca  1a 16 16 12 13
    23cf  06 11 11 14 1f
    23d4  02 10 11 24 25
    23d9  01 10 10 1e 23
    23de  02 10 11 20 21
    23e3  02 10 10 1c 1d
    23e8  07 10 10 14 1b
    23ed  01 15 16 14 16
    23f2  0a 14 14 16 16
    23f7  01 12 13 16 17
    23fc  01 13 13 18 1f
    2401  01 15 15 1a 38
    2406  01 14 14 1a 1b
    240b  07 14 14 1c 1c
    2410  0b 12 14 20 31
    2415  06 12 12 22 23
    241a  02 13 13 20 21
    241f  02 14 14 22 23
    2424  02 13 13 24 25
    2429  06 12 12 26 27
    242e  02 14 14 26 27
    2433  02 13 13 28 29
    2438  06 12 12 2a 2b
    243d  02 14 14 2a 2b
    2442  02 13 13 2c 2d
    2447  06 12 12 2e 2f
    244c  02 14 14 2e 2f
    2451  02 13 13 30 31
    2456  02 14 14 32 33
    245b  0b 13 13 32 33
    2460  0b 10 10 26 27
    2465  00
    2466  15 04
    2468  07 25
    246a  14 1e
    246c  00 00
    246e  00 00
    2470  02                                    ; Number of enemies 
    2471  01 3a                                 ; Exit location


MAP_10:
    2473  01 01 17 00 3f
    2478  18 05 0b 02 05
    247d  0b 01 01 02 17
    2482  18 02 04 02 03
    2487  0e 03 03 06 0f
    248c  07 03 03 06 06
    2491  07 03 03 0f 0f
    2496  02 04 0d 08 09
    249b  0e 0d 0d 04 07
    24a0  02 0e 15 04 05
    24a5  0e 15 15 06 0f
    24aa  02 14 15 10 11
    24af  07 13 13 10 11
    24b4  0e 0f 0f 06 1b
    24b9  02 05 0f 16 17
    24be  0e 09 09 0a 15
    24c3  18 0b 0d 0c 13
    24c8  18 05 07 0c 13
    24cd  18 02 04 12 13
    24d2  18 02 02 14 17
    24d7  18 06 0d 1a 1b
    24dc  18 11 13 08 0d
    24e1  18 11 11 0e 21
    24e6  18 0f 10 1e 21
    24eb  0e 04 04 16 1f
    24f0  02 04 04 1a 1b
    24f5  0e 01 03 1a 1b
    24fa  02 05 0d 1e 1f
    24ff  0e 09 09 20 27
    2504  07 09 09 28 28
    2509  0e 0d 0d 20 27
    250e  07 0d 0d 27 27
    2513  0e 13 13 18 31
    2518  05 14 14 18 19
    251d  02 0e 13 24 25
    2522  07 13 13 1a 1a
    2527  0e 14 14 30 3b
    252c  02 14 14 30 31
    2531  02 0f 14 3a 3b
    2536  0e 0e 0e 3a 3d
    253b  08 0e 0e 3d 3d
    2540  02 10 13 2e 2f
    2545  0e 0f 0f 2e 31
    254a  02 0a 0f 32 33
    254f  0e 09 09 32 3b
    2554  05 0a 0a 3a 3b
    2559  07 09 09 39 39
    255e  02 06 09 30 31
    2563  0e 05 05 30 3b
    2568  0e 03 03 28 2f
    256d  0e 01 02 28 29
    2572  02 04 05 2e 2f
    2577  0a 05 05 34 34
    257c  02 01 05 39 39
    2581  18 12 16 14 15
    2586  18 16 16 16 3d
    258b  18 15 15 1c 2d
    2590  18 02 02 1e 25
    2595  0b 01 01 1e 25
    259a  18 03 07 22 25
    259f  18 05 07 26 2b
    25a4  18 07 0b 2c 2d
    25a9  18 0b 0b 22 2f
    25ae  18 0c 0d 2a 2f
    25b3  18 0e 11 2a 2b
    25b8  18 0f 11 28 29
    25bd  0b 01 01 2c 36
    25c2  18 02 03 32 36
    25c7  0b 01 01 3c 3d
    25cc  18 02 03 3c 3d
    25d1  18 07 07 34 3d
    25d6  18 0b 12 36 37
    25db  18 0c 0c 38 3d
    25e0  18 11 11 32 35
    25e5  18 12 12 34 37
    25ea  00
    25eb  15 06
    25ed  00 1a
    25ef  00 28
    25f1  00 00
    25f3  00 00
    25f5  02                                    ; Number of enemies 
    25f6  01 39                                 ; Exit location


25f8  00
25f9  00         NOP
25fa  00         NOP
25fb  00         NOP
25fc  00         NOP
25fd  00         NOP
25fe  00         NOP
25ff  00         NOP


MAP_11:
    2600  01 01 17 00 03
    2605  01 16 17 00 3f
    260a  01 01 15 3c 3f
    260f  1a 16 16 14 27
    2614  1a 16 16 2c 33
    2619  01 15 15 12 3f
    261e  05 15 15 14 27
    2623  05 15 15 2c 33
    2628  0b 01 01 06 1d
    262d  0b 01 01 20 3b
    2632  0b 13 13 06 23
    2637  06 13 13 18 1b
    263c  06 13 13 24 27
    2641  0b 11 12 06 0b
    2646  0b 0d 10 06 09
    264b  0b 05 0c 06 07
    2650  0b 11 11 0e 25
    2655  06 11 11 18 19
    265a  02 11 15 10 11
    265f  01 0e 0f 0c 11
    2664  05 0e 0e 0e 0f
    2669  0b 0a 0d 0c 0d
    266e  06 0a 0a 08 0b
    2673  0b 0e 0f 12 17
    2678  02 0e 10 14 15
    267d  0b 03 03 0c 2d
    2682  0b 05 05 0c 0d
    2687  0b 08 08 0c 0d
    268c  06 04 04 08 09
    2691  02 03 08 0a 0b
    2696  06 08 08 0e 0f
    269b  02 08 0d 10 11
    26a0  0b 0b 0b 12 17
    26a5  0b 0c 0c 16 17
    26aa  06 09 09 12 13
    26af  0b 09 09 14 1b
    26b4  0b 0a 0c 1a 1b
    26b9  0b 0c 0c 1c 1f
    26be  0b 0d 0d 1e 1f
    26c3  06 0e 0e 18 19
    26c8  0b 0e 0e 1a 1b
    26cd  0b 0f 0f 1a 29
    26d2  06 0f 0f 20 21
    26d7  0b 05 05 10 1b
    26dc  02 03 04 1a 1b
    26e1  0b 05 05 1e 1f
    26e6  0b 07 07 14 35
    26eb  0b 08 0a 1e 1f
    26f0  06 07 07 12 13
    26f5  06 07 07 1c 1d
    26fa  06 07 07 20 21
    26ff  02 07 08 2c 2d
    2704  06 07 07 2e 33
    2709  0b 05 05 24 33
    270e  0b 06 06 2a 2b
    2713  02 05 06 22 23
    2718  02 04 05 2a 2b
    271d  06 05 05 2e 2f
    2722  0b 09 09 24 3b
    2727  02 09 0a 22 23
    272c  01 0b 0d 22 2b
    2731  06 0b 0b 24 27
    2736  05 0c 0c 24 29
    273b  06 09 09 2e 2f
    2740  06 09 09 32 33
    2745  0b 0b 0b 28 2d
    274a  0b 0b 0e 2e 31
    274f  06 0b 0b 2e 2f
    2754  06 0b 0b 32 33
    2759  0b 0b 0c 34 37
    275e  0b 0e 11 34 37
    2763  02 0b 14 38 39
    2768  0b 10 10 28 31
    276d  06 10 10 2a 2d
    2772  01 12 13 28 29
    2777  02 12 14 2a 2b
    277c  06 12 12 2c 2d
    2781  0b 12 12 2e 2f
    2786  0b 13 14 2e 31
    278b  06 13 13 32 33
    2790  0b 13 14 34 35
    2795  0b 02 03 30 31
    279a  02 03 04 32 33
    279f  0b 03 04 34 3b
    27a4  0b 05 07 38 39
    27a9  02 04 06 36 37
    27ae  0b 05 05 3a 3b
    27b3  02 01 02 39 39
    27b8  0a 02 02 34 34
    27bd  07 04 04 06 07
    27c2  07 0c 0c 08 09
    27c7  07 10 10 0a 0b
    27cc  07 0a 0a 16 17
    27d1  07 12 12 1e 1e
    27d6  07 14 14 28 29
    27db  07 0c 0c 2e 2f
    27e0  07 02 02 2c 2c
    27e5  07 04 04 16 17
    27ea  07 04 04 3a 3b
    27ef  08 04 04 16 16
    27f4  00
    27f5  01 04
    27f7  01 1e
    27f9  00 00
    27fb  00 00
    27fd  00 00
    27ff  01                                    ; Number of enemies 
    2800  00 39                                 ; Exit location


2802  00         NOP
2803  00         NOP
2804  00         NOP
2805  00         NOP
2806  00         NOP
2807  00         NOP
2808  00         NOP
2809  00         NOP
280a  00         NOP
280b  00         NOP
280c  00         NOP
280d  00         NOP
280e  00         NOP
280f  00         NOP


MAP_12:
    2810  01 01 17 00 03
    2815  01 17 17 00 3f
    281a  0b 16 16 04 0b
    281f  01 01 16 3c 3f
    2824  05 16 16 0c 3b
    2829  02 14 15 0a 0b
    282e  06 14 14 0c 15
    2833  02 14 14 16 17
    2838  06 15 15 18 25
    283d  02 14 14 26 27
    2842  06 14 14 28 37
    2847  02 12 13 38 39
    284c  06 12 12 26 37
    2851  02 12 12 24 25
    2856  06 13 13 1a 23
    285b  02 12 12 18 19
    2860  06 12 12 0c 17
    2865  02 10 12 0a 0b
    286a  06 10 10 0c 19
    286f  02 10 10 1a 1b
    2874  06 11 11 1c 21
    2879  02 10 10 22 23
    287e  06 10 10 24 37
    2883  02 02 10 38 39
    2888  06 0e 0e 36 37
    288d  0b 0e 0e 34 35
    2892  06 02 02 24 37
    2897  06 03 03 1c 1f
    289c  02 03 04 20 21
    28a1  02 05 05 1e 1f
    28a6  02 06 07 1c 1d
    28ab  02 08 08 1e 1f
    28b0  02 09 0a 20 21
    28b5  02 0b 0d 22 23
    28ba  0b 0e 0e 24 25
    28bf  06 0e 0e 26 2f
    28c4  02 0c 0e 30 31
    28c9  06 0c 0c 28 2f
    28ce  02 0a 0c 26 27
    28d3  06 0a 0a 28 2f
    28d8  02 08 0a 30 31
    28dd  06 08 08 28 2f
    28e2  02 06 08 26 27
    28e7  06 06 06 28 31
    28ec  02 05 06 32 33
    28f1  02 04 04 30 31
    28f6  06 04 04 28 2f
    28fb  07 04 04 27 27
    2900  07 08 08 34 34
    2905  07 0a 0a 34 34
    290a  07 0c 0c 34 34
    290f  02 0f 0f 1e 1f
    2914  02 0e 0e 1c 1d
    2919  02 0e 0e 20 21
    291e  06 0e 0e 0e 1b
    2923  0b 0e 0e 0c 0d
    2928  07 0d 0d 0c 15
    292d  06 0d 0d 18 1b
    2932  0b 0c 0c 0a 0b
    2937  06 0c 0c 0c 15
    293c  07 0b 0b 0a 15
    2941  07 0c 0c 18 19
    2946  02 0b 0c 1a 1b
    294b  02 0c 0c 1e 1f
    2950  02 0b 0b 1c 1d
    2955  02 0a 0a 18 19
    295a  02 09 09 16 17
    295f  02 08 08 14 15
    2964  02 07 07 12 13
    2969  02 06 06 10 11
    296e  02 05 05 0e 0f
    2973  02 04 04 0c 0d
    2978  02 03 03 0a 0b
    297d  02 01 02 09 09
    2982  0b 04 05 06 09
    2987  0a 06 06 08 08
    298c  02 07 0d 06 07
    2991  0b 07 07 08 09
    2996  06 07 07 0a 11
    299b  07 09 09 08 09
    29a0  0b 0a 0a 08 09
    29a5  07 0d 0d 08 09
    29aa  0b 0e 0e 08 09
    29af  07 02 02 1c 1d
    29b4  08 09 09 09 09
    29b9  00
    29ba  10 04
    29bc  01 0b
    29be  00 00
    29c0  00 00
    29c2  00 00
    29c4  01                                    ; Number of enemies 
    29c5  00 09                                 ; Exit location



29c7  00         NOP
29c8  00         NOP
29c9  00         NOP
29ca  00         NOP
29cb  00         NOP
29cc  00         NOP
29cd  00         NOP
29ce  00         NOP
29cf  00         NOP


MAP_13:
    29d0  01 01 17 00 03
    29d5  01 15 17 04 3f
    29da  01 01 14 3a 3f
    29df  05 16 16 04 39
    29e4  06 15 15 0a 35
    29e9  06 03 03 05 1d
    29ee  02 03 14 04 04
    29f3  02 01 14 39 39
    29f8  01 14 14 08 09
    29fd  01 13 13 36 38
    2a02  0a 14 14 36 36
    2a07  0b 03 04 1e 1f
    2a0c  0b 05 05 1a 23
    2a11  0b 06 06 18 1d
    2a16  0b 06 06 20 25
    2a1b  0b 07 07 1c 21
    2a20  0b 08 08 18 25
    2a25  0b 09 09 16 1b
    2a2a  0b 09 09 22 27
    2a2f  0b 0a 0a 1a 23
    2a34  0b 0b 0b 18 25
    2a39  0b 0c 0c 16 1b
    2a3e  0b 0c 0c 22 27
    2a43  0b 0d 0d 1a 23
    2a48  0b 0e 0e 16 27
    2a4d  0b 0f 0f 14 1b
    2a52  0b 0f 0f 22 29
    2a57  0b 10 10 1a 23
    2a5c  0b 11 11 14 29
    2a61  0b 12 12 12 1b
    2a66  0b 12 12 22 2b
    2a6b  0b 13 14 18 19
    2a70  0b 13 14 24 25
    2a75  0b 15 16 12 2b
    2a7a  07 07 07 1e 1f
    2a7f  07 0a 0a 1c 21
    2a84  07 0d 0d 1c 21
    2a89  07 10 10 1c 21
    2a8e  07 14 14 1c 21
    2a93  02 08 14 1e 1f
    2a98  08 14 14 1c 1c
    2a9d  00
    2a9e  14 07
    2aa0  12 1c
    2aa2  12 21
    2aa4  00 00
    2aa6  00 00
    2aa8  02                                    ; Number of enemies 
    2aa9  00 39                                 ; Exit location


2aab  00         NOP
2aac  00         NOP
2aad  00         NOP
2aae  00         NOP
2aaf  00         NOP


MAP_14:
    2ab0  01 01 17 00 03
    2ab5  01 17 17 04 3f
    2aba  01 01 16 3c 3f
    2abf  01 01 01 04 13
    2ac4  01 01 01 16 2b
    2ac9  01 01 01 2e 3b
    2ace  0b 13 16 14 2d
    2ad3  05 13 13 0a 13
    2ad8  05 13 13 1a 27
    2add  05 13 13 2e 37
    2ae2  1a 14 16 0a 13
    2ae7  1a 14 16 1a 27
    2aec  1a 14 16 2e 3b
    2af1  01 12 13 04 05
    2af6  01 12 16 08 09
    2afb  01 16 16 04 07
    2b00  02 12 15 06 07
    2b05  06 04 04 0c 35
    2b0a  06 06 06 0c 1b
    2b0f  06 06 06 26 35
    2b14  06 08 08 0c 35
    2b19  06 0a 0a 0c 13
    2b1e  06 0c 0c 0c 13
    2b23  06 0e 0e 0c 13
    2b28  06 10 10 0c 13
    2b2d  06 12 12 0c 0f
    2b32  06 0a 0a 2e 35
    2b37  06 0c 0c 2e 35
    2b3c  06 0e 0e 2e 35
    2b41  06 10 10 2e 35
    2b46  06 12 12 32 35
    2b4b  0b 0a 0a 1a 27
    2b50  06 0a 0a 1c 25
    2b55  06 0c 0c 20 23
    2b5a  06 0e 0e 1e 21
    2b5f  06 0f 0f 1a 1b
    2b64  06 0f 0f 26 27
    2b69  06 10 10 20 23
    2b6e  06 12 12 1a 21
    2b73  06 12 12 26 27
    2b78  0b 04 05 20 21
    2b7d  0b 06 07 1e 1f
    2b82  0b 06 07 22 23
    2b87  0b 08 09 1c 1d
    2b8c  0b 08 09 24 25
    2b91  0b 0c 0d 28 29
    2b96  0b 0c 0d 18 19
    2b9b  0b 0e 0e 16 17
    2ba0  0b 0e 0e 2a 2b
    2ba5  0b 10 10 14 19
    2baa  0b 10 10 28 2d
    2baf  0b 12 12 14 15
    2bb4  0b 12 12 2c 2d
    2bb9  02 04 12 0a 0b
    2bbe  02 04 12 10 11
    2bc3  02 04 0d 16 17
    2bc8  02 04 07 1c 1d
    2bcd  02 04 07 24 25
    2bd2  02 04 0d 2a 2b
    2bd7  02 04 12 30 31
    2bdc  02 04 12 36 37
    2be1  02 0c 12 1c 1d
    2be6  02 0c 12 24 25
    2beb  01 02 14 38 3b
    2bf0  0e 11 11 38 3b
    2bf5  02 01 11 3b 3b
    2bfa  0a 11 11 39 39
    2bff  07 07 07 20 21
    2c04  07 09 09 20 21
    2c09  07 0b 0b 20 21
    2c0e  07 0d 0d 20 21
    2c13  07 0f 0f 20 21
    2c18  07 11 11 20 21
    2c1d  08 0f 0f 20 20
    2c22  03 0f 0f 16 16
    2c27  04 0f 0f 2b 2b
    2c2c  00
    2c2d  14 04
    2c2f  01 14
    2c31  01 2d
    2c33  00 00
    2c35  00 00
    2c37  02                                    ; Number of enemies 
    2c38  00 3b                                 ; Exit location


2c3a  00         NOP
2c3b  00         NOP
2c3c  00         NOP
2c3d  00         NOP
2c3e  00         NOP
2c3f  00         NOP



MAP_15:
    2c40  01 01 17 00 03
    2c45  01 16 17 04 3f
    2c4a  01 01 15 3c 3f
    2c4f  05 16 16 0e 33
    2c54  02 04 15 06 07
    2c59  06 04 04 08 21
    2c5e  0b 02 02 20 21
    2c63  0b 04 04 1e 1f
    2c68  0b 04 04 22 23
    2c6d  0b 06 06 1c 25
    2c72  06 06 06 20 21
    2c77  0b 08 08 1a 1b
    2c7c  0b 08 08 1e 23
    2c81  0b 08 08 26 27
    2c86  0b 0a 0a 18 1b
    2c8b  0b 0a 0a 1e 23
    2c90  0b 0a 0a 26 29
    2c95  0b 0c 0c 16 19
    2c9a  0b 0c 0c 1c 25
    2c9f  0b 0c 0c 28 2b
    2ca4  0b 0e 0e 14 17
    2ca9  0b 0e 0e 1a 27
    2cae  0b 0e 0e 2a 2d
    2cb3  0b 10 10 12 15
    2cb8  0b 10 10 18 29
    2cbd  0b 10 10 2c 2f
    2cc2  0b 12 12 10 13
    2cc7  0b 12 12 16 2b
    2ccc  0b 12 12 2e 31
    2cd1  0b 14 14 0e 33
    2cd6  07 05 05 1e 23
    2cdb  07 07 07 1e 23
    2ce0  07 09 09 1e 23
    2ce5  07 0b 0b 1e 23
    2cea  07 0d 0d 1e 23
    2cef  07 0f 0f 1e 23
    2cf4  07 11 11 1e 23
    2cf9  07 13 13 1e 23
    2cfe  0e 07 14 20 21
    2d03  01 14 14 38 3b
    2d08  02 01 15 3b 3b
    2d0d  0a 15 15 39 39
    2d12  0e 05 05 20 21
    2d17  08 09 09 23 23
    2d1c  00
    2d1d  14 04
    2d1f  01 1c
    2d21  01 25
    2d23  00 00
    2d25  00 00
    2d27  02                                    ; Number of enemies 
    2d28  00 3b                                 ; Exit location



2d2a  00         NOP
2d2b  00         NOP
2d2c  00         NOP
2d2d  00         NOP
2d2e  00         NOP
2d2f  00         NOP



MAP_16:
    2d30  01 01 17 00 03
    2d35  01 17 17 04 3f
    2d3a  01 01 16 3a 3f
    2d3f  0e 11 11 3a 3c
    2d44  05 13 13 04 39
    2d49  1b 14 16 04 39
    2d4e  02 02 11 02 03
    2d53  06 03 03 04 37
    2d58  02 03 08 38 39
    2d5d  06 07 07 08 37
    2d62  07 09 11 20 21
    2d67  06 0c 0c 06 39
    2d6c  06 09 0a 30 37
    2d71  02 09 09 30 31
    2d76  02 0a 0b 38 39
    2d7b  06 09 0a 08 11
    2d80  02 07 08 06 07
    2d85  02 09 09 10 11
    2d8a  02 0a 0b 06 07
    2d8f  06 12 12 04 13
    2d94  06 12 12 2e 39
    2d99  0b 04 05 20 21
    2d9e  0b 06 07 1e 23
    2da3  0b 08 09 1c 1f
    2da8  0b 0a 0b 1a 1d
    2dad  0b 0c 0d 18 1b
    2db2  0b 0e 0f 16 19
    2db7  0b 10 10 14 17
    2dbc  0b 11 13 14 15
    2dc1  0b 13 13 16 19
    2dc6  0b 12 12 18 19
    2dcb  0b 08 09 22 25
    2dd0  0b 0a 0b 24 27
    2dd5  0b 0c 0d 26 29
    2dda  0b 0e 0f 28 2b
    2ddf  0b 10 10 2a 2b
    2de4  0b 11 13 2c 2d
    2de9  0b 13 13 28 2b
    2dee  0b 12 12 28 29
    2df3  06 0a 0a 1e 23
    2df8  06 0e 0e 1a 21
    2dfd  06 0e 0e 26 27
    2e02  06 10 10 1a 1b
    2e07  06 10 10 20 27
    2e0c  06 12 12 1a 21
    2e11  06 12 12 26 27
    2e16  02 0e 12 1c 1d
    2e1b  02 0e 12 24 25
    2e20  0a 11 11 3b 3b
    2e25  02 01 11 3d 3d
    2e2a  08 11 11 21 21
    2e2f  01 01 01 04 1d
    2e34  01 01 01 20 21
    2e39  01 01 01 24 3a
    2e3e  00
    2e3f  02 02
    2e41  01 1f
    2e43  01 22
    2e45  00 00
    2e47  00 00
    2e49  02                                    ; Number of enemies 
    2e4a  00 3d                                 ; Exit location



2e4c  00         NOP
2e4d  00         NOP
2e4e  00         NOP
2e4f  00         NOP



MAP_17:
    2e50  01 01 17 00 03
    2e55  01 16 17 04 3f
    2e5a  01 01 17 3c 3f
    2e5f  02 13 15 09 09
    2e64  02 04 12 0a 0a
    2e69  06 04 04 0b 1d
    2e6e  0b 02 02 20 21
    2e73  0b 04 04 1e 23
    2e78  0b 06 06 1c 25
    2e7d  06 06 06 1e 1f
    2e82  06 06 06 22 23
    2e87  07 05 05 20 21
    2e8c  0b 08 08 1a 1b
    2e91  0b 08 08 1e 23
    2e96  0b 08 08 26 27
    2e9b  07 09 09 1c 1d
    2ea0  07 09 09 24 25
    2ea5  0b 0a 0a 18 19
    2eaa  0b 0a 0a 1c 1f
    2eaf  0b 0a 0a 22 25
    2eb4  0b 0a 0a 28 29
    2eb9  07 0b 0b 1a 1b
    2ebe  07 0b 0b 26 27
    2ec3  0b 0c 0c 16 17
    2ec8  06 0c 0c 1a 1b
    2ecd  01 0c 0e 1c 1d
    2ed2  01 0e 0e 1e 25
    2ed7  01 0c 0d 24 25
    2edc  0b 0c 0c 26 2b
    2ee1  06 0c 0c 28 29
    2ee6  02 0e 0e 18 19
    2eeb  0b 0e 0e 14 15
    2ef0  05 0d 0d 1e 23
    2ef5  02 0e 0e 28 29
    2efa  0b 0e 0e 2c 2d
    2eff  0b 10 10 12 13
    2f04  0b 10 10 16 1f
    2f09  06 10 10 18 1b
    2f0e  0b 10 10 22 2b
    2f13  0b 10 10 2e 2f
    2f18  0b 12 12 10 17
    2f1d  06 12 12 12 13
    2f22  0b 12 12 1a 1f
    2f27  06 12 12 20 21
    2f2c  0b 12 12 24 27
    2f31  0b 12 12 2a 31
    2f36  06 12 12 2e 2f
    2f3b  0b 14 14 0e 15
    2f40  0b 14 14 18 19
    2f45  0b 14 14 1c 1f
    2f4a  0b 14 14 22 29
    2f4f  0b 14 14 2c 2f
    2f54  0b 14 14 32 33
    2f59  01 14 14 38 3b
    2f5e  0a 15 15 39 39
    2f63  02 01 15 3b 3b
    2f68  07 0f 0f 16 17
    2f6d  04 0f 0f 1a 1b
    2f72  07 0f 0f 2a 2b
    2f77  07 11 11 14 15
    2f7c  07 11 11 1e 1f
    2f81  07 11 11 2c 2d
    2f86  03 13 13 10 10
    2f8b  07 13 13 22 23
    2f90  08 11 11 1e 1e
    2f95  00
    2f96  15 04
    2f98  01 1a
    2f9a  01 27
    2f9c  00 00
    2f9e  00 00
    2fa0  02                                    ; Number of enemies 
    2fa1  00 3b                                 ; Exit location



2fa3  00         NOP
2fa4  00         NOP
2fa5  00         NOP
2fa6  00         NOP
2fa7  00         NOP
2fa8  00         NOP
2fa9  00         NOP
2faa  00         NOP
2fab  00         NOP
2fac  00         NOP
2fad  00         NOP
2fae  00         NOP
2faf  00         NOP



MAP_18:
    2fb0  01 01 17 00 03
    2fb5  01 16 17 04 3f
    2fba  01 01 15 3c 3f
    2fbf  05 16 16 10 3b
    2fc4  06 15 15 08 3b
    2fc9  02 03 15 04 05
    2fce  01 04 14 06 07
    2fd3  01 14 15 0e 0f
    2fd8  06 03 03 06 0b
    2fdd  06 02 02 12 2b
    2fe2  06 03 03 0e 29
    2fe7  06 04 04 14 29
    2fec  06 05 05 0a 25
    2ff1  02 01 02 0e 0e
    2ff6  02 02 02 28 29
    2ffb  06 07 07 0a 19
    3000  06 07 07 20 25
    3005  02 05 06 08 09
    300a  02 08 09 08 09
    300f  06 09 09 0a 0d
    3014  01 06 09 0e 0f
    3019  02 07 09 10 11
    301e  06 0a 0a 10 13
    3023  01 0c 0c 0c 0f
    3028  02 0d 0d 0a 0b
    302d  01 0e 0f 08 0b
    3032  05 0e 0e 08 09
    3037  02 11 14 08 09
    303c  01 11 13 0a 0b
    3041  02 0e 10 0c 0d
    3046  01 11 11 0c 0f
    304b  01 0e 10 0e 0f
    3050  06 0e 0e 10 17
    3055  01 0f 0f 10 19
    305a  06 0f 0f 12 13
    305f  02 0a 0d 14 15
    3064  01 09 0d 16 17
    3069  02 09 0e 18 19
    306e  02 07 07 1e 1f
    3073  02 07 07 26 27
    3078  06 09 09 1a 21
    307d  02 09 09 1e 1f
    3082  02 04 09 2a 2b
    3087  06 0a 0a 24 2b
    308c  02 0a 0e 22 23
    3091  0b 0b 0b 1c 1d
    3096  0b 0d 0d 1c 1d
    309b  0b 0f 0f 20 23
    30a0  06 0f 0f 1e 1f
    30a5  02 0f 0f 1c 1d
    30aa  06 10 10 1e 23
    30af  01 10 10 1c 1d
    30b4  02 10 11 1a 1b
    30b9  01 11 11 1c 27
    30be  02 0c 0e 26 27
    30c3  06 11 11 24 25
    30c8  06 0c 0c 28 29
    30cd  01 0f 0f 26 27
    30d2  06 0f 0f 28 2f
    30d7  06 11 11 28 2f
    30dc  06 12 12 12 19
    30e1  01 13 13 12 27
    30e6  06 13 13 0e 11
    30eb  06 13 13 14 19
    30f0  06 13 13 24 25
    30f5  06 13 13 28 29
    30fa  02 13 14 1c 1d
    30ff  0b 0d 0d 2a 2b
    3104  0b 0f 0f 2a 2b
    3109  0b 11 11 2a 2b
    310e  0b 13 13 2a 2b
    3113  02 11 11 30 31
    3118  0b 11 11 32 33
    311d  0b 11 11 36 37
    3122  02 11 12 38 39
    3127  0b 13 13 36 39
    312c  06 13 13 34 35
    3131  02 13 14 32 33
    3136  07 02 0e 34 35
    313b  0b 03 03 30 37
    3140  0b 05 05 32 37
    3145  0b 09 09 32 37
    314a  0b 07 07 32 37
    314f  0b 0b 0b 32 37
    3154  0b 0d 0d 32 37
    3159  0b 0f 0f 30 37
    315e  02 02 03 2e 2f
    3163  02 03 03 34 35
    3168  02 03 04 38 39
    316d  02 05 06 30 31
    3172  02 05 05 34 35
    3177  02 07 07 34 35
    317c  02 07 08 38 39
    3181  02 09 09 34 35
    3186  02 09 0a 30 31
    318b  02 0b 0b 34 35
    3190  02 0b 0c 38 39
    3195  02 0d 0d 34 35
    319a  02 0d 0e 30 31
    319f  02 0f 0f 34 35
    31a4  01 01 01 32 33
    31a9  01 01 01 36 3b
    31ae  01 02 02 2c 2d
    31b3  07 02 02 0a 0b
    31b8  07 02 02 10 11
    31bd  07 01 01 12 13
    31c2  07 06 06 0c 0d
    31c7  07 08 08 0c 0d
    31cc  07 06 06 18 19
    31d1  07 06 06 1e 1f
    31d6  07 06 06 26 27
    31db  07 08 08 1c 1d
    31e0  07 08 08 20 21
    31e5  07 0a 0a 1c 1d
    31ea  07 0c 0c 1c 1d
    31ef  07 0b 0b 0e 0f
    31f4  07 0c 0c 0a 0b
    31f9  07 0c 0c 2a 2b
    31fe  07 0e 0e 2a 2b
    3203  07 10 10 2a 2b
    3208  07 12 12 2a 2b
    320d  07 12 12 1c 1d
    3212  07 12 12 20 21
    3217  07 14 14 10 11
    321c  08 12 12 1c 1c
    3221  03 11 11 12 13
    3226  04 12 12 1a 1b
    322b  04 12 12 1e 1e
    3230  03 12 12 32 33
    3235  09 02 02 33 33
    323a  00
    323b  15 06
    323d  00 11
    323f  00 34
    3241  00 00
    3243  00 00
    3245  02                                    ; Number of enemies 
    3246  00 0e                                 ; Exit location


3248  00
3249  00         NOP
324a  00         NOP
324b  00         NOP
324c  00         NOP
324d  00         NOP
324e  00         NOP
324f  00         NOP


MAP_19:
    3250  01 01 17 00 05
    3255  01 16 17 00 3f
    325a  01 01 17 3c 3f
    325f  05 16 16 06 09
    3264  05 16 16 38 3b
    3269  01 0e 14 0c 35
    326e  02 0e 15 0a 0b
    3273  02 04 0e 06 07
    3278  06 0f 0f 06 09
    327d  05 0f 0f 0e 1f
    3282  05 0f 0f 22 33
    3287  0b 04 08 08 11
    328c  02 04 04 10 11
    3291  01 05 07 08 09
    3296  01 05 06 10 11
    329b  07 05 07 0a 0f
    32a0  01 09 0c 08 09
    32a5  06 09 09 0a 0f
    32aa  01 09 0c 10 11
    32af  07 0a 0c 0a 0f
    32b4  06 08 08 12 1b
    32b9  0b 09 09 14 15
    32be  01 0a 0d 14 15
    32c3  02 0a 0d 16 17
    32c8  01 0d 0d 18 1b
    32cd  06 0e 0e 1e 23
    32d2  02 01 0e 20 21
    32d7  06 08 08 26 2f
    32dc  0b 09 09 2c 2d
    32e1  02 0a 0d 2a 2b
    32e6  01 0d 0d 26 29
    32eb  01 0a 0d 2c 2d
    32f0  0b 04 08 30 39
    32f5  02 04 04 30 31
    32fa  01 05 06 30 31
    32ff  01 05 07 38 39
    3304  07 05 07 32 37
    3309  02 04 0e 3a 3b
    330e  06 0f 0f 38 3b
    3313  01 09 0c 30 39
    3318  06 09 09 32 37
    331d  07 0a 0c 32 37
    3322  02 0e 15 36 37
    3327  1b 10 12 0e 33
    332c  01 01 01 06 1f
    3331  01 01 01 21 3b
    3336  00
    3337  15 20
    3339  02 18
    333b  02 29
    333d  00 00
    333f  00 00
    3341  02                                    ; Number of enemies 
    3342  00 20                                 ; Exit location


3344  00         NOP
3345  00         NOP
3346  00         NOP
3347  00         NOP
3348  00         NOP
3349  00         NOP
334a  00         NOP
334b  00         NOP
334c  00         NOP
334d  00         NOP
334e  00         NOP
334f  00         NOP

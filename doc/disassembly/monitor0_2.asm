; Memory copying function
; Enters 3 parameters:
; - Source start address
; - Source end address
; - Destination start address
;
; Depending on the entered parameters, the program can copy data
; up or down. Overlapped regions are supported (will be overwritten)
MEM_COPY:
    0200  cd 24 02   CALL 0224                  ; Enter and validate addresses

    0203  da 0a 02   JC 020a                    ; Copy down up?
    0206  cd 0e 02   CALL MEM_COPY_DOWN (020e)
    0209  c7         RST 0                      ; The end (reset)

    020a  cd 19 02   CALL MEM_COPY_UP (0219)
    020d  c7         RST 0                      ; The end (reset)

; Copy memory from end address down to start address
; HL = dest end addr
; BC = source start address
; DE = source end address
MEM_COPY_DOWN:
    020e  1a         LDAX DE                ; Copy the byte (from end to start)
    020f  77         MOV M, A

    0210  cd 94 01   CALL CMP_BC_DE (0194)

    0213  1b         DCX DE                 ; Decrement pointers
    0214  2b         DCX HL
    0215  c2 0e 02   JNZ MEM_COPY_DOWN (020e)   ; Until start address reached

    0218  c9         RET


MEM_COPY_UP:
; Copy memory from start address up to end address
; HL = dest start addr
; BC = source start address
; DE = source end address
    0219  0a         LDAX BC         ; Copy the byte
    021a  77         MOV M, A

    021b  cd 94 01   CALL CMP_BC_DE (0194)

    021e  03         INX BC          ; Increment pointers until end addr reached
    021f  23         INX HL
    0220  c2 19 02   JNZ MEM_COPY_UP (0219)

    0223  c9         RET

; Helper function that enters source start and end addresses, and destination 
; start address. A few more parameters are calculated, and stored as follows:
; - 0xc3f0  - Source start address
; - 0xc3f2  - Source end address
; - 0xc3f4  - Destination start address
; - 0xc3f6  - Destination end address
; - 0xc3f8  - Difference between Destination and Source start addresses
;
; Return:
; Carry=1 and HL=dest start addr, if destination address is lower than source address
; Carry=0 and HL=dest end addr, otherwise
; BC = source start address
; DE = source end address
ENTER_ADDR:
    0224  f7         RST 6                  ; Enter source start address to DE
    0225  d5         PUSH DE
    0226  f7         RST 6                  ; Enter source end address to HL
    0227  eb         XCHG
    0228  22 f2 c3   SHLD c3f2              ; Store source end address at 0xc3f2

    022b  e1         POP HL
    022c  22 f0 c3   SHLD c3f0              ; Store source start address at 0xc3f0

    022f  f7         RST 6                  ; Enter destination start address to HL
    0230  eb         XCHG
    0231  22 f4 c3   SHLD c3f4              ; Store destination start address at 0xc3f4

    0234  7d         MOV A, L               ; HL = <dest start> - <source start>
    0235  93         SUB E
    0236  6f         MOV L, A
    0237  7c         MOV A, H
    0238  9a         SBB D
    0239  67         MOV H, A
    023a  22 f8 c3   SHLD c3f8              ; Store difference at 0xc3f8

    023d  4d         MOV C, L               ; Calculate destination end address
    023e  44         MOV B, H
    023f  2a f2 c3   LHLD c3f2
    0242  e5         PUSH HL
    0243  09         DAD BC                 ; Store destination end addr at 0xc3f6
    0244  22 f6 c3   SHLD c3f6

    0247  2a f0 c3   LHLD c3f0              ; Load source start address to BC
    024a  4d         MOV C, L
    024b  44         MOV B, H
    024c  d1         POP DE                 ; Load source end address to DE
    024d  2a f4 c3   LHLD c3f4              ; Load destination start address to HL

    0250  7d         MOV A, L               ; Compare HL and BC
    0251  91         SUB C
    0252  7c         MOV A, H
    0253  98         SBB B

    0254  d8         RC                     ; If dest addr < source addr -> carry bit is on, HL=dest start addr

    0255  2a f6 c3   LHLD c3f6              ; Otherwise carry bit is off, HL=dest end addr
    0258  c9         RET






0250                             7c ba c0 7d bb c9 cd
0260  24 02 cd 66 02 c7 2a f4 c3 56 e5 cd b9 02 60 e3
0270  78 fe 03 c2 a5 02 23 4e 23 46 2b e5 2a f0 c3 79
0280  95 78 9c da a3 02 2a f2 c3 7d 91 7c 98 da a3 02
0290  2a f8 c3 7d 81 5f 7c 88 57 e1 73 23 72 23 33 33
02a0  c3 ab 02 e1 2b c1 23 05 c2 a6 02 5d 54 2a f6 c3
02b0  23 cd 59 02 eb c2 69 02 c9 01 06 03 21 d3 02 7a
02c0  a6 23 be c8 23 0d c2 bf 02 0e 03 05 78 fe 01 c2
02d0  bf 02 c9 ff cd c7 c4 ff c3 c7 c2 e7 22 cf 01 c7
02e0  06 c7 c6 f7 d3 f7 eb 22 f0 c3 22 f4 c3 e5 f7 eb
02f0  22 f2 c3 22 f6 c3 f7 eb 22 fa c3 d1 7d 93 6f 7c
0300  9a 67 22 f8 c3 cd 66 02 c7 f7 d5 f7 eb 22 f2 c3
0310  f7 eb 22 fa c3 f7 eb 22 ee c3 e1 22 f0 c3 56 e5
0320  cd b9 02 60 e3 78 fe 03 c2 4a 03 23 5e 23 56 2b
0330  e5 2a fa c3 cd 59 02 c2 48 03 2a ee c3 eb e1 73
0340  23 72 23 33 33 c3 50 03 e1 2b c1 23 05 c2 4b 03
0350  5d 54 2a f2 c3 23 cd 59 02 eb c2 1e 03 c7 f7 eb
0360  22 f0 c3 4d 44 f7 6b 62 22 f2 c3 23 22 f6 c3 cd
0370  0e 02 af 77 e5 23 22 f4 c3 21 01 00 22 f8 c3 cd
0380  66 02 e1 7e ef d7 77 c7 f7 eb 22 f0 c3 22 f4 c3
0390  4d 44 e5 f7 6b 62 22 f2 c3 e1 c5 03 cd 19 02 af
03a0  77 2b 22 f6 c3 21 ff ff 22 f8 c3 cd 66 02 e1 c3
03b0  7d 00 

;============================================================================
; Memory compare program
; Parameters:
; - Source start address
; - Source end address
; - Destination start address
;
; In case of success, the program displays 11 on all displays
;
; In case of a difference, the program displays the address of difference, and value
; on target memory cell. Then program accepts the new value for the cell, then returns
; to the memory compare process.
MEM_CMP:
    03b2  f7         RST 6                  ; Enter source start addr to BC
    03b3  4b         MOV C, E
    03b4  42         MOV B, D

    03b5  f7         RST 6                  ; Enter source end addr to DE
    03b6  d5         PUSH DE

    03b7  f7         RST 6                  ; Enter destination address to HL
    03b8  eb         XCHG
    03b9  d1         POP DE

MEM_CMP_LOOP:
    03ba  0a         LDAX BC                ; Compare bytes at [BC] and [HL]
    03bb  be         CMP M]
    03bc  c2 d4 03   JNZ MEM_CMP_ERR (03d4) ; Display the memory mismatch error

    03bf  79         MOV A, C               ; Check if end address (in DE) is reached
    03c0  bb         CMP E
    03c1  c2 cf 03   JNZ MEM_CMP_CONT (03cf)
    03c4  78         MOV A, B
    03c5  ba         CMP D
    03c6  c2 cf 03   JNZ MEM_CMP_CONT (03cf)

    03c9  3e 11      MVI A, 11              ; Display 11 on all displays, indicating success
    03cb  6f         MOV L, A
    03cc  67         MOV H, A
    03cd  ef         RST 5

    03ce  c7         RST 0                  ; The end (reset)

MEM_CMP_CONT:
    03cf  03         INX BC                 ; Increment pointers and repeat
    03d0  23         INX HL
    03d1  c3 ba 03   JMP MEM_CMP_LOOP (03ba)

MEM_CMP_ERR:
    03d4  f5         PUSH PSW               ; Display address of difference, and the value
    03d5  7e         MOV A, M
    03d6  ef         RST 5

    03d7  d7         RST 2                  ; Enter and store new value for the destination memory cell
    03d8  77         MOV M, A

    03d9  f1         POP PSW                ; Return to the memory compare program
    03da  c3 ba 03   JMP MEM_CMP_LOOP





03d0                                         c5 d5 e5
03e0  f5 7e ef e7 e3 3e af ef e7 e3 69 60 3e bc ef e7
03f0  eb 3e de ef e7 f1 e1 d1 c1 c9 ff ff ff ff ff ff

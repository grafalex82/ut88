; This part of the Monitor0 firmware contains a few handy programs:
; - 0x0200  - Memory copying program
; - 0x025f  - Address correction program (correct addresses after copying to other memory region)
; - 0x02e5  - "Super" Address correction program (correct addresses before copying to other memory region)
; - 0x0309  - Replace address (replace all occurrances of the address in the range with another address)
; - 0x035e  - Insert byte program (shifts the range 1 byte further)
; - 0x0388  - Delete byte program (shifts the range 1 byte backward, and correct addresses within the range)
; - 0x03b2  - Memory compare program
; - 0x03dd  - Display registers helper function


; Memory copying program
; 
; Program expects 3 parameters:
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

; Compare DE and HL register pairs, set Z if equeal
CMD_DE_HL:
    0259  7c         MOV A, H
    025a  ba         CMP D
    025b  c0         RNZ
    025c  7d         MOV A, L
    025d  bb         CMP E
    025e  c9         RET


; Memory address correction program. Used to correct addresses after copying a code to another
; memory region. The program detects 3-byte instructions, and corrects their arguments
; if they are in the source address region.
; 
; Program expects 3 parameters:
; - Source start address
; - Source end address
; - Destination start address
MEM_CORR:
    025f  cd 24 02   CALL ENTER_ADDR (0224) ; Enter addresses to work
    0262  cd 66 02   CALL DO_MEM_CORR (0266); Execute the actual program
    0265  c7         RST 0                  ; The end (reset)

DO_MEM_CORR:
    0266  2a f4 c3   LHLD c3f4              ; Load destination start address in HL

MEM_CORR_LOOP:
    0269  56         MOV D, M               ; Load next byte and match it with an opcode
    026a  e5         PUSH HL
    026b  cd b9 02   CALL MATCH_OPCODE (02b9)

    026e  60         MOV H, B               ; Restore current address in HL, but store B (instruction
    026f  e3         XTHL                   ; size) on the stack instead

    0270  78         MOV A, B               ; Check if 3-byte instruction was matched
    0271  fe 03      CPI 03
    0273  c2 a5 02   JNZ MEM_CORR_2 (02a5)

    0276  23         INX HL                 ; 3-byte instruction matched - patch the 2-byte argument
    0277  4e         MOV C, M               ; Load the argument to BC
    0278  23         INX HL
    0279  46         MOV B, M

    027a  2b         DCX HL
    027b  e5         PUSH HL

    027c  2a f0 c3   LHLD c3f0              ; Compare instruction argument with 
    027f  79         MOV A, C               ; the source start. Skip patching if
    0280  95         SUB L                  ; the argument is below source start address
    0281  78         MOV A, B
    0282  9c         SBB H
    0283  da a3 02   JC MEM_CORR_1 (02a3)

    0286  2a f2 c3   LHLD c3f2              ; Compare instruction argument with the
    0289  7d         MOV A, L               ; Source end address. Skip patching if the
    028a  91         SUB C                  ; argument is above source end address
    028b  7c         MOV A, H
    028c  98         SBB B
    028d  da a3 02   JC MEM_CORR_1 (02a3)

    0290  2a f8 c3   LHLD c3f8              ; Load the source-destination address difference to HL
    0293  7d         MOV A, L               ; Add the difference to instruction argument
    0294  81         ADD C
    0295  5f         MOV E, A               ; Store result to DE
    0296  7c         MOV A, H
    0297  88         ADC B
    0298  57         MOV D, A

    0299  e1         POP HL                 ; Patch the instruction argument
    029a  73         MOV M, E
    029b  23         INX H
    029c  72         MOV M, D
    029d  23         INX H
    02be  33         INX SP
    02bf  33         INX SP

    02a0  c3 ab 02   JMP MEM_CORR_NEXT (02ab)   ; Advance to the next instruction

MEM_CORR_1:
    02a3  e1         POP HL                 ; Just restore current instruction address (HL)
    02a4  2b         DCX HL

MEM_CORR_2:
    02a5  c1         POP BC                 ; And instruction size

MEM_CORR_L:
    02a6  23         INX HL                 ; Advance HL by instruction size
    02a7  05         DCR B
    02a8  c2 a6 02   JNZ MEM_CORR_L (02a6)

MEM_CORR_NEXT:
    02ab  5d         MOV E, L               ; Repeat until destination address is reached
    02ac  54         MOV D, H
    02ad  2a f6 c3   LHLD c3f6
    02b0  23         INX HL
    02b1  cd 59 02   CALL CMD_DE_HL (0259)
    02b4  eb         XCHG
    02b5  c2 69 02   JNZ MEM_CORR_LOOP (0269)
    02b8  c9         RET


; Match an opcode given in D with a instructions matching table
; Return Z=1 if instruction matches (B=instruction length)
; Z=0 if no match
MATCH_OPCODE:
    02b9  01 06 03   LXI BC, 0306           ; Start with 3-byte instructions, 6 types
    02bc  21 d3 02   LXI HL, 02d3           ; Load opcode mask table address

MATCH_LOOP:
    02bf  7a         MOV A, D               ; Check whether the given byte matches instruction
    02c0  a6         ANA M                  ; in the table
    02c1  23         INX HL5
    02c2  be         CMP M
    02c3  c8         RZ                     ; Return with Z flag in case of match, B - instruction length

    02c4  23         INX HL                 ; Repeat C times (6 for 3-byte instructions, 3 for 2-byte)
    02c5  0d         DCR C
    02c6  c2 bf 02   JNZ MATCH_LOOP (02bf)

    02c9  0e 03      MVI C, 03
    02cb  05         DCR B
    02cc  78         MOV A, B
    02cd  fe 01      CPI 01
    02cf  c2 bf 02   JNZ 02bf    
    02d2  c9         RET                    ; Zero Z flag means no match

    ; 3-byte instructions masks
    02d3 ff cd                              ; Match for CALL opcode
    02d5 c7 c4                              ; Match for conditional CALL opcodes
    02d7 ff c3                              ; Match for JMP opcode
    02d9 c7 c2                              ; Match for conditional JMP opcodes
    02db e7 22                              ; Match for SHLD, LHLD, STA, LDA opcodes
    02dd cf 01                              ; Match for LXI opcodes
    
    ; 2-byte instructions masks
    02df c7 06                              ; Match for MVI opcodes
    02e1 c7 c6                              ; Match for ADI, ACI, SUI, SBI, ANI, XRI, ORI and CPI instructions
    02e3 f7 d3                              ; Match for IN and OUT instructions


; Super address corrector
;
; This program is intended for correcting addresses before copying the program elsewhere.
; The difference with the previous program in the use case
; - Previous program is supposed to be run after the memory copying program, to correct addresses
;   in the memory copy
; - This program is supposed to be run before memory copying (or moving code in other way, e.g. tape)
;   So this program is preparing addresses to be executed at other memory region later.
;
; Technically this is the same algorithm, just different addresses passed as a parameter for the
; address correction routine.
; 
; Program expects 3 parameters:
; - Start address of the corrected code
; - End address of the corrected code
; - Destination start address, where the code is supposed to run
SUPER_CORR:
    02e5  f7         RST 6                  ; Enter start addr, and store it to 0xc3f0 and 0xc3f4
    02e6  eb         XCHG
    02e7  22 f0 c3   SHLD c3f0
    02ea  22 f4 c3   SHLD c3f4
    02ed  e5         PUSH HL

    02ee  f7         RST 6                  ; Enter end addr, and store it to 0xc3f2 and 0xc3f6
    02ef  eb         XCHG
    02f0  22 f2 c3   SHLD c3f2
    02f3  22 f6 c3   SHLD c3f6

    02f6  f7         RST 6                  ; Enter target address, and store it to 0xc3fa
    02f7  eb         XCHG
    02f8  22 fa c3   SHLD c3fa

    02fb  d1         POP DE                 ; Restore start address
    02fc  7d         MOV A, L               ; Calculate difference between original address
    02fd  93         SUB E                  ; and target address
    02fe  6f         MOV L, A
    02ff  7c         MOV A, H
    0300  9a         SBB D
    0301  67         MOV H, A               ; Store the difference to 0xc3f8
    0302  22 f8 c3   SHLD c3f8

    0305  cd 66 02   CALL DO_MEM_CORR (0266); Perform the actual correction
    0308  c7         RST 0                  ; The end (Reset)

; Program to correct specific address in the specified memory range
; The program searches for 3-byte instruction, and if the argument matches
; the certain address, it changes it to another 
; 
; Program expects 4 parameters:
; - Start address of the memory range
; - End address of the memory range
; - Address to search
; - Address to replace with
REPLACE_ADDR:
    0309  f7         RST 6                  ; Enter start address
    030a  d5         PUSH DE
    030b  f7         RST 6                  ; Enter end address and store to 0xc3f2      
    030c  eb         XCHG
    030d  22 f2 c3   SHLD c3f2

    0310  f7         RST 6                  ; Enter address to match and store to 0xc3fa
    0311  eb         XCHG
    0312  22 fa c3   SHLD c3fa             
    0315  f7         RST 6                  ; Enter replacement address and store to 0xc3ee
    0316  eb         XCHG
    0317  22 ee c3   SHLD c3ee

    031a  e1         POP HL                 ; Start address in HL (store it to 0xc3f0)
    031b  22 f0 c3   SHLD c3f0

REPLACE_LOOP:
    031e  56         MOV D, M               ; Load the next byte
    031f  e5         PUSH HL
    0320  cd b9 02   CALL MATCH_OPCODE (02b9)   ; Match the instruction code

    0323  60         MOV H, B               ; Restore current address in HL, but store B (instruction
    0324  e3         XTHL                   ; size) on the stack instead

    0325  78         MOV A, B               ; Check if 3-byte instruction was matched
    0326  fe 03      CPI 03
    0328  c2 4a 03   JNZ REPLACE_2 (034a)

    032b  23         INX HL                 ; Load the instruction argument to DE
    032c  5e         MOV E, M
    032d  23         INX HL
    032e  56         MOV D, M

    032f  2b         DCX HL
    0330  e5         PUSH HL
    0331  2a fa c3   LHLD c3fa              ; Check the argument equals to the address to replace
    0334  cd 59 02   CALL CMD_DE_HL (0259)
    0337  c2 48 03   JNZ REPLACE_1 (0348)

    033a  2a ee c3   LHLD c3ee              ; Replace argument with the replacement address
    033d  eb         XCHG
    033e  e1         POP HL
    033f  73         MOV M, E
    0340  23         INX HL
    0341  72         MOV M, D
    0342  23         INX HL

    0343  33         INX SP                 ; Prepare for the next instruction
    0344  33         INX SP
    0345  c3 50 03   JMP REPLACE_NEXT (0350)

REPLACE_1:
    0348  e1         POP HL
    0349  2b         DCX HL

REPLACE_2:
    034a  c1         POP BC                 ; Restore instruction size

REPLACE_L:
    034b  23         INX HL                 ; Advance address by the instruction size
    034c  05         DCR B
    034d  c2 4b 03   JNZ REPLACE_L (034b)

REPLACE_NEXT:
    0350  5d         MOV E, L               ; Repeat until end address reached
    0351  54         MOV D, H
    0352  2a f2 c3   LHLD c3f2
    0355  23         INX HL                 ; Advance to the next instruction
    0356  cd 59 02   CALL CMD_DE_HL (0259)
    0359  eb         XCHG
    035a  c2 1e 03   JNZ REPLACE_LOOP (031e)

    035d  c7         RST 0                  ; The end (reset)


; Insert byte program
;
; The program moves the memory block at the specified address range 1 byte further
; and enters a new byte at the insert location
;
; Parameters:
; - Insert location
; - End of program
INSERT_BYTE:
    035e  f7         RST 6                  ; Enter insert location and store in 0xc3f0
    035f  eb         XCHG
    0360  22 f0 c3   SHLD c3f0
    0363  4d         MOV C, L               ; And BC
    0364  44         MOV B, H

    0365  f7         RST 6                  ; Enter end address and store it to 0xc3f2
    0366  6b         MOV L, E
    0367  62         MOV H, D
    0368  22 f2 c3   SHLD c3f2

    036b  23         INX HL                 ; Prepare destination end address in 0xc3f6
    036c  22 f6 c3   SHLD c3f6              ; (1 byte higher than source start address)

    036f  cd 0e 02   CALL MEM_COPY_DOWN (020e)  ; Execute the memory copying

    0382  e1         POP HL                 ; Display the insert address
    0383  7e         MOV A, M
    0384  ef         RST 5

    0385  d7         RST 2                  ; Wait for a new byte at inserted location
    0386  77         MOV M, A               ; Store the entered byte
    0387  c7         RST 0                  ; The end (reset)
    

; Byte deletion program
;
; The program does selected memory range shift (memcopy) 1 byte down, and then calls
; address correction routine to correct 3-byte instructions arguments
;
; Parameters:
; - Address to delete byte at
; - End of program address
DELETE_BYTE:
    0388  f7         RST 6                  ; Enter start address, and store it to 0xc3f0 and 0xc3f4
    0389  eb         XCHG
    038a  22 f0 c3   SHLD c3f0
    038d  22 f4 c3   SHLD c3f4
    0390  4d         MOV C, L               ; ... And BC
    0391  44         MOV B, H
    0392  e5         PUSH HL

    0393  f7         RST 6                  ; Enter end address, and store it to 0xc3f2
    0394  6b         MOV L, E
    0395  62         MOV H, D
    0396  22 f2 c3   SHLD c3f2
    0399  e1         POP HL

    039a  c5         PUSH BC
    039b  03         INX BC                 ; Start address will be 1 byte higher than entered address
    039c  cd 19 02   CALL MEM_COPY_UP (0219)    ; Do the mem copy

    039f  af         XRA A                  ; Clear the byte after the mem range end
    03a0  77         MOV M, A

    03a1  2b         DCX HL                 ; Store the target mem end address at 0xc3f6
    03a2  22 f6 c3   SHLD c3f6

    03a5  21 ff ff   LXI HL, ffff           ; Set the difference as -1 byte and store it to 0xc3f8
    03a8  22 f8 c3   SHLD c3f8
    03ab  cd 66 02   CALL DO_MEM_CORR (0266); Do the address corrections within the moved range

    03ae  e1         POP HL                 ; Go to RAM read routine
    03af  c3 7d 00   JMP RAM_READ (007d)


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
    03bb  be         CMP M
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


; Display registers
;
; A debugging helper function to display registers and memory at HL
SHOW_REGISTERS:
    03dd  c5         PUSH BC
    03de  d5         PUSH DE
    03df  e5         PUSH HL
    03e0  f5         PUSH PSW

    03e1  7e         MOV A, M               ; Display HL and value at [HL]
    03e2  ef         RST 5
    03e3  e7         RST 4

    03e4  e3         XTHL                   ; Display PSW and 'AF' mark
    03e5  3e af      MVI A, af
    03e7  ef         RST 5
    03e8  e7         RST 4

    03e9  e3         XTHL                   ; Display BC and 'BC' mark
    03ea  69         MOV L, C
    03eb  60         MOV H, B
    03ec  3e bc      MVI A, bc
    03ee  ef         RST 5
    03ef  e7         RST 4

    03f0  eb         XCHG                   ; Display DE and 'DE' mark
    03f1  3e de      MVI A, de
    03f3  ef         RST 5
    03f4  e7         RST 4
    
    03f5  f1         POP PSW
    03f6  e1         POP HL
    03f7  d1         POP DE
    03f8  c1         POP BC
    03f9  c9         RET

; Monitor F console output patch
;
; This file contains a small addition to the Monitor'S F put character functions. The goal of the
; addition is ??????
;
; 
; This file is loaded to the memory by CP/M initial bootloader, and initially is located at
; 0x31e0-0x32ff address range of the CP/M binary
    
PUT_CHAR_CPM:
    f500  e5         PUSH HL
    f501  c5         PUSH BC
    f502  d5         PUSH DE
    f503  f5         PUSH PSW

    f504  3a 15 f6   LDA f615                   ; ????
    f507  fe 00      CPI A, 00
    f509  c2 30 f5   JNZ f530

    f50c  79         MOV A, C
    f50d  fe 20      CPI A, 20
    f50f  d2 12 f6   JNC DO_MONITOR_PUT_CHAR (f612)

    f512  fe 08      CPI A, 08
    f514  ca 12 f6   JZ DO_MONITOR_PUT_CHAR (f612)

    f517  fe 0a      CPI A, 0a
    f519  ca 12 f6   JZ DO_MONITOR_PUT_CHAR (f612)

    f51c  fe 0d      CPI A, 0d
    f51e  ca 12 f6   JZ DO_MONITOR_PUT_CHAR (f612)

    f521  fe 1b      CPI A, 1b
    f523  c2 2b f5   JNZ PUT_CHAR_CPM_EXIT (f52b)

    f526  3e 01      MVI A, 01
    f528  32 15 f6   STA f615

PUT_CHAR_CPM_EXIT:
    f52b  f1         POP PSW
    f52c  d1         POP DE
    f52d  c1         POP BC
    f52e  e1         POP HL
    f52f  c9         RET

????:
    f530  3a 15 f6   LDA f615
    f533  fe 01      CPI A, 01
    f535  c2 b9 f5   JNZ f5b9

    f538  79         MOV A, C
    f539  fe 41      CPI A, 41
    f53b  c2 43 f5   JNZ f543

    f53e  0e 19      MVI C, 19
    f540  c3 0d f6   JMP f60d

????:
    f543  fe 42      CPI A, 42
    f545  c2 4d f5   JNZ f54d

    f548  0e 1a      MVI C, 1a
    f54a  c3 0d f6   JMP f60d

????:
    f54d  fe 43      CPI A, 43
    f54f  c2 57 f5   JNZ f557

    f552  0e 18      MVI C, 18
    f554  c3 0d f6   JMP f60d

????:
    f557  fe 44      CPI A, 44
    f559  c2 61 f5   JNZ f561

    f55c  0e 08      MVI C, 08
    f55e  c3 0d f6   JMP f60d
????:
    f561  fe 45      CPI A, 45
    f563  c2 6b f5   JNZ f56b

    f566  0e 1f      MVI C, 1f
    f568  c3 0d f6   JMP f60d

????:
    f56b  fe 48      CPI A, 48
    f56d  c2 75 f5   JNZ f575

    f570  0e 0c      MVI C, 0c
    f572  c3 0d f6   JMP f60d
????:
    f575  fe 4a      CPI A, 4a
    f577  c2 8a f5   JNZ f58a

    f57a  2a 5a f7   LHLD f75a
    f57d  3e f0      MVI A, f0
    f57f  06 20      MVI B, 20

????:
    f581  70         MOV M, B
    f582  23         INX HL
    f583  bc         CMP H
    f584  c2 81 f5   JNZ f581
    f587  c3 05 f6   JMP f605

????:
    f58a  fe 4b      CPI A, 4b
    f58c  c2 a3 f5   JNZ f5a3
    f58f  2a 5a f7   LHLD f75a
    f592  af         XRA A
    f593  7d         MOV A, L
    f594  e6 c0      ANI A, c0
    f596  c6 40      ADI A, 40
    f598  06 20      MVI B, 20
????:
    f59a  70         MOV M, B
    f59b  23         INX HL
    f59c  bd         CMP L
    f59d  c2 9a f5   JNZ f59a
    f5a0  c3 05 f6   JMP f605
????:
    f5a3  fe 59      CPI A, 59
    f5a5  c2 17 f6   JNZ f617
    f5a8  2a 5a f7   LHLD f75a
    f5ab  11 01 f8   LXI DE, f801
    f5ae  19         DAD DE
    f5af  36 00      MVI M, 00
    f5b1  3e 02      MVI A, 02
    f5b3  32 15 f6   STA f615
    f5b6  c3 2b f5   JMP PUT_CHAR_CPM_EXIT (f52b)

????:
    f5b9  79         MOV A, C
    f5ba  fe 1b      CPI A, 1b
    f5bc  c2 c9 f5   JNZ f5c9
    f5bf  3e 01      MVI A, 01
    f5c1  32 15 f6   STA f615
    f5c4  0e 1f      MVI C, 1f
    f5c6  c3 12 f6   JMP DO_MONITOR_PUT_CHAR (f612)
????:
    f5c9  3a 15 f6   LDA f615
    f5cc  fe 02      CPI A, 02
    f5ce  c2 e0 f5   JNZ f5e0
    f5d1  af         XRA A
    f5d2  79         MOV A, C
    f5d3  de 20      SBI A, 20
    f5d5  32 16 f6   STA f616
    f5d8  3e 03      MVI A, 03
    f5da  32 15 f6   STA f615
    f5dd  c3 2b f5   JMP PUT_CHAR_CPM_EXIT (f52b)
????:
    f5e0  af         XRA A
    f5e1  79         MOV A, C
    f5e2  de 20      SBI A, 20
    f5e4  fe 3f      CPI A, 3f
    f5e6  da eb f5   JC f5eb
    f5e9  3e 3f      MVI A, 3f
????:
    f5eb  6f         MOV L, A
    f5ec  3a 16 f6   LDA f616
    f5ef  0f         RRC
    f5f0  0f         RRC
    f5f1  4f         MOV C, A
    f5f2  e6 c0      ANI A, c0
    f5f4  b5         ORA L
    f5f5  6f         MOV L, A
    f5f6  79         MOV A, C
    f5f7  e6 07      ANI A, 07
    f5f9  f6 e8      ORI A, e8
    f5fb  67         MOV H, A
    f5fc  22 5a f7   SHLD f75a
    f5ff  11 01 f8   LXI DE, f801
    f602  19         DAD DE
    f603  36 80      MVI M, 80

????:
    f605  3e 00      MVI A, 00
    f607  32 15 f6   STA f615
    f60a  c3 2b f5   JMP PUT_CHAR_CPM_EXIT (f52b)
????:
    f60d  3e 00      MVI A, 00
    f60f  32 15 f6   STA f615

DO_MONITOR_PUT_CHAR:
    f612  c3 47 fc   JMP fc47


????:
    f615  00         NOP

????:
    f616  00         NOP

????:
    f617  c3 05 f6   JMP f605
    f61a  00         NOP
    f61b  00         NOP
    f61c  00         NOP
    f61d  00         NOP
    f61e  00         NOP
    f61f  00         NOP

f800  c3 36 f8   JMP f836
f803  c3 63 fe   JMP fe63
f806  c3 98 fb   JMP fb98
f809  c3 ba fc   JMP fcba
f80c  c3 46 fc   JMP fc46
f80f  c3 ba fc   JMP fcba
f812  c3 01 fe   JMP fe01
f815  c3 a5 fc   JMP fca5
f818  c3 22 f9   JMP f922
f81b  c3 72 fe   JMP fe72
f81e  c3 7b fa   JMP fa7b
f821  c3 7f fa   JMP fa7f
f824  c3 b6 fa   JMP fab6
f827  c3 49 fb   JMP fb49
f82a  c3 16 fb   JMP fb16
f82d  c3 ce fa   JMP face
f830  c3 52 ff   JMP ff52
f833  c3 56 ff   JMP ff56
????:
f836  3e 8a      MVI A, 8a
f838  32 03 80   STA 8003

f83b  31 cf 76   LXI SP, 76cf
f83e  cd ce fa   CALL face
f841  21 00 76   LXI HL, 7600
f844  11 5f 76   LXI DE, 765f
f847  0e 00      MVI C, 00
f849  cd ed f9   CALL f9ed
f84c  21 cf 76   LXI HL, 76cf
f84f  22 1c 76   SHLD 761c
f852  21 5a ff   LXI HL, ff5a
f855  cd 22 f9   CALL f922
f858  cd ce fa   CALL face
f85b  21 ff 75   LXI HL, 75ff
f85e  22 31 76   SHLD 7631
f861  21 2a 1d   LXI HL, 1d2a
f864  22 2f 76   SHLD 762f
f867  3e c3      MVI A, c3
f869  32 26 76   STA 7626
????:
f86c  31 cf 76   LXI SP, 76cf
f86f  21 66 ff   LXI HL, ff66
f872  cd 22 f9   CALL f922
f875  32 02 80   STA 8002
f878  3d         DCR A
f879  32 02 a0   STA a002
f87c  cd ee f8   CALL f8ee
f87f  21 6c f8   LXI HL, f86c
f882  e5         PUSH HL
f883  21 33 76   LXI HL, 7633
f886  7e         MOV A, M
f887  fe 58      CPI A, 58
f889  ca d3 ff   JZ ffd3
f88c  fe 55      CPI A, 55
f88e  ca 00 f0   JZ f000
f891  f5         PUSH PSW
f892  cd 2c f9   CALL f92c
f895  2a 2b 76   LHLD 762b
f898  4d         MOV C, L
f899  44         MOV B, H
f89a  2a 29 76   LHLD 7629
f89d  eb         XCHG
f89e  2a 27 76   LHLD 7627
f8a1  f1         POP PSW
f8a2  fe 44      CPI A, 44
f8a4  ca c5 f9   JZ f9c5
f8a7  fe 43      CPI A, 43
f8a9  ca d7 f9   JZ f9d7
f8ac  fe 46      CPI A, 46
f8ae  ca ed f9   JZ f9ed
f8b1  fe 53      CPI A, 53
f8b3  ca f4 f9   JZ f9f4
f8b6  fe 54      CPI A, 54
f8b8  ca ff f9   JZ f9ff
f8bb  fe 4d      CPI A, 4d
f8bd  ca 26 fa   JZ fa26
f8c0  fe 47      CPI A, 47
f8c2  ca 3f fa   JZ fa3f
f8c5  fe 49      CPI A, 49
f8c7  ca 86 fa   JZ fa86
f8ca  fe 4f      CPI A, 4f
f8cc  ca 2d fb   JZ fb2d
f8cf  fe 4c      CPI A, 4c
f8d1  ca 08 fa   JZ fa08
f8d4  fe 52      CPI A, 52
f8d6  ca 68 fa   JZ fa68
f8d9  c3 00 f0   JMP f000
????:
f8dc  3e 33      MVI A, 33
f8de  bd         CMP L
f8df  ca f1 f8   JZ f8f1
f8e2  e5         PUSH HL
f8e3  21 9e ff   LXI HL, ff9e
f8e6  cd 22 f9   CALL f922
f8e9  e1         POP HL
f8ea  2b         DCX HL
f8eb  c3 f3 f8   JMP f8f3
????:
f8ee  21 33 76   LXI HL, 7633
????:
f8f1  06 00      MVI B, 00
????:
f8f3  cd 63 fe   CALL fe63
f8f6  fe 08      CPI A, 08
f8f8  ca dc f8   JZ f8dc
f8fb  fe 7f      CPI A, 7f
f8fd  ca dc f8   JZ f8dc
f900  c4 b9 fc   CNZ fcb9
f903  77         MOV M, A
f904  fe 0d      CPI A, 0d
f906  ca 1a f9   JZ f91a
f909  fe 2e      CPI A, 2e
f90b  ca 6c f8   JZ f86c
f90e  06 ff      MVI B, ff
f910  3e 52      MVI A, 52
f912  bd         CMP L
f913  ca ae fa   JZ faae
f916  23         INX HL
f917  c3 f3 f8   JMP f8f3
????:
f91a  78         MOV A, B
f91b  17         RAL
f91c  11 33 76   LXI DE, 7633
f91f  06 00      MVI B, 00
f921  c9         RET
????:
f922  7e         MOV A, M
f923  a7         ANA A
f924  c8         RZ
f925  cd b9 fc   CALL fcb9
f928  23         INX HL
f929  c3 22 f9   JMP f922
????:
f92c  21 27 76   LXI HL, 7627
f92f  11 2d 76   LXI DE, 762d
f932  0e 00      MVI C, 00
f934  cd ed f9   CALL f9ed
f937  11 34 76   LXI DE, 7634
f93a  cd 5a f9   CALL f95a
f93d  22 27 76   SHLD 7627
f940  22 29 76   SHLD 7629
f943  d8         RC
f944  3e ff      MVI A, ff
f946  32 2d 76   STA 762d
f949  cd 5a f9   CALL f95a
f94c  22 29 76   SHLD 7629
f94f  d8         RC
f950  cd 5a f9   CALL f95a
f953  22 2b 76   SHLD 762b
f956  d8         RC
f957  c3 ae fa   JMP faae
????:
f95a  21 00 00   LXI HL, 0000
????:
f95d  1a         LDAX DE
f95e  13         INX DE
f95f  fe 0d      CPI A, 0d
f961  ca 8e f9   JZ f98e
f964  fe 2c      CPI A, 2c
f966  c8         RZ
f967  fe 20      CPI A, 20
f969  ca 5d f9   JZ f95d
f96c  d6 30      SUI A, 30
f96e  fa ae fa   JM faae
f971  fe 0a      CPI A, 0a
f973  fa 82 f9   JM f982
f976  fe 11      CPI A, 11
f978  fa ae fa   JM faae
f97b  fe 17      CPI A, 17
f97d  f2 ae fa   JP faae
f980  d6 07      SUI A, 07
????:
f982  4f         MOV C, A
f983  29         DAD HL
f984  29         DAD HL
f985  29         DAD HL
f986  29         DAD HL
f987  da ae fa   JC faae
f98a  09         DAD BC
f98b  c3 5d f9   JMP f95d
????:
f98e  37         STC
f98f  c9         RET

COMPARE_DE_HL:
f990  7c         MOV A, H
f991  ba         CMP D
f992  c0         RNZ
f993  7d         MOV A, L
f994  bb         CMP E
f995  c9         RET

????:
f996  cd a4 f9   CALL f9a4

ADVANCE_HL:
f999  cd 90 f9   CALL COMPARE_DE_HL (f990)
f99c  c2 a2 f9   JNZ f9a2

????:
f99f  33         INX SP
f9a0  33         INX SP
f9a1  c9         RET

????:
f9a2  23         INX HL
f9a3  c9         RET

????:
f9a4  cd 72 fe   CALL fe72
f9a7  fe 03      CPI A, 03
f9a9  c0         RNZ
f9aa  cd ce fa   CALL face
f9ad  c3 ae fa   JMP faae

????:
f9b0  e5         PUSH HL
f9b1  21 6c ff   LXI HL, ff6c
f9b4  cd 22 f9   CALL f922
f9b7  e1         POP HL
f9b8  c9         RET
????:
f9b9  7e         MOV A, M
????:
f9ba  c5         PUSH BC
f9bb  cd a5 fc   CALL fca5
f9be  3e 20      MVI A, 20
f9c0  cd b9 fc   CALL fcb9
f9c3  c1         POP BC
f9c4  c9         RET
????:
f9c5  cd 78 fb   CALL fb78
????:
f9c8  cd b9 f9   CALL f9b9
f9cb  cd 96 f9   CALL f996
f9ce  7d         MOV A, L
f9cf  e6 0f      ANI A, 0f
f9d1  ca c5 f9   JZ f9c5
f9d4  c3 c8 f9   JMP f9c8
????:
f9d7  0a         LDAX BC
f9d8  be         CMP M
f9d9  ca e6 f9   JZ f9e6
f9dc  cd 78 fb   CALL fb78
f9df  cd b9 f9   CALL f9b9
f9e2  0a         LDAX BC
f9e3  cd ba f9   CALL f9ba
????:
f9e6  03         INX BC
f9e7  cd 96 f9   CALL f996
f9ea  c3 d7 f9   JMP f9d7
????:
f9ed  71         MOV M, C
f9ee  cd 99 f9   CALL ADVANCE_HL (f999)
f9f1  c3 ed f9   JMP f9ed
????:
f9f4  79         MOV A, C
f9f5  be         CMP M
f9f6  cc 78 fb   CZ fb78
f9f9  cd 96 f9   CALL f996
f9fc  c3 f4 f9   JMP f9f4
????:
f9ff  7e         MOV A, M
fa00  02         STAX BC
fa01  03         INX BC
fa02  cd 99 f9   CALL ADVANCE_HL (f999)
fa05  c3 ff f9   JMP f9ff
????:
fa08  cd 78 fb   CALL fb78
????:
fa0b  7e         MOV A, M
fa0c  b7         ORA A
fa0d  fa 15 fa   JM fa15
fa10  fe 20      CPI A, 20
fa12  d2 17 fa   JNC fa17
????:
fa15  3e 2e      MVI A, 2e
????:
fa17  cd b9 fc   CALL fcb9
fa1a  cd 96 f9   CALL f996
fa1d  7d         MOV A, L
fa1e  e6 0f      ANI A, 0f
fa20  ca 08 fa   JZ fa08
fa23  c3 0b fa   JMP fa0b
????:
fa26  cd 78 fb   CALL fb78
fa29  cd b9 f9   CALL f9b9
fa2c  e5         PUSH HL
fa2d  cd ee f8   CALL f8ee
fa30  e1         POP HL
fa31  d2 3b fa   JNC fa3b
fa34  e5         PUSH HL
fa35  cd 5a f9   CALL f95a
fa38  7d         MOV A, L
fa39  e1         POP HL
fa3a  77         MOV M, A
????:
fa3b  23         INX HL
fa3c  c3 26 fa   JMP fa26
????:
fa3f  cd 90 f9   CALL COMPARE_DE_HL (f990)
fa42  ca 5a fa   JZ fa5a
fa45  eb         XCHG
fa46  22 23 76   SHLD 7623
fa49  7e         MOV A, M
fa4a  32 25 76   STA 7625
fa4d  36 f7      MVI M, f7
fa4f  3e c3      MVI A, c3
fa51  32 30 00   STA 0030
fa54  21 a2 ff   LXI HL, ffa2
fa57  22 31 00   SHLD 0031
????:
fa5a  31 18 76   LXI SP, 7618
fa5d  c1         POP BC
fa5e  d1         POP DE
fa5f  e1         POP HL
fa60  f1         POP PSW
fa61  f9         SPHL
fa62  2a 16 76   LHLD 7616
fa65  c3 26 76   JMP 7626
????:
fa68  3e 90      MVI A, 90
fa6a  32 03 a0   STA a003
????:
fa6d  22 01 a0   SHLD a001
fa70  3a 00 a0   LDA a000
fa73  02         STAX BC
fa74  03         INX BC
fa75  cd 99 f9   CALL ADVANCE_HL (f999)
fa78  c3 6d fa   JMP fa6d
????:
fa7b  2a 02 76   LHLD 7602
fa7e  c9         RET
????:
fa7f  e5         PUSH HL
fa80  2a 00 76   LHLD 7600
fa83  7e         MOV A, M
fa84  e1         POP HL
fa85  c9         RET
????:
fa86  3a 2d 76   LDA 762d
fa89  b7         ORA A
fa8a  ca 91 fa   JZ fa91
fa8d  7b         MOV A, E
fa8e  32 2f 76   STA 762f
????:
fa91  cd b6 fa   CALL fab6
fa94  cd 78 fb   CALL fb78
fa97  eb         XCHG
fa98  cd 78 fb   CALL fb78
fa9b  eb         XCHG
fa9c  c5         PUSH BC
fa9d  cd 16 fb   CALL fb16
faa0  60         MOV H, B
faa1  69         MOV L, C
faa2  cd 78 fb   CALL fb78
faa5  d1         POP DE
faa6  cd 90 f9   CALL COMPARE_DE_HL (f990)
faa9  c8         RZ
faaa  eb         XCHG
faab  cd 78 fb   CALL fb78
????:
faae  3e 3f      MVI A, 3f
fab0  cd b9 fc   CALL fcb9
fab3  c3 6c f8   JMP f86c
????:
fab6  3e ff      MVI A, ff
fab8  cd ff fa   CALL faff
fabb  e5         PUSH HL
fabc  09         DAD BC
fabd  eb         XCHG
fabe  cd fd fa   CALL fafd
fac1  e1         POP HL
fac2  09         DAD BC
fac3  eb         XCHG
fac4  e5         PUSH HL
fac5  cd 0a fb   CALL fb0a
fac8  3e ff      MVI A, ff
faca  cd ff fa   CALL faff
facd  e1         POP HL
????:
face  e5         PUSH HL
facf  21 01 c0   LXI HL, c001
fad2  36 00      MVI M, 00
fad4  2b         DCX HL
fad5  36 4d      MVI M, 4d
fad7  36 1d      MVI M, 1d
fad9  36 99      MVI M, 99
fadb  36 d3      MVI M, d3			# 93???
fadd  23         INX HL
fade  36 27      MVI M, 27
fae0  7e         MOV A, M
????:
fae1  7e         MOV A, M
fae2  e6 20      ANI A, 20
fae4  ca e1 fa   JZ fae1
fae7  21 08 e0   LXI HL, e008
faea  36 80      MVI M, 80
faec  2e 04      MVI L, 04
faee  36 d0      MVI M, d0
faf0  36 76      MVI M, 76
faf2  2c         INR L
faf3  36 23      MVI M, 23
faf5  36 49      MVI M, 49
faf7  2e 08      MVI L, 08
faf9  36 a4      MVI M, a4
fafb  e1         POP HL
fafc  c9         RET
????:
fafd  3e 08      MVI A, 08
????:
faff  cd 98 fb   CALL fb98
fb02  47         MOV B, A
fb03  3e 08      MVI A, 08
fb05  cd 98 fb   CALL fb98
fb08  4f         MOV C, A
fb09  c9         RET
????:
fb0a  3e 08      MVI A, 08
fb0c  cd 98 fb   CALL fb98
fb0f  77         MOV M, A
fb10  cd 99 f9   CALL ADVANCE_HL (f999)
fb13  c3 0a fb   JMP fb0a
????:
fb16  01 00 00   LXI BC, 0000
????:
fb19  7e         MOV A, M
fb1a  81         ADD C
fb1b  4f         MOV C, A
fb1c  f5         PUSH PSW
fb1d  cd 90 f9   CALL COMPARE_DE_HL (f990)
fb20  ca 9f f9   JZ f99f
fb23  f1         POP PSW
fb24  78         MOV A, B
fb25  8e         ADC M
fb26  47         MOV B, A
fb27  cd 99 f9   CALL ADVANCE_HL (f999)
fb2a  c3 19 fb   JMP fb19
????:
fb2d  79         MOV A, C
fb2e  b7         ORA A
fb2f  ca 35 fb   JZ fb35
fb32  32 30 76   STA 7630
????:
fb35  e5         PUSH HL
fb36  cd 16 fb   CALL fb16
fb39  e1         POP HL
fb3a  cd 78 fb   CALL fb78
fb3d  eb         XCHG
fb3e  cd 78 fb   CALL fb78
fb41  eb         XCHG
fb42  e5         PUSH HL
fb43  60         MOV H, B
fb44  69         MOV L, C
fb45  cd 78 fb   CALL fb78
fb48  e1         POP HL
????:
fb49  c5         PUSH BC
fb4a  01 00 00   LXI BC, 0000
????:
fb4d  cd 46 fc   CALL fc46
fb50  05         DCR B
fb51  e3         XTHL
fb52  e3         XTHL
fb53  c2 4d fb   JNZ fb4d
fb56  0e e6      MVI C, e6
fb58  cd 46 fc   CALL fc46
fb5b  cd 90 fb   CALL fb90
fb5e  eb         XCHG
fb5f  cd 90 fb   CALL fb90
fb62  eb         XCHG
fb63  cd 86 fb   CALL fb86
fb66  21 00 00   LXI HL, 0000
fb69  cd 90 fb   CALL fb90
fb6c  0e e6      MVI C, e6
fb6e  cd 46 fc   CALL fc46
fb71  e1         POP HL
fb72  cd 90 fb   CALL fb90
fb75  c3 ce fa   JMP face
????:
fb78  c5         PUSH BC
fb79  cd b0 f9   CALL f9b0
fb7c  7c         MOV A, H
fb7d  cd a5 fc   CALL fca5
fb80  7d         MOV A, L
fb81  cd ba f9   CALL f9ba
fb84  c1         POP BC
fb85  c9         RET
????:
fb86  4e         MOV C, M
fb87  cd 46 fc   CALL fc46
fb8a  cd 99 f9   CALL ADVANCE_HL (f999)
fb8d  c3 86 fb   JMP fb86
????:
fb90  4c         MOV C, H
fb91  cd 46 fc   CALL fc46
fb94  4d         MOV C, L
fb95  c3 46 fc   JMP fc46
????:
fb98  e5         PUSH HL
fb99  c5         PUSH BC
fb9a  d5         PUSH DE
fb9b  57         MOV D, A
????:
fb9c  3e 80      MVI A, 80
fb9e  32 08 e0   STA e008
fba1  21 00 00   LXI HL, 0000
fba4  39         DAD SP
fba5  31 00 00   LXI SP, 0000
fba8  22 0d 76   SHLD 760d
fbab  0e 00      MVI C, 00
fbad  3a 02 80   LDA 8002
fbb0  0f         RRC
fbb1  0f         RRC
fbb2  0f         RRC
fbb3  0f         RRC
fbb4  e6 01      ANI A, 01
fbb6  5f         MOV E, A
????:
fbb7  f1         POP PSW
fbb8  79         MOV A, C
fbb9  e6 7f      ANI A, 7f
fbbb  07         RLC
fbbc  4f         MOV C, A
fbbd  26 00      MVI H, 00
????:
fbbf  25         DCR H
fbc0  ca 34 fc   JZ fc34
fbc3  f1         POP PSW
fbc4  3a 02 80   LDA 8002
fbc7  0f         RRC
fbc8  0f         RRC
fbc9  0f         RRC
fbca  0f         RRC
fbcb  e6 01      ANI A, 01
fbcd  bb         CMP E
fbce  ca bf fb   JZ fbbf
fbd1  b1         ORA C
fbd2  4f         MOV C, A
fbd3  15         DCR D
fbd4  3a 2f 76   LDA 762f
fbd7  c2 dc fb   JNZ fbdc
fbda  d6 12      SUI A, 12
????:
fbdc  47         MOV B, A
????:
fbdd  f1         POP PSW
fbde  05         DCR B
fbdf  c2 dd fb   JNZ fbdd
fbe2  14         INR D
fbe3  3a 02 80   LDA 8002
fbe6  0f         RRC
fbe7  0f         RRC
fbe8  0f         RRC
fbe9  0f         RRC
fbea  e6 01      ANI A, 01
fbec  5f         MOV E, A
fbed  7a         MOV A, D
fbee  b7         ORA A
fbef  f2 0b fc   JP fc0b
fbf2  79         MOV A, C
fbf3  fe e6      CPI A, e6
fbf5  c2 ff fb   JNZ fbff
fbf8  af         XRA A
fbf9  32 2e 76   STA 762e
fbfc  c3 09 fc   JMP fc09
????:
fbff  fe 19      CPI A, 19
fc01  c2 b7 fb   JNZ fbb7
fc04  3e ff      MVI A, ff
fc06  32 2e 76   STA 762e
????:
fc09  16 09      MVI D, 09
????:
fc0b  15         DCR D
fc0c  c2 b7 fb   JNZ fbb7
fc0f  21 04 e0   LXI HL, e004
fc12  36 d0      MVI M, d0
fc14  36 76      MVI M, 76
fc16  23         INX HL
fc17  36 23      MVI M, 23
fc19  36 49      MVI M, 49
fc1b  3e 27      MVI A, 27
fc1d  32 01 c0   STA c001
fc20  3e e0      MVI A, e0
fc22  32 01 c0   STA c001
fc25  2e 08      MVI L, 08
fc27  36 a4      MVI M, a4
fc29  2a 0d 76   LHLD 760d
fc2c  f9         SPHL
fc2d  3a 2e 76   LDA 762e
fc30  a9         XRA C
fc31  c3 a1 fc   JMP fca1
????:
fc34  2a 0d 76   LHLD 760d
fc37  f9         SPHL
fc38  cd ce fa   CALL face
fc3b  7a         MOV A, D
fc3c  b7         ORA A
fc3d  f2 ae fa   JP faae
fc40  cd a4 f9   CALL f9a4
fc43  c3 9c fb   JMP fb9c
????:
fc46  e5         PUSH HL
fc47  c5         PUSH BC
fc48  d5         PUSH DE
fc49  f5         PUSH PSW
fc4a  3e 80      MVI A, 80
fc4c  32 08 e0   STA e008
fc4f  21 00 00   LXI HL, 0000
fc52  39         DAD SP
fc53  31 00 00   LXI SP, 0000
fc56  16 08      MVI D, 08
????:
fc58  f1         POP PSW
fc59  79         MOV A, C
fc5a  07         RLC
fc5b  4f         MOV C, A
fc5c  3e 01      MVI A, 01
fc5e  a9         XRA C
fc5f  32 02 80   STA 8002
fc62  3a 30 76   LDA 7630
fc65  47         MOV B, A
????:
fc66  f1         POP PSW
fc67  05         DCR B
fc68  c2 66 fc   JNZ fc66
fc6b  3e 00      MVI A, 00
fc6d  a9         XRA C
fc6e  32 02 80   STA 8002
fc71  15         DCR D
fc72  3a 30 76   LDA 7630
fc75  c2 7a fc   JNZ fc7a
fc78  d6 0e      SUI A, 0e
????:
fc7a  47         MOV B, A
????:
fc7b  f1         POP PSW
fc7c  05         DCR B
fc7d  c2 7b fc   JNZ fc7b
fc80  14         INR D
fc81  15         DCR D
fc82  c2 58 fc   JNZ fc58
fc85  f9         SPHL
fc86  21 04 e0   LXI HL, e004
fc89  36 d0      MVI M, d0
fc8b  36 76      MVI M, 76
fc8d  23         INX HL
fc8e  36 23      MVI M, 23
fc90  36 49      MVI M, 49
fc92  3e 27      MVI A, 27
fc94  32 01 c0   STA c001
fc97  3e e0      MVI A, e0
fc99  32 01 c0   STA c001
fc9c  2e 08      MVI L, 08
fc9e  36 a4      MVI M, a4
fca0  f1         POP PSW
????:
fca1  d1         POP DE
fca2  c1         POP BC
fca3  e1         POP HL
fca4  c9         RET
????:
fca5  f5         PUSH PSW
fca6  0f         RRC
fca7  0f         RRC
fca8  0f         RRC
fca9  0f         RRC
fcaa  cd ae fc   CALL fcae
fcad  f1         POP PSW
????:
fcae  e6 0f      ANI A, 0f
fcb0  fe 0a      CPI A, 0a
fcb2  fa b7 fc   JM fcb7
fcb5  c6 07      ADI A, 07
????:
fcb7  c6 30      ADI A, 30
????:
fcb9  4f         MOV C, A
????:
fcba  f5         PUSH PSW
fcbb  c5         PUSH BC
fcbc  d5         PUSH DE
fcbd  e5         PUSH HL
fcbe  cd 01 fe   CALL fe01
fcc1  21 85 fd   LXI HL, fd85
fcc4  e5         PUSH HL
fcc5  2a 02 76   LHLD 7602
fcc8  eb         XCHG
fcc9  2a 00 76   LHLD 7600
fccc  3a 04 76   LDA 7604
fccf  3d         DCR A
fcd0  fa ee fc   JM fcee
fcd3  ca 65 fd   JZ fd65
fcd6  e2 73 fd   JPO fd73
fcd9  79         MOV A, C
fcda  d6 20      SUI A, 20
fcdc  4f         MOV C, A
????:
fcdd  0d         DCR C
fcde  fa e9 fc   JM fce9
fce1  c5         PUSH BC
fce2  cd b9 fd   CALL fdb9
fce5  c1         POP BC
fce6  c3 dd fc   JMP fcdd
????:
fce9  af         XRA A
????:
fcea  32 04 76   STA 7604
fced  c9         RET
????:
fcee  79         MOV A, C
fcef  e6 7f      ANI A, 7f
fcf1  4f         MOV C, A
fcf2  fe 1f      CPI A, 1f
fcf4  ca a3 fd   JZ fda3
fcf7  fe 0c      CPI A, 0c
fcf9  ca b2 fd   JZ fdb2
fcfc  fe 0d      CPI A, 0d
fcfe  ca f3 fd   JZ fdf3
fd01  fe 0a      CPI A, 0a
fd03  ca 47 fd   JZ fd47
fd06  fe 08      CPI A, 08
fd08  ca d6 fd   JZ fdd6
fd0b  fe 18      CPI A, 18
fd0d  ca b9 fd   JZ fdb9
fd10  fe 19      CPI A, 19
fd12  ca e2 fd   JZ fde2
fd15  fe 1a      CPI A, 1a
fd17  ca c5 fd   JZ fdc5
fd1a  fe 1b      CPI A, 1b
fd1c  ca 9e fd   JZ fd9e
fd1f  fe 07      CPI A, 07
fd21  c2 38 fd   JNZ fd38
fd24  01 f0 05   LXI BC, 05f0
????:
fd27  78         MOV A, B
????:
fd28  fb         EI
fd29  3d         DCR A
fd2a  c2 28 fd   JNZ fd28
fd2d  78         MOV A, B
????:
fd2e  f3         DI
fd2f  3d         DCR A
fd30  c2 2e fd   JNZ fd2e
fd33  0d         DCR C
fd34  c2 27 fd   JNZ fd27
fd37  c9         RET
????:
fd38  71         MOV M, C
fd39  cd b9 fd   CALL fdb9
fd3c  7a         MOV A, D
fd3d  fe 03      CPI A, 03
fd3f  c0         RNZ
fd40  7b         MOV A, E
fd41  fe 08      CPI A, 08
fd43  c0         RNZ
fd44  cd e2 fd   CALL fde2
????:
fd47  7a         MOV A, D
fd48  fe 1b      CPI A, 1b
fd4a  c2 c5 fd   JNZ fdc5
fd4d  e5         PUSH HL
fd4e  d5         PUSH DE
fd4f  21 c2 77   LXI HL, 77c2
fd52  11 10 78   LXI DE, 7810
fd55  01 9e 07   LXI BC, 079e
????:
fd58  1a         LDAX DE
fd59  77         MOV M, A
fd5a  23         INX HL
fd5b  13         INX DE
fd5c  0b         DCX BC
fd5d  79         MOV A, C
fd5e  b0         ORA B
fd5f  c2 58 fd   JNZ fd58
fd62  d1         POP DE
fd63  e1         POP HL
fd64  c9         RET
????:
fd65  79         MOV A, C
fd66  fe 59      CPI A, 59
fd68  c2 e9 fc   JNZ fce9
fd6b  cd b2 fd   CALL fdb2
fd6e  3e 02      MVI A, 02
fd70  c3 ea fc   JMP fcea
????:
fd73  79         MOV A, C
fd74  d6 20      SUI A, 20
fd76  4f         MOV C, A
????:
fd77  0d         DCR C
fd78  3e 04      MVI A, 04
fd7a  fa ea fc   JM fcea
fd7d  c5         PUSH BC
fd7e  cd c5 fd   CALL fdc5
fd81  c1         POP BC
fd82  c3 77 fd   JMP fd77
????:
fd85  22 00 76   SHLD 7600
fd88  eb         XCHG
fd89  22 02 76   SHLD 7602
fd8c  3e 80      MVI A, 80
fd8e  32 01 c0   STA c001
fd91  7d         MOV A, L
fd92  32 00 c0   STA c000
fd95  7c         MOV A, H
fd96  32 00 c0   STA c000
fd99  e1         POP HL
fd9a  d1         POP DE
fd9b  c1         POP BC
fd9c  f1         POP PSW
fd9d  c9         RET
????:
fd9e  3e 01      MVI A, 01
fda0  c3 ea fc   JMP fcea
????:
fda3  21 f4 7f   LXI HL, 7ff4
fda6  11 25 09   LXI DE, 0925
????:
fda9  af         XRA A
fdaa  77         MOV M, A
fdab  2b         DCX HL
fdac  1b         DCX DE
fdad  7b         MOV A, E
fdae  b2         ORA D
fdaf  c2 a9 fd   JNZ fda9
????:
fdb2  11 08 03   LXI DE, 0308
fdb5  21 c2 77   LXI HL, 77c2
fdb8  c9         RET
????:
fdb9  7b         MOV A, E
fdba  23         INX HL
fdbb  1c         INR E
fdbc  fe 47      CPI A, 47
fdbe  c0         RNZ
fdbf  1e 08      MVI E, 08
fdc1  01 c0 ff   LXI BC, ffc0
fdc4  09         DAD BC
????:
fdc5  7a         MOV A, D
fdc6  fe 1b      CPI A, 1b
fdc8  01 4e 00   LXI BC, 004e
fdcb  c2 d3 fd   JNZ fdd3
fdce  16 02      MVI D, 02
fdd0  01 b0 f8   LXI BC, f8b0
????:
fdd3  14         INR D
fdd4  09         DAD BC
fdd5  c9         RET
????:
fdd6  7b         MOV A, E
fdd7  2b         DCX HL
fdd8  1d         DCR E
fdd9  fe 08      CPI A, 08
fddb  c0         RNZ
fddc  1e 47      MVI E, 47
fdde  01 40 00   LXI BC, 0040
fde1  09         DAD BC
????:
fde2  7a         MOV A, D
fde3  fe 03      CPI A, 03
fde5  01 b2 ff   LXI BC, ffb2
fde8  c2 f0 fd   JNZ fdf0
fdeb  16 1c      MVI D, 1c
fded  01 50 07   LXI BC, 0750
????:
fdf0  15         DCR D
fdf1  09         DAD BC
fdf2  c9         RET
????:
fdf3  7d         MOV A, L
fdf4  93         SUB E
fdf5  d2 f9 fd   JNC fdf9
fdf8  25         DCR H
????:
fdf9  6f         MOV L, A
fdfa  1e 08      MVI E, 08
fdfc  01 08 00   LXI BC, 0008
fdff  09         DAD BC
fe00  c9         RET
????:
fe01  3a 02 80   LDA 8002
fe04  e6 80      ANI A, 80
fe06  ca 0e fe   JZ fe0e
fe09  3a 05 76   LDA 7605
fe0c  b7         ORA A
fe0d  c0         RNZ
????:
fe0e  e5         PUSH HL
fe0f  2a 09 76   LHLD 7609
fe12  cd 72 fe   CALL fe72
fe15  bd         CMP L
fe16  6f         MOV L, A
fe17  ca 2a fe   JZ fe2a
????:
fe1a  3e 01      MVI A, 01
fe1c  32 0b 76   STA 760b
fe1f  26 15      MVI H, 15
????:
fe21  af         XRA A
????:
fe22  22 09 76   SHLD 7609
fe25  e1         POP HL
fe26  32 05 76   STA 7605
fe29  c9         RET
????:
fe2a  25         DCR H
fe2b  c2 21 fe   JNZ fe21
fe2e  3c         INR A
fe2f  ca 22 fe   JZ fe22
fe32  3c         INR A
fe33  ca 51 fe   JZ fe51
fe36  c5         PUSH BC
fe37  01 03 50   LXI BC, 5003
fe3a  cd 27 fd   CALL fd27
fe3d  c1         POP BC
fe3e  3a 0b 76   LDA 760b
fe41  26 e0      MVI H, e0
fe43  3d         DCR A
fe44  32 0b 76   STA 760b
fe47  ca 4c fe   JZ fe4c
fe4a  26 40      MVI H, 40
????:
fe4c  3e ff      MVI A, ff
fe4e  c3 22 fe   JMP fe22
????:
fe51  3a 02 80   LDA 8002
fe54  e6 80      ANI A, 80
fe56  ca 51 fe   JZ fe51
fe59  3a 06 76   LDA 7606
fe5c  2f         CMA
fe5d  32 06 76   STA 7606
fe60  c3 1a fe   JMP fe1a
????:
fe63  cd 01 fe   CALL fe01
fe66  b7         ORA A
fe67  ca 63 fe   JZ fe63
fe6a  af         XRA A
fe6b  32 05 76   STA 7605
fe6e  3a 09 76   LDA 7609
fe71  c9         RET
????:
fe72  3a 02 80   LDA 8002
fe75  e6 80      ANI A, 80
fe77  c2 7d fe   JNZ fe7d
fe7a  3e fe      MVI A, fe
fe7c  c9         RET
????:
fe7d  af         XRA A
fe7e  32 00 80   STA 8000
fe81  32 02 80   STA 8002
fe84  3a 06 76   LDA 7606
fe87  e6 01      ANI A, 01
fe89  f6 06      ORI A, 06
fe8b  32 03 80   STA 8003
fe8e  3a 01 80   LDA 8001
fe91  3c         INR A
fe92  c2 97 fe   JNZ fe97
fe95  3d         DCR A
fe96  c9         RET
????:
fe97  e5         PUSH HL
fe98  2e 01      MVI L, 01
fe9a  26 07      MVI H, 07
????:
fe9c  7d         MOV A, L
fe9d  0f         RRC
fe9e  6f         MOV L, A
fe9f  2f         CMA
fea0  32 00 80   STA 8000
fea3  3a 01 80   LDA 8001
fea6  2f         CMA
fea7  b7         ORA A
fea8  c2 b3 fe   JNZ feb3
feab  25         DCR H
feac  f2 9c fe   JP fe9c
????:
feaf  3e ff      MVI A, ff
feb1  e1         POP HL
feb2  c9         RET
????:
feb3  2e 20      MVI L, 20
????:
feb5  3a 01 80   LDA 8001
feb8  2f         CMA
feb9  b7         ORA A
feba  ca af fe   JZ feaf
febd  2d         DCR L
febe  c2 b5 fe   JNZ feb5
fec1  2e 08      MVI L, 08
????:
fec3  2d         DCR L
fec4  07         RLC
fec5  d2 c3 fe   JNC fec3
fec8  7c         MOV A, H
fec9  65         MOV H, L
feca  6f         MOV L, A
fecb  fe 01      CPI A, 01
fecd  ca fa fe   JZ fefa
fed0  da f3 fe   JC fef3
fed3  07         RLC
fed4  07         RLC
fed5  07         RLC
fed6  c6 20      ADI A, 20
fed8  b4         ORA H
fed9  fe 5f      CPI A, 5f
fedb  c2 06 ff   JNZ ff06
fede  3e 20      MVI A, 20
fee0  e1         POP HL
fee1  c9         RET
????:
fee2  09         DAD BC
fee3  0a         LDAX BC
fee4  0d         DCR C
fee5  7f         MOV A, A
fee6  08         db 08
fee7  19         DAD DE
fee8  18         db 18
fee9  1a         LDAX DE
????:
feea  0c         INR C
feeb  1f         RAR
feec  1b         DCX DE
feed  00         NOP
feee  01 02 03   LXI BC, 0302
fef1  04         INR B
fef2  05         DCR B
????:
fef3  7c         MOV A, H
fef4  21 ea fe   LXI HL, feea
fef7  c3 fe fe   JMP fefe
????:
fefa  7c         MOV A, H
fefb  21 e2 fe   LXI HL, fee2
????:
fefe  85         ADD L
feff  6f         MOV L, A
ff00  7e         MOV A, M
ff01  fe 40      CPI A, 40
ff03  e1         POP HL
ff04  d8         RC
ff05  e5         PUSH HL
????:
ff06  6f         MOV L, A
ff07  3a 02 80   LDA 8002
ff0a  67         MOV H, A
ff0b  e6 40      ANI A, 40
ff0d  c2 1a ff   JNZ ff1a
ff10  7d         MOV A, L
ff11  fe 40      CPI A, 40
ff13  fa 3f ff   JM ff3f
ff16  e6 1f      ANI A, 1f
ff18  e1         POP HL
ff19  c9         RET
????:
ff1a  3a 06 76   LDA 7606
ff1d  b7         ORA A
ff1e  ca 2a ff   JZ ff2a
ff21  7d         MOV A, L
ff22  fe 40      CPI A, 40
ff24  fa 2a ff   JM ff2a
ff27  f6 20      ORI A, 20
ff29  6f         MOV L, A
????:
ff2a  7c         MOV A, H
ff2b  e6 20      ANI A, 20
ff2d  c2 3f ff   JNZ ff3f
ff30  7d         MOV A, L
ff31  fe 40      CPI A, 40
ff33  fa 3b ff   JM ff3b
ff36  7d         MOV A, L
ff37  ee 20      XRI A, 20
ff39  e1         POP HL
ff3a  c9         RET
????:
ff3b  7d         MOV A, L
ff3c  e6 2f      ANI A, 2f
ff3e  6f         MOV L, A
????:
ff3f  7d         MOV A, L
ff40  fe 40      CPI A, 40
ff42  e1         POP HL
ff43  f0         RP
ff44  e5         PUSH HL
ff45  6f         MOV L, A
ff46  e6 0f      ANI A, 0f
ff48  fe 0c      CPI A, 0c
ff4a  7d         MOV A, L
ff4b  fa 50 ff   JM ff50
ff4e  ee 10      XRI A, 10
????:
ff50  e1         POP HL
ff51  c9         RET
????:
ff52  2a 31 76   LHLD 7631
ff55  c9         RET
????:
ff56  22 31 76   SHLD 7631
ff59  c9         RET
????:
ff5a  1f         RAR
ff5b  72         MOV M, D
ff5c  61         MOV H, C
ff5d  64         MOV H, H
ff5e  69         MOV L, C
ff5f  6f         MOV L, A
ff60  2d         DCR L
ff61  38         db 38
ff62  36 72      MVI M, 72
ff64  6b         MOV L, E
ff65  00         NOP
????:
ff66  0d         DCR C
ff67  0a         LDAX BC
ff68  2d         DCR L
ff69  2d         DCR L
ff6a  3e 00      MVI A, 00
????:
ff6c  0d         DCR C
ff6d  0a         LDAX BC
ff6e  18         db 18
ff6f  18         db 18
ff70  18         db 18
ff71  18         db 18
ff72  00         NOP
????:
ff73  0d         DCR C
ff74  0a         LDAX BC
ff75  20         db 20
ff76  50         MOV D, B
ff77  43         MOV B, E
ff78  2d         DCR L
ff79  0d         DCR C
ff7a  0a         LDAX BC
ff7b  20         db 20
ff7c  48         MOV C, B
ff7d  4c         MOV C, H
ff7e  2d         DCR L
ff7f  0d         DCR C
ff80  0a         LDAX BC
ff81  20         db 20
ff82  42         MOV B, D
ff83  43         MOV B, E
ff84  2d         DCR L
ff85  0d         DCR C
ff86  0a         LDAX BC
ff87  20         db 20
ff88  44         MOV B, H
ff89  45         MOV B, L
ff8a  2d         DCR L
ff8b  0d         DCR C
ff8c  0a         LDAX BC
ff8d  20         db 20
ff8e  53         MOV D, E
ff8f  50         MOV D, B
ff90  2d         DCR L
ff91  0d         DCR C
ff92  0a         LDAX BC
ff93  20         db 20
ff94  41         MOV B, C
ff95  46         MOV B, M
ff96  2d         DCR L
ff97  19         DAD DE
ff98  19         DAD DE
ff99  19         DAD DE
ff9a  19         DAD DE
ff9b  19         DAD DE
ff9c  19         DAD DE
ff9d  00         NOP
????:
ff9e  08         db 08
ff9f  20         db 20
ffa0  08         db 08
ffa1  00         NOP
????:
ffa2  22 16 76   SHLD 7616
ffa5  f5         PUSH PSW
ffa6  e1         POP HL
ffa7  22 1e 76   SHLD 761e
ffaa  e1         POP HL
ffab  2b         DCX HL
ffac  22 14 76   SHLD 7614
ffaf  21 00 00   LXI HL, 0000
????:
ffb2  39         DAD SP
ffb3  31 1e 76   LXI SP, 761e
ffb6  e5         PUSH HL
ffb7  d5         PUSH DE
ffb8  c5         PUSH BC
ffb9  2a 14 76   LHLD 7614
ffbc  31 cf 76   LXI SP, 76cf
ffbf  cd 78 fb   CALL fb78
ffc2  eb         XCHG
ffc3  2a 23 76   LHLD 7623
ffc6  cd 90 f9   CALL COMPARE_DE_HL (f990)
ffc9  c2 6c f8   JNZ f86c
ffcc  3a 25 76   LDA 7625
ffcf  77         MOV M, A
ffd0  c3 6c f8   JMP f86c
????:
ffd3  21 73 ff   LXI HL, ff73
ffd6  cd 22 f9   CALL f922
ffd9  21 14 76   LXI HL, 7614
ffdc  06 06      MVI B, 06
????:
ffde  5e         MOV E, M
ffdf  23         INX HL
ffe0  56         MOV D, M
ffe1  c5         PUSH BC
ffe2  e5         PUSH HL
ffe3  eb         XCHG
ffe4  cd 78 fb   CALL fb78
ffe7  cd ee f8   CALL f8ee
ffea  d2 f6 ff   JNC fff6
ffed  cd 5a f9   CALL f95a
fff0  d1         POP DE
fff1  d5         PUSH DE
fff2  eb         XCHG
fff3  72         MOV M, D
fff4  2b         DCX HL
fff5  73         MOV M, E
????:
fff6  e1         POP HL
fff7  c1         POP BC
fff8  05         DCR B
fff9  23         INX HL
fffa  c2 de ff   JNZ ffde
fffd  c9         RET
fffe  ff         RST 7
ffff  ff         RST 7

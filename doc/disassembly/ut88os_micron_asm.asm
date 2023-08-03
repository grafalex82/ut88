????:
d800  31 80 bf   LXI SP, bf80
d803  21 c5 df   LXI HL, dfc5
d806  cd 18 f8   CALL PRINT_STRING (f818)
d809  cd 25 d8   CALL d825
d80c  cd 50 de   CALL de50
d80f  cd d3 dd   CALL ddd3
d812  d6 31      SUI A, 31
d814  fa 1f d0   JM d01f
d817  fe 03      CPI A, 03
d819  32 94 bf   STA bf94
d81c  fa 2f d8   JM d82f
d81f  21 d6 df   LXI HL, dfd6
d822  c3 4d db   JMP db4d
????:
d825  cd 03 f8   CALL KBD_INPUT (f803)
d828  4f         MOV C, A
d829  fe 03      CPI A, 03
d82b  ca 65 f8   JZ f865
d82e  c9         RET
????:
d82f  af         XRA A
d830  32 95 bf   STA bf95
d833  3c         INR A
d834  32 83 bf   STA bf83
d837  21 00 00   LXI HL, 0000
d83a  22 98 bf   SHLD bf98
d83d  21 00 30   LXI HL, 3000
????:
d840  7e         MOV A, M
d841  3c         INR A
d842  23         INX HL
d843  ca 4c d8   JZ d84c
d846  cd 40 db   CALL db40
d849  c3 40 d8   JMP d840
????:
d84c  22 80 bf   SHLD bf80
d84f  36 00      MVI M, 00
????:
d851  21 00 30   LXI HL, 3000
d854  22 8f bf   SHLD bf8f
d857  21 00 a0   LXI HL, a000
d85a  22 85 bf   SHLD bf85
d85d  af         XRA A
d85e  32 82 bf   STA bf82
????:
d861  af         XRA A
d862  32 84 bf   STA bf84
d865  2a 85 bf   LHLD bf85
d868  22 87 bf   SHLD bf87
d86b  31 80 bf   LXI SP, bf80
d86e  cd 9a da   CALL da9a
d871  21 a0 bf   LXI HL, bfa0
d874  7e         MOV A, M
d875  fe 3b      CPI A, 3b
d877  ca c4 d0   JZ d0c4
d87a  cd cd da   CALL dacd
d87d  fe 3a      CPI A, 3a
d87f  c2 9b d8   JNZ d89b
d882  af         XRA A
d883  b9         CMP C
d884  ca 92 da   JZ da92
d887  e5         PUSH HL
d888  cd 12 db   CALL db12
d88b  e1         POP HL
d88c  cd 0a db   CALL db0a
d88f  b7         ORA A
d890  ca c4 d8   JZ d8c4
d893  fe 3b      CPI A, 3b
d895  ca c4 d8   JZ d8c4
d898  cd cd da   CALL dacd
????:
d89b  e5         PUSH HL
d89c  cd 0d dd   CALL dd0d
d89f  e1         POP HL
d8a0  cd b2 db   CALL dbb2
d8a3  e5         PUSH HL
d8a4  21 53 de   LXI HL, de53
d8a7  3a 89 bf   LDA bf89
d8aa  5f         MOV E, A
d8ab  16 00      MVI D, 00
d8ad  19         DAD DE
d8ae  19         DAD DE
d8af  5e         MOV E, M
d8b0  23         INX HL
d8b1  7e         MOV A, M
d8b2  b9         CMP C
d8b3  c2 8d da   JNZ da8d
d8b6  21 d9 d8   LXI HL, d8d9
d8b9  19         DAD DE
d8ba  11 c4 d8   LXI DE, d8c4
d8bd  eb         XCHG
d8be  e3         XTHL
d8bf  d5         PUSH DE
d8c0  3a 8b bf   LDA bf8b
d8c3  c9         RET
????:
d8c4  cd 80 dd   CALL dd80
d8c7  cd 12 f8   CALL f812
d8ca  00         NOP
d8cb  ca 61 d8   JZ d861
d8ce  cd 25 d8   CALL d825
d8d1  fe 03      CPI A, 03
d8d3  ca 00 d8   JZ d800
d8d6  c3 61 d8   JMP d861
????:
d8d9  f6 40      ORI A, 40
d8db  32 8c bf   STA bf8c
d8de  cd 9a db   CALL db9a
d8e1  3a 8a bf   LDA bf8a
d8e4  c3 32 da   JMP da32
d8e7  f6 06      ORI A, 06
d8e9  32 8c bf   STA bf8c
d8ec  cd 9a db   CALL db9a
d8ef  0e 01      MVI C, 01
d8f1  c3 40 da   JMP da40
d8f4  cd 56 da   CALL da56
d8f7  f6 01      ORI A, 01
d8f9  32 8c bf   STA bf8c
d8fc  cd 9a db   CALL db9a
d8ff  0e 02      MVI C, 02
d901  c3 40 da   JMP da40
d904  cd 56 da   CALL da56
d907  c3 32 da   JMP da32
d90a  cd 5e da   CALL da5e
d90d  c3 32 da   JMP da32
d910  cd 66 da   CALL da66
d913  c3 32 da   JMP da32
d916  3a 8a bf   LDA bf8a
d919  47         MOV B, A
d91a  e6 07      ANI A, 07
d91c  b8         CMP B
d91d  c2 8d da   JNZ da8d
d920  07         RLC
d921  07         RLC
d922  07         RLC
d923  c3 32 da   JMP da32
d926  2a 85 bf   LHLD bf85
d929  eb         XCHG
d92a  2a 8a bf   LHLD bf8a
d92d  19         DAD DE
d92e  22 85 bf   SHLD bf85
d931  c9         RET
d932  21 a0 bf   LXI HL, bfa0
d935  cd cd da   CALL dacd
d938  fe 3a      CPI A, 3a
d93a  c2 92 da   JNZ da92
d93d  2a 8a bf   LHLD bf8a
d940  22 87 bf   SHLD bf87
d943  eb         XCHG
d944  3a 83 bf   LDA bf83
d947  3d         DCR A
d948  c0         RNZ
d949  3a 84 bf   LDA bf84
d94c  3d         DCR A
d94d  c8         RZ
d94e  fa 54 d9   JM d954
d951  11 fe ff   LXI DE, fffe
????:
d954  2a 8d bf   LHLD bf8d
d957  73         MOV M, E
d958  23         INX HL
d959  72         MOV M, D
d95a  c9         RET
????:
d95b  eb         XCHG
d95c  2a 85 bf   LHLD bf85
d95f  1a         LDAX DE
d960  fe 27      CPI A, 27
d962  c2 76 d9   JNZ d976
d965  13         INX DE
????:
d966  1a         LDAX DE
d967  13         INX DE
d968  b7         ORA A
d969  ca 8d da   JZ da8d
d96c  fe 27      CPI A, 27
d96e  ca 88 d9   JZ d988
d971  77         MOV M, A
d972  23         INX HL
d973  c3 66 d9   JMP d966
????:
d976  3a 8a bf   LDA bf8a
d979  77         MOV M, A
d97a  23         INX HL
d97b  3a 89 bf   LDA bf89
d97e  fe 0e      CPI A, 0e
d980  ca 88 d9   JZ d988
d983  3a 8b bf   LDA bf8b
d986  77         MOV M, A
d987  23         INX HL
????:
d988  22 85 bf   SHLD bf85
d98b  eb         XCHG
d98c  cd 0a db   CALL db0a
d98f  b7         ORA A
d990  c8         RZ
d991  fe 3b      CPI A, 3b
d993  c8         RZ
d994  cd 9a db   CALL db9a
d997  c3 5b d9   JMP d95b
d99a  3a 95 bf   LDA bf95
d99d  b7         ORA A
d99e  c0         RNZ
d99f  3c         INR A
d9a0  32 95 bf   STA bf95
d9a3  21 00 a0   LXI HL, a000
d9a6  eb         XCHG
d9a7  2a 8a bf   LHLD bf8a
d9aa  cd 20 da   CALL da20
d9ad  22 98 bf   SHLD bf98
d9b0  c9         RET
????:
d9b1  cd 80 dd   CALL dd80
d9b4  21 83 bf   LXI HL, bf83
d9b7  7e         MOV A, M
d9b8  34         INR M
d9b9  3d         DCR A
d9ba  ca 51 d8   JZ d851
d9bd  3a 94 bf   LDA bf94
d9c0  fe 02      CPI A, 02
d9c2  c2 fc d9   JNZ d9fc
d9c5  0e 1f      MVI C, 1f
d9c7  cd 50 de   CALL de50
d9ca  2a 80 bf   LHLD bf80
????:
d9cd  06 06      MVI B, 06
????:
d9cf  7e         MOV A, M
d9d0  b7         ORA A
d9d1  ca fc d9   JZ d9fc
d9d4  4f         MOV C, A
d9d5  cd 50 de   CALL de50
d9d8  05         DCR B
d9d9  23         INX HL
d9da  c2 cf d9   JNZ d9cf
d9dd  0e 3d      MVI C, 3d
d9df  cd 50 de   CALL de50
d9e2  0e 20      MVI C, 20
d9e4  cd 50 de   CALL de50
d9e7  23         INX HL
d9e8  7e         MOV A, M
d9e9  cd 42 de   CALL de42
d9ec  2b         DCX HL
d9ed  7e         MOV A, M
d9ee  cd 42 de   CALL de42
d9f1  23         INX HL
d9f2  23         INX HL
d9f3  01 20 04   LXI BC, 0420
d9f6  cd 27 da   CALL da27
d9f9  c3 cd d9   JMP d9cd
????:
d9fc  21 b3 df   LXI HL, dfb3
d9ff  cd 18 f8   CALL PRINT_STRING (f818)
da02  3a 82 bf   LDA bf82
da05  cd 42 de   CALL de42
da08  cd d3 dd   CALL ddd3
da0b  2a 85 bf   LHLD bf85
da0e  2b         DCX HL
da0f  eb         XCHG
da10  2a 98 bf   LHLD bf98
da13  19         DAD DE
da14  0e 2f      MVI C, 2f
da16  cd 48 de   CALL de48
da19  eb         XCHG
da1a  cd 48 de   CALL de48
da1d  c3 00 d8   JMP d800
????:
da20  7d         MOV A, L
da21  93         SUB E
da22  6f         MOV L, A
da23  7c         MOV A, H
da24  9a         SBB D
da25  67         MOV H, A
da26  c9         RET
????:
da27  04         INR B
da28  05         DCR B
da29  c8         RZ
????:
da2a  cd 50 de   CALL de50
da2d  05         DCR B
da2e  c8         RZ
da2f  c3 2a da   JMP da2a
????:
da32  47         MOV B, A
da33  3a 8c bf   LDA bf8c
da36  b0         ORA B
da37  2a 85 bf   LHLD bf85
????:
da3a  77         MOV M, A
da3b  23         INX HL
????:
da3c  22 85 bf   SHLD bf85
da3f  c9         RET
????:
da40  2a 8a bf   LHLD bf8a
da43  eb         XCHG
da44  2a 85 bf   LHLD bf85
da47  3a 8c bf   LDA bf8c
da4a  77         MOV M, A
da4b  23         INX HL
da4c  73         MOV M, E
da4d  23         INX HL
da4e  0d         DCR C
da4f  ca 3c da   JZ da3c
da52  7a         MOV A, D
da53  c3 3a da   JMP da3a
????:
da56  fe 40      CPI A, 40
????:
da58  c2 63 da   JNZ da63
da5b  3e 30      MVI A, 30
da5d  c9         RET
????:
da5e  fe 48      CPI A, 48
da60  c3 58 da   JMP da58
????:
da63  fe 20      CPI A, 20
da65  c8         RZ
????:
da66  fe 10      CPI A, 10
da68  c8         RZ
da69  b7         ORA A
da6a  c2 8d da   JNZ da8d
da6d  c9         RET
????:
da6e  06 01      MVI B, 01
da70  c3 78 da   JMP da78
????:
da73  06 02      MVI B, 02
da75  11 fe ff   LXI DE, fffe
????:
da78  e5         PUSH HL
da79  21 84 bf   LXI HL, bf84
da7c  7e         MOV A, M
da7d  b0         ORA B
da7e  77         MOV M, A
da7f  21 82 bf   LXI HL, bf82
da82  7e         MOV A, M
da83  3c         INR A
da84  27         DAA
da85  77         MOV M, A
da86  e1         POP HL
da87  c9         RET
????:
da88  06 04      MVI B, 04
da8a  c3 94 da   JMP da94
????:
da8d  06 08      MVI B, 08
da8f  c3 94 da   JMP da94
????:
da92  06 10      MVI B, 10
????:
da94  cd 78 da   CALL da78
da97  c3 c4 d8   JMP d8c4
????:
da9a  11 a0 bf   LXI DE, bfa0
da9d  0e 40      MVI C, 40
da9f  2a 8f bf   LHLD bf8f
????:
daa2  7e         MOV A, M
daa3  fe ff      CPI A, ff
daa5  ca b1 d9   JZ d9b1
daa8  fe 0d      CPI A, 0d
daaa  ca c0 da   JZ dac0
daad  fe 09      CPI A, 09
daaf  c2 b4 da   JNZ dab4
dab2  3e 20      MVI A, 20
????:
dab4  12         STAX DE
dab5  af         XRA A
dab6  b9         CMP C
dab7  ca bc da   JZ dabc
daba  13         INX DE
dabb  0d         DCR C
????:
dabc  23         INX HL
dabd  c3 a2 da   JMP daa2
????:
dac0  af         XRA A
dac1  12         STAX DE
dac2  23         INX HL
dac3  79         MOV A, C
dac4  fe 40      CPI A, 40
dac6  ca a2 da   JZ daa2
dac9  22 8f bf   SHLD bf8f
dacc  c9         RET
????:
dacd  0e 06      MVI C, 06
dacf  11 e0 bf   LXI DE, bfe0
dad2  d5         PUSH DE
dad3  3e 20      MVI A, 20
????:
dad5  12         STAX DE
dad6  13         INX DE
dad7  0d         DCR C
dad8  c2 d5 da   JNZ dad5
dadb  d1         POP DE
dadc  cd 0a db   CALL db0a
dadf  fe 3f      CPI A, 3f
dae1  f8         RM
dae2  fe 80      CPI A, 80
dae4  f0         RP
????:
dae5  47         MOV B, A
dae6  79         MOV A, C
dae7  fe 06      CPI A, 06
dae9  ca f0 da   JZ daf0
daec  78         MOV A, B
daed  12         STAX DE
daee  13         INX DE
daef  0c         INR C
????:
daf0  23         INX HL
daf1  7e         MOV A, M
daf2  fe 30      CPI A, 30
daf4  fa 0a db   JM db0a
daf7  fe 3a      CPI A, 3a
daf9  ca 08 db   JZ db08
dafc  fa e5 da   JM dae5
daff  ff         RST 7
db00  40         MOV B, B
db01  f8         RM
db02  fe 80      CPI A, 80
db04  fa e5 da   JM dae5
db07  c9         RET
????:
db08  23         INX HL
db09  c9         RET
????:
db0a  7e         MOV A, M
db0b  fe 20      CPI A, 20
db0d  c0         RNZ
db0e  23         INX HL
db0f  c3 0a db   JMP db0a
????:
db12  cd 79 db   CALL db79
db15  3a 83 bf   LDA bf83
db18  3d         DCR A
db19  c2 5e db   JNZ db5e
db1c  b9         CMP C
db1d  ca 59 db   JZ db59
db20  11 e0 bf   LXI DE, bfe0
db23  0e 06      MVI C, 06
????:
db25  1a         LDAX DE
db26  77         MOV M, A
db27  13         INX DE
db28  23         INX HL
db29  0d         DCR C
db2a  c2 25 db   JNZ db25
db2d  22 8d bf   SHLD bf8d
db30  e5         PUSH HL
db31  2a 85 bf   LHLD bf85
db34  eb         XCHG
db35  2a 98 bf   LHLD bf98
db38  19         DAD DE
db39  eb         XCHG
db3a  e1         POP HL
db3b  73         MOV M, E
db3c  23         INX HL
db3d  72         MOV M, D
db3e  23         INX HL
db3f  71         MOV M, C
????:
db40  eb         XCHG
db41  21 f0 ff   LXI HL, fff0
db44  39         DAD SP
db45  eb         XCHG
db46  cd 53 db   CALL db53
db49  d8         RC
db4a  21 eb df   LXI HL, dfeb
????:
db4d  cd 18 f8   CALL PRINT_STRING (f818)
db50  c3 00 d8   JMP d800
????:
db53  7c         MOV A, H
db54  ba         CMP D
db55  c0         RNZ
db56  7d         MOV A, L
db57  bb         CMP E
db58  c9         RET
????:
db59  3d         DCR A
db5a  77         MOV M, A
db5b  23         INX HL
db5c  77         MOV M, A
db5d  c9         RET
????:
db5e  46         MOV B, M
db5f  23         INX HL
db60  7e         MOV A, M
db61  fe ff      CPI A, ff
db63  c0         RNZ
db64  b8         CMP B
db65  ca 6e da   JZ da6e
db68  3d         DCR A
db69  b8         CMP B
db6a  ca 73 da   JZ da73
db6d  c9         RET
????:
db6e  cd 79 db   CALL db79
db71  0d         DCR C
db72  f2 73 da   JP da73
db75  5e         MOV E, M
db76  23         INX HL
db77  56         MOV D, M
db78  c9         RET
????:
db79  2a 80 bf   LHLD bf80
????:
db7c  0e 06      MVI C, 06
db7e  af         XRA A
db7f  be         CMP M
db80  c8         RZ
db81  e5         PUSH HL
db82  11 e0 bf   LXI DE, bfe0
????:
db85  1a         LDAX DE
db86  be         CMP M
db87  ca 92 db   JZ db92
db8a  e1         POP HL
db8b  01 08 00   LXI BC, 0008
db8e  09         DAD BC
db8f  c3 7c db   JMP db7c
????:
db92  13         INX DE
db93  23         INX HL
db94  0d         DCR C
db95  c2 85 db   JNZ db85
db98  d1         POP DE
db99  c9         RET
????:
db9a  7e         MOV A, M
db9b  fe 2c      CPI A, 2c
db9d  c2 8d da   JNZ da8d
dba0  23         INX HL
dba1  cd b2 db   CALL dbb2
dba4  3a 89 bf   LDA bf89
dba7  fe 03      CPI A, 03
dba9  ca ad db   JZ dbad
dbac  0d         DCR C
????:
dbad  0d         DCR C
dbae  c2 8d da   JNZ da8d
dbb1  c9         RET
????:
dbb2  cd cd da   CALL dacd
dbb5  af         XRA A
dbb6  32 93 bf   STA bf93
dbb9  32 8a bf   STA bf8a
dbbc  32 8b bf   STA bf8b
dbbf  b9         CMP C
dbc0  ca da db   JZ dbda
dbc3  cd 22 dc   CALL dc22
dbc6  fe 01      CPI A, 01
dbc8  c2 d3 db   JNZ dbd3
dbcb  4f         MOV C, A
dbcc  cd 17 dc   CALL dc17
dbcf  c8         RZ
dbd0  da 8d da   JC da8d
????:
dbd3  e5         PUSH HL
dbd4  cd 6e db   CALL db6e
dbd7  c3 03 dc   JMP dc03
????:
dbda  cd 17 dc   CALL dc17
dbdd  c8         RZ
dbde  fe 2b      CPI A, 2b
dbe0  ca e8 db   JZ dbe8
dbe3  fe 2d      CPI A, 2d
dbe5  c2 ec db   JNZ dbec
????:
dbe8  32 93 bf   STA bf93
dbeb  23         INX HL
????:
dbec  cd 58 dc   CALL dc58
dbef  0c         INR C
dbf0  ca 8d da   JZ da8d
dbf3  3a 93 bf   LDA bf93
dbf6  fe 2d      CPI A, 2d
dbf8  c2 02 dc   JNZ dc02
dbfb  af         XRA A
dbfc  93         SUB E
dbfd  5f         MOV E, A
dbfe  3e 00      MVI A, 00
dc00  9a         SBB D
dc01  57         MOV D, A
????:
dc02  e5         PUSH HL
????:
dc03  2a 8a bf   LHLD bf8a
dc06  19         DAD DE
dc07  22 8a bf   SHLD bf8a
dc0a  e1         POP HL
dc0b  cd 58 dc   CALL dc58
dc0e  0c         INR C
dc0f  c2 8d da   JNZ da8d
dc12  0e 02      MVI C, 02
dc14  c3 da db   JMP dbda
????:
dc17  7e         MOV A, M
dc18  b7         ORA A
dc19  c8         RZ
dc1a  fe 2c      CPI A, 2c
dc1c  c8         RZ
dc1d  fe 3b      CPI A, 3b
dc1f  c8         RZ
dc20  37         STC
dc21  c9         RET
????:
dc22  e5         PUSH HL
dc23  21 77 de   LXI HL, de77
dc26  41         MOV B, C
????:
dc27  11 e0 bf   LXI DE, bfe0
dc2a  48         MOV C, B
dc2b  7e         MOV A, M
dc2c  23         INX HL
dc2d  b7         ORA A
dc2e  ca 56 dc   JZ dc56
dc31  b9         CMP C
dc32  ca 3f dc   JZ dc3f
dc35  4f         MOV C, A
????:
dc36  23         INX HL
dc37  0d         DCR C
dc38  c2 36 dc   JNZ dc36
dc3b  23         INX HL
dc3c  c3 27 dc   JMP dc27
????:
dc3f  1a         LDAX DE
dc40  13         INX DE
dc41  be         CMP M
dc42  c2 36 dc   JNZ dc36
dc45  23         INX HL
dc46  0d         DCR C
dc47  c2 3f dc   JNZ dc3f
dc4a  7e         MOV A, M
dc4b  32 8a bf   STA bf8a
dc4e  07         RLC
dc4f  07         RLC
dc50  07         RLC
dc51  32 8b bf   STA bf8b
dc54  3e 01      MVI A, 01
????:
dc56  e1         POP HL
dc57  c9         RET
????:
dc58  cd cd da   CALL dacd
dc5b  0d         DCR C
dc5c  f2 ef dc   JP dcef
dc5f  7e         MOV A, M
dc60  fe 27      CPI A, 27
dc62  ca d2 dc   JZ dcd2
dc65  fe 24      CPI A, 24
dc67  ca fe dc   JZ dcfe
dc6a  fe 30      CPI A, 30
dc6c  f8         RM
dc6d  fe 3a      CPI A, 3a
dc6f  f0         RP
dc70  11 e0 bf   LXI DE, bfe0
dc73  0e 00      MVI C, 00
????:
dc75  d6 30      SUI A, 30
dc77  12         STAX DE
dc78  13         INX DE
dc79  23         INX HL
dc7a  7e         MOV A, M
dc7b  fe 30      CPI A, 30
dc7d  fa 9a dc   JM dc9a
dc80  fe 3a      CPI A, 3a
dc82  fa 75 dc   JM dc75
dc85  fe 41      CPI A, 41
dc87  fa 9a dc   JM dc9a
dc8a  0c         INR C
dc8b  fe 48      CPI A, 48
dc8d  ca a4 dc   JZ dca4
dc90  fe 4a      CPI A, 4a
dc92  f2 8d da   JP da8d
dc95  d6 07      SUI A, 07
dc97  c3 75 dc   JMP dc75
????:
dc9a  af         XRA A
dc9b  b9         CMP C
dc9c  c2 8d da   JNZ da8d
dc9f  3e 19      MVI A, 19
dca1  c3 a7 dc   JMP dca7
????:
dca4  23         INX HL
dca5  3e 29      MVI A, 29
????:
dca7  12         STAX DE
dca8  e5         PUSH HL
dca9  21 e0 bf   LXI HL, bfe0
dcac  11 00 00   LXI DE, 0000
dcaf  de 19      SBI A, 19
????:
dcb1  47         MOV B, A
dcb2  7e         MOV A, M
dcb3  23         INX HL
dcb4  fe 10      CPI A, 10
dcb6  f2 09 dd   JP dd09
dcb9  4f         MOV C, A
dcba  78         MOV A, B
dcbb  b7         ORA A
dcbc  06 00      MVI B, 00
dcbe  e5         PUSH HL
dcbf  62         MOV H, D
dcc0  6b         MOV L, E
dcc1  29         DAD HL
dcc2  29         DAD HL
dcc3  c2 ca dc   JNZ dcca
dcc6  19         DAD DE
dcc7  c3 cb dc   JMP dccb
????:
dcca  29         DAD HL
????:
dccb  29         DAD HL
dccc  09         DAD BC
dccd  eb         XCHG
dcce  e1         POP HL
dccf  c3 b1 dc   JMP dcb1
????:
dcd2  0e 02      MVI C, 02
dcd4  3a 89 bf   LDA bf89
dcd7  fe 0e      CPI A, 0e
dcd9  c2 df dc   JNZ dcdf
dcdc  33         INX SP
dcdd  33         INX SP
dcde  c9         RET
????:
dcdf  23         INX HL
dce0  5e         MOV E, M
dce1  23         INX HL
dce2  56         MOV D, M
????:
dce3  7e         MOV A, M
dce4  23         INX HL
dce5  b7         ORA A
dce6  ca 8d da   JZ da8d
dce9  fe 27      CPI A, 27
dceb  c2 e3 dc   JNZ dce3
dcee  c9         RET
????:
dcef  cd 22 dc   CALL dc22
dcf2  fe 01      CPI A, 01
dcf4  ca 8d da   JZ da8d
dcf7  e5         PUSH HL
dcf8  cd 6e db   CALL db6e
dcfb  c3 09 dd   JMP dd09
????:
dcfe  23         INX HL
dcff  e5         PUSH HL
dd00  2a 87 bf   LHLD bf87
dd03  eb         XCHG
dd04  2a 98 bf   LHLD bf98
dd07  19         DAD DE
dd08  eb         XCHG
????:
dd09  e1         POP HL
dd0a  0e 02      MVI C, 02
dd0c  c9         RET
????:
dd0d  3a e3 bf   LDA bfe3
dd10  fe 58      CPI A, 58
dd12  c2 18 dd   JNZ dd18
dd15  32 e2 bf   STA bfe2
????:
dd18  3a e0 bf   LDA bfe0
dd1b  d6 41      SUI A, 41
dd1d  fa 88 da   JM da88
dd20  5f         MOV E, A
dd21  16 00      MVI D, 00
dd23  21 99 de   LXI HL, de99
dd26  19         DAD DE
dd27  5e         MOV E, M
dd28  23         INX HL
dd29  7e         MOV A, M
dd2a  93         SUB E
dd2b  ca 88 da   JZ da88
dd2e  4f         MOV C, A
dd2f  c5         PUSH BC
dd30  21 b4 de   LXI HL, deb4
dd33  19         DAD DE
dd34  19         DAD DE
dd35  19         DAD DE
dd36  0e 20      MVI C, 20
dd38  3a e1 bf   LDA bfe1
dd3b  91         SUB C
dd3c  ca 43 dd   JZ dd43
dd3f  91         SUB C
dd40  fa 88 da   JM da88
????:
dd43  07         RLC
dd44  07         RLC
dd45  07         RLC
dd46  47         MOV B, A
dd47  3a e2 bf   LDA bfe2
dd4a  91         SUB C
dd4b  ca 52 dd   JZ dd52
dd4e  91         SUB C
dd4f  fa 88 da   JM da88
????:
dd52  0f         RRC
dd53  0f         RRC
dd54  4f         MOV C, A
dd55  e6 07      ANI A, 07
dd57  b0         ORA B
dd58  57         MOV D, A
dd59  79         MOV A, C
dd5a  e6 c0      ANI A, c0
dd5c  5f         MOV E, A
dd5d  c1         POP BC
????:
dd5e  7e         MOV A, M
dd5f  23         INX HL
dd60  ba         CMP D
dd61  c2 6b dd   JNZ dd6b
dd64  7e         MOV A, M
dd65  e6 c0      ANI A, c0
dd67  bb         CMP E
dd68  ca 74 dd   JZ dd74
????:
dd6b  23         INX HL
dd6c  23         INX HL
dd6d  0d         DCR C
dd6e  c2 5e dd   JNZ dd5e
dd71  c3 88 da   JMP da88
????:
dd74  7e         MOV A, M
dd75  e6 3f      ANI A, 3f
dd77  32 89 bf   STA bf89
dd7a  23         INX HL
dd7b  7e         MOV A, M
dd7c  32 8c bf   STA bf8c
dd7f  c9         RET
????:
dd80  3a 94 bf   LDA bf94
dd83  1f         RAR
dd84  d0         RNC
dd85  3a 83 bf   LDA bf83
dd88  3d         DCR A
dd89  c8         RZ
dd8a  cd d3 dd   CALL ddd3
dd8d  3a 84 bf   LDA bf84
dd90  b7         ORA A
dd91  ca 9f dd   JZ dd9f
dd94  cd 42 de   CALL de42
dd97  0e 2a      MVI C, 2a
dd99  cd 50 de   CALL de50
dd9c  c3 a5 dd   JMP dda5
????:
dd9f  01 20 03   LXI BC, 0320
dda2  cd 27 da   CALL da27
????:
dda5  11 a0 bf   LXI DE, bfa0
dda8  1a         LDAX DE
dda9  fe 3b      CPI A, 3b
ddab  01 20 11   LXI BC, 1120
ddae  ca b8 dd   JZ ddb8
ddb1  af         XRA A
ddb2  32 93 bf   STA bf93
ddb5  cd dd dd   CALL dddd
????:
ddb8  eb         XCHG
ddb9  cd 27 da   CALL da27
ddbc  cd 18 f8   CALL PRINT_STRING (f818)
????:
ddbf  3a 93 bf   LDA bf93
ddc2  b7         ORA A
ddc3  c8         RZ
ddc4  cd d3 dd   CALL ddd3
ddc7  01 20 03   LXI BC, 0320
ddca  cd 27 da   CALL da27
ddcd  cd dd dd   CALL dddd
ddd0  c3 bf dd   JMP ddbf
????:
ddd3  0e 0d      MVI C, 0d
ddd5  cd 50 de   CALL de50
ddd8  0e 0a      MVI C, 0a
ddda  c3 50 de   JMP de50
????:
dddd  3a 89 bf   LDA bf89
dde0  fe 0c      CPI A, 0c
dde2  c8         RZ
dde3  fe 0d      CPI A, 0d
dde5  c8         RZ
dde6  2a 87 bf   LHLD bf87
dde9  fe 11      CPI A, 11
ddeb  ca 3d de   JZ de3d
ddee  f5         PUSH PSW
ddef  d5         PUSH DE
ddf0  eb         XCHG
ddf1  2a 98 bf   LHLD bf98
ddf4  19         DAD DE
ddf5  cd 48 de   CALL de48
ddf8  eb         XCHG
ddf9  d1         POP DE
ddfa  f1         POP PSW
ddfb  fe 10      CPI A, 10
ddfd  ca 24 de   JZ de24
de00  06 04      MVI B, 04
????:
de02  3a 85 bf   LDA bf85
de05  95         SUB L
de06  ca 1c de   JZ de1c
de09  7e         MOV A, M
de0a  23         INX HL
de0b  cd 42 de   CALL de42
de0e  cd 50 de   CALL de50
de11  05         DCR B
de12  c2 02 de   JNZ de02
de15  3a 85 bf   LDA bf85
de18  95         SUB L
de19  22 87 bf   SHLD bf87
????:
de1c  32 93 bf   STA bf93
de1f  78         MOV A, B
de20  07         RLC
de21  80         ADD B
de22  47         MOV B, A
de23  c9         RET
????:
de24  0e 28      MVI C, 28
de26  cd 50 de   CALL de50
de29  0e 20      MVI C, 20
de2b  cd 50 de   CALL de50
de2e  2a 8a bf   LHLD bf8a
de31  cd 48 de   CALL de48
de34  0e 29      MVI C, 29
de36  cd 50 de   CALL de50
de39  01 20 04   LXI BC, 0420
de3c  c9         RET
????:
de3d  06 0c      MVI B, 0c
de3f  c3 48 de   JMP de48
????:
de42  c5         PUSH BC
de43  cd 15 f8   CALL f815
de46  c1         POP BC
de47  c9         RET
????:
de48  7c         MOV A, H
de49  cd 42 de   CALL de42
de4c  7d         MOV A, L
de4d  cd 42 de   CALL de42
????:
de50  c3 09 f8   JMP PUT_CHAR (f809)
????:
de53  0b         DCX BC
de54  00         NOP
de55  08         db 08
de56  01 2e 01   LXI BC, 012e
de59  00         NOP
de5a  01 16 02   LXI BC, 0216
de5d  0e 01      MVI C, 01
de5f  26 02      MVI H, 02
de61  2b         DCX HL
de62  01 31 01   LXI BC, 0131
de65  37         STC
de66  01 1b 01   LXI BC, 011b
de69  3d         DCR A
de6a  02         STAX BC
de6b  c1         POP BC
de6c  02         STAX BC
de6d  d8         RC
de6e  00         NOP
de6f  82         ADD D
de70  02         STAX BC
de71  82         ADD D
de72  02         STAX BC
de73  4d         MOV C, L
de74  02         STAX BC
de75  59         MOV E, C
de76  02         STAX BC
????:
de77  01 41 07   LXI BC, 0741
de7a  01 42 00   LXI BC, 0042
de7d  01 43 01   LXI BC, 0143
de80  01 44 02   LXI BC, 0244
de83  01 45 03   LXI BC, 0345
de86  01 48 04   LXI BC, 0448
de89  01 4c 05   LXI BC, 054c
de8c  01 4d 00   LXI BC, 004d
de8f  02         STAX BC
de90  53         MOV D, E
de91  50         MOV D, B
de92  08         db 08
de93  03         INX BC
de94  50         MOV D, B
de95  53         MOV D, E
de96  57         MOV D, A
de97  09         DAD BC
de98  00         NOP
????:
de99  00         NOP
de9a  06 06      MVI B, 06
de9c  13         INX DE
de9d  1b         DCX DE
de9e  1e 1e      MVI E, 1e
dea0  1e 1f      MVI E, 1f
dea2  22 2c 2c   SHLD 2c2c
dea5  30         db 30
dea6  32 33 37   STA 3733
dea9  3a 3a 48   LDA 483a
deac  51         MOV D, C
dead  51         MOV D, C
deae  51         MOV D, C
deaf  51         MOV D, C
deb0  51         MOV D, C
deb1  55         MOV D, L
deb2  55         MOV D, L
deb3  55         MOV D, L
????:
deb4  1a         LDAX DE
deb5  44         MOV B, H
deb6  ce 20      ACI A, 20
deb8  c1         POP BC
deb9  88         ADC B
deba  21 01 80   LXI HL, 8001
debd  22 44 c6   SHLD c644
dec0  70         MOV M, B
dec1  41         MOV B, C
dec2  a0         ANA B
dec3  72         MOV M, D
dec4  44         MOV B, H
dec5  e6 0b      ANI A, 0b
dec7  06 cd      MVI B, cd
dec9  18         db 18
deca  06 dc      MVI B, dc
decc  68         MOV L, B
decd  06 fc      MVI B, fc
decf  68         MOV L, B
ded0  40         MOV B, B
ded1  2f         CMA
ded2  68         MOV L, B
ded3  c0         RNZ
ded4  3f         CMC
ded5  6c         MOV L, H
ded6  01 b8 70   LXI BC, 70b8
ded9  c6 d4      ADI A, d4
dedb  76         HLT
dedc  86         ADD M
dedd  c4 00 06   CNZ 0600
dee0  f4 81 46   CP 4681
dee3  ec 82 44   CPE 4482
dee6  fe 83      CPI A, 83
dee8  c6 e4      ADI A, e4
deea  d0         RNC
deeb  06 cc      MVI B, cc
deed  08         db 08
deee  40         MOV B, B
deef  27         DAA
def0  09         DAD BC
def1  07         RLC
def2  09         DAD BC
def3  1c         INR E
def4  82         ADD D
def5  05         DCR B
def6  1e 07      MVI E, 07
def8  0b         DCX BC
def9  48         MOV C, B
defa  00         NOP
defb  f3         DI
defc  10         db 10
defd  0e 60      MVI C, 60
deff  b8         CMP B
df00  0f         RRC
df01  00         NOP
df02  98         SBB B
df03  10         db 10
df04  00         NOP
df05  48         MOV C, B
df06  00         NOP
df07  fb         EI
df08  71         MOV M, C
df09  0d         DCR C
df0a  00         NOP
df0b  80         ADD B
df0c  51         MOV D, C
df0d  00         NOP
df0e  65         MOV H, L
df0f  00         NOP
df10  76         HLT
df11  70         MOV M, B
df12  04         INR B
df13  db 74      IN 74
df15  82         ADD D
df16  04         INR B
df17  76         HLT
df18  07         RLC
df19  03         INX BC
df1a  18         db 18
df1b  06 da      MVI B, da
df1d  68         MOV L, B
df1e  06 fa      MVI B, fa
df20  6c         MOV L, H
df21  06 c3      MVI B, c3
df23  00         NOP
df24  06 c3      MVI B, c3
df26  70         MOV M, B
df27  c6 d2      ADI A, d2
df29  76         HLT
df2a  86         ADD M
df2b  02         STAX BC
df2c  00         NOP
df2d  06 f2      MVI B, f2
df2f  01 46 ea   LXI BC, ea46
df32  83         ADD E
df33  c6 e2      ADI A, e2
df35  d0         RNC
df36  06 ca      MVI B, ca
df38  20         db 20
df39  46         MOV B, M
df3a  3a 26 09   LDA 0926
df3d  0a         LDAX BC
df3e  43         MOV B, E
df3f  06 2a      MVI B, 2a
df41  c2 4a 01   JNZ 014a
df44  b2         ORA D
df45  45         MOV B, L
df46  06 7d      MVI B, 7d
df48  83         ADD E
df49  40         MOV B, B
df4a  7d         MOV A, L
df4b  00         NOP
df4c  00         NOP
df4d  90         SUB B
df4e  41         MOV B, C
df4f  b0         ORA B
df50  92         SUB D
df51  44         MOV B, H
df52  f6 ad      ORI A, ad
df54  04         INR B
df55  d3 91      OUT 91
df57  cc 00 1a   CZ 1a00
df5a  00         NOP
df5b  e9         PCHL
df5c  7c         MOV A, H
df5d  08         db 08
df5e  c1         POP BC
df5f  ac         XRA H
df60  c8         RZ
df61  c5         PUSH BC
df62  0b         DCX BC
df63  00         NOP
df64  17         RAL
df65  0c         INR C
df66  80         ADD B
df67  1f         RAR
df68  60         MOV H, B
df69  c0         RNZ
df6a  07         RLC
df6b  90         SUB B
df6c  c0         RNZ
df6d  0f         RRC
df6e  2d         DCR L
df6f  00         NOP
df70  c9         RET
df71  18         db 18
df72  00         NOP
df73  d8         RC
df74  70         MOV M, B
df75  c0         RNZ
df76  d0         RNC
df77  d0         RNC
df78  00         NOP
df79  c8         RZ
df7a  76         HLT
df7b  80         ADD B
df7c  c0         RNZ
df7d  80         ADD B
df7e  00         NOP
df7f  f0         RP
df80  68         MOV L, B
df81  00         NOP
df82  f8         RM
df83  81         ADD C
df84  40         MOV B, B
df85  e8         RPE
df86  83         ADD E
df87  c0         RNZ
df88  e0         RPO
df89  9d         SBB L
df8a  0b         DCX BC
df8b  c7         RST 0
df8c  10         db 10
df8d  81         ADD C
df8e  98         SBB B
df8f  12         STAX DE
df90  44         MOV B, H
df91  de 43      SBI A, 43
df93  06 22      MVI B, 22
df95  82         ADD D
df96  00         NOP
df97  f9         SPHL
df98  a0         ANA B
df99  46         MOV B, M
df9a  32 a6 09   STA 09a6
df9d  02         STAX BC
df9e  a0         ANA B
df9f  c0         RNZ
dfa0  37         STC
dfa1  a8         XRA B
dfa2  81         ADD C
dfa3  90         SUB B
dfa4  aa         XRA D
dfa5  44         MOV B, H
dfa6  d6 1a      SUI A, 1a
dfa8  00         NOP
dfa9  eb         XCHG
dfaa  90         SUB B
dfab  41         MOV B, C
dfac  a8         XRA B
dfad  92         SUB D
dfae  44         MOV B, H
dfaf  ee a2      XRI A, a2
dfb1  00         NOP
dfb2  e3         XTHL
????:
dfb3  0a         LDAX BC
dfb4  45         MOV B, L
dfb5  52         MOV D, D
dfb6  52         MOV D, D
dfb7  4f         MOV C, A
dfb8  52         MOV D, D
dfb9  53         MOV D, E
dfba  20         db 20
dfbb  44         MOV B, H
dfbc  45         MOV B, L
dfbd  54         MOV D, H
dfbe  45         MOV B, L
dfbf  43         MOV B, E
dfc0  54         MOV D, H
dfc1  45         MOV B, L
dfc2  44         MOV B, H
dfc3  3a 00 0a   LDA 0a00
dfc6  41         MOV B, C
dfc7  53         MOV D, E
dfc8  53         MOV D, E
????:
dfc9  4d         MOV C, L
dfca  2e 2a      MVI L, 2a
dfcc  6d         MOV L, L
dfcd  69         MOV L, C
dfce  6b         MOV L, E
dfcf  72         MOV M, D
dfd0  6f         MOV L, A
dfd1  6e         MOV L, M
dfd2  2a 0a 2a   LHLD 2a0a
dfd5  00         NOP
????:
dfd6  50         MOV D, B
dfd7  4c         MOV C, H
dfd8  45         MOV B, L
dfd9  41         MOV B, C
dfda  53         MOV D, E
dfdb  45         MOV B, L
dfdc  20         db 20
dfdd  31 2c 32   LXI SP, 322c
dfe0  2c         INR L
dfe1  33         INX SP
dfe2  2c         INR L
dfe3  43         MOV B, E
dfe4  54         MOV D, H
dfe5  52         MOV D, D
dfe6  4c         MOV C, H
dfe7  22 43 22   SHLD 2243
dfea  00         NOP
????:
dfeb  54         MOV D, H
dfec  4f         MOV C, A
dfed  4f         MOV C, A
dfee  20         db 20
dfef  4c         MOV C, H
dff0  4f         MOV C, A
dff1  4e         MOV C, M
dff2  47         MOV B, A
dff3  00         NOP
dff4  00         NOP
dff5  00         NOP
dff6  00         NOP
dff7  00         NOP
dff8  00         NOP
dff9  00         NOP
dffa  00         NOP
dffb  00         NOP
dffc  00         NOP
dffd  00         NOP
dffe  00         NOP
dfff  00         NOP



START:
    0000  c3 a9 09   JMP 09a9

????:
0003  20         db 20
0004  11 08 08   LXI DE, 0808
0007  1a         LDAX DE
0008  00         NOP
????:
0009  06 20      MVI B, 20
????:
000b  08         db 08
000c  08         db 08
000d  1a         LDAX DE
000e  00         NOP
????:
000f  1b         DCX DE
0010  59         MOV E, C
????:
0011  34         INR M
0012  22 00 08   SHLD 0800
0015  19         DAD DE
0016  00         NOP
????:
0017  1a         LDAX DE
0018  08         db 08
0019  00         NOP
????:
001a  08         db 08
001b  08         db 08
????:
001c  00         NOP
????:
001d  1b         DCX DE
????:
001e  59         MOV E, C
001f  37         STC
????:
0020  23         INX HL
0021  73         MOV M, E
0022  7e         MOV A, M
0023  65         MOV H, L
0024  74         MOV M, H
0025  3a 20 30   LDA 3020
0028  30         db 30
0029  30         db 30
002a  30         db 30
002b  30         db 30
002c  30         db 30
002d  30         db 30
002e  30         db 30
002f  1b         DCX DE
0030  59         MOV E, C
0031  37         STC
0032  3a 6c 60   LDA 606c
0035  64         MOV H, H
0036  65         MOV H, L
0037  6a         MOV L, D
0038  3a 1b 59   LDA 591b
003b  37         STC
003c  4b         MOV C, E
003d  75         MOV M, L
003e  72         MOV M, D
003f  6f         MOV L, A
0040  77         MOV M, A
0041  65         MOV H, L
0042  6e         MOV L, M
0043  78         MOV A, B
0044  3a 00 1b   LDA 1b00
0047  59         MOV E, C
0048  37         STC
0049  29         DAD HL
004a  00         NOP
????:
004b  1b         DCX DE
004c  59         MOV E, C
004d  37         STC
004e  41         MOV B, C
004f  00         NOP
????:
0050  1b         DCX DE
0051  59         MOV E, C
0052  37         STC
0053  54         MOV D, H
0054  00         NOP
????:
0055  0e 1f      MVI C, 1f
0057  cd 09 f8   CALL f809
005a  06 3e      MVI B, 3e
005c  0e 03      MVI C, 03
????:
005e  cd 09 f8   CALL f809
0061  05         DCR B
0062  c2 5e 00   JNZ 005e
0065  06 16      MVI B, 16
????:
0067  21 09 00   LXI HL, 0009
006a  cd 18 f8   CALL f818
006d  05         DCR B
006e  c2 67 00   JNZ 0067
0071  0e 0c      MVI C, 0c
0073  cd 09 f8   CALL f809
0076  06 15      MVI B, 15
????:
0078  21 03 00   LXI HL, 0003
007b  cd 18 f8   CALL f818
007e  05         DCR B
007f  c2 78 00   JNZ 0078
0082  0e 20      MVI C, 20
0084  cd 09 f8   CALL f809
0087  0e 11      MVI C, 11
0089  cd 09 f8   CALL f809
008c  06 3c      MVI B, 3c
008e  0e 14      MVI C, 14
????:
0090  cd 09 f8   CALL f809
0093  05         DCR B
0094  c2 90 00   JNZ 0090
0097  21 1d 00   LXI HL, 001d
009a  cd 18 f8   CALL f818
009d  c9         RET
????:
009e  fe 00      CPI A, 00
00a0  ca f1 00   JZ 00f1
00a3  fe 01      CPI A, 01
00a5  ca ec 00   JZ 00ec
00a8  fe 02      CPI A, 02
00aa  ca e7 00   JZ 00e7
00ad  fe 03      CPI A, 03
00af  ca e2 00   JZ 00e2
00b2  fe 04      CPI A, 04
00b4  ca dd 00   JZ 00dd
00b7  fe 05      CPI A, 05
00b9  ca dd 00   JZ 00dd
00bc  fe 06      CPI A, 06
00be  ca d8 00   JZ 00d8
00c1  fe 07      CPI A, 07
00c3  ca d3 00   JZ 00d3
00c6  fe 0a      CPI A, 0a
00c8  ca f1 00   JZ 00f1
00cb  fe 09      CPI A, 09
00cd  c0         RNZ
00ce  0e 5e      MVI C, 5e
00d0  c3 f3 00   JMP 00f3
????:
00d3  0e 09      MVI C, 09
00d5  c3 f3 00   JMP 00f3
????:
00d8  0e 76      MVI C, 76
00da  c3 f3 00   JMP 00f3
????:
00dd  0e 70      MVI C, 70
00df  c3 f3 00   JMP 00f3
????:
00e2  0e 17      MVI C, 17
00e4  c3 f3 00   JMP 00f3
????:
00e7  0e 1e      MVI C, 1e
00e9  c3 f3 00   JMP 00f3
????:
00ec  0e 23      MVI C, 23
00ee  c3 f3 00   JMP 00f3
????:
00f1  0e 20      MVI C, 20
????:
00f3  cd 09 f8   CALL f809
00f6  c9         RET
????:
00f7  eb         XCHG
00f8  06 14      MVI B, 14
00fa  3e 21      MVI A, 21
00fc  32 11 00   STA 0011
????:
00ff  21 0f 00   LXI HL, 000f
0102  cd 18 f8   CALL f818
0105  eb         XCHG
0106  16 1e      MVI D, 1e
????:
0108  7e         MOV A, M
0109  e6 f0      ANI A, f0
010b  0f         RRC
010c  0f         RRC
010d  0f         RRC
010e  0f         RRC
010f  cd 9e 00   CALL 009e
0112  7e         MOV A, M
0113  e6 0f      ANI A, 0f
0115  cd 9e 00   CALL 009e
0118  23         INX HL
0119  15         DCR D
011a  c2 08 01   JNZ 0108
011d  05         DCR B
011e  c8         RZ
011f  eb         XCHG
0120  21 11 00   LXI HL, 0011
0123  34         INR M
0124  c3 ff 00   JMP 00ff
0127  c9         RET
????:
0128  21 00 00   LXI HL, 0000
012b  22 89 04   SHLD 0489
012e  97         SUB A
012f  32 09 05   STA 0509
0132  2a 5a 05   LHLD 055a
0135  16 21      MVI D, 21
????:
0137  1e 22      MVI E, 22
????:
0139  7e         MOV A, M
013a  e6 f0      ANI A, f0
013c  0f         RRC
013d  0f         RRC
013e  0f         RRC
013f  0f         RRC
0140  cd 5e 01   CALL 015e
0143  1c         INR E
0144  7e         MOV A, M
0145  e6 0f      ANI A, 0f
0147  cd 5e 01   CALL 015e
014a  23         INX HL
014b  1c         INR E
014c  3e 5e      MVI A, 5e
014e  bb         CMP E
014f  c2 39 01   JNZ 0139
0152  14         INR D
0153  3e 35      MVI A, 35
0155  ba         CMP D
0156  c2 37 01   JNZ 0137
0159  21 09 05   LXI HL, 0509
015c  34         INR M
015d  c9         RET
????:
015e  e5         PUSH HL
015f  d5         PUSH DE
0160  c5         PUSH BC
0161  fe 02      CPI A, 02
0163  ca 7e 01   JZ 017e
0166  fe 06      CPI A, 06
0168  ca 88 01   JZ 0188
016b  fe 07      CPI A, 07
016d  c2 a9 01   JNZ 01a9
0170  22 0f 05   SHLD 050f
0173  7a         MOV A, D
0174  32 0c 05   STA 050c
0177  7b         MOV A, E
0178  32 0d 05   STA 050d
017b  c3 a9 01   JMP 01a9
????:
017e  2a 89 04   LHLD 0489
0181  23         INX HL
0182  22 89 04   SHLD 0489
0185  c3 a9 01   JMP 01a9
????:
0188  3a 09 05   LDA 0509
018b  fe 05      CPI A, 05
018d  d2 a9 01   JNC 01a9
0190  3c         INR A
0191  32 09 05   STA 0509
0194  e5         PUSH HL
0195  21 0c 05   LXI HL, 050c
0198  01 0b 00   LXI BC, 000b
????:
019b  09         DAD BC
019c  3d         DCR A
019d  c2 9b 01   JNZ 019b
01a0  72         MOV M, D
01a1  23         INX HL
01a2  73         MOV M, E
01a3  23         INX HL
01a4  23         INX HL
01a5  d1         POP DE
01a6  73         MOV M, E
01a7  23         INX HL
01a8  72         MOV M, D
????:
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
01cd  21 0a 05   LXI HL, 050a
01d0  3a 09 05   LDA 0509
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
021a  cd 18 f8   CALL f818
021d  0e 1a      MVI C, 1a
021f  cd 09 f8   CALL f809
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
0269  21 1c 00   LXI HL, 001c
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
028b  21 1a 00   LXI HL, 001a
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
02b7  21 17 00   LXI HL, 0017
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
02e0  21 14 00   LXI HL, 0014
02e3  22 8c 04   SHLD 048c
02e6  3e ff      MVI A, ff
02e8  32 90 04   STA 0490
02eb  11 e2 ff   LXI DE, ffe2
02ee  c3 06 03   JMP 0306
????:
02f1  06 19      MVI B, 19
02f3  3e 1a      MVI A, 1a
02f5  32 8b 04   STA 048b
02f8  21 17 00   LXI HL, 0017
02fb  22 8c 04   SHLD 048c
02fe  3e 01      MVI A, 01
0300  32 90 04   STA 0490
0303  11 1e 00   LXI DE, 001e
????:
0306  21 4e 05   LXI HL, 054e
0309  22 8e 04   SHLD 048e
????:
030c  21 4c 05   LXI HL, 054c
030f  cd 18 f8   CALL f818
0312  3a 8b 04   LDA 048b
0315  4f         MOV C, A
0316  cd 09 f8   CALL f809
0319  cd ad 01   CALL 01ad
031c  c2 90 03   JNZ 0390
????:
031f  21 55 05   LXI HL, 0555
0322  48         MOV C, B
0323  cd 09 f8   CALL f809
0326  4e         MOV C, M
0327  cd 09 f8   CALL f809
032a  32 55 05   STA 0555
032d  2a 8c 04   LHLD 048c
0330  cd 18 f8   CALL f818
0333  0e 09      MVI C, 09
0335  cd 09 f8   CALL f809
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
034f  21 0c 05   LXI HL, 050c
0352  11 13 05   LXI DE, 0513
0355  01 0b 00   LXI BC, 000b
0358  3a 09 05   LDA 0509
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
03b3  2a 89 04   LHLD 0489
03b6  2b         DCX HL
03b7  22 89 04   SHLD 0489
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
03d0  cd 18 f8   CALL f818
03d3  06 04      MVI B, 04
03d5  21 85 04   LXI HL, 0485
????:
03d8  7e         MOV A, M
03d9  cd 15 f8   CALL f815
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
03fc  cd 09 f8   CALL f809
03ff  0e 59      MVI C, 59
0401  cd 09 f8   CALL f809
0404  4e         MOV C, M
0405  cd 09 f8   CALL f809
0408  23         INX HL
0409  4e         MOV C, M
040a  cd 09 f8   CALL f809
040d  0e 70      MVI C, 70
040f  cd 09 f8   CALL f809
????:
0412  3a 14 05   LDA 0514
0415  fe 1f      CPI A, 1f
0417  c2 25 04   JNZ 0425
041a  21 0a 05   LXI HL, 050a
041d  cd 18 f8   CALL f818
0420  0e 18      MVI C, 18
0422  c3 30 04   JMP 0430
????:
0425  fe 0c      CPI A, 0c
0427  c0         RNZ
0428  21 0a 05   LXI HL, 050a
042b  cd 18 f8   CALL f818
042e  0e 08      MVI C, 08
????:
0430  cd 09 f8   CALL f809
0433  cd 21 f8   CALL f821
0436  fe 20      CPI A, 20
0438  ca 3e 04   JZ 043e
043b  fe 5e      CPI A, 5e
043d  c0         RNZ
????:
043e  0e 1a      MVI C, 1a
0440  cd 09 f8   CALL f809
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
047c  cd 09 f8   CALL f809
047f  3e 00      MVI A, 00
0481  32 14 05   STA 0514
0484  c9         RET
????:
0485  00         NOP
0486  02         STAX BC
????:
0487  80         ADD B
0488  00         NOP
????:
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
????:
0509  03         INX BC
????:
050a  1b         DCX DE
050b  59         MOV E, C
????:
050c  33         INX SP
????:
050d  51         MOV D, C
050e  00         NOP
????:
050f  4b         MOV C, E
0510  0d         DCR C
0511  ff         RST 7
????:
0512  00         NOP
????:
0513  23         INX HL
????:
0514  08         db 08
????:
0515  1b         DCX DE
0516  59         MOV E, C
????:
0517  33         INX SP
0518  51         MOV D, C
0519  00         NOP
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
????:
055a  18         db 18
055b  0b         DCX BC
????:
055c  1f         RAR
055d  1b         DCX DE
055e  59         MOV E, C
055f  27         DAA
0560  34         INR M
0561  17         RAL
0562  20         db 20
0563  20         db 20
0564  20         db 20
0565  20         db 20
0566  20         db 20
0567  20         db 20
0568  17         RAL
0569  17         RAL
056a  17         RAL
056b  20         db 20
056c  20         db 20
056d  17         RAL
056e  17         RAL
056f  17         RAL
0570  17         RAL
0571  20         db 20
0572  20         db 20
0573  17         RAL
0574  17         RAL
0575  17         RAL
0576  17         RAL
0577  17         RAL
0578  1b         DCX DE
0579  59         MOV E, C
057a  28         db 28
057b  34         INR M
057c  17         RAL
057d  20         db 20
057e  20         db 20
057f  20         db 20
0580  20         db 20
0581  20         db 20
0582  17         RAL
0583  20         db 20
0584  20         db 20
0585  20         db 20
0586  17         RAL
0587  20         db 20
0588  17         RAL
0589  20         db 20
058a  20         db 20
058b  20         db 20
058c  17         RAL
058d  20         db 20
058e  17         RAL
058f  1b         DCX DE
0590  59         MOV E, C
0591  29         DAD HL
0592  34         INR M
0593  17         RAL
0594  20         db 20
0595  20         db 20
0596  20         db 20
0597  20         db 20
0598  20         db 20
0599  17         RAL
059a  20         db 20
059b  20         db 20
059c  20         db 20
059d  17         RAL
059e  20         db 20
059f  17         RAL
05a0  20         db 20
05a1  20         db 20
05a2  20         db 20
05a3  17         RAL
05a4  20         db 20
05a5  17         RAL
05a6  17         RAL
05a7  17         RAL
05a8  17         RAL
05a9  1b         DCX DE
05aa  59         MOV E, C
05ab  2a 34 17   LHLD 1734
05ae  20         db 20
05af  20         db 20
05b0  20         db 20
05b1  20         db 20
05b2  20         db 20
05b3  17         RAL
05b4  20         db 20
05b5  20         db 20
05b6  20         db 20
05b7  17         RAL
05b8  20         db 20
05b9  17         RAL
05ba  20         db 20
05bb  20         db 20
05bc  20         db 20
05bd  17         RAL
05be  20         db 20
05bf  17         RAL
05c0  1b         DCX DE
05c1  59         MOV E, C
05c2  2b         DCX HL
05c3  34         INR M
05c4  17         RAL
05c5  17         RAL
05c6  17         RAL
05c7  17         RAL
05c8  17         RAL
05c9  20         db 20
05ca  20         db 20
05cb  17         RAL
05cc  17         RAL
05cd  17         RAL
05ce  20         db 20
05cf  20         db 20
05d0  17         RAL
05d1  17         RAL
05d2  17         RAL
05d3  17         RAL
05d4  20         db 20
05d5  20         db 20
05d6  17         RAL
05d7  17         RAL
05d8  17         RAL
05d9  17         RAL
05da  17         RAL
05db  1b         DCX DE
05dc  59         MOV E, C
05dd  2f         CMA
05de  2e 17      MVI L, 17
05e0  17         RAL
05e1  17         RAL
05e2  17         RAL
05e3  20         db 20
05e4  20         db 20
05e5  17         RAL
05e6  20         db 20
05e7  20         db 20
05e8  20         db 20
05e9  17         RAL
05ea  20         db 20
05eb  17         RAL
05ec  20         db 20
05ed  20         db 20
05ee  20         db 20
05ef  17         RAL
05f0  20         db 20
05f1  17         RAL
05f2  20         db 20
05f3  20         db 20
05f4  20         db 20
05f5  17         RAL
05f6  20         db 20
05f7  17         RAL
05f8  17         RAL
05f9  17         RAL
05fa  17         RAL
05fb  17         RAL
05fc  20         db 20
05fd  17         RAL
05fe  17         RAL
05ff  17         RAL
0600  17         RAL
0601  1b         DCX DE
0602  59         MOV E, C
0603  30         db 30
0604  2e 17      MVI L, 17
0606  20         db 20
0607  20         db 20
0608  20         db 20
0609  17         RAL
060a  20         db 20
060b  17         RAL
060c  20         db 20
060d  20         db 20
060e  20         db 20
060f  17         RAL
0610  20         db 20
0611  17         RAL
0612  17         RAL
0613  20         db 20
0614  20         db 20
0615  17         RAL
0616  20         db 20
0617  17         RAL
0618  17         RAL
0619  20         db 20
061a  20         db 20
061b  17         RAL
061c  20         db 20
061d  17         RAL
061e  20         db 20
061f  20         db 20
0620  20         db 20
0621  20         db 20
0622  20         db 20
0623  17         RAL
0624  20         db 20
0625  20         db 20
0626  20         db 20
0627  17         RAL
0628  1b         DCX DE
0629  59         MOV E, C
062a  31 2e 17   LXI SP, 172e
062d  17         RAL
062e  17         RAL
062f  17         RAL
0630  20         db 20
0631  20         db 20
0632  17         RAL
0633  20         db 20
0634  20         db 20
0635  20         db 20
0636  17         RAL
0637  20         db 20
0638  17         RAL
0639  20         db 20
063a  17         RAL
063b  20         db 20
063c  17         RAL
063d  20         db 20
063e  17         RAL
063f  20         db 20
0640  17         RAL
0641  20         db 20
0642  17         RAL
0643  20         db 20
0644  17         RAL
0645  17         RAL
0646  17         RAL
0647  17         RAL
0648  20         db 20
0649  20         db 20
064a  17         RAL
064b  17         RAL
064c  17         RAL
064d  17         RAL
064e  1b         DCX DE
064f  59         MOV E, C
0650  32 2e 17   STA 172e
0653  20         db 20
0654  17         RAL
0655  20         db 20
0656  20         db 20
0657  20         db 20
0658  17         RAL
0659  20         db 20
065a  20         db 20
065b  20         db 20
065c  17         RAL
065d  20         db 20
065e  17         RAL
065f  20         db 20
0660  20         db 20
0661  17         RAL
0662  17         RAL
0663  20         db 20
0664  17         RAL
0665  20         db 20
0666  20         db 20
0667  17         RAL
0668  17         RAL
0669  20         db 20
066a  17         RAL
066b  20         db 20
066c  20         db 20
066d  20         db 20
066e  20         db 20
066f  20         db 20
0670  17         RAL
0671  20         db 20
0672  17         RAL
0673  1b         DCX DE
0674  59         MOV E, C
0675  33         INX SP
0676  2e 17      MVI L, 17
0678  20         db 20
0679  20         db 20
067a  17         RAL
067b  20         db 20
067c  20         db 20
067d  20         db 20
067e  17         RAL
067f  17         RAL
0680  17         RAL
0681  20         db 20
0682  20         db 20
0683  17         RAL
0684  20         db 20
0685  20         db 20
0686  20         db 20
0687  17         RAL
0688  20         db 20
0689  17         RAL
068a  20         db 20
068b  20         db 20
068c  20         db 20
068d  17         RAL
068e  20         db 20
068f  17         RAL
0690  17         RAL
0691  17         RAL
0692  17         RAL
0693  17         RAL
0694  20         db 20
0695  17         RAL
0696  20         db 20
0697  20         db 20
0698  17         RAL
0699  00         NOP
????:
069a  1f         RAR
069b  1b         DCX DE
069c  59         MOV E, C
069d  2b         DCX HL
069e  34         INR M
069f  17         RAL
06a0  17         RAL
06a1  17         RAL
06a2  17         RAL
06a3  17         RAL
06a4  20         db 20
06a5  17         RAL
06a6  20         db 20
06a7  20         db 20
06a8  20         db 20
06a9  17         RAL
06aa  20         db 20
06ab  20         db 20
06ac  20         db 20
06ad  17         RAL
06ae  20         db 20
06af  20         db 20
06b0  20         db 20
06b1  17         RAL
06b2  17         RAL
06b3  17         RAL
06b4  17         RAL
06b5  17         RAL
06b6  1b         DCX DE
06b7  59         MOV E, C
06b8  2c         INR L
06b9  34         INR M
06ba  17         RAL
06bb  20         db 20
06bc  20         db 20
06bd  20         db 20
06be  20         db 20
06bf  20         db 20
06c0  20         db 20
06c1  17         RAL
06c2  20         db 20
06c3  17         RAL
06c4  20         db 20
06c5  20         db 20
06c6  20         db 20
06c7  20         db 20
06c8  17         RAL
06c9  20         db 20
06ca  20         db 20
06cb  20         db 20
06cc  20         db 20
06cd  20         db 20
06ce  17         RAL
06cf  1b         DCX DE
06d0  59         MOV E, C
06d1  2d         DCR L
06d2  34         INR M
06d3  17         RAL
06d4  17         RAL
06d5  17         RAL
06d6  17         RAL
06d7  20         db 20
06d8  20         db 20
06d9  20         db 20
06da  20         db 20
06db  17         RAL
06dc  20         db 20
06dd  20         db 20
06de  20         db 20
06df  20         db 20
06e0  20         db 20
06e1  17         RAL
06e2  20         db 20
06e3  20         db 20
06e4  20         db 20
06e5  20         db 20
06e6  20         db 20
06e7  17         RAL
06e8  1b         DCX DE
06e9  59         MOV E, C
06ea  2e 34      MVI L, 34
06ec  17         RAL
06ed  20         db 20
06ee  20         db 20
06ef  20         db 20
06f0  20         db 20
06f1  20         db 20
06f2  20         db 20
06f3  17         RAL
06f4  20         db 20
06f5  17         RAL
06f6  20         db 20
06f7  20         db 20
06f8  20         db 20
06f9  20         db 20
06fa  17         RAL
06fb  20         db 20
06fc  20         db 20
06fd  20         db 20
06fe  20         db 20
06ff  20         db 20
????:
0700  17         RAL
0701  1b         DCX DE
0702  59         MOV E, C
0703  2f         CMA
0704  34         INR M
0705  17         RAL
0706  17         RAL
0707  17         RAL
0708  17         RAL
0709  17         RAL
070a  20         db 20
070b  17         RAL
070c  20         db 20
070d  20         db 20
070e  20         db 20
070f  17         RAL
0710  20         db 20
0711  20         db 20
0712  20         db 20
0713  17         RAL
0714  20         db 20
0715  20         db 20
0716  20         db 20
0717  20         db 20
0718  20         db 20
0719  17         RAL
071a  00         NOP
????:
071b  21 15 05   LXI HL, 0515
071e  3a 09 05   LDA 0509
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
0780  3a 0c 05   LDA 050c
0783  21 4e 05   LXI HL, 054e
0786  be         CMP M
0787  ca b0 07   JZ 07b0
078a  fa a3 07   JM 07a3
078d  21 4c 05   LXI HL, 054c
0790  cd 18 f8   CALL f818
0793  0e 1a      MVI C, 1a
0795  cd 09 f8   CALL f809
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
07b0  3a 0d 05   LDA 050d
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
07ca  3a 0c 05   LDA 050c
07cd  21 4e 05   LXI HL, 054e
07d0  be         CMP M
07d1  fa 09 08   JM 0809
07d4  21 4c 05   LXI HL, 054c
07d7  cd 18 f8   CALL f818
07da  0e 1a      MVI C, 1a
07dc  cd 09 f8   CALL f809
07df  1e 00      MVI E, 00
????:
07e1  0e 08      MVI C, 08
07e3  cd 09 f8   CALL f809
07e6  1c         INR E
07e7  cd b5 01   CALL 01b5
07ea  c2 e1 07   JNZ 07e1
07ed  21 4c 05   LXI HL, 054c
07f0  cd 18 f8   CALL f818
07f3  0e 1a      MVI C, 1a
07f5  cd 09 f8   CALL f809
07f8  16 00      MVI D, 00
????:
07fa  0e 18      MVI C, 18
07fc  cd 09 f8   CALL f809
07ff  14         INR D
????:
0800  cd b5 01   CALL 01b5
0803  c2 fa 07   JNZ 07fa
0806  c3 49 08   JMP 0849
????:
0809  21 4c 05   LXI HL, 054c
080c  cd 18 f8   CALL f818
080f  1e 00      MVI E, 00
????:
0811  0e 08      MVI C, 08
0813  cd 09 f8   CALL f809
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
082c  cd 18 f8   CALL f818
082f  16 00      MVI D, 00
????:
0831  0e 18      MVI C, 18
0833  cd 09 f8   CALL f809
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
0870  cd 18 f8   CALL f818
0873  cd 21 f8   CALL f821
0876  fe 70      CPI A, 70
0878  ca bc 08   JZ 08bc
087b  0e 19      MVI C, 19
087d  cd 09 f8   CALL f809
0880  cd b5 01   CALL 01b5
0883  c2 ef 08   JNZ 08ef
0886  21 55 05   LXI HL, 0555
0889  0e 1a      MVI C, 1a
088b  cd 09 f8   CALL f809
088e  4e         MOV C, M
088f  cd 09 f8   CALL f809
0892  32 55 05   STA 0555
0895  0e 08      MVI C, 08
0897  cd 09 f8   CALL f809
089a  0e 19      MVI C, 19
089c  cd 09 f8   CALL f809
089f  0e 09      MVI C, 09
08a1  cd 09 f8   CALL f809
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
08c3  2a 5a 05   LHLD 055a
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
08df  cd 18 f8   CALL f818
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
090d  2a 89 04   LHLD 0489
0910  3e 00      MVI A, 00
0912  bc         CMP H
0913  c0         RNZ
0914  bd         CMP L
0915  c0         RNZ
0916  06 14      MVI B, 14
0918  2a 5a 05   LHLD 055a
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
094b  cd 09 f8   CALL f809
094e  0e 59      MVI C, 59
0950  cd 09 f8   CALL f809
0953  4a         MOV C, D
0954  cd 09 f8   CALL f809
0957  4b         MOV C, E
0958  cd 09 f8   CALL f809
095b  cd 21 f8   CALL f821
095e  fe 09      CPI A, 09
0960  c2 a3 09   JNZ 09a3
0963  e5         PUSH HL
0964  d5         PUSH DE
0965  c5         PUSH BC
0966  eb         XCHG
0967  22 12 0b   SHLD 0b12
096a  21 0c 05   LXI HL, 050c
096d  11 13 05   LXI DE, 0513
0970  01 0b 00   LXI BC, 000b
0973  3a 09 05   LDA 0509
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
09a5  cd 09 f8   CALL f809
09a8  c9         RET

REAL_START:
09a9  21 5c 05   LXI HL, 055c
09ac  cd 18 f8   CALL f818
09af  cd 03 f8   CALL f803
09b2  cd 55 00   CALL 0055
09b5  21 18 0b   LXI HL, 0b18
09b8  22 5a 05   SHLD 055a
09bb  06 04      MVI B, 04
09bd  21 85 04   LXI HL, 0485
????:
09c0  23         INX HL
09c1  36 00      MVI M, 00
09c3  05         DCR B
09c4  c2 c0 09   JNZ 09c0
09c7  3e 03      MVI A, 03
09c9  32 17 0b   STA 0b17
09cc  3e 01      MVI A, 01
09ce  32 11 0b   STA 0b11
????:
09d1  21 4b 00   LXI HL, 004b
09d4  cd 18 f8   CALL f818
09d7  3a 17 0b   LDA 0b17
09da  27         DAA
09db  cd 15 f8   CALL f815
09de  21 50 00   LXI HL, 0050
09e1  cd 18 f8   CALL f818
09e4  3a 11 0b   LDA 0b11
09e7  cd 15 f8   CALL f815
09ea  21 13 05   LXI HL, 0513
09ed  11 0b 00   LXI DE, 000b
09f0  06 06      MVI B, 06
????:
09f2  36 20      MVI M, 20
09f4  19         DAD DE
09f5  05         DCR B
09f6  c2 f2 09   JNZ 09f2
09f9  21 12 05   LXI HL, 0512
09fc  06 06      MVI B, 06
????:
09fe  36 00      MVI M, 00
????:
0a00  19         DAD DE
0a01  05         DCR B
0a02  c2 fe 09   JNZ 09fe
0a05  21 91 04   LXI HL, 0491
0a08  06 78      MVI B, 78
????:
0a0a  36 00      MVI M, 00
0a0c  23         INX HL
0a0d  05         DCR B
0a0e  c2 0a 0a   JNZ 0a0a
0a11  2a 5a 05   LHLD 055a
0a14  cd f7 00   CALL 00f7
0a17  cd 28 01   CALL 0128
0a1a  3e 00      MVI A, 00
0a1c  32 16 0b   STA 0b16
????:
0a1f  cd 03 f8   CALL f803
0a22  fe 4c      CPI A, 4c
0a24  ca 8d 0a   JZ 0a8d
0a27  fe 4d      CPI A, 4d
0a29  c2 40 0a   JNZ 0a40
0a2c  21 4b 00   LXI HL, 004b
0a2f  cd 18 f8   CALL f818
0a32  3a 17 0b   LDA 0b17
0a35  3c         INR A
0a36  32 17 0b   STA 0b17
0a39  27         DAA
0a3a  cd 15 f8   CALL f815
0a3d  c3 1f 0a   JMP 0a1f
????:
0a40  cd 1b f8   CALL f81b
0a43  fe ff      CPI A, ff
0a45  ca 4b 0a   JZ 0a4b
0a48  32 14 05   STA 0514
????:
0a4b  fe 41      CPI A, 41
0a4d  ca e0 0a   JZ 0ae0
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
0a6f  2a 89 04   LHLD 0489
0a72  97         SUB A
0a73  bc         CMP H
0a74  c2 ac 0a   JNZ 0aac
0a77  bd         CMP L
0a78  c2 ac 0a   JNZ 0aac
0a7b  3a 0c 05   LDA 050c
0a7e  fe 21      CPI A, 21
0a80  c2 ac 0a   JNZ 0aac
0a83  e6 00      ANI A, 00
0a85  3a 17 0b   LDA 0b17
0a88  3c         INR A
0a89  32 17 0b   STA 0b17
0a8c  27         DAA
????:
0a8d  3a 11 0b   LDA 0b11
0a90  3c         INR A
0a91  27         DAA
0a92  fe 19      CPI A, 19
0a94  f2 02 0b   JP 0b02
0a97  32 11 0b   STA 0b11
0a9a  2a 5a 05   LHLD 055a
0a9d  11 58 02   LXI DE, 0258
0aa0  19         DAD DE
0aa1  22 5a 05   SHLD 055a
0aa4  0e 07      MVI C, 07
0aa6  cd 09 f8   CALL f809
0aa9  c3 d1 09   JMP 09d1
????:
0aac  21 0a 05   LXI HL, 050a
0aaf  cd 18 f8   CALL f818
0ab2  cd 21 f8   CALL f821
0ab5  fe 70      CPI A, 70
0ab7  ca e0 0a   JZ 0ae0
0aba  21 17 05   LXI HL, 0517
0abd  11 0b 00   LXI DE, 000b
0ac0  3a 09 05   LDA 0509
0ac3  3d         DCR A
0ac4  4f         MOV C, A
????:
0ac5  3a 0c 05   LDA 050c
0ac8  be         CMP M
0ac9  c2 d8 0a   JNZ 0ad8
0acc  23         INX HL
0acd  3a 0d 05   LDA 050d
0ad0  be         CMP M
0ad1  c2 d7 0a   JNZ 0ad7
0ad4  c3 e0 0a   JMP 0ae0
????:
0ad7  2b         DCX HL
????:
0ad8  19         DAD DE
0ad9  0d         DCR C
0ada  c2 c5 0a   JNZ 0ac5
0add  c3 40 0a   JMP 0a40
????:
0ae0  06 00      MVI B, 00
0ae2  3a 17 0b   LDA 0b17
0ae5  3d         DCR A
0ae6  80         ADD B
0ae7  32 17 0b   STA 0b17
0aea  0e 07      MVI C, 07
0aec  cd 09 f8   CALL f809
0aef  0e 07      MVI C, 07
0af1  cd 09 f8   CALL f809
0af4  cd 03 f8   CALL f803
0af7  3a 17 0b   LDA 0b17
0afa  fe 00      CPI A, 00
0afc  ca a9 09   JZ 09a9
0aff  c3 d1 09   JMP 09d1
????:
0b02  21 9a 06   LXI HL, 069a
0b05  cd 18 f8   CALL f818
0b08  cd 1b f8   CALL f81b
0b0b  cd 03 f8   CALL f803
0b0e  c3 d1 09   JMP 09d1
????:
0b11  01 00 00   LXI BC, 0000
0b14  00         NOP
????:
0b15  ce 00      ACI A, 00
????:
0b17  00         NOP
????:
0b18  50         MOV D, B
0b19  00         NOP
0b1a  00         NOP
0b1b  00         NOP
0b1c  00         NOP
0b1d  00         NOP
0b1e  00         NOP
0b1f  00         NOP
0b20  00         NOP
0b21  00         NOP
0b22  00         NOP
0b23  00         NOP
0b24  00         NOP
0b25  00         NOP
0b26  00         NOP
0b27  00         NOP
0b28  00         NOP
0b29  00         NOP
0b2a  00         NOP
0b2b  00         NOP
0b2c  00         NOP
0b2d  00         NOP
0b2e  00         NOP
0b2f  00         NOP
0b30  00         NOP
0b31  00         NOP
0b32  00         NOP
0b33  00         NOP
0b34  0a         LDAX BC
0b35  05         DCR B
0b36  50         MOV D, B
0b37  a0         ANA B
0b38  00         NOP
0b39  00         NOP
0b3a  00         NOP
0b3b  00         NOP
0b3c  00         NOP
0b3d  00         NOP
0b3e  00         NOP
0b3f  00         NOP
0b40  00         NOP
0b41  00         NOP
0b42  00         NOP
0b43  00         NOP
0b44  00         NOP
0b45  00         NOP
0b46  00         NOP
0b47  00         NOP
0b48  00         NOP
0b49  00         NOP
0b4a  00         NOP
0b4b  00         NOP
0b4c  00         NOP
0b4d  00         NOP
0b4e  00         NOP
0b4f  00         NOP
0b50  00         NOP
0b51  00         NOP
0b52  0a         LDAX BC
0b53  05         DCR B
0b54  50         MOV D, B
0b55  a0         ANA B
0b56  00         NOP
0b57  00         NOP
0b58  00         NOP
0b59  00         NOP
0b5a  00         NOP
0b5b  00         NOP
0b5c  00         NOP
0b5d  00         NOP
0b5e  00         NOP
0b5f  00         NOP
0b60  00         NOP
0b61  00         NOP
0b62  00         NOP
0b63  00         NOP
0b64  00         NOP
0b65  00         NOP
0b66  00         NOP
0b67  00         NOP
0b68  00         NOP
0b69  00         NOP
0b6a  00         NOP
0b6b  00         NOP
0b6c  00         NOP
0b6d  00         NOP
0b6e  00         NOP
0b6f  00         NOP
0b70  0a         LDAX BC
0b71  05         DCR B
0b72  50         MOV D, B
0b73  a0         ANA B
0b74  00         NOP
0b75  00         NOP
0b76  00         NOP
0b77  00         NOP
0b78  00         NOP
0b79  20         db 20
0b7a  99         SBB C
0b7b  99         SBB C
0b7c  99         SBB C
0b7d  99         SBB C
0b7e  99         SBB C
0b7f  99         SBB C
0b80  99         SBB C
0b81  99         SBB C
0b82  90         SUB B
0b83  00         NOP
0b84  00         NOP
0b85  00         NOP
0b86  20         db 20
0b87  00         NOP
0b88  00         NOP
0b89  00         NOP
0b8a  02         STAX BC
0b8b  00         NOP
0b8c  00         NOP
0b8d  00         NOP
0b8e  0a         LDAX BC
0b8f  05         DCR B
0b90  50         MOV D, B
0b91  a0         ANA B
0b92  00         NOP
0b93  55         MOV D, L
0b94  55         MOV D, L
0b95  55         MOV D, L
0b96  45         MOV B, L
0b97  55         MOV D, L
0b98  00         NOP
0b99  00         NOP
0b9a  00         NOP
0b9b  00         NOP
0b9c  00         NOP
0b9d  00         NOP
0b9e  00         NOP
0b9f  00         NOP
0ba0  01 55 55   LXI BC, 5555
0ba3  55         MOV D, L
0ba4  55         MOV D, L
0ba5  55         MOV D, L
0ba6  55         MOV D, L
0ba7  55         MOV D, L
0ba8  55         MOV D, L
0ba9  55         MOV D, L
0baa  55         MOV D, L
0bab  55         MOV D, L
0bac  0a         LDAX BC
0bad  05         DCR B
0bae  50         MOV D, B
0baf  a0         ANA B
0bb0  00         NOP
0bb1  00         NOP
0bb2  00         NOP
0bb3  00         NOP
0bb4  00         NOP
0bb5  00         NOP
0bb6  00         NOP
0bb7  00         NOP
0bb8  00         NOP
0bb9  00         NOP
0bba  00         NOP
0bbb  00         NOP
0bbc  00         NOP
0bbd  00         NOP
0bbe  01 00 00   LXI BC, 0000
0bc1  00         NOP
0bc2  00         NOP
0bc3  00         NOP
0bc4  00         NOP
0bc5  00         NOP
0bc6  00         NOP
0bc7  00         NOP
0bc8  00         NOP
0bc9  00         NOP
0bca  0a         LDAX BC
0bcb  05         DCR B
0bcc  50         MOV D, B
0bcd  a0         ANA B
0bce  00         NOP
0bcf  00         NOP
0bd0  00         NOP
0bd1  00         NOP
0bd2  00         NOP
0bd3  00         NOP
0bd4  20         db 20
0bd5  00         NOP
0bd6  00         NOP
0bd7  00         NOP
0bd8  00         NOP
0bd9  00         NOP
0bda  02         STAX BC
0bdb  00         NOP
0bdc  01 00 00   LXI BC, 0000
0bdf  00         NOP
0be0  00         NOP
0be1  00         NOP
0be2  20         db 20
0be3  00         NOP
0be4  06 00      MVI B, 00
0be6  20         db 20
0be7  00         NOP
0be8  0a         LDAX BC
0be9  05         DCR B
0bea  50         MOV D, B
0beb  a0         ANA B
0bec  00         NOP
0bed  00         NOP
0bee  00         NOP
0bef  00         NOP
0bf0  05         DCR B
0bf1  55         MOV D, L
0bf2  55         MOV D, L
0bf3  54         MOV D, H
0bf4  55         MOV D, L
0bf5  55         MOV D, L
0bf6  15         DCR D
0bf7  55         MOV D, L
0bf8  55         MOV D, L
0bf9  55         MOV D, L
0bfa  55         MOV D, L
0bfb  55         MOV D, L
0bfc  55         MOV D, L
0bfd  45         MOV B, L
0bfe  15         DCR D
0bff  55         MOV D, L
0c00  55         MOV D, L
0c01  55         MOV D, L
0c02  55         MOV D, L
0c03  55         MOV D, L
0c04  55         MOV D, L
0c05  55         MOV D, L
0c06  0a         LDAX BC
0c07  05         DCR B
0c08  50         MOV D, B
0c09  a0         ANA B
0c0a  00         NOP
0c0b  00         NOP
0c0c  00         NOP
0c0d  00         NOP
0c0e  00         NOP
0c0f  00         NOP
0c10  00         NOP
0c11  00         NOP
0c12  00         NOP
0c13  00         NOP
0c14  10         db 10
0c15  00         NOP
0c16  00         NOP
0c17  00         NOP
0c18  00         NOP
0c19  00         NOP
0c1a  00         NOP
0c1b  00         NOP
0c1c  10         db 10
0c1d  00         NOP
0c1e  00         NOP
0c1f  00         NOP
0c20  00         NOP
0c21  00         NOP
0c22  00         NOP
0c23  00         NOP
0c24  0a         LDAX BC
0c25  05         DCR B
0c26  50         MOV D, B
0c27  a0         ANA B
0c28  00         NOP
0c29  00         NOP
0c2a  20         db 20
0c2b  00         NOP
0c2c  00         NOP
0c2d  00         NOP
0c2e  00         NOP
0c2f  00         NOP
0c30  00         NOP
0c31  00         NOP
0c32  10         db 10
0c33  00         NOP
0c34  00         NOP
0c35  00         NOP
0c36  00         NOP
0c37  00         NOP
0c38  00         NOP
0c39  00         NOP
0c3a  10         db 10
0c3b  00         NOP
0c3c  20         db 20
0c3d  00         NOP
0c3e  00         NOP
0c3f  00         NOP
0c40  20         db 20
0c41  00         NOP
0c42  0a         LDAX BC
0c43  05         DCR B
0c44  50         MOV D, B
0c45  a0         ANA B
0c46  00         NOP
0c47  55         MOV D, L
0c48  55         MOV D, L
0c49  51         MOV D, C
0c4a  00         NOP
0c4b  00         NOP
0c4c  00         NOP
0c4d  00         NOP
0c4e  55         MOV D, L
0c4f  55         MOV D, L
0c50  55         MOV D, L
0c51  55         MOV D, L
0c52  55         MOV D, L
0c53  51         MOV D, C
0c54  00         NOP
0c55  00         NOP
0c56  00         NOP
0c57  00         NOP
0c58  55         MOV D, L
0c59  55         MOV D, L
0c5a  55         MOV D, L
0c5b  55         MOV D, L
0c5c  15         DCR D
0c5d  55         MOV D, L
0c5e  55         MOV D, L
0c5f  55         MOV D, L
0c60  0a         LDAX BC
0c61  05         DCR B
0c62  50         MOV D, B
0c63  a0         ANA B
0c64  00         NOP
0c65  00         NOP
0c66  00         NOP
0c67  01 00 00   LXI BC, 0000
0c6a  00         NOP
0c6b  00         NOP
0c6c  00         NOP
0c6d  00         NOP
0c6e  00         NOP
0c6f  00         NOP
0c70  00         NOP
0c71  01 00 00   LXI BC, 0000
0c74  00         NOP
0c75  00         NOP
0c76  00         NOP
0c77  00         NOP
0c78  00         NOP
0c79  00         NOP
0c7a  10         db 10
0c7b  00         NOP
0c7c  00         NOP
0c7d  00         NOP
0c7e  0a         LDAX BC
0c7f  05         DCR B
0c80  50         MOV D, B
0c81  a0         ANA B
0c82  00         NOP
0c83  00         NOP
0c84  00         NOP
0c85  01 00 02   LXI BC, 0200
0c88  00         NOP
0c89  00         NOP
0c8a  00         NOP
0c8b  00         NOP
0c8c  00         NOP
0c8d  00         NOP
0c8e  20         db 20
0c8f  01 00 70   LXI BC, 7000
0c92  00         NOP
0c93  00         NOP
0c94  20         db 20
0c95  00         NOP
0c96  00         NOP
0c97  00         NOP
0c98  10         db 10
0c99  00         NOP
0c9a  20         db 20
0c9b  00         NOP
0c9c  0a         LDAX BC
0c9d  05         DCR B
0c9e  50         MOV D, B
0c9f  a0         ANA B
0ca0  00         NOP
0ca1  00         NOP
0ca2  00         NOP
0ca3  05         DCR B
0ca4  55         MOV D, L
0ca5  55         MOV D, L
0ca6  55         MOV D, L
0ca7  00         NOP
0ca8  00         NOP
0ca9  00         NOP
0caa  15         DCR D
0cab  55         MOV D, L
0cac  55         MOV D, L
0cad  55         MOV D, L
0cae  55         MOV D, L
0caf  55         MOV D, L
0cb0  55         MOV D, L
0cb1  55         MOV D, L
0cb2  55         MOV D, L
0cb3  55         MOV D, L
0cb4  55         MOV D, L
0cb5  55         MOV D, L
0cb6  55         MOV D, L
0cb7  55         MOV D, L
0cb8  55         MOV D, L
0cb9  55         MOV D, L
0cba  0a         LDAX BC
0cbb  05         DCR B
0cbc  50         MOV D, B
0cbd  a0         ANA B
0cbe  00         NOP
0cbf  00         NOP
0cc0  00         NOP
0cc1  00         NOP
0cc2  00         NOP
0cc3  00         NOP
0cc4  00         NOP
0cc5  00         NOP
0cc6  00         NOP
0cc7  00         NOP
0cc8  10         db 10
0cc9  00         NOP
0cca  00         NOP
0ccb  00         NOP
0ccc  00         NOP
0ccd  00         NOP
0cce  00         NOP
0ccf  00         NOP
0cd0  00         NOP
0cd1  00         NOP
0cd2  00         NOP
0cd3  00         NOP
0cd4  00         NOP
0cd5  00         NOP
0cd6  00         NOP
0cd7  00         NOP
0cd8  0a         LDAX BC
0cd9  05         DCR B
0cda  50         MOV D, B
0cdb  a0         ANA B
0cdc  00         NOP
0cdd  00         NOP
0cde  00         NOP
0cdf  00         NOP
0ce0  00         NOP
0ce1  60         MOV H, B
0ce2  00         NOP
0ce3  00         NOP
0ce4  00         NOP
0ce5  00         NOP
0ce6  10         db 10
0ce7  00         NOP
0ce8  00         NOP
0ce9  00         NOP
0cea  00         NOP
0ceb  00         NOP
0cec  00         NOP
0ced  00         NOP
0cee  00         NOP
0cef  20         db 20
0cf0  00         NOP
0cf1  00         NOP
0cf2  00         NOP
0cf3  00         NOP
0cf4  20         db 20
0cf5  00         NOP
0cf6  0a         LDAX BC
0cf7  05         DCR B
0cf8  50         MOV D, B
0cf9  a0         ANA B
0cfa  15         DCR D
0cfb  55         MOV D, L
0cfc  55         MOV D, L
0cfd  55         MOV D, L
0cfe  55         MOV D, L
0cff  55         MOV D, L
0d00  55         MOV D, L
0d01  55         MOV D, L
0d02  55         MOV D, L
0d03  55         MOV D, L
0d04  50         MOV D, B
0d05  00         NOP
0d06  00         NOP
0d07  00         NOP
0d08  00         NOP
0d09  00         NOP
0d0a  00         NOP
0d0b  05         DCR B
0d0c  55         MOV D, L
0d0d  55         MOV D, L
0d0e  55         MOV D, L
0d0f  51         MOV D, C
0d10  55         MOV D, L
0d11  55         MOV D, L
0d12  55         MOV D, L
0d13  55         MOV D, L
0d14  0a         LDAX BC
0d15  05         DCR B
0d16  50         MOV D, B
0d17  a0         ANA B
0d18  10         db 10
0d19  00         NOP
0d1a  00         NOP
0d1b  00         NOP
0d1c  00         NOP
0d1d  00         NOP
0d1e  00         NOP
0d1f  00         NOP
0d20  00         NOP
0d21  00         NOP
0d22  00         NOP
0d23  00         NOP
0d24  00         NOP
0d25  00         NOP
0d26  00         NOP
0d27  00         NOP
0d28  00         NOP
0d29  00         NOP
0d2a  00         NOP
0d2b  00         NOP
0d2c  00         NOP
0d2d  01 00 00   LXI BC, 0000
0d30  00         NOP
0d31  00         NOP
0d32  0a         LDAX BC
0d33  05         DCR B
0d34  50         MOV D, B
0d35  a0         ANA B
0d36  10         db 10
0d37  00         NOP
0d38  00         NOP
0d39  00         NOP
0d3a  00         NOP
0d3b  00         NOP
0d3c  00         NOP
0d3d  20         db 20
0d3e  00         NOP
0d3f  00         NOP
0d40  00         NOP
0d41  00         NOP
0d42  00         NOP
0d43  20         db 20
0d44  00         NOP
0d45  00         NOP
0d46  00         NOP
0d47  00         NOP
0d48  20         db 20
0d49  00         NOP
0d4a  00         NOP
0d4b  01 00 00   LXI BC, 0000
0d4e  00         NOP
0d4f  00         NOP
0d50  0a         LDAX BC
0d51  05         DCR B
0d52  55         MOV D, L
0d53  55         MOV D, L
0d54  55         MOV D, L
0d55  55         MOV D, L
0d56  55         MOV D, L
0d57  55         MOV D, L
0d58  55         MOV D, L
0d59  55         MOV D, L
0d5a  55         MOV D, L
0d5b  55         MOV D, L
0d5c  55         MOV D, L
0d5d  55         MOV D, L
0d5e  55         MOV D, L
0d5f  55         MOV D, L
0d60  55         MOV D, L
0d61  55         MOV D, L
0d62  55         MOV D, L
0d63  55         MOV D, L
0d64  55         MOV D, L
0d65  55         MOV D, L
0d66  55         MOV D, L
0d67  55         MOV D, L
0d68  55         MOV D, L
0d69  55         MOV D, L
0d6a  55         MOV D, L
0d6b  55         MOV D, L
0d6c  55         MOV D, L
0d6d  55         MOV D, L
0d6e  55         MOV D, L
0d6f  55         MOV D, L
0d70  50         MOV D, B
0d71  00         NOP
0d72  00         NOP
0d73  00         NOP
0d74  00         NOP
0d75  00         NOP
0d76  00         NOP
0d77  00         NOP
0d78  00         NOP
0d79  00         NOP
0d7a  00         NOP
0d7b  00         NOP
0d7c  00         NOP
0d7d  00         NOP
0d7e  00         NOP
0d7f  00         NOP
0d80  00         NOP
0d81  00         NOP
0d82  00         NOP
0d83  00         NOP
0d84  00         NOP
0d85  00         NOP
0d86  00         NOP
0d87  00         NOP
0d88  00         NOP
0d89  00         NOP
0d8a  00         NOP
0d8b  00         NOP
0d8c  00         NOP
0d8d  05         DCR B
0d8e  50         MOV D, B
0d8f  00         NOP
0d90  55         MOV D, L
0d91  55         MOV D, L
0d92  55         MOV D, L
0d93  55         MOV D, L
0d94  55         MOV D, L
0d95  55         MOV D, L
0d96  55         MOV D, L
0d97  55         MOV D, L
0d98  55         MOV D, L
0d99  55         MOV D, L
0d9a  55         MOV D, L
0d9b  51         MOV D, C
0d9c  55         MOV D, L
0d9d  55         MOV D, L
0d9e  55         MOV D, L
0d9f  55         MOV D, L
0da0  55         MOV D, L
0da1  55         MOV D, L
0da2  45         MOV B, L
0da3  55         MOV D, L
0da4  55         MOV D, L
0da5  55         MOV D, L
0da6  55         MOV D, L
0da7  55         MOV D, L
0da8  55         MOV D, L
0da9  55         MOV D, L
0daa  55         MOV D, L
0dab  15         DCR D
0dac  50         MOV D, B
0dad  00         NOP
0dae  00         NOP
0daf  00         NOP
0db0  00         NOP
0db1  00         NOP
0db2  00         NOP
0db3  00         NOP
0db4  00         NOP
0db5  00         NOP
0db6  00         NOP
0db7  00         NOP
0db8  00         NOP
0db9  01 00 00   LXI BC, 0000
0dbc  00         NOP
0dbd  00         NOP
0dbe  00         NOP
0dbf  00         NOP
0dc0  00         NOP
0dc1  00         NOP
0dc2  00         NOP
0dc3  00         NOP
0dc4  00         NOP
0dc5  00         NOP
0dc6  00         NOP
0dc7  00         NOP
0dc8  00         NOP
0dc9  15         DCR D
0dca  50         MOV D, B
0dcb  00         NOP
0dcc  55         MOV D, L
0dcd  55         MOV D, L
0dce  55         MOV D, L
0dcf  55         MOV D, L
0dd0  55         MOV D, L
0dd1  55         MOV D, L
0dd2  55         MOV D, L
0dd3  45         MOV B, L
0dd4  55         MOV D, L
0dd5  55         MOV D, L
0dd6  55         MOV D, L
0dd7  55         MOV D, L
0dd8  55         MOV D, L
0dd9  55         MOV D, L
0dda  55         MOV D, L
0ddb  55         MOV D, L
0ddc  51         MOV D, C
0ddd  55         MOV D, L
0dde  55         MOV D, L
0ddf  55         MOV D, L
0de0  55         MOV D, L
0de1  55         MOV D, L
0de2  55         MOV D, L
0de3  55         MOV D, L
0de4  55         MOV D, L
0de5  55         MOV D, L
0de6  55         MOV D, L
0de7  15         DCR D
0de8  50         MOV D, B
0de9  00         NOP
0dea  50         MOV D, B
0deb  00         NOP
0dec  00         NOP
0ded  00         NOP
0dee  00         NOP
0def  00         NOP
0df0  52         MOV D, D
0df1  00         NOP
0df2  00         NOP
0df3  00         NOP
0df4  00         NOP
0df5  06 00      MVI B, 00
0df7  00         NOP
0df8  00         NOP
0df9  00         NOP
0dfa  51         MOV D, C
0dfb  00         NOP
0dfc  00         NOP
0dfd  00         NOP
0dfe  00         NOP
0dff  00         NOP
0e00  00         NOP
0e01  00         NOP
0e02  00         NOP
0e03  00         NOP
0e04  05         DCR B
0e05  15         DCR D
0e06  50         MOV D, B
0e07  00         NOP
0e08  50         MOV D, B
0e09  05         DCR B
0e0a  55         MOV D, L
0e0b  55         MOV D, L
0e0c  55         MOV D, L
0e0d  51         MOV D, C
0e0e  55         MOV D, L
0e0f  45         MOV B, L
0e10  55         MOV D, L
0e11  55         MOV D, L
0e12  55         MOV D, L
0e13  55         MOV D, L
0e14  55         MOV D, L
0e15  51         MOV D, C
0e16  55         MOV D, L
0e17  55         MOV D, L
0e18  51         MOV D, C
0e19  55         MOV D, L
0e1a  55         MOV D, L
0e1b  55         MOV D, L
0e1c  55         MOV D, L
0e1d  55         MOV D, L
0e1e  55         MOV D, L
0e1f  55         MOV D, L
0e20  55         MOV D, L
0e21  55         MOV D, L
0e22  55         MOV D, L
0e23  15         DCR D
0e24  50         MOV D, B
0e25  02         STAX BC
0e26  50         MOV D, B
0e27  25         DCR H
0e28  00         NOP
0e29  00         NOP
0e2a  00         NOP
0e2b  01 50 00   LXI BC, 0050
0e2e  00         NOP
0e2f  00         NOP
0e30  00         NOP
0e31  00         NOP
0e32  00         NOP
0e33  01 00 00   LXI BC, 0000
0e36  01 00 00   LXI BC, 0000
0e39  00         NOP
0e3a  00         NOP
0e3b  00         NOP
0e3c  00         NOP
0e3d  00         NOP
0e3e  00         NOP
0e3f  00         NOP
0e40  05         DCR B
0e41  15         DCR D
0e42  50         MOV D, B
0e43  00         NOP
0e44  50         MOV D, B
0e45  05         DCR B
0e46  15         DCR D
0e47  55         MOV D, L
0e48  55         MOV D, L
0e49  55         MOV D, L
0e4a  55         MOV D, L
0e4b  55         MOV D, L
0e4c  55         MOV D, L
0e4d  55         MOV D, L
0e4e  55         MOV D, L
0e4f  55         MOV D, L
0e50  55         MOV D, L
0e51  51         MOV D, C
0e52  55         MOV D, L
0e53  55         MOV D, L
0e54  55         MOV D, L
0e55  55         MOV D, L
0e56  55         MOV D, L
0e57  55         MOV D, L
0e58  55         MOV D, L
0e59  55         MOV D, L
0e5a  55         MOV D, L
0e5b  55         MOV D, L
0e5c  55         MOV D, L
0e5d  55         MOV D, L
0e5e  55         MOV D, L
0e5f  15         DCR D
0e60  50         MOV D, B
0e61  00         NOP
0e62  50         MOV D, B
0e63  05         DCR B
0e64  10         db 10
0e65  00         NOP
0e66  20         db 20
0e67  00         NOP
0e68  00         NOP
0e69  00         NOP
0e6a  20         db 20
0e6b  00         NOP
0e6c  50         MOV D, B
0e6d  00         NOP
0e6e  00         NOP
0e6f  01 00 00   LXI BC, 0000
0e72  00         NOP
0e73  00         NOP
0e74  00         NOP
0e75  00         NOP
0e76  00         NOP
0e77  00         NOP
0e78  02         STAX BC
0e79  00         NOP
0e7a  00         NOP
0e7b  00         NOP
0e7c  05         DCR B
0e7d  15         DCR D
0e7e  50         MOV D, B
0e7f  00         NOP
0e80  55         MOV D, L
0e81  55         MOV D, L
0e82  55         MOV D, L
0e83  55         MOV D, L
0e84  55         MOV D, L
0e85  55         MOV D, L
0e86  55         MOV D, L
0e87  55         MOV D, L
0e88  55         MOV D, L
0e89  51         MOV D, C
0e8a  55         MOV D, L
0e8b  55         MOV D, L
0e8c  55         MOV D, L
0e8d  51         MOV D, C
0e8e  55         MOV D, L
0e8f  55         MOV D, L
0e90  55         MOV D, L
0e91  55         MOV D, L
0e92  54         MOV D, H
0e93  55         MOV D, L
0e94  55         MOV D, L
0e95  55         MOV D, L
0e96  55         MOV D, L
0e97  55         MOV D, L
0e98  55         MOV D, L
0e99  55         MOV D, L
0e9a  55         MOV D, L
0e9b  15         DCR D
0e9c  50         MOV D, B
0e9d  00         NOP
0e9e  00         NOP
0e9f  00         NOP
0ea0  00         NOP
0ea1  00         NOP
0ea2  06 00      MVI B, 00
0ea4  00         NOP
0ea5  00         NOP
0ea6  00         NOP
0ea7  01 00 07   LXI BC, 0700
0eaa  00         NOP
0eab  01 00 00   LXI BC, 0000
0eae  00         NOP
0eaf  00         NOP
0eb0  06 00      MVI B, 00
0eb2  00         NOP
0eb3  00         NOP
0eb4  00         NOP
0eb5  00         NOP
0eb6  00         NOP
0eb7  00         NOP
0eb8  05         DCR B
0eb9  15         DCR D
0eba  55         MOV D, L
0ebb  55         MOV D, L
0ebc  55         MOV D, L
0ebd  55         MOV D, L
0ebe  15         DCR D
0ebf  55         MOV D, L
0ec0  55         MOV D, L
0ec1  55         MOV D, L
0ec2  55         MOV D, L
0ec3  54         MOV D, H
0ec4  55         MOV D, L
0ec5  51         MOV D, C
0ec6  55         MOV D, L
0ec7  55         MOV D, L
0ec8  55         MOV D, L
0ec9  55         MOV D, L
0eca  55         MOV D, L
0ecb  55         MOV D, L
0ecc  55         MOV D, L
0ecd  55         MOV D, L
0ece  55         MOV D, L
0ecf  55         MOV D, L
0ed0  55         MOV D, L
0ed1  55         MOV D, L
0ed2  55         MOV D, L
0ed3  55         MOV D, L
0ed4  55         MOV D, L
0ed5  55         MOV D, L
0ed6  55         MOV D, L
0ed7  15         DCR D
0ed8  50         MOV D, B
0ed9  00         NOP
0eda  00         NOP
0edb  00         NOP
0edc  10         db 10
0edd  00         NOP
0ede  00         NOP
0edf  00         NOP
0ee0  50         MOV D, B
0ee1  00         NOP
0ee2  00         NOP
0ee3  01 50 00   LXI BC, 0050
0ee6  00         NOP
0ee7  00         NOP
0ee8  00         NOP
0ee9  06 00      MVI B, 00
0eeb  00         NOP
0eec  00         NOP
0eed  00         NOP
0eee  00         NOP
0eef  02         STAX BC
0ef0  00         NOP
0ef1  00         NOP
0ef2  00         NOP
0ef3  00         NOP
0ef4  05         DCR B
0ef5  15         DCR D
0ef6  51         MOV D, C
0ef7  55         MOV D, L
0ef8  55         MOV D, L
0ef9  55         MOV D, L
0efa  55         MOV D, L
0efb  55         MOV D, L
0efc  55         MOV D, L
0efd  51         MOV D, C
0efe  55         MOV D, L
0eff  54         MOV D, H
0f00  55         MOV D, L
0f01  51         MOV D, C
0f02  50         MOV D, B
0f03  00         NOP
0f04  15         DCR D
0f05  55         MOV D, L
0f06  55         MOV D, L
0f07  55         MOV D, L
0f08  55         MOV D, L
0f09  55         MOV D, L
0f0a  55         MOV D, L
0f0b  10         db 10
0f0c  00         NOP
0f0d  55         MOV D, L
0f0e  55         MOV D, L
0f0f  45         MOV B, L
0f10  55         MOV D, L
0f11  15         DCR D
0f12  15         DCR D
0f13  15         DCR D
0f14  51         MOV D, C
0f15  00         NOP
0f16  00         NOP
0f17  00         NOP
0f18  00         NOP
0f19  00         NOP
0f1a  20         db 20
0f1b  01 50 00   LXI BC, 0050
0f1e  02         STAX BC
0f1f  01 50 00   LXI BC, 0050
0f22  10         db 10
0f23  00         NOP
0f24  02         STAX BC
0f25  00         NOP
0f26  00         NOP
0f27  20         db 20
0f28  00         NOP
0f29  10         db 10
0f2a  00         NOP
0f2b  50         MOV D, B
0f2c  00         NOP
0f2d  00         NOP
0f2e  00         NOP
0f2f  15         DCR D
0f30  15         DCR D
0f31  15         DCR D
0f32  55         MOV D, L
0f33  55         MOV D, L
0f34  55         MOV D, L
0f35  55         MOV D, L
0f36  15         DCR D
0f37  55         MOV D, L
0f38  55         MOV D, L
0f39  55         MOV D, L
0f3a  55         MOV D, L
0f3b  54         MOV D, H
0f3c  55         MOV D, L
0f3d  51         MOV D, C
0f3e  50         MOV D, B
0f3f  00         NOP
0f40  15         DCR D
0f41  55         MOV D, L
0f42  55         MOV D, L
0f43  55         MOV D, L
0f44  55         MOV D, L
0f45  55         MOV D, L
0f46  55         MOV D, L
0f47  10         db 10
0f48  00         NOP
0f49  50         MOV D, B
0f4a  00         NOP
0f4b  55         MOV D, L
0f4c  55         MOV D, L
0f4d  55         MOV D, L
0f4e  15         DCR D
0f4f  15         DCR D
0f50  50         MOV D, B
0f51  00         NOP
0f52  00         NOP
0f53  00         NOP
0f54  10         db 10
0f55  00         NOP
0f56  00         NOP
0f57  00         NOP
0f58  50         MOV D, B
0f59  00         NOP
0f5a  00         NOP
0f5b  01 50 00   LXI BC, 0050
0f5e  50         MOV D, B
0f5f  00         NOP
0f60  00         NOP
0f61  00         NOP
0f62  20         db 20
0f63  00         NOP
0f64  00         NOP
0f65  10         db 10
0f66  00         NOP
0f67  50         MOV D, B
0f68  20         db 20
0f69  00         NOP
0f6a  00         NOP
0f6b  05         DCR B
0f6c  15         DCR D
0f6d  15         DCR D
0f6e  51         MOV D, C
0f6f  55         MOV D, L
0f70  55         MOV D, L
0f71  55         MOV D, L
0f72  55         MOV D, L
0f73  55         MOV D, L
0f74  55         MOV D, L
0f75  51         MOV D, C
0f76  55         MOV D, L
0f77  54         MOV D, H
0f78  55         MOV D, L
0f79  51         MOV D, C
0f7a  50         MOV D, B
0f7b  00         NOP
0f7c  15         DCR D
0f7d  55         MOV D, L
0f7e  55         MOV D, L
0f7f  55         MOV D, L
0f80  55         MOV D, L
0f81  55         MOV D, L
0f82  55         MOV D, L
0f83  10         db 10
0f84  00         NOP
0f85  55         MOV D, L
0f86  55         MOV D, L
0f87  55         MOV D, L
0f88  55         MOV D, L
0f89  55         MOV D, L
0f8a  15         DCR D
0f8b  15         DCR D
0f8c  51         MOV D, C
0f8d  00         NOP
0f8e  02         STAX BC
0f8f  00         NOP
0f90  00         NOP
0f91  00         NOP
0f92  00         NOP
0f93  01 50 20   LXI BC, 2050
0f96  00         NOP
0f97  01 50 00   LXI BC, 0050
0f9a  10         db 10
0f9b  00         NOP
0f9c  00         NOP
0f9d  00         NOP
0f9e  00         NOP
0f9f  00         NOP
0fa0  00         NOP
0fa1  10         db 10
0fa2  00         NOP
0fa3  00         NOP
0fa4  00         NOP
0fa5  00         NOP
0fa6  00         NOP
0fa7  00         NOP
0fa8  10         db 10
0fa9  15         DCR D
0faa  55         MOV D, L
0fab  55         MOV D, L
0fac  55         MOV D, L
0fad  55         MOV D, L
0fae  55         MOV D, L
0faf  55         MOV D, L
0fb0  55         MOV D, L
0fb1  55         MOV D, L
0fb2  55         MOV D, L
0fb3  55         MOV D, L
0fb4  55         MOV D, L
0fb5  55         MOV D, L
0fb6  55         MOV D, L
0fb7  55         MOV D, L
0fb8  55         MOV D, L
0fb9  55         MOV D, L
0fba  55         MOV D, L
0fbb  55         MOV D, L
0fbc  55         MOV D, L
0fbd  55         MOV D, L
0fbe  55         MOV D, L
0fbf  55         MOV D, L
0fc0  55         MOV D, L
0fc1  55         MOV D, L
0fc2  55         MOV D, L
0fc3  55         MOV D, L
0fc4  55         MOV D, L
0fc5  55         MOV D, L
0fc6  55         MOV D, L
0fc7  55         MOV D, L
0fc8  50         MOV D, B
0fc9  00         NOP
0fca  00         NOP
0fcb  00         NOP
0fcc  00         NOP
0fcd  00         NOP
0fce  00         NOP
0fcf  00         NOP
0fd0  00         NOP
0fd1  00         NOP
0fd2  00         NOP
0fd3  00         NOP
0fd4  00         NOP
0fd5  00         NOP
0fd6  00         NOP
0fd7  00         NOP
0fd8  00         NOP
0fd9  00         NOP
0fda  00         NOP
0fdb  00         NOP
0fdc  00         NOP
0fdd  00         NOP
0fde  00         NOP
0fdf  00         NOP
0fe0  00         NOP
0fe1  00         NOP
0fe2  00         NOP
0fe3  00         NOP
0fe4  a0         ANA B
0fe5  05         DCR B
0fe6  50         MOV D, B
0fe7  00         NOP
0fe8  00         NOP
0fe9  00         NOP
0fea  60         MOV H, B
0feb  00         NOP
0fec  00         NOP
0fed  00         NOP
0fee  00         NOP
0fef  00         NOP
0ff0  00         NOP
0ff1  00         NOP
0ff2  00         NOP
0ff3  00         NOP
0ff4  00         NOP
0ff5  00         NOP
0ff6  00         NOP
0ff7  00         NOP
0ff8  00         NOP
0ff9  00         NOP
0ffa  00         NOP
0ffb  00         NOP
0ffc  00         NOP
0ffd  00         NOP
0ffe  00         NOP
0fff  00         NOP
1000  00         NOP
1001  00         NOP
1002  a0         ANA B
1003  05         DCR B
1004  50         MOV D, B
1005  01 55 55   LXI BC, 5555
1008  55         MOV D, L
1009  55         MOV D, L
100a  55         MOV D, L
100b  55         MOV D, L
100c  55         MOV D, L
100d  50         MOV D, B
100e  00         NOP
100f  00         NOP
1010  00         NOP
1011  00         NOP
1012  00         NOP
1013  00         NOP
1014  00         NOP
1015  60         MOV H, B
1016  00         NOP
1017  00         NOP
1018  00         NOP
1019  00         NOP
101a  00         NOP
101b  00         NOP
101c  00         NOP
101d  00         NOP
101e  00         NOP
101f  99         SBB C
1020  10         db 10
1021  05         DCR B
1022  50         MOV D, B
1023  01 55 00   LXI BC, 0055
1026  50         MOV D, B
1027  00         NOP
1028  20         db 20
1029  00         NOP
102a  02         STAX BC
102b  09         DAD BC
102c  99         SBB C
102d  00         NOP
102e  00         NOP
102f  00         NOP
1030  00         NOP
1031  13         INX DE
1032  33         INX SP
1033  33         INX SP
1034  33         INX SP
1035  00         NOP
1036  00         NOP
1037  00         NOP
1038  00         NOP
1039  00         NOP
103a  00         NOP
103b  00         NOP
103c  20         db 20
103d  00         NOP
103e  10         db 10
103f  05         DCR B
1040  50         MOV D, B
1041  01 55 00   LXI BC, 0055
1044  50         MOV D, B
1045  05         DCR B
1046  55         MOV D, L
1047  54         MOV D, H
1048  55         MOV D, L
1049  50         MOV D, B
104a  05         DCR B
104b  55         MOV D, L
104c  55         MOV D, L
104d  00         NOP
104e  00         NOP
104f  10         db 10
1050  00         NOP
1051  00         NOP
1052  00         NOP
1053  00         NOP
1054  00         NOP
1055  00         NOP
1056  00         NOP
1057  15         DCR D
1058  55         MOV D, L
1059  45         MOV B, L
105a  55         MOV D, L
105b  00         NOP
105c  10         db 10
105d  05         DCR B
105e  50         MOV D, B
105f  01 55 00   LXI BC, 0055
1062  50         MOV D, B
1063  00         NOP
1064  00         NOP
1065  20         db 20
1066  00         NOP
1067  00         NOP
1068  05         DCR B
1069  52         MOV D, D
106a  55         MOV D, L
106b  00         NOP
106c  00         NOP
106d  19         DAD DE
106e  99         SBB C
106f  91         SUB C
1070  03         INX BC
1071  33         INX SP
1072  33         INX SP
1073  30         db 30
1074  00         NOP
1075  10         db 10
1076  00         NOP
1077  00         NOP
1078  00         NOP
1079  00         NOP
107a  10         db 10
107b  05         DCR B
107c  50         MOV D, B
107d  01 55 00   LXI BC, 0055
1080  50         MOV D, B
1081  05         DCR B
1082  55         MOV D, L
1083  55         MOV D, L
1084  55         MOV D, L
1085  50         MOV D, B
1086  05         DCR B
1087  55         MOV D, L
1088  55         MOV D, L
1089  00         NOP
108a  00         NOP
108b  00         NOP
108c  00         NOP
108d  01 00 00   LXI BC, 0000
1090  03         INX BC
1091  20         db 20
1092  00         NOP
1093  10         db 10
1094  00         NOP
1095  00         NOP
1096  00         NOP
1097  00         NOP
1098  10         db 10
1099  05         DCR B
109a  50         MOV D, B
109b  01 55 00   LXI BC, 0055
109e  50         MOV D, B
109f  05         DCR B
10a0  00         NOP
10a1  00         NOP
10a2  20         db 20
10a3  00         NOP
10a4  00         NOP
10a5  00         NOP
10a6  00         NOP
10a7  00         NOP
10a8  00         NOP
10a9  00         NOP
10aa  00         NOP
10ab  01 02 00   LXI BC, 0002
10ae  03         INX BC
10af  33         INX SP
10b0  33         INX SP
10b1  33         INX SP
10b2  00         NOP
10b3  00         NOP
10b4  99         SBB C
10b5  99         SBB C
10b6  10         db 10
10b7  05         DCR B
10b8  50         MOV D, B
10b9  01 55 20   LXI BC, 2055
10bc  50         MOV D, B
10bd  05         DCR B
10be  00         NOP
10bf  55         MOV D, L
10c0  55         MOV D, L
10c1  50         MOV D, B
10c2  00         NOP
10c3  00         NOP
10c4  00         NOP
10c5  99         SBB C
10c6  09         DAD BC
10c7  99         SBB C
10c8  99         SBB C
10c9  91         SUB C
10ca  05         DCR B
10cb  51         MOV D, C
10cc  00         NOP
10cd  00         NOP
10ce  00         NOP
10cf  00         NOP
10d0  00         NOP
10d1  01 00 00   LXI BC, 0000
10d4  10         db 10
10d5  05         DCR B
10d6  50         MOV D, B
10d7  01 33 33   LXI BC, 3333
10da  30         db 30
10db  05         DCR B
10dc  00         NOP
10dd  00         NOP
10de  00         NOP
10df  09         DAD BC
10e0  99         SBB C
10e1  99         SBB C
10e2  00         NOP
10e3  00         NOP
10e4  10         db 10
10e5  00         NOP
10e6  00         NOP
10e7  00         NOP
10e8  00         NOP
10e9  01 00 00   LXI BC, 0000
10ec  09         DAD BC
10ed  99         SBB C
10ee  99         SBB C
10ef  91         SUB C
10f0  00         NOP
10f1  00         NOP
10f2  10         db 10
10f3  05         DCR B
10f4  50         MOV D, B
10f5  01 00 60   LXI BC, 6000
10f8  00         NOP
10f9  00         NOP
10fa  00         NOP
10fb  00         NOP
10fc  00         NOP
10fd  00         NOP
10fe  00         NOP
10ff  00         NOP
1100  00         NOP
1101  00         NOP
1102  10         db 10
1103  00         NOP
1104  26 20      MVI H, 20
1106  00         NOP
1107  01 99 99   LXI BC, 9999
110a  99         SBB C
110b  00         NOP
110c  00         NOP
110d  01 00 00   LXI BC, 0000
1110  10         db 10
1111  05         DCR B
1112  50         MOV D, B
1113  01 33 53   LXI BC, 5333
1116  33         INX SP
1117  55         MOV D, L
1118  35         DCR M
1119  53         MOV D, E
111a  33         INX SP
111b  50         MOV D, B
111c  00         NOP
111d  00         NOP
111e  00         NOP
111f  00         NOP
1120  10         db 10
1121  05         DCR B
1122  55         MOV D, L
1123  55         MOV D, L
1124  10         db 10
1125  00         NOP
1126  00         NOP
1127  00         NOP
1128  02         STAX BC
1129  00         NOP
112a  00         NOP
112b  01 00 00   LXI BC, 0000
112e  10         db 10
112f  05         DCR B
1130  50         MOV D, B
1131  01 00 00   LXI BC, 0000
1134  00         NOP
1135  00         NOP
1136  00         NOP
1137  00         NOP
1138  00         NOP
1139  00         NOP
113a  00         NOP
113b  00         NOP
113c  00         NOP
113d  00         NOP
113e  10         db 10
113f  00         NOP
1140  00         NOP
1141  00         NOP
1142  19         DAD DE
1143  99         SBB C
1144  99         SBB C
1145  00         NOP
1146  00         NOP
1147  00         NOP
1148  00         NOP
1149  00         NOP
114a  00         NOP
114b  00         NOP
114c  10         db 10
114d  05         DCR B
114e  50         MOV D, B
114f  01 00 55   LXI BC, 5500
1152  55         MOV D, L
1153  45         MOV B, L
1154  55         MOV D, L
1155  45         MOV B, L
1156  55         MOV D, L
1157  50         MOV D, B
1158  00         NOP
1159  02         STAX BC
115a  00         NOP
115b  00         NOP
115c  10         db 10
115d  00         NOP
115e  00         NOP
115f  00         NOP
1160  00         NOP
1161  00         NOP
1162  00         NOP
1163  10         db 10
1164  00         NOP
1165  00         NOP
1166  00         NOP
1167  00         NOP
1168  00         NOP
1169  00         NOP
116a  33         INX SP
116b  05         DCR B
116c  50         MOV D, B
116d  01 00 20   LXI BC, 2000
1170  05         DCR B
1171  20         db 20
1172  00         NOP
1173  25         DCR H
1174  00         NOP
1175  20         db 20
1176  05         DCR B
1177  05         DCR B
1178  05         DCR B
1179  00         NOP
117a  55         MOV D, L
117b  55         MOV D, L
117c  55         MOV D, L
117d  55         MOV D, L
117e  55         MOV D, L
117f  44         MOV B, H
1180  55         MOV D, L
1181  55         MOV D, L
1182  55         MOV D, L
1183  55         MOV D, L
1184  55         MOV D, L
1185  10         db 10
1186  00         NOP
1187  00         NOP
1188  00         NOP
1189  05         DCR B
118a  50         MOV D, B
118b  01 00 55   LXI BC, 5500
118e  55         MOV D, L
118f  45         MOV B, L
1190  55         MOV D, L
1191  45         MOV B, L
1192  55         MOV D, L
1193  51         MOV D, C
1194  00         NOP
1195  50         MOV D, B
1196  40         MOV B, B
1197  00         NOP
1198  55         MOV D, L
1199  55         MOV D, L
119a  55         MOV D, L
119b  55         MOV D, L
119c  55         MOV D, L
119d  44         MOV B, H
119e  55         MOV D, L
119f  55         MOV D, L
11a0  55         MOV D, L
11a1  55         MOV D, L
11a2  55         MOV D, L
11a3  10         db 10
11a4  00         NOP
11a5  00         NOP
11a6  00         NOP
11a7  25         DCR H
11a8  50         MOV D, B
11a9  01 00 00   LXI BC, 0000
11ac  00         NOP
11ad  00         NOP
11ae  00         NOP
11af  00         NOP
11b0  00         NOP
11b1  01 00 00   LXI BC, 0000
11b4  00         NOP
11b5  00         NOP
11b6  55         MOV D, L
11b7  50         MOV D, B
11b8  02         STAX BC
11b9  00         NOP
11ba  55         MOV D, L
11bb  44         MOV B, H
11bc  55         MOV D, L
11bd  00         NOP
11be  20         db 20
11bf  05         DCR B
11c0  55         MOV D, L
11c1  10         db 10
11c2  00         NOP
11c3  00         NOP
11c4  00         NOP
11c5  55         MOV D, L
11c6  50         MOV D, B
11c7  01 33 33   LXI BC, 3333
11ca  33         INX SP
11cb  53         MOV D, E
11cc  33         INX SP
11cd  33         INX SP
11ce  53         MOV D, E
11cf  30         db 30
11d0  00         NOP
11d1  00         NOP
11d2  00         NOP
11d3  00         NOP
11d4  55         MOV D, L
11d5  55         MOV D, L
11d6  55         MOV D, L
11d7  55         MOV D, L
11d8  55         MOV D, L
11d9  44         MOV B, H
11da  55         MOV D, L
11db  55         MOV D, L
11dc  55         MOV D, L
11dd  55         MOV D, L
11de  55         MOV D, L
11df  10         db 10
11e0  00         NOP
11e1  00         NOP
11e2  00         NOP
11e3  05         DCR B
11e4  50         MOV D, B
11e5  01 00 00   LXI BC, 0000
11e8  00         NOP
11e9  00         NOP
11ea  00         NOP
11eb  00         NOP
11ec  00         NOP
11ed  00         NOP
11ee  00         NOP
11ef  00         NOP
11f0  70         MOV M, B
11f1  00         NOP
11f2  00         NOP
11f3  00         NOP
11f4  00         NOP
11f5  00         NOP
11f6  00         NOP
11f7  00         NOP
11f8  00         NOP
11f9  00         NOP
11fa  00         NOP
11fb  00         NOP
11fc  00         NOP
11fd  10         db 10
11fe  00         NOP
11ff  00         NOP
1200  00         NOP
1201  05         DCR B
1202  55         MOV D, L
1203  55         MOV D, L
1204  55         MOV D, L
1205  55         MOV D, L
1206  55         MOV D, L
1207  55         MOV D, L
1208  55         MOV D, L
1209  55         MOV D, L
120a  55         MOV D, L
120b  55         MOV D, L
120c  55         MOV D, L
120d  55         MOV D, L
120e  55         MOV D, L
120f  55         MOV D, L
1210  55         MOV D, L
1211  55         MOV D, L
1212  55         MOV D, L
1213  55         MOV D, L
1214  55         MOV D, L
1215  55         MOV D, L
1216  55         MOV D, L
1217  55         MOV D, L
1218  55         MOV D, L
1219  55         MOV D, L
121a  55         MOV D, L
121b  55         MOV D, L
121c  55         MOV D, L
121d  55         MOV D, L
121e  55         MOV D, L
121f  55         MOV D, L
1220  50         MOV D, B
1221  00         NOP
1222  a0         ANA B
1223  00         NOP
1224  00         NOP
1225  00         NOP
1226  00         NOP
1227  00         NOP
1228  00         NOP
1229  00         NOP
122a  00         NOP
122b  00         NOP
122c  00         NOP
122d  00         NOP
122e  00         NOP
122f  00         NOP
1230  00         NOP
1231  00         NOP
1232  00         NOP
1233  00         NOP
1234  00         NOP
1235  00         NOP
1236  00         NOP
1237  00         NOP
1238  00         NOP
1239  00         NOP
123a  00         NOP
123b  0a         LDAX BC
123c  00         NOP
123d  05         DCR B
123e  50         MOV D, B
123f  00         NOP
1240  a0         ANA B
1241  00         NOP
1242  00         NOP
1243  00         NOP
1244  00         NOP
1245  00         NOP
1246  00         NOP
1247  00         NOP
1248  00         NOP
1249  00         NOP
124a  00         NOP
124b  00         NOP
124c  00         NOP
124d  00         NOP
124e  00         NOP
124f  00         NOP
1250  00         NOP
1251  00         NOP
1252  00         NOP
1253  00         NOP
1254  00         NOP
1255  00         NOP
1256  00         NOP
1257  00         NOP
1258  00         NOP
1259  0a         LDAX BC
125a  00         NOP
125b  05         DCR B
125c  50         MOV D, B
125d  00         NOP
125e  a0         ANA B
125f  00         NOP
1260  00         NOP
1261  00         NOP
1262  00         NOP
1263  00         NOP
1264  00         NOP
1265  00         NOP
1266  00         NOP
1267  00         NOP
1268  00         NOP
1269  00         NOP
126a  00         NOP
126b  00         NOP
126c  00         NOP
126d  00         NOP
126e  00         NOP
126f  00         NOP
1270  00         NOP
1271  00         NOP
1272  00         NOP
1273  00         NOP
1274  00         NOP
1275  00         NOP
1276  00         NOP
1277  0a         LDAX BC
1278  00         NOP
1279  05         DCR B
127a  50         MOV D, B
127b  00         NOP
127c  a0         ANA B
127d  00         NOP
127e  00         NOP
127f  00         NOP
1280  00         NOP
1281  00         NOP
1282  00         NOP
1283  00         NOP
1284  00         NOP
1285  00         NOP
1286  00         NOP
1287  00         NOP
1288  00         NOP
1289  00         NOP
128a  00         NOP
128b  00         NOP
128c  00         NOP
128d  00         NOP
128e  00         NOP
128f  00         NOP
1290  00         NOP
1291  00         NOP
1292  00         NOP
1293  00         NOP
1294  00         NOP
1295  0a         LDAX BC
1296  00         NOP
1297  05         DCR B
1298  50         MOV D, B
1299  00         NOP
129a  a0         ANA B
129b  00         NOP
129c  19         DAD DE
129d  99         SBB C
129e  99         SBB C
129f  99         SBB C
12a0  99         SBB C
12a1  00         NOP
12a2  99         SBB C
12a3  99         SBB C
12a4  99         SBB C
12a5  99         SBB C
12a6  99         SBB C
12a7  99         SBB C
12a8  99         SBB C
12a9  99         SBB C
12aa  99         SBB C
12ab  99         SBB C
12ac  90         SUB B
12ad  09         DAD BC
12ae  99         SBB C
12af  99         SBB C
12b0  99         SBB C
12b1  91         SUB C
12b2  00         NOP
12b3  0a         LDAX BC
12b4  00         NOP
12b5  05         DCR B
12b6  50         MOV D, B
12b7  00         NOP
12b8  a0         ANA B
12b9  00         NOP
12ba  10         db 10
12bb  00         NOP
12bc  00         NOP
12bd  00         NOP
12be  00         NOP
12bf  00         NOP
12c0  10         db 10
12c1  00         NOP
12c2  00         NOP
12c3  00         NOP
12c4  00         NOP
12c5  20         db 20
12c6  00         NOP
12c7  00         NOP
12c8  00         NOP
12c9  00         NOP
12ca  10         db 10
12cb  00         NOP
12cc  00         NOP
12cd  00         NOP
12ce  00         NOP
12cf  01 00 0a   LXI BC, 0a00
12d2  00         NOP
12d3  05         DCR B
12d4  50         MOV D, B
12d5  00         NOP
12d6  a0         ANA B
12d7  00         NOP
12d8  10         db 10
12d9  00         NOP
12da  02         STAX BC
12db  00         NOP
12dc  00         NOP
12dd  00         NOP
12de  10         db 10
12df  00         NOP
12e0  00         NOP
12e1  00         NOP
12e2  20         db 20
12e3  00         NOP
12e4  20         db 20
12e5  00         NOP
12e6  00         NOP
12e7  00         NOP
12e8  10         db 10
12e9  00         NOP
12ea  00         NOP
12eb  00         NOP
12ec  00         NOP
12ed  01 00 0a   LXI BC, 0a00
12f0  00         NOP
12f1  05         DCR B
12f2  50         MOV D, B
12f3  00         NOP
12f4  a0         ANA B
12f5  00         NOP
12f6  10         db 10
12f7  00         NOP
12f8  00         NOP
12f9  00         NOP
12fa  00         NOP
12fb  00         NOP
12fc  10         db 10
12fd  55         MOV D, L
12fe  55         MOV D, L
12ff  45         MOV B, L
1300  55         MOV D, L
1301  45         MOV B, L
1302  55         MOV D, L
1303  45         MOV B, L
1304  55         MOV D, L
1305  50         MOV D, B
1306  10         db 10
1307  00         NOP
1308  00         NOP
1309  00         NOP
130a  00         NOP
130b  01 00 0a   LXI BC, 0a00
130e  00         NOP
130f  05         DCR B
1310  50         MOV D, B
1311  00         NOP
1312  a0         ANA B
1313  00         NOP
1314  10         db 10
1315  00         NOP
1316  00         NOP
1317  00         NOP
1318  09         DAD BC
1319  99         SBB C
131a  10         db 10
131b  00         NOP
131c  00         NOP
131d  20         db 20
131e  00         NOP
131f  00         NOP
1320  00         NOP
1321  20         db 20
1322  00         NOP
1323  00         NOP
1324  19         DAD DE
1325  99         SBB C
1326  00         NOP
1327  00         NOP
1328  00         NOP
1329  01 00 0a   LXI BC, 0a00
132c  00         NOP
132d  05         DCR B
132e  50         MOV D, B
132f  00         NOP
1330  a0         ANA B
1331  00         NOP
1332  10         db 10
1333  00         NOP
1334  00         NOP
1335  00         NOP
1336  00         NOP
1337  00         NOP
1338  00         NOP
1339  00         NOP
133a  55         MOV D, L
133b  55         MOV D, L
133c  55         MOV D, L
133d  45         MOV B, L
133e  55         MOV D, L
133f  55         MOV D, L
1340  50         MOV D, B
1341  00         NOP
1342  00         NOP
1343  00         NOP
1344  00         NOP
1345  00         NOP
1346  00         NOP
1347  01 00 0a   LXI BC, 0a00
134a  00         NOP
134b  05         DCR B
134c  50         MOV D, B
134d  00         NOP
134e  a0         ANA B
134f  00         NOP
1350  19         DAD DE
1351  99         SBB C
1352  99         SBB C
1353  00         NOP
1354  20         db 20
1355  00         NOP
1356  00         NOP
1357  00         NOP
1358  00         NOP
1359  60         MOV H, B
135a  20         db 20
135b  00         NOP
135c  20         db 20
135d  60         MOV H, B
135e  00         NOP
135f  00         NOP
1360  00         NOP
1361  02         STAX BC
1362  00         NOP
1363  99         SBB C
1364  99         SBB C
1365  91         SUB C
1366  00         NOP
1367  0a         LDAX BC
1368  00         NOP
1369  05         DCR B
136a  50         MOV D, B
136b  00         NOP
136c  a0         ANA B
136d  00         NOP
136e  00         NOP
136f  00         NOP
1370  01 55 55   LXI BC, 5555
1373  10         db 10
1374  00         NOP
1375  00         NOP
1376  00         NOP
1377  55         MOV D, L
1378  55         MOV D, L
1379  45         MOV B, L
137a  55         MOV D, L
137b  50         MOV D, B
137c  00         NOP
137d  00         NOP
137e  01 55 55   LXI BC, 5555
1381  10         db 10
1382  00         NOP
1383  00         NOP
1384  00         NOP
1385  0a         LDAX BC
1386  00         NOP
1387  05         DCR B
1388  50         MOV D, B
1389  00         NOP
138a  a0         ANA B
138b  02         STAX BC
138c  00         NOP
138d  00         NOP
138e  01 20 00   LXI BC, 0020
1391  10         db 10
1392  00         NOP
1393  00         NOP
1394  00         NOP
1395  00         NOP
1396  20         db 20
1397  00         NOP
1398  20         db 20
1399  00         NOP
139a  00         NOP
139b  00         NOP
139c  01 00 02   LXI BC, 0200
139f  10         db 10
13a0  00         NOP
13a1  00         NOP
13a2  00         NOP
13a3  0a         LDAX BC
13a4  00         NOP
13a5  05         DCR B
13a6  50         MOV D, B
13a7  00         NOP
13a8  a0         ANA B
13a9  00         NOP
13aa  00         NOP
13ab  01 55 55   LXI BC, 5555
13ae  55         MOV D, L
13af  55         MOV D, L
13b0  10         db 10
13b1  00         NOP
13b2  00         NOP
13b3  00         NOP
13b4  55         MOV D, L
13b5  45         MOV B, L
13b6  50         MOV D, B
13b7  00         NOP
13b8  00         NOP
13b9  01 55 55   LXI BC, 5555
13bc  55         MOV D, L
13bd  55         MOV D, L
13be  10         db 10
13bf  00         NOP
13c0  00         NOP
13c1  0a         LDAX BC
13c2  00         NOP
13c3  05         DCR B
13c4  50         MOV D, B
13c5  00         NOP
13c6  a0         ANA B
13c7  00         NOP
13c8  00         NOP
13c9  01 00 00   LXI BC, 0000
13cc  00         NOP
13cd  20         db 20
13ce  10         db 10
13cf  00         NOP
13d0  00         NOP
13d1  00         NOP
13d2  00         NOP
13d3  00         NOP
13d4  00         NOP
13d5  00         NOP
13d6  00         NOP
13d7  01 02 00   LXI BC, 0002
13da  00         NOP
13db  00         NOP
13dc  10         db 10
13dd  00         NOP
13de  00         NOP
13df  0a         LDAX BC
13e0  00         NOP
13e1  05         DCR B
13e2  50         MOV D, B
13e3  00         NOP
13e4  a0         ANA B
13e5  00         NOP
13e6  01 55 55   LXI BC, 5555
13e9  55         MOV D, L
13ea  55         MOV D, L
13eb  55         MOV D, L
13ec  55         MOV D, L
13ed  10         db 10
13ee  00         NOP
13ef  00         NOP
13f0  00         NOP
13f1  00         NOP
13f2  00         NOP
13f3  00         NOP
13f4  01 55 55   LXI BC, 5555
13f7  55         MOV D, L
13f8  55         MOV D, L
13f9  55         MOV D, L
13fa  55         MOV D, L
13fb  10         db 10
13fc  00         NOP
13fd  0a         LDAX BC
13fe  00         NOP
13ff  05         DCR B
1400  50         MOV D, B
1401  00         NOP
1402  a0         ANA B
1403  00         NOP
1404  01 02 00   LXI BC, 0002
1407  00         NOP
1408  00         NOP
1409  00         NOP
140a  00         NOP
140b  10         db 10
140c  00         NOP
140d  00         NOP
140e  00         NOP
140f  00         NOP
1410  00         NOP
1411  00         NOP
1412  01 00 00   LXI BC, 0000
1415  00         NOP
1416  00         NOP
1417  00         NOP
1418  20         db 20
1419  10         db 10
141a  00         NOP
141b  0a         LDAX BC
141c  00         NOP
141d  05         DCR B
141e  50         MOV D, B
141f  00         NOP
1420  a0         ANA B
1421  01 55 55   LXI BC, 5555
1424  55         MOV D, L
1425  55         MOV D, L
1426  55         MOV D, L
1427  55         MOV D, L
1428  55         MOV D, L
1429  55         MOV D, L
142a  10         db 10
142b  00         NOP
142c  00         NOP
142d  00         NOP
142e  00         NOP
142f  01 55 55   LXI BC, 5555
1432  55         MOV D, L
1433  55         MOV D, L
1434  55         MOV D, L
1435  55         MOV D, L
1436  55         MOV D, L
1437  55         MOV D, L
1438  10         db 10
1439  0a         LDAX BC
143a  00         NOP
143b  05         DCR B
143c  50         MOV D, B
143d  00         NOP
143e  a0         ANA B
143f  01 00 02   LXI BC, 0200
1442  00         NOP
1443  00         NOP
1444  20         db 20
1445  02         STAX BC
1446  06 00      MVI B, 00
1448  10         db 10
1449  00         NOP
144a  00         NOP
144b  70         MOV M, B
144c  00         NOP
144d  01 00 60   LXI BC, 6000
1450  20         db 20
1451  00         NOP
1452  02         STAX BC
1453  00         NOP
1454  00         NOP
1455  20         db 20
1456  10         db 10
1457  0a         LDAX BC
1458  00         NOP
1459  05         DCR B
145a  55         MOV D, L
145b  55         MOV D, L
145c  55         MOV D, L
145d  55         MOV D, L
145e  55         MOV D, L
145f  55         MOV D, L
1460  55         MOV D, L
1461  55         MOV D, L
1462  55         MOV D, L
1463  55         MOV D, L
1464  55         MOV D, L
1465  55         MOV D, L
1466  55         MOV D, L
1467  55         MOV D, L
1468  55         MOV D, L
1469  55         MOV D, L
146a  55         MOV D, L
146b  55         MOV D, L
146c  55         MOV D, L
146d  55         MOV D, L
146e  55         MOV D, L
146f  55         MOV D, L
1470  55         MOV D, L
1471  55         MOV D, L
1472  55         MOV D, L
1473  55         MOV D, L
1474  55         MOV D, L
1475  55         MOV D, L
1476  55         MOV D, L
1477  55         MOV D, L

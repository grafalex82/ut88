; Mathematical functions library
;
; This module contains a set of different routines, that implement mathematical functions.
; The library provide functions, that work with 1-byte signed integers, 2-byte signed integers,
; and 3-byte floating point numbers.
;
; Data formats used:
; - 1-byte integer in Sign-Magnitude representation. 7 lower bits represent the value, 8th bit
;   is a sign. Example: -5 decimal would be 10000101 (0x85), the MSB is a sign (value is negative),
;   the rest of the bits represent value of 5 (absolute value)
; - 2-byte integer in Sign-Magnitude representation. 14 lower bits represent the value, 14th bit
;   is an overflow, 15th bit is a sign. Value stored high byte first, low byte next.
; 
; See more on data formats at https://en.wikipedia.org/wiki/Signed_number_representations
;
;

; Add two 1-byte integers in Sign-Magnitude representation.
; Arguments are located at 0xc371 and 0xc374, the result is stored at 0xc374
;
; Both arguments are converted from Sign-Magnitude to a more computer-friendly Two's complement
; code. Then both operands are added, and then converted back to Sign-Magniture representation.
ADD_1_BYTE:
    0849  21 71 c3   LXI HL, c371               ; Load the first operand
    084c  0e 02      MVI C, 02                  ; Number of operands

    084e  7e         MOV A, M                   ; Check if the first operand negative
    084f  a7         ANA A
    0850  fa 63 08   JN CONV_TC_1_BYTE (0863)   ; Convert to Two's complement

    0853  0d         DCR C                      ; If the first operand is positive - one less negation needed

ADD_1_BYTE_2ND_OPERAND:
    0854  47         MOV B, A                   ; Store the first operand in B

    0855  21 74 c3   LXI HL, c374               ; Load the second operand

    0858  7e         MOV A, M                   ; Check if the second operand negative
    0859  a7         ANA A
    085a  fa 63 08   JN CONV_TC_1_BYTE (0863)   ; And convert to Two's complement if necessary

ADD_1_BYTE_DO_ADD:
    085d  80         ADD B                      ; Actually add operands
    085e  fa 6f 08   JN CONV_SM_1_BYTE (086f)   ; Convert negative number to Sign-Magnitude form

ADD_1_BYTE_EXIT:
    0861  77         MOV M, A                   ; Store result and exit
    0862  c9         RET

CONV_TC_1_BYTE:
    0863  e6 7f      ANI 7f                     ; Convert 1 byte in sign-magnitude representation
    0865  2f         CMA                        ; to Two's complement
    0866  c6 01      ADI 01

    0868  0d         DCR C                      ; Decrement operands counter
    0869  ca 5d 08   JZ ADD_1_BYTE_DO_ADD (085d)
    086c  c3 54 08   JMP ADD_1_BYTE_2ND_OPERAND (0854)


CONV_SM_1_BYTE:
    086f  2f         CMA                        ; Convert 1-byte value from Two's complement
    0870  c6 01      ADI 01                     ; to Sign-Magnitude representation
    0872  f6 80      ORI 80
    0874  c3 61 08   JMP ADD_1_BYTE_EXIT (0861)

;----------------------------------------------------

0870                       21 74 C3 7E A7 FA 83 08 47
0880  C3 8B 08 E6 7F 2F C6 01 C3 7F 08 21 71 C3 7E A7
0890  FA 9D 08 90 CA CC 08 FA CD 08 C3 A5 08 E6 7F 2F
08A0  C6 01 C3 93 08 4F 21 71 C3 7E 21 74 C3 77 23 7E
08B0  E6 7F 57 23 5E 97 7A 1F 57 7B 1F 37 3F 5F 0D CA
08C0  C5 08 C3 B6 08 73 2B 7E E6 80 B2 77 C9 2F C6 01
08D0  4F 21 74 C3 7E 21 71 C3 77 23 C3 AF 08 

; Add two 2-byte integers in Sign-Magnitude representation.
; Arguments are located at 0xc372/0xc373 and 0xc375/0xc376 (high byte first), the result is
; stored at 0xc375/0xc376
;
; Both arguments are converted from Sign-Magnitude to a more computer-friendly Two's complement
; code. Then both operands are added, and then converted back to Sign-Magniture representation.

ADD_2_BYTE:
    08dd  21 73 c3   LXI HL, c373               ; Load first operand to A (and eventually B) and C
    08e0  4e         MOV C, M
    08e1  2b         DCX HL
    08e2  7e         MOV A, M

    08e3  a7         ANA A                      ; Convert negative value to Two's Complement code
    08e4  fa ff 08   JN CONV_TC_2_BYTE_1 (08ff)

ADD_2_BYTE_1:
    08e7  47         MOV B, A

    08e8  21 76 c3   LXI HL, c376               ; Load the second operand to A (then D) and E
    08eb  5e         MOV E, M
    08ec  2b         DCX HL
    08ed  7e         MOV A, M

    08ee  a7         ANA A                      ; Convert negative value to Two's Complement
    08ef  fa 0e 09   JN CONV_TC_2_BYTE_2 (090e)

ADD_2_BYTE_2:
    08f2  57         MOV D, A                   ; Move second operand to HL (the first is in BC already)
    08f3  eb         XCHG

    08f4  09         DAD BC                     ; Add 2 operands
    08f5  eb         XCHG                       ; Put result to DE

    08f6  7a         MOV A, D                   ; Convert to Sign-Magnitude if the result is negative
    08f7  a7         ANA A
    08f8  fa 1d 09   JN CONV_SM_2_BYTE (091d)

ADD_2_BYTE_EXIT:
    08fb  72         MOV M, D                   ; Store result at 0xc375/0xc376
    08fc  23         INX HL
    08fd  73         MOV M, E
    08fe  c9         RET

CONV_TC_2_BYTE_1:
    08ff  e6 7f      ANI 7f                     ; Invert high byte
    0901  2f         CMA
    0902  47         MOV B, A

    0903  79         MOV A, C                   ; Invert low byte
    0904  2f         CMA

    0905  c6 01      ADI 01                     ; Add 1
    0907  4f         MOV C, A

    0908  3e 00      MVI A, 00                  ; Add carry bit to the high byte
    090a  88         ADC B
    090b  c3 e7 08   JMP ADD_2_BYTE_1 (08e7)

CONV_TC_2_BYTE_2:
    090e  e6 7f      ANI 7f                     ; Invert high byte
    0910  2f         CMA
    0911  57         MOV D, A

    0912  7b         MOV A, E                   ; Invert low byte
    0913  2f         CMA

    0914  c6 01      ADI 01                     ; Add 1
    0916  5f         MOV E, A

    0917  3e 00      MVI A, 00                  ; Add carry bit to the high byte
    0919  8a         ADC D
    091a  c3 f2 08   JMP ADD_2_BYTE_2 (08f2)    ; Return to the main code flow

CONV_SM_2_BYTE:
    091d  2f         CMA                        ; Invert high byte
    091e  57         MOV D, A

    091f  7b         MOV A, E                   ; Invert low byte
    0920  2f         CMA

    0921  c6 01      ADI 01                     ; Add 1
    0923  5f         MOV E, A

    0924  3e 00      MVI A, 00                  ; Add carry bit to the high byte
    0926  8a         ADC D

    0927  f6 80      ORI 80                     ; Set the negative sign bit
    0929  57         MOV D, A
    092a  c3 fb 08   JMP ADD_2_BYTE_EXIT (08fb)

;-----------------------------------------------------

MANTISSA_NORM:          ???
    092d  7e         MOV A, M                   ; 
    092e  a7         ANA A
    092f  fa 36 09   JN 0936

    0932  4f         MOV C, A
    0933  c3 3e 09   JMP 093e

    0936  e6 7f      ANI A, c6
    0938  2f         CMA
    0939  c6 01      ADI A, 01
    093a  c3 32 09   JMP 0932

    093e  23         INX HL
    093f  7e         MOV A, M
    0940  e6 80      ANI 80
    0942  47         MOV B, A
    0943  7e         MOV A, M
    0944  e6 7f      ANI 7f
    0946  57         MOV D, A
    0947  23         INX HL
    0948  7e         MOV A, M
    0949  a7         ANA A
    094a  ca 7e 09   JZ 097e
    094d  5f         MOV E, A
    094e  0d         DCR C
    094f  7b         MOV A, E
    0950  17         RAL
    0951  5f         MOV E, A
    0952  7a         MOV A, D
    0953  17         RAL
    0954  a7         ANA A
    0955  fa 5c 09   JN 095c
    0958  57         MOV D, A
    0959  c3 4e 09   JMP 094e

0920                                         7E A7 FA
0930  36 09 4F C3 3E 09 E6 7F 2F C6 01 C3 32 09 23 7E
0940  E6 80 47 7E E6 7F 57 23 7E A7 CA 7E 09 5F 0D 7B
0950  17 5F 7A 17 A7 FA 5C 09 57 C3 4E 09 1F 57 73 1F
0960  5F 0C 7A 1F 57 7B 1F 5F 0C 73 2B 7A B0 77 2B 79
0970  A7 FA 76 09 77 C9 2F C6 01 F6 80 C3 74 09 7A A7
0980  CA 75 09 97 C3 4D 09 CD 77 08 CD DD 08 21 74 C3
0990  CD 2D 09 C9 21 72 C3 7E 21 75 C3 AE E6 80 F5 7E
09A0  E6 7F 57 23 5E 97 67 6F 06 08 3A 73 C3 1F 4F DA
09B0  C1 09 7C 1F 67 7D 1F 6F AF 05 CA C5 09 79 C3 AD
09C0  09 19 C3 B2 09 06 06 3A 72 C3 1F 4F DA DE 09 7C
09D0  1F 67 7D 1F 6F AF 05 CA E2 09 79 C3 CA 09 19 C3
09E0  CF 09 11 76 C3 7D 12 1B F1 B4 12 C9 CD 49 08 CD
09F0  94 09 21 74 C3 CD 2D 09 C9 21 72 C3 7E 21 75 C3
0A00  AE E6 80 F5 7E E6 7F 57 23 5E 21 72 C3 7E E6 7F
0A10  47 23 4E EB 16 02 1E 01 7D 91 6F 7C 98 67 FA 2D
0A20  0A 17 3F 7A 17 57 DA 50 0A 29 C3 18 0A 17 3F 7A
0A30  17 57 DA 5C 0A 09 29 7C B7 FA 2D 0A C3 18 0A 7D
0A40  91 6F 7C 98 67 FA 54 0A 17 3F 7B 17 5F DA 66 0A
0A50  29 C3 3F 0A 17 3F 7B 17 5F DA 66 0A 09 29 7C B7
0A60  FA 54 0A C3 3F 0A 21 75 C3 F1 B2 77 23 73 C9 21
0A70  71 C3 7E 17 3F 1F 77 CD 49 08 CD F9 09 21 74 C3
0A80  CD 2D 09 21 71 C3 7E 17 3F 1F 77 C9 7E 23 46 23
0A90  4E C9 77 23 70 23 71 C9 0E 01 16 20 1E 00 62 6B
0AA0  FE 02 D2 A8 0A C3 E6 0A 06 08 07 DA B2 0A 05 C3
0AB0  AA 0A 05 CA DB 0A F5 AF 7A 1F 57 7B 1F 5F 0C F1
0AC0  07 D2 B2 0A 19 D2 B2 0A F5 7C 1F 67 7D 1F 6F AF
0AD0  7A 1F 57 7B 1F 5F 0C F1 C3 B2 0A 3D FE 01 CA E6
0AE0  0A 54 5D C3 A8 0A AF 84 FA F0 0A 29 0D C3 E6 0A
0AF0  7C 1F 67 7D 1F 6F 0C AF 7C 1F 32 78 C3 7D 1F 32
0B00  79 C3 0C 79 32 77 C3 C9 3A 64 C3 E6 7F CA 5E 0B
0B10  F5 21 71 C3 CD 8C 0A 21 74 C3 CD 92 0A F1 3D CA
0B20  29 0B F5 CD EC 09 C3 1D 0B 3A 64 C3 A7 F2 6A 0B
0B30  21 71 C3 CD 8C 0A F5 C5 21 74 C3 CD 8C 0A 21 71
0B40  C3 CD 92 0A 21 74 C3 3E 01 06 20 0E 00 CD 92 0A
0B50  CD 6F 0A C1 F1 21 71 C3 CD 92 0A C3 6A 0B 21 74
0B60  C3 3E 01 06 20 0E 00 CD 92 0A C9 3E 02 06 20 0E
0B70  00 21 7A C3 CD 92 0A 3E 01 21 77 C3 CD 92 0A 21
0B80  6B C3 CD 92 0A 21 64 C3 77 06 A0 21 7D C3 CD 92
0B90  0A 21 61 C3 CD 8C 0A 21 71 C3 CD 92 0A 21 77 C3
0BA0  CD 8C 0A 21 74 C3 CD 92 0A CD 87 09 21 74 C3 CD
0BB0  8C 0A 21 65 C3 CD 92 BA 21 7D C3 CD 8C 0A 21 74
0BC0  C3 CD 92 0A CD 87 09 21 65 C3 CD 8C 0A 21 71 C3
0BD0  CD 92 0A CD 6F 0A 21 74 C3 CD 8C BA 21 65 C3 CD
0BE0  92 0A 21 68 C3 CD 92 0A 21 6B C3 CD 8C BA 21 71
0BF0  C3 CD 92 0A 21 7A C3 CD 8C 0A 21 74 C3 CD 92 0A
0C00  CD 87 09 21 74 C3 CD 8C 0A 21 6B C3 CD 92 0A 21
0C10  64 C3 34 34 21 65 C3 CD 8C 0A 21 71 C3 CD 92 0A
0C20  CD 08 0B 21 6B C3 CD 8C 0A 21 71 C3 CD 92 0A CD
0C30  6F 0A 21 68 C3 CD 8C 0A 21 71 C3 CD 92 0A CD 87
0C40  09 21 74 C3 CD 8C 0A 21 68 C3 CD 92 0A 21 72 C3
0C50  7E 17 3F 1F 77 CD 77 08 CD DD 08 21 75 C3 7E E6
0C60  7F CA 67 0C C3 E8 0B 23 7E FE 02 DA 71 0C C3 E8
0C70  0B 21 68 C3 7E A7 FA 7D 0C 3C C3 85 0C 3D E6 7F
0C80  CA 85 0C F6 80 77 C9 21 62 C3 21 64 C3 36 01 21
0C90  61 C3 CD 8C BA 21 65 C3 CD 92 0A 21 6B C3 36 02
0CA0  21 64 C3 34 34 7E CD 98 0A 21 61 C3 CD 8C 0A 21
0CB0  71 C3 CD 92 0A CD 08 0B 21 77 C3 CD 8C 0A 21 71
0CC0  C3 CD 92 0A CD 6F 0A 21 6B C3 35 CA E3 0C 21 75
0CD0  C3 7E 17 3F 1F 77 2B CD 8C 0A 21 68 C3 CD 92 BA
0CE0  C3 A0 0C 21 68 C3 CD 8C 0A 21 71 C3 CD 92 0A CD
0CF0  87 09 21 65 C3 CD 8C 0A 21 71 C3 CD 92 0A CD 87
0D00  09 21 74 C3 CD 8C 0A 21 65 C3 CD 92 0A 21 72 C3
0D10  7E 17 3F 1F 77 CD 77 08 CD DD 08 21 75 C3 7E E6
0D20  7F CA 27 0D C3 9B 0C 23 7E FE 02 DA 31 0D C3 9B
0D30  0C C9 21 62 C3 21 64 C3 36 00 23 36 01 23 36 20
0D40  23 36 00 CD 9B 0C C9 21 62 C3 7E E6 80 F5 7E E6
0D50  7F 77 21 64 C3 36 01 21 61 C3 CD 8C 0A 21 65 C3
0D60  CD 92 0A 23 AF 36 01 23 36 20 23 77 23 36 02 23
0D70  36 20 23 77 23 36 02 23 36 20 23 77 21 77 C3 36
0D80  01 23 36 20 23 77 CD EE 0D CD 34 0F CD 15 0F 21
0D90  77 C3 CD 8C 0A 21 71 C3 CD 92 0A CD EC 09 21 65
0DA0  C3 CD 8C BA 21 71 C3 CD 92 0A CD 87 09 21 74 C3
0DB0  CD 8C 0A 21 7A C3 CD 92 0A 21 72 C3 7E 17 3F 1F
0DC0  77 CD 77 08 CD DD 08 21 75 C3 7E E6 7F CA DF 0D
0DD0  21 7A C3 CD 8C 0A 21 65 C3 CD 92 0A C3 86 0D 23
0DE0  7E FE 02 D2 D0 0D 21 66 C3 46 F1 B0 77 C9 21 6E
0DF0  C3 CD 8C 0A 21 71 C3 CD 92 0A 21 6B C3 CD 8C 0A
0E00  21 74 C3 CD 92 0A CD 87 09 21 74 C3 CD 8C 0A 21
0E10  6E C3 CD 92 0A 21 68 C3 CD 8C 0A 21 74 C3 CD 92
0E20  0A CD 6F 0A 21 77 C3 CD 8C 0A 21 71 C3 CD 92 0A
0E30  CD EC 09 21 74 C3 CD 8C 0A 21 77 C3 CD 92 0A C9
0E40  CD 47 0D CD 92 0F C9 CD 32 0D 21 65 C3 CD 8C 0A
0E50  21 7B C3 CD 92 0A CD 87 0C 21 65 C3 CD 8C 0A 21
0E60  74 C3 CD 92 0A 21 7B C3 CD 8C 0A 21 71 C3 CD 92
0E70  0A CD 6F 0A C9 21 62 C3 7E E6 80 F5 7E E6 7F 77
0E80  21 64 C3 36 01 23 AF 77 23 77 23 77 23 36 01 23
0E90  36 20 23 77 23 36 02 23 36 20 23 77 CD 15 0F 21
0EA0  74 C3 CD 8C 0A 21 6E C3 CD 92 0A CD 34 0F CD 15
0EB0  0F 21 75 C3 7E 17 3F 1F 77 21 6E C3 CD 8C 0A 21
0EC0  71 C3 CD 92 0A CD 87 09 21 65 C3 CD 8C 0A 21 71
0ED0  C3 CD 92 0A CD 87 09 21 74 C3 CD 8C 0A 21 65 C3
0EE0  CD 92 0A 21 72 C3 7E 17 3F 1F 77 CD 77 08 CD DD
0EF0  08 21 75 C3 7E E6 7F CA 00 0F CD 34 0F C3 9C 0A
0F00  23 7E FE 02 DA 0D 0F CD 34 0F C3 9C 0E 21 66 C3
0F10  46 F1 B0 77 C9 21 61 C3 CD 8C 0A 21 71 C3 CD 92
0F20  0A CD 08 0B 21 68 C3 CD 8C 0A 21 71 C3 CD 92 0A
0F30  CD 6F 0A C9 21 64 C3 34 34 21 68 C3 CD 8C 0A 21
0F40  71 C3 CD 92 0A 21 6B C3 CD 8C 0A 21 74 C3 CD 92
0F50  0A CD 87 09 21 74 C3 CD 8C 0A 21 68 C3 CD 92 0A
0F60  C9 CD 87 0C 21 65 C3 CD 8C 0A 21 7B C3 CD 92 0A
0F70  CD 32 0D 21 65 C3 CD 8C 0A 21 74 C3 CD 92 0A 21
0F80  7B C3 CD 8C 0A 21 71 C3 CD 92 0A CD 6F 0A C9 CD
0F90  75 0E 21 65 C3 CD 8C 0A 21 71 C3 CD 92 0A 2B 7E
0FA0  17 3F 1F 77 23 23 36 01 23 36 32 23 36 42 CD 87
0FB0  09 21 74 C3 CD 8C 0A 21 65 C3 CD 92 0A C9 C3 87
0FC0  09 C3 EC 09 C3 6F 0A C3 C7 0F C3 98 0A C3 08 0B
0FD0  C3 D0 0F C3 6B 0B C3 87 0C C3 32 0D C3 47 0D C3
0FE0  40 0E C3 75 0E C3 61 0F C3 47 0E C3 8F 0F C3 49
0FF0  08 C3 DD 08 C3 94 09 C3 F9 09 C3 8C 0A C3 92 0A

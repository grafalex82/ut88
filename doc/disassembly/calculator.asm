; Mathematical functions library
;
; This module contains a set of different routines, that implement mathematical functions.
; The library provide functions, that work with 1-byte signed integers, 2-byte signed integers,
; and 3-byte floating point numbers.
;
; Data formats used:
; - 1-byte integer in Sign-Magnitude representation
;   - 7 lower bits represent the value
;   - 8th bit is a sign. 
;   Example: -5 decimal would be 10000101 (0x85), the MSB is a sign (value is negative),
;   the rest of the bits represent value of 5 (absolute value)
; - 2-byte integer in Sign-Magnitude representation
;   - 14 lower bits represent the value
;   - 14th bit is an overflow
;   - 15th bit is a sign. 
;   - Value stored high byte first, low byte next.
; - 3-byte floating point number. 
;   - First byte is an exponent
;   - 2nd and 3rd bytes are mantissa (high byte first, bit 7 of the high byte is a sign)
; 
; See more on data formats at https://en.wikipedia.org/wiki/Signed_number_representations
;
; Routine addresses (see parameters description in the respective function disassembly):
; - 0849 - add two 1-byte integers in Sign-Magnitude representation
; - 0877 - Normalize two 3-byte floats before adding
; - 08ff - Add two 2-byte integers in Sign-Magnitude representation.
; - 092d - Normalize exponent
; - 0987 - Add two 3-byte floats
; - 0994 - Multiply two 2-byte mantissa values
; - 09ec - Multiply two 3-byte flot values


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

; Normalize two 3-byte floats before adding
;
; The function prepares two floats for adding, by aligning their exponents. Bigger exponent value
; will replace smaller exponent, the mantissa of the argument with smaller exponent will be shifted
; right for number of bits that equal exponents difference. Shifting mantissa right happens without
; rounding

NORM_VALUES:
    0877  21 74 c3   LXI HL, c374               ; Load second argument exponent
    087a  7e         MOV A, M

    087b  a7         ANA A                      ; Check if the exponent is signed
    087c  fa 83 08   JN CONV_EXP_TC_1 (0883)

NORM_VALUES_1:
    087f  47         MOV B, A                   ; Store the second argument exponent to B
    0880  c3 8b 08   JMP NORM_VALUES_2 (088b)

CONV_EXP_TC_1:
    0883  e6 7f      ANI 7f                     ; Convert exponent to Two's Complement
    0885  2f         CMA
    0886  c6 01      ADI 01
    0888  c3 7f 08   JMP NORM_VALUES_1 (087f)

NORM_VALUES_2:
    088b  21 71 c3   LXI HL, c371               ; Load first argument exponent
    088e  7e         MOV A, M

    088f  a7         ANA A                      ; Check if the exponent is signed
    0890  fa 9d 08   JN CONV_EXP_TC_1 (089d)

NORM_VALUES_3:
    0893  90         SUB B                      ; Calculate exponents difference
    0894  ca cc 08   JZ NORM_VALUES_EXIT (08cc) ; Nothing to do if exponents are equal
    0897  fa cd 08   JN NORM_VALUES_EXP_LT (08cd) ; Check if first exponent is less than second
    089a  c3 a5 08   JMP NORM_VALUES_EXP_GT (08a5)

CONV_EXP_TC_2:
    089d  e6 7f      ANI 7f                     ; Convert exponent to Two's Complement
    089f  2f         CMA
    08a0  c6 01      ADI 01
    08a2  c3 93 08   JMP NORM_VALUES_3 (0893)

NORM_VALUES_EXP_GT:
    08a5  4f         MOV C, A                   ; Store exponent difference in C

    08a6  21 71 c3   LXI HL, c371               ; Replace smaller exponent (2nd argument) with 
    08a9  7e         MOV A, M                   ; the greater one (1st argument)
    08aa  21 74 c3   LXI HL, c374
    08ad  77         MOV M, A

    08ae  23         INX HL                     ; Now shift the 2nd argument mantissa

NORM_VALUES_MANT_1:    
    08af  7e         MOV A, M                   ; Load mantissa into DE
    08b0  e6 7f      ANI 7f                     ; Clear the sign bit for mantissa manipulation
    08b2  57         MOV D, A
    08b3  23         INX HL
    08b4  5e         MOV E, M

    08b5  97         SUB A                      ; Clear A and carry bit

NORM_VALUES_MANT_2:
    08b6  7a         MOV A, D                   ; Shift DE one bit down
    08b7  1f         RAR
    08b8  57         MOV D, A
    08b9  7b         MOV A, E
    08ba  1f         RAR

    08bb  37         STC                        ; Clear carry bit
    08bc  3f         CMC

    08bd  5f         MOV E, A

    08be  0d         DCR C                      ; Repeat until exponents equal
    08bf  ca c5 08   JZ NORM_VALUES_RESULT (08c5)
    08c2  c3 b6 08   JMP NORM_VALUES_MANT_2 (08b6)

NORM_VALUES_RESULT:
    08c5  73         MOV M, E                   ; Store result, keeping the sign
    08c6  2b         DCX HL
    08c7  7e         MOV A, M
    08c8  e6 80      ANI 80
    08ca  b2         ORA D
    08cb  77         MOV M, A

NORM_VALUES_EXIT:
    08cc  c9         RET

NORM_VALUES_EXP_LT:
    08cd  2f         CMA                        ; Convert exponent difference to Two's Complement
    08ce  c6 01      ADI 01
    08d0  4f         MOV C, A                   ; And store it to C

    08d1  21 74 c3   LXI HL, c374               ; Replace smaller exponent (1st argument) with 
    08d4  7e         MOV A, M                   ; the greater one (2nd)
    08d5  21 71 c3   LXI HL, c371
    08d8  77         MOV M, A

    08d9  23         INX HL                     ; Now shift the 1st argument mantissa
    08da  c3 af 08   JMP NORM_VALUES_MANT_1 (08af)



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



; Normalize exponent
; 
; The value is located at [HL], result is stored at the same location
;
; Mantissa is moved left until 14th bit is 0, and 13th bit is 1. Bit 15 maintains sign flag.
; Exponent is corrected accordingly
NORM_EXPONENT:
    092d  7e         MOV A, M                   ; Load the exponent value
    092e  a7         ANA A
    092f  fa 36 09   JN NORM_EXPONENT_1 (0936)  ; Convert to Two's Complement if necessary

NORM_EXPONENT_1:
    0932  4f         MOV C, A                   ; Store the exponent in C
    0933  c3 3e 09   JMP NORM_EXPONENT_3 (093e)

NORM_EXPONENT_2:
    0936  e6 7f      ANI A, 7f                  ; Convert exponent to Two's complement
    0938  2f         CMA
    0939  c6 01      ADI A, 01
    093a  c3 32 09   JMP NORM_EXPONENT_1 (0932)

NORM_EXPONENT_3:
    093e  23         INX HL                     ; Load the mantissa
    093f  7e         MOV A, M

    0940  e6 80      ANI 80                     ; Store the sign flag in B
    0942  47         MOV B, A

    0943  7e         MOV A, M                   ; Load the mantissa to DE
    0944  e6 7f      ANI 7f
    0946  57         MOV D, A
    0947  23         INX HL
    0948  7e         MOV A, M
    0949  a7         ANA A                      ; Check if mantissa is zero
    094a  ca 7e 09   JZ NORM_EXPONENT_ZERO (097e)
NORM_EXPONENT_4:
    094d  5f         MOV E, A

NORM_EXPONENT_L:
    094e  0d         DCR C                      ; Shift mantissa 1 bit left, counting shifts in C (exponent)
    094f  7b         MOV A, E
    0950  17         RAL
    0951  5f         MOV E, A
    0952  7a         MOV A, D
    0953  17         RAL
    0954  a7         ANA A
    0955  fa 5c 09   JN NORM_EXPONENT_5 (095c)  ; Shift until the most significant bit reaches bit 15
    0958  57         MOV D, A
    0959  c3 4e 09   JMP NORM_EXPONENT_L (094e)

NORM_EXPONENT_5:
    095c  1f         RAR                        ; Shift the mantissa 1 bit back (right)
    095d  57         MOV D, A                   ; to reserve place for the sign bit
    095e  7b         MOV A, E
    095f  1f         RAR
    0960  5f         MOV E, A

    0961  0c         INR C                      ; Correct exponent

    0962  7a         MOV A, D                   ; Shift the mantissa for 1 more bit back
    0963  1f         RAR                        ; to reserve place for the most significant 0 bit
    0964  57         MOV D, A
    0965  7b         MOV A, E
    0966  1f         RAR
    0967  5f         MOV E, A

    0968  0c         INR C                      ; Correct exponent as well

    0969  73         MOV M, E                   ; Store the result
    096a  2b         DCX HL
    096b  7a         MOV A, D                   ; Do not forget to restore the sign bit
    096c  b0         ORA B
    096d  77         MOV M, A

    096e  2b         DCX HL
    096f  79         MOV A, C                   ; Save the exponent
    0970  a7         ANA A
    0971  fa 76 09   JN NORM_EXPONENT_SM (0976) ; Restore exponent's Sign-Magnitude form, if needed

NORM_EXPONENT_EXIT:
    0974  77         MOV M, A
NORM_EXPONENT_EXIT_2:
    0975  c9         RET


NORM_EXPONENT_SM:
    0976  2f         CMA                        ; Convert to Sign-Magnitude representation
    0977  c6 01      ADI A, 01
    0979  f6 80      ORI A, 80                  ; Restore sign bit
    097b  c3 74 09   JMP NORM_EXPONENT_EXIT (0974)


NORM_EXPONENT_ZERO:
    097e  7a         MOV A, D                   ; If the mantissa is zero, nothing is needed
    097f  a7         ANA A                      ; Just exit without any changes
    0980  ca 75 09   JZ NORM_EXPONENT_EXIT_2 (0975)

    0983  97         SUB A                      ; Clear A, carry bit, and continue
    0984  c3 4d 09   JMP NORM_EXPONENT_4 (094d)



; Add two 3-byte float values
;
; Adds two floats at the addresses 0xc371-0xc373, and 0xc374-0xc376. Result is stored
; at 0xc374-0xc376
ADD_FLOATS:
    0987  cd 77 08   CALL NORM_VALUES (0877)    ; Normalize values, so that they have the same exponent
    098a  cd dd 08   CALL ADD_2_BYTE (08dd)     ; Add mantissa values

    098d  21 74 c3   LXI HL, c374               ; Normalize exponent
    0990  cd 2d 09   CALL NORM_EXPONENT (092d)
    0993  c9         RET


; Multiply two 2-byte signed mantissa values
;
; Arguments are located at 0xc372/0xc373 and 0xc375/0xc376 (high byte first), the result is
; stored at 0xc375/0xc376
;
; Although the documentation states this is multiplication of two 2-byte integers, it worth
; noting that this is very special implementation, and does not work for generic integers.
; Instead it is supposed to multiply normalized mantissa values:
; - Shifted to the left, so that 14th bit is 0, and 13th bit is 1
; - Bit 14 represents integer part of the value, bits 0-13 represent fraction part. This
;   means that the value represent a number between 0 and 1, and multiplication result will
;   also be in this range. Moreover multiplication result will be less than arguments, and
;   and therefore will require mantissa normalization.
; - Bit 15 is a sign bit
;
; Implementation is a classic column multiplication. If argument has a particular bit set,
; the result will be added with a second argument shifted by a respected number of bits. The
; only important thing to note, that instead of shifting one of the arguments left, this 
; implementation does shift the result right. That is why it does not work for generic integers,
; but ok for mantissa multiplication.
MULT_MANTISSA:
    0994  21 72 c3   LXI HL, c372               ; Load high bytes and compare their signs
    0997  7e         MOV A, M
    0998  21 75 c3   LXI HL, c375
    099b  ae         XRA M                      ; resulting sign is a XOR of arguments' signs
    099c  e6 80      ANI 80
    099e  f5         PUSH PSW                   ; Just store the sign on stack for now

    099f  7e         MOV A, M                   ; Load the second argument to DE without the sign bit
    09a0  e6 7f      ANI 7f
    09a2  57         MOV D, A
    09a3  23         INX HL
    09a4  5e         MOV E, M

    09a5  97         SUB A                      ; Zero HL (result accumulator) and carry bit
    09a6  67         MOV H, A
    09a7  6f         MOV L, A

    09a8  06 08      MVI B, 08                  ; Set the number bits in the low byte

    09aa  3a 73 c3   LDA c373                   ; Load first argument low byte

MULT_MANTISSA_L1:
    09ad  1f         RAR                        ; Argument 1 will be shifted right bit by bit
    09ae  4f         MOV C, A                   ; If the bit is set - add the second argument 
    09af  da c1 09   JC MULT_ARG2_ADD_1 (09c1)  ; to the result accumulator (HL)

MULT_MANTISSA_CONT_1:
    09b2  7c         MOV A, H                   ; Shift the result 1 bit right
    09b3  1f         RAR                        ; 
    09b4  67         MOV H, A
    09b5  7d         MOV A, L
    09b6  1f         RAR
    09b7  6f         MOV L, A

    09b8  af         XRA A                      ; Clear A and carry bit
    09b9  05         DCR B                      ; Repeat for all bits in the low byte of the 1st arg
    09ba  ca c5 09   JZ MULT_MANTISSA_CONT_2 (09c5)

    09bd  79         MOV A, C                   ; Load the next part of the low byte
    09be  c3 ad 09   JMP MULT_MANTISSA_L1 (09ad); and repeat

MULT_ARG2_ADD_1:
    09c1  19         DAD DE                     ; Add the second argument to the result
    09c2  c3 b2 09   JMP MULT_MANTISSA_CONT_1 (09b2)

MULT_MANTISSA_CONT_2:
    09c5  06 06      MVI B, 06                  ; Number of iterations for the high byte
    09c7  3a 72 c3   LDA c372                   ; Load the high byte of the first argument

MULT_MANTISSA_L2:
    09ca  1f         RAR                        ; Argument 1 will be shifted right bit by bit
    09cb  4f         MOV C, A                   ; If the bit is set - add the second argument 
    09cc  da de 09   JC MULT_ARG2_ADD_2 (09de)  ; to the result accumulator (HL)

MULT_MANTISSA_CONT_3:
    09cf  7c         MOV A, H                   ; Shift result right 1 bit
    09d0  1f         RAR
    09d1  67         MOV H, A
    09d2  7d         MOV A, L
    09d3  1f         RAR
    09d4  6f         MOV L, A

    09d5  af         XRA A                      ; 
    09d6  05         DCR B                      ; Repeat for all 6 bits in the high byte
    09d7  ca e2 09   JZ MULT_MANTISSA_CONT_4 (09e2)
    09da  79         MOV A, C
    09db  c3 ca 09   JMP MULT_MANTISSA_L2 (09ca)

MULT_ARG2_ADD_2:
    09de  19         DAD DE                     ; Add the second argument to the result
    09df  c3 cf 09   JMP MULT_MANTISSA_CONT_3 (09cf)

MULT_MANTISSA_CONT_4:
    09e2  11 76 c3   LXI DE, c376               ; Store result
    09e5  7d         MOV A, L
    09e6  12         STAX DE
    09e7  1b         DCX DE
    09e8  f1         POP PSW

    09e9  b4         ORA H                      ; Add the sign bit
    09ea  12         STAX DE

    09eb  c9         RET


; Multiply two 3-byte floating point values
;
; Multplies two floats at the addresses 0xc371-0xc373, and 0xc374-0xc376. Result is stored
; at 0xc374-0xc376
;
; Multiplication algorithm is quite simple:
; - Exponents simply added
; - Mantissas multiplicated
; - Result is normalized, if necessary
MULT_3_BYTE:
    09ec  cd 49 08   CALL ADD_1_BYTE (0849)     ; Sum exponents
    09ef  cd 94 09   CALL MULT_2_BYTE (0994)    ; Multiply mantissa values
    09f2  21 74 c3   LXI HL, c374
    09f5  cd 2d 09   CALL NORM_EXPONENT (092d)  ; Normalize the exponent
    09f8  c9         RET    


; Divide two 2-byte signed mantissa values
;
; Arguments are located at 0xc372/0xc373 (divider) and 0xc375/0xc376 (divident) high byte first,
; the result is stored at 0xc375/0xc376
;
; The algorithm is a column division, but instead of shifting divider right, the algorithm
; shifts the divident left. Division is done using subtraction - if subtraction is successful, then
; corresponding output bit is 1, otherwise 0
DIV_MANTISSA:
    09f9  21 72 c3   LXI HL, c372               ; Resulting sign is a XOR of arguments' sings
    09fc  7e         MOV A, M
    09fd  21 75 c3   LXI HL, c375
    0a00  ae         XRA M
    0a01  e6 80      ANI 80
    0a03  f5         PUSH PSW                   ; Just store the sign on stack for now

    0a04  7e         MOV A, M                   ; Load divident into DE

    0a05  e6 7f      ANI 7f
    0a07  57         MOV D, A
    0a08  23         INX HL 
    0a09  5e         MOV E, M

    0a0a  21 72 c3   LXI HL, c372               ; Load divider into BC
    0a0d  7e         MOV A, M
    0a0e  e6 7f      ANI 7f
    0a10  47         MOV B, A
    0a11  23         INX HL
    0a12  4e         MOV C, M

    0a13  eb         XCHG                       ; Move divident to HL, this will be minuend

    0a14  16 02      MVI D, 02                  ; Load stop counters into DE (7 bits to process in D,
    0a16  1e 01      MVI E, 01                  ; 8 bits to process in E). DE will be the result accumulator

DIV_MANTISSA_L1:
    0a18  7d         MOV A, L                   ; Subtract divider (BD) from the minuend (HL)
    0a19  91         SUB C
    0a1a  6f         MOV L, A
    0a1b  7c         MOV A, H
    0a1c  98         SBB B
    0a1d  67         MOV H, A

    0a1e  fa 2d 0a   JN DIV_MANTISSA_1 (0a2d)   ; If result is negative - store zero bit in the result

    0a21  17         RAL                        ; Otherwise store set bit in the result
    0a22  3f         CMC                        ; Shift D left, setting the rightmost bit
    0a23  7a         MOV A, D                   
    0a24  17         RAL
    0a25  57         MOV D, A
    0a26  da 50 0a   JC DIV_MANTISSA_2 (0a50)   ; Repeat until D stop mark is reached, then move to part 2

    0a29  29         DAD HL                     ; Shift HL left 1 bit
    0a2a  c3 18 0a   JMP DIV_MANTISSA_L1 (0a18)

DIV_MANTISSA_1:
    0a2d  17         RAL                        ; Shift D left, Clear the rightmost bit
    0a2e  3f         CMC
    0a2f  7a         MOV A, D                   
    0a30  17         RAL
    0a31  57         MOV D, A
    0a32  da 5c 0a   JC DIV_MANTISSA_4 (0a5c)   ; Repeat until D stop mark is reached, then move to part 2

    0a35  09         DAD BC                     ; Restore the original divident
    0a36  29         DAD HL                     ; And shift it left
    0a37  7c         MOV A, H
    0a38  b7         ORA A
    0a39  fa 2d 0a   JN DIV_MANTISSA_1 (0a2d)   ; ???

    0a3c  c3 18 0a   JMP DIV_MANTISSA_L1 (0a18)

DIV_MANTISSA_L2:
    0a3f  7d         MOV A, L                   ; Part 2: Do the same, but use E as a counter
    0a40  91         SUB C                      ; Subtract divider (BD) from the minuend (HL)
    0a41  6f         MOV L, A
    0a42  7c         MOV A, H
    0a43  98         SBB B
    0a44  67         MOV H, A
    0a45  fa 54 0a   JN DIV_MANTISSA_3 (0a54)   ; If result is negative - store zero bit in the result

    0a48  17         RAL                        ; Otherwise store set bit in the result
    0a49  3f         CMC                        ; Shift D left, setting the rightmost bit
    0a4a  7b         MOV A, E
    0a4b  17         RAL
    0a4c  5F         MOV E, A
    0a4d  da 66 0a   JC DIV_MANTISSA_EXIT (0a66)    ; Repeat until stop mark in E reached

DIV_MANTISSA_2:
    0a50  29         DAD HL                     ; Shift HL left 1 bit
    0a52  c3 3f 0a   JMP DIV_MANTISSA_L2 (0a3f)

DIV_MANTISSA_3:
    0a54  17         RAL                        ; Shift D left, and set 0 in the rightmost bit
    0a55  3f         CMC
    0a56  7b         MOV A, E
    0a57  17         RAL
    0a58  5f         MOV E, A
    0a59  da 66 0a   JC DIV_MANTISSA_EXIT (0a66)

DIV_MANTISSA_4:
    0a5c  09         DAD BC                     ; Restore the original divident
    0a5d  29         DAD HL                     ; And shift it left
    0a5e  7c         MOV A, H
    0a5f  b7         ORA A
    0a60  fa 54 0a   JN DIV_MANTISSA_3 (0a54)
    0a63  c3 3f 0a   JMP DIV_MANTISSA_L2 (0a3f)

DIV_MANTISSA_EXIT:
    0a66  21 75 c3   LXI HL, c375               ; Store accumulator at c375
    0a69  f1         POP PSW
    0a6a  b2         ORA D                      ; Do not forget to apply sign bit
    0a6b  77         MOV M, A
    0a6c  23         INX HL
    0a6d  73         MOV M, E

    0a6e  c9         RET                        ; Done



; Divide two 3-byte floating point values
;
; Divide value at 0xc374-0xc376 (divident) by value at 0xc371-0xc373 (divider).
; Result is stored at 0xc374-0xc376
;
; Division algorithm:
; - Divider exponent is subtracted from divident's exponent
; - Mantissas divided
; - Result is normalized, if necessary
DIV_3_BYTE:
    0a6f  21 71 c3   LXI HL, c371               ; Load Divider's exponent
    0a72  7e         MOV A, M

    0a73  17         RAL                        ; Invert the exponent's sign bit
    0a74  3f         CMC                        ; In order to subtract divider exponent from
    0a75  1f         RAR                        ; divident's exponent
    0a76  77         MOV M, A

    0a77  cd 49 08   CALL ADD_1_BYTE (0849)     ; Perform the subtraction

    0a7a  cd f9 09   CALL DIV_MANTISSA (09f9)

    0a7d  21 74 c3   LXI HL, c374               ; Normalize the result
    0a80  cd 2d 09   CALL NORM_EXPONENT (092d)

    0a83  21 71 c3   LXI HL, c371               ; Invert divider's exponent sign back
    0a86  7e         MOV A, M
    0a87  17         RAL
    0a88  3f         CMC
    0a89  1f         RAR
    0a8a  77         MOV M, A

    0a8b  c9         RET                        ; Done

0A80                                      7E 23 46 23
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

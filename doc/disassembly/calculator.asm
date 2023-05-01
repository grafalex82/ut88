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
; - 09ec - Multiply two 3-byte float values
; - 0a6f - Divide two 3-byte float values
; - 0b08 - Power
; - 0b6b - Logarithm
; - 0c87 - Sine


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


; Load 3 bytes at HL address to A, B, and C registers respectively
LOAD_ABC:
    0a8c  7e         MOV A, M
    0a8d  23         INX HL
    0a8e  46         MOV B, M
    0a8f  23         INX HL
    0a90  4e         MOV C, M
    0a91  c9         RET

; Store A, B, and C registers at HL address
STORE_ABC:
    0a92  77         MOV M, A    
    0a93  23         INX HL      
    0a94  70         MOV M, B    
    0a95  23         INX HL      
    0a96  71         MOV M, C    
    0a97  c9         RET         


; Calculate factorial
;
; Parameter in A, result in 0xc377
;
; Algorithm explanation TBD
FACTORIAL:
    0a98  0e 01      MVI C, 01                  ; Load 1.0 to C-D-E
    0a9a  16 20      MVI D, 20
    0a9c  1e 00      MVI E, 00

    0a9e  62         MOV H, D                   ; HL will be the result accumulator
    0a9f  6b         MOV L, E                   ; Place 1. there as well

    0aa0  fe 02      CPI 02                     ; Cases when A>=2 require calculations
    0aa2  d2 a8 0a   JNC FACTORIAL_LOOP_1 (0aa8)

    0aa5  c3 e6 0a   JMP FACTORIAL_3 (0ae6)     ; Cases when A<2 are trivial (return 1.0)
    
FACTORIAL_LOOP_1:   
    0aa8  06 08      MVI B, 08                  ; Bit counter

FACTORIAL_LOOP_2:
    0aaa  07         RLC                        ; Shift it left until the non-zero bit is reached
    0aab  da b2 0a   JC FACTORIAL_1 (0ab2)

    0aae  05         DCR B                      ; Count shifts with B
    0aaf  c3 aa 0a   JMP FACTORIAL_LOOP_2 (0aaa)

FACTORIAL_1:
    0ab2  05         DCR B                      ; If we shifted all 8 bits and have not found any
    0ab3  ca db 0a   JZ 0adb                    ; bits set - just exit (thoug this case should never happen)

    0ab6  f5         PUSH PSW

    0ab7  af         XRA A                      ; Shift current value right
    0ab8  7a         MOV A, D                   ; Taking into account increasing the exponent
    0ab9  1f         RAR                        ; a little below, this should not basically change
    0aba  57         MOV D, A                   ; the C-D-E floating point value
    0abb  7b         MOV A, E
    0abc  1f         RAR     
    0abd  5f         MOV E, A

    0abe  0c         INR C                      ; Increase the exponent

    0abf  f1         POP PSW

    0ac0  07         RLC                        ; Restore the original value of A
    0ac1  d2 b2 0a   JNC FACTORIAL_1 (0ab2)
    0ac4  19         DAD DE                     ; 
    0ac5  d2 b2 0a   JNC FACTORIAL_1 (0ab2)

    0ac8  f5         PUSH PSW
    0ac9  7c         MOV A, H
    0aca  1f         RAR
    0acb  67         MOV H, A
    0acc  7d         MOV A, L
    0acd  1f         RAR
    0ace  6f         MOV L, A

    0acf  af         XRA A

    0ad0  7a         MOV A, D
    0ad1  1f         RAR
    0ad2  57         MOV D, A

    0ad3  7b         MOV A, E
    0ad4  1f         RAR
    0ad5  5f         MOV E, A
    0ad6  0c         INR C

    0ad7  f1         POP PSW
    0ad8  c3 b2 0a   JMP FACTORIAL_1 (0ab2)

FACTORIAL_2:
    0adb  3d         DCR A
    0adc  fe 01      CPI 01
    0ade  ca e6 0a   JZ FACTORIAL_3 (0ae6)

    0ae1  54         MOV D, H
    0ae2  5d         MOV E, L
    0ae3  c3 a8 0a   JMP FACTORIAL_LOOP_1 (0aa8)

FACTORIAL_3:
    0ae6  af         XRA A                      ; Normalize mantissa, by shifting it left
    0ae7  84         ADD H                      ; until the highest bit is set
    0ae8  fa f0 0a   JN 0af0

    0aeb  29         DAD HL
    0aec  0d         DCR C                      ; Correct exponent accordingly
    0aed  c3 e6 0a   JMP 0ae6

FACTORIAL_4:
    0af0  7c         MOV A, H                   ; Shift it back for 1 bit
    0af1  1f         RAR
    0af2  67         MOV H, A
    0af3  7d         MOV A, L
    0af4  1f         RAR
    0af5  6f         MOV L, A
    0af6  0c         INR C                      ; Correct exponent accordingly

    0af7  af         XRA A                      ; Save result in 0xc377-0xc379
    0af8  7c         MOV A, H                   ; But first shift it right for 1 more bit
    0af9  1f         RAR                        ; so that bit 14 is 0, and bit 13 is 1, as required
    0afa  32 78 c3   STA c378                   ; by the format
    0afd  7d         MOV A, L
    0afe  1f         RAR
    0aff  32 79 c3   STA c379
    0b02  0c         INR C
    0b03  79         MOV A, C
    0b04  32 77 c3   STA c377

    0b07  c9         RET                        ; Done



; Exponentiate a 3-byte float into a integer power
;
; Arguments: Base - 0xc371-0xc373 (3-byte float), power - 0xc374 (1 byte integer)
; Result: 0xc374-0xc376
;
; The algorithm is pretty simple - just multiply the base for power-1 number of times
POWER:
    0b08  3a 64 c3   LDA c364                   ; Load the power value to A

    0b0b  e6 7f      ANI 7f                     ; Zero exponent => result is 1.0
    0b0d  ca 5e 0b   JZ POWER_RESULT_ONE (0b5e)

    0b10  f5         PUSH PSW                   ; Load base to A-B-C
    0b11  21 71 c3   LXI HL, c371
    0b14  cd 8c 0a   CALL LOAD_ABC (0a8c)

    0b17  21 74 c3   LXI HL, c374               ; And store it as a result, for now
    0b1a  cd 92 0a   CALL STORE_ABC (0a92)

POWER_LOOP:
    0b1d  f1         POP PSW
    0b1e  3d         DCR A                      ; decrement exponent, do while exponent is not zero
    0b1f  ca 29 0b   JZ POWER_CONT_1 (0b29)

    0b22  f5         PUSH PSW
    0b23  cd ec 09   CALL MULT_3_BYTE (09ec)    ; Multiply result accumulator with the base (again)

    0b26  c3 1d 0b   JMP POWER_LOOP (0b1d)

POWER_CONT_1:
    0b29  3a 64 c3   LDA c364                   ; Load the power value to A again
    0b2c  a7         ANA A
    0b2d  f2 6a 0b   JP POWER_EXIT (0b6a)       ; If it was positive exponent - we are done

    0b30  21 71 c3   LXI HL, c371               ; Load whatever is in c371 and save it on the stack
    0b33  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0b36  f5         PUSH PSW
    0b37  c5         PUSH BC

    0b38  21 74 c3   LXI HL, c374               ; Load the power result
    0b3b  cd 8c 0a   CALL LOAD_ABC (0a8c)

    0b3e  21 71 c3   LXI HL, c371               ; And store it to 0xc371 (as a divider)
    0b41  cd 92 0a   CALL STORE_ABC (0a92)

    0b44  21 74 c3   LXI HL, c374               ; Prepare 1.0 as a divident
    0b47  3e 01      MVI A, 01
    0b49  06 20      MVI B, 20
    0b4b  0e 00      MVI C, 00
    0b4d  cd 92 0a   CALL STORE_ABC (0a92)

    0b50  cd 6f 0a   CALL DIV_3_BYTE (0a6f)     ; Divide 1.0 by the power result obtained above

    0b53  c1         POP BC                     ; Restore value at c371
    0b54  f1         POP PSW
    0b55  21 71 c3   LXI HL, c371
    0b58  cd 92 0a   CALL STORE_ABC (0a92)

    0b5b  c3 6a 0b   JMP POWER_EXIT (0b6a)      ; Done

POWER_RESULT_ONE:
    0b5e  21 74 c3   LXI HL, c374               ; Store 1.0 as a result
    0b61  3e 01      MVI A, 01   
    0b63  06 20      MVI B, 20   
    0b65  0e 00      MVI C, 00   
    0b67  cd 92 0a   CALL STORE_ABC (0a92)

POWER_EXIT:
    0b6a  c9         RET         


; Calculate natual logarithm
;
; Argument is located at 0xc361-0xc363, result is at 0xc368-0xc36a
;
; Calculation algorithm is based on the Taylor series:
; Ln(x) = 2 * (A + A^3 / 3 + A^5 / 5 + ...) 
; where A = (x - 1) / (x + 1)
; Taylor series calculation continues until the next member does not change
; the result for more than 1 LSB
; 
; The following helper variables used:
; 0xc361 - function argument
; 0xc364 - next series member power (1, 3, 5, ...)
; 0xc365 - A = (x-1)/(x+1)
; 0xc368 - result accumulator
; 0xc36b - next series member divisor (1, 3, 5, ...)
; 0xc377 - 1.
; 0xc37a - 2.
; 0xc37d - -1.
LOGARITHM:
    0b6b  3e 02      MVI A, 02                  ; Store value 2. at 0xc37a
    0b6d  06 20      MVI B, 20
    0b6f  0e 00      MVI C, 00
    0b71  21 7a c3   LXI HL, c37a
    0b74  cd 92 0a   CALL STORE_ABC (0a92)

    0b77  3e 01      MVI A, 01                  ; Stora value 1. at 0xc377
    0b79  21 77 c3   LXI HL, c377
    0b7c  cd 92 0a   CALL STORE_ABC (0a92)

    0b7f  21 6b c3   LXI HL, c36b               ; Initial member divisor (1.)
    0b82  cd 92 0a   CALL STORE_ABC (0a92)

    0b85  21 64 c3   LXI HL, c364               ; Initial member power factor (1)
    0b88  77         MOV M, A

    0b89  06 a0      MVI B, a0                  ; Store value -1. at 0xc37d
    0b8b  21 7d c3   LXI HL, c37d
    0b8e  cd 92 0a   CALL STORE_ABC (0a92)

    0b91  21 61 c3   LXI HL, c361               ; Load 0xc361 (argument) to 0xc371
    0b94  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0b97  21 71 c3   LXI HL, c371               
    0b9a  cd 92 0a   CALL STORE_ABC (0a92)

    0b9d  21 77 c3   LXI HL, c377               ; Copy c377 (1.) to 0xc374
    0ba0  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0ba3  21 74 c3   LXI HL, c374               
    0ba6  cd 92 0a   CALL STORE_ABC (0a92)

    0ba9  cd 87 09   CALL ADD_FLOATS (0987)     ; Calculate x+1

    0bac  21 74 c3   LXI HL, c374               ; Store the result at 0xc365
    0baf  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0bb2  21 65 c3   LXI HL, c365
    0bb5  cd 92 0a   CALL STORE_ABC (0a92)

    0bb8  21 7d c3   LXI HL, c37d               ; Copy 0xc37d (-1.) to 0xc374
    0bbb  cd 8c 0a   CALL LOAD_ABC (0a8c) 
    0bbe  21 74 c3   LXI HL, c374
    0bc1  cd 92 0a   CALL STORE_ABC (0a92)

    0bc4  cd 87 09   CALL ADD_FLOATS (0987)     ; Calculate x-1 (x is still at 0xc371)

    0bc7  21 65 c3   LXI HL, c365               ; Copy 0xc365 (x+1) to 0xc371
    0bca  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0bcd  21 71 c3   LXI HL, c371
    0bd0  cd 92 0a   CALL STORE_ABC (0a92)

    0bd3  cd 6f 0a   CALL DIV_3_BYTE (0a6f)     ; Calculate (x-1)/(x+1)

    0bd6  21 74 c3   LXI HL, c374               ; Store and keep the result at 0xc365
    0bd9  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0bdc  21 65 c3   LXI HL, c365
    0bdf  cd 92 0a   CALL STORE_ABC (0a92)

    0be2  21 68 c3   LXI HL, c368               ; Initialize the result with the first calculated
    0be5  cd 92 0a   CALL STORE_ABC (0a92)      ; member A = (x-1)/(x+1)

LOGARITHM_LOOP:
    0be8  21 6b c3   LXI HL, c36b               ; Copy 0xc36b (next member divisor) to 0xc371
    0beb  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0bee  21 71 c3   LXI HL, c371
    0bf1  cd 92 0a   CALL STORE_ABC (0a92)

    0bf4  21 7a c3   LXI HL, c37a               ; Copy 0xc37a (2.) to 0xc374
    0bf7  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0bfa  21 74 c3   LXI HL, c374
    0bfd  cd 92 0a   CALL STORE_ABC (0a92)

    0c00  cd 87 09   CALL ADD_FLOATS (0987)     ; 0xc374 = 0xc371 (divisor) + 0xc374 (2.)

    0c03  21 74 c3   LXI HL, c374               ; Next member divisor (0xc36b) is now higher by 2
    0c06  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0c09  21 6b c3   LXI HL, c36b
    0c0c  cd 92 0a   CALL STORE_ABC (0a92)

    0c0f  21 64 c3   LXI HL, c364               ; Increase power factor by 2
    0c12  34         INR M
    0c13  34         INR M

    0c14  21 65 c3   LXI HL, c365               ; Load A=(x-1)/(x+1) to 0xc371
    0c17  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0c1a  21 71 c3   LXI HL, c371
    0c1d  cd 92 0a   CALL STORE_ABC (0a92)

    0c20  cd 08 0b   CALL POWER (0b08)          ; Calculate A^q where q is the next member power, result at 0xc374

    0c23  21 6b c3   LXI HL, c36b               ; Load next member divisor (0xc36b) to 0xc371
    0c26  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0c29  21 71 c3   LXI HL, c371
    0c2c  cd 92 0a   CALL STORE_ABC (0a92)

    0c2f  cd 6f 0a   CALL DIV_3_BYTE (0a6f)     ; Finish next member calculation (A^q / q)

    0c32  21 68 c3   LXI HL, c368               ; Load the result accumulator (0xc368) to 0xc371
    0c35  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0c38  21 71 c3   LXI HL, c371
    0c3b  cd 92 0a   CALL STORE_ABC (0a92)

    0c3e  cd 87 09   CALL ADD_FLOATS (0987)     ; And add the next member

    0c41  21 74 c3   LXI HL, c374               ; Store the sum back to the result accumulator (0xc368)
    0c44  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0c47  21 68 c3   LXI HL, c368
    0c4a  cd 92 0a   CALL STORE_ABC (0a92)

    0c4d  21 72 c3   LXI HL, c372               ; Toggle sign bit in 0xc371
    0c50  7e         MOV A, M
    0c51  17         RAL
    0c52  3f         CMC
    0c53  1f         RAR
    0c54  77         MOV M, A

    0c55  cd 77 08   CALL NORM_VALUES (0877)    ; Compare new accumulator value with the previous one
    0c58  cd dd 08   CALL ADD_2_BYTE (08dd)     ; (do the subtraction, but without result normalization)

    0c5b  21 75 c3   LXI HL, c375               ; If the difference is high - repeat the algorithm
    0c5e  7e         MOV A, M                   ; by adding another series member
    0c5f  e6 7f      ANI 7f
    0c61  ca 67 0c   JZ LOGARITHM_1 (0c67)

    0c64  c3 e8 0b   JMP LOGARITHM_LOOP (0be8)

LOGARITHM_1:
    0c67  23         INX HL                     ; If the high byte is equal, compare the low byte
    0c68  7e         MOV A, M
    0c69  fe 02      CPI 02                     ; If the low byte difference is more than 1 bit - 
    0c6b  da 71 0c   JC LOGARITHM_2 (0c71)      ; repeat the algorithm again, add another member

    0c6e  c3 e8 0b   JMP LOGARITHM_LOOP (0be8)

LOGARITHM_2:
    0c71  21 68 c3   LXI HL, c368               ; Get the result exponent
    0c74  7e         MOV A, M                   ; The idea is to multiply result by 2, which in fact
    0c75  a7         ANA A                      ; will be just increasing the exponent by 1
    0c76  fa 7d 0c   JN LOGARITHM_3 (0c7d)

    0c79  3c         INR A                      ; if exponent is positive - increase it
    0c7a  e3 85 0c   JMP LOGARITHM_EXIT (0c85)

LOGARITHM_3:
    0c7d  3d         DCR A                      ; If the exponent is negative - decrease absolute
    0c7e  e6 7f      ANI 7f                     ; value
    0c80  ca 85 0c   JZ 0c85

    0c83  f6 80      ORI 80                     ; keep the sign

LOGARITHM_EXIT:
    0c85  77         MOV M, A                   ; Store the result and exit
    0c86  c9         RET


; Sine function
;
; Argument is located at 0xc361-0xc363, result is at 0xc365-0xc367
;
; The alcorithm is based on calculating the Taylor series:
; sin(x) = x - x^3/3! + x^5/5! - x^7/7! + x^9/9! - ...
;
; Taylor series calculation continues until the next member does not change
; the result for more than 1 LSB
; 
; The following helper variables used:
; 0xc361 - Argument
; 0xc364 - Series member power/factorial number
; 0xc365 - Result accumulator
; 0xc368 - last calculated negative series member
; 0xc371/0xc374/0xc377 - temporary variables
SINE:
    0c87  21 62 c3   LXI HL, c362               ; Useless?

    0c8a  21 64 c3   LXI HL, c364               ; Series member power/factorial number
    0c8d  36 01      MVI M, 01                  ; Start with 1

    0c8f  21 61 c3   LXI HL, c361               ; Copy argument to result accumulator 0xc365
    0c92  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0c95  21 65 c3   LXI HL, c365
    0c98  cd 92 0a   CALL STORE_ABC (0a92)

SINE_LOOP_1:
    0c9b  21 6b c3   LXI HL, c36b               ; On each algorithm step we will be generating
    0c9e  36 02      MVI M, 02                  ; 2 members - positive and negative

SINE_LOOP_2:
    0ca0  21 64 c3   LXI HL, c364               ; Get to the next index of series member
    0ca3  34         INR M
    0ca4  34         INR M

    0ca5  7e         MOV A, M                   ; Calculate factorial in the member divider
    0ca6  cd 98 0a   CALL FACTORIAL (0a98)

    0ca9  21 61 c3   LXI HL, c361               ; Copy argument to 0xc371 
    0cac  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0caf  21 71 c3   LXI HL, c371
    0cb2  cd 92 0a   CALL STORE_ABC (0a92)

    0cb5  cd 08 0b   CALL POWER (0b08)          ; And power it

    0cb8  21 77 c3   LXI HL, c377               ; Copy factorial's result into a divider argument
    0cbb  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0cbe  21 71 c3   LXI HL, c371
    0cc1  cd 92 0a   CALL STORE_ABC (0a92)

    0cc4  cd 6f 0a   CALL DIV_3_BYTE (0a6f)     ; Calculate x^n / n!

    0cc7  21 6b c3   LXI HL, c36b               ; Positive member will stay in 0xc374
    0cca  35         DCR M
    0ccb  ca e3 0c   JZ SINE_CONT (0ce3)

    0cce  21 75 c3   LXI HL, c375               ; Toggle sign of the series member
    0cd1  7e         MOV A, M
    0cd2  17         RAL
    0cd3  3f         CMC
    0cd4  1f         RAR
    0cd5  77         MOV M, A

    0cd6  2b         DCX HL                     ; Negative members will be copied to 0xc368
    0cd7  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0cda  21 68 c3   LXI HL, c368
    0cdd  cd 92 0a   CALL STORE_ABC (0a92)

    0ce0  c3 a0 0c   JMP SINE_LOOP_2 (0ca0)

SINE_CONT:
    0ce3  21 68 c3   LXI HL, c368               ; Now it is time to add calculated positive
    0ce6  cd 8c 0a   CALL LOAD_ABC (0a8c)       ; and negative members of the series
    0ce9  21 71 c3   LXI HL, c371
    0cec  cd 92 0a   CALL STORE_ABC (0a92)

    0cef  cd 87 09   CALL ADD_FLOATS (0987)

    0cf2  21 65 c3   LXI HL, c365               ; Add both to the result accumulator
    0cf5  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0cf8  21 71 c3   LXI HL, c371
    0cfb  cd 92 0a   CALL STORE_ABC (0a92)

    0cfe  cd 87 09   CALL ADD_FLOATS (0987)

    0d01  21 74 c3   LXI HL, c374               ; Store new value in the result accumulator
    0d04  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0d07  21 65 c3   LXI HL, c365
    0d0a  cd 92 0a   CALL STORE_ABC (0a92)

    0d0d  21 72 c3   LXI HL, c372               ; 0xc371 still has previous result accumulator value
    0d10  7e         MOV A, M                   ; Toggle its sign
    0d11  17         RAL
    0d12  3f         CMC
    0d13  1f         RAR
    0d14  77         MOV M, A

    0d15  cd 77 08   CALL NORM_VALUES (0877)    ; Subtract old result (0xc371) from new result (0xc374)
    0d18  cd dd 08   CALL ADD_2_BYTE (08dd)     ; (same algorithm as ADD_FLOATS, but without normalization)

    0d1b  21 75 c3   LXI HL, c375               ; Check high byte of the result
    0d1e  7e         MOV A, M
    0d1f  e6 7f      ANI 7f
    0d21  ca 27 0d   JZ SINE_CONT_2 (0d27)

    0d24  c3 9b 0c   JMP SINE_LOOP_1 (0c9b)    ; Repeat the algorithm, if the difference is not small enough

SINE_CONT_2:
    0d27  23         INX HL                     ; Check low byte, if the difference is greater than
    0d28  7e         MOV A, M                   ; the least significant bit
    0d29  fe 02      CPI 02
    0d2b  da 31 0d   JC SINE_EXIT (0d31)

    0dbe  c3 9b 0c   JMP SINE_LOOP_1 (0c9b)    ; Repeat the algorithm, if the difference is not small enough
SINE_EXIT:
    0d31  c9         RET


; Cosine function
;
; Argument is located at 0xc361-0xc363, result is at 0xc365-0xc367
;
; The alcorithm is based on calculating the Taylor series:
; cos(x) = 1 - x^2/2! + x^4/4! - x^6/6! + x^8/8! - ...
;
; Taylor series calculation continues until the next member does not change
; the result for more than 1 LSB
;
; In fact the implementation is based on the sine function, just first member (1.) and
; initial power/factorial differs.
; 
; The following helper variables used:
; 0xc361 - Argument
; 0xc364 - Series member power/factorial number
; 0xc365 - Result accumulator
; 0xc368 - last calculated negative series member
; 0xc371/0xc374/0xc377 - temporary variables
COSINE:
    0d32  21 62 c3   LXI HL, c362               ; Useless?

    0d35  21 64 c3   LXI HL, c364               ; Initial member power/factorial at 0xc364
    0d38  36 00      MVI M, 00

    0d3a  23         INX HL                     ; Store 1. to the result accumulator (0xc365)
    0d3b  36 01      MVI M, 01
    0d3d  23         INX HL
    0d3e  36 20      MVI M, 20
    0d40  23         INX HL
    0d41  36 00      MVI M, 00

    0d43  cd 9b 0c   CALL SINE_LOOP_1 (0c9b)   ; Everything else matches the sine algorithm

    0d46  c9         RET



; Arcsine function
;
; Argument is located at 0xc361-0xc363, result is at 0xc365-0xc367
;
; The alcorithm is based on calculating the Taylor series:
; arcsin(x) = x + x^3/(2*3) + 1*3*x^5/(2*4*5) + 1*3*5*x^7/(2*4*6*7) + ..
; The implementation is calculating this like follows (different coefficient grouping):
; arcsin(x) = x + 1/2 * x^3/3 + 1*3/(2*4) * x^5/5 + 1*3*5/(2*4*6) * x^7/7 + ..
;
; Taylor series calculation continues until the next member does not change
; the result for more than 1 LSB
;
; Function variables:
; 0xc361 - argument (x)
; 0xc364 - power (1 byte integer, odd numbers - 1, 3, 5...)
; 0xc365 - result accumulator
; 0xc368 - next member x divisor (same value as power, but float, odd numbers - 1, 3, 5...)
; 0xc36b - 2.
; 0xc36e - next member even coefficient in the divisor (2, 4, 6, ...)
; 0xc371 - temporary value
; 0xc374 - temporary value
; 0xc377 - next member coefficient (1, 1*3/2*4, 1*3*5/2*4*6, ...)
;
; Issues: due to big number of multiplications and divisions, precision of this function is
; very low. Series convergence is very slow (it may take over 10 seconds to calculate arcsin(1)),
; and result is quite inaccurate (+-0.08)
ARCSIN:
    0d47  21 62 c3   LXI HL, c362               ; Get the argument's sign and store it on stack
    0d4a  7e         MOV A, M
    0d4b  e6 80      ANI 80
    0d4d  f5         PUSH PSW

    0d4e  7e         MOV A, M                   ; For calculation let's remove the sign for now
    0d4f  e6 7f      ANI 7f
    0d51  77         MOV M, A

    0d52  21 64 c3   LXI HL, c364               ; next series member power
    0d55  36 01      MVI M, 01

    0d57  21 61 c3   LXI HL, c361               ; Put the argument to the result accumulator
    0d5a  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0d5d  21 65 c3   LXI HL, c365
    0d60  cd 92 0a   CALL STORE_ABC (0a92)

    0d63  23         INX HL                     ; Store 1. to 0xc368 (next member divisor)
    0d64  af         XRA A
    0d65  36 01      MVI M, 01
    0d67  23         INX HL
    0d68  36 20      MVI M, 20
    0d6a  23         INX HL
    0d6b  77         MOV M, A

    0d6c  23         INX HL                     ; Store 2. to 0xc36b (just a constant)
    0d6d  36 02      MVI M, 02
    0d6f  23         INX HL
    0d70  36 20      MVI M, 20
    0d72  23         INX HL
    0d73  77         MOV M, A

    0d74  23         INX HL                     ; Store 2. to 0xc36e (next member even coefficient)
    0d75  36 02      MVI M, 02
    0d77  23         INX HL
    0d78  36 20      MVI M, 20
    0d7a  23         INX HL
    0d7b  77         MOV M, A

    0d7c  21 77 c3   LXI HL, c377               ; Store 1. to 0xc377 (next member coefficient)
    0d7f  36 01      MVI M, 01
    0d81  23         INX HL
    0d82  36 20      MVI M, 20
    0d84  23         INX HL
    0d85  77         MOV M, A

ARCSIN_LOOP:
    0d86  cd ee 0d   CALL ARCSIN_COEF (0dee)    ; c371 = c36e
                                                ; c36e = c36e + 2.
                                                ; c377 = c368 / c371 * c377

    0d89  cd 34 0f   CALL ARCSIN_ADVANCE (0f34) ; c368 += 2., c364 += 2
    0d8c  cd 15 0f   CALL ARCSIN_MEMBER (0f15)  ; c374 = c361 ^ c364 / c368

    0d8f  21 77 c3   LXI HL, c377               ; Multiply next member (x^n/n) and 
    0d92  cd 8c 0a   CALL LOAD_ABC (0a8c)       ; coefficient (1*3*5*..*n / 2*4*6*..*(n+1))
    0d95  21 71 c3   LXI HL, c371
    0d98  cd 92 0a   CALL STORE_ABC (0a92)

    0d9b  cd ec 09   CALL MULT_3_BYTE (09ec)

    0d9e  21 65 c3   LXI HL, c365               ; Add result accumulator and the next member
    0da1  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0da4  21 71 c3   LXI HL, c371
    0da7  cd 92 0a   CALL STORE_ABC (0a92)

    0daa  cd 87 09   CALL ADD_FLOATS (0987)

    0dad  21 74 c3   LXI HL, c374               ; Compare sum and previous result accumulator value
    0db0  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0db3  21 7a c3   LXI HL, c37a
    0db6  cd 92 0a   CALL STORE_ABC (0a92)

    0db9  21 72 c3   LXI HL, c372               ; Flip sign of one of the values to do subtraction
    0dbc  7e         MOV A, M
    0dbd  17         RAL
    0dbe  3f         CMC
    0dbf  1f         RAR
    0dc0  77         MOV M, A

    0dc1  cd 77 08   CALL NORM_VALUES (0877)    ; Calculate difference between previous and new
    0dc4  cd dd 08   CALL ADD_2_BYTE (08dd)     ; result

    0dc7  21 75 c3   LXI HL, c375               ; Check the difference high byte
    0dca  7e         MOV A, M
    0dcb  e6 7f      ANI 7f
    0dcd  ca df 0d   JZ ARCSIN_2 (0ddf)

ARCSIN_1:
    0dd0  21 7a c3   LXI HL, c37a               ; Save the new result in the result accumulator
    0dd3  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0dd6  21 65 c3   LXI HL, c365
    0dd9  cd 92 0a   CALL STORE_ABC (0a92)

    0ddc  c3 86 0d   JMP ARCSIN_LOOP (0d86)

ARCSIN_2:
    0ddf  23         INX HL                     ; Compare the difference low byte
    0de0  7e         MOV A, M                   ; If the difference is greater than LSB
    0de1  fe 02      CPI 02                     ; then repeat for one more iteration
    0de3  d2 d0 0d   JNC ARCSIN_1 (0dd0)

    0de6  21 66 c3   LXI HL, c366               ; Apply the sign bit
    0de9  46         MOV B, M
    0dea  F1         POP PSW
    0deb  B0         ORA B
    0dec  77         MOV M, A

    0ded  C9         RET                        ; Done

; Calculate next arcsin series member coefficient
;
;  c371 = c36e
;  c36e = c36e + 2.
;  c377 = c368 / c371 * c377
;
; Where:
; 0xc368 - next member x divisor (same value as power, but float, odd numbers - 1, 3, 5...)
; 0xc36e - next member even coefficient in the divisor (2, 4, 6, ...)
; 0xc377 - next member coefficient (1, 1*3/2*4, 1*3*5/2*4*6, ...)
ARCSIN_COEF:
    0dee  21 6e c3   LXI HL, c36e               ; Store 0xc36e old value at 0xc371
    0df1  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0df4  21 71 c3   LXI HL, c371
    0df7  cd 92 0a   CALL STORE_ABC (0a92)

    0dfa  21 6b c3   LXI HL, c36b               ; Load 2. to 0xc374
    0dfd  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0e00  21 74 c3   LXI HL, c374
    0e03  cd 92 0a   CALL STORE_ABC (0a92)

    0e06  cd 87 09   CALL ADD_FLOATS (0987)     ; c36e = c36e + 2.

    0e09  21 74 c3   LXI HL, c374               
    0e0c  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0e0f  21 6e c3   LXI HL, c36e
    0e12  cd 92 0a   CALL STORE_ABC (0a92)

    0e15  21 68 c3   LXI HL, c368               ; Load 0xc368 to the divident slot
    0e18  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0e1b  21 74 c3   LXI HL, c374
    0e1e  cd 92 0a   CALL STORE_ABC (0a92)

    0e21  cd 6f 0a   CALL DIV_3_BYTE (0a6f)     ; calculate c368 / c371

    0e24  21 77 c3   LXI HL, c377               ; Load 0xc377 to 0xc371
    0e27  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0e2a  21 71 c3   LXI HL, c371
    0e2d  cd 92 0a   CALL STORE_ABC (0a92)

    0e30  cd ec 09   CALL MULT_3_BYTE (09ec)    ; c377 = c368 / c371 * c377

    0e33  21 74 c3   LXI HL, c374
    0e36  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0e39  21 77 c3   LXI HL, c377
    0e3c  cd 92 0a   CALL STORE_ABC (0a92)

    0e3f  c9         RET

; Arccos function
;
; Argument is located at 0xc361-0xc363, result is at 0xc365-0xc367
;
; Algorithm:
; arccos(x) = Pi/2 - arcsin(x)
ARCCOS:
    0e40  cd 47 0d   CALL ARCSIN (0d47)
    0e43  cd 92 0f   CALL CALC_ARCCOS (0f92)
    0e46  c9         RET


; Tangens function
;
; Argument: 0xc361, result: 0xc374
;
; Algorithm is simply 
; tg(x) = sin(x)/cos(x) 
TANGENS:
    0e47  cd 32 0d   CALL COSINE (0d32)        ; Calculate cosine and store result at 0xc37b

    0e4a  21 65 c3   LXI HL, c365
    0e4d  cd 8c 0a   CALL 0a8c
    0e50  21 7b c3   LXI HL, c37b
    0e53  cd 92 0a   CALL 0a92

    0e56  cd 87 0c   CALL 0c87                  ; Calculate sine and store result at 0xc374

    0e59  21 65 c3   LXI HL, c365
    0e5c  cd 8c 0a   CALL 0a8c
    0e5f  21 74 c3   LXI HL, c374
    0e62  cd 92 0a   CALL 0a92

    0e65  21 7b c3   LXI HL, c37b               ; Restore cosine value to 0xc371
    0e68  cd 8c 0a   CALL 0a8c
    0e6b  21 71 c3   LXI HL, c371
    0e6e  cd 92 0a   CALL 0a92

    0e71  cd 6f 0a   CALL 0a6f                  ; Divide sine by cosine

    0e74  c9         RET

0E70                 21 62 C3 7E E6 80 F5 7E E6 7F 77
0E80  21 64 C3 36 01 23 AF 77 23 77 23 77 23 36 01 23
0E90  36 20 23 77 23 36 02 23 36 20 23 77 CD 15 0F 21
0EA0  74 C3 CD 8C 0A 21 6E C3 CD 92 0A CD 34 0F CD 15
0EB0  0F 21 75 C3 7E 17 3F 1F 77 21 6E C3 CD 8C 0A 21
0EC0  71 C3 CD 92 0A CD 87 09 21 65 C3 CD 8C 0A 21 71
0ED0  C3 CD 92 0A CD 87 09 21 74 C3 CD 8C 0A 21 65 C3
0EE0  CD 92 0A 21 72 C3 7E 17 3F 1F 77 CD 77 08 CD DD
0EF0  08 21 75 C3 7E E6 7F CA 00 0F CD 34 0F C3 9C 0A
0F00  23 7E FE 02 DA 0D 0F CD 34 0F C3 9C 0E 21 66 C3
0F10  46 F1 B0 77 C9 

; Calculate the next arcsine member (without coefficient)
; res = x^n/n
; 
; Implementation:
; 0xc374 = 0xc361 ^ 0xc364 / 0xc368
ARCSIN_MEMBER:
    0f15  21 61 c3   LXI HL, c361               ; Power 0xc361 into 0xc364 exp
    0f18  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0f1b  21 71 c3   LXI HL, c371
    0f1e  cd 92 0a   CALL STORE_ABC (0a92)
    
    0f21  cd 08 0b   CALL POWER (0b08)

    0f24  21 68 c3   LXI HL, c368               ; And divide by 0xc368
    0f27  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0f2a  21 71 c3   LXI HL, c371
    0f2d  cd 92 0a   CALL STORE_ABC (0a92)

    0f30  cd 6f 0a   CALL DIV_3_BYTE (0a6f)

    0f33  c9         RET

; Advance to the next member coefficients
; c368 += 2., c364 += 2
ARCSIN_ADVANCE:
    0f34  21 64 c3   LXI HL, c364               ; Advance next member index by 2
    0f37  34         INR M
    0f38  34         INR M

    0f39  21 68 c3   LXI HL, c368               ; Add 0xc368 and 2.
    0f3c  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0f3f  21 71 c3   LXI HL, c371
    0f42  cd 92 0a   CALL STORE_ABC (0a92)

    0f45  21 6b c3   LXI HL, c36b
    0f48  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0f4b  21 74 c3   LXI HL, c374
    0f4e  cd 92 0a   CALL STORE_ABC (0a92)

    0f51  cd 87 09   CALL ADD_FLOATS (0987)

    0f54  21 74 c3   LXI HL, c374               ; Store result at 0xc368
    0f57  cd 8c 0a   CALL LOAD_ABC (0a8c)
    0f5a  21 68 c3   LXI HL, c368
    0f5d  cd 92 0a   CALL STORE_ABC (0a92)

    0f60  c9         RET


; Cotangens function
;
; Argument: 0xc361, result: 0xc374
;
; Algorithm is simply 
; ctg(x) = cos(x)/sin(x) 
COTANGENS:
    0f61  cd 87 0c   CALL SINE (0c87)          ; Calculate Sine and store result at 0xc37b

    0f64  21 65 c3   LXI HL, c365
    0f67  cd 8c 0a   CALL 0a8c
    0f6a  21 7b c3   LXI HL, c37b
    0f6d  cd 92 0a   CALL 0a92

    0f70  cd 32 0d   CALL COSINE (0d32)        ; Calculate cosine and store result at 0xc374

    0f73  21 65 c3   LXI HL, c365
    0f76  cd 8c 0a   CALL 0a8c
    0f79  21 74 c3   LXI HL, c374
    0f7c  cd 92 0a   CALL 0a92
    
    0f7f  21 7b c3   LXI HL, c37b               ; Restore sine value
    0f82  cd 8c 0a   CALL 0a8c
    0f85  21 71 c3   LXI HL, c371
    0f88  cd 92 0a   CALL 0a92
    
    0f8b  cd 6f 0a   CALL DIV_3_BYTE (0a6f)     ; Calculate cos(x)/sin(x)
    
    0f8e  c9         RET
    




?????:
    0f8f  cd 75 0e   CALL 0e75


; Calculate arccosine
; res = Pi/2 - arg
; 
; Where
; 0xc365 - input and output value
CALC_ARCCOS:
    0f92  21 65 c3   LXI HL, c365               ; Load arcsin result to 0xc371
    0f95  cd 8c 0a   CALL 0a8c
    0f98  21 71 c3   LXI HL, c371
    0f9b  cd 92 0a   CALL 0a92

    0f9e  2b         DCX HL                     ; Flip its sign
    0f9f  7e         MOV A, M
    0fa0  17         RAL
    0fa1  3f         CMC
    0fa2  1f         RAR
    0fa3  77         MOV M, A

    0fa4  23         INX HL                     ; Load Pi/2 (1.570556640625) tp 0xc374
    0fa5  23         INX HL
    0fa6  36 01      MVI M, 01
    0fa8  23         INX HL
    0fa9  36 32      MVI M, 32
    0fab  23         INX HL
    0fac  36 42      MVI M, 42

    0fae  cd 87 09   CALL ADD_FLOATS (0987)     ; Move result to 0xc365

    0fb1  21 74 c3   LXI HL, c374
    0fb4  cd 8c 0a   CALL 0a8c
    0fb7  21 65 c3   LXI HL, c365
    0fba  cd 92 0a   CALL 0a92
    0fbd  c9         RET


0FB0                                            C3 87
0FC0  09 C3 EC 09 C3 6F 0A C3 C7 0F C3 98 0A C3 08 0B
0FD0  C3 D0 0F C3 6B 0B C3 87 0C C3 32 0D C3 47 0D C3
0FE0  40 0E C3 75 0E C3 61 0F C3 47 0E C3 8F 0F C3 49
0FF0  08 C3 DD 08 C3 94 09 C3 F9 09 C3 8C 0A C3 92 0A

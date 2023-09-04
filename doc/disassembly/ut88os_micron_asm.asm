; Description TBD
;
; Bugs/Inconsistencies:
; - This program expects 0x01-0x1f keycodes for Ctrl combinations.
;
; Variables:
; - below bf80  - stack area
; - bf80 - end of text pointer
; - bf82 - errors counter in BCD form
; - bf83 - current pass number (1, 2 ????)
; - bf84 - ???? error type
; - bf85 - Current output pointer (starting 0xa000)
; - bf87 - Current instruction target address
; - bf89 - parsed opcode's argument type
; - bf8a - register argument bitmask low bits (applied on top of base opcode)
; - bf8b - register argument bitmask high bits (applied on top of base opcode)
; - bf8c - parsed opcode (base opcode, without register bits applied)
; - bf8d - currently selected label record pointer (valid for lines starting with a label)
; - bf8f - currently processing line pointer
; - bf93 - temporary variable, meaning depends on the function
; - bf94 - working mode ????
; - bf95 - ????
; - bf98 - ORG offset (difference between ORG target address and target storage address 0xa000)
; - bfa0 - line buffer (0x40 bytes)
; - bfe0 - working buffer for parsing instruction mnemonic or instruction arguments (6 bytes)


START:
    d800  31 80 bf   LXI SP, bf80               ; Set up own stack

    d803  21 c5 df   LXI HL, HELLO_STR (dfc5)   ; Print the prompt string
    d806  cd 18 f8   CALL PRINT_STRING (f818)

    d809  cd 25 d8   CALL GET_KBD_INPUT (d825)  ; Get the mode

    d80c  cd 50 de   CALL PUT_CHAR (de50)       ; Echo entered char
    d80f  cd d3 dd   CALL PRINT_CR_LF (ddd3)

    d812  d6 31      SUI A, 31                  ; Chars < '1' are invalid - print the hint string
    d814  fa 1f d8   JM PRINT_HINT_AND_RESTART (d81f)

    d817  fe 03      CPI A, 03                  ; Chars > '3' are also invalid, restart the program
    d819  32 94 bf   STA WORKING_MODE (bf94)    ; Store the mode
    d81c  fa 2f d8   JM d82f

PRINT_HINT_AND_RESTART:
    d81f  21 d6 df   LXI HL, PLEASE_1_2_3_STR (dfd6)    ; Print the hint string, and restart the program
    d822  c3 4d db   JMP PRINT_ERROR_AND_RESTART (db4d)

; Wait for a keyboard input, return char in C
; If Ctrl-C is pressed - exit to Monitor
GET_KBD_INPUT:
    d825  cd 03 f8   CALL KBD_INPUT (f803)      ; Get the keyboard input
    d828  4f         MOV C, A

    d829  fe 03      CPI A, 03                  ; Check if Ctrl-C is pressed
    d82b  ca 65 f8   JZ MONITOR_RESTART_MAIN_LOOP (f865)    ; Hack: use direct call to Monitor, not 0xf800

    d82e  c9         RET                        ; Return otherwise

????:
    d82f  af         XRA A                      ;  ??? Zero something ?
    d830  32 95 bf   STA bf95

    d833  3c         INR A                      ; Start with pass #1
    d834  32 83 bf   STA PASS_NUMBER (bf83)

    d837  21 00 00   LXI HL, 0000               ; Zero target offset
    d83a  22 98 bf   SHLD ORG_OFFSET (bf98)

    d83d  21 00 30   LXI HL, 3000               ; Will search for end of text marker starting 0x3000

SEARCH_EOF_LOOP:
    d840  7e         MOV A, M                   ; Get next text character, and compare it with 0xff     
    d841  3c         INR A
    d842  23         INX HL
    d843  ca 4c d8   JZ EOF_FOUND (d84c)

    d846  cd 40 db   CALL CHECK_TEXT_SIZE (db40); Repeat until reached end of text area
    d849  c3 40 d8   JMP SEARCH_EOF_LOOP (d840)

EOF_FOUND:
    d84c  22 80 bf   SHLD EOF_PTR (bf80)        ; Store end of text pointer

    d84f  36 00      MVI M, 00                  ; Zero the char after the text

????:
    d851  21 00 30   LXI HL, 3000               ; Start processing from the very first line at 0x3000
    d854  22 8f bf   SHLD bf8f

    d857  21 00 a0   LXI HL, a000               ; Initialize current output pointer
    d85a  22 85 bf   SHLD CUR_OUTPUT_PTR (bf85)

    d85d  af         XRA A                      ; Reset the error counter
    d85e  32 82 bf   STA ERRORS_COUNT (bf82)

????:
    d861  af         XRA A                      ; ????
    d862  32 84 bf   STA bf84

    d865  2a 85 bf   LHLD CUR_OUTPUT_PTR (bf85) ; Save current output pointer as current instruction address
    d868  22 87 bf   SHLD CUR_OPCODE_TARGET_ADDR (bf87) ; (used for $ arithmetic)

    d86b  31 80 bf   LXI SP, EOF_PTR (bf80)     ; ????

    d86e  cd 9a da   CALL COPY_LINE_TO_BUF (da9a)   ; Aquire next line into the buffer

    d871  21 a0 bf   LXI HL, LINE_BUF (bfa0)    ; Get the first line symbol
    d874  7e         MOV A, M

    d875  fe 3b      CPI A, 3b                  ; Skip lines starting with semicolon (comment)
    d877  ca c4 d8   JZ ADVANCE_TO_NEXT_LINE (d8c4)

    d87a  cd cd da   CALL COPY_WORD_TO_WORK_BUF (dacd)  ; Copy instruction mnemonic to the working buffer

    d87d  fe 3a      CPI A, 3a                  ; Compare with ':'? Is this a label?
    d87f  c2 9b d8   JNZ d89b

    d882  af         XRA A                      ; There must be at least a few letters before ':'
    d883  b9         CMP C                      ; Otherwise indicate an error
    d884  ca 92 da   JZ da92

    d887  e5         PUSH HL
    d888  cd 12 db   CALL SAVE_LABEL (db12)
    d88b  e1         POP HL

    d88c  cd 0a db   CALL SEARCH_NON_SPACE_CHAR (db0a)  ; Look for the instruction start

    d88f  b7         ORA A                      ; If this is the end of the line - advance to the next line
    d890  ca c4 d8   JZ ADVANCE_TO_NEXT_LINE (d8c4)

    d893  fe 3b      CPI A, 3b                  ; String after the semicolon is a comment - skip it
    d895  ca c4 d8   JZ ADVANCE_TO_NEXT_LINE (d8c4)

    d898  cd cd da   CALL COPY_WORD_TO_WORK_BUF (dacd)  ; Otherwise get ready to parse the command


????:
    d89b  e5         PUSH HL                    ; Parse instruction mnemonic
    d89c  cd 0d dd   CALL PARSE_MNEMONIC (dd0d)
    d89f  e1         POP HL

    d8a0  cd b2 db   CALL PARSE_EXPRESSION (dbb2)   ; ??? Parse first argument ????

    d8a3  e5         PUSH HL                    ; Load pointer to output handlers
    d8a4  21 53 de   LXI HL, OUTPUT_HANDLERS_TABLE (de53)

    d8a7  3a 89 bf   LDA OPCODE_ARG_TYPE (bf89) ; Calculate the handler's address based on the argument type
    d8aa  5f         MOV E, A
    d8ab  16 00      MVI D, 00
    d8ad  19         DAD DE
    d8ae  19         DAD DE

    d8af  5e         MOV E, M                   ; Load the handler value
    d8b0  23         INX HL

    d8b1  7e         MOV A, M                   ; ????? Where C gets its values? Is this instruction bytes count?
    d8b2  b9         CMP C
    d8b3  c2 8d da   JNZ da8d

    d8b6  21 d9 d8   LXI HL, OUTPUT_HANDLER_BASE (d8d9) ; Load the base handler address, add offset
    d8b9  19         DAD DE

    d8ba  11 c4 d8   LXI DE, ADVANCE_TO_NEXT_LINE (d8c4)    ; Store exit pointer on the stack
    d8bd  eb         XCHG
    d8be  e3         XTHL

    d8bf  d5         PUSH DE                    ; Push handler's address to stack

    d8c0  3a 8b bf   LDA OPCODE_REGISTER_ARG_HIGH (bf8b)    ; Load the opcode argument in A
    d8c3  c9         RET                        ; Jump to handler

ADVANCE_TO_NEXT_LINE:
    d8c4  cd 80 dd   CALL dd80                  ; ????

    d8c7  cd 12 f8   CALL MONITOR_IS_BUTTON_PRESSED (f812)  ; Check if a button is pressed
    d8ca  00         NOP
    d8cb  ca 61 d8   JZ d861

    d8ce  cd 25 d8   CALL GET_KBD_INPUT (d825)  ; If yes - this may be a Ctrl-C
    d8d1  fe 03      CPI A, 03
    d8d3  ca 00 d8   JZ START (d800)            ; Ctrl-C will restart the program

    d8d6  c3 61 d8   JMP d861                   ; If not - process the next line


OUTPUT_HANDLER_BASE:                            ; Just an anchor, handlers' offsets are calculated from here

; Output 1-byte MOV instruction with source and destination register arguments
OUTPUT_HANDLER_1B_MOV:
    d8d9  f6 40      ORI A, 40                  ; MOV is the only instruction processed by this handler.
    d8db  32 8c bf   STA BASE_OPCODE (bf8c)     ; The base opcode is 0x40

    d8de  cd 9a db   CALL PARSE_2ND_REG_ARG (db9a)  ; Destination register is parsed by now, parse source register

; Output 1-byte instruction with source register coded in 3 lower bits
OUTPUT_HANDLER_1B_SRC_REG:
    d8e1  3a 8a bf   LDA OPCODE_REGISTER_ARG_LOW (bf8a) ; Apply 3 lower register bits

; Output 1-byte instruction with no arguments
OUTPUT_HANDLER_1B_NO_ARGS:
    d8e4  c3 32 da   JMP STORE_OPCODE_TO_OUTPUT (da32)

; Output 2-byte MVI instruction, with destination reg coded in the opcode, and 1-byte immediate value
OUTPUT_HANDLER_2B_MVI:
    d8e7  f6 06      ORI A, 06                      ; MVI is the only instruction of this type
    d8e9  32 8c bf   STA BASE_OPCODE (bf8c)         ; The base opcode is 0x06

    d8ec  cd 9a db   CALL PARSE_2ND_REG_ARG (db9a)  ; Parse the destination re

; Output 2-byte instruction, with no destination reg bits. Second byte is an immediate value
OUTPUT_HANDLER_2B_IMMEDIATE:
    d8ef  0e 01      MVI C, 01                      ; 1 byte of the immediate argument to store
    d8f1  c3 40 da   JMP STORE_IMMEDIATE_ARG (da40)

; Output 3-byte LXI instruction, with register pair coded in 4-5th bits, and 2-byte immediate value
OUTPUT_HANDLER_3B_LXI:
    d8f4  cd 56 da   CALL PARSE_REG_PAIR (da56)     ; Parse register pair name

    d8f7  f6 01      ORI A, 01                      ; 0x01 is a base opcode for LXI instruction
    d8f9  32 8c bf   STA BASE_OPCODE (bf8c)

    d8fc  cd 9a db   CALL PARSE_2ND_REG_ARG (db9a)  ; Parse immediate argument

; Store a 3-byte instruction with a 2-byte immediate argument
OUTPUT_HANDLER_3B_IMMEDIATE_ARG:
    d8ff  0e 02      MVI C, 02                      ; Store 2 bytes of the immediate value
    d901  c3 40 da   JMP STORE_IMMEDIATE_ARG (da40)

; Output a 1-byte instruction with register pair coded in the opcode
OUTPUT_HANDLER_1B_REG_PAIR:
    d904  cd 56 da   CALL PARSE_REG_PAIR (da56)    ; Parse register pair name

; Output 1-byte instruction with 1 argument (register name is coded in the opcode)
OUTPUT_HANDLER_1B_1_REG_ARG:
    d907  c3 32 da   JMP STORE_OPCODE_TO_OUTPUT (da32)

; Output 1-byte PUSH or POP instruction (register pair is coded in the opcode)
OUTPUT_HANDLER_1B_PUSH_POP:
    d90a  cd 5e da   CALL PARSE_REG_PAIR_PSW (da5e)     ; Parse register pair name
    d90d  c3 32 da   JMP STORE_OPCODE_TO_OUTPUT (da32)  ; Store resulting opcode

; Output 1-byte LDAX/STAX instruction, register pair name is coded in the 5th bit
OUTPUT_HANDLER_1B_STAX_LDAX:
    d910  cd 66 da   CALL PARSE_REG_PAIR_BC_DE (da66)   ; Parse register pair name
    d913  c3 32 da   JMP STORE_OPCODE_TO_OUTPUT (da32)  ; Store resulting opcode

; Output 1-byte RST instruction, rst number is coded in the 3-5th bits of the opcode
OUTPUT_HANDLER_1B_RST:
    d916  3a 8a bf   LDA OPCODE_REGISTER_ARG_LOW (bf8a) ; RST number shall be parsed as a part of mnemonic+arg
    d919  47         MOV B, A                           ; parsing routine

    d91a  e6 07      ANI A, 07                          ; Verify the number does not exceed 0x07, otherwise
    d91c  b8         CMP B                              ; report an error
    d91d  c2 8d da   JNZ da8d

    d920  07         RLC                                ; Shift to 3-5th bits
    d921  07         RLC
    d922  07         RLC

    d923  c3 32 da   JMP STORE_OPCODE_TO_OUTPUT (da32)  ; And store the opcode

DS_HANDLER:
    d926  2a 85 bf   LHLD CUR_OUTPUT_PTR (bf85)         ; Load the current storage target address to DE
    d929  eb         XCHG

    d92a  2a 8a bf   LHLD OPCODE_REGISTER_ARG_LOW (bf8a)    ; Load the argument to HL

    d92d  19         DAD DE                             ; Advance current storage pointer with the argument value
    d92e  22 85 bf   SHLD CUR_OUTPUT_PTR (bf85)

    d931  c9         RET                                ; Done
    
; Parse EQU line
; 
; Expected line format:
; <label>: EQU <value>
;
; The value is stored in the labels area
EQU_HANDLER:
    d932  21 a0 bf   LXI HL, LINE_BUF (bfa0)            ; We need to start parsing the whole string, not just
    d935  cd cd da   CALL COPY_WORD_TO_WORK_BUF (dacd)  ; value (as it would for other handlers)

    d938  fe 3a      CPI A, 3a                          ; The line must start with the label (which is loaded by
    d93a  c2 92 da   JNZ da92                           ; COPY_WORD_TO_WORK_BUF), then ':' colon. Otherwise error.

    d93d  2a 8a bf   LHLD OPCODE_REGISTER_ARG_LOW (bf8a); Store EQU value in a temporary variable
    d940  22 87 bf   SHLD CUR_OPCODE_TARGET_ADDR (bf87)

    d943  eb         XCHG                               ; Load EQU value to DE as well

    d944  3a 83 bf   LDA PASS_NUMBER (bf83)             ; Perform EQU loading only on pass #1, skip on other
    d947  3d         DCR A                              ; passes
    d948  c0         RNZ

    d949  3a 84 bf   LDA bf84                           ; ???? Return if error mask is 01, pass otherwise ???
    d94c  3d         DCR A
    d94d  c8         RZ

    d94e  fa 54 d9   JM EQU_HANDLER_1 (d954)            ; Skip if there were no errors so far

    d951  11 fe ff   LXI DE, fffe                       ; Set the value to 0xfffe magic number in case of error

EQU_HANDLER_1:
    d954  2a 8d bf   LHLD CUR_LABEL_VALUE_PTR (bf8d)    ; Store the EQU value to the label record
    d957  73         MOV M, E
    d958  23         INX HL
    d959  72         MOV M, D
    d95a  c9         RET


; Parse DB and DW directive arguments, store data to the output
DB_DW_HANDLER:
    d95b  eb         XCHG                       ; Load source argument pointer in DE

    d95c  2a 85 bf   LHLD CUR_OUTPUT_PTR (bf85) ; Load output address to HL

    d95f  1a         LDAX DE                    ; Check if the argument starts with a quote
    d960  fe 27      CPI A, 27
    d962  c2 76 d9   JNZ DB_DW_HANDLER_1 (d976)

    d965  13         INX DE

DB_DW_HANDLER_QUOTE_LOOP:
    d966  1a         LDAX DE                    ; Load the symbol in quotes
    d967  13         INX DE

    d968  b7         ORA A                      ; EOL is a syntax error
    d969  ca 8d da   JZ da8d

    d96c  fe 27      CPI A, 27                  ; Stop parsing on closing quote
    d96e  ca 88 d9   JZ DB_DW_HANDLER_STORE (d988)

    d971  77         MOV M, A                   ; Store the symbol to the output
    d972  23         INX HL

    d973  c3 66 d9   JMP DB_DW_HANDLER_QUOTE_LOOP (d966); Advance to the next symbol until closing quote is found

DB_DW_HANDLER_1:
    d976  3a 8a bf   LDA OPCODE_REGISTER_ARG_LOW (bf8a) ; Store the parsed by to the output
    d979  77         MOV M, A

    d97a  23         INX HL                         ; Advance to the next output byte

    d97b  3a 89 bf   LDA OPCODE_ARG_TYPE (bf89)     ; If this is 'DB' directive - we are done
    d97e  fe 0e      CPI A, 0e
    d980  ca 88 d9   JZ DB_DW_HANDLER_STORE (d988)

    d983  3a 8b bf   LDA OPCODE_REGISTER_ARG_HIGH (bf8b); For 'DW' directive save the second byte as well
    d986  77         MOV M, A
    d987  23         INX HL

DB_DW_HANDLER_STORE:
    d988  22 85 bf   SHLD CUR_OUTPUT_PTR (bf85)     ; Store the new output pointer

    d98b  eb         XCHG                           ; Look whether there is another byte/word specified
    d98c  cd 0a db   CALL SEARCH_NON_SPACE_CHAR (db0a)

    d98f  b7         ORA A                          ; Stop processing if no more data
    d990  c8         RZ

    d991  fe 3b      CPI A, 3b                      ; Stop parsing on semicolon (everything else is a comment)
    d993  c8         RZ

    d994  cd 9a db   CALL PARSE_2ND_REG_ARG (db9a)  ; Parse the next item
    d997  c3 5b d9   JMP DB_DW_HANDLER (d95b)


; Process ORG directive, cakculate difference between output storage address and code target address
ORG_HANDLER:
    d99a  3a 95 bf   LDA bf95                   ; Allow having only one ORG directive, otherwise return
    d99d  b7         ORA A
    d99e  c0         RNZ

    d99f  3c         INR A                      ; Set the flag that ORG directive was already used
    d9a0  32 95 bf   STA bf95

    d9a3  21 00 a0   LXI HL, a000               ; Load the default target address 0xa000 to DE
    d9a6  eb         XCHG

    d9a7  2a 8a bf   LHLD OPCODE_REGISTER_ARG_LOW (bf8a)    ; Load the new ORG address to HL

    d9aa  cd 20 da   CALL SUB_HL_DE (da20)      ; Calculate difference between ORG address and target address

    d9ad  22 98 bf   SHLD ORG_OFFSET (bf98)     ; Store the difference in the var

    d9b0  c9         RET


????:
    d9b1  cd 80 dd   CALL dd80                  ; ????

d9b4  21 83 bf   LXI HL, PASS_NUMBER (bf83)
d9b7  7e         MOV A, M

d9b8  34         INR M                      ; Increment current pass number ????
d9b9  3d         DCR A                      ; ????
d9ba  ca 51 d8   JZ d851

d9bd  3a 94 bf   LDA WORKING_MODE (bf94)
d9c0  fe 02      CPI A, 02
d9c2  c2 fc d9   JNZ d9fc

    d9c5  0e 1f      MVI C, 1f              ; Clear screen
    d9c7  cd 50 de   CALL PUT_CHAR (de50)

d9ca  2a 80 bf   LHLD EOF_PTR (bf80)

????:
d9cd  06 06      MVI B, 06

????:
d9cf  7e         MOV A, M
d9d0  b7         ORA A
d9d1  ca fc d9   JZ d9fc

d9d4  4f         MOV C, A
d9d5  cd 50 de   CALL PUT_CHAR (de50)

d9d8  05         DCR B
d9d9  23         INX HL
d9da  c2 cf d9   JNZ d9cf
d9dd  0e 3d      MVI C, 3d
d9df  cd 50 de   CALL PUT_CHAR (de50)
d9e2  0e 20      MVI C, 20
d9e4  cd 50 de   CALL PUT_CHAR (de50)
d9e7  23         INX HL
d9e8  7e         MOV A, M
d9e9  cd 42 de   CALL PRINT_BYTE_HEX (de42)
d9ec  2b         DCX HL
d9ed  7e         MOV A, M
d9ee  cd 42 de   CALL PRINT_BYTE_HEX (de42)
d9f1  23         INX HL
d9f2  23         INX HL
d9f3  01 20 04   LXI BC, 0420
d9f6  cd 27 da   CALL PRINT_CHAR_BLOCK (da27)
d9f9  c3 cd d9   JMP d9cd

????:
    d9fc  21 b3 df   LXI HL, ERRORS_STR (dfb3)      ; Print report string
    d9ff  cd 18 f8   CALL PRINT_STRING (f818)

    da02  3a 82 bf   LDA ERRORS_COUNT (bf82)        ; Print number of errors
    da05  cd 42 de   CALL PRINT_BYTE_HEX (de42)
    da08  cd d3 dd   CALL PRINT_CR_LF (ddd3)

    da0b  2a 85 bf   LHLD CUR_OUTPUT_PTR (bf85)     ; Load last output byte pointer to DE
    da0e  2b         DCX HL
    da0f  eb         XCHG

    da10  2a 98 bf   LHLD ORG_OFFSET (bf98)         ; Apply the org offset
    da13  19         DAD DE

    da14  0e 2f      MVI C, 2f                      ; Print ??? address followed by '/'
    da16  cd 48 de   CALL PRINT_WORD_HEX (de48)

    da19  eb         XCHG                           ; Print last output address, follower by '/'
    da1a  cd 48 de   CALL PRINT_WORD_HEX (de48)

    da1d  c3 00 d8   JMP START (d800)               ; Restart the program

SUB_HL_DE:
    da20  7d         MOV A, L
    da21  93         SUB E
    da22  6f         MOV L, A
    da23  7c         MOV A, H
    da24  9a         SBB D
    da25  67         MOV H, A
    da26  c9         RET

; Print char in C register B times
PRINT_CHAR_BLOCK:
    da27  04         INR B                      ; Do nothing if B==0
    da28  05         DCR B
    da29  c8         RZ

PRINT_CHAR_BLOCK_LOOP:
    da2a  cd 50 de   CALL PUT_CHAR (de50)       ; Print C

    da2d  05         DCR B                      ; Repeat B times
    da2e  c8         RZ
    da2f  c3 2a da   JMP PRINT_CHAR_BLOCK_LOOP (da2a)


; ??????
STORE_OPCODE_TO_OUTPUT:
    da32  47         MOV B, A                   ; Apply register bits to the base opcode
    da33  3a 8c bf   LDA BASE_OPCODE (bf8c)
    da36  b0         ORA B

    da37  2a 85 bf   LHLD CUR_OUTPUT_PTR (bf85) ; Store opcode to the output

STORE_BYTE_TO_OUTPUT:
    da3a  77         MOV M, A                   ; Store byte to output

    da3b  23         INX HL                     ; Increment output pointer

STORE_BYTE_TO_OUTPUT_EXIT:
    da3c  22 85 bf   SHLD CUR_OUTPUT_PTR (bf85) ; Store output pointer
    da3f  c9         RET


; Store 2- or 3-byte instruction with 1 or 2 bytes of the immediate argument
STORE_IMMEDIATE_ARG:
    da40  2a 8a bf   LHLD OPCODE_REGISTER_ARG_LOW (bf8a)    ; Load the argument byte(s) to (D)E
    da43  eb         XCHG

    da44  2a 85 bf   LHLD CUR_OUTPUT_PTR (bf85) ; Store the opcode
    da47  3a 8c bf   LDA BASE_OPCODE (bf8c)
    da4a  77         MOV M, A

    da4b  23         INX HL                     ; Store first byte of the argument
    da4c  73         MOV M, E
    da4d  23         INX HL

    da4e  0d         DCR C                      ; Check how many bytes to store
    da4f  ca 3c da   JZ STORE_BYTE_TO_OUTPUT_EXIT (da3c)    ; If only 1 byte of the argument to store - just exit

    da52  7a         MOV A, D                   ; Store the second byte and exit
    da53  c3 3a da   JMP STORE_BYTE_TO_OUTPUT (da3a)


; Parse register pair code into register bits
; Register pair code is a derivative from register name parsing. It is passed in A register as a parameter,
; and can have the following values:
; - 0x40 - for SP register      - produce 0x30 value as result
; - 0x48 - for PSW register     - produce 0x30 value as result (used in PUSH/POP instructions)
; - 0x20 - for HL register pair - produce 0x20 value as result
; - 0x10 - for DE register pair - produce 0x10 value as result
; - 0x00 - for BC register pair - produce 0x00 value as result
; - other values flag an error
;
; The function has 3 entry points:
; - PARSE_REG_PAIR for parsing all 4 register pairs (BC/DE/HL/SP) 
; - PARSE_REG_PAIR_PSW for parsing all 4 register pairs, but PSW instead of SP
; - PARSE_REG_PAIR_BC_DE for parsing only BC and DE register pairs (used for LDAX/STAX instructions)
; 
; Returns register bits in A register
PARSE_REG_PAIR:
    da56  fe 40      CPI A, 40                  ; 0x40 will appear in A in case of SP register

PARSE_REG_PAIR_1:
    da58  c2 63 da   JNZ PARSE_REG_PAIR_2 (da63); If not - check other options below

    da5b  3e 30      MVI A, 30                  ; 0x30 is be the register bits code for SP or PSW registers
    da5d  c9         RET

PARSE_REG_PAIR_PSW:
    da5e  fe 48      CPI A, 48                  ; 0x48 will appear in A in case of PSW register pair
    da60  c3 58 da   JMP PARSE_REG_PAIR_1 (da58)

PARSE_REG_PAIR_2:
    da63  fe 20      CPI A, 20                  ; 0x20 is the register bits code for HL register pair
    da65  c8         RZ

PARSE_REG_PAIR_BC_DE:
    da66  fe 10      CPI A, 10                  ; 0x10 is the register bits code for DE register pair
    da68  c8         RZ

    da69  b7         ORA A                      ; 0x00 is the register bits code for BC register pair
    da6a  c2 8d da   JNZ da8d

    da6d  c9         RET                        ; Other values are incorrect. Report an error


????:
da6e  06 01      MVI B, 01
da70  c3 78 da   JMP da78

????:
da73  06 02      MVI B, 02
da75  11 fe ff   LXI DE, fffe

????:
    da78  e5         PUSH HL

    da79  21 84 bf   LXI HL, bf84                   ; Apply error type mask
    da7c  7e         MOV A, M                       
    da7d  b0         ORA B
    da7e  77         MOV M, A

    da7f  21 82 bf   LXI HL, ERRORS_COUNT (bf82)    ; Increment error counter
    da82  7e         MOV A, M
    da83  3c         INR A
    da84  27         DAA
    da85  77         MOV M, A

    da86  e1         POP HL
    da87  c9         RET

; Instruction match error ???? Syntax error ???
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
da97  c3 c4 d8   JMP ADVANCE_TO_NEXT_LINE (d8c4)


; Copy next line from source text area to the line buffer (0xbfa0)
; Copy up to 0x40 bytes from current line in source text to the line buffer at 0xbfa0
COPY_LINE_TO_BUF:
    da9a  11 a0 bf   LXI DE, LINE_BUF (bfa0)    ; Will copy up to 0x40 chars into the 0xbfa0 buffer
    da9d  0e 40      MVI C, 40
    da9f  2a 8f bf   LHLD CUR_LINE_PTR (bf8f)   ; Starting the current line pointer

COPY_LINE_TO_BUF_LOOP:
    daa2  7e         MOV A, M                   ; Load the next symbol from source

    daa3  fe ff      CPI A, ff                  ; 0xff EOF marker will stop processing
    daa5  ca b1 d9   JZ d9b1

    daa8  fe 0d      CPI A, 0d                  ; 0x0d EOL symbol will finish copying the current line
    daaa  ca c0 da   JZ COPY_LINE_TO_BUF_LINE_COMPLETED (dac0)

    daad  fe 09      CPI A, 09                  ; 0x09 tab symbols will be treated as spaces
    daaf  c2 b4 da   JNZ COPY_LINE_TO_BUF_STORE_CHAR (dab4)

    dab2  3e 20      MVI A, 20                  ; Replace tab with a space

COPY_LINE_TO_BUF_STORE_CHAR:
    dab4  12         STAX DE                    ; Store the symbol to the lin buffer

    dab5  af         XRA A                      ; Check if we reached end of the buffer. Too long lines will be
    dab6  b9         CMP C                      ; truncated to just 0x40 chars
    dab7  ca bc da   JZ COPY_LINE_TO_BUF_NEXT_CHAR (dabc)

    daba  13         INX DE                     ; If not - advance to the next char in the buffer, decrement
    dabb  0d         DCR C                      ; remaining chars counter

COPY_LINE_TO_BUF_NEXT_CHAR:
    dabc  23         INX HL                     ; Advance to the next source char, and repeat
    dabd  c3 a2 da   JMP COPY_LINE_TO_BUF_LOOP (daa2)

COPY_LINE_TO_BUF_LINE_COMPLETED:
    dac0  af         XRA A                      ; Terminate the line buffer with zero
    dac1  12         STAX DE

    dac2  23         INX HL                     ; Set HL to the beginning of the next line

    dac3  79         MOV A, C                   ; Check if line buffer is still empty. Read another line.
    dac4  fe 40      CPI A, 40
    dac6  ca a2 da   JZ COPY_LINE_TO_BUF_LOOP (daa2)

    dac9  22 8f bf   SHLD CUR_LINE_PTR (bf8f)   ; Store the new line pointer
    dacc  c9         RET


; Copy up to 6 chars literal to the working buffer 0xbfe0
;
; The function algorithm:
; - The output buffer is filled with spaces
; - Skip leading spaces on input
; - Copied literal must start with a letter
; - Up to 6 chars are copies (or until a non-alpha numeric character is met. EOF symbol 0x80 also stops the
;   copying)
;
; Arguments:
; HL - pointer in the source buffer
;
; The function fills the buffer with spaces. Upon return C indicates number of chars in the buffer
COPY_WORD_TO_WORK_BUF:
    dacd  0e 06      MVI C, 06                  ; Will fill 0xbfe0 buffer with 6 spaces
    dacf  11 e0 bf   LXI DE, bfe0
    dad2  d5         PUSH DE
    dad3  3e 20      MVI A, 20

COPY_WORD_TO_WORK_BUF_CLEAR_LOOP:
    dad5  12         STAX DE                    ; Store the next space symbol
    dad6  13         INX DE
    dad7  0d         DCR C
    dad8  c2 d5 da   JNZ COPY_WORD_TO_WORK_BUF_CLEAR_LOOP (dad5)

    dadb  d1         POP DE                     ; Skip spaces in the beginning of the string
    dadc  cd 0a db   CALL SEARCH_NON_SPACE_CHAR (db0a)

    dadf  fe 3f      CPI A, 3f                  ; Symbols below 0x40 (symbols, not letters) will stop copying
    dae1  f8         RM                         ; the literal

    dae2  fe 80      CPI A, 80                  ; Symbols with codes >= 0x80 will also stop processing the line
    dae4  f0         RP                         ; as well

COPY_WORD_TO_WORK_BUF_LOOP:
    dae5  47         MOV B, A                   ; Store loaded symbol in B

    dae6  79         MOV A, C                   ; Copy up to 6 characters into the buffer (symbols above 6-char
    dae7  fe 06      CPI A, 06                  ; length will not be copied, but processed looking for an end
    dae9  ca f0 da   JZ COPY_WORD_TO_WORK_BUF_1 (daf0)  ; of the word)

    daec  78         MOV A, B                   ; Store char to the output buffer
    daed  12         STAX DE

    daee  13         INX DE                     ; Advance to the next symbol
    daef  0c         INR C

COPY_WORD_TO_WORK_BUF_1:
    daf0  23         INX HL                     ; Look up for the next source char
    daf1  7e         MOV A, M

    daf2  fe 30      CPI A, 30                  ; Chars < 0x30 will stop copying instruction, advance to the
    daf4  fa 0a db   JM SEARCH_NON_SPACE_CHAR (db0a)    ; next non-space char

    daf7  fe 3a      CPI A, 3a                  ; ':' colon symbol probably means a label. Stop copying.
    daf9  ca 08 db   JZ COPY_WORD_TO_WORK_BUF_2 (db08)

    dafc  fa e5 da   JM COPY_WORD_TO_WORK_BUF_LOOP (dae5)   ; Symbols below 0x3a stop copying

    daff  fe 40      CPI A, 40                  ; Also stop on symbols between 0x3b and 0x40
    db01  f8         RM

    db02  fe 80      CPI A, 80                  ; Repeat for the next char, stop on char codes >= 80
    db04  fa e5 da   JM COPY_WORD_TO_WORK_BUF_LOOP (dae5)

    db07  c9         RET

COPY_WORD_TO_WORK_BUF_2:                                           
    db08  23         INX HL                     ; Advance to the next source char
    db09  c9         RET


; Look for a non space character in a string pointed by HL
SEARCH_NON_SPACE_CHAR:
    db0a  7e         MOV A, M                   ; Compare next char with a space
    db0b  fe 20      CPI A, 20
    db0d  c0         RNZ                        ; Return if non-space char found

    db0e  23         INX HL                     ; Advance to the next symbol and repeat
    db0f  c3 0a db   JMP SEARCH_NON_SPACE_CHAR (db0a)


; Create new label record
;
; The function searches a slot in the labels area, and creates a new label record there.
;
; The label record are has the following structure:
; - Array of items of the following format:
;   - 6 char label (padded with spaces, if the label is shorter than 6 chars)
;   - 2-byte label value
; - the array is terminated with a zero byte
;
; The label value may be used in 2 ways:
; - target address of the instruction that has a label
; - value assigned with EQU directive
;
; The label is added only during 1st pass. If the label is added more than once, the value is set to 0xffff
; special value, indicating an error.
SAVE_LABEL:
    db12  cd 79 db   CALL SEARCH_LABEL_RECORD (db79)    ; Check whether the label with the same name exists ???

    db15  3a 83 bf   LDA PASS_NUMBER (bf83)     ; Store values only during the first pass, on the second pass
    db18  3d         DCR A                      ; just verify whether the value is correct
    db19  c2 5e db   JNZ SAVE_LABEL_2ND_PASS (db5e)

    db1c  b9         CMP C                      ; Check if the label already exists, mark it as incorrect
    db1d  ca 59 db   JZ CLEAR_LABEL_ADDRESS (db59)

    db20  11 e0 bf   LXI DE, bfe0               ; Save the new label - copy 6 chars from bfe0 to HL (next slot
    db23  0e 06      MVI C, 06                  ; found by the SEARCH_LABEL_RECORD function)

SAVE_LABEL_COPY_LOOP:
    db25  1a         LDAX DE                    ; Copy symbol
    db26  77         MOV M, A

    db27  13         INX DE                     ; Advance to the next char
    db28  23         INX HL

    db29  0d         DCR C                      ; Repeat for all 6 chars
    db2a  c2 25 db   JNZ SAVE_LABEL_COPY_LOOP (db25)

    db2d  22 8d bf   SHLD CUR_LABEL_VALUE_PTR (bf8d)    ; Store the pointer to the label record
    db30  e5         PUSH HL

    db31  2a 85 bf   LHLD CUR_OUTPUT_PTR (bf85) ; Load label target address to DE
    db34  eb         XCHG

    db35  2a 98 bf   LHLD ORG_OFFSET (bf98)     ; Apply ORG offset if needed
    db38  19         DAD DE
    db39  eb         XCHG                       ; Store result to DE

    db3a  e1         POP HL                     ; Store label target address right after the label text
    db3b  73         MOV M, E
    db3c  23         INX HL
    db3d  72         MOV M, D

    db3e  23         INX HL                     ; Store terminating zero
    db3f  71         MOV M, C


; Check if the pointer is within the text size limit
; If HL is greater than SP-0x10 an error will be fired
;
; Argument:
; HL - pointer to check
CHECK_TEXT_SIZE:
    db40  eb         XCHG                       ; HL points to a symbol in a text area
    db41  21 f0 ff   LXI HL, fff0               ; DE = stack pointer - 0x10
    db44  39         DAD SP
    db45  eb         XCHG

    db46  cd 53 db   CALL CMP_HL_DE (db53)      ; Check if HL (current ptr) reaches DE (stack and vars area)
    db49  d8         RC

    db4a  21 eb df   LXI HL, TOO_LONG_STR (dfeb); Report a 'text too long' error and restart the program


; Print an error message pointed by HL, then restart the application
PRINT_ERROR_AND_RESTART:
    db4d  cd 18 f8   CALL PRINT_STRING (f818)   ; Print the error string, and restart the program
    db50  c3 00 d8   JMP START (d800)


; Compare HL and DE, set Z and C flags accordingly
CMP_HL_DE:
    db53  7c         MOV A, H
    db54  ba         CMP D
    db55  c0         RNZ
    db56  7d         MOV A, L
    db57  bb         CMP E
    db58  c9         RET

; Special code to 'corrupt' the label value, and set it to 0xffff
CLEAR_LABEL_ADDRESS:
    db59  3d         DCR A                      ; Save 0xffff as a label value
    db5a  77         MOV M, A
    db5b  23         INX HL
    db5c  77         MOV M, A
    db5d  c9         RET


; On the second pass the function just checks the value, and reports an error if the value is either
; 0xffff, or 0xfefe
SAVE_LABEL_2ND_PASS:
    db5e  46         MOV B, M                   ; Load the label calue
    db5f  23         INX HL
    db60  7e         MOV A, M

    db61  fe ff      CPI A, ff                  ; If it is not a 0xffff - that is a correct value, just return
    db63  c0         RNZ

    db64  b8         CMP B                      ; Report an error if the value is 0xffff
    db65  ca 6e da   JZ da6e

    db68  3d         DCR A                      ; Also report an error if the value is 0xfefe
    db69  b8         CMP B
    db6a  ca 73 da   JZ da73

    db6d  c9         RET                        ; Otherwise consider it as a normal value


; Search for a label record, and return a label pointer
GET_LABEL_VALUE:
    db6e  cd 79 db   CALL SEARCH_LABEL_RECORD (db79)    ; Search for a label record

    db71  0d         DCR C                      ; If no label record matched - raise an error
    db72  f2 73 da   JP da73

    db75  5e         MOV E, M                   ; Return the label pointer in DE
    db76  23         INX HL
    db77  56         MOV D, M
    db78  c9         RET


; Search for a label record in the records area (after the main text)
;
; The function searches for a record, that matches label in the working buffer (0xbfe0) and returns the pointer
; to the record
;
; The function expects:
; - Label records are stored after the EOF
; - Label to match is in the working buffer (0xbfe0)
;
; Return:
; - C=0x00 in case of match, HL points to the label pointer field
; - C=0x06 if no matches found
SEARCH_LABEL_RECORD:
    db79  2a 80 bf   LHLD EOF_PTR (bf80)                ; Look for a end of labels array, starting the EOF pointer

SEARCH_LABEL_RECORD_LOOP:
    db7c  0e 06      MVI C, 06                          ; If the byte at pointer is zero - we reached the end of
    db7e  af         XRA A                              ; the table - return 
    db7f  be         CMP M
    db80  c8         RZ

    db81  e5         PUSH HL                            ; Save the current record pointer

    db82  11 e0 bf   LXI DE, bfe0                       ; Will match with the working buffer

SEARCH_LABEL_RECORD_CHAR_LOOP:
    db85  1a         LDAX DE                            ; Compare if the label in the buffer matches the label
    db86  be         CMP M                              ; in the labels array
    db87  ca 92 db   JZ SEARCH_LABEL_RECORD_1 (db92)

    db8a  e1         POP HL                             ; If not - advance by 8 bytes (6 chars is a label length,
    db8b  01 08 00   LXI BC, 0008                       ; and 2 bytes label pointer)
    db8e  09         DAD BC

    db8f  c3 7c db   JMP SEARCH_LABEL_RECORD_LOOP (db7c)

SEARCH_LABEL_RECORD_1:
    db92  13         INX DE                             ; Advance to the next byte
    db93  23         INX HL

    db94  0d         DCR C                              ; Repeat until all 6 chars of the label are matched
    db95  c2 85 db   JNZ SEARCH_LABEL_RECORD_CHAR_LOOP (db85)

    db98  d1         POP DE                             ; If all chars are matched - return the label pointer
    db99  c9         RET


; Parse an argument after the comma
; The function is used to parse second argument for MOV/MVI/LXI instruction, or a next element in the DB/DW
; comma separated sequence 
PARSE_2ND_ARG:
    db9a  7e         MOV A, M                   ; The function expects an expression, but first we need to match
    db9b  fe 2c      CPI A, 2c                  ; a comma symbol
    db9d  c2 8d da   JNZ da8d

    dba0  23         INX HL                     ; Parse the expression
    dba1  cd b2 db   CALL PARSE_EXPRESSION (dbb2)

    dba4  3a 89 bf   LDA OPCODE_ARG_TYPE (bf89) ; Argument type 0x03 is a special case - MOV instruction with two
    dba7  fe 03      CPI A, 03                  ; register arguments. C has the instruction bytes counter
    dba9  ca ad db   JZ PARSE_2ND_ARG_1 (dbad)

    dbac  0d         DCR C                      ; MOV type has less bytes (1 byte) than other similar instructions

PARSE_2ND_ARG_1:
    dbad  0d         DCR C                      ; Verify the instruction length. Report an error in case of
    dbae  c2 8d da   JNZ da8d                   ; mismatch

    dbb1  c9         RET


; Parse expression
;
; Obviously not all instructions accept full range of features allowed in the expressions. Thus, most of the
; instructions allows just a register name as an argument. The function tries to match a register name as an
; expression as a first step.
;
; At the same time other instructions may accept immediate values as their arguments (chars, numbers, addresses),
; and this is where full power of expressions can be used. The expression is a series of 1 or more members,
; that are added or subtracted. Each member may be a number, label value, or string/char literal (all parsed by
; PARSE_IMMEDIATE_VALUE function). The function support + and - operations between values. The value may start
; with an unary + or - as well.
PARSE_EXPRESSION:
    dbb2  cd cd da   CALL COPY_WORD_TO_WORK_BUF (dacd)  ; Copy next token to the working buffer

    dbb5  af         XRA A                      ; Reset variables to be filled while parsing
    dbb6  32 93 bf   STA ARITHMETIC_OPERATION (bf93)
    dbb9  32 8a bf   STA OPCODE_REGISTER_ARG_LOW (bf8a) ; This is 2-byte result accumulator
    dbbc  32 8b bf   STA OPCODE_REGISTER_ARG_HIGH (bf8b)

    dbbf  b9         CMP C                      ; Some expressions may start with a + or -, without a first
    dbc0  ca da db   JZ PARSE_EXPRESSION_NEXT (dbda)    ; member

    dbc3  cd 22 dc   CALL PARSE_REGISTER_NAME (dc22)    ; Try matchin a register name first

    dbc6  fe 01      CPI A, 01                  ; Check if the register name was matched successfully
    dbc8  c2 d3 db   JNZ PARSE_EXPRESSION_1 (dbd3)

    dbcb  4f         MOV C, A                   ; Ensure that argument was fully matched
    dbcc  cd 17 dc   CALL CHECK_END_OF_ARG (dc17)
    dbcf  c8         RZ                         ; Return on success

    dbd0  da 8d da   JC da8d                    ; Report an error if argument was not fully parsed

PARSE_EXPRESSION_1:
    dbd3  e5         PUSH HL                    ; Argument is not a register name, maybe a label or EQU value
    dbd4  cd 6e db   CALL GET_LABEL_VALUE (db6e)

    dbd7  c3 03 dc   JMP PARSE_EXPRESSION_STORE_VALUE (dc03)    ; The function continues elsewhere


; Continue parsing the expression, process the next member of the expression
PARSE_EXPRESSION_NEXT:
    dbda  cd 17 dc   CALL CHECK_END_OF_ARG (dc17)   ; Return if end of arg reached
    dbdd  c8         RZ

    dbde  fe 2b      CPI A, 2b                      ; Check if we found a '+'
    dbe0  ca e8 db   JZ PARSE_EXPRESSION_2 (dbe8)

    dbe3  fe 2d      CPI A, 2d                      ; Chack if we found a '-'
    dbe5  c2 ec db   JNZ PARSE_EXPRESSION_3 (dbec)

PARSE_EXPRESSION_2:
    dbe8  32 93 bf   STA ARITHMETIC_OPERATION (bf93)    ; Store the +/- operation type for future use little below
    dbeb  23         INX HL

PARSE_EXPRESSION_3:
    dbec  cd 58 dc   CALL PARSE_IMMEDIATE_VALUE (dc58)  ; Parse the next value in the sequence

    dbef  0c         INR C                          ; Check if the value parsed successfully, report an error if
    dbf0  ca 8d da   JZ da8d                        ; needed

    dbf3  3a 93 bf   LDA ARITHMETIC_OPERATION (bf93)    ; Recall the arithmetic operation to apply

    dbf6  fe 2d      CPI A, 2d                      ; Check if it was '-'
    dbf8  c2 02 dc   JNZ PARSE_EXPRESSION_4 (dc02)

    dbfb  af         XRA A                          ; Prepare parsed value in DE for subtraction (negate it)
    dbfc  93         SUB E
    dbfd  5f         MOV E, A
    dbfe  3e 00      MVI A, 00
    dc00  9a         SBB D
    dc01  57         MOV D, A

PARSE_EXPRESSION_4:
    dc02  e5         PUSH HL

PARSE_EXPRESSION_STORE_VALUE:
    dc03  2a 8a bf   LHLD OPCODE_REGISTER_ARGS (bf8a)   ; Add the parsed value in DE to the result accumulator
    dc06  19         DAD DE
    dc07  22 8a bf   SHLD OPCODE_REGISTER_ARGS (bf8a)

    dc0a  e1         POP HL

    dc0b  cd 58 dc   CALL PARSE_IMMEDIATE_VALUE (dc58)  ; Try parsing if any more data is there

    dc0e  0c         INR C                      ; Report a syntax error if unexpected argument is found
    dc0f  c2 8d da   JNZ da8d

    dc12  0e 02      MVI C, 02                  ; Instruction with immediate value is at least 2-byte instruction

    dc14  c3 da db   JMP PARSE_EXPRESSION_NEXT (dbda)   ; Parse the next member of expression sequence (if any)


; Check if the byte at [HL] is zero (EOL), ',', or ';', indicating end of an instruction argument
; Clear C flag and set Z flag if mentioned symbol matched, otherwise set C flag and clear Z
CHECK_END_OF_ARG:
    dc17  7e         MOV A, M                   ; Check if the source byte is zero (end of line)
    dc18  b7         ORA A
    dc19  c8         RZ

    dc1a  fe 2c      CPI A, 2c                  ; Check if the byte is ','
    dc1c  c8         RZ

    dc1d  fe 3b      CPI A, 3b                  ; Check if the byte is ';'
    dc1f  c8         RZ

    dc20  37         STC                        ; Otherwise set C flag
    dc21  c9         RET


; Parse register name in the instruction argument
;
; The function matches word in the buffer with records in the REGISTER_MATCH_TABLE table.
; In case of match, the function fills OPCODE_REGISTER_ARG_LOW and OPCODE_REGISTER_ARG_HIGH, and returns
; 0x01 in A register. The 0x00 value is returned in A in case of no matches found.
PARSE_REGISTER_NAME:
    dc22  e5         PUSH HL                    ; Load the pointer to the register names table
    dc23  21 77 de   LXI HL, REGISTER_MATCH_TABLE (de77)

    dc26  41         MOV B, C                   ; Number of chars to match in B

PARSE_REGISTER_NAME_LOOP:
    dc27  11 e0 bf   LXI DE, bfe0               ; Will start with the first char in the buffer

    dc2a  48         MOV C, B                   ; C is a character counter

    dc2b  7e         MOV A, M                   ; Repeat until all records in the table matched (reached zero
    dc2c  23         INX HL                     ; terminating byte)
    dc2d  b7         ORA A
    dc2e  ca 56 dc   JZ PARSE_REGISTER_NAME_EXIT (dc56)

    dc31  b9         CMP C                      ; Before we start matching characters, first compare register 
    dc32  ca 3f dc   JZ PARSE_REGISTER_LEN_MATCHED (dc3f)   ; name length match

    dc35  4f         MOV C, A                   ; If length is different - skip to the next record

PARSE_REGISTER_SKIP_LOOP:
    dc36  23         INX HL                     ; Iterate over all characters in the register name
    dc37  0d         DCR C
    dc38  c2 36 dc   JNZ PARSE_REGISTER_SKIP_LOOP (dc36)

    dc3b  23         INX HL                     ; Skip opcode argument, and advance to the next record
    dc3c  c3 27 dc   JMP PARSE_REGISTER_NAME_LOOP (dc27)

PARSE_REGISTER_LEN_MATCHED:
    dc3f  1a         LDAX DE                    ; Compare the next register name character
    dc40  13         INX DE                     ; Skip to the next record in case of mismatch
    dc41  be         CMP M
    dc42  c2 36 dc   JNZ PARSE_REGISTER_SKIP_LOOP (dc36)

    dc45  23         INX HL                     ; Advance to the next char until all chars matched
    dc46  0d         DCR C
    dc47  c2 3f dc   JNZ PARSE_REGISTER_LEN_MATCHED (dc3f)

    dc4a  7e         MOV A, M                   ; Store the opcode argument in the variable
    dc4b  32 8a bf   STA OPCODE_REGISTER_ARG_LOW (bf8a)

    dc4e  07         RLC                        ; Make a copy shifted by 3 bits left - this is used for some
    dc4f  07         RLC                        ; instructions that have register bits at other position
    dc50  07         RLC
    dc51  32 8b bf   STA OPCODE_REGISTER_ARG_HIGH (bf8b)

    dc54  3e 01      MVI A, 01                  ; Return 0x01 in case of match, otherwise 0x00

PARSE_REGISTER_NAME_EXIT:
    dc56  e1         POP HL                     ; Return
    dc57  c9         RET



; Parse immediate value
;
; The function parses immediate value of the following formats:
; - 12345   - decimal integer value
; - 0ABH    - hex value (must start with decimal digit, and end with H)
; - $       - current output address
; - 'ch'    - char value in single quotes (may be 1 or 2 chars depending on instruction)
; - <reg>   - register name (for those opcodes that assume it)
; - <label> - label address or EQU value
;
; Parsed value is returned in DE
; 
; Return number suggested size of the instruction in C, or 0xff in case of error ???? TODO Check
PARSE_IMMEDIATE_VALUE:
    dc58  cd cd da   CALL COPY_WORD_TO_WORK_BUF (dacd)  ; Copy the argument word to the working buffer

    dc5b  0d         DCR C                      ; Check if there were any letters copied (otherwise it is a number,
    dc5c  f2 ef dc   JP PARSE_IMMEDIATE_VALUE_LITERAL (dcef)  ; or a string literal)

    dc5f  7e         MOV A, M                   ; Check if the argument starts with quote symbol '
    dc60  fe 27      CPI A, 27
    dc62  ca d2 dc   JZ PARSE_IMMEDIATE_VALUE_QUOTE (dcd2)

    dc65  fe 24      CPI A, 24                  ; Check if the argument is '$' (current address)
    dc67  ca fe dc   JZ PARSE_IMMEDIATE_VALUE_CUR_ADDR (dcfe)

    dc6a  fe 30      CPI A, 30                  ; Check if it is a digit ('0'-'9')
    dc6c  f8         RM                         ; Otherwise return
    dc6d  fe 3a      CPI A, 3a
    dc6f  f0         RP

    dc70  11 e0 bf   LXI DE, bfe0               ; ???? Output buffer ??
    dc73  0e 00      MVI C, 00                  ; ???? Counter ??

PARSE_IMMEDIATE_VALUE_LOOP:
    dc75  d6 30      SUI A, 30                  ; Convert symbol to number (subtract '0'), and store it in the
    dc77  12         STAX DE                    ; output buffer

    dc78  13         INX DE                     ; Advance to the next byte
    dc79  23         INX HL

    dc7a  7e         MOV A, M                   ; Load the next byte

    dc7b  fe 30      CPI A, 30                  ; Verify this is still in '0'-'9' range

    dc7d  fa 9a dc   JM PARSE_IMMEDIATE_VALUE_ERROR (dc9a)  ; Symbols < '0' are incorrect

    dc80  fe 3a      CPI A, 3a                  ; Process next digit
    dc82  fa 75 dc   JM PARSE_IMMEDIATE_VALUE_LOOP (dc75)

    dc85  fe 41      CPI A, 41                  ; Symbols <'A' are incorrect
    dc87  fa 9a dc   JM PARSE_IMMEDIATE_VALUE_ERROR (dc9a)

    dc8a  0c         INR C                      ; Probably we match a hex char, 'H' will stop the match, and 
    dc8b  fe 48      CPI A, 48                  ; start converting the string to the value
    dc8d  ca a4 dc   JZ HEX_STR_TO_INT (dca4)

    dc90  fe 4a      CPI A, 4a                  ; Chars >= 'I' lead to error
    dc92  f2 8d da   JP da8d

    dc95  d6 07      SUI A, 07                  ; Convert the char to 0x3a-0x3f range, than it can be stored to
    dc97  c3 75 dc   JMP PARSE_IMMEDIATE_VALUE_LOOP (dc75)  ; the buffer for further parsing in HEX_STR_TO_INT

PARSE_IMMEDIATE_VALUE_ERROR:
    dc9a  af         XRA A                      ; Check if all symbols are parsed, if not - it is a syntax error
    dc9b  b9         CMP C                      ; If all symbols are parsed - convert them to the value
    dc9c  c2 8d da   JNZ da8d

; Convert a string to 16-bit value, treating symbols as decimal digits
; See STR_TO_INT for more information
DEC_STR_TO_INT:
    dc9f  3e 19      MVI A, 19
    dca1  c3 a7 dc   JMP dca7

; Convert a string to 16-bit value, treating symbols as hex digits
; See STR_TO_INT for more information
HEX_STR_TO_INT:
    dca4  23         INX HL
    dca5  3e 29      MVI A, 29

; Convert a string to 16-bit integer value
;
; Algorithm:
; Result accumulator is shifted left for 1 digit (multiply by 10 or 16 depending on mode), and next digit
; is added to the accumulator.
; 
; Note: this is not a standalone function, just a piece of code that does conversion.
;
; Arguments:
; A - 0x19 to treat input string as decimal digits, 0x29 to treat them as hex digits
; Input digits are in the buffer at 0xbfe0, each symbol shall be prepared to a 0x00-0x0f range.
; DE shall point to the position after the last digit.
;
; Result:
; DE - parsed value
STR_TO_INT:
    dca7  12         STAX DE                    ; Store mode flag after the last digit
    dca8  e5         PUSH HL

    dca9  21 e0 bf   LXI HL, bfe0               ; Will start processing from the beginning of the buffer
    dcac  11 00 00   LXI DE, 0000               ; Zero result accumulator

    dcaf  de 19      SBI A, 19                  ; A=0 for decimal mode, A>0 for hex mode

STR_TO_INT_LOOP:
    dcb1  47         MOV B, A                   ; Store mode flag in B

    dcb2  7e         MOV A, M                   ; Load the next digit, and advance pointer to the next one
    dcb3  23         INX HL

    dcb4  fe 10      CPI A, 10                  ; Digits >= 0x10 stop processing
    dcb6  f2 09 dd   JP PARSE_IMMEDIATE_VALUE_EXIT_3B (dd09)

    dcb9  4f         MOV C, A                   ; Load the next digit into C

    dcba  78         MOV A, B                   ; Check the mode, set Z flag
    dcbb  b7         ORA A

    dcbc  06 00      MVI B, 00                  ; Clear B, so that in BC there is next digit

    dcbe  e5         PUSH HL                    ; The following lines multiply DE by 10 or 16, depending on Z
                                                ; flag

    dcbf  62         MOV H, D                   ; HL = 4 * DE
    dcc0  6b         MOV L, E
    dcc1  29         DAD HL
    dcc2  29         DAD HL

    dcc3  c2 ca dc   JNZ STR_TO_INT (dcca)      ; Zero flag - multiplication by 10, otherwise by 16

    dcc6  19         DAD DE                     ; HL = 5 * original DE

    dcc7  c3 cb dc   JMP STR_TO_INT_2 (dccb)

STR_TO_INT_1:
    dcca  29         DAD HL                     ; Double HL, so that it contains 8 * original DE

STR_TO_INT_2:
    dccb  29         DAD HL                     ; Double HL, so that it contains either 16*DE or 10*DE (original DE)

    dccc  09         DAD BC                     ; Add the loaded digit

    dccd  eb         XCHG                       ; Store result in the result accumulator

    dcce  e1         POP HL                     ; Advance to the next digit
    dccf  c3 b1 dc   JMP STR_TO_INT_LOOP (dcb1)


; Parse char or pair of chars in quotes as immediate value
PARSE_IMMEDIATE_VALUE_QUOTE:
    dcd2  0e 02      MVI C, 02                  ; Opcodes with the arguments are at least 2-byte instructions

    dcd4  3a 89 bf   LDA OPCODE_ARG_TYPE (bf89) ; DB directive (type 0x0e) has special processing for symbols
    dcd7  fe 0e      CPI A, 0e
    dcd9  c2 df dc   JNZ PARSE_IMMEDIATE_VALUE_QUOTE_1 (dcdf)

    dcdc  33         INX SP                     ; Skip returning to parent, return right to the caller's caller
    dcdd  33         INX SP                     ; Perhaps quoted string in DB directive does not assume any
    dcde  c9         RET                        ; further arithmetic

PARSE_IMMEDIATE_VALUE_QUOTE_1:
    dcdf  23         INX HL                     ; Load symbol
    dce0  5e         MOV E, M
    dce1  23         INX HL                     ; Load second symbol (applicable for 2-char strings)
    dce2  56         MOV D, M

PARSE_IMMEDIATE_VALUE_QUOTE_LOOP:
    dce3  7e         MOV A, M                   ; Load next char
    dce4  23         INX HL

    dce5  b7         ORA A                      ; If EOL happens earlier than closing quote - report an error
    dce6  ca 8d da   JZ da8d

    dce9  fe 27      CPI A, 27                  ; Repeat until closing quote is found
    dceb  c2 e3 dc   JNZ PARSE_IMMEDIATE_VALUE_QUOTE_LOOP (dce3)

    dcee  c9         RET                        ; Done, return matched symbol(s) in DE


; The immediate value is possibly a register name, or a label reference
PARSE_IMMEDIATE_VALUE_LITERAL:
    dcef  cd 22 dc   CALL PARSE_REGISTER_NAME (dc22)    ; Try matching a register name

    dcf2  fe 01      CPI A, 01                  ; Check if any register is matched
    dcf4  ca 8d da   JZ da8d

    dcf7  e5         PUSH HL                    ; If not a register name, then this probably a label
    dcf8  cd 6e db   CALL GET_LABEL_VALUE (db6e); Parse the label

    dcfb  c3 09 dd   JMP PARSE_IMMEDIATE_VALUE_EXIT_3B (dd09)

; Usage of '$' means use target address of the currently parsed instruction
PARSE_IMMEDIATE_VALUE_CUR_ADDR:
    dcfe  23         INX HL                     ; Advance to the next char
    dcff  e5         PUSH HL

    dd00  2a 87 bf   LHLD CUR_OPCODE_TARGET_ADDR (bf87) ; Load current instruction address to DE
    dd03  eb         XCHG

    dd04  2a 98 bf   LHLD ORG_OFFSET (bf98)     ; Apply the ORG offset, put result to DE
    dd07  19         DAD DE
    dd08  eb         XCHG

PARSE_IMMEDIATE_VALUE_EXIT_3B:
    dd09  e1         POP HL                     ; Set output as 3-byte instruction
    dd0a  0e 02      MVI C, 02
    dd0c  c9         RET


; Parse mnemonic string, and convert it to opcode and argument type code
; 
; The function parses a 3-char string in 0xbfe0 array. Some of the instructions are 4-char, but most of them
; are not ambiguous except for STA/STAX and LDA/LDAX. So the first step of the algorithm is to convert STAX and
; LDAX instructions into STX and LDX respectively. Thus all instructions are not ambiguous having only first
; 3 letters.
;
; Then it follows the next algorithm:
; - Use the first letter to find a value in the MNEMONIC_1ST_LETTER_LUT table. The value represents first index
;   of a record in the MNEMONIC_2ND_3RD_LETTER_LUT table, that corresponds to instruction starting with this
;   letter. The function also checks the next value in the MNEMONIC_1ST_LETTER_LUT table to determine how many
;   records in the MNEMONIC_2ND_3RD_LETTER_LUT table are associated with this letter.
; - Every record in the MNEMONIC_2ND_3RD_LETTER_LUT includes 2nd and 3rd letters of the mnemonic. The function
;   searches the corresponding record
; - When exact record is found, the function extracts base opcode, and argument type. These values are stored in
;   BASE_OPCODE and OPCODE_ARG_TYPE variables for further processing.
;  
;
; Example:
; MVI instruction is parsed as follows:
; - First byte is 'M'. A record that matches 'M' symbol in MNEMONIC_1ST_LETTER_LUT contains value 0x30. This
;   means we need to look at 0x30th record in the MNEMONIC_2ND_3RD_LETTER_LUT table, which contains two records:
;   b2 45 06 and 7d 83 40
; - Take lowest 5 bits of the 2nd char ('V' = 0x56 -> 0x16 -> 1 0110), and lowest 5 bits of 3rd char ('I' = 0x49
;   -> 0x09 -> 0 1001) and arrange them as 22222333 33xxxxxx: 10110 010 01 xxxxxx -> 0xb2 0x40. Calculated value
;   corresponds the first record (of the two found on the previous step)
; - 3rd byte of the record (0x06) is a base opcode
; - 6 lowest bits of the 2nd byte of the record (0x05) represent argument type. Literally it selects a function 
;   responsible to parse instruction arguments
PARSE_MNEMONIC:
    dd0d  3a e3 bf   LDA bfe3                   ; Check the 4th symbol of the mnemonic

    dd10  fe 58      CPI A, 58                  ; Is it 'X'? LDAX/STAX
    dd12  c2 18 dd   JNZ PARSE_MNEMONIC_1 (dd18)

    dd15  32 e2 bf   STA bfe2                   ; Copy 'X' to 3rd symbol as well (so it becomes LDX/STX)

PARSE_MNEMONIC_1:
    dd18  3a e0 bf   LDA bfe0                   ; Load the 1st symbol of the mnemonic

    dd1b  d6 41      SUI A, 41                  ; Symbols with codes < 'A' are invalid. Report a syntax error
    dd1d  fa 88 da   JM da88

    dd20  5f         MOV E, A                   ; Load opcode-'A' to DE
    dd21  16 00      MVI D, 00

    dd23  21 99 de   LXI HL, MNEMONIC_1ST_LETTER_LUT (de99) ; Search in the look up table
    dd26  19         DAD DE

    dd27  5e         MOV E, M                   ; Duplicating items in the table mean there is no instruction
    dd28  23         INX HL                     ; starting this letter (B, F, G, K, Q, T, U, V, W, Y, Z). Report
    dd29  7e         MOV A, M                   ; an error in this case
    dd2a  93         SUB E
    dd2b  ca 88 da   JZ da88

    dd2e  4f         MOV C, A                   ; Store number of instructions that start with this letter in C
    dd2f  c5         PUSH BC

    dd30  21 b4 de   LXI HL, MNEMONIC_2ND_3RD_LETTER_LUT (deb4) ; Calculate a pointer in the 2nd/3rd letters table
    dd33  19         DAD DE                     ; HL = 0xdeb4 + 3*index  (each record is 3 bytes: 2 bytes match
    dd34  19         DAD DE                     ; the letters, 3rd byte is instruction opcode base)
    dd35  19         DAD DE

    dd36  0e 20      MVI C, 20
    dd38  3a e1 bf   LDA bfe1                   ; Load 2nd char, and compare it with space
    dd3b  91         SUB C
    dd3c  ca 43 dd   JZ PARSE_MNEMONIC_2 (dd43)

    dd3f  91         SUB C                      ; Symbols below 0x40 (letter) is a syntax error
    dd40  fa 88 da   JM da88

PARSE_MNEMONIC_2:
    dd43  07         RLC                        ; Shift 2nd char for 3 bits left
    dd44  07         RLC
    dd45  07         RLC
    dd46  47         MOV B, A

    dd47  3a e2 bf   LDA bfe2                   ; Check if the 3rd char is a space
    dd4a  91         SUB C
    dd4b  ca 52 dd   JZ PARSE_MNEMONIC_3 (dd52) 
    dd4e  91         SUB C                      ; Symbols below 'A' are syntax error
    dd4f  fa 88 da   JM da88

PARSE_MNEMONIC_3:
    dd52  0f         RRC                        ; Apply 3 highest bits of the 3rd char (so that result is
    dd53  0f         RRC                        ; 22222333, where 2s are 5 low bits of the 2nd char, and 
    dd54  4f         MOV C, A                   ; 3s are 3 bits of the 3rd char)
    dd55  e6 07      ANI A, 07
    dd57  b0         ORA B                      ; Put result in D
    dd58  57         MOV D, A

    dd59  79         MOV A, C                   ; Take 2 remaining bits of the 3rd char and place it to DE
    dd5a  e6 c0      ANI A, c0                  ; Now DE is 22222333 33000000
    dd5c  5f         MOV E, A
    dd5d  c1         POP BC

PARSE_MNEMONIC_LOOP:
    dd5e  7e         MOV A, M                   ; Compare D with the next record's 1st byte
    dd5f  23         INX HL
    dd60  ba         CMP D
    dd61  c2 6b dd   JNZ PARSE_MNEMONIC_4 (dd6b)

    dd64  7e         MOV A, M                   ; Compare 2 highest bits of E with the record's 2nd byte
    dd65  e6 c0      ANI A, c0
    dd67  bb         CMP E
    dd68  ca 74 dd   JZ PARSE_MNEMONIC_EXIT (dd74)

PARSE_MNEMONIC_4:
    dd6b  23         INX HL                     ; If no match - advance to the next record
    dd6c  23         INX HL

    dd6d  0d         DCR C                      ; Repear for all records associated with the first letter of
    dd6e  c2 5e dd   JNZ PARSE_MNEMONIC_LOOP (dd5e) ; mnemonic

    dd71  c3 88 da   JMP da88                   ; If still no match - report a syntax error

PARSE_MNEMONIC_EXIT:
    dd74  7e         MOV A, M                   ; Lowest 6 bits of the record's 2nd byte are the argument
    dd75  e6 3f      ANI A, 3f                  ; increment
    dd77  32 89 bf   STA OPCODE_ARG_TYPE (bf89)

    dd7a  23         INX HL                     ; 3rd byte of the record is the base opcode
    dd7b  7e         MOV A, M
    dd7c  32 8c bf   STA BASE_OPCODE (bf8c)

    dd7f  c9         RET



; ???????? Second pass processing ???
;
;
????:
    dd80  3a 94 bf   LDA WORKING_MODE (bf94)    ; The following code works only for mode 2
    dd83  1f         RAR
    dd84  d0         RNC

dd85  3a 83 bf   LDA PASS_NUMBER (bf83)
dd88  3d         DCR A
dd89  c8         RZ
dd8a  cd d3 dd   CALL PRINT_CR_LF (ddd3)
dd8d  3a 84 bf   LDA bf84
dd90  b7         ORA A
dd91  ca 9f dd   JZ dd9f
dd94  cd 42 de   CALL PRINT_BYTE_HEX (de42)
dd97  0e 2a      MVI C, 2a
dd99  cd 50 de   CALL PUT_CHAR (de50)
dd9c  c3 a5 dd   JMP dda5

????:
dd9f  01 20 03   LXI BC, 0320
dda2  cd 27 da   CALL PRINT_CHAR_BLOCK (da27)
????:
dda5  11 a0 bf   LXI DE, LINE_BUF (bfa0)
dda8  1a         LDAX DE
dda9  fe 3b      CPI A, 3b
ddab  01 20 11   LXI BC, 1120
ddae  ca b8 dd   JZ ddb8
ddb1  af         XRA A
ddb2  32 93 bf   STA bf93
ddb5  cd dd dd   CALL dddd
????:
ddb8  eb         XCHG
ddb9  cd 27 da   CALL PRINT_CHAR_BLOCK (da27)
ddbc  cd 18 f8   CALL PRINT_STRING (f818)
????:
ddbf  3a 93 bf   LDA bf93
ddc2  b7         ORA A
ddc3  c8         RZ
ddc4  cd d3 dd   CALL PRINT_CR_LF (ddd3)
ddc7  01 20 03   LXI BC, 0320
ddca  cd 27 da   CALL PRINT_CHAR_BLOCK (da27)
ddcd  cd dd dd   CALL dddd
ddd0  c3 bf dd   JMP ddbf

; Print 0x0d and 0x0a chars
PRINT_CR_LF:
    ddd3  0e 0d      MVI C, 0d
    ddd5  cd 50 de   CALL PUT_CHAR (de50)
    ddd8  0e 0a      MVI C, 0a
    ddda  c3 50 de   JMP PUT_CHAR (de50)

; ?????
; Return ??? in B, and ??? in C
????:
dddd  3a 89 bf   LDA OPCODE_ARG_TYPE (bf89)
dde0  fe 0c      CPI A, 0c
dde2  c8         RZ
dde3  fe 0d      CPI A, 0d
dde5  c8         RZ

dde6  2a 87 bf   LHLD CUR_OPCODE_TARGET_ADDR (bf87)
dde9  fe 11      CPI A, 11
ddeb  ca 3d de   JZ de3d

ddee  f5         PUSH PSW
ddef  d5         PUSH DE
ddf0  eb         XCHG
ddf1  2a 98 bf   LHLD ORG_OFFSET (bf98)
ddf4  19         DAD DE
ddf5  cd 48 de   CALL PRINT_WORD_HEX (de48)
ddf8  eb         XCHG
ddf9  d1         POP DE
ddfa  f1         POP PSW
ddfb  fe 10      CPI A, 10
ddfd  ca 24 de   JZ de24
de00  06 04      MVI B, 04
????:
de02  3a 85 bf   LDA CUR_OUTPUT_PTR (bf85)
de05  95         SUB L
de06  ca 1c de   JZ de1c
de09  7e         MOV A, M
de0a  23         INX HL
de0b  cd 42 de   CALL PRINT_BYTE_HEX (de42)
de0e  cd 50 de   CALL PUT_CHAR (de50)
de11  05         DCR B
de12  c2 02 de   JNZ de02
de15  3a 85 bf   LDA CUR_OUTPUT_PTR (bf85)
de18  95         SUB L
de19  22 87 bf   SHLD CUR_OPCODE_TARGET_ADDR (bf87)
????:
de1c  32 93 bf   STA bf93
de1f  78         MOV A, B
de20  07         RLC
de21  80         ADD B
de22  47         MOV B, A
de23  c9         RET

????:
    de24  0e 28      MVI C, 28                  ; Print '('
    de26  cd 50 de   CALL PUT_CHAR (de50)
    de29  0e 20      MVI C, 20                  ; Print ' '
    de2b  cd 50 de   CALL PUT_CHAR (de50)

    de2e  2a 8a bf   LHLD OPCODE_REGISTER_ARG_LOW (bf8a)   ; ????? Print 0xbf8a
    de31  cd 48 de   CALL PRINT_WORD_HEX (de48)

    de34  0e 29      MVI C, 29                  ; Print ')'
    de36  cd 50 de   CALL PUT_CHAR (de50)

    de39  01 20 04   LXI BC, 0420               ; ?????
    de3c  c9         RET

????:
de3d  06 0c      MVI B, 0c
de3f  c3 48 de   JMP PRINT_WORD_HEX (de48)

; Print byte as hex
PRINT_BYTE_HEX:
    de42  c5         PUSH BC
    de43  cd 15 f8   CALL MONITOR_PRINT_BYTE_HEX (f815)
    de46  c1         POP BC
    de47  c9         RET

; Print 16-bit value in HL as hex, then print a byte in C
PRINT_WORD_HEX:
    de48  7c         MOV A, H
    de49  cd 42 de   CALL PRINT_BYTE_HEX (de42)
    de4c  7d         MOV A, L
    de4d  cd 42 de   CALL PRINT_BYTE_HEX (de42)

; Print char in C register
PUT_CHAR:
    de50  c3 09 f8   JMP MONITOR_PUT_CHAR (f809)


; Output handlers table. Each entry consists of 2 bytes:
; - offset from OUTPUT_HANDLER_BASE (0xd8d9)
; - ????    number of bytes ?
OUTPUT_HANDLERS_TABLE:
    de53  0b 00     ; arg type 0x00: 1-byte instruction with no arguments (OUTPUT_HANDLER_1B_NO_ARGS)
    de55  08 01     ; arg type 0x01: 1-byte instruction with source 8-reg coded in lower 3 bits (OUTPUT_HANDLER_1B_SRC_REG)
    de57  2e 01     ; arg type 0x02: 1-byte instruction with register coded in the opcode (OUTPUT_HANDLER_1B_1_REG_ARG)
    de59  00 01     ; arg type 0x03: MOV - 1-byte instruction with 2 register args (OUTPUT_HANDLER_1B_MOV)
    de5b  16 02     ; arg type 0x04: 2 byte instruction, no registers coded in the opcode, 8-bit immediate value (OUTPUT_HANDLER_2B_IMMEDIATE)
    de5d  0e 01     ; arg type 0x05: MVI - destination 8-bit register coded in 3-5th bits, 8-bit immediate value (OUTPUT_HANDLER_2B_MVI)
    de5f  26 02     ; arg type 0x06: no register bits, 2-byte immediate value (OUTPUT_HANDLER_3B_IMMEDIATE_ARG)
    de61  2b 01     ; arg type 0x07: 1-byte instruction with register pair coded in 4-5th bits (OUTPUT_HANDLER_1B_REG_PAIR)
    de63  31 01     ; arg type 0x08: PUSH/POP - register pair coded in the opcode (OUTPUT_HANDLER_1B_PUSH_POP)
    de65  37 01     ; arg type 0x09: 1-byte LDAX/STAX instruction, register pair name is coded in the 5th bit (OUTPUT_HANDLER_1B_STAX_LDAX)
    de67  1b 01     ; arg type 0x0a: LXI - reg pair bits cpded in 4-5 bits of the opcode, 2-byte 2nd argument value (OUTPUT_HANDLER_3B_LXI)
    de69  3d 02     ; arg type 0x0b: RST - rst number is coded in the 3-5th bits of the opcode (OUTPUT_HANDLER_1B_RST)
    de6b  c1 02     ; arg type 0x0c: ORG compiler directive (ORG_HANDLER)
    de6d  d8 00     ; arg type 0x0d:
    de6f  82 02     ; arg type 0x0e: DB compiler directive (DB_DW_HANDLER)
    de71  82 02     ; arg type 0x0f: DW compiler directive (DB_DW_HANDLER)
    de73  4d 02     ; arg type 0x10: DS compiler directive (DS_HANDLER)
    de75  59 02     ; arg type 0x11: EQU compiler directive (EQU_HANDLER)

; A table that matches register names and return an opcode modifier that corresponds the register
;
; Format of each record:
; - Number of symbols to match (0x00 - end of the table)
; - Symbols to match (1-3 chars)
; - Opcode modifier
REGISTER_MATCH_TABLE:
    de77  01 41 07          db 0x01, 'A', 0x07
    de7a  01 42 00          db 0x01, 'B', 0x00
    de7d  01 43 01          db 0x01, 'C', 0x01
    de80  01 44 02          db 0x01, 'D', 0x02
    de83  01 45 03          db 0x01, 'E', 0x03
    de86  01 48 04          db 0x01, 'H', 0x04
    de89  01 4c 05          db 0x01, 'L', 0x05
    de8c  01 4d 00          db 0x01, 'M', 0x06
    de8f  02 53 50 08       db 0x02, 'SP', 0x08
    de93  03 50 53 57 09    db 0x01, 'PSW', 0x09
    de98  00                db 0x00


; First symbol of the mnemonic lookup table
;
; This table is used to match first letter of the instruction. Position in this table matches the letter if 
; counting from 'A'. Value in this table is index in the next lookup table, that matches 2nd and 3rd chars of
; the instruction. 
;
; Difference between the two items in the table represent number of different instructions stat start with the
; particular letters. Duplicating items represent error cases when no instruction starting the particular letter
; exists.
MNEMONIC_1ST_LETTER_LUT:
    de99  00                            ; 'A'
    de9a  06                            ; 'B' - no instruction starting this letter
    de9b  06                            ; 'C'
    de9c  13                            ; 'D'
    de9d  1b                            ; 'E'
    de9e  1e                            ; 'F' - no instruction starting this letter
    de9f  1e                            ; 'G' - no instruction starting this letter
    dea0  1e                            ; 'H' 
    dea1  1f                            ; 'I'
    dea2  22                            ; 'J' 
    dea3  2c                            ; 'K' - no instruction starting this letter
    dea4  2c                            ; 'L'
    dea5  30                            ; 'M' - MOV, MVI
    dea6  32                            ; 'N' - NOP
    dea7  33                            ; 'O'
    dea8  37                            ; 'P'
    dea9  3a                            ; 'Q' - no instruction starting this letter
    deaa  3a                            ; 'R'
    deab  48                            ; 'S'
    deac  51                            ; 'T' - no instruction starting this letter
    dead  51                            ; 'U' - no instruction starting this letter
    deae  51                            ; 'V' - no instruction starting this letter
    deaf  51                            ; 'W' - no instruction starting this letter
    deb0  51                            ; 'X'
    deb1  55                            ; 'Y' - no instruction starting this letter
    deb2  55                            ; 'Z' - no instruction starting this letter
    deb3  55                            ; end of table marker


; Instructions table for matching 2nd and 3rd symbols of the mnemonic
; Each record contains 3 bytes:
; - 1st and 2nd byte are 22222333 33bbbbbb, where
;   - '2's are lowest 5 bits of the 2nd mnemonic char
;   - '3's are lowest 5 bits of the 3rd mnemonic char
;   - 'b's are the argument type, and particularly selects the function that is used to parse arguments
; - 3rd byte is the base opcode with register bits masked out
;
; Different instructions use different types of register bits coded in the opcode:
; - 0x00 - no register bits in the opcode
; - 0x01 - source 8-bit register coded in lower 3 bits of the opcode
; - 0x02 - 1-byte instruction with register name coded in the 3-5th bits
; - 0x03 - MOV - 1-byte instruction with 2 register args
; - 0x04 - 2 byte instruction, no registers coded in the opcode, 8-bit immediate value
; - 0x05 - MVI - destination 8-bit register coded in 3-5th bits, 8-bit immediate value
; - 0x06 - no register bits, 2-byte immediate value
; - 0x07 - 1-byte instruction with register name coded in the 3-5th bits of theopcode
; - 0x08 - 1-byte PUSH/POP instruction, register pair name coded in the 3-5th bits of the opcode
; - 0x09 - 1-byte LDAX/STAX instruction, register pair name is coded in the 5th bit
; - 0x0a - LXI - reg pair bits cpded in 4-5 bits of the opcode, 2-byte 2nd argument value
; - 0x0b - RST - rst number is coded in the 3-5th bits of the opcode
; - 0x0c - ORG compiler directive
; - 0x0d - 
; - 0x0e - DB compiler directive (data byte)
; - 0x0f - DW compiler directive (data word)
; - 0x10 - DS compiler directive (data start)
; - 0x11 - EQU compiler directive
;
MNEMONIC_2ND_3RD_LETTER_LUT:
    deb4  1a 44 ce                      ; ACI (opcode 0xce, type=0x04 - no register bits, 1-byte immediate value)
    deb7  20 c1 88                      ; ADC (base opcode 0x88, type=0x01 - source register coded in opcode)
    deba  21 01 80                      ; ADD (base 0pcode 0x80, type=0x01 - source register coded in opcode)
    debd  22 44 c6                      ; ADI (opcode 0xc6, type=0x04 - no register bits, 1-byte immediate value)
    dec0  70 41 a0                      ; ANA (base opcode 0xa0, type=0x01 - source register coded in opcode)
    dec3  72 44 e6                      ; ANI (opcode 0xe6, type=0x04 - no register bits, 1-byte immediate value)
    dec6  0b 06 cd                      ; CALL (opcode 0xcd, arg=0x06 - no register bits, 2-byte immediate value)
    dec9  18 06 dc                      ; CC (opcode 0xdc, arg=0x06 - no register bits, 2-byte immediate value)
    decc  68 06 fc                      ; CM (opcode 0xfc, arg=0x06 - no register bits, 2-byte immediate value)
    decf  68 40 2f                      ; CMA (opcode 0x2f, type=0x00 - no register bits in the opcode)
    ded2  68 c0 3f                      ; CMC (opcode 0x3f, type=0x00 - no register bits in the opcode)
    ded5  6c 01 b8                      ; CMP (base opcode 0xb8, type=0x01 - source register coded in opcode)
    ded8  70 c6 d4                      ; CNC (opcode 0xd4, arg=0x06 - no register bits, 2-byte immediate value)
    dedb  76 86 c4                      ; CNZ (opcode 0xc4, arg=0x06 - no register bits, 2-byte immediate value)
    dede  00 06 f4                      ; CP (opcode 0xf4, arg=0x06 - no register bits, 2-byte immediate value)
    dee1  81 46 ec                      ; CPE (opcode 0xec, arg=0x06 - no register bits, 2-byte immediate value)
    dee4  82 44 fe                      ; CPI (opcode 0xfe, arg=0x04 - no register bits, 1-byte immediate value)
    dee7  83 c6 e4                      ; CPO (opcode 0xe4, arg=0x06 - no register bits, 2-byte immediate value)
    deea  d0 06 cc                      ; CZ (opcode 0xcc, arg=0x06 - no register bits, 2-byte immediate value)
    deed  08 40 27                      ; DAA (opcode 0x27, type=0x00 - no register bits in the opcode)
    def0  09 07 09                      ; DAD (opcode 0x09, type=0x07 - reg pair is coded in 3-4th bits)
    def3  1c 82 05                      ; DCR (base opcode 0x05, type=0x02 - register coded in 3-5th bits)
    def6  1e 07 0b                      ; DCX (base opcode 0x0b, type=0x07 - reg pair is coded in 3-4th bits)
    def9  48 00 f3                      ; DI (opcode 0xf3, type=0x00 - no register bits in the opcode)
    defc  10 0e 00                      ; DB - compiler special instruction, arg code 0x0e
    deff  b8 0f 00                      ; DW - compiler special instruction, arg code 0x0f
    df02  98 10 00                      ; DS - compiler special instruction, arg code 0x10
    df05  48 00 fb                      ; EI (opcode 0xfb, type=0x00 - no register bits in the opcode)
    df08  71 0d 00                      ; END - compiler special instruction, arg code 0x0d
    df0b  8d 51 00                      ; EQU - compiler special instruction, arg code 0x11
    df0e  65 00 76                      ; HLT (opcode 0x76, type=0x00 - no register bits in the opcode)
    df11  70 04 db                      ; IN (opcode 0xdb, type=0x04 - no register bits, 1-byte immediate value)
    df14  74 82 04                      ; INR (base opcode 0x04, type=0x02 - register coded in 3-5th bits)
    df17  76 07 03                      ; INX (base opcode 0x03, type=0x07 - reg pair is coded in 3-4th bits)
    df1a  18 06 da                      ; JC (opcode 0xda, type=0x06 - no register bits, 2-byte immediate value)
    df1d  68 06 fa                      ; JM (opcode 0xfa, type=0x06 - no register bits, 2-byte immediate value)
    df20  6c 06 c3                      ; JMP (opcode 0xc3, type=0x06 - no register bits, 2-byte immediate value) 
    df23  00 06 c3                      ; J - non standard alias for JMP (opcode 0xc3, type=0x06 - no register bits, 2-byte immediate value) 
    df26  70 c6 d2                      ; JNC (opcode 0xd2, type=0x06 - no register bits, 2-byte immediate value) 
    df29  76 86 c2                      ; JNZ (opcode 0xc2, type=0x06 - no register bits, 2-byte immediate value) 
    df2c  80 06 f2                      ; JP (opcode 0xf2, type=0x06 - no register bits, 2-byte immediate value)
    df2f  81 46 ea                      ; JPE (opcode 0xea, type=0x06 - no register bits, 2-byte immediate value)
    df32  83 c6 e2                      ; JPO (opcode 0xe2, type=0x06 - no register bits, 2-byte immediate value)
    df35  d0 06 ca                      ; JZ (opcode 0xca, type=0x06 - no register bits, 2-byte immediate value)
    df38  20 46 3a                      ; LDA (opcode 0x3a, type=0x06 - no register bits, 2-byte immediate value)
    df3b  26 09 0a                      ; LDX (LDAX) (base opcode 0x0a, type=0x09 - reg pair bits)
    df3e  43 06 2a                      ; LHLD (opcode 0x2a, type=0x06 - no register bits, 2-byte immediate value)
    df41  c2 4a 01                      ; LXI (base opcode 0x01, type=0x0a - reg pair bits, 2-byte value)
    df44  b2 45 06                      ; MVI (base opcode 0x06, type=0x05 - register and immediate 1-byte value)
    df47  7d 83 40                      ; MOV (base opcode 0x40, type=0x03 - two registers coded in the opcode)
    df4a  7c 00 00                      ; NOP (opcode 0x00, type=0x00 - no register bits in the opcode)
    df4d  90 41 b0                      ; ORA (base opcode 0xb0, type=0x01 - source register coded in opcode)
    df50  92 44 f6                      ; ORI (opcode 0xf6, type=0x04 - no register bits, 1-byte immediate value)
    df53  ad 04 d3                      ; OUT (opcode 0xd3, type=0x04 - no register bits, 1-byte immediate value)
    df56  91 cc 00                      ; ORG - compiler special instruction, arg code 0x0c 
    df59  1a 00 e9                      ; PCHL (opcode 0xe9, type=0x00 - no register bits in the opcode)
    df5c  7c 08 c1                      ; POP (base opcode 0xc1, type=0x08 - register pair coded in the opcode)
    df5f  ac c8 c5                      ; PUSH (base opcode 0xc5, type=0x08 - register pair coded in the opcode)
    df62  0b 00 17                      ; RAL (opcode 0x17, type=0x00 - no register bits in the opcode)
    df65  0c 80 1f                      ; RAR (opcode 0x1f, type=0x00 - no register bits in the opcode)
    df68  60 c0 07                      ; RLC (opcode 0x07, type=0x00 - no register bits in the opcode)
    df6b  90 c0 0f                      ; RRC (opcode 0x0f, type=0x00 - no register bits in the opcode)
    df6e  2d 00 c9                      ; RET (opcode 0xc9, type=0x00 - no register bits in the opcode)
    df71  18 00 d8                      ; RC (opcode 0xd8, type=0x00 - no register bits in the opcode)
    df74  70 c0 d0                      ; RNC (opcode 0xd0, type=0x00 - no register bits in the opcode)
    df77  d0 00 c8                      ; RZ (opcode 0xc8, type=0x00 - no register bits in the opcode)
    df7a  76 80 c0                      ; RNZ (opcode 0xc0, type=0x00 - no register bits in the opcode)
    df7d  80 00 f0                      ; RP (opcode 0xf0, type=0x00 - no register bits in the opcode)
    df80  68 00 f8                      ; RM (opcode 0xf8, type=0x00 - no register bits in the opcode)
    df83  81 40 e8                      ; RPE (opcode 0xe8, type=0x00 - no register bits in the opcode)
    df86  83 c0 e0                      ; RPO (opcode 0xe0, type=0x00 - no register bits in the opcode)
    df89  9d 0b c7                      ; RST (opcode 0xc7, type=0x0b - rst number is coded in the opcode)
    df8c  10 81 98                      ; SBB (base opcode 0x98, type=0x01 - source register coded in opcode)
    df8f  12 44 de                      ; SBI (opcode 0xde, type=0x04 - no register bits, 1-byte immediate value)
    df92  43 06 22                      ; SHLD (opcode 0x22, type=0x06 - no register bits, 2-byte immediate value)
    df95  82 00 f9                      ; SPHL (opcode 0xf9, type=0x00 - no register bits in the opcode)
    df98  a0 46 32                      ; STA (opcode 0x32, type=0x06 - no register bits, 2-byte immediate value)
    df9b  a6 09 02                      ; STX (STAX) (base opcode 0x02, type=0x09 - reg pair bits)
    df9e  a0 c0 37                      ; STC (opcode 0x37, type=0x00 - no register bits in the opcode)
    dfa1  a8 81 90                      ; SUB (base opcode 0x90, type=0x01 - source register coded in opcode)
    dfa4  aa 44 d6                      ; SUI (opcode 0xd6, type=0x04 - no register bits, 1-byte immediate value)
    dfa7  1a 00 eb                      ; XCHG (opcode 0xeb, type=0x00 - no register bits in the opcode)
    dfaa  90 41 a8                      ; XRA (base opcode 0xa8, type=0x01 - source register coded in opcode)
    dfad  92 44 ee                      ; XRI (opcode 0xee, type=0x04 - no register bits, 1-byte immediate value)
    dfb0  a2 00 e3                      ; XTHL (opcode 0xe3, type=0x00 - no register bits in the opcode)

ERRORS_STR:
    dfb3  0a 45 52 52 4f 52 53 20   db 0x0a, "ERRORS "
    dfbb  44 45 54 45 43 54 45 44   db "DETECTED"
    dfc3  3a 00                     db ":", 0x00

HELLO_STR:
    dfc5  0a 41 53 53 4d 2e 2a 6d   db 0x0a, "ASSM.*М"
    dfcd  69 6b 72 6f 6e 2a 0a 2a   db "ИКРОН*", 0x0a, "*"
    dfd5  00                        db 0x00

PLEASE_1_2_3_STR:
    dfd6  50 4c 45 41 53 45 20 31   db "PLEASE 1"
    dfde  2c 32 2c 33 2c 43 54 52   db ",2,3,CTR"
    dfe6  4c 22 43 22 00            db "L\"C\"", 0x00

TOO_LONG_STR:
    dfeb  54 4f 4f 20 4c 4f 4e 47   db "TOO LONG"
    df3f  00                        db 0x00
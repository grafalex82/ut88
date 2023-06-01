; CP/M-64 Basic Disk Operating System (BDOS)
;
; This code is loaded to the 0xcc00-0xd9ff by CP/M initial bootloader, and initially is located at
; 0x3c00-0x49ff address range of the CP/M binary.
;
; ?????????????? Description TBD
;
;
; Important variables:
; 0003  - I/O Byte ?????
; cf0d  - ????? flag indicating that output to the printer is enabled in addition to console output
; cf0e  - if a keypress is detected, entered symbol is buffered in this variable
; cf0f  - save caller's SP (2 byte)
; cf43  - function arguments (2 byte)
; cf45  - function return code or return value(2 byte)
; d9d6  - function argument (low byte)
cc00  f9         SPHL
cc01  16 00      MVI D, 00
cc03  00         NOP
cc04  00         NOP
cc05  6b         MOV L, E


BDOS_ENTRY:
    cc06  c3 11 cc   JMP REAL_BDOS_ENTRY (cc11)

DISK_READ_WRITE_ERROR_PTR:
    cc09  99 cc     dw DISK_READ_WRITE_ERROR (cc99)

DISK_SELECT_ERROR_PTR:
    cc0b  a5 cc     dw DISK_SELECT_ERROR (cca5)

DISK_READ_ONLY_ERROR_PTR:
    cc0d  ab cc     dw DISK_READ_ONLY_ERROR (ccab)

FILE_READ_ONLY_ERROR_PTR:
    cc0f  b1 cc     dw FILE_READ_ONLY_ERROR (ccb1)


; The BDOS entry (entry point for all BDOS functions)
;
; Arguments:
; C     - function number
; DE    - arguments
;
; Returns:
; A     - result (low byte of the result)
; B     - high byte of the result
REAL_BDOS_ENTRY:
    cc11  eb         XCHG                       ; Store arguments at cf43
    cc12  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)
    cc15  eb         XCHG

    cc16  7b         MOV A, E                   ; Store argument low byte separately
    cc17  32 d6 d9   STA FUNCTION_BYTE_ARGUMENT (d9d6)

    cc1a  21 00 00   LXI HL, 0000               ; Prepare result code
    cc1d  22 45 cf   SHLD FUNCTION_RETURN_VALUE (cf45)

    cc20  39         DAD SP                     ; Save caller's SP
    cc21  22 0f cf   SHLD BDOS_SAVE_SP (cf0f)

    cc24  31 41 cf   LXI SP, cf41               ; And set our own stack

    cc27  af         XRA A                      ; ????
    cc28  32 e0 d9   STA d9e0
    cc2b  32 de d9   STA d9de

    cc2e  21 74 d9   LXI HL, BDOS_HANDLER_RETURN (d974) ; Set the return address
    cc31  e5         PUSH HL

    cc32  79         MOV A, C                   ; Function with numbers >= 0x29 are not supported
    cc33  fe 29      CPI A, 29
    cc35  d0         RNC

    cc36  4b         MOV C, E                   ; One byte arguments are available in C register
    
    cc37  21 47 cc   LXI HL, FUNCTION_HANDLERS_TABLE (cc47)
    cc3a  5f         MOV E, A                   ; DE is a function number
    cc3b  16 00      MVI D, 00

    cc3d  19         DAD DE                     ; Calculate the entry pointer in the table
    cc3e  19         DAD DE

    cc3f  5e         MOV E, M                   ; Load the handler address in DE
    cc40  23         INX HL
    cc41  56         MOV D, M

    cc42  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Load arguments in HL

    cc45  eb         XCHG                       ; Jump to the handler
    cc46  e9         PCHL


FUNCTION_HANDLERS_TABLE:
    cc47  03 da      dw BIOS_WARM_BOOT (da03)       ; Function 0x00 - Warm boot
    cc48  c8 ce      dw CONSOLE_INPUT (cec8)        ; Function 0x01 - Console input
    cc4b  90 cd      dw PUT_CHAR (cd90)             ; Function 0x02 - Console output
    cc4d  ce ce      dw IN_BYTE (cece)              ; Function 0x03 - Input a byte from the tape
    cc4f  12 da      dw BIOS_OUT_BYTE (da12)        ; Function 0x04 - Output a byte to the tape
    cc51  0f da      dw BIOS_PRINT_BYTE (da0f)      ; Function 0x05 - Print (List) a byte
    cc53  d4 ce      dw DIRECT_CONSOLE_IO (ced4)    ; Function 0x06 - Direct console input or output
    cc55  ed ce      dw GET_IO_BYTE (ceed)          ; Function 0x07 - Get I/O Byte
    cc57  f3 ce      dw SET_IO_BYTE (cef3)          ; Function 0x08 - Set I/O Byte
    cc59  f8 ce      dw PRINT_STRING (cef8)         ; Function 0x09 - print string
cc5b  e1 cd 
    cc5d  fe ce      dw GET_CONSOLE_STATUS (cefe)   ; Function 0x0b - get console status (if a button pressed)
    cc5f  7e d8      dw GET_BDOS_VERSION (d87e)     ; Function 0x0c - get version
cc61  83         ADD E
cc62  d8         RC
cc63  45         MOV B, L
cc64  d8         RC
cc65  9c         SBB H
cc66  d8         RC
cc67  a5         ANA L
cc68  d8         RC
cc69  ab         XRA E
cc6a  d8         RC
cc6b  c8         RZ
cc6c  d8         RC
cc6d  d7         RST 2
cc6e  d8         RC
cc6f  e0         RPO
cc70  d8         RC
cc71  e6 d8      ANI A, d8
cc73  ec d8 f5   CPE f5d8
cc76  d8         RC
cc77  fe d8      CPI A, d8
cc79  04         INR B
cc7a  d9         db d9
cc7b  0a         LDAX BC
cc7c  d9         db d9
cc7d  11 d9 2c   LXI DE, 2cd9
cc80  d1         POP DE
cc81  17         RAL
cc82  d9         db d9
cc83  1d         DCR E
cc84  d9         db d9
cc85  26 d9      MVI H, d9
cc87  2d         DCR L
cc88  d9         db d9
cc89  41         MOV B, C
cc8a  d9         db d9
cc8b  47         MOV B, A
cc8c  d9         db d9
cc8d  4d         MOV C, L
cc8e  d9         db d9
cc8f  0e d8      MVI C, d8
cc91  53         MOV D, E
cc92  d9         db d9
cc93  04         INR B
cc94  cf         RST 1
cc95  04         INR B
cc96  cf         RST 1
cc97  9b         SBB E
cc98  d9         db d9

DISK_READ_WRITE_ERROR:
cc99  21 ca cc   LXI HL, ccca
cc9c  cd e5 cc   CALL cce5
cc9f  fe 03      CPI A, 03
cca1  ca 00 00   JZ 0000
cca4  c9         RET

DISK_SELECT_ERROR:
cca5  21 d5 cc   LXI HL, ccd5
cca8  c3 b4 cc   JMP ccb4

DISK_READ_ONLY_ERROR:
ccab  21 e1 cc   LXI HL, cce1
ccae  c3 b4 cc   JMP ccb4

FILE_READ_ONLY_ERROR:
ccb1  21 dc cc   LXI HL, ccdc
????:
ccb4  cd e5 cc   CALL cce5
ccb7  c3 00 00   JMP 0000
????:
ccba  42         MOV B, D
ccbb  64         MOV H, H
ccbc  6f         MOV L, A
ccbd  73         MOV M, E
ccbe  20         db 20
ccbf  45         MOV B, L
ccc0  72         MOV M, D
ccc1  72         MOV M, D
ccc2  20         db 20
ccc3  4f         MOV C, A
ccc4  6e         MOV L, M
ccc5  20         db 20
????:
ccc6  20         db 20
ccc7  3a 20 24   LDA 2420
????:
ccca  42         MOV B, D
cccb  61         MOV H, C
cccc  64         MOV H, H
cccd  20         db 20
ccce  53         MOV D, E
cccf  65         MOV H, L
ccd0  63         MOV H, E
ccd1  74         MOV M, H
ccd2  6f         MOV L, A
ccd3  72         MOV M, D
ccd4  24         INR H
????:
ccd5  53         MOV D, E
ccd6  65         MOV H, L
ccd7  6c         MOV L, H
ccd8  65         MOV H, L
ccd9  63         MOV H, E
ccda  74         MOV M, H
ccdb  24         INR H
????:
ccdc  46         MOV B, M
ccdd  69         MOV L, C
ccde  6c         MOV L, H
ccdf  65         MOV H, L
cce0  20         db 20
????:
cce1  52         MOV D, D
cce2  2f         CMA
cce3  4f         MOV C, A
cce4  24         INR H
????:
cce5  e5         PUSH HL
cce6  cd c9 cd   CALL cdc9
cce9  3a 42 cf   LDA cf42
ccec  c6 41      ADI A, 41
ccee  32 c6 cc   STA ccc6
ccf1  01 ba cc   LXI BC, ccba
ccf4  cd d3 cd   CALL DO_PRINT_STRING (cdd3)
ccf7  c1         POP BC
ccf8  cd d3 cd   CALL DO_PRINT_STRING (cdd3)

; Wait for a character from the console input (keyboard)
;
; Return: A - entered symbol
WAIT_CONSOLE_CHAR:
    ccfb  21 0e cf   LXI HL, CONSOLE_KEY_PRESSED (cf0e) ; Check if we have a character in the byffer already
    ccfe  7e         MOV A, M                           ; Get the buffered char and reset the buffer
    ccff  36 00      MVI M, 00
    cd01  b7         ORA A
    cd02  c0         RNZ

    cd03  c3 09 da   JMP BIOS_CONSOLE_INPUT (da09)  ; If no character ready - wait for it using BIOS routines


; Function 0x01 - Console input
;
; The function waits for a console character (if not received already), and echo it on the screen
;
; Return: A - entered character code
DO_CONSOLE_INPUT:
    cd06  cd fb cc   CALL WAIT_CONSOLE_CHAR (ccfb)  ; Wait for the character
    
    cd09  cd 14 cd   CALL IS_SPECIAL_SYMBOL (cd14)  ; Skip echoing non-printable characters
    cd0c  d8         RC

    cd0d  f5         PUSH PSW                   ; Echo entered character
    cd0e  4f         MOV C, A
    cd0f  cd 90 cd   CALL PUT_CHAR (cd90)
    cd12  f1         POP PSW
    cd13  c9         RET


; Check if A has a special symbol
;
; Function raises Z flag if A contains 0x0d (carriage return), 0x0a (line feed), 0x08 (backspace), 
; or 0x09 (tab)
; Function raises C flag if the symbol is not printable (symbol code < 0x20)
IS_SPECIAL_SYMBOL:
    cd14  fe 0d      CPI A, 0d
    cd16  c8         RZ
    cd17  fe 0a      CPI A, 0a
    cd19  c8         RZ
    cd1a  fe 09      CPI A, 09
    cd1c  c8         RZ
    cd1d  fe 08      CPI A, 08
    cd1f  c8         RZ
    cd20  fe 20      CPI A, 20
    cd22  c9         RET


; Check if a key is pressed
;
; This function not just calls BIOS IS_KEY_PRESSED function, it also checks if a Ctrl-S combination
; is pressed. If yes, Ctrl-C combination will do the software reset.
;
; If a key is pressed, entered symbol is buffered at cf0e
;
; Return: A=01 if key is pressed (Z flag is off), A=00 otherwise (Z flag is on)
IS_KEY_PRESSED:
    cd23  3a 0e cf   LDA CONSOLE_KEY_PRESSED (cf0e) ; Check if there is a symbol in the buffer already
    cd26  b7         ORA A
    cd27  c2 45 cd   JNZ IS_KEY_PRESSED_EXIT (cd45)

    cd2a  cd 06 da   CALL BIOS_IS_KEY_PRESSED (da06); Return if no button is pressed
    cd2d  e6 01      ANI A, 01
    cd2f  c8         RZ

    cd30  cd 09 da   CALL BIOS_CONSOLE_INPUT (da09) ; Check if Ctrl-S is pressed (Stop Screen condition)
    cd33  fe 13      CPI A, 13
    cd35  c2 42 cd   JNZ cd42

    cd38  cd 09 da   CALL BIOS_CONSOLE_INPUT (da09) ; If Ctrl-C is pressed - do soft reset
    cd3b  fe 03      CPI A, 03
    cd3d  ca 00 00   JZ 0000

    cd40  af         XRA A                      ; Other symbols are invalid
    cd41  c9         RET

IS_KEY_PRESSED_OK:
    cd42  32 0e cf   STA CONSOLE_KEY_PRESSED (cf0e) ; Some valid symbol is entered - buffer it

IS_KEY_PRESSED_EXIT:
    cd45  3e 01      MVI A, 01                  ; Indicate that a button is pressed
    cd47  c9         RET


;
DO_PUT_CHAR:
    cd48  3a 0a cf   LDA cf0a                   ; ???????
    cd4b  b7         ORA A
    cd4c  c2 62 cd   JNZ DO_PUT_CHAR_1 (cd62)

    cd4f  c5         PUSH BC                    ; Get a chance to process Ctrl-S/Ctrl-C combinations
    cd50  cd 23 cd   CALL IS_KEY_PRESSED (cd23) ; to break long output
    cd53  c1         POP BC

    cd54  c5         PUSH BC                    ; Print the character normally
    cd55  cd 0c da   CALL BIOS_PUT_CHAR (da0c)
    cd58  c1         POP BC

    cd59  c5         PUSH BC
    cd5a  3a 0d cf   LDA PRINTER_ENABLED (cf0d) ; If printer enabled - print the char on printer as well
    cd5d  b7         ORA A
    cd5e  c4 0f da   CNZ BIOS_PRINT_CHAR (da0f)
    cd61  c1         POP BC

DO_PUT_CHAR_1:
    cd62  79         MOV A, C                   ; Load cursor position index   ?????
    cd63  21 0c cf   LXI HL, cf0c

    cd66  fe 7f      CPI A, 7f                  ; Do not print 0x7f character
    cd68  c8         RZ

    cd69  34         INR M                      ; Normal characters advance the cursor

    cd6a  fe 20      CPI A, 20                  ; Nothing else needed to do for printable characters
    cd6c  d0         RNC

    cd6d  35         DCR M                      ; Special characters do not advance the cursor, revert bacl

    cd6e  7e         MOV A, M                   ; Check if we reached start of string
    cd6f  b7         ORA A
    cd70  c8         RZ

    cd71  79         MOV A, C                   ; Check if the printed symbol is a backspace
    cd72  fe 08      CPI A, 08
    cd74  c2 79 cd   JNZ DO_PUT_CHAR_2 (cd79)

    cd77  35         DCR M                      ; Backspace moves cursor left
    cd78  c9         RET

DO_PUT_CHAR_2:
    cd79  fe 0a      CPI A, 0a                  ; No cursor position changes on all characters except for CR
    cd7b  c0         RNZ

    cd7c  36 00      MVI M, 00                  ; Reset the cursor position in case of carriage return
    cd7e  c9         RET


????:
cd7f  79         MOV A, C
cd80  cd 14 cd   CALL IS_SPECIAL_SYMBOL (cd14)
cd83  d2 90 cd   JNC PUT_CHAR (cd90)
cd86  f5         PUSH PSW
cd87  0e 5e      MVI C, 5e
cd89  cd 48 cd   CALL DO_PUT_CHAR (cd48)
cd8c  f1         POP PSW
cd8d  f6 40      ORI A, 40
cd8f  4f         MOV C, A


; Function 0x02 - Put a char to console (and printer)
;
; Parameters: 
; C - character to output
PUT_CHAR:
    cd90  79         MOV A, C                   ; Tab symbol is processed separately
    cd91  fe 09      CPI A, 09
    cd93  c2 48 cd   JNZ DO_PUT_CHAR (cd48)     ; All other symbols are processed by DO_PUT_CHAR

PUT_CHAR_TAB_LOOP:
    cd96  0e 20      MVI C, 20                  ; Print spaces until next 8-char column
    cd98  cd 48 cd   CALL DO_PUT_CHAR (cd48)

    cd9b  3a 0c cf   LDA cf0c                   ; Check if we reached next 8-char column
    cd9e  e6 07      ANI A, 07
    cda0  c2 96 cd   JNZ cd96

    cda3  c9         RET


????:
cda4  cd ac cd   CALL cdac
cda7  0e 20      MVI C, 20
cda9  cd 0c da   CALL BIOS_PUT_CHAR (da0c)

????:
cdac  0e 08      MVI C, 08
cdae  c3 0c da   JMP BIOS_PUT_CHAR (da0c)

????:
cdb1  0e 23      MVI C, 23
cdb3  cd 48 cd   CALL DO_PUT_CHAR (cd48)
cdb6  cd c9 cd   CALL cdc9
????:
cdb9  3a 0c cf   LDA cf0c
cdbc  21 0b cf   LXI HL, cf0b
cdbf  be         CMP M
cdc0  d0         RNC
cdc1  0e 20      MVI C, 20
cdc3  cd 48 cd   CALL DO_PUT_CHAR (cd48)
cdc6  c3 b9 cd   JMP cdb9
????:
cdc9  0e 0d      MVI C, 0d
cdcb  cd 48 cd   CALL DO_PUT_CHAR (cd48)
cdce  0e 0a      MVI C, 0a
cdd0  c3 48 cd   JMP DO_PUT_CHAR (cd48)

; Print string pointed by BC, until '$' symbol is reached
DO_PRINT_STRING:
    cdd3  0a         LDAX BC                    ; Load next byte

    cdd4  fe 24      CPI A, 24                  ; Stop printing when '$' is reached
    cdd6  c8         RZ

    cdd7  03         INX BC
    cdd8  c5         PUSH BC

    cdd9  4f         MOV C, A                   ; Print next character
    cdda  cd 90 cd   CALL PUT_CHAR (cd90)

    cddd  c1         POP BC
    cdde  c3 d3 cd   JMP DO_PRINT_STRING (cdd3)

????:
cde1  3a 0c cf   LDA cf0c
cde4  32 0b cf   STA cf0b
cde7  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
cdea  4e         MOV C, M
cdeb  23         INX HL
cdec  e5         PUSH HL
cded  06 00      MVI B, 00
????:
cdef  c5         PUSH BC
cdf0  e5         PUSH HL
????:
cdf1  cd fb cc   CALL WAIT_CONSOLE_CHAR (ccfb)
cdf4  e6 7f      ANI A, 7f
cdf6  e1         POP HL
cdf7  c1         POP BC
cdf8  fe 0d      CPI A, 0d
cdfa  ca c1 ce   JZ cec1
cdfd  fe 0a      CPI A, 0a
cdff  ca c1 ce   JZ cec1
ce02  fe 08      CPI A, 08
ce04  c2 16 ce   JNZ ce16
ce07  78         MOV A, B
ce08  b7         ORA A
ce09  ca ef cd   JZ cdef
ce0c  05         DCR B
ce0d  3a 0c cf   LDA cf0c
ce10  32 0a cf   STA cf0a
ce13  c3 70 ce   JMP ce70
????:
ce16  fe 7f      CPI A, 7f
ce18  c2 26 ce   JNZ ce26
ce1b  78         MOV A, B
ce1c  b7         ORA A
ce1d  ca ef cd   JZ cdef
ce20  7e         MOV A, M
ce21  05         DCR B
ce22  2b         DCX HL
ce23  c3 a9 ce   JMP cea9
????:
ce26  fe 05      CPI A, 05
ce28  c2 37 ce   JNZ ce37
ce2b  c5         PUSH BC
ce2c  e5         PUSH HL
ce2d  cd c9 cd   CALL cdc9
ce30  af         XRA A
ce31  32 0b cf   STA cf0b
ce34  c3 f1 cd   JMP cdf1
????:
ce37  fe 10      CPI A, 10
ce39  c2 48 ce   JNZ ce48
ce3c  e5         PUSH HL
ce3d  21 0d cf   LXI HL, PRINTER_ENABLED (cf0d)
ce40  3e 01      MVI A, 01
ce42  96         SUB M
ce43  77         MOV M, A
ce44  e1         POP HL
ce45  c3 ef cd   JMP cdef
????:
ce48  fe 18      CPI A, 18
ce4a  c2 5f ce   JNZ ce5f
ce4d  e1         POP HL
????:
ce4e  3a 0b cf   LDA cf0b
ce51  21 0c cf   LXI HL, cf0c
ce54  be         CMP M
ce55  d2 e1 cd   JNC cde1
ce58  35         DCR M
ce59  cd a4 cd   CALL cda4
ce5c  c3 4e ce   JMP ce4e
????:
ce5f  fe 15      CPI A, 15
ce61  c2 6b ce   JNZ ce6b
ce64  cd b1 cd   CALL cdb1
ce67  e1         POP HL
ce68  c3 e1 cd   JMP cde1
????:
ce6b  fe 12      CPI A, 12
ce6d  c2 a6 ce   JNZ cea6
????:
ce70  c5         PUSH BC
ce71  cd b1 cd   CALL cdb1
ce74  c1         POP BC
ce75  e1         POP HL
ce76  e5         PUSH HL
ce77  c5         PUSH BC
????:
ce78  78         MOV A, B
ce79  b7         ORA A
ce7a  ca 8a ce   JZ ce8a
ce7d  23         INX HL
ce7e  4e         MOV C, M
ce7f  05         DCR B
ce80  c5         PUSH BC
ce81  e5         PUSH HL
ce82  cd 7f cd   CALL cd7f
ce85  e1         POP HL
ce86  c1         POP BC
ce87  c3 78 ce   JMP ce78
????:
ce8a  e5         PUSH HL
ce8b  3a 0a cf   LDA cf0a
ce8e  b7         ORA A
ce8f  ca f1 cd   JZ cdf1
ce92  21 0c cf   LXI HL, cf0c
ce95  96         SUB M
ce96  32 0a cf   STA cf0a
????:
ce99  cd a4 cd   CALL cda4
ce9c  21 0a cf   LXI HL, cf0a
ce9f  35         DCR M
cea0  c2 99 ce   JNZ ce99
cea3  c3 f1 cd   JMP cdf1
????:
cea6  23         INX HL
cea7  77         MOV M, A
cea8  04         INR B
????:
cea9  c5         PUSH BC
ceaa  e5         PUSH HL
ceab  4f         MOV C, A
ceac  cd 7f cd   CALL cd7f
ceaf  e1         POP HL
ceb0  c1         POP BC
ceb1  7e         MOV A, M
ceb2  fe 03      CPI A, 03
ceb4  78         MOV A, B
ceb5  c2 bd ce   JNZ cebd
ceb8  fe 01      CPI A, 01
ceba  ca 00 00   JZ 0000
????:
cebd  b9         CMP C
cebe  da ef cd   JC cdef
????:
cec1  e1         POP HL
cec2  70         MOV M, B
cec3  0e 0d      MVI C, 0d
cec5  c3 48 cd   JMP DO_PUT_CHAR (cd48)

; Function 0x01 - Console input
CONSOLE_INPUT:
    cec8  cd 06 cd   CALL DO_CONSOLE_INPUT (cd06)
    cecb  c3 01 cf   JMP FUNCTION_EXIT (cf01)

; Function 0x03 - Input byte from the tape reader
; 
; Return: received byte in A
IN_BYTE:
    cece  cd 15 da   CALL BIOS_IN_BYTE (da15)   ; Input a byte using BIOS/Monitor functions
    ced1  c3 01 cf   JMP FUNCTION_EXIT (cf01)

; Function 0x06 - Direct console input or output
;
; As output: The function prints the character directly using BIOS routines, without Ctrl-S key 
; combination handling.
;
; Arguments:
; E (or C)  - 0xff for input, or a character symbol for output
; 
; Returns:
; A - char code of the input character, or 0x00 if no character ready (input mode only)
DIRECT_CONSOLE_IO:
    ced4  79         MOV A, C                   ; Check if the byte is 0xff
    ced5  3c         INR A
    ced6  ca e0 ce   JZ DIRECT_CONSOLE_INPUT (cee0)

    ced9  3c         INR A                      ; ??????
    ceda  ca 06 da   JZ BIOS_IS_KEY_PRESSED (da06)

    cedd  c3 0c da   JMP BIOS_PUT_CHAR (da0c)   ; In output mode - print characters as usual

DIRECT_CONSOLE_INPUT:
    cee0  cd 06 da   CALL BIOS_IS_KEY_PRESSED (da06); Check if a character is ready
    cee3  b7         ORA A
    cee4  ca 91 d9   JZ d991

    cee7  cd 09 da   CALL BIOS_CONSOLE_INPUT (da09) ; Input the character. No echo is performed.
    ceea  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x07 - Get I/O byte
;
; Get the byte from its location at 0x0003
GET_IO_BYTE:
    ceed  3a 03 00   LDA 0003
    cef0  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x08 - Set I/O byte
;
; Store the byte to its location at 0x0003
SET_IO_BYTE:
    cef3  21 03 00   LXI HL, 0003
    cef6  71         MOV M, C
    cef7  c9         RET


; Function 0x09 - Print string
;
; Arguments:
; DE - pointer to the string to print
PRINT_STRING:
    cef8  eb         XCHG                       ; Move pointer to BC
    cef9  4d         MOV C, L
    cefa  44         MOV B, H
    cefb  c3 d3 cd   JMP DO_PRINT_STRING (cdd3)

; Function 0x0b - check console status (check if a symbol entered on keyboard)
;
; Returns: A=01 if a key is pressed, A=00 if no key pressed
GET_CONSOLE_STATUS:
    cefe  cd 23 cd   CALL IS_KEY_PRESSED (cd23)


FUNCTION_EXIT:
    cf01  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)   ; Store A in the predefined variable
    cf04  c9         RET

????:
cf05  3e 01      MVI A, 01
cf07  c3 01 cf   JMP FUNCTION_EXIT (cf01)
????:
cf0a  00         NOP
????:
cf0b  00         NOP
????:
cf0c  00         NOP

PRINTER_ENABLED:
    cf0d  00         NOP

CONSOLE_KEY_PRESSED:
    cf0e  00           db 00

BDOS_SAVE_SP:
    cf0f  00 00        dw 0000

cf11  00         NOP
cf12  00         NOP
cf13  00         NOP
cf14  00         NOP
cf15  00         NOP
cf16  00         NOP
cf17  00         NOP
cf18  00         NOP
cf19  00         NOP
cf1a  00         NOP
cf1b  00         NOP
cf1c  00         NOP
cf1d  00         NOP
cf1e  00         NOP
cf1f  00         NOP
cf20  00         NOP
cf21  00         NOP
cf22  00         NOP
cf23  00         NOP
cf24  00         NOP
cf25  00         NOP
cf26  00         NOP
cf27  00         NOP
cf28  00         NOP
cf29  00         NOP
cf2a  00         NOP
cf2b  00         NOP
cf2c  00         NOP
cf2d  00         NOP
cf2e  00         NOP
cf2f  00         NOP
cf30  00         NOP
cf31  00         NOP
cf32  00         NOP
cf33  00         NOP
cf34  00         NOP
cf35  00         NOP
cf36  00         NOP
cf37  00         NOP
cf38  00         NOP
cf39  00         NOP
cf3a  00         NOP
cf3b  00         NOP
cf3c  00         NOP
cf3d  00         NOP
cf3e  00         NOP
cf3f  00         NOP
cf40  00         NOP

BDOS_STACK:
    cf41  00         NOP

????:
cf42  00         NOP


FUNCTION_ARGUMENTS:
    cf43  00 00      dw 0000

FUNCTION_RETURN_VALUE:
    cf45  00 00      dw 0000

????:
cf47  21 0b cc   LXI HL, DISK_SELECT_ERROR_PTR (cc0b)
????:
cf4a  5e         MOV E, M
cf4b  23         INX HL
cf4c  56         MOV D, M
cf4d  eb         XCHG
cf4e  e9         PCHL
????:
cf4f  0c         INR C
????:
cf50  0d         DCR C
cf51  c8         RZ
cf52  1a         LDAX DE
cf53  77         MOV M, A
cf54  13         INX DE
cf55  23         INX HL
cf56  c3 50 cf   JMP cf50
????:
cf59  3a 42 cf   LDA cf42
cf5c  4f         MOV C, A
cf5d  cd 1b da   CALL da1b
cf60  7c         MOV A, H
cf61  b5         ORA L
cf62  c8         RZ
cf63  5e         MOV E, M
cf64  23         INX HL
cf65  56         MOV D, M
cf66  23         INX HL
cf67  22 b3 d9   SHLD d9b3
cf6a  23         INX HL
cf6b  23         INX HL
cf6c  22 b5 d9   SHLD d9b5
cf6f  23         INX HL
cf70  23         INX HL
cf71  22 b7 d9   SHLD d9b7
cf74  23         INX HL
cf75  23         INX HL
cf76  eb         XCHG
cf77  22 d0 d9   SHLD d9d0
cf7a  21 b9 d9   LXI HL, d9b9
cf7d  0e 08      MVI C, 08
cf7f  cd 4f cf   CALL cf4f
cf82  2a bb d9   LHLD d9bb
cf85  eb         XCHG
cf86  21 c1 d9   LXI HL, d9c1
cf89  0e 0f      MVI C, 0f
cf8b  cd 4f cf   CALL cf4f
cf8e  2a c6 d9   LHLD d9c6
cf91  7c         MOV A, H
cf92  21 dd d9   LXI HL, d9dd
cf95  36 ff      MVI M, ff
cf97  b7         ORA A
cf98  ca 9d cf   JZ cf9d
cf9b  36 00      MVI M, 00
????:
cf9d  3e ff      MVI A, ff
cf9f  b7         ORA A
cfa0  c9         RET
????:
cfa1  cd 18 da   CALL da18
cfa4  af         XRA A
cfa5  2a b5 d9   LHLD d9b5
cfa8  77         MOV M, A
cfa9  23         INX HL
cfaa  77         MOV M, A
cfab  2a b7 d9   LHLD d9b7
cfae  77         MOV M, A
cfaf  23         INX HL
cfb0  77         MOV M, A
cfb1  c9         RET
????:
cfb2  cd 27 da   CALL da27
cfb5  c3 bb cf   JMP cfbb
????:
cfb8  cd 2a da   CALL da2a
????:
cfbb  b7         ORA A
cfbc  c8         RZ
cfbd  21 09 cc   LXI HL, DISK_READ_WRITE_ERROR_PTR (cc09)
cfc0  c3 4a cf   JMP cf4a
????:
cfc3  2a ea d9   LHLD d9ea
cfc6  0e 02      MVI C, 02
cfc8  cd ea d0   CALL d0ea
cfcb  22 e5 d9   SHLD d9e5
cfce  22 ec d9   SHLD d9ec
????:
cfd1  21 e5 d9   LXI HL, d9e5
cfd4  4e         MOV C, M
cfd5  23         INX HL
cfd6  46         MOV B, M
cfd7  2a b7 d9   LHLD d9b7
cfda  5e         MOV E, M
cfdb  23         INX HL
cfdc  56         MOV D, M
cfdd  2a b5 d9   LHLD d9b5
cfe0  7e         MOV A, M
cfe1  23         INX HL
cfe2  66         MOV H, M
cfe3  6f         MOV L, A
????:
cfe4  79         MOV A, C
cfe5  93         SUB E
cfe6  78         MOV A, B
cfe7  9a         SBB D
cfe8  d2 fa cf   JNC cffa
cfeb  e5         PUSH HL
cfec  2a c1 d9   LHLD d9c1
cfef  7b         MOV A, E
cff0  95         SUB L
cff1  5f         MOV E, A
cff2  7a         MOV A, D
cff3  9c         SBB H
cff4  57         MOV D, A
cff5  e1         POP HL
cff6  2b         DCX HL
cff7  c3 e4 cf   JMP cfe4
????:
cffa  e5         PUSH HL
cffb  2a c1 d9   LHLD d9c1
cffe  19         DAD DE
cfff  da 0f d0   JC d00f
d002  79         MOV A, C
d003  95         SUB L
d004  78         MOV A, B
d005  9c         SBB H
d006  da 0f d0   JC d00f
d009  eb         XCHG
d00a  e1         POP HL
d00b  23         INX HL
d00c  c3 fa cf   JMP cffa
????:
d00f  e1         POP HL
d010  c5         PUSH BC
d011  d5         PUSH DE
d012  e5         PUSH HL
d013  eb         XCHG
d014  2a ce d9   LHLD d9ce
d017  19         DAD DE
d018  44         MOV B, H
d019  4d         MOV C, L
d01a  cd 1e da   CALL da1e
d01d  d1         POP DE
d01e  2a b5 d9   LHLD d9b5
d021  73         MOV M, E
d022  23         INX HL
d023  72         MOV M, D
d024  d1         POP DE
d025  2a b7 d9   LHLD d9b7
d028  73         MOV M, E
d029  23         INX HL
d02a  72         MOV M, D
d02b  c1         POP BC
d02c  79         MOV A, C
d02d  93         SUB E
d02e  4f         MOV C, A
d02f  78         MOV A, B
d030  9a         SBB D
d031  47         MOV B, A
d032  2a d0 d9   LHLD d9d0
d035  eb         XCHG
d036  cd 30 da   CALL da30
d039  4d         MOV C, L
d03a  44         MOV B, H
d03b  c3 21 da   JMP da21
????:
d03e  21 c3 d9   LXI HL, d9c3
d041  4e         MOV C, M
d042  3a e3 d9   LDA d9e3
????:
d045  b7         ORA A
d046  1f         RAR
d047  0d         DCR C
d048  c2 45 d0   JNZ d045
d04b  47         MOV B, A
d04c  3e 08      MVI A, 08
d04e  96         SUB M
d04f  4f         MOV C, A
d050  3a e2 d9   LDA d9e2
????:
d053  0d         DCR C
d054  ca 5c d0   JZ d05c
d057  b7         ORA A
d058  17         RAL
d059  c3 53 d0   JMP d053
????:
d05c  80         ADD B
d05d  c9         RET
????:
d05e  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d061  11 10 00   LXI DE, 0010
d064  19         DAD DE
d065  09         DAD BC
d066  3a dd d9   LDA d9dd
d069  b7         ORA A
d06a  ca 71 d0   JZ d071
d06d  6e         MOV L, M
d06e  26 00      MVI H, 00
d070  c9         RET
????:
d071  09         DAD BC
d072  5e         MOV E, M
d073  23         INX HL
d074  56         MOV D, M
d075  eb         XCHG
d076  c9         RET
????:
d077  cd 3e d0   CALL d03e
d07a  4f         MOV C, A
d07b  06 00      MVI B, 00
d07d  cd 5e d0   CALL d05e
d080  22 e5 d9   SHLD d9e5
d083  c9         RET
????:
d084  2a e5 d9   LHLD d9e5
d087  7d         MOV A, L
d088  b4         ORA H
d089  c9         RET
????:
d08a  3a c3 d9   LDA d9c3
d08d  2a e5 d9   LHLD d9e5
????:
d090  29         DAD HL
d091  3d         DCR A
d092  c2 90 d0   JNZ d090
d095  22 e7 d9   SHLD d9e7
d098  3a c4 d9   LDA d9c4
d09b  4f         MOV C, A
d09c  3a e3 d9   LDA d9e3
d09f  a1         ANA C
d0a0  b5         ORA L
d0a1  6f         MOV L, A
d0a2  22 e5 d9   SHLD d9e5
d0a5  c9         RET
????:
d0a6  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d0a9  11 0c 00   LXI DE, 000c
d0ac  19         DAD DE
d0ad  c9         RET
????:
d0ae  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d0b1  11 0f 00   LXI DE, 000f
d0b4  19         DAD DE
d0b5  eb         XCHG
d0b6  21 11 00   LXI HL, 0011
d0b9  19         DAD DE
d0ba  c9         RET
????:
d0bb  cd ae d0   CALL d0ae
d0be  7e         MOV A, M
d0bf  32 e3 d9   STA d9e3
d0c2  eb         XCHG
d0c3  7e         MOV A, M
d0c4  32 e1 d9   STA d9e1
d0c7  cd a6 d0   CALL d0a6
d0ca  3a c5 d9   LDA d9c5
d0cd  a6         ANA M
d0ce  32 e2 d9   STA d9e2
d0d1  c9         RET
????:
d0d2  cd ae d0   CALL d0ae
d0d5  3a d5 d9   LDA d9d5
d0d8  fe 02      CPI A, 02
d0da  c2 de d0   JNZ d0de
d0dd  af         XRA A
????:
d0de  4f         MOV C, A
d0df  3a e3 d9   LDA d9e3
d0e2  81         ADD C
d0e3  77         MOV M, A
d0e4  eb         XCHG
d0e5  3a e1 d9   LDA d9e1
d0e8  77         MOV M, A
d0e9  c9         RET
????:
d0ea  0c         INR C
????:
d0eb  0d         DCR C
d0ec  c8         RZ
d0ed  7c         MOV A, H
d0ee  b7         ORA A
d0ef  1f         RAR
d0f0  67         MOV H, A
d0f1  7d         MOV A, L
d0f2  1f         RAR
d0f3  6f         MOV L, A
d0f4  c3 eb d0   JMP d0eb
????:
d0f7  0e 80      MVI C, 80
d0f9  2a b9 d9   LHLD d9b9
d0fc  af         XRA A
????:
d0fd  86         ADD M
d0fe  23         INX HL
d0ff  0d         DCR C
d100  c2 fd d0   JNZ d0fd
d103  c9         RET
????:
d104  0c         INR C
????:
d105  0d         DCR C
d106  c8         RZ
d107  29         DAD HL
d108  c3 05 d1   JMP d105
????:
d10b  c5         PUSH BC
d10c  3a 42 cf   LDA cf42
d10f  4f         MOV C, A
d110  21 01 00   LXI HL, 0001
d113  cd 04 d1   CALL d104
d116  c1         POP BC
d117  79         MOV A, C
d118  b5         ORA L
d119  6f         MOV L, A
d11a  78         MOV A, B
d11b  b4         ORA H
d11c  67         MOV H, A
d11d  c9         RET
????:
d11e  2a ad d9   LHLD d9ad
d121  3a 42 cf   LDA cf42
d124  4f         MOV C, A
d125  cd ea d0   CALL d0ea
d128  7d         MOV A, L
d129  e6 01      ANI A, 01
d12b  c9         RET
????:
d12c  21 ad d9   LXI HL, d9ad
d12f  4e         MOV C, M
d130  23         INX HL
d131  46         MOV B, M
d132  cd 0b d1   CALL d10b
d135  22 ad d9   SHLD d9ad
d138  2a c8 d9   LHLD d9c8
d13b  23         INX HL
d13c  eb         XCHG
d13d  2a b3 d9   LHLD d9b3
d140  73         MOV M, E
d141  23         INX HL
d142  72         MOV M, D
d143  c9         RET
????:
d144  cd 5e d1   CALL d15e
????:
d147  11 09 00   LXI DE, 0009
d14a  19         DAD DE
d14b  7e         MOV A, M
d14c  17         RAL
d14d  d0         RNC
d14e  21 0f cc   LXI HL, FILE_READ_ONLY_ERROR_PTR (cc0f)
d151  c3 4a cf   JMP cf4a
????:
d154  cd 1e d1   CALL d11e
d157  c8         RZ
d158  21 0d cc   LXI HL, DISK_READ_ONLY_ERROR_PTR (cc0d)
d15b  c3 4a cf   JMP cf4a
????:
d15e  2a b9 d9   LHLD d9b9
d161  3a e9 d9   LDA d9e9
????:
d164  85         ADD L
d165  6f         MOV L, A
d166  d0         RNC
d167  24         INR H
d168  c9         RET
????:
d169  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d16c  11 0e 00   LXI DE, 000e
d16f  19         DAD DE
d170  7e         MOV A, M
d171  c9         RET
????:
d172  cd 69 d1   CALL d169
d175  36 00      MVI M, 00
d177  c9         RET
????:
d178  cd 69 d1   CALL d169
d17b  f6 80      ORI A, 80
d17d  77         MOV M, A
d17e  c9         RET
????:
d17f  2a ea d9   LHLD d9ea
d182  eb         XCHG
d183  2a b3 d9   LHLD d9b3
d186  7b         MOV A, E
d187  96         SUB M
d188  23         INX HL
d189  7a         MOV A, D
d18a  9e         SBB M
d18b  c9         RET
????:
d18c  cd 7f d1   CALL d17f
d18f  d8         RC
d190  13         INX DE
d191  72         MOV M, D
d192  2b         DCX HL
d193  73         MOV M, E
d194  c9         RET
????:
d195  7b         MOV A, E
d196  95         SUB L
d197  6f         MOV L, A
d198  7a         MOV A, D
d199  9c         SBB H
d19a  67         MOV H, A
d19b  c9         RET
????:
d19c  0e ff      MVI C, ff
????:
d19e  2a ec d9   LHLD d9ec
d1a1  eb         XCHG
d1a2  2a cc d9   LHLD d9cc
d1a5  cd 95 d1   CALL d195
d1a8  d0         RNC
d1a9  c5         PUSH BC
d1aa  cd f7 d0   CALL d0f7
d1ad  2a bd d9   LHLD d9bd
d1b0  eb         XCHG
d1b1  2a ec d9   LHLD d9ec
d1b4  19         DAD DE
d1b5  c1         POP BC
d1b6  0c         INR C
d1b7  ca c4 d1   JZ d1c4
d1ba  be         CMP M
d1bb  c8         RZ
d1bc  cd 7f d1   CALL d17f
d1bf  d0         RNC
d1c0  cd 2c d1   CALL d12c
d1c3  c9         RET
????:
d1c4  77         MOV M, A
d1c5  c9         RET
????:
d1c6  cd 9c d1   CALL d19c
d1c9  cd e0 d1   CALL d1e0
d1cc  0e 01      MVI C, 01
d1ce  cd b8 cf   CALL cfb8
d1d1  c3 da d1   JMP d1da
????:
d1d4  cd e0 d1   CALL d1e0
d1d7  cd b2 cf   CALL cfb2
????:
d1da  21 b1 d9   LXI HL, d9b1
d1dd  c3 e3 d1   JMP d1e3
????:
d1e0  21 b9 d9   LXI HL, d9b9
????:
d1e3  4e         MOV C, M
d1e4  23         INX HL
d1e5  46         MOV B, M
d1e6  c3 24 da   JMP da24
????:
d1e9  2a b9 d9   LHLD d9b9
d1ec  eb         XCHG
d1ed  2a b1 d9   LHLD d9b1
d1f0  0e 80      MVI C, 80
d1f2  c3 4f cf   JMP cf4f
????:
d1f5  21 ea d9   LXI HL, d9ea
d1f8  7e         MOV A, M
d1f9  23         INX HL
d1fa  be         CMP M
d1fb  c0         RNZ
d1fc  3c         INR A
d1fd  c9         RET
????:
d1fe  21 ff ff   LXI HL, ffff
d201  22 ea d9   SHLD d9ea
d204  c9         RET
????:
d205  2a c8 d9   LHLD d9c8
d208  eb         XCHG
d209  2a ea d9   LHLD d9ea
d20c  23         INX HL
d20d  22 ea d9   SHLD d9ea
d210  cd 95 d1   CALL d195
d213  d2 19 d2   JNC d219
d216  c3 fe d1   JMP d1fe
????:
d219  3a ea d9   LDA d9ea
d21c  e6 03      ANI A, 03
d21e  06 05      MVI B, 05
????:
d220  87         ADD A
d221  05         DCR B
d222  c2 20 d2   JNZ d220
d225  32 e9 d9   STA d9e9
d228  b7         ORA A
d229  c0         RNZ
d22a  c5         PUSH BC
d22b  cd c3 cf   CALL cfc3
d22e  cd d4 d1   CALL d1d4
d231  c1         POP BC
d232  c3 9e d1   JMP d19e
????:
d235  79         MOV A, C
d236  e6 07      ANI A, 07
d238  3c         INR A
d239  5f         MOV E, A
d23a  57         MOV D, A
d23b  79         MOV A, C
d23c  0f         RRC
d23d  0f         RRC
d23e  0f         RRC
d23f  e6 1f      ANI A, 1f
d241  4f         MOV C, A
d242  78         MOV A, B
d243  87         ADD A
d244  87         ADD A
d245  87         ADD A
d246  87         ADD A
d247  87         ADD A
d248  b1         ORA C
d249  4f         MOV C, A
d24a  78         MOV A, B
d24b  0f         RRC
d24c  0f         RRC
d24d  0f         RRC
d24e  e6 1f      ANI A, 1f
d250  47         MOV B, A
d251  2a bf d9   LHLD d9bf
d254  09         DAD BC
d255  7e         MOV A, M
????:
d256  07         RLC
d257  1d         DCR E
d258  c2 56 d2   JNZ d256
d25b  c9         RET
????:
d25c  d5         PUSH DE
d25d  cd 35 d2   CALL d235
d260  e6 fe      ANI A, fe
d262  c1         POP BC
d263  b1         ORA C
????:
d264  0f         RRC
d265  15         DCR D
d266  c2 64 d2   JNZ d264
d269  77         MOV M, A
d26a  c9         RET
????:
d26b  cd 5e d1   CALL d15e
d26e  11 10 00   LXI DE, 0010
d271  19         DAD DE
d272  c5         PUSH BC
d273  0e 11      MVI C, 11
????:
d275  d1         POP DE
d276  0d         DCR C
d277  c8         RZ
d278  d5         PUSH DE
d279  3a dd d9   LDA d9dd
d27c  b7         ORA A
d27d  ca 88 d2   JZ d288
d280  c5         PUSH BC
d281  e5         PUSH HL
d282  4e         MOV C, M
d283  06 00      MVI B, 00
d285  c3 8e d2   JMP d28e
????:
d288  0d         DCR C
d289  c5         PUSH BC
d28a  4e         MOV C, M
d28b  23         INX HL
d28c  46         MOV B, M
d28d  e5         PUSH HL
????:
d28e  79         MOV A, C
d28f  b0         ORA B
d290  ca 9d d2   JZ d29d
d293  2a c6 d9   LHLD d9c6
d296  7d         MOV A, L
d297  91         SUB C
d298  7c         MOV A, H
d299  98         SBB B
d29a  d4 5c d2   CNC d25c
????:
d29d  e1         POP HL
d29e  23         INX HL
d29f  c1         POP BC
d2a0  c3 75 d2   JMP d275
????:
d2a3  2a c6 d9   LHLD d9c6
d2a6  0e 03      MVI C, 03
d2a8  cd ea d0   CALL d0ea
d2ab  23         INX HL
d2ac  44         MOV B, H
d2ad  4d         MOV C, L
d2ae  2a bf d9   LHLD d9bf
????:
d2b1  36 00      MVI M, 00
d2b3  23         INX HL
d2b4  0b         DCX BC
d2b5  78         MOV A, B
d2b6  b1         ORA C
d2b7  c2 b1 d2   JNZ d2b1
d2ba  2a ca d9   LHLD d9ca
d2bd  eb         XCHG
d2be  2a bf d9   LHLD d9bf
d2c1  73         MOV M, E
d2c2  23         INX HL
d2c3  72         MOV M, D
d2c4  cd a1 cf   CALL cfa1
d2c7  2a b3 d9   LHLD d9b3
d2ca  36 03      MVI M, 03
d2cc  23         INX HL
d2cd  36 00      MVI M, 00
d2cf  cd fe d1   CALL d1fe
????:
d2d2  0e ff      MVI C, ff
d2d4  cd 05 d2   CALL d205
d2d7  cd f5 d1   CALL d1f5
d2da  c8         RZ
d2db  cd 5e d1   CALL d15e
d2de  3e e5      MVI A, e5
d2e0  be         CMP M
d2e1  ca d2 d2   JZ d2d2
d2e4  3a 41 cf   LDA BDOS_STACK (cf41)
d2e7  be         CMP M
d2e8  c2 f6 d2   JNZ d2f6
d2eb  23         INX HL
d2ec  7e         MOV A, M
d2ed  d6 24      SUI A, 24
d2ef  c2 f6 d2   JNZ d2f6
d2f2  3d         DCR A
d2f3  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)
????:
d2f6  0e 01      MVI C, 01
d2f8  cd 6b d2   CALL d26b
d2fb  cd 8c d1   CALL d18c
d2fe  c3 d2 d2   JMP d2d2
????:
d301  3a d4 d9   LDA d9d4
d304  c3 01 cf   JMP FUNCTION_EXIT (cf01)
????:
d307  c5         PUSH BC
d308  f5         PUSH PSW
d309  3a c5 d9   LDA d9c5
d30c  2f         CMA
d30d  47         MOV B, A
d30e  79         MOV A, C
d30f  a0         ANA B
d310  4f         MOV C, A
d311  f1         POP PSW
d312  a0         ANA B
d313  91         SUB C
d314  e6 1f      ANI A, 1f
d316  c1         POP BC
d317  c9         RET
????:
d318  3e ff      MVI A, ff
d31a  32 d4 d9   STA d9d4
d31d  21 d8 d9   LXI HL, d9d8
d320  71         MOV M, C
d321  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d324  22 d9 d9   SHLD d9d9
d327  cd fe d1   CALL d1fe
d32a  cd a1 cf   CALL cfa1
????:
d32d  0e 00      MVI C, 00
d32f  cd 05 d2   CALL d205
d332  cd f5 d1   CALL d1f5
d335  ca 94 d3   JZ d394
d338  2a d9 d9   LHLD d9d9
d33b  eb         XCHG
d33c  1a         LDAX DE
d33d  fe e5      CPI A, e5
d33f  ca 4a d3   JZ d34a
d342  d5         PUSH DE
d343  cd 7f d1   CALL d17f
d346  d1         POP DE
d347  d2 94 d3   JNC d394
????:
d34a  cd 5e d1   CALL d15e
d34d  3a d8 d9   LDA d9d8
d350  4f         MOV C, A
d351  06 00      MVI B, 00
????:
d353  79         MOV A, C
d354  b7         ORA A
d355  ca 83 d3   JZ d383
d358  1a         LDAX DE
d359  fe 3f      CPI A, 3f
d35b  ca 7c d3   JZ d37c
d35e  78         MOV A, B
d35f  fe 0d      CPI A, 0d
d361  ca 7c d3   JZ d37c
d364  fe 0c      CPI A, 0c
d366  1a         LDAX DE
d367  ca 73 d3   JZ d373
d36a  96         SUB M
d36b  e6 7f      ANI A, 7f
d36d  c2 2d d3   JNZ d32d
d370  c3 7c d3   JMP d37c
????:
d373  c5         PUSH BC
d374  4e         MOV C, M
d375  cd 07 d3   CALL d307
d378  c1         POP BC
d379  c2 2d d3   JNZ d32d
????:
d37c  13         INX DE
d37d  23         INX HL
d37e  04         INR B
d37f  0d         DCR C
d380  c3 53 d3   JMP d353
????:
d383  3a ea d9   LDA d9ea
d386  e6 03      ANI A, 03
d388  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)
d38b  21 d4 d9   LXI HL, d9d4
d38e  7e         MOV A, M
d38f  17         RAL
d390  d0         RNC
d391  af         XRA A
d392  77         MOV M, A
d393  c9         RET
????:
d394  cd fe d1   CALL d1fe
d397  3e ff      MVI A, ff
d399  c3 01 cf   JMP FUNCTION_EXIT (cf01)
????:
d39c  cd 54 d1   CALL d154
d39f  0e 0c      MVI C, 0c
d3a1  cd 18 d3   CALL d318
????:
d3a4  cd f5 d1   CALL d1f5
d3a7  c8         RZ
d3a8  cd 44 d1   CALL d144
d3ab  cd 5e d1   CALL d15e
d3ae  36 e5      MVI M, e5
d3b0  0e 00      MVI C, 00
d3b2  cd 6b d2   CALL d26b
d3b5  cd c6 d1   CALL d1c6
d3b8  cd 2d d3   CALL d32d
d3bb  c3 a4 d3   JMP d3a4
????:
d3be  50         MOV D, B
d3bf  59         MOV E, C
????:
d3c0  79         MOV A, C
d3c1  b0         ORA B
d3c2  ca d1 d3   JZ d3d1
d3c5  0b         DCX BC
d3c6  d5         PUSH DE
d3c7  c5         PUSH BC
d3c8  cd 35 d2   CALL d235
d3cb  1f         RAR
d3cc  d2 ec d3   JNC d3ec
d3cf  c1         POP BC
d3d0  d1         POP DE
????:
d3d1  2a c6 d9   LHLD d9c6
d3d4  7b         MOV A, E
d3d5  95         SUB L
d3d6  7a         MOV A, D
d3d7  9c         SBB H
d3d8  d2 f4 d3   JNC d3f4
d3db  13         INX DE
d3dc  c5         PUSH BC
d3dd  d5         PUSH DE
d3de  42         MOV B, D
d3df  4b         MOV C, E
d3e0  cd 35 d2   CALL d235
d3e3  1f         RAR
d3e4  d2 ec d3   JNC d3ec
d3e7  d1         POP DE
d3e8  c1         POP BC
d3e9  c3 c0 d3   JMP d3c0
????:
d3ec  17         RAL
d3ed  3c         INR A
d3ee  cd 64 d2   CALL d264
d3f1  e1         POP HL
d3f2  d1         POP DE
d3f3  c9         RET
????:
d3f4  79         MOV A, C
d3f5  b0         ORA B
d3f6  c2 c0 d3   JNZ d3c0
d3f9  21 00 00   LXI HL, 0000
d3fc  c9         RET
????:
d3fd  0e 00      MVI C, 00
d3ff  1e 20      MVI E, 20
????:
d401  d5         PUSH DE
d402  06 00      MVI B, 00
d404  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d407  09         DAD BC
d408  eb         XCHG
d409  cd 5e d1   CALL d15e
d40c  c1         POP BC
d40d  cd 4f cf   CALL cf4f
????:
d410  cd c3 cf   CALL cfc3
d413  c3 c6 d1   JMP d1c6
????:
d416  cd 54 d1   CALL d154
d419  0e 0c      MVI C, 0c
d41b  cd 18 d3   CALL d318
d41e  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d421  7e         MOV A, M
d422  11 10 00   LXI DE, 0010
d425  19         DAD DE
d426  77         MOV M, A
????:
d427  cd f5 d1   CALL d1f5
d42a  c8         RZ
d42b  cd 44 d1   CALL d144
d42e  0e 10      MVI C, 10
d430  1e 0c      MVI E, 0c
d432  cd 01 d4   CALL d401
d435  cd 2d d3   CALL d32d
d438  c3 27 d4   JMP d427
????:
d43b  0e 0c      MVI C, 0c
d43d  cd 18 d3   CALL d318
????:
d440  cd f5 d1   CALL d1f5
d443  c8         RZ
d444  0e 00      MVI C, 00
d446  1e 0c      MVI E, 0c
d448  cd 01 d4   CALL d401
d44b  cd 2d d3   CALL d32d
d44e  c3 40 d4   JMP d440
????:
d451  0e 0f      MVI C, 0f
d453  cd 18 d3   CALL d318
d456  cd f5 d1   CALL d1f5
d459  c8         RZ
????:
d45a  cd a6 d0   CALL d0a6
d45d  7e         MOV A, M
d45e  f5         PUSH PSW
d45f  e5         PUSH HL
d460  cd 5e d1   CALL d15e
d463  eb         XCHG
d464  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d467  0e 20      MVI C, 20
d469  d5         PUSH DE
d46a  cd 4f cf   CALL cf4f
d46d  cd 78 d1   CALL d178
d470  d1         POP DE
d471  21 0c 00   LXI HL, 000c
d474  19         DAD DE
d475  4e         MOV C, M
d476  21 0f 00   LXI HL, 000f
d479  19         DAD DE
d47a  46         MOV B, M
d47b  e1         POP HL
d47c  f1         POP PSW
d47d  77         MOV M, A
d47e  79         MOV A, C
d47f  be         CMP M
d480  78         MOV A, B
d481  ca 8b d4   JZ d48b
d484  3e 00      MVI A, 00
d486  da 8b d4   JC d48b
d489  3e 80      MVI A, 80
????:
d48b  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d48e  11 0f 00   LXI DE, 000f
d491  19         DAD DE
d492  77         MOV M, A
d493  c9         RET
????:
d494  7e         MOV A, M
d495  23         INX HL
d496  b6         ORA M
d497  2b         DCX HL
d498  c0         RNZ
d499  1a         LDAX DE
d49a  77         MOV M, A
d49b  13         INX DE
d49c  23         INX HL
d49d  1a         LDAX DE
d49e  77         MOV M, A
d49f  1b         DCX DE
d4a0  2b         DCX HL
d4a1  c9         RET
????:
d4a2  af         XRA A
d4a3  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)
d4a6  32 ea d9   STA d9ea
d4a9  32 eb d9   STA d9eb
d4ac  cd 1e d1   CALL d11e
d4af  c0         RNZ
d4b0  cd 69 d1   CALL d169
d4b3  e6 80      ANI A, 80
d4b5  c0         RNZ
d4b6  0e 0f      MVI C, 0f
d4b8  cd 18 d3   CALL d318
d4bb  cd f5 d1   CALL d1f5
d4be  c8         RZ
d4bf  01 10 00   LXI BC, 0010
d4c2  cd 5e d1   CALL d15e
d4c5  09         DAD BC
d4c6  eb         XCHG
d4c7  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d4ca  09         DAD BC
d4cb  0e 10      MVI C, 10
????:
d4cd  3a dd d9   LDA d9dd
d4d0  b7         ORA A
d4d1  ca e8 d4   JZ d4e8
d4d4  7e         MOV A, M
d4d5  b7         ORA A
d4d6  1a         LDAX DE
d4d7  c2 db d4   JNZ d4db
d4da  77         MOV M, A
????:
d4db  b7         ORA A
d4dc  c2 e1 d4   JNZ d4e1
d4df  7e         MOV A, M
d4e0  12         STAX DE
????:
d4e1  be         CMP M
d4e2  c2 1f d5   JNZ d51f
d4e5  c3 fd d4   JMP d4fd
????:
d4e8  cd 94 d4   CALL d494
d4eb  eb         XCHG
d4ec  cd 94 d4   CALL d494
d4ef  eb         XCHG
d4f0  1a         LDAX DE
d4f1  be         CMP M
d4f2  c2 1f d5   JNZ d51f
d4f5  13         INX DE
d4f6  23         INX HL
d4f7  1a         LDAX DE
d4f8  be         CMP M
d4f9  c2 1f d5   JNZ d51f
d4fc  0d         DCR C
????:
d4fd  13         INX DE
d4fe  23         INX HL
d4ff  0d         DCR C
d500  c2 cd d4   JNZ d4cd
d503  01 ec ff   LXI BC, ffec
d506  09         DAD BC
d507  eb         XCHG
d508  09         DAD BC
d509  1a         LDAX DE
d50a  be         CMP M
d50b  da 17 d5   JC d517
d50e  77         MOV M, A
d50f  01 03 00   LXI BC, 0003
d512  09         DAD BC
d513  eb         XCHG
d514  09         DAD BC
d515  7e         MOV A, M
d516  12         STAX DE
????:
d517  3e ff      MVI A, ff
d519  32 d2 d9   STA d9d2
d51c  c3 10 d4   JMP d410
????:
d51f  21 45 cf   LXI HL, FUNCTION_RETURN_VALUE (cf45)
d522  35         DCR M
d523  c9         RET
????:
d524  cd 54 d1   CALL d154
d527  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d52a  e5         PUSH HL
d52b  21 ac d9   LXI HL, d9ac
d52e  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)
d531  0e 01      MVI C, 01
d533  cd 18 d3   CALL d318
d536  cd f5 d1   CALL d1f5
d539  e1         POP HL
d53a  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)
d53d  c8         RZ
d53e  eb         XCHG
d53f  21 0f 00   LXI HL, 000f
d542  19         DAD DE
d543  0e 11      MVI C, 11
d545  af         XRA A
????:
d546  77         MOV M, A
d547  23         INX HL
d548  0d         DCR C
d549  c2 46 d5   JNZ d546
d54c  21 0d 00   LXI HL, 000d
d54f  19         DAD DE
d550  77         MOV M, A
d551  cd 8c d1   CALL d18c
d554  cd fd d3   CALL d3fd
d557  c3 78 d1   JMP d178
????:
d55a  af         XRA A
d55b  32 d2 d9   STA d9d2
d55e  cd a2 d4   CALL d4a2
d561  cd f5 d1   CALL d1f5
d564  c8         RZ
d565  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d568  01 0c 00   LXI BC, 000c
d56b  09         DAD BC
d56c  7e         MOV A, M
d56d  3c         INR A
d56e  e6 1f      ANI A, 1f
d570  77         MOV M, A
d571  ca 83 d5   JZ d583
d574  47         MOV B, A
d575  3a c5 d9   LDA d9c5
d578  a0         ANA B
d579  21 d2 d9   LXI HL, d9d2
d57c  a6         ANA M
d57d  ca 8e d5   JZ d58e
d580  c3 ac d5   JMP d5ac
????:
d583  01 02 00   LXI BC, 0002
d586  09         DAD BC
d587  34         INR M
d588  7e         MOV A, M
d589  e6 0f      ANI A, 0f
d58b  ca b6 d5   JZ d5b6
????:
d58e  0e 0f      MVI C, 0f
d590  cd 18 d3   CALL d318
d593  cd f5 d1   CALL d1f5
d596  c2 ac d5   JNZ d5ac
d599  3a d3 d9   LDA d9d3
d59c  3c         INR A
d59d  ca b6 d5   JZ d5b6
d5a0  cd 24 d5   CALL d524
d5a3  cd f5 d1   CALL d1f5
d5a6  ca b6 d5   JZ d5b6
d5a9  c3 af d5   JMP d5af
????:
d5ac  cd 5a d4   CALL d45a
????:
d5af  cd bb d0   CALL d0bb
d5b2  af         XRA A
d5b3  c3 01 cf   JMP FUNCTION_EXIT (cf01)
????:
d5b6  cd 05 cf   CALL cf05
d5b9  c3 78 d1   JMP d178
????:
d5bc  3e 01      MVI A, 01
d5be  32 d5 d9   STA d9d5
????:
d5c1  3e ff      MVI A, ff
d5c3  32 d3 d9   STA d9d3
d5c6  cd bb d0   CALL d0bb
d5c9  3a e3 d9   LDA d9e3
d5cc  21 e1 d9   LXI HL, d9e1
d5cf  be         CMP M
d5d0  da e6 d5   JC d5e6
d5d3  fe 80      CPI A, 80
d5d5  c2 fb d5   JNZ d5fb
d5d8  cd 5a d5   CALL d55a
d5db  af         XRA A
d5dc  32 e3 d9   STA d9e3
d5df  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)
d5e2  b7         ORA A
d5e3  c2 fb d5   JNZ d5fb
????:
d5e6  cd 77 d0   CALL d077
d5e9  cd 84 d0   CALL d084
d5ec  ca fb d5   JZ d5fb
d5ef  cd 8a d0   CALL d08a
d5f2  cd d1 cf   CALL cfd1
d5f5  cd b2 cf   CALL cfb2
d5f8  c3 d2 d0   JMP d0d2
????:
d5fb  c3 05 cf   JMP cf05
????:
d5fe  3e 01      MVI A, 01
d600  32 d5 d9   STA d9d5
????:
d603  3e 00      MVI A, 00
d605  32 d3 d9   STA d9d3
d608  cd 54 d1   CALL d154
d60b  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d60e  cd 47 d1   CALL d147
d611  cd bb d0   CALL d0bb
d614  3a e3 d9   LDA d9e3
d617  fe 80      CPI A, 80
d619  d2 05 cf   JNC cf05
d61c  cd 77 d0   CALL d077
d61f  cd 84 d0   CALL d084
d622  0e 00      MVI C, 00
d624  c2 6e d6   JNZ d66e
d627  cd 3e d0   CALL d03e
d62a  32 d7 d9   STA d9d7
d62d  01 00 00   LXI BC, 0000
d630  b7         ORA A
d631  ca 3b d6   JZ d63b
d634  4f         MOV C, A
d635  0b         DCX BC
d636  cd 5e d0   CALL d05e
d639  44         MOV B, H
d63a  4d         MOV C, L
????:
d63b  cd be d3   CALL d3be
d63e  7d         MOV A, L
d63f  b4         ORA H
d640  c2 48 d6   JNZ d648
d643  3e 02      MVI A, 02
d645  c3 01 cf   JMP FUNCTION_EXIT (cf01)
????:
d648  22 e5 d9   SHLD d9e5
d64b  eb         XCHG
d64c  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d64f  01 10 00   LXI BC, 0010
d652  09         DAD BC
d653  3a dd d9   LDA d9dd
d656  b7         ORA A
d657  3a d7 d9   LDA d9d7
d65a  ca 64 d6   JZ d664
d65d  cd 64 d1   CALL d164
d660  73         MOV M, E
d661  c3 6c d6   JMP d66c
????:
d664  4f         MOV C, A
d665  06 00      MVI B, 00
d667  09         DAD BC
d668  09         DAD BC
d669  73         MOV M, E
d66a  23         INX HL
d66b  72         MOV M, D
????:
d66c  0e 02      MVI C, 02
????:
d66e  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)
d671  b7         ORA A
d672  c0         RNZ
d673  c5         PUSH BC
d674  cd 8a d0   CALL d08a
d677  3a d5 d9   LDA d9d5
d67a  3d         DCR A
d67b  3d         DCR A
d67c  c2 bb d6   JNZ d6bb
d67f  c1         POP BC
d680  c5         PUSH BC
d681  79         MOV A, C
d682  3d         DCR A
d683  3d         DCR A
d684  c2 bb d6   JNZ d6bb
d687  e5         PUSH HL
d688  2a b9 d9   LHLD d9b9
d68b  57         MOV D, A
????:
d68c  77         MOV M, A
d68d  23         INX HL
d68e  14         INR D
d68f  f2 8c d6   JP d68c
d692  cd e0 d1   CALL d1e0
d695  2a e7 d9   LHLD d9e7
d698  0e 02      MVI C, 02
????:
d69a  22 e5 d9   SHLD d9e5
d69d  c5         PUSH BC
d69e  cd d1 cf   CALL cfd1
d6a1  c1         POP BC
d6a2  cd b8 cf   CALL cfb8
d6a5  2a e5 d9   LHLD d9e5
d6a8  0e 00      MVI C, 00
d6aa  3a c4 d9   LDA d9c4
d6ad  47         MOV B, A
d6ae  a5         ANA L
d6af  b8         CMP B
d6b0  23         INX HL
d6b1  c2 9a d6   JNZ d69a
d6b4  e1         POP HL
d6b5  22 e5 d9   SHLD d9e5
d6b8  cd da d1   CALL d1da
????:
d6bb  cd d1 cf   CALL cfd1
d6be  c1         POP BC
d6bf  c5         PUSH BC
d6c0  cd b8 cf   CALL cfb8
d6c3  c1         POP BC
d6c4  3a e3 d9   LDA d9e3
d6c7  21 e1 d9   LXI HL, d9e1
d6ca  be         CMP M
d6cb  da d2 d6   JC d6d2
d6ce  77         MOV M, A
d6cf  34         INR M
d6d0  0e 02      MVI C, 02
????:
d6d2  0d         DCR C
d6d3  0d         DCR C
d6d4  c2 df d6   JNZ d6df
d6d7  f5         PUSH PSW
d6d8  cd 69 d1   CALL d169
d6db  e6 7f      ANI A, 7f
d6dd  77         MOV M, A
d6de  f1         POP PSW
????:
d6df  fe 7f      CPI A, 7f
d6e1  c2 00 d7   JNZ d700
d6e4  3a d5 d9   LDA d9d5
d6e7  fe 01      CPI A, 01
d6e9  c2 00 d7   JNZ d700
d6ec  cd d2 d0   CALL d0d2
d6ef  cd 5a d5   CALL d55a
d6f2  21 45 cf   LXI HL, FUNCTION_RETURN_VALUE (cf45)
d6f5  7e         MOV A, M
d6f6  b7         ORA A
d6f7  c2 fe d6   JNZ d6fe
d6fa  3d         DCR A
d6fb  32 e3 d9   STA d9e3
????:
d6fe  36 00      MVI M, 00
????:
d700  c3 d2 d0   JMP d0d2
????:
d703  af         XRA A
d704  32 d5 d9   STA d9d5
????:
d707  c5         PUSH BC
d708  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d70b  eb         XCHG
d70c  21 21 00   LXI HL, 0021
d70f  19         DAD DE
d710  7e         MOV A, M
d711  e6 7f      ANI A, 7f
d713  f5         PUSH PSW
d714  7e         MOV A, M
d715  17         RAL
d716  23         INX HL
d717  7e         MOV A, M
d718  17         RAL
d719  e6 1f      ANI A, 1f
d71b  4f         MOV C, A
d71c  7e         MOV A, M
d71d  1f         RAR
d71e  1f         RAR
d71f  1f         RAR
d720  1f         RAR
d721  e6 0f      ANI A, 0f
d723  47         MOV B, A
d724  f1         POP PSW
d725  23         INX HL
d726  6e         MOV L, M
d727  2c         INR L
d728  2d         DCR L
d729  2e 06      MVI L, 06
d72b  c2 8b d7   JNZ d78b
d72e  21 20 00   LXI HL, 0020
d731  19         DAD DE
d732  77         MOV M, A
d733  21 0c 00   LXI HL, 000c
d736  19         DAD DE
d737  79         MOV A, C
d738  96         SUB M
d739  c2 47 d7   JNZ d747
d73c  21 0e 00   LXI HL, 000e
d73f  19         DAD DE
d740  78         MOV A, B
d741  96         SUB M
d742  e6 7f      ANI A, 7f
d744  ca 7f d7   JZ d77f
????:
d747  c5         PUSH BC
d748  d5         PUSH DE
d749  cd a2 d4   CALL d4a2
d74c  d1         POP DE
d74d  c1         POP BC
d74e  2e 03      MVI L, 03
d750  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)
d753  3c         INR A
d754  ca 84 d7   JZ d784
d757  21 0c 00   LXI HL, 000c
d75a  19         DAD DE
d75b  71         MOV M, C
d75c  21 0e 00   LXI HL, 000e
d75f  19         DAD DE
d760  70         MOV M, B
d761  cd 51 d4   CALL d451
d764  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)
d767  3c         INR A
d768  c2 7f d7   JNZ d77f
d76b  c1         POP BC
d76c  c5         PUSH BC
d76d  2e 04      MVI L, 04
d76f  0c         INR C
d770  ca 84 d7   JZ d784
d773  cd 24 d5   CALL d524
d776  2e 05      MVI L, 05
d778  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)
d77b  3c         INR A
d77c  ca 84 d7   JZ d784
????:
d77f  c1         POP BC
d780  af         XRA A
d781  c3 01 cf   JMP FUNCTION_EXIT (cf01)
????:
d784  e5         PUSH HL
d785  cd 69 d1   CALL d169
d788  36 c0      MVI M, c0
d78a  e1         POP HL
????:
d78b  c1         POP BC
d78c  7d         MOV A, L
d78d  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)
d790  c3 78 d1   JMP d178
????:
d793  0e ff      MVI C, ff
d795  cd 03 d7   CALL d703
d798  cc c1 d5   CZ d5c1
d79b  c9         RET
????:
d79c  0e 00      MVI C, 00
d79e  cd 03 d7   CALL d703
d7a1  cc 03 d6   CZ d603
d7a4  c9         RET
????:
d7a5  eb         XCHG
d7a6  19         DAD DE
d7a7  4e         MOV C, M
d7a8  06 00      MVI B, 00
d7aa  21 0c 00   LXI HL, 000c
d7ad  19         DAD DE
d7ae  7e         MOV A, M
d7af  0f         RRC
d7b0  e6 80      ANI A, 80
d7b2  81         ADD C
d7b3  4f         MOV C, A
d7b4  3e 00      MVI A, 00
d7b6  88         ADC B
d7b7  47         MOV B, A
d7b8  7e         MOV A, M
d7b9  0f         RRC
d7ba  e6 0f      ANI A, 0f
d7bc  80         ADD B
d7bd  47         MOV B, A
d7be  21 0e 00   LXI HL, 000e
d7c1  19         DAD DE
d7c2  7e         MOV A, M
d7c3  87         ADD A
d7c4  87         ADD A
d7c5  87         ADD A
d7c6  87         ADD A
d7c7  f5         PUSH PSW
d7c8  80         ADD B
d7c9  47         MOV B, A
d7ca  f5         PUSH PSW
d7cb  e1         POP HL
d7cc  7d         MOV A, L
d7cd  e1         POP HL
d7ce  b5         ORA L
d7cf  e6 01      ANI A, 01
d7d1  c9         RET
????:
d7d2  0e 0c      MVI C, 0c
d7d4  cd 18 d3   CALL d318
d7d7  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d7da  11 21 00   LXI DE, 0021
d7dd  19         DAD DE
d7de  e5         PUSH HL
d7df  72         MOV M, D
d7e0  23         INX HL
d7e1  72         MOV M, D
d7e2  23         INX HL
d7e3  72         MOV M, D
????:
d7e4  cd f5 d1   CALL d1f5
d7e7  ca 0c d8   JZ d80c
d7ea  cd 5e d1   CALL d15e
d7ed  11 0f 00   LXI DE, 000f
d7f0  cd a5 d7   CALL d7a5
d7f3  e1         POP HL
d7f4  e5         PUSH HL
d7f5  5f         MOV E, A
d7f6  79         MOV A, C
d7f7  96         SUB M
d7f8  23         INX HL
d7f9  78         MOV A, B
d7fa  9e         SBB M
d7fb  23         INX HL
d7fc  7b         MOV A, E
d7fd  9e         SBB M
d7fe  da 06 d8   JC d806
d801  73         MOV M, E
d802  2b         DCX HL
d803  70         MOV M, B
d804  2b         DCX HL
d805  71         MOV M, C
????:
d806  cd 2d d3   CALL d32d
d809  c3 e4 d7   JMP d7e4
????:
d80c  e1         POP HL
d80d  c9         RET
d80e  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d811  11 20 00   LXI DE, 0020
d814  cd a5 d7   CALL d7a5
d817  21 21 00   LXI HL, 0021
d81a  19         DAD DE
d81b  71         MOV M, C
d81c  23         INX HL
d81d  70         MOV M, B
d81e  23         INX HL
d81f  77         MOV M, A
d820  c9         RET
????:
d821  2a af d9   LHLD d9af
d824  3a 42 cf   LDA cf42
d827  4f         MOV C, A
d828  cd ea d0   CALL d0ea
d82b  e5         PUSH HL
d82c  eb         XCHG
d82d  cd 59 cf   CALL cf59
d830  e1         POP HL
d831  cc 47 cf   CZ cf47
d834  7d         MOV A, L
d835  1f         RAR
d836  d8         RC
d837  2a af d9   LHLD d9af
d83a  4d         MOV C, L
d83b  44         MOV B, H
d83c  cd 0b d1   CALL d10b
d83f  22 af d9   SHLD d9af
d842  c3 a3 d2   JMP d2a3
????:
d845  3a d6 d9   LDA FUNCTION_BYTE_ARGUMENT (d9d6)
d848  21 42 cf   LXI HL, cf42
d84b  be         CMP M
d84c  c8         RZ
d84d  77         MOV M, A
d84e  c3 21 d8   JMP d821
????:
d851  3e ff      MVI A, ff
d853  32 de d9   STA d9de
d856  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d859  7e         MOV A, M
d85a  e6 1f      ANI A, 1f
d85c  3d         DCR A
d85d  32 d6 d9   STA FUNCTION_BYTE_ARGUMENT (d9d6)
d860  fe 1e      CPI A, 1e
d862  d2 75 d8   JNC d875
d865  3a 42 cf   LDA cf42
d868  32 df d9   STA d9df
d86b  7e         MOV A, M
d86c  32 e0 d9   STA d9e0
d86f  e6 e0      ANI A, e0
d871  77         MOV M, A
d872  cd 45 d8   CALL d845
????:
d875  3a 41 cf   LDA BDOS_STACK (cf41)
d878  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d87b  b6         ORA M
d87c  77         MOV M, A
d87d  c9         RET

; Function 0x0c - get BDOS version
;
; Arguments: none
;
; Returns: 0x22, meaning CP/M v2.2
GET_BDOS_VERSION:
    d87e  3e 22      MVI A, 22                  ; Return version 2.2
    d880  c3 01 cf   JMP FUNCTION_EXIT (cf01)


d883  21 00 00   LXI HL, 0000
d886  22 ad d9   SHLD d9ad
d889  22 af d9   SHLD d9af
d88c  af         XRA A
d88d  32 42 cf   STA cf42
d890  21 80 00   LXI HL, 0080
d893  22 b1 d9   SHLD d9b1
d896  cd da d1   CALL d1da
d899  c3 21 d8   JMP d821
d89c  cd 72 d1   CALL d172
d89f  cd 51 d8   CALL d851
d8a2  c3 51 d4   JMP d451
d8a5  cd 51 d8   CALL d851
d8a8  c3 a2 d4   JMP d4a2
d8ab  0e 00      MVI C, 00
d8ad  eb         XCHG
d8ae  7e         MOV A, M
d8af  fe 3f      CPI A, 3f
d8b1  ca c2 d8   JZ d8c2
d8b4  cd a6 d0   CALL d0a6
d8b7  7e         MOV A, M
d8b8  fe 3f      CPI A, 3f
d8ba  c4 72 d1   CNZ d172
d8bd  cd 51 d8   CALL d851
d8c0  0e 0f      MVI C, 0f
????:
d8c2  cd 18 d3   CALL d318
d8c5  c3 e9 d1   JMP d1e9
d8c8  2a d9 d9   LHLD d9d9
d8cb  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)
d8ce  cd 51 d8   CALL d851
d8d1  cd 2d d3   CALL d32d
d8d4  c3 e9 d1   JMP d1e9
d8d7  cd 51 d8   CALL d851
d8da  cd 9c d3   CALL d39c
d8dd  c3 01 d3   JMP d301
d8e0  cd 51 d8   CALL d851
d8e3  c3 bc d5   JMP d5bc
d8e6  cd 51 d8   CALL d851
d8e9  c3 fe d5   JMP d5fe
d8ec  cd 72 d1   CALL d172
d8ef  cd 51 d8   CALL d851
d8f2  c3 24 d5   JMP d524
d8f5  cd 51 d8   CALL d851
d8f8  cd 16 d4   CALL d416
d8fb  c3 01 d3   JMP d301
d8fe  2a af d9   LHLD d9af
d901  c3 29 d9   JMP d929
d904  3a 42 cf   LDA cf42
d907  c3 01 cf   JMP FUNCTION_EXIT (cf01)
d90a  eb         XCHG
d90b  22 b1 d9   SHLD d9b1
d90e  c3 da d1   JMP d1da
d911  2a bf d9   LHLD d9bf
d914  c3 29 d9   JMP d929
d917  2a ad d9   LHLD d9ad
d91a  c3 29 d9   JMP d929
d91d  cd 51 d8   CALL d851
d920  cd 3b d4   CALL d43b
d923  c3 01 d3   JMP d301
d926  2a bb d9   LHLD d9bb
????:
d929  22 45 cf   SHLD FUNCTION_RETURN_VALUE (cf45)
d92c  c9         RET
d92d  3a d6 d9   LDA FUNCTION_BYTE_ARGUMENT (d9d6)
d930  fe ff      CPI A, ff
d932  c2 3b d9   JNZ d93b
d935  3a 41 cf   LDA BDOS_STACK (cf41)
d938  c3 01 cf   JMP FUNCTION_EXIT (cf01)
????:
d93b  e6 1f      ANI A, 1f
d93d  32 41 cf   STA BDOS_STACK (cf41)
d940  c9         RET
d941  cd 51 d8   CALL d851
d944  c3 93 d7   JMP d793
d947  cd 51 d8   CALL d851
d94a  c3 9c d7   JMP d79c
d94d  cd 51 d8   CALL d851
d950  c3 d2 d7   JMP d7d2
d953  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d956  7d         MOV A, L
d957  2f         CMA
d958  5f         MOV E, A
d959  7c         MOV A, H
d95a  2f         CMA
d95b  2a af d9   LHLD d9af
d95e  a4         ANA H
d95f  57         MOV D, A
d960  7d         MOV A, L
d961  a3         ANA E
d962  5f         MOV E, A
d963  2a ad d9   LHLD d9ad
d966  eb         XCHG
d967  22 af d9   SHLD d9af
d96a  7d         MOV A, L
d96b  a3         ANA E
d96c  6f         MOV L, A
d96d  7c         MOV A, H
d96e  a2         ANA D
d96f  67         MOV H, A
d970  22 ad d9   SHLD d9ad
d973  c9         RET

BDOS_HANDLER_RETURN:
d974  3a de d9   LDA d9de
d977  b7         ORA A
d978  ca 91 d9   JZ d991
d97b  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
d97e  36 00      MVI M, 00
d980  3a e0 d9   LDA d9e0
d983  b7         ORA A
d984  ca 91 d9   JZ d991
d987  77         MOV M, A
d988  3a df d9   LDA d9df
d98b  32 d6 d9   STA FUNCTION_BYTE_ARGUMENT (d9d6)
d98e  cd 45 d8   CALL d845
????:
d991  2a 0f cf   LHLD BDOS_SAVE_SP (cf0f)
d994  f9         SPHL
d995  2a 45 cf   LHLD FUNCTION_RETURN_VALUE (cf45)
d998  7d         MOV A, L
d999  44         MOV B, H
d99a  c9         RET
d99b  cd 51 d8   CALL d851
d99e  3e 02      MVI A, 02
d9a0  32 d5 d9   STA d9d5
d9a3  0e 00      MVI C, 00
d9a5  cd 07 d7   CALL d707
d9a8  cc 03 d6   CZ d603
d9ab  c9         RET

????:
d9ac  e5         PUSH HL



FUNCTION_BYTE_ARGUMENT:
    d9d6 00           db 00 
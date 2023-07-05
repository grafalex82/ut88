; CH.COM (Changer) is a program to export CP/M files to the tape recorder, or load data from the
; tape recorder and store it as CP/M file.
;
; Usage:
; CH <file name>
;
; If the file already exists - the program will output its contents to the tape
; If the file does not yet exists - the program will input data from the tape and save to the file
;
; Tape format is different compared to one used in MonitorF:
; 256 zero bytes    - pilot tone
; 0xe6              - synchronization byte
; 2 bytes           - CRC (low byte first)
; 2 bytes           - data size (low byte first)
; data bytes

BDOS    equ 0005
FCB     equ 005c

START:
    0100  c3 eb 01   JMP REAL_START (01eb)

WELCOME_STR:
    0103  43 48 41 4e 47 45 52 20       db "CHANGER "
    010b  56 45 52 53 20 31 2e 31       db "VERS 1.1"
    0113  0d 0a 0d 0a 24                db 0x0d, 0x0a, 0x0d, 0x0a, '$'

READY_FOR_INPUT_STR:
    0118  52 45 41 44 59 20 54 52       db "READY TR"
    0120  20 46 4f 52 20 49 4e 50       db " FOR INP"
    0128  55 54 2c 20 50 52 45 53       db "UP, PRES"
    0130  53 20 43 52 2e 24             db "S CR.$"

READY_FOR_OUT_STR:
    0136  52 45 41 44 59 20 54 52       db "READY TR"
    013e  20 46 4f 52 20 4f 55 54       db " FOR OUT"
    0146  50 55 54 2c 20 50 52 45       db "PUT, PRE"
    014e  53 53 20 43 52 2e 24          db "SS CR.$" 

READY_FOR_VERIFY_STR:
    0155  52 45 41 44 59 20 54 52       db "READY TR"
    015d  20 46 4f 52 20 56 45 52       db " FOR VER"
    0165  49 46 59 2c 20 50 52 45       db "IFY, PRE"
    016d  53 53 20 43 52 2e 24          db "SS CR.$"

READ_ERROR_STR:
    0174  52 45 41 44 20 45 52 52       db "READ ERR"
    017c  4f 52 2e 0d 0a 24             db "OR.", 0x0d, 0x0a, '$'

VERIFY_ERROR_STR:
    0182  56 45 52 49 46 59 20 45       db "VERIFY E"
    018a  52 52 4f 52 2e 0d 0a 24       db "RROR.", 0x0d, 0x0a, '$'

NO_SOURCE_FILE_STR:
    0192  4e 4f 20 53 4f 55 52 43       db "NO SOURC"
    019a  45 20 46 49 4c 45 20 50       db "E FILE P"
    01a2  52 45 53 45 4e 54 2e 0d       db "RESENT.", 0x0d
    01aa  0a 24                         db 0x0a, '$'

OUT_OF_MEMORY_STR:
    01ac  4e 4f 54 20 45 4e 4f 55       db "NOT ENOU"
    01b4  47 48 20 4d 45 4d 4f 52       db "GH MEMOR"
    01bc  59 2e 0d 0a 24                db "Y.", 0x0d, 0x0a, '$'

NO_DIRECTORY_SPACE_STR:
    01c1  4e 4f 20 44 49 52 45 43       db "NO DIREC"
    01c9  54 4f 52 59 20 53 50 41       db "TORY SPA"
    01d1  43 45 2e 0d 0a 24             db "CE.", 0x0d, 0x0a, '$'

DISK_FULL_STR:
    01d7  44 49 53 4b 20 46 55 4c       db "DISK FUL"
    01df  4c 2e 0d 0a 24                db "L.", 0x0d, 0x0a, '$'

CUR_PTR:
    01e4  2e 00      db 0000                    ; Pointer to the buffer where to read next chunk, or pointer to
                                                ; data end, after file is loaded

FILE_CRC:
    01e6  e9 00      db 0000                    ; CRC of the loaded file

DATA_SIZE:
    01e8  00 00      db 0000                    ; Size of the loaded data

01ea  00         NOP

REAL_START:
    01eb  31 00 05   LXI SP, 0500               ; Setup the stack

    01ee  11 03 01   LXI DE, WELCOME_STR (0103) ; Print welcome string
    01f1  0e 09      MVI C, 09
    01f3  cd 05 00   CALL BDOS (0005)

    01f6  3a 5d 00   LDA 005d                   ; Get pointer to default FCB name field
    01f9  fe 20      CPI A, 20                  ; Check if any argument is provided
    01fb  c2 09 02   JNZ ARGUMENT_OK (0209)

    01fe  11 92 01   LXI DE, NO_SOURCE_FILE_STR (0192)  ; Report no argument provided
    0201  0e 09      MVI C, 09
    0203  cd 05 00   CALL BDOS (0005)
    0206  c3 00 00   JMP 0000                   ; Exit to CP/M

ARGUMENT_OK:
    0209  11 5c 00   LXI DE, FCB (005c)         ; Open the specified file for output
    020c  0e 0f      MVI C, 0f
    020e  cd 05 00   CALL BDOS (0005)

    0211  fe ff      CPI A, ff                  ; Check if file exists
    0213  ca 2d 03   JZ INPUT_DATA (032d)       ; If not exists - input data to a new file

    0216  21 00 05   LXI HL, 0500               ; Set start address for loading the file
    0219  22 e4 01   SHLD CUR_PTR (01e4)

READ_NEXT_CHUNK:
    021c  2a e4 01   LHLD CUR_PTR (01e4)        ; Restore next chunk address
    021f  eb         XCHG

    0220  0e 1a      MVI C, 1a                  ; Set the buffer address
    0222  cd 05 00   CALL BDOS (0005)

    0225  11 5c 00   LXI DE, FCB (005c)         ; Read next chunk of the file
    0228  0e 14      MVI C, 14
    022a  cd 05 00   CALL BDOS (0005)

    022d  b7         ORA A                      ; Check for EOF
    022e  c2 4e 02   JNZ FILE_LOADED (024e)

    0231  2a e4 01   LHLD CUR_PTR (01e4)        ; Advance to the next chunk
    0234  11 80 00   LXI DE, 0080
    0237  19         DAD DE
    0238  22 e4 01   SHLD CUR_PTR (01e4)

    023b  7c         MOV A, H                   ; Check if pointer reached BIOS area already
    023c  2a 06 00   LHLD 0006
    023f  bc         CMP H
    0240  da 1c 02   JC READ_NEXT_CHUNK (021c)

    0243  11 ac 01   LXI DE, OUT_OF_MEMORY_STR (01ac)   ; Report out of memory problem
    0246  0e 09      MVI C, 09
    0248  cd 05 00   CALL BDOS (0005)

    024b  c3 00 00   JMP 0000                   ; Exit to CP/M

FILE_LOADED:
    024e  11 36 01   LXI DE, READY_FOR_OUT_STR (0136)   ; Let user we are ready for output to tape recorder
    0251  0e 09      MVI C, 09
    0253  cd 05 00   CALL BDOS (0005)

    0256  0e 01      MVI C, 01                  ; Wait for a key press
    0258  cd 05 00   CALL BDOS (0005)

    025b  cd 1f 03   CALL PRINT_CR_LF (031f)

    025e  11 00 05   LXI DE, 0500               ; Calculate CRC for the loaded file  
    0261  2a e4 01   LHLD CUR_PTR (01e4)
    0264  cd 07 03   CALL CALC_CRC (0307)

    0267  22 e6 01   SHLD FILE_CRC (01e6)       ; Store CRC

    026a  2a e4 01   LHLD CUR_PTR (01e4)        ; Load start and end address
    026d  11 00 05   LXI DE, 0500

    0270  7d         MOV A, L                   ; Calculate the difference in HL
    0271  93         SUB E
    0272  6f         MOV L, A
    0273  7c         MOV A, H
    0274  9a         SBB D
    0275  67         MOV H, A

    0276  22 e8 01   SHLD DATA_SIZE (01e8)      ; Store data size

    0279  2e 00      MVI L, 00                  ; Out 256 zero bytes of the pilot tone
OUT_PILOT_TONE:
    027b  0e 00      MVI C, 00                  ; Out a zero byte
    027d  cd f8 03   CALL OUT_BYTE (03f8)

    0280  2d         DCR L                      ; Repeat for 256 bytes
    0281  c2 7b 02   JNZ OUT_PILOT_TONE (027b)

    0284  0e e6      MVI C, e6                  ; Out sync byte
    0286  cd f8 03   CALL OUT_BYTE (03f8)

    0289  2a e6 01   LHLD FILE_CRC (01e6)       ; Out CRC
    028c  4d         MOV C, L
    028d  cd f8 03   CALL OUT_BYTE (03f8)
    0290  4c         MOV C, H
    0291  cd f8 03   CALL OUT_BYTE (03f8)

    0294  2a e8 01   LHLD DATA_SIZE (01e8)      ; Out data size
    0297  4d         MOV C, L
    0298  cd f8 03   CALL OUT_BYTE (03f8)
    029b  4c         MOV C, H
    029c  cd f8 03   CALL OUT_BYTE (03f8)

    029f  eb         XCHG                       ; DE - data size
    02a0  21 00 05   LXI HL, 0500               ; HL - start address

OUT_LOOP:
    02a3  4e         MOV C, M                   ; Out a data byte
    02a4  cd f8 03   CALL OUT_BYTE (03f8)

    02a7  23         INX HL                     ; Advance to the next byte
    02a8  1b         DCX DE

    02a9  7a         MOV A, D                   ; Repeat until no bytes remaining
    02aa  b3         ORA E
    02ab  c2 a3 02   JNZ OUT_LOOP (02a3)

    02ae  11 55 01   LXI DE, READY_FOR_VERIFY_STR (0155); Prepare for verification
    02b1  0e 09      MVI C, 09
    02b3  cd 05 00   CALL BDOS (0005)

    02b6  0e 01      MVI C, 01                  ; Wait for a key press
    02b8  cd 05 00   CALL BDOS (0005)

    02bb  cd 1f 03   CALL PRINT_CR_LF (031f)    ; New line

    02be  2a e6 01   LHLD FILE_CRC (01e6)       ; Restore CRC in HL

    02c1  3e ff      MVI A, ff                  ; Wait for a tape sync, then receive CRC low byte
    02c3  cd f4 03   CALL IN_BYTE (03f4)

    02c6  bd         CMP L                      ; Check CRC low byte
    02c7  c2 f7 02   JNZ VERIFY_ERROR (02f7)

    02ca  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Receive CRC high byte

    02cd  bc         CMP H                      ; Compare CRC high byte
    02ce  c2 f7 02   JNZ VERIFY_ERROR (02f7)

    02d1  2a e8 01   LHLD DATA_SIZE (01e8)      ; Load data size to HL

    02d4  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Input and verify data size low byte
    02d7  bd         CMP L
    02d8  c2 f7 02   JNZ VERIFY_ERROR (02f7)

    02db  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Input and verify data size high byte
    02de  bc         CMP H
    02df  c2 f7 02   JNZ VERIFY_ERROR (02f7)

    02e2  eb         XCHG                       ; DE - data size
    02e3  21 00 05   LXI HL, 0500               ; HL - data start

VERIFY_LOOP:
    02e6  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Input and verify data byte
    02e9  be         CMP M
    02ea  c2 f7 02   JNZ VERIFY_ERROR (02f7)

    02ed  23         INX HL                     ; Advance to the next byte
    02ee  1b         DCX DE

    02ef  7a         MOV A, D                   ; Repeat until all bytes are processed
    02f0  b3         ORA E
    02f1  c2 e6 02   JNZ VERIFY_LOOP (02e6)

    02f4  c3 00 00   JMP 0000                   ; Exit to CP/M


VERIFY_ERROR:
    02f7  11 82 01   LXI DE, VERIFY_ERROR_STR (0182)
    02fa  0e 09      MVI C, 09
    02fc  cd 05 00   CALL BDOS (0005)

    02ff  c3 00 00   JMP 0000

IN_BYTE_NO_SYNC:
    0302  3e 08      MVI A, 08                  ; Input a byte from the tape, no sync
    0304  c3 f4 03   JMP IN_BYTE (03f4)


; Calculate CRC for DE-HL memory range, return result in HL
CALC_CRC:
    0307  01 00 00   LXI BC, 0000               ; Prepare accumulator

CALC_CRC_LOOP:
    030a  1a         LDAX DE                    ; Load the next byte

    030b  81         ADD C                      ; Add the loaded byte to the result accumulator
    030c  4f         MOV C, A

    030d  3e 00      MVI A, 00                  ; Deal with high byte
    030f  88         ADC B
    0310  47         MOV B, A

    0311  13         INX DE                     ; Advance to the next byte

    0312  7a         MOV A, D                   ; Check if is reached the end of the range
    0313  bc         CMP H
    0314  c2 0a 03   JNZ CALC_CRC_LOOP (030a)

    0317  7b         MOV A, E
    0318  bd         CMP L
    0319  c2 0a 03   JNZ CALC_CRC_LOOP (030a)

    031c  69         MOV L, C                   ; Return the result in HL
    031d  60         MOV H, B
    031e  c9         RET


PRINT_CR_LF:
    031f  0e 02      MVI C, 02                  ; Print CR
    0321  1e 0d      MVI E, 0d
    0323  cd 05 00   CALL BDOS (0005)

    0326  0e 02      MVI C, 02                  ; Print LF
    0328  1e 0a      MVI E, 0a
    032a  c3 05 00   JMP BDOS (0005)

INPUT_DATA:
    032d  11 18 01   LXI DE, READY_FOR_INPUT_STR (0118) ; Prepare for input
    0330  0e 09      MVI C, 09
    0332  cd 05 00   CALL BDOS (0005)

    0335  0e 01      MVI C, 01                  ; Wait for a key press
    0337  cd 05 00   CALL BDOS (0005)

    033a  cd 1f 03   CALL PRINT_CR_LF (031f)    ; New line

    033d  3e ff      MVI A, ff                  ; Input for CRC low byte
    033f  cd f4 03   CALL IN_BYTE (03f4)
    0342  6f         MOV L, A

    0343  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Input for CRC high byte
    0346  67         MOV H, A

    0347  22 e6 01   SHLD FILE_CRC (01e6)       ; Store CRC

    034a  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Input data size low byte
    034d  6f         MOV L, A

    034e  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Input data size high byte
    0351  67         MOV H, A

    0352  22 e8 01   SHLD DATA_SIZE (01e8)      ; Store data size

    0355  eb         XCHG                       ; DE - data size
    0356  21 00 05   LXI HL, 0500               ; HL - data start address

IN_LOOP:
    0359  cd 02 03   CALL IN_BYTE_NO_SYNC (0302); Input next byte
    035c  77         MOV M, A

    035d  23         INX HL                     ; Advance to the next byte
    035e  1b         DCX DE

    035f  7a         MOV A, D                   ; Repeat until all bytes received
    0360  b3         ORA E
    0361  c2 59 03   JNZ IN_LOOP (0359)

    0364  2a e8 01   LHLD DATA_SIZE (01e8)      ; HL - data end address
    0367  11 00 05   LXI DE, 0500               ; DE - data start address
    036a  19         DAD DE

    036b  cd 07 03   CALL CALC_CRC (0307)       ; Calculate CRC, store in DE
    036e  eb         XCHG

    036f  2a e6 01   LHLD FILE_CRC (01e6)       ; HL - CRC read from the tape

    0372  7a         MOV A, D                   ; Compare calculated and read CRC
    0373  bc         CMP H
    0374  c2 7c 03   JNZ READ_ERROR (037c)

    0377  7b         MOV A, E
    0378  bd         CMP L
    0379  ca 87 03   JZ SAVE_TO_FILE (0387)
    
READ_ERROR:
    037c  11 74 01   LXI DE, READ_ERROR_STR (0174)  ; Report read error
    037f  0e 09      MVI C, 09
    0381  cd 05 00   CALL BDOS (0005)

    0384  c3 00 00   JMP 0000                   ; And exit to CP/M

SAVE_TO_FILE:
    0387  11 5c 00   LXI DE, FCB (005c)         ; Create file
    038a  0e 16      MVI C, 16
    038c  cd 05 00   CALL BDOS (0005)

    038f  fe ff      CPI A, ff                  ; Check if file cannot be created
    0391  c2 9f 03   JNZ SAVE_TO_FILE_1 (039f)

    0394  11 c1 01   LXI DE, NO_DIRECTORY_SPACE_STR (01c1)  ; Report error
    0397  0e 09      MVI C, 09
    0399  cd 05 00   CALL BDOS (0005)

    039c  c3 00 00   JMP 0000                   ; And exit

SAVE_TO_FILE_1:
    039f  21 00 05   LXI HL, 0500               ; Set the start address
    03a2  22 e4 01   SHLD CUR_PTR (01e4)

WRITE_LOOP:
    03a5  2a e4 01   LHLD CUR_PTR (01e4)        ; Load next chunk address
    03a8  eb         XCHG

    03a9  0e 1a      MVI C, 1a                  ; Set address of the next data chunk
    03ab  cd 05 00   CALL BDOS (0005)

    03ae  11 5c 00   LXI DE, FCB (005c)         ; Write the chunk of data
    03b1  0e 15      MVI C, 15
    03b3  cd 05 00   CALL BDOS (0005)

    03b6  b7         ORA A                      ; Check the error
    03b7  ca cd 03   JZ SAVE_TO_FILE_2 (03cd)

    03ba  11 d7 01   LXI DE, DISK_FULL_STR (01d7)   ; Report Disk full error
    03bd  0e 09      MVI C, 09
    03bf  cd 05 00   CALL BDOS (0005)

    03c2  11 5c 00   LXI DE, FCB (005c)         ; Delete partially stored file
    03c5  0e 13      MVI C, 13
    03c7  cd 05 00   CALL BDOS (0005)

    03ca  c3 00 00   JMP 0000                   ; Exit to CP/M

SAVE_TO_FILE_2:
    03cd  2a e4 01   LHLD CUR_PTR (01e4)        ; Advance to the next chunk of data
    03d0  11 80 00   LXI DE, 0080
    03d3  19         DAD DE
    03d4  22 e4 01   SHLD CUR_PTR (01e4)

    03d7  2a e8 01   LHLD DATA_SIZE (01e8)      ; Decrease data size by 0x0080
    03da  7d         MOV A, L
    03db  d6 80      SUI A, 80
    03dd  6f         MOV L, A
    03de  7c         MOV A, H
    03df  de 00      SBI A, 00
    03e1  67         MOV H, A
    03e2  22 e8 01   SHLD DATA_SIZE (01e8)

    03e5  b5         ORA L                      ; Repeat until all bytes were written to file
    03e6  c2 a5 03   JNZ WRITE_LOOP (03a5)

    03e9  11 5c 00   LXI DE, FCB (005c)         ; Close the file
    03ec  0e 10      MVI C, 10
    03ee  cd 05 00   CALL BDOS (0005)

    03f1  c3 00 00   JMP 0000                   ; Exit to CP/M

IN_BYTE:
    03f4  cd 06 f8   CALL MONITOR_IN_BYTE (f806); Input a byte from the tape (why don't it use BIOS function?)
    03f7  c9         RET

OUT_BYTE:
    03f8  cd 0c f8   CALL MONITOR_OUT_BYTE (f80c)   ; Output a byte to the tape (why don't it use BIOS function?)
    03fb  c9         RET

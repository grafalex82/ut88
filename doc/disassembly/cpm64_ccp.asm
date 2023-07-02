; CP/M-64 Console Command Processor (CCP)
;
; This code is loaded to the 0xc400-0xcbff by CP/M initial bootloader, and initially is located at
; 0x3400-0x3bff address range of the CP/M binary.
;
; CCP is a simple command processor for CP/M system. It accepts commands from the user, parses them,
; and execute commands as necessary. There are 6 built-in commands supported:
; - DIR - lists files on the disk (file patterns may be applied)
; - ERA - delete specified file
; - TYPE - print contents of the specified file to console
; - REN - rename the file
; - SAVE - saves piece of memory to a new file
; - USER - select current user
;
; Besides internal commands, CCP may execute external programs by loading them to the memory and passing
; them control flow.


; An entry point of CCP. This entry point allows a command to be pre-loaded to the command buffer, and
; executed on start.
START:
    c400  c3 5c c7   JMP REAL_START (c75c)

; Another entry point of CCP. This function clears the command buffer, and no command will be executed
; automatically during start-up process.
START_CLEAR:
    c403  c3 58 c7   JMP START_WITH_CLEAR (c758)

COMMAND_BUFFER:
    c406  7f                        db 7f               ; A 0x80-bytes buffer for input commands
COMMAND_BYTES:
    c407  00                        db 00               ; Actual number chars in the buffer
COMMAND_DATA:
    c408  7f * 00                   db 7f * 0x00        ; Command buffer

COPYRIGHT_STR:
    c408  20 20 20 20 20 20 20 20   db  "        "
    c410  20 20 20 20 20 20 20 20   db  "        "
    c418  43 4f 50 59 52 49 47 48   db  "COPYRIGH"
    c420  54 20 28 43 29 20 31 39   db  "T (C) 19"
    c428  37 39 2c 20 44 49 47 49   db  "79, DIGI"
    c430  54 41 4c 20 52 45 53 45   db  "TAL RESE"
    c438  41 52 43 48 20 20 00      db  "ARCH  ", 0x00


COMMAND_BUF_PTR:
    c488  08 c4                     db c408         ; Pointer to the next command or argument to parse

NEXT_CMD_PTR:
    c48a  00 00                     db 0000         ; Pointer to the next command word

; Call BDOS Put char function. Printed char in A register
PUT_CHAR:
    c48c  5f         MOV E, A
    c48d  0e 02      MVI C, 02
    c48f  c3 05 00   JMP 0005

; Call BDOS Put Char function, but save BC value
PUT_CHAR_SAVE_BC:
    c492  c5         PUSH BC
    c493  cd 8c c4   CALL PUT_CHAR (c48c)
    c496  c1         POP BC
    c497  c9         RET

; Print a new line on the console
PRINT_CR_LF:
    c498  3e 0d      MVI A, 0d
    c49a  cd 92 c4   CALL PUT_CHAR_SAVE_BC (c492)
    c49d  3e 0a      MVI A, 0a
    c49f  c3 92 c4   JMP PUT_CHAR_SAVE_BC (c492)

; Print a space symbol to the console
PRINT_SPACE:
    c4a2  3e 20      MVI A, 20
    c4a4  c3 92 c4   JMP PUT_CHAR_SAVE_BC (c492)

; Print a string starting from a new line. BC points to the string to print
PRINT_STR_FROM_NEW_LINE:
    c4a7  c5         PUSH BC
    c4a8  cd 98 c4   CALL PRINT_CR_LF (c498)
    c4ab  e1         POP HL

; Print a NULL-terminated string pointed by HL
PRINT_STR:
    c4ac  7e         MOV A, M
    c4ad  b7         ORA A
    c4ae  c8         RZ

    c4af  23         INX HL
    c4b0  e5         PUSH HL
    c4b1  cd 8c c4   CALL PUT_CHAR (c48c)
    c4b4  e1         POP HL
    c4b5  c3 ac c4   JMP PRINT_STR (c4ac)

; Call BDOS Disk Reset function
RESET_DISK_SYSTEM:
    c4b8  0e 0d      MVI C, 0d
    c4ba  c3 05 00   JMP 0005

; Call BDOS Select Disk function. A - disk to select
SELECT_DISK:
    c4bd  5f         MOV E, A
    c4be  0e 0e      MVI C, 0e
    c4c0  c3 05 00   JMP 0005

; Helper function to call BDOS and verify the result (0xff error code means error, Z flag is set)
CALL_BDOS_AND_CHECK_FF:
    c4c3  cd 05 00   CALL 0005
    c4c6  32 ee cb   STA BDOS_RESULT (cbee)
    c4c9  3c         INR A
    c4ca  c9         RET

; Call BDOS Open File function. DE - pointer to FCB
OPEN_FILE:
    c4cb  0e 0f      MVI C, 0f
    c4cd  c3 c3 c4   JMP CALL_BDOS_AND_CHECK_FF (c4c3)

; Open file, and reset record counter so that file can be read from the beginning
OPEN_FILE_RESET_POS:
    c4d0  af         XRA A                      ; Reset current record counter in FCB
    c4d1  32 ed cb   STA FCB+0x20 (cbed)

    c4d4  11 cd cb   LXI DE, FCB (cbcd)         ; Open the file
    c4d7  c3 cb c4   JMP OPEN_FILE (c4cb)

; Call BDOS Close file function. DE - pointer to FCB
CLOSE_FILE:
    c4da  0e 10      MVI C, 10
    c4dc  c3 c3 c4   JMP CALL_BDOS_AND_CHECK_FF (c4c3)

; Call BDOS Search First function, DE - pointer to FCB
DO_SEARCH_FIRST:
    c4df  0e 11      MVI C, 11
    c4e1  c3 c3 c4   JMP CALL_BDOS_AND_CHECK_FF (c4c3)

; Call BDOS Search Next function, DE - pointer to FCB
SEARCH_NEXT:
    c4e4  0e 12      MVI C, 12
    c4e6  c3 c3 c4   JMP CALL_BDOS_AND_CHECK_FF (c4c3)

; Call BDOS search first function, use default FCB
SEARCH_FIRST:
    c4e9  11 cd cb   LXI DE, FCB (cbcd)
    c4ec  c3 df c4   JMP DO_SEARCH_FIRST (c4df)

; Call BDOS delete file function, DE - pointer to FCB
DELETE_FILE:
    c4ef  0e 13      MVI C, 13
    c4f1  c3 05 00   JMP 0005

; Call BDOS function, and check the result. If return code is zero - set Z flag
CALL_BDOS_AND_CHECK_ZERO:
    c4f4  cd 05 00   CALL 0005
    c4f7  b7         ORA A
    c4f8  c9         RET

; Call BDOS Read Sequental function. DE - pointer to FCB
READ_SEQUENTAL:
    c4f9  0e 14      MVI C, 14
    c4fb  c3 f4 c4   JMP CALL_BDOS_AND_CHECK_ZERO (c4f4)

; Call BDOS Read Sequental function, use default FCB
READ_DEFAULT_FILE:
    c4fe  11 cd cb   LXI DE, FCB (cbcd)
    c501  c3 f9 c4   JMP READ_SEQUENTAL (c4f9)

; Call BDOS Write Sequental function, DE - pointer to FCB
WRITE_SEQUENTAL:
    c504  0e 15      MVI C, 15
    c506  c3 f4 c4   JMP CALL_BDOS_AND_CHECK_ZERO (c4f4)

; Call BDOS Create File function, DE - pointer to FCB
CREATE_FILE:
    c509  0e 16      MVI C, 16
    c50b  c3 c3 c4   JMP CALL_BDOS_AND_CHECK_FF (c4c3)

; Call BDOS Rename File function, DE - pointer to FCB
RENAME_FILE:
    c50e  0e 17      MVI C, 17
    c510  c3 05 00   JMP 0005

; Call BDOS Get User Code function. Return user code in A
GET_USER_CODE:
    c513  1e ff      MVI E, ff

; Call BDOS Set User code function. E - user code to set
SET_USER_CODE:
    c515  0e 20      MVI C, 20
    c517  c3 05 00   JMP 0005

; Store User Code and Current disk to 0x0004, value will survive on warm reboot
STORE_CCP_USER_AND_DISK:
    c51a  cd 13 c5   CALL GET_USER_CODE (c513)  ; Pack user code and current disk into a single byte
    c51d  87         ADD A
    c51e  87         ADD A
    c51f  87         ADD A
    c520  87         ADD A
    c521  21 ef cb   LXI HL, CURRENT_DISK (cbef)
    c524  b6         ORA M

    c525  32 04 00   STA 0004                   ; And store it in a variable, that will survive reboot
    c528  c9         RET

; Store current disk value to 0x0004, value will survive on warm reboot
STORE_CCP_DISK:
    c529  3a ef cb   LDA CURRENT_DISK (cbef)    ; Store current disk in a variable, that will survive reboot
    c52c  32 04 00   STA 0004
    c52f  c9         RET

; Helper function that converts character in A to the upper case.
TO_UPPER:
    c530  fe 61      CPI A, 61
    c532  d8         RC
    c533  fe 7b      CPI A, 7b
    c535  d0         RNC
    c536  e6 5f      ANI A, 5f
    c538  c9         RET

; Input next command
;
; The function gets the new command to the buffer in one of two ways:
; - if $$$.SUB substitution file is detected - load the file, and execute a command from there
; - input the command from the console otherwise (delegate to INPUT_COMMAND_CONSOLE)
;
; Regardless of the source of command, the input line is then parsed and processed.
INPUT_COMMAND:
    c539  3a ab cb   LDA SUBST_FILE_PRESENT (cbab)  ; If there is no substitution file - get the command
    c53c  b7         ORA A                          ; from console
    c53d  ca 96 c5   JZ INPUT_COMMAND_CONSOLE (c596)

    c540  3a ef cb   LDA CURRENT_DISK (cbef)        ; Select disk A if not already
    c543  b7         ORA A
    c544  3e 00      MVI A, 00
    c546  c4 bd c4   CNZ SELECT_DISK (c4bd)

    c549  11 ac cb   LXI DE, SUBST_FCB (cbac)       ; Open $$$.SUB file
    c54c  cd cb c4   CALL OPEN_FILE (c4cb)
    c54f  ca 96 c5   JZ INPUT_COMMAND_CONSOLE (c596)

    c552  3a bb cb   LDA SUBST_FCB + 0x0f (cbbb)    ; Seek to the last record
    c555  3d         DCR A
    c556  32 cc cb   STA SUBST_FCB + 0x20 (cbcc)

    c559  11 ac cb   LXI DE, SUBST_FCB (cbac)       ; Read the last record
    c55c  cd f9 c4   CALL READ_SEQUENTAL (c4f9)
    c55f  c2 96 c5   JNZ INPUT_COMMAND_CONSOLE (c596)

    c562  11 07 c4   LXI DE, COMMAND_BYTES (c407)   ; Copy bytes from the file to the command buffer
    c565  21 80 00   LXI HL, 0080
    c568  06 80      MVI B, 80
    c56a  cd 42 c8   CALL MEMCOPY_HL_DE (c842)

    c56d  21 ba cb   LXI HL, SPEC_FCB + 0x0e (cbba) ; Zero extent number high byte
    c570  36 00      MVI M, 00

    c572  23         INX HL                     ; Decrement records number
    c573  35         DCR M

    c574  11 ac cb   LXI DE, SUBST_FCB (cbac)   ; Close the file
    c577  cd da c4   CALL CLOSE_FILE (c4da)
    c57a  ca 96 c5   JZ INPUT_COMMAND_CONSOLE (c596)

    c57d  3a ef cb   LDA CURRENT_DISK (cbef)    ; Restore the disk if needed
    c580  b7         ORA A
    c581  c4 bd c4   CNZ SELECT_DISK (c4bd)

    c584  21 08 c4   LXI HL, COPYRIGHT_STR (c408)   ; Print the copyright string (or whatever is read from
    c587  cd ac c4   CALL PRINT_STR (c4ac)          ; $$$.SUB file)

    c58a  cd c2 c5   CALL GET_CHAR (c5c2)       ; Look for a key press
    c58d  ca a7 c5   JZ PARSE_COMMAND (c5a7)    ; If no keyboard pressed - parse and process the command

    c590  cd dd c5   CALL DELETE_SUBST_FILE (c5dd)  ; Delete the $$$.SUB 

    c593  c3 82 c7   JMP MAIN_COMMAND_LOOP (c782)   ; Read to enter the new command


; Input the next command from the console, then parse and process it
INPUT_COMMAND_CONSOLE:
    c596  cd dd c5   CALL DELETE_SUBST_FILE (c5dd)  ; Delete substitution file, if exists

    c599  cd 1a c5   CALL STORE_CCP_USER_AND_DISK (c51a)

    c59c  0e 0a      MVI C, 0a                  ; Read console to the buffer
    c59e  11 06 c4   LXI DE, COMMAND_BUFFER (c406)
    c5a1  cd 05 00   CALL 0005

    c5a4  cd 29 c5   CALL STORE_CCP_DISK (c529) ; Save disk code for reboots


; Parse the input command
;
; The function converts input string to upper case, and sets up buffer pointers
PARSE_COMMAND:
    c5a7  21 07 c4   LXI HL, COMMAND_BYTES (c407)   ; Load the command buffer address

    c5aa  46         MOV B, M                   ; Read number of entered chars

TO_UPPER_LOOP:
    c5ab  23         INX HL                     ; Advance to the next symbol

    c5ac  78         MOV A, B                   ; We are done if all bytes are processed
    c5ad  b7         ORA A
    c5ae  ca ba c5   JZ PARSE_COMMAND_1 (c5ba)

    c5b1  7e         MOV A, M                   ; Apply ToUpper() to the symbol
    c5b2  cd 30 c5   CALL TO_UPPER (c530)
    c5b5  77         MOV M, A

    c5b6  05         DCR B                      ; Advance to the next symbol
    c5b7  c3 ab c5   JMP TO_UPPER_LOOP (c5ab)

PARSE_COMMAND_1:
    c5ba  77         MOV M, A                   ; Add a terminating zero, and print the command

    c5bb  21 08 c4   LXI HL, COMMAND_DATA (c408); Store a pointer to the command bufer
    c5be  22 88 c4   SHLD COMMAND_BUF_PTR (c488)

    c5c1  c9         RET


; Check if there is a key pressed, if yes - read the symbol
;
; This function is typically used to break long lasting operations
GET_CHAR:
    c5c2  0e 0b      MVI C, 0b                  ; Check if there is something in the console (call BDOS' is
    c5c4  cd 05 00   CALL 0005                  ; key pressed function)
    c5c7  b7         ORA A
    c5c8  c8         RZ

    c5c9  0e 01      MVI C, 01                  ; Get the character from the console (call BDOS' wait for
    c5cb  cd 05 00   CALL 0005                  ; char function)
    c5ce  b7         ORA A
    c5cf  c9         RET

; Call BDOS get current disk function
GET_CURRENT_DISK:
    c5d0  0e 19      MVI C, 19
    c5d2  c3 05 00   JMP 0005

; Set the default disk buffer at 0x0080
SET_DEFAULT_DISK_BUFFER:
    c5d5  11 80 00   LXI DE, 0080

; Call BDOS Set disk buffer function. DE - pointer to the disk buffer
SET_DISK_BUFFER:
    c5d8  0e 1a      MVI C, 1a
    c5da  c3 05 00   JMP 0005

; Delete $$$.SUB substitution file, if present
DELETE_SUBST_FILE:
    c5dd  21 ab cb   LXI HL, SUBST_FILE_PRESENT (cbab)  ; Check if the flag is raised
    c5e0  7e         MOV A, M
    c5e1  b7         ORA A
    c5e2  c8         RZ                         ; Nothing to do if the flag is not set

    c5e3  36 00      MVI M, 00                  ; Reset the flag

    c5e5  af         XRA A                      ; Select disk A
    c5e6  cd bd c4   CALL SELECT_DISK (c4bd)

    c5e9  11 ac cb   LXI DE, SUBST_FCB (cbac)   ; Delete $$$.SUB file
    c5ec  cd ef c4   CALL DELETE_FILE (c4ef)

    c5ef  3a ef cb   LDA CURRENT_DISK (cbef)    ; Restore previous disk
    c5f2  c3 bd c4   JMP SELECT_DISK (c4bd)


; Compare serial numbers in CCP and BDOS. If they do not match - halt the system
CHECK_SERIAL:
    c5f5  11 28 c7   LXI DE, SERIAL_NUMER (c728); Pointer to serial number in CCP
    c5f8  21 00 cc   LXI HL, cc00               ; Pointer to serial number in BDOS
    c5fb  06 06      MVI B, 06                  ; Size of the serial number

CHECK_SERIAL_LOOP:
    c5fd  1a         LDAX DE                    ; Compare serial numbers byte-by-byte
    c5fe  be         CMP M
    c5ff  c2 cf c7   JNZ HALT_SYSTEM (c7cf)     ; Halt the system in case of serial number mismatch

    c602  13         INX DE                     ; Advance to the next byte
    c603  23         INX HL
    c604  05         DCR B
    c605  c2 fd c5   JNZ CHECK_SERIAL_LOOP (c5fd)

    c608  c9         RET                        ; Finish with Z flag


; Print Bad command message
;
; The function prints entered command, and a '?' sign indicating that command was not processed.
BAD_COMMAND:
    c609  cd 98 c4   CALL PRINT_CR_LF (c498)    ; Print error starting next string
    c60c  2a 8a c4   LHLD NEXT_CMD_PTR (c48a)

BAD_COMMAND_LOOP:
    c60f  7e         MOV A, M                   ; Load the next command symbol until space is found
    c610  fe 20      CPI A, 20
    c612  ca 22 c6   JZ BAD_COMMAND_1 (c622)

    c615  b7         ORA A                      ; ... or EOL is found
    c616  ca 22 c6   JZ BAD_COMMAND_1 (c622)

    c619  e5         PUSH HL                    ; Print the entered command
    c61a  cd 8c c4   CALL PUT_CHAR (c48c)
    c61d  e1         POP HL

    c61e  23         INX HL
    c61f  c3 0f c6   JMP BAD_COMMAND_LOOP (c60f)

BAD_COMMAND_1:
    c622  3e 3f      MVI A, 3f                  ; Print '?'
    c624  cd 8c c4   CALL PUT_CHAR (c48c)

    c627  cd 98 c4   CALL PRINT_CR_LF (c498)    ; Next command will be entered starting the new line

    c62a  cd dd c5   CALL DELETE_SUBST_FILE (c5dd)  ; Delete substitution file, just in case

    c62d  c3 82 c7   JMP MAIN_COMMAND_LOOP (c782)


; Return Z flag set if symbol is not valid for a command
CHECK_VALID_SYMBOL:
    c630  1a         LDAX DE                    ; Stop if EOL reached
    c631  b7         ORA A
    c632  c8         RZ

    c633  fe 20      CPI A, 20                  ; Stop if space reached
    c635  da 09 c6   JC BAD_COMMAND (c609)      ; Symbols below 0x20 are not allowed
    c638  c8         RZ

    c639  fe 3d      CPI A, 3d                  ; Match '='
    c63b  c8         RZ
    c63c  fe 5f      CPI A, 5f                  ; Match '_'
    c63e  c8         RZ
    c63f  fe 2e      CPI A, 2e                  ; Match '.'
    c641  c8         RZ
    c642  fe 3a      CPI A, 3a                  ; Match ':'
    c644  c8         RZ
    c645  fe 3b      CPI A, 3b                  ; Match ';'
    c647  c8         RZ
    c648  fe 3c      CPI A, 3c                  ; Match '<'
    c64a  c8         RZ
    c64b  fe 3e      CPI A, 3e                  ; Match '>'
    c64d  c8         RZ

    c64e  c9         RET

; Search for non-space and non zero symbol at [DE] string
SEARCH_NEXT_SYMBOL:
    c64f  1a         LDAX DE                    ; Load next symbol, and compare it with zero
    c650  b7         ORA A
    c651  c8         RZ

    c652  fe 20      CPI A, 20                  ; Skip all spaces, return on valid symbols
    c654  c0         RNZ

    c655  13         INX DE                     ; Advance to the next symbol
    c656  c3 4f c6   JMP SEARCH_NEXT_SYMBOL (c64f)

ADD_HL_A:
    c659  85         ADD L
    c65a  6f         MOV L, A
    c65b  d0         RNC
    c65c  24         INR H
    c65d  c9         RET


; Parse file name in the buffer, and store parsed name in FCB
;
; The function parses buffer string pointed by COMMAND_BUF_PTR, and match there a pattern:
; [<disk code>:]<file name>.<file extension>
; If a corresponding pattern is matched, it is placed in the FCB in corresponding fields
;
; The function supports '*' wildcard symbol for name or extension, which is converted to number of '?' in FCB
;
; The last thing this function performs is counting '?' in the file name and extension fields. This is needed
; to understand whether this is exact file name or a pattern. Number of '?' is returned in A.
PARSE_FILE_NAME:
    c65e  3e 00      MVI A, 00

; Parse file name in other part of FCB (A - offset)
PARSE_FILE_NAME_ADV:
    c660  21 cd cb   LXI HL, FCB (cbcd)         ; Calculate desired offset in the FCB structure
    c663  cd 59 c6   CALL ADD_HL_A (c659)

    c666  e5         PUSH HL
    c667  e5         PUSH HL

    c668  af         XRA A                      ; Mark disk is not specified, unless we find disk code
    c669  32 f0 cb   STA COMMAND_DISK (cbf0)

    c66c  2a 88 c4   LHLD COMMAND_BUF_PTR (c488); Load command buffer pointer to DE
    c66f  eb         XCHG

    c670  cd 4f c6   CALL SEARCH_NEXT_SYMBOL (c64f) ; Search for a command symbol, place pointer to HL
    c673  eb         XCHG

    c674  22 8a c4   SHLD NEXT_CMD_PTR (c48a)   ; Store found command pointer, move to DE
    c677  eb         XCHG
    c678  e1         POP HL

    c679  1a         LDAX DE                    ; Check if we are at the end of the string
    c67a  b7         ORA A
    c67b  ca 89 c6   JZ PARSE_FILE_NAME_1 (c689)

    c67e  de 40      SBI A, 40                  ; Match "<disk>:" disk specification
    c680  47         MOV B, A                   ; Store disk number in B
    c681  13         INX DE

    c682  1a         LDAX DE
    c683  fe 3a      CPI A, 3a
    c685  ca 90 c6   JZ DISK_SPEC (c690)

    c688  1b         DCX DE                     ; This is not a disk selection - will be using cur disk

PARSE_FILE_NAME_1:
    c689  3a ef cb   LDA CURRENT_DISK (cbef)    ; Use current disk, and set it to FCB
    c68c  77         MOV M, A
    c68d  c3 96 c6   JMP PARSE_FILE_NAME_2 (c696)

DISK_SPEC:
    c690  78         MOV A, B                   ; Store selected disk in the variable to be widely used later
    c691  32 f0 cb   STA COMMAND_DISK (cbf0)

    c694  70         MOV M, B                   ; Store selected disk in FCB
    c695  13         INX DE


PARSE_FILE_NAME_2:
    c696  06 08      MVI B, 08                  ; Will match up to 8 file name characters

PARSE_FILE_NAME_LOOP:
    c698  cd 30 c6   CALL CHECK_VALID_SYMBOL (c630) ; Check if the symbol is valid
    c69b  ca b9 c6   JZ PARSE_FILE_NAME_6 (c6b9)    ; Otherwise switch to extension field

    c69e  23         INX HL

    c69f  fe 2a      CPI A, 2a                  ; Match symbol with '*'
    c6a1  c2 a9 c6   JNZ PARSE_FILE_NAME_3 (c6a9)

    c6a4  36 3f      MVI M, 3f                  ; Store '?' in FCB if '*' is passed
    c6a6  c3 ab c6   JMP PARSE_FILE_NAME_4 (c6ab)

PARSE_FILE_NAME_3:
    c6a9  77         MOV M, A                   ; If this is a normal symbol - copy it to FCB
    c6aa  13         INX DE

PARSE_FILE_NAME_4:
    c6ab  05         DCR B                      ; Repeat for all symbols
    c6ac  c2 98 c6   JNZ PARSE_FILE_NAME_LOOP (c698)

PARSE_FILE_NAME_5:
    c6af  cd 30 c6   CALL CHECK_VALID_SYMBOL (c630) ; Iterate till the next command word
    c6b2  ca c0 c6   JZ PARSE_FILE_NAME_7 (c6c0)    ; then switch to match extension

    c6b5  13         INX DE
    c6b6  c3 af c6   JMP PARSE_FILE_NAME_5 (c6af)

PARSE_FILE_NAME_6:
    c6b9  23         INX HL                     ; If command is shorter than 8 symbols - pad with spaces
    c6ba  36 20      MVI M, 20
    c6bc  05         DCR B
    c6bd  c2 b9 c6   JNZ PARSE_FILE_NAME_6 (c6b9)

PARSE_FILE_NAME_7:
    c6c0  06 03      MVI B, 03                  ; Match a '.'. If no extension provided - fill extension
    c6c2  fe 2e      CPI A, 2e                  ; field in the FCB with spaces
    c6c4  c2 e9 c6   JNZ PARSE_FILE_NAME_12 (c6e9)
    c6c7  13         INX DE

PARSE_FILE_NAME_8:
    c6c8  cd 30 c6   CALL CHECK_VALID_SYMBOL (c630)
    c6cb  ca e9 c6   JZ PARSE_FILE_NAME_12 (c6e9)

    c6ce  23         INX HL                     ; If '* is specified - fill FCB with '?'
    c6cf  fe 2a      CPI A, 2a
    c6d1  c2 d9 c6   JNZ PARSE_FILE_NAME_9 (c6d9)

    c6d4  36 3f      MVI M, 3f
    c6d6  c3 db c6   JMP PARSE_FILE_NAME_10 (c6db)

PARSE_FILE_NAME_9:
    c6d9  77         MOV M, A                   ; Normal symbols are just copied
    c6da  13         INX DE

PARSE_FILE_NAME_10:
    c6db  05         DCR B                      ; Repeat for all 3 symbols of extension
    c6dc  c2 c8 c6   JNZ PARSE_FILE_NAME_8 (c6c8)

PARSE_FILE_NAME_11:
    c6df  cd 30 c6   CALL CHECK_VALID_SYMBOL (c630) ; Symbols over 3 extension chars are just skipped
    c6e2  ca f0 c6   JZ PARSE_FILE_NAME_13 (c6f0)
    c6e5  13         INX DE
    c6e6  c3 df c6   JMP PARSE_FILE_NAME_11 (c6df)

PARSE_FILE_NAME_12:
    c6e9  23         INX HL                     ; If extension is shorter than 3 symbols (or not provided)
    c6ea  36 20      MVI M, 20                  ; Fill corresponding FCB bytes with spaces
    c6ec  05         DCR B
    c6ed  c2 e9 c6   JNZ PARSE_FILE_NAME_12 (c6e9)


PARSE_FILE_NAME_13:
    c6f0  06 03      MVI B, 03                  ; Fill next 3 FCB bytes with zeros (extent number and record
PARSE_FILE_NAME_14:                             ; counter fields
    c6f2  23         INX HL
    c6f3  36 00      MVI M, 00
    c6f5  05         DCR B
    c6f6  c2 f2 c6   JNZ PARSE_FILE_NAME_14 (c6f2)

    c6f9  eb         XCHG                       ; Store the pointer to next command argument
    c6fa  22 88 c4   SHLD COMMAND_BUF_PTR (c488)

    c6fd  e1         POP HL
    c6fe  01 0b 00   LXI BC, 000b               ; Check 8+3 symbols of FCB (name/extension)

PARSE_FILE_NAME_15:
    c701  23         INX HL                     ; Search for '?' symbol in the name or extension
    c702  7e         MOV A, M
    c703  fe 3f      CPI A, 3f
    c705  c2 09 c7   JNZ PARSE_FILE_NAME_16 (c709)

    c708  04         INR B                      ; Increment counter of found '?'s

PARSE_FILE_NAME_16:
    c709  0d         DCR C                      ; Repeat for all 11 symbols
    c70a  c2 01 c7   JNZ PARSE_FILE_NAME_15 (c701)

    c70d  78         MOV A, B                   ; Return Z flag set if file name is exact, and Z=false
    c70e  b7         ORA A                      ; if at least '?' is found in the file name

    c70f  c9         RET

; The list of built-in commands
COMMANDS_TABLE:
    c710  44 49 52 20           db  "DIR "
    c714  45 52 41 20           db  "ERA "
    c718  54 59 50 45           db  "TYPE"
    c71c  53 41 56 45           db  "SAVE"
    c720  52 45 4e 20           db  "REN "
    c724  55 53 45 52           db  "USER"


SERIAL_NUMER:
    c728  f9 16 00 00 00 6b


; Function that matches entered command with one of the built-in commands in the list.
;
; Function returns the index of found command (0-5) or 6 if any built-in command was not matched
MATCH_COMMAND:
    c72e  21 10 c7   LXI HL, COMMANDS_TABLE (c710)
    c731  0e 00      MVI C, 00

MATCH_NEXT_COMMAND:
    c733  79         MOV A, C                   ; Match up to 6 commands in the table
    c734  fe 06      CPI A, 06
    c736  d0         RNC

    c737  11 ce cb   LXI DE, FCB+0x01 (cbce)    ; Expect the command name in FCB name area

    c73a  06 04      MVI B, 04                  ; Match 4 chars of the command

MATCH_COMMAND_NEXT_CHAR:
    c73c  1a         LDAX DE                    ; Compare chars
    c73d  be         CMP M
    c73e  c2 4f c7   JNZ c74f

    c741  13         INX DE                     ; Advance to the next char
    c742  23         INX HL
    c743  05         DCR B
    c744  c2 3c c7   JNZ MATCH_COMMAND_NEXT_CHAR (c73c)

    c747  1a         LDAX DE                    ; We matched all 4 chars of the command
    c748  fe 20      CPI A, 20                  ; Check if the next character is space (command is no longer
    c74a  c2 54 c7   JNZ MATCH_NEXT_COMMAND_2 (c754)    ; than 4 chars)

    c74d  79         MOV A, C                   ; Return matched command index in A
    c74e  c9         RET

MATCH_NEXT_COMMAND_1:
    c74f  23         INX HL                     ; Advance to the next command
    c750  05         DCR B
    c751  c2 4f c7   JNZ MATCH_NEXT_COMMAND_1 (c74f)

MATCH_NEXT_COMMAND_2:
    c754  0c         INR C                      ; Increment commands counter and repeat
    c755  c3 33 c7   JMP MATCH_NEXT_COMMAND (c733)


; CCP Start with clearing the command buffer
START_WITH_CLEAR:
    c758  af         XRA A                      ; Clear the number of bytes in the buffer
    c759  32 07 c4   STA COMMAND_BYTES (c407)


; CCP Entry Point
;
; This is the main function of the CCP. 
;
; The function takes an argument passed from BIOS when starting CCP. Depending on cold/warm start this
; field will be either cleared, or restored from 0x0004.
;
; The function does initial initialization of the CCP, including stack, current disk, user code, etc. Then
; it gets the command to process, parses it, and executes.
;
; As an input, commands may be obtained in 3 ways:
; - Command may be pre-defined in the command buffer prior CCP start. This is a way to submit commands
;   during reboot
; - Command may be loaded from a $$$.SUB substutution file. However function relies that BDOS will report
;   presense of this file during disk reset function, but this is not really documented or implemented.
; - Finally commands typically entered from the console.
;
; The commands may be internal (built-in) or external. In first case a predefined handler is executed. 
; External commands are processed in CMD_OTHER function, and load the specified command file.
REAL_START:
    c75c  31 ab cb   LXI SP, CCP_STACK_TOP (cbab)   ; Set up stack

    c75f  c5         PUSH BC                    ; Take upper 4 bits of argument, and shift them to lower
    c760  79         MOV A, C                   ; 4 bits
    c761  1f         RAR
    c762  1f         RAR
    c763  1f         RAR
    c764  1f         RAR
    c765  e6 0f      ANI A, 0f
    c767  5f         MOV E, A

    c768  cd 15 c5   CALL SET_USER_CODE (c515)  ; Set this as user code

    c76b  cd b8 c4   CALL RESET_DISK_SYSTEM (c4b8)
    
    c76e  32 ab cb   STA SUBST_FILE_PRESENT (cbab)  ; Expect that disk reset function will raise the flag
    c771  c1         POP BC                         ; if there is $$$.SUB file is on the disk ?????

    c772  79         MOV A, C                   ; Take lower 4 bits of the argument and set as current disk
    c773  e6 0f      ANI A, 0f
    c775  32 ef cb   STA CURRENT_DISK (cbef)

    c778  cd bd c4   CALL SELECT_DISK (c4bd)    ; Select the disk in the system

    c77b  3a 07 c4   LDA COMMAND_BYTES (c407)   ; Check if there are any bytes in the buffer already
    c77e  b7         ORA A
    c77f  c2 98 c7   JNZ PROCESS_COMMAND_BUFFER (c798)


MAIN_COMMAND_LOOP:
    c782  31 ab cb   LXI SP, CCP_STACK_TOP (cbab)   ; Set our own stack

    c785  cd 98 c4   CALL PRINT_CR_LF (c498)        ; Print prompt: disk letter, and > sign
    c788  cd d0 c5   CALL GET_CURRENT_DISK (c5d0)
    c78b  c6 41      ADI A, 41
    c78d  cd 8c c4   CALL PUT_CHAR (c48c)
    c790  3e 3e      MVI A, 3e
    c792  cd 8c c4   CALL PUT_CHAR (c48c)

    c795  cd 39 c5   CALL INPUT_COMMAND (c539)  ; Get the command (either from console, or from subst file)

PROCESS_COMMAND_BUFFER:
    c798  11 80 00   LXI DE, 0080               ; Setup the disk buffer pointer
    c79b  cd d8 c5   CALL SET_DISK_BUFFER (c5d8)

    c79e  cd d0 c5   CALL GET_CURRENT_DISK (c5d0)   ; Reset current disk variable
    c7a1  32 ef cb   STA CURRENT_DISK (cbef)

    c7a4  cd 5e c6   CALL PARSE_FILE_NAME (c65e)    ; Put file name or a command name to FCB
    c7a7  c4 09 c6   CNZ BAD_COMMAND (c609)

    c7aa  3a f0 cb   LDA COMMAND_DISK (cbf0)    ; If command specifies a disk, it cannot be a built-in
    c7ad  b7         ORA A                      ; command - process it as external command.
    c7ae  c2 a5 ca   JNZ CMD_OTHER (caa5)       

    c7b1  cd 2e c7   CALL MATCH_COMMAND (c72e)  ; Check if this is a built in command

    c7b4  21 c1 c7   LXI HL, c7c1               ; Calculate command handler address
    c7b7  5f         MOV E, A
    c7b8  16 00      MVI D, 00
    c7ba  19         DAD DE
    c7bb  19         DAD DE

    c7bc  7e         MOV A, M                   ; Get command handler address to HL
    c7bd  23         INX HL
    c7be  66         MOV H, M
    c7bf  6f         MOV L, A

    c7c0  e9         PCHL                       ; Execute the command handler


COMMAND_HANDLERS:
    c7c1  77 c8     dw CMD_DIR (c877)           ; Command DIR
    c7c3  1f c9     dw CMD_ERA (c91f)           ; Command ERA
    c7c5  5d c9     dw CMD_TYPE (c95d)          ; Command TYPE
    c7c7  ad c9     dw CMD_SAVE (c9ad)          ; Command SAVE
    c7c9  10 ca     dw CMD_REN (ca10)           ; Command REN
    c7cb  8e ca     dw CMD_USER (ca8e)          ; Command USER
    c7cd  a5 ca     dw CMD_OTHER (caa5)         ; Not built-in command


; Halt the system
;
; The function writes DI and HLT opcodes instead of CCP entry point, so that system will halt on every boot
HALT_SYSTEM:
    c7cf  21 f3 76   LXI HL, 76f3               ; Write DI and HLT opcodes to 0xc400 entry point
    c7d2  22 00 c4   SHLD c400

    c7d5  21 00 c4   LXI HL, c400               ; Execute the entry point
    c7d8  e9         PCHL

; Print a read error message
PRINT_READ_ERROR:
    c7d9  01 df c7   LXI BC, READ_ERROR_STR (c7df)
    c7dc  c3 a7 c4   JMP PRINT_STR_FROM_NEW_LINE (c4a7)

READ_ERROR_STR:
    c7df  52 45 41 44 20 45 52 52   db  "READ ERR"
    c7e7  4f 52 00                  db  "OR", 0x00

; Print NO FILE error message
PRINT_NO_FILE_ERROR:
    c7ea  01 f0 c7   LXI BC, NO_FILE_STR (c7f0)
    c7ed  c3 a7 c4   JMP PRINT_STR_FROM_NEW_LINE (c4a7)

NO_FILE_STR:
    c7f0  4e 4f 20 46 49 4c 45 00   db  "NO FILE", 0x00


; Parse a 0-255 number that may be passed as an argument
PARSE_NUMBER:
    c7f8  cd 5e c6   CALL PARSE_FILE_NAME (c65e); Separate the parameter (from other params), store it to FCB

    c7fb  3a f0 cb   LDA COMMAND_DISK (cbf0)    ; If a disk is specified (not just number) - this is an error
    c7fe  b7         ORA A
    c7ff  c2 09 c6   JNZ BAD_COMMAND (c609)

    c802  21 ce cb   LXI HL, FCB+0x01 (cbce)    ; Get pointer to the first byte of the param
    c805  01 0b 00   LXI BC, 000b               ; B=0 (result), No more 11 bytes to process (C register). 

PARSE_NUMBER_LOOP:
    c808  7e         MOV A, M                   ; Get the next byte, unless it is space
    c809  fe 20      CPI A, 20
    c80b  ca 33 c8   JZ PARSE_NUMBER_LOOP_2 (c833)

    c80e  23         INX HL                     ; Advance pointer to the next byte

    c80f  d6 30      SUI A, 30                  ; Expect symbols between 0 and 9, otherwise report an error
    c811  fe 0a      CPI A, 0a
    c813  d2 09 c6   JNC BAD_COMMAND (c609)

    c816  57         MOV D, A                   ; Store parsed digit in D for now

    c817  78         MOV A, B                   ; Check if result is not too big
    c818  e6 e0      ANI A, e0
    c81a  c2 09 c6   JNZ BAD_COMMAND (c609)

    c81d  78         MOV A, B                   ; Multiply B by 10 (A*8 + A + A)
    c81e  07         RLC
    c81f  07         RLC
    c820  07         RLC
    c821  80         ADD B
    c822  da 09 c6   JC BAD_COMMAND (c609)      ; Control overflow
    c825  80         ADD B
    c826  da 09 c6   JC BAD_COMMAND (c609)

    c829  82         ADD D                      ; Add parsed digit
    c82a  da 09 c6   JC BAD_COMMAND (c609)

    c82d  47         MOV B, A                   ; Store result in B

    c82e  0d         DCR C                      ; Parse other characters
    c82f  c2 08 c8   JNZ PARSE_NUMBER_LOOP (c808)

    c832  c9         RET

PARSE_NUMBER_LOOP_2:
    c833  7e         MOV A, M                   ; All other non-digit characters must be spaces (no other
    c834  fe 20      CPI A, 20                  ; characters allowed)
    c836  c2 09 c6   JNZ BAD_COMMAND (c609)

    c839  23         INX HL                     ; Advance to the next byte, until all 11 chars processed
    c83a  0d         DCR C
    c83b  c2 33 c8   JNZ PARSE_NUMBER_LOOP_2 (c833)

    c83e  78         MOV A, B                   ; Return the result
    c83f  c9         RET



; Copy 3 bytes from [HL] to [DE]
MEMCOPY_3_BYTES_HL_DE:
    c840  06 03      MVI B, 03

; Copy B bytes from [HL] to [DE]
MEMCOPY_HL_DE:
    c842  7e         MOV A, M
    c843  12         STAX DE
    c844  23         INX HL
    c845  13         INX DE
    c846  05         DCR B
    c847  c2 42 c8   JNZ MEMCOPY_HL_DE (c842)
    c84a  c9         RET

; A = [HL + A + C]
GET_DIR_ENTRY_BYTE:
    c84b  21 80 00   LXI HL, 0080
    c84e  81         ADD C
    c84f  cd 59 c6   CALL ADD_HL_A (c659)
    c852  7e         MOV A, M
    c853  c9         RET


; Select the disk specified in the command
;
; The function checks if the disk is already selected, and does not perform extra initialization
SELECT_COMMAND_DISK:
    c854  af         XRA A                      ; Reset disk field of the FCB
    c855  32 cd cb   STA FCB (cbcd)

    c858  3a f0 cb   LDA COMMAND_DISK (cbf0)    ; Check if command is executed on the default disk
    c85b  b7         ORA A
    c85c  c8         RZ

    c85d  3d         DCR A                      ; Check if the command is executed on the current disk
    c85e  21 ef cb   LXI HL, CURRENT_DISK (cbef)
    c861  be         CMP M
    c862  c8         RZ

    c863  c3 bd c4   JMP SELECT_DISK (c4bd)     ; Select disk otherwise


; Restore the disk user prior the command execution
RESTORE_CURRENT_DISK:
    c866  3a f0 cb   LDA COMMAND_DISK (cbf0)    ; Check if command is executed on the default disk
    c869  b7         ORA A
    c86a  c8         RZ

    c86b  3d         DCR A                      ; Check if command is executed on the current disk
    c86c  21 ef cb   LXI HL, CURRENT_DISK (cbef)
    c86f  be         CMP M
    c870  c8         RZ

    c871  3a ef cb   LDA CURRENT_DISK (cbef)    ; Restore the current disk
    c874  c3 bd c4   JMP SELECT_DISK (c4bd)


; DIR built-in command
;
; The command displays the content of the disk, apply filtering by disk letter or file name if needed.
;
; The function searches file by pattern provided. If no argument is provided, then it uses ????????.??? 
; pattern. Function prints 4 files in the line, each line is prefixed with the disk letter.
CMD_DIR:
    c877  cd 5e c6   CALL PARSE_FILE_NAME (c65e); Check if disk name is provided as argument
    c87a  cd 54 c8   CALL SELECT_COMMAND_DISK (c854)    ; Select new disk if needed

    c87d  21 ce cb   LXI HL, FCB+0x01 (cbce)    ; Check if any name is provided as dir command argument
    c880  7e         MOV A, M
    c881  fe 20      CPI A, 20
    c883  c2 8f c8   JNZ CMD_DIR_1 (c88f)

    c886  06 0b      MVI B, 0b                  ; If not - generate all-question-marks pattern
CMD_DIR_FILL_QM_LOOP:
    c888  36 3f      MVI M, 3f
    c88a  23         INX HL
    c88b  05         DCR B
    c88c  c2 88 c8   JNZ CMD_DIR_FILL_QM_LOOP (c888)

CMD_DIR_1:
    c88f  1e 00      MVI E, 00                  ; Reset files counter (to print only 4 files per line)
    c891  d5         PUSH DE

    c892  cd e9 c4   CALL SEARCH_FIRST (c4e9)   ; Search for files

    c895  cc ea c7   CZ PRINT_NO_FILE_ERROR (c7ea)  ; If no files found - print an error

CMD_DIR_FILE_LOOP:
    c898  ca 1b c9   JZ CMD_DIR_EXIT (c91b)     ; If no more files left - exit the command

    c89b  3a ee cb   LDA BDOS_RESULT (cbee)     ; Calculate offset of the directory entry returned by 
    c89e  0f         RRC                        ; BDOS search function 
    c89f  0f         RRC
    c8a0  0f         RRC
    c8a1  e6 60      ANI6 A, 60
    c8a3  4f         MOV C, A

    c8a4  3e 0a      MVI A, 0a                  ; Get byte 10 of the directory entry (2nd byte of extension)
    c8a6  cd 4b c8   CALL GET_DIR_ENTRY_BYTE (c84b)

    c8a9  17         RAL                        ; MSB of the byte 10 marks the file as system, and should not
    c8aa  da 0f c9   JC c90f                    ; be printed with the DIR command

    c8ad  d1         POP DE                     ; Increment the files counter
    c8ae  7b         MOV A, E
    c8af  1c         INR E

    c8b0  d5         PUSH DE                    ; Check if we printed next 4 files
    c8b1  e6 03      ANI A, 03
    c8b3  f5         PUSH PSW
    c8b4  c2 cc c8   JNZ CMD_DIR_2 (c8cc)

    c8b7  cd 98 c4   CALL PRINT_CR_LF (c498)    ; Print new line every 4 files

    c8ba  c5         PUSH BC                    ; Print drive letter in the beginning of each line
    c8bb  cd d0 c5   CALL GET_CURRENT_DISK (c5d0)
    c8be  c1         POP BC
    c8bf  c6 41      ADI A, 41
    c8c1  cd 92 c4   CALL PUT_CHAR_SAVE_BC (c492)

    c8c4  3e 3a      MVI A, 3a                  ; Print ':'
    c8c6  cd 92 c4   CALL PUT_CHAR_SAVE_BC (c492)

    c8c9  c3 d4 c8   JMP CMD_DIR_3 (c8d4)

CMD_DIR_2:
    c8cc  cd a2 c4   CALL PRINT_SPACE (c4a2)    ; Files within the line are split with ' : '
    c8cf  3e 3a      MVI A, 3a
    c8d1  cd 92 c4   CALL PUT_CHAR_SAVE_BC (c492)

CMD_DIR_3:
    c8d4  cd a2 c4   CALL PRINT_SPACE (c4a2)    ; Print space separator

    c8d7  06 01      MVI B, 01                  ; Load the name offset in the directory entry
CMD_DIR_4:
    c8d9  78         MOV A, B                   ; Get next symbol
    c8da  cd 4b c8   CALL GET_DIR_ENTRY_BYTE (c84b)

    c8dd  e6 7f      ANI A, 7f                  ; Print only printable chars
    c8df  fe 20      CPI A, 20
    c8e1  c2 f9 c8   JNZ CMD_DIR_6 (c8f9)

    c8e4  f1         POP PSW                    ; Avoid printing extra characters for files without extension
    c8e5  f5         PUSH PSW                   ; when this is the last file in the line
    c8e6  fe 03      CPI A, 03
    c8e8  c2 f7 c8   JNZ CMD_DIR_5 (c8f7)

    c8eb  3e 09      MVI A, 09                  ; Move to the extension
    c8ed  cd 4b c8   CALL GET_DIR_ENTRY_BYTE (c84b)

    c8f0  e6 7f      ANI A, 7f                  ; Check if the extension is empty
    c8f2  fe 20      CPI A, 20
    c8f4  ca 0e c9   JZ CMD_DIR_7 (c90e)

CMD_DIR_5:
    c8f7  3e 20      MVI A, 20

CMD_DIR_6:
    c8f9  cd 92 c4   CALL PUT_CHAR_SAVE_BC (c492)   ; Print spaces...

    c8fc  04         INR B                      ; ... until both name and extension is printed
    c8fd  78         MOV A, B
    c8fe  fe 0c      CPI A, 0c
    c900  d2 0e c9   JNC CMD_DIR_7 (c90e)

    c903  fe 09      CPI A, 09                  ; Print extra space between name and extension
    c905  c2 d9 c8   JNZ CMD_DIR_4 (c8d9)
    c908  cd a2 c4   CALL PRINT_SPACE (c4a2)

    c90b  c3 d9 c8   JMP c8d9                   ; Advance to the next symbol

CMD_DIR_7:
    c90e  f1         POP PSW

CMD_DIR_NEXT_FILE:
    c90f  cd c2 c5   CALL GET_CHAR (c5c2)       ; Check if we were stopped
    c912  c2 1b c9   JNZ CMD_DIR_EXIT (c91b)

    c915  cd e4 c4   CALL SEARCH_NEXT (c4e4)    ; Search for the next file
    c918  c3 98 c8   JMP CMD_DIR_FILE_LOOP (c898)

CMD_DIR_EXIT:
    c91b  d1         POP DE
    c91c  c3 86 cb   JMP CMD_EXIT_RESTORE_DISK (cb86)


; ERA (Erase) built-in command
;
; Delete a file (masks are supported). If the user accidentally wants to erase all files (ERA *.*), the user
; will be asked with a confirmation.
CMD_ERA:
    c91f  cd 5e c6   CALL PARSE_FILE_NAME (c65e)    ; Parse arguments

    c922  fe 0b      CPI A, 0b                      ; Check if all files match
    c924  c2 42 c9   JNZ CMD_ERA_DO_DELETE (c942)

    c927  01 52 c9   LXI BC, ALL_STR (c952)         ; Warn user which wants to delete all the files
    c92a  cd a7 c4   CALL PRINT_STR_FROM_NEW_LINE (c4a7)

    c92d  cd 39 c5   CALL INPUT_COMMAND (c539)      ; Get user's decision
    c930  21 07 c4   LXI HL, COMMAND_BYTES (c407)

    c933  35         DCR M                          ; Expect only 1 byte in the answer
    c934  c2 82 c7   JNZ MAIN_COMMAND_LOOP (c782)

    c937  23         INX HL                         ; Check if the answer was 'Yes'
    c938  7e         MOV A, M
    c939  fe 59      CPI A, 59
    c93b  c2 82 c7   JNZ MAIN_COMMAND_LOOP (c782)

    c93e  23         INX HL                         ; Advance to the next argument
    c93f  22 88 c4   SHLD COMMAND_BUF_PTR (c488)

CMD_ERA_DO_DELETE:
    c942  cd 54 c8   CALL SELECT_COMMAND_DISK (c854); Select the disk

    c945  11 cd cb   LXI DE, FCB (cbcd)         ; Actually delete the file
    c948  cd ef c4   CALL DELETE_FILE (c4ef)

    c94b  3c         INR A                      ; If no file was deleted - print the error message

    c94c  cc ea c7   CZ PRINT_NO_FILE_ERROR (c7ea)
    c94f  c3 86 cb   JMP CMD_EXIT_RESTORE_DISK (cb86)


ALL_STR:
    c952  41 4c 4c 20 28 59 2f 4e   db  "ALL (Y/N"
    c95a  29 3f 00                  db  ")?", 0x00


; TYPE built-in command
;
; This function prints the specified file to the console, until no more data in the file left, or 0x1a
; end-of-file symbol is reached.
CMD_TYPE:
    c95d  cd 5e c6   CALL PARSE_FILE_NAME (c65e)    ; Expect the file name as an argument
    c960  c2 09 c6   JNZ BAD_COMMAND (c609)

    c963  cd 54 c8   CALL SELECT_COMMAND_DISK (c854); Select the disk if needed

    c966  cd d0 c4   CALL OPEN_FILE_RESET_POS (c4d0); Open the file
    c969  ca a7 c9   JZ CMD_TYPE_EXIT_WITH_ERROR (c9a7)

    c96c  cd 98 c4   CALL PRINT_CR_LF (c498)        ; Start printing the file contents with the new line

    c96f  21 f1 cb   LXI HL, TYPE_BYTE_COUNTER (cbf1) ; Reset the printed bytes counter for the current sector
    c972  36 ff      MVI M, ff

CMD_TYPE_LOOP:
    c974  21 f1 cb   LXI HL, TYPE_BYTE_COUNTER (cbf1)   ; Check if we printed less than 128 bytes, otherwise
    c977  7e         MOV A, M                       ; we need to read the next sector
    c978  fe 80      CPI A, 80
    c97a  da 87 c9   JC CMD_TYPE_SKIP_READ (c987)

    c97d  e5         PUSH HL                        ; Read the next chunk of file
    c97e  cd fe c4   CALL READ_DEFAULT_FILE (c4fe)
    c981  e1         POP HL
    c982  c2 a0 c9   JNZ CMD_TYPE_EXIT (c9a0)

    c985  af         XRA A                          ; Reset the bytes counter
    c986  77         MOV M, A

CMD_TYPE_SKIP_READ:
    c987  34         INR M                          ; Increment the bytes counter

    c988  21 80 00   LXI HL, 0080                   ; Calculate next byte address (A is an offset in the
    c98b  cd 59 c6   CALL ADD_HL_A (c659)           ; sector buffer)

    c98e  7e         MOV A, M                       ; Stop printing if reached the end of file symbol
    c98f  fe 1a      CPI A, 1a
    c991  ca 86 cb   JZ CMD_EXIT_RESTORE_DISK (cb86)

    c994  cd 8c c4   CALL PUT_CHAR (c48c)           ; Print the character

    c997  cd c2 c5   CALL GET_CHAR (c5c2)           ; Check keyboard stop condition
    c99a  c2 86 cb   JNZ CMD_EXIT_RESTORE_DISK (cb86)

    c99d  c3 74 c9   JMP CMD_TYPE_LOOP (c974)       ; Advance to the next symbol

CMD_TYPE_EXIT:
    c9a0  3d         DCR A                          ; If BDOS read returns 1 this means end of file. Exit
    c9a1  ca 86 cb   JZ CMD_EXIT_RESTORE_DISK (cb86); normally

    c9a4  cd d9 c7   CALL PRINT_READ_ERROR (c7d9)   ; Other error codes indicate an error

CMD_TYPE_EXIT_WITH_ERROR:
    c9a7  cd 66 c8   CALL RESTORE_CURRENT_DISK (c866)
    c9aa  c3 09 c6   JMP BAD_COMMAND (c609)


; SAVE built-in command
;
; This command save specified number of pages (256 blocks) starting 0x0100 address to the specified file.
;
; Format:
; SAVE <num pages> <file name>
;
CMD_SAVE:
    c9ad  cd f8 c7   CALL PARSE_NUMBER (c7f8)   ; First argument must be a page number

    c9b0  f5         PUSH PSW                   ; Second argument is a file name
    c9b1  cd 5e c6   CALL PARSE_FILE_NAME (c65e)
    c9b4  c2 09 c6   JNZ BAD_COMMAND (c609)

    c9b7  cd 54 c8   CALL SELECT_COMMAND_DISK (c854)    ; Select the disk if needed

    c9ba  11 cd cb   LXI DE, FCB (cbcd)         ; If there is a file with the same name - delete it
    c9bd  d5         PUSH DE
    c9be  cd ef c4   CALL DELETE_FILE (c4ef)

    c9c1  d1         POP DE                     ; Create the file
    c9c2  cd 09 c5   CALL CREATE_FILE (c509)
    c9c5  ca fb c9   JZ PRINT_NO_SPACE_ERROR (c9fb)

    c9c8  af         XRA A                      ; Reset record counter (truncate the file)
    c9c9  32 ed cb   STA FCB+0x20 (cbed)

    c9cc  f1         POP PSW                    ; 1 page (256 bytes) = 2 sectors
    c9cd  6f         MOV L, A
    c9ce  26 00      MVI H, 00
    c9d0  29         DAD HL

    c9d1  11 00 01   LXI DE, 0100               ; Starting address

CMD_SAVE_LOOP:
    c9d4  7c         MOV A, H                   ; Exit when HL reaches zero
    c9d5  b5         ORA L
    c9d6  ca f1 c9   JZ CMD_SAVE_FINALIZE (c9f1)

    c9d9  2b         DCX HL                     ; Decrease counter
    c9da  e5         PUSH HL

    c9db  21 80 00   LXI HL, 0080               ; Advance pointer to the next record
    c9de  19         DAD DE
    c9df  e5         PUSH HL

    c9e0  cd d8 c5   CALL SET_DISK_BUFFER (c5d8); Set the calculated pointer as a data buffer to write

    c9e3  11 cd cb   LXI DE, FCB (cbcd)         ; Write the piece of memory
    c9e6  cd 04 c5   CALL WRITE_SEQUENTAL (c504)

    c9e9  d1         POP DE                     ; Check the error code
    c9ea  e1         POP HL
    c9eb  c2 fb c9   JNZ PRINT_NO_SPACE_ERROR (c9fb)

    c9ee  c3 d4 c9   JMP CMD_SAVE_LOOP (c9d4)   ; Repeat for the next sector

CMD_SAVE_FINALIZE:
    c9f1  11 cd cb   LXI DE, FCB (cbcd)         ; Close the file when done
    c9f4  cd da c4   CALL CLOSE_FILE (c4da)

    c9f7  3c         INR A                      ; 0xff indicate an error, otherwise exit normally
    c9f8  c2 01 ca   JNZ CMD_SAVE_EXIT (ca01)   

PRINT_NO_SPACE_ERROR:
    c9fb  01 07 ca   LXI BC, NO_SPACE_STR (ca07)
    c9fe  cd a7 c4   CALL PRINT_STR_FROM_NEW_LINE (c4a7)

CMD_SAVE_EXIT:
    ca01  cd d5 c5   CALL SET_DEFAULT_DISK_BUFFER (c5d5)
    ca04  c3 86 cb   JMP CMD_EXIT_RESTORE_DISK (cb86)

NO_SPACE_STR:
    ca07  4e 4f 20 53 50 41 43 45   db "NO SPACE"
    ca0f  00                        db 0x00


; REN builtin command
;
; This command renames a file on the drive
;
; Usage:
; REN <new_name>=<old_name>
CMD_REN:
    ca10  cd 5e c6   CALL PARSE_FILE_NAME (c65e)    ; Tokenize the parameter
    ca13  c2 09 c6   JNZ BAD_COMMAND (c609)

    ca16  3a f0 cb   LDA COMMAND_DISK (cbf0)    ; Select specified disk
    ca19  f5         PUSH PSW
    ca1a  cd 54 c8   CALL SELECT_COMMAND_DISK (c854)

    ca1d  cd e9 c4   CALL SEARCH_FIRST (c4e9)   ; Check if the destination file already exists
    ca20  c2 79 ca   JNZ PRINT_FILE_EXISTS_ERROR (ca79)

    ca23  21 cd cb   LXI HL, FCB (cbcd)         ; Move the desitnation file name to FCB + 0x10
    ca26  11 dd cb   LXI DE, FCB + 0x10 (cbdd)
    ca29  06 10      MVI B, 10
    ca2b  cd 42 c8   CALL MEMCOPY_HL_DE (c842)

    ca2e  2a 88 c4   LHLD COMMAND_BUF_PTR (c488); Get the parameter pointer
    ca31  eb         XCHG

    ca32  cd 4f c6   CALL SEARCH_NEXT_SYMBOL (c64f) ; Search for '=' symbol
    ca35  fe 3d      CPI A, 3d
    ca37  ca 3f ca   JZ CMD_REN_1 (ca3f)

    ca3a  fe 5f      CPI A, 5f                  ; '_' on some system is a left arrow, treat it same way as '='
    ca3c  c2 73 ca   JNZ CMD_REN_EXIT_ERROR (ca73)

CMD_REN_1:
    ca3f  eb         XCHG                       ; Symbols after '=' must be source file name
    ca40  23         INX HL
    ca41  22 88 c4   SHLD COMMAND_BUF_PTR (c488)

    ca44  cd 5e c6   CALL PARSE_FILE_NAME (c65e)    ; Parse the file name and put it to first half of FCB
    ca47  c2 73 ca   JNZ CMD_REN_EXIT_ERROR (ca73)

    ca4a  f1         POP PSW                    ; Save drive letter for later
    ca4b  47         MOV B, A

    ca4c  21 f0 cb   LXI HL, COMMAND_DISK (cbf0); Check if source file is on the default drive
    ca4f  7e         MOV A, M
    ca50  b7         ORA A
    ca51  ca 59 ca   JZ CMD_REN_2 (ca59)

    ca54  b8         CMP B                      ; Source and destination drives must be equal
    ca55  70         MOV M, B
    ca56  c2 73 ca   JNZ CMD_REN_EXIT_ERROR (ca73)

CMD_REN_2:
    ca59  70         MOV M, B

    ca5a  af         XRA A                      ; Clear the drive byte
    ca5b  32 cd cb   STA FCB (cbcd)

    ca5e  cd e9 c4   CALL SEARCH_FIRST (c4e9)   ; Search for the source file, indicate an error if file 
    ca61  ca 6d ca   JZ CMD_REN_FILE_NOT_FOUND (ca6d)   ; was not found

    ca64  11 cd cb   LXI DE, FCB (cbcd)             ; Actually rename the file
    ca67  cd 0e c5   CALL RENAME_FILE (c50e)

    ca6a  c3 86 cb   JMP CMD_EXIT_RESTORE_DISK (cb86)   ; Exit normally

CMD_REN_FILE_NOT_FOUND:
    ca6d  cd ea c7   CALL PRINT_NO_FILE_ERROR (c7ea)
    ca70  c3 86 cb   JMP CMD_EXIT_RESTORE_DISK (cb86)

CMD_REN_EXIT_ERROR:
    ca73  cd 66 c8   CALL RESTORE_CURRENT_DISK (c866)
    ca76  c3 09 c6   JMP BAD_COMMAND (c609)

PRINT_FILE_EXISTS_ERROR:
    ca79  01 82 ca   LXI BC, FILE_EXISTS_STR (ca82)
    ca7c  cd a7 c4   CALL PRINT_STR_FROM_NEW_LINE (c4a7)
    ca7f  c3 86 cb   JMP CMD_EXIT_RESTORE_DISK (cb86)

FILE_EXISTS_STR:
    ca82  46 49 4c 45 20 45 58 49   db  "FILE EXI"
    ca8a  53 54 53 00               db  "STS", 0x00s


; USER built-in command
;
; Select the active user (all commands will see only current user's files)
;
; Usage:
; USER <user number>
CMD_USER:
    ca8e  cd f8 c7   CALL PARSE_NUMBER (c7f8)   ; Parse the parameter

    ca91  fe 10      CPI A, 10                  ; Validate the input (user code is no more 16)
    ca93  d2 09 c6   JNC BAD_COMMAND (c609)

    ca96  5f         MOV E, A

    ca97  3a ce cb   LDA FCB+0x01 (cbce)        ; Check the code was really specified
    ca9a  fe 20      CPI A, 20
    ca9c  ca 09 c6   JZ BAD_COMMAND (c609)

    ca9f  cd 15 c5   CALL SET_USER_CODE (c515)  ; Set the provided code
    caa2  c3 89 cb   JMP CMD_EXIT (cb89)


; Execute non-built-in command (execute user program)
;
; This function runs the specified user program. The function performs the following steps:
; - Searches for the <program>.COM file
; - Loads the file at 0x0100 address
; - Parse first and second argument and put parsed result into default FCB area (0x005c). Arguments are
;   parsed for the application convenience (so that the app has not parse it). First argument is placed
;   into beginning of FCB, second argument into FCB + 0x10
; - All arguments as a string are copied to 0x0080 area, where the first byte is a number of bytes in the
;   buffer.
; - Run the program
; - Restore stack and disk
CMD_OTHER:
    caa5  cd f5 c5   CALL CHECK_SERIAL (c5f5)   ; Validate serial number

    caa8  3a ce cb   LDA FCB+0x01 (cbce)        ; Perhaps no command specified, but only drive selection
    caab  fe 20      CPI A, 20
    caad  c2 c4 ca   JNZ CMD_OTHER_1 (cac4)

    cab0  3a f0 cb   LDA COMMAND_DISK (cbf0)    ; If no disk and file specified - just exit
    cab3  b7         ORA A
    cab4  ca 89 cb   JZ CMD_EXIT (cb89)

    cab7  3d         DCR A                      ; This is drive selection command. Store disk as current
    cab8  32 ef cb   STA CURRENT_DISK (cbef)

    cabb  cd 29 c5   CALL STORE_CCP_DISK (c529) ; Select the disk, and exit
    cabe  cd bd c4   CALL SELECT_DISK (c4bd)
    cac1  c3 89 cb   JMP CMD_EXIT (cb89)

CMD_OTHER_1:
    cac4  11 d6 cb   LXI DE, FCB+0x09 (cbd6)    ; Here we will load and execute program
    cac7  1a         LDAX DE                    ; Commands shall not have extension (even default .COM)
    cac8  fe 20      CPI A, 20
    caca  c2 09 c6   JNZ BAD_COMMAND (c609)

    cacd  d5         PUSH DE                    ; Select the disk specified in the command
    cace  cd 54 c8   CALL SELECT_COMMAND_DISK (c854)

    cad1  d1         POP DE
    cad2  21 83 cb   LXI HL, COM_EXT (cb83)
    cad5  cd 40 c8   CALL MEMCOPY_3_BYTES_HL_DE (c840)

    cad8  cd d0 c4   CALL OPEN_FILE_RESET_POS (c4d0); Open the specified file
    cadb  ca 6b cb   JZ CMD_OTHER_EXIT_ERROR (cb6b)

    cade  21 00 01   LXI HL, 0100               ; Load the file starting 0x0100

CMD_OTHER_LOAD_LOOP:
    cae1  e5         PUSH HL                    ; Set the next chunk target address
    cae2  eb         XCHG
    cae3  cd d8 c5   CALL SET_DISK_BUFFER (c5d8)

    cae6  11 cd cb   LXI DE, FCB (cbcd)         ; Read the next chunk until the end of the file
    cae9  cd f9 c4   CALL READ_SEQUENTAL (c4f9)
    caec  c2 01 cb   JNZ CMD_OTHER_2 (cb01)

    caef  e1         POP HL                     ; Advance the address
    caf0  11 80 00   LXI DE, 0080
    caf3  19         DAD DE

    caf4  11 00 c4   LXI DE, c400               ; Do not let overwriting the CP/M (0xc400 and higher)

    caf7  7d         MOV A, L                   ; Check the address, and report an error if needed
    caf8  93         SUB E
    caf9  7c         MOV A, H
    cafa  9a         SBB D
    cafb  d2 71 cb   JNC PRINT_BAD_LOAD_ERROR (cb71)

    cafe  c3 e1 ca   JMP CMD_OTHER_LOAD_LOOP (cae1) ; Read the next sector

CMD_OTHER_2:
    cb01  e1         POP HL                     ; Read error code 1 means end of file, otherwise error
    cb02  3d         DCR A
    cb03  c2 71 cb   JNZ PRINT_BAD_LOAD_ERROR (cb71)

    cb06  cd 66 c8   CALL RESTORE_CURRENT_DISK (c866)   ; Restore the disk

    cb09  cd 5e c6   CALL PARSE_FILE_NAME (c65e)    ; Parse first argument

    cb0c  21 f0 cb   LXI HL, COMMAND_DISK (cbf0)    ; Get the disk name, and store it in the FCB
    cb0f  e5         PUSH HL
    cb10  7e         MOV A, M                   
    cb11  32 cd cb   STA FCB (cbcd)

    cb14  3e 10      MVI A, 10                      ; Parse second argument into upper part of FCB
    cb16  cd 60 c6   CALL PARSE_FILE_NAME_ADV (c660)

    cb19  e1         POP HL                         ; Put the disk code in the upper part of FCB
    cb1a  7e         MOV A, M
    cb1b  32 dd cb   STA FCB + 0x10 (cbdd)

    cb1e  af         XRA A                          ; Clear the record counter
    cb1f  32 ed cb   STA FCB+0x20 (cbed)

    cb22  11 5c 00   LXI DE, 005c                   ; Copy filled FCB into default FCB area (at 0x005c)
    cb25  21 cd cb   LXI HL, FCB (cbcd)
    cb28  06 21      MVI B, 21
    cb2a  cd 42 c8   CALL MEMCOPY_HL_DE (c842)

    cb2d  21 08 c4   LXI HL, COMMAND_DATA (c408)    ; Scan command and parameers for EOL or space

CMD_OTHER_ARG_SEARCH_LOOP:
    cb30  7e         MOV A, M                       ; Repeat until zero byte found
    cb31  b7         ORA A
    cb32  ca 3e cb   JZ CMD_OTHER_3 (cb3e)

    cb35  fe 20      CPI A, 20                      ; Or a space
    cb37  ca 3e cb   JZ CMD_OTHER_3 (cb3e)

    cb3a  23         INX HL
    cb3b  c3 30 cb   JMP CMD_OTHER_ARG_SEARCH_LOOP (cb30)

CMD_OTHER_3:
    cb3e  06 00      MVI B, 00                      ; Copy command to 0x0080 buffer, count chars in B
    cb40  11 81 00   LXI DE, 0081

CMD_OTHER_ARG_COPY_LOOP:
    cb43  7e         MOV A, M                       ; Copy char until zero byte is found
    cb44  12         STAX DE
    cb45  b7         ORA A
    cb46  ca 4f cb   JZ CMD_OTHER_4 (cb4f)

    cb49  04         INR B                          ; Advance to the next byte, count chars in B
    cb4a  23         INX HL
    cb4b  13         INX DE
    cb4c  c3 43 cb   JMP CMD_OTHER_ARG_COPY_LOOP (cb43)

CMD_OTHER_4:
    cb4f  78         MOV A, B                       ; Store number of chars in the copied buffer
    cb50  32 80 00   STA 0080

    cb53  cd 98 c4   CALL PRINT_CR_LF (c498)        ; Executed program will print data starting new line

    cb56  cd d5 c5   CALL SET_DEFAULT_DISK_BUFFER (c5d5)    ; Set the default disk buffer

    cb59  cd 1a c5   CALL STORE_CCP_USER_AND_DISK (c51a)    ; Remember user code and disk in case reboot

    cb5c  cd 00 01   CALL 0100                      ; Actually execute the loaded program

    cb5f  31 ab cb   LXI SP, CCP_STACK_TOP (cbab)   ; Restore CCP's stack
    
    cb62  cd 29 c5   CALL STORE_CCP_DISK (c529)     ; Restore disk state
    cb65  cd bd c4   CALL SELECT_DISK (c4bd)

    cb68  c3 82 c7   JMP MAIN_COMMAND_LOOP (c782)   ; Now we are ready to get new commands

CMD_OTHER_EXIT_ERROR:
    cb6b  cd 66 c8   CALL RESTORE_CURRENT_DISK (c866)
    cb6e  c3 09 c6   JMP BAD_COMMAND (c609)

PRINT_BAD_LOAD_ERROR:
    cb71  01 7a cb   LXI BC, BAD_LOAD_STR (cb7a)
    cb74  cd a7 c4   CALL PRINT_STR_FROM_NEW_LINE (c4a7)
    cb77  c3 86 cb   JMP CMD_EXIT_RESTORE_DISK (cb86)

BAD_LOAD_STR:
    cb7a  42 41 44 20 4c 4f 41 44   db  "BAD LOAD"
    cb82  00                        db  0x00

COM_EXT:
    cb83  43 4f 4d                  db "COM"



CMD_EXIT_RESTORE_DISK:
    cb86  cd 66 c8   CALL RESTORE_CURRENT_DISK (c866)

CMD_EXIT:
    cb89  cd 5e c6   CALL PARSE_FILE_NAME (c65e)    ; Check for garbage at the end of command line

    cb8c  3a ce cb   LDA FCB+0x01 (cbce)            ; If there is something else but spaces...
    cb8f  d6 20      SUI A, 20

    cb91  21 f0 cb   LXI HL, COMMAND_DISK (cbf0)    ; ... Or a disk specification - this is an error
    cb94  b6         ORA M
    cb95  c2 09 c6   JNZ BAD_COMMAND (c609)

    cb98  c3 82 c7   JMP MAIN_COMMAND_LOOP (c782)   ; Otherwise we are ready for the next command

CCP_STACK:
    cb9b  16 * 00       db 0x10 * 0x10          ; Stack area

CCP_STACK_TOP:

SUBST_FILE_PRESENT:
    cbab  00            db 00                   ; Flag indicating that substitution file is present

SUBST_FCB:                                      ; FCB for $$$.SUB substitution file
    cbac  00 24 24 24 20 20 20 20
    cbb4  20 53 55 42 00 00 00 00
    cbbc  00 00 00 00 00 00 00 00
    cbc4  00 00 00 00 00 00 00 00
    cbcc  00

FCB:                                            ; FCB for various file operations
    cbcd  0x31 * 00     db 0x31 * 00

BDOS_RESULT:
    cbee  00            db 00                   ; BDOS function return value

CURRENT_DISK:
    cbef  00            db 00                   ; Currently selected disk

COMMAND_DISK:
    cbf0  00            db 00                   ; Disk specified in the command (1 based), or 0 if not specified

TYPE_BYTE_COUNTER:
    cbf1  00            db 00                   ; Bytes counter for TYPE command

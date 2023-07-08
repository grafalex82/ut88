; SUBMIT is a program to run scripts on CP/M system. The program may schedule for execution a list of
; commands, that then processed by CCP and executed one by one. The SUBMIT application allows developing
; generic scripts, where exact arguments are substituted while submiting the script.
;
; Usage:
; SUBMIT <script> <arg1> <arg2> ... <argN>
;
; The program works in the following way:
; - Command line arguments are saved in ARG_BUFFER in order to free up 0x80-0xff area
; - Open the input script. It will be read byte-by-byte, and read from disk as needed
; - Input script is copied to output SUBST_BUF area:
;   - $<num> is substituted with an actual arg
;   - $$ is replaced with $
;   - ^<symb> is replaced with ctrl symbol in 0x01-0x1a range
; - Processing function counts processed line in order to report errors if needed.
; - Script with substituted variables is then stored in $$$.SUB. Lines are stored from last to first. Each
;   line is stored as a separate 128-byte record, and its format matches CCP internal structure
; - When the program finished, warm reboot is performed. CCP detects $$$.SUB file and starts executing
;   commands in it
FCB             equ 005c

START:
    0100  c3 df 01   JMP REAL_START (01df)

    0103  20 63 6f 70 79 72 69 67   db " copyrig"       ; Copyright string, not used in the code
    010b  68 74 28 63 29 20 31 39   db "ht(c) 19"
    0113  37 37 2c 20 64 69 67 69   db "77, digi"
    011b  74 61 6c 20 72 65 73 65   db "tal rese"
    0123  61 72 63 68 20            db "arch "

CR_LF_STR:
    0128  0d 0a 24                  db 0x0d, 0x0a, '$'

ERROR_ON_LINE_STR:
    012b  45 72 72 6f 72 20 4f 6e   db "Error On"
    0133  20 4c 69 6e 65 20 24      db " Line $"

SUB_EXT:
    013a  53 55 42          db "SUB"

NO_SUB_FILE_STR:
    013d  4e 6f 20 27 53 55 42 27   db "No 'SUB'"
    0145  20 46 69 6c 65 20 50 72   db " File Pr"
    014d  65 73 65 6e 74 24         db "esent$"

DISK_WRITE_ERROR_STR:
    0153  44 69 73 6b 20 57 72 69   db "Disk Wri"
    015b  74 65 20 45 72 72 6f 72   db "te Error"
    0163  24                        db "$"


COMMAND_BUF_OVERFLOW_STR:
    0164  43 6f 6d 6d 61 6e 64 20   db "Command "
    016c  42 75 66 66 65 72 20 4f   db "Buffer O"
    0174  76 65 72 66 6c 6f 77 24   db "verflow$"

COMMAND_TOO_LONG_STR:
    017c  43 6f 6d 6d 61 6e 64 20   db "Command "
    0184  54 6f 6f 20 4c 6f 6e 67   db "Too Long"
    018c  24                        db "$"

PARAMETER_ERROR_STR:
    018d  50 61 72 61 6d 65 74 65   db "Paramete"
    0195  72 20 45 72 72 6f 72 24   db "r Error$"

INVALID_CTL_CHAR_STR:
    019d  49 6e 76 61 6c 69 64 20   db "Invalid "
    01a5  43 6f 6e 74 72 6f 6c 20   db "Control "
    01ad  43 68 61 72 61 63 74 65   db "Characte"
    01b5  72 24                     db "r$"

DIRECTORY_FULL_STR:
    01b7  44 69 72 65 63 74 6f 72   db "Director"
    01bf  79 20 46 75 6c 6c 24      db "y Full$"

CLOSE_ERROR_STR:
    01c6  43 61 6e 6e 6f 74 20 43   db "Cannot C"
    01ce  6c 6f 73 65 2c 20 52 65   db "lose, Re"
    01d6  61 64 2f 4f 6e 6c 79 3f   db "ad/Only?"
    01de  24                        db "$"


REAL_START:
    01df  21 00 00   LXI HL, 0000               ; Save SP for some time
    01e2  39         DAD SP
    01e3  22 f0 05   SHLD SAVE_SP (05f0)

    01e6  21 93 0e   LXI HL, SUBMIT_STACK (0e93); Set own SP
    01e9  f9         SPHL

    01ea  cd cc 02   CALL INITIALIZE (02cc)
    01ed  cd 8a 03   CALL PROCESS_DATA (038a)
    01f0  cd fe 04   CALL WRITE_OUTPUT (04fe)
    01f3  cd 87 05   CALL RESET (0587)          ; Reset the system (CALL 0000)
    01f6  c9         RET


; Print a '$' terminated string
;
; Arguments: BC - pointer to the string
PRINT_STR:
    01f7  21 dd 05   LXI HL, PRINT_STR_ARG + 1 (05dd)   ; Store the BC argument in the variable
    01fa  70         MOV M, B
    01fb  2b         DCX HL
    01fc  71         MOV M, C

    01fd  2a dc 05   LHLD PRINT_STR_ARG (05dc)          ; Load the argument to DE
    0200  eb         XCHG

    0201  0e 09      MVI C, 09                          ; Call BDOS Print String function
    0203  cd 8a 05   CALL BDOS_NO_RET_VAL (058a)
    0206  c9         RET


; Open file
;
; Arguments: BC - pointer to FCB
OPEN_FILE:
    0207  21 e0 05   LXI HL, OPEN_FILE_ARG + 1 (05e0)   ; Store BC argument to the OPEN_FILE_ARG variable
    020a  70         MOV M, B
    020b  2b         DCX HL
    020c  71         MOV M, C

    020d  2a df 05   LHLD OPEN_FILE_ARG (05df)  ; Load arg back to DE (OMG)
    0210  eb         XCHG

    0211  0e 0f      MVI C, 0f                  ; Call BDOS open file functions
    0213  cd 8d 05   CALL BDOS (058d)

    0216  32 de 05   STA RET_VAL (05de)         ; Store return value in the variable
    0219  c9         RET


; Close file
;
; Argument: BC - pointer to FCB
CLOSE_FILE:
    021a  21 e2 05   LXI HL, CLOSE_FILE_ARG + 1 (05e2)  ; Store argument in the temporary variable
    021d  70         MOV M, B
    021e  2b         DCX HL
    021f  71         MOV M, C

    0220  2a e1 05   LHLD CLOSE_FILE_ARG (05e1) ; Load the argument back to DE
    0223  eb         XCHG

    0224  0e 10      MVI C, 10                  ; Call BDOS close file function
    0226  cd 8d 05   CALL BDOS (058d)

    0229  32 de 05   STA RET_VAL (05de)         ; Store return value in the variable
    022c  c9         RET


; Delete file
;
; Argument: BC - pointer to FCB
DELETE_FILE:
    022d  21 e4 05   LXI HL, DELETE_FILE_ARG + 1 (05e4) ; Store argument in a temporary variable
    0230  70         MOV M, B
    0231  2b         DCX HL
    0232  71         MOV M, C

    0233  2a e3 05   LHLD DELETE_FILE_ARG (05e3)    ; Load argument to DE
    0236  eb         XCHG

    0237  0e 13      MVI C, 13
    0239  cd 8a 05   CALL BDOS_NO_RET_VAL (058a)    ; Call BDOS delete file function

    023c  c9         RET


; Read file record
;
; Argument: BC - pointer to FCB
READ_FILE:
    023d  21 e6 05   LXI HL, READ_FILE_ARG + 1 (05e6)   ; Store argument in temporary variable
    0240  70         MOV M, B
    0241  2b         DCX HL
    0242  71         MOV M, C

    0243  2a e5 05   LHLD READ_FILE_ARG (05e5)  ; Restore argument to DE
    0246  eb         XCHG

    0247  0e 14      MVI C, 14                  ; Call BDOS read file function
    0249  cd 8d 05   CALL BDOS (058d)
    024c  c9         RET


; Write file record
;
; Argument: BC - pointer to FCB
WRITE_FILE:
    024d  21 e8 05   LXI HL, WRITE_FILE_ARG + 1 (05e8)  ; Store argument in a temporary variable 
    0250  70         MOV M, B
    0251  2b         DCX HL
    0252  71         MOV M, C

    0253  2a e7 05   LHLD WRITE_FILE_ARG (05e7) ; Restore argument to DE
    0256  eb         XCHG

    0257  0e 15      MVI C, 15                  ; Call BDOS write function
    0259  cd 8d 05   CALL BDOS (058d)

    025c  c9         RET


; Create file
;
; Argument: BC - pointer to FCB
CREATE_FILE:
    025d  21 ea 05   LXI HL, CREATE_FILE_ARG + 1 (05ea) ; Store argument in a temporary variable
    0260  70         MOV M, B
    0261  2b         DCX HL
    0262  71         MOV M, C

    0263  2a e9 05   LHLD CREATE_FILE_ARG (05e9)    ; Restore argument to DE
    0266  eb         XCHG

    0267  0e 16      MVI C, 16                      ; Call BDOS create file function
    0269  cd 8d 05   CALL BDOS (058d)

    026c  32 de 05   STA RET_VAL (05de)             ; Store return value in a variable
    026f  c9         RET


; Copy Memory
; 
; Arguments:
; E             - Number of bytes to copy
; BC            - pointer to destination
; arg on stack  - pointer to source
MEMCOPY:
    0270  21 ef 05   LXI HL, MEMCOPY_COUNT (05ef)   ; Store number of bytes argument
    0273  73         MOV M, E                   

    0274  2b         DCX HL                     ; Store destination address argument
    0275  70         MOV M, B
    0276  2b         DCX HL
    0277  71         MOV M, C

    0278  2b         DCX HL

    0279  d1         POP DE                     ; Temporary get save return address in DE

    027a  c1         POP BC                     ; Pop one more arg from the stack (source address)

    027b  70         MOV M, B                   ; And store it in the MEMCOPY_SRC variable
    027c  2b         DCX HL
    027d  71         MOV M, C

    027e  d5         PUSH DE                    ; Push return address back

MEMCOPY_LOOP:
    027f  3a ef 05   LDA MEMCOPY_COUNT (05ef)   ; Decrease counter, originally passed in E ????
    0282  3d         DCR A
    0283  32 ef 05   STA MEMCOPY_COUNT (05ef)

    0286  fe ff      CPI A, ff                  ; Stop if all bytes are copied
    0288  ca a6 02   JZ MEMCOPY_EXIT (02a6)

    028b  2a eb 05   LHLD MEMCOPY_SRC (05eb)    ; Source address -> BC
    028e  e5         PUSH HL
    028f  2a ed 05   LHLD MEMCOPY_DST (05ed)    ; Destination address -> HL
    0292  c1         POP BC

    0293  0a         LDAX BC                    ; Copy byte [Dst] <- [Src]
    0294  77         MOV M, A

    0295  2a eb 05   LHLD MEMCOPY_SRC (05eb)    ; Increment source address
    0298  23         INX HL
    0299  22 eb 05   SHLD MEMCOPY_SRC (05eb)

    029c  2a ed 05   LHLD MEMCOPY_DST (05ed)    ; Increment destination address
    029f  23         INX HL
    02a0  22 ed 05   SHLD MEMCOPY_DST (05ed)

    02a3  c3 7f 02   JMP MEMCOPY_LOOP (027f)

MEMCOPY_EXIT:
    02a6  c9         RET


; Report an error and exit
;
; The function prints a default error message, indicating line where error happened. Then
; the function prints the message provided as an argument, and finally exits the application
REPORT_ERROR:
    02a7  21 f3 05   LXI HL, REPORT_ERROR_ARG + 1 (05f3)    ; Save argument in a temporary variable
    02aa  70         MOV M, B
    02ab  2b         DCX HL
    02ac  71         MOV M, C

    02ad  01 28 01   LXI BC, CR_LF_STR (0128)           ; Print CR/LF
    02b0  cd f7 01   CALL PRINT_STR (01f7)

    02b3  01 2b 01   LXI BC, ERROR_ON_LINE_STR (012b)   ; Print error string
    02b6  cd f7 01   CALL PRINT_STR (01f7)

    02b9  01 b6 05   LXI BC, LINE_NUM_STR (05b6)        ; Supply error string with a line number
    02bc  cd f7 01   CALL PRINT_STR (01f7)

    02bf  2a f2 05   LHLD REPORT_ERROR_ARG (05f2)       ; Restore pointer to the argument
    02c2  44         MOV B, H
    02c3  4d         MOV C, L

    02c4  cd f7 01   CALL PRINT_STR (01f7)      ; Print string passed as an argument

    02c7  2a f0 05   LHLD SAVE_SP (05f0)        ; Restore original SP and return back to the OS
    02ca  f9         SPHL

    02cb  c9         RET


; Initialize the application:
; - Copy command line arguments to ARG_BUFFER
; - Open SUB file passed as a first argument (report error on failure)
INITIALIZE:
    02cc  01 81 00   LXI BC, 0081               ; Copy 0x7f bytes from arguments area to the arg buffer
    02cf  c5         PUSH BC
    02d0  1e 7f      MVI E, 7f
    02d2  01 f4 05   LXI BC, ARG_BUFFER (05f4)
    02d5  cd 70 02   CALL MEMCOPY (0270)

    02d8  2a 80 00   LHLD 0080                  ; Get number of bytes in the arguments area
    02db  26 00      MVI H, 00
    02dd  01 f4 05   LXI BC, ARG_BUFFER (05f4)  ; And add terminating zero at the arg buffer
    02e0  09         DAD BC                     ; (AKA convert pascal string to C string)
    02e1  36 00      MVI M, 00

    02e3  01 3a 01   LXI BC, SUB_EXT (013a)     ; Copy 'SUB' extension to argument file name in FCB area
    02e6  c5         PUSH BC
    02e7  1e 03      MVI E, 03
    02e9  01 65 00   LXI BC, FCB+0x09 (0065)
    02ec  cd 70 02   CALL MEMCOPY (0270)

    02ef  01 5c 00   LXI BC, FCB (005c)         ; Open the file
    02f2  cd 07 02   CALL OPEN_FILE (0207)

    02f5  3a de 05   LDA RET_VAL (05de)         ; Check result code
    02f8  fe ff      CPI A, ff
    02fa  c2 03 03   JNZ INITIALIZE_1 (0303)

    02fd  01 3d 01   LXI BC, NO_SUB_FILE_STR (013d)
    0300  cd a7 02   CALL REPORT_ERROR (02a7)

INITIALIZE_1:
    0303  21 74 06   LXI HL, SOURCE_OFFSET (0674)   ; Set the offset to 0x80 indicating a data needs to be read
    0306  36 80      MVI M, 80
    0308  c9         RET


; Read next character from the source file
;
; The function reads next character from the buffer. If all chars in the buffer were already read, the function
; reads the next sector of data from the source file. The function also maintain the lines counter to be 
; reported in case of errors.
READ_NEXT_CHAR:
    0309  3e 7f      MVI A, 7f                  ; Check if offset is over data sector size
    030b  21 74 06   LXI HL, SOURCE_OFFSET (0674)
    030e  be         CMP M
    030f  d2 25 03   JNC READ_NEXT_CHAR_2 (0325)

    0312  01 5c 00   LXI BC, FCB (005c)         ; If yes - read next sector
    0315  cd 3d 02   CALL READ_FILE (023d)

    0318  fe 00      CPI A, 00                  ; Check result
    031a  ca 20 03   JZ READ_NEXT_CHAR_1 (0320)

    031d  3e 1a      MVI A, 1a                  ; Indicate we are at end of file
    031f  c9         RET

READ_NEXT_CHAR_1:
    0320  21 74 06   LXI HL, SOURCE_OFFSET (0674)   ; Read was successfull - reset the offset variable
    0323  36 00      MVI M, 00

READ_NEXT_CHAR_2:
    0325  3a 74 06   LDA SOURCE_OFFSET (0674)   ; Increment the offset
    0328  3c         INR A
    0329  32 74 06   STA SOURCE_OFFSET (0674)

    032c  3d         DCR A                      ; Calculate the address in the buffer (HL = 0x0080 + offset)
    032d  4f         MOV C, A
    032e  06 00      MVI B, 00
    0330  21 80 00   LXI HL, 0080
    0333  09         DAD BC

    0334  7e         MOV A, M                   ; Read the next byte, store it in a variable  
    0335  32 75 06   STA NEXT_CHAR (0675)

    0338  fe 0d      CPI A, 0d                  ; Did we reach end of the line?
    033a  c2 62 03   JNZ READ_NEXT_CHAR_3 (0362)

    033d  3a b8 05   LDA LINE_NUM_STR + 2 (05b8); Increment the line number
    0340  3c         INR A
    0341  32 b8 05   STA LINE_NUM_STR + 2 (05b8)

    0344  4f         MOV C, A                   ; Did it overflow the lowest digit?
    0345  3e 39      MVI A, 39
    0347  b9         CMP C
    0348  d2 62 03   JNC READ_NEXT_CHAR_3 (0362)

    034b  21 b8 05   LXI HL, LINE_NUM_STR + 2 (05b8); Set lower digit to '0' and advance to the middle digit
    034e  36 30      MVI M, 30

    0350  2b         DCX HL                     ; Increment middle digit
    0351  7e         MOV A, M
    0352  3c         INR A
    0353  77         MOV M, A

    0354  4f         MOV C, A                   ; Check if it overflows middle digit
    0355  3e 39      MVI A, 39
    0357  b9         CMP C
    0358  d2 62 03   JNC READ_NEXT_CHAR_3 (0362)

    035b  21 b7 05   LXI HL, LINE_NUM_STR + 1 (05b7); Reset middle digit to '0'
    035e  36 30      MVI M, 30

    0360  2b         DCX HL                     ; and increment highest digit
    0361  34         INR M

READ_NEXT_CHAR_3:
    0362  3a 75 06   LDA NEXT_CHAR (0675)       ; Check if the loaded byte is a lower case letter
    0365  d6 61      SUI A, 61
    0367  fe 1a      CPI A, 1a
    0369  d2 74 03   JNC READ_NEXT_CHAR_4 (0374)

    036c  3a 75 06   LDA NEXT_CHAR (0675)       ; Make it upper case
    036f  e6 5f      ANI A, 5f
    0371  32 75 06   STA NEXT_CHAR (0675)

READ_NEXT_CHAR_4:
    0374  3a 75 06   LDA NEXT_CHAR (0675)       ; Return the read character
    0377  c9         RET


; Write next portion of the $$$.SUB file
WRITE_SUB_FILE:
    0378  01 bb 05   LXI BC, SUB_FILE_FCB (05bb); Write next sector of data
    037b  cd 4d 02   CALL WRITE_FILE (024d)

    037e  fe 00      CPI A, 00                  ; Check for error
    0380  ca 89 03   JZ WRITE_SUB_FILE_1 (0389)

    0383  01 53 01   LXI BC, DISK_WRITE_ERROR_STR (0153); Report error and exit
    0386  cd a7 02   CALL REPORT_ERROR (02a7)

WRITE_SUB_FILE_1:
    0389  c9         RET



; Process input data, and perform substitution
;
; The function reads input submit file character by character, and copy the data into output substitution
; buffer. The function handles a few special cases:
; - If $ symbol is found, the following cases possible:
;   - Double $$ is stored in output as a single $ symbol
;   - $<number> substitutes corresponding argument instead (the function iterates over command line arguments,
;     searches the argument with the specified number, and copies it to the output instead of $<number>
;   - all other char sequences that start with $ are invalid
; - ^<symb> are treated as a control character. Corresponding character with code 0x01-0x1a is stored in the
;   output instead
; - New line (0x0d) or end of file (0x1a) symbol triggers finalizing the line in the output:
;   - Line counter is incremented (used in case of a syntax error)
;   - after each line a 1-byte line length is added. The output will be processed in the reverse order, and
;     having a line length at the end of the line helps calculating the line start
PROCESS_DATA:
    038a  21 76 06   LXI HL, SUBST_BUF (0676)   ; Zero buffer byte
    038d  36 00      MVI M, 00

    038f  21 00 00   LXI HL, 0000               ; Zero substitution data length
    0392  22 76 0e   SHLD SUBST_LEN (0e76)

    0395  21 7c 0e   LXI HL, PROCESSING_IN_PROGRESS (0e7c)  ; Start the processing loop
    0398  36 01      MVI M, 01

PROCESS_DATA_LOOP:
    039a  3a 7c 0e   LDA PROCESSING_IN_PROGRESS (0e7c)  ; Repeat while processing flag is set
    039d  1f         RAR
    039e  d2 80 04   JNC PROCESS_DATA_EXIT (0480)

    03a1  21 78 0e   LXI HL, SUBST_LINE_LEN (0e78)  ; Zero the next line length
    03a4  36 00      MVI M, 00

PROCESS_DATA_NEXT_CHAR:
    03a6  cd 09 03   CALL READ_NEXT_CHAR (0309) ; Read the next input char
    03a9  32 7d 0e   STA PROCESS_DATA_CHAR (0e7d)

    03ac  d6 1a      SUI A, 1a                  ; Compare read byte with 0x1a (End of file)
    03ae  c6 ff      ADI A, ff                  
    03b0  9f         SBB A                      ; A=00 if byte is 0x1a, 0xff otherwise

    03b1  f5         PUSH PSW                   ; Temporary store it on stack

    03b2  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; Compare read byte with 0x0d (new line)
    03b5  d6 0d      SUI A, 0d
    03b7  c6 ff      ADI A, ff
    03b9  9f         SBB A                      ; A=00 if byte is 0x0d, 0xff otherwise                  

    03ba  c1         POP BC                     ; AND the two values above
    03bb  48         MOV C, B
    03bc  a1         ANA C

    03bd  1f         RAR                        ; Check the result
    03be  d2 6b 04   JNC PROCESS_DATA_EOL_EOF(046b) ; Jump if read byte is either EOF (0x1a) or EOL (0x0d)

    03c1  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; Skip 0x0a (go to the next byte)
    03c4  fe 0a      CPI A, 0a
    03c6  ca 68 04   JZ PROCESS_DATA_NEXT_CHAR_3 (0468)

    03c9  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; Check if read char is '$'
    03cc  fe 24      CPI A, 24
    03ce  c2 36 04   JNZ PROCESS_DATA_CTRL_CHAR (0436)  ; Process other chars elsewhere

    03d1  cd 09 03   CALL READ_NEXT_CHAR (0309) ; Read the character following after '$'
    03d4  32 7d 0e   STA PROCESS_DATA_CHAR (0e7d)

    03d7  fe 24      CPI A, 24                  ; Double '$$' means singe '$' in output
    03d9  c2 e6 03   JNZ PROCESS_DATA_1 (03e6)  ; Non-'$' second char is processed elsewhere

    03dc  2a 7d 0e   LHLD PROCESS_DATA_CHAR (0e7d)  ; Store the character in the output buffer
    03df  4d         MOV C, L
    03e0  cd c4 04   CALL STORE_SUBST_CHAR (04c4)

    03e3  c3 33 04   JMP PROCESS_DATA_NEXT_CHAR_1 (0433)    ; Go to the next symbol

PROCESS_DATA_1:
    03e6  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; Subtract 0x30 ('0') from the char
    03e9  d6 30      SUI A, 30
    03eb  32 7d 0e   STA PROCESS_DATA_CHAR (0e7d)

    03ee  4f         MOV C, A                   ; Check if it does not exceed 0-9 range
    03ef  3e 09      MVI A, 09
    03f1  b9         CMP C
    03f2  d2 fe 03   JNC PROCESS_DATA_2 (03fe)

    03f5  01 8d 01   LXI BC, PARAMETER_ERROR_STR (018d) ; If other character provided - report an error and exit
    03f8  cd a7 02   CALL REPORT_ERROR (02a7)

    03fb  c3 33 04   JMP PROCESS_DATA_NEXT_CHAR_1 (0433)

PROCESS_DATA_2:
    03fe  21 7a 0e   LXI HL, ARG_BUFFER_OFFSET (0e7a)   ; Start searching from the beginning of the arg line
    0401  36 00      MVI M, 00

    0403  cd ad 04   CALL SEARCH_NEXT_ARG (04ad)    ; Search for an argument start

PROCESS_DATA_SEARCH_ARG_LOOP:
    0406  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; Get the argument index, check if we reached the needed
    0409  fe 00      CPI A, 00                      ; aegument
    040b  ca 22 04   JZ PROCESS_DATA_COPY_ARG (0422)

    040e  21 7d 0e   LXI HL, PROCESS_DATA_CHAR (0e7d)   ; If not - decrease the argument index
    0411  35         DCR M

PROCESS_DATA_SEARCH_ARG_LOOP_1:
    0412  cd 81 04   CALL SEARCH_ARG_END (0481)     ; And search for the current argument end....
    0415  1f         RAR
    0416  d2 1c 04   JNC PROCESS_DATA_SEARCH_ARG_LOOP_2 (041c)

    0419  c3 12 04   JMP PROCESS_DATA_SEARCH_ARG_LOOP_1 (0412)

PROCESS_DATA_SEARCH_ARG_LOOP_2:
    041c  cd ad 04   CALL SEARCH_NEXT_ARG (04ad)    ; ... and then to the next argument start

    041f  c3 06 04   JMP PROCESS_DATA_SEARCH_ARG_LOOP (0406)

PROCESS_DATA_COPY_ARG:
    0422  cd 81 04   CALL SEARCH_ARG_END (0481)     ; Copy the argument char-by-char...
    0425  1f         RAR                            
    0426  d2 33 04   JNC PROCESS_DATA_NEXT_CHAR_1 (0433)

    0429  2a 79 0e   LHLD SEARCH_ARG_END_CHAR (0e79); ... and store it in a substitution buffer
    042c  4d         MOV C, L
    042d  cd c4 04   CALL STORE_SUBST_CHAR (04c4)

    0430  c3 22 04   JMP PROCESS_DATA_COPY_ARG (0422)

PROCESS_DATA_NEXT_CHAR_1:
    0433  c3 68 04   JMP PROCESS_DATA_NEXT_CHAR_3 (0468)

PROCESS_DATA_CTRL_CHAR:
    0436  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; Check if read character is '^'
    0439  fe 5e      CPI A, 5e
    043b  c2 61 04   JNZ PROCESS_DATA_NORMAL_CHAR (0461); Process other characters elsewhere

    043e  cd 09 03   CALL READ_NEXT_CHAR (0309) ; Read next char, treating this as Ctrl-symb
    0441  d6 61      SUI A, 61
    0443  32 7d 0e   STA PROCESS_DATA_CHAR (0e7d)

    0446  4f         MOV C, A                   ; Allow only lower case lating chars
    0447  3e 19      MVI A, 19
    0449  b9         CMP C
    044a  d2 56 04   JNC PROCESS_DATA_CTRL_CHAR_1 (0456)

    044d  01 9d 01   LXI BC, INVALID_CTL_CHAR_STR (019d)    ; Otherwise report error
    0450  cd a7 02   CALL REPORT_ERROR (02a7)

    0453  c3 5e 04   JMP PROCESS_DATA_NEXT_CHAR_2 (045e)

PROCESS_DATA_CTRL_CHAR_1:
    0456  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; Store the char in the output
    0459  3c         INR A
    045a  4f         MOV C, A
    045b  cd c4 04   CALL STORE_SUBST_CHAR (04c4)

PROCESS_DATA_NEXT_CHAR_2:
    045e  c3 68 04   JMP PROCESS_DATA_NEXT_CHAR_3 (0468)

PROCESS_DATA_NORMAL_CHAR:
    0461  2a 7d 0e   LHLD PROCESS_DATA_CHAR (0e7d)  ; Other chars are simply stored to the buffer
    0464  4d         MOV C, L
    0465  cd c4 04   CALL STORE_SUBST_CHAR (04c4)

PROCESS_DATA_NEXT_CHAR_3:
    0468  c3 a6 03   JMP PROCESS_DATA_NEXT_CHAR (03a6)

PROCESS_DATA_EOL_EOF:
    046b  3a 7d 0e   LDA PROCESS_DATA_CHAR (0e7d)   ; If char == 0x0d: processing = True
    046e  d6 0d      SUI A, 0d                      ; If char == 0x1a: processing = False (in other words stop
    0470  d6 01      SUI A, 01                      ; processing on end of file)
    0472  9f         SBB A
    0473  32 7c 0e   STA PROCESSING_IN_PROGRESS (0e7c)

    0476  2a 78 0e   LHLD SUBST_LINE_LEN (0e78) ; Store line length at the end of the data line
    0479  4d         MOV C, L
    047a  cd c4 04   CALL STORE_SUBST_CHAR (04c4)

    047d  c3 9a 03   JMP PROCESS_DATA_LOOP (039a)   ; Repeat the loop

PROCESS_DATA_EXIT:
    0480  c9         RET                        ; Exit when no more data to process



; Search for a space or EOL in the argument buffer (literally end of the currently parsed parameter)
; Return 1 if the current character is still a non-space character, advance to the next char.
; Return 0 if the end of the parameter reached (space or EOL)
SEARCH_ARG_END:
    0481  2a 7a 0e   LHLD ARG_BUFFER_OFFSET (0e7a)  ; Get offset in the argument buffer
    0484  26 00      MVI H, 00

    0486  01 f4 05   LXI BC, ARG_BUFFER (05f4)  ; Calc the address in the argument buffer
    0489  09         DAD BC

    048a  7e         MOV A, M                   ; Load argument char from the buffer
    048b  32 79 0e   STA SEARCH_ARG_END_CHAR (0e79)

    048e  d6 20      SUI A, 20                  ; A=ff if char is 0x20, A=00 otherwise
    0490  d6 01      SUI A, 01
    0492  9f         SBB A
    0493  f5         PUSH PSW

    0494  3a 79 0e   LDA SEARCH_ARG_END_CHAR (0e79) ; A=ff if char is 0x00, A=00 otherwise
    0497  d6 00      SUI A, 00
    0499  d6 01      SUI A, 01
    049b  9f         SBB A

    049c  c1         POP BC                     ; OR the two conditions above
    049d  48         MOV C, B
    049e  b1         ORA C

    049f  1f         RAR
    04a0  da aa 04   JC SEARCH_ARG_END_1 (04aa) ; Jump if char is a space or end of the line

    04a3  21 7a 0e   LXI HL, ARG_BUFFER_OFFSET (0e7a)   ; Advance to the next char
    04a6  34         INR M

    04a7  3e 01      MVI A, 01                  ; Return True
    04a9  c9         RET

SEARCH_ARG_END_1:
    04aa  3e 00      MVI A, 00                  ; Return False if char is a space or end of the line
    04ac  c9         RET


; Search for a non-space character in the argument buffer.
; Search is performed in the argument buffer, pointed with a ARG_BUFFER_OFFSET
SEARCH_NEXT_ARG:
    04ad  2a 7a 0e   LHLD ARG_BUFFER_OFFSET (0e7a)
    04b0  26 00      MVI H, 00

    04b2  01 f4 05   LXI BC, ARG_BUFFER (05f4)
    04b5  09         DAD BC

    04b6  7e         MOV A, M
    04b7  fe 20      CPI A, 20
    04b9  c2 c3 04   JNZ SEARCH_NEXT_ARG_1 (04c3)

    04bc  21 7a 0e   LXI HL, ARG_BUFFER_OFFSET (0e7a)
    04bf  34         INR M

    04c0  c3 ad 04   JMP SEARCH_NEXT_ARG (04ad)

SEARCH_NEXT_ARG_1:
    04c3  c9         RET


; Store a symbol in the output substutition buffer.
; The function updates internal counters, and checks
; - total size of data in the output buffer does not exceed 0x7ff bytes (2k)
; - length of each individual line does not exceed 0x7d bytes
STORE_SUBST_CHAR:
    04c4  21 7b 0e   LXI HL, STORE_SUBST_SYMB (0e7b); Save char in a temporary variable
    04c7  71         MOV M, C

    04c8  2a 76 0e   LHLD SUBST_LEN (0e76)      ; Increment substitution string length
    04cb  23         INX HL
    04cc  22 76 0e   SHLD SUBST_LEN (0e76)

    04cf  11 ff 07   LXI DE, 07ff               ; Check the accumulated data length
    04d2  cd 99 05   CALL SUB_DE_HL (0599)
    04d5  d2 de 04   JNC STORE_SUBST_CHAR_1 (04de)

    04d8  01 64 01   LXI BC, COMMAND_BUF_OVERFLOW_STR (0164)    ; Report error if the string is too long
    04db  cd a7 02   CALL REPORT_ERROR (02a7)

STORE_SUBST_CHAR_1:
    04de  2a 76 0e   LHLD SUBST_LEN (0e76)      ; Calculate address where to store the byte
    04e1  01 76 06   LXI BC, SUBST_BUF (0676)
    04e4  09         DAD BC

    04e5  3a 7b 0e   LDA STORE_SUBST_SYMB (0e7b); Store the symbol in the substitution buffer
    04e8  77         MOV M, A                   

    04e9  3a 78 0e   LDA SUBST_LINE_LEN (0e78)  ; Increment current line length
    04ec  3c         INR A
    04ed  32 78 0e   STA SUBST_LINE_LEN (0e78)

    04f0  4f         MOV C, A                   ; Check if single line exceeds 0x7d symbols
    04f1  3e 7d      MVI A, 7d
    04f3  b9         CMP C
    04f4  d2 fd 04   JNC STORE_SUBST_CHAR_2 (04fd)

    04f7  01 7c 01   LXI BC, COMMAND_TOO_LONG_STR (017c)    ; Report error if the command is too long
    04fa  cd a7 02   CALL REPORT_ERROR (02a7)

STORE_SUBST_CHAR_2:
    04fd  c9         RET


; Write data to the output $$$.SUB file
;
; The function writes lines collected in the SUBST_BUF buffer into $$$.SUB file. Lines are written in the
; reverse order (last to first), one line per file record. Each record has the following format:
; - number of bytes in the line
; - bytes of the line
; - terminating zero
; - '$' symbol
; Total size of the record must not exceed 128 bytes (one sector)
WRITE_OUTPUT:
    04fe  01 bb 05   LXI BC, SUB_FILE_FCB (05bb)    ; Delete previous submit file
    0501  cd 2d 02   CALL DELETE_FILE (022d)

    0504  21 db 05   LXI HL, SUB_FILE_FCB + 0x20 (05db) ; Reset record counter
    0507  36 00      MVI M, 00

    0509  01 bb 05   LXI BC, SUB_FILE_FCB (05bb)    ; Create new submit file
    050c  cd 5d 02   CALL CREATE_FILE (025d)

    050f  3a de 05   LDA RET_VAL (05de)             ; Check if the file created successfully
    0512  fe ff      CPI A, ff
    0514  c2 1d 05   JNZ WRITE_OUTPUT_NEXT_REC (051d)

    0517  01 b7 01   LXI BC, DIRECTORY_FULL_STR (01b7)  ; Report Directory full error, and exit
    051a  cd a7 02   CALL REPORT_ERROR (02a7)

WRITE_OUTPUT_NEXT_REC:
    051d  cd 7a 05   CALL READ_LAST_CHAR (057a)     ; Pop the last char (expect it has the size of the line)
    0520  32 7e 0e   STA WRITE_OUTPUT_CHAR (0e7e)

    0523  fe 00      CPI A, 00                      ; Check if the read byte is zero, which is the marker
    0525  ca 65 05   JZ WRITE_OUTPUT_CLOSE (0565)   ; of the last line

    0528  3a 7e 0e   LDA WRITE_OUTPUT_CHAR (0e7e)   ; Store line size in the first byte of the output buffer
    052b  32 80 00   STA 0080

    052e  4f         MOV C, A                       ; Calculate address of the last char in the output buffer    
    052f  06 00      MVI B, 00
    0531  21 81 00   LXI HL, 0081
    0534  09         DAD BC
 
    0535  36 00      MVI M, 00                      ; Put terminating zero

    0537  2a 7e 0e   LHLD WRITE_OUTPUT_CHAR (0e7e)  ; Calculate address of the pre-last char in the output buffer
    053a  26 00      MVI H, 00
    053c  01 82 00   LXI BC, 0082
    053f  09         DAD BC

    0540  36 24      MVI M, 24                      ; And store '$' sign

WRITE_OUTPUT_LOOP:
    0542  3e 00      MVI A, 00                      ; Check if char counter reached zero
    0544  21 7e 0e   LXI HL, WRITE_OUTPUT_CHAR (0e7e)
    0547  be         CMP M
    0548  d2 5f 05   JNC WRITE_OUTPUT_3 (055f)

    054b  cd 7a 05   CALL READ_LAST_CHAR (057a)     ; Pop the last character

    054e  2a 7e 0e   LHLD WRITE_OUTPUT_CHAR (0e7e)  ; Calculate its place in the output buffer
    0551  26 00      MVI H, 00
    0553  01 80 00   LXI BC, 0080
    0556  09         DAD BC

    0557  77         MOV M, A                       ; Store the character

    0558  21 7e 0e   LXI HL, WRITE_OUTPUT_CHAR (0e7e)   ; Decrease the counter
    055b  35         DCR M

    055c  c3 42 05   JMP WRITE_OUTPUT_LOOP (0542)   ; And repeat for the next char

WRITE_OUTPUT_3:
    055f  cd 78 03   CALL WRITE_SUB_FILE (0378)     ; When all chars in the line are copied - write them into
    0562  c3 1d 05   JMP WRITE_OUTPUT_NEXT_REC (051d)  ; $$$.SUB file

WRITE_OUTPUT_CLOSE:
    0565  01 bb 05   LXI BC, SUB_FILE_FCB (05bb)    ; Close the file
    0568  cd 1a 02   CALL CLOSE_FILE (021a)

    056b  3a de 05   LDA RET_VAL (05de)             ; Check if close was successful
    056e  fe ff      CPI A, ff
    0570  c2 79 05   JNZ WRITE_OUTPUT_EXIT (0579)

    0573  01 c6 01   LXI BC, CLOSE_ERROR_STR (01c6) ; Report Close error message, and exit
    0576  cd a7 02   CALL REPORT_ERROR (02a7)

WRITE_OUTPUT_EXIT:
    0579  c9         RET                            ; Exit normally



; Pop the last character in the substitution buffer, decrease buffer size
READ_LAST_CHAR:
    057a  2a 76 0e   LHLD SUBST_LEN (0e76)      ; Descrease data length counter
    057d  2b         DCX HL
    057e  22 76 0e   SHLD SUBST_LEN (0e76)

    0581  01 76 06   LXI BC, SUBST_BUF (0676)   ; Calculate the last byte address
    0584  09         DAD BC

    0585  7e         MOV A, M                   ; Read the last byte
    0586  c9         RET



RESET:
    0587  c3 00 00   JMP 0000

BDOS_NO_RET_VAL:
    058a  c3 05 00   JMP 0005

BDOS:
    058d  c3 05 00   JMP 0005

; Garbage
    0590  cd 05 00   CALL 0005
    0593  c9         RET
    0594  c9         RET
    0595  c9         RET
    0596  5f         MOV E, A
    0597  16 00      MVI D, 00


SUB_DE_HL:
    0599  7b         MOV A, E                   ; HL = DE - HL
    059a  95         SUB L
    059b  6f         MOV L, A

    059c  7a         MOV A, D
    059d  9c         SBB H
    059e  67         MOV H, A

    059f  c9         RET


LINE_NUM_STR:
    05b6  30 30 31 20 24            db "001 $"  ; String to identify line number where error occurred

SUB_FILE_FCB:
    05bb  00 24 24 24 20 20 20 20   db 0x00, "$$$    "      ; FCB pointing to $$$.SUB (at some garbage
    05c3  20 53 55 42 00 00 00 1a   db " SUB", 0x00, 0x00, 0x00, 0x00   ; at the end)
    05cb  1a 1a 1a 1a 1a 1a 1a 1a   
    05d3  1a 1a 1a 1a 1a 1a 1a 1a
    05db  1a

PRINT_STR_ARG:
    05dc  1a 1a         dw 0000                 ; Print String function argument (local variable)

RET_VAL:
    05de  1a            db 00                   ; Return value of BDOS functions

OPEN_FILE_ARG:
    05df  1a 1a         dw 0000                 ; Open file argument (local variable)

CLOSE_FILE_ARG:
    05e1  1a 1a         dw 0000                 ; Close file argument (local variable)
    
DELETE_FILE_ARG:
    05e3  1a 1a         dw 0000                 ; Delete file argument (local variable)
    
READ_FILE_ARG:
    05e5  1a 1a         dw 0000                 ; Read file argument (local variable)

WRITE_FILE_ARG:
    05e7  1a 1a         dw 0000                 ; Write file argument (local variable)

CREATE_FILE_ARG:
    05e9  1a 1a         dw 0000                 ; Write file argument (local variable)

MEMCOPY_SRC:
    05eb  1a 1a         db 0000                 ; Source address for MEMCOPY function (local variable)

MEMCOPY_DST:
    05ed  1a 1a         db 0000                 ; Destination address for MEMCOPY function (local variable)

MEMCOPY_COUNT:
    05ef  1a            db 00                   ; number of bytes to copy in MEMCOPY function (local variable)

SAVE_SP:
    05f0  1a 1a         dw 0000                 ; Temprary SP storage

REPORT_ERROR_ARG:
    05f2  1a 1a         dw 0000                 ; Argument of REPORT_ERROR function (klocal variable)

ARG_BUFFER:
    05f4  0x80 * [00]                           ; Command line arguments

SOURCE_OFFSET:
    0674   00       db 00                       ; Offset in the currently parsed data sector of the input file

NEXT_CHAR:
    0675   00       db 00                       ; Next read character (local variable for READ_NEXT_CHAR function)

SUBST_BUF:
    0676   2048 * [00]                          ; Buffer for substitution

SUBST_LEN:
    0e76   00 00        dw 0000                 ; Length of the data in the substitution buffer

SUBST_LINE_LEN:
    0e78   00           db 00                   ; Lenght of the current line in the substitution buffer

SEARCH_ARG_END_CHAR:
    0e79   00           db 00                   ; Currently processed char in SEARCH_ARG_END function (local var)

ARG_BUFFER_OFFSET:
    0e7a   00           db 00                   ; Offest in the arguments buffer

STORE_SUBST_SYMB:
    0e7b   00           db 00                   ; Symbol to be stored in the substutution buffer

PROCESSING_IN_PROGRESS:
    0e7c   00           db 00                   ; Flag indicating that processing the input data is in progress

PROCESS_DATA_CHAR:
    0e7d   00           db 00                   ; Currently processing character in PROCESS_DATA function

WRITE_OUTPUT_CHAR:
    0e7e   00           db 00                   ; Currently processing character in WRITE_OUTPUT function


    0e7f   20 * [00]                            ; Stack area (10 words)
SUBMIT_STACK:
    0e93   00           db 00                   ; Stack area (here and above)
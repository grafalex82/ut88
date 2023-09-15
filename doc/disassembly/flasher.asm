; This program is a flashing utility for 573RF2 and 573RF5 2k ROM chips (both are claimed as Intel 2716 analogs).
; The flasher allows writing and reading ROM chips using a simple i8255 based device. The i8255 ports are 
; connected as follows:
; - Port A - data input and output
; - Port B - low byte of the address
; - Port C - high byte of the address (lowest 6 bits). bits 6 and 7 of Port C are connected to OE and CE pins of
;            the ROM respectively.
;
; Note that schematic published in the magazine has OE and CE lines interchanged, so the flasher may not be
; working properly.
;
; On start the program shows the User a main menu with the following options:
; - R - read entire ROM (2k) to the RAM at address provided by the User
; - W - write entire ROM (2k) from the RAM address provided by the User. The user shall turn on +25V high voltage
;       line when requested by the program, and switch it off after.
; - E - exit to the Monitor
;
; Surprisingly, the code has a few unused functions. Looks like this is a leftover from a bigger set of functions,
; that were removed from the binary while porting to UT-88.
;
; Variables:
; 0568 - Pointer in the line buffer indicating next symbol to parse
; 056a - Line buffer address

START:
    0100  3e 90      MVI A, 90                  ; Out Control Word (I/O mode, Port A - input mode 0, Ports B and C
    0102  d3 fb      OUT fb                     ; - output)

    0104  3e c0      MVI A, c0                  ; Deselect target ROM (bits 6 and 7 of Port C are connected to OE 
    0106  d3 fa      OUT fa                     ; and CE pins of the ROM respectively)

MAIN_MENU:
    0108  21 d6 03   LXI HL, PROMPT_STR (03d6)  ; Print the main menu and prompt
    010b  cd 8d 03   CALL PRINT_STR (038d)

    010e  cd 3c 02   CALL INPUT_LINE (023c)     ; Input the mode command
    0111  cd 78 03   CALL PRINT_CR_LF (0378)

    0114  21 6a 05   LXI HL, LINE_BUFFER (056a) ; Initialize current pointer
    0117  22 68 05   SHLD NEXT_BUF_CHAR (0568)

    011a  cd 93 02   CALL CHECK_BUF_CHAR (0293) ; Check the entered command char

    011d  fe 00      CPI A, 00                  ; A space will restart the prompt
    011f  ca 08 01   JZ MAIN_MENU (0108)

    0122  79         MOV A, C                   ; Check the command

    0123  fe 52      CPI A, 52                  ; Is this a 'R' (Read the ROM)?
    0125  ca 48 01   JZ READ_ROM (0148)

    0128  fe 57      CPI A, 57                  ; Is this a 'W' (Write the ROM)?
    012a  ca 8c 01   JZ WRITE_ROM (018c)

    012d  fe 43      CPI A, 43                  ; Is this a 'C'? Perhaps not implemented, reset
    012f  ca 00 00   JZ 0000

    0132  fe 50      CPI A, 50                  ; Is this a 'P'? Perhaps not implemented, reset
    0134  ca 00 00   JZ 0000

    0137  fe 45      CPI A, 45                  ; Is this a 'E'? Restart the Monitor
    0139  ca 00 f8   JZ f800

    013c  21 62 04   LXI HL, ERROR_STR (0462)   ; Print the error string in case of invalid input
    013f  cd 8d 03   CALL PRINT_STR (038d)

    0142  cd 24 02   CALL LONG_PAUSE (0224)     ; Make a pause

    0145  c3 08 01   JMP MAIN_MENU (0108)       ; Rester the main menu


; Read the ROM
;
; Algorithm:
; - Read the target RAM address
; - Read 0x0800 bytes (2k) of data from ROM starting the address 0x0000
;   - Read the byte using READ_ROM_BYTE function
;   - Store received byte at the target RAM address
;   - Advance to the next byte
; - Calculate and print CRC of the read data
READ_ROM:
    0148  3e 90      MVI A, 90                  ; Reset the 8255 configuration: Port A as input (data), Ports
    014a  d3 fb      OUT fb                     ; B and C output (address and control lines)

READ_ROM_1:
    014c  21 c6 04   LXI HL, READ_MODE_STR (04c6)   ; Print the read mode prompt
    014f  cd 8d 03   CALL PRINT_STR (038d)

    0152  cd 3c 02   CALL INPUT_LINE (023c)     ; Enter the target address

    0155  21 6a 05   LXI HL, LINE_BUFFER (056a) ; Initialize buffer pointer
    0158  22 68 05   SHLD NEXT_BUF_CHAR (0568)

    015b  cd 0d 03   CALL HEX_STR_TO_INT (030d) ; Convert entered address string to int value

    015e  3d         DCR A                      ; Check whether string parsed successfully, otherwise restart input
    015f  c2 4c 01   JNZ READ_ROM_1 (014c)

    0162  e5         PUSH HL                    
    0163  11 00 00   LXI DE, 0000               ; Set starting ROM address to zero
    0166  01 00 08   LXI BC, 0800               ; Will read 2k of data

READ_ROM_LOOP:
    0169  cd 15 02   CALL READ_ROM_BYTE (0215)  ; Read

    016c  77         MOV M, A                   ; Store the read byte to the buffer, advance to the next address
    016d  13         INX DE
    016e  23         INX HL

    016f  0b         DCX BC                     ; Decrement bytes counter, and repeat until the counter is zero
    0170  78         MOV A, B
    0171  b1         ORA C
    0172  c2 69 01   JNZ READ_ROM_LOOP (0169)

    0175  d1         POP DE                     ; DE = start RAM address, HL - end RAM address
    0176  2b         DCX HL
    0177  eb         XCHG

    0178  cd 9f 03   CALL CALC_CRC (039f)       ; Calculate CRC

    017b  c5         PUSH BC                    ; Print new line
    017c  cd 78 03   CALL PRINT_CR_LF (0378)
    017f  e1         POP HL

    0180  cd 6d 03   CALL PRINT_HL_HEX (036d)   ; Print CRC
    0183  cd 78 03   CALL PRINT_CR_LF (0378)

    0186  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for the user's confirmation

    0189  c3 08 01   JMP MAIN_MENU (0108)       ; Restart the program


; Write ROM
;
; Algorithm:
; - Input source RAM address
; - Ask the user to enable high voltage
; - Write and verify 0x800 (2k) bytes of data starting ROM address 0x0000
;   - Write the byte
;     - Configure port A as output
;     - Set the address lines
;     - Output the data byte
;     - Strobe the CE line for 50ms, while keeping OE line high
;   - Verify the byte
;     - Configure Port A as input
;     - Set the address lines
;     - Set OE and CE lines low
;     - Read and verify the data byte
WRITE_ROM:
    018c  21 06 05   LXI HL, WRITE_MODE_STR (0506)  ; Print the mode string
    018f  cd 8d 03   CALL PRINT_STR (038d)

    0192  cd 3c 02   CALL INPUT_LINE (023c)     ; Input source RAM address

    0195  21 6a 05   LXI HL, LINE_BUFFER (056a) ; Initialize line buffer pointer for parsing
    0198  22 68 05   SHLD NEXT_BUF_CHAR (0568)

    019b  cd 0d 03   CALL HEX_STR_TO_INT (030d) ; Parse the RAM address, restart the input in case of failure
    019e  3d         DCR A
    019f  c2 8c 01   JNZ WRITE_ROM (018c)

    01a2  e5         PUSH HL                    ; Reconfigure port so that Port A (data) now is an output
    01a3  3e 80      MVI A, 80
    01a5  d3 fb      OUT fb

    01a7  3e 0d      MVI A, 0d                  ; Set ROM's OE pin high for now
    01a9  d3 fb      OUT fb

    01ab  21 7f 04   LXI HL, ENABLE_HIGH_VOLTAGE_STR (047f) ; Ask the User to enable high voltage
    01ae  cd 8d 03   CALL PRINT_STR (038d)

    01b1  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for a confirmation
    01b4  cd 78 03   CALL PRINT_CR_LF (0378)

    01b7  11 00 00   LXI DE, 0000               ; Set the ROM starting address
    01ba  01 00 08   LXI BC, 0800               ; Will write 2k of data
    01bd  e1         POP HL

WRITE_ROM_LOOP:
    01be  7e         MOV A, M                   ; Set the data byte on the Port A
    01bf  d3 f8      OUT f8

    01c1  7b         MOV A, E                   ; Set the address low byte on Port B
    01c2  d3 f9      OUT f9

    01c4  7a         MOV A, D                   ; Set the address high byte, but keep the OE ROM line high
    01c5  ee 40      XRI A, 40
    01c7  d3 fa      OUT fa

    01c9  3e 0f      MVI A, 0f                  ; Set ROM's CE line high - make the write strobe
    01cb  d3 fb      OUT fb

    01cd  cd 30 02   CALL PAUSE (0230)          ; Make a 50 ms pause, letting the values to settle

    01d0  3e 0e      MVI A, 0e                  ; Set ROM's CE line low
    01d2  d3 fb      OUT fb

    01d4  3e 90      MVI A, 90                  ; Reset port A configuration, allowing it read again
    01d6  d3 fb      OUT fb

    01d8  7b         MOV A, E                   ; Set the address low byte
    01d9  d3 f9      OUT f9

    01db  7a         MOV A, D                   ; Set the address high byte (setting CE and OE lines low)
    01dc  d3 fa      OUT fa

    01de  db f8      IN f8                      ; Read data from Port A

    01e0  be         CMP M                      ; Verify the data is written
    01e1  ca f9 01   JZ WRITE_ROM_NEXT (01f9)

    01e4  c5         PUSH BC                    ; In case of verification failue, print the '#' symbol
    01e5  0e 23      MVI C, 23
    01e7  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    01ea  cd 78 03   CALL PRINT_CR_LF (0378)    ; New line

    01ed  c1         POP BC                     ; Set Port A to output again
    01ee  3e 80      MVI A, 80
    01f0  d3 fb      OUT fb

    01f2  3e 0d      MVI A, 0d                  ; Set ROM's CE line high
    01f4  d3 fb      OUT fb

    01f6  c3 be 01   JMP WRITE_ROM_LOOP (01be)  ; Restart writing a byte

WRITE_ROM_NEXT:
    01f9  23         INX HL                     ; Advance to the next address
    01fa  13         INX DE

    01fb  0b         DCX BC                     ; Decrement remaining bytes counter

    01fc  3e 80      MVI A, 80                  ; Set Port A to output
    01fe  d3 fb      OUT fb

    0200  3e 0d      MVI A, 0d                  ; Set ROM's OE line high, disabling its output data lines
    0202  d3 fb      OUT fb

    0204  78         MOV A, B                   ; Repeat until the counter reaches zero
    0205  b1         ORA C
    0206  c2 be 01   JNZ WRITE_ROM_LOOP (01be)

    0209  21 c0 03   LXI HL, 03c0               ; BUG? Perhaps there should be DISABLE_HIGH_VOLTAGE_STR print
    020c  cd 8d 03   CALL PRINT_STR (038d)      ; to ask the User switcing off the high voltage

    020f  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for the User's confirmation

    0212  c3 08 01   JMP MAIN_MENU (0108)       ; And exit to the main menu


; Read a byte from the ROM
;
; Algorithm:
; - Set the address lines based on DE value
; - This will also tie low CE and OE pins of the ROM
; - Read the byte from ROM to A register
; - Return the CE pin high
; 
; Return the read byte in A register
READ_ROM_BYTE:
    0215  7b         MOV A, E                   ; Output low address byte to the port B
    0216  d3 f9      OUT f9

    0218  7a         MOV A, D                   ; Output high address to the port C (also set CE and OE pins low,
    0219  d3 fa      OUT fa                     ; that will enable data output from the ROM)

    021b  db f8      IN f8                      ; Input the data byte from the Port A

    021d  f5         PUSH PSW

    021e  3e 0d      MVI A, 0d                  ; deselect ROM by setting CE bit high (use 8255 BSR mode)
    0220  d3 fb      OUT fb

    0222  f1         POP PSW
    0223  c9         RET


; Perform a pause (on error)
LONG_PAUSE:
    0224  c5         PUSH BC                    ; Load the pause value
    0225  01 ff ff   LXI BC, ffff

LONG_PAUSE_LOOP:
    0228  0b         DCX BC                     ; Decrement the pause counter

    0229  78         MOV A, B                   ; Check if counter reached zero
    022a  b1         ORA C
    022b  c2 28 02   JNZ LONG_PAUSE_LOOP (0228)

    022e  c1         POP BC                     ; Stop and exit
    022f  c9         RET


; Perform a shorter 50 ms pause (used for write strobe)
PAUSE:
    0230  c5         PUSH BC                    ; Load the pause value
    0231  01 00 a0   LXI BC, a000

PAUSE_LOOP:
    0234  0b         DCX BC                     ; Decrement pause counter

    0235  78         MOV A, B                   ; Check if the counter reached zero
    0236  b1         ORA C
    0237  c2 34 02   JNZ PAUSE_LOOP (0234)

    023a  c1         POP BC                     ; Stop and exit
    023b  c9         RET


; Input a line up to 50 bytes long
; Entered line is stored in the buffer at 0x056a
; Return: A=0x00 on success, 0xff on buffer overflow
INPUT_LINE:
    023c  c5         PUSH BC                    ; Save registers
    023d  e5         PUSH HL

    023e  06 00      MVI B, 00                  ; B register will contain number of entered symbols
    0240  21 6a 05   LXI HL, LINE_BUFFER (056a) ; Reset buffer address

INPUT_LINE_LOOP:
    0243  cd 03 f8   CALL MONITOR_WAIT_KEY (f803)   ; Wait for a key press

    0246  fe 08      CPI A, 08                  ; Is this a back space / left arrow?
    0248  c2 56 02   JNZ INPUT_LINE_1 (0256)

    024b  78         MOV A, B                   ; Do not allow moving beyond the left border
    024c  b7         ORA A
    024d  ca 43 02   JZ INPUT_LINE_LOOP (0243)

    0250  cd 81 02   CALL PRINT_BACK_SPACE (0281)   ; Erase the symbol on the left, move cursor 1 position left
    0253  c3 43 02   JMP INPUT_LINE_LOOP (0243)

INPUT_LINE_1:
    0256  fe 18      CPI A, 18                  ; Is this a right arrow? Right arrow clears the whole string
    0258  c2 66 02   JNZ INPUT_LINE_3 (0266)

INPUT_LINE_2:
    025b  78         MOV A, B                   ; Do not allow moving beyond the left border
    025c  b7         ORA A
    025d  ca 43 02   JZ INPUT_LINE_LOOP (0243)

    0260  cd 81 02   CALL PRINT_BACK_SPACE (0281)   ; Print backspace, and repeat for the next symbol
    0263  c3 5b 02   JMP INPUT_LINE_2 (025b)

INPUT_LINE_3:
    0266  77         MOV M, A                   ; Store the entered char to the buffer

    0267  4f         MOV C, A                   ; Echo it on the screen as well
    0268  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    026b  fe 0d      CPI A, 0d                  ; Is this a return key?
    026d  ca 7d 02   JZ INPUT_LINE_4 (027d)

    0270  23         INX HL                     ; Increment the buffer pointer and symbols counter
    0271  04         INR B

    0272  78         MOV A, B                   ; Have we reached end of the buffer (50 symbols)?.
    0273  fe 32      CPI A, 32                  ; If not yet - wait for another symbol
    0275  c2 43 02   JNZ INPUT_LINE_LOOP (0243)

    0278  3e ff      MVI A, ff                  ; Return 0xff marking the buffer is full
    027a  c3 7e 02   JMP INPUT_LINE_5 (027e)

INPUT_LINE_4:
    027d  af         XRA A                      ; Return 0x00 marking the buffer value is correct

INPUT_LINE_5:
    027e  e1         POP HL                     ; Restore registers and exit
    027f  c1         POP BC
    0280  c9         RET


; Erase a symbol left to the cursor, move cursor 1 position left
PRINT_BACK_SPACE:
    0281  05         DCR B                      ; Reduce number of symbols in the buffer
    0282  2b         DCX HL                     ; Move the pointer to the previous symbol in the buffer

    0283  0e 08      MVI C, 08                  ; Print space to the left from cursor, then move cursor
    0285  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)   ; one position left
    0288  0e 20      MVI C, 20
    028a  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    028d  0e 08      MVI C, 08
    028f  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0292  c9         RET


; Load and check a char in the line buffer
;
; The function is also responsible for retrieving the char from the buffer, and returning it in C
; 
; Arguments: HL points to the char in the buffer to check
; Return:
; C - next char in the buffer
; A=0x00  if the char is a space
; A=0x01  if the char is 0x0d (EOL)
; A=0xff  if any other symbol is there
CHECK_BUF_CHAR:
    0293  e5         PUSH HL                    ; Load the next symbol from the buffer
    0294  2a 68 05   LHLD NEXT_BUF_CHAR (0568)
    0297  7e         MOV A, M

    0298  4f         MOV C, A                   ; Save loaded symbol in C

    0299  fe 20      CPI A, 20                  ; Is this a space?
    029b  c2 a2 02   JNZ CHECK_BUF_CHAR_1 (02a2)

    029e  af         XRA A                      ; Return 0x00 in case of a space
    029f  c3 ae 02   JMP CHECK_BUF_CHAR_3 (02ae)

CHECK_BUF_CHAR_1:
    02a2  fe 0d      CPI A, 0d                  ; Is this a CR?
    02a4  c2 ac 02   JNZ CHECK_BUF_CHAR_2 (02ac)

    02a7  3e 01      MVI A, 01                  ; CR char will return A=0x01
    02a9  c3 ae 02   JMP CHECK_BUF_CHAR_3 (02ae)

CHECK_BUF_CHAR_2:
    02ac  3e ff      MVI A, ff                  ; Return 0xff in case of any valid symbol

CHECK_BUF_CHAR_3:
    02ae  23         INX HL                     ; Advance to the next char, and save the new pointer value
    02af  22 48 05   SHLD NEXT_BUF_CHAR (0568)

    02b2  e1         POP HL                     ; Return
    02b3  c9         RET


; Parse hex byte (UNUSED function)
;
; The function parses up to 2 hex digits
;
; Return:
; C - parsed value
; A=0xff in case of error, other A values mean success
HEX_STR_TO_BYTE:
    02b4  d5         PUSH DE                    ; Zero the result accumulator (E reg) and char counter (D reg)
    02b5  11 00 00   LXI DE, 0000

HEX_STR_TO_BYTE_LOOP:
    02b8  cd 93 02   CALL CHECK_BUF_CHAR (0293) ; Get the next char, stop if reached EOL
    02bb  b7         ORA A
    02bc  fa cf 02   JM HEX_STR_TO_BYTE_1 (02cf)

    02bf  f5         PUSH PSW                   ; Return success if there was at least 1 char parsed
    02c0  7a         MOV A, D
    02c1  b7         ORA A
    02c2  c2 ca 02   JNZ HEX_STR_TO_BYTE_SUCCESS (02ca)
    02c5  f1         POP PSW

HEX_STR_TO_BYTE_ERROR:
    02c6  3e ff      MVI A, ff                  ; Return a failure (A = 0xff)

HEX_STR_TO_BYTE_EXIT:
    02c8  d1         POP DE                     ; Return A as error code
    02c9  c9         RET

HEX_STR_TO_BYTE_SUCCESS:
    02ca  f1         POP PSW                    ; Return parsed value in C on success
    02cb  4b         MOV C, E
    02cc  c3 c8 02   JMP HEX_STR_TO_BYTE_EXIT (02c8)

HEX_STR_TO_BYTE_1:
    02cf  14         INR D                      ; Increment parsed symbols counter

    02d0  7a         MOV A, D                   ; Fail the parsing if more than 2 chars detected
    02d1  fe 03      CPI A, 03
    02d3  d2 c6 02   JNC HEX_STR_TO_BYTE_ERROR (02c6)

    02d6  7b         MOV A, E                   ; Shift the result (E reg) 4 bits left, reserving low 4 bits
    02d7  07         RLC                        ; for a new value
    02d8  07         RLC
    02d9  07         RLC
    02da  07         RLC
    02db  e6 f0      ANI A, f0
    02dd  5f         MOV E, A

    02de  cd eb 02   CALL CHAR_TO_INT (02eb)    ; Parse lower nibble, exit with error on wrong char
    02e1  b7         ORA A
    02e2  c2 c6 02   JNZ HEX_STR_TO_BYTE_ERROR (02c6)

    02e5  79         MOV A, C                   ; Apply parsed symbol to the result in E register
    02e6  83         ADD E
    02e7  5f         MOV E, A

    02e8  c3 b8 02   JMP HEX_STR_TO_BYTE_LOOP (02b8)    ; Repeat for the next char


; Convert a hex char in C ('0'-'9' or 'A'-'F') to an integer value in C
; Return A=0x00 if no error, 0xff in case of error
CHAR_TO_INT:
    02eb  79         MOV A, C                   ; Char < '0' is an error
    02ec  fe 30      CPI A, 30
    02ee  da 0a 03   JC CHAR_TO_INT_ERROR (030a)

    02f1  fe 47      CPI A, 47                  ; Char > 'F' is an error
    02f3  d2 0a 03   JNC CHAR_TO_INT_ERROR (030a)

    02f6  fe 41      CPI A, 41                  ; Is char < 'A'?
    02f8  da 00 03   JC CHAR_TO_INT_1 (0300)

    02fb  d6 37      SUI A, 37                  ; Convert char 'A'-'F' to the hex value
    02fd  c3 07 03   JMP CHAR_TO_INT_2 (0307)

CHAR_TO_INT_1:
    0300  fe 3a      CPI A, 3a                  ; Symbol between '9' and 'A' is an error
    0302  d2 0a 03   JNC CHAR_TO_INT_ERROR (030a)

    0305  e6 0f      ANI A, 0f                  ; Convert the char '0'-'9' to the hex value

CHAR_TO_INT_2:
    0307  4f         MOV C, A                   ; Return result in C
    0308  af         XRA A                      ; A=0x00 indicates successful conversion
    0309  c9         RET

CHAR_TO_INT_ERROR:
    030a  3e ff      MVI A, ff                  ; A=0xff indicate an error
    030c  c9         RET



; Convert a string, representing a hex value, to the integer value
;
; The function converts the digits one by one, and adds them to the result accumulator. Upon parsing the next
; digit, the result accumulator is shifted left by 4 bits.
;
; Arguments:
; - a string pointed by the 0x0568 variable
;
; Returns:
; - A - number of parsed chars, or 0xff in case of error
; - HL - parsed value
HEX_STR_TO_INT:
    030d  c5         PUSH BC                    ; Save registers
    030e  d5         PUSH DE

    030f  21 00 00   LXI HL, 0000               ; Output value accumulator

    0312  06 00      MVI B, 00                  ; Reset input bytes counter

HEX_STR_TO_INT_LOOP:
    0314  cd 93 02   CALL CHECK_BUF_CHAR (0293) ; Check the char for EOF, EOL, etc.

    0317  b7         ORA A                      ; Continue elsewhere if normal symbol found
    0318  fa 2b 03   JM HEX_STR_TO_INT_2 (032b)

    031b  f5         PUSH PSW                   ; Check whether any symbols were parsed
    031c  78         MOV A, B
    031d  b7         ORA A
    031e  c2 27 03   JNZ HEX_STR_TO_INT_1 (0327)

    0321  f1         POP PSW                    ; Restore stack

HEX_STR_TO_INT_ERROR:
    0322  3e ff      MVI A, ff                  ; Report an error (A=0xff)

HEX_STR_TO_INT_EXIT:
    0324  d1         POP DE                     ; Exit
    0325  c1         POP BC
    0326  c9         RET

HEX_STR_TO_INT_1:
    0327  f1         POP PSW                    ; Restore stack, and exit
    0328  c3 24 03   JMP HEX_STR_TO_INT_EXIT (0324)

HEX_STR_TO_INT_2:
    032b  04         INR B                      ; Increment symbol counter

    032c  78         MOV A, B                   ; Parse no more than 5 symbols (report errpr otherwise)
    032d  fe 05      CPI A, 05
    032f  d2 22 03   JNC HEX_STR_TO_INT_ERROR (0322)

    0332  16 04      MVI D, 04                  ; Shift counter (do 4 shifts of HL left)

HEX_STR_TO_INT_3:
    0334  af         XRA A                      ; Reset C flag

    0335  7d         MOV A, L                   ; Shift lower byte 1 bit left
    0336  17         RAL
    0337  6f         MOV L, A

    0338  7c         MOV A, H                   ; Shift high byte 1 bit left
    0339  17         RAL
    033a  67         MOV H, A

    033b  15         DCR D                      ; Repeat 4 times
    033c  c2 34 03   JNZ HEX_STR_TO_INT_3 (0334)

    033f  cd eb 02   CALL CHAR_TO_INT (02eb)    ; Convert char to the value

    0342  b7         ORA A                      ; Check error code
    0343  c2 22 03   JNZ HEX_STR_TO_INT_ERROR (0322)

    0346  79         MOV A, C                   ; Add the parsed value to the result accumulator
    0347  b5         ORA L
    0348  6f         MOV L, A

    0349  c3 14 03   JMP HEX_STR_TO_INT_LOOP (0314)


; Print a byte in A register in a hex form
PRINT_BYTE:
    034c  c5         PUSH BC                    ; Save input byte in B temporarily
    034d  47         MOV B, A

    034e  e6 f0      ANI A, f0                  ; Bring high nibble to the low
    0350  0f         RRC
    0351  0f         RRC
    0352  0f         RRC
    0353  0f         RRC

    0354  cd 5f 03   CALL PRINT_HEX_DIGIT (035f); And print it

    0357  78         MOV A, B                   ; Now print the low nibble
    0358  e6 0f      ANI A, 0f
    035a  cd 5f 03   CALL PRINT_HEX_DIGIT (035f)

    035d  c1         POP BC                     ; Done
    035e  c9         RET


; Print a hex digit in A register
PRINT_HEX_DIGIT:
    035f  fe 0a      CPI A, 0a                  ; Digits A-F will be slightly corrected
    0361  da 66 03   JC PRINT_HEX_DIGIT_1 (0366)
    0364  c6 07      ADI A, 07

PRINT_HEX_DIGIT_1:
    0366  c6 30      ADI A, 30                  ; All digits are now either '0'-'9' or 'A'-'F'

    0368  4f         MOV C, A                   ; Print the calculated char
    0369  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    036c  c9         RET                        ; Done

; Print HL value in a hex form
PRINT_HL_HEX:
    036d  f5         PUSH PSW                   ; Print H register
    036e  7c         MOV A, H
    036f  cd 4c 03   CALL PRINT_BYTE (034c)

    0372  7d         MOV A, L                   ; Print L register
    0373  cd 4c 03   CALL PRINT_BYTE (034c)

    0376  f1         POP PSW                    ; Done
    0377  c9         RET

; Print 0x0d-0x0a (CR/LF) sequence
PRINT_CR_LF:
    0378  c5         PUSH BC
    0379  0e 0d      MVI C, 0d
    037b  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    037e  0e 0a      MVI C, 0a
    0380  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    0383  c1         POP BC
    0384  c9         RET

; Print a space symbol (unused code, not referenced in the code)
PRINT_SPACE:
    0385  c5         PUSH BC
    0386  0e 20      MVI C, 20
    0388  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)
    038b  c1         POP BC
    038c  c9         RET

; Print null-terminated string, pointed by HL
PRINT_STR:
    038d  f5         PUSH PSW                   ; Save some registers
    038e  c5         PUSH BC

PRINT_STR_LOOP:
    038f  7e         MOV A, M                   ; Load the next char to print

    0390  b7         ORA A                      ; Stop printing on zero symbol
    0391  ca 9c 03   JZ PRINT_STR_EXIT (039c)

    0394  4f         MOV C, A                   ; Print the char
    0395  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    0398  23         INX HL                     ; Advance to the next byte, and repeat
    0399  c3 8f 03   JMP PRINT_STR_LOOP (038f)

PRINT_STR_EXIT:
    039c  c1         POP BC                     ; Restore registers and exit
    039d  f1         POP PSW
    039e  c9         RET


; Calculate a simple CRC for a HL-DE memory range, return result in BC
CALC_CRC:
    039f  f5         PUSH PSW                   ; Reset result accumulator
    03a0  e5         PUSH HL
    03a1  01 00 00   LXI BC, 0000

CALC_CRC_LOOP:
    03a4  79         MOV A, C                   ; Add the memory byte to the low byte of the accumulator
    03a5  86         ADD M
    03a6  4f         MOV C, A

    03a7  78         MOV A, B                   ; Adjust the high byte
    03a8  ce 00      ACI A, 00
    03aa  47         MOV B, A

    03ab  23         INX HL                     ; Advance to the next byte

    03ac  7c         MOV A, H                   ; Compare HL and DE, repeat until they are not equal
    03ad  ba         CMP D
    03ae  c2 a4 03   JNZ CALC_CRC_LOOP (03a4)
    03b1  7d         MOV A, L
    03b2  bb         CMP E
    03b3  c2 a4 03   JNZ CALC_CRC_LOOP (03a4)

    03b6  79         MOV A, C                   ; Add the last byte the the accumulator
    03b7  86         ADD M
    03b8  4f         MOV C, A

    03b9  78         MOV A, B
    03ba  ce 00      ACI A, 00
    03bc  47         MOV B, A

    03bd  e1         POP HL                     ; Done
    03be  f1         POP PSW
    03bf  c9         RET


NOTHING:
    03c0  16 * 00          db 16 x 00


PROMPT_STR:
    03d6  0d 0a 20 20 20 20 20 70 72 6f 67 72 61 6d 6d 61   db 0x0d, 0x0a, "     ПРОГРАММА"
    03e6  74 6f 72 20 20 70 7a 75 20 35 37 33 72 66 32 20   db "ТОР  ПЗУ 573РФ2 "
    03f6  72 66 35 20 20 20 20 20 0d 0a 0d 0a 20 20 20 20   db "РФ5     ", 0x0d, 0x0a, 0x0d, 0x0a, "    "
    0406  20 70 65 72 65 7e 65 6e 78 20 6b 6f 6d 61 6e 64   db " ПЕРЕЧЕНЬ КОМАНД"
    0416  20 20 20 3a 20 20 20 20 0d 0a 20 52 20 20 20 7e   db "   :    ", 0x0d, 0x0a, " R   Ч"
    0426  74 65 6e 69 65 20 0d 0a 20 57 20 20 20 7a 61 70   db "ТЕНИЕ ", 0x0d, 0x0a, " W   ЗАП"
    0436  69 73 78 20 0d 0a 20 45 20 2d 20 77 79 68 6f 64   db "ИСЬ ", 0x0d, 0x0a, " E - ВЫХОД"
    0446  20 77 20 6d 6f 6e 69 74 6f 72 20 20 20 0d 0a 0d   db " В МОНИТОР   ", 0x0d, 0x0a, 0x0d
    0456  0a 20 6b 6f 6d 61 6e 64 61 20 3e 00               db 0x0a, " КОМАНДА >", 0x00

ERROR_STR:
    0462  0d 0a 0d 0a 20 20 20 2a 20 20 6f 20 7b 20 69 20   db 0x0d, 0x0a, 0x0d, 0x0a, "   *  О Ш И "
    0472  62 20 6b 20 61 20 20 2a 20 20 0d 0a 00            db "Б К А  *  ", 0x0d, 0x0a, 0x00

ENABLE_HIGH_VOLTAGE_STR:
    047f  0d 0a 0d 0a 20 77 6b 6c 60 7e 69 74 65 20 6e 61   db 0x0d, 0x0a, 0x0d, 0x0a, " ВКЛЮЧИТЕ НА"
    048f  70 72 71 76 65 6e 69 65 20 2b 32 36 20 77 6f 6c   db "ПРЯЖЕНИЕ +26 ВОЛ"
    049f  78 74 20 00                                       db "ЬТ ", 0x00

DISABLE_HIGH_VOLTAGE_STR:
    04a3  0d 0a 20 77 79 6b 6c 60 7e 69 74 65 20 6e 61 70   db 0x0d, 0x0a, " ВЫКЛЮЧИТЕ НАП"
    04b3  72 71 76 65 6e 69 65 20 2b 32 36 20 77 6f 6c 78   db "РЯЖЕНИЕ +26 ВОЛЬ"
    04c3  74 20 00                                          db "Т ", 0x00

READ_MODE_STR:
    04c6  0d 0a 20 20 20 20 20 20 20 20 72 65 76 69 6d 20   db 0x0d, 0x0a, "        РЕЖИМ "
    04d6  7e 74 65 6e 69 71 20 20 20 20 20 20 20 0d 0a 0d   db "ЧТЕНИЯ       ", 0x0d, 0x0a, 0x0d
    04e6  0a 20 7a 61 64 61 6a 74 65 20 6e 61 7e 61 6c 78   db 0x0a, " ЗАДАЙТЕ НАЧАЛЬ"
    04f6  6e 79 6a 20 61 64 72 65 73 20 6f 7a 75 20 20 00   db "НЫЙ АДРЕС ОЗУ  ", 0x00

WRITE_MODE_STR:
    0506  0d 0a 20 20 20 20 20 20 20 20 72 65 76 69 6d 20   db 0x0d, 0x0a, "        РЕЖИМ "
    0516  7a 61 70 69 73 69 20 20 20 20 20 20 20 0d 0a 0d   db "ЗАПИСИ       ", 0x0d, 0x0a, 0x0d
    0526  0a 20 7a 61 64 61 6a 74 65 20 6e 61 7e 61 6c 78   db 0x0a, " ЗАДАЙТЕ НАЧАЛЬ"
    0536  6e 79 6a 20 61 64 72 65 73 20 6f 7a 75 20 20 00   db "НЫЙ АДРЕС ОЗУ  ", 0x00

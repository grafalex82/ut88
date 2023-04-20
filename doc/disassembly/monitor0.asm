; Monitor0 is a primary firmware for the CPU module. Monitor0 is located in ROM at
; 0x0000-0x03ff address and provides basic routines for CPU module peripheral. The Monitor0
; is split into 2 parts
; - 0x0000-0x01ff - essential part of the ROM that includes
;     - Handy routines to input data from the keyboard, output to LCD, input and output
;       the data to the tape.
;     - Basic operating system to read/write memory and ROM, execute programs
;     - Current time clock
; - 0x0200-0x03ff - optional part with a few useful programs:
;     - memory copying programs
;     - TBD 
;
; This disassembly listing includes only the first part of the Monitor. See the second part
; disassembly in a separate listing.
;
; Monitor0 exposes a few handy routines for the purposes of Monitor itself and the
; user application. Unlike typical approach, when CALL 3-byte instruction is used to
; execute these routines, the Monitor0 uses RSTx 1-byte instructions. This is clever
; solution in terms of packing code into a tiny ROM. Since RST addresses are spaced
; by 8 bytes, the routine implementation starts at RST address, and continues elsewhere.
;
; RST routines are:
; - RST 0 (address 0x0000)  - reset routine
; - RST 1 (address 0x0008)  - output a byte in A to the tape
; - RST 2 (address 0x0010)  - wait for a byte (2 digit) pressed on the keypad, return in A
; - RST 3 (address 0x0018)  - 1 second delay
; - RST 4 (address 0x0020)  - wait for a button press, return key code in A
; - RST 5 (address 0x0028)  - display A and HL registers on the LCD
; - RST 6 (address 0x0030)  - wait for a 2 byte (4 digit) value typed on the keyboard, return in DE
; - RST 7 (address 0x0038)  - time interrupt (executed every second, and advances time value)
; 
; When Monior0 starts, it displays 11 on the rightmost LCD digits - this is a ready signal.
; The Monitor0 interacts with the user with the following commands (entered using HEX keyboard)
; - 0 <addr>    - Manually enter data starting <addr>. 
;                   - Current address is displayed on the LCD
;                   - Monitor0 waits for the byte to be entered
;                   - Entered byte is stored at the current address, then address advances
;                   - Reset to exit memory write mode (memory data will be preserved)
; - 1           - Manually enter data starting address 0xc000 (similar to command 0)
; - 2           - Read memory data starting the address 0xc000 (similar to command 5)
; - 3           - Run an LCD test
; - 4           - Run memory test for the range of 0xc000 - 0xc400.
;                   - If a memory error found, the LCD will display the address and the read value
;                   - Address 0xc400 on the display means no memory errors found
;                   - Reset to exit memory test mode
; - 5 <addr>    - Display data starting address <addr>
;                   - Current address and the byte at the address are displayed on the LCD
;                   - Press a button for the next byte
;                   - Reset to exit memory read mode (memory data will be preserved)
; - 6           - Start the program starting address 0xc000
; - 7 <addr>    - Start the program starting the user address
; - 8 <a1> <a2> - Calculate CRC for the address range a1-a2
; - 9 <a1> <a2> - Store data at the address range a1-a2 to the tape
; - A <offset>  - Read data from tape with the offset (to the start address written on the tape)
; - B           - Display current time (0x3cfd - seconds, 0x3cfe - minutes, 0x3cff - hours)
; - C <addr>    - Enter new time. Same as command 0, but interrupts disabled. Address shall be 0x3cfd
;
; Important memory adresses:
; - 0x3fc       - tape reading polarity (0x00 - non inverted, 0xff - inverted)
; - 0x3fd       - seconds
; - 0x3fe       - minutes
; - 0x3ff       - hours
;
; Tape recording format:
; - 256 x 0xff  - pilot tone, to sync with the sequence
; - 0xe6        - synchronization byte, marks polarity and start of data bytes
; - 2 bytes     - start address
; - 2 bytes     - end address
; - <bytes>     - data bytes
;
; No CRC bytes are stored on the tape. The CRC value is displayed on the screen after store
; and load commands. The User is responsible for validating the CRC.
;
; Bugs and issues:
; - RST4 is a handy routine for waiting a keyboard input. But Step Back button is also 
;   processed in the RST4. And instead of returning the step back button code to the caller
;   it rudely switches to RAM write (Command 0) execution, regardless of what was executed before
; - Commands 8, 9 and C gently save all the registers, and restores them back. But it ends up calling
;   a RST0 (reset) function eventually. So the code could save at least 16 bytes as no one really
;   interested in those registers
; - Command B (display current time) uses RST 3 delay routine between displaying a new time value.
;   This causes a non-uniform displaying, some values are skipped


; Reset entry point
RST0:
    ; Set up the stack pointer
    0000  31 ee c3   LXI SP, c3ee

    ; Prepare for displaying 11 on the LCD
    0003  3e 11      MVI A, 11
    0005  c3 3b 00   JMP RST0_CONT (003b)   ; Continuate elsewhere, as RST1 handler is located at 0x0008

; RST 1 - Output data byte to the tape
RST1:
    0008  c3 00 01   JMP RST_1_CONT (0100)

; Command 5 - read memory data at the provided address
CMD_5:
    000b  f7         RST 6                  ; Wait for the address type on the keyboard
    000c  eb         XCHG                   ; Move the address to HL
    000d  c3 7d 00   JMP RAM_READ (007d)    ; Continue elsewhere

; RST2 - wait for entering a 2-digit byte value using the keypad
RST2:
    0010  d5         PUSH DE                ; Prepare
    0011  af         XRA A
    0012  57         MOV D, A
    0013  e7         RST 4                  ; Read first digit

    0014  07         RLC                    ; Move received half byte to left
    0015  c3 47 00   JMP RST2_CONT (0047)   ; Continue elsewhere

; RST3 - 1 second delay routine
RST3: 
    0018  e5         PUSH HL                ; Save modified registers
    0019  f5         PUSH PSW

    001a  21 50 66   LXI HL, 6650           ; Load number of wait cycles
    001d  c3 56 00   JMP RST3_CONT (0056)   ; Continue elsewhere, as RST4 handles is located at 0020

; RST4 handler - wait for a button press
RST4:
    0020  df         RST 3                  ; 1 second delay
    0021  c3 5f 00   JMP RST4_CONT (005f)   ; continue elsewhere
    0024  00         NOP

; Command 6 - Start the program from 0xc000
CMD_6:
    0025  c3 00 c0   JMP c000               ; Direct jump to the starting address

; RST5 - display HL and A values on the LCD
RST5:
    0028  32 00 90   STA 9000               ; Write A and HL to respective LCD address
    002b  22 01 90   SHLD 9001              
    002e  c9         RET
    002f  00         NOP

; RST6 - Wait for 2 byte value from the keyboard, return in DE
RST6:
    0030  f5         PUSH PSW
    0031  d7         RST 2                  ; Wait for a high address byte entered on keypad
    0032  57         MOV D, A               ; and store it in D

    0033  d7         RST 2                  ; Wait for the low address byte
    0034  5f         MOV E, A               ; Return the entered address in DE
    0035  f1         POP PSW
    0036  c9         RET
    0037  00         NOP

; RST7 - 1 second timer interrupt handler
RST7:
    0038  c3 c1 00   JMP TIMER_INT (00c1)   ; Just jump to the actual handler


RST0_CONT:
    003b  fb         EI                     ; Continue initial initialization, enable interrputs

    ; Print 11 (ready sign) on the LCD (0x9000)
    003c  32 00 90   STA 9000
    003f  e7         RST 4                  ; Wait for a command

    0040  c6 f3      ADI f3                 ; The array at 0x00f3 has addresses of the command handlers
    0042  26 00      MVI H, 00
    0044  6f         MOV L, A
    0045  6e         MOV L, M               ; Load the command handler address to L (H is 0x00)

    0046  e9         PCHL                   ; Execute the command


RST2_CONT:
    0047  07         RLC                    ; Finish moving entered half a byte to upper half
    0048  07         RLC
    0049  07         RLC

    004a  b2         ORA D                  ; Temporary Store entered half a byte in D
    004b  57         MOV D, A
    004c  32 00 90   STA 9000               ; And display it on the screen

    004f  e7         RST 4                  ; Enter second half a byte
    0050  b2         ORA D                  ; Add the previous half of the byte
    0051  32 00 90   STA 9000               ; And display it on the screen

    0054  d1         POP DE                 ; Return the entered byte in A
    0055  c9         RET    

RST3_CONT:
    0056  2b         DCX HL                 ; Decrement HL...
    0057  7d         MOV A, L
    0058  b4         ORA H
    0059  c2 d1 c9   JNZ 0056               ; ... until it is zero

    005c  f1         POP PSW                ; Restore registers and exit
    005d  e1         POP HL
    005e  c9         RET

RST4_CONT:
    005f  db a0      IN a0                  ; Read the keyboard port
    0061  c6 00      ADI 00                 ; Wait for a button to be pressed
    0063  ca 5f 00   JZ 005f

    0066  fe 80      CPI 80                 ; Check for step back button
    0068  ca 6e 00   JZ BACK_BTN (006e)
    006b  e6 0f      ANI 0f                 ; Return pressed button code in A register (0x0-0xf value)
    006d  c9         RET

BACK_BTN:
    006e  2b         DCX HL                 ; Rudely return from the RST4, and switch to RAM write mode
    006f  3b         DCX SP
    0070  3b         DCX SP                 

RAM_WRITE:
    0071  af         XRA A                  ; Display current address and 0x00 value
    0072  ef         RST 5

    0073  d7         RST 2                  ; Wait for the data byte entered using keyborad
    0074  77         MOV M, A               ; Store the byte
    0075  df         RST 3                  ; and let it be displed for a second

    0076  23         INX HL                 ; Then move to the next byte
    0077  c3 71 00   JMP 0071    

; Command 2 - read memory starting from address 0xc000
CMD_2:
    007a  21 00 c0   LXI HL, c000           ; Load the starting address

RAM_READ:
    007d  e7         RST 4                  ; Wait for the button press
    
    007e  7e         MOV A, M               ; Load and display the value at the current address
    007f  ef         RST 5

    0080  23         INX HL                 ; Advance the address and repeat
    0081  c3 7d 00   JMP 007d


; Command 7 - Start the program starting the given address
CMD_7:
    0084  f7         RST 6                  ; Enter the address to start from
    0085  eb         XCHG

RUN_PROG:
    0086  af         XRA A                  ; Display the address for a second
    0087  ef         RST 5
    0088  df         RST 3

    0089  e9         PCHL                   ; Execute the program starting the given address

CMD_1:
    008a  21 00 c0   LXI HL, c000           ; Load 0xc000 as a starting address
    008d  c3 71 00   JMP RAM_WRITE (0071)   ; And jump to the RAM manual write function


; Command C - set new time. In fact a synonym for Command 0 (write memory), but disabling interrupts first
CMD_C:
    0090  f3         DI                     ; Disable interrupt before setting new time

CMD_0:
    0091  f7         RST 6                  ; Wait for the address typed on the keyboard, returned in DE
    0092  eb         XCHG                   ; Load the enterred address into HL
    0093  c3 71 00   JMP RAM_WRITE (0071)   ; And continue at the ram writing function

; Command 3 - test LCD. Displays numbers from 0 to F on all 6-digits of the LCD
CMD_3:
    0096  af         XRA A                  ; Zero A and HL

CMD_3_DISPLAY_DIGIT:
    0097  67         MOV H, A
    0098  6f         MOV L, A
    0099  ef         RST 5                  ; Display the value to all LCDs
    009a  df         RST 3                  ; Wait 1 second

    009b  c6 11      ADI 11                 ; Switch to the next digit
    009d  fe 10      CPI 10                 ; Repeat until all digits are displayed
    009f  c2 97 00   JNZ CMD_3_DISPLAY_DIGIT (0097)
    
    00a2  c7         RST 0                  ; Reset to the main loop


; Command 4 - test RAM
CMD_4:
    00a3  21 00 c0   LXI HL, c000           ; Load RAM start address (0xc000)

CMD_4_LOOP:
    00a6  af         XRA A                  ; Store a 0x00 value
    00a7  77         MOV M, A
    00a8  7e         MOV A, M               ; Load value back and check if it is still zero
    00a9  b7         ORA A
    00aa  c2 bb 00   JNZ CMD_4_ERROR (00bb)

    00ad  3d         DCR A                  ; Store a 0xff value
    00ae  77         MOV M, A
    00af  7e         MOV A, M               ; Load it back and check if it is still 0xff
    00b0  3c         INR A
    00b1  c2 bb 00   JNZ CMD_4_ERROR (00bb)

    00b4  23         INX HL                 ; Repeat until 0xc400 is reached
    00b5  7c         MOV A, H
    00b6  e6 04      ANI 04
    00b8  ca a6 00   JZ CMD_4_LOOP (00a6)

CMD_4_ERROR:
    00bb  7e         MOV A, M               ; Display the read value and its address
    00bc  ef         RST 5

    00bd  e7         RST 4                  ; Wait for button, and repeat
    00be  c3 a6 00   JMP CMD_4_LOOP

TIMER_INT:
    00c1  f3         DI                     ; Save registers, and disable interrupts
    00c2  f5         PUSH PSW
    00c3  c5         PUSH BC
    00c4  d5         PUSH DE
    00c5  e5         PUSH HL

    00c6  21 e4 00   LXI HL, 00e4           ; Maximum for corresponding value
    00c9  11 fd c3   LXI DE, c3fd           ; Start with seconds
    00cc  06 03      MVI B, 03              ; 3 values to increment

TIMER_ADV:
    00ce  1a         LDAX DE                ; Increment value
    00cf  3c         INR A                  ; 
    00d0  27         DAA
    00d1  12         STAX DE

    00d2  be         CMP M                  ; Check if maximum reached
    00d3  c2 de 00   JNZ 00de

    00d6  af         XRA A                  ; Zero and store the value if maximum reached
    00d7  12         STAX DE

    00d8  23         INX HL                 ; Advance maximum values and time values addresses
    00d9  13         INX DE
    
    00da  05         DCR B                  ; Repeat for seconds, minutes, and hours
    00db  c2 ce 00   JNZ TIMER_ADV (00ce)

    00de  e1         POP HL                 ; Restore registers and interrupts
    00df  d1         POP DE
    00e0  c1         POP BC
    00e1  f1         POP PSW
    00e2  fb         EI
    00e3  c9         RET

    00e4             60, 60, 24             ; Maximum values for seconds, minutes, and hours


; Command 9 - store a data range to the tape
CMD_9:
    00e7  c3 9a 01   JMP CMD_9_CONT (019a)  ; Continue elsewhere (out of the first 0x100 bytes)

; Command A - read data from tape
CMD_A:
    00ea  c3 c2 01   JMP CMD_A_CONT (01c2)

; Command 8 - CRC of the memory region
CMD_8:
    00ed  c3 75 01   JMP CMD_8_CONT (0175)

; Command B - display current time
CMD_B:
    00f0  c3 f5 01   JMP CMD_B_CONT (01f5)

; Command handlers addresses (low byte)
CMD_HANDLERS:
    db    91, 8a, 7a, 96, a3, 0b, 25, 84, ed, e7, ea, f0, 90       

; RST 1 - Output data byte to the tape
RST_1_CONT:
    0100  c5         PUSH BC                ; Save affected registers
    0101  d5         PUSH DE
    0102  f5         PUSH PSW

    0103  57         MOV D, A               ; Save the byte to send
    0104  0e 08      MVI C, 08              ; 8 bits to send

OUT_NEXT_BIT:
    0106  7a         MOV A, D               ; Get next bit into carry flag
    0107  07         RLC
    0108  57         MOV D, A

    0109  3e 01      MVI A, 01              ; Output least significant bit inverted
    010b  aa         XRA D
    010c  d3 a1      OUT a1
    010e  cd 21 01   CALL TAPE_DELAY (0121)

    0111  3e 00      MVI A, 00              ; Output least significant bit non inverted
    0113  aa         XRA D
    0114  d3 a1      OUT a1
    0116  cd 21 01   CALL TAPE_DELAY (0121)

    0119  0d         DCR C                  ; Repeat until all bits are sent
    011a  c2 06 01   JNZ OUT_NEXT_BIT (0106)

    011d  f1         POP PSW                ; Restore registers and exit
    011e  d1         POP DE
    011f  c1         POP BC
    0120  c9         RET

; A small delay function, used to measure bit length while storing to tape
TAPE_DELAY:
    0121  06 1e      MVI B, 1e              ; Delay counter
TAPE_DELAY_LOOP:
    0123  05         DCR B
    0124  c2 23 01   JNZ TAPE_DELAY_LOOP (0123)
    0127  c9         RET


; Receive a byte from the tape. A - number of bits to receive, or 0xff to wait for synchronization
IN_TAPE_BYTE:
    0128  c5         PUSH BC
    0129  d5         PUSH DE
    012a  0e 00      MVI C, 00              ; register C - Data byte accumulator
    012c  57         MOV D, A               ; register D - Number of bits to listen (or 0xff for sync)
    
    012d  db a1      IN a1                  ; Input a bit from the tape
    012f  5f         MOV E, A
    
IN_NEXT_BIT:
    0130  79         MOV A, C               ; Prepare current byte accumulator for receiving next bit
    0131  e6 7f      ANI 7f
    0133  07         RLC
    0134  4f         MOV C, A

WAIT_NEXT_PHASE:
    0135  db a1      IN a1                  ; Wait for the bit phase change
    0137  bb         CMP E
    0138  ca 35 01   JZ WAIT_NEXT_PHASE (0135)

    013b  e6 01      ANI 01                 ; Received bit is the data bit
    013d  b1         ORA C                  ; Store the value in C
    013e  4f         MOV C, A

    013f  cd 6e 01   CALL TAPE2_DELAY (016e); Wait for the next bit

    0142  db a1      IN a1                  ; Input next bit
    0144  5f         MOV E, A

    0145  7a         MOV A, D               ; If synchronization is already happened - repeat
    0146  b7         ORA A                  ; needed number of bytes, otherwise (D == 0xff) wait
    0147  f2 63 01   JP BIT_RECEIVED (0163) ; for a sync byte

    014a  79         MOV A, C               ; Check if synchronization byte has been received
    014b  fe e6      CPI e6
    014d  c2 57 01   JNZ TRY_SYNC_NEGATIVE (0157)

    0150  af         XRA A                  ; Synchronization happen in positive polarity
    0151  32 fc c3   STA c3fc               ; Remember this fact in 0xc3fc, no bytes inversion will be performed
    0154  c3 61 01   JMP IN_SYNCHRONIZED (0161)

TRY_SYNC_NEGATIVE:
    0157  fe 19      CPI 19                 ; Try another polarity of the sync byte (e6 inverted)
    0159  c2 30 01   JNZ IN_NEXT_BIT (0130) ; If sync has not happen - wait for the next bit

    015c  3e ff      MVI A, ff              ; Synchronization happened in reverse polarity
    015e  32 fc c3   STA c3fc               ; Remember this in 0xc3fc, and invert all received bytes

IN_SYNCHRONIZED:
    0161  16 09      MVI D, 09              ; Prepare for receiving a real data byte
 
BIT_RECEIVED:
    0163  15         DCR D                  ; Repeat until all bits are received
    0164  c2 30 01   JNZ 0130

    0167  3a fc c3   LDA c3fc               ; Apply inverting if necessary
    016a  a9         XRA C

    016b  d1         POP DE                 ; Return received byte in A
    016c  c1         POP BC
    016d  c9         RET

; A small delay function, used to measure bit length while loading from tape
TAPE2_DELAY:
    016e  06 2d      MVI B, 2d                  ; Delay counter
TAPE2_DELAY_LOOP:
    0170  05         DCR B
    0171  c2 70 01   JNZ TAPE2_DELAY_LOOP (0170)
    0174  c9         RET

; Command 8 - Calculate CRC of the memory region
CMD_8_CONT:
    0175  c5         PUSH BC
    0176  d5         PUSH DE
    0177  e5         PUSH HL
    0178  f5         PUSH PSW

    0179  f7         RST 6                  ; Read the starting address
    017a  42         MOV B, D               ; And move it to BC
    017b  4b         MOV C, E

    017c  f7         RST 6                  ; Read the ending address to DE

CALC_CRC:
    017d  2e 00      MVI L, 00              ; Zero CRC value accumulator in HL
    017f  65         MOV H, L

CRC_NEXT:
    0180  0a         LDAX BC                ; Load the value at BC address
    0181  d5         PUSH DE
    0182  5f         MOV E, A               ; And add it to HL
    0183  16 00      MVI D, 00
    0185  19         DAD DE
    0186  d1         POP DE

    0187  cd 94 01   CALL CMD_BC_DE (0194)  ; Check if we reached the end address
    018a  03         INX BC                 ; Advance the address and continue
    018b  c2 80 01   JNZ CRC_NEXT (0180)

    018e  ef         RST 5                  ; Display the result

    018f  f1         POP PSW                ; Finish and reset
    0190  e1         POP HL
    0191  d1         POP DE
    0192  c1         POP BC
    0193  c7         RST 0    

CMP_BC_DE:
    0194  7a         MOV A, D               ; Compare D and B
    0195  b8         CMP B
    0196  c0         RNZ
    0197  7b         MOV A, E               ; Compare E and C
    0198  b9         CMP C
    0199  c9         RET


; Command 9 - store a data range to the tape
CMD_9_CONT:
    019a  c5         PUSH BC
    019b  d5         PUSH DE
    019c  e5         PUSH HL
    019d  f5         PUSH PSW

    019e  f7         RST 6                  ; Read starting address to BC
    019f  42         MOV B, D
    01a0  4b         MOV C, E

    01a1  f7         RST 6                  ; Read ending address to DE

    01a2  c5         PUSH BC                ; Save start address to be used during CRC calculation
    01a3  af         XRA A                  
    01a4  6f         MOV L, A               ; L will contain byte counter

OUT_SYNC_LOOP:
    01a5  cf         RST 1                  ; Output zero byte 256 times (synchronization sequence)
    01a6  2c         INR L                  ; 
    01a7  c2 a5 01   JNZ OUT_SYNC_LOOP (01a5)

    01aa  3e e6      MVI A, e6              ; Send synchronization byte
    01ac  cf         RST 1

    01ad  78         MOV A, B               ; Output BC register (start address)
    01ae  cf         RST 1
    01af  79         MOV A, C
    01b0  cf         RST 1

    01b1  7a         MOV A, D               ; Output DE register (end address)
    01b2  cf         RST 1
    01b3  7b         MOV A, E
    01b4  cf         RST 1

OUT_NEXT_BYTE:
    01b5  0a         LDAX BC                ; Output next data byte
    01b6  cf         RST 1

    01b7  cd 94 01   CALL CMP_BC_DE (0194)  ; Advance to the next byte, until end address reached
    01ba  03         INX BC
    01bb  c2 b5 01   JNZ OUT_NEXT_BYTE (01b5)

    01be  c1         POP BC                 ; Restore start address and switch to CRC calculation
    01bf  c3 7d 01   JMP CALC_CRC (017d)

; Command A - read data from tape
CMD_A_CONT:
    01c2  c5         PUSH BC
    01c3  d5         PUSH DE
    01c4  e5         PUSH HL
    01c5  f5         PUSH PSW

    01c6  f7         RST 6                  ; Read address offset to DE

    01c7  3e ff      MVI A, ff              ; Wait for a synchronization, then input a data byte

    01c9  cd 28 01   CALL IN_TAPE_BYTE (0128)   ; Read start address in HL
    01cc  67         MOV H, A
    01cd  cd ee 01   CALL IN_NEXT_BYTE (01ee)
    01d0  6f         MOV L, A

    01d1  19         DAD DE                 ; Apply offset
    01d2  44         MOV B, H               ; Store the calculated start address at BC
    01d3  4d         MOV C, L
    01d4  c5         PUSH BC                

    01d5  cd ee 01   CALL 01ee              ; Read end address to HL
    01d8  67         MOV H, A
    01d9  cd ee 01   CALL 01ee    
    01dc  6f         MOV L, A

    01dd  19         DAD DE                 ; And apply offset as well
    01de  eb         XCHG                   ; Store the calculated end address at DE

IN_LOOP:
    01df  cd ee 01   CALL 01ee              ; Read and store the data byte
    01e2  02         STAX B
    01e3  cd 94 01   CALL CMP_BC_DE (0194)  ; Continue until all the data bytes received
    01e6  03         INX B
    01e7  cd df 01   JNZ IN_LOOP (01df)

    01ea  c1         POP BC
    01eb  c3 7d 01   JMP CALC_CRC (017d)    ; Double check the CRC and finish


IN_NEXT_BYTE:
    01ee  3e 08      MVI A, 08              ; Set number of bits to receive
    01f0  cd 28 01   CALL IN_TAPE_BYTE (0128)
    01f3  c9         RET
    01f4  00         NOP

CMD_B_CONT:
    01f5  2a fe c3   LHLD c3fe              ; Load minutes and hours to HL
    01f8  3a fd c3   LDA c3fd               ; Load seconds to A
    01fb  ef         RST 5                  ; Display the time

    01fc  df         RST 3                  ; Repeat after a pause
    01fd  c3 f5 01   JMP CMD_B_CONT (01f5)


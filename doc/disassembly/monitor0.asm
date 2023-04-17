; Monitor0 is a primary firmware for the CPU module. Monitor0 is located in ROM
; at 0x0000-0x03ff address and provides basic routines for CPU module peripheral:
; - TBD
;
; Monitor0 exposes a few handy routines for the purposes of Monitor itself and the
; user application. Unlike typical approach, when CALL 3-byte instruction is used to
; execute these routines, the Monitor0 uses RSTx 1-byte instructions. This is clever
; solution in terms of packing code into a tiny ROM. Since RST addresses are spaced
; by 8 bytes, the routine implementation starts at RST address, and continues elsewhere.
;
; RST routines are:
; - RST 0 (address 0x0000) - reset routine
; - RST 3 (address 0x0018) - 1 second delay
; - RST 4 (address 0x0020) - wait for a button press, return key code in A
; - RST 5 (address 0x0028) - display A and HL registers on the LCD
; 
; The Monitor0 also interacts with the user with the following commands (entered
; using HEX keyboard)
; - 3   - Run an LCD test
; - 4   - Run memory test for the range of 0xc000 - 0xc400
;

; Reset entry point
RST0:
    ; Set up the stack pointer
    0000  31 ee c3   LXI SP, c3ee

    ; Prepare for displaying 11 on the LCD
    0003  3e 11      MVI A, 11
    0005  c3 3b 00   JMP RST0_CONT (003b)   ; Continuate elsewhere, as RST1 handler is located at 0x0008

0000                          c3 00 01 f7 eb c3 7d 00

CMD_5:
    000b

0010  d5 af 57 e7 07 c3 47 00 

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

0020             00 c3 00 c0          

CMD_6:
    0025

RST5:
    0028  32 00 90   STA 9000               ; Write A and HL to respective LCD address
    002b  22 01 90   SHLD 9001              
    002e  c9         RET
    002f  00         NOP

0030  f5 d7 57 d7 5f f1 c9 00 c3 c1 00 

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

0040                       07 07 07 b2 57 32 00 90 e7
0050  b2 32 00 90 d1 c9

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



0060                                            2b 3b
0070  3b af ef d7 77 df 23 c3 71 00 21 00 c0 e7 7e ef

CMD_2:
    007a

0080  23 c3 7d 00 f7 eb af ef df e9 21 00 c0 c3 71 00

CMD_7:
    0084

CMD_1:
    008a

0090  f3 f7 eb c3 71 00             df c6 11 fe 10 c2

CMD_C:
    0090

CMD_0:
    0091    

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

00a0           21 00 c0 af 77 7e b7 c2 bb 00 3d 77 7e

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
00bb

00b0                                   7e ef e7 c3 a6
00c0  00 f3 f5 c5 d5 e5 21 e4 00 11 fd c3 06 03 1a 3c
00d0  27 12 be c2 de 00 af 12 23 13 05 c2 ce 00 e1 d1
00e0  c1 f1 fb c9 60 60 24 c3 9a 01 c3 c2 01 c3 75 01

CMD_9:
    00e7

CMD_A:
    00ea

CMD_8:
    00ed

CMD_B:
    00f0

00f0  c3 f5 01 

; Command handlers addresses (low byte)
CMD_HANDLERS:
    db    91, 8a, 7a, 96, a3, 0b, 25, 84, ed, e7, ea, f0, 90       


0100  c5 d5 f5 57 0e 08 7a 07 57 3e 01 aa d3 a1 cd 21
0110  01 3e 00 aa d3 a1 cd 21 01 0d c2 06 01 f1 d1 c1
0120  c9 06 1e 05 c2 23 01 c9 c5 d5 0e 00 57 db a1 5f
0130  79 e6 7f 07 4f db a1 bb ca 35 01 e6 01 b1 4f cd
0140  6e 01 db a1 5f 7a b7 f2 63 01 79 fe e6 c2 57 01
0150  af 32 fc c3 c3 61 01 fe 19 c2 30 01 3e ff 32 fc
0160  c3 16 09 15 c2 30 01 3a fc c3 a9 d1 c1 c9 06 2d
0170  05 c2 70 01 c9 c5 d5 e5 f5 f7 42 4b f7 2e 00 65
0180  0a d5 5f 16 00 19 d1 cd 94 01 03 c2 80 01 ef f1
0190  e1 d1 c1 c7 7a b8 c0 7b b9 c9 c5 d5 e5 f5 f7 42
01a0  4b f7 c5 af 6f cf 2c c2 a5 01 3e e6 cf 78 cf 79
01b0  cf 7a cf 7b cf 0a cf cd 94 01 03 c2 b5 01 c1 c3
01c0  7d 01 c5 d5 e5 f5 f7 3e ff cd 28 01 67 cd ee 01
01d0  6f 19 44 4d c5 cd ee 01 67 cd ee 01 6f 19 eb cd
01e0  ee 01 02 cd 94 01 03 c2 df 01 c1 c3 7d 01 3e 08
01f0  cd 28 01 c9 00 2a fe c3 3a fd c3 ef df c3 f5 01
0200  cd 24 02 da 0a 02 cd 0e 02 c7 cd 19 02 c7 1a 77
0210  cd 94 01 1b 2b c2 0e 02 c9 0a 77 cd 94 01 03 23
0220  c2 19 02 c9 f7 d5 f7 eb 22 f2 c3 e1 22 f0 c3 f7
0230  eb 22 f4 c3 7d 93 6f 7c 9a 67 22 f8 c3 4d 44 2a
0240  f2 c3 e5 09 22 f6 c3 2a f0 c3 4d 44 d1 2a f4 c3
0250  7d 91 7c 98 d8 2a f6 c3 c9 7c ba c0 7d bb c9 cd
0260  24 02 cd 66 02 c7 2a f4 c3 56 e5 cd b9 02 60 e3
0270  78 fe 03 c2 a5 02 23 4e 23 46 2b e5 2a f0 c3 79
0280  95 78 9c da a3 02 2a f2 c3 7d 91 7c 98 da a3 02
0290  2a f8 c3 7d 81 5f 7c 88 57 e1 73 23 72 23 33 33
02a0  c3 ab 02 e1 2b c1 23 05 c2 a6 02 5d 54 2a f6 c3
02b0  23 cd 59 02 eb c2 69 02 c9 01 06 03 21 d3 02 7a
02c0  a6 23 be c8 23 0d c2 bf 02 0e 03 05 78 fe 01 c2
02d0  bf 02 c9 ff cd c7 c4 ff c3 c7 c2 e7 22 cf 01 c7
02e0  06 c7 c6 f7 d3 f7 eb 22 f0 c3 22 f4 c3 e5 f7 eb
02f0  22 f2 c3 22 f6 c3 f7 eb 22 fa c3 d1 7d 93 6f 7c
0300  9a 67 22 f8 c3 cd 66 02 c7 f7 d5 f7 eb 22 f2 c3
0310  f7 eb 22 fa c3 f7 eb 22 ee c3 e1 22 f0 c3 56 e5
0320  cd b9 02 60 e3 78 fe 03 c2 4a 03 23 5e 23 56 2b
0330  e5 2a fa c3 cd 59 02 c2 48 03 2a ee c3 eb e1 73
0340  23 72 23 33 33 c3 50 03 e1 2b c1 23 05 c2 4b 03
0350  5d 54 2a f2 c3 23 cd 59 02 eb c2 1e 03 c7 f7 eb
0360  22 f0 c3 4d 44 f7 6b 62 22 f2 c3 23 22 f6 c3 cd
0370  0e 02 af 77 e5 23 22 f4 c3 21 01 00 22 f8 c3 cd
0380  66 02 e1 7e ef d7 77 c7 f7 eb 22 f0 c3 22 f4 c3
0390  4d 44 e5 f7 6b 62 22 f2 c3 e1 c5 03 cd 19 02 af
03a0  77 2b 22 f6 c3 21 ff ff 22 f8 c3 cd 66 02 e1 c3
03b0  7d 00 f7 4b 42 f7 d5 f7 eb d1 0a be c2 d4 03 79
03c0  bb c2 cf 03 78 ba c2 cf 03 3e 11 6f 67 ef c7 03
03d0  23 c3 ba 03 f5 7e ef d7 77 f1 c3 ba 03 c5 d5 e5
03e0  f5 7e ef e7 e3 3e af ef e7 e3 69 60 3e bc ef e7
03f0  eb 3e de ef e7 f1 e1 d1 c1 c9 ff ff ff ff ff ff




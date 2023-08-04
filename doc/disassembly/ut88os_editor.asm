; General description TBD

;
; Variables:
; - f6df    - ???
; - f6e0    - 0x3f bytes of buffer ????
; - f721    - 
; - f722    - 
; - f723    - 
; - f724    - 
; - f725    - Cursor Y position (counting from top-left corner)
; - f726    - 
; - f727    - end of file pointer (points to the next symbol after the last text char)
; - f729    - ????
; - f72b    - ????

COMMAND_E_EDITOR:
    cb00  0e 1f      MVI C, 1f                  ; Clear screen
    cb02  cd 09 f8   CALL PUT_CHAR (f809)

    cb05  21 00 00   LXI HL, 0000               ; Save SP value
    cb08  39         DAD SP
    cb09  22 2f f7   SHLD SAVE_SP (f72f)

EDITOR_MAIN_LOOP:
    cb0c  2a 2f f7   LHLD SAVE_SP (f72f)        ; Restore SP
    cb0f  f9         SPHL

    cb10  cd 12 cc   CALL PRINT_HELLO_PROMPT (cc12) ; Print prompt

    cb13  21 00 30   LXI HL, 3000               ; ???? text start, and current cursor position?????
    cb16  22 29 f7   SHLD f729
    cb19  22 2b f7   SHLD f72b

    cb1c  cd 9b cf   CALL GET_END_OF_FILE (cf9b); ???? get end of file pointer
    cb1f  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    cb22  cd 6f ce   CALL CLEAR_BUFFER (ce6f)

    cb25  eb         XCHG                       ; ????? Store 0x00
    cb26  32 22 f7   STA f722
    cb29  32 26 f7   STA f726

    cb2c  3d         DCR A                      ; ???? Store 0xff
    cb2d  32 21 f7   STA f721
    cb30  32 23 f7   STA f723
    cb33  32 25 f7   STA CURSOR_Y (f725)

    cb36  2b         DCX HL                     ; ???? Store 0xff to f6df
    cb37  77         MOV M, A
    cb38  23         INX HL

    cb39  3e 03      MVI A, 03                  ; ????
    cb3b  32 24 f7   STA f724

????:
    cb3e  01 3e cb   LXI BC, cb3e               ; Character processing will return back here
    cb41  c5         PUSH BC

    cb42  cd b4 cb   CALL GET_KBD_KEY (cbb4)
    cb45  ca 95 cb   JZ cb95

    cb48  fe 08      CPI A, 08                  ; Check if left arrow is pressed
    cb4a  ca 01 ce   JZ ce01

    cb4d  fe 18      CPI A, 18                  ; Check if right arrow is pressed
    cb4f  ca 85 cb   JZ cb85

    cb52  fe 19      CPI A, 19                  ; Check if up arrow is pressed
    cb54  ca 1f ce   JZ ce1f

    cb57  fe 1a      CPI A, 1a                  ; Check if down arrow is pressed
    cb59  ca 34 cf   JZ cf34

    cb5c  fe 0c      CPI A, 0c                  ; Check if home key is pressed
    cb5e  ca b1 ce   JZ ceb1

    cb61  fe 1f      CPI A, 1f                  ; Check if clear screen key is pressed
    cb63  c2 6b cb   JNZ cb6b

cb66  cd ce ce   CALL cece
cb69  c1         POP BC
cb6a  c9         RET

????:
    cb6b  fe 0d      CPI A, 0d                  ; Check if Return key is pressed
    cb6d  ca db cc   JZ PILOT_TONE (ccdb)

    cb70  cd aa cb   CALL cbaa

cb73  3a 26 f7   LDA f726
cb76  b7         ORA A
cb77  c2 7f cb   JNZ cb7f

cb7a  c5         PUSH BC
cb7b  cd 62 d0   CALL d062
cb7e  c1         POP BC
????:
cb7f  7e         MOV A, M
cb80  b7         ORA A
cb81  ca db cc   JZ PILOT_TONE (ccdb)
cb84  71         MOV M, C
????:
cb85  3a 23 f7   LDA f723
cb88  fe 3e      CPI A, 3e
cb8a  d2 db cc   JNC PILOT_TONE (ccdb)
cb8d  3c         INR A
cb8e  32 23 f7   STA f723
cb91  23         INX HL
cb92  c3 09 f8   JMP PUT_CHAR (f809)

????:
cb95  e5         PUSH HL
cb96  21 4a d3   LXI HL, d34a
????:
cb99  7e         MOV A, M
cb9a  b7         ORA A
cb9b  ca da cc   JZ ccda

cb9e  b9         CMP C
cb9f  23         INX HL
cba0  5e         MOV E, M
cba1  23         INX HL
cba2  56         MOV D, M
cba3  23         INX HL
cba4  c2 99 cb   JNZ cb99

cba7  e1         POP HL
cba8  d5         PUSH DE
cba9  c9         RET

????:
cbaa  7e         MOV A, M
cbab  b7         ORA A
cbac  c0         RNZ

cbad  2b         DCX HL
cbae  b6         ORA M
cbaf  23         INX HL
cbb0  c0         RNZ

cbb1  c3 dc cc   JMP PILOT_TONE_1 (ccdc)


GET_KBD_KEY:
    cbb4  cd 03 f8   CALL KBD_INPUT (f803)      ; Input char
    cbb7  4f         MOV C, A

    cbb8  db 05      IN 05                      ; Check if high bit in Port C is set (BUG? MSB of the port C
    cbba  e6 80      ANI A, 80                  ; is not connected, shall be 0x02 for Ctrl key)

    cbbc  79         MOV A, C                   ; Return entered char in A
    cbbd  c9         RET

????_COMMAND_X:
cbbe  e5         PUSH HL
cbbf  2a 2b f7   LHLD f72b
cbc2  e3         XTHL
cbc3  c3 cb cb   JMP cbcb

????_COMMAND_L:
cbc6  e5         PUSH HL
cbc7  21 00 30   LXI HL, 3000
cbca  e3         XTHL
????:
cbcb  cd fd cb   CALL CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT (cbfd)
cbce  cd 20 cc   CALL cc20
cbd1  dc 6f ce   CC CLEAR_BUFFER (ce6f)
cbd4  44         MOV B, H
cbd5  4d         MOV C, L
cbd6  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
cbd9  eb         XCHG
cbda  e1         POP HL
cbdb  e5         PUSH HL
????:
cbdc  c5         PUSH BC
cbdd  e5         PUSH HL
????:
cbde  0a         LDAX BC
cbdf  b7         ORA A
cbe0  ca f0 cc   JZ ccf0
cbe3  be         CMP M
cbe4  23         INX HL
cbe5  03         INX BC
cbe6  ca de cb   JZ cbde
cbe9  cd ea cc   CALL CMP_HL_DE (ccea)
cbec  e1         POP HL
cbed  c1         POP BC
cbee  23         INX HL
cbef  da dc cb   JC cbdc
cbf2  0e 3f      MVI C, 3f
cbf4  cd 09 f8   CALL PUT_CHAR (f809)

; Produce a error sound, and exit to the main loop
BEEP_AND_EXIT:
    cbf7  cd db cc   CALL PILOT_TONE (ccdb)
    cbfa  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c)


CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT:
    cbfd  f5         PUSH PSW                   ; ????
    cbfe  cd ce ce   CALL cece
    cc01  f1         POP PSW

    cc02  0e 1f      MVI C, 1f                  ; Clear screen
    cc04  cd 09 f8   CALL PUT_CHAR (f809)

    cc07  cd 12 cc   CALL PRINT_HELLO_PROMPT (cc12) ; Print the prompt, then print command symbol

; Print char in A register, then print a space
PUT_CHAR_AND_SPACE:
    cc0a  cd 81 cd   CALL PUT_CHAR_A (cd81)     ; Print char

    cc0d  0e 20      MVI C, 20                  ; Print space
    cc0f  c3 09 f8   JMP PUT_CHAR (f809)


; Print greetings string, and command prompt
PRINT_HELLO_PROMPT:
    cc12  e5         PUSH HL
    cc13  21 23 d3   LXI HL, HELLO_STR (d323)

    cc16  cd 18 f8   CALL PRINT_STRING (f818)
    cc19  e1         POP HL
    cc1a  c9         RET


; Move cursor to the top-left corner of the screen
HOME_SCREEN_CURSOR:
    cc1b  0e 0c      MVI C, 0c
    cc1d  c3 09 f8   JMP PUT_CHAR (f809)


????:
cc20  cd 6f ce   CALL CLEAR_BUFFER (ce6f)
cc23  62         MOV H, D
cc24  6b         MOV L, E
cc25  32 23 f7   STA f723

????:
cc28  cd ca cc   CALL PRINT_HASH_CURSOR (ccca)
cc2b  cd b4 cb   CALL GET_KBD_KEY (cbb4)
cc2e  c2 68 cc   JNZ cc68

cc31  fe 20      CPI A, 20
cc33  c2 d4 cc   JNZ ccd4

cc36  3a 24 f7   LDA f724
cc39  2f         CMA
cc3a  4f         MOV C, A
cc3b  3a 23 f7   LDA f723
cc3e  47         MOV B, A
cc3f  a1         ANA C
cc40  91         SUB C
cc41  fe 40      CPI A, 40
cc43  d2 d4 cc   JNC ccd4
cc46  90         SUB B
cc47  47         MOV B, A
????:
cc48  4e         MOV C, M
cc49  79         MOV A, C
cc4a  b7         ORA A
cc4b  c2 51 cc   JNZ cc51
cc4e  0e 20      MVI C, 20
cc50  71         MOV M, C
????:
cc51  3a 23 f7   LDA f723
cc54  3c         INR A
cc55  fe 3f      CPI A, 3f
cc57  d2 d4 cc   JNC ccd4
cc5a  32 23 f7   STA f723
cc5d  23         INX HL
cc5e  cd 09 f8   CALL PUT_CHAR (f809)
cc61  05         DCR B
cc62  c2 48 cc   JNZ cc48
cc65  c3 28 cc   JMP cc28
????:
cc68  b7         ORA A
cc69  ca d4 cc   JZ ccd4
cc6c  fe 0c      CPI A, 0c
cc6e  ca d4 cc   JZ ccd4
cc71  fe 1f      CPI A, 1f
cc73  ca a8 cc   JZ cca8
cc76  4f         MOV C, A
cc77  fe 08      CPI A, 08
cc79  ca b1 cc   JZ ccb1
cc7c  fe 18      CPI A, 18
cc7e  ca ac cc   JZ ccac
cc81  fe 19      CPI A, 19
cc83  ca d4 cc   JZ ccd4
cc86  fe 1a      CPI A, 1a
cc88  ca d4 cc   JZ ccd4
cc8b  d6 0d      SUI A, 0d
cc8d  c2 ab cc   JNZ ccab
cc90  77         MOV M, A
cc91  3a 23 f7   LDA f723
cc94  3c         INR A
cc95  32 22 f7   STA f722
cc98  eb         XCHG
cc99  0e 0a      MVI C, 0a
cc9b  cd 09 f8   CALL PUT_CHAR (f809)

; Move cursor to the beginning of the current line
HOME_CURSOR:
    cc9e  0e 0a      MVI C, 0a                  ; Print CR symbol
    cca0  cd 09 f8   CALL PUT_CHAR (f809)
    cca3  0e 19      MVI C, 19                  ; Step one row up
    cca5  c3 09 f8   JMP PUT_CHAR (f809)

????:
cca8  eb         XCHG
cca9  37         STC
ccaa  c9         RET
????:
ccab  71         MOV M, C
????:
ccac  06 01      MVI B, 01
ccae  c3 48 cc   JMP cc48
????:
ccb1  3a 23 f7   LDA f723
ccb4  3d         DCR A
ccb5  fa d4 cc   JM ccd4
ccb8  32 23 f7   STA f723
ccbb  3e 20      MVI A, 20
ccbd  cd 81 cd   CALL PUT_CHAR_A (cd81)
ccc0  2b         DCX HL
ccc1  cd 09 f8   CALL PUT_CHAR (f809)
ccc4  cd 09 f8   CALL PUT_CHAR (f809)
ccc7  c3 28 cc   JMP cc28

PRINT_HASH_CURSOR:
    ccca  0e 23      MVI C, 23                  ; Print '#' symbol, then move cursor left
    cccc  cd 09 f8   CALL PUT_CHAR (f809)

; Print 'move left' symbol
PRINT_BACKSPACE:
    cccf  0e 08      MVI C, 08                  ; Print 'move left' symbol
    ccd1  c3 09 f8   JMP PUT_CHAR (f809)

????:
ccd4  cd db cc   CALL PILOT_TONE (ccdb)
ccd7  c3 28 cc   JMP cc28
????:
ccda  e1         POP HL


; Output a pilot tone (0x55 times byte 0x55)
; ???? Beep?
PILOT_TONE:
    ccdb  c5         PUSH BC

PILOT_TONE_1:
    ccdc  f5         PUSH PSW                   ; Output 0x55 times byte 0x55
    ccdd  3e 55      MVI A, 55
    ccdf  47         MOV B, A

PILOT_TONE_LOOP:
    cce0  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output a byte until counter is zero
    cce3  05         DCR B
    cce4  c2 e0 cc   JNZ PILOT_TONE_LOOP (cce0)

    cce7  f1         POP PSW
    cce8  c1         POP BC
    cce9  c9         RET


CMP_HL_DE:
    ccea  7c         MOV A, H                   ; Compare high bytes
    cceb  ba         CMP D
    ccec  c0         RNZ

    cced  7d         MOV A, L                   ; Compare low bytes
    ccee  bb         CMP E
    ccef  c9         RET

????:
ccf0  c1         POP BC
ccf1  c1         POP BC
ccf2  d1         POP DE
ccf3  7e         MOV A, M
ccf4  fe 0d      CPI A, 0d
ccf6  c2 fa cc   JNZ ccfa
ccf9  2b         DCX HL
????:
ccfa  cd 53 ce   CALL ce53

????:
ccfd  cd 1b cc   CALL HOME_SCREEN_CURSOR (cc1b)

cd00  22 29 f7   SHLD f729

cd03  af         XRA A
cd04  32 23 f7   STA f723

cd07  06 1f      MVI B, 1f

????:
cd09  0e 3f      MVI C, 3f
cd0b  cd 6f ce   CALL CLEAR_BUFFER (ce6f)

????:
cd0e  7e         MOV A, M
cd0f  fe 0d      CPI A, 0d
cd11  c2 74 cd   JNZ cd74

    cd14  3e 2a      MVI A, 2a                  ; Print '*' prompt
    cd16  cd 81 cd   CALL PUT_CHAR_A (cd81)

    cd19  c5         PUSH BC                    ; Clear rest of the line with spaces
    cd1a  41         MOV B, C
    cd1b  3e 01      MVI A, 01
    cd1d  0e 20      MVI C, 20
    cd1f  cd 97 d0   CALL PUT_CHAR_BLOCK (d097)
    cd22  c1         POP BC

    cd23  23         INX HL                     ; Load the marker after last text symbol
    cd24  7e         MOV A, M
    cd25  2b         DCX HL

    cd26  b7         ORA A                      ; Check if it is >=0x80
    cd27  fa 32 cd   JM cd32

    cd2a  05         DCR B                      ; ????
    cd2b  ca 33 cd   JZ cd33

    cd2e  23         INX HL                     ; ????
    cd2f  c3 09 cd   JMP cd09


????:
    cd32  05         DCR B                      ; ????

????:
    cd33  3e 08      MVI A, 08                  ; Move 2 characters back
    cd35  cd 81 cd   CALL PUT_CHAR_A (cd81)
    cd38  cd 81 cd   CALL PUT_CHAR_A (cd81)

    cd3b  3e 3f      MVI A, 3f                  ; ????? C = 0x3f - C
    cd3d  91         SUB C                      ; ???? Update X coordinate????
    cd3e  4f         MOV C, A

    cd3f  32 21 f7   STA f721                   ; ????
    cd42  32 22 f7   STA f722

    cd45  3e 1e      MVI A, 1e                  ; ???? Update Y coordinate????
    cd47  90         SUB B
    cd48  32 25 f7   STA CURSOR_Y (f725)

    cd4b  79         MOV A, C                   ; Change sign of C (X coordinate ????)
    cd4c  2f         CMA
    cd4d  3c         INR A

    cd4e  ca 55 cd   JZ cd55                    ; Skip next operation if C is zero

    cd51  4f         MOV C, A                   ; HL -= X coordinate ???
    cd52  06 ff      MVI B, ff
    cd54  09         DAD BC

????:
    cd55  22 2b f7   SHLD f72b                  ; ????

    cd58  11 e0 f6   LXI DE, f6e0               ; Load start buffer address
    cd5b  eb         XCHG

????:
    cd5c  3a 25 f7   LDA CURSOR_Y (f725)        ; Calculate how many lines below the cursor
    cd5f  f5         PUSH PSW
    cd60  47         MOV B, A
    cd61  3e 1f      MVI A, 1f
    cd63  90         SUB B

    cd64  01 20 40   LXI BC, 4020               ; Clear those lines
    cd67  cd 97 d0   CALL PUT_CHAR_BLOCK (d097)

    cd6a  cd 16 cc   CALL HOME_SCREEN_CURSOR (cc1b) ; Move cursor to the top-left position
                                                    ; BUG: Wrong Scan, shall be cc1b, not cc16

    cd6d  f1         POP PSW                    ; Move cursor Y positions down
    cd6e  01 1a 01   LXI BC, 011a
    cd71  c3 97 d0   JMP PUT_CHAR_BLOCK (d097)

????:
cd74  0d         DCR C
cd75  12         STAX DE
cd76  ca 0f ce   JZ ce0f

cd79  cd 81 cd   CALL PUT_CHAR_A (cd81)
cd7c  23         INX HL
cd7d  13         INX DE
cd7e  c3 0e cd   JMP cd0e

PUT_CHAR_A:
    cd81  c5         PUSH BC
    cd82  4f         MOV C, A
    cd83  cd 09 f8   CALL PUT_CHAR (f809)
    cd86  c1         POP BC
    cd87  c9         RET


????_COMMAND_W:
cd88  f5         PUSH PSW
cd89  3a 24 f7   LDA f724
cd8c  fe 07      CPI A, 07
cd8e  c2 96 cd   JNZ cd96
cd91  3e 03      MVI A, 03
cd93  c3 98 cd   JMP cd98
????:
cd96  3e 07      MVI A, 07
????:
cd98  32 24 f7   STA f724
cd9b  f1         POP PSW
cd9c  c9         RET

????_COMMAND_Y:
cd9d  f5         PUSH PSW
cd9e  3a 26 f7   LDA f726
cda1  2f         CMA
cda2  32 26 f7   STA f726
cda5  f1         POP PSW
cda6  c9         RET

????_COMMAND_R:
cda7  d5         PUSH DE
cda8  e5         PUSH HL
cda9  11 2d 20   LXI DE, 202d
cdac  2a 5c f7   LHLD f75c
cdaf  cd ea cc   CALL CMP_HL_DE (ccea)
cdb2  c2 b8 cd   JNZ cdb8
cdb5  11 14 10   LXI DE, 1014
????:
cdb8  eb         XCHG
cdb9  22 5c f7   SHLD f75c
cdbc  e1         POP HL
cdbd  d1         POP DE
cdbe  c9         RET


????_COMMAND_F:
cdbf  cd fd cb   CALL CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT (cbfd)
cdc2  21 34 d3   LXI HL, d334
cdc5  cd 18 f8   CALL PRINT_STRING (f818)
cdc8  e5         PUSH HL
cdc9  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
cdcc  cd f9 cd   CALL cdf9
cdcf  eb         XCHG
cdd0  e1         POP HL
cdd1  cd 18 f8   CALL PRINT_STRING (f818)
cdd4  e5         PUSH HL
cdd5  21 00 30   LXI HL, 3000
cdd8  eb         XCHG
cdd9  e5         PUSH HL
cdda  cd f2 cd   CALL cdf2
cddd  23         INX HL
cdde  cd f9 cd   CALL cdf9
cde1  d1         POP DE
cde2  e1         POP HL
cde3  cd 18 f8   CALL PRINT_STRING (f818)
cde6  21 ff 9f   LXI HL, 9fff
cde9  cd f2 cd   CALL cdf2
cdec  cd f9 cd   CALL cdf9
cdef  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c)
????:
cdf2  7d         MOV A, L
cdf3  93         SUB E
cdf4  6f         MOV L, A
cdf5  7c         MOV A, H
cdf6  9a         SBB D
cdf7  67         MOV H, A
cdf8  c9         RET
????:
cdf9  7c         MOV A, H
cdfa  cd 15 f8   CALL f815
cdfd  7d         MOV A, L
cdfe  c3 15 f8   JMP f815
????:
ce01  3a 23 f7   LDA f723
ce04  3d         DCR A
ce05  fa db cc   JM PILOT_TONE (ccdb)

ce08  32 23 f7   STA f723
ce0b  2b         DCX HL
ce0c  c3 09 f8   JMP PUT_CHAR (f809)
????:
ce0f  11 f6 d2   LXI DE, LONG_STRING_STR (d2f6)

; Print error
; DE - pointer to error type
PRINT_ERROR:
    ce12  21 ee d2   LXI HL, ERROR_STR (d2ee)   ; Print ERROR: prefix
    ce15  cd 18 f8   CALL PRINT_STRING (f818)

    ce18  eb         XCHG                       ; Print the error type
    ce19  cd 18 f8   CALL PRINT_STRING (f818)

    ce1c  c3 f7 cb   JMP BEEP_AND_EXIT (cbf7)   ; ?????

????:
ce1f  cd 80 ce   CALL ce80
ce22  fa b4 ce   JM ceb4

ce25  2a 2b f7   LHLD f72b
ce28  cd 51 ce   CALL ce51
????:
ce2b  22 2b f7   SHLD f72b
ce2e  cd 6f ce   CALL CLEAR_BUFFER (ce6f)
ce31  d5         PUSH DE
ce32  06 00      MVI B, 00
????:
ce34  7e         MOV A, M
ce35  fe 0d      CPI A, 0d
ce37  ca 41 ce   JZ ce41
ce3a  12         STAX DE
ce3b  04         INR B
ce3c  23         INX HL
ce3d  13         INX DE
ce3e  c3 34 ce   JMP ce34
????:
ce41  78         MOV A, B
ce42  32 21 f7   STA f721
ce45  32 22 f7   STA f722
ce48  e1         POP HL
ce49  3a 23 f7   LDA f723
ce4c  5f         MOV E, A
ce4d  16 00      MVI D, 00
ce4f  19         DAD DE
ce50  c9         RET
????:
ce51  2b         DCX HL
ce52  2b         DCX HL
????:
ce53  c1         POP BC
ce54  cd ea cc   CALL CMP_HL_DE (ccea)
ce57  ca fd cc   JZ ccfd
ce5a  7e         MOV A, M
ce5b  fe 0d      CPI A, 0d
ce5d  c5         PUSH BC
ce5e  23         INX HL
ce5f  c8         RZ
ce60  c3 51 ce   JMP ce51
????:
ce63  cd ea cc   CALL CMP_HL_DE (ccea)
ce66  ca fd cc   JZ ccfd
ce69  cd 51 ce   CALL ce51
ce6c  c3 fd cc   JMP ccfd

CLEAR_BUFFER:
    ce6f  c5         PUSH BC                    ; Will clean 0x3f bytes
    ce70  06 3f      MVI B, 3f

    ce72  11 e0 f6   LXI DE, f6e0               ; Load buffer address
    ce75  d5         PUSH DE

    ce76  af         XRA A                      ; Fill with zeros

CLEAR_BUFFER_LOOP:
    ce77  12         STAX DE                    ; Clear byte

    ce78  13         INX DE                     ; Advance to the next byte, until all bytes are cleared
    ce79  05         DCR B
    ce7a  c2 77 ce   JNZ CLEAR_BUFFER_LOOP (ce77)

    ce7d  d1         POP DE                     ; Exit
    ce7e  c1         POP BC
    ce7f  c9         RET

????:
ce80  cd 09 f8   CALL PUT_CHAR (f809)
ce83  cd ce ce   CALL cece
ce86  21 25 f7   LXI HL, CURSOR_Y (f725)
ce89  35         DCR M
ce8a  2a 29 f7   LHLD f729
ce8d  11 00 30   LXI DE, 3000
ce90  c9         RET

?????_UP:
ce91  cd ce ce   CALL cece
ce94  2a 29 f7   LHLD f729
ce97  06 1e      MVI B, 1e

????:
ce99  11 00 30   LXI DE, 3000

????:
ce9c  cd ea cc   CALL CMP_HL_DE (ccea)
ce9f  ca fd cc   JZ ccfd

cea2  2e 7e      MVI L, 7e
cea4  fe 0d      CPI A, 0d
cea6  c2 9c ce   JNZ ce9c

cea9  05         DCR B
ceaa  c2 9c ce   JNZ ce9c

cead  23         INX HL
ceae  c3 fd cc   JMP ccfd

????:
ceb1  cd 80 ce   CALL ce80
????:
ceb4  fc 63 ce   CM ce63
ceb7  af         XRA A
ceb8  32 23 f7   STA f723
cebb  32 25 f7   STA CURSOR_Y (f725)
cebe  cd 1b cc   CALL HOME_SCREEN_CURSOR (cc1b)
cec1  2a 29 f7   LHLD f729
cec4  c3 26 ce   JMP ce26
????:
cec7  3a 23 f7   LDA f723
ceca  b7         ORA A
cecb  c2 dc cc   JNZ PILOT_TONE_1 (ccdc)

????:
cece  3a 21 f7   LDA f721
ced1  b7         ORA A
ced2  f8         RM

ced3  4f         MOV C, A
ced4  06 00      MVI B, 00
ced6  2a 2b f7   LHLD f72b
ced9  e5         PUSH HL
ceda  09         DAD BC

cedb  c2 df ce   JNZ cedf

cede  2b         DCX HL

????:
cedf  3a 22 f7   LDA f722
cee2  91         SUB C

cee3  5f         MOV E, A
cee4  16 00      MVI D, 00

cee6  fc fe ce   CM cefe
cee9  c4 18 cf   CNZ cf18
ceec  d1         POP DE

ceed  21 e0 f6   LXI HL, f6e0

????:
cef0  7e         MOV A, M
cef1  b7         ORA A
cef2  c2 f7 ce   JNZ cef7
cef5  3e 0d      MVI A, 0d
????:
cef7  12         STAX DE
cef8  c8         RZ
cef9  23         INX HL
cefa  13         INX DE
cefb  c3 f0 ce   JMP cef0

????:
cefe  15         DCR D
ceff  e5         PUSH HL
cf00  19         DAD DE
cf01  44         MOV B, H
cf02  4d         MOV C, L
cf03  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
cf06  e5         PUSH HL
cf07  19         DAD DE
cf08  22 27 f7   SHLD END_OF_FILE_PTR (f727)
cf0b  d1         POP DE
cf0c  e1         POP HL
????:
cf0d  7e         MOV A, M
cf0e  02         STAX BC
cf0f  cd ea cc   CALL CMP_HL_DE (ccea)
cf12  c8         RZ
cf13  23         INX HL
cf14  03         INX BC
cf15  c3 0d cf   JMP cf0d
????:
cf18  23         INX HL
cf19  e5         PUSH HL
cf1a  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
cf1d  e5         PUSH HL
cf1e  19         DAD DE
cf1f  cd aa cf   CALL CHECK_FILE_SIZE (cfaa)
cf22  44         MOV B, H
cf23  4d         MOV C, L
cf24  22 27 f7   SHLD END_OF_FILE_PTR (f727)
cf27  e1         POP HL
cf28  d1         POP DE

; Shift string right (copy string from last to first symbol)
; DE - start of source string
; HL - end of source string
; BC - end of target string
SHIFT_STR_RIGHT:
    cf29  7e         MOV A, M                   ; Copy one symbol
    cf2a  02         STAX BC

    cf2b  cd ea cc   CALL CMP_HL_DE (ccea)      ; Stop when reached the last symbol to copy
    cf2e  c8         RZ

    cf2f  2b         DCX HL                     ; Move to the previous symbol, and repeat
    cf30  0b         DCX BC
    cf31  c3 29 cf   JMP SHIFT_STR_RIGHT (cf29)

????:
cf34  3a 25 f7   LDA CURSOR_Y (f725)
cf37  b7         ORA A
cf38  fa 0e d0   JM d00e

cf3b  0e 1a      MVI C, 1a
cf3d  cd 09 f8   CALL PUT_CHAR (f809)
cf40  cd ce ce   CALL cece
cf43  cd 89 cf   CALL cf89
cf46  21 25 f7   LXI HL, CURSOR_Y (f725)
cf49  34         INR M
cf4a  7e         MOV A, M
cf4b  fe 1f      CPI A, 1f
cf4d  f2 5e cf   JP cf5e
cf50  3a 22 f7   LDA f722
cf53  4f         MOV C, A
cf54  2a 2b f7   LHLD f72b
cf57  06 00      MVI B, 00
cf59  09         DAD BC
cf5a  23         INX HL
cf5b  c3 2b ce   JMP ce2b
????:
cf5e  2a 29 f7   LHLD f729
????:
cf61  7e         MOV A, M
cf62  d6 0d      SUI A, 0d
cf64  23         INX HL
cf65  c2 61 cf   JNZ cf61
cf68  c3 fd cc   JMP ccfd

????_DOWN:
cf6b  cd ce ce   CALL cece
cf6e  cd 89 cf   CALL cf89
cf71  2a 29 f7   LHLD f729
cf74  06 1f      MVI B, 1f
????:
cf76  7e         MOV A, M
cf77  fe 0d      CPI A, 0d
cf79  ca 80 cf   JZ cf80
????:
cf7c  23         INX HL
cf7d  c3 76 cf   JMP cf76
????:
cf80  05         DCR B
cf81  c2 7c cf   JNZ cf7c

????:
cf84  06 02      MVI B, 02
cf86  c3 99 ce   JMP ce99

????:
cf89  2a 2b f7   LHLD f72b
cf8c  3a 22 f7   LDA f722
cf8f  4f         MOV C, A
cf90  06 00      MVI B, 00
cf92  09         DAD BC
cf93  23         INX HL
cf94  7e         MOV A, M
cf95  b7         ORA A
cf96  f0         RP
cf97  c1         POP BC
cf98  c3 fe d0   JMP d0fe


GET_END_OF_FILE:
    cf9b  21 00 30   LXI HL, 3000               ; Set the start address

GET_END_OF_FILE_LOOP:
    cf9e  7e         MOV A, M                   ; Check the next char. Return if EOF char (>=0x80) is found
    cf9f  b7         ORA A
    cfa0  f8         RM

    cfa1  06 00      MVI B, 00                  ; Check content size does not exceed 0x9fff
    cfa3  cd aa cf   CALL CHECK_FILE_SIZE (cfaa)

    cfa6  23         INX HL                     ; Advance to the next byte and repeat
    cfa7  c3 9e cf   JMP GET_END_OF_FILE_LOOP (cf9e)


CHECK_FILE_SIZE:
    cfaa  eb         XCHG                       ; Compare HL with 0x9fff
    cfab  21 ff 9f   LXI HL, 9fff
    cfae  eb         XCHG

    cfaf  cd ea cc   CALL CMP_HL_DE (ccea)      ; Return if HL has not exceeded 0x9fff
    cfb2  d8         RC

    cfb3  36 ff      MVI M, ff                  ; Make sure text is truncated at 0x9fff

    cfb5  11 02 d3   LXI DE, LONG_FILE_STR (d302)   ; Inform the user about file is too long
    cfb8  c3 12 ce   JMP PRINT_ERROR (ce12)


????_COMMAND_D:
cfbb  cd c7 ce   CALL cec7
cfbe  2a 29 f7   LHLD f729
cfc1  22 31 f7   SHLD f731
cfc4  2a 2b f7   LHLD f72b
cfc7  22 2d f7   SHLD f72d
cfca  cd ca cc   CALL PRINT_HASH_CURSOR (ccca)
????:
cfcd  cd b4 cb   CALL GET_KBD_KEY (cbb4)
cfd0  ca e4 cf   JZ cfe4
cfd3  d6 19      SUI A, 19
cfd5  ca 3f d0   JZ d03f
cfd8  3d         DCR A
cfd9  ca 14 d0   JZ d014
cfdc  fe 05      CPI A, 05
cfde  ca 0e d0   JZ d00e
cfe1  c3 ee cf   JMP cfee
????:
cfe4  fe 1a      CPI A, 1a
cfe6  ca 23 d0   JZ d023
cfe9  fe 44      CPI A, 44
cfeb  ca f4 cf   JZ cff4
????:
cfee  cd db cc   CALL PILOT_TONE (ccdb)
cff1  c3 cd cf   JMP cfcd
????:
cff4  2a 27 f7   LHLD END_OF_FILE_PTR (f727)
cff7  eb         XCHG
cff8  2a 31 f7   LHLD f731
cffb  22 29 f7   SHLD f729
cffe  2a 2d f7   LHLD f72d
d001  44         MOV B, H
d002  4d         MOV C, L
d003  2a 2b f7   LHLD f72b
d006  cd 0d cf   CALL cf0d
d009  60         MOV H, B
d00a  69         MOV L, C
d00b  22 27 f7   SHLD END_OF_FILE_PTR (f727)

????:
d00e  2a 29 f7   LHLD f729
d011  c3 fd cc   JMP ccfd

????:
d014  cd 2f d0   CALL d02f
d017  ca ee cf   JZ cfee
d01a  cd 34 cf   CALL cf34
????:
d01d  cd 9e cc   CALL HOME_CURSOR (cc9e)
d020  c3 cd cf   JMP cfcd
????:
d023  cd 2f d0   CALL d02f
d026  ca ee cf   JZ cfee
d029  cd 6b cf   CALL cf6b
d02c  c3 1d d0   JMP d01d
????:
d02f  e5         PUSH HL
d030  2a 2b f7   LHLD f72b
d033  3a 22 f7   LDA f722
d036  5f         MOV E, A
d037  16 00      MVI D, 00
d039  19         DAD DE
d03a  23         INX HL
d03b  7e         MOV A, M
d03c  3c         INR A
d03d  e1         POP HL
d03e  c9         RET
????:
d03f  2a 2b f7   LHLD f72b
d042  eb         XCHG
d043  2a 2d f7   LHLD f72d
d046  cd ea cc   CALL CMP_HL_DE (ccea)
d049  ca ee cf   JZ cfee
d04c  3a 25 f7   LDA CURSOR_Y (f725)
d04f  b7         ORA A
d050  c2 59 d0   JNZ d059
d053  cd b1 ce   CALL ceb1
d056  c3 cd cf   JMP cfcd
????:
d059  cd 1f ce   CALL ce1f
d05c  c3 cd cf   JMP cfcd

????_RIGHT:
d05f  cd aa cb   CALL cbaa

????:
d062  11 22 f7   LXI DE, f722
d065  1a         LDAX DE

d066  3c         INR A
d067  fe 3f      CPI A, 3f
d069  d2 db cc   JNC PILOT_TONE (ccdb)

d06c  12         STAX DE
d06d  e5         PUSH HL

d06e  cd cb d0   CALL SEARCH_END_OF_STRING (d0cb)
d071  23         INX HL
d072  44         MOV B, H
d073  4d         MOV C, L

d074  d1         POP DE
d075  2b         DCX HL

d076  cd 29 cf   CALL SHIFT_STR_RIGHT (cf29)
d079  36 20      MVI M, 20

????:
d07b  cd 18 f8   CALL PRINT_STRING (f818)

d07e  0e 2a      MVI C, 2a                  ; Print '*'
d080  cd 09 f8   CALL PUT_CHAR (f809)

d083  0e 20      MVI C, 20                  ; Print space
d085  cd 09 f8   CALL PUT_CHAR (f809)

d088  cd cf cc   CALL PRINT_BACKSPACE (cccf)
d08b  cd 9e cc   CALL HOME_CURSOR (cc9e)
d08e  3a 23 f7   LDA f723
d091  47         MOV B, A
d092  0e 18      MVI C, 18
d094  3e 01      MVI A, 01
d096  eb         XCHG

; Print char in C register A*B times
PUT_CHAR_BLOCK:
    d097  b7         ORA A                          ; Do not print anything if A is zero
    d098  c8         RZ

    d099  05         DCR B                          ; Do not print anything if B is zero
    d09a  f8         RM
    d09b  04         INR B
    d09c  c5         PUSH BC

PUT_CHAR_BLOCK_LOOP:
    d09d  cd 09 f8   CALL PUT_CHAR (f809)           ; Print the char in C register B times
    d0a0  05         DCR B
    d0a1  c2 9d d0   JNZ PUT_CHAR_BLOCK_LOOP (d09d)

    d0a4  c1         POP BC                         ; Decrement A
    d0a5  3d         DCR A
    d0a6  c8         RZ

    d0a7  c3 97 d0   JMP PUT_CHAR_BLOCK (d097)      ; Repeat if A is not zero


????_LEFT:
d0aa  cd aa cb   CALL cbaa
d0ad  7e         MOV A, M
d0ae  b7         ORA A
d0af  ca db cc   JZ PILOT_TONE (ccdb)
d0b2  eb         XCHG
d0b3  21 22 f7   LXI HL, f722
d0b6  35         DCR M
d0b7  eb         XCHG
d0b8  e5         PUSH HL
d0b9  e5         PUSH HL
d0ba  e5         PUSH HL
d0bb  cd cb d0   CALL SEARCH_END_OF_STRING (d0cb)
d0be  eb         XCHG
d0bf  c1         POP BC
d0c0  e1         POP HL
d0c1  23         INX HL
d0c2  cd 0d cf   CALL cf0d
d0c5  d1         POP DE
d0c6  62         MOV H, D
d0c7  6b         MOV L, E
d0c8  c3 7b d0   JMP d07b

; Search for a zero character
SEARCH_END_OF_STRING:
    d0cb  7e         MOV A, M                   ; Check if the char is zero
    d0cc  b7         ORA A
    d0cd  c8         RZ

    d0ce  23         INX HL                     ; Advance to the next char, and repeat
    d0cf  c3 cb d0   JMP SEARCH_END_OF_STRING (d0cb)


????_COMMAND_A:
d0d2  cd c7 ce   CALL cec7
d0d5  cd 9e cc   CALL HOME_CURSOR (cc9e)
d0d8  cd 34 cf   CALL cf34
d0db  cd 5c cd   CALL cd5c
????:
d0de  af         XRA A
d0df  32 21 f7   STA f721
d0e2  cd 20 cc   CALL cc20
d0e5  da 0e d0   JC d00e
d0e8  cd ce ce   CALL cece
d0eb  3a 22 f7   LDA f722
d0ee  5f         MOV E, A
d0ef  16 00      MVI D, 00
d0f1  2a 2b f7   LHLD f72b
d0f4  19         DAD DE
d0f5  22 2b f7   SHLD f72b
d0f8  c3 de d0   JMP d0de

????_COMMAND_T:
d0fb  cd ce ce   CALL cece

????:
    d0fe  2a 27 f7   LHLD END_OF_FILE_PTR (f727)    ; Get pointer to the last text char
    d101  2b         DCX HL

d102  cd 84 cf   CALL cf84
d105  3a 22 f7   LDA f722
d108  4f         MOV C, A
d109  06 00      MVI B, 00
d10b  eb         XCHG
d10c  09         DAD BC
d10d  23         INX HL
d10e  22 2b f7   SHLD f72b
d111  0e 1a      MVI C, 1a
d113  cd 09 f8   CALL PUT_CHAR (f809)
d116  c3 de d0   JMP d0de

NEW_FILE:
    d119  cd ce ce   CALL cece                  ; ?????

    d11c  21 17 d3   LXI HL, NEW_FILE_PROMPT_STR (d317) ; Ask the User whether they really want a new file
    d11f  cd 18 f8   CALL PRINT_STRING (f818)

    d122  cd b4 cb   CALL GET_KBD_KEY (cbb4)    ; Get an answer, and check whether it is 'Y'
    d125  d6 59      SUI A, 59

    d127  c2 0c cb   JNZ EDITOR_MAIN_LOOP (cb0c); Non-Y will get the editor back to the main loop

    d12a  21 00 30   LXI HL, 3000               ; Add \r at the beginning of the text
    d12d  36 0d      MVI M, 0d

    d12f  23         INX HL                     ; Store the new End Of Text pointer
    d130  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    d133  36 ff      MVI M, ff                  ; Add end of text marker

    d135  c3 fe d0   JMP d0fe                   ; ????


; Output file to the tape
;
; This function outputs the current text to the tape. The format is slightly different to what
; is used for storing programs. Perhaps this is done intentionally in order to avoid loading programs
; as text and vice versa.
;
; Output format is:
; - 0x55 bytes 0x55             - pilot tone
; - 0x55 bytes 0x00             - another pilot tone
; - 0x55 bytes 0x55             - pilot tone
; - 0x55 bytes 0x00             - another pilot tone
; - 5 bytes 0xe6                - Sync byte
; - zero terminated string      - file name
; - 2 bytes (low byte first)    - data size
; - 256 bytes 0x00              - pilot tone
; - 0xe6                        - sync byte
; - 2 bytes (high byte first)   - data start
; - 2 bytes (high byte first)   - data end
; - data bytes                  - data bytes
; - 2 bytes (low byte first)    - CRC
OUTPUT_FILE:
    d138  cd bf d1   CALL GET_FILE_NAME (d1bf)  ; Input file name

    d13b  13         INX DE                     ; Store file name end pointer BC
    d13c  42         MOV B, D
    d13d  4b         MOV C, E

    d13e  2a 27 f7   LHLD END_OF_FILE_PTR (f727)    ; Load the end of data pointer to DE
    d141  eb         XCHG

    d142  21 00 d0   LXI HL, d000               ; Subtract 0x3000 (file start) to get file size
    d145  19         DAD DE

    d146  d5         PUSH DE                    ; Prepare pointers:
    d147  e5         PUSH HL                    ; end of data, data size, and file name ptr are pushed 
    d148  21 00 30   LXI HL, 3000               ; on the stack
    d14b  c5         PUSH BC                    ; HL = text start; DE = text end + 1
    d14c  13         INX DE                     ; BC = file name end

    d14d  cd da d1   CALL CALCULATE_CRC (d1da)  ; Calculate CRC of the text

    d150  16 04      MVI D, 04                  ; 4 iterations of pilot tones
    
    d152  af         XRA A                      ; Even iterations use tone 0x00

OUTPUT_FILE_TONE_LOOP_1:
    d153  1e 55      MVI E, 55                  ; Each pilot tone is 0x55 bytes long

    d155  ab         XRA E                      ; Odd iterations use tone 0xff

OUTPUT_FILE_TONE_LOOP_2:
    d156  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output 0x55 bytes of the pilot tone
    d159  1d         DCR E
    d15a  c2 56 d1   JNZ OUTPUT_FILE_TONE_LOOP_2 (d156)

    d15d  15         DCR D                      ; Switch tone, and output next portion of the pilot tone
    d15e  c2 53 d1   JNZ OUTPUT_FILE_TONE_LOOP_1 (d153)

    d161  21 e0 f6   LXI HL, f6e0               ; HL - file name start
    d164  d1         POP DE                     ; DE - file name end
    d165  c5         PUSH BC                    ; Push CRC to stack

    d166  3e e6      MVI A, e6                  ; Output 4 sync bytes 0xe6 (in fact even 5)
    d168  06 04      MVI B, 04

OUTPUT_FILE_SYNC_BYTE_LOOP:
    d16a  cd 0c f8   CALL OUT_BYTE (f80c)
    d16d  05         DCR B
    d16e  c2 6a d1   JNZ OUTPUT_FILE_SYNC_BYTE_LOOP (d16a)

OUTPUT_FILE_NAME_LOOP:
    d171  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output next byte of the file name
    d174  cd ea cc   CALL CMP_HL_DE (ccea)

    d177  7e         MOV A, M                   ; Advance to the next byte, until zero byte is reached
    d178  23         INX HL
    d179  c2 71 d1   JNZ OUTPUT_FILE_NAME_LOOP (d171)

    d17c  c1         POP BC                     ; Restore CRC (BC), and data size (HL)
    d17d  e1         POP HL

    d17e  7d         MOV A, L                   ; Output data size, low byte first
    d17f  cd 0c f8   CALL OUT_BYTE (f80c)
    d182  7c         MOV A, H
    d183  cd 0c f8   CALL OUT_BYTE (f80c)

    d186  d1         POP DE                     ; Restore data end pointer

    d187  af         XRA A                      ; Output 256 zero bytes
    d188  6f         MOV L, A

OUTPUT_FILE_TONE_LOOP_3:
    d189  cd 0c f8   CALL OUT_BYTE (f80c)       ; Output next zero byte
    d18c  2d         DCR L
    d18d  c2 89 d1   JNZ OUTPUT_FILE_TONE_LOOP_3 (d189)

    d190  21 00 30   LXI HL, 3000               ; Will start output data from 0x3000

    d193  3e e6      MVI A, e6                  ; Output 0xe6 sync byte
    d195  cd 0c f8   CALL OUT_BYTE (f80c)

    d198  7c         MOV A, H                   ; Output data start (high byte first)
    d199  cd 0c f8   CALL OUT_BYTE (f80c)
    d19c  7d         MOV A, L
    d19d  cd 0c f8   CALL OUT_BYTE (f80c)

    d1a0  7a         MOV A, D                   ; Output data end (high byte first)
    d1a1  cd 0c f8   CALL OUT_BYTE (f80c)
    d1a4  7b         MOV A, E
    d1a5  cd 0c f8   CALL OUT_BYTE (f80c)

    d1a8  13         INX DE

OUTPUT_FILE_DATA_LOOP:
    d1a9  7e         MOV A, M                   ; Output next data byte
    d1aa  23         INX HL
    d1ab  cd 0c f8   CALL OUT_BYTE (f80c)

    d1ae  cd ea cc   CALL CMP_HL_DE (ccea)      ; Until HL reaches DE (end of data)
    d1b1  c2 a9 d1   JNZ OUTPUT_FILE_DATA_LOOP (d1a9)

    d1b4  79         MOV A, C                   ; Output CRC (low byte first)
    d1b5  cd 0c f8   CALL OUT_BYTE (f80c)
    d1b8  78         MOV A, B
    d1b9  cd 0c f8   CALL OUT_BYTE (f80c)

    d1bc  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c)    ; Finish, exit to the main loop


; Input file name
; The function prints the "FILE?" prompt and waits for the user input
;
; Return: 
; File name in the 0xf6e0 buffer
; DE - pointer to the last entered symbol in the buffer
GET_FILE_NAME:
    d1bf  c5         PUSH BC                    ; Clear screen and show the prompt
    d1c0  cd fd cb   CALL CLEAR_SCREEN_AND_PRINT_COMMAND_PROMPT (cbfd)

    d1c3  21 1d d3   LXI HL, FILE_STR (d31d)    ; Print 'FILE' string
    d1c6  cd 18 f8   CALL PRINT_STRING (f818)

    d1c9  3e 3f      MVI A, 3f                  ; Print '?'
    d1cb  cd 0a cc   CALL PUT_CHAR_AND_SPACE (cc0a)

    d1ce  c1         POP BC                     ; Store the input mode in a variable
    d1cf  78         MOV A, B                   ; BUG? Why shall it belong to this function?
    d1d0  32 20 f7   STA INPUT_MODE (f720)

    d1d3  cd 20 cc   CALL cc20                  ; Get the file name, exit to main loop in case of error
    d1d6  da 0c cb   JC EDITOR_MAIN_LOOP (cb0c)

    d1d9  c9         RET


; Calculate CRC by adding all bytes in the given range into 16-bit value
; Arguments:
; HL - start address
; DE - next byte after end address
; Return: CRC in BC
CALCULATE_CRC:
    d1da  e5         PUSH HL
    d1db  01 00 00   LXI BC, 0000               ; Zero result accumulator

CALCULATE_CRC_LOOP:
    d1de  7e         MOV A, M                   ; Add the next data byte to the accumulator
    d1df  81         ADD C
    d1e0  4f         MOV C, A

    d1e1  78         MOV A, B                   ; Adjust high byte if needed
    d1e2  ce 00      ACI A, 00
    d1e4  47         MOV B, A

    d1e5  23         INX HL                     ; Advance to the next byte

    d1e6  cd ea cc   CALL CMP_HL_DE (ccea)      ; Repeat until reached DE
    d1e9  c2 de d1   JNZ CALCULATE_CRC_LOOP (d1de)

    d1ec  e1         POP HL                     ; Return
    d1ed  c9         RET


; Read text file from the tape
;
; The function serves Command I (text input), M (merge file), and V (verify). The function works according
; to the following algorithm:
; - Ask user for the desired file name
; - Read the tape until 4 x 0xe6 marker bytes are found, followed by the file name. If the file name does not
;   match the requested one, the function will wait for another file record.
; - Data size field stored on the tape has priority over data start/end address fields
; - Command M calculates data start/end address so that it appends tape data to the text already in the
;   memory. Commands I and V will use 0x3000 as data start address.
; - Commands I and M do the actual data load according to calculated addresses.
; - Command V does not data verification, report mismatch errors if any.
; - CRC field stored at the end of file is checked against the memory data, report mismatch errors if any.
INPUT_FILE:
    d1ee  06 00      MVI B, 00                  ; Set the mode 0 - normal input file from tape

INPUT_FILE_1:
    d1f0  cd bf d1   CALL GET_FILE_NAME (d1bf)  ; Input file name
    d1f3  eb         XCHG                       ; DE buffer start, HL buffer end

INPUT_FILE_WAIT_SYNC_BYTE:
    d1f4  06 04      MVI B, 04                  ; Wait for 4 sync bytes in a raw
    d1f6  3e ff      MVI A, ff                  ; Expect synchronization first

INPUT_FILE_WAIT_SYNC_BYTE_LOOP:
    d1f8  cd 06 f8   CALL IN_BYTE (f806)        ; Read the byte, and check if it is 0xe6 sync byte
    d1fb  fe e6      CPI A, e6
    d1fd  c2 f4 d1   JNZ INPUT_FILE_WAIT_SYNC_BYTE (d1f4)

    d200  05         DCR B                      ; Another sync byte received, look for the next one
    d201  3e 08      MVI A, 08
    d203  c2 f8 d1   JNZ INPUT_FILE_WAIT_SYNC_BYTE_LOOP (d1f8)

    d206  21 a0 f6   LXI HL, f6a0               ; Will compare file name on the tape with one in the buffer
                                                ; BUG: File name is received from the tape into the same
                                                ; buffer where user types file name from the keyboard. So
                                                ; in fact comparison will happen to self, and file names will
                                                ; always match.

; Read the file name from the tape, anc compare it with requested one
INPUT_FILE_NAME_LOOP:
    d209  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)

    d20c  77         MOV M, A                   ; Receive next byte of the file name
    d20d  b7         ORA A 

    d20e  23         INX HL                     ; Advance to the next byte, until a zero byte is found
    d20f  c2 09 d2   JNZ INPUT_FILE_NAME_LOOP (d209)

    d212  cd df d2   CALL IN_BYTE_NO_SYNC (d2df); Input data size
    d215  4f         MOV C, A
    d216  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d219  47         MOV B, A

    d21a  c5         PUSH BC                    ; Print "FILE" string
    d21b  21 1d d3   LXI HL, FILE_STR (d31d)
    d21e  cd 18 f8   CALL PRINT_STRING (f818)

    d221  3e 3a      MVI A, 3a                  ; Print ':'
    d223  cd 0a cc   CALL PUT_CHAR_AND_SPACE (cc0a)

    d226  21 a0 f6   LXI HL, f6a0               ; Print received file name
    d229  e5         PUSH HL
    d22a  cd 18 f8   CALL PRINT_STRING (f818)
    d22d  e1         POP HL

INPUT_FILE_NAME_COMPARE_LOOP:
    d22e  1a         LDAX DE                    ; Stop name comparison when terminating zero is found
    d22f  b7         ORA A
    d230  ca 3d d2   JZ INPUT_FILE_2 (d23d)

    d233  be         CMP M                      ; Compare next byte of the file name
    d234  23         INX HL
    d235  13         INX DE
    d236  ca 2e d2   JZ INPUT_FILE_NAME_COMPARE_LOOP (d22e)

    d239  c1         POP BC                     ; If the file name was not matched - look for another file
    d23a  c3 f4 d1   JMP INPUT_FILE_WAIT_SYNC_BYTE (d1f4)

; This part calculates data start/end address for Command M (Merge)
INPUT_FILE_2:
    d23d  c1         POP BC                     ; Restore file size. Check it is zero
    d23e  78         MOV A, B
    d23f  b1         ORA C

    d240  f5         PUSH PSW
    d241  c5         PUSH BC

    d242  3a 20 f7   LDA INPUT_MODE (f720)      ; Code below is executed for Command M only, otherwise skip
    d245  3d         DCR A             
    d246  fa 5d d2   JM INPUT_FILE_3 (d25d)

    d249  2a 27 f7   LHLD END_OF_FILE_PTR (f727); end of current file += loaded file size
    d24c  d1         POP DE
    d24d  e5         PUSH HL
    d24e  19         DAD DE

    d24f  cd aa cf   CALL CHECK_FILE_SIZE (cfaa); Check the new file size does not exceed limits

    d252  eb         XCHG                       ; Print error if loaded file size is zero
    d253  e1         POP HL
    d254  f1         POP PSW
    d255  ca d6 d2   JZ INPUT_FILE_ERROR (d2d6)

    d258  af         XRA A                      ; Rest of the function act as Command I (normal file input)
    d259  f5         PUSH PSW

    d25a  c3 86 d2   JMP INPUT_FILE_4 (d286)

; This part calculates start/end address depending on data size field stored on the tape, or (if it zero)
; on data start/end address stored on the tape.
INPUT_FILE_3:
    d25d  3c         INR A                      ; Get 0 for command I, 0xff for Ccommand V

    d25e  21 00 30   LXI HL, 3000               ; Calculate end of data address (0x3000+file size)
    d261  eb         XCHG
    d262  e1         POP HL
    d263  19         DAD DE

    d264  f5         PUSH PSW                   ; Check if the file fits into the memory
    d265  d5         PUSH DE
    d266  cd aa cf   CALL CHECK_FILE_SIZE (cfaa)
    d269  d1         POP DE

    d26a  eb         XCHG                       ; Restore and check the data size
    d26b  c1         POP BC
    d26c  f1         POP PSW
    d26d  c5         PUSH BC

    d26e  c2 86 d2   JNZ INPUT_FILE_4 (d286)    ; If file size is not zero - use it for calculating end addr

    d271  3e ff      MVI A, ff                  ; If file size value is zero try to guess it from data start
    d273  cd 06 f8   CALL IN_BYTE (f806)        ; and data end fields. Load data start field first
    d276  67         MOV H, A
    d277  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d27a  6f         MOV L, A

    d27b  cd df d2   CALL IN_BYTE_NO_SYNC (d2df); Then load data end field
    d27e  57         MOV D, A
    d27f  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d282  5f         MOV E, A

    d283  c3 94 d2   JMP INPUT_FILE_5 (d294)    ; Continue with loading the file data

INPUT_FILE_4:
    d286  3e ff      MVI A, ff                  ; Data size field is non-zero. Ignore data start/end fields
    d288  cd 06 f8   CALL IN_BYTE (f806)
    d28b  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d28e  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d291  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)

INPUT_FILE_5:
    d294  13         INX DE                     ; Set DE 1 byte after data end

    d295  f1         POP PSW                    ; Restore input mode. Command I will actually load data
    d296  e5         PUSH HL                    ; from tape.
    d297  c2 c5 d2   JNZ d2c5                   ; Command V (validation) will be processed elsewhere

; This part actually loads the data from tape to the memory
INPUT_FILE_DATA_LOOP:
    d29a  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)    ; Read next data byte
    d29d  77         MOV M, A
    d29e  23         INX HL

    d29f  cd ea cc   CALL CMP_HL_DE (ccea)          ; Repeat until end of data is reached
    d2a2  c2 9a d2   JNZ INPUT_FILE_DATA_LOOP (d29a)

; This is the final stage of the algorithm - comparing the calculated CRC on the data in memory
; with the CRC value stored on the tape. Report an error in case of mismatch
INPUT_FILE_CHECK_CRC:
    d2a5  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)    ; Read CRC value
    d2a8  4f         MOV C, A
    d2a9  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)
    d2ac  47         MOV B, A

    d2ad  e1         POP HL                     ; Calculate actual data CRC
    d2ae  c5         PUSH BC
    d2af  cd da d1   CALL CALCULATE_CRC (d1da)
    d2b2  e1         POP HL

    d2b3  7c         MOV A, H                   ; Compare calculated and read CRC. Report error in case of
    d2b4  b8         CMP B                      ; mismatch
    d2b5  c2 d6 d2   JNZ INPUT_FILE_ERROR (d2d6)
    d2b8  7d         MOV A, L
    d2b9  b9         CMP C
    d2ba  c2 d6 d2   JNZ INPUT_FILE_ERROR (d2d6)

    d2bd  1b         DCX DE                     ; Update end of file pointer
    d2be  eb         XCHG
    d2bf  22 27 f7   SHLD END_OF_FILE_PTR (f727)

    d2c2  c3 0c cb   JMP EDITOR_MAIN_LOOP (cb0c); Return to the main loop

; This part serves Command V (Verify) and compares data on the tape with data in memory
INPUT_FILE_DATA_COMPARE_LOOP:
    d2c5  cd df d2   CALL IN_BYTE_NO_SYNC (d2df)    ; Compare next data byte
    d2c8  be         CMP M

    d2c9  23         INX HL                         ; Advance to the next byte

    d2ca  c2 d6 d2   JNZ INPUT_FILE_ERROR (d2d6)    ; Report error in case of mismatch

    d2cd  cd ea cc   CALL CMP_HL_DE (ccea)          ; Repeat until end of data reached
    d2d0  c2 c5 d2   JNZ INPUT_FILE_DATA_COMPARE_LOOP (d2c5)

    d2d3  c3 a5 d2   JMP INPUT_FILE_CHECK_CRC (d2a5); Proceed with the next step (CRC match)


; Report "I/O ERROR", beep, and exit to main loop
INPUT_FILE_ERROR:
    d2d6  11 0c d3   LXI DE, IO_DEVICE_STR (d30c)   ; Print error string
    d2d9  cd 12 ce   CALL PRINT_ERROR (ce12)

    d2dc  c3 f7 cb   JMP BEEP_AND_EXIT (cbf7)

; Input a byte, assuming sync has been already happened
IN_BYTE_NO_SYNC:
    d2df  3e 08      MVI A, 08
    d2e1  c3 06 f8   JMP IN_BYTE (f806)

; Command Ctrl-V: Verify file on tape with text in memory
;
; The command works almost the same way as Input File command, except for data from the tape is
; not loaded to the memory, but just compared with the data that is in memory already. In case of
; mismatch an error will be shown.
VERIFY_FILE:
    d2e4  06 ff      MVI B, ff                  ; Input Mode 0xff - verify
    d2e6  c3 f0 d1   JMP INPUT_FILE_1 (d1f0)


; Command Ctrl-M: Merge file (append text file from the tape at the end of existing text)
;
; This command is another variation of the Input File function. It also reads the file from the tape,
; but start and end address is calculated so that file is loaded right after existing text.
MERGE_FILE:
    d2e9  06 01      MVI B, 01                  ; Input Mode 0x01 - Merge
    d2eb  c3 f0 d1   JMP INPUT_FILE_1 (d1f0)

ERROR_STR:
    d2ee  0a 45 52 52 4f 52 3a 00   db "\rERROR:", 0x00
    
LONG_STRING_STR:
    d2f6  4c 4f 4e 47 20 53 54 52   db "LONG STR"
    d2fe  49 4e 47 00               db "ING", 0x00

LONG_FILE_STR:
    d302  4c 4f 4e 47 20 46 49 4c   db "LONG FIL"
    d30a  45 00                     db "E", 0x00

IO_DEVICE_STR:
    d30c  49 2f 4f 20 44 45 56 49   db "I/O DEVI"
    d314  43 45 00                  db "CE", 0x00

NEW_FILE_PROMPT_STR:
    d317  1f 4e 45 57 3f 00         db 0x1f, "NEW?", 0x00

FILE_STR:
    d31d  0a 46 49 4c 45 00         db "\rFILE", 0x00

HELLO_STR:
    d323  0a 45 44 49 54 20 2a 6d   db "\rEDIT *М"
    d32b  69 6b 72 6f 6e 2a 0a 2a   db "ИКРОН*\r*"
    d333  00                        db 0x00

????:
    d334  0a 45 4e 44 3d 00         db "\rEND=", 0x00
    
????:
    d33a  20 20 55 53 45 44 3d 00   db "  USED=", 0x00
    
????:
    d342  20 20 46 52 45 45 3d 00   db "  FREE=", 0x00


; The following is the table of command handlers
;
; BUG (or at least incompatibility): It is supposed to enter commands with the Ctrl key. First issue, is
; that GET_KBD_KEY function is looking for a high bit of the Keyboard's Port C, while the Ctrl key is 
; connected to 1st bit of that port. Another issue is that Ctrl-<char> combinations produce char codes in
; 0x01-0x1a range, while the table below expects normal char codes (in 0x41-0x5a range)
COMMAND_HANDLERS:
    d34a  4c c6 cb      db 'L', ????_COMMAND_L (cbc6)
    d34d  58 be cb      db 'X', ????_COMMAND_X (cbbe)
    d350  44 bb cf      db 'D', ????_COMMAND_D (cfbb)
    d353  41 d2 d0      db 'A', ????_COMMAND_A (d0d2)
    d356  54 fb d0      db 'T', ????_COMMAND_T (d0fb)
    d359  4e 19 d1      db 'N', NEW_FILE (d119)
    d35c  4f 38 d1      db 'O', OUTPUT_FILE (d138)
    d35f  49 ee d1      db 'I', INPUT_FILE (d1ee)
    d362  56 e4 d2      db 'V', VERIFY_FILE (d2e4)
    d365  4d e9 d2      db 'M', MERGE_FILE (d2e9)
    d368  57 88 cd      db 'W', ????_COMMAND_W (cd88)
    d36b  52 a7 cd      db 'R', ????_COMMAND_R (cda7)
    d36e  46 bf cd      db 'F', ????_COMMAND_F (cdbf)
    d371  59 9d cd      db 'Y', ????_COMMAND_Y (cd9d)
    d374  08 aa d0      db 0x08, d0aa
    d377  18 5f d0      db 0x18, d05f
    d37a  19 91 ce      db 0x19, ce91
    d37d  1a 6b cf      db 0x1a, cf6b

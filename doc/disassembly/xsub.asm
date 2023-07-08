; XSUB is a program for emulating keyboard input for applications, by providing predefined data
; instead. The program hooks 0x0a console input BDOS function, and fill provided buffer with data
; that is read from $$$.SUB file.
;
; XSUB is an example of resident program (similar to MS DOS resident programs), and consists of 2 parts:
; - First part loads the program, and copies second part right below CCP. Also this part hooks Warm boot
;   and BDOS handlers, and substitute it with own ones. Then the program exits to CCP
; - Second part remains loaded in the memory, and handles BDOS calls. If an application calls 0x0a console
;   input function, XSUB provides data instead. All other functions are routed to original BDOS handler.


; NON-RESIDENT MODULE
; The code below is loaded as a regular CP/M application starting from address 0x0100
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:
    0100  01 bc 01   LXI BC, 01bc                   ; Resident module size
    0103  c3 57 01   JMP REAL_START (0157)

    0106  20 45 78 74 65 6e 64 65       db " Extende"       ; App name string, not used in the code
    010e  64 20 53 75 62 6d 69 74       db "d Submit"
    0116  20 56 65 72 73 20 32 2e       db " Vers 2."
    011e  30                            db "0"

XSUB_PRESENT_STR:
    011f  58 73 75 62 20 41 6c 72       db "Xsub Alr"
    0127  65 61 64 79 20 50 72 65       db "eady Pre"
    012f  73 65 6e 74 24                db "sent$"


CPM_VERSION_ERR_STR:
    0134  52 65 71 75 69 72 65 73       db "Requires"
    013c  20 43 50 2f 4d 20 56 65       db " CP/M Ve"
    0144  72 73 69 6f 6e 20 32 2e       db "rsion 2."
    014c  30 20 6f 72 20 6c 61 74       db "0 or lat"
    0154  65 72 24                      db "er$"

; Non-resident part entry point.
;
; The function performs the next steps:
; - Checks whether XSUB resident is already installed
; - Checks CP/M version
; - Calculates resident module location (so that it is located right below CCP)
; - Copy resident part to the calculated location
; - Adjust 3-byte commands addresses to the new memory range (using special relocation table)
; - Pass control to the resident module initializer function (RESIDENT_START)
REAL_START:
    0157  c5         PUSH BC                    ; Save resident module size for later

    0158  3a 06 00   LDA 0006                   ; Check if BDOS entry point is XSUB handler (real BDOS handler
    015b  fe 06      CPI A, 06                  ; is 0xXX06 depending on the memory layout, XSUB handler has
    015d  c2 79 01   JNZ XSUB_PRESENT_ERR (0179); other address)

    0160  2a 06 00   LHLD 0006                  ; Get BDOS entry point address

    0163  23         INX HL                     ; XSUB resident has 'xsub' identifier right after the handler's
    0164  23         INX HL                     ; JMP xxxx instruction
    0165  23         INX HL

    0166  11 db 01   LXI DE, XSUB_ID (01db)     ; Compare this identifier
    0169  0e 04      MVI C, 04
CHECK_XSUB_LOOP:
    016b  1a         LDAX DE                    ; Compare chars
    016c  be         CMP M
    016d  c2 83 01   JNZ NO_XSUB (0183)

    0170  23         INX HL                     ; Advance to the next char
    0171  13         INX DE
    0172  0d         DCR C

    0173  ca 79 01   JZ XSUB_PRESENT_ERR (0179) ; Repeat until all 4 chars are compared

    0176  c3 6b 01   JMP CHECK_XSUB_LOOP (016b)


XSUB_PRESENT_ERR:
    0179  0e 09      MVI C, 09                  ; Print "XSub Already Present" message
    017b  11 1f 01   LXI DE, XSUB_PRESENT_STR (011f)
    017e  cd 05 00   CALL 0005

    0181  c1         POP BC                     ; and exit
    0182  c9         RET

NO_XSUB:
    0183  0e 0c      MVI C, 0c                  ; Get CP/M version
    0185  cd 05 00   CALL 0005

    0188  fe 20      CPI A, 20
    018a  d2 97 01   JNC VERSION_OK (0197)

    018d  0e 09      MVI C, 09                  ; Report CP/M version error
    018f  11 34 01   LXI DE, CPM_VERSION_ERR_STR (0134)
    0192  cd 05 00   CALL 0005

    0195  c1         POP BC                     ; And exit
    0196  c9         RET

VERSION_OK:
    0197  21 07 00   LXI HL, 0007               ; Get the BDOS high address byte (e.g. 0xcc??)

    019a  7e         MOV A, M                   ; Decrease it by 1 to fit non-full page of resident module
    019b  3d         DCR A                     
    019c  d6 08      SUI A, 08                  ; Decrease by 8 more pages (CCP size)

    019e  c1         POP BC                     ; Recall the module size
    019f  c5         PUSH BC

    01a0  90         SUB B                      ; Decrease by module size (full pages)
    01a1  57         MOV D, A                   ; Thus resident module will be located right below CCP
    01a2  1e 00      MVI E, 00

    01a4  d5         PUSH DE                    ; DE is a base address of the resident module
    01a5  21 00 02   LXI HL, 0200               ; HL is a source of the resident module

MEMCOPY_LOOP:   ; Mem copy from 0x0200 to resident module address
    01a8  78         MOV A, B                   ; BC == 0?
    01a9  b1         ORA C
    01aa  ca b5 01   JZ RELOCATE (01b5)

    01ad  0b         DCX BC

    01ae  7e         MOV A, M
    01af  12         STAX DE

    01b0  13         INX DE
    01b1  23         INX HL
    01b2  c3 a8 01   JMP MEMCOPY_LOOP (01a8)

RELOCATE:
    01b5  d1         POP DE                     ; Recall resident base address
    01b6  c1         POP BC                     ; Recall module size
    01b7  e5         PUSH HL                    ; HL is points to relocation table at 0x3bc

    01b8  62         MOV H, D                   ; Advance to a similar area at resident module address range

RELOCATE_LOOP:
    01b9  78         MOV A, B                   ; BC == 0 (have we processed all bytes?)
    01ba  b1         ORA C
    01bb  ca d7 01   JZ START_XSUB_RES (01d7)

    01be  0b         DCX BC                     ; Decrement size counter

    01bf  7b         MOV A, E                   ; Get next byte from relocation table every 8 bytes
    01c0  e6 07      ANI A, 07
    01c2  c2 ca 01   JNZ RELOCATE_1 (01ca)

    01c5  e3         XTHL                       ; Load next relocation element address
    01c6  7e         MOV A, M                   ; Load the relocation element
    01c7  23         INX HL                     ; Advance the address
    01c8  e3         XTHL                       ; and store it back
    01c9  6f         MOV L, A

RELOCATE_1:
    01ca  7d         MOV A, L                   ; Check if high bit of the relocation element is set
    01cb  17         RAL
    01cc  6f         MOV L, A
    01cd  d2 d3 01   JNC RELOCATE_2 (01d3)

    01d0  1a         LDAX DE                    ; Correct the address of the byte in resident module
    01d1  84         ADD H
    01d2  12         STAX DE

RELOCATE_2:
    01d3  13         INX DE                     ; Advance to the next byte
    01d4  c3 b9 01   JMP RELOCATE_LOOP (01b9)

START_XSUB_RES:
    01d7  d1         POP DE                     ; Start XSUB part 2 at residental address range
    01d8  2e 00      MVI L, 00                  ; (see RESIDENT_START)
    01da  e9         PCHL

XSUB_ID:
    01db  78 73 75 62       db "xsub"           ; xsub identifier, used to check the resident is installer
    

; 0x01df - 0x01ff is a garbage


; RESIDENT MODULE
; The code below is already relocated to 0xc200 (right below CCP which is located at 0xc400)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RESIDENT_START: 
    c200  c3 0d c2   JMP RESIDENT_REAL_START (c20d) ; Initialize entry point

    c203  05 00 c9                                  ; Garbage

XSUB_BDOS_ENTRY:
    c206  c3 5d c2   JMP XSUB_BDOS_REAL_ENTRY (c25d)    ; BDOS handler

    c209  78 73 75 62           db "xsub"       ; Magic identifier (used to check whether XSUB loaded already)



; Residental part initialization function
;
; The function performs the following actions:
; - Replaces warm boot handler (0x0000) with XSUB one (original address is saved)
; - Replaces BDOS handler (0x0005) with own one (original address is saved)
; - Returns control to CCP
RESIDENT_REAL_START:
    c20d  2a 01 00   LHLD 0001                  ; Save the original warm reboot address
    c210  22 2d c2   SHLD REBOOT_ADDR_ORIG (c22d)

    c213  21 2f c2   LXI HL, XSUB_REBOOT_ADDR (c22f)    ; Substitute with XSUB reboot entry
    c216  22 01 00   SHLD 0001

    c219  2a 06 00   LHLD 0006                          ; Save original BDOS handler address
    c21c  22 2b c2   SHLD JMP_TO_BDOS + 1 (c22b)

    c21f  21 06 c2   LXI HL, XSUB_BDOS_ENTRY (c206)     ; Replace it with XSUB BDOS handler
    c222  22 06 00   SHLD 0006

    c225  e1         POP HL                     ; Recall CCP return address
    c226  22 bc c3   SHLD CCP_RET_ADDR (c3bc)   ; Save it, and return to CCP
    c229  e9         PCHL


JMP_TO_BDOS:
    c22a  c3 00 00   JMP 0000                   ; Jump to real BDOS handler (address filled a little above)

REBOOT_ADDR_ORIG:
    c22d  00 c9      db 0000                    ; Save original warm reboot address


; Warm Boot Handler
;
; This function is executed in case of reboot, and performs the following actions:
; - Prints "xsub active" message
; - Restores the default disk buffer
; - Re-sets XSUB handler for BDOS functions
; - Exits to CCP
XSUB_REBOOT_ADDR:
    c22f  31 de c3   LXI SP, XSUB_STACK + 0x20 (c3de)  ; Set up local stack

    c232  0e 09      MVI C, 09                      ; Print the message that XSUB is active 
    c234  11 4d c2   LXI DE, XSUB_ACTIVE_STR (c24d)
    c237  cd 2a c2   CALL JMP_TO_BDOS (c22a)

    c23a  21 80 00   LXI HL, 0080                   ; Set the default disk buffer
    c23d  22 ba c3   SHLD SAVE_DISK_BUF_ADDR (c3ba)
    c240  cd 81 c2   CALL RESTORE_DISK_BUFFER (c281)

    c243  21 06 c2   LXI HL, XSUB_BDOS_ENTRY (c206) ; Reset XSUB BDOS entry address (in case it is corrupter)
    c246  22 06 00   SHLD 0006

    c249  2a bc c3   LHLD CCP_RET_ADDR (c3bc)       ; Jump to CCP (BUG? do we really need to jump in the
    c24c  e9         PCHL                           ; middle of CCP during reboot?)

XSUB_ACTIVE_STR:
    c24d  0d 0a 28 78 73 75 62 20       db 0x0d, 0x0a, "(xsub "
    c255  61 63 74 69 76 65 29 24       db "active)$"


; Substituted BDOS handler
;
; This function is called instead of BDOS handler. The implementation replaces 2 functions:
; - Function 0x0a - console input (see XSUB_CONSOLE_INPUT)
; - Function 0x1a - set disk buffer
; 
; Console input implementation does disk operations into its own buffer. There is no way in CP/M to get
; the current disk address. So handling Set Disk Buffer command is needed to remember the disk buffer address,
; and restore it when needed.
XSUB_BDOS_REAL_ENTRY:
    c25d  e1         POP HL                     ; Recall the return address
    c25e  e5         PUSH HL

    c25f  7c         MOV A, H                   ; Check if the address is 0xff00 or above
    c260  fe ff      CPI A, ff
    c262  d2 2a c2   JNC JMP_TO_BDOS (c22a)     ; Go directly to real BDOS in this case

    c265  79         MOV A, C                   ; XSUB substitutes function 0x0a (read console input)
    c266  fe 0a      CPI A, 0a
    c268  ca a5 c2   JZ XSUB_CONSOLE_INPUT (c2a5)

    c26b  fe 1a      CPI A, 1a                  ; All other functions except for 0x1a (set buffer) processed
    c26d  c2 2a c2   JNZ JMP_TO_BDOS (c22a)     ; by real BDOS

    c270  eb         XCHG                       ; XSUB Set disk buffer handler: remember the new disk buffer
    c271  22 ba c3   SHLD SAVE_DISK_BUF_ADDR (c3ba) ; address
    c274  eb         XCHG
    c275  c3 2a c2   JMP JMP_TO_BDOS (c22a)     ; Let BDOS do its stuff


; Set the XSUB disk buffer
SET_XSUB_DISK_BUF:
    c278  0e 1a      MVI C, 1a                  ; Set the XSUB buffer for disk operations
    c27a  11 37 c3   LXI DE, XSUB_DISK_BUF (c337)
    c27d  cd 2a c2   CALL JMP_TO_BDOS (c22a)
    c280  c9         RET


; Restore previously set disk buffer 
RESTORE_DISK_BUFFER:
    c281  0e 1a      MVI C, 1a                  ; Call SET_DMA_BUFFER BDOS function
    c283  2a ba c3   LHLD SAVE_DISK_BUF_ADDR (c3ba) ; Restore BDOS disk buffer address previously saved in
    c286  eb         XCHG                           ; the SAVE_DISK_BUF_ADDR variable
    c287  cd 2a c2   CALL JMP_TO_BDOS (c22a)
    c28a  c9         RET


; Wrapper over disk operations
; The function sets XSUB disk buffer, performs the disk operation, and restores buffer back
CALL_BDOS_XSUB_BUF:
    c28b  c5         PUSH BC                    ; Set XSUB buffer for disk operations
    c28c  d5         PUSH DE
    c28d  cd 78 c2   CALL SET_XSUB_DISK_BUF (c278)
    c290  d1         POP DE
    c291  c1         POP BC

    c292  cd 2a c2   CALL JMP_TO_BDOS (c22a)    ; Call the requested function

    c295  f5         PUSH PSW                   ; Restore previous disk buffer
    c296  cd 81 c2   CALL RESTORE_DISK_BUFFER (c281)
    c299  f1         POP PSW

    c29a  c9         RET


; Open $$$.SUB file
OPEN_SUB_FILE:
    c29b  0e 0f      MVI C, 0f
    c29d  11 16 c3   LXI DE, SUB_FILE_FCB (c316)
    c2a0  cd 8b c2   CALL CALL_BDOS_XSUB_BUF (c28b)

    c2a3  3c         INR A                      ; Set Z flag in case of error
    c2a4  c9         RET


; Console Input Function replacement
;
; This function emulates BDOS Console Input Function, by reading $$$.SUB file (if exists) and storing
; it in the buffer provided for BDOS function.
;
; Algorithm:
; - Open the $$$.SUB file (if no file, or no data in the file, the function will route to the original
;   BDOS function)
; - Load the record from the file. Records are stored in backwards order, so the function technically
;   reads the last record from the file.
; - Depending on the data size and buffer size the data may be truncated to avoid buffer overrun
; - Data from the file is copied to the console input buffer
; - Data is also echoed on the screen, same way as original BDOS function does
; - If no more records left in the $$$.SUB file, the file is deleted
; - Control returned to the caller
XSUB_CONSOLE_INPUT:
    c2a5  d5         PUSH DE                    ; Open the $$$.SUB file
    c2a6  cd 9b c2   CALL OPEN_SUB_FILE (c29b)
    c2a9  d1         POP DE

    c2aa  0e 0a      MVI C, 0a
    c2ac  ca 0d c3   JZ XSUB_CONSOLE_INPUT_RESTORE (c30d)   ; Check if file could not be opened

    c2af  d5         PUSH DE                    ; Get records number
    c2b0  3a 25 c3   LDA SUB_FILE_FCB + 0x1f (c325)

    c2b3  b7         ORA A                      ; If no more records left in the file - continue with BDOS
    c2b4  ca 2a c2   JZ JMP_TO_BDOS (c22a)      ; console input function

    c2b7  3d         DCR A                      ; Set record counter to the last record of the file
    c2b8  32 36 c3   STA SUB_FILE_FCB + 0x20 (c336)

    c2bb  0e 14      MVI C, 14                  ; Read the record to the XSUB buffer
    c2bd  11 16 c3   LXI DE, SUB_FILE_FCB (c316)
    c2c0  cd 8b c2   CALL CALL_BDOS_XSUB_BUF (c28b)

    c2c3  21 37 c3   LXI HL, XSUB_DISK_BUF (c337)   ; Get the record size in DE
    c2c6  5e         MOV E, M
    c2c7  16 00      MVI D, 00

    c2c9  19         DAD DE                     ; Calculate offset of the last data byte 

    c2ca  23         INX HL                     ; Append 0x0d
    c2cb  36 0d      MVI M, 0d

    c2cd  23         INX HL                     ; Append 0x0a
    c2ce  36 0a      MVI M, 0a

    c2d0  23         INX HL                     ; Append '$'
    c2d1  36 24      MVI M, 24

    c2d3  0e 09      MVI C, 09                  ; Echo the command read from file
    c2d5  11 38 c3   LXI DE, XSUB_DISK_BUF + 1 (c338)
    c2d8  cd 2a c2   CALL JMP_TO_BDOS (c22a)

    c2db  e1         POP HL                     ; HL (previously DE) is a Func 0x0a argument - buffer address
    c2dc  11 37 c3   LXI DE, XSUB_DISK_BUF (c337)   ; Compare it with data size that was read from the file
    c2df  1a         LDAX DE
    c2e0  be         CMP M

    c2e1  da e6 c2   JC XSUB_CONSOLE_INPUT_1 (c2e6) ; Jump if buffer is larger that data size
    
    c2e4  7e         MOV A, M                   ; Limit data with the buffer size
    c2e5  12         STAX DE

XSUB_CONSOLE_INPUT_1:
    c2e6  4f         MOV C, A                   
    c2e7  0c         INR C                      ; Will copy data + line length (extra byte)
    c2e8  23         INX HL

MEMCOPY_RES_LOOP:
    c2e9  1a         LDAX DE
    c2ea  77         MOV M, A
    c2eb  23         INX HL
    c2ec  13         INX DE
    c2ed  0d         DCR C
    c2ee  c2 e9 c2   JNZ MEMCOPY_RES_LOOP (c2e9)

    c2f1  0e 10      MVI C, 10                      ; Prepare for closing $$$.SUB file
    c2f3  11 16 c3   LXI DE, SUB_FILE_FCB (c316)

    c2f6  21 0e 00   LXI HL, 000e                   ; Reset S2 byte in the FCB ????
    c2f9  19         DAD DE                         ; (probably this shall mark the file as written)
    c2fa  36 00      MVI M, 00

    c2fc  3a 36 c3   LDA SUB_FILE_FCB + 0x20 (c336) ; Seek to the previous record
    c2ff  3d         DCR A
    c300  32 25 c3   STA SUB_FILE_FCB + 0x1f (c325)

    c303  b7         ORA A                          ; If there are more records to go - just close the file
    c304  c2 09 c3   JNZ XSUB_CONSOLE_INPUT_2 (c309)

    c307  0e 13      MVI C, 13                      ; Otherwise delete $$$.SUB file
XSUB_CONSOLE_INPUT_2:
    c309  cd 8b c2   CALL CALL_BDOS_XSUB_BUF (c28b)

    c30c  c9         RET                            ; Exit from the handle

XSUB_CONSOLE_INPUT_RESTORE:
    c30d  2a 2d c2   LHLD REBOOT_ADDR_ORIG (c22d)   ; If no $$$.SUB available - restore the warm boot address
    c310  22 01 00   SHLD 0001

    c313  c3 2a c2   JMP JMP_TO_BDOS (c22a)         ; And perform BDOS duties normally


SUB_FILE_FCB:
    c316  01 24 24 24 20 20 20 20                   ; FCB for dealing with $$$.SUB (second part of FCB
    c31e  20 53 55 42 00 00 00 71                   ; contains garbage)
    c326  d5 3a 28 1f 3d 32 28 1f
    c32e  fe ff ca 4e 0a 2a 24 1f
    c336  e5

XSUB_DISK_BUF:
    c337  83 * [00]                             ; Disk buffer for file operations (filled with garbage initially)

SAVE_DISK_BUF_ADDR:
    c3ba  80 00     dw 0080                     ; Disk buffer address currently set in BDOS

CCP_RET_ADDR:
    c3bc  00 00     dw 0000                     ; CCP return address

XSUB_STACK:
    c3bc  20 * [00]                             ; Stack area

RELOCATION_TABLE:
    03bc  20 80 24 02 40 80 42 41               ; Relocation table. Each byte is a bit mask. Each bit
    03c4  24 10 00 00 08 21 11 09               ; corresponds to a byte in the 0x0200+ range. If bit is
    03cc  04 41 08 81 20 82 22 21               ; set, the corresponding byte probably is an address, and
    0cd4  24 00 01 22 10 00 84 02               ; must be relocated to the resident module range
    03dc  22 11 04 00 00 00 00 00
    03e4  00 00 00 00 00 00 00 00
    03ec  00 00 00 00 00 00 00 00
    03f4  00 00 00 00 00 00 00 00
    03fc  00 00 00 00

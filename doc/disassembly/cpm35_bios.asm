; CP/M BIOS implementation for 35k RAM disk
;
; This implementation provides required functions API for the CP/M system. Console functions are routed to
; the appropriate MonitorF implementation. Disk functions provide read/write facilities for a 35k RAM disk.
;
; The RAM disk is located at 0x5000-0xdc00 memory range (35k) and organized as follows:
; - 8 sectors per track (each track is 1k)
; - 35 tracks
; - no reserved track (and therefore warm boot functionality, that is supposed to load CCP and BDOS from
;   these reserved tracks is switched off)
; - block size is 1k
;
; Surprisingly this implementation exposes 4 disks. All of them eventually use the same RAM storage, but use
; different allocation vectors and CRC storages. 
;
; Overall the implementation looks dirty, and perhaps is a quick adaptation of a sample BIOS implementation:
; - The code contains a lot of garbage
; - The code sometimes refer to some peripheral that is not installed in the system (probably related to 
;   some disk controller initialization)
; - there is a leftover from 26-sector translation table
; - Worm Boot code is switched off, and replaced to JMP to the monitor (perhaps in order to avoid reserving 
;   extra tracks for CCP and BDOS)
ENTRY_POINTS:
    4a00  c3 b3 4a   JMP COLD_BOOT (4ab3)
    4a03  c3 6c f8   JMP MONITOR_MAIN_LOOP (f86c)   ; This shall lead to WARM_BOOT, unused in this implementation
    4a06  c3 61 4b   JMP IS_BUTTON_PRESSED (4b61)
    4a09  c3 64 4b   JMP KBD_INPUT (4b64)
    4a0c  c3 6a 4b   JMP PUT_CHAR (4b6a)
    4a0f  c3 6d 4b   JMP PRINT_CHAR (4b6d)
    4a12  c3 72 4b   JMP OUT_BYTE (4b72)
    4a15  c3 75 4b   JMP IN_BYTE (4b75)
    4a18  c3 78 4b   JMP TRACK_ZERO (4b78)
    4a1b  c3 7d 4b   JMP SELECT_DISK (4b7d)
    4a1e  c3 a7 4b   JMP SELECT_TRACK (4ba7)
    4a21  c3 ac 4b   JMP SELECT_SECTOR (4bac)
    4a24  c3 bb 4b   JMP SET_BUFFER (4bbb)
    4a27  c3 e0 4b   JMP READ_SECTOR (4be0)
    4a2a  c3 00 4c   JMP WRITE_SECTOR (4c00)
    4a2d  c3 70 4b   JMP PRINTER_STATUS (4b70)
    4a30  c3 b1 4b   JMP TRANSLATE_SECTOR (4bb1)

DISK_DESCRIPTOR:
    ; Disk A
    4a33  82 4a     dw SECTOR_TRANSLATION_TABLE (4a82)      ; Sector translation table
    4a35  03 00     dw 0003                                 ; Last directory entry number
    4a37  00 00     dw 0000                                 ; Currently selected track
    4a39  00 00     dw 0000                                 ; Currently selected sector
    4a3b  6e 4c     dw DIRECTORY_BUFFER (4c6e)              ; 128-byte buffer for directory operations
    4a3d  73 4a     dw DISK_PARAMETER_BLOCK (4a73)          ; Disk parameters block address
    4a3f  0d 4d     dw DISK_A_DIR_ENTRY_CRC_VECTOR (4d0d)   ; Address of directory sectors CRC vector
    4a41  ee 4c     dw DISK_A_ALLOCATION_VECTOR (4cee)      ; Address of disk allocation vector

    ; Disk B
    4a43  82 4a     dw SECTOR_TRANSLATION_TABLE (4a82)      ; Sector translation table
    4a45  05 00     dw 0005                                 ; Last directory entry number
    4a47  00 00     dw 0000                                 ; Currently selected track
    4a49  00 00     dw 0000                                 ; Currently selected sector
    4a4b  6e 4c     dw DIRECTORY_BUFFER (4c6e)              ; 128-byte buffer for directory operations
    4a4d  73 4a     dw DISK_PARAMETER_BLOCK (4a73)          ; Disk parameters block address
    4a4f  3c 4d     dw DISK_B_DIR_ENTRY_CRC_VECTOR (4d3c)   ; Address of directory sectors CRC vector
    4a51  1d 4d     dw DISK_B_ALLOCATION_VECTOR (4d1d)      ; Address of disk allocation vector

    ; Disk C
    4a53  82 4a     dw SECTOR_TRANSLATION_TABLE (4a82)      ; Sector translation table
    4a55  05 00     dw 0005                                 ; Last directory entry number
    4a57  00 00     dw 0000                                 ; Currently selected track
    4a59  00 00     dw 0000                                 ; Currently selected sector
    4a5b  6e 4c     dw DIRECTORY_BUFFER (4c6e)              ; 128-byte buffer for directory operations
    4a5d  73 4a     dw DISK_PARAMETER_BLOCK (4a73)          ; Disk parameters block address
    4a5f  6b 4d     dw DISK_C_DIR_ENTRY_CRC_VECTOR (4d6b)   ; Address of directory sectors CRC vector
    4a61  4c 4d     dw DISK_C_ALLOCATION_VECTOR (4d4c)      ; Address of disk allocation vector

    ; Disk D
    4a63  82 4a     dw SECTOR_TRANSLATION_TABLE (4a82)      ; Sector translation table
    4a65  00 00     dw 0005                                 ; Last directory entry number
    4a67  00 00     dw 0000                                 ; Currently selected track
    4a69  00 00     dw 0000                                 ; Currently selected sector
    4a6b  6e 4c     dw DIRECTORY_BUFFER (4c6e)              ; 128-byte buffer for directory operations
    4a6d  73 4a     dw DISK_PARAMETER_BLOCK (4a73)          ; Disk parameters block address
    4a6f  9a 4d     dw DISK_D_DIR_ENTRY_CRC_VECTOR (4d9a)   ; Address of directory sectors CRC vector
    4a71  7b 4d     dw DISK_D_ALLOCATION_VECTOR (4d7b)      ; Address of disk allocation vector

DISK_PARAMETER_BLOCK:
    4a73  08 00         dw 0008                 ; 8 Sectors per track
    4a75  03            db 03                   ; Block shift factor (block size = 1k)
    4a76  07            db 07                   ; Block shift mask (block size = 1k)
    4a77  00            db 00                   ; Extent mask
    4a78  22 00         dw 0022                 ; Total number of blocks - 1 (disk size = 35k)
    4a7a  1f 00         dw 001f                 ; Number of dir entries -1 (32 entries)
    4a7b  00 80         dw 0080                 ; Directory blocks mask (bug? perhaps shall be 8000)
    4a7d  00 00         dw 0000                 ; Directory checksum vector size (bug? perhaps shall be 8)
    4a7f  00 00         dw 0000                 ; Number of reserved tracks (0)



    4a81  00            db 00                   ; unused


SECTOR_TRANSLATION_TABLE:
    4a82  01 02 03 04 05 06 07 08               ; Logical to physical sector number mapping (8 sectors/track)

    4a8a  09 0a 0b 0c 0d 0e 0f 10               ; Unused. Perhaps this is a leftover from a template BIOS
    4a92  11 12 13 14 15 16 17 18               ; implementation that would use floppy disk drive with 26
    4a9a  19 1a                                 ; sectors per track


WELCOME_STR:
    4a9c  0d 0d 0a 33 35 4b 20 43   db 0x0d, 0x0d, 0x0a, "35K C"
    4aa4  50 2f 4d 20 56 45 52 53   db "P/M VERS"
    4aac  20 32 2e 32 0d 0a 00      db " 2.2", 0x0d, 0x0a, 0x00

; Entry point on the reboot
;
; Performs initial initialization, prints a welcome message, and starts the CP/M CCP
COLD_BOOT:
    4ab3  31 00 01   LXI SP, 0100               ; Set up stack

    4ab6  21 9c 4a   LXI HL, WELCOME_STR (4a9c) ; Print welcome message
    4ab9  cd d3 4b   CALL PRINT_STR (4bd3)

    4abc  af         XRA A                      ; Reset CCP's current disk and user code]
    4abd  32 04 00   STA 0004

    4ac0  c3 0f 4b   JMP START_CPM (4b0f)


; Note: DEAD CODE!!!!
;
; Warm Boot
;
; This function performs worm boot, which means BIOS is already in the memory, but CCP and BDOS shall
; be loaded from the disk. The function loads 0x2c sectors (0x1600 bytes) from the first several sectors
; of the disk into 0x3400-0x49ff memory range (address 0x4a00 and above is used by BIOS)
WARM_BOOT:
    4ac3  31 80 00   LXI SP, 0080               ; Set the stack

    4ac6  0e 0a      MVI C, 0a                  ; ??? unknown value
    4ac8  c5         PUSH BC

BOOT_ATTEMPT:
    4ac9  01 00 34   LXI BC, 3400               ; Start address of the CP/M CCP
    4acc  cd bb 4b   CALL SET_BUFFER (4bbb)

    4acf  0e 00      MVI C, 00                  ; Select disk 0
    4ad1  cd 7d 4b   CALL SELECT_DISK (4b7d)

    4ad4  0e 00      MVI C, 00                  ; Select track 0
    4ad6  cd a7 4b   CALL SELECT_TRACK (4ba7)

    4ad9  0e 02      MVI C, 02                  ; Select sector 2 ?????
    4adb  cd ac 4b   CALL SELECT_SECTOR (4bac)

    4ade  c1         POP BC
    4adf  06 2c      MVI B, 2c                  ; Will be copying 0x2c sectors  

WARM_BOOT_LOOP:
    4ae1  c5         PUSH BC

    4ae2  cd c1 4b   CALL DO_READ_SECTOR (4bc1) ; Read next sector
    4ae5  c2 49 4b   JNZ BAD_SECTOR (4b49)

    4ae8  2a 6c 4c   LHLD DATA_BUF_PTR (4c6c)   ; Load the current buffer ptr

    4aeb  11 80 00   LXI DE, 0080               ; Advance to the next chunk of data
    4aee  19         DAD DE

    4aef  44         MOV B, H                   ; Let it BIOS about the new address
    4af0  4d         MOV C, L
    4af1  cd bb 4b   CALL SET_BUFFER (4bbb)

    4af4  3a 6b 4c   LDA CURRENT_SECTOR (4c6b)  ; Check if we reached the last sector on the track
    4af7  fe 1a      CPI A, 1a
    4af9  da 05 4b   JC WARM_BOOT_NEXT_SECT (4b05)  ; If not maximum - just go and select next sector

    4afc  3a 6a 4c   LDA CURRENT_TRACK (4c6a)   ; Otherwise increment the track counter
    4aff  3c         INR A

    4b00  4f         MOV C, A                   ; Select the new track
    4b01  cd a7 4b   CALL SELECT_TRACK (4ba7)

    4b04  af         XRA A                      ; And zero the sector counter

WARM_BOOT_NEXT_SECT:
    4b05  3c         INR A                      ; Increment the sector counter
    4b06  4f         MOV C, A
    4b07  cd ac 4b   CALL SELECT_SECTOR (4bac)

    4b0a  c1         POP BC                     ; Repeat for all 0x2c sectors
    4b0b  05         DCR B
    4b0c  c2 e1 4a   JNZ WARM_BOOT_LOOP (4ae1)


; Start CP/M CCP
;
; This function gets prepared to run the CCP:
; - Disk buffer is set to the default location (0x0080)
; - 0x0000 address is filled with JMP WARM_BOOT instruction
; - 0x0005 address is filled with JMP BDOS instruction
; - 0x0038 address is filled with JMP MONITOR instruction
; - 0x0004 address is filled with user code and current disk code (used by CCP)
; - CCP started from address 0x3400
START_CPM:
    4b0f  f3         DI                         ; Disable interrupts while preparing entry points

    4b10  3e 12      MVI A, 12                  ; ???? setting some values in not-existing port
    4b12  d3 fd      OUT fd                     ; Perhaps just quick and dirty port from other system

    4b14  af         XRA A
    4b15  d3 fc      OUT fc

    4b17  3e 7e      MVI A, 7e
    4b19  d3 fc      OUT fc

    4b1b  af         XRA A
    4b1c  d3 f3      OUT f3

    4b1e  01 80 00   LXI BC, 0080               ; Set the default buffer address
    4b21  cd bb 4b   CALL SET_BUFFER (4bbb)

    4b24  3e c3      MVI A, c3                  ; Put JMP opcode to 0000 to handle warm restart
    4b26  32 00 00   STA 0000

    4b29  21 03 4a   LXI HL, 4a03               ; Set the WARM_START address for that JMP instruction
    4b2c  22 01 00   SHLD 0001

    4b2f  32 05 00   STA 0005                   ; Prepare JMP <BDOS> instruction at 0x0005
    4b32  21 06 3c   LXI HL, 3c06
    4b35  22 06 00   SHLD 0006

    4b38  32 38 00   STA 0038                   ; Prepare JMP <MonitorF> instruction at 0x0038
    4b3b  21 00 f8   LXI HL, f800
    4b3e  22 39 00   SHLD 0039

    4b41  3a 04 00   LDA 0004                   ; Set the user code as CCP argument
    4b44  4f         MOV C, A

    4b45  fb         EI                         ; Enable interrupts and start CCP
    4b46  c3 00 34   JMP 3400


; Note: DEAD CODE
;
; This is a part of WARM_BOOT function, that performs another boot attempt if the previous
; attempt failed due to disk read error. If the system can't boot after 10 attempts, the flow is
; passed to the monitor.
BAD_SECTOR:
    4b49  c1         POP BC                     ; Decrease attempt counter
    4b4a  0d         DCR C
    4b4b  ca 52 4b   JZ BOOT_FAILED (4b52)

    4b4e  c5         PUSH BC                    ; Perform another boot attempt
    4b4f  c3 c9 4a   JMP BOOT_ATTEMPT (4ac9)

BOOT_FAILED:
    4b52  21 5b 4b   LXI HL, BOOT_STR (4b5b)    ; Print boot failed message
    4b55  cd d3 4b   CALL PRINT_STR (4bd3)

    4b58  c3 0f ff   JMP ff0f                   ; Perhaps this should be a call to a monitor handler, but
                                                ; this is a wrong address for UT-88

BOOT_STR:
    4b5b  3f 42 4f 4f 54 00         db "?BOOT", 0x00


IS_BUTTON_PRESSED:
    4b61  c3 12 f8   JMP MONITOR_IS_BUTTON_PRESSED (f812)

KBD_INPUT:
    4b64  cd 03 f8   CALL MONITOR_KBD_INPUT (f803)
    4b67  e6 7f      ANI A, 7f                  ; Check the received button scan code (if anything pressed)
    4b69  c9         RET

PUT_CHAR:
    4b6a  c3 09 f8   JMP MONITOR_PUT_CHAR (f809)

PRINT_CHAR:
    4b6d  c3 0f f8   JMP MONITOR_PRINT_CHAR (f80f)

PRINTER_STATUS:
    4b70  af         XRA A                      ; Printer always ready
    4b71  c9         RET

OUT_BYTE:
    4b72  c3 0c f8   JMP MONITOR_OUT_BYTE (f80c)

IN_BYTE:
    4b75  c3 06 f8   JMP MONITOR_IN_BYTE (f806)

TRACK_ZERO:
    4b78  0e 00      MVI C, 00
    4b7a  c3 a7 4b   JMP SELECT_TRACK (4ba7)

SELECT_DISK:
    4b7d  21 00 00   LXI HL, 0000

    4b80  79         MOV A, C                   ; Support only 4 disks
    4b81  fe 04      CPI A, 04
    4b83  d0         RNC

    4b84  32 66 4c   STA CURRENT_DISK (4c66)

    4b87  69         MOV L, C                   ; Multiply disk number by 16 (sizeof Disk Descriptor)
    4b88  26 00      MVI H, 00
    4b8a  29         DAD HL
    4b8b  29         DAD HL
    4b8c  29         DAD HL
    4b8d  29         DAD HL

    4b8e  11 33 4a   LXI DE, DISK_DESCRIPTOR (4a33) ; Calculate disk descriptor address
    4b91  19         DAD DE
    4b92  c9         RET


; Note: DEAD CODE
; (similar to the previous function)
????:
    4b93  21 68 74   LXI HL, 7468
    4b96  7e         MOV A, M
    4b97  e6 cf      ANI A, cf
    4b99  b0         ORA B
    4b9a  77         MOV M, A

    4b9b  69         MOV L, C
    4b9c  26 00      MVI H, 00
    4b9e  29         DAD HL
    4b9f  29         DAD HL
    4ba0  29         DAD HL
    4ba1  29         DAD HL

    4ba2  11 33 4a   LXI DE, DISK_DESCRIPTOR (4a33)
    4ba5  19         DAD DE

    4ba6  c9         RET

; Select track
; (remember track number for further use in read/write sector function)
;
; Arguments: C - track number
SELECT_TRACK:
    4ba7  21 6a 4c   LXI HL, CURRENT_TRACK (4c6a)
    4baa  71         MOV M, C
    4bab  c9         RET

; Select sector
; (remember sector number for further use in read/write sector function)
;
; Arguments: C - sector number
SELECT_SECTOR:
    4bac  21 6b 4c   LXI HL, CURRENT_SECTOR (4c6b)
    4baf  71         MOV M, C
    4bb0  c9         RET

; Translate sector
;
; Interface function that converts provided logical sector number (in C register) to physical
; sector number according to the translation table in HL
;
; Arguments:
; C - logical sector number
; HL - pointer to the sector translation table
TRANSLATE_SECTOR:
    4bb1  06 00      MVI B, 00                  ; Calculate offset in translation table
    4bb3  eb         XCHG
    4bb4  09         DAD BC

    4bb5  7e         MOV A, M                   ; Read the translated sector index, and set as cur sector
    4bb6  32 6b 4c   STA CURRENT_SECTOR (4c6b)

    4bb9  6f         MOV L, A                   ; Return translated value
    4bba  c9         RET


; Set the buffer address to be used in read/write sector functions
;
; Arguments: BC - pointer to the data buffer
SET_BUFFER:
    4bbb  69         MOV L, C
    4bbc  60         MOV H, B
    4bbd  22 6c 4c   SHLD DATA_BUF_PTR (4c6c)
    4bc0  c9         RET


; Note: DEAD CODE
;
; Perform sector read and do something unclear then, probably check the result
DO_READ_SECTOR:
    4bc1  0e 04      MVI C, 04
    4bc3  cd e0 4b   CALL READ_SECTOR (4be0)
    4bc6  cd f0 4b   CALL 4bf0
    4bc9  c9         RET

    4bca  0e 06      MVI C, 06                  ; Even more dead code, does the same as above
    4bcc  cd e0 4b   CALL READ_SECTOR (4be0)
    4bcf  cd f0 4b   CALL 4bf0
    4bd2  c9         RET


; Print a NULL-terminated string to the console
PRINT_STR:
    4bd3  7e         MOV A, M                   ; Load next symbol until terminating zero is reached
    4bd4  b7         ORA A
    4bd5  c8         RZ

    4bd6  e5         PUSH HL                    ; Print the char
    4bd7  4f         MOV C, A
    4bd8  cd 6a 4b   CALL PUT_CHAR (4b6a)
    4bdb  e1         POP HL

    4bdc  23         INX HL                     ; Repeat for the next symbol
    4bdd  c3 d3 4b   JMP PRINT_STR (4bd3)


; Read the sector
;
; Reads previously selected disk/track/sector to the selected data buffer
READ_SECTOR:
    4be0  cd 20 4c   CALL CALC_SECTOR_ADDRESS (4c20)    ; Calculate sector address

    4be3  06 80      MVI B, 80                  ; Will copy 0x80 bytes

    4be5  2a 68 4c   LHLD SECTOR_ADDRESS (4c68) ; Load sector address to DE
    4be8  eb         XCHG

    4be9  2a 6c 4c   LHLD DATA_BUF_PTR (4c6c)   ; Load the data buffer to HL

MEMCOPY_DE_HL:
    4bec  1a         LDAX DE                    ; Copy from disk area to the buffer
    4bed  77         MOV M, A
    4bee  23         INX HL
    4bef  13         INX DE

????:
    4bf0  05         DCR B                      ; Advance to the next byte
    4bf1  c2 ec 4b   JNZ MEMCOPY_DE_HL (4bec)

    4bf4  af         XRA A                      ; Return success
    4bf5  c9         RET


; Piece of DEAD CODE
    4bf6  4c         MOV C, H
    4bf7  74         MOV M, H
    4bf8  3a 66 74   LDA 7466
    4bfb  b7         ORA A
    4bfc  3e 67      MVI A, 67
    4bfe  06 74      MVI B, 74


; Write the sector
;
; Write 0x80 bytes of data from the previously set data buffer to the selected disk/track/sector
WRITE_SECTOR:
    4c00  cd 20 4c   CALL CALC_SECTOR_ADDRESS (4c20)    ; Calculate the sector address

    4c03  06 80      MVI B, 80                  ; Will copy 0x80 bytes

    4c05  2a 68 4c   LHLD SECTOR_ADDRESS (4c68) ; Load sector address to DE
    4c08  eb         XCHG

    4c09  2a 6c 4c   LHLD DATA_BUF_PTR (4c6c)   ; Load data buffer to HL

WRITE_SECTOR_LOOP:
    4c0c  7e         MOV A, M                   ; Copy data from data buffer to the disk area
    4c0d  12         STAX DE
    4c0e  23         INX HL
    4c0f  13         INX DE
    4c10  05         DCR B
    4c11  c2 0c 4c   JNZ WRITE_SECTOR_LOOP (4c0c)

    4c14  af         XRA A                      ; Return success
    4c15  c9         RET


; DEAD CODE
    4c16  10         db 10
    4c17  74         MOV M, H
    4c18  cd 3f 74   CALL 743f
    4c1b  fe 02      CPI A, 02
    4c1d  ca 32 74   JZ 7432


; Calculate sector address on the RAM Disk
;
; This function convert track/sector number into the address in the RAM disk:
; SECTOR_ADDRESS = 0x5000 + 0x400*track + 0x80*sector
CALC_SECTOR_ADDRESS:
    4c20  3a 6a 4c   LDA CURRENT_TRACK (4c6a)   ; HL = cur_track * track_data_size (0x400)
    4c23  11 00 04   LXI DE, 0400
    4c26  cd 43 4c   CALL MUL_DE_BY_A (4c43)
    4c29  22 60 4c   SHLD TRACK_OFFSET (4c60)

    4c2c  3a 6b 4c   LDA CURRENT_SECTOR (4c6b)  ; DE = cur_sect * sector_size (0x80)
    4c2f  3d         DCR A                      ; Sectors are 1-based
    4c30  11 80 00   LXI DE, 0080
    4c33  cd 43 4c   CALL MUL_DE_BY_A (4c43)
    4c36  eb         XCHG

    4c37  2a 60 4c   LHLD TRACK_OFFSET (4c60)   ; Add the two values
    4c3a  19         DAD DE

    4c3b  11 00 50   LXI DE, 5000               ; Add the disk base address (0x5000)
    4c3e  19         DAD DE
    4c3f  22 68 4c   SHLD SECTOR_ADDRESS (4c68)

    4c42  c9         RET


; Multiply DE by A
MUL_DE_BY_A:
    4c43  21 00 00   LXI HL, 0000               ; Result accumulator

    4c46  b7         ORA A                      ; Return if no shifts needed
    4c47  c8         RZ

MUL_DE_BY_A_LOOP:
    4c48  19         DAD DE                     ; Add DE
    4c49  3d         DCR A                      ; Repeat until counter is zero
    4c4a  c8         RZ
    4c4b  c3 48 4c   JMP MUL_DE_BY_A_LOOP (4c48)


; DEAD CODE
    4c4e  19         DAD DE
    4c4f  ce 00      ACI A, 00
    4c51  0d         DCR C
    4c52  c2 49 4c   JNZ 4c49
    4c55  c9         RET


TRACK_OFFSET:
    4c60  00 00         dw 0000                 ; Offset of the current track (from the beginning of disk)

CURRENT_DISK:
    4c66  00            db 00

SECTOR_ADDRESS:
    4c68  00 00         dw 0000                 ; Address of the currently selected sector on disk

CURRENT_TRACK:
    4c6a  00            db 00

CURRENT_SECTOR:
    4c6b  00            db 00

DATA_BUF_PTR:
    4c6c  00 00         dw 0000

DIRECTORY_BUFFER:
    4c6e  00            db 128*0x00             ; 128 byte buffer for directory operations

DISK_A_ALLOCATION_VECTOR:
    4cee  0x1f x 00     db 0x1f*00              ; Disk allocation vector, 1 bit per block (5 bytes would be enough)

DISK_A_DIR_ENTRY_CRC_VECTOR:
    4d0d  16 x 00       db 16 x 00              ; CRC of 8 directory sectors (8 bytes would be enough)

DISK_B_ALLOCATION_VECTOR:
    4d1d  0x1f x 00     db 0x1f*00              ; Disk allocation vector, 1 bit per block (5 bytes would be enough)

DISK_B_DIR_ENTRY_CRC_VECTOR:
    4d3c  16 x 00       db 16 x 00              ; CRC of 8 directory sectors (8 bytes would be enough)

DISK_C_ALLOCATION_VECTOR:
    4d4c  0x1f x 00     db 0x1f*00              ; Disk allocation vector, 1 bit per block (5 bytes would be enough)

DISK_C_DIR_ENTRY_CRC_VECTOR:
    4d6b  16 x 00       db 16 x 00              ; CRC of 8 directory sectors (8 bytes would be enough)

DISK_D_ALLOCATION_VECTOR:
    4d7b  0x1f x 00     db 0x1f*00              ; Disk allocation vector, 1 bit per block (5 bytes would be enough)

DISK_D_DIR_ENTRY_CRC_VECTOR:
    4d9a  16 x 00       db 16 x 00              ; CRC of 8 directory sectors (8 bytes would be enough)

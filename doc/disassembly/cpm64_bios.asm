; CP/M-64 Basic Input/Output System (BIOS)
;
; This code is loaded to the 0xda00-0xdbff by CP/M initial bootloader, and initially is located at
; 0x4a00-0x4bff address range of the CP/M binary.
;
; The goal of the module is to provide CP/M upper levers a centralized entry point to various import/output
; routines:
; - Console input and output (in case of UT-88 is a keyboard and display)
; - Printer output (in case of UT-88 is mapped to the same display console)
; - Tape puncher and reader (in case of UT-88 magnetic tape recorder is used instead)
; - Number of functions to read and write a sector on the disk
;
; In UT-88 a Quasik Disk is used as a disk drive. The Quasi disk is a battery powered RAM, that consists
; of four 64k pages. This gives 256k capacity in total. Within a single page data can be addressed using
; stack read and write operations within 0x0000-0xffff memory range. Stack read/write approach provides
; possibility to use main RAM and quasi disk simultaneously on the same address range. Quasi disk page
; selection (as well as disconnection from the stack read/write operations) is performed by writing a
; configuration byte to 0x40 port.
; 
; Quasi Disk "physical" configuration is: 
; - 256 tracks
; - 8 sectors per track
; - 128 bytes per sector
;
; This gives the disk of size 256k, which is logically distributed as follows:
; - First 6 tracks are reserved for the system (see last field of the DISK_PARAMETER_BLOCK structure).
;   Bootloader is responsible for storing there CP/M system components during cols start. On warm boot
;   BIOS will load BDOS and CCP parts from these tracks to the memory.
; - Remaining 250 tracks are data tracks, each track represents a single data block of size 1k
; - Reserved directory blocks data field of DISK_PARAMETER_BLOCK structure allocates the first data block
;   for the files directory (which in turn will contain 32 directory entries 32 bytes each)
;
; Note: Surprisingly, CP/M OS does not measure disk size in tracks. Instead it is measured in blocks.
; In UT-88 case each block conincidentally matches full track, but this is not true for real diskettes
; with 77 tracks and 26 sectors. In that case first 2 tracks are reserved, while remaining 75 tracks
; 26 sectors each provide 243 one kilobyte blocks, and 6 sectors remaining unused.
;
; The module provides the following entry points:
; 0xda00    - Cold boot (assuming that CP/M is loaded to the memory by a bootloader)
; 0xda03    - Warm boot (assuming that BIOS part is already loaded, devices are initialized, but CCP
;             and BDOS parts may need to be read from disk first)
; 0xda06    - Check console input readines (in case of UT-88 checks if a button is pressed)
;             Return A=0x00 if no buttons pressed, and A=0xff if any button is pressed
; 0xda09    - Read the byte from console (in case of UT-88 read the symbol from the keyboard)
;             Returns character code in A register
; 0xda0c    - Put the char to the console (prints the character using escape sequence processing addon)
;             Arguments: C register - character to output
; 0xda0f    - Print character to printer (UT-88 does not have a printer, character is displayer to the console)
;             Arguments: C register - character to output
; 0xda12    - Output a byte to the tape
;             Arguments: C register - character to output
; 0xda15    - Input a byte from the tape
;             Returns received byte in A register
; 0xda18    - Move to track #0 of the current disk
; 0xda1b    - Select the disk
;             Arguments: C register - disk to select (the only disk is supported is 0x00)
; 0xda1e    - Select the disk track
;             Arguments: C register - track to select
; 0xda21    - Select sector on the track
;             Arguments: C register - sector to select (1-based numbering)
; 0xda24    - Set the buffer to read/write sector data
;             Arguments: BC - pointer to the buffer to use
; 0xda27    - Read the selected sector to previously set buffer
; 0xda2a    - Write the buffer data to the selected sector
; 0xda2d    - Check if printer is ready
;             Always returns 0xff "Ready" status in A register
; 0xda30    - "Logical" to "physical" sector translation
;             Arguments: DE - translation table pointer, C - logical sector number
;             Returns: L - physical sector number
;
; Important variables:
; 0x0000    - JMP WARM_BOOT opcode
; 0x0003    - I/O Byte ?????
; 0x0004    - ????
; 0x0005    - JMP BDOS_START opcode
; 0x0080    - Default read/write buffer (128 bytes)
; 0xdbec    - Quasi disk page that matches selected track
; 0xdbed    - Selected track number (within selected Quasi disk page)
; 0xdbee    - Selected sector number (within selected disl and track)
; 0xdbef    - Buffer address
; 0xdbf1    - Current disk number
; 0xdbf2    - Calculated offset of the selected disk/page/track/sector
; 0xdbf4    - Save stack pointer while doing quasi disk operations

ENTRY_POINTS:
    da00  c3 80 da   JMP COLD_BOOT (da80)           ; Cold boot
    da03  c3 9e da   JMP WARM_BOOT (da9e)           ; Warm boot
    da06  c3 12 f8   JMP MONITOR_IS_BUTTON_PRESSED (f812)   ; Check if there is a console input ready
    da09  c3 03 f8   JMP MONITOR_KBD_INPUT (f803)   ; Console input
    da0c  c3 00 f5   JMP MONITOR_ADDON_PUT_CHAR (f500)  ; Console output
    da0f  c3 09 f8   JMP MONITOR_PUT_CHAR (f809)    ; Printer (List) output
    da12  c3 0c f8   JMP MONITOR_OUT_BYTE (f80c)    ; Output a byte to the tape
    da15  c3 06 f8   JMP MONITOR_IN_BYTE (f806)     ; Input a byte from the tape
    da18  c3 0c db   JMP TRACK_ZERO (db0c)          ; Move to track 0 on the current disk
    da1b  c3 11 db   JMP SELECT_DISK (db11)         ; Select current disk
    da1e  c3 2a db   JMP SELECT_TRACK (db2a)        ; Select track on the current disk
    da21  c3 5e db   JMP SELECT_SECTOR (db5e)       ; Select sector on currently selected disk and track
    da24  c3 6d db   JMP SET_BUFFER (db6d)          ; Set the buffer for reading and writing sectors
    da27  c3 73 db   JMP READ_SECTOR (db73)         ; Read selected sector to the provided buffer
    da2a  c3 9e db   JMP WRITE_SECTOR (db9e)        ; Write data buffer to selected sector
    da2d  c3 09 db   JMP PRINTER_STATUS (db09)      ; Get the printer (list) status
    da30  c3 63 db   JMP TRANSLATE_SECTOR (db63)    ; "Logical" to "physical" sector translation

DISK_DESCRIPTION:
    da33  43 da      dw SECTOR_TRANSLATION_TABLE (da43) ; Pointer to the sector translation table, or 0000
    da35  00 00      dw 0000                            ; Last directory entry number
    da37  00 00      dw 0000                            ; Currently selected track
    da39  00 00      dw 0000                            ; Currently selected sector
    da3b  f6 db      dw DIRECTORY_BUFFER (dbf6)         ; Pointer to the 128b buffer for directory operations
    da3d  4b da      dw DISK_PARAMETER_BLOCK (da4b)     ; Pointer to the Disk Parameter Block (DPB)
    da3f  95 dc      dw DIR_ENTRY_CRC_VECTOR (dc95)     ; Address of directory sectors CRC vector
    da41  76 dc      dw dc76                            ; Address of disk allocation information ????
    
SECTOR_TRANSLATION_TABLE:
    da43  01 02 03 04 05 06 07 08
    
DISK_PARAMETER_BLOCK:
    da4b  08 00      dw 0x0008                  ; Sectors per table (8)
    da4d  03         db 03                      ; BSH (Block shift factor)
    da4e  07         db 07                      ; BLM (Block mask). BSH and BLM determine block size as 1k
    da4f  00         db 00                      ; Extent mask
    da50  f9 00      dw 00f9                    ; Total number of blocks - 1
    da52  1f 00      dw 001f                    ; Number of directory entries - 1
    da54  80         db 80                      ; AL0 ???? Reserved directory blocks
    da55  00         db 00                      ; AL1 ???? Reserved directory blocks
    da56  08 00      dw 0008                    ; Size of the directory checksum vector
    da58  06 00      dw 0006                    ; Number of reserved tracks in the beginning

WELCOME_STR:
    da5a  1f 0a 20 43 50 4d 20 56   db 0x1f, 0x0a, " CPM V"
    da62  20 2d 20 32 2e 32 20 20   db " - 2.2  "
    da6a  44 49 53 4b 20 52 41 4d   db "DISK RAM"
    da72  20 2d 20 32 35 36 4b 2e   db " - 256K."
    da7a  0a 00                     db 0x0a, 0x00


; Very initial boot of the system.
; 
; The function assumes that CP/M is loaded to the memory already, so it just prints
; the welcome message and starts the CP/M OS
COLD_BOOT:
    da80  31 00 01   LXI SP, 0100               ; Initialize the stack pointer

    da83  21 5a da   LXI HL, WELCOME_STR (da5a) ; Print the welcome message
    da86  cd 93 da   CALL PRINT_STR (da93)

    da89  af         XRA A                      ; ?????
    da8a  32 04 00   STA 0004

    da8d  32 03 00   STA 0003                   ; Clear the I/O byte

    da90  c3 e7 da   JMP START_CPM (dae7)


; Print a string pointed by HL to the console
PRINT_STR:
    da93  7e         MOV A, M                   ; Print characters one by one, until zero is reached
    da94  b7         ORA A
    da95  c8         RZ

    da96  4f         MOV C, A                   ; Print the caracter using Monitor's routine
    da97  cd 09 f8   CALL MONITOR_PUT_CHAR (f809)

    da9a  23         INX HL                     ; Advance to the next character in the string
    da9b  c3 93 da   JMP PRINT_STR (da93)

; Warm Boot
;
; The function assumes that BIOS is already loaded and working, all devices are initialized.
; At the same time CCP and BDOS parts may be unloaded by transit application, so these parts
; needs to be loaded from disk first.
WARM_BOOT:
    da9e  31 80 00   LXI SP, 0080               ; Initialize stack pointer (why 0x80? Cold boot uses 0x100)
    
    daa1  0e 00      MVI C, 00                  ; Select the disk and track
    daa3  cd 11 db   CALL SELECT_DISK (db11)
    daa6  cd 0c db   CALL TRACK_ZERO (db0c)

    daa9  06 2c      MVI B, 2c                  ; Number of sectors to read (0x2c*0x80 = 0x1600 bytes)
    daab  0e 00      MVI C, 00
    daad  16 01      MVI D, 01                  ; First sector number
    daaf  21 00 c4   LXI HL, c400               ; Target loading address

READ_NEXT_SECTOR:
    dab2  c5         PUSH BC
    dab3  d5         PUSH DE
    dab4  e5         PUSH HL

    dab5  4a         MOV C, D                   ; Select next sector
    dab6  cd 5e db   CALL SELECT_SECTOR (db5e)

    dab9  c1         POP BC
    daba  c5         PUSH BC

    dabb  cd 6d db   CALL SET_BUFFER (db6d)     ; Read the sector
    dabe  cd 73 db   CALL READ_SECTOR (db73)

    dac1  fe 00      CPI A, 00                  ; Check reading error
    dac3  c2 9e da   JNZ WARM_BOOT (da9e)

    dac6  e1         POP HL                     ; Advance the buffer pointer by 128 bytes
    dac7  11 80 00   LXI DE, 0080
    daca  19         DAD DE

    dacb  d1         POP DE                     ; Decrement remaining sectors counter
    dacc  c1         POP BC
    dacd  05         DCR B
    dace  ca e7 da   JZ START_CPM (dae7)

    dad1  14         INR D                      ; Advance to the next sector
    dad2  7a         MOV A, D
    dad3  fe 09      CPI A, 09
    dad5  da b2 da   JC READ_NEXT_SECTOR (dab2)

    dad8  16 01      MVI D, 01                  ; Read next track
    dada  0c         INR C
    dadb  c5         PUSH BC
    dadc  d5         PUSH DE
    dadd  e5         PUSH HL
    dade  cd 2a db   CALL SELECT_TRACK (db2a)
    dae1  e1         POP HL
    dae2  d1         POP DE
    dae3  c1         POP BC
    dae4  c3 b2 da   JMP READ_NEXT_SECTOR (dab2)

; Start the CPM
;
; This function does remaining initialization of the disk system, sets some entry points,
; and passes the control to CP/M command processor
START_CPM:
    dae7  f3         DI                         ; Store WARM_BOOT address at 0x0000 jump command
    dae8  21 03 da   LXI HL, WARM_BOOT (da03)
    daeb  22 01 00   SHLD 0001

    daee  01 80 00   LXI BC, 0080               ; Set the default buffer address to use
    daf1  cd 6d db   CALL SET_BUFFER (db6d)

    daf4  3e c3      MVI A, c3                  ; Put the JMP opcode to 0x0000
    daf6  32 00 00   STA 0000

    daf9  32 05 00   STA 0005                   ; Store JMP BDOS_ENTRY opcode to 0x0005
    dafc  21 06 cc   LXI HL, BDOS_ENTRY (cc06)
    daff  22 06 00   SHLD 0006

    db02  3a 04 00   LDA 0004                   ; ????
    db05  4f         MOV C, A
    db06  c3 00 c4   JMP c400                   ; Jump to CP/M command processor


PRINTER_STATUS:
    db09  3e ff      MVI A, ff                  ; Printer status is always ready
    db0b  c9         RET

TRACK_ZERO:
    db0c  0e 00      MVI C, 00
    db0e  c3 2a db   JMP SELECT_TRACK (db2a)

; Select current disk
;
; Arguments:
; C - disk number (zero based)
;
; Returns:
; HL - pointer to disk description record, or 0x0000 in case of error
SELECT_DISK:
    db11  21 00 00   LXI HL, 0000

    db14  79         MOV A, C                   ; Save the disk number
    db15  32 f1 db   STA CUR_DISK_NO (dbf1)

    db18  fe 01      CPI A, 01                  ; We have just 1 disk, otherwise return an error
    db1a  d0         RNC

    db1b  3a f1 db   LDA CUR_DISK_NO (dbf1)

    db1e  6f         MOV L, A                   ; HL = A << 4
    db1f  26 00      MVI H, 00
    db21  29         DAD HL
    db22  29         DAD HL
    db23  29         DAD HL
    db24  29         DAD HL

    db25  11 33 da   LXI DE, DISK_DESCRIPTION (da33); Return the entry in disk description table
    db28  19         DAD DE

    db29  c9         RET

; Select track of the current disk
;
; Arguments:
; C - track number
SELECT_TRACK:
    db2a  3e fe      MVI A, fe                  ; Select Page 0 for tracks under 0x40
    db2c  32 ec db   STA CURRENT_QUASI_DISK_PAGE (dbec)

    db2f  79         MOV A, C
    db30  fe 40      CPI A, 40
    db32  da 59 db   JC SELECT_TRACK_EXIT (db59)

    db35  d6 40      SUI A, 40                  ; Select Page 1 for next 0x40 tracks
    db37  4f         MOV C, A
    db38  3e fd      MVI A, fd
    db3a  32 ec db   STA CURRENT_QUASI_DISK_PAGE (dbec)

    db3d  79         MOV A, C
    db3e  fe 40      CPI A, 40
    db40  da 59 db   JC SELECT_TRACK_EXIT (db59)

    db43  d6 40      SUI A, 40                  ; Select Page 2 for next 0x40 tracks
    db45  4f         MOV C, A
    db46  3e fb      MVI A, fb
    db48  32 ec db   STA CURRENT_QUASI_DISK_PAGE (dbec)

    db4b  79         MOV A, C
    db4c  fe 40      CPI A, 40
    db4e  da 59 db   JC SELECT_TRACK_EXIT (db59)

    db51  d6 40      SUI A, 40                  ; Select Page 3 for next 0x40 tracks
    db53  4f         MOV C, A
    db54  3e f7      MVI A, f7
    db56  32 ec db   STA CURRENT_QUASI_DISK_PAGE (dbec)

SELECT_TRACK_EXIT:
    db59  21 ed db   LXI HL, CURRENT_TRACK (dbed); Save the track number on selected page
    db5c  71         MOV M, C
    db5d  c9         RET


; Select sector of the current disk and track
;
; Arguments:
; C - track number
SELECT_SECTOR:
    db5e  21 ee db   LXI HL, CURRENT_SECTOR (dbee)
    db61  71         MOV M, C
    db62  c9         RET


; Sector translation is needed on old machines to allow enough time to 
; finish reading one sector and processing its buffers, while the disk has already rotated to 
; the next sector. The machine is logically reading N+1 sector, while physically it will read
; sector located at other place.
;
; As for the implementation, this function is a simple table lookup.
; No sectors translation needed for RAM quasi disk
;
; Arguments:
; DE - pointer to sector translation table (typically da43)
; C  - logical sector number
;
; Return:
; L  - physical sector number
TRANSLATE_SECTOR:
    db63  06 00      MVI B, 00                  ; Calculate pointer to the sector translation table
    db65  eb         XCHG
    db66  09         DAD BC

    db67  7e         MOV A, M                   ; Read the value and set it to the current sector
    db68  32 ee db   STA CURRENT_SECTOR (dbee)

    db6b  6f         MOV L, A                   ; Return the value in L
    db6c  c9         RET


; Set read/write buffer address
;
; Arguments:
; BC    - pointer to the buffer
SET_BUFFER:
    db6d  69         MOV L, C
    db6e  60         MOV H, B
    db6f  22 ef db   SHLD BUFFER_ADDR (dbef)
    db72  c9         RET


; Read selected track/sector to previously set buffer
;
; This function reads 128 bytes sector, previously selected by select SELECT_DISK/TRACK/SECTOR functions.
; Reading is performed into the buffer previously provided by SET_BUFFER function
READ_SECTOR:
    db73  cd c8 db   CALL CALCULATE_SECTOR_ADDR (dbc8)  ; Calculate sector offset

    db76  21 00 00   LXI HL, 0000               ; Save stack pointer
    db79  39         DAD SP
    db7a  22 f4 db   SHLD SAVE_SP (dbf4)
    
    db7d  2a f2 db   LHLD SECTOR_OFFSET (dbf2)  ; Set the calculated sector offset to SP
    db80  f9         SPHL

    db81  2a ef db   LHLD BUFFER_ADDR (dbef)    ; Set the buffer address

    db84  06 40      MVI B, 40                  ; 0x40 words (0x80 bytes) in the sector

    db86  3a ec db   LDA CURRENT_QUASI_DISK_PAGE (dbec) ; Select the quasi disk page
    db89  d3 40      OUT 40

READ_SECTOR_LOOP:
    db8b  d1         POP DE                     ; Read 2 bytes from the quasi disk using stack read operations,
    db8c  73         MOV M, E                   ; and store them at [HL]
    db8d  23         INX HL
    db8e  72         MOV M, D
    db8f  23         INX HL
    db90  05         DCR B
    db91  c2 8b db   JNZ READ_SECTOR_LOOP (db8b)

SECTOR_READ_WRITE_EXIT:
    db94  3e ff      MVI A, ff                  ; Disconnect from the quasi disk
    db96  d3 40      OUT 40

    db98  2a f4 db   LHLD SAVE_SP (dbf4)        ; Restore original stack pointer
    db9b  f9         SPHL

    db9c  af         XRA A                      ; Indicate no error
    db9d  c9         RET



WRITE_SECTOR:
    db9e  cd c8 db   CALL CALCULATE_SECTOR_ADDR (dbc8)  ; Calculate the sector address

    dba1  19         DAD DE                     ; And add another sector on top (DE shall contain 0x80)
    dba2  22 f2 db   SHLD SECTOR_OFFSET (dbf2)

    dba5  21 00 00   LXI HL, 0000               ; Save the stack pointer
    dba8  39         DAD SP
    dba9  22 f4 db   SHLD SAVE_SP (dbf4)

    dbac  2a f2 db   LHLD SECTOR_OFFSET (dbf2)  ; Set the sector offset into SP
    dbaf  f9         SPHL

    dbb0  2a ef db   LHLD BUFFER_ADDR (dbef)    ; Load the buffer address
    dbb3  19         DAD DE
    dbb4  2b         DCX HL

    dbb5  06 40      MVI B, 40                  ; Read 0x40 words (0x80 bytes - sector size)

    dbb7  3a ec db   LDA CURRENT_QUASI_DISK_PAGE (dbec) ; Enable quasi disk, and select the page
    dbba  d3 40      OUT 40

WRITE_SECTOR_LOOP:
    dbbc  56         MOV D, M                   ; Read data from the buffer, and store it to 
    dbbd  2b         DCX HL                     ; the quasi disk using stack write operations
    dbbe  5e         MOV E, M
    dbbf  2b         DCX HL
    dbc0  d5         PUSH DE
    dbc1  05         DCR B
    dbc2  c2 bc db   JNZ WRITE_SECTOR_LOOP (dbbc)

    dbc5  c3 94 db   JMP SECTOR_READ_WRITE_EXIT (db94)  ; Restore SP and exit


; Calculate sector offset
;
; This function calculates offset of the currently selected track/sector on the currently
; selected quasi disk page. Result is stored at 0xdbf2
;
; offset = 0x0400 * track_number + 0x0080 * sector_number
CALCULATE_SECTOR_ADDR:
    dbc8  21 00 00   LXI HL, 0000               ; Resulting address

    dbcb  11 00 04   LXI DE, 0400               ; Number of bytes on a track

    dbce  3a ed db   LDA CURRENT_TRACK (dbed)   ; Check if track #0 is selected
    dbd1  b7         ORA A
    dbd2  ca da db   JZ CALCULATE_SECTOR_ADDR_1 (dbda)

CALCULATE_TRACK_LOOP:
    dbd5  19         DAD DE                     ; Multiply track number by number of bytes on the track
    dbd6  3d         DCR A
    dbd7  c2 d5 db   JNZ CALCULATE_TRACK_LOOP (dbd5)

CALCULATE_SECTOR_ADDR_1:
    dbda  11 80 00   LXI DE, 0080               ; Number of bytes in a single sector
    dbdd  3a ee db   LDA CURRENT_SECTOR (dbee)

CALCULATE_SECTOR_LOOP:
    dbe0  3d         DCR A                      ; Multiply current sector index by sector size
    dbe1  ca e8 db   JZ CALCULATE_SECTOR_ADDR_EXIT (dbe8)

    dbe4  19         DAD DE
    dbe5  c3 e0 db   JMP CALCULATE_SECTOR_LOOP (dbe0)
    
CALCULATE_SECTOR_ADDR_EXIT:
    dbe8  22 f2 db   SHLD SECTOR_OFFSET (dbf2)  ; Store the result
    dbeb  c9         RET



CURRENT_QUASI_DISK_PAGE:
    dbec  00         db 00

CURRENT_TRACK:
    dbed  00         db 00

CURRENT_SECTOR:
    dbee  00         db 00

BUFFER_ADDR:
    dbef  00         db 00

CUR_DISK_NO:
    dbf1  00         db 00

SECTOR_OFFSET:
    dbf2  00 00      dw 0000

SAVE_SP:
    dbf4  00 00      dw 0000

DIRECTORY_BUFFER:
    dbf6  00         db 128*0x00                ; 128 byte buffer for directory operations

DISK_ALLOCATION_INFO:
    dc76  00         db 00

DIR_ENTRY_CRC_VECTOR:
    dc95  8 x 00     db 8 x 00                  ; CRC of 8 directory sectors
; CP/M-64 Basic Disk Operating System (BDOS)
;
; This code is loaded to the 0xcc00-0xd9ff by CP/M initial bootloader, and initially is located at
; 0x3c00-0x49ff address range of the CP/M binary.
;
;
; Generic notes
; ------------- 
;
; BDOS part of CP/M OS provide high level building blocks for user application. BDOS provides two groups
; of functions:
; - console input and output
; - file operations
;
; All functions are executed via a single entry located at 0xcc06. A particular function is selected by
; setting function number in C register. The function may take an input parameter in E register (single byte)
; or DE register pair (for word parameter or address). The result is usually passed in A register for a 8-bit
; result, or HL register pair for 16-bit result of address. 
;
; Note: In case of error most of the functions return an error code, but in some emergency situations (such
; as writing to a read/only drive, or disk structure corruption) the function does a software reset.
;
; CP/M v2.2 supports the following functions:
; - Function 0x00 - Warm reboot
; - Function 0x01 - Console input (wait symbol from console, then echo it. Return symbol in A)
; - Function 0x02 - Console output (print symbol in C register, process some special symbols)
; - Function 0x03 - Input a byte from the tape (BIOS function)
; - Function 0x04 - Output a byte to the tape (BIOS function)
; - Function 0x05 - Print (List) a byte (BIOS function)
; - Function 0x06 - Direct console input or output (input a byte if C=0xff, otherwise output symbol)
; - Function 0x07 - Get I/O Byte
; - Function 0x08 - Set I/O Byte
; - Function 0x09 - print string (Print '$' terminated string pointed by DE)
; - Function 0x0a - read console to the buffer (read a string from console to the buffer pointed by DE)
; - Function 0x0b - get console status (check if a button is pressed)
; - Function 0x0c - get version (return CP/M version in A)
; - Function 0x0d - reset disk system (reload all disks, reset all internal data)
; - Function 0x0e - select disk (select a default drive for default operations)
; - Function 0x0f - open existing file (DE is pointer to FCB with a file name)
; - Function 0x10 - close file (DE is pointer to FCB for previously opened file)
; - Function 0x11 - search first match (DE is pointer to FCB with a matching filename pattern)
; - Function 0x12 - search next match (DE is pointer to FCB with a matching filename pattern)
; - Function 0x13 - delete file (DE is pointer to FCB containing a file name)
; - Function 0x14 - read sequentally (DE is pointer to FCB of the opened file)
; - Function 0x15 - write sequentally (DE is pointer to FCB of the opened file)
; - Function 0x16 - create file (DE is pointer to FCB containing a file name)
; - Function 0x17 - rename file (DE is pointer to FCB containing original and new file name)
; - Function 0x18 - Return disk login vector (return login vector in HL, each bit indicates disk is online)
; - Function 0x19 - Return current disk (return current disk number in A, 0-based)
; - Function 0x1a - Set DMA buffer address (DE is a pointer to 128-byte buffer)
; - Function 0x1b - Get current disk allocation vector (return pointer in HL)
; - Function 0x1c - Write protect disk (no pameters, current disk will be write protectedf)
; - Function 0x1d - Get Read Only vector (returns HL - read/only vector, each bit indicates disk is read only)
; - Function 0x1e - Set file attribites (DE is a pointer to FCB with attributes to set)
; - Function 0x1f - Get address of Disk Params Block (return pointer to DBP in HL)
; - Function 0x20 - Get or set user code
; - Function 0x21 - Read randomly accessed file sector (DE is pointer to FCB of the opened file)
; - Function 0x22 - Write randomly accessed file sector (DE is pointer to FCB of the opened file)
; - Function 0x23 - Compute file size (DE is pointer to FCB with file name, function sets bytes 33-35)
; - Function 0x24 - Set random record (DE is pointer to FCB of previously opened file)
; - Function 0x25 - Reset drive (DE is a bit mask of drives to switch off)
; - Function 0x28 - Write unallocated block with zero fill (DE is pointer to FCB of the opened file)
;
; 
; Console I/O functions notes
; ---------------------------
;
; These functions add a few features on top of BIOS' console input and output functions:
; - Console output (print char) operations support pausing or canceling long lasting operations by pressing
;   certain key combination. This is reasonable for application that produce a lot of text on the screen. 
;   Since i8080 supports only one execution thread, keyboard scanning has to happen in the same execution
;   thread (same function) as printing a character.
;
; - Console input does bufferring for one symbol. This may be reasonable in case the console input is
;   a terminal connected via a network link. When character printing function checks if a Ctrl-C or Ctrl-S
;   key combinations it does a keyboard read BIOS operation. Since the read read symbol cannot be unread, 
;   BDOS has to buffer it for other functions that really wait for a symbol from console.
;
;   This fact causes some problem when running under emulators. Keyboard emulation cannot distinguish between
;   real keyboard read and a pre-flight keyboard scan for Ctrl-C/Ctrl-S combinations. This causes extra
;   keyboard scans and double symbol entering in some cases.
; 
; - Console output counts X screen position. Perhaps things could be easier if BIOS provides a function to
;   read cursor position. But since there is no such a function, BDOS has to virtually calculate symbol
;   position on its level before calling BIOS function to actually output the symbol. Calculating symbol
;   position is needed for the following reasons:
;
;   - BDOS processes 0x09 tabulation symbols, and advances cursor to the next tab stop (each 8 symbols)
;
;   - BDOS text input function (0x0a) supports making input fields starting from a certain cursor positon.
;     Also it supports clearing current input, moving cursor to the beginning of the input field, re-starting
;     the input from the new line from the same column position. Moreover input supports Ctrl-* key combi-
;     nations, which are printed as 2 symbols ^char. Performing a backspace requires BDOS to know the width
;     of each symbol.
;  
;  
; Disk I/O functions notes
; ------------------------
; 
; - Each disk is split into number of tracks, each track contains a certain number of 128-byte records 
;   (sectors). While BIOS is mostly concentrated on physical disk structure, BDOS cares about logical
;   structure, how files are located on the disk, and files metadata (name, extension, read only flags, etc)
;
; - Physical disk structure (number of tracks and sectors) is typically hardcoded in the BIOS, and cannot
;   be changed in runtime. BIOS even does not provide number of tracks on the disk to upper levels. Logical
;   disk structure is also hardcoded in BIOS, but this information is shared with upper levels (BDOS, and 
;   user programs via function 0x1f) in a form of Disk Parameters Block (DPB). Though typical application
;   would not need this information.
;
; - Each disk has a few tracks reserved for the system. Typically these tracks contain CCP+BDOS+BIOS code,
;   which is loaded by the BIOS from disk to the memory during warm boot. Number of reserved tracks is
;   specified in the disk parameters block (DPB). Reserved tracks do not participate in logical sector number
;   calculations. Reserved tracks are located at first physical tracks, and all logical sectors start from
;   the first track after the reserved tracks.
;
; - Minimum amount of data that BDOS allows to read or write is 128-byte sector (record). Even if file has
;   less data, it will be padded with garbage or EOF symbols till 128-byte boundary. Typically text files
;   use EOF (0x1a) byte to indicate the end of the file.
;
; - CP/M does not have any metadata field to indicate an exact file size up to bytes. The size is counted 
;   in 128-byte records (sectors), and this is the best precision can be obtained.
;
; - Tracking every individual sector on the disk, whether it is allocated to a file or empty would require
;   storing a lot of metadata, and therefore consume a lot of CPU cycles to process. This is especially
;   critical for large disks with huge number of sectors. Instead, the information on the disk is tracked in
;   blocks - a bigger chunk of data, containing several sectors. Typical block size is between 1k and 16k, 
;   depending on the disk size. Block size is selected in the way so that total numbers of blocks does not
;   exceed 65536 (and each block can be identified as a 2-byte integer).
;
; - Depending on the disk size, CP/M supports two ways of blocks numbering. Small disks would contain less
;   number of blocks. In this case individual block will be addressed with a single byte integer. Larger
;   disk may have larger number of blocks, which are addressed with 2-byte integer. Blocks numbering start
;   with 1, while zero is reserved to indicate the block is not allocated.
;
; - Every file allocates 0 or more data blocks. Despite files may be really small (say a few bytes), it will
;   still allocate a full block. Unused sectors of the block are unavailable for other files.
;
; - Information about files on the disk (file metadata) is stored in the directory entries. Each file is
;   described with at least one 32-byte directory entry. Each directory entry contains information about
;   file name, extension, number of records (file size), read only and system file flags, etc.
;
; - Number of directory entries is defined in a DPB parameter. Directory is located at first logical blocks,
;   right after reserved tracks.
;
; - File allocation information is also stored in the directory entry. Each entry contains 16 1-byte, or 8
;   2-byte records, specifying which block will be used to store corresponding piece of file.
;
; - In case if a file does not fit a single directory entry, the data can be split into several chunks called
;   extents. Each extent is represented by its own directory entry with the same name/extension, but different
;   allocation data. Each directory entry has extent number field, so that BDOS can always find the next
;   data extent. 
;
; - Maximum amount of data can be stored in a single extent is 128 records (sectors), which is 16k. Exact
;   amount of records for the extent is stored in a records count field.
;
; - There is no global allocation information for entire disk is available (unlike in FAT systems). Instead,
;   BDOS builds the allocation information internally while initializing the disk, by scanning all directory
;   entries and loading its allocation information into a in-memory disk allocation map.
;
; - CP/M v2.2 does not offer any specific directory structure. All files are located in the same directory,
;   and are distinguished only by their names and extensions. 
;
; - Directory entry format:
;   1 byte    - 0xe5 if entry is empty, or user code ????
;   8 bytes   - file name (padded with 0x20 space symbols)
;   3 bytes   - file extension (low 7 bits of each byte). Highest bit of the 9th byte indicates that the file
;               is read only, Highest bit of the 10th byte indicates that the file is system, and should not
;               be visible to the user on DIR command.
;   1 byte    - current extent number (low 5 bits)
;   1 byte    - reserved ???
;   1 byte    - current extent number (high 4 bits)
;   1 byte    - number of records in the current extent
;   16 bytes  - disk allocation map (16 one-byte records, or 8 two-byte records, indicating the block index
;               storing the corresponding piece of file data)
;
; - All file operations accept as an argument a pointer to File Control Block (FCB) structure. This structure
;   is used to pass input information to the function (e.g. name of the file to open), get output information
;   (for example name of the file found with a name pattern), or even store intermediate information related
;   to the currently opened file (e.g. current record number during sequental read).
; 
; - Structure of the FCB is very similar to the directory entry structure. This simplifies internal functions,
;   so that it process information in a unified way. At the same time there are a few differences between FCB
;   and directory entry:
;
;   - A byte at offset 0x00 of FCB represent the disk number that the operation is related to. This allows
;     working with several disk drives simultaneously by specifying their disk codes in different FCBs
;
;   - MSB of the byte at offset 0x0e (extent number high byte) indicates that file or directory entry was
;     created, but no data yet to be written on the disk, and therefore this entry is not yet valid. File
;     close operation prevents closing files with such a flag.
;
;   - A byte at offset 0x20 is a current record counter for sequental operations. Represent the current
;     record (sector) index within the current extent. When the record counter reaches a value of 0x80, the
;     sequental operation switches to the next extent (create a new one for write operation if necessary)
;
;   - 3 bytes at offset 0x21-0x23 are used for random access write or read operations. The user may set the
;     record index for the entire file in bytes 0x21-0x22 (in a range of 0-65535). and the random access
;     read/write operations will convert it to the extent number (low and high byte) and record index within
;     the extent. This means that it will further allow sequental reading or writing starting from the 
;     selected record (sector).
;
;   - The function 0x24 does the opposite thing - convert high and low extent number bytes and current record
;     into a single 2-byte value in bytes 0x21-0x22.
;
;   - Byte at offset 0x23 does not participate in the file seek calculations, but indicates an overflow 
;     during compute file size operation (function 0x23)
;
; - Search first / search next operations are most used functions in the BDOS. Since files do not have unique
;   identifiers, each BDOS file function searches the corresponding directory entry by the name or pattern
;   provided in the FCB. Some functions return so called directory code from 0 to 3, which in fact is an
;   index of a directory entry on a currently loaded directory sector (4 entries per sector).
;
; - Original CP/M system is single user, but later it was added with a multi-user extensions. Technically
;   each file got a label called user code, which is an integer from 0 to 31. Each user has its own label,
;   and search first/next operation returns only files with the matching user code. There was no special
;   protection in order to forbid users to read other's files, just filtering on the directory level. User
;   program may still use search first/next functions, specify '?' in the user code field, and get all files
;   on the disk regardless the user code.
;
; - Disk Parameter Block structure (returned by BIOS) for the UT-88 Quasi disk is the following:
;   - 0x0008 (2 bytes)  - sectors per track
;   - 0x03   (1 byte)   - Block Shift Factor (BSH). Each block contains 2^BSH number of sectors, which is
;                         8 records per block, or 1k block size for UT-88 quasi disk.
;   - 0x07   (1 byte)   - Block Mask (BLM). Used while converting logical record/block index into track/sector
;                         pair. BLM will mask bits responsible for record index within a block
;   - 0x00   (1 byte)   - Extent mask. Participates in extent size calculations for large disks. Not relevant
;                         for UT-88 Quasi disk
;   - 0x00f9 (2 bytes)  - total number of data blocks - 1, including directory entries, but not counting
;                         reserved tracks. In case of UT-88, 0xfa blocks 1k each, plus 6 reserved tracks by
;                         8 sectors each (1k per track) fully utilize all 256 tracks, while the 256 tracks
;                         number is not stated explicitly in DPB.
;   - 0x001f (2 bytes)  - Number of directory entries - 1 (in case of UT-88 32 directory entries 32 bytes
;                         each will fully utilize the first block on the disk)
;   - 0x8000 (2 bytes)  - bit mask for blocks reserved for directory entries. In this case the first block
;                         (highest bit) is reserved for the directory
;   - 0x0008 (2 bytes)  - Size of the directory checksum vector (directory size is 8 sectors, 1 byte of CRC
;                         for each sector)
;   - 0x0006 (2 bytes)  - number of reserved tracks in the beginning of the disk
;
; - More information on the disk structure, directory entry format, and compatibility notes for other
;   CP/M versions can be found at https://www.cpm8680.com/cpmtools/cpm.htm
;
;
;
;
; Important variables:
; 0003  - I/O Byte ?????
; cf0a  - Flag indicating that no char printing needed, only computing cursor position
; cf0b  - Start column of the input buffer reading (used to track back Ctrl-H and backspace)
; cf0c  - Current cursor horizontal position (used to print tabs)
; cf0d  - flag indicating that output to the printer is enabled in addition to console output
; cf0e  - if a keypress is detected, entered symbol is buffered in this variable
; cf0f  - save caller's SP (2 byte)
; cf11  - BDOS strack area (0x30 bytes)
; cf41  - user code (get/set by function 0x20)
; cf42  - current disk
; cf43  - function arguments (2 byte)
; cf45  - function return code or return value(2 byte)
; d9ad  - Read only vector (Bitmask of the disks currently marked as read only)
; d9af  - Disk Login Vector (Bitmask of the disks currently marked as online)
; d9b1  - Pointer to the currently set data buffer
; d9b3  - Address of the variable containing last directory entry number
; d9b5  - Address of the variable containing current track number
; d9b7  - Address of the variable containing current track first sector number
; d9b9  - Pointer to the directory buffer
; d9bb  - Address of Disk Params Block (DPB)
; d9bd  - Address of CRC vector for directory sectors
; d9bf  - Address of disk allocation vector
; d9c1  - Disk Parameters Block: sectors per track
; d9c3  - Disk Parameters Block: block shift factor
; d9c4  - Disk Parameters Block: block number mask
; d9c5  - Disk Parameters Block: extent number mask
; d9c6  - Disk Parameters Block: total number of blocks on the disk - 1
; d9c8  - Disk Parameters Block: number of directory entries - 1
; d9ca  - Disk Parameters Block: bitmap of directory entry blocks
; d9cc  - Disk Parameters Block: Size of the directory check vector
; d9ce  - Disk Parameters Block: Number of reserved tracks
; d9d0  - Pointer to the sector translation table
; d9d2  - Flag indicating the FCB has been flushed to directory entry
; d9d3  - read/write type (0 for write, 0xff for read)
; d9d4  - Search in progress flag (file has not yet been found)
; d9d5  - operation type (0 - random read/write, 1 - sequenta, 2 - random write with zero blocks)
; d9d6  - function argument (low byte)
; d9d7  - Current record block index in FCB alloc vector
; d9d8  - number of bytes to match during search first/next operation
; d9d9  - Current search FCB (used for subsequent SEARCH_NEXT calls)
; d9dd  - Flag indicating that total disk capacity high byte is 0, and 1-byte allocation entries can be used
; d9de  - Flag indicating that disk needs to be restored on exit
; d9df  - Previously selected disk
; d9e0  - Drive code passed as a first byte of FCB
; d9e1  - Total records (sector) in current extent
; d9e2  - Current extent number (masked with extent mask)
; d9e3  - Index of the current sector for sequental read/write ops
; d9e5  - Actual sector number (similar to LBA concept)
; d9e7  - index of the first sector of the block
; d9e9  - Directory entry offset (on the current sector)
; d9ea  - Directory entries counter (while iterating over directory)
; d9eb  - ????
; d9ec  - Sector number of the current directory entry (LBA)



; Unknown piece of data, probably a serial number
cc00  f9 16 00 00 00 6b


; The main entry point to all BDOS functions (fixed address)
BDOS_ENTRY:
    cc06  c3 11 cc   JMP REAL_BDOS_ENTRY (cc11)

; Pointer to read/write error handler
DISK_READ_WRITE_ERROR_PTR:
    cc09  99 cc     dw DISK_READ_WRITE_ERROR (cc99)

; Pointer to disk select error handler
DISK_SELECT_ERROR_PTR:
    cc0b  a5 cc     dw DISK_SELECT_ERROR (cca5)

; Pointer to disk read only error handler
DISK_READ_ONLY_ERROR_PTR:
    cc0d  ab cc     dw DISK_READ_ONLY_ERROR (ccab)

; Pointer to file read only error handler
FILE_READ_ONLY_ERROR_PTR:
    cc0f  b1 cc     dw FILE_READ_ONLY_ERROR (ccb1)


; The BDOS entry (entry point for all BDOS functions)
;
; The function does preparation for BDOS function execution:
; - Sets the BDOS stack
; - Saves arguments to variables
; - Prepare return address
;
; After all preparation is done, the function dispatches execution to the function handler requested.
;
; Arguments:
; C     - function number
; DE    - arguments
;
; Returns:
; A     - result (low byte of the result)
; B     - high byte of the result
REAL_BDOS_ENTRY:
    cc11  eb         XCHG                       ; Store arguments for future use in the functions
    cc12  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)
    cc15  eb         XCHG

    cc16  7b         MOV A, E                   ; Store argument low byte separately
    cc17  32 d6 d9   STA FUNCTION_BYTE_ARGUMENT (d9d6)

    cc1a  21 00 00   LXI HL, 0000               ; Prepare result code
    cc1d  22 45 cf   SHLD FUNCTION_RETURN_VALUE (cf45)

    cc20  39         DAD SP                     ; Save caller's SP
    cc21  22 0f cf   SHLD BDOS_SAVE_SP (cf0f)

    cc24  31 41 cf   LXI SP, BDOS_STACK (cf41)  ; And set our own stack

    cc27  af         XRA A                      ; Do not perform drive selection unless explicitly requested
    cc28  32 e0 d9   STA FCB_DRIVE_CODE (d9e0)  ; in FCB
    cc2b  32 de d9   STA RESELECT_DISK_ON_EXIT (d9de)

    cc2e  21 74 d9   LXI HL, BDOS_HANDLER_RETURN (d974) ; Set the return address
    cc31  e5         PUSH HL

    cc32  79         MOV A, C                   ; Function with numbers >= 0x29 are not supported
    cc33  fe 29      CPI A, 29
    cc35  d0         RNC

    cc36  4b         MOV C, E                   ; One byte arguments are available in C register
    
    cc37  21 47 cc   LXI HL, FUNCTION_HANDLERS_TABLE (cc47)
    cc3a  5f         MOV E, A                   ; DE is a function number
    cc3b  16 00      MVI D, 00

    cc3d  19         DAD DE                     ; Calculate the entry pointer in the table
    cc3e  19         DAD DE

    cc3f  5e         MOV E, M                   ; Load the handler address in DE
    cc40  23         INX HL
    cc41  56         MOV D, M

    cc42  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Load arguments in HL

    cc45  eb         XCHG                       ; Jump to the handler
    cc46  e9         PCHL


; The BDOS function pointers table
FUNCTION_HANDLERS_TABLE:
    cc47  03 da      dw BIOS_WARM_BOOT (da03)       ; Function 0x00 - Warm boot
    cc48  c8 ce      dw CONSOLE_INPUT (cec8)        ; Function 0x01 - Console input
    cc4b  90 cd      dw PUT_CHAR (cd90)             ; Function 0x02 - Console output
    cc4d  ce ce      dw IN_BYTE (cece)              ; Function 0x03 - Input a byte from the tape
    cc4f  12 da      dw BIOS_OUT_BYTE (da12)        ; Function 0x04 - Output a byte to the tape
    cc51  0f da      dw BIOS_PRINT_BYTE (da0f)      ; Function 0x05 - Print (List) a byte
    cc53  d4 ce      dw DIRECT_CONSOLE_IO (ced4)    ; Function 0x06 - Direct console input or output
    cc55  ed ce      dw GET_IO_BYTE (ceed)          ; Function 0x07 - Get I/O Byte
    cc57  f3 ce      dw SET_IO_BYTE (cef3)          ; Function 0x08 - Set I/O Byte
    cc59  f8 ce      dw PRINT_STRING (cef8)         ; Function 0x09 - print string
    cc5b  e1 cd      dw READ_CONSOLE_BUFFER (cde1)  ; Function 0x0a - read console to the buffer
    cc5d  fe ce      dw GET_CONSOLE_STATUS (cefe)   ; Function 0x0b - get console status (if a button pressed)
    cc5f  7e d8      dw GET_BDOS_VERSION (d87e)     ; Function 0x0c - get version
    cc61  83 d8      dw RESET_DISK_SYSTEM (d883)    ; Function 0x0d - reset disk system
    cc63  45 d8      dw SELECT_DISK_FUNC (d845)     ; Function 0x0e - select disk
    cc65  9c d8      dw OPEN_FILE_FUNC (d89c)       ; Function 0x0f - open existing file
    cc67  a5 d8      dw CLOSE_FILE_FUNC (d8a5)      ; Function 0x10 - close file
    cc69  ab d8      dw SEARCH_FIRST_FUNC (d8ab)    ; Function 0x11 - search first match
    cc6b  c8 d8      dw SEARCH_NEXT_FUNC (d8c8)     ; Function 0x12 - search next match
    cc6d  d7 d8      dw DELETE_FILE_FUNC (d8d7)     ; Function 0x13 - delete file
    cc6f  e0 d8      dw READ_SEQUENTAL_FUNC (d8e0)  ; Function 0x14 - read sequentally
    cc71  e6 d8      dw WRITE_SEQUENTAL_FUNC (d8e6) ; Function 0x15 - write sequentally
    cc73  ec d8      dw CREATE_FILE_FUNC (d8ec)     ; Function 0x16 - create file
    cc75  f5 d8      dw RENAME_FILE_FUNC (d8f5)     ; Function 0x17 - rename file
    cc77  fe d8      dw GET_LOGIN_VECTOR (d8fe)     ; Function 0x18 - Return disk login vector
    cc79  04 d9      dw GET_CURRENT_DISK (d904)     ; Function 0x19 - Return current disk
    cc7b  0a d9      dw SET_BUFFER_ADDR (d90a)      ; Function 0x1a - Set DMA buffer address
    cc7d  11 d9      dw GET_ALLOCATION_VECTOR (d911); Function 0x1b - Get current disk allocation vector
    cc7f  2c d1      dw WRITE_PROTECT_DISK (d12c)   ; Function 0x1c - Write protect disk
    cc81  17 d9      dw GET_READ_ONLY_VECTOR (d917) ; Function 0x1d - Get Read Only vector
    cc83  1d d9      dw SET_FILE_ATTRS_FUNC (d91d)  ; Function 0x1e - Set file attribites
    cc85  26 d9      dw GET_DISK_PARAMS (d926)      ; Function 0x1f - Get address of Disk Params Block (DPB)
    cc87  2d d9      dw GET_SET_USER_CODE (d92d)    ; Function 0x20 - Get or set user code
    cc89  41 d9      dw READ_RANDOM_FUNC (d941)     ; Function 0x21 - Read random
    cc8b  47 d9      dw WRITE_RANDOM_FUNC (d947)    ; Function 0x22 - Write random
    cc8d  4d d9      dw GET_FILE_SIZE_FUNC (d94d)   ; Function 0x23 - Compute file size
    cc8f  0e d8      dw SET_RANDOM_REC_FUNC (d80e)  ; Function 0x24 - Set random record
    cc91  53 d9      dw RESET_DRIVE_FUNC (d953)     ; Function 0x25 - Reset drive
    cc93  04 cf      dw FUNC_26 (cf04)              ; Unused
    cc95  04 cf      dw FUNC_27 (cf04)              ; Unused
    cc97  9b d9      dw WRITE_WITH_ZERO_FILL (d99b) ; Function 0x28 - Write unallocated block with zero fill


; Disk Read/Write error handler
;
; The function prints an error. If the user presses Ctrl-C combination, the function will do a CPU reset
DISK_READ_WRITE_ERROR:
    cc99  21 ca cc   LXI HL, DISK_READ_WRITE_ERROR_STR (ccca)   ; Print the error
    cc9c  cd e5 cc   CALL PRINT_ERROR (cce5)

    cc9f  fe 03      CPI A, 03                  ; Ctrl-C will reset
    cca1  ca 00 00   JZ 0000

    cca4  c9         RET

; Disk select error handler
;
; The function prints an error message and resets.
DISK_SELECT_ERROR:
    cca5  21 d5 cc   LXI HL, DISK_SELECT_ERROR_STR (ccd5)
    cca8  c3 b4 cc   JMP PRINT_ERROR_AND_RESET (ccb4)

; Disk read only error handler
;
; The function prints an error message and resets.
DISK_READ_ONLY_ERROR:
    ccab  21 e1 cc   LXI HL, DISK_READ_ONLY_ERROR_STR (cce1)
    ccae  c3 b4 cc   JMP PRINT_ERROR_AND_RESET (ccb4)

; File read only error handler
;
; The function prints an error message and resets.
FILE_READ_ONLY_ERROR:
    ccb1  21 dc cc   LXI HL, FILE_READ_ONLY_ERROR_STR (ccdc)

; Helper function to print an error message, and then perform a CPU restart
PRINT_ERROR_AND_RESET:
    ccb4  cd e5 cc   CALL PRINT_ERROR (cce5)    ; Print error
    ccb7  c3 00 00   JMP 0000                   ; and reset


BDOS_ERROR_STR:
    ccba  42 64 6f 73 20 45 72 72   db "Bdos Err"
    ccc2  20 4f 6e 20 20 3a 20 24   db " On  : $"
    
DISK_READ_WRITE_ERROR_STR:
    ccca  42 61 64 20 53 65 63 74   db "Bad sect"
    ccd2  6f 72 24                  db "or$"

DISK_SELECT_ERROR_STR:
    ccd5  53 65 6c 65 63 74 24      db "Select$"
    
FILE_READ_ONLY_ERROR_STR:
    ccdc  46 69 6c 65 20            db "File "

DISK_READ_ONLY_ERROR_STR:
    cce1  52 2f 4f 24               db "R/O$"


; Print the error message, prefixed by BDOS message, indicating the drive letter.
; The function waits for a keyboard press, and returns the entered code
;
; Arguments: BC pointer to the error message
;
; Return: A - keyboard character
PRINT_ERROR:
    cce5  e5         PUSH HL
    cce6  cd c9 cd   CALL PRINT_CRLF (cdc9)     ; Error will be printed on the next line

    cce9  3a 42 cf   LDA CURRENT_DISK (cf42)    ; Calculate the disk letter and burn it to the message
    ccec  c6 41      ADI A, 41
    ccee  32 c6 cc   STA ccc6

    ccf1  01 ba cc   LXI BC, BDOS_ERROR_STR (ccba)  ; Print the "BDOS Error on X: " prefix, where X is 
    ccf4  cd d3 cd   CALL DO_PRINT_STRING (cdd3)    ; drive letter

    ccf7  c1         POP BC                     ; Print the message pointed by BC, and wait for a key
    ccf8  cd d3 cd   CALL DO_PRINT_STRING (cdd3)


; Wait for a character from the console input (keyboard)
;
; Return: A - entered symbol
WAIT_CONSOLE_CHAR:
    ccfb  21 0e cf   LXI HL, CONSOLE_KEY_PRESSED (cf0e) ; Check if we have a character in the buffer already
    ccfe  7e         MOV A, M                           ; Get the buffered char and reset the buffer
    ccff  36 00      MVI M, 00
    cd01  b7         ORA A
    cd02  c0         RNZ

    cd03  c3 09 da   JMP BIOS_CONSOLE_INPUT (da09)  ; If no character ready - wait for it using BIOS routines


; Function 0x01 - Console input
;
; The function waits for a console character (if not received already), and echo it on the screen
;
; Return: A - entered character code
DO_CONSOLE_INPUT:
    cd06  cd fb cc   CALL WAIT_CONSOLE_CHAR (ccfb)  ; Wait for the character
    
    cd09  cd 14 cd   CALL IS_SPECIAL_SYMBOL (cd14)  ; Skip echoing non-printable characters
    cd0c  d8         RC

    cd0d  f5         PUSH PSW                   ; Echo entered character
    cd0e  4f         MOV C, A
    cd0f  cd 90 cd   CALL PUT_CHAR (cd90)
    cd12  f1         POP PSW
    cd13  c9         RET


; Check if A contains a special symbol code
;
; Function raises Z flag if A contains 0x0d (carriage return), 0x0a (line feed), 0x08 (backspace), 
; or 0x09 (tab)
; Function raises C flag if the symbol is not printable (symbol code < 0x20)
IS_SPECIAL_SYMBOL:
    cd14  fe 0d      CPI A, 0d
    cd16  c8         RZ
    cd17  fe 0a      CPI A, 0a
    cd19  c8         RZ
    cd1a  fe 09      CPI A, 09
    cd1c  c8         RZ
    cd1d  fe 08      CPI A, 08
    cd1f  c8         RZ
    cd20  fe 20      CPI A, 20
    cd22  c9         RET


; Check if a key is pressed
;
; This function not just calls BIOS IS_KEY_PRESSED function, it also checks if a Ctrl-S combination
; is pressed. If yes, Ctrl-C combination will do the software reset.
;
; If a key is pressed, entered symbol is buffered at CONSOLE_KEY_PRESSED variable
;
; Return: A=01 if key is pressed (Z flag is off), A=00 otherwise (Z flag is on)
IS_KEY_PRESSED:
    cd23  3a 0e cf   LDA CONSOLE_KEY_PRESSED (cf0e) ; Check if there is a symbol in the buffer already
    cd26  b7         ORA A
    cd27  c2 45 cd   JNZ IS_KEY_PRESSED_EXIT (cd45)

    cd2a  cd 06 da   CALL BIOS_IS_KEY_PRESSED (da06); Return if no button is pressed
    cd2d  e6 01      ANI A, 01
    cd2f  c8         RZ

    cd30  cd 09 da   CALL BIOS_CONSOLE_INPUT (da09) ; Check if Ctrl-S is pressed (Stop Screen condition)
    cd33  fe 13      CPI A, 13
    cd35  c2 42 cd   JNZ IS_KEY_PRESSED_OK (cd42)

    cd38  cd 09 da   CALL BIOS_CONSOLE_INPUT (da09) ; If Ctrl-C is pressed - do soft reset
    cd3b  fe 03      CPI A, 03
    cd3d  ca 00 00   JZ 0000

    cd40  af         XRA A                      ; Other symbols are invalid
    cd41  c9         RET

IS_KEY_PRESSED_OK:
    cd42  32 0e cf   STA CONSOLE_KEY_PRESSED (cf0e) ; Some valid symbol is entered - buffer it

IS_KEY_PRESSED_EXIT:
    cd45  3e 01      MVI A, 01                  ; Indicate that a button is pressed
    cd47  c9         RET


; Print a character in C to console
;
; The function is a wrapper over BIOS' print char function. The main goal of this wrapper is to track
; printed character horizontal position, to be later used for tab stop, or clearing a text in a text editable
; field. Moreover, the funcion even can skip character printing (if COM_CURSOR_POSITION is flagged), and
; perform only horizontal position calculation.
;
; Special characters, such as backspace, also tracked by the function, and cursor position is calculated
; accordingly.
;
; The function also scans the keyboard to allow the user to stop/cancel long lasting text output.
;
; If printer is attached to the system, the function also routes character printing to the printer as well.
;
; Arguments:
; C - character to print
DO_PUT_CHAR:
    cd48  3a 0a cf   LDA COMP_CURSOR_POSITION (cf0a); Do we need to print the character?
    cd4b  b7         ORA A
    cd4c  c2 62 cd   JNZ DO_PUT_CHAR_1 (cd62)

    cd4f  c5         PUSH BC                    ; Get a chance to process Ctrl-S/Ctrl-C combinations
    cd50  cd 23 cd   CALL IS_KEY_PRESSED (cd23) ; to break long output
    cd53  c1         POP BC

    cd54  c5         PUSH BC                    ; Print the character normally
    cd55  cd 0c da   CALL BIOS_PUT_CHAR (da0c)
    cd58  c1         POP BC

    cd59  c5         PUSH BC
    cd5a  3a 0d cf   LDA PRINTER_ENABLED (cf0d) ; If printer enabled - print the char on printer as well
    cd5d  b7         ORA A
    cd5e  c4 0f da   CNZ BIOS_PRINT_CHAR (da0f)
    cd61  c1         POP BC

DO_PUT_CHAR_1:
    cd62  79         MOV A, C                   ; Load cursor position
    cd63  21 0c cf   LXI HL, CURSOR_COLUMN (cf0c)

    cd66  fe 7f      CPI A, 7f                  ; Do not print 0x7f character
    cd68  c8         RZ

    cd69  34         INR M                      ; Normal characters advance the cursor

    cd6a  fe 20      CPI A, 20                  ; Nothing else needed to do for printable characters
    cd6c  d0         RNC

    cd6d  35         DCR M                      ; Special characters do not advance the cursor, revert back

    cd6e  7e         MOV A, M                   ; Check if we reached start of the line
    cd6f  b7         ORA A
    cd70  c8         RZ

    cd71  79         MOV A, C                   ; Check if the printed symbol is a backspace
    cd72  fe 08      CPI A, 08
    cd74  c2 79 cd   JNZ DO_PUT_CHAR_2 (cd79)

    cd77  35         DCR M                      ; Backspace moves cursor left
    cd78  c9         RET

DO_PUT_CHAR_2:
    cd79  fe 0a      CPI A, 0a                  ; No cursor position changes on all characters except for CR
    cd7b  c0         RNZ

    cd7c  36 00      MVI M, 00                  ; Reset the cursor position in case of carriage return
    cd7e  c9         RET


; Print character including control symbols
;
; Prints character in C register as follows:
; - Characters with codes >= 0x20 printed normally
; - Characters with codes < 0x20 printed as "^<Letter>"
PUT_CHAR_CTRL_SYMBOLS:
    cd7f  79         MOV A, C                   ; Print characters that can be printed
    cd80  cd 14 cd   CALL IS_SPECIAL_SYMBOL (cd14)
    cd83  d2 90 cd   JNC PUT_CHAR (cd90)

    cd86  f5         PUSH PSW                   ; Characters in 0x00-0x1f range are printed as '^'
    cd87  0e 5e      MVI C, 5e                  ; and a letter
    cd89  cd 48 cd   CALL DO_PUT_CHAR (cd48)
    cd8c  f1         POP PSW

    cd8d  f6 40      ORI A, 40                  ; Convert 0x00-0x1f to 0x40-0x5f range, and print
    cd8f  4f         MOV C, A


; Function 0x02 - Put a char to console (and printer)
;
; Parameters: 
; C - character to output
PUT_CHAR:
    cd90  79         MOV A, C                   ; Tab symbol is processed separately
    cd91  fe 09      CPI A, 09
    cd93  c2 48 cd   JNZ DO_PUT_CHAR (cd48)     ; All other symbols are processed by DO_PUT_CHAR

PUT_CHAR_TAB_LOOP:
    cd96  0e 20      MVI C, 20                  ; Print spaces until next 8-char column is reached
    cd98  cd 48 cd   CALL DO_PUT_CHAR (cd48)

    cd9b  3a 0c cf   LDA CURSOR_COLUMN (cf0c)   ; Check if we reached next 8-char tab stop
    cd9e  e6 07      ANI A, 07
    cda0  c2 96 cd   JNZ cd96

    cda3  c9         RET


; Do a backspace (literally print space left to the cursot)
;
; Function moves cursor left, prints a space, and moves cursor left again
PRINT_BACKSPACE:
    cda4  cd ac cd   CALL MOVE_CURSOR_LEFT (cdac)
    cda7  0e 20      MVI C, 20
    cda9  cd 0c da   CALL BIOS_PUT_CHAR (da0c)

MOVE_CURSOR_LEFT:
    cdac  0e 08      MVI C, 08
    cdae  c3 0c da   JMP BIOS_PUT_CHAR (da0c)


; Print '#' and CR/LF
;
; This function is used in combination with Ctrl-R (repeat current line), Ctrl-U (Remove current line),
; and Ctrl-X (backspace till the beginning of the current line) key combinations. Restarts the line starting
; from READ_START_COLUMN positions (characters to the left are filled with spaces).
PRINT_HASH_CRLF:
    cdb1  0e 23      MVI C, 23                  ; Print '#' symbol
    cdb3  cd 48 cd   CALL DO_PUT_CHAR (cd48)    

    cdb6  cd c9 cd   CALL PRINT_CRLF (cdc9)     ; Then CR/LF

PRINT_HASH_CRLF_LOOP:
    cdb9  3a 0c cf   LDA CURSOR_COLUMN (cf0c)   ; Fill space between start of the line and start column
    cdbc  21 0b cf   LXI HL, READ_START_COLUMN (cf0b)   ; with spaces
    cdbf  be         CMP M
    cdc0  d0         RNC

    cdc1  0e 20      MVI C, 20
    cdc3  cd 48 cd   CALL DO_PUT_CHAR (cd48)
    cdc6  c3 b9 cd   JMP PRINT_HASH_CRLF_LOOP (cdb9)


PRINT_CRLF:
    cdc9  0e 0d      MVI C, 0d                  ; Print CR and LF symbols
    cdcb  cd 48 cd   CALL DO_PUT_CHAR (cd48)
    cdce  0e 0a      MVI C, 0a
    cdd0  c3 48 cd   JMP DO_PUT_CHAR (cd48)



; Print string pointed by BC, until '$' symbol is reached
DO_PRINT_STRING:
    cdd3  0a         LDAX BC                    ; Load next byte

    cdd4  fe 24      CPI A, 24                  ; Stop printing when '$' is reached
    cdd6  c8         RZ

    cdd7  03         INX BC
    cdd8  c5         PUSH BC

    cdd9  4f         MOV C, A                   ; Print next character
    cdda  cd 90 cd   CALL PUT_CHAR (cd90)

    cddd  c1         POP BC
    cdde  c3 d3 cd   JMP DO_PRINT_STRING (cdd3)


; Function 0x0a - read console input to the provided buffer
;
; The function waits user console input and writes it to the provided buffer. First 2 elements of
; the buffer have special meaning (1st byte - buffer size, 2nd byte - number of symbols entered).
;
; Each entered symbol is echoed to the console output. Characters with codes < 0x20 (if not processed
; as special symbols) are printed as 2-char sequence - ^symb. 
;
; Console reading is finished on either reaching the end of the buffer, or Enter key (Ctrl-J and Ctrl-M
; do the same) is pressed.
;
; The function also handles special keys and key combinations:
; - backspace   - removes symbol left to the cursor. Special 2-char symbols are erased as well (2 symbols
;   (or Ctrl-H)   at a once). This is done using a 'fake printing' approach - function sets
;                 COMP_CURSOR_POSITION to turn printing into width calculation mode, then previously entered
;                 string is 'printed'. Extra characters are erased with spaces.
; - rubout      - similar to the backspace, but erases only one character on the screen (so in case of 
;                 2-byte special symbols the line can be visually corrupted)
; - Ctrl-C      - reboots the system from 0x0000
; - Ctrl-E      - New line on terminal. Continues reading the console to the same buffer, while echoing
;                 symbols is moved to the next line. Resulting buffer does not contain Ctrl-E symbol. This
;                 is just visual moving to the next line.
; - Ctrl-R      - Retype currently entered line from the new line. Handy in case of the line if visually
;                 corrupted, and simply needs to be redrawn on the screen. Does not change the buffer.
; - Ctrl-U      - Restart entering the current input. Visually it moves to the new line, and start reading
;                 to the buffer from the beginning.
; - Ctrl-X      - Restart entering the current input in the same line. Technically it does multiple back
;                 spaces, until reaches the beginning of line.
;
; The function tries to maintain the starting column of the input line. This allows making input not at
; the beginning of the line, but at further positions. Various erase combinations (Ctrl-X, Ctrl-U) maintain
; the start position and restart the input from the same column.
;
; Arguments:
; [cf43]    - pointer to the buffer. First byte of the buffer indicates buffer size (not counting first
;             2 service bytes)
;
; Return:
; Buffer is filled with entered characters as follows:
; - 1st byte - buffer size (original byte)
; - 2nd byte - number of entered symbols
; - 3rd byte and further - entered symbols
READ_CONSOLE_BUFFER:
    cde1  3a 0c cf   LDA CURSOR_COLUMN (cf0c)   ; Remember the start position for proper handling of
    cde4  32 0b cf   STA READ_START_COLUMN (cf0b); Ctrl-H and backspace

    cde7  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Get the buffer size
    cdea  4e         MOV C, M

    cdeb  23         INX HL                     ; Advance pointer to the first data byte in the buffer
    cdec  e5         PUSH HL

    cded  06 00      MVI B, 00                  ; Counter of the entered symbols

READ_NEXT_SYMBOL:
    cdef  c5         PUSH BC
    cdf0  e5         PUSH HL

READ_NEXT_SYMBOL_2:
    cdf1  cd fb cc   CALL WAIT_CONSOLE_CHAR (ccfb)  ; Wait for the next symbol
    cdf4  e6 7f      ANI A, 7f
    cdf6  e1         POP HL
    cdf7  c1         POP BC

    cdf8  fe 0d      CPI A, 0d                  ; Check if CR is entered
    cdfa  ca c1 ce   JZ READ_CONSOLE_BUFFER_EOL (cec1)

    cdfd  fe 0a      CPI A, 0a                  ; Check if LF is entered
    cdff  ca c1 ce   JZ READ_CONSOLE_BUFFER_EOL (cec1)

    ce02  fe 08      CPI A, 08                  ; Check if backspace is entered
    ce04  c2 16 ce   JNZ READ_NEXT_SYMBOL_3 (ce16)

    ce07  78         MOV A, B                   ; Can't do backspace if there are no symbols in the buffer
    ce08  b7         ORA A
    ce09  ca ef cd   JZ READ_NEXT_SYMBOL (cdef)

    ce0c  05         DCR B                      ; Decrease symbols counter

    ce0d  3a 0c cf   LDA CURSOR_COLUMN (cf0c)   ; Enable 'fake printing' mode to calculate visible width
    ce10  32 0a cf   STA COMP_CURSOR_POSITION (cf0a)    ; of the entered line

    ce13  c3 70 ce   JMP REPRINT_BUFFER (ce70)

READ_NEXT_SYMBOL_3:
    ce16  fe 7f      CPI A, 7f                  ; Check if rubout symbol is entered
    ce18  c2 26 ce   JNZ READ_NEXT_SYMBOL_4 (ce26)

    ce1b  78         MOV A, B                   ; Can't do backspace if there are no symbols in the buffer
    ce1c  b7         ORA A
    ce1d  ca ef cd   JZ READ_NEXT_SYMBOL (cdef)

    ce20  7e         MOV A, M                   ; Just erase previous character on the screen, and a char
    ce21  05         DCR B                      ; in the buffer. Unlike previuos backspace case this will
    ce22  2b         DCX HL                     ; not track 2-char control characters, and erase only one
                                                ; on the screen

    ce23  c3 a9 ce   JMP READ_CONSOLE_ECHO_SYMBOL (cea9)

READ_NEXT_SYMBOL_4:
    ce26  fe 05      CPI A, 05                  ; Check if this is Ctrl-E (end of line)
    ce28  c2 37 ce   JNZ READ_NEXT_SYMBOL_5 (ce37)

    ce2b  c5         PUSH BC
    ce2c  e5         PUSH HL
    ce2d  cd c9 cd   CALL PRINT_CRLF (cdc9)     ; Print the CR/LF

    ce30  af         XRA A                      ; Restart entering the characters on the next line
    ce31  32 0b cf   STA READ_START_COLUMN (cf0b)   ; (Ctrl-E will not be added to the buffer)

    ce34  c3 f1 cd   JMP READ_NEXT_SYMBOL_2 (cdf1)

READ_NEXT_SYMBOL_5:
    ce37  fe 10      CPI A, 10                  ; Check if Ctrl-P entered
    ce39  c2 48 ce   JNZ READ_NEXT_SYMBOL_6 (ce48)

    ce3c  e5         PUSH HL                    ; Toggle the PRINTER_ENABLED flag
    ce3d  21 0d cf   LXI HL, PRINTER_ENABLED (cf0d)
    ce40  3e 01      MVI A, 01
    ce42  96         SUB M
    ce43  77         MOV M, A
    ce44  e1         POP HL

    ce45  c3 ef cd   JMP READ_NEXT_SYMBOL (cdef)

READ_NEXT_SYMBOL_6:
    ce48  fe 18      CPI A, 18                  ; Check if Ctrl-X entered (restart the current line)
    ce4a  c2 5f ce   JNZ READ_NEXT_SYMBOL_7 (ce5f)

    ce4d  e1         POP HL
BACKSPACE_LOOP:
    ce4e  3a 0b cf   LDA READ_START_COLUMN (cf0b)   ; Backspace until reached start of the line
    ce51  21 0c cf   LXI HL, CURSOR_COLUMN (cf0c)
    ce54  be         CMP M
    ce55  d2 e1 cd   JNC READ_CONSOLE_BUFFER (cde1)

    ce58  35         DCR M                      ; Do the backspace
    ce59  cd a4 cd   CALL PRINT_BACKSPACE (cda4)
    
    ce5c  c3 4e ce   JMP BACKSPACE_LOOP (ce4e)

READ_NEXT_SYMBOL_7:
    ce5f  fe 15      CPI A, 15                  ; Check if this is Ctrl-U (restart from the next line)
    ce61  c2 6b ce   JNZ READ_NEXT_SYMBOL_8 (ce6b)

    ce64  cd b1 cd   CALL PRINT_HASH_CRLF (cdb1); Print the CR/LF and restart the buffer read
    ce67  e1         POP HL
    ce68  c3 e1 cd   JMP READ_CONSOLE_BUFFER (cde1)

READ_NEXT_SYMBOL_8:
    ce6b  fe 12      CPI A, 12                  ; Check if this Ctrl-R keyboard combination (retype)
    ce6d  c2 a6 ce   JNZ READ_CONSOLE_STORE_SYMBOL (cea6)


; Re-print the buffer from the next line
;
; Function prints '#' has sign, moves to the next line, and then re-prints symbols currently
; collected in the buffer. The function is used in 2 cases:
; - User entered Ctrl-R combination. In this case function works as described above - re-prints
;   the buffer from the next line
; - User has pressed backspace button. In this case char output function works in 'fake printing'
;   mode, and just calculates the cursor position. Function does 'printing' of the buffer, and 
;   calculate the line width, taking into account that special characters are printed as 2 symbols.
REPRINT_BUFFER:   
    ce70  c5         PUSH BC
    ce71  cd b1 cd   CALL PRINT_HASH_CRLF (cdb1); print #, then CR/LF
    ce74  c1         POP BC
    ce75  e1         POP HL
    ce76  e5         PUSH HL
    ce77  c5         PUSH BC

REPRINT_BUFFER_LOOP:
    ce78  78         MOV A, B                   ; Re-print the line once again, while counting number of
    ce79  b7         ORA A                      ; printed characters
    ce7a  ca 8a ce   JZ REPRINT_BUFFER_1 (ce8a) ; Exit when all characters are printed

    ce7d  23         INX HL                     ; Some symbols in the input buffer are printed as 2 characters
    ce7e  4e         MOV C, M                   ; (^symb). This function calculates number of printed chars
    ce7f  05         DCR B

    ce80  c5         PUSH BC
    ce81  e5         PUSH HL                    ; "Print" the char (in fact, just count characters to print,
    ce82  cd 7f cd   CALL PUT_CHAR_CTRL_SYMBOLS (cd7f)  ; without actual printing)
    ce85  e1         POP HL
    ce86  c1         POP BC

    ce87  c3 78 ce   JMP REPRINT_BUFFER_LOOP (ce78)

REPRINT_BUFFER_1:
    ce8a  e5         PUSH HL

    ce8b  3a 0a cf   LDA COMP_CURSOR_POSITION (cf0a); If we are at the target column already - go
    ce8e  b7         ORA A                          ; and wait for the next symbol
    ce8f  ca f1 cd   JZ READ_NEXT_SYMBOL_2 (cdf1)

    ce92  21 0c cf   LXI HL, CURSOR_COLUMN (cf0c)   ; Calculate how many symbols needs to be erased
    ce95  96         SUB M                          ; with spaces
    ce96  32 0a cf   STA COMP_CURSOR_POSITION (cf0a)

REPRINT_BUFFER_LOOP_2:
    ce99  cd a4 cd   CALL PRINT_BACKSPACE (cda4); Print spaces back until calculated position reached
    
    ce9c  21 0a cf   LXI HL, COMP_CURSOR_POSITION (cf0a)
    ce9f  35         DCR M                      ; Eventualy this will reset COMP_CURSOR_POSITION flag, 
    cea0  c2 99 ce   JNZ REPRINT_BUFFER_LOOP_2 (ce99)   ; and reenable symbols printing

    cea3  c3 f1 cd   JMP READ_NEXT_SYMBOL_2 (cdf1)  ; Then we are ready to wait for the next symbol


; Continuation of READ_CONSOLE function, process regular symbols here.
READ_CONSOLE_STORE_SYMBOL:
    cea6  23         INX HL                     ; Store entered symbol in the input buffer
    cea7  77         MOV M, A
    cea8  04         INR B

READ_CONSOLE_ECHO_SYMBOL:
    cea9  c5         PUSH BC                    ; Print the entered symbol
    ceaa  e5         PUSH HL
    ceab  4f         MOV C, A
    ceac  cd 7f cd   CALL PUT_CHAR_CTRL_SYMBOLS (cd7f)
    ceaf  e1         POP HL
    ceb0  c1         POP BC

    ceb1  7e         MOV A, M                   ; Check if Ctrl-C is pressed
    ceb2  fe 03      CPI A, 03
    ceb4  78         MOV A, B
    ceb5  c2 bd ce   JNZ READ_CONSOLE_ECHO_SYMBOL_1 (cebd)

    ceb8  fe 01      CPI A, 01                  ; Ctrl-C causes soft reset
    ceba  ca 00 00   JZ 0000

READ_CONSOLE_ECHO_SYMBOL_1:
    cebd  b9         CMP C                      ; Check if buffer is full
    cebe  da ef cd   JC READ_NEXT_SYMBOL (cdef)

READ_CONSOLE_BUFFER_EOL:
    cec1  e1         POP HL
    cec2  70         MOV M, B                   ; Store number of received symbols

    cec3  0e 0d      MVI C, 0d                  ; And print the CR (meaning no more symbols in this input)
    cec5  c3 48 cd   JMP DO_PUT_CHAR (cd48)



; Function 0x01 - Console input
;
; The function waits for a console character (if not received already), and echo it on the screen
;
; Return: A - entered character code
CONSOLE_INPUT:
    cec8  cd 06 cd   CALL DO_CONSOLE_INPUT (cd06)
    cecb  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x03 - Input byte from the tape reader
; 
; Return: received byte in A
IN_BYTE:
    cece  cd 15 da   CALL BIOS_IN_BYTE (da15)   ; Input a byte using BIOS/Monitor functions
    ced1  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x06 - Direct console input or output
;
; As output: The function prints the character directly using BIOS routines, without Ctrl-S key 
; combination handling.
;
; Arguments:
; C - 0xff for input char, 0xfe for checking for a key press, or a character symbol for output otherwise
; 
; Returns:
; A - char code of the input character, or 0x00 if no character ready (input mode only)
DIRECT_CONSOLE_IO:
    ced4  79         MOV A, C                   ; Check if the byte is 0xff
    ced5  3c         INR A
    ced6  ca e0 ce   JZ DIRECT_CONSOLE_INPUT (cee0)

    ced9  3c         INR A                      ; Check if the byte is 0xfe
    ceda  ca 06 da   JZ BIOS_IS_KEY_PRESSED (da06)

    cedd  c3 0c da   JMP BIOS_PUT_CHAR (da0c)   ; In output mode - print characters as usual

DIRECT_CONSOLE_INPUT:
    cee0  cd 06 da   CALL BIOS_IS_KEY_PRESSED (da06); Check if a character is ready
    cee3  b7         ORA A
    cee4  ca 91 d9   JZ BDOS_HANDLER_RETURN_EXIT (d991)

    cee7  cd 09 da   CALL BIOS_CONSOLE_INPUT (da09) ; Input the character. No echo is performed.
    ceea  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x07 - Get I/O byte
;
; Get the byte from its location at 0x0003
GET_IO_BYTE:
    ceed  3a 03 00   LDA 0003
    cef0  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x08 - Set I/O byte
;
; Store the byte to its location at 0x0003
SET_IO_BYTE:
    cef3  21 03 00   LXI HL, 0003
    cef6  71         MOV M, C
    cef7  c9         RET


; Function 0x09 - Print string
;
; Arguments:
; DE - pointer to the string to print
PRINT_STRING:
    cef8  eb         XCHG                       ; Move pointer to BC
    cef9  4d         MOV C, L
    cefa  44         MOV B, H
    cefb  c3 d3 cd   JMP DO_PRINT_STRING (cdd3)


; Function 0x0b - check console status (check if a symbol entered on keyboard)
;
; Returns: A=01 if a key is pressed, A=00 if no key pressed
GET_CONSOLE_STATUS:
    cefe  cd 23 cd   CALL IS_KEY_PRESSED (cd23)


; A handy function that does function exit and stores exit code from A to a variable to be used later.
FUNCTION_EXIT:
    cf01  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)   ; Store A in the predefined variable

FUNC_26:
FUNC_27:
    cf04  c9         RET

; A handy function that signals an error from a function
EXIT_WITH_ERROR:
    cf05  3e 01      MVI A, 01                  ; Set the return code to 1 and exit
    cf07  c3 01 cf   JMP FUNCTION_EXIT (cf01)

COMP_CURSOR_POSITION:
    cf0a  00           db 00                    ; Flag indicates that no char printing required, only
                                                ; computing the resulting cursor position

READ_START_COLUMN:
    cf0b  00           db 00                    ; Cursor position when starting a input buffer reading

CURSOR_COLUMN:
    cf0c  00           db 00                    ; Variable that tracks current cursor column

PRINTER_ENABLED:
    cf0d  00           db 00                    ; Flag indicating that symbols are output to the printer

CONSOLE_KEY_PRESSED:
    cf0e  00           db 00                    ; Buffer for the entered symbol

BDOS_SAVE_SP:
    cf0f  00 00        dw 0000                  ; User stack pointer (BDOS switches to its own stack)

BDOS_STACK_BUF:
    cf11  0x30 *00     dw 0x30 * 0x00           ; BDOS stack area

BDOS_STACK:                                     ; Top of the stack                 

USER_CODE:
    cf41  00           db 00                    ; user code (get/set by function 0x20)

CURRENT_DISK:
    cf42  00           db 00                    ; Current disk


FUNCTION_ARGUMENTS:
    cf43  00 00        dw 0000                  ; Function arguments, so that functions can refer to it any time

FUNCTION_RETURN_VALUE:
    cf45  00 00        dw 0000                  ; Function return value, passed via a variable, not register



HANDLE_DISK_SELECT_ERROR:
    cf47  21 0b cc   LXI HL, DISK_SELECT_ERROR_PTR (cc0b)


; A helper function that jumps to the error handler address stored at [HL]
ROUTE_TO_ERROR_HANDLER:
    cf4a  5e         MOV E, M                   ; Load handler address to DE
    cf4b  23         INX HL
    cf4c  56         MOV D, M

    cf4d  eb         XCHG                       ; Jump to the handler
    cf4e  e9         PCHL


; Copy C bytes from [DE] to [HL]
MEMCOPY_DE_HL:
    cf4f  0c         INR C

MEMCOPY_DE_HL_LOOP:
    cf50  0d         DCR C
    cf51  c8         RZ

    cf52  1a         LDAX DE
    cf53  77         MOV M, A
    cf54  13         INX DE
    cf55  23         INX HL
    cf56  c3 50 cf   JMP MEMCOPY_DE_HL_LOOP (cf50)


; Select disk specified in CURRENT_DISK variable, and perform disk initialization routines
;
; The function performs the following steps:
; - Select the disk in BIOS
; - Parses disk descriptor and stores its values in BDOS variables
; - Parses disk parameter block and store its values in BDOS variables
; - Depending on the disk size prepare for 1-byte or 2-byte allocation records
DO_SELECT_DISK:
    cf59  3a 42 cf   LDA CURRENT_DISK (cf42)    ; Select the disk
    cf5c  4f         MOV C, A
    cf5d  cd 1b da   CALL BIOS_SELECT_DISK (da1b)

    cf60  7c         MOV A, H                   ; Check if return code in HL is zero (no disk selected)
    cf61  b5         ORA L
    cf62  c8         RZ

    cf63  5e         MOV E, M                   ; Parse Disk Descriptor. Get address of sector translation
    cf64  23         INX HL                     ; table to DE
    cf65  56         MOV D, M
    cf66  23         INX HL

    cf67  22 b3 d9   SHLD LAST_DIR_ENTRY_NUM_ADDR (d9b3)  ; Store the pointer last directory entry number

    cf6a  23         INX HL                     ; Store the pointer to current track variable
    cf6b  23         INX HL
    cf6c  22 b5 d9   SHLD CUR_TRACK_ADDR (d9b5)

    cf6f  23         INX HL                     ; Store the pointer to current sector variable
    cf70  23         INX HL
    cf71  22 b7 d9   SHLD CUR_TRACK_SECTOR_ADDR (d9b7)

    cf74  23         INX HL                     ; Get address of the directory buffer ptr field
    cf75  23         INX HL
    cf76  eb         XCHG

    cf77  22 d0 d9   SHLD SECTOR_TRANS_TABLE (d9d0) ; Store sector translation table

    cf7a  21 b9 d9   LXI HL, DIRECTORY_BUFFER_ADDR (d9b9)   ; Copy directory buffer ptr, disk param block ptr,
    cf7d  0e 08      MVI C, 08                              ; directory CRC vector addr, allocation vector addr
    cf7f  cd 4f cf   CALL MEMCOPY_DE_HL (cf4f)

    cf82  2a bb d9   LHLD DISK_PARAMS_BLOCK_ADDR (d9bb) ; Copy disk parameters block into separate variables
    cf85  eb         XCHG
    cf86  21 c1 d9   LXI HL, DISK_PARAMETER_BLOCK (d9c1)
    cf89  0e 0f      MVI C, 0f
    cf8b  cd 4f cf   CALL MEMCOPY_DE_HL (cf4f)  

    cf8e  2a c6 d9   LHLD DISK_TOTAL_STORAGE_CAPACITY (d9c6)    ; Check if disk capacity is small enough
    cf91  7c         MOV A, H
    cf92  21 dd d9   LXI HL, SINGLE_BYTE_ALLOCATION_MAP (d9dd)
    cf95  36 ff      MVI M, ff                          ; if small - use the single byte allocation records
    cf97  b7         ORA A                              ; for file allocation table
    cf98  ca 9d cf   JZ DO_SELECT_DISK_EXIT (cf9d)
    cf9b  36 00      MVI M, 00                          ; otherwise it will be double byte records

DO_SELECT_DISK_EXIT:
    cf9d  3e ff      MVI A, ff                  ; Indicate success of the disk selection
    cf9f  b7         ORA A
    cfa0  c9         RET


; Move to track zero and reset all track/sector counters
SET_TRACK_ZERO:
    cfa1  cd 18 da   CALL BIOS_SET_TRACK_ZERO (da18)

    cfa4  af         XRA A                      ; Reset current track number
    cfa5  2a b5 d9   LHLD CUR_TRACK_ADDR (d9b5)
    cfa8  77         MOV M, A
    cfa9  23         INX HL
    cfaa  77         MOV M, A

    cfab  2a b7 d9   LHLD CUR_TRACK_SECTOR_ADDR (d9b7)  ; Reset current sector number
    cfae  77         MOV M, A
    cfaf  23         INX HL
    cfb0  77         MOV M, A

    cfb1  c9         RET

; Read a sector
;
; This function is a little wrapper over BIOS' read sector function, with the addition of error handling
READ_SECTOR:
    cfb2  cd 27 da   CALL BIOS_READ_SECTOR (da27)
    cfb5  c3 bb cf   JMP CHECK_READ_WRITE_ERROR (cfbb)

; Write a sector
;
; This function is a little wrapper over BIOS' write sector function, with the addition of error handling
WRITE_SECTOR:
    cfb8  cd 2a da   CALL BIOS_WRITE_SECTOR (da2a)

; Check the read/write sector function error code, and handle it if necessary
CHECK_READ_WRITE_ERROR:
    cfbb  b7         ORA A
    cfbc  c8         RZ

    cfbd  21 09 cc   LXI HL, DISK_READ_WRITE_ERROR_PTR (cc09)
    cfc0  c3 4a cf   JMP ROUTE_TO_ERROR_HANDLER (cf4a)


; Seek to directory entry
;
; The function converts the directory entry index (counter) to the index of the sector that contains
; the desired entry.
SEEK_TO_DIR_ENTRY:
    cfc3  2a ea d9   LHLD DIRECTORY_COUNTER (d9ea)  ; Calculate sector number of the directory entry
    cfc6  0e 02      MVI C, 02                      ; (having just 4 entries on the sector, the sector number
    cfc8  cd ea d0   CALL SHIFT_HL_RIGHT (d0ea)     ; is entry number divided by 4)

    cfcb  22 e5 d9   SHLD ACTUAL_SECTOR (d9e5)      ; Set the desired sector (assuming directory sectors are
    cfce  22 ec d9   SHLD CURRENT_DIR_ENTRY_SECTOR (d9ec)   ; in the beginning of the disk)


; Seek to selected sector
;
; The function moves to the requested track and sector. Argument of the function is a sector number
; (d9e5), which is a logical sector index from the start of the disk. The function converts it to the
; track number and track sector index.
;
; Since the disk may have reserved tracks at the beginning of the disk, reserved tracks number is added
; to the logical track number when calculating physical track number.
;
; Eventually the function uses BIOS functions to select track and sector.
;
; Result is calculated as follows:
; - Logical track number = requested sector number / sectors per track (ignore the rest)
; - Physical track number = logical track number + number of reserved tracks
; - Track first sector number = logical track number * sectors-per-track
; - Logical sector number = requested sector number - track first sector number
;                           (should be the same as requested sector number % sectors per track)
; - Physical sector number = sector_translate(logical sector number)
;
; Perhaps counting track number as requested sector number / sectors per track could be very CPU consuming
; for large sector numbers, and significantly drop performance on the far tracks. Instead, the implementation
; does a trick: most probably programs will move a few tracks further or backward, rathar than do large
; jumps. So the trick is to advance track counter starting on current track, by adding/subtracting
; sectors-per-track value to the sector counter.
SEEK_TO_SECTOR:
    cfd1  21 e5 d9   LXI HL, ACTUAL_SECTOR (d9e5)   ; Load desired sector number to BC
    cfd4  4e         MOV C, M
    cfd5  23         INX HL
    cfd6  46         MOV B, M

    cfd7  2a b7 d9   LHLD CUR_TRACK_SECTOR_ADDR (d9b7)  ; Load current track first sector number to DE
    cfda  5e         MOV E, M
    cfdb  23         INX HL
    cfdc  56         MOV D, M

    cfdd  2a b5 d9   LHLD CUR_TRACK_ADDR (d9b5) ; Load current track number to HL
    cfe0  7e         MOV A, M
    cfe1  23         INX HL
    cfe2  66         MOV H, M
    cfe3  6f         MOV L, A

    ; If requested sector number is lower than current track sector number, decrease current track sector
    ; in sector-per-track steps, and simultaneously decrease track counter. As a result of this operation
    ; it will calculate track number where requested sector is located.
SEEK_TO_SECTOR_LOOP1:
    cfe4  79         MOV A, C                   
    cfe5  93         SUB E                      ; Compare desired sector number with current sector number
    cfe6  78         MOV A, B                   ; (BC - HL)
    cfe7  9a         SBB D
    cfe8  d2 fa cf   JNC SEEK_TO_SECTOR_LOOP2 (cffa)

    cfeb  e5         PUSH HL                    ; Load sectors per track value to HL
    cfec  2a c1 d9   LHLD DISK_SECTORS_PER_TRACK (d9c1)

    cfef  7b         MOV A, E                   ; Decrease current sector number by sectors-per-track value
    cff0  95         SUB L
    cff1  5f         MOV E, A

    cff2  7a         MOV A, D
    cff3  9c         SBB H
    cff4  57         MOV D, A

    cff5  e1         POP HL                     ; and decrement track counter
    cff6  2b         DCX HL

    cff7  c3 e4 cf   JMP SEEK_TO_SECTOR_LOOP1 (cfe4); repeat until we reach requested track

    ; If requested sector number is greater than current sector number - do the same in other direction:
    ; increase current sector by sectors-per-track steps, and simultaneously increment track counter. 
    ; As a result of this operation it will calculate track number where requested sector is located
SEEK_TO_SECTOR_LOOP2:
    cffa  e5         PUSH HL                    ; Load sectors-per-track value
    cffb  2a c1 d9   LHLD DISK_SECTORS_PER_TRACK (d9c1)

    cffe  19         DAD DE                     ; Increase current sector number by sectors-per-track value
    cfff  da 0f d0   JC SEEK_TO_SECTOR_EXIT (d00f)

    d002  79         MOV A, C                   ; Compare requested track number and current track number
    d003  95         SUB L
    d004  78         MOV A, B
    d005  9c         SBB H
    d006  da 0f d0   JC SEEK_TO_SECTOR_EXIT (d00f)

    d009  eb         XCHG                       
    d00a  e1         POP HL
    d00b  23         INX HL                     ; Increment track number

    d00c  c3 fa cf   JMP SEEK_TO_SECTOR_LOOP2 (cffa); Continue until reached desired track

SEEK_TO_SECTOR_EXIT:
    d00f  e1         POP HL
    d010  c5         PUSH BC
    d011  d5         PUSH DE
    d012  e5         PUSH HL

    d013  eb         XCHG                       ; Load the reserved track number
    d014  2a ce d9   LHLD DISK_NUM_RESERVED_TRACKS (d9ce)

    d017  19         DAD DE                     ; Physical track number = logical track + reserved tracks

    d018  44         MOV B, H                   ; Select track
    d019  4d         MOV C, L
    d01a  cd 1e da   CALL BIOS_SELECT_TRACK (da1e)

    d01d  d1         POP DE
    d01e  2a b5 d9   LHLD CUR_TRACK_ADDR (d9b5) ; Store calculated track number
    d021  73         MOV M, E
    d022  23         INX HL
    d023  72         MOV M, D
    d024  d1         POP DE

    d025  2a b7 d9   LHLD CUR_TRACK_SECTOR_ADDR (d9b7); Store calculated track sector number
    d028  73         MOV M, E
    d029  23         INX HL
    d02a  72         MOV M, D
    d02b  c1         POP BC

    d02c  79         MOV A, C                   ; Calculate sector number on the track which is a difference
    d02d  93         SUB E                      ; between requested sector number, and number of the first
    d02e  4f         MOV C, A                   ; sector on the track (BC = BC - sector number)

    d02f  78         MOV A, B
    d030  9a         SBB D
    d031  47         MOV B, A

    d032  2a d0 d9   LHLD SECTOR_TRANS_TABLE (d9d0) ; Translate logical to physical sector number
    d035  eb         XCHG
    d036  cd 30 da   CALL BIOS_TRANSLATE_SECTOR (da30)

    d039  4d         MOV C, L                   ; Select the sector
    d03a  44         MOV B, H
    d03b  c3 21 da   JMP BIOS_SELECT_SECTOR (da21)


; Calculate position in the disk allocation vector
;
; The function algorithm:
;     block index = current record >> block shift factor
;     extent value = extent number << (7 - block shift factor)
;     res = extent value + block index
;
; It is quite hard to understand the intention of the function. Here are a few examples for different
; block shift factors (number of sectors in block)
;
; block size    sectors per block       block shift     disk map position
; 1k            8                       3               sect/8  + extval*16
; 2k            16                      4               sect/16 + extval*8
; 4k            32                      5               sect/32 + extval*4
; 8k            64                      6               sect/64 + extval*2
; 16k           128                     7               sect/128 + extval
; Where sect is a record (sector) number within the current extent, and extval is a extent number masked
; with disk extent mask.
;
; In other words this function calculates the position of the byte in the allocation vector that corresponds
; to the given file record.
;
; Return: calculated value is in A register
CALC_DISK_MAP_POS:
    d03e  21 c3 d9   LXI HL, DISK_BLOCK_SHIFT_FACTOR (d9c3)
    d041  4e         MOV C, M

    d042  3a e3 d9   LDA CURRENT_RECORD_INDEX (d9e3)

CALC_DISK_MAP_POS_LOOP1:
    d045  b7         ORA A                      ; Shift record index right Block Shift Factor times
    d046  1f         RAR                        ; This will get the block index in the extent
    d047  0d         DCR C
    d048  c2 45 d0   JNZ CALC_DISK_MAP_POS_LOOP1 (d045)

    d04b  47         MOV B, A                   ; Store block index in B

    d04c  3e 08      MVI A, 08                  ; C = 8 - block shift factor
    d04e  96         SUB M
    d04f  4f         MOV C, A

    d050  3a e2 d9   LDA EXTENT_NUMBER_MASKED (d9e2)

CALC_DISK_MAP_POS_LOOP2:
    d053  0d         DCR C                      ; Move extent number left C-1 times
    d054  ca 5c d0   JZ CALC_DISK_MAP_POS_FIN (d05c)
    d057  b7         ORA A
    d058  17         RAL
    d059  c3 53 d0   JMP CALC_DISK_MAP_POS_LOOP2 (d053)

CALC_DISK_MAP_POS_FIN:
    d05c  80         ADD B
    d05d  c9         RET


; Return a record in the FCB or extent allocation vector (block number)
;
; Each FCB or a directory entry has a vector, containing 16 one-byte or 8 two-byte block numbers.
; This function returns an entry in this vector at the given index.
;
; Arguments:
; BC - block index in the current extent or FCB allocation vector
;
; Return:
; HL - block number
GET_BLOCK_NUM_FOR_RECORD:
    d05e  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Calculate allocation vector ptr of the given FCB
    d061  11 10 00   LXI DE, 0010
    d064  19         DAD DE

    d065  09         DAD BC                     ; Add current record (sector) block number index

    d066  3a dd d9   LDA SINGLE_BYTE_ALLOCATION_MAP (d9dd)  ; Check if the allocation map is single byte
    d069  b7         ORA A
    d06a  ca 71 d0   JZ GET_BLOCK_NUM_FOR_RECORD_1 (d071)

    d06d  6e         MOV L, M                   ; Load 1-byte block number at given index to HL
    d06e  26 00      MVI H, 00
    d070  c9         RET

GET_BLOCK_NUM_FOR_RECORD_1:
    d071  09         DAD BC                     ; Double the offset

    d072  5e         MOV E, M                   ; get the 2-byte block number to HL
    d073  23         INX HL
    d074  56         MOV D, M
    d075  eb         XCHG

    d076  c9         RET



; Calculate block number for currently read/write sector
;
; This function is used for sequental read/write operations, and convert current sector index
; into block number.
;
; Algorithm:
; - Take current sector index and convert it into the block index
; - Read the block number from the FCB allocation vector at the calculated index
; - Store calculated block number into ACTUAL_SECTOR variable (yeah, temporary ACTUAL_SECTOR variable
;   contains the block number)
; - Calculated block number is returned in HL
CALC_BLOCK_NUMBER:
    d077  cd 3e d0   CALL CALC_DISK_MAP_POS (d03e)
    d07a  4f         MOV C, A

    d07b  06 00      MVI B, 00
    d07d  cd 5e d0   CALL GET_BLOCK_NUM_FOR_RECORD (d05e)

    d080  22 e5 d9   SHLD ACTUAL_SECTOR (d9e5)  ; Store calculated block number
    d083  c9         RET


; Check if the block number record is zero (HL==0)
IS_BLOCK_ZERO:
    d084  2a e5 d9   LHLD ACTUAL_SECTOR (d9e5)
    d087  7d         MOV A, L
    d088  b4         ORA H
    d089  c9         RET


; Calculate sector number based current record index
;
; This function calculates the actual sector number, taking into account block number (calculated
; previously) and current record index
;
; Algorithm:
; - First sector of block = block number << block shift factor
; - sector within the block = record index & block mask
; - res (HL) = first sector of block + sector within the block
CALC_SECTOR_NUMBER:
    d08a  3a c3 d9   LDA DISK_BLOCK_SHIFT_FACTOR (d9c3) ; Load block shift factor (number of sectors in block)
    d08d  2a e5 d9   LHLD ACTUAL_SECTOR (d9e5)          ; Load the block number

CALC_SECTOR_NUMBER_LOOP:
    d090  29         DAD HL                     ; sector number = block number << shift factor
    d091  3d         DCR A
    d092  c2 90 d0   JNZ CALC_SECTOR_NUMBER_LOOP (d090)

    d095  22 e7 d9   SHLD BLOCK_FIRST_SECTOR (d9e7) ; Save for future use

    d098  3a c4 d9   LDA DISK_BLOCK_BLM (d9c4)  ; Load the block mask
    d09b  4f         MOV C, A

    d09c  3a e3 d9   LDA CURRENT_RECORD_INDEX (d9e3); Load current record index and apply the block mask
    d09f  a1         ANA C

    d0a0  b5         ORA L                      ; Add current record index to the sector number
    d0a1  6f         MOV L, A

    d0a2  22 e5 d9   SHLD ACTUAL_SECTOR (d9e5)  ; Store the calculated sector number
    d0a5  c9         RET



; HL = FCB pointer + 0x0c (extent number offset in the FCB)
GET_FCB_EXTENT_NUMBER:
    d0a6  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
    d0a9  11 0c 00   LXI DE, 000c
    d0ac  19         DAD DE
    d0ad  c9         RET


; DE = FCB pointer + 0xf (record count)
; HL = FCB pointer + 0x20 (current read/write record)
GET_FCB_NUM_RECORDS:
    d0ae  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
    d0b1  11 0f 00   LXI DE, 000f
    d0b4  19         DAD DE
    d0b5  eb         XCHG

    d0b6  21 11 00   LXI HL, 0011
    d0b9  19         DAD DE
    d0ba  c9         RET


; Load record counter and total record number values, and store them into variables
LOAD_RECORDS_COUNT:
    d0bb  cd ae d0   CALL GET_FCB_NUM_RECORDS (d0ae); Get current record (sector) number
    d0be  7e         MOV A, M
    d0bf  32 e3 d9   STA CURRENT_RECORD_INDEX (d9e3)

    d0c2  eb         XCHG                       ; Get total number of records (sectors) in this extent
    d0c3  7e         MOV A, M
    d0c4  32 e1 d9   STA TOTAL_EXTENT_RECORDS (d9e1)

    d0c7  cd a6 d0   CALL GET_FCB_EXTENT_NUMBER (d0a6)  ; Get extent number from FCB

    d0ca  3a c5 d9   LDA DISK_EXTENT_MASK (d9c5); Apply extent mask and save
    d0cd  a6         ANA M
    d0ce  32 e2 d9   STA EXTENT_NUMBER_MASKED (d9e2); Extent number masked
    d0d1  c9         RET



; Update FCB record counter
;
; The function increments current record counter for sequental operations (leave it as is for random
; access operations), and update total record counter
UPDATE_RECORD_COUNTER:
    d0d2  cd ae d0   CALL GET_FCB_NUM_RECORDS (d0ae); Get current and total records for the extent in DE and HL

    d0d5  3a d5 d9   LDA SEQUENTAL_OPERATION (d9d5) ; Compare operation type with #2 (zeroed write)
    d0d8  fe 02      CPI A, 02
    d0da  c2 de d0   JNZ UPDATE_RECORD_COUNTER_1 (d0de)

    d0dd  af         XRA A                      ; Operation #2 is similar to operation #0 (random read/write)

UPDATE_RECORD_COUNTER_1:
    d0de  4f         MOV C, A                   ; Increment record counter for sequental operation, but do
    d0df  3a e3 d9   LDA CURRENT_RECORD_INDEX (d9e3)    ; nothing for random access operations
    d0e2  81         ADD C
    d0e3  77         MOV M, A

    d0e4  eb         XCHG
    d0e5  3a e1 d9   LDA TOTAL_EXTENT_RECORDS (d9e1)    ; Update total records count
    d0e8  77         MOV M, A

    d0e9  c9         RET


; Shift HL right C number of times
SHIFT_HL_RIGHT:
    d0ea  0c         INR C

SHIFT_HL_RIGHT_LOOP:
    d0eb  0d         DCR C
    d0ec  c8         RZ

    d0ed  7c         MOV A, H
    d0ee  b7         ORA A
    d0ef  1f         RAR
    d0f0  67         MOV H, A

    d0f1  7d         MOV A, L
    d0f2  1f         RAR
    d0f3  6f         MOV L, A

    d0f4  c3 eb d0   JMP SHIFT_HL_RIGHT_LOOP (d0eb)

; Calculate CRC on the data buffer at DIRECTORY_BUFFER_ADDR
CALC_DIRECTORY_BUF_CRC:
    d0f7  0e 80      MVI C, 80
    d0f9  2a b9 d9   LHLD DIRECTORY_BUFFER_ADDR (d9b9)

    d0fc  af         XRA A
CALC_DIRECTORY_BUF_CRC_LOOP:
    d0fd  86         ADD M
    d0fe  23         INX HL
    d0ff  0d         DCR C
    d100  c2 fd d0   JNZ CALC_DIRECTORY_BUF_CRC_LOOP (d0fd)

    d103  c9         RET


; Shift HL left C number of times
SHIFT_HL_LEFT:
    d104  0c         INR C
SHIFT_HL_LEFT_LOOP:
    d105  0d         DCR C
    d106  c8         RZ
    d107  29         DAD HL
    d108  c3 05 d1   JMP SHIFT_HL_LEFT_LOOP (d105)


; Calculate disk bitmask
;
; Arguments:
; BC - original bitmask
;
; Return:
; HL - original bitmask with current disk bit set
SET_DISK_BIT_MASK:
    d10b  c5         PUSH BC
    d10c  3a 42 cf   LDA CURRENT_DISK (cf42)    ; Calculate disk bit position
    d10f  4f         MOV C, A
    d110  21 01 00   LXI HL, 0001
    d113  cd 04 d1   CALL SHIFT_HL_LEFT (d104)
    d116  c1         POP BC

    d117  79         MOV A, C
    d118  b5         ORA L
    d119  6f         MOV L, A

    d11a  78         MOV A, B
    d11b  b4         ORA H
    d11c  67         MOV H, A

    d11d  c9         RET

; Check if the disk is read only
;
; Arguments:
; A - disk number
; 
; Returns:
; Z flag set if disk is writable, Z flag reset read only
IS_DISK_READ_ONLY:
    d11e  2a ad d9   LHLD READ_ONLY_VECTOR (d9ad)   ; Get read only vector

    d121  3a 42 cf   LDA CURRENT_DISK (cf42)        ; Shift it right up to the current disk bit
    d124  4f         MOV C, A
    d125  cd ea d0   CALL SHIFT_HL_RIGHT (d0ea)

    d128  7d         MOV A, L                       ; Check if the disk bit is set
    d129  e6 01      ANI A, 01
    d12b  c9         RET


; Function 0x1c - Write protect current disk
;
; Arguments:
; E - disk index
WRITE_PROTECT_DISK:
    d12c  21 ad d9   LXI HL, READ_ONLY_VECTOR (d9ad); Load read only vector to BC
    d12f  4e         MOV C, M
    d130  23         INX HL
    d131  46         MOV B, M

    d132  cd 0b d1   CALL SET_DISK_BIT_MASK (d10b)  ; Set the bit in the vector

    d135  22 ad d9   SHLD READ_ONLY_VECTOR (d9ad)   ; Store the vector back

    d138  2a c8 d9   LHLD DISK_NUM_DIRECTORY_ENTRIES (d9c8) ; Get the maximum number of dir entries to DE
    d13b  23         INX HL
    d13c  eb         XCHG

    d13d  2a b3 d9   LHLD LAST_DIR_ENTRY_NUM_ADDR (d9b3)  ; Set the last directory entry number as max+1
    d140  73         MOV M, E                       ; so that no more entries can be written
    d141  23         INX HL
    d142  72         MOV M, D

    d143  c9         RET

; Load the directory entry, check the first byte of the file extension.
; If the MSB is set (the file is read only) - raise the error
CHECK_FILE_READ_ONLY:
    d144  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Load directory entry address in HL

; Check the file read only flag for record address in HL.
; If file is read only corresponding message is printed, and system restarted.
CHECK_FILE_READ_ONLY_FLAG:
    d147  11 09 00   LXI DE, 0009               ; Offset to file extension
    d14a  19         DAD DE

    d14b  7e         MOV A, M                   ; Return if file is writable (MSB of first extension byte
    d14c  17         RAL                        ; is 0)
    d14d  d0         RNC

    d14e  21 0f cc   LXI HL, FILE_READ_ONLY_ERROR_PTR (cc0f); Report file read only error
    d151  c3 4a cf   JMP ROUTE_TO_ERROR_HANDLER (cf4a)


; Check if the disk is read only, and report an error.
; If the disk is read only, corresponding message is printed, and system restarted.
CHECK_DISK_READ_ONLY:
    d154  cd 1e d1   CALL IS_DISK_READ_ONLY (d11e)
    d157  c8         RZ
    d158  21 0d cc   LXI HL, DISK_READ_ONLY_ERROR_PTR (cc0d)
    d15b  c3 4a cf   JMP ROUTE_TO_ERROR_HANDLER (cf4a)

; Calculate directory entry address
;
; HL = dir buffer + dir entry offset
GET_DIR_ENTRY_ADDR:
    d15e  2a b9 d9   LHLD DIRECTORY_BUFFER_ADDR (d9b9)
    d161  3a e9 d9   LDA DIRECTORY_ENTRY_OFFSET (d9e9)

; HL += A
HL_ADD_A:
    d164  85         ADD L
    d165  6f         MOV L, A
    d166  d0         RNC
    d167  24         INR H
    d168  c9         RET


; Get extent number high byte (S2 byte) of the File Control Block (FCB)
;
; Returns:
; HL = HL + 0x0e
; A = [HL]
GET_FCB_EXT_NUM_HIGH:
    d169  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
    d16c  11 0e 00   LXI DE, 000e
    d16f  19         DAD DE
    d170  7e         MOV A, M
    d171  c9         RET

; Clear the extent number high byte (S2 byte) in the File Control Block (FCB)
CLEAR_FCB_EXT_NUM_HIGH:
    d172  cd 69 d1   CALL GET_FCB_EXT_NUM_HIGH (d169)
    d175  36 00      MVI M, 00
    d177  c9         RET

; Set the high bit in S2 byte of the File Control Block (FCB) indicating that the file is in write mode
SET_FILE_WRITE_FLAG:
    d178  cd 69 d1   CALL GET_FCB_EXT_NUM_HIGH (d169)
    d17b  f6 80      ORI A, 80
    d17d  77         MOV M, A
    d17e  c9         RET

; Compare current directory counter and the last dir entry number. Set corresponding flags.
CMP_DIR_COUNTER_WITH_MAX:
    d17f  2a ea d9   LHLD DIRECTORY_COUNTER (d9ea)  ; Load directory entries counter to DE
    d182  eb         XCHG

    d183  2a b3 d9   LHLD LAST_DIR_ENTRY_NUM_ADDR (d9b3)  ; Load last directory entry number ptr to HL

    d186  7b         MOV A, E                   ; Compare the 2 values (DE - [HL])
    d187  96         SUB M
    d188  23         INX HL
    d189  7a         MOV A, D
    d18a  9e         SBB M

    d18b  c9         RET


UPDATE_LAST_DIR_ENTRY_NUMBER:
    d18c  cd 7f d1   CALL CMP_DIR_COUNTER_WITH_MAX (d17f)   ; Check if dir entry counter reached the last
    d18f  d8         RC                                     ; value

    d190  13         INX DE                     ; If yes - update the last entry number with the current
    d191  72         MOV M, D                   ; entry + 1
    d192  2b         DCX HL
    d193  73         MOV M, E
    d194  c9         RET

; Compares DE and HL (do DE - HL, and set flags)
CMP_DE_HL:
    d195  7b         MOV A, E
    d196  95         SUB L
    d197  6f         MOV L, A
    d198  7a         MOV A, D
    d199  9c         SBB H
    d19a  67         MOV H, A
    d19b  c9         RET


; Calculate and store directory checksum
UPDATE_DIR_CHECKSUM:   
    d19c  0e ff      MVI C, ff

; Calculate, check or store directory sector checksum
;
; The function calculates the CRC for current directory sector, and compares it to one stored
; in the CRC vector. If does not match - the disk will be marked as read only to avoid further corruption.
;
; Each byte of the CRC vector matches a whole directory sector (which is located at the beginning of the
; disk, if not counting reserved tracks)
;
; Arguments: 
; C = 0xff - calculate and store checksum
; other C value - check the disk entry checksum
CHECK_UPDATE_DIR_CHECKSUM:
    d19e  2a ec d9   LHLD CURRENT_DIR_ENTRY_SECTOR (d9ec)   ; Load current dir entry sector number to DE
    d1a1  eb         XCHG

    d1a2  2a cc d9   LHLD DISK_DIRECTORY_CHECK_VECT_SIZE (d9cc) ; Compare it with directory vector size,
    d1a5  cd 95 d1   CALL CMP_DE_HL (d195)                      ; meaning we reached the end of directory
    d1a8  d0         RNC

    d1a9  c5         PUSH BC
    d1aa  cd f7 d0   CALL CALC_DIRECTORY_BUF_CRC (d0f7) ; Calculate the directory buffer CRC to A

    d1ad  2a bd d9   LHLD DIR_CRC_VECTOR_PTR (d9bd)     ; Load address of the CRC vector
    d1b0  eb         XCHG

    d1b1  2a ec d9   LHLD CURRENT_DIR_ENTRY_SECTOR (d9ec)   ; Add the current dir sector number
    d1b4  19         DAD DE
    d1b5  c1         POP BC

    d1b6  0c         INR C                      ; Check the argument flag
    d1b7  ca c4 d1   JZ STORE_NEW_CHECKSUM (d1c4)   ; If flag is 0xff - store the calculated checksum

    d1ba  be         CMP M                      ; Compare checksum otherwise
    d1bb  c8         RZ                         ; Exit if checksum has not changed

    d1bc  cd 7f d1   CALL CMP_DIR_COUNTER_WITH_MAX (d17f)   ; Checksum check failed, but that is ok if
    d1bf  d0         RNC                        ; we reached end of the entries list. If yes - just return

    d1c0  cd 2c d1   CALL WRITE_PROTECT_DISK (d12c) ; Checksum failed for normal entries - write protect the
    d1c3  c9         RET                        ; disk, just in case

STORE_NEW_CHECKSUM:
    d1c4  77         MOV M, A                   ; Store checksum at previously calculated location
    d1c5  c9         RET



; Write an updated directory sector
;
; The function switches the data buffer to the directory buffer, writes the directory sector, and restores buffer back
WRITE_DIRECTORY_SECTOR:
    d1c6  cd 9c d1   CALL UPDATE_DIR_CHECKSUM (d19c); Update directory checksum
    
    d1c9  cd e0 d1   CALL SET_DIR_DISK_BUFFER (d1e0); Write the updated directory entry to the disk

    d1cc  0e 01      MVI C, 01                      ; This supposed to indicate it will write directory 
                                                    ; sector, but this flag never checked

    d1ce  cd b8 cf   CALL WRITE_SECTOR (cfb8)       ; Actually write the sector

    d1d1  c3 da d1   JMP SET_DATA_DISK_BUFFER (d1da); Restore the buffer address


; Read a single sector in directory area
;
; Function sets the directory buffer, reads the sector, and sets the buffer back to data buffer
READ_DIR_SECTOR:
    d1d4  cd e0 d1   CALL SET_DIR_DISK_BUFFER (d1e0)
    d1d7  cd b2 cf   CALL READ_SECTOR (cfb2)


; Set the BIOS Disk buffer to the data buffer
SET_DATA_DISK_BUFFER:
    d1da  21 b1 d9   LXI HL, DISK_BUFFER_ADDR (d9b1)
    d1dd  c3 e3 d1   JMP SET_DISK_BUFFER (d1e3)

; Set the BIOS Disk buffer to the directory buffer
SET_DIR_DISK_BUFFER:
    d1e0  21 b9 d9   LXI HL, DIRECTORY_BUFFER_ADDR (d9b9)

; Set the BIOS Disk buffer to the value pointed by [HL]
SET_DISK_BUFFER:
    d1e3  4e         MOV C, M                   ; Load disk buffer addres from [HL]
    d1e4  23         INX HL
    d1e5  46         MOV B, M
    d1e6  c3 24 da   JMP BIOS_SET_DISK_BUFFER (da24)

; Copy data from directory buffer to the disk buffer.
;
; Search file functions need to return directory data, and therefore have to copy data from the private directory buffer to the 
; public data buffer.
COPY_DIR_BUF_TO_DISK_BUF:
    d1e9  2a b9 d9   LHLD DIRECTORY_BUFFER_ADDR (d9b9)
    d1ec  eb         XCHG
    d1ed  2a b1 d9   LHLD DISK_BUFFER_ADDR (d9b1)
    d1f0  0e 80      MVI C, 80
    d1f2  c3 4f cf   JMP MEMCOPY_DE_HL (cf4f)


; Check if directory counter is 0xffff
;
; Returns Z flag if directory counter is 0xffff
IS_DIR_COUNTER_RESET:
    d1f5  21 ea d9   LXI HL, DIRECTORY_COUNTER (d9ea)
    d1f8  7e         MOV A, M
    d1f9  23         INX HL
    d1fa  be         CMP M
    d1fb  c0         RNZ
    d1fc  3c         INR A
    d1fd  c9         RET


; Set the directory entries counter to 0xffff
RESET_DIRECTORY_COUNTER:
    d1fe  21 ff ff   LXI HL, ffff               
    d201  22 ea d9   SHLD DIRECTORY_COUNTER (d9ea)
    d204  c9         RET


; Advance to the next directory entry
;
; The function advances to the next directory entry, calculating the offset in the buffer.
; The function reads the next directory sector if needed.
;
; Arguments:
; C = 0xff - calculate and set directory sector CRC, 0x00 - to check CRC
;
; Input variables:
; - DIRECTORY_COUNTER 
;
; Updated variables:
; - DIRECTORY_COUNTER 
; - DIRECTORY_ENTRY_OFFSET
GET_NEXT_DIR_ENTRY:
    d205  2a c8 d9   LHLD DISK_NUM_DIRECTORY_ENTRIES (d9c8)
    d208  eb         XCHG                           ; Load number of directory entries to DE

    d209  2a ea d9   LHLD DIRECTORY_COUNTER (d9ea)  ; Increment directory counter and load it to HL
    d20c  23         INX HL
    d20d  22 ea d9   SHLD DIRECTORY_COUNTER (d9ea)

    d210  cd 95 d1   CALL CMP_DE_HL (d195)          ; Check if we reached the last entry
    d213  d2 19 d2   JNC GET_NEXT_DIR_ENTRY_1 (d219)

    d216  c3 fe d1   JMP RESET_DIRECTORY_COUNTER (d1fe) ; If reached - reset the counter and exit

GET_NEXT_DIR_ENTRY_1:
    d219  3a ea d9   LDA DIRECTORY_COUNTER (d9ea)   ; Calculate offset of the directory entry in the sector.
    d21c  e6 03      ANI A, 03                      
    d21e  06 05      MVI B, 05                      ; Each entry is 32 bytes (2^5)

GET_NEXT_DIR_ENTRY_LOOP:
    d220  87         ADD A                          ; Multiply 2 LSB of the counter by 32
    d221  05         DCR B
    d222  c2 20 d2   JNZ GET_NEXT_DIR_ENTRY_LOOP (d220)

    d225  32 e9 d9   STA DIRECTORY_ENTRY_OFFSET (d9e9)  ; Store the calculated offset

    d228  b7         ORA A                          ; Check if we need to read the next sector
    d229  c0         RNZ                            ; if not - we are done

    d22a  c5         PUSH BC                        ; Read the directory sector to the dir buffer
    d22b  cd c3 cf   CALL SEEK_TO_DIR_ENTRY (cfc3)
    d22e  cd d4 d1   CALL READ_DIR_SECTOR (d1d4)
    d231  c1         POP BC

    d232  c3 9e d1   JMP CHECK_UPDATE_DIR_CHECKSUM (d19e)   ; Check/Update directory sector checksum


; Get the disk allocation vector entry for the given block number
;
; This function calculates the address of the bit in the allocation vector, that corresponds
; to the given block index. The function returns current bit value in the vector, and the value
; address so that the caller may update the record.
;
; Arguments:
; BC    - disk map block index
;
; Return:
; HL    - address of the allocation vector byte
; D     - bit index in the allocation vector byte
; A     - disk map entry shifted right so that LSB corresponds to the selected block
GET_DISK_ALLOCATION_BIT:
    d235  79         MOV A, C                   ; Calculate the bit number that correspond the block 
    d236  e6 07      ANI A, 07                  ; D = E = (BC % 8 + 1)
    d238  3c         INR A
    d239  5f         MOV E, A
    d23a  57         MOV D, A

    d23b  79         MOV A, C                   ; Shift remaining 5 bits of C right to the lowest position
    d23c  0f         RRC
    d23d  0f         RRC
    d23e  0f         RRC
    d23f  e6 1f      ANI A, 1f
    d241  4f         MOV C, A

    d242  78         MOV A, B                   ; Add lowest 3 bits of B
    d243  87         ADD A
    d244  87         ADD A
    d245  87         ADD A
    d246  87         ADD A
    d247  87         ADD A
    d248  b1         ORA C
    d249  4f         MOV C, A

    d24a  78         MOV A, B                   ; Take 5 bits of B so that BC now looks like follows:
    d24b  0f         RRC                        ; 000bbbbb bbbccccc (lowest 3 bits of C are in D and E)
    d24c  0f         RRC
    d24d  0f         RRC
    d24e  e6 1f      ANI A, 1f
    d250  47         MOV B, A

    d251  2a bf d9   LHLD DISK_ALLOCATION_VECTOR_PTR (d9bf)
    d254  09         DAD BC                     ; Calculate the address in the allocation vector

    d255  7e         MOV A, M                   ; Load the value in the vector

GET_DISK_ALLOCATION_BIT_LOOP:
    d256  07         RLC                        ; Shift value right, so that LSB correspond to the 
    d257  1d         DCR E                      ; required block
    d258  c2 56 d2   JNZ GET_DISK_ALLOCATION_BIT_LOOP (d256)

    d25b  c9         RET



; Set disk allocation bit
;
; The function updates the bit in the disk allocation map. The bit correspond to the given disk block number.
;
; Arguments
; BC    - block number
; E     - bit to set
SET_DISK_ALLOCATION_BIT:
    d25c  d5         PUSH DE                    ; Get the map entry that correspond the disk block
    d25d  cd 35 d2   CALL GET_DISK_ALLOCATION_BIT (d235)
    
    d260  e6 fe      ANI A, fe                  ; Clear the bit
    d262  c1         POP BC

    d263  b1         ORA C                      ; And set the requested one

STORE_DISK_ALLOCATION_BIT:
SET_DISK_ALLOCATION_BIT_LOOP:
    d264  0f         RRC                        ; Restore the map entry bit position
    d265  15         DCR D
    d266  c2 64 d2   JNZ SET_DISK_ALLOCATION_BIT_LOOP (d264)

    d269  77         MOV M, A                   ; Store the map entry
    d26a  c9         RET


; Update disk map
;
; For the given file (current directory entry) the function will go over the file allocation vector,
; and update disk allocation map bits with the given value.
;
; Arguments:
; C - 0x00 or 0x01 to clear or set the allocation map bit
UPDATE_DISK_MAP:
    d26b  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Get the disk map address for the current dir entry
    d26e  11 10 00   LXI DE, 0010
    d271  19         DAD DE

    d272  c5         PUSH BC
    d273  0e 11      MVI C, 11                  ; Size of the map field + 1

UPDATE_DISK_MAP_LOOP:
    d275  d1         POP DE                     ; Recall the argument (bit to set or clear) in E

    d276  0d         DCR C                      ; Continue until all bytes of the map are processed
    d277  c8         RZ

    d278  d5         PUSH DE                    ; Save the argument for the next cycle

    d279  3a dd d9   LDA SINGLE_BYTE_ALLOCATION_MAP (d9dd)  ; Check map contains 1-byte values
    d27c  b7         ORA A
    d27d  ca 88 d2   JZ UPDATE_DISK_MAP_DOUBLE (d288)

    d280  c5         PUSH BC                    ; Load the map record to BC (high byte is 0 for one
    d281  e5         PUSH HL                    ; byte entries)
    d282  4e         MOV C, M
    d283  06 00      MVI B, 00
    d285  c3 8e d2   JMP UPDATE_DISK_MAP_1 (d28e)

UPDATE_DISK_MAP_DOUBLE:
    d288  0d         DCR C                      ; Load the 2 byte map record to BC (for two byte entries)
    d289  c5         PUSH BC
    d28a  4e         MOV C, M
    d28b  23         INX HL
    d28c  46         MOV B, M
    d28d  e5         PUSH HL

UPDATE_DISK_MAP_1:
    d28e  79         MOV A, C                   ; Check if the record is zero
    d28f  b0         ORA B
    d290  ca 9d d2   JZ UPDATE_DISK_MAP_NEXT (d29d)

    d293  2a c6 d9   LHLD DISK_TOTAL_STORAGE_CAPACITY (d9c6)
    d296  7d         MOV A, L                   ; Compare total number of blocks with map record
    d297  91         SUB C
    d298  7c         MOV A, H
    d299  98         SBB B

    d29a  d4 5c d2   CNC SET_DISK_ALLOCATION_BIT (d25c) ; Set the corresponding allocation map bit

UPDATE_DISK_MAP_NEXT:
    d29d  e1         POP HL                     ; Advance to the next record in the map
    d29e  23         INX HL
    d29f  c1         POP BC
    d2a0  c3 75 d2   JMP UPDATE_DISK_MAP_LOOP (d275)



; Initialize the drive, and update all internal data structures.
;
; The function performs the following actions:
; - Clear the disk allocation vector
; - Set bits that correspond to directory entry blocks as allocated
; - Iterate over all files and their extents, mark blocks used by the file as allocated in allocation vector
; - Calculate actual number of directory entries
DISK_INITIALIZE:
    d2a3  2a c6 d9   LHLD DISK_TOTAL_STORAGE_CAPACITY (d9c6); Disk allocation vector size is total number of blocks / 8 + 1
    d2a6  0e 03      MVI C, 03                              ; (one bit per block)
    d2a8  cd ea d0   CALL SHIFT_HL_RIGHT (d0ea)
    d2ab  23         INX HL

    d2ac  44         MOV B, H                   ; Store allocation vector size to BC
    d2ad  4d         MOV C, L

    d2ae  2a bf d9   LHLD DISK_ALLOCATION_VECTOR_PTR (d9bf)
DISK_INITIALIZE_ALLOC_LOOP:
    d2b1  36 00      MVI M, 00                  ; Reset the disk allocation vector with zeros
    d2b3  23         INX HL
    d2b4  0b         DCX BC
    d2b5  78         MOV A, B
    d2b6  b1         ORA C
    d2b7  c2 b1 d2   JNZ DISK_INITIALIZE_ALLOC_LOOP (d2b1)

    d2ba  2a ca d9   LHLD DISK_RESERVED_DIRECTORY_BLOCKS (d9ca)
    d2bd  eb         XCHG                       ; Load reserved directory blocks number to DE

    d2be  2a bf d9   LHLD DISK_ALLOCATION_VECTOR_PTR (d9bf)
    d2c1  73         MOV M, E                   ; Apply directory block map to the disk allocation vector
    d2c2  23         INX HL
    d2c3  72         MOV M, D

    d2c4  cd a1 cf   CALL SET_TRACK_ZERO (cfa1) ; Move to track #0, zero track/sector numbers

    d2c7  2a b3 d9   LHLD LAST_DIR_ENTRY_NUM_ADDR (d9b3)    ; Store 0003 as a last directory entry number
    d2ca  36 03      MVI M, 03                              ; (one sector. This will be updated later)
    d2cc  23         INX HL
    d2cd  36 00      MVI M, 00

    d2cf  cd fe d1   CALL RESET_DIRECTORY_COUNTER (d1fe); reset directory entries counter

DISK_INITIALIZE_NEXT_FILE:
    d2d2  0e ff      MVI C, ff                  ; Initialize CRC vectory by reading all directory entries
    d2d4  cd 05 d2   CALL GET_NEXT_DIR_ENTRY (d205)

    d2d7  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)
    d2da  c8         RZ                         ; Return when reached the end of the directory

    d2db  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Get the directory entry address to HL

    d2de  3e e5      MVI A, e5                  ; Check if the entry starts with 0xe5 (empty record)
    d2e0  be         CMP M
    d2e1  ca d2 d2   JZ DISK_INITIALIZE_NEXT_FILE (d2d2); If yes - advance to the next record

    d2e4  3a 41 cf   LDA USER_CODE (cf41)       ; Check if the entry starts with the user code
    d2e7  be         CMP M
    d2e8  c2 f6 d2   JNZ DISK_INITIALIZE_1 (d2f6)

    d2eb  23         INX HL                     ; Advance to the file name field
    d2ec  7e         MOV A, M                   ; Check if file name starts with '$' symbol
    d2ed  d6 24      SUI A, 24
    d2ef  c2 f6 d2   JNZ DISK_INITIALIZE_1 (d2f6)

    d2f2  3d         DCR A                      ; Files that start with '$' cause error condition
    d2f3  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)

DISK_INITIALIZE_1:
    d2f6  0e 01      MVI C, 01                  ; Update the disk map, by setting bits in the allocation map
    d2f8  cd 6b d2   CALL UPDATE_DISK_MAP (d26b)

    d2fb  cd 8c d1   CALL UPDATE_LAST_DIR_ENTRY_NUMBER (d18c)   ; Update the entries counter
    d2fe  c3 d2 d2   JMP DISK_INITIALIZE_NEXT_FILE (d2d2)



; Return 0xff if file was not found, or index of the directory entry on current directory sector
RETURN_DIRECTORY_CODE:
    d301  3a d4 d9   LDA SEARCH_IN_PROGRESS (d9d4)  ; Return error if file not found
    d304  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Compare and match extent bytes of FCB and directory entry
;
; Arguments:
; A - extent byte of the FCB
; C - extent byte of the directory entry
;
; Return:
; Zero flag if entries match
MATCH_EXTENT_BYTE:
    d307  c5         PUSH BC
    d308  f5         PUSH PSW

    d309  3a c5 d9   LDA DISK_EXTENT_MASK (d9c5); Extent mask is stored negated. Negate it back
    d30c  2f         CMA
    d30d  47         MOV B, A

    d30e  79         MOV A, C                   ; Apply the mask to the dir entry's extent number
    d30f  a0         ANA B
    d310  4f         MOV C, A

    d311  f1         POP PSW
    d312  a0         ANA B                      ; Apply the mask to the FCB's extent number

    d313  91         SUB C                      ; Compare the numbers (low 5 bits)
    d314  e6 1f      ANI A, 1f

    d316  c1         POP BC
    d317  c9         RET



; Search for a directory entry, that matches a pattern in FCB
;
; Arguments:
; DE - pointer to FCB
; C - number of bytes to match
;
; The function iterates over the directory entries, and compares them with FCB byte-by-byte. The '?' is
; respected during the match, so that a particular symbol is skipped for match.
;
; The function ignores the byte with offset 0x0d (S1 byte) during match. And matching thr extent number
; byte (offset 0x0c) is performed according to the extent mask applied for the drive.
; 
; Returns:
; A = 0xff if not matches found, or 0x00 if there was a match
;
; Also, in case of match, the function loads the directory entry sector, and sets FUNCTION_RETURN_VALUE to 
; the record number of the entry on this sector, that corresponds to the found file
SEARCH_FIRST:
    d318  3e ff      MVI A, ff                  ; Set the Search in progress flag
    d31a  32 d4 d9   STA SEARCH_IN_PROGRESS (d9d4)

    d31d  21 d8 d9   LXI HL, NUM_BYTES_TO_MATCH (d9d8)  ; Remember the number of bytes to match for 
    d320  71         MOV M, C                           ; SEARCH_NEXT calls

    d321  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Store pointer to FCB to be used in SEARCH_NEXT calls
    d324  22 d9 d9   SHLD CURRENT_SEARCH_FCB (d9d9)

    d327  cd fe d1   CALL RESET_DIRECTORY_COUNTER (d1fe); Prepare for iterating over directory entries
    d32a  cd a1 cf   CALL SET_TRACK_ZERO (cfa1)

SEARCH_NEXT:
    d32d  0e 00      MVI C, 00                  ; Get next entry, check CRC (not update)
    d32f  cd 05 d2   CALL GET_NEXT_DIR_ENTRY (d205)

    d332  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)   ; Have we reached the end of directory?
    d335  ca 94 d3   JZ SEARCH_NEXT_NO_MORE_ENTRIES (d394)

    d338  2a d9 d9   LHLD CURRENT_SEARCH_FCB (d9d9) ; Restore the FCB pointer, load it to DE
    d33b  eb         XCHG

    d33c  1a         LDAX DE                    ; Load the first byte of the FCB
    
    d33d  fe e5      CPI A, e5                  ; This allows matching empty directory entries
    d33f  ca 4a d3   JZ SEARCH_NEXT_1 (d34a)

    d342  d5         PUSH DE                    ; Check if we reached the end of the directory
    d343  cd 7f d1   CALL CMP_DIR_COUNTER_WITH_MAX (d17f)
    d346  d1         POP DE
    d347  d2 94 d3   JNC SEARCH_NEXT_NO_MORE_ENTRIES (d394)

SEARCH_NEXT_1:
    d34a  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Get the entry address

    d34d  3a d8 d9   LDA NUM_BYTES_TO_MATCH (d9d8)  ; Load the number of bytes to match, store in C
    d350  4f         MOV C, A
    d351  06 00      MVI B, 00                  ; Reset bytes counter (offset)

SEARCH_NEXT_SYMBOL_LOOP:
    d353  79         MOV A, C                   ; Check if all bytes are matched (and match still did
    d354  b7         ORA A                      ; not fail) - exit with success
    d355  ca 83 d3   JZ SEARCH_MATCHED (d383)

    d358  1a         LDAX DE                    ; If the search mask contains '?' - match any symbol
    d359  fe 3f      CPI A, 3f                  ; which technically means we can advance to the next char
    d35b  ca 7c d3   JZ SEARCH_NEXT_ADVANCE (d37c)

    d35e  78         MOV A, B                   ; S1 byte does not participate in match - skip it
    d35f  fe 0d      CPI A, 0d
    d361  ca 7c d3   JZ SEARCH_NEXT_ADVANCE (d37c)

    d364  fe 0c      CPI A, 0c                  ; Compare extent byte separately
    d366  1a         LDAX DE                    ; Load FCB extent byte
    d367  ca 73 d3   JZ SEARCH_NEXT_COMPARE_EXTENT (d373)

    d36a  96         SUB M                      ; Compare symbols, but mask (ignore) the MSB which may
    d36b  e6 7f      ANI A, 7f                  ; contain R/O and sys flags for the file
    d36d  c2 2d d3   JNZ SEARCH_NEXT (d32d)     ; If not matched - advance to the next directory entry

    d370  c3 7c d3   JMP SEARCH_NEXT_ADVANCE (d37c) ; Current characters match. Advance to the next char.

SEARCH_NEXT_COMPARE_EXTENT:
    d373  c5         PUSH BC
    d374  4e         MOV C, M
    d375  cd 07 d3   CALL MATCH_EXTENT_BYTE (d307)  ; Extent byte is matched in a separate function
    d378  c1         POP BC
    d379  c2 2d d3   JNZ SEARCH_NEXT (d32d)

SEARCH_NEXT_ADVANCE:
    d37c  13         INX DE                     ; Advance to the next char in FCB and directory entry
    d37d  23         INX HL

    d37e  04         INR B                      ; Increment dir entry offset
    d37f  0d         DCR C                      ; Decrement characters counter

    d380  c3 53 d3   JMP SEARCH_NEXT_SYMBOL_LOOP  (d353)

SEARCH_MATCHED:
    d383  3a ea d9   LDA DIRECTORY_COUNTER (d9ea)   ; Return the index of the directory entry within the
    d386  e6 03      ANI A, 03                      ; current directory sector
    d388  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)

    d38b  21 d4 d9   LXI HL, SEARCH_IN_PROGRESS (d9d4)  ; Return if file was found previously
    d38e  7e         MOV A, M
    d38f  17         RAL
    d390  d0         RNC

    d391  af         XRA A                      ; File matched, clear the search in progress flag
    d392  77         MOV M, A
    d393  c9         RET


SEARCH_NEXT_NO_MORE_ENTRIES:
    d394  cd fe d1   CALL RESET_DIRECTORY_COUNTER (d1fe)    ; Reset the counter
    d397  3e ff      MVI A, ff                  ; And report that no more entries left
    d399  c3 01 cf   JMP FUNCTION_EXIT (cf01)



; Delete the file
;
; Arguments:
; DE - Pointer to FCB with file mask
DELETE_FILE:
    d39c  cd 54 d1   CALL CHECK_DISK_READ_ONLY (d154)   ; Can't do anything on the read only disk

    d39f  0e 0c      MVI C, 0c                  ; Search for file that matches the name pattern (0x0c bytes)
    d3a1  cd 18 d3   CALL SEARCH_FIRST (d318)

DELETE_FILE_LOOP:
    d3a4  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)
    d3a7  c8         RZ                         ; Return if all file were processed

    d3a8  cd 44 d1   CALL CHECK_FILE_READ_ONLY (d144)   ; Can't delete the file if it is read only

    d3ab  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Calculate directory entry address
    d3ae  36 e5      MVI M, e5                  ; and mark it's first byte as 0xe5 (empty record)

    d3b0  0e 00      MVI C, 00                  ; Clear allocation bits for blocks of the file
    d3b2  cd 6b d2   CALL UPDATE_DISK_MAP (d26b)

    d3b5  cd c6 d1   CALL WRITE_DIRECTORY_SECTOR (d1c6) ; Flush the directory changes

    d3b8  cd 2d d3   CALL SEARCH_NEXT (d32d)    ; Repeat for the next entry
    d3bb  c3 a4 d3   JMP DELETE_FILE_LOOP (d3a4)



; Search available block left and right
;
; This block searches for an empty block, and return its position. The function also sets the allocation
; bit for the found block, marking the block allocated.
;
; The function does its work in a pretty interesting way - it searches in both left and right direction, 
; until block number 0 is reached at the left, or total number of blocks reached on the right.
;
; Arguments:
; BC - Start block number
;
; Return:
; HL - Available block number
SEARCH_AVAILABLE_BLOCK:
    d3be  50         MOV D, B                   ; Move BC to DE. BC will search for a block to the left,
    d3bf  59         MOV E, C                   ; while DE will be used for the search to the right

SEARCH_AVAILABLE_BLOCK_LEFT:
    d3c0  79         MOV A, C                   ; Check if BC is zero (we reached the left border)
    d3c1  b0         ORA B
    d3c2  ca d1 d3   JZ SEARCH_AVAILABLE_BLOCK_RIGHT (d3d1)

    d3c5  0b         DCX BC                     ; Decrement the left block number

    d3c6  d5         PUSH DE                    ; Search if the block to the left is not allocated
    d3c7  c5         PUSH BC
    d3c8  cd 35 d2   CALL GET_DISK_ALLOCATION_BIT (d235)
    d3cb  1f         RAR
    d3cc  d2 ec d3   JNC SEARCH_AVAILABLE_BLOCK_FOUND (d3ec); If block is empty - allocate it
    d3cf  c1         POP BC
    d3d0  d1         POP DE

SEARCH_AVAILABLE_BLOCK_RIGHT:
    d3d1  2a c6 d9   LHLD DISK_TOTAL_STORAGE_CAPACITY (d9c6); Check if we have any empty blocks (is requested
    d3d4  7b         MOV A, E                               ; block number >= total number of blocks?)
    d3d5  95         SUB L
    d3d6  7a         MOV A, D
    d3d7  9c         SBB H

    d3d8  d2 f4 d3   JNC SEARCH_AVAILABLE_NEXT (d3f4)   ; If reached - try moving left or exit with error

    d3db  13         INX DE                     ; Try moving right
    d3dc  c5         PUSH BC
    d3dd  d5         PUSH DE

    d3de  42         MOV B, D                   ; Get allocation for that block
    d3df  4b         MOV C, E
    d3e0  cd 35 d2   CALL GET_DISK_ALLOCATION_BIT (d235)

    d3e3  1f         RAR                        ; Check the allocation bit
    d3e4  d2 ec d3   JNC SEARCH_AVAILABLE_BLOCK_FOUND (d3ec)

    d3e7  d1         POP DE                     ; This block is allocated, try another one
    d3e8  c1         POP BC
    d3e9  c3 c0 d3   JMP SEARCH_AVAILABLE_BLOCK_LEFT (d3c0)

SEARCH_AVAILABLE_BLOCK_FOUND:
    d3ec  17         RAL                        ; This block is not allocated - allocate it
    d3ed  3c         INR A                      ; Set the allocation bit and store in the allocation vector
    d3ee  cd 64 d2   CALL STORE_DISK_ALLOCATION_BIT (d264)
    d3f1  e1         POP HL
    d3f2  d1         POP DE
    d3f3  c9         RET                        ; And exit

SEARCH_AVAILABLE_NEXT:
    d3f4  79         MOV A, C                   ; We can move right, but perhaps we still can move left 
    d3f5  b0         ORA B                      
    d3f6  c2 c0 d3   JNZ SEARCH_AVAILABLE_BLOCK_LEFT (d3c0)

    d3f9  21 00 00   LXI HL, 0000               ; No luck - return zero, indicating no available block found
    d3fc  c9         RET


; Copy the FCB to the selected directory entry, then update the corresponding sector
COPY_FCB_TO_DIR:
    d3fd  0e 00      MVI C, 00                  ; Will copy from start of the FCB

    d3ff  1e 20      MVI E, 20                  ; Size of the entry to copy

; Copy E bytes of FCB starting from C offset to the directory entry, then update corresponding dir sector
COPY_DIR_ENTRY:
    d401  d5         PUSH DE
    d402  06 00      MVI B, 00                  ; Add the offset to the FCB address
    d404  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
    d407  09         DAD BC
    d408  eb         XCHG

    d409  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Get the directory entry address
    d40c  c1         POP BC

    d40d  cd 4f cf   CALL MEMCOPY_DE_HL (cf4f)  ; Copy FCB to the directory entry

FLUSH_DIR_SECTOR:
    d410  cd c3 cf   CALL SEEK_TO_DIR_ENTRY (cfc3)  ; Seek to the directory entry sector
    d413  c3 c6 d1   JMP WRITE_DIRECTORY_SECTOR (d1c6)  ; And update with the new data


; Rename file
;
; Argument:
; DE - pointer to FCB, where first 0x10 bytes represent old name, and next 0x10 bytes for the new name
RENAME_FILE:
    d416  cd 54 d1   CALL CHECK_DISK_READ_ONLY (d154)   ; Fail if disk is read only

    d419  0e 0c      MVI C, 0c                  ; Search for the file entry (matching only name, 0x0c bytes)
    d41b  cd 18 d3   CALL SEARCH_FIRST (d318)

    d41e  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Load disk code for the source file name
    d421  7e         MOV A, M

    d422  11 10 00   LXI DE, 0010               ; Copy disk code to the target file name
    d425  19         DAD DE
    d426  77         MOV M, A

RENAME_FILE_LOOP:
    d427  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)
    d42a  c8         RZ                         ; Exit if no file found, or all entries processed

    d42b  cd 44 d1   CALL CHECK_FILE_READ_ONLY (d144)

    d42e  0e 10      MVI C, 10                  ; Copy 12 bytes of the new name to the directory entry
    d430  1e 0c      MVI E, 0c
    d432  cd 01 d4   CALL COPY_DIR_ENTRY (d401)

    d435  cd 2d d3   CALL SEARCH_NEXT (d32d)    ; Update all similar entries
    d438  c3 27 d4   JMP RENAME_FILE_LOOP (d427)


; Set file attributes
;
; The function copies file attributes (high bits of each name or extension byte) from FCB to the
; directory entry.
SET_FILE_ATTRS:
    d43b  0e 0c      MVI C, 0c                  ; Search for the file
    d43d  cd 18 d3   CALL SEARCH_FIRST (d318)

SET_FILE_ATTRS_LOOP:
    d440  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)   ; Continue until all directory entries processed
    d443  c8         RZ

    d444  0e 00      MVI C, 00                  ; Copy data from FCB to the directory entry (all MSB flags
    d446  1e 0c      MVI E, 0c                  ; on top of name and extension bytes)
    d448  cd 01 d4   CALL COPY_DIR_ENTRY (d401)

    d44b  cd 2d d3   CALL SEARCH_NEXT (d32d)    ; Advance to the next entry
    d44e  c3 40 d4   JMP SET_FILE_ATTRS_LOOP (d440)


; Open existing file
;
; The function search a directory entry that matches provided FCB, and updates FCB with allocation
; information, records count, and other fields stored in the directory entry.
OPEN_FILE:
    d451  0e 0f      MVI C, 0f
    d453  cd 18 d3   CALL SEARCH_FIRST (d318)
    d456  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)
    d459  c8         RZ


; Update FCB for next extent
;
; The function resets FCB with the directory entry data, but keep the extent number and record counter.
; This is needed to load next extent of the same file to FCB. If the extent has changed, record counter
; is reset.
UPDATE_FCB_FOR_NEXT_EXTENT:
    d45a  cd a6 d0   CALL GET_FCB_EXTENT_NUMBER (d0a6)  ; Load extent number from FCB and save it for later
    d45d  7e         MOV A, M
    d45e  f5         PUSH PSW                   
    d45f  e5         PUSH HL

    d460  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Get directory entry address to DE
    d463  eb         XCHG

    d464  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Load FCB address to HL

    d467  0e 20      MVI C, 20                  ; Copy directory entry to FCB
    d469  d5         PUSH DE
    d46a  cd 4f cf   CALL MEMCOPY_DE_HL (cf4f)

    d46d  cd 78 d1   CALL SET_FILE_WRITE_FLAG (d178); Set the file write mode

    d470  d1         POP DE                     ; Load extent number from the directory entry to C
    d471  21 0c 00   LXI HL, 000c
    d474  19         DAD DE
    d475  4e         MOV C, M

    d476  21 0f 00   LXI HL, 000f               ; Load records counter from the directory entry to B
    d479  19         DAD DE
    d47a  46         MOV B, M

    d47b  e1         POP HL                     ; Restore extent number in the FCB
    d47c  f1         POP PSW
    d47d  77         MOV M, A

    d47e  79         MOV A, C                   ; Compare FCB extent number with directory entry one
    d47f  be         CMP M

    d480  78         MOV A, B                   ; Load the record counter
    d481  ca 8b d4   JZ UPDATE_FCB_FOR_NEXT_EXTENT_1 (d48b)

    d484  3e 00      MVI A, 00                  ; If extent numbers do not match, reset the record counter
    d486  da 8b d4   JC UPDATE_FCB_FOR_NEXT_EXTENT_1 (d48b) ; for the new extent

    d489  3e 80      MVI A, 80                  ; Limit record counter with 0x80

UPDATE_FCB_FOR_NEXT_EXTENT_1:
    d48b  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Store the updated record counter
    d48e  11 0f 00   LXI DE, 000f
    d491  19         DAD DE
    d492  77         MOV M, A

    d493  c9         RET


; Merge non-zero disk allocation entries
;
; Check if [HL] is zero, and if it is copy word from [DE] to [HL]
MERGE_ALLOC_ENTRIES:
    d494  7e         MOV A, M                   ; Compare word at [HL] with zero
    d495  23         INX HL
    d496  b6         ORA M
    d497  2b         DCX HL
    d498  c0         RNZ                        ; return if not zero

    d499  1a         LDAX DE                    ; Copy word from [DE] to [HL]
    d49a  77         MOV M, A
    d49b  13         INX DE
    d49c  23         INX HL
    d49d  1a         LDAX DE
    d49e  77         MOV M, A
    d49f  1b         DCX DE
    d4a0  2b         DCX HL
    d4a1  c9         RET


; Close file
;
; Function algorithm:
; - Check file write flag
; - Find the directory entry that matches current FCB
; - Merge FCB and directory entry allocation records (1- or 2-byte records supported)
; - Update extent number and record counter from FCB to directory entry
; - Flush the directory entry to disk
CLOSE_FILE:
    d4a2  af         XRA A                      ; Clear return value
    d4a3  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)

    d4a6  32 ea d9   STA DIRECTORY_COUNTER (d9ea)   ; Clear directory counter

    d4a9  32 eb d9   STA d9eb                   ; ?????

    d4ac  cd 1e d1   CALL IS_DISK_READ_ONLY (d11e)  ; Can't proceed if the disk is read only
    d4af  c0         RNZ

    d4b0  cd 69 d1   CALL GET_FCB_EXT_NUM_HIGH (d169)   ; Do not close the file if it has unwritten entries
    d4b3  e6 80      ANI A, 80
    d4b5  c0         RNZ

    d4b6  0e 0f      MVI C, 0f                  ; Search for directory entry that exactly (0xf bytes)
    d4b8  cd 18 d3   CALL SEARCH_FIRST (d318)   ; matches the FCB

    d4bb  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)   ; Return if the entry was not found
    d4be  c8         RZ

    d4bf  01 10 00   LXI BC, 0010               ; Calculate the pointer to allocation vector of the entry
    d4c2  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e)
    d4c5  09         DAD BC
    d4c6  eb         XCHG                       ; Move to DE

    d4c7  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Calculate similar pointer in the FCB, load to HL
    d4ca  09         DAD BC
    d4cb  0e 10      MVI C, 10                  ; allocation entries count

CLOSE_FILE_MERGE_ALLOC_LOOP:
    d4cd  3a dd d9   LDA SINGLE_BYTE_ALLOCATION_MAP (d9dd)
    d4d0  b7         ORA A                      ; Check if single-byte allocation entries used
    d4d1  ca e8 d4   JZ CLOSE_FILE_MERGE_2B_ALLOC (d4e8)

    d4d4  7e         MOV A, M                   ; Merge non-zero allocation records between FCB ([HL]) and
    d4d5  b7         ORA A                      ; directory entry ([DE])
    d4d6  1a         LDAX DE
    d4d7  c2 db d4   JNZ CLOSE_FILE_MERGE_ALLOC_1 (d4db)
    d4da  77         MOV M, A                   ; record at [HL] is empty - copy from [DE]

CLOSE_FILE_MERGE_ALLOC_1:
    d4db  b7         ORA A                      ; Record ad [DE] is empty - copy from [HL]
    d4dc  c2 e1 d4   JNZ CLOSE_FILE_MERGE_ALLOC_2 (d4e1)
    d4df  7e         MOV A, M
    d4e0  12         STAX DE

CLOSE_FILE_MERGE_ALLOC_2:
    d4e1  be         CMP M                      ; Check the merge error ([HL] != [DE])
    d4e2  c2 1f d5   JNZ CLOSE_FILE_MERGE_ALLOC_ERROR (d51f)

    d4e5  c3 fd d4   JMP CLOSE_FILE_MERGE_ALLOC_NEXT (d4fd) ; Advance to the next record

CLOSE_FILE_MERGE_2B_ALLOC:
    d4e8  cd 94 d4   CALL MERGE_ALLOC_ENTRIES (d494); Merge non-zero 2-byte allocation records in FCB and
    d4eb  eb         XCHG                           ; directory entry
    d4ec  cd 94 d4   CALL MERGE_ALLOC_ENTRIES (d494)
    d4ef  eb         XCHG

    d4f0  1a         LDAX DE                    ; Check the merge error  ([HL] != [DE])
    d4f1  be         CMP M
    d4f2  c2 1f d5   JNZ CLOSE_FILE_MERGE_ALLOC_ERROR (d51f)

    d4f5  13         INX DE                     ; Check the second byte for the merge error condition
    d4f6  23         INX HL
    d4f7  1a         LDAX DE
    d4f8  be         CMP M
    d4f9  c2 1f d5   JNZ CLOSE_FILE_MERGE_ALLOC_ERROR (d51f)

    d4fc  0d         DCR C                      ; We are working with 2-byte records - advance C twice faster

CLOSE_FILE_MERGE_ALLOC_NEXT:
    d4fd  13         INX DE                     ; Advance to the next allocation record
    d4fe  23         INX HL
    d4ff  0d         DCR C                      ; Check if we are done
    d500  c2 cd d4   JNZ CLOSE_FILE_MERGE_ALLOC_LOOP (d4cd)

    d503  01 ec ff   LXI BC, ffec               ; Move pointer to -0x14 bytes (to extent number at 0x0c offset)
    d506  09         DAD BC
    d507  eb         XCHG

    d508  09         DAD BC                     ; Same for FCB pointer

    d509  1a         LDAX DE                    ; Load extent number from FCB to A

    d50a  be         CMP M                      ; Compare extent numbers with one in directory entry
    d50b  da 17 d5   JC CLOSE_FILE_MERGE_ALLOC_EXIT (d517)

    d50e  77         MOV M, A                   ; Update the extent number in the directory entry

    d50f  01 03 00   LXI BC, 0003               ; Advance pointers to the record counter
    d512  09         DAD BC
    d513  eb         XCHG
    d514  09         DAD BC                     

    d515  7e         MOV A, M                   ; Copy from record counter from FCB to directory entry
    d516  12         STAX DE

CLOSE_FILE_MERGE_ALLOC_EXIT:
    d517  3e ff      MVI A, ff                  ; Set the flag that FCB has been flushed to directory entry
    d519  32 d2 d9   STA FCB_COPIED_TO_DIR (d9d2)

    d51c  c3 10 d4   JMP FLUSH_DIR_SECTOR (d410); Update the data on disk

CLOSE_FILE_MERGE_ALLOC_ERROR:
    d51f  21 45 cf   LXI HL, FUNCTION_RETURN_VALUE (cf45)   ; Return an error (0xff)
    d522  35         DCR M
    d523  c9         RET


; Create a file, name in FCB
;
; The function algorithm:
; - search for an empty directory entry (one that starts with 0xe5 byte)
; - Clear allocation data in the FCB (bytes 0x0f-0x1f)
; - Stores the FCB in the directory sector
CREATE_FILE:
    d524  cd 54 d1   CALL CHECK_DISK_READ_ONLY (d154)   ; Check if operation is possible

    d527  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)     ; Load the pointer to FCB
    d52a  e5         PUSH HL

    d52b  21 ac d9   LXI HL, EMPTY_ENTRY_SIGNATURE (d9ac)   ; Search for an emtpy directory entry
    d52e  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)

    d531  0e 01      MVI C, 01                          ; Will match only empty entry signature (1 byte)
    d533  cd 18 d3   CALL SEARCH_FIRST (d318)

    d536  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)   ; Reached end of the directory? no empty slots

    d539  e1         POP HL                             ; Restore and save FCB address
    d53a  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)     

    d53d  c8         RZ                         ; Return if no empty slots found

    d53e  eb         XCHG                       ; Calculate pointer to the record count of the extent
    d53f  21 0f 00   LXI HL, 000f
    d542  19         DAD DE

    d543  0e 11      MVI C, 11                  ; Clear 17 bytes of the record (bytes 0x0f - 0x1f)
    d545  af         XRA A

CREATE_FILE_CLEAR_LOOP:
    d546  77         MOV M, A                   ; Clear the next byte
    d547  23         INX HL
    d548  0d         DCR C
    d549  c2 46 d5   JNZ CREATE_FILE_CLEAR_LOOP (d546)

    d54c  21 0d 00   LXI HL, 000d               ; Clear also S1 byte
    d54f  19         DAD DE
    d550  77         MOV M, A

    d551  cd 8c d1   CALL UPDATE_LAST_DIR_ENTRY_NUMBER (d18c)   ; Update the entries counter

    d554  cd fd d3   CALL COPY_FCB_TO_DIR (d3fd); Copy FCB to the directory entry

    d557  c3 78 d1   JMP SET_FILE_WRITE_FLAG (d178) ; Set the write flag




; Advance to the next extent
;
; If all records of the current extent are processed, this function closes the extent, and advances
; to the next one. In case of reading or updating operations the extent must already exist. In case
; of sequental writing, the new extent is created. 
ADVANCE_TO_NEXT_EXTENT:
    d55a  af         XRA A                      ; Indicate FCB needs to be flushed on the disk
    d55b  32 d2 d9   STA FCB_COPIED_TO_DIR (d9d2)

    d55e  cd a2 d4   CALL CLOSE_FILE (d4a2)     ; Close File function will do all the directory update stuff

    d561  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)   ; Check if error has happened during dir update
    d564  c8         RZ

    d565  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Calculate pointer to FCB extent number
    d568  01 0c 00   LXI BC, 000c
    d56b  09         DAD BC

    d56c  7e         MOV A, M                   ; Increment the extent number
    d56d  3c         INR A
    d56e  e6 1f      ANI A, 1f
    d570  77         MOV M, A

    d571  ca 83 d5   JZ ADVANCE_TO_NEXT_EXTENT_1 (d583) ; Check if the maximum extents count reached

    d574  47         MOV B, A                   ; Apply the extent mask
    d575  3a c5 d9   LDA DISK_EXTENT_MASK (d9c5)
    d578  a0         ANA B

    d579  21 d2 d9   LXI HL, FCB_COPIED_TO_DIR (d9d2)   ; Update FCB flushed flag
    d57c  a6         ANA M
    d57d  ca 8e d5   JZ ADVANCE_TO_NEXT_EXTENT_2 (d58e)

    d580  c3 ac d5   JMP ADVANCE_TO_NEXT_EXTENT_3 (d5ac)

ADVANCE_TO_NEXT_EXTENT_1:
    d583  01 02 00   LXI BC, 0002               ; Advance to high byte of the extent number
    d586  09         DAD BC

    d587  34         INR M                      ; Increment extent number high byte until it reaches 0x10
    d588  7e         MOV A, M                   ; (only 4 bits of the byte are used)
    d589  e6 0f      ANI A, 0f
    d58b  ca b6 d5   JZ ADVANCE_TO_NEXT_EXTENT_EXIT_ERROR (d5b6)

ADVANCE_TO_NEXT_EXTENT_2:
    d58e  0e 0f      MVI C, 0f                  ; Search if there is directory entry for next extent already
    d590  cd 18 d3   CALL SEARCH_FIRST (d318)

    d593  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)
    d596  c2 ac d5   JNZ ADVANCE_TO_NEXT_EXTENT_3 (d5ac); Create new one of needed

    d599  3a d3 d9   LDA READ_OR_WRITE (d9d3)   ; Are we reading or writing?
    d59c  3c         INR A
    d59d  ca b6 d5   JZ ADVANCE_TO_NEXT_EXTENT_EXIT_ERROR (d5b6)

    ; We are writing
    d5a0  cd 24 d5   CALL CREATE_FILE (d524)    ; Creating the new extent technically means creating a file

    d5a3  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)   ; No directory entries left?
    d5a6  ca b6 d5   JZ ADVANCE_TO_NEXT_EXTENT_EXIT_ERROR (d5b6)

    d5a9  c3 af d5   JMP ADVANCE_TO_NEXT_EXTENT_EXIT (d5af)

ADVANCE_TO_NEXT_EXTENT_3:
    d5ac  cd 5a d4   CALL UPDATE_FCB_FOR_NEXT_EXTENT (d45a) ; Update FCB, load the new extent if needed

ADVANCE_TO_NEXT_EXTENT_EXIT:
    d5af  cd bb d0   CALL LOAD_RECORDS_COUNT (d0bb) ; Update records counters

    d5b2  af         XRA A                      ; Exit normally
    d5b3  c3 01 cf   JMP FUNCTION_EXIT (cf01)

ADVANCE_TO_NEXT_EXTENT_EXIT_ERROR:
    d5b6  cd 05 cf   CALL EXIT_WITH_ERROR (cf05); Exit with error
    d5b9  c3 78 d1   JMP SET_FILE_WRITE_FLAG (d178) ; Indicate that entry is not valid




; Read file in a sequental manner
;
; Arguments:
; DE - Pointer to FCB
READ_SEQUENTAL:
    d5bc  3e 01      MVI A, 01                  ; Mark the operation as sequental
    d5be  32 d5 d9   STA SEQUENTAL_OPERATION (d9d5)

DISK_READ:
    d5c1  3e ff      MVI A, ff                  ; Mark the operation as read operation
    d5c3  32 d3 d9   STA READ_OR_WRITE (d9d3)

    d5c6  cd bb d0   CALL LOAD_RECORDS_COUNT (d0bb) ; Load record counters

    d5c9  3a e3 d9   LDA CURRENT_RECORD_INDEX (d9e3); Check if the current record is within current extent
    d5cc  21 e1 d9   LXI HL, TOTAL_EXTENT_RECORDS (d9e1)
    d5cf  be         CMP M
    d5d0  da e6 d5   JC DISK_READ_1 (d5e6)

    d5d3  fe 80      CPI A, 80                      ; Check if we reached maximum records for extent
    d5d5  c2 fb d5   JNZ READ_FILE_ERROR (d5fb)

    d5d8  cd 5a d5   CALL ADVANCE_TO_NEXT_EXTENT (d55a) ; Current extent is over, advance to the next one

    d5db  af         XRA A                          ; Will start from record 0 in the next extent
    d5dc  32 e3 d9   STA CURRENT_RECORD_INDEX (d9e3)

    d5df  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)   ; Check if there were errors already
    d5e2  b7         ORA A
    d5e3  c2 fb d5   JNZ READ_FILE_ERROR (d5fb)

DISK_READ_1:
    d5e6  cd 77 d0   CALL CALC_BLOCK_NUMBER (d077)  ; Calculate block number based on the record number

    d5e9  cd 84 d0   CALL IS_BLOCK_ZERO (d084)      ; Zero block number indicates an error
    d5ec  ca fb d5   JZ READ_FILE_ERROR (d5fb)

    d5ef  cd 8a d0   CALL CALC_SECTOR_NUMBER (d08a) ; Calculate sector number based on block and record number

    d5f2  cd d1 cf   CALL SEEK_TO_SECTOR (cfd1)     ; Read the desired sector
    d5f5  cd b2 cf   CALL READ_SECTOR (cfb2)

    d5f8  c3 d2 d0   JMP UPDATE_RECORD_COUNTER (d0d2)   ; Advance to the next record and exit normally

READ_FILE_ERROR:
    d5fb  c3 05 cf   JMP EXIT_WITH_ERROR (cf05)




; Write data sector
;
; Write the data previously stored to the data buffer. Data is written to the previously opened file. 
; The function supports 3 modes of writing data (mode is stored in SEQUENTAL_OPERATION variable):
; Mode 0 - random access write - data is written to the previously specified sector
; Mode 1 - sequental write - data is written to a sector selected with the record counter (incremented after
;          each write operation, so that next call of the function will write to the next sector)
; Mode 2 - random access write with clearing blocks. Unlike Mode 0 where write operation overwrites the
;          data leaving other sectors of the block intact, Mode 2 will zero all sectors in written block first
; 
; Overall, write operation is performed at multiple stages:
; - Calculate block number for the desired sector (selected for random access write, or the next record in 
;   sequental writing mode)
; - If the operation expects to start a new block, the function searches for an empty (unallocated) block,
;   Preferably close to the previous one. If the mode 2 is used, the new block is zeroed first.
;   - Since the function starts a new block, disk allocation map is updated accordingly
; - No extra actions needed if writing a sector within previously allocated block. The function just
;   calculates the actual sector number within the block, and write data buffer.
; - Finally, the function increments record counter for sequental write operation. If the current extent 
;   is full and no more records can fit the extent, a new extent is crteated (with the same name, but
;   incremented extent number)
WRITE_SEQUENTAL:
    d5fe  3e 01      MVI A, 01                  ; Set mode, indicating sequental read/write op
    d600  32 d5 d9   STA SEQUENTAL_OPERATION (d9d5)

DISK_WRITE:
    d603  3e 00      MVI A, 00                  ; This will be a write operation
    d605  32 d3 d9   STA READ_OR_WRITE (d9d3)

    d608  cd 54 d1   CALL CHECK_DISK_READ_ONLY (d154)   ; Can't write on a read only disk

    d60b  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Can't also write to a read only file
    d60e  cd 47 d1   CALL CHECK_FILE_READ_ONLY_FLAG (d147)

    d611  cd bb d0   CALL LOAD_RECORDS_COUNT (d0bb) ; Load record counter variables used below

    d614  3a e3 d9   LDA CURRENT_RECORD_INDEX (d9e3); Check if we record index is over the maximum for extent
    d617  fe 80      CPI A, 80
    d619  d2 05 cf   JNC EXIT_WITH_ERROR (cf05)

    d61c  cd 77 d0   CALL CALC_BLOCK_NUMBER (d077)  ; Get the block number for the current record

    d61f  cd 84 d0   CALL IS_BLOCK_ZERO (d084)      ; Check if the slot in the allocation vector is free.

    d622  0e 00      MVI C, 00                      ; Will use normal write operation
    d624  c2 6e d6   JNZ DISK_WRITE_5 (d66e)        ; for partially allocated blocks

    d627  cd 3e d0   CALL CALC_DISK_MAP_POS (d03e)  ; Get current record block index in FCB alloc vector
    d62a  32 d7 d9   STA CUR_RECORD_BLOCK_INDEX (d9d7)

    d62d  01 00 00   LXI BC, 0000                   ; Check if this is the first write operation
    d630  b7         ORA A                          ; on the file. If yes - set the block number BC=0
    d631  ca 3b d6   JZ DISK_WRITE_1 (d63b)

    d634  4f         MOV C, A                       ; If not - get the block number in BC
    d635  0b         DCX BC                         ; (start searching from the previous block)
    d636  cd 5e d0   CALL GET_BLOCK_NUM_FOR_RECORD (d05e)
    d639  44         MOV B, H
    d63a  4d         MOV C, L

DISK_WRITE_1:
    d63b  cd be d3   CALL SEARCH_AVAILABLE_BLOCK (d3be) ; Search for an available block
    d63e  7d         MOV A, L
    d63f  b4         ORA H
    d640  c2 48 d6   JNZ DISK_WRITE_2 (d648)

    d643  3e 02      MVI A, 02                  ; No available blocks left - exit with error #2
    d645  c3 01 cf   JMP FUNCTION_EXIT (cf01)

DISK_WRITE_2:
    d648  22 e5 d9   SHLD ACTUAL_SECTOR (d9e5)  ; Load block number to DE
    d64b  eb         XCHG

    d64c  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Load FCB allocation vector ptr in HL
    d64f  01 10 00   LXI BC, 0010
    d652  09         DAD BC

    d653  3a dd d9   LDA SINGLE_BYTE_ALLOCATION_MAP (d9dd)  ; Check if allocation vector uses 1-byte records
    d656  b7         ORA A
    d657  3a d7 d9   LDA CUR_RECORD_BLOCK_INDEX (d9d7)  ; Load the allocation vector element index
    d65a  ca 64 d6   JZ DISK_WRITE_3 (d664)

    d65d  cd 64 d1   CALL HL_ADD_A (d164)       ; Load the block number from the allocation vector (1 byte)
    d660  73         MOV M, E
    d661  c3 6c d6   JMP DISK_WRITE_4 (d66c)

DISK_WRITE_3:
    d664  4f         MOV C, A                   ; Load the block number from the allocation vector (2 byte)
    d665  06 00      MVI B, 00
    d667  09         DAD BC
    d668  09         DAD BC
    d669  73         MOV M, E
    d66a  23         INX HL
    d66b  72         MOV M, D

DISK_WRITE_4:
    d66c  0e 02      MVI C, 02                  ; Set unallocated write operation

DISK_WRITE_5:
    d66e  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)   ; Check if previous functions set an error
    d671  b7         ORA A 
    d672  c0         RNZ                        ; If yes - stop execution

    d673  c5         PUSH BC                    ; Calculate the sector number
    d674  cd 8a d0   CALL CALC_SECTOR_NUMBER (d08a)

    d677  3a d5 d9   LDA SEQUENTAL_OPERATION (d9d5) ; Check the operation type
    d67a  3d         DCR A
    d67b  3d         DCR A
    d67c  c2 bb d6   JNZ DISK_WRITE_DATA (d6bb)

    ; Here and below we will be zeroing the block sectors
    d67f  c1         POP BC                     ; Restore write type operation set above
    d680  c5         PUSH BC
    
    d681  79         MOV A, C                   ; Check the write type set above
    d682  3d         DCR A
    d683  3d         DCR A
    d684  c2 bb d6   JNZ DISK_WRITE_DATA (d6bb)

    d687  e5         PUSH HL                    ; Will use directory buffer for clearing unallocated sectors
    d688  2a b9 d9   LHLD DIRECTORY_BUFFER_ADDR (d9b9)

    d68b  57         MOV D, A                   ; Zero bytes counter

DISK_WRITE_ZERO_BUF_LOOP:
    d68c  77         MOV M, A                   ; Fill buffer with zeros
    d68d  23         INX HL
    d68e  14         INR D
    d68f  f2 8c d6   JP DISK_WRITE_ZERO_BUF_LOOP (d68c)

    d692  cd e0 d1   CALL SET_DIR_DISK_BUFFER (d1e0); Prepare for writing zeroed buffer

    d695  2a e7 d9   LHLD BLOCK_FIRST_SECTOR (d9e7) ; Get the number of block first sector

    d698  0e 02      MVI C, 02                  ; ?????
DISK_WRITE_ZERO_BLOCK_LOOP:
    d69a  22 e5 d9   SHLD ACTUAL_SECTOR (d9e5)  ; Seek to the next sector
    d69d  c5         PUSH BC
    d69e  cd d1 cf   CALL SEEK_TO_SECTOR (cfd1)
    d6a1  c1         POP BC

    d6a2  cd b8 cf   CALL WRITE_SECTOR (cfb8)   ; Write the zeroed sector

    d6a5  2a e5 d9   LHLD ACTUAL_SECTOR (d9e5)  ; Get the current sector number
    d6a8  0e 00      MVI C, 00

    d6aa  3a c4 d9   LDA DISK_BLOCK_BLM (d9c4)  ; Load the block mask
    d6ad  47         MOV B, A
    d6ae  a5         ANA L

    d6af  b8         CMP B                      ; Loop while we still within the current block
    d6b0  23         INX HL
    d6b1  c2 9a d6   JNZ DISK_WRITE_ZERO_BLOCK_LOOP (d69a)

    d6b4  e1         POP HL                     ; Restore the data sector number
    d6b5  22 e5 d9   SHLD ACTUAL_SECTOR (d9e5)

    d6b8  cd da d1   CALL SET_DATA_DISK_BUFFER (d1da)   ; Restore the data buffer

    ; Write the actual data
DISK_WRITE_DATA:
    d6bb  cd d1 cf   CALL SEEK_TO_SECTOR (cfd1)     ; Seek to the sector to write

    d6be  c1         POP BC                         ; Write the sector
    d6bf  c5         PUSH BC
    d6c0  cd b8 cf   CALL WRITE_SECTOR (cfb8)

    d6c3  c1         POP BC                         ; Check if record index still fits the extent
    d6c4  3a e3 d9   LDA CURRENT_RECORD_INDEX (d9e3)
    d6c7  21 e1 d9   LXI HL, TOTAL_EXTENT_RECORDS (d9e1)

    d6ca  be         CMP M
    d6cb  da d2 d6   JC DISK_WRITE_6 (d6d2)

    d6ce  77         MOV M, A                       ; If yes, increment the record counter
    d6cf  34         INR M                      

    d6d0  0e 02      MVI C, 02

DISK_WRITE_6:
    d6d2  0d         DCR C                          ; Check if this is a new block operation
    d6d3  0d         DCR C
    d6d4  c2 df d6   JNZ DISK_WRITE_7 (d6df)

    d6d7  f5         PUSH PSW                       ; Clear the file write flag, to indicate that current
    d6d8  cd 69 d1   CALL GET_FCB_EXT_NUM_HIGH (d169)   ; extent has valid data
    d6db  e6 7f      ANI A, 7f
    d6dd  77         MOV M, A
    d6de  f1         POP PSW

DISK_WRITE_7:
    d6df  fe 7f      CPI A, 7f                      ; Check if we reached maximum record count for the extent
    d6e1  c2 00 d7   JNZ DISK_WRITE_9 (d700)

    d6e4  3a d5 d9   LDA SEQUENTAL_OPERATION (d9d5) ; Check if this is a sequental operation
    d6e7  fe 01      CPI A, 01
    d6e9  c2 00 d7   JNZ DISK_WRITE_9 (d700)

    d6ec  cd d2 d0   CALL UPDATE_RECORD_COUNTER (d0d2)  ; Update record counters

    d6ef  cd 5a d5   CALL ADVANCE_TO_NEXT_EXTENT (d55a) ; And advance/create new extent

    d6f2  21 45 cf   LXI HL, FUNCTION_RETURN_VALUE (cf45)   ; Check if an error happened
    d6f5  7e         MOV A, M
    d6f6  b7         ORA A
    d6f7  c2 fe d6   JNZ DISK_WRITE_8 (d6fe)

    d6fa  3d         DCR A                              ; Set 0xff as return code indicating the error
    d6fb  32 e3 d9   STA CURRENT_RECORD_INDEX (d9e3)

DISK_WRITE_8:
    d6fe  36 00      MVI M, 00                          ; Set return code to zero indicating success

DISK_WRITE_9:
    d700  c3 d2 d0   JMP UPDATE_RECORD_COUNTER (d0d2)   ; Update counters and exit


; Select sector for random read or write
;
; Prepare for random access read or write operation. The function parses bytes 0x21-0x23 of the FCB, that
; indicates record index of the file to be read or written. The requested record index is converted to
; a triple of extent high byte, extent low byte, and extent record index parameters. These parameters
; are then written to the FCB. The function also loads needed extent of the file, and reads file allocation
; vector for this extent.
;
; When all actions described above are performed, regular sequental read/write operation may be performed
; next to read/write more than 1 sector of data
;
; Arguments:
; C - operation type (0xff - read, 0x00 - write)
; Bytes 0x21-0x23 of FCB specify file position (in sectors) to read or write
SELECT_FILE_SECTOR:
    d703  af         XRA A                      ; Mark this is a random access operation (not sequental)
    d704  32 d5 d9   STA SEQUENTAL_OPERATION (d9d5)

SELECT_FILE_SECTOR_1:
    d707  c5         PUSH BC                    ; Load FCB pointer to DE
    d708  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
    d70b  eb         XCHG

    d70c  21 21 00   LXI HL, 0021               ; Calculate offset to selected sector numer
    d70f  19         DAD DE

    d710  7e         MOV A, M                   ; record number = sector % 128
    d711  e6 7f      ANI A, 7f
    d713  f5         PUSH PSW

    d714  7e         MOV A, M                   ; Move MSB of the low byte to the high byte
    d715  17         RAL
    d716  23         INX HL
    d717  7e         MOV A, M
    d718  17         RAL

    d719  e6 1f      ANI A, 1f              ; extent number  = (pos high byte << 1 + pos low byte >> 7) & 0x1f
    d71b  4f         MOV C, A               ; ^ this is low byte of extent number. Store block index to C.

    d71c  7e         MOV A, M               ; Extent number high byte = (position high byte >> 4) & 0xf
    d71d  1f         RAR
    d71e  1f         RAR
    d71f  1f         RAR
    d720  1f         RAR
    d721  e6 0f      ANI A, 0f
    d723  47         MOV B, A                   ; Store calculated extent number high byte to B

    d724  f1         POP PSW                    ; Ensure the 3rd byte is zero
    d725  23         INX HL
    d726  6e         MOV L, M
    d727  2c         INR L
    d728  2d         DCR L
    d729  2e 06      MVI L, 06                  ; Error code 06 - seek past end of the disk
    d72b  c2 8b d7   JNZ SELECT_FILE_SECTOR_ERROR_1 (d78b)

    d72e  21 20 00   LXI HL, 0020               ; Store calculated record counter into dedicated FCB field
    d731  19         DAD DE
    d732  77         MOV M, A

    d733  21 0c 00   LXI HL, 000c               ; Load FCB extent number field address
    d736  19         DAD DE

    d737  79         MOV A, C                   ; Compare low byte of extent
    d738  96         SUB M
    d739  c2 47 d7   JNZ SELECT_FILE_SECTOR_2 (d747); If not equal - switch to the new extent

    d73c  21 0e 00   LXI HL, 000e               ; Load address of the extent high byte
    d73f  19         DAD DE

    d740  78         MOV A, B                   ; Compare high byte of extent
    d741  96         SUB M

    d742  e6 7f      ANI A, 7f                  ; No need to switch extent if extent numbers equal
    d744  ca 7f d7   JZ SELECT_FILE_SECTOR_EXIT (d77f)

SELECT_FILE_SECTOR_2:
    d747  c5         PUSH BC                    ; Close previous extent, flush FCB to directory entry
    d748  d5         PUSH DE
    d749  cd a2 d4   CALL CLOSE_FILE (d4a2)
    d74c  d1         POP DE
    d74d  c1         POP BC

    d74e  2e 03      MVI L, 03                  ; Error code 03 - cannot close current extent

    d750  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)   ; Check if there was indeed an error condition
    d753  3c         INR A
    d754  ca 84 d7   JZ SELECT_FILE_SECTOR_ERROR (d784)

    d757  21 0c 00   LXI HL, 000c               ; Store calculated extent number low byte
    d75a  19         DAD DE
    d75b  71         MOV M, C

    d75c  21 0e 00   LXI HL, 000e               ; Store calculated extent number high byte
    d75f  19         DAD DE
    d760  70         MOV M, B

    d761  cd 51 d4   CALL OPEN_FILE (d451)      ; Load the calculated extent (FCB has all the info already)

    d764  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)   ; Check for an error
    d767  3c         INR A
    d768  c2 7f d7   JNZ SELECT_FILE_SECTOR_EXIT (d77f)

    d76b  c1         POP BC
    d76c  c5         PUSH BC
    d76d  2e 04      MVI L, 04                  ; Prepare to 'seek to unwriten position' error

    d76f  0c         INR C                      ; Check if we are in read operation?
    d770  ca 84 d7   JZ SELECT_FILE_SECTOR_ERROR (d784)

    d773  cd 24 d5   CALL CREATE_FILE (d524)    ; Create extent if needed

    d776  2e 05      MVI L, 05                  ; not documented error code ????
    d778  3a 45 cf   LDA FUNCTION_RETURN_VALUE (cf45)   ; Was there an error?
    d77b  3c         INR A
    d77c  ca 84 d7   JZ SELECT_FILE_SECTOR_ERROR (d784)

SELECT_FILE_SECTOR_EXIT:
    d77f  c1         POP BC
    d780  af         XRA A                      ; Exit with zero (success) code
    d781  c3 01 cf   JMP FUNCTION_EXIT (cf01)

SELECT_FILE_SECTOR_ERROR:
    d784  e5         PUSH HL
    d785  cd 69 d1   CALL GET_FCB_EXT_NUM_HIGH (d169)   ; Raise write flag, indicating the error mode, and file
    d788  36 c0      MVI M, c0                          ; cannot be closed
    d78a  e1         POP HL

SELECT_FILE_SECTOR_ERROR_1:
    d78b  c1         POP BC                     ; Set error code from L and exit
    d78c  7d         MOV A, L
    d78d  32 45 cf   STA FUNCTION_RETURN_VALUE (cf45)
    d790  c3 78 d1   JMP SET_FILE_WRITE_FLAG (d178)  ; Raise write flag, so that file can't be closed



; Function 0x21 - Read randomly accessed sector
;
; DE - pointer to the FCB with filled bytes 0x21-0x22 indicating file offset to read
READ_RANDOM:
    d793  0e ff      MVI C, ff
    d795  cd 03 d7   CALL SELECT_FILE_SECTOR (d703)
    d798  cc c1 d5   CZ DISK_READ (d5c1)
    d79b  c9         RET

; Function 0x22 - Write randomly accessed sector
;
; DE - pointer to the FCB with filled bytes 0x21-0x22 indicating file offset to read
WRITE_RANDOM:
    d79c  0e 00      MVI C, 00
    d79e  cd 03 d7   CALL SELECT_FILE_SECTOR (d703)
    d7a1  cc 03 d6   CZ DISK_WRITE (d603)
    d7a4  c9         RET



; Convert FCB (or directory entry) record counter to sector index
;
; This function is intended to convert a triple record counter/extent number/S2 byte into a single
; 16-bit sector index. The function also calculates the overflow, in case if the file occupies more than
; 65k sectors (8Mb). The result is stored into BC for sectors count, and A contains an overflow flag.
;
; The function does is pretty much opposite to SELECT_FILE_SECTOR function.
;
; Arguments:
; HL - directory entry or FCB address
; DE - offset of current record count field (offset 0x0f) or current record index in sequental read/write
; operations (offset 0x20)
;
; Returns:
; A - 0x00 if no overflow, or 0x01 if size overflow detected
; BC - sector index that corresponds record counter and current extent
CONVERT_RECORD_TO_SECTOR:
    d7a5  eb         XCHG                       ; Read the value at pointer to C (record counter, 0x00-0x80)
    d7a6  19         DAD DE         
    d7a7  4e         MOV C, M

    d7a8  06 00      MVI B, 00                  ; B = 0

    d7aa  21 0c 00   LXI HL, 000c               ; Calculate pointer to extent number
    d7ad  19         DAD DE

    d7ae  7e         MOV A, M                   ; Add LSB of the extent number to the record counter's MSB
    d7af  0f         RRC
    d7b0  e6 80      ANI A, 80
    d7b2  81         ADD C
    d7b3  4f         MOV C, A

    d7b4  3e 00      MVI A, 00                  ; It may happen that record counter is already 0x80, and
    d7b6  88         ADC B                      ; the highest bit will overflow the result. Carry this
    d7b7  47         MOV B, A                   ; to the next digit (store in B for now)

    d7b8  7e         MOV A, M                   ; Take remaining 4 bits of the extent number, and apply
    d7b9  0f         RRC                        ; the carry bit from the previous step
    d7ba  e6 0f      ANI A, 0f
    d7bc  80         ADD B
    d7bd  47         MOV B, A

    d7be  21 0e 00   LXI HL, 000e               ; Get highest 4 bits of the extent number from S2 field
    d7c1  19         DAD DE                     ; and shift them left to be combined with low 4 bits from
    d7c2  7e         MOV A, M                   ; the previous step
    d7c3  87         ADD A
    d7c4  87         ADD A
    d7c5  87         ADD A
    d7c6  87         ADD A

    d7c7  f5         PUSH PSW                   ; Combine low and high bits of the extent number
    d7c8  80         ADD B
    d7c9  47         MOV B, A                   ; BC now contains the actual record size in sectors

    d7ca  f5         PUSH PSW                   ; But there is still may be an overflow from the previous
    d7cb  e1         POP HL                     ; step. Move flags register to L

    d7cc  7d         MOV A, L                   ; Mask the lowest bit which corresponds to the carry flag
    d7cd  e1         POP HL
    d7ce  b5         ORA L
    d7cf  e6 01      ANI A, 01                  ; Put result to A

    d7d1  c9         RET



; Get file size (in sectors)
;
; The function calculates the file size (counting in 128 byte sectors) and stores the value in the bytes
; 0x21-0x23 of the FCB. These bytes may be further used for write operations in case the file is appeneded.
;
; The algorithm iterates over all extents of the selected file, and calculates sector index, based on
; number of records in the extent. The function selects the biggest value, which will will be the file
; size result
;
; Arguments:
; DE - Pointer to FCB
GET_FILE_SIZE:
    d7d2  0e 0c      MVI C, 0c                  ; Search for the first directory entry matching the file
    d7d4  cd 18 d3   CALL SEARCH_FIRST (d318)

    d7d7  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Calculate pointer to the output FCB random pos bytes
    d7da  11 21 00   LXI DE, 0021
    d7dd  19         DAD DE

    d7de  e5         PUSH HL                    ; Zero output bytes (bytes 0x21-0x23 of FCB)
    d7df  72         MOV M, D
    d7e0  23         INX HL
    d7e1  72         MOV M, D
    d7e2  23         INX HL
    d7e3  72         MOV M, D

GET_FILE_SIZE_LOOP:
    d7e4  cd f5 d1   CALL IS_DIR_COUNTER_RESET (d1f5)   ; Repeat until all directory entries processed
    d7e7  ca 0c d8   JZ GET_FILE_SIZE_EXIT (d80c)

    d7ea  cd 5e d1   CALL GET_DIR_ENTRY_ADDR (d15e) ; Get next directory entry address

    d7ed  11 0f 00   LXI DE, 000f               ; Convert record counter to sector index, result in A-B-C
    d7f0  cd a5 d7   CALL CONVERT_RECORD_TO_SECTOR (d7a5)

    d7f3  e1         POP HL                     ; Restore output bytes address
    d7f4  e5         PUSH HL

    d7f5  5f         MOV E, A                   ; Store overflow flag in E

    d7f6  79         MOV A, C                   ; Compare calculated value for current extent with
    d7f7  96         SUB M                      ; results of the previous extents
    d7f8  23         INX HL
    d7f9  78         MOV A, B
    d7fa  9e         SBB M
    d7fb  23         INX HL
    d7fc  7b         MOV A, E
    d7fd  9e         SBB M
    d7fe  da 06 d8   JC GET_FILE_SIZE_NEXT (d806)   ; Skip if new value is less than one already computed

    d801  73         MOV M, E                   ; Store new resulting value
    d802  2b         DCX HL
    d803  70         MOV M, B
    d804  2b         DCX HL
    d805  71         MOV M, C

GET_FILE_SIZE_NEXT:
    d806  cd 2d d3   CALL SEARCH_NEXT (d32d)    ; Look for another extent for the same file
    d809  c3 e4 d7   JMP GET_FILE_SIZE_LOOP (d7e4)

GET_FILE_SIZE_EXIT:
    d80c  e1         POP HL                     ; Exit the function
    d80d  c9         RET



; Function 0x24 - Set random record
;
; Sequental read/write operations operate with triples (record counter/extent low byte/extent high
; byte) which is not convenient for understanding position of the file. The function converts current 
; record index (advanced during read/write operations) to a single value sector index for random access
; read/write operations. 
;
; Arguments:
; DE - pointer to FCB
SET_RANDOM_REC_FUNC:
    d80e  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Convert current record to file sector index
    d811  11 20 00   LXI DE, 0020
    d814  cd a5 d7   CALL CONVERT_RECORD_TO_SECTOR (d7a5)

    d817  21 21 00   LXI HL, 0021               ; Calculate pointer to bytes 33-35 of FCB
    d81a  19         DAD DE

    d81b  71         MOV M, C                   ; Store calculated value
    d81c  23         INX HL
    d81d  70         MOV M, B
    d81e  23         INX HL
    d81f  77         MOV M, A
    d820  c9         RET


; Select disk
;
; THe function selects and initializes the specified disk, and updates login vector.
;
; Arguments:
; E - disk number (0 for A, 1 for B, and so on)
SELECT_DISK:
    d821  2a af d9   LHLD LOGIN_VECTOR (d9af)   ; Get login vector anf shift it right, so that LSB
    d824  3a 42 cf   LDA CURRENT_DISK (cf42)    ; corresponds to the current disk
    d827  4f         MOV C, A
    d828  cd ea d0   CALL SHIFT_HL_RIGHT (d0ea)

    d82b  e5         PUSH HL                    ; Move login vector to DE
    d82c  eb         XCHG

    d82d  cd 59 cf   CALL DO_SELECT_DISK (cf59) ; Perform disk selection and loading all the descriptors
    d830  e1         POP HL

    d831  cc 47 cf   CZ HANDLE_DISK_SELECT_ERROR (cf47) ; Handle errors if needed

    d834  7d         MOV A, L                   ; Return if disk is already online (corresponding bit is set)
    d835  1f         RAR
    d836  d8         RC

    d837  2a af d9   LHLD LOGIN_VECTOR (d9af)   ; Set the bit in login vector
    d83a  4d         MOV C, L
    d83b  44         MOV B, H
    d83c  cd 0b d1   CALL SET_DISK_BIT_MASK (d10b)

    d83f  22 af d9   SHLD LOGIN_VECTOR (d9af)   ; Store the login vector

    d842  c3 a3 d2   JMP DISK_INITIALIZE (d2a3)



; Function 0x0e - Select disk
;
; Arguments:
; E - disk number (0 for A, 1 for B, and so on)
SELECT_DISK_FUNC:
    d845  3a d6 d9   LDA FUNCTION_BYTE_ARGUMENT (d9d6)  ; Get the disk number argument

    d848  21 42 cf   LXI HL, CURRENT_DISK (cf42); Check if the disk has been already selected
    d84b  be         CMP M
    d84c  c8         RZ

    d84d  77         MOV M, A                   ; Store the new disk index

    d84e  c3 21 d8   JMP SELECT_DISK (d821)


; Switch to a drive requested in FCB, if needed
;
; Some functions may request an operation on a different disk drive, compared to the current one.
; In this case the function saves the current drive, and selects the desired one. Drive will be
; restored on exiting from BDOS to the caller
;
; The desired drive is specified in the first byte of the FCB.
RESELECT_DISK:
    d851  3e ff      MVI A, ff                  ; Set flag that disk was reselected, and needs to be restored
    d853  32 de d9   STA RESELECT_DISK_ON_EXIT (d9de)   ; on exit

    d856  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Get file drive code
    d859  7e         MOV A, M

    d85a  e6 1f      ANI A, 1f                  ; Set the code to 0xff if default drive is used
    d85c  3d         DCR A                      ; Normal disk codes will start from 0
    d85d  32 d6 d9   STA FUNCTION_BYTE_ARGUMENT (d9d6)  ; Anyway set the disk code to be used by other funcs

    d860  fe 1e      CPI A, 1e                  ; Check if a drive was specified, or use default drive
    d862  d2 75 d8   JNC RESELECT_DISK_1 (d875)

    d865  3a 42 cf   LDA CURRENT_DISK (cf42)    ; Load currently selected drive, and remember it to be
    d868  32 df d9   STA PREV_SELECTED_DRIVE (d9df) ; restored on exit

    d86b  7e         MOV A, M                   ; Load requested drive and store it to be restored on exit
    d86c  32 e0 d9   STA FCB_DRIVE_CODE (d9e0)

    d86f  e6 e0      ANI A, e0                  ; Make the disk code in FCB as 'current disk' as we are 
    d871  77         MOV M, A                   ; selecting the disk in the next line

    d872  cd 45 d8   CALL SELECT_DISK_FUNC (d845)   ; Select the disk

RESELECT_DISK_1:
    d875  3a 41 cf   LDA USER_CODE (cf41)       ; We do not need disk code anymore. Place user code instead
    d878  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; in the first byte of the FCB
    d87b  b6         ORA M
    d87c  77         MOV M, A

    d87d  c9         RET


; Function 0x0c - get BDOS version
;
; Arguments: none
;
; Returns: 0x22, meaning CP/M v2.2
GET_BDOS_VERSION:
    d87e  3e 22      MVI A, 22                  ; Return version 2.2
    d880  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x0d - Reset disk system
;
; Arguments: None
;
; Returns: nothing
RESET_DISK_SYSTEM:
    d883  21 00 00   LXI HL, 0000               ; Reset read only and login vectors. All disks are offline.
    d886  22 ad d9   SHLD READ_ONLY_VECTOR (d9ad)
    d889  22 af d9   SHLD LOGIN_VECTOR (d9af)

    d88c  af         XRA A                      ; Set current disk to A
    d88d  32 42 cf   STA CURRENT_DISK (cf42)

    d890  21 80 00   LXI HL, 0080               ; Set default disk buffer address
    d893  22 b1 d9   SHLD DISK_BUFFER_ADDR (d9b1)

    d896  cd da d1   CALL SET_DATA_DISK_BUFFER (d1da)   ; Set the disk buffer

    d899  c3 21 d8   JMP SELECT_DISK (d821)


; Function 0x0f - Open existing file
; 
; Arguments:
; DE - Pointer to FCB
OPEN_FILE_FUNC:
    d89c  cd 72 d1   CALL CLEAR_FCB_EXT_NUM_HIGH (d172)
    d89f  cd 51 d8   CALL RESELECT_DISK (d851)
    d8a2  c3 51 d4   JMP OPEN_FILE (d451)


; Function 0x10 - Close file
;
; Arguments:
; DE - Pointer to FCB
CLOSE_FILE_FUNC:
    d8a5  cd 51 d8   CALL RESELECT_DISK (d851)
    d8a8  c3 a2 d4   JMP CLOSE_FILE (d4a2)


; Function 0x11 - Search first match
;
; The function searches for a file record in the directory entry, that matches the pattern in FCB
;
; Arguments:
; DE - pointer to the FCB that contains match pattern
;
; Return:
; - In case of match, A = 0, 1, 2, or 3 representing the file record number in a loaded directory entry sector
; - If no files matched - A = 0xff
SEARCH_FIRST_FUNC:
    d8ab  0e 00      MVI C, 00                  ; Match all the entries, if the drive code is '?'

    d8ad  eb         XCHG                       ; Load drive code (first byte of the FCB)
    d8ae  7e         MOV A, M

    d8af  fe 3f      CPI A, 3f                  ; Check if the drive code is '?' (then C=00 and all entries
    d8b1  ca c2 d8   JZ SEARCH_FIRST_FUNC_1 (d8c2)  ; on the drive will be returned as matched)

    d8b4  cd a6 d0   CALL GET_FCB_EXTENT_NUMBER (d0a6)  ; Get the FCB extent number
    d8b7  7e         MOV A, M

    d8b8  fe 3f      CPI A, 3f                  ; If the extent number is '?', then S2 code will be cleared
    d8ba  c4 72 d1   CNZ CLEAR_FCB_EXT_NUM_HIGH (d172)

    d8bd  cd 51 d8   CALL RESELECT_DISK (d851)  ; Re-select disk if needed

    d8c0  0e 0f      MVI C, 0f                  ; Match full FCB record (disk code, name/extension, extent byte, etc)

SEARCH_FIRST_FUNC_1:
    d8c2  cd 18 d3   CALL SEARCH_FIRST (d318)   ; Do the actual search

    d8c5  c3 e9 d1   JMP COPY_DIR_BUF_TO_DISK_BUF (d1e9); Return directory sector so that caller can
                                                        ; parse the directory entry


; Function 0x11 - Search first match
;
; The function searches for a file record in the directory entry, that matches the pattern in FCB
;
; The function does not have any arguments. However, it will use FCB record, and number of bytes to match
; in each record used for the previous SEARCH_FIRST calls.
;
; Return:
; - In case of match, A = 0, 1, 2, or 3 representing the file record number in a loaded directory entry sector
; - If no files matched - A = 0xff
SEARCH_NEXT_FUNC:
    d8c8  2a d9 d9   LHLD CURRENT_SEARCH_FCB (d9d9) ; Restore the previous FCB pointer
    d8cb  22 43 cf   SHLD FUNCTION_ARGUMENTS (cf43)

    d8ce  cd 51 d8   CALL RESELECT_DISK (d851)      ; Reselect disk if needed

    d8d1  cd 2d d3   CALL SEARCH_NEXT (d32d)        ; Continue the search

    d8d4  c3 e9 d1   JMP COPY_DIR_BUF_TO_DISK_BUF (d1e9); Return the result


; Function 0x13 - Delete File
;
; Arguments:
; DE - Pointer to FCB with file mask
;
; Return:
; A - Directory code (0-3 if file was found and deleted, 0xff if no file was found)
DELETE_FILE_FUNC:
    d8d7  cd 51 d8   CALL RESELECT_DISK (d851)
    d8da  cd 9c d3   CALL DELETE_FILE (d39c)
    d8dd  c3 01 d3   JMP RETURN_DIRECTORY_CODE (d301)


; Function 0x14 - Read file sequentally
;
; Arguments:
; DE - Pointer to opened file FCB 
;
; Return:
; A - Directory code (0-3 if file was found and deleted, 0xff if no file was found)
READ_SEQUENTAL_FUNC:
    d8e0  cd 51 d8   CALL RESELECT_DISK (d851)
    d8e3  c3 bc d5   JMP READ_SEQUENTAL (d5bc)


; Function 0x15 - Write sector sequentally
;
; Write the data previously stored to the data buffer. Data is written to the previous opened file
; in a sequental manner (sector number is incremented automatically)
;
; Arguments:
; DE - pointer to the opened file FCB
;
; Return:
; A = 0x00 - success, other values - failure
WRITE_SEQUENTAL_FUNC:
    d8e6  cd 51 d8   CALL RESELECT_DISK (d851)
    d8e9  c3 fe d5   JMP WRITE_SEQUENTAL (d5fe)

; Function 0x16 - Create a file
;
; Arguments:
; DE - pointer to the File Control Block (FCB)
;
; Return:
; A - directory code (0-3 for entry index on current directory sector, or 0xff if file not found)
CREATE_FILE_FUNC:
    d8ec  cd 72 d1   CALL CLEAR_FCB_EXT_NUM_HIGH (d172)
    d8ef  cd 51 d8   CALL RESELECT_DISK (d851)
    d8f2  c3 24 d5   JMP CREATE_FILE (d524)


; Function 0x17 - Rename the file
;
; Arguments:
; DE - pointer to the File Control Block (FCB)
; where first 0x10 bytes represent original file name
; and second 0x10 bytes represent target file name
;
; Return:
; A - directory code (0-3 for entry index on current directory sector, or 0xff if file not found)
RENAME_FILE_FUNC:
    d8f5  cd 51 d8   CALL RESELECT_DISK (d851)
    d8f8  cd 16 d4   CALL RENAME_FILE (d416)
    d8fb  c3 01 d3   JMP RETURN_DIRECTORY_CODE (d301)


; Function 0x18 - Return disk login vector
;
; Return: HL - login vector
;              LSB corresponds to drive A, MSB - drive P.
;              0 - disk offline, 1 - disk online
GET_LOGIN_VECTOR:
    d8fe  2a af d9   LHLD LOGIN_VECTOR (d9af)
    d901  c3 29 d9   JMP RETURN_HL (d929)

; Function 0x19 - return current disk number
;
; Arguments: None
;
; Return: A - current disk number
GET_CURRENT_DISK:
    d904  3a 42 cf   LDA CURRENT_DISK (cf42)
    d907  c3 01 cf   JMP FUNCTION_EXIT (cf01)


; Function 0x1a - Set DMA buffer address for sector read/write operations
;
; Arguments:
; DE - buffer address to set
SET_BUFFER_ADDR:
    d90a  eb         XCHG                       ; Store the buffer address
    d90b  22 b1 d9   SHLD DISK_BUFFER_ADDR (d9b1)  

    d90e  c3 da d1   JMP SET_DATA_DISK_BUFFER (d1da); Let BIOS know about the new address


; Function 0x1b - Get current disk allocation vector
;
; Return: Pointer to the allocation vector
GET_ALLOCATION_VECTOR:
    d911  2a bf d9   LHLD DISK_ALLOCATION_VECTOR_PTR (d9bf)
    d914  c3 29 d9   JMP RETURN_HL (d929)

; Function 0x1d - Get pointer to read only vector
;
; Return: Pointer to the read only vector. LSB correspond to drive A, MSB - to drive P
GET_READ_ONLY_VECTOR:
    d917  2a ad d9   LHLD READ_ONLY_VECTOR (d9ad)
    d91a  c3 29 d9   JMP RETURN_HL (d929)



; Function 0x1e - Set file attributes
;
; Arguments:
; DE - Pointer to FCB with new attributes set
SET_FILE_ATTRS_FUNC:
    d91d  cd 51 d8   CALL RESELECT_DISK (d851)
    d920  cd 3b d4   CALL SET_FILE_ATTRS (d43b)
    d923  c3 01 d3   JMP RETURN_DIRECTORY_CODE (d301)


; Function 0x1f - Get Address of Disk Params Block
;
; Returns: HL - address of DPB
GET_DISK_PARAMS:
    d926  2a bb d9   LHLD DISK_PARAMS_BLOCK_ADDR (d9bb)

RETURN_HL:
    d929  22 45 cf   SHLD FUNCTION_RETURN_VALUE (cf45)  ; Save the HL as a return value
    d92c  c9         RET


; Function 0x20 - Get or Set User code
;
; Arguments:
; - 0xff to get user code
; - other values - set the value
;
; Return:
; 
GET_SET_USER_CODE:
    d92d  3a d6 d9   LDA FUNCTION_BYTE_ARGUMENT (d9d6)  ; Get the argument
    d930  fe ff      CPI A, ff                  ; Compare argument with 0xff
    d932  c2 3b d9   JNZ GET_SET_USER_CODE_1 (d93b)

    d935  3a 41 cf   LDA USER_CODE (cf41)       ; Load and return user code
    d938  c3 01 cf   JMP FUNCTION_EXIT (cf01)

GET_SET_USER_CODE_1:
    d93b  e6 1f      ANI A, 1f                  ; Save the user code
    d93d  32 41 cf   STA USER_CODE (cf41)
    d940  c9         RET


; Function 0x21 - Read randomly accessed sector
;
; DE - pointer to the FCB with fillex bytes 0x20-0x22 indicating file offset to read
READ_RANDOM_FUNC:
    d941  cd 51 d8   CALL RESELECT_DISK (d851)
    d944  c3 93 d7   JMP READ_RANDOM (d793)


; Function 0x22 - Write randomly accessed sector
;
; DE - pointer to the FCB with filled bytes 0x20-0x22 indicating file offset to read
WRITE_RANDOM_FUNC:
    d947  cd 51 d8   CALL RESELECT_DISK (d851)
    d94a  c3 9c d7   JMP WRITE_RANDOM (d79c)


; Function 0x23 - Get file size
;
; DE - pointer to the FCB
GET_FILE_SIZE_FUNC:
    d94d  cd 51 d8   CALL RESELECT_DISK (d851)
    d950  c3 d2 d7   JMP GET_FILE_SIZE (d7d2)


; Function 0x25 - Reset drive
;
; Despite its name (which could be read as reset and reload the drive), the function actually switches
; off the drive that previously was only. It updates the login vector (list of online drives) setting
; corresponding bit to 0. Bits of the read/only vector are also reset. The function can work with multiple
; drives simultaneously (this is just applying a mask)
;
; Arguments:
; DE - bitmask of drives to reset
RESET_DRIVE_FUNC:
    d953  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43) ; Load the drives vector

    d956  7d         MOV A, L                   ; Negate the provided vector of drives
    d957  2f         CMA
    d958  5f         MOV E, A

    d959  7c         MOV A, H
    d95a  2f         CMA

    d95b  2a af d9   LHLD LOGIN_VECTOR (d9af)   ; Load the login vector and apply the mask from previous
    d95e  a4         ANA H                      ; step. This will 'switch off' selected bits in the list
    d95f  57         MOV D, A                   ; of online drives

    d960  7d         MOV A, L
    d961  a3         ANA E
    d962  5f         MOV E, A

    d963  2a ad d9   LHLD READ_ONLY_VECTOR (d9ad)   ; Load the read/only vector

    d966  eb         XCHG
    d967  22 af d9   SHLD LOGIN_VECTOR (d9af)   ; Store the login vector

    d96a  7d         MOV A, L                   ; Apply the mask to read/only vector so that
    d96b  a3         ANA E                      ; disabled drives cannot be read only
    d96c  6f         MOV L, A

    d96d  7c         MOV A, H
    d96e  a2         ANA D
    d96f  67         MOV H, A

    d970  22 ad d9   SHLD READ_ONLY_VECTOR (d9ad)
    d973  c9         RET



; BDOS function epiloque
;
; This is a final part of every BDOS function execution. It restores previously selected disk,
; restores user's stack pointer, and loads function return code to registers to be returned to the caller.
BDOS_HANDLER_RETURN:
    d974  3a de d9   LDA RESELECT_DISK_ON_EXIT (d9de)   ; Check if the disk was changed, and needs to be
    d977  b7         ORA A                              ; re-selected back
    d978  ca 91 d9   JZ BDOS_HANDLER_RETURN_EXIT (d991)

    d97b  2a 43 cf   LHLD FUNCTION_ARGUMENTS (cf43)
    d97e  36 00      MVI M, 00

    d980  3a e0 d9   LDA FCB_DRIVE_CODE (d9e0)      ; FCB shares the first byte for drive code externally
    d983  b7         ORA A                          ; and user code internally. Restore the drive code 
    d984  ca 91 d9   JZ BDOS_HANDLER_RETURN_EXIT (d991) ; previously passed in FCB

    d987  77         MOV M, A                       ; Store the drive code

    d988  3a df d9   LDA PREV_SELECTED_DRIVE (d9df) ; Restore previously selected disk
    d98b  32 d6 d9   STA FUNCTION_BYTE_ARGUMENT (d9d6)
    d98e  cd 45 d8   CALL SELECT_DISK_FUNC (d845)

BDOS_HANDLER_RETURN_EXIT:
    d991  2a 0f cf   LHLD BDOS_SAVE_SP (cf0f)       ; Restore SP
    d994  f9         SPHL

    d995  2a 45 cf   LHLD FUNCTION_RETURN_VALUE (cf45)  ; Load function return value to AB
    d998  7d         MOV A, L
    d999  44         MOV B, H

    d99a  c9         RET                            ; and go back to the caller


; Function 0x28 - Write unallocated block with zero fill
;
; This function is similar to 0x22 random write operation, except for it zeros whole block when
; writing an unallocated block. 
;
; Arguments:
; DE - pointer to FCB with bytes 33-35 filled (see random write operation)
WRITE_WITH_ZERO_FILL:
    d99b  cd 51 d8   CALL RESELECT_DISK (d851)

    d99e  3e 02      MVI A, 02                  ; Select 'write operation with clearing unallocated block'
    d9a0  32 d5 d9   STA SEQUENTAL_OPERATION (d9d5)

    d9a3  0e 00      MVI C, 00                  ; Select the sector, indicating this is write operation
    d9a5  cd 07 d7   CALL SELECT_FILE_SECTOR_1 (d707)

    d9a8  cc 03 d6   CZ DISK_WRITE (d603)       ; Perform write
    d9ab  c9         RET



EMPTY_ENTRY_SIGNATURE:
    d9ac  e5          db e5                     ; A first byte of FCB/direntry that marks entry as empty

READ_ONLY_VECTOR:
    d9ad 00 00        dw 0000                   ; Bitmask of the disks currently marked as read only

LOGIN_VECTOR:
    d9af 00 00        dw 0000                   ; Bitmask of the disks currently marked as online

DISK_BUFFER_ADDR:
    d9b1 00 00        dw 0000                   ; Pointer to the currently set data buffer

LAST_DIR_ENTRY_NUM_ADDR:
    d9b3 00 00        dw 0000                   ; Pointer to latest directory entry number

CUR_TRACK_ADDR:
    d9b5 00 00        dw 0000                   ; Pointer to current track number

CUR_TRACK_SECTOR_ADDR:
    d9b7 00 00        dw 0000                   ; Pointer of the variable that indicates currently selected
                                                ; sector. Despite the name, this is not an index of the 
                                                ; sector. This rather an index of first sector on the selected
                                                ; track, counting from very first sector on the disk

DIRECTORY_BUFFER_ADDR:
    d9b9 00 00        dw 0000                   ; Pointer to the data buffer for directory operations

DISK_PARAMS_BLOCK_ADDR:
    d9bb 00 00        dw 0000                   ; Pointer to the current disk parameter block

DIR_CRC_VECTOR_PTR:
    d9bd 00 00        dw 0000                   ; Pointer to directory CRC vector

DISK_ALLOCATION_VECTOR_PTR:
    d9bf 00 00        dw 0000                   ; Pointer to disk allocation vector


DISK_PARAMETER_BLOCK:
DISK_SECTORS_PER_TRACK:
    d9c1  00 00      dw 0000                    ; Sectors per track (8)

DISK_BLOCK_SHIFT_FACTOR:
    d9c3  03         db 03                      ; Block shift factor

DISK_BLOCK_BLM:
    d9c4  07         db 07                      ; Block number mask 

DISK_EXTENT_MASK:
    d9c5  00         db 00                      ; Extent mask

DISK_TOTAL_STORAGE_CAPACITY:
    d9c6  39 00      dw 0039                    ; Total number of blocks on disk (not counting reserved tracks)

DISK_NUM_DIRECTORY_ENTRIES:
    d9c8  1f 00      dw 001f                    ; Number of directory entries

DISK_RESERVED_DIRECTORY_BLOCKS:
    d9ca  80 00      dw 0080                    ; Reserved directory blocks map

DISK_DIRECTORY_CHECK_VECT_SIZE:
    d9cc  08 00      dw 0008                    ; Size of the directory check vector

DISK_NUM_RESERVED_TRACKS:
    d9ce  06 00      dw 0006                    ; Number of reserved tracks in the beginning

SECTOR_TRANS_TABLE:
    d9d0 00 00        dw 0000                   ; Pointer to the sector translation table

FCB_COPIED_TO_DIR:
    d9d2 00           db 00                     ; Flag indicating the FCB copied to directory entry

READ_OR_WRITE:
    d9d3 00           db 00                     ; 0 for write, 0xff for read

SEARCH_IN_PROGRESS:
    d9d4 00           db 00                     ; Search in progress flag (file has not yet been found)

SEQUENTAL_OPERATION:
    d9d5 00           db 00                     ; Operation type (0 - random read/write, 1 - sequental, 
                                                ; 2 - random write with zero fill of unallocated blocks)
FUNCTION_BYTE_ARGUMENT:
    d9d6 00           db 00                     ; Function argument (byte size)

CUR_RECORD_BLOCK_INDEX:
    d9d7 00           db 00                     ; Current record block index in FCB alloc vector

NUM_BYTES_TO_MATCH:
    d9d8 00           db 00                     ; Number of bytes of FCB to match while doing file search

CURRENT_SEARCH_FCB:
    d9d9 00 00        dw 0000                   ; Current search FCB (used for subsequent SEARCH_NEXT calls)

SINGLE_BYTE_ALLOCATION_MAP:
    d9dd 00           db 00                     ; Flag indicating that total disk capacity high byte is 0

RESELECT_DISK_ON_EXIT:
    d9de 00           db 00                     ; Flag indicating that disk needs to be re-selected on exit

PREV_SELECTED_DRIVE:
    d9df 00           db 00                     ; Previously selected disk

FCB_DRIVE_CODE:
    d9e0 00           db 00                     ; Drive code passed as a first byte of FCB

TOTAL_EXTENT_RECORDS:
    d9e1 00           db 00                     ; Total records (sector) in current extent

EXTENT_NUMBER_MASKED:
    d9e2 00           db 00                     ; Current extent number (masked with extent mask)

CURRENT_RECORD_INDEX:
    d9e3 00           db 00                     ; Index of the current sector for sequental read/write ops


ACTUAL_SECTOR:
    d9e5 00 00        db 0000                   ; Actual sector number - a logical sector index starting from 
                                                ; very first sector on the disk, counting through all the
                                                ; tracks on the disk. Though it does not count reserved tracks. 
                                                ; Overall this is something line a LBA on modern computers)

BLOCK_FIRST_SECTOR:
    d9e7 00 00        db 0000                   ; First sector number for a given block

DIRECTORY_ENTRY_OFFSET:
    d9e9 00           db 00                     ; Offset of the current directory entry from the beginning of
                                                ; current directory sector

DIRECTORY_COUNTER:
    d9ea 00 00        dw 0000                   ; Current directory entry index (while iterating the directory)

????:
    d9eb 00           db 00
    
CURRENT_DIR_ENTRY_SECTOR:
    d9ec 00           db 00                     ; Sector number of the current directory entry


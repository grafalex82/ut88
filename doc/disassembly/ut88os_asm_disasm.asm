; This file contains disassembly and description for UT-88 OS Assembler and Disassembler, as well as
; supplemental commands.
;
; Due to limited resources on the UT-88 computer, the assembler uses somewhat specific syntax, and workflow
; associated with this. 
;
; The following describes assembler syntax:
; - If not stated otherwise, the assembler takes input source at 0x3000-0x9fff, and produce compiled binary
;   at 0xa000. One instruction per line is allowed. \r (0x0d) is treated as end of line. A symbol with code
;   0x80 or greater is treated as end of input file.
; - Line started with semicolon is a comment
; - Most of the instructions have regular syntax (instruction mnemonics, as well as 8-bit register usage):
;       STC             ; Instruction with no arguments
;       INR C           ; Instruction with 1 register argument
;       MOV A, B        ; Instruction with 2 register arguments
;       MVI E, 55       ; Instruction with a immediate byte data
;       LHLD 1234       ; Instruction with a immediate word data
; - Note that due to a bug, each instruction mnemonic shall be 4 chars wide, padded with spaces on the right
;       JZ 1234         ; Fail - mnemonic is too short (just 2 chars)
;       JZ   1234       ; OK - mnemonic matches "JZ  "
;       DI<\r>          ; Fail - mnemonic is too short (just 2 chars)
;       DI  <\r>        ; OK - mnemonic matches "DI  "
; - 2-byte registers are coded with a single letter: B=BC, D=DE, H=HL, S=SP
;       INX D           ; Increment DE register pair
; - Immedite arguments support multiple formats and values:
;       LDAX 1234       ; Hex value
;       LXI H, #12345   ; Decimal value
;       MVI A, 'Q'      ; Char value
;       CPI '''         ; Single quote char (0x27)
;       JMP $           ; $ is an address of the current instruction
;       STA @34         ; Reference to a location defined elsewhere (see description below)
; - Immediate argument support simple expressions with + and - operations:
;       SHLD 1234 + #35 - 'W'   ; 1234 hex + 35 dec (23 hex) - 57 hex
; - Labels and references may be used to not to deal with absolute addresses. Labels have syntax @<num>: 
;   preceeding an instruction, where <num> is a hex number in 00-FF range
;       @12: DCR C      ; Decrement counter
;            JNZ @12    ; Repeat while counter is not zero, repeat 
; - Address of the labeled instruction is stored in the labels area 0xf400-0xf600 (2 bytes per label).
;   Label num is the index in the label table (e.g. label 12 is stored at 0xf400+12*2 = 0xf424 address)
; - It is possible to reference labels defined later in the code. Compiler uses 2 pass algorithm. First
;   pass compiles program as usual, but referenced addresses point to the label area. Second pass searches
;   such references, and substitute with actual label value.
;            JMP @12    ; On 1st pass JMP argument is 0xf424, 2nd pass replaces it with actual label addr
;            ...
;       @12: ...
; - References may be used in argument expressions, but they have to be substituted with the actual label
;   address in compile time (during 1st pass):
;       CALL @12 + 8    ; Substituted with whatever is in 0xf424, and advanced by 8
; - EQU directive allows setting some label values during compilation. The syntax is @<label>: EQU <value>
;   The value follows syntax described above
;       @12: EQU 5A+#10 ; Set label #12 (0xf424) to 5A + 0A = 64 value
; - DB directive is used to define some data bytes. Multiple values may be added separated with comma.
;   each value follows the same syntax as immediate instruction arguments, but also allows defining a string.
;       DB 5A, #23, 'A' ; several data bytes in hex form, decimal form, and char value
;       DB $, @45       ; addresses are truncated to low byte only
;       DB 'ABCDEF'     ; string compiled as is to 6 bytes, NULL terminated is not applied
; - DW directive is used to define data words. Same rules apply to data words (except for strings)
;       DW F8AB, #12343 ; 16-bit values in hex and dec form
;       DW ABCD - 'A'   ; expressions can be used
;       DW $, @45       ; addresses are processed normally
; - ORG directive is used to define output address of the compiled program (same as it would be specified
;   in as a assembler command argument in Monitor command line). Note: It is impossible to store compile
;   output at one memory range, but compile it to be used at other address space. For these purposes Command P
;   shall be used.
; - DIR directive allows running external (Monitor) commands as a part of compilation process
;       DIR DA000,A00F  ; Dump some of the compiled bytes (see Command D description)
; 
; Assembler comes as a suit of several commands:
; - Command A - Assembler
;   - A[@] [target start addr]      - compile text at 0x3000-0x9fff to 0xa000 (or other address, if specified)
;                                     @ modifier runs 2nd pass also (by default only 1st pass is executed)
;
; - Command N - Interactive assembler
;   - N[@] [addr]                   - enter program line by line, store compiled program at 0xa000 (or other
;                                     address if specified). @ modifier runs 2nd pass also after all input
;                                     lines are entered.
;
; - Command @ - Run assembler 2nd pass explicitly
;   - @ [addr1, addr2]              - Run assembler 2nd pass for address range (or 0xa000-0xaffe)
;
; - Command W - Interactive disassembler
;   - W <start_addr>[, <end_addr>]  - Run interactive disassembler for memory range (shows up to 2 pages of
;                                     disassembled program on the screen, allows pagination of the text)
;
; - Command Z - View or clean labels area
;   - Z                             - Show 0xf400-0xf600 labels area, list current values of each label
;   - Z0                            - Zero all labels
;
; - Command P - relocate program from one memory range to another
;   - P[N] <w1>,<w2>,<s1>,<s2>,<t>  - Relocate program
;   - P@ <s1>,<s2>,<t>              - Adjust addresses in 0xf400-0xf600 labels area
;
; See corresponding command description for arguments and algorithm notes.



; Command Z: Zero/dump label reference 0xf400-0xf600 range
; 
; Usage:
; Z         - Dump the range (print 256 16-bit words, each word correspond to a label value)
; Z0        - Fill the range with zeros
;
; This command is supposed to be used with assembler commands (A, N, @). Label values are filled during
; assembly process with addresses of labels found in the source code. These values may be then applied
; back to the compiled program using @ command. Command Z allows the user to verify label values.
COMMAND_Z_DUMP_LABELS:
    c1eb  3a 7c f7   LDA f77b + 1 (f77c)        ; Get the second command byte
    c1ee  fe 30      CPI A, 30                  ; If it is '0' - go and clear memory range
    c1f0  c2 00 c2   JNZ DUMP_LABELS (c200)     ; Non-zero command will show label values

    c1f3  21 ff f3   LXI HL, f3ff               ; 1 byte before start address

CLEAR_LABELS_LOOP:
    c1f6  23         INX HL                     ; Advance to the next byte

    c1f7  7c         MOV A, H                   ; Check if we reached the end of the range
    c1f8  fe f6      CPI A, f6
    c1fa  c8         RZ

    c1fb  36 00      MVI M, 00                  ; Fill byte with zero

    c1fd  c3 f6 c1   JMP CLEAR_LABELS_LOOP (c1f6)   ; Repeat for the next byte

DUMP_LABELS:
    c200  3a 7a f7   LDA ENABLE_SCROLL (f77a)   ; Disable scroll, will output page by page
    c203  f5         PUSH PSW
    c204  af         XRA A
    c205  32 7a f7   STA ENABLE_SCROLL (f77a)

    c208  0e 1f      MVI C, 1f                  ; Clear screen
    c20a  cd f0 f9   CALL PUT_CHAR (f9f0)

    c20d  16 f4      MVI D, f4                  ; Set DE to 0xf400 (label #0)
    c20f  5f         MOV E, A

    c210  47         MOV B, A                   ; Zero label index

DUMP_LABELS_LOOP:
    c211  78         MOV A, B                   ; Print the label index
    c212  cd af fb   CALL PRINT_BYTE_CHECK_KBD (fbaf)

    c215  1a         LDAX DE                    ; Load next word to HL
    c216  13         INX DE
    c217  6f         MOV L, A
    c218  1a         LDAX DE
    c219  13         INX DE
    c21a  67         MOV H, A

    c21b  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print the value

    c21e  04         INR B                      ; Advance to the next word, repeat until reached end of range
    c21f  c2 11 c2   JNZ DUMP_LABELS_LOOP (c211)

    c222  f1         POP PSW                    ; Restore scroll mode
    c223  32 7a f7   STA ENABLE_SCROLL (f77a)

    c226  c9         RET


; Command P: Relocate program to another memory address range
;
; Usage:
; - P[N]<w1>,<w2>,<s1>,<s2>,<t>     - Relocate program (see arguments description below)
; - P@<s1>,<s2>,<t>                 - Adjust addresses in labels area (0xf400-0xf600)
;
; P (PN) command is used to relocate a program from one memory range to another. The command iterates over 
; program instructions, and checks 2- and 3-byte instructions whether they have an address in source memory
; range, and correct them to match the target memory range. 
;
; Arguments description:
; - <s1>-<s2> (arguments 3 and 4) represent the source program memory range. The P command searches for all
;   3-byte instructions that possibly contain an address in <s1>-<s2> range. These instructions are corrected
;   so that they match the target memory range (argument 5)
; - <w1>-<w2> (arguments 3 and 4) represent a working copy of the program. It may happen that command P is
;   used to relocate the program from a ROM to different addresses. In this case modifying <s1>-<s2> source
;   range may not be possible. The user may copy program from the ROM to a working RAM at <w1>-<w2> range,
;   where then instruction modification happens. Note, that command P does not perform copying from <s1>-<s2>
;   to <w1>-<w2>, but expects instructions copied before command P is executed.
; - <t> (argument 5) represents the target address range where the program shall work after relocation. Note
;   that command does not make any copying to target address range. It only change a working copy so that 
;   all the addresses point to the target range.
;
; Example:
; Suppose you have a working program at 0x2000-0x2fff memory range, and you want to port the program to a
; different computer that will execute the program at 0x5000-0x5fff range. 
;
; In order not to corrupt the original program, you may create a working copy, say at 0x4000-0x4fff range
; with a memory copy command:
; CY 2000,2fff,4000
;
; Now you can perform relocation with command P - working copy range (arg1/2), specify original program range
; in arg3/4, and finally the target address:
; P 4000,4fff,2000,2fff,5000
;
; Suppose that source program (which is located in 0x2000-0x2fff range) has an instruction:
;   JMP 2345
;
; Since address 0x2345 belongs to source program range (0x2000-0x2fff), it will be replaced with the 
; corresponding address in the target memory range:
;   JMP 5345
;
; The change is performed in working copy only (0x4000-0x4fff), leaving the original program intact.
;
; In some cases programs may use low and high bytes of the address separately. For example:
;   MVI A, f6
;   CMP D
;
; This code in fact may implement an address checking. For example check that DE counter reached 0xf600
; address. Unfortunately relocation program can't state this for sure, and prints a warning, specifying
; address of suspicious MVI instruction. The user may then double check whether this is related to address
; calculations, and correct the constant if needed.
;
; By default it is assumed that LXI instruction loads an address too. If the address is in source memory
; range, it will be adjusted. The 'PN' command will treat LXI arguments as a number, and will not be adjusted
; even if it matches the memory range. The warning will be displayed indicating a suspicious instruction
; address, so that the User can double check.
;
; Target range and a working copy may coincide. If you want to relocate the program to another range on the
; same system, you can follow the next example:
; CY 2000,2fff,5000
; P 5000,5fff,2000,2fff,5000
; The first command will copy the original program from 0x2000-0x2fff range to 0x5000. The second command
; will adjust instructions that refers the original range so that it points the new address range.
;   
;
; The P@ command also does an address adjustment, but only for labels area:
; - 0xf400-0xf600 range is considered as an array of 256 16-byte address values
; - the command iterates over these values, and check whether they are in <s1>-<s2> range
; - if the address matches the source range, it will be adjusted to a corresponding target address
;
; Suppose there are 2 labels with values 0x2345 and 0x4567
; If you want to relocate all addresses in 0x2000-0x2fff range to 0x6000-0x6fff range, enter the command:
;   P@ 2000,2fff,6000
;
; The first label with value 0x2345 will be changed to 0x6345. The second address will remain 0x4567 as it
; does not belong the 0x2000-0x2fff range.
COMMAND_P_RELOCATE:
    c227  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)  ; Check if this is P@ command
    c22a  c2 79 c2   JNZ RELOCATE_PROGRAM (c279)

    ; The following processes P@ command
    c22d  cd c9 fb   CALL DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9); Parse arguments

    c230  2a 55 f7   LHLD ARG_3 (f755)          ; Load arg 3 to HL (source start address)
    c233  cd c6 fd   CALL HL_SUB_DE (fdc6)      ; Calculate offset from DE (destination end address)

    c236  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print source start address

    c239  44         MOV B, H                   ; BC - offset to apply
    c23a  4d         MOV C, L
    c23b  11 ff f3   LXI DE, f3ff               ; DE - 0xd400 destination start address

RELOCATE_ADDR_LOOP:
    c23e  13         INX DE                     ; Advance to the next value, stop if reached 0xf600
    c23f  3e f6      MVI A, f6
    c241  ba         CMP D
    c242  c8         RZ

    c243  1a         LDAX DE                    ; Load the word at [DE] to HL
    c244  13         INX DE
    c245  6f         MOV L, A
    c246  1a         LDAX DE
    c247  1b         DCX DE
    c248  67         MOV H, A

    c249  d5         PUSH DE
    c24a  eb         XCHG

    c24b  2a 51 f7   LHLD ARG_1 (f751)          ; Check if the value is higher than arg1
    c24e  2b         DCX HL
    c24f  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c252  d2 6a c2   JNC RELOCATE_ADDR_1 (c26a)

    c255  2a 53 f7   LHLD ARG_2 (f753)          ; Check if the value is lower than arg2
    c258  23         INX HL
    c259  eb         XCHG
    c25a  cd d3 fb   CALL CMP_HL_DE (fbd3)

    c25d  d1         POP DE                     ; If not in arg1-arg2 range - advance to the next value
    c25e  d2 6c c2   JNC RELOCATE_ADDR_2 (c26c)

    c261  09         DAD BC                     ; Apply the offset

    c262  7d         MOV A, L                   ; Store value back
    c263  12         STAX DE
    c264  13         INX DE
    c265  7c         MOV A, H
    c266  12         STAX DE

    c267  c3 3e c2   JMP RELOCATE_ADDR_LOOP (c23e)  ; Repeat for the next address

RELOCATE_ADDR_1:
    c26a  eb         XCHG
    c26b  d1         POP DE

RELOCATE_ADDR_2:
    c26c  13         INX DE                     ; Advance to the next address
    c26d  c3 3e c2   JMP RELOCATE_ADDR_LOOP (c23e)


; Helper function to check whether '@' modifier is added to the command
; Raise Z flag if '@' modifier is present
CHECK_AT_MODIFIER:
    c270  11 7c f7   LXI DE, f77b + 1 (f77c)

CHECK_AT_SYMBOL:
    c273  1a         LDAX DE                    ; Check if symbol at [DE] is @
    c274  fe 40      CPI A, 40
    c276  c0         RNZ                        ; Z flag reset if no @

    c277  13         INX DE                     ; Advance DE to the next symbol after @
    c278  c9         RET                        ; Z flag is set if @ is present


; The following process P command (not P@)
RELOCATE_PROGRAM:
    c279  11 7c f7   LXI DE, f77b + 1 (f77c)

    c27c  1a         LDAX DE                    ; Skip 'N' command alteration char
    c27d  fe 4e      CPI A, 4e
    c27f  c2 83 c2   JNZ RELOCATE_PROGRAM_1 (c283)

    c282  13         INX DE

RELOCATE_PROGRAM_1:
    c283  cd d9 fb   CALL PARSE_ARGUMENTS (fbd9); Parse arguments, report an error not all arguments provided
    c286  cc b9 fb   CZ REPORT_INPUT_ERROR (fbb9)

    c289  d5         PUSH DE                    ; Decrement arg2 (destination end address)
    c28a  cd cc fb   CALL LOAD_ARGUMENTS (fbcc)
    c28d  2b         DCX HL
    c28e  22 53 f7   SHLD ARG_2 (f753)

    c291  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)   ; Report error if dest start addr > dest end addr

    c294  2a 55 f7   LHLD ARG_3 (f755)          ; Compare source start and end addresses
    c297  eb         XCHG
    c298  2a 57 f7   LHLD ARG_4 (f757)
    c29b  cd d3 fb   CALL CMP_HL_DE (fbd3)

    c29e  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)   ; Report error if src start addr > src end addr

    c2a1  d1         POP DE                     ; Parse argument 5
    c2a2  cd 04 fc   CALL PARSE_HEX (fc04)
    c2a5  eb         XCHG

    c2a6  2a 55 f7   LHLD ARG_3 (f755)          ; Calculate arg5-arg3 difference
    c2a9  eb         XCHG
    c2aa  cd c6 fd   CALL HL_SUB_DE (fdc6)
    c2ad  22 5e f7   SHLD f75e

RELOCATE_PROGRAM_LOOP:
    c2b0  2a 51 f7   LHLD ARG_1 (f751)          ; Get next byte at [arg1] (destination range)
    c2b3  e5         PUSH HL
    c2b4  7e         MOV A, M

    c2b5  cd 1c c3   CALL MATCH_INSTRUCTION (c31c)  ; Match the opcode
    c2b8  e1         POP HL
    c2b9  d2 ed c2   JNC RELOCATE_PROGRAM_2_BYTE_OPCODE (c2ed)  ; C flag indicates a 3-byte instruction

    c2bc  23         INX HL                     ; Load the instruction argument to DE
    c2bd  5e         MOV E, M
    c2be  23         INX HL
    c2bf  56         MOV D, M

    c2c0  2a 55 f7   LHLD ARG_3 (f755)          ; Check if the argument is greater or equal than source start 
    c2c3  2b         DCX HL                     ; address
    c2c4  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c2c7  d2 0b c3   JNC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2ca  2a 57 f7   LHLD ARG_4 (f757)          ; Check if the argument is lower than source end address
    c2cd  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c2d0  da 0b c3   JC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2d3  78         MOV A, B                   ; The argument is in source memory range. Check if the
    c2d4  fe 07      CPI A, 07                  ; instruction is LXI (argument is not necessarily an address)
    c2d6  c2 e1 c2   JNZ RELOCATE_PROGRAM_2 (c2e1)

    c2d9  3a 7c f7   LDA f77b + 1 (f77c)        ; Check if the 'N' command alteration enabled, which warns
    c2dc  fe 4e      CPI A, 4e                  ; the user that argument is probably an address, and shall be
    c2de  ca 03 c3   JZ RELOCATE_PROGRAM_PRINT_WARNING (c303)   ; double checked

RELOCATE_PROGRAM_2:
    c2e1  2a 5e f7   LHLD f75e                  ; Adjust the instruction argument to the target memory range
    c2e4  19         DAD DE

    c2e5  eb         XCHG                       ; Store the calculated value as a new instruction argument
    c2e6  2a 51 f7   LHLD ARG_1 (f751)
    c2e9  23         INX HL
    c2ea  73         MOV M, E
    c2eb  23         INX HL
    c2ec  72         MOV M, D

RELOCATE_PROGRAM_2_BYTE_OPCODE:
    c2ed  79         MOV A, C                   ; Check if this is a 2-byte instruction
    c2ee  fe 02      CPI A, 02
    c2f0  c2 0b c3   JNZ RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2f3  23         INX HL                     ; Advance to the argument byte

    c2f4  3a 56 f7   LDA ARG_3 + 1 (f756)       ; Perhaps the argument is a high byte of an address.
    c2f7  3d         DCR A                      ; Check if it higher than source start address high byte
    c2f8  be         CMP M
    c2f9  d2 0b c3   JNC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

    c2fc  3a 58 f7   LDA ARG_4 + 1 (f758)       ; And lower than source end address high byte
    c2ff  be         CMP M
    c300  da 0b c3   JC RELOCATE_PROGRAM_1_BYTE_OPCODE (c30b)

RELOCATE_PROGRAM_PRINT_WARNING:
    c303  cd 47 fc   CALL PRINT_ARG_1 (fc47)    ; Print the address with an exclamation mark. These 2-byte
    c306  3e 21      MVI A, 21                  ; instructions will not be changed automatically, but are
    c308  cd e9 f9   CALL PUT_CHAR_A (f9e9)     ; listed to the user as potentially requiring a change

RELOCATE_PROGRAM_1_BYTE_OPCODE:
    c30b  2a 51 f7   LHLD ARG_1 (f751)          ; Advance to the next instruction (C is instruction length)
    c30e  06 00      MVI B, 00
    c310  09         DAD BC
    c311  22 51 f7   SHLD ARG_1 (f751)

    c314  cd cc fb   CALL LOAD_ARGUMENTS (fbcc) ; Stop when reached end of the range
    c317  c8         RZ
    c318  d8         RC

    c319  c3 b0 c2   JMP RELOCATE_PROGRAM_LOOP (c2b0)



; Match byte in A with one of CPU instructions
; Return:
; A - matched and masked instruction (base instruction opcode)
; B - attributes byte
; C - number of bytes in the instruction
; HL - pointer to the instruction record
; C flag is set if 3-byte instruction is matched
;
; The function tries to match exact instruction code agains the instruction table. If no specific 
; instruction matched, the function applies different bitmasks in order to match a whole instruction
; classes (e.g. full class of MOV instructions). In this case only the first instruction in the class 
; is returned.
MATCH_INSTRUCTION:
    c31c  21 cd c5   LXI HL, INSTRUCTION_DESCRIPTORS (c5cd) ; Get instructions descriptors

    c31f  47         MOV B, A                   ; Store instruction in B

MATCH_INSTRUCTION_LOOP:
    c320  23         INX HL                     ; Skip mnemonic
    c321  23         INX HL
    c322  23         INX HL
    c323  23         INX HL

    c324  be         CMP M                      ; Compare instruction code, proceed when matched
    c325  23         INX HL
    c326  ca 68 c3   JZ MATCH_INSTRUCTION_ATTRIBUTE (c368)

    c329  23         INX HL                     ; If we reached end of the table, this probably an instruction
    c32a  34         INR M                      ; that needs to be matched with mask
    c32b  35         DCR M
    c32c  f2 20 c3   JP MATCH_INSTRUCTION_LOOP (c320)

    c32f  21 1c c3   LXI HL, MATCH_INSTRUCTION (c31c)   ; Set return address to MATCH_INSTRUCTION so that 
    c332  e5         PUSH HL                    ; instructions can be matched again after bitmask is applied

    c333  e6 cf      ANI A, cf                  ; Mask POP instructions class, go match exact instruction
    c335  fe c1      CPI A, c1
    c337  c8         RZ

    c338  fe c5      CPI A, c5                  ; Mask PUSH instructions class, go match exact instruction
    c33a  c8         RZ

    c33b  e6 f7      ANI A, f7                  ; Filter out some non-valid instructions
    c33d  ca 64 c3   JZ MATCH_INSTRUCTION_DATA_BYTE (c364)

    c340  fe c7      CPI A, c7                  ; Mask RST instructions class, go match exact instruction
    c342  c8         RZ

    c343  e6 f0      ANI A, f0                  ; Mask MOV instructions class, go match exact instruction
    c345  fe 40      CPI A, 40
    c347  c8         RZ

    c348  78         MOV A, B                   ; Match LXI, STAX, INX, DCX, DAD, and LDAX instruction classes
    c349  e6 c4      ANI A, c4
    c34b  ca 60 c3   JZ MATCH_INSTRUCTION_2 (c360)

    c34e  e6 f0      ANI A, f0                  ; Filter out some instruction set
    c350  c2 57 c3   JNZ MATCH_INSTRUCTION_1 (c357)

    c353  78         MOV A, B                   ; Mask MVI, INR, and DCR instruction classes
    c354  e6 c7      ANI A, c7
    c356  c9         RET

MATCH_INSTRUCTION_1:
    c357  fe 80      CPI A, 80                  ; Match ADD, ADC, SUB, SBB, ANA, XRA, ORA, and CMP
    c359  c2 64 c3   JNZ MATCH_INSTRUCTION_DATA_BYTE (c364) ; instruction classes

    c35c  78         MOV A, B                   ; Apply mask (remove register bits)
    c35d  e6 f8      ANI A, f8
    c35f  c9         RET

MATCH_INSTRUCTION_2:
    c360  78         MOV A, B                   ; Apply mask for LXI, STAX, INX, DCX, DAD, and LDAX
    c361  e6 cf      ANI A, cf                  ; instruction classes
    c363  c9         RET

MATCH_INSTRUCTION_DATA_BYTE:
    c364  e1         POP HL                     ; No exact instruction matched, will return "DB" directive
    c365  21 a6 c7   LXI HL, INSTRUCTION_DESCRIPTORS_DB + 5 (c7a6)

MATCH_INSTRUCTION_ATTRIBUTE:
    c368  7e         MOV A, M                   ; Load attribute byte in A
    c369  e5         PUSH HL

    c36a  21 82 c3   LXI HL, MATCH_INSTRUCTION_EXIT (c382)  ; Set the exit handler
    c36d  e3         XTHL

    c36e  0e 03      MVI C, 03                  ; Match 3-byte instruction attribute

    c370  fe 02      CPI A, 02                  ; Match 0x02 attribute byte (normal 3-byte instruction)
    c372  37         STC
    c373  c8         RZ

    c374  fe 07      CPI A, 07                  ; Match 0x07 attribute byte (LXI instruction)
    c376  37         STC
    c377  c8         RZ

    c378  0d         DCR C                      ; Match 2-byte instruction attribute

    c379  fe 01      CPI A, 01                  ; Match 0x01 attribute byte (normal 2-byte instruction)
    c37b  c8         RZ

    c37c  fe 09      CPI A, 09                  ; Match 0x09 (MVI instruction) attribute byte
    c37e  c8         RZ

    c37f  af         XRA A                      ; Everything else is 1-byte instructions, attribute byte is 0
    c380  0d         DCR C
    c381  c9         RET

MATCH_INSTRUCTION_EXIT:
    c382  78         MOV A, B                   ; Return masked instruction byte in A
    c383  46         MOV B, M                   ; Return instruction attribute byte in B
    c384  2b         DCX HL                     ; Return pointer to instruction record+4 in HL 
    c385  c9         RET


; See ut88os_monitor2.asm for Command L implementation and description (0xc386 - 0xc3c1)



; Command W: Interactive disassembler
;
; Usage:
; W <start_addr>[, <end_addr>]
; 0xffff will be used as end address, if second argument is not specified.
;
; The command does line by line disassembly of the specified memory range. The command prints disassembly
; list page by page (24 lines each). It is possible to use 2-screen disassembly, so that 2 pages can be
; displayed simultaneously on left and right part of the screen. Before printing the next page of data, 
; the program waits a keyboard press. The user may select which part of the screen to use for the next page:
; - '1' - use left part of the screen
; - '2' - use right part of the screen
; - ' ' - use part of the screen alternate to the previously printed page
; - other key will exit to the monitor
; 
; For every instruction the algorithm finds a matching instruction descriptor. The descriptor includes
; 4-char instruction mnemonic, and an attribute code, which is used to find the right printer function for
; the arguments area. These functions are used to fill the string in a buffer, and then print whole string
; on the screen at cursor position.
COMMAND_W_DISASSEMBLER:
    c3c2  cd bf fb   CALL PARSE_AND_LOAD_ARGUMENTS (fbbf)   ; Parse arguments

    c3c5  c2 ce c3   JNZ DISASSEMBLER_START (c3ce)  ; If no second argument added - set it as 0xffff
    c3c8  21 ff ff   LXI HL, ffff
    c3cb  22 53 f7   SHLD ARG_2 (f753)

DISASSEMBLER_START:
    c3ce  cd b0 fd   CALL RESET_COMMAND_MODE_FLAG (fdb0); Will use left part of the screen for the first page
    
DISASSEMBLER_GET_MODE:
    c3d1  0e 57      MVI C, 57                  ; Print 'W' char, indicating we are in disassembler, and  
    c3d3  cd f0 f9   CALL PUT_CHAR (f9f0)       ; waiting for the page number (left, right, alternate)

    c3d6  cd 6b f8   CALL KBD_INPUT (f86b)      ; Wait for the keyboard char

    c3d9  fe 20      CPI A, 20                  ; Check if space bar is pressed
    c3db  c2 e5 c3   JNZ DISASSEMBLER_GET_MODE_1 (c3e5)

    c3de  3a ff f7   LDA VALUE_SIGN (f7ff)      ; Space will alternate the screen part (left to right, right
    c3e1  2f         CMA                        ; to left)
    c3e2  c3 f1 c3   JMP DISASSEMBLER_GET_MODE_2 (c3f1)

DISASSEMBLER_GET_MODE_1:
    c3e5  d6 32      SUI A, 32                  ; '2'-0x32 = 0x00 (right screen); '1'-0x32 = 0xff (left screen)
    c3e7  ca f1 c3   JZ DISASSEMBLER_GET_MODE_2 (c3f1)  ; other keys produce other values

    c3ea  fe ff      CPI A, ff                  ; Compare if other key is pressed

    c3ec  0e 19      MVI C, 19                  ; If other key is pressed the disassembler will exit
    c3ee  c2 f0 f9   JNZ PUT_CHAR (f9f0)        ; through PUT_CHAR

DISASSEMBLER_GET_MODE_2:
    c3f1  32 ff f7   STA VALUE_SIGN (f7ff)      ; Store the selected screen flag

    c3f4  01 0c 18   LXI BC, 180c               ; Will print up to 24 lines (0x18)
    c3f7  cd f0 f9   CALL PUT_CHAR (f9f0)       ; Also move cursor to the top-left corner (0x0c)

DISASSEMBLER_LINE_LOOP:
    c3fa  c5         PUSH BC                    ; Print every instruction with a new line, until 24 lines are
    c3fb  78         MOV A, B                   ; filled
    c3fc  fe 18      CPI A, 18
    c3fe  c4 6b fc   CNZ PRINT_NEW_LINE (fc6b)

    c401  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; If right screen selected - move cursor to col 32
    c404  cc 7b c4   CZ DISASSEMBLER_MOVE_CURSOR_RIGHT (c47b)

    c407  cd 4a fc   CALL PRINT_ARG_1_NO_NEW_LINE (fc4a)    ; Print the instruction address

    c40a  01 7b f7   LXI BC, f77b               ; Going to fill command line buffer with spaces
    c40d  c5         PUSH BC

DISASSEMBLER_CLEAR_LINE_LOOP:
    c40e  3e 20      MVI A, 20                  ; Fill next char with space symbol
    c410  02         STAX BC
    c411  03         INX BC

    c412  79         MOV A, C                   ; Continue until reached 0xf796 address
    c413  fe 96      CPI A, 96
    c415  c2 0e c4   JNZ DISASSEMBLER_CLEAR_LINE_LOOP (c40e)

    c418  c1         POP BC                     ; Print the instruction byte to the buffer
    c419  cd 86 c4   CALL DISASSEMBLER_PRINT_BYTE (c486)

    c41c  cd 1c c3   CALL MATCH_INSTRUCTION (c31c)  ; Search if it matches an instruction
    c41f  11 a6 c7   LXI DE, INSTRUCTION_DESCRIPTORS_DB + 5 (c7a6)
    c422  1b         DCX DE
    c423  cd d3 fb   CALL CMP_HL_DE (fbd3)
    c426  c2 31 c4   JNZ DISASSEMBLER_FILL_INSTRUCTION_LINE (c431)

    c429  eb         XCHG                       ; Instruction not matched. Will be printing DB directive
    c42a  2a 7b f7   LHLD f77b                  ; Copy the byte from bytes area to arguments area
    c42d  22 87 f7   SHLD f77b + 12 (f787)
    c430  eb         XCHG

DISASSEMBLER_FILL_INSTRUCTION_LINE:
    c431  11 5b c4   LXI DE, DISASSEMBLER_PRINT_LINE (c45b) ; Print the disassembled line when ready
    c434  d5         PUSH DE

    c435  e5         PUSH HL
    c436  cd 9b c4   CALL DISASSEMBLER_GET_ATTRIBUTE_HANDLER (c49b)

    c439  7d         MOV A, L                   ; Advance to the corresponding argument printing handler 
    c43a  c6 1e      ADI A, 1e                  ; (15 records after)
    c43c  6f         MOV L, A

    c43d  cd a6 c4   CALL DISASSEMBLER_GET_HANDLER_ADDR (c4a6)  ; Get the handler function address

    c440  01 82 f7   LXI BC, f77b + 7 (f782)    ; Get offset where to place instruction mnemonic

    c443  e3         XTHL                       ; Restore address to instruction descriptor
                                                ; Store printing handler address on stack

    c444  2b         DCX HL                     ; Move to descriptor mnemonic field
    c445  2b         DCX HL
    c446  2b         DCX HL
    c447  2b         DCX HL

    c448  16 04      MVI D, 04                  ; Copy 4 chars of the mnemonic

DISASSEMBLER_COPY_MNEMONIC_LOOP:
    c44a  7e         MOV A, M                   ; Copy next char of the mnemonic
    c44b  02         STAX BC

    c44c  03         INX BC                     ; Advance to the next byte
    c44d  23         INX HL

    c44e  15         DCR D                      ; Repeat for all 4 chars
    c44f  c2 4a c4   JNZ DISASSEMBLER_COPY_MNEMONIC_LOOP (c44a)

    c452  eb         XCHG

DISASSEMBLER_NEXT_BYTE:
    c453  2a 51 f7   LHLD ARG_1 (f751)          ; Advance to the next byte of the instruction
    c456  23         INX HL
    c457  22 51 f7   SHLD ARG_1 (f751)

    c45a  c9         RET


DISASSEMBLER_PRINT_LINE:
    c45b  11 7b f7   LXI DE, f77b               ; Set pointer to the beginning of the buffer

DISASSEMBLER_PRINT_LINE_LOOP:
    c45e  1a         LDAX DE                    ; Load and print next char
    c45f  cd 28 fe   CALL GET_PRINTABLE_SYMBOL (fe28)
    c462  cd f0 f9   CALL PUT_CHAR (f9f0)

    c465  13         INX DE                     ; Advance to the next char

    c466  7b         MOV A, E                   ; Repeat until reached 0x7f95 (26 chars)
    c467  fe 95      CPI A, 95
    c469  c2 5e c4   JNZ DISASSEMBLER_PRINT_LINE_LOOP (c45e)

    c46c  c1         POP BC                     ; Stop disassembling when reached end address
    c46d  cd cc fb   CALL LOAD_ARGUMENTS (fbcc)
    c470  d8         RC

    c471  05         DCR B                      ; Decrement line counter, and repeat for next instruction
    c472  c2 fa c3   JNZ DISASSEMBLER_LINE_LOOP (c3fa)

    c475  cd 6b fc   CALL PRINT_NEW_LINE (fc6b) ; Print newline at the end

    c478  c3 d1 c3   JMP DISASSEMBLER_GET_MODE (c3d1)   ; Wait for the new disassembler command


; Move cursor to right part of the screen (to position #31)
DISASSEMBLER_MOVE_CURSOR_RIGHT:
    c47b  01 18 1f   LXI BC, 1f18               ; Will be printing 31 (0x1f) 'move right' chars (0x18)

DISASSEMBLER_MOVE_CURSOR_RIGHT_LOOP:
    c47e  cd f0 f9   CALL PUT_CHAR (f9f0)
    c481  05         DCR B
    c482  c2 7e c4   JNZ DISASSEMBLER_MOVE_CURSOR_RIGHT_LOOP (c47e)

    c485  c9         RET


; Print byte as hex in the buffer
; HL - pointer to the byte to print
; BC - pointer to the working buffer where to print the byte
; The function also adds the byte itself for symbolic printer at BC+0x13
DISASSEMBLER_PRINT_BYTE:
    c486  c5         PUSH BC                    ; Calculate buffer start + 0x13 (19 dec) offset
    c487  79         MOV A, C
    c488  c6 13      ADI A, 13
    c48a  4f         MOV C, A

    c48b  2a 51 f7   LHLD ARG_1 (f751)          ; Store the byte to disassemble there
    c48e  7e         MOV A, M
    c48f  02         STAX BC

    c490  cd c0 f9   CALL BYTE_TO_HEX (f9c0)    ; Print byte as hex at the buffer address
    c493  e3         XTHL
    c494  71         MOV M, C
    c495  23         INX HL
    c496  70         MOV M, B
    c497  23         INX HL

    c498  e3         XTHL                       ; Restore registers and exit
    c499  c1         POP BC
    c49a  c9         RET

; Calculate address in the attribute handlers table
; Having HL pointing to instruction descriptor, the function loads the attribute, and calculates the address
; in the attribute handlers table
DISASSEMBLER_GET_ATTRIBUTE_HANDLER:
    c49b  23         INX HL                     ; Load instruction attribute byte
    c49c  7e         MOV A, M

    c49d  07         RLC                        ; Multiply it by 2, and put to HL
    c49e  6f         MOV L, A
    c49f  26 00      MVI H, 00

    c4a1  11 cc c7   LXI DE, DISASSEMBLER_ATTR_HANDLERS (c7cc)  ; Calculate the element address in table
    c4a4  19         DAD DE
    c4a5  c9         RET

; Get printing handler address (HL = [HL])
DISASSEMBLER_GET_HANDLER_ADDR:
    c4a6  5e         MOV E, M
    c4a7  23         INX HL
    c4a8  56         MOV D, M
    c4a9  eb         XCHG

DISASSEMBLER_NOP:
    c4aa  c9         RET


; Print byte argument at bytes area and mnemonics area
DISASSEMBLER_PRINT_BYTE_ARG:
    c4ab  01 7d f7   LXI BC, f77b + 2 (f77d)        ; Will be printing argument at bytes area first

DISASSEMBLER_PRINT_BYTE_ARG_1:
    c4ae  cd 86 c4   CALL DISASSEMBLER_PRINT_BYTE (c486); Print the byte at bytes area
    
    c4b1  01 87 f7   LXI BC, f77b + 12 (f787)       ; Print the byte at mnemonic/argument area


; Print byte as hex at BC and advance to the next byte
DISASSEMBLER_PRINT_BYTE_AND_ADVANCE:
    c4b4  cd 86 c4   CALL DISASSEMBLER_PRINT_BYTE (c486)
    c4b7  c3 53 c4   JMP DISASSEMBLER_NEXT_BYTE (c453)


; Print 2 bytes at bytes area, and 4-digit hex at mnemonics area (as instruction argument)
DISASSEMBLER_PRINT_ADDRESS_ARG:
    c4ba  01 7d f7   LXI BC, f77b + 2 (f77d)        ; Print first byte of the argument at bytes area
    c4bd  cd 86 c4   CALL DISASSEMBLER_PRINT_BYTE (c486)

    c4c0  01 89 f7   LXI BC, f77b + 14 (f789)       ; Print it also as low byte at mnemonic area
    c4c3  cd b4 c4   CALL DISASSEMBLER_PRINT_BYTE_AND_ADVANCE (c4b4)

    c4c6  01 7f f7   LXI BC, f77b + 4 (f77f)        ; Print second byte of the argument
    c4c9  c3 ae c4   JMP DISASSEMBLER_PRINT_BYTE_ARG_1 (c4ae)


; Print register name letter to the mnemonic argument area
DISASSEMBLER_PRINT_REGISTER_ARG:
    c4cc  01 ff 01   LXI BC, 01ff               ; Register is coded in lower 3 bits (B=1)

DISASSEMBLER_PRINT_REGISTER_ARG_1:
    c4cf  21 c8 c7   LXI HL, DISASSEMBLER_REGISTER_LETTERS + 8 (c7c8)

DISASSEMBLER_PRINT_REGISTER_ARG_2:
    c4d2  cd 24 c5   CALL DISASSEMBLER_GET_REGISTER_LETTER (c524)   ; Get the letter that correspond to the
    c4d5  32 87 f7   STA f77b + 12 (f787)                           ; register and put to arguments area
    c4d8  c9         RET


; Print register pair name letter to the mnemonics argument area
DISASSEMBLER_PRINT_REGPAIR_ARG:
    c4d9  01 ff 10   LXI BC, 10ff               ; Register is coded in --xx---- bits (B=0x10)
    c4dc  21 cc c7   LXI HL, DISASSEMBLER_REGPAIR_LETTERS + 4 (c7cc)
    c4df  c3 d2 c4   JMP DISASSEMBLER_PRINT_REGISTER_ARG_2 (c4d2)


; Print register name letter to the mnemonics argument area (but different bits used for coding the register)
DISASSEMBLER_PRINT_REGISTER_ARG_3:
    c4e2  01 ff 08   LXI BC, 08ff               ; Register is coded in --xxx--- bits (B=0x08)
    c4e5  c3 cf c4   JMP DISASSEMBLER_PRINT_REGISTER_ARG_1 (c4cf)


; Print "<regpair>, value" string in arguments area
DISASSEMBLER_PRINT_LXI_ARG:
    c4e8  cd d9 c4   CALL DISASSEMBLER_PRINT_REGPAIR_ARG (c4d9) ; Print the regpair name first

    c4eb  01 8b f7   LXI BC, f77b + 0x10 (f78b)     ; Print low byte in the arguments and bytes area
    c4ee  cd 18 c5   CALL DISASSEMBLER_PRINT_BYTE_AFTER_COMMA (c518)    ; Also print comma after reg name

    c4f1  01 89 f7   LXI BC, f77b + 14 (f789)       ; Print high byte in the arguments area
    c4f4  cd 86 c4   CALL DISASSEMBLER_PRINT_BYTE (c486)

    c4f7  01 7f f7   LXI BC, f77b + 4 (f77f)        ; Print high byte in the bytes ares
    c4fa  c3 b4 c4   JMP DISASSEMBLER_PRINT_BYTE_AND_ADVANCE (c4b4)

; Print "<reg>, <reg>" string in arguments area (MOV instruction)
DISASSEMBLER_PRINT_MOV_ARG:
    c4fd  01 c7 01   LXI BC, 01c7                   ; Print destination register name
    c500  cd cf c4   CALL DISASSEMBLER_PRINT_REGISTER_ARG_1 (c4cf)

    c503  32 89 f7   STA f77b + 14 (f789)           ; Print source register name
    c506  01 f8 08   LXI BC, 08f8
    c509  cd cf c4   CALL DISASSEMBLER_PRINT_REGISTER_ARG_1 (c4cf)

; Print comma symbol after destination register name
DISASSEMBLER_PRINT_COMA:
    c50c  3e 2c      MVI A, 2c                  ; Print comma in arguments area
    c50e  32 88 f7   STA f77b + 13 (f788)
    c511  c9         RET

; Print "<reg>, <value>" string (MVI instruction)
DISASSEMBLER_PRINT_MVI_ARG:
    c512  cd e2 c4   CALL DISASSEMBLER_PRINT_REGISTER_ARG_3 (c4e2)
    c515  01 89 f7   LXI BC, f77b + 14 (f789)

; Prints ", <byte>" substring at BC. 
; Can be used with reg or regpair on the left to comma, and 1- or 2-byte argument at the right
DISASSEMBLER_PRINT_BYTE_AFTER_COMMA:
    c518  cd 86 c4   CALL DISASSEMBLER_PRINT_BYTE (c486)    ; Print the byte at BC address

    c51b  01 7d f7   LXI BC, f77b + 2 (f77d)                ; Print the same byte in bytes area
    c51e  cd b4 c4   CALL DISASSEMBLER_PRINT_BYTE_AND_ADVANCE (c4b4)

    c521  c3 0c c5   JMP DISASSEMBLER_PRINT_COMA (c50c)


; Get letter that corresponds to the register that the opcode is operating with
; Arguments:
; - HL - pointer to the register letters (1 byte after the actual data, will iterate backwards)
; - B - increment to the next register in the opcode
; - C - opcode mask
; - DE - pointer to the instruction opcode within the matched instruction descriptor
DISASSEMBLER_GET_REGISTER_LETTER:
    c524  e5         PUSH HL                    ; Get the instruction opcode
    c525  2a 51 f7   LHLD ARG_1 (f751)
    c528  2b         DCX HL
    c529  7e         MOV A, M
    c52a  e1         POP HL

    c52b  a1         ANA C                      ; Apply the mask
    c52c  4f         MOV C, A

    c52d  1a         LDAX DE                    ; Get the masked instruction opcode from the descriptor

    c52e  90         SUB B                      ; Preflight for the ADD instruction below

DISASSEMBLER_GET_REGISTER_LETTER_LOOP:
    c52f  2b         DCX HL                     ; Iterate over the register letters until opcode matches
    c530  80         ADD B

    c531  b9         CMP C                      ; Repeat until opcodes match
    c532  c2 2f c5   JNZ DISASSEMBLER_GET_REGISTER_LETTER_LOOP (c52f)

    c535  7e         MOV A, M                   ; Return the register letter
    c536  c9         RET


; Parse register pair specification
ASSEMBLER_PARSE_REGPAIR:
    c537  01 03 10   LXI BC, 1003               ; Set corresponding bitmasks
    c53a  21 c8 c7   LXI HL, DISASSEMBLER_REGPAIR_LETTERS (c7c8)
    c53d  c3 46 c5   JMP ASSEMBLER_PARSE_REG_OR_REGPAIR (c546)


ASSEMBLER_PARSE_DEST_REG:
    c540  01 07 08   LXI BC, 0807               ; B - opcode increment, C - 8 registers to match

ASSEMBLER_PARSE_REG:
    c543  21 c0 c7   LXI HL, DISASSEMBLER_REGISTER_LETTERS (c7c0)   ; Go through register letters list

ASSEMBLER_PARSE_REG_OR_REGPAIR:
    c546  32 ff f7   STA VALUE_SIGN (f7ff)      ; Store basic opcode

    c549  cd bb c5   CALL ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb)    ; Skip spaces till register name

ASSEMBLER_MATCH_REG_LOOP:
    c54c  be         CMP M                      ; Compare register letter
    c54d  ca 5a c5   JZ ASSEMBLER_REG_MATCHED (c55a)

    c550  23         INX HL                     ; Advance to the next register letter, until all 8 registers
    c551  0d         DCR C                      ; are matched
    c552  f2 4c c5   JP ASSEMBLER_MATCH_REG_LOOP (c54c)


ASSEMBLER_MATCH_ERROR:
    c555  d1         POP DE                     ; Restore stack value, then report an error

ASSEMBLER_MATCH_ERROR_1:
    c556  37         STC                        ; Set flag indicating an error
    c557  c3 8d fb   JMP INPUT_ERROR_1 (fb8d)   ; Report input error (beep and ? symbol, exit to monitor)


ASSEMBLER_REG_MATCHED:
    c55a  13         INX DE                     ; Advance to the next input symbol

    c55b  cd 0b fc   CALL DO_PARSE_HEX (fc0b)   ; Perhaps register letters A/B/C/D/E may in fact be a start
    c55e  da 55 c5   JC ASSEMBLER_MATCH_ERROR (c555); of a hex value. Report an error if any value is matched

    c561  7c         MOV A, H                   ; Report an error if non-zero hex value is matched
    c562  b5         ORA L
    c563  c2 55 c5   JNZ ASSEMBLER_MATCH_ERROR (c555)

    c566  cd d5 c8   CALL ASSEMBLER_SET_BUF_OFFSET (c8d5)   ; Advance input pointer to the next symbol
    c569  3a ff f7   LDA VALUE_SIGN (f7ff)

ASSEMBLER_GENERATE_OPCODE_ON_REG_SPEC:
    c56c  81         ADD C                      ; Generate the instruction opcode based on register
    c56d  05         DCR B                      ; specification
    c56e  c2 6c c5   JNZ ASSEMBLER_GENERATE_OPCODE_ON_REG_SPEC (c56c)

    c571  c9         RET


; Parse @<label>
;
; The function parses 2-digit hexadecimal value after @ symbol (@ symbol itself is parsed outside of this
; function). The parsed 8-bit value is an index in the table of labels located at 0xf400-0xf600. The function
; returns an address within the table that corresponds the parsed index.
;
; Return:
; HL - pointer to the 16-bit label in the labels table
; C flag set in case of error
ASSEMBLER_PARSE_LABEL_ADDRESS:
    c572  cd 0b fc   CALL DO_PARSE_HEX (fc0b)   ; Parse the value
    c575  d8         RC                         ; Return in case of error

    c576  7c         MOV A, H                   ; Verify that high byte is zero. Raise C flag in case of
    c577  b7         ORA A                      ; error (parsed value > 255)
    c578  37         STC
    c579  c0         RNZ

    c57a  26 7a      MVI H, 7a                  ; Calculate address of the 2-byte value in the 0xf400-0xf600
    c57c  29         DAD HL                     ; table (0x7a * 2 = 0xf4)
    c57d  c9         RET


; Parse a single instruction
;
; Arguments:
; HL    - Target address where to store bytecode
; 
; The function skips spaces at the line beginning, then matches instruction mnemonic with the descriptors list.
; In case if instruction is matched, the function runs parsing handler to process instruction arguments.
ASSEMBLER_PARSE_INSTRUCTION:
    c57e  11 cd c5   LXI DE, INSTRUCTION_DESCRIPTORS (c5cd) ; Iterate through the instruction desriptors list

DO_PARSE_INSTRUCTION_LOOP:
    c581  cd b0 fd   CALL RESET_COMMAND_MODE_FLAG (fdb0)    ; Command flag will indicate instruction mismatch

    c584  eb         XCHG                                   ; Find first non-space character
    c585  cd bb c5   CALL ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb)
    c588  eb         XCHG

    c589  06 04      MVI B, 04                  ; Match 4-char instruction mnemonic

DO_PARSE_MNEMONIC_LOOP:
    c58b  1a         LDAX DE                    ; Stop parsing if char code >= 0x80 found
    c58c  b7         ORA A
    c58d  fa 56 c5   JM ASSEMBLER_MATCH_ERROR_1 (c556)

    c590  be         CMP M                      ; Compare next byte of the mnemonic
    c591  c4 b5 fd   CNZ SET_COMMAND_MODE_FLAG (fdb5)   ; Set the flag in case of mismatch
                                                ; Bug! This loop fails to match instructions that are shorter
                                                ; than 4 chars (e.g. DI). User has to type all 4 chars padded
                                                ; with spaces explicitly ("DI  ") so that instruction name
                                                ; can be matched

    c594  13         INX DE                     ; Advance to the next char
    c595  23         INX HL

    c596  05         DCR B                      ; Repeat until all 4 chars of the mnemonic matched
    c597  c2 8b c5   JNZ DO_PARSE_MNEMONIC_LOOP (c58b)

    c59a  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; Load the 'match failed' flag

    c59d  13         INX DE                     ; Skip instruction code and attribute byte, ready to match
    c59e  13         INX DE                     ; next descriptor

    c59f  c2 81 c5   JNZ DO_PARSE_INSTRUCTION_LOOP (c581)   ; Repeat for the next descriptor

    
    c5a2  1b         DCX DE                     ; Instruction matched, get back to instruction opcode
    c5a3  1b         DCX DE

    c5a4  eb         XCHG                       ; Store argument offset
    c5a5  cd d5 c8   CALL ASSEMBLER_SET_BUF_OFFSET (c8d5)

    c5a8  46         MOV B, M                   ; Find the parsing handler for the instruction
    c5a9  cd 9b c4   CALL DISASSEMBLER_GET_ATTRIBUTE_HANDLER (c49b)
    c5ac  cd a6 c4   CALL DISASSEMBLER_GET_HANDLER_ADDR (c4a6)

    c5af  78         MOV A, B                   ; Load instruction opcode in A

    c5b0  e9         PCHL                       ; Execute the parsing handler



; Parse command line arguments if they are specified
PARSE_ARGUMENTS_IF_SPECIFIED:
    c5b1  1a         LDAX DE                    ; Check if any argument is specified
    c5b2  fe 0d      CPI A, 0d

    c5b4  c4 c9 fb   CNZ DO_PARSE_AND_LOAD_ARGUMENTS_ALT (fbc9) ; Parse arguments
    c5b7  dc b9 fb   CC REPORT_INPUT_ERROR (fbb9)   ; Report error if needed
    c5ba  c9         RET


; Search through input string (starting current position) for a non-space character
ASSEMBLER_SEARCH_NON_SPACE_CHAR:
    c5bb  16 f7      MVI D, f7                  ; Set address of next byte to parse to DE (in 0xf77b buffer)
    c5bd  3a 59 f7   LDA BUF_OFFSET (f759)
    c5c0  5f         MOV E, A

    c5c1  1a         LDAX DE                    ; Stop if non-space char is found
    c5c2  fe 20      CPI A, 20
    c5c4  c0         RNZ

ASSEMBLER_ADVANCE_TO_NEXT_ARG:
    c5c5  13         INX DE                     ; Advance to the next byte

    c5c6  cd d5 c8   CALL ASSEMBLER_SET_BUF_OFFSET (c8d5)
    c5c9  c3 bb c5   JMP ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb)


; List of CPU instructions. Each record contains:
; - 4-char mnemonic
; - opcode
; - instruction attribute code
;
; Attribute codes are (for assembler, disassembler, and relocator):
;   - 0x00  - 1-byte instruction
;   - 0x01  - 2-byte instruction, 2nd byte is immediate value
;   - 0x02  - 3-byte instruction, argument is an 2-byte address
;   - 0x03  - 1-byte instruction, argument is a source register name (register is coded by -----xxx bits)
;   - 0x04  - 1-byte instruction, argument is a register pair name (register is coded by --xx---- bits)
;   - 0x05  - 1-byte instruction, argument is a destination register name (register is coded by --xxx--- bits)
;   - 0X06  - 3-byte instruction, argument is a register pair name (register is coded by ---x---- bits)
;   - 0x07  - 3-byte instruction, argument may be an address, but not necessarily (LXI instruction)
;   - 0x08  - 1-byte instruction, argument is 2 registers (coded --dddsss, typically MOV instruction)
;   - 0x09  - 1-byte DB pseudo instruction, 2nd byte is immediate value (arg not printed by handler)
; Additional attribute codes specific for Assembler/parser only:
;   - 0x0a  - DB directive, argument is one byte, or several bytes split with comma
;   - 0x0b  - EQU directive
;   - 0x0c  - ORG directive
;   - 0x0d  - DW directive
;   - 0x0e  - DIR directive
INSTRUCTION_DESCRIPTORS:
    c5cd  41 43 49 20     db "ACI ", 0xce, 0x01
    c5d3  41 44 43 20     db "ADC ", 0x88, 0x03
    c5d9  41 44 44 20     db "ADD ", 0x80, 0x03
    c5df  41 44 49 20     db "ADI ", 0xc6, 0x01
    c5e5  41 4e 41 20     db "ANA ", 0xa0, 0x03
    c5eb  41 4e 49 20     db "ANI ", 0xe6, 0x01
    c5f1  43 41 4c 4c     db "CALL", 0xcd, 0x02
    c5f7  43 43 20 20     db "CC  ", 0xdc, 0x02
    c5fd  43 4d 20 20     db "CM  ", 0xfc, 0x02
    c603  43 4d 41 20     db "CMA ", 0x2f, 0x00
    c609  43 4d 43 20     db "CMC ", 0x3f, 0x00
    c60f  43 4d 50 20     db "CMP ", 0xb8, 0x03
    c615  43 4e 43 20     db "CNC ", 0xd4, 0x02
    c61b  43 4e 5a 20     db "CNZ ", 0xc4, 0x02
    c621  43 50 20 20     db "CP  ", 0xf4, 0x02
    c627  43 50 45 20     db "CPE ", 0xec, 0x02
    c62d  43 50 49 20     db "CPI ", 0xfe, 0x01
    c633  43 50 4f 20     db "CPO ", 0xe4, 0x02
    c639  43 5a 20 20     db "CZ  ", 0xcc, 0x02
    c63f  44 41 41 20     db "DAA ", 0x27, 0x00
    c645  44 41 44 20     db "DAD ", 0x09, 0x04
    c64b  44 43 52 20     db "DCR ", 0x05, 0x05
    c651  44 43 58 20     db "DCX ", 0x0b, 0x04
    c657  44 49 20 20     db "DI  ", 0xf3, 0x00
    c65d  45 49 20 20     db "EI  ", 0xfb, 0x00
    c663  48 4c 54 20     db "HLT ", 0x76, 0x00
    c669  49 4e 20 20     db "IN  ", 0xdb, 0xa1     ; BUG! Attr 0xa1 causes crash. Must be 0x01 (2-byte op)
    c66f  49 4e 52 20     db "INR ", 0x04, 0x05
    c675  49 4e 58 20     db "INX ", 0x03, 0x04
    c67b  4a 43 20 20     db "JC  ", 0xda, 0x02
    c681  4a 4d 20 20     db "JM  ", 0xfa, 0x02
    c687  4a 4d 50 20     db "JMP ", 0xc3, 0x02
    c68d  4a 4e 43 20     db "JNC ", 0xd2, 0x02
    c693  4a 4e 5a 20     db "JNZ ", 0xc2, 0x02
    c699  4a 50 20 20     db "JP  ", 0xf2, 0x02
    c69f  4a 50 45 20     db "JPE ", 0xea, 0x02
    c6a5  4a 50 4f 20     db "JPO ", 0xe2, 0x02
    c6ab  4a 5a 20 20     db "JZ  ", 0xca, 0x02
    c6b1  4c 44 41 20     db "LDA ", 0x3a, 0x02
    c6b7  4c 44 41 58     db "LDAX", 0x0a, 0x06
    c6bd  4c 48 4c 44     db "LHLD", 0x2a, 0x02
    c6c3  4c 58 49 20     db "LXI ", 0x01, 0x07
    c6c9  4d 4f 56 20     db "MOV ", 0x40, 0x08
    c6cf  4d 56 49 20     db "MVI ", 0x06, 0x09
    c6d5  4e 4f 50 20     db "NOP ", 0x00, 0x00
    c6db  4f 52 41 20     db "ORA ", 0xb0, 0x03
    c6e1  4f 52 49 20     db "ORI ", 0xf6, 0x01
    c6e7  4f 55 54 20     db "OUT ", 0xd3, 0xa1     ; BUG! Attr 0xa1 causes crash. Must be 0x01 (2-byte op)
    c6ed  50 43 48 4c     db "PCHL", 0xe9, 0x00
    c6f3  50 4f 50 20     db "POP ", 0xc1, 0x04
    c6f9  50 55 53 48     db "PUSH", 0xc5, 0x04
    c6ff  52 41 4c 20     db "RAL ", 0x17, 0x00
    c705  52 41 52 20     db "RAR ", 0x1f, 0x00
    c70b  52 43 20 20     db "RC  ", 0xd8, 0x00
    c711  52 45 54 20     db "RET ", 0xc9, 0x00
    c717  52 4c 43 20     db "RLC ", 0x07, 0x00
    c71d  52 4d 20 20     db "RM  ", 0xf8, 0x00
    c723  52 4e 43 20     db "RNC ", 0xd0, 0x00
    c729  52 4e 5a 20     db "RNZ ", 0xc0, 0x00
    c72f  52 50 20 20     db "RP  ", 0xf0, 0x00
    c735  52 50 45 20     db "RPE ", 0xe8, 0x00
    c73b  52 50 4f 20     db "RPO ", 0xe0, 0x00
    c741  52 52 43 20     db "RRC ", 0x0f, 0x00
    c747  52 53 54 20     db "RST ", 0xc7, 0x05
    c74d  52 5a 20 20     db "RZ  ", 0xc8, 0x00
    c753  53 42 42 20     db "SBB ", 0x98, 0x03
    c759  53 42 49 20     db "SBI ", 0xde, 0x01
    c75f  53 48 4c 44     db "SHLD", 0x22, 0x02
    c765  53 50 48 4c     db "SPHL", 0xf9, 0x00
    c76b  53 54 41 20     db "STA ", 0x32, 0x02
    c771  53 54 41 58     db "STAX", 0x02, 0x06
    c777  53 54 43 20     db "STC ", 0x37, 0x00
    c77d  53 55 42 20     db "SUB ", 0x90, 0x03
    c783  53 55 49 20     db "SUI ", 0xd6, 0x01
    c789  58 43 48 47     db "XCHG", 0xeb, 0x00
    c78f  58 52 41 20     db "XRA ", 0xa8, 0x03
    c795  58 52 49 20     db "XRI ", 0xee, 0x01
    c79b  58 54 48 4c     db "XTHL", 0xe3, 0x00
INSTRUCTION_DESCRIPTORS_DB:                         ; Records specific for assembler
    c7a1  44 42 20 20     db "DB  ", 0x00, 0x0a
    c7a7  45 51 55 20     db "EQU ", 0x00, 0x0b
    c7ad  4f 52 47 20     db "ORG ", 0x00, 0x0c
    c7b3  44 57 20 20     db "DW  ", 0x00, 0x0d
    c7b9  44 49 52 20     db "DIR ", 0x00, 0x0e

    c7bf  ff                                        ; End marker


DISASSEMBLER_REGISTER_LETTERS:
    c7c0  41 4d 4c 48 45 44 43 42   db "AMLHEDCB"

DISASSEMBLER_REGPAIR_LETTERS:
    c7c8  53 48 44 42               db "SHDB"

DISASSEMBLER_ATTR_HANDLERS:
    ; Argument parsing handlers
    c7cc  da c8         dw ASSEMBLER_PARSE_NO_ARGS (c8da)
    c7ce  e3 c8         dw ASSEMBLER_PARSE_BYTE_ARG (c8e3)
    c7d0  f3 c8         dw ASSEMBLER_PARSE_WORD_ARG (c8f3)
    c7d2  29 c9         dw ASSEMBLER_PARSE_SRC_REG_ARG (c929)
    c7d4  32 c9         dw ASSEMBLER_PARSE_REGPAIR_ARG (c932)
    c7d6  38 c9         dw ASSEMBLER_PARSE_DST_REG_ARG (c938)
    c7d8  3e c9         dw ASSEMBLER_PARSE_REGPAIR_ARG_2 (c93e)
    c7da  4a c9         dw ASSEMBLER_PARSE_LXI_ARG (c94a)
    c7dc  50 c9         dw ASSEMBLER_PARSE_MOV_ARG (c950)
    c7de  56 c9         dw ASSEMBLER_PARSE_MVI_ARG (c956)
    c7e0  76 c9         dw ASSEMBLER_PARSE_DB_ARG (c976)
    c7e2  5c c9         dw ASSEMBLER_PARSE_EQU_ARG (c95c)
    c7e4  b9 c9         dw ASSEMBLER_PARSE_ORG_ARG (c9b9)
    c7e6  d2 c9         dw ASSEMBLER_PARSE_DW_ARG (c9d2)
    c7e8  df c9         dw ASSEMBLER_PARSE_DIR_ARG (c9df)

    ; Argument printing handlers
    c7ea  aa c4         dw DISASSEMBLER_NOP (c4aa)              ; No need to print arguments for 1-byte opcodes
    c7ec  ab c4         dw DISASSEMBLER_PRINT_BYTE_ARG (c4ab)
    c7ee  ba c4         dw DISASSEMBLER_PRINT_ADDRESS_ARG (c4ba)
    c7f0  cc c4         dw DISASSEMBLER_PRINT_REGISTER_ARG (c4cc)
    c7f2  d9 c4         dw DISASSEMBLER_PRINT_REGPAIR_ARG (c4d9)
    c7f4  e2 c4         dw DISASSEMBLER_PRINT_REGISTER_ARG_3 (c4e2)
    c7f6  d9 c4         dw DISASSEMBLER_PRINT_REGPAIR_ARG (c4d9)
    c7f8  e8 c4         dw DISASSEMBLER_PRINT_LXI_ARG (c4e8)
    c7fa  fd c4         dw DISASSEMBLER_PRINT_MOV_ARG (c4fd)
    c7fc  12 c5         dw DISASSEMBLER_PRINT_MVI_ARG (c512)
    c7fe  aa c4         dw DISASSEMBLER_NOP (c4aa)


; Parse assembler instruction line
;
; This function parses a line of the following format:
; [@<label>:] <instruction> [arguments]
;
; The line is expected in the line buffer starting 0xf77b
;
; The instruction must be either CPU instruction mnemonic, or an assembler language directive (e.g. ORG,
; DB, EQU, etc). The function searches for an instruction descriptor. Attribute byte in the descriptor
; indicates a function that shall be used to parse argument, and actually generate the opcode.
;
; The label (if specified) must start with @ symbol and contain 2 hex digits. The label shall be finalized
; with a non-space character (typically ':'). The label is an index in labels table (0xf400-0xf600). 
; Parsed command offset is stored at the label table at the corresponding index. Labels may be referrenced
; by other instructions, and are actually substituted at the code during assembler pass #2 (see command @)
;
; Symbols after semicolon are considered as comments, and ignored.
ASSEMBLER_PARSE_INSTRUCTION_LINE:
    c800  3e 7b      MVI A, 7b                  ; Set buffer start as 0xf77b
    c802  32 59 f7   STA BUF_OFFSET (f759)

    c805  cd bb c5   CALL ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb); Skip spaces at the beginning

    c808  fe 0d      CPI A, 0d                  ; Do not parse if nothing is entered (empty line)
    c80a  ca b5 fd   JZ SET_COMMAND_MODE_FLAG (fdb5)    ; Raise the stop parsing flag

    c80d  b7         ORA A                      ; Also stop parsing if char >= 0x80 is found
    c80e  fa b5 fd   JM SET_COMMAND_MODE_FLAG (fdb5)

    c811  fe 3b      CPI A, 3b                  ; ';' means comment. Stop parsing this line, ready to parse next
    c813  ca b0 fd   JZ RESET_COMMAND_MODE_FLAG (fdb0)

    c816  cd 73 c2   CALL CHECK_AT_SYMBOL (c273)    ; Process label if specified
    c819  cc 22 c8   CZ ASSEMBLER_PARSE_LABEL (c822)

    c81c  cd 7e c5   CALL ASSEMBLER_PARSE_INSTRUCTION (c57e)    ; Actually parse the instruction

    c81f  c3 b0 fd   JMP RESET_COMMAND_MODE_FLAG (fdb0) ; Exit, ready to parse next instruction


; Parse @<label> instruction
;
; The function parses the label (2-digit hex), calculates the address in the labels table (0xf400 + 2 * label)
; Finally the function stores current destination offset (arg #2) to the entry in the labels table. Note, 
; that arg#2 may be altered with ORG directive, and may not equal the output byte address.
ASSEMBLER_PARSE_LABEL:
    c822  cd 72 c5   CALL ASSEMBLER_PARSE_LABEL_ADDRESS (c572)  ; Parse the label index, get the address
    c825  da 8d fb   JC INPUT_ERROR_1 (fb8d)

    c828  cd d5 c8   CALL ASSEMBLER_SET_BUF_OFFSET (c8d5)   ; Advance the input string pointer
    c82b  eb         XCHG

    c82c  2a 53 f7   LHLD ARG_2 (f753)          ; Load the current target address

; [DE] = HL
SAVE_HL_AT_DE:
    c82f  7d         MOV A, L
    c830  12         STAX DE
    c831  13         INX DE
    c832  7c         MOV A, H
    c833  12         STAX DE
    c834  c9         RET

; Parse immediate 1- or 2-byte value
;
; The function parses an immediate value provided as instruction argument. The following features are
; supported:
; - single hex value (e.g. 5A). 
; - decimal values (value started with #, e.g. #123)
; - symbolic char values (e.g. 'Q')
; - Reference to a label (e.g. @12)
; - $ symbol represents 'current instruction address'
;
; It is possible to use + and - arithmetic in the expression (e.g. $ - 5A + #123 - 'Q')
;
; Depending on instruction type, the value can be 1 or 2 bytes. If the value exceeds 1 byte for 2-byte
; instructions (1 byte argument), the only low byte will be used
;
; Return value in BC
ASSEMBLER_PARSE_IMMEDIATE:
    c835  af         XRA A                      ; Zero value accumulator in BC (in case of +/- arithmetics
    c836  47         MOV B, A                   ; used)
    c837  4f         MOV C, A

    c838  3d         DCR A                      ; A != 0 indicating parsed value will be added to accumulator

ASSEMBLER_PARSE_IMMEDIATE_LOOP:
    c839  32 ff f7   STA VALUE_SIGN (f7ff)      ; Save plus/minus flag

    c83c  cd bb c5   CALL ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb)    ; Search for the argument

    c83f  cd 73 c2   CALL CHECK_AT_SYMBOL (c273); Process label reference, if specified (@)
    c842  ca 7a c8   JZ ASSEMBLER_PARSE_LABEL_REF (c87a)

    c845  fe 27      CPI A, 27                  ; Single quote starts a letter symbol
    c847  ca 95 c8   JZ ASSEMBLER_PARSE_IMMEDIATE_SYMB (c895)

    c84a  fe 23      CPI A, 23                  ; Decimal numbers start with '#'
    c84c  ca a8 c8   JZ ASSEMBLER_PARSE_DECIMAL (c8a8)

    c84f  fe 24      CPI A, 24                  ; Set the current instruction address on '$'
    c851  ca 8b c8   JZ ASSEMBLER_PARSE_IMMEDIATE_CUR_ADDR (c88b)

    c854  cd 0b fc   CALL DO_PARSE_HEX (fc0b)   ; Parse the hex value
    c857  da 55 c5   JC ASSEMBLER_MATCH_ERROR (c555)    ; Report error in case of syntax error

ASSEMBLER_PARSE_IMMEDIATE_1:
    c85a  f5         PUSH PSW                   ; Save char to parse temporarily

ASSEMBLER_PARSE_IMMEDIATE_2:
    c85b  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; Check if the operand needs to be subtracted from
    c85e  c2 68 c8   JNZ ASSEMBLER_PARSE_IMMEDIATE_3 (c868) ; result accumulator

    c861  7d         MOV A, L                   ; Negate the parsed hex value, so that the following 
    c862  2f         CMA                        ; addition operation will in fact do a subtraction
    c863  6f         MOV L, A

    c864  7c         MOV A, H                   ; HL = ~HL + 1
    c865  2f         CMA
    c866  67         MOV H, A

    c867  23         INX HL

ASSEMBLER_PARSE_IMMEDIATE_3:
    c868  cd d5 c8   CALL ASSEMBLER_SET_BUF_OFFSET (c8d5)   ; Save the offset

    c86b  f1         POP PSW                    ; Add parsed value to the result accumulator in BC
    c86c  09         DAD BC
    c86d  44         MOV B, H
    c86e  4d         MOV C, L

    c86f  d6 2d      SUI A, 2d                  ; Check if the next symbol is '-' ...
    c871  ca 39 c8   JZ ASSEMBLER_PARSE_IMMEDIATE_LOOP (c839)

    c874  fe fe      CPI A, fe                  ; ... or '+'. If so - go and parse another value. The result
    c876  ca 39 c8   JZ ASSEMBLER_PARSE_IMMEDIATE_LOOP (c839)   ; of comparison will be stored as 0xf7ff flag

    c879  c9         RET                        ; Return parsed value as is

; Parse @<label> label reference. Use value at the reference
ASSEMBLER_PARSE_LABEL_REF:
    c87a  cd 72 c5   CALL ASSEMBLER_PARSE_LABEL_ADDRESS (c572)  ; Parse the reference, and get the address in
    c87d  da 55 c5   JC ASSEMBLER_MATCH_ERROR (c555)            ; the labels table

    c880  1b         DCX DE                     ; Load the next input byte
    c881  1a         LDAX DE
    c882  13         INX DE

    c883  f5         PUSH PSW                   ; Load the reference value to HL
    c884  7e         MOV A, M
    c885  23         INX HL
    c886  66         MOV H, M
    c887  6f         MOV L, A

    c888  c3 5b c8   JMP ASSEMBLER_PARSE_IMMEDIATE_2 (c85b) ; Continue with loaded value as it would be 
                                                            ; immediate value

; Parse $ symbol, treating it as 'current instruction address'
ASSEMBLER_PARSE_IMMEDIATE_CUR_ADDR:
    c88b  cd c5 c5   CALL ASSEMBLER_ADVANCE_TO_NEXT_ARG (c5c5)  ; Advance to the next input byte
    c88e  13         INX DE

    c88f  2a 53 f7   LHLD ARG_2 (f753)          ; Use current instruction address as immediate value
    c892  c3 5a c8   JMP ASSEMBLER_PARSE_IMMEDIATE_1 (c85a)

; Parse symbolic value (e.g. 'Q')
ASSEMBLER_PARSE_IMMEDIATE_SYMB:
    c895  13         INX DE                     ; Load the symbol in quotes
    c896  1a         LDAX DE

    c897  26 00      MVI H, 00                  ; Put the value to HL as it would be when parsing immediate
    c899  6f         MOV L, A                   ; value

    c89a  13         INX DE                     ; Verify there is a closing single quote
    c89b  1a         LDAX DE
    c89c  fe 27      CPI A, 27
    c89e  c2 55 c5   JNZ ASSEMBLER_MATCH_ERROR (c555)

    c8a1  cd c5 c5   CALL ASSEMBLER_ADVANCE_TO_NEXT_ARG (c5c5)  ; Get prepared to the next argument

; Submit the value for processing
ASSEMBLER_PARSE_IMMEDIATE_FINISH:
    c8a4  13         INX DE                     ; Continue with the symbolic value as immediate argument
    c8a5  c3 5a c8   JMP ASSEMBLER_PARSE_IMMEDIATE_1 (c85a)


; Parse decimal number
; On each iteration the result accumulator is multiplied by 10, and newly parsed digit is added
ASSEMBLER_PARSE_DECIMAL:
    c8a8  21 00 00   LXI HL, 0000               ; Clear result accumulator

ASSEMBLER_PARSE_DECIMAL_LOOP:
    c8ab  cd c5 c5   CALL ASSEMBLER_ADVANCE_TO_NEXT_ARG (c5c5)  ; Get prepared for parsing next digit (if any)

    c8ae  fe 30      CPI A, 30                  ; Non-digit (< 0x30) char stops the parsing
    c8b0  da a4 c8   JC ASSEMBLER_PARSE_IMMEDIATE_FINISH (c8a4)

    c8b3  fe 3a      CPI A, 3a                  ; Non-digit (> 0x39) char stops the parsing
    c8b5  d2 a4 c8   JNC ASSEMBLER_PARSE_IMMEDIATE_FINISH (c8a4) 

    c8b8  d6 30      SUI A, 30                  ; Convert to binary

    c8ba  d5         PUSH DE                    ; Push the error handler address
    c8bb  11 ce c8   LXI DE, ASSEMBLER_PARSE_DECIMAL_NEXT (c8ce)
    c8be  d5         PUSH DE

    c8bf  29         DAD HL                     ; HL *= 2

    c8c0  d8         RC

    c8c1  54         MOV D, H                   ; HL *= 5
    c8c2  5d         MOV E, L
    c8c3  29         DAD HL
    c8c4  d8         RC
    c8c5  29         DAD HL
    c8c6  d8         RC
    c8c7  19         DAD DE
    c8c8  d8         RC

    c8c9  5f         MOV E, A                   ; Add the lower digit
    c8ca  16 00      MVI D, 00
    c8cc  19         DAD DE
    c8cd  d1         POP DE

ASSEMBLER_PARSE_DECIMAL_NEXT:
    c8ce  d1         POP DE                     ; Report error in case of overflow
    c8cf  da 55 c5   JC ASSEMBLER_MATCH_ERROR (c555)

    c8d2  c3 ab c8   JMP c8ab                   ; Repeat for the next byte


; Set the input char pointer in a variable, and free up E register
ASSEMBLER_SET_BUF_OFFSET:
    c8d5  7b         MOV A, E
    c8d6  32 59 f7   STA BUF_OFFSET (f759)
    c8d9  c9         RET

; Parse instruction with no arguments
; Instruction opcode is just copied to the target address
ASSEMBLER_PARSE_NO_ARGS:
ASSEMBLER_STORE_OUTPUT_BYTE:
    c8da  2a 53 f7   LHLD ARG_2 (f753)          ; Store instruction at destination address
    c8dd  77         MOV M, A 

    c8de  23         INX HL                     ; Advance target address and exit
    c8df  22 53 f7   SHLD ARG_2 (f753)          
    c8e2  c9         RET

; Parse instruction with immediate 1-byte argument
; Save instruction opcode and argument value to the target address
ASSEMBLER_PARSE_BYTE_ARG:
    c8e3  32 60 f7   STA INSTRUCTION_BYTE (f760)    ; Temporary store instruction byte

ASSEMBLER_PARSE_BYTE_ARG_1:
    c8e6  cd 35 c8   CALL ASSEMBLER_PARSE_IMMEDIATE (c835)  ; Parse the value

ASSEMBLER_PARSE_BYTE_ARG_2:
    c8e9  3a 60 f7   LDA INSTRUCTION_BYTE (f760)    ; Restore instruction byte

ASSEMBLER_STORE_2_BYTES:
    c8ec  cd da c8   CALL ASSEMBLER_STORE_OUTPUT_BYTE (c8da)    ; Store instruction byte to output

    c8ef  79         MOV A, C                                   ; Store argument byte to output as well
    c8f0  c3 da c8   JMP ASSEMBLER_STORE_OUTPUT_BYTE (c8da)     ; (low byte only)


; Parse argument with 2-byte immediate value
; If the argument is a label reference, the reference address is stored as an argument. This allows
; reference processing at phase2 of the compilation
; If the argument is a label reference as a part of arithmetic expression, reference value will be
; substituted immediately, and the overall expression is calculated during compile time
ASSEMBLER_PARSE_WORD_ARG:
    c8f3  32 60 f7   STA INSTRUCTION_BYTE (f760)    ; Save the instruction byte

    c8f6  cd bb c5   CALL ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb)    ; Search for the argument

    c8f9  cd 73 c2   CALL CHECK_AT_SYMBOL (c273)    ; Check if reference is specified
    c8fc  c2 1a c9   JNZ ASSEMBLER_PARSE_WORD_ARG_IMMEDIATE (c91a)  ; Parse other types as usual

    c8ff  cd 72 c5   CALL ASSEMBLER_PARSE_LABEL_ADDRESS (c572)  ; Calculate the reference label address
    c902  da 56 c5   JC ASSEMBLER_MATCH_ERROR_1 (c556)
    
    c905  1b         DCX DE                     ; Load the symbol after the reference
    c906  1a         LDAX DE

    c907  fe 2b      CPI A, 2b                  ; if '+' is detected, whole expression will be re-processed
    c909  ca 1a c9   JZ ASSEMBLER_PARSE_WORD_ARG_IMMEDIATE (c91a)   ; by ASSEMBLER_PARSE_IMMEDIATE

    c90c  fe 2d      CPI A, 2d                  ; if '-' is detected, whole expression will be re-processed
    c90e  ca 1a c9   JZ ASSEMBLER_PARSE_WORD_ARG_IMMEDIATE (c91a)   ; by ASSEMBLER_PARSE_IMMEDIATE

    c911  e5         PUSH HL                    ; Store instruction and low byte of the reference
    c912  4d         MOV C, L
    c913  cd e9 c8   CALL ASSEMBLER_PARSE_BYTE_ARG_2 (c8e9)

    c916  f1         POP PSW                    ; Store high byte of the reference
    c917  c3 da c8   JMP ASSEMBLER_STORE_OUTPUT_BYTE (c8da)


; Parse 16-bit immediate argument, store opcode and 2-byte argument at target address
ASSEMBLER_PARSE_WORD_ARG_IMMEDIATE:
    c91a  e1         POP HL                     ; Temporary save return address
    c91b  22 5e f7   SHLD f75e

    c91e  cd e6 c8   CALL ASSEMBLER_PARSE_BYTE_ARG_1 (c8e6) ; Parse argument to BC, store opcode and low byte

    c921  78         MOV A, B                   ; Store high byte
    c922  cd da c8   CALL ASSEMBLER_STORE_OUTPUT_BYTE (c8da)

    c925  2a 5e f7   LHLD f75e                  ; Restore return address and execute there
    c928  e9         PCHL


; Parse src register specification as instruction argument, store resulting opcode to output
ASSEMBLER_PARSE_SRC_REG_ARG:
    c929  01 07 01   LXI BC, 0107               ; Parse register and convert it into corresponding bits in
    c92c  cd 43 c5   CALL ASSEMBLER_PARSE_REG (c543)    ; the opcode

    c92f  c3 da c8   JMP ASSEMBLER_STORE_OUTPUT_BYTE (c8da) ; Store the opcode in the output


; Parse register pair specification as instruction argument, store resulting opcode to output
ASSEMBLER_PARSE_REGPAIR_ARG:
    c932  cd 37 c5   CALL ASSEMBLER_PARSE_REGPAIR (c537)
    c935  c3 da c8   JMP ASSEMBLER_STORE_OUTPUT_BYTE (c8da)


; Parse dst register specification as instruction argument, store resulting opcode to output
ASSEMBLER_PARSE_DST_REG_ARG:
    c938  cd 40 c5   CALL ASSEMBLER_PARSE_DEST_REG (c540)
    c93b  c3 da c8   JMP ASSEMBLER_STORE_OUTPUT_BYTE (c8da)


; Parse register pair name as instruction argument, store resulting opcode to output
ASSEMBLER_PARSE_REGPAIR_ARG_2:
    c93e  01 01 10   LXI BC, 1001                   ; Parse register name
    c941  21 ca c7   LXI HL, DISASSEMBLER_REGPAIR_LETTERS + 2 (c7ca)
    c944  cd 46 c5   CALL ASSEMBLER_PARSE_REG_OR_REGPAIR (c546)

    c947  c3 da c8   JMP ASSEMBLER_STORE_OUTPUT_BYTE (c8da) ; Store the opcode


; Parse LXI argument regpair and immediate value, store resulting opcode to output
ASSEMBLER_PARSE_LXI_ARG:
    c94a  cd 37 c5   CALL ASSEMBLER_PARSE_REGPAIR (c537)
    c94d  c3 f3 c8   JMP ASSEMBLER_PARSE_WORD_ARG (c8f3)


; Parse MOV arguments (two register names), store resulting opcode to output
ASSEMBLER_PARSE_MOV_ARG:
    c950  cd 40 c5   CALL ASSEMBLER_PARSE_DEST_REG (c540)
    c953  c3 29 c9   JMP ASSEMBLER_PARSE_SRC_REG_ARG (c929)


; Parse MVI arguments (register, and immediate value), store resulting opcode to output
ASSEMBLER_PARSE_MVI_ARG:
    c956  cd 40 c5   CALL ASSEMBLER_PARSE_DEST_REG (c540)
    c959  c3 e3 c8   JMP ASSEMBLER_PARSE_BYTE_ARG (c8e3)


; Parse EQU expression according to the next syntax:
; @<label>: EQU <value>
;
; Where label has to be a 2-digit hex (label reference), and value corresponds to ASSEMBLER_PARSE_IMMEDIATE
; requirements
ASSEMBLER_PARSE_EQU_ARG:
    c95c  cd 35 c8   CALL ASSEMBLER_PARSE_IMMEDIATE (c835)  ; Parse the value right to EQU directive (into BC)

    c95f  1e 7a      MVI E, 7a                              ; Get back to the beginning of the line
    c961  cd c5 c5   CALL ASSEMBLER_ADVANCE_TO_NEXT_ARG (c5c5)

    c964  cd 73 c2   CALL CHECK_AT_SYMBOL (c273)            ; Verify the line starts with the label reference
    c967  c2 56 c5   JNZ ASSEMBLER_MATCH_ERROR_1 (c556)

    c96a  cd 72 c5   CALL ASSEMBLER_PARSE_LABEL_ADDRESS (c572)  ; Parse the label reference, and store label
    c96d  da 56 c5   JC ASSEMBLER_MATCH_ERROR_1 (c556)          ; address at HL

    c970  50         MOV D, B                               ; Move label address to DE, value to HL
    c971  59         MOV E, C
    c972  eb         XCHG

    c973  c3 2f c8   JMP SAVE_HL_AT_DE (c82f)               ; Store the value in the labels table


; Parse DB (data byte) expression
;
; The DB expression supports the following features:
; - a single value (each may be an expression with $, @, #, +, -, etc. See ASSEMBLER_PARSE_IMMEDIATE)
; - multiple values split with comma
; - a string in single quotes (each char is stored as a data byte)
; - ''' (triple single quote) generates ' (single quote) symbol at output
ASSEMBLER_PARSE_DB_ARG:
    c976  cd bb c5   CALL ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb)    ; Skip spaces before the arg

    c979  fe 27      CPI A, 27                  ; Match single quote for symbolic/string arguments
    c97b  ca 8d c9   JZ c98d

    c97e  cd 35 c8   CALL ASSEMBLER_PARSE_IMMEDIATE (c835)  ; Parse the value

    c981  3c         INR A                      ; Compare A with ',' comma symbol

    c982  79         MOV A, C                   ; Store parsed value to the output
    c983  cd da c8   CALL ASSEMBLER_STORE_OUTPUT_BYTE (c8da)

ASSEMBLER_PARSE_DB_NEXT_ARG:
    c986  cd d5 c8   CALL ASSEMBLER_SET_BUF_OFFSET (c8d5)   ; Prepare for the next byte to parse

    c989  ca 76 c9   JZ ASSEMBLER_PARSE_DB_ARG (c976)   ; Process another value after comma (if specified)
    
    c98c  c9         RET

; Parse string DB argument (store bytes to output until closing singlee quote is found)
ASSEMBLER_PARSE_DB_STRING:
    c98d  13         INX DE                     ; Load the next symbol
    c98e  1a         LDAX DE

    c98f  fe 27      CPI A, 27                  ; Handle double single quote
    c991  ca a6 c9   JZ ASSEMBLER_PARSE_DB_TRIPLE_QUOTE (c9a6)

ASSEMBLER_PARSE_DB_STRING_LOOP:
    c994  cd da c8   CALL ASSEMBLER_STORE_OUTPUT_BYTE (c8da)    ; Copy the byte to output

    c997  13         INX DE                     ; Load the next symbol
    c998  1a         LDAX DE

    c999  fe 27      CPI A, 27                  ; Continue until closing quote is found
    c99b  ca b0 c9   JZ c9b0

    c99e  fe 0d      CPI A, 0d                  ; Unexpected EOL before closing quote is found generates error
    c9a0  ca 56 c5   JZ ASSEMBLER_MATCH_ERROR_1 (c556)

    c9a3  c3 94 c9   JMP ASSEMBLER_PARSE_DB_STRING_LOOP (c994)  ; Repeat for the next symbol

ASSEMBLER_PARSE_DB_TRIPLE_QUOTE:
    c9a6  13         INX DE                     ; Advance for one more symbol
    c9a7  1a         LDAX DE

    c9a8  fe 27      CPI A, 27                  ; Tripple single quote means a one single quote symbol
    c9aa  c2 56 c5   JNZ ASSEMBLER_MATCH_ERROR_1 (c556)

    c9ad  cd da c8   CALL ASSEMBLER_PARSE_NO_ARGS (c8da)    ; Submit the parsed symbol


; Finalize string, go and parse another parameter if specified after comma
ASSEMBLER_PARSE_DB_SUBMIT_STRING:
    c9b0  cd c5 c5   CALL ASSEMBLER_ADVANCE_TO_NEXT_ARG (c5c5)  ; Look for the next argument, if any

    c9b3  fe 2c      CPI A, 2c                  ; Check if there is another value after comma
    c9b5  13         INX DE

    c9b6  c3 86 c9   JMP ASSEMBLER_PARSE_DB_NEXT_ARG (c986) ; Continue with matching DB arguments


; Parse ORG directive
; The function sets the new target address
; The function prints the previous target address, then sets the new one
ASSEMBLER_PARSE_ORG_ARG:
    c9b9  cd 35 c8   CALL ASSEMBLER_PARSE_IMMEDIATE (c835)  ; Parse the argument value to DE
    c9bc  eb         XCHG

    c9bd  cd 6b fc   CALL PRINT_NEW_LINE (fc6b)             ; Print original target start address
    c9c0  cd 4a fc   CALL PRINT_ARG_1_NO_NEW_LINE (fc4a)

    c9c3  2a 53 f7   LHLD ARG_2 (f753)                      ; Print current target address - 1
    c9c6  2b         DCX HL
    c9c7  cd 4d fc   CALL PRINT_HL (fc4d)

    c9ca  eb         XCHG                                   ; Store argument as a new target address
    c9cb  22 51 f7   SHLD ARG_1 (f751)
    c9ce  22 53 f7   SHLD ARG_2 (f753)
    c9d1  c9         RET


; Parse DW (data word) instruction argument
;
; Each value corresponds ASSEMBLER_PARSE_IMMEDIATE value format (including references, arithmetic, $, #, etc).
; The format supports several word values, separated with comma. 
ASSEMBLER_PARSE_DW_ARG:
    c9d2  cd 35 c8   CALL ASSEMBLER_PARSE_IMMEDIATE (c835)  ; Parse the data word

    c9d5  3c         INR A                      ; 0xff will be returned in case of ',' match

    c9d6  79         MOV A, C                   ; Move parsed value to A (low byte) and C (high byte)
    c9d7  48         MOV C, B

    c9d8  cd ec c8   CALL ASSEMBLER_STORE_2_BYTES (c8ec); Store parsed value to the output

    c9db  ca d2 c9   JZ ASSEMBLER_PARSE_DW_ARG (c9d2)   ; If comma was matched earlier - parse next word

    c9de  c9         RET


; DIR directive allows executing Monitor's command right while parsing assembler source code
;
; Usage:
; DIR <monitor command>
ASSEMBLER_PARSE_DIR_ARG:
    c9df  cd bb c5   CALL ASSEMBLER_SEARCH_NON_SPACE_CHAR (c5bb)    ; Set pointer to monitor command
    c9e2  21 7b f7   LXI HL, f77b                                   ; As well as pointer to the command buf

DIR_COMMAND_COPY_LOOP:
    c9e5  1a         LDAX DE                        ; Copy next symbol

    c9e6  fe 0d      CPI A, 0d                      ; Stop at EOL
    c9e8  77         MOV M, A

    c9e9  13         INX DE                         ; Advance to the next symbol
    c9ea  23         INX HL

    c9eb  c2 e5 c9   JNZ DIR_COMMAND_COPY_LOOP (c9e5)   ; Repeat until EOL found

    c9ee  2a 51 f7   LHLD ARG_1 (f751)              ; Save current assembler state
    c9f1  e5         PUSH HL
    c9f2  2a 53 f7   LHLD ARG_2 (f753)
    c9f5  e5         PUSH HL
    c9f6  2a 55 f7   LHLD ARG_3 (f755)
    c9f9  e5         PUSH HL
    c9fa  2a 57 f7   LHLD ARG_4 (f757)
    c9fd  e5         PUSH HL

    c9fe  21 9c ff   LXI HL, ff9c               ; Load the command symbol
    ca01  3a 7b f7   LDA f77b
    ca04  47         MOV B, A

    ca05  fe 58      CPI A, 58                  ; Execute monitor commands, unless this is X command
    ca07  f5         PUSH PSW
    ca08  c4 53 f8   CNZ SEARCH_COMMAND_LOOP (f853)

    ca0b  f1         POP PSW                    ; Restore current assembler state
    ca0c  e1         POP HL
    ca0d  22 57 f7   SHLD ARG_4 (f757)
    ca10  e1         POP HL
    ca11  22 55 f7   SHLD ARG_3 (f755)
    ca14  e1         POP HL
    ca15  22 53 f7   SHLD ARG_2 (f753)
    ca18  e1         POP HL
    ca19  22 51 f7   SHLD ARG_1 (f751)

    ca1c  c0         RNZ                        ; Report errors if any
    ca1d  c3 56 c5   JMP ASSEMBLER_MATCH_ERROR_1 (c556)


; Command A: Assembler
;
; Usage:
; A[@] [target start addr]
; 
; The command runs assembler for source code located at 0x3000-0x9fff, to target location specified in the
; argument (or 0xa000 if no argument specified).
; 
; Command A runs the assembler 1st pass. If @ modifier is added, second pass is executed as well. The
; function reads source code line by line, copies line data to 0xf77b line buffer, and execute 
; ASSEMBLER_PARSE_INSTRUCTION_LINE function to parse the line and generate the code.
;
; Internal variables:
; Arg 1 - Target start address
; Arg 2 - Target start address / Current target address
; Arg 3 - Source start address / Current source address
; Arg 4 - Currently parsed source string address
COMMAND_A_ASSEMBLER:
    ca20  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)  ; Check if A@ command is requested

    ca23  f5         PUSH PSW                   ; Store @ modifier flags to be checked later

    ca24  21 00 a0   LXI HL, a000               ; Set 0xa000 as a default start address
    ca27  22 51 f7   SHLD ARG_1 (f751)
    ca2a  22 53 f7   SHLD ARG_2 (f753)

    ca2d  cd b1 c5   CALL PARSE_ARGUMENTS_IF_SPECIFIED (c5b1)   ; Parse arguments if they are

    ca30  21 00 30   LXI HL, 3000               ; Set 0x3000 as source start address
    ca33  22 55 f7   SHLD ARG_3 (f755)


; The main assembler loop
ASSEMBLER_LOOP:
    ca36  11 7b f7   LXI DE, f77b               ; Will copy input assembler text into the line buffer
    ca39  2a 55 f7   LHLD ARG_3 (f755)
    ca3c  22 57 f7   SHLD ARG_4 (f757)

ASSEMBLER_COPY_LINE_LOOP:
    ca3f  7e         MOV A, M                   ; Copy next symbol to the line buffer
    ca40  12         STAX DE

    ca41  23         INX HL                     ; Advance to the next symbol
    ca42  13         INX DE

    ca43  fe 0d      CPI A, 0d                  ; Repeat until EOL reached
    ca45  ca 57 ca   JZ ASSEMBLER_EOL_REACHED (ca57)

    ca48  7b         MOV A, E                   ; Limit the input with the size of the buffer (0x40 bytes)
    ca49  fe bb      CPI A, bb
    ca4b  c2 3f ca   JNZ ASSEMBLER_COPY_LINE_LOOP (ca3f)

; Report line error (print line address, and finish 1st pass)
ASSEMBLER_REPORT_LINE_ERROR:
    ca4e  2a 57 f7   LHLD ARG_4 (f757)          ; If line is too long - print the address
    ca51  cd 4d fc   CALL PRINT_HL (fc4d)

    ca54  c3 6c ca   JMP ASSEMBLER_FINISH_PASS_1 (ca6c) ; Finish pass 1 and get prepared for pass 2

; String is copied - run the assembler on it
ASSEMBLER_EOL_REACHED:
    ca57  22 55 f7   SHLD ARG_3 (f755)          ; Parse a single instruction line
    ca5a  cd 00 c8   CALL ASSEMBLER_PARSE_INSTRUCTION_LINE (c800)
    ca5d  da 4e ca   JC ASSEMBLER_REPORT_LINE_ERROR (ca4e)  ; Report error if any

    ca60  cd 4b fb   CALL CHECK_CTRL_KEY (fb4b) ; Ctrl-<something> will stop execution
    ca63  dc b5 fd   CC SET_COMMAND_MODE_FLAG (fdb5)

    ca66  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; Continue while flag is not yet raised
    ca69  f2 36 ca   JP ASSEMBLER_LOOP (ca36)           ; Otherwise finalize pass 1 and proceed with pass 2



ASSEMBLER_FINISH_PASS_1:
    ca6c  cd 4a fc   CALL PRINT_ARG_1_NO_NEW_LINE (fc4a)    ; Print target start address

    ca6f  2a 53 f7   LHLD ARG_2 (f753)              ; Load and print target end address
    ca72  2b         DCX HL
    ca73  cd 4d fc   CALL PRINT_HL (fc4d)

    ca76  f1         POP PSW                        ; Restore @ modifier flag. Stop processing if no flag
    ca77  c0         RNZ                            ; specified

    ca78  3e 40      MVI A, 40                      ; Print '@' symbol
    ca7a  cd e9 f9   CALL PUT_CHAR_A (f9e9)




; Assembler 2nd pass
;
; The function goes through the assembled binary code, and looks for 3-byte instruction.
; If 3-byte instruction refers to a label in 0xf400-0xf600 range, it substitutes the reference
; with the actual value
ASSEMBLER_2ND_PASS:
    ca7d  2a 51 f7   LHLD ARG_1 (f751)          ; Load the next byte
    ca80  7e         MOV A, M

    ca81  cd 1c c3   CALL MATCH_INSTRUCTION (c31c)  ; Search corresponding instruction descriptor
    ca84  dc 98 ca   CC ASSEMBLER_2ND_PASS_APPLY_REF (ca98) ; Process 3-byte instructions

    ca87  2a 51 f7   LHLD ARG_1 (f751)          ; Advance to the next instructions (C - number of bytes in 
    ca8a  06 00      MVI B, 00                  ; the current instruction)
    ca8c  09         DAD BC
    ca8d  22 51 f7   SHLD ARG_1 (f751)

    ca90  cd cc fb   CALL LOAD_ARGUMENTS (fbcc) ; Stop if reached end address
    ca93  c8         RZ
    ca94  d8         RC

    ca95  c3 7d ca   JMP ASSEMBLER_2ND_PASS (ca7d)  ; Repeat for the next instruction


; For a 3-byte instruction pointed by ARG_1, if the instruction refers to 0xf400-0xf600 labels area, 
; the function substitutes label value, instead of reference.
ASSEMBLER_2ND_PASS_APPLY_REF:
    ca98  2a 51 f7   LHLD ARG_1 (f751)          ; Load instruction address, then load high byte of the
    ca9b  23         INX HL                     ; argument
    ca9c  23         INX HL
    ca9d  7e         MOV A, M

    ca9e  e6 fe      ANI A, fe                  ; Check if the address within 0xf400-0xf600 range
    caa0  fe f4      CPI A, f4
    caa2  c0         RNZ                        ; Stop processing if address outside of the range

    caa3  56         MOV D, M                   ; Load the argument into DE
    caa4  2b         DCX HL
    caa5  5e         MOV E, M

    caa6  1a         LDAX DE                    ; Replace argument with the value in relocation table
    caa7  77         MOV M, A
    caa8  13         INX DE
    caa9  23         INX HL
    caaa  1a         LDAX DE
    caab  77         MOV M, A
    caac  c9         RET


; Command @: Assembler 2nd pass
;
; Usage:
; @ [addr1, addr2]
;
; Runs the assembler 2nd pass for <addr1>-<addr2> range (or 0xa000-0xaffe if arguments are not specified)
;
; See ASSEMBLER_2ND_PASS function description for 2nd pass algorithm
COMMAND_@_ASSEMBLER_2ND_PASS:
    caad  21 fe af   LXI HL, affe               ; Set 0xaffe as default end address
    cab0  22 53 f7   SHLD ARG_2 (f753)

    cab3  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)  ; Advance to the next byte

    cab6  21 00 a0   LXI HL, a000               ; Set 0xa000 as default start address
    cab9  22 51 f7   SHLD ARG_1 (f751)

    cabc  cd b1 c5   CALL PARSE_ARGUMENTS_IF_SPECIFIED (c5b1)   ; Parse start/end address if specified

    cabf  c3 7d ca   JMP ASSEMBLER_2ND_PASS (ca7d)



; Command N: Interactive assembler
;
; Usage:
; N[@] [addr]
;
; Assemble program line by line as per user input. Store compiled program at <addr> (or 0xa000 if <addr> is
; not specified). Empty line stops assembly, and exits to the Monitor. @ modifier enables pass 2.
COMMAND_N_INTERACTIVE_ASSEMBLER:
    cac2  21 00 a0   LXI HL, a000               ; Set 0xa000 as default start address
    cac5  22 53 f7   SHLD ARG_2 (f753)
    cac8  22 51 f7   SHLD ARG_1 (f751)

    cacb  cd 70 c2   CALL CHECK_AT_MODIFIER (c270)  ; Check if N@ command is requested (enable 2nd pass)
    cace  f5         PUSH PSW

    cacf  cd b1 c5   CALL PARSE_ARGUMENTS_IF_SPECIFIED (c5b1)   ; Parse arguments

INTERACTIVE_ASSEMBLER_LOOP:
    cad2  cd 6b fc   CALL PRINT_NEW_LINE (fc6b) ; Every new command is entered from a new line

    cad5  2a 53 f7   LHLD ARG_2 (f753)
    cad8  cd 4d fc   CALL PRINT_HL (fc4d)       ; Print current address

    cadb  cd 8b fa   CALL INPUT_LINE (fa8b)     ; Input the command to assemble

    cade  cd 00 c8   CALL ASSEMBLER_PARSE_INSTRUCTION_LINE (c800); parse and process the entered command
    cae1  da d2 ca   JC INTERACTIVE_ASSEMBLER_LOOP (cad2)   ; Restart in case of error

    cae4  cd ab fd   CALL GET_COMMAND_MODE_FLAG (fdab)  ; Check if 'stop flag' is set. Otherwise continue
    cae7  f2 d2 ca   JP INTERACTIVE_ASSEMBLER_LOOP (cad2)   ; with the next line

    caea  c3 6c ca   JMP ASSEMBLER_FINISH_PASS_1 (ca6c) ; Finish pass 1 and get prepared for pass 2

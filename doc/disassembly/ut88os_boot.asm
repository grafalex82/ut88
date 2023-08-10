; UT-88 OS Bootstrap module
;
; The goal of this program is to load UT-88 OS binary into dedicated address range, and prepare OS for
; execution. 
;
; It is supposed to run this bootstrap program on a working Video Module configuration, which includes
; MonitorF ROM. UT-88 provides its own Monitor, so the program asks the User to switch off MonitorF ROM, 
; and enable RAM instead on the same memory range. After ROM(s) are disconnected, the program copies
; US-88 OS binaries to memory locations as follows:
; - 0x30b0-0x38af to 0xf800-0xffff (Monitor main part)
; - 0x38b0-0x58af to 0xc000-0xdfff (Other monitor functions, Editor, Assembler, Debugger)
;
; When OS binaries are settled at their addresses, the program starts the Monitor starting 0xf800 address

START:
    3000  21 50 30   LXI HL, WELCOME_STR (3050)     ; Print welcome message
    3003  cd 18 f8   CALL PRINT_STRING (f818)

    3006  31 03 30   LXI SP, 3003                   ; Set up own stack

    3009  3e 8b      MVI A, 8b                      ; Configure keyboard port (A - output, B and C - input)
    300b  d3 04      OUT 04

WAIT_ANY_KEY:
    300d  af         XRA A                          ; Check all scan columns
    300e  d3 07      OUT 07

    3010  db 06      IN 06                          ; Read the pressed keys value

    3012  e6 7f      ANI A, 7f                      ; Repeat if no key is pressed
    3014  fe 7f      CPI A, 7f
    3016  ca 0d 30   JZ WAIT_ANY_KEY (300d)

    3019  21 b0 30   LXI HL, 30b0                   ; Copy monitor from 0x30b0 to 0xf800 area
    301c  11 00 f8   LXI DE, f800
    301f  d5         PUSH DE                        ; Push start address

MONITOR_MEMCOPY:
    3020  7e         MOV A, M                       ; Copy one byte
    3021  12         STAX DE

    3022  23         INX HL                         ; Advance to the next byte
    3023  13         INX DE

    3024  af         XRA A                          ; Check if we reached 0x0000 address
    3025  ba         CMP D
    3026  c2 20 30   JNZ MONITOR_MEMCOPY (3020)


    3029  3e c3      MVI A, c3                      ; Put JMP opcode to 0x0000
    302b  12         STAX DE

    302c  11 00 c0   LXI DE, c000                   ; Load second part target address

EDITOR_MEMCOPY:
    302f  7e         MOV A, M                       ; Copy byte
    3030  12         STAX DE

    3031  23         INX HL                         ; Advance to the next byte
    3032  13         INX DE

    3033  3e e0      MVI A, e0                      ; Load end address
    
    3035  c3 3b 30   JMP EDITOR_MEMCOPY_1 (303b)    ; Continue elsewhere

    3038  c3 65 f8   JMP f865                       ; ????? RST7 handler ????

EDITOR_MEMCOPY_1:
    303b  ba         CMP D                          ; Repeat until reached the end address
    303c  c2 2f 30   JNZ EDITOR_MEMCOPY (302f)

    303f  c9         RET                            ; Pass to Monitor start address (0xf800)

????:
    3040  20 20 20 20 20 20 20 20                   ; Garbage ????
    3048  20 20 20 20 20 20 20 20 

WELCOME_STR:
    3050  20 20 20 20 20 20 20 20       db "        "           ; Welcome message says 'This is UT-88
    3058  20 20 20 20 20 20 20 20       db "        "           ; OS starter. Switch off MonitorF ROM,
    3060  20 20 20 20 73 74 61 72       db "    СТАР"           ; and press any key'
    3068  74 65 72 20 22 6f 73 20       db "ТЕР "ОС "
    3070  60 74 2a 38 38 22 0a 20       db "ЮТ-88"", 0x0a, " "
    3078  20 20 20 20 20 20 20 77       db "       В"
    3080  79 6b 6c 60 7e 69 74 65       db "ЫКЛЮЧИТЕ"
    3088  20 70 7a 75 20 6d 6f 6e       db " ПЗУ МОН"
    3090  69 74 6f 72 61 20 69 20       db "ИТОРА И "
    3098  6e 61 76 6d 69 74 65 20       db "НАЖМИТЕ "
    30a0  6c 60 62 75 60 20 6b 6c       db "ЛЮБУЮ КЛ"
    30a8  61 77 69 7b 75 0a 0a 00       db "АВИШУ", 0x0a, 0x0a, 0x00

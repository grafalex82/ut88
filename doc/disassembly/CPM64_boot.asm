; CP/M64 Loader
;
; This is a single binary loader of the CP/M operating system. The loader is responsible for
; copying CP/M parts into specific memory addresses, prepare a CP/M copy on the quasi disk, and
; finally run the operating system.
;
; The loader copies CP/M parts at the following addresses:

; Part name         binary address      target address
;-----------------------------------------------------
; CP/M CCP          0x3400-0x3bff       0xc400-0xcbff
; CP/M BDOS         0x3c00-0x49ff       0xcc00-0xd9ff
; CP/M BIOS         0x4a00-0x4bff       0xda00-0xdbff
; Monitor F addon   0x31e0-0x32ff       0xf500-0xf61f


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Phase 1:
; Copy 0x3400-0x4c00 of the initial binary to the memory range 0xc400-0xdbff
;
; This range includes copying CP/M parts into its addresses (CCP, BIOS, BDOS)
; 
START:
    3100  21 00 34   LXI HL, 3400               ; Set ranges start addresses
    3103  11 00 c4   LXI DE, c400
COPY_BYTES_LOOP:
    3106  7e         MOV A, M                   ; Copy bytes one by one
    3107  12         STAX DE
    3108  23         INX HL
    3109  13         INX DE
    310a  7c         MOV A, H
    310b  fe 4c      CPI A, 4c                  ; Repeat until reached 0x4c00
    310d  c2 06 31   JNZ COPY_BYTES_LOOP (3106)

    3110  7d         MOV A, L                   ; Useless, just to double check the end address
    3111  fe 00      CPI A, 00
    3113  c2 06 31   JNZ COPY_BYTES_LOOP (3106)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Phase 2:
; Copy 0x3400-0x4fff initial binary range to the quasi disk at addresses 0x0000-0x1c00 (bank 0)
;
    3116  31 00 1c   LXI SP, 1c00               ; Open the quasi disk, prepare for writing from 
    3119  21 ff 4f   LXI HL, 4fff               ; 0x3400-0x4fff range to quasi disk bank 0 address
    311c  3e fe      MVI A, fe                  ; 0x0000-0x1c00 (in reverse order) 
    311e  d3 40      OUT 40
COPY_DISK_LOOP:
    3120  56         MOV D, M                   ; Load 2 bytes to DE
    3121  2b         DCX HL
    3122  5e         MOV E, M
    3123  2b         DCX HL

    3124  d5         PUSH DE                    ; Push 2 bytes to the quasi disk

    3125  7c         MOV A, H                   ; Check if we reached 0x3400
    3126  fe 33      CPI A, 33
    3128  c2 20 31   JNZ COPY_DISK_LOOP (3120)

    312b  3e ff      MVI A, ff                  ; Disable quasi disk
    312d  d3 40      OUT 40

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Phase 3:
; Copy range 0x31e0-0x32ff   to 0xf500-0xf61f
;
    312f  21 e0 31   LXI HL, 31e0               ; Set ranges start addresses
    3132  11 00 f5   LXI DE, f500
COPY_MONITOR_ADDON_LOOP:
    3135  7e         MOV A, M
    3136  12         STAX DE
    3137  23         INX HL
    3138  13         INX DE
    3139  7c         MOV A, H
    313a  fe 33      CPI A, 33
    313c  c2 35 31   JNZ COPY_MONITOR_ADDON_LOOP (3135)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Phase 4:
; Start CP/M
;
    313f  c3 00 da   JMP BIOS_START (da00)

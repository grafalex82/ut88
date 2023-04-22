# UT-88 Soviet DIY i8080-based Computer Emulator

This is the emulator of UT-88 computer, written in Python. Goals of the project:
- Understand the computer schematics, and emulate it as close as possible to the real hardware
- Understand software part of the computer, disassemble and document it

## UT-88 - Computer Description

UT-88 (Russian: ЮТ-88) is a DIY computer, first published in "Young Technician - For Skilled Hands" magazine (Russian: "ЮТ Для Умелых Рук") on Feb 1989. In late 80x a typical DIY computers was quite complex, consist of many parts, and required quite solid technical skills to bring it up. Instead, UT-88 offered a very simple design, and a step-by-step build. This extends target audience to children and hobbyist.

The magazine published the computer schematics and software codes. It was supposed to build the computer in phases:
- Basic configuration looks like a calculator with a 6-digit LCD and hexadecimal button keypad. 
- Calculator addon adds a ROM with some floating point functions, making possible scientific calculations
- Video module adds 55-keys alpha-numeric keyboard, and a 64x28 char monochrome display (TV output). 
- Dynamic 64k RAM adds possibility to run programs from other compatible computers
- 64k-256k Quasi Disk (a battery powered dynamic ROM) adds possibility to store large amount of data
- There were a few custom addons such as Flash memory programmer, and i8253-based sound generator

From the software point of view each phase provided additional capabilities:
- The basic configuration allowed doing basic computer operations (read/write memory, calculate CRC), loading programs from tape, creating and running own simple programs. 
- The video module provided possibility to run text based programs, such as simple text based video games.
- Full configuration allowed running so called UT-88 operating system, which provided a text editor, assembler, and better compatibility with other i8080-based computers.
- The magazine offerred a special port of the CP/M operating system, that allows working with files on the quasi disk.

# UT-88 Basic Configuration

Basic UT-88 configuration includes:
- КР580ВМ80/KR580VM80 CPU (Intel 8080A functional clone) and supplemental chips: КР580ГФ24/KR580GF24 clock generator (Intel 8224 clone), address buffers, КР580ВК38/KR580VK38 system controller (Intel 8238 clone).
- 1kb ROM at 0x0000-0x03ff address.
- 1kb RAM at 0xc000-0xc3ff address.
- 6-digit 7-segment indicator displaying 3-byte registers at memory address 0x9000-0x9002. Typical usage is to display 2-byte address information and 1-byte data. Display addressing is from right to left (0x9002 - 0x9001 - 0x9000) in order to display 2-byte addresses in a natural way.
- 17 button keyboard, that allows entering 16 hex digits (general purpose), and a "step back" button used for correction the previously entered byte when manually enter the program. Keyboard is connected to 0xa0 I/O port.
- A reset button, that resets only CPU, but leave RAM content untouched.
- Tape recorder input/output to load and store data and programs (connected to LSB of 0xa1 I/O port).
- Clock timer for generating interrputs every 1 second. Since there is no interrput controller, CPU will read data line pulled up (0xff), which is RST7 command. The special handler in the firmware advances hours/minutes/seconds values in a software mode.

The minimal firmware called "Monitor 0" (since located starting 0x0000) provides common routines, as well as a minimal operating system for the computer. The Monitor 0 is split into 2 parts:
- 0x0000-0x01ff - essential part ([see disasssembly](doc/disassembly/monitor0.asm)) of the ROM that includes
    - Handy routines to input data from the keyboard, output to LCD, input and output data to the tape.
    - Basic operating system that allows the User to read and write memory and ROM, calculate CRC, and execute programs
    - Current time clock
- 0x0200-0x03ff - optional part ([see disasssembly](doc/disassembly/monitor0_2.asm)) with a few useful programs:
    - memory copying programs (including special cases to insert or remove a byte from the program)
    - memory compare programs
    - address correction programs after the program was moved to another memory region

Usage of the Monitor 0:
- On CPU reset the Monitor 0 will display 11 on the right display to indicate it is ready to accept commands
- User enters desired commands using Hex Keyboard. Some commands require additional parameters, described below
- Some commands do CPU reset when finished, the computer will be ready for a new command. Other commands are endless, and will be interacting with the User until Reset is pressed.

Commands are:
- 0 `addr`    - Manually enter data starting `addr`. 
                  - Current address is displayed on the LCD
                  - Monitor0 waits for the byte to be entered
                  - Entered byte is stored at the current address, then address advances to the next byte
                  - Reset to exit memory write mode (memory data will be preserved)
- 1           - Manually enter data starting address 0xc000 (similar to command 0)
- 2           - Read memory data starting the address 0xc000 (similar to command 5)
- 3           - Run an LCD test
- 4           - Run memory test for the range of 0xc000 - 0xc400.
                  - If a memory error found, the LCD will display the address and the read value
                  - Address 0xc400 on the display means no memory errors found
                  - Reset to exit memory test mode
- 5 `addr`    - Display data starting address `addr`
                  - Current address and the byte at the address are displayed on the LCD
                  - Press a button for the next byte
                  - Reset to exit memory read mode (memory data will be preserved)
- 6           - Start the program starting address 0xc000
- 7 `addr`    - Start the program starting the user address
- 8 `a1` `a2` - Calculate CRC for the address range a1-a2
- 9 `a1` `a2` - Store data at the address range a1-a2 to the tape
- A `offset`  - Read data from tape with the offset (to the start address written on the tape)
- B           - Display current time (0x3cfd - seconds, 0x3cfe - minutes, 0x3cff - hours)
- C `addr`    - Enter new time. Same as command 0, but interrupts disabled. Address shall be 0x3cfd

Monitor 0 exposes a few handy routines for the purposes of Monitor itself and the user program. Unlike typical approach, when 3-byte CALL instruction is used to execute these routines, the Monitor 0 uses RSTx 1-byte instructions. This is clever solution in terms of packing code into a tiny ROM. 

RST routines are:
- RST 0 (address 0x0000)  - reset routine
- RST 1 (address 0x0008)  - output a byte in A to the tape
- RST 2 (address 0x0010)  - wait for a byte (2 digit) pressed on the keypad, return in A
- RST 3 (address 0x0018)  - 1 second delay
- RST 4 (address 0x0020)  - wait for a button press, return key code in A
- RST 5 (address 0x0028)  - display A and HL registers on the LCD
- RST 6 (address 0x0030)  - wait for a 2 byte (4 digit) value typed on the keyboard, return in DE
- RST 7 (address 0x0038)  - time interrupt (executed every second, and advances time value)

Important memory adresses:
- 0x3fc       - tape reading polarity (0x00 - non inverted, 0xff - inverted)
- 0x3fd       - seconds
- 0x3fe       - minutes
- 0x3ff       - hours

Tape recording format:
- 256 * 0xff  - pilot tone, to sync with the sequence
- 0xe6        - synchronization byte, marks polarity and start of data bytes
- 2 bytes     - start address
- 2 bytes     - end address
- `bytes`     - data bytes

No CRC bytes are stored on the tape. The CRC value is displayed on the screen after store and load commands. The User is responsible for validating the CRC.

The second part of the Monitor 0 includes the following programs (called with command 7 from the start address listed below):
- 0x0200  - Memory copying program. Accepts source start address, source end address, and target start address. The program can handle a case when source and destination memory ranges overlap.
- 0x025f  - Address correction program. Used to fix address arguments of 3-byte instructions, after the program was moved to a new address range. Accepts start and end address of the original program, and destination address.
- 0x02e5  - "Super" Address correction program. Similar to the previous program, but address correction is made before copying the program to a different address range. Accepts start and end addresses of the program to correct, and a destination address where the program is supposed to work.
- 0x0309  - Replace address. Replaces all occurrances of the address in the range with another address. Program accepts start and end address of the program to correct, address to search and the replacement address.
- 0x035e  - Insert byte program. Shifts the range 1 byte further. Accepts start and end address of the range to be moved.
- 0x0388  - Delete byte program. Shifts the range 1 byte backward, and correct addresses within the range. Accepts start and end address of the range to be moved.
- 0x03b2  - Memory compare program. Accept start and end address of a source range, and start address of the range to compare with.
- 0x03dd  - Display registers helper function (Displays AF, BC, DE, HL, and the memory byte underneath HL pointer)



# UT-88 Emulator

This project is an emulator of the UT-88 hardware, including CPU, memory, and I/O peripherals. The architecture of the emulator pretty much reflects the modular computer design. 

To be continued...

# Running the emulator

To run tests:
```
cd tests
py.test -rfeEsxXwa --verbose --showlocals
```

To run the emulator in basic UT-88 configuration
```
python src/main.py
```
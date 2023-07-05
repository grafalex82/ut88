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

The UT-88 computer architecture is based on previously published Micro-80 computer (early 80s), and Radio-86RK (published in 'Radio' magazine in 1985-1987s). It reuses multiple technical solutions such as tape recorder connectivity and recording format, keyboard layout and schematics. 

It worth noting that UT-88 offers a more mature schematics, such as using i8224 and i8238 (instead of number of TTL logic gate chips in Radio-86RK), and wide use of peripheral in I/O address space (unlike Radio-86RK where the peripheral was located in the main address space). UT-88 schematics also takes into account chip availability. Thus hard to buy i8275 used in 86RK was replaced with a number of registers and counters in UT-88 video module.

Software part is also highly compatible with the previous generation computers. Thus Monitor F (the primary firmware for the Video Module) is very similar to the Radio-86RK Monitor, and shares same routine entry points. This makes possible loading Radio-86RK programs from the tape and run them with no or little modifications.

Scans of the original magazine can be found [here](doc/scans).

## UT-88 Basic Configuration

Basic UT-88 configuration includes:
- КР580ВМ80/KR580VM80 CPU (Intel 8080A functional clone) and supplemental chips: КР580ГФ24/KR580GF24 clock generator (Intel 8224 clone), address buffers, КР580ВК38/KR580VK38 system controller (Intel 8238 clone).
- 1kb ROM at `0x0000-0x03ff` address.
- 1kb RAM at `0xc000-0xc3ff` address.
- 6-digit 7-segment indicator displaying 3-byte registers at memory address `0x9000-0x9002`. Typical usage is to display 2-byte address information and 1-byte data. Display addressing is from right to left (`0x9002` - `0x9001` - `0x9000`) in order to display 2-byte addresses in a natural way.
- 17 button keyboard, that allows entering 16 hex digits (general purpose), and a "step back" button used for correction the previously entered byte when manually enter the program. Keyboard is connected to I/O port `0xa0`.
- A reset button, that resets only CPU, but leave RAM content intact.
- Tape recorder input/output to load and store data and programs (connected to LSB of I/O port `0xa1`).
- Clock timer for generating interrputs every 1 second. Since there is no interrput controller, CPU will read data line pulled up (0xff), which is RST7 command. The special handler in the firmware advances hours/minutes/seconds values in a software mode.

The minimal firmware called "Monitor 0" (since located starting `0x0000`) provides common routines, as well as a minimal operating system for the computer. The Monitor 0 is split into 2 parts:
- `0x0000-0x01ff` - essential part ([see disasssembly](doc/disassembly/monitor0.asm)) of the ROM that includes
    - Handy routines to input data from the keyboard, output to LCD, input and output data to the tape.
    - Basic operating system that allows the User to read and write memory and ROM, calculate CRC, and execute programs
    - Current time clock
- `0x0200-0x03ff` - optional part ([see disasssembly](doc/disassembly/monitor0_2.asm)) with a few useful programs:
    - memory copying programs (including special cases to insert or remove a byte from the program)
    - memory compare programs
    - address correction programs after the program was moved to another memory region

Memory map of the UT-88 in Basic Configuration:
- `0x0000`-`0x03ff` - Monitor 0 ROM
- `0x0800`-`0x0fff` - Optional Calculator ROM (see below)
- `0x9000`-`0x9002` - LCD screen (3 bytes, 6 digits)
- `0xc000`-`0xc3ff` - RAM

I/O address space map:
- `0xa0`  - hex heyboard
- `0xa1`  - tape recorder

Usage of the Monitor 0:
- On CPU reset the Monitor 0 will display 11 on the right display to indicate it is ready to accept commands
- User enters desired commands using Hex Keyboard. Some commands require additional parameters, described below
- Some commands do CPU reset when finished, the computer will be ready for a new command. Other commands are endless, and will be interacting with the User until Reset button is pressed.

Commands are:
- 0 `addr`    - Manually enter data starting `addr`. 
                  - Current address is displayed on the LCD
                  - Monitor0 waits for the byte to be entered
                  - Entered byte is stored at the current address, then address advances to the next byte
                  - Reset to exit memory write mode (memory data will be preserved)
- 1           - Manually enter data starting address `0xc000` (similar to command 0)
- 2           - Read memory data starting the address `0xc000` (similar to command 5)
- 3           - Run an LCD test
- 4           - Run memory test for the range of `0xc000` - `0xc400`.
                  - If a memory error found, the LCD will display the address and the read value
                  - Address `0xc400` on the display means no memory errors found
                  - Reset to exit memory test mode
- 5 `addr`    - Display data starting address `addr`
                  - Current address and the byte at the address are displayed on the LCD
                  - Press a button for the next byte
                  - Reset to exit memory read mode (memory data will be preserved)
- 6           - Start the program starting address `0xc000`
- 7 `addr`    - Start the program starting the user address
- 8 `a1` `a2` - Calculate CRC for the address range a1-a2
- 9 `a1` `a2` - Store data at the address range a1-a2 to the tape
- A `offset`  - Read data from tape with the offset (to the start address written on the tape)
- B           - Display current time (`0x3cfd` - seconds, `0x3cfe` - minutes, `0x3cff` - hours)
- C `addr`    - Enter new time. Same as command 0, but interrupts disabled. Address shall be `0x3cfd`

Monitor 0 exposes a few handy routines for the purposes of Monitor itself and the user program. Unlike typical approach, when 3-byte CALL instruction is used to execute these routines, the Monitor 0 uses RSTx 1-byte instructions. This is clever solution in terms of packing code into a tiny ROM. 

RST routines are:
- RST 0 (address `0x0000`)  - reset routine
- RST 1 (address `0x0008`)  - output a byte in A to the tape
- RST 2 (address `0x0010`)  - wait for a byte (2 digit) pressed on the keypad, return in A
- RST 3 (address `0x0018`)  - 1 second delay
- RST 4 (address `0x0020`)  - wait for a button press, return key code in A
- RST 5 (address `0x0028`)  - display A and HL registers on the LCD
- RST 6 (address `0x0030`)  - wait for a 2 byte (4 digit) value typed on the keyboard, return in DE
- RST 7 (address `0x0038`)  - time interrupt (executed every second, and advances time value)

Important memory adresses:
- `0x3fc`       - tape reading polarity (`0x00` - non inverted, `0xff` - inverted)
- `0x3fd`       - seconds
- `0x3fe`       - minutes
- `0x3ff`       - hours

Tape recording format:
- 256 * `0xff`- pilot tone, to sync with the sequence
- `0xe6`      - synchronization byte, marks polarity and start of data bytes
- 2 bytes     - start address (high byte first)
- 2 bytes     - end address (high byte first)
- `bytes`     - data bytes

No CRC bytes are stored on the tape. The CRC value is displayed on the screen after store and load commands. The User is responsible for validating the CRC.

The second part of the Monitor 0 includes the following programs (called with command 7 from the start address listed below):
- `0x0200` - Memory copying program. Accepts source start address, source end address, and target start address. The program can handle a case when source and destination memory ranges overlap.
- `0x025f` - Address correction program. Used to fix address arguments of 3-byte instructions, after the program was moved to a new address range. Accepts start and end address of the original program, and destination address.
- `0x02e5` - "Super" Address correction program. Similar to the previous program, but address correction is made before copying the program to a different address range. Accepts start and end addresses of the program to correct, and a destination address where the program is supposed to work.
- `0x0309` - Replace address. Replaces all occurrances of the address in the range with another address. Program accepts start and end address of the program to correct, address to search and the replacement address.
- `0x035e` - Insert byte program. Shifts the range 1 byte further. Accepts start and end address of the range to be moved.
- `0x0388` - Delete byte program. Shifts the range 1 byte backward, and correct addresses within the range. Accepts start and end address of the range to be moved.
- `0x03b2` - Memory compare program. Accept start and end address of a source range, and start address of the range to compare with.
- `0x03dd` - Display registers helper function (Displays AF, BC, DE, HL, and the memory byte underneath HL pointer)

The UT-88 computer in the Basic Configuration is quite poor in terms of software variety. The Basic CPU module instructions come with a few test programs. Unfortunately quality of those programs is much worse than the main firmware (perhaps it was written by UT-88 author's students). Programs are:
- [Tic Tac Toe game](doc/disassembly/tictactoe.asm) - a classic game. Computer always goes first, and there is no way for the player to win.
- [Labyrinth game](doc/disassembly/labyrinth.asm) - player searches a way in a 16x16 labyrinth.
- [Reaction game](doc/disassembly/reaction.asm) - program starts counter, goal to stop the counter as early as possible.
- [Gamma](doc/disassembly/gamma.asm) - generates gamma notes to the tape recorder.

Basic CPU module schematics can be found here: [part 1](doc/scans/UT08.djvu), [part 2](doc/scans/UT09.djvu).

## UT-88 Calculator Add-On

One of the suggested modifications to the computer is the calculator add-on. It adds a 2k ROM at `0x0800`-`0x0fff` address range. This ROM contains some functions to work with floating point values, and include arithmetic operations (+, -, *, /), and also trigonometric functions (sin, cos, tg, ctg, arcsin, arccos, arctg, arcctg), based on Taylor series calculations.

The calculator ROM is supposed to work with 3-byte floats, which consists of 8-bit signed exponent, and 16-bit signed mantissa. The ROM contains a number of helper functions to operate with these floating point numbers as a whole, as well as operate with its parts (exponent and mantissa). Exponent and Mantissa are presented in a Sign-Magnitude form in order to simplify user experience, and decrease complexity of converting numbers into a human readable form. Unfortunately conversion from/to decimal form is not a part of the library, the User has to work with 3-byte hexadecimal floating point numbers.

Overall, 3-byte floating point values provide a good balance between accuracy and calculation power required to operate with these numbers. Simple arithmetic calculations work quite fast, and allows building own calculation algorithms based on provided functions. Unfortunately some of the trigonometric functions use high exponent values, a lot of multiplications and divisions, and as result accuracy of these functions for some values appears to be quite low (+-0.01), and function execution time is quite high (>10 seconds). 

The ROM provides number of function with fixed starting addresses outlined below. Unlike modern approach when parameters and the result are passed via stack or registers, functions in this library expects parameters and store the result at a fixed memory addresses. This adds some complexity of the client programs to copy values to/from specific addresses.

The disassembly of the calculator ROM is [here](doc/disassembly/calculator.asm). Refer to the disassembly for parameter/result addresses, as well as for algorithm explanation. 

Functions in the library are:
- `0x0849` - add two 1-byte integers in Sign-Magnitude representation
- `0x0877` - Normalize two 3-byte floats before adding
- `0x08dd` - Add two 2-byte integers in Sign-Magnitude representation.
- `0x092d` - Normalize exponent
- `0x0987` - Add two 3-byte floats
- `0x0994` - Multiply two 2-byte mantissa values
- `0x09ec` - Multiply two 3-byte float values
- `0x0a6f` - Divide two 3-byte float values
- `0x0a98` - Calculate factorial
- `0x0b08` - Raise a floating point value to a integer power
- `0x0b6b` - Logarithm
- `0x0c87` - Sine
- `0x0d32` - Cosine
- `0x0d47` - Arcsine
- `0x0e40` - Arccosine
- `0x0e47` - Tangent
- `0x0e75` - Arctangent
- `0x0f61` - Cotangent
- `0x0f8f` - Arccotangent

In order to better understand how 3-byte floating numbers work, a special [Float](misc/float.py) python component was created. It provides conversion from/to a regular 4-byte floating point numbers.

In order to simplify calling library functions for disassembly and testing purposes, a special [set of automated tests](test/test_calculator.py) were created, along with the helper python code to run the library functions and load parameters. These tests are not supposed to _test_ the library functions, but rather run different branches of the code, and check the result accuracy.

Add-on schematics can be found [here](doc/scans/UT18.djvu).

## UT-88 Video Module

The Video Module adds a 64x28 chars monochrome display and a full 55-keys keyboard. With this module UT-88 becomes a real computer, and can run text-based video games, text editors, programming language compilers, and many more. Video Module provides good level of compatibility with previously released Radio-86RK and its modifications, so that using/porting of programs for 86RK to UT-88 is not a big problem.

The hardware additions in more details:
- Video adapter is based on a 2-port RAM at the address range `0xe800`-`0xefff`. One port of this memory is attached to the computer's data bus, and works like a regular memory. A special schematics based on counters and logic gates is reading the video memory through the second port, and converts it to a TV signal. A special 2k ROM (not connected to the data bus) is used as a font generator.
  Overall, the video adapter can display 64x28 monochrome
chars 6x8 pixels each. Characters partially comply to 7-bit ASCII table (perhaps this is KOI-7 N2 encoding). Chars in `0x00`-`0x1f` range provide pseudo-graphics symbols. Chars in `0x20`-`0x5f` range match standard ASCII table. Chars in `0x60`-`0x7f` range allocated for Cyrilic symbols. Highest bit signals the video controller to invert the symbol.
- The keyboard is connected via i8255 chip to ports `0x04`-`0x07` (2 lowest bits of the address are inverted). The keyboard is a 7x8 buttons matrix connected to Port A (columns) and Port B (rows) of the i8255. 3 modification keys are used to enter special, control, and Cyrilic symbols. These keys connected to the Port C. Monitor F is responsible for scanning the keyboard matrix, and converting the scan code to the ASCII character value.
- A 1k RAM at `0xf400`-`0xf7ff` address range
- A 2k ROM at `0xf800`-`0xffff` range, containing Monitor F
- An optional 4k RAM can be connected to the `0x3000`-`0x3fff` address range
- An optional external ROM can be connected via another i8255 chip at ports `0xf8`-`0xfb`. Unfortunately the magazine never published the connection schematics, and the firmware support looks incorrect.

This hardware can work together with the CPU Basic Module components. Thus Video Module is supposed to use Tape Recorder connection at port `0xa1`. It also may use the LCD screen connected to `0x9000`-`0x9002` to display some information (e.g. current time). Some other components such as Monitor 0 ROM (`0x0000`-`0x03ff`) may be disconnected, and replaced with other memory modules (e.g. extra RAM). Hex keyboard is also not used in the Video Module configuration.

The primary firmware for the Video Module is Monitor F (since located starting `0xf800` address). The Monitor F provides a set of routines to work with the new hardware, such as display and keyboard. These routines are accessed via static and predefined entry points. Refer to the [Monitor F disassembly](doc/disassembly/monitorF.asm) for arguments and return values explanation, as well as algorithm description.
- `0xf800`    - Software reset
- `0xf803`    - Wait for a keyboard press, returns entered symbol in A
- `0xf806`    - Input a byte from the tape (A - number of bits to receive, or `0xff` if synchronization is needed. Returns the received byte in A)
- `0xf809`    - Put a char to the display at cursor location (C - char to print)
- `0xf80c`    - Output a byte to the tape (C - byte to output)
- `0xf80f`    - Put a char to the display at cursor location (C - char to print)
- `0xf812`    - Check if any button is pressed on the keyboard (A=`0x00` if no buttons pressed, `0xff` otherwise)
- `0xf815`    - Print a byte in a 2-digit hexadecimal form (A - byte to print)
- `0xf818`    - print a NULL terminated string at cursor position (HL - pointer to the string)
- `0xf81b`    - Scan a keyboard, return when a stable scan code is read (returns scan code in A)
- `0xf81e`    - Get the current cursor position (offset from `0xe800` video memory start, return in HL)
- `0xf821`    - Get the character under cursor (return in A)
- `0xf824`    - Load a program from tape (HL - offset, returns CRC in BC)
- `0xf827`    - Output a program to the tape (HL - start address, DE - end address, BC - CRC)
- `0xf82a`    - Calculate CRC for a memory range (HL - start address, DE - end address, Result in BC)

Character output function performs printing in a terminal mode: the symbol is printed at the cursor position, and cursor advances to the next position. If the cursor reaches the end of line, it advances to the next line. If cursor reaches the bottom right position of the screen, the screen is scrolled for one line.

Character output function also support several control symbols:
- `0x08`  - Move cursor 1 position left
- `0x0c`  - Move cursor to the top left position
- `0x18`  - Move cursor 1 position right
- `0x19`  - Move cursor 1 line up
- `0x1a`  - Move cursor 1 line down
- `0x1f`  - Clear screen
- `0x1b`  - Move cursor to a selected position. This is a 4-symbol sequence (similar to Esc sequence): `0x1b`, '`Y`', `0x20`+Y position, `0x20`+X position

Besides general purpose routines, the Monitor F also provides a basic command console, that provide the User with possibilities to:
- View, modify, copy, fill memory data
- Input from and output programs to the tape recorder
- Run user programs with a breakpoint possibility
- Handle time interrupt and display current time

The following commands are supported:
- Memory commands:
  - `D` `<addr1>`, `<addr2>`        - Dump the memory range in hex form
  - `L` `<addr1>`, `<addr2>`        - List the memory range in text form ('.' is printed for non-printable chars)
  - `K` `<addr1>`, `<addr2>`        - Calculate CRC for the memory range
  - `F` `<addr1>`, `<addr2>`, `<val>` - Fill the memory range with the provided constant
  - `S` `<addr1>`, `<addr2>`, `<val>` - Search the specified byte in the memory range
  - `T` `<src1>`, `<src2>`, `<dst>`   - Copy (Transfer) `<src1>`-`<src2>` memory range to `<dst>`
  - `C` `<src1>`, `<src2>`, `<dst>`   - Compare `<src1>`-`<src2>` memory range with range starting `<dst>`
  - `M` `<addr>`                  - View and edit memory starting `<addr>`
- Tape commands:
  - `O` `<start>`, `<end>`[, `<spd>`] - Save the memory range to the tape. Use speed constant if provided.
  - `I` `<offset>`[, `<spd>`]       - Load program from the tape, apply specified offset. Use speed constant.
  - `V`                         - Measure tape loading delay constant
- Program execution:
  - `W`                         - Start the program from `0xc000`
  - `U`                         - Start the program from `0xf000`
  - `G` `<addr>`[, `<brk`>]         - Start/Continue the program from `<addr>`, set breakpoint at `<brk>`
  - `X`                         - View/Modify CPU registers when breakpoint hit
- Time commands:
  - `B`                         - Display current time at CPU module LCD
- External ROM:
  - `R` `<start>`, `<end>`, `<dst>`   - Import `<start>`-`<end>` data range from external ROM

The tape format is similar to one used in Monitor 0, except for 2 additions:
- The recording format is extended with CRC. The Monitor F can detect stored and calculated CRC mismatch, and report this to the User
- Speed can be adjusted, by specifying so called 'tape constant' (which is a delay between bits). This is done to unify the format and allow read tapes for Micro-80 and Radio-86RK computers. These computers may potentially use different crystals, and therefore write to the tape at different speed. 

Tape recording format (last 3 fields are new, compared to Monitor 0 format):
- 256 x `0x00` - pilot tone
- `0xe6`       - Synchronization byte
- 2 byte       - start address (high byte first)
- 2 byte       - end address (high byte first)
- data bytes   - program data bytes
- `0x0000`     - micro-pilot tone (2 bytes)
- `0xe6`       - Synchronization byte
- 2 byte       - Calculated CRC (high byte first)


Memory map of the UT-88 in the Video Configuration:
- `0x0000`-`0x03ff` - CPU Module ROM (Monitor 0, Optional)
- `0x3000`-`0x3fff` - Optional 4k RAM
- `0xc000`-`0xc3ff` - CPU Module RAM (Optional)
- `0xe800`-`0xefff` - Video RAM
- `0xf400`-`0xf7ff` - Video Module RAM
- `0xf800`-`0xffff` - Video Module ROM (Monitor F)

I/O address space map:
- `0x04`  - Keyboard i8255 Control register
- `0x05`  - Keyboard i8255 Port C (Mod keys)
- `0x06`  - Keyboard i8255 Port B (Keyboard matrix rows)
- `0x07`  - Keyboard i8255 Port A (Keyboard matrix column)
- `0xf8`  - (Optional) external ROM i8255 Port A
- `0xf9`  - (Optional) external ROM i8255 Port B
- `0xfa`  - (Optional) external ROM i8255 Port C
- `0xfb`  - (Optional) external ROM i8255 Control register
- `0xa1`  - tape recorder

From the software perspective the Video Module makes the UT-88 a classic computer with a keyboard and monitor, and typical terminal-like routines that expected from this kind of computer. The only program published with the UT-88 video module is [Tetris game](tapes/TETR1.GAM) ([Disassembly](doc/disassembly/tetris.asm)).


Video module schematics can be found here: [part 1](doc/scans/UT22.djvu), [part 2](doc/scans/UT24.djvu).


## 64k Dynamic RAM

The next proposed step in upgrading UT-88 computer was building a 64k dynamic RAM module ([schematics](doc/scans/UT38.djvu)). While the RAM module covers whole address space, special logic disables the dynamic RAM for `0xe000`-`0xefff`, and `0xf000`-`0xffff` address ranges (video RAM, and MonitorF RAM/ROM respectively). Thus actual dynamic RAM size is 56k.

Additional RAM allows running programs in other address ranges. It is claimed that UT-88 has partial compatibility with other computers in the same class (particularly Micro-80 and Radio-86RK), but this is true only partially. Programs that communicate with keyboard and display using the Monitor F functions will work as expected. Unfortunately most of the Radio-86RK programs write directly to the video memory (which is located at different address range), or even re-configure i8275 video controller used in 86RK (but not available for UT-88) for a different screen resolution. This makes almost all 86RK games pretty much incompatible. 

Examples of Radio-86RK games that run on UT-88 are Treasure game ([Disassembly](doc/disassembly/klad.asm)), and 2048 game ([Disassembly](doc/disassembly/2048.asm)) which was (surprinsingly) developed recently.


## CP/M Operating System and Quasi Disk

The topmost UT-88 configuration adds 256k Quasi Disk, and allows running a well known CP/M v2.2 operating system, including plenty of software available for this OS. Typical CP/M program uses CP/M API for disk and console operations, and therefore provides high level of compatibility with other computers working on the same OS.

Quasi Disk is a 64/128/192/256k RAM module (depending on how many RAM chips available), organized in 1-4 64k banks. Module schematics uses a nice trick: i8080 CPU generates different signals when accessing stack and regular memory. Thus quasi disk RAM is enabled for stack push/pop instructions, while the main memory is accessible with regular read/write operations. This makes possible main RAM and quasi disk operate simultaneously in the same address space. A special configuration port `0x40` allows selecting a RAM bank, or disconnect from the quasi disk, so that stack operations are routed back to the main RAM.

The magazine mentions that Quasi Disk may be powered from an accumulator, and therefore data on the disk may 'persist' for a long time.

CP/M system provides modular design, and consists of a few components:
- [Console Commands Processor (CCP)](doc/disassembly/cpm64_ccp.asm) is a user facing application, that accepts and interprets user commands, and runs user programs.
- [Basic Disk Operating System (BDOS)](doc/disassembly/cpm64_bdos.asm) provides a rich set of high level functions to work with console (print a string, input a line from console to a buffer), and rich set of file functions (create/open/read/write/close file, search for a file by pattern)
- [Basic Input/Output System (BIOS)](doc/disassembly/cpm64_bios.asm) provide low level functions to work with console (input/output a char), and disk operations (select disk, read/write disk sector).

While CCP and BDOS are hardware-independent components, and provide the same code for all systems, BIOS is specific for a hardware platform. Thus this particular CP/M version is provided with BIOS taylored specifically for UT-88:
- Keyboard input are routed to MonitorF implementation
- Character printing functions provide an [additional layer](doc/disassembly/cpm64_monitorf_addon.asm) on top of MonitorF function, that implements some sort of ANSI escape sequences to move the cursor. MonitorF already provides a similar functionality, but this module provides a different char sequences to control the cursor position.
- Disk operations provide access to the quasi disk, implementing disk/track/sector selection functions, as well as sector read/write operations that actually transfer data to/from the disk. Depending on the selected track, BIOS enables corresponding Quasi Disk RAM bank.
- BIOS also exposes a structure that describes physical and logical structure of the quasi disk. This structure is used by BDOS to properly allocate data on the disk.

Since Quasi Disk is essentially a RAM module, it does not have a concept of sectors and tracks. BIOS is responsible for emulating the disk tracks and sectors to match CP/M concepts. Exposed disk structure:
- 64/128/192/256 tracks (depending on the quasi disk size)
- First 6 tracks are reserved for the system (see boot approach description below)
- 8 sectors per track

The following describes the main memory map, as well as CP/M components layout:
- `0x0000`-`0x00ff` (256 bytes) - base memory page, contains warm reboot and BDOS entry points, default disk buffer area, which is also used to pass parameters between CCP and user programs.
- `0x0100`-`0xc3ff` (almost 49k) - transient programs area. CCP loads and executes user programs in this memory range. User programs are free to use this memory for their data and variables.
- `0xc400`-`0xcbff` - CCP and its data variables
- `0xcc00`-`0xd9ff` - BDOS and its data variables
- `0xda00`-`0xdeff` - BIOS and its data variables
- `0xe800`-`0xefff` - Video RAM
- `0xf400`-`0xf7ff` - MonitorF RAM, including
  - `0xf500`-`0xf620` - Put Char function addon
- `0xf800`-`0xffff` - MonitorF ROM

The CP/M system comes as a single binary, that loads at `0x3100`. A [special bootstrap code](doc/disassembly/CPM64_boot.asm) performs loading of CP/M components at their addresses, as well as initializes the quasi disk. Eventualy the bootstrap component executes the CP/M starting `0xda00` address (BIOS cold boot handler).

CP/M bootstrap file can be found [here](tapes/CPM64.RKU). Start address is `0x3100`. Alternatively, to simplify and speed up loading in the emulator, all CP/M components were extracted in separate tape files, that load to their correct CP/M locations - [CCP](tapes/cpm64_ccp.rku), [BDOS](tapes/cpm64_bdos.rku), [BIOS](tapes/cpm64_bios.rku), [Put char addon](tapes/cpm64_monitorf_addon.rku). In case of loading CP/M components separately, start address is `0xda00`.

As per CP/M design, there are 2 startup scenarios for the system:
- cold boot operation performs disk initialization, and uploads CP/M system components to first several tracks of the disk, specifically reserved to contain the system (in case of UT-88 first 6 tracks of the quasi disk are reserved for the system).
- warm boot operation assumes that disk system and BIOS are already initialized. In this case CCP and BDOS components are loaded from the disk (in case if these ares were modified/erased by the user program). During cold boot CP/M startup code puts a JMP WARM_BOOT instruction at 0x0000 so that all subsequent boots, or a CPU reset will go through the warm boot scenario.

While CP/M system and various CP/M programs are basically working on UT-88 hardware, there are 2 compatibility issues:
- UT-88 video module uses KOI-7 N2 encoding, which means there are no lower case Latin letters, and upper case Cyrillic letters are used instead. Thus all lower case text messages are printed with Cyrillic letters. Although this is somewhat readable, it looks quite weird.
- CP/M BIOS expects 2 functions to deal with the terminal input: Wait for a key, and check if a key is currently pressed. Although MonitorF provides basically the same functionality, these are incompatible in details. 
  - MonitorF keyboard press function generates a signal on the first key press. If the key is still pressed, subsequent calls to Wait for key function will not be processed. This is done to avoid flooding console with keypress events. Thus subsequent wait for key function will wait until the key is released and pressed again (or keyboard auto-repeat triggers).
  - CP/M BIOS expects immediate result - if a key is pressed, wait for key function shall return the code of the pressed function immediately. 
  - CP/M BIOS _printing_ function checks for a keyboard activity, looking whether user pressed Ctrl-C break key combination. 
  - So it causes strange scenarios: the user has entered a symbol, symbol is echoed on the console, printing function sees that the key is _still_ pressed, and starts waiting for a new key. This leads to swallowing every second entered key, which is very annoyhing (at least when running in emulator).
  - As a quick work around the problem, reading the keyboard while printing a symbol was disabled in the emulator.

### CP/M-35 (CP/M with no quasi disk)

For those users who cannot afford quasi disk module, a special CP/M version is offerred with in-memory RAM drive. Following the CP/M design, CCP and BDOS components remain the same as in normal disk version of CP/M. At the same time system comes with a [special BIOS version](doc/disassembly/cpm35_bios.asm) that allocates a 35k RAM drive in the system memory. 

CP/M-35 comes as a single binary, but there is no bootstrap process like in full CP/M version. Instead, CP/M components are immediately loaded to their working addresses.

Memory map and CP/M components layout:
- `0x0000`-`0x00ff` (256 bytes) - base memory page, contains warm reboot and BDOS entry points, default disk buffer area, which is also used to pass parameters between CCP and user programs.
- `0x0100`-`0x33ff` (only 12.5k) - transient programs area. CCP loads and executes user programs in this memory range. User programs are free to use this memory for their data and variables.
- `0x3400`-`0x3bff` - CCP and its data variables
- `0x3c00`-`0x49ff` - BDOS and its data variables
- `0x4a00`-`0x4c50` - BIOS and its data variables
- `0x5000`-`0xdfff` (36k) - RAM drive
- `0xe800`-`0xefff` - Video RAM
- `0xf400`-`0xf7ff` - MonitorF RAM
- `0xf800`-`0xffff` - MonitorF ROM

Special notes about this CP/M version (and particularly BIOS implementation):
- Surprisingly, the BIOS exposes 4 disk drives, all pointing to the same data memory.
- Although 36k are allocated for the RAM disk, the disk descriptor exposes only 35k drive
- There is no special addon that supports ANSI escape sequences
- 0 tracks are reserved on the disk for the system. Cold boot process does not copy system to the disk
- There is no warm boot supported. Instead, MonitorF will take operation during reboot.

CP/M-35 binary is located [here](tapes/CPM35.RKU). Start address is `0x4a00`.


# UT-88 Emulator

This project is an emulator of the UT-88 hardware, including CPU, memory, and I/O peripherals. The architecture of the emulator pretty much reflects the modular computer design. 

## Emulated hardware components

This section describe main parts of the emulator, and outlines important implementation notes. Each component and their relationships are emulated as close as possible to the real hardware.

- [CPU](src/cpu.py) - implements the i8080 CPU, including its registers, instruction implementation, interrupt handling, and instruction fetching pipeline. This class also provides optional rich instruction logging capabilities for code disassembly purposes. The implementation is inspired by [py8080 project](https://github.com/matthewmpalen/py8080).
- [Machine](src/machine.py) - implements the machine as a whole, sets up relationships between the CPU, registered (installed) memories, attached I/O devices, and interrupt controller (if it would exist for the UT-88 machine). The concept of the Machine class allow emulating UT-88 design closer to how it works in the hardware. Thus it implements some important concepts:
    - Real CPU does not read the memory directly. Instead, the CPU sets the desired address on its address lines, and reads the data that a memory device (if connected and selected) sets on the data bus. This is emulated in the same way: the CPU is a part of the particular Machine configuration, and can access only a memory which is installed in this configuration. Same for I/O devices, which may vary for different computer configurations.
    - Reset button resets only the CPU, but leaves the RAM intact. This makes possible some workflows implemented in the Monitor 0, where exiting from some modes (e.g. Memory read or write) is performed using the Reset button.
    - Some types of memory is triggerred with stack read/write operations. Thus the Quasi Disc module is connected in this way. This allows RAM and Quasi Disk operate in the same address space, but use different accessing mechanisms.
    - The UT-88 Computer does not have an interrupt controller. Instead if an interrupts occurr, the data bus will have 0xff value on the line due to pull-up resistors. This coincide with the RST7 instruction, that runs an interrupt handler.
- [RAM](src/ram.py), [ROM](src/rom.py), stack memories (e.g. Quasi Disc), and I/O devices are connected to the machine according to a few [generic interfaces](src/interfaces.py). This allows extending functionality of the computer with new devices very easily - just implement the interface, and register the device/memory in the Machine object. Note that some devices (such as [LCD display](src/lcd.py)) in fact connected to a memory bus, and not to the I/O devices space.
- Finally, the [Emulator](src/emulator.py) class provides handy routines for emulating the machine and its CPU. Particularly, this class adds routines to run a single or multiple machine steps, and handle breakpoints. The breakpoint concept is a handy way to do emulator side actions, based on the machine condition or CPU state. Particularly it is possible to add some extra logging when a CPU enters a specific stage or executes a certain code.

The following peripherals is emulated:
- [17-button hexadecimal keyboard](src/hexkbd.py) (16 digits, and a step back button) is connected to I/O port `0xa0` (read only). Reading the port will return the button scan code, or 0x00 if no button is pressed. The implementation checks host computer button presses (using pygame) and converts it to UT-88 Hex keyboard scan codes. 
- [6-digit 7-segment display](src/lcd.py), mapped to memory range `0x9000`-`0x9002` (Write only). The implementation displays images of the 7-segment indicators (using pygame) according to values in the memory cells. 
- [Tape port](src/tape.py), mapped to I/O port `0xa1` LSB. The implementation of the class emulates 2-phase coding of the data (with some hacks), native for the UT-88 Monitors (both 0 and F). The tape emulator can load a binary file and convert it to a series of bit values, so that the Monitor can correctly read it with IN instruction, and treat it as a correct tape data. And vice versa, the emulator can collect data bits, that Monitor sends using OUT instructions, and convert them into a file on disk. The implementation is a little bit hacky, as it is not really time based, but just counts In and Out calls.
- [Seconds Timer](src/timer.py) is not connected to any data buses in the computer, but generates an interrupt every second. As said previously, Machine will set `0xff` on the data line, so that CPU will treat it as RST7 instruction.
- [Display](src/display.py) emulates the 64x28 chars monochrome display. Technically this is a piece of RAM at `0xe800`-`0xefff` that CPU can write to. Every character is displayed according to the Font ROM used in the original hardware (each symbol is displayed as 6x8 dot matrix). Font can display chars in `0x00`-`0x7f` range. MSB is used to invert the symbol (e.g. to show the cursor). Symbols in `0x00`-`0x1f` range are pseudo-graphics symbols, that allows converting the display to pseudo 128x56 dots graphic display.
- [Keyboard](src/keyboard.py) class emulates a 55-button keyboard connected through a i8255 controller to `0x04`-`0x07` ports. The monitor does a keyboard matrix scan by setting low levels on a column (via Port A) and reading rows (via Port B). The emulator handles host computer key presses (taking onto account Shift and Ctrl mod keys, and Russian keyboard layout), and sets Port B/C scan codes accordingly. The Monitor F reads these scan codes, and converts them to char codes.

The Emulator class, as well as CPU, memories, and some of the peripherals are UI agnostic. This means it can work as a non-UI component, executed in a script, or be checked in automated tests.

Other components, such as LCD, Display and keyboards interact with the User. This is done using [pygame](https://www.pygame.org/) framework. In order to properly handle the keyboard input, and prepare output graphics, components have an `update()` method. The update signal is propagated via Machine object to all memories and devices registered in the Machine. The `update()` method is called approx 15-60 times a second, providing a way to emulate these devices.


## Running the emulator

To run the emulator in basic UT-88 configuration
```
python src/main.py basic
```

This is how to run the emulator in Video UT-88 configuration
```
python src/main.py video
```

The `--debug` option will enable CPU instructions logging. In order not to clutter the log for dumping waiting loops, each configuration suppresses logging for some well known functions (e.g. various delays, printing a character, input/output a byte to the tape, etc)

## Tests

In order to verify correctness of the implemented features (especially CPU instructions), a comprehensive [set of automated tests](test) was developed. These tests also help to control massive changes across the codebase, and verify that nothing is broken with the change.

Most of the tests cover a component functionality in isolation. Some tests require a few components work together (e.g. Machine + RAM + CPU). In order not to use hard-to-set-up or User facing components, [Mocks](test/mock.py) are used where it is convenient.

Some tests, such as [Calculator tests](test/test_calculator.py) are not really tests in classic meaning - it does not suppose to _test_ the firmware (though it found a few issues). These tests is a simple and handy way to execute some functions in the firmware.

Tests are implemented with pytest framework.

To run tests:
```
cd test
py.test -rfeEsxXwa --verbose --showlocals
```

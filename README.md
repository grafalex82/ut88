# UT-88 Soviet DIY i8080-based Computer Emulator

This is an emulator of the UT-88 computer, developed using Python. The project has two primary objectives:
- Understand the computer schematics, and emulate it as close as possible to the real hardware
- Understand software part of the computer, disassemble and document it

Additionally, this project serves as the most comprehensive repository of UT-88 related information, encompassing:
- scematics and modules descriptions
- binary files (addressing numerous scanning issues compared to other binaries available on the internet)
- Disassembly of every program ever published for the UT-88, and even beyond.

## UT-88 - Computer Description

UT-88 (Russian: ЮТ-88) is a DIY computer originally introduced in "Young Technician - For Skilled Hands" magazine (Russian: "ЮТ Для Умелых Рук") on Feb 1989. In late 1980s, a typical DIY computers were notably complex, comprised of numerous components, and demanded substantial technical expertise to assemble and bring it up. In contrast, the UT-88 presented an elegantly simple design and a step-by-step construction process. This approach significantly broadened its appeal to a wider audience, including children and hobbyists.

The magazine featured both computer schematics and software code, with the intention of guiding readers through a computer construction process in several phases:
- **Basic Configuration:** The CPU module resembled a calculator, featuring a 6-digit LCD display and a hexadecimal button keypad.
- **Calculator Add-on:** This expanded the capabilities by incorporating a ROM with floating-point functions, enabling scientific calculations.
- **Video Module:** The next phase introduced a 55-key alphanumeric keyboard and a 64x28 character monochrome display (with TV output).
- **Dynamic 64k RAM:** This upgrade allowed users to run programs from other compatible computers.
- **64k-256k Quasi Disk:** A battery-powered dynamic RAM was added, providing the capacity to store a substantial amount of data.
- **Custom Add-ons:** In addition to the phases listed above, there were custom add-ons, including a Flash memory programmer and an i8253-based sound generator.

These phases offered readers a structured approach to gradually build and enhance the UT-88 computer according to their preferences and needs. Each phase of the UT-88 build not only expanded the hardware but also enriched the software capabilities, providing users with a versatile computing experience.

From a software perspective, each phase of the UT-88 computer build introduced additional functionalities:
- **Basic Configuration:** In the basic configuration, users could perform basic computer operations such as memory read/write, CRC calculations, load programs from tape, and create and execute simple programs.
- **Video Module:** With the video module installed, the UT-88 could run text-based programs, including simple text-based video games.
- **Full Configuration:** Achieving the full configuration unlocked the ability to run the UT-88 operating system. This OS offered essential tools like a full screen text editor and an assembler, enhancing compatibility with other i8080-based computers.
- **Special CP/M Port:** The magazine also provided an unique port of the CP/M operating system, enabling users to work with files stored on the quasi disk, expanding the computer's capabilities even further.

The architecture of the UT-88 computer draws significant inspiration from two previously published computer systems: the Micro-80 (from the early 1980s) and the Radio-86RK (featured in the 'Radio' magazine between 1985 and 1987). Several technical solutions and design elements are inherited from these predecessors, enhancing the UT-88's overall functionality and compatibility. Key elements carried over from its predecessors include connectivity with tape recorders and the associated recording format, the layout and schematics of the keyboard, and the general hardware framework.

Notably, the UT-88 distinguishes itself by incorporating more advanced and refined schematics. This includes the integration of components like the i8224 and i8238, which replace a multitude of TTL logic gate chips used in the Radio-86RK. Additionally, the UT-88's peripheral are connected to the CPU using I/O address space, in contrast to the Radio-86RK where peripherals were located within the main memory address space. Furthermore, the UT-88's design takes into account chip availability, addressing the scarcity of the i8275 chip in late USSR. In response, the UT-88's video module employs a combination of registers and counters, providing a practical alternative for the video signal generation.

On the software front, the UT-88 maintains a high degree of compatibility with its predecessors. For instance, the Monitor F, which serves as the primary firmware for the Video Module, closely resembles the Radio-86RK Monitor and shares common routine entry points. This compatibility allows for the loading and execution of Radio-86RK programs from tape with minimal to no modifications, underscoring the seamless transition between these related computer systems.

Scans of the original magazine can be found [here](doc/scans).

## UT-88 Basic Configuration

The basic UT-88 configuration consists of the following components:
- **CPU**: It employs the КР580ВМ80/KR580VM80 CPU, a functional clone of the Intel 8080A.
- **Supplemental Chips**:
  - КР580ГФ24/KR580GF24 clock generator (Intel 8224 clone).
  - Address buffers.
  - КР580ВК38/KR580VK38 system controller (Intel 8238 clone).
- **Memory**:
  - 1kb ROM located at addresses `0x0000`-`0x03ff`.
  - 1kb RAM positioned at addresses `0xc000`-`0xc3ff`.
- **Display**: It features a 6-digit 7-segment indicator used to display 3-byte registers located at memory addresses `0x9000`-`0x9002`. The typical usage is to show 2-byte address information and 1-byte of data. The display addresses data from right to left (`0x9002` - `0x9001` - `0x9000`) to present 2-byte addresses naturally.
- **Keyboard**: The computer is equipped with a 17-button keyboard that enables the input of 16 hexadecimal digits for general-purpose use. It also includes a "step back" button used for correcting the previously entered byte when manually entering a program. The keyboard is connected to I/O port `0xa0`.
- **Reset Button**: A reset button is provided, which resets only the CPU while leaving the RAM content intact.
- **Tape Recorder I/O**: The system includes tape recorder input/output capabilities for loading and storing data and programs. This functionality is connected to the least significant bit (LSB) of I/O port `0xa1`.
- **Clock Timer**: A clock timer generates interrupts every 1 second. Since there is no interrupt controller in the system, the CPU reads the data line pulled up to `0xff`, which acts as the RST7 command. A special handler in the firmware manages the advancement of hours, minutes, and seconds values in software mode.

The minimal firmware, called "Monitor 0" (as it is located from `0x0000`), provides common routines and serves as a basic operating system for the UT-88 computer. "Monitor 0" is divided into two distinct parts within the ROM:
- `0x0000-0x01ff` - Essential Part ([see disasssembly](doc/disassembly/monitor0.asm)). This section encompasses:
    - Convenient routines for keyboard input, LCD output, and tape data input and output.
    - A basic operating system that allows users to read and write memory and ROM, calculate CRC, and execute programs.
    - A real-time clock for tracking the current time.
- `0x0200-0x03ff` - Optional part ([see disasssembly](doc/disassembly/monitor0_2.asm)). This optional segment includes a few useful programs:
    - Memory copying programs, including special cases for inserting or removing a byte from a program.
    - Memory comparison programs.
    - Address correction programs designed to rectify addresses after a program has been relocated to another memory region.

Memory map of the UT-88 in Basic Configuration:
- `0x0000`-`0x03ff` - Monitor 0 ROM
- `0x0800`-`0x0fff` - Optional Calculator ROM (see below)
- `0x9000`-`0x9002` - LCD screen (3 bytes, 6 digits)
- `0xc000`-`0xc3ff` - RAM

I/O address space map:
- `0xa0`  - hex heyboard
- `0xa1`  - tape recorder

Usage of the Monitor 0:
- Upon CPU reset, Monitor 0 will display the number `11` on the right display to indicate its readiness to accept commands.
- Users can input commands using the Hex Keyboard. Certain commands may require additional parameters, as described below.
- Some commands will automatically perform a CPU reset when they are finished. This will leave the computer ready to accept a new command. Conversely, certain commands are designed to be continuous and will engage with the user until the Reset button is pressed. These commands will remain active until manually interrupted.

Monitor0 Commands:
- 0 `addr`    - Manually enter data from memory address `addr`. 
  - Current address is displayed on the LCD
  - Monitor0 waits for the byte to be entered
  - The entered byte is stored at the current address, then address advances to the next byte
  - To exit memory write mode press the Reset button. The memory data will be preserved.
- 1           - Manually enter data starting from memory address `0xc000` (similar to command 0)
- 2           - Read memory data starting from memory address `0xc000` (similar to command 5)
- 3           - Run an LCD test
- 4           - Run a memory test for the range of addresses `0xc000` to `0xc400`.
  - If a memory error is found, the LCD will display the address and the read value.
  - Displaying address `0xc400` on the LCD means no memory errors were found.
  - To exit memory test mode, press the Reset button.
- 5 `addr`    - Display data starting from memory address `addr`
  - The current address and the byte at the address are displayed on the LCD.
  - Press a button to display the next byte.
  - To exit memory read mode, press the Reset button. The memory data will be preserved.
- 6           - Start the program from memory address `0xc000`
- 7 `addr`    - Start the program from the user-specified address.
- 8 `a1` `a2` - Calculate CRC for the address range from `a1` to `a2`
- 9 `a1` `a2` - Store data at the address range from `a1` to `a2` to the tape.
- A `offset`  - Read data from the tape with the specified offset (relative to the start address written on the tape).
- B           - Display current time (`0x3cfd` - seconds, `0x3cfe` - minutes, `0x3cff` - hours)
- C `addr`    - Enter a new time (similar to Command 0, but with interrupts disabled). The address should be `0x3cfd`

Monitor 0 incorporates several useful routines designed for both the Monitor itself and user programs. Unlike the conventional approach, where 3-byte CALL instructions are used to execute these routines, Monitor 0 employs 1-byte RSTx instructions. This innovative approach optimizes code size, allowing for efficient use of the limited ROM space.

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
- 256 * `0xff`  - pilot tone, to sync with the sequence
- `0xe6`        - synchronization byte, marks polarity and start of data bytes
- 2 bytes       - start address (high byte first)
- 2 bytes       - end address (high byte first)
- `bytes`       - data bytes

No CRC bytes are stored on the tape. Instead, the CRC value is displayed on the screen following store and load commands. It is the user's responsibility to validate the CRC for data integrity.

Programs in the second part of Monitor 0  extend the functionality of Monitor 0, providing tools for memory operations, address corrections, data comparisons, and register displays. Users can call these programs with Command 7 from the respective start addresses listed below:
- `0x0200` - **Memory copying program**:
  - Accepts source start address, source end address, and target start address.
  - Can handle cases where the source and destination memory ranges overlap.
- `0x025f` - **Address correction program**:
  - Used to fix address arguments of 3-byte instructions after a program has been relocated to a new address range.
  - Accepts the start and end address of the original program and the destination address.
- `0x02e5` - **"Super" Address correction program**:
  - Similar to the previous program but performs address correction *before* copying the program to a different address range.
  - Accepts the start and end addresses of the program to correct and a destination address where the program is intended to operate.
- `0x0309` - **Replace address program**:
  - Replaces all occurrences of an address within a specified range with another address.
  - Accepts the start and end address of the program to correct, the address to search for, and the replacement address.
- `0x035e` - **Insert byte program**:
  - Shifts the range 1 byte further.
  - Accepts the start and end address of the range to be moved.
- `0x0388` - **Delete byte program**:
  - Shifts the range 1 byte backward and corrects addresses within the range.
  - Accepts the start and end address of the range to be moved.
- `0x03b2` - **Memory compare program**:
  - Accepts the start and end address of a source range and the start address of the range to compare with.
- `0x03dd` - **Display registers helper function**:
  - Displays AF, BC, DE, HL, and the memory byte underneath the HL pointer.


In the Basic Configuration, the UT-88 computer offers limited software variety. The programs included with the Basic CPU module instructions, however, may not meet the same quality standards as the main firmware, possibly being authored by the UT-88 creator's students. These programs are as follows:
- [Tic Tac Toe game](doc/disassembly/tictactoe.asm) - a classic game. Computer always goes first, and there is no way for the player to win.
- [Labyrinth game](doc/disassembly/labyrinth.asm) - player searches a way in a 16x16 labyrinth.
- [Reaction game](doc/disassembly/reaction.asm) - program starts counter, goal to stop the counter as early as possible.
- [Gamma](doc/disassembly/gamma.asm) - generates gamma notes to the tape recorder.

Basic CPU module schematics can be found here: [part 1](doc/scans/UT08.djvu), [part 2](doc/scans/UT09.djvu).


## UT-88 Calculator Add-On

The calculator add-on is a valuable extension for the UT-88 computer, introducing a 2k ROM at the memory address range `0x0800`-`0x0fff`. This calculator add-on significantly expands the computational capabilities of the UT-88 computer, enabling users to perform advanced mathematical operations and trigonometric calculations with ease. The ROM contains a set of functions designed to work with floating-point values, offering a wide range of mathematical operations. 

- **Arithmetic Operations**: The calculator ROM provides support for basic arithmetic operations, including addition (+), subtraction (-), multiplication (*), and division (/) of floating point values.
- **Trigonometric Functions**: Users can also access trigonometric functions, such as sine (sin), cosine (cos), tangent (tg), cotangent (ctg), arcsine (arcsin), arccosine (arccos), arctangent (arctg), and arccotangent (arcctg). These functions are computed using Taylor series calculations.

The calculator ROM operates with 3-byte floating-point numbers, each consisting of an 8-bit signed exponent and a 16-bit signed mantissa. These numbers are represented in Sign-Magnitude form, enhancing user-friendliness and simplifying the process of handling them as a whole or working with their individual parts (exponent and mantissa).

It's important to note that the calculator ROM does not include built-in functionality for converting these floating-point numbers to or from decimal form. Users are expected to work with these numbers in their hexadecimal representation.

The choice of 3-byte floating-point values strikes a balance between accuracy and computational efficiency. Basic arithmetic calculations are executed quite fast, enabling users to develop their own calculation algorithms based on the provided building blocks. However, some of the trigonometric functions involve high exponent values, numerous multiplications, and divisions, resulting in reduced accuracy for certain values (approximately ±0.01) and longer execution times (exceeding 10 seconds).

It's important to note that the ROM offers a set of functions with fixed starting addresses. Unlike modern programming approaches, where parameters and results are typically passed via stack or registers, these functions expect parameters and store results at specific, predetermined memory addresses. This design choice adds complexity to client programs, which must manage the copying of values to and from these specific addresses.

While the use of fixed memory addresses may present challenges, it allows for efficient use of the limited resources and capabilities of the UT-88 computer, making the most of its computational power and expanding its functionality for mathematical operations.

The disassembly of the calculator ROM can be found [here](doc/disassembly/calculator.asm). Refer to the disassembly for parameters/result addresses, as well as for algorithm explanation. 

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

To enhance comprehension of 3-byte floating-point numbers and facilitate their usage, a dedicated Python component called [Float](misc/float.py) was developed. This component enables the conversion of these 3-byte floating-point numbers to and from regular 4-byte floating-point numbers commonly used in computing.

To streamline the process of calling library functions for disassembly and testing purposes, a comprehensive [set of automated tests](test/test_calculator.py) was designed. These tests are intended not to _validate_ the functionality of the library functions, but rather to execute various branches of the code and assess the accuracy of the results. They serve as valuable tools for analyzing and verifying the behavior and performance of the library functions under different conditions.

Add-on schematics can be found [here](doc/scans/UT18.djvu).

## UT-88 Video Module

The Video Module is a pivotal addition to the UT-88 computer, bringing with it a 64x28 character monochrome display and a 55-key keyboard. With this module in place, the UT-88 transforms into a fully-fledged computer, capable of running text-based video games, text editors, programming language compilers, and a wide array of applications.

The Video Module not only enhances the UT-88's functionality but also offers a high level of compatibility with previously released Radio-86RK and its various modifications. This compatibility ensures that using and porting programs from the Radio-86RK to the UT-88 is a straightforward and manageable task. It effectively bridges the gap between these related computer systems, enabling a seamless transition of software and expanding the UT-88's capabilities.

Here's a detailed description of the hardware additions to the UT-88 computer:
- **Video Adapter**: 
  - The Video Adapter is built around a 2-port RAM located in the address range `0xe800`-`0xefff`. One port of this memory is connected to the computer's data bus and functions like regular memory. A specialized circuit, consisting of counters and logic gates, reads the video memory through the second port and converts it into a TV signal.
  - Additionally, a dedicated 2k ROM (not connected to the data bus) serves as a font generator. 
  - The video adapter is capable of displaying a 64x28 monochrome character matrix, with each character being 6x8 pixels in size. The character set matches the KOI-7 N2 encoding: characters in the `0x00`-`0x1f` range providing pseudo-graphic symbols, characters in the `0x20`-`0x5f` range matching the standard ASCII table, and characters in the `0x60`-`0x7f` range allocated for Cyrillic symbols.
  - The highest bit of each character signals the video controller to invert the symbol.
- **Keyboard**:
  - The keyboard is connected via an i8255 chip to ports 0x04-0x07, with the two lowest bits of the address inverted.
  - The keyboard comprises a 7x8 button matrix connected to Port A (columns) and Port B (rows) of the i8255. Three modification keys are used to enter special, control, and Cyrillic symbols and are connected to Port C.
  - The keyboard matrix scanning and conversion of scan codes to ASCII character values are managed by Monitor F.
- **Memory Additions**:
  - A 1k RAM is located at the address range `0xf400`-`0xf7ff`.
  - A 2k ROM, containing Monitor F, resides in the address range `0xf800`-`0xffff`.
  - Optionally, a 4k RAM can be connected to the address range `0x3000`-`0x3fff`.
- **External ROM Support**:
  - An optional external ROM can be connected via another i8255 chip at ports `0xf8`-`0xfb`. However, it's worth noting the schematics of the external ROM was published 2 years later than the other computer components. Unfortunately the firmware support does not look correct. 

The Video Module seamlessly integrates with the CPU Basic Module components, allowing for the coexistence of these hardware modules. In the Video Module configuration, the Tape Recorder connection is utilized at port `0xa1`, and the LCD screen connected to addresses `0x9000`-`0x9002` can be employed to display various information, such as the current time. Some other components, such as the Monitor 0 ROM at addresses `0x0000`-`0x03ff`, may be disconnected and replaced with alternative memory modules, such as additional RAM. Additionally, the hexadecimal keyboard is not used in the Video Module configuration.

The primary firmware for the Video Module is Monitor F, as it resides at memory addresses starting from `0xf800`. Monitor F provides a comprehensive set of routines to interact with the new hardware components, including display and keyboard input. These routines are accessed via static and predefined entry points, each serving specific purposes:
- `0xf800`    - Software reset
- `0xf803`    - Wait for a keyboard press, returning the entered symbol in register A
- `0xf806`    - Input a byte from the tape (A - number of bits to receive or `0xff` if synchronization is needed). Returns the received byte in register A.
- `0xf809`    - Put a character to the display at the cursor location (C - character to print)
- `0xf80c`    - Output a byte to the tape (C - byte to output)
- `0xf80f`    - This function is supposed to print a byte on a printer. Since the printer connectivity is not implemented in UT-88, this function is just an alias for `0xf809` (put char to the display)
- `0xf812`    - Check if any button is pressed on the keyboard (A=`0x00` if no buttons are pressed, `0xff` otherwise)
- `0xf815`    - Print a byte in a 2-digit hexadecimal form (A - byte to print)
- `0xf818`    - Print a NULL-terminated string at the cursor position (HL - pointer to the string)
- `0xf81b`    - Scan a keyboard, returning when a stable scan code is read (returns the scan code in register A)
- `0xf81e`    - Get the current cursor position (offset from `0xe800` video memory start, returned in registers HL)
- `0xf821`    - Get the character under the cursor (returned in register A)
- `0xf824`    - Load a program from tape (HL - offset, returns CRC in registers BC)
- `0xf827`    - Output a program to the tape (HL - start address, DE - end address, BC - CRC)
- `0xf82a`    - Calculate CRC for a memory range (HL - start address, DE - end address, result in registers BC)

These predefined entry points simplify interaction with the Video Module hardware and enable efficient development of software that leverages its capabilities. For detailed information on arguments and return values, as well as algorithm descriptions, please refer to the [Monitor F disassembly](doc/disassembly/monitorF.asm).

The character output function operates in a terminal mode, where the symbol is printed at the cursor's current position, and then the cursor advances to the next position. When the cursor reaches the end of a line, it automatically advances to the next line. If the cursor reaches the bottom-right position of the screen, the screen is scrolled down by one line to make room for additional text.

Additionally, the character output function supports several control symbols for special actions:
- `0x08`  - Moves the cursor one position to the left.
- `0x0c`  - Moves the cursor to the top-left position of the screen.
- `0x18`  - Moves the cursor one position to the right.
- `0x19`  - Moves the cursor one line up.
- `0x1a`  - Moves the cursor one line down.
- `0x1f`  - Clears the entire screen.
- `0x1b`  - Moves the cursor to a specific position. This is achieved using a 4-symbol sequence, similar to an Escape sequence, consisting of `0x1b`, `'Y'`, `0x20` + Y position, and `0x20` + X position.

In addition to its general-purpose routines, Monitor F offers a basic command console that provides users with several essential capabilities:
- **View, Modify, Copy, and Fill Memory Data**: Users can interactively view the contents of memory, make modifications to memory values, copy data from one memory location to another, and fill specific memory ranges with desired values. These commands are invaluable for low-level memory manipulation and debugging.
- **Input from and Output Programs to the Tape Recorder**: Monitor F allows users to load programs from a connected tape recorder into the computer's memory. It also provides the functionality to save programs from memory onto a tape recorder for storage or sharing. These operations are crucial for program transfer and archival purposes.
- **Run User Programs with Breakpoint Possibility**: Users can execute their own programs loaded into memory. Monitor F offers the convenience of setting breakpoints, which enable users to pause program execution at specific memory addresses. Breakpoints are a valuable tool for debugging and tracing program flow.
- **Handle Time Interrupt and Display Current Time**: The Monitor F console includes functionality for handling time interrupts and displaying the current time. This feature is especially useful for applications that require precise timing or for monitoring the passage of time during program execution.

The following commands are supported by the Monitor F:
- **Memory commands**:
  - `D` `<addr1>`, `<addr2>`        - Dump the memory range in hexadecimal format.
  - `L` `<addr1>`, `<addr2>`        - List the memory range in text format, with '.' indicating non-printable characters.
  - `K` `<addr1>`, `<addr2>`        - Calculate the CRC for the specified memory range.
  - `F` `<addr1>`, `<addr2>`, `<val>` - Fill the memory range with the provided constant value.
  - `S` `<addr1>`, `<addr2>`, `<val>` - Search for the specified byte value in the memory range.
  - `T` `<src1>`, `<src2>`, `<dst>`   - Copy (Transfer) the memory range specified by `<src1>`-`<src2>` to the destination `<dst>`
  - `C` `<src1>`, `<src2>`, `<dst>`   - Compare the memory range specified by `<src1>`-`<src2>` with the range starting from `<dst>`
  - `M` `<addr>`                  - View and edit memory starting at address `<addr>`
- **Tape commands**:
  - `O` `<start>`, `<end>`[, `<spd>`] - Save the memory range to the tape. Optionally, use the speed constant if provided.
  - `I` `<offset>`[, `<spd>`]       - Load a program from the tape and apply the specified offset. Optionally, use the speed constant.
  - `V`                         - Measure the tape loading delay constant.
- **Program execution**:
  - `W`                         - Start the program from address `0xc000`.
  - `U`                         - Start the program from address `0xf000`.
  - `G` `<addr>`[, `<brk`>]         - Start or continue the program from the specified address `<addr>`. Optionally, set a breakpoint at address `<brk>`.
  - `X`                         - View and modify CPU registers when a breakpoint is hit.
- **Time commands**:
  - `B`                         - Display the current time at the CPU module's LCD.
- **External ROM**:
  - `R` `<start>`, `<end>`, `<dst>`   - Import data from the external ROM in the range `<start>`-`<end>` to the destination memory location `<dst>`.

The tape format used in Monitor F is an extension of the format used in Monitor 0, with two notable additions:
- The recording format now includes a CRC, which is used for error detection. Monitor F can detect a CRC mismatch between the stored CRC value and the calculated CRC value, allowing it to report this discrepancy to the user.
- Users have the option to adjust the tape speed by specifying a "tape constant". This tape constant represents the delay between individual bits in the recorded data. This feature is included to standardize the format and accommodate potential variations in tape recording speeds due to differences in crystal frequencies between computers like Micro-80 and Radio-86RK.

The tape recording format, with the additional fields introduced in Monitor F, is as follows:
- 256 x `0x00` - pilot tone
- `0xe6`       - Synchronization byte
- 2 byte       - start address (high byte first)
- 2 byte       - end address (high byte first)
- data bytes   - program data bytes
- `0x0000`     - micro-pilot tone (2 bytes)
- `0xe6`       - Synchronization byte
- 2 byte       - Calculated CRC (high byte first)

These enhancements to the tape format improve data integrity and provide greater flexibility in working with tape recordings, ensuring accurate program loading and error detection during the tape loading process.

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

From a software perspective, the Video Module transforms the UT-88 into a classic computer with the essential components of a keyboard and monitor. This expansion enables the UT-88 to operate as a traditional computer with typical terminal-like routines expected from this type of machine. It opens the door for various software applications and interactions that are common to such computers.

One notable program published for the UT-88 with the Video Module is the Tetris game, which offers an engaging gaming experience. The Tetris game allows users to enjoy the classic block-stacking challenge on their UT-88 computer. You can find the program tape for Tetris [here](tapes/TETR1.GAM) and explore its disassembly [here](doc/disassembly/tetris.asm)).

Video module schematics can be found here: [part 1](doc/scans/UT22.djvu), [part 2](doc/scans/UT24.djvu).


## 64k Dynamic RAM

The upgrade to a 64k dynamic RAM module ([schematics](doc/scans/UT38.djvu)) significantly enhances UT-88 computer memory capabilities. While the RAM module covers the entire 64k address space, it includes special logic to disable the dynamic RAM for specific address ranges, such as `0xe000`-`0xefff` (video RAM) and `0xf000`-`0xffff` (reserved for Monitor F RAM/ROM). As a result, the effective dynamic RAM size is 56k.

This additional RAM capacity opens up the possibility of running a wider range of programs on the UT-88. It is claimed that the UT-88 is programmatically compatible with other computers in the same class, particularly the Micro-80 and Radio-86RK. However, compatibility is only partial, as some programs designed for the Radio-86RK write directly to video memory or make use of the i8275 video controller (which is not available in the UT-88). These differences can result in incompatibility with many Radio-86RK games.

Nonetheless, there are examples of Radio-86RK games that can run on the UT-88, thanks to the compatibility provided by Monitor F functions. Programs that communicate with the keyboard and display using Monitor F functions will work as expected on the UT-88. For instance, Treasure game ([Disassembly](doc/disassembly/klad.asm)) and the more recently developed 2048 game ([Disassembly](doc/disassembly/2048.asm)) are two examples of Radio-86RK games that are compatible with the UT-88.


## ROM flasher addon

The magazine offered an interesting addon for the UT-88 computer, which was a ROM flasher. This device was designed to enable the programming of 573RF2 and 573RF5 2k ROM chips, both of which were claimed to be analogs of Intel 2716 ROM chips. Overall, the ROM flasher addon added a valuable feature to the UT-88, enabling users to work with ROM chips and potentially customize their computer's functionality to suit their specific needs.

The [schematics](doc/scans/UT60.djvu) for the ROM flasher device appear to be relatively straightforward, and is based on the i8255 chip. However, it's worth noting that there is a discrepancy in the CE (Chip Enable) and OE (Output Enable) lines compared to their references in the code.

To support the ROM flasher device, a dedicated flasher program was provided. This program, which you can explore in the [disassembly](doc/disassembly/flasher.asm), allowed users to read and write to the ROM chips using the flasher device. 

## UT-88 OS

The 64k RAM configuration, with some minor modifications, enables the UT-88 to run what is referred to as the "UT-88 OS". This OS is presented as an operating system tailored specifically for the UT-88, although it should be noted that it doesn't adhere to the classical definition of an operating system. In essence, the UT-88 OS serves as a suite of tools and programs that enhance the UT-88's capabilities, making it more versatile and suitable for a range of programming and development tasks.

The components of this package include:
- **Extended Monitor**: This version of the Monitor offers an expanded set of commands, including features like a blinking cursor and improvements in text output (such as scroll control).
- **Development Tools**: The OS includes a set of development tools, such as the ability to run programs with two software breakpoints, a program relocator, an interactive disassembler, and an assembler.
- **"Micron" Text Editor**: The package incorporates a full-screen text editor known as "Micron". This editor provides users with text editing capabilities and is designed to work seamlessly within the UT-88 environment.
- **"Micron" Assembler**: This is another assembler tool in the UT-88 suite, providing a reacher syntax.

It's important to note that the UT-88 OS doesn't introduce a specific API layering, akin to what is found in operating systems like CP/M. Instead, it retains a mixture of functions that are closely related to hardware operations (e.g., keyboard, display, tape recorder), middleware (e.g., line editing functions), and higher-level programs (e.g., the interactive assembler). At the same time, the 'Micron' text editor and assembler are standalone programs that could potentially be adapted for use on other systems with minor modifications.

The UT-88 OS is loaded into memory through a [single bootstrap binary file](tapes/UT88.rku). As a part of the bootstrap loading, the User is asked to deactivate the Monitor ROM (as well as any other ROMs, if present) and enable RAM at the corresponding addresses. Once the system is reconfigured in this manner, the bootstrap program takes over and proceeds to copy the different components of the UT-88 OS to their designated memory locations.

Here is an overview of the memory map in the UT-88 OS configuration, assuming that the OS components have already been loaded by the bootstrap program:
- `0x0000` - `0xbfff` - This region represents general-purpose RAM. Some portions of this range are reserved for specific purposes:
  - `0x3000` - `0x9fff` - Text area used by the text editor for storing edited text and by assemblers for source code.
  - `0xa000` - `0xbfff` - Default area for binary code generated by the assembler.
- `0xc000` - `0xcaff` - This segment contains an additional part of the Monitor, which includes various [additional functions](doc/disassembly/ut88os_monitor2.asm), [interactive assembler/disassembler](doc/disassembly/ut88os_asm_disasm.asm), and some other development tools.
- `0xcb00` - `0xd7ff` - ['Micron' text editor](doc/disassembly/ut88os_editor.asm)
- `0xd800` - `0xdfff` - ['Micron' assembler](doc/disassembly/ut88os_micron_asm.asm)
- `0xe000` - `0xefff` - Video RAM
- `0xf400` - `0xf5ff` - A special area reserved for labels and references used during the compilation of assembler code.
- `0xf600` - `0xf7ff` - This segment is used for storing variables related to the Monitor and other UT-88 OS programs.
- `0xf800` - `0xffff` - The main part of the [Monitor](doc/disassembly/ut88os_monitor.asm) is located in this region. It includes hardware functions and handles basic command processing.

It appears that the documentation and software for the UT-88 OS suffer from various shortcomings, including insufficient command explanations, discrepancies between documented behavior and actual implementation, and mistakes in command names and descriptions. These issues can certainly make it challenging for users to understand and effectively use the software. Additionally, there are compatibility issues between various OS components, which suggest that UT-88 OS may have been assembled from different sources without thorough testing.

Published binary codes also contains a lot of mistakes (for example `0x3c00`-`0x3fff` range of the [UT-88 OS binary code](doc/scans/UT44.djvu) is misplaced with a similar range of [CP/M-35 binary](doc/scans/UT56.djvu)). Some code is obviously wrong (incorrect addresses or values used) and simply does not work out of the box. 

The following subchapters describe UT-88 OS software in detail.

### UT-88 OS Monitor

The UT-88 OS Monitor shares many similarities with the MonitorF in terms of its main entry points and functionalities. Although the API is narrower, it still provides basic I/O operations, tape input/output, display operations, and keyboard interactions:
- `0xf800`    - Software reset
- `0xf803`    - Wait for a keyboard press, returning the entered symbol in register A
- `0xf806`    - Input a byte from the tape (A - number of bits to receive or `0xff` if synchronization is needed). Returns the received byte in register A
- `0xf809`    - Put a character to the display at the cursor location (C - character to print)
- `0xf80c`    - Output a byte to the tape (C - byte to output)
- `0xf80f`    - This function is supposed to print a byte on a printer. Since the printer connectivity is not implemented in UT-88, this function is just an alias for `0xf809` (put char to the display)
- `0xf812`    - Check if any button is pressed on the keyboard (A=`0x00` if no buttons are pressed, `0xff` otherwise)
- `0xf815`    - Print a byte in a 2-digit hexadecimal form (A - byte to print)
- `0xf818`    - Print a NULL-terminated string at the cursor position (HL - pointer to the string)

The character output function in the UT-88 OS Monitor is slightly simplified compared to its MonitorF counterpart, and lacks support for the Esc-Y cursor positioning sequence. The scrolling behavior, where the cursor moves beyond the last line is similar to that of MonitorF.

Two scroll modes are supported:
- Continuous scroll, similar to MonitorF: When the screen is entirely filled, it scrolls up by one line, and a new line is printed in the freed last line.
- Page turning: When the screen is filled, the Monitor awaits a key press. Upon input, it clears the page, providing a fresh canvas for new lines.

The character output function recognizes several control symbols:
- `0x08` - Move the cursor one position to the left.
- `0x0c` - Move the cursor to the top-left position.
- `0x18` - Move the cursor one position to the right.
- `0x19` - Move the cursor one line up.
- `0x1a` - Move the cursor one line down.
- `0x1f` - Clear the screen.

Unlike MonitorF, there is no direct Esc-Y cursor positioning sequence. Instead, some programs utilize the `0x0c` (home cursor) control symbol, followed by a specific number of `0x1a` (cursor down) and `0x18` (cursor right) characters.

The UT-88 OS Monitor supports a range of commands for memory operations, tape recorder functions, mode and helper commands, and program execution. Here's a detailed breakdown:
- **Memory commands**:
  - Command M: View and edit memory
      M `<addr>`                                    - View and edit memory starting at `addr`
  - Command K: Calculate and print CRC for a memory range
      K `<addr1>`, `<addr2>`                        - Calculate CRC for the range `addr1`-`addr2`
  - Command C: Memory copy and compare
      C `<src_start>`, `<src_end>`, `<dst_start>`   - Compare memory data between two ranges
      CY `<src_start>`, `<src_end>`, `<dst_start>`  - Copy memory from one range to another
  - Command F: Fill or verify memory range
      FY `<addr1>`, `<addr2>`, `<constant>`         - Fill memory range with the constant
      F `<addr1>`, `<addr2>`, `<constant>`          - Compare memory range with the constant, report differences
  - Command D: Dump the memory
      D                                             - Dump 128-byte chunk of memory, starting the user program's HL
      D`<start>`                                    - Dump 128-byte chunk, starting from the specified address
      D`<start>`,`<end>`                            - Dump memory for the specified range
  - Command S: Search string in a memory range
      S `maddr1`, `maddr2`, `saddr1`, `saddr2`      - Search string located `saddr1`-`saddr2` in a memory range `maddr1`-`maddr2`
      S `maddr1`, `maddr2`, '`<string>`'            - Search string specified in single quotes in `maddr1`-`maddr2` memory
      S `maddr1`, `maddr2`, &`<hex>`, `<hex>`,...   - Search string specified in a form of hex sequence in specified memory range
  - Command L: List the text from the memory
      L `<addr1>`[, `<addr2>`]                      - List text located at `addr1`-`addr2` range
- **Tape recorder commands**:
  - Command O: Output data to the tape
      O `<addr1>`,`<addr2>`,`<offset>`[,`<speed>`]  - Output data for `addr1`-`addr2` range, at specified speed. `offset` parameter is not used
  - Commands I and IY: input data from the tape (IY - data input, I - data verification)
      I/IY                                          - Data start and end addresses are stored on the tape
      I/IY`<addr1>`                                 - Search for `addr1` signature on tape, then read `addr2` from the tape
      I/IY`<addr1>`,`<addr2>`                       - Search `addr1`/`addr2` sequence on the tape
      I/IY`<space>``<addr1>`                        - Tape data is loaded to the address provided as a parameter
      I/IY`<space>``<addr1>`,`<addr2>`              - Data start and end addresses are specified as parameters. `addr2` can be used to limit the amount of data to be loaded.
  - Command V: Measure tape delay constant
- **Mode and Helper commands**:
  - Command R: enable or disable scroll
      R`<any symbol>`                               - Enable scroll
      R                                             - Disable scroll (clear screen if full page is filled)
  - Command T: trace the command line
      T`<string>`                                   - Print command line string in a hexadecimal form
  - Command H: Calculate sum and difference between the two 16-bit arguments
      H `<arg1>`, `<arg2>`                          - Calculate and print the sum and difference of the two args
- **Program execution commands**:
  - Command G: Run user program
      G `<addr>`                                    - Run a user program from `<addr>`
      GY `<addr>`[,`<bp1>`[,`<bp2>`[,`<cnt>`]]]     - Run a user program from `<addr>`, set up to two breakpoints. This command also sets/restores registers previously set by the Command X (edit registers) or captured during breakpoint handling. 
  - Command X: View and edit CPU registers
  - Command J: Quick jump
      J`<addr>`                                     - Set the quick jump address
      J                                             - Execute from the previously set quick jump address
- **Interactive assembler and disassembler commands** (see description below):
  - Command A: assembler
  - Command N: interactive assembler
  - Command @: assembler second pass
  - Command W: disassembler
  - Command Z: clear reference/label table
  - Command P: Relocate program
- **Other programs execution commands** (see respective descriptions below)
  - Command E: run Micron editor
  - Command B: run Micron assembler
  
Refer to a respective monitor disassembly ([1](doc/disassembly/ut88os_monitor.asm), [2](doc/disassembly/ut88os_monitor2.asm)) for a more detailed description of the  commands' parameters and algorithm.

The UT-88 OS Monitor does not include time counting functions, and the time interrupt should be switched off while working with the OS. 

The UT-88 OS Monitor has a couple of inconsistencies compared to the original UT-88 MonitorF, particularly in the display module design and the handling of Ctrl key combinations.

The original display module design uses a single 2k video RAM at `0xe800`-`0xef00` range. Each byte's lower 7 bits represent a character code, while the MSB is responsible for symbol highlighting (inversion). The UT-88 OS Monitor code expects a different hardware design. The `0xe800`-`0xef00` range is used for symbol character codes only, while a parallel range `0xe000`-`0xe700` is used for symbol attributes (only MSB is used, other 7 bits are ignored). This may create compatibility issues with the official hardware, and it's worth noting that this alternate schematics is implemented in this emulator.

Another incompatibility is related to Ctrl key handling. When `Ctrl-<char>` key combination is pressed, the original MonitorF produces the `<char>`-`0x40` code. This means that the returned character code is in the `0x01`-`0x1f` range. This design provides a single keycode for Ctrl-char key combinations without requiring additional actions. Some UT-88 OS programs, including the Monitor itself (but not including the Micron assembler), expect a different behavior. Symbol keys are returned as is (in the `0x41`-`0x5f` range), and additional code reads the keyboard's port C to check whether the Ctrl key is pressed.

The emulator is using [fixed version](tapes/ut88os_monitor.rku) of the editor by default. Difference with original version are described in details [here](tapes/ut88os_monitor.diff).

### Interactive assembler and disassembler

The UT-88 OS comes with a set of development tools, built around a simple assembler and disassembler, and share some internal functions and approaches. The tools are described in details in the [assembler/disassembler disassembly](doc/disassembly/ut88os_asm_disasm.asm).

The **Assembler** compiles source code located at `0x3000`-`0x9fff` into a machine code, and stores it to `0xa000`+ location. The compiler supports a relatively simple syntax that covers all i8080 instructions. Immediate values can be represented as decimals or hexadecimal numbers, or character symbols. Simple mathematical expressions with + and - operations between values are allowed.

The assembler operates in two passes. The first pass performs the actual compilation of the source code. The second pass is responsible for substituting label references. The two-pass processing and support for labeled references enable the assembler to handle more complex source code with forward references, common in assembly language programming. Users can choose to execute specific passes or clear the label table based on their needs.

Labels are represented in source code using the syntax `@<lbl>`, where `<lbl>` is a 2-digit hexadecimal number. Label values are stored in the dedicated range `0xf400`-`0xf600` (2 bytes per label). Each label record corresponds to a label, and the address is calculated based on the label number.

The **Interactive Assembler** in the UT-88 OS utilizes the same compilation engine as the standard assembler but allows users to enter source code interactively line by line. This provides a more dynamic coding experience compared to the standard assembler. It suits users who prefer to interactively develop and test assembly language code, offering flexibility in the compilation process. 

Similar to the standard assembler, the Interactive Assembler operates in two passes. Users have the option to perform the first pass, the second pass, or both during the interactive session.

The **Interactive Disassembler** in the UT-88 OS is a tool that allows users to interactively perform the disassembly of a specified memory range. The disassembler analyzes the machine code within the specified range and generates a human-readable assembly language listing. 

The disassembly listing is presented to the user page by page. Users can view up to two pages of disassembled program simultaneously on the screen. The display is divided into left and right parts, each capable of showing a page of disassembled code. After displaying each page, the Interactive Disassembler waits for the user input.
The user can input commands such as '1' to print the next page on the left part of the screen, '2' to print the page on the right, or a space bar to print the next page on the opposite side compared to the previous one.

The **Program Relocator** in the UT-88 OS is a specialized tool designed to relocate a program from one memory address range to another. The relocator focuses on relocating machine code (program) from a source memory range to a target memory range. It looks for 2- and 3-byte instructions within the code that reference the source memory range. When the relocator identifies instructions referencing the source memory range, it corrects these references to point to the target memory range. This correction ensures that the program operates correctly in the new memory location.

The relocator always works with a copy of the original program. This approach ensures that modifications made during the relocation process do not impact the integrity of the source program. The relocator provides the flexibility to prepare a relocated program for use in a memory range that may not exist on the computer.
Users can specify both the source and destination memory ranges as well as an additional target memory range, allowing for flexibility in relocating programs to hypothetical or non-standard memory configurations.

The relocator program utilizes up to five parameters to facilitate the relocation process. These parameters include the source memory range, the target memory range, and the additional target memory range. Detailed information about the usage and parameters of the relocator program can be found in the [relocator command description](doc/disassembly/ut88os_asm_disasm.asm) in the disassembly documentation.

Described tools are accessed using the following monitor commands:
- Command A - Assembler
  - A[@] [`target start addr`]    - compile text located at `0x3000`-`0x9fff` to `0xa000` (or another specified address). The @ modifier runs the 2nd pass as well (by default, only the 1st pass is executed).

- Command N - Interactive assembler
  - N[@] [`addr`]                 - Enter program lines interactively, storing the compiled program at 0xa000 (or another specified address). The @ modifier runs the 2nd pass after all input lines are entered.

- Command @ - Run assembler 2nd pass explicitly
  - @ [`addr1`, `addr2`]          - Run the assembler 2nd pass for the specified address range (or `0xa000`-`0xaffe`)

- Command W - Interactive disassembler
  - W <`start`>[, <`end>`]        - Run the interactive disassembler for the specified memory range.

- Command Z - View or clean labels area
  - Z                             - Show `0xf400`-`0xf600` labels area, listing the current values of each label.
  - Z0                            - Zero all labels

- Command P - relocate program from one memory range to another
  - P[N] `<w1>`,`<w2>`,`<s1>`,`<s2>`,`<t>`  -  Relocate the program from `s1`-`s2` to the `<t>` target address range, using `w1`-`w2` as a working copy (source program is not modified, only the working copy is modified).
  - P@ `<s1>`,`<s2>`,`<t>`                  - Adjust addresses in the `0xf400`-`0xf600` labels area


Refer to the [assembler tools disassembly](doc/disassembly/ut88os_asm_disasm.asm) for assembler syntax details, command arguments descriptions, and implementation notes.


### 'Micron' Editor

The 'Micron' Editor is a text editing application that comes as part of the UT-88 OS package. It provides various features for full-screen text editing in the UT-88 computer environment. Here is an overview of its features:
- Micron Editor supports full-screen text editing.
- It can handle up to 28k of text in the `0x3000`-`0x9fff` memory range.
- Each line can have up to 63 characters. Lines are terminated with the \r character, and text ends with a symbol with a code greater than or equal to `0x80`.
- Users can switch between insert and overwrite modes for text entry.
- Users can navigate the cursor using arrow buttons, as well as Page Up/Down (with Ctrl-Up/Down keys).
- Insert or delete characters under the cursor with Ctrl-Left/Right. Insert or delete a line with Ctrl-A/Ctrl-D key combinations.
- Users can search for a substring within the text.
- Micron Editor allows users to set the tab size as either 4 or 8 characters. Tabs can be entered with the Ctrl-Space key combination.
- Users can input and output text from/to the tape recorder. Text in memory can be verified against the tape.
- Users can append a file from the tape to the text currently loaded in memory.

It's important to note that some features commonly found in modern text editors, such as copy/paste, line wrapping, and undo/redo functionality, are not present in the 'Micron' Editor. 

When launching the 'Micron' Editor program, it begins with a prompt, awaiting user commands. The user can load an existing text from tape using Ctrl-I, or create a new text file using Ctrl-N. If the text was already loaded in any other way, the User can switch from prompt to text editing mode using Up or Down keys.

Due to performance reasons, the 'Micron' Editor operates with one line at a time. When line editing is finished, the line is submitted to the text. Unfortunately there is no way to split a single line into several lines.

The 'Micron' Editor in the UT-88 OS offers a variety of key combinations and commands for efficient text editing. Here's a summary of the supported keys and commands:
- Pressing alphanumeric or symbol keys inputs characters into the text. Depending on the insert/overwrite mode, a new symbol is either inserted at the cursor position (shifting the rest of the line right) or overwrites the symbol at the cursor position (maintaining the line size). The Ctrl-Y key combination toggles the insert/overwrite mode.
- The Ctrl-Space key combination adds spaces up to the next 4-char or 8-char tab stop (Ctrl-W command toggles the tab width).
- Ctrl-Left/Ctrl-Right performs deletion/insertion of a symbol at the cursor position, with insertion occurring even in overwrite mode.
- Arrow keys (Up/Down/Left/Right) move the cursor on the screen. If the cursor reaches the top or bottom of the screen, it is scrolled by one line.
- Ctrl-Up/Ctrl-Down performs page up or down.
- Ctrl-L searches for a substring in the entire text file.
- Ctrl-X searches for a substring from the current line to the end of the file.
- Ctrl-D is intended to delete one or more lines. The command works only at the beginning of the line. When Ctrl-D is pressed, the line is marked with a # symbol indicating a range start. Users can navigate to a point later in the file with Up/Down arrows or Ctrl-Up/Down keys, selecting the end range to delete. It is possible to select only entire lines; deleting part of the line with Ctrl-D is not possible. Another Ctrl-D press performs the deletion. The Clear Screen button exits the range selection and cancels the mode.
- Ctrl-A adds a new line after the current line. The command works only at the beginning of the line. When a line is added, the user can enter text into a new line. The command allows adding multiple lines. The Return key submits the added line, and the Clear Screen key exits the mode.
- Ctrl-T command is similar, but text is added at the end of the text file.
- Ctrl-N creates a new empty text file. Previous text is cleared.
- Ctrl-F prints the current text file size and free memory stats.
- Ctrl-O outputs the current text to the tape. The user enters the file name, which is stored on the tape in the file header. The storage format is slightly different compared to the format used by the Monitor. This makes it impossible to load text files exported from the Editor in the Monitor, and vice versa. Loading binary data as text is not allowed. The format uses a different pilot tone so that text and binary can be audibly distinguished.
- Ctrl-I loads a text from the tape. The user enters the expected file name, and the function searches for the matched file name on the tape.
- Ctrl-V is similar to the previous command, but instead of loading text data from the tape, it verifies that the text in memory matches the text on the tape.
- Ctrl-M appends a file on tape to the current text.
- Ctrl-R toggles the default Monitor's tape delay constants with shorter ones, allowing text to be saved at a faster speed.
- The Clear Screen key exits to the Monitor.

Perhaps this editor is a hastily adapted version from another system. It was designed to operate on a system with a 32-line screen, whereas UT-88 provides only a 28-line screen. This results in very peculiar visual rendering, making it nearly impractical for effective text editing. Numerous adjustments were necessary to ensure the editor's functionality on the UT-88 display. Another compatibility concern arises from how Ctrl symbols are managed by the monitor. The editor anticipates a symbol to be returned conventionally (within the `0x20`-`0x7f` range), and reading Keyboard Port C allows checking the Ctrl key state. As the Monitor behaves differently, the editor code demands a patched Monitor that returns normal char codes even when pressed in combination with Ctrl.

Refer to the [editor disassembly](doc/disassembly/ut88os_editor.asm) for more detailed description. The emulator is using [fixed version](tapes/ut88os_editor.rku) of the editor by default. [Difference with original version](tapes/ut88os_editor.diff) are explained in details.


### 'Micron' assembler

This program is another assembler utility included in the UT-88 OS Bundle. It provides slightly more advanced assembly capabilities compared to the built-in assembler, offering more precise control over the target address through directives such as ORG and DS, and introduces improvements to label handling. Unlike the built-in assembler, which uses numbered labels, this version allows the definition of 6-character long symbolic labels, significantly enhancing the readability of the source code. In terms of general i8080 assembler syntax, it provides standard features for expressions, allowing the use of decimal and hex digits, symbol char codes, and $ as the current address, among others.

Upon startup, the program prompts the user to select a working mode. The following working modes are supported:
- '1' - Silent mode: The source code is compiled without detailed error reporting.
- '2' - Verbose mode: The compiler dumps the source code, annotating each line with the obtained target address, generated byte code, EQU, and label values. In case of a compilation error, the dumped line will contain an error code.
- '3' - Label values: Similar to silent mode, but also dumps label and EQU values.

Regardless of the mode, the program provides general statistics on the compiled program, including:
- Number of detected errors
- Last byte execution address of the compiled program
- Last byte storage address of the compiled program

In verbose mode, the assembler provides error codes if any syntax errors are detected during compilation. The error code is a bitmask representing possible errors:

- 0x01    - Label problem (e.g. double label definition).
- 0x02    - Label not found.
- 0x04    - Unexpected symbol error (e.g. expecting a character, but a digit is found, or encountering an invalid instruction mnemonic).
- 0x08    - Syntax error (incorrect expression structure, unexpected end-of-line, missing mandatory arguments, etc).
- 0x10    - Label-related syntax error (e.g., a label is not followed by a colon).

The compilation process consists of two passes:
- The first pass calculates label addresses and stores them in the labels table.
- The second pass is responsible for actual code generation, where all expression values are calculated using the correct label values set during the first pass.

Unlike the built-in assembler, there is no option to specify the number of passes to execute; both passes are executed during the compilation process.

Detailed description of the assembler syntax, as well as implementation details can be found in the [assembler disassembly](doc/disassembly/ut88os_micron_asm.asm).



## CP/M Operating System and Quasi Disk

The highest UT-88 configuration includes a 256k Quasi Disk, enabling it to run the widely recognized CP/M v2.2 operating system. CP/M is an operating system that gained popularity during the era of early microcomputers. With the inclusion of CP/M, the UT-88 system becomes compatible with a wealth of software developed for this operating system.

Typical CP/M programs leverage the CP/M Application Programming Interface (API) for disk and console operations. This adherence to a standardized API enhances compatibility with other computers running CP/M, fostering a high level of interoperability. As a result, users can access and run a variety of software applications and utilities designed for the CP/M ecosystem on the UT-88 system.


### Quasi Disk

The Quasi Disk is a RAM module in the UT-88 system, offering capacities of 64k, 128k, 192k, or 256k, depending on the number of available RAM chips. It is organized into 1-4 banks, each with a capacity of 64k. The module utilizes a clever design using the i8080 CPU's ability to generate different signals for stack and regular memory access.

Specifically, the quasi disk RAM is enabled for stack push/pop instructions, while regular memory is accessible through standard read/write operations. This innovative approach allows both the main RAM and the quasi disk to operate simultaneously within the same address space. A dedicated configuration port at address `0x40` provides the capability to select a RAM bank or disconnect from the quasi disk. By doing so, stack operations are then routed back to the main RAM.

Quasi disk schematic and description can be found [here](doc/scans/UT49.djvu). The magazine suggests that the Quasi Disk may be powered from an accumulator, and therefore data on the disk may 'persist' for a long time.

### CP/M-64

The CP/M system on the UT-88 consists of several modular components, each serving a specific purpose:
- **Console Commands Processor (CCP)**: This component is the user-facing application responsible for accepting and interpreting user commands. It runs user programs and acts as the interface between the user and the system. (CCP Documentation and disassembly is available [here](doc/disassembly/cpm64_ccp.asm))
- **Basic Disk Operating System (BDOS)**: BDOS provides a comprehensive set of high-level functions for interacting with the console and performing file operations. It includes functions for console I/O (input and output), as well as file-related operations such as creating, searching, opening, reading, writing, and closing files. (BDOS documentation and disassembly is available [here](doc/disassembly/cpm64_bdos.asm))
- **Basic Input/Output System (BIOS)**: BIOS offers low-level functions for working with the console and low level disk operations. Console functions include input and output a char. Disk operations provide a way to select a disk, read or write a data sector. (Refer [here](doc/disassembly/cpm64_bios.asm) for the BIOS disassembly)

While CCP and BDOS are hardware-independent and share the same code across different systems, the BIOS is system-specific and tailored to the UT-88 hardware platform. This modular design allows for a high degree of portability and flexibility in CP/M systems.

Particular BIOS for UT-88 provides the following functionality:
- **Keyboard Input**: Routed to the MonitorF implementation.
- **Character Printing Functions**: An [additional layer](doc/disassembly/cpm64_monitorf_addon.asm) on top of MonitorF, implementing ANSI escape sequences for cursor control.
- **Disk Operations**: Provide access to the Quasi Disk, implementing functions for disk/track/sector selection and sector read/write operations. The BIOS dynamically enables the appropriate Quasi Disk RAM bank based on the selected track.
- **Disk Structure Description**: BIOS exposes a structure describing the physical and logical structure of the Quasi Disk. BDOS uses this structure for proper disk data allocation.

Given that the Quasi Disk is essentially a RAM module without a physical concept of sectors and tracks, the BIOS plays a crucial role in emulating these disk structures to align with CP/M's concepts. The exposed disk structure for the Quasi Disk includes:
- 64/128/192/256 tracks (depending on the quasi disk size)
- First 6 tracks are reserved for the system (see boot approach description below)
- 8 sectors per track

This emulation of disk tracks and sectors by the BIOS enables the Quasi Disk to function within the CP/M operating system seamlessly. The BIOS manages the translation between the RAM-based storage of the Quasi Disk and the logical structure expected by CP/M, ensuring compatibility and allowing CP/M applications to interact with the Quasi Disk as if it were a traditional disk drive.

The memory map for the UT-88 system, along with the layout of CP/M components, is as follows:
- `0x0000`-`0x00ff` (256 bytes) - Base memory page. Contains warm reboot and BDOS entry points, default disk buffer area, utilized for passing parameters between CCP and user programs.
- `0x0100`-`0xc3ff` (almost 49k) - Transient programs area. CCP loads and executes user programs in this memory range. User programs can use this memory for their data and variables.
- `0xc400`-`0xcbff` - CCP and its data variables
- `0xcc00`-`0xd9ff` - BDOS and its data variables
- `0xda00`-`0xdeff` - BIOS and its data variables
- `0xe800`-`0xefff` - Video RAM
- `0xf400`-`0xf7ff` - MonitorF RAM, including
  - `0xf500`-`0xf620` - Put Char function addon
- `0xf800`-`0xffff` - MonitorF ROM

The CP/M system is delivered as a unified binary file that loads at `0x3100`. The loading process is facilitated by a [dedicated bootstrap code](doc/disassembly/CPM64_boot.asm), which not only loads CP/M components to their specified addresses but also initializes the quasi disk. The bootstrap component eventually executes CP/M starting at the `0xda00` address, which corresponds to the BIOS cold boot handler.

CP/M bootstrap file can be found [here](tapes/CPM64.RKU) (Start address is `0x3100`). For convenience and to expedite loading in the emulator, the CP/M components have been extracted into separate tape files. Each tape file loads to its designated CP/M location:
- [CCP](tapes/cpm64_ccp.rku)
- [BDOS](tapes/cpm64_bdos.rku)
- [BIOS](tapes/cpm64_bios.rku)
- [Put char addon](tapes/cpm64_monitorf_addon.rku). 

When loading the individual CP/M components separately, the start address is `0xda00`. 

In the CP/M design, two startup scenarios are defined for the system:
- **Cold Boot Operation**:
  - This operation involves initializing the disk and uploading CP/M system components to the first several tracks of the disk. Specifically, the first 6 tracks of the quasi disk are reserved for the system
  - Cold boot is responsible for the initial setup of the disk and ensuring that the necessary CP/M components are available for execution.
- **Warm Boot Operation**:
  - This operation assumes that the disk system and BIOS are already initialized. In a warm boot, CCP and BDOS components are loaded from the disk if these areas were modified or erased by a user program.
  - During a cold boot, the CP/M startup code places a JMP WARM_BOOT instruction at 0x0000. This ensures that all subsequent boots or CPU resets go through the warm boot scenario, skipping the disk initialization phase.

While the CP/M system and various CP/M programs function on UT-88 hardware, there are two compatibility issues:
- **Encoding Issue**:
  - UT-88 video module uses KOI-7 N2 encoding, which lacks lower case Latin letters. Instead, upper case Cyrillic letters are used. This results in lower case text messages being printed with Cyrillic letters, making it appear unusual though still somewhat readable.
- **Keyboard Input Incompatibility**:
  - CP/M BIOS expects two functions to handle terminal input: one to check if a key is currently pressed and another to read the pressed key. If no key is pressed, the second function shall return immediately.
  - The MonitorF provides similar, but not exactly the same interface. The keyboard read function generates a value on the first key press. If the key is _still_ pressed, subsequent calls to the wait-for-key function will not be processed until the key is released and pressed again (or the keyboard auto-repeat triggers).
  - CP/M BIOS expects immediate results; if a key is pressed, the wait-for-key function should return the code of the pressed key immediately.
  - CP/M BDOS printing function checks for keyboard activity, specifically looking for the Ctrl-C break key combination.
  - This results in a scenario where the user enters a symbol, the symbol is echoed on the console, and the printing function detects that the key is still pressed, attempting to get its code. This call in fact starts waiting for a new key, leading to the skipping of every second entered key. This behavior can be disruptive, especially in an emulator.
  - As a quick workaround in the emulator, reading the keyboard while printing a symbol was disabled to alleviate this issue.


### CP/M-35 (CP/M with no quasi disk)

For users who do not have access to the quasi disk module, a special version of CP/M is offered, featuring an in-memory RAM drive. In accordance with CP/M design principles, CCP and BDOS components remain identical to the normal disk version of CP/M. However, this version comes with a [custom BIOS](doc/disassembly/cpm35_bios.asm) that allocates a 35k RAM drive in the system memory.

CP/M-35 is delivered as a single binary. Unlike the full CP/M version, there is no bootstrap process. Instead, CP/M components are loaded directly into their designated working addresses.

Memory map and CP/M components layout:
- `0x0000`-`0x00ff` (256 bytes) - Base memory page. Contains warm reboot and BDOS entry points, default disk buffer area, utilized for passing parameters between CCP and user programs.
- `0x0100`-`0x33ff` (only 12.5k) - Transient programs area. CCP loads and executes user programs in this memory range. User programs can use this memory for their data and variables.
- `0x3400`-`0x3bff` - CCP and its data variables
- `0x3c00`-`0x49ff` - BDOS and its data variables
- `0x4a00`-`0x4c50` - BIOS and its data variables
- `0x5000`-`0xdfff` (36k) - RAM drive
- `0xe800`-`0xefff` - Video RAM
- `0xf400`-`0xf7ff` - MonitorF RAM
- `0xf800`-`0xffff` - MonitorF ROM

Special considerations for this CP/M version, especially in terms of BIOS implementation:
- The BIOS unexpectedly exposes 4 disk drives, all referencing the same data memory.
- Despite allocating 36k for the RAM disk, the disk descriptor exposes only a 35k drive.
- There is no additional add-on that supports ANSI escape sequences (fortunately, the system itself does not rely on this feature).
- No tracks are reserved on the disk for the system. The cold boot process does not copy the system to the disk.
- Warm boot is not supported. Instead, MonitorF takes control during reboot.

CP/M-35 binary is located [here](tapes/CPM35.RKU). Start address is `0x4a00`.


### CP/M programs

If a CP/M program avoids hardware-specific features and relies solely on BDOS/BIOS routines to interact with the system, there's a high likelihood that the program will function normally on the UT-88 version of CP/M.

Here are descriptions of a few standard CP/M programs that are interesting for learning and evaluation:
- [SUBMIT.COM](doc/disassembly/submit.asm) - This program provides a way to create and run scripts that are automatically executed by the CP/M CCP. SUBMIT.COM allows for the parameterization of scripts, making them generic, and the program substitutes actual parameter values. Despite being a standalone application, it has some support from CCP and even BDOS functions to facilitate its operation. The program was originally written in PL/M language, and the original source has been [added to the repository](doc/disassembly/SUBMIT.PLM) for comparison (code found on the Internet, probably the original source).
- [XSUB.COM](doc/disassembly/xsub.asm) - XSUB is a program that enables substituting console input to be passed to other programs. The program loads and stays resident in memory, hooks the BDOS handler, and substitutes it with its own. If a program calls BDOS for console input, XSUB provides predefined data instead (loaded from a file). This program is interesting due to its 'terminate and stay resident' approach, as well as its capability of hooking the BDOS handler.


# UT-88 Emulator

This project is an emulator of the UT-88 hardware, including CPU, memory, and I/O peripherals. The architecture of the emulator pretty much reflects the modular computer design. 

## Emulated hardware components

This section describe main parts of the emulator, and outlines important implementation notes. Each component and their relationships are emulated as close as possible to the real hardware.

- [CPU](src/cpu.py) - implements the i8080 CPU, including its registers, instruction implementation, interrupt handling, and instruction fetching pipeline. This class also provides optional rich instruction logging capabilities for code disassembly purposes. The implementation is inspired by [py8080 project](https://github.com/matthewmpalen/py8080).
- [Machine](src/machine.py) - implements the machine as a whole, sets up relationships between the CPU, registered (installed) memories, attached I/O devices, and interrupt controller (if it would exist for the UT-88 machine). The concept of the Machine class allow emulating UT-88 design closer to how it works in the hardware. Thus it implements some important concepts:
    - Real CPU does not read the memory directly. Instead, the CPU sets the desired address on its address lines, and reads the data that a memory device (if connected and selected) sets on the data bus. This is emulated in the same way: the CPU is a part of the particular Machine configuration, and can access only a memory which is installed in this configuration. Same for I/O devices, which may vary for different computer configurations.
    - Reset button resets only the CPU, but leaves the RAM intact. This makes possible some workflows implemented in the Monitor 0, where exiting from some modes (e.g. Memory read or write) is performed using the Reset button.
    - Some types of memory is triggerred with stack read/write operations. Thus the Quasi Disc module is connected in this way. This allows RAM and Quasi Disk operate in the same address space, but use different accessing mechanisms. At the same time, the Machine class is responsible for handling `0x40` port in order to select between regular memory and the quasi disk.
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
- [Quasi Disk](src/quasidisk.py) class emulates the quasi disk. It responds to stack read/write commands to perform read/write data from/to the 'disk'. The 'disk' is a 256k memory buffer, that is loaded during emulator start, and flushed to the host system disk from time to time. The 256k disk is logically split into four 64k pages. The software can use port `0x40` to select the data page to work with.

The Emulator class, as well as CPU, memories, and some of the peripherals are UI agnostic. This means it can work as a non-UI component, executed in a script, or be checked in automated tests.

Other components, such as LCD, Display and keyboards interact with the User. This is done using [pygame](https://www.pygame.org/) framework. In order to properly handle the keyboard input, and prepare output graphics, components have an `update()` method. The update signal is propagated via Machine object to all memories and devices registered in the Machine. The `update()` method is called approx 15-60 times a second, providing a way to emulate these devices.

## Breakpoints and hooks in emulator

TBD

## Emulating the emulator

TBD Describe 


# Usage of the emulator


### Basic configuration

Basic UT-88 configuration is started with the following command:
```
python src/main.py basic
```

Calculator ROM is also pre-loaded in this configuration.


### Video configuration
This is how to run the emulator in Video module configuration:
```
python src/main.py video
```

This configuration enables `0x0000`-`0x7fff` (32k) memory range available for user programs, which allows running some of Radio-86RK software. The configuration also enables some workarounds that improve stability of the MonitorF when running under emulator (see [setup_special_breakpoints()](src/main.py) function for moore details)



### UT-88 OS configuration

To run the emulator with UT-88 OS enter this command:
```
python src/main.py ut88os
```

This configuration skips the [UT-88 OS bootstrap module](tapes/UT88.rku), as it requires reconfiguration of RAM and ROM components on the fly. Instead it loads UT-88 OS components directly to their target locations, as they would be loaded by the bootstrap module.

Unfortunately the UT-88 OS is pretty raw and contains a lot of bugs. Most critical of them are worked around with special hooks in [setup_special_breakpoints()](src/main.py) function (refer the code for moore details)


### CP/M operating system
UT-88 with CP/M-64 system loaded can be started as follows:
```
python src/main.py cpm64
```

This command starts the regular video module monitor with CP/M components loaded to the memory ([CCP](tapes/cpm64_ccp.rku), [BDOS](tapes/cpm64_bdos.rku), [BIOS](tapes/cpm64_bios.rku)). Use `G DA00` command to skip CP/M bootstrap module, and start CP/M directly. In this case pre-created quasi disk image is used, and its contents survive between runs. 

Use `G 3000` command to run [bootstrap module](tapes/CPM64.RKU), which is also preloaded in this configuration. The bootstrap module will create/clear and initialize quasi disk image, that later may be used with the system.

CP/M-35 version of the OS can be executed as follows: load [OS binary](tapes/CPM35.RKU), and execute it with `G 4A00` command. Note that keyboard incompatibility workaround is applied only for CP/M-64 version, but not CP/M-35.

### Other emulator notes

The `--debug` option will enable CPU instructions logging, and can be used will all modes described above. In order not to clutter the log for dumping waiting loops, each configuration suppresses logging for some well known functions (e.g. various delays, printing a character, input/output a byte to the tape, etc). [configure_logging() method](src/main.py) is responsible for setting up log suppression for a specific configuration.

Basic and Video configurations offer tape recorder component. Use `Alt-L` key combination to load a binary to the tape recorder. When the binary is loaded it can be read by corresponding tape load Monitor command. The data can be also output to the tape. Use `Alt-S` to save data buffered in the tape recorder to a file.

Loading data through the tape recorder is quite time consuming. So emulator offers a shortcut: `Alt-M` key combination loads the tape file directly to the memory. Start address is taken from the binary. `Alt-M` combination works for all configurations, not only those that offer tape recorder.

The emulator supports storage formats from other similar emulators:
- .PKI files (sometimes used with .GAM extensions). 
- .RK and .RKU files 
- raw binary files   

These formats provide similar capabilities, and have just minor differences in data layout. Refer [tape recorder](src/tape.py) component description for more detail.

# Tests

In order to verify correctness of the implemented features (especially CPU instructions), a comprehensive [set of automated tests](test) was developed. These tests also help to control massive changes across the codebase, and verify that nothing is broken with the change.

Most of the tests cover a component functionality in isolation. Some tests require a few components work together (e.g. Machine + RAM + CPU). In order not to use hard-to-set-up or User facing components, [Mocks](test/mock.py) are used where it is convenient.

Some tests, such as [Calculator tests](test/test_calculator.py) are not really tests in classic meaning - it does not suppose to _test_ the firmware (though it found a few issues). These tests is a simple and handy way to execute some functions in the firmware.

For running big portions of machine code, that interacts with memories and peripherals, a [special helper class](test/helper.py) was created. The helper class provide handy way to read/write a machine memory in the test, operate with the peripheral (e.g. emulate key press sequence), and run specific functins of the software. Derived classes represent a specific configuration ([Calculator](test/test_calculator.py), [CP/M](test/cpm_helper.py), [UT-88 OS](test/ut88os_helper.py)), set up corresponding RAM/ROM configuration, peripherals, and load application images.

Tests are implemented with pytest framework.

To run tests:
```
cd test
py.test -rfeEsxXwa --verbose --showlocals
```


# Future plans

TBD
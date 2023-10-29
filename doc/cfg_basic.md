# UT-88 Basic Configuration

UT-88 in Basic Configuration consists of a CPU with supplemental chips, featuring a 6-digit LCD display and a hexadecimal button keypad. Tape recorder can be used for permanent storage of user programs. This configuration is relatively simple and does not require solid technical skills to bring it up. In the basic configuration, users could perform basic computer operations such as memory read/write, CRC calculations, load programs from tape, and create and execute simple programs.

## Hardware

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

Memory map of the UT-88 in Basic Configuration:
- `0x0000`-`0x03ff` - Monitor 0 ROM
- `0x0800`-`0x0fff` - Optional Calculator ROM (see below)
- `0x9000`-`0x9002` - LCD screen (3 bytes, 6 digits)
- `0xc000`-`0xc3ff` - RAM

I/O address space map:
- `0xa0`  - hex heyboard
- `0xa1`  - tape recorder

Basic CPU module schematics can be found here: [part 1](doc/scans/UT08.djvu), [part 2](doc/scans/UT09.djvu).

## Firmware

The minimal firmware, called "Monitor 0" (as it is located from `0x0000`), provides common routines and serves as a basic operating system for the UT-88 computer. "Monitor 0" is divided into two distinct parts within the ROM:
- `0x0000-0x01ff` - Essential Part ([see disasssembly](disassembly/monitor0.asm)). This section encompasses:
    - Convenient routines for keyboard input, LCD output, and tape data input and output.
    - A basic operating system that allows users to read and write memory and ROM, calculate CRC, and execute programs.
    - A real-time clock for tracking the current time.
- `0x0200-0x03ff` - Optional part ([see disasssembly](disassembly/monitor0_2.asm)). This optional segment includes a few useful programs:
    - Memory copying programs, including special cases for inserting or removing a byte from a program.
    - Memory comparison programs.
    - Address correction programs designed to rectify addresses after a program has been relocated to another memory region.

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

## Optional firmware

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

## Other software

In the Basic Configuration, the UT-88 computer offers limited software variety. The programs included with the Basic CPU module instructions, however, may not meet the same quality standards as the main firmware, possibly being authored by the UT-88 creator's students. These programs are as follows:
- [Tic Tac Toe game](doc/disassembly/tictactoe.asm) - a classic game. Computer always goes first, and there is no way for the player to win.
- [Labyrinth game](doc/disassembly/labyrinth.asm) - player searches a way in a 16x16 labyrinth.
- [Reaction game](doc/disassembly/reaction.asm) - program starts counter, goal to stop the counter as early as possible.
- [Gamma](doc/disassembly/gamma.asm) - generates gamma notes to the tape recorder.


# Running emulator in Basic Configuration

Basic UT-88 configuration is started with the following command:

```
python src/main.py basic
```

Calculator ROM is also pre-loaded in this configuration.

![](doc/images/basic.png)

# UT-88 Video Module

The Video Module is a pivotal addition to the UT-88 computer, bringing with it a 64x28 character monochrome display and a 55-key keyboard. With this module in place, the UT-88 transforms into a fully-fledged computer, capable of running text-based video games, text editors, programming language compilers, and a wide array of applications.

The Video Module not only enhances the UT-88's functionality but also offers a high level of compatibility with previously released Radio-86RK and its various modifications. This compatibility ensures that using and porting programs from the Radio-86RK to the UT-88 is a straightforward and manageable task. It effectively bridges the gap between these related computer systems, enabling a seamless transition of software and expanding the UT-88's capabilities.

## Hadrware

Here's a detailed description of the hardware additions to the UT-88 computer:
- **Video Adapter**: 
  - The Video Adapter is built around a 2-port RAM located in the address range `0xe800`-`0xefff`. One port of this memory is connected to the computer's data bus and functions like regular memory. A specialized circuit, consisting of counters and logic gates, reads the video memory through the second port and converts it into a TV signal.
  - The video adapter is capable of displaying a 64x28 monochrome character matrix, with each character being 6x8 pixels in size.
  - A dedicated 2k ROM (not connected to the data bus) serves as a font generator. It contains 2 characters sets. Schematically only lower part is connected to system. Upper part of the ROM may be connected *instead* with a minor hardware modifications (e.g. by adding a switch). The font ROM is dumped [here](ut88_font.txt), along with the comparison between fonts, and bugs description.
  - Lower 1k of the Font ROM contains 128 chars in the KOI-7 N2 encoding: characters in the `0x00`-`0x1f` range providing pseudo-graphic symbols, characters in the `0x20`-`0x5f` range matching the standard ASCII table, and characters in the `0x60`-`0x7f` range allocated for Cyrillic symbols.
  - Upper 1k contains alternative font, that matches KOI-7 N1 encoding. `0x00`-`0x1f` range provides a different set of pseudo-graphic symbols. `0x20`-`0x3f` range matches to ASCII symbol set, `0x40`-`0x7f` range represents upper and lower case cyrillic chars. There are no Latin chars in this font. All chars supposed to be printed with latin letters in fact are printed with lower case cyrillic symbols.
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

Video module schematics can be found here: [part 1](scans/UT22.djvu), [part 2](scans/UT24.djvu).

## Firmware

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

These predefined entry points simplify interaction with the Video Module hardware and enable efficient development of software that leverages its capabilities. For detailed information on arguments and return values, as well as algorithm descriptions, please refer to the [Monitor F disassembly](disassembly/monitorF.asm).

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

## Software

From a software perspective, the Video Module transforms the UT-88 into a classic computer with the essential components of a keyboard and monitor. This expansion enables the UT-88 to operate as a traditional computer with typical terminal-like routines expected from this type of machine. It opens the door for various software applications and interactions that are common to such computers.

One notable program published for the UT-88 with the Video Module is the Tetris game, which offers an engaging gaming experience. The Tetris game allows users to enjoy the classic block-stacking challenge on their UT-88 computer. You can find the program tape for Tetris [here](tapes/TETR1.GAM) and explore its disassembly [here](disassembly/tetris.asm)).


# Running the emulator in Video Configuration

This is how to run the emulator in Video module configuration:
```
python src/main.py video
```

This configuration enables `0x0000`-`0x7fff` (32k) memory range available for user programs, which allows running some of Radio-86RK software. The configuration also enables some workarounds that improve stability of the MonitorF when running under emulator (see [setup_special_breakpoints()](../src/main.py) function for moore details)

![](images/video.png)

![](images/tetris.png)


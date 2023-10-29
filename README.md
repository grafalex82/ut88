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
- **Basic Configuration:** The CPU module resembled a calculator, featuring a 6-digit LCD display and a hexadecimal button keypad. See detailed description of the basic configuration including hardware and software description [here](doc/cfg_basic.md).
- **Calculator Add-on:** This expanded the capabilities by incorporating a ROM with floating-point functions, enabling scientific calculations. The calculator addon is described [here](doc/cfg_calculator.md).
- **Video Module:** The next phase introduced a 55-key alphanumeric keyboard and a 64x28 character monochrome display (with TV output). The hardware and software of the Video Configuration is described in [this document](doc/cfg_video.md).
- **Dynamic 64k RAM:** This upgrade allowed users to run programs from other compatible computers. See [64k RAM mod notes](doc/64k_mod.md) for more details.
- **64k-256k Quasi Disk:** A battery-powered dynamic RAM was added, providing the capacity to store a substantial amount of data.
- **Custom Add-ons:** In addition to the phases listed above, there were custom add-ons, including a [Flash memory programmer](doc/rom_flasher.md) and an i8253-based sound generator.

These phases offered readers a structured approach to gradually build and enhance the UT-88 computer according to their preferences and needs. Each phase of the UT-88 build not only expanded the hardware but also enriched the software capabilities, providing users with a versatile computing experience.

From a software perspective, each phase of the UT-88 computer build introduced additional functionalities:
- **Basic Configuration:** In the basic configuration, users could perform basic computer operations such as memory read/write, CRC calculations, load programs from tape, and create and execute simple programs.
- **Video Module:** With the video module installed, the UT-88 could run text-based programs, including simple text-based video games.
- **Full Configuration:** Achieving the full configuration unlocked the ability to run the [UT-88 operating system](doc/cfg_ut88os.md). This OS offered essential tools like a full screen text editor and an assembler, enhancing compatibility with other i8080-based computers.
- **Special CP/M Port:** The magazine also provided an unique port of the CP/M operating system, enabling users to work with files stored on the quasi disk, expanding the computer's capabilities even further.

The architecture of the UT-88 computer draws significant inspiration from two previously published computer systems: the Micro-80 (from the early 1980s) and the Radio-86RK (featured in the 'Radio' magazine between 1985 and 1987). Several technical solutions and design elements are inherited from these predecessors, enhancing the UT-88's overall functionality and compatibility. Key elements carried over from its predecessors include connectivity with tape recorders and the associated recording format, the layout and schematics of the keyboard, and the general hardware framework.

Notably, the UT-88 distinguishes itself by incorporating more advanced and refined schematics. This includes the integration of components like the i8224 and i8238, which replace a multitude of TTL logic gate chips used in the Radio-86RK. Additionally, the UT-88's peripheral are connected to the CPU using I/O address space, in contrast to the Radio-86RK where peripherals were located within the main memory address space. Furthermore, the UT-88's design takes into account chip availability, addressing the scarcity of the i8275 chip in late USSR. In response, the UT-88's video module employs a combination of registers and counters, providing a practical alternative for the video signal generation.

On the software front, the UT-88 maintains a high degree of compatibility with its predecessors. For instance, the Monitor F, which serves as the primary firmware for the Video Module, closely resembles the Radio-86RK Monitor and shares common routine entry points. This compatibility allows for the loading and execution of Radio-86RK programs from tape with minimal to no modifications, underscoring the seamless transition between these related computer systems.

Scans of the original magazine can be found [here](doc/scans).






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


## Radio-86RK

The Radio-86RK is a foundational computer in the family and the predecessor of the UT-88. While the Radio-86RK is a more popular DIY computer, this comparison is UT-88-centric.

The Radio-86RK computer features a video adapter based on the Intel 8275 chip, working in conjunction with the Intel 8257 DMA controller. This collaboration facilitates the transfer of video RAM contents into the video controller without direct involvement from the main CPU. The main drawback of this approach is that the DMA controller shares the same address and data buses with the CPU, resulting in the CPU being halted during data transfer. This interruption negatively impacts time-critical routines, such as tape input and output. To work around this, the tape functions temporarily disable video output and re-enable it upon completion.

The Radio-86RK schematics don't allocate a dedicated video RAM. Instead, the screen buffer is located in the main memory. The DMA controller is configured to transfer the video RAM contents to the video controller. The screen size is 78x30 characters, and the video buffer of 78 x 30 = 2340 (0x924) bytes is situated at 0x76d0. However, not all characters are visible on the screen due to CRT margins. To address this, 8 characters on the left, 6 characters on the right, 3 lines at the top, and 2 lines at the bottom are programmatically disabled. The Monitor software is responsible for managing these margins and ensuring that no valuable data is written into non-visible areas. Consequently, the effective screen size is only 64x25 lines, and part of the video memory is unused.

The i8275 chip allows for slightly reconfiguring the video chip if necessary. Thus, some programs or games may increase the number of rows on the screen by removing spacing between rows. In this case, the amount of video RAM is increased, but it can be easily moved to another address by reconfiguring the DMA controller. Some programs may even use non-visible rows and columns to store some information.

In comparison to the RK86 video adapter, the UT-88's adapter is based on a number of timer/counter and logic gate chips. These chips are responsible for generating the video synchronization signals, taking into account the duration of strobes and pauses between them. Importantly, these chips generate dead rows and columns that are not visible on the screen, preventing video RAM wastage for non-visible characters.

The UT-88 features a dedicated video RAM located at the fixed address `0xe800`. The effective video screen size is 64x28 characters. The screen width of 64 (0x40) significantly simplifies character position calculations and allows for the use of simple bit shift operations. The only feature UT-88 lacks compared to the Radio-86RK is hardware cursor support, but this is emulated programmatically by inverting a symbol at the cursor position.

Another significant difference between the Radio-86RK and UT-88 is how peripheral devices are connected to the CPU. In the Radio-86RK, devices are connected as memory-mapped devices, allowing access to these peripherals by reading or writing certain memory cells. The drawback of this approach is that only 32k of RAM is available to the user. Peripheral devices use only a few cells, but they do not allow creating a consecutive RAM for the entire address space. In the UT-88 design, peripheral devices are connected to the I/O space. This allows for the creation of a consecutive RAM space for almost the entire address space.

The Radio-86RK utilizes a 67-key keyboard organized as an 8x8 matrix, along with a few standalone keys. Although the schematic is very similar, the key layout on the matrix is different. The keyboard matrix includes not only alphanumeric and some control keys (e.g., arrows) but also 5 functional buttons (F1-F5) that are supposed to be user-assignable. However, there is no support for these keys in the Monitor.

Entering Cyrillic characters is a bit different compared to the UT-88. In the UT-88, the Rus key works like a modifier key, requiring the user to hold the Rus key to enter Cyrillic characters. In contrast, in the Radio-86RK, the Rus key functions as a toggle, maintaining the new state for the next input. The mode is indicated with an LED so that the user knows which mode is currently enabled.

Other differences between the Radio-86RK and UT-88 include:
- Radio-86RK uses a CR/LF sequence for a new line, behaving literally like carriage return (in the same line) and line feed (keeping the existing cursor column position). The UT-88 uses only LF (0x0a) acting as both carriage return and line feed, while CR (0x0d) is ignored.
- Radio-86RK has dedicated LF, F1-F5 keys, separate backspace, and Escape (AR2) buttons, while the UT-88 does not have these buttons. Conversely, the UT-88 has a '_' symbol not available on the Radio-86RK.
- Both Radio-86RK and UT-88 use the same font ROM.
- The Radio-86RK Monitor obviously has a different implementation for hardware-related functions (tape, display, keyboard) but uses very similar algorithms. Non-hardware-related functions (such as memory commands) are identical in both Radio-86RK and UT-88 Monitors, including some peculiarities like making tape delays using random stack operations.
- Monitor Commands K and V are not available in the Radio-86RK.
- Radio-86RK does not have a time module.
- Radio-86RK does not use hardware interrupts.
- Radio-86RK uses the EI pin for sound generation. The level on this pin is changed with DI/EI instructions. Instead, UT-88 uses the tape port for sound generation.

Memory map of the Radio-86RK computer:
- `0x0000` - `0x7fff`: 32k general-purpose RAM, including Video RAM. 16k version of the computer uses the range `0x0000` - `0x3fff`
- `0x8000` - `0x8003`: Intel 8255 PPI chip that is used for the keyboard matrix, and Rus LED. Port C is also used for tape input and output.
- `0xa000` - `0xa003`: Additional Intel 8255 port, used for external ROM.
- `0xc000` - `0xc001`: Intel 8275 video controller chip.
- `0xe000` - `0xe008`: Intel 8257 DMA controller chip.
- `0xf800` - `0xffff`: Monitor ROM.

A classic [Lode Runner](tapes/LRUNNER.rku) game ([disassembly](doc/disassembly/LRUNNER.asm)) is added as an example of Radio-86RK game.

# UT-88 Emulator

This project serves as an emulator for the UT-88 hardware, encompassing the CPU, memory, and I/O peripherals. The emulator's architecture closely mirrors the hardware design of the UT-88 computer.

## Emulated hardware components

The emulator project is structured to closely emulate the UT-88 hardware, with each component mirroring its real-world counterpart. Here's a breakdown of the main components and their key implementation notes:

- [**CPU**](src/common/cpu.py) - Implements the i8080 CPU, incorporating registers, instruction execution, interrupt handling, and instruction fetching pipeline. Optional rich instruction logging for code disassembly and debugging purposes is available. The implementation is inspired by the [py8080 project](https://github.com/matthewmpalen/py8080).
- [**Machine**](src/common/machine.py) - Represents the machine as a whole, establishing relationships between the CPU, registered (installed) memories, attached I/O devices, and a hypothetical interrupt controller (if applicable).
The concept of the Machine class allow emulating UT-88 design closer to how it works in the hardware. Thus it implements some important concepts:
    - Real CPU does not directly read memory. Instead, it sets the desired address, and the connected and selected memory device provides the data on the data bus. This emulation closely resembles the behavior: the CPU is a part of the particular Machine configuration, and can access only a memory which is installed in this configuration. Same for I/O devices, which may vary for different computer configurations.
    - The reset button resets only the CPU, leaving the RAM intact. This aligns with certain workflows in the Monitor 0, where exiting some modes (e.g. Memory Read or Write) is achieved by pressing the Reset button.
    - Some types of memory are triggered by stack read/write operations, such as the Quasi Disk module. This enables RAM and Quasi Disk to operate in the same address space but use different access mechanisms. The Machine class handles port `0x40` to select between regular memory and the quasi disk for stack read/write operations. This behavior is specifically implemented in [UT88Machine](src/ut88/machine.py) sublass.
    - The UT-88 Computer does not have an interrupt controller. If an interrupt occurr, the data bus will have `0xff` value on the line due to pull-up resistors. This coincide with the RST7 instruction, that runs an interrupt handler.
- Various types of memory, such as [**RAM**](src/common/ram.py), [**ROM**](src/common/rom.py), stack memories (e.g. Quasi Disk), and I/O devices are connected to the machine using [MemoryDevice and IODevice adapters](src/common/interfaces.py). The idea behind is that device does not care about which address it is connected to, and even which address space (memory or I/O). Thus the same device (e.g. keyboard port) may be connected as a memory mapped device in Radio-86RK or as a I/O device in UT-88. The MemoryDevice and IODevice adapters are responsible for assigning a peripheral an exact address or port. This design allows for easy extension of the emulator's functionality by implementing new devices or memories, and device configurations by registering devices it in the Machine object. 
- Common components also include general purpose chip emulations (such as [Intel 8255 parallel port](src/common/ppi)), as well as specific chip implementations (such as [Intel 8257 DMA Controller](src/common/dma.py)). These components reflect the electrical connectivity and purpose of such chips, emulating their behavior and data flow. At the same time it is assumed that the actual peripherals (e.g. keyboard, tape recorder, or CRT display) will be connected to these chips on the initialization stage.
- Finally, the [**Emulator**](src/common/emulator.py) class offers convenient routines for running emulation process for the Machine. It provides methods to execute single or multiple machine steps and handle breakpoints. Breakpoints serve as a useful mechanism for performing emulator-side actions based on the machine's condition or CPU state. For instance, it allows adding extra logging when the CPU enters a specific stage or executes specific code.


The following UT-88 peripherals are emulated:
- [**17-button hexadecimal keyboard**](src/ut88/hexkbd.py) emulates 16 digits buttons, and a step back key. Typically in the UT-88 basic configration this keyboard is connected to I/O port `0xa0` (read only). Reading the port returns the button scan code, or `0x00` if no button is pressed. The implementation converts host computer button presses to UT-88 Hex keyboard scan codes using pygame.
- [**6-digit 7-segment display**](src/ut88/lcd.py) implementation mimics 7-segment indicators, displaying digit images using pygame according to values in the memory cells. In the UT-88 basic configuration the LCD display is mapped to memory range `0x9000`-`0x9002` (Write only). 
- [**Tape recorder**](src/common/tape.py) emulates 2-phase coding of data native to UT-88 Monitors (0 and F) as well as Radio-86RK. The emulator can load a binary file and convert it to a series of bit values, allowing the Monitor to read it correctly. It can also collect data bits sent by the Monitor and convert them into a file on disk. The implementation is a little bit hacky, as it is not really time based, but just counts In and Out calls. In the UT-88 configuration the tape recorder is mapped to I/O port `0xa1` LSB. 
- [**Seconds Timer**](src/ut88/timer.py) is not connected to any data buses in the computer, but rather generates an interrupt every second. As said previously, Machine will set `0xff` on the data line, so that CPU will treat it as RST7 instruction.
- [**Display**](src/ut88/display.py) emulates the 64x28 chars monochrome display. The module represents a piece of RAM at `0xe800`-`0xefff` that the CPU can write to. 
  - As an extension, the Display class also implement behavior required for UT-88 OS: A parallel memory range `0xe000`-`0xe7ff` (MSB only) can be used to read of write character inversion bit. Character codes in the main range remain intact.
  - The implementation is using [DisplaySurface](src/common/surface.py) class for actual symbols drawing. Drawing characters based on the Font ROM used in the original hardware (6x8 dot matrix). The display supports symbols in the `0x00`-`0x7f` range, with MSB used to invert the symbol. Symbols in `0x00`-`0x1f` range are pseudo-graphics symbols, which allows converting the display to pseudo 128x56 dots graphic display.
- [**Keyboard**](src/ut88/keyboard.py) class emulates a 55-button keyboard connected through the [i8255 controller](src/common/ppi.py) and in case of UT-88 is connected to ports `0x04`-`0x07`. The emulator handles host computer key presses, taking into account Shift and Ctrl mod keys and the Russian keyboard layout, and then sets Port B and C scan codes accordingly. The MonitorF scans the keyboard matrix by setting low levels on the column port A and reading rows through the Port B. Additionally it reads mod keys stats by reading the Port C. Then a special code in the MonitorF converts these scan codes into character codes.
- [**Quasi Disk**](src/ut88/quasidisk.py) class emulates the quasi disk. It responds to stack read/write commands to perform read/write data on the 'disk'. The 'disk' is a 256k memory buffer loaded during emulator start and flushed to the host system disk periodically. The disk is internally split into four 64k pages, software can use port `0x40` to select the data page to work with.

In addition to UT-88, the following Radio-86RK specific components are implemented as well:
- [**RK86Keyboard**](src/radio86rk/keyboard.py) is a Radio-86RK keyboard implementation. It is very similar to UT-88's one, but since the keyboard layout is different it required a separate implementation. The keyboard is connected to the machine via i8255 chip, memory mapped to the `0x8000`-`0x8003` memory range.
- [**RK86Display**](src/radio86rk/display.py) emulates 78x30 characters display based on the Intel 8275 CRT video controller. In the Radio-86RK configuration the CRT chip works in conjunction with Intel 8257 DMA controller to fetch video RAM data. This behavior is also implemented in this class.

The Emulator class, along with the CPU, memories, and some peripherals, is designed to be UI-agnostic. This means it can function as a non-UI component, running in a script, or being used in automated tests.

On the other hand, components like LCD, Display, and keyboards interact with the user using the [pygame](https://www.pygame.org/) framework. To handle keyboard input and prepare graphical output, these components implement an update() method. The update signal is propagated through the Machine object to all memories and devices registered in the Machine. The update() method is typically called around 15-60 times per second, providing a way to emulate the behavior of these devices and update the UI accordingly. This approach enables flexibility in adapting the emulator for different user interfaces.

## Breakpoints and hooks in emulator

Breakpoints are a useful feature in the emulator that allows executing specific code when the emulated CPU reaches a particular address. Breakpoints serve various purposes, including fixing or altering the behavior of UT-88 software, disabling certain code branches in automated test environments, suppressing logging for a piece of code, generating keypress events for testing, hooking display functions for output text collection, and more.

The usage of breakpoints is straightforward. Here's an example:

```
  emulator.add_breakpoint(0x1234, lambda: emulator._cpu.set_pc(0x2345))
```

In this example, a breakpoint is added at address 0x1234. When the CPU reaches this address, the lambda function is executed, diverting the execution flow to address 0x2345.

Breakpoint hooks can perform various actions, such as reading or writing to memory, changing registers, triggering emulated hardware features, or executing host routines in the emulator.

Multiple breakpoints can be added to the same address to accommodate different actions.


## CPU instructions logging

The CPU instruction logging feature in the emulator is a valuable tool for understanding and debugging UT-88 code execution. It provides detailed information about the program's behavior, including the current execution address, the executed instruction, and the CPU register values. This information can help developers gain insights into how the emulated program behaves.

By default, CPU instruction logging is turned off to avoid excessive performance overhead. However, users can enable logging using a CLI option or by calling the `enable_registers_logging()` function on the CPU object in the code.

One particularly useful feature is the ability to temporarily disable logging when entering specific functions or code blocks that are not of interest for a particular debugging session. This feature is implemented using the NestedLogger class, which sets hooks at enter and exit addresses and disables logging on enter while re-enabling it on exit. The NestedLogger class also keeps track of nested function calls.

Here's an example of how to use the `suppress_logging()` method to disable logging for specific functions or code blocks:

```
        self.suppress_logging(0xfd92, 0xfd95, "Beep")
        self.suppress_logging(0xfd57, 0xfd99, "Keyboard input")
        self.suppress_logging(0xfd9a, 0xfdad, "Scan keyboard")
```

That's an important consideration when using the logging suppression feature. Selecting the exit address carefully is crucial to ensure that logging is correctly re-enabled when the function or code block exits. Since the suppression feature uses breakpoints that trigger when the CPU reaches a specific address, it's essential to account for all possible exit points within the specified range.

Functions with multiple exit points or conditional returns can be more challenging to handle. In such cases, it's essential to carefully analyze the code flow and identify the most appropriate exit address to use. While it may not always be possible to set a breakpoint on the exact exit condition, selecting an address that covers the majority of exit scenarios can help minimize the impact of this limitation.

## Emulating the emulator

That's a clever approach to optimize performance by selectively replacing certain computationally intensive functions with emulator-side implementation. Using the breakpoint feature it is possible to hook to a UT-88 function, replace it with more efficient Python implementations, bypassing the original code. This strategy allows for a balance between emulation accuracy and performance in emulation. This approach may significantly enhance the overall performance of the emulated system. 

As a proof of concept, the [character output function](src/bios_emulator.py) was re-implemented in Python, replacing the MonitorF's implementation. Although this does not introduce any new functionality, it significantly boosts performance of display operations for MonitorF and CP/M use cases.

It's worth noting that extending this approach to optimize quasi disk operations would be another valuable enhancement. This would further demonstrate the emulator's ability to fine-tune its behavior to suit different use cases and scenarios.

This emulation mode is enabled by adding `--emulate_bios` command line switch to the emulator.


# Usage of the emulator

The following sections describe how to run and use the Emulator in the configuration options described above.

### Basic configuration

Basic UT-88 configuration is started with the following command:
```
python src/main.py basic
```

Calculator ROM is also pre-loaded in this configuration.

![](doc/images/basic.png)

### Video configuration

This is how to run the emulator in Video module configuration:
```
python src/main.py video
```

This configuration enables `0x0000`-`0x7fff` (32k) memory range available for user programs, which allows running some of Radio-86RK software. The configuration also enables some workarounds that improve stability of the MonitorF when running under emulator (see [setup_special_breakpoints()](src/main.py) function for moore details)

![](doc/images/video.png)

![](doc/images/tetris.png)


### UT-88 OS configuration

To run the emulator with UT-88 OS enter this command:
```
python src/main.py ut88os
```

This configuration skips the [UT-88 OS bootstrap module](tapes/UT88.rku), as it requires reconfiguration of RAM and ROM components on the fly. Instead, it loads UT-88 OS components directly to their target locations, as they would be loaded by the bootstrap module.

Unfortunately the UT-88 OS is pretty raw and contains a lot of bugs. Most critical of them are fixed right in the binary (see [detailed description](tapes/ut88os_monitor.diff)), other worked around with special hooks in [setup_special_breakpoints()](src/main.py) function (refer the code for moore details)

![](doc/images/ut88os.png)

![](doc/images/ut88os_disasm.png)


### CP/M operating system

UT-88 with CP/M-64 system loaded can be started as follows:
```
python src/main.py cpm64
```

This command starts the regular video module monitor with CP/M components loaded to the memory ([CCP](tapes/cpm64_ccp.rku), [BDOS](tapes/cpm64_bdos.rku), and [BIOS](tapes/cpm64_bios.rku)). Use `G DA00` command to skip CP/M bootstrap module, and start CP/M directly. In this case pre-created quasi disk image is used, and its contents survive between runs. 

The `G 3000` command can be used to run [bootstrap module](tapes/CPM64.RKU), which is also preloaded in this configuration. The bootstrap module will create/clear and initialize quasi disk image, that later may be used with the system.

Note that the QuasiDisk.bin quasi disk file is created in the current directory. 

CP/M-35 version of the OS can be executed as follows: load [OS binary](tapes/CPM35.RKU), and execute it with `G 4A00` command. Note that keyboard incompatibility workaround is applied only for CP/M-64 version, but not CP/M-35.

![](doc/images/cpm64.png)


### Radio-86RK emulator

Radio086RK emulator can be started as follows:
```
python src/main.py radio86rk
```

The configuration enables 32k RAM. Video and DMA controllers are emulated to a level sufficient to run Radio-86RK programs. Keyboard is emulated for Latin letters and control symbols (Cyrillic letters mode is not implemented).


### Other emulator notes

The `--debug` option activates CPU instruction logging, compatible with all the modes outlined earlier. To prevent log cluttering with repetitive waiting loops, each configuration selectively suppresses logging for specific well-known functions (e.g., delays, character printing, tape input/output, etc.). The [configure_logging() method](src/main.py) is responsible for configuring log suppression for a given setup.

The `--alternate_font` switch forces using an alternate font located in the upper part of the font generator ROM. 

Both Basic and Video configurations include a tape recorder component. Utilize the `Alt-L` key combination to load a binary into the tape recorder. Once loaded, the data can be read using the corresponding Monitor tape load command. Additionally, the data can be output to the tape using `Alt-S` to save the buffered data in the tape recorder to a file.

Loading data through the tape recorder can be time-consuming. Hence, the emulator provides a shortcut: the `Alt-M` key combination directly loads the tape file into memory. The start address is extracted from the binary. Importantly, the `Alt-M` combination is applicable to all configurations, not limited to those featuring the tape recorder.

The emulator supports storage formats from other similar emulators, including .PKI files (sometimes associated with .GAM extensions), .RK and .RKU files, and raw binary files. These formats offer similar capabilities with minor differences in data layout. For more details, refer to the [tape recorder](src/tape.py) component description.


# Tests

To ensure the accuracy of implemented features, particularly CPU instructions, a comprehensive [suite of automated tests](test) has been developed. These tests serve the dual purpose of validating individual component functionalities in isolation and safeguarding against inadvertent codebase alterations during development.

While many tests focus on the functionality of individual components, certain scenarios excercise the collaboration of multiple components (e.g., Machine + RAM + CPU). To facilitate testing without relying on hard-to-set-up or user-facing components, [Mocks](test/mock.py) are employed when feasible.

Some tests, such as [Calculator tests](test/test_calculator.py) are not really tests in classic meaning - it does not suppose to _test_ the firmware (though it found a few issues). These tests is a simple and handy way to execute some functions in the firmware.

For executing substantial portions of machine code that interact with memories and peripherals, a dedicated [helper](test/helper.py) class has been introduced. This helper class offers a convenient interface for reading/writing machine memory during tests, managing peripherals (e.g., emulating keypress sequences), and executing specific functions in the software. Derived classes represent specific configurations ([Calculator](test/test_calculator.py), [CP/M](test/cpm_helper.py), [UT-88 OS](test/ut88os_helper.py)), configuring the appropriate RAM/ROM setup, peripherals, and loading application images.

The tests are implemented with pytest framework.

To run tests use the following commands:
```
cd test
py.test -rfeEsxXwa --verbose --showlocals
```

# Other tools

The repository also contains a few tools created while working on this project.

- [bin2text.py](misc/bin2text.py) prints the contents of a binary file as a hex dump. An optional parameter can be used to specify the starting address for the dump.
- [text2bin.py](misc/text2bin.py) performs the reverse operation by parsing a text hex dump and converting it back into a binary file.
- [float.py](misc/float.py) serves as a helper for the 3-byte float numbers format used in the Calculator module. The class provides the ability to convert 3-byte floats to 4-byte and vice versa.
- [disassembler.py](misc/disassembler.py) is a straightforward disassembler utility. It takes a binary or tape file as input and attempts to disassemble it using i8080 mnemonics. The disassembler provides tracked address references and sets label boilerplates.
- [cpmdisk.py](misc/cpmdisk.py) is a helper class for reading and writing CP/M disks. The class supports both UT-88 and classic CP/M diskette formats. It allows reading directories, reading file contents, and deleting files. For the sake of simplicity, the class works only with whole files and does not provide sector-level access.
- [cpmdisktool.py](misc/cpmdisktool.py) is a command-line utility that facilitates listing, reading, and writing files on the CP/M disk, utilizing the functionality provided by the CPMDisk class mentioned above.
- [dump_font.py](misc/dump_font.py) is a utility to dump a font file contents, presenting each 8 bytes of the binary file as 8x8 bitmask.

# Future plans

This repository contains the complete list of features, descriptions, schematics, and software ever published for UT-88 computer. There are no specific plans to extend this emulator any further.

At the same time there are a few nice to have areas where improvements appreciated:
- Sound over the tape recorder port
- Run "8080/8085 CPU Exerciser" test by Ian Bartholomew to validate implementation correctness
- Add description and disassembly of more UT-88, RK-86, and CP/M programs

Also, it would be interesting to compare UT-88 with other computers in the Radio RK86 family.

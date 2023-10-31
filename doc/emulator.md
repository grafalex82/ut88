# UT-88 Emulator

This project serves as an emulator for the UT-88 hardware, encompassing the CPU, memory, and I/O peripherals. The emulator's architecture closely mirrors the hardware design of the UT-88 computer.

## Emulated hardware components

The emulator project is structured to closely emulate the UT-88 hardware, with each component mirroring its real-world counterpart. Here's a breakdown of the main components and their key implementation notes:

- [**CPU**](../src/common/cpu.py) - Implements the i8080 CPU, incorporating registers, instruction execution, interrupt handling, and instruction fetching pipeline. Optional rich instruction logging for code disassembly and debugging purposes is available. The implementation is inspired by the [py8080 project](https://github.com/matthewmpalen/py8080).
- [**Machine**](../src/common/machine.py) - Represents the machine as a whole, establishing relationships between the CPU, registered (installed) memories, attached I/O devices, and a hypothetical interrupt controller (if applicable).
The concept of the Machine class allows emulating UT-88 design closer to how it works in the hardware. Thus it implements some important concepts:
    - Real CPU does not directly read memory. Instead, it sets the desired address on the address bus, and the connected and selected memory device provides the data on the data bus. This emulation closely resembles the behavior: the CPU is a part of the particular Machine configuration, and can access only a memory which is installed in this configuration. Same for I/O devices, which may vary for different computer configurations.
    - The reset button resets only the CPU, leaving the RAM intact. This aligns with certain workflows in the Monitor 0, where exiting some modes (e.g. Memory Read or Write) is achieved by pressing the Reset button.
    - Some types of memory are triggered by stack read/write operations, such as the Quasi Disk module. This enables RAM and Quasi Disk to operate in the same address space but use different access mechanisms. The Machine class handles port `0x40` to select between regular memory and the quasi disk for stack read/write operations. This behavior is specifically implemented in [UT88Machine](../src/ut88/machine.py) sublass.
    - The UT-88 Computer does not have an interrupt controller. If an interrupt occurr, the data bus will have `0xff` value on the line due to pull-up resistors. This coincide with the RST7 instruction, that runs an interrupt handler.
- Various types of memory, such as [**RAM**](../src/common/ram.py), [**ROM**](../src/common/rom.py), stack memories (e.g. Quasi Disk), and I/O devices are connected to the machine using [MemoryDevice and IODevice adapters](../src/common/interfaces.py). The idea behind is that device does not care about which address it is connected to, and even which address space (memory or I/O). Thus the same device (e.g. keyboard port) may be connected as a memory mapped device in Radio-86RK or as a I/O device in UT-88. The [MemoryDevice and IODevice](../src/common/interfaces.py) adapters are responsible for assigning a peripheral an exact address or port. This design allows for easy extension of the emulator's functionality by implementing new devices or memories, and device configurations by registering devices it in the Machine object. 
- Common components also include general purpose chip emulations (such as [Intel 8255 parallel port](../src/common/ppi)), as well as specific chip implementations (such as [Intel 8257 DMA Controller](../src/common/dma.py)). These components reflect the electrical connectivity and purpose of such chips, emulating their behavior and data flow. At the same time it is assumed that the actual peripherals (e.g. keyboard, tape recorder, or CRT display) will be connected to these chips on the initialization stage.
- Finally, the [**Emulator**](../src/common/emulator.py) class offers convenient routines for running emulation process for the Machine. It provides methods to execute single or multiple machine steps and handle breakpoints. Breakpoints serve as a useful mechanism for performing emulator-side actions based on the machine's condition or CPU state. For instance, it allows adding extra logging when the CPU enters a specific stage or executes specific code.


The following UT-88 peripherals are emulated:
- [**17-button hexadecimal keyboard**](../src/ut88/hexkbd.py) emulates 16 digits buttons, and a step back key. Typically in the UT-88 basic configration this keyboard is connected to I/O port `0xa0` (read only). Reading the port returns the button scan code, or `0x00` if no button is pressed. The implementation converts host computer button presses to UT-88 Hex keyboard scan codes using pygame.
- [**6-digit 7-segment display**](../src/ut88/lcd.py) implementation mimics 7-segment indicators, displaying digit images using pygame according to values in the memory cells. In the UT-88 basic configuration the LCD display is mapped to memory range `0x9000`-`0x9002` (Write only). 
- [**Tape recorder**](../src/common/tape.py) emulates 2-phase coding of data native to UT-88 Monitors (0 and F) as well as Radio-86RK. The emulator can load a binary file and convert it to a series of bit values, allowing the Monitor to read it correctly. It can also collect data bits sent by the Monitor and convert them into a file on disk. The implementation is a little bit hacky, as it is not really time based, but just counts In and Out calls. In the UT-88 configuration the tape recorder is mapped to I/O port `0xa1` LSB. 
- [**Seconds Timer**](../src/ut88/timer.py) is not connected to any data buses in the computer, but rather generates an interrupt every second. As said previously, Machine will set `0xff` on the data line, so that CPU will treat it as RST7 instruction.
- [**Display**](../src/ut88/display.py) emulates the 64x28 chars monochrome display. The module represents a piece of RAM at `0xe800`-`0xefff` that the CPU can write to. 
  - As an extension, the Display class also implement behavior required for UT-88 OS: A parallel memory range `0xe000`-`0xe7ff` (MSB only) can be used to read of write character inversion bit. Character codes in the main range remain intact.
  - The implementation is using [DisplaySurface](../src/common/surface.py) class for actual symbols drawing. Drawing characters based on the Font ROM used in the original hardware (6x8 dot matrix). The display supports symbols in the `0x00`-`0x7f` range, with MSB used to invert the symbol. Symbols in `0x00`-`0x1f` range are pseudo-graphics symbols, which allows converting the display to pseudo 128x56 dots graphic display.
- [**Keyboard**](../src/ut88/keyboard.py) class emulates a 55-button keyboard connected through the [i8255 controller](../src/common/ppi.py) and in case of UT-88 is connected to ports `0x04`-`0x07`. The emulator handles host computer key presses, taking into account Shift and Ctrl mod keys and the Russian keyboard layout, and then sets Port B and C scan codes accordingly. The MonitorF scans the keyboard matrix by setting low levels on the column port A and reading rows through the Port B. Additionally it reads mod keys stats by reading the Port C. Then a special code in the MonitorF converts these scan codes into character codes.
- [**Quasi Disk**](../src/ut88/quasidisk.py) class emulates the quasi disk. It responds to stack read/write commands to perform read/write data on the 'disk'. The 'disk' is a 256k memory buffer loaded during emulator start and flushed to the host system disk periodically. The disk is internally split into four 64k pages, software can use port `0x40` to select the data page to work with.

In addition to UT-88, the following Radio-86RK specific components are implemented as well:
- [**RK86Keyboard**](../src/radio86rk/keyboard.py) is a Radio-86RK keyboard implementation. It is very similar to UT-88's one, but since the keyboard layout is different it required a separate implementation. The keyboard is connected to the machine via i8255 chip, memory mapped to the `0x8000`-`0x8003` memory range.
- [**RK86Display**](../src/radio86rk/display.py) emulates 78x30 characters display based on the Intel 8275 CRT video controller. In the Radio-86RK configuration the CRT chip works in conjunction with Intel 8257 DMA controller to fetch video RAM data. This behavior is also implemented in this class.

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

As a proof of concept, the [character output function](../src/bios_emulator.py) was re-implemented in Python, replacing the MonitorF's implementation. Although this does not introduce any new functionality, it significantly boosts performance of display operations for MonitorF and CP/M use cases.

It's worth noting that extending this approach to optimize quasi disk operations would be another valuable enhancement. This would further demonstrate the emulator's ability to fine-tune its behavior to suit different use cases and scenarios.

This emulation mode is enabled by adding `--emulate_bios` command line switch to the emulator.

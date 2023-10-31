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
- **Special CP/M Port:** The magazine also provided an unique [port of the CP/M operating system](doc/cfg_cpm.md), enabling users to work with files stored on the quasi disk, expanding the computer's capabilities even further.

The architecture of the UT-88 computer draws significant inspiration from two previously published computer systems: the Micro-80 (from the early 1980s) and the Radio-86RK (featured in the 'Radio' magazine between 1985 and 1987). Several technical solutions and design elements are inherited from these predecessors, enhancing the UT-88's overall functionality and compatibility. Key elements carried over from its predecessors include connectivity with tape recorders and the associated recording format, the layout and schematics of the keyboard, and the general hardware framework.

Notably, the UT-88 distinguishes itself by incorporating more advanced and refined schematics. This includes the integration of components like the i8224 and i8238, which replace a multitude of TTL logic gate chips used in the Radio-86RK. Additionally, the UT-88's peripheral are connected to the CPU using I/O address space, in contrast to the Radio-86RK where peripherals were located within the main memory address space. Furthermore, the UT-88's design takes into account chip availability, addressing the scarcity of the i8275 chip in late USSR. In response, the UT-88's video module employs a combination of registers and counters, providing a practical alternative for the video signal generation.

On the software front, the UT-88 maintains a high degree of compatibility with its predecessors. For instance, the Monitor F, which serves as the primary firmware for the Video Module, closely resembles the Radio-86RK Monitor and shares common routine entry points. This compatibility allows for the loading and execution of Radio-86RK programs from tape with minimal to no modifications, underscoring the seamless transition between these related computer systems.

In order to compare UT-88 with the Radio-86RK [a special configuration](doc/cfg_radio86rk.md) is created in this emulator. It allows running vast majority of the Radio-86RK programs.

Scans of the original magazine can be found [here](doc/scans).


# UT-88 Emulator

This project serves as an emulator for the UT-88 hardware, encompassing the CPU, memory, and I/O peripherals. The emulator's architecture closely mirrors the hardware design of the UT-88 computer. The emulator implementation notes are described in [this document](doc/emulator.md) in details.

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

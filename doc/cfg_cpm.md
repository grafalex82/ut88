# CP/M Operating System and Quasi Disk

The highest UT-88 configuration includes a 256k Quasi Disk, enabling it to run the widely recognized CP/M v2.2 operating system. CP/M is an operating system that gained popularity during the era of early microcomputers. With the inclusion of CP/M, the UT-88 system becomes compatible with a wealth of software developed for this operating system.

Typical CP/M programs leverage the CP/M Application Programming Interface (API) for disk and console operations. This adherence to a standardized API enhances compatibility with other computers running CP/M, fostering a high level of interoperability. As a result, users can access and run a variety of software applications and utilities designed for the CP/M ecosystem on the UT-88 system.


## Quasi Disk

The Quasi Disk is a RAM module in the UT-88 system, offering capacities of 64k, 128k, 192k, or 256k, depending on the number of available RAM chips. It is organized into 1-4 banks, each with a capacity of 64k. The module utilizes a clever design using the i8080 CPU's ability to generate different signals for stack and regular memory access.

Specifically, the quasi disk RAM is enabled for stack push/pop instructions, while regular memory is accessible through standard read/write operations. This innovative approach allows both the main RAM and the quasi disk to operate simultaneously within the same address space. A dedicated configuration port at address `0x40` provides the capability to select a RAM bank or disconnect from the quasi disk. By doing so, stack operations are then routed back to the main RAM.

Quasi disk schematic and description can be found [here](scans/UT49.djvu). The magazine suggests that the Quasi Disk may be powered from an accumulator, and therefore data on the disk may 'persist' for a long time.

## CP/M-64

The CP/M system on the UT-88 consists of several modular components, each serving a specific purpose:
- **Console Commands Processor (CCP)**: This component is the user-facing application responsible for accepting and interpreting user commands. It runs user programs and acts as the interface between the user and the system. (CCP Documentation and disassembly is available [here](disassembly/cpm64_ccp.asm))
- **Basic Disk Operating System (BDOS)**: BDOS provides a comprehensive set of high-level functions for interacting with the console and performing file operations. It includes functions for console I/O (input and output), as well as file-related operations such as creating, searching, opening, reading, writing, and closing files. (BDOS documentation and disassembly is available [here](disassembly/cpm64_bdos.asm))
- **Basic Input/Output System (BIOS)**: BIOS offers low-level functions for working with the console and low level disk operations. Console functions include input and output a char. Disk operations provide a way to select a disk, read or write a data sector. (Refer [here](disassembly/cpm64_bios.asm) for the BIOS disassembly)

While CCP and BDOS are hardware-independent and share the same code across different systems, the BIOS is system-specific and tailored to the UT-88 hardware platform. This modular design allows for a high degree of portability and flexibility in CP/M systems.

Particular BIOS for UT-88 provides the following functionality:
- **Keyboard Input**: Routed to the MonitorF implementation.
- **Character Printing Functions**: An [additional layer](disassembly/cpm64_monitorf_addon.asm) on top of MonitorF, implementing ANSI escape sequences for cursor control.
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

## OS Startup

The CP/M system is delivered as a unified binary file that loads at `0x3100`. The loading process is facilitated by a [dedicated bootstrap code](disassembly/CPM64_boot.asm), which not only loads CP/M components to their specified addresses but also initializes the quasi disk. The bootstrap component eventually executes CP/M starting at the `0xda00` address, which corresponds to the BIOS cold boot handler.

CP/M bootstrap file can be found [here](../tapes/CPM64.RKU) (Start address is `0x3100`). For convenience and to expedite loading in the emulator, the CP/M components have been extracted into separate tape files. Each tape file loads to its designated CP/M location:
- [CCP](../tapes/cpm64_ccp.rku)
- [BDOS](../tapes/cpm64_bdos.rku)
- [BIOS](../tapes/cpm64_bios.rku)
- [Put char addon](../tapes/cpm64_monitorf_addon.rku). 

When loading the individual CP/M components separately, the start address is `0xda00`. 

In the CP/M design, two startup scenarios are defined for the system:
- **Cold Boot Operation**:
  - This operation involves initializing the disk and uploading CP/M system components to the first several tracks of the disk. Specifically, the first 6 tracks of the quasi disk are reserved for the system
  - Cold boot is responsible for the initial setup of the disk and ensuring that the necessary CP/M components are available for execution.
- **Warm Boot Operation**:
  - This operation assumes that the disk system and BIOS are already initialized. In a warm boot, CCP and BDOS components are loaded from the disk if these areas were modified or erased by a user program.
  - During a cold boot, the CP/M startup code places a JMP WARM_BOOT instruction at 0x0000. This ensures that all subsequent boots or CPU resets go through the warm boot scenario, skipping the disk initialization phase.


## CP/M UT-88 Compatibility

While the CP/M system and various CP/M programs function on UT-88 hardware, there are two compatibility issues:
- **Encoding Issue**:
  UT-88 video module uses KOI-7 N2 encoding, which lacks lower case Latin letters. Instead, upper case Cyrillic letters are used. This results in lower case text messages being printed with Cyrillic letters, making it appear unusual though still somewhat readable.
- **Keyboard Input Incompatibility**:
  CP/M BIOS expects two functions to handle terminal input: one to check if a key is currently pressed and another to read the pressed key. If no key is pressed, the second function shall return immediately. The MonitorF provides similar, but not exactly the same interface. The keyboard read function generates a value on the first key press. If the key is _still_ pressed, subsequent calls to the wait-for-key function will not be processed until the key is released and pressed again (or the keyboard auto-repeat triggers). CP/M BIOS expects immediate results - if a key is pressed, the wait-for-key function should return the code of the pressed key immediately.

  At the same time CP/M BDOS printing function checks for keyboard activity, specifically looking for the Ctrl-C break key combination. This results in a scenario where the user enters a symbol, the symbol is echoed on the console, and the printing function detects that the key is still pressed, attempting to get its code. This call in fact starts waiting for a new key, leading to the skipping of every second entered key. This behavior can be disruptive, especially in an emulator.

  As a quick workaround in the emulator, reading the keyboard while printing a symbol was disabled to alleviate this issue.


## CP/M-35 (CP/M with no quasi disk)

For users who do not have access to the quasi disk module, a special version of CP/M is offered, featuring an in-memory RAM drive. In accordance with CP/M design principles, CCP and BDOS components remain identical to the normal disk version of CP/M. However, this version comes with a [custom BIOS](disassembly/cpm35_bios.asm) that allocates a 35k RAM drive in the system memory.

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

CP/M-35 binary is located [here](../tapes/CPM35.RKU). Start address is `0x4a00`.


## CP/M programs

If a CP/M program avoids hardware-specific features and relies solely on BDOS/BIOS routines to interact with the system, there's a high likelihood that the program will function normally on the UT-88 version of CP/M.

Here are descriptions of a few standard CP/M programs that are interesting for learning and evaluation:
- [SUBMIT.COM](disassembly/submit.asm) - This program provides a way to create and run scripts that are automatically executed by the CP/M CCP. SUBMIT.COM allows for the parameterization of scripts, making them generic, and the program substitutes actual parameter values. Despite being a standalone application, it has some support from CCP and even BDOS functions to facilitate its operation. The program was originally written in PL/M language, and the original source has been [added to the repository](disassembly/SUBMIT.PLM) for comparison (code found on the Internet, probably the original source).
- [XSUB.COM](disassembly/xsub.asm) - XSUB is a program that enables substituting console input to be passed to other programs. The program loads and stays resident in memory, hooks the BDOS handler, and substitutes it with its own. If a program calls BDOS for console input, XSUB provides predefined data instead (loaded from a file). This program is interesting due to its 'terminate and stay resident' approach, as well as its capability of hooking the BDOS handler.


# Running CP/M in the UT-88 Emulator

UT-88 with CP/M-64 system loaded can be started as follows:
```
python src/main.py cpm64
```

This command starts the regular video module monitor with CP/M components loaded to the memory ([CCP](../tapes/cpm64_ccp.rku), [BDOS](../tapes/cpm64_bdos.rku), and [BIOS](../tapes/cpm64_bios.rku)). Use `G DA00` command to skip CP/M bootstrap module, and start CP/M directly. In this case pre-created quasi disk image is used, and its contents survive between runs. 

The `G 3000` command can be used to run [bootstrap module](../tapes/CPM64.RKU), which is also preloaded in this configuration. The bootstrap module will create/clear and initialize quasi disk image, that later may be used with the system.

Note that the QuasiDisk.bin quasi disk file is created in the current directory. 

CP/M-35 version of the OS can be executed as follows: load [OS binary](../tapes/CPM35.RKU), and execute it with `G 4A00` command. Note that keyboard incompatibility workaround is applied only for CP/M-64 version, but not CP/M-35.

![](images/cpm64.png)

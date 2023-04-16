# UT-88 - Soviet DIY i8080-based computer

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
- The magazine offerred a special port of the CP/M operating system, that allows working with files on the disk.

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
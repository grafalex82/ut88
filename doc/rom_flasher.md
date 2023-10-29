# ROM flasher addon

The magazine offered an interesting addon for the UT-88 computer, which was a ROM flasher. This device was designed to enable the programming of 573RF2 and 573RF5 2k ROM chips, both of which were claimed to be analogs of Intel 2716 ROM chips. Overall, the ROM flasher addon added a valuable feature to the UT-88, enabling users to work with ROM chips and potentially customize their computer's functionality to suit their specific needs.

The [schematics](scans/UT60.djvu) for the ROM flasher device appear to be relatively straightforward, and is based on the i8255 chip. However, it's worth noting that there is a discrepancy in the CE (Chip Enable) and OE (Output Enable) lines compared to their references in the code.

To support the ROM flasher device, a dedicated flasher program was provided. This program, which you can explore in the [disassembly](disassembly/flasher.asm), allowed users to read and write to the ROM chips using the flasher device. 

The ROM flasher is not emulated in this emulator.
import argparse
import struct
import re

ADDR_RE = re.compile("([0-9A-Fa-f]+)\\s+(.*)")
BYTE_RE = re.compile("([0-9A-Fa-f]+)(\\s+.*)?")

def main():
    parser = argparse.ArgumentParser(
                    prog='text2bin',
                    description='Hexadecimal textual view to binary converter')
    parser.add_argument('textfile')
    parser.add_argument('binfile')
    parser.add_argument("-t", "--tape", action="store_false", help="Add tape header")
    args = parser.parse_args()

    output_data = bytearray()

    start_addr = None
    end_addr = None

    with open(args.textfile, mode="rt") as infile:
        for line in infile.readlines():
            m = ADDR_RE.match(line)
            if not m:
                continue

            addr = int(m.group(1), 16)
            if not start_addr:
                start_addr = addr
                end_addr = addr

            data = m.group(2)

            while m:=BYTE_RE.match(data):
                byte = int(m.group(1), 16) & 0xff
                output_data += bytes([byte])
                end_addr += 1

                data = m.group(2).strip() if m.group(2) else ""

    with open(args.binfile, mode="wb") as outfile:
        if args.tape:
            outfile.write(b'\x00' * 256)    # Pilot tone
            outfile.write(b'\xe6')          # Sync byte
            outfile.write(struct.pack(">H", start_addr))
            outfile.write(struct.pack(">H", end_addr - 1))

        outfile.write(output_data)


if __name__ == '__main__':
    main()

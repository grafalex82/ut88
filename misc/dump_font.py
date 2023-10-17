import argparse

def get_scan_line(font, char, line):
    index = (char << 3) + line
    byte = ~font[index]
    line = ""
    for j in range(8):
        ch = "@" if byte & 0x01 else " "
        line = ch + line
        byte >>= 1

    return line

def dump_font(filename):
    with open(filename, "rb") as f:
        data = f.read()

    for ch in range(len(data) // 8):
        print()
        print(f"Char: {ch:02x}")

        for i in range(8):
            line = get_scan_line(data, ch, i)
            print(line)


def dump_font_2_columns(filename):
    with open(filename, "rb") as f:
        data = f.read()

    for ch in range(128):
        print()
        print(f"Char: {ch:02x}    Char: {ch + 0x80:02x}")

        for i in range(8):
            line1 = get_scan_line(data, ch, i)
            line2 = get_scan_line(data, ch + 0x80, i)
            print(line1 + "    " + line2)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
                    prog='dump_font',
                    description='Utility to dump 8x8 font files')
    parser.add_argument('fontfile')
    parser.add_argument("-2", "--twocolumns", action="store_true", help="Dump the font file in 2 columns")
    args = parser.parse_args()

    if args.twocolumns:
        dump_font_2_columns(args.fontfile)
    else:
        dump_font(args.fontfile)

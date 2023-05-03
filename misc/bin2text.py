import argparse
import sys

def main():
    parser = argparse.ArgumentParser(
                    prog='bin2text',
                    description='Binary to hexadecimal textual view converter')
    parser.add_argument('binfile')
    parser.add_argument('startaddr', nargs="?")
    args = parser.parse_args()

    with open(args.binfile, mode="rb") as f:
        bin = f.read()

        addr = 0
        if args.startaddr:
            addr = int(args.startaddr, 16)

        for c in bin:
            if addr % 0x10 == 0:
                sys.stdout.write(f"\n{addr:04x} ")
            sys.stdout.write(f" {int(c):02x}")
            addr += 1
            

if __name__ == '__main__':
    main()

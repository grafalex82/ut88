import argparse

from cpmdisk import *


def main():
    parser = argparse.ArgumentParser(
                    prog='cpmdisktool',
                    description='Loader/Saver for CPMDisk')
    parser.add_argument('diskfile')
    parser.add_argument('command', choices=["put", "get", "list", "delete"])
    parser.add_argument('file', nargs='?')
    args = parser.parse_args()

    disk = CPMDisk(args.diskfile, params=UT88DiskParams)
    if args.command == 'put':
        with open(args.file, "rb") as f:
            data = f.read()
            disk.write_file(args.file.upper(), data)
            disk.flush()

    if args.command == 'get':
        data = disk.read_file(args.file.upper())
        with open(args.file, "w+b") as f:
            f.write(data)

    if args.command == 'list':
        for entry, data in disk.list_dir().items():
            print(f"{entry}: {data}")

    if args.command == 'delete':
        disk.delete_file(args.file.upper())
        disk.flush()


if __name__ == '__main__':
    main()

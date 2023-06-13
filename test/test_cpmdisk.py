# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CPMDisk module, checking functions provided by the class.

import pytest
import sys

sys.path.append('../misc')

from cpmdisk import *

@pytest.fixture
def tmp_disk_file(tmp_path):
    f = tmp_path / "test_disk.img"
    return f


@pytest.fixture
def standard_disk_file():
    f = "test_disk.img"
    return f


def gen_content(lines_count):
    res = ""
    for i in range(lines_count):
        res += f"Line num {i:04}!\r\n"

    return res


def bin2str(data):
    return ''.join(chr(code) for code in data)


def str2bin(data):
    return bytearray(data.encode('ascii'))


def test_create_disk(tmp_disk_file):
    # Create an empty disk
    disk = CPMDisk(tmp_disk_file)
    disk.flush()

    # Check the file exists
    assert tmp_disk_file.exists()
    assert tmp_disk_file.stat().st_size == 256256 # 77 tracks * 26 sectors * 128 bytes in sector


def test_list_dir_raw(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    entries = disk.list_dir_raw()

    # for entry in entries:
    #     print(entry)
    # assert False

    entry2 = entries[1]
    assert entry2['name'] == 'OS2CCP'
    assert entry2['ext'] == 'ASM'
    assert entry2['entry'] == 0 
    assert entry2['num_records'] == 128
    assert entry2['allocation'] == [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]


def test_list_dir(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    entries = disk.list_dir()

    os2cpp_asm = entries['OS2CCP.ASM']
    assert os2cpp_asm['filename'] == "OS2CCP.ASM"
    assert os2cpp_asm['num_records'] == 200
    assert os2cpp_asm['allocation'] == list(range(5, 30))


def test_read_small_file(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    data = bin2str(disk.read_file('OS5TRINT.SRC'))

    print(data)
    assert "PIP INTERFACE" in data
    assert "DEFAULT BUFFER" in data


def test_read_big_file(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    data = bin2str(disk.read_file('OS3BDOS.ASM'))

    print(data)
    assert "Bdos Interface, Bdos, Version 2.2 Feb, 1980" in data        # A line at the beginning
    assert "directory record 0,1,...,dirmax/4" in data                  # A line at the end


def test_disk_allocation(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    allocation = disk.get_disk_allocation()

    assert allocation[0] == True        # Directory block
    assert allocation[1] == True        # Directory block
    assert allocation[2] == True        # Data block
    assert allocation[200] == True      # Data block
    assert allocation[221] == False     # Empty data block
    assert allocation[240] == False     # Empty data block


def test_get_free_blocks(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    free_blocks = disk.get_free_blocks()
    assert free_blocks == [x for x in range(221, 243)]


def test_write_small_file(tmp_disk_file):
    # Generate test content
    content = gen_content(8)

    # Create the disk, and write the content to a new file
    disk = CPMDisk(tmp_disk_file)
    disk.write_file('TEST.TXT', str2bin(content))
    disk.flush()

    # Read the file and check the content
    data = bin2str(disk.read_file('TEST.TXT'))
    assert content == data


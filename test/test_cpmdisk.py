# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CPMDisk module, checking functions provided by the class.

import pytest
import sys

sys.path.append('../misc')

from cpmdisk import *
from helper import bytes2str, str2bytes

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

    entry2 = entries[1]
    assert entry2['name'] == 'OS2CCP'
    assert entry2['ext'] == 'ASM'
    assert entry2['user_code'] == 0
    assert entry2['entry'] == 0 
    assert entry2['num_records'] == 128
    assert entry2['allocation'] == [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]


def test_list_dir(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    entries = disk.list_dir()

    os2cpp_asm = entries['OS2CCP.ASM']
    assert os2cpp_asm['filename'] == "OS2CCP.ASM"
    assert os2cpp_asm['user_code'] == 0
    assert os2cpp_asm['num_records'] == 200
    assert os2cpp_asm['allocation'] == list(range(5, 30))


def test_read_small_file(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    data = bytes2str(disk.read_file('OS5TRINT.SRC'))

    print(data)
    assert "PIP INTERFACE" in data
    assert "DEFAULT BUFFER" in data


def test_read_big_file(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    data = bytes2str(disk.read_file('OS3BDOS.ASM'))

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

@pytest.mark.parametrize("data_size", [
    8,      # 1 sector, block is partially filled
    64,     # 8 sectors, 1 full block
    128,    # 16 sectors, 2 full blocks
    1024,   # 128 sectors, 16 full blocks - full extent
    1032,   # >128 sectors, require additional extent
])
def test_write_file(tmp_disk_file, data_size):
    # Generate test content
    content = gen_content(data_size)

    # Create the disk, and write the content to a new file
    disk = CPMDisk(tmp_disk_file)
    disk.write_file('TEST.TXT', str2bytes(content))
    disk.flush()

    # Read the file and check the content
    data = bytes2str(disk.read_file('TEST.TXT'))
    assert content == data


def test_write_with_padding(tmp_disk_file):
    # Generate test content <128 bytes
    content = gen_content(2)

    # Create the disk, and write the content to a new file
    disk = CPMDisk(tmp_disk_file)
    disk.write_file('TEST.TXT', str2bytes(content))
    disk.flush()

    # Read the file and check the content
    data = disk.read_file('TEST.TXT')
    assert bytes2str(data[0:32]) == content           # First bytes match the generated content
    assert data[32:128] == bytearray([0x1a] * 96)   # Remainder of the sector was padded with EOF bytes


def test_create_file_with_user_code(tmp_disk_file):
    # Generate test content
    content = gen_content(16)

    # Create the disk, and write several files on the disk with different error codes
    disk = CPMDisk(tmp_disk_file)
    disk.write_file('TEST1.TXT', str2bytes(content), 1)
    disk.write_file('TEST2.TXT', str2bytes(content), 2)
    disk.write_file('TEST3.TXT', str2bytes(content), 3)
    disk.flush()

    # Check that all these files have correct user codes
    entries = disk.list_dir()
    assert entries['TEST1.TXT']['user_code'] == 1
    assert entries['TEST2.TXT']['user_code'] == 2
    assert entries['TEST3.TXT']['user_code'] == 3


@pytest.mark.parametrize("data_size", [
    1024,   # one full extent
    4096,   # several extents
])
def test_delete_small_file(tmp_disk_file, data_size):
    # Create a file on the disk
    disk = CPMDisk(tmp_disk_file)
    content = gen_content(data_size)
    disk.write_file('TEST.TXT', str2bytes(content))

    # Check the file is on the disk
    entries = disk.list_dir()
    assert len(entries) == 1
    assert 'TEST.TXT' in entries

    # Delete the file
    disk.delete_file('TEST.TXT')

    # Ensure no files on the disk
    assert len(disk.list_dir()) == 0


def test_overwrite_file(tmp_disk_file):
    # Create a file
    disk = CPMDisk(tmp_disk_file)
    content = gen_content(8)
    disk.write_file('TEST.TXT', str2bytes(content))

    # Verify its size
    assert disk.list_dir()['TEST.TXT']['num_records'] == 1

    # Write another file with the same name
    content = gen_content(512)
    disk.write_file('TEST.TXT', str2bytes(content))

    # Verify the file was overwrittent
    for entry in disk.list_dir_raw():
        print(entry)

    assert len(disk.list_dir()) == 1
    assert disk.list_dir()['TEST.TXT']['num_records'] == 64
    assert bytes2str(disk.read_file('TEST.TXT')) == content

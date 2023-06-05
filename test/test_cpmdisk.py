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


def test_create(tmp_disk_file):
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
    data = disk.read_file('OS5TRINT.SRC')
    data_str = ''.join(chr(code) for code in data)

    print(''.join(chr(code) for code in data))
    assert "PIP INTERFACE" in data_str
    assert "DEFAULT BUFFER" in data_str


def test_read_big_file(standard_disk_file):
    disk = CPMDisk(standard_disk_file)
    data = disk.read_file('OS3BDOS.ASM')
    data_str = ''.join(chr(code) for code in data)

    print(''.join(chr(code) for code in data))
    assert "Bdos Interface, Bdos, Version 2.2 Feb, 1980" in data_str        # A line at the beginning
    assert "directory record 0,1,...,dirmax/4" in data_str                  # A line at the end

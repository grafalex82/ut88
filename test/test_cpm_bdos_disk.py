# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CP/M operating system (BDOS console functions), rather than UT-88 schematics. 
# These tests are not tests in general meaning, they are not supposed to _test_ anything.
# This is rather a handy way to run emulation of some functions from the CP/M software bundle,
# in order to understand better how do they work.
#
# Tests run an emulator, load CP/M components, and run required functions with certain arguments.

import sys
import pytest

sys.path.append('../misc')

from cpm_helper import CPM
from quasidisk import QuasiDisk
from cpmdisk import *


@pytest.fixture
def cpm():
    return CPM()


@pytest.fixture
def disk(tmp_path):
    # Create and install an empty quasi disk
    f = tmp_path / "test.bin"
    f.write_bytes(bytearray([0xe5] * (256*1024)))
    disk = QuasiDisk(f)
    return disk


def call_bdos_function(cpm, func, arg = 0):
    cpm.cpu._c = func
    cpm.cpu.de = arg
    cpm.run_function(0xcc06)
    return (cpm.cpu._b << 8) | cpm.cpu._a


def fill_fcb(cpm, addr, filename):
    # Zero the file control block
    for i in range(33):
        cpm.set_byte(addr + i, 0x00)

    # Set name
    name = f"{filename.split('.')[0]:8s}"
    for i in range(8):
        cpm.set_byte(addr + 1 + i, ord(name[i]))

    # Set extension
    ext = f"{filename.split('.')[1]:3s}"
    for i in range(3):
        cpm.set_byte(addr + 9 + i, ord(ext[i]))


def test_reset_disk_system(cpm, disk):
    cpm._emulator._machine.set_quasi_disk(disk)

    call_bdos_function(cpm, 0x0d)


def test_write_protect_disk(cpm, disk):
    cpm._emulator._machine.set_quasi_disk(disk)
    call_bdos_function(cpm, 0x0d)

    # Check starting conditions
    assert cpm.get_word(0xd9ad) == 0x0000   # Write protect bit is not set for any disk

    # Write protect disk A (0)
    call_bdos_function(cpm, 0x1c, 0)

    # Check new conditions
    assert cpm.get_word(0xd9ad) == 0x0001   # Write protect bit is set for disk A
    assert cpm.get_word(0xda35) == 32       # Last entry number is set to maximum dir entries number


def test_seek(cpm, disk):
    cpm._emulator._machine.set_quasi_disk(disk)
    call_bdos_function(cpm, 0x0d)

    # Seek in forward direction, compared to current track
    cpm.set_word(0xd9e5, 0x0342)    # Set expected sector number to 0x342
    cpm.run_function(0xcfd1)        # Call seek function

    # Sector #0x342 is located on track 0x68 having 8 sectors per track. Disk is split into four
    # pages 0x40 tracks each. So track #0x68 is located on page 1, track 0x28.
    # Also, the disk has 6 reserved tracks, so the physical track number will be 0x28 + 6 = 0x2e
    # Sector number is 0x342 % 8 = 2. This is a logical sector number, whick will be renumbered
    # to #3 physical sector number.
    assert cpm.get_byte(0xdbec) == 0xfd # Page 2
    assert cpm.get_byte(0xdbed) == 0x2e # Logical Track 0x28 (Physical track = 0x28 + 6 reserved tracks)
    assert cpm.get_byte(0xdbee) == 0x03 # Sector #3 (Logical track #2, physical track #3 since 1-based)


    # Seek in backward direction, compared to current track
    cpm.set_word(0xd9e5, 0x073)     # Set expected sector number to 0x342
    cpm.run_function(0xcfd1)        # Call seek function

    assert cpm.get_byte(0xdbec) == 0xfe
    assert cpm.get_byte(0xdbed) == 0x14
    assert cpm.get_byte(0xdbee) == 0x04


def test_create_file(cpm, disk):
    cpm._emulator._machine.set_quasi_disk(disk)
    call_bdos_function(cpm, 0x0d)

    fill_fcb(cpm, 0x1000, 'ABC.TXT')

    code = call_bdos_function(cpm, 0x16, 0x1000)
    assert code == 0

    code = call_bdos_function(cpm, 0x10, 0x1000)
    assert code == 0

    disk.update()
    loader = CPMDisk(disk.filename, params=UT88DiskParams)
    entries = loader.list_dir()

    assert len(entries) == 1
    assert entries['ABC.TXT']['num_records'] == 0


# Test create a file on a read only disk
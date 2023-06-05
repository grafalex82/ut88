# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CP/M operating system (BDOS console functions), rather than UT-88 schematics. 
# These tests are not tests in general meaning, they are not supposed to _test_ anything.
# This is rather a handy way to run emulation of some functions from the CP/M software bundle,
# in order to understand better how do they work.
#
# Tests run an emulator, load CP/M components, and run required functions with certain arguments.

import pytest

from cpm_helper import CPM
from quasidisk import QuasiDisk

@pytest.fixture
def cpm():
    return CPM()


@pytest.fixture
def disk(tmp_path):
    # Create and install an empty quasi disk
    f = tmp_path / "test.bin"
    f.write_bytes(bytearray(256*1024))
    disk = QuasiDisk(f)
    return disk


def call_bdos_function(cpm, func, arg = 0):
    cpm.cpu._c = func
    cpm.cpu.de = arg
    cpm.run_function(0xcc06)
    return (cpm.cpu._b << 8) | cpm.cpu._a



def test_reset_disk_system(cpm, disk):
    cpm._emulator._machine.set_quasi_disk(disk)

    call_bdos_function(cpm, 0x0d)


def test_seek(cpm, disk):
    cpm._emulator._machine.set_quasi_disk(disk)
    call_bdos_function(cpm, 0x0d)

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



    cpm.set_word(0xd9e5, 0x073)    # Set expected sector number to 0x342
    cpm.run_function(0xcfd1)        # Call seek function

    assert cpm.get_byte(0xdbec) == 0xfe
    assert cpm.get_byte(0xdbed) == 0x14
    assert cpm.get_byte(0xdbee) == 0x04


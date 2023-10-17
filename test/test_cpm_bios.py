# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

# This file contains tests for CP/M operating system (BIOS part), rather than UT-88 schematics.
# These tests are not tests in general meaning, they are not supposed to _test_ anything.
# This is rather a handy way to run emulation of some functions from the CP/M software bundle,
# in order to understand better how do they work.
#
# Tests run an emulator, load CP/M components, and run required functions with certain arguments.

import pytest

from cpm_helper import CPM
from ut88.quasidisk import QuasiDisk


# Exposed BIOS functions
BIOS_FUNC_SELECT_TRACK_ZERO     = 0xda18
BIOS_FUNC_SELECT_DISK           = 0xda1b
BIOS_FUNC_SELECT_TRACK          = 0xda1e
BIOS_FUNC_SELECT_SECTOR         = 0xda21
BIOS_FUNC_SET_BUFFER            = 0xda24
BIOS_FUNC_READ_SECTOR           = 0xda27
BIOS_FUNC_WRITE_SECTOR          = 0xda2a

# Some important BIOS variables, that are checked in the tests
BIOS_DESCRIPTOR_PTR             = 0xda33
BIOS_QUASI_DISK_PAGE            = 0xdbec
BIOS_QUASI_DISK_TRACK           = 0xdbed
BIOS_QUASI_DISK_SECTOR          = 0xdbee
BIOS_CUR_BUF_PTR                = 0xdbef

# Data buffer used in tests
DATA_BUF_PTR                    = 0x4200

@pytest.fixture
def cpm():
    return CPM()


def select_disk(cpm, disk):
    cpm.cpu._c = disk
    cpm.run_function(BIOS_FUNC_SELECT_DISK)


def select_track(cpm, track):
    cpm.cpu._c = track
    cpm.run_function(BIOS_FUNC_SELECT_TRACK)


def select_sector(cpm, sector):
    cpm.cpu._c = sector
    cpm.run_function(BIOS_FUNC_SELECT_SECTOR)


def set_disk_buffer(cpm, addr):
    cpm.cpu.bc = addr
    cpm.run_function(BIOS_FUNC_SET_BUFFER)


def test_bios_select_disk(cpm):
    select_disk(cpm, 0)
    assert cpm.cpu.hl == BIOS_DESCRIPTOR_PTR


def test_bios_select_incorrect_disk(cpm):
    select_disk(cpm, 1)
    assert cpm.cpu.hl == 0x0000


def test_bios_select_track(cpm):
    select_track(cpm, 0x05)
    assert cpm.get_byte(BIOS_QUASI_DISK_PAGE) == 0xfe   # Page 0
    assert cpm.get_byte(BIOS_QUASI_DISK_TRACK) == 0x05  # Track 5

    select_track(cpm, 0x98)
    assert cpm.get_byte(BIOS_QUASI_DISK_PAGE) == 0xfb   # Page 2
    assert cpm.get_byte(BIOS_QUASI_DISK_TRACK) == 0x18  # Track 0x18

    select_track(cpm, 0xff)
    assert cpm.get_byte(BIOS_QUASI_DISK_PAGE) == 0xf7   # Page 3
    assert cpm.get_byte(BIOS_QUASI_DISK_TRACK) == 0x3f  # Track 0x3f


def test_bios_select_track_zero(cpm):
    cpm.run_function(BIOS_FUNC_SELECT_TRACK_ZERO)

    assert cpm.get_byte(BIOS_QUASI_DISK_PAGE) == 0xfe   # Page 0
    assert cpm.get_byte(BIOS_QUASI_DISK_TRACK) == 0x00  # Track 0


def test_bios_select_sector(cpm):
    select_sector(cpm, 0x42)

    assert cpm.get_byte(BIOS_QUASI_DISK_SECTOR) == 0x42


def test_bios_set_buffer(cpm):
    set_disk_buffer(cpm, DATA_BUF_PTR)

    assert cpm.get_word(BIOS_CUR_BUF_PTR) == DATA_BUF_PTR


def test_bios_read_sector(cpm, tmp_path):
    data = bytearray(256*1024)
    offset = 70*1024 + 3*128 # track 70 (track 6 on page 1), sector 3
    sector_data = [1, 2, 3, 4, 5, 6, 7, 8] * 16
    data[offset:offset+128] = sector_data

    # Store the data to disk
    f = tmp_path / "test.bin"
    f.write_bytes(data)

    # Attach the quasi disk with prepared data to the machine
    disk = QuasiDisk(f)
    cpm._emulator._machine.set_quasi_disk(disk)

    # Select disk/track/sector
    select_disk(cpm, 0)
    select_track(cpm, 70)
    select_sector(cpm, 3 + 1) # Sectors numbering is 1-based
    set_disk_buffer(cpm, DATA_BUF_PTR)

    # Read the selected sector into the buffer
    cpm.run_function(BIOS_FUNC_READ_SECTOR)

    # Check the read sector
    for i in range(len(sector_data)):
        assert cpm.get_byte(DATA_BUF_PTR + i) == sector_data[i]


def test_bios_write_sector(cpm, tmp_path):
    # Prepare data buffer
    sector_data = [1, 2, 3, 4, 5, 6, 7, 8] * 16
    for i in range(len(sector_data)):
        cpm.set_byte(DATA_BUF_PTR + i, sector_data[i])

    # Create and install an empty quasi disk
    f = tmp_path / "test.bin"
    f.write_bytes(bytearray(256*1024))
    disk = QuasiDisk(f)
    cpm._emulator._machine.set_quasi_disk(disk)

    # Select disk/track/sector
    select_disk(cpm, 0)
    select_track(cpm, 70)
    select_sector(cpm, 3 + 1) # Sectors numbering is 1-based
    set_disk_buffer(cpm, DATA_BUF_PTR)

    # Write the buffer data to the selected sector
    cpm.run_function(BIOS_FUNC_WRITE_SECTOR)

    # Flush the data to the host
    disk.update()

    # Check written data
    data = f.read_bytes()
    offset = 70*1024 + 3*128 # track 70 (track 6 on page 1), sector 3
    for i in range(128):
        assert data[offset + i] == sector_data[i]

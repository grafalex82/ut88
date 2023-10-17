# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from machine import UT88Machine
from common.utils import *
from quasidisk import QuasiDisk
from common.interfaces import MemoryDevice
from ram import RAM

# The Port 0x40 is a configuration port. Writing 0xfe, 0xfd, 0xfb, or 0xf7 to this port will enable
# 1st, 2nd, 3rd, or 4th page respectively, so that subsequent stack operations will read or write data
# to/from the quasi disk page. Writing 0xff to the port disables the quasi disk access, and stack 
# operations are routed to the main memory
CONFIG_PORT = 0x40

# Constants that select a quasi disk page
QUASI_DISK_PAGE_0   = 0xfe
QUASI_DISK_PAGE_1   = 0xfd
QUASI_DISK_PAGE_2   = 0xfb
QUASI_DISK_PAGE_3   = 0xf7
QUASI_DISK_DISABLE  = 0xff

@pytest.fixture
def diskfile(tmp_path):
    f = tmp_path / "test.bin"
    f.write_bytes(b"\x00"*256*1024)
    return f


@pytest.fixture
def quasidisk(diskfile):
    disk = QuasiDisk(diskfile)
    return disk


def test_creation(quasidisk):
    assert quasidisk._page == None


def test_page_selection(quasidisk):
    quasidisk.select_page(QUASI_DISK_PAGE_0)
    assert quasidisk._page == 0

    quasidisk.select_page(QUASI_DISK_PAGE_1)
    assert quasidisk._page == 1

    quasidisk.select_page(QUASI_DISK_PAGE_2)
    assert quasidisk._page == 2

    quasidisk.select_page(QUASI_DISK_PAGE_3)
    assert quasidisk._page == 3

    quasidisk.select_page(QUASI_DISK_DISABLE)
    assert quasidisk._page == None


def test_incorrect_page_selection(quasidisk):
    # Try writing incorrect page index
    with pytest.raises(IOError):
        quasidisk.select_page(0x42)


def test_page_not_selected(quasidisk):
    with pytest.raises(IOError):
        quasidisk.write_stack(0x4000, 0x4242)

    with pytest.raises(IOError):
        quasidisk.read_stack(0x4000)


def test_read_write(quasidisk):
    # Select a page
    quasidisk.select_page(QUASI_DISK_PAGE_3)

    # Write then read on the same page
    quasidisk.write_stack(0x4000, 0x4242)
    assert quasidisk.read_stack(0x4000) == 0x4242


def test_read_write_different_pages(quasidisk):
    # Write on page 4
    quasidisk.select_page(QUASI_DISK_PAGE_3)
    quasidisk.write_stack(0x4000, 0x4242)

    # Try reading from a different page
    quasidisk.select_page(QUASI_DISK_PAGE_0)
    assert quasidisk.read_stack(0x4000) == 0x0000


def test_read_data(tmp_path):
    # Prepare data
    data = bytearray(256*1024)
    data[0        + 0x1234] = 0x12
    data[64*1024  + 0x2345] = 0x34
    data[128*1024 + 0x3456] = 0x56
    data[192*1024 + 0x4567] = 0x78

    # Store the data to disk
    f = tmp_path / "test.bin"
    f.write_bytes(data)

    # Create quasi disk
    quasidisk = QuasiDisk(f)

    # Validate data on the disk
    quasidisk.select_page(QUASI_DISK_PAGE_0)
    assert quasidisk.read_stack(0x1234) == 0x12
    quasidisk.select_page(QUASI_DISK_PAGE_1)
    assert quasidisk.read_stack(0x2345) == 0x34
    quasidisk.select_page(QUASI_DISK_PAGE_2)
    assert quasidisk.read_stack(0x3456) == 0x56
    quasidisk.select_page(QUASI_DISK_PAGE_3)
    assert quasidisk.read_stack(0x4567) == 0x78



def test_read_data(diskfile):
    quasidisk = QuasiDisk(diskfile)

    # Write some data on the disk
    quasidisk.select_page(QUASI_DISK_PAGE_0)
    quasidisk.write_stack(0x1234, 0x12)
    quasidisk.select_page(QUASI_DISK_PAGE_1)
    quasidisk.write_stack(0x2345, 0x34)
    quasidisk.select_page(QUASI_DISK_PAGE_2)
    quasidisk.write_stack(0x3456, 0x56)
    quasidisk.select_page(QUASI_DISK_PAGE_3)
    quasidisk.write_stack(0x4567, 0x78)

    # Ensure data is dumped to the host system file
    quasidisk.update()

    # Validate the data
    data = diskfile.read_bytes()

    assert data[0        + 0x1234] == 0x12
    assert data[64*1024  + 0x2345] == 0x34
    assert data[128*1024 + 0x3456] == 0x56
    assert data[192*1024 + 0x4567] == 0x78


@pytest.fixture
def ut88(quasidisk):
    machine = UT88Machine()
    machine.set_quasi_disk(quasidisk)
    machine.set_strict_validation(True)
    return machine

def test_read_write_via_machine(ut88):
    # Enable quasi disk
    ut88.write_io(CONFIG_PORT, QUASI_DISK_PAGE_0)
    ut88.write_stack(0xbeef, 0x42)

    assert ut88.read_stack(0xbeef) == 0x42


def test_machine_disk_not_selected(ut88):
    # Quasidisk is not selected via port 0x40

    with pytest.raises(MemoryError):
        ut88.write_stack(0xbeef, 0x42)

    with pytest.raises(MemoryError):
        ut88.read_stack(0xbeef)

def test_select_between_disk_and_memory(ut88):
    ut88.add_memory(MemoryDevice(RAM(), 0x0000, 0xffff))

    # Write RAM, read QuasiDisk
    ut88.write_io(CONFIG_PORT, QUASI_DISK_DISABLE)
    ut88.write_stack(0xbeef, 0x1234)            # RAM write
    ut88.write_io(CONFIG_PORT, QUASI_DISK_PAGE_0)
    ut88.write_stack(0xbeef, 0x4321)            # Quasi Disk write

    assert ut88.read_stack(0xbeef) == 0x4321    # Quasi disk read
    ut88.write_io(CONFIG_PORT, QUASI_DISK_DISABLE)
    assert ut88.read_stack(0xbeef) == 0x1234    # RAM read

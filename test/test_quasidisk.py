# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from machine import Machine
from utils import *
from quasidisk import QuasiDisk


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
    quasidisk.write_io(0x40, 0xfe)
    assert quasidisk._page == 0

    quasidisk.write_io(0x40, 0xfd)
    assert quasidisk._page == 1

    quasidisk.write_io(0x40, 0xfb)
    assert quasidisk._page == 2

    quasidisk.write_io(0x40, 0xf7)
    assert quasidisk._page == 3

    quasidisk.write_io(0x40, 0xff)
    assert quasidisk._page == None


def test_incorrect_port(quasidisk):
    # Try writing incorrect port
    with pytest.raises(IOError):
        quasidisk.write_io(0x42, 0x24)


def test_incorrect_page_selection(quasidisk):
    # Try writing incorrect page index
    with pytest.raises(IOError):
        quasidisk.write_io(0x40, 0x42)


def test_page_not_selected(quasidisk):
    with pytest.raises(IOError):
        quasidisk.write_stack(0x4000, 0x4242)

    with pytest.raises(IOError):
        quasidisk.read_stack(0x4000)


def test_read_write(quasidisk):
    # Select a page
    quasidisk.write_io(0x40, 0xf7)

    # Write then read on the same page
    quasidisk.write_stack(0x4000, 0x4242)
    assert quasidisk.read_stack(0x4000) == 0x4242


def test_read_write_different_pages(quasidisk):
    # Write on page 4
    quasidisk.write_io(0x40, 0xf7)
    quasidisk.write_stack(0x4000, 0x4242)

    # Try reading from a different page
    quasidisk.write_io(0x40, 0xfe)
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
    quasidisk.write_io(0x40, 0xfe)
    assert quasidisk.read_stack(0x1234) == 0x12
    quasidisk.write_io(0x40, 0xfd)
    assert quasidisk.read_stack(0x2345) == 0x34
    quasidisk.write_io(0x40, 0xfb)
    assert quasidisk.read_stack(0x3456) == 0x56
    quasidisk.write_io(0x40, 0xf7)
    assert quasidisk.read_stack(0x4567) == 0x78



def test_read_data(diskfile):
    quasidisk = QuasiDisk(diskfile)

    # Write some data on the disk
    quasidisk.write_io(0x40, 0xfe)
    quasidisk.write_stack(0x1234, 0x12)
    quasidisk.write_io(0x40, 0xfd)
    quasidisk.write_stack(0x2345, 0x34)
    quasidisk.write_io(0x40, 0xfb)
    quasidisk.write_stack(0x3456, 0x56)
    quasidisk.write_io(0x40, 0xf7)
    quasidisk.write_stack(0x4567, 0x78)

    # Ensure data is dumped to the host system file
    quasidisk.update()

    # Validate the data
    data = diskfile.read_bytes()

    assert data[0        + 0x1234] == 0x12
    assert data[64*1024  + 0x2345] == 0x34
    assert data[128*1024 + 0x3456] == 0x56
    assert data[192*1024 + 0x4567] == 0x78

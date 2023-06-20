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
def disk(tmp_path, cpm):
    # Create and install an empty quasi disk
    f = tmp_path / "test.bin"
    f.write_bytes(bytearray([0xe5] * (256*1024)))
    disk = QuasiDisk(f)

    # Register the disk at CPM and initialize the disk system
    cpm._emulator._machine.set_quasi_disk(disk)
    disk_reset(cpm)

    return disk


def call_bdos_function(cpm, func, arg = 0):
    cpm.cpu._c = func
    cpm.cpu.de = arg
    cpm.run_function(0xcc06)
    return (cpm.cpu._b << 8) | cpm.cpu._a


def gen_content(lines_count, start = 0):
    res = ""
    for i in range(start, start + lines_count):
        res += f"Line num {i:04}!\r\n"

    return res

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


def bin2str(data):
    return ''.join(chr(code) for code in data)


def str2bin(data):
    return bytearray(data.encode('ascii'))


def write_protect_disk(cpm, disk_no):
    call_bdos_function(cpm, 0x1c, 0)


def disk_reset(cpm):
    call_bdos_function(cpm, 0x0d)


def create_file(cpm, name):
    fill_fcb(cpm, 0x1000, name)
    return call_bdos_function(cpm, 0x16, 0x1000)


def open_file(cpm, name):
    fill_fcb(cpm, 0x1000, name)
    return call_bdos_function(cpm, 0x0f, 0x1000)


def close_file(cpm):
    return call_bdos_function(cpm, 0x10, 0x1000)


def search_first(cpm, name):
    fill_fcb(cpm, 0x1000, name)
    return call_bdos_function(cpm, 0x11, 0x1000)


def search_next(cpm):
    return call_bdos_function(cpm, 0x12, 0x1000)


def delete_file(cpm, name):
    fill_fcb(cpm, 0x1000, name)
    return call_bdos_function(cpm, 0x13, 0x1000)


def write_file_sequentally(cpm, data):
    while len(data) > 0:
        # Fill the 128-byte default disk buffer at 0x0080
        i = 0
        chunk_len = min(128, len(data))
        for b in data[0 : chunk_len]:
            cpm.set_byte(0x0080 + i, b)
            i += 1

        # Call the sector write function
        call_bdos_function(cpm, 0x15, 0x1000)
        data = data[chunk_len:]


def read_file_sequentally(cpm, size):
    offset = 0
    res = []
    while offset < size:
        call_bdos_function(cpm, 0x14, 0x1000)

        for i in range(128):
            res.append(cpm.get_byte(0x0080 + i))

        offset += 128

    return res


def read_file_random(cpm, pos, size):
    res = []

    pos >>= 7   # Convert byte offset to sector number

    while size > 0:
        # Set read position
        cpm.set_word(0x1021, pos & 0xffff)
        cpm.set_byte(0x1023, (pos >> 16) & 0xff) # Should be zero for normal files under 8Mb

        # Read sector
        call_bdos_function(cpm, 0x21, 0x1000)

        for i in range(128):
            res.append(cpm.get_byte(0x0080 + i))

        size -= 128
        pos += 1

    return res


def write_file_random(cpm, pos, data, zero_fill=False):
    pos >>= 7   # Convert byte offset to sector number

    while len(data) > 0:
        # Set read position
        cpm.set_word(0x1021, pos & 0xffff)
        cpm.set_byte(0x1023, (pos >> 16) & 0xff) # Should be zero for normal files under 8Mb

        # Fill the 128-byte default disk buffer at 0x0080
        i = 0
        chunk_len = min(128, len(data))
        for b in data[0 : chunk_len]:
            cpm.set_byte(0x0080 + i, b)
            i += 1

        # Call the sector write function
        if zero_fill:
            call_bdos_function(cpm, 0x28, 0x1000)
        else:
            call_bdos_function(cpm, 0x22, 0x1000)

        # Advance to the next sector
        data = data[chunk_len:]
        pos += 1


def rename_file(cpm, oldname, newname):
    fill_fcb(cpm, 0x1000, oldname)  # Old name in the first 16 bytes of FCB
    fill_fcb(cpm, 0x1010, newname)  # New name in the second 16 bytes
    return call_bdos_function(cpm, 0x17, 0x1000)


def get_file_size(cpm, filename):
    fill_fcb(cpm, 0x1000, filename)
    call_bdos_function(cpm, 0x23, 0x1000)
    assert cpm.get_byte(0x1023) == 0    # No file size overflows
    return cpm.get_word(0x1021)



def test_reset_disk_system(cpm, disk):
    pass


def test_write_protect_disk(cpm, disk):
    # Check starting conditions
    assert cpm.get_word(0xd9ad) == 0x0000   # Write protect bit is not set for any disk

    # Write protect disk A (0)
    write_protect_disk(cpm, 0)

    # Check new conditions
    assert cpm.get_word(0xd9ad) == 0x0001   # Write protect bit is set for disk A
    assert cpm.get_word(0xda35) == 32       # Last entry number is set to maximum dir entries number


def test_seek(cpm, disk):
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
    code = create_file(cpm, 'ABC.TXT')
    assert code == 0

    disk.flush()
    loader = CPMDisk(disk.filename, params=UT88DiskParams)
    entries = loader.list_dir()

    assert len(entries) == 1
    assert entries['ABC.TXT']['num_records'] == 0


def test_search_specific_file(cpm, disk):
    create_file(cpm, 'FOO.TXT')
    create_file(cpm, 'BAR.ASM')
    create_file(cpm, 'ZOO.COM')
    
    index = search_first(cpm, 'BAR.ASM')
    assert index == 1   # Index of the BAR.ASM in the directory


def test_search_by_pattern(cpm, disk):
    create_file(cpm, 'BAR.TXT')
    create_file(cpm, 'FOO.TXT')
    create_file(cpm, 'FAA.TXT')
    
    index = search_first(cpm, 'F??.TXT')
    assert index == 1   # Index of the first match

    index = search_next(cpm)
    assert index == 2   # Index of the first match

# TODO: delete the file, and see that search with '?' as a drive code returns all the entries

def test_rename_file(cpm, disk):
    create_file(cpm, 'FOO.TXT')

    assert search_first(cpm, 'FOO.TXT') == 0        # Foo exists
    assert search_first(cpm, 'BAR.TXT') == 0xff     # Bar does not

    rename_file(cpm, 'FOO.TXT', 'BAR.TXT') 

    assert search_first(cpm, 'FOO.TXT') == 0xff     # Foo no longer found
    assert search_first(cpm, 'BAR.TXT') == 0        # Bar is at foo's location


def test_delete_file(cpm, disk):
    create_file(cpm, 'FOO.TXT')
    assert search_first(cpm, 'FOO.TXT') == 0        # File exists

    delete_file(cpm, 'FOO.TXT') 
    assert search_first(cpm, 'FOO.TXT') == 0xff     # Foo no longer exists


def test_delete_file_by_mask(cpm, disk):
    create_file(cpm, 'FOO1.TXT')
    create_file(cpm, 'FOO2.TXT')
    create_file(cpm, 'FOO3.TXT')
    assert search_first(cpm, 'FOO?.TXT') == 0        # Files exists

    delete_file(cpm, 'FOO?.TXT') 
    assert search_first(cpm, 'FOO?.TXT') == 0xff     # Files no longer exist


@pytest.mark.parametrize("data_size", [
    8,      # 1 sector, block is partially filled
    64,     # 8 sectors, 1 full block
    128,    # 16 sectors, 2 full blocks
    1024,   # 128 sectors, 16 full blocks - full extent
    1032,   # >128 sectors, require additional extent
])
def test_write_file_sequentally(cpm, data_size, disk):
    assert create_file(cpm, 'FOO.TXT') != 0xff

    content = gen_content(data_size)
    write_file_sequentally(cpm, str2bin(content))
    
    assert close_file(cpm) != 0xff

    # Check the content
    disk.flush()
    loader = CPMDisk(disk.filename, params=UT88DiskParams)
    read_str = bin2str(loader.read_file('FOO.TXT'))
    assert read_str == content


def test_open_file(cpm, disk):
    content = gen_content(8)

    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bin(content))
    writer.flush()
    disk.reload()

    assert open_file(cpm, 'FOO.TXT') == 0       # Existing file
    assert open_file(cpm, 'BAR.TXT') == 0xff    # Non-existing file


@pytest.mark.parametrize("data_size", [
    8,      # 1 sector, block is partially filled
    64,     # 8 sectors, 1 full block
    128,    # 16 sectors, 2 full blocks
    1024,   # 128 sectors, 16 full blocks - full extent
    1032,   # >128 sectors, require additional extent
])
def test_read_file_sequentally(cpm, data_size, disk):
    content = gen_content(data_size)

    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bin(content))
    writer.flush()
    disk.reload()

    assert open_file(cpm, 'FOO.TXT') == 0
    data = bin2str(read_file_sequentally(cpm, len(content)))
    assert content == data


def test_read_file_random(cpm, disk):
    # Prepare a file on disk
    content = gen_content(2048)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bin(content))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it loads the directory
    disk.reload()
    disk_reset(cpm)

    # Open the file, and read a sector in the middle
    open_file(cpm, 'FOO.TXT')
    data = bin2str(read_file_random(cpm, 0x2000, 256))   # Read 2 sectors at offset 0x2000
    assert data == gen_content(16, 512) # 16 records == 256 bytes read, 512 records match requested offset


def test_write_file_random(cpm, disk):
    # Prepare a file on disk
    wcontent = gen_content(2048)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bin(wcontent))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it loads the directory
    disk.reload()
    disk_reset(cpm)

    # Open the file, and write a sector in the middle
    open_file(cpm, 'FOO.TXT')
    insert = gen_content(16, 4096)
    write_file_random(cpm, 0x2000, str2bin(insert))   # Write 2 sectors at offset 0x2000
    close_file(cpm)

    # Read the file, and check that content has overwritten sectors
    disk.flush()
    check = CPMDisk(disk.filename, params=UT88DiskParams)
    rcontent = bin2str(check.read_file('FOO.TXT'))
    wcontent = wcontent[:0x2000] + insert + wcontent[0x2000 + 256:]
    assert rcontent == wcontent


def test_write_file_zero_fill(cpm, disk):
    # Prepare a file on disk
    wcontent = gen_content(2048)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bin(wcontent))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it loads the directory
    disk.reload()
    disk_reset(cpm)

    # Open the file, and write a sector in the middle
    open_file(cpm, 'FOO.TXT')
    insert = gen_content(16, 4096)
    # Write 2 sectors at offset 0x8100, but whole 1k block 0x8000-0x8400 will be erased first
    write_file_random(cpm, 0x8100, str2bin(insert), zero_fill=True)
    close_file(cpm)

    # Read the file, and check that content has overwritten sectors
    disk.flush()
    check = CPMDisk(disk.filename, params=UT88DiskParams)
    rcontent = check.read_file('FOO.TXT')
    assert bin2str(rcontent[0 : 0x8000]) == wcontent    # Original content is unchanged
    assert rcontent[0x8000:0x8100] == [0]*256           # Beginning of block is zeroed
    assert len(rcontent) == 0x8200                      # No data after the written records
    assert bin2str(rcontent[0x8100 : 0x8200]) == insert # 2 sectors in the middle have content


def test_get_file_size(cpm, disk):
    # Prepare a file on disk
    wcontent = gen_content(2160)    # Create a file of an odd size - 270 sectors (34 blocks, last not full)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bin(wcontent))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it reloads the directory
    disk.reload()
    disk_reset(cpm)

    # Check the file size is correct
    assert get_file_size(cpm, 'FOO.TXT') == 270
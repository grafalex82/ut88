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
from helper import str2bytes, bytes2str

# Standard entry point for all BDOS functions
# The function number is passed to the function in the C register
BDOS_ENTRY_POINT                = 0xcc06

# All CP/M BDOS file related functions use File Control Block (FCB) structure to pass parameters to
# the function, get results, as well as store intermediate data between calls to BDOS. Tests below
# use an FCB located at 0x1000
FCB                             = 0x1000


# Most of the file functions use the default 128-byte data buffer at 0x0080
DATA_BUF                        = 0x0080

# The BDOS holds the bitmask of write protected disks currently installed in the system
BDOS_READ_ONLY_VECTOR           = 0xd9ad

# The BIOS contains a structure that contains currently selected disk parameters. The structure is filled
# during selecting the disk. One of the fields represents current entries count (Note: this value is set 
# to maximum when the disk is marked as read only)
BDOS_LAST_ENTRY_NUMBER          = 0xda35


# BDOS always 'knows' internally which sector is currently selected. Although BIOS provides a concept of
# track/sector, the BDOS internally calculates sectors absolutely, starting from non-reserved tracks.
BDOS_CURRENT_SECTOR             = 0xd9e5

# When BDOS wants to read a file or a directory sector, it performs a seek operation. This operation 
# translates currently selected absolute sector number into track/sector pair, taking into account
# tracks-pre-sector number, and reserved tracks count. Seek function is internal BDOS function, and shall
# not be executed directly. It is used in tests just to trigger some functionality of the function.
BDOS_SEEK_FUNCTION              = 0xcfd1


# BDOS counts sectors using an absolute number (similar to LBA in modern systems). At the same time
# BIOS exposes tracks/sector interface. More overs. UT-88 quasi disk adds a concept of a memory page,
# which is another parameter to control. The following variables represent BIOS variables that specify
# which page/track/sector is currently selected for reading
BIOS_DISK_PAGE                  = 0xdbec
BIOS_DISK_TRACK                 = 0xdbed
BIOS_DISK_SECTOR                = 0xdbee

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
    disk_system_reset(cpm)

    return disk


def call_bdos_function(cpm, func, arg = 0):
    cpm.cpu.c = func
    cpm.cpu.de = arg
    cpm.run_function(BDOS_ENTRY_POINT)
    return (cpm.cpu.b << 8) | cpm.cpu.a


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


def write_protect_disk(cpm):
    call_bdos_function(cpm, 0x1c)


def disk_system_reset(cpm):
    call_bdos_function(cpm, 0x0d)


def get_login_vector(cpm):
    return call_bdos_function(cpm, 0x18)
    

def get_disk_read_only_vector(cpm):
    return call_bdos_function(cpm, 0x1d)
    

def get_current_disk(cpm):
    return call_bdos_function(cpm, 0x19)


def set_user_code(cpm, code):
    return call_bdos_function(cpm, 0x20, code)


def switch_off_drive(cpm, drive):
    call_bdos_function(cpm, 0x25, drive)


def create_file(cpm, name):
    fill_fcb(cpm, FCB, name)
    return call_bdos_function(cpm, 0x16, FCB)


def open_file(cpm, name):
    fill_fcb(cpm, FCB, name)
    return call_bdos_function(cpm, 0x0f, FCB)


def close_file(cpm):
    return call_bdos_function(cpm, 0x10, FCB)


def search_first(cpm, name):
    fill_fcb(cpm, FCB, name)
    return call_bdos_function(cpm, 0x11, FCB)


def search_next(cpm):
    return call_bdos_function(cpm, 0x12, FCB)


def delete_file(cpm, name):
    fill_fcb(cpm, FCB, name)
    return call_bdos_function(cpm, 0x13, FCB)


def write_file_sequentally(cpm, data):
    while len(data) > 0:
        # Fill the 128-byte default disk buffer at 0x0080
        i = 0
        chunk_len = min(128, len(data))
        for b in data[0 : chunk_len]:
            cpm.set_byte(DATA_BUF + i, b)
            i += 1

        # Call the sector write function
        call_bdos_function(cpm, 0x15, FCB)
        data = data[chunk_len:]


def read_file_sequentally(cpm, size):
    offset = 0
    res = []
    while offset < size:
        call_bdos_function(cpm, 0x14, FCB)

        for i in range(128):
            res.append(cpm.get_byte(DATA_BUF + i))

        offset += 128

    return res


def read_file_random(cpm, pos, size):
    res = []

    pos >>= 7   # Convert byte offset to sector number

    while size > 0:
        # Set read position
        cpm.set_word(FCB + 0x21, pos & 0xffff)
        cpm.set_byte(FCB + 0x23, (pos >> 16) & 0xff) # Should be zero for normal files under 8Mb

        # Read sector
        call_bdos_function(cpm, 0x21, FCB)

        for i in range(128):
            res.append(cpm.get_byte(DATA_BUF + i))

        size -= 128
        pos += 1

    return res


def write_file_random(cpm, pos, data, zero_fill=False):
    pos >>= 7   # Convert byte offset to sector number

    while len(data) > 0:
        # Set read position
        cpm.set_word(FCB + 0x21, pos & 0xffff)
        cpm.set_byte(FCB + 0x23, (pos >> 16) & 0xff) # Should be zero for normal files under 8Mb

        # Fill the 128-byte default disk buffer at 0x0080
        i = 0
        chunk_len = min(128, len(data))
        for b in data[0 : chunk_len]:
            cpm.set_byte(DATA_BUF + i, b)
            i += 1

        # Call the sector write function
        if zero_fill:
            call_bdos_function(cpm, 0x28, FCB)
        else:
            call_bdos_function(cpm, 0x22, FCB)

        # Advance to the next sector
        data = data[chunk_len:]
        pos += 1


def rename_file(cpm, oldname, newname):
    fill_fcb(cpm, FCB, oldname)  # Old name in the first 16 bytes of FCB
    fill_fcb(cpm, FCB + 0x10, newname)  # New name in the second 16 bytes
    return call_bdos_function(cpm, 0x17, FCB)


def get_file_size(cpm, filename):
    fill_fcb(cpm, FCB, filename)
    call_bdos_function(cpm, 0x23, FCB)
    assert cpm.get_byte(FCB + 0x23) == 0    # No file size overflows
    return cpm.get_word(FCB + 0x21)


def get_file_position(cpm):
    call_bdos_function(cpm, 0x24, FCB)
    assert cpm.get_byte(FCB + 0x23) == 0    # No file size overflows
    return cpm.get_word(FCB + 0x21)



def test_reset_disk_system(cpm, disk):
    pass


def test_write_protect_disk(cpm, disk):
    # Check starting conditions
    assert cpm.get_word(BDOS_READ_ONLY_VECTOR) == 0x0000   # Write protect bit is not set for any disk
    assert get_disk_read_only_vector(cpm) == 0x0000

    # Write protect currently selected disk
    write_protect_disk(cpm)

    # Check new conditions
    assert cpm.get_word(BDOS_READ_ONLY_VECTOR) == 0x0001   # Write protect bit is set for disk A
    assert cpm.get_word(BDOS_LAST_ENTRY_NUMBER) == 32      # Last entry number is set to maximum dir entries number
    assert get_disk_read_only_vector(cpm) == 0x0001


def test_seek(cpm, disk):
    # Seek in forward direction, compared to current track
    cpm.set_word(BDOS_CURRENT_SECTOR, 0x0342)   # Set expected sector number to 0x342
    cpm.run_function(BDOS_SEEK_FUNCTION)      # Call seek function

    # Sector #0x342 is located on track 0x68 having 8 sectors per track. Disk is split into four
    # pages 0x40 tracks each. So track #0x68 is located on page 1, track 0x28.
    # Also, the disk has 6 reserved tracks, so the physical track number will be 0x28 + 6 = 0x2e
    # Sector number is 0x342 % 8 = 2. This is a logical sector number, whick will be renumbered
    # to #3 physical sector number.
    assert cpm.get_byte(BIOS_DISK_PAGE) == 0xfd     # Page 2
    assert cpm.get_byte(BIOS_DISK_TRACK) == 0x2e    # Logical Track 0x28 (Physical track = 0x28 + 6 reserved tracks)
    assert cpm.get_byte(BIOS_DISK_SECTOR) == 0x03   # Sector #3 (Logical track #2, physical track #3 since 1-based)

    # Seek in backward direction, compared to current track
    cpm.set_word(BDOS_CURRENT_SECTOR, 0x073)    # Set expected sector number to 0x342
    cpm.run_function(BDOS_SEEK_FUNCTION)      # Call seek function

    assert cpm.get_byte(BIOS_DISK_PAGE) == 0xfe
    assert cpm.get_byte(BIOS_DISK_TRACK) == 0x14
    assert cpm.get_byte(BIOS_DISK_SECTOR) == 0x04


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
    assert index == 2   # Index of the second match

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
    write_file_sequentally(cpm, str2bytes(content))
    
    assert close_file(cpm) != 0xff

    # Check the content
    disk.flush()
    loader = CPMDisk(disk.filename, params=UT88DiskParams)
    read_str = bytes2str(loader.read_file('FOO.TXT'))
    assert read_str == content


def test_open_file(cpm, disk):
    content = gen_content(8)

    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bytes(content))
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
    writer.write_file('FOO.TXT', str2bytes(content))
    writer.flush()
    disk.reload()

    assert open_file(cpm, 'FOO.TXT') == 0
    data = bytes2str(read_file_sequentally(cpm, len(content)))
    assert content == data


def test_read_eof(cpm, disk):
    # Write file of 2 sectors
    content = gen_content(16)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bytes(content))
    writer.flush()
    disk.reload()

    assert open_file(cpm, 'FOO.TXT') == 0
    assert call_bdos_function(cpm, 0x14, FCB) == 0   # First read shall succeed
    assert call_bdos_function(cpm, 0x14, FCB) == 0   # Second read will succeed too
    assert call_bdos_function(cpm, 0x14, FCB) == 1   # Third will indicate end of file


def test_read_file_random(cpm, disk):
    # Prepare a file on disk
    content = gen_content(2048)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bytes(content))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it loads the directory
    disk.reload()
    disk_system_reset(cpm)

    # Open the file, and read a sector in the middle
    open_file(cpm, 'FOO.TXT')
    data = bytes2str(read_file_random(cpm, 0x2000, 256))   # Read 2 sectors at offset 0x2000
    assert data == gen_content(16, 512) # 16 records == 256 bytes read, 512 records match requested offset


def test_write_file_random(cpm, disk):
    # Prepare a file on disk
    wcontent = gen_content(2048)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bytes(wcontent))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it loads the directory
    disk.reload()
    disk_system_reset(cpm)

    # Open the file, and write a sector in the middle
    open_file(cpm, 'FOO.TXT')
    insert = gen_content(16, 4096)
    write_file_random(cpm, 0x2000, str2bytes(insert))   # Write 2 sectors at offset 0x2000
    close_file(cpm)

    # Read the file, and check that content has overwritten sectors
    disk.flush()
    check = CPMDisk(disk.filename, params=UT88DiskParams)
    rcontent = bytes2str(check.read_file('FOO.TXT'))
    wcontent = wcontent[:0x2000] + insert + wcontent[0x2000 + 256:]
    assert rcontent == wcontent


def test_write_file_zero_fill(cpm, disk):
    # Prepare a file on disk
    wcontent = gen_content(2048)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bytes(wcontent))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it loads the directory
    disk.reload()
    disk_system_reset(cpm)

    # Open the file, and write a sector in the middle
    open_file(cpm, 'FOO.TXT')
    insert = gen_content(16, 4096)
    # Write 2 sectors at offset 0x8100, but whole 1k block 0x8000-0x8400 will be erased first
    write_file_random(cpm, 0x8100, str2bytes(insert), zero_fill=True)
    close_file(cpm)

    # Read the file, and check that content has overwritten sectors
    disk.flush()
    check = CPMDisk(disk.filename, params=UT88DiskParams)
    rcontent = check.read_file('FOO.TXT')
    assert bytes2str(rcontent[0 : 0x8000]) == wcontent    # Original content is unchanged
    assert rcontent[0x8000:0x8100] == bytearray(256)    # Beginning of block is zeroed
    assert len(rcontent) == 0x8200                      # No data after the written records
    assert bytes2str(rcontent[0x8100 : 0x8200]) == insert # 2 sectors in the middle have content


def test_get_file_size(cpm, disk):
    # Prepare a file on disk
    wcontent = gen_content(2160)    # Create a file of an odd size - 270 sectors (34 blocks, last not full)
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bytes(wcontent))
    writer.flush()

    # Load the new disk content, and reset disk in CPM so that it reloads the directory
    disk.reload()
    disk_system_reset(cpm)

    # Check the file size is correct
    assert get_file_size(cpm, 'FOO.TXT') == 270


def test_get_file_position(cpm, disk):
    # Create file large enough
    content = gen_content(1789)     # Just random size between 1 and 2 full extents
    writer = CPMDisk(disk.filename, params=UT88DiskParams)
    writer.write_file('FOO.TXT', str2bytes(content))
    writer.flush()
    disk.reload()

    # Read part of the file
    assert open_file(cpm, 'FOO.TXT') == 0
    read_file_sequentally(cpm, 16*1240) # Read some random number of sectors (more than one extent)

    assert get_file_position(cpm) == 16*1240 // 128


def test_reset_disk(cpm, disk):
    # All disks shall be enabled at this point
    assert get_login_vector(cpm) == 0x0001  # Our disk is online
    assert get_current_disk(cpm) == 0x00    # Our disk is current

    # Switch off the drive
    switch_off_drive(cpm, 0x0001)

    # Check the drive is off
    assert get_login_vector(cpm) == 0x0000  # Our disk is no longer online


def test_search_by_user_code(cpm, disk):
    set_user_code(cpm, 1)
    create_file(cpm, 'TEST1.TXT')
    set_user_code(cpm, 2)
    create_file(cpm, 'TEST2.TXT')
    set_user_code(cpm, 3)
    create_file(cpm, 'TEST3.TXT')
    
    set_user_code(cpm, 1)
    assert search_first(cpm, 'TEST1.TXT') == 0      # User #1 sees only their file
    assert search_first(cpm, 'TEST2.TXT') == 0xff
    assert search_first(cpm, 'TEST3.TXT') == 0xff

    set_user_code(cpm, 2)
    assert search_first(cpm, 'TEST1.TXT') == 0xff   # User #2 sees only their file
    assert search_first(cpm, 'TEST2.TXT') == 1
    assert search_first(cpm, 'TEST3.TXT') == 0xff

    set_user_code(cpm, 3)
    assert search_first(cpm, 'TEST1.TXT') == 0xff   # User #3 sees only their file
    assert search_first(cpm, 'TEST2.TXT') == 0xff
    assert search_first(cpm, 'TEST3.TXT') == 2

    fill_fcb(cpm, FCB, 'TEST1.TXT')              # Special trick - put '?' in the FCB user code field and 
    cpm.set_byte(FCB, ord('?'))                  # see files for all users
    assert call_bdos_function(cpm, 0x11, FCB) == 0

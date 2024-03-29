# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from common.tape import TapeRecorder


def test_write_bytes(tmp_path):
    recorder = TapeRecorder()

    # Byte 1 (0x5a)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)

    # Byte 2 (0xd2)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)
    recorder.write_byte(0xa1, 0)   # Ignore
    recorder.write_byte(0xa1, 1)
    recorder.write_byte(0xa1, 1)   # Ignore
    recorder.write_byte(0xa1, 0)

    testfile = tmp_path / "test.bin"
    recorder.dump_to_file(str(testfile))
    assert testfile.read_bytes() == b"\x5a\xd2"

def test_read_bytes(tmp_path):
    recorder = TapeRecorder()

    testfile = tmp_path / "test.bin"
    testfile.write_bytes(b"\x5a\xd2")

    recorder.load_from_file(str(testfile))

    # Byte 1    
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Duplicate bit at the beginning of each byte
    assert recorder.read_byte(0xa1) == 0  # Real data bit
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Real data bit
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Real data bit
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Real data bit

    # Byte 2 (0xd2)
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Duplicate bit at the beginning of each byte
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Real data bit
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Real data bit
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Real data bit
    assert recorder.read_byte(0xa1) == 0  # Inverted bit
    assert recorder.read_byte(0xa1) == 1  # Real data bit
    assert recorder.read_byte(0xa1) == 1  # Inverted bit
    assert recorder.read_byte(0xa1) == 0  # Real data bit

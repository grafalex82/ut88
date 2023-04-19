# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from tape import TapeRecorder


def test_write_bytes(tmp_path):
    recorder = TapeRecorder()

    # Byte 1 (0x5a)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)

    # Byte 2 (0xd2)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)
    recorder.write_io(0xa1, 0)   # Ignore
    recorder.write_io(0xa1, 1)
    recorder.write_io(0xa1, 1)   # Ignore
    recorder.write_io(0xa1, 0)

    testfile = tmp_path / "test.bin"
    recorder.dump_to_file(testfile)
    assert testfile.read_bytes() == b"\x5a\xd2"
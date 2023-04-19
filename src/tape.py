import struct
from interfaces import *

class TapeRecorder(IODevice):
    """
    Tape Recorder Port Emulator

    The TapeRecorder class emulates storing/loading data to/from the tape recorder.
    Electrically tape recorder is connected to a bit 0 of the 0xA1 port.

    Data storage format is based on the 2-phase coding algorithm. Each bit is 
    coded as 2 periods with opposite values. The actual bit value is determined
    at the transition between the periods:
    - transition from 1 to 0 represents value 0
    - transition from 0 to 1 represents value 1
    
    Bytes are written MSB first. Typical recording speed is 1500 bits per second.

    The Tape Recorder component allows to store written data into a file, as well as
    load a binary file and emulate tape reading. 

    The emulation of the tape recorder component is a bit hacky in favor of simplification:
    - it does not take into account exact timings. Each write or read is considered as a next bit phase
    - writing data ignores the first phase of each bit, only second phase is taken into account

    The implementation does not care about the data format, synchronization sequences,
    and any extra metadata written or read - this additional information is a part of the
    dumped data.
    """
    def __init__(self):
        IODevice.__init__(self, 0xa1, 0xa1)
        self._reset_buffer()

    def _reset_buffer(self):
        self._buffer = bytearray()
        self._byte = 0
        self._bits = 0

    def dump_to_file(self, fname):
        with open(fname, "wb") as f:
            f.write(self._buffer)
        self._reset_buffer()

    def write_io(self, addr, value):
        self.validate_addr(addr)

        self._bits += 1
        if self._bits % 2:
            return # Skip odd calls, only even phase has the data
        
        self._byte <<= 1
        self._byte |= (value & 0x01)

        if self._bits == 16:
            self._buffer.extend(self._byte.to_bytes(1, 'big'))
            self._bits = 0
            self._byte = 0


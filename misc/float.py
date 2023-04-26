import struct

class Float:
    def __init__(self, value:float = 0):
        self.from_float(value)

    def is_negative(self):
        return self._negative
    
    def get_exponent(self):
        return self._exponent
    
    def get_mantissa(self):
        return self._mantissa

    def __str__(self) -> str:
        return f"{'-' if self._negative else ''}{self._mantissa:06x}e{self._exponent}"

    def __repr__(self) -> str:
        return self.__str__()

    def from_float(self, value: float):
        float_bytes = struct.pack('f', value)
        int_value = struct.unpack('i', float_bytes)[0]

        print(f"Value = {value} {int_value:08x}")

        if value == 0.:
            self._negative = False
            self._exponent = 0
            self._mantissa = 0
        else:
            self._negative = (int_value & 0x80000000 != 0)
            self._exponent = ((int_value & 0x7f800000) >> 23) - 127
            self._mantissa = (int_value & 0x7fffff) | 0x800000

    def from_sem(self, sign, exponent, mantissa):
        self._negative = sign
        self._exponent = exponent
        self._mantissa = mantissa

        self.normalize()

    def normalize(self):
        if self._mantissa == 0:
            return
        
        while self._mantissa < 0x800000:
            self._mantissa <<= 1
            self._exponent -= 1

        while self._mantissa >= 0x01000000:
            self._mantissa >>= 1
            self._exponent += 1

    def to_float(self):
        if self._mantissa == 0 and self._exponent == 0:
            return 0.
        
        int_value = self._mantissa & 0x7fffff
        int_value |= ((self._exponent + 127) & 0xff) << 23
        int_value |= 0x80000000 if self._negative else 0

        float_bytes = struct.pack('i', int_value)
        return struct.unpack('f', float_bytes)[0]

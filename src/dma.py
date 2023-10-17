from utils import *
from common.interfaces import *

DMA_CH0_START   = 0
DMA_CH0_COUNT   = 1
DMA_CH1_START   = 2
DMA_CH1_COUNT   = 3
DMA_CH2_START   = 4
DMA_CH2_COUNT   = 5
DMA_CH3_START   = 6
DMA_CH3_COUNT   = 7
DMA_PORT_CFG    = 8

class DMA:
    """
        The Intel 8257 DMA controller emulator.

        This class mimics the Intel 8257 DMA controller, providing the following features:
        - controller configuration ports for setting up data transfer
        - Burst data transfer (read or write) using one of 4 channels
        - autoload feature on the channel 2

        The controller exposes 9 registers: 8 registers to set start address and data count for 4 channels, and
        the 9th register is a control register. Typically, in original Radio-86RK schematics the DMA controller
        resides at 0xe000-0xe008 memory addresses, but setting actual memory address is the MemoryDevice 
        responsibility.

        Note, that this class provides a very limited implementation, and does not provide all the features
        of the original controller. Just a few features that enough to run Radio-86RK use case.
    """
    
    def __init__(self, machine):
        self._machine = machine

        self._autoload = False
        self._tc_stop = False
        self._extended_write = False
        self._rotating_priority = False
        self._channels = [{
            'enabled': False, 
            'start_addr': None, 
            'count': None, 
            'read':False, 
            'write':False} for _ in range(4)]
        self._waiting_high_byte = False


    def get_size(self):
        return 9    # 8 registers for 4 DMA channels, and a configuration register


    def _enable_channel(self, channel, enable):
        # Store the enable flag
        self._channels[channel]['enabled'] = enable

        # Nothing to do if the channel is disabled
        if not enable:
            return
        
        # Just assert we are prepared for data transfer
        assert self._channels[channel]['start_addr'] != None
        assert self._channels[channel]['count'] != None


    def set_register_value(self, channel, count_register, value):
        if count_register:
            if self._waiting_high_byte:
                self._channels[channel]['count'] |= (value & 0x3f) << 8         # High byte
                self._channels[channel]['count'] += 1                           # Parameter is 1 less than actual count
                self._channels[channel]['read'] = is_bit_set(value, 6)
                self._channels[channel]['write'] = is_bit_set(value, 7)
            else:
                self._channels[channel]['count'] = value & 0xff                 # Low byte
        else:
            if self._waiting_high_byte:
                self._channels[channel]['start_addr'] |= (value & 0xff) << 8    # High byte
            else:
                self._channels[channel]['start_addr'] = value & 0xff            # Low byte

        self._waiting_high_byte = not self._waiting_high_byte

        # In case of Autoload option, channel 3 registers will store original values for start address 
        # and bytes count for channel 2
        if self._autoload and channel == 2:
            self._channels[3]['count'] = self._channels[2]['count']
            self._channels[3]['start_addr'] = self._channels[2]['start_addr']


    def get_register_value(self, channel, count_register):
        if count_register:
            return self._channels[channel]['count']
        else:
            return self._channels[channel]['start_addr']
            

    def write_byte(self, offset, value):
        match offset:
            case offset if offset < DMA_PORT_CFG:       # Start address or counter register
                channel = (offset >> 1) & 0x03
                count_register = is_bit_set(offset, 0)
                self.set_register_value(channel, count_register, value)

            case offset if offset == DMA_PORT_CFG:      # Mode byte
                self._autoload = is_bit_set(value, 7)
                self._tc_stop = is_bit_set(value, 6)
                self._extended_write = is_bit_set(value, 5)
                self._rotating_priority = is_bit_set(value, 4)
                self._enable_channel(3, is_bit_set(value, 3))
                self._enable_channel(2, is_bit_set(value, 2))
                self._enable_channel(1, is_bit_set(value, 1))
                self._enable_channel(0, is_bit_set(value, 0))

            case _:
                raise MemoryError(f"Writing DMA register {offset} is not supported")


    def _get_transfer_settings(self, channel):
        if not self._channels[channel]['enabled']:
            raise RuntimeError(f"DMA Channel {channel} is not configured for data transfer")

        start_addr = self._channels[channel]['start_addr']
        count = self._channels[channel]['count'] 

        # Autoload feature will reload channel 2 settings from channel 3
        # If no autoload feature is on, or other channel is used, the channel will be disabled
        if channel == 2 and self._autoload:
            self._channels[2]['start_addr'] = self._channels[3]['start_addr']
            self._channels[2]['count'] = self._channels[3]['count']
        else:
            self._channels[channel]['enabled'] = False

        return start_addr, count


    def dma_read(self, channel):
        start_addr, count = self._get_transfer_settings(channel)
        assert self._channels[channel]['read']
        return self._machine.read_memory_burst(start_addr, count)


    def dma_write(self, channel, data):
        start_addr, count = self._get_transfer_settings(channel)
        assert self._channels[channel]['write']
        assert len(data) == count

        self._machine.write_memory_burst(start_addr, data)


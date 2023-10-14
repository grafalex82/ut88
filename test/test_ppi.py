# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys
from unittest.mock import MagicMock

sys.path.append('../src')

from ppi import *
from utils import *
from interfaces import MemoryDevice

@pytest.fixture
def ppi():
    return PPI()


def test_configure(ppi):
    ppi.write_byte(PPI_PORT_CFG, 0x8a)

    assert ppi._portA_mode_input == False
    assert ppi._portB_mode_input == True
    assert ppi._portCu_mode_input == True
    assert ppi._portCl_mode_input == False


def test_write_output_port(ppi):
    ppi.write_byte(PPI_PORT_CFG, 0x80)    # Configure with all 3 ports as output

    portA_mock_func = MagicMock()
    ppi.set_portA_handler(portA_mock_func)
    ppi.write_byte(PPI_PORT_A, 0x42)
    portA_mock_func.assert_called_once_with(0x42)

    portB_mock_func = MagicMock()
    ppi.set_portB_handler(portB_mock_func)
    ppi.write_byte(PPI_PORT_B, 0x34)
    portB_mock_func.assert_called_once_with(0x34)

    portC_mock_func = MagicMock()
    ppi.set_portC_handler(portC_mock_func)
    ppi.write_byte(PPI_PORT_C, 0x56)
    portC_mock_func.assert_called_once_with(0x56)


def test_read_input_port(ppi):
    ppi.write_byte(PPI_PORT_CFG, 0x9b)    # Configure with all 3 ports as input

    portA_mock_func = MagicMock(return_value = 0x42)
    ppi.set_portA_handler(portA_mock_func)
    assert ppi.read_byte(PPI_PORT_A) == 0x42

    portB_mock_func = MagicMock(return_value = 0x34)
    ppi.set_portB_handler(portB_mock_func)
    assert ppi.read_byte(PPI_PORT_B) == 0x34

    portC_mock_func = MagicMock(return_value = 0x56)
    ppi.set_portC_handler(portC_mock_func)
    assert ppi.read_byte(PPI_PORT_C) == 0x56


def test_read_output_port_bit(ppi):
    ppi.write_byte(PPI_PORT_CFG, 0x80)    # Configure with PortC as output

    # Create a few bit handlers
    mock_func0 = MagicMock()
    ppi.set_portC_bit_handler(0, mock_func0)
    mock_func1 = MagicMock()
    ppi.set_portC_bit_handler(1, mock_func1)
    mock_func5 = MagicMock()
    ppi.set_portC_bit_handler(5, mock_func5)
    mock_func6 = MagicMock()
    ppi.set_portC_bit_handler(6, mock_func6)

    # Write to port C (set bits 1 and 6)
    ppi.write_byte(PPI_PORT_C, 0x42)

    # Verify both handlers were triggered
    mock_func0.assert_called_once_with(False)
    mock_func1.assert_called_once_with(True)
    mock_func5.assert_called_once_with(False)
    mock_func6.assert_called_once_with(True)


def test_read_attempt_to_write_input_portC(ppi):
    ppi.write_byte(PPI_PORT_CFG, 0x89)    # Configure with PortC as input

    # Create a few bit handlers
    mock_func0 = MagicMock()
    ppi.set_portC_bit_handler(0, mock_func0)
    mock_func1 = MagicMock()
    ppi.set_portC_bit_handler(1, mock_func1)
    mock_func5 = MagicMock()
    ppi.set_portC_bit_handler(5, mock_func5)
    mock_func6 = MagicMock()
    ppi.set_portC_bit_handler(6, mock_func6)

    # Attempt to write to port C (set bits 1 and 6)
    ppi.write_byte(PPI_PORT_C, 0x42)

    # Verify none of the handlers were called
    mock_func0.assert_not_called()
    mock_func1.assert_not_called()
    mock_func5.assert_not_called()
    mock_func6.assert_not_called()


def test_bsr_set(ppi):
    ppi.write_byte(PPI_PORT_CFG, 0x80)    # Configure with PortC as output

    # Create a few bit handlers
    mock_func6 = MagicMock()
    ppi.set_portC_bit_handler(6, mock_func6)

    # Reset bit #0
    mock_func0 = MagicMock()
    ppi.set_portC_bit_handler(0, mock_func0)
    ppi.write_byte(PPI_PORT_CFG, 0x00)
    mock_func0.assert_called_once_with(False)

    # Set bit #1
    mock_func1 = MagicMock()
    ppi.set_portC_bit_handler(1, mock_func1)
    ppi.write_byte(PPI_PORT_CFG, 0x03)
    mock_func1.assert_called_once_with(True)

    # Reset bit #5
    mock_func5 = MagicMock()
    ppi.set_portC_bit_handler(5, mock_func5)
    ppi.write_byte(PPI_PORT_CFG, 0x0a)
    mock_func5.assert_called_once_with(False)

    # Set bit #6
    mock_func6 = MagicMock()
    ppi.set_portC_bit_handler(6, mock_func6)
    ppi.write_byte(PPI_PORT_CFG, 0x0d)
    mock_func6.assert_called_once_with(True)    

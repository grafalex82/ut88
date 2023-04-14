# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from machine import Machine
from cpu import CPU
from utils import *

@pytest.fixture
def cpu():
    machine = Machine()
    return CPU(machine) 

def test_cpu_create(cpu):
    pass

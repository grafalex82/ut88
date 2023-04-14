# To run these tests install pytest, then run this command line:
# py.test -rfeEsxXwa --verbose --showlocals

import pytest
import sys

sys.path.append('../src')

from machine import Machine
from utils import *

@pytest.fixture
def machine():
    return Machine() 

def test_machine_create(machine):
    pass

import logging

class MemoryError(Exception):
    pass

class IOError(Exception):
    pass

class InvalidInstruction(Exception):
    pass

class NestedLogger():
    def __init__(self):
        self._level = 0

    def enter(self, msg):
        logging.debug(msg() if callable(msg) else msg)

        self._level += 1
        logging.disable(logging.DEBUG)

    def exit(self):
        self._level -= 1
        if self._level == 0:
            logging.disable(logging.NOTSET)

    def reset(self):
        self._level =0
        logging.disable(logging.NOTSET)

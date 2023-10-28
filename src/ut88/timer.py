import time

class Timer:
    """
        Seconds Timer
        
        UT-88 basic configuration employs a timer/counter that generates an interrupt request every second.
        The Monitor 0 handles this interrupt to track current time.
    """

    def __init__(self, machine):
        self._machine = machine
        self._last_update = int(time.time())
    
    def update(self):
        cur_time = int(time.time())
        if self._last_update == cur_time:
            return
        
        self._last_update = cur_time
        self._machine.schedule_interrupt()
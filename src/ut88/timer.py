import time

class Timer:
    def __init__(self, machine):
        self._machine = machine
        self._last_update = int(time.time())
    
    def update(self):
        cur_time = int(time.time())
        if self._last_update == cur_time:
            return
        
        self._last_update = cur_time
        self._machine.schedule_interrupt()
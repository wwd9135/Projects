# Persistence artefact parsing module

# 1: startupcommands (including scheduled tasks, run keys, services, wmi event subscriptions, etc.)
# 2: Schedules tasks (This is a bit of a grey area as to whether this should be in persistence or not, but given the amount of abuse of scheduled tasks for persistence, it felt appropriate to include it here.)
# 3: service persistence (This is also a bit of a grey area as to whether this should be in persistence or not, but given the amount of abuse of services for persistence, it felt appropriate to include it here.)
class Persistence_run:
    def __init__(self,data):
        self.data = data

    def parse(self):
        pass
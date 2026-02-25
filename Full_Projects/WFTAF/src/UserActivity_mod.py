# User Activity parsing module
# 1: USB device activity, report all recent, or any data downloads in the report, rare field so when data is there we need to grab it all and make sure an LLM or human scans it
# 2: PS history check, create list of unusula commands to parse through
class user_activity_run:
    def __init__(self, data):
        self.data = data
    def parse(self):
        pass

    
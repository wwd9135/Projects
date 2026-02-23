# Advanced extra artefacts parsing module

# 1: defender exclusions
# 2: WMI subscription check
# 3: Prefetch checker (Mainly LLM for this one as anything could be appended to prefetch so creating a parse that will hit specific edge cases is unlikely, but an LLM to format that data and pick out key suspicious areas of prefetch is more appropriate.)
class Advanced:
    def __init__(self):
        pass
    def parse(self,data):
        pass
    
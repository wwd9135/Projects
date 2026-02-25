import json


# 1: defender exclusions
class defender_exclusions:
    def __init__(self):
        pass
    def parse(self,data):
        pass

# 2: WMI subscription check
class wmi_subscriptions:
    def __init__(self):
        pass
    def parse(self,data):
        pass
# 3: Prefetch checker (Mainly LLM for this one as anything could be appended to prefetch so creating a parse that will hit specific edge cases is unlikely, but an LLM to format that data and pick out key suspicious areas of prefetch is more appropriate.)
class prefetch_checker:
    def __init__(self):
        pass
    def parse(self,data):
        pass


class Advanced_Run:
    def __init__(self, data):
        self.data = data   # <-- this is already the Advanced dict

    def run(self):
        defender:object = defender_exclusions()
        wmi:object = wmi_subscriptions()
        prefetch:object = prefetch_checker()

        defender_data : dict = defender.parse(self.data.get("DefenderExclusions", []))
        wmi_data : dict = wmi.parse(self.data.get("WmiSubscriptions", []))
        prefetch_data : dict = prefetch.parse(self.data.get("Prefetch", []))

        advanced_report : dict = {
            "DefenderExclusions": defender_data,
            "WmiSubscriptions": wmi_data,
            "PrefetchData": prefetch_data
        }

        return advanced_report

    

#<
# PowerShell foresnic commands for reference.
#  # --- Advanced Forensics ---
#            try {
#                $Prefetch = @($(Get-ChildItem C:\Windows\Prefetch\ | Select-Object Name, CreationTime, LastWriteTime))
#            } catch { $Prefetch = @() }
#            try {
#                $WmiSubscriptions = @($(Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding | Select-Object Filter, Consumer))
#            } catch { $WmiSubscriptions = @() }
#
#            try {
#                $DefenderExclusions = @($(Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions' | Select-Object Name))
#            } catch { $DefenderExclusions = @() }
#
#            $Advanced = [PSCustomObject]@{
#                Prefetch          = $Prefetch
#                WmiSubscriptions  = $WmiSubscriptions
#                DefenderExclusions = $DefenderExclusions
#            }>#
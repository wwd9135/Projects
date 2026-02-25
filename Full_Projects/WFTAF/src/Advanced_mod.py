import json

#Paths under Users, Temp, ProgramData
#Processes: powershell.exe, mshta.exe, rundll32.exe
#Broad extensions: .dll, .exe#
#🟠 Medium Risk
#IP exclusions (almost never legitimate)
#TemporaryPaths enabled
#Custom-named binaries
# 1: defender exclusions
class defender_exclusions:
    def parse(self, data):
        # data is a LIST of dicts
        results = []
        for entry in data:
            if entry.get("Value") is None:
                return {
                    "present": False,
                    "note": entry.get("Note")
                }

            results.append({
                "category": entry.get("Category"),
                "value": entry.get("Value"),
                "registry_path": entry.get("RegistryPath")
            })
        else:
            s= "pass"
            # Insert parsing logic.
        return {
            "present": True,
            "exclusions": results
        }
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
        self.data = data  

    def run(self):
        defender:object = defender_exclusions()
        wmi:object = wmi_subscriptions()
        prefetch:object = prefetch_checker()

        defender_data : list = defender.parse(self.data.get("DefenderExclusions", []))
        wmi_data : list = wmi.parse(self.data.get("WmiSubscriptions", []))
        prefetch_data : list = prefetch.parse(self.data.get("Prefetch", []))

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
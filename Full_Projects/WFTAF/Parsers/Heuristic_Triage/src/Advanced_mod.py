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
    def __init__(self):
        pass
    def Run(self,data):
        # Run each of the advanced artefact checks and compile the data into a format that can be easily added to the final report.
        defender = defender_exclusions()
        wmi = wmi_subscriptions()
        prefetch = prefetch_checker()

        defender_data = defender.parse(data)
        wmi_data = wmi.parse(data)
        prefetch_data = prefetch.parse(data)

        # Compile the data into a structured format for the final report.
        # Format data in classes not the main report, so that the data can be easily accessed and formatted in the final report.
        advanced_report = {
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